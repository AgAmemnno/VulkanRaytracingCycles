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

#ifndef _KERNEL_TYPES_H_
#define _KERNEL_TYPES_H_

#if !defined(_KERNEL_GPU_) && defined(WITH_EMBREE)
#  include <embree3/rtcore.h>
#  include <embree3/rtcore_scene.h>
#  define _EMBREE_
#endif

#ifdef _KERNEL_VULKAN_
#define PUSH_POOL_SIZE  (512 * 1024 * 1024)
#define POOL_SC_SIZE  (144)
#define POOL_IS_SIZE  (24)
// 64(MAX_CLOSURE)*32( warps max )*32(subgroup max)*34( sm max) = 2228224
#define MAX_ALLOCATE 2228224

#ifdef ENABLE_PROFI
int PROFI_IDX;
struct PROF_BLOCK{
    float d[36];
};
#define PROFI_OFFSET MAX_ALLOCATE
#define PROFI_MAX_SIZE 1024*1024
#define PROFI_ATOMIC   1023

#define PROFI_HIT_IDX(x,y,z,w) PROFI(PROFI_IDX).weight    = vec4(x,y,z,w);
#define PROFI_LAMP_TF(b1,b2,b3) PROFI(PROFI_IDX).N    = vec4(b1,b2,b3,0.);


#define PROFI_DATA_012(x,y,z) {PROFI(PROFI_IDX).data[0]   = float(x);PROFI(PROFI_IDX).data[1]   = float(y);PROFI(PROFI_IDX).data[2]   = float(z);}
#define PROFI_DATA_345(x,y,z) {PROFI(PROFI_IDX).data[3]   = float(x);PROFI(PROFI_IDX).data[4]   = float(y);PROFI(PROFI_IDX).data[5]   = float(z);}
#define PROFI_DATA_678(x,y,z) {PROFI(PROFI_IDX).data[6]   = float(x);PROFI(PROFI_IDX).data[7]   = float(y);PROFI(PROFI_IDX).data[8]   = float(z);}
#define PROFI_DATA_911(x,y,z) {PROFI(PROFI_IDX).data[9]   = float(x);PROFI(PROFI_IDX).data[10]   = float(y);PROFI(PROFI_IDX).data[11]   = float(z);}

#define PROFI_LI_EVAL(l)    {PROFI(PROFI_IDX).data[12]   =  l.x;PROFI(PROFI_IDX).data[13]   =  l.y;PROFI(PROFI_IDX).data[14]   =  l.z;}
#define PROFI_LI_SD_FLAG(x,y)   { PROFI(PROFI_IDX).data[15]   = float(x); PROFI(PROFI_IDX).data[16]   = float(y);}
#define PROFI_BSDF_ALLOC(x) PROFI(PROFI_IDX).data[17]   = float(x);

#define PROFI_ATOMIC_567(x,y,z) {\
    atomicAdd(counter[PROFI_ATOMIC-7], x);\
    atomicAdd(counter[PROFI_ATOMIC-6], y);\
    atomicAdd(counter[PROFI_ATOMIC-5], z);}
#endif

#endif



#include "kernel/kernel_math.h.glsl"
#include "kernel/svm/svm_types.h.glsl"

#ifndef _KERNEL_VULKAN_
#include "util/util_static_assert.h"
#endif

#ifndef _KERNEL_GPU_
#  define _KERNEL_CPU_
#endif


/* TODO(sergey): This is only to make it possible to include this header
 * from outside of the kernel. but this could be done somewhat cleaner?
 */
#ifndef ccl_addr_space
#  define ccl_addr_space
#endif

CCL_NAMESPACE_BEGIN

/* Constants */
#define OBJECT_MOTION_PASS_SIZE 2
#define FILTER_TABLE_SIZE 1024
#define RAMP_TABLE_SIZE 256
#define SHUTTER_TABLE_SIZE 256

#define BSSRDF_MIN_RADIUS 1e-8f
#define BSSRDF_MAX_HITS 4
#define BSSRDF_MAX_BOUNCES 256
#define LOCAL_MAX_HITS 4

#define VOLUME_BOUNDS_MAX 1024

#define BECKMANN_TABLE_SIZE 256

#define SHADER_NONE (~0)
#define OBJECT_NONE (~0)
#define PRIM_NONE (~0)
#define LAMP_NONE (~0)
#define ID_NONE (0.0f)

#define VOLUME_STACK_SIZE 32

/* Split kernel constants */
#define WORK_POOL_SIZE_GPU 64
#define WORK_POOL_SIZE_CPU 1
#ifdef _KERNEL_GPU_
#  define WORK_POOL_SIZE WORK_POOL_SIZE_GPU
#else
#  define WORK_POOL_SIZE WORK_POOL_SIZE_CPU
#endif

#define SHADER_SORT_BLOCK_SIZE 2048

#ifdef _KERNEL_OPENCL_
#  define SHADER_SORT_LOCAL_SIZE 64
#elif defined(_KERNEL_CUDA_) | defined(_KERNEL_VULKAN_) 
#  define SHADER_SORT_LOCAL_SIZE 32
#else
#  define SHADER_SORT_LOCAL_SIZE 1
#endif

/* Kernel features */
#define _SOBOL_
#define _DPDU_
#define _BACKGROUND_
#define _CAUSTICS_TRICKS_
#define _VISIBILITY_FLAG_
#define _RAY_DIFFERENTIALS_
#define _CAMERA_CLIPPING_
#define _INTERSECTION_REFINE_
#define _CLAMP_SAMPLE_
#define _PATCH_EVAL_
#define _SHADOW_TRICKS_
#define _DENOISING_FEATURES_
#define _SHADER_RAYTRACE_
#define _AO_
#define _PASSES_
#define _HAIR_

/* Without these we get an AO render, used by OpenCL preview kernel. */
#ifndef _KERNEL_AO_PREVIEW_
#  define _SVM_
#  define _EMISSION_
#  define _HOLDOUT_
#  define _MULTI_CLOSURE_
#  define _TRANSPARENT_SHADOWS_
#  define _BACKGROUND_MIS_
#  define _LAMP_MIS_
#  define _CAMERA_MOTION_
#  define _OBJECT_MOTION2_
#  define _BAKING_
#  define _PRINCIPLED_
#  define _SUBSURFACE_
#  define _VOLUME_
#  define _VOLUME_SCATTER_
#  define _CMJ_
#  define _SHADOW_RECORD_ALL_
#  define _BRANCHED_PATH_
#endif

/* Device specific features */
#ifdef _KERNEL_CPU_
#  ifdef WITH_OSL
#    define _OSL_
#  endif
#  define _VOLUME_DECOUPLED_
#  define _VOLUME_RECORD_ALL_
#endif /* _KERNEL_CPU_ */

#ifdef _KERNEL_CUDA_
#  ifdef _SPLIT_KERNEL_
#    undef _BRANCHED_PATH_
#  endif
#endif /* _KERNEL_CUDA_ */

#ifdef _KERNEL_OPTIX_
#  undef _BAKING_
#  undef _BRANCHED_PATH_
/* TODO(pmours): Cannot use optixTrace in non-inlined functions */
#  undef _SHADER_RAYTRACE_
#endif /* _KERNEL_OPTIX_ */

#ifdef _KERNEL_OPENCL_
#endif /* _KERNEL_OPENCL_ */

#ifdef _KERNEL_VULKAN_

#undef _HAIR_
#undef _VOLUME_
#undef _VOLUME_SCATTER_

#undef _OBJECT_MOTION_
#undef _DENOISING_FEATURES_
#define LOOKUP

#endif /* _KERNEL_VULKAN_ */


/* Scene-based selective features compilation. */
#ifdef _NO_CAMERA_MOTION_
#  undef _CAMERA_MOTION_
#endif
#ifdef _NO_OBJECT_MOTION_
#  undef _OBJECT_MOTION_
#endif
#ifdef _NO_HAIR_
#  undef _HAIR_
#endif
#ifdef _NO_VOLUME_
#  undef _VOLUME_
#  undef _VOLUME_SCATTER_
#endif
#ifdef _NO_SUBSURFACE_
#  undef _SUBSURFACE_
#endif
#ifdef _NO_BAKING_
#  undef _BAKING_
#endif
#ifdef _NO_BRANCHED_PATH_
#  undef _BRANCHED_PATH_
#endif
#ifdef _NO_PATCH_EVAL_
#  undef _PATCH_EVAL_
#endif
#ifdef _NO_TRANSPARENT_
#  undef _TRANSPARENT_SHADOWS_
#endif
#ifdef _NO_SHADOW_TRICKS_
#  undef _SHADOW_TRICKS_
#endif
#ifdef _NO_PRINCIPLED_
#  undef _PRINCIPLED_
#endif
#ifdef _NO_DENOISING_
#  undef _DENOISING_FEATURES_
#endif
#ifdef _NO_SHADER_RAYTRACE_
#  undef _SHADER_RAYTRACE_
#endif

