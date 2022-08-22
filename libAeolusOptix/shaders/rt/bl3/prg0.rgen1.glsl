#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_NV_shader_sm_builtins: enable
#extension GL_KHR_shader_subgroup_basic : enable

#include "kernel_compat_vulkan.h.glsl"
#define ENABLE_PROFI
#include "kernel/_kernel_types.h.glsl"
#define TEST_MODE 
#define SET_KERNEL 2
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

layout(location = 1) callableDataNV ShaderData sd;

void main()
{  

#ifdef ENABLE_PROFI
  PROFI_IDX  = 12345;
  //PROFI_HIT_IDX(gl_LaunchIDNV.x,gl_LaunchIDNV.y,arg.state.rng_hash, float(gl_PrimitiveID) );
#endif

          sd.num_closure_left = 123;
          executeCallableNV(2u,1);
          atomicAdd(counter[PROFI_ATOMIC-2],1);

}
