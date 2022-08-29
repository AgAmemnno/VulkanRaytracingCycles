#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_NV_shader_sm_builtins: enable
#extension GL_KHR_shader_subgroup_basic : enable

#include "kernel_compat_vulkan.h.glsl"
#define ENABLE_PROFI
#include "kernel/_kernel_types.h.glsl"
#define TEST_MODE 


#define SET_AS 0
#define SET_WRITE_PASSES
#define SET_KERNEL 2
#define SET_KERNEL_PROF SET_KERNEL
#define PUSH_KERNEL_TEX
#define PUSH_POOL_SC
#define PUSH_POOL_IS
#include "kernel/kernel_globals.h.glsl"

#define RPL_RGEN_OUT
#define CD_TYPE0_OUT arg
#define CD_TYPE1_OUT sd
#define CD_TYPE2_OUT arg2
#define SHADOW_CALLER2
#ifdef _BVH_LOCAL_
#define LHIT_CALLER
#define MISS_THROUGH_CALLER
#endif
#include "kernel/payload.glsl"

#include "kernel/kernel_differential.h.glsl"



#define CALL_RNG
#define RNG_Caller


#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_montecarlo.h.glsl"
#include "kernel/kernel_projection.h.glsl"
#include "kernel/kernel_camera.h.glsl"

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

#include "kernel/kernel_path_common.h.glsl"

#include "kernel/kernel_path_state.h.glsl"
#include "kernel/kernel_accumulate.h.glsl"


#define CALL_SETUP
#include "kernel/_kernel_shader.h.glsl"
#include "kernel/kernel_shadow.h.glsl"
#include "kernel/kernel_emission.h.glsl"
#include "kernel/kernel_passes.h.glsl"
#include "kernel/kernel_indirect_background.h.glsl"
#include "kernel/kernel_path_surface.h.glsl"
#include "kernel/kernel_path_subsurface.h.glsl"
#define PATH_CALLER
#include "kernel/kernel_path.h.glsl"


  /* NOTE: Due to some vectorization code  non-finite origin point might
   * cause lots of false-positive intersections which will overflow traversal
   * stack.
   * This code is a quick way to perform early output, to avoid crashes in
   * such cases.
   * From production scenes so far it seems it's enough to test first element
   * only.
   * Scene intersection may also called with empty rays for conditional trace
   * calls that evaluate to false, so filter those out.
   */
#define  scene_intersect_valid(ray) (isfinite_safe(ray.P.x) && isfinite_safe(ray.D.x) && len_squared(ray.D) != 0.0f)

bool scene_intersect(in Ray ray,const uint visibility)
{

/*
#ifdef _KERNEL_OPTIX_
  uint p0 = 0;
  uint p1 = 0;
  uint p2 = 0;
  uint p3 = 0;
  uint p4 = visibility;
  uint p5 = PRIMITIVE_NONE;

  optixTrace(scene_intersect_valid(ray) ? kernel_data.bvh.scene : 0,
             ray->P,
             ray->D,
             0.0f,
             ray->t,
             ray->time,
             0xF,
             OPTIX_RAY_FLAG_NONE,
             0,  // SBT offset for PG_HITD
             0,
             0,
             p0,
             p1,
             p2,
             p3,
             p4,
             p5);

  isect->t = __uint_as_float(p0);
  isect->u = __uint_as_float(p1);
  isect->v = __uint_as_float(p2);
  isect->prim = p3;
  isect->object = p4;
  isect->type = p5;

  return p5 != PRIMITIVE_NONE;
#else
*/

  if(scene_intersect_valid(ray)){
    /*
    const uint gl_RayFlagsNoneNV = 0U;
    const uint gl_RayFlagsOpaqueNV = 1U;
    const uint gl_RayFlagsNoOpaqueNV = 2U;
    const uint gl_RayFlagsTerminateOnFirstHitNV = 4U;
    const uint gl_RayFlagsSkipClosestHitShaderNV = 8U;
    const uint gl_RayFlagsCullBackFacingTrianglesNV = 16U;
    const uint gl_RayFlagsCullFrontFacingTrianglesNV = 32U;
    const uint gl_RayFlagsCullOpaqueNV = 64U;
    const uint gl_RayFlagsCullNoOpaqueNV = 128U;
    */
      TRACE_SET_VISIBILITY(visibility);

      traceNV(
         topLevelAS,      // acceleration structure
         gl_RayFlagsNoneNV,        // rayFlags
         0xFF,             // cullMask
         TRACE_TYPE_MAIN,  // sbtRecordOffset
         0,                // sbtRecordStride
         MISS_TYPE_MAIN,   // missIndex
         ray.P.xyz,        // ray origin
          0.f,             // ray min range
         ray.D.xyz,        // ray direction
         ray.t,            // ray max range
         RPL_TYPE_ISECT     // payload location
      );

      if(GISECT.prim!=-1){
        GSD.geometry         =  GISECT.type;
        GISECT.type          =  int(kernel_tex_fetch(_prim_type, GISECT.prim));
        TRACE_RET_MAIN
      }
  }
  return false;
}

bool kernel_path_scene_intersect(in Ray ray){

    uint visibility = path_state_ray_visibility();

    if (path_state_ao_bounce()) {
        visibility = PATH_RAY_SHADOW;
        ray.t = kernel_data.background.ao_distance;
    }
   return scene_intersect(ray, visibility);

}

