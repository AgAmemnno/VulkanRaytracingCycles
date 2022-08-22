#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_scalar_block_layout  :require

#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"


#include "kernel/kernel_globals.h.glsl"


struct args{
    ShaderDataTinyStorage sd;
    int path_flag;
};

layout(location = 0) callableDataInNV args arg;

#define _sd arg.sd
ShaderClosure sc;
float stack[255];
bool  alloc = false;
#define MAX_ALLOCATE  1024*1024

#define getSC() SC(_sd.alloc_offset)

#define assignSC(sc) if(alloc){SC(_sd.alloc_offset) = sc;alloc = false;}


ccl_device int closure_alloc(ClosureType type, float3 weight)
{
  
  if (_sd.num_closure_left == 0)
    return -1;

  int idx = atomicAdd(counter[_sd.atomic_offset],1);
  kernel_assert(idx <= MAX_ALLOCATE);

  if(_sd.num_closure > 0){
    SC(_sd.alloc_offset).next = idx;
  }

  _sd.alloc_offset = idx;
  getSC().type         =  type;
  getSC().weight       =  weight;
  
  _sd.num_closure++;
  _sd.num_closure_left--;
  alloc = true;



  return _sd.num_closure-1;
}


ccl_device_inline int bsdf_alloc( float3 weight)
{

    int n  = closure_alloc(CLOSURE_NONE_ID, weight);
    if (n < 0)
    return -1;

    float sample_weight = fabsf(average(weight));
    sc.sample_weight = sample_weight;
    return (sample_weight >= CLOSURE_WEIGHT_CUTOFF) ? n : -1;

}



#define read_node(offset) kernel_tex_fetch(_svm_nodes, offset++)
#define stack_valid(a) (a != uint(SVM_STACK_INVALID))

#define stack_load_float3(a) make_float3(stack[a + 0], stack[a + 1], stack[a + 2])
#define stack_store_float3(a,f) {stack[a + 0] = f.x;stack[a + 1] = f.y;stack[a + 2] = f.z;}
#define stack_load_float(a) stack[a]
#define stack_load_float_default(a,value) ((a == (uint)SVM_STACK_INVALID) ? _uint_as_float(value) : stack_load_float(stack, a) );


#define stack_store_float( a, f) stack[a] = f
#define stack_load_int(a) _float_as_int(stack[a])
#define stack_load_int_default(a,value) ((a == uint(SVM_STACK_INVALID) ) ? int(value) : stack_load_int(a))
#define stack_store_int(a,i) stack[a] = _int_as_float(i)

#define DiffuseBsdf ShaderClosure
#define sizeof_DiffuseBsdf 0
#define bsdf_diffuse_setup(flag, bsdf)\
{\
  bsdf.type = CLOSURE_BSDF_DIFFUSE_ID;\
  flag |= int(SD_BSDF | SD_BSDF_HAS_EVAL);\
}

#define sizeof_OrenNayarBsdf 12

#define OrenNayarBsdf ShaderClosure
#define OrenNayar_roughness(bsdf) bsdf.data[0]
#define OrenNayar_a(bsdf) bsdf.data[1]
#define OrenNayar_b(bsdf) bsdf.data[2]

#define bsdf_oren_nayar_setup(flag,bsdf)\
{\
  float sigma = OrenNayar_roughness(bsdf);\
  bsdf.type = CLOSURE_BSDF_OREN_NAYAR_ID;\
  sigma = saturate(sigma);\
  float div = 1.0f / (M_PI_F + ((3.0f * M_PI_F - 4.0f) / 6.0f) * sigma);\
  OrenNayar_a(bsdf) = 1.0f * div;\
  OrenNayar_b(bsdf) = sigma * div;\
  flag|= int(SD_BSDF | SD_BSDF_HAS_EVAL);\
}

#define svm_unpack_node_uchar4(i, x, y, z, w)\
{\
  x = (i & 0xFF);\
  y = ((i >> 8) & 0xFF);\
  z = ((i >> 16) & 0xFF);\
  w = ((i >> 24) & 0xFF);\
}


