#pragma once
#include "pch_mm.h"
#include "working_mm.h"

extern front::Schedule         sch;
extern vkDSLMem DSL;
std::atomic<int> vkmm::Allocation_T::counter = 0;

#ifdef USE_HIREDIS
class RedisLogger{
public:
    redisContext* c;

    void SetUp()  {
     
        unsigned int  isunix = 0;
        const char* hostname = "127.0.0.1";
        int port = 6379;

        struct timeval timeout = { 1, 500000 }; // 1.5 seconds
        if (isunix) {
            c = redisConnectUnixWithTimeout(hostname, timeout);
        }
        else {
            c = redisConnectWithTimeout(hostname, port, timeout);
        }
        if (c == NULL || c->err) {
            if (c) {
                printf("Connection error: %s\n", c->errstr);
                redisFree(c);
            }
            else {
                printf("Connection error: can't allocate redis context\n");
            }
            exit(1);
        }
    };
    void TearDown() {
        if (c != NULL)redisFree(c);
    }

    const char* CRLF = "\r\n";
    const char* USED = "used_memory_human:";
    const char* CMD = "total_commands_processed:";

    void redisINFO(const char* name)
    {
        redisReply* reply;
        char* p1, * p2;
        char bU[32];


        reply = (redisReply*)redisCommand(c, "INFO");
        if (reply->type == REDIS_REPLY_STRING)
        {

            p1 = strstr(reply->str, name);
            if (!p1) return;
            p1 += strlen(name);
            p2 = strstr(p1, CRLF);
            memcpy(bU, p1, p2 - p1);
            bU[p2 - p1] = 0;

            printf(" %s : %s  \n", name, bU);

            freeReplyObject(reply);
        }
    }

    bool  AppendCommandArgv(std::vector<char*>& argv) {

        std::vector< size_t>  arglen;
        for (auto v : argv)  arglen.push_back(strlen(v));
        redisAppendCommandArgv(c, argv.size(), (const char**)argv.data(), (const size_t*)arglen.data());

    }
    int  ExecAppendCommand(int N) {

        redisReply* reply = NULL;
        for (int j = 0; j < N; j++) {
            int r = redisGetReply(c, (void**)&reply);
            if (r == REDIS_ERR) {
                printf("ERROR\n");
            }
            freeReplyObject(reply);
        }

        return 0;
    }

#define  _rd_check(_r){\
			auto r = (redisReply*)_r;\
			if (!r || r->type == REDIS_REPLY_ERROR) { printf("Error\n"); return -1; }}


    int  CommandArgv(std::vector<std::vector<char*>> argv) {

        /*
        std::vector<char*> argv;
        argv.push_back(const_cast<char*>("ZUNIONSTORE"));
        argv.push_back(const_cast<char*>("out-set"));
        argv.push_back(const_cast<char*>("5"));
        argv.push_back(const_cast<char*>("one"));
        argv.push_back(const_cast<char*>("two"));
        argv.push_back(const_cast<char*>("three"));
        */


        std::vector<std::vector< size_t>>  arglen(argv.size());
        int i = 0;
        for (auto com : argv) {
            for (auto v : com)  arglen[i].push_back(strlen(v));
            i++;
        }



        for (int j = 0; j < i; j++) { _rd_check(redisCommandArgv(c, argv[j].size(), (const char**)argv[j].data(), (const size_t*)arglen[j].data())); }


        return  0;
    }
    int Del(const char* pattern) {

        std::vector<char*> argv;
        argv.push_back(const_cast<char*>("DEL"));

        redisReply* reply = (redisReply*)redisCommand(c, "KEYS %b ", pattern, strlen(pattern));
        if (reply->type == REDIS_REPLY_ARRAY) {
            for (int j = 0; j < reply->elements; j++) {
                argv.push_back(const_cast<char*>(reply->element[j]->str));
            }
        }
        return CommandArgv({ argv });
    }
    template<class T>
    std::vector<T> GetKeys(const char* pattern, bool hkey = false) {

        std::vector<T> argv;


        redisReply* reply = nullptr;
        if (hkey) {
            reply = (redisReply*)redisCommand(c, "HKEYS %b ", pattern, strlen(pattern));
        }
        else
            reply = (redisReply*)redisCommand(c, "KEYS %b ", pattern, strlen(pattern));

        if (reply->type == REDIS_REPLY_ARRAY) {
            for (int j = 0; j < reply->elements; j++) {
                argv.push_back(const_cast<T>(reply->element[j]->str));
            }
        }
        return argv;
    }
    bool HExists(const char* hkey, const char* key) {

        redisReply* reply = nullptr;
        reply = (redisReply*)redisCommand(c, "HEXISTS %s %s ", hkey, key);
        if (reply->integer)return true;
        return false;

    }

    void FlushDB(int n) {

        redisReply* reply;
        reply = (redisReply*)redisCommand(c, "SELECT %d", n);
        RD_CHECK(reply);
        freeReplyObject(reply);

        reply = (redisReply*)redisCommand(c, "FLUSHDB");
        RD_CHECK(reply);
        freeReplyObject(reply);

    }


    void hpushf(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...)
    {
        char message[512] = { 0 };
        va_list args;
        va_start(args, fmt);
        vsprintf_s(message, fmt, args);
        va_end(args);

        char key[128] = { 0 };
        sprintf_s(key, "%s:%d %s ", file, line, log_label(level));


        RD_CHECK( ((redisReply*) redisCommand(c, "HMSET ALLOCATE_LOG  %s  %s", key,message)) );



    }

    void hpush(const  char* file, int line, enum LOG_LEVEL level, const  char* rep)
    {

        char key[128] = { 0 };
        sprintf_s(key, "%s:%d %s ", file, line, log_label(level));


        RD_CHECK(((redisReply*)redisCommand(c, "HMSET ALLOCATE_LOG  %s  %s", rep,key)));



    }




};


static RedisLogger rlog;

#define log_redis(...)   rlog.hpushf(__FILE__, __LINE__, LOG_TRACE, __VA_ARGS__)

#endif



/// <summary>
/// interface
/// </summary>
namespace  vkmm {
    VkResult CreateAllocator(
        const AllocatorCreateInfo* pCreateInfo,
        Allocator* pAllocator)
    {
        assert(pCreateInfo && pAllocator);
        *pAllocator = vkmm_new(pCreateInfo->pAllocationCallbacks, Allocator_T)(pCreateInfo);
        return (*pAllocator)->Init(pCreateInfo);
    }


    VkResult MapMemory(
        Allocator allocator,
        Allocation allocation,
        void** ppData)
    {
        assert(allocator && allocation && ppData);

        //VMA_DEBUG_GLOBAL_MUTEX_LOCK

        VkResult res = allocator->Map(allocation, ppData);

        return res;
    }

    void UnmapMemory(
        Allocator allocator,
        Allocation allocation)
    {
        assert(allocator && allocation);
        //VMA_DEBUG_GLOBAL_MUTEX_LOCK
        allocator->Unmap(allocation);

    }

};
/// <summary>
/// vector
/// </summary>
namespace  vkmm {



    template<typename T, typename allocatorT>
    static void VectorRemove(VkmmVector<T, allocatorT>& vec, size_t index)
    {
        vec.erase(vec.begin() + index);
     
    }

    template<typename CmpLess, typename VectorT>
    bool VectorRemoveSorted(VectorT& v,typename VectorT::value_type& value)
    {
        CmpLess comparator;
            auto it = find(v.begin(), v.end(), value);
            if (it != v.end())
            {
#ifdef USE_HIREDIS
                rlog.hpush(__FILE__, __LINE__, LOG_TRACE, value.__rep__(true));
#endif
              // v.erase(it);
                return true;
            }
         
            /*
        typename VectorT::iterator it = BinaryFindFirstNotLess(
            vector.begin(),
            vector.end(),
            value,
            comparator);
  
        if ((it != vector.end()) && !comparator(*it, value) && !comparator(value, *it))
        {
#ifdef USE_HIREDIS
            rlog.hpush(__FILE__, __LINE__, LOG_TRACE,value->__rep__(true));
#endif
            size_t indexToRemove = it - vector.begin();
            VectorRemove(vector, indexToRemove);
            return true;
        }
                  */
        return false;
    }

