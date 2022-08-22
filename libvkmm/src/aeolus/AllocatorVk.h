#pragma once


#ifndef ALLOCATOR_VK_H
#define ALLOCATOR_VK_H
#include "pch_mm.h"
#include "working_mm.h"

#ifdef  LOG_NO_allo
#define log_allo(...)
#else
#define log_allo(...) log_out(__FILE__, __LINE__, LOG_INFO, __VA_ARGS__)
#endif



static bool Verbose = true;

#ifndef HARNESS_DEFAULT_MIN_THREADS
#define HARNESS_DEFAULT_MIN_THREADS 1
#endif

static int MinThread = HARNESS_DEFAULT_MIN_THREADS;

#ifndef HARNESS_DEFAULT_MAX_THREADS
#define HARNESS_DEFAULT_MAX_THREADS 4
#endif
static int MaxThread = HARNESS_DEFAULT_MAX_THREADS;

#ifndef NOMINMAX 
#define NOMINMAX // For Windows.h
#endif

#if VK_KHR_get_memory_requirements2 && VK_KHR_dedicated_allocation
#define DEDICATED_ALLOCATION 1
#else
#define DEDICATED_ALLOCATION 0
#endif


namespace front {

        template<typename T, typename do_check_element_state>
        void test_basic_common(const char* str, do_check_element_state)
        {
            T cont;
            const T& ccont(cont);
            CheckEmptyContainerAllocatorE(cont, 1, 0); // one dummy is always allocated
            // bool empty() const;
            ASSERT(ccont.empty(), "Concurrent container is not empty after construction");

            // size_type size() const;
            ASSERT(ccont.size() == 0, "Concurrent container is not empty after construction");

            // size_type max_size() const;
            ASSERT(ccont.max_size() > 0, "Concurrent container max size is invalid");

            //iterator begin();
            //iterator end();
            ASSERT(cont.begin() == cont.end(), "Concurrent container iterators are invalid after construction");
            ASSERT(ccont.begin() == ccont.end(), "Concurrent container iterators are invalid after construction");
            ASSERT(cont.cbegin() == cont.cend(), "Concurrent container iterators are invalid after construction");

            //std::pair<iterator, bool> insert(const value_type& obj);
            std::pair<typename T::iterator, bool> ins = cont.insert(Value<T>::make(1));
            ASSERT(ins.second == true && Value<T>::get(*(ins.first)) == 1, "Element 1 has not been inserted properly");

#if __TBB_CPP11_RVALUE_REF_PRESENT
            test_rvalue_insert<T, do_check_element_state>(1, 2);
#if __TBB_CPP11_VARIADIC_TEMPLATES_PRESENT
            test_emplace_insert<T, do_check_element_state>(1, 2);
#endif // __TBB_CPP11_VARIADIC_TEMPLATES_PRESENT
#endif // __TBB_CPP11_RVALUE_REF_PRESENT

            // bool empty() const;
            ASSERT(!ccont.empty(), "Concurrent container is empty after adding an element");

            // size_type size() const;
            ASSERT(ccont.size() == 1, "Concurrent container size is incorrect");

            std::pair<typename T::iterator, bool> ins2 = cont.insert(Value<T>::make(1));

            if (T::allow_multimapping)
            {
                // std::pair<iterator, bool> insert(const value_type& obj);
                ASSERT(ins2.second == true && Value<T>::get(*(ins2.first)) == 1, "Element 1 has not been inserted properly");

                // size_type size() const;
                ASSERT(ccont.size() == 2, "Concurrent container size is incorrect");

                // size_type count(const key_type& k) const;
                ASSERT(ccont.count(1) == 2, "Concurrent container count(1) is incorrect");
                // std::pair<iterator, iterator> equal_range(const key_type& k);
                std::pair<typename T::iterator, typename T::iterator> range = cont.equal_range(1);
                typename T::iterator it = range.first;
                ASSERT(it != cont.end() && Value<T>::get(*it) == 1, "Element 1 has not been found properly");
                unsigned int count = 0;
                for (; it != range.second; it++)
                {
                    count++;
                    ASSERT(Value<T>::get(*it) == 1, "Element 1 has not been found properly");
                }

                ASSERT(count == 2, "Range doesn't have the right number of elements");
            }
            else
            {
                // std::pair<iterator, bool> insert(const value_type& obj);
                ASSERT(ins2.second == false && ins2.first == ins.first, "Element 1 should not be re-inserted");

                // size_type size() const;
                ASSERT(ccont.size() == 1, "Concurrent container size is incorrect");

                // size_type count(const key_type& k) const;
                ASSERT(ccont.count(1) == 1, "Concurrent container count(1) is incorrect");

                // std::pair<const_iterator, const_iterator> equal_range(const key_type& k) const;
                // std::pair<iterator, iterator> equal_range(const key_type& k);
                std::pair<typename T::iterator, typename T::iterator> range = cont.equal_range(1);
                typename T::iterator it = range.first;
                ASSERT(it != cont.end() && Value<T>::get(*it) == 1, "Element 1 has not been found properly");
                ASSERT(++it == range.second, "Range doesn't have the right number of elements");
            }

            // const_iterator find(const key_type& k) const;
            // iterator find(const key_type& k);
            typename T::iterator it = cont.find(1);
            ASSERT(it != cont.end() && Value<T>::get(*(it)) == 1, "Element 1 has not been found properly");
            ASSERT(ccont.find(1) == it, "Element 1 has not been found properly");

            // Will be implemented in unordered containers later
#if !__TBB_UNORDERED_TEST
    //bool contains(const key_type&k) const
            ASSERT(cont.contains(1), "contains() cannot detect existing element");
            ASSERT(!cont.contains(0), "contains() detect not existing element");
#endif /*__TBB_UNORDERED_TEST*/

            // iterator insert(const_iterator hint, const value_type& obj);
            typename T::iterator it2 = cont.insert(ins.first, Value<T>::make(2));
            ASSERT(Value<T>::get(*it2) == 2, "Element 2 has not been inserted properly");

            // T(const T& _Umap)
            T newcont = ccont;
            ASSERT(T::allow_multimapping ? (newcont.size() == 3) : (newcont.size() == 2), "Copy construction has not copied the elements properly");

            // this functionality not implemented yet
            // size_type unsafe_erase(const key_type& k);
            typename T::size_type size = cont.unsafe_erase(1);
            ASSERT(T::allow_multimapping ? (size == 2) : (size == 1), "Erase has not removed the right number of elements");

            // iterator unsafe_erase(iterator position);
            typename T::iterator it4 = cont.unsafe_erase(cont.find(2));
            ASSERT(it4 == cont.end() && cont.size() == 0, "Erase has not removed the last element properly");

            // iterator unsafe_erase(const_iterator position);
            cont.insert(Value<T>::make(3));
            typename T::iterator it5 = cont.unsafe_erase(cont.cbegin());
            ASSERT(it5 == cont.end() && cont.size() == 0, "Erase has not removed the last element properly");

            // template<class InputIterator> void insert(InputIterator first, InputIterator last);
            cont.insert(newcont.begin(), newcont.end());
            ASSERT(T::allow_multimapping ? (cont.size() == 3) : (cont.size() == 2), "Range insert has not copied the elements properly");

            // this functionality not implemented yet
            // iterator unsafe_erase(const_iterator first, const_iterator last);
            std::pair<typename T::iterator, typename T::iterator> range2 = newcont.equal_range(1);
            newcont.unsafe_erase(range2.first, range2.second);
            ASSERT(newcont.size() == 1, "Range erase has not erased the elements properly");

            // void clear();
            newcont.clear();
            ASSERT(newcont.begin() == newcont.end() && newcont.size() == 0, "Clear has not cleared the container");

#if __TBB_INITIALIZER_LISTS_PRESENT
#if __TBB_CPP11_INIT_LIST_TEMP_OBJS_LIFETIME_BROKEN
            REPORT("Known issue: the test for insert with initializer_list is skipped.\n");
#else
            // void insert(const std::initializer_list<value_type> &il);
            newcont.insert({ Value<T>::make(1), Value<T>::make(2), Value<T>::make(1) });
            if (T::allow_multimapping) {
                ASSERT(newcont.size() == 3, "Concurrent container size is incorrect");
                ASSERT(newcont.count(1) == 2, "Concurrent container count(1) is incorrect");
                ASSERT(newcont.count(2) == 1, "Concurrent container count(2) is incorrect");
                std::pair<typename T::iterator, typename T::iterator> range = cont.equal_range(1);
                it = range.first;
                ASSERT(it != newcont.end() && Value<T>::get(*it) == 1, "Element 1 has not been found properly");
                unsigned int count = 0;
                for (; it != range.second; it++) {
                    count++;
                    ASSERT(Value<T>::get(*it) == 1, "Element 1 has not been found properly");
                }
                ASSERT(count == 2, "Range doesn't have the right number of elements");
                range = newcont.equal_range(2); it = range.first;
                ASSERT(it != newcont.end() && Value<T>::get(*it) == 2, "Element 2 has not been found properly");
                count = 0;
                for (; it != range.second; it++) {
                    count++;
                    ASSERT(Value<T>::get(*it) == 2, "Element 2 has not been found properly");
                }
                ASSERT(count == 1, "Range doesn't have the right number of elements");
            }
            else {
                ASSERT(newcont.size() == 2, "Concurrent container size is incorrect");
                ASSERT(newcont.count(1) == 1, "Concurrent container count(1) is incorrect");
                ASSERT(newcont.count(2) == 1, "Concurrent container count(2) is incorrect");
                std::pair<typename T::iterator, typename T::iterator> range = newcont.equal_range(1);
                it = range.first;
                ASSERT(it != newcont.end() && Value<T>::get(*it) == 1, "Element 1 has not been found properly");
                ASSERT(++it == range.second, "Range doesn't have the right number of elements");
                range = newcont.equal_range(2); it = range.first;
                ASSERT(it != newcont.end() && Value<T>::get(*it) == 2, "Element 2 has not been found properly");
                ASSERT(++it == range.second, "Range doesn't have the right number of elements");
            }
#endif /* __TBB_CPP11_INIT_LIST_TEMP_OBJS_COMPILATION_BROKEN */
#endif /* __TBB_INITIALIZER_LISTS_PRESENT */

            // T& operator=(const T& _Umap)
            newcont = ccont;
            ASSERT(T::allow_multimapping ? (newcont.size() == 3) : (newcont.size() == 2), "Assignment operator has not copied the elements properly");

            REMARK("passed -- basic %s tests\n", str);

#if defined (VERBOSE)
            REMARK("container dump debug:\n");
            cont._Dump();
            REMARK("container dump release:\n");
            cont.dump();
            REMARK("\n");
#endif

            cont.clear();
            CheckEmptyContainerAllocatorA(cont, 1, 0); // one dummy is always allocated
            for (int i = 0; i < 256; i++)
            {
                std::pair<typename T::iterator, bool> ins3 = cont.insert(Value<T>::make(i));
                ASSERT(ins3.second == true && Value<T>::get(*(ins3.first)) == i, "Element 1 has not been inserted properly");
            }
            ASSERT(cont.size() == 256, "Wrong number of elements have been inserted");
            ASSERT((256 == CheckRecursiveRange<T, typename T::iterator>(cont.range()).first), NULL);
            ASSERT((256 == CheckRecursiveRange<T, typename T::const_iterator>(ccont.range()).first), NULL);

            // void swap(T&);
            cont.swap(newcont);
            ASSERT(newcont.size() == 256, "Wrong number of elements after swap");
            ASSERT(newcont.count(200) == 1, "Element with key 200 is not present after swap");
            ASSERT(newcont.count(16) == 1, "Element with key 16 is not present after swap");
            ASSERT(newcont.count(99) == 1, "Element with key 99 is not present after swap");
            ASSERT(T::allow_multimapping ? (cont.size() == 3) : (cont.size() == 2), "Assignment operator has not copied the elements properly");

            // Need to be enabled
            SpecialTests<T>::Test(str);
        }


