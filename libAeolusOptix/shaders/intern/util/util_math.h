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

#ifndef __UTIL_MATH_H__
#define __UTIL_MATH_H__

#ifndef __KERNEL_VULKAN__
      #pragma warning(disable:4146)
      #ifndef __KERNEL_GPU__
      #  include <cmath>
      #endif
      #ifndef __KERNEL_OPENCL__
      #  include <float.h>
      #  include <math.h>
      #  include <stdio.h>
      #endif /* __KERNEL_OPENCL__ */
#include "util/util_types.h"
#else



#extension GL_EXT_shader_explicit_arithmetic_types_float32 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_float64 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int16 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int32 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int64 : enable
precision highp float;

#define CHAR_BIT         8
#define SCHAR_MAX        127
#define SCHAR_MIN        (-127-1)
#define CHAR_MAX         SCHAR_MAX
#define CHAR_MIN         SCHAR_MIN
#define UCHAR_MAX        255
#define SHRT_MAX         32767
#define SHRT_MIN         (-32767-1)
#define USHRT_MAX        65535
#define INT_MAX          2147483647
#define INT_MIN          (-2147483647-1)
#define UINT_MAX         0xffffffffU
#define LONG_MAX         0x7fffffffffffffffL
#define LONG_MIN         (-0x7fffffffffffffffL-1)
#define ULONG_MAX        ((ulong) 0xFFFFFFFFFFFFFFFFULL)

#define NULL_FLT FLT_MAX
#define NULL_INT INT_MIN
#define NULL_UINT UINT_MAX

#define isNULL4(a) (a.x==FLT_MAX)
#define isNULL3(a) (a.x==FLT_MAX)
#define isNULL2(a) (a.x==FLT_MAX)
#define isNULL(a)  (a==FLT_MAX)
#define isNULLI(a) (a==INT_MIN)
#define isNULLU(a) (a==NULL_UINT)

float null_flt = NULL_FLT;
vec2 null_flt2 = vec2(NULL_FLT);
vec4 null_flt3 = vec4(NULL_FLT);
vec4 null_flt4 = vec4(NULL_FLT);
int null_int = NULL_INT;
uint null_uint = NULL_UINT;




#define len length
#define interp mix

#define sinf sin
#define cosf cos
#define tanf tan

#define sinhf sinh
#define coshf cosh
#define tanhf tanh

#define sqrtf sqrt
#define fmaxf max
#define fminf min

#define asinf  asin
#define asinhf asinh
#define acosf acos
#define acoshf acosh
#define atanf atan   
#define atanhf atanh
#define atan2f atan
#define absf abs
#define fabs abs
#define fabsf abs
#define fmodf mod
#define powf pow
#define logf log


const double LGAMMA_LANCOZ[6] = double[6]( 76.18009172947146,
    -86.50532032941677, 24.01409824083091,
    -1.231739572450155, 0.1208650973866179E-2,
    -0.5395239384953E-5 );

#  define M_LN_SQR_2PI_F 0.91893853320467274178

/// https://jamesmccaffrey.wordpress.com/2013/06/19/the-log-gamma-function-with-c/
double lgamma(double x)
{
  // Log of Gamma from Lanczos with g=5, n=6/7
  // not in A & S 

  double denom = x + 1;
  double y = x + 5.5;
  double series = 1.000000000190015;
  for (int i = 0; i < 6; ++i)
   {
    series += LGAMMA_LANCOZ[i] / denom;
    denom += 1.0;
  }

  return (M_LN_SQR_2PI_F + (x + 0.5) * log(y) - y + log(series / x));
}

#define lgammaf(v) float(lgamma(double(v)))
#define expf exp

#include "util/util_types.h.glsl"
#endif




CCL_NAMESPACE_BEGIN

/* Float Pi variations */