/* Features that enable others */
#ifdef WITH_CYCLES_DEBUG
#  define _KERNEL_DEBUG_
#endif

#if defined(_SUBSURFACE_) || defined(_SHADER_RAYTRACE_)
#  define _BVH_LOCAL_
#endif

/* Shader Evaluation */

//modify => enum ShaderEvalType 
#define ShaderEvalType uint
#define SHADER_EVAL_DISPLACE uint(0)
#define SHADER_EVAL_BACKGROUND uint(1)
#define SHADER_EVAL_BAKE uint(2)
#define SHADER_EVAL_NORMAL uint(3)
#define SHADER_EVAL_UV uint(4)
#define SHADER_EVAL_ROUGHNESS uint(5)
#define SHADER_EVAL_DIFFUSE_COLOR uint(6)
#define SHADER_EVAL_GLOSSY_COLOR uint(7)
#define SHADER_EVAL_TRANSMISSION_COLOR uint(8)
#define SHADER_EVAL_EMISSION uint(9)
#define SHADER_EVAL_AOV_COLOR uint(10)
#define SHADER_EVAL_AOV_VALUE uint(11)
#define SHADER_EVAL_AO uint(12)
#define SHADER_EVAL_COMBINED uint(13)
#define SHADER_EVAL_SHADOW uint(14)
#define SHADER_EVAL_DIFFUSE uint(15)
#define SHADER_EVAL_GLOSSY uint(16)
#define SHADER_EVAL_TRANSMISSION uint(17)
#define SHADER_EVAL_ENVIRONMENT uint(18)
//modified ==> ShaderEvalType




/* Path Tracing
 * note we need to keep the u/v pairs at even values */

//modify => enum PathTraceDimension 
#define PathTraceDimension uint
#define PRNG_FILTER_U  uint(0)
#define PRNG_FILTER_V  uint(1)
#define PRNG_LENS_U  uint(2)
#define PRNG_LENS_V  uint(3)
#define PRNG_TIME  uint(4)
#define PRNG_UNUSED_0  uint(5)
#define PRNG_UNUSED_1  uint(6)
#define PRNG_UNUSED_2  uint(7)
#define PRNG_BASE_NUM  uint(10)
#define PRNG_BSDF_U  uint(0)
#define PRNG_BSDF_V  uint(1)
#define PRNG_LIGHT_U  uint(2)
#define PRNG_LIGHT_V  uint(3)
#define PRNG_LIGHT_TERMINATE  uint(4)
#define PRNG_TERMINATE  uint(5)
#define PRNG_PHASE_CHANNEL  uint(6)
#define PRNG_SCATTER_DISTANCE  uint(7)
#define PRNG_BOUNCE_NUM  uint(8)
#define PRNG_BEVEL_U  uint(6)
#define PRNG_BEVEL_V  uint(7)
//modified ==> PathTraceDimension




//modify => enum SamplingPattern 
#define SamplingPattern uint
#define SAMPLING_PATTERN_SOBOL  uint(0)
#define SAMPLING_PATTERN_CMJ  uint(1)
#define SAMPLING_PATTERN_PMJ  uint(2)
#define SAMPLING_NUM_PATTERNS uint(3)
//modified ==> SamplingPattern




/* these flags values correspond to raytypes in osl.cpp, so keep them in sync! */

//modify => enum PathRayFlag 
#define PathRayFlag uint
#define PATH_RAY_CAMERA  uint((1<<0))
#define PATH_RAY_REFLECT  uint((1<<1))
#define PATH_RAY_TRANSMIT  uint((1<<2))
#define PATH_RAY_DIFFUSE  uint((1<<3))
#define PATH_RAY_GLOSSY  uint((1<<4))
#define PATH_RAY_SINGULAR  uint((1<<5))
#define PATH_RAY_TRANSPARENT  uint((1<<6))
#define PATH_RAY_SHADOW_OPAQUE_NON_CATCHER  uint((1<<7))
#define PATH_RAY_SHADOW_OPAQUE_CATCHER  uint((1<<8))
#define PATH_RAY_SHADOW_OPAQUE  uint((PATH_RAY_SHADOW_OPAQUE_NON_CATCHER|PATH_RAY_SHADOW_OPAQUE_CATCHER))
#define PATH_RAY_SHADOW_TRANSPARENT_NON_CATCHER  uint((1<<9))
#define PATH_RAY_SHADOW_TRANSPARENT_CATCHER  uint((1<<10))
#define PATH_RAY_SHADOW_TRANSPARENT  uint((PATH_RAY_SHADOW_TRANSPARENT_NON_CATCHER|PATH_RAY_SHADOW_TRANSPARENT_CATCHER))
#define PATH_RAY_SHADOW_NON_CATCHER  uint((PATH_RAY_SHADOW_OPAQUE_NON_CATCHER|PATH_RAY_SHADOW_TRANSPARENT_NON_CATCHER))
#define PATH_RAY_SHADOW  uint((PATH_RAY_SHADOW_OPAQUE|PATH_RAY_SHADOW_TRANSPARENT))
#define PATH_RAY_UNUSED  uint((1<<11))
#define PATH_RAY_VOLUME_SCATTER  uint((1<<12))
#define PATH_RAY_NODE_UNALIGNED  uint((1<<13))
#define PATH_RAY_ALL_VISIBILITY  uint(((1<<14)-1))
#define PATH_RAY_MIS_SKIP  uint((1<<14))
#define PATH_RAY_DIFFUSE_ANCESTOR  uint((1<<15))
#define PATH_RAY_SINGLE_PASS_DONE  uint((1<<16))
#define PATH_RAY_SHADOW_CATCHER  uint((1<<17))
#define PATH_RAY_STORE_SHADOW_INFO  uint((1<<18))
#define PATH_RAY_TRANSPARENT_BACKGROUND  uint((1<<19))
#define PATH_RAY_TERMINATE_IMMEDIATE  uint((1<<20))
#define PATH_RAY_TERMINATE_AFTER_TRANSPARENT  uint((1<<21))
#define PATH_RAY_TERMINATE  uint((PATH_RAY_TERMINATE_IMMEDIATE|PATH_RAY_TERMINATE_AFTER_TRANSPARENT))
#define PATH_RAY_EMISSION  uint((1<<22))
//modified ==> PathRayFlag




/* Closure Label */

//modify => enum ClosureLabel 
#define ClosureLabel uint
#define LABEL_NONE  uint(0)
#define LABEL_TRANSMIT  uint(1)
#define LABEL_REFLECT  uint(2)
#define LABEL_DIFFUSE  uint(4)
#define LABEL_GLOSSY  uint(8)
#define LABEL_SINGULAR  uint(16)
#define LABEL_TRANSPARENT  uint(32)
#define LABEL_VOLUME_SCATTER  uint(64)
#define LABEL_TRANSMIT_TRANSPARENT  uint(128)
//modified ==> ClosureLabel




/* Render Passes */

#define PASS_NAME_JOIN(a, b) a##_##b
#define PASSMASK(pass) (1 << ((PASS_NAME_JOIN(PASS, pass)) % 32))

#define PASSMASK_COMPONENT(comp) \
  (PASSMASK(PASS_NAME_JOIN(comp, DIRECT)) | PASSMASK(PASS_NAME_JOIN(comp, INDIRECT)) | \
   PASSMASK(PASS_NAME_JOIN(comp, COLOR)))

