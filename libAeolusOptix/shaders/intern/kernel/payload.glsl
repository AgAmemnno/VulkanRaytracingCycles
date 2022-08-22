///prim_object  = > idxOffset
///prim_index    = > vertOffset

#define ObjectID (gl_InstanceCustomIndexNV & 0x7FFFFF)
#define PrimitiveOffset(id) kernel_tex_fetch(_prim_object, id)
#define VertexOffset(id) kernel_tex_fetch(_prim_index, id)
#define OBJECT_IS_NONE(id) bool(id  & 0x800000)
#define GetObjectID(id) (id & 0x7FFFFF)


#define DEBX 226 
#define DEBY 146

#define RPL_TYPE_ISECT 0

#if defined(RPL_RGEN_OUT) |  defined(RPL_RGEN_IN)  |  defined(RPL_RGEN_AHIT_IN)
#define TRACE_TYPE_MAIN 0
#define MISS_TYPE_MAIN 0

#if defined(RPL_RGEN_OUT)


#ifndef CD_TYPE0_OUT
PathState state;
#define GSTATE state

#endif

#ifndef CD_TYPE1_OUT
ShaderData    sd;
#define GSD   sd
#endif

PathRadiance L;   
#define GLAD   L

vec4 throughput;
#define GTHR   throughput
#define L_USE_LIGHT_PASS GLAD.use_light_pass

layout(location = RPL_TYPE_ISECT) rayPayloadNV Intersection isect;
#define GISECT  isect
#define TRACE_RET_MAIN  return !(isect.type== PRIMITIVE_NONE);

#define TRACE_SET_VISIBILITY(vis) { \
    isect.type   = int(PRIMITIVE_NONE);\
    isect.t      = uintBitsToFloat(vis);\
    isect.prim   = -1;\
}


#endif


#if defined(RPL_RGEN_IN)

layout(location = RPL_TYPE_ISECT) rayPayloadInNV Intersection isect;
#define GISECT  isect
#ifndef RPL_MISS
hitAttributeNV vec2 attribs;
#endif
#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_tri_verts2_;
layout(buffer_reference) buffer _prim_type_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer _tri_vindex2_;
layout(buffer_reference, std430) buffer KernelTextures
{
    _prim_tri_verts2_  _prim_tri_verts2;
    int64_t pad;
    _prim_type_ _prim_type;
    int64_t pad1;
    _prim_index_  _prim_index;
    _prim_object_ _prim_object;
    int64_t pad2[11];
    _tri_vindex2_ _tri_vindex2;
};

