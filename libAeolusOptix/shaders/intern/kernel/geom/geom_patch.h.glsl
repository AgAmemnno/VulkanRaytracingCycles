#ifndef _GEOM_PATCH_H_
#define _GEOM_PATCH_H_

/*
 * Based on code from OpenSubdiv released under this license:
 *
 * Copyright 2013 Pixar
 *
 * Licensed under the Apache License, Version 2.0 (the "Apache License")
 * with the following modification; you may not use this file except in_rsv
 * compliance with the Apache License and the following modification to it:
 * Section 6. Trademarks. is deleted and replaced with:
 *
 * 6. Trademarks. This License does not grant permission to use the trade
 *   names, trademarks, service marks, or product names of the Licensor
 *   and its affiliates, except as required to comply with Section 4c(of)
 *   the License and to reproduce the content of the NOTICE file.

 *
 * You may obtain a copy of the Apache License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in_rsv writing, software
 * distributed under the Apache License with the above modification is
 * distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the Apache License for the specific
 * language governing permissions and limitations under the Apache License.
 */
#include "kernel/geom/geom_object.h.glsl"

CCL_NAMESPACE_BEGIN

struct PatchHandle {
  int array_index, patch_index, vert_index;
} ;


ccl_device_inline int patch_map_resolve_quadrant(float median, inout float u, inout float v)
{
  int quadrant = -1;

  if (u < median) {
    if (v < median) {
      quadrant = 0;
    }
    else {
      quadrant = 1;
      v -= median;
    }
  }
  else {
    if (v < median) {
      quadrant = 3;
    }
    else {
      quadrant = 2;
      v -= median;
    }
    u -= median;
  }

  return quadrant;
}

/* retrieve PatchHandle from patch_rsv coords */

ccl_device_inline PatchHandle
patch_map_find_patch( int object, int patch_rsv, float u, float v)
{
  PatchHandle handle;

  kernel_assert("assert geom patch at 71 ",(u >= 0.0f) && (u <= 1.0f) && (v >= 0.0f) && (v <= 1.0f));

  int node = int((object_patch_map_offset(object) + patch_rsv) / 2);
  float median = 0.5f;

  for (int depth = 0; depth < 0xff; depth++) {
    float delta = median * 0.5f;

    int quadrant = patch_map_resolve_quadrant(median, (u), (v));


    kernel_assert("assert geom patch at 84 ",quadrant >= 0);

    uint child = kernel_tex_fetch(_patches, node + quadrant);

    /* is the quadrant a hole? */
    if (!(bool(child & PATCH_MAP_NODE_IS_SET))) {
      handle.array_index = -1;
      return handle;
    }

    uint index = child & PATCH_MAP_NODE_INDEX_MASK;

    if (bool(child & PATCH_MAP_NODE_IS_LEAF)
) {
      handle.array_index = int(kernel_tex_fetch(_patches, index + 0));
      handle.patch_index = int(kernel_tex_fetch(_patches, index + 1));
      handle.vert_index  = int(kernel_tex_fetch(_patches, index + 2));

      return handle;
    }
    else {
      node = int(index);
    }

    median = delta;
  }

  /* no leaf found */
  kernel_assert("assert geom patch at 112 ",false);

  handle.array_index = -1;
  return handle;
}

#define patch_eval_bspline_weights(t,point,deriv) {\
  float inv_6 = 1.0f / 6.0f;float t2 = t * t;float t3 = t * t2;\
  point[0] = inv_6 * (1.0f - 3.0f * (t - t2) - t3);\
  point[1] = inv_6 * (4.0f - 6.0f * t2 + 3.0f * t3);\
  point[2] = inv_6 * (1.0f + 3.0f * (t + t2 - t3));\
  point[3] = inv_6 * t3;\
  deriv[0] = -0.5f * t2 + t - 0.5f;\
  deriv[1] = 1.5f * t2 - 2.0f * t;\
  deriv[2] = -1.5f * t2 + t + 0.5f;\
  deriv[3] = 0.5f * t2;\
}

