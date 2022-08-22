#include "pch_mm.h"
#include "working_mm.h"




void  ImmidiateCmdPool3::alloc() {
	createSemaphore();
	cmdBufInfo          = vka::plysm::commandBufferBeginInfo();
	cmdBufInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
}
void  ImmidiateCmdPool3::allocCmd(int i) {
	///free();
	createCommandPool();
	VkCommandBufferAllocateInfo cmdBufAllocateInfo = vka::plysm::commandBufferAllocateInfo(cmdPool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, i);
	cmds = new std::vector<VkCommandBuffer>;
	cmds->resize(i);
	VK_CHECK_RESULT(vkAllocateCommandBuffers($device, &cmdBufAllocateInfo, cmds->data()));

}
void  ImmidiateCmdPool3::free() {

	if (cmds != nullptr && cmds->size() != 0) {
		vkFreeCommandBuffers($device, cmdPool, cmds->size(), cmds->data()); 
		delete cmds;
	}
	cmd = VK_NULL_HANDLE;
	ImmidiateCmdPool::free();
	destroySemaphore();
}
void ImmidiateCmdPool3::begin() {
	ImmidiateCmdPool::begin();
};

void ImmidiateCmdPool3::end() {

	ImmidiateCmdPool::end();

};
void ImmidiateCmdPool3::cmdSet(int i) {
	cmd = (*cmds)[i];
};

VkCommandBuffer ImmidiateCmdPool3::begin(int i) {
	cmd = (*cmds)[i];
	VK_CHECK_RESULT(vkBeginCommandBuffer(cmd, &cmdBufInfo));
	commit = true;
	return cmd;
};

void ImmidiateCmdPool3::setInfo(VkCommandBufferUsageFlags flag) {
	 cmdBufInfo = vka::plysm::commandBufferBeginInfo();
	 cmdBufInfo.flags = flag;
}

VkCommandBuffer ImmidiateCmdPool3::begin(int i, VkCommandBufferBeginInfo  binfo ) {

	cmd = (*cmds)[i];
	VK_CHECK_RESULT(vkBeginCommandBuffer(cmd, &binfo));
	commit = true;
	return cmd;

};


void ImmidiateCmdPool3::end(int i) {

	VK_CHECK_RESULT(vkEndCommandBuffer((*cmds)[i]));

};

void ImmidiateCmdPool3::submit(int i) {

	VkSubmitInfo submitInfo = vka::plysm::submitInfo();
	submitInfo.waitSemaphoreCount = 0;
	submitInfo.signalSemaphoreCount = 0;
	submitInfo.commandBufferCount = 1;
	if (i < 0) {
		submitInfo.pCommandBuffers = cmds->data();
		submitInfo.commandBufferCount = cmds->size();
	}
	else submitInfo.pCommandBuffers = &((*cmds)[i]);

	VK_CHECK_RESULT(vkQueueSubmit(queue, 1, &submitInfo, VK_NULL_HANDLE));

	//log_imcm("IMCM     QUEUE submit   [%x]     %p  \n", _threadid, queue);

};



void  ImmidiateCmdPool::alloc() {

	createCommandPool();
	VkCommandBufferAllocateInfo cmdBufAllocateInfo = vka::plysm::commandBufferAllocateInfo(cmdPool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1);
	VK_CHECK_RESULT(vkAllocateCommandBuffers($device, &cmdBufAllocateInfo, &cmd));
	log_imcm("IMCM    queue   %x    pool    %x    cmd    %x    \n ", queue, cmdPool, cmd);

};

void  ImmidiateCmdPool2::alloc() {
	ImmidiateCmdPool::alloc();
	createSemaphore();
}

void  ImmidiateCmdPool::free() {
	freeStaging();
	if (cmd != VK_NULL_HANDLE) {
		log_imcm("dealloc  Immidiate    %p  \n", cmd);
		vkFreeCommandBuffers($device, cmdPool, 1, &cmd); cmd = VK_NULL_HANDLE;
	}
	destroyCommandPool();
};

void  ImmidiateCmdPool2::free() {
	ImmidiateCmdPool::free();
	destroySemaphore();
}