    template<typename T, typename allocatorT>
    static void VectorInsert(VkmmVector<T, allocatorT>& vec, size_t index, const T& item)
    {
        vec.insert(vec.begin() + index, item);
#ifdef USE_HIREDIS
        rlog.hpush(__FILE__, __LINE__, LOG_TRACE,item.__rep__());
#endif

    }

    template <typename CmpLess, typename IterT, typename KeyT>
    static IterT BinaryFindFirstNotLess(IterT beg, IterT end, const KeyT& key, CmpLess cmp)
    {
        size_t down = 0, up = (end - beg);
        while (down < up)
        {
            const size_t mid = (down + up) / 2;
            if (cmp(*(beg + mid), key))
            {
                down = mid + 1;
            }
            else
            {
                up = mid;
            }
        }
        return beg + down;
    }

    template<typename CmpLess, typename VectorT>
    size_t VectorInsertSorted(VectorT& vector, const typename VectorT::value_type& value)
    {
        
        const size_t indexToInsert = BinaryFindFirstNotLess(
            vector.data(),
            vector.data() + vector.size(),
            value,
            CmpLess()) - vector.data();
        
        VectorInsert(vector, indexToInsert, value);
        return indexToInsert;
    }

};
/// <summary>
/// utils
/// </summary>
namespace vkmm {
    /*
    for (int e = 0; e < 63; e++) {
        UINT64   u = 1ULL << (UINT64)e;
        printf("\n power  %d  VALUE OF: %zu  \n", e, u);
        printbits(u);

        long long  i = 1LL << (long long)e;
        printf("\n power  %d  VALUE OF: %zd  \n", e, i);
        printbits(i);
        printf("\n power  %d  Negative VALUE OF: %zd \n", e, (~i) + 1);
        auto ni = (~i) + 1;
        printbits(ni);

    }*/

    template<typename P,typename T>
    void append_pNext(P& parent,T& child)
    {

        struct ExtensionHeader 
        {
            VkStructureType sType;
            void* pNext;
        };

        auto last = (ExtensionHeader*)&parent;
        while (last->pNext != nullptr)last = (ExtensionHeader*)last->pNext;
        last->pNext = &child;

    }

    template<typename T>
    void _printbits(T number, unsigned int num_bits_to_print)
    {
        if (number || num_bits_to_print > 0) {
            _printbits(number >> (T)1, num_bits_to_print - 1);
            printf("%d", ((int)number) & 1);
        }
    }
    template<typename T>
    void printbits(T number)
    {
        if (number < 0) {
            printf(" Negative Binary : You should use unsigned type.\n");
            return;
        };

        printf("0B");
        _printbits(number, 8 * sizeof(T));
        printf("\n");

    }



    static inline uint32_t CountBitsSet(uint32_t v)
    {
        uint32_t c = v - ((v >> 1) & 0x55555555);
        c = ((c >> 2) & 0x33333333) + (c & 0x33333333);
        c = ((c >> 4) + c) & 0x0F0F0F0F;
        c = ((c >> 8) + c) & 0x00FF00FF;
        c = ((c >> 16) + c) & 0x0000FFFF;
        return c;
    }


    VkResult FindMemoryTypeIndex(
        Allocator allocator,
        uint32_t memoryTypeBits,
        AllocationCreateInfo* pAllocationCreateInfo,
        uint32_t* pMemoryTypeIndex)
    {
        assert(allocator != VK_NULL_HANDLE);
        assert(pAllocationCreateInfo != nullptr);
        assert(pMemoryTypeIndex != nullptr);

        if (pAllocationCreateInfo->memoryTypeBits != 0)
        {
            memoryTypeBits &= pAllocationCreateInfo->memoryTypeBits;
        }

        uint32_t requiredFlags = pAllocationCreateInfo->requiredFlags;
        uint32_t preferredFlags = pAllocationCreateInfo->preferredFlags;

        const bool mapped = (pAllocationCreateInfo->flags & ALLOCATION_CREATE_MAPPED_BIT) != 0;
        if (mapped)
        {
            preferredFlags |= VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;
        }

        // Convert usage to requiredFlags and preferredFlags.
        switch (pAllocationCreateInfo->usage)
        {
        case MEMORY_USAGE_UNKNOWN:
            break;
        case MEMORY_USAGE_GPU_ONLY:
            if (!allocator->IsIntegratedGpu() || (preferredFlags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) == 0)
            {
                requiredFlags |= VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
            }
            break;

        case MEMORY_USAGE_GPU:
            if (!allocator->IsIntegratedGpu() || (preferredFlags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) == 0)
            {
                preferredFlags |= VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
            }
            break;
        case MEMORY_USAGE_CPU_ONLY:
            requiredFlags |= VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
            break;
        case MEMORY_USAGE_CPU_TO_GPU:
            requiredFlags |= VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;
            if ( (pAllocationCreateInfo->flags & ALLOCATION_CREATE_MAPPED_BIT) == 0) {
                pAllocationCreateInfo->flags |= ALLOCATION_CREATE_MAPPED_BIT;
            }
            if (!allocator->IsIntegratedGpu() || (preferredFlags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) == 0)
            {
                preferredFlags |= VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
            }
            break;
        case MEMORY_USAGE_GPU_TO_CPU:
            requiredFlags |= VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;
            preferredFlags |= VK_MEMORY_PROPERTY_HOST_COHERENT_BIT | VK_MEMORY_PROPERTY_HOST_CACHED_BIT;
            break;
        default:
            break;
        }

        /*
        printf("memTypeBit Request  ");
        printbits(memoryTypeBits);

        printf("memTypeBit Require  ");
        printbits(requiredFlags);

        printf("memTypeBit Prefered  ");
        printbits(preferredFlags);

        for (uint32_t memTypeIndex = 0, memTypeBit = 1;
            memTypeIndex < allocator->GetMemoryTypeCount();
            ++memTypeIndex, memTypeBit <<= 1)
        {
            // This memory type is acceptable according to memoryTypeBits bitmask.
            printf("memTypeBit[%d]     ", memTypeIndex);
            printbits(memTypeBit);
            printf(" propFlags .ex{Cache | Coherent | Visible|  DeviceLocal ,None}  [%d]   ", memTypeIndex);
            printbits(allocator->m_MemProps.memoryTypes[memTypeIndex].propertyFlags);

        }
        */
        *pMemoryTypeIndex = UINT32_MAX;
        uint32_t minCost = UINT32_MAX;
        for (uint32_t memTypeIndex = 0, memTypeBit = 1;
            memTypeIndex < allocator->GetMemoryTypeCount();
            ++memTypeIndex, memTypeBit <<= 1)
        {

            if ((memTypeBit & memoryTypeBits) != 0)
            {
                const VkMemoryPropertyFlags currFlags =
                    allocator->m_MemProps.memoryTypes[memTypeIndex].propertyFlags;
                // This memory type contains requiredFlags.
                if ((requiredFlags & ~currFlags) == 0)
                {
                    // Calculate cost as number of bits from preferredFlags not present in this memory type.
                    uint32_t currCost = CountBitsSet(preferredFlags & ~currFlags);
                    // Remember memory type with lowest cost.
                    if (currCost < minCost)
                    {
                        *pMemoryTypeIndex = memTypeIndex;
                        if (currCost == 0)
                        {
                            return VK_SUCCESS;
                        }
                        minCost = currCost;
                    }
                }
            }
        }
        return (*pMemoryTypeIndex != UINT32_MAX) ? VK_SUCCESS : VK_ERROR_FEATURE_NOT_PRESENT;
    }

