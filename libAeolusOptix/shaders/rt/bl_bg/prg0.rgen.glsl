#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable




#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"


#include "kernel/kernel_globals.h.glsl"
#include "kernel/kernel_differential.h.glsl"
#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_montecarlo.h.glsl"
#include "kernel/kernel_projection.h.glsl"


struct hitPayload
{
    float3 throughput;
    PathRadiance L;
    PathState state;
    ShaderData            sd;
    //ShaderDataTinyStorage esd;
};

layout(location = 0) rayPayloadNV hitPayload prd;
layout(binding = 0, set = 0) uniform accelerationStructureNV topLevelAS;
layout(binding = 1, set = 0, rgba8) uniform image2D image;



layout(binding = 0, set = 1) uniform CameraProperties
{
  mat4 view;
  mat4 proj;
  mat4 viewInverse;
  mat4 projInverse;
} cam;




/* Common */
ccl_device float2 camera_sample_aperture( float u, float v)
{
  float blades = kernel_data.cam.blades;
  float2 bokeh;

  if (blades == 0.0f) {
    /* sample disk */
    bokeh = concentric_sample_disk(u, v);
  }
  else {
    /* sample polygon */
    float rotation = kernel_data.cam.bladesrotation;
    bokeh = regular_polygon_sample(blades, rotation, u, v);
  }

  /* anamorphic lens bokeh */
  bokeh.x *= kernel_data.cam.inv_aperture_ratio;

  return bokeh;
}

/* Orthographic Camera */
ccl_device void camera_sample_orthographic(
                                           float raster_x,
                                           float raster_y,
                                           float lens_u,
                                           float lens_v,
                                           ccl_addr_space inout Ray ray)
{
  /* create ray form raster position */
  ProjectionTransform rastertocamera = kernel_data.cam.rastertocamera;
  float3 Pcamera = transform_perspective((rastertocamera), make_float3(raster_x, raster_y, 0.0f));


  float3 P;
  float3 D = make_float3(0.0f, 0.0f, 1.0f);

  /* modify ray for depth of field */
  float aperturesize = kernel_data.cam.aperturesize;

  if (aperturesize > 0.0f) {
    /* sample point on aperture */
    float2 lensuv = camera_sample_aperture(lens_u, lens_v) * aperturesize;

    /* compute point on plane of focus */
    float3 Pfocus = D * kernel_data.cam.focaldistance;

    /* update ray for effect of lens */
    float3 lensuvw = make_float3(lensuv.x, lensuv.y, 0.0f);
    P = Pcamera + lensuvw;
    D = normalize(Pfocus - lensuvw);
  }
  else {
    P = Pcamera;
  }
  /* transform ray from camera to world */
  Transform cameratoworld = kernel_data.cam.cameratoworld;

#ifdef _CAMERA_MOTION_
  if (bool(kernel_data.cam.num_motion_steps)) {

    transform_motion_array_interpolate(cameratoworld,
                                       kernel_data.cam.num_motion_steps,
                                       ray.time,0);
  }
#endif

  ray.P = transform_point((cameratoworld), P);

  ray.D = normalize(transform_direction((cameratoworld), D));


#ifdef _RAY_DIFFERENTIALS_
  /* ray differential */
  ray.dP.dx = float4_to_float3(kernel_data.cam.dx);
  ray.dP.dy = float4_to_float3(kernel_data.cam.dy);

  ray.dD = differential3_zero();
#endif

#ifdef _CAMERA_CLIPPING_
  /* clipping */
  ray.t = kernel_data.cam.cliplength;
#else
  ray.t = FLT_MAX;
#endif
}

