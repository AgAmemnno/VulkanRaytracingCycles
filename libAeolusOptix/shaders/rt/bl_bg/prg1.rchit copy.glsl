#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout :require
#extension GL_GOOGLE_include_directive : enable


#define SET_KERNEL 2
#define PUSH_KERNEL_TEX
#define PUSH_POOL_SC
#define GSD sd
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"


#include "kernel/kernel_globals.h.glsl"


#include "kernel/kernel_random.h.glsl"
#include "kernel/kernel_differential.h.glsl"
#include "kernel/kernel_montecarlo.h.glsl"


#define LIGHT_SAMPLE 0u
#define SVM_NODES_EVAL 1u

#define sizeof_BsdfEval   4*(6*4 + 1)


float3 ray_offset(float3 P, float3 Ng)
{
#ifdef _INTERSECTION_REFINE_
  const float epsilon_f = 1e-5f;
  /* ideally this should match epsilon_f, but instancing and motion blur
   * precision makes it problematic */
  const float epsilon_test = 1.0f;
  const int epsilon_i = 32;

  float3 res;

  /* x component */
  if (fabsf(P.x) < epsilon_test) {
    res.x = P.x + Ng.x * epsilon_f;
  }
  else {
    uint ix = _float_as_uint(P.x);
    ix +=  (bool((ix ^ _float_as_uint(Ng.x)) >> 31)) ? -epsilon_i : epsilon_i;
    res.x = _uint_as_float(ix);
  }

  /* y component */
  if (fabsf(P.y) < epsilon_test) {
    res.y = P.y + Ng.y * epsilon_f;
  }
  else {
    uint iy = _float_as_uint(P.y);
    iy += (bool((iy ^ _float_as_uint(Ng.y)) >> 31)) ? -epsilon_i : epsilon_i;
    res.y = _uint_as_float(iy);
  }

  /* z component */
  if (fabsf(P.z) < epsilon_test) {
    res.z = P.z + Ng.z * epsilon_f;
  }
  else {
    uint iz = _float_as_uint(P.z);
    iz += (bool((iz ^ _float_as_uint(Ng.z)) >> 31) )? -epsilon_i : epsilon_i;
    res.z = _uint_as_float(iz);
  }

  return res;
#else
  const float epsilon_f = 1e-4f;
  return P + epsilon_f * Ng;
#endif
}

struct hitPayload_
{
vec4 throughput;
PathRadiance L;    //424
PathState state;        //56
ShaderData            sd; //276
//ShaderDataTinyStorage esd; //276
};
#define sizeof_PathState  4*(14)
#define sizeof_hitPayload_ 772 //1032
#define prd_return(tf) {prd.throughput.w  = float(tf);return;}




struct args_acc_light{
  int use_light_pass;
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 path_total;
  vec4 throughput;
};



#define ply_prs_diffuse  arg.sd.N
#define ply_prs_glossy  arg.sd.I
#define ply_prs_transmission  arg.sd.dP.dx
#define ply_prs_volume  arg.sd.dP.dy

#define ply_assign_bounce {\
     prd.L.state.diffuse =  ply_prs_diffuse;\
     prd.L.state.glossy =  ply_prs_glossy;\
     prd.L.state.transmission =  ply_prs_transmission;\
     prd.L.state.volume =  ply_prs_volume;\
}


#define set_arg_L {\
  arg.L.use_light_pass = prd.L.use_light_pass;\
  arg.L.emission = prd.L.emission;\
  arg.L.direct_emission = prd.L.direct_emission;\
  arg.L.indirect = prd.L.indirect;\
  arg.L.path_total = prd.L.path_total;\
  arg.L.throughput = prd.throughput;\
  }
#define prd_set_arg_L {\
  prd.L.use_light_pass = arg.L.use_light_pass;\
  prd.L.emission = arg.L.emission;\
  prd.L.direct_emission = arg.L.direct_emission;\
  prd.L.indirect = arg.L.indirect;\
  prd.L.path_total =arg.L.path_total;\
  prd.L.state.diffuse = ply_prs_diffuse;\
  prd.L.state.glossy = ply_prs_glossy;\
  prd.L.state.transmission = ply_prs_transmission;\
  prd.L.state.volume = ply_prs_volume;\
  prd.throughput = arg.L.throughput;\
}




struct args_sd{
int type;
int flag;
float time; 
int object;
float3 P;
float3 N; 
float3 I;
float3 Ng;
differential3       dP;
float       ray_length;
int        num_closure;
int      atomic_offset;
int       alloc_offset;
};

//128
#define sizeof_args_sd 4*(8 + 4*6) 