void svm_node_closure_set_weight(uint r, uint g, uint b)
{
  float3 weight = make_float3(_uint_as_float(r), _uint_as_float(g), _uint_as_float(b));
  _sd.svm_closure_weight = weight;
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

  float3 N  = stack_valid(data_node.x) ? stack_load_float3(data_node.x) : _sd.N;

  float param1 = (stack_valid(param1_offset)) ? stack_load_float(param1_offset) :
                                                _uint_as_float(node.z);
  float param2 = (stack_valid(param2_offset)) ? stack_load_float(param2_offset) :
                                                _uint_as_float(node.w);

  switch (type) {
#ifdef _PRINCIPLED_
    case CLOSURE_BSDF_PRINCIPLED_ID: {
      uint specular_offset, roughness_offset, specular_tint_offset, anisotropic_offset,
          sheen_offset, sheen_tint_offset, clearcoat_offset, clearcoat_roughness_offset,
          eta_offset, transmission_offset, anisotropic_rotation_offset,
          transmission_roughness_offset;
      uint4 data_node2 = read_node(kg, offset);

      float3 T = stack_load_float3(stack, data_node.y);
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
      float specular = stack_load_float(stack, specular_offset);
      float roughness = stack_load_float(stack, roughness_offset);
      float specular_tint = stack_load_float(stack, specular_tint_offset);
      float anisotropic = stack_load_float(stack, anisotropic_offset);
      float sheen = stack_load_float(stack, sheen_offset);
      float sheen_tint = stack_load_float(stack, sheen_tint_offset);
      float clearcoat = stack_load_float(stack, clearcoat_offset);
      float clearcoat_roughness = stack_load_float(stack, clearcoat_roughness_offset);
      float transmission = stack_load_float(stack, transmission_offset);
      float anisotropic_rotation = stack_load_float(stack, anisotropic_rotation_offset);
      float transmission_roughness = stack_load_float(stack, transmission_roughness_offset);
      float eta = fmaxf(stack_load_float(stack, eta_offset), 1e-5f);

      ClosureType distribution = ClosureType(data_node2.y);

      ClosureType subsurface_method = ClosureType(data_node2.z);


      /* rotate tangent */
      if (anisotropic_rotation != 0.0f)
        T = rotate_around_axis(T, N, anisotropic_rotation * M_2PI_F);

      /* calculate ior */
      float ior = bool(bool(_sd.flag & SD_BACKFACING)
) ? 1.0f / eta : eta;


      // calculate fresnel for refraction
      float cosNO = dot(N, _sd.I);
      float fresnel = fresnel_dielectric_cos(cosNO, ior);

      // calculate weights of the diffuse and specular part
      float diffuse_weight = (1.0f - saturate(metallic)) * (1.0f - saturate(transmission));

      float final_transmission = saturate(transmission) * (1.0f - saturate(metallic));
      float specular_weight = (1.0f - final_transmission);

      // get the base color
      uint4 data_base_color = read_node(kg, offset);
      float3 base_color = stack_valid(data_base_color.x) ?
                              stack_load_float3(stack, data_base_color.x) :
                              make_float3(_uint_as_float(data_base_color.y),
                                          _uint_as_float(data_base_color.z),
                                          _uint_as_float(data_base_color.w));

      // get the additional clearcoat normal and subsurface scattering radius
      uint4 data_cn_ssr = read_node(kg, offset);
      float3 clearcoat_normal = stack_valid(data_cn_ssr.x) ?
                                    stack_load_float3(stack, data_cn_ssr.x) :
                                    _sd.N;
      float3 subsurface_radius = stack_valid(data_cn_ssr.y) ?
                                     stack_load_float3(stack, data_cn_ssr.y) :
                                     make_float3(1.0f, 1.0f, 1.0f);

      // get the subsurface color
      uint4 data_subsurface_color = read_node(kg, offset);
      float3 subsurface_color = stack_valid(data_subsurface_color.x) ?
                                    stack_load_float3(stack, data_subsurface_color.x) :
                                    make_float3(_uint_as_float(data_subsurface_color.y),
                                                _uint_as_float(data_subsurface_color.z),
                                                _uint_as_float(data_subsurface_color.w));

      float3 weight = _sd.svm_closure_weight * mix_weight;

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

            _sd.closure[n].N = N;

            PrincipledDiffuse_roughness(_sd.closure[n]) = roughness;


            /* setup bsdf */
            _sd.flag |= bsdf_principled_diffuse_setup(_sd.closure[n]);

          }
        }
        else if (subsurface > CLOSURE_WEIGHT_CUTOFF) {
          int n = bssrdf_alloc(sd, subsurf_weight);

          if (n >= 0) {
            Bssrdf_radius_lval(_sd.closure[n]) = subsurface_radius * subsurface;
            Bssrdf_radius_assign(_sd.closure[n]) 
            Bssrdf_albedo_lval(_sd.closure[n]) = (subsurface_method == CLOSURE_BSSRDF_PRINCIPLED_ID) ?
                                 subsurface_color :
                                 mixed_ss_base_color;
            Bssrdf_albedo_assign(_sd.closure[n])
            Bssrdf_texture_blur(_sd.closure[n]) = 0.0f;
            Bssrdf_sharpness(_sd.closure[n]) = 0.0f;
            _sd.closure[n].N = N;
            Bssrdf_roughness(_sd.closure[n]) = roughness;

            /* setup bsdf */
            _sd.flag |= bssrdf_setup(sd, _sd.closure[n], subsurface_method);
          }
        }
      }
#  else
      /* diffuse */
      if (diffuse_weight > CLOSURE_WEIGHT_CUTOFF) {
        float3 diff_weight = weight * base_color * diffuse_weight;

        int n = bsdf_alloc(

            sd, sizeof_PrincipledDiffuseBsdf, diff_weight);


         if (n >= 0) {

          _sd.closure[n].N = N;

          PrincipledDiffuse_roughness(_sd.closure[n]) =  roughness;


          /* setup bsdf */
          _sd.flag |= bsdf_principled_diffuse_setup(_sd.closure[n]);

        }
      }
#  endif

      /* sheen */
      if (diffuse_weight > CLOSURE_WEIGHT_CUTOFF && sheen > CLOSURE_WEIGHT_CUTOFF) {
        float m_cdlum = linear_rgb_to_gray(kg, base_color);
        float3 m_ctint = m_cdlum > 0.0f ?
                             base_color / m_cdlum :
                             make_float3(1.0f, 1.0f, 1.0f);  // normalize lum. to isolate hue+sat

        /* color of the sheen component */
        float3 sheen_color = make_float3(1.0f, 1.0f, 1.0f) * (1.0f - sheen_tint) +
                             m_ctint * sheen_tint;

        float3 sheen_weight = weight * sheen * sheen_color * diffuse_weight;

        int n = bsdf_alloc(

            sd, sizeof_PrincipledSheenBsdf, sheen_weight);


         if (n >= 0) {

          _sd.closure[n].N = N;


          /* setup bsdf */
          _sd.flag |= bsdf_principled_sheen_setup(sd, _sd.closure[n]);
        }
      }

      /* specular reflection */
#  ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_reflective) || !(bool(path_flag & PATH_RAY_DIFFUSE))) {


