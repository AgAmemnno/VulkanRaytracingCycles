#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#define PUSH_POOL_SC
#define PUSH_KERNEL_TEX
#define SET_KERNEL 2
#define GSD plymo.sd
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"

#include "kernel/kernel_globals.h.glsl"

struct LightSample {
  float3 P;       /* position on light, or direction for distant light */
  float3 Ng;      /* normal on light */
  float3 D;       /* direction from shading point to light */
  float t;        /* distance to light (FLT_MAX for distant light) */
  float u, v;     /* parametric coordinate on primitive */
  float pdf;      /* light sampling probability density function */
  float eval_fac; /* intensity multiplier */
  int object;     /* object id for triangle/curve lights */
  int prim;       /* primitive id for triangle/curve lights */
  int shader;     /* shader id */
  int lamp;       /* lamp id */
  LightType type; /* type of light */
} ;

#include "kernel/kernel_light_common.h.glsl"
#include "kernel/kernel_light_background.h.glsl"

#include "kernel/kernel_random.h.glsl"

#include "kernel/kernel_differential.h.glsl"

#include "kernel/closure/emissive.h.glsl"

//#include "kernel/geom/geom_triangle.h.glsl"
ccl_device_inline float3
triangle_smooth_normal(float3 Ng, int prim, float u, float v)
{
  /* load triangle vertices */
  const uint4 tri_vindex = kernel_tex_fetch(_tri_vindex, prim);
  float3 n0 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.x));
  float3 n1 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.y));
  float3 n2 = float4_to_float3(kernel_tex_fetch(_tri_vnormal, tri_vindex.z));

  float3 N = safe_normalize((1.0f - u - v) * n2 + u * n0 + v * n1);

  return is_zero(N) ? Ng : N;
}

/* Ray differentials on triangle */

ccl_device_inline void triangle_dPdudv(
                                       int prim,
                                       ccl_addr_space inout float3 dPdu,
                                       ccl_addr_space inout float3 dPdv)
{
  /* fetch triangle vertex coordinates */
  const uint4 tri_vindex = kernel_tex_fetch(_tri_vindex, prim);
  const float3 p0 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 0));
  const float3 p1 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 1));
  const float3 p2 = float4_to_float3(kernel_tex_fetch(_prim_tri_verts, tri_vindex.w + 2));

  /* compute derivatives of P w.r.t. uv */
  dPdu = (p0 - p2);
  dPdv = (p1 - p2);
}
//#include "kernel/geom/geom_triangle.h.glsl"


//Bsdf_eval <plymo> 
struct args_acc_light{
  //int use_light_pass;
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 path_total;
  vec4 throughput;
};



#define ply_L2Eval_lamp pay.use_light_pass
#define ply_L2Eval_light_uv_term_double pay.L.emission.xyzw
#define ply_L2Eval_light_hasemission pay.type
#define ply_L2Eval_use_light_pass pay.use_light_pass
#define ply_L2Eval_profi_idx pay.L.direct_emission.x


#define ply_L2Eval_diffuse pay.L.emission
#define ply_L2Eval_glossy   pay.L.direct_emission
#define ply_L2Eval_transmission pay.L.indirect
#define ply_L2Eval_transparent pay.L.path_total
#define ply_L2Eval_sum_no_mis pay.L.throughput





#define ply_rng_u plymo.eval.diffuse.x
#define ply_rng_v plymo.eval.diffuse.y
#define ply_prs_diffuse  pay.sd.N
#define ply_prs_glossy  pay.sd.I
#define ply_prs_transmission  pay.sd.dP.dx
#define ply_prs_volume  pay.sd.dP.dy



struct PRG2ARG
{
args_sd    sd;     // 140
args_acc_light L;  // 80
int  use_light_pass;
int  type;
Ray ray; //104
PathState  state; //56
};


// 4 + 68 + 104 + 128 + 56
#define sizeof_hitPatload0 360
#define ply_return_bounce   pay.type
#define ply_label  pay.sd.alloc_offset

struct PLMO_SD
{
ShaderData sd;   //340
};

struct PLMO_SD_EVAL
{
args_sd    sd;   // 140
BsdfEval eval;   // 80

vec4 omega_in;    
differential3 domega_in; 

int    label;
int    use_light_pass;
int   type;
float    pdf;
};
// 140 + 80 + 52 = 272

layout(location = 0) callableDataInNV PRG2ARG pay;
layout(location = 1) callableDataNV   PLMO_SD plymo;


#define set_prg3_tiny_sd(omega_in,pdf,label,light_pass,use_mis, _type ,state_flag) {\
  plymo.sd.P      = pay.sd.P;\
  plymo.sd.N      = pay.sd.N;\
  plymo.sd.Ng     = pay.sd.Ng;\
  plymo.sd.I      = pay.sd.I;\
  plymo.sd.shader = pay.sd.flag;\
  plymo.sd.flag   = pay.sd.type;\
  plymo.sd.object_flag = pay.sd.object;\
  plymo.sd.prim     =  pay.sd.num_closure;\
  plymo.sd.type     =  pay.sd.atomic_offset;\
  plymo.sd.u        =  pay.sd.time;\
  plymo.sd.v        =  pay.sd.ray_length;\
  plymo.sd.object   =  pay.sd.alloc_offset;\
  plymo.sd.time     =  uintBitsToFloat(pay.sd.lcg_state);\
  plymo.sd.dP       =  pay.sd.dI;\
  plymo.sd.dI.dx    =  vec4(intBitsToFloat(state_flag), intBitsToFloat(use_mis),intBitsToFloat(1234),0.);\
  plymo.sd.ray_P    =  omega_in;\
  plymo.sd.lcg_state = label;\
  plymo.sd.num_closure = light_pass;\
  plymo.sd.num_closure_left = _type;\
  plymo.sd.randb_closure = pdf;\
}

