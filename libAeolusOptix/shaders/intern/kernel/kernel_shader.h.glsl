/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * ShaderData, used in four steps:
 *
 * Setup from incoming ray, sampled position and background.
 * Execute for surface, volume or displacement.
 * Evaluate one or more closures.
 * Release.
 */

// clang-format off
#include "kernel/closure/alloc.h.glsl"
#include "kernel/closure/bsdf_util.h.glsl"
#include "kernel/closure/bsdf.h.glsl"
#include "kernel/closure/emissive.h.glsl"
// clang-format on

#include "kernel/svm/svm.h.glsl"

CCL_NAMESPACE_BEGIN

/* ShaderData setup from incoming ray */

#ifdef _OBJECT_MOTION_
ccl_device void shader_setup_object_transforms(inout KernelGlobals kg, inout ShaderData sd, float time)
{
  if (bool(sd.object_flag & SD_OBJECT_MOTION)) {
    sd.ob_tfm = object_fetch_transform_motion(kg, sd.object, time);

    sd.ob_itfm = transform_quick_inverse(sd.ob_tfm);
  }
  else {
    sd.ob_tfm = object_fetch_transform(kg, sd.object, OBJECT_TRANSFORM);
    sd.ob_itfm = object_fetch_transform(kg, sd.object, OBJECT_INVERSE_TRANSFORM);
  }
}
#endif

#ifdef _KERNEL_OPTIX_
ccl_device_inline
#else
ccl_device_noinline
#endif
void
    shader_setup_from_ray(inout KernelGlobals kg,
                          inout ShaderData sd,
                          in Intersection isect,
                          in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);

  sd.object = (isect.object == OBJECT_NONE) ? int(kernel_tex_fetch(_prim_object, isect.prim)) :isect.object;
  sd.lamp = LAMP_NONE;

  sd.type = isect.type;
  sd.flag = 0;
  sd.object_flag = int(kernel_tex_fetch(_object_flag, sd.object));


  /* matrices and time */
#ifdef _OBJECT_MOTION_
  shader_setup_object_transforms(kg, sd, ray.time);
#endif
  sd.time = ray.time;

  sd.prim = int(kernel_tex_fetch(_prim_index, isect.prim));

  sd.ray_length = isect.t;

  sd.u = isect.u;
  sd.v = isect.v;

#ifdef _HAIR_
  if (bool(sd.type & PRIMITIVE_ALL_CURVE)) {
    /* curve */
    curve_shader_setup(kg, sd, isect, ray);
  }

  else
#endif
      if (bool(sd.type & PRIMITIVE_TRIANGLE)) {
    /* static triangle */

    float3 Ng = triangle_normal(kg, sd);
    sd.shader = int(kernel_tex_fetch(_tri_shader, sd.prim));


    /* vectors */
    sd.P = triangle_refine(kg, sd, isect, ray);
    sd.Ng = Ng;
    sd.N = Ng;

    /* smooth normal */
    if (bool(sd.shader & SHADER_SMOOTH_NORMAL))

      sd.N = triangle_smooth_normal(kg, Ng, sd.prim, sd.u, sd.v);

#ifdef _DPDU_
    /* dPdu/dPdv */
    triangle_dPdudv(kg, sd.prim, (sd.dPdu), (sd.dPdv));


#endif
  }
  else {
    /* motion triangle */
    motion_triangle_shader_setup(kg, sd, isect, ray, false);
  }

  sd.I = -ray.D;

  sd.flag |= kernel_tex_fetch(_shaders, (sd.shader & SHADER_MASK)).flags;

  if (isect.object != OBJECT_NONE) {
    /* instance transform */
    object_normal_transform_auto(kg, sd, (sd.N));

    object_normal_transform_auto(kg, sd, (sd.Ng));

#ifdef _DPDU_
    object_dir_transform_auto(kg, sd, (sd.dPdu));

    object_dir_transform_auto(kg, sd, (sd.dPdv));

#endif
  }

  /* backfacing test */
  bool backfacing = (dot3(sd.Ng, sd.I) < 0.0f);

  if (bool(backfacing)) {

    sd.flag |= int(SD_BACKFACING);

    sd.Ng = -sd.Ng;
    sd.N = -sd.N;
#ifdef _DPDU_
    sd.dPdu = -sd.dPdu;
    sd.dPdv = -sd.dPdv;
#endif
  }

#ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  differential_transfer((sd.dP), ray.dP, ray.D, ray.dD, sd.Ng, isect.t);

  differential_incoming((sd.dI), ray.dD);

  differential_dudv((sd.du), (sd.dv), sd.dPdu, sd.dPdv, sd.dP, sd.Ng);


#endif

  PROFILING_SHADER(sd.shader);
  PROFILING_OBJECT(sd.object);
}

/* ShaderData setup from BSSRDF scatter */

