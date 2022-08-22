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
#define BSDF_VEC3(offset,v) {nio.data[offset]=v.x;nio.data[offset+1]=v.y;nio.data[offset+2]=v.z;}

#define BSSRDF_RADIUS_OFFSET 4
#define BSSRDF_RADIUS(rad) stack_load_float3_nio(rad,BSSRDF_RADIUS_OFFSET)
#define BSSRDF_MIX_OFFSET 15
#define BSSRDF_MIX(mix) nio.data[BSSRDF_MIX_OFFSET] = mix
#define BSSRDF_SHARP_OFFSET 16
#define BSSRDF_SHARP(sharp) nio.data[BSSRDF_SHARP_OFFSET] = sharp

#define BSDF_SD(_caus) {\
nio.offset  =  int(path_flag);\
nio.type    =  uint(type);\
uint  caus = uint(_caus);\
nio.data[0] =  uintBitsToFloat(( uint(sd.num_closure_left)&0xffff) |  (caus << 16u) );\
nio.data[1] =  uintBitsToFloat(( uint(sd.num_closure)&0xffff) |  (rec_num << 16u) );\
nio.data[2] =  intBitsToFloat(sd.alloc_offset);\
nio.data[3] =  intBitsToFloat(sd.flag);\
}

#define BSDF_SD_I_OFFSET 4
#define BSDF_SD_I(I) BSDF_VEC3(BSDF_SD_I_OFFSET,I)

#define BSDF_STACK_PARAM_OFFSET 7
#define BSDF_STACK_LOAD_PARAM(N,p1,p2) {\
BSDF_VEC3(BSDF_STACK_PARAM_OFFSET,N);\
nio.data[BSDF_STACK_PARAM_OFFSET+3] =  p1;nio.data[BSDF_STACK_PARAM_OFFSET+4] =  p2;\
}

#define BSDF_WEIGHT_OFFSET 12
#define BSDF_WEIGHT(w) { vec3 v = (w).xyz;BSDF_VEC3(BSDF_WEIGHT_OFFSET,v)}

#define BSDF_DISNEY_PARAM_OFFSET 15
#define BSDF_DISNEY_PARAM(data_node,data_node2) { \
    uint specular_offset, roughness_offset, specular_tint_offset, anisotropic_offset,sheen_offset, sheen_tint_offset, clearcoat_offset, clearcoat_roughness_offset,eta_offset, transmission_offset, anisotropic_rotation_offset,transmission_roughness_offset;\
    svm_unpack_node_uchar4(data_node.z,(specular_offset),(roughness_offset),(specular_tint_offset),(anisotropic_offset));\
    svm_unpack_node_uchar4(data_node.w,(sheen_offset), (sheen_tint_offset), (clearcoat_offset),(clearcoat_roughness_offset));\
    svm_unpack_node_uchar4(data_node2.x, (eta_offset), (transmission_offset), (anisotropic_rotation_offset),(transmission_roughness_offset));\
 nio.data[BSDF_DISNEY_PARAM_OFFSET]  = stack_load_float( specular_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+1]  = stack_load_float( roughness_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+2]  = stack_load_float( specular_tint_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+3]  = stack_load_float( anisotropic_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+4]  = stack_load_float( sheen_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+5]  = stack_load_float( sheen_tint_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+6]  =stack_load_float( clearcoat_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+7]  = stack_load_float( clearcoat_roughness_offset);\
 nio.data[BSDF_DISNEY_PARAM_OFFSET+8]  = stack_load_float( transmission_offset);\
nio.data[BSDF_DISNEY_PARAM_OFFSET+9]  = stack_load_float( anisotropic_rotation_offset);\
nio.data[BSDF_DISNEY_PARAM_OFFSET+10]  = stack_load_float( transmission_roughness_offset);\
nio.data[BSDF_DISNEY_PARAM_OFFSET+11]  = fmaxf(stack_load_float( eta_offset), 1e-5f);\
nio.data[BSDF_DISNEY_PARAM_OFFSET+12]  = uintBitsToFloat(ClosureType(data_node2.y));\
nio.data[BSDF_DISNEY_PARAM_OFFSET+13]  = uintBitsToFloat(ClosureType(data_node2.z));\
}  


