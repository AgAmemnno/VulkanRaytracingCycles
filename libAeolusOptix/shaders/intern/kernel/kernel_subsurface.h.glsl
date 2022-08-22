#ifndef _KERNEL_SUBSURFACE_H_
#define _KERNEL_SUBSURFACE_H_

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


#ifdef SSS_CALLEE

#include "kernel/closure/bssrdf.h.glsl"
CCL_NAMESPACE_BEGIN


#define NULL_LCG uint(-1)
#define  scene_intersect_local_valid(ray) (isfinite_safe(ray.P.x) && isfinite_safe(ray.D.x) && len_squared(ray.D) != 0.0f)
bool scene_intersect_local(
                                                int local_object,
                                                inout uint lcg_state,/* buffer ref */
                                                int max_hits)
{


  linfo2.max_hits = max_hits;
  linfo2.local_object = local_object;
  linfo2.num_hits = 0;
  linfo2.lcg_state = lcg_state;
  linfo2.offset = linfo.offset;

#ifdef  scene_intersect_local_P
    STAT_DUMP_f3(scene_intersect_local_P, ss_isect.ray.P);
    STAT_DUMP_f3(scene_intersect_local_D, ss_isect.ray.D);
    STAT_DUMP_f1(scene_intersect_local_t, ss_isect.ray.t);
#endif
  /// assertion if (local_isect) {local_isect.num_hits = 0;}  // Initialize hit count to zero
  if(scene_intersect_local_valid(ss_isect.ray)){
    traceNV(
         topLevelAS,      // acceleration structure
         gl_RayFlagsSkipClosestHitShaderNV,        // rayFlags
         0xFF,             // cullMask
         2,  // sbtRecordOffset
         0,                // sbtRecordStride
         2,   // missIndex
         ss_isect.ray.P.xyz,        // ray origin
          0.f,             // ray min range
         ss_isect.ray.D.xyz,        // ray direction
         ss_isect.ray.t,            // ray max range
         1       // payload location
    );

    return true;
  }
  return false;
}


ccl_device float3 volume_color_transmittance(float3 sigma, float t)
{
  return exp3(-sigma * t);
}
ccl_device float kernel_volume_channel_get(float3 value, int channel)
{
  return (channel == 0) ? value.x : ((channel == 1) ? value.y : value.z);
}

/* Volume Path */
ccl_device int kernel_volume_sample_channel(float3 albedo,
                                            float3 throughput,
                                            float rand,
                                            inout float3 pdf)
{
  /* Sample color channel proportional to throughput and single scattering
   * albedo, to significantly reduce noise with many bounce, following:
   *
   * "Practical and Controllable Subsurface Scattering for Production Path
   *  Tracing". Matt Jen-Yuan Chiang, Peter Kutz, Brent Burley. SIGGRAPH 2016. */
  float3 weights = fabs(throughput * albedo);
  float sum_weights = weights.x + weights.y + weights.z;
  float3 weights_pdf;

  if (sum_weights > 0.0f) {
    weights_pdf = weights / sum_weights;
  }
  else {
    weights_pdf = make_float3(1.0f / 3.0f, 1.0f / 3.0f, 1.0f / 3.0f);
  }

  pdf = weights_pdf;
  /* OpenCL does not support -> on float3, so don't use pdf->x. */
  if (rand < weights_pdf.x) {
    return 0;
  }
  else if (rand < weights_pdf.x + weights_pdf.y) {
    return 1;
  }
  else {
    return 2;
  }
}


/* Given cosine between rays, return probability density that a photon bounces
 * to that direction. The g parameter controls how different it is from the
 * uniform sphere. g=0 uniform diffuse-like, g=1 close to sharp single ray. */
ccl_device float single_peaked_henyey_greenstein(float cos_theta, float g)
{
  return ((1.0f - g * g) / safe_powf(1.0f + g * g - 2.0f * g * cos_theta, 1.5f)) *
         (M_1_PI_F * 0.25f);
};

