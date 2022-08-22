/*
 * Copyright 2011-2017 Blender Foundation
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

#ifndef _UTIL_TYPES_FLOAT4_H_
#define _UTIL_TYPES_FLOAT4_H_

#ifndef _UTIL_TYPES_H_
#  error "Do not include this file directly, include util_types.h instead."
#endif

CCL_NAMESPACE_BEGIN

#ifndef _KERNEL_GPU_
struct int4;

struct ccl_try_align(16) float4
{
#  ifdef _KERNEL_SSE_
  union {
    _m128 m128;
    struct {
      float x, y, z, w;
    };
  };

  _forceinline float4();
  _forceinline explicit float4(const _m128 &a);

  _forceinline operator const _m128 &() const;
  _forceinline operator _m128 &();

  _forceinline float4 &operator=(const float4 &a);

#  else  /* _KERNEL_SSE_ */
  float x, y, z, w;
#  endif /* _KERNEL_SSE_ */

  _forceinline float operator[](int i) const;
  _forceinline float &operator[](int i);
};

ccl_device_inline float4 make_float4(float f);
ccl_device_inline float4 make_float4(float x, float y, float z, float w);
ccl_device_inline float4 make_float4(const int4 &i);
ccl_device_inline void print_float4(const char *label, const float4 &a);
#endif /* _KERNEL_GPU_ */

CCL_NAMESPACE_END

#ifdef _KERNEL_VULKAN_
#define float4 vec4
#define make_float4 vec4
#define print_float4(label,a)
#endif


#endif /* _UTIL_TYPES_FLOAT4_H_ */
