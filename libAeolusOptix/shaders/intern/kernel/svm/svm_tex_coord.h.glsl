#ifndef _SVM_TEX_COORD_H_
#define _SVM_TEX_COORD_H_
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
float3   camera_position()
{
  Transform cameratoworld = kernel_data.cam.cameratoworld;
  return  make_float3(cameratoworld.x.w, cameratoworld.y.w, cameratoworld.z.w);
}

float3 camera_world_to_ndc(float3 P)
{
  if (kernel_data.cam.type != CAMERA_PANORAMA) {
    /* perspective / ortho */
    if (GSD.object == PRIM_NONE && kernel_data.cam.type == CAMERA_PERSPECTIVE)
      P += camera_position();

    ProjectionTransform tfm = kernel_data.cam.worldtondc;
    return transform_perspective((tfm), P);

  }
  else {
    /* panorama 
    Transform tfm = kernel_data.cam.worldtocamera;

    if (GSD.object != OBJECT_NONE)
      P = normalize(transform_point((tfm), P));

    else
      P = normalize(transform_direction((tfm), P));


    float2 uv = direction_to_panorama(P);

    return make_float3(uv.x, uv.y, 0.0f);
    */
  }
}


#ifdef NODE_Caller
/* 
GSD.P
GSD.ray_P
GSD.object
GSD.N 
GSD.type 
GSD.lamp
GSD.I
Texture Coordinate Node */
//#define TEX_COORD__

ccl_device void svm_node_tex_coord( int path_flag, uint4 node, inout int offset)
{
  float3 data;
  uint type = node.y;
  uint out_offset = node.z;

  switch (type) {
    case NODE_TEXCO_OBJECT: {
      data = GSD.P;
      if (node.w == 0) {
        if (GSD.object != OBJECT_NONE) {
          object_inverse_position_transform((data));

        }
      }
      else {
        Transform tfm;
        read_node_float(tfm.x, offset);
        read_node_float(tfm.y, offset);
        read_node_float(tfm.z, offset);
        data = transform_point((tfm), data);

      }
      break;
    }
    case NODE_TEXCO_NORMAL: {
      data = GSD.N;
      object_inverse_normal_transform( (data));

      break;
    }
    case NODE_TEXCO_CAMERA: {
      Transform tfm = kernel_data.cam.worldtocamera;

      if (GSD.object != OBJECT_NONE)
        data = transform_point((tfm), GSD.P);

      else
        data = transform_point((tfm), GSD.P + camera_position());

      break;
    }
    case NODE_TEXCO_WINDOW: {
      if (bool(path_flag & PATH_RAY_CAMERA) &&GSD.object == OBJECT_NONE &&kernel_data.cam.type == CAMERA_ORTHOGRAPHIC)
        data = camera_world_to_ndc( GSD.ray_P);
      else
        data = camera_world_to_ndc( GSD.P);
      data.z = 0.0f;
      break;
    }
    case NODE_TEXCO_REFLECTION: {
      if (GSD.object != OBJECT_NONE)
        data = 2.0f * dot3(GSD.N, GSD.I) * GSD.N - GSD.I;
      else
        data = GSD.I;
      break;
    }
    case NODE_TEXCO_DUPLI_GENERATED: {
    
      data = object_dupli_generated( GSD.object);
      break;
    }
    case NODE_TEXCO_DUPLI_UV: {
      data = object_dupli_uv( GSD.object);
      break;
    }
    case NODE_TEXCO_VOLUME_GENERATED: {
      data = GSD.P;

#ifdef _VOLUME_
      if (GSD.object != OBJECT_NONE)
        data = volume_normalized_position(kg, sd, data);
#endif
      break;
    }
  }

  stack_store_float3(out_offset, data);
}
ccl_device void svm_node_normal_map(uint4 node)
{
  uint color_offset, strength_offset, normal_offset, space;
  svm_unpack_node_uchar4(node.y, (color_offset), (strength_offset), (normal_offset), (space));

  float3 color = stack_load_float3(color_offset);
  color = 2.0f * make_float3(color.x - 0.5f, color.y - 0.5f, color.z - 0.5f);
  bool is_backfacing = (GSD.flag & SD_BACKFACING) != 0;
  float3 N;
  if (space == NODE_NORMAL_MAP_TANGENT) {
    /* tangent space */
    if (GSD.object == OBJECT_NONE) {
      stack_store_float3(normal_offset, make_float3(0.0f, 0.0f, 0.0f));
      return;
    }
    
    SVM_NORMAL_SD(GSD,nio,color,is_backfacing)
    SVM_GEOM_SD_NODE(node)
    nio.type = SVM_NODE_NORMAL;
  
    EXECUTION_GEOM;
    
    if (!SVM_GEOM_RET_TF){
        stack_store_float3(normal_offset, make_float3(0.0f, 0.0f, 0.0f));
        return;
    }

    N= SVM_GEOM_RET_NORMAL;
 
  }else{
    /* strange blender convention */
    if (space == NODE_NORMAL_MAP_BLENDER_OBJECT || space == NODE_NORMAL_MAP_BLENDER_WORLD) {
      color.y = -color.y;
      color.z = -color.z;
    }

    /* object, world space */
    N = color;

    if (space == NODE_NORMAL_MAP_OBJECT || space == NODE_NORMAL_MAP_BLENDER_OBJECT)
      object_normal_transform(N);
    else
      N = safe_normalize(N);
  }

  /* invert normal for backfacing polygons */
  if (is_backfacing) {
    N = -N;
  }

  float strength = stack_load_float(strength_offset);

  if (strength != 1.0f) {
    strength = max(strength, 0.0f);
    N = safe_normalize(GSD.N + (N - GSD.N) * strength);
  }

  N = ensure_valid_reflection(GSD.Ng, GSD.I, N);

  if (is_zero(N)) {N = GSD.N;}

  stack_store_float3(normal_offset, N);

}

