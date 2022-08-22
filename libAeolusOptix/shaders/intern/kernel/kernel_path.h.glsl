#ifndef _KERNEL_PATH_H_
#define _KERNEL_PATH_H_

#if defined(PATH_CALLER) && defined(GSTATE)
#include "kernel/kernel_emission.h.glsl"

#if defined(GSD) && defined(GLAD) && !defined(RMISS_BG) 

ccl_device_forceinline bool kernel_path_shader_apply(in Ray ray)
{

PROFILING_INIT(kg, PROFILING_SHADER_APPLY);
#ifdef  WITH_STAT_ALL
 #ifdef kernel_path_shader_apply_state_flag
    {
        uint flag = uint(GSTATE.flag);
        STAT_DUMP_u1(kernel_path_shader_apply_state_flag, flag);
    }
  #endif  
#endif

#ifdef _SHADOW_TRICKS_
  if ( bool(GSD.object_flag & SD_OBJECT_SHADOW_CATCHER) ) {
    /* object shadow catcher*/
    if (bool(GSTATE.flag & PATH_RAY_TRANSPARENT_BACKGROUND)) {
      GSTATE.flag |= int(PATH_RAY_SHADOW_CATCHER | PATH_RAY_STORE_SHADOW_INFO);
      float3 bg = make_float3(0.0f, 0.0f, 0.0f);
      if (!bool(kernel_data.background.transparent)) {

#ifdef  WITH_STAT_ALL
        CNT_ADD(CNT_kernel_path_shader_apply_bg);
#endif        
        bg = indirect_background(ray);//indirect_background(kg, emission_sd, state, NULL, ray);

#ifdef  WITH_STAT_ALL
    #ifdef kernel_path_shader_apply_bg
        STAT_DUMP_f3(kernel_path_shader_apply_bg,bg);
    #endif
#endif
      }
      path_radiance_accum_shadowcatcher( bg);
    }
    
  }
  else if (bool(GSTATE.flag & PATH_RAY_SHADOW_CATCHER)) {

#ifdef  WITH_STAT_ALL
        CNT_ADD(CNT_kernel_path_shader_apply_shadow_transparency);
#endif
    /* Only update transparency after shadow catcher bounce. */
    GLAD.shadow_transparency *= average(shader_bsdf_transparency());
 
  }
#endif /* _SHADOW_TRICKS_ */


#ifdef _TODO____
  /* holdout */
#ifdef _HOLDOUT_
  if (((sd->flag & SD_HOLDOUT) || (sd->object_flag & SD_OBJECT_HOLDOUT_MASK)) &&
      (state->flag & PATH_RAY_TRANSPARENT_BACKGROUND)) {
    const float3 holdout_weight = shader_holdout_apply(kg, sd);
    if (kernel_data.background.transparent) {
      L->transparent += average(holdout_weight * throughput);
    }
    if (isequal_float3(holdout_weight, make_float3(1.0f, 1.0f, 1.0f))) {
      return false;
    }
  }
#endif /* __HOLDOUT__ */
  /* holdout mask objects do not write data passes */

#endif
  kernel_write_data_passes();


   if (kernel_data.integrator.filter_glossy != FLT_MAX) {
    float blur_pdf = kernel_data.integrator.filter_glossy * GSTATE.min_ray_pdf;
    if (blur_pdf < 1.0f) {

        float ply_tmp  = GSD.randb_closure;
        int   ply_tmp2 = GSD.num_closure_left;
        GSD.num_closure_left = -1;
#ifdef  WITH_STAT_ALL
        CNT_ADD(CNT_kernel_path_shader_apply_blur);
        GSD.num_closure_left = -rec_num;
#endif
        GSD.randb_closure = blur_pdf;
        EXECUTION_SVM;
        GSD.randb_closure = ply_tmp;
        GSD.num_closure_left = ply_tmp2;
      }
  }

#ifdef _EMISSION_
  /* emission */
  if (bool(GSD.flag & SD_EMISSION)) {

#ifdef  WITH_STAT_ALL
     CNT_ADD(CNT_kernel_path_shader_apply_emission);
#endif

    float3 emission = indirect_primitive_emission(GSD.ray_length, GSTATE.flag, GSTATE.ray_pdf);
    path_radiance_accum_emission(GSTATE.flag,GSTATE.bounce, GTHR, emission);

#ifdef  WITH_STAT_ALL
#ifdef kernel_path_shader_apply_emission_emission
        STAT_DUMP_f3(kernel_path_shader_apply_emission_emission, GLAD.emission);
        if (G_use_light_pass) {
            STAT_DUMP_f3(kernel_path_shader_apply_emission_direct_emission,GLAD.direct_emission);
            STAT_DUMP_f3(kernel_path_shader_apply_emission_indirect, GLAD.indirect);
        }
#endif
#endif
  }
#endif /* __EMISSION__ */

  return true;

}
#endif