        template <typename base_alloc_t, typename count_t = tbb::atomic<size_t> >
        class local_counting_allocator : public base_alloc_t
        {
        public:
            typedef typename base_alloc_t::pointer pointer;
            typedef typename base_alloc_t::const_pointer const_pointer;
            typedef typename base_alloc_t::reference reference;
            typedef typename base_alloc_t::const_reference const_reference;
            typedef typename base_alloc_t::value_type value_type;
            typedef typename base_alloc_t::size_type size_type;
            typedef typename base_alloc_t::difference_type difference_type;
            template<typename U> struct rebind {
                typedef local_counting_allocator<typename base_alloc_t::template rebind<U>::other, count_t> other;
            };

            count_t items_allocated;
            count_t items_freed;
            count_t allocations;
            count_t frees;
            size_t max_items;

            void set_counters(const count_t& a_items_allocated, const count_t& a_items_freed, const count_t& a_allocations, const count_t& a_frees, const count_t& a_max_items) {
                items_allocated = a_items_allocated;
                items_freed = a_items_freed;
                allocations = a_allocations;
                frees = a_frees;
                max_items = a_max_items;
            }

            template< typename allocator_t>
            void set_counters(const allocator_t& a) {
                this->set_counters(a.items_allocated, a.items_freed, a.allocations, a.frees, a.max_items);
            }

            void clear_counters() {
                count_t zero;
                zero = 0;
                this->set_counters(zero, zero, zero, zero, zero);
            }

            local_counting_allocator() throw() {
                this->clear_counters();
            }

            local_counting_allocator(const local_counting_allocator& a) throw()
                : base_alloc_t(a)
                , items_allocated(a.items_allocated)
                , items_freed(a.items_freed)
                , allocations(a.allocations)
                , frees(a.frees)
                , max_items(a.max_items)
            { }

            /*
            template<typename U, typename C>
            local_counting_allocator(const static_counting_allocator<U, C>& a) throw() {
                this->set_counters(a);
            }
            */
            template<typename U, typename C>
            local_counting_allocator(const local_counting_allocator<U, C>& a) throw()
                : items_allocated(a.items_allocated)
                , items_freed(a.items_freed)
                , allocations(a.allocations)
                , frees(a.frees)
                , max_items(a.max_items)
            { }

            bool operator==(const local_counting_allocator& a) const
            {
                return static_cast<const base_alloc_t&>(a) == *this;
            }

            pointer allocate(const size_type n)
            {
                if (max_items && items_allocated + n >= max_items)
                    __TBB_THROW(std::bad_alloc());
                pointer p = base_alloc_t::allocate(n, pointer(0));
                ++allocations;
                items_allocated += n;
                return p;
            }

            pointer allocate(const size_type n, const void* const)
            {
                return allocate(n);
            }

            void deallocate(const pointer ptr, const size_type n)
            {
                ++frees;
                items_freed += n;
                base_alloc_t::deallocate(ptr, n);
            }

            void set_limits(size_type max = 0) {
                max_items = max;
            }
        };

        template <typename T, template<typename X> class Allocator = std::allocator>
        class debug_allocator : public Allocator<T>
        {
        public:
            typedef Allocator<T> base_allocator_type;
            typedef typename base_allocator_type::value_type value_type;
            typedef typename base_allocator_type::pointer pointer;
            typedef typename base_allocator_type::const_pointer const_pointer;
            typedef typename base_allocator_type::reference reference;
            typedef typename base_allocator_type::const_reference const_reference;
            typedef typename base_allocator_type::size_type size_type;
            typedef typename base_allocator_type::difference_type difference_type;
            template<typename U> struct rebind {
                typedef debug_allocator<U, Allocator> other;
            };

            debug_allocator() throw() { }
            debug_allocator(const debug_allocator& a) throw() : base_allocator_type(a) { }
            template<typename U>
            debug_allocator(const debug_allocator<U>& a) throw() : base_allocator_type(Allocator<U>(a)) { }

            pointer allocate(const size_type n, const void* hint = 0) {
                pointer ptr = base_allocator_type::allocate(n, hint);
                std::memset((void*)ptr, 0xE3E3E3E3, n * sizeof(value_type));
                return ptr;
            }
        };