    void Allocation_T::FreeUserDataString(Allocator hAllocator)
    {
        assert(IsUserDataString());
        if (m_pUserData != nullptr)
        {
            char* const oldStr = (char*)m_pUserData;
            const size_t oldStrLen = strlen(oldStr);
            Delete_array(hAllocator, oldStr, oldStrLen + 1);
            m_pUserData = nullptr;
        }
    }
    void Allocation_T::SetUserData(Allocator hAllocator, void* pUserData)
    {
        if (IsUserDataString())
        {
            assert(pUserData == nullptr || pUserData != m_pUserData);

            FreeUserDataString(hAllocator);

            if (pUserData != nullptr)
            {
                const char* const newStrSrc = (char*)pUserData;
                const size_t newStrLen = strlen(newStrSrc);
                char* const newStrDst = vkmm_new_array(hAllocator, char, newStrLen + 1);
                memcpy(newStrDst, newStrSrc, newStrLen + 1);
                m_pUserData = newStrDst;
            }
        }
        else
        {
            m_pUserData = pUserData;
        }
    }
    void Allocator_T::GetAllocationInfo(Allocation hAllocation, AllocationInfo* pAllocationInfo)
    {
        if (hAllocation->CanBecomeLost())
        {
            /*
            Warning: This is a carefully designed algorithm.
            Do not modify unless you really know what you're doing :)
            */
            const uint32_t localCurrFrameIndex = m_CurrentFrameIndex.load();
            uint32_t localLastUseFrameIndex = hAllocation->GetLastUseFrameIndex();
            for (;;)
            {
                if (localLastUseFrameIndex == FRAME_INDEX_LOST)
                {
                    pAllocationInfo->memoryType = UINT32_MAX;
                    pAllocationInfo->deviceMemory = VK_NULL_HANDLE;
                    pAllocationInfo->offset = 0;
                    pAllocationInfo->size = hAllocation->GetSize();
                    pAllocationInfo->pMappedData = nullptr;
                    pAllocationInfo->pUserData = hAllocation->GetUserData();
                    return;
                }
                else if (localLastUseFrameIndex == localCurrFrameIndex)
                {
                    pAllocationInfo->memoryType = hAllocation->GetMemoryTypeIndex();
                    pAllocationInfo->deviceMemory = hAllocation->GetMemory();
                    pAllocationInfo->offset = hAllocation->GetOffset();
                    pAllocationInfo->size = hAllocation->GetSize();
                    pAllocationInfo->pMappedData = nullptr;
                    pAllocationInfo->pUserData = hAllocation->GetUserData();
                    return;
                }
                else // Last use time earlier than current time.
                {
                    if (hAllocation->CompareExchangeLastUseFrameIndex(localLastUseFrameIndex, localCurrFrameIndex))
                    {
                        localLastUseFrameIndex = localCurrFrameIndex;
                    }
                }
            }
        }
        else
        {


            pAllocationInfo->memoryType = hAllocation->GetMemoryTypeIndex();
            pAllocationInfo->deviceMemory = hAllocation->GetMemory();
            pAllocationInfo->offset = hAllocation->GetOffset();
            pAllocationInfo->size = hAllocation->GetSize();
            pAllocationInfo->pMappedData = hAllocation->GetMappedData();
            pAllocationInfo->pUserData = hAllocation->GetUserData();
        }
    }
    void Allocator_T::FillAllocation(const Allocation hAllocation, uint8_t pattern)
    {
        if (_DEBUG_INITIALIZE_ALLOCATIONS &&
            !hAllocation->CanBecomeLost() &&
            (m_MemProps.memoryTypes[hAllocation->GetMemoryTypeIndex()].propertyFlags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) != 0)
        {
            void* pData = nullptr;
            VkResult res = Map(hAllocation, &pData);
            if (res == VK_SUCCESS)
            {
                memset(pData, (int)pattern, (size_t)hAllocation->GetSize());
                FlushOrInvalidateAllocation(hAllocation, 0, VK_WHOLE_SIZE, CACHE_FLUSH);
                Unmap(hAllocation);
            }
            else
            {
                assert(0 && "VMA_DEBUG_INITIALIZE_ALLOCATIONS is enabled, but couldn't map memory to fill allocation.");
            }
        }
    }
    bool Allocator_T::TouchAllocation(Allocation hAllocation)
    {
        // This is a stripped-down version of VmaAllocator_T::GetAllocationInfo.
        if (hAllocation->CanBecomeLost())
        {
            uint32_t localCurrFrameIndex = m_CurrentFrameIndex.load();
            uint32_t localLastUseFrameIndex = hAllocation->GetLastUseFrameIndex();
            for (;;)
            {
                if (localLastUseFrameIndex == FRAME_INDEX_LOST)
                {
                    return false;
                }
                else if (localLastUseFrameIndex == localCurrFrameIndex)
                {
                    return true;
                }
                else // Last use time earlier than current time.
                {
                    if (hAllocation->CompareExchangeLastUseFrameIndex(localLastUseFrameIndex, localCurrFrameIndex))
                    {
                        localLastUseFrameIndex = localCurrFrameIndex;
                    }
                }
            }
        }
        else
        {


            return true;
        }
    }

    void Allocator_T::FlushOrInvalidateAllocation(
        Allocation hAllocation,
        VkDeviceSize offset, VkDeviceSize size,
        CACHE_OPERATION op)
    {
        const uint32_t memTypeIndex = hAllocation->GetMemoryTypeIndex();
        if (size > 0 && IsMemoryTypeNonCoherent(memTypeIndex))
        {
            const VkDeviceSize allocationSize = hAllocation->GetSize();
            assert(offset <= allocationSize);

            const VkDeviceSize nonCoherentAtomSize = m_PhysicalDeviceProperties.limits.nonCoherentAtomSize;

            VkMappedMemoryRange memRange = { VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE };
            memRange.memory = hAllocation->GetMemory();

            switch (hAllocation->GetType())
            {
            case Allocation_T::ALLOCATION_TYPE_DEDICATED:
                memRange.offset = AlignDown(offset, nonCoherentAtomSize);
                if (size == VK_WHOLE_SIZE)
                {
                    memRange.size = allocationSize - memRange.offset;
                }
                else
                {
                    assert(offset + size <= allocationSize);
                    memRange.size = __min(
                        AlignUp(size + (offset - memRange.offset), nonCoherentAtomSize),
                        allocationSize - memRange.offset);
                }
                break;

            case Allocation_T::ALLOCATION_TYPE_BLOCK:
            {
                /* COM
                // 1. Still within this allocation.
                memRange.offset = AlignDown(offset, nonCoherentAtomSize);
                if (size == VK_WHOLE_SIZE)
                {
                    size = allocationSize - offset;
                }
                else
                {
                    assert(offset + size <= allocationSize);
                }
                memRange.size = AlignUp(size + (offset - memRange.offset), nonCoherentAtomSize);

                // 2. Adjust to whole block.
                const VkDeviceSize allocationOffset = hAllocation->GetOffset();
                assert(allocationOffset % nonCoherentAtomSize == 0);
                const VkDeviceSize blockSize = hAllocation->GetBlock()->m_pMetadata->GetSize();
                memRange.offset += allocationOffset;
                memRange.size = __min(memRange.size, blockSize - memRange.offset);

                break;
                */
            }

            default:
                assert(0);
            }

            switch (op)
            {
            case CACHE_FLUSH:
                vkFlushMappedMemoryRanges(m_hDevice, 1, &memRange);
                break;
            case CACHE_INVALIDATE:
                vkInvalidateMappedMemoryRanges(m_hDevice, 1, &memRange);
                break;
            default:
                assert(0);
            }
        }
        // else: Just ignore this call.
    }

    bool Allocation_T::CanBecomeLost() const
    {
        switch (m_Type)
        {
        case ALLOCATION_TYPE_BLOCK:
            return m_BlockAllocation.m_CanBecomeLost;
        case ALLOCATION_TYPE_DEDICATED:
            return false;
        default:
            assert(0);
            return false;
        }

    }

    VkDeviceSize Allocation_T::GetOffset() const
    {
        switch (m_Type)
        {
        case ALLOCATION_TYPE_BLOCK:
            ///COM return m_BlockAllocation.m_Offset;
        case ALLOCATION_TYPE_DEDICATED:
            return 0;
        default:
           assert(0);
            return 0;
        }
    }

    VkDeviceMemory Allocation_T::GetMemory() const
    {
        switch (m_Type)
        {
        case ALLOCATION_TYPE_BLOCK:
            ///COM return m_BlockAllocation.m_Block->GetDeviceMemory();
        case ALLOCATION_TYPE_DEDICATED:
            return m_DedicatedAllocation.m_hMemory;
        default:
            assert(0);
            return VK_NULL_HANDLE;
        }
    }

    uint32_t Allocation_T::GetMemoryTypeIndex() const
    {
        switch (m_Type)
        {
        case ALLOCATION_TYPE_BLOCK:
            ///COM return m_BlockAllocation.m_Block->GetMemoryTypeIndex();
        case ALLOCATION_TYPE_DEDICATED:
            return m_DedicatedAllocation.m_MemoryTypeIndex;
        default:
            assert(0);
            return UINT32_MAX;
        }
    }

