/*
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

#ifndef _BSDF_OREN_NAYAR_H_
#define _BSDF_OREN_NAYAR_H_


CCL_NAMESPACE_BEGIN
#define sizeof_OrenNayarBsdf 12

#define OrenNayarBsdf ShaderClosure
#define OrenNayar_roughness(bsdf) bsdf.data[0]
#define OrenNayar_a(bsdf) bsdf.data[1]
#define OrenNayar_b(bsdf) bsdf.data[2]





#ifdef  SVM_TYPE_SETUP
ccl_device int bsdf_oren_nayar_setup()
{
  float sigma = OrenNayar_roughness(DEF_BSDF);

  DEF_BSDF.type = CLOSURE_BSDF_OREN_NAYAR_ID;

  sigma = saturate(sigma);

  float div = 1.0f / (M_PI_F + ((3.0f * M_PI_F - 4.0f) / 6.0f) * sigma);

  OrenNayar_a(DEF_BSDF) = 1.0f * div;
  OrenNayar_b(DEF_BSDF) = sigma * div;

  return int(SD_BSDF | SD_BSDF_HAS_EVAL);

}
#else

/*
typedef ccl_addr_space struct OrenNayarBsdf {
  SHADER_CLOSURE_BASE;

  float roughness;
  float a;
  float b;
} OrenNayarBsdf;

static_assert(sizeof(ShaderClosure) >= sizeof(OrenNayarBsdf), "OrenNayarBsdf is too large!");
*/
ccl_device float3 bsdf_oren_nayar_get_intensity(
                                                float3 n,
                                                float3 v,
                                                float3 l)
{
  
  float nl = max(dot3(n, l), 0.0f);
  float nv = max(dot3(n, v), 0.0f);
  float t = dot3(l, v) - nl * nv;

  if (t > 0.0f)
    t /= (max(nl, nv) + FLT_MIN);
  float is = nl * (OrenNayar_a(DEF_BSDF) + OrenNayar_b(DEF_BSDF) * t);
  return make_float3(is, is, is);
}

ccl_device bool bsdf_oren_nayar_merge(in ShaderClosure bsdf_a, in ShaderClosure bsdf_b)

{
  
  

  return (isequal_float3(bsdf_a.N, bsdf_b.N)) && (OrenNayar_roughness(bsdf_a) == OrenNayar_roughness(bsdf_b));
}

ccl_device float3 bsdf_oren_nayar_eval_reflect(
                                               const float3 I,
                                               const float3 omega_in,
                                               inout float pdf)
{
  
  if (dot3(DEF_BSDF.N, omega_in) > 0.0f) {
    pdf = 0.5f * M_1_PI_F;
    return bsdf_oren_nayar_get_intensity(DEF_BSDF.N, I, omega_in);
  }
  else {
    pdf = 0.0f;
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

ccl_device float3 bsdf_oren_nayar_eval_transmit(
                                                const float3 I,
                                                const float3 omega_in,
                                                inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device int bsdf_oren_nayar_sample(
                                      float3 Ng,
                                      float3 I,
                                      float3 dIdx,
                                      float3 dIdy,
                                      float randu,
                                      float randv,
                                      inout float3 eval,
                                      inout float3 omega_in,
                                      inout float3 domega_in_dx,
                                      inout float3 domega_in_dy,
                                      inout float pdf)
{
  
  sample_uniform_hemisphere(DEF_BSDF.N, randu, randv, omega_in, pdf);

  if (dot3(Ng, omega_in) > 0.0f) {
    eval = bsdf_oren_nayar_get_intensity( DEF_BSDF.N, I, omega_in);



#ifdef _RAY_DIFFERENTIALS_
    // TODO: find a better approximation for the bounce
    domega_in_dx = (2.0f * dot3(DEF_BSDF.N, dIdx)) * DEF_BSDF.N - dIdx;
    domega_in_dy = (2.0f * dot3(DEF_BSDF.N, dIdy)) * DEF_BSDF.N - dIdy;
#endif
  }
  else {
    pdf = 0.0f;
    eval = make_float3(0.0f, 0.0f, 0.0f);
  }


  return int(LABEL_REFLECT | LABEL_DIFFUSE);

}

#endif
CCL_NAMESPACE_END

#endif /* _BSDF_OREN_NAYAR_H_ */
