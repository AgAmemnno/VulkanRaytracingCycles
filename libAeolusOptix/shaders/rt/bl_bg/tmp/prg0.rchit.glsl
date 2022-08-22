#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#define PUSH_KERNEL_TEX
#define SET_KERNEL 2

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

//layout(location = 1) rayPayloadInNV bool isMiss;
layout(location = 1) rayPayloadInNV Intersection isect;
hitAttributeNV vec2 attribs;

void main()
{

isect.t      =  gl_HitTNV;
isect.u      = (1.0 - attribs.x) - attribs.y;
isect.v      = attribs.x;
isect.prim   = gl_PrimitiveID;
isect.object = 0;
isect.type   = int(push.data_ptr._prim_type.data[gl_PrimitiveID]);

}
