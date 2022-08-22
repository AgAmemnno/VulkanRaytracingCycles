#version 460
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable

#define OMIT_NULL_SC
#define FLOAT3_AS_VEC3
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

#include "kernel/payload.glsl"



#define NODE_Callee_Utils
#define NODE_Callee
#include "kernel/svm/svm_callable.glsl"
#include "kernel/svm/svm_color_util.h.glsl"



void main(){
  switch (nio.type) {
    case CALLEE_UTILS_MIX:
     nio.c1 = svm_mix(UTILS_NODE_MIX_TYPE, nio.fac, nio.c1, nio.c2);
     break;
    case CALLEE_UTILS_BRI:
     nio.c1 =  svm_brightness_contrast(nio.c1, nio.fac, nio.c2.x);
     break;
    default:
    break;
  }  
}