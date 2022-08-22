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

#define sizeof_BsdfEval   4*(6*4 + 1)


struct args_PathState
{
    int flag;
    uint rng_hash;
    int rng_offset;
    int sample_rsv;
    int num_samples;
    float branch_factor;
    int bounce;
};
#define sizeof_args_PathState   4*(7)


struct args_ShaderData
{
vec4 P;
vec4 N;
vec4 Ng;
vec4 I;
int flag;
int type;
int object;
float time;
differential3 dP;
uint lcg_state;
int num_closure;

};
#define sizeof_args_ShaderData   4*( 4*4 + 6 + 4*2)



struct hitPayload0
{
ShaderDataTinyStorage esd;
int    lamp;        
float light_u;
float light_v;          // 3
args_ShaderData sd;     // 33 = 30 + 3
args_PathState  state;  // 40 = 7 + 33 
float pad[88];
};

#define ls_P emi.pad[0]
#define ls_Ng emi.pad[4]
#define ls_D emi.pad[8]
#define ls_t emi.pad[12]
#define ls_u emi.pad[13]
#define ls_v emi.pad[14]
#define ls_pdf emi.pad[15]
#define ls_eval_fac emi.pad[16]
#define ls_object emi.pad[17]
#define ls_prim emi.pad[18]
#define ls_shader emi.pad[19]
#define ls_lamp emi.pad[20]
#define ls_type emi.pad[21]
struct hitPayload_
{
vec4 throughput;
PathRadiance L;
PathState state;
ShaderData            sd;
ShaderDataTinyStorage esd;
};


layout(location = 0) rayPayloadInNV hitPayload_ prd;
layout(location = 0) callableDataNV hitPayload0 emi;
hitAttributeNV vec2 attribs;


#define  light_select_reached_max_bounces(index,bounce) (bounce > kernel_tex_fetch(_lights, index).max_bounces)
#define  light_select_num_samples(index) kernel_tex_fetch(_lights, index).samples


#define set_args_PathState(_lamp,lu,lv){\
emi.esd  = prd.esd;\
emi.lamp = _lamp;emi.light_u = lu;emi.light_v = lv;\
emi.sd.P =  prd.esd.P;\
emi.sd.N =  prd.esd.N;\
emi.sd.Ng=  prd.esd.Ng;\
emi.sd.I=  prd.esd.I;\
emi.sd.flag=  prd.esd.flag;\
emi.sd.type=  prd.esd.type;\
emi.sd.object=  prd.esd.object;\
emi.sd.time=  prd.esd.time;\
emi.sd.dP=  prd.esd.dP;\
emi.sd.lcg_state=  prd.esd.lcg_state;\
emi.sd.num_closure=  prd.esd.num_closure;\
emi.state.flag = prd.state.flag;\
emi.state.rng_hash= prd.state.rng_hash;\
emi.state.rng_offset= prd.state.rng_offset;\
emi.state.sample_rsv= prd.state.sample_rsv;\
emi.state.num_samples= prd.state.num_samples;\
emi.state.branch_factor= prd.state.branch_factor;\
emi.state.bounce= prd.state.bounce;\
}

#define light_sample_args(_lamp,lu,lv){\
emi.lamp = _lamp;emi.light_u = lu;emi.light_v = lv;\
emi.sd.time = prd.sd.time;emi.sd.P= prd.sd.P;emi.state.bounce= prd.state.bounce;\
}


#include "kernel/kernel_differential.h.glsl"

/* Constant emission optimization */

