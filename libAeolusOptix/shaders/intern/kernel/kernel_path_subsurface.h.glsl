#ifndef _KERNEL_PATH_SUBSURFACE_H_
#define _KERNEL_PATH_SUBSURFACE_H_

SubsurfaceIndirectRays ss_indirect;
#ifndef _getSC
#define _getSC(idx) SC(idx)
#endif

#include "kernel/kernel_subsurface.h.glsl"
/*
 * Copyright 2017 Blender Foundation
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


 // if (kernel_path_subsurface_scatter(kg, &sd, emission_sd, L, state, ray, &throughput, &ss_indirect)) {
#define SS_STATE(i) ss_indirect.state[i]
#define SS_RAY(i) ss_indirect.rays[i] 
#define SS_THR(i) ss_indirect.throughputs[i] 
#define SS_LSTATE(i) ss_indirect.L_state[i] 

void path_radiance_bsdf_bounce_local(int idx,float bsdf_pdf,int bounce,int bsdf_label)
{
  float inverse_pdf = 1.0f / bsdf_pdf;

#ifdef _PASSES_
  if (bool(kernel_data.film.use_light_pass)){
    if (bounce == 0 && !bool(bsdf_label & LABEL_TRANSPARENT)) {
      /* first on directly visible surface */
      float3 value = SS_THR(idx)* inverse_pdf;
      SS_LSTATE(idx).diffuse      = PLYMO_EVAL_diffuse * value;
      SS_LSTATE(idx).glossy       = PLYMO_EVAL_glossy * value;
      SS_LSTATE(idx).transmission = PLYMO_EVAL_transmission * value;
      //ply_prs_volume = PLYMO_EVAL_volume * value;
      SS_THR(idx) =SS_LSTATE(idx).diffuse + SS_LSTATE(idx).glossy + SS_LSTATE(idx).transmission;//+ ply_prs_volume;
    }
    else {
      /* transparent bounce before first hit, or indirectly visible through BSDF */
      float3 sum  = (PLYMO_bsdf_eval_sum() + PLYMO_EVAL_transparent) * inverse_pdf;
      SS_THR(idx)*= sum;
    }
  }
  else
