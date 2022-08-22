/*
 * Copyright 2018 Blender Foundation
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

#ifdef _KERNEL_CPU_
#  include <fenv.h>
#endif

#include "kernel/kernel_color.h.glsl"

#ifndef _BSDF_HAIR_PRINCIPLED_H_
#  define _BSDF_HAIR_PRINCIPLED_H_


CCL_NAMESPACE_BEGIN


#define PrincipledHairBSDF ShaderClosure
#define PrincipledHair_sigma(bsdf) vec4(bsdf.data[0], bsdf.data[0+1], bsdf.data[0+2],0.f)
#define PrincipledHair_sigma_lval(bsdf) { vec4 tmp =  PrincipledHair_sigma(bsdf); tmp 
#define PrincipledHair_sigma_assign(bsdf) bsdf.data[0] = tmp.x, bsdf.data[0+1] = tmp.y, bsdf.data[0+2] = tmp.z;}
#define PrincipledHair_v(bsdf) bsdf.data[3]
#define PrincipledHair_s(bsdf) bsdf.data[4]
#define PrincipledHair_alpha(bsdf) bsdf.data[5]
#define PrincipledHair_eta(bsdf) bsdf.data[6]
#define PrincipledHair_m0_roughness(bsdf) bsdf.data[7]
#define PrincipledHair_geom(bsdf) vec4(bsdf.data[8], bsdf.data[8+1], bsdf.data[8+2], bsdf.data[8+3])
#define PrincipledHair_geom_lval(bsdf) { vec4 tmp =  PrincipledHair_geom(bsdf); tmp 
#define PrincipledHair_geom_assign(bsdf) bsdf.data[8] = tmp.x, bsdf.data[8+1] = tmp.y, bsdf.data[8+2] = tmp.z,bsdf.data[8+3] = tmp.w;}
#define PrincipledHair_extra_NULL(bsdf) { bsdf.data[8]=FLT_MIN;  bsdf.data[11]=FLT_MIN;  } 
#define PrincipledHair_is_extra_NULL(bsdf) (bsdf.data[8]==FLT_MIN && bsdf.data[11]==FLT_MIN )




/*
typedef ccl_addr_space struct PrincipledHairExtra {
  // Geometry data. 
  float4 geom;
} PrincipledHairExtra;

typedef ccl_addr_space struct PrincipledHairBSDF {
  SHADER_CLOSURE_BASE;

  // Absorption coefficient. 
  float3 sigma;
  // Variance of the underlying logistic distribution. 
  float v;
  // Scale factor of the underlying logistic distribution. 
  float s;
  // Cuticle tilt angle. 
  float alpha;
  // IOR. 
  float eta;
  // Effective variance for the diffuse bounce only. 
  float m0_roughness;

  // Extra closure. 
  PrincipledHairExtra *extra;
} PrincipledHairBSDF;

static_assert(sizeof(ShaderClosure) >= sizeof(PrincipledHairBSDF),
              "PrincipledHairBSDF is too large!");
static_assert(sizeof(ShaderClosure) >= sizeof(PrincipledHairExtra),
              "PrincipledHairExtra is too large!");
*/
ccl_device_inline float cos_from_sin(const float s)
{
  return safe_sqrtf(1.0f - s * s);
}

/* Gives the change in direction in the normal plane for the given angles and p-th-order
 * scattering. */
ccl_device_inline float delta_phi(int p, float gamma_o, float gamma_t)
{
  return 2.0f * p * gamma_t - 2.0f * gamma_o + p * M_PI_F;
}

/* Remaps the given angle to [-pi, pi]. */
ccl_device_inline float wrap_angle(float a)
{
  while (a > M_PI_F) {
    a -= M_2PI_F;
  }
  while (a < -M_PI_F) {
    a += M_2PI_F;
  }
  return a;
}

/* Logistic distribution function. */
ccl_device_inline float logistic(float x, float s)
{
  float v = expf(-fabsf(x) / s);
  return v / (s * sqr(1.0f + v));
}