#ifdef _SUBSURFACE_
#  ifndef _KERNEL_CUDA_
ccl_device
#  else
ccl_device_inline
#  endif
    void
    shader_setup_from_subsurface(inout KernelGlobals kg,
                                 inout ShaderData sd,
                                 in Intersection isect,
                                 in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);

  const bool backfacing = bool(sd.flag & SD_BACKFACING);


  /* object, matrices, time, ray_length stay the same */
  sd.flag = 0;
  sd.object_flag = int(kernel_tex_fetch(_object_flag, sd.object));

  sd.prim = int(kernel_tex_fetch(_prim_index, isect.prim));

  sd.type = isect.type;

  sd.u = isect.u;
  sd.v = isect.v;

  /* fetch triangle data */
  if (sd.type == PRIMITIVE_TRIANGLE) {
    float3 Ng = triangle_normal(kg, sd);
    sd.shader = int(kernel_tex_fetch(_tri_shader, sd.prim));


    /* static triangle */
    sd.P = triangle_refine_local(kg, sd, isect, ray);
    sd.Ng = Ng;
    sd.N = Ng;

    if (bool(sd.shader & SHADER_SMOOTH_NORMAL))

      sd.N = triangle_smooth_normal(kg, Ng, sd.prim, sd.u, sd.v);

#  ifdef _DPDU_
    /* dPdu/dPdv */
    triangle_dPdudv(kg, sd.prim, (sd.dPdu), (sd.dPdv));


#  endif
  }
  else {
    /* motion triangle */
    motion_triangle_shader_setup(kg, sd, isect, ray, true);
  }

  sd.flag |= kernel_tex_fetch(_shaders, (sd.shader & SHADER_MASK)).flags;

  if (isect.object != OBJECT_NONE) {
    /* instance transform */
    object_normal_transform_auto(kg, sd, (sd.N));

    object_normal_transform_auto(kg, sd, (sd.Ng));

#  ifdef _DPDU_
    object_dir_transform_auto(kg, sd, (sd.dPdu));

    object_dir_transform_auto(kg, sd, (sd.dPdv));

#  endif
  }

  /* backfacing test */
  if (bool(backfacing)) {

    sd.flag |= int(SD_BACKFACING);

    sd.Ng = -sd.Ng;
    sd.N = -sd.N;
#  ifdef _DPDU_
    sd.dPdu = -sd.dPdu;
    sd.dPdv = -sd.dPdv;
#  endif
  }

  /* should not get used in principle as the shading will only use a diffuse
   * BSDF, but the shader might still access it */
  sd.I = sd.N;

#  ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  differential_dudv((sd.du), (sd.dv), sd.dPdu, sd.dPdv, sd.dP, sd.Ng);


  /* don't modify dP and dI */
#  endif

  PROFILING_SHADER(sd.shader);
}
#endif

