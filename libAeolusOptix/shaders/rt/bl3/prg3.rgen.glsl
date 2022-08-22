#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_NV_shader_sm_builtins: enable
#extension GL_KHR_shader_subgroup_basic : enable
#extension GL_EXT_buffer_reference : require
#include "kernel_compat_vulkan.h.glsl"
#define ENABLE_PROFI
#include "kernel/_kernel_types.h.glsl"
#define TEST_MODE 
#define SET_AS 0
#define SET_WRITE_PASSES
#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#define PUSH_POOL_SC
#define PUSH_POOL_IS
#include "kernel/kernel_globals.h.glsl"


#define kernel_tex_fetch_vindex(t,i) uvec3( kernel_tex_fetch(t,3*i), kernel_tex_fetch(t,3*i + 1) ,kernel_tex_fetch(t,3*i + 2 ))

ShaderData sd;
#define GSD sd
#include "kernel/payload.glsl"
#include "kernel/geom/geom_triangle.h.glsl"

void main()
{  
   triangle_normal();
 //uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2,0);
 //uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GSD.prim)
 uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2,0);
 debugPrintfEXT(" %v3u \n",tri_vindex); 

}