bool  ImmidiateCmdPool::allocStaging(size_t size) {
	if (staging.Nums == 0) {

		staging.allocInfo = vka::plysm::memoryAllocateInfo();
		staging.bufferCreateInfo = vka::plysm::bufferCreateInfo();
		staging.bufferCreateInfo.size = 0;
		staging.bufferCreateInfo.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		staging.bufferCreateInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

		///staging.memReqs.memoryTypeBits = 1665;
		///staging.allocInfo.memoryTypeIndex = vka::shelve::getMemoryType(staging.memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
		staging.allocInfo.allocationSize = 0;

	}
	else log_img("Bridge Test ==>>   NUMS == %d   \n", staging.Nums);
	staging.Nums++;
	if (staging.bufferCreateInfo.size < size) {

		if (staging.bufferCreateInfo.size != 0) {
			log_img("Bridge Test ==>>  destroy  stagingBuffer   %p  \n", staging.buffer);
			vkDestroyBuffer($device, staging.buffer, nullptr);
		}
		staging.bufferCreateInfo.size = size;
		VK_CHECK_RESULT(vkCreateBuffer($device, &staging.bufferCreateInfo, nullptr, &staging.buffer));
		vkGetBufferMemoryRequirements($device, staging.buffer, &staging.memReqs);
		staging.allocInfo.memoryTypeIndex = vka::shelve::getMemoryType(staging.memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, nullptr);
		log_img("Bridge Test ==>>  recreate  stagingBuffer   %zu   %p    TypeBits   %u   TypeIndex  %u \n", staging.bufferCreateInfo.size, staging.buffer, (uint32_t)staging.memReqs.memoryTypeBits, (uint32_t)staging.allocInfo.memoryTypeIndex);

		///if (staging.allocInfo.allocationSize < staging.memReqs.size) {
			///if (staging.allocInfo.allocationSize != 0) {

		if (staging.allocInfo.allocationSize != 0) {
			log_img("Bridge Test ==>> Free  stagingMemory   %p  \n", staging.memory);
			vkFreeMemory($device, staging.memory, nullptr);
		}
		staging.allocInfo.allocationSize = staging.memReqs.size;
		VK_CHECK_RESULT(vkAllocateMemory($device, &staging.allocInfo, nullptr, &staging.memory));
		VK_CHECK_RESULT(vkBindBufferMemory($device, staging.buffer, staging.memory, 0));
		log_img("Bridge Test ==>>  reallocate  stagingMemory   %zu    %p  \n", staging.memReqs.size, staging.memory);
	}

	return true;
};
void  ImmidiateCmdPool::freeStaging() {

	if (staging.buffer != VK_NULL_HANDLE) {

		vkDestroyBuffer($device, staging.buffer, nullptr);

	}

	if (staging.memory != VK_NULL_HANDLE) {
		vkFreeMemory($device, staging.memory, nullptr);

	}

	staging = { VK_NULL_HANDLE ,VK_NULL_HANDLE ,nullptr };

};


void ImmidiateCmdPool::begin() {
	static VkCommandBufferBeginInfo cmdBufInfo = vka::plysm::commandBufferBeginInfo();

	log_imcm("IMCM    queue  BEGIN   %x    pool    %x    cmd    %x    \n ", queue, cmdPool, cmd);
	VK_CHECK_RESULT(vkBeginCommandBuffer(cmd, &cmdBufInfo));
	commit = true;
};

void ImmidiateCmdPool::end() {

	VK_CHECK_RESULT(vkEndCommandBuffer(cmd));
	log_img("IMCM    Make  CopyAfterX      %x    \n ", cmd);

};

void ImmidiateCmdPool::submit(int  i) {

	VkSubmitInfo submitInfo = vka::plysm::submitInfo();
	submitInfo.commandBufferCount = 1;
	submitInfo.pCommandBuffers = &cmd;

	VK_CHECK_RESULT(vkQueueSubmit(queue, 1, &submitInfo, VK_NULL_HANDLE));

	///log_imcm("IMCM     QUEUE submit   [%x]     %p  \n", _threadid, queue);

};






void ImmidiateCmdPool2::submit(int i) {

	if (i == 0) return ImmidiateCmdPool::submit(0);

	VkSubmitInfo submitInfo = vka::plysm::submitInfo();
	static VkPipelineStageFlags graphicsWaitStageMasks[] = { VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT };
	VkSemaphore graphicsWaitSemaphores[] = { waitSemaphore };
	if (i == 2 || i == 3) {
		submitInfo.pWaitDstStageMask = graphicsWaitStageMasks;
		submitInfo.pWaitSemaphores = graphicsWaitSemaphores;
		submitInfo.waitSemaphoreCount = 1;
	}

	if (i == 1 || i == 3) {
		submitInfo.signalSemaphoreCount = 1;
		submitInfo.pSignalSemaphores = &semaphore;
	}

	submitInfo.commandBufferCount = 1;
	submitInfo.pCommandBuffers = &cmd;

	VK_CHECK_RESULT(vkQueueSubmit(queue, 1, &submitInfo, VK_NULL_HANDLE));

	//log_imcm("IMCM     QUEUE submit   [%x]     %p  \n", _threadid, queue);

};



