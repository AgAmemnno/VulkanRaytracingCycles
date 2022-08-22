#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable
#define OMIT_NULL_SC

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

struct KernelData2
{
    KernelCamera cam;
};

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_tri_verts_;
layout(buffer_reference) buffer _prim_tri_index_;
layout(buffer_reference) buffer _objects_;
layout(buffer_reference) buffer _object_flag_;
layout(buffer_reference) buffer _patches_;
layout(buffer_reference) buffer _attributes_map_;
layout(buffer_reference) buffer _attributes_float_;
layout(buffer_reference) buffer _attributes_float2_;
layout(buffer_reference) buffer _attributes_float3_;
layout(buffer_reference) buffer _attributes_uchar4_;
layout(buffer_reference) buffer _tri_vindex_;
layout(buffer_reference) buffer _tri_patch_;
layout(buffer_reference) buffer _tri_patch_uv_;
layout(buffer_reference) buffer _tri_shader_;
layout(buffer_reference) buffer _tri_vnormal_;
layout(buffer_reference) buffer _lights_;
layout(buffer_reference, std430) buffer KernelTextures
{
    _prim_tri_verts_ _prim_tri_verts;
    _prim_tri_index_ _prim_tri_index;
    int64_t pad2[4];
    _objects_ _objects;
    _object_flag_ _object_flag;
    int64_t pad3[1];
    _patches_ _patches;
    _attributes_map_ _attributes_map;
    _attributes_float_ _attributes_float;
    _attributes_float2_ _attributes_float2;
    _attributes_float3_ _attributes_float3;
    _attributes_uchar4_ _attributes_uchar4;
    _tri_shader_ _tri_shader;
    _tri_vnormal_ _tri_vnormal;
    _tri_vindex_ _tri_vindex;
    _tri_patch_ _tri_patch;
    _tri_patch_uv_ _tri_patch_uv;
    int64_t pad5;
    _lights_ _lights;
};

layout(buffer_reference, std430) readonly buffer _prim_tri_verts_
{
    vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _prim_tri_index_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _objects_
{
    KernelObject data[];
};

layout(buffer_reference, std430) readonly buffer _object_flag_
{
    uint data[];
};


layout(buffer_reference, std430) readonly buffer _patches_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_map_
{
    uvec4 data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_float_
{
    float data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_float2_
{
    vec2 data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_float3_
{
    vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_uchar4_
{
    u8vec4 data[];
};
layout(buffer_reference, std430) readonly buffer _tri_shader_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _tri_vnormal_
{
    vec4 data[];
};
layout(buffer_reference, std430) readonly buffer _tri_vindex_
{
    uvec4 data[];
};

layout(buffer_reference, std430) readonly buffer _tri_patch_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _tri_patch_uv_
{
    vec2 data[];
};


layout(buffer_reference, std430) readonly buffer _lights_
{
    KernelLight data[];
};
layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;


#define NODE_Callee

#include "kernel/geom/geom_primitive.h.glsl"
#include "kernel/svm/svm_tex_coord.h.glsl"
#include "kernel/svm/svm_attribute.h.glsl"

void main(){
if(ioSD.call_type == SVM_NODE_TANGENT){
    svm_node_tangent();
}else if(ioSD.call_type == SVM_GEOM_TANGENT){
    primitive_tangent();
}else if(ioSD.call_type == SVM_NODE_ATTR){
   
    svm_node_attr();
}
};