#  endif
        if (specular_weight > CLOSURE_WEIGHT_CUTOFF &&
            (specular > CLOSURE_WEIGHT_CUTOFF || metallic > CLOSURE_WEIGHT_CUTOFF)) {
          float3 spec_weight = weight * specular_weight;

          int n = bsdf_alloc(

              sd, sizeof_MicrofacetBsdf, spec_weight);



          if (n >= 0) {

            _sd.closure[n].N = N;

            Microfacet_ior(_sd.closure[n]) = (2.0f / (1.0f - safe_sqrtf(0.08f * specular))) - 1.0f;

             Microfacet_T_lval(_sd.closure[n]) =  T; Microfacet_T_assign(_sd.closure[n]) 


  /*_sd.closure[n].extra = extra;*/


            float aspect = safe_sqrtf(1.0f - anisotropic * 0.9f);
            float r2 = roughness * roughness;

            Microfacet_alpha_x(_sd.closure[n]) = r2 / aspect;

            Microfacet_alpha_y(_sd.closure[n]) = r2 * aspect;


            float m_cdlum = 0.3f * base_color.x + 0.6f * base_color.y +
                            0.1f * base_color.z;  // luminance approx.
            float3 m_ctint = m_cdlum > 0.0f ?
                                 base_color / m_cdlum :
                                 make_float3(
                                     0.0f, 0.0f, 0.0f);  // normalize lum. to isolate hue+sat
            float3 tmp_col = make_float3(1.0f, 1.0f, 1.0f) * (1.0f - specular_tint) +
                             m_ctint * specular_tint;

             Microfacet_cspec0_lval(_sd.closure[n]) =  (specular * 0.08f * tmp_col) * (1.0f - metallic) +

                                  base_color * metallic; Microfacet_cspec0_assign(_sd.closure[n]) 

             Microfacet_color_lval(_sd.closure[n]) =  base_color; Microfacet_color_assign(_sd.closure[n]) 


            Microfacet_clearcoat(_sd.closure[n]) = 0.0f;


            /* setup bsdf */
            if (distribution == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID ||
                roughness <= 0.075f) /* use single-scatter GGX */
              _sd.flag |= bsdf_microfacet_ggx_fresnel_setup(_sd.closure[n], sd);
            else /* use multi-scatter GGX */
              _sd.flag |= bsdf_microfacet_multi_ggx_fresnel_setup(_sd.closure[n], sd);
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif

      /* BSDF */
#  ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_reflective) ||

          bool(kernel_data.integrator.caustics_refractive) || !(bool(path_flag & PATH_RAY_DIFFUSE))) {


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
            if (bool(kernel_data.integrator.caustics_reflective) || !(bool(path_flag & PATH_RAY_DIFFUSE)))


#  endif
            {
              int n = bsdf_alloc(

                  sd, sizeof_MicrofacetBsdf, glass_weight * fresnel);

/*extra allocate elim*/

              if (n >= 0) {

                _sd.closure[n].N = N;

                 Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) 


      /*_sd.closure[n].extra = extra;*/


                Microfacet_alpha_x(_sd.closure[n]) = refl_roughness * refl_roughness;

                Microfacet_alpha_y(_sd.closure[n]) = refl_roughness * refl_roughness;

                Microfacet_ior(_sd.closure[n]) = ior;


                 Microfacet_color_lval(_sd.closure[n]) =  base_color; Microfacet_color_assign(_sd.closure[n]) 


                 Microfacet_cspec0_lval(_sd.closure[n]) =  cspec0; Microfacet_cspec0_assign(_sd.closure[n]) 


                Microfacet_clearcoat(_sd.closure[n]) = 0.0f;


                /* setup bsdf */
                _sd.flag |= bsdf_microfacet_ggx_fresnel_setup(_sd.closure[n], sd);
              }
            }

            /* refraction */
#  ifdef _CAUSTICS_TRICKS_
            if (bool(kernel_data.integrator.caustics_refractive) || !(bool(path_flag & PATH_RAY_DIFFUSE)))


#  endif
            {
              int n = bsdf_alloc(

                  sd, sizeof_MicrofacetBsdf, base_color * glass_weight * (1.0f - fresnel));

               if (n >= 0) {

                _sd.closure[n].N = N;

                 Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) Microfacet_extra_NULL(_sd.closure[n]);




                if (distribution == CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID)
                  transmission_roughness = 1.0f - (1.0f - refl_roughness) *
                                                      (1.0f - transmission_roughness);
                else
                  transmission_roughness = refl_roughness;

                Microfacet_alpha_x(_sd.closure[n]) = transmission_roughness * transmission_roughness;

                Microfacet_alpha_y(_sd.closure[n]) = transmission_roughness * transmission_roughness;

                Microfacet_ior(_sd.closure[n]) = ior;


                /* setup bsdf */
                _sd.flag |= bsdf_microfacet_ggx_refraction_setup(_sd.closure[n]);

              }
            }
          }
          else { /* use multi-scatter GGX */
            int n = bsdf_alloc(

                sd, sizeof_MicrofacetBsdf, glass_weight);



            if (n >= 0) {

              _sd.closure[n].N = N;

    /*_sd.closure[n].extra = extra;*/

               Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) 



              Microfacet_alpha_x(_sd.closure[n]) = roughness * roughness;

              Microfacet_alpha_y(_sd.closure[n]) = roughness * roughness;

              Microfacet_ior(_sd.closure[n]) = ior;


               Microfacet_color_lval(_sd.closure[n]) =  base_color; Microfacet_color_assign(_sd.closure[n]) 


               Microfacet_cspec0_lval(_sd.closure[n]) =  cspec0; Microfacet_cspec0_assign(_sd.closure[n]) 


              Microfacet_clearcoat(_sd.closure[n]) = 0.0f;


              /* setup bsdf */
              _sd.flag |= bsdf_microfacet_multi_ggx_glass_fresnel_setup(_sd.closure[n], sd);    
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
          int n = bsdf_alloc(sd, sizeof_MicrofacetBsdf, weight);




          if (n >= 0) {

            _sd.closure[n].N = clearcoat_normal;

             Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) 


            Microfacet_ior(_sd.closure[n]) = 1.5f;

  /*_sd.closure[n].extra = extra;*/


            Microfacet_alpha_x(_sd.closure[n]) = clearcoat_roughness * clearcoat_roughness;

            Microfacet_alpha_y(_sd.closure[n]) = clearcoat_roughness * clearcoat_roughness;


             Microfacet_color_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_color_assign(_sd.closure[n]) 


             Microfacet_cspec0_lval(_sd.closure[n]) =  make_float3(0.04f, 0.04f, 0.04f); Microfacet_cspec0_assign(_sd.closure[n]) 


            Microfacet_clearcoat(_sd.closure[n]) = clearcoat;


            /* setup bsdf */
            _sd.flag |= bsdf_microfacet_ggx_clearcoat_setup(_sd.closure[n], sd);
          }
        }
