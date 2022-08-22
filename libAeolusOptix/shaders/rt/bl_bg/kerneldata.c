int64_t pad;
_tri_vindex
int64_t pad2[4];
_objects
int64_t pad3[2];
_patches
_attributes_map
_attributes_float
_attributes_float2
_attributes_float3
_attributes_uchar4
int64_t pad4[3];
_tri_patch
_tri_patch_uv
int64_t pad5;
    _lights_ _lights;


[L_sum]
    
__PASSES__
{
 ///  val = val1 + val2 +  state.val*( (emi + indir) / dir);

  0 : ["L_direct" , "L_indirect"],

   // val1 = dif + glo + tra + vol + emi + bac
   // state.val = st_dif + st_glo + st_tra + st_vol 
    "L_direct"  :  [
      "L->direct_diffuse" ,"L->direct_glossy", 
      "L->direct_transmission","L->direct_volume",
      "L->emission","L->background"],
   /// val1 = val1 +  state.val*(emi / dir);
    "L->direct_volume" : [
              "L->state.volume",
              "L->direct_emission",
              "L->state.direct"
    ],
    "L->direct_transmission" : [
              "L->state.transmission",
              "L->direct_emission",
              "L->state.direct"
    ],
    "L->direct_glossy" : [
              "L->state.glossy",
              "L->direct_emission",
              "L->state.direct"
    ],
    "L->direct_diffuse" : [
              "L->state.diffuse",
              "L->direct_emission",
              "L->state.direct"
    ],
     
    "L_indirect" :[
      "L->indirect_diffuse" ,
      "L->indirect_glossy",
      "L->indirect_transmission",
      "L->indirect_volume"
    ],
    // val2 = in_dif + in_glo + in_tra + in_vol 
    /// val2 = val2 +  state.val*(indir / dir);
    "L->indirect_volume" : [
              "L->state.volume",
              "L->indirect"
              "L->state.direct"
    ],
    "L->indirect_transmission" : [
              "L->state.tarnsmission",
              "L->indirect"
              "L->state.direct"
    ],
    "L->indirect_glossy" : [
              "L->state.glossy",
              "L->indirect"
              "L->state.direct"
    ],
    "L->indirect_diffuse" : [
              "L->state.diffuse",
              "L->indirect"
              "L->state.direct"
    ],

  1 :  ["L->state.direct" ,"L->state.diffuse" ,"L->state.glossy","L->state.transmission","L->state.volume"]
     //path_radiance_bsdf_bounce
    "L_state->direct" : [
        "L_state->diffuse", "L_state->glossy" ,"L_state->transmission" ,"L_state->volume"
    ],
     "L_state->diffuse" :
     [
       "eval->diffuse", "throughput" ,"LOC_bsdf_pdf"
     ],
     "L_state->glossy" :
     [
       "eval->glossy", "throughput" ,"LOC_bsdf_pdf"
     ],
     "L_state->trransmission" :
     [
      "eval->transmission", "throughput" ,"LOC_bsdf_pdf"
     ],
    "L_state->volume" :
     [
       "eval->volume", "throughput" ,"LOC_bsdf_pdf"
     ],
    //bsdf_eval_accum
    //_shader_bsdf_multi_eval
    // bsdf_eval
    "eval->diffuse":[
        "LOC_eval" , "sc->weight"
    ]
       "LOC_eval" :[
           "BSDF_EVAL_RESULT"
       ]
    
    //shader_bsdf_sample
    //bsdf_sample
    "LOC_bsdf_pdf":
    [
      "LOC_sum_pdf" , "LOC_sum_sample_weight"
    ]

      "LOC_sum_pdf" :
      [
       "sc->sample_weight","LOC_LOC_bsdf_pdf",
      ],
        "LOC_LOC_bsdf_pdf":
            [
      "FUNC_reflect" :["sc->N","omega_in"]
      "FUNC_transmit":["sc->N","sd.I","sd->Ng","sd->N","omega_in","scARGS"]
           ]

      "LOC_sum_sample_weight":
      [ 
        "sc->sample_weight"
      ]

  2 : ["L->emission","L->direct_diffuse"],
     //path_radiance_accum_light not use_light_pass
     //path_radiance_accum_ao

     "L->emission" : 
     {

     "path_radiance_accum_emission" : //    same as L->direct_emission  L->direct_emission  L->indirect
     {
       "throughput" :{},
       "LOC_value" :{
          "indirect_lamp_emission" :
          [
            "state->ray_pdf", "ls.pdf", {
                                          "direct_emissive_eval" : 
                                               []
                                          }
          ],
          "kernel_path_shader_apply" :
          [
           {
             "indirect_primitive_emission" : 
           [
             "sd->ray_length", "state->flag", "state->ray_pdf",
           ]
           }
          ]
       }
     },
     //no use_light_pass
     "path_radiance_accum_background"://   same as L->indirect  L->direct_emission L->path_total  L->path_total_shaded  L->background
     [
       "throughput",
       "LOC_value"
     ],
     "path_radiance_accum_sample" ://   same as all
     [
       "SPLIT_state_buffer"
     ]
     
     
     }

    //path_radiance_accum_ao
    //path_radiance_sum_indirect
    //path_radiance_accum_sample

    //path_radiance_accum_light
    "L->direct_diffuse" :[
       "throughput",
       "LOC_shadow"
       "bsdf_eval->diffuse"
    ],

      "LOC_shadow": 
      [

      ]





}

