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

#ifndef _KERNEL_BSSRDF_H_
#define _KERNEL_BSSRDF_H_


CCL_NAMESPACE_BEGIN


#define Bssrdf ShaderClosure
#define Bssrdf_radius(bsdf) make_float3(bsdf.data[0], bsdf.data[0+1], bsdf.data[0+2])
#define Bssrdf_radius_lval(bsdf) { float3 tmp =  Bssrdf_radius(bsdf); tmp 
#define Bssrdf_radius_assign(bsdf) bsdf.data[0] = tmp.x, bsdf.data[0+1] = tmp.y, bsdf.data[0+2] = tmp.z;}
#define Bssrdf_albedo(bsdf) make_float3(bsdf.data[3], bsdf.data[3+1], bsdf.data[3+2])
#define Bssrdf_albedo_lval(bsdf) { float3 tmp =  Bssrdf_albedo(bsdf); tmp 
#define Bssrdf_albedo_assign(bsdf) bsdf.data[3] = tmp.x, bsdf.data[3+1] = tmp.y, bsdf.data[3+2] = tmp.z;}
#define Bssrdf_sharpness(bsdf) bsdf.data[6]
#define Bssrdf_texture_blur(bsdf) bsdf.data[7]
#define Bssrdf_roughness(bsdf) bsdf.data[8]
#define Bssrdf_channels(bsdf) bsdf.data[9]

#define BURLEY_TRUNCATE 16.0f
#define BURLEY_TRUNCATE_CDF 0.9963790093708328f  // cdf(BURLEY_TRUNCATE)





#define sizeof_Bssrdf (12*4)
/*
typedef ccl_addr_space struct Bssrdf {
  SHADER_CLOSURE_BASE;

  float3 radius;
  float3 albedo;
  float sharpness;
  float texture_blur;
  float roughness;
  float channels;
} Bssrdf;

static_assert(sizeof(ShaderClosure) >= sizeof(Bssrdf), "Bssrdf is too large!");
*/
/* Planar Truncated Gaussian
 *
 * Note how this is different from the typical gaussian, this one integrates
 * to 1 over the plane (where you get an extra 2*pi*x factor). We are lucky
 * that integrating x*exp(-x) gives a nice closed form solution. */

/* paper suggests 1/12.46 which is much too small, suspect it's *12.46 */

#ifdef  SVM_TYPE_SETUP



/* Generic */
#define bssrdf DEF_BSDF

ccl_device_inline int bssrdf_alloc(float3 weight)
{

  int n = closure_alloc(sizeof_Bssrdf, vec4(weight,0));
  if (n < 0) return -1;
  float sample_weight = fabsf(average(weight));
  DEF_BSDF.sample_weight = sample_weight;
  return (sample_weight >= CLOSURE_WEIGHT_CUTOFF) ? n : -1;

}

ccl_device_inline float bssrdf_burley_fitting(float A)
{
  /* Diffuse surface transmission, equation (6). */
  return 1.9f - A + 3.5f * (A - 0.8f) * (A - 0.8f);
}

/* Scale mean free path length so it gives similar looking result
 * to Cubic and Gaussian models.
 */
ccl_device_inline float3 bssrdf_burley_compatible_mfp(float3 r)
{
  return 0.25f * M_1_PI_F * r;
}


ccl_device void bssrdf_burley_setup()
{
  /* Mean free path length. */
  const float3 l = bssrdf_burley_compatible_mfp(as_float3(Bssrdf_radius(bssrdf)));
  /* Surface albedo. */
  const float3 A = as_float3(Bssrdf_albedo(bssrdf));
  const float3 s = make_float3(bssrdf_burley_fitting(A.x), bssrdf_burley_fitting(A.y), bssrdf_burley_fitting(A.z));
  Bssrdf_radius_lval(bssrdf) =  l / s; Bssrdf_radius_assign(bssrdf) 

}


