#pragma once
#ifndef MEMORYVK_H
#define MEMORYVK_H
#include "pch_mm.h"
#include "incomplete.h"


#define  GB  (1024ull*1024 * 1024)
#define  MB  (1024ull*1024)
#define HOST_VISIBLE_SINGLE_ALLO_MAX  3*GB
namespace vkmm {


	static VkDeviceSize  preferredLargeHeapBlock    = 256 * MB;
	static VkDeviceSize  HeapLimit[3] = { 5 * GB, 12 * GB, 256 * MB };

	static void* VKAPI_CALL VK_TB_AllocationFunction(void* pData, size_t size, size_t alignment, VkSystemAllocationScope scope)
	{

		// https://www.khronos.org/registry/vulkan/specs/1.0/man/html/PFN_vkAllocationFunction.html need to threat null as error from Vulkan!

		Temperance* temp = (Temperance*)pData;
		InterlockedDecrement(&temp->limits.memory);
		///temp->heapBudget();
		void* ptr = _aligned_malloc(size, alignment);
		log_allo("VkCallback    Allocation   %x   size %zu  align  %zu   scope  %u      nums  %d  \n ", ptr, size, alignment, (UINT32)scope, temp->limits.memory);

		return   ptr;
	};
	static void VKAPI_CALL VK_TB_FreeFunction(void* _pUserData, void* pMemory)
	{
		if (pMemory == nullptr) // https://www.khronos.org/registry/vulkan/specs/1.0/man/html/PFN_vkFreeFunction.html (may be null and it would be safe anyway!)
		{
			return;
		}
		return _aligned_free(pMemory);
	};


	struct  BufferAllocation {
		Allocation  alloc;
		VkBuffer   buffer;
	};


	struct  MemoryVk {

		SRWLOCK                slim;
		typedef tbb::concurrent_unordered_map<std::string, BufferAllocation, std::hash<std::string>, std::equal_to<std::string>, front::tbbTAllocator> tb_umapBA;// > tb_umapBA;
		//typedef tbb::concurrent_hash_map<std::string, BufferAllocation > tb_umapBA;
		//typedef std::unordered_map<std::string, BufferAllocation >   tb_umapBA;
		tb_umapBA           bamp ;


		vkmm::AllocatorCreateInfo allocInfo = {};
		typedef std::function<bool(BufferAllocation& balloc)>  mapcbTy;
   


		MemoryVk() {
			InitializeSRWLock(&slim);
		};
		~MemoryVk() {};

		template<class T>
		void destroy(T* ptr) {


			if (ptr != nullptr)
			{
				ptr->~T();
				if ((allocInfo.pAllocationCallbacks != nullptr) &&
					(allocInfo.pAllocationCallbacks != nullptr))
				{
					(*allocInfo.pAllocationCallbacks->pfnFree)(allocInfo.pAllocationCallbacks->pUserData, ptr);
				}
				else
				{
					_aligned_free(ptr);
				}
			}

		};

		template<typename T = mapcbTy >
		void createBuffer(const char* name ,VkDeviceSize size,
			VkBufferUsageFlags  bflags ,
			MemoryUsage mflag ,T  cb 
			) {


			BufferAllocation   balloc = {};

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = size;
			///BufferInfo.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
			BufferInfo.usage = bflags;

			vkmm::AllocationCreateInfo ainfo;
			ainfo.flags = vkmm::ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;/// | vkmm::ALLOCATION_CREATE_MAPPED_BIT;
			ainfo.usage = mflag; // vkmm::MEMORY_USAGE_GPU_ONLY;  //vkmm::MEMORY_USAGE_CPU_TO_GPU;
			ainfo.pool = VK_NULL_HANDLE;
			ainfo.memoryTypeBits = 0;
			ainfo.requiredFlags = 0;
			ainfo.preferredFlags = 0;

			strcpy(ainfo.name, name);
			assert(bamp.count(name) == 0);

			vkmm::CreateBuffer($pallocator, &BufferInfo, ainfo, &balloc.buffer, &balloc.alloc, NULL);

			cb(balloc);
			bamp[name] = balloc;

		};


		void deleteBuffer(std::string name) {

			if (bamp.count(name) > 0) {
				
				auto ba = bamp[name];
				AcquireSRWLockExclusive(&slim);
				bamp.unsafe_erase(name);
				ReleaseSRWLockExclusive(&slim);

				vkmm::UnmapMemory($pallocator, ba.alloc);
				vkmm::DestroyBuffer($pallocator, ba.buffer, ba.alloc);

				
			}
		}


		void initialize() {

			$Policy_AllocateMemory.pUserData = &$Temperance;   // I don't care
			$Policy_AllocateMemory.pfnAllocation = &VK_TB_AllocationFunction;
			$Policy_AllocateMemory.pfnReallocation = &VK_ReallocationFunction;
			$Policy_AllocateMemory.pfnFree = &VK_TB_FreeFunction;

			$Policy_AllocateMemory.pfnInternalAllocation = nullptr;
			$Policy_AllocateMemory.pfnInternalFree = nullptr;


			allocInfo.frameInUseCount = 4;
			allocInfo.pHeapSizeLimit = (VkDeviceSize*)HeapLimit;
			allocInfo.preferredLargeHeapBlockSize = preferredLargeHeapBlock;
			allocInfo.pAllocationCallbacks = nullptr;
			allocInfo.flags = vkmm::ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;
			$pallocator = new(vkmm::Allocate<Allocator_T>(allocInfo.pAllocationCallbacks))(Allocator_T)(&allocInfo);


		}
		void deinitialize() {

		
			printf(" leaking  memory  %zu      ", bamp.size());
			std::for_each(bamp.begin(), bamp.end(), [&](auto& p)
				{ 

					auto  ba = p.second;
					printf(" leaking  memory be  released. NAME [ %s]  SIZE %zu   \n ",(const char*)(p.first.c_str()), ba.alloc->GetSize()) ;
					vkmm::UnmapMemory($pallocator, ba.alloc);
					vkmm::DestroyBuffer($pallocator, ba.buffer, ba.alloc);
					
				});

			bamp.clear();
			destroy($pallocator);
		};

	};


};
#endif