#define PLYMO_EVAL_diffuse plymo.sd.dI.dx
#define PLYMO_EVAL_glossy  plymo.sd.dI.dy
#define PLYMO_EVAL_transmission  vec4(plymo.sd.du.dx,plymo.sd.du.dy,plymo.sd.dv.dx,plymo.sd.dv.dy)
#define PLYMO_EVAL_set_mul_transmission(value){\
     plymo.sd.du.dx  *= value;\
     plymo.sd.du.dy  *= value;\
     plymo.sd.dv.dx  *= value;\
}
#define PLYMO_EVAL_set_mul3_transmission(value){\
     plymo.sd.du.dx  *= value.x;\
     plymo.sd.du.dy  *= value.y;\
     plymo.sd.dv.dx  *= value.z;\
}
#define PLYMO_EVAL_set_zero_transmission {\
       plymo.sd.du.dx    = 0.f;\
       plymo.sd.du.dy    = 0.f;\
       plymo.sd.dv.dx    = 0.f;\
}
#define PLYMO_EVAL_transparent  plymo.sd.dPdu
#define PLYMO_EVAL_sum_no_mis  plymo.sd.dPdv
#define PLYMO_EVAL_use_light_pass  plymo.sd.num_closure

#define set_ply_Eval {\
  ply_L2Eval_diffuse = PLYMO_EVAL_diffuse;\
  ply_L2Eval_glossy= PLYMO_EVAL_glossy;\
  ply_L2Eval_transmission= PLYMO_EVAL_transmission;\
  ply_L2Eval_transparent= PLYMO_EVAL_transparent;\
  ply_L2Eval_sum_no_mis= PLYMO_EVAL_sum_no_mis;\
}




void PLYMO_bsdf_eval_mul3( float3 value)
{
#ifdef _SHADOW_TRICKS_
  PLYMO_EVAL_sum_no_mis *= value;
#endif
#ifdef _PASSES_
  if (PLYMO_EVAL_use_light_pass  !=0 ) {
    PLYMO_EVAL_diffuse *= value;
    PLYMO_EVAL_glossy *= value;
    PLYMO_EVAL_set_mul3_transmission(value);
    //PLYMO.eval.volume *= value;
    /* skipping transparent, this function is used by for eval(), will be zero then */
  }
  else
  PLYMO_EVAL_diffuse *= value;
#else
  PLYMO_EVAL_diffuse *= value;
#endif

};


bool PLYMO_bsdf_eval_is_zero()
{
#ifdef _PASSES_
  if (PLYMO_EVAL_use_light_pass !=0) {
    return is_zero(PLYMO_EVAL_diffuse) && is_zero(PLYMO_EVAL_glossy) && is_zero(PLYMO_EVAL_transmission) &&
           is_zero(PLYMO_EVAL_transparent) ; //&& is_zero(eval.volume);
  }
  else
#endif
  {
    return is_zero(PLYMO_EVAL_diffuse);
  }
}


float3 PLYMO_bsdf_eval_sum()
{
#ifdef _PASSES_
  if (PLYMO_EVAL_use_light_pass !=0) {
    return PLYMO_EVAL_diffuse + PLYMO_EVAL_glossy + PLYMO_EVAL_transmission;// + PLYMO_EVAL_volume;
  }
  else
#endif
    return PLYMO_EVAL_diffuse;
}

void PLYMO_bsdf_eval_mis(float value)
{
#ifdef _PASSES_
  if (PLYMO_EVAL_use_light_pass !=0) {
    PLYMO_EVAL_diffuse *= value;
    PLYMO_EVAL_glossy *= value;
    PLYMO_EVAL_set_mul_transmission(value);
    //PLYMO_EVAL_volume *= value;
    /* skipping transparent, this function is used by for eval(), will be zero then */
  }
  else
#endif
  {
    PLYMO_EVAL_diffuse *= value;
  }
}
void PLYMO_bsdf_eval_mul(float value)
{
#ifdef _SHADOW_TRICKS_
  PLYMO_EVAL_sum_no_mis *= value;
#endif
  PLYMO_bsdf_eval_mis(value);
}


#define get_ply_type int(plymo.eval.glossy.y)
#define ply_type plymo.eval.glossy.y



#include "kernel/geom/geom_object.h.glsl"
#include "kernel/geom/geom_object.h.glsl"

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
  if (bool(pay.use_light_pass)) {
    if (state_bounce == 0)
      pay.L.emission += contribution;
    else if (state_bounce == 1)
      pay.L.direct_emission += contribution;
    else
      pay.L.indirect += contribution;
  }
  else
#endif
  {
    pay.L.emission += contribution;
  }
}





ccl_device int light_distribution_sample(inout float randu)
{
  /* This is basically std::upper_bound as used by pbrt, to find a point light or
   * triangle to emit from, proportional to area. a good improvement would be to
   * also sample_rsv proportional to power, though it's not so well defined with
   * arbitrary shaders. */
  int first =  0;
  int _len   =  kernel_data.integrator.num_distribution + 1;
  float r   =   randu;

  do {
    int half_len = _len >> 1;
    int middle = first + half_len;

    if (r < kernel_tex_fetch(_light_distribution, middle).totarea) {
      _len = half_len;
    }
    else {
      first = middle + 1;
      _len = _len - half_len - 1;
    }
  } while (_len > 0);

  /* Clamping should not be needed but float rounding errors seem to
   * make this fail on rare occasions. */
  int index = clamp(first - 1, 0, kernel_data.integrator.num_distribution - 1);

  /* Rescale to reuse random number. this helps the 2D samples within
   * each area light be stratified as well. */
  float distr_min = kernel_tex_fetch(_light_distribution, index).totarea;
  float distr_max = kernel_tex_fetch(_light_distribution, index + 1).totarea;
  randu = (r - distr_min) / (distr_max - distr_min);

  return index;
}



