/*
 * Copyright 2011-2016 Blender Foundation
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

CCL_NAMESPACE_BEGIN

ccl_device ShaderClosure *closure_alloc(ShaderData *sd, int size, ClosureType type, float3 weight)
{
  kernel_assert(size <= sizeof(ShaderClosure));

  if (sd->num_closure_left == 0)
    return NULL;

  ShaderClosure *sc = &sd->closure[sd->num_closure];

  sc->type   = type;
  sc->weight = weight;

  sd->num_closure++;
  sd->num_closure_left--;

  return sc;
}

ccl_device ccl_addr_space void *closure_alloc_extra(ShaderData *sd, int size)
{
  /* Allocate extra space for closure that need more parameters. We allocate
   * in chunks of sizeof(ShaderClosure) starting from the end of the closure
   * array.
   *
   * This lets us keep the same fast array iteration over closures, as we
   * found linked list iteration and iteration with skipping to be slower. */
  int num_extra = ((size + sizeof(ShaderClosure) - 1) / sizeof(ShaderClosure));

  if (num_extra > sd->num_closure_left) {
    /* Remove previous closure if it was allocated. */
    sd->num_closure--;
    sd->num_closure_left++;
    return NULL;
  }

  sd->num_closure_left -= num_extra;
  return (ccl_addr_space void *)(sd->closure + sd->num_closure + sd->num_closure_left);
}

ccl_device_inline ShaderClosure *bsdf_alloc(ShaderData *sd, int size, float3 weight)
{
  ShaderClosure *sc = closure_alloc(sd, size, CLOSURE_NONE_ID, weight);

  if (sc == NULL)
    return NULL;

  float sample_weight = fabsf(average(weight));
  sc->sample_weight = sample_weight;
  //return (sample_weight >= CLOSURE_WEIGHT_CUTOFF) ? sc : NULL;
  if (sample_weight >= CLOSURE_WEIGHT_CUTOFF) {

      return sc;
  }
  else {
#ifdef WITH_STAT_AUX  
      stat_aux.add(&stat_aux.hit_rec_cnt[11]);
#endif
  }
      return NULL;
  
}

#ifdef __OSL__
ccl_device_inline ShaderClosure *bsdf_alloc_osl(ShaderData *sd,
                                                int size,
                                                float3 weight,
                                                void *data)
{
  ShaderClosure *sc = closure_alloc(sd, size, CLOSURE_NONE_ID, weight);

  if (!sc)
    return NULL;

  memcpy((void *)sc, data, size);

  float sample_weight = fabsf(average(weight));
  sc->weight = weight;
  sc->sample_weight = sample_weight;
  return (sample_weight >= CLOSURE_WEIGHT_CUTOFF) ? sc : NULL;
}
#endif

CCL_NAMESPACE_END
