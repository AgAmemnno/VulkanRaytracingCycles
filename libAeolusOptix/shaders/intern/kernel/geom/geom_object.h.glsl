#ifndef _GEOM_OBJ_H_
#define _GEOM_OBJ_H_
/*
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

/* Object Primitive
 *
 * All mesh and curve primitives are part of an object. The same mesh and curves
 * may be instanced multiple times by different objects.
 *
 * If the mesh is not instanced multiple times, the object will not be explicitly
 * stored as a primitive in_rsv the BVH, rather the bare triangles are curved are
 * directly primitives in_rsv the BVH with world space locations applied, and the object
 * ID is looked up afterwards. */

CCL_NAMESPACE_BEGIN

/* Object attributes, for now a fixed size and contents */

//modify => enum ObjectTransform 
#define ObjectTransform uint
#define  OBJECT_TRANSFORM  0
#define  OBJECT_INVERSE_TRANSFORM 1
//modified ==> ObjectTransform




//modify => enum ObjectVectorTransform 
#define ObjectVectorTransform uint
#define  OBJECT_PASS_MOTION_PRE  0
#define  OBJECT_PASS_MOTION_POST 1
//modified ==> ObjectVectorTransform




/* Object to world space transformation */
ccl_device_inline Transform object_fetch_transform(
                                                   int object,
                                                   ObjectTransform type
)
{
  if (type == OBJECT_INVERSE_TRANSFORM) {
    return kernel_tex_fetch(_objects, object).itfm;
  }
  else {
    return kernel_tex_fetch(_objects, object).tfm;
  }
}

/* Lamp to world space transformation */

ccl_device_inline Transform lamp_fetch_transform( int lamp, bool inverse)
{
  if (inverse) {
    return kernel_tex_fetch(_lights, lamp).itfm;
  }
  else {
    return kernel_tex_fetch(_lights, lamp).tfm;
  }
}

/* Object to world space transformation for motion vectors */

ccl_device_inline Transform object_fetch_motion_pass_transform(
                                                               int object,
                                                               ObjectVectorTransform type
)
{
 #ifdef _OBJECT_MOTION_
  int offset = object * OBJECT_MOTION_PASS_SIZE + int(type);
  
return kernel_tex_fetch(_object_motion_pass, offset);
#else
   Transform tr;
   return tr;
#endif
}

/* Motion blurred object transformations */
#ifdef _OBJECT_MOTION2_
ccl_device_inline Transform object_fetch_transform_motion(
                                                          int object,
                                                          float time)
{
  int motion_offset    = int(kernel_tex_fetch(_objects, object).motion_offset);
  const uint num_steps = kernel_tex_fetch(_objects, object).numsteps * 2 + 1;

  Transform tfm;
  //TODO OBJECT MOTION 
  //transform_motion_array_interpolate((tfm),num_steps, time ,motion_offset);

  return tfm;
}

#endif

#ifdef _OBJECT_MOTION_
ccl_device_inline Transform object_fetch_transform_motion(inout KernelGlobals kg,
                                                          int object,
                                                          float time)
{
  int motion_offset    = int(kernel_tex_fetch(_objects, object).motion_offset);
  const uint num_steps = kernel_tex_fetch(_objects, object).numsteps * 2 + 1;

  Transform tfm;
  transform_motion_array_interpolate((tfm),num_steps, time ,motion_offset);

  return tfm;
}

ccl_device_inline Transform object_fetch_transform_motion_test(inout KernelGlobals kg,
                                                               int object,
                                                               float time,
                                                               inout Transform itfm)
{
  int object_flag = int(kernel_tex_fetch(_object_flag, object));

  if (bool(object_flag & SD_OBJECT_MOTION)
) {
    /* if we do motion blur */
    Transform tfm = object_fetch_transform_motion(kg, object, time);

    if (!(Transform_ISNULL(itfm)))

      itfm = transform_quick_inverse(tfm);

    return tfm;
  }
  else {
    Transform tfm = object_fetch_transform(kg, object, OBJECT_TRANSFORM);
    if (!(Transform_ISNULL(itfm)))

      itfm = object_fetch_transform(kg, object, OBJECT_INVERSE_TRANSFORM);

    return tfm;
  }
}
#endif

