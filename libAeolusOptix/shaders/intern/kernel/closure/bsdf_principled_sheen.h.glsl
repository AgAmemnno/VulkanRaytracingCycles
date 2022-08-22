/*
 * Copyright 2011-2017 Blender Foundation
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

#ifndef _BSDF_PRINCIPLED_SHEEN_H_
#define _BSDF_PRINCIPLED_SHEEN_H_

/* DISNEY PRINCIPLED SHEEN BRDF
 *
 * Shading model by Brent Burley (Disney): "Physically Based Shading at Disney" (2012)
 */


CCL_NAMESPACE_BEGIN
#define sizeof_PrincipledSheenBsdf 4

#define PrincipledSheenBsdf ShaderClosure
#define PrincipledSheen_avg_value(bsdf) bsdf.data[0]





#ifdef  SVM_TYPE_SETUP

/*
typedef ccl_addr_space struct PrincipledSheenBsdf {
  SHADER_CLOSURE_BASE;
  float avg_value;
} PrincipledSheenBsdf;

static_assert(sizeof(ShaderClosure) >= sizeof(PrincipledSheenBsdf),
              "PrincipledSheenBsdf is too large!");
*/
ccl_device_inline float calculate_avg_principled_sheen_brdf(float3 N, float3 I)
{
  /* To compute the average, we set the half-vector to the normal, resulting in
   * NdotI = NdotL = NdotV = LdotH */
  float NdotI = dot3(N, I);
  if (NdotI < 0.0f) {
    return 0.0f;
  }

  return schlick_fresnel(NdotI) * NdotI;
}

ccl_device int bsdf_principled_sheen_setup()
{
  DEF_BSDF.type = CLOSURE_BSDF_PRINCIPLED_SHEEN_ID;
  PrincipledSheen_avg_value(DEF_BSDF) = calculate_avg_principled_sheen_brdf(as_float3(DEF_BSDF.N), GSD.I);
  DEF_BSDF.sample_weight *= PrincipledSheen_avg_value(DEF_BSDF);
  return int(SD_BSDF | SD_BSDF_HAS_EVAL);

}
#else
ccl_device float3
calculate_principled_sheen_brdf(float3 N, float3 V, float3 L, float3 H, inout float pdf)
{
  float NdotL = dot3(N, L);
  float NdotV = dot3(N, V);

  if (NdotL < 0 || NdotV < 0) {
    pdf = 0.0f;
    return make_float3(0.0f, 0.0f, 0.0f);
  }

  float LdotH = dot3(L, H);

  float value = schlick_fresnel(LdotH) * NdotL;

  return make_float3(value, value, value);
}

ccl_device float3 bsdf_principled_sheen_eval_reflect(const float3 I,
                                                     const float3 omega_in,
                                                     inout float pdf)
{
  

  float3 N = DEF_BSDF.N;
  float3 V = I;         // outgoing
  float3 L = omega_in;  // incoming
  float3 H = normalize(L + V);

  if (dot3(N, omega_in) > 0.0f) {
    pdf = fmaxf(dot3(N, omega_in), 0.0f) * M_1_PI_F;
    return calculate_principled_sheen_brdf(N, V, L, H, pdf);
  }
  else {
    pdf = 0.0f;
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

ccl_device float3 bsdf_principled_sheen_eval_transmit(
                                                      const float3 I,
                                                      const float3 omega_in,
                                                      inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device int bsdf_principled_sheen_sample(
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
  

  float3 N = DEF_BSDF.N;
  sample_cos_hemisphere(N, randu, randv, omega_in, pdf);
  if (dot3(Ng, omega_in) > 0) {
    float3 H = normalize(I + omega_in);
    eval = calculate_principled_sheen_brdf(N, I, omega_in, H, pdf);
#ifdef _RAY_DIFFERENTIALS_
    // TODO: find a better approximation for the diffuse bounce
    domega_in_dx = -((2 * dot3(N, dIdx)) * N - dIdx);
    domega_in_dy = -((2 * dot3(N, dIdy)) * N - dIdy);
#endif
  }
  else {
    pdf = 0.0f;
  }
  return int(LABEL_REFLECT | LABEL_DIFFUSE);

}

#endif

CCL_NAMESPACE_END

#endif /* _BSDF_PRINCIPLED_SHEEN_H_ */
