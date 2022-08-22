#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable


#define ENABLE_PROFI



#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"


#define PUSH_POOL_SC
#define PUSH_KERNEL_TEX
#define SET_KERNEL 2
#define SET_KERNEL_PROF SET_KERNEL
#include "kernel/kernel_globals.h.glsl"

#define CD_TYPE01_IN 
#define CD_TYPE01_0 arg
#define CD_TYPE01_1 arg2

#include "kernel/payload.glsl"

#include "util/util_math_func.glsl"
#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_montecarlo.h.glsl"

#include "kernel/_kernel_shader.h.glsl"


void main(){
    
#ifdef  WITH_STAT_ALL
    setDumpPixel();
#endif

if(BSDF_CALL_TYPE_EVAL == int(arg.type) ){
#ifdef WITH_STAT_ALL
rec_num = ply_rec_num;
#endif
   int state_flag = ply_state_flag;
   PLYMO.eval.diffuse = vec4(0.);
 
   shader_bsdf_eval();

}else if(BSDF_CALL_TYPE_SAMPLE == int(arg.type) ){

#ifdef ENABLE_PROFI
PROFI_IDX =  int(PLYMO_Eval_profi_idx);
PLYMO_Eval_profi_idx = 0.f;
#endif
#ifdef WITH_STAT_ALL
rec_num = int(PLYMO_Eval_rec_num);
PLYMO_Eval_rec_num = 0.f;
#endif
   float bsdf_u = ply_rng_u;
   float bsdf_v = ply_rng_v;
   float3 omega_in;
   differential3 domega_in;
   float pdf = 0.f;
   arg.label     = shader_bsdf_sample(bsdf_u, bsdf_v,omega_in,domega_in,pdf);
   arg.omega_in  = omega_in;
   arg.domega_in = domega_in;
   arg.pdf = pdf;

}


}
