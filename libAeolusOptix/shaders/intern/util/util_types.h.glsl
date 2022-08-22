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

#ifndef _UTIL_TYPES_H_
#define _UTIL_TYPES_H_

#ifdef _KERNEL_VULKAN_
#define DEADBEAF 3735928559u
#define FFFFFFFF 4294967295u


#endif

#if (!defined(_KERNEL_OPENCL_) & !defined(_KERNEL_VULKAN_))
#  include <stdlib.h>
#endif

/* Standard Integer Types */

#if !defined(_KERNEL_GPU_) && !defined(_WIN32)
#  include <stdint.h>
#endif

#ifndef _KERNEL_VULKAN_
#include "util/util_defines.h"
#else
#include "util/util_defines.h.glsl"
#endif

#ifndef _KERNEL_GPU_
#  include "util/util_optimization.h"
#  include "util/util_simd.h"
#endif

CCL_NAMESPACE_BEGIN

/* Types
 *
 * Define simpler
 uint type names, and integer with defined number of bits.
 * Also vector types, named to be compatible with OpenCL builtin types, while
 * working for CUDA and C++ too. */

/* Shorter Unsigned Names */

#ifndef _KERNEL_OPENCL_
#ifdef _KERNEL_VULKAN_
/* pyhton convert
 uint */
#define uchar uint8_t
#define ushort uint16_t
#define ulong uint64_t
#ifdef _KERNEL_64_BIT_
#define ssize_t int64_t 
#define size_t  uint64_t
#else
#define ssize_t int
#define size_t  uint
#endif
#else

typedef
 uint8_t uchar;
typedef
 uint uint;
typedef
 uint16_t ushort;

#endif
#endif

/* Fixed Bits Types */
#ifdef _KERNEL_OPENCL_
typedef ulong uint64_t;
#endif


#ifndef _KERNEL_GPU_
#  ifdef _WIN32
typedef
 int8_t int8_t;
typedef
 uint8_t uint8_t;

typedef
 int16_t int16_t;
typedef
 uint16_t uint16_t;

typedef
 int int32_t;
typedef
 uint uint32_t;

typedef
 int64_t int64_t;
typedef
 uint int64_t uint64_t;
#    ifdef _KERNEL_64_BIT_
typedef int64_t ssize_t;
#    else
typedef int32_t ssize_t;
#    endif
#  endif /* _WIN32 */

/* Generic Memory Pointer */

typedef uint64_t device_ptr;
#endif /* _KERNEL_GPU_ */

ccl_device_inline size_t align_up(size_t offset, size_t alignment)
{
  return (offset + alignment - 1) & ~(alignment - 1);
}

ccl_device_inline size_t divide_up(size_t x, size_t y)
{
  return (x + y - 1) / y;
}

ccl_device_inline size_t round_up(size_t x, size_t multiple)
{
  return ((x + multiple - 1) / multiple) * multiple;
}

ccl_device_inline size_t round_down(size_t x, size_t multiple)
{
  return (x / multiple) * multiple;
}

ccl_device_inline bool is_power_of_two(size_t x)
{
  return (x & (x - 1)) == 0;
}

CCL_NAMESPACE_END
#ifdef _KERNEL_VULKAN_
#extension GL_EXT_shader_8bit_storage : enable
#endif
/* Vectorized types declaration. */
#ifdef _KERNEL_VULKAN_
#include "util/util_types_uchar2.h.glsl"
#include "util/util_types_uchar3.h.glsl"
#include "util/util_types_uchar4.h.glsl"

#include "util/util_types_int2.h.glsl"
#include "util/util_types_int3.h.glsl"
#include "util/util_types_int4.h.glsl"

#include "util/util_types_uint2.h.glsl"
#include "util/util_types_uint3.h.glsl"
#include "util/util_types_uint4.h.glsl"

#include "util/util_types_ushort4.h.glsl"

#include "util/util_types_float2.h.glsl"
#include "util/util_types_float3.h.glsl"
#include "util/util_types_float4.h.glsl"
#include "util/util_types_float8.h.glsl"

#include "util/util_types_vector3.h.glsl"
#else
#include "util/util_types_uchar2.h"
#include "util/util_types_uchar3.h"
#include "util/util_types_uchar4.h"

#include "util/util_types_int2.h"
#include "util/util_types_int3.h"
#include "util/util_types_int4.h"

#include "util/util_types_uint2.h"
#include "util/util_types_uint3.h"
#include "util/util_types_uint4.h"

#include "util/util_types_ushort4.h"

#include "util/util_types_float2.h"
#include "util/util_types_float3.h"
#include "util/util_types_float4.h"
#include "util/util_types_float8.h"

#include "util/util_types_vector3.h"
#endif


/* Vectorized types implementation. */
#ifndef _KERNEL_VULKAN_

#include "util/util_types_uchar2_impl.h"
#include "util/util_types_uchar3_impl.h"
#include "util/util_types_uchar4_impl.h"

#include "util/util_types_int2_impl.h"
#include "util/util_types_int3_impl.h"
#include "util/util_types_int4_impl.h"

#include "util/util_types_uint2_impl.h"
#include "util/util_types_uint3_impl.h"
#include "util/util_types_uint4_impl.h"

#include "util/util_types_float2_impl.h"
#include "util/util_types_float3_impl.h"
#include "util/util_types_float4_impl.h"
#include "util/util_types_float8_impl.h"

#include "util/util_types_vector3_impl.h"

#endif

/* SSE types. */
#ifndef _KERNEL_GPU_
#  include "util/util_sseb.h"
#  include "util/util_ssef.h"
#  include "util/util_ssei.h"
#  if defined(_KERNEL_AVX_) || defined(_KERNEL_AVX2_)
#    include "util/util_avxb.h"
#    include "util/util_avxf.h"
#    include "util/util_avxi.h"
#  endif
#endif

#endif /* _UTIL_TYPES_H_ */