void ImmidiateCmdPool::wait() {

	///log_img("IMCM   Q Submit     %x   this[%u] \n ", queue, GetCurrentThreadId());
	VK_CHECK_RESULT(vkQueueWaitIdle(queue));

	commit = false;
}

void ImmidiateCmdPool::createCommandPool()
{


	ContextVk* ctx = nullptr;

	if (!$tank.takeout(ctx, 0)) {
		log_bad(" not found  ContextVk.");
	};

	///queue = ctx->device.Qvillage.queueTR;
	static uint32_t qid = 0;
	queue = ctx->device.Qvillage.queues[qid];
	qid = (qid + 1) % 4;

	VkCommandPoolCreateInfo cmdPoolInfo = {};
	cmdPoolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
	cmdPoolInfo.queueFamilyIndex = ctx->device.Qvillage.index[0];
	cmdPoolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
	VK_CHECK_RESULT(vkCreateCommandPool($device, &cmdPoolInfo, nullptr, &cmdPool));

};

void ImmidiateCmdPool::destroyCommandPool() {
	if (cmdPool != VK_NULL_HANDLE) {
		vkDestroyCommandPool($device, cmdPool, nullptr);
		cmdPool = VK_NULL_HANDLE;
	}
};


/*
template<class Pool>
ImmidiateBufferCmd<Pool>::ImmidiateBufferCmd() { alloc(); };


template<class Pool>
ImmidiateBufferCmd<Pool>::~ImmidiateBufferCmd() { free(); };

template<class Pool>
void ImmidiateBufferCmd<Pool>::alloc() {
		Pool::alloc();
	}

template<class Pool>
void ImmidiateBufferCmd<Pool>::free() {
		Pool::free();
	};

template<class Pool>
bool ImmidiateBufferCmd<Pool>::Map(void* src, VkDeviceSize offset, VkDeviceSize size) {

		char* dst;
		VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, offset, size, 0, (void**)&dst));
		memcpy(dst, src, size);
		vkUnmapMemory($device, Pool::staging.memory);

		return true;

	};

template<class Pool>
template<class B>
bool ImmidiateBufferCmd<Pool>::Copy(B& _, VkDeviceSize size, VkDeviceSize srcOffset , VkDeviceSize dstOffset ) {

	VkBufferCopy copyRegion = { srcOffset ,dstOffset,size };
	vkCmdCopyBuffer(Pool::cmd, Pool::staging.buffer, _.buffer, 1, &copyRegion);
	return true;
};

*/
template<class Pool>
ImmidiateCmd<Pool>::ImmidiateCmd(VkCommandPool pool) {
	VkCommandBufferAllocateInfo cmdBufAllocateInfo = vka::plysm::commandBufferAllocateInfo(pool, VK_COMMAND_BUFFER_LEVEL_PRIMARY, 1);
	VK_CHECK_RESULT(vkAllocateCommandBuffers($device, &cmdBufAllocateInfo, &(Pool::cmd)));
	Pool::cmdPool = VK_NULL_HANDLE;
};

template<class Pool>
ImmidiateCmd<Pool>::ImmidiateCmd() {
	Pool::alloc();
};

template<class Pool>
ImmidiateCmd<Pool>::~ImmidiateCmd() {
	///if (cmd != VK_NULL_HANDLE) { log_bad("Memory Leak ImmidiateCommands ?   %p    \n", cmd); }
	Pool::free();
}


template<class Pool>
ImmidiateRTCmd<Pool>::ImmidiateRTCmd() {
	Pool::alloc();
};


template<class Pool>
ImmidiateRTCmd<Pool>::~ImmidiateRTCmd() { Pool::free(); };

