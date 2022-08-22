#include "pch.h"

#include "types.hpp"
#include "working.h"
#include "Vk.h"
#include  "vulkan/vulkan_win32.h"
#include "SwapChain.h"
#include "util/log.hpp"
using namespace aeo;



void SwapChainVk::initSurface(void* platformHandle, void* platformWindow)
{
	VkResult err = VK_SUCCESS;


	VkWin32SurfaceCreateInfoKHR surfaceCreateInfo = {};
	surfaceCreateInfo.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
	surfaceCreateInfo.hinstance = (HINSTANCE)platformHandle;
	surfaceCreateInfo.hwnd = (HWND)platformWindow;
	err = vkCreateWin32SurfaceKHR($instance, &surfaceCreateInfo, nullptr, &surface);


	if (err != VK_SUCCESS) {
		log_bad("Could not create surface!   %s  ", UINT32(err));
	}

	// Get available queue family properties
	uint32_t queueCount;
	vkGetPhysicalDeviceQueueFamilyProperties($physicaldevice, &queueCount, NULL);
	assert(queueCount >= 1);

	std::vector<VkQueueFamilyProperties> queueProps(queueCount);
	vkGetPhysicalDeviceQueueFamilyProperties($physicaldevice, &queueCount, queueProps.data());


	std::vector<VkBool32> supportsPresent(queueCount);
	for (uint32_t i = 0; i < queueCount; i++)
	{
		fpGetPhysicalDeviceSurfaceSupportKHR($physicaldevice, i, surface, &supportsPresent[i]);
	}

	uint32_t graphicsQueueNodeIndex = UINT32_MAX;
	uint32_t presentQueueNodeIndex = UINT32_MAX;
	for (uint32_t i = 0; i < queueCount; i++)
	{
		if ((queueProps[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) != 0)
		{
			if (graphicsQueueNodeIndex == UINT32_MAX)
			{
				graphicsQueueNodeIndex = i;
			}
			if (supportsPresent[i] == VK_TRUE)
			{
				graphicsQueueNodeIndex = i;
				presentQueueNodeIndex = i;
				break;
			}
		}
	}
	if (presentQueueNodeIndex == UINT32_MAX)
	{
		for (uint32_t i = 0; i < queueCount; ++i)
		{
			if (supportsPresent[i] == VK_TRUE)
			{
				presentQueueNodeIndex = i;
				break;
			}
		}
	}

	// Exit if either a graphics or a presenting queue hasn't been found
	if (graphicsQueueNodeIndex == UINT32_MAX || presentQueueNodeIndex == UINT32_MAX)
	{
		log_bad("Could not find a graphics and/or presenting queue!   -1");
	}

	// todo : Add support for separate graphics and presenting queue
	if (graphicsQueueNodeIndex != presentQueueNodeIndex)
	{
		log_bad("Separate graphics and presenting queues are not supported yet! -1");
	}

	queueNodeIndex = graphicsQueueNodeIndex;



}
/**
* Set instance, physical and logical device to use for the swapchain and get all required function pointers
*
* @param instance Vulkan instance to use
* @param physicalDevice Physical device used to query properties and formats relevant to the swapchain
* @param device Logical representation of the device to create the swapchain for
*
*/

void SwapChainVk::connect()
{

	GET_INSTANCE_PROC_ADDR($instance, GetPhysicalDeviceSurfaceSupportKHR);
	GET_INSTANCE_PROC_ADDR($instance, GetPhysicalDeviceSurfaceCapabilitiesKHR);
	                                                             
	GET_INSTANCE_PROC_ADDR($instance, GetPhysicalDeviceSurfaceFormatsKHR);
	GET_INSTANCE_PROC_ADDR($instance, GetPhysicalDeviceSurfacePresentModesKHR);
	GET_DEVICE_PROC_ADDR($device, CreateSwapchainKHR);
	GET_DEVICE_PROC_ADDR($device, DestroySwapchainKHR);
	GET_DEVICE_PROC_ADDR($device, GetSwapchainImagesKHR);
	GET_DEVICE_PROC_ADDR($device, AcquireNextImageKHR);
	GET_DEVICE_PROC_ADDR($device, QueuePresentKHR);


}

void SwapChainVk::create(uint32_t width, uint32_t height, bool vsync)
{

	VkSwapchainKHR oldSwapchain = swapChain;

	// Get physical device surface properties and formats
	VkSurfaceCapabilitiesKHR surfCaps;
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfaceCapabilitiesKHR($physicaldevice, surface, &surfCaps));
	log_cir("SurfaceInformation    supportedCompositeAlpha : %u     \n", (UINT)surfCaps.supportedCompositeAlpha);

	//Get available present modes
	uint32_t presentModeCount;
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfacePresentModesKHR($physicaldevice, surface, &presentModeCount, NULL));
	assert(presentModeCount > 0);

	std::vector<VkPresentModeKHR> presentModes(presentModeCount);
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfacePresentModesKHR($physicaldevice, surface, &presentModeCount, presentModes.data()));

	log_cir("SurfaceInformation    presentModeCount : %u     \n",
		(UINT)presentModeCount);

	uint32_t formatCount;
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfaceFormatsKHR($physicaldevice, surface, &formatCount, NULL));
	assert(formatCount > 0);

	std::vector<VkSurfaceFormatKHR> surfaceFormats(formatCount);
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfaceFormatsKHR($physicaldevice, surface, &formatCount, surfaceFormats.data()));

	for (auto& format : surfaceFormats) {
		log_cir("SurfaceInformation    format  : %u   space %u   \n", (UINT)format.format, (UINT)format.colorSpace);
	}
	if ((formatCount == 1) && (surfaceFormats[0].format == VK_FORMAT_UNDEFINED))
	{
		colorFormat = VK_FORMAT_B8G8R8A8_UNORM;
		colorSpace = surfaceFormats[0].colorSpace;
	}
	else
	{

		bool found_B8G8R8A8_UNORM = false;
		for (auto&& surfaceFormat : surfaceFormats)
		{
			if (surfaceFormat.format == VK_FORMAT_B8G8R8A8_UNORM)
			{
				colorFormat = surfaceFormat.format;
				colorSpace = surfaceFormat.colorSpace;
				found_B8G8R8A8_UNORM = true;
				break;
			}
		}

		// in case VK_FORMAT_B8G8R8A8_UNORM is not available
		// select the first available color format
		if (!found_B8G8R8A8_UNORM)
		{
			colorFormat = surfaceFormats[0].format;
			colorSpace = surfaceFormats[0].colorSpace;
		}
	}



	VkExtent2D swapchainExtent = { width ,height };
	// If width (and height) equals the special value 0xFFFFFFFF, the size of the surface will be set by the swapchain

	if (height != (uint32_t)0)
	{
		// If the surface size is undefined, the size is set to
		// the size of the images requested.
		swapchainExtent.width =width;
		swapchainExtent.height = height;
	}
	else
	{
		// If the surface size is defined, the swap chain size must match
		swapchainExtent.width = 1;
		swapchainExtent.height = 1;
	}


	
	// Select a present mode for the swapchain

	// The VK_PRESENT_MODE_FIFO_KHR mode must always be present as per spec
	// This mode waits for the vertical blank ("v-sync")
	VkPresentModeKHR swapchainPresentMode = VK_PRESENT_MODE_FIFO_KHR;


	if (!vsync)
	{
		for (size_t i = 0; i < presentModeCount; i++)
		{
			
			if (presentModes[i] == VK_PRESENT_MODE_MAILBOX_KHR)
			{
				swapchainPresentMode = VK_PRESENT_MODE_MAILBOX_KHR;
				break;
			}
			/*
			if (presentModes[i] == VK_PRESENT_MODE_IMMEDIATE_KHR) {
				swapchainPresentMode = VK_PRESENT_MODE_IMMEDIATE_KHR;
				break;
			}
			*/


			if ((swapchainPresentMode != VK_PRESENT_MODE_MAILBOX_KHR) && (presentModes[i] == VK_PRESENT_MODE_IMMEDIATE_KHR))
			{
				swapchainPresentMode = VK_PRESENT_MODE_IMMEDIATE_KHR;
			}
		}
	}
	// Determine the number of images
	uint32_t desiredNumberOfSwapchainImages = surfCaps.minImageCount + 1;
	if ((surfCaps.maxImageCount > 0) && (desiredNumberOfSwapchainImages > surfCaps.maxImageCount))
	{
		desiredNumberOfSwapchainImages = surfCaps.maxImageCount;
	}

	// Find the transformation of the surface
	VkSurfaceTransformFlagsKHR preTransform;
	if (surfCaps.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR)
	{
		// We prefer a non-rotated transform
		preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
	}
	else
	{
		preTransform = surfCaps.currentTransform;
	}

	// Find a supported composite alpha format (not all devices support alpha opaque)
	VkCompositeAlphaFlagBitsKHR compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
	// Simply select the first composite alpha format available
	std::vector<VkCompositeAlphaFlagBitsKHR> compositeAlphaFlags = {
		VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
		VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
		VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR,
		VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR,
	};
	for (auto& compositeAlphaFlag : compositeAlphaFlags) {
		if (surfCaps.supportedCompositeAlpha & compositeAlphaFlag) {
			compositeAlpha = compositeAlphaFlag;
			break;
		};
	}

	VkSwapchainCreateInfoKHR swapchainCI = {};
	swapchainCI.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
	swapchainCI.pNext = NULL;
	swapchainCI.surface = surface;
	swapchainCI.minImageCount = desiredNumberOfSwapchainImages;
	swapchainCI.imageFormat = colorFormat;
	swapchainCI.imageColorSpace =( VkColorSpaceKHR)colorSpace;
	swapchainCI.imageExtent = { swapchainExtent.width, swapchainExtent.height };
	swapchainCI.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
	swapchainCI.preTransform = (VkSurfaceTransformFlagBitsKHR)preTransform;
	swapchainCI.imageArrayLayers = 1;
	swapchainCI.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
	swapchainCI.queueFamilyIndexCount = 0;
	swapchainCI.pQueueFamilyIndices = NULL;
	swapchainCI.presentMode = swapchainPresentMode;
	swapchainCI.oldSwapchain = oldSwapchain;
	// Setting clipped to VK_TRUE allows the implementation to discard rendering outside of the surface area
	swapchainCI.clipped = VK_TRUE;
	swapchainCI.compositeAlpha = compositeAlpha;

	// Enable transfer source on swap chain images if supported
	if (surfCaps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) {
		swapchainCI.imageUsage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
	}

	// Enable transfer destination on swap chain images if supported
	if (surfCaps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_DST_BIT) {
		swapchainCI.imageUsage |= VK_IMAGE_USAGE_TRANSFER_DST_BIT;
	}

	VK_CHECK_RESULT(fpCreateSwapchainKHR($device, &swapchainCI, nullptr, &swapChain));

	// If an existing swap chain is re-created, destroy the old swap chain
	// This also cleans up all the presentable images
	if (oldSwapchain != VK_NULL_HANDLE)
	{
		for (uint32_t i = 0; i < imageCount; i++)
		{
			vkDestroyImageView($device, buffers[i].view, nullptr);
		}
		fpDestroySwapchainKHR($device, oldSwapchain, nullptr);
	}
	VK_CHECK_RESULT(fpGetSwapchainImagesKHR($device, swapChain, &imageCount, NULL));

	// Get the swap chain images
	images.resize(imageCount);
	VK_CHECK_RESULT(fpGetSwapchainImagesKHR($device, swapChain, &imageCount, images.data()));

	// Get the swap chain buffers containing the image and imageview
	buffers.resize(imageCount);
	for (uint32_t i = 0; i < imageCount; i++)
	{
		VkImageViewCreateInfo colorAttachmentView = {};
		colorAttachmentView.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		colorAttachmentView.pNext = NULL;
		colorAttachmentView.format = $format.COLORFORMAT;
		colorAttachmentView.components = {
			VK_COMPONENT_SWIZZLE_R,
			VK_COMPONENT_SWIZZLE_G,
			VK_COMPONENT_SWIZZLE_B,
			VK_COMPONENT_SWIZZLE_A
		};
		colorAttachmentView.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		colorAttachmentView.subresourceRange.baseMipLevel = 0;
		colorAttachmentView.subresourceRange.levelCount = 1;
		colorAttachmentView.subresourceRange.baseArrayLayer = 0;
		colorAttachmentView.subresourceRange.layerCount = 1;
		colorAttachmentView.viewType = VK_IMAGE_VIEW_TYPE_2D;
		colorAttachmentView.flags = 0;

		buffers[i].image = images[i];

		colorAttachmentView.image = buffers[i].image;

		VK_CHECK_RESULT(vkCreateImageView($device, &colorAttachmentView, nullptr, &buffers[i].view));

	}

	W = width, H = height;
	recreate();
	if (pipelineCache == VK_NULL_HANDLE) {
		createPipelineCache();
		createSynchronizationPrimitives();
	}
	

}

