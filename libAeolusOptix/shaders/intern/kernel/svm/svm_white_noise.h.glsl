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
#define NODE_WN_VECTOR 0
#define NODE_WN_W 3
#define NODE_WN_dim 4
#define NODE_WN_FLAG 5
#define NODE_WN_RET NODE_WN_VECTOR
#define NODE_WN_VAL NODE_WN_W

#ifdef NODE_Caller

ccl_device void svm_node_tex_white_noise(
                                         uint dimensions,
                                         uint inputs_stack_offsets,
                                         uint ouptuts_stack_offsets,
                                         inout int offset)
{
  uint vector_stack_offset, w_stack_offset, value_stack_offset, color_stack_offset;
  svm_unpack_node_uchar2(inputs_stack_offsets, (vector_stack_offset), (w_stack_offset));
  svm_unpack_node_uchar2(ouptuts_stack_offsets, (value_stack_offset), (color_stack_offset));
  bool cstore = stack_valid(color_stack_offset);
  bool vstore = stack_valid(value_stack_offset);

 if (cstore||vstore) {
  nio.type = CALLEE_SVM_TEX_WHITE_NOISE;
  stack_load_float3_nio(vector_stack_offset,NODE_WN_VECTOR)
  stack_load_float_nio(w_stack_offset,NODE_WN_W);
  nio.data[NODE_WN_dim]  =  uintBitsToFloat(dimensions);
  nio.data[NODE_WN_FLAG] = float(((cstore)?1:0) | ((vstore)?2:0));
  EXECUTION_NOISE;
  if (cstore)stack_store_float3_nio(color_stack_offset, NODE_WN_RET);
  if (vstore)stack_store_float_nio(value_stack_offset, NODE_WN_VAL);
 }
 
}

#else

#define NODE_WN_RET_VAL nio.data[NODE_WN_W] 
#define NODE_WN_GET_DIM floatBitsToUint(nio.data[NODE_WN_dim])
#define NODE_WN_RET_COLOR(v) {nio.data[NODE_WN_RET] = v.x;nio.data[NODE_WN_RET+1] = v.y;nio.data[NODE_WN_RET+2] = v.z;}

ccl_device void svm_node_tex_white_noise()
{
  uint dimensions = NODE_WN_GET_DIM;
  vec4 vector = vec4(nio.data[NODE_WN_VECTOR],nio.data[NODE_WN_VECTOR+1],nio.data[NODE_WN_VECTOR+2],nio.data[NODE_WN_W]);
/*
  vec4 vector = vec4(IS_FZERO(nio.data[NODE_WN_VECTOR])?0:nio.data[NODE_WN_VECTOR], 
  IS_FZERO(nio.data[NODE_WN_VECTOR+1])?0:nio.data[NODE_WN_VECTOR+1], 
  IS_FZERO(nio.data[NODE_WN_VECTOR+2])?0:nio.data[NODE_WN_VECTOR+2],
  IS_FZERO(nio.data[NODE_WN_W])?0:nio.data[NODE_WN_W]
  );
*/


  float3 color;
  if(bool(uint(nio.data[NODE_WN_FLAG])&1u)){

    switch (dimensions) {
      case 1:
        color = hash_float_to_float3(vector.w);
        break;
      case 2:
        color = hash_float2_to_float3(vector.xy);
        break;
      case 3:
        color = hash_float3_to_float3(vector);
        break;
      case 4:
        color = hash_float4_to_float3(vector);
        break;
      default:
        color = make_float3(1.0f, 0.0f, 1.0f);
        kernel_assert("assert WN Error flag:78 \n",false);
        break;
    }
    NODE_WN_RET_COLOR(color);
  }

  if(bool(uint(nio.data[NODE_WN_FLAG])&2u)){
    switch (dimensions) {
      case 1:
        NODE_WN_RET_VAL = hash_float_to_float(vector.w);
        break;
      case 2:
       NODE_WN_RET_VAL = hash_float2_to_float(vector.xy);
        break;
      case 3:
        NODE_WN_RET_VAL = hash_float3_to_float(vector);
        break;
      case 4:
        NODE_WN_RET_VAL = hash_float4_to_float(vector);
        break;
      default:
        NODE_WN_RET_VAL = 0.0f;
        kernel_assert("assert WN Error flag:100 \n",false);
        break;
    }
  }




}


#endif

CCL_NAMESPACE_END
