#ifndef _GEOM_SUBD_TRIANGLE_H_
#define _GEOM_SUBD_TRIANGLE_H_
//SD GLOBAL

/*
 * Copyright 2011-2016 Blender Foundation
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

/* Functions for retrieving attributes on triangles produced from subdivision meshes */
#include "kernel/geom/geom_patch.h.glsl"
CCL_NAMESPACE_BEGIN

/* Patch index for triangle, -1 if not subdivision triangle */

#define subd_triangle_patch() uint((GSD.prim != PRIM_NONE) ? kernel_tex_fetch(_tri_patch, GSD.prim) : ~0)

/* UV coords of triangle within patch_rsv */
#define  subd_triangle_patch_uv(uv)\
{ uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, GSD.prim) + VertexOffset(GSD.geometry);\
  uv[0] = kernel_tex_fetch(_tri_patch_uv, tri_vindex.x);\
  uv[1] = kernel_tex_fetch(_tri_patch_uv, tri_vindex.y);\
  uv[2] = kernel_tex_fetch(_tri_patch_uv, tri_vindex.z);\
}

/* Vertex indices of patch_rsv */

ccl_device_inline uint4 subd_triangle_patch_indices(int patch_rsv)
{
  uint4 indices;

  indices.x = kernel_tex_fetch(_patches, patch_rsv + 0);
  indices.y = kernel_tex_fetch(_patches, patch_rsv + 1);
  indices.z = kernel_tex_fetch(_patches, patch_rsv + 2);
  indices.w = kernel_tex_fetch(_patches, patch_rsv + 3);

  return indices;
}

/* Originating face for patch_rsv */
#define subd_triangle_patch_face(patch_rsv) uint(kernel_tex_fetch(_patches, patch_rsv + 4))


/* Number of corners on originating face */
#define  subd_triangle_patch_num_corners(patch_rsv) uint(kernel_tex_fetch(_patches, patch_rsv + 5) & 0xffff)
/* Indices of the four corners that are used by the patch_rsv */
#define  subd_triangle_patch_corners(patch_rsv,  corners )\
{\
  uint4 data;\
  data.x = kernel_tex_fetch(_patches, patch_rsv + 4);\
  data.y = kernel_tex_fetch(_patches, patch_rsv + 5);\
  data.z = kernel_tex_fetch(_patches, patch_rsv + 6);\
  data.w = kernel_tex_fetch(_patches, patch_rsv + 7);\
  int num_corners = int(data.y & 0xffff);\
  if (num_corners == 4) {\
    corners[0] = int(data.z);\
    corners[1] = int(data.z) + 1;\
    corners[2] = int(data.z) + 2;\
    corners[3] = int(data.z) + 3;\
  }\
  else {\
    int c = int(data.y >> 16);\
    corners[0] = int(data.z) + c;\
    corners[1] = int(data.z) + mod(c + 1, num_corners);\
    corners[2] = int(data.w);\
    corners[3] = int(data.z) + mod(c - 1, num_corners);\
  }\
}

/* Reading attributes on various subdivision triangle elements */