#if defined( GSD ) & !defined(GSD_TINY)

/* Transform position from world to object space */

ccl_device_inline void object_inverse_position_transform(
                                                         inout float3 P)
{
#ifdef _OBJECT_MOTION2_
  P = transform_point_auto((GSD.ob_itfm),P);
#else
  Transform tfm = object_fetch_transform(GSD.object, OBJECT_INVERSE_TRANSFORM);
  P = transform_point((tfm),P);
#endif
}

/* Transform normal from world to object space */

ccl_device_inline void object_inverse_normal_transform(
                                                       inout float3 N)
{

#ifdef _OBJECT_MOTION2_
  if ((GSD.object != OBJECT_NONE) || (GSD.type == PRIMITIVE_LAMP)) {
    N = normalize(transform_direction_transposed_auto(GSD.ob_tfm, N));
  }
#else
  if (GSD.object != OBJECT_NONE) {
    Transform tfm = object_fetch_transform(GSD.object, OBJECT_TRANSFORM);
    N = normalize(transform_direction_transposed(tfm, N));
  }
  else if ( GSD>type == PRIMITIVE_LAMP) {
    Transform tfm = lamp_fetch_transform(GSD.lamp, false);
    N = normalize(transform_direction_transposed(tfm, N));
  }
#endif

}


ccl_device_inline void object_normal_transform(inout float3 N)
{
#ifdef _OBJECT_MOTION2_
  N = normalize(transform_direction_transposed_auto((GSD.ob_itfm),N));
#else
  Transform tfm = object_fetch_transform(GSD.object, OBJECT_INVERSE_TRANSFORM);
  N = normalize(transform_direction_transposed(tfm, N));
#endif

}
ccl_device_inline void object_dir_transform(inout float3 D)
{

#ifdef _OBJECT_MOTION2_
  D = transform_direction_auto((GSD.ob_tfm),D);
#else
  Transform tfm = object_fetch_transform(GSD.object, OBJECT_TRANSFORM);
  D = transform_direction(tfm, D);
#endif
}

ccl_device_inline void object_inverse_dir_transform(float3 D)
{
#ifdef _OBJECT_MOTION2_
  D = transform_direction_auto((GSD.ob_itfm),D);
#else
  Transform tfm = object_fetch_transform(GSD.object, OBJECT_INVERSE_TRANSFORM);
  D = transform_direction(tfm, D);
#endif
}

/* Object center position */
ccl_device_inline float3 object_location()
{
  if (GSD.object == OBJECT_NONE)
    return make_float3(0.0f, 0.0f, 0.0f);
#ifdef _OBJECT_MOTION2_
   return make_float3(GSD.ob_tfm.x.w, GSD.ob_tfm.y.w, GSD.ob_tfm.z.w);
#else
  Transform tfm = object_fetch_transform(GSD.object, OBJECT_TRANSFORM);
  return make_float3(tfm.x.w, tfm.y.w, tfm.z.w);
#endif

}

ccl_device_inline void object_position_transform(inout float3 P)
{
#ifdef _OBJECT_MOTION2_
  P = transform_point_auto(GSD.ob_tfm, P);
#else
  Transform tfm = object_fetch_transform(GSD.object,OBJECT_TRANSFORM);
  P = transform_point((tfm),P);
#endif
}


#endif


/* Total surface area of object */

ccl_device_inline float object_surface_area(int object)
{
  return kernel_tex_fetch(_objects, object).surface_area;
}

/* Color of the object */

ccl_device_inline float3 object_color( int object)
{
  if (object == OBJECT_NONE)
    return make_float3(0.0f, 0.0f, 0.0f);

  const ccl_global KernelObject kobject = kernel_tex_fetch(_objects, object);

  return make_float3(kobject.color[0], kobject.color[1], kobject.color[2]);
}

/* Pass ID number of object */

ccl_device_inline float object_pass_id(int object)
{
  if (object == OBJECT_NONE)
    return 0.0f;

  return kernel_tex_fetch(_objects, object).pass_id;
}

/* Per lamp random number for shader variation */

ccl_device_inline float lamp_random_number( int lamp)
{
  if (lamp == LAMP_NONE)
    return 0.0f;

  return kernel_tex_fetch(_lights, lamp).random;
}