__NO_PASSES__
{
  0 : "L->emission",

}


[alpha]
{
  0: "1.0f - L->transparent"
}



__SHADOW_TRICKS__






[Shadowcather]
  sd.closure_transparent_extinction;
[shader_bsdf_blur]
  arg.state.min_ray_pdf



SHADERS
__shaders ::  flags  65536 cryptomatte_id 33803906242069300736194377754345472.00000  pass_id 0
__shaders ::  constant_emission 0.00000 0.00000 0.00000

__shaders ::  flags  589824 cryptomatte_id -0.00000  pass_id 0
__shaders ::  constant_emission 0.00000 0.00000 0.00000

__shaders ::  flags  65536 cryptomatte_id -55370101003753702322630160292205559808.00000  pass_id 0
__shaders ::  constant_emission 0.00000 0.00000 0.00000

__shaders ::  flags  134283264 cryptomatte_id -94532754170970112.00000  pass_id 0
__shaders ::  constant_emission 0.05088 0.05088 0.05088

__shaders ::  flags  65536 cryptomatte_id -0.00000  pass_id 0
__shaders ::  constant_emission 0.00000 0.00000 0.00000

__shaders ::  flags  134283264 cryptomatte_id -0.00000  pass_id 0
__shaders ::  constant_emission 1.00000 1.00000 1.00000

__shaders ::  flags  65536 cryptomatte_id 223676571016232960.00000  pass_id 0
__shaders ::  constant_emission 0.00000 0.00000 0.00000

TRI_SHADER

[0] {    1610612742 }
[1] {    1610612742 }
[2] {    1610612742 }
[3] {    1610612742 }
[4] {    1610612742 }
[5] {    1610612742 }
[6] {    1610612742 }
[7] {    1610612742 }
[8] {    1610612742 }
[9] {    1610612742 }
[10] {    1610612742 }
[11] {    1610612742 }
[12] {    1610612742 }
[13] {    1610612742 }
[14] {    1610612742 }
[15] {    1610612742 }
[16] {    1610612742 }
[17] {    1610612742 }
[18] {    1610612742 }
[19] {    1610612742 }
[20] {    1610612742 }
[21] {    1610612742 }
[22] {    1610612742 }
[23] {    1610612742 }
[24] {    1610612742 }
[25] {    1610612742 }
[26] {    1610612742 }
[27] {    1610612742 }
[28] {    1610612742 }
[29] {    1610612742 }
[30] {    1610612742 }
[31] {    1610612742 }
[32] {    1610612742 }
[33] {    1610612742 }
[34] {    1610612742 }
[35] {    1610612742 }
[36] {    1610612742 }
[37] {    1610612742 }
[38] {    1610612742 }
[39] {    1610612742 }
[40] {    1610612742 }
[41] {    1610612742 }
[42] {    1610612742 }
[43] {    1610612742 }
[44] {    1610612742 }
[45] {    1610612742 }
[46] {    1610612742 }
[47] {    1610612742 }
[48] {    1610612742 }
[49] {    1610612742 }
[50] {    1610612742 }
[51] {    1610612742 }
[52] {    1610612742 }
[53] {    1610612742 }
[54] {    1610612742 }
[55] {    1610612742 }
[56] {    1610612742 }
[57] {    1610612742 }
[58] {    1610612742 }
[59] {    1610612742 }
[60] {    1610612742 }
[61] {    1610612742 }
[62] {    1610612742 }
[63] {    1610612742 }
[64] {    1610612742 }
[65] {    1610612742 }
[66] {    1610612742 }
[67] {    1610612742 }
[68] {    1610612742 }
[69] {    1610612742 }
[70] {    1610612742 }
[71] {    1610612742 }
[72] {    1610612742 }
[73] {    1610612742 }
[74] {    1610612742 }
[75] {    1610612742 }
[76] {    1610612742 }
[77] {    1610612742 }
[78] {    1610612742 }
[79] {    1610612742 }
[80] {    1610612742 }
[81] {    1610612742 }
[82] {    1610612742 }
[83] {    1610612742 }
[84] {    1610612742 }
[85] {    1610612742 }
[86] {    1610612742 }
[87] {    1610612742 }
[88] {    1610612742 }
[89] {    1610612742 }
[90] {    1610612742 }
[91] {    1610612742 }
[92] {    1610612742 }
[93] {    1610612742 }
[94] {    1610612742 }
[95] {    1610612742 }
[96] {    1610612742 }
[97] {    1610612742 }
[98] {    1610612742 }
[99] {    1610612742 }
[100] {    1610612742 }
[101] {    1610612742 }
[102] {    1610612742 }
[103] {    1610612742 }
[104] {    1610612742 }
[105] {    1610612742 }
[106] {    1610612742 }
[107] {    1610612742 }
[108] {    1610612742 }
[109] {    1610612742 }
[110] {    1610612742 }
[111] {    1610612742 }
[112] {    1610612742 }
[113] {    1610612742 }
[114] {    1610612742 }
[115] {    1610612742 }
[116] {    1610612742 }
[117] {    1610612742 }
[118] {    1610612742 }
[119] {    1610612742 }
[120] {    1610612742 }
[121] {    1610612742 }
[122] {    1610612742 }
[123] {    1610612742 }
[124] {    1610612742 }
[125] {    1610612742 }
[126] {    1610612742 }
[127] {    1610612742 }
[128] {    1610612742 }
[129] {    1610612742 }
[130] {    1610612742 }
[131] {    1610612742 }
[132] {    1610612742 }
[133] {    1610612742 }
[134] {    1610612742 }
[135] {    1610612742 }
[136] {    1610612742 }
[137] {    1610612742 }
[138] {    1610612742 }
[139] {    1610612742 }
[140] {    1610612742 }
[141] {    1610612742 }
[142] {    1610612742 }
[143] {    1610612742 }
[144] {    1610612742 }
[145] {    1610612742 }
[146] {    1610612742 }
[147] {    1610612742 }
[148] {    1610612742 }
[149] {    1610612742 }
[150] {    1610612742 }
[151] {    1610612742 }
[152] {    1610612742 }
[153] {    1610612742 }
........

