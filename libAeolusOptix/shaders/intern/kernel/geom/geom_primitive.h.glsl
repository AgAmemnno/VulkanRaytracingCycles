#ifndef _GEOM_PRIM_H_
#define _GEOM_PRIM_H_

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
//#define NODE_Caller
#define SVM_NODE_TANGENT 0
#define SVM_GEOM_TANGENT 1
#define SVM_NODE_ATTR    2
#define SVM_NODE_NORMAL  3
#define SVM_NODE_BUMP_DX 4
#define SVM_NODE_BUMP_DY 5
#define SVM_NODE_VC      6
#define SVM_NODE_VC_BUMP_DX      7
#define SVM_NODE_VC_BUMP_DY      8
#define SVM_NODE_BUMP_ENTRY      9


#ifdef NODE_Caller

#define SVM_VC_SD(sd,nio,layer_id) {\
   nio.data[3]  = uintBitsToFloat(layer_id);\
   nio.data[4]  = intBitsToFloat(sd.object_flag);\
   nio.data[5]  = intBitsToFloat(sd.prim);\
   nio.data[6]  = intBitsToFloat(sd.type);\
   nio.data[7]  = sd.u;   nio.data[8] = sd.v;\
   nio.data[9]  = intBitsToFloat(sd.object);\
   nio.data[19] = intBitsToFloat(sd.geometry);\
}

#define SVM_VC_SD_DUDV(sd,nio) {\
   nio.data[10] = sd.du.dx;nio.data[11] = sd.du.dy;\
   nio.data[12] = sd.dv.dx;nio.data[13] = sd.dv.dy;\
}

  #define SVM_NORMAL_SD(sd,nio,color,is_backfacing) {\
   nio.data[0] = sd.Ng.x;nio.data[1] = sd.Ng.y;nio.data[2] = sd.Ng.z;\
   nio.data[3] = intBitsToFloat(sd.shader);\
   nio.data[4] = intBitsToFloat(sd.object_flag);\
   nio.data[5] = intBitsToFloat(sd.prim);\
   nio.data[6] = intBitsToFloat(sd.type);\
   nio.data[7] = sd.u;   nio.data[8] = sd.v;\
   nio.data[9] = intBitsToFloat(sd.object);\
   nio.data[10] = color.x;nio.data[11] = color.y;\
   nio.data[12] = color.z;nio.data[13] = intBitsToFloat(int(is_backfacing));\
   nio.data[14] = intBitsToFloat(sd.lamp);\
   nio.data[19] = intBitsToFloat(sd.geometry);\
}


#define SVM_GEOM_SD(sd,nio) {\
   nio.data[0] = sd.N.x;nio.data[1] = sd.N.y;nio.data[2] = sd.N.z;\
   nio.data[4] = intBitsToFloat(sd.object_flag);\
   nio.data[5] = intBitsToFloat(sd.prim);\
   nio.data[6] = intBitsToFloat(sd.type);\
   nio.data[7] = sd.u;   nio.data[8] = sd.v;\
   nio.data[9] = intBitsToFloat(sd.object);\
   nio.data[10] = sd.du.dx;nio.data[11] = sd.du.dy;\
   nio.data[12] = sd.dv.dx;nio.data[13] = sd.dv.dy;\
   nio.data[14] = intBitsToFloat(sd.lamp);\
   nio.data[19] = intBitsToFloat(sd.geometry);\
}


#define SVM_GEOM_NODE_OFFSET  15
#define SVM_GEOM_SD_NODE(node) {\
nio.data[SVM_GEOM_NODE_OFFSET]    = uintBitsToFloat(node.x);nio.data[SVM_GEOM_NODE_OFFSET+1] = uintBitsToFloat(node.y);\
nio.data[SVM_GEOM_NODE_OFFSET +2] = uintBitsToFloat(node.z);nio.data[SVM_GEOM_NODE_OFFSET +3] = uintBitsToFloat(node.w);\
}