#define  object_attribute_map_offset(object) uint(kernel_tex_fetch(_objects, object).attribute_map_offset)
#define  light_select_reached_max_bounces(index,bounce) (bounce > kernel_tex_fetch(_lights, index).max_bounces)
#define  light_select_num_samples(index) kernel_tex_fetch(_lights, index).samples

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

void triangle_light_sample(
                                                  int prim,
                                                  int object,
                                                  float randu,
                                                  float randv,
                                                  float time,
                                                  inout LightSample ls,
                                                  const float3 P)
{
  /* A naive heuristic to decide between costly solid angle sampling
   * and simple area sampling, comparing the distance to the triangle plane
   * to the length of the edges of the triangle. */

  float3 V[3];
  bool has_motion = triangle_world_space_vertices(object, prim, time, V);

  const float3 e0 = V[1] - V[0];
  const float3 e1 = V[2] - V[0];
  const float3 e2 = V[2] - V[1];
  const float longest_edge_squared = max(len_squared(e0), max(len_squared(e1), len_squared(e2)));
  const float3 N0 = cross(e0, e1);
  float Nl = 0.0f;
  ls.Ng = safe_normalize_len(N0, Nl);
  float area = 0.5f * Nl;

  /* flip normal if necessary */
  const int object_flag = int(kernel_tex_fetch(_object_flag, object));
  if (bool(object_flag & SD_OBJECT_NEGATIVE_SCALE_APPLIED)) {
    ls.Ng = -ls.Ng;
  }
  ls.eval_fac = 1.0f;
  ls.shader = int(kernel_tex_fetch(_tri_shader, prim));
  ls.object = object;
  ls.prim = prim;
  ls.lamp = LAMP_NONE;
  ls.shader |= int(SHADER_USE_MIS);
  ls.type = LIGHT_TRIANGLE;
  float distance_to_plane = fabsf(dot3(N0, V[0] - P) / dot3(N0, N0));
  if (longest_edge_squared > distance_to_plane * distance_to_plane) {
    /* see James Arvo, "Stratified Sampling of Spherical Triangles"
     * http://www.graphics.cornell.edu/pubs/1995/Arv95c.pdf */

    /* project the triangle to the unit sphere
     * and calculate its edges and angles */
    const float3 v0_p = V[0] - P;
    const float3 v1_p = V[1] - P;
    const float3 v2_p = V[2] - P;

    const float3 u01 = safe_normalize(cross(v0_p, v1_p));
    const float3 u02 = safe_normalize(cross(v0_p, v2_p));
    const float3 u12 = safe_normalize(cross(v1_p, v2_p));

    const float3 A = safe_normalize(v0_p);
    const float3 B = safe_normalize(v1_p);
    const float3 C = safe_normalize(v2_p);

    const float cos_alpha = dot(u02, u01);
    const float cos_beta = -dot(u01, u12);
    const float cos_gamma = dot(u02, u12);

    /* calculate dihedral angles */
    const float alpha = fast_acosf(cos_alpha);
    const float beta = fast_acosf(cos_beta);
    const float gamma = fast_acosf(cos_gamma);
    /* the area of the unit spherical triangle = solid angle */
    const float solid_angle = alpha + beta + gamma - M_PI_F;

    /* precompute a few things
     * these could be re-used to take several samples
     * as they are independent of randu/randv */
    const float cos_c = dot(A, B);
    const float sin_alpha = fast_sinf(alpha);
    const float product = sin_alpha * cos_c;

    /* Select a random sub-area of the spherical triangle
     * and calculate the third vertex C_ of that new triangle */
    const float phi = randu * solid_angle - alpha;
    float s, t;
    fast_sincosf(phi, s, t);
    const float u = t - cos_alpha;
    const float v = s + product;
    const float3 U = safe_normalize(C - dot(C, A) * A);
    float q = 1.0f;
    const float det = ((v * s + u * t) * sin_alpha);
    if (det != 0.0f) {
      q = ((v * t - u * s) * cos_alpha - v) / det;
    }
    const float temp = max(1.0f - q * q, 0.0f);

    const float3 C_ = safe_normalize(q * A + sqrtf(temp) * U);

    /* Finally, select a random point along the edge of the new triangle
     * That point on the spherical triangle is the sampled ray direction */
    const float z = 1.0f - randv * (1.0f - dot(C_, B));
    ls.D = z * B + safe_sqrtf(1.0f - z * z) * safe_normalize(C_ - dot(C_, B) * B);

    /* calculate intersection with the planar triangle */
    if (!ray_triangle_intersect(P,
                                ls.D,
                                FLT_MAX,
                                V[0],
                                V[1],
                                V[2],
                                ls.u,
                                ls.v,
                                ls.t)) {
      ls.pdf = 0.0f;
      return;
    }

    ls.P = P + ls.D * ls.t;

    /* pdf_triangles is calculated over triangle area, but we're sampling over solid angle */
    if (UNLIKELY(solid_angle == 0.0f)) {
      ls.pdf = 0.0f;
      return;
    }
    else {
      if (has_motion) {
        /* get the center frame vertices, this is what the PDF was calculated from */
        triangle_world_space_vertices(object, prim, -1.0f, V);
        area = triangle_area(V[0], V[1], V[2]);
      }
      const float pdf = area * kernel_data.integrator.pdf_triangles;
      ls.pdf = pdf / solid_angle;
    }
  }
  else {
    /* compute random point in triangle. From Eric Heitz's "A Low-Distortion Map Between Triangle
     * and Square" */
    float u = randu;
    float v = randv;
    if (v > u) {
      u *= 0.5f;
      v -= u;
    }
    else {
      v *= 0.5f;
      u -= v;
    }

    const float t = 1.0f - u - v;
    ls.P = u * V[0] + v * V[1] + t * V[2];
    /* compute incoming direction, distance and pdf */
    ls.D = normalize_len(ls.P - P, ls.t);
    ls.pdf = triangle_light_pdf_area(ls.Ng, -ls.D, ls.t);
    if (has_motion && area != 0.0f) {
      /* scale the PDF.
       * area = the area the sample was taken from
       * area_pre = the are from which pdf_triangles was calculated from */
      triangle_world_space_vertices(object, prim, -1.0f, V);
      const float area_pre = triangle_area(V[0], V[1], V[2]);
      ls.pdf = ls.pdf * area_pre / area;
    }
    ls.u = u;
    ls.v = v;
  }
}


