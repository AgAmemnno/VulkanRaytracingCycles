#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable
#define PUSH_POOL_SC
#define PUSH_KERNEL_TEX
#define SET_KERNEL 2
#define PLYMO arg
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#include "kernel/kernel_globals.h.glsl"

#include "util/util_math_func.glsl"
#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_montecarlo.h.glsl"
#define _getSC(idx) SC(idx)
ShaderClosure sc;
#define DEF_BSDF sc

#include "kernel/closure/bsdf_util.h.glsl"

#include "kernel/closure/bsdf_microfacet.h.glsl"
#include "kernel/closure/bsdf_refraction.h.glsl"
#include "kernel/closure/bsdf_reflection.h.glsl"
#include "kernel/closure/bsdf_microfacet_multi.h.glsl"
#include "kernel/closure/bsdf_ashikhmin_shirley.h.glsl"


#include "kernel/closure/bsdf_diffuse.h.glsl"
#include "kernel/closure/bsdf_oren_nayar.h.glsl"
#include "kernel/closure/bsdf_toon.h.glsl"
#include "kernel/closure/bsdf_transparent.h.glsl"
#include "kernel/closure/bsdf_ashikhmin_velvet.h.glsl"





struct PLMO_SD_EVAL
{
args_sd    sd;   // 140
BsdfEval eval;   // 80

vec4 omega_in;    
differential3 domega_in; 

int      label;
int      use_light_pass;
int      type;
float    pdf;
};
// 140 + 80 + 52 = 272





layout(location = 0) callableDataInNV PLMO_SD_EVAL arg;
layout(location = 1) callableDataInNV PLMO_SD_EVAL arg2;


