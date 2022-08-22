#ifndef _SVM_WAVE_H_
#define _SVM_WAVE_H_
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


#include  "kernel/svm/svm_callable.glsl"
#include  "kernel/svm/svm_fractal_noise.h.glsl"

CCL_NAMESPACE_BEGIN


/* Wave */
#ifdef NODE_Caller

#define SVM_NODE_WAVE_OUT_OFFSET(ofs) {nio.offset = ofs;}
#define SVM_NODE_WAVE_OUT_CO(v4) {nio.data[0] = v4.x;nio.data[1] = v4.y;nio.data[2] = v4.z;}
#define SVM_NODE_WAVE_OUT_SCALE(f) {nio.data[3] = f;}
#define SVM_NODE_WAVE_OUT_DISTORTION(f) {nio.data[4] = f;}
#define SVM_NODE_WAVE_OUT_DETAIL(f) {nio.data[5] = f;}
#define SVM_NODE_WAVE_OUT_DSCALE(dscale) {nio.data[6] = dscale;}
#define SVM_NODE_WAVE_OUT_DROUGHNESS(f) {nio.data[7] = f;}
#define SVM_NODE_WAVE_OUT_DPHASE(f) {nio.data[8] = f;}

#define SVM_NODE_WAVE_OUT_PACK4_TYPE(f) {nio.data[9] = uintBitsToFloat(f);}
#define SVM_NODE_WAVE_RET_VALUE  nio.data[0]

ccl_device void svm_node_tex_wave(uint4 node, inout int offset)
{

  nio.type = CALLEE_SVM_TEX_WAVE;

  uint4 node2 = read_node(offset);
  uint4 node3 = read_node(offset);

  /* Inputs, Outputs */
  uint co_offset, scale_offset, distortion_offset, detail_offset, dscale_offset, droughness_offset,phase_offset;
  uint color_offset, fac_offset;


  SVM_NODE_WAVE_OUT_PACK4_TYPE(node.y)

  svm_unpack_node_uchar3(node.z, (co_offset), (scale_offset), (distortion_offset));
  svm_unpack_node_uchar4(node.w, (detail_offset), (dscale_offset), (droughness_offset), (phase_offset));
  svm_unpack_node_uchar2(node2.x, (color_offset), (fac_offset));



  SVM_NODE_WAVE_OUT_CO(stack_load_float3(co_offset));
  SVM_NODE_WAVE_OUT_SCALE(stack_load_float_default(scale_offset, node2.y));
  SVM_NODE_WAVE_OUT_DISTORTION(stack_load_float_default(distortion_offset, node2.z));
  SVM_NODE_WAVE_OUT_DETAIL(stack_load_float_default(detail_offset, node2.w));
  SVM_NODE_WAVE_OUT_DSCALE(stack_load_float_default(dscale_offset, node3.x));
  SVM_NODE_WAVE_OUT_DROUGHNESS(stack_load_float_default(droughness_offset, node3.y));
  SVM_NODE_WAVE_OUT_DPHASE(stack_load_float_default(phase_offset, node3.z));
  
  EXECUTION_NOISE;

  if (stack_valid(fac_offset))
    stack_store_float(fac_offset, SVM_NODE_WAVE_RET_VALUE);
  if (stack_valid(color_offset))
    stack_store_float3(color_offset, vec4(SVM_NODE_WAVE_RET_VALUE));
}

#endif



#ifdef NODE_Callee


#define SVM_NODE_WAVE_IN_CO          vec4(nio.data[0],nio.data[1],nio.data[2],0.)
#define SVM_NODE_WAVE_IN_SCALE       nio.data[3]
#define SVM_NODE_WAVE_IN_DISTORTION  nio.data[4]
#define SVM_NODE_WAVE_IN_DETAIL      nio.data[5]
#define SVM_NODE_WAVE_IN_DSCALE      nio.data[6]
#define SVM_NODE_WAVE_IN_DROUGHNESS  nio.data[7]
#define SVM_NODE_WAVE_IN_DPHASE      nio.data[8]

