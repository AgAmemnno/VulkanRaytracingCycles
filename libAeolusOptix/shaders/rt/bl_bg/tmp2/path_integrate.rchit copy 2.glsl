#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable


#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#define PUSH_POOL_SC
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"


#include "kernel/kernel_globals.h.glsl"


#include "kernel/kernel_random.h.glsl"

#include "kernel/geom/geom_object.h.glsl"
#define LIGHT_SAMPLE 0u
#define SVM_NODES_EVAL 1u


//#include "kernel/kernel_path_state.h.glsl"
ccl_device_inline void path_state_modify_bounce(bool increase)
{
  /* Modify bounce temporarily for shader eval */
  if (increase)
    prd.state.bounce += 1;
  else
    prd.state.bounce -= 1;
}
//#include "kernel/kernel_path_state.h.glsl"

//#include "kernel/geom/geom_triangle.h.glsl"
ccl_device_inline float3
triangle_smooth_normal(float3 Ng, int prim, float u, float v)
{
  /* load triangle vertices */
  const uint4 tri_vindex = kernel_tex_fetch(_tri_vindex, prim);
  float3 n0 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.x));
  float3 n1 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.y));
  float3 n2 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.z));

  float3 N = safe_normalize((1.0f - u - v) * n2 + u * n0 + v * n1);

  return is_zero(N) ? Ng : N;
}

/* Ray differentials on triangle */

ccl_device_inline void triangle_dPdudv(
                                       int prim,
                                       ccl_addr_space inout float3 dPdu,
                                       ccl_addr_space inout float3 dPdv)
{
  /* fetch triangle vertex coordinates */
  const uint4 tri_vindex = kernel_tex_fetch(_tri_vindex, prim);
  const float3 p0 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 0));
  const float3 p1 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 1));
  const float3 p2 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 2));

  /* compute derivatives of P w.r.t. uv */
  dPdu = (p0 - p2);
  dPdv = (p1 - p2);
}
//#include "kernel/geom/geom_triangle.h.glsl"



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
#define ls_object floatBitsToInt(emi.pad[17])
#define ls_prim   floatBitsToInt(emi.pad[18])
#define ls_shader floatBitsToInt(emi.pad[19])
#define ls_lamp   floatBitsToInt(emi.pad[20])
#define ls_type   floatBitsToUint(emi.pad[21])


#define set_ls_object(val) ls_object =   intBitsToFloat(int(val))
#define set_ls_prim(val)   ls_prim =   intBitsToFloat(int(val))
#define set_ls_shader(val) ls_shader =   intBitsToFloat(int(val))
#define set_ls_lamp(val) ls_lamp =   intBitsToFloat(int(val))
#define set_ls_type(val) ls_type =   uintBitsToFloat(uint(val))




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


#define set_args_emissive(_lamp,lu,lv){\
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

#define set_args_PathState(){\
emi.state.flag     = prd.state.flag;\
emi.state.rng_hash  = prd.state.rng_hash;\
emi.state.rng_offset= prd.state.rng_offset;\
emi.state.sample_rsv= prd.state.sample_rsv;\
emi.state.num_samples= prd.state.num_samples;\
emi.state.branch_factor= prd.state.branch_factor;\
emi.state.bounce    = prd.state.bounce;\
}


#include "kernel/kernel_differential.h.glsl"
#include "kernel/closure/emissive.h.glsl"


void shader_setup_from_ray(in Intersection isect,in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);


  sd.object = (isect.object == OBJECT_NONE) ? int( kernel_tex_fetch(_prim_object, isect.prim)) :isect.object;
  sd.lamp   = LAMP_NONE;

  sd.type   = isect.type;
  sd.flag   = 0;
  sd.object_flag = int(kernel_tex_fetch(_object_flag, sd.object));

  /* matrices and time */
#ifdef __OBJECT_MOTION__
  shader_setup_object_transforms(kg, sd, ray->time);
#endif
  sd.time = ray.time;

  sd.prim = int(kernel_tex_fetch(_prim_index, isect.prim));
  sd.ray_length = isect.t;

  sd.u = isect.u;
  sd.v = isect.v;