#define RETURN_TF(b) {lamp = (b)?1:0;return;}


/* Regular Light */

ccl_device_inline bool lamp_light_sample(int lamp, float randu, float randv, float3 P, inout LightSample ls)
{


  const ccl_global KernelLight klight =  kernel_tex_fetch(_lights, lamp);
  LightType type = LightType(klight.type);
  
  ls.type = type;
  ls.shader = klight.shader_id;
  ls.object = PRIM_NONE;
  ls.prim = PRIM_NONE;
  ls.lamp = lamp;
  ls.u = randu;
  ls.v = randv;

if (type == LIGHT_DISTANT) {
    /* distant light */
    float3 lightD = make_float3(klight.co[0], klight.co[1], klight.co[2]);
    float3 D = lightD;
    float radius = DistantLight_radius(klight);
    float invarea = DistantLight_invarea(klight);

    if (radius > 0.0f)
      D = distant_light_sample(D, radius,  randu,  randv);

    ls.P = D;
    ls.Ng = D;
    ls.D = -D;
    ls.t = FLT_MAX;

    float costheta = dot(lightD, D);
    ls.pdf = invarea / (costheta * costheta * costheta);
    ls.eval_fac = ls.pdf;
  }
#ifdef _BACKGROUND_MIS_
  else if (type == LIGHT_BACKGROUND) {
    /* infinite area light (e.g. light dome or env light) */
    float3 D = -background_light_sample(P, randu, randv, (ls.pdf));

    ls.P = D;
    ls.Ng = D;
    ls.D = -D;
    ls.t = FLT_MAX;
    ls.eval_fac = 1.0f;

  }
#endif
  else {
    ls.P = make_float3(klight.co[0], klight.co[1], klight.co[2]);

    if (type == LIGHT_POINT || type == LIGHT_SPOT) {

      float radius = SpotLight_radius(klight);
      if (radius > 0.0f)ls.P += sphere_light_sample(P, ls.P, radius,  randu,  randv);

      ls.D = normalize_len(ls.P - P, (ls.t));
      ls.Ng = -ls.D;
      float invarea = SpotLight_invarea(klight);
      ls.eval_fac = (0.25f * M_1_PI_F) * invarea;
      ls.pdf = invarea;

      if (type == LIGHT_SPOT) {
        /* spot light attenuation */
        float3 dir = make_float3(SpotLight_dir0(klight), SpotLight_dir1(klight), SpotLight_dir2(klight));
        ls.eval_fac *= spot_light_attenuation(dir, SpotLight_spot_angle(klight), SpotLight_spot_smooth(klight), ls.Ng);
        if (ls.eval_fac == 0.0f) {
          return false;
        }
      }
      
      float2 uv = map_to_sphere(ls.Ng);
      ls.u = uv.x;
      ls.v = uv.y;
      ls.pdf *= lamp_light_pdf(ls.Ng, -ls.D, ls.t);
    }
    else {
      /* area light */
      float3 axisu = make_float3(AreaLight_axisu0(klight), AreaLight_axisu1(klight), AreaLight_axisu2(klight));
      float3 axisv = make_float3(AreaLight_axisv0(klight) , AreaLight_axisv1(klight) , AreaLight_axisv2(klight));
      float3 D = make_float3(AreaLight_dir0(klight), AreaLight_dir1(klight), AreaLight_dir2(klight));
      float invarea = fabsf(AreaLight_invarea(klight));
      bool is_round = (AreaLight_invarea(klight) < 0.0f);

      if (dot(ls.P - P, D) > 0.0f) {
        return false;
      }

      float3 inplane;

      if (is_round) {

        inplane  = ellipse_sample(axisu * 0.5f, axisv * 0.5f,   randu,   randv);
        ls.P     += inplane;
        ls.pdf   = invarea;

      }else {

        inplane = ls.P;
        ls.pdf  = rect_light_sample(P, (ls.P), axisu, axisv,   randu,   randv, true);
        inplane = ls.P - inplane;

      }

      ls.u = dot(inplane, axisu) * (1.0f / dot(axisu, axisu)) + 0.5f;
      ls.v = dot(inplane, axisv) * (1.0f / dot(axisv, axisv)) + 0.5f;

      ls.Ng = D;
      ls.D = normalize_len(ls.P - P, (ls.t));


      ls.eval_fac = 0.25f * invarea;
      if (is_round) {
        ls.pdf *= lamp_light_pdf(D, -ls.D, ls.t);
      }
    }
  }

  ls.pdf *= kernel_data.integrator.pdf_lights;




  return (ls.pdf > 0.0f);
}


