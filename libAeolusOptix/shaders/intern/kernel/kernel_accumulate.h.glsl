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

/* BSDF Eval
 *
 * BSDF evaluation result, split per BSDF type. This is used to accumulate
 * render passes separately. */


#ifdef GSD
ccl_device float3 shader_bsdf_transparency()
{
  if (bool(GSD.flag & SD_HAS_ONLY_VOLUME)) {
    return make_float3(1.0f, 1.0f, 1.0f);
  }
  else if (bool(GSD.flag & SD_TRANSPARENT)) {
    return GSD.closure_transparent_extinction;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

#endif

#ifdef _CLAMP_SAMPLE_
#define  path_radiance_clamp(L,  bounce)\
{\
  float limit = (bounce > 0) ? kernel_data.integrator.sample_clamp_indirect :kernel_data.integrator.sample_clamp_direct;\
  float sum = reduce_add(fabs(L));\
  if (sum > limit) {L *= limit / sum; }\
}

#define path_radiance_clamp_throughput( L,throughput,bounce) \
{\
  float limit = (bounce > 0) ? kernel_data.integrator.sample_clamp_indirect :kernel_data.integrator.sample_clamp_direct;\
  float sum = reduce_add(fabs(L));\
  if (sum > limit) {float clamp_factor = limit / sum;L *= clamp_factor;throughput *= clamp_factor;}\
}

#endif

#ifdef PLYMO
ccl_device_inline void bsdf_eval_init(
                                      ClosureType type,
                                      float3 value,
                                      int use_light_pass)
{
#ifdef _PASSES_
  PLYMO.use_light_pass = use_light_pass;

  if (PLYMO.use_light_pass !=0 ) {
    PLYMO.eval.diffuse = make_float3(0.0f, 0.0f, 0.0f);
    PLYMO.eval.glossy = make_float3(0.0f, 0.0f, 0.0f);
    PLYMO.eval.transmission = make_float3(0.0f, 0.0f, 0.0f);
    PLYMO.eval.transparent = make_float3(0.0f, 0.0f, 0.0f);
    //PLYMO.eval.volume = make_float3(0.0f, 0.0f, 0.0f);

    if (type == CLOSURE_BSDF_TRANSPARENT_ID)
      PLYMO.eval.transparent = value;
    else if (CLOSURE_IS_BSDF_DIFFUSE(type) || CLOSURE_IS_BSDF_BSSRDF(type))
      PLYMO.eval.diffuse = value;
    else if (CLOSURE_IS_BSDF_GLOSSY(type))
      PLYMO.eval.glossy = value;
    else if (CLOSURE_IS_BSDF_TRANSMISSION(type))
      PLYMO.eval.transmission = value;
     /* 
    else if (CLOSURE_IS_PHASE(type))
      PLYMO.eval.volume = value;
    */
  }
  else
#endif
  {
    PLYMO.eval.diffuse = value;
  }
#ifdef _SHADOW_TRICKS_
  PLYMO.eval.sum_no_mis = make_float3(0.0f, 0.0f, 0.0f);
#endif

}

ccl_device_inline void bsdf_eval_accum(
                                       ClosureType type,
                                       float3 value,
                                       float mis_weight)
{
#ifdef _SHADOW_TRICKS_
  PLYMO.eval.sum_no_mis += value;
#endif
  value *= mis_weight;

#ifdef _PASSES_

  if (PLYMO.use_light_pass !=0) {
    if (CLOSURE_IS_BSDF_DIFFUSE(type) || CLOSURE_IS_BSDF_BSSRDF(type))
      PLYMO.eval.diffuse += value;
    else if (CLOSURE_IS_BSDF_GLOSSY(type))
      PLYMO.eval.glossy += value;
    else if (CLOSURE_IS_BSDF_TRANSMISSION(type))
      PLYMO.eval.transmission += value;
    /*  
    else if (CLOSURE_IS_PHASE(type))
      PLYMO.eval.volume += value;
    */  
    /* skipping transparent, this function is used by for eval(), will be zero then */
  }
  else
#endif
  {
    PLYMO.eval.diffuse += value;
  }
}


ccl_device_inline bool bsdf_eval_is_zero()
{
#ifdef _PASSES_
  if (PLYMO.use_light_pass!=0) {
    return is_zero(PLYMO.eval.diffuse) && is_zero(PLYMO.eval.glossy) && is_zero(PLYMO.eval.transmission) &&
           is_zero(PLYMO.eval.transparent);  //&& is_zero(eval.volume);
  }
  else
#endif
  {
    return is_zero(PLYMO.eval.diffuse);
  }
}

ccl_device_inline void bsdf_eval_mis( float value)
{
#ifdef _PASSES_
  if (PLYMO.use_light_pass !=0) {
    PLYMO.eval.diffuse *= value;
    PLYMO.eval.glossy *= value;
    PLYMO.eval.transmission *= value;
   // PLYMO.eval.volume *= value;

    /* skipping transparent, this function is used by for eval(), will be zero then */
  }
  else
#endif
  {
    PLYMO.eval.diffuse *= value;
  }
}

ccl_device_inline void bsdf_eval_mul( float value)
{
#ifdef _SHADOW_TRICKS_
  PLYMO.eval.sum_no_mis *= value;
#endif
  bsdf_eval_mis(value);
}


ccl_device_inline void bsdf_eval_mul3( float3 value)
{
#ifdef _SHADOW_TRICKS_
  PLYMO.eval.sum_no_mis *= value;
#endif
#ifdef _PASSES_
  if (PLYMO.use_light_pass !=0 ) {
    PLYMO.eval.diffuse *= value;
    PLYMO.eval.glossy *= value;
    PLYMO.eval.transmission *= value;
    //PLYMO.eval.volume *= value;

    /* skipping transparent, this function is used by for eval(), will be zero then */
  }
  else
    PLYMO.eval.diffuse *= value;
#else
  PLYMO.eval.diffuse *= value;
#endif
}

ccl_device_inline float3 bsdf_eval_sum()
{
#ifdef _PASSES_
  if (PLYMO.use_light_pass !=0) {
    return PLYMO.eval.diffuse + PLYMO.eval.glossy + PLYMO.eval.transmission;// + PLYMO.eval.volume;
  }
  else
#endif
    return PLYMO.eval.diffuse;
}

#endif
/* Path Radiance
 *
 * We accumulate different render passes separately. After summing at the end
 * to get the combined result, it should be identical. We definite directly
 * visible as the first non-transparent hit, while indirectly visible are the
 * bounces after that. */
#if defined(GLAD) && defined(RPL_RGEN_OUT)

ccl_device_inline void path_radiance_init()
{
  /* clear all */
#ifdef _PASSES_
  GLAD.use_light_pass = kernel_data.film.use_light_pass;

  if (kernel_data.film.use_light_pass !=0) {
    GLAD.indirect = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.direct_emission = make_float3(0.0f, 0.0f, 0.0f);

    GLAD.color_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.color_glossy = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.color_transmission = make_float3(0.0f, 0.0f, 0.0f);

    GLAD.direct_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.direct_glossy = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.direct_transmission = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.direct_volume = make_float3(0.0f, 0.0f, 0.0f);

    GLAD.indirect_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.indirect_glossy = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.indirect_transmission = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.indirect_volume = make_float3(0.0f, 0.0f, 0.0f);

    GLAD.transparent = 0.0f;
    GLAD.emission = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.background = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.ao = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.shadow = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    GLAD.mist = 0.0f;

    GLAD.state.diffuse = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.state.glossy = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.state.transmission = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.state.volume = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.state.direct = make_float3(0.0f, 0.0f, 0.0f);
  }
  else
#endif
  {
    GLAD.transparent = 0.0f;
    GLAD.emission = make_float3(0.0f, 0.0f, 0.0f);
  }

#ifdef _SHADOW_TRICKS_
  GLAD.path_total = make_float3(0.0f, 0.0f, 0.0f);
  GLAD.path_total_shaded = make_float3(0.0f, 0.0f, 0.0f);
  GLAD.shadow_background_color = make_float3(0.0f, 0.0f, 0.0f);
  GLAD.shadow_throughput = 0.0f;
  GLAD.shadow_transparency = 1.0f;
  GLAD.has_shadow_catcher = 0;
#endif

#ifdef _DENOISING_FEATURES_
  GLAD.denoising_normal = make_float3(0.0f, 0.0f, 0.0f);
  GLAD.denoising_albedo = make_float3(0.0f, 0.0f, 0.0f);
  GLAD.denoising_depth = 0.0f;
#endif

#ifdef _KERNEL_DEBUG_
  GLAD.debug_data.num_bvh_traversed_nodes = 0;
  GLAD.debug_data.num_bvh_traversed_instances = 0;
  GLAD.debug_data.num_bvh_intersections = 0;
  GLAD.debug_data.num_ray_bounces = 0;
#endif
}

ccl_device_inline void path_radiance_sum_indirect()
{
#ifdef _PASSES_
  /* this division is a bit ugly, but means we only have to keep track of
   * only a single throughput further along the path, here we recover just
   * the indirect path that is not influenced by any particular BSDF type */
  if (GLAD.use_light_pass!=0) {
    GLAD.direct_emission = safe_divide_color(GLAD.direct_emission, GLAD.state.direct);
    GLAD.direct_diffuse += GLAD.state.diffuse * GLAD.direct_emission;
    GLAD.direct_glossy += GLAD.state.glossy * GLAD.direct_emission;
    GLAD.direct_transmission += GLAD.state.transmission * GLAD.direct_emission;
    #ifdef _VOLUME_
    GLAD.direct_volume += GLAD.state.volume * GLAD.direct_emission;
    #endif

    GLAD.indirect = safe_divide_color(GLAD.indirect, GLAD.state.direct);
    GLAD.indirect_diffuse += GLAD.state.diffuse * GLAD.indirect;
    GLAD.indirect_glossy += GLAD.state.glossy * GLAD.indirect;
    GLAD.indirect_transmission += GLAD.state.transmission * GLAD.indirect;
    #ifdef _VOLUME_
    GLAD.indirect_volume += GLAD.state.volume * GLAD.indirect;
    #endif
  }
#endif
}



#ifdef _SHADOW_TRICKS_
ccl_device_inline void path_radiance_sum_shadowcatcher(inout float3 L_sum,inout float alpha)
{
  /* Calculate current shadow of the path. */
  float path_total = average(GLAD.path_total);
  float shadow;

  if (UNLIKELY(!isfinite_safe(path_total))) {
    //kernel_assert(!"Non-finite total radiance along the path");
    kernel_assert("assert KERNEL_ACCUM : 286",false);
    shadow = 0.0f;
  }
  else if (path_total == 0.0f) {
    shadow = GLAD.shadow_transparency;
  }
  else {
    float path_total_shaded = average(GLAD.path_total_shaded);
    shadow = path_total_shaded / path_total;
  }

  /* Calculate final light sum and transparency for shadow catcher object. */
  if (kernel_data.background.transparent!=0) {
    alpha -= GLAD.shadow_throughput * shadow;
  }
  else {
    GLAD.shadow_background_color *= shadow;
    L_sum += GLAD.shadow_background_color;
  }
}
#endif

ccl_device_inline float3 path_radiance_clamp_and_sum(inout float alpha)
{
  float3 L_sum;
  // Light Passes are used 
#ifdef _PASSES_
  float3 L_direct, L_indirect;
  if (GLAD.use_light_pass!=0) {
    path_radiance_sum_indirect();

    L_direct = GLAD.direct_diffuse + GLAD.direct_glossy + GLAD.direct_transmission + GLAD.emission 
    #ifdef _VOLUME_
    + GLAD.direct_volume
    #endif
    ;

    L_indirect = GLAD.indirect_diffuse + GLAD.indirect_glossy + GLAD.indirect_transmission    
    #ifdef _VOLUME_
    + GLAD.indirect_volume
    #endif
    ;

    if (kernel_data.background.transparent ==0)
      L_direct += GLAD.background;

    L_sum = L_direct + L_indirect;
    float sum = fabsf(L_sum.x) + fabsf(L_sum.y) + fabsf(L_sum.z);

    /* Reject invalid value */
    if (!isfinite_safe(sum)) {
      kernel_assert("assert KERNEL_ACCUM 337 Non-finite sum in path_radiance_clamp_and_sum! ",false);
      L_sum = make_float3(0.0f, 0.0f, 0.0f);
      GLAD.direct_diffuse = make_float3(0.0f, 0.0f, 0.0f);
      GLAD.direct_glossy = make_float3(0.0f, 0.0f, 0.0f);
      GLAD.direct_transmission = make_float3(0.0f, 0.0f, 0.0f);
      #ifdef _VOLUME_
      GLAD.direct_volume = make_float3(0.0f, 0.0f, 0.0f);
      #endif

      GLAD.indirect_diffuse = make_float3(0.0f, 0.0f, 0.0f);
      GLAD.indirect_glossy = make_float3(0.0f, 0.0f, 0.0f);
      GLAD.indirect_transmission = make_float3(0.0f, 0.0f, 0.0f);
      #ifdef _VOLUME_
      GLAD.indirect_volume = make_float3(0.0f, 0.0f, 0.0f);
      #endif

      GLAD.emission = make_float3(0.0f, 0.0f, 0.0f);
    }
  }

  // No Light Passes 
  else
#endif
  {
    L_sum = GLAD.emission;
    //Reject invalid value 
    float sum = fabsf(L_sum.x) + fabsf(L_sum.y) + fabsf(L_sum.z);
    if (!isfinite_safe(sum)) {
      //kernel_assert("assert KERNEL_ACCUM 365 Non-finite sum in path_radiance_clamp_and_sum! ",false);
      L_sum = make_float3(1.0f, 0.0f, 0.0f);
    }
  }

  // Compute alpha. 
  alpha = 1.0f - GLAD.transparent;

  // Add shadow catcher contributions. 
#ifdef _SHADOW_TRICKS_
  if (GLAD.has_shadow_catcher!=0) {
    path_radiance_sum_shadowcatcher(L_sum, alpha);
  }
#endif // _SHADOW_TRICKS_ 

  return L_sum;
}

#endif

#if defined(GLAD)
ccl_device_inline void path_radiance_accum_emission(
                                                    int state_flag,
                                                    int state_bounce,
                                                    float3 throughput,
                                                    float3 value)
{
#ifdef _SHADOW_TRICKS_
  if (bool(state_flag & PATH_RAY_SHADOW_CATCHER) ){
    return;
  }
#endif

  float3 contribution = throughput * value;
#ifdef _CLAMP_SAMPLE_
  path_radiance_clamp(contribution, state_bounce - 1);
#endif

#ifdef _PASSES_
  if (bool(L_USE_LIGHT_PASS)) {
    if (state_bounce == 0)
      GLAD.emission += contribution;
    else if (state_bounce == 1)
      GLAD.direct_emission += contribution;
    else
      GLAD.indirect += contribution;
  }
  else
#endif
  {
    GLAD.emission += contribution;
  }

}


#endif




#ifdef PLYMO

ccl_device_inline void path_radiance_accum_ao(inout KernelGlobals kg,
                                              inout PathRadiance L,
                                              ccl_addr_space inout PathState state,
                                              float3 throughput,
                                              float3 alpha,
                                              float3 bsdf,
                                              float3 ao)
{
#ifdef _PASSES_
  /* Store AO pass. */
  if (bool( (L.use_light_pass!=0) && state.bounce == 0) ){
    L.ao += alpha * throughput * ao;
  }
#endif

#ifdef _SHADOW_TRICKS_
  /* For shadow catcher, accumulate ratio. */
  if (bool(state.flag & PATH_RAY_STORE_SHADOW_INFO) ){
    float3 light = throughput * bsdf;
    L.path_total += light;
    L.path_total_shaded += ao * light;

    if (bool(state.flag & PATH_RAY_SHADOW_CATCHER) ){
      return;
    }
  }
#endif

  float3 contribution = throughput * bsdf * ao;

#ifdef _PASSES_
  if (L.use_light_pass !=0) {
    if (state.bounce == 0) {
      /* Directly visible lighting. */
      L.direct_diffuse += contribution;
    }
    else {
      /* Indirectly visible lighting after BSDF bounce. */
      L.indirect += contribution;
    }
  }
  else
#endif
  {
    L.emission += contribution;
  }
}

ccl_device_inline void path_radiance_accum_total_ao(inout PathRadiance L,
                                                    ccl_addr_space inout PathState state,
                                                    float3 throughput,
                                                    float3 bsdf)
{
#ifdef _SHADOW_TRICKS_
  if (bool(state.flag & PATH_RAY_STORE_SHADOW_INFO) ){
    L.path_total += throughput * bsdf;
  }
#else
#ifdef _KERNEL_VULKAN_
#else
  (void)L;
  (void)state;
  (void)throughput;
  (void)bsdf;
#endif
#endif
}


ccl_device_inline void path_radiance_accum_transparent(inout PathRadiance L,
                                                       ccl_addr_space inout PathState state,
                                                       float3 throughput)
{
  L.transparent += average(throughput);
}







ccl_device_inline void path_radiance_copy_indirect(inout PathRadiance L, in PathRadiance L_src)
{
#ifdef _PASSES_
  if (L.use_light_pass!=0) {
    L.state = L_src.state;

    L.direct_emission = L_src.direct_emission;
    L.indirect = L_src.indirect;
  }
#endif
}



#endif

#if defined(GSTATE) && defined(GLAD) &&defined(GTHR) 


#if defined(RPL_RGEN_OUT) 

#ifdef _SHADOW_TRICKS_
ccl_device_inline void path_radiance_accum_shadowcatcher(float3 background)
{
  GLAD.shadow_throughput += average(GTHR);
  GLAD.shadow_background_color += GTHR * background;
  GLAD.has_shadow_catcher = 1;
}
#endif


// Ladiance Payload
ccl_device_inline void path_radiance_accum_background(in float3 value)
{

#ifdef _SHADOW_TRICKS_
  if (bool(GSTATE.flag & PATH_RAY_STORE_SHADOW_INFO)) {
    GLAD.path_total += GTHR * value;
    GLAD.path_total_shaded += GTHR * value * GLAD.shadow_transparency;

    if (bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER) ){
      return;
    }
  }
#endif

  float3 contribution = GTHR * value;
#ifdef _CLAMP_SAMPLE_
  path_radiance_clamp(contribution, GSTATE.bounce - 1);
#endif

#ifdef _PASSES_
  if (GLAD.use_light_pass !=0) {
    if (bool(GSTATE.flag & PATH_RAY_TRANSPARENT_BACKGROUND))
      GLAD.background += contribution;
    else if (GSTATE.bounce == 1)
      GLAD.direct_emission += contribution;
    else
      GLAD.indirect += contribution;
  }
  else
#endif
  {
    
    
  
    GLAD.emission += contribution;
  }




#ifdef _DENOISING_FEATURES_
  GLAD.denoising_albedo += GSTATE.denoising_feature_weight * GSTATE.denoising_feature_throughput *
                         value;
#endif /* _DENOISING_FEATURES_ */
}
#endif

ccl_device_inline void path_radiance_accum_total_light(
                                                       int state_flag,
                                                       vec4 throughput,
                                                       vec4 sum_no_mis)
{
#ifdef _SHADOW_TRICKS_
  if (bool(state_flag & PATH_RAY_STORE_SHADOW_INFO)) {
    GLAD.path_total +=  throughput * sum_no_mis;
  }
#else
  uint(state_flag);
#endif
}

#if  (!defined(NO_L_STATE)) 


ccl_device_inline void path_radiance_reset_indirect()
{
#ifdef _PASSES_
  if (GLAD.use_light_pass !=0) {
    GLAD.state.diffuse = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.state.glossy = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.state.transmission = make_float3(0.0f, 0.0f, 0.0f);
     #ifdef _VOLUME_
    GLAD.state.volume = make_float3(0.0f, 0.0f, 0.0f);
    #endif

    GLAD.direct_emission = make_float3(0.0f, 0.0f, 0.0f);
    GLAD.indirect = make_float3(0.0f, 0.0f, 0.0f);
  }
#endif
}


void path_radiance_bsdf_bounce(float bsdf_pdf,int bounce,int bsdf_label)
{
  float inverse_pdf = 1.0f / bsdf_pdf;

#ifdef _PASSES_
  if (bool(kernel_data.film.use_light_pass)){
    if (bounce == 0 && !bool(bsdf_label & LABEL_TRANSPARENT)) {
      /* first on directly visible surface */
      float3 value = GTHR * inverse_pdf;
      GLAD.state.diffuse = PLYMO_EVAL_diffuse * value;
      GLAD.state.glossy    = PLYMO_EVAL_glossy * value;
      GLAD.state.transmission = PLYMO_EVAL_transmission * value;
      //ply_prs_volume = PLYMO_EVAL_volume * value;
      GTHR = GLAD.state.diffuse + GLAD.state.glossy + GLAD.state.transmission;//+ ply_prs_volume;
      
    }
    else {
      /* transparent bounce before first hit, or indirectly visible through BSDF */
      float3 sum  = (PLYMO_bsdf_eval_sum() + PLYMO_EVAL_transparent) * inverse_pdf;
      GTHR*= sum;
    }
  }
  else
#endif
  {
/*
      atomicAdd(counter[PROFI_ATOMIC - 10],int(1000.f*PLYMO_EVAL_diffuse.x));
      atomicAdd(counter[PROFI_ATOMIC - 9],int(1000.f*PLYMO_EVAL_diffuse.y));
      atomicAdd(counter[PROFI_ATOMIC - 8],int(1000.f*PLYMO_EVAL_diffuse.z));
      atomicAdd(counter[PROFI_ATOMIC - 7],int(1000.f* bsdf_pdf));
      atomicAdd(counter[PROFI_ATOMIC - 6],int(1));
*/
    GTHR  *=  PLYMO_EVAL_diffuse * inverse_pdf;
  }



}

ccl_device_inline void path_radiance_accum_light(
                                                 float3 shadow,
                                                 float shadow_fac,
                                                 bool is_lamp)
{
#ifdef _SHADOW_TRICKS_
  if (bool(GSTATE.flag & PATH_RAY_STORE_SHADOW_INFO)) {
    float3 light = GTHR * PLYMO_EVAL_sum_no_mis;
    GLAD.path_total += light;
    GLAD.path_total_shaded += shadow * light;
    if (bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER)) {return;}
  }
#endif
  float3 shaded_throughput = GTHR * shadow;

#ifdef _PASSES_
  if (GLAD.use_light_pass !=0) {
    /* Compute the clamping based on the total contribution.
     * The resulting scale is then be applied to all individual components. */
    float3 full_contribution = shaded_throughput * PLYMO_bsdf_eval_sum();
#  ifdef _CLAMP_SAMPLE_
     path_radiance_clamp_throughput(full_contribution, shaded_throughput, GSTATE.bounce);
#  endif

    if (GSTATE.bounce == 0) {
      /* directly visible lighting */
      GLAD.direct_diffuse += shaded_throughput * PLYMO_EVAL_diffuse;
      GLAD.direct_glossy += shaded_throughput * PLYMO_EVAL_glossy;
      GLAD.direct_transmission += shaded_throughput * PLYMO_EVAL_transmission;
      //prd.L.direct_volume += shaded_throughput * bsdf_eval.volume;

      if (is_lamp) {
        GLAD.shadow.x += shadow.x * shadow_fac;
        GLAD.shadow.y += shadow.y * shadow_fac;
        GLAD.shadow.z += shadow.z * shadow_fac;
      }
    }
    else {
      /* indirectly visible lighting after BSDF bounce */
      GLAD.indirect += full_contribution;
    }
  }
  else
#endif
  {
    float3 contribution = shaded_throughput * PLYMO_EVAL_diffuse;
    path_radiance_clamp( contribution, GSTATE.bounce);
    GLAD.emission += contribution;
  }

}