//modify => enum PassType 
#define PassType uint
#define PASS_NONE  uint(0)
#define PASS_COMBINED  uint(1)
#define PASS_DEPTH uint(2)
#define PASS_NORMAL uint(3)
#define PASS_UV uint(4)
#define PASS_OBJECT_ID uint(5)
#define PASS_MATERIAL_ID uint(6)
#define PASS_MOTION uint(7)
#define PASS_MOTION_WEIGHT uint(8)
#define PASS_RENDER_TIME uint(9)
#define PASS_CRYPTOMATTE uint(10)
#define PASS_AOV_COLOR uint(11)
#define PASS_AOV_VALUE uint(12)
#define PASS_ADAPTIVE_AUX_BUFFER uint(13)
#define PASS_SAMPLE_COUNT uint(14)
#define PASS_CATEGORY_MAIN_END  uint(31)
#define PASS_MIST  uint(32)
#define PASS_EMISSION uint(33)
#define PASS_BACKGROUND uint(34)
#define PASS_AO uint(35)
#define PASS_SHADOW uint(36)
#define PASS_LIGHT uint(37)
#define PASS_DIFFUSE_DIRECT uint(38)
#define PASS_DIFFUSE_INDIRECT uint(39)
#define PASS_DIFFUSE_COLOR uint(40)
#define PASS_GLOSSY_DIRECT uint(41)
#define PASS_GLOSSY_INDIRECT uint(42)
#define PASS_GLOSSY_COLOR uint(43)
#define PASS_TRANSMISSION_DIRECT uint(44)
#define PASS_TRANSMISSION_INDIRECT uint(45)
#define PASS_TRANSMISSION_COLOR uint(46)
#define PASS_VOLUME_DIRECT  uint(50)
#define PASS_VOLUME_INDIRECT uint(51)
#define PASS_CATEGORY_LIGHT_END  uint(63)
#define PASS_BAKE_PRIMITIVE uint(64)
#define PASS_BAKE_DIFFERENTIAL uint(65)
#define PASS_CATEGORY_BAKE_END  uint(95)
//modified ==> PassType




#define PASS_ANY (~0)

//modify => enum CryptomatteType 
#define CryptomatteType uint
#define CRYPT_NONE  uint(0)
#define CRYPT_OBJECT  uint((1<<0))
#define CRYPT_MATERIAL  uint((1<<1))
#define CRYPT_ASSET  uint((1<<2))
#define CRYPT_ACCURATE  uint((1<<3))
//modified ==> CryptomatteType




//modify => enum DenoisingPassOffsets 
#define DenoisingPassOffsets uint
#define DENOISING_PASS_NORMAL  uint(0)
#define DENOISING_PASS_NORMAL_VAR  uint(3)
#define DENOISING_PASS_ALBEDO  uint(6)
#define DENOISING_PASS_ALBEDO_VAR  uint(9)
#define DENOISING_PASS_DEPTH  uint(12)
#define DENOISING_PASS_DEPTH_VAR  uint(13)
#define DENOISING_PASS_SHADOW_A  uint(14)
#define DENOISING_PASS_SHADOW_B  uint(17)
#define DENOISING_PASS_COLOR  uint(20)
#define DENOISING_PASS_COLOR_VAR  uint(23)
#define DENOISING_PASS_CLEAN  uint(26)
#define DENOISING_PASS_PREFILTERED_DEPTH  uint(0)
#define DENOISING_PASS_PREFILTERED_NORMAL  uint(1)
#define DENOISING_PASS_PREFILTERED_SHADOWING  uint(4)
#define DENOISING_PASS_PREFILTERED_ALBEDO  uint(5)
#define DENOISING_PASS_PREFILTERED_COLOR  uint(8)
#define DENOISING_PASS_PREFILTERED_VARIANCE  uint(11)
#define DENOISING_PASS_PREFILTERED_INTENSITY  uint(14)
#define DENOISING_PASS_SIZE_BASE  uint(26)
#define DENOISING_PASS_SIZE_CLEAN  uint(3)
#define DENOISING_PASS_SIZE_PREFILTERED  uint(15)
//modified ==> DenoisingPassOffsets




//modify => enum eBakePassFilter 
#define eBakePassFilter uint
#define BAKE_FILTER_NONE  uint(0)
#define BAKE_FILTER_DIRECT  uint((1<<0))
#define BAKE_FILTER_INDIRECT  uint((1<<1))
#define BAKE_FILTER_COLOR  uint((1<<2))
#define BAKE_FILTER_DIFFUSE  uint((1<<3))
#define BAKE_FILTER_GLOSSY  uint((1<<4))
#define BAKE_FILTER_TRANSMISSION  uint((1<<5))
#define BAKE_FILTER_EMISSION  uint((1<<6))
#define BAKE_FILTER_AO  uint((1<<7))
//modified ==> eBakePassFilter




//modify => enum BakePassFilterCombos 
#define BakePassFilterCombos uint
#define BAKE_FILTER_COMBINED  uint((BAKE_FILTER_DIRECT|BAKE_FILTER_INDIRECT|BAKE_FILTER_DIFFUSE|BAKE_FILTER_GLOSSY|BAKE_FILTER_TRANSMISSION|BAKE_FILTER_EMISSION|BAKE_FILTER_AO))
#define BAKE_FILTER_DIFFUSE_DIRECT  uint((BAKE_FILTER_DIRECT|BAKE_FILTER_DIFFUSE))
#define BAKE_FILTER_GLOSSY_DIRECT  uint((BAKE_FILTER_DIRECT|BAKE_FILTER_GLOSSY))
#define BAKE_FILTER_TRANSMISSION_DIRECT  uint((BAKE_FILTER_DIRECT|BAKE_FILTER_TRANSMISSION))
#define BAKE_FILTER_DIFFUSE_INDIRECT  uint((BAKE_FILTER_INDIRECT|BAKE_FILTER_DIFFUSE))
#define BAKE_FILTER_GLOSSY_INDIRECT  uint((BAKE_FILTER_INDIRECT|BAKE_FILTER_GLOSSY))
#define BAKE_FILTER_TRANSMISSION_INDIRECT  uint((BAKE_FILTER_INDIRECT|BAKE_FILTER_TRANSMISSION))
//modified ==> BakePassFilterCombos




//modify => enum DenoiseFlag 
#define DenoiseFlag uint
#define DENOISING_CLEAN_DIFFUSE_DIR  uint((1<<0))
#define DENOISING_CLEAN_DIFFUSE_IND  uint((1<<1))
#define DENOISING_CLEAN_GLOSSY_DIR  uint((1<<2))
#define DENOISING_CLEAN_GLOSSY_IND  uint((1<<3))
#define DENOISING_CLEAN_TRANSMISSION_DIR  uint((1<<4))
#define DENOISING_CLEAN_TRANSMISSION_IND  uint((1<<5))
#define DENOISING_CLEAN_ALL_PASSES  uint((1<<6)-1)
//modified ==> DenoiseFlag




#ifdef _KERNEL_DEBUG_
/* NOTE: This is a runtime-only struct, alignment is not
 * really important here.
 */
 struct DebugData {
  int num_bvh_traversed_nodes;
  int num_bvh_traversed_instances;
  int num_bvh_intersections;
  int num_ray_bounces;
} ;
#endif

 struct PathRadianceState {
#ifdef _PASSES_
  float3 diffuse;
  float3 glossy;
  float3 transmission;
  float3 volume;

  float3 direct;
#endif
} ;

 struct PathRadiance { 
#ifdef _PASSES_
  int use_light_pass;
#endif

  float transparent;
  float3 emission;
#ifdef _PASSES_
  float3 background;
  float3 ao;

  float3 indirect;
  float3 direct_emission;

  float3 color_diffuse;
  float3 color_glossy;
  float3 color_transmission;

  float3 direct_diffuse;
  float3 direct_glossy;
  float3 direct_transmission;
  float3 direct_volume;

  float3 indirect_diffuse;
  float3 indirect_glossy;
  float3 indirect_transmission;
  float3 indirect_volume;

  float4 shadow;
  float mist;
#endif 
 PathRadianceState state;

#ifdef _SHADOW_TRICKS_
  /* Total light reachable across the path, ignoring shadow blocked queries. */
  float3 path_total;
  /* Total light reachable across the path with shadow blocked queries
   * applied here.
   *
   * Dividing this figure by path_total will give estimate of shadow pass.
   */
  float3 path_total_shaded;

  /* Color of the background on which shadow is alpha-overed. */
  float3 shadow_background_color;

  /* Path radiance sum and throughput at the moment when ray hits shadow
   * catcher object.
   */
  float shadow_throughput;

  /* Accumulated transparency along the path after shadow catcher bounce. */
  float shadow_transparency;

  /* Indicate if any shadow catcher data is set. */
  int has_shadow_catcher;
#endif

#ifdef _DENOISING_FEATURES_
  float3 denoising_normal;
  float3 denoising_albedo;
  float denoising_depth;
#endif /* _DENOISING_FEATURES_ */

#ifdef _KERNEL_DEBUG_
  DebugData debug_data;
#endif /* _KERNEL_DEBUG_ */
 };


 struct BsdfEval {
#ifdef _PASSES_
  //int use_light_pass;
#endif

  float3 diffuse;
#ifdef _PASSES_
  float3 glossy;
  float3 transmission;
  float3 transparent;
  //float3 volume;
#endif
#ifdef _SHADOW_TRICKS_
  float3 sum_no_mis;
#endif
} ;

