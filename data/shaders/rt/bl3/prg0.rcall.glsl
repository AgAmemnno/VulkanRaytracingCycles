#version 460
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
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

struct differential3
{
    vec4 dx;
    vec4 dy;
};

struct Ray
{
    float t;
    float time;
    vec4 P;
    vec4 D;
    differential3 dP;
    differential3 dD;
};

struct KernelGlobals_PROF
{
    uvec2 pixel;
    vec4 f3[960];
    float f1[960];
    uint u1[960];
};

struct differential
{
    float dx;
    float dy;
};

struct ShaderData
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
    Transform ob_tfm;
    Transform ob_itfm;
    int geometry;
    vec4 closure_emission_background;
    vec4 closure_transparent_extinction;
    int atomic_offset;
    int alloc_offset;
};

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

struct KernelLightDistribution
{
    float totarea;
    int prim;
    float data[2];
};

struct KernelLight
{
    int type;
    float co[3];
    int shader_id;
    int samples;
    float max_bounces;
    float random;
    float strength[3];
    float pad1;
    Transform tfm;
    Transform itfm;
    float uni[12];
};

struct KernelParticle
{
    int index;
    float age;
    float lifetime;
    float size;
    vec4 rotation;
    vec4 location;
    vec4 velocity;
    vec4 angular_velocity;
};

struct KernelShader
{
    float constant_emission[3];
    float cryptomatte_id;
    int flags;
    int pass_id;
    int pad2;
    int pad3;
};

