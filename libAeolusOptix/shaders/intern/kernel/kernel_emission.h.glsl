#ifndef _KERNEL_EMISSION_H_
#define _KERNEL_EMISSION_H_

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

CCL_NAMESPACE_BEGIN

#if defined(GSD) && defined(_KERNEL_LIGHT_H_)
#include "kernel/bvh/bvh_utils.h.glsl"
/* Direction Emission emission sd */
ccl_device_noinline_cpu float3 direct_emissive_eval(
                                                    inout LightSample ls,
                                                    float3 I,
                                                    differential3 dI,
                                                    float t,
                                                    float time)
{
  /* setup shading at emitter */

  float3 eval = make_float3(0.0f, 0.0f, 0.0f);
  if (shader_constant_emission_eval(ls.shader, eval)) {
    if ((ls.prim != PRIM_NONE) && dot3(ls.Ng, I) < 0.0f) {
      ls.Ng = -ls.Ng;
    }
#ifdef WITH_STAT_ALL  
        CNT_ADD(CNT_direct_emissive_eval_constant);
#endif
    }
  else
   {
    /* Setup shader data and call shader_eval_surface once, better
     * for GPU coherence and compile times. */
#ifdef _BACKGROUND_MIS_
    if (ls.type == LIGHT_BACKGROUND) {
      Ray ray;
      ray.D = ls.D;
      ray.P = ls.P;
      ray.t = 1.0f;
      ray.time = time;
      differential3_zero(ray.dP);
      ray.dD = dI;

      shader_setup_from_background(ray);
#ifdef WITH_STAT_ALL
        CNT_ADD(CNT_direct_emissive_eval_bg);
#endif

    }
    else
#endif
    {
      shader_setup_from_sample(
                               ls.P,
                               ls.Ng,
                               I,
                               ls.shader,
                               ls.object,
                               ls.prim,
                               ls.u,
                               ls.v,
                               t,
                               time,
                               false,
                               ls.lamp);

#ifdef WITH_STAT_ALL 
        CNT_ADD(CNT_direct_emissive_eval_sample);
#endif

      ls.Ng =  GSD.Ng;
    }

    /* No proper path flag, we're evaluating this for all closures. that's
     * weak but we'd have to do multiple evaluations otherwise. */
    path_state_modify_bounce(true);
    shader_eval_surface( PATH_RAY_EMISSION);
    path_state_modify_bounce(false);

    /* Evaluate closures. */
#ifdef _BACKGROUND_MIS_
    if (ls.type == LIGHT_BACKGROUND) {
      eval = shader_background_eval();
    }
    else
#endif
    {
      eval = shader_emissive_eval();
    }
  }

  eval *= ls.eval_fac;

  if (ls.lamp != LAMP_NONE) {
    const ccl_global KernelLight klight = kernel_tex_fetch(_lights, ls.lamp);
    eval *= make_float3(klight.strength[0], klight.strength[1], klight.strength[2]);
  }



  return eval;

}