ccl_device bool shader_constant_emission_eval(in int shader,inout  float3 eval)
{
  int shader_index = int(shader & SHADER_MASK);
  int shader_flag = kernel_tex_fetch(_shaders, shader_index).flags;

  if (shader_flag & SD_HAS_CONSTANT_EMISSION) {
    *eval = make_float3(kernel_tex_fetch(_shaders, shader_index).constant_emission[0],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[1],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[2]);

    return true;
  }

  return false;
}
/* Direction Emission */
ccl_device_noinline_cpu float3 direct_emissive_eval(
                                                    float3 I,
                                                    differential3 dI,
                                                    float t,
                                                    float time)
{
  /* setup shading at emitter */
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  if (shader_constant_emission_eval(kg, int(ls_shader), &eval)) {
    if ((ls->prim != PRIM_NONE) && dot(ls->Ng, I) < 0.0f) {
      ls->Ng = -ls->Ng;
    }
  }
  else {
    /* Setup shader data and call shader_eval_surface once, better
     * for GPU coherence and compile times. */
#ifdef __BACKGROUND_MIS__
    if (ls->type == LIGHT_BACKGROUND) {
      Ray ray;
      ray.D = ls->D;
      ray.P = ls->P;
      ray.t = 1.0f;
      ray.time = time;
      ray.dP = differential3_zero();
      ray.dD = dI;

      shader_setup_from_background(kg, emission_sd, &ray);
    }
    else
#endif
    {
      shader_setup_from_sample(kg,
                               emission_sd,
                               ls->P,
                               ls->Ng,
                               I,
                               ls->shader,
                               ls->object,
                               ls->prim,
                               ls->u,
                               ls->v,
                               t,
                               time,
                               false,
                               ls->lamp);

      ls->Ng = emission_sd->Ng;
    }

    /* No proper path flag, we're evaluating this for all closures. that's
     * weak but we'd have to do multiple evaluations otherwise. */
    path_state_modify_bounce(state, true);
    shader_eval_surface(kg, emission_sd, state, NULL, PATH_RAY_EMISSION);
    path_state_modify_bounce(state, false);

    /* Evaluate closures. */
#ifdef __BACKGROUND_MIS__
    if (ls->type == LIGHT_BACKGROUND) {
      eval = shader_background_eval(emission_sd);
    }
    else
#endif
    {
      eval = shader_emissive_eval(emission_sd);
    }
  }

  eval *= ls->eval_fac;

  if (ls->lamp != LAMP_NONE) {
    const ccl_global KernelLight *klight = &kernel_tex_fetch(__lights, ls->lamp);
    eval *= make_float3(klight->strength[0], klight->strength[1], klight->strength[2]);
  }

  return eval;
}



ccl_device_noinline_cpu bool direct_emission(
                                             inout Ray ray,
                                             inout BsdfEval eval,
                                             inout bool is_lamp,
                                             float rand_terminate)
{

  if ( ls_pdf == 0.0f)
    return false;
  /* todo: implement */
  differential3 dD = differential3_zero();
  /* evaluate closure */
  float3 light_eval = direct_emissive_eval(-ls_D, dD, ls_t, emi.sd.time);
  if (is_zero(light_eval))
    return false;


}


void main()
{

    set_args_PathState(-1,0.5,0.5);
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

  int   sample_all_lights    =  int(prd.state.flag & PATH_RAY_SHADOW_CATCHER);
  float num_samples_adjust   = 1.0f;
  int   num_lights           = 0;

  if (bool(kernel_data.integrator.use_direct_light)) {
    if (bool(sample_all_lights)) {
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

    if ( bool(sample_all_lights) ) {
      /* lamp sampling */
      is_lamp = i < kernel_data.integrator.num_all_lights;
      if (is_lamp) {
        if (UNLIKELY(light_select_reached_max_bounces(i, prd.state.bounce))) {
          continue;
        }
        num_samples = ceil_to_int(num_samples_adjust * light_select_num_samples(i));
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

      if (bool(kernel_data.integrator.use_direct_light) && bool(prd.sd.flag & SD_BSDF_HAS_EVAL)) {
        
        
        float light_u, light_v;
        path_branched_rng_2D(lamp_rng_hash, prd.state, j, num_samples, int(PRNG_LIGHT_U), light_u, light_v);

        float terminate = path_branched_rng_light_termination(lamp_rng_hash, prd.state, j, num_samples);

        /* only sample triangle lights */
        if ( bool(is_mesh_light)  &&  bool(double_pdf) ){
             light_u = 0.5f * light_u;
        }

        light_sample_args((is_lamp ? i : -1) ,light_u, light_v )

        executeCallableNV(0u, 0);
        
        if (double_pdf) {
            ls_pdf *= 2.0f;
        };

        has_emission = direct_emission(light_ray, L_light, is_lamp, terminate);
        /*
        LightSample ls ccl_optional_struct_init;
        const int lamp = is_lamp ? i : -1;
        if (light_sample(kg, lamp, light_u, light_v, sd->time, sd->P, state->bounce, &ls)) {
          // The sampling probability returned by lamp_light_sample assumes that all lights were
          // sampled. However, this code only samples lamps, so if the scene also had mesh lights,
          // the real probability is twice as high. 

          if (double_pdf) {
            ls.pdf *= 2.0f;
          }

          has_emission = direct_emission(
              kg, sd, emission_sd, &ls, state, &light_ray, &L_light, &is_lamp, terminate);
        }
        */



      }

      /* trace shadow ray 
      float3 shadow;

      const bool blocked = shadow_blocked(kg, sd, emission_sd, state, &light_ray, &shadow);

      if (has_emission) {
        if (!blocked) {
          // accumulate 
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
       
       */
    }
  
  
  }




    // 
    prd.throughput = vec4(0.2,0.4,0.5,1.);

#else



#endif

#endif /* __EMISSION__ */

//kernel_path_surface_bounce


}

