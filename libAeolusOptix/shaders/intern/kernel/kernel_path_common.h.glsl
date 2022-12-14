/*
 * Copyright 2011-2015 Blender Foundation
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

#include "util/util_hash.h.glsl"

CCL_NAMESPACE_BEGIN

ccl_device_inline void kernel_path_trace_setup( int x,int y, int sample_rsv,inout  uint rng_hash, inout  Ray ray)
{
  float filter_u;
  float filter_v;
  int   num_samples = kernel_data.integrator.aa_samples;
  //path_rng_init(sample_rsv, num_samples, rng_hash, x, y, filter_u, filter_v);

  path_rng_init(sample_rsv, num_samples, rng_hash, x, y, filter_u, filter_v);

  /* sample camera ray */
  float lens_u = 0.0f, lens_v = 0.0f;
  if (kernel_data.cam.aperturesize > 0.0f){
    path_rng_2D(rng_hash, sample_rsv, num_samples,  int(PRNG_LENS_U), lens_u, lens_v);
  }

  float time = 0.0f;

#ifdef _CAMERA_MOTION_
  if (kernel_data.cam.shuttertime != -1.0f){
    #ifdef CALL_RNG
     path_rng_1D(rng_hash, sample_rsv, num_samples,int(PRNG_TIME),time);
    #else
     time = path_rng_1D(rng_hash, sample_rsv, num_samples,int(PRNG_TIME));
    #endif
  }
#endif

  camera_sample(x, y, filter_u, filter_v, lens_u, lens_v, time, ray);
}

CCL_NAMESPACE_END
