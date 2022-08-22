#ifndef _SVM_ATTR_H_
#define _SVM_ATTR_H_
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

ccl_device void svm_node_attr(uint4 node)
{


SVM_GEOM_SD_NODE(node);
SVM_GEOM_SD(sd,nio);
nio.type = SVM_NODE_ATTR;

EXECUTION_GEOM;

  NodeAttributeType type = SVM_GEOM_RET_TYPE;
  uint out_offset = SVM_GEOM_RET_OUTOFFSET;
  uint desc_type  = SVM_GEOM_RET_DESCTYPE;



  /* fetch and store attribute */
  if (desc_type == NODE_ATTR_FLOAT) {

    float f =  SVM_GEOM_RET_ATTR.x;

    if (type == NODE_ATTR_FLOAT) {
      stack_store_float( out_offset, f);
    }
    else {
      stack_store_float3( out_offset, make_float3(f, f, f));
    }
  }
  else if (desc_type == NODE_ATTR_FLOAT2) {
    float2 f =  SVM_GEOM_RET_ATTR.xy;

    if (type == NODE_ATTR_FLOAT) {
      stack_store_float( out_offset, f.x);
    }
    else {
      stack_store_float3( out_offset, make_float3(f.x, f.y, 0.0f));
    }
  }
  else if (desc_type == NODE_ATTR_RGBA) {
    float4 f =  SVM_GEOM_RET_ATTR;

    if (type == NODE_ATTR_FLOAT) {
      stack_store_float( out_offset, average(float4_to_float3(f)));
    }
    else {
      stack_store_float3( out_offset, float4_to_float3(f));
    }
  }
  else {
    float3 f =  SVM_GEOM_RET_ATTR;

    if (type == NODE_ATTR_FLOAT) {
      stack_store_float(out_offset, average(f));
    }
    else {
      stack_store_float3( out_offset, f);
    }
  }
}


ccl_device void svm_node_attr_bump_dx(uint4 node)
{

SVM_GEOM_SD_NODE(node);
SVM_GEOM_SD(sd,nio);
nio.type = SVM_NODE_BUMP_DX;

EXECUTION_GEOM;
  
  NodeAttributeType type = SVM_GEOM_RET_TYPE;
  uint out_offset = SVM_GEOM_RET_OUTOFFSET;
  uint desc_type  = SVM_GEOM_RET_DESCTYPE;
  vec4 f = SVM_GEOM_RET_ATTR;
  /* fetch and store attribute */
  if (desc_type == NODE_ATTR_FLOAT) {

    if (type == NODE_ATTR_FLOAT) {
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset, f);
    }
  }
  else if (desc_type == NODE_ATTR_FLOAT2) {
    if (type == NODE_ATTR_FLOAT) {
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset, f);
    }
  }
  else if (desc_type == NODE_ATTR_RGBA) {
    if (type == NODE_ATTR_FLOAT) {
 
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset, f);
    }
  }
  else {
    if (type == NODE_ATTR_FLOAT) {
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset, f);
    }
  }


}

ccl_device void svm_node_attr_bump_dy(uint4 node)
{

SVM_GEOM_SD_NODE(node);
SVM_GEOM_SD(sd,nio);
nio.type = SVM_NODE_BUMP_DY;

EXECUTION_GEOM;
  
  NodeAttributeType type = SVM_GEOM_RET_TYPE;
  uint out_offset = SVM_GEOM_RET_OUTOFFSET;
  uint desc_type  = SVM_GEOM_RET_DESCTYPE;
  vec4 f = SVM_GEOM_RET_ATTR;
  /* fetch and store attribute */
  if (desc_type == NODE_ATTR_FLOAT) {

    if (type == NODE_ATTR_FLOAT) {
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset, f.xyz);
    }
  }
  else if (desc_type == NODE_ATTR_FLOAT2) {
    if (type == NODE_ATTR_FLOAT) {
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset,f);
    }
  }
  else if (desc_type == NODE_ATTR_RGBA) {
    if (type == NODE_ATTR_FLOAT) {
 
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset, f);
    }
  }
  else {
    if (type == NODE_ATTR_FLOAT) {
      stack_store_float(out_offset, f.x);
    }
    else {
      stack_store_float3(out_offset, f);
    }
  }


}