ccl_device_inline void bsdf_eval_init(
                                      ClosureType type,
                                      float3 value
                                      )
{
#ifdef _PASSES_
  PLYMO.use_light_pass =  kernel_data.film.use_light_pass;

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







///#include "kernel/closure/bsdf.h.glsl"
/* An additional term to smooth_rsv illumination on grazing angles when using bump mapping.
 * Based on "Taming the Shadow Terminator" by Matt Jen-Yuan Chiang,
 * Yining Karl Li and Brent Burley. */
ccl_device_inline float bump_shadowing_term(float3 Ng, float3 N, float3 I)
{
  float g = safe_divide(dot(Ng, I), dot(N, I) * dot(Ng, N));

  /* If the incoming light is on the unshadowed side, return full brightness. */
  if (g >= 1.0f) {
    return 1.0f;
  }

  /* If the incoming light points away from the surface, return black. */
  if (g < 0.0f) {
    return 0.0f;
  }

  /* Return smoothed value to avoid discontinuity at perpendicular angle. */
  float g2 = sqr(g);
  return -g2 * g + g2 + g;
}
/* Shadow terminator workaround, taken from Appleseed.
 * Original code is under the MIT License
 * Copyright (c) 2019 Francois Beaune, The appleseedhq Organization */
ccl_device_inline float shift_cos_in(float cos_in, const float frequency_multiplier)
{
  cos_in = min(cos_in, 1.0f);

  const float angle = fast_acosf(cos_in);
  const float val = max(cosf(angle * frequency_multiplier), 0.0f) / cos_in;
  return val;
}
ccl_device_inline float bsdf_get_specular_roughness_squared(in ShaderClosure sc)
{
  if (CLOSURE_IS_BSDF_SINGULAR(sc.type)) {
    return 0.0f;
  }

  if (CLOSURE_IS_BSDF_MICROFACET(sc.type)) {
    return Microfacet_alpha_x(sc) * Microfacet_alpha_y(sc);
  }

  return 1.0f;
}










/*Shared Arguments Parse Difinitions */
#define ply_state_flag floatBitsToInt(arg.eval.diffuse.x)
#define ply_call_flag floatBitsToInt(arg.eval.diffuse.z)
#define ply_use_mis floatBitsToInt(arg.eval.diffuse.y)
#define ply_rng_u arg.eval.diffuse.x
#define ply_rng_v arg.eval.diffuse.y
#define ARGS_shader_bsdf_eval \
bool use_mis          = bool(ply_use_mis);\
const float3 omega_in = arg.omega_in;\
float light_pdf       = arg.pdf;





#define ARGS_EVAL1 (sc, arg.sd.I, omega_in, pdf);
#define ARGS_EVAL2 (arg.sd.I, omega_in, pdf);
#define ARGS_EVAL3 (arg.sd.I, omega_in, pdf,lcg_state);

ccl_device_inline
float3
    bsdf_eval(
              const ShaderClosure sc,
              const float3 omega_in,
              inout float pdf)
{
  /* For curves use the smooth normal, particularly for ribbons the geometric
   * normal gives too much darkening otherwise. */
  const float3 Ng = (bool(arg.sd.type & PRIMITIVE_ALL_CURVE)) ? arg.sd.N : arg.sd.Ng;
  float3 eval;
  

  uint lcg_state = arg.sd.lcg_state;
/*
if(bool(PROFI_IDX)){
  atomicAdd(counter[PROFI_ATOMIC - 9 + 2*(PROFI_IDX - 1)],int(arg.sd.lcg_state));
}
*/


  if (dot(Ng, omega_in) >= 0.0f) {
    switch (sc.type) {
      case CLOSURE_BSDF_DIFFUSE_ID:
      case CLOSURE_BSDF_BSSRDF_ID:
        eval = bsdf_diffuse_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_OREN_NAYAR_ID:
        eval = bsdf_oren_nayar_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_DIFFUSE_TOON_ID:
        eval = bsdf_diffuse_toon_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_GLOSSY_TOON_ID:
        eval = bsdf_glossy_toon_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_TRANSLUCENT_ID:
        eval = bsdf_translucent_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_REFRACTION_ID:
        eval = bsdf_refraction_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_TRANSPARENT_ID:
        eval = bsdf_transparent_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_ASHIKHMIN_VELVET_ID:
        eval = bsdf_ashikhmin_velvet_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_MICROFACET_GGX_ID:
      case CLOSURE_BSDF_MICROFACET_GGX_FRESNEL_ID:
      case CLOSURE_BSDF_MICROFACET_GGX_CLEARCOAT_ID:
      case CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID:
        eval = bsdf_microfacet_ggx_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_MICROFACET_BECKMANN_ID:
      case CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID:
        eval = bsdf_microfacet_beckmann_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_REFLECTION_ID:
        eval = bsdf_reflection_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID:
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_FRESNEL_ID:
        eval = bsdf_microfacet_multi_ggx_eval_reflect ARGS_EVAL3 
        break;
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID:
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_FRESNEL_ID:
        eval = bsdf_microfacet_multi_ggx_glass_eval_reflect ARGS_EVAL3
        //atomicAdd(counter[PROFI_ATOMIC - 30], int(1000.f*eval.x)); 
        break;
      case CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID:
        eval = bsdf_ashikhmin_shirley_eval_reflect ARGS_EVAL2
        break;
#ifdef __SVM_

      case CLOSURE_BSDF_HAIR_PRINCIPLED_ID:
        eval = bsdf_principled_hair_eval(kg, sd, sc, omega_in, pdf);
        break;
      case CLOSURE_BSDF_HAIR_REFLECTION_ID:
        eval = bsdf_hair_reflection_eval_reflect(sc, sd->I, omega_in, pdf);
        break;
      case CLOSURE_BSDF_HAIR_TRANSMISSION_ID:
        eval = bsdf_hair_transmission_eval_reflect(sc, sd->I, omega_in, pdf);
        break;
#  ifdef __PRINCIPLED__
      case CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID:
      case CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID:
        eval = bsdf_principled_diffuse_eval_reflect(sc, sd->I, omega_in, pdf);
        break;
      case CLOSURE_BSDF_PRINCIPLED_SHEEN_ID:
        eval = bsdf_principled_sheen_eval_reflect(sc, sd->I, omega_in, pdf);
        break;
#  endif /* __PRINCIPLED__ */
#endif
#ifdef _VOLUME_
      case CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID:
        eval = volume_henyey_greenstein_eval_phase(sc, sd->I, omega_in, pdf);
        break;
#endif
      default:
        eval = make_float3(0.0f, 0.0f, 0.0f);
        break;
    }
    if (CLOSURE_IS_BSDF_DIFFUSE(sc.type)) {
      if (!isequal_float3(sc.N, arg.sd.N)) {
        eval *= bump_shadowing_term(arg.sd.N, sc.N, omega_in);
      }
    }
    /* Shadow terminator offset. */
    const float frequency_multiplier =
        kernel_tex_fetch(_objects, arg.sd.object).shadow_terminator_offset;
    if (frequency_multiplier > 1.0f) {
      eval *= shift_cos_in(dot(omega_in, sc.N), frequency_multiplier);
    }
  }
  else {
    switch (sc.type) {
      case CLOSURE_BSDF_DIFFUSE_ID:
      case CLOSURE_BSDF_BSSRDF_ID:
        eval = bsdf_diffuse_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_OREN_NAYAR_ID:
        eval = bsdf_oren_nayar_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_DIFFUSE_TOON_ID:
        eval = bsdf_diffuse_toon_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_GLOSSY_TOON_ID:
        eval = bsdf_glossy_toon_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_TRANSLUCENT_ID:
        eval = bsdf_translucent_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_TRANSPARENT_ID:
        eval = bsdf_transparent_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_ASHIKHMIN_VELVET_ID:
        eval = bsdf_ashikhmin_velvet_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_REFRACTION_ID:
        eval = bsdf_refraction_eval_transmit ARGS_EVAL2

        break;
      case CLOSURE_BSDF_MICROFACET_GGX_ID:
      case CLOSURE_BSDF_MICROFACET_GGX_FRESNEL_ID:
      case CLOSURE_BSDF_MICROFACET_GGX_CLEARCOAT_ID:
      case CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID:
        eval = bsdf_microfacet_ggx_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_MICROFACET_BECKMANN_ID:
      case CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID:
        eval = bsdf_microfacet_beckmann_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_REFLECTION_ID:
        eval = bsdf_reflection_eval_transmit ARGS_EVAL2
        break;
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID:
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_FRESNEL_ID:
        eval = bsdf_microfacet_multi_ggx_eval_transmit ARGS_EVAL3
        break;
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID:
      case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_FRESNEL_ID:
        eval = bsdf_microfacet_multi_ggx_glass_eval_transmit ARGS_EVAL3
        // atomicAdd(counter[PROFI_ATOMIC - 29], int(1000.f*eval.x)); 
        break;
      case CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID:
        eval = bsdf_ashikhmin_shirley_eval_transmit ARGS_EVAL2
        break;
#ifdef __SVM_

      case CLOSURE_BSDF_HAIR_PRINCIPLED_ID:
        eval = bsdf_principled_hair_eval(kg, sd, sc, omega_in, pdf);
        break;
      case CLOSURE_BSDF_HAIR_REFLECTION_ID:
        eval = bsdf_hair_reflection_eval_transmit(sc, sd->I, omega_in, pdf);
        break;
      case CLOSURE_BSDF_HAIR_TRANSMISSION_ID:
        eval = bsdf_hair_transmission_eval_transmit(sc, sd->I, omega_in, pdf);
        break;
#ifdef __PRINCIPLED__
      case CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID:
      case CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID:
        eval = bsdf_principled_diffuse_eval_transmit(sc, sd->I, omega_in, pdf);
        break;
      case CLOSURE_BSDF_PRINCIPLED_SHEEN_ID:
        eval = bsdf_principled_sheen_eval_transmit(sc, sd->I, omega_in, pdf);
        break;
#endif /* __PRINCIPLED__ */

#endif
#ifdef _VOLUME_
      case CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID:
        eval = volume_henyey_greenstein_eval_phase(sc, sd->I, omega_in, pdf);
        break;
#endif
      default:
        eval = make_float3(0.0f, 0.0f, 0.0f);
        break;
    }
    if (CLOSURE_IS_BSDF_DIFFUSE(sc.type)) {
      if (!isequal_float3(sc.N, arg.sd.N)) {
        eval *= bump_shadowing_term(-arg.sd.N, sc.N, omega_in);
      }
    }
  }

/*
if(bool(PROFI_IDX)){
  atomicAdd(counter[PROFI_ATOMIC - 8 + 2*(PROFI_IDX - 1)],int(arg.sd.lcg_state));
}
*/
  arg.sd.lcg_state = lcg_state;
  memoryBarrier();

/*
      float prec = 1.f;
      vec3 v3 = prec* eval.xyz;
      PROFI_DATA_012(v3.x,v3.y,v3.z);
*/





  return eval;
}


#ifdef _BRANCHED_PATH_
ccl_device_inline void _shader_bsdf_multi_eval_branched(
                                                        const float3 omega_in,
                                                        float light_pdf,
                                                        bool use_mis)
{
  int it_next = arg.sd.alloc_offset;
  for (int i = 0; i < arg.sd.num_closure; i++) {
    sc  = _getSC(it_next);
    if (CLOSURE_IS_BSDF(sc.type)) {
      float bsdf_pdf = 0.0f;
      float3 b_eval = bsdf_eval(sc, omega_in, bsdf_pdf);
      if (bsdf_pdf != 0.0f) {
        float mis_weight = use_mis ? power_heuristic(light_pdf, bsdf_pdf) : 1.0f;
        bsdf_eval_accum(sc.type, b_eval * sc.weight, mis_weight);
      }
    }
    it_next = sc.next;
  }
}
#endif /* __BRANCHED_PATH__ */


ccl_device_inline void _shader_bsdf_multi_eval(
                                               const float3 omega_in,
                                               inout float pdf,
                                               const int skip_sc,
                                               float sum_pdf,
                                               float sum_sample_weight)
{
  /* this is the veach one-sample model with balance heuristic, some pdf
   * factors drop out when using balance heuristic weighting */

  int it_next = arg.sd.alloc_offset;

  for (int i = 0; i < arg.sd.num_closure; i++) {
    sc = _getSC(it_next);
    if (it_next != skip_sc && CLOSURE_IS_BSDF( sc.type) ) {
          float bsdf_pdf = 0.0f;
          float3 eval = bsdf_eval(sc, omega_in, bsdf_pdf);
          if (bsdf_pdf != 0.0f) {
            bsdf_eval_accum(sc.type, eval * sc.weight, 1.0f);
            sum_pdf += bsdf_pdf * sc.sample_weight;
          }
          sum_sample_weight += sc.sample_weight;    
    }
    it_next = sc.next;
  }
  pdf = (sum_sample_weight > 0.0f) ? sum_pdf / sum_sample_weight : 0.0f;

}

void shader_bsdf_eval()
{

ARGS_shader_bsdf_eval

bsdf_eval_init(NBUILTIN_CLOSURES, make_float3(0.0f, 0.0f, 0.0f));


#ifdef _BRANCHED_PATH_
  if (bool(kernel_data.integrator.branched))
    _shader_bsdf_multi_eval_branched(omega_in,light_pdf, use_mis);
  else
#endif
  {
    float pdf;
    _shader_bsdf_multi_eval(omega_in, pdf, -1, 0.0f, 0.0f);

    if (use_mis) {
      float weight = power_heuristic(light_pdf, pdf);
      bsdf_eval_mis(weight);
    }
  }

}

#define ARGS_SAMPLE1                  (sc,\
                                       Ng,\
                                       arg.sd.I,\
                                       arg.sd.dI.dx,\
                                       arg.sd.dI.dy,\
                                       randu,\
                                       randv,\
                                       eval,\
                                       omega_in,\
                                       domega_in.dx,\
                                       domega_in.dy,\
                                       pdf);