#  ifdef _CAUSTICS_TRICKS_
      }
#  endif

      break;
    }
#endif /* _PRINCIPLED_ */
    case CLOSURE_BSDF_DIFFUSE_ID: {
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sizeof_OrenNayarBsdf, weight);
      if (n >= 0) {

        getSC().N = N;
        float roughness = param1;

        if (roughness == 0.0f) {
          bsdf_diffuse_setup(_sd.flag,getSC());
          /*conv 18*/
        }
        else {
          OrenNayar_roughness(getSC()) =  roughness;
          bsdf_oren_nayar_setup(_sd.flag,getSC());
        }
      }
      break;
    }

#ifdef _PRINCIPLED_  
    case CLOSURE_BSDF_TRANSLUCENT_ID: {
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sd, sizeof_DiffuseBsdf, weight);



       if (n >= 0) {

        _sd.closure[n].N = N;

        _sd.flag |= bsdf_translucent_setup(_sd.closure[n]);

      }
      break;
    }
    case CLOSURE_BSDF_TRANSPARENT_ID: {
      float3 weight = _sd.svm_closure_weight * mix_weight;
      bsdf_transparent_setup(sd, weight, path_flag);
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
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sd, sizeof_MicrofacetBsdf, weight);



      if (n < 0) 
 {
        break;
      }

      float roughness = sqr(param1);

      _sd.closure[n].N = N;

      Microfacet_ior(_sd.closure[n]) = 0.0f;Microfacet_extra_NULL(_sd.closure[n]);



      if (data_node.y == SVM_STACK_INVALID) {
         Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) 


        Microfacet_alpha_x(_sd.closure[n]) = roughness;

        Microfacet_alpha_y(_sd.closure[n]) = roughness;

      }
      else {
         Microfacet_T_lval(_sd.closure[n]) =  stack_load_float3(stack, data_node.y); Microfacet_T_assign(_sd.closure[n]) 



        /* rotate tangent */
        float rotation = stack_load_float(stack, data_node.z);
        if (rotation != 0.0f)
           Microfacet_T_lval(_sd.closure[n]) =  rotate_around_axis(Microfacet_T(_sd.closure[n]), _sd.closure[n].N, rotation * M_2PI_F); Microfacet_T_assign(_sd.closure[n]) 





        /* compute roughness */
        float anisotropy = clamp(param2, -0.99f, 0.99f);
        if (anisotropy < 0.0f) {
          Microfacet_alpha_x(_sd.closure[n]) = roughness / (1.0f + anisotropy);

          Microfacet_alpha_y(_sd.closure[n]) = roughness * (1.0f + anisotropy);

        }
        else {
          Microfacet_alpha_x(_sd.closure[n]) = roughness * (1.0f - anisotropy);

          Microfacet_alpha_y(_sd.closure[n]) = roughness / (1.0f - anisotropy);

        }
      }

      /* setup bsdf */
      if (type == CLOSURE_BSDF_REFLECTION_ID)
        _sd.flag |= bsdf_reflection_setup(_sd.closure[n]);

      else if (type == CLOSURE_BSDF_MICROFACET_BECKMANN_ID)
        _sd.flag |= bsdf_microfacet_beckmann_setup(_sd.closure[n]);

      else if (type == CLOSURE_BSDF_MICROFACET_GGX_ID)
        _sd.flag |= bsdf_microfacet_ggx_setup(_sd.closure[n]);

      else if (type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID) {
        kernel_assert(stack_valid(data_node.w));
        /*_sd.closure[n].extra = (MicrofacetExtra *)closure_alloc_extra(sd, sizeof_MicrofacetExtra);*/


        /*if (_sd.closure[n].extra) */{

           Microfacet_color_lval(_sd.closure[n]) =  stack_load_float3(stack, data_node.w); Microfacet_color_assign(_sd.closure[n]) 


           Microfacet_cspec0_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_cspec0_assign(_sd.closure[n]) 


          Microfacet_clearcoat(_sd.closure[n]) = 0.0f;

          _sd.flag |= bsdf_microfacet_multi_ggx_setup(_sd.closure[n]);

        }
      }
      else {
        _sd.flag |= bsdf_ashikhmin_shirley_setup(_sd.closure[n]);

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
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sd, sizeof_MicrofacetBsdf, weight);



       if (n >= 0) {

        _sd.closure[n].N = N;

         Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) Microfacet_extra_NULL(_sd.closure[n]);




        float eta = fmaxf(param2, 1e-5f);
        eta = (bool(_sd.flag & SD_BACKFACING)
) ? 1.0f / eta : eta;

        /* setup bsdf */
        if (type == CLOSURE_BSDF_REFRACTION_ID) {
          Microfacet_alpha_x(_sd.closure[n]) = 0.0f;

          Microfacet_alpha_y(_sd.closure[n]) = 0.0f;

          Microfacet_ior(_sd.closure[n]) = eta;


          _sd.flag |= bsdf_refraction_setup(_sd.closure[n]);

        }
        else {
          float roughness = sqr(param1);
          Microfacet_alpha_x(_sd.closure[n]) = roughness;

          Microfacet_alpha_y(_sd.closure[n]) = roughness;

          Microfacet_ior(_sd.closure[n]) = eta;


          if (type == CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID)
            _sd.flag |= bsdf_microfacet_beckmann_refraction_setup(_sd.closure[n]);

          else
            _sd.flag |= bsdf_microfacet_ggx_refraction_setup(_sd.closure[n]);

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
      float3 weight = _sd.svm_closure_weight * mix_weight;

      /* index of refraction */
      float eta = fmaxf(param2, 1e-5f);
      eta = (bool(_sd.flag & SD_BACKFACING)
) ? 1.0f / eta : eta;

      /* fresnel */
      float cosNO = dot(N, _sd.I);
      float fresnel = fresnel_dielectric_cos(cosNO, eta);
      float roughness = sqr(param1);

      /* reflection */
#ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_reflective) || !(bool(path_flag & PATH_RAY_DIFFUSE)))


#endif
      {
        int n = bsdf_alloc(

            sd, sizeof_MicrofacetBsdf, weight * fresnel);


         if (n >= 0) {

          _sd.closure[n].N = N;

           Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) Microfacet_extra_NULL(_sd.closure[n]);



          svm_node_glass_setup(sd,_sd.closure[n], int(type), float(eta), float(roughness), false);
        }
      }

      /* refraction */