layout(buffer_reference, std430) readonly buffer _prim_tri_verts2_
{
     float4 data[];
};
layout(buffer_reference, std430) readonly buffer _prim_type_
{
     uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_object_
{
     uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_index_
{
     uint data[];
};
layout(buffer_reference, std430) readonly buffer _tri_vindex2_
{
     uint data[];
};
layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

#endif

#if defined(RPL_RGEN_AHIT_IN)

layout(location = RPL_TYPE_ISECT) rayPayloadInNV uint visibility;
#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_visibility_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
//_tri_shader
//_curves
//_shaders

layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[3];
    _prim_visibility_ _prim_visibility;
    _prim_index_  _prim_index;
    _prim_object_ _prim_object;
};
layout(buffer_reference, std430) readonly buffer _prim_visibility_
{
     uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_index_
{
     uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_object_
{
     uint data[];
};
layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

#endif


#endif


#ifdef SHADOW_CALLER
#define SHADOW_ANYHIT 1
#endif



#if defined(SHADOW_CALLER2) || defined(SHADOW_CALLEE2)
/*
struct Intersection
{
    float t;
    float u;
    float v;
    int prim;
    int object;
    int type;
};
*/

struct IsectInfo{
    uint offset;
    uint numhits;
    uint max_hits;
    uint visibility;
    int  terminate;
};

#ifdef SHADOW_CALLER2

#define  PLYMO_ISECT_offset(ofs) isect.t = uintBitsToFloat(ofs)
#define  PLYMO_ISECT_numhits(numhits) isect.u = uintBitsToFloat(numhits)
#define  PLYMO_ISECT_maxhits(maxhits) isect.v = uintBitsToFloat(maxhits)
#define  PLYMO_ISECT_visibility(v)    isect.prim = int(v);
#define  PLYMO_ISECT_terminate(v)     isect.object = int(v);

#define  PLYMO_ISECT_get_offset       floatBitsToUint(isect.t)
#define  PLYMO_ISECT_get_numhits      floatBitsToUint(isect.u)
#define  PLYMO_ISECT_get_maxhits      floatBitsToUint(isect.v) 
#define  PLYMO_ISECT_get_visibility    uint(isect.prim)
#define  PLYMO_ISECT_get_terminate     bool(isect.object)
#define TRACE_RET_TERM  return bool(isect.object);

#define PLYMO_ISECT_SET(ofs,num,mx,vis,ter){\
  PLYMO_ISECT_offset(ofs);\
  PLYMO_ISECT_numhits(num);\
  PLYMO_ISECT_maxhits(mx);\
  PLYMO_ISECT_visibility(vis);\
  PLYMO_ISECT_terminate(ter);\
}

#define SHADOW_ANYHIT 1
#define SHADOW_LOCATION 1
#endif

#ifdef SHADOW_CALLEE2
layout(location = 0) rayPayloadInNV IsectInfo iinfo;

#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_type_;
layout(buffer_reference) buffer _prim_visibility_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer _tri_shader_;
layout(buffer_reference) buffer _shaders_;

//_curves
//_shaders
layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[2];
    _prim_type_             _prim_type;
    _prim_visibility_  _prim_visibility;
    _prim_index_       _prim_index;
    _prim_object_       _prim_object;
    int64_t pad1[9];
    _tri_shader_       _tri_shader;
    int64_t pad2[10];
    _shaders_ _shaders;

};

layout(buffer_reference, std430) readonly buffer _prim_type_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_visibility_
{
     uint data[];
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
layout(buffer_reference, std430) readonly buffer _shaders_
{
    KernelShader data[];
};

#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) buffer name##_ {\
  type data[];\
};

KERNEL_TEX(Intersection,pool_is)
#undef KERNEL_TEX

#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer IntersectionPool {
    KERNEL_TEX(Intersection,pool_is)
};
#undef KERNEL_TEX


layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    layout(offset=16) IntersectionPool  pool2_ptr;
} push;
#define IS(i) push.pool2_ptr.pool_is.data[i]

#endif

#endif



#if defined(LHIT_CALLER) || defined(LHIT_CALLEE)

#if defined(LHIT_CALLER)

struct LocalIntersection_tiny { 
  int    num_hits; 
  float3 rayP;
  float3 rayD;
  Intersection isect[LOCAL_MAX_HITS];
  float3 weight[LOCAL_MAX_HITS];
 };

#define GetReturnRayPD {\
        ss_isect.rayP.xyz = vec3(isect.t,isect.u,isect.v);\
        ss_isect.rayD.xyz = vec3(intBitsToFloat(isect.prim),intBitsToFloat(isect.object),intBitsToFloat(isect.type));\
}
#define GetReturnNumHit {\
    int idx         = GSD.atomic_offset + BSSRDF_MAX_HITS;\
     ss_isect.num_hits = IS(idx).prim;\
}


#define  TRACE_TYPE_LHIT 2
#define  MISS_TYPE_LHIT 2
#define  RPL_TYPE_LISECT 0
#define  PLYMO_LISECT_offset(ofs)       isect.t = intBitsToFloat(ofs)
#define  PLYMO_LISECT_maxhits(maxhits)  isect.u = intBitsToFloat(maxhits)
#define  PLYMO_LISECT_lcg_state(lcg)    isect.v = uintBitsToFloat(lcg)
#define  PLYMO_LISECT_numhits(numhits)  isect.prim  = numhits
#define  PLYMO_LISECT_local_object(obj) isect.object = obj
#define  PLYMO_LISECT_GET_numhits ss_isect.num_hits =  isect.prim
#define  PLYMO_LISECT_GET_lcg_state(lcg) lcg = floatBitsToUint(isect.v)
#define  LISECT_GET_NG(Ng,ISid) {\
  uvec3 tri_vindex = kernel_tex_fetch_vindex(_tri_vindex2, IS(ISid).prim) + VertexOffset(IS(ISid).type);\
  float3 tri_a = push.data_ptr._prim_tri_verts2.data[tri_vindex.x];\
  float3 tri_b = push.data_ptr._prim_tri_verts2.data[tri_vindex.y];\
  float3 tri_c = push.data_ptr._prim_tri_verts2.data[tri_vindex.z];\
  Ng = normalize(cross(tri_b - tri_a, tri_c - tri_a));\
}