/* Shader Flag */

//modify => enum ShaderFlag 
#define ShaderFlag uint
#define SHADER_SMOOTH_NORMAL  uint((1<<31))
#define SHADER_CAST_SHADOW  uint((1<<30))
#define SHADER_AREA_LIGHT  uint((1<<29))
#define SHADER_USE_MIS  uint((1<<28))
#define SHADER_EXCLUDE_DIFFUSE  uint((1<<27))
#define SHADER_EXCLUDE_GLOSSY  uint((1<<26))
#define SHADER_EXCLUDE_TRANSMIT  uint((1<<25))
#define SHADER_EXCLUDE_CAMERA  uint((1<<24))
#define SHADER_EXCLUDE_SCATTER  uint((1<<23))
#define SHADER_EXCLUDE_ANY  uint((SHADER_EXCLUDE_DIFFUSE|SHADER_EXCLUDE_GLOSSY|SHADER_EXCLUDE_TRANSMIT|SHADER_EXCLUDE_CAMERA|SHADER_EXCLUDE_SCATTER))
#define SHADER_MASK  uint(~(SHADER_SMOOTH_NORMAL|SHADER_CAST_SHADOW|SHADER_AREA_LIGHT|SHADER_USE_MIS|SHADER_EXCLUDE_ANY))
//modified ==> ShaderFlag




/* Light Type */

//modify => enum LightType 
#define LightType uint
#define LIGHT_POINT uint(0)
#define LIGHT_DISTANT uint(1)
#define LIGHT_BACKGROUND uint(2)
#define LIGHT_AREA uint(3)
#define LIGHT_SPOT uint(4)
#define LIGHT_TRIANGLE uint(5)
//modified ==> LightType




/* Camera Type */

//modify => enum CameraType 
#define CameraType uint
#define CAMERA_PERSPECTIVE uint(0)
#define CAMERA_ORTHOGRAPHIC uint(1)
#define CAMERA_PANORAMA uint(2)
//modified ==> CameraType




/* Panorama Type */

//modify => enum PanoramaType 
#define PanoramaType uint
#define PANORAMA_EQUIRECTANGULAR  uint(0)
#define PANORAMA_FISHEYE_EQUIDISTANT  uint(1)
#define PANORAMA_FISHEYE_EQUISOLID  uint(2)
#define PANORAMA_MIRRORBALL  uint(3)
#define PANORAMA_NUM_TYPES uint(4)
//modified ==> PanoramaType




/* Differential */

 struct differential3 {
  float3 dx;
  float3 dy;
} ;

 struct differential {
  float dx;
  float dy;
} ;

/* Ray */

 struct Ray {
/* TODO(sergey): This is only needed because current AMD
 * compiler has hard time building the kernel with this
 * reshuffle. And at the same time reshuffle will cause
 * less optimal CPU code in certain places.
 *
 * We'll get rid of this nasty exception once AMD compiler
 * is fixed.
 */
/*
#ifndef _KERNEL_OPENCL_AMD_
  float3 P;   
  float3 D;   
  float t;    
  float time; 
#else
*/
  float t;    /* length of the ray */
  float time; /* time (for motion blur) */
  float3 P;   /* origin */
  float3 D;   /* direction */
//#endif

#ifdef _RAY_DIFFERENTIALS_
  differential3 dP;
  differential3 dD;
#endif
} ;

/* Intersection */

 struct Intersection {
#ifdef _EMBREE_
  float3 Ng;
#endif
  float t, u, v;
  int prim;
  int object;
  int type;

#ifdef _KERNEL_DEBUG_
  int num_traversed_nodes;
  int num_traversed_instances;
  int num_intersections;
#endif
} ;

 struct Intersection2 {

  float t, u, v;
  int prim;
  int object;
  int type;
  vec3 P;
};

/* Primitives */

//modify => enum PrimitiveType 
#define PrimitiveType uint
#define PRIMITIVE_NONE  uint(0)
#define PRIMITIVE_TRIANGLE  uint((1<<0))
#define PRIMITIVE_MOTION_TRIANGLE  uint((1<<1))
#define PRIMITIVE_CURVE_THICK  uint((1<<2))
#define PRIMITIVE_MOTION_CURVE_THICK  uint((1<<3))
#define PRIMITIVE_CURVE_RIBBON  uint((1<<4))
#define PRIMITIVE_MOTION_CURVE_RIBBON  uint((1<<5))
#define PRIMITIVE_LAMP  uint((1<<6))
#define PRIMITIVE_ALL_TRIANGLE  uint((PRIMITIVE_TRIANGLE|PRIMITIVE_MOTION_TRIANGLE))
#define PRIMITIVE_ALL_CURVE  uint((PRIMITIVE_CURVE_THICK|PRIMITIVE_MOTION_CURVE_THICK|PRIMITIVE_CURVE_RIBBON|PRIMITIVE_MOTION_CURVE_RIBBON))
#define PRIMITIVE_ALL_MOTION  uint((PRIMITIVE_MOTION_TRIANGLE|PRIMITIVE_MOTION_CURVE_THICK|PRIMITIVE_MOTION_CURVE_RIBBON))
#define PRIMITIVE_ALL  uint((PRIMITIVE_ALL_TRIANGLE|PRIMITIVE_ALL_CURVE))
#define PRIMITIVE_NUM_TOTAL  uint(6)
//modified ==> PrimitiveType




#define PRIMITIVE_PACK_SEGMENT(type, segment) ((segment << PRIMITIVE_NUM_TOTAL) | (type))
#define PRIMITIVE_UNPACK_SEGMENT(type) (type >> PRIMITIVE_NUM_TOTAL)

//modify => enum CurveShapeType 
#define CurveShapeType uint
#define CURVE_RIBBON  uint(0)
#define CURVE_THICK  uint(1)
#define CURVE_NUM_SHAPE_TYPES uint(2)
//modified ==> CurveShapeType




/* Attributes */

//modify => enum AttributePrimitive 
#define AttributePrimitive uint
#define ATTR_PRIM_GEOMETRY  uint(0)
#define ATTR_PRIM_SUBD uint(1)
#define ATTR_PRIM_TYPES uint(2)
//modified ==> AttributePrimitive




//modify => enum AttributeElement 
#define AttributeElement uint
#define ATTR_ELEMENT_NONE uint(0)
#define ATTR_ELEMENT_OBJECT uint(1)
#define ATTR_ELEMENT_MESH uint(2)
#define ATTR_ELEMENT_FACE uint(3)
#define ATTR_ELEMENT_VERTEX uint(4)
#define ATTR_ELEMENT_VERTEX_MOTION uint(5)
#define ATTR_ELEMENT_CORNER uint(6)
#define ATTR_ELEMENT_CORNER_BYTE uint(7)
#define ATTR_ELEMENT_CURVE uint(8)
#define ATTR_ELEMENT_CURVE_KEY uint(9)
#define ATTR_ELEMENT_CURVE_KEY_MOTION uint(10)
#define ATTR_ELEMENT_VOXEL uint(11)
//modified ==> AttributeElement




