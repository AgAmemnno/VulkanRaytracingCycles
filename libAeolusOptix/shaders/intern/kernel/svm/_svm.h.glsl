#ifndef _SVM_H_
#define _SVM_H_
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



/* Shader Virtual Machine
 *
 * A shader is a list of nodes to be executed. These are simply read one after
 * the other and executed, using an node counter. Each node and it's associated
 * data is encoded as one or more uint4's in_rsv a 1D texture. If the data is larger
 * than an uint4, the node can increase the node counter to compensate for this.
 * Floats are encoded as int and then converted to float again.
 *
 * Nodes write their output into a stack. All stack data in_rsv the stack is
 * floats, since it's all factors, colors and vectors. The stack will be stored
 * in_rsv local memory on the GPU, as it would take too many register and indexes in_rsv
 * ways not known at compile time. This seems the only solution even though it
 * may be slow, with two positive factors. If the same shader is being executed,
 * memory access will be coalesced and cached.
 *
 * The result of shader execution will be a single closure. This means the
 * closure type, associated label, data and weight. Sampling from multiple
 * closures is supported through the mix closure node, the logic for that is
 * mostly taken care of in_rsv the SVM compiler.
 */


#include "kernel/svm/svm_types.h.glsl"

/* Reading Nodes */
#define read_node(offset) kernel_tex_fetch(_svm_nodes, offset++)
#define read_node_float(f, offset)\
{\
  uint4 node = kernel_tex_fetch(_svm_nodes, offset);\
  f  = make_float4(_uint_as_float(node.x),_uint_as_float(node.y),_uint_as_float(node.z),_uint_as_float(node.w));\
  offset++;\
}
#define svm_unpack_node_uchar2(i, x,  y)\
{\
  x = (i & 0xFF);\
  y = ((i >> 8) & 0xFF);\
}

#define svm_unpack_node_uchar3(i, x,  y, z)\
{\
  x = (i & 0xFF);\
  y = ((i >> 8) & 0xFF);\
  z = ((i >> 16) & 0xFF);\
}

#define svm_unpack_node_uchar4(i, x, y, z, w)\
{\
  x = (i & 0xFF);\
  y = ((i >> 8) & 0xFF);\
  z = ((i >> 16) & 0xFF);\
  w = ((i >> 24) & 0xFF);\
}

#ifndef NO_SVM_NODES
float3 fetch_node_float(int offset) {
  uint4 node = kernel_tex_fetch(_svm_nodes, offset);
  return make_float4(_uint_as_float(node.x),_uint_as_float(node.y),_uint_as_float(node.z),_uint_as_float(node.w));
}
#endif
/* Stack */
#define stack_valid(a) (a != uint(SVM_STACK_INVALID))
#ifdef NODE_Caller
float stack[255];
#define stack_load_float3(a) make_float3(stack[a + 0], stack[a + 1], stack[a + 2])
#define stack_store_float3(a,f) {stack[a + 0] = f.x;stack[a + 1] = f.y;stack[a + 2] = f.z;}
#define stack_load_float(a) stack[a]
#define stack_load_float_default(a,value) ((a == uint(SVM_STACK_INVALID)) ? _uint_as_float(value) : stack_load_float(a) );

#define stack_store_float( a, f) stack[a] = f
#define stack_load_int(a) _float_as_int(stack[a])
#define stack_load_int_default(a,value) ((a == uint(SVM_STACK_INVALID) ) ? int(value) : stack_load_int(a))
#define stack_store_int(a,i) stack[a] = _int_as_float(i)
#endif


#ifdef SVM_ORIG
#include "kernel/svm/svm_noise.h.glsl"
#include "kernel/svm/svm_fractal_noise.h.glsl"
#include "kernel/svm/svm_color_util.h.glsl"
#include "kernel/svm/svm_mapping_util.h.glsl"
#include "kernel/svm/svm_math_util.h.glsl"
#include "kernel/svm/svm_aov.h.glsl"
#include "kernel/svm/svm_attribute.h.glsl"
#include "kernel/svm/svm_blackbody.h.glsl"
#include "kernel/svm/svm_brick.h.glsl"
#include "kernel/svm/svm_brightness.h.glsl"
#include "kernel/svm/svm_bump.h.glsl"
#include "kernel/svm/svm_camera.h.glsl"
#include "kernel/svm/svm_checker.h.glsl"

