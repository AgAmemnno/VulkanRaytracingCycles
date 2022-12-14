#ifndef _SVM_RAMP_H_
#define _SVM_RAMP_H_
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

#include "kernel/svm/svm_util.h.glsl"

CCL_NAMESPACE_BEGIN

/* NOTE: svm_ramp.h, svm_ramp_util.h and node_ramp_util.h must stay consistent */

float4 rgb_ramp_lookup(
    int offset, float f, bool interpolate, bool extrapolate, int table_size)
{
  if ((f < 0.0f || f > 1.0f) && extrapolate) {
    float4 t0, dy;
    if (f < 0.0f) {
      t0 = fetch_node_float(offset);
      dy = t0 - fetch_node_float(offset + 1);
      f = -f;
    }
    else {
      t0 = fetch_node_float(offset + table_size - 1);
      dy = t0 - fetch_node_float(offset + table_size - 2);
      f = f - 1.0f;
    }
    return t0 + dy * f * (table_size - 1);
  }

  f = saturate(f) * (table_size - 1);

  /* clamp int as well in_rsv case of NaN */
  int i = clamp(float_to_int(f), 0, table_size - 1);
  float t = f - float(i);

  float4 a = fetch_node_float(offset + i);

  if (interpolate && t > 0.0f)
    a = (1.0f - t) * a + t * fetch_node_float(offset + i + 1);

  return a;
}

ccl_device void svm_node_rgb_ramp(uint4 node, inout int offset)
{
  uint fac_offset, color_offset, alpha_offset;
  uint interpolate = node.z;

  svm_unpack_node_uchar3(node.y, (fac_offset), (color_offset), (alpha_offset));
  uint table_size = read_node(offset).x;
  float fac = stack_load_float(fac_offset);
  float4 color = rgb_ramp_lookup(offset, fac, bool(interpolate), false, int(table_size));
  if (stack_valid(color_offset))
    stack_store_float3(color_offset, float4_to_float3(color));
  if (stack_valid(alpha_offset))
    stack_store_float(alpha_offset, color.w);
  offset += int(table_size);
}


ccl_device void svm_node_curves( uint4 node, inout int offset)
{
  uint fac_offset, color_offset, out_offset;
  svm_unpack_node_uchar3(node.y, (fac_offset), (color_offset), (out_offset));
  uint table_size = read_node(offset).x;

  float fac = stack_load_float(fac_offset);
  float3 color = stack_load_float3(color_offset);
  const float min_x = _uint_as_float(node.z), max_x = _uint_as_float(node.w);
  const float range_x = max_x - min_x;
  const float3 relpos = (color - make_float3(min_x, min_x, min_x)) / range_x;
  float r = rgb_ramp_lookup(offset, relpos.x, true, true, int(table_size)).x;
  float g = rgb_ramp_lookup(offset, relpos.y, true, true, int(table_size)).y;
  float b = rgb_ramp_lookup(offset, relpos.z, true, true, int(table_size)).z;

  color = (1.0f - fac) * color + fac * make_float3(r, g, b);
  stack_store_float3(out_offset, color);
  offset += int(table_size);

}

CCL_NAMESPACE_END

#endif /* _SVM_RAMP_H_ */
