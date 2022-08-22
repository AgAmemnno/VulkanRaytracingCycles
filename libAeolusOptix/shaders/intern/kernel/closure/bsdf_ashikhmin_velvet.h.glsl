/*
 * Adapted from Open Shading Language with this license:
 *
 * Copyright (c) 2009-2010 Sony Pictures Imageworks Inc., et al.
 * All Rights Reserved.
 *
 * Modifications Copyright 2011, Blender Foundation.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * * Neither the name of Sony Pictures Imageworks nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _BSDF_ASHIKHMIN_VELVET_H_
#define _BSDF_ASHIKHMIN_VELVET_H_


CCL_NAMESPACE_BEGIN


#define VelvetBsdf ShaderClosure
#define Velvet_sigma(bsdf) bsdf.data[0]
#define Velvet_invsigma2(bsdf) bsdf.data[1]
#define sizeof_VelvetBsdf 8



/*
typedef ccl_addr_space struct VelvetBsdf {
  SHADER_CLOSURE_BASE;

  float sigma;
  float invsigma2;
} VelvetBsdf;

static_assert(sizeof(ShaderClosure) >= sizeof(VelvetBsdf), "VelvetBsdf is too large!");
*/
#ifdef  SVM_TYPE_SETUP
ccl_device int bsdf_ashikhmin_velvet_setup()
{
  float sigma = fmaxf(Velvet_sigma(DEF_BSDF), 0.01f);
  Velvet_invsigma2(DEF_BSDF) = 1.0f / (sigma * sigma);

  DEF_BSDF.type = int(CLOSURE_BSDF_ASHIKHMIN_VELVET_ID);

  return int(SD_BSDF | SD_BSDF_HAS_EVAL);

}
#else
ccl_device bool bsdf_ashikhmin_velvet_merge(in ShaderClosure bsdf_a, in ShaderClosure bsdf_b)
{
  //
  //

  return (isequal_float3(bsdf_a.N, bsdf_b.N)) && (Velvet_sigma(bsdf_a) == Velvet_sigma(bsdf_b));
}

ccl_device float3 bsdf_ashikhmin_velvet_eval_reflect(
                                                     const float3 I,
                                                     const float3 omega_in,
                                                     inout float pdf)
{
  
  float m_invsigma2 = Velvet_invsigma2(DEF_BSDF);
  float3 N = DEF_BSDF.N;

  float cosNO = dot3(N, I);
  float cosNI = dot3(N, omega_in);
  if (cosNO > 0 && cosNI > 0) {
    float3 H = normalize(omega_in + I);

    float cosNH = dot3(N, H);
    float cosHO = fabsf(dot3(I, H));

    if (!(fabsf(cosNH) < 1.0f - 1e-5f && cosHO > 1e-5f))
      return make_float3(0.0f, 0.0f, 0.0f);

    float cosNHdivHO = cosNH / cosHO;
    cosNHdivHO = fmaxf(cosNHdivHO, 1e-5f);

    float fac1 = 2 * fabsf(cosNHdivHO * cosNO);
    float fac2 = 2 * fabsf(cosNHdivHO * cosNI);

    float sinNH2 = 1 - cosNH * cosNH;
    float sinNH4 = sinNH2 * sinNH2;
    float cotangent2 = (cosNH * cosNH) / sinNH2;

    float D = expf(-cotangent2 * m_invsigma2) * m_invsigma2 * M_1_PI_F / sinNH4;
    float G = min(1.0f, min(fac1, fac2));  // TODO: derive G from D analytically

    float out_rsv = 0.25f * (D * G) / cosNO;

    pdf = 0.5f * M_1_PI_F;
    return make_float3(out_rsv, out_rsv, out_rsv);
  }

  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device float3 bsdf_ashikhmin_velvet_eval_transmit(
                                                      const float3 I,
                                                      const float3 omega_in,
                                                      inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device int bsdf_ashikhmin_velvet_sample(
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
  
  float m_invsigma2 = Velvet_invsigma2(DEF_BSDF);
  float3 N = DEF_BSDF.N;

  // we are viewing the surface from above - send a ray out_rsv with uniform
  // distribution over the hemisphere
  sample_uniform_hemisphere(N, randu, randv, omega_in, pdf);

  if (dot3(Ng, omega_in) > 0) {
    float3 H = normalize(omega_in + I);

    float cosNI = dot3(N, omega_in);
    float cosNO = dot3(N, I);
    float cosNH = dot3(N, H);
    float cosHO = fabsf(dot3(I, H));

    if (fabsf(cosNO) > 1e-5f && fabsf(cosNH) < 1.0f - 1e-5f && cosHO > 1e-5f) {
      float cosNHdivHO = cosNH / cosHO;
      cosNHdivHO = fmaxf(cosNHdivHO, 1e-5f);

      float fac1 = 2 * fabsf(cosNHdivHO * cosNO);
      float fac2 = 2 * fabsf(cosNHdivHO * cosNI);

      float sinNH2 = 1 - cosNH * cosNH;
      float sinNH4 = sinNH2 * sinNH2;
      float cotangent2 = (cosNH * cosNH) / sinNH2;

      float D = expf(-cotangent2 * m_invsigma2) * m_invsigma2 * M_1_PI_F / sinNH4;
      float G = min(1.0f, min(fac1, fac2));  // TODO: derive G from D analytically

      float power = 0.25f * (D * G) / cosNO;

      eval = make_float3(power, power, power);

#ifdef _RAY_DIFFERENTIALS_
      // TODO: find a better approximation for the retroreflective bounce
      domega_in_dx = (2 * dot3(N, dIdx)) * N - dIdx;
      domega_in_dy = (2 * dot3(N, dIdy)) * N - dIdy;
#endif
    }
    else
      pdf = 0.0f;
  }
  else
    pdf = 0.0f;

  return int(LABEL_REFLECT | LABEL_DIFFUSE);
}

#endif

CCL_NAMESPACE_END

#endif /* _BSDF_ASHIKHMIN_VELVET_H_ */
