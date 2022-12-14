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

#ifndef _UTIL_TYPES_INT2_H_
#define _UTIL_TYPES_INT2_H_

#ifndef _UTIL_TYPES_H_
#  error "Do not include this file directly, include util_types.h instead."
#endif

CCL_NAMESPACE_BEGIN

#ifndef _KERNEL_GPU_
struct int2 {
  int x, y;

  _forceinline int operator[](int i) const;
  _forceinline int &operator[](int i);
};

ccl_device_inline int2 make_int2(int x, int y);
#endif /* _KERNEL_GPU_ */

CCL_NAMESPACE_END

#ifdef _KERNEL_VULKAN_
#define int2 ivec2
#define make_int2 ivec2
#endif


#endif /* _UTIL_TYPES_INT2_H_ */
