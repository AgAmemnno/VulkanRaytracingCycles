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
    vec4 closure_emission_background;
    vec4 closure_transparent_extinction;
    int atomic_offset;
    int alloc_offset;
};

struct PLMO_SD
{
    ShaderData sd;
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

struct Ray
{
    float t;
    float time;
    vec4 P;
    vec4 D;
    differential3 dP;
    differential3 dD;
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

struct Intersection
{
    float t;
    float u;
    float v;
    int prim;
    int object;
    int type;
};

struct KernelGlobals
{
    Intersection hits_stack[64];
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer ShaderClosurePool;
layout(buffer_reference) buffer _prim_tri_verts_;
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
layout(buffer_reference) buffer _tri_vindex_;
layout(buffer_reference) buffer _tri_patch_;
layout(buffer_reference) buffer _tri_patch_uv_;
layout(buffer_reference) buffer _light_distribution_;
layout(buffer_reference) buffer _lights_;
layout(buffer_reference) buffer _particles_;
layout(buffer_reference) buffer _svm_nodes_;
layout(buffer_reference) buffer _shaders_;
layout(buffer_reference) buffer _lookup_table_;
layout(buffer_reference) buffer _sample_pattern_lut_;
layout(buffer_reference) buffer _texture_info_;
layout(buffer_reference) buffer pool_sc_;
layout(buffer_reference, std430) buffer KernelTextures
{
    _prim_tri_verts_ _prim_tri_verts;
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
    _tri_vindex_ _tri_vindex;
    _tri_patch_ _tri_patch;
    _tri_patch_uv_ _tri_patch_uv;
    _light_distribution_ _light_distribution;
    _lights_ _lights;
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

layout(buffer_reference, std430) readonly buffer _prim_tri_verts_
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

layout(buffer_reference, std430) readonly buffer _tri_vindex_
{
    uvec4 data[];
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

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _2416;

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals kg;
} _5248;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _5252;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    ShaderClosurePool pool_ptr;
} push;

layout(location = 1) callableDataNV PLMO_SD plymo;
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
int PROFI_IDX;
ShaderClosure null_sc;

vec4 normalize_len(vec4 a, inout float t)
{
    t = sqrt(dot(a.xyz, a.xyz));
    float x = 1.0 / t;
    return vec4(a.xyz * x, 0.0);
}

float len_squared(vec4 a)
{
    return dot(a, a);
}

bool ray_aligned_disk_intersect(vec4 ray_P, vec4 ray_D, float ray_t, vec4 disk_P, float disk_radius, inout vec4 isect_P, inout float isect_t)
{
    float disk_t;
    float param = disk_t;
    vec4 _989 = normalize_len(ray_P - disk_P, param);
    disk_t = param;
    vec4 disk_N = _989;
    float div = dot(ray_D, disk_N);
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
    float attenuation = dot(dir, N);
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
    float l = sqrt(dot(co, co));
    float u;
    float v;
    if (l > 0.0)
    {
        bool _735 = co.x == 0.0;
        bool _740;
        if (_735)
        {
            _740 = co.y == 0.0;
        }
        else
        {
            _740 = _735;
        }
        if (_740)
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
    float cos_pi = dot(Ng, I);
    if (cos_pi <= 0.0)
    {
        return 0.0;
    }
    return (t * t) / cos_pi;
}

bool ray_quad_intersect(vec4 ray_P, vec4 ray_D, float ray_mint, float ray_maxt, vec4 quad_P, vec4 quad_u, vec4 quad_v, vec4 quad_n, inout vec4 isect_P, inout float isect_t, inout float isect_u, inout float isect_v, bool ellipse)
{
    float t = (-(dot(ray_P, quad_n) - dot(quad_P, quad_n))) / dot(ray_D, quad_n);
    if ((t < ray_mint) || (t > ray_maxt))
    {
        return false;
    }
    vec4 hit = ray_P + (ray_D * t);
    vec4 inplane = hit - quad_P;
    float u = dot(inplane, quad_u) / dot(quad_u, quad_u);
    if ((u < (-0.5)) || (u > 0.5))
    {
        return false;
    }
    float v = dot(inplane, quad_v) / dot(quad_v, quad_v);
    if ((v < (-0.5)) || (v > 0.5))
    {
        return false;
    }
    bool _1254;
    if (ellipse)
    {
        _1254 = ((u * u) + (v * v)) > 0.25;
    }
    else
    {
        _1254 = ellipse;
    }
    if (_1254)
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

vec4 cross(vec4 e1, vec4 e0)
{
    return vec4(cross(e1.xyz, e0.xyz), 0.0);
}

float rect_light_sample(vec4 P, inout vec4 light_p, vec4 axisu, vec4 axisv, float randu, float randv, bool sample_coord)
{
    vec4 corner = (light_p - (axisu * 0.5)) - (axisv * 0.5);
    float axisu_len;
    float param = axisu_len;
    vec4 _1457 = normalize_len(axisu, param);
    axisu_len = param;
    vec4 x = _1457;
    float axisv_len;
    float param_1 = axisv_len;
    vec4 _1464 = normalize_len(axisv, param_1);
    axisv_len = param_1;
    vec4 y = _1464;
    vec4 param_2 = x;
    vec4 param_3 = y;
    vec4 z = cross(param_2, param_3);
    vec4 dir = corner - P;
    float z0 = dot(dir, z);
    if (z0 > 0.0)
    {
        z *= (-1.0);
        z0 *= (-1.0);
    }
    float x0 = dot(dir, x);
    float y0 = dot(dir, y);
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
        float _1698;
        if (hv2 < 0.999998986721038818359375)
        {
            _1698 = (hv * d) / sqrt(1.0 - hv2);
        }
        else
        {
            _1698 = y1;
        }
        float yv = _1698;
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
    KernelLight _3843;
    _3843.type = push.data_ptr._lights.data[lamp].type;
    _3843.co[0] = push.data_ptr._lights.data[lamp].co[0];
    _3843.co[1] = push.data_ptr._lights.data[lamp].co[1];
    _3843.co[2] = push.data_ptr._lights.data[lamp].co[2];
    _3843.shader_id = push.data_ptr._lights.data[lamp].shader_id;
    _3843.samples = push.data_ptr._lights.data[lamp].samples;
    _3843.max_bounces = push.data_ptr._lights.data[lamp].max_bounces;
    _3843.random = push.data_ptr._lights.data[lamp].random;
    _3843.strength[0] = push.data_ptr._lights.data[lamp].strength[0];
    _3843.strength[1] = push.data_ptr._lights.data[lamp].strength[1];
    _3843.strength[2] = push.data_ptr._lights.data[lamp].strength[2];
    _3843.pad1 = push.data_ptr._lights.data[lamp].pad1;
    _3843.tfm.x = push.data_ptr._lights.data[lamp].tfm.x;
    _3843.tfm.y = push.data_ptr._lights.data[lamp].tfm.y;
    _3843.tfm.z = push.data_ptr._lights.data[lamp].tfm.z;
    _3843.itfm.x = push.data_ptr._lights.data[lamp].itfm.x;
    _3843.itfm.y = push.data_ptr._lights.data[lamp].itfm.y;
    _3843.itfm.z = push.data_ptr._lights.data[lamp].itfm.z;
    _3843.uni[0] = push.data_ptr._lights.data[lamp].uni[0];
    _3843.uni[1] = push.data_ptr._lights.data[lamp].uni[1];
    _3843.uni[2] = push.data_ptr._lights.data[lamp].uni[2];
    _3843.uni[3] = push.data_ptr._lights.data[lamp].uni[3];
    _3843.uni[4] = push.data_ptr._lights.data[lamp].uni[4];
    _3843.uni[5] = push.data_ptr._lights.data[lamp].uni[5];
    _3843.uni[6] = push.data_ptr._lights.data[lamp].uni[6];
    _3843.uni[7] = push.data_ptr._lights.data[lamp].uni[7];
    _3843.uni[8] = push.data_ptr._lights.data[lamp].uni[8];
    _3843.uni[9] = push.data_ptr._lights.data[lamp].uni[9];
    _3843.uni[10] = push.data_ptr._lights.data[lamp].uni[10];
    _3843.uni[11] = push.data_ptr._lights.data[lamp].uni[11];
    KernelLight klight = _3843;
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
        float costheta = dot(-lightD, D);
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
            bool _3967 = ray_aligned_disk_intersect(param, param_1, param_2, param_3, param_4, param_5, param_6);
            ls.P = param_5;
            ls.t = param_6;
            if (!_3967)
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
                if (dot(D, Ng) >= 0.0)
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
                bool _4129 = ray_quad_intersect(param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24);
                ls.P = param_20;
                ls.t = param_21;
                ls.u = param_22;
                ls.v = param_23;
                if (!_4129)
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
                    float _4171 = rect_light_sample(param_26, param_27, param_28, param_29, param_30, param_31, param_32);
                    light_P = param_27;
                    ls.pdf = _4171;
                }
                ls.eval_fac = 0.25 * invarea_2;
            }
            else
            {
                return false;
            }
        }
    }
    ls.pdf *= _2416.kernel_data.integrator.pdf_lights;
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

Transform object_fetch_transform(int object, uint type)
{
    if (type == 1u)
    {
        Transform _2294;
        _2294.x = push.data_ptr._objects.data[object].itfm.x;
        _2294.y = push.data_ptr._objects.data[object].itfm.y;
        _2294.z = push.data_ptr._objects.data[object].itfm.z;
        Transform _2293 = _2294;
        return _2293;
    }
    else
    {
        Transform _2306;
        _2306.x = push.data_ptr._objects.data[object].tfm.x;
        _2306.y = push.data_ptr._objects.data[object].tfm.y;
        _2306.z = push.data_ptr._objects.data[object].tfm.z;
        Transform _2305 = _2306;
        return _2305;
    }
}

vec4 transform_point(Transform t, vec4 a)
{
    vec4 c = vec4((((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z)) + t.x.w, (((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z)) + t.y.w, (((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z)) + t.z.w, 0.0);
    c.w = 1.0;
    return c;
}

void object_position_transform(inout vec4 P)
{
    int param = plymo.sd.object;
    uint param_1 = 0u;
    Transform tfm = object_fetch_transform(param, param_1);
    Transform param_2 = tfm;
    tfm = param_2;
    P = transform_point(param_2, P);
}

vec4 transform_direction_transposed(Transform t, vec4 a)
{
    vec4 x = vec4(t.x.x, t.y.x, t.z.x, 0.0);
    vec4 y = vec4(t.x.y, t.y.y, t.z.y, 0.0);
    vec4 z = vec4(t.x.z, t.y.z, t.z.z, 0.0);
    return vec4(dot(x, a), dot(y, a), dot(z, a), 0.0);
}

void object_normal_transform(inout vec4 N)
{
    int param = plymo.sd.object;
    uint param_1 = 1u;
    Transform tfm = object_fetch_transform(param, param_1);
    N = normalize(transform_direction_transposed(tfm, N));
}

vec4 transform_direction(Transform t, vec4 a)
{
    vec4 c = vec4(((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z), ((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z), ((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z), 0.0);
    return c;
}

void object_dir_transform(inout vec4 D)
{
    int param = plymo.sd.object;
    uint param_1 = 0u;
    Transform tfm = object_fetch_transform(param, param_1);
    Transform param_2 = tfm;
    tfm = param_2;
    D = transform_direction(param_2, D);
}

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

vec4 safe_normalize(vec4 a)
{
    float t = sqrt(dot(a, a));
    vec4 _571;
    if (!(t == 0.0))
    {
        _571 = a * (1.0 / t);
    }
    else
    {
        _571 = a;
    }
    return _571;
}

bool is_zero(vec4 a)
{
    bool _582 = a.x == 0.0;
    bool _587;
    if (_582)
    {
        _587 = a.y == 0.0;
    }
    else
    {
        _587 = _582;
    }
    bool _592;
    if (_587)
    {
        _592 = a.z == 0.0;
    }
    else
    {
        _592 = _587;
    }
    bool _597;
    if (_592)
    {
        _597 = a.w == 0.0;
    }
    else
    {
        _597 = _592;
    }
    return _597;
}

vec4 triangle_smooth_normal(vec4 Ng, int prim, float u, float v)
{
    uvec4 tri_vindex = push.data_ptr._tri_vindex.data[prim];
    vec4 n0 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.x]);
    vec4 n1 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.y]);
    vec4 n2 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.z]);
    vec4 N = safe_normalize(((n2 * ((1.0 - u) - v)) + (n0 * u)) + (n1 * v));
    return is_zero(N) ? Ng : N;
}

void triangle_dPdudv(int prim, out vec4 dPdu, out vec4 dPdv)
{
    uvec4 tri_vindex = push.data_ptr._tri_vindex.data[prim];
    vec4 p0 = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 0u]);
    vec4 p1 = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 1u]);
    vec4 p2 = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 2u]);
    dPdu = p0 - p2;
    dPdv = p1 - p2;
}

