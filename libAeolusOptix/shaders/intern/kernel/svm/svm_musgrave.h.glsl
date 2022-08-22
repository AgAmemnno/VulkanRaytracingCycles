#ifndef _SVM_MASGRAVE_H_
#define _SVM_MASGRAVE_H_

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

#define SVM_NODE_MASG_OUT_COORD(v4) {nio.data[0] = v4.x;nio.data[1] = v4.y;nio.data[2] = v4.z;}
#define SVM_NODE_MASG_OUT_W(f) {nio.data[3] = f;}
#define SVM_NODE_MASG_OUT_SCALE(f) {nio.data[4] = f;}
#define SVM_NODE_MASG_OUT_DETAIL(f) {nio.data[5] = f;}
#define SVM_NODE_MASG_OUT_DIMENTION(f) {nio.data[6] = f;}
#define SVM_NODE_MASG_OUT_LACUNARITY(f) {nio.data[7] = f;}
#define SVM_NODE_MASG_OUT_FOFFSET(f) {nio.data[8] = f;}
#define SVM_NODE_MASG_OUT_GAIN(f) {nio.data[9] = f;}
#define SVM_NODE_MASG_OUT_DIMENTIONS(u) {nio.data[10] = uintBitsToFloat(u);}

#define SVM_NODE_VOR_RET_FAC  nio.data[0]

ccl_device void svm_node_tex_musgrave(
                                      uint offsets1,
                                      uint offsets2,
                                      uint offsets3,
                                      inout int offset)
{
  uint type, dimensions, co_stack_offset, w_stack_offset;
  uint scale_stack_offset, detail_stack_offset, dimension_stack_offset, lacunarity_stack_offset;
  uint offset_stack_offset, gain_stack_offset, fac_stack_offset;

  svm_unpack_node_uchar4(offsets1, (type), (dimensions), (co_stack_offset), (w_stack_offset));
  svm_unpack_node_uchar4(offsets2,
                         (scale_stack_offset),
                         (detail_stack_offset),
                         (dimension_stack_offset),
                         (lacunarity_stack_offset));
  svm_unpack_node_uchar3(offsets3, (offset_stack_offset), (gain_stack_offset), (fac_stack_offset));

  SVM_NODE_MASG_OUT_DIMENTIONS(dimensions);
  nio.type = type;

  uint4 defaults1 = read_node(offset);
  uint4 defaults2 = read_node(offset);

 SVM_NODE_MASG_OUT_COORD(stack_load_float3(co_stack_offset));
 SVM_NODE_MASG_OUT_W(stack_load_float_default(w_stack_offset, defaults1.x));
 SVM_NODE_MASG_OUT_SCALE(stack_load_float_default(scale_stack_offset, defaults1.y));
 SVM_NODE_MASG_OUT_DETAIL(stack_load_float_default(detail_stack_offset, defaults1.z));
 SVM_NODE_MASG_OUT_DIMENTION(stack_load_float_default(dimension_stack_offset, defaults1.w));
 SVM_NODE_MASG_OUT_LACUNARITY(stack_load_float_default(lacunarity_stack_offset, defaults2.x));
 SVM_NODE_MASG_OUT_FOFFSET(stack_load_float_default(offset_stack_offset, defaults2.y));
 SVM_NODE_MASG_OUT_GAIN(stack_load_float_default(gain_stack_offset, defaults2.z));

 EXECUTION_MASG;

 stack_store_float(fac_stack_offset, SVM_NODE_VOR_RET_FAC);

}

#endif

#ifdef NODE_Callee
#include  "kernel/svm/svm_noise.h.glsl"
#include  "kernel/svm/svm_fractal_noise.h.glsl"




/* 1D Musgrave fBm
 *
 * H: fractal increment parameter
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 *
 * from "Texturing and Modelling: A procedural approach"
 */

ccl_device_noinline_cpu float noise_musgrave_fBm_1d(float co,
                                                    float H,
                                                    float lacunarity,
                                                    float octaves)
{
  float p = co;
  float value = 0.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value += snoise_1d(p) * pwr;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * snoise_1d(p) * pwr;
  }

  return value;
}

/* 1D Musgrave Multifractal
 *
 * H: highest fractal dimension
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 */

ccl_device_noinline_cpu float noise_musgrave_multi_fractal_1d(float co,
                                                              float H,
                                                              float lacunarity,
                                                              float octaves)
{
  float p = co;
  float value = 1.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value *= (pwr * snoise_1d(p) + 1.0f);
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value *= (rmd * pwr * snoise_1d(p) + 1.0f); /* correct? */
  }

  return value;
}

