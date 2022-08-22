#ifndef _SVM_MIX_H_
#define _SVM_MIX_H_

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
//#define NOT_CALL

#ifdef NOT_CALL
#include "kernel/svm/svm_color_util.h.glsl"
/* Node */
ccl_device void svm_node_mix(
                             uint fac_offset,
                             uint c1_offset,
                             uint c2_offset,
                             inout int offset)
{
  // read extra data 
  uint4 node1 = read_node(offset);
  float fac = stack_load_float(fac_offset);
  float3 c1 = stack_load_float3(c1_offset);
  float3 c2 = stack_load_float3(c2_offset);
  float3 result = svm_mix(NodeMix(node1.y), fac, c1, c2);
  stack_store_float3(node1.z, result);

}
#else

#define NODE_UTILS_TYPE 0
#define NODE_UTILS_FAC 1
#define NODE_UTILS_C1  2
#define NODE_UTILS_C2  5
#define NODE_UTILS_RESULT  NODE_UTILS_C1
ccl_device void svm_node_mix(
                             uint fac_offset,
                             uint c1_offset,
                             uint c2_offset,
                             inout int offset)
{
  // read extra data 
  uint4 node1                 = read_node(offset);
  nio.type                    = CALLEE_UTILS_MIX;
  nio.data[NODE_UTILS_TYPE]   = uintBitsToFloat(NodeMix(node1.y));
  stack_load_float_nio(fac_offset,NODE_UTILS_FAC)
  stack_load_float3_nio(c1_offset,NODE_UTILS_C1)
  stack_load_float3_nio(c2_offset,NODE_UTILS_C2)
  EXECUTION_UTILS;
  stack_store_float3_nio(node1.z,NODE_UTILS_RESULT)
}


#define svm_node_brightness(in_color, out_color, node)\
{\
  if (stack_valid(out_color)){\
  nio.type                    = CALLEE_UTILS_BRI;\
  uint bright_offset, contrast_offset;\
  stack_load_float3_nio(in_color,NODE_UTILS_C1)\
  svm_unpack_node_uchar2(node, (bright_offset), (contrast_offset));\
  stack_load_float_nio(bright_offset,NODE_UTILS_FAC)\
  stack_load_float_nio(contrast_offset,NODE_UTILS_C2)\
  EXECUTION_UTILS;\
  stack_store_float3_nio(out_color, NODE_UTILS_RESULT);}\
}

#endif
CCL_NAMESPACE_END

#endif