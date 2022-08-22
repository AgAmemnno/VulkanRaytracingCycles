#ifndef _KERNEL_SHADER_H_
#define _KERNEL_SHADER_H_

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

/*
 * ShaderData, used in four steps:
 *
 * Setup from incoming ray, sampled position and background.
 * Execute for surface, volume or displacement.
 * Evaluate one or more closures.
 * Release.
 */

#include "kernel/kernel_differential.h.glsl"
#include "kernel/kernel_random.h.glsl"


#ifdef GSD
#include "kernel/geom/geom_object.h.glsl"
#include "kernel/geom/geom_triangle.h.glsl"
//#undef _INTERSECTION_REFINE_
#include "kernel/geom/geom_triangle_intersect.h.glsl"
#include "kernel/geom/geom_attribute.h.glsl"
#include "kernel/geom/geom_motion_triangle.h.glsl"
#endif

#ifdef  SVM_TYPE_SETUP

#define DEF_BSDF SC(sd.alloc_offset)
#define SHADER_BSDF_EVAL
#include "kernel/closure/bsdf_util.h.glsl"
//#include "kernel/closure/alloc.h.glsl"
#include "kernel/closure/emissive.h.glsl"

//#include "kernel/closure/bsdf_microfacet.h.glsl"
//#include "kernel/closure/bsdf_refraction.h.glsl"
//#include "kernel/closure/bsdf_reflection.h.glsl"
//#include "kernel/closure/bsdf_ashikhmin_shirley.h.glsl"
//#include "kernel/closure/bsdf_microfacet_multi.h.glsl"

//#include "kernel/closure/bsdf_toon.h.glsl"
//#include "kernel/closure/bsdf_diffuse.h.glsl"
//#include "kernel/closure/bsdf_oren_nayar.h.glsl"
//#include "kernel/closure/bsdf_transparent.h.glsl"

//#include "kernel/closure/bsdf_ashikhmin_velvet.h.glsl"

//#include "kernel/closure/bsdf_principled_diffuse.h.glsl"
//#include "kernel/closure/bsdf_principled_sheen.h.glsl"

#include "kernel/closure/_bsdf.h.glsl"
#include "kernel/svm/_svm.h.glsl"


#endif


#ifdef SVM_TYPE_EVAL_SAMPLE 
#include "kernel/closure/bsdf_util.h.glsl"
#include "kernel/closure/bsdf_microfacet.h.glsl"
#include "kernel/closure/bsdf_refraction.h.glsl"
#include "kernel/closure/bsdf_reflection.h.glsl"
#include "kernel/closure/bsdf_microfacet_multi.h.glsl"
#include "kernel/closure/bsdf_ashikhmin_shirley.h.glsl"

#include "kernel/closure/bsdf_diffuse.h.glsl"
#include "kernel/closure/bsdf_oren_nayar.h.glsl"
#include "kernel/closure/bsdf_toon.h.glsl"
#include "kernel/closure/bsdf_transparent.h.glsl"
#include "kernel/closure/bsdf_ashikhmin_velvet.h.glsl"


#include "kernel/closure/bsdf_principled_diffuse.h.glsl"
#include "kernel/closure/bsdf_principled_sheen.h.glsl"


#include "kernel/closure/_bsdf.h.glsl"
#endif


CCL_NAMESPACE_BEGIN

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

/* Background */
#define shader_background_eval()  ( (bool(GSD.flag & SD_EMISSION)) ? GSD.closure_emission_background : make_float3(0.0f, 0.0f, 0.0f))


#ifdef  SVM_TYPE_SETUP


ccl_device void shader_bsdf_blur(float roughness)
{

  int it_next = sd.alloc_offset;
  for (int i = 0; i < sd.num_closure; i++) {
    if (CLOSURE_IS_BSDF(_getSC(it_next).type))
      bsdf_blur( it_next, roughness);
    it_next -= 1;
  }

}


#else 

#ifdef GSD

/* ShaderData setup from incoming ray */