ccl_device float3 henyey_greenstrein_sample(float3 D, float g, float randu, float randv, inout float pdf)
{
  /* match pdf for small g */
  float cos_theta;
  bool isotropic = fabsf(g) < 1e-3f;

  if (isotropic) {
    cos_theta = (1.0f - 2.0f * randu);
    if (!isNULL(pdf)){
      pdf = M_1_PI_F * 0.25f;
    }
  }
  else {
    float k = (1.0f - g * g) / (1.0f - g + 2.0f * g * randu);
    cos_theta = (1.0f + g * g - k * k) / (2.0f * g);
    if (!isNULL(pdf)){
      pdf = single_peaked_henyey_greenstein(cos_theta, g);
    }
  }

  float sin_theta = safe_sqrtf(1.0f - cos_theta * cos_theta);
  float phi = M_2PI_F * randv;
  float3 dir = make_float3(sin_theta * cosf(phi), sin_theta * sinf(phi), cos_theta);

  float3 T, B;
  make_orthonormals(D, T, B);
  dir = dir.x * T + dir.y * B + dir.z * D;
  return dir;

}


/* BSSRDF using disk based importance sampling.
 *
 * BSSRDF Importance Sampling, SIGGRAPH 2013
 * http://library.imageworks.com/pdfs/imageworks-library-BSSRDF-sampling.pdf
 */

ccl_device_inline float3 subsurface_scatter_eval(float disk_r, float r, bool all)
{
  /* this is the veach one-sample model with balance heuristic, some pdf
   * factors drop out when using balance heuristic weighting */
  float3 eval_sum = make_float3(0.0f, 0.0f, 0.0f);
  float pdf_sum = 0.0f;
  float sample_weight_inv = 0.0f;
  
  int it_begin = linfo.offset;

  if (!all) {
    float sample_weight_sum = 0.0f;
    GSD.alloc_offset = it_begin-1;
    for (int i = 0; i < GSD.num_closure; i++) {
      GSD.alloc_offset+=1;
      if (CLOSURE_IS_DISK_BSSRDF(getSC().type)) {
        sample_weight_sum += getSC().sample_weight;
      }
      
    }
    sample_weight_inv = 1.0f / sample_weight_sum;
  }
  GSD.alloc_offset = it_begin-1;
  for (int i = 0; i < GSD.num_closure; i++) {
    GSD.alloc_offset+=1;
    if (CLOSURE_IS_DISK_BSSRDF(getSC().type)) {
      /* in case of branched path integrate we sample all bssrdf's once,
       * for path trace we pick one, so adjust pdf for that */
      float sample_weight = (all) ? 1.0f : getSC().sample_weight * sample_weight_inv;
      /* compute pdf */
      float3 eval = bssrdf_eval(r);
      float pdf = bssrdf_pdf(disk_r);
      eval_sum += as_float3(getSC().weight) * eval;
      pdf_sum += sample_weight * pdf;
    }
  }
  return (pdf_sum > 0.0f) ? eval_sum / pdf_sum : make_float3(0.0f, 0.0f, 0.0f);
}

/* Subsurface scattering step, from a point on the surface to other
 * nearby points on the same object.
 */