void shader_setup_from_sample(vec4 P, vec4 Ng, vec4 I, int shader, int object, int prim, float u, float v, float t, float time, bool object_space, int lamp)
{
    plymo.sd.P = P;
    plymo.sd.N = Ng;
    plymo.sd.Ng = Ng;
    plymo.sd.I = I;
    plymo.sd.shader = shader;
    if (prim != (-1))
    {
        plymo.sd.type = 1;
    }
    else
    {
        if (lamp != (-1))
        {
            plymo.sd.type = 64;
        }
        else
        {
            plymo.sd.type = 0;
        }
    }
    plymo.sd.object = object;
    plymo.sd.lamp = -1;
    plymo.sd.prim = prim;
    plymo.sd.u = u;
    plymo.sd.v = v;
    plymo.sd.time = time;
    plymo.sd.ray_length = t;
    plymo.sd.flag = push.data_ptr._shaders.data[uint(plymo.sd.shader) & 8388607u].flags;
    plymo.sd.object_flag = 0;
    if (plymo.sd.object != (-1))
    {
        plymo.sd.object_flag |= int(push.data_ptr._object_flag.data[plymo.sd.object]);
    }
    else
    {
        if (lamp != (-1))
        {
            plymo.sd.lamp = lamp;
        }
    }
    if (object_space)
    {
        vec4 param = plymo.sd.P;
        object_position_transform(param);
        plymo.sd.P = param;
        vec4 param_1 = plymo.sd.Ng;
        object_normal_transform(param_1);
        plymo.sd.Ng = param_1;
        plymo.sd.N = plymo.sd.Ng;
        vec4 param_2 = plymo.sd.I;
        object_dir_transform(param_2);
        plymo.sd.I = param_2;
    }
    if ((uint(plymo.sd.type) & 1u) != 0u)
    {
        if ((uint(plymo.sd.shader) & 2147483648u) != 0u)
        {
            vec4 param_3 = Ng;
            int param_4 = plymo.sd.prim;
            float param_5 = plymo.sd.u;
            float param_6 = plymo.sd.v;
            plymo.sd.N = triangle_smooth_normal(param_3, param_4, param_5, param_6);
            if (!((uint(plymo.sd.object_flag) & 4u) != 0u))
            {
                vec4 param_7 = plymo.sd.N;
                object_normal_transform(param_7);
                plymo.sd.N = param_7;
            }
        }
        int param_8 = plymo.sd.prim;
        vec4 param_9 = plymo.sd.dPdu;
        vec4 param_10 = plymo.sd.dPdv;
        triangle_dPdudv(param_8, param_9, param_10);
        plymo.sd.dPdu = param_9;
        plymo.sd.dPdv = param_10;
        if (!((uint(plymo.sd.object_flag) & 4u) != 0u))
        {
            vec4 param_11 = plymo.sd.dPdu;
            object_dir_transform(param_11);
            plymo.sd.dPdu = param_11;
            vec4 param_12 = plymo.sd.dPdv;
            object_dir_transform(param_12);
            plymo.sd.dPdv = param_12;
        }
    }
    else
    {
        plymo.sd.dPdu = vec4(0.0);
        plymo.sd.dPdv = vec4(0.0);
    }
    if (plymo.sd.prim != (-1))
    {
        bool backfacing = dot(plymo.sd.Ng, plymo.sd.I) < 0.0;
        if (backfacing)
        {
            plymo.sd.flag |= 1;
            plymo.sd.Ng = -plymo.sd.Ng;
            plymo.sd.N = -plymo.sd.N;
            plymo.sd.dPdu = -plymo.sd.dPdu;
            plymo.sd.dPdv = -plymo.sd.dPdv;
        }
    }
    plymo.sd.dP.dx = vec4(0.0);
    plymo.sd.dP.dy = vec4(0.0);
    plymo.sd.dI.dx = vec4(0.0);
    plymo.sd.dI.dy = vec4(0.0);
    plymo.sd.du.dx = 0.0;
    plymo.sd.du.dy = 0.0;
    plymo.sd.dv.dx = 0.0;
    plymo.sd.dv.dy = 0.0;
}

