#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable


#define SET_KERNEL 2
#define PUSH_KERNEL_TEX

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"


#include "kernel/kernel_globals.h.glsl"
struct hitPayload
{
    float3 throughput;
    PathRadiance L;
    PathState state;
    ShaderData emission_sd;
    
};
struct args_bsdf
{
int label;
ShaderClosure bsdf;
vec4 Ng;
vec4 I;
vec4 dIdx;
vec4 dIdy;
float randu;
float randv;
vec4 eval;
vec4 omega_in;
differential3 domega;
float pdf;
};

layout(location = 0) rayPayloadInNV hitPayload prd;
layout(location = 0) callableDataNV ShaderData sd;
layout(location = 1) callableDataNV args_bsdf args;


void main()
{
   prd.throughput = vec4(1.f);
}