ccl_device void camera_sample_perspective(
                                          float raster_x,
                                          float raster_y,
                                          float lens_u,
                                          float lens_v,
                                          ccl_addr_space inout Ray ray)
{
  /* create ray form raster position */
  ProjectionTransform rastertocamera = kernel_data.cam.rastertocamera;
  float3 raster = make_float3(raster_x, raster_y, 0.0f);
  float3 Pcamera = transform_perspective((rastertocamera), raster);


#ifdef _CAMERA_MOTION_
  if (bool(kernel_data.cam.have_perspective_motion)) {

    /* TODO(sergey): Currently we interpolate projected coordinate which
     * gives nice looking result and which is simple, but is in fact a bit
     * different comparing to constructing projective matrix from an
     * interpolated field of view.
     */
    if (ray.time < 0.5f) {
      ProjectionTransform rastertocamera_pre = kernel_data.cam.perspective_pre;
      float3 Pcamera_pre = transform_perspective((rastertocamera_pre), raster);

      Pcamera = interp(Pcamera_pre, Pcamera, ray.time * 2.0f);
    }
    else {
      ProjectionTransform rastertocamera_post = kernel_data.cam.perspective_post;
      float3 Pcamera_post = transform_perspective((rastertocamera_post), raster);

      Pcamera = interp(Pcamera, Pcamera_post, (ray.time - 0.5f) * 2.0f);
    }
  }
#endif

  float3 P = make_float3(0.0f, 0.0f, 0.0f);
  float3 D = Pcamera;

  /* modify ray for depth of field */
  float aperturesize = kernel_data.cam.aperturesize;

  if (aperturesize > 0.0f) {
    /* sample point on aperture */
    float2 lensuv = camera_sample_aperture(lens_u, lens_v) * aperturesize;

    /* compute point on plane of focus */
    float ft = kernel_data.cam.focaldistance / D.z;
    float3 Pfocus = D * ft;

    /* update ray for effect of lens */
    P = make_float3(lensuv.x, lensuv.y, 0.0f);
    D = normalize(Pfocus - P);
  }

  /* transform ray from camera to world */
  Transform cameratoworld = kernel_data.cam.cameratoworld;

#ifdef _CAMERA_MOTION_
  if (bool(kernel_data.cam.num_motion_steps)) {


    transform_motion_array_interpolate(cameratoworld,
                                    kernel_data.cam.num_motion_steps,
                                    ray.time,0);
  }
#endif

  P = transform_point((cameratoworld), P);

  D = normalize(transform_direction((cameratoworld), D));


  bool use_stereo = kernel_data.cam.interocular_offset != 0.0f;
  if (!use_stereo) {
    /* No stereo */
    ray.P = P;
    ray.D = D;

#ifdef _RAY_DIFFERENTIALS_
    float3 Dcenter = transform_direction((cameratoworld), Pcamera);


    ray.dP = differential3_zero();
    ray.dD.dx = normalize(Dcenter + float4_to_float3(kernel_data.cam.dx)) - normalize(Dcenter);
    ray.dD.dy = normalize(Dcenter + float4_to_float3(kernel_data.cam.dy)) - normalize(Dcenter);
#endif
  }
  else {
    /* Spherical stereo */
    spherical_stereo_transform( P, D);

    ray.P = P;
    ray.D = D;

#ifdef _RAY_DIFFERENTIALS_
    /* Ray differentials, computed from scratch using the raster coordinates
     * because we don't want to be affected by depth of field. We compute
     * ray origin and direction for the center and two neighboring pixels
     * and simply take their differences. */
    float3 Pnostereo = transform_point((cameratoworld), make_float3(0.0f, 0.0f, 0.0f));


    float3 Pcenter = Pnostereo;
    float3 Dcenter = Pcamera;
    Dcenter = normalize(transform_direction((cameratoworld), Dcenter));

    spherical_stereo_transform( Pcenter, Dcenter);


    float3 Px = Pnostereo;
    float3 Dx = transform_perspective((rastertocamera),

                                      make_float3(raster_x + 1.0f, raster_y, 0.0f));
    Dx = normalize(transform_direction((cameratoworld), Dx));

    spherical_stereo_transform( Px, Dx);


    ray.dP.dx = Px - Pcenter;
    ray.dD.dx = Dx - Dcenter;

    float3 Py = Pnostereo;
    float3 Dy = transform_perspective((rastertocamera),

                                      make_float3(raster_x, raster_y + 1.0f, 0.0f));
    Dy = normalize(transform_direction((cameratoworld), Dy));

    spherical_stereo_transform( Py, Dy);


    ray.dP.dy = Py - Pcenter;
    ray.dD.dy = Dy - Dcenter;
#endif
  }

#ifdef _CAMERA_CLIPPING_
  /* clipping */
  float z_inv = 1.0f / normalize(Pcamera).z;
  float nearclip = kernel_data.cam.nearclip * z_inv;
  ray.P += nearclip * ray.D;
  ray.dP.dx += nearclip * ray.dD.dx;
  ray.dP.dy += nearclip * ray.dD.dy;
  ray.t = kernel_data.cam.cliplength * z_inv;
#else
  ray.t = FLT_MAX;
#endif
}
/* Panorama Camera */

