#version 460
#extension GL_NV_ray_tracing : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_debug_printf : enable
#pragma use_vulkan_memory_model

#define  FLOAT3_AS_VEC3
#include "kernel_compat_vulkan.h.glsl"
#define  ENABLE_PROFI 
#include "kernel/_kernel_types.h.glsl"
#define  SET_AS 0
#define SET_KERNEL 2
#define SET_KERNEL_PROF SET_KERNEL
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"
#define  LHIT_CALLEE
#define  MISS_THROUGH_CALLEE
#include "kernel/payload.glsl"
#define RPL_TYPE_LISECT 0

struct sd_tiny{
  float3 P;
  float3 Ng;
  int type;
  int object;
  float time;
#ifdef _RAY_DIFFERENTIALS_
  differential3 dP;
  differential3 dI;
#endif
  int num_closure;
  int alloc_offset;
};

sd_tiny GSD;
#define getSC() SC(GSD.alloc_offset)
#define _getSC(scN) SC(scN)

#undef _OBJECT_MOTION2_
#define ObjectTransform uint
#define  OBJECT_TRANSFORM  0
#define  OBJECT_INVERSE_TRANSFORM 1
//modified ==> ObjectTransform




//modify => enum ObjectVectorTransform 
#define ObjectVectorTransform uint
#define  OBJECT_PASS_MOTION_PRE  0
#define  OBJECT_PASS_MOTION_POST 1
//modified ==> ObjectVectorTransform
/* Object to world space transformation */
ccl_device_inline Transform object_fetch_transform(
                                                   int object,
                                                   ObjectTransform type
)
{
  if (type == OBJECT_INVERSE_TRANSFORM) {
    return kernel_tex_fetch(_objects, object).itfm;
  }
  else {
    return kernel_tex_fetch(_objects, object).tfm;
  }
}


ccl_device_inline void object_normal_transform(inout float3 N)
{
  Transform tfm = object_fetch_transform(GSD.object, OBJECT_INVERSE_TRANSFORM);
  N = normalize(transform_direction_transposed(tfm, N));
}
ccl_device void to_unit_disk(inout float x, inout float y)
{
  float phi = M_2PI_F * (x);
  float r = sqrtf(y);

  x = r * cosf(phi);
  y = r * sinf(phi);
}



/* sample direction with cosine weighted distributed in hemisphere */
ccl_device_inline void sample_cos_hemisphere(
    const float3 N,float randu,float randv, inout float3 omega_in, inout float pdf)
{
  to_unit_disk(randu, randv);
  float costheta = sqrtf(max(1.0f - randu * randu - randv * randv, 0.0f));
  float3 T, B;
  make_orthonormals(N, T, B);
  omega_in = randu * T + randv * B + costheta * N;
  pdf = costheta * M_1_PI_F;
}

PathState state;
#define GSTATE state
#include "kernel/kernel_random.h.glsl"
#include "kernel/bvh/bvh_utils.h.glsl"
#include "kernel/geom/geom_triangle_intersect.h.glsl"
#define differential3_zero(agd) agd.dx = make_float3(0.0f, 0.0f, 0.0f); agd.dy = make_float3(0.0f, 0.0f, 0.0f);

struct LocalIntersection_tiny { 
  Ray    ray;
  float3 weight[LOCAL_MAX_HITS];
};

LocalIntersection_tiny ss_isect;

#define PLYMO_IS_WEIGHT(hit,val) {\
  int idx      = linfo.offset + BSSRDF_MAX_HITS + hit;\
  IS(idx).t    = val.x;\
  IS(idx).u    = val.y;\
  IS(idx).v    = val.z;\
}
#define ReturnRayPD {\
        linfo.offset    = floatBitsToInt(ss_isect.ray.P.x);\
        linfo.max_hits  = floatBitsToInt(ss_isect.ray.P.y);\
        linfo.lcg_state = floatBitsToUint(ss_isect.ray.P.z);\
        linfo.num_hits  = floatBitsToInt(ss_isect.ray.D.x);\
        linfo.local_object= floatBitsToInt(ss_isect.ray.D.y);\
        linfo.type       = floatBitsToInt(ss_isect.ray.D.z);\
}
#define ReturnNumHit(nums,offset) {\
    int idx         = offset + BSSRDF_MAX_HITS;\
    IS(idx).prim    = nums;\
}

#define  LISECT_GET_NG(Ng,ISid) {\
  uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, IS(ISid).prim) + VertexOffset(IS(ISid).type);\
  float3 tri_a = as_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.x]);\
  float3 tri_b = as_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.y]);\
  float3 tri_c = as_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.z]);\
  Ng = normalize(cross(tri_b - tri_a, tri_c - tri_a));\
}
#define SSS_CALLEE
#include "kernel/kernel_subsurface.h.glsl"

void main(){

if(linfo.max_hits<0){
  #ifdef  WITH_STAT_ALL
  setDumpPixel();
  rec_num = linfo.num_hits;
  #endif
    float bssrdf_u,bssrdf_v;
    int scN;
    PLYMO_IS_ARGLHIT(GSD);
    uint lcg_state   = linfo.lcg_state;
    int offset = linfo.offset;
    GSD.alloc_offset = offset + GSD.num_closure - 1;

    int num_hit = subsurface_scatter_multi_intersect(scN,lcg_state,bssrdf_u,bssrdf_v,false);
    ReturnNumHit(num_hit,offset)
    if(num_hit>0){ReturnRayPD;}

}

}

