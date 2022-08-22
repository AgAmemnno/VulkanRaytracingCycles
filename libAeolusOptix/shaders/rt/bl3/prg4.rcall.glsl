#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable

#define OMIT_NULL_SC
//#define PUSH_KERNEL_TEX
#include "kernel_compat_vulkan.h.glsl"

#include "kernel/payload.glsl"

#include "kernel/_kernel_types.h.glsl"

#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

#define NODE_Callee_VORONOI
#define NODE_Callee
#include "util/util_hash.h.glsl"
#include "kernel/svm/svm_voronoi.h.glsl"

void main(){
   
    svm_node_tex_voronoi();
};
