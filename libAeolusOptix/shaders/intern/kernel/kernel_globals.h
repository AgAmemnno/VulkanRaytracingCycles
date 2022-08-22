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

#ifndef __KERNEL_GLOBALS_H__
#define __KERNEL_GLOBALS_H__

#ifndef __KERNEL_VULKAN__
#include "kernel/kernel_profiling.h"
#endif

#ifdef __KERNEL_CPU__
#  include "util/util_map.h"
#  include "util/util_vector.h"
#endif

#ifdef __KERNEL_OPENCL__
#  include "util/util_atomic.h"
#endif

CCL_NAMESPACE_BEGIN




/* On the CPU, we pass along the struct KernelGlobals to nearly everywhere in
 * the kernel, to access constant data. These are all stored as "textures", but
 * these are really just standard arrays. We can't use actually globals because
 * multiple renders may be running inside the same process. */

#ifdef __KERNEL_CPU__

#  ifdef __OSL__
struct OSLGlobals;
struct OSLThreadData;
struct OSLShadingSystem;
#  endif

typedef unordered_map<float, float> CoverageMap;

struct Intersection;
struct VolumeStep;

typedef struct KernelGlobals {
#  define KERNEL_TEX(type, name) texture<type> name;
#  include "kernel/kernel_textures.h"

  KernelData __data;

#  ifdef __OSL__
  /* On the CPU, we also have the OSL globals here. Most data structures are shared
   * with SVM, the difference is in the shaders and object/mesh attributes. */
  OSLGlobals *osl;
  OSLShadingSystem *osl_ss;
  OSLThreadData *osl_tdata;
#  endif

  /* **** Run-time data ****  */

  /* Heap-allocated storage for transparent shadows intersections. */
  Intersection *transparent_shadow_intersections;

  /* Storage for decoupled volume steps. */
  VolumeStep *decoupled_volume_steps[2];
  int decoupled_volume_steps_index;

  /* A buffer for storing per-pixel coverage for Cryptomatte. */
  CoverageMap *coverage_object;
  CoverageMap *coverage_material;
  CoverageMap *coverage_asset;

  /* split kernel */
  SplitData split_data;
  SplitParams split_param_data;

  int2 global_size;
  int2 global_id;

  ProfilingState profiler;
} KernelGlobals;

#endif /* __KERNEL_CPU__ */




#ifdef _KERNEL_VULKAN_






#define _VULKAN_SET_OFS 0
#undef _VOLUME_
//float4 *output;
//uint4 *input;


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




#ifdef PUSH_KERNEL_TEX
#extension GL_EXT_buffer_reference2 : enable
#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) buffer name##_ {\
  type data[];\
};
//#define LOOKUP

#include "kernel/kernel_textures.h.glsl"

#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer KernelTextures {
  #include "kernel/kernel_textures.h.glsl"
};

#define _DEFINE_KERNEL_TEX_ 1
layout(push_constant) uniform PushData {
  KernelTextures data_ptr;
} push;

#endif


#ifdef PUSH_POOL_SC
#extension GL_EXT_buffer_reference2 : enable
#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) buffer name##_ {\
  type data[];\
};

KERNEL_TEX(ShaderClosure,pool_sc)


#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer ShaderClosurePool {
    KERNEL_TEX(ShaderClosure,pool_sc)
};
layout(push_constant) uniform PushData {
  layout(offset=8) ShaderClosurePool  pool_ptr;
} push;

#endif


layout (set=SET_KERNEL,binding = 0) buffer KD { 
  KernelData kernel_data;
};

layout (set=SET_KERNEL,binding = 1) buffer KG { 
  KernelGlobals kg;
};


layout (set=SET_KERNEL,binding = 2) buffer Alloc { 
  uint counter[1024];
};


#define OutBuffer resultImageL
#ifdef SET0
#ifdef LAYOUT_OUT_IMAGE

layout (set = 0,binding = 0, rgba32f) uniform writeonly image2D resultImageL;
layout (set = 0,binding = 1, rgba32f) uniform writeonly image2D resultImageR;
ivec2 OutBuffer_Size = imageSize(resultImageL);

