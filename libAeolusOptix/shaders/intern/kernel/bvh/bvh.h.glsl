/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* BVH
 *
 * Bounding volume hierarchy for ray tracing. We compile different variations
 * of the same BVH traversal function for faster rendering when some types of
 * primitives are not needed, using #includes to work around the lack of
 * C++ templates in OpenCL.
 *
 * Originally based on "Understanding the Efficiency of Ray Traversal on GPUs",
 * the code has been extended and modified to support more primitives and work
 * with CPU/CUDA/OpenCL. */

#ifdef _EMBREE_
#  include "kernel/bvh/bvh_embree.h"
#endif

CCL_NAMESPACE_BEGIN

#include "kernel/bvh/bvh_types.h.glsl"

#ifndef _KERNEL_OPTIX_

/* Regular BVH traversal */

#  include "kernel/bvh/bvh_nodes.h.glsl"

/* Regular BVH traversal */
#  if defined(_HAIR_) && defined(_OBJECT_MOTION_)
#    define BVH_FUNCTION_NAME bvh_intersect_hair_motion
#    define BVH_FUNCTION_FEATURES BVH_HAIR | BVH_MOTION
#    include "kernel/bvh/bvh_traversal.h.glsl"
#  elif defined(_OBJECT_MOTION_)
#    define BVH_FUNCTION_NAME bvh_intersect_motion
#    define BVH_FUNCTION_FEATURES BVH_MOTION
#    include "kernel/bvh/bvh_traversal.h.glsl"
#  elif defined(_HAIR_)
#    define BVH_FUNCTION_NAME bvh_intersect_hair
#    define BVH_FUNCTION_FEATURES BVH_HAIR
#    include "kernel/bvh/bvh_traversal.h.glsl"
#  else
#  define BVH_FUNCTION_NAME bvh_intersect
#  define BVH_FUNCTION_FEATURES 0
#  include "kernel/bvh/bvh_traversal.h.glsl"
#  endif



/* Subsurface scattering BVH traversal */

#  if defined(_BVH_LOCAL_)
#    if defined(_OBJECT_MOTION_)
#      define BVH_FUNCTION_NAME bvh_intersect_local_motion
#      define BVH_FUNCTION_FEATURES BVH_MOTION | BVH_HAIR
#      include "kernel/bvh/bvh_local.h.glsl"
#    else
#      define BVH_FUNCTION_NAME bvh_intersect_local
#      define BVH_FUNCTION_FEATURES BVH_HAIR
#      include "kernel/bvh/bvh_local.h.glsl"
#    endif

#  endif /* _BVH_LOCAL_ */

/* Volume BVH traversal */

#  if defined(_VOLUME_)
#    define BVH_FUNCTION_NAME bvh_intersect_volume
#    define BVH_FUNCTION_FEATURES BVH_HAIR
#    include "kernel/bvh/bvh_volume.h"

#    if defined(_OBJECT_MOTION_)
#      define BVH_FUNCTION_NAME bvh_intersect_volume_motion
#      define BVH_FUNCTION_FEATURES BVH_MOTION | BVH_HAIR
#      include "kernel/bvh/bvh_volume.h"
#    endif
#  endif /* _VOLUME_ */

/* Record all intersections - Shadow BVH traversal */

#  if defined(_SHADOW_RECORD_ALL_)
#    define BVH_FUNCTION_NAME bvh_intersect_shadow_all
#    define BVH_FUNCTION_FEATURES 0
#    include "kernel/bvh/bvh_shadow_all.h"

#    if defined(_HAIR_)
#      define BVH_FUNCTION_NAME bvh_intersect_shadow_all_hair
#      define BVH_FUNCTION_FEATURES BVH_HAIR
#      include "kernel/bvh/bvh_shadow_all.h"
#    endif

#    if defined(_OBJECT_MOTION_)
#      define BVH_FUNCTION_NAME bvh_intersect_shadow_all_motion
#      define BVH_FUNCTION_FEATURES BVH_MOTION
#      include "kernel/bvh/bvh_shadow_all.h"
#    endif