ccl_device void svm_node_enter_bump_eval(uint offset)
{
  /* save state */
  stack_store_float3(offset + 0, sd.P);
  stack_store_float3(offset + 3, sd.dP.dx);
  stack_store_float3(offset + 6, sd.dP.dy);

SVM_GEOM_SD(sd,nio);
nio.type = SVM_NODE_BUMP_ENTRY;
EXECUTION_GEOM;

if (SVM_GEOM_RET_OUTOFFSET != ATTR_STD_NOT_FOUND) {
    float3 P    = SVM_GEOM_RET_P;
    float3 dPdx = SVM_GEOM_RET_dPdx;
    float3 dPdy = SVM_GEOM_RET_dPdy;
    object_position_transform(P);
    object_dir_transform(dPdx);
    object_dir_transform(dPdy);
    sd.P = P;
    sd.dP.dx = dPdx;
    sd.dP.dy = dPdy;
}

}

ccl_device void svm_node_leave_bump_eval(uint offset)
{
  /* restore state */
  sd.P = stack_load_float3(offset + 0);
  sd.dP.dx = stack_load_float3(offset + 3);
  sd.dP.dy = stack_load_float3(offset + 6);
}

#endif


#ifdef NODE_Callee

/* Attribute Node */

ccl_device AttributeDescriptor svm_node_attr_init(  inout NodeAttributeType type, inout uint out_offset)
{


  out_offset = GSD.node.z;
  type = NodeAttributeType(GSD.node.w);
  AttributeDescriptor desc;
  if (GSD.object != OBJECT_NONE) {
    desc = find_attribute(GSD.node.y);
    if (desc.offset == ATTR_STD_NOT_FOUND) {
      desc = attribute_not_found();
      desc.offset = 0;
      desc.type = NodeAttributeType(GSD.node.w);
    }
  }
  else {
    /* background */
    desc = attribute_not_found();
    desc.offset = 0;
    desc.type = NodeAttributeType(GSD.node.w);
  }
  return desc;
}


ccl_device void svm_node_attr()
{

  NodeAttributeType type = NODE_ATTR_FLOAT;
  uint out_offset = 0;
  AttributeDescriptor desc = svm_node_attr_init( (type), (out_offset));
  
  SVM_GEOM_RET_DESCTYPE(desc.type);
  SVM_GEOM_RET_TYPE = type;
  SVM_GEOM_RET_OUTOFFSET(out_offset);


  vec4 ret;

  /* fetch and store attribute */
  if (desc.type == NODE_ATTR_FLOAT) {
    ret.x = primitive_attribute_float(desc, null_flt, null_flt);
  }
  else if (desc.type == NODE_ATTR_FLOAT2) {
    ret.xy = primitive_attribute_float2(desc, null_flt2, null_flt2);
  }
  else if (desc.type == NODE_ATTR_RGBA) {
    ret = primitive_attribute_float4( desc, null_flt4, null_flt4);
  }
  else {
    ret = primitive_attribute_float3( desc, null_flt3, null_flt3);
  }

  SVM_GEOM_RET_ATTR(ret);


}

