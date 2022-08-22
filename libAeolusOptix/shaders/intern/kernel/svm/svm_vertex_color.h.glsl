#ifndef _SVM_VERTEX_COLOR_H_
#define _SVM_VERTEX_COLOR_H_
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
#include "kernel/svm/svm_callable.glsl"
CCL_NAMESPACE_BEGIN


#ifdef NODE_Caller

ccl_device void svm_node_vertex_color(
                                      uint layer_id,
                                      uint color_offset,
                                      uint alpha_offset)
{

SVM_VC_SD(GSD,nio,layer_id);
nio.type = SVM_NODE_VC;
EXECUTION_GEOM;

uint desc_offset = SVM_GEOM_RET_DESC_OFFSET;
if (desc_offset != ATTR_STD_NOT_FOUND) {
  vec4 vertex_color           = SVM_GEOM_RET_VC;
  stack_store_float3(color_offset, vertex_color);
  stack_store_float(alpha_offset , vertex_color.w);
}
else {
  stack_store_float3(color_offset, make_float3(0.0f, 0.0f, 0.0f));
  stack_store_float(alpha_offset, 0.0f);
}
}

#define  func_vertex_color_bump {\
  SVM_VC_SD(GSD,nio,layer_id);\
  SVM_VC_SD_DUDV(GSD,nio);\
  EXECUTION_GEOM;\
  uint desc_offset = SVM_GEOM_RET_DESC_OFFSET;\
  if (desc_offset != ATTR_STD_NOT_FOUND) {\
     vec4 vertex_color           = SVM_GEOM_RET_VC;\
     stack_store_float3(color_offset, vertex_color);\
     stack_store_float(alpha_offset , vertex_color.w);\
  }\
  else {\
    stack_store_float3(color_offset, make_float3(0.0f, 0.0f, 0.0f));\
    stack_store_float(alpha_offset, 0.0f);\
  }\
}

void svm_node_vertex_color_bump_dx(
                                  uint layer_id,
                                  uint color_offset,
                                  uint alpha_offset)
{
    nio.type = SVM_NODE_VC_BUMP_DX;
    func_vertex_color_bump
}



void svm_node_vertex_color_bump_dy(
                                  uint layer_id,
                                  uint color_offset,
                                  uint alpha_offset)
{
    nio.type = SVM_NODE_VC_BUMP_DY;
    func_vertex_color_bump
}


#endif

#ifdef NODE_Callee
ccl_device void svm_node_vertex_color()
{

   uint layer_id = SVM_GEOM_VC_LAYERID;

  AttributeDescriptor descriptor = find_attribute(layer_id);
  float4 vertex_color;
  if (descriptor.offset != ATTR_STD_NOT_FOUND) {
    vertex_color = primitive_attribute_float4(descriptor, null_flt4, null_flt4);
    SVM_GEOM_VC_RET(vertex_color);
  }
  SVM_GEOM_VC_RET_DESC_OFFSET(descriptor.offset);
}

void svm_node_vertex_color_bump_dx()
{
  uint layer_id = SVM_GEOM_VC_LAYERID;
  AttributeDescriptor descriptor = find_attribute(layer_id);
  if (descriptor.offset != ATTR_STD_NOT_FOUND) {
    float4 dx;
    float4 vertex_color = primitive_attribute_float4(descriptor, (dx), null_flt4);
    vertex_color += dx;
    SVM_GEOM_VC_RET(vertex_color);
  }
  SVM_GEOM_VC_RET_DESC_OFFSET(descriptor.offset);
}
void svm_node_vertex_color_bump_dy()
{
  uint layer_id = SVM_GEOM_VC_LAYERID;
  AttributeDescriptor descriptor = find_attribute(layer_id);
  if (descriptor.offset != ATTR_STD_NOT_FOUND) {
    float4 dy;
    float4 vertex_color = primitive_attribute_float4(descriptor, null_flt4 ,(dy));
    vertex_color += dy;
    SVM_GEOM_VC_RET(vertex_color);
  }
  SVM_GEOM_VC_RET_DESC_OFFSET(descriptor.offset);
}
#endif

CCL_NAMESPACE_END
#endif
