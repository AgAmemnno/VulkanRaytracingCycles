#include "pch.h"
#include "working.h"


using namespace aeo;
namespace brunch {
    BrunchVk::BrunchVk(long id) {
        signal = {
          .update = false,
          .escape = false,
          .ID = id,
          .tID = _threadid,
          .Request = {NULL},
        };
        sigcmd = {
          .join = false,
          .escape = false,
          .ID = id,
          .tID = _threadid,
          .Join = {NULL},
        };
        HND = NULL;
    };
    BrunchVk::~BrunchVk() {
        log_once("destruct  Brunch Base\n");
        destroySemaphore();
        if (HND != NULL)CloseHandle(HND);
    }
    void BrunchVk::createSemaphore(uint32_t max) {
        signal.Request.BlueLight = CreateSemaphore(NULL, 0, max, (__T("Brunch-signal-Req") + std::to_tstring(signal.tID)).c_str());
        signal.Return.BlueLight = CreateSemaphore(NULL, 0, 1, (__T("Brunch-signal-Ret") + std::to_tstring(signal.tID)).c_str());
    };

    void BrunchVk::destroySemaphore() {
        if (signal.Request.BlueLight != NULL) { CloseHandle(signal.Request.BlueLight); signal.Request.BlueLight = NULL; };
        if (signal.Return.BlueLight != NULL) { CloseHandle(signal.Return.BlueLight); signal.Return.BlueLight = NULL; };
    };

    void BrunchVk::ClearSemaphore() {
        LONG prev;
        while (true) {
            ReleaseSemaphore(signal.Return.RedLight, 0, &prev);
            if (prev > 0) WaitForSingleObject(signal.Return.BlueLight, 0);
            else break;
        };
    };

    void BrunchVk::WaitReturn() {
        WaitForSingleObject(signal.Return.BlueLight, INFINITE);
    };
    void BrunchVk::Release(char c) {

        if (c == 'r') {
            LONG prev;
            ReleaseSemaphore(signal.Return.RedLight, 1, &prev);
        }
        else {
            long idx = InterlockedAdd(&signal.modeID, 1) % MaxSize;
            signal.mode[idx] = c;
            LONG prev;
            ReleaseSemaphore(signal.Request.RedLight, 1, &prev);
            ///log_mut("Realese %d   mode %c    prev  %d\n", idx, c, prev);
            if (prev == MaxSize - 1) {
                log_bad("Semaphore Release Limit Fault. Max %u  \n", MaxSize);
            };
        }

    }


    void BrunchVk::WaitReturnCmd() {
        WaitForSingleObject(sigcmd.Return.BlueLight, INFINITE);
    };
    void BrunchVk::ReleaseCmd(char c) {

        if (c == 'r') {
            LONG prev;
            ReleaseSemaphore(sigcmd.Return.RedLight, 1, &prev);
        }
        else {

        }

    }

    SimplyConnectedPartyVk::~SimplyConnectedPartyVk() {
        destroyFbWithCmdALL();
    };

