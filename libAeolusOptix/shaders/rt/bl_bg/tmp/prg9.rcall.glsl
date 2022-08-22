#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable

#define OMIT_NULL_SC
#define SET_KERNEL 2
#define SET_TEXTURES 3
#define PUSH_KERNEL_TEX
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"


#define NODE_Callee
#include "kernel/svm/svm_callable.glsl"
#include "kernel/svm/svm_sky.h.glsl"
#include "kernel/svm/svm_image.h.glsl"
void main(){

    if(nio.type ==  CALLEE_SVM_TEX_SKY)
    svm_node_tex_sky();
    else if(nio.type ==  CALLEE_SVM_TEX_ENV)
    svm_node_tex_environment();
    
};
