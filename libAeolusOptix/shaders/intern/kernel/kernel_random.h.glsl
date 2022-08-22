#ifndef _KERNEL_RANDOM_H_
#define _KERNEL_RANDOM_H_
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

#include "kernel/kernel_jitter.h.glsl"
#include "util/util_hash.h.glsl"

CCL_NAMESPACE_BEGIN

#define CALLEE_UTILS_RNG_1D    0
#define CALLEE_UTILS_RNG_2D    1
#define CALLEE_UTILS_RNG_INIT  2

#define Float_0XFFFFFFFF 4294967295.0

#ifndef CALL_RNG
/* Pseudo random numbers, uncomment this for debugging correlations. Only run
 * this single threaded on a CPU for repeatable results. */
//#define _DEBUG_CORRELATION_

/* High Dimensional Sobol.
 *
 * Multidimensional sobol with generator matrices. Dimension 0 and 1 are equal
 * to classic Van der Corput and Sobol sequences. */

#ifdef _SOBOL_

/* Skip initial numbers that for some dimensions have clear patterns that
 * don't cover the entire sample space. Ideally we would have a better
 * progressive pattern that doesn't suffer from this problem, because even
 * with this offset some dimensions are quite poor.
 */
#  define SOBOL_SKIP 64


#ifdef _KERNEL_VULKAN_
ccl_device uint sobol_dimension(int index, int dimension)
#else
ccl_device uint sobol_dimension(KernelGlobals *kg, int index, int dimension)
#endif
{
  uint result = 0;
  uint i = index + SOBOL_SKIP;
  for (int j = 0, x; bool(x = int(find_first_set(i)) ); i >>= x) {
    j += x;
    result ^= kernel_tex_fetch(_sample_pattern_lut, 32 * dimension + j - 1);
  }
  return result;
}


#endif /* _SOBOL_ */

#ifdef _KERNEL_VULKAN_
ccl_device_forceinline float path_rng_1D(
     uint rng_hash, int sample_rsv, int num_samples, int dimension)
#else
ccl_device_forceinline float path_rng_1D(
    KernelGlobals *kg, uint rng_hash, int sample_rsv, int num_samples, int dimension)
#endif
{
#ifdef _DEBUG_CORRELATION_
  return (float)drand48();
#endif
  if (kernel_data.integrator.sampling_pattern == SAMPLING_PATTERN_PMJ) {
    return pmj_sample_1D(int(sample_rsv), int(rng_hash), int(dimension) );
  }
#ifdef _CMJ_
#  ifdef _SOBOL_
  if (kernel_data.integrator.sampling_pattern == SAMPLING_PATTERN_CMJ)
#  endif
  {
    /* Correlated multi-jitter. */
    int p = int(rng_hash + dimension);
    return cmj_sample_1D(int(sample_rsv), int(num_samples), int(p));
  }
#endif

#ifdef _SOBOL_
  /* Sobol sequence value using direction vectors. */
  uint result = sobol_dimension(sample_rsv, dimension);
  float r = float(result) * (1.0f / Float_0XFFFFFFFF);

  /* Cranly-Patterson rotation using rng seed */
  float shift;

  /* Hash rng with dimension to solve correlation issues.
   * See T38710, T50116.
   */
  uint tmp_rng = cmj_hash_simple(dimension, rng_hash);
  shift = tmp_rng * (1.0f / Float_0XFFFFFFFF);

  return r + shift - floorf(r + shift);
#endif
}


#ifdef _KERNEL_VULKAN_
ccl_device_forceinline void path_rng_2D(
                                        uint rng_hash,
                                        int sample_rsv,
                                        int num_samples,
                                        int dimension,
                                        inout float fx,
                                        inout float fy)
#else
ccl_device_forceinline void path_rng_2D(KernelGlobals *kg,
                                        uint rng_hash,
                                        int  sample_rsv,
                                        int num_samples,
                                        int dimension,
                                        float *fx,
                                        float *fy)
#endif
{
#ifdef _DEBUG_CORRELATION_
#ifdef _KERNEL_VULKAN_
  fx = float(drand48());
  fy = float(drand48());
#else
  *fx = (float)drand48();
  *fy = (float)drand48();
#endif
  return;
#endif
  if (kernel_data.integrator.sampling_pattern == SAMPLING_PATTERN_PMJ) {
    const float2 f = pmj_sample_2D(sample_rsv, int(rng_hash), dimension);
    #ifdef _KERNEL_VULKAN_
    fx = f.x;
    fy = f.y;
    #else
    *fx = f.x;
    *fy = f.y;
    #endif
    return;
  }
#ifdef _CMJ_
#  ifdef _SOBOL_
  if (kernel_data.integrator.sampling_pattern == SAMPLING_PATTERN_CMJ)
#  endif
  {
    /* Correlated multi-jitter. */
    int p = int(rng_hash + dimension);
    cmj_sample_2D( sample_rsv, num_samples, p, fx, fy);
    return;
  }
#endif

#ifdef _SOBOL_
  /* Sobol. */
  #ifdef _KERNEL_VULKAN_
  fx = path_rng_1D( rng_hash,  sample_rsv, num_samples, dimension);
  fy = path_rng_1D( rng_hash,  sample_rsv, num_samples, dimension + 1);
  #else
  *fx = path_rng_1D(kg, rng_hash,  sample_rsv, num_samples, dimension);
  *fy = path_rng_1D(kg, rng_hash,  sample_rsv, num_samples, dimension + 1);
  #endif
#endif
}

