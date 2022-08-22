#ifndef _GEOM_TRI_H_
#define _GEOM_TRI_H_

/*
 * Copyright 2011-2013 Blender Foundation
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

/* Triangle Primitive
 *
 * Basic triangle with 3 vertices is used to represent mesh surfaces. For BVH
 * ray intersection we use a precomputed triangle storage to accelerate
 * intersection at the cost of more memory usage */

CCL_NAMESPACE_BEGIN

/* normal on triangle  */

vec4 triangle_normal()
{
  uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GSD.prim) + VertexOffset(GSD.geometry);
  vec4 v0 = push.data_ptr._prim_tri_verts2.data[tri_vindex.x];
  vec4 v1 = push.data_ptr._prim_tri_verts2.data[tri_vindex.y];
  vec4 v2 = push.data_ptr._prim_tri_verts2.data[tri_vindex.z];

  /* return normal */
  if (bool(GSD.object_flag & SD_OBJECT_NEGATIVE_SCALE_APPLIED ) ){
    return vec4(normalize(cross(v2.xyz - v0.xyz, v1.xyz - v0.xyz)),0.);
  }
  else {
    return vec4(normalize(cross(v1.xyz - v0.xyz, v2.xyz - v0.xyz)),0.);
  }
}

/* point and normal on triangle  */
ccl_device_inline void triangle_point_normal(
    int object, int prim, float u, float v,inout float3 P,inout float3 Ng,inout int shader)
{
  /* load triangle vertices */
  const uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, prim)+ VertexOffset(GSD.geometry);
  float3 v0 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.x));
  float3 v1 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.y));
  float3 v2 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.z));
  /* compute point */
  float t = 1.0f - u - v;
  P = (u * v0 + v * v1 + t * v2);
  /* get object flags */
  int object_flag = int(kernel_tex_fetch(_object_flag, object));
  /* compute normal */
  if(bool(object_flag & SD_OBJECT_NEGATIVE_SCALE_APPLIED) ){
    Ng = make_float3_v3(normalize(cross((v2 - v0).xyz, (v1 - v0).xyz )));
  }
  else {
    Ng = make_float3_v3(normalize(cross((v1 - v0).xyz, (v2 - v0).xyz )));
  }

  /* shader`*/
  shader = int(kernel_tex_fetch(_tri_shader, prim));
}

/* Triangle vertex locations */

ccl_device_inline void triangle_vertices( int prim,out float3 P[3])
{
  const uint3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, prim) + VertexOffset(GSD.geometry);
  P[0] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.x));
  P[1] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.y));
  P[2] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.z));
}

/* Interpolate smooth_rsv vertex normal from vertices */

ccl_device_inline float3
triangle_smooth_normal( float3 Ng, int prim, float u, float v)
{
  /* load triangle vertices */
  const uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, prim) + VertexOffset(GSD.geometry);
  float3 n0 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.x));
  float3 n1 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.y));
  float3 n2 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.z));

  float3 N = safe_normalize((1.0f - u - v) * n2 + u * n0 + v * n1);

  return is_zero(N) ? Ng : N;
}

/* Ray differentials on triangle */


#define triangle_dPdudv(prim,dPdu,dPdv)\
{\
  const uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, prim)+ VertexOffset(GSD.geometry);\
  const float3 p0 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.x));\
  const float3 p1 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.y));\
  const float3 p2 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts2, tri_vindex.z));\
  dPdu = (p0 - p2);\
  dPdv = (p1 - p2);\
}

#ifndef GEOM_NO_ATTR
/* Reading attributes on various triangle elements */

