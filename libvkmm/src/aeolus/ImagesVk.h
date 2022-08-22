#pragma once
#pragma once

#ifndef IMAGEVK_H
#define IMAGEVK_H

#include "incomplete.h"
#include "pch_mm.h"
#include "working_mm.h"

#ifdef  LOG_img
#define log_img(...) 
#else
#define log_img(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

#define SIZE_MIVSI   100
#define SIZE_MIV 100


MemExtern(MIVSIvk, SIZE_MIVSI);
MemExtern(MIVvk, SIZE_MIV);




struct special {

public:

	VkSpecializationInfo Info;
	std::vector<VkSpecializationMapEntry> entry;
	std::vector<char> data;
	uint32_t     memorySize;
	uint32_t        fieldNum;

	special();
	~special();

	void append(arth::SCALAR t, char* d);
	VkSpecializationInfo& get();


};


/*
template<class Pool>
struct ImmidiateCmd : public Pool {

	ImmidiateCmd(VkCommandPool pool) {
		VkCommandBufferAllocateInfo cmdBufAllocateInfo = vka::plysm::commandBufferAllocateInfo(pool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1);
		VK_CHECK_RESULT(vkAllocateCommandBuffers($device, &cmdBufAllocateInfo, &cmd));
		cmdPool = VK_NULL_HANDLE;
	};

	ImmidiateCmd() {
		alloc();
	};
	~ImmidiateCmd() {
		///if (cmd != VK_NULL_HANDLE) { log_bad("Memory Leak ImmidiateCommands ?   %p    \n", cmd); }
		free();
	}



	bool bridgeMap(MIVSIvk& _, void* src, VkImageLayout X) {

		allocStaging(_);

		char* dst;

		VK_CHECK_RESULT(vkMapMemory($device, staging.memory, 0, staging.allocInfo.allocationSize, 0, (void**)&dst));
		memcpy(dst, src, _.size);
		vkUnmapMemory($device, staging.memory);


		VkBufferImageCopy Region = {};
		Region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		Region.imageSubresource.mipLevel = 0;
		Region.imageSubresource.layerCount = 1;
		Region.imageExtent.width = _.w;
		Region.imageExtent.height = _.h;
		Region.imageExtent.depth = 1;

		std::vector<VkBufferImageCopy> bufferCopyRegions;
		for (int i = 0; i < _.l; i++) {
			Region.imageSubresource.baseArrayLayer  = i;
			if(i > 0)Region.imageExtent.width = 0;
			bufferCopyRegions.push_back(Region);
		}

		CopyArrayAfterX(staging.buffer, _, std::move(bufferCopyRegions), X);


		return true;

	};
	bool bridgeMap(MIVSIvk& _, void* src, int layer, VkImageLayout X) {

		allocStaging(_);

		char* dst;

		VK_CHECK_RESULT(vkMapMemory($device, staging.memory, 0, staging.allocInfo.allocationSize, 0, (void**)&dst));
		memcpy(dst, src, _.size);
		vkUnmapMemory($device, staging.memory);


		VkBufferImageCopy Region = {};
		Region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		Region.imageSubresource.mipLevel = 0;
		Region.imageSubresource.layerCount = 1;
		Region.imageSubresource.baseArrayLayer = layer;
		Region.imageExtent.width = _.w;
		Region.imageExtent.height = _.h;
		Region.imageExtent.depth = 1;
		CopyAfterX(staging.buffer, _,{ Region}, X);

		return true;

	};
	bool bridgeMapArray(MIVSIvk& _, ktxTexture* ktxTexture, VkImageLayout X) {

		allocStaging(_);

		uint8_t* data;
		ktx_uint8_t* ktxTextureData = ktxTexture_GetData(ktxTexture);
		VK_CHECK_RESULT(vkMapMemory($device, staging.memory, 0, staging.memReqs.size, 0, (void**)&data));
		memcpy(data, ktxTextureData, _.size);
		vkUnmapMemory($device, staging.memory);


		std::vector<VkBufferImageCopy> bufferCopyRegions;
		for (uint32_t layer = 0; layer < _.l; layer++)
		{
			ktx_size_t offset;
			KTX_error_code ret = ktxTexture_GetImageOffset(ktxTexture, 0, layer, 0, &offset);
			assert(ret == KTX_SUCCESS);

			VkBufferImageCopy bufferCopyRegion = {};
			bufferCopyRegion.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			bufferCopyRegion.imageSubresource.mipLevel = 0;
			bufferCopyRegion.imageSubresource.baseArrayLayer = layer;
			bufferCopyRegion.imageSubresource.layerCount = 1;
			bufferCopyRegion.imageExtent.width = ktxTexture->baseWidth;
			bufferCopyRegion.imageExtent.height = ktxTexture->baseHeight;
			bufferCopyRegion.imageExtent.depth = 1;
			bufferCopyRegion.bufferOffset = offset;
			bufferCopyRegions.push_back(bufferCopyRegion);

		}
		_.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;

		CopyArrayAfterX(staging.buffer, _, std::move(bufferCopyRegions), X);

		return true;
	}
	bool bridgeMap(MIVSIvk& _, void* src, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X) {

		allocStaging(_);

		char* dst;

		VK_CHECK_RESULT(vkMapMemory($device, staging.memory, 0, staging.allocInfo.allocationSize, 0, (void**)&dst));
		memcpy(dst, src, _.size);
		vkUnmapMemory($device, staging.memory);

		CopyAfterX(staging.buffer, _, bufferCopyRegions, X);

		return true;

	};
	void free() {
		Pool::free();
	}

	void CopyAfterShaderRead(VkBuffer src, VkImage dst, VkBufferImageCopy bufferCopyRegion) {

		begin();

		vka::shelve::setImageLayout(
			cmd,
			dst,
			VK_IMAGE_ASPECT_COLOR_BIT,
			VK_IMAGE_LAYOUT_UNDEFINED,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);

		vkCmdCopyBufferToImage(
			cmd,
			src,
			dst,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			1,
			&bufferCopyRegion
		);

		vka::shelve::setImageLayout(
			cmd,
			dst,
			VK_IMAGE_ASPECT_COLOR_BIT,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);


		end();

	};
	void CopyArrayAfterShaderRead(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy> bufferCopyRegion) {




		begin();

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = uint32_t(bufferCopyRegion.size());

		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			dst.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			subresourceRange);

		vkCmdCopyBufferToImage(
			cmd,
			src,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			bufferCopyRegion.size(),
			bufferCopyRegion.data()
		);


		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			subresourceRange);

		end();
		dst.Info.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
	};
	void CopyArrayAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy> _bufferCopyRegion, VkImageLayout X) {


		std::vector<VkBufferImageCopy> bufferCopyRegion;
		int base = 0;
		for (auto& region : _bufferCopyRegion) {
			if (base > region.imageSubresource.baseArrayLayer) base = region.imageSubresource.baseArrayLayer;
			if (region.imageExtent.width != 0)bufferCopyRegion.push_back(region);
		};

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = uint32_t(_bufferCopyRegion.size());
		subresourceRange.baseArrayLayer = base;

		begin();

		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			dst.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			subresourceRange);

		vkCmdCopyBufferToImage(
			cmd,
			src,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			bufferCopyRegion.size(),
			bufferCopyRegion.data()
		);


		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			X,
			subresourceRange);

		end();
		submit();
		wait();


		log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout,X);


		dst.Info.imageLayout = X;

	};
	void CopyAfterX(VkBuffer src, MIVSIvk& dst, VkBufferImageCopy&  _bufferCopyRegion, VkImageLayout X) {


		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = 1;
		subresourceRange.baseArrayLayer = _bufferCopyRegion.imageSubresource.baseArrayLayer;

		begin();

		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			dst.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			subresourceRange);

		vkCmdCopyBufferToImage(
			cmd,
			src,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			1,
			&_bufferCopyRegion
		);


		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			X,
			subresourceRange);

		end();
		submit();
		wait();


		log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


		dst.Info.imageLayout = X;

	};
	void CopyAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X) {


		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = dst.mipLevel;
		subresourceRange.layerCount = dst.l;

		begin();

		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			dst.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			subresourceRange);

		vkCmdCopyBufferToImage(
			cmd,
			src,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			static_cast<uint32_t>(bufferCopyRegions.size()),
			bufferCopyRegions.data()
		);


		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			X,
			subresourceRange);

		end();
		submit();
		wait();


		log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


		dst.Info.imageLayout = X;

	};

	void  MakeCopyAfterX(VkBuffer src, MIVSIvk& dst, VkBufferImageCopy& _bufferCopyRegion, VkImageLayout X) {


		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = 1;
		subresourceRange.baseArrayLayer = _bufferCopyRegion.imageSubresource.baseArrayLayer;

		Pool::begin();

		vka::shelve::setImageLayout(
			Pool::cmd,
			dst.image,
			dst.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			subresourceRange);

		vkCmdCopyBufferToImage(
			Pool::cmd,
			src,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			1,
			&_bufferCopyRegion
		);


		vka::shelve::setImageLayout(
			Pool::cmd,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			X,
			subresourceRange);

		Pool::end();


		log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


		dst.Info.imageLayout = X;

	};
	void MakeCopyAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X) {


			VkImageSubresourceRange subresourceRange = {};
			subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			subresourceRange.baseMipLevel = 0;
			subresourceRange.levelCount = dst.mipLevel;
			subresourceRange.layerCount = dst.l;

			Pool::begin();

			vka::shelve::setImageLayout(
				Pool::cmd,
				dst.image,
				dst.Info.imageLayout,
				VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
				subresourceRange);

			vkCmdCopyBufferToImage(
				Pool::cmd,
				src,
				dst.image,
				VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
				static_cast<uint32_t>(bufferCopyRegions.size()),
				bufferCopyRegions.data()
			);


			vka::shelve::setImageLayout(
				Pool::cmd,
				dst.image,
				VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
				X,
				subresourceRange);

			Pool::end();



			log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


			dst.Info.imageLayout = X;

		
	};
	void  TransX(MIVSIvk& dst, VkImageLayout O, VkImageLayout X) {

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = dst.mipLevel;
		subresourceRange.layerCount = dst.l;

		begin();

		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			O,
			X,
			subresourceRange);

		end();
		submit();
		wait();


		log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


		dst.Info.imageLayout = X;

	};

	template<typename Src,typename Dst>
	void BlitImageAfterX(Dst& dst, Src& src, std::vector<VkImageBlit> BlitRegion, VkImageLayout X, VkFilter  filter = VK_FILTER_NEAREST) {

		begin();

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = dst.l;/// blit_region.dstSubresource.layerCount;

		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			dst.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			subresourceRange);

		subresourceRange.layerCount = src.l;

		vka::shelve::setImageLayout(
			cmd,
			src.image,
			src.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			subresourceRange);

		vkCmdBlitImage(cmd, src.image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			dst.image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			(uint32_t)BlitRegion.size(), BlitRegion.data(), filter);


		vka::shelve::setImageLayout(
			cmd,
			src.image,
			VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			X,
			subresourceRange);

		
		subresourceRange.layerCount = dst.l;

		vka::shelve::setImageLayout(
			cmd,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			X,
			subresourceRange);

		end();
		submit();
		wait();


		log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);

		src.Info.imageLayout = X;
		dst.Info.imageLayout = X;

	};
	void 	CopyImageAfterX(MIVSIvk& dst, MIVSIvk& src, VkImageLayout X, VkImageLayout Y)
	{

		VkImageCopy imageCopyRegion{};
		imageCopyRegion.srcSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		imageCopyRegion.srcSubresource.layerCount = dst.l;
		imageCopyRegion.dstSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		imageCopyRegion.dstSubresource.layerCount = dst.l;
		imageCopyRegion.extent.width = dst.w;
		imageCopyRegion.extent.height = dst.h;
		imageCopyRegion.extent.depth = 1;

		Pool::begin();

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = dst.l;/// blit_region.dstSubresource.layerCount;

		vka::shelve::setImageLayout(
			Pool::cmd,
			dst.image,
			dst.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			subresourceRange);

		vka::shelve::setImageLayout(
			Pool::cmd,
			src.image,
			src.Info.imageLayout,
			VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			subresourceRange);

		vkCmdCopyImage(
			Pool::cmd,
			src.image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			dst.image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			1,
			&imageCopyRegion);


		vka::shelve::setImageLayout(
			Pool::cmd,
			src.image,
			VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
			X,
			subresourceRange);

		vka::shelve::setImageLayout(
			Pool::cmd,
			dst.image,
			VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
			Y,
			subresourceRange);

		Pool::end();
		Pool::submit();
		Pool::wait();

		log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);

		src.Info.imageLayout = X;
		dst.Info.imageLayout = Y;

	}


};

*/




