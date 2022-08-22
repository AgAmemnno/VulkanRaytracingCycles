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

#ifndef _BSDF_DIFFUSE_H_
#define _BSDF_DIFFUSE_H_


CCL_NAMESPACE_BEGIN


#define DiffuseBsdf ShaderClosure
#define sizeof_DiffuseBsdf 0

/*
typedef ccl_addr_space struct DiffuseBsdf {
  SHADER_CLOSURE_BASE;
} DiffuseBsdf;

static_assert(sizeof(ShaderClosure) >= sizeof(DiffuseBsdf), "DiffuseBsdf is too large!");
*/
/* DIFFUSE */
#ifdef  SVM_TYPE_SETUP

ccl_device int bsdf_diffuse_setup()
{
  DEF_BSDF.type = CLOSURE_BSDF_DIFFUSE_ID;
  return int(SD_BSDF | SD_BSDF_HAS_EVAL);

}

/* TRANSLUCENT */
ccl_device int bsdf_translucent_setup()
{
  DEF_BSDF.type = CLOSURE_BSDF_TRANSLUCENT_ID;
  return int(SD_BSDF | SD_BSDF_HAS_EVAL);

}

#else

ccl_device bool bsdf_diffuse_merge(in ShaderClosure bsdf_a, in ShaderClosure bsdf_b)

{
  
  

  return (isequal_float3(bsdf_a.N, bsdf_b.N));
}

ccl_device float3 bsdf_diffuse_eval_reflect(
                                            const float3 I,
                                            const float3 omega_in,
                                            inout float pdf)
{
  
  float3 N = DEF_BSDF.N;

  float cos_pi = fmaxf(dot3(N, omega_in), 0.0f) * M_1_PI_F;
  pdf = cos_pi;
  return make_float3(cos_pi, cos_pi, cos_pi);
}

ccl_device float3 bsdf_diffuse_eval_transmit(
                                             const float3 I,
                                             const float3 omega_in,
                                             inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device int bsdf_diffuse_sample(
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
                                   inout float  pdf)
{
  
  float3 N = DEF_BSDF.N;

  // distribution over the hemisphere
  sample_cos_hemisphere(N, randu, randv, omega_in, pdf);

  if (dot3(Ng, omega_in) > 0.0f) {
    eval = make_float3(pdf, pdf, pdf);
#ifdef _RAY_DIFFERENTIALS_
    // TODO: find a better approximation for the diffuse bounce
    domega_in_dx = (2 * dot3(N, dIdx)) * N - dIdx;
    domega_in_dy = (2 * dot3(N, dIdy)) * N - dIdy;
#endif
  }
  else {
    pdf = 0.0f;
  }


  return int(LABEL_REFLECT | LABEL_DIFFUSE);

}

/* TRANSLUCENT */



ccl_device float3 bsdf_translucent_eval_reflect(
                                                const float3 I,
                                                const float3 omega_in,
                                                inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device float3 bsdf_translucent_eval_transmit(
                                                 const float3 I,
                                                 const float3 omega_in,
                                                 inout float pdf)
{
  
  float3 N = DEF_BSDF.N;

  float cos_pi = fmaxf(-dot3(N, omega_in), 0.0f) * M_1_PI_F;
  pdf = cos_pi;
  return make_float3(cos_pi, cos_pi, cos_pi);
}

ccl_device int bsdf_translucent_sample(
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

  // we are viewing the surface from the right side - send a ray out_rsv with cosine
  // distribution over the hemisphere
  sample_cos_hemisphere(-N, randu, randv, omega_in, pdf);
  if (dot3(Ng, omega_in) < 0) {
    eval = make_float3(pdf, pdf, pdf);
#ifdef _RAY_DIFFERENTIALS_
    // TODO: find a better approximation for the diffuse bounce
    domega_in_dx = -((2 * dot3(N, dIdx)) * N - dIdx);
    domega_in_dy = -((2 * dot3(N, dIdy)) * N - dIdy);
#endif
  }
  else {
    pdf = 0;
  }
  return int(LABEL_TRANSMIT | LABEL_DIFFUSE);

}

#endif

CCL_NAMESPACE_END

#endif /* _BSDF_DIFFUSE_H_ */
