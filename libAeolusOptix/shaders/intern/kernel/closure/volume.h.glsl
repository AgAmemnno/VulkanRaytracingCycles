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

#ifndef _VOLUME_H_
#define _VOLUME_H_


CCL_NAMESPACE_BEGIN


#define HenyeyGreensteinVolume ShaderClosure
#define HenyeyGreensteinVolume_g(bsdf) bsdf.data[0]





/* VOLUME EXTINCTION */

ccl_device void volume_extinction_setup(inout ShaderData sd, float3 weight)
{
  if (bool(sd.flag & SD_EXTINCTION)
) {
    sd.closure_transparent_extinction += weight;
  }
  else {
    sd.flag |= int(SD_EXTINCTION);

    sd.closure_transparent_extinction = weight;
  }
}

/* HENYEY-GREENSTEIN CLOSURE */
/*
typedef ccl_addr_space struct HenyeyGreensteinVolume {
  SHADER_CLOSURE_BASE;

  float g;
} HenyeyGreensteinVolume;

static_assert(sizeof(ShaderClosure) >= sizeof(HenyeyGreensteinVolume),
              "HenyeyGreensteinVolume is too large!");
*/

/* Given cosine between rays, return probability density that a photon bounces
 * to that direction. The g parameter controls how different it is from the
 * uniform sphere. g=0 uniform diffuse-like, g=1 close to sharp single ray. */
ccl_device float single_peaked_henyey_greenstein(float cos_theta, float g)
{
  return ((1.0f - g * g) / safe_powf(1.0f + g * g - 2.0f * g * cos_theta, 1.5f)) *
         (M_1_PI_F * 0.25f);
};

ccl_device int volume_henyey_greenstein_setup(inout HenyeyGreensteinVolume volume)
{
  volume.type = CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID;

  /* clamp anisotropy to avoid delta function */
  HenyeyGreensteinVolume_g(volume) = signf(HenyeyGreensteinVolume_g(volume)) * min(fabsf(HenyeyGreensteinVolume_g(volume)), 1.0f - 1e-3f);

  return int(SD_SCATTER);

}

ccl_device bool volume_henyey_greenstein_merge(in ShaderClosure volume_a, in ShaderClosure volume_b)

{
  
  

  return (HenyeyGreensteinVolume_g(volume_a) == HenyeyGreensteinVolume_g(volume_b));
}

ccl_device float3 volume_henyey_greenstein_eval_phase(in ShaderClosure volume,
                                                      const float3 I,
                                                      float3 omega_in,
                                                      inout float pdf)
{
  
  float g = HenyeyGreensteinVolume_g(volume);

  /* note that I points towards the viewer */
  if (fabsf(g) < 1e-3f) {
    pdf = M_1_PI_F * 0.25f;
  }
  else {
    float cos_theta = dot3(-I, omega_in);
    pdf = single_peaked_henyey_greenstein(cos_theta, g);
  }

  return make_float3(pdf, pdf, pdf);
}

ccl_device float3
henyey_greenstrein_sample(float3 D, float g, float randu, float randv, inout float pdf)
{
  /* match pdf for small g */
  float cos_theta;
  bool isotropic = fabsf(g) < 1e-3f;

  if (isotropic) {
    cos_theta = (1.0f - 2.0f * randu);
    if (bool(pdf)) {

      pdf = M_1_PI_F * 0.25f;
    }
  }
  else {
    float k = (1.0f - g * g) / (1.0f - g + 2.0f * g * randu);
    cos_theta = (1.0f + g * g - k * k) / (2.0f * g);
    if (bool(pdf)) {

      pdf = single_peaked_henyey_greenstein(cos_theta, g);
    }
  }

  float sin_theta = safe_sqrtf(1.0f - cos_theta * cos_theta);
  float phi = M_2PI_F * randv;
  float3 dir = make_float3(sin_theta * cosf(phi), sin_theta * sinf(phi), cos_theta);

  float3 T, B;
  make_orthonormals(D, T, B);

  dir = dir.x * T + dir.y * B + dir.z * D;

  return dir;
}

ccl_device int volume_henyey_greenstein_sample(in ShaderClosure volume,
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
  
  float g = HenyeyGreensteinVolume_g(volume);

  /* note that I points towards the viewer and so is used negated */
  omega_in = henyey_greenstrein_sample(-I, g, randu, randv, pdf);
  eval = make_float3(pdf, pdf, pdf); /* perfect importance sampling */

#ifdef _RAY_DIFFERENTIALS_
  /* todo: implement ray differential estimation */
  domega_in_dx = make_float3(0.0f, 0.0f, 0.0f);
  domega_in_dy = make_float3(0.0f, 0.0f, 0.0f);
#endif

  return int(LABEL_VOLUME_SCATTER);

}

/* VOLUME CLOSURE */

ccl_device float3 volume_phase_eval(in ShaderData sd,
                                    in ShaderClosure volume,
                                    float3 omega_in,
                                    inout float pdf)
{
  kernel_assert(volume.type == CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID);

  return volume_henyey_greenstein_eval_phase(volume, sd.I, omega_in, pdf);
}

ccl_device int volume_phase_sample(in ShaderData sd,
                                   in ShaderClosure volume,
                                   float randu,
                                   float randv,
                                   inout float3 eval,
                                   inout float3 omega_in,
                                   inout differential3 domega_in,
                                   inout float pdf)
{
  int label;
#ifdef _KERNEL_VULKAN_
  const uint _CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID = 43;
  switch (volume.type) {
    case _CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID:
#else
  switch (volume.type) {
    case CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID:
#endif
      label = volume_henyey_greenstein_sample(volume,
                                              sd.I,
                                              sd.dI.dx,
                                              sd.dI.dy,
                                              randu,
                                              randv,
                                              eval,
                                              omega_in,
                                              domega_in.dx,

                                              domega_in.dy,

                                              pdf);
      break;
    default:
      eval = make_float3(0.0f, 0.0f, 0.0f);
      label = int(LABEL_NONE);       

      break;
  }

  return label;
}

CCL_NAMESPACE_END

#endif