ccl_device void svm_node_attr_bump_dx()
{

  NodeAttributeType type = NODE_ATTR_FLOAT;
  uint out_offset = 0;
  AttributeDescriptor desc = svm_node_attr_init( type , out_offset);
  
  SVM_GEOM_RET_DESCTYPE(desc.type);
  SVM_GEOM_RET_TYPE = type;
  SVM_GEOM_RET_OUTOFFSET(out_offset);
  vec4 ret;
  /* fetch and store attribute */
  if (desc.type == NODE_ATTR_FLOAT) {
    float dx;
    float f = primitive_surface_attribute_float(desc, (dx), null_flt);

    if (type == NODE_ATTR_FLOAT) {
      ret.x =  f + dx;
    }
    else {
      ret.xyz = vec3(f + dx, f + dx, f + dx);
    }
  }
  else if (desc.type == NODE_ATTR_FLOAT2) {
    float2 dx;
    float2 f = primitive_attribute_float2(desc, dx,null_flt2);
    if (type == NODE_ATTR_FLOAT) {
      ret.x =  f.x + dx.x;
    }
    else {
      ret.xyz  = vec3(f.x + dx.x, f.y + dx.y, 0.0f);
    }
  }
  else if (desc.type == NODE_ATTR_RGBA) {
    float4 dx;
    float4 f = primitive_attribute_float4(desc, dx, null_flt4);
    if (type == NODE_ATTR_FLOAT) {
      ret.x = average(float4_to_float3(f + dx));
    }
    else {
      ret = f + dx;
    }
  }
  else {
    float3 dx;
    float3 f = primitive_surface_attribute_float3(desc, dx, null_flt4);
    
    if (type == NODE_ATTR_FLOAT) {
      ret.x =  average(f + dx);
    }
    else {
      ret = f + dx;
    }
  }

  SVM_GEOM_RET_ATTR(ret);

}

ccl_device void svm_node_attr_bump_dy()
{

  NodeAttributeType type = NODE_ATTR_FLOAT;
  uint out_offset = 0;
  AttributeDescriptor desc = svm_node_attr_init( type , out_offset);
  
  SVM_GEOM_RET_DESCTYPE(desc.type);
  SVM_GEOM_RET_TYPE = type;
  SVM_GEOM_RET_OUTOFFSET(out_offset);
  vec4 ret;
  /* fetch and store attribute */
  if (desc.type == NODE_ATTR_FLOAT) {
    float dy;
    float f = primitive_surface_attribute_float(desc, null_flt,(dy));

    if (type == NODE_ATTR_FLOAT) {
      ret.x =  f + dy;
    }
    else {
      ret.xyz = vec3(f + dy, f + dy, f + dy);
    }
  }
  else if (desc.type == NODE_ATTR_FLOAT2) {
    float2 dy;
    float2 f = primitive_attribute_float2(desc,null_flt2,dy);
    if (type == NODE_ATTR_FLOAT) {
      ret.x =  f.x + dy.x;
    }
    else {
      ret.xyz  = vec3(f.x + dy.x, f.y + dy.y, 0.0f);
    }
  }
  else if (desc.type == NODE_ATTR_RGBA) {
    float4 dy;
    float4 f = primitive_attribute_float4(desc,null_flt4,dy);
    if (type == NODE_ATTR_FLOAT) {
      ret.x = average(float4_to_float3(f + dy));
    }
    else {
      ret = f + dy;
    }
  }
  else {
    float3 dy;
    float3 f = primitive_surface_attribute_float3(desc, null_flt4 ,dy);
    
    if (type == NODE_ATTR_FLOAT) {
      ret.x =  average(f + dy);
    }
    else {
      ret = f + dy;
    }
  }

  SVM_GEOM_RET_ATTR(ret);

}

ccl_device void svm_node_enter_bump_eval()
{

  AttributeDescriptor desc = find_attribute(ATTR_STD_POSITION_UNDISPLACED);

  if (desc.offset != ATTR_STD_NOT_FOUND) {

    float3 P, dPdx, dPdy;
    P = primitive_surface_attribute_float3(desc, (dPdx), (dPdy));
    SVM_GEOM_RET_BUMP_ENTER(P,dPdx,dPdy);
  }

  ioSD.offset = desc.offset;
}



#endif
CCL_NAMESPACE_END
#endif