bool light_sample(                    vec2  rand,
                                      float time,
                                      float3 P,
                                      int bounce,
                                      inout LightSample ls)
{


  int lamp        =  ply_L2Eval_lamp;
  if (lamp < 0) {
    /* sample_rsv index */
    int index = light_distribution_sample(rand.x);
    /* fetch light data */
    const  KernelLightDistribution kdistribution = kernel_tex_fetch(_light_distribution, index);
    int prim = kdistribution.prim;

    if (prim >= 0) {
      int object      = LightDistribution_mesh_light_object_id(kdistribution);
      int shader_flag = LightDistribution_mesh_light_shader_flag(kdistribution);
      triangle_light_sample(prim, object, rand.x, rand.y, time, ls, P);

      ls.shader |= shader_flag;
      return (ls.pdf > 0.0f);
    }

    lamp = -prim - 1;
  }


  if (UNLIKELY(light_select_reached_max_bounces(lamp, bounce))) {
    return false;
  }




  return lamp_light_sample(lamp, rand.x, rand.y, P, ls);

}

bool lamp_light_eval(inout  LightSample ls,int lamp, float3 P, float3 D, float t)
{
  const ccl_global KernelLight klight = kernel_tex_fetch(_lights, lamp);
  LightType type = LightType(klight.type);
  ls.type = type;
  ls.shader = klight.shader_id;
  ls.object = PRIM_NONE;
  ls.prim = PRIM_NONE;
  ls.lamp = lamp;
  /* todo: missing texture coordinates */
  ls.u = 0.0f;
  ls.v = 0.0f;

  if (!bool(ls.shader & SHADER_USE_MIS))
    return false;

  if (type == LIGHT_DISTANT) {
    /* distant light */
    float radius = DistantLight_radius(klight);
    if (radius == 0.0f)
     return false;
    if (t != FLT_MAX)
     return false;

    /* a distant light is infinitely far away, but equivalent to a disk
     * shaped light exactly 1 unit away from the current shading point.
     *
     *     radius              t^2/cos(theta)
     *  <---------.           t = sqrt(1^2 + tan(theta)^2)
     *       tanth(area) 
= radius*radius*pi
     *       <----.
     *        \    |           (1 + tan(theta)^2)/cos(theta)
     *         \   |           (1 + tan(acos(cos(theta)))^2)/cos(theta)
     *       t  \th| 1         simplifies to
     *           \-|           1/(cos(theta)^3)
     *            \|           magic!
     *             P
     */

    float3 lightD = make_float3(klight.co[0], klight.co[1], klight.co[2]);
    float costheta = dot(-lightD, D);
    float cosangle = DistantLight_cosangle(klight);

    if (costheta < cosangle)
      return false;

    ls.P = -D;
    ls.Ng = -D;
    ls.D = D;
    ls.t = FLT_MAX;

    /* compute pdf */
    float invarea = DistantLight_invarea(klight);
    ls.pdf = invarea / (costheta * costheta * costheta);
    ls.eval_fac = ls.pdf;
  }
  else if (type == LIGHT_POINT || type == LIGHT_SPOT) {
    float3 lightP = make_float3(klight.co[0], klight.co[1], klight.co[2]);
    float radius = SpotLight_radius(klight);

    /* sphere light */
    if (radius == 0.0f)
      return false;

    if (!ray_aligned_disk_intersect(P, D, t, lightP, radius, (ls.P), (ls.t))) return false;
    

    ls.Ng = -D;
    ls.D = D;

    float invarea = SpotLight_invarea(klight);
    ls.eval_fac = (0.25f * M_1_PI_F) * invarea;
    ls.pdf = invarea;

  if (type == LIGHT_SPOT) {
        /* spot light attenuation */
        float3 dir = make_float3(SpotLight_dir0(klight), SpotLight_dir1(klight), SpotLight_dir2(klight));
        ls.eval_fac *= spot_light_attenuation(dir, SpotLight_spot_angle(klight), SpotLight_spot_smooth(klight), ls.Ng);

        if (ls.eval_fac == 0.0f)
            return false;
    }
    float2 uv = map_to_sphere(ls.Ng);
    ls.u = uv.x;
    ls.v = uv.y;
    /* compute pdf */
    if (ls.t != FLT_MAX)
        ls.pdf *= lamp_light_pdf(ls.Ng, -ls.D, ls.t);
    }
  else if (type == LIGHT_AREA) {
    /* area light */
    float invarea = fabsf(AreaLight_invarea(klight));
    bool is_round = (AreaLight_invarea(klight) < 0.0f);
    if (invarea == 0.0f)return false;

    float3 axisu = make_float3(AreaLight_axisu0(klight), AreaLight_axisu1(klight), AreaLight_axisu2(klight));
    float3 axisv = make_float3(AreaLight_axisv0(klight), AreaLight_axisv1(klight) , AreaLight_axisv2(klight));
    float3 Ng = make_float3(AreaLight_dir0(klight), AreaLight_dir1(klight), AreaLight_dir2(klight));

    /* one sided */
    if (dot(D, Ng) >= 0.0f) return false;

    float3 light_P = make_float3(klight.co[0], klight.co[1], klight.co[2]);

    if (!ray_quad_intersect(P, D, 0.0f, t, light_P, axisu, axisv, Ng, (ls.P), (ls.t), (ls.u), (ls.v), is_round))  return false;

    ls.D = D;
    ls.Ng = Ng;
    if (is_round) {
       ls.pdf = invarea * lamp_light_pdf(Ng, -D, ls.t);
    }
    else {
      ls.pdf = rect_light_sample(P, (light_P), axisu, axisv, 0, 0, false);

    }
    ls.eval_fac = 0.25f * invarea;
  }
  else  return false;

  ls.pdf *= kernel_data.integrator.pdf_lights;

  return true; 

}


