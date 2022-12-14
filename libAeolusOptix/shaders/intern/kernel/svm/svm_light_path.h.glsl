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

CCL_NAMESPACE_BEGIN

/* Light Path Node */

ccl_device void svm_node_light_path(inout ShaderData sd,
                                    ccl_addr_space inout PathState state,
                                    inout float stack[SVM_STACK_SIZE]
,
                                    uint type,
                                    uint out_offset,
                                    int path_flag)
{
  float info = 0.0f;

  switch (type) {
    case NODE_LP_camera:
      info = (bool(path_flag & PATH_RAY_CAMERA)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_shadow:
      info = (bool(path_flag & PATH_RAY_SHADOW)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_diffuse:
      info = (bool(path_flag & PATH_RAY_DIFFUSE)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_glossy:
      info = (bool(path_flag & PATH_RAY_GLOSSY)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_singular:
      info = (bool(path_flag & PATH_RAY_SINGULAR)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_reflection:
      info = (bool(path_flag & PATH_RAY_REFLECT)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_transmission:
      info = (bool(path_flag & PATH_RAY_TRANSMIT)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_volume_scatter:
      info = (bool(path_flag & PATH_RAY_VOLUME_SCATTER)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_backfacing:
      info = (bool(sd.flag & SD_BACKFACING)) ? 1.0f : 0.0f;

      break;
    case NODE_LP_ray_length:
      info = sd.ray_length;
      break;
    case NODE_LP_ray_depth:
      info = float(state.bounce);

      break;
    case NODE_LP_ray_diffuse:
      info = float(state.diffuse_bounce);

      break;
    case NODE_LP_ray_glossy:
      info = float(state.glossy_bounce);

      break;
    case NODE_LP_ray_transparent:
      info = float(state.transparent_bounce);

      break;
    case NODE_LP_ray_transmission:
      info = float(state.transmission_bounce);

      break;
  }

  stack_store_float(stack, out_offset, info);
}

/* Light Falloff Node */

ccl_device void svm_node_light_falloff(inout ShaderData sd, inout float stack[SVM_STACK_SIZE]
, uint4 node)
{
  uint strength_offset, out_offset, smooth_offset;

  svm_unpack_node_uchar3(node.z, (strength_offset), (smooth_offset), (out_offset));




  float strength = stack_load_float(stack, strength_offset);
  uint type = node.y;

  switch (type) {
    case NODE_LIGHT_FALLOFF_QUADRATIC:
      break;
    case NODE_LIGHT_FALLOFF_LINEAR:
      strength *= sd.ray_length;
      break;
    case NODE_LIGHT_FALLOFF_CONSTANT:
      strength *= sd.ray_length * sd.ray_length;
      break;
  }

  float smooth_rsv = stack_load_float(stack, smooth_offset);

  if (smooth_rsv > 0.0f) {
    float squared = sd.ray_length * sd.ray_length;
    /* Distant lamps set the ray length to FLT_MAX, which causes squared to overflow. */
    if (isfinite_safe
(squared)) {
      strength *= squared / (smooth_rsv + squared);
    }
  }

  stack_store_float(stack, out_offset, strength);
}

CCL_NAMESPACE_END
