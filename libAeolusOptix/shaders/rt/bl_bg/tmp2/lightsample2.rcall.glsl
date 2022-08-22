#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#define PUSH_POOL_SC
#define PUSH_KERNEL_TEX
#define SET_KERNEL 2

#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"
#include "kernel/kernel_globals.h.glsl"

#include "kernel/kernel_light_common.h.glsl"
#include "kernel/kernel_light_background.h.glsl"



//modify => enum ObjectTransform 
#define ObjectTransform uint
#define  OBJECT_TRANSFORM  0
#define  OBJECT_INVERSE_TRANSFORM  1
//modified ==> ObjectTransform




//modify => enum ObjectVectorTransform 
#define ObjectVectorTransform uint
#define  OBJECT_PASS_MOTION_PRE  0
#define  OBJECT_PASS_MOTION_POST  1
//modified ==> ObjectVectorTransform



struct LightSample
{
    vec4 P;           
    vec4 Ng;          
    vec4 D;           
    float t;          
    float u;          
    float v;          
    float pdf;        
    float eval_fac;   
    int object;       
    int prim;         
    int shader;       
    int lamp;         
    uint type;        
};
#define ls_P emi.pad[0]
#define ls_Ng emi.pad[4]
#define ls_D emi.pad[8]
#define ls_t emi.pad[12]
#define ls_u emi.pad[13]
#define ls_v emi.pad[14]
#define ls_pdf emi.pad[15]
#define ls_eval_fac emi.pad[16]

#define ls_object floatBitsToInt(emi.pad[17])
#define ls_prim   floatBitsToInt(emi.pad[18])
#define ls_shader floatBitsToInt(emi.pad[19])
#define ls_lamp   floatBitsToInt(emi.pad[20])
#define ls_type   floatBitsToUint(emi.pad[21])

#define set_ls_object(val) emi.pad[17] =   intBitsToFloat(int(val))
#define set_ls_prim(val)   emi.pad[18] =   intBitsToFloat(int(val))
#define set_ls_shader(val) emi.pad[19] =   intBitsToFloat(int(val))
#define set_ls_lamp(val) emi.pad[20] =   intBitsToFloat(int(val))
#define set_ls_type(val) emi.pad[21] =   uintBitsToFloat(uint(val))


#define sizeof_LightSample 4*( 4*3 + 10)

struct args_PathState
{
    int flag;
    uint rng_hash;
    int rng_offset;
    int sample_rsv;
    int num_samples;
    float branch_factor;
    int bounce;
};
#define sizeof_args_PathState   4*(7)


struct args_ShaderData
{
vec4 P;
vec4 N;
vec4 Ng;
vec4 I;
int flag;
int type;
int object;
float time;
differential3 dP;
uint lcg_state;
int num_closure;

};
#define sizeof_args_ShaderData   4*( 4*4 + 6 + 4*2)


struct hitPayload0
{
ShaderDataTinyStorage esd;
int    lamp;        
float light_u;
float light_v;          // 3
args_ShaderData sd;     // 33 = 30 + 3
args_PathState  state;  // 40 = 7 + 33 
LightSample ls;
};









layout(location = 0) callableDataInNV hitPayload0 emi;




ccl_device int light_distribution_sample( )
{
  /* This is basically std::upper_bound as used by pbrt, to find a point light or
   * triangle to emit from, proportional to area. a good improvement would be to
   * also sample_rsv proportional to power, though it's not so well defined with
   * arbitrary shaders. */
  int first =  0;
  int _len   =  kernel_data.integrator.num_distribution + 1;
  float r   =   emi.light_u;

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
  emi.light_u = (r - distr_min) / (distr_max - distr_min);

  return index;
}

/* Information about mesh for motion blurred triangles and curves */