#    if defined(_HAIR_) && defined(_OBJECT_MOTION_)
#      define BVH_FUNCTION_NAME bvh_intersect_shadow_all_hair_motion
#      define BVH_FUNCTION_FEATURES BVH_HAIR | BVH_MOTION
#      include "kernel/bvh/bvh_shadow_all.h"
#    endif
#  endif /* _SHADOW_RECORD_ALL_ */

/* Record all intersections - Volume BVH traversal  */

#  if defined(_VOLUME_RECORD_ALL_)
#    define BVH_FUNCTION_NAME bvh_intersect_volume_all
#    define BVH_FUNCTION_FEATURES BVH_HAIR
#    include "kernel/bvh/bvh_volume_all.h"

#    if defined(_OBJECT_MOTION_)
#      define BVH_FUNCTION_NAME bvh_intersect_volume_all_motion
#      define BVH_FUNCTION_FEATURES BVH_MOTION | BVH_HAIR
#      include "kernel/bvh/bvh_volume_all.h"
#    endif
#  endif /* _VOLUME_RECORD_ALL_ */

#  undef BVH_FEATURE
#  undef BVH_NAME_JOIN
#  undef BVH_NAME_EVAL
#  undef BVH_FUNCTION_FULL_NAME

#endif /* _KERNEL_OPTIX_ */

ccl_device_inline bool scene_intersect_valid(in Ray ray)
{
  /* NOTE: Due to some vectorization code  non-finite origin point might
   * cause lots of false-positive intersections which will overflow traversal
   * stack.
   * This code is a quick way to perform early output, to avoid crashes in
   * such cases.
   * From production scenes so far it seems it's enough to test first element
   * only.
   * Scene intersection may also called with empty rays for conditional trace
   * calls that evaluate to false, so filter those out.
   */
  return isfinite_safe(ray.P.x) && isfinite_safe(ray.D.x) && len_squared(ray.D) != 0.0f;
}

ccl_device_intersect bool scene_intersect(inout KernelGlobals kg,
                                          in Ray ray,
                                          const uint visibility,
                                          inout Intersection isect)
{
  PROFILING_INIT(kg, PROFILING_INTERSECT);

#ifdef _KERNEL_OPTIX_
  uint p0 = 0;
  uint p1 = 0;
  uint p2 = 0;
  uint p3 = 0;
  uint p4 = visibility;
  uint p5 = PRIMITIVE_NONE;

  optixTrace(scene_intersect_valid(ray) ? kernel_data.bvh.scene : 0,
             ray.P,
             ray.D,
             0.0f,
             ray.t,
             ray.time,
             0xF,
             OPTIX_RAY_FLAG_NONE,
             0,  // SBT offset for PG_HITD
             0,
             0,
             p0,
             p1,
             p2,
             p3,
             p4,
             p5);

  isect.t = _uint_as_float(p0);
  isect.u = _uint_as_float(p1);
  isect.v = _uint_as_float(p2);
  isect.prim = p3;
  isect.object = p4;
  isect.type = p5;

  return p5 != PRIMITIVE_NONE;
#else /* _KERNEL_OPTIX_ */
  if (!scene_intersect_valid(ray)) {
    return false;
  }

#  ifdef _EMBREE_
  if (kernel_data.bvh.scene) {
    isect.t = ray.t;
    CCLIntersectContext ctx(kg, CCLIntersectContext::RAY_REGULAR);
    IntersectContext rtc_ctx(&ctx);
    RTCRayHit ray_hit;
    kernel_embree_setup_rayhit(*ray, ray_hit, visibility);
    rtcIntersect1(kernel_data.bvh.scene, &rtc_ctx.context, &ray_hit);
    if (ray_hit.hit.geomID != RTC_INVALID_GEOMETRY_ID &&
        ray_hit.hit.primID != RTC_INVALID_GEOMETRY_ID) {
      kernel_embree_convert_hit(kg, &ray_hit.ray, &ray_hit.hit, isect);
      return true;
    }
    return false;
  }
#  endif /* _EMBREE_ */

#  ifdef _OBJECT_MOTION_
  if (bool(kernel_data.bvh.have_motion) ){
#    ifdef _HAIR_
    if (bool(kernel_data.bvh.have_curves)) {
      return false;
      //TODO return bvh_intersect_hair_motion(kg, ray, isect, visibility);
    }
#    endif /* _HAIR_ */

    return false;
    //TODO return bvh_intersect_motion(kg, ray, isect, visibility);
  }
#  endif   /* _OBJECT_MOTION_ */

#  ifdef _HAIR_
  if( bool(kernel_data.bvh.have_curves) ){
    return false;
    //TODO return bvh_intersect_hair(kg, ray, isect, visibility);
  }
#  endif /* _HAIR_ */
  // return false;
  return bvh_intersect(kg, ray, isect, visibility);

#endif   /* _KERNEL_OPTIX_ */
}

