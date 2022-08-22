#ifndef _SVM_SKY_H_
#define _SVM_SKY_H_
/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in_rsv compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in_rsv writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

CCL_NAMESPACE_BEGIN

#ifdef NODE_Caller


#define SVM_NODE_SKY_OUT_DIR(v4) {nio.data[0]  = v4.x;nio.data[1] = v4.y;nio.data[2] = v4.z;}
#define SVM_NODE_SKY_OUT_NODE(u4) {nio.data[4] = uintBitsToFloat(u4.x);nio.data[5] = uintBitsToFloat(u4.y);nio.data[6] = uintBitsToFloat(u4.z);nio.data[7] = uintBitsToFloat(u4.w);}

#define SVM_NODE_SKY_RET_FAC4  vec4(nio.data[0] ,nio.data[1] ,nio.data[2] ,nio.data[3])

ccl_device void svm_node_tex_sky(uint4 node, inout int offset)
{
  nio.offset = offset;
  nio.type   = CALLEE_SVM_TEX_SKY;
  SVM_NODE_SKY_OUT_DIR(stack_load_float3(node.y))
  SVM_NODE_SKY_OUT_NODE(node)

  EXECUTION_TEX;
  stack_store_float3(node.z, SVM_NODE_SKY_RET_FAC4);
  offset = nio.offset;
}


#endif



//#define NODE_Callee
#ifdef NODE_Callee


#include "kernel/kernel_vulkan_image.h.glsl"


//#include "kernel/kernel_projection.h.glsl"
ccl_device float2 direction_to_spherical(float3 dir)
{
  float theta = safe_acosf(dir.z);
  float phi = atan2f(dir.x, dir.y);

  return make_float2(theta, phi);
}
//#include "kernel/kernel_color.h.glsl"
ccl_device float3 xyz_to_rgb( float3 xyz)
{
  return make_float3(
                     dot3(kernel_data.film.xyz_to_r.xyz, xyz.xyz),
                     dot3(kernel_data.film.xyz_to_g.xyz, xyz.xyz),
                     dot3(kernel_data.film.xyz_to_b.xyz, xyz.xyz)
                     );
}


#ifndef _SVM_UTIL_H_
#define read_node(offset) kernel_tex_fetch(_svm_nodes, offset++)
#define read_node_float(f, offset)\
{\
  uint4 node = kernel_tex_fetch(_svm_nodes, offset);\
  f  = make_float4(_uint_as_float(node.x),_uint_as_float(node.y),_uint_as_float(node.z),_uint_as_float(node.w));\
  offset++;\
}
#endif



/* Sky texture */

ccl_device float sky_angle_between(float thetav, float phiv, float theta, float phi)
{
  float cospsi = sinf(thetav) * sinf(theta) * cosf(phi - phiv) + cosf(thetav) * cosf(theta);
  return safe_acosf(cospsi);
}

/*
 * "A Practical Analytic Model for Daylight"
 * A. J. Preetham, Peter Shirley, Brian Smits
 */
ccl_device float sky_perez_function(inout float lam[9],
 float theta, float gamma)
{
  float ctheta = cosf(theta);
  float cgamma = cosf(gamma);

  return (1.0f + lam[0] * expf(lam[1] / ctheta)) *
         (1.0f + lam[2] * expf(lam[3] * gamma) + lam[4] * cgamma * cgamma);
}

ccl_device float3 sky_radiance_preetham(
                                        float3 dir,
                                        float sunphi,
                                        float suntheta,
                                        float radiance_x,
                                        float radiance_y,
                                        float radiance_z,
                                        inout float config_x[9],
                                        inout float config_y[9],
                                        inout float config_z[9])
{
  /* convert vector to spherical coordinates */
  float2 spherical = direction_to_spherical(dir);
  float theta = spherical.x;
  float phi = spherical.y;

  /* angle between sun direction and dir */
  float gamma = sky_angle_between(theta, phi, suntheta, sunphi);

  /* clamp theta to horizon */
  theta = min(theta, M_PI_2_F - 0.001f);

  /* compute xyY color space values */
  float x = radiance_y * sky_perez_function(config_y, theta, gamma);
  float y = radiance_z * sky_perez_function(config_z, theta, gamma);
  float Y = radiance_x * sky_perez_function(config_x, theta, gamma);

  /* convert to RGB */
  float3 xyz = xyY_to_xyz(x, y, Y);
  return xyz_to_rgb(xyz);
}

