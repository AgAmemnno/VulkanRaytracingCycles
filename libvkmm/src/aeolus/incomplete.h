#pragma once

#ifndef INCOMPLETE_H
#define INCOMPLETE_H


#include "enum.hpp"
#include "types.hpp"
#include "aeolus/vthreepy_const.h"
#include "aeolus/vthreepy_types.h"


struct AttaCD {
	MIVvk color, depth;
};





struct DescriptorVk;
template<class pool>
struct ImmidiateBufferCmd;
struct ImmidiateCmdPool;
struct CanvasVk;
struct GuiMaterialVk;

typedef struct Mache {
	long                                        id;
	long                                 refCnt;
	Hache                                 mem;

	void* mapped;
	std::string_view                        type;
	VkDeviceSize                             size;
	std::vector<VkDeviceSize>    sizeSet;

	VkDeviceSize               memSize;
	VkDeviceSize                 reqSize;
	VkDeviceSize                      align;
	VkDeviceSize                 reqAlign;

} Mache;

typedef struct  Iache {


	VkFormat        format;
	uint32_t         multisample;
	VkImageLayout            layout;
	VkDescriptorType           type;
	long     refCnt;
	const  size_t      hash;
	Hache                 hach;
	VkImageView       vkI;
	std::string          name;
	Iache() :hash(size_t(-1)), refCnt(0), multisample(1) {};
	Iache(size_t hash) :hash(hash), hach({ .id = -1,.version = 0,.hash = hash }), refCnt(0), multisample(1) { name = "new"; };
	~Iache() { log_once(" Call  destructor   Iache   \n"); };

	
	Iache& operator=(size_t hash)
	{
		if (this->hash == hash) return *this;
		if (refCnt > 0)log_bad("Iache  reference exists. you lost the hash.  \n");
		this->~Iache();
		new (this) Iache(hash);
		return *this;
	};
	template<class T>
	Iache& operator=(T& iach)
	{

		log_once(" Call Swap  Iache  %d    %x <=> %x  ,  %x <=> %x \n", refCnt, this->hach.id, iach.hach.id, this->hash, iach.hash);

		if (this->hash == iach.hash) return *this;
		if (refCnt > 0)log_bad("Iache  reference exists. you lost the hash.  \n");
		this->~Iache();
		new (this) Iache(iach.hash);
		this->hach.id = iach.hach.id;
		this->format = iach.format;
		this->multisample = iach.multisample;
		this->refCnt = iach.refCnt;
		this->vkI = iach.vkI;
		log_once(" Call Swap  view %x   id  %x  hash  %x  version %x\n", this->vkI, this->hach.id, this->hach.hash, this->hach.version);
		return *this;
	};

	static size_t rehash(std::string imgName, size_t seed)  noexcept
	{
		static  std::hash<std::string> h_img{};
		static  std::hash<size_t> h_seed{};

		std::size_t  hash = 0;
		hash += h_img(imgName);
		hash += hash << 10;
		hash ^= hash >> 6;

		hash += h_seed(seed);
		hash += hash << 3;
		hash ^= hash >> 11;
		hash += hash << 15;
		return hash;
	};

	template<class I>
	void Delete(I* im) {
		long cnt = InterlockedDecrement(&refCnt);
		log_once(" Decrement  Iache  %d   \n", cnt);
		if (cnt == 0) {
			im->$Delete(&hach);
		}
	};

}Iache;

typedef  struct Bache {

	long                                        id;
	long                                 refCnt;
	Hache                             buffer;

	VkDeviceSize                      align;
	VkDeviceSize                 reqAlign;

	VkDeviceSize                      size;
	VkDeviceSize                   offset;
	VkDeviceSize                 reqSize;

	std::queue<uint32_t>       vacancy;
	std::string_view                  type;
	
	SRWLOCK                           excl;
	VkBuffer                       vkBuffer;
	void*                             mapped;
	
	Bache();
	Bache(size_t    hash,
		VkDeviceSize                      align,
		LayoutType   type
	);
	Bache& operator=(const Bache& other);
	template<class T>
	void Undo(T desc) {

		AcquireSRWLockExclusive(&excl);
		vacancy.push(desc.id);
		desc.info.buffer = VK_NULL_HANDLE;
		refCnt--;
		ReleaseSRWLockExclusive(&excl);

	};

	template<class T>
	void Redo(T desc) {

		AcquireSRWLockExclusive(&excl);
		desc.id = vacancy.front();
		vacancy.pop();
		refCnt++;
		ReleaseSRWLockExclusive(&excl);

	};

}Bache;