#endif
  {
    SS_THR(idx)  *=  PLYMO_EVAL_diffuse * inverse_pdf;
  }
}
ccl_device bool kernel_path_surface_bounce_local()
{
#ifdef WITH_STAT_ALL
#ifdef kernel_path_surface_bounce_flag
STAT_DUMP_u1(kernel_path_surface_bounce_flag , uint(GSD.flag));
#endif
#endif
  int idx = ss_indirect.num_rays;
  /* no BSDF? we can stop here */
  if (bool(GSD.flag & SD_BSDF)) {

    float randu,randv;
    path_rng_2D(
             SS_STATE(idx).rng_hash,
             SS_STATE(idx).sample_rsv,
             SS_STATE(idx).num_samples,
             SS_STATE(idx).rng_offset + int(PRNG_BSDF_U),
              randu,
              randv);
#ifdef ENABLE_PROFI
ply_L2Eval_profi_idx = float(PROFI_IDX);
#endif
#ifdef WITH_STAT_ALL
ply_L2Eval_rec_num = float(rec_num);
#endif

    ARGS_PRG3_SAMPLE(randu,randv)
    EXECUTION_SAMPLE;
#ifdef WITH_STAT_ALL
#ifdef kernel_path_surface_bounce_pdf
STAT_DUMP_f1(kernel_path_surface_bounce_pdf,PLYMO_L2Eval_pdf);
#endif
#ifdef shader_bsdf_sample_eval_light_pass
STAT_DUMP_u1(shader_bsdf_sample_eval_light_pass,uint(PLYMO_EVAL_get_use_light_pass));
#endif
#endif
#ifdef  WITH_STAT_ALL
#ifdef shader_bsdf_sample_eval_diffuse
  STAT_DUMP_f3(shader_bsdf_sample_eval_diffuse, PLYMO_EVAL_diffuse);

  if(bool(PLYMO_EVAL_get_use_light_pass)){
      STAT_DUMP_f3(shader_bsdf_sample_eval_glossy, PLYMO_EVAL_glossy);
      STAT_DUMP_f3(shader_bsdf_sample_eval_transmission, PLYMO_EVAL_transmission);
      STAT_DUMP_f3(shader_bsdf_sample_eval_transparent, PLYMO_EVAL_transparent);
  }
#endif
#endif

    if (PLYMO_L2Eval_pdf == 0.0f || PLYMO_bsdf_eval_is_zero())
      return false;
    int label = PLYMO_L2Eval_label;
    /* modify throughput */
    path_radiance_bsdf_bounce_local(idx,PLYMO_L2Eval_pdf , SS_STATE(idx).bounce, label);

#ifdef WITH_STAT_ALL
#ifdef kernel_path_surface_bounce_thr
    STAT_DUMP_f3(kernel_path_surface_bounce_thr,SS_THR(idx));
#endif
#endif

        /* set labels */
    if (!bool(label & LABEL_TRANSPARENT)) {
      SS_STATE(idx).ray_pdf = PLYMO_L2Eval_pdf;
#ifdef _LAMP_MIS_
      SS_STATE(idx).ray_t = 0.0f;
#endif
      SS_STATE(idx).min_ray_pdf = fminf(PLYMO_L2Eval_pdf, SS_STATE(idx).min_ray_pdf);
    }

    /* update path state */
    path_state_next(SS_STATE(idx),label);


    /* setup ray */
    SS_RAY(idx).P = ray_offset(GSD.P, bool(label & LABEL_TRANSMIT) ? -GSD.Ng : GSD.Ng);
    SS_RAY(idx).D = vec4(normalize(PLYMO_L2Eval_omega_in.xyz),0.);

#ifdef kernel_path_surface_bounce_local_D
  if(idx ==0){
   STAT_DUMP_f3(kernel_path_surface_bounce_local_D, SS_RAY(idx).D);
  }
#endif

    if (GSTATE.bounce == 0)
      SS_RAY(idx).t -= GSD.ray_length; /* clipping works through transparent */
    else
      SS_RAY(idx).t = FLT_MAX;

#ifdef _RAY_DIFFERENTIALS_
    SS_RAY(idx).dP    = GSD.dP;
    SS_RAY(idx).dD.dx = PLYMO_L2Eval_domega_in_dx;
    SS_RAY(idx).dD.dy = PLYMO_L2Eval_domega_in_dy;
#endif

#ifdef _VOLUME_
    /* enter/exit volume */
    if (label & LABEL_TRANSMIT)
      kernel_volume_stack_enter_exit(kg, sd, state->volume_stack);
#endif
    return true;
  }    
    return false;
};


ccl_device_inline int shader_bssrdf_pick(
                                        ccl_addr_space inout float3 throughput,
                                        inout float randu)
{
  /* Note the sampling here must match shader_bsdf_pick,
   * since we reuse the same random number. */
  int sampled = GSD.atomic_offset;

  if (GSD.num_closure > 1) {
    /* Pick a BSDF or BSSRDF or based on sample weights. */
    float sum_bsdf = 0.0f;
    float sum_bssrdf = 0.0f;
    int next = sampled;
    for (int i = 0; i < GSD.num_closure; i++) {
      if (CLOSURE_IS_BSDF(_getSC(next).type)) {
        sum_bsdf += _getSC(next).sample_weight;
      }
      else if (CLOSURE_IS_BSSRDF(_getSC(next).type)) {
        sum_bssrdf += _getSC(next).sample_weight;
      }
      next++;
    }

    float r = (randu) * (sum_bsdf + sum_bssrdf);
    float partial_sum = 0.0f;
    sampled = GSD.atomic_offset;
    for (int i = 0; i < GSD.num_closure; i++) {
  
      if (CLOSURE_IS_BSDF_OR_BSSRDF(_getSC( (sampled+i) ).type)) {
        float next_sum = partial_sum + _getSC( (sampled+i) ).sample_weight;
        if (r < next_sum) {
          if (CLOSURE_IS_BSDF(_getSC( (sampled+i) ).type)) {
            throughput *= (sum_bsdf + sum_bssrdf) / sum_bsdf;
            return -1;
          }
          else {
            throughput *= (sum_bsdf + sum_bssrdf) / sum_bssrdf;
            sampled = sampled+i;
            /* Rescale to reuse for direction sample, to better preserve stratification. */
            randu = (r - partial_sum) / _getSC(sampled).sample_weight;
            break;
          }
        }
        partial_sum = next_sum;
      }
    }
  }
  
  return CLOSURE_IS_BSSRDF(_getSC(sampled).type) ? sampled : -1;
}
                   