/* Logistic cumulative density function. */
ccl_device_inline float logistic_cdf(float x, float s)
{
  float arg = -x / s;
  /* expf() overflows if arg >= 89.0. */
  if (arg > 88.0f) {
    return 0.0f;
  }
  else {
    return 1.0f / (1.0f + expf(arg));
  }
}

/* Numerical approximation to the Bessel function of the first kind. */
ccl_device_inline float bessel_I0(float x)
{
  x = sqr(x);
  float val = 1.0f + 0.25f * x;
  float pow_x_2i = sqr(x);
  uint64_t i_fac_2 = 1;
  int pow_4_i = 16;
  for (int i = 2; i < 10; i++) {
    i_fac_2 *= i * i;
    float newval = val + pow_x_2i / (float(pow_4_i) * float(i_fac_2));

    if (val == newval) {
      return val;
    }
    val = newval;
    pow_x_2i *= x;
    pow_4_i *= 4;
  }
  return val;
}

/* Logarithm of the Bessel function of the first kind. */
ccl_device_inline float log_bessel_I0(float x)
{
  if (x > 12.0f) {
    /* log(1/x) == -log(x) iff x > 0.
     * This is only used with positive cosines */
    return x + 0.5f * (1.f / (8.0f * x) - M_LN_2PI_F - logf(x));
  }
  else {
    return logf(bessel_I0(x));
  }
}

/* Logistic distribution limited to the interval [-pi, pi]. */
ccl_device_inline float trimmed_logistic(float x, float s)
{
  /* The logistic distribution is symmetric and centered around zero,
   * so logistic_cdf(x, s) = 1 - logistic_cdf(-x, s).
   * Therefore, logistic_cdf(x, s)-logistic_cdf(-x, s) = 1 - 2*logistic_cdf(-x, s) */
  float scaling_fac = 1.0f - 2.0f * logistic_cdf(-M_PI_F, s);
  float val = logistic(x, s);
  return safe_divide(val, scaling_fac);
}

/* Sampling function for the trimmed logistic function. */
ccl_device_inline float sample_trimmed_logistic(float u, float s)
{
  float cdf_minuspi = logistic_cdf(-M_PI_F, s);
  float x = -s * logf(1.0f / (u * (1.0f - 2.0f * cdf_minuspi) + cdf_minuspi) - 1.0f);
  return clamp(x, -M_PI_F, M_PI_F);
}

/* Azimuthal scattering function Np. */
ccl_device_inline float azimuthal_scattering(
    float phi, int p, float s, float gamma_o, float gamma_t)
{
  float phi_o = wrap_angle(phi - delta_phi(p, gamma_o, gamma_t));
  float val = trimmed_logistic(phi_o, s);
  return val;
}

/* Longitudinal scattering function Mp. */
ccl_device_inline float longitudinal_scattering(
    float sin_theta_i, float cos_theta_i, float sin_theta_o, float cos_theta_o, float v)
{
  float inv_v = 1.0f / v;
  float cos_arg = cos_theta_i * cos_theta_o * inv_v;
  float sin_arg = sin_theta_i * sin_theta_o * inv_v;
  if (v <= 0.1f) {
    float i0 = log_bessel_I0(cos_arg);
    float val = expf(i0 - sin_arg - inv_v + 0.6931f + logf(0.5f * inv_v));
    return val;
  }
  else {
    float i0 = bessel_I0(cos_arg);
    float val = (expf(-sin_arg) * i0) / (sinhf(inv_v) * 2.0f * v);
    return val;
  }
}

/* Combine the three values using their luminances. */
ccl_device_inline float4 combine_with_energy(inout KernelGlobals kg, float3 c)
{
  return make_float4(c.x, c.y, c.z, linear_rgb_to_gray(kg, c));
}

