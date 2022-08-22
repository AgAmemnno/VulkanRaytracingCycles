#ifndef _SVM_CLOSURE_H_
#define _SVM_CLOSURE_H_
/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in_rsv compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in_rsv writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


CCL_NAMESPACE_BEGIN

/*
typedef ccl_addr_space struct MicrofacetExtra {
  float3 color;
  float3 cspec0;
  float3 fresnel_color;
  float clearcoat;
} MicrofacetExtra;

typedef ccl_addr_space struct MicrofacetBsdf {
  SHADER_CLOSURE_BASE;

  float alpha_x;
  float alpha_y;
  float  ior;
  MicrofacetExtra *extra;
  float3 T;
} MicrofacetBsdf;
*/

/* Closure Nodes */
#define NODE_Caller

#ifdef NODE_Caller 
ccl_device void svm_node_glass_setup(int type, float eta, float roughness, bool refract)
{
  if (type == CLOSURE_BSDF_SHARP_GLASS_ID) {
    if (refract) {
      Microfacet_alpha_y(DEF_BSDF) = 0.0f;

      Microfacet_alpha_x(DEF_BSDF) = 0.0f;

      Microfacet_ior(DEF_BSDF) = eta;

      sd.flag |= bsdf_refraction_setup();

    }
    else {
      Microfacet_alpha_y(DEF_BSDF) = 0.0f;

      Microfacet_alpha_x(DEF_BSDF) = 0.0f;

      Microfacet_ior(DEF_BSDF) = 0.0f;

      sd.flag |= bsdf_reflection_setup();

    }
  }
  else if (type == CLOSURE_BSDF_MICROFACET_BECKMANN_GLASS_ID) {
    Microfacet_alpha_x(DEF_BSDF) = roughness;

    Microfacet_alpha_y(DEF_BSDF) = roughness;

    Microfacet_ior(DEF_BSDF) = eta;


    if (refract){
      sd.flag |= bsdf_microfacet_beckmann_refraction_setup();
    }
    else
      sd.flag |= bsdf_microfacet_beckmann_setup();

  }
  else {
    Microfacet_alpha_x(DEF_BSDF) = roughness;

    Microfacet_alpha_y(DEF_BSDF) = roughness;

    Microfacet_ior(DEF_BSDF) = eta;


    if (refract){
      sd.flag |= bsdf_microfacet_ggx_refraction_setup();
    }
    else
      sd.flag |= bsdf_microfacet_ggx_setup();

  }
}