void SwapChainVk::createVR(uint32_t width, uint32_t height, bool vsync)
{
	VkSwapchainKHR oldSwapchain = swapChain;

	// Get physical device surface properties and formats
	VkSurfaceCapabilitiesKHR surfCaps;
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfaceCapabilitiesKHR($physicaldevice, surface, &surfCaps));

	//Get available present modes
	uint32_t presentModeCount;
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfacePresentModesKHR($physicaldevice, surface, &presentModeCount, NULL));
	assert(presentModeCount > 0);

	std::vector<VkPresentModeKHR> presentModes(presentModeCount);
	VK_CHECK_RESULT(fpGetPhysicalDeviceSurfacePresentModesKHR($physicaldevice, surface, &presentModeCount, presentModes.data()));


	VkExtent2D swapchainExtent = { width , height };
	// If width (and height) equals the special value 0xFFFFFFFF, the size of the surface will be set by the swapchain

	printf("Surface   %u   %u   W,H   %u %u     \n", surfCaps.currentExtent.width, surfCaps.currentExtent.height, width, height);

	// Select a present mode for the swapchain

	// The VK_PRESENT_MODE_FIFO_KHR mode must always be present as per spec
	// This mode waits for the vertical blank ("v-sync")
	VkPresentModeKHR swapchainPresentMode = VK_PRESENT_MODE_FIFO_KHR;

	//If v-sync is not requested, try to find a mailbox mode
	// It's the lowest latency non-tearing present mode available
	if (!vsync)
	{
		for (size_t i = 0; i < presentModeCount; i++)
		{
			if (presentModes[i] == VK_PRESENT_MODE_MAILBOX_KHR)
			{
				swapchainPresentMode = VK_PRESENT_MODE_MAILBOX_KHR;
				break;
			}
			if ((swapchainPresentMode != VK_PRESENT_MODE_MAILBOX_KHR) && (presentModes[i] == VK_PRESENT_MODE_IMMEDIATE_KHR))
			{
				swapchainPresentMode = VK_PRESENT_MODE_IMMEDIATE_KHR;
			}
		}
	}

	// Determine the number of images
	uint32_t desiredNumberOfSwapchainImages = surfCaps.minImageCount + 1;
	if ((surfCaps.maxImageCount > 0) && (desiredNumberOfSwapchainImages > surfCaps.maxImageCount))
	{
		desiredNumberOfSwapchainImages = surfCaps.maxImageCount;
	}

	// Find the transformation of the surface
	VkSurfaceTransformFlagsKHR preTransform;
	if (surfCaps.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR)
	{
		// We prefer a non-rotated transform
		preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
	}
	else
	{
		preTransform = surfCaps.currentTransform;
	}

	// Find a supported composite alpha format (not all devices support alpha opaque)
	VkCompositeAlphaFlagBitsKHR compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
	// Simply select the first composite alpha format available
	std::vector<VkCompositeAlphaFlagBitsKHR> compositeAlphaFlags = {
		VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
		VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
		VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR,
		VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR,
	};
	for (auto& compositeAlphaFlag : compositeAlphaFlags) {
		if (surfCaps.supportedCompositeAlpha & compositeAlphaFlag) {
			compositeAlpha = compositeAlphaFlag;
			break;
		};
	}

	VkSwapchainCreateInfoKHR swapchainCI = {};
	swapchainCI.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
	swapchainCI.pNext = NULL;
	swapchainCI.surface = surface;
	swapchainCI.minImageCount = desiredNumberOfSwapchainImages;
	swapchainCI.imageFormat = colorFormat;
	swapchainCI.imageColorSpace = colorSpace;
	swapchainCI.imageExtent = { swapchainExtent.width, swapchainExtent.height };
	swapchainCI.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
	swapchainCI.preTransform = (VkSurfaceTransformFlagBitsKHR)preTransform;
	swapchainCI.imageArrayLayers = 2;
	swapchainCI.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
	swapchainCI.queueFamilyIndexCount = 0;
	swapchainCI.pQueueFamilyIndices = NULL;
	swapchainCI.presentMode = swapchainPresentMode;
	swapchainCI.oldSwapchain = oldSwapchain;
	// Setting clipped to VK_TRUE allows the implementation to discard rendering outside of the surface area
	swapchainCI.clipped = VK_TRUE;
	swapchainCI.compositeAlpha = compositeAlpha;

	// Enable transfer source on swap chain images if supported
	if (surfCaps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) {
		swapchainCI.imageUsage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
	}

	// Enable transfer destination on swap chain images if supported
	if (surfCaps.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_DST_BIT) {
		swapchainCI.imageUsage |= VK_IMAGE_USAGE_TRANSFER_DST_BIT;
	}

	VK_CHECK_RESULT(fpCreateSwapchainKHR($device, &swapchainCI, nullptr, &swapChain));

	// If an existing swap chain is re-created, destroy the old swap chain
	// This also cleans up all the presentable images
	if (oldSwapchain != VK_NULL_HANDLE)
	{
		for (uint32_t i = 0; i < imageCount; i++)
		{
			vkDestroyImageView($device, buffers[i].view, nullptr);
		}
		fpDestroySwapchainKHR($device, oldSwapchain, nullptr);
	}


	W = width, H = height;

	createCommandBuffers();
	createSynchronizationPrimitives();
	createDepthStencil();
	createRenderPass();
	createFrameBuffer();
	createDescriptors();

}

