#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable

#pragma use_vulkan_memory_model

#include "kernel_compat_vulkan.h.glsl"
#define ENABLE_PROFI 
#include "kernel/_kernel_types.h.glsl"
#define LHIT_CALLEE
#include "kernel/payload.glsl"
hitAttributeNV vec2 attribs;
/*
  uint p0 = ((uint64_t)lcg_state) & 0xFFFFFFFF;
  uint p1 = (((uint64_t)lcg_state) >> 32) & 0xFFFFFFFF;
  uint p2 = ((uint64_t)local_isect) & 0xFFFFFFFF;
  uint p3 = (((uint64_t)local_isect) >> 32) & 0xFFFFFFFF;
  uint p4 = local_object;
  // Is set to zero on miss or if ray is aborted, so can be used as return value
  uint p5 = max_hits;
*/

// Can just remove the high bit since instance always contains object ID
// object & 0x7FFFFF [ enumerational ID]


ccl_device uint lcg_step_uint(inout uint rng)
{
  /* implicit mod 2^32 */
  rng = (1103515245U * (rng) + 12345U);
  return rng;
}

void main()
{

#ifdef _BVH_LOCAL_

  const uint object = GET_OBJECTID;
  if (object != uint(linfo.local_object)) {
    // Only intersect with matching object
    ignoreIntersectionNV();
  }

  int hit = 0;

  uint lcg_state = linfo.lcg_state; //get_payload_ptr_0<uint>();
  //LocalIntersection *const local_isect = get_payload_ptr_2<LocalIntersection>();
  uint ISidx     = linfo.offset;

  if (isValid_lcg_state(lcg_state)) {
    uint max_hits = uint(linfo.max_hits);
    for (int i = int(min(max_hits, linfo.num_hits)) -1; i >= 0; --i) {
      if (gl_HitTNV ==  IS((ISidx+i)).t) {
        ignoreIntersectionNV();
      }
    }

    hit = linfo.num_hits++;

    if (linfo.num_hits > max_hits) {
      hit = int(lcg_step_uint(lcg_state) % linfo.num_hits);
      if (hit >= max_hits) {
        ignoreIntersectionNV();
      }
    }
  }
  else {
    if ( bool(linfo.num_hits) && gl_HitTNV > IS(ISidx).t) {
      // Record closest intersection only
      // Do not terminate ray here, since there is no guarantee about distance ordering in any-hit
      ignoreIntersectionNV();
    }
    linfo.num_hits = 1;
  }

  ISidx  += hit;

  IS(ISidx).t        = gl_HitTNV;
  IS(ISidx).object   =  ( gl_InstanceCustomIndexNV & 0x800000 ) | gl_InstanceID;
  IS(ISidx).prim     =  int(gl_PrimitiveID + PrimitiveOffset(ObjectID));
  IS(ISidx).type     =  gl_InstanceCustomIndexNV & 0x7FFFFF; 
  IS(ISidx).u        = 1.0f - attribs.y - attribs.x;
  IS(ISidx).v        = attribs.x;

  /* Record geometric normal
  const uint tri_vindex = kernel_tex_fetch(__prim_tri_index, isect->prim);
  const float3 tri_a    = float4_to_float3(kernel_tex_fetch(__prim_tri_verts, tri_vindex + 0));
  const float3 tri_b    = float4_to_float3(kernel_tex_fetch(__prim_tri_verts, tri_vindex + 1));
  const float3 tri_c    =  float4_to_float3(kernel_tex_fetch(__prim_tri_verts, tri_vindex + 2));
  local_isect->Ng[hit]  = normalize(cross(tri_b - tri_a, tri_c - tri_a));
  */
  // Continue tracing (without this the trace call would return after the first hit)
  ignoreIntersectionNV();

#endif

}