    void* Allocation_T::GetMappedData() const
    {
        switch (m_Type)
        {
        case ALLOCATION_TYPE_BLOCK:
            /*COM 
            if (m_MapCount != 0)
            {
                void* pBlockData = m_BlockAllocation.m_Block->GetMappedData();
                VMA_ASSERT(pBlockData != VMA_NULL);
                return (char*)pBlockData + m_BlockAllocation.m_Offset;
            }
            else
            {
                return VMA_NULL;
            }
            */
            break;
        case ALLOCATION_TYPE_DEDICATED:
            assert((m_DedicatedAllocation.m_pMappedData != nullptr) == (m_MapCount != 0));
            return m_DedicatedAllocation.m_pMappedData;
        default:
            assert(0);
            return nullptr;
        }
        return nullptr;
    }

}

/// <summary>
/// vulkan
/// </summary>
namespace vkmm {

    static front::tbbALMap asmap;

    VkResult Allocator_T::BindBufferMemory(Allocation hAllocation, VkBuffer hBuffer)
    {
        VkResult res = VK_SUCCESS;
        switch (hAllocation->GetType())
        {
        case Allocation_T::ALLOCATION_TYPE_DEDICATED:
            res = vkBindBufferMemory(
                m_hDevice,
                hBuffer,
                hAllocation->GetMemory(),
                0); //memoryOffset
            break;

        case Allocation_T::ALLOCATION_TYPE_BLOCK:
        {
            /*
            VmaDeviceMemoryBlock* pBlock = hAllocation->GetBlock();
            VMA_ASSERT(pBlock && "Binding buffer to allocation that doesn't belong to any block. Is the allocation lost?");
            res = pBlock->BindBufferMemory(this, hAllocation, hBuffer);
            */
            break;
        }
        default:
            assert(0);
        }
        return res;
    }

    VkResult Allocator_T::Map(Allocation hAllocation, void** ppData)
    {
        if (hAllocation->CanBecomeLost())
        {
            return VK_ERROR_MEMORY_MAP_FAILED;
        }

        switch (hAllocation->GetType())
        {
        case Allocation_T::ALLOCATION_TYPE_BLOCK:
        {
            /*COM
            DeviceMemoryBlock* const pBlock = hAllocation->GetBlock();
            char* pBytes = VMA_NULL;
            VkResult res = pBlock->Map(this, 1, (void**)&pBytes);
            if (res == VK_SUCCESS)
            {
                *ppData = pBytes + (ptrdiff_t)hAllocation->GetOffset();
                hAllocation->BlockAllocMap();
            }
            return res;
            */
        }
        case Allocation_T::ALLOCATION_TYPE_DEDICATED:
            return hAllocation->DedicatedAllocMap(this, ppData);
        default:
            assert(0);
            return VK_ERROR_MEMORY_MAP_FAILED;
        }
    }

    void Allocator_T::Unmap(Allocation hAllocation)
    {
        switch (hAllocation->GetType())
        {
        case Allocation_T::ALLOCATION_TYPE_BLOCK:
        {
            /*
            VmaDeviceMemoryBlock* const pBlock = hAllocation->GetBlock();
            hAllocation->BlockAllocUnmap();
            pBlock->Unmap(this, 1);
            */
        }
        break;
        case Allocation_T::ALLOCATION_TYPE_DEDICATED:
            hAllocation->DedicatedAllocUnmap(this);
            break;
        default:
            assert(0);
        }
    }

    VkResult CreateBuffer(
        Allocator allocator,
        const VkBufferCreateInfo* pBufferCreateInfo,
         AllocationCreateInfo& pAllocationCreateInfo,
        VkBuffer* pBuffer,
        Allocation* pAllocation,
        AllocationInfo* pAllocationInfo)
    {
        assert(allocator && pBufferCreateInfo && &pAllocationCreateInfo && pBuffer && pAllocation);
        ///VMA_DEBUG_GLOBAL_MUTEX_LOCK

        *pBuffer = VK_NULL_HANDLE;
        *pAllocation = VK_NULL_HANDLE;
        VkResult res = vkCreateBuffer(
            allocator->m_hDevice,
            pBufferCreateInfo,
            allocator->GetAllocationCallbacks(),
            pBuffer);
        if (res >= 0)
        {

            VkMemoryRequirements vkMemReq = {};
            bool requiresDedicatedAllocation = false;
            bool prefersDedicatedAllocation = false;
            allocator->GetBufferMemoryRequirements(*pBuffer, vkMemReq,
                requiresDedicatedAllocation, prefersDedicatedAllocation);

            if ((pBufferCreateInfo->usage & VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT) != 0)
            {
                assert(vkMemReq.alignment %
                    allocator->m_PhysicalDeviceProperties.limits.minTexelBufferOffsetAlignment == 0);
            }
            if ((pBufferCreateInfo->usage & VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT) != 0)
            {
                assert(vkMemReq.alignment %
                    allocator->m_PhysicalDeviceProperties.limits.minUniformBufferOffsetAlignment == 0);
            }
            if ((pBufferCreateInfo->usage & VK_BUFFER_USAGE_STORAGE_BUFFER_BIT) != 0)
            {
                assert(vkMemReq.alignment %
                    allocator->m_PhysicalDeviceProperties.limits.minStorageBufferOffsetAlignment == 0);
            }

            
            if ((pBufferCreateInfo->usage & VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT) != 0) {
                VkMemoryAllocateFlagsInfo* info = nullptr;
                pAllocationCreateInfo.info.append(info);
                info->deviceMask = 0;
                info->flags = VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT | VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_CAPTURE_REPLAY_BIT;
            }
            

           

            res = allocator->AllocateMemory(
                vkMemReq,
                requiresDedicatedAllocation,
                prefersDedicatedAllocation,
                *pBuffer,
                VK_NULL_HANDLE,
                pAllocationCreateInfo,
                SUBALLOCATION_TYPE_BUFFER,
                pAllocation);

            if (res >= 0)
            {

                res = allocator->BindBufferMemory(*pAllocation, *pBuffer);
                if (res >= 0)
                {

#if VMA_STATS_STRING_ENABLED
                    (*pAllocation)->InitBufferImageUsage(pBufferCreateInfo->usage);
#endif
                    if (pAllocationInfo != nullptr)
                    {
                        allocator->GetAllocationInfo(*pAllocation, pAllocationInfo);
                    }

                    return VK_SUCCESS;
                }

                allocator->FreeMemory(*pAllocation);
                *pAllocation = VK_NULL_HANDLE;
                vkDestroyBuffer(allocator->m_hDevice, *pBuffer, allocator->GetAllocationCallbacks());
                *pBuffer = VK_NULL_HANDLE;
                return res;
            }

            vkDestroyBuffer(allocator->m_hDevice, *pBuffer, allocator->GetAllocationCallbacks());
            *pBuffer = VK_NULL_HANDLE;
            return res;
        }
        return res;
    }

    void DestroyBuffer(
        Allocator allocator,
        VkBuffer buffer,
        Allocation allocation)
    {

        assert(allocator);
        if (buffer == VK_NULL_HANDLE && allocation == VK_NULL_HANDLE)
        {
            return;
        }

        VKMM_DEBUG_LOG("DestroyBuffer");

        /// VKMM_DEBUG_GLOBAL_MUTEX_LOCK

        if (buffer != VK_NULL_HANDLE)
        {
            vkDestroyBuffer(allocator->m_hDevice, buffer, allocator->GetAllocationCallbacks());
        }

        if (allocation != VK_NULL_HANDLE)
        {
            allocator->FreeMemory(allocation);
        }
    }

    void Allocator_T::FreeVulkanMemory(uint32_t memoryType, VkDeviceSize size, VkDeviceMemory hMemory)
    {
        if (m_DeviceMemoryCallbacks.pfnFree != nullptr)
        {
            (*m_DeviceMemoryCallbacks.pfnFree)(this, memoryType, hMemory, size);
        }

        vkFreeMemory(m_hDevice, hMemory, GetAllocationCallbacks());

        const uint32_t heapIndex = MemoryTypeIndexToHeapIndex(memoryType);
        if (m_HeapSizeLimit[heapIndex] != VK_WHOLE_SIZE)
        {
            //VmaMutexLock lock(m_HeapSizeLimitMutex, m_UseMutex);
            m_HeapSizeLimit[heapIndex] += size;
        }
    }