    void SimplyConnectedPartyVk::createRenderpass(uint32_t flag) {

        PassMode = flag;
        VkAttachmentLoadOp  imLoad;
        VkAttachmentStoreOp  imStore;
        if (flag == OP_CLEAR) {
            imLoad = VK_ATTACHMENT_LOAD_OP_CLEAR;
            imStore = VK_ATTACHMENT_STORE_OP_STORE;
        }
        else {
            imLoad = VK_ATTACHMENT_LOAD_OP_LOAD;
            imStore = VK_ATTACHMENT_STORE_OP_STORE;
        };

        VkAttachmentDescription attachments[2] = {};

        // Color attachment
        attachments[0].format = $format.COLORFORMAT;
        attachments[0].samples = VK_SAMPLE_COUNT_1_BIT;
        // Don't clear the framebuffer (like the renderpass from the example does)
        attachments[0].loadOp = imLoad;
        attachments[0].storeOp = imStore;//   //VK_ATTACHMENT_STORE_OP_STORE;
        attachments[0].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        attachments[0].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        attachments[0].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        attachments[0].finalLayout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

        // Depth attachment
        attachments[1].format = $format.DEPTHFORMAT;
        attachments[1].samples = VK_SAMPLE_COUNT_1_BIT;
        attachments[1].loadOp = imLoad;
        attachments[1].storeOp = imStore;
        attachments[1].stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        attachments[1].stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        attachments[1].initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        attachments[1].finalLayout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

        VkAttachmentReference colorReference = {};
        colorReference.attachment = 0;
        colorReference.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

        VkAttachmentReference depthReference = {};
        depthReference.attachment = 1;
        depthReference.layout = VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;

        // Use subpass dependencies for image layout transitions
        VkSubpassDependency subpassDependencies[2] = {};

        // Transition from final to initial (VK_SUBPASS_EXTERNAL refers to all commmands executed outside of the actual renderpass)
        subpassDependencies[0].srcSubpass = VK_SUBPASS_EXTERNAL;
        subpassDependencies[0].dstSubpass = 0;
        subpassDependencies[0].srcStageMask = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
        subpassDependencies[0].dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        subpassDependencies[0].srcAccessMask = VK_ACCESS_MEMORY_READ_BIT;
        subpassDependencies[0].dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
        subpassDependencies[0].dependencyFlags = VK_DEPENDENCY_BY_REGION_BIT;

        // Transition from initial to final
        subpassDependencies[1].srcSubpass = 0;
        subpassDependencies[1].dstSubpass = VK_SUBPASS_EXTERNAL;
        subpassDependencies[1].srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
        subpassDependencies[1].dstStageMask = VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
        subpassDependencies[1].srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
        subpassDependencies[1].dstAccessMask = VK_ACCESS_MEMORY_READ_BIT;
        subpassDependencies[1].dependencyFlags = VK_DEPENDENCY_BY_REGION_BIT;

        VkSubpassDescription subpassDescription = {};
        subpassDescription.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
        subpassDescription.flags = 0;
        subpassDescription.inputAttachmentCount = 0;
        subpassDescription.pInputAttachments = NULL;
        subpassDescription.colorAttachmentCount = 1;
        subpassDescription.pColorAttachments = &colorReference;
        subpassDescription.pResolveAttachments = NULL;
        subpassDescription.pDepthStencilAttachment = &depthReference;
        subpassDescription.preserveAttachmentCount = 0;
        subpassDescription.pPreserveAttachments = NULL;

        VkRenderPassCreateInfo renderPassInfo = {};
        renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
        renderPassInfo.pNext = NULL;
        renderPassInfo.attachmentCount = 2;
        renderPassInfo.pAttachments = attachments;
        renderPassInfo.subpassCount = 1;
        renderPassInfo.pSubpasses = &subpassDescription;
        renderPassInfo.dependencyCount = 2;
        renderPassInfo.pDependencies = subpassDependencies;

        VK_CHECK_RESULT(vkCreateRenderPass($device, &renderPassInfo, nullptr, &renderPass));

    }
    void SimplyConnectedPartyVk::destroyRenderpass() {

        if (renderPass != VK_NULL_HANDLE) {
            vkDestroyRenderPass($device, renderPass, nullptr);
            renderPass = VK_NULL_HANDLE;
        };
    };

