#ifndef _BVH_UTILS_H_
#define _BVH_UTILS_H_

/// bvh.h

float3 ray_offset(in float3 P,in float3 Ng)
{
#ifdef _INTERSECTION_REFINE_
  const float epsilon_f = 1e-5f;
  /* ideally this should match epsilon_f, but instancing and motion blur
   * precision makes it problematic */
  const float epsilon_test = 1.0f;
  const int epsilon_i = 32;

  float3 res;

  /* x component */
  if (fabsf(P.x) < epsilon_test) {
    res.x = P.x + Ng.x * epsilon_f;
  }
  else {
    uint ix = _float_as_uint(P.x);
    ix +=  (bool((ix ^ _float_as_uint(Ng.x)) >> 31)) ? -epsilon_i : epsilon_i;
    res.x = _uint_as_float(ix);
  }

  /* y component */
  if (fabsf(P.y) < epsilon_test) {
    res.y = P.y + Ng.y * epsilon_f;
  }
  else {
    uint iy = _float_as_uint(P.y);
    iy += (bool((iy ^ _float_as_uint(Ng.y)) >> 31)) ? -epsilon_i : epsilon_i;
    res.y = _uint_as_float(iy);
  }

  /* z component */
  if (fabsf(P.z) < epsilon_test) {
    res.z = P.z + Ng.z * epsilon_f;
  }
  else {
    uint iz = _float_as_uint(P.z);
    iz += (bool((iz ^ _float_as_uint(Ng.z)) >> 31) )? -epsilon_i : epsilon_i;
    res.z = _uint_as_float(iz);
  }

  return res;
#else
  const float epsilon_f = 1e-4f;
  return P + epsilon_f * Ng;
#endif
}




#endif