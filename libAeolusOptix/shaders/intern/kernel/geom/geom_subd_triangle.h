/*
 * Copyright 2011-2016 Blender Foundation
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

/* Functions for retrieving attributes on triangles produced from subdivision meshes */

CCL_NAMESPACE_BEGIN

/* Patch index for triangle, -1 if not subdivision triangle */

ccl_device_inline uint subd_triangle_patch(KernelGlobals *kg, const ShaderData *sd)
{
  return (sd->prim != PRIM_NONE) ? kernel_tex_fetch(__tri_patch, sd->prim) : ~0;
}

/* UV coords of triangle within patch */

ccl_device_inline void subd_triangle_patch_uv(KernelGlobals *kg,
                                              const ShaderData *sd,
                                              float2 uv[3])
{
  uint4 tri_vindex = kernel_tex_fetch(__tri_vindex, sd->prim);

  uv[0] = kernel_tex_fetch(__tri_patch_uv, tri_vindex.x);
  uv[1] = kernel_tex_fetch(__tri_patch_uv, tri_vindex.y);
  uv[2] = kernel_tex_fetch(__tri_patch_uv, tri_vindex.z);
}

/* Vertex indices of patch */

ccl_device_inline uint4 subd_triangle_patch_indices(KernelGlobals *kg, int patch)
{
  uint4 indices;

  indices.x = kernel_tex_fetch(__patches, patch + 0);
  indices.y = kernel_tex_fetch(__patches, patch + 1);
  indices.z = kernel_tex_fetch(__patches, patch + 2);
  indices.w = kernel_tex_fetch(__patches, patch + 3);

  return indices;
}

/* Originating face for patch */

ccl_device_inline uint subd_triangle_patch_face(KernelGlobals *kg, int patch)
{
  return kernel_tex_fetch(__patches, patch + 4);
}

/* Number of corners on originating face */

ccl_device_inline uint subd_triangle_patch_num_corners(KernelGlobals *kg, int patch)
{
  return kernel_tex_fetch(__patches, patch + 5) & 0xffff;
}

/* Indices of the four corners that are used by the patch */

ccl_device_inline void subd_triangle_patch_corners(KernelGlobals *kg, int patch, int corners[4])
{
  uint4 data;

  data.x = kernel_tex_fetch(__patches, patch + 4);
  data.y = kernel_tex_fetch(__patches, patch + 5);
  data.z = kernel_tex_fetch(__patches, patch + 6);
  data.w = kernel_tex_fetch(__patches, patch + 7);

  int num_corners = data.y & 0xffff;

  if (num_corners == 4) {
    /* quad */
    corners[0] = (int)data.z;
    corners[1] = (int)data.z + 1;
    corners[2] = (int)data.z + 2;
    corners[3] = (int)data.z + 3;
  }
  else {
    /* ngon */
    int c = (int)(data.y >> 16);

    corners[0] = (int)data.z + c;
    corners[1] = (int)data.z + mod(c + 1, num_corners);
    corners[2] = (int)data.w;
    corners[3] = (int)data.z + mod(c - 1, num_corners);
  }
}

/* Reading attributes on various subdivision triangle elements */

ccl_device_noinline float subd_triangle_attribute_float(
    KernelGlobals *kg, const ShaderData *sd, const AttributeDescriptor desc, float *dx, float *dy)
{
  int patch = subd_triangle_patch(kg, sd);

#ifdef __PATCH_EVAL__
  if (desc.flags & ATTR_SUBDIVIDED) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * sd->u + dpdv * sd->v + uv[2];

    float a, dads, dadt;
    a = patch_eval_float(kg, sd, desc.offset, patch, p.x, p.y, 0, &dads, &dadt);

#  ifdef __RAY_DIFFERENTIALS__
    if (dx || dy) {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (dx) {
        float dudx = sd->du.dx;
        float dvdx = sd->dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        *dx = dads * dsdx + dadt * dtdx;
      }
      if (dy) {
        float dudy = sd->du.dy;
        float dvdy = sd->dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        *dy = dads * dsdy + dadt * dtdy;
      }
    }
#  endif

    return a;
  }
  else