void path_state_modify_bounce(bool increase)
{
    if (increase)
    {
        pay.state.bounce++;
    }
    else
    {
        pay.state.bounce--;
    }
}

uint lcg_step_uint(inout uint rng)
{
    rng = (1103515245u * rng) + 12345u;
    return rng;
}

uint lcg_init(uint seed)
{
    uint rng = seed;
    uint param = rng;
    uint _1857 = lcg_step_uint(param);
    rng = param;
    return rng;
}

void shader_eval_surface(int path_flag)
{
    int max_closures;
    if ((uint(path_flag) & 7341952u) != 0u)
    {
        max_closures = 0;
    }
    else
    {
        max_closures = _2416.kernel_data.integrator.max_closures;
    }
    plymo.sd.num_closure = path_flag;
    plymo.sd.num_closure_left = max_closures;
    plymo.sd.alloc_offset = PROFI_IDX;
    executeCallableNV(4u, 1);
    if ((uint(plymo.sd.flag) & 1024u) != 0u)
    {
        uint param = pay.state.rng_hash * 3032234323u;
        plymo.sd.lcg_state = lcg_init(param);
    }
}

float emissive_pdf(vec4 Ng, vec4 I)
{
    float cosNO = abs(dot(Ng, I));
    return float(cosNO > 0.0);
}

vec4 emissive_simple_eval(vec4 Ng, vec4 I)
{
    float res = emissive_pdf(Ng, I);
    return vec4(res, res, res, 0.0);
}