        template<template<typename T> class Allocator>
        class debug_allocator<void, Allocator> : public Allocator<void> {
        public:
            typedef Allocator<void> base_allocator_type;
            typedef typename base_allocator_type::value_type value_type;
            typedef typename base_allocator_type::pointer pointer;
            typedef typename base_allocator_type::const_pointer const_pointer;
            template<typename U> struct rebind {
                typedef debug_allocator<U, Allocator> other;
            };
        };

        template<typename T1, template<typename X1> class B1, typename T2, template<typename X2> class B2>
        inline bool operator==(const debug_allocator<T1, B1>& a, const debug_allocator<T2, B2>& b) {
            return static_cast<B1<T1>>(a) == static_cast<B2<T2>>(b);
        }
        template<typename T1, template<typename X1> class B1, typename T2, template<typename X2> class B2>
        inline bool operator!=(const debug_allocator<T1, B1>& a, const debug_allocator<T2, B2>& b) {
            return static_cast<B1<T1>>(a) != static_cast<B2<T2>>(b);
        }

        typedef local_counting_allocator<debug_allocator<std::pair<const int, int>, std::allocator> > tbbTAllocator;

};

//#define VK_NS_DEFINE_HANDLE(object) typedef struct vkmm::object##_T* vkmm::object;
#define VK_MAX_MEMORY_TYPES_MIN 3
#define  VK_MAX_MEMORY_HEAPS_MIN 3
namespace vkmm {

    struct VkMAInfo : VkMemoryAllocateInfo {
        /*Each pNext member of any structure(including this one) in the pNext chain must be either NULL or a pointer to a valid instance of
        VkDedicatedAllocationMemoryAllocateInfoNV,
        VkExportMemoryAllocateInfo,
        VkExportMemoryAllocateInfoNV,
        VkExportMemoryWin32HandleInfoKHR,
        VkExportMemoryWin32HandleInfoNV,
        VkImportAndroidHardwareBufferInfoANDROID,
        VkImportMemoryFdInfoKHR,
        VkImportMemoryHostPointerInfoEXT,
        VkImportMemoryWin32HandleInfoKHR,
        VkImportMemoryWin32HandleInfoNV,
        VkMemoryAllocateFlagsInfo,
        VkMemoryDedicatedAllocateInfo,
        VkMemoryOpaqueCaptureAddressAllocateInfo,
        VkMemoryPriorityAllocateInfoEXT
        */
        struct Header
        {
            VkStructureType sType;
            void* pNext;
        }*pCurr;
        std::size_t size;
        template<class T>
        VkStructureType  setsType(T* i) {
            if (0) {}
#define ST2STYPE(t,stype) else if (std::is_same<T, t>::value) return  stype;
            ST2STYPE(VkMemoryAllocateFlagsInfo, VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO)
                ST2STYPE(VkMemoryDedicatedAllocateInfo, VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO)
                ;
            assert(0);
            return (VkStructureType)0;
        };
        size_t  getSize(Header* h) {
            switch (h->sType)
            {
#define STYPE2SIZE(t,stype) case stype: return sizeof(t);
                STYPE2SIZE(VkMemoryAllocateFlagsInfo, VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO)
                    STYPE2SIZE(VkMemoryDedicatedAllocateInfo, VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO)
            default:
                break;
            }
            assert(0);
            return 0;
        };
        template<typename T>
        T* getStruct() {
            auto h = (VkMAInfo::Header*)(VkMemoryAllocateInfo::pNext);
            VkStructureType stype = setsType((T*)h);
            while (h) {
                if (stype == h->sType) return (T*)h;
                else  h = (VkMAInfo::Header*)h->pNext;
            }
            return (T*)nullptr;
        };
        template<>
        float* getStruct<float>() {
            return (float*)nullptr;
        }
        VkMAInfo() :size(0) {

            (*(VkMemoryAllocateInfo*)(this)) = VkMemoryAllocateInfo{ .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO };
            pCurr = (Header*)(this);


        };
        template<typename T>
        void append(T*& info) {

            size_t  n = sizeof(T);
            ///BYTE* ptr  = traits::allocate(alloc, size + n);
            BYTE* ptr = new BYTE[n];
            info = reinterpret_cast<T*>(ptr);
            size += n;

            pCurr->pNext = (void*)info;
            pCurr = (Header*)info;
            pCurr->sType = setsType(info);
            pCurr->pNext = nullptr;

        }
        void clear(){

            if (size > 0) {
                auto h = (VkMAInfo::Header*)(this->pNext);
                BYTE* data = nullptr;
                size_t dsize = 0;
                while (h) {
                    data = (BYTE*)h;
                    dsize = getSize(h);
                    h = (VkMAInfo::Header*)h->pNext;
                    memset(data, 0, dsize);
                    ::operator delete(data, dsize);
                }
                size = 0;
            }
            (*(VkMemoryAllocateInfo*)(this)) =  VkMemoryAllocateInfo{ .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO };
            pCurr = (Header*)(this);
          
        }
        ~VkMAInfo()
        {
            clear();
        }

    };

    ///VK_DEFINE_HANDLE(Allocator)
    typedef void (VKAPI_PTR* PFN_AllocateDeviceMemoryFunction)(
        Allocator      allocator,
        uint32_t          memoryType,
        VkDeviceMemory    memory,
        VkDeviceSize      size);
    /// Callback function called before vkFreeMemory.
    typedef void (VKAPI_PTR* PFN_FreeDeviceMemoryFunction)(
        Allocator      allocator,
        uint32_t          memoryType,
        VkDeviceMemory    memory,
        VkDeviceSize      size);

    typedef struct DeviceMemoryCallbacks {
        /// Optional, can be null.
        PFN_AllocateDeviceMemoryFunction pfnAllocate;
        /// Optional, can be null.
        PFN_FreeDeviceMemoryFunction pfnFree;
    } DeviceMemoryCallbacks;
    /// Description of a Allocator to be created.
    /// /// Flags for created #VmaAllocator.
    typedef enum AllocatorCreateFlagBits {
        ALLOCATOR_CREATE_EXTERNALLY_SYNCHRONIZED_BIT = 0x00000001,

        ALLOCATOR_CREATE_KHR_DEDICATED_ALLOCATION_BIT = 0x00000002,

        ALLOCATOR_CREATE_FLAG_BITS_MAX_ENUM = 0x7FFFFFFF
    } AllocatorCreateFlagBits;

    typedef VkFlags AllocatorCreateFlags;
    typedef struct AllocatorCreateInfo
    {
        /// Flags for created allocator. Use #VmaAllocatorCreateFlagBits enum.
        AllocatorCreateFlags flags;
        /// Vulkan physical device.
        ///         /** Set to 0 to use default, which is currently 256 MiB. */
        VkDeviceSize preferredLargeHeapBlockSize;
        /// Custom CPU memory allocation callbacks. Optional.

        const VkAllocationCallbacks* pAllocationCallbacks;
        const DeviceMemoryCallbacks* pDeviceMemoryCallbacks;

        uint32_t frameInUseCount;

        const VkDeviceSize* pHeapSizeLimit;


    } AllocatorCreateInfo;


    typedef struct StatInfo
    {
        /// Number of `VkDeviceMemory` Vulkan memory blocks allocated.
        uint32_t blockCount;
        /// Number of #VmaAllocation allocation objects allocated.
        uint32_t allocationCount;
        /// Number of free ranges of memory between allocations.
        uint32_t unusedRangeCount;
        /// Total number of bytes occupied by all allocations.
        VkDeviceSize usedBytes;
        /// Total number of bytes occupied by unused ranges.
        VkDeviceSize unusedBytes;
        VkDeviceSize allocationSizeMin, allocationSizeAvg, allocationSizeMax;
        VkDeviceSize unusedRangeSizeMin, unusedRangeSizeAvg, unusedRangeSizeMax;
    } StatInfo;

    /// General statistics from current state of Allocator.
    typedef struct Stats
    {
        StatInfo memoryType[VK_MAX_MEMORY_TYPES];
        StatInfo memoryHeap[VK_MAX_MEMORY_HEAPS];
        StatInfo total;
    } Stats;