bool shader_constant_emission_eval(int shader, inout float3 eval)
{
  int shader_index = int(shader & SHADER_MASK);
  int shader_flag = kernel_tex_fetch(_shaders, shader_index).flags;

//#ifdef ENABLE_PROFI
//PROFI_LI_SD_FLAG(shader_flag, float(shader_flag & SD_HAS_CONSTANT_EMISSION))
//#endif

  if (bool(shader_flag & SD_HAS_CONSTANT_EMISSION) ){
    eval = make_float3(kernel_tex_fetch(_shaders, shader_index).constant_emission[0],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[1],
                        kernel_tex_fetch(_shaders, shader_index).constant_emission[2]);

    return true;
  }

  return false;
}

/* Surface Evaluation */
#define  lcg_state_init_addrspace(state_rng,scramble) lcg_init( uint(state_rng * scramble));



ccl_device void shader_eval_surface(
                                    int path_flag)
{
  /* If path is being terminated, we are tracing a shadow ray or evaluating
   * emission, then we don't need to store closures. The emission and shadow
   * shader data also do not have a closure array to save GPU memory. */
  
  int max_closures;
  if (bool(path_flag & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION))) {
    max_closures = 0;
  }
  else {
    max_closures = kernel_data.integrator.max_closures;
  }
  plymo.sd.num_closure = int(path_flag);
  plymo.sd.num_closure_left = max_closures;