#define ARGS_SAMPLE2                  (\
                                       Ng,\
                                       arg.sd.I,\
                                       arg.sd.dI.dx,\
                                       arg.sd.dI.dy,\
                                       randu,\
                                       randv,\
                                       eval,\
                                       omega_in,\
                                       domega_in.dx,\
                                       domega_in.dy,\
                                       pdf);
#define ARGS_SAMPLE3                  (\
                                       Ng,\
                                       arg.sd.I,\
                                       arg.sd.dI.dx,\
                                       arg.sd.dI.dy,\
                                       randu,\
                                       randv,\
                                       eval,\
                                       omega_in,\
                                       domega_in.dx,\
                                       domega_in.dy,\
                                       pdf,\
                                       lcg_state);

ccl_device_inline int bsdf_sample(
                                  float randu,
                                  float randv,
                                  inout float3 eval,
                                  inout float3 omega_in,
                                  inout differential3 domega_in,
                                  inout float pdf
                                )
{
  /* For curves use the smooth normal, particularly for ribbons the geometric
   * normal gives too much darkening otherwise. */

  int label;
  const float3 Ng = (bool(arg.sd.type & PRIMITIVE_ALL_CURVE)) ? sc.N : arg.sd.Ng;
  uint lcg_state = arg.sd.lcg_state;


  switch (sc.type) {
    case CLOSURE_BSDF_DIFFUSE_ID:
    case CLOSURE_BSDF_BSSRDF_ID:
      label = bsdf_diffuse_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_OREN_NAYAR_ID:
      label = bsdf_oren_nayar_sample ARGS_SAMPLE2
      break;
     case CLOSURE_BSDF_DIFFUSE_TOON_ID:
      label = bsdf_diffuse_toon_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_GLOSSY_TOON_ID:
      label = bsdf_glossy_toon_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_TRANSLUCENT_ID:
      label = bsdf_translucent_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_TRANSPARENT_ID:
      label = bsdf_transparent_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_ASHIKHMIN_VELVET_ID:
      label = bsdf_ashikhmin_velvet_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_REFRACTION_ID:
      label = bsdf_refraction_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_MICROFACET_GGX_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_FRESNEL_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_CLEARCOAT_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID:
      label = bsdf_microfacet_ggx_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_MICROFACET_BECKMANN_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID:
      label = bsdf_microfacet_beckmann_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_REFLECTION_ID:
      label = bsdf_reflection_sample  ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID:
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_FRESNEL_ID:
      label = bsdf_microfacet_multi_ggx_sample ARGS_SAMPLE3
      break;
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID:
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_FRESNEL_ID:
      label = bsdf_microfacet_multi_ggx_glass_sample  ARGS_SAMPLE3
      break;
    case CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID:
      label = bsdf_ashikhmin_shirley_sample  ARGS_SAMPLE2
      break;

#ifdef __SVM_






    case CLOSURE_BSDF_HAIR_REFLECTION_ID:
      label = bsdf_hair_reflection_sample(sc,
                                          Ng,
                                          sd->I,
                                          sd->dI.dx,
                                          sd->dI.dy,
                                          randu,
                                          randv,
                                          eval,
                                          omega_in,
                                          &domega_in->dx,
                                          &domega_in->dy,
                                          pdf);
      break;
    case CLOSURE_BSDF_HAIR_TRANSMISSION_ID:
      label = bsdf_hair_transmission_sample(sc,
                                            Ng,
                                            sd->I,
                                            sd->dI.dx,
                                            sd->dI.dy,
                                            randu,
                                            randv,
                                            eval,
                                            omega_in,
                                            &domega_in->dx,
                                            &domega_in->dy,
                                            pdf);
      break;
    case CLOSURE_BSDF_HAIR_PRINCIPLED_ID:
      label = bsdf_principled_hair_sample(
          kg, sc, sd, randu, randv, eval, omega_in, &domega_in->dx, &domega_in->dy, pdf);
      break;
#  ifdef _PRINCIPLED_
    case CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID:
    case CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID:
      label = bsdf_principled_diffuse_sample(sc,
                                             Ng,
                                             sd->I,
                                             sd->dI.dx,
                                             sd->dI.dy,
                                             randu,
                                             randv,
                                             eval,
                                             omega_in,
                                             &domega_in->dx,
                                             &domega_in->dy,
                                             pdf);
      break;
    case CLOSURE_BSDF_PRINCIPLED_SHEEN_ID:
      label = bsdf_principled_sheen_sample(sc,
                                           Ng,
                                           sd->I,
                                           sd->dI.dx,
                                           sd->dI.dy,
                                           randu,
                                           randv,
                                           eval,
                                           omega_in,
                                           &domega_in->dx,
                                           &domega_in->dy,
                                           pdf);
      break;
#  endif /* __PRINCIPLED__ */
#endif
#ifdef _VOLUME_
    case CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID:
      label = volume_henyey_greenstein_sample(sc,
                                              sd->I,
                                              sd->dI.dx,
                                              sd->dI.dy,
                                              randu,
                                              randv,
                                              eval,
                                              omega_in,
                                              &domega_in->dx,
                                              &domega_in->dy,
                                              pdf);
      break;
#endif
    default:
      label = int(LABEL_NONE);
      break;
  }

  /* Test if BSDF sample should be treated as transparent for background. */
  if (bool(label & LABEL_TRANSMIT)){
    float threshold_squared = kernel_data.background.transparent_roughness_squared_threshold;

    if (threshold_squared >= 0.0f) {
      if (bsdf_get_specular_roughness_squared(sc) <= threshold_squared) {
        label |= int(LABEL_TRANSMIT_TRANSPARENT);
      }
    }
  }
  else {
    /* Shadow terminator offset. */
    const float frequency_multiplier =
        kernel_tex_fetch(_objects, arg.sd.object).shadow_terminator_offset;
    if (frequency_multiplier > 1.0f) {
      eval *= shift_cos_in(dot(arg.omega_in, sc.N), frequency_multiplier);
    }
    if (bool(label & LABEL_DIFFUSE)) {
      if (!isequal_float3(sc.N, arg.sd.N)) {
        eval *= bump_shadowing_term((bool(label & LABEL_TRANSMIT)) ? -arg.sd.N : arg.sd.N, sc.N, omega_in);
      }
    }
  }


  arg.sd.lcg_state =  lcg_state;
  memoryBarrier();
/*
if(PROFI_IDX == 0){
      float prec = 1000.f;
      int v = int(arg.sd.lcg_state & uint(0xFFFF));
      atomicAdd(counter[PROFI_ATOMIC - 30], int(v));
      atomicAdd(counter[PROFI_ATOMIC - 29], int(1));
}
*/

  return label;
}



 int shader_bsdf_pick(inout float randu)
{
  /* Note the sampling here must match shader_bssrdf_pick,
   * since we reuse the same random number. */
  int sampled = arg.sd.atomic_offset;
 

  if (arg.sd.num_closure > 1) {
    //int list[32];
    /* Pick a BSDF or based on sample weights. */
    float sum = 0.0f;
    int next = sampled;
    
    for (int i = 0; i < arg.sd.num_closure; i++) {
      //list[arg.sd.num_closure-1-i] = next;
      if (CLOSURE_IS_BSDF_OR_BSSRDF(_getSC(next).type)) {
        sum += _getSC(next).sample_weight;
      }
      //next = _getSC(next).next;
      next++;
    }

    float r = (randu) * sum;
    float partial_sum = 0.0f;
    sampled = arg.sd.atomic_offset;
    for (int i = 0; i < arg.sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(_getSC( (sampled+i) ).type)) {
        float next_sum = partial_sum + _getSC( (sampled+i) ).sample_weight;
        if (r < next_sum) {
          sampled =  (sampled+i) ;
          /* Rescale to reuse for direction sample, to better preserve stratification. */
          randu = (r - partial_sum) / _getSC(sampled).sample_weight;
          break;
        }
        partial_sum = next_sum;
      }
    }

 }
  
  

  return CLOSURE_IS_BSDF( _getSC(sampled).type) ? sampled : -1;
}