    VK_DEFINE_HANDLE(Pool)
        typedef enum MemoryUsage
    {

        MEMORY_USAGE_UNKNOWN = 0,
        MEMORY_USAGE_GPU          =1,
        MEMORY_USAGE_GPU_ONLY = 2,
       MEMORY_USAGE_CPU_ONLY = 3,
        MEMORY_USAGE_CPU_TO_GPU = 4,
        MEMORY_USAGE_GPU_TO_CPU = 5,
        MEMORY_USAGE_MAX_ENUM = 0x7FFFFFFF
    } MemoryUsage;
        typedef enum AllocationCreateFlagBits {
  
        ALLOCATION_CREATE_DEDICATED_MEMORY_BIT = 0x00000001,

        ALLOCATION_CREATE_NEVER_ALLOCATE_BIT = 0x00000002,

        ALLOCATION_CREATE_MAPPED_BIT = 0x00000004,

        ALLOCATION_CREATE_CAN_BECOME_LOST_BIT = 0x00000008,

        ALLOCATION_CREATE_CAN_MAKE_OTHER_LOST_BIT = 0x00000010,

        ALLOCATION_CREATE_USER_DATA_COPY_STRING_BIT = 0x00000020,

        ALLOCATION_CREATE_UPPER_ADDRESS_BIT = 0x00000040,

        ALLOCATION_CREATE_FLAG_BITS_MAX_ENUM = 0x7FFFFFFF
    } AllocationCreateFlagBits;
    typedef VkFlags AllocationCreateFlags;
    typedef struct AllocationCreateInfo
    {
        /// Use #VmaAllocationCreateFlagBits enum.
        AllocationCreateFlags flags;

        MemoryUsage usage;

        VkMemoryPropertyFlags requiredFlags;

        VkMemoryPropertyFlags preferredFlags;

        uint32_t memoryTypeBits;

        vkmm::VkMAInfo                info;

       Pool pool;
        char name[16];
        void* pUserData;
    } AllocationCreateInfo;

    typedef enum PoolCreateFlagBits {

        POOL_CREATE_IGNORE_BUFFER_IMAGE_GRANULARITY_BIT = 0x00000002,

        POOL_CREATE_LINEAR_ALGORITHM_BIT = 0x00000004,

       POOL_CREATE_FLAG_BITS_MAX_ENUM = 0x7FFFFFFF
    } PoolCreateFlagBits;
    typedef VkFlags PoolCreateFlags;
    typedef struct PoolCreateInfo {

        uint32_t memoryTypeIndex;

        PoolCreateFlags flags;

        VkDeviceSize blockSize;

        size_t minBlockCount;

        size_t maxBlockCount;

        uint32_t frameInUseCount;
    } PoolCreateInfo;
    typedef struct PoolStats {

        VkDeviceSize size;

        VkDeviceSize unusedSize;

        size_t allocationCount;

        size_t unusedRangeCount;

        VkDeviceSize unusedRangeSizeMax;

        size_t blockCount;
    } PoolStats;

    VK_DEFINE_HANDLE(Allocation)
        typedef struct AllocationInfo {

        uint32_t memoryType;

        VkDeviceMemory deviceMemory;
        VkDeviceSize                  offset;
        VkDeviceSize                      size;

        void* pMappedData;
        void* pUserData;
    } AllocationInfo;

    typedef struct DefragmentationInfo {

        VkDeviceSize maxBytesToMove;
        uint32_t maxAllocationsToMove;
    } DefragmentationInfo;
    typedef struct DefragmentationStats {
    
        VkDeviceSize bytesMoved;
         VkDeviceSize bytesFreed;

        uint32_t allocationsMoved;
        uint32_t deviceMemoryBlocksFreed;
    } DefragmentationStats;


#define VKMM_DEBUG_LOG(...) 
#define _DEBUG_ALWAYS_DEDICATED_MEMORY (0)
#define _DEBUG_ALIGNMENT (1)
#define _DEBUG_MARGIN (0)
#define _DEBUG_INITIALIZE_ALLOCATIONS (0)
#define _DEBUG_DETECT_CORRUPTION (0)
#define _DEBUG_GLOBAL_MUTEX (0)
#define _DEBUG_MIN_BUFFER_IMAGE_GRANULARITY (1)
#define _SMALL_HEAP_MAX_SIZE (1024ull * 1024 * 1024)
#define _DEFAULT_LARGE_HEAP_BLOCK_SIZE (256ull * 1024 * 1024)
#ifndef _CLASS_NO_COPY
#define _CLASS_NO_COPY(className) \
        private: \
            className(const className&) = delete; \
            className& operator=(const className&) = delete;
#endif
    static const uint32_t FRAME_INDEX_LOST = UINT32_MAX;

    // Decimal 2139416166, float NaN, little-endian binary 66 E6 84 7F.
    static const uint32_t CORRUPTION_DETECTION_MAGIC_VALUE = 0x7F84E666;

    static const uint8_t ALLOCATION_FILL_PATTERN_CREATED = 0xDC;
    static const uint8_t ALLOCATION_FILL_PATTERN_DESTROYED = 0xEF;

    static VkAllocationCallbacks EmptyAllocationCallbacks = {};

    enum SuballocationType
    {
        SUBALLOCATION_TYPE_FREE = 0,
        SUBALLOCATION_TYPE_UNKNOWN = 1,
        SUBALLOCATION_TYPE_BUFFER = 2,
        SUBALLOCATION_TYPE_IMAGE_UNKNOWN = 3,
        SUBALLOCATION_TYPE_IMAGE_LINEAR = 4,
        SUBALLOCATION_TYPE_IMAGE_OPTIMAL = 5,
        SUBALLOCATION_TYPE_MAX_ENUM = 0x7FFFFFFF
    };


    static const VkDeviceSize MIN_FREE_SUBALLOCATION_SIZE_TO_REGISTER = 16;