#endif


#if defined(MISS_THROUGH_CALLER)

#define PLYMO_IS_ARGLHIT(scN,bssrdf_u,bssrdf_v) {\
  int idx      = GSD.atomic_offset;\
  IS(idx).t    = GSD.Ng.x;\
  IS(idx).u    = GSD.Ng.y;\
  IS(idx).v    = GSD.Ng.z;\
  IS(idx).prim = floatBitsToInt(GSD.time);\
  IS(idx).object = GSD.object;\
  IS(idx).type = GSD.type;\
  idx++;\
  IS(idx).t = GSD.P.x;\
  IS(idx).u = GSD.P.y;\
  IS(idx).v = GSD.P.z;\
  IS(idx).prim   = floatBitsToInt(bssrdf_u);\
  IS(idx).object = floatBitsToInt(bssrdf_v);\
  IS(idx).type   = scN;\
  idx++;\
  IS(idx).t = GSD.dP.dx.x;\
  IS(idx).u = GSD.dP.dx.y;\
  IS(idx).v = GSD.dP.dx.z;\
  IS(idx).type   = GSD.num_closure;\
  idx++;\
  IS(idx).t = GSD.dP.dy.x;\
  IS(idx).u = GSD.dP.dy.y;\
  IS(idx).v = GSD.dP.dy.z;\
} 

#endif

#if defined(LHIT_CALLEE)
#define RPL_LHIT 1
#define GET_OBJECTID gl_InstanceID;
/*
struct Intersection
{
    float t;
    float u;
    float v;
    int prim;
    int object;
    int type;
};
*/
struct LIsectInfo{ 
  int  offset;
  int  max_hits;
  uint lcg_state;
  int  num_hits;
  int  local_object;
  int  type;
};


#define  isValid_lcg_state(lcg) lcg != uint(-1)
#if defined(MISS_THROUGH_CALLEE)
layout(location = 0) rayPayloadInNV LIsectInfo linfo;
layout(location = 1) rayPayloadNV   LIsectInfo linfo2;
#define PLYMO_IS_ARGLHIT(GSD) {\
  int idx           = linfo.offset;\
  GSD.Ng.xyz        = vec3(IS(idx).t,IS(idx).u,IS(idx).v);\
  GSD.time          = intBitsToFloat(IS(idx).prim);\
  GSD.object        = IS(idx).object;\
  GSD.type          = IS(idx).type;\
  idx++;\
  GSD.P.xyz   = vec3(IS(idx).t,IS(idx).u,IS(idx).v);\
  bssrdf_u    =  intBitsToFloat( IS(idx).prim );\
  bssrdf_v    =  intBitsToFloat( IS(idx).object );\
  scN   = IS(idx).type;\
  idx++;\
  GSD.dP.dx.xyz   = vec3(IS(idx).t,IS(idx).u,IS(idx).v);\
  GSD.num_closure =   IS(idx).type;\
  idx++;\
  GSD.dP.dy.xyz   = vec3(IS(idx).t,IS(idx).u,IS(idx).v);\
} 
#else
layout(location = 1) rayPayloadInNV LIsectInfo linfo;
#endif

#extension GL_EXT_buffer_reference2 : enable
#extension GL_EXT_scalar_block_layout :require
layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_object_;