struct args_state{
int      flag; 
uint rng_hash;
int  bounce;
int  rng_offset;
int  sample_rsv;
int  num_samples;
float ray_pdf;
float ray_t;
float min_ray_pdf;
 //esd->closure_emission_background
};
//36


struct hitPayload0
{
int  type;
args_acc_light L; //68
Ray ray; //104
args_sd    sd; //128 
PathState  state; //56
};

// 4*(1 + 4 ) + 424  + 104 + 128 +36
#define sizeof_hitPatload0 336

#define ply_return_bounce   arg.type
#define ply_label  arg.sd.alloc_offset

layout(location = 0) rayPayloadInNV hitPayload_ prd;
layout(location = 0) callableDataNV hitPayload0 arg;
layout(location = 1) callableDataNV ShaderData   sd;


#define sizeof_prg1_dataNV 2020


hitAttributeNV vec2 attribs;

#define getSC() SC(sd.alloc_offset)

#include "kernel/geom/geom_object.h.glsl"


#define set_arg_state {\
  arg.state.flag   =  prd.state.flag; \
  arg.state.rng_hash = prd.state.rng_hash;\
  arg.state.bounce = prd.state.bounce;\
  arg.state.rng_offset =  prd.state.rng_offset;\
  arg.state.sample_rsv =  prd.state.sample_rsv;\
  arg.state.ray_pdf = prd.state.ray_pdf;\
  arg.state.num_samples =  prd.state.num_samples;\
  arg.state.ray_pdf = prd.state.ray_pdf;\
}

#define prd_set_arg_state {\
  prd.state.flag = arg.state.flag; \
  prd.state.rng_hash = arg.state.rng_hash;\
  prd.state.bounce = arg.state.bounce;\
  prd.state.rng_offset =  arg.state.rng_offset;\
  prd.state.sample_rsv =  arg.state.sample_rsv;\
  prd.state.ray_pdf = arg.state.ray_pdf;\
  prd.state.num_samples =  arg.state.num_samples;\
  prd.state.ray_pdf = arg.state.ray_pdf;\
}

void kernel_path_lamp_emission(in Ray ray,in Intersection isect)
{
  PROFILING_INIT(kg, PROFILING_INDIRECT_EMISSION);

#ifdef ENABLE_PROFI
PROFI_LAMP_TF(kernel_data.integrator.use_lamp_mis,arg.state.flag, int(bool(kernel_data.integrator.use_lamp_mis) && !bool( arg.state.flag & PATH_RAY_CAMERA)))
#endif

#ifdef _LAMP_MIS_
  if ( bool(kernel_data.integrator.use_lamp_mis) && !bool( arg.state.flag & PATH_RAY_CAMERA)) {
    /* ray starting from previous non-transparent bounce */

    arg.ray.P = ray.P - arg.state.ray_t * ray.D;
    arg.state.ray_t += isect.t;
    arg.ray.D = ray.D;
    arg.ray.t = arg.state.ray_t;
    arg.ray.time = ray.time;
    arg.ray.dD = ray.dD;
    arg.ray.dP = ray.dP;
    

    
    arg.type = SURFACE_CALL_TYPE_indirect_lamp;
    /* intersect with lamp */
    executeCallableNV(2u, 0);

  }
#endif /* __LAMP_MIS__ */
}

vec4 triangle_normal()
{
  uint tri_vindex = push.data_ptr._tri_vindex.data[sd.prim].w;
  vec4 v0 = push.data_ptr._prim_tri_verts.data[tri_vindex + 0u];
  vec4 v1 = push.data_ptr._prim_tri_verts.data[tri_vindex + 1u];
  vec4 v2 = push.data_ptr._prim_tri_verts.data[tri_vindex + 2u];
  /* return normal */
  if (bool(sd.object_flag & SD_OBJECT_NEGATIVE_SCALE_APPLIED ) ){
    return vec4(normalize(cross(v2.xyz - v0.xyz, v1.xyz - v0.xyz)),0.);
  }
  else {
    return vec4(normalize(cross(v1.xyz - v0.xyz, v2.xyz - v0.xyz)),0.);
  }
}
#define triangle_dPdudv(prim,dPdu,dPdv)\
{\
  const uint4 tri_vindex = kernel_tex_fetch(_tri_vindex, prim);\
  const float3 p0 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 0));\
  const float3 p1 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 1));\
  const float3 p2 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 2));\
  dPdu = (p0 - p2);\
  dPdv = (p1 - p2);\
}