    static void* Malloc(const VkAllocationCallbacks* pAllocationCallbacks, size_t size, size_t alignment)
    {
        if ((pAllocationCallbacks != nullptr) &&
            (pAllocationCallbacks->pfnAllocation != nullptr))
        {
            return (*pAllocationCallbacks->pfnAllocation)(
                pAllocationCallbacks->pUserData,
                size,
                alignment,
                VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
        }
        else
        {
            return _aligned_malloc(size, alignment);
        }
    }

    static void Free(const VkAllocationCallbacks* pAllocationCallbacks, void* ptr)
    {
        if ((pAllocationCallbacks !=  nullptr) &&
            (pAllocationCallbacks->pfnFree !=  nullptr))
        {
            (*pAllocationCallbacks->pfnFree)(pAllocationCallbacks->pUserData, ptr);
        }
        else
        {
            _aligned_free(ptr);
        }
    }



    void* Malloc(Allocator hAllocator, size_t size, size_t alignment);
    
    void Free(Allocator hAllocator, void* ptr);


    template<typename T>
    static T* Allocate(Allocator hAllocator)
    {
        return (T*)Malloc(hAllocator, sizeof(T), __alignof(T));
    }

    template<typename T>
    static T* AllocateArray(Allocator hAllocator, size_t count)
    {
        return (T*)Malloc(hAllocator, sizeof(T) * count, __alignof(T));
    }

    template<typename T>
    static T* Allocate(const VkAllocationCallbacks* pAllocationCallbacks)
    {
        return (T*)Malloc(pAllocationCallbacks, sizeof(T), __alignof(T));
    }

    template<typename T>
    static T* AllocateArray(const VkAllocationCallbacks* pAllocationCallbacks, size_t count)
    {
        return (T*)Malloc(pAllocationCallbacks, sizeof(T) * count, __alignof(T));
    }

#define vkmm_new(allocator, type)   new(vkmm::Allocate<type>(allocator))(type)

#define vkmm_new_array(allocator, type, count)   new(vkmm::AllocateArray<type>((allocator), (count)))(type)

    template<typename T>
    static void Delete(const VkAllocationCallbacks* pAllocationCallbacks, T* ptr)
    {
        ptr->~T();
        Free(pAllocationCallbacks, ptr);
    }

    template<typename T>
    static void Delete_array(const VkAllocationCallbacks* pAllocationCallbacks, T* ptr, size_t count)
    {
        if (ptr != nullptr)
        {
            for (size_t i = count; i--; )
            {
                ptr[i].~T();
            }
            Free(pAllocationCallbacks, ptr);
        }
    }



    template<typename T>
    static void Delete(Allocator hAllocator, T* ptr)
    {
        if (ptr != nullptr)
        {
            ptr->~T();
            Free(hAllocator, ptr);
        }
    }

    template<typename T>
    static void Delete_array(Allocator hAllocator, T* ptr, size_t count)
    {
        if (ptr != nullptr)
        {
            for (size_t i = count; i--; )
                ptr[i].~T();
            Free(hAllocator, ptr);
        }
    }


    //#define VkmmVector tbb::concurrent_vector
    #define   VkmmVector std::vector
    struct PointerLess
    {
        bool operator()(const void* lhs, const void* rhs) const
        {
            return lhs < rhs;
        }
    };




    template<typename T>
    class StlAllocator
    {
    public:
        const VkAllocationCallbacks* const m_pCallbacks;
        typedef T value_type;
        StlAllocator() :m_pCallbacks(nullptr) { };
        StlAllocator(const VkAllocationCallbacks* pCallbacks) : m_pCallbacks(pCallbacks) { }
        template<typename U> StlAllocator(const StlAllocator<U>& src) : m_pCallbacks(src.m_pCallbacks) { }

        T* allocate(size_t n) { return AllocateArray<T>(m_pCallbacks, n); }
        void deallocate(T* p, size_t n) { Free(m_pCallbacks, p); }

        template<typename U>
        bool operator==(const StlAllocator<U>& rhs) const
        {
            return m_pCallbacks == rhs.m_pCallbacks;
        }
        template<typename U>
        bool operator!=(const StlAllocator<U>& rhs) const
        {
            return m_pCallbacks != rhs.m_pCallbacks;
        }

        StlAllocator& operator=(const StlAllocator& x) = delete;
    };

    class DeviceMemoryBlock;

    enum CACHE_OPERATION { CACHE_FLUSH, CACHE_INVALIDATE };

    // Main allocator object.

    struct Allocator_T
    {
        _CLASS_NO_COPY(Allocator_T)
    public:

        SRWLOCK        slim;

        bool m_UseMutex;
        bool m_UseKhrDedicatedAllocation;
        VkDevice m_hDevice;
        bool m_AllocationCallbacksSpecified;
        VkAllocationCallbacks m_AllocationCallbacks;
        DeviceMemoryCallbacks m_DeviceMemoryCallbacks;

        // Number of bytes free out of limit, or VK_WHOLE_SIZE if not limit for that heap.
        VkDeviceSize m_HeapSizeLimit[VK_MAX_MEMORY_HEAPS_MIN];
        ///COM VMA_MUTEX m_HeapSizeLimitMutex;

        VkPhysicalDeviceProperties m_PhysicalDeviceProperties;
        VkPhysicalDeviceMemoryProperties m_MemProps;

        // Default pools.
        ///COM VmaBlockVector* m_pBlockVectors[VK_MAX_MEMORY_TYPES];

        // Each vector is sorted by memory (handle value).
        //typedef VkmmVector< Allocation, StlAllocator<Allocation> > AllocationVectorType;
        typedef tbb::concurrent_unordered_map<int, vkmm::Allocation, std::hash<int>, std::equal_to<int>, front::tbbTAllocator> AllocMapTy;
        typedef tbb::concurrent_unordered_map<int, AllocMapTy, std::hash<int>, std::equal_to<int>, front::tbbTAllocator> AllocMapMapTy;

        AllocMapMapTy  m_pDedicatedAllocations;

         //VMA_MUTEX m_DedicatedAllocationsMutex[VK_MAX_MEMORY_TYPES];
        Allocator_T() {};
        Allocator_T(const AllocatorCreateInfo* pCreateInfo);
        VkResult Init(const AllocatorCreateInfo* pCreateInfo);
        ~Allocator_T();

        const VkAllocationCallbacks* GetAllocationCallbacks() const
        {
            return m_AllocationCallbacksSpecified ? &m_AllocationCallbacks : 0;
        }


        VkDeviceSize GetBufferImageGranularity() const
        {
            return __max(
                static_cast<VkDeviceSize>(_DEBUG_MIN_BUFFER_IMAGE_GRANULARITY),
                m_PhysicalDeviceProperties.limits.bufferImageGranularity);
        }

        uint32_t GetMemoryHeapCount() const { return m_MemProps.memoryHeapCount; }
        uint32_t GetMemoryTypeCount() const { return m_MemProps.memoryTypeCount; }

        uint32_t MemoryTypeIndexToHeapIndex(uint32_t memTypeIndex) const
        {
            assert(memTypeIndex < m_MemProps.memoryTypeCount);
            return m_MemProps.memoryTypes[memTypeIndex].heapIndex;
        }
        // True when specific memory type is HOST_VISIBLE but not HOST_COHERENT.
        bool IsMemoryTypeNonCoherent(uint32_t memTypeIndex) const
        {
            return (m_MemProps.memoryTypes[memTypeIndex].propertyFlags & (VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)) ==
                VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;
        }
        // Minimum alignment for all allocations in specific memory type.
        VkDeviceSize GetMemoryTypeMinAlignment(uint32_t memTypeIndex) const
        {
            return IsMemoryTypeNonCoherent(memTypeIndex) ?
                __max((VkDeviceSize)_DEBUG_ALIGNMENT, m_PhysicalDeviceProperties.limits.nonCoherentAtomSize) :
                (VkDeviceSize)_DEBUG_ALIGNMENT;
        }

        bool IsIntegratedGpu() const
        {
            return m_PhysicalDeviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU;
        }

#if VMA_RECORDING_ENABLED
        VmaRecorder* GetRecorder() const { return m_pRecorder; }
#endif

        void GetBufferMemoryRequirements(
            VkBuffer hBuffer,
            VkMemoryRequirements& memReq,
            bool& requiresDedicatedAllocation,
            bool& prefersDedicatedAllocation) const;
        void GetImageMemoryRequirements(
            VkImage hImage,
            VkMemoryRequirements& memReq,
            bool& requiresDedicatedAllocation,
            bool& prefersDedicatedAllocation) const;

        // Main allocation function.
        VkResult AllocateMemory(
            const VkMemoryRequirements& vkMemReq,
            bool requiresDedicatedAllocation,
            bool prefersDedicatedAllocation,
            VkBuffer dedicatedBuffer,
            VkImage dedicatedImage,
            AllocationCreateInfo& createInfo,
            SuballocationType suballocType,
            Allocation* pAllocation);

        // Main deallocation function.
        void FreeMemory(const Allocation allocation);

        void CalculateStats(Stats* pStats);

#if VMA_STATS_STRING_ENABLED
        void PrintDetailedMap(class VmaJsonWriter& json);
#endif

        VkResult Defragment(
            Allocation* pAllocations,
            size_t allocationCount,
            VkBool32* pAllocationsChanged,
            const DefragmentationInfo* pDefragmentationInfo,
            DefragmentationStats* pDefragmentationStats);

        void GetAllocationInfo(Allocation hAllocation, AllocationInfo* pAllocationInfo);
        bool TouchAllocation(Allocation hAllocation);

        VkResult CreatePool(const PoolCreateInfo* pCreateInfo, Pool* pPool);
        void DestroyPool(Pool pool);
        void GetPoolStats(Pool pool, PoolStats* pPoolStats);

        void SetCurrentFrameIndex(uint32_t frameIndex);
        uint32_t GetCurrentFrameIndex() const { return m_CurrentFrameIndex.load(); }

        void MakePoolAllocationsLost(
            Pool hPool,
            size_t* pLostAllocationCount);
        VkResult CheckPoolCorruption(Pool hPool);
        VkResult CheckCorruption(uint32_t memoryTypeBits);

        void CreateLostAllocation(Allocation* pAllocation);

        VkResult AllocateVulkanMemory(VkMemoryAllocateInfo* pAllocateInfo, VkDeviceMemory* pMemory);
        void FreeVulkanMemory(uint32_t memoryType, VkDeviceSize size, VkDeviceMemory hMemory);

        VkResult Map(Allocation hAllocation, void** ppData);
        void Unmap(Allocation hAllocation);

        VkResult BindBufferMemory(Allocation hAllocation, VkBuffer hBuffer);
        VkResult BindImageMemory(Allocation hAllocation, VkImage hImage);

        void FlushOrInvalidateAllocation(
            Allocation hAllocation,
            VkDeviceSize offset, VkDeviceSize size,
            CACHE_OPERATION op);

        void FillAllocation(const Allocation hAllocation, uint8_t pattern);

  ///  private:
        VkDeviceSize m_PreferredLargeHeapBlockSize;

        VkPhysicalDevice m_PhysicalDevice;
        std::atomic<UINT> m_CurrentFrameIndex;

        ///COM  VMA_MUTEX m_PoolsMutex;
          // Protected by m_PoolsMutex. Sorted by pointer value.
         VkmmVector<Pool, StlAllocator<Pool> > m_Pools;
        uint32_t m_NextPoolId;

        ///COM   VmaVulkanFunctions m_VulkanFunctions;

#if VMA_RECORDING_ENABLED
        VmaRecorder* m_pRecorder;
#endif

        ///COM       void ImportVulkanFunctions(const VmaVulkanFunctions* pVulkanFunctions);

        VkDeviceSize CalcPreferredBlockSize(uint32_t memTypeIndex);

        VkResult AllocateMemoryOfType(
            VkDeviceSize size,
            VkDeviceSize alignment,
            bool dedicatedAllocation,
            VkBuffer dedicatedBuffer,
            VkImage dedicatedImage,
            AllocationCreateInfo& createInfo,
            uint32_t memTypeIndex,
            SuballocationType suballocType,
            Allocation* pAllocation);

        // Allocates and registers new VkDeviceMemory specifically for single allocation.
        VkResult AllocateDedicatedMemory(
            VkDeviceSize size,
            SuballocationType suballocType,
            uint32_t memTypeIndex,
            bool map,
            bool isUserDataString,
            AllocationCreateInfo& createInfo,
            VkBuffer dedicatedBuffer,
            VkImage dedicatedImage,
            Allocation* pAllocation);

        // Tries to free pMemory as Dedicated Memory. Returns true if found and freed.
        void FreeDedicatedMemory(Allocation allocation);
    };

    struct Allocation_T
    {
      _CLASS_NO_COPY(Allocation_T)
    private:
        static const uint8_t MAP_COUNT_FLAG_PERSISTENT_MAP = 0x80;
        static std::atomic<int>    counter;

        enum FLAGS
        {
            FLAG_USER_DATA_STRING = 0x01,
        };

    public:
        const int ID;
        char   name[16];

        enum ALLOCATION_TYPE
        {
            ALLOCATION_TYPE_NONE,
            ALLOCATION_TYPE_BLOCK,
            ALLOCATION_TYPE_DEDICATED,
            ALLOCATION_TYPE_BLOCK_DEDICATED,
        };



        Allocation_T(uint32_t currentFrameIndex, bool userDataString) :
            ID(counter++),
            m_Alignment(1),
            m_Size(0),
            m_pUserData(nullptr),
            m_LastUseFrameIndex(currentFrameIndex),
            m_Type((uint8_t)ALLOCATION_TYPE_NONE),
            m_SuballocationType((uint8_t)SUBALLOCATION_TYPE_UNKNOWN),
            m_MapCount(0),
            m_Flags(userDataString ? (uint8_t)FLAG_USER_DATA_STRING : 0)
        {
#if VMA_STATS_STRING_ENABLED
            m_CreationFrameIndex = currentFrameIndex;
            m_BufferImageUsage = 0;
#endif
        }
        
        /*
        Allocation_T(const vkmm::Allocation_T& a):
            m_Alignment(a.GetAlignment()),
            m_Size(a.GetSize()),
            m_pUserData(a.GetUserData()),
            m_LastUseFrameIndex(a.GetLastUseFrameIndex()),
            m_Type(a.GetType()),
            m_SuballocationType(a.GetSuballocationType()),
            m_MapCount(a.GetMapCount()),
            m_Flags(a.GetFlags())
        {
            strcpy(name, a.name);
        };
        */
       

        ~Allocation_T()
        {
            assert((m_MapCount & ~MAP_COUNT_FLAG_PERSISTENT_MAP) == 0 && "Allocation was not unmapped before destruction.");

            // Check if owned string was freed.
            assert(m_pUserData == nullptr);
        }

        void InitBlockAllocation(
            Pool hPool,
            DeviceMemoryBlock* block,
            VkDeviceSize offset,
            VkDeviceSize alignment,
            VkDeviceSize size,
            SuballocationType suballocationType,
            bool mapped,
            bool canBecomeLost)
        {
            assert(m_Type == ALLOCATION_TYPE_NONE);
            assert(block != nullptr);
            m_Type = (uint8_t)ALLOCATION_TYPE_BLOCK;
            m_Alignment = alignment;
            m_Size = size;
            m_MapCount = mapped ? MAP_COUNT_FLAG_PERSISTENT_MAP : 0;
            m_SuballocationType = (uint8_t)suballocationType;
            m_BlockAllocation.m_hPool = hPool;
            m_BlockAllocation.m_Block = block;
            m_BlockAllocation.m_Offset = offset;
            m_BlockAllocation.m_CanBecomeLost = canBecomeLost;
        }

        void InitLost()
        {
            assert(m_Type == ALLOCATION_TYPE_NONE);
            assert(m_LastUseFrameIndex.load() == FRAME_INDEX_LOST);
            m_Type = (uint8_t)ALLOCATION_TYPE_BLOCK;
            m_BlockAllocation.m_hPool = VK_NULL_HANDLE;
            m_BlockAllocation.m_Block = nullptr;
            m_BlockAllocation.m_Offset = 0;
            m_BlockAllocation.m_CanBecomeLost = true;
        }

        void ChangeBlockAllocation(
            Allocator hAllocator,
            DeviceMemoryBlock* block,
            VkDeviceSize offset);

        // pMappedData not null means allocation is created with MAPPED flag.
        void InitDedicatedAllocation(
            uint32_t memoryTypeIndex,
            VkDeviceMemory hMemory,
            SuballocationType suballocationType,
            void* pMappedData,
            VkDeviceSize size)
        {
            assert(m_Type == ALLOCATION_TYPE_NONE);
            assert(hMemory != VK_NULL_HANDLE);
            m_Type = (uint8_t)ALLOCATION_TYPE_DEDICATED;
            m_Alignment = 0;
            m_Size = size;
            m_SuballocationType = (uint8_t)suballocationType;
            m_MapCount = (pMappedData != nullptr) ? MAP_COUNT_FLAG_PERSISTENT_MAP : 0;
            m_DedicatedAllocation.m_MemoryTypeIndex = memoryTypeIndex;
            m_DedicatedAllocation.m_hMemory = hMemory;
            m_DedicatedAllocation.m_pMappedData = pMappedData;
        }



        ALLOCATION_TYPE GetType() const { return (ALLOCATION_TYPE)m_Type; }
        VkDeviceSize GetAlignment() const { return m_Alignment; }
        VkDeviceSize GetSize() const { return m_Size; }
        bool IsUserDataString() const { return (m_Flags & FLAG_USER_DATA_STRING) != 0; }
        void* GetUserData() const { return m_pUserData; }
        void SetUserData(Allocator hAllocator, void* pUserData);
        SuballocationType GetSuballocationType() const { return (SuballocationType)m_SuballocationType; }
        uint8_t  GetMapCount()const  {
            return m_MapCount;
        };
        uint8_t  GetFlags()const {
            return m_Flags;
        };
        DeviceMemoryBlock* GetBlock() const
        {
            assert(m_Type == ALLOCATION_TYPE_BLOCK);
            return m_BlockAllocation.m_Block;
        }
        VkDeviceSize GetOffset() const;
        VkDeviceMemory GetMemory() const;
        uint32_t GetMemoryTypeIndex() const;
        bool IsPersistentMap() const { return (m_MapCount & MAP_COUNT_FLAG_PERSISTENT_MAP) != 0; }
        void* GetMappedData() const;
        bool CanBecomeLost() const;
        Pool GetPool() const;

        uint32_t GetLastUseFrameIndex() const
        {
            return m_LastUseFrameIndex.load();
        }
        bool CompareExchangeLastUseFrameIndex(uint32_t& expected, uint32_t desired)
        {
            return m_LastUseFrameIndex.compare_exchange_weak(expected, desired);
        }
        bool MakeLost(uint32_t currentFrameIndex, uint32_t frameInUseCount);

        void DedicatedAllocCalcStatsInfo(StatInfo& outInfo)
        {
            assert(m_Type == ALLOCATION_TYPE_DEDICATED);
            outInfo.blockCount = 1;
            outInfo.allocationCount = 1;
            outInfo.unusedRangeCount = 0;
            outInfo.usedBytes = m_Size;
            outInfo.unusedBytes = 0;
            outInfo.allocationSizeMin = outInfo.allocationSizeMax = m_Size;
            outInfo.unusedRangeSizeMin = UINT64_MAX;
            outInfo.unusedRangeSizeMax = 0;
        }

        void BlockAllocMap();
        void BlockAllocUnmap();
        VkResult DedicatedAllocMap(Allocator hAllocator, void** ppData);
        void DedicatedAllocUnmap(Allocator hAllocator);

        char*  __rep__(bool remove = false) {

            static  char msg[512];
            memset(msg, 1, sizeof(msg));

            if (remove) {
                sprintf_s(msg, "DELETE  %s  ::  addr[%p]  \n  memoryType %u   align:%zu       size:%zu  \n",
                    name,
                    m_DedicatedAllocation.m_hMemory,
                    m_DedicatedAllocation.m_MemoryTypeIndex,
                    m_Alignment,
                    m_Size);
            }
            else {
                sprintf_s(msg, "NEW  %s  ::  addr[%p]  \n  memoryType %u   align:%zu       size:%zu  \n",
                    name,
                    m_DedicatedAllocation.m_hMemory,
                    m_DedicatedAllocation.m_MemoryTypeIndex,
                    m_Alignment,
                    m_Size);
            }
            return msg;

        }

        void* m_pUserData;

    private:
        VkDeviceSize m_Alignment;
        VkDeviceSize m_Size;

        std::atomic<uint32_t> m_LastUseFrameIndex;
        uint8_t m_Type; // ALLOCATION_TYPE
        uint8_t m_SuballocationType; // VmaSuballocationType
        // Bit 0x80 is set when allocation was created with VMA_ALLOCATION_CREATE_MAPPED_BIT.
        // Bits with mask 0x7F are reference counter for vmaMapMemory()/vmaUnmapMemory().
        uint8_t m_MapCount;
        uint8_t m_Flags; // enum FLAGS

        // Allocation out of VmaDeviceMemoryBlock.
        struct BlockAllocation
        {
            Pool m_hPool; // Null if belongs to general memory.
            DeviceMemoryBlock* m_Block;
            VkDeviceSize m_Offset;
            bool m_CanBecomeLost;
        };

        // Allocation for an object that has its own private VkDeviceMemory.
        struct DedicatedAllocation
        {
            uint32_t m_MemoryTypeIndex;
            VkDeviceMemory m_hMemory;
            void* m_pMappedData; // Not null means memory is mapped.
        };





        union
        {
            // Allocation out of VmaDeviceMemoryBlock.
            BlockAllocation m_BlockAllocation;
            // Allocation for an object that has its own private VkDeviceMemory.
            DedicatedAllocation m_DedicatedAllocation;
        };



        void FreeUserDataString(Allocator hAllocator);
    };

};


namespace vkmm {