#ifdef _CAUSTICS_TRICKS_
      if (bool(kernel_data.integrator.caustics_refractive) || !(bool(path_flag & PATH_RAY_DIFFUSE)))


#endif
      {
        int n = bsdf_alloc(

            sd, sizeof_MicrofacetBsdf, weight * (1.0f - fresnel));


         if (n >= 0) {

          _sd.closure[n].N = N;

           Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) Microfacet_extra_NULL(_sd.closure[n]);



          svm_node_glass_setup(sd,    _sd.closure[n], int(type), eta, roughness, true);
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
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sd, sizeof_MicrofacetBsdf, weight);


      if (n < 0) 
 {
        break;
      }



      _sd.closure[n].N = N;



       Microfacet_T_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_T_assign(_sd.closure[n]) 



      float roughness = sqr(param1);
      Microfacet_alpha_x(_sd.closure[n]) = roughness;

      Microfacet_alpha_y(_sd.closure[n]) = roughness;

      float eta = fmaxf(param2, 1e-5f);
      Microfacet_ior(_sd.closure[n]) = (bool(_sd.flag & SD_BACKFACING)
) ? 1.0f / eta : eta;


      kernel_assert(stack_valid(data_node.z));
       Microfacet_color_lval(_sd.closure[n]) =  stack_load_float3(stack, data_node.z); Microfacet_color_assign(_sd.closure[n]) 


       Microfacet_cspec0_lval(_sd.closure[n]) =  make_float3(0.0f, 0.0f, 0.0f); Microfacet_cspec0_assign(_sd.closure[n]) 


      Microfacet_clearcoat(_sd.closure[n]) = 0.0f;


      /* setup bsdf */
      _sd.flag |= bsdf_microfacet_multi_ggx_glass_setup(_sd.closure[n]);

      break;
    }
    case CLOSURE_BSDF_ASHIKHMIN_VELVET_ID: {
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sd, sizeof_VelvetBsdf, weight);



       if (n >= 0) {

        _sd.closure[n].N = N;


        Velvet_sigma(_sd.closure[n]) = saturate(param1);

        _sd.flag |= bsdf_ashikhmin_velvet_setup(_sd.closure[n]);

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
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bsdf_alloc(sd, sizeof_ToonBsdf, weight);



       if (n >= 0) {

        _sd.closure[n].N = N;

        Toon_size(_sd.closure[n]) = param1;

        Toon_smooth(_sd.closure[n]) = param2;


        if (type == CLOSURE_BSDF_DIFFUSE_TOON_ID)
          _sd.flag |= bsdf_diffuse_toon_setup(_sd.closure[n]);

        else
          _sd.flag |= bsdf_glossy_toon_setup(_sd.closure[n]);

      }
      break;
    }