vec4 triangle_refine(Intersection isect, Ray ray)
{
return ray.P + (ray.D * isect.t);
}
vec4 triangle_smooth_normal(vec4 Ng, int prim, float u, float v)
{
uvec4 tri_vindex = push.data_ptr._tri_vindex.data[prim];
vec4 n0 = push.data_ptr._tri_vnormal.data[tri_vindex.x];
vec4 n1 = push.data_ptr._tri_vnormal.data[tri_vindex.y];
vec4 n2 = push.data_ptr._tri_vnormal.data[tri_vindex.z];
vec4 N = safe_normalize(((n2 * ((1.0 - u) - v)) + (n0 * u)) + (n1 * v));
return is_zero(N) ? Ng : N;
}


/* path tracing: connect path directly to position on a light and add it to L */
ccl_device_inline void kernel_path_surface_connect_light(
                                                        
                                                       )
{

  PROFILING_INIT(kg, PROFILING_CONNECT_LIGHT);
  arg.sd.type   = sd.type;
  arg.sd.flag   = sd.flag;
  arg.sd.time   = sd.time; 
  arg.sd.object =sd.object;
  arg.sd.P      =sd.P;
  arg.sd.N      =sd.N; 
  arg.sd.I      =sd.I;
  arg.sd.Ng     =sd.Ng;
  arg.sd.dP     =sd.dP;
  arg.sd.num_closure=sd.num_closure;
  arg.sd.atomic_offset=sd.atomic_offset;
  arg.sd.alloc_offset= sd.alloc_offset;

#ifdef ENABLE_PROFI
arg.L.emission.w = float(PROFI_IDX);
#endif

#ifdef _EMISSION_
#  ifdef _SHADOW_TRICKS_
   arg.type = SURFACE_CALL_TYPE_connect_light;
   executeCallableNV(2u,0);

   //int all = (prd.state.flag & PATH_RAY_SHADOW_CATCHER);
   //kernel_branched_path_surface_connect_light( throughput, 1.0f, L, all);
#  else
  /* sample illumination from lights to find path contribution */
  Ray light_ray ccl_optional_struct_init;
  BsdfEval L_light ccl_optional_struct_init;
  bool is_lamp = false;
  bool has_emission = false;

  light_ray.t = 0.0f;
#    ifdef __OBJECT_MOTION__
  light_ray.time = sd->time;
#    endif

  if (kernel_data.integrator.use_direct_light && (sd->flag & SD_BSDF_HAS_EVAL)) {
    float light_u, light_v;
    path_state_rng_2D(kg, state, PRNG_LIGHT_U, &light_u, &light_v);

    LightSample ls ccl_optional_struct_init;
    if (light_sample(kg, -1, light_u, light_v, sd->time, sd->P, state->bounce, &ls)) {
      float terminate = path_state_rng_light_termination(kg, state);
      has_emission = direct_emission(
          kg, sd, emission_sd, &ls, state, &light_ray, &L_light, &is_lamp, terminate);
    }
  }

  /* trace shadow ray */
  float3 shadow;

  const bool blocked = shadow_blocked(kg, sd, emission_sd, state, &light_ray, &shadow);

  if (has_emission) {
    if (!blocked) {
      /* accumulate */
      path_radiance_accum_light(kg, L, state, throughput, &L_light, shadow, 1.0f, is_lamp);
    }
    else {
      path_radiance_accum_total_light(L, state, throughput, &L_light);
    }
  }
  
#  endif

   prd.L.path_total = arg.L.path_total;




#endif
}

/* Surface Evaluation */
void shader_eval_surface()
{
  PROFILING_INIT(kg, PROFILING_SHADER_EVAL);

  /* If path is being terminated, we are tracing a shadow ray or evaluating
   * emission, then we don't need to store closures. The emission and shadow
   * shader data also do not have a closure array to save GPU memory. */
  int max_closures;
  if (bool(arg.state.flag & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION))) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }

  sd.num_closure = arg.state.flag;
  sd.num_closure_left = max_closures;

#ifdef ENABLE_PROFI
  sd.alloc_offset  = PROFI_IDX;
#endif

  executeCallableNV(4u, 1);   
    //svm_eval_nodes(kg, sd, state, buffer_ofs, SHADER_TYPE_SURFACE, path_flag);
#ifdef ENABLE_PROFI
  PROFI_SD_NUM_CL(sd.num_closure);
#endif

if (bool(sd.flag & SD_BSDF_NEEDS_LCG) ){
    sd.lcg_state = lcg_init(arg.state.rng_hash + arg.state.rng_offset + arg.state.sample_rsv *  0xb4bc3953);
}

}