#ifdef _OBJECT_MOTION2_
ccl_device void shader_setup_object_transforms(float time)
{
  if (bool(GSD.object_flag & SD_OBJECT_MOTION)) {
    GSD.ob_tfm  = object_fetch_transform_motion(GSD.object, time);
    GSD.ob_itfm = transform_quick_inverse(GSD.ob_tfm);
  }
  else {
    GSD.ob_tfm  = object_fetch_transform(GSD.object, OBJECT_TRANSFORM);
    GSD.ob_itfm = object_fetch_transform(GSD.object, OBJECT_INVERSE_TRANSFORM);
  }
}
#endif


/* ShaderData setup from ray into background */


void shader_setup_from_background(in Ray ray)
{


  /* vectors */
  GSD.P = ray.D;
  GSD.N = -ray.D;
  GSD.Ng = -ray.D;
  GSD.I = -ray.D;
  GSD.shader = kernel_data.background.surface_shader;
  GSD.flag = kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).flags;
  GSD.object_flag = 0;
  GSD.time = ray.time;
  GSD.ray_length = 0.0f;

  GSD.object = OBJECT_NONE;
  GSD.lamp = LAMP_NONE;
  GSD.prim = PRIM_NONE;
  GSD.u = 0.0f;
  GSD.v = 0.0f;

#ifdef _DPDU_
  /* dPdu/dPdv */
  GSD.dPdu = make_float3(0.0f, 0.0f, 0.0f);
  GSD.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#endif

#ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  GSD.dP = ray.dD;
  differential_incoming(GSD.dI, GSD.dP);
  differential_zero(GSD.du);
  differential_zero(GSD.dv );
#endif

  /* for NDC coordinates */
  GSD.ray_P = ray.P;


}

#ifdef GISECT
#ifdef CALL_SETUP

void shader_setup_from_ray(in Ray ray)
{
  ///GSD.object = (GISECT.object == OBJECT_NONE) ? int( kernel_tex_fetch(_prim_object, GISECT.prim)) :GISECT.object;
  GSD.object      = GISECT.object; 
  GSD.lamp        = LAMP_NONE;
  GSD.flag        = 0;
  GSD.type        = GISECT.type;
  GSD.object_flag = int(kernel_tex_fetch(_object_flag,  GetObjectID(GSD.object)));
  /* matrices and time */
#ifdef _OBJECT_MOTION2_
  shader_setup_object_transforms(ray.time);
#endif
  GSD.time =  ray.time;
  GSD.prim =  GISECT.prim; //int(kernel_tex_fetch(_prim_index, GISECT.prim));
  GSD.ray_length = GISECT.t;
  GSD.u = GISECT.u;
  GSD.v = GISECT.v;
  GSD.P = ray.P;
  GSD.I = ray.D;
  #ifdef _RAY_DIFFERENTIALS_
  GSD.dP = ray.dP;
  GSD.dI = ray.dD;
  #endif

  GSD.Ng.x = float(rec_num);
  SET_SETUP_CALL_TYPE = SETUP_CALL_TYPE_RAY;
  EXECUTION_SETUP;


}

#else
void shader_setup_from_ray(in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);


  ///GSD.object = (GISECT.object == OBJECT_NONE) ? int( kernel_tex_fetch(_prim_object, GISECT.prim)) :GISECT.object;
  GSD.object      = GetObjectID(GISECT.object);
  GSD.lamp        = LAMP_NONE;
  GSD.flag        = 0;
  GSD.type        = GISECT.type;
  GSD.object_flag = int(kernel_tex_fetch(_object_flag, GSD.object));

  /* matrices and time */
#ifdef _OBJECT_MOTION2_
    /*  migrate  CloseHit Shader
     */
  shader_setup_object_transforms(ray.time);
    
#endif
  GSD.time =  ray.time;
  GSD.prim =  GISECT.prim; //int(kernel_tex_fetch(_prim_index, GISECT.prim));
  GSD.ray_length = GISECT.t;
  GSD.u = GISECT.u;
  GSD.v = GISECT.v;




#ifdef _HAIR_
  if (sd->type & PRIMITIVE_ALL_CURVE) {
    /* curve */
    curve_shader_setup(kg, sd, isect, ray);
  }
  else