/* ShaderData setup from position sampled on mesh */
ccl_device_inline void shader_setup_from_sample(
                                                const float3 P,
                                                const float3 Ng,
                                                const float3 I,
                                                int shader,
                                                int object,
                                                int prim,
                                                float u,
                                                float v,
                                                float t,
                                                float time,
                                                bool object_space,
                                                int   lamp)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);
  /* vectors */
  GSD.P  = P;
  GSD.N  = Ng;
  GSD.Ng = Ng;
  GSD.I  = I;
  GSD.shader = shader;
  if (prim != PRIM_NONE)
    GSD.type = int(PRIMITIVE_TRIANGLE);

  else if (lamp != LAMP_NONE)
    GSD.type = int( PRIMITIVE_LAMP);
  else
    GSD.type = int( PRIMITIVE_NONE);


  /* primitive */
  GSD.object = object;
  GSD.lamp   = LAMP_NONE;
  /* currently no access to bvh prim index for strand GSD.prim*/
  GSD.prim = prim;
  GSD.u = u;
  GSD.v = v;
  GSD.time = time;
  GSD.ray_length = t;

  GSD.flag = kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).flags;
  GSD.object_flag = 0;
  if (GSD.object != OBJECT_NONE) {
    GSD.object_flag |= int(kernel_tex_fetch(_object_flag, GSD.object));


#ifdef _OBJECT_MOTION_
    shader_setup_object_transforms(kg, sd, time);
  }
  else if (lamp != LAMP_NONE) {
    GSD.ob_tfm = lamp_fetch_transform(kg, lamp, false);
    GSD.ob_itfm = lamp_fetch_transform(kg, lamp, true);
    GSD.lamp = lamp;
#else
  }
  else if (lamp != LAMP_NONE) {
    GSD.lamp = lamp;
#endif
  }

  /* transform into world space */
  if (object_space) {
    object_position_transform_auto(GSD.P);
    object_normal_transform_auto(GSD.Ng);
    GSD.N = GSD.Ng;
    object_dir_transform_auto(GSD.I);

  }

  if (bool(GSD.type & PRIMITIVE_TRIANGLE)) {
    /* smooth normal */
    if (bool(GSD.shader & SHADER_SMOOTH_NORMAL)) {


      GSD.N = triangle_smooth_normal(Ng, GSD.prim, GSD.u, GSD.v);

      if (!(bool(GSD.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {
        object_normal_transform_auto(GSD.N);
      }
    }

    /* dPdu/dPdv */
#ifdef _DPDU_
    triangle_dPdudv(GSD.prim, (GSD.dPdu), (GSD.dPdv));
    if (!(bool(GSD.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {
      object_dir_transform_auto(GSD.dPdu);
      object_dir_transform_auto(GSD.dPdv);
    }
#endif
  }
  else {
#ifdef _DPDU_
    GSD.dPdu = make_float3(0.0f, 0.0f, 0.0f);
    GSD.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#endif
  }

  /* backfacing test */
  if (GSD.prim != PRIM_NONE) {
    bool backfacing = (dot3(GSD.Ng, GSD.I) < 0.0f);

    if (bool(backfacing)) {

      GSD.flag |= int(SD_BACKFACING);

      GSD.Ng = -GSD.Ng;
      GSD.N = -GSD.N;
#ifdef _DPDU_
      GSD.dPdu = -GSD.dPdu;
      GSD.dPdv = -GSD.dPdv;
#endif
    }
  }

#ifdef _RAY_DIFFERENTIALS_
  /* no ray differentials here yet */
   differential3_zero(GSD.dP);
   differential3_zero(GSD.dI);
   differential_zero(GSD.du);
   differential_zero(GSD.dv);
#endif

  PROFILING_SHADER(GSD.shader);
  PROFILING_OBJECT(GSD.object);
}


/* ShaderData setup for displacement */

ccl_device void shader_setup_from_displace(
    inout KernelGlobals kg, inout ShaderData sd, int object, int prim, float u, float v)
{
  float3 P, Ng, I = make_float3(0.0f, 0.0f, 0.0f);
  int shader;

  triangle_point_normal(kg, object, prim, u, v, (P), (Ng), shader);




  /* force smooth shading for displacement */
  shader |= int(SHADER_SMOOTH_NORMAL);


  shader_setup_from_sample(
      kg,
      sd,
      P,
      Ng,
      I,
      shader,
      object,
      prim,
      u,
      v,
      0.0f,
      0.5f,
      !bool(kernel_tex_fetch(_object_flag, object) & SD_OBJECT_TRANSFORM_APPLIED),

      LAMP_NONE);
}

/* ShaderData setup from ray into background */

ccl_device_inline void shader_setup_from_background(inout KernelGlobals kg,
                                                    inout ShaderData sd,
                                                    in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);

  /* vectors */
  sd.P = ray.D;
  sd.N = -ray.D;
  sd.Ng = -ray.D;
  sd.I = -ray.D;
  sd.shader = kernel_data.background.surface_shader;
  sd.flag = kernel_tex_fetch(_shaders, (sd.shader & SHADER_MASK)).flags;
  sd.object_flag = 0;
  sd.time = ray.time;
  sd.ray_length = 0.0f;

  sd.object = OBJECT_NONE;
  sd.lamp = LAMP_NONE;
  sd.prim = PRIM_NONE;
  sd.u = 0.0f;
  sd.v = 0.0f;

#ifdef _DPDU_
  /* dPdu/dPdv */
  sd.dPdu = make_float3(0.0f, 0.0f, 0.0f);
  sd.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#endif

#ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  sd.dP = ray.dD;
  differential_incoming((sd.dI), sd.dP);

  sd.du = differential_zero();
  sd.dv = differential_zero();
#endif

  /* for NDC coordinates */
  sd.ray_P = ray.P;

  PROFILING_SHADER(sd.shader);
  PROFILING_OBJECT(sd.object);
}

/* ShaderData setup from point inside volume */

#ifdef _VOLUME_
ccl_device_inline void shader_setup_from_volume(inout KernelGlobals kg, inout ShaderData sd, in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);

  /* vectors */
  sd.P = ray.P;
  sd.N = -ray.D;
  sd.Ng = -ray.D;
  sd.I = -ray.D;
  sd.shader = SHADER_NONE;
  sd.flag = 0;
  sd.object_flag = 0;
  sd.time = ray.time;
  sd.ray_length = 0.0f; /* todo: can we set this to some useful value? */

  sd.object = OBJECT_NONE; /* todo: fill this for texture coordinates */
  sd.lamp = LAMP_NONE;
  sd.prim = PRIM_NONE;
  sd.type = int(PRIMITIVE_NONE);


  sd.u = 0.0f;
  sd.v = 0.0f;

#  ifdef _DPDU_
  /* dPdu/dPdv */
  sd.dPdu = make_float3(0.0f, 0.0f, 0.0f);
  sd.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#  endif

#  ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  sd.dP = ray.dD;
  differential_incoming((sd.dI), sd.dP);

  sd.du = differential_zero();
  sd.dv = differential_zero();
#  endif

  /* for NDC coordinates */
  sd.ray_P = ray.P;
  sd.ray_dP = ray.dP;

  PROFILING_SHADER(sd.shader);
  PROFILING_OBJECT(sd.object);
}
#endif /* _VOLUME_ */

/* Merging */

#if defined(_BRANCHED_PATH_) || defined(_VOLUME_)
ccl_device_inline void shader_merge_closures(inout ShaderData sd)
{
  /* merge identical closures, better when we sample a single closure at a time */
  for (int i = 0; i < sd.num_closure; i++) {
    for (int j = i + 1; j < sd.num_closure; j++) {
      if (sd.closure[i].type != sd.closure[j].type)
        continue;
      if (!bsdf_merge(sd.closure[i], sd.closure[j]))
        continue;

      sd.closure[i].weight += sd.closure[j].weight;
      sd.closure[i].sample_weight += sd.closure[j].sample_weight;

      int size = sd.num_closure - (j + 1);
      if (size > 0) {
        for (int k = 0; k < size; k++) {
          sd.closure[j + k ] = sd.closure[j + k + 1];
        }
      }

      sd.num_closure--;
      kernel_assert(sd.num_closure >= 0);
      j--;
    }
  }
}
#endif /* _BRANCHED_PATH_ || _VOLUME_ */

/* Defensive sampling. */

ccl_device_inline void shader_prepare_closures(inout ShaderData sd, ccl_addr_space inout PathState state)
{
  /* We can likely also do defensive sampling at deeper bounces, particularly
   * for cases like a perfect mirror but possibly also others. This will need
   * a good heuristic. */
  if (state.bounce + state.transparent_bounce == 0 && sd.num_closure > 1) {
    float sum = 0.0f;

    for (int i = 0; i < sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(sd.closure[i].type)) {
        sum += sd.closure[i].sample_weight;
      }
    }

    for (int i = 0; i < sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(sd.closure[i].type)) {
        sd.closure[i].sample_weight = max(sd.closure[i].sample_weight, 0.125f * sum);
      }
    }
  }
}

/* BSDF */

ccl_device_inline void _shader_bsdf_multi_eval(inout KernelGlobals kg,
                                               inout ShaderData sd,
                                               const float3 omega_in,
                                               inout float pdf,
                                               in ShaderClosure skip_sc,
                                               inout BsdfEval result_eval,
                                               float sum_pdf,
                                               float sum_sample_weight)
{
  /* this is the veach one-sample model with balance heuristic, some pdf
   * factors drop out when using balance heuristic weighting */
  for (int i = 0; i < sd.num_closure; i++) {
    if (!eq_ShaderClosure(sd.closure[i],skip_sc) && CLOSURE_IS_BSDF(sd.closure[i].type)) {
      float bsdf_pdf = 0.0f;
      float3 eval = bsdf_eval(kg, sd, sd.closure[i], omega_in, (bsdf_pdf));
      if (bsdf_pdf != 0.0f) {
        bsdf_eval_accum(result_eval, sd.closure[i].type, eval * sd.closure[i].weight, 1.0f);
        sum_pdf += bsdf_pdf * sd.closure[i].sample_weight;
      }
      sum_sample_weight += sd.closure[i].sample_weight;
    }
  }
  pdf = (sum_sample_weight > 0.0f) ? sum_pdf / sum_sample_weight : 0.0f;
}

#ifdef _BRANCHED_PATH_
ccl_device_inline void _shader_bsdf_multi_eval_branched(inout KernelGlobals kg,
                                                        inout ShaderData sd,
                                                        const float3 omega_in,
                                                        inout BsdfEval result_eval,
                                                        float light_pdf,
                                                        bool use_mis)
{
  for (int i = 0; i < sd.num_closure; i++) {
    if (CLOSURE_IS_BSDF(sd.closure[i].type)) {
      float bsdf_pdf = 0.0f;
      float3 eval = bsdf_eval(kg, sd, sd.closure[i], omega_in, (bsdf_pdf));
      if (bsdf_pdf != 0.0f) {
        float mis_weight = use_mis ? power_heuristic(light_pdf, bsdf_pdf) : 1.0f;
        bsdf_eval_accum(result_eval, sd.closure[i].type, eval * sd.closure[i].weight, mis_weight);
      }
    }
  }
}
#endif /* _BRANCHED_PATH_ */

#ifndef _KERNEL_CUDA_
ccl_device
#else
ccl_device_inline
#endif
    void
    shader_bsdf_eval(inout KernelGlobals kg,
                     inout ShaderData sd,
                     const float3 omega_in,
                     inout BsdfEval eval,
                     float light_pdf,
                     bool use_mis)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_EVAL);

  bsdf_eval_init(
      eval, NBUILTIN_CLOSURES, make_float3(0.0f, 0.0f, 0.0f), kernel_data.film.use_light_pass);

