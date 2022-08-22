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

ccl_device_inline void path_state_init(uint rng_hash,int sample_rsv
                                       #ifdef _VOLUME_
                                       ,ccl_addr_space inout Ray ray
                                       #endif
                                       )
{
  GSTATE.flag = int(PATH_RAY_CAMERA | PATH_RAY_MIS_SKIP | PATH_RAY_TRANSPARENT_BACKGROUND);
  GSTATE.rng_hash = rng_hash;
  GSTATE.rng_offset = int(PRNG_BASE_NUM);
  GSTATE.sample_rsv = sample_rsv;
  GSTATE.num_samples = kernel_data.integrator.aa_samples;
  GSTATE.branch_factor = 1.0f;

  GSTATE.bounce = 0;
  GSTATE.diffuse_bounce = 0;
  GSTATE.glossy_bounce = 0;
  GSTATE.transmission_bounce = 0;
  GSTATE.transparent_bounce = 0;

#ifdef _DENOISING_FEATURES_
  if (kernel_data.film.pass_denoising_data !=0) {
    GSTATE.flag |= int(PATH_RAY_STORE_SHADOW_INFO);
    GSTATE.denoising_feature_weight = 1.0f;
    GSTATE.denoising_feature_throughput = make_float3(1.0f, 1.0f, 1.0f);
  }
  else {
    GSTATE.denoising_feature_weight = 0.0f;
    GSTATE.denoising_feature_throughput = make_float3(0.0f, 0.0f, 0.0f);
  }
#endif /* _DENOISING_FEATURES_ */

  GSTATE.min_ray_pdf = FLT_MAX;
  GSTATE.ray_pdf = 0.0f;
#ifdef _LAMP_MIS_
  GSTATE.ray_t = 0.0f;
#endif

#ifdef _VOLUME_
  GSTATE.volume_bounce = 0;
  GSTATE.volume_bounds_bounce = 0;

  if (kernel_data.integrator.use_volumes) {
    /* Initialize volume stack with volume we are inside of. */
    kernel_volume_stack_init(GSD, GSTATE, ray, GSTATE.volume_stack);
  }
  else {
    GSTATE.volume_stack[0].shader = SHADER_NONE;
  }
#endif
}

#if defined(GSTATE)
ccl_device_inline void path_state_next(inout PathState STATE,int label)
{
  /* ray through transparent keeps same flags from previous ray and is
   * not counted as a regular bounce, transparent has separate max */
  if (bool(label & LABEL_TRANSPARENT)) {
    STATE.flag |= int(PATH_RAY_TRANSPARENT);
    STATE.transparent_bounce++;
    if (STATE.transparent_bounce >= kernel_data.integrator.transparent_max_bounce) {
      STATE.flag |= int(PATH_RAY_TERMINATE_IMMEDIATE);
    }

    if (!bool(kernel_data.integrator.transparent_shadows))
      STATE.flag |= int(PATH_RAY_MIS_SKIP);

    /* random number generator next bounce */
    STATE.rng_offset += int(PRNG_BOUNCE_NUM);
    return;

  }

  STATE.bounce++;
  if (STATE.bounce >= kernel_data.integrator.max_bounce) {
    STATE.flag |= int(PATH_RAY_TERMINATE_AFTER_TRANSPARENT);
  }

  STATE.flag &= int(~(PATH_RAY_ALL_VISIBILITY | PATH_RAY_MIS_SKIP));

#ifdef _VOLUME_
  if (label & LABEL_VOLUME_SCATTER) {
    /* volume scatter */
    STATE.flag |= PATH_RAY_VOLUME_SCATTER;
    STATE.flag &= ~PATH_RAY_TRANSPARENT_BACKGROUND;

    STATE.volume_bounce++;
    if (STATE.volume_bounce >= kernel_data.integrator.max_volume_bounce) {
      STATE.flag |= PATH_RAY_TERMINATE_AFTER_TRANSPARENT;
    }
  }
  else
#endif
  {
    /* surface reflection/transmission */
    if (bool(label & LABEL_REFLECT)) {
      STATE.flag |=  int(PATH_RAY_REFLECT);
      STATE.flag &=  int(~PATH_RAY_TRANSPARENT_BACKGROUND);

      if(bool(label & LABEL_DIFFUSE)) {
        STATE.diffuse_bounce++;
        if (STATE.diffuse_bounce >= kernel_data.integrator.max_diffuse_bounce) {
          STATE.flag |= int(PATH_RAY_TERMINATE_AFTER_TRANSPARENT);
        }
      }
      else {
        STATE.glossy_bounce++;
        if (STATE.glossy_bounce >= kernel_data.integrator.max_glossy_bounce) {
          STATE.flag |= int(PATH_RAY_TERMINATE_AFTER_TRANSPARENT);
        }
      }
    }
    else {
      kernel_assert("assert rchit1 1738 ",label & LABEL_TRANSMIT);

      STATE.flag |= int(PATH_RAY_TRANSMIT);
      if (!bool(label & LABEL_TRANSMIT_TRANSPARENT)) {
        STATE.flag &= int(~PATH_RAY_TRANSPARENT_BACKGROUND);
      }

      STATE.transmission_bounce++;
      if (STATE.transmission_bounce >= kernel_data.integrator.max_transmission_bounce) {
        STATE.flag |= int(PATH_RAY_TERMINATE_AFTER_TRANSPARENT);
      }
    }

    /* diffuse/glossy/singular */
    if (bool(label & LABEL_DIFFUSE)) {
      STATE.flag |= int(PATH_RAY_DIFFUSE | PATH_RAY_DIFFUSE_ANCESTOR);
    }
    else if (bool(label & LABEL_GLOSSY)) {
      STATE.flag |= int(PATH_RAY_GLOSSY);
    }
    else {
      kernel_assert("assert rchit1 1759 ",label & LABEL_SINGULAR);
      STATE.flag |= int(PATH_RAY_GLOSSY | PATH_RAY_SINGULAR | PATH_RAY_MIS_SKIP);
    }
  }

  /* random number generator next bounce */
  STATE.rng_offset += int(PRNG_BOUNCE_NUM);

#ifdef _DENOISING_FEATURES_
  if ((STATE.denoising_feature_weight == 0.0f) && !(STATE.flag & PATH_RAY_SHADOW_CATCHER)) {
    STATE.flag &= ~PATH_RAY_STORE_SHADOW_INFO;
  }
#endif

}

