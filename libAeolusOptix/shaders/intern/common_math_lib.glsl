#ifndef _COMMON_MATH_LIB_
#define _COMMON_MATH_LIB_
/* ---------------------------------------------------------------------- */
/** \name Common Math Utilities
 * \{ */

#define M_PI 3.14159265358979323846     /* pi */
#define M_2PI 6.28318530717958647692    /* 2*pi */
#define M_PI_2 1.57079632679489661923   /* pi/2 */
#define M_1_PI 0.318309886183790671538  /* 1/pi */
#define M_1_2PI 0.159154943091895335768 /* 1/(2*pi) */
#define M_1_PI2 0.101321183642337771443 /* 1/(pi^2) */
//#define FLT_MAX 3.402823e+38

vec3 mul(mat3 m, vec3 v)
{
  return m * v;
}
mat3 mul(mat3 m1, mat3 m2)
{
  return m1 * m2;
}
vec3 transform_direction(mat4 m, vec3 v)
{
  return mat3(m) * v;
}
vec3 transform_point(mat4 m, vec3 v)
{
  return (m * vec4(v, 1.0)).xyz;
}
vec3 project_point(mat4 m, vec3 v)
{
  vec4 tmp = m * vec4(v, 1.0);
  return tmp.xyz / tmp.w;
}
/*
#define min3(a, b, c) min(a, min(b, c))
#define min4(a, b, c, d) min(a, min3(b, c, d))
#define min5(a, b, c, d, e) min(a, min4(b, c, d, e))
#define min6(a, b, c, d, e, f) min(a, min5(b, c, d, e, f))
#define min7(a, b, c, d, e, f, g) min(a, min6(b, c, d, e, f, g))
#define min8(a, b, c, d, e, f, g, h) min(a, min7(b, c, d, e, f, g, h))
#define min9(a, b, c, d, e, f, g, h, i) min(a, min8(b, c, d, e, f, g, h, i))

#define max3(a, b, c) max(a, max(b, c))
#define max4(a, b, c, d) max(a, max3(b, c, d))
#define max5(a, b, c, d, e) max(a, max4(b, c, d, e))
#define max6(a, b, c, d, e, f) max(a, max5(b, c, d, e, f))
#define max7(a, b, c, d, e, f, g) max(a, max6(b, c, d, e, f, g))
#define max8(a, b, c, d, e, f, g, h) max(a, max7(b, c, d, e, f, g, h))
#define max9(a, b, c, d, e, f, g, h, i) max(a, max8(b, c, d, e, f, g, h, i))
*/
#define avg3(a, b, c) (a + b + c) * (1.0 / 3.0)
#define avg4(a, b, c, d) (a + b + c + d) * (1.0 / 4.0)
#define avg5(a, b, c, d, e) (a + b + c + d + e) * (1.0 / 5.0)
#define avg6(a, b, c, d, e, f) (a + b + c + d + e + f) * (1.0 / 6.0)
#define avg7(a, b, c, d, e, f, g) (a + b + c + d + e + f + g) * (1.0 / 7.0)
#define avg8(a, b, c, d, e, f, g, h) (a + b + c + d + e + f + g + h) * (1.0 / 8.0)
#define avg9(a, b, c, d, e, f, g, h, i) (a + b + c + d + e + f + g + h + i) * (1.0 / 9.0)

/* clang-format off */
float min_v2(vec2 v) { return min(v.x, v.y); }
float min_v3(vec3 v) { return min(v.x, min(v.y, v.z)); }
float min_v4(vec4 v) { return min(min(v.x, v.y), min(v.z, v.w)); }
float max_v2(vec2 v) { return max(v.x, v.y); }
float max_v3(vec3 v) { return max(v.x, max(v.y, v.z)); }
float max_v4(vec4 v) { return max(max(v.x, v.y), max(v.z, v.w)); }

float sum(vec2 v) { return dot(vec2(1.0), v); }
float sum(vec3 v) { return dot(vec3(1.0), v); }
float sum(vec4 v) { return dot(vec4(1.0), v); }
/// vec4 == float3
float sum_float3(vec4 v) { return dot(vec3(1.0), v.xyz); }

float avg(vec2 v) { return dot(vec2(1.0 / 2.0), v); }
float avg(vec3 v) { return dot(vec3(1.0 / 3.0), v); }
float avg(vec4 v) { return dot(vec4(1.0 / 4.0), v); }
float avg_float3(vec4 v) { return dot(vec3(1.0 / 3.0), v.xyz); }

/* clang-format on */

#define saturate(a) clamp(a, 0.0, 1.0)

float distance_squared(vec2 a, vec2 b)
{
  a -= b;
  return dot(a, a);
}

float distance_squared(vec3 a, vec3 b)
{
  a -= b;
  return dot(a, a);
}

/*
float len_squared(vec3 a)
{
  return dot(a, a);
}
*/

/** \} */

/* ---------------------------------------------------------------------- */
/** \name Fast Math
 * \{ */

/* [Drobot2014a] Low Level Optimizations for GCN */
float fast_sqrt(float v)
{
  return intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(v) >> 1));
}

vec2 fast_sqrt(vec2 v)
{
  return intBitsToFloat(0x1fbd1df5 + (floatBitsToInt(v) >> 1));
}

/* [Eberly2014] GPGPU Programming for Games and Science */
float fast_acos(float v)
{
  float res = -0.156583 * abs(v) + M_PI_2;
  res *= fast_sqrt(1.0 - abs(v));
  return (v >= 0) ? res : M_PI - res;
}

vec2 fast_acos(vec2 v)
{
  vec2 res = -0.156583 * abs(v) + M_PI_2;
  res *= fast_sqrt(1.0 - abs(v));
  v.x = (v.x >= 0) ? res.x : M_PI - res.x;
  v.y = (v.y >= 0) ? res.y : M_PI - res.y;
  return v;
}

/** \} */
#endif