#endif
  if(bool(GSD.type & PRIMITIVE_TRIANGLE) ){
    /* static triangle */
    float3 Ng  = triangle_normal();
    GSD.shader = int(kernel_tex_fetch(_tri_shader, GSD.prim));
#ifdef _BVH_LOCAL_
    GSD.P = triangle_refine(ray.P,ray.D,GISECT.t,GISECT.object,GISECT.prim,GSD.geometry);
#else
    GSD.P = triangle_refine(ray);
#endif
    GSD.Ng = Ng;
    GSD.N  = Ng;


    /* smooth normal */
    if( bool (GSD.shader & SHADER_SMOOTH_NORMAL))
      GSD.N = triangle_smooth_normal(Ng,GSD.prim,GSD.u,GSD.v);

#ifdef  WITH_STAT_ALL
#ifdef sd_N_f3
    CNT_ADD(CNT_sd_N);
    STAT_DUMP_f3(sd_N_f3,GSD.N);
#endif
#endif


#ifdef _DPDU_
    /* dPdu/dPdv */
    triangle_dPdudv(GSD.prim, GSD.dPdu, GSD.dPdv);
#endif
  }
  else {
    /* motion triangle */
    //motion_triangle_shader_setup(kg, sd, isect, ray, false);
  }

  GSD.I = -ray.D;

  GSD.flag |= kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).flags;


  if (!OBJECT_IS_NONE(GISECT.object)) {
    /* instance transform */
    object_normal_transform(GSD.N);
    object_normal_transform(GSD.Ng);
#ifdef _DPDU_
    object_dir_transform_auto(GSD.dPdu);
    object_dir_transform_auto(GSD.dPdv);
#endif
  }

  /* backfacing test */
  bool backfacing = (dot3(GSD.Ng, GSD.I) < 0.0f);

  if (backfacing) {
    GSD.flag |= int(SD_BACKFACING);
    GSD.Ng = -GSD.Ng;
    GSD.N  = -GSD.N;
#ifdef _DPDU_
    GSD.dPdu = -GSD.dPdu;
    GSD.dPdv = -GSD.dPdv;
#endif

  }

#ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  differential_transfer(GSD.dP, ray.dP, ray.D, ray.dD, GSD.Ng, GISECT.t);
  differential_incoming(GSD.dI, ray.dD);
  differential3 dP = GSD.dP;
  differential_dudv(GSD.du, GSD.dv, GSD.dPdu, GSD.dPdv, dP, GSD.Ng);
  //