    bool SimplyConnectedPartyVk::_createCommand(VkCommandBuffer cmd[2]) {

        if (cmd[0] != VK_NULL_HANDLE) return true;

        if (whirlpool == VK_NULL_HANDLE) {

            VkCommandPoolCreateInfo cmdPoolInfo = {};
            cmdPoolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
            cmdPoolInfo.queueFamilyIndex = 0;
            cmdPoolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
            VK_CHECK_RESULT(vkCreateCommandPool($device, &cmdPoolInfo, nullptr, &whirlpool));


            VkFenceCreateInfo fenceCreateInfo = vka::plysm::fenceCreateInfo(VK_FENCE_CREATE_SIGNALED_BIT);
            VkSemaphoreCreateInfo semaphoreCI = vka::plysm::semaphoreCreateInfo();

            VK_CHECK_RESULT(vkCreateFence($device, &fenceCreateInfo, nullptr, &fence[0]));
            VK_CHECK_RESULT(vkCreateFence($device, &fenceCreateInfo, nullptr, &fence[1]));
            VK_CHECK_RESULT(vkCreateSemaphore($device, &semaphoreCI, nullptr, &semaphore));

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
    void SimplyConnectedPartyVk::createFbWithCmd(CanvasVk* cvs) {

        cvs->state.passID = (uint32_t)fbcmd.size();
        fbcmd.emplace_back();
        auto& fbSet = fbcmd.back();

        log_br("CreateFbWithCmd    %x   \n", fbSet.cmd[0]);
        ///create framebuffer
        {

            VkFramebuffer& fb = fbSet.frameBuffer;
            std::array<VkImageView, 2> pAttachments;
            pAttachments[0] = cvs->iachCol.vkI;
            pAttachments[1] = cvs->iachDep.vkI;

            VkFramebufferCreateInfo frameBufferCreateInfo = {};
            frameBufferCreateInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
            frameBufferCreateInfo.pNext = NULL;
            frameBufferCreateInfo.renderPass = renderPass;
            frameBufferCreateInfo.attachmentCount = pAttachments.size();
            frameBufferCreateInfo.pAttachments = pAttachments.data();
            frameBufferCreateInfo.width = cvs->w;
            frameBufferCreateInfo.height = cvs->h;
            frameBufferCreateInfo.layers = 1;
            VK_CHECK_RESULT(vkCreateFramebuffer($device, &frameBufferCreateInfo, nullptr, &fb));
        }

        _createCommand(fbSet.cmd);

        ///beginInfomation
        {
            VkRenderPassBeginInfo   renderPassBeginInfo = vka::plysm::renderPassBeginInfo();
            renderPassBeginInfo.renderPass = renderPass;
            renderPassBeginInfo.renderArea.offset.x = 0;
            renderPassBeginInfo.renderArea.offset.y = 0;
            renderPassBeginInfo.renderArea.extent.width = cvs->w;
            renderPassBeginInfo.renderArea.extent.height = cvs->h;
            renderPassBeginInfo.framebuffer = fbSet.frameBuffer;

            if (PassMode == OP_LOAD) {
                renderPassBeginInfo.clearValueCount = 0;
            }
            else {
                fbSet.clearValues[0].color = { { 0.5f, 0.5f, 0.5f, 1.0f } };
                fbSet.clearValues[1].depthStencil = { 1.0f, 0 };
                renderPassBeginInfo.clearValueCount = 2;
                renderPassBeginInfo.pClearValues = fbSet.clearValues;
            }

            fbSet.beginInfo = renderPassBeginInfo;
        }

        return;

    }

    void SimplyConnectedPartyVk::resizeFramebuffer(CanvasVk* cvs) {

        auto& fbSet = fbcmd[cvs->state.passID];
        VkFramebuffer& fb = fbSet.frameBuffer;
        vkDestroyFramebuffer($device, fb, nullptr);

        ///create framebuffer

        std::array<VkImageView, 2> pAttachments;
        pAttachments[0] = cvs->iachCol.vkI;
        pAttachments[1] = cvs->iachDep.vkI;

        VkFramebufferCreateInfo frameBufferCreateInfo = {};
        frameBufferCreateInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
        frameBufferCreateInfo.pNext = NULL;
        frameBufferCreateInfo.renderPass = renderPass;
        frameBufferCreateInfo.attachmentCount = pAttachments.size();
        frameBufferCreateInfo.pAttachments = pAttachments.data();
        frameBufferCreateInfo.width = cvs->w;
        frameBufferCreateInfo.height = cvs->h;
        frameBufferCreateInfo.layers = 1;
        VK_CHECK_RESULT(vkCreateFramebuffer($device, &frameBufferCreateInfo, nullptr, &fb));


        fbSet.beginInfo.renderArea.extent.width = cvs->w;
        fbSet.beginInfo.renderArea.extent.height = cvs->h;
        fbSet.beginInfo.framebuffer = fb;

        log_br("ResizeFramebuffer    %x   [%x  %x] \n", fb, cvs->w, cvs->h);
    };

    void SimplyConnectedPartyVk::destroyFbWithCmd(FbWithCmd& set) {

        if (set.frameBuffer != VK_NULL_HANDLE) {
            vkDestroyFramebuffer($device, set.frameBuffer, nullptr);
            vkFreeCommandBuffers($device, whirlpool, 2, set.cmd);
            set.cmd[0] = set.cmd[1] = VK_NULL_HANDLE;
            set.frameBuffer = VK_NULL_HANDLE;
        }

    };
    void SimplyConnectedPartyVk::destroyFbWithCmdALL() {

        for (auto& v : fbcmd) destroyFbWithCmd(v);

        destroyRenderpass();

        if (semaphore != VK_NULL_HANDLE) {

            vkDestroySemaphore($device, semaphore, nullptr);

            vkDestroyFence($device, fence[0], nullptr);
            vkDestroyFence($device, fence[1], nullptr);

            semaphore = VK_NULL_HANDLE;

        }

        if (whirlpool != VK_NULL_HANDLE) {
            vkDestroyCommandPool($device, whirlpool, nullptr);
            whirlpool = VK_NULL_HANDLE;
        }


    };

    void SimplyConnectedPartyVk::createPipelineCache()
    {
        VkPipelineCacheCreateInfo pipelineCacheCreateInfo = {};
        pipelineCacheCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
        VK_CHECK_RESULT(vkCreatePipelineCache($device, &pipelineCacheCreateInfo, nullptr, &pipelineCache));

    };
    void SimplyConnectedPartyVk::destroyPipelineCache()
    {
        vkDestroyPipelineCache($device, pipelineCache, nullptr);
    };

};