#endif /* __PATCH_EVAL__ */
      if (desc.element == ATTR_ELEMENT_FACE) {
    if (dx)
      *dx = 0.0f;
    if (dy)
      *dy = 0.0f;

    return kernel_tex_fetch(__attributes_float, desc.offset + subd_triangle_patch_face(kg, patch));
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    uint4 v = subd_triangle_patch_indices(kg, patch);

    float f0 = kernel_tex_fetch(__attributes_float, desc.offset + v.x);
    float f1 = kernel_tex_fetch(__attributes_float, desc.offset + v.y);
    float f2 = kernel_tex_fetch(__attributes_float, desc.offset + v.z);
    float f3 = kernel_tex_fetch(__attributes_float, desc.offset + v.w);

    if (subd_triangle_patch_num_corners(kg, patch) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef __RAY_DIFFERENTIALS__
    if (dx)
      *dx = sd->du.dx * a + sd->dv.dx * b - (sd->du.dx + sd->dv.dx) * c;
    if (dy)
      *dy = sd->du.dy * a + sd->dv.dy * b - (sd->du.dy + sd->dv.dy) * c;
#endif

    return sd->u * a + sd->v * b + (1.0f - sd->u - sd->v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    int corners[4];
    subd_triangle_patch_corners(kg, patch, corners);

    float f0 = kernel_tex_fetch(__attributes_float, corners[0] + desc.offset);
    float f1 = kernel_tex_fetch(__attributes_float, corners[1] + desc.offset);
    float f2 = kernel_tex_fetch(__attributes_float, corners[2] + desc.offset);
    float f3 = kernel_tex_fetch(__attributes_float, corners[3] + desc.offset);

    if (subd_triangle_patch_num_corners(kg, patch) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef __RAY_DIFFERENTIALS__
    if (dx)
      *dx = sd->du.dx * a + sd->dv.dx * b - (sd->du.dx + sd->dv.dx) * c;
    if (dy)
      *dy = sd->du.dy * a + sd->dv.dy * b - (sd->du.dy + sd->dv.dy) * c;
#endif

    return sd->u * a + sd->v * b + (1.0f - sd->u - sd->v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (dx)
      *dx = 0.0f;
    if (dy)
      *dy = 0.0f;

    return kernel_tex_fetch(__attributes_float, desc.offset);
  }
  else {
    if (dx)
      *dx = 0.0f;
    if (dy)
      *dy = 0.0f;

    return 0.0f;
  }
}

ccl_device_noinline float2 subd_triangle_attribute_float2(KernelGlobals *kg,
                                                          const ShaderData *sd,
                                                          const AttributeDescriptor desc,
                                                          float2 *dx2,
                                                          float2 *dy2)
{
  int patch = subd_triangle_patch(kg, sd);

#ifdef __PATCH_EVAL__
  if (desc.flags & ATTR_SUBDIVIDED) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * sd->u + dpdv * sd->v + uv[2];

    float2 a, dads, dadt;

    a = patch_eval_float2(kg, sd, desc.offset, patch, p.x, p.y, 0, &dads, &dadt);

#  ifdef __RAY_DIFFERENTIALS__
    if (dx2 || dy2) {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (dx2) {
        float dudx = sd->du.dx;
        float dvdx = sd->dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        *dx2 = dads * dsdx + dadt * dtdx;
      }
      if (dy2) {
        float dudy = sd->du.dy;
        float dvdy = sd->dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        *dy2 = dads * dsdy + dadt * dtdy;
      }
    }
#  endif

    return a;
  }
  else
#endif /* __PATCH_EVAL__ */
      if (desc.element == ATTR_ELEMENT_FACE) {
    if (dx2)
      *dx2 = make_float2(0.0f, 0.0f);
    if (dy2)
      *dy2 = make_float2(0.0f, 0.0f);

    return kernel_tex_fetch(__attributes_float2,
                            desc.offset + subd_triangle_patch_face(kg, patch));
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    uint4 v = subd_triangle_patch_indices(kg, patch);

    float2 f0 = kernel_tex_fetch(__attributes_float2, desc.offset + v.x);
    float2 f1 = kernel_tex_fetch(__attributes_float2, desc.offset + v.y);
    float2 f2 = kernel_tex_fetch(__attributes_float2, desc.offset + v.z);
    float2 f3 = kernel_tex_fetch(__attributes_float2, desc.offset + v.w);

    if (subd_triangle_patch_num_corners(kg, patch) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float2 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float2 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float2 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef __RAY_DIFFERENTIALS__
    if (dx2)
      *dx2 = sd->du.dx * a + sd->dv.dx * b - (sd->du.dx + sd->dv.dx) * c;
    if (dy2)
      *dy2 = sd->du.dy * a + sd->dv.dy * b - (sd->du.dy + sd->dv.dy) * c;
#endif

    return sd->u * a + sd->v * b + (1.0f - sd->u - sd->v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    int corners[4];
    subd_triangle_patch_corners(kg, patch, corners);

    float2 f0, f1, f2, f3;

    f0 = kernel_tex_fetch(__attributes_float2, corners[0] + desc.offset);
    f1 = kernel_tex_fetch(__attributes_float2, corners[1] + desc.offset);
    f2 = kernel_tex_fetch(__attributes_float2, corners[2] + desc.offset);
    f3 = kernel_tex_fetch(__attributes_float2, corners[3] + desc.offset);

    if (subd_triangle_patch_num_corners(kg, patch) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float2 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float2 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float2 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef __RAY_DIFFERENTIALS__
    if (dx2)
      *dx2 = sd->du.dx * a + sd->dv.dx * b - (sd->du.dx + sd->dv.dx) * c;
    if (dy2)
      *dy2 = sd->du.dy * a + sd->dv.dy * b - (sd->du.dy + sd->dv.dy) * c;
#endif

    return sd->u * a + sd->v * b + (1.0f - sd->u - sd->v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (dx2)
      *dx2 = make_float2(0.0f, 0.0f);
    if (dy2)
      *dy2 = make_float2(0.0f, 0.0f);

    return kernel_tex_fetch(__attributes_float2, desc.offset);
  }
  else {
    if (dx2)
      *dx2 = make_float2(0.0f, 0.0f);
    if (dy2)
      *dy2 = make_float2(0.0f, 0.0f);

    return make_float2(0.0f, 0.0f);
  }
}

ccl_device_noinline float3 subd_triangle_attribute_float3(KernelGlobals *kg,
                                                          const ShaderData *sd,
                                                          const AttributeDescriptor desc,
                                                          float3 *dx3,
                                                          float3 *dy3)
{
  int patch = subd_triangle_patch(kg, sd);

#ifdef __PATCH_EVAL__
  if (desc.flags & ATTR_SUBDIVIDED) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * sd->u + dpdv * sd->v + uv[2];

    float3 a, dads, dadt;
    a = patch_eval_float3(kg, sd, desc.offset, patch, p.x, p.y, 0, &dads, &dadt);

#  ifdef __RAY_DIFFERENTIALS__
    if (dx3 || dy3) {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (dx3) {
        float dudx = sd->du.dx;
        float dvdx = sd->dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        *dx3 = dads * dsdx + dadt * dtdx;
      }
      if (dy3) {
        float dudy = sd->du.dy;
        float dvdy = sd->dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        *dy3 = dads * dsdy + dadt * dtdy;
      }
    }
#  endif

    return a;
  }
  else
#endif /* __PATCH_EVAL__ */
      if (desc.element == ATTR_ELEMENT_FACE) {
    if (dx3)
      *dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if (dy3)
      *dy3 = make_float3(0.0f, 0.0f, 0.0f);

    return float4_to_float3(
        kernel_tex_fetch(__attributes_float3, desc.offset + subd_triangle_patch_face(kg, patch)));
  }
  else if (desc.element == ATTR_ELEMENT_VERTEX || desc.element == ATTR_ELEMENT_VERTEX_MOTION) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    uint4 v = subd_triangle_patch_indices(kg, patch);

    float3 f0 = float4_to_float3(kernel_tex_fetch(__attributes_float3, desc.offset + v.x));
    float3 f1 = float4_to_float3(kernel_tex_fetch(__attributes_float3, desc.offset + v.y));
    float3 f2 = float4_to_float3(kernel_tex_fetch(__attributes_float3, desc.offset + v.z));
    float3 f3 = float4_to_float3(kernel_tex_fetch(__attributes_float3, desc.offset + v.w));

    if (subd_triangle_patch_num_corners(kg, patch) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float3 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float3 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float3 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef __RAY_DIFFERENTIALS__
    if (dx3)
      *dx3 = sd->du.dx * a + sd->dv.dx * b - (sd->du.dx + sd->dv.dx) * c;
    if (dy3)
      *dy3 = sd->du.dy * a + sd->dv.dy * b - (sd->du.dy + sd->dv.dy) * c;
#endif

    return sd->u * a + sd->v * b + (1.0f - sd->u - sd->v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_CORNER) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    int corners[4];
    subd_triangle_patch_corners(kg, patch, corners);

    float3 f0, f1, f2, f3;

    f0 = float4_to_float3(kernel_tex_fetch(__attributes_float3, corners[0] + desc.offset));
    f1 = float4_to_float3(kernel_tex_fetch(__attributes_float3, corners[1] + desc.offset));
    f2 = float4_to_float3(kernel_tex_fetch(__attributes_float3, corners[2] + desc.offset));
    f3 = float4_to_float3(kernel_tex_fetch(__attributes_float3, corners[3] + desc.offset));

    if (subd_triangle_patch_num_corners(kg, patch) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float3 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float3 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float3 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef __RAY_DIFFERENTIALS__
    if (dx3)
      *dx3 = sd->du.dx * a + sd->dv.dx * b - (sd->du.dx + sd->dv.dx) * c;
    if (dy3)
      *dy3 = sd->du.dy * a + sd->dv.dy * b - (sd->du.dy + sd->dv.dy) * c;
#endif

    return sd->u * a + sd->v * b + (1.0f - sd->u - sd->v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (dx3)
      *dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if (dy3)
      *dy3 = make_float3(0.0f, 0.0f, 0.0f);

    return float4_to_float3(kernel_tex_fetch(__attributes_float3, desc.offset));
  }
  else {
    if (dx3)
      *dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if (dy3)
      *dy3 = make_float3(0.0f, 0.0f, 0.0f);

    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

ccl_device_noinline float4 subd_triangle_attribute_float4(KernelGlobals *kg,
                                                          const ShaderData *sd,
                                                          const AttributeDescriptor desc,
                                                          float4 *dx4,
                                                          float4 *dy4)
{
  int patch = subd_triangle_patch(kg, sd);

#ifdef __PATCH_EVAL__
  if (desc.flags & ATTR_SUBDIVIDED) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    float2 dpdu = uv[0] - uv[2];
    float2 dpdv = uv[1] - uv[2];

    /* p is [s, t] */
    float2 p = dpdu * sd->u + dpdv * sd->v + uv[2];

    float4 dads, dadt;

    float4 a = patch_eval_uchar4(kg, sd, desc.offset, patch, p.x, p.y, 0, &dads, &dadt);

#  ifdef __RAY_DIFFERENTIALS__
    if (dx4 || dy4) {
      float dsdu = dpdu.x;
      float dtdu = dpdu.y;
      float dsdv = dpdv.x;
      float dtdv = dpdv.y;

      if (dx4) {
        float dudx = sd->du.dx;
        float dvdx = sd->dv.dx;

        float dsdx = dsdu * dudx + dsdv * dvdx;
        float dtdx = dtdu * dudx + dtdv * dvdx;

        *dx4 = dads * dsdx + dadt * dtdx;
      }
      if (dy4) {
        float dudy = sd->du.dy;
        float dvdy = sd->dv.dy;

        float dsdy = dsdu * dudy + dsdv * dvdy;
        float dtdy = dtdu * dudy + dtdv * dvdy;

        *dy4 = dads * dsdy + dadt * dtdy;
      }
    }
#  endif
    return a;
  }
  else
#endif /* __PATCH_EVAL__ */
      if (desc.element == ATTR_ELEMENT_CORNER_BYTE) {
    float2 uv[3];
    subd_triangle_patch_uv(kg, sd, uv);

    int corners[4];
    subd_triangle_patch_corners(kg, patch, corners);

    float4 f0 = color_uchar4_to_float4(
        kernel_tex_fetch(__attributes_uchar4, corners[0] + desc.offset));
    float4 f1 = color_uchar4_to_float4(
        kernel_tex_fetch(__attributes_uchar4, corners[1] + desc.offset));
    float4 f2 = color_uchar4_to_float4(
        kernel_tex_fetch(__attributes_uchar4, corners[2] + desc.offset));
    float4 f3 = color_uchar4_to_float4(
        kernel_tex_fetch(__attributes_uchar4, corners[3] + desc.offset));

    if (subd_triangle_patch_num_corners(kg, patch) != 4) {
      f1 = (f1 + f0) * 0.5f;
      f3 = (f3 + f0) * 0.5f;
    }

    float4 a = mix(mix(f0, f1, uv[0].x), mix(f3, f2, uv[0].x), uv[0].y);
    float4 b = mix(mix(f0, f1, uv[1].x), mix(f3, f2, uv[1].x), uv[1].y);
    float4 c = mix(mix(f0, f1, uv[2].x), mix(f3, f2, uv[2].x), uv[2].y);

#ifdef __RAY_DIFFERENTIALS__
    if (dx4)
      *dx4 = sd->du.dx * a + sd->dv.dx * b - (sd->du.dx + sd->dv.dx) * c;
    if (dy4)
      *dy4 = sd->du.dy * a + sd->dv.dy * b - (sd->du.dy + sd->dv.dy) * c;
#endif

    return sd->u * a + sd->v * b + (1.0f - sd->u - sd->v) * c;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
    if (dx4)
      *dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if (dy4)
      *dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);

    return color_uchar4_to_float4(kernel_tex_fetch(__attributes_uchar4, desc.offset));
  }
  else {
    if (dx4)
      *dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if (dy4)
      *dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);

    return make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  }
}

CCL_NAMESPACE_END