ccl_device_inline void camera_sample_panorama(
#ifdef _CAMERA_MOTION_
                                              int cam_motion_ofs,
#endif
                                              float raster_x,
                                              float raster_y,
                                              float lens_u,
                                              float lens_v,
                                              ccl_addr_space inout Ray ray)
{
  ProjectionTransform rastertocamera = kernel_data.cam.rastertocamera;
  float3 Pcamera = transform_perspective((rastertocamera), make_float3(raster_x, raster_y, 0.0f));


  /* create ray form raster position */
  float3 P = make_float3(0.0f, 0.0f, 0.0f);
  float3 D = panorama_to_direction(Pcamera.x, Pcamera.y);

  /* indicates ray should not receive any light, outside of the lens */
  if (is_zero(D)) {
    ray.t = 0.0f;
    return;
  }

  /* modify ray for depth of field */
  float aperturesize = kernel_data.cam.aperturesize;

  if (aperturesize > 0.0f) {
    /* sample point on aperture */
    float2 lensuv = camera_sample_aperture(lens_u, lens_v) * aperturesize;

    /* compute point on plane of focus */
    float3 Dfocus = normalize(D);
    float3 Pfocus = Dfocus * kernel_data.cam.focaldistance;

    /* calculate orthonormal coordinates perpendicular to Dfocus */
    float3 U, V;
    U = normalize(make_float3(1.0f, 0.0f, 0.0f) - Dfocus.x * Dfocus);
    V = normalize(cross(Dfocus, U));

    /* update ray for effect of lens */
    P = U * lensuv.x + V * lensuv.y;
    D = normalize(Pfocus - P);
  }

  /* transform ray from camera to world */
  Transform cameratoworld = kernel_data.cam.cameratoworld;

#ifdef _CAMERA_MOTION_
  if (bool(kernel_data.cam.num_motion_steps)) {
    transform_motion_array_interpolate(
        cameratoworld, kernel_data.cam.num_motion_steps, ray.time,cam_motion_ofs);
  }
#endif

  P = transform_point((cameratoworld), P);

  D = normalize(transform_direction((cameratoworld), D));


  /* Stereo transform */
  bool use_stereo = kernel_data.cam.interocular_offset != 0.0f;
  if (use_stereo) {
    spherical_stereo_transform(P, D);
  }

  ray.P = P;
  ray.D = D;

#ifdef _RAY_DIFFERENTIALS_
  /* Ray differentials, computed from scratch using the raster coordinates
   * because we don't want to be affected by depth of field. We compute
   * ray origin and direction for the center and two neighboring pixels
   * and simply take their differences. */
  float3 Pcenter = Pcamera;
  float3 Dcenter = panorama_to_direction(Pcenter.x, Pcenter.y);
  Pcenter = transform_point((cameratoworld), Pcenter);

  Dcenter = normalize(transform_direction((cameratoworld), Dcenter));

  if (use_stereo) {
    spherical_stereo_transform(Pcenter, Dcenter);
  }

  float3 Px = transform_perspective((rastertocamera), make_float3(raster_x + 1.0f, raster_y, 0.0f));

  float3 Dx = panorama_to_direction(Px.x, Px.y);
  Px = transform_point((cameratoworld), Px);

  Dx = normalize(transform_direction((cameratoworld), Dx));

  if (use_stereo) {
    spherical_stereo_transform(Px, Dx);
  }

  ray.dP.dx = Px - Pcenter;
  ray.dD.dx = Dx - Dcenter;

  float3 Py = transform_perspective((rastertocamera), make_float3(raster_x, raster_y + 1.0f, 0.0f));

  float3 Dy = panorama_to_direction(Py.x, Py.y);
  Py = transform_point((cameratoworld), Py);

  Dy = normalize(transform_direction((cameratoworld), Dy));

  if (use_stereo) {
    spherical_stereo_transform(Py, Dy);
  }

  ray.dP.dy = Py - Pcenter;
  ray.dD.dy = Dy - Dcenter;
#endif

#ifdef _CAMERA_CLIPPING_
  /* clipping */
  float nearclip = kernel_data.cam.nearclip;
  ray.P += nearclip * ray.D;
  ray.dP.dx += nearclip * ray.dD.dx;
  ray.dP.dy += nearclip * ray.dD.dy;
  ray.t = kernel_data.cam.cliplength;
#else
  ray.t = FLT_MAX;
#endif
}