void SwapChainVk::createCommandBuffers()
{


	//vkGetDeviceQueue($device, , 0, &queue);
	VkCommandPoolCreateInfo cmdPoolInfo = {};
	cmdPoolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
	cmdPoolInfo.queueFamilyIndex = $queueIdx.stcg;
	cmdPoolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
	VK_CHECK_RESULT(vkCreateCommandPool($device, &cmdPoolInfo, nullptr, &cmdPool));

	drawCmdBuffers.resize(imageCount);
	VkCommandBufferAllocateInfo cmdBufAllocateInfo =
		vka::plysm::commandBufferAllocateInfo(
			cmdPool,
			VK_COMMAND_BUFFER_LEVEL_PRIMARY,
			static_cast<uint32_t>(drawCmdBuffers.size()));

	VK_CHECK_RESULT(vkAllocateCommandBuffers($device, &cmdBufAllocateInfo, drawCmdBuffers.data()));
};
void SwapChainVk::destroyCommandBuffers()
{
	if (cmdPool != VK_NULL_HANDLE) {
	vkFreeCommandBuffers($device, cmdPool, static_cast<uint32_t>(drawCmdBuffers.size()), drawCmdBuffers.data());
	vkDestroyCommandPool($device, cmdPool, nullptr);
		cmdPool = VK_NULL_HANDLE;
	}
};