#ifdef _BRANCHED_PATH_
  if(bool(kernel_data.integrator.branched))

    _shader_bsdf_multi_eval_branched(kg, sd, omega_in, eval, light_pdf, use_mis);
  else
#endif
  {
    float pdf;
     _shader_bsdf_multi_eval(kg, sd, omega_in, (pdf), null_sc, eval, 0.0f, 0.0f);


    if (use_mis) {
      float weight = power_heuristic(light_pdf, pdf);
      bsdf_eval_mis(eval, weight);
    }
  }
}

ccl_device_inline int shader_bsdf_pick(inout ShaderData sd, inout float randu)
{
  /* Note the sampling here must match shader_bssrdf_pick,
   * since we reuse the same random number. */
  int sampled = 0;

  if (sd.num_closure > 1) {
    /* Pick a BSDF or based on sample weights. */
    float sum = 0.0f;

    for (int i = 0; i < sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(sd.closure[i].type)) {
        sum += sd.closure[i].sample_weight;
      }
    }

    float r = (randu) * sum;
    float partial_sum = 0.0f;

    for (int i = 0; i < sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(sd.closure[i].type)) {
        float next_sum = partial_sum + sd.closure[i].sample_weight;

        if (r < next_sum) {
          sampled = i;

          /* Rescale to reuse for direction sample, to better preserve stratification. */
          randu = (r - partial_sum) / sd.closure[i].sample_weight;
          break;
        }

        partial_sum = next_sum;
      }
    }
  }

     return  CLOSURE_IS_BSDF(sd.closure[sampled].type)  ? sampled :-1;
}