#ifdef __HAIR__
  if (sd->type & PRIMITIVE_ALL_CURVE) {
    /* curve */
    curve_shader_setup(kg, sd, isect, ray);
  }
  else
#endif
      if(bool(sd.type & PRIMITIVE_TRIANGLE) ){
    /* static triangle */
    float3 Ng = triangle_normal();
    sd.shader = int(kernel_tex_fetch(_tri_shader, sd.prim));

    /* vectors */
    sd.P = triangle_refine(isect, ray);
    sd.Ng = Ng;
    sd.N  = Ng;

    /* smooth normal */
    if( bool (sd.shader & SHADER_SMOOTH_NORMAL))
      sd.N = triangle_smooth_normal(Ng, sd.prim, sd.u, sd.v);

#ifdef __DPDU__
    /* dPdu/dPdv */
    triangle_dPdudv(kg, sd->prim, &sd->dPdu, &sd->dPdv);
#endif
  }
  else {
    /* motion triangle */
    //motion_triangle_shader_setup(kg, sd, isect, ray, false);
  }

  sd.I = -ray.D;

  sd.flag |= kernel_tex_fetch(_shaders, (sd.shader & SHADER_MASK)).flags;

  if (isect.object != OBJECT_NONE) {
    /* instance transform */
    object_normal_transform(sd.N);
    object_normal_transform(sd.Ng);
#ifdef __DPDU__
    object_dir_transform_auto(kg, sd, &sd->dPdu);
    object_dir_transform_auto(kg, sd, &sd->dPdv);
#endif
  }

  /* backfacing test */
  bool backfacing = (dot(sd.Ng, sd.I) < 0.0f);

  if (backfacing) {
    sd.flag |= int(SD_BACKFACING);
    sd.Ng = -sd.Ng;
    sd.N = -sd.N;
#ifdef __DPDU__
    sd->dPdu = -sd->dPdu;
    sd->dPdv = -sd->dPdv;
#endif
  }

#ifdef __RAY_DIFFERENTIALS__
  /* differentials */
  differential_transfer(&sd->dP, ray->dP, ray->D, ray->dD, sd->Ng, isect->t);
  differential_incoming(&sd->dI, ray->dD);
  differential_dudv(&sd->du, &sd->dv, sd->dPdu, sd->dPdv, sd->dP, sd->Ng);
#endif

  PROFILING_SHADER(sd.shader);
  PROFILING_OBJECT(sd.object);
}


/* Constant emission optimization */

ccl_device bool shader_constant_emission_eval(int shader, inout float3 eval)
{
  int shader_index = shader & SHADER_MASK;
  int shader_flag = kernel_tex_fetch(_shaders, shader_index).flags;

  if (shader_flag & SD_HAS_CONSTANT_EMISSION) {
      eval = make_float3(kernel_tex_fetch(_shaders, shader_index).constant_emission[0],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[1],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[2]);

    return true;
  }

  return false;
}

/* Surface Evaluation */

ccl_device void shader_eval_surface(
                                    inout ShaderData sd,
                                    int path_flag)
{
  /* If path is being terminated, we are tracing a shadow ray or evaluating
   * emission, then we don't need to store closures. The emission and shadow
   * shader data also do not have a closure array to save GPU memory. */
  /*
  int max_closures;
  if (bool(path_flag & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION))) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }
  sd.num_closure = 0;
  sd.num_closure_left = max_closures;
  svm_eval_nodes(kg, sd, state, buffer, SHADER_TYPE_SURFACE, path_flag);
  */

   emi.lamp =  path_flag;
   executeCallableNV(SVM_NODES_EVAL, 0);

  if (bool(sd.flag & SD_BSDF_NEEDS_LCG)) {
    sd.lcg_state = lcg_state_init_addrspace(prd.state, 0xb4bc3953);
  }

}