void SwapChainVk::createSynchronizationPrimitives()
{


	VkSemaphoreCreateInfo semaphoreCreateInfo = vka::plysm::semaphoreCreateInfo();
	// Create a semaphore used to synchronize image presentation
	// Ensures that the image is displayed before we start submitting new commands to the queu
	VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCreateInfo, nullptr, &semaphores.presentComplete));
	// Create a semaphore used to synchronize command submission
	// Ensures that the image is not presented until all commands have been sumbitted and executed
	for (int i = 0; i < 3; i++) {
		VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCreateInfo, nullptr, &semaphores.renderCompletes[i]));
	}

	VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCreateInfo, nullptr, &semaphores.renderComplete));

	VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCreateInfo, nullptr, &semaphores.graphics));

	// Set up submit info structure
	// Semaphores will stay the same during application lifetime
	// Command buffer submission info is set by each example
	submitPipelineStages = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

	submitInfo = vka::plysm::submitInfo();
	submitInfo.pWaitDstStageMask = &submitPipelineStages;
	submitInfo.waitSemaphoreCount = 1;
	submitInfo.pWaitSemaphores = &semaphores.presentComplete;
	submitInfo.signalSemaphoreCount = 1;
	submitInfo.pSignalSemaphores = &semaphores.renderComplete;

	VkFenceCreateInfo fenceCreateInfo = vka::plysm::fenceCreateInfo(VK_FENCE_CREATE_SIGNALED_BIT);
	waitFences.resize(drawCmdBuffers.size());
	for (auto& fence : waitFences) {
		VK_CHECK_RESULT(vkCreateFence($device, &fenceCreateInfo, nullptr, &fence));
	}

}
void SwapChainVk::destroySynchronizationPrimitives() {

	if (semaphores.presentComplete != VK_NULL_HANDLE) {

		vkDestroySemaphore($device, semaphores.presentComplete, nullptr);
		vkDestroySemaphore($device, semaphores.renderComplete, nullptr);
		for (int i = 0; i < 3; i++)vkDestroySemaphore($device, semaphores.renderCompletes[i], nullptr);

		vkDestroySemaphore($device, semaphores.graphics, nullptr);


		for (auto& fence : waitFences) {
			vkDestroyFence($device, fence, nullptr);
		};
		semaphores.presentComplete = VK_NULL_HANDLE;
	}


}

void SwapChainVk::createPipelineCache()
{
	VkPipelineCacheCreateInfo pipelineCacheCreateInfo = {};
	pipelineCacheCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
	VK_CHECK_RESULT(vkCreatePipelineCache($device, &pipelineCacheCreateInfo, nullptr, &pipelineCache));

};
void SwapChainVk::destroyPipelineCache()
{
	if (pipelineCache != VK_NULL_HANDLE) {
		vkDestroyPipelineCache($device, pipelineCache, nullptr);
		pipelineCache = VK_NULL_HANDLE;
	}
};

VkResult SwapChainVk::acquireNextImage(uint32_t* imageIndex)
{
	// By setting timeout to UINT64_MAX we will always wait until the next image has been acquired or an actual error is thrown
	// With that we don't have to handle VK_NOT_READY
	return fpAcquireNextImageKHR($device, swapChain, UINT64_MAX, semaphores.presentComplete, (VkFence)nullptr, imageIndex);
}
VkResult SwapChainVk::queuePresent(VkQueue queue, uint32_t imageIndex, VkSemaphore waitSemaphore)
{
	VkPresentInfoKHR presentInfo = {};
	presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
	presentInfo.pNext = NULL;
	presentInfo.swapchainCount = 1;
	presentInfo.pSwapchains = &swapChain;
	presentInfo.pImageIndices = &imageIndex;
	// Check if a wait semaphore has been specified to wait for before presenting the image
	if (waitSemaphore != VK_NULL_HANDLE)
	{
		presentInfo.pWaitSemaphores = &waitSemaphore;
		presentInfo.waitSemaphoreCount = 1;
	}
	return fpQueuePresentKHR(queue, &presentInfo);
}

void SwapChainVk::recreate()
{

	if (cmdPool != VK_NULL_HANDLE) {
		destroyCommandBuffers();
		destroyFrameBuffer();
		destroyRenderPass();
		destroyDepthStencil();
	}


	createCommandBuffers();
	createDepthStencil();
	createRenderPass();
	createFrameBuffer();
	
}

void SwapChainVk::cleanup()
{
	destroyPipelineCache();
	destroySynchronizationPrimitives();
	destroyCommandBuffers();
	destroyFrameBuffer();
	destroyRenderPass();
	destroyDepthStencil();
	if (swapChain != VK_NULL_HANDLE)
	{
		for (uint32_t i = 0; i < imageCount; i++)
		{

			vkDestroyImageView($device, buffers[i].view, nullptr);
		}
	}
	if (surface != VK_NULL_HANDLE)
	{
		fpDestroySwapchainKHR($device, swapChain, nullptr);
		vkDestroySurfaceKHR($instance, surface, nullptr);
	}
	surface = VK_NULL_HANDLE;
	swapChain = VK_NULL_HANDLE;
}
void SwapChainVk::cleanupVR()
{

	if (swapChain != VK_NULL_HANDLE)
	{
		for (uint32_t i = 0; i < imageCount; i++)
		{
			vkDestroySampler($device, buffers[i].sampler, nullptr);
			vkDestroyImageView($device, buffers[i].view, nullptr);
		}

		if (surface != VK_NULL_HANDLE)
		{
			fpDestroySwapchainKHR($device, swapChain, nullptr);
			vkDestroySurfaceKHR($instance, surface, nullptr);
		}
		surface = VK_NULL_HANDLE;
		swapChain = VK_NULL_HANDLE;

		destroySynchronizationPrimitives();
		destroyCommandBuffers();
	}

}