ccl_device_inline int shader_bssrdf_pick(inout ShaderData sd,
                                                          ccl_addr_space inout float3 throughput,
                                                          inout float randu)
{
  /* Note the sampling here must match shader_bsdf_pick,
   * since we reuse the same random number. */
  int sampled = 0;

  if (sd.num_closure > 1) {
    /* Pick a BSDF or BSSRDF or based on sample weights. */
    float sum_bsdf = 0.0f;
    float sum_bssrdf = 0.0f;

    for (int i = 0; i < sd.num_closure; i++) {
     
      if (CLOSURE_IS_BSDF(sd.closure[i].type)) {
        sum_bsdf += sd.closure[i].sample_weight;
      }
      else if (CLOSURE_IS_BSSRDF(sd.closure[i].type)) {
        sum_bssrdf += sd.closure[i].sample_weight;
      }
    }

    float r = (randu) * (sum_bsdf + sum_bssrdf);
    float partial_sum = 0.0f;

    for (int i = 0; i < sd.num_closure; i++) {
    

      if (CLOSURE_IS_BSDF_OR_BSSRDF(sd.closure[i].type)) {
        float next_sum = partial_sum + sd.closure[i].sample_weight;

        if (r < next_sum) {
          if (CLOSURE_IS_BSDF(sd.closure[i].type)) {
            throughput *= (sum_bsdf + sum_bssrdf) / sum_bsdf;
            return NULL;
          }
          else {
            throughput *= (sum_bsdf + sum_bssrdf) / sum_bssrdf;
            sampled = i;

            /* Rescale to reuse for direction sample, to better preserve stratification. */
            randu = (r - partial_sum) / sd.closure[i].sample_weight;
            break;
          }
        }

        partial_sum = next_sum;
      }
    }
  }
  return CLOSURE_IS_BSSRDF(sd.closure[sampled].type) ? sampled : -1;
}

ccl_device_inline int shader_bsdf_sample(inout KernelGlobals kg,
                                         inout ShaderData sd,
                                         float randu,
                                         float randv,
                                         inout BsdfEval bsdf_eval,
                                         inout float3 omega_in,
                                         inout differential3 domega_in,
                                         inout float pdf)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_SAMPLE);

  int sampled = shader_bsdf_pick(sd, (randu));

  if (sampled == -1) {
    pdf = 0.0f;
    return int(LABEL_NONE);
  }
  
  /* BSSRDF should already have been handled elsewhere. */
  kernel_assert(CLOSURE_IS_BSDF(sd.closure[sampled].type));

  int label;
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  pdf = 0.0f;
  label = bsdf_sample(kg, sd, sd.closure[sampled], randu, randv, (eval), omega_in, domega_in, pdf);


  if (pdf != 0.0f) {
    bsdf_eval_init(bsdf_eval, sd.closure[sampled].type, eval * sd.closure[sampled].weight, kernel_data.film.use_light_pass);

    if (sd.num_closure > 1) {
      float sweight = sd.closure[sampled].sample_weight;
      _shader_bsdf_multi_eval(kg, sd, omega_in, pdf, sd.closure[sampled], bsdf_eval, pdf * sweight, sweight);
    }
  }

  return label;
}

ccl_device int shader_bsdf_sample_closure(inout KernelGlobals kg,
                                          inout ShaderData sd,
                                          in ShaderClosure sc,
                                          float randu,
                                          float randv,
                                          inout BsdfEval bsdf_eval,
                                          inout float3 omega_in,
                                          inout differential3 domega_in,
                                          inout float pdf)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_SAMPLE);

  int label;
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  pdf = 0.0f;
  label = bsdf_sample(kg, sd, sc, randu, randv, (eval), omega_in, domega_in, pdf);


  if (pdf != 0.0f)
    bsdf_eval_init(bsdf_eval, sc.type, eval * sc.weight, kernel_data.film.use_light_pass);

  return label;
}

ccl_device float shader_bsdf_average_roughness(inout ShaderData sd)
{
  float roughness = 0.0f;
  float sum_weight = 0.0f;

  for (int i = 0; i < sd.num_closure; i++) {
    if (CLOSURE_IS_BSDF(sd.closure[i].type)) {
      /* sqrt once to undo the squaring from multiplying roughness on the
       * two axes, and once for the squared roughness convention. */
      float weight = fabsf(average(sd.closure[i].weight));
      roughness += weight * sqrtf(safe_sqrtf(bsdf_get_roughness_squared(sd.closure[i])));
      sum_weight += weight;
    }
  }
  return (sum_weight > 0.0f) ? roughness / sum_weight : 0.0f;
}

ccl_device void shader_bsdf_blur(inout KernelGlobals kg, inout ShaderData sd, float roughness)
{
  for (int i = 0; i < sd.num_closure; i++) {
    if (CLOSURE_IS_BSDF(sd.closure[i].type))
      bsdf_blur(kg, sd.closure[i], roughness);
  }
}