    template <typename T>
    static inline T AlignUp(T val, VkBufferUsageFlagBits usage)
    {
        if ((usage & VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT) != 0)

            return AlignUp(val, $properties.limits.minTexelBufferOffsetAlignment);

        if ((usage & VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT) != 0)

            return AlignUp(val, $properties.limits.minUniformBufferOffsetAlignment);

        if ((usage & VK_BUFFER_USAGE_STORAGE_BUFFER_BIT) != 0)

            return AlignUp(val, $properties.limits.minStorageBufferOffsetAlignment);

        log_bad("Unknown usage passed.");
        return (T)0;
    }


    template <typename T>
    static inline T AlignUp(T val, T align)
    {
        return (val + align - 1) / align * align;
    }
    // Aligns given value down to nearest multiply of align value. For example: VmaAlignUp(11, 8) = 8.
    // Use types like uint32_t, uint64_t as T.
    template <typename T>
    static inline T AlignDown(T val, T align)
    {
        return val / align * align;
    }

    // Division with mathematical rounding to nearest number.
    template <typename T>
    inline T RoundDiv(T x, T y)
    {
        return (x + (y / (T)2)) / y;
    }
};

namespace vkmm {


    VkResult CreateAllocator(
        const AllocatorCreateInfo* pCreateInfo,
        Allocator* pAllocator);