/* Division */
#ifndef M_PI_F
#  define M_PI_F (3.1415926535897932f) /* pi */
#endif
#ifndef M_PI_2_F
#  define M_PI_2_F (1.5707963267948966f) /* pi/2 */
#endif
#ifndef M_PI_4_F
#  define M_PI_4_F (0.7853981633974830f) /* pi/4 */
#endif
#ifndef M_1_PI_F
#  define M_1_PI_F (0.3183098861837067f) /* 1/pi */
#endif
#ifndef M_2_PI_F
#  define M_2_PI_F (0.6366197723675813f) /* 2/pi */
#endif
#ifndef M_1_2PI_F
#  define M_1_2PI_F (0.1591549430918953f) /* 1/(2*pi) */
#endif
#ifndef M_SQRT_PI_8_F
#  define M_SQRT_PI_8_F (0.6266570686577501f) /* sqrt(pi/8) */
#endif
#ifndef M_LN_2PI_F
#  define M_LN_2PI_F (1.8378770664093454f) /* ln(2*pi) */
#endif

/* Multiplication */
#ifndef M_2PI_F
#  define M_2PI_F (6.2831853071795864f) /* 2*pi */
#endif
#ifndef M_4PI_F
#  define M_4PI_F (12.566370614359172f) /* 4*pi */
#endif

/* Float sqrt variations */
#ifndef M_SQRT2_F
#  define M_SQRT2_F (1.4142135623730950f) /* sqrt(2) */
#endif
#ifndef M_LN2_F
#  define M_LN2_F (0.6931471805599453f) /* ln(2) */
#endif
#ifndef M_LN10_F
#  define M_LN10_F (2.3025850929940457f) /* ln(10) */
#endif

/* Scalar */

#ifdef _WIN32
#  ifndef __KERNEL_OPENCL__
ccl_device_inline float fmaxf(float a, float b)
{
  return (a > b) ? a : b;
}

ccl_device_inline float fminf(float a, float b)
{
  return (a < b) ? a : b;
}
#  endif /* !__KERNEL_OPENCL__ */
#endif   /* _WIN32 */





#ifndef __KERNEL_GPU__
using std::isfinite;
using std::isnan;
using std::sqrt;

ccl_device_inline int abs(int x)
{
  return (x > 0) ? x : -x;
}

ccl_device_inline int max(int a, int b)
{
  return (a > b) ? a : b;
}

ccl_device_inline int min(int a, int b)
{
  return (a < b) ? a : b;
}

ccl_device_inline float max(float a, float b)
{
  return (a > b) ? a : b;
}

ccl_device_inline float min(float a, float b)
{
  return (a < b) ? a : b;
}

ccl_device_inline double max(double a, double b)
{
  return (a > b) ? a : b;
}

ccl_device_inline double min(double a, double b)
{
  return (a < b) ? a : b;
}

/* These 2 guys are templated for usage with registers data.
 *
 * NOTE: Since this is CPU-only functions it is ok to use references here.
 * But for other devices we'll need to be careful about this.
 */

template<typename T> ccl_device_inline T min4(const T &a, const T &b, const T &c, const T &d)
{
  return min(min(a, b), min(c, d));
}

template<typename T> ccl_device_inline T max4(const T &a, const T &b, const T &c, const T &d)
{
  return max(max(a, b), max(c, d));
}
#endif /* __KERNEL_GPU__ */

ccl_device_inline float min4(float a, float b, float c, float d)
{
  return min(min(a, b), min(c, d));
}

ccl_device_inline float max4(float a, float b, float c, float d)
{
  return max(max(a, b), max(c, d));
}

#ifndef __KERNEL_OPENCL__
/* Int/Float conversion */
#ifdef __KERNEL_VULKAN__
#define as_int  int
#define as_uint uint

#define __float_as_uint floatBitsToUint
#define __float_as_int  floatBitsToInt

#define __int_as_float  intBitsToFloat
#define __uint_as_float uintBitsToFloat

#define __float4_as_int4 floatBitsToInt
#define __int4_as_float4 intBitsToFloat
#else
ccl_device_inline int as_int(uint i)
{
  union {
    uint ui;
    int i;
  } u;
  u.ui = i;
  return u.i;
}

ccl_device_inline uint as_uint(int i)
{
  union {
    uint ui;
    int i;
  } u;
  u.i = i;
  return u.ui;
}