vec4 shader_emissive_eval()
{
    if ((uint(plymo.sd.flag) & 2u) != 0u)
    {
        return emissive_simple_eval(plymo.sd.Ng, plymo.sd.I) * plymo.sd.closure_emission_background;
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
    bool _4528 = shader_constant_emission_eval(param, param_1);
    eval = param_1;
    if (_4528)
    {
        bool _4534 = ls.prim != (-1);
        bool _4542;
        if (_4534)
        {
            _4542 = dot(ls.Ng, I) < 0.0;
        }
        else
        {
            _4542 = _4534;
        }
        if (_4542)
        {
            ls.Ng = -ls.Ng;
        }
    }
    else
    {
        int param_2 = ls.shader;
        int param_3 = ls.object;
        int param_4 = ls.prim;
        float param_5 = ls.u;
        float param_6 = ls.v;
        float param_7 = t;
        float param_8 = time;
        bool param_9 = false;
        int param_10 = ls.lamp;
        shader_setup_from_sample(ls.P, ls.Ng, I, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, param_10);
        ls.Ng = plymo.sd.Ng;
        bool param_11 = true;
        path_state_modify_bounce(param_11);
        int param_12 = 4194304;
        shader_eval_surface(param_12);
        bool param_13 = false;
        path_state_modify_bounce(param_13);
        eval = shader_emissive_eval();
    }
    eval *= ls.eval_fac;
    if (ls.lamp != (-1))
    {
        KernelLight _4608;
        _4608.type = push.data_ptr._lights.data[ls.lamp].type;
        _4608.co[0] = push.data_ptr._lights.data[ls.lamp].co[0];
        _4608.co[1] = push.data_ptr._lights.data[ls.lamp].co[1];
        _4608.co[2] = push.data_ptr._lights.data[ls.lamp].co[2];
        _4608.shader_id = push.data_ptr._lights.data[ls.lamp].shader_id;
        _4608.samples = push.data_ptr._lights.data[ls.lamp].samples;
        _4608.max_bounces = push.data_ptr._lights.data[ls.lamp].max_bounces;
        _4608.random = push.data_ptr._lights.data[ls.lamp].random;
        _4608.strength[0] = push.data_ptr._lights.data[ls.lamp].strength[0];
        _4608.strength[1] = push.data_ptr._lights.data[ls.lamp].strength[1];
        _4608.strength[2] = push.data_ptr._lights.data[ls.lamp].strength[2];
        _4608.pad1 = push.data_ptr._lights.data[ls.lamp].pad1;
        _4608.tfm.x = push.data_ptr._lights.data[ls.lamp].tfm.x;
        _4608.tfm.y = push.data_ptr._lights.data[ls.lamp].tfm.y;
        _4608.tfm.z = push.data_ptr._lights.data[ls.lamp].tfm.z;
        _4608.itfm.x = push.data_ptr._lights.data[ls.lamp].itfm.x;
        _4608.itfm.y = push.data_ptr._lights.data[ls.lamp].itfm.y;
        _4608.itfm.z = push.data_ptr._lights.data[ls.lamp].itfm.z;
        _4608.uni[0] = push.data_ptr._lights.data[ls.lamp].uni[0];
        _4608.uni[1] = push.data_ptr._lights.data[ls.lamp].uni[1];
        _4608.uni[2] = push.data_ptr._lights.data[ls.lamp].uni[2];
        _4608.uni[3] = push.data_ptr._lights.data[ls.lamp].uni[3];
        _4608.uni[4] = push.data_ptr._lights.data[ls.lamp].uni[4];
        _4608.uni[5] = push.data_ptr._lights.data[ls.lamp].uni[5];
        _4608.uni[6] = push.data_ptr._lights.data[ls.lamp].uni[6];
        _4608.uni[7] = push.data_ptr._lights.data[ls.lamp].uni[7];
        _4608.uni[8] = push.data_ptr._lights.data[ls.lamp].uni[8];
        _4608.uni[9] = push.data_ptr._lights.data[ls.lamp].uni[9];
        _4608.uni[10] = push.data_ptr._lights.data[ls.lamp].uni[10];
        _4608.uni[11] = push.data_ptr._lights.data[ls.lamp].uni[11];
        KernelLight klight = _4608;
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
    float _2401;
    if ((state_bounce - 1) > 0)
    {
        _2401 = _2416.kernel_data.integrator.sample_clamp_indirect;
    }
    else
    {
        _2401 = _2416.kernel_data.integrator.sample_clamp_direct;
    }
    float limit = _2401;
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
    for (int lamp = 0; lamp < _2416.kernel_data.integrator.num_all_lights; lamp++)
    {
        LightSample param = ls;
        int param_1 = lamp;
        vec4 param_2 = pay.ray.P;
        vec4 param_3 = pay.ray.D;
        float param_4 = pay.ray.t;
        bool _4649 = lamp_light_eval(param, param_1, param_2, param_3, param_4);
        ls = param;
        if (!_4649)
        {
            continue;
        }
        if ((uint(ls.shader) & 260046848u) != 0u)
        {
            bool _4667 = (uint(ls.shader) & 134217728u) != 0u;
            bool _4674;
            if (_4667)
            {
                _4674 = (uint(state_flag) & 8u) != 0u;
            }
            else
            {
                _4674 = _4667;
            }
            bool _4692;
            if (!_4674)
            {
                bool _4683 = (uint(ls.shader) & 67108864u) != 0u;
                bool _4691;
                if (_4683)
                {
                    _4691 = (uint(state_flag) & 18u) == 18u;
                }
                else
                {
                    _4691 = _4683;
                }
                _4692 = _4691;
            }
            else
            {
                _4692 = _4674;
            }
            bool _4709;
            if (!_4692)
            {
                bool _4701 = (uint(ls.shader) & 33554432u) != 0u;
                bool _4708;
                if (_4701)
                {
                    _4708 = (uint(state_flag) & 4u) != 0u;
                }
                else
                {
                    _4708 = _4701;
                }
                _4709 = _4708;
            }
            else
            {
                _4709 = _4692;
            }
            bool _4727;
            if (!_4709)
            {
                bool _4718 = (uint(ls.shader) & 8388608u) != 0u;
                bool _4726;
                if (_4718)
                {
                    _4726 = (uint(state_flag) & 4096u) != 0u;
                }
                else
                {
                    _4726 = _4718;
                }
                _4727 = _4726;
            }
            else
            {
                _4727 = _4709;
            }
            if (_4727)
            {
                continue;
            }
        }
        LightSample param_5 = ls;
        vec4 param_6 = -pay.ray.D;
        differential3 param_7 = pay.ray.dD;
        float param_8 = ls.t;
        float param_9 = pay.ray.time;
        vec4 _4748 = direct_emissive_eval(param_5, param_6, param_7, param_8, param_9);
        ls = param_5;
        vec4 lamp_L = _4748;
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
    int _2491 = _2416.kernel_data.integrator.num_distribution + 1;
    float r = randu;
    int _len = _2491;
    do
    {
        int half_len = _len >> 1;
        int middle = first + half_len;
        if (r < push.data_ptr._light_distribution.data[middle].totarea)
        {
            _len = half_len;
        }
        else
        {
            first = middle + 1;
            _len = (_len - half_len) - 1;
        }
    } while (_len > 0);
    int index = clamp(first - 1, 0, _2416.kernel_data.integrator.num_distribution - 1);
    float distr_min = push.data_ptr._light_distribution.data[index].totarea;
    float distr_max = push.data_ptr._light_distribution.data[index + 1].totarea;
    randu = (r - distr_min) / (distr_max - distr_min);
    return index;
}

void object_motion_info(int object, inout int numsteps, inout int numverts, inout int numkeys)
{
    if (!(float(numkeys) == 3.4028234663852885981170418348452e+38))
    {
        numkeys = push.data_ptr._objects.data[object].numkeys;
    }
    if (!(float(numkeys) == 3.4028234663852885981170418348452e+38))
    {
        numsteps = push.data_ptr._objects.data[object].numsteps;
    }
    if (!(float(numkeys) == 3.4028234663852885981170418348452e+38))
    {
        numverts = push.data_ptr._objects.data[object].numverts;
    }
}

int find_attribute_motion(int object, uint id, inout uint elem)
{
    uint attr_offset = push.data_ptr._objects.data[object].attribute_map_offset;
    uvec4 attr_map = push.data_ptr._attributes_map.data[attr_offset];
    while (attr_map.x != id)
    {
        attr_offset += 2u;
        attr_map = push.data_ptr._attributes_map.data[attr_offset];
    }
    elem = attr_map.y;
    int _2642;
    if (attr_map.y == 0u)
    {
        _2642 = -1;
    }
    else
    {
        _2642 = int(attr_map.z);
    }
    return _2642;
}

void motion_triangle_verts_for_step(uvec4 tri_vindex, int offset, int numverts, int numsteps, int _step, inout vec4 verts[3])
{
    if (_step == numsteps)
    {
        verts[0] = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 0u]);
        verts[1] = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 1u]);
        verts[2] = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 2u]);
    }
}

