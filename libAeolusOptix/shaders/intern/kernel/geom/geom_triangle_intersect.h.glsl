#ifndef _GEOM_TRI_INTERSECT_H_
#define _GEOM_TRI_INTERSECT_H_
/*
 * Copyright 2014, Blender Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in_rsv compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in_rsv writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* Triangle/Ray intersections.
 *
 * For BVH ray intersection we use a precomputed triangle storage to accelerate
 * intersection at the cost of more memory usage.
 */

CCL_NAMESPACE_BEGIN
#ifndef _KERNEL_VULKAN_
ccl_device_inline bool triangle_intersect(inout KernelGlobals kg,
                                          inout Intersection isect,
                                          float3 P,
                                          float3 dir,
                                          uint visibility,
                                          int object,
                                          int prim_addr)
{
  const uint tri_vindex = kernel_tex_fetch(_prim_tri_index, prim_addr);
#if defined(_KERNEL_SSE2_) && defined(_KERNEL_SSE_)
  const ssef *ssef_verts = (ssef *)&kg._prim_tri_verts.data[tri_vindex];
#else
  const float4 tri_a = kernel_tex_fetch(_prim_tri_verts, tri_vindex + 0),
               tri_b = kernel_tex_fetch(_prim_tri_verts, tri_vindex + 1),
               tri_c = kernel_tex_fetch(_prim_tri_verts, tri_vindex + 2);
#endif
  float t, u, v;
  if (ray_triangle_intersect(P,
                             dir,
                             GISECT.t,
#if defined(_KERNEL_SSE2_) && defined(_KERNEL_SSE_)
                             ssef_verts,
#else
                             float4_to_float3(tri_a),
                             float4_to_float3(tri_b),
                             float4_to_float3(tri_c),
#endif
                             u,
                             v,
                             t)) {
#ifdef _VISIBILITY_FLAG_
    /* Visibility flag test. we do it here under the assumption
     * that most triangles are culled by node flags.
     */
    if (bool(kernel_tex_fetch(_prim_visibility, prim_addr) & visibility))
#endif
    {
      GISECT.prim = prim_addr;
      GISECT.object = object;
      GISECT.type = int(PRIMITIVE_TRIANGLE);
      GISECT.u = u;
      GISECT.v = v;
      GISECT.t = t;
      return true;
    }
  }
  return false;
}

/* Special ray intersection routines for subsurface scattering. In that case we
 * only want to intersect with primitives in_rsv the same object, and if case of
 * multiple hits we pick a single random primitive as the intersection point.
 * Returns whether traversal should be stopped.
 */


#ifdef _BVH_LOCAL_
ccl_device_inline bool triangle_intersect_local(inout KernelGlobals kg,
                                                inout LocalIntersection local_isect,
                                                float3 P,
                                                float3 dir,
                                                int object,
                                                int local_object,
                                                int prim_addr,
                                                float tmax,
                                                inout uint lcg_state,
                                                int max_hits)
{
  /* Only intersect with matching object, for instanced objects we
   * already know we are only intersecting the right object. */
  // objectIndex Cpu
  if (object == OBJECT_NONE) {
    if (kernel_tex_fetch(_prim_object, prim_addr) != local_object) {
      return false;
    }
  }

  const uint tri_vindex = kernel_tex_fetch(_prim_tri_index, prim_addr);
#  if defined(_KERNEL_SSE2_) && defined(_KERNEL_SSE_)
  const ssef *ssef_verts = (ssef *)&kg._prim_tri_verts.data[tri_vindex];
#  else
  const float3 tri_a = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex + 0)),
               tri_b = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex + 1)),
               tri_c = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex + 2));
