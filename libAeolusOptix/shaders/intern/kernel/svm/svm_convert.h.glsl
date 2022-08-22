#ifndef _SVM_CONVERT_H_
#define _SVM_CONVERT_H_
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

/* Conversion Nodes */

/* Conversion Nodes */

ccl_device void svm_node_convert( uint type, uint from, uint to)
{
  switch (type) {
    case NODE_CONVERT_FI: {
      float f = stack_load_float(from);
      stack_store_int(to, float_to_int(f));
      break;
    }
    case NODE_CONVERT_FV: {
      float f = stack_load_float(from);
      stack_store_float3(to, make_float3(f, f, f));
      break;
    }
    case NODE_CONVERT_CF: {
      float3 f = stack_load_float3(from);
      float g = linear_rgb_to_gray(f);
      stack_store_float(to, g);
      break;
    }
    case NODE_CONVERT_CI: {
      float3 f = stack_load_float3(from);
      int i = int(linear_rgb_to_gray(f));
      stack_store_int(to, i);
      break;
    }
    case NODE_CONVERT_VF: {
      float3 f = stack_load_float3(from);
      float g = average(f);
      stack_store_float(to, g);
      break;
    }
    case NODE_CONVERT_VI: {
      float3 f = stack_load_float3(from);
      int i = int(average(f));
      stack_store_int(to, i);
      break;
    }
    case NODE_CONVERT_IF: {
      float f = float(stack_load_int(from));
      stack_store_float(to, f);
      break;
    }
    case NODE_CONVERT_IV: {
      float f = float(stack_load_int(from));
      stack_store_float3(to, make_float3(f, f, f));
      break;
    }
  }
}

CCL_NAMESPACE_END
#endif