#pragma once
#include "pch_mm.h"
#include "working_mm.h"


AttachmentsVk::AttachmentsVk(uint32_t w, uint32_t h, uint32_t multisample) :w(w), h(h), multisample(multisample) {
	color = {};
	for (int i = 0; i < 5; i++)member[i] = {};
};

bool AttachmentsVk::destroy() {
	for (int i = 0; i < 5; i++)member[i].dealloc();
	color.dealloc();
	return true;
};
void AttachmentsVk::createMultiViewColorDepthWithResolution() {

	const uint32_t multiviewLayerCount = 2;

	log_ata("create MVColDepWithReso   [%u  %u] multisample %u \n", w, h,multisample);
	{
		VkImageCreateInfo imageCI = vka::plysm::imageCreateInfo();
		imageCI.imageType = VK_IMAGE_TYPE_2D;
		imageCI.format = $format.COLORFORMAT;
		imageCI.extent = { w, h, 1 };
		imageCI.mipLevels = 1;
		imageCI.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
		imageCI.arrayLayers = multiviewLayerCount;
		imageCI.samples = (VkSampleCountFlagBits)multisample; ///VK_SAMPLE_COUNT_1_BIT;
		imageCI.tiling = VK_IMAGE_TILING_OPTIMAL;
		imageCI.usage = VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		VK_CHECK_RESULT(vkCreateImage($device, &imageCI, nullptr, &colorMS.image));

		VkMemoryRequirements memReqs;
		vkGetImageMemoryRequirements($device, colorMS.image, &memReqs);

		VkMemoryAllocateInfo memoryAllocInfo = vka::plysm::memoryAllocateInfo();
		memoryAllocInfo.allocationSize = memReqs.size;
		memoryAllocInfo.memoryTypeIndex = vka::shelve::getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,nullptr);
		VK_CHECK_RESULT(vkAllocateMemory($device, &memoryAllocInfo, nullptr, &colorMS.memory));
		VK_CHECK_RESULT(vkBindImageMemory($device, colorMS.image, colorMS.memory, 0));

		VkImageViewCreateInfo imageViewCI = vka::plysm::imageViewCreateInfo();
		imageViewCI.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		imageViewCI.format = $format.COLORFORMAT;
		imageViewCI.flags = 0;
		imageViewCI.components.r = VK_COMPONENT_SWIZZLE_R;
		imageViewCI.components.g = VK_COMPONENT_SWIZZLE_G;
		imageViewCI.components.b = VK_COMPONENT_SWIZZLE_B;
		imageViewCI.components.a = VK_COMPONENT_SWIZZLE_A;
		imageViewCI.subresourceRange = {};
		imageViewCI.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		imageViewCI.subresourceRange.baseMipLevel = 0;
		imageViewCI.subresourceRange.levelCount = 1;
		imageViewCI.subresourceRange.baseArrayLayer = 0;
		imageViewCI.subresourceRange.layerCount = multiviewLayerCount;
		imageViewCI.image = colorMS.image;
		VK_CHECK_RESULT(vkCreateImageView($device, &imageViewCI, nullptr, &colorMS.view));

	}


	{
		VkImageCreateInfo imageCI = vka::plysm::imageCreateInfo();
		imageCI.imageType = VK_IMAGE_TYPE_2D;
		imageCI.format = $format.COLORFORMAT;
		imageCI.extent = { w, h, 1 };
		imageCI.mipLevels = 1;
		imageCI.arrayLayers = multiviewLayerCount;
		imageCI.samples = VK_SAMPLE_COUNT_1_BIT;
		imageCI.tiling = VK_IMAGE_TILING_OPTIMAL;
		imageCI.usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
		VK_CHECK_RESULT(vkCreateImage($device, &imageCI, nullptr, &color.image));

		VkMemoryRequirements memReqs;
		vkGetImageMemoryRequirements($device, color.image, &memReqs);

		VkMemoryAllocateInfo memoryAllocInfo = vka::plysm::memoryAllocateInfo();
		memoryAllocInfo.allocationSize = memReqs.size;
		memoryAllocInfo.memoryTypeIndex = vka::shelve::getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT,nullptr);
		VK_CHECK_RESULT(vkAllocateMemory($device, &memoryAllocInfo, nullptr, &color.memory));
		VK_CHECK_RESULT(vkBindImageMemory($device, color.image, color.memory, 0));

		VkImageViewCreateInfo imageViewCI = vka::plysm::imageViewCreateInfo();
		imageViewCI.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		imageViewCI.format = $format.COLORFORMAT;
		imageViewCI.flags = 0;
		imageViewCI.subresourceRange = {};
		imageViewCI.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		imageViewCI.subresourceRange.baseMipLevel = 0;
		imageViewCI.subresourceRange.levelCount = 1;
		imageViewCI.subresourceRange.baseArrayLayer = 0;
		imageViewCI.subresourceRange.layerCount = multiviewLayerCount;
		imageViewCI.image = color.image;
		VK_CHECK_RESULT(vkCreateImageView($device, &imageViewCI, nullptr, &color.view));

		// Create sampler to sample from the attachment in the fragment shader
		VkSamplerCreateInfo samplerCI = vka::plysm::samplerCreateInfo();
		samplerCI.magFilter = VK_FILTER_NEAREST;
		samplerCI.minFilter = VK_FILTER_NEAREST;
		samplerCI.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
		samplerCI.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		samplerCI.addressModeV = samplerCI.addressModeU;
		samplerCI.addressModeW = samplerCI.addressModeU;
		samplerCI.mipLodBias = 0.0f;
		samplerCI.maxAnisotropy = 1.0f;
		samplerCI.minLod = 0.0f;
		samplerCI.maxLod = 1.0f;
		samplerCI.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
		VK_CHECK_RESULT(vkCreateSampler($device, &samplerCI, nullptr, &color.sampler));

		
		color.Info.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		color.Info.imageView = color.view;
		color.Info.sampler = color.sampler;

	}


	{
		VkImageCreateInfo imageCI = vka::plysm::imageCreateInfo();
		imageCI.imageType = VK_IMAGE_TYPE_2D;
		imageCI.format = $format.DEPTHFORMAT;
		imageCI.extent = { w, h, 1 };
		imageCI.mipLevels = 1;
		imageCI.arrayLayers = multiviewLayerCount;
		imageCI.samples = (VkSampleCountFlagBits)multisample;
		imageCI.tiling = VK_IMAGE_TILING_OPTIMAL;
		imageCI.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
		imageCI.usage = VK_IMAGE_USAGE_TRANSIENT_ATTACHMENT_BIT | VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
		imageCI.flags = 0;
		VK_CHECK_RESULT(vkCreateImage($device, &imageCI, nullptr, &depthMS.image));

		VkMemoryRequirements memReqs;
		vkGetImageMemoryRequirements($device, depthMS.image, &memReqs);

		VkMemoryAllocateInfo memAllocInfo{};
		memAllocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		memAllocInfo.allocationSize = 0;
		memAllocInfo.memoryTypeIndex = 0;

		VkImageViewCreateInfo depthStencilView = {};
		depthStencilView.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		depthStencilView.pNext = NULL;
		depthStencilView.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		depthStencilView.format = $format.DEPTHFORMAT;
		depthStencilView.flags = 0;
		depthStencilView.subresourceRange = {};
		depthStencilView.subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
		depthStencilView.subresourceRange.baseMipLevel = 0;
		depthStencilView.subresourceRange.levelCount = 1;
		depthStencilView.subresourceRange.baseArrayLayer = 0;
		depthStencilView.subresourceRange.layerCount = multiviewLayerCount;
		depthStencilView.image = depthMS.image;

		memAllocInfo.allocationSize = memReqs.size;
		memAllocInfo.memoryTypeIndex = vka::shelve::getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, nullptr);
		VK_CHECK_RESULT(vkAllocateMemory($device, &memAllocInfo, nullptr, &depthMS.memory));
		VK_CHECK_RESULT(vkBindImageMemory($device, depthMS.image, depthMS.memory, 0));
		VK_CHECK_RESULT(vkCreateImageView($device, &depthStencilView, nullptr, &depthMS.view));

	}


	{
		VkImageCreateInfo imageCI = vka::plysm::imageCreateInfo();
		imageCI.imageType = VK_IMAGE_TYPE_2D;
		imageCI.format = $format.DEPTHFORMAT;
		imageCI.extent = { w, h, 1 };
		imageCI.mipLevels = 1;
		imageCI.arrayLayers = multiviewLayerCount;
		imageCI.samples = VK_SAMPLE_COUNT_1_BIT;
		imageCI.tiling = VK_IMAGE_TILING_OPTIMAL;
		imageCI.usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
		imageCI.flags = 0;
		VK_CHECK_RESULT(vkCreateImage($device, &imageCI, nullptr, &depth.image));

		VkMemoryRequirements memReqs;
		vkGetImageMemoryRequirements($device, depth.image, &memReqs);

		VkMemoryAllocateInfo memAllocInfo{};
		memAllocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
		memAllocInfo.allocationSize = 0;
		memAllocInfo.memoryTypeIndex = 0;

		VkImageViewCreateInfo depthStencilView = {};
		depthStencilView.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
		depthStencilView.pNext = NULL;
		depthStencilView.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		depthStencilView.format = $format.DEPTHFORMAT;
		depthStencilView.flags = 0;
		depthStencilView.subresourceRange = {};
		depthStencilView.subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
		depthStencilView.subresourceRange.baseMipLevel = 0;
		depthStencilView.subresourceRange.levelCount = 1;
		depthStencilView.subresourceRange.baseArrayLayer = 0;
		depthStencilView.subresourceRange.layerCount = multiviewLayerCount;
		depthStencilView.image = depth.image;

		memAllocInfo.allocationSize = memReqs.size;
		memAllocInfo.memoryTypeIndex = vka::shelve::getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, nullptr);
		VK_CHECK_RESULT(vkAllocateMemory($device, &memAllocInfo, nullptr, &depth.memory));
		VK_CHECK_RESULT(vkBindImageMemory($device, depth.image, depth.memory, 0));
		VK_CHECK_RESULT(vkCreateImageView($device, &depthStencilView, nullptr, &depth.view));
	}


};