template<class Pool>
bool ImmidiateCmd<Pool>::bridgeMap(MIVSIvk& _, void* src, VkImageLayout X) {

	Pool::allocStaging(_);

	char* dst;

	VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, 0, Pool::staging.allocInfo.allocationSize, 0, (void**)&dst));
	memcpy(dst, src, _.size);
	vkUnmapMemory($device, Pool::staging.memory);


	VkBufferImageCopy Region = {};
	Region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	Region.imageSubresource.mipLevel = 0;
	Region.imageSubresource.layerCount = 1;
	Region.imageExtent.width = _.w;
	Region.imageExtent.height = _.h;
	Region.imageExtent.depth = 1;

	std::vector<VkBufferImageCopy> bufferCopyRegions;
	for (int i = 0; i < int(_.l); i++) {
		Region.imageSubresource.baseArrayLayer = i;
		if (i > 0)Region.imageExtent.width = 0;
		bufferCopyRegions.push_back(Region);
	}

	CopyArrayAfterX(Pool::staging.buffer, _, std::move(bufferCopyRegions), X);


	return true;

};
template<class Pool>
bool ImmidiateCmd<Pool>::bridgeMap(MIVSIvk& _, void* src, int layer, VkImageLayout X) {

	Pool::allocStaging(_);

	char* dst;

	VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, 0, Pool::staging.allocInfo.allocationSize, 0, (void**)&dst));
	memcpy(dst, src, _.size);
	vkUnmapMemory($device, Pool::staging.memory);


	VkBufferImageCopy Region = {};
	Region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	Region.imageSubresource.mipLevel = 0;
	Region.imageSubresource.layerCount = 1;
	Region.imageSubresource.baseArrayLayer = layer;
	Region.imageExtent.width = _.w;
	Region.imageExtent.height = _.h;
	Region.imageExtent.depth = 1;
	CopyAfterX(Pool::staging.buffer, _, { Region }, X);

	return true;

};
template<class Pool>
bool ImmidiateCmd<Pool>::bridgeMapArray(MIVSIvk& _, ktxTexture* ktxTexture, VkImageLayout X) {

	Pool::allocStaging(_);

	uint8_t* data;
	ktx_uint8_t* ktxTextureData = ktxTexture_GetData(ktxTexture);
	VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, 0, Pool::staging.memReqs.size, 0, (void**)&data));
	memcpy(data, ktxTextureData, _.size);
	vkUnmapMemory($device, Pool::staging.memory);


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

	CopyArrayAfterX(Pool::staging.buffer, _, std::move(bufferCopyRegions), X);

	return true;
}

template<class Pool>
bool ImmidiateCmd<Pool>::bridgeMap(MIVSIvk& _, void* src, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X) {

	Pool::allocStaging(_);

	char* dst;

	VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, 0, Pool::staging.allocInfo.allocationSize, 0, (void**)&dst));
	memcpy(dst, src, _.size);
	vkUnmapMemory($device, Pool::staging.memory);

	CopyAfterX(Pool::staging.buffer, _, bufferCopyRegions, X);

	return true;

};

template<class Pool>
void  ImmidiateCmd<Pool>::free() {
	Pool::free();
}

template<class Pool>
void  ImmidiateCmd<Pool>::CopyAfterShaderRead(VkBuffer src, VkImage dst, VkBufferImageCopy bufferCopyRegion) {

	Pool::begin();

	vka::shelve::setImageLayout(
		Pool::cmd,
		dst,
		VK_IMAGE_ASPECT_COLOR_BIT,
		VK_IMAGE_LAYOUT_UNDEFINED,
		VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);

	vkCmdCopyBufferToImage(
		Pool::cmd,
		src,
		dst,
		VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		1,
		&bufferCopyRegion
	);

	vka::shelve::setImageLayout(
		Pool::cmd,
		dst,
		VK_IMAGE_ASPECT_COLOR_BIT,
		VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);


	Pool::end();

};
template<class Pool>
void  ImmidiateCmd<Pool>::CopyArrayAfterShaderRead(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy> bufferCopyRegion) {




	Pool::begin();

	VkImageSubresourceRange subresourceRange = {};
	subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	subresourceRange.baseMipLevel = 0;
	subresourceRange.levelCount = 1;
	subresourceRange.layerCount = uint32_t(bufferCopyRegion.size());

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
		bufferCopyRegion.size(),
		bufferCopyRegion.data()
	);


	vka::shelve::setImageLayout(
		Pool::cmd,
		dst.image,
		VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
		subresourceRange);

	Pool::end();
	dst.Info.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
};
template<class Pool>
void  ImmidiateCmd<Pool>::CopyArrayAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy> _bufferCopyRegion, VkImageLayout X) {


	std::vector<VkBufferImageCopy> bufferCopyRegion;
	uint32_t base = 0;
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
		bufferCopyRegion.size(),
		bufferCopyRegion.data()
	);


	vka::shelve::setImageLayout(
		Pool::cmd,
		dst.image,
		VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		X,
		subresourceRange);

	Pool::end();
	Pool::submit();
	Pool::wait();


	log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


	dst.Info.imageLayout = X;

};
template<class Pool>
void  ImmidiateCmd<Pool>::CopyAfterX(VkBuffer src, MIVSIvk& dst, VkBufferImageCopy& _bufferCopyRegion, VkImageLayout X, int submitFlag) {


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
	Pool::submit(submitFlag);
	Pool::wait();


	log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


	dst.Info.imageLayout = X;

};
template<class Pool>
void  ImmidiateCmd<Pool>::CopyAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X) {

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
	Pool::submit();
	Pool::wait();


	log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


	dst.Info.imageLayout = X;

};