/* 1D Musgrave Heterogeneous Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hetero_terrain_1d(
    float co, float H, float lacunarity, float octaves, float offset)
{
  float p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  /* first unscaled octave of function; later octaves are scaled */
  float value = offset + snoise_1d(p);
  p *= lacunarity;

  for (int i = 1; i < float_to_int(octaves); i++) {
    float increment = (snoise_1d(p) + offset) * pwr * value;
    value += increment;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    float increment = (snoise_1d(p) + offset) * pwr * value;
    value += rmd * increment;
  }

  return value;
}

/* 1D Hybrid Additive/Multiplicative Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hybrid_multi_fractal_1d(
    float co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float value = snoise_1d(p) + offset;
  float weight = gain * value;
  p *= lacunarity;

  for (int i = 1; (weight > 0.001f) && (i < float_to_int(octaves)); i++) {
    if (weight > 1.0f) {
      weight = 1.0f;
    }

    float signal = (snoise_1d(p) + offset) * pwr;
    pwr *= pwHL;
    value += weight * signal;
    weight *= gain * signal;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * ((snoise_1d(p) + offset) * pwr);
  }

  return value;
}

/* 1D Ridged Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_ridged_multi_fractal_1d(
    float co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float signal = offset - fabsf(snoise_1d(p));
  signal *= signal;
  float value = signal;
  float weight = 1.0f;

  for (int i = 1; i < float_to_int(octaves); i++) {
    p *= lacunarity;
    weight = saturate(signal * gain);
    signal = offset - fabsf(snoise_1d(p));
    signal *= signal;
    signal *= weight;
    value += signal * pwr;
    pwr *= pwHL;
  }

  return value;
}

/* 2D Musgrave fBm
 *
 * H: fractal increment parameter
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 *
 * from "Texturing and Modelling: A procedural approach"
 */

ccl_device_noinline_cpu float noise_musgrave_fBm_2d(float2 co,
                                                    float H,
                                                    float lacunarity,
                                                    float octaves)
{
  float2 p = co;
  float value = 0.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value += snoise_2d(p) * pwr;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * snoise_2d(p) * pwr;
  }

  return value;
}

/* 2D Musgrave Multifractal
 *
 * H: highest fractal dimension
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 */

ccl_device_noinline_cpu float noise_musgrave_multi_fractal_2d(float2 co,
                                                              float H,
                                                              float lacunarity,
                                                              float octaves)
{
  float2 p = co;
  float value = 1.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value *= (pwr * snoise_2d(p) + 1.0f);
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value *= (rmd * pwr * snoise_2d(p) + 1.0f); /* correct? */
  }

  return value;
}

/* 2D Musgrave Heterogeneous Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hetero_terrain_2d(
    float2 co, float H, float lacunarity, float octaves, float offset)
{
  float2 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  /* first unscaled octave of function; later octaves are scaled */
  float value = offset + snoise_2d(p);
  p *= lacunarity;

  for (int i = 1; i < float_to_int(octaves); i++) {
    float increment = (snoise_2d(p) + offset) * pwr * value;
    value += increment;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    float increment = (snoise_2d(p) + offset) * pwr * value;
    value += rmd * increment;
  }

  return value;
}

/* 2D Hybrid Additive/Multiplicative Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hybrid_multi_fractal_2d(
    float2 co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float2 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float value = snoise_2d(p) + offset;
  float weight = gain * value;
  p *= lacunarity;

  for (int i = 1; (weight > 0.001f) && (i < float_to_int(octaves)); i++) {
    if (weight > 1.0f) {
      weight = 1.0f;
    }

    float signal = (snoise_2d(p) + offset) * pwr;
    pwr *= pwHL;
    value += weight * signal;
    weight *= gain * signal;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * ((snoise_2d(p) + offset) * pwr);
  }

  return value;
}

/* 2D Ridged Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_ridged_multi_fractal_2d(
    float2 co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float2 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float signal = offset - fabsf(snoise_2d(p));
  signal *= signal;
  float value = signal;
  float weight = 1.0f;

  for (int i = 1; i < float_to_int(octaves); i++) {
    p *= lacunarity;
    weight = saturate(signal * gain);
    signal = offset - fabsf(snoise_2d(p));
    signal *= signal;
    signal *= weight;
    value += signal * pwr;
    pwr *= pwHL;
  }

  return value;
}

/* 3D Musgrave fBm
 *
 * H: fractal increment parameter
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 *
 * from "Texturing and Modelling: A procedural approach"
 */

ccl_device_noinline_cpu float noise_musgrave_fBm_3d(float3 co,
                                                    float H,
                                                    float lacunarity,
                                                    float octaves)
{
  float3 p = co;
  float value = 0.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value += snoise_3d(p) * pwr;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * snoise_3d(p) * pwr;
  }

  return value;
}

