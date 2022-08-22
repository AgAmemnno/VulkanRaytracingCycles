#ifndef _SVM_MAP_RANGE_H_
#define _SVM_MAP_RANGE_H_
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

/* Map Range Node */

ccl_device_inline float smootherstep(float edge0, float edge1, float x)
{
  x = clamp(safe_divide((x - edge0), (edge1 - edge0)), 0.0f, 1.0f);
  return x * x * x * (x * (x * 6.0f - 15.0f) + 10.0f);
}

ccl_device void svm_node_map_range(
                                   uint value_stack_offset,
                                   uint parameters_stack_offsets,
                                   uint results_stack_offsets,
                                   inout int offset)
{
  uint from_min_stack_offset, from_max_stack_offset, to_min_stack_offset, to_max_stack_offset;
  uint type_stack_offset, steps_stack_offset, result_stack_offset;
  svm_unpack_node_uchar4(parameters_stack_offsets, (from_min_stack_offset), (from_max_stack_offset),(to_min_stack_offset),(to_max_stack_offset));

  svm_unpack_node_uchar3(results_stack_offsets, (type_stack_offset), (steps_stack_offset), (result_stack_offset));
  uint4 defaults = read_node(offset);
  uint4 defaults2 = read_node(offset);
  float value = stack_load_float(value_stack_offset);
  float from_min = stack_load_float_default(from_min_stack_offset, defaults.x);
  float from_max = stack_load_float_default(from_max_stack_offset, defaults.y);
  float to_min = stack_load_float_default(to_min_stack_offset, defaults.z);
  float to_max = stack_load_float_default(to_max_stack_offset, defaults.w);
  float steps = stack_load_float_default(steps_stack_offset, defaults2.x);
  float result;
  if (from_max != from_min) {
    float factor = value;
    switch (type_stack_offset) {
      default:
      case NODE_MAP_RANGE_LINEAR:
        factor = (value - from_min) / (from_max - from_min);
        break;
      case NODE_MAP_RANGE_STEPPED: {
        factor = (value - from_min) / (from_max - from_min);
        factor = (steps > 0.0f) ? floorf(factor * (steps + 1.0f)) / steps : 0.0f;
        break;
      }
      case NODE_MAP_RANGE_SMOOTHSTEP: {
        factor = (from_min > from_max) ? 1.0f - smoothstep(from_max, from_min, factor) :
                                         smoothstep(from_min, from_max, factor);
        break;
      }
      case NODE_MAP_RANGE_SMOOTHERSTEP: {
        factor = (from_min > from_max) ? 1.0f - smootherstep(from_max, from_min, factor) :
                                         smootherstep(from_min, from_max, factor);
        break;
      }
    }
    result = to_min + factor * (to_max - to_min);
  }
  else {
    result = 0.0f;
  }
  stack_store_float(result_stack_offset, result);
}

CCL_NAMESPACE_END

#endif