ccl_device float triangle_attribute_float(
  const AttributeDescriptor desc, inout float dx,inout float dy)
{
  if (desc.element == ATTR_ELEMENT_FACE) {
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;

    return kernel_tex_fetch(_attributes_float, desc.offset + GSD.prim);
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GSD.prim) + VertexOffset(GSD.geometry);

    float f0 = kernel_tex_fetch(_attributes_float, desc.offset + tri_vindex.x);
    float f1 = kernel_tex_fetch(_attributes_float, desc.offset + tri_vindex.y);
    float f2 = kernel_tex_fetch(_attributes_float, desc.offset + tri_vindex.z);

#ifdef _RAY_DIFFERENTIALS_
    if(!isNULL(dx))

      dx = GSD.du.dx * f0 + GSD.dv.dx * f1 - (GSD.du.dx + GSD.dv.dx) * f2;
    if(!isNULL(dy))

      dy = GSD.du.dy * f0 + GSD.dv.dy * f1 - (GSD.du.dy + GSD.dv.dy) * f2;
#endif

    return GSD.u * f0 + GSD.v * f1 + (1.0f - GSD.u - GSD.v) * f2;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    /// TODO ATTR_ELEMENT_CORNER
    int tri = desc.offset + GSD.prim * 3;
    float f0 = kernel_tex_fetch(_attributes_float, tri + 0);
    float f1 = kernel_tex_fetch(_attributes_float, tri + 1);
    float f2 = kernel_tex_fetch(_attributes_float, tri + 2);

#ifdef _RAY_DIFFERENTIALS_
    if(!isNULL(dx))

      dx = GSD.du.dx * f0 + GSD.dv.dx * f1 - (GSD.du.dx + GSD.dv.dx) * f2;
    if(!isNULL(dy))

      dy = GSD.du.dy * f0 + GSD.dv.dy * f1 - (GSD.du.dy + GSD.dv.dy) * f2;
#endif

    return GSD.u * f0 + GSD.v * f1 + (1.0f - GSD.u - GSD.v) * f2;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;

    return kernel_tex_fetch(_attributes_float, desc.offset);
  }
  else {
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;

    return 0.0f;
  }
}

ccl_device float2 triangle_attribute_float2(
                                            const AttributeDescriptor desc,
                                            inout float2 dx2,
                                            inout float2 dy2)
{
  if (desc.element == ATTR_ELEMENT_FACE) {
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);

    return kernel_tex_fetch(_attributes_float2, desc.offset + GSD.prim);
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GSD.prim) + VertexOffset(GSD.geometry);

    float2 f0 = kernel_tex_fetch(_attributes_float2, desc.offset + tri_vindex.x);
    float2 f1 = kernel_tex_fetch(_attributes_float2, desc.offset + tri_vindex.y);
    float2 f2 = kernel_tex_fetch(_attributes_float2, desc.offset + tri_vindex.z);

#ifdef _RAY_DIFFERENTIALS_
    if(!isNULL2(dx2))

      dx2 = GSD.du.dx * f0 + GSD.dv.dx * f1 - (GSD.du.dx + GSD.dv.dx) * f2;
    if(!isNULL2(dy2))

      dy2 = GSD.du.dy * f0 + GSD.dv.dy * f1 - (GSD.du.dy + GSD.dv.dy) * f2;
#endif
    return GSD.u * f0 + GSD.v * f1 + (1.0f - GSD.u - GSD.v) * f2;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    int tri = desc.offset + GSD.prim * 3;
    float2 f0, f1, f2;

    if (desc.element == ATTR_ELEMENT_CORNER) {
      f0 = kernel_tex_fetch(_attributes_float2, tri + 0);
      f1 = kernel_tex_fetch(_attributes_float2, tri + 1);
      f2 = kernel_tex_fetch(_attributes_float2, tri + 2);
    }

#ifdef _RAY_DIFFERENTIALS_
    if(!isNULL2(dx2))

      dx2 = GSD.du.dx * f0 + GSD.dv.dx * f1 - (GSD.du.dx + GSD.dv.dx) * f2;
    if(!isNULL2(dy2))

      dy2 = GSD.du.dy * f0 + GSD.dv.dy * f1 - (GSD.du.dy + GSD.dv.dy) * f2;
#endif

    return GSD.u * f0 + GSD.v * f1 + (1.0f - GSD.u - GSD.v) * f2;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);

    return kernel_tex_fetch(_attributes_float2, desc.offset);
  }
  else {
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);

    return make_float2(0.0f, 0.0f);
  }
}



