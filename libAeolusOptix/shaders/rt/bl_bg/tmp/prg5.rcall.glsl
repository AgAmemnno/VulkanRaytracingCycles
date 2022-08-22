#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require
//#define SET_KERNEL 2
//#define PUSH_KERNEL_TEX
//#define  PUSH_KERNEL_TEX
#define OMIT_NULL_SC
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

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


#define NODE_Callee
struct NodeIO{
    int  offset;
    uint type;
    float data[62];
};

layout(location = 2) callableDataInNV NodeIO nio;

#include "util/util_hash.h.glsl"
#include "kernel/svm/svm_util.h.glsl"
#include "kernel/svm/svm_noisetex.h.glsl"
#include "kernel/svm/svm_wave.h.glsl"





void main(){

    if(nio.type == CALLEE_SVM_TEX_NOISE)
    svm_node_tex_noise();
    else if (nio.type == CALLEE_SVM_TEX_WAVE)
    svm_node_tex_wave();

};