ccl_device_inline int subsurface_scatter_disk(int scN,
                                              inout uint  lcg_state,
                                              float disk_u,
                                              float disk_v,
                                              bool all)
{
  /* pick random axis in local frame and point on disk */
  float3 disk_N, disk_T, disk_B;
  float pick_pdf_N, pick_pdf_T, pick_pdf_B;

  disk_N = GSD.Ng;
  make_orthonormals(disk_N, disk_T, disk_B);

  if (disk_v < 0.5f) {
    pick_pdf_N = 0.5f;
    pick_pdf_T = 0.25f;
    pick_pdf_B = 0.25f;
    disk_v *= 2.0f;
  }
  else if (disk_v < 0.75f) {
    float3 tmp = disk_N;
    disk_N = disk_T;
    disk_T = tmp;
    pick_pdf_N = 0.25f;
    pick_pdf_T = 0.5f;
    pick_pdf_B = 0.25f;
    disk_v = (disk_v - 0.5f) * 4.0f;
  }
  else {
    float3 tmp = disk_N;
    disk_N = disk_B;
    disk_B = tmp;
    pick_pdf_N = 0.25f;
    pick_pdf_T = 0.25f;
    pick_pdf_B = 0.5f;
    disk_v = (disk_v - 0.75f) * 4.0f;
  }

  /* sample point on disk */
  float phi = M_2PI_F * disk_v;
  float disk_height, disk_r;

  bssrdf_sample(scN,disk_u, disk_r, disk_height);

  float3 disk_P = (disk_r * cosf(phi)) * disk_T + (disk_r * sinf(phi)) * disk_B;

  
#ifdef _SPLIT_KERNEL_
  Ray ray_object = ss_isect->ray;
  Ray *ray = &ray_object;
#endif

  ss_isect.ray.P    = GSD.P + disk_N * disk_height + disk_P;
  ss_isect.ray.D    = -disk_N;
  ss_isect.ray.t    = 2.0f * disk_height;
  ss_isect.ray.dP   = GSD.dP;
  differential3_zero(ss_isect.ray.dD);
  ss_isect.ray.time = GSD.time;


  scene_intersect_local(  GSD.object, lcg_state, BSSRDF_MAX_HITS);

  int num_eval_hits = min(linfo2.num_hits, BSSRDF_MAX_HITS);
  int ISid          = linfo.offset-1;
  for (int hit = 0; hit < num_eval_hits; hit++) {
    ISid += 1;

    float3 hit_P;
    if (bool(GSD.type & PRIMITIVE_TRIANGLE)){
      hit_P = triangle_refine_local(ISid, ss_isect.ray);
    }
#ifdef _OBJECT_MOTION_
    else if (bool(GSD.type & PRIMITIVE_MOTION_TRIANGLE)){
      // TODO 
      //float3 verts[3];
      //motion_triangle_vertices(kg,
      //                         sd->object,
      //                         kernel_tex_fetch(__prim_index, ss_isect->hits[hit].prim),
      //                         sd->time,
      //                         verts);
      //hit_P = motion_triangle_refine_local(kg, sd, &ss_isect->hits[hit], ray, verts);
    }
#endif 
    else {
      float3 v = make_float3(0.0f, 0.0f, 0.0f);
      PLYMO_IS_WEIGHT(hit,v);
      continue;
    }
    //float3 hit_Ng = ss_isect->Ng[hit];
    float3 hit_Ng;
    LISECT_GET_NG(hit_Ng,ISid);
    if (!OBJECT_IS_NONE(IS(ISid).object)) {
      object_normal_transform(hit_Ng);
    }
#ifdef subsurface_scatter_hit_Ng
       STAT_DUMP_f3(subsurface_scatter_hit_Ng, hit_Ng);
#endif

    float pdf_N = pick_pdf_N * fabsf(dot(disk_N, hit_Ng));
    float pdf_T = pick_pdf_T * fabsf(dot(disk_T, hit_Ng));
    float pdf_B = pick_pdf_B * fabsf(dot(disk_B, hit_Ng));
    float w = pdf_N / (sqr(pdf_N) + sqr(pdf_T) + sqr(pdf_B));
    if (linfo.num_hits > BSSRDF_MAX_HITS) {
      w *= float(linfo.num_hits) / float(BSSRDF_MAX_HITS);
    }
    float r = length(hit_P.xyz - GSD.P.xyz);

    float3 eval = subsurface_scatter_eval(disk_r, r, all) * w;
    PLYMO_IS_WEIGHT(hit,eval);
#ifdef subsurface_scatter_eval_disk
       STAT_DUMP_f3(subsurface_scatter_eval_disk,eval);
#endif
  }

#ifdef _SPLIT_KERNEL_
  ss_isect->ray = *ray;
#endif
   
  return num_eval_hits;
}



/* Random walk subsurface scattering.
 *
 * "Practical and Controllable Subsurface Scattering for Production Path
 *  Tracing". Matt Jen-Yuan Chiang, Peter Kutz, Brent Burley. SIGGRAPH 2016. */

ccl_device void subsurface_random_walk_remap(in float A,
                                             in float d,
                                             inout float sigma_t,
                                             inout float sigma_s)
{
  /* Compute attenuation and scattering coefficients from albedo. */
  const float a = 1.0f - expf(A * (-5.09406f + A * (2.61188f - A * 4.31805f)));
  const float s = 1.9f - A + 3.5f * sqr(A - 0.8f);
  sigma_t = 1.0f / fmaxf(d * s, 1e-16f);
  sigma_s = sigma_t * a;
}