void SwapChainVk::Command()
{

	VkCommandBufferBeginInfo cmdBufInfo = vka::plysm::commandBufferBeginInfo();
	VkClearValue clearValues[2];
	clearValues[0].color = __defaultClearColor;
	clearValues[1].depthStencil = { 1.0f, 0 };


	VkRenderPassBeginInfo renderPassBeginInfo = vka::plysm::renderPassBeginInfo();
	renderPassBeginInfo.renderPass                = renderPass;
	renderPassBeginInfo.renderArea.offset.x = 0; 
	renderPassBeginInfo.renderArea.offset.y = 0;
	renderPassBeginInfo.renderArea.extent.width  = W;
	renderPassBeginInfo.renderArea.extent.height = H;
	renderPassBeginInfo.clearValueCount = 2;
	renderPassBeginInfo.pClearValues = clearValues;

	AttachmentsVk* atta = nullptr;
	if (atta == nullptr) {
		if (!$tank.takeout(atta, 0)) {
			log_bad(" not found  WindowVk.");
		};
	};
	///EYEIMAGE    ->    SHADER_READ_ONLY    // COLOR ATTACHMENT

	for (int32_t i = 0; i < drawCmdBuffers.size(); ++i) {

		renderPassBeginInfo.framebuffer = frameBuffers[i];

		VK_CHECK_RESULT(vkBeginCommandBuffer(drawCmdBuffers[i], &cmdBufInfo));

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask         = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel      = 0;
		subresourceRange.levelCount           =  1;
		subresourceRange.baseArrayLayer = 0;
		subresourceRange.layerCount          = 2;

		vka::shelve::setImageLayout(
			drawCmdBuffers[i],
			atta->color.image,
			VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			subresourceRange
		);
		
		vkCmdBeginRenderPass(drawCmdBuffers[i], &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);

		VkViewport viewport = vka::plysm::viewport((float)W, (float)H, 0.0f, 1.0f);
		VkRect2D scissor = vka::plysm::rect2D(W,H, 0, 0);


		vkCmdSetViewport(drawCmdBuffers[i], 0, 1, &viewport);
		vkCmdSetScissor(drawCmdBuffers[i], 0, 1, &scissor);

		vkCmdBindPipeline(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline[0]);

		vkCmdBindDescriptorSets(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &(descriptorSet), 0, nullptr);


		vkCmdDraw(drawCmdBuffers[i], 3, 1, 0, 0);

		vkCmdEndRenderPass(drawCmdBuffers[i]);


		vka::shelve::setImageLayout(
			drawCmdBuffers[i],
			atta->color.image,
			VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			subresourceRange
		);

		

		///setvrImg(drawCmdBuffers[i]);
		VK_CHECK_RESULT(vkEndCommandBuffer(drawCmdBuffers[i]));
	}


};
bool SwapChainVk::copy2disp(VkCommandBuffer commandBuffer) {


	AttachmentsVk* atta = nullptr;
	if (atta == nullptr) {
		if (!$tank.takeout(atta, 0)) {
			log_bad(" not found  WindowVk.");
		};
	};
	///EYEIMAGE    ->    SHADER_READ_ONLY    // COLOR ATTACHMENT
	vka::shelve::setImageLayout(
		commandBuffer,
		atta->color.image,
		VK_IMAGE_ASPECT_COLOR_BIT,
		atta->color.Info.imageLayout,
		VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL
	);

	atta->color.Info.imageLayout   = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL; ///VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

///vkCmdPipelineBarrier(commandBuffer, VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, NULL, 0, NULL, 1, &imageMemoryBarrier);
	return true;

}


void SwapChainVk::Command2()
{

	VkCommandBufferBeginInfo cmdBufInfo = vka::plysm::commandBufferBeginInfo();
	VkClearValue clearValues[2];
	clearValues[0].color = __defaultClearColor;
	clearValues[1].depthStencil = { 1.0f, 0 };


	VkRenderPassBeginInfo renderPassBeginInfo = vka::plysm::renderPassBeginInfo();
	renderPassBeginInfo.renderPass = renderPass;
	renderPassBeginInfo.renderArea.offset.x = 0;
	renderPassBeginInfo.renderArea.offset.y = 0;
	renderPassBeginInfo.renderArea.extent.width = W;
	renderPassBeginInfo.renderArea.extent.height = H;
	renderPassBeginInfo.clearValueCount = 2;
	renderPassBeginInfo.pClearValues = clearValues;

	AttachmentsVk* atta = nullptr;
	if (atta == nullptr) {
		if (!$tank.takeout(atta, 0)) {
			log_bad(" not found  WindowVk.");
		};
	};
	///EYEIMAGE    ->    SHADER_READ_ONLY    // COLOR ATTACHMENT

	for (int32_t i = 0; i < drawCmdBuffers.size(); ++i) {

		renderPassBeginInfo.framebuffer = frameBuffers[i];

		VK_CHECK_RESULT(vkBeginCommandBuffer(drawCmdBuffers[i], &cmdBufInfo));

		vkCmdBeginRenderPass(drawCmdBuffers[i], &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);

		VkViewport viewport = vka::plysm::viewport((float)W, (float)H, 0.0f, 1.0f);
		VkRect2D scissor = vka::plysm::rect2D(W, H, 0, 0);


		vkCmdSetViewport(drawCmdBuffers[i], 0, 1, &viewport);
		vkCmdSetScissor(drawCmdBuffers[i], 0, 1, &scissor);


		vkCmdBindPipeline(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipeline[0]);
		vkCmdBindDescriptorSets(drawCmdBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &(descriptorSet), 0, nullptr);
		vkCmdDraw(drawCmdBuffers[i], 4, 1, 0, 0);

		vkCmdEndRenderPass(drawCmdBuffers[i]);
		VK_CHECK_RESULT(vkEndCommandBuffer(drawCmdBuffers[i]));

	}


};
void SwapChainVk::setImage(VkDescriptorImageInfo& info) {

	std::vector<VkWriteDescriptorSet> writeDescriptorSets = {
		///vka::plysm::writeDescriptorSet(descriptorSet, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 0, &uniform.descriptor),
		vka::plysm::writeDescriptorSet(descriptorSet, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 0, &(info)),
	};
	vkUpdateDescriptorSets($device, static_cast<uint32_t>(writeDescriptorSets.size()), writeDescriptorSets.data(), 0, nullptr);


}


template<class M>
void SwapChainVk::Command3(M&  mat)
{


	VkCommandBufferBeginInfo cmdBufInfo = vka::plysm::commandBufferBeginInfo();
	VkClearValue clearValues[2];
	clearValues[0].color = __defaultClearColor;
	clearValues[1].depthStencil = { 1.0f, 0 };


	VkRenderPassBeginInfo renderPassBeginInfo = vka::plysm::renderPassBeginInfo();
	renderPassBeginInfo.renderPass = renderPass;
	renderPassBeginInfo.renderArea.offset.x = 0;
	renderPassBeginInfo.renderArea.offset.y = 0;
	renderPassBeginInfo.renderArea.extent.width = W;
	renderPassBeginInfo.renderArea.extent.height = H;
	renderPassBeginInfo.clearValueCount = 2;
	renderPassBeginInfo.pClearValues = clearValues;

	AttachmentsVk* atta = nullptr;
	if (atta == nullptr) {
		if (!$tank.takeout(atta, 0)) {
			log_bad(" not found  WindowVk.");
		};
	};
	///EYEIMAGE    ->    SHADER_READ_ONLY    // COLOR ATTACHMENT

	for (int32_t i = 0; i < drawCmdBuffers.size(); ++i) {

		renderPassBeginInfo.framebuffer = frameBuffers[i];

		VK_CHECK_RESULT(vkBeginCommandBuffer(drawCmdBuffers[i], &cmdBufInfo));

		vkCmdBeginRenderPass(drawCmdBuffers[i], &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);

		VkViewport viewport = vka::plysm::viewport((float)W, (float)H, 0.0f, 1.0f);
		VkRect2D scissor = vka::plysm::rect2D(W, H, 0, 0);


		vkCmdSetViewport(drawCmdBuffers[i], 0, 1, &viewport);
		vkCmdSetScissor(drawCmdBuffers[i], 0, 1, &scissor);


		mat.make(drawCmdBuffers[i], semaphores.renderCompletes[i]);

		vkCmdEndRenderPass(drawCmdBuffers[i]);
		VK_CHECK_RESULT(vkEndCommandBuffer(drawCmdBuffers[i]));

	}


};


