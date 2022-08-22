#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"

#define PUSH_POOL_IS
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"
#define  SHADOW_CALLEE2
#include "kernel/payload.glsl"
hitAttributeNV vec2 attribs;
uint ISidx;


//#include "kernel/_kernel_shader.h.glsl"
#ifdef _TRANSPARENT_SHADOWS_
ccl_device bool shader_transparent_shadow()
{
  int prim = int(kernel_tex_fetch(_prim_index,IS(ISidx).prim));
  int shader = 0;

#  ifdef _HAIR_
  if (bool(isect.type & PRIMITIVE_ALL_TRIANGLE)) {

#  endif
    shader = int(kernel_tex_fetch(_tri_shader, prim));
#  ifdef _HAIR_
  }
  else {
    float4 str = kernel_tex_fetch(_curves, prim);
    shader = _float_as_int(str.z);
  }
#  endif
  int flag = kernel_tex_fetch(_shaders, (shader & SHADER_MASK)).flags;

  return bool(flag & SD_HAS_TRANSPARENT_SHADOW) != 0;
}
#endif /* _TRANSPARENT_SHADOWS_ */


// __anyhit__kernel_optix_shadow_all_hit()
void main()
{


#ifdef _SHADOW_RECORD_ALL_
  const uint prim = gl_PrimitiveID + gl_InstanceCustomIndexNV;
#  ifdef _VISIBILITY_FLAG_
  const uint visibility = iinfo.visibility;
  if ((kernel_tex_fetch(_prim_visibility, prim) & visibility) == 0) {
    ignoreIntersectionNV();
  }
#  endif

  // Offset into array with num_hits  need  global  allocate
  //Intersection *const isect = get_payload_ptr_0<Intersection>() + optixGetPayload_2();

  uint num    = atomicAdd(iinfo.numhits,1u);
  uint ISidx  = iinfo.offset + num;
  IS(ISidx).t       = gl_HitTNV;//gl_RayTmaxNV;//   optixGetRayTmax();
  IS(ISidx).prim    = prim;
  IS(ISidx).object  = gl_InstanceID;//get_object_id();
  IS(ISidx).type    = kernel_tex_fetch(_prim_type, prim);

  // if(  gl_HitKindNV ==  isTriangleHit )
  IS(ISidx).u       = 1.0f - attribs.y - attribs.x;
  IS(ISidx).v       = attribs.x;
  //}

#  ifdef _HAIR_
  else {
    const float u = __uint_as_float(optixGetAttribute_0());
    isect->u = u;
    isect->v = __uint_as_float(optixGetAttribute_1());

    // Filter out curve endcaps
    if (u == 0.0f || u == 1.0f) {
      return optixIgnoreIntersection();
    }
  }
#  endif

#  ifdef _TRANSPARENT_SHADOWS_
  // Detect if this surface has a shader with transparent shadows
  if (!shader_transparent_shadow() || num >= (iinfo.maxhits-1) ){
#  endif
    // This is an opaque hit or the hit limit has been reached, abort traversal
    iinfo.terminate = 1;
    terminateRayNV();
#  ifdef _TRANSPARENT_SHADOWS_
  }


  // Continue tracing
  ignoreIntersectionNV();
#  endif
#endif
}