ccl_device_inline uint as_uint(float f)
{
  union {
    uint i;
    float f;
  } u;
  u.f = f;
  return u.i;
}

ccl_device_inline int __float_as_int(float f)
{
  union {
    int i;
    float f;
  } u;
  u.f = f;
  return u.i;
}

ccl_device_inline float __int_as_float(int i)
{
  union {
    int i;
    float f;
  } u;
  u.i = i;
  return u.f;
}

ccl_device_inline uint __float_as_uint(float f)
{
  union {
    uint i;
    float f;
  } u;
  u.f = f;
  return u.i;
}

ccl_device_inline float __uint_as_float(uint i)
{
  union {
    uint i;
    float f;
  } u;
  u.i = i;
  return u.f;
}

ccl_device_inline int4 __float4_as_int4(float4 f)
{
#  ifdef __KERNEL_SSE__
  return int4(_mm_castps_si128(f.m128));
#  else
  return make_int4(
      __float_as_int(f.x), __float_as_int(f.y), __float_as_int(f.z), __float_as_int(f.w));
#  endif
}

ccl_device_inline float4 __int4_as_float4(int4 i)
{
#  ifdef __KERNEL_SSE__
  return float4(_mm_castsi128_ps(i.m128));
#  else
  return make_float4(
      __int_as_float(i.x), __int_as_float(i.y), __int_as_float(i.z), __int_as_float(i.w));
#  endif
}

#endif

#endif /* __KERNEL_OPENCL__ */

/* Versions of functions which are safe for fast math. */
ccl_device_inline bool isnan_safe(float f)
{
  unsigned int x = __float_as_uint(f);
  return (x << 1) > 0xff000000u;
}

ccl_device_inline bool isfinite_safe(float f)
{
  /* By IEEE 754 rule, 2*Inf equals Inf */
  unsigned int x = __float_as_uint(f);
  return (f == f) && (x == 0 || x == (1u << 31) || (f != 2.0f * f)) && !((x << 1) > 0xff000000u);
}

ccl_device_inline float ensure_finite(float v)
{
  return isfinite_safe(v) ? v : 0.0f;
}

#if (!defined(__KERNEL_OPENCL__) & !defined(__KERNEL_VULKAN__))
ccl_device_inline int clamp(int a, int mn, int mx)
{
  return min(max(a, mn), mx);
}

ccl_device_inline float clamp(float a, float mn, float mx)
{
  return min(max(a, mn), mx);
}

ccl_device_inline float mix(float a, float b, float t)
{
  return a + t * (b - a);
}

ccl_device_inline float smoothstep(float edge0, float edge1, float x)
{
  float result;
  if (x < edge0)
    result = 0.0f;
  else if (x >= edge1)
    result = 1.0f;
  else {
    float t = (x - edge0) / (edge1 - edge0);
    result = (3.0f - 2.0f * t) * (t * t);
  }
  return result;
}

#endif /* __KERNEL_OPENCL__ */

#ifndef __KERNEL_CUDA__
ccl_device_inline float saturate(float a)
{
  return clamp(a, 0.0f, 1.0f);
}
#endif /* __KERNEL_CUDA__ */


#ifdef __KERNEL_VULKAN__
#define  float_to_int int
#define  floorf floor
#define  ceilf ceil
#define  fractf fract
#else

ccl_device_inline int float_to_int(float f)
{
  return (int)f;
}
ccl_device_inline float fractf(float x)
{
  return x - floorf(x);
}
#endif

ccl_device_inline int floor_to_int(float f)
{
  return float_to_int(floorf(f));
}

ccl_device_inline int quick_floor_to_int(float x)
{
  return float_to_int(x) - ((x < 0) ? 1 : 0);
}

ccl_device_inline float floorfrac(float x,inout int i)
{
  i = quick_floor_to_int(x);
  return x - i;
}

ccl_device_inline int ceil_to_int(float f)
{
  return float_to_int(ceilf(f));
}



