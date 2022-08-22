#ifndef _KERNEL_WRITE_PASSES_H_
#define _KERNEL_WRITE_PASSES_H_
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

#if defined(_SPLIT_KERNEL_) || defined(_KERNEL_CUDA_)
#  define _ATOMIC_PASS_WRITE_
#endif

CCL_NAMESPACE_BEGIN

#ifdef SET_WRITE_PASSES

ccl_device_inline void kernel_write_pass_float4(int ofs, float4 value)
{
#ifdef _ATOMIC_PASS_WRITE_
  kernel_write_pass_float4_launchID_atomic(value);
#else
  kernel_write_pass_float4_launchID(value);
#endif
}
#endif



#ifdef TODO_PASSES__

ccl_device_inline void kernel_write_pass_float(int ofs, float value)
{
#ifdef _ATOMIC_PASS_WRITE_
  atomic_add_and_fetch_float(OutBuffer[ofs], value);
#else
  OutBuffer[ofs] += value;
#endif
}


ccl_device_inline void kernel_write_pass_float3(int ofs, float3 value)
{
#ifdef _ATOMIC_PASS_WRITE_
  atomic_add_and_fetch_float(OutBuffer[ofs], value.x);
  atomic_add_and_fetch_float(OutBuffer[ofs+1], value.y);
  atomic_add_and_fetch_float(OutBuffer[ofs+2], value.z);
#else
  OutBuffer[ofs] += value.x;
  OutBuffer[ofs+1] += value.y;
  OutBuffer[ofs+2] += value.z;
#endif
}

#ifdef _DENOISING_FEATURES_
ccl_device_inline void kernel_write_pass_float_variance(int ofs, float value)
{
  kernel_write_pass_float(ofs, value);

  /* The online one-pass variance update that's used for the megakernel can't easily be implemented
   * with atomics, so for the split kernel the E[x^2] - 1/N * (E[x])^2 fallback is used. */
  kernel_write_pass_float(ofs + 1, value * value);
}

#    define kernel_write_pass_float3_unaligned kernel_write_pass_float3
/*
#  ifdef _ATOMIC_PASS_WRITE_
#    define kernel_write_pass_float3_unaligned kernel_write_pass_float3
#  else
ccl_device_inline void kernel_write_pass_float3_unaligned(ccl_global inout float buffer, float3 value)
{
  buffer[0] += value.x;
  buffer[1] += value.y;
  buffer[2] += value.z;
}
#  endif
*/

ccl_device_inline void kernel_write_pass_float3_variance(int ofs, float3 value)
{
  kernel_write_pass_float3_unaligned(ofs, value);
  kernel_write_pass_float3_unaligned(ofs + 3, value * value);
}

#endif /* _DENOISING_FEATURES_ */
#endif

CCL_NAMESPACE_END
#endif