#include "kernel/svm/svm_clamp.h.glsl"
#include "kernel/svm/svm_closure.h.glsl"
#include "kernel/svm/svm_convert.h.glsl"
#include "kernel/svm/svm_displace.h.glsl"
#include "kernel/svm/svm_fresnel.h.glsl"
#include "kernel/svm/svm_gamma.h.glsl"
#include "kernel/svm/svm_geometry.h.glsl"
#include "kernel/svm/svm_gradient.h.glsl"
#include "kernel/svm/svm_hsv.h.glsl"
#include "kernel/svm/svm_ies.h.glsl"
#include "kernel/svm/svm_image.h.glsl"
#include "kernel/svm/svm_invert.h.glsl"
#include "kernel/svm/svm_light_path.h.glsl"
#include "kernel/svm/svm_magic.h.glsl"
#include "kernel/svm/svm_map_range.h.glsl"
#include "kernel/svm/svm_mapping.h.glsl"
#include "kernel/svm/svm_math.h.glsl"
#include "kernel/svm/svm_mix.h.glsl"
#include "kernel/svm/svm_musgrave.h.glsl"
#include "kernel/svm/svm_noisetex.h.glsl"
#include "kernel/svm/svm_normal.h.glsl"
#include "kernel/svm/svm_ramp.h.glsl"
#include "kernel/svm/svm_sepcomb_hsv.h.glsl"
#include "kernel/svm/svm_sepcomb_vector.h.glsl"
#include "kernel/svm/svm_sky.h.glsl"
#include "kernel/svm/svm_tex_coord.h.glsl"
#include "kernel/svm/svm_value.h.glsl"
#include "kernel/svm/svm_vector_rotate.h.glsl"
#include "kernel/svm/svm_vector_transform.h.glsl"
#include "kernel/svm/svm_vertex_color.h.glsl"
#include "kernel/svm/svm_voronoi.h.glsl"
#include "kernel/svm/svm_voxel.h.glsl"
#include "kernel/svm/svm_wave.h.glsl"
#include "kernel/svm/svm_wavelength.h.glsl"
#include "kernel/svm/svm_white_noise.h.glsl"
#include "kernel/svm/svm_wireframe.h.glsl"
#ifdef _SHADER_RAYTRACE_
#  include "kernel/svm/svm_ao.h.glsl"
#  include "kernel/svm/svm_bevel.h.glsl"
#endif
/* Nodes */
#endif



#ifdef NODE_Caller

#include "kernel/svm/svm_mix.h.glsl"
#include "kernel/svm/svm_value.h.glsl"
#include "kernel/svm/svm_convert.h.glsl"
#include "kernel/svm/svm_ramp.h.glsl"
#include "kernel/svm/svm_tex_coord.h.glsl"
#include "kernel/svm/svm_attribute.h.glsl"
#include "kernel/svm/svm_map_range.h.glsl"
#include "kernel/svm/svm_sepcomb_vector.h.glsl"
#include "kernel/svm/svm_math.h.glsl"
#include "kernel/svm/svm_gamma.h.glsl"
#include "kernel/svm/svm_hsv.h.glsl"
#include "kernel/svm/svm_sepcomb_hsv.h.glsl"
#include "kernel/svm/svm_brightness.h.glsl"
#include "kernel/svm/svm_mapping.h.glsl"
#include "kernel/svm/svm_noisetex.h.glsl"
#include "kernel/svm/svm_white_noise.h.glsl"
#include "kernel/svm/svm_wave.h.glsl"
#include "kernel/svm/svm_voronoi.h.glsl"
#include "kernel/svm/svm_musgrave.h.glsl"
#include "kernel/svm/svm_sky.h.glsl"
#include "kernel/svm/svm_image.h.glsl"
#include "kernel/svm/svm_checker.h.glsl"
#include "kernel/svm/svm_geometry.h.glsl"
#include "kernel/svm/svm_displace.h.glsl"
#include "kernel/svm/svm_vector_rotate.h.glsl"
#include "kernel/svm/svm_vector_transform.h.glsl"
#include "kernel/svm/svm_vertex_color.h.glsl"
//ShaderClosure accessor
#include "kernel/svm/svm_closure.h.glsl"

CCL_NAMESPACE_BEGIN

/* Main Interpreter Loop */

