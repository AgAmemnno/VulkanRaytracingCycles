#version 460
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types_int16 : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require

struct Transform
{
    vec4 x;
    vec4 y;
    vec4 z;
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
    vec3 dx;
    vec3 dy;
};

struct Ray
{
    float t;
    float time;
    vec3 P;
    vec3 D;
    differential3 dP;
    differential3 dD;
};

struct KernelGlobals_PROF
{
    uvec2 pixel;
    vec3 f3[960];
    float f1[960];
    uint u1[960];
};

const uint _725[16] = uint[](4u, 3u, 2u, 2u, 1u, 1u, 1u, 1u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u);

struct KernelObject
{
    Transform tfm;
    Transform itfm;
    float surface_area;
    float pass_id;
    float random_number;
    float color[3];
    int particle_index;
    float dupli_generated[3];
    float dupli_uv[2];
    int numkeys;
    int numsteps;
    int numverts;
    uint patch_map_offset;
    uint attribute_map_offset;
    uint motion_offset;
    float cryptomatte_object;
    float cryptomatte_asset;
    float shadow_terminator_offset;
    float pad1;
    float pad2;
    float pad3;
};

struct ShaderClosure
{
    vec4 weight;
    uint type;
    float sample_weight;
    vec4 N;
    int next;
    float data[25];
};

struct Intersection
{
    float t;
    float u;
    float v;
    int prim;
    int object;
    int type;
};

struct sd_tiny
{
    vec3 P;
    vec3 Ng;
    int type;
    int object;
    float time;
    differential3 dP;
    differential3 dI;
    int num_closure;
    int alloc_offset;
};

struct ProjectionTransform
{
    vec4 x;
    vec4 y;
    vec4 z;
    vec4 w;
};

struct KernelCamera
{
    int type;
    int panorama_type;
    float fisheye_fov;
    float fisheye_lens;
    vec4 equirectangular_range;
    float interocular_offset;
    float convergence_distance;
    float pole_merge_angle_from;
    float pole_merge_angle_to;
    Transform cameratoworld;
    ProjectionTransform rastertocamera;
    vec4 dx;
    vec4 dy;
    float aperturesize;
    float blades;
    float bladesrotation;
    float focaldistance;
    float shuttertime;
    int num_motion_steps;
    int have_perspective_motion;
    float nearclip;
    float cliplength;
    float sensorwidth;
    float sensorheight;
    float width;
    float height;
    int resolution;
    float inv_aperture_ratio;
    int is_inside_volume;
    ProjectionTransform screentoworld;
    ProjectionTransform rastertoworld;
    ProjectionTransform ndctoworld;
    ProjectionTransform worldtoscreen;
    ProjectionTransform worldtoraster;
    ProjectionTransform worldtondc;
    Transform worldtocamera;
    ProjectionTransform perspective_pre;
    ProjectionTransform perspective_post;
    Transform motion_pass_pre;
    Transform motion_pass_post;
    int shutter_table_offset;
    int rolling_shutter_type;
    float rolling_shutter_duration;
    int pad;
};

struct KernelFilm
{
    float exposure;
    int pass_flag;
    int light_pass_flag;
    int pass_stride;
    int use_light_pass;
    int pass_combined;
    int pass_depth;
    int pass_normal;
    int pass_motion;
    int pass_motion_weight;
    int pass_uv;
    int pass_object_id;
    int pass_material_id;
    int pass_diffuse_color;
    int pass_glossy_color;
    int pass_transmission_color;
    int pass_diffuse_indirect;
    int pass_glossy_indirect;
    int pass_transmission_indirect;
    int pass_volume_indirect;
    int pass_diffuse_direct;
    int pass_glossy_direct;
    int pass_transmission_direct;
    int pass_volume_direct;
    int pass_emission;
    int pass_background;
    int pass_ao;
    float pass_alpha_threshold;
    int pass_shadow;
    float pass_shadow_scale;
    int filter_table_offset;
    int cryptomatte_passes;
    int cryptomatte_depth;
    int pass_cryptomatte;
    int pass_adaptive_aux_buffer;
    int pass_sample_count;
    int pass_mist;
    float mist_start;
    float mist_inv_depth;
    float mist_falloff;
    int pass_denoising_data;
    int pass_denoising_clean;
    int denoising_flags;
    int pass_aov_color;
    int pass_aov_value;
    int pass_aov_color_num;
    int pass_aov_value_num;
    int pad1;
    int pad2;
    int pad3;
    vec4 xyz_to_r;
    vec4 xyz_to_g;
    vec4 xyz_to_b;
    vec4 rgb_to_y;
    int pass_bake_primitive;
    int pass_bake_differential;
    int pad;
    int display_pass_stride;
    int display_pass_components;
    int display_divide_pass_stride;
    int use_display_exposure;
    int use_display_pass_alpha;
    int pad4;
    int pad5;
    int pad6;
};

struct KernelBackground
{
    int surface_shader;
    int volume_shader;
    float volume_step_size;
    int transparent;
    float transparent_roughness_squared_threshold;
    float ao_factor;
    float ao_distance;
    float ao_bounces_factor;
    float portal_weight;
    int num_portals;
    int portal_offset;
    float sun_weight;
    vec4 sun;
    float map_weight;
    int map_res_x;
    int map_res_y;
    int use_mis;
};

struct KernelIntegrator
{
    int use_direct_light;
    int use_ambient_occlusion;
    int num_distribution;
    int num_all_lights;
    float pdf_triangles;
    float pdf_lights;
    float light_inv_rr_threshold;
    int min_bounce;
    int max_bounce;
    int max_diffuse_bounce;
    int max_glossy_bounce;
    int max_transmission_bounce;
    int max_volume_bounce;
    int ao_bounces;
    int transparent_min_bounce;
    int transparent_max_bounce;
    int transparent_shadows;
    int caustics_reflective;
    int caustics_refractive;
    float filter_glossy;
    int seed;
    float sample_clamp_direct;
    float sample_clamp_indirect;
    int branched;
    int volume_decoupled;
    int diffuse_samples;
    int glossy_samples;
    int transmission_samples;
    int ao_samples;
    int mesh_light_samples;
    int subsurface_samples;
    int sample_all_lights_direct;
    int sample_all_lights_indirect;
    int use_lamp_mis;
    int sampling_pattern;
    int aa_samples;
    int adaptive_min_samples;
    int adaptive_step;
    int adaptive_stop_per_sample;
    float adaptive_threshold;
    int use_volumes;
    int volume_max_steps;
    float volume_step_rate;
    int volume_samples;
    int start_sample;
    int max_closures;
    int pad1;
    int pad2;
};

struct KernelBVH
{
    int root;
    int have_motion;
    int have_curves;
    int bvh_layout;
    int use_bvh_steps;
    int curve_subdivisions;
    int scene;
    int pad2;
};

struct KernelTables
{
    int beckmann_offset;
    int pad1;
    int pad2;
    int pad3;
};

struct KernelBake
{
    int object_index;
    int tri_offset;
    int type;
    int pass_filter;
};

struct KernelData
{
    KernelCamera cam;
    KernelFilm film;
    KernelBackground background;
    KernelIntegrator integrator;
    KernelBVH bvh;
    KernelTables tables;
    KernelBake bake;
};

struct LIsectInfo
{
    int offset;
    int max_hits;
    uint lcg_state;
    int num_hits;
    int local_object;
    int type;
};

struct LocalIntersection_tiny
{
    Ray ray;
    vec3 weight[4];
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer ShaderClosurePool;
layout(buffer_reference) buffer IntersectionPool;
layout(buffer_reference) buffer _prim_tri_verts2_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer _objects_;
layout(buffer_reference) buffer _tri_vindex2_;
layout(buffer_reference) buffer _sample_pattern_lut_;
layout(buffer_reference) buffer pool_sc_;
layout(buffer_reference) buffer pool_is_;
layout(buffer_reference, std430) buffer KernelTextures
{
    _prim_tri_verts2_ _prim_tri_verts2;
    int64_t pad[3];
    _prim_index_ _prim_index;
    _prim_object_ _prim_object;
    _objects_ _objects;
    int64_t pad1[10];
    _tri_vindex2_ _tri_vindex2;
    int64_t pad2[10];
    _sample_pattern_lut_ _sample_pattern_lut;
};

layout(buffer_reference, std430) buffer ShaderClosurePool
{
    pool_sc_ pool_sc;
};

layout(buffer_reference, std430) buffer IntersectionPool
{
    pool_is_ pool_is;
};

layout(buffer_reference, std430) readonly buffer _prim_tri_verts2_
{
    vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _prim_index_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _prim_object_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _objects_
{
    KernelObject data[];
};

layout(buffer_reference, std430) readonly buffer _tri_vindex2_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _sample_pattern_lut_
{
    uint data[];
};

layout(buffer_reference, scalar) buffer pool_sc_
{
    ShaderClosure data[];
};

layout(buffer_reference, std430) buffer pool_is_
{
    Intersection data[];
};

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals_PROF kg;
} _459;

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _1776;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _4633;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    ShaderClosurePool pool1_ptr;
    IntersectionPool pool2_ptr;
} push;

