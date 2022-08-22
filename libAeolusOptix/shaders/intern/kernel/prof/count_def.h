//counting
#define CNT_MISS 0
#define CNT_HIT  1
//rec  2 ~ 31
#define CNT_REC  2
#define CNT_indirect_lamp_emission 32
#define CNT_AO_BOUNCE 33
#define CNT_sd_N 34
#define CNT_shader_prepare_closures 35
#define CNT_kernel_path_shader_apply_bg 36
#define CNT_kernel_path_shader_apply_shadow_transparency 37
#define CNT_kernel_path_shader_apply_blur 38
#define CNT_kernel_path_shader_apply_emission 39
#define CNT_direct_emission 40
#define CNT_shadow_blocked 41
#define CNT_has_emission 42
#define CNT_kernel_path_surface_bounce 43
#define CNT_direct_emissive_eval_constant 44
#define CNT_direct_emissive_eval_bg 45
#define CNT_direct_emissive_eval_sample 46

#define CNT_HIT_REC 1000

#ifndef CNT_READER
#define CNT_READER(c)
#endif
#define CNT_ALL { \
      CNT_READER(CNT_MISS);\
      CNT_READER(CNT_HIT);\
      for(int i=0;i<30;i++)CNT_READER( (CNT_REC+i) );\
      CNT_READER(CNT_indirect_lamp_emission);\
      CNT_READER(CNT_AO_BOUNCE );\
      CNT_READER(CNT_sd_N);\
      CNT_READER(CNT_shader_prepare_closures);\
      CNT_READER(CNT_kernel_path_shader_apply_bg);\
      CNT_READER(CNT_kernel_path_shader_apply_shadow_transparency);\
      CNT_READER(CNT_kernel_path_shader_apply_blur);\
      CNT_READER(CNT_kernel_path_shader_apply_emission);\
      CNT_READER(CNT_direct_emission);\
      CNT_READER(CNT_shadow_blocked);\
      CNT_READER(CNT_has_emission);\
      CNT_READER(CNT_kernel_path_surface_bounce);\
CNT_READER(CNT_direct_emissive_eval_constant);\
CNT_READER(CNT_direct_emissive_eval_bg);\
CNT_READER(CNT_direct_emissive_eval_sample);\
}