ccl_device void subsurface_random_walk_coefficients(int scN,inout float3 sigma_t,
                                                    inout float3 sigma_s,
                                                    inout float3 weight)
{

  const float3 A = Bssrdf_albedo(_getSC(scN));
  const float3 d = Bssrdf_radius(_getSC(scN));
  float sigma_t_x, sigma_t_y, sigma_t_z;
  float sigma_s_x, sigma_s_y, sigma_s_z;

  subsurface_random_walk_remap(A.x, d.x, sigma_t_x, sigma_s_x);
  subsurface_random_walk_remap(A.y, d.y, sigma_t_y, sigma_s_y);
  subsurface_random_walk_remap(A.z, d.z, sigma_t_z, sigma_s_z);

  sigma_t = make_float3(sigma_t_x, sigma_t_y, sigma_t_z);
  sigma_s = make_float3(sigma_s_x, sigma_s_y, sigma_s_z);

  /* Closure mixing and Fresnel weights separate from albedo. */
  weight = safe_divide_color(as_float3(_getSC(scN).weight), A);
}


bool subsurface_random_walk(int scN,
                            inout  float bssrdf_u,
                            inout  float bssrdf_v)
{
  /* Sample diffuse surface scatter into the object. */
  float3 D;
  float pdf;
  //TODO sample_cos_hemisphere(-GSD.N, bssrdf_u, bssrdf_v, D, pdf);
  sample_cos_hemisphere(-GSD.Ng, bssrdf_u, bssrdf_v, D, pdf);
  if (dot(-GSD.Ng, D) <= 0.0f) { return false;}
  /* Convert subsurface to volume coefficients. */
  float3 sigma_t, sigma_s;
  float3 throughput = make_float3(1.0f, 1.0f, 1.0f);
  subsurface_random_walk_coefficients(scN, sigma_t, sigma_s, throughput);

  /* Setup ray. */
#ifdef _SPLIT_KERNEL_
  Ray ray_object = ss_isect->ray;
  Ray *ray = &ray_object;
#else
  //Ray *ray = &ss_isect->ray;
#endif
  ss_isect.ray.P    = ray_offset(GSD.P, -GSD.Ng);
  ss_isect.ray.D    = D;
  ss_isect.ray.t    = FLT_MAX;
  ss_isect.ray.time = GSD.time;

  /* Modify state for RNGs, decorrelated from other paths. */
  uint prev_rng_offset = GSTATE.rng_offset;
  uint prev_rng_hash = GSTATE.rng_hash;
  GSTATE.rng_hash = cmj_hash(GSTATE.rng_hash + GSTATE.rng_offset, DEADBEAF);

  /* Random walk until we hit the surface again. */
  bool hit = false;

  for (int bounce = 0; bounce < BSSRDF_MAX_BOUNCES; bounce++) {
    /* Advance random number offset. */
    GSTATE.rng_hash += PRNG_BOUNCE_NUM;

    if (bounce > 0) {
      /* Sample scattering direction. */
      const float anisotropy = 0.0f;
      float scatter_u, scatter_v;
      path_state_rng_2D(GSTATE,int(PRNG_BSDF_U), scatter_u, scatter_v);
      ss_isect.ray.D  = henyey_greenstrein_sample(ss_isect.ray.D , anisotropy, scatter_u, scatter_v, null_flt);
    }

    /* Sample color channel, use MIS with balance heuristic. */
    float rphase  = path_state_rng_1D(int(PRNG_PHASE_CHANNEL));
    float3 albedo = safe_divide_color(sigma_s, sigma_t);
    float3 channel_pdf;
    int channel = kernel_volume_sample_channel(albedo, throughput, rphase, channel_pdf);
    /* Distance sampling. */
    float rdist = path_state_rng_1D(int(PRNG_SCATTER_DISTANCE));
    float sample_sigma_t = kernel_volume_channel_get(sigma_t, channel);
    float t = -logf(1.0f - rdist) / sample_sigma_t;

    ss_isect.ray.t = t;
    uint null = NULL_LCG;
    scene_intersect_local(GSD.object,null, 1);
    hit = bool(linfo.num_hits > 0);

    if (hit) {
#if defined( _KERNEL_OPTIX_) | defined( _KERNEL_VULKAN_)
      /* t is always in world space with OptiX. */
      t = IS(linfo.offset).t;
#else
      /* Compute world space distance to surface hit. */
      float3 D = ray->D;
      object_inverse_dir_transform(kg, sd, &D);
      D = normalize(D) * ss_isect->hits[0].t;
      object_dir_transform(kg, sd, &D);
      t = len(D);
#endif
    }

    /* Advance to new scatter location. */
    ss_isect.ray.P += t * ss_isect.ray.D;

    /* Update throughput. */
    float3 transmittance = volume_color_transmittance(sigma_t, t);
    float pdf = dot3(channel_pdf, (hit) ? transmittance : sigma_t * transmittance);
    throughput *= ((hit) ? transmittance : sigma_s * transmittance) / pdf;

    if (hit) {
      /* If we hit the surface, we are done. */
      break;
    }

    /* Russian roulette. */
    float terminate = path_state_rng_1D(int(PRNG_TERMINATE));
    float probability = min(max3(fabs(throughput)), 1.0f);
    if (terminate >= probability) {
      break;
    }
    throughput /= probability;
  }

  kernel_assert("assert SUBSURFACE  ::668   \n",isfinite_safe(throughput.x) && isfinite_safe(throughput.y) && isfinite_safe(throughput.z));
  GSTATE.rng_offset  = int(prev_rng_offset);
  GSTATE.rng_hash    = prev_rng_hash;

  /* Return number of hits in ss_isect. */
  if (!hit) {
    return false;
  }

  /* TODO: gain back performance lost from merging with disk BSSRDF. We
   * only need to return on hit so this indirect ray push/pop overhead
   * is not actually needed, but it does keep the code simpler. */
  PLYMO_IS_WEIGHT(0,throughput);
#ifdef _SPLIT_KERNEL_
  ss_isect->ray = *ray;
#endif

  return true;
}

