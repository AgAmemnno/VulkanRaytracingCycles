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

#ifndef _UTIL_TYPES_FLOAT3_H_
#define _UTIL_TYPES_FLOAT3_H_

#ifndef _UTIL_TYPES_H_
#  error "Do not include this file directly, include util_types.h instead."
#endif

CCL_NAMESPACE_BEGIN

#ifndef _KERNEL_GPU_
struct ccl_try_align(16) float3
{
#  ifdef _KERNEL_SSE_
  union {
    _m128 m128;
    struct {
      float x, y, z, w;
    };
  };

  _forceinline float3();
  _forceinline float3(const float3 &a);
  _forceinline explicit float3(const _m128 &a);

  _forceinline operator const _m128 &() const;
  _forceinline operator _m128 &();

  _forceinline float3 &operator=(const float3 &a);
#  else  /* _KERNEL_SSE_ */
  float x, y, z, w;
#  endif /* _KERNEL_SSE_ */

  _forceinline float operator[](int i) const;
  _forceinline float &operator[](int i);
};

ccl_device_inline float3 make_float3(float f);
ccl_device_inline float3 make_float3(float x, float y, float z);
ccl_device_inline void print_float3(const char *label, const float3 &a);
#endif /* _KERNEL_GPU_ */

CCL_NAMESPACE_END

#ifdef _KERNEL_VULKAN_
#ifdef FLOAT3_AS_VEC3

#define float3 vec3
#define sizeof_float3 16
#define aignof_float3 16
#define make_float3(x,y,z) vec3(x,y,z)
#define make_float3_v3(v)  vec3((v).xyz)
#define make_float3_f(v)   vec3(v)
#define as_float3(v) v.xyz

#define dot3(a,b) dot((a).xyz,(b).xyz)
#define cross3(a,b) cross((a).xyz,(b).xyz)
#define normalize3(a) normalize((a).xyz)
#define _normalize(a) a/len(a)


#else


#define float3 vec4
#define sizeof_float3 16
#define aignof_float3 16
#define make_float3(x,y,z) vec4(x,y,z,0.f)
#define make_float3_v3(v)  vec4(v,0.f)
#define make_float3_f(v)   vec4(v)
#define as_float3(v) make_float3_v3(v.xyz)

#define dot3(a,b) dot((a).xyz,(b).xyz)
#define cross3(a,b) vec4(cross((a).xyz,(b).xyz),0.)
#define normalize3(a) vec4(normalize((a).xyz),0.f)
#define _normalize(a) a/len(a)

float3 cross(in float3 e1,in float3 e0){
        return vec4(cross(e1.xyz,e0.xyz),0.f);
} 

#endif

#define print_float3(label,a)
#endif


#endif /* _UTIL_TYPES_FLOAT3_H_ */
