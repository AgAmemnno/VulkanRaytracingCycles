#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable

#extension GL_NV_shader_sm_builtins : enable
#extension GL_KHR_shader_subgroup_basic : enable
#extension GL_KHR_shader_subgroup_arithmetic : enable
#extension GL_KHR_shader_subgroup_vote :enable
#extension GL_KHR_shader_subgroup_ballot :enable
#include "kernel_compat_vulkan.h.glsl"

#define ENABLE_PROFI
#include "kernel/_kernel_types.h.glsl"
#define SET_AS 0
#define SET_KERNEL 2
#define SET_KERNEL_PROF SET_KERNEL
#define PUSH_KERNEL_TEX
#define NO_READ_ONLY
#include "kernel/kernel_globals.h.glsl"
SET_BG(4,inpu,outpu)




#define CD_TYPE1_OUT sd
#include "kernel/payload.glsl"

#include "kernel/kernel_projection.h.glsl"
#include "kernel/closure/emissive.h.glsl"
#define LCG_NO_USE
#include "kernel/_kernel_shader.h.glsl"



int    ofsY;
#define cond_cdf(i) push.data_ptr._light_background_conditional_cdf.data[i]
#define pixels(i) bgoutpu[i]

void genPixel()
{
   
    uint   idx   = gl_LaunchIDNV.x + gl_LaunchSizeNV.x*(gl_LaunchIDNV.y +  gl_LaunchSizeNV.y*gl_LaunchIDNV.z);
    uint   resY  = idx / kernel_data.background.map_res_x + uint(ofsY);


    if(resY >=kernel_data.background.map_res_y) return;
    uint   resX  = idx % kernel_data.background.map_res_x;


    //PathState state;
    //uint4 inp = bginpu[i];
    //float u = _uint_as_float(inp.x);
    //float v = _uint_as_float(inp.y);
    float u = (float(resX) + 0.5f) / kernel_data.background.map_res_x;
    float v = (float(resY) + 0.5f) / kernel_data.background.map_res_y;

  Ray ray;
  ray.P = make_float3(0.0f, 0.0f, 0.0f);
  ray.D = equirectangular_to_direction(u, v);
  ray.t = 0.0f;
#ifdef _CAMERA_MOTION_
  ray.time = 0.5f;
#endif

#ifdef _RAY_DIFFERENTIALS_
  differential3_zero(ray.dD);
  differential3_zero(ray.dP);
#endif

 shader_setup_from_background(ray);

 uint path_flag = 0; 
 shader_eval_surface( path_flag | PATH_RAY_EMISSION);

 float3 color = shader_background_eval();

 bgoutpu[idx] = make_float4(color.x, color.y, color.z, 0.0f);

 //bgoutpu[idx] = make_float4(1.,2.,3., 4.0f);
  
      
 memoryBarrierBuffer();

}

void background_cdf( int i)
{       
        int   gid      = i + ofsY;
        int   res_x    = int(kernel_data.background.map_res_x);
        int   res_y    = int(kernel_data.background.map_res_y);
        int cdf_width  = res_x + 1;

    /* Conditional CDFs (rows, U direction). */
        float  sin_theta = sinf(M_PI_F * (gid + 0.5f) / res_y);
        float3 env_color = pixels(i * res_x);
        float ave_luminance = average(env_color);

        cond_cdf(gid * cdf_width).x = ave_luminance * sin_theta;
        cond_cdf(gid * cdf_width).y = 0.0f;

        for (int j = 1; j < res_x; j++) {
            env_color = pixels(i * res_x + j);
            ave_luminance = average(env_color);

            cond_cdf(gid * cdf_width + j).x = ave_luminance * sin_theta;
            cond_cdf(gid * cdf_width + j).y = cond_cdf(gid * cdf_width + j - 1).y + cond_cdf(gid* cdf_width + j - 1).x / res_x;
        }

        float cdf_total = cond_cdf(gid * cdf_width + res_x - 1).y + cond_cdf(gid * cdf_width + res_x - 1).x / res_x;
        float cdf_total_inv = 1.0f / cdf_total;

        /* stuff the total into the brightness value for the last entry, because
         * we are going to normalize the CDFs to 0.0 to 1.0 afterwards */
        cond_cdf(gid * cdf_width + res_x).x = cdf_total;
        
        if (cdf_total > 0.0f)
            for (int j = 1; j < res_x; j++)
                cond_cdf(gid * cdf_width + j).y *= cdf_total_inv;

        cond_cdf(gid * cdf_width + res_x).y = 1.0f;
}