ccl_device_inline int subsurface_scatter_multi_intersect(int scN,
                                                         inout uint lcg_state,
                                                         float bssrdf_u,
                                                         float bssrdf_v,
                                                         bool all)
{
  if (CLOSURE_IS_DISK_BSSRDF(_getSC(scN).type)) {
    return subsurface_scatter_disk(scN, lcg_state, bssrdf_u, bssrdf_v, all);
  }
  else {
    return int(subsurface_random_walk(scN,bssrdf_u, bssrdf_v));
  }
}



#else
/* ShaderData setup from BSSRDF scatter */
#ifdef CALL_SETUP
void shader_setup_from_subsurface(
                                 in float3 rayP,in float3 rayD,
                                 in Intersection lisect
                                )
{
  GSD.geometry         =  lisect.type;
  GSD.type             =  int(kernel_tex_fetch(_prim_type, lisect.prim));
  /* object, matrices, time, ray_length stay the same */
  GSD.object_flag = int(kernel_tex_fetch(_object_flag, GetObjectID(GSD.object)));
  GSD.u           = lisect.u;
  GSD.v           = lisect.v;
  GSD.prim        = lisect.prim;
  GSD.P           = rayP;
  GSD.I           = rayD;
  GSD.object      = lisect.object;
  GSD.P.w         = lisect.t;
  GSD.Ng.x        = float(rec_num);
  SET_SETUP_CALL_TYPE = SETUP_CALL_TYPE_SSS;


  EXECUTION_SETUP;
};
#else
void shader_setup_from_subsurface(
                                 in float3 rayP,in float3 rayD,
                                 in Intersection lisect
                                )
{

  GSD.geometry         =  lisect.type;
  GSD.type             =  int(kernel_tex_fetch(_prim_type, lisect.prim));

  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);
  const bool backfacing = bool(GSD.flag & SD_BACKFACING);

  /* object, matrices, time, ray_length stay the same */
  GSD.flag = 0;
  GSD.object_flag = int(kernel_tex_fetch(_object_flag, GSD.object));
  GSD.u           = lisect.u;
  GSD.v           = lisect.v;
  GSD.prim        = lisect.prim;

  /* fetch triangle data */
  if (GSD.type == PRIMITIVE_TRIANGLE) {
    float3 Ng = triangle_normal();
    GSD.shader = int(kernel_tex_fetch(_tri_shader, GSD.prim));
    /* TODO  static triangle */
    GSD.P = triangle_refine(rayP,rayD,lisect.t,lisect.object,lisect.prim,lisect.type);
#ifdef shader_setup_from_subsurface_P
   STAT_DUMP_f3(shader_setup_from_subsurface_P, GSD.P);
#endif
    GSD.Ng = Ng;
    GSD.N  = Ng;
    /* smooth normal */
    if( bool (GSD.shader & SHADER_SMOOTH_NORMAL))
      GSD.N = triangle_smooth_normal(Ng,GSD.prim,GSD.u,GSD.v);



#ifdef _DPDU_
    /* dPdu/dPdv */
    triangle_dPdudv(GSD.prim, GSD.dPdu, GSD.dPdv);
#endif

  }
  else {
    /*TODO motion triangle */
    //motion_triangle_shader_setup(kg, sd, isect, ray, true);
  }

  GSD.flag |= kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).flags;



  if (!OBJECT_IS_NONE(lisect.object)) {
    /* instance transform */
    object_normal_transform(GSD.N);
    object_normal_transform(GSD.Ng);
#ifdef _DPDU_
    object_dir_transform_auto(GSD.dPdu);
    object_dir_transform_auto(GSD.dPdv);
#endif
  }


  /* backfacing test */
  if (backfacing) {
    GSD.flag |= int(SD_BACKFACING);
    GSD.Ng = -GSD.Ng;
    GSD.N  = -GSD.N;
#ifdef _DPDU_
    GSD.dPdu = -GSD.dPdu;
    GSD.dPdv = -GSD.dPdv;
#endif
  }

  /* should not get used in principle as the shading will only use a diffuse
   * BSDF, but the shader might still access it */
   GSD.I = GSD.N;

#ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  differential_dudv(GSD.du, GSD.dv, GSD.dPdu, GSD.dPdv, GSD.dP, GSD.Ng);
  /* don't modify dP and dI */
#endif

#ifdef shader_setup_from_subsurface_I
   STAT_DUMP_f3(shader_setup_from_subsurface_I, GSD.I);
#endif

  PROFILING_SHADER(GSD.shader);


}
#endif
int closure_alloc(uint type, float3 weight)
{
    if (GSD.num_closure_left == 0)return -1;
    if (GSD.num_closure < 63){
        GSD.alloc_offset++;
        push.pool_ptr.pool_sc.data[GSD.alloc_offset].sample_weight = 0.0;
        push.pool_ptr.pool_sc.data[GSD.alloc_offset].N = vec4(0.0);
        for (int _i_ = 0; _i_ < 25; _i_++)
        {
            push.pool_ptr.pool_sc.data[GSD.alloc_offset].data[_i_] = 0.0;
        }
        
    }
    else
    {
      /* limit */
    }

    push.pool_ptr.pool_sc.data[GSD.alloc_offset].type = type;
    push.pool_ptr.pool_sc.data[GSD.alloc_offset].weight = weight;
    GSD.num_closure++;
    GSD.num_closure_left--;


    return GSD.alloc_offset;
}

int bsdf_alloc(uint size, float3 weight)
{
    int n = closure_alloc(0u, weight);
    if (n < 0)return -1;
    float sample_weight = abs(average(weight));
    push.pool_ptr.pool_sc.data[n].sample_weight = sample_weight;
    return (sample_weight >= 9.9999997473787516355514526367188e-06) ? n : (-1);
}

ccl_device float3 shader_bssrdf_sum(inout float3 N_,inout float texture_blur_)
{
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);
  float3 N = make_float3(0.0f, 0.0f, 0.0f);
  float texture_blur = 0.0f, weight_sum = 0.0f;
  int it_begin = GSD.alloc_offset;

  for (int i = 0; i < GSD.num_closure; i++) {
    if (CLOSURE_IS_BSSRDF(getSC().type)) {
      float avg_weight = fabsf(average(getSC().weight));
      N += getSC().N * avg_weight;
      eval += getSC().weight;
      texture_blur += getSC().data[7] * avg_weight;
      weight_sum += avg_weight;
    }
    GSD.alloc_offset -=1; 
  }
  GSD.alloc_offset = it_begin;
  if (!isNULL3(N_))
    N_ = (is_zero(N)) ? GSD.N : normalize(N);
  if (!isNULL(texture_blur_))
    texture_blur_ = safe_divide(texture_blur, weight_sum);
  return eval;

}

/* optionally do blurring of color and/or bump mapping, at the cost of a shader evaluation */
#define subsurface_color_pow(color,exponent) {\
  color = max(color, make_float3(0.0f, 0.0f, 0.0f));\
  if (exponent == 1.0f) {}\
  else if (exponent == 0.5f) {\
    color.x = sqrtf(color.x);\
    color.y = sqrtf(color.y);\
    color.z = sqrtf(color.z);\
  }\
  else {\
    color.x = powf(color.x, exponent);\
    color.y = powf(color.y, exponent);\
    color.z = powf(color.z, exponent);\
  }\
}