struct TextureInfo
{
    uint64_t data;
    uint data_type;
    uint cl_buffer;
    uint interpolation;
    uint extension;
    uint width;
    uint height;
    uint depth;
    uint use_transform_3d;
    Transform transform_3d;
    uint pad[2];
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

struct args_sd
{
    vec4 P;
    vec4 N;
    vec4 Ng;
    vec4 I;
    int flag;
    int type;
    int object;
    int num_closure;
    int atomic_offset;
    float time;
    float ray_length;
    int alloc_offset;
    float pad0;
    uint lcg_state;
    float pad1;
    differential3 dI;
};

struct args_acc_light
{
    vec4 emission;
    vec4 direct_emission;
    vec4 indirect;
    vec4 path_total;
    vec4 throughput;
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

struct PRG2ARG
{
    args_sd sd;
    args_acc_light L;
    int use_light_pass;
    int type;
    Ray ray;
    PathState state;
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer ShaderClosurePool;
layout(buffer_reference) buffer _prim_tri_verts2_;
layout(buffer_reference) buffer _prim_tri_index_;
layout(buffer_reference) buffer _prim_type_;
layout(buffer_reference) buffer _prim_visibility_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer _objects_;
layout(buffer_reference) buffer _object_flag_;
layout(buffer_reference) buffer _object_volume_step_;
layout(buffer_reference) buffer _patches_;
layout(buffer_reference) buffer _attributes_map_;
layout(buffer_reference) buffer _attributes_float_;
layout(buffer_reference) buffer _attributes_float2_;
layout(buffer_reference) buffer _attributes_float3_;
layout(buffer_reference) buffer _attributes_uchar4_;
layout(buffer_reference) buffer _tri_shader_;
layout(buffer_reference) buffer _tri_vnormal_;
layout(buffer_reference) buffer _tri_vindex2_;
layout(buffer_reference) buffer _tri_patch_;
layout(buffer_reference) buffer _tri_patch_uv_;
layout(buffer_reference) buffer _light_distribution_;
layout(buffer_reference) buffer _lights_;
layout(buffer_reference) buffer _light_background_marginal_cdf_;
layout(buffer_reference) buffer _light_background_conditional_cdf_;
layout(buffer_reference) buffer _particles_;
layout(buffer_reference) buffer _svm_nodes_;
layout(buffer_reference) buffer _shaders_;
layout(buffer_reference) buffer _lookup_table_;
layout(buffer_reference) buffer _sample_pattern_lut_;
layout(buffer_reference) buffer _texture_info_;
layout(buffer_reference) buffer pool_sc_;
layout(buffer_reference, std430) buffer KernelTextures
{
    _prim_tri_verts2_ _prim_tri_verts2;
    _prim_tri_index_ _prim_tri_index;
    _prim_type_ _prim_type;
    _prim_visibility_ _prim_visibility;
    _prim_index_ _prim_index;
    _prim_object_ _prim_object;
    _objects_ _objects;
    _object_flag_ _object_flag;
    _object_volume_step_ _object_volume_step;
    _patches_ _patches;
    _attributes_map_ _attributes_map;
    _attributes_float_ _attributes_float;
    _attributes_float2_ _attributes_float2;
    _attributes_float3_ _attributes_float3;
    _attributes_uchar4_ _attributes_uchar4;
    _tri_shader_ _tri_shader;
    _tri_vnormal_ _tri_vnormal;
    _tri_vindex2_ _tri_vindex2;
    _tri_patch_ _tri_patch;
    _tri_patch_uv_ _tri_patch_uv;
    _light_distribution_ _light_distribution;
    _lights_ _lights;
    _light_background_marginal_cdf_ _light_background_marginal_cdf;
    _light_background_conditional_cdf_ _light_background_conditional_cdf;
    _particles_ _particles;
    _svm_nodes_ _svm_nodes;
    _shaders_ _shaders;
    _lookup_table_ _lookup_table;
    _sample_pattern_lut_ _sample_pattern_lut;
    _texture_info_ _texture_info;
};

layout(buffer_reference, std430) buffer ShaderClosurePool
{
    pool_sc_ pool_sc;
};

layout(buffer_reference, std430) readonly buffer _prim_tri_verts2_
{
    vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _prim_tri_index_
{
    uint data[];
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

layout(buffer_reference, std430) readonly buffer _objects_
{
    KernelObject data[];
};

layout(buffer_reference, std430) readonly buffer _object_flag_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _object_volume_step_
{
    float data[];
};

layout(buffer_reference, std430) readonly buffer _patches_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_map_
{
    uvec4 data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_float_
{
    float data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_float2_
{
    vec2 data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_float3_
{
    vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _attributes_uchar4_
{
    u8vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _tri_shader_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _tri_vnormal_
{
    vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _tri_vindex2_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _tri_patch_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _tri_patch_uv_
{
    vec2 data[];
};

layout(buffer_reference, std430) readonly buffer _light_distribution_
{
    KernelLightDistribution data[];
};

layout(buffer_reference, std430) readonly buffer _lights_
{
    KernelLight data[];
};

layout(buffer_reference, std430) readonly buffer _light_background_marginal_cdf_
{
    vec2 data[];
};

layout(buffer_reference, std430) readonly buffer _light_background_conditional_cdf_
{
    vec2 data[];
};

layout(buffer_reference, std430) readonly buffer _particles_
{
    KernelParticle data[];
};

layout(buffer_reference, std430) readonly buffer _svm_nodes_
{
    uvec4 data[];
};

layout(buffer_reference, std430) readonly buffer _shaders_
{
    KernelShader data[];
};

layout(buffer_reference, std430) readonly buffer _lookup_table_
{
    float data[];
};

layout(buffer_reference, std430) readonly buffer _sample_pattern_lut_
{
    uint data[];
};

layout(buffer_reference, scalar) readonly buffer _texture_info_
{
    TextureInfo data[];
};

layout(buffer_reference, scalar) readonly buffer pool_sc_
{
    ShaderClosure data[];
};

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals_PROF kg;
} _580;

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _3116;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _6346;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    ShaderClosurePool pool_ptr;
} push;

layout(location = 1) callableDataNV ShaderData sd;
layout(location = 0) callableDataInNV PRG2ARG pay;

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
int PROFI_IDX;
bool G_use_light_pass;
ShaderClosure null_sc;

vec4 normalize_len(vec4 a, inout float t)
{
    t = length(a.xyz);
    float x = 1.0 / t;
    return vec4(a.xyz * x, 0.0);
}

float len_squared(vec4 a)
{
    return dot(a.xyz, a.xyz);
}

bool ray_aligned_disk_intersect(vec4 ray_P, vec4 ray_D, float ray_t, vec4 disk_P, float disk_radius, inout vec4 isect_P, inout float isect_t)
{
    float disk_t;
    float param = disk_t;
    vec4 _1134 = normalize_len(ray_P - disk_P, param);
    disk_t = param;
    vec4 disk_N = _1134;
    float div = dot(ray_D.xyz, disk_N.xyz);
    if (div == 0.0)
    {
        return false;
    }
    float t = (-disk_t) / div;
    if ((t < 0.0) || (t > ray_t))
    {
        return false;
    }
    vec4 P = ray_P + (ray_D * t);
    if (len_squared(P - disk_P) > (disk_radius * disk_radius))
    {
        return false;
    }
    isect_P = P;
    isect_t = t;
    return true;
}

float smoothstepf(float f)
{
    float ff = f * f;
    return (3.0 * ff) - ((2.0 * ff) * f);
}

float spot_light_attenuation(vec4 dir, float spot_angle, float spot_smooth, vec4 N)
{
    float attenuation = dot(dir.xyz, N.xyz);
    if (attenuation <= spot_angle)
    {
        attenuation = 0.0;
    }
    else
    {
        float t = attenuation - spot_angle;
        if ((t < spot_smooth) && (!(spot_smooth == 0.0)))
        {
            float param = t / spot_smooth;
            attenuation *= smoothstepf(param);
        }
    }
    return attenuation;
}

float safe_acosf(float a)
{
    return acos(clamp(a, -1.0, 1.0));
}

vec2 map_to_sphere(vec4 co)
{
    float l = length(co.xyz);
    float u;
    float v;
    if (l > 0.0)
    {
        bool _881 = co.x == 0.0;
        bool _886;
        if (_881)
        {
            _886 = co.y == 0.0;
        }
        else
        {
            _886 = _881;
        }
        if (_886)
        {
            u = 0.0;
        }
        else
        {
            u = (1.0 - (atan(co.x, co.y) / 3.1415927410125732421875)) / 2.0;
        }
        float param = co.z / l;
        v = 1.0 - (safe_acosf(param) / 3.1415927410125732421875);
    }
    else
    {
        v = 0.0;
        u = 0.0;
    }
    return vec2(u, v);
}

float lamp_light_pdf(vec4 Ng, vec4 I, float t)
{
    float cos_pi = dot(Ng.xyz, I.xyz);
    if (cos_pi <= 0.0)
    {
        return 0.0;
    }
    return (t * t) / cos_pi;
}

bool ray_quad_intersect(vec4 ray_P, vec4 ray_D, float ray_mint, float ray_maxt, vec4 quad_P, vec4 quad_u, vec4 quad_v, vec4 quad_n, inout vec4 isect_P, inout float isect_t, inout float isect_u, inout float isect_v, bool ellipse)
{
    float t = (-(dot(ray_P.xyz, quad_n.xyz) - dot(quad_P.xyz, quad_n.xyz))) / dot(ray_D.xyz, quad_n.xyz);
    if ((t < ray_mint) || (t > ray_maxt))
    {
        return false;
    }
    vec4 hit = ray_P + (ray_D * t);
    vec4 inplane = hit - quad_P;
    float u = dot(inplane.xyz, quad_u.xyz) / dot(quad_u.xyz, quad_u.xyz);
    if ((u < (-0.5)) || (u > 0.5))
    {
        return false;
    }
    float v = dot(inplane.xyz, quad_v.xyz) / dot(quad_v.xyz, quad_v.xyz);
    if ((v < (-0.5)) || (v > 0.5))
    {
        return false;
    }
    bool _1436;
    if (ellipse)
    {
        _1436 = ((u * u) + (v * v)) > 0.25;
    }
    else
    {
        _1436 = ellipse;
    }
    if (_1436)
    {
        return false;
    }
    if (!(isect_P.x == 3.4028234663852885981170418348452e+38))
    {
        isect_P = hit;
    }
    if (!(isect_t == 3.4028234663852885981170418348452e+38))
    {
        isect_t = t;
    }
    if (!(isect_u == 3.4028234663852885981170418348452e+38))
    {
        isect_u = u + 0.5;
    }
    if (!(isect_v == 3.4028234663852885981170418348452e+38))
    {
        isect_v = v + 0.5;
    }
    return true;
}

vec4 _cross(vec4 e1, vec4 e0)
{
    return vec4(cross(e1.xyz, e0.xyz), 0.0);
}

float rect_light_sample(vec4 P, inout vec4 light_p, vec4 axisu, vec4 axisv, float randu, float randv, bool sample_coord)
{
    vec4 corner = (light_p - (axisu * 0.5)) - (axisv * 0.5);
    float axisu_len;
    float param = axisu_len;
    vec4 _2619 = normalize_len(axisu, param);
    axisu_len = param;
    vec4 x = _2619;
    float axisv_len;
    float param_1 = axisv_len;
    vec4 _2626 = normalize_len(axisv, param_1);
    axisv_len = param_1;
    vec4 y = _2626;
    vec4 param_2 = x;
    vec4 param_3 = y;
    vec4 z = _cross(param_2, param_3);
    vec4 dir = corner - P;
    float z0 = dot(dir.xyz, z.xyz);
    if (z0 > 0.0)
    {
        z *= (-1.0);
        z0 *= (-1.0);
    }
    float x0 = dot(dir.xyz, x.xyz);
    float y0 = dot(dir.xyz, y.xyz);
    float x1 = x0 + axisu_len;
    float y1 = y0 + axisv_len;
    vec4 diff = vec4(x0, y1, x1, y0) - vec4(x1, y0, x0, y1);
    vec4 nz = vec4(y0, x1, y1, x0) * diff;
    nz /= sqrt(((diff * (z0 * z0)) * diff) + (nz * nz));
    float param_4 = (-nz.x) * nz.y;
    float g0 = safe_acosf(param_4);
    float param_5 = (-nz.y) * nz.z;
    float g1 = safe_acosf(param_5);
    float param_6 = (-nz.z) * nz.w;
    float g2 = safe_acosf(param_6);
    float param_7 = (-nz.w) * nz.x;
    float g3 = safe_acosf(param_7);
    float b0 = nz.x;
    float b1 = nz.z;
    float b0sq = b0 * b0;
    float k = (6.283185482025146484375 - g2) - g3;
    float S = (g0 + g1) - k;
    if (sample_coord)
    {
        float au = (randu * S) + k;
        float fu = ((cos(au) * b0) - b1) / sin(au);
        float cu = (1.0 / sqrt((fu * fu) + b0sq)) * ((fu > 0.0) ? 1.0 : (-1.0));
        cu = clamp(cu, -1.0, 1.0);
        float xu = (-(cu * z0)) / max(sqrt(1.0 - (cu * cu)), 1.0000000116860974230803549289703e-07);
        xu = clamp(xu, x0, x1);
        float z0sq = z0 * z0;
        float y0sq = y0 * y0;
        float y1sq = y1 * y1;
        float d = sqrt((xu * xu) + z0sq);
        float h0 = y0 / sqrt((d * d) + y0sq);
        float h1 = y1 / sqrt((d * d) + y1sq);
        float hv = h0 + (randv * (h1 - h0));
        float hv2 = hv * hv;
        float _2866;
        if (hv2 < 0.999998986721038818359375)
        {
            _2866 = (hv * d) / sqrt(1.0 - hv2);
        }
        else
        {
            _2866 = y1;
        }
        float yv = _2866;
        light_p = ((P + (x * xu)) + (y * yv)) + (z * z0);
    }
    if (!(S == 0.0))
    {
        return 1.0 / S;
    }
    else
    {
        return 0.0;
    }
}

bool lamp_light_eval(inout LightSample ls, int lamp, vec4 P, vec4 D, float t)
{
    KernelLight _5302;
    _5302.type = push.data_ptr._lights.data[lamp].type;
    _5302.co[0] = push.data_ptr._lights.data[lamp].co[0];
    _5302.co[1] = push.data_ptr._lights.data[lamp].co[1];
    _5302.co[2] = push.data_ptr._lights.data[lamp].co[2];
    _5302.shader_id = push.data_ptr._lights.data[lamp].shader_id;
    _5302.samples = push.data_ptr._lights.data[lamp].samples;
    _5302.max_bounces = push.data_ptr._lights.data[lamp].max_bounces;
    _5302.random = push.data_ptr._lights.data[lamp].random;
    _5302.strength[0] = push.data_ptr._lights.data[lamp].strength[0];
    _5302.strength[1] = push.data_ptr._lights.data[lamp].strength[1];
    _5302.strength[2] = push.data_ptr._lights.data[lamp].strength[2];
    _5302.pad1 = push.data_ptr._lights.data[lamp].pad1;
    _5302.tfm.x = push.data_ptr._lights.data[lamp].tfm.x;
    _5302.tfm.y = push.data_ptr._lights.data[lamp].tfm.y;
    _5302.tfm.z = push.data_ptr._lights.data[lamp].tfm.z;
    _5302.itfm.x = push.data_ptr._lights.data[lamp].itfm.x;
    _5302.itfm.y = push.data_ptr._lights.data[lamp].itfm.y;
    _5302.itfm.z = push.data_ptr._lights.data[lamp].itfm.z;
    _5302.uni[0] = push.data_ptr._lights.data[lamp].uni[0];
    _5302.uni[1] = push.data_ptr._lights.data[lamp].uni[1];
    _5302.uni[2] = push.data_ptr._lights.data[lamp].uni[2];
    _5302.uni[3] = push.data_ptr._lights.data[lamp].uni[3];
    _5302.uni[4] = push.data_ptr._lights.data[lamp].uni[4];
    _5302.uni[5] = push.data_ptr._lights.data[lamp].uni[5];
    _5302.uni[6] = push.data_ptr._lights.data[lamp].uni[6];
    _5302.uni[7] = push.data_ptr._lights.data[lamp].uni[7];
    _5302.uni[8] = push.data_ptr._lights.data[lamp].uni[8];
    _5302.uni[9] = push.data_ptr._lights.data[lamp].uni[9];
    _5302.uni[10] = push.data_ptr._lights.data[lamp].uni[10];
    _5302.uni[11] = push.data_ptr._lights.data[lamp].uni[11];
    KernelLight klight = _5302;
    uint type = uint(klight.type);
    ls.type = type;
    ls.shader = klight.shader_id;
    ls.object = -1;
    ls.prim = -1;
    ls.lamp = lamp;
    ls.u = 0.0;
    ls.v = 0.0;
    if (!((uint(ls.shader) & 268435456u) != 0u))
    {
        return false;
    }
    if (type == 1u)
    {
        float radius = klight.uni[0];
        if (radius == 0.0)
        {
            return false;
        }
        if (!(t == 3.4028234663852885981170418348452e+38))
        {
            return false;
        }
        vec4 lightD = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
        float costheta = dot((-lightD).xyz, D.xyz);
        float cosangle = klight.uni[1];
        if (costheta < cosangle)
        {
            return false;
        }
        ls.P = -D;
        ls.Ng = -D;
        ls.D = D;
        ls.t = 3.4028234663852885981170418348452e+38;
        float invarea = klight.uni[2];
        ls.pdf = invarea / ((costheta * costheta) * costheta);
        ls.eval_fac = ls.pdf;
    }
    else
    {
        if ((type == 0u) || (type == 4u))
        {
            vec4 lightP = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
            float radius_1 = klight.uni[0];
            if (radius_1 == 0.0)
            {
                return false;
            }
            vec4 param = P;
            vec4 param_1 = D;
            float param_2 = t;
            vec4 param_3 = lightP;
            float param_4 = radius_1;
            vec4 param_5;
            float param_6;
            bool _5428 = ray_aligned_disk_intersect(param, param_1, param_2, param_3, param_4, param_5, param_6);
            ls.P = param_5;
            ls.t = param_6;
            if (!_5428)
            {
                return false;
            }
            ls.Ng = -D;
            ls.D = D;
            float invarea_1 = klight.uni[1];
            ls.eval_fac = 0.079577468335628509521484375 * invarea_1;
            ls.pdf = invarea_1;
            if (type == 4u)
            {
                vec4 dir = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
                vec4 param_7 = dir;
                float param_8 = klight.uni[2];
                float param_9 = klight.uni[3];
                vec4 param_10 = ls.Ng;
                ls.eval_fac *= spot_light_attenuation(param_7, param_8, param_9, param_10);
                if (ls.eval_fac == 0.0)
                {
                    return false;
                }
            }
            vec2 uv = map_to_sphere(ls.Ng);
            ls.u = uv.x;
            ls.v = uv.y;
            if (!(ls.t == 3.4028234663852885981170418348452e+38))
            {
                float param_11 = ls.t;
                ls.pdf *= lamp_light_pdf(ls.Ng, -ls.D, param_11);
            }
        }
        else
        {
            if (type == 3u)
            {
                float invarea_2 = abs(klight.uni[3]);
                bool is_round = klight.uni[3] < 0.0;
                if (invarea_2 == 0.0)
                {
                    return false;
                }
                vec4 axisu = vec4(klight.uni[0], klight.uni[1], klight.uni[2], 0.0);
                vec4 axisv = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
                vec4 Ng = vec4(klight.uni[8], klight.uni[9], klight.uni[10], 0.0);
                if (dot(D.xyz, Ng.xyz) >= 0.0)
                {
                    return false;
                }
                vec4 light_P = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
                vec4 param_12 = P;
                vec4 param_13 = D;
                float param_14 = 0.0;
                float param_15 = t;
                vec4 param_16 = light_P;
                vec4 param_17 = axisu;
                vec4 param_18 = axisv;
                vec4 param_19 = Ng;
                bool param_24 = is_round;
                vec4 param_20;
                float param_21;
                float param_22;
                float param_23;
                bool _5592 = ray_quad_intersect(param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);
                ls.P = param_20;
                ls.t = param_21;
                ls.u = param_22;
                ls.v = param_23;
                if (!_5592)
                {
                    return false;
                }
                ls.D = D;
                ls.Ng = Ng;
                if (is_round)
                {
                    float param_25 = ls.t;
                    ls.pdf = invarea_2 * lamp_light_pdf(Ng, -D, param_25);
                }
                else
                {
                    vec4 param_26 = P;
                    vec4 param_27 = light_P;
                    vec4 param_28 = axisu;
                    vec4 param_29 = axisv;
                    float param_30 = 0.0;
                    float param_31 = 0.0;
                    bool param_32 = false;
                    float _5634 = rect_light_sample(param_26, param_27, param_28, param_29, param_30, param_31, param_32);
                    light_P = param_27;
                    ls.pdf = _5634;
                }
                ls.eval_fac = 0.25 * invarea_2;
            }
            else
            {
                return false;
            }
        }
    }
    ls.pdf *= _3116.kernel_data.integrator.pdf_lights;
    return true;
}

bool shader_constant_emission_eval(int shader, inout vec4 eval)
{
    int shader_index = int(uint(shader) & 8388607u);
    int shader_flag = push.data_ptr._shaders.data[shader_index].flags;
    if ((uint(shader_flag) & 134217728u) != 0u)
    {
        eval = vec4(push.data_ptr._shaders.data[shader_index].constant_emission[0], push.data_ptr._shaders.data[shader_index].constant_emission[1], push.data_ptr._shaders.data[shader_index].constant_emission[2], 0.0);
        return true;
    }
    return false;
}

void shader_setup_from_background(Ray ray)
{
    sd.P = ray.D;
    sd.N = -ray.D;
    sd.Ng = -ray.D;
    sd.I = -ray.D;
    sd.shader = _3116.kernel_data.background.surface_shader;
    sd.flag = push.data_ptr._shaders.data[uint(sd.shader) & 8388607u].flags;
    sd.object_flag = 0;
    sd.time = ray.time;
    sd.ray_length = 0.0;
    sd.object = -1;
    sd.lamp = -1;
    sd.prim = -1;
    sd.u = 0.0;
    sd.v = 0.0;
    sd.dPdu = vec4(0.0);
    sd.dPdv = vec4(0.0);
    sd.dP = ray.dD;
    sd.dI.dx = -sd.dP.dx;
    sd.dI.dy = -sd.dP.dy;
    sd.du.dx = 0.0;
    sd.du.dy = 0.0;
    sd.dv.dx = 0.0;
    sd.dv.dy = 0.0;
    sd.ray_P = ray.P;
}

Transform object_fetch_transform_motion(int object, float time)
{
    int motion_offset = int(push.data_ptr._objects.data[object].motion_offset);
    uint num_steps = uint((push.data_ptr._objects.data[object].numsteps * 2) + 1);
    Transform tfm;
    return tfm;
}

Transform transform_quick_inverse(inout Transform M)
{
    float det = ((M.x.x * ((M.z.z * M.y.y) - (M.z.y * M.y.z))) - (M.y.x * ((M.z.z * M.x.y) - (M.z.y * M.x.z)))) + (M.z.x * ((M.y.z * M.x.y) - (M.y.y * M.x.z)));
    if (det == 0.0)
    {
        M.x.x += 9.9999999392252902907785028219223e-09;
        M.y.y += 9.9999999392252902907785028219223e-09;
        M.z.z += 9.9999999392252902907785028219223e-09;
        det = ((M.x.x * ((M.z.z * M.y.y) - (M.z.y * M.y.z))) - (M.y.x * ((M.z.z * M.x.y) - (M.z.y * M.x.z)))) + (M.z.x * ((M.y.z * M.x.y) - (M.y.y * M.x.z)));
    }
    float _1711;
    if (!(det == 0.0))
    {
        _1711 = 1.0 / det;
    }
    else
    {
        _1711 = 0.0;
    }
    det = _1711;
    vec4 Rx = vec4((M.z.z * M.y.y) - (M.z.y * M.y.z), (M.z.y * M.x.z) - (M.z.z * M.x.y), (M.y.z * M.x.y) - (M.y.y * M.x.z), 0.0) * det;
    vec4 Ry = vec4((M.z.x * M.y.z) - (M.z.z * M.y.x), (M.z.z * M.x.x) - (M.z.x * M.x.z), (M.y.x * M.x.z) - (M.y.z * M.x.x), 0.0) * det;
    vec4 Rz = vec4((M.z.y * M.y.x) - (M.z.x * M.y.y), (M.z.x * M.x.y) - (M.z.y * M.x.x), (M.y.y * M.x.x) - (M.y.x * M.x.y), 0.0) * det;
    vec4 T = -vec4(M.x.w, M.y.w, M.z.w, 0.0);
    Transform R;
    R.x = vec4(Rx.x, Rx.y, Rx.z, dot(Rx.xyz, T.xyz));
    R.y = vec4(Ry.x, Ry.y, Ry.z, dot(Ry.xyz, T.xyz));
    R.z = vec4(Rz.x, Rz.y, Rz.z, dot(Rz.xyz, T.xyz));
    return R;
}

Transform object_fetch_transform(int object, uint type)
{
    if (type == 1u)
    {
        Transform _2208;
        _2208.x = push.data_ptr._objects.data[object].itfm.x;
        _2208.y = push.data_ptr._objects.data[object].itfm.y;
        _2208.z = push.data_ptr._objects.data[object].itfm.z;
        Transform _2207 = _2208;
        return _2207;
    }
    else
    {
        Transform _2220;
        _2220.x = push.data_ptr._objects.data[object].tfm.x;
        _2220.y = push.data_ptr._objects.data[object].tfm.y;
        _2220.z = push.data_ptr._objects.data[object].tfm.z;
        Transform _2219 = _2220;
        return _2219;
    }
}

void shader_setup_object_transforms(float time)
{
    if ((uint(sd.object_flag) & 2u) != 0u)
    {
        int param = sd.object;
        float param_1 = time;
        sd.ob_tfm = object_fetch_transform_motion(param, param_1);
        Transform param_2 = sd.ob_tfm;
        Transform _5715 = transform_quick_inverse(param_2);
        sd.ob_itfm = _5715;
    }
    else
    {
        int param_3 = sd.object;
        uint param_4 = 0u;
        sd.ob_tfm = object_fetch_transform(param_3, param_4);
        int param_5 = sd.object;
        uint param_6 = 1u;
        sd.ob_itfm = object_fetch_transform(param_5, param_6);
    }
}

Transform lamp_fetch_transform(int lamp, bool _inverse)
{
    if (_inverse)
    {
        Transform _2239;
        _2239.x = push.data_ptr._lights.data[lamp].itfm.x;
        _2239.y = push.data_ptr._lights.data[lamp].itfm.y;
        _2239.z = push.data_ptr._lights.data[lamp].itfm.z;
        Transform _2238 = _2239;
        return _2238;
    }
    else
    {
        Transform _2252;
        _2252.x = push.data_ptr._lights.data[lamp].tfm.x;
        _2252.y = push.data_ptr._lights.data[lamp].tfm.y;
        _2252.z = push.data_ptr._lights.data[lamp].tfm.z;
        Transform _2251 = _2252;
        return _2251;
    }
}

vec4 transform_point(Transform t, vec4 a)
{
    vec4 c = vec4((((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z)) + t.x.w, (((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z)) + t.y.w, (((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z)) + t.z.w, 0.0);
    return c;
}

void object_position_transform(inout vec4 P)
{
    Transform param = sd.ob_tfm;
    sd.ob_tfm = param;
    P = transform_point(param, P);
}

vec4 transform_direction_transposed(Transform t, vec4 a)
{
    vec4 x = vec4(t.x.x, t.y.x, t.z.x, 0.0);
    vec4 y = vec4(t.x.y, t.y.y, t.z.y, 0.0);
    vec4 z = vec4(t.x.z, t.y.z, t.z.z, 0.0);
    return vec4(dot(x.xyz, a.xyz), dot(y.xyz, a.xyz), dot(z.xyz, a.xyz), 0.0);
}

void object_normal_transform(inout vec4 N)
{
    N = normalize(transform_direction_transposed(sd.ob_itfm, N));
}

vec4 transform_direction(Transform t, vec4 a)
{
    vec4 c = vec4(((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z), ((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z), ((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z), 0.0);
    return c;
}

void object_dir_transform(inout vec4 D)
{
    Transform param = sd.ob_tfm;
    sd.ob_tfm = param;
    D = transform_direction(param, D);
}

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

vec4 safe_normalize(vec4 a)
{
    float t = length(a.xyz);
    vec4 _679;
    if (!(t == 0.0))
    {
        _679 = a * (1.0 / t);
    }
    else
    {
        _679 = a;
    }
    return _679;
}

bool is_zero(vec4 a)
{
    bool _690 = a.x == 0.0;
    bool _705;
    if (!_690)
    {
        _705 = (int((floatBitsToUint(a.x) >> uint(23)) & 255u) - 127) < (-60);
    }
    else
    {
        _705 = _690;
    }
    bool _721;
    if (_705)
    {
        bool _709 = a.y == 0.0;
        bool _720;
        if (!_709)
        {
            _720 = (int((floatBitsToUint(a.y) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _720 = _709;
        }
        _721 = _720;
    }
    else
    {
        _721 = _705;
    }
    bool _737;
    if (_721)
    {
        bool _725 = a.z == 0.0;
        bool _736;
        if (!_725)
        {
            _736 = (int((floatBitsToUint(a.z) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _736 = _725;
        }
        _737 = _736;
    }
    else
    {
        _737 = _721;
    }
    return _737;
}

vec4 triangle_smooth_normal(vec4 Ng, int prim, float u, float v)
{
    uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * prim], push.data_ptr._tri_vindex2.data[(3 * prim) + 1], push.data_ptr._tri_vindex2.data[(3 * prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
    vec4 n0 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.x]);
    vec4 n1 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.y]);
    vec4 n2 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.z]);
    vec4 N = safe_normalize(((n2 * ((1.0 - u) - v)) + (n0 * u)) + (n1 * v));
    return is_zero(N) ? Ng : N;
}

void shader_setup_from_sample(vec4 P, vec4 Ng, vec4 I, int shader, int object, int prim, float u, float v, float t, float time, bool object_space, int lamp)
{
    sd.P = P;
    sd.N = Ng;
    sd.Ng = Ng;
    sd.I = I;
    sd.shader = shader;
    if (prim != (-1))
    {
        sd.type = 1;
    }
    else
    {
        if (lamp != (-1))
        {
            sd.type = 64;
        }
        else
        {
            sd.type = 0;
        }
    }
    sd.object = object;
    sd.lamp = -1;
    sd.prim = prim;
    sd.u = u;
    sd.v = v;
    sd.time = time;
    sd.ray_length = t;
    sd.flag = push.data_ptr._shaders.data[uint(sd.shader) & 8388607u].flags;
    sd.object_flag = 0;
    if (sd.object != (-1))
    {
        sd.object_flag |= int(push.data_ptr._object_flag.data[sd.object]);
        float param = time;
        shader_setup_object_transforms(param);
    }
    else
    {
        if (lamp != (-1))
        {
            int param_1 = lamp;
            bool param_2 = false;
            sd.ob_tfm = lamp_fetch_transform(param_1, param_2);
            int param_3 = lamp;
            bool param_4 = true;
            sd.ob_itfm = lamp_fetch_transform(param_3, param_4);
            sd.lamp = lamp;
        }
    }
    if (object_space)
    {
        vec4 param_5 = sd.P;
        object_position_transform(param_5);
        sd.P = param_5;
        vec4 param_6 = sd.Ng;
        object_normal_transform(param_6);
        sd.Ng = param_6;
        sd.N = sd.Ng;
        vec4 param_7 = sd.I;
        object_dir_transform(param_7);
        sd.I = param_7;
    }
    if ((uint(sd.type) & 1u) != 0u)
    {
        if ((uint(sd.shader) & 2147483648u) != 0u)
        {
            vec4 param_8 = Ng;
            int param_9 = sd.prim;
            float param_10 = sd.u;
            float param_11 = sd.v;
            sd.N = triangle_smooth_normal(param_8, param_9, param_10, param_11);
            if (!((uint(sd.object_flag) & 4u) != 0u))
            {
                vec4 param_12 = sd.N;
                object_normal_transform(param_12);
                sd.N = param_12;
            }
        }
        uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * sd.prim], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 1], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
        vec4 p0 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.x]);
        vec4 p1 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.y]);
        vec4 p2 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.z]);
        sd.dPdu = p0 - p2;
        sd.dPdv = p1 - p2;
        if (!((uint(sd.object_flag) & 4u) != 0u))
        {
            vec4 param_13 = sd.dPdu;
            object_dir_transform(param_13);
            sd.dPdu = param_13;
            vec4 param_14 = sd.dPdv;
            object_dir_transform(param_14);
            sd.dPdv = param_14;
        }
    }
    else
    {
        sd.dPdu = vec4(0.0);
        sd.dPdv = vec4(0.0);
    }
    if (sd.prim != (-1))
    {
        bool backfacing = dot(sd.Ng.xyz, sd.I.xyz) < 0.0;
        if (backfacing)
        {
            sd.flag |= 1;
            sd.Ng = -sd.Ng;
            sd.N = -sd.N;
            sd.dPdu = -sd.dPdu;
            sd.dPdv = -sd.dPdv;
        }
    }
    sd.dP.dx = vec4(0.0);
    sd.dP.dy = vec4(0.0);
    sd.dI.dx = vec4(0.0);
    sd.dI.dy = vec4(0.0);
    sd.du.dx = 0.0;
    sd.du.dy = 0.0;
    sd.dv.dx = 0.0;
    sd.dv.dy = 0.0;
}

void shader_eval_surface(uint state_flag)
{
    int max_closures;
    if ((state_flag & 7341952u) != 0u)
    {
        max_closures = 0;
    }
    else
    {
        max_closures = _3116.kernel_data.integrator.max_closures;
    }
    sd.num_closure = int(state_flag);
    sd.num_closure_left = max_closures;
    sd.alloc_offset = rec_num;
    executeCallableNV(2u, 1);
    if ((uint(sd.flag) & 1024u) != 0u)
    {
        // unimplemented ext op 12
    }
}

float emissive_pdf(vec4 Ng, vec4 I)
{
    float cosNO = abs(dot(Ng.xyz, I.xyz));
    return float(cosNO > 0.0);
}

vec4 emissive_simple_eval(vec4 Ng, vec4 I)
{
    float res = emissive_pdf(Ng, I);
    return vec4(res, res, res, 0.0);
}

vec4 shader_emissive_eval()
{
    if ((uint(sd.flag) & 2u) != 0u)
    {
        return emissive_simple_eval(sd.Ng, sd.I) * sd.closure_emission_background;
    }
    else
    {
        return vec4(0.0);
    }
}

vec4 direct_emissive_eval(inout LightSample ls, vec4 I, differential3 dI, float t, float time)
{
    vec4 eval = vec4(0.0);
    int param = ls.shader;
    vec4 param_1 = eval;
    bool _6320 = shader_constant_emission_eval(param, param_1);
    eval = param_1;
    if (_6320)
    {
        bool _6326 = ls.prim != (-1);
        bool _6336;
        if (_6326)
        {
            _6336 = dot(ls.Ng.xyz, I.xyz) < 0.0;
        }
        else
        {
            _6336 = _6326;
        }
        if (_6336)
        {
            ls.Ng = -ls.Ng;
        }
        int _6349 = atomicAdd(_6346.counter[44], 1);
    }
    else
    {
        if (ls.type == 2u)
        {
            Ray ray;
            ray.D = ls.D;
            ray.P = ls.P;
            ray.t = 1.0;
            ray.time = time;
            ray.dP.dx = vec4(0.0);
            ray.dP.dy = vec4(0.0);
            ray.dD = dI;
            Ray param_2 = ray;
            shader_setup_from_background(param_2);
            int _6374 = atomicAdd(_6346.counter[45], 1);
        }
        else
        {
            int param_3 = ls.shader;
            int param_4 = ls.object;
            int param_5 = ls.prim;
            float param_6 = ls.u;
            float param_7 = ls.v;
            float param_8 = t;
            float param_9 = time;
            bool param_10 = false;
            int param_11 = ls.lamp;
            shader_setup_from_sample(ls.P, ls.Ng, I, param_3, param_4, param_5, param_6, param_7, param_8, param_9, param_10, param_11);
            int _6407 = atomicAdd(_6346.counter[46], 1);
            ls.Ng = sd.Ng;
        }
        if (true)
        {
            pay.state.bounce++;
        }
        else
        {
            pay.state.bounce--;
        }
        uint param_12 = 4194304u;
        shader_eval_surface(param_12);
        if (false)
        {
            pay.state.bounce++;
        }
        else
        {
            pay.state.bounce--;
        }
        if (ls.type == 2u)
        {
            vec4 _6446;
            if ((uint(sd.flag) & 2u) != 0u)
            {
                _6446 = sd.closure_emission_background;
            }
            else
            {
                _6446 = vec4(0.0);
            }
            eval = _6446;
        }
        else
        {
            eval = shader_emissive_eval();
        }
    }
    eval *= ls.eval_fac;
    if (ls.lamp != (-1))
    {
        KernelLight _6473;
        _6473.type = push.data_ptr._lights.data[ls.lamp].type;
        _6473.co[0] = push.data_ptr._lights.data[ls.lamp].co[0];
        _6473.co[1] = push.data_ptr._lights.data[ls.lamp].co[1];
        _6473.co[2] = push.data_ptr._lights.data[ls.lamp].co[2];
        _6473.shader_id = push.data_ptr._lights.data[ls.lamp].shader_id;
        _6473.samples = push.data_ptr._lights.data[ls.lamp].samples;
        _6473.max_bounces = push.data_ptr._lights.data[ls.lamp].max_bounces;
        _6473.random = push.data_ptr._lights.data[ls.lamp].random;
        _6473.strength[0] = push.data_ptr._lights.data[ls.lamp].strength[0];
        _6473.strength[1] = push.data_ptr._lights.data[ls.lamp].strength[1];
        _6473.strength[2] = push.data_ptr._lights.data[ls.lamp].strength[2];
        _6473.pad1 = push.data_ptr._lights.data[ls.lamp].pad1;
        _6473.tfm.x = push.data_ptr._lights.data[ls.lamp].tfm.x;
        _6473.tfm.y = push.data_ptr._lights.data[ls.lamp].tfm.y;
        _6473.tfm.z = push.data_ptr._lights.data[ls.lamp].tfm.z;
        _6473.itfm.x = push.data_ptr._lights.data[ls.lamp].itfm.x;
        _6473.itfm.y = push.data_ptr._lights.data[ls.lamp].itfm.y;
        _6473.itfm.z = push.data_ptr._lights.data[ls.lamp].itfm.z;
        _6473.uni[0] = push.data_ptr._lights.data[ls.lamp].uni[0];
        _6473.uni[1] = push.data_ptr._lights.data[ls.lamp].uni[1];
        _6473.uni[2] = push.data_ptr._lights.data[ls.lamp].uni[2];
        _6473.uni[3] = push.data_ptr._lights.data[ls.lamp].uni[3];
        _6473.uni[4] = push.data_ptr._lights.data[ls.lamp].uni[4];
        _6473.uni[5] = push.data_ptr._lights.data[ls.lamp].uni[5];
        _6473.uni[6] = push.data_ptr._lights.data[ls.lamp].uni[6];
        _6473.uni[7] = push.data_ptr._lights.data[ls.lamp].uni[7];
        _6473.uni[8] = push.data_ptr._lights.data[ls.lamp].uni[8];
        _6473.uni[9] = push.data_ptr._lights.data[ls.lamp].uni[9];
        _6473.uni[10] = push.data_ptr._lights.data[ls.lamp].uni[10];
        _6473.uni[11] = push.data_ptr._lights.data[ls.lamp].uni[11];
        KernelLight klight = _6473;
        eval *= vec4(klight.strength[0], klight.strength[1], klight.strength[2], 0.0);
    }
    return eval;
}

float power_heuristic(float a, float b)
{
    return (a * a) / ((a * a) + (b * b));
}

float reduce_add(vec4 a)
{
    return ((a.x + a.y) + a.z) + a.w;
}

void path_radiance_accum_emission(int state_flag, int state_bounce, vec4 throughput, vec4 value)
{
    if ((uint(state_flag) & 131072u) != 0u)
    {
        return;
    }
    vec4 contribution = throughput * value;
    float _6151;
    if ((state_bounce - 1) > 0)
    {
        _6151 = _3116.kernel_data.integrator.sample_clamp_indirect;
    }
    else
    {
        _6151 = _3116.kernel_data.integrator.sample_clamp_direct;
    }
    float limit = _6151;
    float sum = reduce_add(abs(contribution));
    if (sum > limit)
    {
        contribution *= (limit / sum);
    }
    if (pay.use_light_pass != int(0u))
    {
        if (state_bounce == 0)
        {
            pay.L.emission += contribution;
        }
        else
        {
            if (state_bounce == 1)
            {
                pay.L.direct_emission += contribution;
            }
            else
            {
                pay.L.indirect += contribution;
            }
        }
    }
    else
    {
        pay.L.emission += contribution;
    }
}

void indirect_lamp_emission()
{
    int state_flag = pay.state.flag;
    LightSample ls;
    for (int lamp = 0; lamp < _3116.kernel_data.integrator.num_all_lights; lamp++)
    {
        LightSample param = ls;
        int param_1 = lamp;
        vec4 param_2 = pay.ray.P;
        vec4 param_3 = pay.ray.D;
        float param_4 = pay.ray.t;
        bool _6828 = lamp_light_eval(param, param_1, param_2, param_3, param_4);
        ls = param;
        if (!_6828)
        {
            continue;
        }
        if ((uint(ls.shader) & 260046848u) != 0u)
        {
            bool _6845 = (uint(ls.shader) & 134217728u) != 0u;
            bool _6852;
            if (_6845)
            {
                _6852 = (uint(state_flag) & 8u) != 0u;
            }
            else
            {
                _6852 = _6845;
            }
            bool _6869;
            if (!_6852)
            {
                bool _6860 = (uint(ls.shader) & 67108864u) != 0u;
                bool _6868;
                if (_6860)
                {
                    _6868 = (uint(state_flag) & 18u) == 18u;
                }
                else
                {
                    _6868 = _6860;
                }
                _6869 = _6868;
            }
            else
            {
                _6869 = _6852;
            }
            bool _6885;
            if (!_6869)
            {
                bool _6877 = (uint(ls.shader) & 33554432u) != 0u;
                bool _6884;
                if (_6877)
                {
                    _6884 = (uint(state_flag) & 4u) != 0u;
                }
                else
                {
                    _6884 = _6877;
                }
                _6885 = _6884;
            }
            else
            {
                _6885 = _6869;
            }
            bool _6903;
            if (!_6885)
            {
                bool _6894 = (uint(ls.shader) & 8388608u) != 0u;
                bool _6902;
                if (_6894)
                {
                    _6902 = (uint(state_flag) & 4096u) != 0u;
                }
                else
                {
                    _6902 = _6894;
                }
                _6903 = _6902;
            }
            else
            {
                _6903 = _6885;
            }
            if (_6903)
            {
                continue;
            }
        }
        LightSample param_5 = ls;
        vec4 param_6 = -pay.ray.D;
        differential3 param_7 = pay.ray.dD;
        float param_8 = ls.t;
        float param_9 = pay.ray.time;
        vec4 _6923 = direct_emissive_eval(param_5, param_6, param_7, param_8, param_9);
        ls = param_5;
        vec4 lamp_L = _6923;
        if (!((uint(state_flag) & 16384u) != 0u))
        {
            float param_10 = pay.state.ray_pdf;
            float param_11 = ls.pdf;
            float mis_weight = power_heuristic(param_10, param_11);
            lamp_L *= mis_weight;
        }
        int param_12 = pay.state.flag;
        int param_13 = pay.state.bounce;
        vec4 param_14 = pay.L.throughput;
        vec4 param_15 = lamp_L;
        path_radiance_accum_emission(param_12, param_13, param_14, param_15);
    }
}

int light_distribution_sample(inout float randu)
{
    int first = 0;
    int _4225 = _3116.kernel_data.integrator.num_distribution + 1;
    float r = randu;
    int len = _4225;
    do
    {
        int half_len = len >> 1;
        int middle = first + half_len;
        if (r < push.data_ptr._light_distribution.data[middle].totarea)
        {
            len = half_len;
        }
        else
        {
            first = middle + 1;
            len = (len - half_len) - 1;
        }
    } while (len > 0);
    int index = clamp(first - 1, 0, _3116.kernel_data.integrator.num_distribution - 1);
    float distr_min = push.data_ptr._light_distribution.data[index].totarea;
    float distr_max = push.data_ptr._light_distribution.data[index + 1].totarea;
    randu = (r - distr_min) / (distr_max - distr_min);
    return index;
}

void triangle_vertices(int prim, inout vec4 P[3])
{
    uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * prim], push.data_ptr._tri_vindex2.data[(3 * prim) + 1], push.data_ptr._tri_vindex2.data[(3 * prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
    P[0] = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.x]);
    P[1] = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.y]);
    P[2] = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.z]);
}

bool triangle_world_space_vertices(int object, int prim, float time, inout vec4 V[3])
{
    bool has_motion = false;
    int object_flag = int(push.data_ptr._object_flag.data[object]);
    if (((uint(object_flag) & 64u) != 0u) && (time >= 0.0))
    {
        has_motion = true;
    }
    else
    {
        int param = prim;
        vec4 param_1[3];
        triangle_vertices(param, param_1);
        V = param_1;
    }
    if (!((uint(object_flag) & 4u) != 0u))
    {
        int param_2 = object;
        uint param_3 = 0u;
        Transform tfm = object_fetch_transform(param_2, param_3);
        Transform param_4 = tfm;
        tfm = param_4;
        V[0] = transform_point(param_4, V[0]);
        Transform param_5 = tfm;
        tfm = param_5;
        V[1] = transform_point(param_5, V[1]);
        Transform param_6 = tfm;
        tfm = param_6;
        V[2] = transform_point(param_6, V[2]);
        has_motion = true;
    }
    return has_motion;
}

vec4 safe_normalize_len(vec4 a, inout float t)
{
    t = length(a.xyz);
    vec4 _649;
    if (!(t == 0.0))
    {
        _649 = a / vec4(t);
    }
    else
    {
        _649 = a;
    }
    return _649;
}

float fast_acosf(float x)
{
    float f = abs(x);
    float _1090;
    if (f < 1.0)
    {
        _1090 = 1.0 - (1.0 - f);
    }
    else
    {
        _1090 = 1.0;
    }
    float m = _1090;
    float a = sqrt(1.0 - m) * (1.57079637050628662109375 + (m * ((-0.21330098807811737060546875) + (m * (0.077980481088161468505859375 + (m * (-0.02164095081388950347900390625)))))));
    float _1117;
    if (x < 0.0)
    {
        _1117 = 3.1415927410125732421875 - a;
    }
    else
    {
        _1117 = a;
    }
    return _1117;
}

float copysignf(float a, float b)
{
    float r = abs(a);
    float s = sign(b);
    float _757;
    if (s >= 0.0)
    {
        _757 = r;
    }
    else
    {
        _757 = -r;
    }
    return _757;
}

int fast_rint(float x)
{
    float param = 0.5;
    float param_1 = x;
    return int(x + copysignf(param, param_1));
}

float madd(float a, float b, float c)
{
    return (a * b) + c;
}

float fast_sinf(inout float x)
{
    float param = x * 0.3183098733425140380859375;
    int q = fast_rint(param);
    float qf = float(q);
    x = madd(qf, -3.140625, x);
    x = madd(qf, -0.000967502593994140625, x);
    x = madd(qf, -1.50990672409534454345703125e-07, x);
    x = madd(qf, -5.1266881365141792059603176312521e-12, x);
    x = 1.57079637050628662109375 - (1.57079637050628662109375 - x);
    float s = x * x;
    if ((q & 1) != 0)
    {
        x = -x;
    }
    float u = 2.6083159809786593541502952575684e-06;
    u = madd(u, s, -0.00019810690719168633222579956054688);
    u = madd(u, s, 0.008333078585565090179443359375);
    u = madd(u, s, -0.1666665971279144287109375);
    u = madd(s, u * x, x);
    if (abs(u) > 1.0)
    {
        u = 0.0;
    }
    return u;
}

void fast_sincosf(inout float x, out float sine, out float cosine)
{
    float param = x * 0.3183098733425140380859375;
    int q = fast_rint(param);
    float qf = float(q);
    x = madd(qf, -3.140625, x);
    x = madd(qf, -0.000967502593994140625, x);
    x = madd(qf, -1.50990672409534454345703125e-07, x);
    x = madd(qf, -5.1266881365141792059603176312521e-12, x);
    x = 1.57079637050628662109375 - (1.57079637050628662109375 - x);
    float s = x * x;
    if ((q & 1) != 0)
    {
        x = -x;
    }
    float su = 2.6083159809786593541502952575684e-06;
    su = madd(su, s, -0.00019810690719168633222579956054688);
    su = madd(su, s, 0.008333078585565090179443359375);
    su = madd(su, s, -0.1666665971279144287109375);
    su = madd(s, su * x, x);
    float cu = -2.7181184236724220681935548782349e-07;
    cu = madd(cu, s, 2.4799044695100747048854827880859e-05);
    cu = madd(cu, s, -0.001388887874782085418701171875);
    cu = madd(cu, s, 0.041666664183139801025390625);
    cu = madd(cu, s, -0.5);
    cu = madd(cu, s, 1.0);
    if ((q & 1) != 0)
    {
        cu = -cu;
    }
    if (abs(su) > 1.0)
    {
        su = 0.0;
    }
    if (abs(cu) > 1.0)
    {
        cu = 0.0;
    }
    sine = su;
    cosine = cu;
}

float safe_sqrtf(float f)
{
    return sqrt(max(f, 0.0));
}

float xor_signmask(float x, int y)
{
    return intBitsToFloat(floatBitsToInt(x) ^ y);
}

bool ray_triangle_intersect(vec4 ray_P, vec4 ray_dir, float ray_t, vec4 tri_a, vec4 tri_b, vec4 tri_c, inout float isect_u, inout float isect_v, inout float isect_t)
{
    vec4 P = ray_P;
    vec4 dir = ray_dir;
    vec4 v0 = tri_c - P;
    vec4 v1 = tri_a - P;
    vec4 v2 = tri_b - P;
    vec4 e0 = v2 - v0;
    vec4 e1 = v0 - v1;
    vec4 e2 = v1 - v2;
    float U = dot(vec4(cross((v2 + v0).xyz, e0.xyz), 0.0).xyz, ray_dir.xyz);
    float V = dot(vec4(cross((v0 + v1).xyz, e1.xyz), 0.0).xyz, ray_dir.xyz);
    float W = dot(vec4(cross((v1 + v2).xyz, e2.xyz), 0.0).xyz, ray_dir.xyz);
    float minUVW = min(U, min(V, W));
    float maxUVW = max(U, max(V, W));
    if ((minUVW < 0.0) && (maxUVW > 0.0))
    {
        return false;
    }
    vec4 param = e1;
    vec4 param_1 = e0;
    vec4 Ng1 = _cross(param, param_1);
    vec4 Ng = Ng1 + Ng1;
    float den = dot(Ng.xyz, dir.xyz);
    if (den == 0.0)
    {
        return false;
    }
    float T = dot(v0.xyz, Ng.xyz);
    int sign_den = floatBitsToInt(den) & (-2147483648);
    float param_2 = T;
    int param_3 = sign_den;
    float sign_T = xor_signmask(param_2, param_3);
    bool _1314 = sign_T < 0.0;
    bool _1327;
    if (!_1314)
    {
        float param_4 = den;
        int param_5 = sign_den;
        _1327 = sign_T > (ray_t * xor_signmask(param_4, param_5));
    }
    else
    {
        _1327 = _1314;
    }
    if (_1327)
    {
        return false;
    }
    float inv_den = 1.0 / den;
    isect_u = U * inv_den;
    isect_v = V * inv_den;
    isect_t = T * inv_den;
    return true;
}

float len(vec3 a)
{
    return length(a);
}

float triangle_area(vec4 v1, vec4 v2, vec4 v3)
{
    vec3 param = cross(v3.xyz - v2.xyz, v1.xyz - v2.xyz);
    return len(param) * 0.5;
}

float triangle_light_pdf_area(vec4 Ng, vec4 I, float t)
{
    float pdf = _3116.kernel_data.integrator.pdf_triangles;
    float cos_pi = abs(dot(Ng.xyz, I.xyz));
    if (cos_pi == 0.0)
    {
        return 0.0;
    }
    return ((t * t) * pdf) / cos_pi;
}

void triangle_light_sample(int prim, int object, float randu, float randv, float time, inout LightSample ls, vec4 P)
{
    int param = object;
    int param_1 = prim;
    float param_2 = time;
    vec4 V[3];
    vec4 param_3[3] = V;
    bool _4305 = triangle_world_space_vertices(param, param_1, param_2, param_3);
    V = param_3;
    bool has_motion = _4305;
    vec4 e0 = V[1] - V[0];
    vec4 e1 = V[2] - V[0];
    vec4 e2 = V[2] - V[1];
    float longest_edge_squared = max(len_squared(e0), max(len_squared(e1), len_squared(e2)));
    vec4 N0 = vec4(cross(e0.xyz, e1.xyz), 0.0);
    float Nl = 0.0;
    float param_4 = Nl;
    vec4 _4348 = safe_normalize_len(N0, param_4);
    ls.Ng = _4348;
    float area = 0.5 * Nl;
    int object_flag = int(push.data_ptr._object_flag.data[object]);
    if ((uint(object_flag) & 8u) != 0u)
    {
        ls.Ng = -ls.Ng;
    }
    ls.eval_fac = 1.0;
    ls.shader = int(push.data_ptr._tri_shader.data[prim]);
    ls.object = object;
    ls.prim = prim;
    ls.lamp = -1;
    ls.shader |= 268435456;
    ls.type = 5u;
    float distance_to_plane = abs(dot(N0.xyz, (V[0] - P).xyz) / dot(N0.xyz, N0.xyz));
    if (longest_edge_squared > (distance_to_plane * distance_to_plane))
    {
        vec4 v0_p = V[0] - P;
        vec4 v1_p = V[1] - P;
        vec4 v2_p = V[2] - P;
        vec4 u01 = safe_normalize(vec4(cross(v0_p.xyz, v1_p.xyz), 0.0));
        vec4 u02 = safe_normalize(vec4(cross(v0_p.xyz, v2_p.xyz), 0.0));
        vec4 u12 = safe_normalize(vec4(cross(v1_p.xyz, v2_p.xyz), 0.0));
        vec4 A = safe_normalize(v0_p);
        vec4 B = safe_normalize(v1_p);
        vec4 C = safe_normalize(v2_p);
        float cos_alpha = dot(u02.xyz, u01.xyz);
        float cos_beta = -dot(u01.xyz, u12.xyz);
        float cos_gamma = dot(u02.xyz, u12.xyz);
        float param_5 = cos_alpha;
        float alpha = fast_acosf(param_5);
        float param_6 = cos_beta;
        float beta = fast_acosf(param_6);
        float param_7 = cos_gamma;
        float gamma = fast_acosf(param_7);
        float solid_angle = ((alpha + beta) + gamma) - 3.1415927410125732421875;
        float cos_c = dot(A.xyz, B.xyz);
        float param_8 = alpha;
        float _4517 = fast_sinf(param_8);
        float sin_alpha = _4517;
        float product = sin_alpha * cos_c;
        float phi = (randu * solid_angle) - alpha;
        float param_9 = phi;
        float param_10;
        float param_11;
        fast_sincosf(param_9, param_10, param_11);
        float s = param_10;
        float t = param_11;
        float u = t - cos_alpha;
        float v = s + product;
        vec4 U = safe_normalize(C - (A * dot(C.xyz, A.xyz)));
        float q = 1.0;
        float det = ((v * s) + (u * t)) * sin_alpha;
        if (!(det == 0.0))
        {
            q = ((((v * t) - (u * s)) * cos_alpha) - v) / det;
        }
        float temp = max(1.0 - (q * q), 0.0);
        vec4 C_ = safe_normalize((A * q) + (U * sqrt(temp)));
        float z = 1.0 - (randv * (1.0 - dot(C_.xyz, B.xyz)));
        float param_12 = 1.0 - (z * z);
        ls.D = (B * z) + (safe_normalize(C_ - (B * dot(C_.xyz, B.xyz))) * safe_sqrtf(param_12));
        vec4 param_13 = P;
        vec4 param_14 = ls.D;
        float param_15 = 3.4028234663852885981170418348452e+38;
        float param_16;
        float param_17;
        float param_18;
        bool _4646 = ray_triangle_intersect(param_13, param_14, param_15, V[0], V[1], V[2], param_16, param_17, param_18);
        ls.u = param_16;
        ls.v = param_17;
        ls.t = param_18;
        if (!_4646)
        {
            ls.pdf = 0.0;
            return;
        }
        ls.P = P + (ls.D * ls.t);
        if (solid_angle == 0.0)
        {
            ls.pdf = 0.0;
            return;
        }
        else
        {
            if (has_motion)
            {
                int param_19 = object;
                int param_20 = prim;
                float param_21 = -1.0;
                vec4 param_22[3] = V;
                bool _4682 = triangle_world_space_vertices(param_19, param_20, param_21, param_22);
                V = param_22;
                area = triangle_area(V[0], V[1], V[2]);
            }
            float pdf = area * _3116.kernel_data.integrator.pdf_triangles;
            ls.pdf = pdf / solid_angle;
        }
    }
    else
    {
        float u_1 = randu;
        float v_1 = randv;
        if (v_1 > u_1)
        {
            u_1 *= 0.5;
            v_1 -= u_1;
        }
        else
        {
            v_1 *= 0.5;
            u_1 -= v_1;
        }
        float t_1 = (1.0 - u_1) - v_1;
        ls.P = ((V[0] * u_1) + (V[1] * v_1)) + (V[2] * t_1);
        float param_23 = ls.t;
        vec4 _4747 = normalize_len(ls.P - P, param_23);
        ls.t = param_23;
        ls.D = _4747;
        float param_24 = ls.t;
        ls.pdf = triangle_light_pdf_area(ls.Ng, -ls.D, param_24);
        if (has_motion && (!(area == 0.0)))
        {
            int param_25 = object;
            int param_26 = prim;
            float param_27 = -1.0;
            vec4 param_28[3] = V;
            bool _4774 = triangle_world_space_vertices(param_25, param_26, param_27, param_28);
            V = param_28;
            float area_pre = triangle_area(V[0], V[1], V[2]);
            ls.pdf = (ls.pdf * area_pre) / area;
        }
        ls.u = u_1;
        ls.v = v_1;
    }
}

void make_orthonormals(vec4 N, inout vec4 a, inout vec4 b)
{
    bool _784 = !(N.x == N.y);
    bool _793;
    if (!_784)
    {
        _793 = !(N.x == N.z);
    }
    else
    {
        _793 = _784;
    }
    if (_793)
    {
        a = vec4(N.z - N.y, N.x - N.z, N.y - N.x, 0.0);
    }
    else
    {
        a = vec4(N.z - N.y, N.x + N.z, (-N.y) - N.x, 0.0);
    }
    vec4 _830 = a;
    vec3 _832 = normalize(_830.xyz);
    a.x = _832.x;
    a.y = _832.y;
    a.z = _832.z;
    vec3 _843 = cross(N.xyz, a.xyz);
    b.x = _843.x;
    b.y = _843.y;
    b.z = _843.z;
}

void to_unit_disk(inout float x, inout float y)
{
    float phi = 6.283185482025146484375 * x;
    float r = sqrt(y);
    x = r * cos(phi);
    y = r * sin(phi);
}

vec4 ellipse_sample(vec4 ru, vec4 rv, inout float randu, inout float randv)
{
    float param = randu;
    float param_1 = randv;
    to_unit_disk(param, param_1);
    randu = param;
    randv = param_1;
    return (ru * randu) + (rv * randv);
}

vec4 disk_light_sample(vec4 v, float randu, float randv)
{
    vec4 param = v;
    vec4 ru;
    vec4 param_1 = ru;
    vec4 param_2;
    make_orthonormals(param, param_1, param_2);
    ru = param_1;
    vec4 rv = param_2;
    vec4 param_3 = ru;
    vec4 param_4 = rv;
    float param_5 = randu;
    float param_6 = randv;
    vec4 _2936 = ellipse_sample(param_3, param_4, param_5, param_6);
    return _2936;
}

vec4 distant_light_sample(vec4 D, float radius, float randu, float randv)
{
    vec4 param = D;
    float param_1 = randu;
    float param_2 = randv;
    return normalize(D + (disk_light_sample(param, param_1, param_2) * radius));
}

bool background_portal_data_fetch_and_check_side(vec4 P, int index, inout vec4 lightpos, inout vec4 dir)
{
    int portal = _3116.kernel_data.background.portal_offset + index;
    KernelLight _3493;
    _3493.type = push.data_ptr._lights.data[portal].type;
    _3493.co[0] = push.data_ptr._lights.data[portal].co[0];
    _3493.co[1] = push.data_ptr._lights.data[portal].co[1];
    _3493.co[2] = push.data_ptr._lights.data[portal].co[2];
    _3493.shader_id = push.data_ptr._lights.data[portal].shader_id;
    _3493.samples = push.data_ptr._lights.data[portal].samples;
    _3493.max_bounces = push.data_ptr._lights.data[portal].max_bounces;
    _3493.random = push.data_ptr._lights.data[portal].random;
    _3493.strength[0] = push.data_ptr._lights.data[portal].strength[0];
    _3493.strength[1] = push.data_ptr._lights.data[portal].strength[1];
    _3493.strength[2] = push.data_ptr._lights.data[portal].strength[2];
    _3493.pad1 = push.data_ptr._lights.data[portal].pad1;
    _3493.tfm.x = push.data_ptr._lights.data[portal].tfm.x;
    _3493.tfm.y = push.data_ptr._lights.data[portal].tfm.y;
    _3493.tfm.z = push.data_ptr._lights.data[portal].tfm.z;
    _3493.itfm.x = push.data_ptr._lights.data[portal].itfm.x;
    _3493.itfm.y = push.data_ptr._lights.data[portal].itfm.y;
    _3493.itfm.z = push.data_ptr._lights.data[portal].itfm.z;
    _3493.uni[0] = push.data_ptr._lights.data[portal].uni[0];
    _3493.uni[1] = push.data_ptr._lights.data[portal].uni[1];
    _3493.uni[2] = push.data_ptr._lights.data[portal].uni[2];
    _3493.uni[3] = push.data_ptr._lights.data[portal].uni[3];
    _3493.uni[4] = push.data_ptr._lights.data[portal].uni[4];
    _3493.uni[5] = push.data_ptr._lights.data[portal].uni[5];
    _3493.uni[6] = push.data_ptr._lights.data[portal].uni[6];
    _3493.uni[7] = push.data_ptr._lights.data[portal].uni[7];
    _3493.uni[8] = push.data_ptr._lights.data[portal].uni[8];
    _3493.uni[9] = push.data_ptr._lights.data[portal].uni[9];
    _3493.uni[10] = push.data_ptr._lights.data[portal].uni[10];
    _3493.uni[11] = push.data_ptr._lights.data[portal].uni[11];
    KernelLight klight = _3493;
    lightpos = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
    dir = vec4(klight.uni[8], klight.uni[9], klight.uni[10], 0.0);
    if (dot(dir.xyz, (P - lightpos).xyz) > 9.9999997473787516355514526367188e-05)
    {
        return true;
    }
    return false;
}

int background_num_possible_portals(vec4 P)
{
    int num_possible_portals = 0;
    vec4 lightpos;
    vec4 dir;
    for (int p = 0; p < _3116.kernel_data.background.num_portals; p++)
    {
        vec4 param = P;
        int param_1 = p;
        vec4 param_2 = lightpos;
        vec4 param_3 = dir;
        bool _3712 = background_portal_data_fetch_and_check_side(param, param_1, param_2, param_3);
        lightpos = param_2;
        dir = param_3;
        if (_3712)
        {
            num_possible_portals++;
        }
    }
    return num_possible_portals;
}

vec4 sample_uniform_sphere(float u1, float u2)
{
    float z = 1.0 - (2.0 * u1);
    float r = sqrt(max(0.0, 1.0 - (z * z)));
    float phi = 6.283185482025146484375 * u2;
    float x = r * cos(phi);
    float y = r * sin(phi);
    return vec4(x, y, z, 0.0);
}

vec4 background_portal_sample(vec4 P, float randu, inout float randv, int num_possible, inout int sampled_portal, inout float pdf)
{
    randv *= float(num_possible);
    int portal = int(randv);
    randv -= float(portal);
    vec4 lightpos;
    vec4 dir;
    vec4 D;
    float t;
    for (int p = 0; p < _3116.kernel_data.background.num_portals; p++)
    {
        vec4 param = P;
        int param_1 = p;
        vec4 param_2 = lightpos;
        vec4 param_3 = dir;
        bool _3755 = background_portal_data_fetch_and_check_side(param, param_1, param_2, param_3);
        lightpos = param_2;
        dir = param_3;
        if (!_3755)
        {
            continue;
        }
        if (portal == 0)
        {
            int portal_1 = _3116.kernel_data.background.portal_offset + p;
            KernelLight _3779;
            _3779.type = push.data_ptr._lights.data[portal_1].type;
            _3779.co[0] = push.data_ptr._lights.data[portal_1].co[0];
            _3779.co[1] = push.data_ptr._lights.data[portal_1].co[1];
            _3779.co[2] = push.data_ptr._lights.data[portal_1].co[2];
            _3779.shader_id = push.data_ptr._lights.data[portal_1].shader_id;
            _3779.samples = push.data_ptr._lights.data[portal_1].samples;
            _3779.max_bounces = push.data_ptr._lights.data[portal_1].max_bounces;
            _3779.random = push.data_ptr._lights.data[portal_1].random;
            _3779.strength[0] = push.data_ptr._lights.data[portal_1].strength[0];
            _3779.strength[1] = push.data_ptr._lights.data[portal_1].strength[1];
            _3779.strength[2] = push.data_ptr._lights.data[portal_1].strength[2];
            _3779.pad1 = push.data_ptr._lights.data[portal_1].pad1;
            _3779.tfm.x = push.data_ptr._lights.data[portal_1].tfm.x;
            _3779.tfm.y = push.data_ptr._lights.data[portal_1].tfm.y;
            _3779.tfm.z = push.data_ptr._lights.data[portal_1].tfm.z;
            _3779.itfm.x = push.data_ptr._lights.data[portal_1].itfm.x;
            _3779.itfm.y = push.data_ptr._lights.data[portal_1].itfm.y;
            _3779.itfm.z = push.data_ptr._lights.data[portal_1].itfm.z;
            _3779.uni[0] = push.data_ptr._lights.data[portal_1].uni[0];
            _3779.uni[1] = push.data_ptr._lights.data[portal_1].uni[1];
            _3779.uni[2] = push.data_ptr._lights.data[portal_1].uni[2];
            _3779.uni[3] = push.data_ptr._lights.data[portal_1].uni[3];
            _3779.uni[4] = push.data_ptr._lights.data[portal_1].uni[4];
            _3779.uni[5] = push.data_ptr._lights.data[portal_1].uni[5];
            _3779.uni[6] = push.data_ptr._lights.data[portal_1].uni[6];
            _3779.uni[7] = push.data_ptr._lights.data[portal_1].uni[7];
            _3779.uni[8] = push.data_ptr._lights.data[portal_1].uni[8];
            _3779.uni[9] = push.data_ptr._lights.data[portal_1].uni[9];
            _3779.uni[10] = push.data_ptr._lights.data[portal_1].uni[10];
            _3779.uni[11] = push.data_ptr._lights.data[portal_1].uni[11];
            KernelLight klight = _3779;
            vec4 axisu = vec4(klight.uni[0], klight.uni[1], klight.uni[2], 0.0);
            vec4 axisv = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
            bool is_round = klight.uni[3] < 0.0;
            if (is_round)
            {
                vec4 param_4 = axisu * 0.5;
                vec4 param_5 = axisv * 0.5;
                float param_6 = randu;
                float param_7 = randv;
                vec4 _3813 = ellipse_sample(param_4, param_5, param_6, param_7);
                lightpos += _3813;
                float param_8 = t;
                vec4 _3823 = normalize_len(lightpos - P, param_8);
                t = param_8;
                D = _3823;
                float param_9 = t;
                pdf = abs(klight.uni[3]) * lamp_light_pdf(dir, -D, param_9);
            }
            else
            {
                vec4 param_10 = P;
                vec4 param_11 = lightpos;
                vec4 param_12 = axisu;
                vec4 param_13 = axisv;
                float param_14 = randu;
                float param_15 = randv;
                bool param_16 = true;
                float _3849 = rect_light_sample(param_10, param_11, param_12, param_13, param_14, param_15, param_16);
                lightpos = param_11;
                pdf = _3849;
                D = normalize(lightpos - P);
            }
            pdf /= float(num_possible);
            sampled_portal = p;
            return D;
        }
        portal--;
    }
    return vec4(0.0);
}

float background_portal_pdf(vec4 P, vec4 direction, int ignore_portal, inout bool is_possible)
{
    float portal_pdf = 0.0;
    int num_possible = 0;
    vec4 lightpos;
    vec4 dir;
    vec4 param_12;
    float param_13;
    float param_14;
    float param_15;
    float t;
    for (int p = 0; p < _3116.kernel_data.background.num_portals; p++)
    {
        if (p == ignore_portal)
        {
            continue;
        }
        vec4 param = P;
        int param_1 = p;
        vec4 param_2 = lightpos;
        vec4 param_3 = dir;
        bool _3550 = background_portal_data_fetch_and_check_side(param, param_1, param_2, param_3);
        lightpos = param_2;
        dir = param_3;
        if (!_3550)
        {
            continue;
        }
        if (is_possible)
        {
            is_possible = true;
        }
        num_possible++;
        int portal = _3116.kernel_data.background.portal_offset + p;
        KernelLight _3575;
        _3575.type = push.data_ptr._lights.data[portal].type;
        _3575.co[0] = push.data_ptr._lights.data[portal].co[0];
        _3575.co[1] = push.data_ptr._lights.data[portal].co[1];
        _3575.co[2] = push.data_ptr._lights.data[portal].co[2];
        _3575.shader_id = push.data_ptr._lights.data[portal].shader_id;
        _3575.samples = push.data_ptr._lights.data[portal].samples;
        _3575.max_bounces = push.data_ptr._lights.data[portal].max_bounces;
        _3575.random = push.data_ptr._lights.data[portal].random;
        _3575.strength[0] = push.data_ptr._lights.data[portal].strength[0];
        _3575.strength[1] = push.data_ptr._lights.data[portal].strength[1];
        _3575.strength[2] = push.data_ptr._lights.data[portal].strength[2];
        _3575.pad1 = push.data_ptr._lights.data[portal].pad1;
        _3575.tfm.x = push.data_ptr._lights.data[portal].tfm.x;
        _3575.tfm.y = push.data_ptr._lights.data[portal].tfm.y;
        _3575.tfm.z = push.data_ptr._lights.data[portal].tfm.z;
        _3575.itfm.x = push.data_ptr._lights.data[portal].itfm.x;
        _3575.itfm.y = push.data_ptr._lights.data[portal].itfm.y;
        _3575.itfm.z = push.data_ptr._lights.data[portal].itfm.z;
        _3575.uni[0] = push.data_ptr._lights.data[portal].uni[0];
        _3575.uni[1] = push.data_ptr._lights.data[portal].uni[1];
        _3575.uni[2] = push.data_ptr._lights.data[portal].uni[2];
        _3575.uni[3] = push.data_ptr._lights.data[portal].uni[3];
        _3575.uni[4] = push.data_ptr._lights.data[portal].uni[4];
        _3575.uni[5] = push.data_ptr._lights.data[portal].uni[5];
        _3575.uni[6] = push.data_ptr._lights.data[portal].uni[6];
        _3575.uni[7] = push.data_ptr._lights.data[portal].uni[7];
        _3575.uni[8] = push.data_ptr._lights.data[portal].uni[8];
        _3575.uni[9] = push.data_ptr._lights.data[portal].uni[9];
        _3575.uni[10] = push.data_ptr._lights.data[portal].uni[10];
        _3575.uni[11] = push.data_ptr._lights.data[portal].uni[11];
        KernelLight klight = _3575;
        vec4 axisu = vec4(klight.uni[0], klight.uni[1], klight.uni[2], 0.0);
        vec4 axisv = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
        bool is_round = klight.uni[3] < 0.0;
        float _n0 = 3.4028234663852885981170418348452e+38;
        float _n1 = 3.4028234663852885981170418348452e+38;
        float _n2 = 3.4028234663852885981170418348452e+38;
        vec4 _n4 = vec4(3.4028234663852885981170418348452e+38);
        vec4 param_4 = P;
        vec4 param_5 = direction;
        float param_6 = 9.9999997473787516355514526367188e-05;
        float param_7 = 3.4028234663852885981170418348452e+38;
        vec4 param_8 = lightpos;
        vec4 param_9 = axisu;
        vec4 param_10 = axisv;
        vec4 param_11 = dir;
        bool param_16 = is_round;
        bool _3621 = ray_quad_intersect(param_4, param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16);
        _n4 = param_12;
        _n0 = param_13;
        _n1 = param_14;
        _n2 = param_15;
        if (!_3621)
        {
            continue;
        }
        if (is_round)
        {
            float param_17 = t;
            vec4 _3640 = normalize_len(lightpos - P, param_17);
            t = param_17;
            vec4 D = _3640;
            float param_18 = t;
            portal_pdf += (abs(klight.uni[3]) * lamp_light_pdf(dir, -D, param_18));
        }
        else
        {
            vec4 param_19 = P;
            vec4 param_20 = lightpos;
            vec4 param_21 = axisu;
            vec4 param_22 = axisv;
            float param_23 = 0.0;
            float param_24 = 0.0;
            bool param_25 = false;
            float _3666 = rect_light_sample(param_19, param_20, param_21, param_22, param_23, param_24, param_25);
            lightpos = param_20;
            portal_pdf += _3666;
        }
    }
    if (ignore_portal >= 0)
    {
        num_possible++;
    }
    float _3680;
    if (num_possible > 0)
    {
        _3680 = portal_pdf / float(num_possible);
    }
    else
    {
        _3680 = 0.0;
    }
    return _3680;
}

float sqr(float a)
{
    return a * a;
}

void sample_uniform_cone(vec4 N, float angle, float randu, float randv, out vec4 omega_in, out float pdf)
{
    float zMin = cos(angle);
    float z = (zMin - (zMin * randu)) + randu;
    float param = z;
    float param_1 = 1.0 - sqr(param);
    float r = safe_sqrtf(param_1);
    float phi = 6.283185482025146484375 * randv;
    float x = r * cos(phi);
    float y = r * sin(phi);
    vec4 param_2 = N;
    vec4 T;
    vec4 param_3 = T;
    vec4 param_4;
    make_orthonormals(param_2, param_3, param_4);
    T = param_3;
    vec4 B = param_4;
    omega_in = ((T * x) + (B * y)) + (N * z);
    pdf = 0.15915493667125701904296875 / (1.0 - zMin);
}

vec4 background_sun_sample(float randu, float randv, inout float pdf)
{
    vec4 N = float4_to_float3(_3116.kernel_data.background.sun);
    float angle = _3116.kernel_data.background.sun.w;
    float param = angle;
    float param_1 = randu;
    float param_2 = randv;
    vec4 D;
    vec4 param_3 = D;
    float param_4 = pdf;
    sample_uniform_cone(N, param, param_1, param_2, param_3, param_4);
    D = param_3;
    pdf = param_4;
    return D;
}

float inverse_lerp(float a, float b, float x)
{
    return (x - a) / (b - a);
}

vec4 equirectangular_range_to_direction(float u, float v, vec4 range)
{
    float phi = (range.x * u) + range.y;
    float theta = (range.z * v) + range.w;
    float sin_theta = sin(theta);
    return vec4(sin_theta * cos(phi), sin_theta * sin(phi), cos(theta), 0.0);
}

vec4 equirectangular_to_direction(float u, float v)
{
    float param = u;
    float param_1 = v;
    vec4 param_2 = vec4(-6.283185482025146484375, 3.1415927410125732421875, -3.1415927410125732421875, 3.1415927410125732421875);
    return equirectangular_range_to_direction(param, param_1, param_2);
}

vec4 background_map_sample(float randu, float randv, inout float pdf)
{
    int res_x = _3116.kernel_data.background.map_res_x;
    int res_y = _3116.kernel_data.background.map_res_y;
    int cdf_width = res_x + 1;
    int first = 0;
    int count = res_y;
    while (count > 0)
    {
        int _step = count >> 1;
        int middle = first + _step;
        if (push.data_ptr._light_background_marginal_cdf.data[middle].y < randv)
        {
            first = middle + 1;
            count -= (_step + 1);
        }
        else
        {
            count = _step;
        }
    }
    int index_v = max(0, (first - 1));
    if (!((index_v >= 0) && (index_v < res_y)))
    {
        // unimplemented ext op 12
    }
    vec2 cdf_v = push.data_ptr._light_background_marginal_cdf.data[index_v];
    vec2 cdf_next_v = push.data_ptr._light_background_marginal_cdf.data[index_v + 1];
    vec2 cdf_last_v = push.data_ptr._light_background_marginal_cdf.data[res_y];
    float param = cdf_v.y;
    float param_1 = cdf_next_v.y;
    float param_2 = randv;
    float dv = inverse_lerp(param, param_1, param_2);
    float v = (float(index_v) + dv) / float(res_y);
    first = 0;
    count = res_x;
    while (count > 0)
    {
        int _step_1 = count >> 1;
        int middle_1 = first + _step_1;
        if (push.data_ptr._light_background_conditional_cdf.data[(index_v * cdf_width) + middle_1].y < randu)
        {
            first = middle_1 + 1;
            count -= (_step_1 + 1);
        }
        else
        {
            count = _step_1;
        }
    }
    int index_u = max(0, (first - 1));
    if (!((index_u >= 0) && (index_u < res_x)))
    {
        // unimplemented ext op 12
    }
    vec2 cdf_u = push.data_ptr._light_background_conditional_cdf.data[(index_v * cdf_width) + index_u];
    vec2 cdf_next_u = push.data_ptr._light_background_conditional_cdf.data[((index_v * cdf_width) + index_u) + 1];
    vec2 cdf_last_u = push.data_ptr._light_background_conditional_cdf.data[(index_v * cdf_width) + res_x];
    float param_3 = cdf_u.y;
    float param_4 = cdf_next_u.y;
    float param_5 = randu;
    float du = inverse_lerp(param_3, param_4, param_5);
    float u = (float(index_u) + du) / float(res_x);
    float sin_theta = sin(3.1415927410125732421875 * v);
    float denom = ((19.739208221435546875 * sin_theta) * cdf_last_u.x) * cdf_last_v.x;
    if ((sin_theta == 0.0) || (denom == 0.0))
    {
        pdf = 0.0;
    }
    else
    {
        pdf = (cdf_u.x * cdf_v.x) / denom;
    }
    float param_6 = u;
    float param_7 = v;
    return equirectangular_to_direction(param_6, param_7);
}

float pdf_uniform_cone(vec4 N, vec4 D, float angle)
{
    float zMin = cos(angle);
    float z = dot(N.xyz, D.xyz);
    if (z > zMin)
    {
        return 0.15915493667125701904296875 / (1.0 - zMin);
    }
    return 0.0;
}

float background_sun_pdf(vec4 D)
{
    vec4 N = float4_to_float3(_3116.kernel_data.background.sun);
    float angle = _3116.kernel_data.background.sun.w;
    vec4 param = D;
    float param_1 = angle;
    return pdf_uniform_cone(N, param, param_1);
}

vec2 direction_to_equirectangular_range(vec4 dir, vec4 range)
{
    if (is_zero(dir))
    {
        return vec2(0.0);
    }
    float u = (atan(dir.y, dir.x) - range.y) / range.x;
    float v = (acos(dir.z / length(dir.xyz)) - range.w) / range.z;
    return vec2(u, v);
}

vec2 direction_to_equirectangular(vec4 dir)
{
    vec4 param = dir;
    vec4 param_1 = vec4(-6.283185482025146484375, 3.1415927410125732421875, -3.1415927410125732421875, 3.1415927410125732421875);
    return direction_to_equirectangular_range(param, param_1);
}

float background_map_pdf(vec4 direction)
{
    vec4 param = direction;
    vec2 uv = direction_to_equirectangular(param);
    int res_x = _3116.kernel_data.background.map_res_x;
    int res_y = _3116.kernel_data.background.map_res_y;
    int cdf_width = res_x + 1;
    float sin_theta = sin(uv.y * 3.1415927410125732421875);
    if (sin_theta == 0.0)
    {
        return 0.0;
    }
    int index_u = clamp(int(uv.x * float(res_x)), 0, res_x - 1);
    int index_v = clamp(int(uv.y * float(res_y)), 0, res_y - 1);
    vec2 cdf_last_u = push.data_ptr._light_background_conditional_cdf.data[(index_v * cdf_width) + res_x];
    vec2 cdf_last_v = push.data_ptr._light_background_marginal_cdf.data[res_y];
    float denom = ((19.739208221435546875 * sin_theta) * cdf_last_u.x) * cdf_last_v.x;
    if (denom == 0.0)
    {
        return 0.0;
    }
    vec2 cdf_u = push.data_ptr._light_background_conditional_cdf.data[(index_v * cdf_width) + index_u];
    vec2 cdf_v = push.data_ptr._light_background_marginal_cdf.data[index_v];
    return (cdf_u.x * cdf_v.x) / denom;
}

vec4 background_light_sample(vec4 P, inout float randu, float randv, inout float pdf)
{
    float portal_method_pdf = _3116.kernel_data.background.portal_weight;
    float sun_method_pdf = _3116.kernel_data.background.sun_weight;
    float map_method_pdf = _3116.kernel_data.background.map_weight;
    int num_portals = 0;
    if (portal_method_pdf > 0.0)
    {
        vec4 param = P;
        num_portals = background_num_possible_portals(param);
        if (num_portals == 0)
        {
            portal_method_pdf = 0.0;
        }
    }
    float pdf_fac = (portal_method_pdf + sun_method_pdf) + map_method_pdf;
    if (pdf_fac == 0.0)
    {
        pdf = 0.079577468335628509521484375;
        float param_1 = randu;
        float param_2 = randv;
        return sample_uniform_sphere(param_1, param_2);
    }
    pdf_fac = 1.0 / pdf_fac;
    portal_method_pdf *= pdf_fac;
    sun_method_pdf *= pdf_fac;
    map_method_pdf *= pdf_fac;
    float sun_method_cdf = portal_method_pdf + sun_method_pdf;
    int method = 0;
    vec4 D;
    if (randu < portal_method_pdf)
    {
        method = 0;
        if (!(portal_method_pdf == 1.0))
        {
            randu /= portal_method_pdf;
        }
        vec4 param_3 = P;
        float param_4 = randu;
        float param_5 = randv;
        int param_6 = num_portals;
        int portal;
        int param_7 = portal;
        float param_8 = pdf;
        vec4 _3994 = background_portal_sample(param_3, param_4, param_5, param_6, param_7, param_8);
        portal = param_7;
        pdf = param_8;
        D = _3994;
        if (num_portals > 1)
        {
            bool null_boo = false;
            vec4 param_9 = P;
            vec4 param_10 = D;
            int param_11 = portal;
            bool param_12 = null_boo;
            float _4010 = background_portal_pdf(param_9, param_10, param_11, param_12);
            null_boo = param_12;
            pdf += _4010;
        }
        if (portal_method_pdf == 1.0)
        {
            return D;
        }
        pdf *= portal_method_pdf;
    }
    else
    {
        if (randu < sun_method_cdf)
        {
            method = 1;
            if (!(sun_method_pdf == 1.0))
            {
                randu = (randu - portal_method_pdf) / sun_method_pdf;
            }
            float param_13 = randu;
            float param_14 = randv;
            float param_15 = pdf;
            vec4 _4044 = background_sun_sample(param_13, param_14, param_15);
            pdf = param_15;
            D = _4044;
            if (sun_method_pdf == 1.0)
            {
                return D;
            }
            pdf *= sun_method_pdf;
        }
        else
        {
            method = 2;
            if (!(map_method_pdf == 1.0))
            {
                randu = (randu - sun_method_cdf) / map_method_pdf;
            }
            float param_16 = randu;
            float param_17 = randv;
            float param_18 = pdf;
            vec4 _4071 = background_map_sample(param_16, param_17, param_18);
            pdf = param_18;
            D = _4071;
            if (map_method_pdf == 1.0)
            {
                return D;
            }
            pdf *= map_method_pdf;
        }
    }
    if ((method != 0) && (!(portal_method_pdf == 0.0)))
    {
        bool null_boo_1 = false;
        vec4 param_19 = P;
        vec4 param_20 = D;
        int param_21 = -1;
        bool param_22 = null_boo_1;
        float _4099 = background_portal_pdf(param_19, param_20, param_21, param_22);
        null_boo_1 = param_22;
        pdf += (portal_method_pdf * _4099);
    }
    if ((method != 1) && (!(sun_method_pdf == 0.0)))
    {
        vec4 param_23 = D;
        pdf += (sun_method_pdf * background_sun_pdf(param_23));
    }
    if ((method != 2) && (!(map_method_pdf == 0.0)))
    {
        vec4 param_24 = D;
        pdf += (map_method_pdf * background_map_pdf(param_24));
    }
    return D;
}

vec4 sphere_light_sample(vec4 P, vec4 center, float radius, float randu, float randv)
{
    vec4 param = normalize(P - center);
    float param_1 = randu;
    float param_2 = randv;
    return disk_light_sample(param, param_1, param_2) * radius;
}

bool lamp_light_sample(int lamp, float randu, float randv, vec4 P, inout LightSample ls)
{
    KernelLight _4803;
    _4803.type = push.data_ptr._lights.data[lamp].type;
    _4803.co[0] = push.data_ptr._lights.data[lamp].co[0];
    _4803.co[1] = push.data_ptr._lights.data[lamp].co[1];
    _4803.co[2] = push.data_ptr._lights.data[lamp].co[2];
    _4803.shader_id = push.data_ptr._lights.data[lamp].shader_id;
    _4803.samples = push.data_ptr._lights.data[lamp].samples;
    _4803.max_bounces = push.data_ptr._lights.data[lamp].max_bounces;
    _4803.random = push.data_ptr._lights.data[lamp].random;
    _4803.strength[0] = push.data_ptr._lights.data[lamp].strength[0];
    _4803.strength[1] = push.data_ptr._lights.data[lamp].strength[1];
    _4803.strength[2] = push.data_ptr._lights.data[lamp].strength[2];
    _4803.pad1 = push.data_ptr._lights.data[lamp].pad1;
    _4803.tfm.x = push.data_ptr._lights.data[lamp].tfm.x;
    _4803.tfm.y = push.data_ptr._lights.data[lamp].tfm.y;
    _4803.tfm.z = push.data_ptr._lights.data[lamp].tfm.z;
    _4803.itfm.x = push.data_ptr._lights.data[lamp].itfm.x;
    _4803.itfm.y = push.data_ptr._lights.data[lamp].itfm.y;
    _4803.itfm.z = push.data_ptr._lights.data[lamp].itfm.z;
    _4803.uni[0] = push.data_ptr._lights.data[lamp].uni[0];
    _4803.uni[1] = push.data_ptr._lights.data[lamp].uni[1];
    _4803.uni[2] = push.data_ptr._lights.data[lamp].uni[2];
    _4803.uni[3] = push.data_ptr._lights.data[lamp].uni[3];
    _4803.uni[4] = push.data_ptr._lights.data[lamp].uni[4];
    _4803.uni[5] = push.data_ptr._lights.data[lamp].uni[5];
    _4803.uni[6] = push.data_ptr._lights.data[lamp].uni[6];
    _4803.uni[7] = push.data_ptr._lights.data[lamp].uni[7];
    _4803.uni[8] = push.data_ptr._lights.data[lamp].uni[8];
    _4803.uni[9] = push.data_ptr._lights.data[lamp].uni[9];
    _4803.uni[10] = push.data_ptr._lights.data[lamp].uni[10];
    _4803.uni[11] = push.data_ptr._lights.data[lamp].uni[11];
    KernelLight klight = _4803;
    uint type = uint(klight.type);
    ls.type = type;
    ls.shader = klight.shader_id;
    ls.object = -1;
    ls.prim = -1;
    ls.lamp = lamp;
    ls.u = randu;
    ls.v = randv;
    if (type == 1u)
    {
        vec4 lightD = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
        vec4 D = lightD;
        float radius = klight.uni[0];
        float invarea = klight.uni[2];
        if (radius > 0.0)
        {
            vec4 param = D;
            float param_1 = radius;
            float param_2 = randu;
            float param_3 = randv;
            D = distant_light_sample(param, param_1, param_2, param_3);
        }
        ls.P = D;
        ls.Ng = D;
        ls.D = -D;
        ls.t = 3.4028234663852885981170418348452e+38;
        float costheta = dot(lightD.xyz, D.xyz);
        ls.pdf = invarea / ((costheta * costheta) * costheta);
        ls.eval_fac = ls.pdf;
    }
    else
    {
        if (type == 2u)
        {
            vec4 param_4 = P;
            float param_5 = randu;
            float param_6 = randv;
            float param_7 = ls.pdf;
            vec4 _4894 = background_light_sample(param_4, param_5, param_6, param_7);
            ls.pdf = param_7;
            vec4 D_1 = -_4894;
            ls.P = D_1;
            ls.Ng = D_1;
            ls.D = -D_1;
            ls.t = 3.4028234663852885981170418348452e+38;
            ls.eval_fac = 1.0;
        }
        else
        {
            ls.P = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
            if ((type == 0u) || (type == 4u))
            {
                float radius_1 = klight.uni[0];
                if (radius_1 > 0.0)
                {
                    vec4 param_8 = P;
                    vec4 param_9 = ls.P;
                    float param_10 = radius_1;
                    float param_11 = randu;
                    float param_12 = randv;
                    ls.P += sphere_light_sample(param_8, param_9, param_10, param_11, param_12);
                }
                float param_13 = ls.t;
                vec4 _4953 = normalize_len(ls.P - P, param_13);
                ls.t = param_13;
                ls.D = _4953;
                ls.Ng = -ls.D;
                float invarea_1 = klight.uni[1];
                ls.eval_fac = 0.079577468335628509521484375 * invarea_1;
                ls.pdf = invarea_1;
                if (type == 4u)
                {
                    vec4 dir = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
                    vec4 param_14 = dir;
                    float param_15 = klight.uni[2];
                    float param_16 = klight.uni[3];
                    vec4 param_17 = ls.Ng;
                    ls.eval_fac *= spot_light_attenuation(param_14, param_15, param_16, param_17);
                    if (ls.eval_fac == 0.0)
                    {
                        return false;
                    }
                }
                vec2 uv = map_to_sphere(ls.Ng);
                ls.u = uv.x;
                ls.v = uv.y;
                float param_18 = ls.t;
                ls.pdf *= lamp_light_pdf(ls.Ng, -ls.D, param_18);
            }
            else
            {
                vec4 axisu = vec4(klight.uni[0], klight.uni[1], klight.uni[2], 0.0);
                vec4 axisv = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
                vec4 D_2 = vec4(klight.uni[8], klight.uni[9], klight.uni[10], 0.0);
                float invarea_2 = abs(klight.uni[3]);
                bool is_round = klight.uni[3] < 0.0;
                if (dot((ls.P - P).xyz, D_2.xyz) > 0.0)
                {
                    return false;
                }
                vec4 inplane;
                if (is_round)
                {
                    vec4 param_19 = axisu * 0.5;
                    vec4 param_20 = axisv * 0.5;
                    float param_21 = randu;
                    float param_22 = randv;
                    vec4 _5085 = ellipse_sample(param_19, param_20, param_21, param_22);
                    inplane = _5085;
                    ls.P += inplane;
                    ls.pdf = invarea_2;
                }
                else
                {
                    inplane = ls.P;
                    vec4 param_23 = P;
                    vec4 param_24 = ls.P;
                    vec4 param_25 = axisu;
                    vec4 param_26 = axisv;
                    float param_27 = randu;
                    float param_28 = randv;
                    bool param_29 = true;
                    float _5110 = rect_light_sample(param_23, param_24, param_25, param_26, param_27, param_28, param_29);
                    ls.P = param_24;
                    ls.pdf = _5110;
                    inplane = ls.P - inplane;
                }
                ls.u = (dot(inplane.xyz, axisu.xyz) * (1.0 / dot(axisu.xyz, axisu.xyz))) + 0.5;
                ls.v = (dot(inplane.xyz, axisv.xyz) * (1.0 / dot(axisv.xyz, axisv.xyz))) + 0.5;
                ls.Ng = D_2;
                float param_30 = ls.t;
                vec4 _5155 = normalize_len(ls.P - P, param_30);
                ls.t = param_30;
                ls.D = _5155;
                ls.eval_fac = 0.25 * invarea_2;
                if (is_round)
                {
                    float param_31 = ls.t;
                    ls.pdf *= lamp_light_pdf(D_2, -ls.D, param_31);
                }
            }
        }
    }
    ls.pdf *= _3116.kernel_data.integrator.pdf_lights;
    return ls.pdf > 0.0;
}

bool light_sample(inout vec2 rand, float time, vec4 P, int bounce, inout LightSample ls)
{
    int lamp = pay.use_light_pass;
    if (lamp < 0)
    {
        float param = rand.x;
        int _5206 = light_distribution_sample(param);
        rand.x = param;
        int index = _5206;
        KernelLightDistribution _5220;
        _5220.totarea = push.data_ptr._light_distribution.data[index].totarea;
        _5220.prim = push.data_ptr._light_distribution.data[index].prim;
        _5220.data[0] = push.data_ptr._light_distribution.data[index].data[0];
        _5220.data[1] = push.data_ptr._light_distribution.data[index].data[1];
        KernelLightDistribution kdistribution = _5220;
        int prim = kdistribution.prim;
        if (prim >= 0)
        {
            int object = floatBitsToInt(kdistribution.data[1]);
            int shader_flag = floatBitsToInt(kdistribution.data[0]);
            int param_1 = prim;
            int param_2 = object;
            float param_3 = rand.x;
            float param_4 = rand.y;
            float param_5 = time;
            LightSample param_6 = ls;
            triangle_light_sample(param_1, param_2, param_3, param_4, param_5, param_6, P);
            ls = param_6;
            ls.shader |= shader_flag;
            return ls.pdf > 0.0;
        }
        lamp = (-prim) - 1;
    }
    if (float(bounce) > push.data_ptr._lights.data[lamp].max_bounces)
    {
        return false;
    }
    int param_7 = lamp;
    float param_8 = rand.x;
    float param_9 = rand.y;
    vec4 param_10 = P;
    LightSample param_11 = ls;
    bool _5290 = lamp_light_sample(param_7, param_8, param_9, param_10, param_11);
    ls = param_11;
    return _5290;
}

void PLYMO_bsdf_eval_mul3(vec4 value)
{
    sd.dPdv *= value;
    if (sd.num_closure != 0)
    {
        sd.dI.dx *= value;
        sd.dI.dy *= value;
        sd.du.dx *= value.x;
        sd.du.dy *= value.y;
        sd.dv.dx *= value.z;
    }
    else
    {
        sd.dI.dx *= value;
    }
}

bool PLYMO_bsdf_eval_is_zero()
{
    if (sd.num_closure != 0)
    {
        bool _1988 = is_zero(sd.dI.dx);
        bool _1994;
        if (_1988)
        {
            _1994 = is_zero(sd.dI.dy);
        }
        else
        {
            _1994 = _1988;
        }
        bool _2007;
        if (_1994)
        {
            _2007 = is_zero(vec4(sd.du.dx, sd.du.dy, sd.dv.dx, sd.dv.dy));
        }
        else
        {
            _2007 = _1994;
        }
        bool _2014;
        if (_2007)
        {
            _2014 = is_zero(sd.dPdu);
        }
        else
        {
            _2014 = _2007;
        }
        return _2014;
    }
    else
    {
        return is_zero(sd.dI.dx);
    }
}

vec4 PLYMO_bsdf_eval_sum()
{
    if (sd.num_closure != 0)
    {
        return (sd.dI.dx + sd.dI.dy) + vec4(sd.du.dx, sd.du.dy, sd.dv.dx, sd.dv.dy);
    }
    else
    {
        return sd.dI.dx;
    }
}

float max3(vec4 a)
{
    return max(max(a.x, a.y), a.z);
}

void PLYMO_bsdf_eval_mis(float value)
{
    if (sd.num_closure != 0)
    {
        sd.dI.dx *= value;
        sd.dI.dy *= value;
        sd.du.dx *= value;
        sd.du.dy *= value;
        sd.dv.dx *= value;
    }
    else
    {
        sd.dI.dx *= value;
    }
}

void PLYMO_bsdf_eval_mul(float value)
{
    sd.dPdv *= value;
    float param = value;
    PLYMO_bsdf_eval_mis(param);
}

vec4 ray_offset(vec4 P, vec4 Ng)
{
    vec4 res;
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

bool direct_emission(inout LightSample ls, inout bool is_lamp, float rand_terminate)
{
    if (ls.pdf == 0.0)
    {
        return false;
    }
    differential3 dD;
    dD.dx = vec4(0.0);
    dD.dy = vec4(0.0);
    LightSample param = ls;
    vec4 param_1 = -ls.D;
    differential3 param_2 = dD;
    float param_3 = ls.t;
    float param_4 = pay.sd.time;
    vec4 _6511 = direct_emissive_eval(param, param_1, param_2, param_3, param_4);
    ls = param;
    vec4 light_eval = _6511;
    if (G_dump)
    {
        _580.kg.f3[21 + ((rec_num - 1) * 64)] = light_eval;
    }
    if (is_zero(light_eval))
    {
        return false;
    }
    sd.P = pay.sd.P;
    sd.N = pay.sd.N;
    sd.Ng = pay.sd.Ng;
    sd.I = pay.sd.I;
    sd.shader = pay.sd.flag;
    sd.flag = pay.sd.type;
    sd.object_flag = pay.sd.object;
    sd.prim = pay.sd.num_closure;
    sd.type = pay.sd.atomic_offset;
    sd.u = pay.sd.time;
    sd.v = pay.sd.ray_length;
    sd.object = pay.sd.alloc_offset;
    sd.time = uintBitsToFloat(pay.sd.lcg_state);
    sd.dP = pay.sd.dI;
    sd.dI.dx = vec4(intBitsToFloat(pay.state.flag), intBitsToFloat(int(uint(ls.shader) & 268435456u)), intBitsToFloat(1234), intBitsToFloat(rec_num));
    sd.ray_P = ls.D;
    sd.lcg_state = uint(PROFI_IDX);
    sd.num_closure = pay.use_light_pass;
    sd.num_closure_left = 0;
    sd.randb_closure = ls.pdf;
    if (G_dump)
    {
        _580.kg.f1[1 + ((rec_num - 1) * 64)] = ls.pdf;
    }
    executeCallableNV(1u, 1);
    pay.sd.lcg_state = floatBitsToUint(sd.time);
    vec4 param_5 = light_eval / vec4(ls.pdf);
    PLYMO_bsdf_eval_mul3(param_5);
    if ((uint(ls.shader) & 260046848u) != 0u)
    {
        if ((uint(ls.shader) & 134217728u) != 0u)
        {
            sd.dI.dx = vec4(0.0);
        }
        if ((uint(ls.shader) & 67108864u) != 0u)
        {
            sd.dI.dy = vec4(0.0);
        }
        if ((uint(ls.shader) & 33554432u) != 0u)
        {
            sd.du.dx = 0.0;
            sd.du.dy = 0.0;
            sd.dv.dx = 0.0;
        }
    }
    if (PLYMO_bsdf_eval_is_zero())
    {
        return false;
    }
    bool _6665 = _3116.kernel_data.integrator.light_inv_rr_threshold > 0.0;
    bool _6673;
    if (_6665)
    {
        _6673 = (uint(pay.state.flag) & 131072u) == 0u;
    }
    else
    {
        _6673 = _6665;
    }
    if (_6673)
    {
        vec4 param_6 = abs(PLYMO_bsdf_eval_sum());
        float probability = max3(param_6) * _3116.kernel_data.integrator.light_inv_rr_threshold;
        if (probability < 1.0)
        {
            if (rand_terminate >= probability)
            {
                return false;
            }
            float param_7 = 1.0 / probability;
            PLYMO_bsdf_eval_mul(param_7);
        }
    }
    if ((uint(ls.shader) & 1073741824u) != 0u)
    {
        bool transmit = dot(pay.sd.Ng.xyz, ls.D.xyz) < 0.0;
        vec4 _6716;
        if (transmit)
        {
            _6716 = -pay.sd.Ng;
        }
        else
        {
            _6716 = pay.sd.Ng;
        }
        vec4 param_8 = pay.sd.P;
        vec4 param_9 = _6716;
        pay.ray.P = ray_offset(param_8, param_9);
        if (ls.t == 3.4028234663852885981170418348452e+38)
        {
            pay.ray.D = ls.D;
            pay.ray.t = ls.t;
        }
        else
        {
            vec4 param_10 = ls.P;
            vec4 param_11 = ls.Ng;
            pay.ray.D = ray_offset(param_10, param_11) - pay.ray.P;
            float param_12 = pay.ray.t;
            vec4 _6760 = normalize_len(pay.ray.D, param_12);
            pay.ray.t = param_12;
            pay.ray.D = _6760;
        }
        pay.ray.dD.dx = vec4(0.0);
        pay.ray.dD.dy = vec4(0.0);
    }
    else
    {
        pay.ray.t = 0.0;
    }
    bool _6770 = ls.prim == (-1);
    bool _6776;
    if (_6770)
    {
        _6776 = ls.type != 2u;
    }
    else
    {
        _6776 = _6770;
    }
    is_lamp = _6776;
    pay.L.emission = sd.dI.dx;
    pay.L.direct_emission = sd.dI.dy;
    pay.L.indirect = vec4(sd.du.dx, sd.du.dy, sd.dv.dx, sd.dv.dy);
    pay.L.path_total = sd.dPdu;
    pay.L.throughput = sd.dPdv;
    return true;
}

void kernel_branched_path_surface_connect_light()
{
    bool has_emission = false;
    bool is_lamp = (pay.use_light_pass == (-1)) ? false : true;
    vec4 param = pay.L.emission;
    vec2 param_1 = param.xy;
    float param_2 = pay.sd.time;
    vec4 param_3 = pay.sd.P;
    int param_4 = pay.state.bounce;
    LightSample ls;
    LightSample param_5 = ls;
    bool _6982 = light_sample(param_1, param_2, param_3, param_4, param_5);
    ls = param_5;
    if (_6982)
    {
        if (!(param.w == 0.0))
        {
            ls.pdf *= 2.0;
        }
        int _6997 = atomicAdd(_6346.counter[40], 1);
        LightSample param_6 = ls;
        bool param_7 = is_lamp;
        float param_8 = param.z;
        bool _7005 = direct_emission(param_6, param_7, param_8);
        ls = param_6;
        is_lamp = param_7;
        pay.type = int(_7005);
        if (G_dump)
        {
            _580.kg.f3[9 + ((rec_num - 1) * 64)] = sd.dI.dx;
        }
        if (G_dump)
        {
            _580.kg.f3[12 + ((rec_num - 1) * 64)] = sd.dPdv;
        }
        if (G_use_light_pass)
        {
            if (G_dump)
            {
                _580.kg.f3[10 + ((rec_num - 1) * 64)] = sd.dI.dy;
            }
            if (G_dump)
            {
                _580.kg.f3[11 + ((rec_num - 1) * 64)] = vec4(sd.du.dx, sd.du.dy, sd.dv.dx, sd.dv.dy);
            }
        }
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
    Dpixel = _580.kg.pixel;
    rec_num = 0;
    G_dump = false;
    if (all(equal(Dpixel, gl_LaunchIDNV.xy)))
    {
        G_dump = true;
        G_use_light_pass = _3116.kernel_data.film.use_light_pass != int(0u);
    }
    rec_num = int(pay.L.indirect.w);
    pay.L.indirect.w = 0.0;
    PROFI_IDX = int(pay.L.direct_emission.w);
    pay.L.direct_emission.w = 0.0;
    if (pay.type == 2)
    {
        indirect_lamp_emission();
    }
    else
    {
        if (pay.type == 0)
        {
            kernel_branched_path_surface_connect_light();
        }
    }
}