ccl_device_inline void camera_sample(
                                     int x,
                                     int y,
                                     float filter_u,
                                     float filter_v,
                                     float lens_u,
                                     float lens_v,
                                     float time,
                                     ccl_addr_space inout Ray ray)
{
  /* pixel filter */
  int filter_table_offset = kernel_data.film.filter_table_offset;
  float raster_x = x + lookup_table_read( filter_u, filter_table_offset, int(FILTER_TABLE_SIZE));
  float raster_y = y + lookup_table_read( filter_v, filter_table_offset, int(FILTER_TABLE_SIZE));

#ifdef _CAMERA_MOTION_
  /* motion blur */
  if (kernel_data.cam.shuttertime == -1.0f) {
    ray.time = 0.5f;
  }
  else {
    /* TODO(sergey): Such lookup is unneeded when there's rolling shutter
     * effect in use but rolling shutter duration is set to 0.0.
     */
    const int shutter_table_offset = kernel_data.cam.shutter_table_offset;
    ray.time = lookup_table_read(time, shutter_table_offset, SHUTTER_TABLE_SIZE);
    /* TODO(sergey): Currently single rolling shutter effect type only
     * where scan-lines are acquired from top to bottom and whole scan-line
     * is acquired at once (no delay in acquisition happens between pixels
     * of single scan-line).
     *
     * Might want to support more models in the future.
     */
    if (bool(kernel_data.cam.rolling_shutter_type)) {

      /* Time corresponding to a fully rolling shutter only effect:
       * top of the frame is time 0.0, bottom of the frame is time 1.0.
       */
      const float time = 1.0f - float(y) / kernel_data.cam.height;

      const float duration = kernel_data.cam.rolling_shutter_duration;
      if (duration != 0.0f) {
        /* This isn't fully physical correct, but lets us to have simple
         * controls in the interface. The idea here is basically sort of
         * linear interpolation between how much rolling shutter effect
         * exist on the frame and how much of it is a motion blur effect.
         */
        ray.time = (ray.time - 0.5f) * duration;
        ray.time += (time - 0.5f) * (1.0f - duration) + 0.5f;
      }
      else {
        ray.time = time;
      }
    }
  }
#endif

  /* sample */
  if (kernel_data.cam.type == CAMERA_PERSPECTIVE) {
    camera_sample_perspective(raster_x, raster_y, lens_u, lens_v, ray);
  }
  else if (kernel_data.cam.type == CAMERA_ORTHOGRAPHIC) {
    camera_sample_orthographic(raster_x, raster_y, lens_u, lens_v, ray);
  }
  else {
#ifdef _CAMERA_MOTION_
    camera_sample_panorama(0, raster_x, raster_y, lens_u, lens_v, ray);

#else
    camera_sample_panorama(raster_x, raster_y, lens_u, lens_v, ray);

#endif

  }
}


void kernel_path_trace_setup(
  int sample_rsv,inout  uint rng_hash, inout  Ray ray)
{
  float filter_u;
  float filter_v;
  int x = int(gl_LaunchIDNV.x);
  int y = int(gl_LaunchIDNV.y);

  int num_samples = kernel_data.integrator.aa_samples;

  path_rng_init(sample_rsv, num_samples, rng_hash, x, y, filter_u, filter_v);

  /* sample camera ray */

  float lens_u = 0.0f, lens_v = 0.0f;

  if (kernel_data.cam.aperturesize > 0.0f)
    path_rng_2D(rng_hash, sample_rsv, num_samples, int(PRNG_LENS_U), lens_u, lens_v);

  float time = 0.0f;

#ifdef _CAMERA_MOTION_
  if (kernel_data.cam.shuttertime != -1.0f)
    time = path_rng_1D(rng_hash, sample_rsv, num_samples, int(PRNG_TIME));
#endif

  camera_sample(x, y, filter_u, filter_v, lens_u, lens_v, time, ray);
}