#endif


  PROFILING_SHADER(GSD.shader);
  PROFILING_OBJECT(GSD.object);
}
#endif
#endif
ccl_device float3 shader_emissive_eval()
{
  if (bool(GSD.flag & SD_EMISSION)) {

    return emissive_simple_eval(GSD.Ng, GSD.I) * GSD.closure_emission_background;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}


/* ShaderData setup from position sampled on mesh */
ccl_device_inline void shader_setup_from_sample(
                                                const float3 P,
                                                const float3 Ng,
                                                const float3 I,
                                                int shader,
                                                int object,
                                                int prim,
                                                float u,
                                                float v,
                                                float t,
                                                float time,
                                                bool object_space,
                                                int   lamp)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);
  /* vectors */
  GSD.P  = P;
  GSD.N  = Ng;
  GSD.Ng = Ng;
  GSD.I  = I;
  GSD.shader = shader;
  if (prim != PRIM_NONE)
    GSD.type = int(PRIMITIVE_TRIANGLE);

  else if (lamp != LAMP_NONE)
    GSD.type = int( PRIMITIVE_LAMP);
  else
    GSD.type = int( PRIMITIVE_NONE);


  /* primitive */
  GSD.object = object;
  GSD.lamp   = LAMP_NONE;
  /* currently no access to bvh prim index for strand GSD.prim*/
  GSD.prim = prim;
  GSD.u = u;
  GSD.v = v;
  GSD.time = time;
  GSD.ray_length = t;

  GSD.flag = kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).flags;
  GSD.object_flag = 0;
  if (GSD.object != OBJECT_NONE) {
    GSD.object_flag |= int(kernel_tex_fetch(_object_flag, GSD.object));


#ifdef _OBJECT_MOTION2_
    shader_setup_object_transforms(time);
  }
  else if (lamp != LAMP_NONE) {
    GSD.ob_tfm = lamp_fetch_transform(lamp, false);
    GSD.ob_itfm = lamp_fetch_transform(lamp, true);
    GSD.lamp = lamp;
#else
  }
  else if (lamp != LAMP_NONE) {
    GSD.lamp = lamp;
#endif
  }

  /* transform into world space */
  if (object_space) {
    object_position_transform_auto(GSD.P);
    object_normal_transform_auto(GSD.Ng);
    GSD.N = GSD.Ng;
    object_dir_transform_auto(GSD.I);

  }

  if (bool(GSD.type & PRIMITIVE_TRIANGLE)) {
    /* smooth normal */
    if (bool(GSD.shader & SHADER_SMOOTH_NORMAL)) {


      GSD.N = triangle_smooth_normal(Ng, GSD.prim, GSD.u, GSD.v);

      if (!(bool(GSD.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {
        object_normal_transform_auto(GSD.N);
      }
    }

    /* dPdu/dPdv */
#ifdef _DPDU_
    triangle_dPdudv(GSD.prim, (GSD.dPdu), (GSD.dPdv));
    if (!(bool(GSD.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {
      object_dir_transform_auto(GSD.dPdu);
      object_dir_transform_auto(GSD.dPdv);
    }
#endif
  }
  else {
#ifdef _DPDU_
    GSD.dPdu = make_float3(0.0f, 0.0f, 0.0f);
    GSD.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#endif
  }

  /* backfacing test */
  if (GSD.prim != PRIM_NONE) {
    bool backfacing = (dot3(GSD.Ng, GSD.I) < 0.0f);

    if (bool(backfacing)) {

      GSD.flag |= int(SD_BACKFACING);

      GSD.Ng = -GSD.Ng;
      GSD.N = -GSD.N;
#ifdef _DPDU_
      GSD.dPdu = -GSD.dPdu;
      GSD.dPdv = -GSD.dPdv;
#endif
    }
  }

#ifdef _RAY_DIFFERENTIALS_
  /* no ray differentials here yet */
   differential3_zero(GSD.dP);
   differential3_zero(GSD.dI);
   differential_zero(GSD.du);
   differential_zero(GSD.dv);
#endif

  PROFILING_SHADER(GSD.shader);
  PROFILING_OBJECT(GSD.object);
}


void shader_eval_surface(uint state_flag)
{


  /* If path is being terminated, we are tracing a shadow ray or evaluating
   * emission, then we don't need to store closures. The emission and shadow
   * shader data also do not have a closure array to save GPU memory. */
  int max_closures;
  if (bool( state_flag & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION))) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }

  GSD.num_closure = int(state_flag);
  GSD.num_closure_left = max_closures;

#ifdef  WITH_STAT_ALL
  GSD.alloc_offset  = rec_num;
#endif
  //svm_eval_nodes
  EXECUTION_SVM;  

if (bool(GSD.flag & SD_BSDF_NEEDS_LCG) ){
    #ifndef LCG_NO_USE
      GSD.lcg_state = lcg_init( uint(GSTATE.rng_hash) + uint(GSTATE.rng_offset) + uint(GSTATE.sample_rsv) *  3032234323u );//0xb4bc3953
    #else
      debugPrintfEXT(" warning lcg_state_no_use , but used.\n");
    #endif
}

}

#if defined(SC) && defined(GSTATE)
void shader_prepare_closures()
{
  /* We can likely also do defensive sampling at deeper bounces, particularly
   * for cases like a perfect mirror but possibly also others. This will need
   * a good heuristic. */
  if (GSTATE.bounce + GSTATE.transparent_bounce == 0 &&  GSD.num_closure > 1) {

    int it_begin = GSD.alloc_offset;

    float sum = 0.0f;
    for (int i = 0; i < GSD.num_closure; i++) { 
      if (CLOSURE_IS_BSDF_OR_BSSRDF(getSC().type)) {
        sum += getSC().sample_weight;
      }
      GSD.alloc_offset -=1; 
    }
    GSD.alloc_offset = it_begin;

    for (int i = 0; i < GSD.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(getSC().type)) {
        getSC().sample_weight = max(getSC().sample_weight, 0.125f * sum);
      }
      GSD.alloc_offset -=1; 
    }
    GSD.alloc_offset = it_begin;

  }

 #ifdef  WITH_STAT_ALL
  CNT_ADD(CNT_shader_prepare_closures);
  #ifdef shader_prepare_closures_sum
  int it_begin = GSD.alloc_offset;
  float sum = 0.0f;
  for (int i = 0; i < GSD.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(getSC().type)) {
        sum += getSC().sample_weight;
      }
      GSD.alloc_offset -= 1;
  }
  GSD.alloc_offset = it_begin;
  float3  f = make_float3(sum, float(GSTATE.bounce), float(GSD.num_closure) );
  STAT_DUMP_f3(shader_prepare_closures_sum, f);
  #endif
#endif

}

#endif

#endif

#endif


#ifdef  SVM_TYPE_EVAL_SAMPLE

#if defined(_BRANCHED_PATH_)



ccl_device_inline void _shader_bsdf_multi_eval_branched(
                                                        const float3 omega_in,
                                                        float light_pdf,
                                                        bool use_mis)
{
  int it_next = PLYMO.sd.alloc_offset;
  for (int i = 0; i < PLYMO.sd.num_closure; i++) {
    sc  = _getSC(it_next);
    if (CLOSURE_IS_BSDF(sc.type)) {
      float bsdf_pdf = 0.0f;
      float3 b_eval = bsdf_eval(sc, omega_in, bsdf_pdf);
      if (bsdf_pdf != 0.0f) {
        float mis_weight = use_mis ? power_heuristic(light_pdf, bsdf_pdf) : 1.0f;
        PLYMO_bsdf_eval_accum(sc.type, b_eval * sc.weight, mis_weight);
      }
    }
    it_next -= 1;
  }
}




#endif /* _BRANCHED_PATH_ */


ccl_device_inline void _shader_bsdf_multi_eval(
                                               const float3 omega_in,
                                               inout float pdf,
                                               const int skip_sc,
                                               float sum_pdf,
                                               float sum_sample_weight)
{
  /* this is the veach one-sample model with balance heuristic, some pdf
   * factors drop out when using balance heuristic weighting */

  int it_next = PLYMO.sd.alloc_offset;

  for (int i = 0; i < PLYMO.sd.num_closure; i++) {
    sc = _getSC(it_next);
    if (it_next != skip_sc && CLOSURE_IS_BSDF( sc.type) ) {
          float bsdf_pdf = 0.0f;
          float3 eval = bsdf_eval(sc, omega_in, bsdf_pdf);
          if (bsdf_pdf != 0.0f) {
            PLYMO_bsdf_eval_accum(sc.type, eval * sc.weight, 1.0f);
            sum_pdf += bsdf_pdf * sc.sample_weight;
          }
          sum_sample_weight += sc.sample_weight;    
    }
    it_next -= 1;
  }
  pdf = (sum_sample_weight > 0.0f) ? sum_pdf / sum_sample_weight : 0.0f;
#ifdef  WITH_STAT_ALL
#ifdef shader_bsdf_multi_eval_sum_no_mis
  STAT_DUMP_f3(shader_bsdf_multi_eval_sum_no_mis, PLYMO_EVAL_sum_no_mis);
#endif
#endif
}

void shader_bsdf_eval()
{

ARGS_shader_bsdf_eval

PLYMO_bsdf_eval_init(NBUILTIN_CLOSURES, make_float3(0.0f, 0.0f, 0.0f),kernel_data.film.use_light_pass);


#ifdef _BRANCHED_PATH_
  if (bool(kernel_data.integrator.branched))
    _shader_bsdf_multi_eval_branched(omega_in,light_pdf, use_mis);
  else
#endif
  {
    float pdf;
    _shader_bsdf_multi_eval(omega_in, pdf, -1, 0.0f, 0.0f);

    if (use_mis) {
      float weight = power_heuristic(light_pdf, pdf);
      PLYMO_bsdf_eval_mis(weight);
    }
  }

}



int shader_bsdf_pick(inout float randu)
{
  /* Note the sampling here must match shader_bssrdf_pick,
   * since we reuse the same random number. */
  int sampled = PLYMO.sd.atomic_offset;
 

  if (PLYMO.sd.num_closure > 1) {
    //int list[32];
    /* Pick a BSDF or based on sample weights. */
    float sum = 0.0f;
    int next = sampled;
    
    for (int i = 0; i < PLYMO.sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(_getSC(next).type)) {
        sum += _getSC(next).sample_weight;
      }
      next++;
    }

    float r = (randu) * sum;
    float partial_sum = 0.0f;
    sampled = PLYMO.sd.atomic_offset;
    for (int i = 0; i < PLYMO.sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(_getSC( (sampled+i) ).type)) {
        float next_sum = partial_sum + _getSC( (sampled+i) ).sample_weight;
        if (r < next_sum) {
          sampled =  (sampled+i) ;
          /* Rescale to reuse for direction sample, to better preserve stratification. */
          randu = (r - partial_sum) / _getSC(sampled).sample_weight;
          break;
        }
        partial_sum = next_sum;
      }
    }

 }
  
  

  return CLOSURE_IS_BSDF( _getSC(sampled).type) ? sampled : -1;
}

