#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable
#define RMISS_BG

#include "kernel_compat_vulkan.h.glsl"
#define ENABLE_PROFI
#include "kernel/_kernel_types.h.glsl"
#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

#define RPL_TYPE_RGEN_IN
#define CD_TYPE0_OUT arg
#define CD_TYPE1_OUT sd
#include "kernel/payload.glsl"

#include "kernel/kernel_differential.h.glsl"
#include "kernel/kernel_random.h.glsl"
#include "kernel/closure/emissive.h.glsl"
#include "kernel/_kernel_shader.h.glsl"
#include "kernel/kernel_light_background.h.glsl"
#include "kernel/kernel_path_state.h.glsl"
#define PATH_CALLER
#include "kernel/kernel_indirect_background.h.glsl"
#include "kernel/kernel_accumulate.h.glsl"
#include "kernel/kernel_path.h.glsl"
int rec = 0;





void main(){

arg.state  = prd.state;
Intersection isect;
Ray ray;
ray.P = PLYMO_RPL0_IN_ray_P;//vec4(gl_WorldRayOriginNV, 0.0);
ray.D = PLYMO_RPL0_IN_ray_D;//vec4(gl_WorldRayDirectionNV, 0.0);
ray.t = FLT_MAX;
getARG_RGEN(ray);
prd.throughput.z = 1.;
prd.throughput.x = 1.;
isect.t      = FLT_MAX;
isect.prim   = -1;
isect.object = -1;
isect.type   =  1;

kernel_path_lamp_emission(ray,isect);
kernel_path_background(ray);


    //   prd.L.use_light_pass = 1234;
    //   prd.throughput =  make_float3(0.1f, 0.1f, 0.1f);//indirect_background();
}

