/*
 * Copyright 2011-2013 Blender Foundation
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

/* Constant Globals */

#ifndef _KERNEL_GLOBALS_H_
#define _KERNEL_GLOBALS_H_

CCL_NAMESPACE_BEGIN

#ifdef _KERNEL_VULKAN_
#undef  _VOLUME_

 struct ShaderParams {
  int type;
  int filter_;
  int sx;
  int offset;
  int sample_;
} ;

 struct KernelGlobals {
#  ifdef _VOLUME_
  VolumeState volume_state;
#  endif
  Intersection hits_stack[64];
} ;

#  define PROFILING_INIT(kg, event)
#  define PROFILING_EVENT(event)
#  define PROFILING_SHADER(shader)
#  define PROFILING_OBJECT(object)
#define NULL 0


#ifdef NO_READ_ONLY
#define READ_ONLY 
#else 
#define READ_ONLY readonly
#endif


#ifdef PUSH_KERNEL_TEX

#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) READ_ONLY buffer name##_ {\
  type data[];\
};
//#define LOOKUP

#include "kernel/kernel_textures.h.glsl"


#ifdef PUSH_POOL_SC
  #undef PUSH_POOL_SC
  layout(buffer_reference, scalar, buffer_reference_align = 8) buffer ShaderClosurePool {
      pool_sc_ pool_sc;
  };
  #define PUSH_POOL
  #define SC(i)    push.pool_ptr.pool_sc.data[i]
  #ifdef ENABLE_PROFI 
  #define PROFI(i) push.pool_ptr.pool_sc.data[i + PROFI_OFFSET]
  #endif
#endif


#ifdef PUSH_POOL_IS
  #undef PUSH_POOL_IS
  layout(buffer_reference, scalar, buffer_reference_align = 8) buffer IntersectionPool {
      pool_is_ pool_is;
  };
  #define PUSH_POOL_IS_DEF
  #define IS(i)    push.pool_ptr2.pool_is.data[i]

#endif

#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer KernelTextures {
  #include "kernel/kernel_textures.h.glsl"
};



#define _DEFINE_KERNEL_TEX_ 1
layout(push_constant) uniform PushData {
  KernelTextures     data_ptr;
  #ifdef PUSH_POOL
    layout(offset=8) ShaderClosurePool  pool_ptr;
  #endif
  #ifdef PUSH_POOL_IS_DEF
    layout(offset=16) IntersectionPool  pool_ptr2;
  #endif
} push;


#elif defined(PUSH_POOL_SC)

#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) buffer name##_ {\
  type data[];\
};

KERNEL_TEX(ShaderClosure,pool_sc)
#undef KERNEL_TEX

#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer ShaderClosurePool {
    KERNEL_TEX(ShaderClosure,pool_sc)
};
#undef KERNEL_TEX
layout(push_constant) uniform PushData2 {
  layout(offset=8) ShaderClosurePool  pool_ptr;
} push2;
#define SC(i)    push2.pool_ptr.pool_sc.data[i]

#ifdef ENABLE_PROFI 
#define PROFI(i) push2.pool_ptr.pool_sc.data[i + PROFI_OFFSET]
#endif



#elif defined(PUSH_POOL_IS)

#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) buffer name##_ {\
  type data[];\
};

KERNEL_TEX(Intersection,pool_is)
#undef KERNEL_TEX

#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer IntersectionPool {
    KERNEL_TEX(Intersection,pool_is)
};
#undef KERNEL_TEX

layout(push_constant) uniform PushData3 {
  layout(offset=16) IntersectionPool  pool2_ptr;
} push3;
#define IS(i)    push3.pool2_ptr.pool_is.data[i]


#endif


#ifdef SET_AS
layout(binding = 0, set =SET_AS) uniform accelerationStructureNV topLevelAS;
#endif

#ifdef SET_WRITE_PASSES
layout(binding = 1, set =SET_AS, rgba8) uniform image2D image;
#define kernel_write_pass_float4_launchID(val)  {\
  ivec2 dim = imageSize(image);\
  imageStore(image, ivec2(gl_LaunchIDNV.x,dim.y - gl_LaunchIDNV.y), val);\
}
#define kernel_write_pass_float4_launchID_atomic(val) 
#define buffer_ofs_null 0
#endif