/*
 * "An Analytic Model for Full Spectral Sky-Dome Radiance"
 * Lukas Hosek, Alexander Wilkie
 */
ccl_device float sky_radiance_internal(inout float configuration[9],
 float theta, float gamma)
{
  float ctheta = cosf(theta);
  float cgamma = cosf(gamma);

  float expM = expf(configuration[4] * gamma);
  float rayM = cgamma * cgamma;
  float mieM = (1.0f + rayM) / powf((1.0f + configuration[8] * configuration[8] -
                                     2.0f * configuration[8] * cgamma),
                                    1.5f);
  float zenith = sqrtf(ctheta);

  return (1.0f + configuration[0] * expf(configuration[1] / (ctheta + 0.01f))) *
         (configuration[2] + configuration[3] * expM + configuration[5] * rayM +
          configuration[6] * mieM + configuration[7] * zenith);
}

ccl_device float3 sky_radiance_hosek(
                                     float3 dir,
                                     float sunphi,
                                     float suntheta,
                                     float radiance_x,
                                     float radiance_y,
                                     float radiance_z,
                                     inout float config_x[9],
                                     inout float config_y[9],
                                     inout float config_z[9])
{
  /* convert vector to spherical coordinates */
  float2 spherical = direction_to_spherical(dir);
  float theta = spherical.x;
  float phi = spherical.y;

  /* angle between sun direction and dir */
  float gamma = sky_angle_between(theta, phi, suntheta, sunphi);

  /* clamp theta to horizon */
  theta = min(theta, M_PI_2_F - 0.001f);

  /* compute xyz color space values */
  float x = sky_radiance_internal(config_x, theta, gamma) * radiance_x;
  float y = sky_radiance_internal(config_y, theta, gamma) * radiance_y;
  float z = sky_radiance_internal(config_z, theta, gamma) * radiance_z;

  /* convert to RGB and adjust strength */
  return xyz_to_rgb(make_float3(x, y, z)) * (M_2PI_F / 683);
}

/* Nishita improved sky model */
ccl_device float3 geographical_to_direction(float lat, float lon)
{
  return make_float3(cos(lat) * cos(lon), cos(lat) * sin(lon), sin(lat));
}



#define _interp(a, b, t)  ((a.xyz) + t * ((b) - (a)).xyz)

ccl_device float3 sky_radiance_nishita(
                                       float3 dir,
                                       inout float nishita_data[10],
                                       uint texture_id)
{
  /* definitions */
  float sun_elevation = nishita_data[6];
  float sun_rotation = nishita_data[7];
  float angular_diameter = nishita_data[8];
  float sun_intensity = nishita_data[9];
  bool sun_disc = (angular_diameter >= 0.0f);
  float3 xyz;
  /* convert dir to spherical coordinates */
  float2 direction = direction_to_spherical(dir);



  /* render above the horizon */
  if (dir.z >= 0.0f) {
    /* definitions */
    float3 sun_dir = geographical_to_direction(sun_elevation, sun_rotation + M_PI_2_F);
    float sun_dir_angle = precise_angle(dir, sun_dir);
    float half_angular = angular_diameter / 2.0f;
    float dir_elevation = M_PI_2_F - direction.x;


    /* if ray inside sun disc render it, otherwise render sky */
    if (sun_disc && sun_dir_angle < half_angular) {
      /* get 2 pixels data */
      vec3 pixel_bottom = vec3(nishita_data[0], nishita_data[1], nishita_data[2]);
      vec3 pixel_top =    vec3(nishita_data[3], nishita_data[4], nishita_data[5]);
      float y;

      /* sun interpolation */
      if (sun_elevation - half_angular > 0.0f) {
        if (sun_elevation + half_angular > 0.0f) {
          y = ((dir_elevation - sun_elevation) / angular_diameter) + 0.5f;
          xyz.rgb = _interp(pixel_bottom, pixel_top, y) * sun_intensity;
        }
      }
      else {
        if (sun_elevation + half_angular > 0.0f) {
          y = dir_elevation / (sun_elevation + half_angular);
          xyz.rgb = _interp(pixel_bottom, pixel_top, y) * sun_intensity;
        }
      }

      /* limb darkening, coefficient is 0.6f */
      float limb_darkening = (1.0f -
                              0.6f * (1.0f - sqrtf(1.0f - sqr(sun_dir_angle / half_angular))));
      xyz.rgb *= limb_darkening;
  
    }
    /* sky */
    else {
      /* sky interpolation */
      float x = (direction.y + M_PI_F + sun_rotation) / M_2PI_F;
      /* more pixels toward horizon compensation */
      float y = safe_sqrtf(dir_elevation / M_PI_2_F);
      if (x > 1.0f) {
        x -= 1.0f;
      }
      
      xyz = float4_to_float3(kernel_tex_image_interp(int(texture_id), x, y));

    }
   

  }
  /* ground */
  else {
    if (dir.z < -0.4f) {
      xyz = make_float3(0.0f, 0.0f, 0.0f);
    }
    else {
      /* black ground fade */
      float fade = 1.0f + dir.z * 2.5f;
      fade = sqr(fade) * fade;
      /* interpolation */
      float x = (direction.y + M_PI_F + sun_rotation) / M_2PI_F;
      if (x > 1.0f) {
        x -= 1.0f;
      }
    
      xyz = float4_to_float3(kernel_tex_image_interp(int(texture_id), x, -0.5)) * fade;
    }
  }

  /* convert to RGB */
   float3 rgb = xyz_to_rgb( xyz);

   return rgb;
  //return xyz_to_rgb( xyz);
}

