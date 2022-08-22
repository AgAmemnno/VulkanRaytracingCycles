#ifndef _KERNEL_SHADOW_H_
#define _KERNEL_SHADOW_H_
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


CCL_NAMESPACE_BEGIN



#ifdef SHADOW_CALLER3
/* Special version which only handles opaque shadows. */
ccl_device bool shadow_blocked_opaque(
#ifdef _VOLUME_
                                      ShaderData *shadow_sd,
                                        inout float3 shadow,
                                      
#endif
                                       const uint visibility
)
{
      // cpu const bool blocked = scene_intersect(kg, ray, visibility & PATH_RAY_SHADOW_OPAQUE, isect);
      PLYMO_ISECT_SET(GSD.atomic_offset,0,64,visibility,0);
      traceNV(
         topLevelAS,      // acceleration structure
         gl_RayFlagsSkipClosestHitShaderNV,        // rayFlags
         0xFF,             // cullMask
         1,  // sbtRecordOffset
         0,                // sbtRecordStride
         1,   // missIndex
         GARG.ray.P.xyz,        // ray origin
          0.f,             // ray min range
         GARG.ray.D.xyz,        // ray direction
         GARG.ray.t,            // ray max range
         RPL_TYPE_ISECT     // payload location
      );


#ifdef _VOLUME_
  if (!blocked && state->volume_stack[0].shader != SHADER_NONE) {
    /* Apply attenuation from current volume shader. */
    kernel_volume_shadow(kg, shadow_sd, state, ray, shadow);
  }
#endif


#ifdef  WITH_STAT_ALL
          if(!(isect.type== PRIMITIVE_NONE))CNT_ADD(CNT_shadow_blocked);
          #ifdef shadow_blocked_ray_P
          STAT_DUMP_f3(shadow_blocked_ray_P, GARG.ray.P);
          STAT_DUMP_u1(shadow_blocked_numhits, PLYMO_ISECT_get_numhits);
          #endif
#endif

  TRACE_RET_TERM 
}

ccl_device_inline bool shadow_blocked( inout float3 shadow)
{
  shadow = make_float3(1.0f, 1.0f, 1.0f);
  /* Some common early checks.
#if !defined(__KERNEL_OPTIX__)

   * Avoid conditional trace call in OptiX though, since those hurt performance there.
  
  if (ray->t == 0.0f) {
    return false;
  }
#endif
 */

  if (GARG.ray.t == 0.0f) {
    return false;
  }

#ifdef _SHADOW_TRICKS_
  const uint visibility = (bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER)) ? PATH_RAY_SHADOW_NON_CATCHER :
                                                                    PATH_RAY_SHADOW;
#else
  const uint visibility = PATH_RAY_SHADOW;
#endif
  /* Do actual shadow shading.
   * First of all, we check if integrator requires transparent shadows.
   * if not, we use simplest and fastest ever way to calculate occlusion.
   * Do not do this in OptiX to avoid the additional trace call.
   */
//#if !defined(_KERNEL_OPTIX_) || !defined(_TRANSPARENT_SHADOWS_)
  //Intersection isect;
#  ifdef _TRANSPARENT_SHADOWS_
  if (!bool(kernel_data.integrator.transparent_shadows))
#  endif
  {
    return shadow_blocked_opaque(visibility);
  }
//#endif

}



#endif



#define SHADOW_CALLER2
#define _SHADOW_RECORD_ALL_
#define _TRANSPARENT_SHADOWS_
#define  _KERNEL_GPU_



#ifdef SHADOW_CALLER2
#define SHADOW_STACK_MAX_HITS 64
#ifdef _TRANSPARENT_SHADOWS_
#ifdef _SHADOW_RECORD_ALL_

/// bvh.h