layout(location = 1) rayPayloadNV LIsectInfo linfo2;
layout(location = 0) rayPayloadInNV LIsectInfo linfo;
layout(set = 0, binding = 0) uniform accelerationStructureNV topLevelAS;

float null_flt;
vec2 null_flt2;
vec4 null_flt3;
vec4 null_flt4;
int null_int;
uint INTERPOLATION_NONE;
uint INTERPOLATION_LINEAR;
uint INTERPOLATION_CLOSEST;
uint INTERPOLATION_CUBIC;
uint INTERPOLATION_SMART;
uint INTERPOLATION_NUM_TYPES;
uint IMAGE_DATA_TYPE_FLOAT4;
uint IMAGE_DATA_TYPE_BYTE4;
uint IMAGE_DATA_TYPE_HALF4;
uint IMAGE_DATA_TYPE_FLOAT;
uint IMAGE_DATA_TYPE_BYTE;
uint IMAGE_DATA_TYPE_HALF;
uint IMAGE_DATA_TYPE_USHORT4;
uint IMAGE_DATA_TYPE_USHORT;
uint IMAGE_DATA_NUM_TYPES;
uint IMAGE_ALPHA_UNASSOCIATED;
uint IMAGE_ALPHA_ASSOCIATED;
uint IMAGE_ALPHA_CHANNEL_PACKED;
uint IMAGE_ALPHA_IGNORE;
uint IMAGE_ALPHA_AUTO;
uint IMAGE_ALPHA_NUM_TYPES;
uint EXTENSION_REPEAT;
uint EXTENSION_EXTEND;
uint EXTENSION_CLIP;
uint EXTENSION_NUM_TYPES;
bool G_dump;
int rec_num;
uvec2 Dpixel;
sd_tiny GSD;
PathState state;
LocalIntersection_tiny ss_isect;
bool G_use_light_pass;
int PROFI_IDX;
ShaderClosure null_sc;

void make_orthonormals(vec3 N, inout vec3 a, out vec3 b)
{
    bool _540 = !(N.x == N.y);
    bool _549;
    if (!_540)
    {
        _549 = !(N.x == N.z);
    }
    else
    {
        _549 = _540;
    }
    if (_549)
    {
        a = vec3(N.z - N.y, N.x - N.z, N.y - N.x);
    }
    else
    {
        a = vec3(N.z - N.y, N.x + N.z, (-N.y) - N.x);
    }
    a = normalize(a);
    b = cross(N, a);
}

float bssrdf_cubic_quintic_root_find(float xi)
{
    float x = 0.25;
    for (int i = 0; i < 10; i++)
    {
        float x2 = x * x;
        float x3 = x2 * x;
        float nx = 1.0 - x;
        float f = ((((10.0 * x2) - (20.0 * x3)) + ((15.0 * x2) * x2)) - ((4.0 * x2) * x3)) - xi;
        float f_ = (20.0 * (x * nx)) * (nx * nx);
        if ((abs(f) < 9.9999999747524270787835121154785e-07) || (f_ == 0.0))
        {
            break;
        }
        x = clamp(x - (f / f_), 0.0, 1.0);
    }
    return x;
}

float safe_sqrtf(float f)
{
    return sqrt(max(f, 0.0));
}

void bssrdf_cubic_sample(float radius, float sharpness, float xi, out float r, out float h)
{
    float Rm = radius;
    float param = xi;
    float r_ = bssrdf_cubic_quintic_root_find(param);
    if (!(sharpness == 0.0))
    {
        r_ = pow(r_, 1.0 + sharpness);
        Rm *= (1.0 + sharpness);
    }
    r_ *= Rm;
    r = r_;
    float param_1 = (Rm * Rm) - (r_ * r_);
    h = safe_sqrtf(param_1);
}

void bssrdf_gaussian_sample(float radius, float xi, out float r, out float h)
{
    float v = (radius * radius) * 0.0625;
    float Rm = sqrt(v * 12.46000003814697265625);
    float r_squared = ((-2.0) * v) * log(1.0 - (xi * 0.99803054332733154296875));
    r = sqrt(r_squared);
    float param = (Rm * Rm) - r_squared;
    h = safe_sqrtf(param);
}

float bssrdf_burley_root_find(float xi)
{
    float r;
    if (xi <= 0.89999997615814208984375)
    {
        r = exp((xi * xi) * 2.400000095367431640625) - 1.0;
    }
    else
    {
        r = 15.0;
    }
    for (int i = 0; i < 10; i++)
    {
        float exp_r_3 = exp((-r) / 3.0);
        float exp_r = (exp_r_3 * exp_r_3) * exp_r_3;
        float f = ((1.0 - (0.25 * exp_r)) - (0.75 * exp_r_3)) - xi;
        float f_ = (0.25 * exp_r) + (0.25 * exp_r_3);
        if ((abs(f) < 9.9999999747524270787835121154785e-07) || (f_ == 0.0))
        {
            break;
        }
        r -= (f / f_);
        if (r < 0.0)
        {
            r = 0.0;
        }
    }
    return r;
}

void bssrdf_burley_sample(float d, float xi, out float r, out float h)
{
    float Rm = 16.0 * d;
    float param = xi * 0.99637901782989501953125;
    float r_ = bssrdf_burley_root_find(param) * d;
    r = r_;
    float param_1 = (Rm * Rm) - (r_ * r_);
    h = safe_sqrtf(param_1);
}

void bssrdf_sample(int scN, inout float xi, inout float r, inout float h)
{
    xi *= push.pool1_ptr.pool_sc.data[scN].data[9];
    float radius;
    if (xi < 1.0)
    {
        float _2756;
        if (push.pool1_ptr.pool_sc.data[scN].data[0] > 0.0)
        {
            _2756 = push.pool1_ptr.pool_sc.data[scN].data[0];
        }
        else
        {
            float _2775;
            if (push.pool1_ptr.pool_sc.data[scN].data[1] > 0.0)
            {
                _2775 = push.pool1_ptr.pool_sc.data[scN].data[1];
            }
            else
            {
                _2775 = push.pool1_ptr.pool_sc.data[scN].data[2];
            }
            _2756 = _2775;
        }
        radius = _2756;
    }
    else
    {
        if (xi < 2.0)
        {
            xi -= 1.0;
            float _2810;
            if (push.pool1_ptr.pool_sc.data[scN].data[0] > 0.0)
            {
                _2810 = push.pool1_ptr.pool_sc.data[scN].data[1];
            }
            else
            {
                _2810 = push.pool1_ptr.pool_sc.data[scN].data[2];
            }
            radius = _2810;
        }
        else
        {
            xi -= 2.0;
            radius = push.pool1_ptr.pool_sc.data[scN].data[2];
        }
    }
    if (push.pool1_ptr.pool_sc.data[scN].type == 34u)
    {
        float param = xi;
        float param_1 = r;
        float param_2 = h;
        bssrdf_cubic_sample(radius, push.pool1_ptr.pool_sc.data[scN].data[6], param, param_1, param_2);
        r = param_1;
        h = param_2;
    }
    else
    {
        if (push.pool1_ptr.pool_sc.data[scN].type == 35u)
        {
            float param_3 = xi;
            float param_4 = r;
            float param_5 = h;
            bssrdf_gaussian_sample(radius, param_3, param_4, param_5);
            r = param_4;
            h = param_5;
        }
        else
        {
            float param_6 = xi;
            float param_7 = r;
            float param_8 = h;
            bssrdf_burley_sample(radius, param_6, param_7, param_8);
            r = param_7;
            h = param_8;
        }
    }
}

bool isfinite_safe(float f)
{
    uint x = floatBitsToUint(f);
    bool _468 = f == f;
    bool _486;
    if (_468)
    {
        bool _476 = (x == 0u) || (x == 2147483648u);
        bool _485;
        if (!_476)
        {
            _485 = !(f == (2.0 * f));
        }
        else
        {
            _485 = _476;
        }
        _486 = _485;
    }
    else
    {
        _486 = _468;
    }
    bool _495;
    if (_486)
    {
        _495 = !((x << uint(1)) > 4278190080u);
    }
    else
    {
        _495 = _486;
    }
    return _495;
}

float len_squared(vec3 a)
{
    return dot(a, a);
}

