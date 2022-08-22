#pragma once
#ifndef VTHREEPY_TYPES
#define VTHREEPY_TYPES

#include "config_aeolus.h"
#include "enum.hpp"
#include "vulkan/vulkan.h"
#include "util/log.hpp"
#include <vector>

typedef unsigned char TypeType;

#define UNDEFINED_TYPE 127
#define FLUSH_TYPE 126


/// Exculsive Class Definition
#define CONTEXTVK 0

#ifdef ENABLED_VULKAN_OPTIX
typedef struct ContextExVk ContextVk;
#else
typedef struct Context0Vk ContextVk;                       ///Context1Vk
#endif

#define WINDOWVK 1
typedef struct WindowVk WindowVk;                     ///WindowVk
#define DESCRIPTORVK 2
typedef struct DescriptorVk DescriptorVk;                     ///DescriptorVk
#define IMAGESVK 3
typedef struct ImagesVk ImagesVk;
#define OVRVK    4
typedef struct OVR OVR;
#define OBJECTSVK 5
typedef struct ObjectsVk ObjectsVk;
#define VISIBLEOBJECTSVK 6
typedef struct VisibleObjectsVk VisibleObjectsVk;
#define ATTACHMENTSVK 7
typedef struct AttachmentsVk AttachmentsVk;
#define PIPELINEVK 8
typedef struct PipelineVk  PipelineVk;

namespace types {

	template<class T>
	TypeType Type(T* _) {
		if (std::is_same<T, ContextVk>::value) return CONTEXTVK;
		else if (std::is_same<T, WindowVk>::value) return WINDOWVK;
		else if (std::is_same<T, DescriptorVk>::value) return DESCRIPTORVK;
		else if (std::is_same<T, ImagesVk>::value) return IMAGESVK;
		else if (std::is_same<T, OVR>::value) return OVRVK;
		else if (std::is_same<T, ObjectsVk>::value) return OBJECTSVK;
		else if (std::is_same<T, VisibleObjectsVk>::value) return VISIBLEOBJECTSVK;
		else if (std::is_same<T, AttachmentsVk>::value) return ATTACHMENTSVK;
		else if (std::is_same<T, PipelineVk>::value) return PIPELINEVK;
		return (TypeType)UNDEFINED_TYPE;
	};

};





typedef struct UniformVk UniformVk;
typedef struct DescriptorVk DescriptorVk;
namespace vkmm {
	typedef struct Allocator_T* Allocator;
};

extern   VkInstance                          __instance;
extern   VkPhysicalDevice                 __physicaldevice;
extern   VkDevice                              __device;
extern   VkQueue                              __queue;
extern   ContextVk*                         __ctx__;
extern   vkmm::Allocator                  __vkmmallocator;
struct queueFamilyIndices
{
	uint32_t stcg;
	uint32_t stc;
	uint32_t st;
};

extern   queueFamilyIndices __queueFamilyIndices;

typedef struct _Vkformat {

	VkFormat                            COLORFORMAT;
	VkColorSpaceKHR                   COLORSPACE;
	VkFormat                            DEPTHFORMAT;
	VkFormat                            COLORFORMAT_VR;
	VkFormat                            COLORFORMAT_RT;

}_Vkformat;

extern   _Vkformat __format;
extern VkPhysicalDeviceProperties __properties;
extern VkPhysicalDeviceFeatures __features;
extern VkPhysicalDeviceMemoryProperties __memoryProperties;
struct FormatConfig {
	VkFormat                            COLORFORMAT;
	VkColorSpaceKHR                   COLORSPACE;
	VkFormat                            DEPTHFORMAT;
	void copy(FormatConfig   form) {
		COLORFORMAT = form.COLORFORMAT;
		COLORSPACE = form.COLORSPACE;
		DEPTHFORMAT = form.DEPTHFORMAT;
	};
};




#define $instance __instance
#define $physicaldevice __physicaldevice
#define $device __device 
#define $queue  __queue
#define $queueIdx  __queueFamilyIndices
#define $format __format
#define $properties  __properties
#define $features __features
#define $memoryProperties __memoryProperties
#define $ctx __ctx__

#define  $des     des
#define  $tank   otank
#define  $pallocator __vkmmallocator
#define  $allocator  (*__vkmmallocator)


