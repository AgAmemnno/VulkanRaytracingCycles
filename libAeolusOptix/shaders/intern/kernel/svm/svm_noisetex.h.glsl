#ifndef _SVM_NOISETEX_H_
#define _SVM_NOISETEX_H_
/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in_rsv compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in_rsv writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "kernel/svm/svm_callable.glsl"


CCL_NAMESPACE_BEGIN



#ifdef NODE_Caller


#define SVM_NODE_TEX_OUT_OFFSET(ofs) {nio.offset = ofs;}
#define SVM_NODE_TEX_OUT_VECTOR(v4) {nio.data[0] = v4.x;nio.data[1] = v4.y;nio.data[2] = v4.z;}
#define SVM_NODE_TEX_OUT_W(f) {nio.data[3] = f;}
#define SVM_NODE_TEX_OUT_SCALE(f) {nio.data[4] = f;}
#define SVM_NODE_TEX_OUT_DETAIL(f) {nio.data[5] = f;}
#define SVM_NODE_TEX_OUT_ROUGHNESS(f) {nio.data[6] = f;}
#define SVM_NODE_TEX_OUT_DISTORTION(f) {nio.data[7] = f;}
#define SVM_NODE_TEX_OUT_DIMENTION(dim) {nio.data[8] = float(dim);}

#define SVM_NODE_TEX_RET_COLOR vec4(nio.data[0],nio.data[1],nio.data[2],0)
#define SVM_NODE_TEX_RET_VALUE nio.data[3]

ccl_device void svm_node_tex_noise(uint dimensions,
                                   uint offsets1,
                                   uint offsets2,
                                   inout int offset)
{

  nio.type = CALLEE_SVM_TEX_NOISE;

  uint vector_stack_offset, w_stack_offset, scale_stack_offset;
  uint detail_stack_offset, roughness_stack_offset, distortion_stack_offset;
  uint value_stack_offset, color_stack_offset;
  svm_unpack_node_uchar4(
      offsets1, (vector_stack_offset), (w_stack_offset), (scale_stack_offset), (detail_stack_offset));
  svm_unpack_node_uchar4(offsets2,
                         (roughness_stack_offset),
                         (distortion_stack_offset),
                         (value_stack_offset),
                         (color_stack_offset));
  uint4 defaults1 = read_node(offset);
  uint4 defaults2 = read_node(offset);


SVM_NODE_TEX_OUT_DIMENTION(dimensions)
SVM_NODE_TEX_OUT_OFFSET(int(color_stack_offset))
SVM_NODE_TEX_OUT_VECTOR(stack_load_float3(vector_stack_offset)) 
SVM_NODE_TEX_OUT_W(stack_load_float_default(w_stack_offset, defaults1.x))
SVM_NODE_TEX_OUT_SCALE(stack_load_float_default(scale_stack_offset, defaults1.y))
SVM_NODE_TEX_OUT_DETAIL(stack_load_float_default(detail_stack_offset, defaults1.z))
SVM_NODE_TEX_OUT_ROUGHNESS(stack_load_float_default(roughness_stack_offset, defaults1.w))
SVM_NODE_TEX_OUT_DISTORTION(stack_load_float_default(distortion_stack_offset, defaults2.x))


EXECUTION_NOISE;
  
if (stack_valid(value_stack_offset)) {
    stack_store_float(value_stack_offset, SVM_NODE_TEX_RET_VALUE);
}

if (stack_valid(color_stack_offset)) {
    stack_store_float3(color_stack_offset, SVM_NODE_TEX_RET_COLOR);
}


}



#endif



#ifdef NODE_Callee

#include  "kernel/svm/svm_noise.h.glsl"
#include  "kernel/svm/svm_fractal_noise.h.glsl"

#define SVM_NODE_TEX_IN_OFFSET nio.offset

#define SVM_NODE_TEX_IN_VECTOR vec4(nio.data[0],nio.data[1],nio.data[2],0.)
#define SVM_NODE_TEX_IN_W nio.data[3]
#define SVM_NODE_TEX_IN_SCALE nio.data[4]
#define SVM_NODE_TEX_IN_DETAIL nio.data[5]
#define SVM_NODE_TEX_IN_ROUGHNESS nio.data[6]
#define SVM_NODE_TEX_IN_DISTORTION nio.data[7]
#define SVM_NODE_TEX_IN_DIMENTION uint(nio.data[8])


#define SVM_NODE_TEX_RET_COLOR(v4) { nio.data[0] = v4.x;nio.data[1] = v4.y;nio.data[2] = v4.z;}
#define SVM_NODE_TEX_RET_VALUE(f)  { nio.data[3] = f;}


/* The following offset functions generate random offsets to be added to texture
 * coordinates to act as a seed since the noise functions don't have seed values.
 * A seed value is needed for generating distortion textures and color outputs.
 * The offset's components are in_rsv the range [100, 200], not too high to cause
 * bad precision and not to small to be noticeable. We use float seed because
 * OSL only support float hashes.
 */

ccl_device_inline float random_float_offset(float seed)
{
  return 100.0f + hash_float_to_float(seed) * 100.0f;
}

ccl_device_inline float2 random_float2_offset(float seed)
{
  return make_float2(100.0f + hash_float2_to_float(make_float2(seed, 0.0f)) * 100.0f,
                     100.0f + hash_float2_to_float(make_float2(seed, 1.0f)) * 100.0f);
}

ccl_device_inline float3 random_float3_offset(float seed)
{
  return make_float3(100.0f + hash_float2_to_float(make_float2(seed, 0.0f)) * 100.0f,
                     100.0f + hash_float2_to_float(make_float2(seed, 1.0f)) * 100.0f,
                     100.0f + hash_float2_to_float(make_float2(seed, 2.0f)) * 100.0f);
}

