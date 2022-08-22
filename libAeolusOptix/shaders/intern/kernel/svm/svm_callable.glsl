#ifndef _SVM_CALLABLE_H_
#define _SVM_CALLABLE_H_

#include "kernel/svm/svm_util.h.glsl"

#define CALLABLE_NODE_LOCATION 2
#define CALLABLE_NOISE 3u
#define CALLABLE_VORONOI 4u
#define CALLABLE_GEOM 5u
#define CALLABLE_MASG 6u
#define CALLABLE_TEX 7u
#define CALLABLE_BSDF 8u
#define CALLABLE_UTILS 9u

#define CALLEE_SVM_TEX_NOISE 0
#define CALLEE_SVM_TEX_WAVE  1
#define CALLEE_SVM_TEX_SKY   2 
#define CALLEE_SVM_TEX_ENV   3
#define CALLEE_SVM_TEX_WHITE_NOISE   4


#define CALLEE_UTILS_MIX       0
#define CALLEE_UTILS_BRI       1


#ifdef NODE_Caller

struct NodeIO{
    int  offset;
    uint type;
    float data[62];
};

layout(location = CALLABLE_NODE_LOCATION) callableDataNV NodeIO nio;
#define EXECUTION_NOISE    executeCallableNV(CALLABLE_NOISE,CALLABLE_NODE_LOCATION)
#define EXECUTION_VOR      executeCallableNV(CALLABLE_VORONOI,CALLABLE_NODE_LOCATION)
#define EXECUTION_GEOM     executeCallableNV(CALLABLE_GEOM,CALLABLE_NODE_LOCATION)
#define EXECUTION_MASG     executeCallableNV(CALLABLE_MASG,CALLABLE_NODE_LOCATION)
#define EXECUTION_TEX      executeCallableNV(CALLABLE_TEX,CALLABLE_NODE_LOCATION)
#define EXECUTION_BSDF     executeCallableNV(CALLABLE_BSDF,CALLABLE_NODE_LOCATION)
#define EXECUTION_UTILS    executeCallableNV(CALLABLE_UTILS,CALLABLE_NODE_LOCATION)

#define stack_store_float_nio(a,ofs) {stack[a + 0] = nio.data[ofs];}
#define stack_store_float3_nio(a,ofs) {stack[a + 0] = nio.data[ofs];stack[a + 1] = nio.data[ofs+1];stack[a + 2] = nio.data[ofs+2];}
#define stack_load_float_nio(a,ofs)  {nio.data[ofs]  = stack[a + 0];}
#define stack_load_float3_nio(a,ofs) {nio.data[ofs]  = stack[a + 0];nio.data[ofs+1]=stack[a + 1];nio.data[ofs+2]=stack[a + 2];}

#endif




#ifdef NODE_Callee

#ifdef NODE_Callee_Utils
struct NodeIO_Utils{
    int   offset;
    uint  type;
    uint  type2;
    float fac;
    vec3    c1;
    vec3    c2;
};
layout(location = CALLABLE_NODE_LOCATION) callableDataInNV NodeIO_Utils nio;
#define UTILS_NODE_MIX_TYPE nio.type2
#endif

#ifdef NODE_Callee_BSDF
struct NodeIO_BSDF{
    int  offset;
    uint type;
    
    int  num_closure_left;   /// 0
    int  num_closure;
    int  alloc_offset;    
    int  flag;        

    float3 I;              ///  4 

    float3    N;            /// 7  
    float param1;
    float param2;

    float3 weight;        /// 12


     float specular;     /// 15
     float roughness;
     float specular_tint;
     float anisotropic;

     float sheen;
     float sheen_tint;
     float clearcoat;
     float clearcoat_roughness;

     float transmission;
     float anisotropic_rotation;
     float transmission_roughness;
     float eta; 

     uint  type_dist;
     uint  type_ssr;        


    float3       T;            /// 29
    float4 base_color;         /// 32
    float3 clearcoat_normal;   /// 36
    float3 subsurface_radius;  /// 39
    float3 subsurface_color;   /// 42

};
#define BSSRDF_RAD nio.I
#define BSSRDF_MIX_W nio.specular
#define BSSRDF_SHARP nio.roughness