#  ifdef _HAIR_
/* Set up the hair closure. */
ccl_device int bsdf_principled_hair_setup(inout ShaderData sd, inout PrincipledHairBSDF bsdf)
{
  bsdf.type = CLOSURE_BSDF_HAIR_PRINCIPLED_ID;
  PrincipledHair_v(bsdf) = clamp(PrincipledHair_v(bsdf), 0.001f, 1.0f);
  PrincipledHair_s(bsdf) = clamp(PrincipledHair_s(bsdf), 0.001f, 1.0f);
  /* Apply Primary Reflection Roughness modifier. */
  PrincipledHair_m0_roughness(bsdf) = clamp(PrincipledHair_m0_roughness(bsdf) * PrincipledHair_v(bsdf), 0.001f, 1.0f);

  /* Map from roughness_u and roughness_v to variance and scale factor. */
  PrincipledHair_v(bsdf) = sqr(0.726f * PrincipledHair_v(bsdf) + 0.812f * sqr(PrincipledHair_v(bsdf)) + 3.700f * pow20(PrincipledHair_v(bsdf)));
  PrincipledHair_s(bsdf) = (0.265f * PrincipledHair_s(bsdf) + 1.194f * sqr(PrincipledHair_s(bsdf)) + 5.372f * pow22(PrincipledHair_s(bsdf))) * M_SQRT_PI_8_F;
  PrincipledHair_m0_roughness(bsdf) = sqr(0.726f * PrincipledHair_m0_roughness(bsdf) + 0.812f * sqr(PrincipledHair_m0_roughness(bsdf)) +
                           3.700f * pow20(PrincipledHair_m0_roughness(bsdf)));

  /* Compute local frame, aligned to curve tangent and ray direction. */
  float3 X = safe_normalize(sd.dPdu);
  float3 Y = safe_normalize(cross(X, sd.I));
  float3 Z = safe_normalize(cross(X, Y));

  /* h -1..0..1 means the rays goes from grazing the hair, to hitting it at
   * the center, to grazing the other edge. This is the sine of the angle
   * between sd.Ng and Z, as seen from the tangent X. */

  /* TODO: we convert this value to a cosine later and discard the sign, so
   * we could probably save some operations. */
  float h = (sd.type & (PRIMITIVE_CURVE_RIBBON | PRIMITIVE_MOTION_CURVE_RIBBON)) ?
                -sd.v :
                dot3(cross3(sd.Ng, X), Z);

  kernel_assert(fabsf(h) < 1.0f + 1e-4f);
  kernel_assert(isfinite3_safe(Y));
  kernel_assert(isfinite_safe(h));

   PrincipledHair_geom_lval(bsdf) =  make_float4(Y.x, Y.y, Y.z, h); PrincipledHair_geom_assign(bsdf) 

  return SD_BSDF | SD_BSDF_HAS_EVAL | SD_BSDF_NEEDS_LCG;
}

#  endif /* _HAIR_ */

/* Given the Fresnel term and transmittance, generate the attenuation terms for each bounce. */
ccl_device_inline void hair_attenuation(inout KernelGlobals kg, float f, float3 T, float4 Ap[4])

{
  /* Primary specular (R). */
  Ap[0] = make_float4(f, f, f, f);

  /* Transmission (TT). */
  float3 col = sqr(1.0f - f) * T;
  Ap[1] = combine_with_energy(kg, col);

  /* Secondary specular (TRT). */
  col *= T * f;
  Ap[2] = combine_with_energy(kg, col);

  /* Residual component (TRRT+). */
  col *= safe_divide_color(T * f, make_float3(1.0f, 1.0f, 1.0f) - T * f);
  Ap[3] = combine_with_energy(kg, col);

  /* Normalize sampling weights. */
  float totweight = Ap[0].w + Ap[1].w + Ap[2].w + Ap[3].w;
  float fac = safe_divide(1.0f, totweight);

  Ap[0].w *= fac;
  Ap[1].w *= fac;
  Ap[2].w *= fac;
  Ap[3].w *= fac;
}

/* Given the tilt angle, generate the rotated theta_i for the different bounces. */
ccl_device_inline void hair_alpha_angles(float sin_theta_i,
                                         float cos_theta_i,
                                         float alpha,
                                         float angles[6])

