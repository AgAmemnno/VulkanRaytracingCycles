
#ifndef _EMISSIVE_H_
#define _EMISSIVE_H_

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

CCL_NAMESPACE_BEGIN

/* BACKGROUND CLOSURE */
#ifdef SHADER_BSDF_EVAL
ccl_device void background_setup(const float3 weight)
{
  if (bool(sd.flag & SD_EMISSION)
) {
    sd.closure_emission_background += weight;
  }
  else {
    sd.flag |= int(SD_EMISSION);

    sd.closure_emission_background = weight;
  }
}

/* EMISSION CLOSURE */

ccl_device void emission_setup(const float3 weight)
{
  if (bool(sd.flag & SD_EMISSION)
) {
    sd.closure_emission_background += weight;
  }
  else {
    sd.flag |= int(SD_EMISSION);

    sd.closure_emission_background = weight;
  }
}
#endif
/* return the probability distribution function in the direction I,
 * given the parameters and the light's surface normal.  This MUST match
 * the PDF computed by sample(). */
ccl_device float emissive_pdf(const float3 Ng, const float3 I)
{
  float cosNO = fabsf(dot3(Ng, I));
  return (cosNO > 0.0f) ? 1.0f : 0.0f;
}

ccl_device void emissive_sample(
    const float3 Ng, float randu, float randv, inout float3 omega_out, inout float pdf)
{
  /* todo: not implemented and used yet */
}

ccl_device float3 emissive_simple_eval(const float3 Ng, const float3 I)
{
  float res = emissive_pdf(Ng, I);

  return make_float3(res, res, res);
}
CCL_NAMESPACE_END

#endif