bool scene_intersect_local(int local_object, uint lcg_state, int max_hits)
{
    linfo2.max_hits = max_hits;
    linfo2.local_object = local_object;
    linfo2.num_hits = 0;
    linfo2.lcg_state = lcg_state;
    linfo2.offset = linfo.offset;
    if (G_dump)
    {
        _459.kg.f3[26 + ((rec_num - 1) * 64)] = ss_isect.ray.P;
    }
    if (G_dump)
    {
        _459.kg.f3[27 + ((rec_num - 1) * 64)] = ss_isect.ray.D;
    }
    if (G_dump)
    {
        _459.kg.f1[3 + ((rec_num - 1) * 64)] = ss_isect.ray.t;
    }
    float param = ss_isect.ray.P.x;
    bool _3075 = isfinite_safe(param);
    bool _3082;
    if (_3075)
    {
        float param_1 = ss_isect.ray.D.x;
        _3082 = isfinite_safe(param_1);
    }
    else
    {
        _3082 = _3075;
    }
    bool _3089;
    if (_3082)
    {
        _3089 = !(len_squared(ss_isect.ray.D) == 0.0);
    }
    else
    {
        _3089 = _3082;
    }
    if (_3089)
    {
        traceNV(topLevelAS, 8u, 255u, 2u, 0u, 2u, ss_isect.ray.P, 0.0, ss_isect.ray.D, ss_isect.ray.t, 1);
        return true;
    }
    return false;
}

Transform object_fetch_transform(int object, uint type)
{
    if (type == 1u)
    {
        Transform _1013;
        _1013.x = push.data_ptr._objects.data[object].itfm.x;
        _1013.y = push.data_ptr._objects.data[object].itfm.y;
        _1013.z = push.data_ptr._objects.data[object].itfm.z;
        Transform _1012 = _1013;
        return _1012;
    }
    else
    {
        Transform _1025;
        _1025.x = push.data_ptr._objects.data[object].tfm.x;
        _1025.y = push.data_ptr._objects.data[object].tfm.y;
        _1025.z = push.data_ptr._objects.data[object].tfm.z;
        Transform _1024 = _1025;
        return _1024;
    }
}

vec3 transform_point(Transform t, vec3 a)
{
    vec3 c = vec3((((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z)) + t.x.w, (((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z)) + t.y.w, (((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z)) + t.z.w);
    return c;
}

vec3 transform_direction(Transform t, vec3 a)
{
    vec3 c = vec3(((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z), ((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z), ((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z));
    return c;
}

vec3 normalize_len(vec3 a, inout float t)
{
    t = length(a);
    float x = 1.0 / t;
    return vec3(a * x);
}

vec3 triangle_refine(inout vec3 P, inout vec3 D, inout float t, int object, int prim, int geometry)
{
    if (!((object & 8388608) != int(0u)))
    {
        if (t == 0.0)
        {
            return P;
        }
        int param = object & 8388607;
        uint param_1 = 1u;
        Transform tfm = object_fetch_transform(param, param_1);
        Transform param_2 = tfm;
        tfm = param_2;
        P = transform_point(param_2, P);
        Transform param_3 = tfm;
        tfm = param_3;
        D = transform_direction(param_3, D * t);
        float param_4 = t;
        vec3 _2090 = normalize_len(D, param_4);
        t = param_4;
        D = _2090;
    }
    P += (D * t);
    uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * prim], push.data_ptr._tri_vindex2.data[(3 * prim) + 1], push.data_ptr._tri_vindex2.data[(3 * prim) + 2]) + uvec3(push.data_ptr._prim_index.data[geometry]);
    vec4 tri_a = push.data_ptr._prim_tri_verts2.data[tri_vindex.x];
    vec4 tri_b = push.data_ptr._prim_tri_verts2.data[tri_vindex.y];
    vec4 tri_c = push.data_ptr._prim_tri_verts2.data[tri_vindex.z];
    vec3 edge1 = vec3(tri_a.x - tri_c.x, tri_a.y - tri_c.y, tri_a.z - tri_c.z);
    vec3 edge2 = vec3(tri_b.x - tri_c.x, tri_b.y - tri_c.y, tri_b.z - tri_c.z);
    vec3 tvec = vec3(P.x - tri_c.x, P.y - tri_c.y, P.z - tri_c.z);
    vec3 qvec = cross(tvec, edge1);
    vec3 pvec = cross(D, edge2);
    float det = dot(edge1, pvec);
    if (!(det == 0.0))
    {
        float rt = dot(edge2, qvec) / det;
        P += (D * rt);
    }
    if (!((object & 8388608) != int(0u)))
    {
        int param_5 = object & 8388607;
        uint param_6 = 0u;
        Transform tfm_1 = object_fetch_transform(param_5, param_6);
        Transform param_7 = tfm_1;
        tfm_1 = param_7;
        P = transform_point(param_7, P);
    }
    return P;
}

vec3 triangle_refine_local(int ISid, Ray ray)
{
    float t = push.pool2_ptr.pool_is.data[ISid].t;
    int object = push.pool2_ptr.pool_is.data[ISid].object;
    int prim = push.pool2_ptr.pool_is.data[ISid].prim;
    int geometry = push.pool2_ptr.pool_is.data[ISid].type;
    vec3 param = ray.P;
    vec3 param_1 = ray.D;
    float param_2 = t;
    int param_3 = object;
    int param_4 = prim;
    int param_5 = geometry;
    vec3 _2317 = triangle_refine(param, param_1, param_2, param_3, param_4, param_5);
    return _2317;
}

vec3 transform_direction_transposed(Transform t, vec3 a)
{
    vec3 x = vec3(t.x.x, t.y.x, t.z.x);
    vec3 y = vec3(t.x.y, t.y.y, t.z.y);
    vec3 z = vec3(t.x.z, t.y.z, t.z.z);
    return vec3(dot(x, a), dot(y, a), dot(z, a));
}

void object_normal_transform(inout vec3 N)
{
    int param = GSD.object;
    uint param_1 = 1u;
    Transform tfm = object_fetch_transform(param, param_1);
    N = normalize(transform_direction_transposed(tfm, N));
}

float sqr(float a)
{
    return a * a;
}

float bssrdf_cubic_eval(float radius, float sharpness, float r)
{
    if (sharpness == 0.0)
    {
        float Rm = radius;
        if (r >= Rm)
        {
            return 0.0;
        }
        float Rm5 = ((Rm * Rm) * (Rm * Rm)) * Rm;
        float f = Rm - r;
        float num = (f * f) * f;
        return (10.0 * num) / (Rm5 * 3.1415927410125732421875);
    }
    else
    {
        float Rm_1 = radius * (1.0 + sharpness);
        if (r >= Rm_1)
        {
            return 0.0;
        }
        float y = 1.0 / (1.0 + sharpness);
        float Rmy;
        float ry;
        float ryinv;
        if (sharpness == 1.0)
        {
            Rmy = sqrt(Rm_1);
            ry = sqrt(r);
            float _2444;
            if (ry > 0.0)
            {
                _2444 = 1.0 / ry;
            }
            else
            {
                _2444 = 0.0;
            }
            ryinv = _2444;
        }
        else
        {
            Rmy = pow(Rm_1, y);
            ry = pow(r, y);
            float _2460;
            if (r > 0.0)
            {
                _2460 = pow(r, y - 1.0);
            }
            else
            {
                _2460 = 0.0;
            }
            ryinv = _2460;
        }
        float Rmy5 = ((Rmy * Rmy) * (Rmy * Rmy)) * Rmy;
        float f_1 = Rmy - ry;
        float num_1 = (f_1 * (f_1 * f_1)) * (y * ryinv);
        return (10.0 * num_1) / (Rmy5 * 3.1415927410125732421875);
    }
}

float bssrdf_cubic_pdf(float radius, float sharpness, float r)
{
    float param = r;
    return bssrdf_cubic_eval(radius, sharpness, param);
}

float bssrdf_gaussian_eval(float radius, float r)
{
    float v = (radius * radius) * 0.0625;
    float Rm = sqrt(v * 12.46000003814697265625);
    if (r >= Rm)
    {
        return 0.0;
    }
    return exp(((-r) * r) / (2.0 * v)) / (6.283185482025146484375 * v);
}

float bssrdf_gaussian_pdf(float radius, float r)
{
    float param = r;
    return bssrdf_gaussian_eval(radius, param) * 1.0019733905792236328125;
}

float bssrdf_burley_eval(float d, float r)
{
    float Rm = 16.0 * d;
    if (r >= Rm)
    {
        return 0.0;
    }
    float exp_r_3_d = exp((-r) / (3.0 * d));
    float exp_r_d = (exp_r_3_d * exp_r_3_d) * exp_r_3_d;
    return (exp_r_d + exp_r_3_d) / (4.0 * d);
}

float bssrdf_burley_pdf(float d, float r)
{
    float param = r;
    return bssrdf_burley_eval(d, param) * 1.00363409519195556640625;
}

float bssrdf_channel_pdf(float radius, float r)
{
    if (radius == 0.0)
    {
        return 0.0;
    }
    else
    {
        if (push.pool1_ptr.pool_sc.data[GSD.alloc_offset].type == 34u)
        {
            float param = r;
            return bssrdf_cubic_pdf(radius, push.pool1_ptr.pool_sc.data[GSD.alloc_offset].data[6], param);
        }
        else
        {
            if (push.pool1_ptr.pool_sc.data[GSD.alloc_offset].type == 35u)
            {
                float param_1 = r;
                return bssrdf_gaussian_pdf(radius, param_1);
            }
            else
            {
                float param_2 = r;
                return bssrdf_burley_pdf(radius, param_2);
            }
        }
    }
}

vec3 bssrdf_eval(float r)
{
    float param = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].data[0];
    float param_1 = r;
    float param_2 = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].data[1];
    float param_3 = r;
    float param_4 = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].data[2];
    float param_5 = r;
    return vec3(bssrdf_channel_pdf(param, param_1), bssrdf_channel_pdf(param_2, param_3), bssrdf_channel_pdf(param_4, param_5));
}

float bssrdf_pdf(float r)
{
    float param = r;
    vec3 pdf = bssrdf_eval(param);
    return ((pdf.x + pdf.y) + pdf.z) / push.pool1_ptr.pool_sc.data[GSD.alloc_offset].data[9];
}

vec3 subsurface_scatter_eval(float disk_r, float r, bool _all)
{
    vec3 eval_sum = vec3(0.0);
    float pdf_sum = 0.0;
    float sample_weight_inv = 0.0;
    int it_begin = linfo.offset;
    if (!_all)
    {
        float sample_weight_sum = 0.0;
        GSD.alloc_offset = it_begin - 1;
        for (int i = 0; i < GSD.num_closure; i++)
        {
            GSD.alloc_offset++;
            bool _3345 = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].type >= 34u;
            bool _3358;
            if (_3345)
            {
                _3358 = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].type <= 37u;
            }
            else
            {
                _3358 = _3345;
            }
            if (_3358)
            {
                sample_weight_sum += push.pool1_ptr.pool_sc.data[GSD.alloc_offset].sample_weight;
            }
        }
        sample_weight_inv = 1.0 / sample_weight_sum;
    }
    GSD.alloc_offset = it_begin - 1;
    float _3417;
    for (int i_1 = 0; i_1 < GSD.num_closure; i_1++)
    {
        GSD.alloc_offset++;
        bool _3400 = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].type >= 34u;
        bool _3412;
        if (_3400)
        {
            _3412 = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].type <= 37u;
        }
        else
        {
            _3412 = _3400;
        }
        if (_3412)
        {
            if (_all)
            {
                _3417 = 1.0;
            }
            else
            {
                _3417 = push.pool1_ptr.pool_sc.data[GSD.alloc_offset].sample_weight * sample_weight_inv;
            }
            float sample_weight = _3417;
            float param = r;
            vec3 eval = bssrdf_eval(param);
            float param_1 = disk_r;
            float pdf = bssrdf_pdf(param_1);
            eval_sum += (push.pool1_ptr.pool_sc.data[GSD.alloc_offset].weight.xyz * eval);
            pdf_sum += (sample_weight * pdf);
        }
    }
    vec3 _3462;
    if (pdf_sum > 0.0)
    {
        _3462 = eval_sum / vec3(pdf_sum);
    }
    else
    {
        _3462 = vec3(0.0);
    }
    return _3462;
}