ccl_device void svm_node_closure_bsdf(
                                      uint4 node,
                                      ShaderType shader_type,
                                      int path_flag,
                                      inout int offset)
{
  uint type, param1_offset, param2_offset;

  uint mix_weight_offset;
  svm_unpack_node_uchar4(node.y, (type), (param1_offset), (param2_offset), (mix_weight_offset));
  float mix_weight = (stack_valid(mix_weight_offset) ? stack_load_float(mix_weight_offset) : 1.0f);

  /* note we read this extra node before weight check, so offset is added */
  uint4 data_node = read_node(offset);

  /* Only compute BSDF for surfaces, transparent variable is shared with volume extinction. */
  if (mix_weight == 0.0f || shader_type != SHADER_TYPE_SURFACE) {
    if (type == CLOSURE_BSDF_PRINCIPLED_ID) {
      /* Read all principled BSDF extra data to get the right offset. */
      offset+= 4;
      /*read_node(kg, offset);
      read_node(kg, offset);
      read_node(kg, offset);
      read_node(kg, offset);
      */
    }

    return;
  }

  float3 N  = stack_valid(data_node.x) ? stack_load_float3(data_node.x) : sd.N;

  float param1 = (stack_valid(param1_offset)) ? stack_load_float(param1_offset) :
                                                _uint_as_float(node.z);
  float param2 = (stack_valid(param2_offset)) ? stack_load_float(param2_offset) :
                                                _uint_as_float(node.w);





#define _PRINCIPLED_
  switch (type) {
#ifdef _PRINCIPLED_
    case CLOSURE_BSDF_PRINCIPLED_ID: {
      uint specular_offset, roughness_offset, specular_tint_offset, anisotropic_offset,
          sheen_offset, sheen_tint_offset, clearcoat_offset, clearcoat_roughness_offset,
          eta_offset, transmission_offset, anisotropic_rotation_offset,
          transmission_roughness_offset;
      uint4 data_node2 = read_node(offset);

      float3 T = stack_load_float3(data_node.y);
      svm_unpack_node_uchar4(data_node.z,
                             (specular_offset),

                             (roughness_offset),

                             (specular_tint_offset),

                             (anisotropic_offset));

      svm_unpack_node_uchar4(data_node.w,
                             (sheen_offset),

                             (sheen_tint_offset),

                             (clearcoat_offset),

                             (clearcoat_roughness_offset));

      svm_unpack_node_uchar4(data_node2.x,
                             (eta_offset),

                             (transmission_offset),

                             (anisotropic_rotation_offset),

                             (transmission_roughness_offset));


      // get Disney principled parameters
      float metallic = param1;
      float subsurface = param2;
      float specular = stack_load_float( specular_offset);
      float roughness = stack_load_float( roughness_offset);
      float specular_tint = stack_load_float( specular_tint_offset);
      float anisotropic = stack_load_float( anisotropic_offset);
      float sheen = stack_load_float( sheen_offset);
      float sheen_tint = stack_load_float( sheen_tint_offset);
      float clearcoat = stack_load_float( clearcoat_offset);
      float clearcoat_roughness = stack_load_float( clearcoat_roughness_offset);
      float transmission = stack_load_float( transmission_offset);
      float anisotropic_rotation = stack_load_float( anisotropic_rotation_offset);
      float transmission_roughness = stack_load_float( transmission_roughness_offset);
      float eta = fmaxf(stack_load_float( eta_offset), 1e-5f);

      ClosureType distribution = ClosureType(data_node2.y);

      ClosureType subsurface_method = ClosureType(data_node2.z);


      /* rotate tangent */
      if (anisotropic_rotation != 0.0f)
        T = rotate_around_axis(T, N, anisotropic_rotation * M_2PI_F);

      /* calculate ior */
      float ior = bool(bool(sd.flag & SD_BACKFACING)) ? 1.0f / eta : eta;
      // calculate fresnel for refraction
      float cosNO   = dot3(N, sd.I);
      float fresnel = fresnel_dielectric_cos(cosNO, ior);

      // calculate weights of the diffuse and specular part
      float diffuse_weight = (1.0f - saturate(metallic)) * (1.0f - saturate(transmission));

      float final_transmission = saturate(transmission) * (1.0f - saturate(metallic));
      float specular_weight = (1.0f - final_transmission);

      // get the base color
      uint4 data_base_color = read_node(offset);
      float3 base_color = stack_valid(data_base_color.x) ?
                              stack_load_float3(data_base_color.x) :
                              make_float3(_uint_as_float(data_base_color.y),
                                          _uint_as_float(data_base_color.z),
                                          _uint_as_float(data_base_color.w));

      // get the additional clearcoat normal and subsurface scattering radius
      uint4  data_cn_ssr = read_node(offset);
      float3 clearcoat_normal = stack_valid(data_cn_ssr.x) ?
                                    stack_load_float3(data_cn_ssr.x) :
                                    sd.N;
      float3 subsurface_radius = stack_valid(data_cn_ssr.y) ?
                                     stack_load_float3(data_cn_ssr.y) :
                                     make_float3(1.0f, 1.0f, 1.0f);

      // get the subsurface color
      uint4 data_subsurface_color = read_node(offset);
      float3 subsurface_color = stack_valid(data_subsurface_color.x) ?
                                    stack_load_float3(data_subsurface_color.x) :
                                    make_float3(_uint_as_float(data_subsurface_color.y),
                                                _uint_as_float(data_subsurface_color.z),
                                                _uint_as_float(data_subsurface_color.w));

      float3 weight = sd.svm_closure_weight * mix_weight;

#  ifdef _SUBSURFACE_
      float3 mixed_ss_base_color = subsurface_color * subsurface +
                                   base_color * (1.0f - subsurface);
      float3 subsurf_weight = weight * mixed_ss_base_color * diffuse_weight;

      /* disable in_rsv case of diffuse ancestor, can't see it well then and
       * adds considerably noise due to probabilities of continuing path
       * getting lower and lower */
      if (bool(path_flag & PATH_RAY_DIFFUSE_ANCESTOR)) {

        subsurface = 0.0f;

        /* need to set the base color in_rsv this case such that the
         * rays get the correctly mixed color after transmitting
         * the object */
        base_color = mixed_ss_base_color;
      }

      /* diffuse */
      if (fabsf(average(mixed_ss_base_color)) > CLOSURE_WEIGHT_CUTOFF) {
        if (subsurface <= CLOSURE_WEIGHT_CUTOFF && diffuse_weight > CLOSURE_WEIGHT_CUTOFF) {
          float3 diff_weight = weight * base_color * diffuse_weight;

          int n = bsdf_alloc(

              sd, sizeof_PrincipledDiffuseBsdf, diff_weight);


           if (n >= 0) {

            sd.closure[n].N = N;

            PrincipledDiffuse_roughness(sd.closure[n]) = roughness;


            /* setup bsdf */
            sd.flag |= bsdf_principled_diffuse_setup(sd.closure[n]);

          }
        }
        else if (subsurface > CLOSURE_WEIGHT_CUTOFF) {
          int n = bssrdf_alloc(sd, subsurf_weight);

          if (n >= 0) {
            Bssrdf_radius_lval(sd.closure[n]) = subsurface_radius * subsurface;
            Bssrdf_radius_assign(sd.closure[n]) 
            Bssrdf_albedo_lval(sd.closure[n]) = (subsurface_method == CLOSURE_BSSRDF_PRINCIPLED_ID) ?
                                 subsurface_color :
                                 mixed_ss_base_color;
            Bssrdf_albedo_assign(sd.closure[n])
            Bssrdf_texture_blur(sd.closure[n]) = 0.0f;
            Bssrdf_sharpness(sd.closure[n]) = 0.0f;
            sd.closure[n].N = N;
            Bssrdf_roughness(sd.closure[n]) = roughness;

            /* setup bsdf */
            sd.flag |= bssrdf_setup(sd, sd.closure[n], subsurface_method);
          }
        }
      }
#  else
      /* diffuse */
      if (diffuse_weight > CLOSURE_WEIGHT_CUTOFF) {
        float3 diff_weight = weight * base_color * diffuse_weight;

        int n = bsdf_alloc(sizeof_PrincipledDiffuseBsdf, diff_weight);

         if (n >= 0) {
          getSC().N = N;
          PrincipledDiffuse_roughness(getSC()) =  roughness;
          /* setup bsdf */
          sd.flag |= bsdf_principled_diffuse_setup();
        }
      }
#  endif

      /* sheen */
      if (diffuse_weight > CLOSURE_WEIGHT_CUTOFF && sheen > CLOSURE_WEIGHT_CUTOFF) {
        float m_cdlum = linear_rgb_to_gray(base_color);
        float3 m_ctint = m_cdlum > 0.0f ?
                             base_color / m_cdlum :
                             make_float3(1.0f, 1.0f, 1.0f);  // normalize lum. to isolate hue+sat

        /* color of the sheen component */
        float3 sheen_color = make_float3(1.0f, 1.0f, 1.0f) * (1.0f - sheen_tint) +
                             m_ctint * sheen_tint;

        float3 sheen_weight = weight * sheen * sheen_color * diffuse_weight;

        int n = bsdf_alloc(sizeof_PrincipledSheenBsdf, sheen_weight);


         if (n >= 0) {

          getSC().N = N;
          /* setup bsdf */
          sd.flag |= bsdf_principled_sheen_setup();
        }
      }

      /* specular reflection */
#  ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_reflective) || !(bool(path_flag & PATH_RAY_DIFFUSE))) {
#  endif
        if (specular_weight > CLOSURE_WEIGHT_CUTOFF &&
            (specular > CLOSURE_WEIGHT_CUTOFF || metallic > CLOSURE_WEIGHT_CUTOFF)) {
          float3 spec_weight = weight * specular_weight;

          int n = bsdf_alloc(sizeof_MicrofacetBsdf, spec_weight);
          if (n >= 0) {
            getSC().N = N;
            Microfacet_ior(getSC()) = (2.0f / (1.0f - safe_sqrtf(0.08f * specular))) - 1.0f;
            Microfacet_T_lval(getSC()) =  T; Microfacet_T_assign(getSC()) 
  /*sd.closure[n].extra = extra;*/
            float aspect = safe_sqrtf(1.0f - anisotropic * 0.9f);
            float r2 = roughness * roughness;

            Microfacet_alpha_x(getSC()) = r2 / aspect;

            Microfacet_alpha_y(getSC()) = r2 * aspect;


            float m_cdlum = 0.3f * base_color.x + 0.6f * base_color.y +
                            0.1f * base_color.z;  // luminance approx.
            float3 m_ctint = m_cdlum > 0.0f ?
                                 base_color / m_cdlum :
                                 make_float3(
                                     0.0f, 0.0f, 0.0f);  // normalize lum. to isolate hue+sat
            float3 tmp_col = make_float3(1.0f, 1.0f, 1.0f) * (1.0f - specular_tint) +
                             m_ctint * specular_tint;

             Microfacet_cspec0_lval(getSC()) =  (specular * 0.08f * tmp_col) * (1.0f - metallic) + base_color * metallic; 
             Microfacet_cspec0_assign(getSC()) 

             Microfacet_color_lval(getSC()) =  base_color; Microfacet_color_assign(getSC()) 
             Microfacet_clearcoat(getSC()) = 0.0f;

            /* setup bsdf */
            if (distribution == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID || roughness <= 0.075f) /* use single-scatter GGX */
              sd.flag |= bsdf_microfacet_ggx_fresnel_setup();
            else /* use multi-scatter GGX */
              sd.flag |= bsdf_microfacet_multi_ggx_fresnel_setup();
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif

      /* BSDF */
#  ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_refractive) || !(bool(path_flag & PATH_RAY_DIFFUSE))) {
#  endif
        if (final_transmission > CLOSURE_WEIGHT_CUTOFF) {
          float3 glass_weight = weight * final_transmission;
          float3 cspec0 = base_color * specular_tint +
                          make_float3(1.0f, 1.0f, 1.0f) * (1.0f - specular_tint);

          if (roughness <= 5e-2f ||
              distribution == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID) { /* use single-scatter GGX */
            float refl_roughness = roughness;

            /* reflection */
#  ifdef _CAUSTICS_TRICKS_
            if (bool(kernel_data.integrator.caustics_reflective) || !(bool(path_flag & PATH_RAY_DIFFUSE))){
#  endif
            
              int n = bsdf_alloc(sizeof_MicrofacetBsdf, glass_weight * fresnel);
/*extra allocate elim*/
              if (n >= 0) {
                getSC().N = N;
                Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) 
      /*sd.closure[n].extra = extra;*/
                Microfacet_alpha_x(getSC()) = refl_roughness * refl_roughness;
                Microfacet_alpha_y(getSC()) = refl_roughness * refl_roughness;
                Microfacet_ior(getSC()) = ior;
                Microfacet_color_lval(getSC()) =  base_color; Microfacet_color_assign(getSC()) 
                Microfacet_cspec0_lval(getSC()) =  cspec0; Microfacet_cspec0_assign(getSC()) 
                Microfacet_clearcoat(getSC()) = 0.0f;

                /* setup bsdf */
                sd.flag |= bsdf_microfacet_ggx_fresnel_setup();
              }
            }

            /* refraction */
#  ifdef _CAUSTICS_TRICKS_
            if (bool(kernel_data.integrator.caustics_refractive) || !(bool(path_flag & PATH_RAY_DIFFUSE))){
#  endif
              int n = bsdf_alloc(sizeof_MicrofacetBsdf, base_color * glass_weight * (1.0f - fresnel));

               if (n >= 0) {
                 getSC().N = N;
                 Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) Microfacet_extra_NULL(getSC());
                if (distribution == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID)
                  transmission_roughness = 1.0f - (1.0f - refl_roughness) *
                                                      (1.0f - transmission_roughness);
                else
                  transmission_roughness = refl_roughness;

                Microfacet_alpha_x(getSC()) = transmission_roughness * transmission_roughness;
                Microfacet_alpha_y(getSC()) = transmission_roughness * transmission_roughness;
                Microfacet_ior(getSC()) = ior;
                /* setup bsdf */
                sd.flag |= bsdf_microfacet_ggx_refraction_setup();

              }
            }
          }
          else { /* use multi-scatter GGX */
            int n = bsdf_alloc(sizeof_MicrofacetBsdf, glass_weight);
            if (n >= 0) {
               getSC().N = N;
    /*sd.closure[n].extra = extra;*/
               Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) 
              Microfacet_alpha_x(getSC()) = roughness * roughness;
              Microfacet_alpha_y(getSC()) = roughness * roughness;
              Microfacet_ior(getSC()) = ior;
              Microfacet_color_lval(getSC()) =  base_color; Microfacet_color_assign(getSC()) 
              Microfacet_cspec0_lval(getSC()) =  cspec0; Microfacet_cspec0_assign(getSC()) 
              Microfacet_clearcoat(getSC()) = 0.0f;
              /* setup bsdf */
              sd.flag |= bsdf_microfacet_multi_ggx_glass_fresnel_setup();    
            }
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif

      /* clearcoat */
#  ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_reflective) || !(bool(path_flag & PATH_RAY_DIFFUSE))) {
#  endif
        if (clearcoat > CLOSURE_WEIGHT_CUTOFF) {
          int n = bsdf_alloc(sizeof_MicrofacetBsdf, weight);
          if (n >= 0) {
            getSC().N = clearcoat_normal;
            Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) 
            Microfacet_ior(getSC()) = 1.5f;
  /*sd.closure[n].extra = extra;*/
            Microfacet_alpha_x(getSC()) = clearcoat_roughness * clearcoat_roughness;
            Microfacet_alpha_y(getSC()) = clearcoat_roughness * clearcoat_roughness;
            Microfacet_color_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_color_assign(getSC()) 
            Microfacet_cspec0_lval(getSC()) =  make_float3(0.04f, 0.04f, 0.04f); Microfacet_cspec0_assign(getSC()) 
            Microfacet_clearcoat(getSC()) = clearcoat;
            /* setup bsdf */
            sd.flag |= bsdf_microfacet_ggx_clearcoat_setup();
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif
      break;
    }

#endif /* _PRINCIPLED_ */
    case CLOSURE_BSDF_DIFFUSE_ID: {
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_OrenNayarBsdf, weight);
       if (n >= 0) {

        getSC().N = N;

        float roughness = param1;

        if (roughness == 0.0f) {
          sd.flag |= bsdf_diffuse_setup();

        }
        else {
          OrenNayar_roughness(getSC()) =  roughness;
          sd.flag |= bsdf_oren_nayar_setup();
        }
      }
      break;
    }
    case CLOSURE_BSDF_GLOSSY_TOON_ID:
#ifdef _CAUSTICS_TRICKS_
      if (!bool(kernel_data.integrator.caustics_reflective) && (bool(path_flag & PATH_RAY_DIFFUSE)))
        break;
      ATTR_FALLTHROUGH;
#endif
    case CLOSURE_BSDF_DIFFUSE_TOON_ID: {
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_ToonBsdf, weight);
      
       if (n >= 0) {

        getSC().N = N;

        Toon_size(getSC()) = param1;

        Toon_smooth(getSC()) = param2;


        if (type == CLOSURE_BSDF_DIFFUSE_TOON_ID)
          sd.flag |= bsdf_diffuse_toon_setup();
        else
          sd.flag |= bsdf_glossy_toon_setup();

      }
    
        break;
    }
    case CLOSURE_BSDF_TRANSLUCENT_ID: {
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_DiffuseBsdf, weight);
       if (n >= 0) {

        getSC().N = N;

        sd.flag |= bsdf_translucent_setup();

      }
      break;
    }
    case CLOSURE_BSDF_TRANSPARENT_ID: {
      float3 weight = sd.svm_closure_weight * mix_weight;
      bsdf_transparent_setup( weight, path_flag);
      break;
    }
    case CLOSURE_BSDF_ASHIKHMIN_VELVET_ID: {
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_VelvetBsdf, weight);
      if (n >= 0) {
        getSC().N = N;
        Velvet_sigma(getSC()) = saturate(param1);
        sd.flag |= bsdf_ashikhmin_velvet_setup();
      }
      break;
    }
    case CLOSURE_BSDF_REFRACTION_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID: {
#ifdef _CAUSTICS_TRICKS_
      if (!bool(kernel_data.integrator.caustics_refractive) && (bool(path_flag & PATH_RAY_DIFFUSE)))
        break;
#endif
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_MicrofacetBsdf, weight);
       if (n >= 0) {
         getSC().N = N;
         Microfacet_T_lval( getSC()) =  make_float3(0.0f, 0.0f, 0.0f); 
         Microfacet_T_assign(getSC()) Microfacet_extra_NULL(getSC());
         float eta = fmaxf(param2, 1e-5f);
         eta = (bool(sd.flag & SD_BACKFACING)) ? 1.0f / eta : eta;

        /* setup bsdf */
        if (type == CLOSURE_BSDF_REFRACTION_ID) {
          Microfacet_alpha_x(getSC()) = 0.0f;
          Microfacet_alpha_y(getSC()) = 0.0f;
          Microfacet_ior(getSC()) = eta;
          sd.flag |= bsdf_refraction_setup();
        }
        else {
          float roughness = sqr(param1);
          Microfacet_alpha_x(getSC()) = roughness;
          Microfacet_alpha_y(getSC()) = roughness;
          Microfacet_ior(getSC()) = eta;
          if (type == CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID)
            sd.flag |= bsdf_microfacet_beckmann_refraction_setup();
          else
            sd.flag |= bsdf_microfacet_ggx_refraction_setup();
        }
      }
      break;
    }
    case CLOSURE_BSDF_SHARP_GLASS_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_GLASS_ID: {

#ifdef _CAUSTICS_TRICKS_
      if (!bool(kernel_data.integrator.caustics_reflective) &&
          !bool(kernel_data.integrator.caustics_refractive) && (bool(path_flag & PATH_RAY_DIFFUSE))) {
         break;
      }
#endif

      float3 weight = sd.svm_closure_weight * mix_weight;

      /* index of refraction */
      float eta = fmaxf(param2, 1e-5f);
      eta = (bool(sd.flag & SD_BACKFACING)) ? 1.0f / eta : eta;

      /* fresnel */
      float cosNO = dot3(N, sd.I);
      float fresnel = fresnel_dielectric_cos(cosNO, eta);
      float roughness = sqr(param1);
      
      /* reflection */
#ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_reflective) || !(bool(path_flag & PATH_RAY_DIFFUSE)))
#endif
      {
        int n = bsdf_alloc(sizeof_MicrofacetBsdf, weight * fresnel);
         if (n >= 0) {
          getSC().N = N;
          Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) Microfacet_extra_NULL(getSC());
          svm_node_glass_setup( int(type), float(eta), float(roughness), false);
        }
      }

      /* refraction */
#ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_refractive) || !(bool(path_flag & PATH_RAY_DIFFUSE)))
#endif
      {
        int n = bsdf_alloc(sizeof_MicrofacetBsdf, weight * (1.0f - fresnel));
        if (n >= 0) {
           getSC().N = N;
           Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) Microfacet_extra_NULL(getSC());
           svm_node_glass_setup( int(type), eta, roughness, true);
        }
      }
      break;
    }
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID: {
#ifdef _CAUSTICS_TRICKS_
      if (!bool(kernel_data.integrator.caustics_reflective) &&
          !bool(kernel_data.integrator.caustics_refractive) && (bool(path_flag & PATH_RAY_DIFFUSE)))
        break;
#endif
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_MicrofacetBsdf, weight);
      if (n < 0) {break;}
      getSC().N = N;
      Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) 
      float roughness = sqr(param1);
      Microfacet_alpha_x(getSC()) = roughness;
      Microfacet_alpha_y(getSC()) = roughness;
      float eta = fmaxf(param2, 1e-5f);
      Microfacet_ior(getSC()) = (bool(sd.flag & SD_BACKFACING)) ? 1.0f / eta : eta;

      kernel_assert("assert rcall4 860 ",stack_valid(data_node.z));

      Microfacet_color_lval(getSC()) =  stack_load_float3(data_node.z); Microfacet_color_assign(getSC()) 
      Microfacet_cspec0_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_cspec0_assign(getSC());
      Microfacet_clearcoat(getSC()) = 0.0f;
      /* setup bsdf */
      sd.flag |= bsdf_microfacet_multi_ggx_glass_setup();
      break;
    }
    case CLOSURE_BSDF_REFLECTION_ID:
    case CLOSURE_BSDF_MICROFACET_GGX_ID:
    case CLOSURE_BSDF_MICROFACET_BECKMANN_ID:
    case CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID:
    case CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID: {
#ifdef _CAUSTICS_TRICKS_
      if (!bool(kernel_data.integrator.caustics_reflective) && (bool(path_flag & PATH_RAY_DIFFUSE)))
        break;
#endif
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_MicrofacetBsdf, weight);
      if (n < 0) {
        break;
      }

      float roughness = sqr(param1);
      getSC().N = N;

      Microfacet_ior(getSC()) = 0.0f;Microfacet_extra_NULL(getSC());
      if (data_node.y == SVM_STACK_INVALID) {
        Microfacet_T_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(getSC()) 
        Microfacet_alpha_x(getSC()) = roughness;
        Microfacet_alpha_y(getSC()) = roughness;
      }
      else {
         Microfacet_T_lval(getSC()) =  stack_load_float3(data_node.y); Microfacet_T_assign(getSC()) 
        /* rotate tangent */
        float rotation = stack_load_float(data_node.z);
        if (rotation != 0.0f)
           Microfacet_T_lval(getSC()) =  rotate_around_axis(Microfacet_T(getSC()), getSC().N, rotation * M_2PI_F);
            Microfacet_T_assign(getSC()) 
        /* compute roughness */
        float anisotropy = clamp(param2, -0.99f, 0.99f);
        if (anisotropy < 0.0f) {
          Microfacet_alpha_x(getSC()) = roughness / (1.0f + anisotropy);

          Microfacet_alpha_y(getSC()) = roughness * (1.0f + anisotropy);

        }
        else {
          Microfacet_alpha_x(getSC()) = roughness * (1.0f - anisotropy);

          Microfacet_alpha_y(getSC()) = roughness / (1.0f - anisotropy);

        }
      }

      /* setup bsdf */
      if (type == CLOSURE_BSDF_REFLECTION_ID)
        sd.flag |= bsdf_reflection_setup();

      else if (type == CLOSURE_BSDF_MICROFACET_BECKMANN_ID)
        sd.flag |= bsdf_microfacet_beckmann_setup();

      else if (type == CLOSURE_BSDF_MICROFACET_GGX_ID)
        sd.flag |= bsdf_microfacet_ggx_setup();

      else if (type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID) {
        kernel_assert("assert rcall4 937 ",stack_valid(data_node.w));
        /*sd.closure[n].extra = (MicrofacetExtra *)closure_alloc_extra(sd, sizeof_MicrofacetExtra);*/
        /*if (sd.closure[n].extra) */{
          Microfacet_color_lval(getSC()) =  stack_load_float3(data_node.w); Microfacet_color_assign(getSC()) 
          Microfacet_cspec0_lval(getSC()) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_cspec0_assign(getSC()) 
          Microfacet_clearcoat(getSC()) = 0.0f;
          sd.flag |= bsdf_microfacet_multi_ggx_setup();
        }
      }
      else {
        sd.flag |= bsdf_ashikhmin_shirley_setup();
      }

      break;
    }
    