ccl_device float3 shader_bsdf_transparency(inout KernelGlobals kg, in ShaderData sd)
{
  if (bool(sd.flag & SD_HAS_ONLY_VOLUME)) {
    return make_float3(1.0f, 1.0f, 1.0f);
  }

  else if (bool(sd.flag & SD_TRANSPARENT)) {
    return sd.closure_transparent_extinction;
  }

  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

ccl_device void shader_bsdf_disable_transparency(inout KernelGlobals kg, inout ShaderData sd)
{
  if (bool(sd.flag & SD_TRANSPARENT)) {

    for (int i = 0; i < sd.num_closure; i++) {

      if (sd.closure[i].type == CLOSURE_BSDF_TRANSPARENT_ID) {
        sd.closure[i].sample_weight = 0.0f;
        sd.closure[i].weight = make_float3(0.0f, 0.0f, 0.0f);
      }
    }

    sd.flag &= int(~SD_TRANSPARENT);
  }
}

ccl_device float3 shader_bsdf_alpha(inout KernelGlobals kg, inout ShaderData sd)
{
  float3 alpha = make_float3(1.0f, 1.0f, 1.0f) - shader_bsdf_transparency(kg, sd);

  alpha = max(alpha, make_float3(0.0f, 0.0f, 0.0f));
  alpha = min(alpha, make_float3(1.0f, 1.0f, 1.0f));

  return alpha;
}

ccl_device float3 shader_bsdf_diffuse(inout KernelGlobals kg, inout ShaderData sd)
{
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  for (int i = 0; i < sd.num_closure; i++) {

    if (CLOSURE_IS_BSDF_DIFFUSE(sd.closure[i].type) || CLOSURE_IS_BSSRDF(sd.closure[i].type) ||
        CLOSURE_IS_BSDF_BSSRDF(sd.closure[i].type))
      eval += sd.closure[i].weight;
  }

  return eval;
}

ccl_device float3 shader_bsdf_glossy(inout KernelGlobals kg, inout ShaderData sd)
{
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  for (int i = 0; i < sd.num_closure; i++) {

    if (CLOSURE_IS_BSDF_GLOSSY(sd.closure[i].type))
      eval += sd.closure[i].weight;
  }

  return eval;
}

ccl_device float3 shader_bsdf_transmission(inout KernelGlobals kg, inout ShaderData sd)
{
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  for (int i = 0; i < sd.num_closure; i++) {

    if (CLOSURE_IS_BSDF_TRANSMISSION(sd.closure[i].type))
      eval += sd.closure[i].weight;
  }

  return eval;
}

ccl_device float3 shader_bsdf_average_normal(inout KernelGlobals kg, inout ShaderData sd)
{
  float3 N = make_float3(0.0f, 0.0f, 0.0f);

  for (int i = 0; i < sd.num_closure; i++) {
    if (CLOSURE_IS_BSDF_OR_BSSRDF(sd.closure[i].type))
      N += sd.closure[i].N * fabsf(average(sd.closure[i].weight));
  }

  return (is_zero(N)) ? sd.N : normalize(N);
}

ccl_device float3 shader_bsdf_ao(inout KernelGlobals kg, inout ShaderData sd, float ao_factor, inout float3 N_)
{
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);
  float3 N = make_float3(0.0f, 0.0f, 0.0f);

  for (int i = 0; i < sd.num_closure; i++) {

    if (CLOSURE_IS_BSDF_DIFFUSE(sd.closure[i].type)) {
      eval += sd.closure[i].weight * ao_factor;
      N += sd.closure[i].N * fabsf(average(sd.closure[i].weight));
    }
  }

  N_ = (is_zero(N)) ? sd.N : normalize(N);
  return eval;
}

#ifdef _SUBSURFACE_
ccl_device float3 shader_bssrdf_sum(inout ShaderData sd, inout float3 N_, inout float texture_blur_)
{
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);
  float3 N = make_float3(0.0f, 0.0f, 0.0f);
  float texture_blur = 0.0f, weight_sum = 0.0f;

  for (int i = 0; i < sd.num_closure; i++) {

    if (CLOSURE_IS_BSSRDF(sd.closure[i].type)) {
      //const Bssrdf *bssrdf = (const Bssrdf *)sc;
      float avg_weight = fabsf(average(sd.closure[i].weight));

      N += sd.closure[i].N * avg_weight;
      eval += sd.closure[i].weight;
      texture_blur += Bssrdf_texture_blur(sd.closure[i]) * avg_weight;
      weight_sum += avg_weight;
    }
  }

  if (bool(N_))
    N_ = (is_zero(N)) ? sd.N : normalize(N);

  if (bool(texture_blur_))
    texture_blur_ = safe_divide(texture_blur, weight_sum);

  return eval;
}
#endif /* _SUBSURFACE_ */

/* Constant emission optimization */

ccl_device bool shader_constant_emission_eval(inout KernelGlobals kg, int shader, inout float3 eval)
{
  int shader_index = int(shader & SHADER_MASK);

  int shader_flag = kernel_tex_fetch(_shaders, shader_index).flags;

  if (bool(shader_flag & SD_HAS_CONSTANT_EMISSION)) {

    eval = make_float3(kernel_tex_fetch(_shaders, shader_index).constant_emission[0],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[1],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[2]);

    return true;
  }

  return false;
}

/* Background */