int shader_bsdf_sample(float randu,
                      float randv,
                      inout float3 omega_in,
                      inout differential3 domega_in,
                      inout float pdf)
{
  PROFILING_INIT(kg, PROFILING_CLOSURE_SAMPLE);

  const int sampled = shader_bsdf_pick(randu);

  if (sampled < 0) {
    pdf = 0.0f;
    return int(LABEL_NONE);
  }

  sc = _getSC(sampled); 

  /* BSSRDF should already have been handled elsewhere. */

  kernel_assert("assert rcall3 661 ",CLOSURE_IS_BSDF(_getSC(sampled).type))

  int label;
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);

  PLYMO_EVAL_set_use_light_pass(0);
  pdf = 0.0f; 
  label = int(bsdf_sample(randu, randv,eval,omega_in,domega_in,pdf));

#ifdef  WITH_STAT_ALL
#ifdef shader_bsdf_sample_eval
  STAT_DUMP_f3(shader_bsdf_sample_eval,eval);
#endif
#endif

  if (pdf != 0.0f) {
    PLYMO_bsdf_eval_init(sc.type, eval * sc.weight,kernel_data.film.use_light_pass);
    if (PLYMO.sd.num_closure > 1) {
      float sweight = sc.sample_weight;
      _shader_bsdf_multi_eval( omega_in, pdf,sampled, pdf * sweight, sweight);
    }
/*
#ifdef  WITH_STAT_ALL
#ifdef shader_bsdf_sample_eval_diffuse
  STAT_DUMP_f3(shader_bsdf_sample_eval_diffuse, PLYMO_EVAL_diffuse);
  if(G_use_light_pass){
      STAT_DUMP_f3(shader_bsdf_sample_eval_glossy, PLYMO_EVAL_glossy);
      STAT_DUMP_f3(shader_bsdf_sample_eval_transmission, PLYMO_EVAL_transmission);
      STAT_DUMP_f3(shader_bsdf_sample_eval_transparent, PLYMO_EVAL_transparent);
  }
#endif
#endif
*/

  }

  
  return label;
}


#endif


/*
#ifdef _TRANSPARENT_SHADOWS_
ccl_device bool shader_transparent_shadow(inout Intersection isect)
{
  int prim = isect.prim ;//int(kernel_tex_fetch(_prim_index, isect.prim));
  int shader = 0;

#  ifdef _HAIR_
  if (bool(isect.type & PRIMITIVE_ALL_TRIANGLE)) {

#  endif
    shader = int(kernel_tex_fetch(_tri_shader, prim));
#  ifdef _HAIR_
  }
  else {
    float4 str = kernel_tex_fetch(_curves, prim);
    shader = _float_as_int(str.z);
  }
#  endif
  int flag = kernel_tex_fetch(_shaders, (shader & SHADER_MASK)).flags;

  return bool(flag & SD_HAS_TRANSPARENT_SHADOW) != 0;
}
#endif // _TRANSPARENT_SHADOWS_ 
*/

CCL_NAMESPACE_END

#endif