#ifdef _PRINCIPLED_ 



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

#ifdef _SUBSURFACE_
    case CLOSURE_BSSRDF_CUBIC_ID:
    case CLOSURE_BSSRDF_GAUSSIAN_ID:
    case CLOSURE_BSSRDF_BURLEY_ID:
    case CLOSURE_BSSRDF_RANDOM_WALK_ID: {
      float3 weight = sd.svm_closure_weight * mix_weight;
      int n = bssrdf_alloc(sd, weight);

      if (n >=0) {
        /* disable in_rsv case of diffuse ancestor, can't see it well then and
         * adds considerably noise due to probabilities of continuing path
         * getting lower and lower */
        if (bool(path_flag & PATH_RAY_DIFFUSE_ANCESTOR))

          param1 = 0.0f;

        Bssrdf_radius_lval(sd.closure[n]) = stack_load_float3(stack, data_node.z) * param1; Bssrdf_radius_assign(sd.closure[n]);
        Bssrdf_albedo_lval(sd.closure[n]) = sd.svm_closure_weight;Bssrdf_albedo_assign(sd.closure[n]);
        Bssrdf_texture_blur(sd.closure[n]) = param2;
        Bssrdf_sharpness(sd.closure[n]) = stack_load_float( data_node.w);
        sd.closure[n].N = N;
        Bssrdf_roughness(sd.closure[n]) = 0.0f;
        sd.flag |= bssrdf_setup(sd, sd.closure[n], ClosureType(type));

      }

      break;
    }