template<class Pool>
void  ImmidiateCmd<Pool>::TransX(MIVSIvk& dst, VkImageLayout O, VkImageLayout X) {

	VkImageSubresourceRange subresourceRange = {};
	subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	subresourceRange.baseMipLevel = 0;
	subresourceRange.levelCount = dst.mipLevel;
	subresourceRange.layerCount = dst.l;

	Pool::begin();

	vka::shelve::setImageLayout(
		Pool::cmd,
		dst.image,
		O,
		X,
		subresourceRange);

	Pool::end();
	Pool::submit();
	Pool::wait();


	log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


	dst.Info.imageLayout = X;

};

template<class Pool>
void  ImmidiateCmd<Pool>::MakeCopyAfterX(VkBuffer src, MIVSIvk& dst, VkBufferImageCopy& _bufferCopyRegion, VkImageLayout X) {


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
template<class Pool>
void  ImmidiateCmd<Pool>::MakeCopyAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X) {

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


template<class Pool>
void 	 ImmidiateCmd<Pool>::BlitImageAfterX(MIVvk& dst, MIVvk& src, std::vector<VkImageBlit> BlitRegion, VkImageLayout X, VkFilter  filter, VkImageLayout Y) {
	/*
	VkImageBlit blit_region = {};
	blit_region.srcSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	blit_region.srcSubresource.baseArrayLayer = 0;
	blit_region.srcSubresource.layerCount = 1;
	blit_region.srcSubresource.mipLevel = 0;
	blit_region.dstSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	blit_region.dstSubresource.baseArrayLayer = 0;
	blit_region.dstSubresource.layerCount = 1;
	blit_region.dstSubresource.mipLevel = 0;
	blit_region.srcOffsets[0] = { 0, 0, 0 };
	blit_region.srcOffsets[1] = { 256, 256, 1 };
	blit_region.dstOffsets[0] = { 0, 0, 0 };
	blit_region.dstOffsets[1] = { 128, 128, 1 };
	*/

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

	subresourceRange.layerCount = src.l;

	vka::shelve::setImageLayout(
		Pool::cmd,
		src.image,
		src.Info.imageLayout,
		VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		subresourceRange);

	vkCmdBlitImage(Pool::cmd, src.image, VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		dst.image, VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		(uint32_t)BlitRegion.size(), BlitRegion.data(), filter);


	vka::shelve::setImageLayout(
		Pool::cmd,
		src.image,
		VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
		X,
		subresourceRange);


	subresourceRange.layerCount = dst.l;

	vka::shelve::setImageLayout(
		Pool::cmd,
		dst.image,
		VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
		X,
		subresourceRange);

	Pool::end();
	Pool::submit();
	Pool::wait();


	log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);

	src.Info.imageLayout = X;
	dst.Info.imageLayout = Y;

};

template<class Pool>
void 	 ImmidiateCmd<Pool>::CopyImageAfterX(MIVSIvk& dst, MIVSIvk& src, VkImageLayout X, VkImageLayout Y)
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

///template struct ImmidiateBufferCmd<ImmidiateCmdPool>;
template struct ImmidiateCmd<ImmidiateCmdPool>;
template struct ImmidiateCmd<ImmidiateCmdPool2>;
template struct ImmidiateCmd<ImmidiateCmdPool3>;

template struct ImmidiateRTCmd<ImmidiateCmdPool3>;