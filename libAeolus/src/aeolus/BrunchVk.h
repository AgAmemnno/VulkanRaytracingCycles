#pragma once

#ifndef BrunchVK_H
#define BrunchVK_H

#define  LOG_NO_br
#ifdef  LOG_NO_br
#define log_br(...)
#else
#define log_br(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

#include "types.hpp"
#include "working.h"
#include "core/common.hpp"
#include "materials/common.hpp"
#include "aeolus/groupVk/common.h"
#include "aeolus/canvasVk/common.h"

namespace brunch {

    const uint32_t  MaxSize = MODE_MAX;

    struct BrunchSignal {

        bool                            update = false;
        bool                            escape = false;
        long                            ID = 0;
        unsigned                     tID = 0;
        char                           mode[MaxSize] = {};
        long                            modeID = -1;
        trafficlight                Request = { NULL };
        trafficlight                Return   = { NULL };

    };

    struct CommanderSignal {
        bool                            join = false;
        bool                            escape = false;
        long                            ID = 0;
        unsigned                     tID = 0;
        trafficlight                Join = { NULL };
        trafficlight            Return = { NULL };
    };

    struct PartyVk {

        arth::CmdType            type = arth::CmdType::Main;

        VkRenderPass                                    renderPass;
        VkFramebuffer                               frameBuffer;
        VkPipelineCache                                pipelineCache;
        VkRenderPassBeginInfo                      beginInfo;
        VkCommandBufferInheritanceInfo           inheri;
        VkClearValue                                 clearValues[3];


       
        VkSemaphore                                      semaphore;
        VkCommandBuffer                                    cmd[2];
        VkFence                                                 fence[2];


        
        VkCommandPool                                      whirlpool;
        VkQueue                                                     queue;

    };

    struct SimplyConnectedPartyVk {

        arth::CmdType                                               type = arth::CmdType::Main;
        uint32_t                                                        PassMode;
        VkRenderPass                                                renderPass = VK_NULL_HANDLE;
        VkCommandPool                                                 whirlpool = VK_NULL_HANDLE;
        VkQueue                                                                queue;
        VkPipelineCache                                         pipelineCache;
        VkFence                                                             fence[2] = { VK_NULL_HANDLE, VK_NULL_HANDLE };
        VkSemaphore                                                 semaphore =  VK_NULL_HANDLE;

        struct  FbWithCmd{
            VkFramebuffer                                   frameBuffer;
            VkRenderPassBeginInfo                           beginInfo;
            VkClearValue                                     clearValues[3];
            VkCommandBuffer                                        cmd[2];
        };

        std::vector<FbWithCmd>                                           fbcmd;

        virtual ~SimplyConnectedPartyVk();

        void resizeFramebuffer(VkFramebuffer fb);
        void resizeFramebuffer(CanvasVk* cvs);

        void createRenderpass(uint32_t flag);
        void destroyRenderpass();

        bool _createCommand(VkCommandBuffer cmd[2]);
        void createFbWithCmd(CanvasVk* cvs);

        void destroyFbWithCmd(FbWithCmd& set);
        void destroyFbWithCmdALL();

        void createPipelineCache();
        void destroyPipelineCache();

    };

    struct ComputePartyVk {

        arth::CmdType            type = arth::CmdType::Main;

        VkPipelineCache                                pipelineCache;
        VkSemaphore                                      semaphore;
        VkCommandBuffer                                    cmd[2] = { VK_NULL_HANDLE, VK_NULL_HANDLE };
        VkFence                                                 fence[2] = { VK_NULL_HANDLE, VK_NULL_HANDLE };

        VkCommandPool                                      whirlpool = VK_NULL_HANDLE;
        VkQueue                                                     queue;


        bool createCommand(VkQueue que, uint32_t family) {


            if (cmd[0] != VK_NULL_HANDLE) return true;

            if (whirlpool == VK_NULL_HANDLE) {

                queue = que;

                VkCommandPoolCreateInfo cmdPoolInfo = {};
                cmdPoolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
                cmdPoolInfo.queueFamilyIndex = family;
                cmdPoolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
                VK_CHECK_RESULT(vkCreateCommandPool($device, &cmdPoolInfo, nullptr, &whirlpool));


                VkFenceCreateInfo fenceCreateInfo = vka::plysm::fenceCreateInfo(VK_FENCE_CREATE_SIGNALED_BIT);
                VkSemaphoreCreateInfo semaphoreCI = vka::plysm::semaphoreCreateInfo();

                VK_CHECK_RESULT(vkCreateFence($device, &fenceCreateInfo, nullptr, &fence[0]));
                VK_CHECK_RESULT(vkCreateFence($device, &fenceCreateInfo, nullptr, &fence[1]));
                VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCI, nullptr, &semaphore));

                createPipelineCache();
            };

            VkCommandBufferAllocateInfo CBAI = {
                .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .commandPool = whirlpool,
                .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .commandBufferCount = 2,
            };

            VK_CHECK_RESULT(vkAllocateCommandBuffers($device, &CBAI, cmd));

            return true;
        };
        bool destroyCommand() {

            destroyPipelineCache();

            if (semaphore != VK_NULL_HANDLE) {

                vkDestroySemaphore($device, semaphore, nullptr);

                vkDestroyFence($device, fence[0], nullptr);
                vkDestroyFence($device, fence[1], nullptr);

                semaphore = VK_NULL_HANDLE;

            }

            if (whirlpool != VK_NULL_HANDLE) {

                vkFreeCommandBuffers($device, whirlpool, 2, cmd);
                vkDestroyCommandPool($device, whirlpool, nullptr);
                cmd[0] = VK_NULL_HANDLE, cmd[1] = VK_NULL_HANDLE;
                whirlpool = VK_NULL_HANDLE;
            };
            return true;
        };

        void createPipelineCache()
        {
            VkPipelineCacheCreateInfo pipelineCacheCreateInfo = {};
            pipelineCacheCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
            VK_CHECK_RESULT(vkCreatePipelineCache($device, &pipelineCacheCreateInfo, nullptr, &pipelineCache));

        };
        void destroyPipelineCache()
        {
            vkDestroyPipelineCache($device, pipelineCache, nullptr);
        };

    };

    template<class G>
    void move(G*& dst, G*&& src)
    {
        dst = std::move(src);
        src = nullptr;
    };

    struct BrunchData {
        arth::BRUNCH_PROC        type;
        bool                                   pong;
        long                              slice[2];

        union {
            Group* receiver;
            Object3D* receiverObj;
        };

    };

    typedef overQ<BrunchData*> Qty;

    struct BrunchVk {

        BrunchData                        data;
        bool                            brandNew;
        BrunchSignal                    signal;
        CommanderSignal            sigcmd;
        HANDLE                            HND;

        std::function<void(listnerData& data)>          ListnerCaller;
        BrunchVk(long id);
        virtual ~BrunchVk();
        void createSemaphore(uint32_t max);
        void destroySemaphore();

        void ClearSemaphore();
        void WaitReturn();
        void Release(char c);
        void WaitReturnCmd();
        void ReleaseCmd(char c);

        virtual void Swap() = 0;
        virtual  int  init() = 0;
        virtual  int  exit() = 0;
        virtual  int  enter() = 0;
        virtual  int  submit() =0;
        virtual  bool update() = 0;
        virtual  bool isUpdate() = 0;
        virtual  void Quit() = 0;

    };

};



#endif