#ifdef TEX_COORD__

ccl_device void svm_node_tex_coord_bump_dx(
    inout KernelGlobals kg, inout ShaderData sd, int path_flag, inout float stack[SVM_STACK_SIZE]
, uint4 node, inout int offset)
{
#ifdef _RAY_DIFFERENTIALS_
  float3 data;
  uint type = node.y;
  uint out_offset = node.z;

  switch (type) {
    case NODE_TEXCO_OBJECT: {
      data = GSD.P + GSD.dP.dx;
      if (node.w == 0) {
        if (GSD.object != OBJECT_NONE) {
          object_inverse_position_transform(kg, sd, (data));

        }
      }
      else {
        Transform tfm;
        tfm.x = read_node_float(kg, offset);
        tfm.y = read_node_float(kg, offset);
        tfm.z = read_node_float(kg, offset);
        data = transform_point((tfm), data);

      }
      break;
    }
    case NODE_TEXCO_NORMAL: {
      data = GSD.N;
      object_inverse_normal_transform(kg, sd, (data));

      break;
    }
    case NODE_TEXCO_CAMERA: {
      Transform tfm = kernel_data.cam.worldtocamera;

      if (GSD.object != OBJECT_NONE)
        data = transform_point((tfm), GSD.P + GSD.dP.dx);

      else
        data = transform_point((tfm), GSD.P + GSD.dP.dx + camera_position(kg));

      break;
    }
    case NODE_TEXCO_WINDOW: {
      if (bool(path_flag & PATH_RAY_CAMERA) &&
 GSD.object == OBJECT_NONE &&
          kernel_data.cam.type == CAMERA_ORTHOGRAPHIC)
        data = camera_world_to_ndc(kg, sd, GSD.ray_P + GSD.ray_dP.dx);
      else
        data = camera_world_to_ndc(kg, sd, GSD.P + GSD.dP.dx);
      data.z = 0.0f;
      break;
    }
    case NODE_TEXCO_REFLECTION: {
      if (GSD.object != OBJECT_NONE)
        data = 2.0f * dot3(GSD.N, GSD.I) * GSD.N - GSD.I;
      else
        data = GSD.I;
      break;
    }
    case NODE_TEXCO_DUPLI_GENERATED: {
      data = object_dupli_generated(kg, GSD.object);
      break;
    }
    case NODE_TEXCO_DUPLI_UV: {
      data = object_dupli_uv(kg, GSD.object);
      break;
    }
    case NODE_TEXCO_VOLUME_GENERATED: {
      data = GSD.P + GSD.dP.dx;

#  ifdef _VOLUME_
      if (GSD.object != OBJECT_NONE)
        data = volume_normalized_position(kg, sd, data);
#  endif
      break;
    }
  }

  stack_store_float3(stack, out_offset, data);
#else
  svm_node_tex_coord(kg, sd, path_flag, stack, node, offset);
#endif
}