typedef struct TexBache {

	long                                        id;
	Hache                             buffer;
	VkDeviceSize                      align;
	VkDeviceSize                 reqAlign;

	VkDeviceSize                      size;
	VkDeviceSize                 reqSize;

	VkDeviceSize                    offset;


	VkFormat                         format;
	VkDescriptorBufferInfo        info;
	VkBufferView                        vkView;
	VkBuffer                           vkBuffer;
	void* mapped;

	TexBache() {
		memset(this, 0, sizeof(TexBache));
		buffer.id = -1;
		vkView = VK_NULL_HANDLE;
	};
	~TexBache() {
		dealloc();
	}

	void dealloc() {
		if (vkView != VK_NULL_HANDLE) {
			vkDestroyBufferView($device, vkView, NULL);
			vkView = VK_NULL_HANDLE;
		}
	};


}TexBache;

typedef struct StoBache {

	long                                        id = { -1 };
	Hache                             buffer;
	VkDeviceSize                      align;
	VkDeviceSize                 reqAlign;

	VkDeviceSize                      size;
	VkDeviceSize                 reqSize;
	VkDeviceSize                    offset;
	VkFormat                         format;
	VkBuffer                           vkBuffer;
	VkDescriptorBufferInfo        info;
	std::vector<VkBufferView>                         view;
	uint32_t                          set,binding;

	void* mapped;

	StoBache() {
		memset(this, 0, sizeof(StoBache));
		buffer.id = -1;
	};

	~StoBache() {
		dealloc();
	};
	void dealloc() {
		for (auto& v : view) {
			if (v != VK_NULL_HANDLE) {
				vkDestroyBufferView($device, v, NULL);
				v = VK_NULL_HANDLE;
			}
		};
		view.clear();
	};


	bool operator < (const StoBache& rhs) const {
		return binding < rhs.binding;
	}

}StoBache;
typedef struct StoBacheArray {

	long                                        id = { -1 };
	Hache                             buffer = { -1,0,0 };
	VkDeviceSize                      align = 0;
	VkDeviceSize                 reqAlign = 0;

	VkDeviceSize                      size = 0;
	VkDeviceSize                 reqSize = 0;
	VkDeviceSize                    offset = 0;
	VkBuffer                           vkBuffer = VK_NULL_HANDLE;
	VkFormat                             format;
	VkDescriptorBufferInfo                            info;
	std::vector<VkDescriptorBufferInfo>        infos;

	void* mapped = nullptr;

}StoBacheArray;


namespace DescUniform {

	static inline VkDeviceSize alignedSize(VkDeviceSize sz, VkDeviceSize align)
	{
		return ((sz + align - 1) / (align)) * align;
	};
	template<typename T>
	VkDeviceSize alignmentSB(T& bach,VkDeviceSize  size,VkDeviceSize _alignment = 0) {

		const VkDeviceSize                 maxChunk = 512 * 1024 * 1024;
		if (_alignment == 0) {
			VkPhysicalDeviceLimits& limits = $properties.limits;
			 _alignment = limits.minStorageBufferOffsetAlignment;
		}
		///MIN
		auto alignment = _alignment - (size % _alignment);
		if (alignment < _alignment)return size + alignment;
		return size;

		///MAX
	    ///VkDeviceSize tboSize = limits.maxStorageBufferRange;
		///const VkDeviceSize structMax = VkDeviceSize(tboSize) * structSize;
		///_maxStructChunk = __min(structMax, maxChunk);

	};


	template<typename T>
	void  appendAlignScalar(T& bach , VkDeviceSize size,int expect = -1) {

		size  =  alignmentSB(bach, size);
		VkDescriptorBufferInfo info = {
				  .offset = bach.size,
				  .range = size
		};
		bach.infos.push_back(info);
		if (expect > 0) assert(bach.infos.size() == expect);
	
		bach.size += size;
		
	};
	template<typename T>
	void  setAlignScalar(T& bach) {
		assert(bach.vkBuffer != VK_NULL_HANDLE);
		for (auto& info : bach.infos) info.buffer = bach.vkBuffer;
	};
}; 


#define $hb hb
#define $Policy_AllocateMemory Callback_vkAllocateMemory
#define $Temperance Tempera


struct vkDSLMem;
template<class Mem, size_t Size>
struct CacheVk;

///#define  MemStatic(vk,sz) static CacheVk<vk, sz> vk##Cache
#define  MemType(vk,sz) CacheVk<vk, sz>
#define  MemStatic(vk,sz) CacheVk<vk, sz> vk##Cache##sz
#define  Mem(vk,sz) vk##Cache##sz
#define  MemExtern(vk,sz) extern CacheVk<vk, sz> vk##Cache##sz
#define  MemClear(vk,sz) vk##Cache##sz.clear();




#define OBJ_GEOM(obj)  ((obj)->geometry->attributes->buffer)



namespace fon {
	struct MSDFfont;
};



namespace arth {

	std::string INPUT_String(arth::INPUT type);

};

#endif