#endif
#endif
    default:
      break;
  }
}


ccl_device void svm_node_closure_volume(
    inout KernelGlobals kg, inout ShaderData sd, inout float stack[SVM_STACK_SIZE]
, uint4 node, ShaderType shader_type)
{
#ifdef _VOLUME_
  /* Only sum extinction for volumes, variable is shared with surface transparency. */
  if (shader_type != SHADER_TYPE_VOLUME) {
    return;
  }

  uint type, density_offset, anisotropy_offset;

  uint mix_weight_offset;
  svm_unpack_node_uchar4(node.y, (type), (density_offset), (anisotropy_offset), (mix_weight_offset));

  float mix_weight = (stack_valid(mix_weight_offset) ? stack_load_float( mix_weight_offset) :
                                                       1.0f);

  if (mix_weight == 0.0f) {
    return;
  }

  float density = (stack_valid(density_offset)) ? stack_load_float( density_offset) :
                                                  _uint_as_float(node.z);
  density = mix_weight * fmaxf(density, 0.0f);

  /* Compute scattering coefficient. */
  float3 weight = sd.svm_closure_weight;

  if (type == CLOSURE_VOLUME_ABSORPTION_ID) {
    weight = make_float3(1.0f, 1.0f, 1.0f) - weight;
  }

  weight *= density;

  /* Add closure for volume scattering. */
  if (type == CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID) {
    int n = bsdf_alloc(
        sd, sizeof_HenyeyGreensteinVolume, weight);


    if (n >=0 ) {
      float anisotropy = (stack_valid(anisotropy_offset)) ?
                             stack_load_float( anisotropy_offset) :
                             _uint_as_float(node.w);
      HenyeyGreensteinVolume_g(sd.closure[n]) = anisotropy; /* g */
      sd.flag |= volume_henyey_greenstein_setup(sd.closure[n]);
    }
  }

  /* Sum total extinction weight. */
  volume_extinction_setup(sd, weight);
#endif
}