ccl_device_inline void object_motion_info(int object, inout int numsteps, inout int numverts, inout int numkeys)
{
   if (!isNULL(numkeys))numkeys = kernel_tex_fetch(_objects, object).numkeys;
   if (!isNULL(numsteps))numsteps = kernel_tex_fetch(_objects, object).numsteps;
   if (!isNULL(numverts))numverts = kernel_tex_fetch(_objects, object).numverts;

}


#define  object_attribute_map_offset(object) uint(kernel_tex_fetch(_objects, object).attribute_map_offset)
#define  light_select_reached_max_bounces(index,bounce) (bounce > kernel_tex_fetch(_lights, index).max_bounces)
#define  light_select_num_samples(index) kernel_tex_fetch(_lights, index).samples;

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

/* Object to world space transformation */
Transform object_fetch_transform(int object,ObjectTransform type)
{
  if (type == OBJECT_INVERSE_TRANSFORM) {
    return kernel_tex_fetch(_objects, object).itfm;
  }
  else {
    return kernel_tex_fetch(_objects, object).tfm;
  }
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

void triangle_light_sample(int prim, int object)
{
  /* A naive heuristic to decide between costly solid angle sampling
   * and simple area sampling, comparing the distance to the triangle plane
   * to the length of the edges of the triangle. */

  float3 V[3];
  bool has_motion = triangle_world_space_vertices(object, prim, emi.sd.time , V);
  const float3 e0 = V[1] - V[0];
  const float3 e1 = V[2] - V[0];
  const float3 e2 = V[2] - V[1];
  const float longest_edge_squared = max(len_squared(e0), max(len_squared(e1), len_squared(e2)));
  const float3 N0 = cross(e0, e1);
  float Nl = 0.0f;
  emi.ls.Ng = safe_normalize_len(N0, (Nl));
  float area = 0.5f * Nl;
  /* flip normal if necessary */
  const int object_flag = int(kernel_tex_fetch(_object_flag, object));

  if (bool(object_flag & SD_OBJECT_NEGATIVE_SCALE_APPLIED)) {
    emi.ls.Ng = -emi.ls.Ng;
  }

  emi.ls.eval_fac = 1.0f;
  emi.ls.shader = int(kernel_tex_fetch(_tri_shader, prim));
  emi.ls.object = object;
  emi.ls.prim = prim;
  emi.ls.lamp = LAMP_NONE;
  emi.ls.shader |= int(SHADER_USE_MIS);
  emi.ls.type = LIGHT_TRIANGLE;

  float3 P = emi.sd.P;
  float distance_to_plane = fabsf(dot(N0, V[0] - P) / dot(N0, N0));

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
    const float phi = emi.light_u * solid_angle - alpha;
    float s, t;
    fast_sincosf(phi, (s), (t));


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
    const float z = 1.0f - emi.light_v * (1.0f - dot(C_, B));
    emi.ls.D = z * B + safe_sqrtf(1.0f - z * z) * safe_normalize(C_ - dot(C_, B) * B);

    /* calculate intersection with the planar triangle */
    if (!ray_triangle_intersect(P,
                                emi.ls.D,
                                FLT_MAX,
                                V[0],
                                V[1],
                                V[2],
                                (emi.ls.u),
                                (emi.ls.v),
                                (emi.ls.t))) {

      emi.ls.pdf = 0.0f;
      return;
    }

    emi.ls.P = P + emi.ls.D * emi.ls.t;

    /* pdf_triangles is calculated over triangle area, but we're sampling over solid angle */
    if (UNLIKELY(solid_angle == 0.0f)) {
      emi.ls.pdf = 0.0f;
      return;
    }
    else {
      if (has_motion) {
        /* get the center frame vertices, this is what the PDF was calculated from */
        triangle_world_space_vertices(object, prim, -1.0f, V);
        area = triangle_area(V[0], V[1], V[2]);
      }
      const float pdf = area * kernel_data.integrator.pdf_triangles;
      emi.ls.pdf = pdf / solid_angle;
    }
  }
  else {
    /* compute random point in triangle. From Eric Heitz's "A Low-Distortion Map Between Triangle
     * and Square" */
    float u = emi.light_u;
    float v = emi.light_v;
    if (v > u) {
      u *= 0.5f;
      v -= u;
    }
    else {
      v *= 0.5f;
      u -= v;
    }

    const float t = 1.0f - u - v;
    emi.ls.P = u * V[0] + v * V[1] + t * V[2];
    /* compute incoming direction, distance and pdf */
    emi.ls.D = normalize_len(emi.ls.P - P, (emi.ls.t));

    emi.ls.pdf = triangle_light_pdf_area(emi.ls.Ng, -emi.ls.D, emi.ls.t);
    if (has_motion && area != 0.0f) {
      /* scale the PDF.
       * area = the area the sample_rsv was taken from
       * area_pre = the are from which pdf_triangles was calculated from */
      triangle_world_space_vertices(object, prim, -1.0f, V);
      const float area_pre = triangle_area(V[0], V[1], V[2]);
      emi.ls.pdf = emi.ls.pdf * area_pre / area;
    }
    emi.ls.u = u;
    emi.ls.v = v;
  }

}


