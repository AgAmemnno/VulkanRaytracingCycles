#version 460
#extension GL_GOOGLE_include_directive : enable
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable

#define OMIT_NULL_SC
#define PUSH_POOL_SC
#define FLOAT3_AS_VEC3
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"

#include "kernel/payload.glsl"


//#define SVM_TYPE_SETUP
//#include "kernel/kernel_path.h.glsl"




#define NODE_Callee_BSDF
#define NODE_Callee
#include "kernel/svm/svm_callable.glsl"

#define DEF_BSDF SC(nio.alloc_offset)
#define GSD nio

#define  SVM_TYPE_SETUP
#include "kernel/closure/bsdf_util.h.glsl"



int closure_alloc(uint type, vec4 weight)
{
    if (nio.num_closure_left == 0)
    {
        return -1;
    }
    if (nio.num_closure < 63)
    {
        nio.alloc_offset++;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight = 0.0;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(0.0);
        for (int _i_ = 0; _i_ < 25; _i_++)
        {
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[_i_] = 0.0;
        }
        
    }
    else
    {
      /* limit */
    }

    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = type;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight = weight;
    nio.num_closure++;
    nio.num_closure_left--;
    return nio.alloc_offset;
}


int bsdf_alloc(uint size, vec3 weight)
{
    uint param   = 0u;
    vec4 param_1 = vec4(weight,0);
    int n = closure_alloc(param, param_1);
    if (n < 0)
    {
        return -1;
    }
    float sample_weight = abs(average(weight));
    push2.pool_ptr.pool_sc.data[n].sample_weight = sample_weight;
    return (sample_weight >= 9.9999997473787516355514526367188e-06) ? n : (-1);
}


#include "kernel/closure/bsdf_toon.h.glsl"
#include "kernel/closure/bsdf_diffuse.h.glsl"
#include "kernel/closure/bsdf_oren_nayar.h.glsl"
#include "kernel/closure/bsdf_transparent.h.glsl"
#include "kernel/closure/bsdf_ashikhmin_velvet.h.glsl"


#include "kernel/closure/bsdf_refraction.h.glsl"
#include "kernel/closure/bsdf_reflection.h.glsl"

#include "kernel/closure/bsdf_microfacet.h.glsl"
#include "kernel/closure/bsdf_microfacet_multi.h.glsl"
#include "kernel/closure/bsdf_ashikhmin_shirley.h.glsl"

#include "kernel/closure/bsdf_principled_diffuse.h.glsl"
#include "kernel/closure/bsdf_principled_sheen.h.glsl"
#include "kernel/closure/bssrdf.h.glsl"

#define _PRINCIPLED_ 

ccl_device void svm_node_glass_setup(int type, float eta, float roughness, bool refract)
{
  if (type == CLOSURE_BSDF_SHARP_GLASS_ID) {
    if (refract) {
      Microfacet_alpha_y(DEF_BSDF) = 0.0f;

      Microfacet_alpha_x(DEF_BSDF) = 0.0f;

      Microfacet_ior(DEF_BSDF) = eta;

      GSD.flag |= bsdf_refraction_setup();

    }
    else {
      Microfacet_alpha_y(DEF_BSDF) = 0.0f;

      Microfacet_alpha_x(DEF_BSDF) = 0.0f;

      Microfacet_ior(DEF_BSDF) = 0.0f;

      GSD.flag |= bsdf_reflection_setup();

    }
  }
  else if (type == CLOSURE_BSDF_MICROFACET_BECKMANN_GLASS_ID) {
    Microfacet_alpha_x(DEF_BSDF) = roughness;

    Microfacet_alpha_y(DEF_BSDF) = roughness;

    Microfacet_ior(DEF_BSDF) = eta;


    if (refract){
      GSD.flag |= bsdf_microfacet_beckmann_refraction_setup();
    }
    else
      GSD.flag |= bsdf_microfacet_beckmann_setup();

  }
  else {
    Microfacet_alpha_x(DEF_BSDF) = roughness;

    Microfacet_alpha_y(DEF_BSDF) = roughness;

    Microfacet_ior(DEF_BSDF) = eta;


    if (refract){
      GSD.flag |= bsdf_microfacet_ggx_refraction_setup();
    }
    else
      GSD.flag |= bsdf_microfacet_ggx_setup();
  }
}