{
  float sin_1alpha = sinf(alpha);
  float cos_1alpha = cos_from_sin(sin_1alpha);
  float sin_2alpha = 2.0f * sin_1alpha * cos_1alpha;
  float cos_2alpha = sqr(cos_1alpha) - sqr(sin_1alpha);
  float sin_4alpha = 2.0f * sin_2alpha * cos_2alpha;
  float cos_4alpha = sqr(cos_2alpha) - sqr(sin_2alpha);

  angles[0] = sin_theta_i * cos_2alpha + cos_theta_i * sin_2alpha;
  angles[1] = fabsf(cos_theta_i * cos_2alpha - sin_theta_i * sin_2alpha);
  angles[2] = sin_theta_i * cos_1alpha - cos_theta_i * sin_1alpha;
  angles[3] = fabsf(cos_theta_i * cos_1alpha + sin_theta_i * sin_1alpha);
  angles[4] = sin_theta_i * cos_4alpha - cos_theta_i * sin_4alpha;
  angles[5] = fabsf(cos_theta_i * cos_4alpha + sin_theta_i * sin_4alpha);
}

/* Evaluation function for our shader. */
ccl_device float3 bsdf_principled_hair_eval(inout KernelGlobals kg,
                                            in ShaderData sd,
                                            in ShaderClosure bsdf,
                                            const float3 omega_in,
                                            inout float pdf)
{
  kernel_assert(isfinite3_safe(sd.P) && isfinite_safe(sd.ray_length));

  
  float3 Y = float4_to_float3(PrincipledHair_geom(bsdf));

  float3 X = safe_normalize(sd.dPdu);
  kernel_assert(fabsf(dot3(X, Y)) < 1e-3f);
  float3 Z = safe_normalize(cross(X, Y));

  float3 wo = make_float3(dot3(sd.I, X), dot3(sd.I, Y), dot3(sd.I, Z));
  float3 wi = make_float3(dot3(omega_in, X), dot3(omega_in, Y), dot3(omega_in, Z));

  float sin_theta_o = wo.x;
  float cos_theta_o = cos_from_sin(sin_theta_o);
  float phi_o = atan2f(wo.z, wo.y);

  float sin_theta_t = sin_theta_o / PrincipledHair_eta(bsdf);
  float cos_theta_t = cos_from_sin(sin_theta_t);

  float sin_gamma_o = PrincipledHair_geom(bsdf).w;
  float cos_gamma_o = cos_from_sin(sin_gamma_o);
  float gamma_o = safe_asinf(sin_gamma_o);

  float sin_gamma_t = sin_gamma_o * cos_theta_o / sqrtf(sqr(PrincipledHair_eta(bsdf)) - sqr(sin_theta_o));
  float cos_gamma_t = cos_from_sin(sin_gamma_t);
  float gamma_t = safe_asinf(sin_gamma_t);

  float3 T = exp3(-PrincipledHair_sigma(bsdf) * (2.0f * cos_gamma_t / cos_theta_t));
  float4 Ap[4];
  hair_attenuation(kg, fresnel_dielectric_cos(cos_theta_o * cos_gamma_o, PrincipledHair_eta(bsdf)), T, Ap);

  float sin_theta_i = wi.x;
  float cos_theta_i = cos_from_sin(sin_theta_i);
  float phi_i = atan2f(wi.z, wi.y);

  float phi = phi_i - phi_o;

  float angles[6];
  hair_alpha_angles(sin_theta_i, cos_theta_i, PrincipledHair_alpha(bsdf), angles);

  float4 F;
  float Mp, Np;

  /* Primary specular (R). */
  Mp = longitudinal_scattering(angles[0], angles[1], sin_theta_o, cos_theta_o, PrincipledHair_m0_roughness(bsdf));
  Np = azimuthal_scattering(phi, 0, PrincipledHair_s(bsdf), gamma_o, gamma_t);
  F = Ap[0] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  /* Transmission (TT). */
  Mp = longitudinal_scattering(angles[2], angles[3], sin_theta_o, cos_theta_o, 0.25f * PrincipledHair_v(bsdf));
  Np = azimuthal_scattering(phi, 1, PrincipledHair_s(bsdf), gamma_o, gamma_t);
  F += Ap[1] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  /* Secondary specular (TRT). */
  Mp = longitudinal_scattering(angles[4], angles[5], sin_theta_o, cos_theta_o, 4.0f * PrincipledHair_v(bsdf));
  Np = azimuthal_scattering(phi, 2, PrincipledHair_s(bsdf), gamma_o, gamma_t);
  F += Ap[2] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  /* Residual component (TRRT+). */
  Mp = longitudinal_scattering(sin_theta_i, cos_theta_i, sin_theta_o, cos_theta_o, 4.0f * PrincipledHair_v(bsdf));
  Np = M_1_2PI_F;
  F += Ap[3] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  pdf = F.w;
  return float4_to_float3(F);
}