    VkResult  Allocator_T::AllocateVulkanMemory(VkMemoryAllocateInfo* pAllocateInfo, VkDeviceMemory* pMemory)
    {
        const uint32_t heapIndex = MemoryTypeIndexToHeapIndex(pAllocateInfo->memoryTypeIndex);

        VkResult res;
        if (m_HeapSizeLimit[heapIndex] != VK_WHOLE_SIZE)
        {
            ///VmaMutexLock lock(m_HeapSizeLimitMutex, m_UseMutex);
            /// 
            if (m_HeapSizeLimit[heapIndex] >= pAllocateInfo->allocationSize)
            {
                    res = vkAllocateMemory(m_hDevice, pAllocateInfo, GetAllocationCallbacks(), pMemory);
                    if (res == VK_SUCCESS)
                    {
                        m_HeapSizeLimit[heapIndex] -= pAllocateInfo->allocationSize;

                    }
            }
            else
            {
                res = VK_ERROR_OUT_OF_DEVICE_MEMORY;
            }
        }
        else
        {
            res = vkAllocateMemory(m_hDevice, pAllocateInfo, GetAllocationCallbacks(), pMemory);
        }

        if (res == VK_SUCCESS && m_DeviceMemoryCallbacks.pfnAllocate != nullptr)
        {
            (*m_DeviceMemoryCallbacks.pfnAllocate)(this, pAllocateInfo->memoryTypeIndex, *pMemory, pAllocateInfo->allocationSize);
        }

        return res;
    }

    void Allocator_T::GetBufferMemoryRequirements(
        VkBuffer hBuffer,
        VkMemoryRequirements& memReq,
        bool& requiresDedicatedAllocation,
        bool& prefersDedicatedAllocation) const
    {

#if DEDICATED_ALLOCATION
        if (m_UseKhrDedicatedAllocation)
        {
            VkBufferMemoryRequirementsInfo2 memReqInfo = { VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2 };
            memReqInfo.buffer = hBuffer;

            VkMemoryDedicatedRequirements memDedicatedReq = { VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS };

            VkMemoryRequirements2 memReq2 = { VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2 };
            memReq2.pNext = &memDedicatedReq;

            vkGetBufferMemoryRequirements2(m_hDevice, &memReqInfo, &memReq2);

            memReq = memReq2.memoryRequirements;
            requiresDedicatedAllocation = (memDedicatedReq.requiresDedicatedAllocation != VK_FALSE);
            prefersDedicatedAllocation = (memDedicatedReq.prefersDedicatedAllocation != VK_FALSE);

        }
        else
#endif // #if VMA_DEDICATED_ALLOCATION
        {
            vkGetBufferMemoryRequirements(m_hDevice, hBuffer, &memReq);
            requiresDedicatedAllocation = false;
            prefersDedicatedAllocation = false;
        }
    }

    void Allocator_T::FreeDedicatedMemory(Allocation allocation)
    {

        assert(allocation && allocation->GetType() == Allocation_T::ALLOCATION_TYPE_DEDICATED);

        const uint32_t memTypeIndex = allocation->GetMemoryTypeIndex();
        {
            AllocMapTy  pDedicatedAllocations = m_pDedicatedAllocations[memTypeIndex];
            const  int id = allocation->ID;
            AcquireSRWLockExclusive(&slim);
            pDedicatedAllocations.unsafe_erase(id);
            ReleaseSRWLockExclusive(&slim);
        }

        VkDeviceMemory hMemory = allocation->GetMemory();

        if (allocation->GetMappedData() != nullptr)
        {
            vkUnmapMemory(m_hDevice, hMemory);
        }

        FreeVulkanMemory(memTypeIndex, allocation->GetSize(), hMemory);

        VKMM_DEBUG_LOG("    Freed DedicatedMemory MemoryTypeIndex=%u", memTypeIndex);
    }




}
/// <summary>
/// allocate
/// </summary>
namespace  vkmm {

    void* Malloc(Allocator hAllocator, size_t size, size_t alignment)
    {
        return Malloc(&hAllocator->m_AllocationCallbacks, size, alignment);
    }

    void Free(Allocator hAllocator, void* ptr)
    {
        Free(&hAllocator->m_AllocationCallbacks, ptr);
    }

    Allocator_T::Allocator_T(const AllocatorCreateInfo* pCreateInfo) :
        m_UseMutex((pCreateInfo->flags& ALLOCATOR_CREATE_EXTERNALLY_SYNCHRONIZED_BIT) == 0),
        m_UseKhrDedicatedAllocation((pCreateInfo->flags& ALLOCATOR_CREATE_KHR_DEDICATED_ALLOCATION_BIT) != 0),
        m_hDevice($device),
        m_AllocationCallbacksSpecified(pCreateInfo->pAllocationCallbacks != nullptr),
        m_AllocationCallbacks(pCreateInfo->pAllocationCallbacks ?
            *pCreateInfo->pAllocationCallbacks : EmptyAllocationCallbacks),
        m_PreferredLargeHeapBlockSize(0),
        m_PhysicalDevice($physicaldevice),
        m_CurrentFrameIndex(0),
        m_Pools(StlAllocator<Pool>(GetAllocationCallbacks())),
        m_NextPoolId(0)
    {
        m_UseKhrDedicatedAllocation = false;
        InitializeSRWLock(&slim);

#ifdef USE_HIREDIS
        rlog.SetUp();
        rlog.FlushDB(15);
#endif

        if (_DEBUG_DETECT_CORRUPTION)
        {
            // Needs to be multiply of uint32_t size because we are going to write VMA_CORRUPTION_DETECTION_MAGIC_VALUE to it.
            assert(_DEBUG_MARGIN % sizeof(uint32_t) == 0);
        }

        assert($physicaldevice && $device);

#if !(DEDICATED_ALLOCATION)
        if ((pCreateInfo->flags & ALLOCATOR_CREATE_KHR_DEDICATED_ALLOCATION_BIT) != 0)
        {
            assert(0 && "VMA_ALLOCATOR_CREATE_KHR_DEDICATED_ALLOCATION_BIT set but required extensions are disabled by preprocessor macros.");
        }
#endif

        memset(&m_DeviceMemoryCallbacks, 0, sizeof(m_DeviceMemoryCallbacks));
        memset(&m_PhysicalDeviceProperties, 0, sizeof(m_PhysicalDeviceProperties));
        memset(&m_MemProps, 0, sizeof(m_MemProps));

        // memset(&m_pBlockVectors, 0, sizeof(m_pBlockVectors));
       // memset(&m_pDedicatedAllocations, 0, sizeof(m_pDedicatedAllocations));

        for (uint32_t i = 0; i < VK_MAX_MEMORY_HEAPS_MIN; ++i)
        {
            m_HeapSizeLimit[i] = VK_WHOLE_SIZE;
        }

        if (pCreateInfo->pDeviceMemoryCallbacks != nullptr)
        {
            m_DeviceMemoryCallbacks.pfnAllocate = pCreateInfo->pDeviceMemoryCallbacks->pfnAllocate;
            m_DeviceMemoryCallbacks.pfnFree = pCreateInfo->pDeviceMemoryCallbacks->pfnFree;
        }

        ///COM    ImportVulkanFunctions(pCreateInfo->pVulkanFunctions);
        m_PhysicalDeviceProperties = $properties;
        m_MemProps = $memoryProperties;

        m_PreferredLargeHeapBlockSize = (pCreateInfo->preferredLargeHeapBlockSize != 0) ?
            pCreateInfo->preferredLargeHeapBlockSize : static_cast<VkDeviceSize>(_DEFAULT_LARGE_HEAP_BLOCK_SIZE);

        if (pCreateInfo->pHeapSizeLimit != nullptr)
        {
            for (uint32_t heapIndex = 0; heapIndex < GetMemoryHeapCount(); ++heapIndex)
            {
                const VkDeviceSize limit = pCreateInfo->pHeapSizeLimit[heapIndex];
                if (limit != VK_WHOLE_SIZE)
                {
                    m_HeapSizeLimit[heapIndex] = limit;
                    if (limit < m_MemProps.memoryHeaps[heapIndex].size)
                    {
                        m_MemProps.memoryHeaps[heapIndex].size = limit;
                    }
                }
            }
        }



        for (uint32_t memTypeIndex = 0; memTypeIndex < VK_MAX_MEMORY_TYPES_MIN; ++memTypeIndex)
        {
            /*
            const VkDeviceSize preferredBlockSize = CalcPreferredBlockSize(memTypeIndex);
            m_pBlockVectors[memTypeIndex] = vma_new(this, VmaBlockVector)(
                this,
                memTypeIndex,
                preferredBlockSize,
                0,
                SIZE_MAX,
                GetBufferImageGranularity(),
                pCreateInfo->frameInUseCount,
                false, // isCustomPool
                false, // explicitBlockSize
                false); // linearAlgorithm
            */
            // No need to call m_pBlockVectors[memTypeIndex][blockVectorTypeIndex]->CreateMinBlocks here,
            // becase minBlockCount is 0.
            m_pDedicatedAllocations[memTypeIndex] = AllocMapTy();
        }
    }