ccl_device float3 triangle_attribute_float3(
                                            const AttributeDescriptor desc,
                                            inout float3 dx3,
                                            inout float3 dy3)
{
  if (desc.element == ATTR_ELEMENT_FACE) {
    if(!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);

    return float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + GSD.prim));
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GSD.prim)   + VertexOffset(GSD.geometry);

    float3 f0 = float4_to_float3(
        kernel_tex_fetch(_attributes_float3, desc.offset + tri_vindex.x));
    float3 f1 = float4_to_float3(
        kernel_tex_fetch(_attributes_float3, desc.offset + tri_vindex.y));
    float3 f2 = float4_to_float3(
        kernel_tex_fetch(_attributes_float3, desc.offset + tri_vindex.z));

#ifdef _RAY_DIFFERENTIALS_
     if(!isNULL3(dx3))

       dx3 = GSD.du.dx * f0 + GSD.dv.dx * f1 - (GSD.du.dx + GSD.dv.dx) * f2;
     if(!isNULL3(dy3))

       dy3 = GSD.du.dy * f0 + GSD.dv.dy * f1 - (GSD.du.dy + GSD.dv.dy) * f2;
#endif

    return GSD.u * f0 + GSD.v * f1 + (1.0f - GSD.u - GSD.v) * f2;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    int tri = desc.offset + GSD.prim * 3;
    float3 f0, f1, f2;

    f0 = float4_to_float3(kernel_tex_fetch(_attributes_float3, tri + 0));
    f1 = float4_to_float3(kernel_tex_fetch(_attributes_float3, tri + 1));
    f2 = float4_to_float3(kernel_tex_fetch(_attributes_float3, tri + 2));

#ifdef _RAY_DIFFERENTIALS_
    if(!isNULL3(dx3))

      dx3 = GSD.du.dx * f0 + GSD.dv.dx * f1 - (GSD.du.dx + GSD.dv.dx) * f2;
    if(!isNULL3(dy3))

      dy3 = GSD.du.dy * f0 + GSD.dv.dy * f1 - (GSD.du.dy + GSD.dv.dy) * f2;
#endif

    return GSD.u * f0 + GSD.v * f1 + (1.0f - GSD.u - GSD.v) * f2;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if(!isNULL3(dx3))

      dx3= make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);

    return float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset));
  }
  else {
    if(!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);

    return make_float3(0.0f, 0.0f, 0.0f);
  }
}


ccl_device float4 triangle_attribute_float4(
                                            const AttributeDescriptor desc,
                                            inout float4 dx4,
                                            inout float4 dy4)
{
  if (desc.element == ATTR_ELEMENT_CORNER_BYTE || desc.element == ATTR_ELEMENT_VERTEX) {
    float4 f0, f1, f2;

    if (desc.element == ATTR_ELEMENT_CORNER_BYTE) {
      int tri = desc.offset + GSD.prim * 3;
      f0 = color_uchar4_to_float4(kernel_tex_fetch(_attributes_uchar4, tri + 0));
      f1 = color_uchar4_to_float4(kernel_tex_fetch(_attributes_uchar4, tri + 1));
      f2 = color_uchar4_to_float4(kernel_tex_fetch(_attributes_uchar4, tri + 2));
    }
    else {
      uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GSD.prim) + VertexOffset(GSD.geometry);
      f0 = kernel_tex_fetch(_attributes_float3, desc.offset + tri_vindex.x);
      f1 = kernel_tex_fetch(_attributes_float3, desc.offset + tri_vindex.y);
      f2 = kernel_tex_fetch(_attributes_float3, desc.offset + tri_vindex.z);
    }

#ifdef _RAY_DIFFERENTIALS_
    if(!isNULL4(dx4))

      dx4 = GSD.du.dx * f0 + GSD.dv.dx * f1 - (GSD.du.dx + GSD.dv.dx) * f2;
    if(!isNULL4(dy4))

      dy4 = GSD.du.dy * f0 + GSD.dv.dy * f1 - (GSD.du.dy + GSD.dv.dy) * f2;
#endif

    return GSD.u * f0 + GSD.v * f1 + (1.0f - GSD.u - GSD.v) * f2;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if(!isNULL4(dx4))

      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if(!isNULL4(dy4))

      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);

    return color_uchar4_to_float4(kernel_tex_fetch(_attributes_uchar4, desc.offset));
  }
  else {
    if(!isNULL4(dx4))

      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if(!isNULL4(dy4))

      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);

    return make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  }
}
#endif
CCL_NAMESPACE_END
#endif