#else

#define format_rgba 4
#define out_format format_rgba

layout (set = 0,binding = 0) buffer OUTBUFFERL { 
  float resultImageL[];
};
layout (set = 0,binding = 1) buffer OUTBUFFERR { float resultImageR[];};
ivec2 OutBuffer_Size = ivec2(kernel_data.cam.width,kernel_data.cam.height);

#define OutBuffer1D(uv) ((int(uv.x) + int(uv.y)*OutBuffer_Size.x)*int(out_format))
void writeOutBuffer(ivec2 uv,vec4 v){
        int idx = OutBuffer1D(uv);
          OutBuffer[idx]   = v.x;
          OutBuffer[idx+1] = v.y;
          OutBuffer[idx+2] = v.z;
          OutBuffer[idx+3] = v.w;
}
void writeOutBuffer(int idx,vec4 v){
          OutBuffer[idx]   = v.x;
          OutBuffer[idx+1] = v.y;
          OutBuffer[idx+2] = v.z;
          OutBuffer[idx+3] = v.w;
}
#endif
#endif //SET0
//#define OutBuffer2D(i) ivec2(int(i)% OutBuffer_Size.x ,int(i)/OutBuffer_Size.x)




/*
layout(binding = 0, set = 0 + _VULKAN_SET_OFS, rgba32ui) uniform image2D input;
layout(binding = 1, set = 0 + _VULKAN_SET_OFS, rgba32f)  uniform image2D output;

layout(binding = 0, set = 1 + _VULKAN_SET_OFS, scalar) buffer WorkTile  tile;
layout(binding = 1, set = 1 + _VULKAN_SET_OFS, scalar) buffer KernelData data;
layout(binding = 2, set = 1 + _VULKAN_SET_OFS, scalar) buffer ShaderParams shader;
layout(binding = 3, set = 1 + _VULKAN_SET_OFS, scalar) buffer KernelGlobals kg;

layout(binding = 1, set = 1 , scalar) buffer MatColorBufferObject { WaveFrontMaterial m[]; } materials[];
layout(binding = 2, set = 1 , scalar) buffer ScnDesc { sceneDesc i[]; } scnDesc;
///layout(binding = 3, set = 1) uniform sampler2D textureSamplers[];
layout(binding = 4, set = 1 )  buffer MatIndexColorBuffer { int i[]; } matIndex[];
layout(binding = 5, set = 1 , scalar) buffer Vertices { Vertex v[]; } vertices[];
layout(binding = 6, set = 1 ) buffer Indices { uint i[]; } indices[];

#  define KERNEL_TEX(type, name) const type *name;
#  include "kernel/kernel_textures.h"

 struct KernelParams {
  WorkTile tile;
  KernelData data;
  ShaderParams shader;
} ;

*/



#endif


#ifdef __KERNEL_OPTIX__

typedef struct ShaderParams {
  uint4 *input;
  float4 *output;
  int type;
  int filter;
  int sx;
  int offset;
  int sample;
} ShaderParams;

typedef struct KernelParams {
  WorkTile tile;
  KernelData data;
  ShaderParams shader;
#  define KERNEL_TEX(type, name) const type *name;
#  include "kernel/kernel_textures.h"
} KernelParams;

typedef struct KernelGlobals {
#  ifdef __VOLUME__
  VolumeState volume_state;
#  endif
  Intersection hits_stack[64];
} KernelGlobals;

extern "C" __constant__ KernelParams __params;

#else /* __KERNEL_OPTIX__ */

/* For CUDA, constant memory textures must be globals, so we can't put them
 * into a struct. As a result we don't actually use this struct and use actual
 * globals and simply pass along a NULL pointer everywhere, which we hope gets
 * optimized out. */

#  ifdef __KERNEL_CUDA__

__constant__ KernelData __data;
typedef struct KernelGlobals {
  /* NOTE: Keep the size in sync with SHADOW_STACK_MAX_HITS. */
  Intersection hits_stack[64];
} KernelGlobals;