    VkResult  Allocator_T::Init(const AllocatorCreateInfo* pCreateInfo)
    {
        VkResult res = VK_SUCCESS;

        return res;
    }

    Allocator_T::~Allocator_T()
    {

        ///COM assert(m_Pools.empty());
#ifdef USE_HIREDIS
        rlog.TearDown();
#endif
        for (size_t i = GetMemoryTypeCount(); i--; )
        {
            m_pDedicatedAllocations[i].clear();
            ///COM Delete(this, m_pBlockVectors[i]);
        }
       m_pDedicatedAllocations.clear();
    }




    VkResult Allocator_T::AllocateDedicatedMemory(
        VkDeviceSize size,
        SuballocationType suballocType,
        uint32_t memTypeIndex,
        bool map,
        bool isUserDataString,
        AllocationCreateInfo& createInfo,
        VkBuffer dedicatedBuffer,
        VkImage dedicatedImage,
        Allocation* pAllocation)
    {

        assert(pAllocation);
        createInfo.info.memoryTypeIndex = memTypeIndex;
        bool dedicated = true;
        if (memTypeIndex == 2 || memTypeIndex == 3 || memTypeIndex == 0) {
            if (HOST_VISIBLE_SINGLE_ALLO_MAX < size) {
                log_bad("memory out of range \n");
            }
        }

        if(dedicated) {
                createInfo.info.allocationSize = size;
#if DEDICATED_ALLOCATION
                VkMemoryDedicatedAllocateInfo* dedicatedAllocInfo = nullptr;
                if (m_UseKhrDedicatedAllocation)
                {
                    createInfo.info.append(dedicatedAllocInfo);
                    if (dedicatedBuffer != VK_NULL_HANDLE)
                    {
                        assert(dedicatedImage == VK_NULL_HANDLE);
                        dedicatedAllocInfo->buffer = dedicatedBuffer;
                    }
                    else if (dedicatedImage != VK_NULL_HANDLE)
                    {
                        dedicatedAllocInfo->image = dedicatedImage;
                    }
                }
#endif // #if VMA_DEDICATED_ALLOCATION
                // Allocate VkDeviceMemory.
                VkDeviceMemory hMemory = VK_NULL_HANDLE;
                VkResult res = AllocateVulkanMemory((VkMemoryAllocateInfo*)&createInfo.info, &hMemory);
                if (res < 0)
                {
                    VKMM_DEBUG_LOG("    vkAllocateMemory FAILED");
                    return res;
                }

                void* pMappedData = nullptr;
                if (map)
                {
                    res = vkMapMemory(
                        m_hDevice,
                        hMemory,
                        0,
                        VK_WHOLE_SIZE,
                        0,
                        &pMappedData);
                    if (res < 0)
                    {
                        VKMM_DEBUG_LOG("    vkMapMemory FAILED");
                        FreeVulkanMemory(memTypeIndex, size, hMemory);
                        return res;
                    }
                }

                *pAllocation = vkmm_new(this, Allocation_T)(m_CurrentFrameIndex.load(), isUserDataString);
                (*pAllocation)->InitDedicatedAllocation(memTypeIndex, hMemory, suballocType, pMappedData, size);
        }


        strcpy((*pAllocation)->name, createInfo.name);

        if (_DEBUG_INITIALIZE_ALLOCATIONS)
        {
            FillAllocation(*pAllocation, ALLOCATION_FILL_PATTERN_CREATED);
        }

        {

            GetCTX($ctx)
                $ctx->deb.setObjectName(dedicatedBuffer, createInfo.name);

            AllocMapTy  pDedicatedAllocations = m_pDedicatedAllocations[memTypeIndex];
            pDedicatedAllocations[(*pAllocation)->ID] = (*pAllocation);
        }

        VKMM_DEBUG_LOG("    Allocated DedicatedMemory MemoryTypeIndex=#%u", memTypeIndex);

        return VK_SUCCESS;
    }

    VkResult Allocator_T::AllocateMemoryOfType(
        VkDeviceSize size,
        VkDeviceSize alignment,
        bool dedicatedAllocation,
        VkBuffer dedicatedBuffer,
        VkImage dedicatedImage,
        AllocationCreateInfo& createInfo,
        uint32_t memTypeIndex,
        SuballocationType suballocType,
        Allocation* pAllocation)
    {
        assert(pAllocation != nullptr);

        AllocationCreateInfo& finalCreateInfo = createInfo;

        // If memory type is not HOST_VISIBLE, disable MAPPED.
        if ((finalCreateInfo.flags & ALLOCATION_CREATE_MAPPED_BIT) != 0 &&
            (m_MemProps.memoryTypes[memTypeIndex].propertyFlags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) == 0)
        {
            finalCreateInfo.flags &= ~ALLOCATION_CREATE_MAPPED_BIT;
        }

        /*COM
        VmaBlockVector* const blockVector = m_pBlockVectors[memTypeIndex];
        assert(blockVector);
                const VkDeviceSize preferredBlockSize = blockVector->GetPreferredBlockSize();
        */

        const VkDeviceSize preferredBlockSize = CalcPreferredBlockSize(memTypeIndex);

        bool preferDedicatedMemory =
            _DEBUG_ALWAYS_DEDICATED_MEMORY ||
            dedicatedAllocation ||
            // Heuristics: Allocate dedicated memory if requested size if greater than half of preferred block size.
            size > preferredBlockSize / 2;

        if (preferDedicatedMemory &&
            (finalCreateInfo.flags & ALLOCATION_CREATE_NEVER_ALLOCATE_BIT) == 0 &&
            finalCreateInfo.pool == VK_NULL_HANDLE)
        {
            finalCreateInfo.flags |= ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;
        }

        if ((finalCreateInfo.flags & ALLOCATION_CREATE_DEDICATED_MEMORY_BIT) != 0)
        {
            if ((finalCreateInfo.flags & ALLOCATION_CREATE_NEVER_ALLOCATE_BIT) != 0)
            {
                return VK_ERROR_OUT_OF_DEVICE_MEMORY;
            }
            else
            {
                return AllocateDedicatedMemory(
                    size,
                    suballocType,
                    memTypeIndex,
                    (finalCreateInfo.flags & ALLOCATION_CREATE_MAPPED_BIT) != 0,
                    (finalCreateInfo.flags & ALLOCATION_CREATE_USER_DATA_COPY_STRING_BIT) != 0,
                    finalCreateInfo,
                    dedicatedBuffer,
                    dedicatedImage,
                    pAllocation);
            }
        }
        else
        {
            /*COM
            VkResult res = blockVector->Allocate(
                VK_NULL_HANDLE, // hCurrentPool
                m_CurrentFrameIndex.load(),
                size,
                alignment,
                finalCreateInfo,
                suballocType,
                pAllocation);
            if (res == VK_SUCCESS)
            {
                return res;
            }

            // 5. Try dedicated memory.
            if ((finalCreateInfo.flags & VMA_ALLOCATION_CREATE_NEVER_ALLOCATE_BIT) != 0)
            {
                return VK_ERROR_OUT_OF_DEVICE_MEMORY;
            }
            else
            {
                res = AllocateDedicatedMemory(
                    size,
                    suballocType,
                    memTypeIndex,
                    (finalCreateInfo.flags & VMA_ALLOCATION_CREATE_MAPPED_BIT) != 0,
                    (finalCreateInfo.flags & VMA_ALLOCATION_CREATE_USER_DATA_COPY_STRING_BIT) != 0,
                    finalCreateInfo.pUserData,
                    dedicatedBuffer,
                    dedicatedImage,
                    pAllocation);
                if (res == VK_SUCCESS)
                {
                    // Succeeded: AllocateDedicatedMemory function already filld pMemory, nothing more to do here.
                    VMA_DEBUG_LOG("    Allocated as DedicatedMemory");
                    return VK_SUCCESS;
                }
                else
                {
                    // Everything failed: Return error code.
                    VMA_DEBUG_LOG("    vkAllocateMemory FAILED");
                    return res;
                }
            }
            */
        }

        assert(0);
        return (VkResult)0;

    }


