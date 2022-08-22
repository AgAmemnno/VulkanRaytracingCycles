#ifndef _KERNEL_INDIRECT_BACKGROUND_H_
#define _KERNEL_INDIRECT_BACKGROUND_H_

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


#if defined(GARG)

ccl_device_noinline_cpu float3 indirect_background(in Ray ray)
{
#ifdef _BACKGROUND_
  int shader = kernel_data.background.surface_shader;

  /* Use visibility flag to skip lights. */
  if (bool(shader & SHADER_EXCLUDE_ANY)) {
    if ((bool(shader & SHADER_EXCLUDE_DIFFUSE) && bool(GARG.state.flag & PATH_RAY_DIFFUSE)) ||
        (bool(shader & SHADER_EXCLUDE_GLOSSY) &&
         ((GARG.state.flag & (PATH_RAY_GLOSSY | PATH_RAY_REFLECT)) ==
          (PATH_RAY_GLOSSY | PATH_RAY_REFLECT))) ||
        (bool(shader & SHADER_EXCLUDE_TRANSMIT) && bool(GARG.state.flag & PATH_RAY_TRANSMIT)) ||
        (bool(shader & SHADER_EXCLUDE_CAMERA) && bool(GARG.state.flag & PATH_RAY_CAMERA)) ||
        (bool(shader & SHADER_EXCLUDE_SCATTER) && bool(GARG.state.flag & PATH_RAY_VOLUME_SCATTER)))
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
    shader_eval_surface( GARG.state.flag | PATH_RAY_EMISSION );
    path_state_modify_bounce(false);

    L = shader_background_eval();


  }




  /* Background MIS weights. */
#  ifdef _BACKGROUND_MIS_
  /* Check if background light exists or if we should skip pdf. */
  if (!(bool(GARG.state.flag & PATH_RAY_MIS_SKIP)) && bool(kernel_data.background.use_mis) ) {

    /* multiple importance sampling, get background light pdf for ray
     * direction, and compute weight with respect to BSDF pdf */
    float pdf = background_light_pdf(ray.P, ray.D);
    float mis_weight = power_heuristic(GARG.state.ray_pdf, pdf);
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