#ifdef _HAIR_
    case CLOSURE_BSDF_HAIR_PRINCIPLED_ID: {
      uint4 data_node2 = read_node(kg, offset);
      uint4 data_node3 = read_node(kg, offset);
      uint4 data_node4 = read_node(kg, offset);

      float3 weight = _sd.svm_closure_weight * mix_weight;

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

        _sd.closure[n].N = N;

        _sd.closure[n].v = roughness;

        _sd.closure[n].s = radial_roughness;

        _sd.closure[n].m0_roughness = m0_roughness;

        _sd.closure[n].alpha = alpha;

        _sd.closure[n].eta = ior;

  


        switch (parametrization) {
          case NODE_PRINCIPLED_HAIR_DIRECT_ABSORPTION: {
            float3 absorption_coefficient = stack_load_float3(stack, absorption_coefficient_ofs);
            PrincipledHair_sigma(_sd.closure[n]) = absorption_coefficient;

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

PrincipledHair_sigma(_sd.closure[n]) = melanin_sigma + tint_sigma;

            break;
          }
          case NODE_PRINCIPLED_HAIR_REFLECTANCE: {
            float3 color = stack_load_float3(stack, color_ofs);
            PrincipledHair_sigma(_sd.closure[n]) =  bsdf_principled_hair_sigma_from_reflectance(color, radial_roughness);

            break;
          }
          default: {
            /* Fallback to brownish hair, same as defaults for melanin. */
            kernel_assert(!"Invalid Principled Hair parametrization!");
           PrincipledHair_sigma(_sd.closure[n])  = bsdf_principled_hair_sigma_from_concentration(0.0f, 0.8054375f);

            break;
          }
        }

        _sd.flag |= bsdf_principled_hair_setup(sd,_sd.closure[n]);
      }
      break;
    }
    case CLOSURE_BSDF_HAIR_REFLECTION_ID:
    case CLOSURE_BSDF_HAIR_TRANSMISSION_ID: {
      float3 weight = _sd.svm_closure_weight * mix_weight;

      int n = bsdf_alloc(sd, sizeof_HairBsdf, weight);



       if (n >= 0) {

        _sd.closure[n].N = N;

        _sd.closure[n].roughness1 = param1;

        _sd.closure[n].roughness2 = param2;

        _sd.closure[n].offset = -stack_load_float(stack, data_node.z);


        if (stack_valid(data_node.y)) {
           Microfacet_T_lval(_sd.closure[n]) =  normalize(stack_load_float3(stack, data_node.y)); Microfacet_T_assign(_sd.closure[n]) 


        }
        else if (!(bool(_sd.type & PRIMITIVE_ALL_CURVE))) {

           Microfacet_T_lval(_sd.closure[n]) =  normalize(_sd.dPdv); Microfacet_T_assign(_sd.closure[n]) 


          _sd.closure[n].offset = 0.0f;

        }
        else
           Microfacet_T_lval(_sd.closure[n]) =  normalize(_sd.dPdu); Microfacet_T_assign(_sd.closure[n]) 



        if (type == CLOSURE_BSDF_HAIR_REFLECTION_ID) {
          _sd.flag |= bsdf_hair_reflection_setup(_sd.closure[n]);

        }
        else {
          _sd.flag |= bsdf_hair_transmission_setup(_sd.closure[n]);

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
      float3 weight = _sd.svm_closure_weight * mix_weight;
      int n = bssrdf_alloc(sd, weight);

      if (n >=0) {
        /* disable in_rsv case of diffuse ancestor, can't see it well then and
         * adds considerably noise due to probabilities of continuing path
         * getting lower and lower */
        if (bool(path_flag & PATH_RAY_DIFFUSE_ANCESTOR))

          param1 = 0.0f;

        Bssrdf_radius_lval(_sd.closure[n]) = stack_load_float3(stack, data_node.z) * param1; Bssrdf_radius_assign(_sd.closure[n]);
        Bssrdf_albedo_lval(_sd.closure[n]) = _sd.svm_closure_weight;Bssrdf_albedo_assign(_sd.closure[n]);
        Bssrdf_texture_blur(_sd.closure[n]) = param2;
        Bssrdf_sharpness(_sd.closure[n]) = stack_load_float(stack, data_node.w);
        _sd.closure[n].N = N;
        Bssrdf_roughness(_sd.closure[n]) = 0.0f;
        _sd.flag |= bssrdf_setup(sd, _sd.closure[n], ClosureType(type));

      }

      break;
    }
#endif
#endif
    default:
      break;
  }
}


void svm_node_geometry( uint type, uint out_offset)
{
  float3 data;
  switch (type) {
    case NODE_GEOM_P:
      data = _sd.P;
      break;
    case NODE_GEOM_N:
      data = _sd.N;
      break;
#ifdef _DPDU_
    case NODE_GEOM_T:
      //data = primitive_tangent(sd);
      break;
#endif
    case NODE_GEOM_I:
      data = _sd.I;
      break;
    case NODE_GEOM_Ng:
      data = _sd.Ng;
      break;
    case NODE_GEOM_uv:
      data = make_float3(_sd.u, _sd.v, 0.0f);
      break;
    default:
      data = make_float3(0.0f, 0.0f, 0.0f);
  }

  stack_store_float3(out_offset, data);
}


#define svm_node_value_f(ivalue,out_offset) stack_store_float(out_offset, _uint_as_float(ivalue));