ccl_device void svm_node_tex_sky()
{

  /* Load data */
  uint dir_offset = nio.node.y;
  uint out_offset = nio.node.z;
  int sky_model = int(nio.node.w);
  float4 data;
  float3 f;
  /* Preetham and Hosek share the same data */
  if (sky_model == 0 || sky_model == 1) {
    /* Define variables */
    float sunphi, suntheta, radiance_x, radiance_y, radiance_z;
    float config_x[9], config_y[9], config_z[9];

 
    read_node_float(data,nio.offset);
    sunphi   = data.x;
    suntheta = data.y;
    radiance_x = data.z;
    radiance_y = data.w;

    read_node_float(data,nio.offset);
    radiance_z = data.x;
    config_x[0] = data.y;
    config_x[1] = data.z;
    config_x[2] = data.w;

    read_node_float(data,nio.offset);
    config_x[3] = data.x;
    config_x[4] = data.y;
    config_x[5] = data.z;
    config_x[6] = data.w;

    read_node_float(data,nio.offset);
    config_x[7] = data.x;
    config_x[8] = data.y;
    config_y[0] = data.z;
    config_y[1] = data.w;

    read_node_float(data,nio.offset);
    config_y[2] = data.x;
    config_y[3] = data.y;
    config_y[4] = data.z;
    config_y[5] = data.w;

    read_node_float(data,nio.offset);
    config_y[6] = data.x;
    config_y[7] = data.y;
    config_y[8] = data.z;
    config_z[0] = data.w;

   read_node_float(data,nio.offset);
    config_z[1] = data.x;
    config_z[2] = data.y;
    config_z[3] = data.z;
    config_z[4] = data.w;

    read_node_float(data,nio.offset);
    config_z[5] = data.x;
    config_z[6] = data.y;
    config_z[7] = data.z;
    config_z[8] = data.w;

    /* Compute Sky */
    if (sky_model == 0) {
      f = sky_radiance_preetham(
                                nio.dir,
                                sunphi,
                                suntheta,
                                radiance_x,
                                radiance_y,
                                radiance_z,
                                config_x,
                                config_y,
                                config_z);
    }
    else {
      f = sky_radiance_hosek(
                             nio.dir,
                             sunphi,
                             suntheta,
                             radiance_x,
                             radiance_y,
                             radiance_z,
                             config_x,
                             config_y,
                             config_z);
    }
  }
  /* Nishita */
  else {
    /* Define variables */
    float nishita_data[10];

    read_node_float(data, nio.offset);
    nishita_data[0] = data.x;
    nishita_data[1] = data.y;
    nishita_data[2] = data.z;
    nishita_data[3] = data.w;

    read_node_float(data,  nio.offset);
    nishita_data[4] = data.x;
    nishita_data[5] = data.y;
    nishita_data[6] = data.z;
    nishita_data[7] = data.w;

     read_node_float(data,  nio.offset);
    nishita_data[8] = data.x;
    nishita_data[9] = data.y;
    uint texture_id = _float_as_uint(data.z);

    /* Compute Sky */
    f = sky_radiance_nishita(nio.dir, nishita_data, texture_id);
  }

  SVM_NODE_SKY_RET_FAC4(f)

}


#endif
CCL_NAMESPACE_END



#endif