#define BSDF_DATA_NODE_Y nio.type_dist
#define BSDF_rotation  nio.specular
#define BSDF_PATH_FLAG nio.offset
#define BSDF_closure_transparent_extinction nio.I

layout(location = CALLABLE_NODE_LOCATION) callableDataInNV NodeIO_BSDF nio;
#endif



#ifdef NODE_Callee_NOISE
struct NodeIO{
    int  offset;
    uint type;
    float data[62];
};
layout(location = CALLABLE_NODE_LOCATION) callableDataInNV NodeIO nio;
#endif
#ifdef NODE_Callee_VORONOI
struct NodeIO_VOR
{
    int offset;
    uint dimensions;
    vec3 coord;
    float w;
    float scale;
    float smoothness;
    float exponent;
    float randomness;
    uint feature;
    uint metric;
  
};
layout(location = CALLABLE_NODE_LOCATION) callableDataInNV NodeIO_VOR nio;
#endif


#ifdef NODE_Callee_GEOM

struct sd_geom_tiny{

  int  offset;
  uint call_type;

  float3 N;    
  int object_flag;
  int prim;
  int type;
  float u;
  float v;
  int object;
  differential du;
  differential dv;
  int lamp;
  uint4      node;
  int         geometry;
  //vec3 dPdu;

};

#define sizeof_sd_geom_tiny 18*4
layout(location = CALLABLE_NODE_LOCATION) callableDataInNV sd_geom_tiny ioSD;
#define GSD ioSD
#define GSD_TINY 

#define SVM_GEOM_NORMAL_COLOR   float3(GSD.du.dx,GSD.du.dy,GSD.dv.dx,0.)
#define SVM_GEOM_NORMAL_ISBACKFACING  bool(floatBitsToInt(GSD.dv.dy))
#define SVM_GEOM_NORMAL_SHADER  floatBitsToInt(GSD.N.w)

#define SVM_GEOM_RET_TF(tf)    ioSD.call_type = uint(tf);
#define SVM_GEOM_RET_TANG(v3) {ioSD.N.x = v3.x;ioSD.N.y = v3.y;ioSD.N.z= v3.z;}
#define SVM_GEOM_RET_NORMAL(v3)  SVM_GEOM_RET_TANG(v3)

#define SVM_GEOM_RET_ATTR(v4) { ioSD.N.x = v4.x;ioSD.N.y = v4.y;ioSD.N.z= v4.z;ioSD.N.w = v4.w;}
#define SVM_GEOM_RET_DESCTYPE(u)  ioSD.object_flag = int(u)
#define SVM_GEOM_RET_TYPE       ioSD.call_type
#define SVM_GEOM_RET_OUTOFFSET(u)  ioSD.offset  = int(u)

#define SVM_GEOM_VC_LAYERID floatBitsToUint(ioSD.N.w)
#define SVM_GEOM_VC_RET_DESC_OFFSET(v) ioSD.call_type = v
#define SVM_GEOM_VC_RET(v4) SVM_GEOM_RET_ATTR(v4)

#define SVM_GEOM_RET_BUMP_ENTER(p,dpdx,dpdy) {\
       ioSD.N.xyz = p.xyz;\
       ioSD.N.w   = dpdx.x;\
       ioSD.object_flag = floatBitsToInt(dpdx.y);\
       ioSD.prim  = floatBitsToInt(dpdx.z);\
       ioSD.type  = floatBitsToInt(dpdy.x);\
       ioSD.u     = dpdy.y;\
       ioSD.v     = dpdy.z;\
}
#endif


#ifdef NODE_Callee_MASG
struct NodeIO_MASG
{
    int offset;
    uint type;

    vec3 co;
    float w;
    float scale;
    float detail;
    float dimension;
    float lacunarity;
    float foffset;
    float gain;
    uint  dimensions;
  
};
layout(location = CALLABLE_NODE_LOCATION) callableDataInNV NodeIO_MASG nio;

#define SVM_NODE_MASG_RET_FAC(f)  { nio.co.x = f;}

#endif
#ifdef NODE_Callee_TEX

struct NodeIO_SKY
{
    int offset;
    uint type;
    float3 dir;
    uint4  node;
};

layout(location = CALLABLE_NODE_LOCATION) callableDataInNV NodeIO_SKY nio;
#define SVM_NODE_SKY_RET_FAC4(f)  { nio.dir = f;}

#endif
#endif

#endif