#define patch_eval_adjust_boundary_weights(bits,s,t) \
{\
  int boundary = int((bits >> 8) & 0xf);\
  if (bool(boundary & 1)) {t[2] -= t[0];t[1] += 2 * t[0];t[0] = 0;}\
  if (bool(boundary & 2)) {s[1] -= s[3];s[2] += 2 * s[3];s[3] = 0;}\
  if (bool(boundary & 4)) {t[1] -= t[3];t[2] += 2 * t[3];t[3] = 0;}\
  if (bool(boundary & 8)) {s[2] -= s[0];s[1] += 2 * s[0];s[0] = 0;}\
}

#define patch_eval_depth(patch_bits) int(patch_bits & 0xf)

#define patch_eval_param_fraction(frac,patch_bits) {\
  bool non_quad_root = bool((patch_bits >> 4) & 0x1);\
  int depth = patch_eval_depth(patch_bits);\
  if (non_quad_root) {frac =  1.0f / float(1 << (depth - 1));}\
  else { frac =  1.0f / float(1 << depth);}}

#define patch_eval_normalize_coords(patch_bits,  u,  v) {\
  float frac;patch_eval_param_fraction(frac,patch_bits);\
  int iu = int((patch_bits >> 22) & 0x3ff);\
  int iv = int((patch_bits >> 12) & 0x3ff);\
  float pu = float(iu * frac);float pv = float(iv * frac);\
  u = (u - pu) / frac;v = (v - pv) / frac;\
}

/* retrieve patch_rsv control indices */
/* XXX: regular patches only */
#define patch_eval_indices( handle, channel,indices)  \
{\
  int index_base = int(kernel_tex_fetch(_patches, handle.array_index + 2) + handle.vert_index);\
  for (int i = 0; i < 16; i++) {indices[i] = int(kernel_tex_fetch(_patches, index_base + i));}\
}
/* evaluate patch_rsv basis functions */
#define patch_eval_basis(handle,u,v,weights,weights_du,weights_dv) {\
  uint patch_bits = kernel_tex_fetch(_patches, handle.patch_index + 1);\
  float d_scale = 1 << patch_eval_depth(patch_bits);\
  bool non_quad_root = bool((patch_bits >> 4) & 0x1);\
  if (non_quad_root) {d_scale *= 0.5f;}\
  patch_eval_normalize_coords(patch_bits, (u), (v));\
  float s[4], t[4], ds[4], dt[4];\
  patch_eval_bspline_weights(u, s, ds);\
  patch_eval_bspline_weights(v, t, dt);\
  patch_eval_adjust_boundary_weights(patch_bits, s, t);\
  patch_eval_adjust_boundary_weights(patch_bits, ds, dt);\
  for (int k = 0; k < 4; k++) {for (int l = 0; l < 4; l++) { weights[4 * k + l] = s[l] * t[k];weights_du[4 * k + l] = ds[l] * t[k] * d_scale;weights_dv[4 * k + l] = s[l] * dt[k] * d_scale;}}\
}

/* generic function for evaluating indices and weights from patch_rsv coords */
#define  patch_eval_control_verts(num_control, object,patch_rsv,u,v,channel,indices,weights,weights_du,weights_dv) {\
  PatchHandle handle = patch_map_find_patch(object, patch_rsv, u, v);\
  kernel_assert("assert geom patch 291 ",handle.array_index >= 0);\
  patch_eval_indices((handle), channel, indices); num_control = 16;\
  patch_eval_basis((handle), u, v, weights, weights_du, weights_dv);\
}

/* functions for evaluating attributes on patches */

ccl_device float patch_eval_float(
                                  int offset,
                                  int patch_rsv,
                                  float u,
                                  float v,
                                  int channel,
                                  inout float du,
                                  inout float dv)
{
  int indices[PATCH_MAX_CONTROL_VERTS];
  float weights[PATCH_MAX_CONTROL_VERTS];
  float weights_du[PATCH_MAX_CONTROL_VERTS];
  float weights_dv[PATCH_MAX_CONTROL_VERTS];

  int num_control;
  patch_eval_control_verts(
    num_control, GSD.object, patch_rsv, u, v, channel, indices, weights, weights_du, weights_dv);

  float val = 0.0f;
  if (!isNULL(du))

    du = 0.0f;
  if (!isNULL(dv))

    dv = 0.0f;

  for (int i = 0; i < num_control; i++) {
    float v = kernel_tex_fetch(_attributes_float, offset + indices[i]);

    val += v * weights[i];
    if (!isNULL(du))

      du += v * weights_du[i];
    if (!isNULL(dv))

      dv += v * weights_dv[i];
  }

  return val;
}


