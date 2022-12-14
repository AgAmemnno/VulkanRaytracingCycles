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

ccl_device_inline bool svm_node_aov_check(ccl_addr_space inout PathState state,
                                          int ofs/*global ssbo offset*/)
{
  int path_flag = state.flag;

  bool is_primary = bool(path_flag & PATH_RAY_CAMERA) && (!bool(path_flag & PATH_RAY_SINGLE_PASS_DONE));

  return ((!isNULLI(ofs)) && is_primary);
}

ccl_device void svm_node_aov_color(
    inout KernelGlobals kg, inout ShaderData sd, inout float stack[SVM_STACK_SIZE]
, uint4 node, int ofs/*global ssbo offset*/)
{
  float3 val = stack_load_float3(stack, node.y);

  if(!isNULLI(ofs)){

    kernel_write_pass_float4(int(ofs + kernel_data.film.pass_aov_color + 4 * node.z),

                             make_float4(val.x, val.y, val.z, 1.0f));
  }
}

ccl_device void svm_node_aov_value(
    inout KernelGlobals kg, inout ShaderData sd, inout float stack[SVM_STACK_SIZE]
, uint4 node, int ofs/*global ssbo offset*/)
{
  float val = stack_load_float(stack, node.y);

  if(!isNULLI(ofs)){

    kernel_write_pass_float(int(ofs + kernel_data.film.pass_aov_value + node.z), val);

  }
}
CCL_NAMESPACE_END
