/*
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

#ifndef _BSDF_TRANSPARENT_H_
#define _BSDF_TRANSPARENT_H_

CCL_NAMESPACE_BEGIN
#ifdef SVM_TYPE_SETUP
ccl_device void bsdf_transparent_setup( const float3 weight, uint path_flag)
{
  /* Check cutoff weight. */
  float sample_weight = fabsf(average(weight));
  if (!(sample_weight >= CLOSURE_WEIGHT_CUTOFF)) {
    return;
  }



  if (bool(GSD.flag & SD_TRANSPARENT)) {
    //sd.closure_transparent_extinction += weight;
    BSDF_closure_transparent_extinction  += weight;
    /* Add weight to existing transparent BSDF. */
    float sum = 0.0f;
    GSD.alloc_offset -= GSD.num_closure;
    for (int i = 0; i < GSD.num_closure;i++) { 
      GSD.alloc_offset +=1;
      if (DEF_BSDF.type == CLOSURE_BSDF_TRANSPARENT_ID) {
        DEF_BSDF.weight += vec4(weight,0);
        DEF_BSDF.sample_weight += sample_weight;
        break;
      }
      
    }
  }
  else {

      GSD.flag |= int( SD_BSDF | SD_TRANSPARENT);
      BSDF_closure_transparent_extinction  = weight;
    if (bool(path_flag & PATH_RAY_TERMINATE)) 
    {
      /* In this case the number of closures is set to zero to disable
       * all others, but we still want to get transparency so increase
       * the number just for this. */
      GSD.num_closure_left = 1;
    }

    /* Create new transparent BSDF. */
    int n = closure_alloc(CLOSURE_BSDF_TRANSPARENT_ID, vec4(weight,0));

    if (n >= 0) {
      DEF_BSDF.sample_weight = sample_weight;
      DEF_BSDF.N = vec4(nio.N,0);
    }
    else if (bool(path_flag & int(PATH_RAY_TERMINATE) )){
      GSD.num_closure_left = 0;
    }

  }



}
#else


ccl_device float3 bsdf_transparent_eval_reflect(
                                                const float3 I,
                                                const float3 omega_in,
                                                inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device float3 bsdf_transparent_eval_transmit(
                                                 const float3 I,
                                                 const float3 omega_in,
                                                 inout float pdf)
{
  return make_float3(0.0f, 0.0f, 0.0f);
}

ccl_device int bsdf_transparent_sample(
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
  // only one direction is possible
  omega_in = -I;
#ifdef _RAY_DIFFERENTIALS_
  domega_in_dx = -dIdx;
  domega_in_dy = -dIdy;
#endif
  pdf = 1;
  eval = make_float3(1, 1, 1);
  return int(LABEL_TRANSMIT | LABEL_TRANSPARENT);

}
#endif
CCL_NAMESPACE_END

#endif /* _BSDF_TRANSPARENT_H_ */
