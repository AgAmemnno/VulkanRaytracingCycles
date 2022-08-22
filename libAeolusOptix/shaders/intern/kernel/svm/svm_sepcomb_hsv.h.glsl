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

CCL_NAMESPACE_BEGIN

ccl_device void svm_node_combine_hsv(
                                     uint hue_in,
                                     uint saturation_in,
                                     uint value_in,
                                     inout int offset)
{
  uint4 node1 = read_node(offset);
  uint color_out = node1.y;

  float hue = stack_load_float(hue_in);
  float saturation = stack_load_float(saturation_in);
  float value = stack_load_float(value_in);

  /* Combine, and convert back to RGB */
  float3 color = hsv_to_rgb(make_float3(hue, saturation, value));

  if (stack_valid(color_out))
    stack_store_float3(color_out, color);
}

ccl_device void svm_node_separate_hsv(
                                      uint color_in,
                                      uint hue_out,
                                      uint saturation_out,
                                      inout int offset)
{
  uint4 node1 = read_node(offset);
  uint value_out = node1.y;

  float3 color = stack_load_float3(color_in);

  /* Convert to HSV */
  color = rgb_to_hsv(color);

  if (stack_valid(hue_out))
    stack_store_float(hue_out, color.x);
  if (stack_valid(saturation_out))
    stack_store_float(saturation_out, color.y);
  if (stack_valid(value_out))
    stack_store_float(value_out, color.z);
}

CCL_NAMESPACE_END