#ifdef MISS_THROUGH_CALLEE
layout(buffer_reference) buffer _prim_tri_verts2_;
layout(buffer_reference) buffer _objects_;
layout(buffer_reference) buffer _tri_vindex2_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _texture_info_;
layout(buffer_reference) buffer  _sample_pattern_lut_;
layout(buffer_reference, std430) buffer KernelTextures
{
  _prim_tri_verts2_  _prim_tri_verts2;
    int64_t pad[3];    
    _prim_index_       _prim_index;
    _prim_object_       _prim_object;
    _objects_            _objects;
    int64_t pad1[10];
    _tri_vindex2_ _tri_vindex2;
    int64_t pad2[10];
    _sample_pattern_lut_     _sample_pattern_lut;

};
layout(buffer_reference, std430) readonly buffer _prim_tri_verts2_
{
    float4 data[];
};
layout(buffer_reference, std430) readonly buffer _objects_
{
    KernelObject data[];
};
layout(buffer_reference, std430) readonly buffer _tri_vindex2_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _prim_index_
{
    uint data[];
};
layout(buffer_reference, std430) readonly buffer _sample_pattern_lut_
{
    uint data[];
};

#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) buffer name##_ {\
  type data[];\
};
KERNEL_TEX(ShaderClosure,pool_sc)
#undef KERNEL_TEX
#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer ShaderClosurePool {
    KERNEL_TEX(ShaderClosure,pool_sc)
};
#undef KERNEL_TEX

#else

layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[5];    
    _prim_object_       _prim_object;
};
#endif

layout(buffer_reference, std430) readonly buffer _prim_object_
{
    uint data[];
};



#define KERNEL_TEX(type,name) \
layout(buffer_reference, scalar, buffer_reference_align = alignof_##type) buffer name##_ {\
  type data[];\
};

KERNEL_TEX(Intersection,pool_is)
#undef KERNEL_TEX

#define KERNEL_TEX(type,name) name##_  name;
layout(buffer_reference, scalar, buffer_reference_align = 8) buffer IntersectionPool {
    KERNEL_TEX(Intersection,pool_is)
};
#undef KERNEL_TEX


layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    #ifdef MISS_THROUGH_CALLEE
    layout(offset=8) ShaderClosurePool  pool1_ptr;
    #endif
    layout(offset=16) IntersectionPool  pool2_ptr;
} push;
#ifdef MISS_THROUGH_CALLEE
    #define SC(i) push.pool1_ptr.pool_sc.data[i]
#endif

#define IS(i) push.pool2_ptr.pool_is.data[i]




#endif

#endif



#if defined(CD_TYPE0_OUT) |  defined(CD_TYPE0_IN) |  defined(CD_TYPE01_IN)

#define LIGHT_SAMPLE 0u

#define prd_return(tf) {break;} ///return;}
struct args_acc_light{
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 path_total;
  vec4 throughput;
};
 
struct PRG2ARG
{
args_sd    sd;     // 140
args_acc_light L;  // 80
int  use_light_pass;
int  type;
Ray ray; //104
PathState  state; //56
};
/*
 struct BsdfEval {
#ifdef _PASSES_
  //int use_light_pass;
#endif

  float3 diffuse;
#ifdef _PASSES_
  float3 glossy;
  float3 transmission;
  float3 transparent;
  //float3 volume;
#endif
#ifdef _SHADOW_TRICKS_
  float3 sum_no_mis;
#endif
} ;
*/
struct PLMO_SD_EVAL
{
args_sd    sd;   // 140
BsdfEval eval;   // 80

vec4 omega_in;    
differential3 domega_in; 

int      label;
int      use_light_pass;
int      type;
float    pdf;
};


#ifdef CD_TYPE0_OUT

layout(location = 0) callableDataNV PRG2ARG CD_TYPE0_OUT;
#define GARG   CD_TYPE0_OUT
#define GSTATE GARG.state

#define ply_L2Eval_lamp GARG.use_light_pass
#define ply_L2Eval_light_uv_term_double GARG.L.emission.xyzw
#define ply_L2Eval_profi_idx GARG.L.direct_emission.w
#define ply_L2Eval_rec_num   GARG.L.indirect.w
#define ply_L2Eval_light_hasemission GARG.type



#define PLYMO_L2Eval_omega_in  vec4(intBitsToFloat(GARG.use_light_pass),intBitsToFloat(GARG.type),GARG.ray.t,GARG.ray.time)
#define PLYMO_L2Eval_domega_in_dx  GARG.ray.P
#define PLYMO_L2Eval_domega_in_dy  GARG.ray.D

