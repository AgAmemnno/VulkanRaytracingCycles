#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#define PUSH_POOL_SC
#define PUSH_KERNEL_TEX
#define SET_KERNEL 2

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#include "kernel/kernel_globals.h.glsl"

#include "kernel/kernel_light_common.h.glsl"
#include "kernel/kernel_light_background.h.glsl"



//modify => enum ObjectTransform 
#define ObjectTransform uint
#define  OBJECT_TRANSFORM  0
#define  OBJECT_INVERSE_TRANSFORM  1
//modified ==> ObjectTransform




//modify => enum ObjectVectorTransform 
#define ObjectVectorTransform uint
#define  OBJECT_PASS_MOTION_PRE  0
#define  OBJECT_PASS_MOTION_POST  1
//modified ==> ObjectVectorTransform



struct LightSample
{
    vec4 P;
    vec4 Ng;
    vec4 D;
    float t;
    float u;
    float v;
    float pdf;
    float eval_fac;
    int object;
    int prim;
    int shader;
    int lamp;
    uint type;
};

#define sizeof_LightSample 4*( 4*3 + 10)

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
LightSample ls;
};


layout(location = 0) callableDataInNV hitPayload0 emi;

/* Direction Emission */
ccl_device_noinline_cpu float3 direct_emissive_eval(KernelGlobals *kg,
                                                    ShaderData *emission_sd,
                                                    LightSample *ls,
                                                    ccl_addr_space PathState *state,
                                                    float3 I,
                                                    differential3 dI,
                                                    float t,
                                                    float time)
{
  /* setup shading at emitter */
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  if (shader_constant_emission_eval(kg, ls->shader, &eval)) {
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



ccl_device_noinline_cpu bool direct_emission(KernelGlobals *kg,
                                             ShaderData *sd,
                                             ShaderData *emission_sd,
                                             LightSample *ls,
                                             ccl_addr_space PathState *state,
                                             Ray *ray,
                                             BsdfEval *eval,
                                             bool *is_lamp,
                                             float rand_terminate)
{
  if (ls->pdf == 0.0f)
    return false;

  /* todo: implement */
  differential3 dD = differential3_zero();

  /* evaluate closure */

  float3 light_eval = direct_emissive_eval(
      kg, emission_sd, ls, state, -ls->D, dD, ls->t, sd->time);

  if (is_zero(light_eval))
    return false;

    /* evaluate BSDF at shading point */

#ifdef __VOLUME__
  if (sd->prim != PRIM_NONE)
    shader_bsdf_eval(kg, sd, ls->D, eval, ls->pdf, ls->shader & SHADER_USE_MIS);
  else {
    float bsdf_pdf;
    shader_volume_phase_eval(kg, sd, ls->D, eval, &bsdf_pdf);
    if (ls->shader & SHADER_USE_MIS) {
      /* Multiple importance sampling. */
      float mis_weight = power_heuristic(ls->pdf, bsdf_pdf);
      light_eval *= mis_weight;
    }
  }
#else
  shader_bsdf_eval(kg, sd, ls->D, eval, ls->pdf, ls->shader & SHADER_USE_MIS);
#endif

  bsdf_eval_mul3(eval, light_eval / ls->pdf);

#ifdef __PASSES__
  /* use visibility flag to skip lights */
  if (ls->shader & SHADER_EXCLUDE_ANY) {
    if (ls->shader & SHADER_EXCLUDE_DIFFUSE)
      eval->diffuse = make_float3(0.0f, 0.0f, 0.0f);
    if (ls->shader & SHADER_EXCLUDE_GLOSSY)
      eval->glossy = make_float3(0.0f, 0.0f, 0.0f);
    if (ls->shader & SHADER_EXCLUDE_TRANSMIT)
      eval->transmission = make_float3(0.0f, 0.0f, 0.0f);
    if (ls->shader & SHADER_EXCLUDE_SCATTER)
      eval->volume = make_float3(0.0f, 0.0f, 0.0f);
  }
#endif

  if (bsdf_eval_is_zero(eval))
    return false;

  if (kernel_data.integrator.light_inv_rr_threshold > 0.0f
#ifdef __SHADOW_TRICKS__
      && (state->flag & PATH_RAY_SHADOW_CATCHER) == 0
#endif
  ) {
    float probability = max3(fabs(bsdf_eval_sum(eval))) *
                        kernel_data.integrator.light_inv_rr_threshold;
    if (probability < 1.0f) {
      if (rand_terminate >= probability) {
        return false;
      }
      bsdf_eval_mul(eval, 1.0f / probability);
    }
  }

  if (ls->shader & SHADER_CAST_SHADOW) {
    /* setup ray */
    bool transmit = (dot(sd->Ng, ls->D) < 0.0f);
    ray->P = ray_offset(sd->P, (transmit) ? -sd->Ng : sd->Ng);

    if (ls->t == FLT_MAX) {
      /* distant light */
      ray->D = ls->D;
      ray->t = ls->t;
    }
    else {
      /* other lights, avoid self-intersection */
      ray->D = ray_offset(ls->P, ls->Ng) - ray->P;
      ray->D = normalize_len(ray->D, &ray->t);
    }

    ray->dP = sd->dP;
    ray->dD = differential3_zero();
  }
  else {
    /* signal to not cast shadow ray */
    ray->t = 0.0f;
  }

  /* return if it's a lamp for shadow pass */
  *is_lamp = (ls->prim == PRIM_NONE && ls->type != LIGHT_BACKGROUND);

  return true;
}


void main(){
    direct_emission();
};