#define SVM_GEOM_RET_TF   bool(nio.type)
#define SVM_GEOM_RET_TANG vec4(nio.data[0], nio.data[1],nio.data[2],0.)
#define SVM_GEOM_RET_NORMAL SVM_GEOM_RET_TANG
#define SVM_GEOM_RET_ATTR vec4(nio.data[0], nio.data[1],nio.data[2],nio.data[3])
#define SVM_GEOM_RET_DESCTYPE  floatBitsToInt(nio.data[4])
#define SVM_GEOM_RET_TYPE      nio.type
#define SVM_GEOM_RET_OUTOFFSET uint(nio.offset)

#define SVM_GEOM_RET_P vec4(nio.data[0], nio.data[1],nio.data[2],0.)
#define SVM_GEOM_RET_dPdx vec4(nio.data[3], nio.data[4],nio.data[5],0.)
#define SVM_GEOM_RET_dPdy vec4(nio.data[6], nio.data[7],nio.data[8],0.)

#define SVM_GEOM_RET_DESC_OFFSET SVM_GEOM_RET_TYPE
#define SVM_GEOM_RET_VC SVM_GEOM_RET_ATTR

#include "kernel/geom/geom_object.h.glsl"
ccl_device float3 primitive_tangent()
{
#ifdef _HAIR_
  if (bool(GSD.type & PRIMITIVE_ALL_CURVE))
#  ifdef _DPDU_

    return normalize(GSD.dPdu);
#  else
    return make_float3(0.0f, 0.0f, 0.0f);
#  endif
#endif

nio.type = SVM_GEOM_TANGENT;
SVM_GEOM_SD(GSD,nio);
EXECUTION_GEOM;


if(SVM_GEOM_RET_TF){
  return SVM_GEOM_RET_TANG;
}else{
    /* otherwise use surface derivatives */
#ifdef _DPDU_
    return normalize(GSD.dPdu);
#else
    return make_float3(0.0f, 0.0f, 0.0f);
#endif
  }

}
#endif



#ifdef  NODE_Callee


/* Primitive Utilities
 *
 * Generic functions to look up mesh, curve and volume primitive attributes for
 * shading and render passes. */
#include "kernel/geom/geom_attribute.h.glsl"
#include "kernel/geom/geom_triangle.h.glsl"
#include "kernel/geom/geom_subd_triangle.h.glsl"

CCL_NAMESPACE_BEGIN


ccl_device_inline float primitive_surface_attribute_float(const AttributeDescriptor desc, inout float dx, inout float dy)
{
  if (bool(GSD.type & PRIMITIVE_ALL_TRIANGLE)) {

    if (subd_triangle_patch() == ~0)
      return triangle_attribute_float(desc, dx, dy);
    else
      return subd_triangle_attribute_float(desc, dx, dy);
  }
#ifdef _HAIR_
  else if (bool(GSD.type & PRIMITIVE_ALL_CURVE)) {
    return curve_attribute_float(kg, sd, desc, dx, dy);
  }

#endif
  else {
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;
    return 0.0f;
  }
}

#ifdef _VOLUME_
ccl_device_inline float primitive_volume_attribute_float(inout KernelGlobals kg,
                                                         in ShaderData sd,
                                                         const AttributeDescriptor desc)
{
  if (GSD.object != OBJECT_NONE && desc.element == ATTR_ELEMENT_VOXEL) {
    return volume_attribute_float(kg, sd, desc);
  }
  else {
    return 0.0f;
  }
}
#endif




ccl_device_inline float2 primitive_surface_attribute_float2(inout KernelGlobals kg,
                                                            in ShaderData sd,
                                                            const AttributeDescriptor desc,
                                                            inout float2 dx2,
                                                            inout float2 dy2)
{
  if (bool(GSD.type & PRIMITIVE_ALL_TRIANGLE)) {

    if (subd_triangle_patch() == ~0)
      return triangle_attribute_float2(desc, dx2, dy2);
    else
      return subd_triangle_attribute_float2(desc, dx2, dy2);
  }
#ifdef _HAIR_
  else if (bool(GSD.type & PRIMITIVE_ALL_CURVE)) {

    return curve_attribute_float2(kg, sd, desc, dx2, dy2);
  }
#endif
  else {
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);
    return make_float2(0.0f, 0.0f);
  }
}