#define RETURN_TF(b) {emi.lamp = (b)?1:0;return;}


/* Regular Light */

ccl_device_inline bool lamp_light_sample(int lamp)
{
  float3 P = emi.sd.P;
  const ccl_global KernelLight klight =  kernel_tex_fetch(_lights, lamp);
  LightType type = LightType(klight.type);
  
  emi.ls.type = type;
  emi.ls.shader = klight.shader_id;
  emi.ls.object = PRIM_NONE;
  emi.ls.prim = PRIM_NONE;
  emi.ls.lamp = lamp;
  emi.ls.u = emi.light_u;
  emi.ls.v = emi.light_v;

  if (type == LIGHT_DISTANT) {
    /* distant light */
    float3 lightD = make_float3(klight.co[0], klight.co[1], klight.co[2]);
    float3 D = lightD;
    float radius = DistantLight_radius(klight);
    float invarea = DistantLight_invarea(klight) ;

    if (radius > 0.0f)
      D = distant_light_sample(D, radius,  emi.light_u,  emi.light_v);

    emi.ls.P = D;
    emi.ls.Ng = D;
    emi.ls.D = -D;
    emi.ls.t = FLT_MAX;

    float costheta = dot(lightD, D);
    emi.ls.pdf = invarea / (costheta * costheta * costheta);
    emi.ls.eval_fac = emi.ls.pdf;
  }
#ifdef _BACKGROUND_MIS_
  else if (type == LIGHT_BACKGROUND) {
    /* infinite area light (e.g. light dome or env light) */
    float3 D = -background_light_sample(P, randu, randv, (emi.ls.pdf));

    emi.ls.P = D;
    emi.ls.Ng = D;
    emi.ls.D = -D;
    emi.ls.t = FLT_MAX;
    emi.ls.eval_fac = 1.0f;

  }
#endif
  else {
    emi.ls.P = make_float3(klight.co[0], klight.co[1], klight.co[2]);

    if (type == LIGHT_POINT || type == LIGHT_SPOT) {

      float radius = SpotLight_radius(klight);
      if (radius > 0.0f)emi.ls.P += sphere_light_sample(P, emi.ls.P, radius,  emi.light_u,  emi.light_v);
      emi.ls.D = normalize_len(emi.ls.P - P, (emi.ls.t));
      emi.ls.Ng = -emi.ls.D;
      float invarea = SpotLight_invarea(klight);
      emi.ls.eval_fac = (0.25f * M_1_PI_F) * invarea;
      emi.ls.pdf = invarea;

      if (type == LIGHT_SPOT) {
        /* spot light attenuation */
        float3 dir = make_float3(SpotLight_dir0(klight), SpotLight_dir1(klight), SpotLight_dir2(klight));
        emi.ls.eval_fac *= spot_light_attenuation(dir, SpotLight_spot_angle(klight), SpotLight_spot_smooth(klight), emi.ls.Ng);
        if (emi.ls.eval_fac == 0.0f) {
          return false;
        }
      }
      
      float2 uv = map_to_sphere(emi.ls.Ng);
      emi.ls.u = uv.x;
      emi.ls.v = uv.y;
      emi.ls.pdf *= lamp_light_pdf(emi.ls.Ng, -emi.ls.D, emi.ls.t);
    }
    else {
      /* area light */
      float3 axisu = make_float3(AreaLight_axisu0(klight), AreaLight_axisu1(klight), AreaLight_axisu2(klight));
      float3 axisv = make_float3(AreaLight_axisv0(klight) , AreaLight_axisv1(klight) , AreaLight_axisv2(klight));
      float3 D = make_float3(AreaLight_dir0(klight), AreaLight_dir1(klight), AreaLight_dir2(klight));
      float invarea = fabsf(AreaLight_invarea(klight));
      bool is_round = (AreaLight_invarea(klight) < 0.0f);

      if (dot(emi.ls.P - P, D) > 0.0f) {
        return false;
      }

      float3 inplane;

      if (is_round) {

        inplane  = ellipse_sample(axisu * 0.5f, axisv * 0.5f,  emi.light_u,  emi.light_v);
        emi.ls.P     += inplane;
        emi.ls.pdf   = invarea;

      }else {

        inplane = emi.ls.P;
        emi.ls.pdf  = rect_light_sample(P, (emi.ls.P), axisu, axisv,  emi.light_u,  emi.light_v, true);
        inplane = emi.ls.P - inplane;

      }

      emi.ls.u = dot(inplane, axisu) * (1.0f / dot(axisu, axisu)) + 0.5f;
      emi.ls.v = dot(inplane, axisv) * (1.0f / dot(axisv, axisv)) + 0.5f;

      emi.ls.Ng = D;
      emi.ls.D = normalize_len(emi.ls.P - P, (emi.ls.t));


      emi.ls.eval_fac = 0.25f * invarea;
      if (is_round) {
        emi.ls.pdf *= lamp_light_pdf(D, -emi.ls.D, emi.ls.t);
      }
    }
  }

  emi.ls.pdf *= kernel_data.integrator.pdf_lights;

  return (emi.ls.pdf > 0.0f);
}


