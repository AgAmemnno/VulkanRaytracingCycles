#pragma once


#ifndef CmdPoolVK_H
#define CmdPoolVK_H
#include "pch_mm.h"
#include "working_mm.h"

#ifdef  LOG_imcm
#define log_imcm(...) 
#else
#define log_imcm(...)  log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif


struct  ImmidiateCmdPool {
public:


	struct {
		VkDeviceMemory memory;
		VkBuffer buffer;
		uint8_t* data;
		mutable int Nums;
		VkMemoryAllocateInfo allocInfo;
		VkMemoryRequirements memReqs;
		VkBufferCreateInfo bufferCreateInfo;
	}  staging = { VK_NULL_HANDLE ,VK_NULL_HANDLE ,nullptr ,0,{}, {},{} };


	VkCommandBuffer      cmd;
	bool                        commit;
	VkCommandPool    cmdPool;
	VkQueue                  queue;



	void createCommandPool();
	void destroyCommandPool();
	void alloc();
	void free();


	bool  allocStaging(size_t size);

	template<class INFO>
	bool  allocStaging(INFO& _) {
		return allocStaging(_.size);
	}


	void  freeStaging();
	void  begin();
	void  end();
	void  submit(int i = 0);
	void  wait();

};


struct  ImmidiateCmdPool2 :public ImmidiateCmdPool {
public:
	VkSemaphore semaphore;
	VkSemaphore waitSemaphore;

	void createSemaphore() {

		VkSemaphoreCreateInfo semaphoreCreateInfo = vka::plysm::semaphoreCreateInfo();
		VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCreateInfo, nullptr, &semaphore));

	};

	void destroySemaphore() {
		vkDestroySemaphore($device, semaphore, nullptr);
	};

	void alloc();
	void free();
	void  submit(int i = 0);
};

struct  ImmidiateCmdPool3 :public ImmidiateCmdPool {
public:
	VkSemaphore semaphore;
	VkSemaphore waitSemaphore;
	VkFence         fence;
	std::vector<VkCommandBuffer>*      cmds;
	VkCommandBufferBeginInfo cmdBufInfo;

	void setInfo(VkCommandBufferUsageFlags flag);
	void createSemaphore() {

		VkSemaphoreCreateInfo semaphoreCreateInfo = vka::plysm::semaphoreCreateInfo();
		VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCreateInfo, nullptr, &semaphore));
		VkFenceCreateInfo fenceCreateInfo = vka::plysm::fenceCreateInfo(VK_FENCE_CREATE_SIGNALED_BIT);
		VK_CHECK_RESULT(vkCreateFence($device, &fenceCreateInfo, nullptr, &fence));
	};

	void destroySemaphore() {
		vkDestroySemaphore($device, semaphore, nullptr);
		vkDestroyFence($device, fence, nullptr);
	};

	void alloc();
	void allocCmd(int);
	void free();
	void  cmdSet(int);
	void  begin();
	void  end();
	VkCommandBuffer  begin(int);
	VkCommandBuffer  begin(int i, VkCommandBufferBeginInfo  binfo);
	void  end(int);
	void  submit(int i = 0);
};


namespace cmcm {
	
	template<typename T,typename T2>
	void  TransX(T& pool,T2& dst, VkImageLayout O, VkImageLayout X) {

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = dst.mipLevel;
		subresourceRange.layerCount = dst.l;

		pool.begin();

		vka::shelve::setImageLayout(
			pool.cmd,
			dst.image,
			O,
			X,
			subresourceRange);

		pool.end();
		pool.submit();
		pool.wait();



		dst.Info.imageLayout = X;

	};

};



template<class Pool>
struct ImmidiateBufferCmd : public 	Pool {

	/*typedef ImmidiateCmdPool Pool;
	ImmidiateBufferCmd();
	~ImmidiateBufferCmd();

	void alloc();
	void free();
	bool Map(void* src, VkDeviceSize offset, VkDeviceSize size);
	template<class B>
	bool Copy(B& _, VkDeviceSize size, VkDeviceSize srcOffset = 0, VkDeviceSize dstOffset = 0);
	*/

	ImmidiateBufferCmd() {
		alloc();
	};


	~ImmidiateBufferCmd() { free(); };

	void alloc() {
		Pool::alloc();
	}

	void free() {
		Pool::free();
	};

	struct mapInfo {
		size_t offset;
		size_t size;
	}stg_info;

	char* GetMap(VkDeviceSize offset, VkDeviceSize size) {
		char* dst;
		VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, offset, size, 0, (void**)&dst));
		stg_info.offset = offset;
		stg_info.size = size;
		return dst;
	}

	bool Map(void* src, VkDeviceSize offset, VkDeviceSize size) {

		char* dst;
		VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, offset, size, 0, (void**)&dst));
		memcpy(dst, src, size);
		vkUnmapMemory($device, Pool::staging.memory);

		return true;

	};

	bool Memset(int val, VkDeviceSize offset, VkDeviceSize size) {

		char* dst;
		VK_CHECK_RESULT(vkMapMemory($device, Pool::staging.memory, offset, size, 0, (void**)&dst));
		memset(dst, val, size);
		vkUnmapMemory($device, Pool::staging.memory);

		return true;

	};
	
	bool Copy(VkBuffer  dst, VkDeviceSize size, VkDeviceSize srcOffset, VkDeviceSize dstOffset) {

		VkBufferCopy copyRegion = { srcOffset ,dstOffset,size };
		vkCmdCopyBuffer(Pool::cmd, Pool::staging.buffer, dst, 1, &copyRegion);
		return true;
	};

	template<class B>
	bool Copy(B& _, VkDeviceSize size, VkDeviceSize srcOffset, VkDeviceSize dstOffset) {

		VkBufferCopy copyRegion = { srcOffset ,dstOffset,size };
		vkCmdCopyBuffer(Pool::cmd, Pool::staging.buffer, _.buffer, 1, &copyRegion);
		return true;
	};


};