struct ImagesVk {

protected:

	VkCommandPool                  cmdPool;

public:

	ImagesVk(VkCommandPool cmdPool);
	ImagesVk();
	~ImagesVk();

	void dealloc();

	template<class T>
	bool getImage(T& iach,MIVSIvk& _) {
		if (Mem(MIVSIvk,SIZE_MIVSI).$get(_, &iach.hach)) {
			return true;
		};
		return false;
	};


	template<class T>
	MIVSIvk& createFromRaw(ImmidiateCmd<T>& cmder, std::string Name, void* src, uint32_t w, uint32_t h, VkImageLayout dstlayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL)
	{
		MIVSIvk  _;
		/*
		if (cache.count(Name) > 0)return cache[Name];

		MIVSIvk& _ = cache[Name];

		_.w = w;
		_.h = h;
		_.c = 4;
		_.l = 1;
		_.size = _.w * _.h * _.c * _.l;

		create2D(_, VK_FORMAT_R8G8B8A8_UNORM);
		//reate2D(_, VK_FORMAT_R8G8B8_SNORM);
		//create2D(_, VK_FORMAT_R8G8B8_UNORM);
		cmder.bridgeMap(_, src, dstlayout);
		*/

		return _;

	};


	bool create2D(MIVSIvk& _, VkFormat format, VkImageUsageFlags  flag = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_SAMPLED_BIT,
		VkMemoryPropertyFlags properties = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);