bool light_sample()
{
  if (emi.lamp < 0) {
    /* sample_rsv index */
    int index = light_distribution_sample();


    /* fetch light data */
    const  KernelLightDistribution kdistribution = kernel_tex_fetch(_light_distribution, index);
    int prim = kdistribution.prim;

    if (prim >= 0) {
      int object = LightDistribution_mesh_light_object_id(kdistribution);
      int shader_flag = LightDistribution_mesh_light_shader_flag(kdistribution);

      triangle_light_sample(prim, object);
      emi.ls.shader |= shader_flag;
      return (emi.ls.pdf > 0.0f);
    }

    emi.lamp = -prim - 1;
  }

  if (UNLIKELY(light_select_reached_max_bounces(emi.lamp, emi.state.bounce))) {
    return false;
  }

  return lamp_light_sample(emi.lamp);

}

void lamp_light_eval( int lamp, float3 P, float3 D, float t)
{
  const ccl_global KernelLight klight = kernel_tex_fetch(_lights, lamp);
  LightType type = LightType(klight.type);
  emi.ls.type = type;
  emi.ls.shader = klight.shader_id;
  emi.ls.object = PRIM_NONE;
  emi.ls.prim = PRIM_NONE;
  emi.ls.lamp = lamp;
  /* todo: missing texture coordinates */
  emi.ls.u = 0.0f;
  emi.ls.v = 0.0f;

  if (!bool(emi.ls.shader & SHADER_USE_MIS))
    RETURN_TF(false);

  if (type == LIGHT_DISTANT) {
    /* distant light */
    float radius = DistantLight_radius(klight);
    if (radius == 0.0f)
      RETURN_TF(false);
    if (t != FLT_MAX)
      RETURN_TF(false);

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
      RETURN_TF(false);

    emi.ls.P = -D;
    emi.ls.Ng = -D;
    emi.ls.D = D;
    emi.ls.t = FLT_MAX;

    /* compute pdf */
    float invarea = DistantLight_invarea(klight) 
;
    emi.ls.pdf = invarea / (costheta * costheta * costheta);
    emi.ls.eval_fac = emi.ls.pdf;
  }
  else if (type == LIGHT_POINT || type == LIGHT_SPOT) {
    float3 lightP = make_float3(klight.co[0], klight.co[1], klight.co[2]);

    float radius = SpotLight_radius(klight)
;

    /* sphere light */
    if (radius == 0.0f)
      RETURN_TF(false);

    if (!ray_aligned_disk_intersect(P, D, t, lightP, radius, (emi.ls.P), (emi.ls.t))) RETURN_TF(false);
    

    emi.ls.Ng = -D;
    emi.ls.D = D;

    float invarea = SpotLight_invarea(klight);
    emi.ls.eval_fac = (0.25f * M_1_PI_F) * invarea;
    emi.ls.pdf = invarea;

    if (type == LIGHT_SPOT) {
      /* spot light attenuation */
      float3 dir = make_float3(SpotLight_dir0(klight), SpotLight_dir1(klight), SpotLight_dir2(klight));
      emi.ls.eval_fac *= spot_light_attenuation(dir, SpotLight_spot_angle(klight), SpotLight_spot_smooth(klight), emi.ls.Ng);

      if (emi.ls.eval_fac == 0.0f)
         RETURN_TF(false);
    }
    float2 uv = map_to_sphere(emi.ls.Ng);
    emi.ls.u = uv.x;
    emi.ls.v = uv.y;
    /* compute pdf */
    if (emi.ls.t != FLT_MAX)
      emi.ls.pdf *= lamp_light_pdf(emi.ls.Ng, -emi.ls.D, emi.ls.t);
  }
  else if (type == LIGHT_AREA) {
    /* area light */
    float invarea = fabsf(AreaLight_invarea(klight));
    bool is_round = (AreaLight_invarea(klight) < 0.0f);
    if (invarea == 0.0f)RETURN_TF(false);

    float3 axisu = make_float3(AreaLight_axisu0(klight), AreaLight_axisu1(klight), AreaLight_axisu2(klight));
    float3 axisv = make_float3(AreaLight_axisv0(klight), AreaLight_axisv1(klight) , AreaLight_axisv2(klight));
    float3 Ng = make_float3(AreaLight_dir0(klight), AreaLight_dir1(klight), AreaLight_dir2(klight));

    /* one sided */
    if (dot(D, Ng) >= 0.0f) RETURN_TF(false);

    float3 light_P = make_float3(klight.co[0], klight.co[1], klight.co[2]);

    if (!ray_quad_intersect(P, D, 0.0f, t, light_P, axisu, axisv, Ng, (emi.ls.P), (emi.ls.t), (emi.ls.u), (emi.ls.v), is_round))  RETURN_TF(false);

    emi.ls.D = D;
    emi.ls.Ng = Ng;
    if (is_round) {
      emi.ls.pdf = invarea * lamp_light_pdf(Ng, -D, emi.ls.t);
    }
    else {
      emi.ls.pdf = rect_light_sample(P, (light_P), axisu, axisv, 0, 0, false);

    }
    emi.ls.eval_fac = 0.25f * invarea;
  }
  else  RETURN_TF(false);

  emi.ls.pdf *= kernel_data.integrator.pdf_lights;

  RETURN_TF(true);

}


#define CALL_TYPE_lamp_light_eval 1234
void main(){
  if(emi.ls.type == CALL_TYPE_lamp_light_eval){

    lamp_light_eval(emi.lamp,emi.ls.P,emi.ls.D,emi.ls.t); 

  }else if(emi.ls.type == CALL_TYPE_light_sample){

    light_sample();

  };
};