/* Adapted from godotengine math_funcs.h. */
ccl_device_inline float wrapf(float value, float max, float min)
{
  float range = max - min;
  return (range != 0.0f) ? value - (range * floorf((value - min) / range)) : min;
}

ccl_device_inline float pingpongf(float a, float b)
{
  return (b != 0.0f) ? fabsf(fractf((a - b) / (b * 2.0f)) * b * 2.0f - b) : 0.0f;
}

ccl_device_inline float smoothminf(float a, float b, float k)
{
  if (k != 0.0f) {
    float h = fmaxf(k - fabsf(a - b), 0.0f) / k;
    return fminf(a, b) - h * h * h * k * (1.0f / 6.0f);
  }
  else {
    return fminf(a, b);
  }
}

ccl_device_inline float signf(float f)
{
  return (f < 0.0f) ? -1.0f : 1.0f;
}

ccl_device_inline float nonzerof(float f, float eps)
{
  if (fabsf(f) < eps)
    return signf(f) * eps;
  else
    return f;
}

/* Signum function testing for zero. Matches GLSL and OSL functions. */
ccl_device_inline float compatible_signf(float f)
{
  if (f == 0.0f) {
    return 0.0f;
  }
  else {
    return signf(f);
  }
}

ccl_device_inline float smoothstepf(float f)
{
  float ff = f * f;
  return (3.0f * ff - 2.0f * ff * f);
}

ccl_device_inline int mod(int x, int m)
{
  return (x % m + m) % m;
}

ccl_device_inline float3 float2_to_float3(const float2 a)
{
  return make_float3(a.x, a.y, 0.0f);
}

ccl_device_inline float3 float4_to_float3(const float4 a)
{
  return make_float3(a.x, a.y, a.z);
}

ccl_device_inline float4 float3_to_float4(const float3 a)
{
  return make_float4(a.x, a.y, a.z, 1.0f);
}

ccl_device_inline float inverse_lerp(float a, float b, float x)
{
  return (x - a) / (b - a);
}

/* Cubic interpolation between b and c, a and d are the previous and next point. */
ccl_device_inline float cubic_interp(float a, float b, float c, float d, float x)
{
  return 0.5f *
             (((d + 3.0f * (b - c) - a) * x + (2.0f * a - 5.0f * b + 4.0f * c - d)) * x +
              (c - a)) *
             x +
         b;
}

CCL_NAMESPACE_END

#ifdef __KERNEL_VULKAN__

#include "util/util_math_float2.h.glsl"
#include "util/util_math_float3.h.glsl"
#include "util/util_math_float4.h.glsl"
#include "util/util_rect.h.glsl"

#else

#include "util/util_math_int2.h"
#include "util/util_math_int3.h"
#include "util/util_math_int4.h"

#include "util/util_math_float2.h"
#include "util/util_math_float3.h"
#include "util/util_math_float4.h"

#include "util/util_rect.h"
#endif

CCL_NAMESPACE_BEGIN

#if defined(__KERNEL_VULKAN__) 

#define LERP(A,B) A(a * (B(1) - t) + b * t)
#define _lerp(A,B) A lerp(A a, const A b, const B t){ return LERP(A,B);}

_lerp(float,float)

#define COPYSIGN_BODY(T) { T r = abs(a); T s = sign(b);return (s >= T(0))?r:-r;}
#define _copysign(T) T copysign(in T a,in T b) COPYSIGN_BODY(T)

_copysign(int)

#define _copysignf(T) T copysignf(in T a,in T b) COPYSIGN_BODY(T)

_copysignf(float)


#define _copysignl(T) T copysignl(in T a,in T b) COPYSIGN_BODY(T)
_copysignl(double)



#elif !defined(__KERNEL_OPENCL__)

template<class A, class B> A lerp(const A &a, const A &b, const B &t)
{
  return (A)(a * ((B)1 - t) + b * t);
}

#endif /* __KERNEL_OPENCL__ */

