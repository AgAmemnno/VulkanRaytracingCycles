#version 460
#extension GL_NV_ray_tracing : require
struct PathRadianceState
{
vec4 diffuse;
vec4 glossy;
vec4 transmission;
vec4 volume;
vec4 direct;
};
struct PathRadiance
{
int use_light_pass;
float transparent;
vec4 emission;
vec4 background;
vec4 ao;
vec4 indirect;
vec4 direct_emission;
vec4 color_diffuse;
vec4 color_glossy;
vec4 color_transmission;
vec4 direct_diffuse;
vec4 direct_glossy;
vec4 direct_transmission;
vec4 direct_volume;
vec4 indirect_diffuse;
vec4 indirect_glossy;
vec4 indirect_transmission;
vec4 indirect_volume;
vec4 shadow;
float mist;
PathRadianceState state;
vec4 path_total;
vec4 path_total_shaded;
vec4 shadow_background_color;
float shadow_throughput;
float shadow_transparency;
int has_shadow_catcher;
};
struct PathState
{
int flag;
uint rng_hash;
int rng_offset;
int sample_rsv;
int num_samples;
float branch_factor;
int bounce;
int diffuse_bounce;
int glossy_bounce;
int transmission_bounce;
int transparent_bounce;
float min_ray_pdf;
float ray_pdf;
float ray_t;
};
struct differential3
{
vec4 dx;
vec4 dy;
};
struct differential
{
float dx;
float dy;
};
struct ShaderDataTinyStorage
{
vec4 P;
vec4 N;
vec4 Ng;
vec4 I;
int shader;
int flag;
int object_flag;
int prim;
int type;
float u;
float v;
int object;
int lamp;
float time;
float ray_length;
differential3 dP;
differential3 dI;
differential du;
differential dv;
vec4 dPdu;
vec4 dPdv;
vec4 ray_P;
differential3 ray_dP;
uint lcg_state;
int num_closure;
int num_closure_left;
float randb_closure;
vec4 svm_closure_weight;
vec4 closure_emission_background;
vec4 closure_transparent_extinction;
};
ccl_addr_space struct ShaderData
{
  /* position */
  float3 P;
  /* smooth normal for shading */
  float3 N;
  /* true geometric normal */
  float3 Ng;
  /* view/incoming direction */
  float3 I;
  /* shader id */
  int shader;
  /* booleans describing shader, see ShaderDataFlag */
  int flag;
  /* booleans describing object of the shader, see ShaderDataObjectFlag */
  int object_flag;

  /* primitive id if there is one, ~0 otherwise */
  int prim;

  /* combined type and curve segment for hair */
  int type;

  /* parametric coordinates
   * - barycentric weights for triangles */
  float u;
  float v;
  /* object id if there is one, ~0 otherwise */
  int object;
  /* lamp id if there is one, ~0 otherwise */
  int lamp;

  /* motion blur sample time */
  float time;

  /* length of the ray being shaded */
  float ray_length;

#ifdef _RAY_DIFFERENTIALS_
  /* differential of P. these are orthogonal to Ng, not N */
  differential3 dP;
  /* differential of I */
  differential3 dI;
  /* differential of u, v */
  differential du;
  differential dv;
#endif
#ifdef _DPDU_
  /* differential of P w.r.t. parametric coordinates. note that dPdu is
   * not readily suitable as a tangent for shading on triangles. */
  float3 dPdu;
  float3 dPdv;
#endif

#ifdef _OBJECT_MOTION_
  /* object <-> world space transformations, cached to avoid
   * re-interpolating them constantly for shading */
  Transform ob_tfm;
  Transform ob_itfm;
#endif

  /* ray start position, only set for backgrounds */
  float3 ray_P;
  differential3 ray_dP;

#ifdef _OSL_ 
 KernelGlobals *osl_globals;
  struct PathState *osl_path_state;
#endif

  /* LCG state for closures that require additional random numbers. */
  uint lcg_state;

  /* Closure data, we store a fixed array of closures */
  int num_closure;
  int num_closure_left;
  float randb_closure;
  float3 svm_closure_weight;

  /* Closure weights summed directly, so we can evaluate
   * emission and shadow transparency with MAX_CLOSURE 0. */
  float3 closure_emission_background;
  float3 closure_transparent_extinction;

  /* At the end so we can adjust size in ShaderDataTinyStorage. */
  //ShaderClosure closure[MAX_CLOSURE];
  int      atomic_offset;
  int      alloc_offset;


};

struct hitPayload_
{
vec4 throughput;
PathRadiance L;
PathState state;
ShaderData            sd;
ShaderDataTinyStorage emission_sd;
};


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
float    lamp;        
float light_u;
float light_v;          // 3
args_ShaderData sd;     // 33 = 30 + 3
args_PathState  state;  // 40 = 7 + 33 
float pad[88];
};



layout(location = 0) rayPayloadInNV hitPayload_ prd;
layout(location = 0) callableDataNV hitPayload0 emi;


#define set_args_PathState(lamp,lu,lv){\
emi.esd  = prd.esd;\
emi.lamp = lamp;emi.light_u = lu;emi.light_v = lv;\
emi.sd.P =  prd.esd.P;\
emi.sd.N =  prd.esd.N;\
emi.sd.Ng=  prd.esd.Ng;\
emi.sd.I=  prd.esd.I;\
emi.sd.flag=  prd.esd.flag;\
emi.sd.type=  prd.esd.type;\
emi.sd.object=  prd.esd.object;\
emi.sd.time=  prd.esd.time;\
emi.sd.dP=  prd.esd.dP;\
emi.sd.lcg_state=  prd.esd.lcg_state;\
emi.sd.num_closure=  prd.esd.num_closure;\
emi.state.flag = prd.state.flag;\
emi.state.rng_hash= prd.state.rng_hash;\
emi.state.rng_offset= prd.state.rng_offset;\
emi.state.sample_rsv= prd.state.sample_rsv;\
emi.state.num_samples= prd.state.num_samples;\
emi.state.branch_factor= prd.state.branch_factor;\
emi.state.bounce= prd.state.bounce;
}





void main()
{

set_args_PathState(-1,0.5,0.5);

executeCallableNV(0, 0);


executeCallableNV(1, 0);


emi.pad[60] = 1.23f;
executeCallableNV(2, 0);

prd.throughput = vec4( 0.,0.,0.,1.);
if(emi.sd.P == vec4(201.23f) ){
     
    prd.throughput = vec4( 1.,0.,0.,1.);
}
}