typedef struct MBvk {

	VkDeviceMemory memory;
	VkBuffer buffer = VK_NULL_HANDLE;
	VkIndexType    idxType;
	int           version = { -1 };
	uint32_t count;
	MBvk() :
		memory(VK_NULL_HANDLE),
		buffer(VK_NULL_HANDLE),
		version(-1),
		count(0),
		idxType(VK_INDEX_TYPE_UINT32)
	{};
	bool isValid() {
		return buffer != VK_NULL_HANDLE;
	}
	void dealloc() {
		if (buffer != VK_NULL_HANDLE) {
			vkDestroyBuffer($device, buffer, nullptr);
			vkFreeMemory($device, memory, nullptr);
			buffer = VK_NULL_HANDLE;
			memory = VK_NULL_HANDLE;
		};
	};

} MBvk;

typedef struct MIBvk {

	VkBuffer buffer = VK_NULL_HANDLE;
	VkDescriptorBufferInfo info;
	VkDeviceMemory memory = VK_NULL_HANDLE;
	size_t size = 0;
	uint32_t count;

	int version = { -1 };

	MIBvk() :
		memory(VK_NULL_HANDLE),
		buffer(VK_NULL_HANDLE),
		info({}),
		version(-1),
		count(0),
		size(0)
	{
	};

	void dealloc() {
		if (buffer) {
			vkDestroyBuffer($device, buffer, nullptr);
			vkFreeMemory($device, memory, nullptr);
		}
	};
	void copy(MIBvk v) {
		memory = v.memory;
		buffer = v.buffer;
		count = v.count;
		version = v.version;
		info = v.info;
		size = v.size;
	}
	bool isValid() {
		return buffer != VK_NULL_HANDLE;
	}
} MIBvk;

typedef struct MIBmvk {

	VkDeviceMemory memory = VK_NULL_HANDLE;
	VkDescriptorBufferInfo info;
	VkBuffer buffer = VK_NULL_HANDLE;
	void* mapped;
	size_t size = 0;

	int version = { -1 };
	void dealloc() {
		if (buffer != VK_NULL_HANDLE) {
			vkDestroyBuffer($device, buffer, nullptr);
			vkFreeMemory($device, memory, nullptr);
			buffer = VK_NULL_HANDLE;
		};
	};
	bool isValid() {
		return buffer != VK_NULL_HANDLE;
	}

} MIBmvk;


typedef struct  MIVSIvk {
	size_t                           size;
	uint32_t                     w, h, d, l, c,mipLevel;
	VkMemoryRequirements memReqs;
	VkDeviceMemory memory;
	VkImage        image;
	VkImageView  view;
	VkSampler  sampler;
	VkDescriptorImageInfo  Info;
	VkFormat                      format;
	BYTE*                          mapped;
	bool                                valid;
	int version = { -1 };
	MIVSIvk* next = nullptr;
	MIVSIvk() :
		memory(VK_NULL_HANDLE),
		image(VK_NULL_HANDLE),
		view(VK_NULL_HANDLE),
		sampler(VK_NULL_HANDLE),
		memReqs({}),
		Info({}),
		valid(false),
		mapped(nullptr),
		next(nullptr)
	{
		size = 0;
		w = h = d = l = c = 0;
	};
	void dealloc() {
		if (sampler != VK_NULL_HANDLE) vkDestroySampler($device, sampler, nullptr);
		if (view != VK_NULL_HANDLE) vkDestroyImageView($device, view, nullptr);
		if (image != VK_NULL_HANDLE) 	vkDestroyImage($device, image, nullptr);
		if (memory != VK_NULL_HANDLE) 	vkFreeMemory($device, memory, nullptr);

		    memory = VK_NULL_HANDLE,
			image = VK_NULL_HANDLE,
			view = VK_NULL_HANDLE,
			sampler = VK_NULL_HANDLE;
		size = 0;
		w = h = d = l = c = 0;
		if (next != nullptr) {
			next->dealloc();
			delete next; next = nullptr;
		}
	};
	bool isValid() {
		return memory != VK_NULL_HANDLE;
	}
}MIVSIvk;