#ifdef ENABLE_PROFI
plymo.sd.alloc_offset = PROFI_IDX;
#endif
   
  // plymo.sd.num_closure =0;
  executeCallableNV(4u,1);

  ///svm_eval_nodes( SHADER_TYPE_SURFACE, path_flag);
  
  if (bool(plymo.sd.flag & SD_BSDF_NEEDS_LCG)) {
    plymo.sd.lcg_state = lcg_state_init_addrspace(pay.state.rng_hash, 0xb4bc3953);
  }

}



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
  plymo.sd.P  = P;
  plymo.sd.N  = Ng;
  plymo.sd.Ng = Ng;
  plymo.sd.I  = I;
  plymo.sd.shader = shader;
  if (prim != PRIM_NONE)
    plymo.sd.type = int(PRIMITIVE_TRIANGLE);

  else if (lamp != LAMP_NONE)
    plymo.sd.type = int( PRIMITIVE_LAMP);
  else
    plymo.sd.type = int( PRIMITIVE_NONE);


  /* primitive */
  plymo.sd.object = object;
  plymo.sd.lamp   = LAMP_NONE;
  /* currently no access to bvh prim index for strand plymo.sd.prim*/
  plymo.sd.prim = prim;
  plymo.sd.u = u;
  plymo.sd.v = v;
  plymo.sd.time = time;
  plymo.sd.ray_length = t;

  plymo.sd.flag = kernel_tex_fetch(_shaders, (plymo.sd.shader & SHADER_MASK)).flags;
  plymo.sd.object_flag = 0;
  if (plymo.sd.object != OBJECT_NONE) {
    plymo.sd.object_flag |= int(kernel_tex_fetch(_object_flag, plymo.sd.object));


#ifdef _OBJECT_MOTION_
    shader_setup_object_transforms(kg, sd, time);
  }
  else if (lamp != LAMP_NONE) {
    plymo.sd.ob_tfm = lamp_fetch_transform(kg, lamp, false);
    plymo.sd.ob_itfm = lamp_fetch_transform(kg, lamp, true);
    plymo.sd.lamp = lamp;
#else
  }
  else if (lamp != LAMP_NONE) {
    plymo.sd.lamp = lamp;
#endif
  }

  /* transform into world space */
  if (object_space) {
    object_position_transform_auto(plymo.sd.P);
    object_normal_transform_auto(plymo.sd.Ng);
    plymo.sd.N = plymo.sd.Ng;
    object_dir_transform_auto(plymo.sd.I);

  }

  if (bool(plymo.sd.type & PRIMITIVE_TRIANGLE)) {
    /* smooth normal */
    if (bool(plymo.sd.shader & SHADER_SMOOTH_NORMAL)) {


      plymo.sd.N = triangle_smooth_normal(Ng, plymo.sd.prim, plymo.sd.u, plymo.sd.v);

      if (!(bool(plymo.sd.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {
        object_normal_transform_auto(plymo.sd.N);
      }
    }

    /* dPdu/dPdv */
#ifdef _DPDU_
    triangle_dPdudv(plymo.sd.prim, (plymo.sd.dPdu), (plymo.sd.dPdv));
    if (!(bool(plymo.sd.object_flag & SD_OBJECT_TRANSFORM_APPLIED))) {
      object_dir_transform_auto(plymo.sd.dPdu);
      object_dir_transform_auto(plymo.sd.dPdv);
    }
#endif
  }
  else {
#ifdef _DPDU_
    plymo.sd.dPdu = make_float3(0.0f, 0.0f, 0.0f);
    plymo.sd.dPdv = make_float3(0.0f, 0.0f, 0.0f);
#endif
  }

  /* backfacing test */
  if (plymo.sd.prim != PRIM_NONE) {
    bool backfacing = (dot(plymo.sd.Ng, plymo.sd.I) < 0.0f);

    if (bool(backfacing)) {

      plymo.sd.flag |= int(SD_BACKFACING);

      plymo.sd.Ng = -plymo.sd.Ng;
      plymo.sd.N = -plymo.sd.N;
#ifdef _DPDU_
      plymo.sd.dPdu = -plymo.sd.dPdu;
      plymo.sd.dPdv = -plymo.sd.dPdv;
#endif
    }
  }

#ifdef _RAY_DIFFERENTIALS_
  /* no ray differentials here yet */
   differential3_zero(plymo.sd.dP);
   differential3_zero(plymo.sd.dI);
   differential_zero(plymo.sd.du);
   differential_zero(plymo.sd.dv);
#endif

  PROFILING_SHADER(plymo.sd.shader);
  PROFILING_OBJECT(plymo.sd.object);
}

//#include "kernel/kernel_path_state.h.glsl"
ccl_device_inline void path_state_modify_bounce(bool increase)
{
  /* Modify bounce temporarily for shader eval */
  if (increase)
    pay.state.bounce += 1;
  else
    pay.state.bounce -= 1;
}
//#include "kernel/kernel_path_state.h.glsl"



/* Emission */

ccl_device float3 shader_emissive_eval()
{
  if (bool(plymo.sd.flag & SD_EMISSION)) {

    return emissive_simple_eval(plymo.sd.Ng, plymo.sd.I) * plymo.sd.closure_emission_background;
  }
  else {
    return make_float3(0.0f, 0.0f, 0.0f);
  }
}


/* Direction Emission emission sd */
ccl_device_noinline_cpu float3 direct_emissive_eval(
                                                    inout LightSample ls,
                                                    float3 I,
                                                    differential3 dI,
                                                    float t,
                                                    float time)
{
  /* setup shading at emitter */
  float3 eval = make_float3(0.0f, 0.0f, 0.0f);
  if (shader_constant_emission_eval(ls.shader, eval)) {
    if ((ls.prim != PRIM_NONE) && dot(ls.Ng, I) < 0.0f) {
      ls.Ng = -ls.Ng;
    }


  }
  else
   {
    /* Setup shader data and call shader_eval_surface once, better
     * for GPU coherence and compile times. */
#ifdef _BACKGROUND_MIS_
    if (ls->type == LIGHT_BACKGROUND) {
      Ray ray;
      ray.D = ls->D;
      ray.P = ls->P;
      ray.t = 1.0f;
      ray.time = time;
      ray.dP = differential3_zero();
      ray.dD = dI;

      shader_setup_from_background(kg, emission_sd, &ray);
    }
    else
#endif
    {
      shader_setup_from_sample(
                               ls.P,
                               ls.Ng,
                               I,
                               ls.shader,
                               ls.object,
                               ls.prim,
                               ls.u,
                               ls.v,
                               t,
                               time,
                               false,
                               ls.lamp);

      ls.Ng =  plymo.sd.Ng;
    }

    /* No proper path flag, we're evaluating this for all closures. that's
     * weak but we'd have to do multiple evaluations otherwise. */
    path_state_modify_bounce(true);
    shader_eval_surface( int(PATH_RAY_EMISSION) );
    path_state_modify_bounce(false);

    /* Evaluate closures. */
#ifdef _BACKGROUND_MIS_
    if (ls->type == LIGHT_BACKGROUND) {
      eval = shader_background_eval(emission_sd);
    }
    else
#endif
    {
      eval = shader_emissive_eval();
    }
  }

  eval *= ls.eval_fac;

  if (ls.lamp != LAMP_NONE) {
    const ccl_global KernelLight klight = kernel_tex_fetch(_lights, ls.lamp);
    eval *= make_float3(klight.strength[0], klight.strength[1], klight.strength[2]);
  }




  return eval;

}


void indirect_lamp_emission()
{
  int state_flag = pay.state.flag;
  for (int lamp = 0; lamp < kernel_data.integrator.num_all_lights; lamp++) {

    LightSample ls;

    if(!lamp_light_eval(ls,lamp,pay.ray.P,pay.ray.D,pay.ray.t))continue; 



#ifdef _PASSES_
    /* use visibility flag to skip lights */
    if (bool(ls.shader & SHADER_EXCLUDE_ANY)) {
      if (( bool(ls.shader & SHADER_EXCLUDE_DIFFUSE) && bool( state_flag & PATH_RAY_DIFFUSE)) ||
          ( bool(ls.shader & SHADER_EXCLUDE_GLOSSY) &&
           (( state_flag & (PATH_RAY_GLOSSY | PATH_RAY_REFLECT)) ==
            (PATH_RAY_GLOSSY | PATH_RAY_REFLECT))) ||
          (bool(ls.shader & SHADER_EXCLUDE_TRANSMIT) && bool( state_flag& PATH_RAY_TRANSMIT)) ||
          (bool(ls.shader & SHADER_EXCLUDE_SCATTER) && bool( state_flag & PATH_RAY_VOLUME_SCATTER)))
        continue;
    }
#endif

    float3 lamp_L = direct_emissive_eval(ls,-pay.ray.D, pay.ray.dD, ls.t, pay.ray.time);

#ifdef _VOLUME_
    if (state.volume_stack[0].shader != SHADER_NONE) {
      /* shadow attenuation */
      Ray volume_ray = *ray;
      volume_ray.t = ls.t;
      float3 volume_tp = make_float3(1.0f, 1.0f, 1.0f);
      kernel_volume_shadow(kg, emission_sd, state, &volume_ray, &volume_tp);
      lamp_L *= volume_tp;
    }
#endif

    if (!bool(state_flag & PATH_RAY_MIS_SKIP)) {
      /* multiple importance sampling, get regular light pdf,
       * and compute weight with respect to BSDF pdf */
      float mis_weight = power_heuristic(pay.state.ray_pdf, ls.pdf);
      lamp_L *= mis_weight;
    }

    path_radiance_accum_emission( pay.state.flag, pay.state.bounce, pay.L.throughput, lamp_L);
  }
}





ccl_device_inline float3 ray_offset(float3 P, float3 Ng)
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

bool direct_emission(               inout LightSample ls,
                                    inout bool is_lamp,
                                    float rand_terminate)
{
  if (ls.pdf == 0.0f)
    return false;

  /* todo: implement */
  differential3 dD;
  differential3_zero(dD);

  /* evaluate closure */
  float3 light_eval = direct_emissive_eval(ls,  -ls.D, dD, ls.t, pay.sd.time);



  if (is_zero(light_eval))
    return false;



    /* evaluate BSDF at shading point */

#ifdef _VOLUME_
  if (sd->prim != PRIM_NONE)
    shader_bsdf_eval(kg, sd, ls->D, eval, ls->pdf, ls->shader & SHADER_USE_MIS);
  else {
    float bsdf_pdf;
    shader_volume_phase_eval(kg, sd, ls->D, eval, &bsdf_pdf);
    if (ls->shader & SHADER_USE_MIS) {
      /* Multiple importance sampling. */
      float mis_weight = power_heuristic(ls->pdf, bsdf_pdf);
      light_eval *= mis_weight;
    }
  }
#else
        
        set_prg3_tiny_sd( ls.D, ls.pdf, uint(PROFI_IDX),pay.use_light_pass, int(ls.shader & SHADER_USE_MIS),BSDF_CALL_TYPE_EVAL ,123)
        
        //plymo.sd.lamp     = int(4294967295);

        executeCallableNV(3u,1);

        pay.sd.lcg_state  = floatBitsToUint(plymo.sd.time);

/*
if(PROFI_IDX == 0){

      float prec = 1000.f;
      int v = int(pay.sd.lcg_state & uint(0xFFFF));
      atomicAdd(counter[PROFI_ATOMIC - 32],int(v));
}
*/
     


        ///shader_bsdf_eval(sd, ls.D, eval, ls.pdf, bool(ls.shader & SHADER_USE_MIS) );
#endif

  PLYMO_bsdf_eval_mul3(light_eval / ls.pdf);

#ifdef _PASSES_
  /* use visibility flag to skip lights */
  if (bool(ls.shader & SHADER_EXCLUDE_ANY)) {
    if(bool (ls.shader & SHADER_EXCLUDE_DIFFUSE))
      PLYMO_EVAL_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    if (bool(ls.shader & SHADER_EXCLUDE_GLOSSY))
      PLYMO_EVAL_glossy = make_float3(0.0f, 0.0f, 0.0f);
    if (bool(ls.shader & SHADER_EXCLUDE_TRANSMIT))
      PLYMO_EVAL_set_zero_transmission
      /*
    if(bool (ls.shader & SHADER_EXCLUDE_SCATTER))
      plymo.eval.volume = make_float3(0.0f, 0.0f, 0.0f);
      */
  }
#endif


  if (PLYMO_bsdf_eval_is_zero())
    return false;
  




  if (kernel_data.integrator.light_inv_rr_threshold > 0.0f
#ifdef _SHADOW_TRICKS_
      && (pay.state.flag & PATH_RAY_SHADOW_CATCHER) == 0
#endif
  ) {
    float probability = max3(fabs(PLYMO_bsdf_eval_sum())) *
                        kernel_data.integrator.light_inv_rr_threshold;
    if (probability < 1.0f) {
      if (rand_terminate >= probability) {
        return false;
      }
      PLYMO_bsdf_eval_mul(1.0f / probability);
    }
  }


  if (bool(ls.shader & SHADER_CAST_SHADOW)){
    /* setup ray */
    bool transmit = (dot(pay.sd.Ng, ls.D) < 0.0f);
    pay.ray.P = ray_offset(pay.sd.P, (transmit) ? -pay.sd.Ng : pay.sd.Ng);
      



    if (ls.t == FLT_MAX) {
      /* distant light */
      pay.ray.D = ls.D;
      pay.ray.t = ls.t;
    }
    else {
      /* other lights, avoid self-intersection */
      pay.ray.D = ray_offset(ls.P, ls.Ng) - pay.ray.P;
      pay.ray.D = normalize_len( pay.ray.D, pay.ray.t);
    }

    //pay.ray.dP = plymo.sd.dP;
    differential3_zero(pay.ray.dD);
  }
  else {
    /* signal to not cast shadow ray */
    pay.ray.t = 0.0f;
  }

  /* return if it's a lamp for shadow pass */
  is_lamp = (ls.prim == PRIM_NONE && ls.type != LIGHT_BACKGROUND);


  set_ply_Eval




  return true;
}




ccl_device_inline void path_radiance_accum_total_light(
                                                       int state_flag,
                                                       vec4 throughput,
                                                       vec4 sum_no_mis)
{
#ifdef _SHADOW_TRICKS_
  if (bool(state_flag & PATH_RAY_STORE_SHADOW_INFO)) {
    pay.L.path_total +=  sum_no_mis;//throughput * sum_no_mis;
  }
#else
  uint(state_flag);
#endif



}




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

   

            if (light_sample( param.xy,pay.sd.time, pay.sd.P, pay.state.bounce, ls)) {


            /* The sampling probability returned by lamp_light_sample assumes that all lights were
            * sampled. However, this code only samples lamps, so if the scene also had mesh lights,
            * the real probability is twice as high. */
                  if (bool(param.w)) {
                      ls.pdf *= 2.0f;
                  }

                 ply_L2Eval_light_hasemission = int(direct_emission(ls, is_lamp, param.z));
                 

            }
      }





#endif
}






void main(){

#ifdef ENABLE_PROFI
PROFI_IDX =  int(ply_L2Eval_profi_idx);
ply_L2Eval_profi_idx  = 0.f;
#endif

if(pay.type ==  SURFACE_CALL_TYPE_indirect_lamp){

   indirect_lamp_emission();

}else if(pay.type ==  SURFACE_CALL_TYPE_connect_light){

   kernel_branched_path_surface_connect_light( );
  
}


};