#define kernel_path_subsurface_init_indirect  ss_indirect.num_rays = 0

void main()
{  

#ifdef  WITH_STAT_ALL
    setDumpPixel();
#endif
#ifdef ENABLE_PROFI
  PROFI_IDX  = 12345;
  //PROFI_HIT_IDX(gl_LaunchIDNV.x,gl_LaunchIDNV.y,arg.state.rng_hash, float(gl_PrimitiveID) );
#endif

  path_radiance_init();

  Ray ray;
  int  sample_rsv = 0;
  uint rng_hash   = 0;
  //TODO Tile Sampling
  kernel_path_trace_setup(int(gl_LaunchIDNV.x),int(gl_LaunchIDNV.y),sample_rsv,  rng_hash, ray);
   
  if (ray.t == 0.0f)return;

  path_state_init(rng_hash,sample_rsv);

  /// global memory allocate SM divide
  GSD.atomic_offset  =  int(( ( gl_SMIDNV *  gl_WarpsPerSMNV  + gl_WarpIDNV ) * gl_SubgroupSize  +  gl_SubgroupInvocationID ) * MAX_CLOSURE);
  
  GTHR  = vec4(1.);

#  ifdef _SUBSURFACE_
    kernel_path_subsurface_init_indirect;
    while(true){
#  endif /* __SUBSURFACE__ */

      while(true){
      
      bool hit = kernel_path_scene_intersect(ray);

#ifdef  WITH_STAT_ALL
            if(rec_num ==0){
                if(!hit) CNT_ADD(CNT_MISS);
                else CNT_ADD(CNT_HIT);
            }
            CNT_ADD(CNT_REC +  rec_num );
            rec_num++;
#endif

      kernel_path_lamp_emission(ray);

      if (!hit) {
          kernel_path_background(ray);
          break;
      }
      else if (path_state_ao_bounce()) {
#ifdef  WITH_STAT_ALL
          CNT_ADD(CNT_AO_BOUNCE );
#endif
          break;
      }
    
          // Setup shader data.
          shader_setup_from_ray(ray);
          // Skip most work for volume bounding surface. 
          shader_eval_surface(GSTATE.flag);      
          shader_prepare_closures();
          // Apply shadow catcher, holdout, emission. 
          if (!kernel_path_shader_apply(ray)){     //   kg, &sd, state, ray, throughput, emission_sd, L, buffer)) {
            break;
          }

           // path termination. this is a strange place to put the termination, it's
          // mainly due to the mixed in MIS that we use. gives too many unneeded
          // shader evaluations, only need emission if we are going to terminate 
          float probability = path_state_continuation_probability();
          if (probability == 0.0f) {
             break;
          }
          else if (probability != 1.0f) {
            #ifndef CALL_RNG
                float terminate = path_rng_1D(GSTATE.rng_hash, GSTATE.sample_rsv, GSTATE.num_samples, GSTATE.rng_offset + int(PRNG_TERMINATE));
            #else
               float terminate;
               path_rng_1D(GSTATE.rng_hash, GSTATE.sample_rsv, GSTATE.num_samples, GSTATE.rng_offset + int(PRNG_TERMINATE),terminate);
            #endif

            if (terminate >= probability)break;
            GTHR /= probability;
          }

          #ifdef _SUBSURFACE_
                  /* bssrdf scatter to a different location on the same object, replacing
                  * the closures with a diffuse BSDF */
                  if (bool(GSD.flag & SD_BSSRDF)) {
                      if (kernel_path_subsurface_scatter(ray)) {
                          break;
                      }
                  }
          #endif /* __SUBSURFACE__ */
          #ifdef _EMISSION_
              // direct lighting 
              int all = int(GSTATE.flag & int(PATH_RAY_SHADOW_CATCHER));
              kernel_path_surface_connect_light( 1.f,all);

          #endif

          if (!kernel_path_surface_bounce(ray))
          {
            #ifdef  WITH_STAT_ALL
               CNT_ADD(CNT_kernel_path_surface_bounce);
            #endif
            break;
          }
          
          #ifdef  WITH_STAT_ALL
          #ifdef  kernel_path_surface_bounce_state_bounce
              {
                          uint bounce = uint(GSTATE.bounce);
                          STAT_DUMP_u1(kernel_path_surface_bounce_state_bounce,bounce);
                          STAT_DUMP_f3(kernel_path_surface_bounce_rayD,ray.D);
                        
            }
          #endif
          #endif
      }
#ifdef _SUBSURFACE_
        /* Trace indirect subsurface rays by restarting the loop. this uses less
         * stack memory than invoking kernel_path_indirect.
         */
        if (bool(ss_indirect.num_rays) ){
          kernel_path_subsurface_setup_indirect(ray);
#ifdef kernel_path_subsurface_setup_THR
   STAT_DUMP_f3(kernel_path_subsurface_setup_THR, GTHR);
#endif

        }
        else {
            break;
        }
    }
#endif /* __SUBSURFACE__ */


#ifdef  WITH_STAT_ALL
  STAT_CNT(CNT_HIT_REC,rec_num);
#endif
  kernel_write_result(buffer_ofs_null,sample_rsv);


}