int subsurface_scatter_disk(int scN, inout uint lcg_state, float disk_u, inout float disk_v, bool _all)
{
    vec3 disk_N = GSD.Ng;
    vec3 param = disk_N;
    vec3 disk_T;
    vec3 param_1 = disk_T;
    vec3 param_2;
    make_orthonormals(param, param_1, param_2);
    disk_T = param_1;
    vec3 disk_B = param_2;
    float pick_pdf_N;
    float pick_pdf_T;
    float pick_pdf_B;
    if (disk_v < 0.5)
    {
        pick_pdf_N = 0.5;
        pick_pdf_T = 0.25;
        pick_pdf_B = 0.25;
        disk_v *= 2.0;
    }
    else
    {
        if (disk_v < 0.75)
        {
            vec3 tmp = disk_N;
            disk_N = disk_T;
            disk_T = tmp;
            pick_pdf_N = 0.25;
            pick_pdf_T = 0.5;
            pick_pdf_B = 0.25;
            disk_v = (disk_v - 0.5) * 4.0;
        }
        else
        {
            vec3 tmp_1 = disk_N;
            disk_N = disk_B;
            disk_B = tmp_1;
            pick_pdf_N = 0.25;
            pick_pdf_T = 0.25;
            pick_pdf_B = 0.5;
            disk_v = (disk_v - 0.75) * 4.0;
        }
    }
    float phi = 6.283185482025146484375 * disk_v;
    int param_3 = scN;
    float param_4 = disk_u;
    float disk_r;
    float param_5 = disk_r;
    float disk_height;
    float param_6 = disk_height;
    bssrdf_sample(param_3, param_4, param_5, param_6);
    disk_r = param_5;
    disk_height = param_6;
    vec3 disk_P = (disk_T * (disk_r * cos(phi))) + (disk_B * (disk_r * sin(phi)));
    ss_isect.ray.P = (GSD.P + (disk_N * disk_height)) + disk_P;
    ss_isect.ray.D = -disk_N;
    ss_isect.ray.t = 2.0 * disk_height;
    ss_isect.ray.dP = GSD.dP;
    ss_isect.ray.dD.dx = vec3(0.0);
    ss_isect.ray.dD.dy = vec3(0.0);
    ss_isect.ray.time = GSD.time;
    int param_7 = GSD.object;
    uint param_8 = lcg_state;
    int param_9 = 4;
    bool _3576 = scene_intersect_local(param_7, param_8, param_9);
    lcg_state = param_8;
    int num_eval_hits = min(linfo2.num_hits, 4);
    int ISid = linfo.offset - 1;
    vec3 hit_P;
    for (int hit = 0; hit < num_eval_hits; hit++)
    {
        ISid++;
        if ((uint(GSD.type) & 1u) != 0u)
        {
            int param_10 = ISid;
            Ray param_11 = ss_isect.ray;
            hit_P = triangle_refine_local(param_10, param_11);
        }
        else
        {
            vec3 v = vec3(0.0);
            int idx = (linfo.offset + 4) + hit;
            push.pool2_ptr.pool_is.data[idx].t = v.x;
            push.pool2_ptr.pool_is.data[idx].u = v.y;
            push.pool2_ptr.pool_is.data[idx].v = v.z;
            continue;
        }
        uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * push.pool2_ptr.pool_is.data[ISid].prim], push.data_ptr._tri_vindex2.data[(3 * push.pool2_ptr.pool_is.data[ISid].prim) + 1], push.data_ptr._tri_vindex2.data[(3 * push.pool2_ptr.pool_is.data[ISid].prim) + 2]) + uvec3(push.data_ptr._prim_index.data[push.pool2_ptr.pool_is.data[ISid].type]);
        vec3 tri_a = push.data_ptr._prim_tri_verts2.data[tri_vindex.x].xyz;
        vec3 tri_b = push.data_ptr._prim_tri_verts2.data[tri_vindex.y].xyz;
        vec3 tri_c = push.data_ptr._prim_tri_verts2.data[tri_vindex.z].xyz;
        vec3 hit_Ng = normalize(cross(tri_b - tri_a, tri_c - tri_a));
        if (!((push.pool2_ptr.pool_is.data[ISid].object & 8388608) != int(0u)))
        {
            vec3 param_12 = hit_Ng;
            object_normal_transform(param_12);
            hit_Ng = param_12;
        }
        if (G_dump)
        {
            _459.kg.f3[28 + ((rec_num - 1) * 64)] = hit_Ng;
        }
        float pdf_N = pick_pdf_N * abs(dot(disk_N, hit_Ng));
        float pdf_T = pick_pdf_T * abs(dot(disk_T, hit_Ng));
        float pdf_B = pick_pdf_B * abs(dot(disk_B, hit_Ng));
        float param_13 = pdf_N;
        float param_14 = pdf_T;
        float param_15 = pdf_B;
        float w = pdf_N / ((sqr(param_13) + sqr(param_14)) + sqr(param_15));
        if (linfo.num_hits > 4)
        {
            w *= (float(linfo.num_hits) / 4.0);
        }
        float r = length(hit_P - GSD.P);
        float param_16 = disk_r;
        float param_17 = r;
        bool param_18 = _all;
        vec3 _3830 = subsurface_scatter_eval(param_16, param_17, param_18);
        vec3 eval = _3830 * w;
        int idx_1 = (linfo.offset + 4) + hit;
        push.pool2_ptr.pool_is.data[idx_1].t = eval.x;
        push.pool2_ptr.pool_is.data[idx_1].u = eval.y;
        push.pool2_ptr.pool_is.data[idx_1].v = eval.z;
        if (G_dump)
        {
            _459.kg.f3[29 + ((rec_num - 1) * 64)] = eval;
        }
    }
    return num_eval_hits;
}

