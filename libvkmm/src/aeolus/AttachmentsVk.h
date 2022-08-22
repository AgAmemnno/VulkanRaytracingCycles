#pragma once

#ifndef AttachmentVK_H
#define AttachmentVK_H
#include "pch_mm.h"


#ifdef  LOG_NO_ata
#define log_ata(...)
#else
#define log_ata(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

struct AttachmentsVk {

	uint32_t w, h;
    uint32_t multiview = 2;
	uint32_t multisample;

    MIVSIvk color;

    AttachmentsVk(uint32_t w, uint32_t h, uint32_t multisample);
    
    bool destroy();

    union {
        struct {
            MIVvk colorMS, depthMS, stencilMS;
            MIVvk depth, stencil;
        };
        struct {
            MIVvk member[5];
        };
    };
   
    void createMultiViewColorDepthWithResolution();

};


#endif