/* Per object random number for shader variation */

ccl_device_inline float object_random_number( int object)
{
  if (object == OBJECT_NONE)
    return 0.0f;

  return kernel_tex_fetch(_objects, object).random_number;
}

/* Particle ID from which this object was generated */

ccl_device_inline int object_particle_id(int object)
{
  if (object == OBJECT_NONE)
    return 0;

  return kernel_tex_fetch(_objects, object).particle_index;
}

/* Generated texture coordinate on surface from where object was instanced */

ccl_device_inline float3 object_dupli_generated(int object)
{
  if (object == OBJECT_NONE)
    return make_float3(0.0f, 0.0f, 0.0f);

  const ccl_global KernelObject kobject = kernel_tex_fetch(_objects, object);

  return make_float3(
      kobject.dupli_generated[0], kobject.dupli_generated[1], kobject.dupli_generated[2]);
}

/* UV texture coordinate on surface from where object was instanced */

ccl_device_inline float3 object_dupli_uv(int object)
{
  if (object == OBJECT_NONE)
    return make_float3(0.0f, 0.0f, 0.0f);

  const ccl_global KernelObject kobject = kernel_tex_fetch(_objects, object);

  return make_float3(kobject.dupli_uv[0], kobject.dupli_uv[1], 0.0f);
}

/* Information about mesh for motion blurred triangles and curves */

ccl_device_inline void object_motion_info(int object, inout int numsteps, inout int numverts, inout int numkeys)
{
   if (!isNULL(numkeys))
 {
    numkeys = kernel_tex_fetch(_objects, object).numkeys;
  }

   if (!isNULL(numkeys))

    numsteps = kernel_tex_fetch(_objects, object).numsteps;
   if (!isNULL(numkeys))

    numverts = kernel_tex_fetch(_objects, object).numverts;
}

/* Offset to an objects patch_rsv map */

ccl_device_inline uint object_patch_map_offset( int object)
{
  if (object == OBJECT_NONE)
    return 0;

  return kernel_tex_fetch(_objects, object).patch_map_offset;
}

/* Volume step size */

ccl_device_inline float object_volume_density(int object)
{
  if (object == OBJECT_NONE) {
    return 1.0f;
  }

  return kernel_tex_fetch(_objects, object).surface_area;
}


/* Pass ID for shader */
#ifdef NODE_CALLER


ccl_device_inline float object_volume_step_size(int object)
{
  if (object == OBJECT_NONE) {
    return kernel_data.background.volume_step_size;
  }

  return kernel_tex_fetch(_object_volume_step, object);
}



ccl_device int shader_pass_id(in ShaderData sd)
{
  return kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).pass_id;
}
#endif

/* Cryptomatte ID */

ccl_device_inline float object_cryptomatte_id(int object)
{
  if (object == OBJECT_NONE)
    return 0.0f;

  return kernel_tex_fetch(_objects, object).cryptomatte_object;
}

ccl_device_inline float object_cryptomatte_asset_id(int object)
{
  if (object == OBJECT_NONE)
    return 0;

  return kernel_tex_fetch(_objects, object).cryptomatte_asset;
}

/* Particle data from which object was instanced */
#define particle_index(particle) kernel_tex_fetch(_particles, particle).index
#define particle_age(particle) kernel_tex_fetch(_particles, particle).age
#define particle_lifetime(particle) kernel_tex_fetch(_particles, particle).lifetime
#define particle_size(particle) kernel_tex_fetch(_particles, particle).size
#define particle_rotation(particle) kernel_tex_fetch(_particles, particle).rotation
#define particle_location(particle) float4_to_float3(kernel_tex_fetch(_particles, particle).location)
#define particle_velocity(particle) float4_to_float3(kernel_tex_fetch(_particles, particle).velocity)
#define particle_angular_velocity(particle) float4_to_float3(kernel_tex_fetch(_particles, particle).angular_velocity)

/* Object intersection in_rsv BVH */

ccl_device_inline float3 bvh_clamp_direction(float3 dir)
{
  const float ooeps = 8.271806E-25f;
  return make_float3((fabsf(dir.x) > ooeps) ? dir.x : copysignf(ooeps, dir.x),
                     (fabsf(dir.y) > ooeps) ? dir.y : copysignf(ooeps, dir.y),
                     (fabsf(dir.z) > ooeps) ? dir.z : copysignf(ooeps, dir.z));
}

