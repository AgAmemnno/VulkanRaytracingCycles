#pragma once
#ifndef   VK_WORKING_MM_H
#define  VK_WORKING_MM_H

#include "config_aeolus.h"


static inline VkDeviceSize alignedSize(VkDeviceSize sz, VkDeviceSize align)
{
	return ((sz + align - 1) / (align)) * align;
};

#include "threepy.h"
#include "threepy_working.h"


namespace front {
	#define   GROUP_MAX 12
	#define   MODE_MAX  128
	template<size_t S> struct ListnerVk;
	struct DeallocatorVk;
	struct oSyncoTank;
};

extern front::DeallocatorVk     des;
extern front::oSyncoTank     otank;


#include "aeolus/vthreepy_const.h"
#include "aeolus/vthreepy_types.h"



#include "aeolus/CacheVk.h"
#include "aeolus/CmdPoolVk.h"
#include "aeolus/WindowVk.h"





#include "aeolus/SignalVk.h"
#include "aeolus/AllocatorVk.h"



#include "aeolus/MemoryVk.h"
#include "aeolus/ObjectVk.h"
#include "aeolus/Context1Vk.h"

#include "aeolus/ScriptorVk.h"



#include "aeolus/ImagesVk.h"
#include "aeolus/AttachmentsVk.h"

#include "aeolus/UniformsVk.h"


#endif