void motion_triangle_vertices(int object, int prim, float time, inout vec4 verts[3])
{
    int numsteps = 0;
    int numverts = 0;
    int param = object;
    int param_1 = numsteps;
    int param_2 = numverts;
    int param_3 = null_int;
    object_motion_info(param, param_1, param_2, param_3);
    numsteps = param_1;
    numverts = param_2;
    null_int = param_3;
    int maxstep = numsteps * 2;
    int _step = min(int(time * float(maxstep)), (maxstep - 1));
    float t = (time * float(maxstep)) - float(_step);
    int param_4 = object;
    uint param_5 = 11u;
    uint elem;
    uint param_6 = elem;
    int _2695 = find_attribute_motion(param_4, param_5, param_6);
    elem = param_6;
    int offset = _2695;
    uvec4 tri_vindex = push.data_ptr._tri_vindex.data[prim];
    uvec4 param_7 = tri_vindex;
    int param_8 = offset;
    int param_9 = numverts;
    int param_10 = numsteps;
    int param_11 = _step;
    vec4 param_12[3] = verts;
    motion_triangle_verts_for_step(param_7, param_8, param_9, param_10, param_11, param_12);
    verts = param_12;
    uvec4 param_13 = tri_vindex;
    int param_14 = offset;
    int param_15 = numverts;
    int param_16 = numsteps;
    int param_17 = _step + 1;
    vec4 next_verts[3];
    vec4 param_18[3] = next_verts;
    motion_triangle_verts_for_step(param_13, param_14, param_15, param_16, param_17, param_18);
    next_verts = param_18;
    verts[0] = (verts[0] * (1.0 - t)) + (next_verts[0] * t);
    verts[1] = (verts[1] * (1.0 - t)) + (next_verts[1] * t);
    verts[2] = (verts[2] * (1.0 - t)) + (next_verts[2] * t);
}

void triangle_vertices(int prim, inout vec4 P[3])
{
    uvec4 tri_vindex = push.data_ptr._tri_vindex.data[prim];
    P[0] = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 0u]);
    P[1] = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 1u]);
    P[2] = float4_to_float3(push.data_ptr._prim_tri_verts.data[tri_vindex.w + 2u]);
}

bool triangle_world_space_vertices(int object, int prim, float time, inout vec4 V[3])
{
    bool has_motion = false;
    int object_flag = int(push.data_ptr._object_flag.data[object]);
    if (((uint(object_flag) & 64u) != 0u) && (time >= 0.0))
    {
        int param = object;
        int param_1 = prim;
        float param_2 = time;
        vec4 param_3[3] = V;
        motion_triangle_vertices(param, param_1, param_2, param_3);
        V = param_3;
        has_motion = true;
    }
    else
    {
        int param_4 = prim;
        vec4 param_5[3];
        triangle_vertices(param_4, param_5);
        V = param_5;
    }
    if (!((uint(object_flag) & 4u) != 0u))
    {
        int param_6 = object;
        uint param_7 = 0u;
        Transform tfm = object_fetch_transform(param_6, param_7);
        Transform param_8 = tfm;
        tfm = param_8;
        V[0] = transform_point(param_8, V[0]);
        Transform param_9 = tfm;
        tfm = param_9;
        V[1] = transform_point(param_9, V[1]);
        Transform param_10 = tfm;
        tfm = param_10;
        V[2] = transform_point(param_10, V[2]);
        has_motion = true;
    }
    return has_motion;
}

vec4 safe_normalize_len(vec4 a, inout float t)
{
    t = sqrt(dot(a.xyz, a.xyz));
    vec4 _543;
    if (!(t == 0.0))
    {
        _543 = a / vec4(t);
    }
    else
    {
        _543 = a;
    }
    return _543;
}

float fast_acosf(float x)
{
    float f = abs(x);
    float _945;
    if (f < 1.0)
    {
        _945 = 1.0 - (1.0 - f);
    }
    else
    {
        _945 = 1.0;
    }
    float m = _945;
    float a = sqrt(1.0 - m) * (1.57079637050628662109375 + (m * ((-0.21330098807811737060546875) + (m * (0.077980481088161468505859375 + (m * (-0.02164095081388950347900390625)))))));
    float _972;
    if (x < 0.0)
    {
        _972 = 3.1415927410125732421875 - a;
    }
    else
    {
        _972 = a;
    }
    return _972;
}

float copysignf(float a, float b)
{
    float r = abs(a);
    float s = sign(b);
    float _617;
    if (s >= 0.0)
    {
        _617 = r;
    }
    else
    {
        _617 = -r;
    }
    return _617;
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
    vec4 param = v2 + v0;
    vec4 param_1 = e0;
    float U = dot(cross(param, param_1), ray_dir);
    vec4 param_2 = v0 + v1;
    vec4 param_3 = e1;
    float V = dot(cross(param_2, param_3), ray_dir);
    vec4 param_4 = v1 + v2;
    vec4 param_5 = e2;
    float W = dot(cross(param_4, param_5), ray_dir);
    float minUVW = min(U, min(V, W));
    float maxUVW = max(U, max(V, W));
    if ((minUVW < 0.0) && (maxUVW > 0.0))
    {
        return false;
    }
    vec4 param_6 = e1;
    vec4 param_7 = e0;
    vec4 Ng1 = cross(param_6, param_7);
    vec4 Ng = Ng1 + Ng1;
    float den = dot(Ng, dir);
    if (den == 0.0)
    {
        return false;
    }
    float T = dot(v0, Ng);
    int sign_den = floatBitsToInt(den) & (-2147483648);
    float param_8 = T;
    int param_9 = sign_den;
    float sign_T = xor_signmask(param_8, param_9);
    bool _1146 = sign_T < 0.0;
    bool _1159;
    if (!_1146)
    {
        float param_10 = den;
        int param_11 = sign_den;
        _1159 = sign_T > (ray_t * xor_signmask(param_10, param_11));
    }
    else
    {
        _1159 = _1146;
    }
    if (_1159)
    {
        return false;
    }
    float inv_den = 1.0 / den;
    isect_u = U * inv_den;
    isect_v = V * inv_den;
    isect_t = T * inv_den;
    return true;
}