SVM_NODES
[0] {    1  7  13  14 }
[1] {    1  15  16  17 }
[2] {    1  18  19  20 }
[3] {    1  21  24  25 }
[4] {    1  26  27  28 }
[5] {    1  29  32  33 }
[6] {    1  34  40  41 }
[7] {    11  1  0  0 }
[8] {    5  1061997773  1061997773  1061997773 }
[9] {    14  0  3  0 }
[10] {    2  -64766  0  0 }
[11] {    0  255  255  255 }
[12] {    0  0  0  0 }
[13] {    0  0  0  0 }
[14] {    0  0  0  0 }
[15] {    0  0  0  0 }
[16] {    0  0  0  0 }
[17] {    0  0  0  0 }
[18] {    0  0  0  0 }
[19] {    0  0  0  0 }
[20] {    0  0  0  0 }
[21] {    5  1028678514  1028678514  1028678514 }
[22] {    4  255  0  0 }
[23] {    0  0  0  0 }
[24] {    0  0  0  0 }
[25] {    0  0  0  0 }
[26] {    0  0  0  0 }
[27] {    0  0  0  0 }
[28] {    0  0  0  0 }
[29] {    5  1065353216  1065353216  1065353216 }
[30] {    3  255  0  0 }
[31] {    0  0  0  0 }
[32] {    0  0  0  0 }
[33] {    0  0  0  0 }
[34] {    11  1  0  0 }
[35] {    5  1061997774  1051630956  1026854240 }
[36] {    14  1059158552  3  0 }
[37] {    2  -64766  1059158552  0 }
[38] {    0  255  255  255 }
[39] {    0  0  0  0 }
[40] {    0  0  0  0 }
[41] {    0  0  0  0 }

__lights_Distribution ::  totarea  0.00000
 lamp type prim 0  size 0.10000
__lights_Distribution ::  totarea  1.00000
 mesh light  type 0  objectid 0  shaderflag 0



__lights ::
 co 4.07625,1.00545,5.90386
  shader_id  1342177285 samples 1 max_bounces 1024.00000 random 0.09012
strength 1000.00000,1000.00000,1000.00000
  light.tfm ::
  light.tfm.x  [ -0.29086 ,-0.77110 ,0.56639 ,4.07625 ]
 light.tfm.y  [ 0.95517 ,-0.19988 ,0.21839 ,1.00545 ]
 light.tfm.z  [ -0.05519 ,0.60452 ,0.79467 ,5.90386 ]
 light.itfm ::
  light.itfm.x  [ -0.29086 ,0.95517 ,-0.05519 ,0.55108 ]
 light.itfm.y  [ -0.77110 ,-0.19988 ,0.60452 ,-0.22486 ]
 light.itfm.z  [ 0.56639 ,0.21839 ,0.79467 ,-7.21998 ]

 TYPE SPOT  or POINT 0
 radius 0.10000; invarea  31.83099;  spot_angle -431602080.00000;  spot_smooth -431602080.00000;
 dir  -431602080.00000,-431602080.00000,-431602080.00000
 