/* 3D Musgrave Multifractal
 *
 * H: highest fractal dimension
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 */

ccl_device_noinline_cpu float noise_musgrave_multi_fractal_3d(float3 co,
                                                              float H,
                                                              float lacunarity,
                                                              float octaves)
{
  float3 p = co;
  float value = 1.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value *= (pwr * snoise_3d(p) + 1.0f);
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value *= (rmd * pwr * snoise_3d(p) + 1.0f); /* correct? */
  }

  return value;
}

/* 3D Musgrave Heterogeneous Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hetero_terrain_3d(
    float3 co, float H, float lacunarity, float octaves, float offset)
{
  float3 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  /* first unscaled octave of function; later octaves are scaled */
  float value = offset + snoise_3d(p);
  p *= lacunarity;

  for (int i = 1; i < float_to_int(octaves); i++) {
    float increment = (snoise_3d(p) + offset) * pwr * value;
    value += increment;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    float increment = (snoise_3d(p) + offset) * pwr * value;
    value += rmd * increment;
  }

  return value;
}

/* 3D Hybrid Additive/Multiplicative Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hybrid_multi_fractal_3d(
    float3 co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float3 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float value = snoise_3d(p) + offset;
  float weight = gain * value;
  p *= lacunarity;

  for (int i = 1; (weight > 0.001f) && (i < float_to_int(octaves)); i++) {
    if (weight > 1.0f) {
      weight = 1.0f;
    }

    float signal = (snoise_3d(p) + offset) * pwr;
    pwr *= pwHL;
    value += weight * signal;
    weight *= gain * signal;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * ((snoise_3d(p) + offset) * pwr);
  }

  return value;
}

/* 3D Ridged Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_ridged_multi_fractal_3d(
    float3 co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float3 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float signal = offset - fabsf(snoise_3d(p));
  signal *= signal;
  float value = signal;
  float weight = 1.0f;

  for (int i = 1; i < float_to_int(octaves); i++) {
    p *= lacunarity;
    weight = saturate(signal * gain);
    signal = offset - fabsf(snoise_3d(p));
    signal *= signal;
    signal *= weight;
    value += signal * pwr;
    pwr *= pwHL;
  }

  return value;
}

/* 4D Musgrave fBm
 *
 * H: fractal increment parameter
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 *
 * from "Texturing and Modelling: A procedural approach"
 */

ccl_device_noinline_cpu float noise_musgrave_fBm_4d(float4 co,
                                                    float H,
                                                    float lacunarity,
                                                    float octaves)
{
  float4 p = co;
  float value = 0.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value += snoise_4d(p) * pwr;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * snoise_4d(p) * pwr;
  }

  return value;
}

/* 4D Musgrave Multifractal
 *
 * H: highest fractal dimension
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 */

ccl_device_noinline_cpu float noise_musgrave_multi_fractal_4d(float4 co,
                                                              float H,
                                                              float lacunarity,
                                                              float octaves)
{
  float4 p = co;
  float value = 1.0f;
  float pwr = 1.0f;
  float pwHL = powf(lacunarity, -H);

  for (int i = 0; i < float_to_int(octaves); i++) {
    value *= (pwr * snoise_4d(p) + 1.0f);
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value *= (rmd * pwr * snoise_4d(p) + 1.0f); /* correct? */
  }

  return value;
}

/* 4D Musgrave Heterogeneous Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hetero_terrain_4d(
    float4 co, float H, float lacunarity, float octaves, float offset)
{
  float4 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  /* first unscaled octave of function; later octaves are scaled */
  float value = offset + snoise_4d(p);
  p *= lacunarity;

  for (int i = 1; i < float_to_int(octaves); i++) {
    float increment = (snoise_4d(p) + offset) * pwr * value;
    value += increment;
    pwr *= pwHL;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    float increment = (snoise_4d(p) + offset) * pwr * value;
    value += rmd * increment;
  }

  return value;
}

/* 4D Hybrid Additive/Multiplicative Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_hybrid_multi_fractal_4d(
    float4 co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float4 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float value = snoise_4d(p) + offset;
  float weight = gain * value;
  p *= lacunarity;

  for (int i = 1; (weight > 0.001f) && (i < float_to_int(octaves)); i++) {
    if (weight > 1.0f) {
      weight = 1.0f;
    }

    float signal = (snoise_4d(p) + offset) * pwr;
    pwr *= pwHL;
    value += weight * signal;
    weight *= gain * signal;
    p *= lacunarity;
  }

  float rmd = octaves - floorf(octaves);
  if (rmd != 0.0f) {
    value += rmd * ((snoise_4d(p) + offset) * pwr);
  }

  return value;
}

/* 4D Ridged Multifractal Terrain
 *
 * H: fractal dimension of the roughest area
 * lacunarity: gap between successive frequencies
 * octaves: number of frequencies in_rsv the fBm
 * offset: raises the terrain from `sea level'
 */