ccl_device void svm_node_tex_coord_bump_dy(
    inout KernelGlobals kg, inout ShaderData sd, int path_flag, inout float stack[SVM_STACK_SIZE]
, uint4 node, inout int offset)
{
#ifdef _RAY_DIFFERENTIALS_
  float3 data;
  uint type = node.y;
  uint out_offset = node.z;

  switch (type) {
    case NODE_TEXCO_OBJECT: {
      data = GSD.P + GSD.dP.dy;
      if (node.w == 0) {
        if (GSD.object != OBJECT_NONE) {
          object_inverse_position_transform(kg, sd, (data));

        }
      }
      else {
        Transform tfm;
        tfm.x = read_node_float(kg, offset);
        tfm.y = read_node_float(kg, offset);
        tfm.z = read_node_float(kg, offset);
        data = transform_point((tfm), data);

      }
      break;
    }
    case NODE_TEXCO_NORMAL: {
      data = GSD.N;
      object_inverse_normal_transform(kg, sd, (data));

      break;
    }
    case NODE_TEXCO_CAMERA: {
      Transform tfm = kernel_data.cam.worldtocamera;

      if (GSD.object != OBJECT_NONE)
        data = transform_point((tfm), GSD.P + GSD.dP.dy);

      else
        data = transform_point((tfm), GSD.P + GSD.dP.dy + camera_position(kg));

      break;
    }
    case NODE_TEXCO_WINDOW: {
      if (bool(path_flag & PATH_RAY_CAMERA) &&
 GSD.object == OBJECT_NONE &&
          kernel_data.cam.type == CAMERA_ORTHOGRAPHIC)
        data = camera_world_to_ndc(kg, sd, GSD.ray_P + GSD.ray_dP.dy);
      else
        data = camera_world_to_ndc(kg, sd, GSD.P + GSD.dP.dy);
      data.z = 0.0f;
      break;
    }
    case NODE_TEXCO_REFLECTION: {
      if (GSD.object != OBJECT_NONE)
        data = 2.0f * dot3(GSD.N, GSD.I) * GSD.N - GSD.I;
      else
        data = GSD.I;
      break;
    }
    case NODE_TEXCO_DUPLI_GENERATED: {
      data = object_dupli_generated(kg, GSD.object);
      break;
    }
    case NODE_TEXCO_DUPLI_UV: {
      data = object_dupli_uv(kg, GSD.object);
      break;
    }
    case NODE_TEXCO_VOLUME_GENERATED: {
      data = GSD.P + GSD.dP.dy;

#  ifdef _VOLUME_
      if (GSD.object != OBJECT_NONE)
        data = volume_normalized_position(kg, sd, data);
#  endif
      break;
    }
  }

  stack_store_float3(stack, out_offset, data);
#else
  svm_node_tex_coord(kg, sd, path_flag, stack, node, offset);
#endif
}


#endif

ccl_device void svm_node_tangent(uint4 node)
{
  uint tangent_offset, direction_type, axis;
  svm_unpack_node_uchar3(node.y, (tangent_offset), (direction_type), (axis));
  float3 tangent;


  nio.type = SVM_NODE_TANGENT;
  nio.offset = int(node.z);
  SVM_GEOM_SD(sd,nio)

   EXECUTION_GEOM;

  float3 attribute_value = SVM_GEOM_RET_TANG;

  if (direction_type == NODE_TANGENT_UVMAP) {
    /* UV map */
    if (!SVM_GEOM_RET_TF)
      tangent = make_float3(0.0f, 0.0f, 0.0f);
    else
      tangent = attribute_value;
  }
  else {
    /* radial */
    float3 generated;

    if (!SVM_GEOM_RET_TF)
      generated = GSD.P;
    else
      generated = attribute_value;

    if (axis == NODE_TANGENT_AXIS_X)
      tangent = make_float3(0.0f, -(generated.z - 0.5f), (generated.y - 0.5f));
    else if (axis == NODE_TANGENT_AXIS_Y)
      tangent = make_float3(-(generated.z - 0.5f), 0.0f, (generated.x - 0.5f));
    else
      tangent = make_float3(-(generated.y - 0.5f), (generated.x - 0.5f), 0.0f);
  }

  object_normal_transform( (tangent));

  tangent = cross3(GSD.N, normalize(cross(tangent, GSD.N)));
  stack_store_float3( tangent_offset, tangent);
}