#ifdef set_prg3_tiny_sd
bool direct_emission(               inout LightSample ls,
                                    inout bool is_lamp,
                                    float rand_terminate)
{
  if (ls.pdf == 0.0f)
    return false;

  /* todo: implement */
  differential3 dD;
  differential3_zero(dD);

  /* evaluate closure */
  float3 light_eval = direct_emissive_eval(ls,  -ls.D, dD, ls.t, GARG.sd.time);
 

#ifdef  WITH_STAT_ALL
    #ifdef direct_emission_light_eval
          STAT_DUMP_f3(direct_emission_light_eval, light_eval);
    #endif
#endif

  if (is_zero(light_eval))
    return false;
    /* evaluate BSDF at shading point */
#ifdef _VOLUME_
  if (sd->prim != PRIM_NONE)
    shader_bsdf_eval(kg, sd, ls->D, eval, ls->pdf, ls->shader & SHADER_USE_MIS);
  else {
    float bsdf_pdf;
    shader_volume_phase_eval(kg, sd, ls->D, eval, &bsdf_pdf);
    if (ls->shader & SHADER_USE_MIS) {
      /* Multiple importance sampling. */
      float mis_weight = power_heuristic(ls->pdf, bsdf_pdf);
      light_eval *= mis_weight;
    }
  }
#else  

        set_prg3_tiny_sd( ls.D, ls.pdf, uint(PROFI_IDX),GARG.use_light_pass, int(ls.shader & SHADER_USE_MIS));
        //GSD.lamp     = int(4294967295);
#ifdef  WITH_STAT_ALL
    #ifdef direct_emission_light_pdf
          STAT_DUMP_f1(direct_emission_light_pdf, ls.pdf);
    #endif
#endif
        EXECUTION_LIGHT_SAMPLE;
        GARG.sd.lcg_state  = floatBitsToUint(GSD.time);
#endif

  PLYMO_bsdf_eval_mul3(light_eval / ls.pdf);
#ifdef _PASSES_
  /* use visibility flag to skip lights */
  if (bool(ls.shader & SHADER_EXCLUDE_ANY)) {
    if(bool (ls.shader & SHADER_EXCLUDE_DIFFUSE))
      PLYMO_EVAL_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    if (bool(ls.shader & SHADER_EXCLUDE_GLOSSY))
      PLYMO_EVAL_glossy = make_float3(0.0f, 0.0f, 0.0f);
    if (bool(ls.shader & SHADER_EXCLUDE_TRANSMIT))
      PLYMO_EVAL_set_zero_transmission
      /*
    if(bool (ls.shader & SHADER_EXCLUDE_SCATTER))
      plymo.eval.volume = make_float3(0.0f, 0.0f, 0.0f);
      */
  }
#endif



  if (PLYMO_bsdf_eval_is_zero())
    return false;
  




  if (kernel_data.integrator.light_inv_rr_threshold > 0.0f
#ifdef _SHADOW_TRICKS_
      && (GARG.state.flag & PATH_RAY_SHADOW_CATCHER) == 0
#endif
  ) {
    float probability = max3(fabs(PLYMO_bsdf_eval_sum())) *
                        kernel_data.integrator.light_inv_rr_threshold;
    if (probability < 1.0f) {
      if (rand_terminate >= probability) {
        return false;
      }
      PLYMO_bsdf_eval_mul(1.0f / probability);
    }
  }


  if (bool(ls.shader & SHADER_CAST_SHADOW)){
    /* setup ray */
    bool transmit = (dot3(GARG.sd.Ng, ls.D) < 0.0f);
    GARG.ray.P = ray_offset(GARG.sd.P, (transmit) ? -GARG.sd.Ng : GARG.sd.Ng);
      



    if (ls.t == FLT_MAX) {
      /* distant light */
      GARG.ray.D = ls.D;
      GARG.ray.t = ls.t;
    }
    else {
      /* other lights, avoid self-intersection */
      GARG.ray.D = ray_offset(ls.P, ls.Ng) - GARG.ray.P;
      GARG.ray.D = normalize_len( GARG.ray.D, GARG.ray.t);
    }

    //pay.ray.dP = GSD.dP;
    differential3_zero(GARG.ray.dD);
  }
  else {
    /* signal to not cast shadow ray */
    GARG.ray.t = 0.0f;
  }

  /* return if it's a lamp for shadow pass */
  is_lamp = (ls.prim == PRIM_NONE && ls.type != LIGHT_BACKGROUND);


  set_ply_Eval




  return true;
}

#endif



#if defined(GSTATE) && defined(GTHR)
void indirect_lamp_emission()
{
  int state_flag = GSTATE.flag;
  for (int lamp = 0; lamp < kernel_data.integrator.num_all_lights; lamp++) {

    LightSample ls;

    if(!lamp_light_eval(ls,lamp,GARG.ray.P,GARG.ray.D,GARG.ray.t))continue; 



#ifdef _PASSES_
    /* use visibility flag to skip lights */
    if (bool(ls.shader & SHADER_EXCLUDE_ANY)) {
      if (( bool(ls.shader & SHADER_EXCLUDE_DIFFUSE) && bool( state_flag & PATH_RAY_DIFFUSE)) ||
          ( bool(ls.shader & SHADER_EXCLUDE_GLOSSY) &&
           (( state_flag & (PATH_RAY_GLOSSY | PATH_RAY_REFLECT)) ==
            (PATH_RAY_GLOSSY | PATH_RAY_REFLECT))) ||
          (bool(ls.shader & SHADER_EXCLUDE_TRANSMIT) && bool( state_flag& PATH_RAY_TRANSMIT)) ||
          (bool(ls.shader & SHADER_EXCLUDE_SCATTER) && bool( state_flag & PATH_RAY_VOLUME_SCATTER)))
        continue;
    }
#endif

    float3 lamp_L = direct_emissive_eval(ls,-GARG.ray.D, GARG.ray.dD, ls.t, GARG.ray.time);

#ifdef _VOLUME_
    if (state.volume_stack[0].shader != SHADER_NONE) {
      /* shadow attenuation */
      Ray volume_ray = *ray;
      volume_ray.t = ls.t;
      float3 volume_tp = make_float3(1.0f, 1.0f, 1.0f);
      kernel_volume_shadow(kg, emission_sd, state, &volume_ray, &volume_tp);
      lamp_L *= volume_tp;
    }
#endif

    if (!bool(state_flag & PATH_RAY_MIS_SKIP)) {
      /* multiple importance sampling, get regular light pdf,
       * and compute weight with respect to BSDF pdf */
      float mis_weight = power_heuristic(GSTATE.ray_pdf, ls.pdf);
      lamp_L *= mis_weight;
    }

    path_radiance_accum_emission( GSTATE.flag, GSTATE.bounce, GTHR, lamp_L);


  }
}