void to_unit_disk(inout float x, inout float y)
{
    float phi = 6.283185482025146484375 * x;
    float r = sqrt(y);
    x = r * cos(phi);
    y = r * sin(phi);
}

void sample_cos_hemisphere(vec3 N, inout float randu, inout float randv, out vec3 omega_in, out float pdf)
{
    float param = randu;
    float param_1 = randv;
    to_unit_disk(param, param_1);
    randu = param;
    randv = param_1;
    float costheta = sqrt(max((1.0 - (randu * randu)) - (randv * randv), 0.0));
    vec3 param_2 = N;
    vec3 T;
    vec3 param_3 = T;
    vec3 param_4;
    make_orthonormals(param_2, param_3, param_4);
    T = param_3;
    vec3 B = param_4;
    omega_in = ((T * randu) + (B * randv)) + (N * costheta);
    pdf = costheta * 0.3183098733425140380859375;
}

void subsurface_random_walk_remap(float A, float d, inout float sigma_t, out float sigma_s)
{
    float a = 1.0 - exp(A * ((-5.09405994415283203125) + (A * (2.6118800640106201171875 - (A * 4.318049907684326171875)))));
    float param = A - 0.800000011920928955078125;
    float s = (1.89999997615814208984375 - A) + (3.5 * sqr(param));
    sigma_t = 1.0 / max(d * s, 1.000000016862383526387164645044e-16);
    sigma_s = sigma_t * a;
}

vec3 safe_divide_color(vec3 a, vec3 b)
{
    float _596;
    if (!(b.x == 0.0))
    {
        _596 = a.x / b.x;
    }
    else
    {
        _596 = 0.0;
    }
    float x = _596;
    float _610;
    if (!(b.y == 0.0))
    {
        _610 = a.y / b.y;
    }
    else
    {
        _610 = 0.0;
    }
    float y = _610;
    float _624;
    if (!(b.z == 0.0))
    {
        _624 = a.z / b.z;
    }
    else
    {
        _624 = 0.0;
    }
    float z = _624;
    return vec3(x, y, z);
}

void subsurface_random_walk_coefficients(int scN, out vec3 sigma_t, out vec3 sigma_s, out vec3 weight)
{
    vec3 A = vec3(push.pool1_ptr.pool_sc.data[scN].data[3], push.pool1_ptr.pool_sc.data[scN].data[4], push.pool1_ptr.pool_sc.data[scN].data[5]);
    vec3 d = vec3(push.pool1_ptr.pool_sc.data[scN].data[0], push.pool1_ptr.pool_sc.data[scN].data[1], push.pool1_ptr.pool_sc.data[scN].data[2]);
    float param = A.x;
    float param_1 = d.x;
    float sigma_t_x;
    float param_2 = sigma_t_x;
    float sigma_s_x;
    float param_3 = sigma_s_x;
    subsurface_random_walk_remap(param, param_1, param_2, param_3);
    sigma_t_x = param_2;
    sigma_s_x = param_3;
    float param_4 = A.y;
    float param_5 = d.y;
    float sigma_t_y;
    float param_6 = sigma_t_y;
    float sigma_s_y;
    float param_7 = sigma_s_y;
    subsurface_random_walk_remap(param_4, param_5, param_6, param_7);
    sigma_t_y = param_6;
    sigma_s_y = param_7;
    float param_8 = A.z;
    float param_9 = d.z;
    float sigma_t_z;
    float param_10 = sigma_t_z;
    float sigma_s_z;
    float param_11 = sigma_s_z;
    subsurface_random_walk_remap(param_8, param_9, param_10, param_11);
    sigma_t_z = param_10;
    sigma_s_z = param_11;
    sigma_t = vec3(sigma_t_x, sigma_t_y, sigma_t_z);
    sigma_s = vec3(sigma_s_x, sigma_s_y, sigma_s_z);
    vec3 param_12 = push.pool1_ptr.pool_sc.data[scN].weight.xyz;
    vec3 param_13 = A;
    weight = safe_divide_color(param_12, param_13);
}

vec3 ray_offset(vec3 P, vec3 Ng)
{
    vec3 res;
    if (abs(P.x) < 1.0)
    {
        res.x = P.x + (Ng.x * 9.9999997473787516355514526367188e-06);
    }
    else
    {
        uint ix = floatBitsToUint(P.x);
        ix += uint((((ix ^ floatBitsToUint(Ng.x)) >> uint(31)) != 0u) ? (-32) : 32);
        res.x = uintBitsToFloat(ix);
    }
    if (abs(P.y) < 1.0)
    {
        res.y = P.y + (Ng.y * 9.9999997473787516355514526367188e-06);
    }
    else
    {
        uint iy = floatBitsToUint(P.y);
        iy += uint((((iy ^ floatBitsToUint(Ng.y)) >> uint(31)) != 0u) ? (-32) : 32);
        res.y = uintBitsToFloat(iy);
    }
    if (abs(P.z) < 1.0)
    {
        res.z = P.z + (Ng.z * 9.9999997473787516355514526367188e-06);
    }
    else
    {
        uint iz = floatBitsToUint(P.z);
        iz += uint((((iz ^ floatBitsToUint(Ng.z)) >> uint(31)) != 0u) ? (-32) : 32);
        res.z = uintBitsToFloat(iz);
    }
    return res;
}

uint cmj_hash(inout uint i, uint p)
{
    i ^= p;
    i ^= (i >> uint(17));
    i ^= (i >> uint(10));
    i *= 3009754341u;
    i ^= (i >> uint(12));
    i ^= (i >> uint(21));
    i *= 2482784149u;
    i ^= 3748540543u;
    i ^= (i >> uint(17));
    i *= (1u | (p >> uint(18)));
    return i;
}

float cmj_randfloat(uint i, uint p)
{
    uint param = i;
    uint param_1 = p;
    uint _1399 = cmj_hash(param, param_1);
    return float(_1399) * 2.3283061589829401327733648940921e-10;
}

uint cmj_hash_simple(inout uint i, uint p)
{
    i = (i ^ 61u) ^ p;
    i += (i << uint(3));
    i ^= (i >> uint(4));
    i *= 668265261u;
    return i;
}

vec2 pmj_sample_2D(int sample_rsv, int rng_hash, int dimension)
{
    if (sample_rsv >= 4096)
    {
        int p = rng_hash + dimension;
        uint param = uint(sample_rsv);
        uint param_1 = uint(p);
        float fx = cmj_randfloat(param, param_1);
        uint param_2 = uint(sample_rsv);
        uint param_3 = uint(p + 1);
        float fy = cmj_randfloat(param_2, param_3);
        return vec2(fx, fy);
    }
    else
    {
        int index = ((((dimension % 48) * 64) * 64) + sample_rsv) * 2;
        uint param_4 = uint(dimension);
        uint param_5 = uint(rng_hash);
        uint _1682 = cmj_hash_simple(param_4, param_5);
        uint maskx = _1682 & 8388607u;
        uint param_6 = uint(dimension + 1);
        uint param_7 = uint(rng_hash);
        uint _1692 = cmj_hash_simple(param_6, param_7);
        uint masky = _1692 & 8388607u;
        float fx_1 = uintBitsToFloat(push.data_ptr._sample_pattern_lut.data[index] ^ maskx) - 1.0;
        float fy_1 = uintBitsToFloat(push.data_ptr._sample_pattern_lut.data[index + 1] ^ masky) - 1.0;
        return vec2(fx_1, fy_1);
    }
}

int cmj_isqrt(int value)
{
    return int(sqrt(float(value)));
}

uint clz8(uint8_t x)
{
    uint upper = uint(x >> uint8_t(4));
    uint lower = uint(x & uint8_t(15));
    uint _720;
    if (upper != 0u)
    {
        _720 = _725[upper];
    }
    else
    {
        _720 = 4u + _725[lower];
    }
    return _720;
}