ccl_device float2 patch_eval_float2(
                                    int offset,
                                    int patch_rsv,
                                    float u,
                                    float v,
                                    int channel,
                                    inout float2 du2,
                                    inout float2 dv2)
{
  int indices[PATCH_MAX_CONTROL_VERTS];
  float weights[PATCH_MAX_CONTROL_VERTS];
  float weights_du[PATCH_MAX_CONTROL_VERTS];
  float weights_dv[PATCH_MAX_CONTROL_VERTS];

  int num_control;
  patch_eval_control_verts(
     num_control, GSD.object, patch_rsv, u, v, channel, indices, weights, weights_du, weights_dv);

  float2 val = make_float2(0.0f, 0.0f);
  if (!isNULL2(du2))

    du2 = make_float2(0.0f, 0.0f);
  if (!isNULL2(dv2))

    dv2 = make_float2(0.0f, 0.0f);

  for (int i = 0; i < num_control; i++) {
    float2 v = kernel_tex_fetch(_attributes_float2, offset + indices[i]);

    val += v * weights[i];
    if (!isNULL2(du2))du2 += v * weights_du[i];
    if (!isNULL2(dv2))dv2 += v * weights_dv[i];
  }

  return val;
}


ccl_device float3 patch_eval_float3(
                                    int offset,
                                    int patch_rsv,
                                    float u,
                                    float v,
                                    int channel,
                                    inout float3 du3,
                                    inout float3 dv3)
{
  int indices[PATCH_MAX_CONTROL_VERTS];
  float weights[PATCH_MAX_CONTROL_VERTS];
  float weights_du[PATCH_MAX_CONTROL_VERTS];
  float weights_dv[PATCH_MAX_CONTROL_VERTS];

  int num_control;
  patch_eval_control_verts( num_control, GSD.object, patch_rsv, u, v, channel, indices, weights, weights_du, weights_dv);
  float3 val = make_float3(0.0f, 0.0f, 0.0f);
  if (!isNULL3(du3))
    du3 = make_float3(0.0f, 0.0f, 0.0f);
  if (!isNULL3(dv3))
    dv3 = make_float3(0.0f, 0.0f, 0.0f);
  for (int i = 0; i < num_control; i++) {
    float3 v = float4_to_float3(kernel_tex_fetch(_attributes_float3, offset + indices[i]));
    val += v * weights[i];
    if (!isNULL3(du3))
      du3 += v * weights_du[i];
    if (!isNULL3(dv3))
      dv3 += v * weights_dv[i];
  }
  return val;
}



ccl_device float4 patch_eval_uchar4(
                                    int offset,
                                    int patch_rsv,
                                    float u,
                                    float v,
                                    int channel,
                                    inout float4 du4,
                                    inout float4 dv4)
{
  int indices[PATCH_MAX_CONTROL_VERTS];
  float weights[PATCH_MAX_CONTROL_VERTS];
  float weights_du[PATCH_MAX_CONTROL_VERTS];
  float weights_dv[PATCH_MAX_CONTROL_VERTS];

  int num_control;
  patch_eval_control_verts(
     num_control, GSD.object, patch_rsv, u, v, channel, indices, weights, weights_du, weights_dv);

  float4 val = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  if (!isNULL4(du4))

    du4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  if (!isNULL4(dv4))

    dv4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);

  for (int i = 0; i < num_control; i++) {
    float4 v = color_uchar4_to_float4(kernel_tex_fetch(_attributes_uchar4, offset + indices[i]));

    val += v * weights[i];
    if (!isNULL4(du4))

      du4 += v * weights_du[i];
    if (!isNULL4(dv4))

      dv4 += v * weights_dv[i];
  }

  return val;
}







CCL_NAMESPACE_END
#endif