#ifdef SET_KERNEL_PROF
#define MAX_HIT 15
#define STAT_BUF_MAX 64
struct KernelGlobals_PROF {
  uvec2    pixel;
	float3   f3[STAT_BUF_MAX * MAX_HIT];
	float    f1[STAT_BUF_MAX * MAX_HIT];
	uint     u1[STAT_BUF_MAX * MAX_HIT];
};
layout (set = SET_KERNEL_PROF,binding = 1) buffer KG { 
  KernelGlobals_PROF kg;
};
#include "kernel/prof/stat_maps.glsl"
layout (set=SET_KERNEL_PROF,binding = 2) buffer Alloc { 
  int counter[1024];
};

#define  SC_SIZE  144
#define  SC_UNIT_MAX  64
#define  SG_SIZE 32
#define  SG_BLOCK_MAX 786
#define  SC_BLOCK_MAX SG_SIZE*SC_UNIT_MAX
#define  ALLOC_COUNTER   counter[SG_BLOCK_MAX]
#define  ALLOC_LEFT      counter[SG_BLOCK_MAX+1]
#define  blockID(idx)    counter[idx]

#endif




#ifdef SET_KERNEL

layout (set=SET_KERNEL,binding = 0) buffer KD { 
  KernelData kernel_data;
};

#endif


#ifdef SET_SAMPLERS
#extension GL_EXT_nonuniform_qualifier : require
#extension GL_EXT_shader_16bit_storage : enable
#extension GL_EXT_shader_explicit_arithmetic_types : enable
#extension GL_EXT_scalar_block_layout : enable
/*
#extension GL_ARB_sparse_texture2 : enable
#extension GL_ARB_sparse_texture_clamp : enable
#extension GL_AMD_texture_gather_bias_lod : enable
#extension GL_AMD_shader_fragment_mask : enable
#extension GL_NV_shader_texture_footprint : enable
#extension GL_EXT_samplerless_texture_functions : enable  // texelFetch with *texture
#define DIT_GL_NV_shader_texture_footprint 1
*/
layout(set=SET_SAMPLERS, binding=0) uniform sampler2D _tex_[];
#endif


#ifdef SET_TEXTURES
#extension GL_EXT_nonuniform_qualifier : require
#extension GL_EXT_shader_16bit_storage : enable
#extension GL_EXT_shader_explicit_arithmetic_types : enable
#extension GL_EXT_scalar_block_layout : enable
layout(set=SET_TEXTURES, binding=0) uniform texture2D _tex_[];
layout(set=SET_TEXTURES, binding=1) uniform sampler   _samp_[];

#endif

#define SET_BG(_set,inpu,outpu)\
layout (set=_set,binding = 0) buffer BG_OUT{ \
  float4  bg##outpu[];\
};

//layout (set=_set,binding = 0) buffer BG_IN { 
//  uint4   bg##inpu[];
//};

#ifdef LOOKUP
ccl_device float lookup_table_read(float x, int offset, int size)
{
  x = saturate(x) * (size - 1);

  int index = min(float_to_int(x), size - 1);
  int nindex = min(index + 1, size - 1);
  float t = x - index;

  float data0 = kernel_tex_fetch(_lookup_table, index + offset);
  if (t == 0.0f)
    return data0;

  float data1 = kernel_tex_fetch(_lookup_table, nindex + offset);
  return (1.0f - t) * data0 + t * data1;
}

ccl_device float lookup_table_read_2D(
   float x, float y, int offset, int xsize, int ysize)
{
  y = saturate(y) * (ysize - 1);

  int index = min(float_to_int(y), ysize - 1);
  int nindex = min(index + 1, ysize - 1);
  float t = y - index;

  float data0 = lookup_table_read( x, offset + xsize * index, xsize);
  if (t == 0.0f)
    return data0;

  float data1 = lookup_table_read( x, offset + xsize * nindex, xsize);
  return (1.0f - t) * data0 + t * data1;
}

CCL_NAMESPACE_END
#endif


#endif   /*_KERNEL_VULKAN_*/


#endif /* _KERNEL_GLOBALS_H_ */