typedef struct  MBIVSIvk {
	size_t                           size;
	uint32_t                     w, h, d, l, c, mipLevel;
	VkMemoryRequirements memReqs;
	VkDeviceMemory memory;
	VkImage        image;
	VkImageView  view;
	VkSampler  sampler;
	VkBuffer        buffer;
	VkDescriptorImageInfo  Info;
	VkDescriptorBufferInfo  bInfo;
	VkFormat                      format;
	bool                                valid;
	int version = { -1 };
	MBIVSIvk() :
		memory(VK_NULL_HANDLE),
		image(VK_NULL_HANDLE),
		view(VK_NULL_HANDLE),
		sampler(VK_NULL_HANDLE),
		buffer(VK_NULL_HANDLE),
		memReqs({}),
		Info({}),
		valid(false)
	{
		size = 0;
		w = h = d = l = c = 0;
	};
	void dealloc() {

		if (sampler != VK_NULL_HANDLE) vkDestroySampler($device, sampler, nullptr);
		if (view != VK_NULL_HANDLE) vkDestroyImageView($device, view, nullptr);
		if (image != VK_NULL_HANDLE) 	vkDestroyImage($device, image, nullptr);
		if (buffer != VK_NULL_HANDLE) 	vkDestroyBuffer($device,buffer, nullptr);
		if (memory != VK_NULL_HANDLE) 	vkFreeMemory($device, memory, nullptr);

		memory = VK_NULL_HANDLE,
			image = VK_NULL_HANDLE,
			view = VK_NULL_HANDLE,
			buffer = VK_NULL_HANDLE,
			sampler = VK_NULL_HANDLE;
	};
	bool isValid() {
		return memory != VK_NULL_HANDLE;
	}
}MBIVSIvk;

typedef struct MIVvk {

	size_t                           size;
	uint32_t                 w, h, d, l, c;
	VkDeviceMemory memory;
	VkImage image;
	VkImageView view;
	VkDescriptorImageInfo  Info;
	int version = { -1 };
	MIVvk() :
		memory(VK_NULL_HANDLE),
		image(VK_NULL_HANDLE),
		view(VK_NULL_HANDLE),
		Info({})
	{
		size = 0;
		w = h = d = l = c = 0;
	};
	void dealloc() {

		if (view != VK_NULL_HANDLE) vkDestroyImageView($device, view, nullptr);
		if (image != VK_NULL_HANDLE) 	vkDestroyImage($device, image, nullptr);
		if (memory != VK_NULL_HANDLE) 	vkFreeMemory($device, memory, nullptr);

		memory = VK_NULL_HANDLE,
			image = VK_NULL_HANDLE,
			view = VK_NULL_HANDLE;

	};
	bool isValid() {
		return memory != VK_NULL_HANDLE;
	}

}MIVvk;


typedef struct PvSvk {

	VkPipeline                          pipeline = VK_NULL_HANDLE;
	std::vector<VkShaderModule> shaderModules;
	PvSvk() :pipeline(VK_NULL_HANDLE), shaderModules({}) {};
	void  dealloc() {

		if (pipeline != VK_NULL_HANDLE) {
			for (auto& shaderModule : shaderModules)
			{
				vkDestroyShaderModule($device, shaderModule, nullptr);
			};
			vkDestroyPipeline($device, pipeline, nullptr);
			pipeline = VK_NULL_HANDLE;
		};

	};
	bool isValid() {
		return pipeline != VK_NULL_HANDLE;
	}
} PvSvk;

typedef struct Mvk {

	VkDeviceMemory memory = VK_NULL_HANDLE;
	size_t size = 0;
	int version = { -1 };
	void dealloc() {
		if (memory != VK_NULL_HANDLE) {
			vkFreeMemory($device, memory, nullptr);
			memory = VK_NULL_HANDLE;
		};
	};
	bool isValid() {
		return memory != VK_NULL_HANDLE;
	}
} Mvk;

typedef struct IBmvk {

	VkDescriptorBufferInfo info;
	VkBuffer buffer = VK_NULL_HANDLE;
	void* mapped;
	VkDeviceSize size = 0;
	VkDeviceSize offset = 0;
	int version = { -1 };
	void dealloc() {
		if (buffer != VK_NULL_HANDLE) {
			vkDestroyBuffer($device, buffer, nullptr);
			buffer = VK_NULL_HANDLE;
		};
	};
	bool isValid() {
		return buffer != VK_NULL_HANDLE;
	};

} IBmvk;