/* Main Interpreter Loop */
ccl_device_noinline void svm_eval_nodes(
                                        ShaderType type,
                                        int path_flag)
{

  int offset = int(_sd.shader & SHADER_MASK);

  while (true) {
    uint4 node = read_node(offset);

    switch (node.x) {
      case NODE_END:
        return;
#if NODES_GROUP(NODE_GROUP_LEVEL_0)
      case NODE_SHADER_JUMP: {
        //if (type == SHADER_TYPE_SURFACE)
          offset = int(node.y);
        /*
        else if (type == SHADER_TYPE_VOLUME)
          offset = node.z;
        else if (type == SHADER_TYPE_DISPLACEMENT)
          offset = node.w;
        else
          return;
        */
        break;
      }
      case NODE_CLOSURE_BSDF:
        svm_node_closure_bsdf(node, type, path_flag, offset);
        break;
       /* 
      case NODE_CLOSURE_EMISSION:
        svm_node_closure_emission(sd, stack, node);
        break;
      case NODE_CLOSURE_BACKGROUND:
        svm_node_closure_background(sd, stack, node);
        break;
        */
      case NODE_CLOSURE_SET_WEIGHT:
        svm_node_closure_set_weight(node.y, node.z, node.w);
        break;
    /*
      case NODE_CLOSURE_WEIGHT:
        svm_node_closure_weight(sd, stack, node.y);
        break;
      case NODE_EMISSION_WEIGHT:
        svm_node_emission_weight(kg, sd, stack, node);
        break;
      case NODE_MIX_CLOSURE:
        svm_node_mix_closure(sd, stack, node);
        break;
    */
      case NODE_JUMP_IF_ZERO:
        if (stack_load_float(node.z) == 0.0f)
          offset +=  int(node.y);
        break;
      case NODE_JUMP_IF_ONE:
        if (stack_load_float(node.z) == 1.0f)
          offset +=  int(node.y);
        break;
      case NODE_GEOMETRY:
        svm_node_geometry(node.y, node.z);
        break;
    /*    
      case NODE_CONVERT:
        svm_node_convert(kg, sd, stack, node.y, node.z, node.w);
        break;
      case NODE_TEX_COORD:
        svm_node_tex_coord(kg, sd, path_flag, stack, node, &offset);
        break;
    */
      case NODE_VALUE_F:
        svm_node_value_f(node.y, node.z);
        break;

#endif /* NODES_GROUP(NODE_GROUP_LEVEL_0) */

#if NODES_GROUP__
#if NODES_GROUP(NODE_GROUP_LEVEL_0)
      case NODE_VALUE_V:
        svm_node_value_v(kg, sd, stack, node.y, &offset);
        break;
      case NODE_ATTR:
        svm_node_attr(kg, sd, stack, node);
        break;
      case NODE_VERTEX_COLOR:
        svm_node_vertex_color(kg, sd, stack, node.y, node.z, node.w);
        break;
#  if NODES_FEATURE(NODE_FEATURE_BUMP)
      case NODE_GEOMETRY_BUMP_DX:
        svm_node_geometry_bump_dx(kg, sd, stack, node.y, node.z);
        break;
      case NODE_GEOMETRY_BUMP_DY:
        svm_node_geometry_bump_dy(kg, sd, stack, node.y, node.z);
        break;
      case NODE_SET_DISPLACEMENT:
        svm_node_set_displacement(kg, sd, stack, node.y);
        break;
      case NODE_DISPLACEMENT:
        svm_node_displacement(kg, sd, stack, node);
        break;
      case NODE_VECTOR_DISPLACEMENT:
        svm_node_vector_displacement(kg, sd, stack, node, &offset);
        break;
#  endif /* NODES_FEATURE(NODE_FEATURE_BUMP) */
      case NODE_TEX_IMAGE:
        svm_node_tex_image(kg, sd, stack, node, &offset);
        break;
      case NODE_TEX_IMAGE_BOX:
        svm_node_tex_image_box(kg, sd, stack, node);
        break;
      case NODE_TEX_NOISE:
        svm_node_tex_noise(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
#  if NODES_FEATURE(NODE_FEATURE_BUMP)
      case NODE_SET_BUMP:
        svm_node_set_bump(kg, sd, stack, node);
        break;
      case NODE_ATTR_BUMP_DX:
        svm_node_attr_bump_dx(kg, sd, stack, node);
        break;
      case NODE_ATTR_BUMP_DY:
        svm_node_attr_bump_dy(kg, sd, stack, node);
        break;
      case NODE_VERTEX_COLOR_BUMP_DX:
        svm_node_vertex_color_bump_dx(kg, sd, stack, node.y, node.z, node.w);
        break;
      case NODE_VERTEX_COLOR_BUMP_DY:
        svm_node_vertex_color_bump_dy(kg, sd, stack, node.y, node.z, node.w);
        break;
      case NODE_TEX_COORD_BUMP_DX:
        svm_node_tex_coord_bump_dx(kg, sd, path_flag, stack, node, &offset);
        break;
      case NODE_TEX_COORD_BUMP_DY:
        svm_node_tex_coord_bump_dy(kg, sd, path_flag, stack, node, &offset);
        break;
      case NODE_CLOSURE_SET_NORMAL:
        svm_node_set_normal(kg, sd, stack, node.y, node.z);
        break;
#    if NODES_FEATURE(NODE_FEATURE_BUMP_STATE)
      case NODE_ENTER_BUMP_EVAL:
        svm_node_enter_bump_eval(kg, sd, stack, node.y);
        break;
      case NODE_LEAVE_BUMP_EVAL:
        svm_node_leave_bump_eval(kg, sd, stack, node.y);
        break;
#    endif /* NODES_FEATURE(NODE_FEATURE_BUMP_STATE) */
#  endif   /* NODES_FEATURE(NODE_FEATURE_BUMP) */
      case NODE_HSV:
        svm_node_hsv(kg, sd, stack, node, &offset);
        break;
#endif /* NODES_GROUP(NODE_GROUP_LEVEL_0) */

#if NODES_GROUP(NODE_GROUP_LEVEL_1)
      case NODE_CLOSURE_HOLDOUT:
        svm_node_closure_holdout(sd, stack, node);
        break;
      case NODE_FRESNEL:
        svm_node_fresnel(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_LAYER_WEIGHT:
        svm_node_layer_weight(sd, stack, node);
        break;
#  if NODES_FEATURE(NODE_FEATURE_VOLUME)
      case NODE_CLOSURE_VOLUME:
        svm_node_closure_volume(kg, sd, stack, node, type);
        break;
      case NODE_PRINCIPLED_VOLUME:
        svm_node_principled_volume(kg, sd, stack, node, type, path_flag, &offset);
        break;
#  endif /* NODES_FEATURE(NODE_FEATURE_VOLUME) */
      case NODE_MATH:
        svm_node_math(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_VECTOR_MATH:
        svm_node_vector_math(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_RGB_RAMP:
        svm_node_rgb_ramp(kg, sd, stack, node, &offset);
        break;
      case NODE_GAMMA:
        svm_node_gamma(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_BRIGHTCONTRAST:
        svm_node_brightness(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_LIGHT_PATH:
        svm_node_light_path(sd, state, stack, node.y, node.z, path_flag);
        break;
      case NODE_OBJECT_INFO:
        svm_node_object_info(kg, sd, stack, node.y, node.z);
        break;
      case NODE_PARTICLE_INFO:
        svm_node_particle_info(kg, sd, stack, node.y, node.z);
        break;
#  if defined(__HAIR__) && NODES_FEATURE(NODE_FEATURE_HAIR)
      case NODE_HAIR_INFO:
        svm_node_hair_info(kg, sd, stack, node.y, node.z);
        break;
#  endif /* NODES_FEATURE(NODE_FEATURE_HAIR) */
#endif   /* NODES_GROUP(NODE_GROUP_LEVEL_1) */

#if NODES_GROUP(NODE_GROUP_LEVEL_2)
      case NODE_TEXTURE_MAPPING:
        svm_node_texture_mapping(kg, sd, stack, node.y, node.z, &offset);
        break;
      case NODE_MAPPING:
        svm_node_mapping(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_MIN_MAX:
        svm_node_min_max(kg, sd, stack, node.y, node.z, &offset);
        break;
      case NODE_CAMERA:
        svm_node_camera(kg, sd, stack, node.y, node.z, node.w);
        break;
      case NODE_TEX_ENVIRONMENT:
        svm_node_tex_environment(kg, sd, stack, node);
        break;
      case NODE_TEX_SKY:
        svm_node_tex_sky(kg, sd, stack, node, &offset);
        break;
      case NODE_TEX_GRADIENT:
        svm_node_tex_gradient(sd, stack, node);
        break;
      case NODE_TEX_VORONOI:
        svm_node_tex_voronoi(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_TEX_MUSGRAVE:
        svm_node_tex_musgrave(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_TEX_WAVE:
        svm_node_tex_wave(kg, sd, stack, node, &offset);
        break;
      case NODE_TEX_MAGIC:
        svm_node_tex_magic(kg, sd, stack, node, &offset);
        break;
      case NODE_TEX_CHECKER:
        svm_node_tex_checker(kg, sd, stack, node);
        break;
      case NODE_TEX_BRICK:
        svm_node_tex_brick(kg, sd, stack, node, &offset);
        break;
      case NODE_TEX_WHITE_NOISE:
        svm_node_tex_white_noise(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_NORMAL:
        svm_node_normal(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_LIGHT_FALLOFF:
        svm_node_light_falloff(sd, stack, node);
        break;
      case NODE_IES:
        svm_node_ies(kg, sd, stack, node, &offset);
        break;
#endif /* NODES_GROUP(NODE_GROUP_LEVEL_2) */

#if NODES_GROUP(NODE_GROUP_LEVEL_3)
      case NODE_RGB_CURVES:
      case NODE_VECTOR_CURVES:
        svm_node_curves(kg, sd, stack, node, &offset);
        break;
      case NODE_TANGENT:
        svm_node_tangent(kg, sd, stack, node);
        break;
      case NODE_NORMAL_MAP:
        svm_node_normal_map(kg, sd, stack, node);
        break;
      case NODE_INVERT:
        svm_node_invert(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_MIX:
        svm_node_mix(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_SEPARATE_VECTOR:
        svm_node_separate_vector(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_COMBINE_VECTOR:
        svm_node_combine_vector(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_SEPARATE_HSV:
        svm_node_separate_hsv(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_COMBINE_HSV:
        svm_node_combine_hsv(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_VECTOR_ROTATE:
        svm_node_vector_rotate(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_VECTOR_TRANSFORM:
        svm_node_vector_transform(kg, sd, stack, node);
        break;
      case NODE_WIREFRAME:
        svm_node_wireframe(kg, sd, stack, node);
        break;
      case NODE_WAVELENGTH:
        svm_node_wavelength(kg, sd, stack, node.y, node.z);
        break;
      case NODE_BLACKBODY:
        svm_node_blackbody(kg, sd, stack, node.y, node.z);
        break;
      case NODE_MAP_RANGE:
        svm_node_map_range(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_CLAMP:
        svm_node_clamp(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
#  ifdef __SHADER_RAYTRACE__
      case NODE_BEVEL:
        svm_node_bevel(kg, sd, state, stack, node);
        break;
      case NODE_AMBIENT_OCCLUSION:
        svm_node_ao(kg, sd, state, stack, node);
        break;
#  endif /* __SHADER_RAYTRACE__ */
#endif   /* NODES_GROUP(NODE_GROUP_LEVEL_3) */

#if NODES_GROUP(NODE_GROUP_LEVEL_4)
#  if NODES_FEATURE(NODE_FEATURE_VOLUME)
      case NODE_TEX_VOXEL:
        svm_node_tex_voxel(kg, sd, stack, node, &offset);
        break;
#  endif /* NODES_FEATURE(NODE_FEATURE_VOLUME) */
      case NODE_AOV_START:
        if (!svm_node_aov_check(state, buffer)) {
          return;
        }
        break;
      case NODE_AOV_COLOR:
        svm_node_aov_color(kg, sd, stack, node, buffer);
        break;
      case NODE_AOV_VALUE:
        svm_node_aov_value(kg, sd, stack, node, buffer);
        break;
#endif /* NODES_GROUP(NODE_GROUP_LEVEL_4) */
#endif

      default:
        
        return;
    }
 
    

     
  }


}
#define CALL_TYPE_lamp_light_eval 1234
void main()
{
  alloc = false;
  int max_closures;

  if (bool(args.path_state & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION))) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }

  _sd.num_closure = 0;
  _sd.num_closure_left = max_closures;
  svm_eval_nodes(SHADER_TYPE_SURFACE, args.path_state);

}