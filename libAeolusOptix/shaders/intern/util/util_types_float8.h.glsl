/*
 * Original code Copyright 2017, Intel Corporation
 * Modifications Copyright 2018, Blender Foundation.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * * Neither the name of Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _UTIL_TYPES_FLOAT8_H_
#define _UTIL_TYPES_FLOAT8_H_

#ifndef _UTIL_TYPES_H_
#  error "Do not include this file directly, include util_types.h instead."
#endif

CCL_NAMESPACE_BEGIN

#ifndef _KERNEL_GPU_

struct ccl_try_align(32) float8
{
#  ifdef _KERNEL_AVX2_
  union {
    _m256 m256;
    struct {
      float a, b, c, d, e, f, g, h;
    };
  };

  _forceinline float8();
  _forceinline float8(const float8 &a);
  _forceinline explicit float8(const _m256 &a);

  _forceinline operator const _m256 &() const;
  _forceinline operator _m256 &();

  _forceinline float8 &operator=(const float8 &a);

#  else  /* _KERNEL_AVX2_ */
  float a, b, c, d, e, f, g, h;
#  endif /* _KERNEL_AVX2_ */

  _forceinline float operator[](int i) const;
  _forceinline float &operator[](int i);
};

ccl_device_inline float8 make_float8(float f);
ccl_device_inline float8
make_float8(float a, float b, float c, float d, float e, float f, float g, float h);
#endif /* _KERNEL_GPU_ */

CCL_NAMESPACE_END

#ifdef _KERNEL_VULKAN_
#define float8 ERROR_FLOAT8_NIL
#define make_float8(x,y,z)  ERROR_FLOAT8_NIL
#endif

#endif /* _UTIL_TYPES_FLOAT8_H_ */
