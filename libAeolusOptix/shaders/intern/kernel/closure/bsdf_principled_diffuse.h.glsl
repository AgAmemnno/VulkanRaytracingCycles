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

#ifndef _BSDF_PRINCIPLED_DIFFUSE_H_
#define _BSDF_PRINCIPLED_DIFFUSE_H_

/* DISNEY PRINCIPLED DIFFUSE BRDF
 *
 * Shading model by Brent Burley (Disney): "Physically Based Shading at Disney" (2012)
 */


CCL_NAMESPACE_BEGIN


#define PrincipledDiffuseBsdf ShaderClosure
#define PrincipledDiffuse_roughness(bsdf) bsdf.data[0]
#define sizeof_PrincipledDiffuseBsdf 4
#ifdef  SVM_TYPE_SETUP

ccl_device int bsdf_principled_diffuse_setup()
{
  DEF_BSDF.type = CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID;
  return int(SD_BSDF | SD_BSDF_HAS_EVAL);

}

#else






/*
typedef ccl_addr_space struct PrincipledDiffuseBsdf {
  SHADER_CLOSURE_BASE;

  float roughness;
} PrincipledDiffuseBsdf;

static_assert(sizeof(ShaderClosure) >= sizeof(PrincipledDiffuseBsdf),
              "PrincipledDiffuseBsdf is too large!");
*/
ccl_device float3 calculate_principled_diffuse_brdf(float3 N, float3 V, float3 L, float3 H, inout float pdf)
{
  float NdotL = max(dot3(N, L), 0.0f);
  float NdotV = max(dot3(N, V), 0.0f);
  if (NdotL < 0 || NdotV < 0) {
    pdf = 0.0f;
    return make_float3(0.0f, 0.0f, 0.0f);
  }
  float LdotH = dot3(L, H);
  float FL = schlick_fresnel(NdotL), FV = schlick_fresnel(NdotV);
  const float Fd90 = 0.5f + 2.0f * LdotH * LdotH * PrincipledDiffuse_roughness(DEF_BSDF);
  float Fd = (1.0f * (1.0f - FL) + Fd90 * FL) * (1.0f * (1.0f - FV) + Fd90 * FV);

  float value = M_1_PI_F * NdotL * Fd;

  return make_float3(value, value, value);
}



ccl_device bool bsdf_principled_diffuse_merge(in ShaderClosure bsdf_a, in ShaderClosure bsdf_b
)
{
  return (isequal_float3(bsdf_a.N, bsdf_b.N) && PrincipledDiffuse_roughness(bsdf_a) == PrincipledDiffuse_roughness(bsdf_b));
}

ccl_device float3 bsdf_principled_diffuse_eval_reflect(
                                                       const float3 I,
                                                       const float3 omega_in,
                                                       inout float pdf)
{
  

  float3 N = DEF_BSDF.N;
  float3 V = I;         // outgoing
  float3 L = omega_in;  // incoming
  float3 H = normalize(L + V);

  if (dot3(N, omega_in) > 0.0f) {
    pdf = fmaxf(dot3(N, omega_in), 0.0f) * M_1_PI_F;
    return calculate_principled_diffuse_brdf(N, V, L, H, pdf);
  }
  else {
    pdf = 0.0f;
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

ccl_device float3 bsdf_principled_diffuse_eval_transmit(
                                                        const float3 I,
                                                        const float3 omega_in,
                                                        inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device int bsdf_principled_diffuse_sample(
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
    eval = calculate_principled_diffuse_brdf(N, I, omega_in, H, pdf);

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

#endif /* _BSDF_PRINCIPLED_DIFFUSE_H_ */