template<class M>
void SwapChainVk::CommandLoop(M& mat,uint32_t i)
{
		static  bool ini = true;
		static VkCommandBufferBeginInfo cmdBufInfo = vka::plysm::commandBufferBeginInfo();
		static  VkClearValue clearValues[2];
		static VkRenderPassBeginInfo renderPassBeginInfo = vka::plysm::renderPassBeginInfo();


		static AttachmentsVk* atta = nullptr;

	   if (ini) {

		//ini = false;
		if (atta == nullptr) {
			if (!$tank.takeout(atta, 0)) {
				log_bad(" not found  WindowVk.");
			};
		};

		clearValues[0].color = __defaultClearColor;
		clearValues[1].depthStencil = { 1.0f, 0 };

		renderPassBeginInfo.renderPass = renderPass;
		renderPassBeginInfo.renderArea.offset.x = 0;
		renderPassBeginInfo.renderArea.offset.y = 0;
		renderPassBeginInfo.renderArea.extent.width = W;
		renderPassBeginInfo.renderArea.extent.height = H;
		renderPassBeginInfo.clearValueCount = 2;
		renderPassBeginInfo.pClearValues = clearValues;
	}

		renderPassBeginInfo.framebuffer = frameBuffers[i];

		VK_CHECK_RESULT(vkBeginCommandBuffer(drawCmdBuffers[i], &cmdBufInfo));

		vkCmdBeginRenderPass(drawCmdBuffers[i], &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);

		VkViewport viewport = vka::plysm::viewport((float)W, (float)H, 0.0f, 1.0f);
		VkRect2D scissor = vka::plysm::rect2D(W, H, 0, 0);


		vkCmdSetViewport(drawCmdBuffers[i], 0, 1, &viewport);
		vkCmdSetScissor(drawCmdBuffers[i], 0, 1, &scissor);


		mat.make(drawCmdBuffers[i], semaphores.renderCompletes[i]);

		vkCmdEndRenderPass(drawCmdBuffers[i]);
		VK_CHECK_RESULT(vkEndCommandBuffer(drawCmdBuffers[i]));




};

template<class M>
void SwapChainVk::CommandInLine(M& mat, VkCommandBuffer cmd, uint32_t i)
{
	static  bool ini = true;

	static  VkClearValue clearValues[2];
	static VkRenderPassBeginInfo renderPassBeginInfo = vka::plysm::renderPassBeginInfo();

	static AttachmentsVk* atta = nullptr;

	if (ini) {

		ini = false;
		if (atta == nullptr) {
			if (!$tank.takeout(atta, 0)) {
				log_bad(" not found  WindowVk.");
			};
		};

		clearValues[0].color = __defaultClearColor;
		clearValues[1].depthStencil = { 1.0f, 0 };

		renderPassBeginInfo.renderPass = renderPass;
		renderPassBeginInfo.renderArea.offset.x = 0;
		renderPassBeginInfo.renderArea.offset.y = 0;
		renderPassBeginInfo.renderArea.extent.width = W;
		renderPassBeginInfo.renderArea.extent.height = H;
		renderPassBeginInfo.clearValueCount = 2;
		renderPassBeginInfo.pClearValues = clearValues;
	}

	renderPassBeginInfo.framebuffer = frameBuffers[i];

	vkCmdBeginRenderPass(cmd, &renderPassBeginInfo, VK_SUBPASS_CONTENTS_INLINE);
	VkViewport viewport = vka::plysm::viewport((float)W, (float)H, 0.0f, 1.0f);
	VkRect2D scissor = vka::plysm::rect2D(W, H, 0, 0);
	vkCmdSetViewport(cmd, 0, 1, &viewport);
	vkCmdSetScissor(cmd, 0, 1, &scissor);
	mat.make(cmd, semaphores.renderCompletes[i]);
	vkCmdEndRenderPass(cmd);


};

void SwapChainVk::createRenderPass()
{
	std::array<VkAttachmentDescription, 2> attachments = {};
	// Color attachment
	attachments[0].format = $format.COLORFORMAT;
	attachments[0].samples = VK_SAMPLE_COUNT_1_BIT;
	attachments[0].loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
	attachments[0].storeOp = VK_ATTACHMENT_STORE_OP_STORE;
	attachments[0].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
	attachments[0].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
	attachments[0].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
	attachments[0].finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
	// Depth attachment
	attachments[1].format = $format.DEPTHFORMAT;
	attachments[1].samples = VK_SAMPLE_COUNT_1_BIT;
	attachments[1].loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
	attachments[1].storeOp = VK_ATTACHMENT_STORE_OP_STORE;
	attachments[1].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
	attachments[1].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
	attachments[1].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
	attachments[1].finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

	VkAttachmentReference colorReference = {};
	colorReference.attachment = 0;
	colorReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

	VkAttachmentReference depthReference = {};
	depthReference.attachment = 1;
	depthReference.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

	VkSubpassDescription subpassDescription = {};
	subpassDescription.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
	subpassDescription.colorAttachmentCount = 1;
	subpassDescription.pColorAttachments = &colorReference;
	subpassDescription.pDepthStencilAttachment = &depthReference;
	subpassDescription.inputAttachmentCount = 0;
	subpassDescription.pInputAttachments = nullptr;
	subpassDescription.preserveAttachmentCount = 0;
	subpassDescription.pPreserveAttachments = nullptr;
	subpassDescription.pResolveAttachments = nullptr;

	// Subpass dependencies for layout transitions
	std::array<VkSubpassDependency, 2> dependencies;

	dependencies[0].srcSubpass = VK_SUBPASS_EXTERNAL;
	dependencies[0].dstSubpass = 0;
	dependencies[0].srcStageMask = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
	dependencies[0].dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
	dependencies[0].srcAccessMask = VK_ACCESS_MEMORY_READ_BIT;
	dependencies[0].dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
	dependencies[0].dependencyFlags = VK_DEPENDENCY_BY_REGION_BIT;

	dependencies[1].srcSubpass = 0;
	dependencies[1].dstSubpass = VK_SUBPASS_EXTERNAL;
	dependencies[1].srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
	dependencies[1].dstStageMask = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
	dependencies[1].srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
	dependencies[1].dstAccessMask = VK_ACCESS_MEMORY_READ_BIT;
	dependencies[1].dependencyFlags = VK_DEPENDENCY_BY_REGION_BIT;

	VkRenderPassCreateInfo renderPassInfo = {};
	renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
	renderPassInfo.attachmentCount = static_cast<uint32_t>(attachments.size());
	renderPassInfo.pAttachments = attachments.data();
	renderPassInfo.subpassCount = 1;
	renderPassInfo.pSubpasses = &subpassDescription;
	renderPassInfo.dependencyCount = static_cast<uint32_t>(dependencies.size());
	renderPassInfo.pDependencies = dependencies.data();

	VK_CHECK_RESULT(vkCreateRenderPass($device, &renderPassInfo, nullptr, &renderPass));

}
void SwapChainVk::destroyRenderPass() {
	vkDestroyRenderPass($device, renderPass, nullptr);
};