    VkResult CreateBuffer(
        Allocator allocator,
        const VkBufferCreateInfo* pBufferCreateInfo,
        AllocationCreateInfo& pAllocationCreateInfo,
        VkBuffer* pBuffer,
        Allocation* pAllocation,
        AllocationInfo* pAllocationInfo);

    void DestroyBuffer(
        Allocator allocator,
        VkBuffer buffer,
        Allocation allocation);



    VkResult MapMemory(
        Allocator allocator,
        Allocation allocation,
        void** ppData);

    void UnmapMemory(
        Allocator allocator,
        Allocation allocation);



}





namespace front {




    ///typedef tbb::concurrent_unordered_map<int, int, tbb::tbb_hash<int>, std::equal_to<int>, tbbTAllocator> tbbMap;
    typedef tbb::concurrent_unordered_map<int, int, std::hash<int>, std::equal_to<int>, tbbTAllocator> tbbMap;

    typedef tbb::concurrent_unordered_map<std::string, vkmm::Allocation, std::hash<std::string>, std::equal_to<std::string>, tbbTAllocator> tbbALMap;

    template<class T>
     char atomicType(T type) {
#define atomicType_init Ctx = 47, Win = 47, Desc = 47, Img = 47, Ovr = 47, Obj = 47, Vobj = 47, Uobj = 47, Atta = 47, Pipe = 47;
        
        static char  atomicType_init
#define inc(i) char(int(i)+1)
        switch (type) {
        case CONTEXTVK: { Ctx = inc(Ctx); return Ctx; };
        case WINDOWVK: { Win = inc(Win); return Win; };
        case DESCRIPTORVK: { Desc = inc(Desc); return Desc; };
        case IMAGESVK: { Img= inc(Img); return Img; };
        case OVRVK: {Ovr = inc(Ovr); return Ovr; };
        case OBJECTSVK: {Obj = inc(Obj); return Obj; };
        case VISIBLEOBJECTSVK: {Vobj = inc(Vobj); return Vobj; };
        case  ATTACHMENTSVK:  {Atta = inc(Atta); return Atta; };
        case  PIPELINEVK: {Pipe = inc(Pipe); return Pipe; };
        case  FLUSH_TYPE: {
                atomicType_init
            return  0;
        }
        }
        log_bad("Synco Name not found.");
        return  0;
    };

    

    template<class T>
    void duplicate(_Inout_opt_ T*& ptr, uintptr_t shn) {
        if (ptr != nullptr) {
            log_bad("take out box should be empty.");
        };

        ptr = (T*)(shn);
 

    };

    struct Synco {

        typedef char type;
        uintptr_t        shn;
        type                name = 'B';
        type                id = '0';


        template<class T>
        Synco* salting(T*&& ptr) {
            if (ptr == nullptr) {
                log_bad("what is shun? there is no shun.");
            };

            shn = (uintptr_t)ptr;
 

            name = types::Type(ptr);
            id = atomicType(name);
          
            return this;
        };

        template<class T>
        void duplicate(_Inout_opt_ T*& ptr) {
            if (ptr != nullptr) {
                log_bad("take out box should be empty.\n");
            };

            ptr = (T*)(shn);
 

        };