uint clz16(uint16_t x)
{
    uint8_t upper = uint8_t(x >> 8us);
    uint8_t lower = uint8_t(x & 255us);
    uint _754;
    if (int(uint(upper)) != 0)
    {
        uint8_t param = upper;
        _754 = clz8(param);
    }
    else
    {
        uint8_t param_1 = lower;
        _754 = 8u + clz8(param_1);
    }
    return _754;
}

uint count_leading_zeros(uint x)
{
    uint16_t upper = uint16_t(x >> 16u);
    uint16_t lower = uint16_t(x & 65535u);
    uint _781;
    if (int(uint(upper)) != 0)
    {
        uint16_t param = upper;
        _781 = clz16(param);
    }
    else
    {
        uint16_t param_1 = lower;
        _781 = 16u + clz16(param_1);
    }
    return _781;
}

uint cmj_w_mask(uint w)
{
    if (!(w > 1u))
    {
        // unimplemented ext op 12
    }
    uint param = w;
    return uint((1 << int(32u - count_leading_zeros(param))) - 1);
}

uint cmj_permute(inout uint i, uint l, uint p)
{
    uint w = l - 1u;
    if ((l & w) == 0u)
    {
        i ^= p;
        i *= 3782248765u;
        i ^= (p >> uint(16));
        i ^= ((i & w) >> uint(4));
        i ^= (p >> uint(8));
        i *= 153742143u;
        i ^= (p >> uint(23));
        i ^= ((i & w) >> uint(1));
        i *= (1u | (p >> uint(27)));
        i *= 1765145193u;
        i ^= ((i & w) >> uint(11));
        i *= 1960620803u;
        i ^= ((i & w) >> uint(2));
        i *= 2656050371u;
        i ^= ((i & w) >> uint(2));
        i *= 3361776607u;
        i &= w;
        i ^= (i >> uint(5));
        return (i + p) & w;
    }
    else
    {
        uint param = w;
        w = cmj_w_mask(param);
        do
        {
            i ^= p;
            i *= 3782248765u;
            i ^= (p >> uint(16));
            i ^= ((i & w) >> uint(4));
            i ^= (p >> uint(8));
            i *= 153742143u;
            i ^= (p >> uint(23));
            i ^= ((i & w) >> uint(1));
            i *= (1u | (p >> uint(27)));
            i *= 1765145193u;
            i ^= ((i & w) >> uint(11));
            i *= 1960620803u;
            i ^= ((i & w) >> uint(2));
            i *= 2656050371u;
            i ^= ((i & w) >> uint(2));
            i *= 3361776607u;
            i &= w;
            i ^= (i >> uint(5));
        } while (i >= l);
        return (i + p) % l;
    }
}

bool cmj_is_pow2(int i)
{
    bool _1099 = i > 1;
    bool _1107;
    if (_1099)
    {
        _1107 = (i & (i - 1)) == 0;
    }
    else
    {
        _1107 = _1099;
    }
    return _1107;
}

uint count_trailing_zeros(uint x)
{
    uint param = x & (-x);
    return 31u - count_leading_zeros(param);
}

int cmj_fast_div_pow2(int a, int b)
{
    if (!(b > 1))
    {
        // unimplemented ext op 12
    }
    uint param = uint(b);
    return a >> int(count_trailing_zeros(param));
}

int cmj_fast_mod_pow2(int a, int b)
{
    return a & (b - 1);
}

void cmj_sample_2D(inout int s, int N, int p, out float fx, out float fy)
{
    if (!(s < N))
    {
        // unimplemented ext op 12
    }
    int param = N;
    int m = cmj_isqrt(param);
    int n = ((N - 1) / m) + 1;
    float invN = 1.0 / float(N);
    float invm = 1.0 / float(m);
    float invn = 1.0 / float(n);
    uint param_1 = uint(s);
    uint param_2 = uint(N);
    uint param_3 = uint(p * 1365458477);
    uint _1495 = cmj_permute(param_1, param_2, param_3);
    s = int(_1495);
    int param_4 = m;
    int sdivm;
    int smodm;
    if (cmj_is_pow2(param_4))
    {
        int param_5 = s;
        int param_6 = m;
        sdivm = cmj_fast_div_pow2(param_5, param_6);
        int param_7 = s;
        int param_8 = m;
        smodm = cmj_fast_mod_pow2(param_7, param_8);
    }
    else
    {
        sdivm = s / m;
        smodm = s - (sdivm * m);
    }
    uint param_9 = uint(smodm);
    uint param_10 = uint(m);
    uint param_11 = uint(p * 1757159915);
    uint _1534 = cmj_permute(param_9, param_10, param_11);
    uint sx = _1534;
    uint param_12 = uint(sdivm);
    uint param_13 = uint(n);
    uint param_14 = uint(p * 48610963);
    uint _1547 = cmj_permute(param_12, param_13, param_14);
    uint sy = _1547;
    uint param_15 = uint(s);
    uint param_16 = uint(p * (-1770354533));
    float jx = cmj_randfloat(param_15, param_16);
    uint param_17 = uint(s);
    uint param_18 = uint(p * 915196087);
    float jy = cmj_randfloat(param_17, param_18);
    fx = (float(sx) + ((float(sy) + jx) * invn)) * invm;
    fy = (float(s) + jy) * invN;
}

float pmj_sample_1D(int sample_rsv, int rng_hash, int dimension)
{
    if (sample_rsv >= 4096)
    {
        int p = rng_hash + dimension;
        uint param = uint(sample_rsv);
        uint param_1 = uint(p);
        return cmj_randfloat(param, param_1);
    }
    else
    {
        uint param_2 = uint(dimension);
        uint param_3 = uint(rng_hash);
        uint _1609 = cmj_hash_simple(param_2, param_3);
        uint mask_rsv = _1609 & 8388607u;
        int index = ((((dimension % 48) * 64) * 64) + sample_rsv) * 2;
        return uintBitsToFloat(push.data_ptr._sample_pattern_lut.data[index] ^ mask_rsv) - 1.0;
    }
}

float cmj_sample_1D(int s, int N, int p)
{
    if (!(s < N))
    {
        // unimplemented ext op 12
    }
    uint param = uint(s);
    uint param_1 = uint(N);
    uint param_2 = uint(p * 1757159915);
    uint _1425 = cmj_permute(param, param_1, param_2);
    uint x = _1425;
    uint param_3 = uint(s);
    uint param_4 = uint(p * (-1770354533));
    float jx = cmj_randfloat(param_3, param_4);
    float invN = 1.0 / float(N);
    return (float(x) + jx) * invN;
}

uint find_first_set(uint x)
{
    uint _807;
    if (x != 0u)
    {
        uint param = x & (-x);
        _807 = 32u - count_leading_zeros(param);
    }
    else
    {
        _807 = 0u;
    }
    return _807;
}

uint sobol_dimension(int index, int dimension)
{
    uint result = 0u;
    uint i = uint(index + 64);
    int j = 0;
    int x;
    for (;;)
    {
        uint param = i;
        uint _1738 = find_first_set(param);
        int _1739 = int(_1738);
        x = _1739;
        if (_1739 != int(0u))
        {
            j += x;
            result ^= push.data_ptr._sample_pattern_lut.data[((32 * dimension) + j) - 1];
            i = i >> uint(x);
            continue;
        }
        else
        {
            break;
        }
    }
    return result;
}

float path_rng_1D(uint rng_hash, int sample_rsv, int num_samples, int dimension)
{
    if (uint(_1776.kernel_data.integrator.sampling_pattern) == 2u)
    {
        int param = sample_rsv;
        int param_1 = int(rng_hash);
        int param_2 = dimension;
        return pmj_sample_1D(param, param_1, param_2);
    }
    if (uint(_1776.kernel_data.integrator.sampling_pattern) == 1u)
    {
        int p = int(rng_hash + uint(dimension));
        int param_3 = sample_rsv;
        int param_4 = num_samples;
        int param_5 = p;
        return cmj_sample_1D(param_3, param_4, param_5);
    }
    int param_6 = sample_rsv;
    int param_7 = dimension;
    uint result = sobol_dimension(param_6, param_7);
    float r = float(result) * 2.3283064365386962890625e-10;
    uint param_8 = uint(dimension);
    uint param_9 = rng_hash;
    uint _1831 = cmj_hash_simple(param_8, param_9);
    uint tmp_rng = _1831;
    float shift = float(tmp_rng) * 2.3283064365386962890625e-10;
    return (r + shift) - floor(r + shift);
}