#define PLYMO_L2Eval_label floatBitsToInt(GARG.ray.dP.dx.x)
#define PLYMO_L2Eval_get_use_light_pass floatBitsToInt(GARG.ray.dP.dx.y)
#define PLYMO_L2Eval_type  floatBitsToInt(GARG.ray.dP.dx.z)
#define PLYMO_L2Eval_set_label(VAL) GARG.ray.dP.dx.x = intBitsToFloat(VAL)
#define PLYMO_L2Eval_set_use_light_pass(VAL) GARG.ray.dP.dx.y = intBitsToFloat(VAL)
#define PLYMO_L2Eval_set_type(VAL)  GARG.ray.dP.dx.z = intBitsToFloat(VAL)
#define PLYMO_L2Eval_pdf  GARG.ray.dP.dx.w
#define PLYMO_EVAL_diffuse GARG.L.emission
#define PLYMO_EVAL_glossy   GARG.L.direct_emission
#define PLYMO_EVAL_transmission GARG.L.indirect
#define PLYMO_EVAL_transparent GARG.L.path_total
#define PLYMO_EVAL_sum_no_mis GARG.L.throughput
#define PLYMO_EVAL_set_use_light_pass(d) PLYMO_L2Eval_set_use_light_pass(d)
#define PLYMO_EVAL_get_use_light_pass PLYMO_L2Eval_get_use_light_pass

#define ply_return_bounce   GARG.type
#define ply_label  GARG.sd.alloc_offset


#ifndef RMISS_BG
/*Shared Arguments Parse Difinitions */
#define ARGS_PRG3_SAMPLE(randu,randv) \
PLYMO_L2Eval_set_type(BSDF_CALL_TYPE_SAMPLE);\
GARG.L.emission           =  vec4(randu,randv,123.,456.);
#endif



#endif

#ifdef CD_TYPE0_IN

layout(location = 0) callableDataInNV PRG2ARG CD_TYPE0_IN;
#define GARG   CD_TYPE0_IN
#define GSTATE GARG.state
#define GLAD   GARG.L
#define GTHR   GARG.L.throughput
#define NO_L_STATE
#define L_USE_LIGHT_PASS GARG.use_light_pass

#define ply_L2Eval_lamp GARG.use_light_pass
#define ply_L2Eval_light_uv_term_double GARG.L.emission.xyzw
#define ply_L2Eval_light_hasemission GARG.type
#define ply_L2Eval_use_light_pass GARG.use_light_pass

#define ply_L2Eval_profi_idx GARG.L.direct_emission.w
#define ply_L2Eval_rec_num   GARG.L.indirect.w

#define ply_L2Eval_diffuse GARG.L.emission
#define ply_L2Eval_glossy   GARG.L.direct_emission
#define ply_L2Eval_transmission GARG.L.indirect
#define ply_L2Eval_transparent GARG.L.path_total
#define ply_L2Eval_sum_no_mis GARG.L.throughput


#define ply_rng_u plymo.eval.diffuse.x
#define ply_rng_v plymo.eval.diffuse.y
#define ply_prs_diffuse  GARG.sd.N
#define ply_prs_glossy  GARG.sd.I
#define ply_prs_transmission  GARG.sd.dP.dx
#define ply_prs_volume  GARG.sd.dP.dy

// 4 + 68 + 104 + 128 + 56
#define sizeof_hitPatload0 360
#define ply_return_bounce   GARG.type
#define ply_label  GARG.sd.alloc_offset

#endif



#if  defined(CD_TYPE01_IN)

layout(location = 0) callableDataInNV PLMO_SD_EVAL CD_TYPE01_0;
layout(location = 1) callableDataInNV PLMO_SD_EVAL CD_TYPE01_1;
#define SVM_TYPE_EVAL_SAMPLE 


#define PLYMO CD_TYPE01_0
ShaderClosure sc;
#define DEF_BSDF sc
#define _getSC(idx) SC(idx)



#define PLYMO_Eval_profi_idx PLYMO.eval.glossy.w
#define PLYMO_Eval_rec_num   PLYMO.eval.transmission.w