float triangle_area(vec4 v1, vec4 v2, vec4 v3)
{
    return sqrt(dot(cross(v3.xyz - v2.xyz, v1.xyz - v2.xyz), cross(v3.xyz - v2.xyz, v1.xyz - v2.xyz))) * 0.5;
}

float triangle_light_pdf_area(vec4 Ng, vec4 I, float t)
{
    float pdf = _2416.kernel_data.integrator.pdf_triangles;
    float cos_pi = abs(dot(Ng, I));
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
    bool _2914 = triangle_world_space_vertices(param, param_1, param_2, param_3);
    V = param_3;
    bool has_motion = _2914;
    vec4 e0 = V[1] - V[0];
    vec4 e1 = V[2] - V[0];
    vec4 e2 = V[2] - V[1];
    float longest_edge_squared = max(len_squared(e0), max(len_squared(e1), len_squared(e2)));
    vec4 param_4 = e0;
    vec4 param_5 = e1;
    vec4 N0 = cross(param_4, param_5);
    float Nl = 0.0;
    float param_6 = Nl;
    vec4 _2953 = safe_normalize_len(N0, param_6);
    ls.Ng = _2953;
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
        vec4 param_7 = v0_p;
        vec4 param_8 = v1_p;
        vec4 u01 = safe_normalize(cross(param_7, param_8));
        vec4 param_9 = v0_p;
        vec4 param_10 = v2_p;
        vec4 u02 = safe_normalize(cross(param_9, param_10));
        vec4 param_11 = v1_p;
        vec4 param_12 = v2_p;
        vec4 u12 = safe_normalize(cross(param_11, param_12));
        vec4 A = safe_normalize(v0_p);
        vec4 B = safe_normalize(v1_p);
        vec4 C = safe_normalize(v2_p);
        float cos_alpha = dot(u02, u01);
        float cos_beta = -dot(u01, u12);
        float cos_gamma = dot(u02, u12);
        float param_13 = cos_alpha;
        float alpha = fast_acosf(param_13);
        float param_14 = cos_beta;
        float beta = fast_acosf(param_14);
        float param_15 = cos_gamma;
        float gamma = fast_acosf(param_15);
        float solid_angle = ((alpha + beta) + gamma) - 3.1415927410125732421875;
        float cos_c = dot(A, B);
        float param_16 = alpha;
        float _3105 = fast_sinf(param_16);
        float sin_alpha = _3105;
        float product = sin_alpha * cos_c;
        float phi = (randu * solid_angle) - alpha;
        float param_17 = phi;
        float param_18;
        float param_19;
        fast_sincosf(param_17, param_18, param_19);
        float s = param_18;
        float t = param_19;
        float u = t - cos_alpha;
        float v = s + product;
        vec4 U = safe_normalize(C - (A * dot(C, A)));
        float q = 1.0;
        float det = ((v * s) + (u * t)) * sin_alpha;
        if (!(det == 0.0))
        {
            q = ((((v * t) - (u * s)) * cos_alpha) - v) / det;
        }
        float temp = max(1.0 - (q * q), 0.0);
        vec4 C_ = safe_normalize((A * q) + (U * sqrt(temp)));
        float z = 1.0 - (randv * (1.0 - dot(C_, B)));
        float param_20 = 1.0 - (z * z);
        ls.D = (B * z) + (safe_normalize(C_ - (B * dot(C_, B))) * safe_sqrtf(param_20));
        vec4 param_21 = P;
        vec4 param_22 = ls.D;
        float param_23 = 3.4028234663852885981170418348452e+38;
        float param_24;
        float param_25;
        float param_26;
        bool _3229 = ray_triangle_intersect(param_21, param_22, param_23, V[0], V[1], V[2], param_24, param_25, param_26);
        ls.u = param_24;
        ls.v = param_25;
        ls.t = param_26;
        if (!_3229)
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
                int param_27 = object;
                int param_28 = prim;
                float param_29 = -1.0;
                vec4 param_30[3] = V;
                bool _3265 = triangle_world_space_vertices(param_27, param_28, param_29, param_30);
                V = param_30;
                area = triangle_area(V[0], V[1], V[2]);
            }
            float pdf = area * _2416.kernel_data.integrator.pdf_triangles;
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
        float param_31 = ls.t;
        vec4 _3330 = normalize_len(ls.P - P, param_31);
        ls.t = param_31;
        ls.D = _3330;
        float param_32 = ls.t;
        ls.pdf = triangle_light_pdf_area(ls.Ng, -ls.D, param_32);
        if (has_motion && (!(area == 0.0)))
        {
            int param_33 = object;
            int param_34 = prim;
            float param_35 = -1.0;
            vec4 param_36[3] = V;
            bool _3357 = triangle_world_space_vertices(param_33, param_34, param_35, param_36);
            V = param_36;
            float area_pre = triangle_area(V[0], V[1], V[2]);
            ls.pdf = (ls.pdf * area_pre) / area;
        }
        ls.u = u_1;
        ls.v = v_1;
    }
}

void make_orthonormals(vec4 N, inout vec4 a, inout vec4 b)
{
    bool _651 = !(N.x == N.y);
    bool _660;
    if (!_651)
    {
        _660 = !(N.x == N.z);
    }
    else
    {
        _660 = _651;
    }
    if (_660)
    {
        a = vec4(N.z - N.y, N.x - N.z, N.y - N.x, 0.0);
    }
    else
    {
        a = vec4(N.z - N.y, N.x + N.z, (-N.y) - N.x, 0.0);
    }
    vec3 _699 = normalize(a.xyz);
    a = vec4(_699.x, _699.y, _699.z, a.w);
    vec3 _706 = cross(N.xyz, a.xyz);
    b = vec4(_706.x, _706.y, _706.z, b.w);
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
    vec4 _1768 = ellipse_sample(param_3, param_4, param_5, param_6);
    return _1768;
}