#define _BVH_LOCAL_

#ifdef _BVH_LOCAL_
#define NULL_LCG uint(-1)
ccl_device_intersect bool scene_intersect_local(
                                                int local_object,
                                                inout uint lcg_state,/* buffer ref */
                                                int max_hits)
{

  PROFILING_INIT(kg, PROFILING_INTERSECT_LOCAL);
  PLYMO_LISECT_offset(GSD.atomic_offset);
  PLYMO_LISECT_lcg_state(lcg_state);
  PLYMO_LISECT_maxhits(max_hits);
  PLYMO_LISECT_local_object(local_object);
  
  PLYMO_LISECT_numhits(0);
  /// assertion if (local_isect) {local_isect.num_hits = 0;}  // Initialize hit count to zero
  if(scene_intersect_valid(ss_isect.ray)){
    traceNV(
         topLevelAS,      // acceleration structure
         gl_RayFlagsSkipClosestHitShaderNV,        // rayFlags
         0xFF,             // cullMask
         TRACE_TYPE_LHIT,  // sbtRecordOffset
         0,                // sbtRecordStride
         MISS_TYPE_MAIN,   // missIndex
         ss_isect.ray.P.xyz,        // ray origin
          0.f,             // ray min range
         ss_isect.ray.D.xyz,        // ray direction
         ss_isect.ray.t,            // ray max range
         RPL_TYPE_LISECT     // payload location
    );

    PLYMO_LISECT_GET_numhits;
    PLYMO_LISECT_GET_lcg_state(lcg_state);
    return true;
  }
  return false;
}
#endif