void path_state_init(
                                       uint rng_hash,
                                       int sample_rsv)
{
  prd.state.flag = int(PATH_RAY_CAMERA | PATH_RAY_MIS_SKIP | PATH_RAY_TRANSPARENT_BACKGROUND);

  prd.state.rng_hash = rng_hash;
  prd.state.rng_offset = int(PRNG_BASE_NUM);
  prd.state.sample_rsv = sample_rsv;
  prd.state.num_samples = kernel_data.integrator.aa_samples;
  prd.state.branch_factor = 1.0f;

  prd.state.bounce = 0;
  prd.state.diffuse_bounce = 0;
  prd.state.glossy_bounce = 0;
  prd.state.transmission_bounce = 0;
  prd.state.transparent_bounce = 0;

#ifdef _DENOISING_FEATURES_
  if (kernel_data.film.pass_denoising_data) {
    prd.state.flag |= PATH_RAY_STORE_SHADOW_INFO;
    prd.state.denoising_feature_weight = 1.0f;
    prd.state.denoising_feature_throughput = make_float3(1.0f, 1.0f, 1.0f);
  }
  else {
    prd.state.denoising_feature_weight = 0.0f;
    prd.state.denoising_feature_throughput = make_float3(0.0f, 0.0f, 0.0f);
  }
#endif /* __DENOISING_FEATURES__ */

  prd.state.min_ray_pdf = FLT_MAX;
  prd.state.ray_pdf = 0.0f;
#ifdef _LAMP_MIS_
  prd.state.ray_t = 0.0f;
#endif

#ifdef _VOLUME_
  prd.state.volume_bounce = 0;
  prd.state.volume_bounds_bounce = 0;

  if (kernel_data.integrator.use_volumes) {
    /* Initialize volume stack with volume we are inside of. */
    kernel_volume_stack_init(kg, stack_sd, state, ray, prd.state.volume_stack);
  }
  else {
    prd.state.volume_stack[0].shader = SHADER_NONE;
  }
#endif
}

void path_radiance_init()
{
  /* clear all */
#ifdef _PASSES_
  prd.L.use_light_pass = kernel_data.film.use_light_pass;

  if (kernel_data.film.use_light_pass !=0) {
    prd.L.indirect = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.direct_emission = make_float3(0.0f, 0.0f, 0.0f);

    prd.L.color_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.color_glossy = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.color_transmission = make_float3(0.0f, 0.0f, 0.0f);

    prd.L.direct_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.direct_glossy = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.direct_transmission = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.direct_volume = make_float3(0.0f, 0.0f, 0.0f);

    prd.L.indirect_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.indirect_glossy = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.indirect_transmission = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.indirect_volume = make_float3(0.0f, 0.0f, 0.0f);

    prd.L.transparent = 0.0f;
    prd.L.emission = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.background = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.ao = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.shadow = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    prd.L.mist = 0.0f;

    prd.L.state.diffuse = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.state.glossy = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.state.transmission = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.state.volume = make_float3(0.0f, 0.0f, 0.0f);
    prd.L.state.direct = make_float3(0.0f, 0.0f, 0.0f);
  }
  else
#endif
  {
    prd.L.transparent = 0.0f;
    prd.L.emission = make_float3(0.0f, 0.0f, 0.0f);
  }

#ifdef _SHADOW_TRICKS_
  prd.L.path_total = make_float3(0.0f, 0.0f, 0.0f);
  prd.L.path_total_shaded = make_float3(0.0f, 0.0f, 0.0f);
  prd.L.shadow_background_color = make_float3(0.0f, 0.0f, 0.0f);
  prd.L.shadow_throughput = 0.0f;
  prd.L.shadow_transparency = 1.0f;
  prd.L.has_shadow_catcher = 0;
#endif

#ifdef _DENOISING_FEATURES_
  prd.L.denoising_normal = make_float3(0.0f, 0.0f, 0.0f);
  prd.L.denoising_albedo = make_float3(0.0f, 0.0f, 0.0f);
  prd.L.denoising_depth = 0.0f;
#endif

#ifdef _KERNEL_DEBUG_
  prd.L.debug_data.num_bvh_traversed_nodes = 0;
  prd.L.debug_data.num_bvh_traversed_instances = 0;
  prd.L.debug_data.num_bvh_intersections = 0;
  prd.L.debug_data.num_ray_bounces = 0;
#endif
}