#ifdef _KERNEL_VULKAN_
ccl_device_inline void path_rng_init(
                                     int  sample_rsv,
                                     int num_samples,
                                     inout uint rng_hash,
                                     int x,
                                     int y,
                                     inout float fx,
                                     inout float fy)
#else
ccl_device_inline void path_rng_init(KernelGlobals *kg,
                                     int  sample_rsv,
                                     int num_samples,
                                     uint *rng_hash,
                                     int x,
                                     int y,
                                     float *fx,
                                     float *fy)
#endif
{
  /* load state */
  #ifdef _KERNEL_VULKAN_
  rng_hash = hash_uint2(x, y);
  rng_hash ^= kernel_data.integrator.seed;
  #else
  *rng_hash = hash_uint2(x, y);
  *rng_hash ^= kernel_data.integrator.seed;
  #endif

#ifdef _DEBUG_CORRELATION_
  #ifdef _KERNEL_VULKAN_
   srand48(rng_hash +  sample_rsv);
   #else
   srand48(*rng_hash +  sample_rsv);
   #endif
#endif

  if ( sample_rsv == 0) {
    #ifdef _KERNEL_VULKAN_
    fx = 0.5f;
    fy = 0.5f;
    #else
    *fx = 0.5f;
    *fy = 0.5f;
    #endif
  }
  else {
    #ifdef _KERNEL_VULKAN_
    path_rng_2D(rng_hash, sample_rsv, num_samples, int(PRNG_FILTER_U), fx, fy);
    #else
    path_rng_2D(kg, *rng_hash, sample_rsv, num_samples, PRNG_FILTER_U, fx, fy);
    #endif
  }
}

/* Linear Congruential Generator */

#else

#if !defined(_SOBOL_) | !defined(_CMJ_)
#error " require SOBOL and CMJ"
#endif




#ifdef RNG_Caller

#define CALLABLE_RNG 11u
#define CALLABLE_RNG_LOCATION 2
#define EXECUTION_RNG    executeCallableNV(CALLABLE_RNG,CALLABLE_RNG_LOCATION)

#define path_rng_1D(rng_hash,sample_rsv,num_samples, dimension,ret) {\
   arg2.v[0] = uintBitsToFloat(rng_hash);\
   arg2.v[1] = intBitsToFloat(sample_rsv);\
   arg2.v[2] = intBitsToFloat(num_samples);\
   arg2.v[3] = intBitsToFloat(dimension);\
   arg2.v[4] = uintBitsToFloat(CALLEE_UTILS_RNG_1D);\
   arg2.v[5] = uintBitsToFloat(kernel_data.integrator.sampling_pattern);\
   EXECUTION_RNG;\
   ret = arg2.v[0];\
}  

#define path_rng_2D(rng_hash,sample_rsv,num_samples,dimension,fx,fy) {\
   arg2.v[0] = uintBitsToFloat(rng_hash);\
   arg2.v[1] = intBitsToFloat(sample_rsv);\
   arg2.v[2] = intBitsToFloat(num_samples);\
   arg2.v[3] = intBitsToFloat(dimension);\
   arg2.v[4] = uintBitsToFloat(CALLEE_UTILS_RNG_2D);\
   arg2.v[5] = uintBitsToFloat(kernel_data.integrator.sampling_pattern);\
   EXECUTION_RNG;\
   fx = arg2.v[0];\
   fy = arg2.v[1];\
}

#define path_rng_init(sample_rsv,num_samples,rng_hash,x,y,fx,fy) {\
   arg2.v[0] = uintBitsToFloat(rng_hash);\
   arg2.v[1] = intBitsToFloat(sample_rsv);\
   arg2.v[2] = intBitsToFloat(num_samples);\
   arg2.v[3] = intBitsToFloat(0);\
   arg2.v[4] = uintBitsToFloat(CALLEE_UTILS_RNG_INIT);\
   arg2.v[5] = uintBitsToFloat(kernel_data.integrator.sampling_pattern);\
   arg2.v[6] = uintBitsToFloat(x);\
   arg2.v[7] = uintBitsToFloat(y);\
   arg2.v[8] = intBitsToFloat(kernel_data.integrator.seed);\
  EXECUTION_RNG;\
  fx =  arg2.v[0];\
  fy =  arg2.v[1];\
  rng_hash = uint(floatBitsToInt( arg2.v[2]));\
}