#define BSDF_T_OFFSET 29
#define BSDF_T(offset){ float3 T = stack_load_float3(offset);BSDF_VEC3(BSDF_T_OFFSET,T);}

#define BSDF_STACK_COLOR_OFFSET 32
#define BSDF_BASE_COLOR(offset) {\
      uint4 data_base_color = read_node(offset);\
      float3 v = stack_valid(data_base_color.x) ?\
                              stack_load_float3(data_base_color.x) :\
                              make_float3(_uint_as_float(data_base_color.y),\
                                          _uint_as_float(data_base_color.z),\
                                          _uint_as_float(data_base_color.w));\
     BSDF_VEC3(BSDF_STACK_COLOR_OFFSET,v)\
     nio.data[BSDF_STACK_COLOR_OFFSET+3]=   linear_rgb_to_gray(v);\
}

#define BSDF_STACK_CNORMAL_OFFSET 36
#define BSDF_CLEAR_NORMAL(node) {\
      float3 clearcoat_normal = stack_valid(node.x) ?\
                                stack_load_float3(node.x) :\
                                sd.N;\
     BSDF_VEC3(BSDF_STACK_CNORMAL_OFFSET,clearcoat_normal)\
}

#define BSDF_STACK_SUBSUF_OFFSET 39
#define BSDF_SUBSUF(node) {\
     float3 subsurface_radius = stack_valid(node.y) ?\
                                    stack_load_float3(node.y) :\
                                   make_float3(1.0f, 1.0f, 1.0f);\
     BSDF_VEC3(BSDF_STACK_SUBSUF_OFFSET,subsurface_radius)\
     uint4 data_subsurface_color = read_node(offset);\
     float3 subsurface_color      = stack_valid(data_subsurface_color.x) ?\
                                    stack_load_float3(data_subsurface_color.x) :\
                                    make_float3(_uint_as_float(data_subsurface_color.y),\
                                                _uint_as_float(data_subsurface_color.z),\
                                                _uint_as_float(data_subsurface_color.w));\
     BSDF_VEC3( (BSDF_STACK_SUBSUF_OFFSET+3) ,subsurface_color)\
}


#define BSDF_RETERN {\
    GSD.num_closure_left = floatBitsToInt(nio.data[0]);\
    GSD.num_closure     = floatBitsToInt(nio.data[1]);\
    GSD.alloc_offset= floatBitsToInt(nio.data[2]); \
    GSD.flag= floatBitsToInt(nio.data[3]);\
}
#define BSDF_RETERN_TRANS  GSD.closure_transparent_extinction = vec4(nio.data[4],nio.data[5],nio.data[6],0 );
#define BSDF_SET_TRANS  nio.data[4] = GSD.closure_transparent_extinction.x;nio.data[5] =GSD.closure_transparent_extinction.y;nio.data[6] = GSD.closure_transparent_extinction.z;

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

#ifdef _CAUSTICS_TRICKS_
bool caustics = bool(kernel_data.integrator.caustics_reflective);
if(type == CLOSURE_BSDF_GLOSSY_TOON_ID){
      if (!caustics && (bool( uint(path_flag) & PATH_RAY_DIFFUSE)))return;
}
#else
bool caustics = true;
#endif

#define _PRINCIPLED_ 