void SwapChainVk::createFrameBuffer()
{

	VkImageView attachments[2];
	attachments[1] = depthStencil.view;
	VkFramebufferCreateInfo frameBufferCreateInfo = {};
	frameBufferCreateInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
	frameBufferCreateInfo.pNext = NULL;
	frameBufferCreateInfo.renderPass = renderPass;
	frameBufferCreateInfo.attachmentCount = 2;
	frameBufferCreateInfo.pAttachments = attachments;
	frameBufferCreateInfo.width  = W;
	frameBufferCreateInfo.height = H;
	frameBufferCreateInfo.layers = 1;

	// Create frame buffers for every swap chain image
	frameBuffers.resize(imageCount);
	for (uint32_t i = 0; i < frameBuffers.size(); i++)
	{
		attachments[0] = buffers[i].view;
		VK_CHECK_RESULT(vkCreateFramebuffer($device, &frameBufferCreateInfo, nullptr, &frameBuffers[i]));
	};

};
void SwapChainVk::destroyFrameBuffer() {
	for (uint32_t i = 0; i < frameBuffers.size(); i++)
	{
		vkDestroyFramebuffer($device, frameBuffers[i], nullptr);
	}
};

void SwapChainVk::createDepthStencil()
{

	VkImageCreateInfo imageCI{};
	imageCI.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
	imageCI.imageType = VK_IMAGE_TYPE_2D;
	imageCI.format = $format.DEPTHFORMAT;
	imageCI.extent = { W, H, 1 };
	imageCI.mipLevels = 1;
	imageCI.arrayLayers = 1;
	imageCI.samples = VK_SAMPLE_COUNT_1_BIT;
	imageCI.tiling = VK_IMAGE_TILING_OPTIMAL;
	imageCI.usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;

	VK_CHECK_RESULT(vkCreateImage($device, &imageCI, nullptr, &depthStencil.image));
	VkMemoryRequirements memReqs{};
	vkGetImageMemoryRequirements($device, depthStencil.image, &memReqs);

	VkMemoryAllocateInfo memAllloc{};
	memAllloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
	memAllloc.allocationSize = memReqs.size;
	memAllloc.memoryTypeIndex = vka::shelve::getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
	VK_CHECK_RESULT(vkAllocateMemory($device, &memAllloc, nullptr, &depthStencil.mem));
	VK_CHECK_RESULT(vkBindImageMemory($device, depthStencil.image, depthStencil.mem, 0));

	VkImageViewCreateInfo imageViewCI{};
	imageViewCI.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
	imageViewCI.viewType = VK_IMAGE_VIEW_TYPE_2D;
	imageViewCI.image = depthStencil.image;
	imageViewCI.format = $format.DEPTHFORMAT;
	imageViewCI.subresourceRange.baseMipLevel = 0;
	imageViewCI.subresourceRange.levelCount = 1;
	imageViewCI.subresourceRange.baseArrayLayer = 0;
	imageViewCI.subresourceRange.layerCount = 1;
	imageViewCI.subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT;
	// Stencil aspect should only be set on depth + stencil formats (VK_FORMAT_D16_UNORM_S8_UINT..VK_FORMAT_D32_SFLOAT_S8_UINT

	if (VkFormat _DEPTHFORMAT = $format.DEPTHFORMAT; _DEPTHFORMAT >= VK_FORMAT_D16_UNORM_S8_UINT) {
		imageViewCI.subresourceRange.aspectMask |= VK_IMAGE_ASPECT_STENCIL_BIT;
	}
	VK_CHECK_RESULT(vkCreateImageView($device, &imageViewCI, nullptr, &depthStencil.view));

};
void SwapChainVk::destroyDepthStencil() {
	vkDestroyImageView($device, depthStencil.view, nullptr);
	vkDestroyImage($device, depthStencil.image, nullptr);
	vkFreeMemory($device, depthStencil.mem, nullptr);
};


void SwapChainVk::createPipeline() {

	VkPipelineInputAssemblyStateCreateInfo inputAssemblyStateCI;
	VkPipelineColorBlendAttachmentState blendAttachmentState = vka::plysm::pipelineColorBlendAttachmentState(0xf, VK_FALSE);
	inputAssemblyStateCI = vka::plysm::pipelineInputAssemblyStateCreateInfo(VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, 0, VK_FALSE);
	VkPipelineRasterizationStateCreateInfo rasterizationStateCI = vka::plysm::pipelineRasterizationStateCreateInfo(VK_POLYGON_MODE_FILL, VK_CULL_MODE_BACK_BIT, VK_FRONT_FACE_COUNTER_CLOCKWISE);

	VkPipelineColorBlendStateCreateInfo colorBlendStateCI = vka::plysm::pipelineColorBlendStateCreateInfo(1, &blendAttachmentState);
	VkPipelineDepthStencilStateCreateInfo depthStencilStateCI = vka::plysm::pipelineDepthStencilStateCreateInfo(VK_TRUE, VK_TRUE, VK_COMPARE_OP_LESS_OR_EQUAL);// VK_COMPARE_OP_GREATER_OR_EQUAL);// VK_COMPARE_OP_ALWAYS);// 
	VkPipelineViewportStateCreateInfo viewportStateCI = vka::plysm::pipelineViewportStateCreateInfo(1, 1, 0);


	VkPipelineMultisampleStateCreateInfo multisampleStateCI = vka::plysm::pipelineMultisampleStateCreateInfo(VK_SAMPLE_COUNT_1_BIT);

	std::vector<VkDynamicState> dynamicStateEnables = { VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };
	VkPipelineDynamicStateCreateInfo dynamicStateCI = vka::plysm::pipelineDynamicStateCreateInfo(dynamicStateEnables);

	VkGraphicsPipelineCreateInfo pipelineCI = vka::plysm::pipelineCreateInfo(pipelineLayout, renderPass);
	std::array<VkPipelineShaderStageCreateInfo, 2> shaderStages;
	VkPipelineVertexInputStateCreateInfo emptyInputState = vka::plysm::pipelineVertexInputStateCreateInfo();
	pipelineCI.pVertexInputState = &emptyInputState;
	shaderStages[0] = loadShader(getAssetPath() + "surface/view.vert.spv", VK_SHADER_STAGE_VERTEX_BIT);
	shaderStages[1] = loadShader(getAssetPath() + "surface/view.frag.spv", VK_SHADER_STAGE_FRAGMENT_BIT);


	pipelineCI.pInputAssemblyState = &inputAssemblyStateCI;
	pipelineCI.pRasterizationState = &rasterizationStateCI;
	pipelineCI.pColorBlendState = &colorBlendStateCI;
	pipelineCI.pMultisampleState = &multisampleStateCI;
	pipelineCI.pViewportState = &viewportStateCI;
	pipelineCI.pDepthStencilState = &depthStencilStateCI;
	pipelineCI.pDynamicState = &dynamicStateCI;

	pipelineCI.pStages = shaderStages.data();
	pipelineCI.stageCount = 2;


	VK_CHECK_RESULT(vkCreateGraphicsPipelines($device, pipelineCache, 1, &pipelineCI, nullptr, &pipeline[0]));


};
VkPipelineShaderStageCreateInfo SwapChainVk::loadShader(std::string fileName, VkShaderStageFlagBits stage)
{
	VkPipelineShaderStageCreateInfo shaderStage = {};
	shaderStage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
	shaderStage.stage = stage;
	shaderStage.module = vka::shelve::loadShader(fileName.c_str(), $device);
	shaderStage.pName = "main"; // todo : make param
	assert(shaderStage.module != VK_NULL_HANDLE);
	shaderModules.push_back(shaderStage.module);
	return shaderStage;
}
void SwapChainVk::destroyPipeline() {

	for (auto& shaderModule : shaderModules)
	{
		vkDestroyShaderModule($device, shaderModule, nullptr);
	};

	vkDestroyPipeline($device, pipeline[0], nullptr); pipeline[0] = VK_NULL_HANDLE;

};