#endif

#ifdef RNG_Callee

#define RNG_RET1(f) arg.rng_hash   = floatBitsToUint(f)
#define RNG_RET2(f) arg.sample_rsv = floatBitsToInt(f)
#define RNG_RET_HASH(f) arg.num_samples = int(f)


#define SOBOL_SKIP 64
ccl_device uint sobol_dimension(int index, int dimension)
{
  uint result = 0;
  uint i = index + SOBOL_SKIP;
  for (int j = 0, x; bool(x = int(find_first_set(i)) ); i >>= x) {
    j += x;
    result ^= kernel_tex_fetch(_sample_pattern_lut, 32 * dimension + j - 1);
  }
  return result;
}



float path_rng_1D(uint rng_hash)
{
 if (arg.sampling == SAMPLING_PATTERN_PMJ) {
    return pmj_sample_1D(arg.sample_rsv, int(rng_hash), arg.dimension);

   }
 if (arg.sampling == SAMPLING_PATTERN_CMJ)
  {
    /* Correlated multi-jitter. */
    int p = int(rng_hash) + arg.dimension;
    return cmj_sample_1D(arg.sample_rsv, int(arg.num_samples), int(p));
  }
  /* Sobol sequence value using direction vectors. */
  uint result = sobol_dimension(arg.sample_rsv, arg.dimension);
  float r = float(result) * (1.0f / Float_0XFFFFFFFF);
  /* Cranly-Patterson rotation using rng seed */
  float shift;
  /* Hash rng with dimension to solve correlation issues.
   * See T38710, T50116.
   */
  uint tmp_rng = cmj_hash_simple(arg.dimension, rng_hash);
  shift = tmp_rng * (1.0f / Float_0XFFFFFFFF);
  return r + shift - floorf(r + shift);
}

void path_rng_2D(uint rng_hash)
{

  if (arg.sampling  == SAMPLING_PATTERN_PMJ) {
    const float2 f = pmj_sample_2D(arg.sample_rsv, int(rng_hash), arg.dimension);
    RNG_RET1(f.x);
    RNG_RET2(f.y);
    return;
  }

  if (arg.sampling  == SAMPLING_PATTERN_CMJ)
  {
    /* Correlated multi-jitter. */
    int p = int(rng_hash) + arg.dimension;
    float fx,fy;
    cmj_sample_2D( arg.sample_rsv, arg.num_samples, p, fx, fy);
    RNG_RET1(fx);
    RNG_RET2(fy);
    return;
  }

  RNG_RET1(path_rng_1D(rng_hash));
  arg.dimension +=1;
  RNG_RET2(path_rng_1D(rng_hash));

}

#define  path_rng_init(rng_hash)  {\
  rng_hash = hash_uint2(arg.x, arg.y);\
  rng_hash ^= arg.seed;\
  RNG_RET_HASH(rng_hash);\
  if ( arg.sample_rsv == 0) {\
    RNG_RET1(0.5f);\
    RNG_RET2(0.5f);\
  }\
  else {\
    path_rng_2D(rng_hash);\
  }\
}

#endif



#endif

#ifndef RNG_Callee


ccl_device uint lcg_step_uint(inout uint rng)
{
  /* implicit mod 2^32 */
  rng = (1103515245U * (rng) + 12345U);
  return rng;
}

ccl_device float lcg_step_float(inout uint rng)
{
  /* implicit mod 2^32 */
  rng = (1103515245U * (rng) + 12345U);
  return float(rng) * (1.0f / Float_0XFFFFFFFF);
}

ccl_device uint lcg_init(in uint seed)
{
  uint rng = seed;
  lcg_step_uint(rng);
  return rng;
}



/* Path Tracing Utility Functions
 *
 * For each random number in each step of the path we must have a unique
 * dimension to avoid using the same sequence twice.
 *
 * For branches in the path we must be careful not to reuse the same number
 * in a sequence and offset accordingly.
 */
#ifdef GSTATE
ccl_device_inline float path_state_rng_1D(int dimension)
{
  #ifdef CALL_RNG
  float ret;
  path_rng_1D(GSTATE.rng_hash, GSTATE.sample_rsv, GSTATE.num_samples, GSTATE.rng_offset + dimension,ret);
  return ret;
  #else
  return path_rng_1D(GSTATE.rng_hash, GSTATE.sample_rsv, GSTATE.num_samples, GSTATE.rng_offset + dimension);
  #endif
}
/* Utility functions to get light termination value,
 * since it might not be needed in many cases.
 */