/* Sampling function for the hair shader. */
ccl_device int bsdf_principled_hair_sample(inout KernelGlobals kg,
                                           in ShaderClosure bsdf,
                                           inout ShaderData sd,
                                           float randu,
                                           float randv,
                                           inout float3 eval,
                                           inout float3 omega_in,
                                           inout float3 domega_in_dx,
                                           inout float3 domega_in_dy,
                                           inout float pdf)
{
  

  float3 Y = float4_to_float3(PrincipledHair_geom(bsdf));

  float3 X = safe_normalize(sd.dPdu);
  kernel_assert(fabsf(dot3(X, Y)) < 1e-3f);
  float3 Z = safe_normalize(cross(X, Y));

  float3 wo = make_float3(dot3(sd.I, X), dot3(sd.I, Y), dot3(sd.I, Z));

  float2 u[2];
  u[0] = make_float2(randu, randv);
  u[1].x = lcg_step_float_addrspace(sd.lcg_state
);
  u[1].y = lcg_step_float_addrspace(sd.lcg_state
);

  float sin_theta_o = wo.x;
  float cos_theta_o = cos_from_sin(sin_theta_o);
  float phi_o = atan2f(wo.z, wo.y);

  float sin_theta_t = sin_theta_o / PrincipledHair_eta(bsdf);
  float cos_theta_t = cos_from_sin(sin_theta_t);

  float sin_gamma_o = PrincipledHair_geom(bsdf).w;
  float cos_gamma_o = cos_from_sin(sin_gamma_o);
  float gamma_o = safe_asinf(sin_gamma_o);

  float sin_gamma_t = sin_gamma_o * cos_theta_o / sqrtf(sqr(PrincipledHair_eta(bsdf)) - sqr(sin_theta_o));
  float cos_gamma_t = cos_from_sin(sin_gamma_t);
  float gamma_t = safe_asinf(sin_gamma_t);

  float3 T = exp3(-PrincipledHair_sigma(bsdf) * (2.0f * cos_gamma_t / cos_theta_t));
  float4 Ap[4];
  hair_attenuation(kg, fresnel_dielectric_cos(cos_theta_o * cos_gamma_o, PrincipledHair_eta(bsdf)), T, Ap);

  int p = 0;
  for (; p < 3; p++) {
    if (u[0].x < Ap[p].w) {
      break;
    }
    u[0].x -= Ap[p].w;
  }

  float v = PrincipledHair_v(bsdf);
  if (p == 1) {
    v *= 0.25f;
  }
  if (p >= 2) {
    v *= 4.0f;
  }

  u[1].x = max(u[1].x, 1e-5f);
  float fac = 1.0f + v * logf(u[1].x + (1.0f - u[1].x) * expf(-2.0f / v));
  float sin_theta_i = -fac * sin_theta_o +
                      cos_from_sin(fac) * cosf(M_2PI_F * u[1].y) * cos_theta_o;
  float cos_theta_i = cos_from_sin(sin_theta_i);

  float angles[6];
  if (p < 3) {
    hair_alpha_angles(sin_theta_i, cos_theta_i, -PrincipledHair_alpha(bsdf), angles);
    sin_theta_i = angles[2 * p];
    cos_theta_i = angles[2 * p + 1];
  }

  float phi;
  if (p < 3) {
    phi = delta_phi(p, gamma_o, gamma_t) + sample_trimmed_logistic(u[0].y, PrincipledHair_s(bsdf));
  }
  else {
    phi = M_2PI_F * u[0].y;
  }
  float phi_i = phi_o + phi;

  hair_alpha_angles(sin_theta_i, cos_theta_i, PrincipledHair_alpha(bsdf), angles);

  float4 F;
  float Mp, Np;

  /* Primary specular (R). */
  Mp = longitudinal_scattering(angles[0], angles[1], sin_theta_o, cos_theta_o, PrincipledHair_m0_roughness(bsdf));
  Np = azimuthal_scattering(phi, 0, PrincipledHair_s(bsdf), gamma_o, gamma_t);
  F = Ap[0] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  /* Transmission (TT). */
  Mp = longitudinal_scattering(angles[2], angles[3], sin_theta_o, cos_theta_o, 0.25f * PrincipledHair_v(bsdf));
  Np = azimuthal_scattering(phi, 1, PrincipledHair_s(bsdf), gamma_o, gamma_t);
  F += Ap[1] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  /* Secondary specular (TRT). */
  Mp = longitudinal_scattering(angles[4], angles[5], sin_theta_o, cos_theta_o, 4.0f * PrincipledHair_v(bsdf));
  Np = azimuthal_scattering(phi, 2, PrincipledHair_s(bsdf), gamma_o, gamma_t);
  F += Ap[2] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  /* Residual component (TRRT+). */
  Mp = longitudinal_scattering(sin_theta_i, cos_theta_i, sin_theta_o, cos_theta_o, 4.0f * PrincipledHair_v(bsdf));
  Np = M_1_2PI_F;
  F += Ap[3] * Mp * Np;
  kernel_assert(isfinite3_safe(float4_to_float3(F)));

  eval = float4_to_float3(F);
  pdf = F.w;

  omega_in = X * sin_theta_i + Y * cos_theta_i * cosf(phi_i) + Z * cos_theta_i * sinf(phi_i);

#  ifdef _RAY_DIFFERENTIALS_
  float3 N = safe_normalize(sd.I + omega_in);
  domega_in_dx = (2 * dot3(N, sd.dI.dx)) * N - sd.dI.dx;
  domega_in_dy = (2 * dot3(N, sd.dI.dy)) * N - sd.dI.dy;
#  endif

  return int( LABEL_GLOSSY | ((p == 0) ? LABEL_REFLECT : LABEL_TRANSMIT));

}

