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

/* Checker */

#define  svm_checker(ret,p)\
{\
  p.x = (p.x + 0.000001f) * 0.999999f;\
  p.y = (p.y + 0.000001f) * 0.999999f;\
  p.z = (p.z + 0.000001f) * 0.999999f;\
  int xi = abs(float_to_int(floorf(p.x)));\
  int yi = abs(float_to_int(floorf(p.y)));\
  int zi = abs(float_to_int(floorf(p.z)));\
  ret =  ((xi % 2 == yi % 2) == bool(zi % 2)) ? 1.0f : 0.0f;\
}

ccl_device void svm_node_tex_checker(uint4 node)
{
  uint co_offset, color1_offset, color2_offset, scale_offset;
  uint color_offset, fac_offset;
  svm_unpack_node_uchar4(node.y, (co_offset), (color1_offset), (color2_offset), (scale_offset));
  svm_unpack_node_uchar2(node.z, (color_offset), (fac_offset));
  float3 co = stack_load_float3(co_offset);
  float3 color1 = stack_load_float3(color1_offset);
  float3 color2 = stack_load_float3(color2_offset);
  float scale = stack_load_float_default(scale_offset, node.w);
  float f;
  float3 cscale = (co * scale);
  svm_checker(f,cscale);
  if (stack_valid(color_offset)){
    cscale = (f == 1.0f) ? color1 : color2;
    stack_store_float3(color_offset, cscale);
  }
  if (stack_valid(fac_offset))
    stack_store_float(fac_offset, f);
}

CCL_NAMESPACE_END