/* Triangle */
#if defined(__KERNEL_VULKAN__) 
ccl_device_inline float triangle_area(const float3 v1, const float3 v2, const float3 v3)
#elif !defined(__KERNEL_OPENCL__)
ccl_device_inline float triangle_area(const float3 &v1, const float3 &v2, const float3 &v3)
#else
ccl_device_inline float triangle_area(const float3 v1, const float3 v2, const float3 v3)
#endif
{
  return len(cross(v3.xyz - v2.xyz, v1.xyz - v2.xyz)) * 0.5f;
}

/* Orthonormal vectors */
#if defined(__KERNEL_VULKAN__) 

ccl_device_inline void make_orthonormals(in float3 N,inout float3 a,out float3 b)
{
  if (N.x != N.y || N.x != N.z)
    a = make_float3(N.z - N.y, N.x - N.z, N.y - N.x);  //(1,1,1)x N
  else
    a = make_float3(N.z - N.y, N.x + N.z, -N.y - N.x);  //(-1,1,1)x N

  a.xyz = normalize(a.xyz);
  b.xyz = cross(N.xyz, a.xyz);

}


#else
ccl_device_inline void make_orthonormals(const float3 N, float3 *a, float3 *b)
{
#if 0
  if (fabsf(N.y) >= 0.999f) {
    *a = make_float3(1, 0, 0);
    *b = make_float3(0, 0, 1);
    return;
  }
  if (fabsf(N.z) >= 0.999f) {
    *a = make_float3(1, 0, 0);
    *b = make_float3(0, 1, 0);
    return;
  }
#endif

  if (N.x != N.y || N.x != N.z)
    *a = make_float3(N.z - N.y, N.x - N.z, N.y - N.x);  //(1,1,1)x N
  else
    *a = make_float3(N.z - N.y, N.x + N.z, -N.y - N.x);  //(-1,1,1)x N

  *a = normalize(*a);
  *b = cross(N, *a);
}


#endif
/* Color division */

ccl_device_inline float3 safe_invert_color(float3 a)
{
  float x, y, z;

  x = (a.x != 0.0f) ? 1.0f / a.x : 0.0f;
  y = (a.y != 0.0f) ? 1.0f / a.y : 0.0f;
  z = (a.z != 0.0f) ? 1.0f / a.z : 0.0f;

  return make_float3(x, y, z);
}

ccl_device_inline float3 safe_divide_color(float3 a, float3 b)
{
  float x, y, z;

  x = (b.x != 0.0f) ? a.x / b.x : 0.0f;
  y = (b.y != 0.0f) ? a.y / b.y : 0.0f;
  z = (b.z != 0.0f) ? a.z / b.z : 0.0f;

  return make_float3(x, y, z);
}

ccl_device_inline float3 safe_divide_even_color(float3 a, float3 b)
{
  float x, y, z;

  x = (b.x != 0.0f) ? a.x / b.x : 0.0f;
  y = (b.y != 0.0f) ? a.y / b.y : 0.0f;
  z = (b.z != 0.0f) ? a.z / b.z : 0.0f;

  /* try to get gray even if b is zero */
  if (b.x == 0.0f) {
    if (b.y == 0.0f) {
      x = z;
      y = z;
    }
    else if (b.z == 0.0f) {
      x = y;
      z = y;
    }
    else
      x = 0.5f * (y + z);
  }
  else if (b.y == 0.0f) {
    if (b.z == 0.0f) {
      y = x;
      z = x;
    }
    else
      y = 0.5f * (x + z);
  }
  else if (b.z == 0.0f) {
    z = 0.5f * (x + y);
  }

  return make_float3(x, y, z);
}

/* Rotation of point around axis and angle */