ccl_device_inline float path_state_rng_light_termination(
                                                         inout PathState state)
{
  if (kernel_data.integrator.light_inv_rr_threshold > 0.0f) {
    return path_state_rng_1D(int(PRNG_LIGHT_TERMINATE));
  }
  return 0.0f;
}

#endif





ccl_device_inline void path_state_rng_2D(in PathState STATE,int dimension, inout float fx,inout float fy)
{

  path_rng_2D(
             STATE.rng_hash,
             STATE.sample_rsv,
             STATE.num_samples,
             STATE.rng_offset + dimension,
              fx,
              fy);

}

ccl_device_inline float path_state_rng_1D_hash(
                                               inout  PathState state,
                                               uint hash)
{
  /* Use a hash instead of dimension, this is not great but avoids adding
   * more dimensions to each bounce which reduces quality of dimensions we
   * are already using. */
  #ifdef CALL_RNG
  float ret;
  path_rng_1D(cmj_hash_simple(state.rng_hash, hash),
                     state.sample_rsv,
                     state.num_samples,
                     state.rng_offset,ret);
  return ret;
  #else
  return path_rng_1D(
                     cmj_hash_simple(state.rng_hash, hash),
                     state.sample_rsv,
                     state.num_samples,
                     state.rng_offset);
  #endif

}

ccl_device_inline float path_branched_rng_1D(
                                             uint rng_hash,
                                             inout PathState state,
                                             int branch,
                                             int num_branches,
                                             int dimension)
{
    #ifdef CALL_RNG
  float ret;
  path_rng_1D(rng_hash,
                     state.sample_rsv * num_branches + branch,
                     state.num_samples * num_branches,
                     state.rng_offset + dimension,ret);
  return ret;
  #else
  return path_rng_1D(
                     rng_hash,
                     state.sample_rsv * num_branches + branch,
                     state.num_samples * num_branches,
                     state.rng_offset + dimension);
  #endif
}



ccl_device_inline float path_branched_rng_light_termination(
                                                            uint rng_hash,
                                                            inout PathState state,
                                                            int branch,
                                                            int num_branches)
{
  if (kernel_data.integrator.light_inv_rr_threshold > 0.0f) {
    return path_branched_rng_1D(rng_hash, state, branch, num_branches, int(PRNG_LIGHT_TERMINATE));
  }
  return 0.0f;
}

ccl_device_inline uint lcg_state_init(inout PathState state, uint scramble)
{
  return lcg_init(state.rng_hash + state.rng_offset + state.sample_rsv * scramble);
}





ccl_device_inline uint lcg_state_init_addrspace(inout PathState state, uint scramble)
{
  return lcg_init( uint(state.rng_hash + state.rng_offset + state.sample_rsv * scramble));
}


ccl_device float lcg_step_float_addrspace(inout ccl_addr_space uint rng)
{
  /* Implicit mod 2^32 */
  rng = (1103515245U * (rng) + 12345U);
  return float(rng) * (1.0f / Float_0XFFFFFFFF);
}





ccl_device_inline void path_branched_rng_2D(
                                            uint rng_hash,
                                            in PathState state,
                                            int branch,
                                            int num_branches,
                                            int dimension,
                                            inout float fx,
                                            inout float fy)
{
  path_rng_2D(
              rng_hash,
              state.sample_rsv * num_branches + branch,
              state.num_samples * num_branches,
              state.rng_offset + dimension,
              fx,
              fy);
}


ccl_device_inline bool sample_is_even(int pattern, int sample_rsv)
{
  if (pattern == SAMPLING_PATTERN_PMJ) {
    /* See Section 10.2.1, "Progressive Multi-Jittered Sample Sequences", Christensen et al.
     * We can use this to get divide sample sequence into two classes for easier variance
     * estimation. */
#if defined(_GNUC_) && !defined(_KERNEL_GPU_)
    return _builtin_popcount(sample_rsv & 0xaaaaaaaa) & 1;
#elif defined(_NVCC_)
    return _popc(sample_rsv & 0xaaaaaaaa) & 1;
#elif defined(_KERNEL_OPENCL_)
    return popcount(sample_rsv & 0xaaaaaaaa) & 1;
#else
    /* TODO(Stefan): popcnt intrinsic for Windows with fallback for older CPUs. */
    int i = sample_rsv & 0xaaaaaaaa;
    i = i - ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    i = (((i + (i >> 4)) & 0xF0F0F0F) * 0x1010101) >> 24;
    return bool(i & 1);
#endif
  }
  else {
    /* TODO(Stefan): Are there reliable ways of dividing CMJ and Sobol into two classes? */
    return bool(sample_rsv & 0x1);
  }
}


#endif

CCL_NAMESPACE_END

#endif