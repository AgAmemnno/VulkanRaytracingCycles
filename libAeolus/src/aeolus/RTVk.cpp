#include  "pch.h"
#include "types.hpp"
#include "working.h"
///#include "aeolus/ObjectVk.h"

#include "aeolus/ObjectVk.h"
#include "aeolus/materialsVk/common.h"
#include "aeolus/GroupVk/common.h"
#include "ext/extensions_vk.hpp"
using namespace aeo;


MemExtern(MBvk, SIZE_MB);
MemExtern(MIBvk, SIZE_MIB);
MemExtern(MIBmvk, SIZE_MIBm);


MemExtern(Mvk, SIZE_MDev);
MemExtern(IBmvk, SIZE_IBmDev);
MemExtern(Mvk, SIZE_MVis);
MemExtern(IBmvk, SIZE_IBmVis);


namespace brunch {


template<class T>
	RTVk<T>::RTVk() :BrunchVk(0) {
		rtcm = new 	ImmidiateRTCmd<ImmidiateCmdPool3>;
		rtcm->allocCmd(3+3);
		
		frameBuffer = VK_NULL_HANDLE;
		cmd[0] = cmd[1] = VK_NULL_HANDLE;
		data = {
			.slice = {0,0},
			.receiver = nullptr,
		};

		
		sigcmd.tID = _threadid;

	};

template<class T>
	RTVk<T>::RTVk(long id) :BrunchVk(id) {
		rtcm = new 	ImmidiateRTCmd<ImmidiateCmdPool3>;
		rtcm->allocCmd(3);
		frameBuffer = VK_NULL_HANDLE;
		cmd[0] = cmd[1] = VK_NULL_HANDLE;
		data = {
			.slice = {0,0},
			.receiver = nullptr,
		};


		sigcmd.tID                      = _threadid;
		sigcmd.Return.BlueLight = CreateSemaphore(NULL, 0, 1, (__T("RTVk----Commander-Ret") + std::to_tstring(sigcmd.tID)).c_str());
		sigcmd.Join.BlueLight     = CreateSemaphore(NULL, 0, 1, (__T("RTVk----Commander-Join") + std::to_tstring(sigcmd.tID)).c_str());

	};

template<class T>
void RTVk<T>::dealloc() {
		destroyImages();
	};
template<class T>
	RTVk<T>::~RTVk() {

		if (rtcm != nullptr) delete rtcm;
		 dealloc();
		if (sigcmd.Join.BlueLight != NULL) { CloseHandle(sigcmd.Join.BlueLight); sigcmd.Join.BlueLight = NULL; };
		if (sigcmd.Return.BlueLight != NULL) { CloseHandle(sigcmd.Return.BlueLight); sigcmd.Return.BlueLight = NULL; };



		master.cmdVk.free();

	};


	template<class T>
	void RTVk<T>::setRenderGroup(arth::eSUBMIT_MODE mode,  SwapChainVkTy* _swapchain, std::vector<RTMaterial*>&& mat, std::vector<PostMaterialVk*>&& pmat) {

		submitMode = mode;
		swapchain = _swapchain; 
		for (auto& v : mat)rtmat.push_back(v);
		for (auto& v : pmat)postmat.push_back(v);

		if EQ_ARTH(submitMode, arth::eSUBMIT_MODE::OneTime) {
			rtcm->setInfo(VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT);
			if  EQ_ARTH(submitMode, arth::eSUBMIT_MODE::Separate) {
				submitSwapChain = [&]() {
					_submitSwapChainSeparate();
					vkResetCommandBuffer(rtcm->cmd, VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT);
				};
			}
			else if  EQ_ARTH(submitMode, arth::eSUBMIT_MODE::Inline) {
				submitSwapChain = [&]() {
					_submitSwapChainInline();
					vkResetCommandBuffer(rtcm->cmd, VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT);
				};
			}
		}
		else {
			rtcm->setInfo(VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT);
			if  EQ_ARTH(submitMode, arth::eSUBMIT_MODE::Separate) 
					submitSwapChain = std::bind(&RTVk::_submitSwapChainSeparate, this);
			else if  EQ_ARTH(submitMode, arth::eSUBMIT_MODE::Inline)
				submitSwapChain = std::bind(&RTVk::_submitSwapChainInline, this);
		};

	

	};