#define PLYMO_EVAL_diffuse PLYMO.eval.diffuse
#define PLYMO_EVAL_glossy  PLYMO.eval.glossy 
#define PLYMO_EVAL_transmission  PLYMO.eval.transmission
#define PLYMO_EVAL_transparent  PLYMO.eval.transparent
#define PLYMO_EVAL_sum_no_mis  PLYMO.eval.sum_no_mis
#define PLYMO_EVAL_get_use_light_pass  PLYMO.use_light_pass
#define PLYMO_EVAL_set_use_light_pass(d)  PLYMO.use_light_pass = d


/*Shared Arguments Parse Difinitions */
#define ply_state_flag floatBitsToInt(PLYMO.eval.diffuse.x)
#define ply_use_mis floatBitsToInt(PLYMO.eval.diffuse.y)
#define ply_call_flag floatBitsToInt(PLYMO.eval.diffuse.z)
#define ply_rec_num floatBitsToInt(PLYMO.eval.diffuse.w)
#define ply_rng_u PLYMO.eval.diffuse.x
#define ply_rng_v PLYMO.eval.diffuse.y
#define ARGS_shader_bsdf_eval \
bool use_mis          = bool(ply_use_mis);\
const float3 omega_in = PLYMO.omega_in;\
float light_pdf       = PLYMO.pdf;


#define ARGS_EVAL1 (sc, PLYMO.sd.I, omega_in, pdf);
#define ARGS_EVAL2 (PLYMO.sd.I, omega_in, pdf);
#define ARGS_EVAL3 (PLYMO.sd.I, omega_in, pdf,lcg_state);



#endif

#ifdef RPL_RGEN_IN_

#define set_arg_state {\
  GARG.state.flag   =  prd.state.flag; \
  GARG.state.rng_hash = prd.state.rng_hash;\
  GARG.state.bounce = prd.state.bounce;\
  GARG.state.rng_offset =  prd.state.rng_offset;\
  GARG.state.sample_rsv =  prd.state.sample_rsv;\
  GARG.state.ray_pdf = prd.state.ray_pdf;\
  GARG.state.num_samples =  prd.state.num_samples;\
  GARG.state.ray_pdf = prd.state.ray_pdf;\
}

#define prd_set_arg_state {\
  prd.state.flag = GARG.state.flag; \
  prd.state.rng_hash = GARG.state.rng_hash;\
  prd.state.bounce = GARG.state.bounce;\
  prd.state.rng_offset =  GARG.state.rng_offset;\
  prd.state.sample_rsv =  GARG.state.sample_rsv;\
  prd.state.ray_pdf = GARG.state.ray_pdf;\
  prd.state.num_samples =  GARG.state.num_samples;\
  prd.state.ray_pdf = GARG.state.ray_pdf;\
}

#endif

#endif

#if defined(CD_TYPE1_OUT) |  defined(CD_TYPE1_IN)
#define SVM_NODES_EVAL 1u


#ifdef CD_TYPE1_OUT
layout(location = 1) callableDataNV ShaderData CD_TYPE1_OUT;
#define GSD CD_TYPE1_OUT
#define getSC() SC(GSD.alloc_offset)
#endif


#ifdef CD_TYPE1_IN

layout(location = 1) callableDataInNV ShaderData CD_TYPE1_IN;
#define GSD CD_TYPE1_IN
#define getSC() SC(sd.alloc_offset)
#define _getSC(next) SC(next)
#endif

#endif



#if defined(CD_TYPE1_OUT) &&  defined(CD_TYPE0_IN)