void path_rng_2D(uint rng_hash, int sample_rsv, int num_samples, int dimension, inout float fx, inout float fy)
{
    if (uint(_1776.kernel_data.integrator.sampling_pattern) == 2u)
    {
        int param = sample_rsv;
        int param_1 = int(rng_hash);
        int param_2 = dimension;
        vec2 f = pmj_sample_2D(param, param_1, param_2);
        fx = f.x;
        fy = f.y;
        return;
    }
    if (uint(_1776.kernel_data.integrator.sampling_pattern) == 1u)
    {
        int p = int(rng_hash + uint(dimension));
        int param_3 = sample_rsv;
        int param_4 = num_samples;
        int param_5 = p;
        float param_6 = fx;
        float param_7 = fy;
        cmj_sample_2D(param_3, param_4, param_5, param_6, param_7);
        fx = param_6;
        fy = param_7;
        return;
    }
    uint param_8 = rng_hash;
    int param_9 = sample_rsv;
    int param_10 = num_samples;
    int param_11 = dimension;
    fx = path_rng_1D(param_8, param_9, param_10, param_11);
    uint param_12 = rng_hash;
    int param_13 = sample_rsv;
    int param_14 = num_samples;
    int param_15 = dimension + 1;
    fy = path_rng_1D(param_12, param_13, param_14, param_15);
}

void path_state_rng_2D(PathState STATE, int dimension, inout float fx, inout float fy)
{
    uint param = STATE.rng_hash;
    int param_1 = STATE.sample_rsv;
    int param_2 = STATE.num_samples;
    int param_3 = STATE.rng_offset + dimension;
    float param_4 = fx;
    float param_5 = fy;
    path_rng_2D(param, param_1, param_2, param_3, param_4, param_5);
    fx = param_4;
    fy = param_5;
}

float compatible_powf(float x, float y)
{
    if (y == 0.0)
    {
        return 1.0;
    }
    if (x < 0.0)
    {
        if (mod(-y, 2.0) == 0.0)
        {
            return pow(-x, y);
        }
        else
        {
            return -pow(-x, y);
        }
    }
    else
    {
        if (x == 0.0)
        {
            return 0.0;
        }
    }
    return pow(x, y);
}

float safe_powf(float a, float b)
{
    bool _684 = a < 0.0;
    bool _692;
    if (_684)
    {
        _692 = !(b == float(int(b)));
    }
    else
    {
        _692 = _684;
    }
    if (_692)
    {
        return 0.0;
    }
    float param = a;
    float param_1 = b;
    return compatible_powf(param, param_1);
}

float single_peaked_henyey_greenstein(float cos_theta, float g)
{
    float param = (1.0 + (g * g)) - ((2.0 * g) * cos_theta);
    float param_1 = 1.5;
    return ((1.0 - (g * g)) / safe_powf(param, param_1)) * 0.079577468335628509521484375;
}

vec3 henyey_greenstrein_sample(vec3 D, float g, float randu, float randv, inout float pdf)
{
    bool isotropic = abs(g) < 0.001000000047497451305389404296875;
    float cos_theta;
    if (isotropic)
    {
        cos_theta = 1.0 - (2.0 * randu);
        if (!(pdf == 3.4028234663852885981170418348452e+38))
        {
            pdf = 0.079577468335628509521484375;
        }
    }
    else
    {
        float k = (1.0 - (g * g)) / ((1.0 - g) + ((2.0 * g) * randu));
        cos_theta = ((1.0 + (g * g)) - (k * k)) / (2.0 * g);
        if (!(pdf == 3.4028234663852885981170418348452e+38))
        {
            float param = cos_theta;
            float param_1 = g;
            pdf = single_peaked_henyey_greenstein(param, param_1);
        }
    }
    float param_2 = 1.0 - (cos_theta * cos_theta);
    float sin_theta = safe_sqrtf(param_2);
    float phi = 6.283185482025146484375 * randv;
    vec3 dir = vec3(sin_theta * cos(phi), sin_theta * sin(phi), cos_theta);
    vec3 param_3 = D;
    vec3 T;
    vec3 param_4 = T;
    vec3 param_5;
    make_orthonormals(param_3, param_4, param_5);
    T = param_4;
    vec3 B = param_5;
    dir = ((T * dir.x) + (B * dir.y)) + (D * dir.z);
    return dir;
}

float path_state_rng_1D(int dimension)
{
    uint param = state.rng_hash;
    int param_1 = state.sample_rsv;
    int param_2 = state.num_samples;
    int param_3 = state.rng_offset + dimension;
    return path_rng_1D(param, param_1, param_2, param_3);
}

int kernel_volume_sample_channel(vec3 albedo, vec3 throughput, float rand, out vec3 pdf)
{
    vec3 weights = abs(throughput * albedo);
    float sum_weights = (weights.x + weights.y) + weights.z;
    vec3 weights_pdf;
    if (sum_weights > 0.0)
    {
        weights_pdf = weights / vec3(sum_weights);
    }
    else
    {
        weights_pdf = vec3(0.3333333432674407958984375);
    }
    pdf = weights_pdf;
    if (rand < weights_pdf.x)
    {
        return 0;
    }
    else
    {
        if (rand < (weights_pdf.x + weights_pdf.y))
        {
            return 1;
        }
        else
        {
            return 2;
        }
    }
}

float kernel_volume_channel_get(vec3 value, int channel)
{
    float _3117;
    if (channel == 0)
    {
        _3117 = value.x;
    }
    else
    {
        float _3125;
        if (channel == 1)
        {
            _3125 = value.y;
        }
        else
        {
            _3125 = value.z;
        }
        _3117 = _3125;
    }
    return _3117;
}

vec3 exp3(vec3 v)
{
    return vec3(exp(v.x), exp(v.y), exp(v.z));
}

vec3 volume_color_transmittance(vec3 sigma, float t)
{
    vec3 param = (-sigma) * t;
    return exp3(param);
}

float max3(vec3 a)
{
    return max(max(a.x, a.y), a.z);
}

bool subsurface_random_walk(int scN, float bssrdf_u, float bssrdf_v)
{
    float param = bssrdf_u;
    float param_1 = bssrdf_v;
    vec3 D;
    vec3 param_2 = D;
    float pdf;
    float param_3 = pdf;
    sample_cos_hemisphere(-GSD.Ng, param, param_1, param_2, param_3);
    D = param_2;
    pdf = param_3;
    if (dot(-GSD.Ng, D) <= 0.0)
    {
        return false;
    }
    vec3 throughput = vec3(1.0);
    int param_4 = scN;
    vec3 sigma_t;
    vec3 param_5 = sigma_t;
    vec3 sigma_s;
    vec3 param_6 = sigma_s;
    vec3 param_7 = throughput;
    subsurface_random_walk_coefficients(param_4, param_5, param_6, param_7);
    sigma_t = param_5;
    sigma_s = param_6;
    throughput = param_7;
    vec3 param_8 = GSD.P;
    vec3 param_9 = -GSD.Ng;
    ss_isect.ray.P = ray_offset(param_8, param_9);
    ss_isect.ray.D = D;
    ss_isect.ray.t = 3.4028234663852885981170418348452e+38;
    ss_isect.ray.time = GSD.time;
    uint prev_rng_offset = uint(state.rng_offset);
    uint prev_rng_hash = state.rng_hash;
    uint param_10 = state.rng_hash + uint(state.rng_offset);
    uint param_11 = 3735928559u;
    uint _4096 = cmj_hash(param_10, param_11);
    state.rng_hash = _4096;
    bool hit = false;
    float scatter_u;
    float scatter_v;
    vec3 channel_pdf;
    vec3 _4220;
    vec3 _4231;
    for (int bounce = 0; bounce < 256; bounce++)
    {
        state.rng_hash += 8u;
        if (bounce > 0)
        {
            PathState param_12 = state;
            int param_13 = 0;
            float param_14 = scatter_u;
            float param_15 = scatter_v;
            path_state_rng_2D(param_12, param_13, param_14, param_15);
            scatter_u = param_14;
            scatter_v = param_15;
            vec3 param_16 = ss_isect.ray.D;
            float param_17 = 0.0;
            float param_18 = scatter_u;
            float param_19 = scatter_v;
            float param_20 = null_flt;
            vec3 _4138 = henyey_greenstrein_sample(param_16, param_17, param_18, param_19, param_20);
            null_flt = param_20;
            ss_isect.ray.D = _4138;
        }
        int param_21 = 6;
        float rphase = path_state_rng_1D(param_21);
        vec3 param_22 = sigma_s;
        vec3 param_23 = sigma_t;
        vec3 albedo = safe_divide_color(param_22, param_23);
        vec3 param_24 = albedo;
        vec3 param_25 = throughput;
        float param_26 = rphase;
        vec3 param_27 = channel_pdf;
        int _4160 = kernel_volume_sample_channel(param_24, param_25, param_26, param_27);
        channel_pdf = param_27;
        int channel = _4160;
        int param_28 = 7;
        float rdist = path_state_rng_1D(param_28);
        vec3 param_29 = sigma_t;
        int param_30 = channel;
        float sample_sigma_t = kernel_volume_channel_get(param_29, param_30);
        float t = (-log(1.0 - rdist)) / sample_sigma_t;
        ss_isect.ray.t = t;
        uint null = 4294967295u;
        int param_31 = GSD.object;
        uint param_32 = null;
        int param_33 = 1;
        bool _4187 = scene_intersect_local(param_31, param_32, param_33);
        null = param_32;
        hit = linfo.num_hits > 0;
        if (hit)
        {
            t = push.pool2_ptr.pool_is.data[linfo.offset].t;
        }
        ss_isect.ray.P += (ss_isect.ray.D * t);
        vec3 param_34 = sigma_t;
        float param_35 = t;
        vec3 transmittance = volume_color_transmittance(param_34, param_35);
        if (hit)
        {
            _4220 = transmittance;
        }
        else
        {
            _4220 = sigma_t * transmittance;
        }
        float pdf_1 = dot(channel_pdf, _4220);
        if (hit)
        {
            _4231 = transmittance;
        }
        else
        {
            _4231 = sigma_s * transmittance;
        }
        throughput *= (_4231 / vec3(pdf_1));
        if (hit)
        {
            break;
        }
        int param_36 = 5;
        float terminate = path_state_rng_1D(param_36);
        vec3 param_37 = abs(throughput);
        float probability = min(max3(param_37), 1.0);
        if (terminate >= probability)
        {
            break;
        }
        throughput /= vec3(probability);
    }
    float param_38 = throughput.x;
    bool _4273 = isfinite_safe(param_38);
    bool _4280;
    if (_4273)
    {
        float param_39 = throughput.y;
        _4280 = isfinite_safe(param_39);
    }
    else
    {
        _4280 = _4273;
    }
    bool _4287;
    if (_4280)
    {
        float param_40 = throughput.z;
        _4287 = isfinite_safe(param_40);
    }
    else
    {
        _4287 = _4280;
    }
    if (!_4287)
    {
        // unimplemented ext op 12
    }
    state.rng_offset = int(prev_rng_offset);
    state.rng_hash = prev_rng_hash;
    if (!hit)
    {
        return false;
    }
    int idx = (linfo.offset + 4) + 0;
    push.pool2_ptr.pool_is.data[idx].t = throughput.x;
    push.pool2_ptr.pool_is.data[idx].u = throughput.y;
    push.pool2_ptr.pool_is.data[idx].v = throughput.z;
    return true;
}