ccl_device_inline void sort_intersections(uint num_hits)
{
#  ifdef _KERNEL_GPU_
  /* Use bubble sort which has more friendly memory pattern on GPU. */
  bool swapped;
  int offset = int(PLYMO_ISECT_get_offset);
 
  do {
    swapped = false;
    for (int j = 0; j < num_hits - 1; ++j) {
      int i = offset + j;
      if ( IS(i).t > IS(i + 1).t) {
        Intersection tmp = IS(i);
        IS(i) = IS(i + 1);
        IS(i + 1) = tmp;
        swapped = true;
      }
    }
    --num_hits;
  } while (swapped);

#  else
  qsort(hits, num_hits, sizeof(Intersection), intersections_compare);
#  endif
}
ccl_device bool shadow_blocked_opaque(
#ifdef _VOLUME_
                                      ShaderData *shadow_sd,
                                        inout float3 shadow,
                                      
#endif
                                       const uint visibility
)
{
      // cpu const bool blocked = scene_intersect(kg, ray, visibility & PATH_RAY_SHADOW_OPAQUE, isect);
      PLYMO_ISECT_SET(GSD.atomic_offset,0,64,visibility,0);
      traceNV(
         topLevelAS,      // acceleration structure
         gl_RayFlagsSkipClosestHitShaderNV,        // rayFlags
         0xFF,             // cullMask
         1,  // sbtRecordOffset
         0,                // sbtRecordStride
         1,   // missIndex
         GARG.ray.P.xyz,        // ray origin
          0.f,             // ray min range
         GARG.ray.D.xyz,        // ray direction
         GARG.ray.t,            // ray max range
         RPL_TYPE_ISECT     // payload location
      );


#ifdef _VOLUME_
  if (!blocked && state->volume_stack[0].shader != SHADER_NONE) {
    /* Apply attenuation from current volume shader. */
    kernel_volume_shadow(kg, shadow_sd, state, ray, shadow);
  }
#endif


#ifdef  WITH_STAT_ALL
          if(!(isect.type== PRIMITIVE_NONE))CNT_ADD(CNT_shadow_blocked);
          #ifdef shadow_blocked_ray_P
          STAT_DUMP_f3(shadow_blocked_ray_P, GARG.ray.P);
          STAT_DUMP_u1(shadow_blocked_numhits, PLYMO_ISECT_get_numhits);
          #endif
#endif

  TRACE_RET_TERM 
}

bool scene_intersect_shadow_all(
                                                     in uint visibility,
                                                     in uint max_hits)
{


      PLYMO_ISECT_SET(GSD.atomic_offset,0,max_hits,visibility,0);
      traceNV(
         topLevelAS,      // acceleration structure
         gl_RayFlagsSkipClosestHitShaderNV,        // rayFlags
         0xFF,             // cullMask
         1,  // sbtRecordOffset
         0,                // sbtRecordStride
         1,   // missIndex
         GARG.ray.P.xyz,        // ray origin
          0.f,             // ray min range
         GARG.ray.D.xyz,        // ray direction
         GARG.ray.t,            // ray max range
         RPL_TYPE_ISECT     // payload location
      );

   
#ifdef _VOLUME_
  if (!blocked && state->volume_stack[0].shader != SHADER_NONE) {
    /* Apply attenuation from current volume shader. */
    kernel_volume_shadow(kg, shadow_sd, state, ray, shadow);
  }
#endif

#ifdef  WITH_STAT_ALL
          if(!(isect.object == PRIMITIVE_NONE))CNT_ADD(CNT_shadow_blocked);
          #ifdef shadow_blocked_ray_P
          STAT_DUMP_f3(shadow_blocked_ray_P, GARG.ray.P);
          STAT_DUMP_u1(shadow_blocked_numhits, PLYMO_ISECT_get_numhits);
          #endif
#endif

 TRACE_RET_TERM

}




/* Attenuate throughput accordingly to the given intersection event.
 * Returns true if the throughput is zero and traversal can be aborted.
 */