#endif

#ifdef NODE_Callee
ccl_device void svm_node_normal_map()
{    

    uint color_offset, strength_offset, normal_offset, space;
    svm_unpack_node_uchar4(GSD.node.y, (color_offset), (strength_offset), (normal_offset), (space));
    float3 color       = SVM_GEOM_NORMAL_COLOR;
    bool is_backfacing = SVM_GEOM_NORMAL_ISBACKFACING;
    float3 N;
  //if (space == NODE_NORMAL_MAP_TANGENT)
  {
    // tangent space  
    /*Caller
    if (GSD.object == OBJECT_NONE) {
      SVM_GEOM_RET_TF(false);
      return;
    }
    */

    /* first try to get tangent attribute */
    const AttributeDescriptor attr       = find_attribute(GSD.node.z);
    const AttributeDescriptor attr_sign  = find_attribute(GSD.node.w);
    const AttributeDescriptor attr_normal = find_attribute(ATTR_STD_VERTEX_NORMAL);

    if (attr.offset == ATTR_STD_NOT_FOUND || attr_sign.offset == ATTR_STD_NOT_FOUND ||
        attr_normal.offset == ATTR_STD_NOT_FOUND) {
      SVM_GEOM_RET_TF(false);
      return;
    }

    /* get _unnormalized_ interpolated normal and tangent */
    float3 tangent = primitive_attribute_float3( attr,null_flt3, null_flt3);
    float  sign    = primitive_attribute_float(  attr_sign, null_flt, null_flt);

    float3 normal;

    if (bool(SVM_GEOM_NORMAL_SHADER & SHADER_SMOOTH_NORMAL)) {

      normal = primitive_attribute_float3(attr_normal, null_flt3, null_flt3);

    }
    else {
      normal = GSD.N;

      /* the normal is already inverted, which is too soon for the math here */
      if (is_backfacing) {
        normal = -normal;
      }

      object_inverse_normal_transform(normal);

    }

    /* apply normal map */
    float3 B = sign * cross3(normal, tangent);
    N = safe_normalize(color.x * tangent + color.y * B + color.z * normal);

    /* transform to world space */
    object_normal_transform(N);

  }
  /*Caller
  else {
    // strange blender convention 
    if (space == NODE_NORMAL_MAP_BLENDER_OBJECT || space == NODE_NORMAL_MAP_BLENDER_WORLD) {
      color.y = -color.y;
      color.z = -color.z;
    }

    // object, world space 
    N = color;

    if (space == NODE_NORMAL_MAP_OBJECT || space == NODE_NORMAL_MAP_BLENDER_OBJECT)
      object_normal_transform(N);
    else
      N = safe_normalize(N);
  }*/

SVM_GEOM_RET_TF(true);
SVM_GEOM_RET_NORMAL(N);

}

ccl_device void svm_node_tangent()
{

  vec4 attribute_value;
  const AttributeDescriptor desc = find_attribute( uint(GSD.offset) );
  if (desc.offset != ATTR_STD_NOT_FOUND) {
    if (desc.type == NODE_ATTR_FLOAT2) {
      float2 value = primitive_attribute_float2( desc, null_flt2, null_flt2);
      attribute_value.x = value.x;
      attribute_value.y = value.y;
      attribute_value.z = 0.0f;
    }
    else {
      attribute_value = primitive_attribute_float3( desc, null_flt3, null_flt3);

    }
     SVM_GEOM_RET_TF(true)
  }else  SVM_GEOM_RET_TF(false)  
  
   SVM_GEOM_RET_TANG(attribute_value)

}
#endif




CCL_NAMESPACE_END

#endif