#ifdef _SHADOW_RECORD_ALL_
ccl_device_intersect bool scene_intersect_shadow_all(inout KernelGlobals kg,
                                                     in Ray ray,
                                                     inout Intersection isect,
                                                     uint visibility,
                                                     uint max_hits,
                                                     out uint num_hits)
{
  PROFILING_INIT(kg, PROFILING_INTERSECT_SHADOW_ALL);

#  ifdef _KERNEL_OPTIX_
  uint p0 = ((uint64_t)isect) & 0xFFFFFFFF;
  uint p1 = (((uint64_t)isect) >> 32) & 0xFFFFFFFF;
  uint p3 = max_hits;
  uint p4 = visibility;
  uint p5 = false;

  *num_hits = 0;  // Initialize hit count to zero
  optixTrace(scene_intersect_valid(ray) ? kernel_data.bvh.scene : 0,
             ray.P,
             ray.D,
             0.0f,
             ray.t,
             ray.time,
             0xF,
             // Need to always call into _anyhit_kernel_optix_shadow_all_hit
             OPTIX_RAY_FLAG_ENFORCE_ANYHIT,
             1,  // SBT offset for PG_HITS
             0,
             0,
             p0,
             p1,
             *num_hits,
             p3,
             p4,
             p5);

  return p5;
#  else /* _KERNEL_OPTIX_ */
  if (!scene_intersect_valid(ray)) {
    num_hits = 0;
    return false;
  }

#    ifdef _EMBREE_
  if (kernel_data.bvh.scene) {
    CCLIntersectContext ctx(kg, CCLIntersectContext::RAY_SHADOW_ALL);
    ctx.isect_s = isect;
    ctx.max_hits = max_hits;
    ctx.num_hits = 0;
    IntersectContext rtc_ctx(&ctx);
    RTCRay rtc_ray;
    kernel_embree_setup_ray(*ray, rtc_ray, visibility);
    rtcOccluded1(kernel_data.bvh.scene, &rtc_ctx.context, &rtc_ray);

    if (ctx.num_hits > max_hits) {
      return true;
    }
    *num_hits = ctx.num_hits;
    return rtc_ray.tfar == -INFINITY;
  }
#    endif /* _EMBREE_ */

#    ifdef _OBJECT_MOTION_
  if (bool(kernel_data.bvh.have_motion) ){
#      ifdef _HAIR_
    if( bool(kernel_data.bvh.have_curves) ){
      return false;
      //TODO return bvh_intersect_shadow_all_hair_motion(kg, ray, isect, visibility, max_hits, num_hits);
    }
#      endif /* _HAIR_ */
    return false;
    ///TODO return bvh_intersect_shadow_all_motion(kg, ray, isect, visibility, max_hits, num_hits);
  }
#    endif   /* _OBJECT_MOTION_ */

#    ifdef _HAIR_
  if  (bool(kernel_data.bvh.have_curves) ){
    return false;
    //TDOO return bvh_intersect_shadow_all_hair(kg, ray, isect, visibility, max_hits, num_hits);
  }
#    endif /* _HAIR_ */
  return false;
  ///TODO return bvh_intersect_shadow_all(kg, ray, isect, visibility, max_hits, num_hits);
#  endif   /* _KERNEL_OPTIX_ */
}
#endif /* _SHADOW_RECORD_ALL_ */

#ifdef _VOLUME_
ccl_device_intersect bool scene_intersect_volume(inout KernelGlobals kg,
                                                 in Ray ray,
                                                 inout Intersection isect,
                                                 const uint visibility)
{
  PROFILING_INIT(kg, PROFILING_INTERSECT_VOLUME);

#  ifdef _KERNEL_OPTIX_
  uint p0 = 0;
  uint p1 = 0;
  uint p2 = 0;
  uint p3 = 0;
  uint p4 = visibility;
  uint p5 = PRIMITIVE_NONE;

  optixTrace(scene_intersect_valid(ray) ? kernel_data.bvh.scene : 0,
             ray.P,
             ray.D,
             0.0f,
             ray.t,
             ray.time,
             // Skip everything but volumes
             0x2,
             OPTIX_RAY_FLAG_NONE,
             0,  // SBT offset for PG_HITD
             0,
             0,
             p0,
             p1,
             p2,
             p3,
             p4,
             p5);

  isect.t = _uint_as_float(p0);
  isect.u = _uint_as_float(p1);
  isect.v = _uint_as_float(p2);
  isect.prim = p3;
  isect.object = p4;
  isect.type = p5;

  return p5 != PRIMITIVE_NONE;
#  else /* _KERNEL_OPTIX_ */
  if (!scene_intersect_valid(ray)) {
    return false;
  }

#    ifdef _OBJECT_MOTION_
  if (kernel_data.bvh.have_motion) {
    return bvh_intersect_volume_motion(kg, ray, isect, visibility);
  }
#    endif /* _OBJECT_MOTION_ */

  return bvh_intersect_volume(kg, ray, isect, visibility);
#  endif   /* _KERNEL_OPTIX_ */
}
#endif /* _VOLUME_ */

