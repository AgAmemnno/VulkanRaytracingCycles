#define BP_GROUP0
#define BP_GROUP_SSS
#ifdef BP_GROUP0

///float3
#define indirect_lamp_emission_emission 0
#define indirect_lamp_emission_direct_emission 1 
#define indirect_lamp_emission_indirect  2
#define sd_N_f3  3
#define shader_prepare_closures_sum 4
#define kernel_path_shader_apply_bg 5
#define kernel_path_shader_apply_emission_emission 6
#define kernel_path_shader_apply_emission_direct_emission 7
#define kernel_path_shader_apply_emission_indirect 8
#define direct_emission_diffuse  9
#define direct_emission_glossy  10
#define direct_emission_transmission 11 
#define direct_emission_sum_no_mis 12 
#define has_emission_shadow 13 
#define has_emission_throughput 14
#define shader_bsdf_sample_eval 15
#define shader_bsdf_multi_eval_sum_no_mis 16
#define kernel_path_background_L 17
#define shadow_blocked_ray_P 18
#define kernel_path_surface_bounce_thr 19
#define kernel_path_surface_bounce_rayD 20

#define direct_emission_light_eval 21
#define shader_bsdf_sample_eval_diffuse 22
#define shader_bsdf_sample_eval_glossy 23
#define shader_bsdf_sample_eval_transmission 24
#define shader_bsdf_sample_eval_transparent 25
 
#define BP0_F3_OFS 26

///float
#define kernel_path_background_transparent 0
#define direct_emission_light_pdf 1
#define kernel_path_surface_bounce_pdf 2

#define BP0_F1_OFS 3


///uint
#define kernel_path_shader_apply_state_flag 0
#define kernel_path_surface_bounce_state_bounce 1
#define kernel_path_surface_bounce_flag 2
#define shader_bsdf_sample_eval_light_pass 3
#define has_emission_nums  4
#define shadow_blocked_numhits 5

#define BP0_U1_OFS 6

#else
#define BP0_F3_OFS 0
#define BP0_F1_OFS 0
#define BP0_U1_OFS 0
#endif

#ifdef BP_GROUP_SSS

#define scene_intersect_local_P        (BP0_F3_OFS)
#define scene_intersect_local_D        (BP0_F3_OFS+1)
#define subsurface_scatter_hit_Ng      (BP0_F3_OFS+2)
#define subsurface_scatter_eval_disk   (BP0_F3_OFS+3)
#define shader_setup_from_subsurface_P (BP0_F3_OFS+4)
#define shader_setup_from_subsurface_I (BP0_F3_OFS+5)
#define kernel_path_surface_bounce_local_D (BP0_F3_OFS+6)
#define kernel_path_subsurface_setup_THR (BP0_F3_OFS+7)



#ifndef has_emission_shadow
#define has_emission_shadow (BP0_F3_OFS+8)
#define has_emission_throughput (BP0_F3_OFS+9)
#endif



#define scene_intersect_local_t (BP0_F1_OFS)


#ifndef has_emission_nums
#define has_emission_nums (BP0_U1_OFS)
#endif


#if (BP0_F3_OFS >= STAT_BUF_MAX) | (BP0_F1_OFS >= STAT_BUF_MAX) | (BP0_U1_OFS >= STAT_BUF_MAX)
 #error  "bp_def.h line::62 STAT AUX may be OVERFLOW."
#endif

#endif