int shader_bsdf_sample(float randu,
                      float randv,
                      inout float3 omega_in,
                      inout differential3 domega_in,
                      inout float pdf)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_SAMPLE);

  const int sampled = shader_bsdf_pick(randu);

  if (sampled < 0) {
    pdf = 0.0f;
    return int(LABEL_NONE);
  }



  sc = _getSC(sampled); 

  /* BSSRDF should already have been handled elsewhere. */

  kernel_assert("assert rcall3 871 ",CLOSURE_IS_BSDF(_getSC(sampled).type))

  int label;
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);


  pdf = 0.0f; 
  label = int(bsdf_sample(randu, randv,eval,omega_in,domega_in,pdf));


  if (pdf != 0.0f) {

/*
if(PROFI_IDX == 0){
      float prec = 1000.f;
      int v = int(arg.sd.lcg_state & uint(0xFFFF));
      float3 V3 = prec* eval;// ray.dP.dx;////
      atomicAdd(counter[PROFI_ATOMIC - 32],int(v));
      atomicAdd(counter[PROFI_ATOMIC - 31],int(V3.y));
      atomicAdd(counter[PROFI_ATOMIC - 30],int(V3.z));
}
*/


    bsdf_eval_init(sc.type, eval * sc.weight);

    if (arg.sd.num_closure > 1) {
      float sweight = sc.sample_weight;
      _shader_bsdf_multi_eval( omega_in, pdf,sampled, pdf * sweight, sweight);
    }
   
  }

  
  return label;
}



