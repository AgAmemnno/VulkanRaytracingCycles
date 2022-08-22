#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_scalar_block_layout  :require
#extension GL_EXT_debug_printf : enable

#define ENABLE_PROFI
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#define SET_KERNEL 2
#define SET_KERNEL_PROF SET_KERNEL
#define SET_TEXTURES 3
//#define SET_SAMPLERS 3
#define PUSH_KERNEL_TEX
#define PUSH_POOL_SC
#include "kernel/kernel_globals.h.glsl"
#define CD_TYPE1_IN sd
#include "kernel/payload.glsl"
#define NODE_Caller
#include "kernel/svm/svm_callable.glsl"
#define PATH_CALLEE
#define  SVM_TYPE_SETUP
#include "kernel/kernel_path.h.glsl"

void main()
{

#ifdef  WITH_STAT_ALL
    setDumpPixel();
#endif

if(sd.num_closure_left < 0){
#ifdef  WITH_STAT_ALL
    rec_num = int(-sd.num_closure_left);
#endif
  kernel_path_shader_apply(sd.randb_closure);
}else{

#ifdef  WITH_STAT_ALL
    rec_num = int(sd.alloc_offset);
#endif
 sd.alloc_offset   = sd.atomic_offset - 1;
 int flag          =  sd.num_closure;
 sd.num_closure    =   0;

 svm_eval_nodes(SHADER_TYPE_SURFACE, flag);
 
}

}