#define set_prg3_tiny_sd(omega_in,pdf,label,light_pass,use_mis) {\
  GSD.P      = GARG.sd.P;\
  GSD.N      = GARG.sd.N;\
  GSD.Ng     = GARG.sd.Ng;\
  GSD.I      = GARG.sd.I;\
  GSD.shader = GARG.sd.flag;\
  GSD.flag   = GARG.sd.type;\
  GSD.object_flag = GARG.sd.object;\
  GSD.prim     =  GARG.sd.num_closure;\
  GSD.type     =  GARG.sd.atomic_offset;\
  GSD.u        =  GARG.sd.time;\
  GSD.v        =  GARG.sd.ray_length;\
  GSD.object   =  GARG.sd.alloc_offset;\
  GSD.time     =  uintBitsToFloat(GARG.sd.lcg_state);\
  GSD.dP       =  GARG.sd.dI;\
  GSD.dI.dx    =  vec4(intBitsToFloat(GSTATE.flag), intBitsToFloat(use_mis),intBitsToFloat(1234),intBitsToFloat(rec_num));\
  GSD.ray_P    =  omega_in;\
  GSD.lcg_state = label;\
  GSD.num_closure = light_pass;\
  GSD.num_closure_left = BSDF_CALL_TYPE_EVAL;\
  GSD.randb_closure = pdf;\
}
#define PLYMO_EVAL_diffuse GSD.dI.dx
#define PLYMO_EVAL_glossy  GSD.dI.dy
#define PLYMO_EVAL_transmission  vec4(GSD.du.dx,GSD.du.dy,GSD.dv.dx,GSD.dv.dy)
#define PLYMO_EVAL_set_transmission(value){\
     GSD.du.dx  = value.x;\
     GSD.du.dy  = value.y;\
     GSD.dv.dx  = value.z;\
}
#define PLYMO_EVAL_set_add3_transmission(value){\
     GSD.du.dx  += value.x;\
     GSD.du.dy  += value.y;\
     GSD.dv.dx  += value.z;\
}
#define PLYMO_EVAL_set_mul_transmission(value){\
     GSD.du.dx  *= value;\
     GSD.du.dy  *= value;\
     GSD.dv.dx  *= value;\
}
#define PLYMO_EVAL_set_mul3_transmission(value){\
     GSD.du.dx  *= value.x;\
     GSD.du.dy  *= value.y;\
     GSD.dv.dx  *= value.z;\
}
#define PLYMO_EVAL_set_zero_transmission {\
       GSD.du.dx    = 0.f;\
       GSD.du.dy    = 0.f;\
       GSD.dv.dx    = 0.f;\
}
#define PLYMO_EVAL_transparent  GSD.dPdu
#define PLYMO_EVAL_sum_no_mis  GSD.dPdv
#define PLYMO_EVAL_get_use_light_pass  GSD.num_closure

#define set_ply_Eval {\
  ply_L2Eval_diffuse      = PLYMO_EVAL_diffuse;\
  ply_L2Eval_glossy       = PLYMO_EVAL_glossy;\
  ply_L2Eval_transmission = PLYMO_EVAL_transmission;\
  ply_L2Eval_transparent  = PLYMO_EVAL_transparent;\
  ply_L2Eval_sum_no_mis   = PLYMO_EVAL_sum_no_mis;\
}

#endif


#if defined(CD_TYPE2_OUT) 
struct ARG_T2{
   float v[12];
};
layout(location = 2) callableDataNV ARG_T2 CD_TYPE2_OUT;
#endif


#ifdef PLYMO_EVAL_diffuse

#if defined(PLYMO_EVAL_sum_no_mis) 

#if defined(PLYMO_EVAL_set_use_light_pass) && defined(PLYMO_EVAL_get_use_light_pass)
ccl_device_inline void PLYMO_bsdf_eval_init(
                                      ClosureType type,
                                      float3 value,
                                      int use_light
                                      )
{
#ifdef _PASSES_
    PLYMO_EVAL_set_use_light_pass(use_light);//kernel_data.film.use_light_pass;

  if (PLYMO_EVAL_get_use_light_pass !=0 ) {
    PLYMO_EVAL_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    PLYMO_EVAL_glossy = make_float3(0.0f, 0.0f, 0.0f);
    #ifdef PLYMO_EVAL_set_transmission
    PLYMO_EVAL_set_transmission(make_float3(0.0f, 0.0f, 0.0f));
    #else
    PLYMO_EVAL_transmission = make_float3(0.0f, 0.0f, 0.0f);
    #endif
    PLYMO_EVAL_transparent = make_float3(0.0f, 0.0f, 0.0f);
    //PLYMO.eval.volume = make_float3(0.0f, 0.0f, 0.0f);

    if (type == CLOSURE_BSDF_TRANSPARENT_ID)
      PLYMO_EVAL_transparent = value;
    else if (CLOSURE_IS_BSDF_DIFFUSE(type) || CLOSURE_IS_BSDF_BSSRDF(type))
      PLYMO_EVAL_diffuse = value;
    else if (CLOSURE_IS_BSDF_GLOSSY(type))
      PLYMO_EVAL_glossy = value;
    else if (CLOSURE_IS_BSDF_TRANSMISSION(type)){
      #ifdef PLYMO_EVAL_set_transmission
      PLYMO_EVAL_set_transmission(value);
      #else
      PLYMO_EVAL_transmission = value;
      #endif
    }
    
     /* 
    else if (CLOSURE_IS_PHASE(type))
      PLYMO.eval.volume = value;
    */
  }
  else
#endif
  {
    PLYMO_EVAL_diffuse = value;
  }
#ifdef _SHADOW_TRICKS_
  PLYMO_EVAL_sum_no_mis = make_float3(0.0f, 0.0f, 0.0f);
#endif

}
#endif