void shader_setup_from_ray(
                          in Intersection isect,
                          in Ray ray)
{
  PROFILING_INIT(kg, PROFILING_SHADER_SETUP);

  sd.object = (isect.object == OBJECT_NONE) ? int( kernel_tex_fetch(_prim_object, isect.prim)) :
                                                isect.object;
  sd.lamp = LAMP_NONE;
  sd.type = isect.type;
  sd.flag = 0;
  sd.object_flag = int(kernel_tex_fetch(_object_flag, sd.object));

  /* matrices and time */
#ifdef _OBJECT_MOTION_
  shader_setup_object_transforms(kg, sd, ray->time);
#endif
  sd.time = ray.time;
  sd.prim = int(kernel_tex_fetch(_prim_index, isect.prim));
  sd.ray_length = isect.t;
  sd.u = isect.u;
  sd.v = isect.v;

#ifdef _HAIR_
  if (sd->type & PRIMITIVE_ALL_CURVE) {
    /* curve */
    curve_shader_setup(kg, sd, isect, ray);
  }
  else
#endif
  if(bool(sd.type & PRIMITIVE_TRIANGLE) ){
    /* static triangle */
    float3 Ng = triangle_normal();
    sd.shader = int(kernel_tex_fetch(_tri_shader, sd.prim));

    /* vectors */
    sd.P = triangle_refine(isect, ray);
    sd.Ng = Ng;
    sd.N  = Ng;

    /* smooth normal */
    if( bool (sd.shader & SHADER_SMOOTH_NORMAL))
      sd.N = triangle_smooth_normal(Ng, sd.prim, sd.u, sd.v);

#ifdef _DPDU_
    /* dPdu/dPdv */
    triangle_dPdudv(sd.prim, sd.dPdu, sd.dPdv);
#endif
  }
  else {
    /* motion triangle */
    //motion_triangle_shader_setup(kg, sd, isect, ray, false);
  }

  sd.I = -ray.D;

  sd.flag |= kernel_tex_fetch(_shaders, (sd.shader & SHADER_MASK)).flags;

  if (isect.object != OBJECT_NONE) {
    /* instance transform */
    object_normal_transform(sd.N);
    object_normal_transform(sd.Ng);
#ifdef _DPDU_
    object_dir_transform_auto(sd.dPdu);
    object_dir_transform_auto(sd.dPdv);
#endif
  }

  /* backfacing test */
  bool backfacing = (dot(sd.Ng, sd.I) < 0.0f);

  if (backfacing) {
    sd.flag |= int(SD_BACKFACING);
    sd.Ng = -sd.Ng;
    sd.N = -sd.N;
#ifdef _DPDU_
    sd.dPdu = -sd.dPdu;
    sd.dPdv = -sd.dPdv;
#endif
  }

#ifdef _RAY_DIFFERENTIALS_
  /* differentials */
  differential_transfer(sd.dP, ray.dP, ray.D, ray.dD, sd.Ng, isect.t);
  differential_incoming(sd.dI, ray.dD);
  differential_dudv(sd.du, sd.dv, sd.dPdu, sd.dPdv, sd.dP, sd.Ng);
#endif

  PROFILING_SHADER(sd.shader);
  PROFILING_OBJECT(sd.object);
}


void shader_prepare_closures()
{
  /* We can likely also do defensive sampling at deeper bounces, particularly
   * for cases like a perfect mirror but possibly also others. This will need
   * a good heuristic. */
  if (arg.state.bounce + arg.state.transparent_bounce == 0 &&  sd.num_closure > 1) {

    int it_begin = sd.alloc_offset;

    float sum = 0.0f;
    for (int i = 0; i < sd.num_closure; i++) { 
      if (CLOSURE_IS_BSDF_OR_BSSRDF(getSC().type)) {
        sum += getSC().sample_weight;
      }
      sd.alloc_offset = getSC().next;
    }
    sd.alloc_offset = it_begin;

    for (int i = 0; i < sd.num_closure; i++) {
      if (CLOSURE_IS_BSDF_OR_BSSRDF(getSC().type)) {
        getSC().sample_weight = max(getSC().sample_weight, 0.125f * sum);
      }
      sd.alloc_offset = getSC().next;
    }
    sd.alloc_offset = it_begin;

  }

 

}



/* Emission */
#define  object_attribute_map_offset(object) uint(kernel_tex_fetch(_objects, object).attribute_map_offset)
#define  light_select_reached_max_bounces(index,bounce) (bounce > kernel_tex_fetch(_lights, index).max_bounces)
#define  light_select_num_samples(index) kernel_tex_fetch(_lights, index).samples
/* return the probability distribution function in the direction I,
 * given the parameters and the light's surface normal.  This MUST match
 * the PDF computed by sample(). */