ccl_device void svm_node_principled_volume(inout KernelGlobals kg,
                                           inout ShaderData sd,
                                           inout float stack[SVM_STACK_SIZE],
                                           uint4 node,
                                           ShaderType shader_type,
                                           int path_flag,
                                           inout int offset)
{
#ifdef _VOLUME_
  uint4 value_node = read_node(kg, offset);
  uint4 attr_node = read_node(kg, offset);

  /* Only sum extinction for volumes, variable is shared with surface transparency. */
  if (shader_type != SHADER_TYPE_VOLUME) {
    return;
  }

  uint density_offset, anisotropy_offset, absorption_color_offset, mix_weight_offset;
  svm_unpack_node_uchar4(
      node.y, (density_offset), (anisotropy_offset), (absorption_color_offset), (mix_weight_offset));




  float mix_weight = (stack_valid(mix_weight_offset) ? stack_load_float( mix_weight_offset) :
                                                       1.0f);

  if (mix_weight == 0.0f) {
    return;
  }

  /* Compute density. */
  float primitive_density = 1.0f;
  float density = (stack_valid(density_offset)) ? stack_load_float( density_offset) :
                                                  _uint_as_float(value_node.x);
  density = mix_weight * fmaxf(density, 0.0f);

  if (density > CLOSURE_WEIGHT_CUTOFF) {
    /* Density and color attribute lookup if available. */
    const AttributeDescriptor attr_density = find_attribute(kg, sd, attr_node.x);
    if (attr_density.offset != ATTR_STD_NOT_FOUND) {
      primitive_density = primitive_volume_attribute_float(kg, sd, attr_density);
      density = fmaxf(density * primitive_density, 0.0f);
    }
  }

  if (density > CLOSURE_WEIGHT_CUTOFF) {
    /* Compute scattering color. */
    float3 color = sd.svm_closure_weight;

    const AttributeDescriptor attr_color = find_attribute(kg, sd, attr_node.y);
    if (attr_color.offset != ATTR_STD_NOT_FOUND) {
      color *= primitive_volume_attribute_float3(kg, sd, attr_color);
    }

    /* Add closure for volume scattering. */
    int n = bsdf_alloc(
        sd, sizeof_HenyeyGreensteinVolume, color * density);

    if (n >= 0) {
      float anisotropy = (stack_valid(anisotropy_offset)) ?
                             stack_load_float( anisotropy_offset) :
                             _uint_as_float(value_node.y);
      HenyeyGreensteinVolume_g(sd.closure[n]) = anisotropy;
      sd.flag |= volume_henyey_greenstein_setup(sd.closure[n]);
    }

    /* Add extinction weight. */
    float3 zero = make_float3(0.0f, 0.0f, 0.0f);
    float3 one = make_float3(1.0f, 1.0f, 1.0f);
    float3 absorption_color = max(sqrt(stack_load_float3(stack, absorption_color_offset)), zero);
    float3 absorption = max(one - color, zero) * max(one - absorption_color, zero);
    volume_extinction_setup(sd, (color + absorption) * density);
  }

  /* Compute emission. */
  if (bool(path_flag & PATH_RAY_SHADOW)) {

    /* Don't need emission for shadows. */
    return;
  }

  uint emission_offset, emission_color_offset, blackbody_offset, temperature_offset;
  svm_unpack_node_uchar4(
      node.z, (emission_offset), (emission_color_offset), (blackbody_offset), (temperature_offset));




  float emission = (stack_valid(emission_offset)) ? stack_load_float( emission_offset) :
                                                    _uint_as_float(value_node.z);
  float blackbody = (stack_valid(blackbody_offset)) ? stack_load_float( blackbody_offset) :
                                                      _uint_as_float(value_node.w);

  if (emission > CLOSURE_WEIGHT_CUTOFF) {
    float3 emission_color = stack_load_float3(stack, emission_color_offset);
    emission_setup(sd, emission * emission_color);
  }

  if (blackbody > CLOSURE_WEIGHT_CUTOFF) {
    float T = stack_load_float( temperature_offset);

    /* Add flame temperature from attribute if available. */
    const AttributeDescriptor attr_temperature = find_attribute(kg, sd, attr_node.z);
    if (attr_temperature.offset != ATTR_STD_NOT_FOUND) {
      float temperature = primitive_volume_attribute_float(kg, sd, attr_temperature);
      T *= fmaxf(temperature, 0.0f);
    }

    T = fmaxf(T, 0.0f);

    /* Stefan-Boltzmann law. */
    float T4 = sqr(sqr(T));
    float sigma = 5.670373e-8f * 1e-6f / M_PI_F;
    float intensity = sigma * mix(1.0f, T4, blackbody);

    if (intensity > CLOSURE_WEIGHT_CUTOFF) {
      float3 blackbody_tint = stack_load_float3(stack, node.w);
      float3 bb = blackbody_tint * intensity * svm_math_blackbody_color(T);
      emission_setup(sd, bb);
    }
  }
#endif
}