ccl_device int bssrdf_setup(ClosureType type)
{
  int flag = 0;
  int bssrdf_channels = 3;
  float3 diffuse_weight = make_float3(0.0f, 0.0f, 0.0f);
  int n0 = nio.alloc_offset;

  /* Verify if the radii are large enough to sample_rsv without precision issues. */
  if (bssrdf.data[0] < BSSRDF_MIN_RADIUS) {
    diffuse_weight.x = bssrdf.weight.x;
    bssrdf.weight.x = 0.0f;
    bssrdf.data[0]= 0.0f;
    bssrdf_channels--;
  }
  if (bssrdf.data[1] < BSSRDF_MIN_RADIUS) {
    diffuse_weight.y = bssrdf.weight.y;
    bssrdf.weight.y = 0.0f;
    bssrdf.data[1] = 0.0f;
    bssrdf_channels--;
  }
  if (bssrdf.data[2] < BSSRDF_MIN_RADIUS) {
    diffuse_weight.z = bssrdf.weight.z;
    bssrdf.weight.z = 0.0f;
    bssrdf.data[2] = 0.0f;
    bssrdf_channels--;
  }

  if (bssrdf_channels < 3) {
    /* Add diffuse BSDF if any radius too small. */

#ifdef _PRINCIPLED_

    if (type == CLOSURE_BSSRDF_PRINCIPLED_ID || type == CLOSURE_BSSRDF_PRINCIPLED_RANDOM_WALK_ID) {
      float roughness = Bssrdf_roughness(bssrdf);
      float3 N = as_float3(bssrdf.N);
      int n = bsdf_alloc(sizeof_PrincipledDiffuseBsdf, diffuse_weight);
      if (n >= 0) {
        DEF_BSDF.type = CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID;
        DEF_BSDF.N = vec4(N,0);
        PrincipledDiffuse_roughness(DEF_BSDF)= roughness;
        flag |= bsdf_principled_diffuse_setup();
      }
    }
    else
#endif /* _PRINCIPLED_ */
    {
      vec4 N = bssrdf.N;
      int n = bsdf_alloc(sizeof_DiffuseBsdf, diffuse_weight);
      if (n >= 0) {
       DEF_BSDF.type = CLOSURE_BSDF_BSSRDF_ID;
       DEF_BSDF.N = N;
       flag |= bsdf_diffuse_setup();
      }
    }
  }

  int n1 = nio.alloc_offset;
  nio.alloc_offset = n0;
  /* Setup BSSRDF if radius is large enough. */
  if (bssrdf_channels > 0) {
    bssrdf.type = type;
    Bssrdf_channels(bssrdf) = bssrdf_channels;
    bssrdf.sample_weight = fabsf(average(as_float3(bssrdf.weight))) * Bssrdf_channels(bssrdf);
    Bssrdf_texture_blur(bssrdf) = saturate(Bssrdf_texture_blur(bssrdf));
    Bssrdf_sharpness(bssrdf) = saturate(Bssrdf_sharpness(bssrdf));

    if (type == CLOSURE_BSSRDF_BURLEY_ID || type == CLOSURE_BSSRDF_PRINCIPLED_ID ||
        type == CLOSURE_BSSRDF_RANDOM_WALK_ID ||
        type == CLOSURE_BSSRDF_PRINCIPLED_RANDOM_WALK_ID) {
      bssrdf_burley_setup();
    }

    flag |= int(SD_BSSRDF);
  }
  else {
    bssrdf.type = type;
    bssrdf.sample_weight = 0.0f;
  }
  
  nio.alloc_offset = n1;
  return flag;
}


#else
#define GAUSS_TRUNCATE 12.46f

ccl_device float bssrdf_gaussian_eval(const float radius, float r)
{
  /* integrate (2*pi*r * exp(-r*r/(2*v)))/(2*pi*v)) from 0 to Rm
   * = 1 - exp(-Rm*Rm/(2*v)) */
  const float v = radius * radius * (0.25f * 0.25f);
  const float Rm = sqrtf(v * GAUSS_TRUNCATE);

  if (r >= Rm)
    return 0.0f;

  return expf(-r * r / (2.0f * v)) / (2.0f * M_PI_F * v);
}