BSDF_SD(caustics)
BSDF_STACK_LOAD_PARAM(N,param1,param2);
BSDF_WEIGHT(sd.svm_closure_weight * mix_weight)
bool exec  = false;
bool trans = false;

  switch (type) {
#ifdef _PRINCIPLED_
    case CLOSURE_BSDF_PRINCIPLED_ID: {


uint4 data_node2 = read_node(offset);
BSDF_SD_I(GSD.I);
BSDF_T(data_node.y);
      // get the base color
BSDF_BASE_COLOR(offset) 
uint4  data_cn_ssr      = read_node(offset);
      // get the additional clearcoat normal and subsurface scattering radius
BSDF_CLEAR_NORMAL(data_cn_ssr ) 
BSDF_SUBSUF(data_cn_ssr )

      // get Disney principled parameters
BSDF_DISNEY_PARAM(data_node,data_node2);
exec = true;
break;
}

#endif /* _PRINCIPLED_ */
case CLOSURE_BSDF_DIFFUSE_ID:
case CLOSURE_BSDF_TRANSLUCENT_ID:     
case CLOSURE_BSDF_GLOSSY_TOON_ID:
case CLOSURE_BSDF_DIFFUSE_TOON_ID:
case CLOSURE_BSDF_ASHIKHMIN_VELVET_ID:{
  exec = true;
  break;
}
case CLOSURE_BSDF_TRANSPARENT_ID:{
  exec  = true;
  trans = true;
  BSDF_SET_TRANS
  break;
}    
case CLOSURE_BSDF_REFRACTION_ID:
case CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID:
case CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID:{
#ifdef _CAUSTICS_TRICKS_
  if (!caustics && (bool(path_flag & PATH_RAY_DIFFUSE)))break;
#endif
  exec  = true;
  break;
}
case CLOSURE_BSDF_SHARP_GLASS_ID:
case CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID:
case CLOSURE_BSDF_MICROFACET_BECKMANN_GLASS_ID: 
{
#ifdef _CAUSTICS_TRICKS_
  if (!caustics && (bool(path_flag & PATH_RAY_DIFFUSE)))break;
#endif
  BSDF_SD_I(sd.I) 
  exec  = true;
  break;
}
case CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID:
{
#ifdef _CAUSTICS_TRICKS_
  if (!caustics && (bool(path_flag & PATH_RAY_DIFFUSE)))break;
#endif
  kernel_assert("assert rcall4 860 ",stack_valid(data_node.z));
  float3 color = stack_load_float3(data_node.z);
  BSDF_VEC3(BSDF_STACK_COLOR_OFFSET,color);
  exec  = true;
  break;
}
case CLOSURE_BSDF_REFLECTION_ID:
case CLOSURE_BSDF_MICROFACET_GGX_ID:
case CLOSURE_BSDF_MICROFACET_BECKMANN_ID:
case CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID:
case CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID:
{
#ifdef _CAUSTICS_TRICKS_
  if (!caustics && (bool(path_flag & PATH_RAY_DIFFUSE)))break;
#endif
  nio.data[BSDF_DISNEY_PARAM_OFFSET+12]  = uintBitsToFloat(ClosureType(data_node.y));
  float3 v = stack_load_float3(data_node.y);
  BSDF_VEC3(BSDF_T_OFFSET,v);
  nio.data[BSDF_DISNEY_PARAM_OFFSET]     = stack_load_float(data_node.z);
  if (type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID) {
      kernel_assert("assert svm_closure 323 ",stack_valid(data_node.w));
      v = stack_load_float3(data_node.w);
      BSDF_VEC3(BSDF_STACK_COLOR_OFFSET,v);
  }
  exec  = true;
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
      BSSRDF_RADIUS(data_node.z) ;
      BSSRDF_MIX(mix_weight) ;
      BSSRDF_SHARP(stack_load_float( data_node.w));
      exec  = true;
      break;
    }
#endif
#endif
    default:
      break;
  }

if(exec){
int n = sd.num_closure;
  EXECUTION_BSDF;
  BSDF_RETERN

  if(trans){BSDF_RETERN_TRANS}
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

/* (Bump) normal */
ccl_device void svm_node_set_normal(uint in_direction, uint out_normal)
{
  float3 normal = stack_load_float3(in_direction);
  sd.N = normal;
  stack_store_float3(out_normal, normal);
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


#endif
#endif


#ifdef NODE_Callee



#endif


CCL_NAMESPACE_END




#endif