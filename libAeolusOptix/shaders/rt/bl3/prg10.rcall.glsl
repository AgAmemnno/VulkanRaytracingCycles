#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_GOOGLE_include_directive : enable
#extension GL_EXT_scalar_block_layout  :require
#extension GL_EXT_debug_printf : enable

#define OMIT_NULL_SC
#define ENABLE_PROFI
#include "kernel_compat_vulkan.h.glsl"
#include "kernel/_kernel_types.h.glsl"

#define SET_KERNEL_PROF 2
//#define PUSH_KERNEL_TEX
#undef LOOKUP
#include "kernel/kernel_globals.h.glsl"
#define CD_TYPE1_IN sd
#include "kernel/payload.glsl"


#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_tri_verts2_;
layout(buffer_reference) buffer _tri_vindex2_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer _objects_;
layout(buffer_reference) buffer _object_flag_;
layout(buffer_reference) buffer _tri_vnormal_;
layout(buffer_reference) buffer  _tri_shader_;
layout(buffer_reference) buffer  _shaders_;
layout(buffer_reference) buffer  _lights_;
layout(buffer_reference, std430) buffer KernelTextures
{
  _prim_tri_verts2_  _prim_tri_verts2;
  int64_t pad[3];    
  _prim_index_         _prim_index;
  _prim_object_       _prim_object;
  _objects_                 _objects;
  _object_flag_         _object_flag;
  int64_t pad1[7];
  _tri_shader_         _tri_shader;
  _tri_vnormal_        _tri_vnormal;
  _tri_vindex2_        _tri_vindex2;
  int64_t pad2[3];
  _lights_                  _lights;
   int64_t pad3[4];
  _shaders_               _shaders;
};


layout(buffer_reference, std430) readonly buffer _lights_
{
    KernelLight data[];
};

layout(buffer_reference, std430) readonly buffer _objects_
{
    KernelObject data[];
};
layout(buffer_reference, std430) readonly buffer _object_flag_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_tri_verts2_
{
    float4 data[];
};
layout(buffer_reference, std430) readonly buffer _prim_index_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_object_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _tri_shader_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _tri_vnormal_
{
    float4 data[];
};
layout(buffer_reference, std430) readonly buffer _tri_vindex2_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _shaders_
{
    KernelShader data[];
};
layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;


#define  GEOM_NO_ATTR
#include "kernel/geom/geom_object.h.glsl"
#include "kernel/geom/geom_triangle.h.glsl"
#include "kernel/kernel_differential.h.glsl"

ccl_device_inline float3 triangle_refine(in float3 P,in float3 D,float t, int object,int prim,int geometry)
{
#ifdef _INTERSECTION_REFINE_

  /// modify if (GISECT.object != OBJECT_NONE) {
  if(!OBJECT_IS_NONE(object)){
    if (UNLIKELY(t == 0.0f)) {
      return P;
    }
#  ifdef _OBJECT_MOTION2_
    Transform tfm = GSD.ob_itfm;
#  else
    Transform tfm = object_fetch_transform(GetObjectID(object), OBJECT_INVERSE_TRANSFORM);
#  endif

    P = transform_point(tfm, P);
    D = transform_direction(tfm, D * t);
    D = normalize_len(D, t);
  }
  P = P + D * t;


  const uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, prim) + VertexOffset(geometry);
  const float4 tri_a = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.x),
               tri_b = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.y),
               tri_c = kernel_tex_fetch(_prim_tri_verts2, tri_vindex.z);
  float3 edge1 = make_float3(tri_a.x - tri_c.x, tri_a.y - tri_c.y, tri_a.z - tri_c.z);
  float3 edge2 = make_float3(tri_b.x - tri_c.x, tri_b.y - tri_c.y, tri_b.z - tri_c.z);
  float3 tvec = make_float3(P.x - tri_c.x, P.y - tri_c.y, P.z - tri_c.z);
  vec3 qvec = cross(tvec.xyz, edge1.xyz);
  vec3 pvec = cross(D.xyz, edge2.xyz);
  float det = dot3(edge1.xyz, pvec.xyz);

  if (det != 0.0f) {

    float rt = dot3(edge2.xyz, qvec.xyz) / det;
    P = P + D * rt;
  }

  /// modify if (GISECT.object != OBJECT_NONE) {
  if(!OBJECT_IS_NONE(object)){
#  ifdef _OBJECT_MOTION2_
    Transform tfm = GSD.ob_tfm;
#  else
    Transform tfm = object_fetch_transform(GetObjectID(object), OBJECT_TRANSFORM);
#  endif
    P = transform_point(tfm, P);
  }

  return P;