#endif

#ifdef _VOLUME_
ccl_device_inline bool path_state_volume_next(inout KernelGlobals kg, ccl_addr_space inout PathState state)
{
  /* For volume bounding meshes we pass through without counting transparent
   * bounces, only sanity check in case self intersection gets us stuck. */
  state.volume_bounds_bounce++;
  if (state.volume_bounds_bounce > VOLUME_BOUNDS_MAX) {
    return false;
  }

  /* Random number generator next bounce. */
  if (state.volume_bounds_bounce > 1) {
    state.rng_offset += int(PRNG_BOUNCE_NUM);
  }

  return true;
}
#endif


#if  defined(GSTATE) 

ccl_device_inline uint path_state_ray_visibility()
{
  uint flag = uint(GSTATE.flag & int(PATH_RAY_ALL_VISIBILITY));

  /* for visibility, diffuse/glossy are for reflection only */
  if (bool(flag & PATH_RAY_TRANSMIT))
    flag &= ~(PATH_RAY_DIFFUSE | PATH_RAY_GLOSSY);
  /* todo: this is not supported as its own ray visibility yet */
  if (bool(GSTATE.flag & PATH_RAY_VOLUME_SCATTER))
    flag |= PATH_RAY_DIFFUSE;

  return flag;
}


#define  path_state_modify_bounce(increase) \
{\
  if (increase) GSTATE.bounce += 1;\
  else GSTATE.bounce -= 1;\
}

#endif

#if defined(GSTATE)

ccl_device_inline bool path_state_ao_bounce()
{
  if (GSTATE.bounce <= kernel_data.integrator.ao_bounces) {
    return false;
  }
  int bounce = GSTATE.bounce - GSTATE.transmission_bounce - int(GSTATE.glossy_bounce > 0);
  return (bounce > kernel_data.integrator.ao_bounces);
}

#if defined(GTHR)  




ccl_device_inline float path_state_continuation_probability()
{
  if (bool(GSTATE.flag & PATH_RAY_TERMINATE_IMMEDIATE)) {
    /* Ray is to be terminated immediately. */
    return 0.0f;
  }
  else if (bool(GSTATE.flag & PATH_RAY_TRANSPARENT) ) {
    /* Do at least specified number of bounces without RR. */
    if (GSTATE.transparent_bounce <= kernel_data.integrator.transparent_min_bounce) {
      return 1.0f;
    }
#ifdef _SHADOW_TRICKS_
    /* Exception for shadow catcher not working correctly with RR. */
    else if ( bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER) && (GSTATE.transparent_bounce <= 8)) {
      return 1.0f;
    }
#endif
  }
  else {
    /* Do at least specified number of bounces without RR. */
    if (GSTATE.bounce <= kernel_data.integrator.min_bounce) {
      return 1.0f;
    }
#ifdef _SHADOW_TRICKS_
    /* Exception for shadow catcher not working correctly with RR. */
    else if ( bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER) && (GSTATE.bounce <= 3)) {
      return 1.0f;
    }
#endif
  }

  /* Probabilistic termination: use sqrt() to roughly match typical view
   * transform and do path termination a bit later on average. */
  return min(sqrtf(max3(fabs(GTHR)) * GSTATE.branch_factor), 1.0f);
}

#endif
#endif


ccl_device_inline void path_state_branch(ccl_addr_space inout PathState state,
                                         int branch,
                                         int num_branches)
{
  if (num_branches > 1) {
    /* Path is splitting into a branch, adjust so that each branch
     * still gets a unique sample_rsv from the same sequence. */
    state.sample_rsv = state.sample_rsv * num_branches + branch;
    state.num_samples = state.num_samples * num_branches;
    state.branch_factor *= num_branches;
  }
}

CCL_NAMESPACE_END