	template<class T>
	void RTVk<T>::_submitSwapChainSeparate() {


		VkResult result;
		auto mat = rtmat[0];


		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = 1;

		uint32_t frame = swapchain->current.frame;
		rtcm->cmdSet(frame);
		mat->pipeline_flags = 0;
		VkCommandBuffer cmd = rtcm->begin(frame);
		for (auto img : mrt) {
			vka::shelve::setImageLayout(
				cmd,
				img.image,
				VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_GENERAL,
				subresourceRange);
		}
		mat->makeCB(cmd);
		//rtcm->imageBarrier(mrt);
		VK_CHECK_RESULT(vkEndCommandBuffer(cmd));




		static std::chrono::time_point<std::chrono::steady_clock>  now, start;
		start = std::chrono::high_resolution_clock::now();

		submitFrameRT();
		do {
			result = vkWaitForFences($device, 1, &rtcm->fence, VK_TRUE, 0.1_fr);
		} while (result == VK_TIMEOUT);
		now = std::chrono::high_resolution_clock::now();
		printf("Submit RT   execution Critical    time    %.5f    milli second      result   %u   Sleeping  3 second.... \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()), (UINT)result);

		//Sleep(10);
		
		swapchain->CommandLoop( *postmat[0], swapchain->current.frame);
		swapchain->submit(&swapchain->drawCmdBuffers[swapchain->current.frame]);



	};
	template<class T>
	void RTVk<T>::_submitSwapChainInline() {




		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = 1;
		rtcm->cmdSet(swapchain->current.frame);

		VkCommandBuffer cmd = rtcm->begin(swapchain->current.frame);

		vka::shelve::setImageLayout(
			cmd,
			images[0].image,
			VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_GENERAL,
			subresourceRange);

		vka::shelve::setImageLayout(
			cmd,
			images[1].image,
			VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL, VK_IMAGE_LAYOUT_GENERAL,
			subresourceRange);

		for (auto mat : rtmat)mat->makeRT(cmd);

		rtcm->imageBarrier(images);

		swapchain->CommandInLine(*postmat[0], cmd, swapchain->current.frame);
		
		VK_CHECK_RESULT(vkEndCommandBuffer(cmd));

		swapchain->submit(&cmd);

	};
	template<class T>
	void RTVk<T>::submitFrameRT()
	{
		
		VkSubmitInfo submitInfo{};
		submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
		VkCommandBuffer cmd = rtcm->cmd;

		submitInfo.waitSemaphoreCount = 0;/// static_cast<uint32_t>(wire.size());
		submitInfo.signalSemaphoreCount = 0;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &cmd;
	

		VK_CHECK_RESULT(vkResetFences($device, 1, &rtcm->fence));

		//static std::chrono::time_point<std::chrono::steady_clock>  now, start;
	    //start  = std::chrono::high_resolution_clock::now();
		VK_CHECK_RESULT(vkQueueSubmit($queue, 1, &submitInfo, rtcm->fence));

		//do {
		//	result = vkWaitForFences($device, 1, &rtcm->fence, VK_TRUE, 0.1_fr);
		//} while (result == VK_TIMEOUT);

		
		//now  = std::chrono::high_resolution_clock::now();
		
		//printf("Submit RT   execution Critical    time    %.5f    milli second      result   %u   Sleeping  3 second.... \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()), (UINT)result);
	
		//Sleep(100);

		//swapchain->submit(&swapchain->drawCmdBuffers[swapchain->current.frame]);

	
	}



	template<class T>
	void RTVk<T>::createPipelineCache()
	{
		VkPipelineCacheCreateInfo pipelineCacheCreateInfo = {};
		pipelineCacheCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
		VK_CHECK_RESULT(vkCreatePipelineCache($device, &pipelineCacheCreateInfo, nullptr, &pipelineCache));
	};
	template<class T>
	void RTVk<T>::destroyPipelineCache()
	{
		vkDestroyPipelineCache($device, pipelineCache, nullptr);
	};
	template<class T>
	void RTVk<T>::createPass(int mode) {

		{


			std::array<VkAttachmentDescription, 4> attachments = {};
			std::array<VkImageView, 4> pAttachments;

			int idx = 0;
			pAttachments[idx] = master.attaVk->colorMS.view;
			attachments[idx].format = $format.COLORFORMAT;
			attachments[idx].samples = (VkSampleCountFlagBits)master.attaVk->multisample;
			attachments[idx].loadOp = (mode == 1) ? VK_ATTACHMENT_LOAD_OP_LOAD : VK_ATTACHMENT_LOAD_OP_CLEAR; //VK_ATTACHMENT_LOAD_OP_LOAD;  // // VK_ATTACHMENT_LOAD_OP_LOAD;  ///VK_ATTACHMENT_LOAD_OP_CLEAR;// _DONT_CARE;// VK_ATTACHMENT_LOAD_OP_CLEAR;
			attachments[idx].storeOp = VK_ATTACHMENT_STORE_OP_STORE;
			attachments[idx].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
			attachments[idx].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
			attachments[idx].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
			attachments[idx].finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

			VkAttachmentReference colorReference = {};
			colorReference.attachment = idx;
			colorReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

			idx = 1;
			pAttachments[idx] = master.attaVk->depthMS.view;
			attachments[idx].format = $format.DEPTHFORMAT;
			attachments[idx].samples = (VkSampleCountFlagBits)master.attaVk->multisample;
			attachments[idx].loadOp = (mode == 1) ? VK_ATTACHMENT_LOAD_OP_LOAD : VK_ATTACHMENT_LOAD_OP_CLEAR;
			attachments[idx].storeOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
			attachments[idx].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
			attachments[idx].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
			attachments[idx].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
			attachments[idx].finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

			VkAttachmentReference depthReference = {};
			depthReference.attachment = idx;
			depthReference.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;


			idx = 2;
			pAttachments[idx] = master.attaVk->color.view;
			attachments[idx].format = $format.COLORFORMAT;
			attachments[idx].samples = VK_SAMPLE_COUNT_1_BIT;
			attachments[idx].loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;// VK_ATTACHMENT_LOAD_OP_LOAD; ///VK_ATTACHMENT_LOAD_OP_DONT_CARE;  //VK_ATTACHMENT_LOAD_OP_LOAD;
			attachments[idx].storeOp = VK_ATTACHMENT_STORE_OP_STORE;
			attachments[idx].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
			attachments[idx].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
			attachments[idx].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
			attachments[idx].finalLayout = VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;


			VkAttachmentReference resolveReference = {};
			resolveReference.attachment = idx;
			resolveReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;


			idx = 3;
			pAttachments[idx] = master.attaVk->depth.view;
			attachments[idx].format = $format.DEPTHFORMAT;
			attachments[idx].samples = VK_SAMPLE_COUNT_1_BIT;
			attachments[idx].loadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
			attachments[idx].storeOp = VK_ATTACHMENT_STORE_OP_STORE;
			attachments[idx].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
			attachments[idx].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
			attachments[idx].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
			attachments[idx].finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

			VkAttachmentReference resolvedepthReference = {};
			resolvedepthReference.attachment = idx;
			resolvedepthReference.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

			VkSubpassDescription subpass = {};
			subpass.flags = VK_SUBPASS_DESCRIPTION_PER_VIEW_ATTRIBUTES_BIT_NVX;
			subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
			subpass.colorAttachmentCount = 1;
			subpass.pColorAttachments = &colorReference;
			subpass.pResolveAttachments = &resolveReference;
			subpass.pDepthStencilAttachment = &depthReference;

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


			const uint32_t viewMask = 0b00000011;
			const uint32_t correlationMask = 0b00000011;

			VkRenderPassMultiviewCreateInfo renderPassMultiviewCI{};
			renderPassMultiviewCI.sType = VK_STRUCTURE_TYPE_RENDER_PASS_MULTIVIEW_CREATE_INFO;
			renderPassMultiviewCI.subpassCount = 1;
			renderPassMultiviewCI.pViewMasks = &viewMask;
			renderPassMultiviewCI.correlationMaskCount = 1;
			renderPassMultiviewCI.pCorrelationMasks = &correlationMask;



			VkRenderPassCreateInfo renderPassInfo = vka::plysm::renderPassCreateInfo();
			renderPassInfo.attachmentCount = attachments.size();
			renderPassInfo.pAttachments = attachments.data();
			renderPassInfo.subpassCount = 1;
			renderPassInfo.pSubpasses = &subpass;
			renderPassInfo.dependencyCount = 2;
			renderPassInfo.pDependencies = dependencies.data();
			renderPassInfo.pNext = &renderPassMultiviewCI;

			VK_CHECK_RESULT(vkCreateRenderPass($device, &renderPassInfo, nullptr, &renderPass));


			VkFramebufferCreateInfo frameBufferCreateInfo = {};
			frameBufferCreateInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
			frameBufferCreateInfo.pNext = NULL;
			frameBufferCreateInfo.renderPass = renderPass;
			frameBufferCreateInfo.attachmentCount = pAttachments.size();
			frameBufferCreateInfo.pAttachments = pAttachments.data();
			frameBufferCreateInfo.width = master.attaVk->w;
			frameBufferCreateInfo.height = master.attaVk->h;
			frameBufferCreateInfo.layers = 1;
			VK_CHECK_RESULT(vkCreateFramebuffer($device, &frameBufferCreateInfo, nullptr, &frameBuffer));
			VkRenderPassBeginInfo   renderPassBeginInfo = vka::plysm::renderPassBeginInfo();
			renderPassBeginInfo.renderPass = renderPass;
			renderPassBeginInfo.renderArea.offset.x = 0;
			renderPassBeginInfo.renderArea.offset.y = 0;
			renderPassBeginInfo.renderArea.extent.width = master.attaVk->w;
			renderPassBeginInfo.renderArea.extent.height = master.attaVk->h;
			renderPassBeginInfo.framebuffer = frameBuffer;

			if (mode == 1) {
				renderPassBeginInfo.clearValueCount = 0;
				///p.clearValues[0].color = { { 0.2f, 0.2f, 0.5f, 0.0f } };
				///renderPassBeginInfo.pClearValues = p.clearValues;
			}
			else {
				clearValues[0].color = { { 0.5f, 0.0f, 1.0f, 1.0f } };
				clearValues[1].depthStencil = { 1.0f, 0 };
				renderPassBeginInfo.clearValueCount = 2;
				renderPassBeginInfo.pClearValues = clearValues;
			
			}

			beginInfo = renderPassBeginInfo;
			VkCommandBufferInheritanceInfo    inheritanceInfo = vka::plysm::commandBufferInheritanceInfo();
			inheritanceInfo.renderPass = renderPass;
			inheritanceInfo.framebuffer = frameBuffer;
			inheri = inheritanceInfo;


		}

	};
	template<class T>
	void RTVk<T>::destroyPass() {
		if (frameBuffer != VK_NULL_HANDLE) {
			vkDestroyFramebuffer($device, frameBuffer, nullptr);
			vkDestroyRenderPass($device, renderPass, nullptr);
			frameBuffer = VK_NULL_HANDLE;
		}

	};


	template<class T>
	void RTVk<T>::SetFormat(VkFormat format) {
		__format.COLORFORMAT_RT = format;
	};


template<class T>
	bool RTVk<T>::extentImage(UINT i,UINT w,UINT h) {
		if (images.size() > i) {
			return  (images[i].w == w && images[i].h == h);
		}
		return false;
	}

	template<class T>
     uint32_t  RTVk<T>::createImage(uint32_t w,uint32_t h, uint32_t nums) {
		
		destroyImages();

		images.resize(nums);


		rtcm->cmdSet(0);
		for (auto& desc : images) {

			VkImageCreateInfo imageCreateInfo = { VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO };
			imageCreateInfo.imageType = VK_IMAGE_TYPE_2D;
			imageCreateInfo.extent.width = desc.w = w;
			imageCreateInfo.extent.height = desc.h = h;
			imageCreateInfo.extent.depth = desc.d = 1;
			imageCreateInfo.mipLevels = desc.mipLevel = 1;
			imageCreateInfo.arrayLayers = desc.l = 1;
			imageCreateInfo.format = $format.COLORFORMAT_RT;
			imageCreateInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
			imageCreateInfo.samples = VK_SAMPLE_COUNT_1_BIT;  ///(VkSampleCountFlagBits)m_nMSAASampleCount;
			imageCreateInfo.usage = (VK_IMAGE_USAGE_STORAGE_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT);
			imageCreateInfo.flags = 0;

			VkResult nResult;
			nResult = vkCreateImage($device, &imageCreateInfo, nullptr, &desc.image);
			if (nResult != VK_SUCCESS)
			{
				log_bad("vkCreateImage failed for eye image with error %d\n", nResult);
				return false;
			}

			desc.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;

			VkMemoryRequirements memoryRequirements = {};
			vkGetImageMemoryRequirements($device, desc.image, &memoryRequirements);

			VkMemoryAllocateInfo memoryAllocateInfo = { VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO };
			memoryAllocateInfo.allocationSize = memoryRequirements.size;
			if (!vka::shelve::MemoryTypeFromProperties(memoryRequirements.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &memoryAllocateInfo.memoryTypeIndex))
			{
				log_bad("Failed to find memory type matching requirements.\n");
				return false;
			}

			nResult = vkAllocateMemory($device, &memoryAllocateInfo, nullptr, &desc.memory);
			if (nResult != VK_SUCCESS)
			{
				log_bad("Failed to find memory for image.\n");
				return false;
			}

			nResult = vkBindImageMemory($device, desc.image, desc.memory, 0);
			if (nResult != VK_SUCCESS)
			{
				log_bad("Failed to bind memory for image.\n");
				return false;
			}


			VkImageViewCreateInfo imageViewCI = vka::plysm::imageViewCreateInfo();
			imageViewCI.viewType = VK_IMAGE_VIEW_TYPE_2D;
			imageViewCI.format = $format.COLORFORMAT_RT;
			imageViewCI.flags = 0;
			imageViewCI.subresourceRange = {};
			imageViewCI.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			imageViewCI.subresourceRange.baseMipLevel = 0;
			imageViewCI.subresourceRange.levelCount = 1;
			imageViewCI.subresourceRange.baseArrayLayer = 0;
			imageViewCI.subresourceRange.layerCount = 1;
			imageViewCI.image = desc.image;
			VK_CHECK_RESULT(vkCreateImageView($device, &imageViewCI, nullptr, &desc.view));

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
			VK_CHECK_RESULT(vkCreateSampler($device, &samplerCI, nullptr, &desc.sampler));

			// Fill a descriptor for later use in a descriptor set 
			desc.Info.imageLayout = VK_IMAGE_LAYOUT_GENERAL;
			desc.Info.imageView = desc.view;
			desc.Info.sampler = desc.sampler;

			cmcm::TransX(*rtcm, desc, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

		}



			return  uint32_t(images.size() - 1);
	};
	 template<class T>
	 uint32_t  RTVk<T>::createImageAndBuffer(uint32_t w, uint32_t h, uint32_t nums) {

		 destroyImages();

		 images.resize(nums);


		 rtcm->cmdSet(0);

		 size_t compoSize = 0;
		 switch ($format.COLORFORMAT_RT) {
		 case VK_FORMAT_R32G32B32A32_SFLOAT:
			 compoSize = 16; break;
		 case VK_FORMAT_R8G8B8A8_UNORM:
			 compoSize = 4; break;
		 default:
			 log_bad("createImageAndBuffer::Unknwoun Format come.   %u \n" , (UINT)$format.COLORFORMAT_RT);
			 break;
		 }

		 for (auto& desc : images) {
			 VkResult nResult;
			 VkBufferCreateInfo BufferInfo = {};
			 {
				 BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
				 BufferInfo.size =  w*h* compoSize;
				 BufferInfo.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
				 VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &desc.buffer));
				 desc.bInfo.buffer = desc.buffer;
				 desc.bInfo.offset = 0;
				 desc.bInfo.range = BufferInfo.size;
			 }

			 VkImageCreateInfo imageCreateInfo = { VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO };
			 {
				 imageCreateInfo.imageType = VK_IMAGE_TYPE_2D;
				 imageCreateInfo.extent.width = desc.w = w;
				 imageCreateInfo.extent.height = desc.h = h;
				 imageCreateInfo.extent.depth = desc.d = 1;
				 imageCreateInfo.mipLevels = desc.mipLevel = 1;
				 imageCreateInfo.arrayLayers = desc.l = 1;
				 imageCreateInfo.format = $format.COLORFORMAT_RT;
				 imageCreateInfo.tiling = VK_IMAGE_TILING_OPTIMAL;// VK_IMAGE_TILING_LINEAR;
				 imageCreateInfo.samples = VK_SAMPLE_COUNT_1_BIT;  ///(VkSampleCountFlagBits)m_nMSAASampleCount;
				 imageCreateInfo.usage = (VK_IMAGE_USAGE_STORAGE_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT);
				 imageCreateInfo.flags = 0;

				 
				 nResult = vkCreateImage($device, &imageCreateInfo, nullptr, &desc.image);
				 if (nResult != VK_SUCCESS)
				 {
					 log_bad("vkCreateImage failed for eye image with error %d\n", nResult);
					 return false;
				 }
			 }

			 desc.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;

			 VkMemoryRequirements memoryRequirements = {};
			 vkGetImageMemoryRequirements($device, desc.image, &memoryRequirements);
			 VkMemoryRequirements memoryRequirements2 = {};
			 vkGetBufferMemoryRequirements($device, desc.buffer, &memoryRequirements2);

			 VkMemoryAllocateInfo memoryAllocateInfo = { VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO };
			 memoryAllocateInfo.allocationSize =  memoryRequirements.size +  memoryRequirements2.size;
			 if (!vka::shelve::MemoryTypeFromProperties(memoryRequirements.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, &memoryAllocateInfo.memoryTypeIndex))
			 {
				 log_bad("Failed to find memory type matching requirements.\n");
				 return false;
			 }

			 nResult = vkAllocateMemory($device, &memoryAllocateInfo, nullptr, &desc.memory);
			 if (nResult != VK_SUCCESS)
			 {
				 log_bad("Failed to find memory for image.\n");
				 return false;
			 }

			 nResult = vkBindImageMemory($device, desc.image, desc.memory, 0);
			 if (nResult != VK_SUCCESS)
			 {
				 log_bad("Failed to bind memory for image.\n");
				 return false;
			 }

			 VK_CHECK_RESULT(vkBindBufferMemory($device, desc.buffer, desc.memory, memoryRequirements.size));


			 VkImageViewCreateInfo imageViewCI = vka::plysm::imageViewCreateInfo();
			 imageViewCI.viewType = VK_IMAGE_VIEW_TYPE_2D;
			 imageViewCI.format = $format.COLORFORMAT_RT;
			 imageViewCI.flags = 0;
			 imageViewCI.subresourceRange = {};
			 imageViewCI.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
			 imageViewCI.subresourceRange.baseMipLevel = 0;
			 imageViewCI.subresourceRange.levelCount = 1;
			 imageViewCI.subresourceRange.baseArrayLayer = 0;
			 imageViewCI.subresourceRange.layerCount = 1;
			 imageViewCI.image = desc.image;
			 VK_CHECK_RESULT(vkCreateImageView($device, &imageViewCI, nullptr, &desc.view));

			 // Create sampler to sample from the attachment in the fragment shader
			 VkSamplerCreateInfo samplerCI = vka::plysm::samplerCreateInfo();
			 samplerCI.magFilter = VK_FILTER_LINEAR;
			 samplerCI.minFilter = VK_FILTER_LINEAR;
			 samplerCI.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
			 samplerCI.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
			 samplerCI.addressModeV = samplerCI.addressModeU;
			 samplerCI.addressModeW = samplerCI.addressModeU;
			 samplerCI.mipLodBias = 0.0f;
			 samplerCI.maxAnisotropy = 1.0f;
			 samplerCI.minLod = 0.0f;
			 samplerCI.maxLod = 1.0f;
			 samplerCI.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
			 VK_CHECK_RESULT(vkCreateSampler($device, &samplerCI, nullptr, &desc.sampler));

			 // Fill a descriptor for later use in a descriptor set 
			 desc.Info.imageLayout = VK_IMAGE_LAYOUT_GENERAL;
			 desc.Info.imageView = desc.view;
			 desc.Info.sampler = desc.sampler;



			 cmcm::TransX(*rtcm, desc, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

		 }



		 return  uint32_t(images.size() - 1);
	 };
	 template<class T>
	 bool RTVk<T>::destroyImages() {
		for (auto& v : images) v.dealloc();
		return true;
	}


template<class T>
	int RTVk<T>::enter() {



		return 0;

	};
	template<class T>
	bool RTVk<T>::isUpdate() {
		return signal.update;
	};
	template<class T>
	void RTVk<T>::Quit() {
		signal.escape = true;
		ReleaseSemaphore(signal.Request.RedLight, 1, NULL);
	};

	template<class T>
int  RTVk<T>::submit() {
		return 0;
	};

	template<class T>
	bool RTVk<T>::update() {

		///if (commander.event == nullptr) {commander.update();}
		return true;
	};
template<class T>
	int RTVk<T>::init() {

		///commander.deployment_process();
		return 0;
	};
template<class T>
	int RTVk<T>::exit() {
		return 0;
	}
	template<class T>
	void RTVk<T>::Swap() {
	};


	template RTVk<MBIVSIvk>;
};