ccl_device_inline void path_radiance_sum_indirect()
{
#ifdef _PASSES_
  /* this division is a bit ugly, but means we only have to keep track of
   * only a single throughput further along the path, here we recover just
   * the indirect path that is not influenced by any particular BSDF type */
  if (prd.L.use_light_pass!=0) {
    prd.L.direct_emission = safe_divide_color(prd.L.direct_emission, prd.L.state.direct);
    prd.L.direct_diffuse += prd.L.state.diffuse * prd.L.direct_emission;
    prd.L.direct_glossy += prd.L.state.glossy * prd.L.direct_emission;
    prd.L.direct_transmission += prd.L.state.transmission * prd.L.direct_emission;
    prd.L.direct_volume += prd.L.state.volume * prd.L.direct_emission;

    prd.L.indirect = safe_divide_color(prd.L.indirect, prd.L.state.direct);
    prd.L.indirect_diffuse += prd.L.state.diffuse * prd.L.indirect;
    prd.L.indirect_glossy += prd.L.state.glossy * prd.L.indirect;
    prd.L.indirect_transmission += prd.L.state.transmission * prd.L.indirect;
    prd.L.indirect_volume += prd.L.state.volume * prd.L.indirect;
  }
#endif
}
#ifdef _SHADOW_TRICKS_

ccl_device_inline void path_radiance_sum_shadowcatcher(
                                                       inout float3 L_sum,
                                                       inout float alpha)
{
  /* Calculate current shadow of the path. */
  float path_total = average(prd.L.path_total);
  float shadow;

  if (UNLIKELY(!isfinite_safe(path_total))) {
    //kernel_assert(!"Non-finite total radiance along the path");
    kernel_assert(false);
    shadow = 0.0f;
  }
  else if (path_total == 0.0f) {
    shadow = prd.L.shadow_transparency;
  }
  else {
    float path_total_shaded = average(prd.L.path_total_shaded);
    shadow = path_total_shaded / path_total;
  }

  /* Calculate final light sum and transparency for shadow catcher object. */
  if (kernel_data.background.transparent!=0) {
    alpha -= prd.L.shadow_throughput * shadow;
  }
  else {
    prd.L.shadow_background_color *= shadow;
    L_sum += prd.L.shadow_background_color;
  }
}
#endif
ccl_device_inline float3 path_radiance_clamp_and_sum(
                                                     inout float alpha)
{
  float3 L_sum;
  // Light Passes are used 
#ifdef _PASSES_
  float3 L_direct, L_indirect;
  if (prd.L.use_light_pass!=0) {
    path_radiance_sum_indirect();

    L_direct = prd.L.direct_diffuse + prd.L.direct_glossy + prd.L.direct_transmission + prd.L.direct_volume +
               prd.L.emission;
    L_indirect = prd.L.indirect_diffuse + prd.L.indirect_glossy + prd.L.indirect_transmission +
                 prd.L.indirect_volume;

    if (kernel_data.background.transparent ==0)
      L_direct += prd.L.background;

    L_sum = L_direct + L_indirect;
    float sum = fabsf(L_sum.x) + fabsf(L_sum.y) + fabsf(L_sum.z);

    /* Reject invalid value */
    if (!isfinite_safe(sum)) {
      
      //kernel_assert(!"Non-finite sum in path_radiance_clamp_and_sum!");
      kernel_assert(false);
      L_sum = make_float3(0.0f, 0.0f, 0.0f);

      prd.L.direct_diffuse = make_float3(0.0f, 0.0f, 0.0f);
      prd.L.direct_glossy = make_float3(0.0f, 0.0f, 0.0f);
      prd.L.direct_transmission = make_float3(0.0f, 0.0f, 0.0f);
      prd.L.direct_volume = make_float3(0.0f, 0.0f, 0.0f);

      prd.L.indirect_diffuse = make_float3(0.0f, 0.0f, 0.0f);
      prd.L.indirect_glossy = make_float3(0.0f, 0.0f, 0.0f);
      prd.L.indirect_transmission = make_float3(0.0f, 0.0f, 0.0f);
      prd.L.indirect_volume = make_float3(0.0f, 0.0f, 0.0f);

      prd.L.emission = make_float3(0.0f, 0.0f, 0.0f);
    }
  }

  // No Light Passes 
  else
#endif
  {
    L_sum = prd.L.emission;

    //Reject invalid value 
    float sum = fabsf(L_sum.x) + fabsf(L_sum.y) + fabsf(L_sum.z);
    if (!isfinite_safe(sum)) {
      //kernel_assert(!"Non-finite sum in path_radiance_clamp_and_sum!");
      kernel_assert(false);
      L_sum = make_float3(0.0f, 0.0f, 0.0f);
    }
  }

  // Compute alpha. 
  alpha = 1.0f - prd.L.transparent;

  // Add shadow catcher contributions. 
#ifdef _SHADOW_TRICKS_
  if (prd.L.has_shadow_catcher!=0) {
    path_radiance_sum_shadowcatcher(L_sum, alpha);
  }
#endif // _SHADOW_TRICKS_ 

  return L_sum;
}