ccl_device float emissive_pdf(const float3 Ng, const float3 I)
{
  float cosNO = fabsf(dot(Ng, I));
  return (cosNO > 0.0f) ? 1.0f : 0.0f;
}
ccl_device float3 emissive_simple_eval(const float3 Ng, const float3 I)
{
  float res = emissive_pdf(Ng, I);

  return make_float3(res, res, res);
}
ccl_device float3 shader_emissive_eval(inout ShaderData sd)
{
  if (bool(sd.flag & SD_EMISSION)) {

    return emissive_simple_eval(sd.Ng, sd.I) * sd.closure_emission_background;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}




void motion_triangle_verts_for_step(
                                                      uint4 tri_vindex,
                                                      int offset,
                                                      int numverts,
                                                      int numsteps,
                                                      int step,
                                                      inout float3 verts[3])
{
  if (step == numsteps) {
    /* center step: regular vertex location */
    verts[0] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 0));
    verts[1] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 1));
    verts[2] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 2));
  }
  else {
    /* center step not store in this array 
    if (step > numsteps)
      step--;

    offset += step * numverts;

    verts[0] = float4_to_float3(kernel_tex_fetch(_attributes_float3, offset + tri_vindex.x));
    verts[1] = float4_to_float3(kernel_tex_fetch(_attributes_float3, offset + tri_vindex.y));
    verts[2] = float4_to_float3(kernel_tex_fetch(_attributes_float3, offset + tri_vindex.z));
    */
  }
}

/* Time interpolation of vertex positions and normals */
ccl_device_inline int find_attribute_motion(
                                            int object,
                                            uint id,
                                            inout AttributeElement elem)
{
  /* todo: find a better fastersolution(for) this, maybe store offset per object */

  uint  attr_offset = object_attribute_map_offset(object);
  uint4 attr_map    = kernel_tex_fetch(_attributes_map, attr_offset);

  while (attr_map.x != id) {
    attr_offset += ATTR_PRIM_TYPES;
    attr_map = kernel_tex_fetch(_attributes_map, attr_offset);
  }

  elem = AttributeElement(attr_map.y);

  /* return result */
  return (attr_map.y == ATTR_ELEMENT_NONE) ? int(ATTR_STD_NOT_FOUND) : int(attr_map.z);

}

ccl_device_inline void motion_triangle_vertices(int object, int prim, float time, inout float3 verts[3])
{

  /* get motion info */
  int numsteps=0, numverts= 0;
  object_motion_info(object, numsteps, numverts, null_int);
  
  /* figure out_rsv which steps we need to fetch and their interpolation factor */
  int maxstep = numsteps * 2;
  int step = min(int(time * maxstep) , maxstep - 1);
  float t = time * maxstep - step;

  /* find attribute */
  AttributeElement elem;
  int offset = find_attribute_motion(object, ATTR_STD_MOTION_VERTEX_POSITION, elem);

  /* fetch vertex coordinates */
  float3 next_verts[3];
  uint4 tri_vindex = kernel_tex_fetch(_tri_vindex, prim);

  motion_triangle_verts_for_step(tri_vindex, offset, numverts, numsteps, step, verts);
  motion_triangle_verts_for_step(tri_vindex, offset, numverts, numsteps, step + 1, next_verts);

  /* interpolate between steps */
  verts[0] = (1.0f - t) * verts[0] + t * next_verts[0];
  verts[1] = (1.0f - t) * verts[1] + t * next_verts[1];
  verts[2] = (1.0f - t) * verts[2] + t * next_verts[2];

}

/* Triangle vertex locations */
ccl_device_inline void triangle_vertices(int prim,out float3 P[3])
{
  const uint4 tri_vindex = kernel_tex_fetch(_tri_vindex, prim);
  P[0] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 0));
  P[1] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 1));
  P[2] = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 2));
}