void background_sg_cdf( int gid)
{       
        int i     = gid - ofsY;
        int sgid  = int(gl_SubgroupInvocationID);
        int mxID  = int(subgroupMax(sgid)) + 1;


        int   res_x    = int(kernel_data.background.map_res_x);
        int   res_y    = int(kernel_data.background.map_res_y);
        int cdf_width  = res_x + 1;

    /* Conditional CDFs (rows, U direction). */
      float  sin_theta = sinf(M_PI_F * (gid + 0.5f) / res_y);

      float  x;
      float cum = 0.f;
      for (int j = 0; j < res_x; j+= mxID) {
        int idx = (j + sgid < res_x) ? j + sgid : -1 ;
        float3 env_color = (idx==-1) ? vec4(0): pixels(i * res_x + idx);
        float ave_luminance = average(env_color);
        x   = ave_luminance * sin_theta;
        int K    = (j + mxID <= res_x) ? mxID : res_x - j;
        float y  = 0.;
        for (int k = 0; k < K ;k++) {
             if(k == sgid){
                cond_cdf(gid * cdf_width + idx) = vec2(x,(y+ cum)/res_x);
             }
             y = (k >= sgid)? x:0;
             y = subgroupAdd(y);
        }
        cum += y;
      }
        
        
        
        float cdf_total     = cum / res_x;
        /* stuff the total into the brightness value for the last entry, because
         * we are going to normalize the CDFs to 0.0 to 1.0 afterwards */
      
        if (cdf_total > 0.0f){
            float cdf_total_inv = 1.0f / cdf_total;
             for (int j = 0; j < res_x; j+= mxID) {
                int idx = j + sgid;
                if(idx < res_x) {
                  cond_cdf(gid * cdf_width + idx).y *= cdf_total_inv;
                }
             }
        }

        if(subgroupElect()){
    
            cond_cdf(gid * cdf_width + res_x).x = cdf_total;
            cond_cdf(gid * cdf_width + res_x).y = 1.0f;
        }

}


void sg_test (int gid)
{       
        int sgid  = int(gl_SubgroupInvocationID);
        int mxID  = int(subgroupMax(sgid)) + 1;


        int   res_x    = int(kernel_data.background.map_res_x);
        int   res_y    = int(kernel_data.background.map_res_y);
        int cdf_width  = res_x + 1;

    /* Conditional CDFs (rows, U direction). */

      float  x;
      float cum = 0.f;
      for (int j = 0; j < res_x; j+= mxID) {
        int idx = ( (j + sgid) < res_x) ? j + sgid : -1 ;
        float3 env_color = (idx==-1) ? vec4(0): pixels(gid * res_x + idx);
        x  =  env_color.x;
        int   K    = (j + mxID <= res_x) ? mxID : res_x - j;
        float y  = 0.;
        for (int k = 0; k < K ;k++) {
             y = (k >= sgid)? x:0;
             y = subgroupAdd(y);
             if(k == sgid){
               int idx = j + sgid;
               cond_cdf(gid * cdf_width + idx) = vec2(x,(y+ cum));
             }
        }
        cum += y;
      }
      
}

void main(){

    int i  = counter[0];
    ofsY   = counter[1];
    if(i==0)genPixel();
    else if(i == 6){
      int   maxY   = counter[2] + ofsY;
      uint  gid    = 0; 
      bool  repri  = (gl_SubgroupInvocationID==0);
      while(true){
       if(repri)gid = atomicAdd(counter[500],1);
       gid = subgroupBroadcastFirst(gid);
       if(gid >= maxY)break;
       background_sg_cdf(int(gid));
       subgroupBarrier();
       subgroupMemoryBarrierBuffer();
      }
    }
    else if(i == 5){
         uint smid = gl_SMIDNV;
         uint wid  = gl_WarpIDNV;
         uint sgid = gl_SubgroupInvocationID;
         uint mxID = subgroupMax(sgid);
         if(subgroupElect()){
           float id = cond_cdf(smid*32 + wid).x;
           cond_cdf(smid*32 + wid).x = id + float(mxID + 1);
           float v = cond_cdf(smid*32 + wid).y;
           cond_cdf(smid*32 + wid).y = v + 1.f;
         }
         atomicAdd(counter[500+smid],1);

         int  idx   = int(gl_LaunchIDNV.x + gl_LaunchSizeNV.x*(gl_LaunchIDNV.y +  gl_LaunchSizeNV.y*gl_LaunchIDNV.z));
         if( (idx + ofsY) >= int(kernel_data.background.map_res_y)) return;
         int   gid      = idx + ofsY;
         int   res_x    = int(kernel_data.background.map_res_x);
         int   res_y    = int(kernel_data.background.map_res_y);
         for(int j =0;j<12;j++)
         cond_cdf(gid * ( res_x+1) + j ) = vec2(j,1.2345);
         //if(sgid == 0){
         //   debugPrintfEXT("  cap gl_SMCountNV %u gl_WarpsPerSMNV  %u    gl_SubgroupSize %u\n",gl_SMCountNV,gl_WarpsPerSMNV,gl_SubgroupSize);
         //}
    }
    else if(i == 7){
      uint gid =0; 
      int  maxY = ofsY;
      bool  repri = (gl_SubgroupInvocationID==0);
      if(repri){
          gid = atomicAdd(counter[500],1);
      }
      gid = subgroupBroadcastFirst(gid);
      if(gid >= maxY)return;
      sg_test(int(gid));
      subgroupBarrier();
      subgroupMemoryBarrierBuffer();
    }
    
    else if(i == 8){

      int  maxY   = counter[2];
      uint gid =0; 
      bool  repri  = (gl_SubgroupInvocationID==0);
      if(repri)gid = atomicAdd(counter[500],1);
      gid = subgroupBroadcastFirst(gid);
      if(gid >= maxY)return;
      background_sg_cdf(int(gid));
      subgroupBarrier();
      subgroupMemoryBarrierBuffer();
    }
    else {

      int  idx   = int(gl_LaunchIDNV.x + gl_LaunchSizeNV.x*(gl_LaunchIDNV.y +  gl_LaunchSizeNV.y*gl_LaunchIDNV.z));
      if( (idx + ofsY) >= int(kernel_data.background.map_res_y)) return;
      background_cdf(idx);

    } 
}
