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

#ifndef _SVM_HSV_H_
#define _SVM_HSV_H_

CCL_NAMESPACE_BEGIN

ccl_device void svm_node_hsv(uint4 node, inout int offset)
{
  uint in_color_offset, fac_offset, out_color_offset;
  uint hue_offset, sat_offset, val_offset;
  svm_unpack_node_uchar3(node.y, (in_color_offset), (fac_offset), (out_color_offset));
  svm_unpack_node_uchar3(node.z, (hue_offset), (sat_offset), (val_offset));

  float fac = stack_load_float(fac_offset);
  float3 in_color = stack_load_float3(in_color_offset);
  float3 color = in_color;

  float hue = stack_load_float(hue_offset);
  float sat = stack_load_float(sat_offset);
  float val = stack_load_float(val_offset);
  color = rgb_to_hsv(color);
  /* remember: fmod doesn't work for negative numbers here */
  color.x = fmodf(color.x + hue + 0.5f, 1.0f);
  color.y = saturate(color.y * sat);
  color.z *= val;
  color = hsv_to_rgb(color);
  color.x = fac * color.x + (1.0f - fac) * in_color.x;
  color.y = fac * color.y + (1.0f - fac) * in_color.y;
  color.z = fac * color.z + (1.0f - fac) * in_color.z;
  /* Clamp color to prevent negative values caused by oversaturation. */
  color.x = max(color.x, 0.0f);
  color.y = max(color.y, 0.0f);
  color.z = max(color.z, 0.0f);
  if (stack_valid(out_color_offset))
    stack_store_float3(out_color_offset, color);
}

CCL_NAMESPACE_END

#endif /* _SVM_HSV_H_ */