ccl_device float3 shader_background_eval(inout ShaderData sd)
{
  if (bool(sd.flag & SD_EMISSION)) {

    return sd.closure_emission_background;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

/* Emission */

ccl_device float3 shader_emissive_eval(inout ShaderData sd)
{
  if (bool(sd.flag & SD_EMISSION)) {

    return emissive_simple_eval(sd.Ng, sd.I) * sd.closure_emission_background;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

/* Holdout */

ccl_device float3 shader_holdout_apply(inout KernelGlobals kg, inout ShaderData sd)
{
  float3 weight = make_float3(0.0f, 0.0f, 0.0f);

  /* For objects marked as holdout, preserve transparency and remove all other
   * closures, replacing them with a holdout weight. */
  if (bool(sd.object_flag & SD_OBJECT_HOLDOUT_MASK)) {

    if (bool(sd.flag & SD_TRANSPARENT) && !bool(sd.flag & SD_HAS_ONLY_VOLUME)) {
      weight = make_float3(1.0f, 1.0f, 1.0f) - sd.closure_transparent_extinction;

      for (int i = 0; i < sd.num_closure; i++) {
        if (!CLOSURE_IS_BSDF_TRANSPARENT(sd.closure[i].type)) {
          sd.closure[i].type = NBUILTIN_CLOSURES;
        }
      }

      sd.flag &= int(~(SD_CLOSURE_FLAGS - (SD_TRANSPARENT | SD_BSDF)));
    }
    else {
      weight = make_float3(1.0f, 1.0f, 1.0f);
    }
  }
  else {
    for (int i = 0; i < sd.num_closure; i++) {
      if (CLOSURE_IS_HOLDOUT(sd.closure[i].type)) {
        weight += sd.closure[i].weight;
      }
    }
  }

  return weight;
}

/* Surface Evaluation */

ccl_device void shader_eval_surface(inout KernelGlobals kg,
                                    inout ShaderData sd,
                                    ccl_addr_space inout PathState state,
                                    inout int buffer_ofs,
                                    int path_flag)
{
  PROFILING_INIT(kg, PROFILING_SHADER_EVAL);

  /* If path is being terminated, we are tracing a shadow ray or evaluating
   * emission, then we don't need to store closures. The emission and shadow
   * shader data also do not have a closure array to save GPU memory. */
  int max_closures;
  if (bool(path_flag & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION))) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }

  sd.num_closure = 0;
  sd.num_closure_left = max_closures;

#ifdef _OSL_
  if (kg.osl) {
    if (sd.object == OBJECT_NONE && sd.lamp == LAMP_NONE) {
      OSLShader::eval_background(kg, sd, state, path_flag);
    }
    else {
      OSLShader::eval_surface(kg, sd, state, path_flag);
    }
  }
  else
#endif
  {
#ifdef _SVM_
    svm_eval_nodes(kg, sd, state, buffer_ofs, SHADER_TYPE_SURFACE, path_flag);
#else
    if (sd.object == OBJECT_NONE) {
      sd.closure_emission_background = make_float3(0.8f, 0.8f, 0.8f);
      sd.flag |= SD_EMISSION;
    }
    else {
      //DiffuseBsdf *bsdf = (DiffuseBsdf *)bsdf_alloc(sd, sizeof(DiffuseBsdf), make_float3(0.8f, 0.8f, 0.8f));
      int n = bsdf_alloc( sd, sizeof_DiffuseBsdf , make_float3(0.8f, 0.8f, 0.8f));
      if (n >= 0) {
        sd.closure[n].N = sd.N;
        sd.flag |= bsdf_diffuse_setup(sd.closure[n]);
      }
    }
#endif
  }

  if (bool(sd.flag & SD_BSDF_NEEDS_LCG)) {

    sd.lcg_state = lcg_state_init_addrspace(state, 0xb4bc3953);
  }
}

/* Volume */

#ifdef _VOLUME_

ccl_device_inline void _shader_volume_phase_multi_eval(in ShaderData sd,
                                                       const float3 omega_in,
                                                       inout float pdf,
                                                       int skip_phase,
                                                       inout BsdfEval result_eval,
                                                       float sum_pdf,
                                                       float sum_sample_weight)
{
  for (int i = 0; i < sd.num_closure; i++) {
    if (i == skip_phase)
      continue;

    if (CLOSURE_IS_PHASE(sd.closure[i].type)) {
      float phase_pdf = 0.0f;
      float3 eval = volume_phase_eval(sd, sd.closure[i], omega_in, (phase_pdf));


      if (phase_pdf != 0.0f) {
        bsdf_eval_accum(result_eval, sd.closure[i].type, eval, 1.0f);
        sum_pdf += phase_pdf * sd.closure[i].sample_weight;
      }

      sum_sample_weight += sd.closure[i].sample_weight;
    }
  }

  pdf = (sum_sample_weight > 0.0f) ? sum_pdf / sum_sample_weight : 0.0f;
}

ccl_device void shader_volume_phase_eval(
    inout KernelGlobals kg, in ShaderData sd, const float3 omega_in, inout BsdfEval eval, inout float pdf)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_VOLUME_EVAL);

  bsdf_eval_init(
      eval, NBUILTIN_CLOSURES, make_float3(0.0f, 0.0f, 0.0f), kernel_data.film.use_light_pass);

  _shader_volume_phase_multi_eval(sd, omega_in, pdf, -1, eval, 0.0f, 0.0f);
}

ccl_device int shader_volume_phase_sample(inout KernelGlobals kg,
                                          in ShaderData sd,
                                          float randu,
                                          float randv,
                                          inout BsdfEval phase_eval,
                                          inout float3 omega_in,
                                          inout differential3 domega_in,
                                          inout float pdf)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_VOLUME_SAMPLE);

  int sampled = 0;

  if (sd.num_closure > 1) {
    /* pick a phase closure based on sample weights */
    float sum = 0.0f;

    for (sampled = 0; sampled < sd.num_closure; sampled++) {

      if (CLOSURE_IS_PHASE(sd.closure[sampled].type))
        sum += sd.closure[sampled].sample_weight;
    }

    float r = randu * sum;
    float partial_sum = 0.0f;

    for (sampled = 0; sampled < sd.num_closure; sampled++) {
      if (CLOSURE_IS_PHASE(sd.closure[sampled].type)) {
        float next_sum = partial_sum + sd.closure[sampled].sample_weight;

        if (r <= next_sum) {
          /* Rescale to reuse for BSDF direction sample. */
          randu = (r - partial_sum) / sd.closure[sampled].sample_weight;
          break;
        }

        partial_sum = next_sum;
      }
    }

    if (sampled == sd.num_closure) {
      pdf = 0.0f;
      return LABEL_NONE;
    }
  }

  /* todo: this isn't quite correct, we don't weight anisotropy properly
   * depending on color channels, even if this is perhaps not a common case */

  int label;
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  pdf = 0.0f;
  label = volume_phase_sample(sd, sd.closure[sampled], randu, randv, (eval), omega_in, domega_in, pdf);


  if (pdf != 0.0f) {
    bsdf_eval_init(phase_eval, sd.closure[sampled].type, eval, kernel_data.film.use_light_pass);
  }

  return label;
}

