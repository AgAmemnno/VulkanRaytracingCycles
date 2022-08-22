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

#define sizeof_PathState  4*(14)

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
#define sizeof_ShaderDataTinyStorage 4*( 4*10 + 15 + 4*2*3 +  2*2 )


struct PathRadianceState
{
vec4 diffuse;
vec4 glossy;
vec4 transmission;
vec4 volume;
vec4 direct;
};

#define sizeof_PathRadianceState 4*(4*5)

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

struct args_acc_light{
  int use_light_pass;
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 emission;
};
#define sizeof_acc_light 4*(1 + 4*4)

/* Ray */

 struct Ray {
/* TODO(sergey): This is only needed because current AMD
 * compiler has hard time building the kernel with this
 * reshuffle. And at the same time reshuffle will cause
 * less optimal CPU code in certain places.
 *
 * We'll get rid of this nasty exception once AMD compiler
 * is fixed.
 */
#ifndef _KERNEL_OPENCL_AMD_
  float3 P;   /* origin */
  float3 D;   /* direction */
  float t;    /* length of the ray */
  float time; /* time (for motion blur) */
#else
  float t;    /* length of the ray */
  float time; /* time (for motion blur) */
  float3 P;   /* origin */
  float3 D;   /* direction */
#endif

#ifdef _RAY_DIFFERENTIALS_
  differential3 dP;
  differential3 dD;
#endif
} ; //104

#define sizeof_Ray 4*(4*2 + 4*2*2 + 2)