    VkResult Allocator_T::AllocateMemory(
        const VkMemoryRequirements& vkMemReq,
        bool requiresDedicatedAllocation,
        bool prefersDedicatedAllocation,
        VkBuffer dedicatedBuffer,
        VkImage dedicatedImage,
        AllocationCreateInfo& createInfo,
        SuballocationType suballocType,
        Allocation* pAllocation)
    {
        if ((createInfo.flags & ALLOCATION_CREATE_DEDICATED_MEMORY_BIT) != 0 &&
            (createInfo.flags & ALLOCATION_CREATE_NEVER_ALLOCATE_BIT) != 0)
        {
            assert(0 && "Specifying VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT together with VMA_ALLOCATION_CREATE_NEVER_ALLOCATE_BIT makes no sense.");
            return VK_ERROR_OUT_OF_DEVICE_MEMORY;
        }
        if ((createInfo.flags & ALLOCATION_CREATE_MAPPED_BIT) != 0 &&
            (createInfo.flags & ALLOCATION_CREATE_CAN_BECOME_LOST_BIT) != 0)
        {
            assert(0 && "Specifying VMA_ALLOCATION_CREATE_MAPPED_BIT together with VMA_ALLOCATION_CREATE_CAN_BECOME_LOST_BIT is invalid.");
            return VK_ERROR_OUT_OF_DEVICE_MEMORY;
        }

        if (requiresDedicatedAllocation)
        {
            if ((createInfo.flags & ALLOCATION_CREATE_NEVER_ALLOCATE_BIT) != 0)
            {
                assert(0 && "VMA_ALLOCATION_CREATE_NEVER_ALLOCATE_BIT specified while dedicated allocation is required.");
                return VK_ERROR_OUT_OF_DEVICE_MEMORY;
            }
            if (createInfo.pool != VK_NULL_HANDLE)
            {
                assert(0 && "Pool specified while dedicated allocation is required.");
                return VK_ERROR_OUT_OF_DEVICE_MEMORY;
            }
        }

        if ((createInfo.pool != VK_NULL_HANDLE) &&
            ((createInfo.flags & (ALLOCATION_CREATE_DEDICATED_MEMORY_BIT)) != 0))
        {
            assert(0 && "Specifying VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT when pool != null is invalid.");
            return VK_ERROR_OUT_OF_DEVICE_MEMORY;
        }

        if (createInfo.pool != VK_NULL_HANDLE)
        {
            /*/// COM
            const VkDeviceSize alignmentForPool = __max(
                vkMemReq.alignment,
                GetMemoryTypeMinAlignment(createInfo.pool->m_BlockVector.GetMemoryTypeIndex()));
            return createInfo.pool->m_BlockVector.Allocate(
                createInfo.pool,
                m_CurrentFrameIndex.load(),
                vkMemReq.size,
                alignmentForPool,
                createInfo,
                suballocType,
                pAllocation);
            */
        }
        else
        {
            // Bit mask of memory Vulkan types acceptable for this allocation.
            uint32_t memoryTypeBits = vkMemReq.memoryTypeBits;
            uint32_t memTypeIndex = UINT32_MAX;
            VkResult res = FindMemoryTypeIndex(this, memoryTypeBits, &createInfo, &memTypeIndex);
            
            if (res == VK_SUCCESS)
            {
                VkDeviceSize alignmentForMemType = __max(
                    vkMemReq.alignment,
                    GetMemoryTypeMinAlignment(memTypeIndex));

                res = AllocateMemoryOfType(
                    vkMemReq.size,
                    alignmentForMemType,
                    requiresDedicatedAllocation || prefersDedicatedAllocation,
                    dedicatedBuffer,
                    dedicatedImage,
                    createInfo,
                    memTypeIndex,
                    suballocType,
                    pAllocation);
                // Succeeded on first try.
                if (res == VK_SUCCESS)
                {
                    return res;
                }
                // Allocation from this memory type failed. Try other compatible memory types.
                else
                {
                    for (;;)
                    {
                        // Remove old memTypeIndex from list of possibilities.
                        memoryTypeBits &= ~(1u << memTypeIndex);
                        // Find alternative memTypeIndex.
                        res = FindMemoryTypeIndex(this, memoryTypeBits, &createInfo, &memTypeIndex);
                        if (res == VK_SUCCESS)
                        {
                            alignmentForMemType = __max(
                                vkMemReq.alignment,
                                GetMemoryTypeMinAlignment(memTypeIndex));

                            res = AllocateMemoryOfType(
                                vkMemReq.size,
                                alignmentForMemType,
                                requiresDedicatedAllocation || prefersDedicatedAllocation,
                                dedicatedBuffer,
                                dedicatedImage,
                                createInfo,
                                memTypeIndex,
                                suballocType,
                                pAllocation);
                            // Allocation from this alternative memory type succeeded.
                            if (res == VK_SUCCESS)
                            {
                                return res;
                            }
                            // else: Allocation from this memory type failed. Try next one - next loop iteration.
                        }
                        // No other matching memory type index could be found.
                        else
                        {
                            // Not returning res, which is VK_ERROR_FEATURE_NOT_PRESENT, because we already failed to allocate once.
                            return VK_ERROR_OUT_OF_DEVICE_MEMORY;
                        }
                    }
                }
            }
            // Can't find any single memory type maching requirements. res is VK_ERROR_FEATURE_NOT_PRESENT.
            else
                return res;
        }
        assert(0);
        return (VkResult)0;
    }


    void Allocator_T::FreeMemory(const Allocation allocation)
    {
        assert(allocation);

        if (TouchAllocation(allocation))
        {
            if (_DEBUG_INITIALIZE_ALLOCATIONS)
            {
                FillAllocation(allocation, ALLOCATION_FILL_PATTERN_DESTROYED);
            }

            switch (allocation->GetType())
            {
            case Allocation_T::ALLOCATION_TYPE_BLOCK:
            {
                /*COM
                BlockVector* pBlockVector = VMA_NULL;
                Pool hPool = allocation->GetPool();
                if (hPool != VK_NULL_HANDLE)
                {
                    pBlockVector = &hPool->m_BlockVector;
                }
                else
                {
                    const uint32_t memTypeIndex = allocation->GetMemoryTypeIndex();
                    pBlockVector = m_pBlockVectors[memTypeIndex];
                }
                pBlockVector->Free(allocation);
                */
            }
            break;
            case Allocation_T::ALLOCATION_TYPE_DEDICATED:
                FreeDedicatedMemory(allocation);
                break;
            default:
                assert(0);
            }
        }

        vkmm::Delete(this, allocation);
        

    }

    VkResult Allocation_T::DedicatedAllocMap(Allocator hAllocator, void** ppData)
    {
        assert(GetType() == ALLOCATION_TYPE_DEDICATED);

        if (m_MapCount != 0)
        {
            if ((m_MapCount & ~MAP_COUNT_FLAG_PERSISTENT_MAP) < 0x7F)
            {
                assert(m_DedicatedAllocation.m_pMappedData != nullptr);
                *ppData = m_DedicatedAllocation.m_pMappedData;
                //++m_MapCount;
                m_MapCount = 1;
                return VK_SUCCESS;
            }
            else
            {
                assert(0 && "Dedicated allocation mapped too many times simultaneously.");
                return VK_ERROR_MEMORY_MAP_FAILED;
            }
        }
        else
        {
            VkResult result = vkMapMemory(
                hAllocator->m_hDevice,
                m_DedicatedAllocation.m_hMemory,
                0, // offset
                VK_WHOLE_SIZE,
                0, // flags
                ppData);
            if (result == VK_SUCCESS)
            {
                m_DedicatedAllocation.m_pMappedData = *ppData;
                m_MapCount = 1;
            }
            return result;
        }
    }
    void Allocation_T::DedicatedAllocUnmap(Allocator hAllocator)
    {
        assert(GetType() == ALLOCATION_TYPE_DEDICATED);

        if ((m_MapCount & ~MAP_COUNT_FLAG_PERSISTENT_MAP) != 0)
        {
            --m_MapCount;
            if (m_MapCount == 0)
            {
                m_DedicatedAllocation.m_pMappedData = nullptr;
                vkUnmapMemory(
                    hAllocator->m_hDevice,
                    m_DedicatedAllocation.m_hMemory);
            }
        }
        else
        {
            log_allo( "Unmapping dedicated allocation not previously mapped.");
        }
    }




}