ccl_device_inline void kernel_write_result()
{
  PROFILING_INIT(kg, PROFILING_WRITE_RESULT);
  PROFILING_OBJECT(PRIM_NONE);

  ivec2 dim = imageSize(image);
  
  float alpha;
  float3 L_sum = path_radiance_clamp_and_sum(alpha);

  /*if (bool(kernel_data.film.pass_flag & PASSMASK(COMBINED))){
   // kernel_write_pass_float4(buffer, 
    imageStore(image, ivec2(gl_LaunchIDNV.x,dim.y - gl_LaunchIDNV.y), make_float4(L_sum.x, L_sum.y, L_sum.z, alpha));
  }*/
 imageStore(image, ivec2(gl_LaunchIDNV.x,dim.y - gl_LaunchIDNV.y), make_float4(L_sum.x, L_sum.y, L_sum.z, 1.0));//alpha));
  //kernel_write_light_passes(kg, buffer, L);

#ifdef _DENOISING_FEATURES_
  if (kernel_data.film.pass_denoising_data) {
#  ifdef __SHADOW_TRICKS__
    kernel_write_denoising_shadow(kg,
                                  buffer + kernel_data.film.pass_denoising_data,
                                  sample,
                                  average(L->path_total),
                                  average(L->path_total_shaded));
#  else
    kernel_write_denoising_shadow(
        kg, buffer + kernel_data.film.pass_denoising_data, sample, 0.0f, 0.0f);
#  endif
    if (kernel_data.film.pass_denoising_clean) {
      float3 noisy, clean;
      path_radiance_split_denoising(kg, L, &noisy, &clean);
      kernel_write_pass_float3_variance(
          buffer + kernel_data.film.pass_denoising_data + DENOISING_PASS_COLOR, noisy);
      kernel_write_pass_float3_unaligned(buffer + kernel_data.film.pass_denoising_clean, clean);
    }
    else {
      kernel_write_pass_float3_variance(buffer + kernel_data.film.pass_denoising_data +
                                            DENOISING_PASS_COLOR,
                                        ensure_finite3(L_sum));
    }

    kernel_write_pass_float3_variance(buffer + kernel_data.film.pass_denoising_data +
                                          DENOISING_PASS_NORMAL,
                                      L->denoising_normal);
    kernel_write_pass_float3_variance(buffer + kernel_data.film.pass_denoising_data +
                                          DENOISING_PASS_ALBEDO,
                                      L->denoising_albedo);
    kernel_write_pass_float_variance(
        buffer + kernel_data.film.pass_denoising_data + DENOISING_PASS_DEPTH, L->denoising_depth);
  }
#endif /* __DENOISING_FEATURES__ */

#ifdef _KERNEL_DEBUG_
  kernel_write_debug_passes(kg, buffer, L);
#endif

  /* Adaptive Sampling. Fill the additional buffer with the odd samples and calculate our stopping
     criteria. This is the heuristic from "A hierarchical automatic stopping condition for Monte
     Carlo global illumination" except that here it is applied per pixel and not in hierarchical
     tiles. 
  if (kernel_data.film.pass_adaptive_aux_buffer &&
      kernel_data.integrator.adaptive_threshold > 0.0f) {
    if (sample_is_even(kernel_data.integrator.sampling_pattern, sample)) {
      kernel_write_pass_float4(buffer + kernel_data.film.pass_adaptive_aux_buffer,
                               make_float4(L_sum.x * 2.0f, L_sum.y * 2.0f, L_sum.z * 2.0f, 0.0f));
    }
#ifdef __KERNEL_CPU__
    if ((sample > kernel_data.integrator.adaptive_min_samples) &&
        kernel_data.integrator.adaptive_stop_per_sample) {
      const int step = kernel_data.integrator.adaptive_step;

      if ((sample & (step - 1)) == (step - 1)) {
        kernel_do_adaptive_stopping(kg, buffer, sample);
      }
    }
#endif
  }
  */

  /* Write the sample count as negative numbers initially to mark the samples as in progress.
   * Once the tile has finished rendering, the sign gets flipped and all the pixel values
   * are scaled as if they were taken at a uniform sample count. 
  if (kernel_data.film.pass_sample_count) {
    /* Make sure it's a negative number. In progressive refine mode, this bit gets flipped between
     * passes. 
#ifdef __ATOMIC_PASS_WRITE__
    atomic_fetch_and_or_uint32((ccl_global uint *)(buffer + kernel_data.film.pass_sample_count),
                               0x80000000);
#else
    if (buffer[kernel_data.film.pass_sample_count] > 0) {
      buffer[kernel_data.film.pass_sample_count] *= -1.0f;
    }
#endif
    kernel_write_pass_float(buffer + kernel_data.film.pass_sample_count, -1.0f);
  }
  */
}