void main(){

#ifdef ENABLE_PROFI
PROFI_IDX =  int(arg.label);

#endif



if(BSDF_CALL_TYPE_EVAL == int(arg.type) ){
   int callFlag  = ply_call_flag;
   if(callFlag == 1234){
       arg = arg2;
   }

atomicAdd(counter[PROFI_ATOMIC - 11],bool(PROFI_IDX) ? 1 : 0 );

   int state_flag = ply_state_flag;
   shader_bsdf_eval();


}else if(BSDF_CALL_TYPE_SAMPLE == int(arg.type) ){


   float bsdf_u = ply_rng_u;
   float bsdf_v = ply_rng_v;
   float3 omega_in;
   differential3 domega_in;
   float pdf;
   arg.label     = shader_bsdf_sample(bsdf_u, bsdf_v,omega_in,domega_in,pdf);
   arg.omega_in  = omega_in;
   arg.domega_in = domega_in;
   arg.pdf = pdf;
/*
      if(PROFI_IDX == 0){
        float prec = 1000.f;
        float3 v = prec * PLYMO.eval.diffuse;//  arg.omega_in;
        int gN   = PROFI_IDX;
        atomicAdd(counter[PROFI_ATOMIC - 20 + gN + 2],int(v.x)); 
        atomicAdd(counter[PROFI_ATOMIC - 20 + gN + 3],int(v.y)); 
        atomicAdd(counter[PROFI_ATOMIC - 20 + gN + 4],int(v.z)); 
        atomicAdd(counter[PROFI_ATOMIC - 20 + gN + 5],int(prec*arg.pdf)); 
      }
*/
}


}