void  svm_node_closure_emission(uint4 node)
{
  uint mix_weight_offset = node.y;
  float3 weight = sd.svm_closure_weight;

  if (stack_valid(mix_weight_offset)) {
    float mix_weight = stack_load_float(mix_weight_offset);
    if (mix_weight == 0.0f)
      return;
    weight *= mix_weight;
  }
  emission_setup(weight);
}


ccl_device void svm_node_closure_background(uint4 node)
{
  uint mix_weight_offset = node.y;
  float3 weight = sd.svm_closure_weight;

  if (stack_valid(mix_weight_offset)) {
    float mix_weight = stack_load_float(mix_weight_offset);

    if (mix_weight == 0.0f)
      return;

    weight *= mix_weight;
  }

  background_setup(weight);
}

#ifdef stack_load_float3

/* Closure Nodes */
#define  svm_node_closure_store_weight(wei) sd.svm_closure_weight = wei
#define  svm_node_closure_set_weight(r, g,b) svm_node_closure_store_weight(make_float3(_uint_as_float(r), _uint_as_float(g), _uint_as_float(b)));
#define  svm_node_closure_weight(offset) svm_node_closure_store_weight(stack_load_float3(offset));
//uint color_offset = node.y;    uint strength_offset = node.z;
#define  svm_node_emission_weight(node) svm_node_closure_store_weight( (stack_load_float3(node.y) *stack_load_float(node.z) ) );

