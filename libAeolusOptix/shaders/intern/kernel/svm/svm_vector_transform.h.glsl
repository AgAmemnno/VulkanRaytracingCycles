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

/* Vector Transform */

ccl_device void svm_node_vector_transform(uint4 node)
{
  uint itype, ifrom, ito;
  uint vector_in, vector_out;

  svm_unpack_node_uchar3(node.y, (itype), (ifrom), (ito));
  svm_unpack_node_uchar2(node.z, (vector_in), (vector_out));

  float3 in_rsv = stack_load_float3(vector_in);
  NodeVectorTransformType type = NodeVectorTransformType(itype);
  NodeVectorTransformConvertSpace from = NodeVectorTransformConvertSpace(ifrom);
  NodeVectorTransformConvertSpace to = NodeVectorTransformConvertSpace(ito);
  Transform tfm;
  bool is_object = (GSD.object != OBJECT_NONE);
  bool is_direction = (type == NODE_VECTOR_TRANSFORM_TYPE_VECTOR ||
                       type == NODE_VECTOR_TRANSFORM_TYPE_NORMAL);
  /* From world */
  if (from == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_WORLD) {
    if (to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_CAMERA) {
      tfm = kernel_data.cam.worldtocamera;
      if (is_direction)
        in_rsv = transform_direction((tfm), in_rsv);

      else
        in_rsv = transform_point((tfm), in_rsv);
    }
    else if (to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_OBJECT && is_object) {
      if (is_direction)
        object_inverse_dir_transform(in_rsv);
      else
        object_inverse_position_transform(in_rsv);
    }
  }

  /* From camera */
  else if (from == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_CAMERA) {
    if (to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_WORLD ||
        to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_OBJECT) {
      tfm = kernel_data.cam.cameratoworld;
      if (is_direction)
        in_rsv = transform_direction((tfm), in_rsv);

      else
        in_rsv = transform_point((tfm), in_rsv);

    }
    if (to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_OBJECT && is_object) {
      if (is_direction)
        object_inverse_dir_transform(in_rsv);

      else
        object_inverse_position_transform(in_rsv);
    }
  }

  /* From object */
  else if (from == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_OBJECT) {
    if ((to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_WORLD ||
         to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_CAMERA) &&
        is_object) {
      if (is_direction)
        object_dir_transform(in_rsv);

      else
        object_position_transform(in_rsv);

    }
    if (to == NODE_VECTOR_TRANSFORM_CONVERT_SPACE_CAMERA) {
      tfm = kernel_data.cam.worldtocamera;
      if (is_direction)
        in_rsv = transform_direction((tfm), in_rsv);

      else
        in_rsv = transform_point((tfm), in_rsv);

    }
  }

  /* Normalize Normal */
  if (type == NODE_VECTOR_TRANSFORM_TYPE_NORMAL)
    in_rsv = normalize(in_rsv);

  /* Output */
  if (stack_valid(vector_out)) {
    stack_store_float3(vector_out, in_rsv);
  }
}

CCL_NAMESPACE_END
