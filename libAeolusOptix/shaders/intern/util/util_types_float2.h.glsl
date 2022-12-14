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

#ifndef _UTIL_TYPES_FLOAT2_H_
#define _UTIL_TYPES_FLOAT2_H_

#ifndef _UTIL_TYPES_H_
#  error "Do not include this file directly, include util_types.h instead."
#endif

CCL_NAMESPACE_BEGIN

#ifndef _KERNEL_GPU_
struct float2 {
  float x, y;

  _forceinline float operator[](int i) const;
  _forceinline float &operator[](int i);
};

ccl_device_inline float2 make_float2(float x, float y);
ccl_device_inline void print_float2(const char *label, const float2 &a);
#endif /* _KERNEL_GPU_ */

CCL_NAMESPACE_END

#ifdef _KERNEL_VULKAN_
#define float2 vec2
#define make_float2 vec2
#define print_float2(label,a)

#endif


#endif /* _UTIL_TYPES_FLOAT2_H_ */