/* fetch weight from blend input, previous mix closures,
   * and write to stack to be used by closure nodes later */
#define  svm_node_mix_closure(node) {\
  uint weight_offset, in_weight_offset, weight1_offset, weight2_offset;\
  svm_unpack_node_uchar4(node.y, (weight_offset), (in_weight_offset), (weight1_offset), (weight2_offset));\
  float weight = stack_load_float(weight_offset);\
  weight = saturate(weight);\
  float in_weight = (stack_valid(in_weight_offset)) ? stack_load_float(in_weight_offset) :1.0f;\
  if (stack_valid(weight1_offset)) stack_store_float(weight1_offset, in_weight * (1.0f - weight));\
  if (stack_valid(weight2_offset)) stack_store_float(weight2_offset, in_weight * weight);\
}

#endif

#ifdef _SVM_CLOSURE_TODO_

ccl_device void svm_node_closure_holdout(inout ShaderData sd, inout float stack[SVM_STACK_SIZE]
, uint4 node)
{
  uint mix_weight_offset = node.y;

  if (stack_valid(mix_weight_offset)) {
    float mix_weight = stack_load_float( mix_weight_offset);

    if (mix_weight == 0.0f)
      return;

    closure_alloc(
        sd, sizeof_ShaderClosure, CLOSURE_HOLDOUT_ID, sd.svm_closure_weight * mix_weight);

  }
  else
    closure_alloc(sd, sizeof_ShaderClosure, CLOSURE_HOLDOUT_ID, sd.svm_closure_weight);


  sd.flag |= int(SD_HOLDOUT);

}
/* (Bump) normal */

ccl_device void svm_node_set_normal(
    inout KernelGlobals kg, inout ShaderData sd, inout float stack[SVM_STACK_SIZE]
, uint in_direction, uint out_normal)
{
  float3 normal = stack_load_float3(stack, in_direction);
  sd.N = normal;
  stack_store_float3(stack, out_normal, normal);
}

#endif
#endif


#ifdef NODE_Callee



#endif


CCL_NAMESPACE_END




#endif