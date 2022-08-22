#pragma once
#include <stdlib.h>
#include <string>
#include <assert.h>
#include <stdio.h>
#include <vector>
#include "types.hpp"
#include "working.h"

#include <vulkan/vulkan.h>
#include "Vk.h"
///#include "base/VulkanTools.h"
#ifdef INCLUDE_MATERIAL_VKVIDEO
#include "VidMaterialVk.h"
typedef VidMaterialVk<3> VideoVk;
#endif

// Macro to get a procedure address based on a vulkan instance
#define GET_INSTANCE_PROC_ADDR(inst, entrypoint)                        \
{                                                                       \
	fp##entrypoint = reinterpret_cast<PFN_vk##entrypoint>(vkGetInstanceProcAddr(inst, "vk"#entrypoint)); \
	if (fp##entrypoint == NULL)                                         \
	{																    \
		exit(1);                                                        \
	}                                                                   \
}

// Macro to get a procedure address based on a vulkan device
#define GET_DEVICE_PROC_ADDR(dev, entrypoint)                           \
{                                                                       \
	fp##entrypoint = reinterpret_cast<PFN_vk##entrypoint>(vkGetDeviceProcAddr(dev, "vk"#entrypoint));   \
	if (fp##entrypoint == NULL)                                         \
	{																    \
		exit(1);                                                        \
	}                                                                   \
}




typedef struct SCBuffer {
	VkImage image;
	VkImageView view;
	VkSampler sampler;
	VkDescriptorImageInfo descriptor;
} SCBuffer;

class SwapChainVk
{
private:
	VkSurfaceKHR surface;
public:
	// Function pointers
	PFN_vkGetPhysicalDeviceSurfaceSupportKHR fpGetPhysicalDeviceSurfaceSupportKHR;
	PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR fpGetPhysicalDeviceSurfaceCapabilitiesKHR;
	PFN_vkGetPhysicalDeviceSurfaceFormatsKHR fpGetPhysicalDeviceSurfaceFormatsKHR;
	PFN_vkGetPhysicalDeviceSurfacePresentModesKHR fpGetPhysicalDeviceSurfacePresentModesKHR;
	PFN_vkCreateSwapchainKHR fpCreateSwapchainKHR;
	PFN_vkDestroySwapchainKHR fpDestroySwapchainKHR;
	PFN_vkGetSwapchainImagesKHR fpGetSwapchainImagesKHR;
	PFN_vkAcquireNextImageKHR fpAcquireNextImageKHR;
	PFN_vkQueuePresentKHR fpQueuePresentKHR;



	VkFormat colorFormat;
	VkColorSpaceKHR colorSpace;
	VkSwapchainKHR swapChain = VK_NULL_HANDLE;
	uint32_t imageCount;
	std::vector<VkImage> images;
	std::vector<SCBuffer> buffers;
	uint32_t queueNodeIndex = UINT32_MAX;

	uint32_t                                    W , H;
	VkRenderPass                   renderPass = VK_NULL_HANDLE;
	VkCommandPool                     cmdPool = VK_NULL_HANDLE;
	std::vector<VkCommandBuffer> drawCmdBuffers;

	VkPipelineStageFlags submitPipelineStages;
	VkSubmitInfo submitInfo;



	struct {
		VkSemaphore presentComplete;
		VkSemaphore renderComplete;
		VkSemaphore  renderCompletes[3];
		VkSemaphore              graphics;
	} semaphores;

	std::vector<VkFence> waitFences;
	std::vector<VkFramebuffer>frameBuffers;


	VkPipelineCache                  pipelineCache = VK_NULL_HANDLE;
	VkPipeline                           pipeline[2] = { VK_NULL_HANDLE,VK_NULL_HANDLE };
	std::vector<VkShaderModule> shaderModules;


	VkDescriptorSetLayout descriptorSetLayout = { VK_NULL_HANDLE };
	VkDescriptorSet descriptorSet = { VK_NULL_HANDLE };
	VkDescriptorPool descriptorPool = { VK_NULL_HANDLE };
	VkPipelineLayout      pipelineLayout = { VK_NULL_HANDLE };

	bool   cmdUpdate[3] = { true,true,true };
	struct
	{
		VkImage image;
		VkDeviceMemory mem;
		VkImageView view;

	} depthStencil;

	struct {
		uint32_t  frame;
	}current;

	void destroyPipelineCache();
	void createPipelineCache();

	void initSurface(void* platformHandle, void* platformWindow);

	void connect();
	void create(uint32_t width, uint32_t height, bool vsync = false);
	void createVR(uint32_t width, uint32_t height, bool vsync = false);

	VkResult acquireNextImage( uint32_t* imageIndex);

	VkResult queuePresent(VkQueue queue, uint32_t imageIndex, VkSemaphore waitSemaphore = VK_NULL_HANDLE);

	void createCommandBuffers();
	void destroyCommandBuffers();

	void createSynchronizationPrimitives();
	void destroySynchronizationPrimitives();

	void recreate();
	void cleanup();
	void cleanupVR();


	void Command();
	bool copy2disp(VkCommandBuffer commandBuffer);

	void Command2();

	template<class M>
	void Command3(M&  mat);

	template<class M>
	void CommandLoop(M& mat, uint32_t cmdID);

	template<class M>
	void CommandInLine(M& mat, VkCommandBuffer cmd, uint32_t i);

	void setImage(VkDescriptorImageInfo& info);

	void createRenderPass();
	void destroyRenderPass();

	void createDepthStencil();
	void destroyDepthStencil();


	void createFrameBuffer();
	void destroyFrameBuffer();


	void createPipeline();
	VkPipelineShaderStageCreateInfo loadShader(std::string fileName, VkShaderStageFlagBits stage);
	void  destroyPipeline();


	void createDescriptors();
	void destroyDescriptors();

	void submit(VkCommandBuffer* cmds);
};


typedef SwapChainVk SwapChainVkTy;