bool shadow_handle_transparent_isect(

#ifdef _VOLUME_
                                                            ccl_addr_space PathState *volume_state,
#endif
                                                            int   is,
                                                            inout float3 throughput)
{
#ifdef _VOLUME_
  /* Attenuation between last surface and next surface. */
  if (volume_state->volume_stack[0].shader != SHADER_NONE) {
    Ray segment_ray = *ray;
    segment_ray.t = isect->t;
    kernel_volume_shadow(kg, shadow_sd, volume_state, &segment_ray, throughput);
  }
#endif
  /* Setup shader data at surface. */
  ShaderData cacheSD = GSD;
  GISECT        =   IS(is);
  GSD.geometry  =  int(GISECT.type);
  GSD.type      = int(kernel_tex_fetch(_prim_type, GISECT.prim));
  GISECT.type   = GSD.type;

  shader_setup_from_ray(GARG.ray);
 
  /* Attenuation from transparent surface. */
#ifdef  WITH_STAT_ALL
          #ifdef shadow_handle_transparent_isect_flag
          STAT_DUMP_u1(shadow_handle_transparent_isect_flag,GSD.flag);
          #endif
#endif

  if (!bool(GSD.flag & SD_HAS_ONLY_VOLUME)) {
    path_state_modify_bounce(true);
    shader_eval_surface(PATH_RAY_SHADOW);
    path_state_modify_bounce(false);
    throughput *= shader_bsdf_transparency();
  }
  /* Stop if all light is blocked. */
  if (is_zero(throughput)) {
    GSD = cacheSD;
    return true;
  }
#ifdef _VOLUME_
  /* Exit/enter volume. */
  kernel_volume_stack_enter_exit(kg, shadow_sd, volume_state->volume_stack);
#endif
  GSD = cacheSD;
  return false;
}

ccl_device bool shadow_blocked_transparent_all_loop(
                                                    in uint visibility,
                                                    in uint max_hits,
                                                    inout float3 shadow)
{
  /* Intersect to find an opaque surface, or record all transparent
   * surface hits.
   */

  const bool blocked = scene_intersect_shadow_all( visibility, max_hits);
#    ifdef _VOLUME_
#      ifdef __KERNEL_OPTIX__
  VolumeState &volume_state = kg->volume_state;
#      else
  VolumeState volume_state;
#      endif
#    endif
  /* If no opaque surface found but we did find transparent hits,
   * shade them.
   */


  uint num_hits = PLYMO_ISECT_get_numhits;
  if ( !blocked && num_hits > 0) {
    float3 throughput = make_float3(1.0f, 1.0f, 1.0f);
    float3 Pend = GARG.ray.P + GARG.ray.D * GARG.ray.t;
    float last_t = 0.0f;
    int bounce = GARG.state.transparent_bounce;
    //Intersection *isect = hits;
     int is =  int(PLYMO_ISECT_get_offset);
#    ifdef _VOLUME_
#      ifdef __SPLIT_KERNEL__
    ccl_addr_space
#      endif
        PathState *ps = shadow_blocked_volume_path_state(kg, &volume_state, state, sd, ray);
#    endif

    sort_intersections(num_hits);
    for (int hit = 0; hit < num_hits; hit++, is++) {
      /* Adjust intersection distance for moving ray forward. */
      float new_t = IS(is).t;
      IS(is).t -= last_t;
      /* Skip hit if we did not move forward, step by step raytracing
       * would have skipped it as well then.
       */
      if (last_t == new_t) {
        continue;
      }
      last_t = new_t;
      /* Attenuate the throughput. */
      if (shadow_handle_transparent_isect(
#    ifdef _VOLUME_
                                          ps,
#    endif
                                          is,
                                          throughput)) {
        return true;
      }
      /* Move ray forward. */
      GARG.ray.P = GSD.P;
      if (GARG.ray.t != FLT_MAX) {
        GARG.ray.D = normalize_len(Pend - GARG.ray.P, GARG.ray.t);
      }
      bounce++;
    }


#    ifdef _VOLUME_
    /* Attenuation for last line segment towards light. */
    if (ps->volume_stack[0].shader != SHADER_NONE) {
      kernel_volume_shadow(kg, shadow_sd, ps, ray, &throughput);
    }
#    endif


    shadow = throughput;
    return is_zero(throughput);

  }
#    ifdef _VOLUME_
  if (!blocked && state->volume_stack[0].shader != SHADER_NONE) {
    /* Apply attenuation from current volume shader. */
#      ifdef __SPLIT_KERNEL__
    ccl_addr_space
#      endif
        PathState *ps = shadow_blocked_volume_path_state(kg, &volume_state, state, sd, ray);
    kernel_volume_shadow(kg, shadow_sd, ps, ray, shadow);
  }
#    endif


  return blocked;
}