template<class Pool>
struct ImmidiateRTCmd : public 	Pool {

	ImmidiateRTCmd();
	~ImmidiateRTCmd();

	
	template<typename T>
	void imageBarrier(std::vector<T> images, VkPipelineStageFlags  X = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT){

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = 1;


		VkImageMemoryBarrier imageMemoryBarrier = vka::plysm::imageMemoryBarrier();
		imageMemoryBarrier.srcAccessMask = VK_ACCESS_SHADER_WRITE_BIT| VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_NV;
		imageMemoryBarrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
		imageMemoryBarrier.oldLayout  = VK_IMAGE_LAYOUT_GENERAL;
		imageMemoryBarrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
	
		imageMemoryBarrier.subresourceRange = subresourceRange;

		for (auto img : images) {
			imageMemoryBarrier.image = img.image;
			vkCmdPipelineBarrier(
				Pool::cmd,
				VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
				X,
				0,
				0, nullptr,
				0, nullptr,
				1, &imageMemoryBarrier);
		}

	};
	

	template<typename T>
	void bufferBarrier(std::vector<T> buffers, VkPipelineStageFlags  X = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT) {


		VkBufferMemoryBarrier bufferMemoryBarrier = vka::plysm::bufferMemoryBarrier();
		bufferMemoryBarrier.srcAccessMask = VK_ACCESS_SHADER_WRITE_BIT;
		bufferMemoryBarrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;


		for (auto info : buffers) {
			bufferMemoryBarrier.buffer = info.buffer;
			bufferMemoryBarrier.offset = info.offset;
			bufferMemoryBarrier.size = info.range;
			vkCmdPipelineBarrier(
				Pool::cmd,
				VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
				X,
				0,
				0, nullptr,
				1, &bufferMemoryBarrier,
				0, nullptr);
		}

	};




};

template<class Pool>
struct ImmidiateCmd : public Pool {

	ImmidiateCmd(VkCommandPool pool);

	ImmidiateCmd();
	~ImmidiateCmd();

	bool bridgeMap(MIVSIvk& _, void* src, VkImageLayout X);
	bool bridgeMap(MIVSIvk& _, void* src, int layer, VkImageLayout X);
	bool bridgeMapArray(MIVSIvk& _, ktxTexture* ktxTexture, VkImageLayout X);
	bool bridgeMap(MIVSIvk& _, void* src, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X);

	void free();

	void CopyAfterShaderRead(VkBuffer src, VkImage dst, VkBufferImageCopy bufferCopyRegion);
	void CopyArrayAfterShaderRead(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy> bufferCopyRegion);
	void CopyArrayAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy> _bufferCopyRegion, VkImageLayout X);
	void CopyAfterX(VkBuffer src, MIVSIvk& dst, VkBufferImageCopy& _bufferCopyRegion, VkImageLayout X, int  SubmitFlag = 0);
	void CopyAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X);
	void MakeCopyAfterX(VkBuffer src, MIVSIvk& dst, VkBufferImageCopy& _bufferCopyRegion, VkImageLayout X);
	void MakeCopyAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy>& bufferCopyRegions, VkImageLayout X);
	void  TransX(MIVSIvk& dst, VkImageLayout O, VkImageLayout X);


	void BlitImageAfterX(MIVvk& dst, MIVvk& src, std::vector<VkImageBlit> BlitRegion, VkImageLayout X, VkFilter  filter = VK_FILTER_NEAREST, VkImageLayout Y = VK_IMAGE_LAYOUT_UNDEFINED);

	void 	 CopyImageAfterX(MIVSIvk& dst, MIVSIvk& src, VkImageLayout X, VkImageLayout Y);
};

//extern template struct ImmidiateBufferCmd<ImmidiateCmdPool>;
//template struct ImmidiateCmd<ImmidiateCmdPool>;

/*
template<class C>
unsigned __stdcall DoEnter(LPVOID lpx)
{
	C* worker = (C*)lpx;

	worker->enter();

	return 0;
};


template<class C>
unsigned __stdcall DoEnterUpdate(LPVOID lpx)
{
	C* worker = (C*)lpx;

	worker->enterupdate();

	return 0;
};


template<class C>
unsigned __stdcall DoEnterOVL(LPVOID lpx)
{

	C* worker = (C*)lpx;
	worker->enterOVL();

	return 0;
};
*/

#define BEGIN_THREAD_ENTER(cls,insta) (HANDLE)_beginthreadex(NULL,0,DoEnter<cls>,&(insta),0,NULL);







#endif