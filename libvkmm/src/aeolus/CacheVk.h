#pragma once

#ifndef CACHEVK_H
#define CACHEVK_H
#include "pch_mm.h"
#include "incomplete.h"

#ifdef  LOG_NO_ca
#define log_ca(...)
#else
#define log_ca(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif


struct Temperance {

	VkPhysicalDeviceMemoryBudgetPropertiesEXT budget;

	struct {

		long       device;
		long       visible;
		long   devisible;

	}heap;
	struct {
		long       memory;
	}limits;

	void init();

	void deviceLimit();

	void heapBudget();

};

extern Temperance Tempera;
extern VkAllocationCallbacks  Callback_vkAllocateMemory;




static void* VKAPI_CALL VK_AllocationFunction(void* pData, size_t size, size_t alignment, VkSystemAllocationScope scope)
{

	// https://www.khronos.org/registry/vulkan/specs/1.0/man/html/PFN_vkAllocationFunction.html need to threat null as error from Vulkan!

	Temperance* temp = (Temperance*)pData;
	InterlockedDecrement(&temp->limits.memory);
	///temp->heapBudget();
	void*  ptr = _aligned_malloc(size, alignment);
	printf("VkCallback    Allocation    size %zu  align  %zu   scope  %u      nums  %d  \n ",size, alignment, (UINT32)scope,temp->limits.memory);

	return   ptr;
};

static void* VKAPI_CALL VK_ReallocationFunction(void* _pUserData, void* _pOriginal, size_t size, size_t alignment, VkSystemAllocationScope scope)
{


	log_ca("VkCallback    ReAllocation    %x   size %zu  align  %zu   scope  %u  \n ", _pOriginal,size, alignment, (UINT32)scope);

	return  _aligned_realloc(_pOriginal,size, alignment);
};

static void VKAPI_CALL VK_FreeFunction(void* _pUserData, void* pMemory)
{
	if (pMemory == nullptr) // https://www.khronos.org/registry/vulkan/specs/1.0/man/html/PFN_vkFreeFunction.html (may be null and it would be safe anyway!)
	{
		return;
	}
	return _aligned_free(pMemory);
};


void PolicyAllocateFree();


template<class Mem, size_t Size>
struct CacheVk {

	typedef   Mem        MemTy[Size];
	typedef   uintptr_t OwnTy[Size];

	Mem										cache[Size];
	uintptr_t								owner[Size];
	uint32_t										     idx;
	size_t                                      size = Size;
	SRWLOCK                                  SlimLock;

	std::queue<uint32_t>                   vacancy;

	CacheVk() {
		idx = -1;
		InitializeSRWLock(&SlimLock);
	};
	~CacheVk() {}
	
	void clear() {
		memset(cache, 0, sizeof(Mem) * Size);
		memset(owner, 0, sizeof(uintptr_t) * Size);
		while (vacancy.size() > 0)vacancy.pop();
	};

	void enter() {
		AcquireSRWLockExclusive(&SlimLock);
	};
	void leave() {
		ReleaseSRWLockExclusive(&SlimLock);
	};

	bool $get(Mem& mem, Hache* obj) {
		if (obj->id < 0) {
			return false;
		}

		AcquireSRWLockShared(&SlimLock);
		if(Size <= obj->id || owner[obj->id] != obj->hash) {
			ReleaseSRWLockShared(&SlimLock);
			return false;
		}
		mem = cache[obj->id];
		ReleaseSRWLockShared(&SlimLock);
		return true;
	};

	template<class T>
	bool get(Mem& mem, T* obj) {
		if (obj->id < 0) {
			log_once("CacheVk  incorrect  index  < 0.\n");
			return false;
		}

		if(Size <= obj->id  || owner[obj->id] != (uintptr_t)obj) {
			log_once("Owner is  exclusive. you are'nt owner.");
			return false;
		};
		mem = cache[obj->id];
		return true;
	};

