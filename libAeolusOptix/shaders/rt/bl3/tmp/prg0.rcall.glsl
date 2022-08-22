#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable

#include "kernel_compat_vulkan.h.glsl"
#define ENABLE_PROFI
#include "kernel/_kernel_types.h.glsl"


#define PUSH_POOL_SC
#define PUSH_KERNEL_TEX
#define SET_KERNEL 2
#define SET_KERNEL_PROF SET_KERNEL
#include "kernel/kernel_globals.h.glsl"
#define CD_TYPE0_IN  pay
#define CD_TYPE1_OUT sd
#include "kernel/payload.glsl"
#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_differential.h.glsl"
#include "kernel/closure/emissive.h.glsl"

#include "kernel/geom/geom_attribute.h.glsl"
#include "kernel/geom/geom_object.h.glsl"
#include "kernel/geom/geom_triangle.h.glsl"
#include "kernel/geom/geom_triangle_intersect.h.glsl"
#include "kernel/geom/geom_motion_triangle.h.glsl"
#include "kernel/kernel_light_common.h.glsl"
#include "kernel/kernel_light_background.h.glsl"
#include "kernel/kernel_light.h.glsl"

#define  LCG_NO_USE
#include "kernel/_kernel_shader.h.glsl"
#include "kernel/kernel_accumulate.h.glsl"
#include "kernel/kernel_path_state.h.glsl"
#include "kernel/kernel_emission.h.glsl"
#include "kernel/kernel_path_surface.h.glsl"


void main(){
   
#ifdef  WITH_STAT_ALL
    setDumpPixel();
    rec_num = int(ply_L2Eval_rec_num);
    ply_L2Eval_rec_num = 0.f;
#endif


#ifdef ENABLE_PROFI
PROFI_IDX =  int(ply_L2Eval_profi_idx);
ply_L2Eval_profi_idx  = 0.f;
#endif

if(GARG.type ==  SURFACE_CALL_TYPE_indirect_lamp){
   indirect_lamp_emission();



}else if(GARG.type ==  SURFACE_CALL_TYPE_connect_light){
   kernel_branched_path_surface_connect_light( );
}

};