struct args_sd{
float3 P;
float3 N; 
float3 Ng;
float3 I;
int flag;
int type;
int object;

int        num_closure;
int      atomic_offset;

float             time; 
float       ray_length;

int       alloc_offset;
float            pad[3];
differential3       dI;

};

struct differential3
{
vec4 dx;
vec4 dy;
};
 struct differential {
  float dx;
  float dy;
} ;

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
  int shader;   //flag
  /* booleans describing shader, see ShaderDataFlag */
  int flag;    //type
  /* booleans describing object of the shader, see ShaderDataObjectFlag */
  int object_flag;  //object

  /* primitive id if there is one, ~0 otherwise */
  int prim;  //num_closure

  /* combined type and curve segment for hair */
  int type;  //atomic_offset

  /* parametric coordinates
   * - barycentric weights for triangles */
  float u;   //time
  float v;   //ray_length
  /* object id if there is one, ~0 otherwise */
  int object; //alloc_offset
  /* lamp id if there is one, ~0 otherwise */
  int lamp;   //pad[0]

  /* motion blur sample time */
  float time; //pad[1]

  /* length of the ray being shaded */
  float ray_length; //pad[2]

#ifdef _RAY_DIFFERENTIALS_
  /* differential of P. these are orthogonal to Ng, not N */
  differential3 dP;      //dI
  /* differential of I */
  differential3 dI;      // diffuse glossy
  /* differential of u, v */ // 
  differential du;   //transmission.xy
  differential dv;    //transmission.zw 
#endif
#ifdef _DPDU_
  /* differential of P w.r.t. parametric coordinates. note that dPdu is
   * not readily suitable as a tangent for shading on triangles. */
  float3 dPdu;       // transparent
  float3 dPdv;        //sum_no_mis     
#endif

#ifdef _OBJECT_MOTION_
  /* object <-> world space transformations, cached to avoid
   * re-interpolating them constantly for shading */
  Transform ob_tfm;
  Transform ob_itfm;
#endif

  /* ray start position, only set for backgrounds */
  float3 ray_P;           //omega_in      
  differential3 ray_dP;     //domega_in

#ifdef _OSL_ 
  KernelGlobals *osl_globals;
  struct PathState *osl_path_state;
#endif

  /* LCG state for closures that require additional random numbers. */
  uint lcg_state;          // label,

  /* Closure data, we store a fixed array of closures */
  int num_closure;         //use_light_pass 
  int num_closure_left;    //pad
  float randb_closure;     //pdf
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

///   4*(4*4 + 11 + 4*2*2 + 2*2  + 4*3 + 4*2 + 4 + 4*3 + 2 )    340




struct BsdfEval {
#ifdef _PASSES_
  int use_light_pass;
#endif

  float3 diffuse;
#ifdef _PASSES_
  float3 glossy;
  float3 transmission;
  float3 transparent;

#ifdef _VOLUME_  
  float3 volume;
#endif

#endif
#ifdef _SHADOW_TRICKS_
  float3 sum_no_mis;
#endif
} ;


struct args_acc_light{
  int use_light_pass;
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 path_total;
  vec4 throughput;
};
 
 struct Ray {
/* TODO(sergey): This is only needed because current AMD
 * compiler has hard time building the kernel with this
 * reshuffle. And at the same time reshuffle will cause
 * less optimal CPU code in certain places.
 *
 * We'll get rid of this nasty exception once AMD compiler
 * is fixed.
 */
/*
#ifndef _KERNEL_OPENCL_AMD_
  float3 P;   
  float3 D;   
  float t;    
  float time; 
#else
*/
  float t;    // length of the ray             pdf 
  float time; // time (for motion blur)        type
  float3 P;   // origin                        omega_in
  float3 D;   // direction                     domega_in.x
//#endif

#ifdef _RAY_DIFFERENTIALS_
  differential3 dP;                           //domega_in.y  
  differential3 dD;
#endif
} ;

 struct PathRadiance { 
#ifdef _PASSES_
  int use_light_pass;
#endif

  float transparent;
  float3 emission;
#ifdef _PASSES_
  float3 background;
  float3 ao;

  float3 indirect;
  float3 direct_emission;

  float3 color_diffuse;
  float3 color_glossy;
  float3 color_transmission;

  float3 direct_diffuse;       ray.dP.dx
  float3 direct_glossy;        ray.dP.dy
  float3 direct_transmission;  ray.dD.dx
  float3 direct_volume;        ray.dD.dy

  float3 indirect_diffuse;         
  float3 indirect_glossy;          
  float3 indirect_transmission;   
  float3 indirect_volume;         

  float4 shadow;
  float mist;                  ray.time
#endif 
 PathRadianceState state;

#ifdef _SHADOW_TRICKS_
  /* Total light reachable across the path, ignoring shadow blocked queries. */
  float3 path_total;
  /* Total light reachable across the path with shadow blocked queries
   * applied here.
   *
   * Dividing this figure by path_total will give estimate of shadow pass.
   */
  float3 path_total_shaded;

  /* Color of the background on which shadow is alpha-overed. */
  float3 shadow_background_color;

  /* Path radiance sum and throughput at the moment when ray hits shadow
   * catcher object.
   */
  float shadow_throughput;

  /* Accumulated transparency along the path after shadow catcher bounce. */
  float shadow_transparency;

  /* Indicate if any shadow catcher data is set. */
  int has_shadow_catcher;
#endif

#ifdef _DENOISING_FEATURES_
  float3 denoising_normal;
  float3 denoising_albedo;
  float denoising_depth;
#endif /* _DENOISING_FEATURES_ */

#ifdef _KERNEL_DEBUG_
  DebugData debug_data;
#endif /* _KERNEL_DEBUG_ */
 }_PathRadiance;



 //Bsdf_eval <plymo> 