void main()
{


  /*
  float3 raster = make_float3_v3( vec3(gl_LaunchIDNV.xy,1.f) );

  ProjectionTransform rastertocamera = kernel_data.cam.rastertocamera;
	Transform cameratoworld            = kernel_data.cam.cameratoworld;

	float3 P        = make_float3(0.0f, 0.0f, 0.0f);
  float3 Pcamera  = transform_perspective(rastertocamera, raster);

  vec4 origin      =   transform_point(cameratoworld, P);
  vec4 direction   =   normalize(transform_direction(cameratoworld, Pcamera));
 Initialize random numbers and sample ray. */


  int sample_rsv = 0;
  uint rng_hash;
  Ray ray;
  float3 raster = make_float3_v3( vec3(gl_LaunchIDNV.xy,1.f) );

  kernel_path_trace_setup(sample_rsv,  rng_hash, ray);

  if (ray.t == 0.0f) {
    return;
  }

  uint  rayFlags = gl_RayFlagsOpaqueNV;
  float tMin     = 0.1;
  float tMax     = 100.0;

  prd.throughput = make_float3(1.0f, 1.0f, 1.0f);
  path_state_init(rng_hash,sample_rsv);
  path_radiance_init();

  traceNV(topLevelAS,     // acceleration structure
          rayFlags,       // rayFlags
          0xFF,           // cullMask
          1,              // sbtRecordOffset
          0,              // sbtRecordStride
          0,              // missIndex
         ray.P.xyz,     // ray origin
          tMin,           // ray min range
         ray.D.xyz,  // ray direction
          tMax,           // ray max range
          0               // payload (location = 0)
  );


 if(prd.L.use_light_pass == 1234){
       ivec2 dim = imageSize(image);
       imageStore(image, ivec2(gl_LaunchIDNV.x,dim.y - gl_LaunchIDNV.y), vec4(prd.throughput.xyz,1.f) );
 }else{
     
       //kernel_write_result();
       ivec2 dim = imageSize(image);
       imageStore(image, ivec2(gl_LaunchIDNV.x,dim.y - gl_LaunchIDNV.y), vec4(prd.throughput.xyz,1.f));
 }
  


}
