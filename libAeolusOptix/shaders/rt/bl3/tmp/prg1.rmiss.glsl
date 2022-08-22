#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"

#define SHADOW_CALLEE2
#include "kernel/payload.glsl"


void main(){

//iinfo.numhits = 0;
//iinfo.terminate = 0;

}