ccl_device float bssrdf_gaussian_pdf(const float radius, float r)
{
  /* 1.0 - expf(-Rm*Rm/(2*v)) simplified */
  const float area_truncated = 1.0f - expf(-0.5f * GAUSS_TRUNCATE);

  return bssrdf_gaussian_eval(radius, r) * (1.0f / (area_truncated));
}

ccl_device void bssrdf_gaussian_sample(const float radius, float xi, inout float r, inout float h)
{
  /* xi = integrate (2*pir * exp(-rr/(2*v)))/(2*pi*v)) = -exp(-r^2/(2*v))
   * r = sqrt(-2*v*logf(xi)) */
  const float v = radius * radius * (0.25f * 0.25f);
  const float Rm = sqrtf(v * GAUSS_TRUNCATE);

  /* 1.0 - expf(-Rm*Rm/(2*v)) simplified */
  const float area_truncated = 1.0f - expf(-0.5f * GAUSS_TRUNCATE);

  /* r(xi) */
  const float r_squared = -2.0f * v * logf(1.0f - xi * area_truncated);
  r = sqrtf(r_squared);

  /* h^2 + r^2 = Rm^2 */
  h = safe_sqrtf(Rm * Rm - r_squared);
}

/* Planar Cubic BSSRDF falloff
 *
 * This is basically (Rm - x)^3, with some factors to normalize it. For sampling
 * we integrate 2*pi*x * (Rm - x)^3, which gives us a quintic equation that as
 * far as I can tell has no closed form solution. So we get an iterative solution
 * instead with newton-raphson. */

ccl_device float bssrdf_cubic_eval(const float radius, const float sharpness, float r)
{
  if (sharpness == 0.0f) {
    const float Rm = radius;

    if (r >= Rm)
      return 0.0f;

    /* integrate (2*pi*r * 10*(R - r)^3)/(pi * R^5) from 0 to R = 1 */
    const float Rm5 = (Rm * Rm) * (Rm * Rm) * Rm;
    const float f = Rm - r;
    const float num = f * f * f;

    return (10.0f * num) / (Rm5 * M_PI_F);
  }
  else {
    float Rm = radius * (1.0f + sharpness);

    if (r >= Rm)
      return 0.0f;

    /* custom variation with extra sharpness, to match the previous code */
    const float y = 1.0f / (1.0f + sharpness);
    float Rmy, ry, ryinv;

    if (sharpness == 1.0f) {
      Rmy = sqrtf(Rm);
      ry = sqrtf(r);
      ryinv = (ry > 0.0f) ? 1.0f / ry : 0.0f;
    }
    else {
      Rmy = powf(Rm, y);
      ry = powf(r, y);
      ryinv = (r > 0.0f) ? powf(r, y - 1.0f) : 0.0f;
    }

    const float Rmy5 = (Rmy * Rmy) * (Rmy * Rmy) * Rmy;
    const float f = Rmy - ry;
    const float num = f * (f * f) * (y * ryinv);

    return (10.0f * num) / (Rmy5 * M_PI_F);
  }
}

ccl_device float bssrdf_cubic_pdf(const float radius, const float sharpness, float r)
{
  return bssrdf_cubic_eval(radius, sharpness, r);
}

/* solve 10x^2 - 20x^3 + 15x^4 - 4x^5 - xi == 0 */
ccl_device_forceinline float bssrdf_cubic_quintic_root_find(float xi)
{
  /* newton-raphson iteration, usually succeeds in 2-4 iterations, except
   * outside 0.02 ... 0.98 where it can go up to 10, so overall performance
   * should not be too bad */
  const float tolerance = 1e-6f;
  const int max_iteration_count = 10;
  float x = 0.25f;
  int i;

  for (i = 0; i < max_iteration_count; i++) {
    float x2 = x * x;
    float x3 = x2 * x;
    float nx = (1.0f - x);

    float f = 10.0f * x2 - 20.0f * x3 + 15.0f * x2 * x2 - 4.0f * x2 * x3 - xi;
    float f_ = 20.0f * (x * nx) * (nx * nx);

    if (fabsf(f) < tolerance || f_ == 0.0f)
      break;

    x = saturate(x - f / f_);
  }

  return x;
}