        void stir_routine();
       

    };

    struct oSyncoTank {

    public:

        typedef  Synco tankType;

        size_t          item = sizeof(Synco);
        const tankType** data = nullptr;
        std::size_t   size = 0;

        explicit oSyncoTank();

        ~oSyncoTank();

        const tankType order(char t, int No = 0);
        void print();
        void flush();

        template<class T>
        bool takeout(T*& dst, int No) {
            char t = types::Type(dst);
            for (int i = 0; i < size; i++) {
                const tankType x = *data[i];
                if (t == x.name && No == int(x.id - '0')) {
                    duplicate(dst, x.shn);
                    return true;
                };
            };


            return false;

        };

        template<class T>
        void add(T*&& x) {
            const tankType** tmp = (const tankType**)std::realloc((void*)data, ++size * sizeof(tankType*));
            if (tmp != nullptr) {
                data = tmp;
                tmp = nullptr;

                tankType* syn = new Synco;
                syn->salting(std::move(x));
 
                data[size - 1] = syn;
                syn = nullptr;

            }
            else {

                log_bad("Osynco Tank failed to allocate.   is this full ? \n");
                return;
            }
        };



    };




    template <class T>
    void asignable(T& dst, const T& src)
    {
        memcpy(&dst, &src, sizeof(T));
    }
    template <class T>
    void movable(uintptr_t& dst, T&& src)
    {
        T* d = (T*)dst;
        d = &src;

    }

    template <typename T> class Lbd {};

    template <typename Out, typename ...In>
    class Lbd<Out(In...)> {

    private:
        Out(*executeLambda)(void*, In...);

        void* lambda = nullptr;
        void (*deleteLambda)(void*);
        void* (*copyLambda)(void*);

        
    public:

        ssize_t                ID = -1;
        static ssize_t occupa;

        Lbd():ID(-1),lambda(nullptr), deleteLambda(nullptr), copyLambda(nullptr), executeLambda(nullptr){};

        ~Lbd()
        {
            Delete();
        }
        Out operator()(In ... in)
        {
          
            assert(lambda != nullptr);
            return executeLambda(lambda, in...);

        }
        
        bool Delete() {
            if (deleteLambda != nullptr) {
                deleteLambda(lambda);
                deleteLambda = nullptr;
                executeLambda = nullptr;
                copyLambda = nullptr;
                lambda = nullptr;
            
                ID = -1;
                InterlockedDecrement64(&occupa);
                //occupa--;
                return true;
            };
            return false;
        };

        template <typename T>
        void generateExecutor(T const& lambda)
        {
            executeLambda = [](void* lambda, In... arguments) -> Out
            {
                return ((T*)lambda)->operator()(arguments...);
            };
        }

        template<typename T>
        void copy(T const& lambda,ssize_t id)
        {
            if (this->lambda != nullptr) Delete();
            
            this->lambda = new T(lambda);
            //occupa++;
            InterlockedIncrement64(&occupa);
            ID = id;

            generateExecutor(lambda);


            deleteLambda = [](void* lambda)
            {
                delete (T*)lambda;

            };

            copyLambda = [](void* lambda) -> void*
            {
                return lambda ? new T(*(T*)lambda) : nullptr;
            };
        };

        template<typename T>
        Lbd<Out(In...)>& operator =(T const& lambda)
        {
            
            copy(lambda,-1);
            return *this;
        }

        operator bool()
        {
            return lambda != nullptr;
        };


        bool operator == (INT64 _ID) const
        {
            return ID == _ID;
        }
        bool operator == (Lbd<Out(In...)> that) const {
            return ID == that.ID;
        }

        static const ssize_t Occupa() {
            return (const ssize_t)occupa;
        }

    };


#define LBSTA  10000

    struct DeallocatorVk {
    public:

        ///typedef std::function<bool(bool)> desType;
        
        typedef bool futType;
        typedef uint32_t  queueType;
        typedef Lbd<bool(bool)> desType;
       
    private:

        struct {
            ///std::vector<desType >                       _;

#if LBSTA == 0
            CRITICAL_SECTION                           sectAlloc;
            desType* _[2];
#else
            desType                                           _[LBSTA];
#endif
     
            ssize_t                                             idx     = 0;
            ssize_t                                            size     = 0;
        }killer;

    public:

        std::unordered_map<std::string, HANDLE>       beginThreads;
        std::vector<std::future<futType>>                           desfuture;
        std::mutex           mtx_desfuture;

        std::atomic_bool                   nib_end;
        bonqueue<uint32_t, 1000000>         buds;
        std::atomic_uint                   budsNums = { 0 };

        uint32_t _total = 0;

        void Dispatch();

        bool NipInTheBud();
        uint32_t AllocFuture();
        bool AllocKiller(ssize_t idx, ssize_t reserve);

        void ClearBuds();

        void Holocaust();
      
        template <class F>
        ssize_t  ToDoList(F const& f, ssize_t reserve = 100)
        {

         
            ssize_t  ID = 0;

            ssize_t  idx = 0;

#if LBSTA == 0
            size = InterlockedAdd64((LONG64*)&killer.size, 0);
            if (idx >= size * 2 / 3) {
                ///if (TryEnterCriticalSection(&sectAlloc)) AllocKiller(idx, reserve);
           };
#else
            ///occupa  = desType::Occupa();
            ssize_t  cnt = 0;
            while(++cnt < killer.size) {
                ID  = InterlockedIncrement64((LONG64*)&killer.idx) - 1;
                idx = ID % killer.size;
                if(!killer._[idx]) {
                    killer._[idx].copy(f, ID);
                    if (killer._[idx](false)) return ID;
                    return -1;
                }
            };

#endif

            
            return -1;

        };

        bool Alive(ssize_t ID) {
          
            ssize_t idx = ID % killer.size;
            ///if (InterlockedAdd64((LONG64*)&killer.size, 0) > idx) {
            if (killer._[idx] == ID) {
                return  killer._[idx](false);
            };
            return false;
        };

        bool Kill(ssize_t ID) {

            ssize_t idx = ID % killer.size;
            if (killer._[idx] == ID) {
                bool ret =   !killer._[idx](true);
                if (ret)killer._[idx].Delete();
                return ret;
            }
            return true;

        };
        bool KillForce(ssize_t idx) {

          
            if (killer._[idx]) {
                bool ret = !killer._[idx](true);
                if(ret)killer._[idx].Delete();
                return ret;
            }
            return true;
        };
       

        ~DeallocatorVk();

    };


    template <class T>
    void asignable(T& dst, const T& src);
    template <class T>
    void movable(uintptr_t& dst, T&& src);


    template <class T>
    class SyncoTank {

        size_t      item = sizeof(T);
        T* data = nullptr;
        std::size_t size = 0;

    public:

        explicit SyncoTank()
            ;

        ~SyncoTank();

        bool alloc1();
        void add(const T& x);
        void add(const T&& x);
        void print();
    };



    ///ROLLCALL BOSS

   

    namespace garbage {
        template<typename ...Args>
        void printer(Args&&... args) {
            (std::cout << ... << args) << '\n';
        }

        template<typename T, typename... Args>
        void push_back_vec(std::vector<T>& v, Args&&... args)
        {
            static_assert((std::is_constructible_v<T, Args&&> && ...));
            (v.push_back(std::forward<Args>(args)), ...);
        }

        // http://stackoverflow.com/a/36937049
        template<class T, std::size_t... N>
        constexpr T bswap_impl(T i, std::index_sequence<N...>) {
            return (((i >> N * CHAR_BIT & std::uint8_t(-1)) << (sizeof(T) - 1 - N) * CHAR_BIT) | ...);
        }
        template<class T, class U = std::make_unsigned_t<T>>
        constexpr U bswap(T i) {
            return bswap_impl<U>(i, std::make_index_sequence<sizeof(T)>{});
        };

        template<typename T, typename... Args>
        auto  passFunc(T&& f, Args... args)
        {
            ///static_assert((std::is_constructible_v<T, Args&&> && ...));
            return  f(args ...);

        }
    }
   

};



#endif