#else
return ray.P + (ray.D * t);
#endif

}



void shader_setup_from_ray()
{

 int object      = GSD.object;
 GSD.object      = GetObjectID( GSD.object);

#ifdef _HAIR_
  if (sd->type & PRIMITIVE_ALL_CURVE) {
    curve_shader_setup(kg, sd, isect, ray);
  }
  else
#endif
  if(bool(GSD.type & PRIMITIVE_TRIANGLE) ){

    float3 Ng  = triangle_normal();
    GSD.shader = int(kernel_tex_fetch(_tri_shader, GSD.prim));
    GSD.P = triangle_refine(GSD.P,GSD.I,GSD.ray_length,object,GSD.prim,GSD.geometry);
    GSD.Ng = Ng;
    GSD.N  = Ng;


    if( bool (GSD.shader & SHADER_SMOOTH_NORMAL))
      GSD.N = triangle_smooth_normal(Ng,GSD.prim,GSD.u,GSD.v);

#ifdef  WITH_STAT_ALL
#ifdef sd_N_f3
    CNT_ADD(CNT_sd_N);
    STAT_DUMP_f3(sd_N_f3,GSD.N);
#endif
#endif
#ifdef _DPDU_
    triangle_dPdudv(GSD.prim, GSD.dPdu, GSD.dPdv);
#endif
  }
  else {
    //motion_triangle_shader_setup(kg, sd, isect, ray, false);
  }
  GSD.flag |= kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).flags;
  if (!OBJECT_IS_NONE(object)) {
    object_normal_transform(GSD.N);
    object_normal_transform(GSD.Ng);
#ifdef _DPDU_
    object_dir_transform_auto(GSD.dPdu);
    object_dir_transform_auto(GSD.dPdv);
#endif
  }
  bool backfacing = (dot3(GSD.Ng, -GSD.I) < 0.0f);
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
  differential_transfer(GSD.dP, GSD.dP, GSD.I, GSD.dI, GSD.Ng, GSD.ray_length);
  differential_incoming(GSD.dI, GSD.dI);
  differential3 dP = GSD.dP;
  differential_dudv(GSD.du, GSD.dv, GSD.dPdu, GSD.dPdv, dP, GSD.Ng);
#endif
  GSD.I *= -1;

}

void shader_setup_from_subsurface()
{
  const bool backfacing = bool(GSD.flag & SD_BACKFACING);
  GSD.flag = 0;
  int object      = GSD.object;
  GSD.object      = GetObjectID( GSD.object);
  float isect_t   = GSD.P.w;
  GSD.P.w         = 0.;
  /* fetch triangle data */
  if (GSD.type == PRIMITIVE_TRIANGLE) {
    float3 Ng  = triangle_normal();
    GSD.shader = int(kernel_tex_fetch(_tri_shader, GSD.prim));
    /* TODO  static triangle */
  
    GSD.P = triangle_refine(GSD.P,GSD.I,isect_t,object,GSD.prim,GSD.geometry);
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

  if (!OBJECT_IS_NONE(object)) {
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

#define GET_CALL_TYPE GSD.shader
void main()
{

#ifdef  WITH_STAT_ALL
    setDumpPixel();
    rec_num  = int(GSD.Ng.x);
#endif

switch(GET_CALL_TYPE){
case SETUP_CALL_TYPE_RAY:
shader_setup_from_ray();
break;
case SETUP_CALL_TYPE_SSS:
shader_setup_from_subsurface();
break;
default:
break;
}


}