#if defined(GARG) && defined(GLAD) && defined(GTHR) && defined(GISECT)
void kernel_path_lamp_emission(in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_INDIRECT_EMISSION);

#ifdef _LAMP_MIS_
  if ( bool(kernel_data.integrator.use_lamp_mis) && !bool( GSTATE.flag & PATH_RAY_CAMERA)) {



    /* ray starting from previous non-transparent bounce */
    GARG.ray.P = ray.P - GSTATE.ray_t * ray.D;
    GSTATE.ray_t += GISECT.t;
    GARG.ray.D = ray.D;
    GARG.ray.t = GSTATE.ray_t;
    GARG.ray.time = ray.time;
    GARG.ray.dD = ray.dD;
    GARG.ray.dP = ray.dP;
    GARG.type = SURFACE_CALL_TYPE_indirect_lamp;

    /* intersect with lamp */
    GARG.use_light_pass = L_USE_LIGHT_PASS;
    GARG.L.emission = GLAD.emission;
    GARG.L.direct_emission = GLAD.direct_emission ;
    GARG.L.indirect = GLAD.indirect;
    GARG.L.path_total = GLAD.path_total;
    GARG.L.throughput = GTHR;

#ifdef ENABLE_PROFI
    ply_L2Eval_profi_idx  = float(PROFI_IDX);
#endif
#ifdef  WITH_STAT_ALL
    ply_L2Eval_rec_num     = float(rec_num);
    CNT_ADD(CNT_indirect_lamp_emission);
#endif

    EXECUTION_SURFACE;

    GLAD.emission = GARG.L.emission;
    GLAD.direct_emission = GARG.L.direct_emission ;
    GLAD.indirect = GARG.L.indirect;
    GLAD.path_total = GARG.L.path_total;
    GTHR = GARG.L.throughput;

#ifdef  WITH_STAT_ALL
   #ifdef indirect_lamp_emission_emission
        STAT_DUMP_f3(indirect_lamp_emission_emission, GLAD.emission);
   #endif
        if (G_use_light_pass) {
#ifdef indirect_lamp_emission_direct_emission
            STAT_DUMP_f3(indirect_lamp_emission_direct_emission, GLAD.direct_emission);
            STAT_DUMP_f3(indirect_lamp_emission_indirect, GLAD.indirect);
#endif
        }
#endif

  }
#endif /* __LAMP_MIS__ */
}

#endif

#if defined(GLAD) && defined(GTHR) 

ccl_device_forceinline void kernel_path_background(in Ray ray)
{
  /* eval background shader if nothing hit */
  if ( bool(kernel_data.background.transparent) && bool(GSTATE.flag & PATH_RAY_TRANSPARENT_BACKGROUND)) {
    GLAD.transparent += average(GTHR);

#ifdef _PASSES_
    if (!bool(kernel_data.film.light_pass_flag & PASSMASK(BACKGROUND)))
#endif /* __PASSES__ */
      return;
  }

  /* When using the ao bounces approximation, adjust background
   * shader intensity with ao factor. */
  if (path_state_ao_bounce()) {
    GTHR *= kernel_data.background.ao_bounces_factor;
  }

#ifdef _BACKGROUND_
  /* sample background shader */
  float3 L_background = indirect_background(ray);
  path_radiance_accum_background(L_background);
#endif /* __BACKGROUND__ */

#ifdef  WITH_STAT_ALL
 #ifdef kernel_path_background_L
    STAT_DUMP_f3(kernel_path_background_L, L_background);
#endif
#endif

}

#endif



#endif //PATH_CALLER

#ifdef PATH_CALLEE

#include "util/util_math_func.glsl"
#include "kernel/geom/geom_primitive.h.glsl"
#include "kernel/kernel_montecarlo.h.glsl"
//#include "kernel/kernel_accumulate.h.glsl"
#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_color.h.glsl"
#include "kernel/_kernel_shader.h.glsl"

void kernel_path_shader_apply(float blur_pdf){
    /* blurring of bsdf after bounces, for rays that have a small likelihood
   * of following this particular path (diffuse, rough glossy) */

    float blur_roughness = sqrtf(1.0f - blur_pdf) * 0.5f;
    shader_bsdf_blur(blur_roughness);
}

#endif //PATH_CALLEE


#endif