/* returns true if the triangle is has motion blur or an instancing transform applied */
ccl_device_inline bool triangle_world_space_vertices(int object, int prim, float time, inout float3 V[3])
{
  bool has_motion = false;
  const int object_flag = int(kernel_tex_fetch(_object_flag, object));

  if (bool(object_flag & SD_OBJECT_HAS_VERTEX_MOTION) && time >= 0.0f) {
    motion_triangle_vertices(object, prim, time, V);
    has_motion = true;
  }
  else {
    triangle_vertices(prim, V);
  }

  if (!(bool(object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {

#ifdef _OBJECT_MOTION_
    float object_time = (time >= 0.0f) ? time : 0.5f;
    #ifdef _KERNEL_VULKAN_
        Transform tfm_null;Transform_NULL(tfm_null);
        Transform tfm = object_fetch_transform_motion_test(object, object_time, tfm_null);
    #else
        Transform tfm = object_fetch_transform_motion_test(object, object_time, NULL);
    #endif
#else
    Transform tfm = object_fetch_transform(object, OBJECT_TRANSFORM);
#endif

    V[0] = transform_point((tfm), V[0]);

    V[1] = transform_point((tfm), V[1]);

    V[2] = transform_point((tfm), V[2]);

    has_motion = true;
  }

  return has_motion;

}
float triangle_light_pdf_area(const float3 Ng,const float3 I,float t)
{
  float pdf    = kernel_data.integrator.pdf_triangles;
  float cos_pi = fabsf(dot(Ng, I));

  if (cos_pi == 0.0f)
    return 0.0f;

  return t * t * pdf / cos_pi;
}


ccl_device_forceinline float triangle_light_pdf(inout ShaderData sd, float t)
{
  /* A naive heuristic to decide between costly solid angle sampling
   * and simple area sampling, comparing the distance to the triangle plane
   * to the length of the edges of the triangle. */

  float3 V[3];
  bool has_motion = triangle_world_space_vertices(sd.object, sd.prim, sd.time, V);

  const float3 e0 = V[1] - V[0];
  const float3 e1 = V[2] - V[0];
  const float3 e2 = V[2] - V[1];
  const float longest_edge_squared = max(len_squared(e0), max(len_squared(e1), len_squared(e2)));
  const float3 N = cross(e0, e1);
  const float distance_to_plane = fabsf(dot(N, sd.I * t)) / dot(N, N);

  if (longest_edge_squared > distance_to_plane * distance_to_plane) {
    /* sd contains the point on the light source
     * calculate Px, the point that we're shading */
    const float3 Px = sd.P + sd.I * t;
    const float3 v0_p = V[0] - Px;
    const float3 v1_p = V[1] - Px;
    const float3 v2_p = V[2] - Px;

    const float3 u01 = safe_normalize(cross(v0_p, v1_p));
    const float3 u02 = safe_normalize(cross(v0_p, v2_p));
    const float3 u12 = safe_normalize(cross(v1_p, v2_p));

    const float alpha = fast_acosf(dot(u02, u01));
    const float beta = fast_acosf(-dot(u01, u12));
    const float gamma = fast_acosf(dot(u02, u12));
    const float solid_angle = alpha + beta + gamma - M_PI_F;

    /* pdf_triangles is calculated over triangle area, but we're not sampling over its area */
    if (UNLIKELY(solid_angle == 0.0f)) {
      return 0.0f;
    }
    else {
      float area = 1.0f;
      if (has_motion) {
        /* get the center frame vertices, this is what the PDF was calculated from */
        triangle_world_space_vertices(sd.object, sd.prim, -1.0f, V);
        area = triangle_area(V[0], V[1], V[2]);
      }
      else {
        area = 0.5f * len(N);
      }
      const float pdf = area * kernel_data.integrator.pdf_triangles;
      return pdf / solid_angle;
    }
  }
  else {
    float pdf = triangle_light_pdf_area(sd.Ng, sd.I, t);
    if (has_motion) {
      const float area = 0.5f * len(N);
      if (UNLIKELY(area == 0.0f)) {
        return 0.0f;
      }
      /* scale the PDF.
       * area = the area the sample_rsv was taken from
       * area_pre = the are from which pdf_triangles was calculated from */
      triangle_world_space_vertices(sd.object, sd.prim, -1.0f, V);
      const float area_pre = triangle_area(V[0], V[1], V[2]);
      pdf = pdf * area_pre / area;
    }
    return pdf;
  }
}


/* Indirect Primitive Emission */

ccl_device_noinline_cpu float3 indirect_primitive_emission(
    inout ShaderData sd, float t, int path_flag, float bsdf_pdf)
{
  /* evaluate emissive closure */
  float3 L = shader_emissive_eval(sd);

#ifdef _HAIR_
  if (!(bool(path_flag & PATH_RAY_MIS_SKIP)) && (sd.flag & SD_USE_MIS) &&
      (sd.type & PRIMITIVE_ALL_TRIANGLE))
#else
  if (!(bool(path_flag & PATH_RAY_MIS_SKIP)) && bool(sd.flag & SD_USE_MIS))
#endif
  {
    /* multiple importance sampling, get triangle light pdf,
     * and compute weight with respect to BSDF pdf */
    float pdf = triangle_light_pdf(sd, t);
    float mis_weight = power_heuristic(bsdf_pdf, pdf);

    return L * mis_weight;
  }

  return L;
}


#define  path_radiance_clamp(L,  bounce)\
{\
  float limit = (bounce > 0) ? kernel_data.integrator.sample_clamp_indirect :kernel_data.integrator.sample_clamp_direct;\
  float sum = reduce_add(fabs(L));\
  if (sum > limit) {L *= limit / sum; }\
}

ccl_device_inline void path_radiance_accum_emission(
                                                    int state_flag,
                                                    int state_bounce,
                                                    float3 throughput,
                                                    float3 value)
{
#ifdef _SHADOW_TRICKS_
  if (bool(state_flag & PATH_RAY_SHADOW_CATCHER) ){
    return;
  }
#endif

  float3 contribution = throughput * value;
#ifdef _CLAMP_SAMPLE_
  path_radiance_clamp(contribution, state_bounce - 1);
#endif

#ifdef _PASSES_
  if (bool(prd.L.use_light_pass)) {
    if (state_bounce == 0)
      prd.L.emission += contribution;
    else if (state_bounce == 1)
      prd.L.direct_emission += contribution;
    else
      prd.L.indirect += contribution;
  }
  else
#endif
  {
    prd.L.emission += contribution;
  }
}


ccl_device float3 shader_bsdf_transparency(in ShaderData sd)
{
  if (bool(sd.flag & SD_HAS_ONLY_VOLUME)) {
    return make_float3(1.0f, 1.0f, 1.0f);
  }
  else if (bool(sd.flag & SD_TRANSPARENT)) {
    return sd.closure_transparent_extinction;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}


ccl_device_forceinline bool kernel_path_shader_apply(
                                                    // KernelGlobals *kg,
                                                    // ShaderData *sd,
                                                    //  ccl_addr_space PathState *state,
                                                    //  ccl_addr_space Ray *ray,
                                                    // float3 throughput,
                                                    // ShaderData *emission_sd,
                                                    // PathRadiance *L,
                                                    //  ccl_global float *buffer)
)
{
  PROFILING_INIT(kg, PROFILING_SHADER_APPLY);

  float exeNum = 0.f;
#ifdef _SHADOW_TRICKS_
  if ( bool(sd.object_flag & SD_OBJECT_SHADOW_CATCHER) ) {
    /* object shadow catcher
    if (bool(arg.state.flag & PATH_RAY_TRANSPARENT_BACKGROUND)) {
      arg.state.flag |= int(PATH_RAY_SHADOW_CATCHER | PATH_RAY_STORE_SHADOW_INFO);
      float3 bg = make_float3(0.0f, 0.0f, 0.0f);
      if (!bool(kernel_data.background.transparent)) {
        bg = indirect_background(kg, emission_sd, state, NULL, ray);
      }
      path_radiance_accum_shadowcatcher(L, throughput, bg);
    }
    */
   exeNum+=1.f;
  }
  else if (bool(arg.state.flag & PATH_RAY_SHADOW_CATCHER)) {
    /* Only update transparency after shadow catcher bounce. */
    prd.L.shadow_transparency *= average(shader_bsdf_transparency(sd));
    exeNum+=1.f;
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
  kernel_write_data_passes(kg, buffer, L, sd, state, throughput);
#endif



   if (kernel_data.integrator.filter_glossy != FLT_MAX) {
    float blur_pdf = kernel_data.integrator.filter_glossy * arg.state.min_ray_pdf;
    if (blur_pdf < 1.0f) {
        float ply_tmp  = sd.randb_closure;
        int   ply_tmp2 = sd.num_closure_left;
        sd.num_closure_left = -1;
        sd.randb_closure = blur_pdf;
        executeCallableNV(4u,1);
        sd.randb_closure = ply_tmp;
        sd.num_closure_left = ply_tmp2;
        exeNum+=1.f;
      }
  }

  /* blurring of bsdf after bounces, for rays that have a small likelihood
   * of following this particular path (diffuse, rough glossy) 
   if (kernel_data.integrator.filter_glossy != FLT_MAX) {
    float blur_pdf = kernel_data.integrator.filter_glossy * arg.state.min_ray_pdf;
    if (blur_pdf < 1.0f) {
      float blur_roughness = sqrtf(1.0f - blur_pdf) * 0.5f;
      shader_bsdf_blur(kg, sd, blur_roughness);
    }
  }
  */




#ifdef _EMISSION_
  /* emission */

  if (bool(sd.flag & SD_EMISSION)) {
    float3 emission = indirect_primitive_emission(sd, sd.ray_length, arg.state.flag, arg.state.ray_pdf);
    path_radiance_accum_emission(arg.state.flag,arg.state.bounce, arg.L.throughput, emission);
    exeNum+=1.f;
  }
#endif /* __EMISSION__ */



#ifdef ENABLE_PROFI
 PROFI_HIT_SD_FLAG(exeNum);
#endif

  return true;

}

ccl_device_inline float path_state_continuation_probability(/*KernelGlobals *kg,
                                                            ccl_addr_space PathState *state,
                                                            const float3 throughput*/)
{
  if (bool(arg.state.flag & PATH_RAY_TERMINATE_IMMEDIATE)) {
    /* Ray is to be terminated immediately. */
    return 0.0f;
  }
  else if (bool(arg.state.flag & PATH_RAY_TRANSPARENT) ) {
    /* Do at least specified number of bounces without RR. */
    if (arg.state.transparent_bounce <= kernel_data.integrator.transparent_min_bounce) {
      return 1.0f;
    }
#ifdef _SHADOW_TRICKS_
    /* Exception for shadow catcher not working correctly with RR. */
    else if ( bool(arg.state.flag & PATH_RAY_SHADOW_CATCHER) && (arg.state.transparent_bounce <= 8)) {
      return 1.0f;
    }
#endif
  }
  else {
    /* Do at least specified number of bounces without RR. */
    if (arg.state.bounce <= kernel_data.integrator.min_bounce) {
      return 1.0f;
    }
#ifdef _SHADOW_TRICKS_
    /* Exception for shadow catcher not working correctly with RR. */
    else if ( bool(arg.state.flag & PATH_RAY_SHADOW_CATCHER) && (arg.state.bounce <= 3)) {
      return 1.0f;
    }
#endif
  }

  /* Probabilistic termination: use sqrt() to roughly match typical view
   * transform and do path termination a bit later on average. */
  return min(sqrtf(max3(fabs(arg.L.throughput)) * arg.state.branch_factor), 1.0f);
}

ccl_device_inline bool path_state_ao_bounce()
{
  if (arg.state.bounce <= kernel_data.integrator.ao_bounces) {
    return false;
  }
  int bounce = arg.state.bounce - arg.state.transmission_bounce - int(arg.state.glossy_bounce > 0);
  return (bounce > kernel_data.integrator.ao_bounces);
}


void main()
{

//set_arg_state
//switch state prd ==> arg
arg.state  = prd.state;
set_arg_L


Ray ray;
ray.P = vec4(gl_WorldRayOriginNV, 0.0);
ray.D = vec4(gl_WorldRayDirectionNV, 0.0);
ray.t = gl_HitTNV;
Intersection isect;
isect.t      = gl_HitTNV;
isect.u      = (1.0 - attribs.x) - attribs.y;
isect.v      = attribs.x;
isect.prim   = gl_PrimitiveID;
isect.object = 0;
isect.type   = int(push.data_ptr._prim_type.data[gl_PrimitiveID]);

#ifdef ENABLE_PROFI
  PROFI_IDX  = atomicAdd(counter[PROFI_ATOMIC],1);
  PROFI_HIT_IDX(gl_LaunchIDNV.x,gl_LaunchIDNV.y,arg.state.rng_hash);
#endif




kernel_path_lamp_emission(ray,isect);


if (path_state_ao_bounce()) {
      prd_return(false);
}

shader_setup_from_ray(isect, ray);
shader_eval_surface();
shader_prepare_closures();


/* Apply shadow catcher, holdout, emission. */
if (!kernel_path_shader_apply()){     //   kg, &sd, state, ray, throughput, emission_sd, L, buffer)) {
  prd_return(false);
}

/* path termination. this is a strange place to put the termination, it's
  * mainly due to the mixed in MIS that we use. gives too many unneeded
  * shader evaluations, only need emission if we are going to terminate */
float probability = path_state_continuation_probability();

#ifdef ENABLE_PROFI
PROFI_HIT_PROB(probability)
#endif

if (probability == 0.0f) {
  prd_return(false);
}
else if (probability != 1.0f) {
  float terminate =/* path_state_rng_1D(kg, state, PRNG_TERMINATE);*/
    path_rng_1D(
      arg.state.rng_hash, arg.state.sample_rsv, arg.state.num_samples, arg.state.rng_offset + int(PRNG_TERMINATE));
  if (terminate >= probability)
    prd_return(false);
    
  arg.L.throughput /= probability;
}
  
#ifdef ENABLE_PROFI
PROFI_HIT_PROB(probability)
#endif



#ifdef _EMISSION_
    /* direct lighting */
    kernel_path_surface_connect_light( );
#endif


//switch state arg ==> prd
if (!bool(ply_return_bounce))
{
  prd_set_arg_L
  prd_return(false);
}

prd_set_arg_L

prd_return(true);

}