//modify => enum AttributeStandard 
#define AttributeStandard uint
#define ATTR_STD_NONE  uint(0)
#define ATTR_STD_VERTEX_NORMAL uint(1)
#define ATTR_STD_FACE_NORMAL uint(2)
#define ATTR_STD_UV uint(3)
#define ATTR_STD_UV_TANGENT uint(4)
#define ATTR_STD_UV_TANGENT_SIGN uint(5)
#define ATTR_STD_VERTEX_COLOR uint(6)
#define ATTR_STD_GENERATED uint(7)
#define ATTR_STD_GENERATED_TRANSFORM uint(8)
#define ATTR_STD_POSITION_UNDEFORMED uint(9)
#define ATTR_STD_POSITION_UNDISPLACED uint(10)
#define ATTR_STD_MOTION_VERTEX_POSITION uint(11)
#define ATTR_STD_MOTION_VERTEX_NORMAL uint(12)
#define ATTR_STD_PARTICLE uint(13)
#define ATTR_STD_CURVE_INTERCEPT uint(14)
#define ATTR_STD_CURVE_RANDOM uint(15)
#define ATTR_STD_PTEX_FACE_ID uint(16)
#define ATTR_STD_PTEX_UV uint(17)
#define ATTR_STD_VOLUME_DENSITY uint(18)
#define ATTR_STD_VOLUME_COLOR uint(19)
#define ATTR_STD_VOLUME_FLAME uint(20)
#define ATTR_STD_VOLUME_HEAT uint(21)
#define ATTR_STD_VOLUME_TEMPERATURE uint(22)
#define ATTR_STD_VOLUME_VELOCITY uint(23)
#define ATTR_STD_POINTINESS uint(24)
#define ATTR_STD_RANDOM_PER_ISLAND uint(25)
#define ATTR_STD_NUM uint(26)
#define ATTR_STD_NOT_FOUND  uint(~0)
//modified ==> AttributeStandard




//modify => enum AttributeFlag 
#define AttributeFlag uint
#define ATTR_FINAL_SIZE  uint((1<<0))
#define ATTR_SUBDIVIDED  uint((1<<1))
//modified ==> AttributeFlag




 struct AttributeDescriptor {
  AttributeElement element;
  NodeAttributeType type;
  uint flags; /* see enum AttributeFlag */
  int offset;
} ;

/* Closure data */
#define MAX_CLOSURE 64
/*
#ifdef _MULTI_CLOSURE_
#  ifdef _SPLIT_KERNEL_
#    define MAX_CLOSURE 1
#  else
#    ifndef _MAX_CLOSURE_
#      define MAX_CLOSURE 4
#    else
#      define MAX_CLOSURE _MAX_CLOSURE_
#    endif
#  endif
#else
#  define MAX_CLOSURE 1
#endif
*/


/* This 
 is the base class for all closures. The common members are
 * duplicated in all derived classes since we don't have C++ in the kernel
 * yet, and because it lets us lay out the members to minimize padding. The
 * weight member is located at the beginning of the struct for this reason.
 *
 * ShaderClosure has a fixed size, and any extra space must be allocated
 * with closure_alloc_extra().
 *
 * We pad the struct to align to 16 bytes. All shader closures are assumed
 * to fit in this struct size. CPU sizes are a bit larger because float3 is
 * padded to be 16 bytes, while it's only 12 bytes on the GPU. */

#define SHADER_CLOSURE_CAP 25
#define SHADER_CLOSURE_BASE \
  vec4 weight; \
  ClosureType type; \
  float sample_weight; \
  vec4 N;

 struct ccl_align(16) ShaderClosure
{
  SHADER_CLOSURE_BASE

#ifdef _KERNEL_CPU_
  float pad[2];
#endif
  int   next;
  float data[SHADER_CLOSURE_CAP];
};


#define SC_zeros(sc) {\
  sc.weight = vec4(0.);\
  sc.type   = 0;\
  sc.sample_weight = 0.f;\
  sc.N = vec4(0.);\
  sc.next = 0;\
  for(int _i_ =0;_i_<SHADER_CLOSURE_CAP;_i_++)sc.data[_i_] = 0.f;\
}



#ifndef OMIT_NULL_SC
ShaderClosure null_sc;
#define NULL_sc null_sc.weight.xyz = vec3(FLT_MIN);
#define isNULLsc(sc) (sc.weight.xyz == vec3(FLT_MIN));
#endif




bool eq_ShaderClosure(in ShaderClosure a,in ShaderClosure b){
   
  bool ret = 
  a.weight == b.weight &&
  a.type   == b.type   &&
  a.sample_weight == b.sample_weight &&
  a.N == b.N ;
  if(ret){
    for(int i =0;i<SHADER_CLOSURE_CAP;i++){
          if(a.data[i] != b.data[i])return false;
    }
  }
  return ret;
}




/* Shader Data
 *
 * Main shader state at a point on the surface or in a volume. All coordinates
 * are in world space.
 */

//modify => enum ShaderDataFlag 
#define ShaderDataFlag uint
#define SD_BACKFACING  uint((1<<0))
#define SD_EMISSION  uint((1<<1))
#define SD_BSDF  uint((1<<2))
#define SD_BSDF_HAS_EVAL  uint((1<<3))
#define SD_BSSRDF  uint((1<<4))
#define SD_HOLDOUT  uint((1<<5))
#define SD_EXTINCTION  uint((1<<6))
#define SD_SCATTER  uint((1<<7))
#define SD_TRANSPARENT  uint((1<<9))
#define SD_BSDF_NEEDS_LCG  uint((1<<10))
#define SD_CLOSURE_FLAGS  uint((SD_EMISSION|SD_BSDF|SD_BSDF_HAS_EVAL|SD_BSSRDF|SD_HOLDOUT|SD_EXTINCTION|SD_SCATTER|SD_BSDF_NEEDS_LCG))
#define SD_USE_MIS  uint((1<<16))
#define SD_HAS_TRANSPARENT_SHADOW  uint((1<<17))
#define SD_HAS_VOLUME  uint((1<<18))
#define SD_HAS_ONLY_VOLUME  uint((1<<19))
#define SD_HETEROGENEOUS_VOLUME  uint((1<<20))
#define SD_HAS_BSSRDF_BUMP  uint((1<<21))
#define SD_VOLUME_EQUIANGULAR  uint((1<<22))
#define SD_VOLUME_MIS  uint((1<<23))
#define SD_VOLUME_CUBIC  uint((1<<24))
#define SD_HAS_BUMP  uint((1<<25))
#define SD_HAS_DISPLACEMENT  uint((1<<26))
#define SD_HAS_CONSTANT_EMISSION  uint((1<<27))
#define SD_NEED_VOLUME_ATTRIBUTES  uint((1<<28))
#define SD_SHADER_FLAGS  uint((SD_USE_MIS|SD_HAS_TRANSPARENT_SHADOW|SD_HAS_VOLUME|SD_HAS_ONLY_VOLUME|SD_HETEROGENEOUS_VOLUME|SD_HAS_BSSRDF_BUMP|SD_VOLUME_EQUIANGULAR|SD_VOLUME_MIS|SD_VOLUME_CUBIC|SD_HAS_BUMP|SD_HAS_DISPLACEMENT|SD_HAS_CONSTANT_EMISSION|SD_NEED_VOLUME_ATTRIBUTES))
//modified ==> ShaderDataFlag




/* Object flags. */
//modify => enum ShaderDataObjectFlag 
#define ShaderDataObjectFlag uint
#define SD_OBJECT_HOLDOUT_MASK  uint((1<<0))
#define SD_OBJECT_MOTION  uint((1<<1))
#define SD_OBJECT_TRANSFORM_APPLIED  uint((1<<2))
#define SD_OBJECT_NEGATIVE_SCALE_APPLIED  uint((1<<3))
#define SD_OBJECT_HAS_VOLUME  uint((1<<4))
#define SD_OBJECT_INTERSECTS_VOLUME  uint((1<<5))
#define SD_OBJECT_HAS_VERTEX_MOTION  uint((1<<6))
#define SD_OBJECT_SHADOW_CATCHER  uint((1<<7))
#define SD_OBJECT_HAS_VOLUME_ATTRIBUTES  uint((1<<8))
#define SD_OBJECT_FLAGS  uint((SD_OBJECT_HOLDOUT_MASK|SD_OBJECT_MOTION|SD_OBJECT_TRANSFORM_APPLIED|SD_OBJECT_NEGATIVE_SCALE_APPLIED|SD_OBJECT_HAS_VOLUME|SD_OBJECT_INTERSECTS_VOLUME|SD_OBJECT_SHADOW_CATCHER|SD_OBJECT_HAS_VOLUME_ATTRIBUTES))
//modified ==> ShaderDataObjectFlag
/* Path State */

#ifdef _VOLUME_

 struct _VolumeStack { 
  int object;
  int shader;
 };