#ifdef __GEOM_TODO

#ifdef _VOLUME_
ccl_device_inline float3 primitive_volume_attribute_float3(inout KernelGlobals kg,
                                                           in ShaderData sd,
                                                           const AttributeDescriptor desc)
{
  if (GSD.object != OBJECT_NONE && desc.element == ATTR_ELEMENT_VOXEL) {
    return volume_attribute_float3(kg, sd, desc);
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}
#endif

/* Default UV coordinate */

ccl_device_inline float3 primitive_uv(inout KernelGlobals kg, inout ShaderData sd)
{
  const AttributeDescriptor desc = find_attribute(kg, sd, ATTR_STD_UV);

  if (desc.offset == ATTR_STD_NOT_FOUND)
    return make_float3(0.0f, 0.0f, 0.0f);

   float2 uv;{float2 null1 = float2(NULL_FLT);float2 null2 = float2(NULL_FLT);uv = primitive_surface_attribute_float2(kg, sd, desc, null1, null2);}

  return make_float3(uv.x, uv.y, 1.0f);
}

/* Ptex coordinates */

ccl_device bool primitive_ptex(inout KernelGlobals kg, inout ShaderData sd, inout float2 uv, inout int face_id)
{
  /* storing ptex data as attributes is not memory efficient but simple for tests */
  const AttributeDescriptor desc_face_id = find_attribute(kg, sd, ATTR_STD_PTEX_FACE_ID);
  const AttributeDescriptor desc_uv = find_attribute(kg, sd, ATTR_STD_PTEX_UV);

  if (desc_face_id.offset == ATTR_STD_NOT_FOUND || desc_uv.offset == ATTR_STD_NOT_FOUND)
    return false;

  float3 uv3;
  float face_id_f;
  {
  float3 null1 = float3(NULL_FLT);
  float3 null2 = float3(NULL_FLT);
  uv3 = primitive_surface_attribute_float3(kg, sd, desc_uv, null1, null2);
  face_id_f = primitive_surface_attribute_float(kg, sd, desc_face_id, null1.x, null2.x);
  }

  uv = make_float2(uv3.x, uv3.y);
  face_id = int(face_id_f);


  return true;
}

/* Motion vector for motion pass */

ccl_device_inline float4 primitive_motion_vector(inout KernelGlobals kg, inout ShaderData sd)
{
  /* center position */
  float3 center;

#ifdef _HAIR_
  bool is_curve_primitive = bool(GSD.type & PRIMITIVE_ALL_CURVE);

  if (is_curve_primitive) {
    center = curve_motion_center_location(kg, sd);

    if (!(bool(GSD.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {

      object_position_transform(kg, sd, (center));

    }
  }
  else
#endif
  center = GSD.P;

  float3 motion_pre = center, motion_post = center;

  /* deformation motion */
  AttributeDescriptor desc = find_attribute(kg, sd, ATTR_STD_MOTION_VERTEX_POSITION);

  if (desc.offset != ATTR_STD_NOT_FOUND) {
    /* get motion info */
    int numverts, numkeys;
    {
      int null_int = NULL_INT;
      object_motion_info(kg, GSD.object, null_int, (numverts), (numkeys));
    };

    /* lookup attributes */
     {
  float3 null1 = float3(NULL_FLT);
  float3 null2 = float3(NULL_FLT);
    motion_pre = primitive_surface_attribute_float3(kg, sd, desc, null1, null2);

    desc.offset += bool(GSD.type & PRIMITIVE_ALL_TRIANGLE) ? numverts : numkeys;
    motion_post = primitive_surface_attribute_float3(kg, sd, desc,null1, null2);
     }

#ifdef _HAIR_
    if (is_curve_primitive && (GSD.object_flag & SD_OBJECT_HAS_VERTEX_MOTION) == 0) {
      object_position_transform(kg, sd, (motion_pre));

      object_position_transform(kg, sd, (motion_post));

    }
#endif
  }

  /* object motion. note that depending on the mesh having motion vectors, this
   * transformation was set match the world/object space of motion_pre/post */
  Transform tfm;

  tfm = object_fetch_motion_pass_transform(kg, GSD.object, OBJECT_PASS_MOTION_PRE);
  motion_pre = transform_point((tfm), motion_pre);


  tfm = object_fetch_motion_pass_transform(kg, GSD.object, OBJECT_PASS_MOTION_POST);
  motion_post = transform_point((tfm), motion_post);


  float3 motion_center;

  /* camera motion, for perspective/orthographic motion.pre/post will be a
   * world-to-raster matrix, for panorama it's world-to-camera */
  if (kernel_data.cam.type != CAMERA_PANORAMA) {
    ProjectionTransform projection = kernel_data.cam.worldtoraster;
    motion_center = transform_perspective((projection), center);


    projection = kernel_data.cam.perspective_pre;
    motion_pre = transform_perspective((projection), motion_pre);


    projection = kernel_data.cam.perspective_post;
    motion_post = transform_perspective((projection), motion_post);

  }
  else {
    tfm = kernel_data.cam.worldtocamera;
    motion_center = normalize(transform_point((tfm), center));

    motion_center = float2_to_float3(direction_to_panorama(
 motion_center));

    motion_center.x *= kernel_data.cam.width;
    motion_center.y *= kernel_data.cam.height;

    tfm = kernel_data.cam.motion_pass_pre;
    motion_pre = normalize(transform_point((tfm), motion_pre));

    motion_pre = float2_to_float3(direction_to_panorama(
 motion_pre));

    motion_pre.x *= kernel_data.cam.width;
    motion_pre.y *= kernel_data.cam.height;

    tfm = kernel_data.cam.motion_pass_post;
    motion_post = normalize(transform_point((tfm), motion_post));

    motion_post = float2_to_float3(direction_to_panorama(
 motion_post));

    motion_post.x *= kernel_data.cam.width;
    motion_post.y *= kernel_data.cam.height;
  }

  motion_pre = motion_pre - motion_center;
  motion_post = motion_center - motion_post;

  return make_float4(motion_pre.x, motion_pre.y, motion_post.x, motion_post.y);
}

#endif

ccl_device_inline float4 primitive_attribute_float4(
                                                    const AttributeDescriptor desc,
                                                    inout float4 dx4,
                                                    inout float4 dy4)
{
  if (bool(GSD.type & PRIMITIVE_ALL_TRIANGLE)) {

    if (subd_triangle_patch() == ~0)
      return triangle_attribute_float4( desc, dx4, dy4);
    else
      return subd_triangle_attribute_float4( desc, dx4, dy4);
  }
#ifdef _HAIR_
  else if (bool(GSD.type & PRIMITIVE_ALL_CURVE)) {

    return curve_attribute_float4(kg, sd, desc, dx4, dy4);
  }
#endif
  else {
    if(!isNULL4(dx4))

      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if(!isNULL4(dy4))

      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    return make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  }
}

/* Generic primitive attribute reading functions */
ccl_device_inline float primitive_attribute_float(const AttributeDescriptor desc, inout float dx, inout float dy)
{
  if (bool(GSD.type & PRIMITIVE_ALL_TRIANGLE)) {

    if (subd_triangle_patch() == ~0)
      return triangle_attribute_float( desc, dx, dy);
    else
      return subd_triangle_attribute_float(desc, dx, dy);
  }
#ifdef _HAIR_
  else if (bool(GSD.type & PRIMITIVE_ALL_CURVE)) {
    return curve_attribute_float(kg, sd, desc, dx, dy);
  }

#endif
#ifdef _VOLUME_
  else if (GSD.object != OBJECT_NONE && desc.element == ATTR_ELEMENT_VOXEL) {
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;
    return volume_attribute_float(kg, sd, desc);
  }
#endif
  else {
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;
    return 0.0f;
  }
}

ccl_device_inline float2 primitive_attribute_float2(
                                                    const AttributeDescriptor desc,
                                                    inout float2 dx2,
                                                    inout float2 dy2)
{


  if (bool(GSD.type & PRIMITIVE_ALL_TRIANGLE)) {

    if (subd_triangle_patch() == ~0)
      return triangle_attribute_float2(desc, dx2, dy2);
    else
      return subd_triangle_attribute_float2( desc, dx2, dy2);
  }
#ifdef _HAIR_
  else if (bool(GSD.type & PRIMITIVE_ALL_CURVE)) {

    return curve_attribute_float2(kg, sd, desc, dx2, dy2);
  }
#endif
#ifdef _VOLUME_
  else if (GSD.object != OBJECT_NONE && desc.element == ATTR_ELEMENT_VOXEL) {
    kernel_assert(0);
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);
    return make_float2(0.0f, 0.0f);
  }
#endif
  else {
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);
    return make_float2(0.0f, 0.0f);
  }
}

ccl_device_inline float3 primitive_attribute_float3(
                                                    const AttributeDescriptor desc,
                                                    inout float3 dx3,
                                                    inout float3 dy3)
{

  
  if (bool(GSD.type & PRIMITIVE_ALL_TRIANGLE)) {

    if (subd_triangle_patch() == ~0)
      return triangle_attribute_float3(desc, dx3, dy3);
    else
      return subd_triangle_attribute_float3( desc, dx3, dy3);
  }
#ifdef _HAIR_
  else if (bool(GSD.type & PRIMITIVE_ALL_CURVE)) {

    return curve_attribute_float3(kg, sd, desc, dx3, dy3);
  }
#endif
#ifdef _VOLUME_
  else if (GSD.object != OBJECT_NONE && desc.element == ATTR_ELEMENT_VOXEL) {
    if(!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);
    return volume_attribute_float3(kg, sd, desc);
  }
#endif
  else {
    if(!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

ccl_device_inline float3 primitive_surface_attribute_float3(
                                                            const AttributeDescriptor desc,
                                                            inout float3 dx3,
                                                            inout float3 dy3)
{
  if (bool(GSD.type & PRIMITIVE_ALL_TRIANGLE)) {

    if (subd_triangle_patch() == ~0)
      return triangle_attribute_float3(desc, dx3, dy3);
    else
      return subd_triangle_attribute_float3(desc, dx3, dy3);
  }
#ifdef _HAIR_
  else if (bool(GSD.type & PRIMITIVE_ALL_CURVE)) {

    return curve_attribute_float3(kg, sd, desc, dx3, dy3);
  }
#endif
  else {
    if(!isNULL3(dx3))
      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))
      dy3 = make_float3(0.0f, 0.0f, 0.0f);
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

/* Surface tangent */

ccl_device_inline void object_normal_transform(inout float3 N)
{
  Transform tfm = object_fetch_transform(GSD.object, OBJECT_INVERSE_TRANSFORM);
  N = normalize(transform_direction_transposed(tfm, N));
}

ccl_device void primitive_tangent()
{


  const AttributeDescriptor desc = find_attribute( ATTR_STD_GENERATED);
   // try to create spherical tangent from generated coordinates 
  if (desc.offset != ATTR_STD_NOT_FOUND) {
    float3 null1 = float3(NULL_FLT);
    float3 null2 = float3(NULL_FLT);


     float3 data  = primitive_surface_attribute_float3(desc, null1, null2);
     data         = make_float3(-(data.y - 0.5f), (data.x - 0.5f), 0.0f);
     object_normal_transform(data);
     vec3 ret = (cross(GSD.N.xyz, normalize(cross(data.xyz, GSD.N.xyz))));
     SVM_GEOM_RET_TANG(ret);
     SVM_GEOM_RET_TF(true);

  }else{

    SVM_GEOM_RET_TF(false);

  }

}


CCL_NAMESPACE_END

#endif


#endif