#endif

#endif


#if defined(GSTATE) && defined(GSD) && defined(ARGS_PRG3_SAMPLE)
 /* path tracing: bounce off or through surface to with new direction stored in ray */
ccl_device bool kernel_path_surface_bounce(inout Ray ray)
{
#ifdef WITH_STAT_ALL
#ifdef kernel_path_surface_bounce_flag
STAT_DUMP_u1(kernel_path_surface_bounce_flag , uint(GSD.flag));
#endif
#endif
  /* no BSDF? we can stop here */
  if (bool(GSD.flag & SD_BSDF)) {

    float randu,randv;
    path_rng_2D(
             GSTATE.rng_hash,
             GSTATE.sample_rsv,
             GSTATE.num_samples,
             GSTATE.rng_offset + int(PRNG_BSDF_U),
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
    path_radiance_bsdf_bounce(PLYMO_L2Eval_pdf , GSTATE.bounce, label);

#ifdef WITH_STAT_ALL
#ifdef kernel_path_surface_bounce_thr
    STAT_DUMP_f3(kernel_path_surface_bounce_thr,GTHR);
#endif
#endif

        /* set labels */
    if (!bool(label & LABEL_TRANSPARENT)) {
      GSTATE.ray_pdf = PLYMO_L2Eval_pdf;
#ifdef _LAMP_MIS_
      GSTATE.ray_t = 0.0f;
#endif
      GSTATE.min_ray_pdf = fminf(PLYMO_L2Eval_pdf, GSTATE.min_ray_pdf);
    }

    /* update path state */
    path_state_next(GSTATE,label);

    /* setup ray */
    ray.P = ray_offset(sd.P, bool(label & LABEL_TRANSMIT) ? -GSD.Ng : GSD.Ng);
    ray.D = vec4(normalize(PLYMO_L2Eval_omega_in.xyz),0.);

    if (GSTATE.bounce == 0)
      ray.t -= GSD.ray_length; /* clipping works through transparent */
    else
      ray.t = FLT_MAX;

#ifdef _RAY_DIFFERENTIALS_
    ray.dP    = GSD.dP;
    ray.dD.dx = PLYMO_L2Eval_domega_in_dx;
    ray.dD.dy = PLYMO_L2Eval_domega_in_dy;
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


#endif

ccl_device_inline void path_radiance_split_denoising(inout KernelGlobals kg,
                                                     inout PathRadiance L,
                                                     inout float3 noisy,
                                                     inout float3 clean)
{
#ifdef _PASSES_
  kernel_assert("assert KERNEL_ACCUM : 737",L.use_light_pass);

  clean = L.emission + L.background;
  #ifdef _VOLUME_
  noisy = L.direct_volume + L.indirect_volume;
  #endif

#  define ADD_COMPONENT(flag, component) \
    if (bool( bool(kernel_data.film.denoising_flags) && bool(flag) )) \
      clean += component; \
    else \
      noisy += component;

  ADD_COMPONENT(DENOISING_CLEAN_DIFFUSE_DIR, L.direct_diffuse);
  ADD_COMPONENT(DENOISING_CLEAN_DIFFUSE_IND, L.indirect_diffuse);
  ADD_COMPONENT(DENOISING_CLEAN_GLOSSY_DIR, L.direct_glossy);
  ADD_COMPONENT(DENOISING_CLEAN_GLOSSY_IND, L.indirect_glossy);
  ADD_COMPONENT(DENOISING_CLEAN_TRANSMISSION_DIR, L.direct_transmission);
  ADD_COMPONENT(DENOISING_CLEAN_TRANSMISSION_IND, L.indirect_transmission);
#  undef ADD_COMPONENT
#else
  noisy = L.emission;
  clean = make_float3(0.0f, 0.0f, 0.0f);
#endif

#ifdef _SHADOW_TRICKS_
  if (L.has_shadow_catcher !=0) {
    noisy += L.shadow_background_color;
  }
#endif

  noisy = ensure_finite3(noisy);
  clean = ensure_finite3(clean);
}

ccl_device_inline void path_radiance_accum_sample(inout PathRadiance L, inout PathRadiance L_sample)
{
#ifdef _SPLIT_KERNEL_
#  define safe_float3_add(f, v) \
    do { \
      ccl_global float *p = (ccl_global float *)(&(f)); \
      atomic_add_and_fetch_float(p + 0, (v).x); \
      atomic_add_and_fetch_float(p + 1, (v).y); \
      atomic_add_and_fetch_float(p + 2, (v).z); \
    } while (0)
#  define safe_float_add(f, v) atomic_add_and_fetch_float(&(f), (v))
#else
#  define safe_float3_add(f, v) (f) += (v)
#  define safe_float_add(f, v) (f) += (v)
#endif /* _SPLIT_KERNEL_ */

#ifdef _PASSES_
  safe_float3_add(L.direct_diffuse, L_sample.direct_diffuse);
  safe_float3_add(L.direct_glossy, L_sample.direct_glossy);
  safe_float3_add(L.direct_transmission, L_sample.direct_transmission);
  #ifdef _VOLUME_
  safe_float3_add(L.direct_volume, L_sample.direct_volume);
  #endif

  safe_float3_add(L.indirect_diffuse, L_sample.indirect_diffuse);
  safe_float3_add(L.indirect_glossy, L_sample.indirect_glossy);
  safe_float3_add(L.indirect_transmission, L_sample.indirect_transmission);
    #ifdef _VOLUME_
  safe_float3_add(L.indirect_volume, L_sample.indirect_volume);
  #endif

  safe_float3_add(L.background, L_sample.background);
  safe_float3_add(L.ao, L_sample.ao);
  safe_float3_add(L.shadow, L_sample.shadow);
  safe_float_add(L.mist, L_sample.mist);
#endif /* _PASSES_ */
  safe_float3_add(L.emission, L_sample.emission);

#undef safe_float_add
#undef safe_float3_add
}

CCL_NAMESPACE_END
