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

#ifndef _UTIL_TYPES_INT3_H_
#define _UTIL_TYPES_INT3_H_

#ifndef _UTIL_TYPES_H_
#  error "Do not include this file directly, include util_types.h instead."
#endif

CCL_NAMESPACE_BEGIN

#ifndef _KERNEL_GPU_
struct ccl_try_align(16) int3
{
#  ifdef _KERNEL_SSE_
  union {
    _m128i m128;
    struct {
      int x, y, z, w;
    };
  };

  _forceinline int3();
  _forceinline int3(const int3 &a);
  _forceinline explicit int3(const _m128i &a);

  _forceinline operator const _m128i &() const;
  _forceinline operator _m128i &();

  _forceinline int3 &operator=(const int3 &a);
#  else  /* _KERNEL_SSE_ */
  int x, y, z, w;
#  endif /* _KERNEL_SSE_ */

  _forceinline int operator[](int i) const;
  _forceinline int &operator[](int i);
};

ccl_device_inline int3 make_int3(int i);
ccl_device_inline int3 make_int3(int x, int y, int z);
ccl_device_inline void print_int3(const char *label, const int3 &a);
#endif /* _KERNEL_GPU_ */

CCL_NAMESPACE_END

#ifdef _KERNEL_VULKAN_
#define int3 ivec3
#define make_int3 ivec3
#define print_int3(label,a)
#endif


#endif /* _UTIL_TYPES_INT3_H_ */
