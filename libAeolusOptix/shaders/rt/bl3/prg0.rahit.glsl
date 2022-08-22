#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"
#define RPL_RGEN_AHIT_IN
#include "kernel/payload.glsl"


///__anyhit__kernel_optix_visibility_test()
void main()
{
  
#ifdef _VISIBILITY_FLAG_
  const uint prim = gl_PrimitiveID + PrimitiveOffset(ObjectID);
  if ((kernel_tex_fetch(_prim_visibility, prim) & visibility) == 0) {
    ignoreIntersectionNV();
  }
#endif

#ifdef _HAIR_
  if (!optixIsTriangleHit()) {
    // Filter out curve endcaps
    const float u = __uint_as_float(optixGetAttribute_0());
    if (u == 0.0f || u == 1.0f) {
       ignoreIntersectionNV();
      
    }
  }
#endif

  // Shadow ray early termination
  if (bool(visibility & PATH_RAY_SHADOW_OPAQUE)) {
    terminateRayNV();
  }


}