vec4 distant_light_sample(vec4 D, float radius, float randu, float randv)
{
    vec4 param = D;
    float param_1 = randu;
    float param_2 = randv;
    return normalize(D + (disk_light_sample(param, param_1, param_2) * radius));
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
    KernelLight _3390;
    _3390.type = push.data_ptr._lights.data[lamp].type;
    _3390.co[0] = push.data_ptr._lights.data[lamp].co[0];
    _3390.co[1] = push.data_ptr._lights.data[lamp].co[1];
    _3390.co[2] = push.data_ptr._lights.data[lamp].co[2];
    _3390.shader_id = push.data_ptr._lights.data[lamp].shader_id;
    _3390.samples = push.data_ptr._lights.data[lamp].samples;
    _3390.max_bounces = push.data_ptr._lights.data[lamp].max_bounces;
    _3390.random = push.data_ptr._lights.data[lamp].random;
    _3390.strength[0] = push.data_ptr._lights.data[lamp].strength[0];
    _3390.strength[1] = push.data_ptr._lights.data[lamp].strength[1];
    _3390.strength[2] = push.data_ptr._lights.data[lamp].strength[2];
    _3390.pad1 = push.data_ptr._lights.data[lamp].pad1;
    _3390.tfm.x = push.data_ptr._lights.data[lamp].tfm.x;
    _3390.tfm.y = push.data_ptr._lights.data[lamp].tfm.y;
    _3390.tfm.z = push.data_ptr._lights.data[lamp].tfm.z;
    _3390.itfm.x = push.data_ptr._lights.data[lamp].itfm.x;
    _3390.itfm.y = push.data_ptr._lights.data[lamp].itfm.y;
    _3390.itfm.z = push.data_ptr._lights.data[lamp].itfm.z;
    _3390.uni[0] = push.data_ptr._lights.data[lamp].uni[0];
    _3390.uni[1] = push.data_ptr._lights.data[lamp].uni[1];
    _3390.uni[2] = push.data_ptr._lights.data[lamp].uni[2];
    _3390.uni[3] = push.data_ptr._lights.data[lamp].uni[3];
    _3390.uni[4] = push.data_ptr._lights.data[lamp].uni[4];
    _3390.uni[5] = push.data_ptr._lights.data[lamp].uni[5];
    _3390.uni[6] = push.data_ptr._lights.data[lamp].uni[6];
    _3390.uni[7] = push.data_ptr._lights.data[lamp].uni[7];
    _3390.uni[8] = push.data_ptr._lights.data[lamp].uni[8];
    _3390.uni[9] = push.data_ptr._lights.data[lamp].uni[9];
    _3390.uni[10] = push.data_ptr._lights.data[lamp].uni[10];
    _3390.uni[11] = push.data_ptr._lights.data[lamp].uni[11];
    KernelLight klight = _3390;
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
        float costheta = dot(lightD, D);
        ls.pdf = invarea / ((costheta * costheta) * costheta);
        ls.eval_fac = ls.pdf;
    }
    else
    {
        ls.P = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
        if ((type == 0u) || (type == 4u))
        {
            float radius_1 = klight.uni[0];
            if (radius_1 > 0.0)
            {
                vec4 param_4 = P;
                vec4 param_5 = ls.P;
                float param_6 = radius_1;
                float param_7 = randu;
                float param_8 = randv;
                ls.P += sphere_light_sample(param_4, param_5, param_6, param_7, param_8);
            }
            float param_9 = ls.t;
            vec4 _3510 = normalize_len(ls.P - P, param_9);
            ls.t = param_9;
            ls.D = _3510;
            ls.Ng = -ls.D;
            float invarea_1 = klight.uni[1];
            ls.eval_fac = 0.079577468335628509521484375 * invarea_1;
            ls.pdf = invarea_1;
            if (type == 4u)
            {
                vec4 dir = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
                vec4 param_10 = dir;
                float param_11 = klight.uni[2];
                float param_12 = klight.uni[3];
                vec4 param_13 = ls.Ng;
                ls.eval_fac *= spot_light_attenuation(param_10, param_11, param_12, param_13);
                if (ls.eval_fac == 0.0)
                {
                    return false;
                }
            }
            vec2 uv = map_to_sphere(ls.Ng);
            ls.u = uv.x;
            ls.v = uv.y;
            float param_14 = ls.t;
            ls.pdf *= lamp_light_pdf(ls.Ng, -ls.D, param_14);
        }
        else
        {
            vec4 axisu = vec4(klight.uni[0], klight.uni[1], klight.uni[2], 0.0);
            vec4 axisv = vec4(klight.uni[4], klight.uni[5], klight.uni[6], 0.0);
            vec4 D_1 = vec4(klight.uni[8], klight.uni[9], klight.uni[10], 0.0);
            float invarea_2 = abs(klight.uni[3]);
            bool is_round = klight.uni[3] < 0.0;
            if (dot(ls.P - P, D_1) > 0.0)
            {
                return false;
            }
            vec4 inplane;
            if (is_round)
            {
                vec4 param_15 = axisu * 0.5;
                vec4 param_16 = axisv * 0.5;
                float param_17 = randu;
                float param_18 = randv;
                vec4 _3641 = ellipse_sample(param_15, param_16, param_17, param_18);
                inplane = _3641;
                ls.P += inplane;
                ls.pdf = invarea_2;
            }
            else
            {
                inplane = ls.P;
                vec4 param_19 = P;
                vec4 param_20 = ls.P;
                vec4 param_21 = axisu;
                vec4 param_22 = axisv;
                float param_23 = randu;
                float param_24 = randv;
                bool param_25 = true;
                float _3666 = rect_light_sample(param_19, param_20, param_21, param_22, param_23, param_24, param_25);
                ls.P = param_20;
                ls.pdf = _3666;
                inplane = ls.P - inplane;
            }
            ls.u = (dot(inplane, axisu) * (1.0 / dot(axisu, axisu))) + 0.5;
            ls.v = (dot(inplane, axisv) * (1.0 / dot(axisv, axisv))) + 0.5;
            ls.Ng = D_1;
            float param_26 = ls.t;
            vec4 _3703 = normalize_len(ls.P - P, param_26);
            ls.t = param_26;
            ls.D = _3703;
            ls.eval_fac = 0.25 * invarea_2;
            if (is_round)
            {
                float param_27 = ls.t;
                ls.pdf *= lamp_light_pdf(D_1, -ls.D, param_27);
            }
        }
    }
    ls.pdf *= _2416.kernel_data.integrator.pdf_lights;
    return ls.pdf > 0.0;
}