ccl_device_inline float4 random_float4_offset(float seed)
{
  return make_float4(100.0f + hash_float2_to_float(make_float2(seed, 0.0f)) * 100.0f,
                     100.0f + hash_float2_to_float(make_float2(seed, 1.0f)) * 100.0f,
                     100.0f + hash_float2_to_float(make_float2(seed, 2.0f)) * 100.0f,
                     100.0f + hash_float2_to_float(make_float2(seed, 3.0f)) * 100.0f);
}

ccl_device void noise_texture_1d(float co,
                                 float detail,
                                 float roughness,
                                 float distortion,
                                 bool color_is_needed,
                                 inout float value,
                                 inout float3 color)
{
  float p = co;
  if (distortion != 0.0f) {
    p += snoise_1d(p + random_float_offset(0.0f)) * distortion;
  }

  value = fractal_noise_1d(p, detail, roughness);
  if (color_is_needed) {
    color = make_float3(value,
                         fractal_noise_1d(p + random_float_offset(1.0f), detail, roughness),
                         fractal_noise_1d(p + random_float_offset(2.0f), detail, roughness));
  }
}

ccl_device void noise_texture_2d(float2 co,
                                 float detail,
                                 float roughness,
                                 float distortion,
                                 bool color_is_needed,
                                 inout float value,
                                 inout float3 color)
{
  float2 p = co;
  if (distortion != 0.0f) {
    p += make_float2(snoise_2d(p + random_float2_offset(0.0f)) * distortion,
                     snoise_2d(p + random_float2_offset(1.0f)) * distortion);
  }

  value = fractal_noise_2d(p, detail, roughness);
  if (color_is_needed) {
    color = make_float3(value,
                         fractal_noise_2d(p + random_float2_offset(2.0f), detail, roughness),
                         fractal_noise_2d(p + random_float2_offset(3.0f), detail, roughness));
  }
}

ccl_device void noise_texture_3d(float3 co,
                                 float detail,
                                 float roughness,
                                 float distortion,
                                 bool color_is_needed,
                                 inout float value,
                                 inout float3 color)
{
  float3 p = co;
  if (distortion != 0.0f) {
    p += make_float3(snoise_3d(p + random_float3_offset(0.0f)) * distortion,
                     snoise_3d(p + random_float3_offset(1.0f)) * distortion,
                     snoise_3d(p + random_float3_offset(2.0f)) * distortion);
  }

  value = fractal_noise_3d(p, detail, roughness);
  if (color_is_needed) {
    color = make_float3(value,
                         fractal_noise_3d(p + random_float3_offset(3.0f), detail, roughness),
                         fractal_noise_3d(p + random_float3_offset(4.0f), detail, roughness));
  }
}

ccl_device void noise_texture_4d(float4 co,
                                 float detail,
                                 float roughness,
                                 float distortion,
                                 bool color_is_needed,
                                 inout float value,
                                 inout float3 color)
{
  float4 p = co;
  if (distortion != 0.0f) {
    p += make_float4(snoise_4d(p + random_float4_offset(0.0f)) * distortion,
                     snoise_4d(p + random_float4_offset(1.0f)) * distortion,
                     snoise_4d(p + random_float4_offset(2.0f)) * distortion,
                     snoise_4d(p + random_float4_offset(3.0f)) * distortion);
  }

  value = fractal_noise_4d(p, detail, roughness);
  if (color_is_needed) {
    color = make_float3(value,
                         fractal_noise_4d(p + random_float4_offset(4.0f), detail, roughness),
                         fractal_noise_4d(p + random_float4_offset(5.0f), detail, roughness));
  }
}



ccl_device void svm_node_tex_noise()
{
  vec4 vector = SVM_NODE_TEX_IN_VECTOR;
   vector    *= SVM_NODE_TEX_IN_SCALE;
  SVM_NODE_TEX_IN_W *= SVM_NODE_TEX_IN_SCALE;
  float value;
  float3 color;
  switch (SVM_NODE_TEX_IN_DIMENTION) {
    case 1:
      noise_texture_1d(SVM_NODE_TEX_IN_W,SVM_NODE_TEX_IN_DETAIL, SVM_NODE_TEX_IN_ROUGHNESS, SVM_NODE_TEX_IN_DISTORTION, stack_valid(SVM_NODE_TEX_IN_OFFSET), (value), (color));
      break;
    case 2:
      noise_texture_2d(vector.xy,SVM_NODE_TEX_IN_DETAIL, SVM_NODE_TEX_IN_ROUGHNESS,SVM_NODE_TEX_IN_DISTORTION,stack_valid(SVM_NODE_TEX_IN_OFFSET),(value),(color));
      break;
    case 3:
      noise_texture_3d(vector, SVM_NODE_TEX_IN_DETAIL, SVM_NODE_TEX_IN_ROUGHNESS, SVM_NODE_TEX_IN_DISTORTION, stack_valid(SVM_NODE_TEX_IN_OFFSET), (value), (color));
      break;
    case 4:
      noise_texture_4d(make_float4(vector.xyz, SVM_NODE_TEX_IN_W), SVM_NODE_TEX_IN_DETAIL, SVM_NODE_TEX_IN_ROUGHNESS,SVM_NODE_TEX_IN_DISTORTION, stack_valid(SVM_NODE_TEX_IN_OFFSET),(value), (color));
      break;
/*default*/
  }

  SVM_NODE_TEX_RET_COLOR(color)
  SVM_NODE_TEX_RET_VALUE(value)

}

#endif

CCL_NAMESPACE_END

#endif