#endif


 struct PathState { 
  /* see enum PathRayFlag */
  int flag;

  /* random number generator state */
  uint rng_hash;       /* per pixel hash */
  int rng_offset;      /* dimension offset */



  int sample_rsv;          /* path sample number */
  int num_samples;     /* total number of times this path will be sampled */
  float branch_factor; /* number of branches in indirect paths */

  /* bounce counting */
  int bounce;
  int diffuse_bounce;
  int glossy_bounce;
  int transmission_bounce;
  int transparent_bounce;

#ifdef _DENOISING_FEATURES_
  float denoising_feature_weight;
  float3 denoising_feature_throughput;
#endif /* _DENOISING_FEATURES_ */

  /* multiple importance sampling */
  float min_ray_pdf; /* smallest bounce pdf over entire path up to now */
  float ray_pdf;     /* last bounce pdf */
#ifdef _LAMP_MIS_
  float ray_t; /* accumulated distance through transparent surfaces */
#endif

  /* volume rendering */
#ifdef _VOLUME_
  int volume_bounce;
  int volume_bounds_bounce;
  _VolumeStack volume_stack[VOLUME_STACK_SIZE];
#endif

 };



ccl_addr_space struct ShaderData
{
  /* position */
  float3 P;
  /* smooth normal for shading */
  float3 N;
  /* true geometric normal */
  float3 Ng;
  /* view/incoming direction */
  float3 I;
  /* shader id */
  int shader;
  /* booleans describing shader, see ShaderDataFlag */
  int flag;
  /* booleans describing object of the shader, see ShaderDataObjectFlag */
  int object_flag;

  /* primitive id if there is one, ~0 otherwise */
  int prim;

  /* combined type and curve segment for hair */
  int type;

  /* parametric coordinates
   * - barycentric weights for triangles */
  float u;
  float v;
  /* object id if there is one, ~0 otherwise */
  int object;
  /* lamp id if there is one, ~0 otherwise */
  int lamp;

  /* motion blur sample time */
  float time;

  /* length of the ray being shaded */
  float ray_length;

#ifdef _RAY_DIFFERENTIALS_
  /* differential of P. these are orthogonal to Ng, not N */
  differential3 dP;
  /* differential of I */
  differential3 dI;
  /* differential of u, v */
  differential du;
  differential dv;
#endif
#ifdef _DPDU_
  /* differential of P w.r.t. parametric coordinates. note that dPdu is
   * not readily suitable as a tangent for shading on triangles. */
  float3 dPdu;
  float3 dPdv;
#endif


  /* ray start position, only set for backgrounds */
  float3 ray_P;
  differential3 ray_dP;

#ifdef _OSL_ 
 KernelGlobals *osl_globals;
  struct PathState *osl_path_state;
#endif

  /* LCG state for closures that require additional random numbers. */
  uint lcg_state;

  /* Closure data, we store a fixed array of closures */
  int num_closure;
  int num_closure_left;
  float randb_closure;
  float3 svm_closure_weight;

#ifdef _OBJECT_MOTION2_
  /* object <-> world space transformations, cached to avoid
   * re-interpolating them constantly for shading */
  Transform ob_tfm;
  Transform ob_itfm;
  /* geometry id */
  int         geometry;
#endif

  /* Closure weights summed directly, so we can evaluate
   * emission and shadow transparency with MAX_CLOSURE 0. */
  float3 closure_emission_background;
  float3 closure_transparent_extinction;

  /* At the end so we can adjust size in ShaderDataTinyStorage. */
  //ShaderClosure closure[MAX_CLOSURE];
  int      atomic_offset;
  int      alloc_offset;


};



/* ShaderDataTinyStorage needs the same alignment as ShaderData, or else
 * the pointer cast in AS_SHADER_DATA invokes undefined behavior. */
/*  
 struct ccl_align(16) ShaderDataTinyStorage
{
  char pad[sizeof(ShaderData) - sizeof(ShaderClosure) * MAX_CLOSURE];
};
#define AS_SHADER_DATA(shader_data_tiny_storage) ((ShaderData *)shader_data_tiny_storage)
*/
ccl_addr_space struct ShaderDataTinyStorage
{
  /* position */
  float3 P;
  /* smooth normal for shading */
  float3 N;
  /* true geometric normal */
  float3 Ng;
  /* view/incoming direction */
  float3 I;
  /* shader id */
  int shader;
  /* booleans describing shader, see ShaderDataFlag */
  int flag;
  /* booleans describing object of the shader, see ShaderDataObjectFlag */
  int object_flag;

  /* primitive id if there is one, ~0 otherwise */
  int prim;

  /* combined type and curve segment for hair */
  int type;

  /* parametric coordinates
   * - barycentric weights for triangles */
  float u;
  float v;
  /* object id if there is one, ~0 otherwise */
  int object;
  /* lamp id if there is one, ~0 otherwise */
  int lamp;

  /* motion blur sample time */
  float time;

  /* length of the ray being shaded */
  float ray_length;

#ifdef _RAY_DIFFERENTIALS_
  /* differential of P. these are orthogonal to Ng, not N */
  differential3 dP;
  /* differential of I */
  differential3 dI;
  /* differential of u, v */
  differential du;
  differential dv;
#endif
#ifdef _DPDU_
  /* differential of P w.r.t. parametric coordinates. note that dPdu is
   * not readily suitable as a tangent for shading on triangles. */
  float3 dPdu;
  float3 dPdv;
#endif

#ifdef _OBJECT_MOTION_
  /* object <-> world space transformations, cached to avoid
   * re-interpolating them constantly for shading */
  Transform ob_tfm;
  Transform ob_itfm;
#endif

  /* ray start position, only set for backgrounds */
  float3 ray_P;
  differential3 ray_dP;

#ifdef _OSL_ 
 KernelGlobals *osl_globals;
  struct PathState *osl_path_state;
#endif

  /* LCG state for closures that require additional random numbers. */
  uint lcg_state;

  /* Closure data, we store a fixed array of closures */
  int num_closure;
  int num_closure_left;
  float randb_closure;
  float3 svm_closure_weight;

  /* Closure weights summed directly, so we can evaluate
   * emission and shadow transparency with MAX_CLOSURE 0. */
  float3 closure_emission_background;
  float3 closure_transparent_extinction;


  int      atomic_offset;
  int      alloc_offset;
};


struct args_sd{

float3 P;
float3 N; 
float3 Ng;
float3 I;
int flag;
int type;
int object;
int        num_closure;
int      atomic_offset;
float             time; 
float       ray_length;
int       alloc_offset;
float             pad0;
uint         lcg_state;
float             pad1;

differential3       dI;

};


#ifdef _VOLUME_
 struct VolumeState { 
#  ifdef _SPLIT_KERNEL_
#  else
  PathState ps;
#  endif
 };
#endif


/* Struct to gather multiple nearby intersections. */
 struct LocalIntersection { 
  Ray ray;
  float3 weight[LOCAL_MAX_HITS];

  int num_hits; 
  Intersection hits[LOCAL_MAX_HITS];
  float3 Ng[LOCAL_MAX_HITS];
 };




/* Subsurface */

/* Struct to gather SSS indirect rays and delay tracing them. */
struct SubsurfaceIndirectRays { 
  PathState state[BSSRDF_MAX_HITS];

  int num_rays; 
  Ray rays[BSSRDF_MAX_HITS];
  float3 throughputs[BSSRDF_MAX_HITS];
  PathRadianceState L_state[BSSRDF_MAX_HITS];
 };

 struct SubsurfaceIndirectRays0 { 
   int num_rays;
 };

//static_assert(BSSRDF_MAX_HITS <= LOCAL_MAX_HITS, "BSSRDF hits too high.");

/* Constant Kernel Data
 *
 * These structs are passed from CPU to various devices, and the struct layout
 * must match exactly. Structs are padded to ensure 16 byte alignment, and we
 * do not use float3 because its size may not be the same on all devices. */

struct KernelCamera { 
  /* type */
  int type;

  /* panorama */
  int panorama_type;
  float fisheye_fov;
  float fisheye_lens;
  float4 equirectangular_range;

  /* stereo */
  float interocular_offset;
  float convergence_distance;
  float pole_merge_angle_from;
  float pole_merge_angle_to;

  /* matrices */
  Transform cameratoworld;
  ProjectionTransform rastertocamera;

  /* differentials */
  float4 dx;
  float4 dy;