#if defined(PLYMO_EVAL_get_use_light_pass)

ccl_device_inline void PLYMO_bsdf_eval_accum(
                                       ClosureType type,
                                       float3 value,
                                       float mis_weight)
{
#ifdef _SHADOW_TRICKS_
  PLYMO_EVAL_sum_no_mis += value;
#endif
  value *= mis_weight;

#ifdef _PASSES_

  if (PLYMO_EVAL_get_use_light_pass !=0) {
    if (CLOSURE_IS_BSDF_DIFFUSE(type) || CLOSURE_IS_BSDF_BSSRDF(type))
      PLYMO_EVAL_diffuse += value;
    else if (CLOSURE_IS_BSDF_GLOSSY(type))
      PLYMO_EVAL_glossy += value;
    else if (CLOSURE_IS_BSDF_TRANSMISSION(type)){
      #ifdef PLYMO_EVAL_set_add3_transmission
       PLYMO_EVAL_set_add3_transmission(value);
      #else
       PLYMO_EVAL_transmission += value;
      #endif
    }
     

    /*  
    else if (CLOSURE_IS_PHASE(type))
      PLYMO.eval.volume += value;
    */  
    /* skipping transparent, this function is used by for eval(), will be zero then */
  }
  else
#endif
  {
    PLYMO_EVAL_diffuse += value;
  }

    

}



void PLYMO_bsdf_eval_mul3( float3 value)
{
#ifdef _SHADOW_TRICKS_
  PLYMO_EVAL_sum_no_mis *= value;
#endif
#ifdef _PASSES_
  if (PLYMO_EVAL_get_use_light_pass  !=0 ) {
    PLYMO_EVAL_diffuse *= value;
    PLYMO_EVAL_glossy *= value;
    #ifdef PLYMO_EVAL_set_mul3_transmission
    PLYMO_EVAL_set_mul3_transmission(value);
    #else
    PLYMO_EVAL_transmission *= value;
    #endif
    //PLYMO.eval.volume *= value;
    /* skipping transparent, this function is used by for eval(), will be zero then */
  }
  else
  PLYMO_EVAL_diffuse *= value;
#else
  PLYMO_EVAL_diffuse *= value;
#endif

};


void PLYMO_bsdf_eval_mis(float value)
{
#ifdef _PASSES_
  if (PLYMO_EVAL_get_use_light_pass !=0) {
    PLYMO_EVAL_diffuse *= value;
    PLYMO_EVAL_glossy *= value;
    #ifdef PLYMO_EVAL_set_mul_transmission
    PLYMO_EVAL_set_mul_transmission(value);
    #else
    PLYMO_EVAL_transmission *= value;
    #endif
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

#endif

#endif

bool PLYMO_bsdf_eval_is_zero()
{
#ifdef _PASSES_
  if (PLYMO_EVAL_get_use_light_pass !=0) {
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
  if (PLYMO_EVAL_get_use_light_pass !=0) {
    return PLYMO_EVAL_diffuse + PLYMO_EVAL_glossy + PLYMO_EVAL_transmission;// + PLYMO_EVAL_volume;
  }
  else
#endif
    return PLYMO_EVAL_diffuse;
}








#endif