void SwapChainVk::createDescriptors()
{

	std::vector<VkDescriptorPoolSize> poolSizes = {
		///vka::plysm::descriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1),
		vka::plysm::descriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1)
	};
	VkDescriptorPoolCreateInfo descriptorPoolInfo = vka::plysm::descriptorPoolCreateInfo(static_cast<uint32_t>(poolSizes.size()), poolSizes.data(), 1);
	VK_CHECK_RESULT(vkCreateDescriptorPool($device, &descriptorPoolInfo, nullptr, &descriptorPool));

	/*
		Layouts
	*/

	std::vector<VkDescriptorSetLayoutBinding> setLayoutBindings = {
		///vka::plysm::descriptorSetLayoutBinding(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT, 0),
		vka::plysm::descriptorSetLayoutBinding(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, VK_SHADER_STAGE_FRAGMENT_BIT, 0)
	};

	VkDescriptorSetLayoutCreateInfo descriptorLayout = vka::plysm::descriptorSetLayoutCreateInfo(setLayoutBindings);
	VK_CHECK_RESULT(vkCreateDescriptorSetLayout($device, &descriptorLayout, nullptr, &descriptorSetLayout));
	VkPipelineLayoutCreateInfo pPipelineLayoutCreateInfo = vka::plysm::pipelineLayoutCreateInfo(&descriptorSetLayout, 1);
	VK_CHECK_RESULT(vkCreatePipelineLayout($device, &pPipelineLayoutCreateInfo, nullptr, &pipelineLayout));

	VkDescriptorSetAllocateInfo allocateInfo = vka::plysm::descriptorSetAllocateInfo(descriptorPool, &descriptorSetLayout, 1);
	VK_CHECK_RESULT(vkAllocateDescriptorSets($device, &allocateInfo, &descriptorSet));


	AttachmentsVk* atta = nullptr;
	if (atta == nullptr) {
		if (!$tank.takeout(atta, 0)) {
			log_bad(" not found  WindowVk.");
		};
	};


}
void SwapChainVk::destroyDescriptors() {

	{
		vkDestroyDescriptorPool($device, descriptorPool, nullptr); descriptorPool = VK_NULL_HANDLE;
	}

	{
		vkDestroyDescriptorSetLayout($device, descriptorSetLayout, nullptr); descriptorSetLayout = VK_NULL_HANDLE;
	}

	{
		vkDestroyPipelineLayout($device, pipelineLayout, nullptr); pipelineLayout = VK_NULL_HANDLE;
	}
}

void SwapChainVk::submit(VkCommandBuffer* cmds ) {

	static VkPipelineStageFlags graphicsWaitStageMasks[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
	VkSemaphore graphicsWaitSemaphores[] = { semaphores.presentComplete };

	VK_CHECK_RESULT(vkResetFences($device, 1, &waitFences[current.frame]));
	submitInfo.pWaitDstStageMask = graphicsWaitStageMasks;
	submitInfo.pWaitSemaphores = graphicsWaitSemaphores;
	submitInfo.waitSemaphoreCount = 1;/// static_cast<uint32_t>(wire.size());
	submitInfo.signalSemaphoreCount = 1;
	submitInfo.pSignalSemaphores = &semaphores.renderComplete;
	submitInfo.commandBufferCount = 1;
	submitInfo.pCommandBuffers = cmds;
	VK_CHECK_RESULT(vkQueueSubmit($queue, 1, &submitInfo, waitFences[current.frame]));
	VkResult result;

	
	result = queuePresent($queue, current.frame, semaphores.renderComplete);
	if (!((result == VK_SUCCESS) || (result == VK_SUBOPTIMAL_KHR))) {
		if (result == VK_ERROR_OUT_OF_DATE_KHR) {
			printf("Next Frame Error or Suboptimal  \n");
			return;
		}
		else {
			VK_CHECK_RESULT(result);
		}
	}
	
	do {
		result = vkWaitForFences($device, 1, &waitFences[current.frame], VK_TRUE, 0.1_fr);
	} while (result == VK_TIMEOUT);


	VK_CHECK_RESULT(vkQueueWaitIdle($queue));

}


#ifdef INCLUDE_MATERIAL_VKVIDEO
template void SwapChainVk::Command3(VideoVk& mat);
#endif

//#if defined(AEOLUS_DEBUG |  CMAKE_MODE_TEST)
#ifdef   CMAKE_MODE_TEST
template void SwapChainVk::Command3(Material2Vk& mat);
template void SwapChainVk::CommandLoop(Material2Vk& mat, uint32_t i);
template void SwapChainVk::CommandLoop(PostMaterialVk& mat, uint32_t i);
template void SwapChainVk::CommandInLine(PostMaterialVk& mat, VkCommandBuffer cmd, uint32_t i);
#endif