ccl_device_inline float3 rotate_around_axis(float3 p, float3 axis, float angle)
{
  float costheta = cosf(angle);
  float sintheta = sinf(angle);
  float3 r;

  r.x = ((costheta + (1 - costheta) * axis.x * axis.x) * p.x) +
        (((1 - costheta) * axis.x * axis.y - axis.z * sintheta) * p.y) +
        (((1 - costheta) * axis.x * axis.z + axis.y * sintheta) * p.z);

  r.y = (((1 - costheta) * axis.x * axis.y + axis.z * sintheta) * p.x) +
        ((costheta + (1 - costheta) * axis.y * axis.y) * p.y) +
        (((1 - costheta) * axis.y * axis.z - axis.x * sintheta) * p.z);

  r.z = (((1 - costheta) * axis.x * axis.z - axis.y * sintheta) * p.x) +
        (((1 - costheta) * axis.y * axis.z + axis.x * sintheta) * p.y) +
        ((costheta + (1 - costheta) * axis.z * axis.z) * p.z);

  return r;
}

/* NaN-safe math ops */

ccl_device_inline float safe_sqrtf(float f)
{
  return sqrtf(max(f, 0.0f));
}

ccl_device_inline float inversesqrtf(float f)
{
  return (f > 0.0f) ? 1.0f / sqrtf(f) : 0.0f;
}

ccl_device float safe_asinf(float a)
{
  return asinf(clamp(a, -1.0f, 1.0f));
}

ccl_device float safe_acosf(float a)
{
  return acosf(clamp(a, -1.0f, 1.0f));
}

ccl_device float compatible_powf(float x, float y)
{
#ifdef __KERNEL_GPU__
  if (y == 0.0f) /* x^0 -> 1, including 0^0 */
    return 1.0f;

  /* GPU pow doesn't accept negative x, do manual checks here */
  if (x < 0.0f) {
    if (fmodf(-y, 2.0f) == 0.0f)
      return powf(-x, y);
    else
      return -powf(-x, y);
  }
  else if (x == 0.0f)
    return 0.0f;
#endif
  return powf(x, y);
}

ccl_device float safe_powf(float a, float b)
{
  if (UNLIKELY(a < 0.0f && b != float_to_int(b)))
    return 0.0f;

  return compatible_powf(a, b);
}

ccl_device float safe_divide(float a, float b)
{
  return (b != 0.0f) ? a / b : 0.0f;
}

ccl_device float safe_logf(float a, float b)
{
  if (UNLIKELY(a <= 0.0f || b <= 0.0f))
    return 0.0f;

  return safe_divide(logf(a), logf(b));
}

ccl_device float safe_modulo(float a, float b)
{
  return (b != 0.0f) ? fmodf(a, b) : 0.0f;
}

ccl_device_inline float sqr(float a)
{
  return a * a;
}

ccl_device_inline float pow20(float a)
{
  return sqr(sqr(sqr(sqr(a)) * a));
}

ccl_device_inline float pow22(float a)
{
  return sqr(a * sqr(sqr(sqr(a)) * a));
}

ccl_device_inline float beta(float x, float y)
{
#if (!defined(__KERNEL_OPENCL__) | defined(__KERNEL_VULKAN__))
  return expf(lgammaf(x) + lgammaf(y) - lgammaf(x + y));
#else
  return expf(lgamma(x) + lgamma(y) - lgamma(x + y));
#endif
}

ccl_device_inline float xor_signmask(float x, int y)
{
  return __int_as_float(__float_as_int(x) ^ y);
}

ccl_device float bits_to_01(uint bits)
{
 #if defined(__KERNEL_VULKAN__)
  return bits * (1.0f / float(0xFFFFFFFF) );
 #else
  return bits * (1.0f / (float)0xFFFFFFFF);
#endif
}

#ifdef __KERNEL__VULKAN__
//https://foonathan.net/2016/02/implementation-challenge-2/
const uint clz_lookup[16] = uint[16]( 4, 3, 2, 2, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0 );
uint clz8(uint8_t x){
    uint upper = uint(x >> 4);
    uint lower = uint(x & 0x0F);
    return (upper!=0) ? clz_lookup[upper] : 4 + clz_lookup[lower];  
}

uint clz16(uint16_t x){
    // shift upper half down, rest is filled up with 0s
    uint8_t upper = uint8_t(x >> 8);
    uint8_t lower = uint8_t(x & 0xFF);
    return  (upper!=0) ? clz8(upper) :  8 + clz8(lower);
}