ccl_device void bssrdf_cubic_sample(
    const float radius, const float sharpness, float xi, inout float r, inout float h)
{
  float Rm = radius;
  float r_ = bssrdf_cubic_quintic_root_find(xi);

  if (sharpness != 0.0f) {
    r_ = powf(r_, 1.0f + sharpness);
    Rm *= (1.0f + sharpness);
  }

  r_ *= Rm;
  r = r_;

  /* h^2 + r^2 = Rm^2 */
  h = safe_sqrtf(Rm * Rm - r_ * r_);
}

/* Approximate Reflectance Profiles
 * http://graphics.pixar.com/library/ApproxBSSRDF/paper.pdf
 */

/* This is a bit arbitrary, just need big enough radius so it matches
 * the mean free length, but still not too big so sampling is still
 * effective. Might need some further tweaks.
 */


ccl_device float bssrdf_burley_eval(const float d, float r)
{
  const float Rm = BURLEY_TRUNCATE * d;

  if (r >= Rm)
    return 0.0f;

  /* Burley reflectance profile, equation (3).
   *
   * NOTES:
   * - Surface albedo is already included into sc.weight, no need to
   *   multiply by this term here.
   * - This is normalized diffuse model, so the equation is multiplied
   *   by 2*pi, which also matches cdf().
   */
  float exp_r_3_d = expf(-r / (3.0f * d));
  float exp_r_d = exp_r_3_d * exp_r_3_d * exp_r_3_d;
  return (exp_r_d + exp_r_3_d) / (4.0f * d);
}

ccl_device float bssrdf_burley_pdf(const float d, float r)
{
  return bssrdf_burley_eval(d, r) * (1.0f / BURLEY_TRUNCATE_CDF);
}

/* Find the radius for desired CDF value.
 * Returns scaled radius, meaning the result is to be scaled up by d.
 * Since there's no closed form solution we do Newton-Raphson method to find it.
 */
ccl_device_forceinline float bssrdf_burley_root_find(float xi)
{
  const float tolerance = 1e-6f;
  const int max_iteration_count = 10;
  /* Do initial guess based on manual curve fitting, this allows us to reduce
   * number of iterations to maximum 4 across the [0..1] range. We keep maximum
   * number of iteration higher just to be sure we didn't miss root in some
   * corner case.
   */
  float r;
  if (xi <= 0.9f) {
    r = expf(xi * xi * 2.4f) - 1.0f;
  }
  else {
    /* TODO(sergey): Some nicer curve fit is possible here. */
    r = 15.0f;
  }
  /* Solve against scaled radius. */
  for (int i = 0; i < max_iteration_count; i++) {
    float exp_r_3 = expf(-r / 3.0f);
    float exp_r = exp_r_3 * exp_r_3 * exp_r_3;
    float f = 1.0f - 0.25f * exp_r - 0.75f * exp_r_3 - xi;
    float f_ = 0.25f * exp_r + 0.25f * exp_r_3;

    if (fabsf(f) < tolerance || f_ == 0.0f) {
      break;
    }

    r = r - f / f_;
    if (r < 0.0f) {
      r = 0.0f;
    }
  }
  return r;
}

ccl_device void bssrdf_burley_sample(const float d, float xi, inout float r, inout float h)
{
  const float Rm = BURLEY_TRUNCATE * d;
  const float r_ = bssrdf_burley_root_find(xi * BURLEY_TRUNCATE_CDF) * d;

  r = r_;

  /* h^2 + r^2 = Rm^2 */
  h = safe_sqrtf(Rm * Rm - r_ * r_);
}