	bool createCubeMap(MIVSIvk& _, VkFormat format);

	bool create2DArray(MIVSIvk& _, VkFormat format);

	template<class Mem>
	bool create2DStorageArray(Mem& _, VkFormat format) {
	   

		VkImageCreateInfo imageCreateInfo = vka::plysm::imageCreateInfo();
		imageCreateInfo.imageType = VK_IMAGE_TYPE_2D;
		imageCreateInfo.format = format;
		imageCreateInfo.mipLevels = 1;
		imageCreateInfo.samples = VK_SAMPLE_COUNT_1_BIT;
		imageCreateInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
		imageCreateInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
		imageCreateInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
		imageCreateInfo.extent = { _.w,_.h, 1 };
		imageCreateInfo.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_STORAGE_BIT;
		imageCreateInfo.arrayLayers = _.l;

		VK_CHECK_RESULT(vkCreateImage($device, &imageCreateInfo, nullptr, &_.image));

		vkGetImageMemoryRequirements($device, _.image, &_.memReqs);

		VkMemoryAllocateInfo allocInfo = vka::plysm::memoryAllocateInfo();
		allocInfo.allocationSize = _.memReqs.size;
		allocInfo.memoryTypeIndex = vka::shelve::getMemoryType(_.memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, nullptr);
		log_img("Bridge Test ==>>   NUMS == 0  generate memory    Size %zu   TypeBits  %u     TypeIndex  %u \n", _.memReqs.size, (uint32_t)_.memReqs.memoryTypeBits, allocInfo.memoryTypeIndex);

		VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, nullptr, &_.memory));
		VK_CHECK_RESULT(vkBindImageMemory($device, _.image, _.memory, 0));




		VkSamplerCreateInfo sampler = vka::plysm::samplerCreateInfo();
		sampler.magFilter = VK_FILTER_LINEAR;
		sampler.minFilter = VK_FILTER_LINEAR;
		sampler.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
		sampler.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
		sampler.addressModeV = sampler.addressModeU;
		sampler.addressModeW = sampler.addressModeU;
		sampler.mipLodBias = 0.0f;
		sampler.maxAnisotropy = 8;
		sampler.compareOp = VK_COMPARE_OP_NEVER;
		sampler.minLod = 0.0f;
		sampler.maxLod = 0.0f;
		sampler.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
		VK_CHECK_RESULT(vkCreateSampler($device, &sampler, nullptr, &_.sampler));


		VkImageViewCreateInfo view = vka::plysm::imageViewCreateInfo();
		view.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		view.format = format;
		view.components = { VK_COMPONENT_SWIZZLE_R, VK_COMPONENT_SWIZZLE_G, VK_COMPONENT_SWIZZLE_B, VK_COMPONENT_SWIZZLE_A };
		view.subresourceRange = { VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1 };
		view.subresourceRange.layerCount = _.l;
		view.subresourceRange.levelCount = 1;
		view.image = _.image;
		VK_CHECK_RESULT(vkCreateImageView($device, &view, nullptr, &_.view));

		return true;
	};

	template<class T>
	bool createCubeMapFromKtx(ImmidiateCmd<T>& cmder, Iache& iach)
	{
		MIVSIvk  miv;

		if (!(Mem(MIVSIvk, SIZE_MIVSI).$get(miv, &iach.hach))) {
			ktxResult result;
			ktxTexture* ktxTexture;

			iach.name  = IMAGE_PATH + iach.name;
			if (!vka::shelve::fileExists(iach.name)) {
				log_bad("Could not load texture from  %s \n\nThe file may be part of the additional asset pack.\n\nRun \"download_assets.py\" in the repository root to download the latest version.", iach.name.c_str());
			}

			result = ktxTexture_CreateFromNamedFile(iach.name.c_str(), KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT, &ktxTexture);

			assert(result == KTX_SUCCESS);

			// Get properties required for using and upload texture data from the ktx texture object
			miv.w = ktxTexture->baseWidth;
			miv.h = ktxTexture->baseHeight;
			//ktxTexture->numLevels = 1;
			miv.l = 6;
			miv.mipLevel = ktxTexture->numLevels;
			ktx_uint8_t* ktxTextureData = ktxTexture_GetData(ktxTexture);
			ktx_size_t ktxTextureSize = ktxTexture_GetSize(ktxTexture);

			miv.size = ktxTextureSize;
			createCubeMap(miv, iach.format);


			std::vector<VkBufferImageCopy> bufferCopyRegions;
	

			for (uint32_t face = 0; face < 6; face++)
			{
				for (uint32_t level = 0; level < miv.mipLevel; level++)
				{

					ktx_size_t offset;
					KTX_error_code ret = ktxTexture_GetImageOffset(ktxTexture, level, 0, face, &offset);
					assert(ret == KTX_SUCCESS);
					VkBufferImageCopy bufferCopyRegion = {};
					bufferCopyRegion.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
					bufferCopyRegion.imageSubresource.mipLevel = level;
					bufferCopyRegion.imageSubresource.baseArrayLayer = face;
					bufferCopyRegion.imageSubresource.layerCount = 1;
					bufferCopyRegion.imageExtent.width = ktxTexture->baseWidth >> level;
					bufferCopyRegion.imageExtent.height = ktxTexture->baseHeight >> level;
					bufferCopyRegion.imageExtent.depth = 1;
					bufferCopyRegion.bufferOffset = offset;
					bufferCopyRegions.push_back(bufferCopyRegion);
				}
			}

			miv.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
			cmder.bridgeMap(miv, ktxTextureData, bufferCopyRegions, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
			
			miv.Info.sampler     = miv.sampler;
			miv.Info.imageView = miv.view;

			Mem(MIVSIvk, SIZE_MIVSI).$set$(std::move(miv), &iach.hach);
			iach.refCnt++;

			ktxTexture_Destroy(ktxTexture);
		}
		return true;
	}

	template<class T>
	bool createFromKtx(ImmidiateCmd<T>& cmder, std::string key, Iache& iach)
	{


		MIVSIvk  miv;

		if (!(Mem(MIVSIvk,SIZE_MIVSI).$get(miv, &iach.hach))) {

			std::string  filename = IMAGE_PATH + key;

			ktxResult              result;
			ktxTexture* ktxTexture;

			if (!vka::shelve::fileExists(filename)) {
				log_bad("Could not load texture from  %s \n\nThe file may be part of the additional asset pack.\n\nRun \"download_assets.py\" in the repository root to download the latest version.", filename.c_str());
			}
			result = ktxTexture_CreateFromNamedFile(filename.c_str(), KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT, &ktxTexture);

			assert(result == KTX_SUCCESS);

			// Get properties required for using and upload texture data from the ktx texture object
			miv.w = ktxTexture->baseWidth;
			miv.h = ktxTexture->baseHeight;
			miv.l = ktxTexture->numLayers;
			miv.size = ktxTexture_GetSize(ktxTexture);
		//	ktx_uint8_t* ktxTextureData = ktxTexture_GetData(ktxTexture);
			///ktx_size_t ktxTextureSize = ktxTexture_GetSize(ktxTexture);
			if (miv.l == 1) {
				create2D(miv, iach.format);
			}
			else {
				create2DArray(miv, iach.format);
			}

			cmder.bridgeMapArray(miv, ktxTexture, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

			ktxTexture_Destroy(ktxTexture);



			miv.Info = {};
			miv.Info.sampler = miv.sampler;
			miv.Info.imageView = miv.view;
			miv.Info.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;

			///cache[filename] = _;
			Mem(MIVSIvk,SIZE_MIVSI).$set$(std::move(miv), &iach.hach);
			iach.refCnt++;

			log_img("ImagesVk Create KTX   TexArray   %x    %s    \n",miv.view,filename.c_str());

			return true;
		};

		return true;
	};

	template<class T >
	bool createFromFile(ImmidiateCmd<T>& cmder, std::string key, Iache& iach) {

		MIVSIvk   _;

		if (!(Mem(MIVSIvk,SIZE_MIVSI).$get(_, &iach.hach))) {

			std::string name = IMAGE_PATH + key;
			log_once("Image Loading...... %s    \n", (name).c_str());

			ktx::loadmap loader;

			if (ktx::Flags::Error == loader.load(name.c_str())) {
				log_bad("stb Load %s    \n", (name).c_str());
			};

			_.w = loader.images->w;
			_.h = loader.images->h;
			_.c = 4;
			_.l = 1;
			_.size = _.w * _.h * _.c * _.l;

			create2D(_, iach.format);
			///create2D(_, VK_FORMAT_R32G32B32A32_SFLOAT);
			///cmder.bridgeMap(_, (char*)loader.images->packed, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
			cmder.bridgeMap(_, (char*)loader.images->packed, iach.layout);/// VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

			Mem(MIVSIvk,SIZE_MIVSI).$set$(std::move(_), &iach.hach);
			iach.refCnt++;
			return true;
		}

		return true;

	};

	template<class T >
	bool createFromFiles(ImmidiateCmd<T>& cmder, std::vector<std::string> keys, Iache& iach) {

		MIVSIvk   _;

		if (!(Mem(MIVSIvk, SIZE_MIVSI).$get(_, &iach.hach))) {

			int l = 0;;

			_.l  =  keys.size();
			for (std::string key : keys) {

				std::string name = IMAGE_PATH + key;
				log_once("Image Loading...... %s    \n", (name).c_str());

				ktx::loadmap loader;

				if (ktx::Flags::Error == loader.load(name.c_str())) {
					log_bad("stb Load %s    \n", (name).c_str());
				};
				if (l ==0) {
					_.w = loader.images->w;
					_.h = loader.images->h;
					_.c = 4;
					_.size = _.w * _.h * _.c;
					create2DArray(_, iach.format);
				}

				_.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
				cmder.bridgeMap(_, (char*)loader.images->packed,l, iach.layout);/// VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
				l++;
			}

			_.size *= _.l ;
			Mem(MIVSIvk, SIZE_MIVSI).$set$(std::move(_), &iach.hach);
			iach.refCnt++;
			return true;
		}

		return true;

	};

	template<class T >
	bool createFromFileStorage(ImmidiateCmd<T>& cmder, std::string key, Iache& iach) {

		MIVSIvk   _;

		if (!(Mem(MIVSIvk,SIZE_MIVSI).$get(_, &iach.hach))) {

			std::string name = IMAGE_PATH + key;
			log_once("Image Loading...... %s    \n", (name).c_str());

			ktx::loadmap loader;

			if (ktx::Flags::Error == loader.load(name.c_str())) {
				log_bad("stb Load %s    \n", (name).c_str());
			};

			_.w = loader.images->w;
			_.h = loader.images->h;
			_.c = 4;
			_.l =  2;
			_.size = _.w * _.h * _.c * _.l;

			create2DStorageArray(_, iach.format);

			if (iach.format == VK_FORMAT_R32G32B32A32_SFLOAT) {
				_.size = _.w * _.h * _.c * 4;
			}
			else {
				_.size = _.w * _.h * _.c;
			};
			

			cmder.bridgeMap(_, (char*)loader.images->packed, iach.layout);/// VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
			
			Mem(MIVSIvk,SIZE_MIVSI).$set$(std::move(_), &iach.hach);
			iach.refCnt++;
			return true;
		}

		return true;

	};

	VkPipelineShaderStageCreateInfo  loadShader(std::string fileName, VkShaderStageFlagBits stage, PvSvk& p);

	template<class T>
	bool  Canvas2D(MIVvk& Color,MIVvk& Depth,T* cvs) {

		const uint32_t multiviewLayerCount = 1;

		{
			bool gen = true;
			
			if (Mem(MIVvk,SIZE_MIV).$get(Color, &cvs->iachCol.hach)) {
				if (cvs->w != Color.w || cvs->h != Color.h) {
					Mem(MIVvk,SIZE_MIV).$delete$(&cvs->iachCol.hach);
				}
				else  gen = false;
			};
			
			if (gen) {

				if (cvs->w == 0 || cvs->h == 0) {
					log_bad("Create Canvas2D::Size InValid.  %u  %u \n", cvs->w, cvs->h);
					return false;
				};


				Color.w = cvs->w;
				Color.h = cvs->h;
				Color.l = 1;
				VkImageCreateInfo imageCI = vka::plysm::imageCreateInfo();
				imageCI.imageType = VK_IMAGE_TYPE_2D;
				imageCI.format = $format.COLORFORMAT;
				imageCI.extent = { Color.w,Color.h, 1 };
				imageCI.mipLevels = 1;
				imageCI.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
				imageCI.arrayLayers = multiviewLayerCount;
				imageCI.samples = VK_SAMPLE_COUNT_1_BIT; // (VkSampleCountFlagBits)MSAASampleCount; ///VK_SAMPLE_COUNT_1_BIT;
				imageCI.tiling = VK_IMAGE_TILING_OPTIMAL;
				imageCI.usage = VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT;
				imageCI.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;  //
				VK_CHECK_RESULT(vkCreateImage($device, &imageCI, nullptr, &Color.image));
				Color.Info.imageLayout = imageCI.initialLayout;



				VkMemoryRequirements memReqs;

				vkGetImageMemoryRequirements($device, Color.image, &memReqs);
				Color.size = memReqs.size;

				VkMemoryAllocateInfo memoryAllocInfo = vka::plysm::memoryAllocateInfo();
				memoryAllocInfo.allocationSize = memReqs.size;
				memoryAllocInfo.memoryTypeIndex = vka::shelve::getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
				VK_CHECK_RESULT(vkAllocateMemory($device, &memoryAllocInfo, nullptr, &Color.memory));
				VK_CHECK_RESULT(vkBindImageMemory($device, Color.image, Color.memory, 0));



				VkImageViewCreateInfo imageViewCI = vka::plysm::imageViewCreateInfo();
				imageViewCI.viewType = VK_IMAGE_VIEW_TYPE_2D;///               VK_IMAGE_VIEW_TYPE_2D_ARRAY;
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
				imageViewCI.image = Color.image;
				VK_CHECK_RESULT(vkCreateImageView($device, &imageViewCI, nullptr, &Color.view));


				
				Mem(MIVvk,SIZE_MIV).$set$(std::move(Color), &cvs->iachCol.hach);

				log_img("Create Canvas2D:: %u  %u     %x    %x \n", cvs->w, cvs->h, Color.image, cvs->iachCol.hach.hash);

				cvs->iachCol.refCnt++; 
				cvs->iachCol.vkI = Color.view;

			}
			
			
			log_img("get Canvas2D:: %u  %u     %x    %x \n", cvs->w, cvs->h, Color.image, cvs->iachCol.hach.hash);
		}

		{
			bool gen = true;
			if (Mem(MIVvk,SIZE_MIV).$get(Depth, &cvs->iachDep.hach)) {
				if (cvs->w != Depth.w || cvs->h != Depth.h) {
					Mem(MIVvk,SIZE_MIV).$delete$(&cvs->iachDep.hach);
				}
				else {
					gen = false;
				}
			}
			
			if (gen) {

				if (cvs->w == 0 || cvs->h == 0) {
					log_bad("Create Canvas2D::Size InValid.  %u  %u \n", cvs->w, cvs->h);
					return  false;
				};


				Depth.w = cvs->w;
				Depth.h = cvs->h;
				Depth.l  = 1;
				VkImageCreateInfo imageCI = vka::plysm::imageCreateInfo();
				imageCI.imageType = VK_IMAGE_TYPE_2D;
				imageCI.format = $format.DEPTHFORMAT;
				imageCI.extent = { Depth.w, Depth.h, 1 };
				imageCI.mipLevels = 1;
				imageCI.arrayLayers = multiviewLayerCount;
				imageCI.samples = VK_SAMPLE_COUNT_1_BIT;
				imageCI.tiling = VK_IMAGE_TILING_OPTIMAL;
				imageCI.usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
				imageCI.flags = 0;
				VK_CHECK_RESULT(vkCreateImage($device, &imageCI, nullptr, &Depth.image));

				VkMemoryRequirements memReqs;
				vkGetImageMemoryRequirements($device, Depth.image, &memReqs);
				Depth.size = memReqs.size;

				VkMemoryAllocateInfo memAllocInfo{};
				memAllocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
				memAllocInfo.allocationSize = 0;
				memAllocInfo.memoryTypeIndex = 0;

				VkImageViewCreateInfo depthStencilView = {};
				depthStencilView.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
				depthStencilView.pNext = NULL;
				depthStencilView.viewType = VK_IMAGE_VIEW_TYPE_2D;
				depthStencilView.format = $format.DEPTHFORMAT;
				depthStencilView.flags = 0;
				depthStencilView.subresourceRange = {};
				depthStencilView.subresourceRange.aspectMask = VK_IMAGE_ASPECT_DEPTH_BIT | VK_IMAGE_ASPECT_STENCIL_BIT;
				depthStencilView.subresourceRange.baseMipLevel = 0;
				depthStencilView.subresourceRange.levelCount = 1;
				depthStencilView.subresourceRange.baseArrayLayer = 0;
				depthStencilView.subresourceRange.layerCount = multiviewLayerCount;
				depthStencilView.image = Depth.image;

				memAllocInfo.allocationSize = memReqs.size;
				memAllocInfo.memoryTypeIndex = vka::shelve::getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
				VK_CHECK_RESULT(vkAllocateMemory($device, &memAllocInfo, nullptr, &Depth.memory));
				VK_CHECK_RESULT(vkBindImageMemory($device, Depth.image, Depth.memory, 0));
				VK_CHECK_RESULT(vkCreateImageView($device, &depthStencilView, nullptr, &Depth.view));


				Mem(MIVvk,SIZE_MIV).$set$(std::move(Depth), &cvs->iachDep.hach);
				
				cvs->iachDep.refCnt++;
				cvs->iachDep.vkI = Depth.view;

			}
			
			
		}

		return true;

	};


	template<class T>
	bool $Delete( T* hach) {
		MIVvk  _;
		if (Mem(MIVvk,SIZE_MIV).$get(_, hach)) {
			Mem(MIVvk,SIZE_MIV).$delete$(hach);
			return true;
		}
		return true;
	};

	template<class T>
	bool $DeleteMIVSI(T* hach) {
		MIVSIvk  _;
		if (Mem(MIVSIvk, SIZE_MIVSI).$get(_, hach)) {
			Mem(MIVSIvk, SIZE_MIVSI).$delete$(hach);
			return true;
		}
		return true;
	};

};



#endif