/* Main Interpreter Loop */
ccl_device_noinline void svm_eval_nodes(
                                        ShaderType type,
                                        int path_flag)
{

  int offset = int(sd.shader & SHADER_MASK);

   if( gl_LaunchIDNV.xy == uvec2(256, 256)){
    uint4 node = read_node(offset);
    debugPrintfEXT("Shader Eval offset  %v4u  %u  \n",node,sd.alloc_offset);
   }




  while (true) {
    uint4 node = read_node(offset);
    switch (node.x) {     
      case NODE_END:
        return;
#if NODES_GROUP(NODE_GROUP_LEVEL_0)
      case NODE_SHADER_JUMP: {
        //if (type == SHADER_TYPE_SURFACE)
          offset = int(node.y);
        /*
        else if (type == SHADER_TYPE_VOLUME)
          offset = node.z;
        else if (type == SHADER_TYPE_DISPLACEMENT)
          offset = node.w;
        else
          return;
        */
        break;
      }
      case NODE_CLOSURE_BSDF:
        svm_node_closure_bsdf(node, type, path_flag, offset);
        break;
      case NODE_CLOSURE_EMISSION:
        svm_node_closure_emission( node);
        break;
      case NODE_CLOSURE_BACKGROUND:
        svm_node_closure_background(node);
        break;
      case NODE_CLOSURE_SET_WEIGHT:
        svm_node_closure_set_weight(node.y, node.z, node.w);
        break;
      case NODE_CLOSURE_WEIGHT:
        svm_node_closure_weight(node.y);
        break;
      case NODE_EMISSION_WEIGHT:
        svm_node_emission_weight(node);
        break;
      case NODE_MIX_CLOSURE:
        svm_node_mix_closure(node);
        break;
      case NODE_JUMP_IF_ZERO:
        if (stack_load_float(node.z) == 0.0f)
          offset +=  int(node.y);
        break;
      case NODE_JUMP_IF_ONE:
        if (stack_load_float(node.z) == 1.0f)
          offset +=  int(node.y);
        break;
      case NODE_GEOMETRY:
        svm_node_geometry(node.y, node.z);
        break;
      case NODE_CONVERT:
        svm_node_convert(node.y, node.z, node.w);
        break;
      case NODE_TEX_COORD:
        svm_node_tex_coord( path_flag, node, offset);
        break;
      case NODE_VALUE_F:
        svm_node_value_f(node.y, node.z);
        break;
      case NODE_VALUE_V:
        svm_node_value_v(node.y,offset);
        break;
      case NODE_ATTR:
        svm_node_attr(node);
        break;
      case NODE_HSV:
        svm_node_hsv(node, offset);
        break;
      case NODE_TEX_IMAGE:
        svm_node_tex_image(node, offset);
        break;
      case NODE_RGB_CURVES:
      case NODE_VECTOR_CURVES:
        svm_node_curves(node, offset);
        break;
      case NODE_VECTOR_ROTATE:
        svm_node_vector_rotate(node.y, node.z, node.w);
        break;
      case NODE_VECTOR_TRANSFORM:
        svm_node_vector_transform(node);
        break;
      case NODE_CLOSURE_SET_NORMAL:
        svm_node_set_normal(node.y, node.z);
        break;

  #if NODES_FEATURE(NODE_FEATURE_BUMP)

      case NODE_SET_DISPLACEMENT:
        svm_node_set_displacement(node.y);
        break;
      case NODE_DISPLACEMENT:
        svm_node_displacement(node);
        break;
      //case NODE_VECTOR_DISPLACEMENT:
      //  svm_node_vector_displacement(kg, sd, stack, node, &offset);
      //  break;

#    if NODES_FEATURE(NODE_FEATURE_BUMP_STATE)
      case NODE_ENTER_BUMP_EVAL:
        svm_node_enter_bump_eval(node.y);
        break;
      case NODE_LEAVE_BUMP_EVAL:
        svm_node_leave_bump_eval(node.y);
        break;
#    endif /* NODES_FEATURE(NODE_FEATURE_BUMP_STATE) */

      case NODE_GEOMETRY_BUMP_DX:
        svm_node_geometry_bump_dx(node.y, node.z);
        break;
      case NODE_GEOMETRY_BUMP_DY:
        svm_node_geometry_bump_dy( node.y, node.z);
        break;
      case NODE_SET_BUMP:
        svm_node_set_bump( node);
        break;
      case NODE_ATTR_BUMP_DX:
        svm_node_attr_bump_dx(node);
        break;
      case NODE_ATTR_BUMP_DY:
        svm_node_attr_bump_dy( node);
        break;
      case NODE_VERTEX_COLOR:
        svm_node_vertex_color(node.y, node.z, node.w);
        break;
      case NODE_VERTEX_COLOR_BUMP_DX:
        svm_node_vertex_color_bump_dx(node.y, node.z, node.w);
        break;
      case NODE_VERTEX_COLOR_BUMP_DY:
        svm_node_vertex_color_bump_dy(node.y, node.z, node.w);
        break;

      case NODE_SEPARATE_HSV:
        svm_node_separate_hsv(node.y, node.z, node.w, offset);
        break;
      case NODE_COMBINE_HSV:
        svm_node_combine_hsv(node.y, node.z, node.w, offset);
        break;
  #endif
#endif /* NODES_GROUP(NODE_GROUP_LEVEL_0) */

#if NODES_GROUP(NODE_GROUP_LEVEL_1)
      case NODE_RGB_RAMP:
        svm_node_rgb_ramp(node, offset);
        break;

      case NODE_MATH:
        svm_node_math(node.y, node.z, node.w, offset);
        break;
      case NODE_VECTOR_MATH:
        svm_node_vector_math( node.y, node.z, node.w, offset);
        break;

      case NODE_GAMMA:
        svm_node_gamma(node.y, node.z, node.w);
        break;
      
      case NODE_BRIGHTCONTRAST:
        svm_node_brightness(node.y, node.z, node.w);
        break;
      
      case NODE_OBJECT_INFO:
        svm_node_object_info(node.y, node.z);
        break;

      case NODE_PARTICLE_INFO:
        svm_node_particle_info(node.y, node.z);
        break;

#endif

#if NODES_GROUP(NODE_GROUP_LEVEL_2)
      case NODE_MAPPING:
        svm_node_mapping(node.y, node.z, node.w, offset);
        break;
      case NODE_TEX_NOISE:
        svm_node_tex_noise(node.y, node.z, node.w, offset);
        break;
      case NODE_TEX_VORONOI:
        svm_node_tex_voronoi(node.y, node.z, node.w, offset);
        break;
      case NODE_TEX_WAVE:
        svm_node_tex_wave(node, offset);
        break;
      case NODE_TEX_CHECKER:
        svm_node_tex_checker(node);
        break;
      case NODE_TEX_MUSGRAVE:
        svm_node_tex_musgrave(node.y, node.z, node.w, offset);
        break; 

      case NODE_TEX_WHITE_NOISE:
        svm_node_tex_white_noise(node.y, node.z, node.w,offset);
        break;

      case NODE_TEX_SKY:
        svm_node_tex_sky(node, offset);
        break;
      case NODE_TEX_ENVIRONMENT:
        svm_node_tex_environment(node);
        break;
#endif

#if NODES_GROUP(NODE_GROUP_LEVEL_3)
      case NODE_MAP_RANGE:
        svm_node_map_range(node.y, node.z, node.w, offset);
        break;
      case NODE_SEPARATE_VECTOR:
        svm_node_separate_vector( node.y, node.z, node.w);
        break;
      case NODE_COMBINE_VECTOR:
        svm_node_combine_vector(node.y, node.z, node.w);
        break;

      case NODE_MIX:
        svm_node_mix(node.y, node.z, node.w, offset);
        break;

      case NODE_TANGENT:
        svm_node_tangent(node);
        break;
      case NODE_NORMAL_MAP:
        svm_node_normal_map(node);
        break;
#endif



#if NODES_GROUP(999999999)



      case NODE_INVERT:
        svm_node_invert(sd, stack, node.y, node.z, node.w);
        break;



      case NODE_WIREFRAME:
        svm_node_wireframe(kg, sd, stack, node);
        break;
      case NODE_WAVELENGTH:
        svm_node_wavelength(kg, sd, stack, node.y, node.z);
        break;
      case NODE_BLACKBODY:
        svm_node_blackbody(kg, sd, stack, node.y, node.z);
        break;

      case NODE_CLAMP:
        svm_node_clamp(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
#  ifdef __SHADER_RAYTRACE__
      case NODE_BEVEL:
        svm_node_bevel(kg, sd, state, stack, node);
        break;
      case NODE_AMBIENT_OCCLUSION:
        svm_node_ao(kg, sd, state, stack, node);
        break;
#  endif /* __SHADER_RAYTRACE__ */
#endif   /* NODES_GROUP(NODE_GROUP_LEVEL_3) */

#if NODES_GROUP__
#if NODES_GROUP(NODE_GROUP_LEVEL_0)

      case NODE_TEX_IMAGE_BOX:
        svm_node_tex_image_box(kg, sd, stack, node);
        break;
#  if NODES_FEATURE(NODE_FEATURE_BUMP)


      case NODE_TEX_COORD_BUMP_DX:
        svm_node_tex_coord_bump_dx(kg, sd, path_flag, stack, node, &offset);
        break;
      case NODE_TEX_COORD_BUMP_DY:
        svm_node_tex_coord_bump_dy(kg, sd, path_flag, stack, node, &offset);
        break;

#  endif   /* NODES_FEATURE(NODE_FEATURE_BUMP) */

#endif /* NODES_GROUP(NODE_GROUP_LEVEL_0) */

#if NODES_GROUP(NODE_GROUP_LEVEL_1)
      case NODE_CLOSURE_HOLDOUT:
        svm_node_closure_holdout(sd, stack, node);
        break;
      case NODE_FRESNEL:
        svm_node_fresnel(sd, stack, node.y, node.z, node.w);
        break;
      case NODE_LAYER_WEIGHT:
        svm_node_layer_weight(sd, stack, node);
        break;
#  if NODES_FEATURE(NODE_FEATURE_VOLUME)
      case NODE_CLOSURE_VOLUME:
        svm_node_closure_volume(kg, sd, stack, node, type);
        break;
      case NODE_PRINCIPLED_VOLUME:
        svm_node_principled_volume(kg, sd, stack, node, type, path_flag, &offset);
        break;
#  endif /* NODES_FEATURE(NODE_FEATURE_VOLUME) */

      case NODE_LIGHT_PATH:
        svm_node_light_path(sd, state, stack, node.y, node.z, path_flag);
        break;

#  if defined(__HAIR__) && NODES_FEATURE(NODE_FEATURE_HAIR)
      case NODE_HAIR_INFO:
        svm_node_hair_info(kg, sd, stack, node.y, node.z);
        break;
#  endif /* NODES_FEATURE(NODE_FEATURE_HAIR) */
#endif   /* NODES_GROUP(NODE_GROUP_LEVEL_1) */

#if NODES_GROUP(NODE_GROUP_LEVEL_2)
      case NODE_TEXTURE_MAPPING:
        svm_node_texture_mapping(kg, sd, stack, node.y, node.z, &offset);
        break;
      case NODE_MAPPING:
        svm_node_mapping(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_MIN_MAX:
        svm_node_min_max(kg, sd, stack, node.y, node.z, &offset);
        break;
      case NODE_CAMERA:
        svm_node_camera(kg, sd, stack, node.y, node.z, node.w);
        break;

      case NODE_TEX_GRADIENT:
        svm_node_tex_gradient(sd, stack, node);
        break;


      case NODE_TEX_MAGIC:
        svm_node_tex_magic(kg, sd, stack, node, &offset);
        break;

      case NODE_TEX_BRICK:
        svm_node_tex_brick(kg, sd, stack, node, &offset);
        break;

      case NODE_NORMAL:
        svm_node_normal(kg, sd, stack, node.y, node.z, node.w, &offset);
        break;
      case NODE_LIGHT_FALLOFF:
        svm_node_light_falloff(sd, stack, node);
        break;
      case NODE_IES:
        svm_node_ies(kg, sd, stack, node, &offset);
        break;
#endif /* NODES_GROUP(NODE_GROUP_LEVEL_2) */



#if NODES_GROUP(NODE_GROUP_LEVEL_4)
#  if NODES_FEATURE(NODE_FEATURE_VOLUME)
      case NODE_TEX_VOXEL:
        svm_node_tex_voxel(kg, sd, stack, node, &offset);
        break;
#  endif /* NODES_FEATURE(NODE_FEATURE_VOLUME) */
      case NODE_AOV_START:
        if (!svm_node_aov_check(state, buffer)) {
          return;
        }
        break;
      case NODE_AOV_COLOR:
        svm_node_aov_color(kg, sd, stack, node, buffer);
        break;
      case NODE_AOV_VALUE:
        svm_node_aov_value(kg, sd, stack, node, buffer);
        break;
#endif /* NODES_GROUP(NODE_GROUP_LEVEL_4) */
#endif

      default:
        
        return;
    }
  }




}


CCL_NAMESPACE_END
#endif

#endif