uint count_leading_zeros(uint x){
    // shift upper half down, rest is filled up with 0s
    uint16_t upper = uint16_t(x >> 16);
    uint16_t lower = uint16_t(x & 0xFFFF);
    return  (upper!=0) ? clz16(upper) :  16 + clz16(lower);
}



#else
ccl_device_inline uint count_leading_zeros(uint x)
{
#if defined(__KERNEL_CUDA__) || defined(__KERNEL_OPTIX__)
  return __clz(x);
#elif defined(__KERNEL_OPENCL__)
  return clz(x);
#else
  
#  ifdef _MSC_VER
  assert(x != 0);
  unsigned long leading_zero = 0;
  _BitScanReverse(&leading_zero, x);
  return (31 - leading_zero);
#  else
  return __builtin_clz(x);
#  endif
#endif
}

#endif


ccl_device_inline uint count_trailing_zeros(uint x)
{
#if defined(__KERNEL_CUDA__) || defined(__KERNEL_OPTIX__)
  return (__ffs(x) - 1);
#elif defined(__KERNEL_OPENCL__) || defined(__KERNEL__VULKAN__)
  return (31 - count_leading_zeros(x & -x));
#else
  assert(x != 0);
#  ifdef _MSC_VER
  unsigned long ctz = 0;
  _BitScanForward(&ctz, x);
  return ctz;
#  else
  return __builtin_ctz(x);
#  endif
#endif
}

ccl_device_inline uint find_first_set(uint x)
{
#if defined(__KERNEL_CUDA__) || defined(__KERNEL_OPTIX__)
  return __ffs(x);
#elif defined(__KERNEL_OPENCL__) || defined(__KERNEL__VULKAN__)
  return (x != 0) ? (32 - count_leading_zeros(x & (-x))) : 0;
#else
#  ifdef _MSC_VER
  return (x != 0) ? (32 - count_leading_zeros(x & (-x))) : 0;
#  else
  return __builtin_ffs(x);
#  endif
#endif
}

/* projections */
ccl_device_inline float2 map_to_tube(const float3 co)
{
  float len, u, v;
  len = sqrtf(co.x * co.x + co.y * co.y);
  if (len > 0.0f) {
    u = (1.0f - (atan2f(co.x / len, co.y / len) / M_PI_F)) * 0.5f;
    v = (co.z + 1.0f) * 0.5f;
  }
  else {
    u = v = 0.0f;
  }
  return make_float2(u, v);
}

ccl_device_inline float2 map_to_sphere(const float3 co)
{
  float l = len(co);
  float u, v;
  if (l > 0.0f) {
    if (UNLIKELY(co.x == 0.0f && co.y == 0.0f)) {
      u = 0.0f; /* othwise domain error */
    }
    else {
      u = (1.0f - atan2f(co.x, co.y) / M_PI_F) / 2.0f;
    }
    v = 1.0f - safe_acosf(co.z / l) / M_PI_F;
  }
  else {
    u = v = 0.0f;
  }
  return make_float2(u, v);
}

/* Compares two floats.
 * Returns true if their absolute difference is smaller than abs_diff (for numbers near zero)
 * or their relative difference is less than ulp_diff ULPs.
 * Based on
 * https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/
 */

ccl_device_inline float compare_floats(float a, float b, float abs_diff, int ulp_diff)
{
  if (fabsf(a - b) < abs_diff) {
    return 1.f;
  }

  if ((a < 0.0f) != (b < 0.0f)) {
    return 0.f;
  }

  return float((abs(_float_as_int(a) - _float_as_int(b)) < ulp_diff));
}

/* Calculate the angle between the two vectors a and b.
 * The usual approach acos(dot(a, b)) has severe precision issues for small angles,
 * which are avoided by this method.
 * Based on "Mangled Angles" from https://people.eecs.berkeley.edu/~wkahan/Mindless.pdf
 */
ccl_device_inline float precise_angle(float3 a, float3 b)
{
  return 2.0f * atan2f(len(a - b), len(a + b));
}

CCL_NAMESPACE_END

#endif /* __UTIL_MATH_H__ */