ccl_device_noinline_cpu float noise_musgrave_ridged_multi_fractal_4d(
    float4 co, float H, float lacunarity, float octaves, float offset, float gain)
{
  float4 p = co;
  float pwHL = powf(lacunarity, -H);
  float pwr = pwHL;

  float signal = offset - fabsf(snoise_4d(p));
  signal *= signal;
  float value = signal;
  float weight = 1.0f;

  for (int i = 1; i < float_to_int(octaves); i++) {
    p *= lacunarity;
    weight = saturate(signal * gain);
    signal = offset - fabsf(snoise_4d(p));
    signal *= signal;
    signal *= weight;
    value += signal * pwr;
    pwr *= pwHL;
  }

  return value;
}

ccl_device void svm_node_tex_musgrave()
{


  nio.dimension = fmaxf(nio.dimension, 1e-5f);
  nio.detail = clamp(nio.detail, 0.0f, 16.0f);
  nio.lacunarity = fmaxf(nio.lacunarity, 1e-5f);

  float fac;

  switch (nio.dimensions) {
    case 1: {
      float p = nio.w * nio.scale;
      switch (NodeMusgraveType(nio.type)) {

        case NODE_MUSGRAVE_MULTIFRACTAL:
          fac = noise_musgrave_multi_fractal_1d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_FBM:
          fac = noise_musgrave_fBm_1d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_HYBRID_MULTIFRACTAL:
          fac = noise_musgrave_hybrid_multi_fractal_1d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_RIDGED_MULTIFRACTAL:
          fac = noise_musgrave_ridged_multi_fractal_1d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_HETERO_TERRAIN:
          fac = noise_musgrave_hetero_terrain_1d(p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset);
          break;
        default:
          fac = 0.0f;
      }
      break;
    }
    case 2: {
      float2 p = make_float2(nio.co.x, nio.co.y) * nio.scale;
      switch (NodeMusgraveType(nio.type)) {

        case NODE_MUSGRAVE_MULTIFRACTAL:
          fac = noise_musgrave_multi_fractal_2d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_FBM:
          fac = noise_musgrave_fBm_2d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_HYBRID_MULTIFRACTAL:
          fac = noise_musgrave_hybrid_multi_fractal_2d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_RIDGED_MULTIFRACTAL:
          fac = noise_musgrave_ridged_multi_fractal_2d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_HETERO_TERRAIN:
          fac = noise_musgrave_hetero_terrain_2d(p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset);
          break;
        default:
          fac = 0.0f;
      }
      break;
    }
    case 3: {
      float3 p = vec4(nio.co,0.) * nio.scale;
      switch (NodeMusgraveType(nio.type)) {

        case NODE_MUSGRAVE_MULTIFRACTAL:
          fac = noise_musgrave_multi_fractal_3d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_FBM:
          fac = noise_musgrave_fBm_3d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_HYBRID_MULTIFRACTAL:
          fac = noise_musgrave_hybrid_multi_fractal_3d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_RIDGED_MULTIFRACTAL:
          fac = noise_musgrave_ridged_multi_fractal_3d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_HETERO_TERRAIN:
          fac = noise_musgrave_hetero_terrain_3d(p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset);
          break;
        default:
          fac = 0.0f;
      }
      break;
    }
    case 4: {
      float4 p = make_float4(nio.co.x, nio.co.y, nio.co.z, nio.w) * nio.scale;
      switch (NodeMusgraveType(nio.type)) {

        case NODE_MUSGRAVE_MULTIFRACTAL:
          fac = noise_musgrave_multi_fractal_4d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_FBM:
          fac = noise_musgrave_fBm_4d(p, nio.dimension, nio.lacunarity, nio.detail);
          break;
        case NODE_MUSGRAVE_HYBRID_MULTIFRACTAL:
          fac = noise_musgrave_hybrid_multi_fractal_4d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_RIDGED_MULTIFRACTAL:
          fac = noise_musgrave_ridged_multi_fractal_4d(
              p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset, nio.gain);
          break;
        case NODE_MUSGRAVE_HETERO_TERRAIN:
          fac = noise_musgrave_hetero_terrain_4d(p, nio.dimension, nio.lacunarity, nio.detail, nio.foffset);
          break;
        default:
          fac = 0.0f;
      }
      break;
    }
    default:
      fac = 0.0f;
  }

 SVM_NODE_MASG_RET_FAC(fac) 

}




#endif

CCL_NAMESPACE_END



#endif