int subsurface_scatter_multi_intersect(int scN, inout uint lcg_state, inout float bssrdf_u, inout float bssrdf_v, bool _all)
{
    bool _4341 = push.pool1_ptr.pool_sc.data[scN].type >= 34u;
    bool _4352;
    if (_4341)
    {
        _4352 = push.pool1_ptr.pool_sc.data[scN].type <= 37u;
    }
    else
    {
        _4352 = _4341;
    }
    if (_4352)
    {
        int param = scN;
        uint param_1 = lcg_state;
        float param_2 = bssrdf_u;
        float param_3 = bssrdf_v;
        bool param_4 = _all;
        int _4365 = subsurface_scatter_disk(param, param_1, param_2, param_3, param_4);
        lcg_state = param_1;
        return _4365;
    }
    else
    {
        int param_5 = scN;
        float param_6 = bssrdf_u;
        float param_7 = bssrdf_v;
        bool _4375 = subsurface_random_walk(param_5, param_6, param_7);
        bssrdf_u = param_6;
        bssrdf_v = param_7;
        return int(_4375);
    }
}

void main()
{
    null_flt = 3.4028234663852885981170418348452e+38;
    null_flt2 = vec2(3.4028234663852885981170418348452e+38);
    null_flt3 = vec4(3.4028234663852885981170418348452e+38);
    null_flt4 = vec4(3.4028234663852885981170418348452e+38);
    null_int = -2147483648;
    INTERPOLATION_NONE = 4294967295u;
    INTERPOLATION_LINEAR = 0u;
    INTERPOLATION_CLOSEST = 1u;
    INTERPOLATION_CUBIC = 2u;
    INTERPOLATION_SMART = 3u;
    INTERPOLATION_NUM_TYPES = 4u;
    IMAGE_DATA_TYPE_FLOAT4 = 0u;
    IMAGE_DATA_TYPE_BYTE4 = 1u;
    IMAGE_DATA_TYPE_HALF4 = 2u;
    IMAGE_DATA_TYPE_FLOAT = 3u;
    IMAGE_DATA_TYPE_BYTE = 4u;
    IMAGE_DATA_TYPE_HALF = 5u;
    IMAGE_DATA_TYPE_USHORT4 = 6u;
    IMAGE_DATA_TYPE_USHORT = 7u;
    IMAGE_DATA_NUM_TYPES = 8u;
    IMAGE_ALPHA_UNASSOCIATED = 0u;
    IMAGE_ALPHA_ASSOCIATED = 1u;
    IMAGE_ALPHA_CHANNEL_PACKED = 2u;
    IMAGE_ALPHA_IGNORE = 3u;
    IMAGE_ALPHA_AUTO = 4u;
    IMAGE_ALPHA_NUM_TYPES = 5u;
    EXTENSION_REPEAT = 0u;
    EXTENSION_EXTEND = 1u;
    EXTENSION_CLIP = 2u;
    EXTENSION_NUM_TYPES = 3u;
    G_dump = false;
    rec_num = 0;
    Dpixel = _459.kg.pixel;
    if (linfo.max_hits < 0)
    {
        rec_num = 0;
        G_dump = false;
        if (all(equal(Dpixel, gl_LaunchIDNV.xy)))
        {
            G_dump = true;
            G_use_light_pass = _1776.kernel_data.film.use_light_pass != int(0u);
        }
        rec_num = linfo.num_hits;
        int idx = linfo.offset;
        GSD.Ng = vec3(push.pool2_ptr.pool_is.data[idx].t, push.pool2_ptr.pool_is.data[idx].u, push.pool2_ptr.pool_is.data[idx].v);
        GSD.time = intBitsToFloat(push.pool2_ptr.pool_is.data[idx].prim);
        GSD.object = push.pool2_ptr.pool_is.data[idx].object;
        GSD.type = push.pool2_ptr.pool_is.data[idx].type;
        idx++;
        GSD.P = vec3(push.pool2_ptr.pool_is.data[idx].t, push.pool2_ptr.pool_is.data[idx].u, push.pool2_ptr.pool_is.data[idx].v);
        float bssrdf_u = intBitsToFloat(push.pool2_ptr.pool_is.data[idx].prim);
        float bssrdf_v = intBitsToFloat(push.pool2_ptr.pool_is.data[idx].object);
        int scN = push.pool2_ptr.pool_is.data[idx].type;
        idx++;
        GSD.dP.dx = vec3(push.pool2_ptr.pool_is.data[idx].t, push.pool2_ptr.pool_is.data[idx].u, push.pool2_ptr.pool_is.data[idx].v);
        GSD.num_closure = push.pool2_ptr.pool_is.data[idx].type;
        idx++;
        GSD.dP.dy = vec3(push.pool2_ptr.pool_is.data[idx].t, push.pool2_ptr.pool_is.data[idx].u, push.pool2_ptr.pool_is.data[idx].v);
        uint lcg_state = linfo.lcg_state;
        int offset = linfo.offset;
        GSD.alloc_offset = (offset + GSD.num_closure) - 1;
        int param = scN;
        uint param_1 = lcg_state;
        float param_2 = bssrdf_u;
        float param_3 = bssrdf_v;
        bool param_4 = false;
        int _4585 = subsurface_scatter_multi_intersect(param, param_1, param_2, param_3, param_4);
        lcg_state = param_1;
        int num_hit = _4585;
        int idx_1 = offset + 4;
        push.pool2_ptr.pool_is.data[idx_1].prim = num_hit;
        if (num_hit > 0)
        {
            linfo.offset = floatBitsToInt(ss_isect.ray.P.x);
            linfo.max_hits = floatBitsToInt(ss_isect.ray.P.y);
            linfo.lcg_state = floatBitsToUint(ss_isect.ray.P.z);
            linfo.num_hits = floatBitsToInt(ss_isect.ray.D.x);
            linfo.local_object = floatBitsToInt(ss_isect.ray.D.y);
            linfo.type = floatBitsToInt(ss_isect.ray.D.z);
        }
    }
}