ccl_device void subsurface_color_bump_blur(inout float3 eval,inout float3 N)
{
  /* average color and texture blur at outgoing point */
  float texture_blur;
  float3 out_color = shader_bssrdf_sum(null_flt3, texture_blur);
  /* do we have bump mapping? */
  bool bump = (GSD.flag & SD_HAS_BSSRDF_BUMP) != 0;

  if (bump || texture_blur > 0.0f) {
    /* average color and normal at incoming point */
    shader_eval_surface(GSTATE.flag);
    float3 _N = (bump) ? N : null_flt3;
    float3 in_color = shader_bssrdf_sum(_N, null_flt);

    /* we simply divide out the average color and multiply with the average
     * of the other one. we could try to do this per closure but it's quite
     * tricky to match closures between shader evaluations, their number and
     * order may change, this is simpler */
    if (texture_blur > 0.0f) {
      subsurface_color_pow(out_color, texture_blur);
      subsurface_color_pow(in_color, texture_blur);
      eval *= safe_divide_color(in_color, out_color);
    }
  }
}

/* replace closures with a single diffuse bsdf closure after scatter step */
ccl_device void subsurface_scatter_setup_diffuse_bsdf(ClosureType type, float roughness, float3 weight, float3 N)
{
 
  GSD.flag = int(uint(GSD.flag) & ~SD_CLOSURE_FLAGS);
  GSD.num_closure = 0;
  GSD.num_closure_left = kernel_data.integrator.max_closures;
  GSD.alloc_offset   = GSD.atomic_offset -1;



#ifdef _PRINCIPLED_
  if (type == CLOSURE_BSSRDF_PRINCIPLED_ID || type == CLOSURE_BSSRDF_PRINCIPLED_RANDOM_WALK_ID) {
    int n = bsdf_alloc(0, weight);
    if (n>=0) {
      getSC().N = N;
      getSC().data[0] = roughness;
      /* replace CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID with this special ID so render passes
       * can recognize it as not being a regular Disney principled diffuse closure */
      getSC().type = CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID;
      GSD.flag |= int(SD_BSDF | SD_BSDF_HAS_EVAL);
    }
  }
  else if (CLOSURE_IS_BSDF_BSSRDF(type) || CLOSURE_IS_BSSRDF(type))
#endif /* __PRINCIPLED__ */
  {

    int n = bsdf_alloc(0, weight);
    if (n >= 0) {
      getSC().N = N;
      /* replace CLOSURE_BSDF_DIFFUSE_ID with this special ID so render passes
       * can recognize it as not being a regular diffuse closure */
      getSC().type = CLOSURE_BSDF_BSSRDF_ID;
      GSD.flag |= int(SD_BSDF | SD_BSDF_HAS_EVAL);
    }
  }


}


#define subsurface_scatter_multi_setup(hit,type,roughness) {\
  shader_setup_from_subsurface(ss_isect.rayP,ss_isect.rayD,ss_isect.isect[hit]);\
  float3 weight = ss_isect.weight[hit];\
  float3 N = GSD.N;\
  subsurface_color_bump_blur(weight, N);\
  subsurface_scatter_setup_diffuse_bsdf(type, roughness, weight, N);\
}


ccl_device_inline int subsurface_scatter_multi_intersect(int scN,
                                                         inout uint lcg_state,
                                                         float bssrdf_u,
                                                         float bssrdf_v,
                                                         bool all)
{
  PLYMO_LISECT_offset(GSD.atomic_offset);
  PLYMO_LISECT_lcg_state(lcg_state);
  PLYMO_LISECT_maxhits(-1);
  #ifdef  WITH_STAT_ALL
  PLYMO_LISECT_numhits(rec_num);
  #endif
  PLYMO_IS_ARGLHIT(scN, bssrdf_u, bssrdf_v);
  traceNV(
         topLevelAS,
         gl_RayFlagsSkipClosestHitShaderNV,
         0xFF,             // cullMask
         TRACE_TYPE_LHIT,  // sbtRecordOffset
         0,                // sbtRecordStride
         MISS_TYPE_LHIT,   // missIndex
         vec3(0.),        // ray origin
         0.f,             // ray min range
         vec3(0.),        // ray direction
         0.,            // ray max range
         RPL_TYPE_LISECT     // payload location
  );


  int nums         = IS(GSD.atomic_offset + BSSRDF_MAX_HITS).prim;
  return nums;
   //return 0;
}


#endif

CCL_NAMESPACE_END
#endif