  /* depth of field */
  float aperturesize;
  float blades;
  float bladesrotation;
  float focaldistance;

  /* motion blur */
  float shuttertime;
  int num_motion_steps, have_perspective_motion;

  /* clipping */
  float nearclip;
  float cliplength;

  /* sensor size */
  float sensorwidth;
  float sensorheight;

  /* render size */
  float width, height;
  int resolution;

  /* anamorphic lens bokeh */
  float inv_aperture_ratio;

  int is_inside_volume;

  /* more matrices */
  ProjectionTransform screentoworld;
  ProjectionTransform rastertoworld;
  ProjectionTransform ndctoworld;
  ProjectionTransform worldtoscreen;
  ProjectionTransform worldtoraster;
  ProjectionTransform worldtondc;
  Transform worldtocamera;

  /* Stores changes in the projection matrix. Use for camera zoom motion
   * blur and motion pass output for perspective camera. */
  ProjectionTransform perspective_pre;
  ProjectionTransform perspective_post;

  /* Transforms for motion pass. */
  Transform motion_pass_pre;
  Transform motion_pass_post;

  int shutter_table_offset;

  /* Rolling shutter */
  int rolling_shutter_type;
  float rolling_shutter_duration;

  int pad;
 };
///static_assert_align(KernelCamera, 16);

struct KernelFilm { 
  float exposure;
  int pass_flag;

  int light_pass_flag;
  int pass_stride;
  int use_light_pass;

  int pass_combined;
  int pass_depth;
  int pass_normal;
  int pass_motion;

  int pass_motion_weight;
  int pass_uv;
  int pass_object_id;
  int pass_material_id;

  int pass_diffuse_color;
  int pass_glossy_color;
  int pass_transmission_color;

  int pass_diffuse_indirect;
  int pass_glossy_indirect;
  int pass_transmission_indirect;
  int pass_volume_indirect;

  int pass_diffuse_direct;
  int pass_glossy_direct;
  int pass_transmission_direct;
  int pass_volume_direct;

  int pass_emission;
  int pass_background;
  int pass_ao;
  float pass_alpha_threshold;

  int pass_shadow;
  float pass_shadow_scale;
  int filter_table_offset;
  int cryptomatte_passes;
  int cryptomatte_depth;
  int pass_cryptomatte;

  int pass_adaptive_aux_buffer;
  int pass_sample_count;

  int pass_mist;
  float mist_start;
  float mist_inv_depth;
  float mist_falloff;

  int pass_denoising_data;
  int pass_denoising_clean;
  int denoising_flags;

  int pass_aov_color;
  int pass_aov_value;
  int pass_aov_color_num;
  int pass_aov_value_num;
  int pad1, pad2, pad3;

  /* XYZ to rendering color space transform. float4 instead of float3 to
   * ensure consistent padding/alignment across devices. */
  float4 xyz_to_r;
  float4 xyz_to_g;
  float4 xyz_to_b;
  float4 rgb_to_y;

  int pass_bake_primitive;
  int pass_bake_differential;
  int pad;

#ifdef _KERNEL_DEBUG_
  int pass_bvh_traversed_nodes;
  int pass_bvh_traversed_instances;
  int pass_bvh_intersections;
  int pass_ray_bounces;
#endif

  /* viewport rendering options */
  int display_pass_stride;
  int display_pass_components;
  int display_divide_pass_stride;
  int use_display_exposure;
  int use_display_pass_alpha;

  int pad4, pad5, pad6;
 };
//static_assert_align(KernelFilm, 16);
struct KernelBackground { 
  /* only shader index */
  int surface_shader;
  int volume_shader;
  float volume_step_size;
  int transparent;
  float transparent_roughness_squared_threshold;

  /* ambient occlusion */
  float ao_factor;
  float ao_distance;
  float ao_bounces_factor;

  /* portal sampling */
  float portal_weight;
  int num_portals;
  int portal_offset;

  /* sun sampling */
  float sun_weight;
  /* xyz store direction, w the angle. float4 instead of float3 is used
   * to ensure consistent padding/alignment across devices. */
  float4 sun;

  /* map sampling */
  float map_weight;
  int map_res_x;
  int map_res_y;

  int use_mis;
 };
///static_assert_align(KernelBackground, 16);

struct KernelIntegrator { 
  /* emission */
  int use_direct_light;
  int use_ambient_occlusion;
  int num_distribution;
  int num_all_lights;
  float pdf_triangles;
  float pdf_lights;
  float light_inv_rr_threshold;

  /* bounces */
  int min_bounce;
  int max_bounce;

  int max_diffuse_bounce;
  int max_glossy_bounce;
  int max_transmission_bounce;
  int max_volume_bounce;

  int ao_bounces;

  /* transparent */
  int transparent_min_bounce;
  int transparent_max_bounce;
  int transparent_shadows;

  /* caustics */
  int caustics_reflective;
  int caustics_refractive;
  float filter_glossy;

  /* seed */
  int seed;

  /* clamp */
  float sample_clamp_direct;
  float sample_clamp_indirect;

  /* branched path */
  int branched;
  int volume_decoupled;
  int diffuse_samples;
  int glossy_samples;
  int transmission_samples;
  int ao_samples;
  int mesh_light_samples;
  int subsurface_samples;
  int sample_all_lights_direct;
  int sample_all_lights_indirect;

  /* mis */
  int use_lamp_mis;

  /* sampler */
  int sampling_pattern;
  int aa_samples;
  int adaptive_min_samples;
  int adaptive_step;
  int adaptive_stop_per_sample;
  float adaptive_threshold;

  /* volume render */
  int use_volumes;
  int volume_max_steps;
  float volume_step_rate;
  int volume_samples;

  int start_sample;

  int max_closures;

  int pad1, pad2;
 };
///static_assert_align(KernelIntegrator, 16);

//modify => enum KernelBVHLayout 
#define KernelBVHLayout uint
#define BVH_LAYOUT_NONE  uint(0)
#define BVH_LAYOUT_BVH2  uint((1<<0))
#define BVH_LAYOUT_EMBREE  uint((1<<1))
#define BVH_LAYOUT_OPTIX  uint((1<<2))
#define BVH_LAYOUT_AUTO  uint(BVH_LAYOUT_EMBREE)
#define BVH_LAYOUT_ALL  uint((~0u))
//modified ==> KernelBVHLayout




struct KernelBVH { 
  /* Own BVH */
  int root;
  int have_motion;
  int have_curves;
  int bvh_layout;
  int use_bvh_steps;
  int curve_subdivisions;

  /* Custom BVH */
#ifdef _KERNEL_OPTIX_
  OptixTraversableHandle scene;
#else
#  ifdef _EMBREE_
  RTCScene scene;
#    ifndef _KERNEL_64_BIT_
  int pad2;
#    endif
#  else
  int scene, pad2;
#  endif
#endif
 };
//static_assert_align(KernelBVH, 16);

struct KernelTables { 
  int beckmann_offset;
  int pad1, pad2, pad3;
 };
//static_assert_align(KernelTables, 16);

struct KernelBake { 
  int object_index;
  int tri_offset;
  int type;
  int pass_filter;
 };
//static_assert_align(KernelBake, 16);
struct KernelData { 
  KernelCamera cam;
  KernelFilm film;
  KernelBackground background;
  KernelIntegrator integrator;
  KernelBVH bvh;
  KernelTables tables;
  KernelBake bake;
 };
//static_assert_align(KernelData, 16);

/* Kernel data structures. */

struct KernelObject { 
  Transform tfm;
  Transform itfm;

  float surface_area;
  float pass_id;
  float random_number;
  float color[3];
  int particle_index;

  float dupli_generated[3];
  float dupli_uv[2];

  int numkeys;
  int numsteps;
  int numverts;

  uint patch_map_offset;
  uint attribute_map_offset;
  uint motion_offset;

  float cryptomatte_object;
  float cryptomatte_asset;

  float shadow_terminator_offset;
  float pad1, pad2, pad3;
 };
//static_assert_align(KernelObject, 16);


/*
struct KernelSpotLight { 
  float radius;
  float invarea;
  float spot_angle;
  float spot_smooth;
  float dir[3];
  float pad;
 };
*/
 
//struct KernelSpotLight { 

