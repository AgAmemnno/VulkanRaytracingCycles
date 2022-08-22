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

#ifndef _UTIL_TYPES_UINT4_H_
#define _UTIL_TYPES_UINT4_H_

#ifndef _UTIL_TYPES_H_
#  error "Do not include this file directly, include util_types.h instead."
#endif

CCL_NAMESPACE_BEGIN

#define sizeof_uint4 16
#ifndef _KERNEL_GPU_
struct uint4 {
  uint x, y, z, w;

  _forceinline uint operator[](uint i) const;
  _forceinline uint &operator[](uint i);
};

ccl_device_inline uint4 make_uint4(uint x, uint y, uint z, uint w);
#endif /* _KERNEL_GPU_ */

CCL_NAMESPACE_END

#ifdef _KERNEL_VULKAN_
#define uint4 uvec4
#define make_uint4 uvec4
#define sizeof_uint4 16
#endif

#endif /* _UTIL_TYPES_UINT4_H_ */