ccl_device_noinline float subd_triangle_attribute_float(const AttributeDescriptor desc, inout float dx, inout float dy)
{
  int patch_rsv = int(subd_triangle_patch());


#ifdef _PATCH_EVAL_
  if (bool(desc.flags & ATTR_SUBDIVIDED)) {
    float2 uv[3];
    subd_triangle_patch_uv( uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * GSD.u + dpdv * GSD.v + uv[2];

    float a, dads, dadt;
    a = patch_eval_float(desc.offset, patch_rsv, p.x, p.y, 0, (dads), (dadt));



#  ifdef _RAY_DIFFERENTIALS_
    if (!isNULL(dx) || !isNULL(dy))
 {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (!isNULL(dx))
 {
        float dudx = GSD.du.dx;
        float dvdx = GSD.dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        dx = dads * dsdx + dadt * dtdx;
      }
      if (!isNULL(dy))
 {
        float dudy = GSD.du.dy;
        float dvdy = GSD.dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        dy = dads * dsdy + dadt * dtdy;
      }
    }
#  endif

    return a;
  }
  else
#endif /* _PATCH_EVAL_ */
      if (desc.element == ATTR_ELEMENT_FACE) {
    if (!isNULL(dx))
      dx = 0.0f;
    if (!isNULL(dy))
      dy = 0.0f;

    return kernel_tex_fetch(_attributes_float, desc.offset + subd_triangle_patch_face(patch_rsv));
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    float2 uv[3];
    subd_triangle_patch_uv( uv);

    uint4 v = subd_triangle_patch_indices( patch_rsv);

    float f0 = kernel_tex_fetch(_attributes_float, desc.offset + v.x);
    float f1 = kernel_tex_fetch(_attributes_float, desc.offset + v.y);
    float f2 = kernel_tex_fetch(_attributes_float, desc.offset + v.z);
    float f3 = kernel_tex_fetch(_attributes_float, desc.offset + v.w);

    if (subd_triangle_patch_num_corners(patch_rsv) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef _RAY_DIFFERENTIALS_
    if (!isNULL(dx))

      dx = GSD.du.dx * a + GSD.dv.dx * b - (GSD.du.dx + GSD.dv.dx) * c;
    if (!isNULL(dy))

      dy = GSD.du.dy * a + GSD.dv.dy * b - (GSD.du.dy + GSD.dv.dy) * c;
#endif

    return GSD.u * a + GSD.v * b + (1.0f - GSD.u - GSD.v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    float2 uv[3];
    subd_triangle_patch_uv( uv);

    int corners[4];
    subd_triangle_patch_corners(patch_rsv, corners);

    float f0 = kernel_tex_fetch(_attributes_float, corners[0] + desc.offset);
    float f1 = kernel_tex_fetch(_attributes_float, corners[1] + desc.offset);
    float f2 = kernel_tex_fetch(_attributes_float, corners[2] + desc.offset);
    float f3 = kernel_tex_fetch(_attributes_float, corners[3] + desc.offset);

    if (subd_triangle_patch_num_corners( patch_rsv) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef _RAY_DIFFERENTIALS_
    if (!isNULL(dx))

      dx = GSD.du.dx * a + GSD.dv.dx * b - (GSD.du.dx + GSD.dv.dx) * c;
    if (!isNULL(dy))

      dy = GSD.du.dy * a + GSD.dv.dy * b - (GSD.du.dy + GSD.dv.dy) * c;
#endif

    return GSD.u * a + GSD.v * b + (1.0f - GSD.u - GSD.v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (!isNULL(dx))

      dx = 0.0f;
    if (!isNULL(dy))

      dy = 0.0f;

    return kernel_tex_fetch(_attributes_float, desc.offset);
  }
  else {
    if (!isNULL(dx))

      dx = 0.0f;
    if (!isNULL(dy))

      dy = 0.0f;

    return 0.0f;
  }
}


ccl_device_noinline float2 subd_triangle_attribute_float2(
                                                          const AttributeDescriptor desc,
                                                          inout float2 dx2,
                                                          inout float2 dy2)
{
  int patch_rsv = int(subd_triangle_patch());


#ifdef _PATCH_EVAL_
  if (bool(desc.flags & ATTR_SUBDIVIDED)) {
    float2 uv[3];
    subd_triangle_patch_uv( uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * GSD.u + dpdv * GSD.v + uv[2];

    float2 a, dads, dadt;

    a = patch_eval_float2(desc.offset, patch_rsv, p.x, p.y, 0, (dads), (dadt));

#  ifdef _RAY_DIFFERENTIALS_
    if (!isNULL2(dx2) || !isNULL2(dy2))
 {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (!isNULL2(dx2))
 {
        float dudx = GSD.du.dx;
        float dvdx = GSD.dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        dx2 = dads * dsdx + dadt * dtdx;
      }
      if (!isNULL2(dy2))
 {
        float dudy = GSD.du.dy;
        float dvdy = GSD.dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        dy2 = dads * dsdy + dadt * dtdy;
      }
    }
#  endif

    return a;
  }
  else
#endif /* _PATCH_EVAL_ */
  if (desc.element == ATTR_ELEMENT_FACE) {
    if (!isNULL2(dx2))
      dx2 = make_float2(0.0f, 0.0f);
    if (!isNULL2(dy2))
      dy2 = make_float2(0.0f, 0.0f);
    return kernel_tex_fetch(_attributes_float2,
                            desc.offset + subd_triangle_patch_face( patch_rsv));
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    float2 uv[3];
    subd_triangle_patch_uv( uv);

    uint4 v = subd_triangle_patch_indices(patch_rsv);

    float2 f0 = kernel_tex_fetch(_attributes_float2, desc.offset + v.x);
    float2 f1 = kernel_tex_fetch(_attributes_float2, desc.offset + v.y);
    float2 f2 = kernel_tex_fetch(_attributes_float2, desc.offset + v.z);
    float2 f3 = kernel_tex_fetch(_attributes_float2, desc.offset + v.w);

    if (subd_triangle_patch_num_corners(patch_rsv) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float2 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float2 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float2 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef _RAY_DIFFERENTIALS_
    if (!isNULL2(dx2))
      dx2 = GSD.du.dx * a + GSD.dv.dx * b - (GSD.du.dx + GSD.dv.dx) * c;
    if (!isNULL2(dy2))
      dy2 = GSD.du.dy * a + GSD.dv.dy * b - (GSD.du.dy + GSD.dv.dy) * c;
#endif

    return GSD.u * a + GSD.v * b + (1.0f - GSD.u - GSD.v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    float2 uv[3];
    subd_triangle_patch_uv( uv);

    int corners[4];
    subd_triangle_patch_corners(patch_rsv, corners);

    float2 f0, f1, f2, f3;

    f0 = kernel_tex_fetch(_attributes_float2, corners[0] + desc.offset);
    f1 = kernel_tex_fetch(_attributes_float2, corners[1] + desc.offset);
    f2 = kernel_tex_fetch(_attributes_float2, corners[2] + desc.offset);
    f3 = kernel_tex_fetch(_attributes_float2, corners[3] + desc.offset);

    if (subd_triangle_patch_num_corners(patch_rsv) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float2 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float2 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float2 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef _RAY_DIFFERENTIALS_
    if (!isNULL2(dx2))

      dx2 = GSD.du.dx * a + GSD.dv.dx * b - (GSD.du.dx + GSD.dv.dx) * c;
    if (!isNULL2(dy2))

      dy2 = GSD.du.dy * a + GSD.dv.dy * b - (GSD.du.dy + GSD.dv.dy) * c;
#endif

    return GSD.u * a + GSD.v * b + (1.0f - GSD.u - GSD.v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if (!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);

    return kernel_tex_fetch(_attributes_float2, desc.offset);
  }
  else {
    if (!isNULL2(dx2))
      dx2 = make_float2(0.0f, 0.0f);
    if (!isNULL2(dy2))
      dy2 = make_float2(0.0f, 0.0f);

    return make_float2(0.0f, 0.0f);
  }
}



ccl_device_noinline float3 subd_triangle_attribute_float3(
                                                          const AttributeDescriptor desc,
                                                          inout float3 dx3,
                                                          inout float3 dy3)
{
  int patch_rsv = int(subd_triangle_patch());
#ifdef _PATCH_EVAL_
  if (bool(desc.flags & ATTR_SUBDIVIDED)
) {
    float2 uv[3];
    subd_triangle_patch_uv(uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * GSD.u + dpdv * GSD.v + uv[2];

    float3 a, dads, dadt;
    a = patch_eval_float3(desc.offset, patch_rsv, p.x, p.y, 0, (dads), (dadt));
#  ifdef _RAY_DIFFERENTIALS_
    if (!isNULL3(dx3) || !isNULL3(dy3))
 {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (!isNULL3(dx3))
 {
        float dudx = GSD.du.dx;
        float dvdx = GSD.dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        dx3 = dads * dsdx + dadt * dtdx;
      }
      if (!isNULL3(dy3))
 {
        float dudy = GSD.du.dy;
        float dvdy = GSD.dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        dy3 = dads * dsdy + dadt * dtdy;
      }
    }
#  endif

    return a;
  }
  else
#endif /* _PATCH_EVAL_ */
      if (desc.element == ATTR_ELEMENT_FACE) {
    if (!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if (!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);

    return float4_to_float3(
        kernel_tex_fetch(_attributes_float3, desc.offset + subd_triangle_patch_face(patch_rsv)));
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    float2 uv[3];
    subd_triangle_patch_uv(uv);

    uint4 v = subd_triangle_patch_indices(patch_rsv);
    float3 f0 = float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + v.x));
    float3 f1 = float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + v.y));
    float3 f2 = float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + v.z));
    float3 f3 = float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + v.w));

    if (subd_triangle_patch_num_corners(patch_rsv) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float3 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float3 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float3 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef _RAY_DIFFERENTIALS_
    if (!isNULL3(dx3))
      dx3 = GSD.du.dx * a + GSD.dv.dx * b - (GSD.du.dx + GSD.dv.dx) * c;
    if (!isNULL3(dy3))
      dy3 = GSD.du.dy * a + GSD.dv.dy * b - (GSD.du.dy + GSD.dv.dy) * c;
#endif
    return GSD.u * a + GSD.v * b + (1.0f - GSD.u - GSD.v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    float2 uv[3];
    subd_triangle_patch_uv(uv);
    int corners[4];
    subd_triangle_patch_corners(patch_rsv, corners);
    float3 f0, f1, f2, f3;
    f0 = float4_to_float3(kernel_tex_fetch(_attributes_float3, corners[0] + desc.offset));
    f1 = float4_to_float3(kernel_tex_fetch(_attributes_float3, corners[1] + desc.offset));
    f2 = float4_to_float3(kernel_tex_fetch(_attributes_float3, corners[2] + desc.offset));
    f3 = float4_to_float3(kernel_tex_fetch(_attributes_float3, corners[3] + desc.offset));
    if (subd_triangle_patch_num_corners(patch_rsv) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }
    float3 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float3 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float3 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);
#ifdef _RAY_DIFFERENTIALS_
    if (!isNULL3(dx3))
      dx3 = GSD.du.dx * a + GSD.dv.dx * b - (GSD.du.dx + GSD.dv.dx) * c;
    if (!isNULL3(dy3))
      dy3 = GSD.du.dy * a + GSD.dv.dy * b - (GSD.du.dy + GSD.dv.dy) * c;
#endif
    return GSD.u * a + GSD.v * b + (1.0f - GSD.u - GSD.v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (!isNULL3(dx3))
      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if (!isNULL3(dy3))
      dy3 = make_float3(0.0f, 0.0f, 0.0f);
    return float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset));
  }
  else {
    if (!isNULL3(dx3))
      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if (!isNULL3(dy3))
      dy3 = make_float3(0.0f, 0.0f, 0.0f);
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}


ccl_device_noinline float4 subd_triangle_attribute_float4(
                                                          const AttributeDescriptor desc,
                                                          inout float4 dx4,
                                                          inout float4 dy4)
{
  int patch_rsv = int(subd_triangle_patch());


#ifdef _PATCH_EVAL_
  if (bool(desc.flags & ATTR_SUBDIVIDED)) {
    float2 uv[3];
    subd_triangle_patch_uv(uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * GSD.u + dpdv * GSD.v + uv[2];

    float4 dads, dadt;

    float4 a = patch_eval_uchar4( desc.offset, patch_rsv, p.x, p.y, 0, (dads), (dadt));

#  ifdef _RAY_DIFFERENTIALS_
    if (!isNULL4(dx4) || !isNULL4(dy4))
 {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (!isNULL4(dx4))
 {
        float dudx = GSD.du.dx;
        float dvdx = GSD.dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        dx4 = dads * dsdx + dadt * dtdx;
      }
      if (!isNULL4(dy4))
 {
        float dudy = GSD.du.dy;
        float dvdy = GSD.dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        dy4 = dads * dsdy + dadt * dtdy;
      }
    }
#  endif
    return a;
  }
  else
#endif /* _PATCH_EVAL_ */
      if (desc.element == ATTR_ELEMENT_CORNER_BYTE) {
    float2 uv[3];
    subd_triangle_patch_uv( uv);

    int corners[4];
    subd_triangle_patch_corners( patch_rsv, corners);

    float4 f0 = color_uchar4_to_float4(
        kernel_tex_fetch(_attributes_uchar4, corners[0] + desc.offset));
    float4 f1 = color_uchar4_to_float4(
        kernel_tex_fetch(_attributes_uchar4, corners[1] + desc.offset));
    float4 f2 = color_uchar4_to_float4(
        kernel_tex_fetch(_attributes_uchar4, corners[2] + desc.offset));
    float4 f3 = color_uchar4_to_float4(
        kernel_tex_fetch(_attributes_uchar4, corners[3] + desc.offset));

    if (subd_triangle_patch_num_corners( patch_rsv) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float4 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float4 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float4 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef _RAY_DIFFERENTIALS_
    if (!isNULL4(dx4))

      dx4 = GSD.du.dx * a + GSD.dv.dx * b - (GSD.du.dx + GSD.dv.dx) * c;
    if (!isNULL4(dy4))

      dy4 = GSD.du.dy * a + GSD.dv.dy * b - (GSD.du.dy + GSD.dv.dy) * c;
#endif

    return GSD.u * a + GSD.v * b + (1.0f - GSD.u - GSD.v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (!isNULL4(dx4))

      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if (!isNULL4(dy4))

      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);

    return color_uchar4_to_float4(kernel_tex_fetch(_attributes_uchar4, desc.offset));
  }
  else {
    if (!isNULL4(dx4))
      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if (!isNULL4(dy4))
      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);

    return make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  }
}

CCL_NAMESPACE_END
#endif