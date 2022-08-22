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



#define sizeof_BsdfEval   4*(6*4 + 1)



struct hitPayload_
{
vec4 throughput;
PathRadiance L;
PathState state;
ShaderData            sd;
ShaderDataTinyStorage esd;
};



struct args_acc_light{
  int use_light_pass;
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 emission;
};
#define sizeof_acc_light 4*(1 + 4*4)


struct hitPayload0
{
int      state_flag;
float    state_ray_pdf;
uint     state_rng; // uint(rng_hash + rng_offset + uint(sample_rsv))
int         bounce;
Ray ray; //104
args_acc_light L; //68
};


layout(location = 0) rayPayloadInNV hitPayload_ prd;
layout(location = 0) callableDataNV hitPayload0 arg;
hitAttributeNV vec2 attribs;


void kernel_path_lamp_emission(in Ray ray,in Intersection isect)
{
  PROFILING_INIT(kg, PROFILING_INDIRECT_EMISSION);

#ifdef _LAMP_MIS_
  if ( bool(kernel_data.integrator.use_lamp_mis) && !bool( prd.state.flag & PATH_RAY_CAMERA)) {
    /* ray starting from previous non-transparent bounce */

    arg.ray.P = ray.P - prd.state.ray_t * ray.D;
    prd.state.ray_t += isect.t;
    arg.ray.D = ray.D;
    arg.ray.t = prd.state.ray_t;
    arg.ray.time = ray.time;
    arg.ray.dD = ray.dD;
    arg.ray.dP = ray.dP;
    
    arg.state_flag    = prd.state.flag;
    arg.state_ray_pdf = prd.state.ray_pdf;
    arg.state_rng     = prd.state.rng_hash + prd.state.rng_offset + uint(prd.state.sample_rsv);
    arg.bounce        = prd.state.bounce;

    /* intersect with lamp */
    executeCallableNV(2u, 0);

  }
#endif /* __LAMP_MIS__ */
}


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


kernel_path_lamp_emission(ray,isect);

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


}