bool kernel_path_subsurface_scatter( in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SUBSURFACE);

  float bssrdf_u, bssrdf_v;
  path_state_rng_2D(GSTATE, int(PRNG_BSDF_U), bssrdf_u, bssrdf_v);
  int n  = shader_bssrdf_pick(throughput, bssrdf_u);
  /* do bssrdf scatter step if we picked a bssrdf closure */
  if (n >= 0) {
    /* We should never have two consecutive BSSRDF bounces,
     * the second one should be converted to a diffuse BSDF to
     * avoid this.
     */
    kernel_assert("assert  ::kernelpath_subsurface ::41 \n",!(bool(GSTATE.flag & PATH_RAY_DIFFUSE_ANCESTOR)));

    uint lcg_state = lcg_state_init_addrspace(GSTATE, 0x68bc21eb);

    int num_hits = subsurface_scatter_multi_intersect(n,lcg_state, bssrdf_u, bssrdf_v, false);
#  ifdef _VOLUME_
    bool need_update_volume_stack = kernel_data.integrator.use_volumes &&sd->object_flag & SD_OBJECT_INTERSECTS_VOLUME;
#  endif /* __VOLUME__ */
    
    
    LocalIntersection_tiny ss_isect;
    for (int hit = 0; hit < num_hits; hit++) {
          int idx = GSD.atomic_offset+hit;
          ss_isect.isect[hit]  =  IS(idx);
          idx += LOCAL_MAX_HITS;
          ss_isect.weight[hit].xyz =  vec3(IS(idx).t,IS(idx).u,IS(idx).v);
          if(hit==0){
             GetReturnRayPD;
          }
    }


    ClosureType bssrdf_type = _getSC(n).type;
    float bssrdf_roughness  = _getSC(n).data[8];

    for (int hit = 0; hit < num_hits; hit++) {
 
      subsurface_scatter_multi_setup(hit,bssrdf_type, bssrdf_roughness);
      int all = int(GSTATE.flag & int(PATH_RAY_SHADOW_CATCHER));
      kernel_path_surface_connect_light( 1.f,all);

      ss_indirect.state[ss_indirect.num_rays]       = GSTATE;
      ss_indirect.rays[ss_indirect.num_rays]        = ray;
      ss_indirect.throughputs[ss_indirect.num_rays] = GTHR;
      ss_indirect.L_state[ss_indirect.num_rays]     = GLAD.state;

      ss_indirect.state[ss_indirect.num_rays].rng_offset += int(PRNG_BOUNCE_NUM);

      if (kernel_path_surface_bounce_local()){
#  ifdef _LAMP_MIS_
        ss_indirect.state[ss_indirect.num_rays].ray_t = 0.0f;
#  endif // __LAMP_MIS__ 

#  ifdef _VOLUME_
        if (need_update_volume_stack) {
          Ray volume_ray = *ray;
          // Setup ray from previous surface point to the new one. 
          volume_ray.D = normalize_len(hit_ray->P - volume_ray.P, &volume_ray.t);

          kernel_volume_stack_update_for_subsurface(
              kg, emission_sd, &volume_ray, hit_state->volume_stack);
        }
#  endif // __VOLUME__ 
        ss_indirect.num_rays+=1;   
      }
    }
    
    return true;
  }
  return false;
}

/* define
ccl_device_inline void kernel_path_subsurface_init_indirect(
    ccl_addr_space SubsurfaceIndirectRays *ss_indirect)
{
  ss_indirect->num_rays = 0;
}
*/


#define kernel_path_subsurface_setup_indirect(ray) {\
  ss_indirect.num_rays--;\
  path_radiance_sum_indirect();\
  path_radiance_reset_indirect();\
  GSTATE     = ss_indirect.state[ss_indirect.num_rays];\
  ray        = ss_indirect.rays[ss_indirect.num_rays];\
  GLAD.state = ss_indirect.L_state[ss_indirect.num_rays];\
  GTHR       = ss_indirect.throughputs[ss_indirect.num_rays];\
  GSTATE.rng_offset += int(ss_indirect.num_rays * PRNG_BOUNCE_NUM);\
}




CCL_NAMESPACE_END

#endif