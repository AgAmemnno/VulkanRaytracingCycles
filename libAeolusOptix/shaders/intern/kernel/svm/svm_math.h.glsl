#ifndef _SVM_MATH_H_
#define  _SVM_MATH_H_
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
#include "kernel/svm/svm_math_util.h.glsl"

CCL_NAMESPACE_BEGIN

#define svm_node_math(type,inputs_stack_offsets, result_stack_offset,offset)\
{\
  uint a_stack_offset, b_stack_offset, c_stack_offset;\
  svm_unpack_node_uchar3(inputs_stack_offsets, (a_stack_offset), (b_stack_offset), (c_stack_offset));\
  stack_store_float(result_stack_offset, svm_math(NodeMathType(type), stack_load_float(a_stack_offset), stack_load_float(b_stack_offset), stack_load_float(c_stack_offset)));\
}

#define svm_node_vector_math(type,inputs_stack_offsets,outputs_stack_offsets,offset)\
{\
  uint value_stack_offset, vector_stack_offset;\
  uint a_stack_offset, b_stack_offset, scale_stack_offset;\
  svm_unpack_node_uchar3(inputs_stack_offsets, (a_stack_offset), (b_stack_offset), (scale_stack_offset));\
  svm_unpack_node_uchar2(outputs_stack_offsets, (value_stack_offset), (vector_stack_offset));\
  float3 c = make_float3(0.0f, 0.0f, 0.0f);\
  float value;float3 vector;\
  if (type == NODE_VECTOR_MATH_WRAP) { uint4 extra_node = read_node(offset);c = stack_load_float3(extra_node.x);}\
  svm_vector_math((value), (vector), NodeVectorMathType(type), stack_load_float3(a_stack_offset),stack_load_float3(b_stack_offset), c,stack_load_float(scale_stack_offset));\
  if (stack_valid(value_stack_offset))stack_store_float(value_stack_offset, value);\
  if (stack_valid(vector_stack_offset))stack_store_float3(vector_stack_offset, vector);\
}

CCL_NAMESPACE_END
#endif