ccl_device_inline void shader_setup_from_sample(
                                                const float3 P,
                                                const float3 Ng,
                                                const float3 I,
                                                int shader,
                                                int object,
                                                int prim,
                                                float u,
                                                float v,
                                                float t,
                                                float time,
                                                bool object_space,
                                                int lamp)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);
  /* vectors */
  emi.esd.P = P;
  emi.esd.N = Ng;
  emi.esd.Ng = Ng;
  emi.esd.I = I;
  emi.esd.shader = shader;
  if (prim != PRIM_NONE)
    emi.esd.type = int(PRIMITIVE_TRIANGLE);

  else if (lamp != LAMP_NONE)
    emi.esd.type = int( PRIMITIVE_LAMP);

  else
    emi.esd.type = int( PRIMITIVE_NONE);


  /* primitive */
  emi.esd.object = object;
  emi.esd.lamp = LAMP_NONE;
  /* currently no access to bvh prim index for strand emi.esd.prim*/
  emi.esd.prim = prim;
  emi.esd.u = u;
  emi.esd.v = v;
  emi.esd.time = time;
  emi.esd.ray_length = t;

  emi.esd.flag = kernel_tex_fetch(_shaders, (emi.esd.shader & SHADER_MASK)).flags;
  emi.esd.object_flag = 0;
  if (emi.esd.object != OBJECT_NONE) {
    emi.esd.object_flag |= int(kernel_tex_fetch(_object_flag, emi.esd.object));


#ifdef _OBJECT_MOTION_
    shader_setup_object_transforms(kg, sd, time);
  }
  else if (lamp != LAMP_NONE) {
    emi.esd.ob_tfm = lamp_fetch_transform(kg, lamp, false);
    emi.esd.ob_itfm = lamp_fetch_transform(kg, lamp, true);
    emi.esd.lamp = lamp;
#else
  }
  else if (lamp != LAMP_NONE) {
    emi.esd.lamp = lamp;
#endif
  }

  /* transform into world space */
  if (object_space) {
    object_position_transform_auto(emi.esd.P);
    object_normal_transform_auto(emi.esd.Ng);
    emi.esd.N = emi.esd.Ng;
    object_dir_transform_auto(emi.esd.I);

  }

  if (bool(emi.esd.type & PRIMITIVE_TRIANGLE)) {
    /* smooth normal */
    if (bool(emi.esd.shader & SHADER_SMOOTH_NORMAL)) {


      emi.esd.N = triangle_smooth_normal(Ng, emi.esd.prim, emi.esd.u, emi.esd.v);

      if (!(bool(emi.esd.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {
        object_normal_transform_auto(emi.esd.N);
      }
    }

    /* dPdu/dPdv */
#ifdef _DPDU_
    triangle_dPdudv(emi.esd.prim, (emi.esd.dPdu), (emi.esd.dPdv));
    if (!(bool(bool(emi.esd.object_flag & SD_OBJECT_TRANSFORM_APPLIED)))) {
      object_dir_transform_auto(emi.esd.dPdu);
      object_dir_transform_auto(emi.esd.dPdv);

    }
#endif
  }
  else {
#ifdef _DPDU_
    emi.esd.dPdu = make_float3(0.0f, 0.0f, 0.0f);
    emi.esd.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#endif
  }

  /* backfacing test */
  if (emi.esd.prim != PRIM_NONE) {
    bool backfacing = (dot(emi.esd.Ng, emi.esd.I) < 0.0f);

    if (bool(backfacing)) {

      emi.esd.flag |= int(SD_BACKFACING);

      emi.esd.Ng = -emi.esd.Ng;
      emi.esd.N = -emi.esd.N;
#ifdef _DPDU_
      emi.esd.dPdu = -emi.esd.dPdu;
      emi.esd.dPdv = -emi.esd.dPdv;
#endif
    }
  }

#ifdef _RAY_DIFFERENTIALS_
  /* no ray differentials here yet */
  emi.esd.dP = differential3_zero();
  emi.esd.dI = differential3_zero();
  emi.esd.du = differential_zero();
  emi.esd.dv = differential_zero();
#endif

  PROFILING_SHADER(emi.esd.shader);
  PROFILING_OBJECT(emi.esd.object);
}


/* Emission */

ccl_device float3 shader_emissive_eval(inout ShaderData sd)
{
  if (bool(sd.flag & SD_EMISSION)) {

    return emissive_simple_eval(sd.Ng, sd.I) * sd.closure_emission_background;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
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

  if (shader_constant_emission_eval(ls_shader, eval)) {
    if ((ls_prim != PRIM_NONE) && dot(ls_Ng, I) < 0.0f) {
      ls_Ng = -ls_Ng;
    }
  }
  else {
    /* Setup shader data and call shader_eval_surface once, better
     * for GPU coherence and compile times. */
#ifdef _BACKGROUND_MIS_
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
      shader_setup_from_sample(
                               ls_P,
                               ls_Ng,
                               I,
                               ls_shader,
                               ls_object,
                               ls_prim,
                               ls_u,
                               ls_v,
                               t,
                               time,
                               false,
                               ls_lamp);

      ls_Ng = emi.esd.Ng;
    }

    /* No proper path flag, we're evaluating this for all closures. that's
     * weak but we'd have to do multiple evaluations otherwise. */

    path_state_modify_bounce(true);
    shader_eval_surface(emi.esd,  PATH_RAY_EMISSION);
    path_state_modify_bounce(false);

    /* Evaluate closures. */
#ifdef _BACKGROUND_MIS_
    if (ls->type == LIGHT_BACKGROUND) {
      eval = shader_background_eval(emission_sd);
    }
    else
#endif
    {
      eval = shader_emissive_eval(emi.esd);
    }
  }

  eval *= ls_eval_fac;

  if (ls_lamp != LAMP_NONE) {
    const ccl_global KernelLight klight = kernel_tex_fetch(_lights, ls_lamp);
    eval *= make_float3(klight.strength[0], klight.strength[1], klight.strength[2]);
  }

  return eval;

}




ccl_device_noinline_cpu bool direct_emission(
                                             inout Ray ray,
                                             inout BsdfEval eval,
                                             inout bool is_lamp,
                                             float rand_terminate)
{
  if (ls_pdf == 0.0f)
    return false;

  /* todo: implement */
  differential3 dD = differential3_zero();

  /* evaluate closure */

  float3 light_eval = direct_emissive_eval( -ls_D, dD, ls_t, prd.sd.time);


  if (is_zero(light_eval))
    return false;
};

#define CALL_TYPE_lamp_light_eval 1234

void indirect_lamp_emission( Ray ray)
{
  for (int lamp = 0; lamp < kernel_data.integrator.num_all_lights; lamp++) {
    //LightSample ls;
    emi.lamp = lamp;
    emi.ls.P = ray.P;
    emi.ls.D = ray.D;
    emi.ls.t = ray.t;
    emi.ls.type = CALL_TYPE_lamp_light_eval;

    executeCallableNV(LIGHT_SAMPLE, 0);
    //if (!lamp_light_eval(lamp, ray.P, ray.D, ray.t, ls))
    //  continue;
    if(!bool(emi.lamp))continue;

#ifdef _PASSES_
    /* use visibility flag to skip lights */
    if (bool(emi.ls.shader & SHADER_EXCLUDE_ANY)) {
      if (( bool(emi.ls.shader & SHADER_EXCLUDE_DIFFUSE) && bool(sd.state.flag & PATH_RAY_DIFFUSE)) ||
          ( bool(emi.ls.shader & SHADER_EXCLUDE_GLOSSY) &&
           ((sd.state.flag & (PATH_RAY_GLOSSY | PATH_RAY_REFLECT)) ==
            (PATH_RAY_GLOSSY | PATH_RAY_REFLECT))) ||
          (bool(emi.ls.shader & SHADER_EXCLUDE_TRANSMIT) && bool(sd.state.flag & PATH_RAY_TRANSMIT)) ||
          (bool(emi.ls.shader & SHADER_EXCLUDE_SCATTER) && bool(sd.state.flag & PATH_RAY_VOLUME_SCATTER)))
        continue;
    }
#endif

    float3 lamp_L = direct_emissive_eval(-ray.D, ray.dD, emi.ls.t, ray.time);

#ifdef _VOLUME_
    if (state.volume_stack[0].shader != SHADER_NONE) {
      /* shadow attenuation */
      Ray volume_ray = *ray;
      volume_ray.t = emi.ls.t;
      float3 volume_tp = make_float3(1.0f, 1.0f, 1.0f);
      kernel_volume_shadow(kg, emission_sd, state, &volume_ray, &volume_tp);
      lamp_L *= volume_tp;
    }
#endif

    if (!bool(prd.state.flag & PATH_RAY_MIS_SKIP)) {
      /* multiple importance sampling, get regular light pdf,
       * and compute weight with respect to BSDF pdf */
      float mis_weight = power_heuristic(prd.state.ray_pdf, emi.ls.pdf);
      lamp_L *= mis_weight;
    }

    path_radiance_accum_emission(lamp_L);
  }
}


 void kernel_path_lamp_emission(in Ray ray,in Intersection isect)
{
  PROFILING_INIT(kg, PROFILING_INDIRECT_EMISSION);

#ifdef _LAMP_MIS_
  if ( bool(kernel_data.integrator.use_lamp_mis) && !bool(prd.state.flag & PATH_RAY_CAMERA)) {
    /* ray starting from previous non-transparent bounce */
    Ray light_ray;

    light_ray.P = ray.P - prd.state.ray_t * ray.D;
    prd.state.ray_t += isect.t;
    light_ray.D = ray.D;
    light_ray.t = prd.state.ray_t;
    light_ray.time = ray.time;
    light_ray.dD = ray.dD;
    light_ray.dP = ray.dP;
    
    /* intersect with lamp */
    indirect_lamp_emission(light_ray);
  }
#endif /* __LAMP_MIS__ */
}


#define getSC() SC(emi.esd.alloc_offset)


void shader_prepare_closures()
{
  /* We can likely also do defensive sampling at deeper bounces, particularly
   * for cases like a perfect mirror but possibly also others. This will need
   * a good heuristic. */
  if (prd.state.bounce + prd.state.transparent_bounce == 0 &&  emi.esd.num_closure > 1) {

    int it_begin = emi.esd.alloc_offset;

    float sum = 0.0f;
    for (int i = 0; i < emi.esd.num_closure; i++) { 
      if (CLOSURE_IS_BSDF_OR_BSSRDF(getSC().type)) {
        sum += getSC().sample_weight;
      }
      emi.esd.alloc_offset = getSC().next;
    }
    emi.esd.alloc_offset = it_begin;

    for (int i = 0; i < sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(getSC().type)) {
        getSC().sample_weight = max(getSC().sample_weight, 0.125f * sum);
      }
      emi.esd.alloc_offset = getSC().next;
    }
    emi.esd.alloc_offset = it_begin;
  }

}


void main()
{


Ray ray;
ray.P = vec4(gl_WorldRayOriginNV, 0.0);
ray.D = vec4(gl_WorldRayDirectionNV, 0.0);
ray.t = gl_HitTNV;
Intersection isect;
isect.t      = gl_HitTNV;
isect.u      = (1.0 - attribs.x) - attribs.y;
isect.v      = attribs.x;
isect.prim   = gl_PrimitiveID;
isect.object = 0;
isect.type   = int(push.data_ptr._prim_type.data[gl_PrimitiveID]);

set_args_PathState()

kernel_path_lamp_emission(ray, isect);
shader_setup_from_ray(isect, ray);

/* Evaluate shader.*/
shader_eval_surface(prd.state.flag);
shader_prepare_closures();



    /* Apply shadow catcher, holdout, emission. 
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

#    ifdef _OBJECT_MOTION_
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

        executeCallableNV(LIGHT_SAMPLE, 0);
        
        if (double_pdf) {
            ls_pdf *= 2.0f;
        };

        ///has_emission = direct_emission(light_ray, L_light, is_lamp, terminate);
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

   executeCallableNV(LIGHT_SAMPLE, 0);
   int idx = atomicAdd(counter[0],1);
   ls_shader       =   intBitsToFloat(int(12345));
   SC(idx).next    =   floatBitsToInt(ls_shader);
    
    // 
    prd.throughput = vec4(0.2,0.4,0.5,1.);

#else



#endif

#endif /* __EMISSION__ */




//kernel_path_surface_bounce


}

