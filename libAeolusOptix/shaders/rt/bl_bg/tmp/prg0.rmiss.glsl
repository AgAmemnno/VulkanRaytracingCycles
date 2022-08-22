#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable


#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#define GSD sd
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"

#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"
struct hitPayload
{
    float3 throughput;
    PathRadiance L;
    PathState state;
    ShaderDataTinyStorage sd;

};
layout(location = 0) rayPayloadInNV hitPayload prd;
bool shader_constant_emission_eval(int shader, inout float3 eval)
{
  int shader_index = int(shader & SHADER_MASK);
  int shader_flag = kernel_tex_fetch(_shaders, shader_index).flags;

  if (bool(shader_flag & SD_HAS_CONSTANT_EMISSION) ){
    eval = make_float3(kernel_tex_fetch(_shaders, shader_index).constant_emission[0],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[1],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[2]);
   
    return true;
  }

  return false;
}
ccl_device_noinline_cpu float3 indirect_background()
{

  int shader = kernel_data.background.surface_shader;


  float3 L = make_float3(0.0f, 0.0f, 0.0f);
  shader_constant_emission_eval(shader, L);
  return L;
};

void main(){

       prd.L.use_light_pass = 1234;
       prd.throughput =  make_float3(0.1f, 0.1f, 0.1f);//indirect_background();
}

