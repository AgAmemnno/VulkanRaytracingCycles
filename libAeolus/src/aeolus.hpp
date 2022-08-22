#pragma once
#ifndef AEOLUS_HPP
#define AEOLUS_HPP

#include "types.hpp"

#ifdef  LOG_NO_MAIN
#define log_main(...)
#else
#define log_main(...) log_out(__FILE__, __LINE__, LOG_CPP, __VA_ARGS__)
#endif



#ifdef  LOG_NO_file
#define log_file(...)
bool FilePrintOn = false;
#else
bool FilePrintOn = true;
#define log_file(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

/*
#include "core/Canvas.h"
#include "core/topics.h"
*/

#include "working.h"


bool                                   LivePrintOff = false;
#define $LivePrintOff      LivePrintOff
VkInstance                          __instance;
VkPhysicalDevice                 __physicaldevice;
VkDevice                              __device;
VkQueue                              __queue;
queueFamilyIndices __queueFamilyIndices;
_Vkformat __format;
VkPhysicalDeviceProperties __properties;
VkPhysicalDeviceFeatures __features;
VkPhysicalDeviceMemoryProperties __memoryProperties;

ContextVk* __ctx__ = nullptr;
vkmm::Allocator      __vkmmallocator = nullptr;
///extern template struct front::HashedBeef<HB_DEFUALT>;

front::DeallocatorVk     des;
front::oSyncoTank     otank;

///front::HashedBeef<HB_DEFUALT> hb;
front::Schedule         sch;
front::CriticalHole     hole;



vkDSLMem DSL;
vkPVISciMem VInfo;
MemStatic(MBvk, SIZE_MB);
MemStatic(MIBvk, SIZE_MIB);
MemStatic(MIBmvk, SIZE_MIBm);

MemStatic(MIVSIvk, SIZE_MIVSI);
MemStatic(MIVvk, SIZE_MIV);



MemStatic(Mvk, SIZE_MDev);
MemStatic(IBmvk, SIZE_IBmDev);
MemStatic(Mvk, SIZE_MVis);
MemStatic(IBmvk, SIZE_IBmVis);

MemStatic(PvSvk, SIZE_PvS);


#define CahceClear {\
MemClear(MBvk, SIZE_MB);\
MemClear(MIBvk, SIZE_MIB);\
MemClear(MIBmvk, SIZE_MIBm);\
MemClear(MIVSIvk, SIZE_MIVSI);\
MemClear(MIVvk, SIZE_MIV);\
MemClear(Mvk, SIZE_MDev);\
MemClear(IBmvk, SIZE_IBmDev);\
MemClear(Mvk, SIZE_MVis);\
MemClear(IBmvk, SIZE_IBmVis);\
MemClear(PvSvk, SIZE_PvS);\
}
Temperance Tempera;
VkAllocationCallbacks  Callback_vkAllocateMemory;
namespace types {
       size_t  LOG_CAPACITY = 512;
};





#endif