ccl_device int shader_phase_sample_closure(inout KernelGlobals kg,
                                           in ShaderData sd,
                                           in ShaderClosure sc,
                                           float randu,
                                           float randv,
                                           inout BsdfEval phase_eval,
                                           inout float3 omega_in,
                                           inout differential3 domega_in,
                                           inout float pdf)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_VOLUME_SAMPLE);

  int label;
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  pdf = 0.0f;
  label = volume_phase_sample(sd, sc, randu, randv, (eval), omega_in, domega_in, pdf);


  if (pdf != 0.0f)
    bsdf_eval_init(phase_eval, sc.type, eval, kernel_data.film.use_light_pass);

  return label;
}

/* Volume Evaluation */

ccl_device_inline void shader_eval_volume(inout KernelGlobals kg,
                                          inout ShaderData sd,
                                          ccl_addr_space inout PathState state,
                                          ccl_addr_space inout VolumeStack stack,
                                          int path_flag)
{
  /* If path is being terminated, we are tracing a shadow ray or evaluating
   * emission, then we don't need to store closures. The emission and shadow
   * shader data also do not have a closure array to save GPU memory. */
  int max_closures;
  if (path_flag & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION)) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }

  /* reset closures once at the start, we will be accumulating the closures
   * for all volumes in the stack into a single array of closures */
  sd.num_closure = 0;
  sd.num_closure_left = max_closures;
  sd.flag = 0;
  sd.object_flag = 0;

  for (int i = 0; stack[i].shader != SHADER_NONE; i++) {
    /* setup shaderdata from stack. it's mostly setup already in
     * shader_setup_from_volume, this switching should be quick */
    sd.object = stack[i].object;
    sd.lamp = LAMP_NONE;
    sd.shader = stack[i].shader;

    sd.flag &= ~SD_SHADER_FLAGS;
    sd.flag |= kernel_tex_fetch(_shaders, (sd.shader & SHADER_MASK)).flags;
    sd.object_flag &= ~SD_OBJECT_FLAGS;

    if (sd.object != OBJECT_NONE) {
      sd.object_flag |= int(kernel_tex_fetch(_object_flag, sd.object));


#  ifdef _OBJECT_MOTION_
      /* todo: this is inefficient for motion blur, we should be
       * caching matrices instead of recomputing them each step */
      shader_setup_object_transforms(kg, sd, sd.time);
#  endif
    }

    /* evaluate shader */
#  ifdef _SVM_
#    ifdef _OSL_
    if (kg.osl) {
      OSLShader::eval_volume(kg, sd, state, path_flag);
    }
    else
#    endif
    {
      svm_eval_nodes(kg, sd, state, NULL, SHADER_TYPE_VOLUME, path_flag);
    }
#  endif

    /* merge closures to avoid exceeding number of closures limit */
    if (i > 0)
      shader_merge_closures(sd);
  }
}

#endif /* _VOLUME_ */

/* Displacement Evaluation */

ccl_device void shader_eval_displacement(inout KernelGlobals kg,
                                         inout ShaderData sd,
                                         ccl_addr_space inout PathState state)
{
  sd.num_closure = 0;
  sd.num_closure_left = 0;

  /* this will modify sd.P */
#ifdef _SVM_
#  ifdef _OSL_
  if (kg.osl)
    OSLShader::eval_displacement(kg, sd, state);
  else
#  endif
  {
    svm_eval_nodes(kg, sd, state, NULL, SHADER_TYPE_DISPLACEMENT, 0);
  }
#endif
}

/* Transparent Shadows */

#ifdef _TRANSPARENT_SHADOWS_
ccl_device bool shader_transparent_shadow(inout KernelGlobals kg, inout Intersection isect)
{
  int prim = int(kernel_tex_fetch(_prim_index, isect.prim));
  int shader = 0;

#  ifdef _HAIR_
  if (bool(isect.type & PRIMITIVE_ALL_TRIANGLE)) {

#  endif
    shader = int(kernel_tex_fetch(_tri_shader, prim));
#  ifdef _HAIR_
  }
  else {
    float4 str = kernel_tex_fetch(_curves, prim);
    shader = _float_as_int(str.z);
  }
#  endif
  int flag = kernel_tex_fetch(_shaders, (shader & SHADER_MASK)).flags;

  return (flag & SD_HAS_TRANSPARENT_SHADOW) != 0;
}
#endif /* _TRANSPARENT_SHADOWS_ */


ccl_device float shader_cryptomatte_id(inout KernelGlobals kg, int shader)
{
  return kernel_tex_fetch(_shaders, (shader & SHADER_MASK)).cryptomatte_id;
}

CCL_NAMESPACE_END