bool light_sample(inout vec2 rand, float time, vec4 P, int bounce, inout LightSample ls)
{
    int lamp = pay.use_light_pass;
    if (lamp < 0)
    {
        float param = rand.x;
        int _3747 = light_distribution_sample(param);
        rand.x = param;
        int index = _3747;
        KernelLightDistribution _3761;
        _3761.totarea = push.data_ptr._light_distribution.data[index].totarea;
        _3761.prim = push.data_ptr._light_distribution.data[index].prim;
        _3761.data[0] = push.data_ptr._light_distribution.data[index].data[0];
        _3761.data[1] = push.data_ptr._light_distribution.data[index].data[1];
        KernelLightDistribution kdistribution = _3761;
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
    bool _3831 = lamp_light_sample(param_7, param_8, param_9, param_10, param_11);
    ls = param_11;
    return _3831;
}

void PLYMO_bsdf_eval_mul3(vec4 value)
{
    plymo.sd.dPdv *= value;
    if (plymo.sd.num_closure != 0)
    {
        plymo.sd.dI.dx *= value;
        plymo.sd.dI.dy *= value;
        plymo.sd.du.dx *= value.x;
        plymo.sd.du.dy *= value.y;
        plymo.sd.dv.dx *= value.z;
    }
    else
    {
        plymo.sd.dI.dx *= value;
    }
}

bool PLYMO_bsdf_eval_is_zero()
{
    if (plymo.sd.num_closure != 0)
    {
        bool _2175 = is_zero(plymo.sd.dI.dx);
        bool _2181;
        if (_2175)
        {
            _2181 = is_zero(plymo.sd.dI.dy);
        }
        else
        {
            _2181 = _2175;
        }
        bool _2194;
        if (_2181)
        {
            _2194 = is_zero(vec4(plymo.sd.du.dx, plymo.sd.du.dy, plymo.sd.dv.dx, plymo.sd.dv.dy));
        }
        else
        {
            _2194 = _2181;
        }
        bool _2201;
        if (_2194)
        {
            _2201 = is_zero(plymo.sd.dPdu);
        }
        else
        {
            _2201 = _2194;
        }
        return _2201;
    }
    else
    {
        return is_zero(plymo.sd.dI.dx);
    }
}

vec4 PLYMO_bsdf_eval_sum()
{
    if (plymo.sd.num_closure != 0)
    {
        return (plymo.sd.dI.dx + plymo.sd.dI.dy) + vec4(plymo.sd.du.dx, plymo.sd.du.dy, plymo.sd.dv.dx, plymo.sd.dv.dy);
    }
    else
    {
        return plymo.sd.dI.dx;
    }
}

float max3(vec4 a)
{
    return max(max(a.x, a.y), a.z);
}

void PLYMO_bsdf_eval_mis(float value)
{
    if (plymo.sd.num_closure != 0)
    {
        plymo.sd.dI.dx *= value;
        plymo.sd.dI.dy *= value;
        plymo.sd.du.dx *= value;
        plymo.sd.du.dy *= value;
        plymo.sd.dv.dx *= value;
    }
    else
    {
        plymo.sd.dI.dx *= value;
    }
}

void PLYMO_bsdf_eval_mul(float value)
{
    plymo.sd.dPdv *= value;
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
    vec4 _4910 = direct_emissive_eval(param, param_1, param_2, param_3, param_4);
    ls = param;
    vec4 light_eval = _4910;
    if (is_zero(light_eval))
    {
        return false;
    }
    plymo.sd.P = pay.sd.P;
    plymo.sd.N = pay.sd.N;
    plymo.sd.Ng = pay.sd.Ng;
    plymo.sd.I = pay.sd.I;
    plymo.sd.shader = pay.sd.flag;
    plymo.sd.flag = pay.sd.type;
    plymo.sd.object_flag = pay.sd.object;
    plymo.sd.prim = pay.sd.num_closure;
    plymo.sd.type = pay.sd.atomic_offset;
    plymo.sd.u = pay.sd.time;
    plymo.sd.v = pay.sd.ray_length;
    plymo.sd.object = pay.sd.alloc_offset;
    plymo.sd.time = uintBitsToFloat(pay.sd.lcg_state);
    plymo.sd.dP = pay.sd.dI;
    plymo.sd.dI.dx = vec4(intBitsToFloat(123), intBitsToFloat(int(uint(ls.shader) & 268435456u)), intBitsToFloat(1234), 0.0);
    plymo.sd.ray_P = ls.D;
    plymo.sd.lcg_state = uint(PROFI_IDX);
    plymo.sd.num_closure = pay.use_light_pass;
    plymo.sd.num_closure_left = 0;
    plymo.sd.randb_closure = ls.pdf;
    executeCallableNV(3u, 1);
    pay.sd.lcg_state = floatBitsToUint(plymo.sd.time);
    vec4 param_5 = light_eval / vec4(ls.pdf);
    PLYMO_bsdf_eval_mul3(param_5);
    if ((uint(ls.shader) & 260046848u) != 0u)
    {
        if ((uint(ls.shader) & 134217728u) != 0u)
        {
            plymo.sd.dI.dx = vec4(0.0);
        }
        if ((uint(ls.shader) & 67108864u) != 0u)
        {
            plymo.sd.dI.dy = vec4(0.0);
        }
        if ((uint(ls.shader) & 33554432u) != 0u)
        {
            plymo.sd.du.dx = 0.0;
            plymo.sd.du.dy = 0.0;
            plymo.sd.dv.dx = 0.0;
        }
    }
    if (PLYMO_bsdf_eval_is_zero())
    {
        return false;
    }
    bool _5037 = _2416.kernel_data.integrator.light_inv_rr_threshold > 0.0;
    bool _5045;
    if (_5037)
    {
        _5045 = (uint(pay.state.flag) & 131072u) == 0u;
    }
    else
    {
        _5045 = _5037;
    }
    if (_5045)
    {
        vec4 param_6 = abs(PLYMO_bsdf_eval_sum());
        float probability = max3(param_6) * _2416.kernel_data.integrator.light_inv_rr_threshold;
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
        bool transmit = dot(pay.sd.Ng, ls.D) < 0.0;
        vec4 _5086;
        if (transmit)
        {
            _5086 = -pay.sd.Ng;
        }
        else
        {
            _5086 = pay.sd.Ng;
        }
        vec4 param_8 = pay.sd.P;
        vec4 param_9 = _5086;
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
            vec4 _5130 = normalize_len(pay.ray.D, param_12);
            pay.ray.t = param_12;
            pay.ray.D = _5130;
        }
        pay.ray.dD.dx = vec4(0.0);
        pay.ray.dD.dy = vec4(0.0);
    }
    else
    {
        pay.ray.t = 0.0;
    }
    bool _5140 = ls.prim == (-1);
    bool _5146;
    if (_5140)
    {
        _5146 = ls.type != 2u;
    }
    else
    {
        _5146 = _5140;
    }
    is_lamp = _5146;
    pay.L.emission = plymo.sd.dI.dx;
    pay.L.direct_emission = plymo.sd.dI.dy;
    pay.L.indirect = vec4(plymo.sd.du.dx, plymo.sd.du.dy, plymo.sd.dv.dx, plymo.sd.dv.dy);
    pay.L.path_total = plymo.sd.dPdu;
    pay.L.throughput = plymo.sd.dPdv;
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
    bool _5195 = light_sample(param_1, param_2, param_3, param_4, param_5);
    ls = param_5;
    if (_5195)
    {
        if (!(param.w == 0.0))
        {
            ls.pdf *= 2.0;
        }
        LightSample param_6 = ls;
        bool param_7 = is_lamp;
        float param_8 = param.z;
        bool _5215 = direct_emission(param_6, param_7, param_8);
        ls = param_6;
        is_lamp = param_7;
        pay.type = int(_5215);
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
    PROFI_IDX = int(pay.L.direct_emission.x);
    pay.L.direct_emission.x = 0.0;
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

