#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#define RPL_RGEN_IN
#define RPL_MISS
#include "kernel/payload.glsl"


void main(){

isect.t      = FLT_MAX;
isect.prim   = -1;
isect.object = -1;
isect.type   = int(PRIMITIVE_NONE);
}