#  endif
  float t, u, v;
  if (!ray_triangle_intersect(P,
                              dir,
                              tmax,
#  if defined(_KERNEL_SSE2_) && defined(_KERNEL_SSE_)
                              ssef_verts,
#  else
                              tri_a,
                              tri_b,
                              tri_c,
#  endif
                              u,
                              v,
                              t)) {
    return false;
  }

  /* If no actual hit information is requested, just return here. */
  if (max_hits == 0) {
    return true;
  }

  int hit;
  if (bool(lcg_state))
 {
    /* Record up to max_hits intersections. */
    for (int i = min(max_hits, local_isect.num_hits) - 1; i >= 0; --i) {
      if (local_isect.hits[i].t == t) {
        return false;
      }
    }

    local_isect.num_hits++;

    if (local_isect.num_hits <= max_hits) {
      hit = local_isect.num_hits - 1;
    }
    else {
      /* reservoir sampling: if we are at the maximum number of
       * hits, randomly replace element or skip it */
      hit =  int(lcg_step_uint(lcg_state) % local_isect.num_hits);


      if (hit >= max_hits)
        return false;
    }
  }
  else {
    /* Record closest intersection only. */
    if (bool(local_isect.num_hits) && t > local_isect.hits[0].t) 
 {
      return false;
    }

    hit = 0;
    local_isect.num_hits = 1;
  }

  /* Record intersection. */
  local_isect.hits[hit].prim = prim_addr;
  local_isect.hits[hit].object = object;
  local_isect.hits[hit].type = int(PRIMITIVE_TRIANGLE);
  local_isect.hits[hit].u = u;
  local_isect.hits[hit].v = v;
  local_isect.hits[hit].t = t;

  /* Record geometric normal. */
#  if defined(_KERNEL_SSE2_) && defined(_KERNEL_SSE_)
  const float3 tri_a = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex + 0)),
               tri_b = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex + 1)),
               tri_c = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex + 2));
#  endif
  local_isect.Ng[hit] = normalize(cross(tri_b - tri_a, tri_c - tri_a));

  return false;
}
#endif /* _BVH_LOCAL_ */
#endif
/* Refine triangle intersection to more precise hit point. For rays that travel
 * far the precision is often not so good, this reintersects the primitive from
 * a closer distance. */

/* Reintersections uses the paper:
 *
 * Tomas Moeller
 * Fast, minimum storage ray/triangle intersection
 * http://www.cs.virginia.edu/~gfx/Courses/2003/ImageSynthesis/papers/Acceleration/Fast%20MinimumStorage%20RayTriangle%20Intersection.pdf
 */

#ifdef _BVH_LOCAL_
ccl_device_inline float3 triangle_refine(in float3 P,in float3 D,float t, int object,int prim,int geometry)
{
#ifdef _INTERSECTION_REFINE_

  /// modify if (GISECT.object != OBJECT_NONE) {
  if(!OBJECT_IS_NONE(object)){
    if (UNLIKELY(t == 0.0f)) {
      return P;
    }
#  ifdef _OBJECT_MOTION2_
    Transform tfm = GSD.ob_itfm;
#  else
    Transform tfm = object_fetch_transform(GetObjectID(object), OBJECT_INVERSE_TRANSFORM);
#  endif

    P = transform_point(tfm, P);
    D = transform_direction(tfm, D * t);
    D = normalize_len(D, t);
  }
  P = P + D * t;


  const uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, prim) + VertexOffset(geometry);
  const float4 tri_a = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.x),
               tri_b = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.y),
               tri_c = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.z);
  float3 edge1 = make_float3(tri_a.x - tri_c.x, tri_a.y - tri_c.y, tri_a.z - tri_c.z);
  float3 edge2 = make_float3(tri_b.x - tri_c.x, tri_b.y - tri_c.y, tri_b.z - tri_c.z);
  float3 tvec = make_float3(P.x - tri_c.x, P.y - tri_c.y, P.z - tri_c.z);
  vec3 qvec = cross(tvec.xyz, edge1.xyz);
  vec3 pvec = cross(D.xyz, edge2.xyz);
  float det = dot3(edge1.xyz, pvec.xyz);

  if (det != 0.0f) {
    /* If determinant is zero it means ray lies in_rsv the plane of
     * the triangle. It is possible in_rsv theory due to watertight
     * nature of triangle intersection. For such cases we simply
     * don't refine intersection hoping it'll go all fine.
     */
    float rt = dot3(edge2.xyz, qvec.xyz) / det;
    P = P + D * rt;
  }

  /// modify if (GISECT.object != OBJECT_NONE) {
  if(!OBJECT_IS_NONE(object)){
#  ifdef _OBJECT_MOTION2_
    Transform tfm = GSD.ob_tfm;
#  else
    Transform tfm = object_fetch_transform(GetObjectID(object), OBJECT_TRANSFORM);
#  endif
    P = transform_point(tfm, P);
  }

  return P;
