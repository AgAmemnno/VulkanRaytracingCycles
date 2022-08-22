#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
//#define SET_KERNEL 2
//#define PUSH_KERNEL_TEX
#include "kernel/kernel_globals.h.glsl"

#define RPL_RGEN_IN
#include "kernel/payload.glsl"

#define SetTFM(tfm){\
    tfm.x = vec4(gl_ObjectToWorldNV[0][0],gl_ObjectToWorldNV[1][0],gl_ObjectToWorldNV[2][0],gl_ObjectToWorldNV[3][0]);\
    tfm.y = vec4(gl_ObjectToWorldNV[0][1],gl_ObjectToWorldNV[1][1],gl_ObjectToWorldNV[2][1],gl_ObjectToWorldNV[3][1]);\
    tfm.z = vec4(gl_ObjectToWorldNV[0][2],gl_ObjectToWorldNV[1][2],gl_ObjectToWorldNV[2][2],gl_ObjectToWorldNV[3][2]);\
}
#define SetITFM(tfm){\
    tfm.x = vec4(gl_WorldToObjectNV[0][0],gl_WorldToObjectNV[1][0],gl_WorldToObjectNV[2][0],gl_WorldToObjectNV[3][0]);\
    tfm.y = vec4(gl_WorldToObjectNV[0][1],gl_WorldToObjectNV[1][1],gl_WorldToObjectNV[2][1],gl_WorldToObjectNV[3][1]);\
    tfm.z = vec4(gl_WorldToObjectNV[0][2],gl_WorldToObjectNV[1][2],gl_WorldToObjectNV[2][2],gl_WorldToObjectNV[3][2]);\
}


ccl_device_inline vec3 triangle_refine()
{
#ifdef _INTERSECTION_REFINE_
  float3 P = float3(gl_WorldRayOriginNV,0.);
  float3 D = float3(gl_WorldRayDirectionNV,0.);
  float t = gl_HitTNV;
  /// modify if (GISECT.object != OBJECT_NONE) {
  Transform tfm;
  if(!OBJECT_IS_NONE(isect.object)){
    if (UNLIKELY(t == 0.0f)) {
      return P.xyz;
    }
#  ifdef _OBJECT_MOTION2_
    SetITFM(tfm);
#  else
    Transform tfm = object_fetch_transform(GetObjectID(isect.object), OBJECT_INVERSE_TRANSFORM);
#  endif

    P = transform_point(tfm, P);
    D = transform_direction(tfm, D * t);
    D = normalize_len(D, t);
  }
  P = P + D * t;


  const uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, isect.prim) + VertexOffset(ObjectID);
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
  if(!OBJECT_IS_NONE(isect.object)){
#  ifdef _OBJECT_MOTION2_
    SetTFM(tfm);
#  else
    Transform tfm = object_fetch_transform(GetObjectID(isect.object), OBJECT_TRANSFORM);
#  endif
    P = transform_point(tfm, P);
  }

  return P.xyz;
#else
  return gl_WorldRayOriginNV + (gl_WorldRayDirectionNV * gl_HitTNV);
#endif
}


void main()
{

isect.t      =  gl_HitTNV;
isect.u      = (1.0 - attribs.x) - attribs.y;
isect.v      = attribs.x;
isect.prim   = int(gl_PrimitiveID + PrimitiveOffset(ObjectID));
isect.object =  gl_InstanceCustomIndexNV;
isect.type   =  int(push.data_ptr._prim_type.data[isect.prim]);
isect.P      = triangle_refine();



}