/* Here we do all device specific trickery before invoking actual traversal
 * loop to help readability of the actual logic.

ccl_device bool shadow_blocked_transparent_all(//Volume  ShaderData *sd, 
                                               in uint max_hits,
                                               float3 *shadow)
{
  // Invoke actual traversal. 
  return shadow_blocked_transparent_all_loop(
      kg, sd, shadow_sd, state, visibility, ray, hits, max_hits, shadow);
}
 */

#endif
#endif


ccl_device_inline bool shadow_blocked2( inout float3 shadow)
{
  shadow = make_float3(1.0f, 1.0f, 1.0f);


  if (GARG.ray.t == 0.0f) {
    return false;
  }

#ifdef _SHADOW_TRICKS_
  const uint visibility = (bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER)) ? PATH_RAY_SHADOW_NON_CATCHER :
                                                                    PATH_RAY_SHADOW;
#else
  const uint visibility = PATH_RAY_SHADOW;
#endif
  /* Do actual shadow shading.
   * First of all, we check if integrator requires transparent shadows.
   * if not, we use simplest and fastest ever way to calculate occlusion.
   * Do not do this in OptiX to avoid the additional trace call.
   */
//#if !defined(_KERNEL_OPTIX_) || !defined(_TRANSPARENT_SHADOWS_)
  //Intersection isect;
 

#  ifdef _TRANSPARENT_SHADOWS_
  if (!bool(kernel_data.integrator.transparent_shadows))
#  endif
  {
    return shadow_blocked_opaque(visibility);
  }
//#endif

}

ccl_device_inline bool shadow_blocked( inout float3 shadow)
{

  shadow = make_float3(1.0f, 1.0f, 1.0f);
  if (GARG.ray.t == 0.0f) {
    return false;
  }

#ifdef _SHADOW_TRICKS_
  const uint visibility = (bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER)) ? PATH_RAY_SHADOW_NON_CATCHER :
                                                                    PATH_RAY_SHADOW;
#else
  const uint visibility = PATH_RAY_SHADOW;
#endif



#ifdef _TRANSPARENT_SHADOWS_
#  ifdef _SHADOW_RECORD_ALL_
  /* For the transparent shadows we try to use record-all logic on the
   * devices which supports this.
   */
  const int transparent_max_bounce = kernel_data.integrator.transparent_max_bounce;
  /* Check transparent bounces here, for volume scatter which can do
   * lighting before surface path termination is checked.
   */
  if (GSTATE.transparent_bounce >= transparent_max_bounce) {
    return true;
  }
  uint max_hits = transparent_max_bounce - GSTATE.transparent_bounce - 1;
  max_hits = min(max_hits, SHADOW_STACK_MAX_HITS - 1);

 
  //return shadow_blocked_opaque(visibility);
  return  shadow_blocked_transparent_all_loop(visibility ,max_hits,shadow);

#  else  /* _SHADOW_RECORD_ALL_ */

  /* Fallback to a slowest version which works on all devices. */
  return shadow_blocked_transparent_stepped(
      kg, sd, shadow_sd, state, visibility, ray, &isect, shadow);
#  endif /* _SHADOW_RECORD_ALL_ */
#endif   /* _TRANSPARENT_SHADOWS_ */

}




#endif

CCL_NAMESPACE_END
#endif