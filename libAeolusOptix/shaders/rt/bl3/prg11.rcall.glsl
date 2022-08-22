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

#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _sample_pattern_lut_;
layout(buffer_reference, std430) buffer KernelTextures
{
  int64_t pad[28];
  _sample_pattern_lut_ _sample_pattern_lut;
};
layout(buffer_reference, std430) readonly buffer _sample_pattern_lut_
{
    uint data[];
};
layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;


#define RNG_Callee
#define CALL_RNG
struct ARG_RNG{
   uint rng_hash;
   int sample_rsv;
   int num_samples;
   int dimension;
   uint type;
   int sampling;
   uint x,y;
   int  seed;
};
layout(location = 2) callableDataInNV ARG_RNG arg;
#include "kernel/kernel_random.h.glsl"

void main(){


  switch (arg.type) {
    case CALLEE_UTILS_RNG_1D:
     RNG_RET1(path_rng_1D(arg.rng_hash));
    break;
    case CALLEE_UTILS_RNG_2D:
     path_rng_2D(arg.rng_hash);
    break;
    case CALLEE_UTILS_RNG_INIT:
     path_rng_init(arg.rng_hash);
    break;
    default:
    break;
  }  



}