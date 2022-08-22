#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable


#define SET_KERNEL 2
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"

#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"
struct hitPayload
{
    float3 throughput;
    PathRadiance L;
    PathState state;
    ShaderDataTinyStorage sd;

};
layout(location = 0) rayPayloadInNV hitPayload prd;
void main(){

       prd.L.use_light_pass = 1234;
       prd.throughput = vec4( 0., 1.f , 0.f ,1.f );//clearColor.xyz * 0.8;


}

