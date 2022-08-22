#ifndef _KERNEL_PATH_SURFACE_H_
#define _KERNEL_PATH_SURFACE_H_

#if defined(RPL_RGEN_OUT) && defined(CD_TYPE0_OUT)
/* path tracing: connect path directly to position on a light and add it to L */
ccl_device_inline void kernel_path_surface_connect_light(
    in float num_samples_adjust,
    in int sample_all_lights                           
)
{


  PROFILING_INIT(kg, PROFILING_CONNECT_LIGHT);
  GARG.type      = SURFACE_CALL_TYPE_connect_light;
  GARG.sd.type   = GSD.type;
  GARG.sd.flag   = GSD.flag;
  GARG.sd.time   = GSD.time; 
  GARG.sd.object = GSD.object;
  GARG.sd.P      = GSD.P;
  GARG.sd.N      = GSD.N; 
  GARG.sd.I      = GSD.I;
  GARG.sd.Ng     = GSD.Ng;
  GARG.sd.dI     = GSD.dI;
  GARG.sd.num_closure   = GSD.num_closure;
  GARG.sd.atomic_offset = GSD.atomic_offset;
  GARG.sd.alloc_offset  = GSD.alloc_offset;
  GARG.sd.lcg_state  = GSD.lcg_state;




 
#ifdef ENABLE_PROFI
  ply_L2Eval_profi_idx  = float(PROFI_IDX);

#endif

#ifdef  WITH_STAT_ALL
  ply_L2Eval_rec_num = float(rec_num);
#endif

#ifdef _EMISSION_
  /* sample illumination from lights to find path contribution */
  //BsdfEval L_light ccl_optional_struct_init;

  int num_lights = 0;
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
    uint lamp_rng_hash = GARG.state.rng_hash;
    bool double_pdf = false;
    bool is_mesh_light = false;
    bool is_lamp = false;

    if (bool(sample_all_lights)) {
      /* lamp sampling */
      is_lamp = i < kernel_data.integrator.num_all_lights;
      if (is_lamp) {
        if (UNLIKELY(light_select_reached_max_bounces(i, GARG.state.bounce))) {
          continue;
        }
        num_samples = ceil_to_int(num_samples_adjust * light_select_num_samples(i));
        num_all_lights = kernel_data.integrator.num_all_lights;
        lamp_rng_hash = cmj_hash( GARG.state.rng_hash, i);
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
      //Ray light_ray ccl_optional_struct_init;
      GARG.ray.t = 0.0f; /* reset ray */
#    ifdef _OBJECT_MOTION_
      GARG.ray.time = GARG.sd.time;
#    endif
      bool has_emission = false;

      if ( bool(kernel_data.integrator.use_direct_light) && bool( GARG.sd.flag & SD_BSDF_HAS_EVAL)) {
            float light_u, light_v;
            //path_branched_rng_2D(lamp_rng_hash, state, j, num_samples, int(PRNG_LIGHT_U), light_u, light_v);
            path_rng_2D(
                lamp_rng_hash,
                GARG.state.sample_rsv * num_samples + j,
                GARG.state.num_samples * num_samples,
                GARG.state.rng_offset + int(PRNG_LIGHT_U),
                light_u, light_v);


            float terminate  = 0.f;
            if (kernel_data.integrator.light_inv_rr_threshold > 0.0f) {
              #ifdef CALL_RNG
                path_rng_1D(lamp_rng_hash,GARG.state.sample_rsv * num_samples + j,GARG.state.num_samples *num_samples,GARG.state.rng_offset + int(PRNG_LIGHT_TERMINATE),terminate);
              #else
                terminate = path_rng_1D(lamp_rng_hash,GARG.state.sample_rsv * num_samples + j,GARG.state.num_samples *num_samples,GARG.state.rng_offset + int(PRNG_LIGHT_TERMINATE));
              #endif
            }
  

            /* only sample triangle lights */
            if (is_mesh_light && bool(double_pdf)) {
                    light_u = 0.5f * light_u;
            }

            ply_L2Eval_lamp = is_lamp ? i : -1;
            ply_L2Eval_light_uv_term_double = vec4(light_u,light_v,terminate ,float(double_pdf));

            EXECUTION_SURFACE;

            has_emission = bool(ply_L2Eval_light_hasemission);
            
      }


      float3 shadow;



      const bool blocked = shadow_blocked(shadow);

      // trace shadow ray    PROFI_ATOMIC_567(int(P.x*1000.f) ,int(P.y*1000.f) ,int(P.z*1000.f));


      if (has_emission) {

        if (!blocked) {
          //accumulate
          
          path_radiance_accum_light(
                                    shadow,
                                    num_samples_inv,
                                    is_lamp);

        }
        else {

          path_radiance_accum_total_light(GARG.state.flag, GTHR * num_samples_inv,  PLYMO_EVAL_sum_no_mis);
        }
#ifdef WITH_STAT_ALL 
        CNT_ADD(CNT_has_emission);
        #ifdef has_emission_nums
        //debugPrintfEXT("HAS Emission  XY %v2u \n", gl_LaunchIDNV.xy);
        STAT_DUMP_u1_add(has_emission_nums); 
        #endif
        #ifdef has_emission_shadow
        STAT_DUMP_f3(has_emission_shadow, shadow);
        STAT_DUMP_f3(has_emission_throughput, GTHR);
        #endif
#endif
      }
      
    }
  
  
  }
  GSD.lcg_state = GARG.sd.lcg_state;
#endif



}


#endif

#if defined(CD_TYPE0_IN) && defined(CD_TYPE1_OUT)

/* branched path tracing: connect path directly to position on one or more lights and add it to L
 */
ccl_device_noinline_cpu void kernel_branched_path_surface_connect_light()
{
#ifdef _EMISSION_
      bool has_emission = false;
      {
            LightSample ls;
            bool is_lamp = (ply_L2Eval_lamp ==-1)?false:true;
            vec4 param = ply_L2Eval_light_uv_term_double;
            if (light_sample( param.xy, GARG.sd.time, GARG.sd.P, GSTATE.bounce, ls)) {
            /* The sampling probability returned by lamp_light_sample assumes that all lights were
            * sampled. However, this code only samples lamps, so if the scene also had mesh lights,
            * the real probability is twice as high. */
                  if (bool(param.w)) {
                      ls.pdf *= 2.0f;
                  }
#ifdef  WITH_STAT_ALL
          CNT_ADD(CNT_direct_emission);
#endif
                 ply_L2Eval_light_hasemission = int(direct_emission(ls, is_lamp, param.z));

#ifdef  WITH_STAT_ALL
    #ifdef direct_emission_diffuse
          STAT_DUMP_f3(direct_emission_diffuse, PLYMO_EVAL_diffuse);
          STAT_DUMP_f3(direct_emission_sum_no_mis, PLYMO_EVAL_sum_no_mis);
          if (G_use_light_pass) {
              STAT_DUMP_f3(direct_emission_glossy, PLYMO_EVAL_glossy);
              STAT_DUMP_f3(direct_emission_transmission, PLYMO_EVAL_transmission);
          }
    #endif
#endif
            }
      }
#endif
}


#endif

#endif