#endif

#endif




/* Indirect Primitive Emission */
#if defined(GSD) && !defined(RMISS_BG)

ccl_device_noinline_cpu float3 indirect_primitive_emission(float t, int path_flag, float bsdf_pdf)
{
  /* evaluate emissive closure */
  float3 L = shader_emissive_eval();

#ifdef _HAIR_
  if (!(bool(path_flag & PATH_RAY_MIS_SKIP)) && (GSD.flag & SD_USE_MIS) &&
      (GSD.type & PRIMITIVE_ALL_TRIANGLE))
#else
  if (!(bool(path_flag & PATH_RAY_MIS_SKIP)) && bool(GSD.flag & SD_USE_MIS))
#endif
  {
    /* multiple importance sampling, get triangle light pdf,
     * and compute weight with respect to BSDF pdf */
    float pdf = triangle_light_pdf(sd, t);
    float mis_weight = power_heuristic(bsdf_pdf, pdf);

    return L * mis_weight;
  }

  return L;
}


/* Indirect Lamp Emission */


#ifdef RMISS_BG
/* Indirect Background */
ccl_device_noinline_cpu float3 indirect_background(in Ray ray)
{
#ifdef _BACKGROUND_
  int shader = kernel_data.background.surface_shader;
  /* Use visibility flag to skip lights. */
  if (bool(shader & SHADER_EXCLUDE_ANY)) {
    if ((bool(shader & SHADER_EXCLUDE_DIFFUSE) && bool(GSTATE.flag & PATH_RAY_DIFFUSE)) ||
        (bool(shader & SHADER_EXCLUDE_GLOSSY) &&
         ((GSTATE.flag & (PATH_RAY_GLOSSY | PATH_RAY_REFLECT)) ==
          (PATH_RAY_GLOSSY | PATH_RAY_REFLECT))) ||
        (bool(shader & SHADER_EXCLUDE_TRANSMIT) && bool(GSTATE.flag & PATH_RAY_TRANSMIT)) ||
        (bool(shader & SHADER_EXCLUDE_CAMERA) && bool(GSTATE.flag & PATH_RAY_CAMERA)) ||
        (bool(shader & SHADER_EXCLUDE_SCATTER) && bool(GSTATE.flag & PATH_RAY_VOLUME_SCATTER)))
      return make_float3(0.0f, 0.0f, 0.0f);
  }

  /* Evaluate background shader. */
  float3 L = make_float3(0.0f, 0.0f, 0.0f);
  if (!shader_constant_emission_eval(shader, L)) {
#  ifdef _SPLIT_KERNEL_
    Ray priv_ray = *ray;
    shader_setup_from_background(kg, emission_sd, &priv_ray);
#  else
    shader_setup_from_background(ray);
#  endif

    path_state_modify_bounce(true);
    shader_eval_surface( GSTATE.flag | PATH_RAY_EMISSION );
    path_state_modify_bounce(false);

    L = shader_background_eval();


  }




  /* Background MIS weights. */
#  ifdef _BACKGROUND_MIS_
  /* Check if background light exists or if we should skip pdf. */
  if (!(bool(GSTATE.flag & PATH_RAY_MIS_SKIP)) && bool(kernel_data.background.use_mis) ) {

    /* multiple importance sampling, get background light pdf for ray
     * direction, and compute weight with respect to BSDF pdf */
    float pdf = background_light_pdf(ray.P, ray.D);
    float mis_weight = power_heuristic(GSTATE.ray_pdf, pdf);
    return L * mis_weight;

  }
#  endif

  return L;
#else
  return make_float3(0.8f, 0.8f, 0.8f);
#endif
}

#endif

CCL_NAMESPACE_END
#endif


#endif