#define    SpotLight_radius(kl) kl.uni[0]
#define    SpotLight_invarea(kl) kl.uni[1]
#define    SpotLight_spot_angle(kl) kl.uni[2]
#define    SpotLight_spot_smooth(kl) kl.uni[3]
#define    SpotLight_dir0(kl) kl.uni[4]
#define    SpotLight_dir1(kl) kl.uni[5]
#define    SpotLight_dir2(kl) kl.uni[6]
#define    SpotLight_pad(kl) kl.uni[7]

 //};

/* PointLight is SpotLight with only radius and invarea being used. */
/*
struct KernelAreaLight { 
  float axisu[3];
  float invarea;
  float axisv[3];
  float pad1;
  float dir[3];
  float pad2;
 };
 */

 //struct KernelAreaLight { 
#define   AreaLight_axisu0(kl) kl.uni[0]
#define   AreaLight_axisu1(kl) kl.uni[1]
#define   AreaLight_axisu2(kl) kl.uni[2]
#define   AreaLight_invarea(kl) kl.uni[3]
#define   AreaLight_axisv0(kl) kl.uni[4]
#define   AreaLight_axisv1(kl) kl.uni[5]
#define   AreaLight_axisv2(kl) kl.uni[6]
#define   AreaLight_pad1(kl) kl.uni[7]
#define   AreaLight_dir0(kl) kl.uni[8]
#define   AreaLight_dir1(kl) kl.uni[9]
#define   AreaLight_dir2(kl) kl.uni[10]
#define   AreaLight_pad2(kl) kl.uni[11]
 //};
/*
struct KernelDistantLight { 
  float radius;
  float cosangle;
  float invarea;
  float pad;
 };
 */
 //struct KernelDistantLight { 
#define  DistantLight_radius(kl) kl.uni[0]
#define  DistantLight_cosangle(kl) kl.uni[1]
#define  DistantLight_invarea(kl) kl.uni[2]
#define  DistantLight_pad(kl) kl.uni[3]
 //};

struct KernelLight { 
  int type;
  float co[3];
  int shader_id;
  int samples;
  float max_bounces;
  float random;
  float strength[3];
  float pad1;
  Transform tfm;
  Transform itfm;
  float  uni[12];
  /* TODO UNION LIGHT
  union {
    KernelSpotLight spot;
    KernelAreaLight area;
    KernelDistantLight distant;
  };
  */
 };
 


struct KernelLightDistribution { 
  float totarea;
  int prim;
  float data[2];
   /* TODO UNION LIGHT
  union {
    struct {
      int shader_flag;
      int object_id;
    } mesh_light;
    struct {
      float pad;
      float size;
    } lamp;
  };
  */
 };

#define LightDistribution_mesh_light_shader_flag(ld) floatBitsToInt(ld.data[0])
#define LightDistribution_mesh_light_object_id(ld) floatBitsToInt(ld.data[1])
#define LightDistribution_lamp_size(ld) ld.data[1]


//static_assert_align(KernelLightDistribution, 16);
struct KernelParticle { 
  int index;
  float age;
  float lifetime;
  float size;
  float4 rotation;
  /* Only xyz are used of the following. float4 instead of float3 are used
   * to ensure consistent padding/alignment across devices. */
  float4 location;
  float4 velocity;
  float4 angular_velocity;
 };
//static_assert_align(KernelParticle, 16);



struct KernelShader { 
  float constant_emission[3];
  float cryptomatte_id;
  int flags;
  int pass_id;
  int pad2, pad3;
 };


//static_assert_align(KernelShader, 16);

/* Declarations required for split kernel */

/* Macro for queues */
/* Value marking queue's empty slot */
#define QUEUE_EMPTY_SLOT -1

/*
 * Queue 1 - Active rays
 * Queue 2 - Background queue
 * Queue 3 - Shadow ray cast kernel - AO
 * Queue 4 - Shadow ray cast kernel - direct lighting
 */

/* Queue names */
//modify => enum QueueNumber 
#define QueueNumber uint
#define QUEUE_ACTIVE_AND_REGENERATED_RAYS  uint(0)
#define QUEUE_HITBG_BUFF_UPDATE_TOREGEN_RAYS uint(1)
#define QUEUE_SHADOW_RAY_CAST_AO_RAYS uint(2)
#define QUEUE_SHADOW_RAY_CAST_DL_RAYS uint(3)
#define QUEUE_SHADER_SORTED_RAYS uint(4)
#define NUM_QUEUES uint(5)
//modified ==> QueueNumber



/* We use RAY_STATE_MASK to get ray_state */
#define RAY_STATE_MASK 0x0F
#define RAY_FLAG_MASK 0xF0
//modify => enum RayState 
#define RayState uint
#define RAY_INVALID  uint(0)
#define RAY_ACTIVE uint(1)
#define RAY_INACTIVE uint(2)
#define RAY_UPDATE_BUFFER uint(3)
#define RAY_HAS_ONLY_VOLUME uint(4)
#define RAY_HIT_BACKGROUND uint(5)
#define RAY_TO_REGENERATE uint(6)
#define RAY_REGENERATED uint(7)
#define RAY_LIGHT_INDIRECT_NEXT_ITER uint(8)
#define RAY_VOLUME_INDIRECT_NEXT_ITER uint(9)
#define RAY_SUBSURFACE_INDIRECT_NEXT_ITER uint(10)
#define RAY_BRANCHED_LIGHT_INDIRECT  uint((1<<4))
#define RAY_BRANCHED_VOLUME_INDIRECT  uint((1<<5))
#define RAY_BRANCHED_SUBSURFACE_INDIRECT  uint((1<<6))
#define RAY_BRANCHED_INDIRECT  uint((RAY_BRANCHED_LIGHT_INDIRECT|RAY_BRANCHED_VOLUME_INDIRECT|RAY_BRANCHED_SUBSURFACE_INDIRECT))
#define RAY_BRANCHED_INDIRECT_SHARED  uint((1<<7))
//modified ==> RayState




#define ASSIGN_RAY_STATE(ray_state, ray_index, state) \
  (ray_state[ray_index] = ((ray_state[ray_index] & RAY_FLAG_MASK) | state))
#define IS_STATE(ray_state, ray_index, state) \
  ((ray_index) != QUEUE_EMPTY_SLOT && ((ray_state)[(ray_index)] & RAY_STATE_MASK) == (state))
#define ADD_RAY_FLAG(ray_state, ray_index, flag) \
  (ray_state[ray_index] = (ray_state[ray_index] | flag))
#define REMOVE_RAY_FLAG(ray_state, ray_index, flag) \
  (ray_state[ray_index] = (ray_state[ray_index] & (~flag)))
#define IS_FLAG(ray_state, ray_index, flag) (ray_state[ray_index] & flag)

/* Patches */

#define PATCH_MAX_CONTROL_VERTS 16

/* Patch map node flags */

#define PATCH_MAP_NODE_IS_SET (1 << 30)
#define PATCH_MAP_NODE_IS_LEAF (1u << 31)
#define PATCH_MAP_NODE_INDEX_MASK (~(PATCH_MAP_NODE_IS_SET | PATCH_MAP_NODE_IS_LEAF))

/* Work Tiles */

struct WorkTile { 
  uint x, y, w, h;

  uint start_sample;
  uint num_samples;

  int offset;
  uint stride;
///TODO Buffer
  //global float *buffer;
 };

/* Precoumputed sample table sizes for PMJ02 sampler. */
#define NUM_PMJ_SAMPLES 64 * 64
#define NUM_PMJ_PATTERNS 48



#define SURFACE_CALL_TYPE_connect_light   0
#define SURFACE_CALL_TYPE_surface_bounce  1
#define SURFACE_CALL_TYPE_indirect_lamp   2
#define EXECUTION_SURFACE  executeCallableNV(0u,0)

#define BSDF_CALL_TYPE_EVAL   0
#define BSDF_CALL_TYPE_SAMPLE 1

#define SETUP_CALL_TYPE_RAY   0
#define SETUP_CALL_TYPE_SSS   1
#define SET_SETUP_CALL_TYPE   GSD.shader



#define EXECUTION_SAMPLE executeCallableNV(1u,0)
#define EXECUTION_LIGHT_SAMPLE executeCallableNV(1u,1)
#define EXECUTION_SVM    executeCallableNV(2u,1)
#define EXECUTION_SETUP    executeCallableNV(10u,1)


CCL_NAMESPACE_END




#include "kernel/kernel_texture_align.h"
#endif /*  _KERNEL_TYPES_H_ */
