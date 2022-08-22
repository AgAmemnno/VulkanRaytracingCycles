#ifndef _SVM_SEPCOMB_VECTOR_H_
#define _SVM_SEPCOMB_VECTOR_H_
/*
 * Copyright 2011-2014 Blender Foundation
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

/* Vector combine / separate, used for the RGB and XYZ nodes */

#define svm_node_combine_vector(in_offset,vector_index,out_offset) if (stack_valid(out_offset)) stack_store_float(out_offset + vector_index, stack_load_float(in_offset));

#define  svm_node_separate_vector(ivector_offset,vector_index,out_offset)\
{\
  float3 vector = stack_load_float3(ivector_offset);\
  if (stack_valid(out_offset)) {\
    if (vector_index == 0)stack_store_float(out_offset, vector.x);\
    else if (vector_index == 1)stack_store_float(out_offset, vector.y);\
    else stack_store_float(out_offset, vector.z);\
  }\
}

CCL_NAMESPACE_END
#endif