#else
return ray.P + (ray.D * t);
#endif

}

#ifdef IS
/* Same as above, except that isect.t is assumed to be in_rsv object space for
 * instancing.
 */
#ifdef MISS_THROUGH_CALLEE
ccl_device_inline float3 triangle_refine_local(int ISid,
                                               in Ray ray)
{

  float t      = IS(ISid).t;
  int object   = IS(ISid).object;
  int prim     = IS(ISid).prim;
  int geometry = IS(ISid).type;
  return triangle_refine(ray.P,ray.D,t,object,prim,geometry);
};

#endif


#endif

#else
#ifdef GISECT
ccl_device_inline float3 triangle_refine(in Ray ray)
{
#ifdef _INTERSECTION_REFINE_
  float3 P = ray.P;
  float3 D = ray.D;
  float t = GISECT.t;
  /// modify if (GISECT.object != OBJECT_NONE) {
  if(!OBJECT_IS_NONE(GISECT.object)){
    if (UNLIKELY(t == 0.0f)) {
      return P;
    }
#  ifdef _OBJECT_MOTION2_
    Transform tfm = GSD.ob_itfm;
#  else
    //Transform tfm = object_fetch_transform(GetObjectID(GISECT.object), OBJECT_INVERSE_TRANSFORM);
#  endif

    P = transform_point(tfm, P);
    D = transform_direction(tfm, D * t);
    D = normalize_len(D, t);
  }
  P = P + D * t;


  const uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GISECT.prim) + VertexOffset(GSD.geometry);
  const float4 tri_a = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.x),
               tri_b = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.y),
               tri_c = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.z);
  float3 edge1 = make_float3(tri_a.x - tri_c.x, tri_a.y - tri_c.y, tri_a.z - tri_c.z);
  float3 edge2 = make_float3(tri_b.x - tri_c.x, tri_b.y - tri_c.y, tri_b.z - tri_c.z);
  float3 tvec = make_float3(P.x - tri_c.x, P.y - tri_c.y, P.z - tri_c.z);
  vec3 qvec = cross(tvec.xyz, edge1.xyz);
  vec3 pvec = cross(D.xyz, edge2.xyz);
  float det = dot3(edge1.xyz, pvec.xyz);

  if (det != 0.0f) {
    /* If determinant is zero it means ray lies in_rsv the plane of
     * the triangle. It is possible in_rsv theory due to watertight
     * nature of triangle intersection. For such cases we simply
     * don't refine intersection hoping it'll go all fine.
     */
    float rt = dot3(edge2.xyz, qvec.xyz) / det;
    P = P + D * rt;
  }

  /// modify if (GISECT.object != OBJECT_NONE) {
  if(!OBJECT_IS_NONE(GISECT.object)){
#  ifdef _OBJECT_MOTION2_
    Transform tfm = GSD.ob_tfm;
#  else
    //Transform tfm = object_fetch_transform(GetObjectID(GISECT.object), OBJECT_TRANSFORM);
#  endif
    P = transform_point(tfm, P);
  }

  return P;
#else
return ray.P + (ray.D * GISECT.t);
#endif

}



#endif
#endif
CCL_NAMESPACE_END
#endif