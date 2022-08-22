#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP

#include "kernel/kernel_globals.h.glsl"

#define RPL_RGEN_IN
#include "kernel/payload.glsl"



void main()
{

isect.t      =  gl_HitTNV;
isect.u      =  (1.0 - attribs.x) - attribs.y;
isect.v      =  attribs.x;
/*
isect.prim   =  int(gl_PrimitiveID + PrimitiveOffset(ObjectID));
isect.object =  gl_InstanceCustomIndexNV;
isect.type   =  int(gl_InstanceID);//int(push.data_ptr._prim_type.data[isect.prim]);
*/

isect.object =  ( gl_InstanceCustomIndexNV & 0x800000 ) | gl_InstanceID;
isect.type   =  gl_InstanceCustomIndexNV & 0x7FFFFF;  // geometry ID
isect.prim   =  int(gl_PrimitiveID + PrimitiveOffset(isect.type));

}
