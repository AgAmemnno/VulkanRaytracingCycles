#pragma once


#ifndef ImmutableVK_H
#define ImmutableVK_H
#include "types.hpp"
#include "working.h"
#include "materials/common.hpp"
#include "core/common.hpp"
#include "threepy_working.h"

//#include <format>
#ifndef ENABLED_VULKAN_HEADLESS
#include "swapchain.h"
#endif


#ifdef  LOG_NO_imm
#define log_imm(...)
#else
#define log_imm(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif



#define TESTMUTA

MemExtern(MBvk, SIZE_MB);
MemExtern(MIBvk, SIZE_MIB);
MemExtern(MIBmvk, SIZE_MIBm);


MemExtern(Mvk, SIZE_MDev);
MemExtern(IBmvk, SIZE_IBmDev);
MemExtern(Mvk, SIZE_MVis);
MemExtern(IBmvk, SIZE_IBmVis);



namespace brunch {
#ifndef DEB
	struct FrustumVk : ComputePartyVk {

		bool   active;

		void setup();
		void shutdown();
		VkCommandBuffer begin(long cid);
		void end(long cid);
		bool submit();

	};


	struct ImmutableVk : PartyVk, BrunchVk {

		typedef std::unordered_map<aeo::Material*, _BufferGeometry*> matMap;

		struct {
			ImmidiateBufferCmd<ImmidiateCmdPool>  cmdVk;
			DescriptorVk                                                 desc;
			ObjectsVk* objVk = nullptr;
			VisibleObjectsVk* vobjVk = nullptr;
			OVR* ovr = nullptr;
			AttachmentsVk* attaVk = nullptr;
			PipelineVk* pipeVk = nullptr;
		}master;

		UniformVk                          cameraVR;
		PrimaryVk<ImmutableVk>                            commander;

		FrustumVk frustum;

		ImmutableVk(long id);
		virtual ~ImmutableVk();


		void  _turn_();
		int  command();
		int  process();

		void buffer_process(matMap& mats);
		void layout_process(matMap& next);
		void pipeline_process(matMap& mats);


		void debutCommander(Group* target);
		int   retireCommander();



		void createPass(int mode);
		void destroyPass();

		void createPipelineCache();
		void destroyPipelineCache();


		virtual  int  enter();
		virtual  int  init();
		virtual  int  exit();

		virtual  bool isUpdate();
		virtual void Quit();

		virtual int submit();
		virtual bool update();
		virtual void Swap();

	};


	struct Mutable2Vk : PartyVk, BrunchVk {

		typedef std::unordered_map<aeo::Material*, _BufferGeometry*> matMap;

		struct {
			ImmidiateBufferCmd<ImmidiateCmdPool>  cmdVk;
			DescriptorVk                                                 desc;
			ObjectsVk* objVk = nullptr;
			VisibleObjectsVk* vobjVk = nullptr;
			OVR* ovr = nullptr;
			AttachmentsVk* attaVk = nullptr;
			PipelineVk* pipeVk = nullptr;
		}master;

		UniformVk                          cameraVR;
		PrimaryVk<Mutable2Vk>                          commander;
		std::vector<Object3D*>                                   crousel;

		FrustumVk frustum;

		Mutable2Vk(long id);
		virtual ~Mutable2Vk();


		void  _turn_();
		int  command();
		int  process();

		void buffer_process(matMap& mats);
		void layout_process(matMap& next);
		void pipeline_process(matMap& mats);


		void debutCommander(Group* target);
		int   retireCommander();



		void createPass(int mode);
		void destroyPass();

		void createPipelineCache();
		void destroyPipelineCache();


		virtual  int  enter();
		virtual  int  init();
		virtual  int  exit();

		virtual  bool isUpdate();
		virtual void Quit();

		virtual int submit();
		virtual bool update();
		virtual void Swap();

	};

#endif

	template<class T = MIVSIvk>
	struct RTVk : PartyVk, BrunchVk {

		typedef std::unordered_map<aeo::Material*, _BufferGeometry*> matMap;
		typedef T storaty;
		struct {
			ImmidiateBufferCmd<ImmidiateCmdPool>  cmdVk;
			DescriptorVk                                                 desc;
			ObjectsVk* objVk = nullptr;
			VisibleObjectsVk* vobjVk = nullptr;
			OVR* ovr = nullptr;
			AttachmentsVk* attaVk = nullptr;
			PipelineVk* pipeVk = nullptr;
		}master;

		UniformVk                          cameraVR;
		//PrimaryVk<RTVk>                          commander;
		std::vector<storaty>                    images;
		std::vector<storaty>                         mrt;


		RTVk();
		RTVk(long id);
		virtual ~RTVk();



#ifndef ENABLED_VULKAN_HEADLESS
		std::function<void(void)> submitSwapChain;

		arth::eSUBMIT_MODE     submitMode;

		ImmidiateRTCmd<ImmidiateCmdPool3>* rtcm;
		SwapChainVkTy*                   swapchain= nullptr;
		std::vector <RTMaterial*>           rtmat;
		std::vector <PostMaterialVk*>    postmat;

		void setRenderGroup(arth::eSUBMIT_MODE  mode, SwapChainVkTy* _swapchain, std::vector<RTMaterial*>&& mat, std::vector<PostMaterialVk*>&& pmat);

		void  _submitSwapChainSeparate();
		void  _submitSwapChainInline();

		template<class T2>
		void submitRayTracing(uint32_t frame, T2* mat) {

			VkResult result;
			mat->pipeline_flags = 0;

			if (mat->bgInfo.bg_make)mat->pipeline_flags = 1;

			rtcm->cmdSet(frame);
			VkCommandBuffer cmd = rtcm->begin(frame);
			mat->makeCB(cmd);
			// rtcm->bufferBarrier(mat->getInfo());
			VK_CHECK_RESULT(vkEndCommandBuffer(cmd));
			submitFrameRT();
			do { result = vkWaitForFences($device, 1, &rtcm->fence, VK_TRUE, 0.1_fr); } while (result == VK_TIMEOUT);

			mat->pipeline_flags = 0;
		}
		void  submitFrameRT();
#endif




		void createPass(int mode);
		void destroyPass();

		void SetFormat(VkFormat format);

		bool   extentImage(UINT i, UINT w, UINT h);
		uint32_t  createImage(uint32_t w = 512, uint32_t h = 512,uint32_t nums =1);
		uint32_t  createImageAndBuffer(uint32_t w, uint32_t h, uint32_t nums =1);

		bool destroyImages();
		void setMRT(std::vector<int>&& idx) {
			mrt.clear();
			for (auto i : idx) {
				mrt.push_back(images[i]);
			}

		}


		void createPipelineCache();
		void destroyPipelineCache();


		virtual  int  enter();
		virtual  int  init();
		virtual  int  exit();

		virtual  bool isUpdate();
		virtual void Quit();

		virtual int submit();
		virtual bool update();
		virtual void Swap();

		void    dealloc();
	};

	typedef RTVk<MBIVSIvk> RTVkty;
	
};

#endif