/* Implements Filter Glossy by capping the effective roughness. */
ccl_device void bsdf_principled_hair_blur(inout ShaderClosure bsdf, float roughness)
{
  

  PrincipledHair_v(bsdf) = fmaxf(roughness, PrincipledHair_v(bsdf));
  PrincipledHair_s(bsdf) = fmaxf(roughness, PrincipledHair_s(bsdf));
  PrincipledHair_m0_roughness(bsdf) = fmaxf(roughness, PrincipledHair_m0_roughness(bsdf));
}

/* Hair Albedo */

ccl_device_inline float bsdf_principled_hair_albedo_roughness_scale(
    const float azimuthal_roughness)
{
  const float x = azimuthal_roughness;
  return (((((0.245f * x) + 5.574f) * x - 10.73f) * x + 2.532f) * x - 0.215f) * x + 5.969f;
}

ccl_device float3 bsdf_principled_hair_albedo(inout ShaderClosure bsdf)
{
  
  return exp3(-sqrt(PrincipledHair_sigma(bsdf)) * bsdf_principled_hair_albedo_roughness_scale(PrincipledHair_v(bsdf)));
}

ccl_device_inline float3
bsdf_principled_hair_sigma_from_reflectance(const float3 color, const float azimuthal_roughness)
{
  const float3 sigma = log3(color) /
                       bsdf_principled_hair_albedo_roughness_scale(azimuthal_roughness);
  return sigma * sigma;
}

ccl_device_inline float3 bsdf_principled_hair_sigma_from_concentration(const float eumelanin,
                                                                       const float pheomelanin)
{
  return eumelanin * make_float3(0.506f, 0.841f, 1.653f) +
         pheomelanin * make_float3(0.343f, 0.733f, 1.924f);
}

CCL_NAMESPACE_END

#endif /* _BSDF_HAIR_PRINCIPLED_H_ */