struct args_acc_light{
  //int use_light_pass;
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 path_total;
  vec4 throughput;
};

struct args_sd{

float3 P;
float3 N; 
float3 Ng;
float3 I;
int flag;
int type;
int object;
int        num_closure;
int      atomic_offset;
float             time; 
float       ray_length;
int       alloc_offset;
float            pad[3];
differential3       dI;

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

struct PLMO_SD
{
ShaderData sd;   //340
};
struct PLMO_SD_EVAL
{
args_sd    sd;   // 140
BsdfEval eval;   // 80
int use_light_pass;
int label;
float pdf;
float   type;
vec4 omega_in;    
differential3 domega_in; 
}
// 140 + 80 + 52 = 272

#define PLYMO_L2Eval_label arg.type
#define PLYMO_L2Eval_pdf  arg.ray.t
#define PLYMO_L2Eval_type  arg.ray.time
#define PLYMO_L2Eval_omega_in  arg.ray.P
#define PLYMO_L2Eval_domega_in_dx  arg.ray.D
#define PLYMO_L2Eval_domega_in_dy  arg.ray.dP.dx

layout(location = 0) callableDataInNV PRG2ARG pay;
layout(location = 1) callableDataNV   PLMO_SD plymo;


 Submit RT   execution Critical    time    4.97720    milli second      result   0   Sleeping  3 second....
  atomic Counter[1023]    val  301     uval   301
 atomic Counter[1022]    val  317     uval   317
 atomic Counter[1021]    val  288     uval   288
 atomic Counter[1020]    val  9     uval   9
 atomic Counter[1019]    val  296     uval   296
 atomic Counter[1018]    val  14     uval   14
 atomic Counter[1017]    val  11     uval   11
 atomic Counter[1016]    val  24     uval   24
 atomic Counter[1015]    val  16     uval   16
 atomic Counter[1014]    val  291     uval   291
 atomic Counter[1013]    val  3     uval   3
 atomic Counter[1012]    val  292     uval   292
 atomic Counter[1011]    val  290     uval   290
 atomic Counter[1010]    val  316     uval   316
 atomic Counter[1009]    val  12     uval   12
 atomic Counter[1008]    val  7     uval   7
 atomic Counter[1007]    val  33     uval   33
 atomic Counter[1006]    val  8     uval   8
 atomic Counter[1005]    val  297     uval   297
 atomic Counter[1004]    val  32     uval   32
 atomic Counter[1003]    val  22     uval   22
 atomic Counter[1002]    val  319     uval   319
 atomic Counter[1001]    val  20     uval   20
 atomic Counter[1000]    val  0     uval   0
 atomic Counter[999]    val  298     uval   298
 atomic Counter[998]    val  1     uval   1
 atomic Counter[997]    val  31     uval   31
 atomic Counter[996]    val  307     uval   307
 atomic Counter[995]    val  2     uval   2
 atomic Counter[994]    val  5     uval   5
 atomic Counter[993]    val  312     uval   312
 atomic Counter[992]    val  15     uval   15
 atomic Counter[991]    val  308     uval   308
 atomic Counter[990]    val  299     uval   299
 atomic Counter[989]    val  37     uval   37
 atomic Counter[988]    val  21     uval   21
 atomic Counter[987]    val  4     uval   4
 atomic Counter[986]    val  306     uval   306
 atomic Counter[985]    val  6     uval   6
 atomic Counter[984]    val  10     uval   10
 atomic Counter[983]    val  25     uval   25
 atomic Counter[982]    val  44     uval   44
 atomic Counter[981]    val  36     uval   36
 atomic Counter[980]    val  38     uval   38
 atomic Counter[979]    val  34     uval   34
 atomic Counter[978]    val  35     uval   35
 atomic Counter[977]    val  17     uval   17
 atomic Counter[976]    val  23     uval   23
 atomic Counter[975]    val  289     uval   289
 atomic Counter[974]    val  29     uval   29
 atomic Counter[973]    val  30     uval   30
 atomic Counter[972]    val  19     uval   19
 atomic Counter[971]    val  18     uval   18
 atomic Counter[970]    val  13     uval   13
 atomic Counter[969]    val  27     uval   27
 atomic Counter[968]    val  28     uval   28
 atomic Counter[967]    val  26     uval   26
 atomic Counter[966]    val  311     uval   311
 atomic Counter[965]    val  293     uval   293
 atomic Counter[964]    val  304     uval   304
 atomic Counter[963]    val  277     uval   277
 atomic Counter[962]    val  309     uval   309
 atomic Counter[961]    val  313     uval   313
 atomic Counter[960]    val  283     uval   283
 atomic Counter[959]    val  273     uval   273
 atomic Counter[958]    val  262     uval   262
 atomic Counter[957]    val  39     uval   39
 atomic Counter[956]    val  108     uval   108
 atomic Counter[955]    val  42     uval   42
 atomic Counter[954]    val  132     uval   132
 atomic Counter[953]    val  139     uval   139
 atomic Counter[952]    val  135     uval   135
 atomic Counter[951]    val  74     uval   74
 atomic Counter[950]    val  78     uval   78
 atomic Counter[949]    val  73     uval   73
 atomic Counter[948]    val  98     uval   98
 atomic Counter[947]    val  43     uval   43
 atomic Counter[946]    val  130     uval   130
 atomic Counter[945]    val  59     uval   59
 atomic Counter[944]    val  95     uval   95
 atomic Counter[943]    val  41     uval   41
 atomic Counter[942]    val  45     uval   45
 atomic Counter[941]    val  96     uval   96
 atomic Counter[940]    val  123     uval   123
 atomic Counter[939]    val  102     uval   102
 atomic Counter[938]    val  53     uval   53
 atomic Counter[937]    val  83     uval   83
 atomic Counter[936]    val  50     uval   50
 atomic Counter[935]    val  93     uval   93
 atomic Counter[934]    val  92     uval   92
 atomic Counter[933]    val  58     uval   58
 atomic Counter[932]    val  75     uval   75
 atomic Counter[931]    val  72     uval   72
 atomic Counter[930]    val  71     uval   71
 atomic Counter[929]    val  65     uval   65
 atomic Counter[928]    val  46     uval   46
 atomic Counter[927]    val  107     uval   107
 atomic Counter[926]    val  111     uval   111
 atomic Counter[925]    val  109     uval   109
 atomic Counter[924]    val  47     uval   47
 atomic Counter[923]    val  82     uval   82
 atomic Counter[922]    val  40     uval   40
 atomic Counter[921]    val  79     uval   79
 atomic Counter[920]    val  84     uval   84
 atomic Counter[919]    val  61     uval   61
 atomic Counter[918]    val  87     uval   87
 atomic Counter[917]    val  89     uval   89
 atomic Counter[916]    val  76     uval   76
 atomic Counter[915]    val  97     uval   97
 atomic Counter[914]    val  80     uval   80
 atomic Counter[913]    val  85     uval   85
 atomic Counter[912]    val  88     uval   88
 atomic Counter[911]    val  91     uval   91
 atomic Counter[910]    val  86     uval   86
 atomic Counter[909]    val  90     uval   90
 atomic Counter[908]    val  121     uval   121
 atomic Counter[907]    val  94     uval   94
 atomic Counter[906]    val  134     uval   134
 atomic Counter[905]    val  103     uval   103
 atomic Counter[904]    val  122     uval   122
 atomic Counter[903]    val  126     uval   126
 atomic Counter[902]    val  119     uval   119
 atomic Counter[901]    val  100     uval   100
 atomic Counter[900]    val  115     uval   115
 atomic Counter[899]    val  105     uval   105
 atomic Counter[898]    val  101     uval   101
 atomic Counter[897]    val  114     uval   114
 atomic Counter[896]    val  118     uval   118
 atomic Counter[895]    val  110     uval   110
 atomic Counter[894]    val  106     uval   106
 atomic Counter[893]    val  116     uval   116
 atomic Counter[892]    val  128     uval   128
 atomic Counter[891]    val  104     uval   104
 atomic Counter[890]    val  120     uval   120
 atomic Counter[889]    val  99     uval   99
 atomic Counter[888]    val  137     uval   137
 atomic Counter[887]    val  127     uval   127
 atomic Counter[886]    val  125     uval   125
 atomic Counter[885]    val  117     uval   117
 atomic Counter[884]    val  144     uval   144
 atomic Counter[883]    val  143     uval   143
 atomic Counter[882]    val  133     uval   133
 atomic Counter[881]    val  136     uval   136
 atomic Counter[880]    val  129     uval   129
 atomic Counter[879]    val  124     uval   124
 atomic Counter[878]    val  138     uval   138
 atomic Counter[877]    val  142     uval   142
 atomic Counter[876]    val  145     uval   145
 atomic Counter[875]    val  141     uval   141
 atomic Counter[874]    val  140     uval   140
 atomic Counter[873]    val  131     uval   131
 atomic Counter[872]    val  151     uval   151
 atomic Counter[871]    val  150     uval   150
 atomic Counter[870]    val  148     uval   148
 atomic Counter[869]    val  146     uval   146
 atomic Counter[868]    val  152     uval   152
 atomic Counter[867]    val  62     uval   62
 atomic Counter[866]    val  153     uval   153
 atomic Counter[865]    val  158     uval   158
 atomic Counter[864]    val  70     uval   70
 atomic Counter[863]    val  157     uval   157
 atomic Counter[862]    val  156     uval   156
 atomic Counter[861]    val  161     uval   161
 atomic Counter[860]    val  155     uval   155
 atomic Counter[859]    val  159     uval   159
 atomic Counter[858]    val  157     uval   157
 atomic Counter[857]    val  154     uval   154
 atomic Counter[856]    val  156     uval   156
 atomic Counter[855]    val  168     uval   168
 atomic Counter[854]    val  169     uval   169
 atomic Counter[853]    val  155     uval   155
 atomic Counter[852]    val  160     uval   160
 atomic Counter[851]    val  161     uval   161
 atomic Counter[850]    val  165     uval   165
 atomic Counter[849]    val  150     uval   150
 atomic Counter[848]    val  171     uval   171
 atomic Counter[847]    val  173     uval   173
 atomic Counter[846]    val  164     uval   164
 atomic Counter[845]    val  177     uval   177
 atomic Counter[844]    val  162     uval   162
 atomic Counter[843]    val  166     uval   166
 atomic Counter[842]    val  175     uval   175
 atomic Counter[841]    val  179     uval   179
 atomic Counter[840]    val  184     uval   184
 atomic Counter[839]    val  176     uval   176
 atomic Counter[838]    val  180     uval   180
 atomic Counter[837]    val  183     uval   183
 atomic Counter[836]    val  170     uval   170
 atomic Counter[835]    val  174     uval   174
 atomic Counter[834]    val  181     uval   181
 atomic Counter[833]    val  186     uval   186
 atomic Counter[832]    val  182     uval   182
 atomic Counter[831]    val  122     uval   122
 atomic Counter[830]    val  97     uval   97
 atomic Counter[829]    val  115     uval   115
 atomic Counter[828]    val  192     uval   192
 atomic Counter[827]    val  106     uval   106
 atomic Counter[826]    val  134     uval   134
 atomic Counter[825]    val  100     uval   100
 atomic Counter[824]    val  164     uval   164
 atomic Counter[823]    val  162     uval   162
 atomic Counter[822]    val  167     uval   167
 atomic Counter[821]    val  135     uval   135
 atomic Counter[820]    val  201     uval   201
 atomic Counter[819]    val  202     uval   202
 atomic Counter[818]    val  194     uval   194
 atomic Counter[817]    val  197     uval   197
 atomic Counter[816]    val  193     uval   193
 atomic Counter[815]    val  160     uval   160
 atomic Counter[814]    val  195     uval   195
 atomic Counter[813]    val  163     uval   163
 atomic Counter[812]    val  204     uval   204
 atomic Counter[811]    val  112     uval   112
 atomic Counter[810]    val  203     uval   203
 atomic Counter[809]    val  172     uval   172
 atomic Counter[808]    val  199     uval   199
 atomic Counter[807]    val  178     uval   178
 atomic Counter[806]    val  113     uval   113
 atomic Counter[805]    val  200     uval   200
 atomic Counter[804]    val  147     uval   147
 atomic Counter[803]    val  198     uval   198
 atomic Counter[802]    val  191     uval   191
 atomic Counter[801]    val  189     uval   189
 atomic Counter[800]    val  187     uval   187
 atomic Counter[799]    val  185     uval   185
 atomic Counter[798]    val  217     uval   217
 atomic Counter[797]    val  218     uval   218
 atomic Counter[796]    val  216     uval   216
 atomic Counter[795]    val  221     uval   221
 atomic Counter[794]    val  188     uval   188
 atomic Counter[793]    val  190     uval   190
 atomic Counter[792]    val  88     uval   88
 atomic Counter[791]    val  215     uval   215
 atomic Counter[790]    val  128     uval   128
 atomic Counter[789]    val  222     uval   222
 atomic Counter[788]    val  219     uval   219
 atomic Counter[787]    val  121     uval   121
 atomic Counter[786]    val  244     uval   244
 atomic Counter[785]    val  210     uval   210
 atomic Counter[784]    val  212     uval   212
 atomic Counter[783]    val  209     uval   209
 atomic Counter[782]    val  224     uval   224
 atomic Counter[781]    val  213     uval   213
 atomic Counter[780]    val  223     uval   223
 atomic Counter[779]    val  205     uval   205
 atomic Counter[778]    val  211     uval   211
 atomic Counter[777]    val  231     uval   231
 atomic Counter[776]    val  228     uval   228
 atomic Counter[775]    val  229     uval   229
 atomic Counter[774]    val  233     uval   233
 atomic Counter[773]    val  208     uval   208
 atomic Counter[772]    val  207     uval   207
 atomic Counter[771]    val  225     uval   225
 atomic Counter[770]    val  247     uval   247
 atomic Counter[769]    val  251     uval   251
 atomic Counter[768]    val  220     uval   220
 atomic Counter[767]    val  226     uval   226
 atomic Counter[766]    val  230     uval   230
 atomic Counter[765]    val  214     uval   214
 atomic Counter[764]    val  227     uval   227
 atomic Counter[763]    val  241     uval   241
 atomic Counter[762]    val  243     uval   243
 atomic Counter[761]    val  250     uval   250
 atomic Counter[760]    val  249     uval   249
 atomic Counter[759]    val  95     uval   95
 atomic Counter[758]    val  234     uval   234
 atomic Counter[757]    val  236     uval   236
 atomic Counter[756]    val  245     uval   245
 atomic Counter[755]    val  238     uval   238
 atomic Counter[754]    val  252     uval   252
 atomic Counter[753]    val  253     uval   253
 atomic Counter[752]    val  246     uval   246
 atomic Counter[751]    val  239     uval   239
 atomic Counter[750]    val  242     uval   242
 atomic Counter[749]    val  256     uval   256
 atomic Counter[748]    val  248     uval   248
 atomic Counter[747]    val  265     uval   265
 atomic Counter[746]    val  264     uval   264
 atomic Counter[745]    val  240     uval   240
 atomic Counter[744]    val  235     uval   235
 atomic Counter[743]    val  280     uval   280
 atomic Counter[742]    val  254     uval   254
 atomic Counter[741]    val  274     uval   274
 atomic Counter[740]    val  206     uval   206
 atomic Counter[739]    val  259     uval   259
 atomic Counter[738]    val  196     uval   196
 atomic Counter[737]    val  258     uval   258
 atomic Counter[736]    val  149     uval   149
 atomic Counter[735]    val  154     uval   154
 atomic Counter[734]    val  268     uval   268
 atomic Counter[733]    val  257     uval   257
 atomic Counter[732]    val  260     uval   260
 atomic Counter[731]    val  261     uval   261
 atomic Counter[730]    val  237     uval   237
 atomic Counter[729]    val  266     uval   266
 atomic Counter[728]    val  263     uval   263
 atomic Counter[727]    val  232     uval   232
 atomic Counter[726]    val  275     uval   275
 atomic Counter[725]    val  267     uval   267
 atomic Counter[724]    val  271     uval   271
 atomic Counter[723]    val  255     uval   255
 atomic Counter[722]    val  276     uval   276
 atomic Counter[721]    val  303     uval   303
 atomic Counter[720]    val  281     uval   281
 atomic Counter[719]    val  272     uval   272
 atomic Counter[718]    val  315     uval   315
 atomic Counter[717]    val  318     uval   318
 atomic Counter[716]    val  269     uval   269
 atomic Counter[715]    val  285     uval   285
 atomic Counter[714]    val  295     uval   295
 atomic Counter[713]    val  314     uval   314
 atomic Counter[712]    val  270     uval   270
 atomic Counter[711]    val  300     uval   300
 atomic Counter[710]    val  284     uval   284
 atomic Counter[709]    val  294     uval   294
 atomic Counter[708]    val  279     uval   279
 atomic Counter[707]    val  287     uval   287
 atomic Counter[706]    val  282     uval   282
 atomic Counter[705]    val  310     uval   310
 atomic Counter[704]    val  286     uval   286
 atomic Counter[703]    val  1125     uval   1125
 atomic Counter[702]    val  320     uval   320
 atomic Counter[701]    val  0     uval   0

atomic Counter[4]    val  0     uval   0
 atomic Counter[3]    val  0     uval   0
 atomic Counter[2]    val  0     uval   0
 atomic Counter[1]    val  1040     uval   1040
 atomic Counter[0]    val  31452     uval   31452