#    define KERNEL_TEX(type, name) const __constant__ __device__ type *name;
#    include "kernel/kernel_textures.h"

#  endif /* __KERNEL_CUDA__ */

#endif /* __KERNEL_OPTIX__ */

/* OpenCL */

#ifdef __KERNEL_OPENCL__

#  define KERNEL_TEX(type, name) typedef type name##_t;
#  include "kernel/kernel_textures.h"

typedef ccl_addr_space struct KernelGlobals {
  ccl_constant KernelData *data;
  ccl_global char *buffers[8];

#  define KERNEL_TEX(type, name) TextureInfo name;
#  include "kernel/kernel_textures.h"

#  ifdef __SPLIT_KERNEL__
  SplitData split_data;
  SplitParams split_param_data;
#  endif
} KernelGlobals;

#  define KERNEL_BUFFER_PARAMS \
    ccl_global char *buffer0, ccl_global char *buffer1, ccl_global char *buffer2, \
        ccl_global char *buffer3, ccl_global char *buffer4, ccl_global char *buffer5, \
        ccl_global char *buffer6, ccl_global char *buffer7

#  define KERNEL_BUFFER_ARGS buffer0, buffer1, buffer2, buffer3, buffer4, buffer5, buffer6, buffer7

ccl_device_inline void kernel_set_buffer_pointers(KernelGlobals *kg, KERNEL_BUFFER_PARAMS)
{
#  ifdef __SPLIT_KERNEL__
  if (ccl_local_id(0) + ccl_local_id(1) == 0)
#  endif
  {
    kg->buffers[0] = buffer0;
    kg->buffers[1] = buffer1;
    kg->buffers[2] = buffer2;
    kg->buffers[3] = buffer3;
    kg->buffers[4] = buffer4;
    kg->buffers[5] = buffer5;
    kg->buffers[6] = buffer6;
    kg->buffers[7] = buffer7;
  }

#  ifdef __SPLIT_KERNEL__
  ccl_barrier(CCL_LOCAL_MEM_FENCE);
#  endif
}

ccl_device_inline void kernel_set_buffer_info(KernelGlobals *kg)
{
#  ifdef __SPLIT_KERNEL__
  if (ccl_local_id(0) + ccl_local_id(1) == 0)
#  endif
  {
    ccl_global TextureInfo *info = (ccl_global TextureInfo *)kg->buffers[0];

#  define KERNEL_TEX(type, name) kg->name = *(info++);
#  include "kernel/kernel_textures.h"
  }

#  ifdef __SPLIT_KERNEL__
  ccl_barrier(CCL_LOCAL_MEM_FENCE);
#  endif
}

#endif /* __KERNEL_OPENCL__ */

/* Interpolated lookup table access */
#ifdef LOOKUP
ccl_device float lookup_table_read(KernelGlobals kg, float x, int offset, int size)
{
  x = saturate(x) * (size - 1);

  int index = min(float_to_int(x), size - 1);
  int nindex = min(index + 1, size - 1);
  float t = x - index;

  float data0 = kernel_tex_fetch(__lookup_table, index + offset);
  if (t == 0.0f)
    return data0;

  float data1 = kernel_tex_fetch(__lookup_table, nindex + offset);
  return (1.0f - t) * data0 + t * data1;
}

ccl_device float lookup_table_read_2D(
    KernelGlobals kg, float x, float y, int offset, int xsize, int ysize)
{
  y = saturate(y) * (ysize - 1);

  int index = min(float_to_int(y), ysize - 1);
  int nindex = min(index + 1, ysize - 1);
  float t = y - index;

  float data0 = lookup_table_read(kg, x, offset + xsize * index, xsize);
  if (t == 0.0f)
    return data0;

  float data1 = lookup_table_read(kg, x, offset + xsize * nindex, xsize);
  return (1.0f - t) * data0 + t * data1;
}

CCL_NAMESPACE_END
#endif
#endif /* __KERNEL_GLOBALS_H__ */
