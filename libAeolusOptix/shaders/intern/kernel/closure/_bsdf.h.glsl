#ifndef _BSDF_AUX_H_
#define _BSDF_AUX_H_


CCL_NAMESPACE_BEGIN


#ifndef _BSDF_H_

#ifdef SVM_TYPE_SETUP

#ifndef Microfacet_alpha_x
#define Microfacet_alpha_x(bsdf) bsdf.data[0]
#define Microfacet_alpha_y(bsdf) bsdf.data[1]
#endif

#define  bsdf_microfacet_blur(next,roughness)\
{\
  Microfacet_alpha_x(_getSC(next)) = fmaxf(roughness, Microfacet_alpha_x(_getSC(next)));\
  Microfacet_alpha_y(_getSC(next)) = fmaxf(roughness, Microfacet_alpha_y(_getSC(next)));\
}



ccl_device void bsdf_blur(int it_next, float roughness)
{
  /* ToDo: do we want to blur volume closures? */
#ifdef _SVM_
  switch (_getSC(it_next).type) {
    //bsdf_microfacet_multi_ggx_blur
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID:
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_FRESNEL_ID:
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID:
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_FRESNEL_ID:
      bsdf_microfacet_blur(it_next,roughness);
      break;

    //bsdf_microfacet_ggx_blur 
    case CLOSURE_BSDF_MICROFACET_GGX_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_FRESNEL_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_CLEARCOAT_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID:
      bsdf_microfacet_blur(it_next,roughness);
      break;
    //bsdf_microfacet_beckmann_blur 
    case CLOSURE_BSDF_MICROFACET_BECKMANN_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID:
      bsdf_microfacet_blur(it_next,roughness);
      break; 
    case CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID:
      bsdf_microfacet_blur(it_next,roughness);
      break;
    /*  
    case CLOSURE_BSDF_HAIR_PRINCIPLED_ID:
      bsdf_principled_hair_blur(sc, roughness);
      break;
      */
    default:
      break;
  }

#endif


}


#endif

//#define SVM_TYPE_EVAL_SAMPLE 
#ifdef SVM_TYPE_EVAL_SAMPLE 
/* An additional term to smooth_rsv illumination on grazing angles when using bump mapping.
 * Based on "Taming the Shadow Terminator" by Matt Jen-Yuan Chiang,
 * Yining Karl Li and Brent Burley. */
ccl_device_inline float bump_shadowing_term(float3 Ng, float3 N, float3 I)
{
  float g = safe_divide(dot3(Ng, I), dot3(N, I) * dot3(Ng, N));

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

float3 bsdf_eval(
              const ShaderClosure sc,
              const float3 omega_in,
              inout float pdf)
{
  /* For curves use the smooth normal, particularly for ribbons the geometric
   * normal gives too much darkening otherwise. */
  const float3 Ng = (bool(PLYMO.sd.type & PRIMITIVE_ALL_CURVE)) ? PLYMO.sd.N : PLYMO.sd.Ng;
  float3 eval;

  uint lcg_state = PLYMO.sd.lcg_state;



  if (dot3(Ng, omega_in) >= 0.0f) {
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

#endif

#ifdef _PRINCIPLED_
      case CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID:
      case CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID:
        eval = bsdf_principled_diffuse_eval_reflect ARGS_EVAL2
        break;
      case CLOSURE_BSDF_PRINCIPLED_SHEEN_ID:
        eval = bsdf_principled_sheen_eval_reflect ARGS_EVAL2
        break;
#endif /* __PRINCIPLED__ */

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
      if (!isequal_float3(sc.N, PLYMO.sd.N)) {
        eval *= bump_shadowing_term(PLYMO.sd.N, sc.N, omega_in);
      }
    }
    /* Shadow terminator offset. */
    const float frequency_multiplier =
        kernel_tex_fetch(_objects, PLYMO.sd.object).shadow_terminator_offset;
    if (frequency_multiplier > 1.0f) {
      eval *= shift_cos_in(dot3(omega_in, sc.N), frequency_multiplier);
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
#endif

#ifdef _PRINCIPLED_
      case CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID:
      case CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID:
        eval = bsdf_principled_diffuse_eval_transmit  ARGS_EVAL2
        break;
      case CLOSURE_BSDF_PRINCIPLED_SHEEN_ID:
        eval = bsdf_principled_sheen_eval_transmit  ARGS_EVAL2
        break;
#endif /* __PRINCIPLED__ */

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
      if (!isequal_float3(sc.N, PLYMO.sd.N)) {
        eval *= bump_shadowing_term(-PLYMO.sd.N, sc.N, omega_in);
      }
    }
  }

/*
if(bool(PROFI_IDX)){
  atomicAdd(counter[PROFI_ATOMIC - 8 + 2*(PROFI_IDX - 1)],int(PLYMO.sd.lcg_state));
}
*/
  PLYMO.sd.lcg_state = lcg_state;
  memoryBarrier();

/*
      float prec = 1.f;
      vec3 v3 = prec* eval.xyz;
      PROFI_DATA_012(v3.x,v3.y,v3.z);
*/

  return eval;
}





#define ARGS_SAMPLE1                  (sc,\
                                       Ng,\
                                       PLYMO.sd.I,\
                                       PLYMO.sd.dI.dx,\
                                       PLYMO.sd.dI.dy,\
                                       randu,\
                                       randv,\
                                       eval,\
                                       omega_in,\
                                       domega_in.dx,\
                                       domega_in.dy,\
                                       pdf);
#define ARGS_SAMPLE2                  (\
                                       Ng,\
                                       PLYMO.sd.I,\
                                       PLYMO.sd.dI.dx,\
                                       PLYMO.sd.dI.dy,\
                                       randu,\
                                       randv,\
                                       eval,\
                                       omega_in,\
                                       domega_in.dx,\
                                       domega_in.dy,\
                                       pdf);
#define ARGS_SAMPLE3                  (\
                                       Ng,\
                                       PLYMO.sd.I,\
                                       PLYMO.sd.dI.dx,\
                                       PLYMO.sd.dI.dy,\
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
  const float3 Ng = (bool(PLYMO.sd.type & PRIMITIVE_ALL_CURVE)) ? sc.N : PLYMO.sd.Ng;
  uint lcg_state = PLYMO.sd.lcg_state;
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

#ifdef _PRINCIPLED_
    case CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID:
    case CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID:
      label = bsdf_principled_diffuse_sample ARGS_SAMPLE2
      break;
    case CLOSURE_BSDF_PRINCIPLED_SHEEN_ID:
      label = bsdf_principled_sheen_sample ARGS_SAMPLE2
      break;
#endif /* __PRINCIPLED__ */

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
        kernel_tex_fetch(_objects, PLYMO.sd.object).shadow_terminator_offset;
    if (frequency_multiplier > 1.0f) {
      eval *= shift_cos_in(dot3(PLYMO.omega_in, sc.N), frequency_multiplier);
    }
    if (bool(label & LABEL_DIFFUSE)) {
      if (!isequal_float3(sc.N, PLYMO.sd.N)) {
        eval *= bump_shadowing_term((bool(label & LABEL_TRANSMIT)) ? -PLYMO.sd.N : PLYMO.sd.N, sc.N, omega_in);
      }
    }
  }


  PLYMO.sd.lcg_state =  lcg_state;
  memoryBarrier();


  return label;
}


#endif



#endif
CCL_NAMESPACE_END

#endif /* _BSDF__H_ */