ccl_device_inline float3 bvh_inverse_direction(float3 dir)
{
  return rcp(dir);
}

/* Transform ray into object space to enter static object in_rsv BVH */

ccl_device_inline float bvh_instance_push(
     int object, in Ray ray, inout float3 P, inout float3 dir, inout float3 idir, float t)
{
  Transform tfm = object_fetch_transform(object, OBJECT_INVERSE_TRANSFORM);

  P = transform_point((tfm),
 ray.P);

  float len;
  dir = bvh_clamp_direction(normalize_len(transform_direction((tfm),
 ray.D), (len))
);
  idir = bvh_inverse_direction(dir);

  if (t != FLT_MAX) {
    t *= len;
  }

  return t;
}

/* Transorm ray to exit static object in_rsv BVH */

ccl_device_inline float bvh_instance_pop(
    int object, in Ray ray, inout float3 P, inout float3 dir, inout float3 idir, float t)
{
  if (t != FLT_MAX) {
    Transform tfm = object_fetch_transform(object, OBJECT_INVERSE_TRANSFORM);
    t /= len3(transform_direction((tfm),ray.D));
  }

  P = ray.P;
  dir = bvh_clamp_direction(ray.D);
  idir = bvh_inverse_direction(dir);

  return t;
}

/* Same as above, but returns scale factor to apply to multiple intersection distances */

ccl_device_inline void bvh_instance_pop_factor(
                                               int object,
                                               in Ray ray,
                                               inout float3 P,
                                               inout float3 dir,
                                               inout float3 idir,
                                               inout float t_fac)
{
  Transform tfm = object_fetch_transform(object, OBJECT_INVERSE_TRANSFORM);
  t_fac = 1.0f / len3(transform_direction((tfm),ray.D));

  P = ray.P;
  dir = bvh_clamp_direction(ray.D);
  idir = bvh_inverse_direction(dir);
}

#ifdef _OBJECT_MOTION_
/* Transform ray into object space to enter motion blurred object in_rsv BVH */

ccl_device_inline float bvh_instance_motion_push(inout KernelGlobals kg,
                                                 int object,
                                                 in Ray ray,
                                                 inout float3 P,
                                                 inout float3 dir,
                                                 inout float3 idir,
                                                 float t,
                                                 inout Transform itfm)
{
  object_fetch_transform_motion_test(kg, object, ray.time, itfm);

  P = transform_point(itfm, ray.P);

  float len;
  dir = bvh_clamp_direction(normalize_len(transform_direction(itfm, ray.D), (len))
);
  idir = bvh_inverse_direction(dir);

  if (t != FLT_MAX) {
    t *= len;
  }

  return t;
}

/* Transorm ray to exit motion blurred object in_rsv BVH */

ccl_device_inline float bvh_instance_motion_pop(inout KernelGlobals kg,
                                                int object,
                                                in Ray ray,
                                                inout float3 P,
                                                inout float3 dir,
                                                inout float3 idir,
                                                float t,
                                                inout Transform itfm)
{
  if (t != FLT_MAX) {
    t /= len(transform_direction(itfm, ray.D));
  }

  P = ray.P;
  dir = bvh_clamp_direction(ray.D);
  idir = bvh_inverse_direction(dir);

  return t;
}

/* Same as above, but returns scale factor to apply to multiple intersection distances */

ccl_device_inline void bvh_instance_motion_pop_factor(inout KernelGlobals kg,
                                                      int object,
                                                      in Ray ray,
                                                      inout float3 P,
                                                      inout float3 dir,
                                                      inout float3 idir,
                                                      inout float t_fac,
                                                      inout Transform itfm)
{
  t_fac = 1.0f / len(transform_direction(itfm, ray.D));
  P = ray.P;
  dir = bvh_clamp_direction(ray.D);
  idir = bvh_inverse_direction(dir);
}

#endif




#  define object_position_transform_auto object_position_transform
#  define object_dir_transform_auto object_dir_transform
#  define object_normal_transform_auto object_normal_transform


CCL_NAMESPACE_END
#endif