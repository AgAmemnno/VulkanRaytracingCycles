#pragma once




#ifndef CIRCUS_VK_H
#define CIRCUS_VK_H
#include "types.hpp"
#include "working.h"

#ifdef  LOG_NO_cir
#define log_cir(...)
#else
#define log_cir(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif
namespace front {

	namespace circus {


#define CIRCUS_CMD 6
		int enter();



        struct CircusVk {
			bool                                                     noVR;
			VkCommandPool                                      Pool;

			VkFence                                                      fence;
			VkSemaphore                                      semaphore;
			VkCommandBuffer                                    cmd[CIRCUS_CMD];
			VkQueue                                                     queue;

            front::ListnerVk<GROUP_MAX>* listner;
			
			OVR* ovr = nullptr;
			AttachmentsVk* attaVk = nullptr;


		    MIVSIvk snapbuf;

			int imgMode = 0;

            CircusVk() {}
            ~CircusVk() {}

			int    enter();
			int    exit();
			int    submit(uint32_t cmdID);
			void  createCommandPool();
			void  destroyCommandPool();
			void  imageTransition(VkImageLayout src = VK_IMAGE_LAYOUT_UNDEFINED, VkImageLayout dst = VK_IMAGE_LAYOUT_GENERAL,int i =0);
			void  process();
			void  createCommandBuffers();
			void  destroyCommandBuffers();
			void  makeWaitFrame();
			inline bool copy2vrImg(uint32_t i);
			bool snapshot(uint32_t i);
			void makeSnapShot();
			int  submitSnapShot();
        };

		/*
		int   gateway() {


			VkPipelineStageFlags  graphicsWaitStageMasks[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
			VkSubmitInfo             submitInfo = {};

			submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
			submitInfo.commandBufferCount = 1;
			submitInfo.pCommandBuffers = &drawCmdBuffers[0];
			if (MtPass != nullptr) {
				////VkSemaphore              graphicsWaitSemaphores[] = { MtPass->primary[0].Semaphore };
				submitInfo.pWaitSemaphores = &MtPass->primary[0].Semaphore;/// graphicsWaitSemaphores;
				submitInfo.waitSemaphoreCount = 1;
				submitInfo.pWaitDstStageMask = graphicsWaitStageMasks;

			}
			else {
				submitInfo.waitSemaphoreCount = 0;
			}

			VK_CHECK_RESULT(vkResetFences(device, 1, &waitFences[0]));
			VK_CHECK_RESULT(vkQueueSubmit(queue, 1, &submitInfo, waitFences[0]));



			static auto task_MUT = [](VkRenderer* self) {
				VkResult  fenceRes = vkWaitForFences(self->device, 1, &self->waitFences[0], VK_TRUE, Hz1G);
				if (fenceRes == VK_SUCCESS) self->submitVr();
				return fenceRes;
			};
			static auto task_OVL = [](VkRenderer* self) {
				vr::VREvent_t event;
				VkResult fenceRes = VK_SUCCESS;
				if (self->VrRdr->HMD->PollNextEvent(&event, sizeof(event))) {
					self->VrRdr->ProcessVREvent(event);
					fenceRes = VK_INCOMPLETE;
				};
				return fenceRes;
			};

			std::function<VkResult(void)> f0 = std::bind(task_MUT, this);
			std::function<VkResult(void)> f1 = std::bind(task_OVL, this);

			std::vector<std::function<VkResult(void)>> worker;
			worker.push_back(f0);
			worker.push_back(f1);

			std::vector<std::future<VkResult>> fut;
			std::vector<int> IDX;


			std::vector<int> next;
			for (int i = 0; i < worker.size(); i++) { next.push_back(i); }

			do {

				fut.clear(); IDX.clear();
				for (auto& idx : next) {
					fut.push_back(std::async(std::launch::async, worker[idx]));
					IDX.push_back(idx);
				};

				next.clear();
				for (int i = 0; i < IDX.size(); i++) {
					if (fut[i].get() != VK_SUCCESS) next.push_back(IDX[i]);
				}


			} while (next.size() > 0);



			return 0;
		}
		*/
	};

};



#endif