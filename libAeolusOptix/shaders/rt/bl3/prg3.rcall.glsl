#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#define OMIT_NULL_SC
#include "kernel_compat_vulkan.h.glsl"

#include "kernel/payload.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
#extension GL_EXT_debug_printf : enable

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _svm_nodes_;
layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[23];
    _svm_nodes_ _svm_nodes;
};
layout(buffer_reference, std430) readonly buffer _svm_nodes_
{
    uvec4 data[];
};
layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;


#define NODE_Callee_NOISE
#define NODE_Callee 

#include "util/util_hash.h.glsl"
#include "kernel/svm/_svm.h.glsl"
#include "kernel/svm/svm_noisetex.h.glsl"
#include "kernel/svm/svm_wave.h.glsl"
#include "kernel/svm/svm_white_noise.h.glsl"



void main(){

    if(nio.type == CALLEE_SVM_TEX_NOISE)
    svm_node_tex_noise();
    else if (nio.type == CALLEE_SVM_TEX_WAVE)
    svm_node_tex_wave();
    else if (nio.type == CALLEE_SVM_TEX_WHITE_NOISE)
    svm_node_tex_white_noise();
};
