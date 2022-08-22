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


#include "kernel/kernel_random.h.glsl"

struct hitPayload
{
    float3 throughput;
    PathRadiance L;
    PathState state;
};

struct BsdfEval {
#ifdef __PASSES__
  int use_light_pass;
#endif

  float3 diffuse;
#ifdef __PASSES__
  float3 glossy;
  float3 transmission;
  float3 transparent;
  float3 volume;
#endif
#ifdef __SHADOW_TRICKS__
  float3 sum_no_mis;
#endif
};
#define sizeof_BsdfEval   4*(6*4 + 1)


struct args_emission{
      ShaderDataTinyStorage sd; //316
      float   data[128];
};


struct args_bsdf
{
int label;
ShaderClosure bsdf;
vec4 Ng;
vec4 I;
vec4 dIdx;
vec4 dIdy;
float randu;
float randv;
vec4 eval;
vec4 omega_in;
differential3 domega;
float pdf;
};

layout(location = 0) rayPayloadInNV hitPayload      prd;
layout(location = 0) callableDataNV args_emission   emi;
layout(location = 1) callableDataNV args_bsdf   args;


hitAttributeNV vec2 attribs;

#define  light_select_reached_max_bounces(index,bounce) (bounce > kernel_tex_fetch(_lights, index).max_bounces)
#define  light_select_num_samples(index) kernel_tex_fetch(_lights, index).samples;


void main()
{

    /* Evaluate shader.
        shader_eval_surface(kg, &sd, state, buffer, state->flag);
        shader_prepare_closures(&sd, state);

        // Apply shadow catcher, holdout, emission. 
        if (!kernel_path_shader_apply(kg, &sd, state, ray, throughput, emission_sd, L, buffer)) {
          break;
        }

        // path termination. this is a strange place to put the termination, it's
        // mainly due to the mixed in MIS that we use. gives too many unneeded
        // shader evaluations, only need emission if we are going to terminate 
        float probability = path_state_continuation_probability(kg, state, throughput);

        if (probability == 0.0f) {
          break;
        }
        else if (probability != 1.0f) {
          float terminate = path_state_rng_1D(kg, state, PRNG_TERMINATE);
          if (terminate >= probability)
            break;

          throughput /= probability;
        }
        */ 


#define _EMISSION_
#define _SHADOW_TRICKS_


#ifdef _EMISSION_
    /* direct lighting */
    //kernel_path_surface_connect_light(kg, &sd, emission_sd, throughput, state, L);
#ifdef _SHADOW_TRICKS_

  //int all = (state->flag & PATH_RAY_SHADOW_CATCHER);
  //kernel_branched_path_surface_connect_light(kg, sd, emission_sd, state, throughput, 1.0f, L, all);

  /* sample illumination from lights to find path contribution */

  int   sample_all_lights    = (prd.state.flag & PATH_RAY_SHADOW_CATCHER);
  float num_samples_adjust   = 1.0f;
  int   num_lights           = 0;

  if (kernel_data.integrator.use_direct_light) {
    if (sample_all_lights) {
      num_lights = kernel_data.integrator.num_all_lights;
      if (kernel_data.integrator.pdf_triangles != 0.0f) {
        num_lights += 1;
      }
    }
    else {
      num_lights = 1;
    }
  }

  for (int i = 0; i < num_lights; i++) {
    /* sample one light at random */
    int num_samples = 1;
    int num_all_lights = 1;
    uint lamp_rng_hash = prd.state.rng_hash;
    bool double_pdf = false;
    bool is_mesh_light = false;
    bool is_lamp = false;

    if (sample_all_lights) {
      /* lamp sampling */
      is_lamp = i < kernel_data.integrator.num_all_lights;
      if (is_lamp) {
        if (UNLIKELY(light_select_reached_max_bounces(i, state->bounce))) {
          continue;
        }
        num_samples = ceil_to_int(num_samples_adjust * light_select_num_samples(kg, i));
        num_all_lights = kernel_data.integrator.num_all_lights;
        lamp_rng_hash = cmj_hash(prd.state.rng_hash, i);
        double_pdf = kernel_data.integrator.pdf_triangles != 0.0f;
      }
      /* mesh light sampling */
      else {
        num_samples = ceil_to_int(num_samples_adjust * kernel_data.integrator.mesh_light_samples);
        double_pdf = kernel_data.integrator.num_all_lights != 0;
        is_mesh_light = true;
      }
    }

    float num_samples_inv = num_samples_adjust / (num_samples * num_all_lights);

    for (int j = 0; j < num_samples; j++) {


      Ray light_ray ccl_optional_struct_init;
      light_ray.t = 0.0f; /* reset ray */

#    ifdef __OBJECT_MOTION__
      light_ray.time = sd->time;
#    endif
      bool has_emission = false;

      if (kernel_data.integrator.use_direct_light && (sd->flag & SD_BSDF_HAS_EVAL)) {
        
        
        float light_u, light_v;
        path_branched_rng_2D(lamp_rng_hash, state, j, num_samples, PRNG_LIGHT_U, light_u, light_v);

        float terminate = path_branched_rng_light_termination(lamp_rng_hash, state, j, num_samples);

        /* only sample triangle lights */
        if ( bool(is_mesh_light)  &&  bool(double_pdf) ){
             light_u = 0.5f * light_u;
        }

        LightSample ls ccl_optional_struct_init;
        const int lamp = is_lamp ? i : -1;
        if (light_sample(kg, lamp, light_u, light_v, sd->time, sd->P, state->bounce, &ls)) {
          /* The sampling probability returned by lamp_light_sample assumes that all lights were
           * sampled. However, this code only samples lamps, so if the scene also had mesh lights,
           * the real probability is twice as high. */
          if (double_pdf) {
            ls.pdf *= 2.0f;
          }

          has_emission = direct_emission(
              kg, sd, emission_sd, &ls, state, &light_ray, &L_light, &is_lamp, terminate);
        }



      }

      /* trace shadow ray */
      float3 shadow;

      const bool blocked = shadow_blocked(kg, sd, emission_sd, state, &light_ray, &shadow);

      if (has_emission) {
        if (!blocked) {
          /* accumulate */
          path_radiance_accum_light(kg,
                                    L,
                                    state,
                                    throughput * num_samples_inv,
                                    &L_light,
                                    shadow,
                                    num_samples_inv,
                                    is_lamp);
        }
        else {
          path_radiance_accum_total_light(L, state, throughput * num_samples_inv, &L_light);
        }
      }
    
    }
  
  
  }




  executeCallableNV(5u, 1);

#else



#endif

#endif /* __EMISSION__ */

//kernel_path_surface_bounce


}