/// <summary>
/// block
/// </summary>
namespace vkmm {
    VkDeviceSize Allocator_T::CalcPreferredBlockSize(uint32_t memTypeIndex)
    {
        const uint32_t heapIndex = MemoryTypeIndexToHeapIndex(memTypeIndex);
        const VkDeviceSize heapSize = m_MemProps.memoryHeaps[heapIndex].size;
        const bool isSmallHeap = heapSize <= _SMALL_HEAP_MAX_SIZE;  //1GB
        return isSmallHeap ? (heapSize / 8) : m_PreferredLargeHeapBlockSize;
    }
}


namespace front {


    ssize_t front::DeallocatorVk::desType::occupa = 0;

    void Synco::stir_routine() {

    };


    oSyncoTank::oSyncoTank()
        : data{ nullptr }, size{ 0 }
    {}

    void oSyncoTank::flush() {
        if (data != nullptr) {
            for (int i = 0; i < size; i++) {
                delete data[i];
            }
            delete[] data;
            data = nullptr;
        }
        size = 0;

        tankType::type name = FLUSH_TYPE;
        atomicType(name);
        
    };
    oSyncoTank::~oSyncoTank()
    {
        flush();
    }




    const oSyncoTank::tankType oSyncoTank::order(char t, int No) {

        
        for (int i = 0; i < size; i++) {
            const tankType x = *data[i];
 
            if (t == x.name && No == int(x.id - '0')) return x;
        };
        log_bad("your order is invalid.  name %c   id %d  \n", t, No);
        return  *(const tankType*)0;

    };


    void oSyncoTank::print()
    {

        std::for_each_n(data, size, [](const tankType* x) {
            std::cout <<  "name :: " << int(x->name)  << "  id ::"  << int(x->id) << std::endl;
         });

    }

    void DeallocatorVk::Dispatch() {

            if (!PyEval_ThreadsInitialized())
            {
                PyEval_InitThreads();
            }
            
#if LBSTA == 0
            InitializeCriticalSectionAndSpinCount(&killer.sectAlloc, 8000);
            AllocKiller(0, 100);
#else
            killer.size = (ssize_t)LBSTA;
#endif 
            buds.reset();
            desfuture.clear();
            killer.idx = 0;
            nib_end.store(false);
            printf("   killer dispatch  occupa %zd  size %zd  \n", desType::Occupa(),killer.size);
    

            uint32_t fid = AllocFuture();
            desfuture[fid] = std::move(std::async(std::launch::async, &DeallocatorVk::NipInTheBud, this));

        };

    bool DeallocatorVk::NipInTheBud() {


            while (!nib_end.load()) {

                uint32_t idx = buds.nip();
                {
                    const std::lock_guard<std::mutex> lock(mtx_desfuture);
                    if (idx == uint32_t(-1)) {
                        _total++;
                    }
                    else {
                        if (idx != 0 && desfuture[idx].valid()) {
                            bool res = desfuture[idx].get();
                            if (!res) {
                                log_warning("you dont know whether or not nip in the bud.");
                            };
                        }
                        _total++;
                        budsNums.store(budsNums - 1);
                    }
                }
            };

            log_debug("Nip in the Bud  Ternimate.   %u  <>  %u     size  % zu  \n", _total, budsNums.load(), desfuture.size());
            buds.push(12345);
            return true;

        };

    uint32_t DeallocatorVk::AllocFuture() {
            const std::lock_guard<std::mutex> lock(mtx_desfuture);
            desfuture.emplace_back();
            budsNums.store(budsNums + 1);
            return (uint32_t)desfuture.size() - 1;
     };

    bool DeallocatorVk::AllocKiller(ssize_t idx,ssize_t reserve) {

#if LBSTA == 0
        log_allo(" AllocKiller IDX %zd    AllocKiller      %zu  \n", idx,  reserve);
        EnterCriticalSection(&killer.sectAlloc);
        
        if (idx < killer.size) {
            LeaveCriticalSection(&killer.sectAlloc); return true;
        };
     
        killer.size +=  reserve;
        ///killer._.resize(size_t(killer.size));
        desType* tmp = new ((void*)killer._, killer.size * sizeof(desType));
        if (tmp != nullptr) {
            killer._ = tmp;
            tmp = nullptr;
        }
        else {
            LeaveCriticalSection(&sectAlloc);
            log_bad("Killer  failed to allocate. \n");
            return false;
        }

        log_allo(" IDX %zd   AllocKiller   %zu  \n", idx, killer.size);

        LeaveCriticalSection(&sectAlloc);
#endif
        return true;
    };


    void DeallocatorVk::ClearBuds() {


        uint32_t expected  = (uint32_t)desfuture.size()-1;


      
        printf("finalizing  ");
        while (expected != _InterlockedCompareExchange(&buds.produce, expected, expected)) {
             std::this_thread::sleep_for(std::chrono::milliseconds(10));
             printf(".");
        };
 
        while (expected != _InterlockedCompareExchange(&buds.consume, expected, expected)) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
            printf(".");
        };

        printf("            ok\n");

        /*
        for(int i = 1;i<desfuture.size();i++){
            auto& fut = desfuture[i];
            if (fut.valid()){
                 fut.get();
 
            }
            i++;
        };
        */


    };

    void DeallocatorVk::Holocaust() {


             $DSL.destroy();


            if (!nib_end.load() && desfuture.size() > 0) {

                
                ClearBuds();

                nib_end.store(true);
                buds.push(0);
                
                std::this_thread::sleep_for(std::chrono::milliseconds(100));

                uint32_t fin = buds.nip();
                if (!(fin == 12345 ||  fin == 0) ){
                    log_bad("Nip Not at All Buds. total %u   fin   %u    last  %u  \n", _total, fin, budsNums.load());
                }
 

            }


            if (killer.size > 0) {
                ssize_t N = (killer.size > killer.idx) ? killer.idx : killer.size;
                for (ssize_t idx = 0; idx < N; idx++) {
                    ///log_allo("Call kill %zu   \n", idx);
                    if (!KillForce(idx)) {
                        log_bad("killer failed to kill.\n");
                    };
                }
            }

            for (auto& [k, th] : beginThreads) {
                log_info("Holocaust  Close  Threads           %s  \n", k.c_str());
                CloseHandle(th);
            };

#if LBSTA == 0
                delete[] killer._;
                killer._ = nullptr;
                killer.size = 0;
                if (sectAlloc.OwningThread != nullptr) {
                    log_allo("Delete SectionAlloc   this %p \n", sectAlloc.OwningThread);
                    DeleteCriticalSection(&sectAlloc);
                    sectAlloc.OwningThread = nullptr;
                };

#endif 
 
        };

        DeallocatorVk::~DeallocatorVk() {
            ///Holocaust();
        };


        template <class T>
        SyncoTank<T>::SyncoTank()
            : data{ nullptr }, size{ 0 }
        {}

        template <class T>
        SyncoTank<T>::~SyncoTank() {

            std::for_each_n(data, size, [](T& x) {
                x.dealloc();
                });
        }

        template <class T>
        bool SyncoTank<T>::alloc1() {
            T* tmp = (T*)std::realloc(data, ++size * sizeof(T));
            if (tmp != nullptr) {

                data = tmp;
                tmp = nullptr;
                return true;
            }
            return false;
        };

        template <class T>
        void SyncoTank<T>::add(const T& x)/// requires std::copy_constructible<T>
        {
            if (alloc1()) {
                front::asignable(data[size - 1], x);
                print();
            }

        };

        template <class T>
        void SyncoTank<T>::add(const T&& x)/// requires std::copy_constructible<T>
        {
            if (alloc1()) {
                data[size - 1] = x;
                print();
            }

        };

        template <class T>
        void SyncoTank<T>::print()
        {

            std::for_each_n(data, size, [](const T& x) {
                std::cout << x << std::endl;
                });

        };



        void g123(int, char, const std::string&) {}


};


///template struct front::HashedBeef<HB_DEFUALT>;