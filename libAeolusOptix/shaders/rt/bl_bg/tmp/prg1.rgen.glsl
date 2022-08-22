#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable



#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"


#include "kernel/kernel_globals.h.glsl"

struct BG_prd
{
    ShaderData            sd;
    //ShaderDataTinyStorage esd;
};


layout(location = 0) rayPayloadNV BG_prd prd;
#define GSD prd.sd
layout(binding = 0, set = 0) uniform accelerationStructureNV topLevelAS;
layout(binding = 1, set = 0, rgba8) uniform image2D image;
layout(binding = 0, set = 1) uniform CameraProperties
{
  mat4 view;
  mat4 proj;
  mat4 viewInverse;
  mat4 projInverse;
} cam;

#define SET_BG  4
#ifdef SET_BG
layout (set=SET_BG,binding = 0) buffer BG_IN { 
  uint4   inpu[];
};

layout (set=SET_BG,binding = 1) buffer BG_OUT{ 
  float4  outpu[];
};

#endif

#include "kernel/kernel_projection.h.glsl"
#include "kernel/kernel_differential.h.glsl"
/* ShaderData setup from ray into background */

void shader_setup_from_background(in Ray ray)
{


  /* vectors */
  GSD.P = ray.D;
  GSD.N = -ray.D;
  GSD.Ng = -ray.D;
  GSD.I = -ray.D;
  GSD.shader = kernel_data.background.surface_shader;
  GSD.flag = kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).flags;
  GSD.object_flag = 0;
  GSD.time = ray.time;
  GSD.ray_length = 0.0f;

  GSD.object = OBJECT_NONE;
  GSD.lamp = LAMP_NONE;
  GSD.prim = PRIM_NONE;
  GSD.u = 0.0f;
  GSD.v = 0.0f;

#ifdef _DPDU_
  /* dPdu/dPdv */
  GSD.dPdu = make_float3(0.0f, 0.0f, 0.0f);
  GSD.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#endif

#ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  GSD.dP = ray.dD;
  differential_incoming(GSD.dI, GSD.dP);
  differential_zero(GSD.du);
  differential_zero(GSD.dv );
#endif

  /* for NDC coordinates */
  GSD.ray_P = ray.P;


}

#define shader_background_eval()  ( (bool(GSD.flag & SD_EMISSION)) ? GSD.closure_emission_background : make_float3(0.0f, 0.0f, 0.0f))

/* Surface Evaluation */
void shader_eval_surface( uint path_flag)
{
 

  /* If path is being terminated, we are tracing a shadow ray or evaluating
   * emission, then we don't need to store closures. The emission and shadow
   * shader data also do not have a closure array to save GPU memory. */
  int max_closures;
  if (bool(path_flag & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION))) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }

  GSD.num_closure = int(path_flag);
  GSD.num_closure_left = max_closures;

#ifdef ENABLE_PROFI
  GSD.alloc_offset  = PROFI_IDX;
#endif

  executeCallableNV(4u, 1);   
    //svm_eval_nodes(kg, sd, state, buffer_ofs, SHADER_TYPE_SURFACE, path_flag);


if (bool(GSD.flag & SD_BSDF_NEEDS_LCG) ){
    debugPrintfEXT(" Warning  lcg_state required   \n",uint(GSD.flag));
   /*lcg_init(state->rng_hash + state->rng_offset + state->sample * scramble);
    sd.lcg_state = lcg_init( uint(arg.state.rng_hash) + uint(arg.state.rng_offset) + uint(arg.state.sample_rsv) *  3032234323u );//0xb4bc3953
    */
}

}

void main()
{


  int i = int(gl_LaunchIDNV.x + gl_LaunchSizeNV.x*gl_LaunchIDNV.y);

  //PathState state;
  uint4 inp = bginpu[i];
  /* setup ray */
  Ray ray;
  float u = _uint_as_float(inp.x);
  float v = _uint_as_float(inp.y);

  ray.P = make_float3(0.0f, 0.0f, 0.0f);
  ray.D = equirectangular_to_direction(u, v);
  ray.t = 0.0f;
#ifdef _CAMERA_MOTION_
  ray.time = 0.5f;
#endif

#ifdef _RAY_DIFFERENTIALS_
  differential3_zero(ray.dD);
  differential3_zero(ray.dP);
#endif

 shader_setup_from_background(ray);
 /* evaluate */
 uint path_flag = 0; /* we can't know which type of BSDF this is for */
 shader_eval_surface( path_flag | PATH_RAY_EMISSION);

float3 color = shader_background_eval();

bgoutpu[i] = make_float4(color.x, color.y, color.z, 0.0f);

}