#define SVM_NODE_WAVE_IN_PACK4_TYPE  floatBitsToUint(nio.data[9])

#define SVM_NODE_WAVE_RET_VALUE(f)  { nio.data[0] = f;}


ccl_device_noinline_cpu float svm_wave(NodeWaveType type,
                                       NodeWaveBandsDirection bands_dir,
                                       NodeWaveRingsDirection rings_dir,
                                       NodeWaveProfile profile,
                                       float3 p,
                                       float distortion,
                                       float detail,
                                       float dscale,
                                       float droughness,
                                       float phase)
{
  /* Prevent precision issues on unit coordinates. */
  p = (p + 0.000001f) * 0.999999f;

  float n;

  if (type == NODE_WAVE_BANDS) {
    if (bands_dir == NODE_WAVE_BANDS_DIRECTION_X) {
      n = p.x * 20.0f;
    }
    else if (bands_dir == NODE_WAVE_BANDS_DIRECTION_Y) {
      n = p.y * 20.0f;
    }
    else if (bands_dir == NODE_WAVE_BANDS_DIRECTION_Z) {
      n = p.z * 20.0f;
    }
    else { /* NODE_WAVE_BANDS_DIRECTION_DIAGONAL */
      n = (p.x + p.y + p.z) * 10.0f;
    }
  }
  else { /* NODE_WAVE_RINGS */
    float3 rp = p;
    if (rings_dir == NODE_WAVE_RINGS_DIRECTION_X) {
      rp *= make_float3(0.0f, 1.0f, 1.0f);
    }
    else if (rings_dir == NODE_WAVE_RINGS_DIRECTION_Y) {
      rp *= make_float3(1.0f, 0.0f, 1.0f);
    }
    else if (rings_dir == NODE_WAVE_RINGS_DIRECTION_Z) {
      rp *= make_float3(1.0f, 1.0f, 0.0f);
    }
    /* else: NODE_WAVE_RINGS_DIRECTION_SPHERICAL */

    n = len3(rp) * 20.0f;
  }

  n += phase;

  if (distortion != 0.0f)
    n += distortion * (fractal_noise_3d(p * dscale, detail, droughness) * 2.0f - 1.0f);

  if (profile == NODE_WAVE_PROFILE_SIN) {
    return 0.5f + 0.5f * sinf(n - M_PI_2_F);
  }
  else if (profile == NODE_WAVE_PROFILE_SAW) {
    n /= M_2PI_F;
    return n - floorf(n);
  }
  else { /* NODE_WAVE_PROFILE_TRI */
    n /= M_2PI_F;
    return fabsf(n - floorf(n + 0.5f)) * 2.0f;
  }
}

ccl_device void svm_node_tex_wave()
{

  /* RNA properties */
  uint type_offset, bands_dir_offset, rings_dir_offset, profile_offset;
  svm_unpack_node_uchar4(SVM_NODE_WAVE_IN_PACK4_TYPE, (type_offset), (bands_dir_offset), (rings_dir_offset), (profile_offset));

  float f = svm_wave(NodeWaveType(type_offset),
                     NodeWaveBandsDirection(bands_dir_offset),
                     NodeWaveRingsDirection(rings_dir_offset),
                     NodeWaveProfile(profile_offset),
                     SVM_NODE_WAVE_IN_CO *SVM_NODE_WAVE_IN_SCALE,
                     SVM_NODE_WAVE_IN_DISTORTION,
                     SVM_NODE_WAVE_IN_DETAIL,
                     SVM_NODE_WAVE_IN_DSCALE,
                     SVM_NODE_WAVE_IN_DROUGHNESS,
                     SVM_NODE_WAVE_IN_DPHASE);

  SVM_NODE_WAVE_RET_VALUE(f);
  
}



#endif
CCL_NAMESPACE_END

#endif