	bool get(Mem& mem, Hache* obj) {
		if (obj->id < 0) {
			log_once("CacheVk  incorrect  index  < 0.\n");
			return false;
		}

		///log_ca(" get  %s     IDX    %d     OWNER    %zu     HASH  %zu  \n",typeid(Mem).name(), obj->id,  owner[obj->id], obj->hash);

		if (Size <= obj->id  || owner[obj->id] != obj->hash) {
			log_once("Hash is  exclusive. you don't have  the hash.");
			return false;
		}
		mem = cache[obj->id];

		return true;
	};

	template<class T>
	bool $set$(Mem&& mem, T* obj) {

		AcquireSRWLockExclusive(&SlimLock);
		idx = (idx + 1) % Size;
		if (cache[idx].isValid()) {
			log_bad(" Buffer is not created  for  Over limit  Nums. \n");
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		};
		cache[idx] = mem;
		cache[idx].version = ++obj->version;
		obj->id = idx;
		owner[idx] = (uintptr_t)obj;
		ReleaseSRWLockExclusive(&SlimLock);

		return true;
	};

	bool $set$(Mem&& mem, Hache* obj) {

		AcquireSRWLockExclusive(&SlimLock);

		idx = (idx + 1) % Size;
		if (cache[idx].isValid()) {
			log_bad(" Buffer is not created  for  Over limit  Nums. \n");
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		};
		cache[idx] = mem;
		cache[idx].version = ++obj->version;
		obj->id = idx;
		owner[idx] = obj->hash;

		ReleaseSRWLockExclusive(&SlimLock);

		return true;
	};

	template<class T>
	bool $delete$(T* obj) {
		if (obj->id < 0)return false;

		AcquireSRWLockExclusive(&SlimLock);

		if (!cache[obj->id].isValid()) {
			log_bad("you can't delete buffer becouse of being not Valid.\n");
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		};
		if (owner[obj->id] != (uintptr_t)obj) {
			log_bad("Owner is  exclusive. you are'nt owner.");
			return false;
		};

		cache[obj->id].dealloc();
		owner[obj->id] = (uintptr_t)(-1);
		vacancy.push(obj->id);


		ReleaseSRWLockExclusive(&SlimLock);

		return true;
	};

	bool $delete$(Hache* obj) {

		if (obj->id < 0)return false;

		AcquireSRWLockExclusive(&SlimLock);

		if (!cache[obj->id].isValid()) {
			log_bad("you can't delete buffer becouse of being not Valid.\n");
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		};
		if (owner[obj->id] != obj->hash) {
			log_bad("Owner is  exclusive. you are'nt owner.");
			return false;
		};

		cache[obj->id].dealloc();
		owner[obj->id] = (uintptr_t)(-1);
		vacancy.push(obj->id);
		obj->id = -1;


		ReleaseSRWLockExclusive(&SlimLock);

		return true;
	};

	bool $kill$(long id) {

		AcquireSRWLockExclusive(&SlimLock);

		if (!cache[id].isValid()) {
			log_bad("you can't delete buffer becouse of being not Valid.\n");
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		};

		cache[id].dealloc();
		owner[id] = (uintptr_t)(-1);
		vacancy.push(id);

		ReleaseSRWLockExclusive(&SlimLock);

		return true;
	};

	struct index{
		long idx = -1;
	};


	template<class O>
	bool $createVisibleMemory$(VkMemoryRequirements& memReqs, O& obj) {


		AcquireSRWLockExclusive(&SlimLock);
		if (obj.mem.id >= 0 && owner[obj.mem.id] == obj.mem.hash) {
			ReleaseSRWLockExclusive(&SlimLock);
			return true;
		}


		idx = (idx + 1) % Size;
		if (cache[idx].isValid()) {
			log_bad(" Buffer is not created  for  Over limit  Nums. \n");
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		};

		Mvk& _ = cache[idx];
		VkMemoryAllocateInfo allocInfo = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
		.allocationSize = obj.memSize,
		.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
		};

		VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, nullptr, &(_.memory)));
		_.version = ++obj.mem.version;
		obj.mem.id = idx;
		owner[idx] = obj.mem.hash;
		ReleaseSRWLockExclusive(&SlimLock);

		log_ca("$createVisibleMemory$  %s      IDX    %d   OWNER    %zu    \n", typeid(Mem).name(), obj.mem.id, obj.mem.hash);

		return true;
	};

};




#endif