typedef struct ImVvk :VkDescriptorBufferInfo {
	void* mapped = nullptr;
	int version = { -1 };

	void dealloc() {
		if (mapped != nullptr)mapped = nullptr;
	};

	bool isValid() {
		return mapped != nullptr;
	};

} ImVvk;

typedef struct AttachCD {
	MIVvk* color;
	MIVvk* depth;
}AttachCD;


typedef struct SLvk {
	VkDescriptorSet         Set;
	VkDescriptorSetLayout Layout;
}	SLvk;

typedef struct  Hache {
	long        id;
	long        version;
	size_t    hash;
}Hache;



struct PipelineConfigure {

	VkPipelineLayout                                              vkPL;
	VkRenderPass                                                  vkRP;
	VkPipelineCache                                               vkPC;
	VkPipelineVertexInputStateCreateInfo* vkPVISci;
	std::string                                                         spv;
	arth::GEOMETRY                                 defulettype;
	uint32_t                                                  multisample;
};

struct CLambda {


	template<typename Tret, typename T>
	static Tret lambda_ptr_exec() {
		return (Tret)(*(T*)fn<T>())();
	}



	template<typename Tret, typename T, typename ...In>
	static Tret lambda_ptr_exec(In... arguments) {
		return (Tret)(*(T*)fn<T>())(arguments...);
	}


	template<typename Tret = void, typename T>
	static auto vptr(T& t) {
		using Tfp = Tret(*)(void);
		fn<T>(&t);
		return (Tfp)lambda_ptr_exec<Tret, T>;
	}


	template<typename Tret = void, typename ...In, typename T>
	static auto ptr(T& t) {
		using Tfp = Tret(*)(In ...);
		fn<T>(&t);
		return (Tfp)lambda_ptr_exec<Tret, T, In...>;
	}

	template<typename T>
	static void* fn(void* new_fn = nullptr) {
		static void* fn;
		///printf("  %s   \n", typeid(T).name());
		if (new_fn != nullptr)
			fn = new_fn;
		return fn;
	}

};

typedef std::vector<VkPipelineShaderStageCreateInfo>& (*ShaderStagesTy)(void*);
typedef VkPipelineDynamicStateCreateInfo* (*DynamicTy)(void*);
typedef VkPipelineViewportStateCreateInfo* (*ViewportTy)(void*);
typedef VkPipelineMultisampleStateCreateInfo* (*MultisampleTy)(void*);
typedef VkPipelineInputAssemblyStateCreateInfo* (*InputAssemblyTy)(void*);
typedef VkPipelineRasterizationStateCreateInfo* (*RasterizationTy)(void*);
typedef VkPipelineDepthStencilStateCreateInfo* (*DepthStencilTy)(void*);
typedef VkPipelineColorBlendStateCreateInfo* (*ColorBlendTy)(void*);

struct PipelineStateCreateInfoVk {

	ShaderStagesTy ShaderStages;
	DynamicTy Dynamic;

	ViewportTy Viewport;
	MultisampleTy Multisample;

	InputAssemblyTy InputAssembly;
	RasterizationTy Rasterization;
	DepthStencilTy DepthStencil;
	ColorBlendTy ColorBlend;


};

namespace info {

	struct Blend_ADV
	{
		VkBlendOp                 advance;
		VkBlendOverlapEXT   overlap;
	};

	const char* String_VkBlendOp(VkBlendOp op);

	//constexpr
	VkBlendOp  getVkBlendOp(const uint32_t N) noexcept;

	//constexpr 
	UINT  getVkBlendOpNum(const VkBlendOp op) noexcept;

	const char* String_VkBlendOverlap(VkBlendOverlapEXT op);


	extern constexpr UINT MAX_BLEND_OP = UINT(VK_BLEND_OP_BLUE_EXT) - (UINT)0x3b9d0c20;
	extern constexpr UINT MAX_OVERLAP_OP = UINT(VK_BLEND_OVERLAP_CONJOINT_EXT) + 1;
	extern      uint64_t HAS_BLENDOP[3];


};







#endif