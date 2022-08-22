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

/* Value Nodes */
#ifdef stack_store_float
#define svm_node_value_f(ivalue,out_offset) stack_store_float(out_offset, _uint_as_float(ivalue));
#define svm_node_value_v(out_offset, offset) uint4 node1 = read_node(offset);stack_store_float3(out_offset, make_float3(_uint_as_float(node1.y), _uint_as_float(node1.z), _uint_as_float(node1.w)));
#endif

CCL_NAMESPACE_END