#ifdef _VOLUME_RECORD_ALL_
ccl_device_intersect uint scene_intersect_volume_all(inout KernelGlobals kg,
                                                     in Ray ray,
                                                     inout Intersection isect,
                                                     const uint max_hits,
                                                     const uint visibility)
{
  PROFILING_INIT(kg, PROFILING_INTERSECT_VOLUME_ALL);

  if (!scene_intersect_valid(ray)) {
    return false;
  }

#  ifdef _EMBREE_
  if (kernel_data.bvh.scene) {
    CCLIntersectContext ctx(kg, CCLIntersectContext::RAY_VOLUME_ALL);
    ctx.isect_s = isect;
    ctx.max_hits = max_hits;
    ctx.num_hits = 0;
    IntersectContext rtc_ctx(&ctx);
    RTCRay rtc_ray;
    kernel_embree_setup_ray(*ray, rtc_ray, visibility);
    rtcOccluded1(kernel_data.bvh.scene, &rtc_ctx.context, &rtc_ray);
    return ctx.num_hits;
  }
#  endif /* _EMBREE_ */

#  ifdef _OBJECT_MOTION_
  if (kernel_data.bvh.have_motion) {
    return bvh_intersect_volume_all_motion(kg, ray, isect, max_hits, visibility);
  }
#  endif /* _OBJECT_MOTION_ */

  return bvh_intersect_volume_all(kg, ray, isect, max_hits, visibility);
}
#endif /* _VOLUME_RECORD_ALL_ */

/* Ray offset to avoid self intersection.
 *
 * This function should be used to compute a modified ray start position for
 * rays leaving from a surface. */

ccl_device_inline float3 ray_offset(float3 P, float3 Ng)
{
#ifdef _INTERSECTION_REFINE_
  const float epsilon_f = 1e-5f;
  /* ideally this should match epsilon_f, but instancing and motion blur
   * precision makes it problematic */
  const float epsilon_test = 1.0f;
  const int epsilon_i = 32;

  float3 res;

  /* x component */
  if (fabsf(P.x) < epsilon_test) {
    res.x = P.x + Ng.x * epsilon_f;
  }
  else {
    uint ix = _float_as_uint(P.x);
    ix += ( bool((ix ^ _float_as_uint(Ng.x)) >> 31) )? -epsilon_i : epsilon_i;
    res.x = _uint_as_float(ix);
  }

  /* y component */
  if (fabsf(P.y) < epsilon_test) {
    res.y = P.y + Ng.y * epsilon_f;
  }
  else {
    uint iy = _float_as_uint(P.y);
    iy += (bool((iy ^ _float_as_uint(Ng.y)) >> 31)) ? -epsilon_i : epsilon_i;
    res.y = _uint_as_float(iy);
  }

  /* z component */
  if (fabsf(P.z) < epsilon_test) {
    res.z = P.z + Ng.z * epsilon_f;
  }
  else {
    uint iz = _float_as_uint(P.z);
    iz += (bool((iz ^ _float_as_uint(Ng.z)) >> 31)) ? -epsilon_i : epsilon_i;
    res.z = _uint_as_float(iz);
  }

  return res;
#else
  const float epsilon_f = 1e-4f;
  return P + epsilon_f * Ng;
#endif
}

#if defined(_VOLUME_RECORD_ALL_) || (defined(_SHADOW_RECORD_ALL_) && defined(_KERNEL_CPU_))
/* ToDo: Move to another file? */
ccl_device int intersections_compare(const void *a, const void *b)
{
  const inout Intersection isect_a = (const Intersection *)a;
  const inout Intersection isect_b = (const Intersection *)b;

  if (isect_a.t < isect_b.t)
    return -1;
  else if (isect_a.t > isect_b.t)
    return 1;
  else
    return 0;
}
#endif

#if defined(_SHADOW_RECORD_ALL_)
ccl_device_inline void sort_intersections(Intersection *hits, uint num_hits)
{
#  ifdef _KERNEL_GPU_
  /* Use bubble sort which has more friendly memory pattern on GPU. */
  bool swapped;
  do {
    swapped = false;
    for (int j = 0; j < num_hits - 1; ++j) {
      if (hits[j].t > hits[j + 1].t) { 
 Intersection tmp = hits[j];
        hits[j] = hits[j + 1];
        hits[j + 1] = tmp;
        swapped = true;
      }
    }
    --num_hits;
  } while (swapped);
#  else
  qsort(hits, num_hits, sizeof(Intersection), intersections_compare);
#  endif
}
#endif /* _SHADOW_RECORD_ALL_ | _VOLUME_RECORD_ALL_ */

CCL_NAMESPACE_END
