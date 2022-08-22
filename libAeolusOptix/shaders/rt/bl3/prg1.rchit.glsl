#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_NV_shader_sm_builtins: enable
#extension GL_KHR_shader_subgroup_basic : enable
#extension GL_KHR_shader_subgroup_ballot : enable
#extension GL_EXT_debug_printf : enable
#pragma use_vulkan_memory_model

#include "kernel_compat_vulkan.h.glsl"
#define ENABLE_PROFI 
#include "kernel/_kernel_types.h.glsl"


#define SET_AS     0
#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#define PUSH_POOL_SC
#include "kernel/kernel_globals.h.glsl"

#define RPL_TYPE_RGEN_IN

#define CD_TYPE0_OUT arg
#define CD_TYPE1_OUT sd
#define SHADOW_CALLER
#include "kernel/payload.glsl"

hitAttributeNV vec2 attribs;
#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_differential.h.glsl"
#include "kernel/kernel_montecarlo.h.glsl"

#include "kernel/bvh/bvh_utils.h.glsl"
#include "kernel/geom/geom_object.h.glsl"
#include "kernel/geom/geom_triangle.h.glsl"
//#undef _INTERSECTION_REFINE_
#include "kernel/geom/geom_triangle_intersect.h.glsl"
#include "kernel/geom/geom_attribute.h.glsl"
#include "kernel/geom/geom_motion_triangle.h.glsl"
#include "kernel/closure/emissive.h.glsl"
#include "kernel/kernel_light.h.glsl"
#include "kernel/kernel_light_background.h.glsl"

#include "kernel/kernel_shadow.h.glsl"
#include "kernel/kernel_path_state.h.glsl"
#include "kernel/kernel_accumulate.h.glsl"

#include "kernel/_kernel_shader.h.glsl"
#include "kernel/kernel_emission.h.glsl"
#include "kernel/kernel_passes.h.glsl"
#include "kernel/kernel_indirect_background.h.glsl"
#include "kernel/kernel_path_surface.h.glsl"

#define PATH_CALLER
#include "kernel/kernel_path.h.glsl"

int     gN = 0;
void main()
{

#ifdef ENABLE_PROFI
  PROFI_IDX  = atomicAdd(counter[PROFI_ATOMIC],1);
  PROFI_HIT_IDX(gl_LaunchIDNV.x,gl_LaunchIDNV.y,arg.state.rng_hash, float(gl_PrimitiveID) );
#endif

PROFI_DATA_678(gl_SMIDNV,gl_WarpIDNV,gl_SubgroupInvocationID);
sd.atomic_offset  =  int(( ( gl_SMIDNV *  gl_WarpsPerSMNV  + gl_WarpIDNV ) * gl_SubgroupSize  +  gl_SubgroupInvocationID ) * MAX_CLOSURE);
arg.state  = prd.state;
uvec2 xy =   gl_LaunchIDNV.xy;


uint visibility =  floatBitsToUint(prd.throughput.x);prd.throughput.x = 1.;


Ray ray;
ray.P = vec4(gl_WorldRayOriginNV, 0.0);
ray.D = vec4(gl_WorldRayDirectionNV, 0.0);
ray.t = prd.throughput.z;prd.throughput.z = 1.;
getARG_RGEN(ray);
isect.t      = gl_HitTNV;
isect.u      = (1.0 - attribs.x) - attribs.y;
isect.v      = attribs.x;
isect.prim   = gl_PrimitiveID + gl_InstanceCustomIndexNV;
isect.object = -1;
isect.type   = int(push.data_ptr._prim_type.data[isect.prim]);
bool isMiss = false;

gN = 0;

while(true){

          kernel_path_lamp_emission(ray,isect);
          if(isMiss){
            kernel_path_background(ray);
            break;
          }
          if (path_state_ao_bounce()) {
                prd_return(false);
          }
          shader_setup_from_ray(isect, ray);
          shader_eval_surface(arg.state.flag);      
          shader_prepare_closures();
          /* Apply shadow catcher, holdout, emission. */
          if (!kernel_path_shader_apply(ray)){     //   kg, &sd, state, ray, throughput, emission_sd, L, buffer)) {
            prd_return(false);
          }
          /* path termination. this is a strange place to put the termination, it's
            * mainly due to the mixed in MIS that we use. gives too many unneeded
            * shader evaluations, only need emission if we are going to terminate */
          float probability = path_state_continuation_probability();
          if (probability == 0.0f) {
            prd_return(false);
          }
          else if (probability != 1.0f) {
            float terminate =/* path_state_rng_1D(kg, state, PRNG_TERMINATE);*/
              path_rng_1D(
                arg.state.rng_hash, arg.state.sample_rsv, arg.state.num_samples, arg.state.rng_offset + int(PRNG_TERMINATE));
            if (terminate >= probability)
              prd_return(false);
              prd.throughput /= probability;
          }
          #ifdef _EMISSION_
              /* direct lighting */
              int all = int(arg.state.flag & int(PATH_RAY_SHADOW_CATCHER));
              kernel_path_surface_connect_light( 1.f,all);
          #endif
          
          if (!kernel_path_surface_bounce(ray))
          {
            prd_return(false);
          }
          uint  flags =   gl_RayFlagsTerminateOnFirstHitNV | gl_RayFlagsOpaqueNV ;//| gl_RayFlagsSkipClosestHitShaderNV;
          isMiss = false;
          traceNV(topLevelAS,  // acceleration structure
                  flags,       // rayFlags
                  0xFF,        // cullMask
                  0,           // sbtRecordOffset
                  0,           // sbtRecordStride
                  1,           // missIndex
                  ray.P.xyz,      // ray origin
                  0.f,        // ray min range
                  ray.D.xyz,      // ray direction
                  ray.t,        // ray max range
                  1            // payload (location = 1)
          );
        if(isect.t < 0){
          isMiss = true;
          isect.t      = ray.t;
        }else {
          isMiss = false;
        }
        {
          float3 L_sum = prd.L.emission;
          float sum = fabsf(L_sum.x) + fabsf(L_sum.y) + fabsf(L_sum.z);
          if (!isfinite_safe(sum)) {
                atomicAdd(counter[PROFI_ATOMIC - 5],int(1)); 
          }
        }

    gN+=1;
}

}