int  rec_num;
void main(){
       bool caustics         =  bool((uint(nio.num_closure_left) >> 16u)&1);
       rec_num               =  int((nio.num_closure) >> 16u);
       bool raydiff          =  bool( uint(BSDF_PATH_FLAG) & PATH_RAY_DIFFUSE);
       nio.num_closure_left  =  int(uint(nio.num_closure_left) & 0xffff);
       nio.num_closure       =  int(uint(nio.num_closure) & 0xffff);

  switch (uint(nio.type)) {

#ifdef _PRINCIPLED_
    case CLOSURE_BSDF_PRINCIPLED_ID: {

       float  metallic       = nio.param1;
       float  subsurface     = nio.param2;
       float  m_cdlum_gray   = nio.base_color.w;
       float3 base_color     = nio.base_color.xyz;
      /* rotate tangent */
      if (nio.anisotropic_rotation != 0.0f)
        nio.T = rotate_around_axis(nio.T, nio.N, nio.anisotropic_rotation * M_2PI_F);

      /* calculate ior */
      float ior = bool(bool(nio.flag & SD_BACKFACING)) ? 1.0f / nio.eta : nio.eta;
      // calculate fresnel for refraction
      float cosNO   = dot3(nio.N, nio.I);
      float fresnel = fresnel_dielectric_cos(cosNO, ior);

      // calculate weights of the diffuse and specular part
      float diffuse_weight = (1.0f - saturate(metallic)) * (1.0f - saturate(nio.transmission));

      float final_transmission = saturate(nio.transmission) * (1.0f - saturate(metallic));
      float specular_weight    = (1.0f - final_transmission);


#  ifdef _SUBSURFACE_
      float3 mixed_ss_base_color = nio.subsurface_color * subsurface +
                                   base_color * (1.0f - subsurface);
      float3 subsurf_weight = nio.weight * mixed_ss_base_color * diffuse_weight;

      /* disable in_rsv case of diffuse ancestor, can't see it well then and
       * adds considerably noise due to probabilities of continuing path
       * getting lower and lower */
      if (bool(BSDF_PATH_FLAG & PATH_RAY_DIFFUSE_ANCESTOR)) {

        subsurface = 0.0f;

        /* need to set the base color in_rsv this case such that the
         * rays get the correctly mixed color after transmitting
         * the object */
        base_color = mixed_ss_base_color;
      }

      /* diffuse */
      if (fabsf(average(mixed_ss_base_color)) > CLOSURE_WEIGHT_CUTOFF) {
        if (subsurface <= CLOSURE_WEIGHT_CUTOFF && diffuse_weight > CLOSURE_WEIGHT_CUTOFF) {
          float3 diff_weight = nio.weight * base_color * diffuse_weight;
          int n = bsdf_alloc(sizeof_PrincipledDiffuseBsdf, diff_weight);
          if (n >= 0) {
            DEF_BSDF.N = vec4(nio.N,0);
            PrincipledDiffuse_roughness(DEF_BSDF) =  nio.roughness;
            /* setup bsdf */
            GSD.flag |= bsdf_principled_diffuse_setup();
          }
        }
        else if (subsurface > CLOSURE_WEIGHT_CUTOFF) {
          int n = bssrdf_alloc(subsurf_weight);

          if (n >= 0) {
            Bssrdf_radius_lval(DEF_BSDF) = nio.subsurface_radius * subsurface;
            Bssrdf_radius_assign(DEF_BSDF) 
            Bssrdf_albedo_lval(DEF_BSDF) = (nio.type_ssr == CLOSURE_BSSRDF_PRINCIPLED_ID) ? nio.subsurface_color : mixed_ss_base_color;
            Bssrdf_albedo_assign(DEF_BSDF)
            Bssrdf_texture_blur(DEF_BSDF) = 0.0f;
            Bssrdf_sharpness(DEF_BSDF) = 0.0f;
            DEF_BSDF.N = vec4(nio.N,0);
            Bssrdf_roughness(DEF_BSDF) = nio.roughness;

            /* setup bsdf */
            GSD.flag |= bssrdf_setup(nio.type_ssr);
          }
        }
      }
#  else
      if (diffuse_weight > CLOSURE_WEIGHT_CUTOFF) {
        float3 diff_weight = nio.weight * base_color * diffuse_weight;
        int n = bsdf_alloc(sizeof_PrincipledDiffuseBsdf, diff_weight);
        if (n >= 0) {
          DEF_BSDF.N = vec4(nio.N,0);
          PrincipledDiffuse_roughness(DEF_BSDF) =  nio.roughness;
          /* setup bsdf */
          GSD.flag |= bsdf_principled_diffuse_setup();
        }
      }
      /* diffuse */
#endif

      /* sheen */
      if (diffuse_weight > CLOSURE_WEIGHT_CUTOFF && nio.sheen > CLOSURE_WEIGHT_CUTOFF) {
        float m_cdlum  = m_cdlum_gray;
        float3 m_ctint = m_cdlum > 0.0f ?
                             base_color / m_cdlum :
                             make_float3(1.0f, 1.0f, 1.0f);  // normalize lum. to isolate hue+sat

        /* color of the sheen component */
        float3 sheen_color = make_float3(1.0f, 1.0f, 1.0f) * (1.0f - nio.sheen_tint) + m_ctint * nio.sheen_tint;
        float3 sheen_weight = nio.weight * nio.sheen * sheen_color * diffuse_weight;
        int n = bsdf_alloc(sizeof_PrincipledSheenBsdf, sheen_weight);
         if (n >= 0) {
          DEF_BSDF.N = vec4(nio.N,0);
          /* setup bsdf */
          GSD.flag |= bsdf_principled_sheen_setup();
        }
      }

      /* specular reflection */
#  ifdef _CAUSTICS_TRICKS_
      if (caustics|| !raydiff) {
#  endif
        if (specular_weight > CLOSURE_WEIGHT_CUTOFF &&
            (nio.specular > CLOSURE_WEIGHT_CUTOFF || metallic > CLOSURE_WEIGHT_CUTOFF)) {
          float3 spec_weight = nio.weight * specular_weight;

          int n = bsdf_alloc(sizeof_MicrofacetBsdf, spec_weight);
          if (n >= 0) {
            DEF_BSDF.N = vec4(nio.N,0);
            Microfacet_ior(DEF_BSDF) = (2.0f / (1.0f - safe_sqrtf(0.08f * nio.specular))) - 1.0f;
            Microfacet_T_lval(DEF_BSDF) =  nio.T; Microfacet_T_assign(DEF_BSDF) 
  /*sd.closure[n].extra = extra;*/
            float aspect = safe_sqrtf(1.0f - nio.anisotropic * 0.9f);
            float r2 = nio.roughness * nio.roughness;

            Microfacet_alpha_x(DEF_BSDF) = r2 / aspect;

            Microfacet_alpha_y(DEF_BSDF) = r2 * aspect;

            float m_cdlum = 0.3f * base_color.x + 0.6f * base_color.y +
                            0.1f * base_color.z;  // luminance approx.
            float3 m_ctint = m_cdlum > 0.0f ?
                                 base_color / m_cdlum :
                                 make_float3(
                                     0.0f, 0.0f, 0.0f);  // normalize lum. to isolate hue+sat
            float3 tmp_col = make_float3(1.0f, 1.0f, 1.0f) * (1.0f - nio.specular_tint) +
                             m_ctint * nio.specular_tint;

             Microfacet_cspec0_lval(DEF_BSDF) =  (nio.specular * 0.08f * tmp_col) * (1.0f - metallic) + base_color * metallic; 
             Microfacet_cspec0_assign(DEF_BSDF) 

             Microfacet_color_lval(DEF_BSDF) =  base_color; Microfacet_color_assign(DEF_BSDF) 
             Microfacet_clearcoat(DEF_BSDF) = 0.0f;

            /* setup bsdf */
            if (nio.type_dist == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID || nio.roughness <= 0.075f) /* use single-scatter GGX */
              GSD.flag |= bsdf_microfacet_ggx_fresnel_setup();
            else /* use multi-scatter GGX */
              GSD.flag |= bsdf_microfacet_multi_ggx_fresnel_setup();
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif

      /* BSDF */
#  ifdef _CAUSTICS_TRICKS_
      if (caustics || !raydiff)  {
#  endif
        if (final_transmission > CLOSURE_WEIGHT_CUTOFF) {
          float3 glass_weight = nio.weight * final_transmission;
          float3 cspec0 = base_color * nio.specular_tint +
                          make_float3(1.0f, 1.0f, 1.0f) * (1.0f - nio.specular_tint);

          if (nio.roughness <= 5e-2f ||
              nio.type_dist == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID) { /* use single-scatter GGX */
            float refl_roughness = nio.roughness;

            /* reflection */
#  ifdef _CAUSTICS_TRICKS_
            if(caustics) {
#  endif
            
              int n = bsdf_alloc(sizeof_MicrofacetBsdf, glass_weight * fresnel);
/*extra allocate elim*/
              if (n >= 0) {
                DEF_BSDF.N = vec4(nio.N,0);
                Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) 
      /*sd.closure[n].extra = extra;*/
                Microfacet_alpha_x(DEF_BSDF) = refl_roughness * refl_roughness;
                Microfacet_alpha_y(DEF_BSDF) = refl_roughness * refl_roughness;
                Microfacet_ior(DEF_BSDF) = ior;
                Microfacet_color_lval(DEF_BSDF) =  base_color; Microfacet_color_assign(DEF_BSDF) 
                Microfacet_cspec0_lval(DEF_BSDF) =  cspec0; Microfacet_cspec0_assign(DEF_BSDF) 
                Microfacet_clearcoat(DEF_BSDF) = 0.0f;
                /* setup bsdf */
                GSD.flag |= bsdf_microfacet_ggx_fresnel_setup();
              }
            }

            /* refraction */
#  ifdef _CAUSTICS_TRICKS_
            if (caustics) {
#  endif
              int n = bsdf_alloc(sizeof_MicrofacetBsdf, base_color * glass_weight * (1.0f - fresnel));

               if (n >= 0) {
                 DEF_BSDF.N = vec4(nio.N,0);
                 Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) Microfacet_extra_NULL(DEF_BSDF);
                if (nio.type_dist == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID)
                  nio.transmission_roughness = 1.0f - (1.0f - refl_roughness) *
                                                      (1.0f - nio.transmission_roughness);
                else
                  nio.transmission_roughness = refl_roughness;

                Microfacet_alpha_x(DEF_BSDF) = nio.transmission_roughness * nio.transmission_roughness;
                Microfacet_alpha_y(DEF_BSDF) = nio.transmission_roughness * nio.transmission_roughness;
                Microfacet_ior(DEF_BSDF) =  ior;
                /* setup bsdf */
                GSD.flag |= bsdf_microfacet_ggx_refraction_setup();
              }
            }
          }
          else { /* use multi-scatter GGX */
            int n = bsdf_alloc(sizeof_MicrofacetBsdf, glass_weight);
            if (n >= 0) {
               DEF_BSDF.N = vec4(nio.N,0);
    /*sd.closure[n].extra = extra;*/
              Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) 
              Microfacet_alpha_x(DEF_BSDF) = nio.roughness * nio.roughness;
              Microfacet_alpha_y(DEF_BSDF) = nio.roughness * nio.roughness;
              Microfacet_ior(DEF_BSDF) =  ior;
              Microfacet_color_lval(DEF_BSDF) =  base_color; Microfacet_color_assign(DEF_BSDF) 
              Microfacet_cspec0_lval(DEF_BSDF) =  cspec0; Microfacet_cspec0_assign(DEF_BSDF) 
              Microfacet_clearcoat(DEF_BSDF) = 0.0f;
              /* setup bsdf */
              GSD.flag |= bsdf_microfacet_multi_ggx_glass_fresnel_setup();    
            }
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif

      /* clearcoat */
#  ifdef _CAUSTICS_TRICKS_
      if (caustics || !raydiff)  {
#  endif
        if (nio.clearcoat > CLOSURE_WEIGHT_CUTOFF) {
          int n = bsdf_alloc(sizeof_MicrofacetBsdf, nio.weight);
          if (n >= 0) {
            DEF_BSDF.N = vec4(nio.clearcoat_normal,0);
            Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) 
            Microfacet_ior(DEF_BSDF) = 1.5f;
  /*sd.closure[n].extra = extra;*/
            Microfacet_alpha_x(DEF_BSDF) = nio.clearcoat_roughness * nio.clearcoat_roughness;
            Microfacet_alpha_y(DEF_BSDF) = nio.clearcoat_roughness * nio.clearcoat_roughness;
            Microfacet_color_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_color_assign(DEF_BSDF) 
            Microfacet_cspec0_lval(DEF_BSDF) =  make_float3(0.04f, 0.04f, 0.04f); Microfacet_cspec0_assign(DEF_BSDF) 
            Microfacet_clearcoat(DEF_BSDF) = nio.clearcoat;
            /* setup bsdf */
            GSD.flag |= bsdf_microfacet_ggx_clearcoat_setup();
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif
      break;
    }

#endif /* _PRINCIPLED_ */

    case CLOSURE_BSDF_DIFFUSE_ID: {

      int n = bsdf_alloc(sizeof_OrenNayarBsdf, nio.weight);
       if (n >= 0) {
        DEF_BSDF.N = vec4(nio.N,0);
        float roughness = nio.param1;

        if (roughness == 0.0f) {
          GSD.flag |= bsdf_diffuse_setup();
        }
        else {
          OrenNayar_roughness(DEF_BSDF) = roughness;
          GSD.flag |= bsdf_oren_nayar_setup();
        }
      }
      break;
    }
    case CLOSURE_BSDF_TRANSLUCENT_ID: {
      int n = bsdf_alloc(sizeof_OrenNayarBsdf, nio.weight);
      if (n >= 0) {
        DEF_BSDF.N = vec4(nio.N,0);
        GSD.flag |= bsdf_translucent_setup();

      }
      break;
    }
    case CLOSURE_BSDF_GLOSSY_TOON_ID:
    case CLOSURE_BSDF_DIFFUSE_TOON_ID: {
      int n = bsdf_alloc(sizeof_ToonBsdf, nio.weight);
       if (n >= 0) {
        DEF_BSDF.N = vec4(nio.N,0);
        Toon_size(DEF_BSDF) = nio.param1;
        Toon_smooth(DEF_BSDF) = nio.param2;
        if (nio.type == CLOSURE_BSDF_DIFFUSE_TOON_ID)
          GSD.flag |= bsdf_diffuse_toon_setup();
        else
          GSD.flag |= bsdf_glossy_toon_setup();
       }
        break;
    }
    case CLOSURE_BSDF_TRANSPARENT_ID: {
      bsdf_transparent_setup(nio.weight, uint(BSDF_PATH_FLAG));
      break;
    }
    case CLOSURE_BSDF_ASHIKHMIN_VELVET_ID: {
      int n = bsdf_alloc(sizeof_VelvetBsdf, nio.weight);
      if (n >= 0) {
        DEF_BSDF.N = vec4(nio.N,0);
        Velvet_sigma(DEF_BSDF) = saturate(nio.param1);
        GSD.flag |= bsdf_ashikhmin_velvet_setup();
      }
      break;
    }

    case CLOSURE_BSDF_REFRACTION_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID: {
      int n = bsdf_alloc(sizeof_MicrofacetBsdf, nio.weight);
       if (n >= 0) {
         DEF_BSDF.N = vec4(nio.N,0);
         Microfacet_T_lval( DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); 
         Microfacet_T_assign(DEF_BSDF) Microfacet_extra_NULL(DEF_BSDF);
         float eta = fmaxf(nio.param2, 1e-5f);
         eta = (bool(GSD.flag & SD_BACKFACING)) ? 1.0f / eta : eta;
        /* setup bsdf */
        if (nio.type == CLOSURE_BSDF_REFRACTION_ID) {
          Microfacet_alpha_x(DEF_BSDF) = 0.0f;
          Microfacet_alpha_y(DEF_BSDF) = 0.0f;
          Microfacet_ior(DEF_BSDF) = eta;
          GSD.flag |= bsdf_refraction_setup();
        }
        else {
          float roughness = sqr(nio.param1);
          Microfacet_alpha_x(DEF_BSDF) = roughness;
          Microfacet_alpha_y(DEF_BSDF) = roughness;
          Microfacet_ior(DEF_BSDF) = eta;
          if (nio.type == CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID)
            GSD.flag |= bsdf_microfacet_beckmann_refraction_setup();
          else
            GSD.flag |= bsdf_microfacet_ggx_refraction_setup();
        }
      }
      break;
    }
    case CLOSURE_BSDF_SHARP_GLASS_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_GLASS_ID: {
      /* index of refraction */
      float eta = fmaxf(nio.param2, 1e-5f);
      eta = (bool(GSD.flag & SD_BACKFACING)) ? 1.0f / eta : eta;
      /* fresnel */
      float cosNO = dot3(nio.N, GSD.I);
      float fresnel = fresnel_dielectric_cos(cosNO, eta);
      float roughness = sqr(nio.param1);
      /* reflection */
#ifdef _CAUSTICS_TRICKS_
      if (caustics || !(raydiff))
#endif
      {
        int n = bsdf_alloc(sizeof_MicrofacetBsdf, nio.weight * fresnel);
         if (n >= 0) {
          DEF_BSDF.N = vec4(nio.N,0);
          Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) Microfacet_extra_NULL(DEF_BSDF);
          svm_node_glass_setup( int(nio.type), float(eta), float(roughness), false);
        }
      }

      /* refraction */
#ifdef _CAUSTICS_TRICKS_
      if (caustics || !(raydiff))
#endif
      {
        int n = bsdf_alloc(sizeof_MicrofacetBsdf, nio.weight * (1.0f - fresnel));
        if (n >= 0) {
           DEF_BSDF.N = vec4(nio.N,0);
           Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) Microfacet_extra_NULL(DEF_BSDF);
           svm_node_glass_setup( int(nio.type), eta, roughness, true);
        }
      }
      break;
    }
    
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID: {
      int n = bsdf_alloc(sizeof_MicrofacetBsdf, nio.weight);
      if (n < 0) {break;}
      DEF_BSDF.N = vec4(nio.N,0);
      Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) 
      float roughness = sqr(nio.param1);
      Microfacet_alpha_x(DEF_BSDF) = roughness;
      Microfacet_alpha_y(DEF_BSDF) = roughness;
      float eta = fmaxf(nio.param2, 1e-5f);
      Microfacet_ior(DEF_BSDF) = (bool(GSD.flag & SD_BACKFACING)) ? 1.0f / eta : eta;
      Microfacet_color_lval(DEF_BSDF)  =  nio.base_color.xyz; Microfacet_color_assign(DEF_BSDF) 
      Microfacet_cspec0_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_cspec0_assign(DEF_BSDF);
      Microfacet_clearcoat(DEF_BSDF)   = 0.0f;
      /* setup bsdf */
      GSD.flag |= bsdf_microfacet_multi_ggx_glass_setup();
      break;
    }



    case CLOSURE_BSDF_REFLECTION_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_ID:
    case CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID:
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID: {
      int n = bsdf_alloc(sizeof_MicrofacetBsdf, nio.weight);
      if (n < 0) break;
      float roughness = sqr(nio.param1);
      DEF_BSDF.N = vec4(nio.N,0);

      Microfacet_ior(DEF_BSDF) = 0.0f;Microfacet_extra_NULL(DEF_BSDF);
      if (BSDF_DATA_NODE_Y == SVM_STACK_INVALID) {
        Microfacet_T_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(DEF_BSDF) 
        Microfacet_alpha_x(DEF_BSDF) = roughness;
        Microfacet_alpha_y(DEF_BSDF) = roughness;
      }
      else {
         Microfacet_T_lval(DEF_BSDF) =  nio.T; Microfacet_T_assign(DEF_BSDF) 
        /* rotate tangent */
        float rotation = BSDF_rotation;
        if (rotation != 0.0f)
           Microfacet_T_lval(DEF_BSDF) =  rotate_around_axis(Microfacet_T(DEF_BSDF), DEF_BSDF.N.xyz, rotation * M_2PI_F);
            Microfacet_T_assign(DEF_BSDF) 
        /* compute roughness */
        float anisotropy = clamp(nio.param2, -0.99f, 0.99f);
        if (anisotropy < 0.0f) {
          Microfacet_alpha_x(DEF_BSDF) = roughness / (1.0f + anisotropy);
          Microfacet_alpha_y(DEF_BSDF) = roughness * (1.0f + anisotropy);
        }
        else {
          Microfacet_alpha_x(DEF_BSDF) = roughness * (1.0f - anisotropy);
          Microfacet_alpha_y(DEF_BSDF) = roughness / (1.0f - anisotropy);
        }
      }

      /* setup bsdf */
      if (nio.type == CLOSURE_BSDF_REFLECTION_ID)
        GSD.flag |= bsdf_reflection_setup();

      else if (nio.type == CLOSURE_BSDF_MICROFACET_BECKMANN_ID)
        GSD.flag |= bsdf_microfacet_beckmann_setup();

      else if (nio.type == CLOSURE_BSDF_MICROFACET_GGX_ID)
        GSD.flag |= bsdf_microfacet_ggx_setup();
      else if (nio.type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID) {
          Microfacet_color_lval(DEF_BSDF) =  nio.base_color.xyz; Microfacet_color_assign(DEF_BSDF) 
          Microfacet_cspec0_lval(DEF_BSDF) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_cspec0_assign(DEF_BSDF) 
          Microfacet_clearcoat(DEF_BSDF) = 0.0f;
          GSD.flag |= bsdf_microfacet_multi_ggx_setup();
      }
      else {
        GSD.flag |= bsdf_ashikhmin_shirley_setup();
      }

      break;
    }

  
#ifdef _PRINCIPLED_ 

#ifdef _SUBSURFACE_
    case CLOSURE_BSSRDF_CUBIC_ID:
    case CLOSURE_BSSRDF_GAUSSIAN_ID:
    case CLOSURE_BSSRDF_BURLEY_ID:
    case CLOSURE_BSSRDF_RANDOM_WALK_ID: {
      int n = bssrdf_alloc(nio.weight);
      if (n >=0) {
        /* disable in_rsv case of diffuse ancestor, can't see it well then and
         * adds considerably noise due to probabilities of continuing path
         * getting lower and lower */
        if (bool( uint(BSDF_PATH_FLAG) & PATH_RAY_DIFFUSE_ANCESTOR)) nio.param1 = 0.0f;
        Bssrdf_radius_lval(DEF_BSDF)  = BSSRDF_RAD * nio.param1; Bssrdf_radius_assign(DEF_BSDF);
        Bssrdf_albedo_lval(DEF_BSDF)  = nio.weight/BSSRDF_MIX_W;Bssrdf_albedo_assign(DEF_BSDF);
        Bssrdf_texture_blur(DEF_BSDF) = nio.param2;
        Bssrdf_sharpness(DEF_BSDF)    = BSSRDF_SHARP;
        DEF_BSDF.N = vec4(nio.N,0);
        Bssrdf_roughness(DEF_BSDF) = 0.0f;
        GSD.flag |= bssrdf_setup(ClosureType(nio.type));

      }

      break;
    }
#endif

#ifdef _HAIR_
    case CLOSURE_BSDF_HAIR_PRINCIPLED_ID: {
      uint4 data_node2 = read_node(kg, offset);
      uint4 data_node3 = read_node(kg, offset);
      uint4 data_node4 = read_node(kg, offset);

      float3 weight = sd.svm_closure_weight * mix_weight;

      uint offset_ofs, ior_ofs, color_ofs, parametrization;
      svm_unpack_node_uchar4(data_node.y, (offset_ofs), (ior_ofs), (color_ofs), (parametrization));




      float alpha = stack_load_float_default(stack, offset_ofs, data_node.z);
      float ior = stack_load_float_default(stack, ior_ofs, data_node.w);

      uint coat_ofs, melanin_ofs, melanin_redness_ofs, absorption_coefficient_ofs;
      svm_unpack_node_uchar4(data_node2.x,
                             (coat_ofs),

                             (melanin_ofs),

                             (melanin_redness_ofs),

                             (absorption_coefficient_ofs));


      uint tint_ofs, random_ofs, random_color_ofs, random_roughness_ofs;
      svm_unpack_node_uchar4(
          data_node3.x, (tint_ofs), (random_ofs), (random_color_ofs), (random_roughness_ofs));





      const AttributeDescriptor attr_descr_random = find_attribute(kg, sd, data_node4.y);
      float random = 0.0f;
      if (attr_descr_random.offset != ATTR_STD_NOT_FOUND) {
        random = primitive_surface_attribute_float(kg, sd, attr_descr_random, NULL, NULL);
      }
      else {
        random = stack_load_float_default(stack, random_ofs, data_node3.y);
      }

      int n = bsdf_alloc(

          sd, sizeof_PrincipledHairBSDF, weight);

       if (n >= 0) {

  /*  PrincipledHairExtra */

        /* Random factors range: [-randomization/2, +randomization/2]. */
        float random_roughness = stack_load_float_default(
            stack, random_roughness_ofs, data_node3.w);
        float factor_random_roughness = 1.0f + 2.0f * (random - 0.5f) * random_roughness;
        float roughness = param1 * factor_random_roughness;
        float radial_roughness = param2 * factor_random_roughness;

        /* Remap Coat value to [0, 100]% of Roughness. */
        float coat = stack_load_float_default(stack, coat_ofs, data_node2.y);
        float m0_roughness = 1.0f - clamp(coat, 0.0f, 1.0f);

        sd.closure[n].N = N;

        sd.closure[n].v = roughness;

        sd.closure[n].s = radial_roughness;

        sd.closure[n].m0_roughness = m0_roughness;

        sd.closure[n].alpha = alpha;

        sd.closure[n].eta = ior;

  


        switch (parametrization) {
          case NODE_PRINCIPLED_HAIR_DIRECT_ABSORPTION: {
            float3 absorption_coefficient = stack_load_float3(stack, absorption_coefficient_ofs);
            PrincipledHair_sigma(sd.closure[n]) = absorption_coefficient;

            break;
          }
          case NODE_PRINCIPLED_HAIR_PIGMENT_CONCENTRATION: {
            float melanin = stack_load_float_default(stack, melanin_ofs, data_node2.z);
            float melanin_redness = stack_load_float_default(
                stack, melanin_redness_ofs, data_node2.w);

            /* Randomize melanin.  */
            float random_color = stack_load_float_default(stack, random_color_ofs, data_node3.z);
            random_color = clamp(random_color, 0.0f, 1.0f);
            float factor_random_color = 1.0f + 2.0f * (random - 0.5f) * random_color;
            melanin *= factor_random_color;

            /* Map melanin 0..inf from more perceptually linear 0..1. */
            melanin = -logf(fmaxf(1.0f - melanin, 0.0001f));

            /* Benedikt Bitterli's melanin ratio remapping. */
            float eumelanin = melanin * (1.0f - melanin_redness);
            float pheomelanin = melanin * melanin_redness;
            float3 melanin_sigma = bsdf_principled_hair_sigma_from_concentration(eumelanin,
                                                                                 pheomelanin);

            /* Optional tint. */
            float3 tint = stack_load_float3(stack, tint_ofs);
            float3 tint_sigma = bsdf_principled_hair_sigma_from_reflectance(tint,
                                                                            radial_roughness);

PrincipledHair_sigma(sd.closure[n]) = melanin_sigma + tint_sigma;

            break;
          }
          case NODE_PRINCIPLED_HAIR_REFLECTANCE: {
            float3 color = stack_load_float3(stack, color_ofs);
            PrincipledHair_sigma(sd.closure[n]) =  bsdf_principled_hair_sigma_from_reflectance(color, radial_roughness);

            break;
          }
          default: {
            /* Fallback to brownish hair, same as defaults for melanin. */
            kernel_assert(!"Invalid Principled Hair parametrization!");
           PrincipledHair_sigma(sd.closure[n])  = bsdf_principled_hair_sigma_from_concentration(0.0f, 0.8054375f);

            break;
          }
        }

        sd.flag |= bsdf_principled_hair_setup(sd,sd.closure[n]);
      }
      break;
    }
    case CLOSURE_BSDF_HAIR_REFLECTION_ID:
    case CLOSURE_BSDF_HAIR_TRANSMISSION_ID: {
      float3 weight = sd.svm_closure_weight * mix_weight;

      int n = bsdf_alloc(sd, sizeof_HairBsdf, weight);



       if (n >= 0) {

        sd.closure[n].N = N;

        sd.closure[n].roughness1 = param1;

        sd.closure[n].roughness2 = param2;

        sd.closure[n].offset = -stack_load_float( data_node.z);


        if (stack_valid(data_node.y)) {
           Microfacet_T_lval(sd.closure[n]) =  normalize(stack_load_float3(stack, data_node.y)); Microfacet_T_assign(sd.closure[n]) 


        }
        else if (!(bool(sd.type & PRIMITIVE_ALL_CURVE))) {

           Microfacet_T_lval(sd.closure[n]) =  normalize(sd.dPdv); Microfacet_T_assign(sd.closure[n]) 


          sd.closure[n].offset = 0.0f;

        }
        else
           Microfacet_T_lval(sd.closure[n]) =  normalize(sd.dPdu); Microfacet_T_assign(sd.closure[n]) 



        if (type == CLOSURE_BSDF_HAIR_REFLECTION_ID) {
          sd.flag |= bsdf_hair_reflection_setup(sd.closure[n]);

        }
        else {
          sd.flag |= bsdf_hair_transmission_setup(sd.closure[n]);

        }
      }

      break;
    }
#endif /* _HAIR_ */


#endif
    default:
      break;
  }
 memoryBarrierBuffer();
};