/* None BSSRDF falloff
 *
 * Samples distributed over disk with no falloff, for reference. */

ccl_device float bssrdf_none_eval(const float radius, float r)
{
  const float Rm = radius;
  return (r < Rm) ? 1.0f : 0.0f;
}

ccl_device float bssrdf_none_pdf(const float radius, float r)
{
  /* integrate (2*pi*r)/(pi*Rm*Rm) from 0 to Rm = 1 */
  const float Rm = radius;
  const float area = (M_PI_F * Rm * Rm);

  return bssrdf_none_eval(radius, r) / area;
}

ccl_device void bssrdf_none_sample(const float radius, float xi, inout float r, inout float h)
{
  /* xi = integrate (2*pir)/(pi*Rm*Rm) = r^2/Rm^2
   * r = sqrt(xi)*Rm */
  const float Rm = radius;
  const float r_ = sqrtf(xi) * Rm;

  r = r_;

  /* h^2 + r^2 = Rm^2 */
  h = safe_sqrtf(Rm * Rm - r_ * r_);
}


ccl_device void bssrdf_sample(int scN,float xi, inout float r, inout float h)
{
  
  float radius;
  /* Sample color channel and reuse random number. Only a subset of channels
   * may be used if their radius was too small to handle as BSSRDF. */
  xi *= Bssrdf_channels(_getSC(scN));
  if (xi < 1.0f) {
    radius = (_getSC(scN).data[0] > 0.0f) ? _getSC(scN).data[0] :
             (_getSC(scN).data[1] > 0.0f) ? _getSC(scN).data[1] : _getSC(scN).data[2];
  }
  else if (xi < 2.0f) {
    xi -= 1.0f;
    radius = (_getSC(scN).data[0] > 0.0f) ? _getSC(scN).data[1] : _getSC(scN).data[2];
  }
  else {
    xi -= 2.0f;
    radius = _getSC(scN).data[2];
  }
  /* Sample BSSRDF. */
  if (_getSC(scN).type == CLOSURE_BSSRDF_CUBIC_ID) {
    bssrdf_cubic_sample(radius, Bssrdf_sharpness(_getSC(scN)), xi, r, h);
  }
  else if (_getSC(scN).type == CLOSURE_BSSRDF_GAUSSIAN_ID) {
    bssrdf_gaussian_sample(radius, xi, r, h);
  }
  else { /* if (bssrdf.type == CLOSURE_BSSRDF_BURLEY_ID ||
          *     bssrdf.type == CLOSURE_BSSRDF_PRINCIPLED_ID) */
    bssrdf_burley_sample(radius, xi, r, h);
  }

}

ccl_device float bssrdf_channel_pdf(float radius, float r)
{
  if (radius == 0.0f) {
    return 0.0f;
  }
  else if (getSC().type == CLOSURE_BSSRDF_CUBIC_ID) {
    return bssrdf_cubic_pdf(radius, Bssrdf_sharpness(getSC()), r);
  }
  else if (getSC().type == CLOSURE_BSSRDF_GAUSSIAN_ID) {
    return bssrdf_gaussian_pdf(radius, r);
  }
  else { /* if (bssrdf.type == CLOSURE_BSSRDF_BURLEY_ID ||
          *     bssrdf.type == CLOSURE_BSSRDF_PRINCIPLED_ID)*/
    return bssrdf_burley_pdf(radius, r);
  }
}

ccl_device_forceinline float3 bssrdf_eval(float r)
{

  return make_float3(bssrdf_channel_pdf(getSC().data[0], r),
                     bssrdf_channel_pdf(getSC().data[1], r),
                     bssrdf_channel_pdf(getSC().data[2], r));
}

ccl_device_forceinline float bssrdf_pdf(float r)
{  
  float3 pdf = bssrdf_eval(r);
  return (pdf.x + pdf.y + pdf.z) / Bssrdf_channels(getSC());
}

#endif
CCL_NAMESPACE_END




#endif /* _KERNEL_BSSRDF_H_ */
