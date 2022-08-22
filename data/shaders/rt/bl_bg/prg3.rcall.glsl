#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require

struct ShaderClosure
{
    vec4 weight;
    uint type;
    float sample_weight;
    vec4 N;
    int next;
    float data[25];
};

struct differential3
{
    vec4 dx;
    vec4 dy;
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

struct BsdfEval
{
    vec4 diffuse;
    vec4 glossy;
    vec4 transmission;
    vec4 transparent;
    vec4 sum_no_mis;
};

struct PLMO_SD_EVAL
{
    args_sd sd;
    BsdfEval eval;
    vec4 omega_in;
    differential3 domega_in;
    int label;
    int use_light_pass;
    int type;
    float pdf;
};

struct Transform
{
    vec4 x;
    vec4 y;
    vec4 z;
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
} _8902;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _10721;

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals kg;
} _10779;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    ShaderClosurePool pool_ptr;
} push;

layout(location = 0) callableDataInNV PLMO_SD_EVAL arg;
layout(location = 1) callableDataInNV PLMO_SD_EVAL arg2;

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
double STIR[8];
double P[8];
double Q[8];
double A[8];
double B[8];
double C[8];
ShaderClosure sc;
int PROFI_IDX;
ShaderClosure null_sc;

void bsdf_eval_init(uint type, vec4 value)
{
    arg.use_light_pass = _8902.kernel_data.film.use_light_pass;
    if (arg.use_light_pass != 0)
    {
        arg.eval.diffuse = vec4(0.0);
        arg.eval.glossy = vec4(0.0);
        arg.eval.transmission = vec4(0.0);
        arg.eval.transparent = vec4(0.0);
        if (type == 33u)
        {
            arg.eval.transparent = value;
        }
        else
        {
            bool _8930 = (type >= 2u) && (type <= 8u);
            bool _8941;
            if (!_8930)
            {
                _8941 = (type == 31u) || (type == 32u);
            }
            else
            {
                _8941 = _8930;
            }
            if (_8941)
            {
                arg.eval.diffuse = value;
            }
            else
            {
                if (((type >= 9u) && (type <= 20u)) || (type == 29u))
                {
                    arg.eval.glossy = value;
                }
                else
                {
                    if ((type >= 21u) && (type <= 30u))
                    {
                        arg.eval.transmission = value;
                    }
                }
            }
        }
    }
    else
    {
        arg.eval.diffuse = value;
    }
    arg.eval.sum_no_mis = vec4(0.0);
}

vec4 bsdf_diffuse_eval_reflect(vec4 I, vec4 omega_in, out float pdf)
{
    vec4 N = sc.N;
    float cos_pi = max(dot(N, omega_in), 0.0) * 0.3183098733425140380859375;
    pdf = cos_pi;
    return vec4(cos_pi, cos_pi, cos_pi, 0.0);
}

vec4 bsdf_oren_nayar_get_intensity(vec4 n, vec4 v, vec4 l)
{
    float nl = max(dot(n, l), 0.0);
    float nv = max(dot(n, v), 0.0);
    float t = dot(l, v) - (nl * nv);
    if (t > 0.0)
    {
        t /= (max(nl, nv) + 1.1754943508222875079687365372222e-38);
    }
    float is = nl * (sc.data[1] + (sc.data[2] * t));
    return vec4(is, is, is, 0.0);
}

vec4 bsdf_oren_nayar_eval_reflect(vec4 I, vec4 omega_in, inout float pdf)
{
    if (dot(sc.N, omega_in) > 0.0)
    {
        pdf = 0.15915493667125701904296875;
        vec4 param = sc.N;
        vec4 param_1 = I;
        vec4 param_2 = omega_in;
        return bsdf_oren_nayar_get_intensity(param, param_1, param_2);
    }
    else
    {
        pdf = 0.0;
        return vec4(0.0);
    }
}

float safe_acosf(float a)
{
    return acos(clamp(a, -1.0, 1.0));
}

vec4 bsdf_toon_get_intensity(float max_angle, float smooth_rsv, float angle)
{
    float is;
    if (angle < max_angle)
    {
        is = 1.0;
    }
    else
    {
        if ((angle < (max_angle + smooth_rsv)) && (!(smooth_rsv == 0.0)))
        {
            is = 1.0 - ((angle - max_angle) / smooth_rsv);
        }
        else
        {
            is = 0.0;
        }
    }
    return vec4(is, is, is, 0.0);
}

float bsdf_toon_get_sample_angle(float max_angle, float smooth_rsv)
{
    return min(max_angle + smooth_rsv, 1.57079637050628662109375);
}

vec4 bsdf_diffuse_toon_eval_reflect(vec4 I, vec4 omega_in, inout float pdf)
{
    float max_angle = sc.data[0] * 1.57079637050628662109375;
    float smooth_rsv = sc.data[1] * 1.57079637050628662109375;
    float param = max(dot(sc.N, omega_in), 0.0);
    float angle = safe_acosf(param);
    float param_1 = max_angle;
    float param_2 = smooth_rsv;
    float param_3 = angle;
    vec4 eval = bsdf_toon_get_intensity(param_1, param_2, param_3);
    if (eval.x > 0.0)
    {
        float param_4 = max_angle;
        float param_5 = smooth_rsv;
        float sample_angle = bsdf_toon_get_sample_angle(param_4, param_5);
        pdf = 0.15915493667125701904296875 / (1.0 - cos(sample_angle));
        return eval * pdf;
    }
    return vec4(0.0);
}

vec4 bsdf_glossy_toon_eval_reflect(vec4 I, vec4 omega_in, inout float pdf)
{
    float max_angle = sc.data[0] * 1.57079637050628662109375;
    float smooth_rsv = sc.data[1] * 1.57079637050628662109375;
    float cosNI = dot(sc.N, omega_in);
    float cosNO = dot(sc.N, I);
    if ((cosNI > 0.0) && (cosNO > 0.0))
    {
        vec4 R = (sc.N * (2.0 * cosNO)) - I;
        float cosRI = dot(R, omega_in);
        float param = max(cosRI, 0.0);
        float angle = safe_acosf(param);
        float param_1 = max_angle;
        float param_2 = smooth_rsv;
        float param_3 = angle;
        vec4 eval = bsdf_toon_get_intensity(param_1, param_2, param_3);
        float param_4 = max_angle;
        float param_5 = smooth_rsv;
        float sample_angle = bsdf_toon_get_sample_angle(param_4, param_5);
        pdf = 0.15915493667125701904296875 / (1.0 - cos(sample_angle));
        return eval * pdf;
    }
    return vec4(0.0);
}

vec4 bsdf_translucent_eval_reflect(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_refraction_eval_reflect(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_transparent_eval_reflect(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_ashikhmin_velvet_eval_reflect(vec4 I, vec4 omega_in, inout float pdf)
{
    float m_invsigma2 = sc.data[1];
    vec4 N = sc.N;
    float cosNO = dot(N, I);
    float cosNI = dot(N, omega_in);
    if ((cosNO > 0.0) && (cosNI > 0.0))
    {
        vec4 H = normalize(omega_in + I);
        float cosNH = dot(N, H);
        float cosHO = abs(dot(I, H));
        if (!((abs(cosNH) < 0.999989986419677734375) && (cosHO > 9.9999997473787516355514526367188e-06)))
        {
            return vec4(0.0);
        }
        float cosNHdivHO = cosNH / cosHO;
        cosNHdivHO = max(cosNHdivHO, 9.9999997473787516355514526367188e-06);
        float fac1 = 2.0 * abs(cosNHdivHO * cosNO);
        float fac2 = 2.0 * abs(cosNHdivHO * cosNI);
        float sinNH2 = 1.0 - (cosNH * cosNH);
        float sinNH4 = sinNH2 * sinNH2;
        float cotangent2 = (cosNH * cosNH) / sinNH2;
        float D = ((exp((-cotangent2) * m_invsigma2) * m_invsigma2) * 0.3183098733425140380859375) / sinNH4;
        float G = min(1.0, min(fac1, fac2));
        float out_rsv = (0.25 * (D * G)) / cosNO;
        pdf = 0.15915493667125701904296875;
        return vec4(out_rsv, out_rsv, out_rsv, 0.0);
    }
    return vec4(0.0);
}

float D_GTR1(float NdotH, float alpha)
{
    if (alpha >= 1.0)
    {
        return 0.3183098733425140380859375;
    }
    float alpha2 = alpha * alpha;
    float t = 1.0 + (((alpha2 - 1.0) * NdotH) * NdotH);
    return (alpha2 - 1.0) / ((3.1415927410125732421875 * log(alpha2)) * t);
}

float safe_sqrtf(float f)
{
    return sqrt(max(f, 0.0));
}

void make_orthonormals_tangent(vec4 N, vec4 T, out vec4 a, inout vec4 b)
{
    b = vec4(normalize(cross(N.xyz, T.xyz)), 0.0);
    a = vec4(cross(b.xyz, N.xyz), 0.0);
}

float fresnel_dielectric_cos(float cosi, float eta)
{
    float c = abs(cosi);
    float g = ((eta * eta) - 1.0) + (c * c);
    if (g > 0.0)
    {
        g = sqrt(g);
        float A_1 = (g - c) / (g + c);
        float B_1 = ((c * (g + c)) - 1.0) / ((c * (g - c)) + 1.0);
        return ((0.5 * A_1) * A_1) * (1.0 + (B_1 * B_1));
    }
    return 1.0;
}

vec4 interpolate_fresnel_color(vec4 L, vec4 H, float ior, float F0, vec4 cspec0)
{
    float F0_norm = 1.0 / (1.0 - F0);
    float param = dot(L, H);
    float param_1 = ior;
    float FH = (fresnel_dielectric_cos(param, param_1) - F0) * F0_norm;
    return (cspec0 * (1.0 - FH)) + (vec4(1.0, 1.0, 1.0, 0.0) * FH);
}

vec4 reflection_color(vec4 L, vec4 H)
{
    vec4 F = vec4(1.0, 1.0, 1.0, 0.0);
    bool _2547 = sc.type == 11u;
    bool _2555;
    if (!_2547)
    {
        _2555 = sc.type == 12u;
    }
    else
    {
        _2555 = _2547;
    }
    bool use_fresnel = _2555;
    if (use_fresnel)
    {
        float param = 1.0;
        float param_1 = sc.data[2];
        float F0 = fresnel_dielectric_cos(param, param_1);
        vec4 param_2 = L;
        vec4 param_3 = H;
        float param_4 = sc.data[2];
        float param_5 = F0;
        vec4 param_6 = vec4(sc.data[6], sc.data[7], sc.data[8], 0.0);
        F = interpolate_fresnel_color(param_2, param_3, param_4, param_5, param_6);
    }
    return F;
}

vec4 bsdf_microfacet_ggx_eval_reflect(vec4 I, vec4 omega_in, inout float pdf)
{
    float alpha_x = sc.data[0];
    float alpha_y = sc.data[1];
    bool m_refractive = sc.type == 23u;
    vec4 N = sc.N;
    bool _2638;
    if (!m_refractive)
    {
        _2638 = (alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07;
    }
    else
    {
        _2638 = m_refractive;
    }
    if (_2638)
    {
        return vec4(0.0);
    }
    float cosNO = dot(N.xyz, I.xyz);
    float cosNI = dot(N.xyz, omega_in.xyz);
    if ((cosNI > 0.0) && (cosNO > 0.0))
    {
        vec4 m = vec4(normalize((omega_in + I).xyz), 0.0);
        float alpha2 = alpha_x * alpha_y;
        float D;
        float G1o;
        float G1i;
        if (alpha_x == alpha_y)
        {
            float cosThetaM = dot(N.xyz, m.xyz);
            float cosThetaM2 = cosThetaM * cosThetaM;
            float cosThetaM4 = cosThetaM2 * cosThetaM2;
            float tanThetaM2 = (1.0 - cosThetaM2) / cosThetaM2;
            if (sc.type == 12u)
            {
                float param = cosThetaM;
                float param_1 = sc.data[0];
                D = D_GTR1(param, param_1);
                alpha2 = 0.0625;
            }
            else
            {
                D = alpha2 / (((3.1415927410125732421875 * cosThetaM4) * (alpha2 + tanThetaM2)) * (alpha2 + tanThetaM2));
            }
            float param_2 = 1.0 + ((alpha2 * (1.0 - (cosNO * cosNO))) / (cosNO * cosNO));
            G1o = 2.0 / (1.0 + safe_sqrtf(param_2));
            float param_3 = 1.0 + ((alpha2 * (1.0 - (cosNI * cosNI))) / (cosNI * cosNI));
            G1i = 2.0 / (1.0 + safe_sqrtf(param_3));
        }
        else
        {
            vec4 Z = N;
            vec4 X;
            vec4 param_4 = X;
            vec4 Y;
            vec4 param_5 = Y;
            make_orthonormals_tangent(Z, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param_4, param_5);
            X = param_4;
            Y = param_5;
            vec4 local_m = vec4(dot(X.xyz, m.xyz), dot(Y.xyz, m.xyz), dot(Z.xyz, m.xyz), 0.0);
            float slope_x = (-local_m.x) / (local_m.z * alpha_x);
            float slope_y = (-local_m.y) / (local_m.z * alpha_y);
            float slope_len = (1.0 + (slope_x * slope_x)) + (slope_y * slope_y);
            float cosThetaM_1 = local_m.z;
            float cosThetaM2_1 = cosThetaM_1 * cosThetaM_1;
            float cosThetaM4_1 = cosThetaM2_1 * cosThetaM2_1;
            D = 1.0 / ((((slope_len * slope_len) * 3.1415927410125732421875) * alpha2) * cosThetaM4_1);
            float tanThetaO2 = (1.0 - (cosNO * cosNO)) / (cosNO * cosNO);
            float cosPhiO = dot(I.xyz, X.xyz);
            float sinPhiO = dot(I.xyz, Y.xyz);
            float alphaO2 = ((cosPhiO * cosPhiO) * (alpha_x * alpha_x)) + ((sinPhiO * sinPhiO) * (alpha_y * alpha_y));
            alphaO2 /= ((cosPhiO * cosPhiO) + (sinPhiO * sinPhiO));
            float param_6 = 1.0 + (alphaO2 * tanThetaO2);
            G1o = 2.0 / (1.0 + safe_sqrtf(param_6));
            float tanThetaI2 = (1.0 - (cosNI * cosNI)) / (cosNI * cosNI);
            float cosPhiI = dot(omega_in.xyz, X.xyz);
            float sinPhiI = dot(omega_in.xyz, Y.xyz);
            float alphaI2 = ((cosPhiI * cosPhiI) * (alpha_x * alpha_x)) + ((sinPhiI * sinPhiI) * (alpha_y * alpha_y));
            alphaI2 /= ((cosPhiI * cosPhiI) + (sinPhiI * sinPhiI));
            float param_7 = 1.0 + (alphaI2 * tanThetaI2);
            G1i = 2.0 / (1.0 + safe_sqrtf(param_7));
        }
        float G = G1o * G1i;
        float common_rsv = (D * 0.25) / cosNO;
        vec4 param_8 = omega_in;
        vec4 param_9 = m;
        vec4 F = reflection_color(param_8, param_9);
        if (sc.type == 12u)
        {
            F *= (0.25 * sc.data[12]);
        }
        vec4 out_rsv = (F * G) * common_rsv;
        pdf = G1o * common_rsv;
        return out_rsv;
    }
    return vec4(0.0);
}

float bsdf_beckmann_G1(float alpha, inout float cos_n)
{
    cos_n *= cos_n;
    float param = (1.0 - cos_n) / cos_n;
    float invA = alpha * safe_sqrtf(param);
    if (invA < 0.625)
    {
        return 1.0;
    }
    float a = 1.0 / invA;
    return (((2.1809999942779541015625 * a) + 3.5350000858306884765625) * a) / ((((2.5769999027252197265625 * a) + 2.27600002288818359375) * a) + 1.0);
}

float bsdf_beckmann_aniso_G1(inout float alpha_x, inout float alpha_y, inout float cos_n, inout float cos_phi, inout float sin_phi)
{
    cos_n *= cos_n;
    sin_phi *= sin_phi;
    cos_phi *= cos_phi;
    alpha_x *= alpha_x;
    alpha_y *= alpha_y;
    float alphaO2 = ((cos_phi * alpha_x) + (sin_phi * alpha_y)) / (cos_phi + sin_phi);
    float param = (alphaO2 * (1.0 - cos_n)) / cos_n;
    float invA = safe_sqrtf(param);
    if (invA < 0.625)
    {
        return 1.0;
    }
    float a = 1.0 / invA;
    return (((2.1809999942779541015625 * a) + 3.5350000858306884765625) * a) / ((((2.5769999027252197265625 * a) + 2.27600002288818359375) * a) + 1.0);
}

vec4 bsdf_microfacet_beckmann_eval_reflect(vec4 I, vec4 omega_in, inout float pdf)
{
    float alpha_x = sc.data[0];
    float alpha_y = sc.data[1];
    bool m_refractive = sc.type == 22u;
    vec4 N = sc.N;
    bool _3874;
    if (!m_refractive)
    {
        _3874 = (alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07;
    }
    else
    {
        _3874 = m_refractive;
    }
    if (_3874)
    {
        return vec4(0.0);
    }
    float cosNO = dot(N.xyz, I.xyz);
    float cosNI = dot(N.xyz, omega_in.xyz);
    if ((cosNO > 0.0) && (cosNI > 0.0))
    {
        vec4 m = vec4(normalize((omega_in + I).xyz), 0.0);
        float alpha2 = alpha_x * alpha_y;
        float D;
        float G1o;
        float G1i;
        if (alpha_x == alpha_y)
        {
            float cosThetaM = dot(N.xyz, m.xyz);
            float cosThetaM2 = cosThetaM * cosThetaM;
            float tanThetaM2 = (1.0 - cosThetaM2) / cosThetaM2;
            float cosThetaM4 = cosThetaM2 * cosThetaM2;
            D = exp((-tanThetaM2) / alpha2) / ((3.1415927410125732421875 * alpha2) * cosThetaM4);
            float param = alpha_x;
            float param_1 = cosNO;
            float _3947 = bsdf_beckmann_G1(param, param_1);
            G1o = _3947;
            float param_2 = alpha_x;
            float param_3 = cosNI;
            float _3953 = bsdf_beckmann_G1(param_2, param_3);
            G1i = _3953;
        }
        else
        {
            vec4 Z = N;
            vec4 X;
            vec4 param_4 = X;
            vec4 Y;
            vec4 param_5 = Y;
            make_orthonormals_tangent(Z, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param_4, param_5);
            X = param_4;
            Y = param_5;
            vec4 local_m = vec4(dot(X.xyz, m.xyz), dot(Y.xyz, m.xyz), dot(Z.xyz, m.xyz), 0.0);
            float slope_x = (-local_m.x) / (local_m.z * alpha_x);
            float slope_y = (-local_m.y) / (local_m.z * alpha_y);
            float cosThetaM_1 = local_m.z;
            float cosThetaM2_1 = cosThetaM_1 * cosThetaM_1;
            float cosThetaM4_1 = cosThetaM2_1 * cosThetaM2_1;
            D = exp(((-slope_x) * slope_x) - (slope_y * slope_y)) / ((3.1415927410125732421875 * alpha2) * cosThetaM4_1);
            float param_6 = alpha_x;
            float param_7 = alpha_y;
            float param_8 = cosNO;
            float param_9 = dot(I.xyz, X.xyz);
            float param_10 = dot(I.xyz, Y.xyz);
            float _4050 = bsdf_beckmann_aniso_G1(param_6, param_7, param_8, param_9, param_10);
            G1o = _4050;
            float param_11 = alpha_x;
            float param_12 = alpha_y;
            float param_13 = cosNI;
            float param_14 = dot(omega_in.xyz, X.xyz);
            float param_15 = dot(omega_in.xyz, Y.xyz);
            float _4067 = bsdf_beckmann_aniso_G1(param_11, param_12, param_13, param_14, param_15);
            G1i = _4067;
        }
        float G = G1o * G1i;
        float common_rsv = (D * 0.25) / cosNO;
        float out_rsv = G * common_rsv;
        pdf = G1o * common_rsv;
        return vec4(out_rsv, out_rsv, out_rsv, 0.0);
    }
    return vec4(0.0);
}

vec4 bsdf_reflection_eval_reflect(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

void make_orthonormals(vec4 N, inout vec4 a, inout vec4 b)
{
    bool _1023 = !(N.x == N.y);
    bool _1032;
    if (!_1023)
    {
        _1032 = !(N.x == N.z);
    }
    else
    {
        _1032 = _1023;
    }
    if (_1032)
    {
        a = vec4(N.z - N.y, N.x - N.z, N.y - N.x, 0.0);
    }
    else
    {
        a = vec4(N.z - N.y, N.x + N.z, (-N.y) - N.x, 0.0);
    }
    vec3 _1071 = normalize(a.xyz);
    a = vec4(_1071.x, _1071.y, _1071.z, a.w);
    vec3 _1078 = cross(N.xyz, a.xyz);
    b = vec4(_1078.x, _1078.y, _1078.z, b.w);
}

float D_ggx_aniso(vec4 wm, vec2 alpha)
{
    float slope_x = (-wm.x) / alpha.x;
    float slope_y = (-wm.y) / alpha.y;
    float tmp = ((wm.z * wm.z) + (slope_x * slope_x)) + (slope_y * slope_y);
    return 1.0 / max((((3.1415927410125732421875 * tmp) * tmp) * alpha.x) * alpha.y, 1.0000000116860974230803549289703e-07);
}

float mf_lambda(vec4 w, vec2 alpha)
{
    if (w.z > 0.99989998340606689453125)
    {
        return 0.0;
    }
    else
    {
        if (w.z < (-0.99989998340606689453125))
        {
            return -0.99989998340606689453125;
        }
    }
    float inv_wz2 = 1.0 / max(w.z * w.z, 1.0000000116860974230803549289703e-07);
    vec2 wa = vec2(w.xy) * alpha;
    float v = sqrt(1.0 + (dot(wa, wa) * inv_wz2));
    if (w.z <= 0.0)
    {
        v = -v;
    }
    return 0.5 * (v - 1.0);
}

float mf_ggx_albedo(float r)
{
    float albedo = (0.806495010852813720703125 * exp(((-1.98712003231048583984375) * r) * r)) + 0.19953100383281707763671875;
    albedo -= ((((((((((((((1.7674100399017333984375 * r) - 8.4389095306396484375) * r) + 15.784000396728515625) * r) - 14.39799976348876953125) * r) + 6.452209949493408203125) * r) - 1.19721996784210205078125) * r) + 0.0278030000627040863037109375) * r) + 0.0056873899884521961212158203125);
    return clamp(albedo, 0.0, 1.0);
}

float mf_ggx_aniso_pdf(vec4 wi, vec4 wo, vec2 alpha)
{
    float D = D_ggx_aniso(vec4(normalize((wi + wo).xyz), 0.0), alpha);
    float lambda = mf_lambda(wi, alpha);
    float singlescatter = (0.25 * D) / max((1.0 + lambda) * wi.z, 1.0000000116860974230803549289703e-07);
    float multiscatter = wo.z * 0.3183098733425140380859375;
    float param = sqrt(alpha.x * alpha.y);
    float albedo = mf_ggx_albedo(param);
    return (albedo * singlescatter) + ((1.0 - albedo) * multiscatter);
}

float D_ggx(inout vec4 wm, inout float alpha)
{
    wm.z *= wm.z;
    alpha *= alpha;
    float tmp = (1.0 - wm.z) + (alpha * wm.z);
    return alpha / max((3.1415927410125732421875 * tmp) * tmp, 1.0000000116860974230803549289703e-07);
}

float mf_ggx_pdf(vec4 wi, vec4 wo, float alpha)
{
    vec4 param = vec4(normalize((wi + wo).xyz), 0.0);
    float param_1 = alpha;
    float _5650 = D_ggx(param, param_1);
    float D = _5650;
    float lambda = mf_lambda(wi, vec2(alpha));
    float singlescatter = (0.25 * D) / max((1.0 + lambda) * wi.z, 1.0000000116860974230803549289703e-07);
    float multiscatter = wo.z * 0.3183098733425140380859375;
    float param_2 = alpha;
    float albedo = mf_ggx_albedo(param_2);
    return (albedo * singlescatter) + ((1.0 - albedo) * multiscatter);
}

float lcg_step_float_addrspace(inout uint rng)
{
    rng = (1103515245u * rng) + 12345u;
    return float(rng) * 2.3283064365386962890625e-10;
}

float mf_invC1(float h)
{
    return (2.0 * clamp(h, 0.0, 1.0)) - 1.0;
}

float mf_G1(vec4 w, float C1, float lambda)
{
    if (w.z > 0.99989998340606689453125)
    {
        return 1.0;
    }
    if (w.z < 9.9999997473787516355514526367188e-06)
    {
        return 0.0;
    }
    return pow(C1, lambda);
}

bool mf_sample_height(vec4 w, inout float h, inout float C1, inout float G1, float lambda, float U)
{
    if (w.z > 0.99989998340606689453125)
    {
        return false;
    }
    if (w.z < (-0.99989998340606689453125))
    {
        C1 *= U;
        h = mf_invC1(C1);
        G1 = mf_G1(w, C1, lambda);
    }
    else
    {
        if (abs(w.z) >= 9.9999997473787516355514526367188e-05)
        {
            if (U > (1.0 - G1))
            {
                return false;
            }
            if (lambda >= 0.0)
            {
                C1 = 1.0;
            }
            else
            {
                C1 *= pow(1.0 - U, (-1.0) / lambda);
            }
            h = mf_invC1(C1);
            G1 = mf_G1(w, C1, lambda);
        }
    }
    return true;
}

vec2 mf_sampleP22_11(float cosI, float randx, float randy)
{
    bool _4885 = cosI > 0.99989998340606689453125;
    bool _4891;
    if (!_4885)
    {
        _4891 = abs(cosI) < 9.9999999747524270787835121154785e-07;
    }
    else
    {
        _4891 = _4885;
    }
    if (_4891)
    {
        float r = sqrt(randx / max(1.0 - randx, 1.0000000116860974230803549289703e-07));
        float phi = 6.283185482025146484375 * randy;
        return vec2(r * cos(phi), r * sin(phi));
    }
    float param = 1.0 - (cosI * cosI);
    float sinI = safe_sqrtf(param);
    float tanI = sinI / cosI;
    float projA = 0.5 * (cosI + 1.0);
    if (projA < 9.9999997473787516355514526367188e-05)
    {
        return vec2(0.0);
    }
    float A_1 = (((2.0 * randx) * projA) / cosI) - 1.0;
    float tmp = (A_1 * A_1) - 1.0;
    if (abs(tmp) < 1.0000000116860974230803549289703e-07)
    {
        return vec2(0.0);
    }
    tmp = 1.0 / tmp;
    float param_1 = (((tanI * tanI) * tmp) * tmp) - (((A_1 * A_1) - (tanI * tanI)) * tmp);
    float D = safe_sqrtf(param_1);
    float slopeX2 = (tanI * tmp) + D;
    bool _4975 = A_1 < 0.0;
    bool _4983;
    if (!_4975)
    {
        _4983 = slopeX2 > (1.0 / tanI);
    }
    else
    {
        _4983 = _4975;
    }
    float _4984;
    if (_4983)
    {
        _4984 = (tanI * tmp) - D;
    }
    else
    {
        _4984 = slopeX2;
    }
    float slopeX = _4984;
    float U2;
    if (randy >= 0.5)
    {
        U2 = 2.0 * (randy - 0.5);
    }
    else
    {
        U2 = 2.0 * (0.5 - randy);
    }
    float z = (U2 * ((U2 * ((U2 * 0.2738499939441680908203125) - 0.7336900234222412109375)) + 0.4634099900722503662109375)) / ((U2 * ((U2 * ((U2 * 0.093073002994060516357421875) + 0.30941998958587646484375)) - 1.0)) + 0.59799897670745849609375);
    float slopeY = z * sqrt(1.0 + (slopeX * slopeX));
    if (randy >= 0.5)
    {
        return vec2(slopeX, slopeY);
    }
    else
    {
        return vec2(slopeX, -slopeY);
    }
}

vec4 safe_normalize(vec4 a)
{
    float t = sqrt(dot(a, a));
    vec4 _986;
    if (!(t == 0.0))
    {
        _986 = a * (1.0 / t);
    }
    else
    {
        _986 = a;
    }
    return _986;
}

bool isfinite_safe(float f)
{
    uint x = floatBitsToUint(f);
    bool _932 = f == f;
    bool _950;
    if (_932)
    {
        bool _940 = (x == 0u) || (x == 2147483648u);
        bool _949;
        if (!_940)
        {
            _949 = !(f == (2.0 * f));
        }
        else
        {
            _949 = _940;
        }
        _950 = _949;
    }
    else
    {
        _950 = _932;
    }
    bool _959;
    if (_950)
    {
        _959 = !((x << uint(1)) > 4278190080u);
    }
    else
    {
        _959 = _950;
    }
    return _959;
}

vec4 mf_sample_vndf(vec4 wi, vec2 alpha, float randx, float randy)
{
    vec4 wi_11 = normalize(vec4(alpha.x * wi.x, alpha.y * wi.y, wi.z, 0.0));
    vec2 slope_11 = mf_sampleP22_11(wi_11.z, randx, randy);
    vec4 cossin_phi = safe_normalize(vec4(wi_11.x, wi_11.y, 0.0, 0.0));
    float slope_x = alpha.x * ((cossin_phi.x * slope_11.x) - (cossin_phi.y * slope_11.y));
    float slope_y = alpha.y * ((cossin_phi.y * slope_11.x) + (cossin_phi.x * slope_11.y));
    float param = slope_x;
    if (!isfinite_safe(param))
    {
        // unimplemented ext op 12
    }
    return normalize(vec4(-slope_x, -slope_y, 1.0, 0.0));
}

vec4 mf_eval_phase_glossy(vec4 w, float lambda, vec4 wo, vec2 alpha)
{
    if (w.z > 0.99989998340606689453125)
    {
        return vec4(0.0);
    }
    vec4 wh = vec4(normalize((wo - w).xyz), 0.0);
    if (wh.z < 0.0)
    {
        return vec4(0.0);
    }
    float _5143;
    if (w.z < (-0.99989998340606689453125))
    {
        _5143 = 1.0;
    }
    else
    {
        _5143 = lambda * w.z;
    }
    float pArea = _5143;
    float dotW_WH = dot(-w, wh);
    if (dotW_WH < 0.0)
    {
        return vec4(0.0);
    }
    float phase = (max(0.0, dotW_WH) * 0.25) / max(pArea * dotW_WH, 1.0000000116860974230803549289703e-07);
    if (alpha.x == alpha.y)
    {
        vec4 param = wh;
        float param_1 = alpha.x;
        float _5177 = D_ggx(param, param_1);
        phase *= _5177;
    }
    else
    {
        phase *= D_ggx_aniso(wh, alpha);
    }
    return vec4(phase, phase, phase, 0.0);
}

float mf_C1(float h)
{
    return clamp(0.5 * (h + 1.0), 0.0, 1.0);
}

vec4 mf_sample_phase_glossy(vec4 wi, vec4 weight, vec4 wm)
{
    return (-wi) + ((wm * 2.0) * dot(wi.xyz, wm.xyz));
}

vec4 mf_eval_glossy(inout vec4 wi, inout vec4 wo, bool wo_outside, vec4 color, float alpha_x, float alpha_y, inout uint lcg_state, float eta, bool use_fresnel, vec4 cspec0)
{
    bool swapped = false;
    if (wo.z < wi.z)
    {
        swapped = true;
        vec4 tmp = wo;
        wo = wi;
        wi = tmp;
    }
    bool _6430 = wi.z < 9.9999997473787516355514526367188e-06;
    bool _6438;
    if (!_6430)
    {
        _6438 = (wo.z < 9.9999997473787516355514526367188e-06) && wo_outside;
    }
    else
    {
        _6438 = _6430;
    }
    bool _6447;
    if (!_6438)
    {
        _6447 = (wo.z > (-9.9999997473787516355514526367188e-06)) && (!wo_outside);
    }
    else
    {
        _6447 = _6438;
    }
    if (_6447)
    {
        return vec4(0.0);
    }
    vec2 alpha = vec2(alpha_x, alpha_y);
    float lambda_r = mf_lambda(-wi, alpha);
    vec4 _6459;
    if (wo_outside)
    {
        _6459 = wo;
    }
    else
    {
        _6459 = -wo;
    }
    float shadowing_lambda = mf_lambda(_6459, alpha);
    vec4 throughput = vec4(1.0, 1.0, 1.0, 0.0);
    vec4 wh = vec4(normalize((wi + wo).xyz), 0.0);
    float G2 = 1.0 / ((1.0 - (lambda_r + 1.0)) + shadowing_lambda);
    float val = (G2 * 0.25) / wi.z;
    if (alpha.x == alpha.y)
    {
        vec4 param = wh;
        float param_1 = alpha.x;
        float _6505 = D_ggx(param, param_1);
        val *= _6505;
    }
    else
    {
        val *= D_ggx_aniso(wh, alpha);
    }
    vec4 eval = vec4(val, val, val, 0.0);
    float param_2 = 1.0;
    float param_3 = eta;
    float F0 = fresnel_dielectric_cos(param_2, param_3);
    if (use_fresnel)
    {
        vec4 param_4 = wi;
        vec4 param_5 = wh;
        float param_6 = eta;
        float param_7 = F0;
        vec4 param_8 = cspec0;
        throughput = interpolate_fresnel_color(param_4, param_5, param_6, param_7, param_8);
        eval *= throughput;
    }
    vec4 wr = -wi;
    float hr = 1.0;
    float C1_r = 1.0;
    float G1_r = 0.0;
    bool outside = true;
    vec4 _6609;
    float _6619;
    for (int order = 0; order < 10; order++)
    {
        uint param_9 = lcg_state;
        float _6556 = lcg_step_float_addrspace(param_9);
        lcg_state = param_9;
        float height_rand = _6556;
        float param_10 = hr;
        float param_11 = C1_r;
        float param_12 = G1_r;
        float param_13 = lambda_r;
        bool _6568 = mf_sample_height(wr, param_10, param_11, param_12, param_13, height_rand);
        hr = param_10;
        C1_r = param_11;
        G1_r = param_12;
        lambda_r = param_13;
        if (!_6568)
        {
            break;
        }
        uint param_14 = lcg_state;
        float _6580 = lcg_step_float_addrspace(param_14);
        lcg_state = param_14;
        float vndf_rand_y = _6580;
        uint param_15 = lcg_state;
        float _6585 = lcg_step_float_addrspace(param_15);
        lcg_state = param_15;
        float vndf_rand_x = _6585;
        vec4 wm = mf_sample_vndf(-wr, alpha, vndf_rand_x, vndf_rand_y);
        if (order > 0)
        {
            vec4 phase = mf_eval_phase_glossy(wr, lambda_r, wo, alpha) * throughput;
            if (wo_outside)
            {
                _6609 = wo;
            }
            else
            {
                _6609 = -wo;
            }
            if (outside == wo_outside)
            {
                _6619 = hr;
            }
            else
            {
                _6619 = -hr;
            }
            eval += ((throughput * phase) * mf_G1(_6609, mf_C1(_6619), shadowing_lambda));
        }
        if ((order + 1) < 10)
        {
            if (use_fresnel && (order > 0))
            {
                vec4 param_16 = -wr;
                vec4 param_17 = wm;
                float param_18 = eta;
                float param_19 = F0;
                vec4 param_20 = cspec0;
                throughput *= interpolate_fresnel_color(param_16, param_17, param_18, param_19, param_20);
            }
            vec4 param_21 = throughput;
            throughput = param_21;
            wr = mf_sample_phase_glossy(-wr, param_21, wm);
            lambda_r = mf_lambda(wr, alpha);
            if (!use_fresnel)
            {
                throughput *= color;
            }
            C1_r = mf_C1(hr);
            G1_r = mf_G1(wr, C1_r, lambda_r);
        }
    }
    if (swapped)
    {
        eval *= abs(wi.z / wo.z);
    }
    return eval;
}

vec4 bsdf_microfacet_multi_ggx_eval_reflect(vec4 I, vec4 omega_in, inout float pdf, inout uint lcg_state)
{
    if ((sc.data[0] * sc.data[1]) < 1.0000000116860974230803549289703e-07)
    {
        return vec4(0.0);
    }
    bool use_fresnel = sc.type == 15u;
    bool is_aniso = !(sc.data[0] == sc.data[1]);
    vec4 Z = sc.N;
    vec4 X;
    vec4 Y;
    if (is_aniso)
    {
        vec4 param = X;
        vec4 param_1 = Y;
        make_orthonormals_tangent(Z, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param, param_1);
        X = param;
        Y = param_1;
    }
    else
    {
        vec4 param_2 = Z;
        vec4 param_3 = X;
        vec4 param_4;
        make_orthonormals(param_2, param_3, param_4);
        X = param_3;
        Y = param_4;
    }
    vec4 localI = vec4(dot(I.xyz, X.xyz), dot(I.xyz, Y.xyz), dot(I.xyz, Z.xyz), 0.0);
    vec4 localO = vec4(dot(omega_in.xyz, X.xyz), dot(omega_in.xyz, Y.xyz), dot(omega_in.xyz, Z.xyz), 0.0);
    if (is_aniso)
    {
        pdf = mf_ggx_aniso_pdf(localI, localO, vec2(sc.data[0], sc.data[1]));
    }
    else
    {
        pdf = mf_ggx_pdf(localI, localO, sc.data[0]);
    }
    vec4 param_5 = localI;
    vec4 param_6 = localO;
    uint param_7 = lcg_state;
    bool param_8 = use_fresnel;
    vec4 _6968 = mf_eval_glossy(param_5, param_6, true, vec4(sc.data[3], sc.data[4], sc.data[5], 0.0), sc.data[0], sc.data[1], param_7, sc.data[2], param_8, vec4(sc.data[6], sc.data[7], sc.data[8], 0.0));
    lcg_state = param_7;
    return _6968;
}

vec4 normalize_len(vec4 a, inout float t)
{
    t = sqrt(dot(a.xyz, a.xyz));
    float x = 1.0 / t;
    return vec4(a.xyz * x, 0.0);
}

float mf_ggx_transmission_albedo(inout float a, inout float ior)
{
    if (ior < 1.0)
    {
        ior = 1.0 / ior;
    }
    a = clamp(a, 0.0, 1.0);
    ior = clamp(ior, 1.0, 3.0);
    float I_1 = ((0.0476897992193698883056640625 * exp(((-0.978352010250091552734375) * (ior - 0.656570017337799072265625)) * (ior - 0.656570017337799072265625))) - (0.0337559990584850311279296875 * ior)) + 0.99326097965240478515625;
    float R_1 = (((((((0.11699099838733673095703125 * a) - 0.270368993282318115234375) * a) + 0.0501365996897220611572265625) * a) - 0.0041151097975671291351318359375) * a) + 1.00007998943328857421875;
    float I_2 = ((((((((((-2.087039947509765625) * ior) + 26.329799652099609375) * ior) - 127.90599822998046875) * ior) + 292.9580078125) * ior) - 287.946014404296875) + (199.8029937744140625 / (ior * ior))) - (101.667999267578125 / ((ior * ior) * ior));
    float R_2 = (((((((((5.372499942779541015625 * a) - 24.9307003021240234375) * a) + 22.7437000274658203125) * a) - 3.4075100421905517578125) * a) + 0.09863249957561492919921875) * a) + 0.004935040138661861419677734375;
    return clamp((1.0 + ((I_2 * R_2) * 0.00191270001232624053955078125)) - (((1.0 - I_1) * (1.0 - R_1)) * 9.32050037384033203125), 0.0, 1.0);
}

float mf_glass_pdf(vec4 wi, vec4 wo, float alpha, float eta)
{
    bool reflective = (wi.z * wo.z) > 0.0;
    vec4 _5726;
    if (reflective)
    {
        _5726 = wo;
    }
    else
    {
        _5726 = wo * eta;
    }
    float wh_len;
    float param = wh_len;
    vec4 _5736 = normalize_len(wi + _5726, param);
    wh_len = param;
    vec4 wh = _5736;
    if (wh.z < 0.0)
    {
        wh = -wh;
    }
    vec4 _5748;
    if (wi.z < 0.0)
    {
        _5748 = -wi;
    }
    else
    {
        _5748 = wi;
    }
    vec4 r_wi = _5748;
    float lambda = mf_lambda(r_wi, vec2(alpha));
    vec4 param_1 = wh;
    float param_2 = alpha;
    float _5762 = D_ggx(param_1, param_2);
    float D = _5762;
    float param_3 = dot(r_wi.xyz, wh.xyz);
    float param_4 = eta;
    float fresnel = fresnel_dielectric_cos(param_3, param_4);
    float multiscatter = abs(wo.z * 0.3183098733425140380859375);
    if (reflective)
    {
        float singlescatter = (0.25 * D) / max((1.0 + lambda) * r_wi.z, 1.0000000116860974230803549289703e-07);
        float param_5 = alpha;
        float albedo = mf_ggx_albedo(param_5);
        return fresnel * ((albedo * singlescatter) + ((1.0 - albedo) * multiscatter));
    }
    else
    {
        float singlescatter_1 = abs(((((dot(r_wi.xyz, wh.xyz) * dot(wo.xyz, wh.xyz)) * D) * eta) * eta) / max((((1.0 + lambda) * r_wi.z) * wh_len) * wh_len, 1.0000000116860974230803549289703e-07));
        float param_6 = alpha;
        float param_7 = eta;
        float _5834 = mf_ggx_transmission_albedo(param_6, param_7);
        float albedo_1 = _5834;
        return (1.0 - fresnel) * ((albedo_1 * singlescatter_1) + ((1.0 - albedo_1) * multiscatter));
    }
}

vec4 mf_eval_phase_glass(vec4 w, float lambda, vec4 wo, bool wo_outside, vec2 alpha, float eta)
{
    if (w.z > 0.99989998340606689453125)
    {
        return vec4(0.0);
    }
    float _5250;
    if (w.z < (-0.99989998340606689453125))
    {
        _5250 = 1.0;
    }
    else
    {
        _5250 = lambda * w.z;
    }
    float pArea = _5250;
    float v;
    if (wo_outside)
    {
        vec4 wh = vec4(normalize((wo - w).xyz), 0.0);
        if (wh.z < 0.0)
        {
            return vec4(0.0);
        }
        float dotW_WH = dot((-w).xyz, wh.xyz);
        float param = dotW_WH;
        float param_1 = eta;
        vec4 param_2 = wh;
        float param_3 = alpha.x;
        float _5291 = D_ggx(param_2, param_3);
        v = (((fresnel_dielectric_cos(param, param_1) * max(0.0, dotW_WH)) * _5291) * 0.25) / (pArea * dotW_WH);
    }
    else
    {
        vec4 wh_1 = vec4(normalize(((wo * eta) - w).xyz), 0.0);
        if (wh_1.z < 0.0)
        {
            wh_1 = -wh_1;
        }
        float dotW_WH_1 = dot((-w).xyz, wh_1.xyz);
        float dotWO_WH = dot(wo.xyz, wh_1.xyz);
        if (dotW_WH_1 < 0.0)
        {
            return vec4(0.0);
        }
        float temp = dotW_WH_1 + (eta * dotWO_WH);
        float param_4 = dotW_WH_1;
        float param_5 = eta;
        vec4 param_6 = wh_1;
        float param_7 = alpha.x;
        float _5352 = D_ggx(param_6, param_7);
        v = ((((1.0 - fresnel_dielectric_cos(param_4, param_5)) * max(0.0, dotW_WH_1)) * max(0.0, -dotWO_WH)) * _5352) / ((pArea * temp) * temp);
    }
    return vec4(v, v, v, 0.0);
}

bool isfinite(double f)
{
    uint64_t hl = doubleBitsToUint64(f);
    uint hx = uint((hl >> 32) & 18446744073709551615ul);
    uint lx = uint(hl & 18446744073709551615ul);
    int retval = -1;
    lx |= (hx & 1048575u);
    hx &= 2146435072u;
    if ((hx | lx) == 0u)
    {
        retval = 0;
    }
    else
    {
        if (hx == 0u)
        {
            retval = -2;
        }
        else
        {
            if (hx == 2146435072u)
            {
                retval = (lx != 0u) ? 1 : 2;
            }
        }
    }
    return !((retval == 1) || (retval == 2));
}

double log(double v)
{
    return double(log(float(v)));
}

double polevl(double x, double coef[8], int N)
{
    int j = 0;
    double indexable[8] = coef;
    double ans = indexable[j];
    j++;
    int i = N;
    for (;;)
    {
        int _1475 = j;
        j = _1475 + 1;
        double indexable_1[8] = coef;
        ans = (ans * x) + indexable_1[_1475];
        int _1481 = i;
        int _1482 = _1481 - 1;
        i = _1482;
        if (_1482 != int(0u))
        {
            continue;
        }
        else
        {
            break;
        }
    }
    return ans;
}

double p1evl(double x, double coef[8], int N)
{
    int j = 0;
    double indexable[8] = coef;
    double ans = x + indexable[j];
    j++;
    int _1499 = N - 1;
    int i = _1499;
    for (;;)
    {
        int _1507 = j;
        j = _1507 + 1;
        double indexable_1[8] = coef;
        ans = (ans * x) + indexable_1[_1507];
        int _1513 = i;
        int _1514 = _1513 - 1;
        i = _1514;
        if (_1514 != int(0u))
        {
            continue;
        }
        else
        {
            break;
        }
    }
    return ans;
}

double lgamma(inout double x, inout int _sign)
{
    _sign = 1;
    double param = x;
    if (!isfinite(param))
    {
        return x;
    }
    if (x < (-34.0lf))
    {
        if (true)
        {
            // unimplemented ext op 12
        }
        return 1.797693134862315708145274237317e+308lf;
    }
    double p;
    if (x < 13.0lf)
    {
        double z = 1.0lf;
        p = 0.0lf;
        double u = x;
        while (u >= 3.0lf)
        {
            p -= 1.0lf;
            u = x + p;
            z *= u;
        }
        while (u < 2.0lf)
        {
            if (u == 0.0lf)
            {
                if (true)
                {
                    // unimplemented ext op 12
                }
                return 1.797693134862315708145274237317e+308lf;
            }
            z /= u;
            p += 1.0lf;
            u = x + p;
        }
        if (z < 0.0lf)
        {
            _sign = -1;
            z = -z;
        }
        else
        {
            _sign = 1;
        }
        if (u == 2.0lf)
        {
            double param_1 = z;
            return log(param_1);
        }
        p -= 2.0lf;
        x += p;
        double param_2 = x;
        int param_3 = 5;
        double param_4 = x;
        int param_5 = 6;
        p = (x * polevl(param_2, B, param_3)) / p1evl(param_4, C, param_5);
        double param_6 = z;
        return log(param_6) + p;
    }
    if (x > 2.5563479999999998225773832577314e+305lf)
    {
        return double(float(_sign) * uintBitsToFloat(0x7f800000u));
    }
    double param_7 = x;
    double q = (((x - 0.5lf) * log(param_7)) - x) + 0.91893853320467278056327131707803lf;
    if (x > 100000000.0lf)
    {
        return q;
    }
    p = 1.0lf / (x * x);
    if (x >= 1000.0lf)
    {
        q += (((((0.00079365079365079365010526846191397lf * p) - 0.0027777777777777778837886568652493lf) * p) + 0.083333333333333328707404064061848lf) / x);
    }
    else
    {
        double param_8 = p;
        int param_9 = 4;
        q += (polevl(param_8, A, param_9) / x);
    }
    return q;
}

float lgammaf(float v)
{
    double param = double(v);
    int _sign;
    int param_1 = _sign;
    double _1702 = lgamma(param, param_1);
    _sign = param_1;
    return float(_1702);
}

float beta(float x, float y)
{
    float param = x;
    float param_1 = y;
    float param_2 = x + y;
    return exp((lgammaf(param) + lgammaf(param_1)) - lgammaf(param_2));
}

vec4 mf_sample_phase_glass(vec4 wi, float eta, vec4 wm, float randV, out bool outside)
{
    float cosI = dot(wi.xyz, wm.xyz);
    float param = cosI;
    float param_1 = eta;
    float f = fresnel_dielectric_cos(param, param_1);
    if (randV < f)
    {
        outside = true;
        return (-wi) + ((wm * 2.0) * cosI);
    }
    outside = false;
    float inv_eta = 1.0 / eta;
    float param_2 = 1.0 - (((1.0 - (cosI * cosI)) * inv_eta) * inv_eta);
    float cosT = -safe_sqrtf(param_2);
    return vec4(normalize(((wm * ((cosI * inv_eta) + cosT)) - (wi * inv_eta)).xyz), 0.0);
}

vec4 mf_eval_glass(inout vec4 wi, inout vec4 wo, bool wo_outside, vec4 color, float alpha_x, float alpha_y, inout uint lcg_state, float eta, bool use_fresnel, vec4 cspec0)
{
    bool swapped = false;
    if ((wi.z * wo.z) < 0.0)
    {
        if ((-wo.z) < wi.z)
        {
            swapped = true;
            vec4 tmp = -wo;
            wo = -wi;
            wi = tmp;
        }
    }
    else
    {
        if (wo.z < wi.z)
        {
            swapped = true;
            vec4 tmp_1 = wo;
            wo = wi;
            wi = tmp_1;
        }
    }
    bool _5885 = wi.z < 9.9999997473787516355514526367188e-06;
    bool _5893;
    if (!_5885)
    {
        _5893 = (wo.z < 9.9999997473787516355514526367188e-06) && wo_outside;
    }
    else
    {
        _5893 = _5885;
    }
    bool _5903;
    if (!_5893)
    {
        _5903 = (wo.z > (-9.9999997473787516355514526367188e-06)) && (!wo_outside);
    }
    else
    {
        _5903 = _5893;
    }
    if (_5903)
    {
        return vec4(0.0);
    }
    vec2 alpha = vec2(alpha_x, alpha_y);
    float lambda_r = mf_lambda(-wi, alpha);
    vec4 _5915;
    if (wo_outside)
    {
        _5915 = wo;
    }
    else
    {
        _5915 = -wo;
    }
    float shadowing_lambda = mf_lambda(_5915, alpha);
    vec4 throughput = vec4(1.0, 1.0, 1.0, 0.0);
    vec4 wh = vec4(normalize((wi + wo).xyz), 0.0);
    vec4 eval = mf_eval_phase_glass(-wi, lambda_r, wo, wo_outside, alpha, eta);
    if (wo_outside)
    {
        eval *= ((-lambda_r) / (shadowing_lambda - lambda_r));
    }
    else
    {
        float param = -lambda_r;
        float param_1 = shadowing_lambda + 1.0;
        eval *= ((-lambda_r) * beta(param, param_1));
    }
    float param_2 = 1.0;
    float param_3 = eta;
    float F0 = fresnel_dielectric_cos(param_2, param_3);
    if (use_fresnel)
    {
        vec4 param_4 = wi;
        vec4 param_5 = wh;
        float param_6 = eta;
        float param_7 = F0;
        vec4 param_8 = cspec0;
        throughput = interpolate_fresnel_color(param_4, param_5, param_6, param_7, param_8);
        eval *= throughput;
    }
    vec4 wr = -wi;
    float hr = 1.0;
    float C1_r = 1.0;
    float G1_r = 0.0;
    bool outside = true;
    vec4 phase;
    vec4 _6068;
    float _6078;
    vec4 phase_1;
    vec4 _6115;
    float _6125;
    float _6155;
    bool next_outside;
    for (int order = 0; order < 10; order++)
    {
        uint param_9 = lcg_state;
        float _6003 = lcg_step_float_addrspace(param_9);
        lcg_state = param_9;
        float height_rand = _6003;
        float param_10 = hr;
        float param_11 = C1_r;
        float param_12 = G1_r;
        float param_13 = lambda_r;
        bool _6015 = mf_sample_height(wr, param_10, param_11, param_12, param_13, height_rand);
        hr = param_10;
        C1_r = param_11;
        G1_r = param_12;
        lambda_r = param_13;
        if (!_6015)
        {
            break;
        }
        uint param_14 = lcg_state;
        float _6027 = lcg_step_float_addrspace(param_14);
        lcg_state = param_14;
        float vndf_rand_y = _6027;
        uint param_15 = lcg_state;
        float _6032 = lcg_step_float_addrspace(param_15);
        lcg_state = param_15;
        float vndf_rand_x = _6032;
        vec4 wm = mf_sample_vndf(-wr, alpha, vndf_rand_x, vndf_rand_y);
        if ((order == 0) && use_fresnel)
        {
            if (outside)
            {
                phase = mf_eval_phase_glass(wr, lambda_r, wo, wo_outside, alpha, eta);
            }
            else
            {
                phase = mf_eval_phase_glass(wr, lambda_r, -wo, !wo_outside, alpha, 1.0 / eta);
            }
            if (wo_outside)
            {
                _6068 = wo;
            }
            else
            {
                _6068 = -wo;
            }
            if (outside == wo_outside)
            {
                _6078 = hr;
            }
            else
            {
                _6078 = -hr;
            }
            eval = (throughput * phase) * mf_G1(_6068, mf_C1(_6078), shadowing_lambda);
        }
        if (order > 0)
        {
            if (outside)
            {
                phase_1 = mf_eval_phase_glass(wr, lambda_r, wo, wo_outside, alpha, eta);
            }
            else
            {
                phase_1 = mf_eval_phase_glass(wr, lambda_r, -wo, !wo_outside, alpha, 1.0 / eta);
            }
            if (wo_outside)
            {
                _6115 = wo;
            }
            else
            {
                _6115 = -wo;
            }
            if (outside == wo_outside)
            {
                _6125 = hr;
            }
            else
            {
                _6125 = -hr;
            }
            eval += ((throughput * phase_1) * mf_G1(_6115, mf_C1(_6125), shadowing_lambda));
        }
        if ((order + 1) < 10)
        {
            vec4 wi_prev = -wr;
            uint param_16 = lcg_state;
            float _6150 = lcg_step_float_addrspace(param_16);
            lcg_state = param_16;
            float phase_rand = _6150;
            if (outside)
            {
                _6155 = eta;
            }
            else
            {
                _6155 = 1.0 / eta;
            }
            bool param_17 = next_outside;
            vec4 _6166 = mf_sample_phase_glass(-wr, _6155, wm, phase_rand, param_17);
            next_outside = param_17;
            wr = _6166;
            if (!next_outside)
            {
                outside = !outside;
                wr = -wr;
                hr = -hr;
            }
            if (use_fresnel && (!next_outside))
            {
                throughput *= color;
            }
            else
            {
                if (use_fresnel && (order > 0))
                {
                    vec4 param_18 = wi_prev;
                    vec4 param_19 = wm;
                    float param_20 = eta;
                    float param_21 = F0;
                    vec4 param_22 = cspec0;
                    throughput *= interpolate_fresnel_color(param_18, param_19, param_20, param_21, param_22);
                }
            }
            lambda_r = mf_lambda(wr, alpha);
            if (!use_fresnel)
            {
                throughput *= color;
            }
            C1_r = mf_C1(hr);
            G1_r = mf_G1(wr, C1_r, lambda_r);
        }
    }
    if (swapped)
    {
        eval *= abs(wi.z / wo.z);
    }
    return eval;
}

vec4 bsdf_microfacet_multi_ggx_glass_eval_reflect(vec4 I, vec4 omega_in, inout float pdf, inout uint lcg_state)
{
    if ((sc.data[0] * sc.data[1]) < 1.0000000116860974230803549289703e-07)
    {
        return vec4(0.0);
    }
    bool use_fresnel = sc.type == 27u;
    vec4 Z = sc.N;
    vec4 param = Z;
    vec4 X;
    vec4 param_1 = X;
    vec4 param_2;
    make_orthonormals(param, param_1, param_2);
    X = param_1;
    vec4 Y = param_2;
    vec4 localI = vec4(dot(I.xyz, X.xyz), dot(I.xyz, Y.xyz), dot(I.xyz, Z.xyz), 0.0);
    vec4 localO = vec4(dot(omega_in.xyz, X.xyz), dot(omega_in.xyz, Y.xyz), dot(omega_in.xyz, Z.xyz), 0.0);
    pdf = mf_glass_pdf(localI, localO, sc.data[0], sc.data[2]);
    vec4 color = vec4(sc.data[3], sc.data[4], sc.data[5], 0.0);
    vec4 cspec = vec4(sc.data[6], sc.data[7], sc.data[8], 0.0);
    float ax = sc.data[0];
    float ay = sc.data[1];
    float ior = sc.data[2];
    vec4 param_3 = localI;
    vec4 param_4 = localO;
    uint param_5 = lcg_state;
    bool param_6 = use_fresnel;
    vec4 _7348 = mf_eval_glass(param_3, param_4, true, color, ax, ay, param_5, ior, param_6, cspec);
    lcg_state = param_5;
    return _7348;
}

float bsdf_ashikhmin_shirley_roughness_to_exponent(float roughness)
{
    return (2.0 / (roughness * roughness)) - 2.0;
}

vec4 bsdf_ashikhmin_shirley_eval_reflect(vec4 I, vec4 omega_in, inout float pdf)
{
    vec4 N = sc.N;
    float NdotI = dot(N, I);
    float NdotO = dot(N, omega_in);
    float out_rsv = 0.0;
    if (max(sc.data[0], sc.data[1]) <= 9.9999997473787516355514526367188e-05)
    {
        return vec4(0.0);
    }
    if ((NdotI > 0.0) && (NdotO > 0.0))
    {
        NdotI = max(NdotI, 9.9999999747524270787835121154785e-07);
        NdotO = max(NdotO, 9.9999999747524270787835121154785e-07);
        vec4 H = normalize(omega_in + I);
        float HdotI = max(abs(dot(H, I)), 9.9999999747524270787835121154785e-07);
        float HdotN = max(dot(H, N), 9.9999999747524270787835121154785e-07);
        float pump = 1.0 / max(9.9999999747524270787835121154785e-07, HdotI * max(NdotO, NdotI));
        float param = sc.data[0];
        float n_x = bsdf_ashikhmin_shirley_roughness_to_exponent(param);
        float param_1 = sc.data[1];
        float n_y = bsdf_ashikhmin_shirley_roughness_to_exponent(param_1);
        if (n_x == n_y)
        {
            float e = n_x;
            float lobe = pow(HdotN, e);
            float norm = (n_x + 1.0) / 25.1327419281005859375;
            out_rsv = ((NdotO * norm) * lobe) * pump;
            pdf = (norm * lobe) / HdotI;
        }
        else
        {
            vec4 X;
            vec4 param_2 = X;
            vec4 Y;
            vec4 param_3 = Y;
            make_orthonormals_tangent(N, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param_2, param_3);
            X = param_2;
            Y = param_3;
            float HdotX = dot(H, X);
            float HdotY = dot(H, Y);
            float lobe_1;
            if (HdotN < 1.0)
            {
                float e_1 = (((n_x * HdotX) * HdotX) + ((n_y * HdotY) * HdotY)) / (1.0 - (HdotN * HdotN));
                lobe_1 = pow(HdotN, e_1);
            }
            else
            {
                lobe_1 = 1.0;
            }
            float norm_1 = sqrt((n_x + 1.0) * (n_y + 1.0)) / 25.1327419281005859375;
            out_rsv = ((NdotO * norm_1) * lobe_1) * pump;
            pdf = (norm_1 * lobe_1) / HdotI;
        }
    }
    return vec4(out_rsv, out_rsv, out_rsv, 0.0);
}

bool isequal_float3(vec4 a, vec4 b)
{
    return all(equal(a, b));
}

float safe_divide(float a, float b)
{
    float _1094;
    if (!(b == 0.0))
    {
        _1094 = a / b;
    }
    else
    {
        _1094 = 0.0;
    }
    return _1094;
}

float sqr(float a)
{
    return a * a;
}

float bump_shadowing_term(vec4 Ng, vec4 N, vec4 I)
{
    float param = dot(Ng, I);
    float param_1 = dot(N, I) * dot(Ng, N);
    float g = safe_divide(param, param_1);
    if (g >= 1.0)
    {
        return 1.0;
    }
    if (g < 0.0)
    {
        return 0.0;
    }
    float param_2 = g;
    float g2 = sqr(param_2);
    return (((-g2) * g) + g2) + g;
}

float fast_acosf(float x)
{
    float f = abs(x);
    float _1119;
    if (f < 1.0)
    {
        _1119 = 1.0 - (1.0 - f);
    }
    else
    {
        _1119 = 1.0;
    }
    float m = _1119;
    float a = sqrt(1.0 - m) * (1.57079637050628662109375 + (m * ((-0.21330098807811737060546875) + (m * (0.077980481088161468505859375 + (m * (-0.02164095081388950347900390625)))))));
    float _1147;
    if (x < 0.0)
    {
        _1147 = 3.1415927410125732421875 - a;
    }
    else
    {
        _1147 = a;
    }
    return _1147;
}

float shift_cos_in(inout float cos_in, float frequency_multiplier)
{
    cos_in = min(cos_in, 1.0);
    float param = cos_in;
    float angle = fast_acosf(param);
    float val = max(cos(angle * frequency_multiplier), 0.0) / cos_in;
    return val;
}

vec4 bsdf_diffuse_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_oren_nayar_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_diffuse_toon_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_glossy_toon_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_translucent_eval_transmit(vec4 I, vec4 omega_in, out float pdf)
{
    vec4 N = sc.N;
    float cos_pi = max(-dot(N, omega_in), 0.0) * 0.3183098733425140380859375;
    pdf = cos_pi;
    return vec4(cos_pi, cos_pi, cos_pi, 0.0);
}

vec4 bsdf_transparent_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_ashikhmin_velvet_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_refraction_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_microfacet_ggx_eval_transmit(vec4 I, vec4 omega_in, inout float pdf)
{
    float alpha_x = sc.data[0];
    float alpha_y = sc.data[1];
    float m_eta = sc.data[2];
    bool m_refractive = sc.type == 23u;
    vec4 N = sc.N;
    bool _2999 = !m_refractive;
    bool _3007;
    if (!_2999)
    {
        _3007 = (alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07;
    }
    else
    {
        _3007 = _2999;
    }
    if (_3007)
    {
        return vec4(0.0);
    }
    float cosNO = dot(N.xyz, I.xyz);
    float cosNI = dot(N.xyz, omega_in.xyz);
    if ((cosNO <= 0.0) || (cosNI >= 0.0))
    {
        return vec4(0.0);
    }
    vec4 ht = -((omega_in * m_eta) + I);
    vec4 Ht = vec4(normalize(ht.xyz), 0.0);
    float cosHO = dot(Ht.xyz, I.xyz);
    float cosHI = dot(Ht.xyz, omega_in.xyz);
    float alpha2 = alpha_x * alpha_y;
    float cosThetaM = dot(N.xyz, Ht.xyz);
    float cosThetaM2 = cosThetaM * cosThetaM;
    float tanThetaM2 = (1.0 - cosThetaM2) / cosThetaM2;
    float cosThetaM4 = cosThetaM2 * cosThetaM2;
    float D = alpha2 / (((3.1415927410125732421875 * cosThetaM4) * (alpha2 + tanThetaM2)) * (alpha2 + tanThetaM2));
    float param = 1.0 + ((alpha2 * (1.0 - (cosNO * cosNO))) / (cosNO * cosNO));
    float G1o = 2.0 / (1.0 + safe_sqrtf(param));
    float param_1 = 1.0 + ((alpha2 * (1.0 - (cosNI * cosNI))) / (cosNI * cosNI));
    float G1i = 2.0 / (1.0 + safe_sqrtf(param_1));
    float G = G1o * G1i;
    float Ht2 = dot(ht.xyz, ht.xyz);
    float common_rsv = (D * (m_eta * m_eta)) / (cosNO * Ht2);
    float out_rsv = (G * abs(cosHI * cosHO)) * common_rsv;
    pdf = (G1o * abs(cosHO * cosHI)) * common_rsv;
    return vec4(out_rsv, out_rsv, out_rsv, 0.0);
}

vec4 bsdf_microfacet_beckmann_eval_transmit(vec4 I, vec4 omega_in, inout float pdf)
{
    float alpha_x = sc.data[0];
    float alpha_y = sc.data[1];
    float m_eta = sc.data[2];
    bool m_refractive = sc.type == 22u;
    vec4 N = sc.N;
    bool _4108 = !m_refractive;
    bool _4116;
    if (!_4108)
    {
        _4116 = (alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07;
    }
    else
    {
        _4116 = _4108;
    }
    if (_4116)
    {
        return vec4(0.0);
    }
    float cosNO = dot(N.xyz, I.xyz);
    float cosNI = dot(N.xyz, omega_in.xyz);
    if ((cosNO <= 0.0) || (cosNI >= 0.0))
    {
        return vec4(0.0);
    }
    vec4 ht = -((omega_in * m_eta) + I);
    vec4 Ht = vec4(normalize(ht.xyz), 0.0);
    float cosHO = dot(Ht.xyz, I.xyz);
    float cosHI = dot(Ht.xyz, omega_in.xyz);
    float alpha2 = alpha_x * alpha_y;
    float cosThetaM = min(dot(N.xyz, Ht.xyz), 1.0);
    float cosThetaM2 = cosThetaM * cosThetaM;
    float tanThetaM2 = (1.0 - cosThetaM2) / cosThetaM2;
    float cosThetaM4 = cosThetaM2 * cosThetaM2;
    float D = exp((-tanThetaM2) / alpha2) / ((3.1415927410125732421875 * alpha2) * cosThetaM4);
    float param = alpha_x;
    float param_1 = cosNO;
    float _4201 = bsdf_beckmann_G1(param, param_1);
    float G1o = _4201;
    float param_2 = alpha_x;
    float param_3 = cosNI;
    float _4207 = bsdf_beckmann_G1(param_2, param_3);
    float G1i = _4207;
    float G = G1o * G1i;
    float Ht2 = dot(ht.xyz, ht.xyz);
    float common_rsv = (D * (m_eta * m_eta)) / (cosNO * Ht2);
    float out_rsv = (G * abs(cosHI * cosHO)) * common_rsv;
    pdf = (G1o * abs(cosHO * cosHI)) * common_rsv;
    return vec4(out_rsv, out_rsv, out_rsv, 0.0);
}

vec4 bsdf_reflection_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_microfacet_multi_ggx_eval_transmit(vec4 I, vec4 omega_in, out float pdf, uint lcg_state)
{
    pdf = 0.0;
    return vec4(0.0);
}

vec4 bsdf_microfacet_multi_ggx_glass_eval_transmit(vec4 I, vec4 omega_in, inout float pdf, inout uint lcg_state)
{
    if ((sc.data[0] * sc.data[1]) < 1.0000000116860974230803549289703e-07)
    {
        return vec4(0.0);
    }
    vec4 Z = sc.N;
    vec4 param = Z;
    vec4 X;
    vec4 param_1 = X;
    vec4 param_2;
    make_orthonormals(param, param_1, param_2);
    X = param_1;
    vec4 Y = param_2;
    vec4 localI = vec4(dot(I.xyz, X.xyz), dot(I.xyz, Y.xyz), dot(I.xyz, Z.xyz), 0.0);
    vec4 localO = vec4(dot(omega_in.xyz, X.xyz), dot(omega_in.xyz, Y.xyz), dot(omega_in.xyz, Z.xyz), 0.0);
    pdf = mf_glass_pdf(localI, localO, sc.data[0], sc.data[2]);
    vec4 color = vec4(sc.data[3], sc.data[4], sc.data[5], 0.0);
    float ax = sc.data[0];
    float ay = sc.data[1];
    float ior = sc.data[2];
    vec4 param_3 = localI;
    vec4 param_4 = localO;
    uint param_5 = lcg_state;
    bool param_6 = false;
    vec4 _7244 = mf_eval_glass(param_3, param_4, false, color, ax, ay, param_5, ior, param_6, color);
    lcg_state = param_5;
    return _7244;
}

vec4 bsdf_ashikhmin_shirley_eval_transmit(vec4 I, vec4 omega_in, float pdf)
{
    return vec4(0.0);
}

vec4 bsdf_eval(ShaderClosure sc_1, vec4 omega_in, inout float pdf)
{
    vec4 _9196;
    if ((uint(arg.sd.type) & 60u) != 0u)
    {
        _9196 = arg.sd.N;
    }
    else
    {
        _9196 = arg.sd.Ng;
    }
    vec4 Ng = _9196;
    uint lcg_state = arg.sd.lcg_state;
    vec4 eval;
    if (dot(Ng, omega_in) >= 0.0)
    {
        switch (sc_1.type)
        {
            case 2u:
            case 31u:
            {
                float param = pdf;
                vec4 _9236 = bsdf_diffuse_eval_reflect(arg.sd.I, omega_in, param);
                pdf = param;
                eval = _9236;
                break;
            }
            case 3u:
            {
                float param_1 = pdf;
                vec4 _9243 = bsdf_oren_nayar_eval_reflect(arg.sd.I, omega_in, param_1);
                pdf = param_1;
                eval = _9243;
                break;
            }
            case 7u:
            {
                float param_2 = pdf;
                vec4 _9250 = bsdf_diffuse_toon_eval_reflect(arg.sd.I, omega_in, param_2);
                pdf = param_2;
                eval = _9250;
                break;
            }
            case 19u:
            {
                float param_3 = pdf;
                vec4 _9257 = bsdf_glossy_toon_eval_reflect(arg.sd.I, omega_in, param_3);
                pdf = param_3;
                eval = _9257;
                break;
            }
            case 8u:
            {
                float param_4 = pdf;
                pdf = param_4;
                eval = bsdf_translucent_eval_reflect(arg.sd.I, omega_in, param_4);
                break;
            }
            case 21u:
            {
                float param_5 = pdf;
                pdf = param_5;
                eval = bsdf_refraction_eval_reflect(arg.sd.I, omega_in, param_5);
                break;
            }
            case 33u:
            {
                float param_6 = pdf;
                pdf = param_6;
                eval = bsdf_transparent_eval_reflect(arg.sd.I, omega_in, param_6);
                break;
            }
            case 17u:
            {
                float param_7 = pdf;
                vec4 _9285 = bsdf_ashikhmin_velvet_eval_reflect(arg.sd.I, omega_in, param_7);
                pdf = param_7;
                eval = _9285;
                break;
            }
            case 10u:
            case 11u:
            case 12u:
            case 23u:
            {
                float param_8 = pdf;
                vec4 _9292 = bsdf_microfacet_ggx_eval_reflect(arg.sd.I, omega_in, param_8);
                pdf = param_8;
                eval = _9292;
                break;
            }
            case 13u:
            case 22u:
            {
                float param_9 = pdf;
                vec4 _9299 = bsdf_microfacet_beckmann_eval_reflect(arg.sd.I, omega_in, param_9);
                pdf = param_9;
                eval = _9299;
                break;
            }
            case 9u:
            {
                float param_10 = pdf;
                pdf = param_10;
                eval = bsdf_reflection_eval_reflect(arg.sd.I, omega_in, param_10);
                break;
            }
            case 14u:
            case 15u:
            {
                float param_11 = pdf;
                uint param_12 = lcg_state;
                vec4 _9315 = bsdf_microfacet_multi_ggx_eval_reflect(arg.sd.I, omega_in, param_11, param_12);
                pdf = param_11;
                lcg_state = param_12;
                eval = _9315;
                break;
            }
            case 24u:
            case 27u:
            {
                float param_13 = pdf;
                uint param_14 = lcg_state;
                vec4 _9325 = bsdf_microfacet_multi_ggx_glass_eval_reflect(arg.sd.I, omega_in, param_13, param_14);
                pdf = param_13;
                lcg_state = param_14;
                eval = _9325;
                break;
            }
            case 16u:
            {
                float param_15 = pdf;
                vec4 _9333 = bsdf_ashikhmin_shirley_eval_reflect(arg.sd.I, omega_in, param_15);
                pdf = param_15;
                eval = _9333;
                break;
            }
            default:
            {
                eval = vec4(0.0);
                break;
            }
        }
        bool _9339 = sc_1.type >= 2u;
        bool _9344;
        if (_9339)
        {
            _9344 = sc_1.type <= 8u;
        }
        else
        {
            _9344 = _9339;
        }
        if (_9344)
        {
            if (!isequal_float3(sc_1.N, arg.sd.N))
            {
                vec4 param_16 = arg.sd.N;
                vec4 param_17 = sc_1.N;
                vec4 param_18 = omega_in;
                eval *= bump_shadowing_term(param_16, param_17, param_18);
            }
        }
        float frequency_multiplier = push.data_ptr._objects.data[arg.sd.object].shadow_terminator_offset;
        if (frequency_multiplier > 1.0)
        {
            float param_19 = dot(omega_in, sc_1.N);
            float _9500 = shift_cos_in(param_19, frequency_multiplier);
            eval *= _9500;
        }
    }
    else
    {
        switch (sc_1.type)
        {
            case 2u:
            case 31u:
            {
                float param_20 = pdf;
                pdf = param_20;
                eval = bsdf_diffuse_eval_transmit(arg.sd.I, omega_in, param_20);
                break;
            }
            case 3u:
            {
                float param_21 = pdf;
                pdf = param_21;
                eval = bsdf_oren_nayar_eval_transmit(arg.sd.I, omega_in, param_21);
                break;
            }
            case 7u:
            {
                float param_22 = pdf;
                pdf = param_22;
                eval = bsdf_diffuse_toon_eval_transmit(arg.sd.I, omega_in, param_22);
                break;
            }
            case 19u:
            {
                float param_23 = pdf;
                pdf = param_23;
                eval = bsdf_glossy_toon_eval_transmit(arg.sd.I, omega_in, param_23);
                break;
            }
            case 8u:
            {
                float param_24 = pdf;
                vec4 _9553 = bsdf_translucent_eval_transmit(arg.sd.I, omega_in, param_24);
                pdf = param_24;
                eval = _9553;
                break;
            }
            case 33u:
            {
                float param_25 = pdf;
                pdf = param_25;
                eval = bsdf_transparent_eval_transmit(arg.sd.I, omega_in, param_25);
                break;
            }
            case 17u:
            {
                float param_26 = pdf;
                pdf = param_26;
                eval = bsdf_ashikhmin_velvet_eval_transmit(arg.sd.I, omega_in, param_26);
                break;
            }
            case 21u:
            {
                float param_27 = pdf;
                pdf = param_27;
                eval = bsdf_refraction_eval_transmit(arg.sd.I, omega_in, param_27);
                break;
            }
            case 10u:
            case 11u:
            case 12u:
            case 23u:
            {
                float param_28 = pdf;
                vec4 _9581 = bsdf_microfacet_ggx_eval_transmit(arg.sd.I, omega_in, param_28);
                pdf = param_28;
                eval = _9581;
                break;
            }
            case 13u:
            case 22u:
            {
                float param_29 = pdf;
                vec4 _9588 = bsdf_microfacet_beckmann_eval_transmit(arg.sd.I, omega_in, param_29);
                pdf = param_29;
                eval = _9588;
                break;
            }
            case 9u:
            {
                float param_30 = pdf;
                pdf = param_30;
                eval = bsdf_reflection_eval_transmit(arg.sd.I, omega_in, param_30);
                break;
            }
            case 14u:
            case 15u:
            {
                float param_31 = pdf;
                uint param_32 = lcg_state;
                vec4 _9604 = bsdf_microfacet_multi_ggx_eval_transmit(arg.sd.I, omega_in, param_31, param_32);
                pdf = param_31;
                lcg_state = param_32;
                eval = _9604;
                break;
            }
            case 24u:
            case 27u:
            {
                float param_33 = pdf;
                uint param_34 = lcg_state;
                vec4 _9614 = bsdf_microfacet_multi_ggx_glass_eval_transmit(arg.sd.I, omega_in, param_33, param_34);
                pdf = param_33;
                lcg_state = param_34;
                eval = _9614;
                break;
            }
            case 16u:
            {
                float param_35 = pdf;
                pdf = param_35;
                eval = bsdf_ashikhmin_shirley_eval_transmit(arg.sd.I, omega_in, param_35);
                break;
            }
            default:
            {
                eval = vec4(0.0);
                break;
            }
        }
        bool _9628 = sc_1.type >= 2u;
        bool _9633;
        if (_9628)
        {
            _9633 = sc_1.type <= 8u;
        }
        else
        {
            _9633 = _9628;
        }
        if (_9633)
        {
            if (!isequal_float3(sc_1.N, arg.sd.N))
            {
                vec4 param_36 = -arg.sd.N;
                vec4 param_37 = sc_1.N;
                vec4 param_38 = omega_in;
                eval *= bump_shadowing_term(param_36, param_37, param_38);
            }
        }
    }
    arg.sd.lcg_state = lcg_state;
    memoryBarrier();
    return eval;
}

float power_heuristic(float a, float b)
{
    return (a * a) / ((a * a) + (b * b));
}

void bsdf_eval_accum(uint type, inout vec4 value, float mis_weight)
{
    arg.eval.sum_no_mis += value;
    value *= mis_weight;
    if (arg.use_light_pass != 0)
    {
        bool _8995 = (type >= 2u) && (type <= 8u);
        bool _9004;
        if (!_8995)
        {
            _9004 = (type == 31u) || (type == 32u);
        }
        else
        {
            _9004 = _8995;
        }
        if (_9004)
        {
            arg.eval.diffuse += value;
        }
        else
        {
            if (((type >= 9u) && (type <= 20u)) || (type == 29u))
            {
                arg.eval.glossy += value;
            }
            else
            {
                if ((type >= 21u) && (type <= 30u))
                {
                    arg.eval.transmission += value;
                }
            }
        }
    }
    else
    {
        arg.eval.diffuse += value;
    }
}

void _shader_bsdf_multi_eval_branched(vec4 omega_in, float light_pdf, bool use_mis)
{
    int it_next = arg.sd.alloc_offset;
    float _9702;
    for (int i = 0; i < arg.sd.num_closure; i++)
    {
        ShaderClosure _9683;
        _9683.weight = push.pool_ptr.pool_sc.data[it_next].weight;
        _9683.type = push.pool_ptr.pool_sc.data[it_next].type;
        _9683.sample_weight = push.pool_ptr.pool_sc.data[it_next].sample_weight;
        _9683.N = push.pool_ptr.pool_sc.data[it_next].N;
        _9683.next = push.pool_ptr.pool_sc.data[it_next].next;
        _9683.data[0] = push.pool_ptr.pool_sc.data[it_next].data[0];
        _9683.data[1] = push.pool_ptr.pool_sc.data[it_next].data[1];
        _9683.data[2] = push.pool_ptr.pool_sc.data[it_next].data[2];
        _9683.data[3] = push.pool_ptr.pool_sc.data[it_next].data[3];
        _9683.data[4] = push.pool_ptr.pool_sc.data[it_next].data[4];
        _9683.data[5] = push.pool_ptr.pool_sc.data[it_next].data[5];
        _9683.data[6] = push.pool_ptr.pool_sc.data[it_next].data[6];
        _9683.data[7] = push.pool_ptr.pool_sc.data[it_next].data[7];
        _9683.data[8] = push.pool_ptr.pool_sc.data[it_next].data[8];
        _9683.data[9] = push.pool_ptr.pool_sc.data[it_next].data[9];
        _9683.data[10] = push.pool_ptr.pool_sc.data[it_next].data[10];
        _9683.data[11] = push.pool_ptr.pool_sc.data[it_next].data[11];
        _9683.data[12] = push.pool_ptr.pool_sc.data[it_next].data[12];
        _9683.data[13] = push.pool_ptr.pool_sc.data[it_next].data[13];
        _9683.data[14] = push.pool_ptr.pool_sc.data[it_next].data[14];
        _9683.data[15] = push.pool_ptr.pool_sc.data[it_next].data[15];
        _9683.data[16] = push.pool_ptr.pool_sc.data[it_next].data[16];
        _9683.data[17] = push.pool_ptr.pool_sc.data[it_next].data[17];
        _9683.data[18] = push.pool_ptr.pool_sc.data[it_next].data[18];
        _9683.data[19] = push.pool_ptr.pool_sc.data[it_next].data[19];
        _9683.data[20] = push.pool_ptr.pool_sc.data[it_next].data[20];
        _9683.data[21] = push.pool_ptr.pool_sc.data[it_next].data[21];
        _9683.data[22] = push.pool_ptr.pool_sc.data[it_next].data[22];
        _9683.data[23] = push.pool_ptr.pool_sc.data[it_next].data[23];
        _9683.data[24] = push.pool_ptr.pool_sc.data[it_next].data[24];
        sc = _9683;
        if (sc.type <= 33u)
        {
            float bsdf_pdf = 0.0;
            ShaderClosure _9691 = sc;
            float param = bsdf_pdf;
            vec4 _9694 = bsdf_eval(_9691, omega_in, param);
            bsdf_pdf = param;
            vec4 b_eval = _9694;
            if (!(bsdf_pdf == 0.0))
            {
                if (use_mis)
                {
                    float param_1 = light_pdf;
                    float param_2 = bsdf_pdf;
                    _9702 = power_heuristic(param_1, param_2);
                }
                else
                {
                    _9702 = 1.0;
                }
                float mis_weight = _9702;
                uint param_3 = sc.type;
                vec4 param_4 = b_eval * sc.weight;
                float param_5 = mis_weight;
                bsdf_eval_accum(param_3, param_4, param_5);
            }
        }
        it_next = sc.next;
    }
}

void _shader_bsdf_multi_eval(vec4 omega_in, inout float pdf, int skip_sc, inout float sum_pdf, inout float sum_sample_weight)
{
    int it_next = arg.sd.alloc_offset;
    for (int i = 0; i < arg.sd.num_closure; i++)
    {
        ShaderClosure _9747;
        _9747.weight = push.pool_ptr.pool_sc.data[it_next].weight;
        _9747.type = push.pool_ptr.pool_sc.data[it_next].type;
        _9747.sample_weight = push.pool_ptr.pool_sc.data[it_next].sample_weight;
        _9747.N = push.pool_ptr.pool_sc.data[it_next].N;
        _9747.next = push.pool_ptr.pool_sc.data[it_next].next;
        _9747.data[0] = push.pool_ptr.pool_sc.data[it_next].data[0];
        _9747.data[1] = push.pool_ptr.pool_sc.data[it_next].data[1];
        _9747.data[2] = push.pool_ptr.pool_sc.data[it_next].data[2];
        _9747.data[3] = push.pool_ptr.pool_sc.data[it_next].data[3];
        _9747.data[4] = push.pool_ptr.pool_sc.data[it_next].data[4];
        _9747.data[5] = push.pool_ptr.pool_sc.data[it_next].data[5];
        _9747.data[6] = push.pool_ptr.pool_sc.data[it_next].data[6];
        _9747.data[7] = push.pool_ptr.pool_sc.data[it_next].data[7];
        _9747.data[8] = push.pool_ptr.pool_sc.data[it_next].data[8];
        _9747.data[9] = push.pool_ptr.pool_sc.data[it_next].data[9];
        _9747.data[10] = push.pool_ptr.pool_sc.data[it_next].data[10];
        _9747.data[11] = push.pool_ptr.pool_sc.data[it_next].data[11];
        _9747.data[12] = push.pool_ptr.pool_sc.data[it_next].data[12];
        _9747.data[13] = push.pool_ptr.pool_sc.data[it_next].data[13];
        _9747.data[14] = push.pool_ptr.pool_sc.data[it_next].data[14];
        _9747.data[15] = push.pool_ptr.pool_sc.data[it_next].data[15];
        _9747.data[16] = push.pool_ptr.pool_sc.data[it_next].data[16];
        _9747.data[17] = push.pool_ptr.pool_sc.data[it_next].data[17];
        _9747.data[18] = push.pool_ptr.pool_sc.data[it_next].data[18];
        _9747.data[19] = push.pool_ptr.pool_sc.data[it_next].data[19];
        _9747.data[20] = push.pool_ptr.pool_sc.data[it_next].data[20];
        _9747.data[21] = push.pool_ptr.pool_sc.data[it_next].data[21];
        _9747.data[22] = push.pool_ptr.pool_sc.data[it_next].data[22];
        _9747.data[23] = push.pool_ptr.pool_sc.data[it_next].data[23];
        _9747.data[24] = push.pool_ptr.pool_sc.data[it_next].data[24];
        sc = _9747;
        bool _9749 = it_next != skip_sc;
        bool _9755;
        if (_9749)
        {
            _9755 = sc.type <= 33u;
        }
        else
        {
            _9755 = _9749;
        }
        if (_9755)
        {
            float bsdf_pdf = 0.0;
            ShaderClosure _9760 = sc;
            float param = bsdf_pdf;
            vec4 _9763 = bsdf_eval(_9760, omega_in, param);
            bsdf_pdf = param;
            vec4 eval = _9763;
            if (!(bsdf_pdf == 0.0))
            {
                uint param_1 = sc.type;
                vec4 param_2 = eval * sc.weight;
                float param_3 = 1.0;
                bsdf_eval_accum(param_1, param_2, param_3);
                sum_pdf += (bsdf_pdf * sc.sample_weight);
            }
            sum_sample_weight += sc.sample_weight;
        }
        it_next = sc.next;
    }
    float _9795;
    if (sum_sample_weight > 0.0)
    {
        _9795 = sum_pdf / sum_sample_weight;
    }
    else
    {
        _9795 = 0.0;
    }
    pdf = _9795;
}

void bsdf_eval_mis(float value)
{
    if (arg.use_light_pass != 0)
    {
        arg.eval.diffuse *= value;
        arg.eval.glossy *= value;
        arg.eval.transmission *= value;
    }
    else
    {
        arg.eval.diffuse *= value;
    }
}

void shader_bsdf_eval()
{
    bool use_mis = floatBitsToInt(arg.eval.diffuse.y) != int(0u);
    vec4 omega_in = arg.omega_in;
    float light_pdf = arg.pdf;
    uint param = 45u;
    vec4 param_1 = vec4(0.0);
    bsdf_eval_init(param, param_1);
    if (_8902.kernel_data.integrator.branched != int(0u))
    {
        float param_2 = light_pdf;
        bool param_3 = use_mis;
        _shader_bsdf_multi_eval_branched(omega_in, param_2, param_3);
    }
    else
    {
        float pdf;
        float param_4 = pdf;
        float param_5 = 0.0;
        float param_6 = 0.0;
        _shader_bsdf_multi_eval(omega_in, param_4, -1, param_5, param_6);
        pdf = param_4;
        if (use_mis)
        {
            float param_7 = light_pdf;
            float param_8 = pdf;
            float weight = power_heuristic(param_7, param_8);
            float param_9 = weight;
            bsdf_eval_mis(param_9);
        }
    }
}

int shader_bsdf_pick(inout float randu)
{
    int sampled = arg.sd.atomic_offset;
    if (arg.sd.num_closure > 1)
    {
        float sum = 0.0;
        int next = sampled;
        for (int i = 0; i < arg.sd.num_closure; i++)
        {
            if (push.pool_ptr.pool_sc.data[next].type <= 39u)
            {
                sum += push.pool_ptr.pool_sc.data[next].sample_weight;
            }
            next++;
        }
        float r = randu * sum;
        float partial_sum = 0.0;
        sampled = arg.sd.atomic_offset;
        for (int i_1 = 0; i_1 < arg.sd.num_closure; i_1++)
        {
            if (push.pool_ptr.pool_sc.data[sampled + i_1].type <= 39u)
            {
                float next_sum = partial_sum + push.pool_ptr.pool_sc.data[sampled + i_1].sample_weight;
                if (r < next_sum)
                {
                    sampled += i_1;
                    randu = (r - partial_sum) / push.pool_ptr.pool_sc.data[sampled].sample_weight;
                    break;
                }
                partial_sum = next_sum;
            }
        }
    }
    return (push.pool_ptr.pool_sc.data[sampled].type <= 33u) ? sampled : (-1);
}

void to_unit_disk(inout float x, inout float y)
{
    float phi = 6.283185482025146484375 * x;
    float r = sqrt(y);
    x = r * cos(phi);
    y = r * sin(phi);
}

void sample_cos_hemisphere(vec4 N, inout float randu, inout float randv, out vec4 omega_in, out float pdf)
{
    float param = randu;
    float param_1 = randv;
    to_unit_disk(param, param_1);
    randu = param;
    randv = param_1;
    float costheta = sqrt(max((1.0 - (randu * randu)) - (randv * randv), 0.0));
    vec4 param_2 = N;
    vec4 T;
    vec4 param_3 = T;
    vec4 param_4;
    make_orthonormals(param_2, param_3, param_4);
    T = param_3;
    vec4 B_1 = param_4;
    omega_in = ((T * randu) + (B_1 * randv)) + (N * costheta);
    pdf = costheta * 0.3183098733425140380859375;
}

int bsdf_diffuse_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, inout float randu, inout float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    vec4 N = sc.N;
    float param = randu;
    float param_1 = randv;
    vec4 param_2 = omega_in;
    float param_3 = pdf;
    sample_cos_hemisphere(N, param, param_1, param_2, param_3);
    randu = param;
    randv = param_1;
    omega_in = param_2;
    pdf = param_3;
    if (dot(Ng, omega_in) > 0.0)
    {
        eval = vec4(pdf, pdf, pdf, 0.0);
        domega_in_dx = (N * (2.0 * dot(N, dIdx))) - dIdx;
        domega_in_dy = (N * (2.0 * dot(N, dIdy))) - dIdy;
    }
    else
    {
        pdf = 0.0;
    }
    return 6;
}

void sample_uniform_hemisphere(vec4 N, float randu, float randv, out vec4 omega_in, out float pdf)
{
    float z = randu;
    float r = sqrt(max(0.0, 1.0 - (z * z)));
    float phi = 6.283185482025146484375 * randv;
    float x = r * cos(phi);
    float y = r * sin(phi);
    vec4 param = N;
    vec4 T;
    vec4 param_1 = T;
    vec4 param_2;
    make_orthonormals(param, param_1, param_2);
    T = param_1;
    vec4 B_1 = param_2;
    omega_in = ((T * x) + (B_1 * y)) + (N * z);
    pdf = 0.15915493667125701904296875;
}

int bsdf_oren_nayar_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, out vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    float param = randu;
    float param_1 = randv;
    vec4 param_2 = omega_in;
    float param_3 = pdf;
    sample_uniform_hemisphere(sc.N, param, param_1, param_2, param_3);
    omega_in = param_2;
    pdf = param_3;
    if (dot(Ng, omega_in) > 0.0)
    {
        vec4 param_4 = sc.N;
        vec4 param_5 = I;
        vec4 param_6 = omega_in;
        eval = bsdf_oren_nayar_get_intensity(param_4, param_5, param_6);
        domega_in_dx = (sc.N * (2.0 * dot(sc.N, dIdx))) - dIdx;
        domega_in_dy = (sc.N * (2.0 * dot(sc.N, dIdy))) - dIdy;
    }
    else
    {
        pdf = 0.0;
        eval = vec4(0.0);
    }
    return 6;
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
    vec4 B_1 = param_4;
    omega_in = ((T * x) + (B_1 * y)) + (N * z);
    pdf = 0.15915493667125701904296875 / (1.0 - zMin);
}

int bsdf_diffuse_toon_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    float max_angle = sc.data[0] * 1.57079637050628662109375;
    float smooth_rsv = sc.data[1] * 1.57079637050628662109375;
    float param = max_angle;
    float param_1 = smooth_rsv;
    float sample_angle = bsdf_toon_get_sample_angle(param, param_1);
    float angle = sample_angle * randu;
    if (sample_angle > 0.0)
    {
        float param_2 = sample_angle;
        float param_3 = randu;
        float param_4 = randv;
        vec4 param_5 = omega_in;
        float param_6 = pdf;
        sample_uniform_cone(sc.N, param_2, param_3, param_4, param_5, param_6);
        omega_in = param_5;
        pdf = param_6;
        if (dot(Ng, omega_in) > 0.0)
        {
            float param_7 = max_angle;
            float param_8 = smooth_rsv;
            float param_9 = angle;
            eval = bsdf_toon_get_intensity(param_7, param_8, param_9) * pdf;
            domega_in_dx = (sc.N * (2.0 * dot(sc.N, dIdx))) - dIdx;
            domega_in_dy = (sc.N * (2.0 * dot(sc.N, dIdy))) - dIdy;
        }
        else
        {
            pdf = 0.0;
        }
    }
    return 6;
}

int bsdf_glossy_toon_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    float max_angle = sc.data[0] * 1.57079637050628662109375;
    float smooth_rsv = sc.data[1] * 1.57079637050628662109375;
    float cosNO = dot(sc.N, I);
    if (cosNO > 0.0)
    {
        vec4 R = (sc.N * (2.0 * cosNO)) - I;
        float param = max_angle;
        float param_1 = smooth_rsv;
        float sample_angle = bsdf_toon_get_sample_angle(param, param_1);
        float angle = sample_angle * randu;
        float param_2 = sample_angle;
        float param_3 = randu;
        float param_4 = randv;
        vec4 param_5 = omega_in;
        float param_6 = pdf;
        sample_uniform_cone(R, param_2, param_3, param_4, param_5, param_6);
        omega_in = param_5;
        pdf = param_6;
        if (dot(Ng, omega_in) > 0.0)
        {
            float cosNI = dot(sc.N, omega_in);
            if (cosNI > 0.0)
            {
                float param_7 = max_angle;
                float param_8 = smooth_rsv;
                float param_9 = angle;
                eval = bsdf_toon_get_intensity(param_7, param_8, param_9) * pdf;
                domega_in_dx = (sc.N * (2.0 * dot(sc.N, dIdx))) - dIdx;
                domega_in_dy = (sc.N * (2.0 * dot(sc.N, dIdy))) - dIdy;
            }
            else
            {
                pdf = 0.0;
            }
        }
        else
        {
            pdf = 0.0;
        }
    }
    return 10;
}

int bsdf_translucent_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, inout float randu, inout float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    vec4 N = sc.N;
    float param = randu;
    float param_1 = randv;
    vec4 param_2 = omega_in;
    float param_3 = pdf;
    sample_cos_hemisphere(-N, param, param_1, param_2, param_3);
    randu = param;
    randv = param_1;
    omega_in = param_2;
    pdf = param_3;
    if (dot(Ng, omega_in) < 0.0)
    {
        eval = vec4(pdf, pdf, pdf, 0.0);
        domega_in_dx = -((N * (2.0 * dot(N, dIdx))) - dIdx);
        domega_in_dy = -((N * (2.0 * dot(N, dIdy))) - dIdy);
    }
    else
    {
        pdf = 0.0;
    }
    return 5;
}

int bsdf_transparent_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, out vec4 eval, out vec4 omega_in, out vec4 domega_in_dx, out vec4 domega_in_dy, out float pdf)
{
    omega_in = -I;
    domega_in_dx = -dIdx;
    domega_in_dy = -dIdy;
    pdf = 1.0;
    eval = vec4(1.0, 1.0, 1.0, 0.0);
    return 33;
}

int bsdf_ashikhmin_velvet_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    float m_invsigma2 = sc.data[1];
    vec4 N = sc.N;
    float param = randu;
    float param_1 = randv;
    vec4 param_2 = omega_in;
    float param_3 = pdf;
    sample_uniform_hemisphere(N, param, param_1, param_2, param_3);
    omega_in = param_2;
    pdf = param_3;
    if (dot(Ng, omega_in) > 0.0)
    {
        vec4 H = normalize(omega_in + I);
        float cosNI = dot(N, omega_in);
        float cosNO = dot(N, I);
        float cosNH = dot(N, H);
        float cosHO = abs(dot(I, H));
        bool _8793 = abs(cosNO) > 9.9999997473787516355514526367188e-06;
        bool _8799;
        if (_8793)
        {
            _8799 = abs(cosNH) < 0.999989986419677734375;
        }
        else
        {
            _8799 = _8793;
        }
        if (_8799 && (cosHO > 9.9999997473787516355514526367188e-06))
        {
            float cosNHdivHO = cosNH / cosHO;
            cosNHdivHO = max(cosNHdivHO, 9.9999997473787516355514526367188e-06);
            float fac1 = 2.0 * abs(cosNHdivHO * cosNO);
            float fac2 = 2.0 * abs(cosNHdivHO * cosNI);
            float sinNH2 = 1.0 - (cosNH * cosNH);
            float sinNH4 = sinNH2 * sinNH2;
            float cotangent2 = (cosNH * cosNH) / sinNH2;
            float D = ((exp((-cotangent2) * m_invsigma2) * m_invsigma2) * 0.3183098733425140380859375) / sinNH4;
            float G = min(1.0, min(fac1, fac2));
            float power = (0.25 * (D * G)) / cosNO;
            eval = vec4(power, power, power, 0.0);
            domega_in_dx = (N * (2.0 * dot(N, dIdx))) - dIdx;
            domega_in_dy = (N * (2.0 * dot(N, dIdy))) - dIdy;
        }
        else
        {
            pdf = 0.0;
        }
    }
    else
    {
        pdf = 0.0;
    }
    return 6;
}

float fresnel_dielectric(float eta, vec4 N, vec4 I, out vec4 R, inout vec4 T, vec4 dIdx, vec4 dIdy, out vec4 dRdx, out vec4 dRdy, inout vec4 dTdx, inout vec4 dTdy, out bool is_inside)
{
    float _cos = dot(N, I);
    float neta;
    vec4 Nn;
    if (_cos > 0.0)
    {
        neta = 1.0 / eta;
        Nn = N;
        is_inside = false;
    }
    else
    {
        _cos = -_cos;
        neta = eta;
        Nn = -N;
        is_inside = true;
    }
    R = (Nn * (2.0 * _cos)) - I;
    dRdx = (Nn * (2.0 * dot(Nn, dIdx))) - dIdx;
    dRdy = (Nn * (2.0 * dot(Nn, dIdy))) - dIdy;
    float arg_1 = 1.0 - ((neta * neta) * (1.0 - (_cos * _cos)));
    if (arg_1 < 0.0)
    {
        T = vec4(0.0);
        dTdx = vec4(0.0);
        dTdy = vec4(0.0);
        return 1.0;
    }
    else
    {
        float dnp = max(sqrt(arg_1), 1.0000000116860974230803549289703e-07);
        float nK = (neta * _cos) - dnp;
        T = (-(I * neta)) + (Nn * nK);
        dTdx = (-(dIdx * neta)) + (Nn * ((neta - (((neta * neta) * _cos) / dnp)) * dot(dIdx, Nn)));
        dTdy = (-(dIdy * neta)) + (Nn * ((neta - (((neta * neta) * _cos) / dnp)) * dot(dIdy, Nn)));
        float cosTheta1 = _cos;
        float cosTheta2 = -dot(Nn, T);
        float pPara = (cosTheta1 - (eta * cosTheta2)) / (cosTheta1 + (eta * cosTheta2));
        float pPerp = ((eta * cosTheta1) - cosTheta2) / ((eta * cosTheta1) + cosTheta2);
        return 0.5 * ((pPara * pPara) + (pPerp * pPerp));
    }
}

int bsdf_refraction_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    float m_eta = sc.data[2];
    vec4 N = sc.N;
    float param = m_eta;
    vec4 R;
    vec4 param_1 = R;
    vec4 T;
    vec4 param_2 = T;
    vec4 dRdx;
    vec4 param_3 = dRdx;
    vec4 dRdy;
    vec4 param_4 = dRdy;
    vec4 dTdx;
    vec4 param_5 = dTdx;
    vec4 dTdy;
    vec4 param_6 = dTdy;
    bool inside;
    bool param_7 = inside;
    float _4758 = fresnel_dielectric(param, N, I, param_1, param_2, dIdx, dIdy, param_3, param_4, param_5, param_6, param_7);
    R = param_1;
    T = param_2;
    dRdx = param_3;
    dRdy = param_4;
    dTdx = param_5;
    dTdy = param_6;
    inside = param_7;
    float fresnel = _4758;
    if ((!inside) && (!(fresnel == 1.0)))
    {
        pdf = 1000000.0;
        eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
        omega_in = T;
        domega_in_dx = dTdx;
        domega_in_dy = dTdy;
    }
    return 17;
}

float copysignf(float a, float b)
{
    float r = abs(a);
    float s = sign(b);
    float _1009;
    if (s >= 0.0)
    {
        _1009 = r;
    }
    else
    {
        _1009 = -r;
    }
    return _1009;
}

float madd(float a, float b, float c)
{
    return (a * b) + c;
}

float fast_erff(float x)
{
    float a = abs(x);
    if (a >= 12.30000019073486328125)
    {
        float param = 1.0;
        float param_1 = x;
        return copysignf(param, param_1);
    }
    float b = 1.0 - (1.0 - a);
    float r = madd(madd(madd(madd(madd(madd(4.3063799239462241530418395996094e-05, b, 0.00027656721067614853382110595703125), b, 0.00015201429778244346380233764648438), b, 0.009270527400076389312744140625), b, 0.0422820113599300384521484375), b, 0.070523075759410858154296875), b, 1.0);
    float s = r * r;
    float t = s * s;
    float u = t * t;
    float v = u * u;
    float param_2 = 1.0 - (1.0 / v);
    float param_3 = x;
    return copysignf(param_2, param_3);
}

float fast_log2f(inout float x)
{
    x = clamp(x, 1.1754943508222875079687365372222e-38, 3.4028234663852885981170418348452e+38);
    uint bits = floatBitsToUint(x);
    int exponent = int(bits >> uint(23)) - 127;
    float f = uintBitsToFloat((bits & 8388607u) | 1065353216u) - 1.0;
    float f2 = f * f;
    float f4 = f2 * f2;
    float hi = madd(f, -0.009310496039688587188720703125, 0.0520646907389163970947265625);
    float lo = madd(f, 0.4786848127841949462890625, -0.7211658954620361328125);
    hi = madd(f, hi, -0.13753123581409454345703125);
    hi = madd(f, hi, 0.24187369644641876220703125);
    hi = madd(f, hi, -0.347305476665496826171875);
    lo = madd(f, lo, 1.4426898956298828125);
    return ((f4 * hi) + (f * lo)) + float(exponent);
}

float fast_logf(float x)
{
    float param = x;
    float _1227 = fast_log2f(param);
    return _1227 * 0.693147182464599609375;
}

float fast_ierff(float x)
{
    float a = abs(x);
    if (a > 0.999999940395355224609375)
    {
        a = 0.999999940395355224609375;
    }
    float param = (1.0 - a) * (1.0 + a);
    float w = -fast_logf(param);
    float p;
    if (w < 5.0)
    {
        w -= 2.5;
        p = 2.8102263627260981593281030654907e-08;
        p = madd(p, w, 3.4327393905186909250915050506592e-07);
        p = madd(p, w, -3.5233877042628591880202293395996e-06);
        p = madd(p, w, -4.3915065361943561583757400512695e-06);
        p = madd(p, w, 0.00021858086984138935804367065429688);
        p = madd(p, w, -0.001253725029528141021728515625);
        p = madd(p, w, -0.0041776816360652446746826171875);
        p = madd(p, w, 0.24664072692394256591796875);
        p = madd(p, w, 1.50140941143035888671875);
    }
    else
    {
        w = sqrt(w) - 3.0;
        p = -0.00020021425734739750623703002929688;
        p = madd(p, w, 0.00010095055768033489584922790527344);
        p = madd(p, w, 0.00134934321977198123931884765625);
        p = madd(p, w, -0.00367342843674123287200927734375);
        p = madd(p, w, 0.0057395077310502529144287109375);
        p = madd(p, w, -0.0076224613003432750701904296875);
        p = madd(p, w, 0.00943887047469615936279296875);
        p = madd(p, w, 1.00167405605316162109375);
        p = madd(p, w, 2.832976818084716796875);
    }
    return p * x;
}

void microfacet_beckmann_sample_slopes(float cos_theta_i, float sin_theta_i, float randu, float randv, out float slope_x, out float slope_y, out float G1i)
{
    if (cos_theta_i >= 0.999989986419677734375)
    {
        float r = sqrt(-log(randu));
        float phi = 6.283185482025146484375 * randv;
        slope_x = r * cos(phi);
        slope_y = r * sin(phi);
        G1i = 1.0;
        return;
    }
    float tan_theta_i = sin_theta_i / cos_theta_i;
    float inv_a = tan_theta_i;
    float cot_theta_i = 1.0 / tan_theta_i;
    float param = cot_theta_i;
    float erf_a = fast_erff(param);
    float exp_a2 = exp((-cot_theta_i) * cot_theta_i);
    float Lambda = (0.5 * (erf_a - 1.0)) + (0.2820948064327239990234375 * (exp_a2 * inv_a));
    float G1 = 1.0 / (1.0 + Lambda);
    G1i = G1;
    float K = tan_theta_i * 0.564189612865447998046875;
    float y_approx = randu * ((1.0 + erf_a) + (K * (1.0 - (erf_a * erf_a))));
    float y_exact = randu * ((1.0 + erf_a) + (K * exp_a2));
    float _2218;
    if (K > 0.0)
    {
        _2218 = (0.5 - sqrt((K * ((K - y_approx) + 1.0)) + 0.25)) / K;
    }
    else
    {
        _2218 = y_approx - 1.0;
    }
    float b = _2218;
    float param_1 = b;
    float inv_erf = fast_ierff(param_1);
    float value = ((1.0 + b) + (K * exp((-inv_erf) * inv_erf))) - y_exact;
    if (abs(value) > 9.9999999747524270787835121154785e-07)
    {
        b -= (value / (1.0 - (inv_erf * tan_theta_i)));
        float param_2 = b;
        inv_erf = fast_ierff(param_2);
        value = ((1.0 + b) + (K * exp((-inv_erf) * inv_erf))) - y_exact;
        b -= (value / (1.0 - (inv_erf * tan_theta_i)));
        float param_3 = b;
        slope_x = fast_ierff(param_3);
    }
    else
    {
        slope_x = inv_erf;
    }
    float param_4 = (2.0 * randv) - 1.0;
    slope_y = fast_ierff(param_4);
}

void microfacet_ggx_sample_slopes(float cos_theta_i, float sin_theta_i, float randu, inout float randv, inout float slope_x, out float slope_y, out float G1i)
{
    if (cos_theta_i >= 0.999989986419677734375)
    {
        float r = sqrt(randu / (1.0 - randu));
        float phi = 6.283185482025146484375 * randv;
        slope_x = r * cos(phi);
        slope_y = r * sin(phi);
        G1i = 1.0;
        return;
    }
    float tan_theta_i = sin_theta_i / cos_theta_i;
    float param = 1.0 + (tan_theta_i * tan_theta_i);
    float G1_inv = 0.5 * (1.0 + safe_sqrtf(param));
    G1i = 1.0 / G1_inv;
    float A_1 = ((2.0 * randu) * G1_inv) - 1.0;
    float AA = A_1 * A_1;
    float tmp = 1.0 / (AA - 1.0);
    float B_1 = tan_theta_i;
    float BB = B_1 * B_1;
    float param_1 = (BB * (tmp * tmp)) - ((AA - BB) * tmp);
    float D = safe_sqrtf(param_1);
    float slope_x_1 = (B_1 * tmp) - D;
    float slope_x_2 = (B_1 * tmp) + D;
    bool _2382 = A_1 < 0.0;
    bool _2390;
    if (!_2382)
    {
        _2390 = (slope_x_2 * tan_theta_i) > 1.0;
    }
    else
    {
        _2390 = _2382;
    }
    slope_x = _2390 ? slope_x_1 : slope_x_2;
    float S;
    if (randv > 0.5)
    {
        S = 1.0;
        randv = 2.0 * (randv - 0.5);
    }
    else
    {
        S = -1.0;
        randv = 2.0 * (0.5 - randv);
    }
    float z = (randv * ((randv * ((randv * 0.2738499939441680908203125) - 0.7336900234222412109375)) + 0.4634099900722503662109375)) / ((randv * ((randv * ((randv * 0.093073002994060516357421875) + 0.30941998958587646484375)) - 1.0)) + 0.59799897670745849609375);
    float param_2 = 1.0 + (slope_x * slope_x);
    slope_y = (S * z) * safe_sqrtf(param_2);
}

vec4 microfacet_sample_stretched(vec4 omega_i, float alpha_x, float alpha_y, float randu, float randv, bool beckmann, inout float G1i)
{
    vec4 omega_i_ = vec4(alpha_x * omega_i.x, alpha_y * omega_i.y, omega_i.z, 0.0);
    omega_i_ = normalize(omega_i_);
    float costheta_ = 1.0;
    float sintheta_ = 0.0;
    float cosphi_ = 1.0;
    float sinphi_ = 0.0;
    if (omega_i_.z < 0.999989986419677734375)
    {
        costheta_ = omega_i_.z;
        float param = 1.0 - (costheta_ * costheta_);
        sintheta_ = safe_sqrtf(param);
        float invlen = 1.0 / sintheta_;
        cosphi_ = omega_i_.x * invlen;
        sinphi_ = omega_i_.y * invlen;
    }
    float slope_x;
    float slope_y;
    if (beckmann)
    {
        float param_1 = randu;
        float param_2 = randv;
        float param_3 = slope_x;
        float param_4 = slope_y;
        float param_5 = G1i;
        microfacet_beckmann_sample_slopes(costheta_, sintheta_, param_1, param_2, param_3, param_4, param_5);
        slope_x = param_3;
        slope_y = param_4;
        G1i = param_5;
    }
    else
    {
        float param_6 = randu;
        float param_7 = randv;
        float param_8 = slope_x;
        float param_9 = slope_y;
        float param_10 = G1i;
        microfacet_ggx_sample_slopes(costheta_, sintheta_, param_6, param_7, param_8, param_9, param_10);
        slope_x = param_8;
        slope_y = param_9;
        G1i = param_10;
    }
    float tmp = (cosphi_ * slope_x) - (sinphi_ * slope_y);
    slope_y = (sinphi_ * slope_x) + (cosphi_ * slope_y);
    slope_x = tmp;
    slope_x = alpha_x * slope_x;
    slope_y = alpha_y * slope_y;
    return normalize(vec4(-slope_x, -slope_y, 1.0, 0.0));
}

int bsdf_microfacet_ggx_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    float alpha_x = sc.data[0];
    float alpha_y = sc.data[1];
    bool m_refractive = sc.type == 23u;
    vec4 N = sc.N;
    float cosNO = dot(N.xyz, I.xyz);
    int label;
    if (cosNO > 0.0)
    {
        vec4 Z = N;
        vec4 X;
        vec4 Y;
        if (alpha_x == alpha_y)
        {
            vec4 param = Z;
            vec4 param_1 = X;
            vec4 param_2;
            make_orthonormals(param, param_1, param_2);
            X = param_1;
            Y = param_2;
        }
        else
        {
            vec4 param_3 = X;
            vec4 param_4 = Y;
            make_orthonormals_tangent(Z, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param_3, param_4);
            X = param_3;
            Y = param_4;
        }
        vec4 local_I = vec4(dot(X.xyz, I.xyz), dot(Y.xyz, I.xyz), cosNO, 0.0);
        bool param_5 = false;
        float G1o;
        float param_6 = G1o;
        vec4 _3242 = microfacet_sample_stretched(local_I, alpha_x, alpha_y, randu, randv, param_5, param_6);
        G1o = param_6;
        vec4 local_m = _3242;
        vec4 m = ((X * local_m.x) + (Y * local_m.y)) + (Z * local_m.z);
        float cosThetaM = local_m.z;
        if (!m_refractive)
        {
            float cosMO = dot(m.xyz, I.xyz);
            label = 10;
            if (cosMO > 0.0)
            {
                omega_in = (m * (2.0 * cosMO)) - I;
                if (dot(Ng, omega_in) > 0.0)
                {
                    if ((alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07)
                    {
                        pdf = 1000000.0;
                        eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
                        bool _3301 = sc.type == 11u;
                        bool _3308;
                        if (!_3301)
                        {
                            _3308 = sc.type == 12u;
                        }
                        else
                        {
                            _3308 = _3301;
                        }
                        bool use_fresnel = _3308;
                        if (use_fresnel)
                        {
                            vec4 param_7 = omega_in;
                            vec4 param_8 = m;
                            eval *= reflection_color(param_7, param_8);
                        }
                        label = 18;
                    }
                    else
                    {
                        float alpha2 = alpha_x * alpha_y;
                        float D;
                        float G1i;
                        if (alpha_x == alpha_y)
                        {
                            float cosThetaM2 = cosThetaM * cosThetaM;
                            float cosThetaM4 = cosThetaM2 * cosThetaM2;
                            float tanThetaM2 = (1.0 / cosThetaM2) - 1.0;
                            float cosNI = dot(N.xyz, omega_in.xyz);
                            if (sc.type == 12u)
                            {
                                float param_9 = cosThetaM;
                                float param_10 = sc.data[0];
                                D = D_GTR1(param_9, param_10);
                                alpha2 = 0.0625;
                                float param_11 = 1.0 + ((alpha2 * (1.0 - (cosNO * cosNO))) / (cosNO * cosNO));
                                G1o = 2.0 / (1.0 + safe_sqrtf(param_11));
                            }
                            else
                            {
                                D = alpha2 / (((3.1415927410125732421875 * cosThetaM4) * (alpha2 + tanThetaM2)) * (alpha2 + tanThetaM2));
                            }
                            float param_12 = 1.0 + ((alpha2 * (1.0 - (cosNI * cosNI))) / (cosNI * cosNI));
                            G1i = 2.0 / (1.0 + safe_sqrtf(param_12));
                        }
                        else
                        {
                            vec4 local_m_1 = vec4(dot(X.xyz, m.xyz), dot(Y.xyz, m.xyz), dot(Z.xyz, m.xyz), 0.0);
                            float slope_x = (-local_m_1.x) / (local_m_1.z * alpha_x);
                            float slope_y = (-local_m_1.y) / (local_m_1.z * alpha_y);
                            float slope_len = (1.0 + (slope_x * slope_x)) + (slope_y * slope_y);
                            float cosThetaM_1 = local_m_1.z;
                            float cosThetaM2_1 = cosThetaM_1 * cosThetaM_1;
                            float cosThetaM4_1 = cosThetaM2_1 * cosThetaM2_1;
                            D = 1.0 / ((((slope_len * slope_len) * 3.1415927410125732421875) * alpha2) * cosThetaM4_1);
                            float cosNI_1 = dot(N.xyz, omega_in.xyz);
                            float tanThetaI2 = (1.0 - (cosNI_1 * cosNI_1)) / (cosNI_1 * cosNI_1);
                            float cosPhiI = dot(omega_in.xyz, X.xyz);
                            float sinPhiI = dot(omega_in.xyz, Y.xyz);
                            float alphaI2 = ((cosPhiI * cosPhiI) * (alpha_x * alpha_x)) + ((sinPhiI * sinPhiI) * (alpha_y * alpha_y));
                            alphaI2 /= ((cosPhiI * cosPhiI) + (sinPhiI * sinPhiI));
                            float param_13 = 1.0 + (alphaI2 * tanThetaI2);
                            G1i = 2.0 / (1.0 + safe_sqrtf(param_13));
                        }
                        float common_rsv = ((G1o * D) * 0.25) / cosNO;
                        pdf = common_rsv;
                        vec4 param_14 = omega_in;
                        vec4 param_15 = m;
                        vec4 F = reflection_color(param_14, param_15);
                        eval = F * (G1i * common_rsv);
                    }
                    if (sc.type == 12u)
                    {
                        eval *= (0.25 * sc.data[12]);
                    }
                    domega_in_dx = (m * (2.0 * dot(m.xyz, dIdx.xyz))) - dIdx;
                    domega_in_dy = (m * (2.0 * dot(m.xyz, dIdy.xyz))) - dIdy;
                }
            }
        }
        else
        {
            label = 9;
            float m_eta = sc.data[2];
            float param_16 = m_eta;
            vec4 R;
            vec4 param_17 = R;
            vec4 T;
            vec4 param_18 = T;
            vec4 dRdx;
            vec4 param_19 = dRdx;
            vec4 dRdy;
            vec4 param_20 = dRdy;
            vec4 dTdx;
            vec4 param_21 = dTdx;
            vec4 dTdy;
            vec4 param_22 = dTdy;
            bool inside;
            bool param_23 = inside;
            float _3611 = fresnel_dielectric(param_16, m, I, param_17, param_18, dIdx, dIdy, param_19, param_20, param_21, param_22, param_23);
            R = param_17;
            T = param_18;
            dRdx = param_19;
            dRdy = param_20;
            dTdx = param_21;
            dTdy = param_22;
            inside = param_23;
            float fresnel = _3611;
            if ((!inside) && (!(fresnel == 1.0)))
            {
                omega_in = T;
                domega_in_dx = dTdx;
                domega_in_dy = dTdy;
                bool _3632 = (alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07;
                bool _3641;
                if (!_3632)
                {
                    _3641 = abs(m_eta - 1.0) < 9.9999997473787516355514526367188e-05;
                }
                else
                {
                    _3641 = _3632;
                }
                if (_3641)
                {
                    pdf = 1000000.0;
                    eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
                    label = 17;
                }
                else
                {
                    float alpha2_1 = alpha_x * alpha_y;
                    float cosThetaM2_2 = cosThetaM * cosThetaM;
                    float cosThetaM4_2 = cosThetaM2_2 * cosThetaM2_2;
                    float tanThetaM2_1 = (1.0 / cosThetaM2_2) - 1.0;
                    float D_1 = alpha2_1 / (((3.1415927410125732421875 * cosThetaM4_2) * (alpha2_1 + tanThetaM2_1)) * (alpha2_1 + tanThetaM2_1));
                    float cosNI_2 = dot(N.xyz, omega_in.xyz);
                    float param_24 = 1.0 + ((alpha2_1 * (1.0 - (cosNI_2 * cosNI_2))) / (cosNI_2 * cosNI_2));
                    float G1i_1 = 2.0 / (1.0 + safe_sqrtf(param_24));
                    float cosHI = dot(m.xyz, omega_in.xyz);
                    float cosHO = dot(m.xyz, I.xyz);
                    float Ht2 = (m_eta * cosHI) + cosHO;
                    Ht2 *= Ht2;
                    float common_rsv_1 = ((G1o * D_1) * (m_eta * m_eta)) / (cosNO * Ht2);
                    float out_rsv = (G1i_1 * abs(cosHI * cosHO)) * common_rsv_1;
                    pdf = (cosHO * abs(cosHI)) * common_rsv_1;
                    eval = vec4(out_rsv, out_rsv, out_rsv, 0.0);
                }
            }
        }
    }
    else
    {
        label = m_refractive ? 9 : 10;
    }
    return label;
}

int bsdf_microfacet_beckmann_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    float alpha_x = sc.data[0];
    float alpha_y = sc.data[1];
    bool m_refractive = sc.type == 22u;
    vec4 N = sc.N;
    float cosNO = dot(N.xyz, I.xyz);
    int label;
    if (cosNO > 0.0)
    {
        vec4 Z = N;
        vec4 X;
        vec4 Y;
        if (alpha_x == alpha_y)
        {
            vec4 param = Z;
            vec4 param_1 = X;
            vec4 param_2;
            make_orthonormals(param, param_1, param_2);
            X = param_1;
            Y = param_2;
        }
        else
        {
            vec4 param_3 = X;
            vec4 param_4 = Y;
            make_orthonormals_tangent(Z, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param_3, param_4);
            X = param_3;
            Y = param_4;
        }
        vec4 local_I = vec4(dot(X.xyz, I.xyz), dot(Y.xyz, I.xyz), cosNO, 0.0);
        bool param_5 = true;
        float G1o;
        float param_6 = G1o;
        vec4 _4330 = microfacet_sample_stretched(local_I, alpha_x, alpha_x, randu, randv, param_5, param_6);
        G1o = param_6;
        vec4 local_m = _4330;
        vec4 m = ((X * local_m.x) + (Y * local_m.y)) + (Z * local_m.z);
        float cosThetaM = local_m.z;
        if (!m_refractive)
        {
            label = 10;
            float cosMO = dot(m.xyz, I.xyz);
            if (cosMO > 0.0)
            {
                omega_in = (m * (2.0 * cosMO)) - I;
                if (dot(Ng.xyz, omega_in.xyz) > 0.0)
                {
                    if ((alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07)
                    {
                        pdf = 1000000.0;
                        eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
                        label = 18;
                    }
                    else
                    {
                        float alpha2 = alpha_x * alpha_y;
                        float D;
                        float G1i;
                        if (alpha_x == alpha_y)
                        {
                            float cosThetaM2 = cosThetaM * cosThetaM;
                            float cosThetaM4 = cosThetaM2 * cosThetaM2;
                            float tanThetaM2 = (1.0 / cosThetaM2) - 1.0;
                            D = exp((-tanThetaM2) / alpha2) / ((3.1415927410125732421875 * alpha2) * cosThetaM4);
                            float cosNI = dot(N.xyz, omega_in.xyz);
                            float param_7 = alpha_x;
                            float param_8 = cosNI;
                            float _4429 = bsdf_beckmann_G1(param_7, param_8);
                            G1i = _4429;
                        }
                        else
                        {
                            vec4 local_m_1 = vec4(dot(X.xyz, m.xyz), dot(Y.xyz, m.xyz), dot(Z.xyz, m.xyz), 0.0);
                            float slope_x = (-local_m_1.x) / (local_m_1.z * alpha_x);
                            float slope_y = (-local_m_1.y) / (local_m_1.z * alpha_y);
                            float cosThetaM_1 = local_m_1.z;
                            float cosThetaM2_1 = cosThetaM_1 * cosThetaM_1;
                            float cosThetaM4_1 = cosThetaM2_1 * cosThetaM2_1;
                            D = exp(((-slope_x) * slope_x) - (slope_y * slope_y)) / ((3.1415927410125732421875 * alpha2) * cosThetaM4_1);
                            float param_9 = alpha_x;
                            float param_10 = alpha_y;
                            float param_11 = dot(omega_in.xyz, N.xyz);
                            float param_12 = dot(omega_in.xyz, X.xyz);
                            float param_13 = dot(omega_in.xyz, Y.xyz);
                            float _4513 = bsdf_beckmann_aniso_G1(param_9, param_10, param_11, param_12, param_13);
                            G1i = _4513;
                        }
                        float G = G1o * G1i;
                        float common_rsv = (D * 0.25) / cosNO;
                        float out_rsv = G * common_rsv;
                        pdf = G1o * common_rsv;
                        eval = vec4(out_rsv, out_rsv, out_rsv, 0.0);
                    }
                    domega_in_dx = (m * (2.0 * dot(m.xyz, dIdx.xyz))) - dIdx;
                    domega_in_dy = (m * (2.0 * dot(m.xyz, dIdy.xyz))) - dIdy;
                }
            }
        }
        else
        {
            label = 9;
            float m_eta = sc.data[2];
            float param_14 = m_eta;
            vec4 R;
            vec4 param_15 = R;
            vec4 T;
            vec4 param_16 = T;
            vec4 dRdx;
            vec4 param_17 = dRdx;
            vec4 dRdy;
            vec4 param_18 = dRdy;
            vec4 dTdx;
            vec4 param_19 = dTdx;
            vec4 dTdy;
            vec4 param_20 = dTdy;
            bool inside;
            bool param_21 = inside;
            float _4586 = fresnel_dielectric(param_14, m, I, param_15, param_16, dIdx, dIdy, param_17, param_18, param_19, param_20, param_21);
            R = param_15;
            T = param_16;
            dRdx = param_17;
            dRdy = param_18;
            dTdx = param_19;
            dTdy = param_20;
            inside = param_21;
            float fresnel = _4586;
            if ((!inside) && (!(fresnel == 1.0)))
            {
                omega_in = T;
                domega_in_dx = dTdx;
                domega_in_dy = dTdy;
                bool _4607 = (alpha_x * alpha_y) <= 1.0000000116860974230803549289703e-07;
                bool _4615;
                if (!_4607)
                {
                    _4615 = abs(m_eta - 1.0) < 9.9999997473787516355514526367188e-05;
                }
                else
                {
                    _4615 = _4607;
                }
                if (_4615)
                {
                    pdf = 1000000.0;
                    eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
                    label = 17;
                }
                else
                {
                    float alpha2_1 = alpha_x * alpha_y;
                    float cosThetaM2_2 = cosThetaM * cosThetaM;
                    float cosThetaM4_2 = cosThetaM2_2 * cosThetaM2_2;
                    float tanThetaM2_1 = (1.0 / cosThetaM2_2) - 1.0;
                    float D_1 = exp((-tanThetaM2_1) / alpha2_1) / ((3.1415927410125732421875 * alpha2_1) * cosThetaM4_2);
                    float cosNI_1 = dot(N.xyz, omega_in.xyz);
                    float param_22 = alpha_x;
                    float param_23 = cosNI_1;
                    float _4657 = bsdf_beckmann_G1(param_22, param_23);
                    float G1i_1 = _4657;
                    float G_1 = G1o * G1i_1;
                    float cosHI = dot(m.xyz, omega_in.xyz);
                    float cosHO = dot(m.xyz, I.xyz);
                    float Ht2 = (m_eta * cosHI) + cosHO;
                    Ht2 *= Ht2;
                    float common_rsv_1 = (D_1 * (m_eta * m_eta)) / (cosNO * Ht2);
                    float out_rsv_1 = (G_1 * abs(cosHI * cosHO)) * common_rsv_1;
                    pdf = ((G1o * cosHO) * abs(cosHI)) * common_rsv_1;
                    eval = vec4(out_rsv_1, out_rsv_1, out_rsv_1, 0.0);
                }
            }
        }
    }
    else
    {
        label = m_refractive ? 9 : 10;
    }
    return label;
}

int bsdf_reflection_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    vec4 N = sc.N;
    float cosNO = dot(N, I);
    if (cosNO > 0.0)
    {
        omega_in = (N * (2.0 * cosNO)) - I;
        if (dot(Ng, omega_in) > 0.0)
        {
            domega_in_dx = (N * (2.0 * dot(N, dIdx))) - dIdx;
            domega_in_dy = (N * (2.0 * dot(N, dIdy))) - dIdy;
            pdf = 1000000.0;
            eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
        }
    }
    return 18;
}

vec4 mf_sample_glossy(vec4 wi, inout vec4 wo, vec4 color, float alpha_x, float alpha_y, inout uint lcg_state, float eta, bool use_fresnel, vec4 cspec0)
{
    vec2 alpha = vec2(alpha_x, alpha_y);
    vec4 throughput = vec4(1.0, 1.0, 1.0, 0.0);
    vec4 wr = -wi;
    float lambda_r = mf_lambda(wr, alpha);
    float hr = 1.0;
    float C1_r = 1.0;
    float G1_r = 0.0;
    bool outside = true;
    float param = 1.0;
    float param_1 = eta;
    float F0 = fresnel_dielectric_cos(param, param_1);
    if (use_fresnel)
    {
        vec4 param_2 = wi;
        vec4 param_3 = vec4(normalize((wi + wr).xyz), 0.0);
        float param_4 = eta;
        float param_5 = F0;
        vec4 param_6 = cspec0;
        throughput = interpolate_fresnel_color(param_2, param_3, param_4, param_5, param_6);
    }
    vec4 _6764;
    for (int order = 0; order < 10; order++)
    {
        uint param_7 = lcg_state;
        float _6743 = lcg_step_float_addrspace(param_7);
        lcg_state = param_7;
        float height_rand = _6743;
        float param_8 = hr;
        float param_9 = C1_r;
        float param_10 = G1_r;
        float param_11 = lambda_r;
        bool _6755 = mf_sample_height(wr, param_8, param_9, param_10, param_11, height_rand);
        hr = param_8;
        C1_r = param_9;
        G1_r = param_10;
        lambda_r = param_11;
        if (!_6755)
        {
            if (outside)
            {
                _6764 = wr;
            }
            else
            {
                _6764 = -wr;
            }
            wo = _6764;
            return throughput;
        }
        uint param_12 = lcg_state;
        float _6777 = lcg_step_float_addrspace(param_12);
        lcg_state = param_12;
        float vndf_rand_y = _6777;
        uint param_13 = lcg_state;
        float _6782 = lcg_step_float_addrspace(param_13);
        lcg_state = param_13;
        float vndf_rand_x = _6782;
        vec4 wm = mf_sample_vndf(-wr, alpha, vndf_rand_x, vndf_rand_y);
        if ((!use_fresnel) && (order > 0))
        {
            throughput *= color;
        }
        if (use_fresnel)
        {
            vec4 param_14 = -wr;
            vec4 param_15 = wm;
            float param_16 = eta;
            float param_17 = F0;
            vec4 param_18 = cspec0;
            vec4 t_color = interpolate_fresnel_color(param_14, param_15, param_16, param_17, param_18);
            if (order == 0)
            {
                throughput = t_color;
            }
            else
            {
                throughput *= t_color;
            }
        }
        vec4 param_19 = throughput;
        throughput = param_19;
        wr = mf_sample_phase_glossy(-wr, param_19, wm);
        lambda_r = mf_lambda(wr, alpha);
        G1_r = mf_G1(wr, C1_r, lambda_r);
    }
    wo = vec4(0.0, 0.0, 1.0, 0.0);
    return vec4(0.0);
}

int bsdf_microfacet_multi_ggx_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, out vec4 omega_in, out vec4 domega_in_dx, out vec4 domega_in_dy, inout float pdf, inout uint lcg_state)
{
    vec4 Z = sc.N;
    if ((sc.data[0] * sc.data[1]) < 1.0000000116860974230803549289703e-07)
    {
        omega_in = (Z * (2.0 * dot(Z.xyz, I.xyz))) - I;
        pdf = 1000000.0;
        eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
        domega_in_dx = (Z * (2.0 * dot(Z.xyz, dIdx.xyz))) - dIdx;
        domega_in_dy = (Z * (2.0 * dot(Z.xyz, dIdy.xyz))) - dIdy;
        return 18;
    }
    bool use_fresnel = sc.type == 15u;
    bool is_aniso = !(sc.data[0] == sc.data[1]);
    vec4 X;
    vec4 Y;
    if (is_aniso)
    {
        vec4 param = X;
        vec4 param_1 = Y;
        make_orthonormals_tangent(Z, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param, param_1);
        X = param;
        Y = param_1;
    }
    else
    {
        vec4 param_2 = Z;
        vec4 param_3 = X;
        vec4 param_4;
        make_orthonormals(param_2, param_3, param_4);
        X = param_3;
        Y = param_4;
    }
    vec4 localI = vec4(dot(I.xyz, X.xyz), dot(I.xyz, Y.xyz), dot(I.xyz, Z.xyz), 0.0);
    vec4 param_5 = localI;
    vec4 localO;
    vec4 param_6 = localO;
    uint param_7 = lcg_state;
    bool param_8 = use_fresnel;
    vec4 _7099 = mf_sample_glossy(param_5, param_6, vec4(sc.data[3], sc.data[4], sc.data[5], 0.0), sc.data[0], sc.data[1], param_7, sc.data[2], param_8, vec4(sc.data[6], sc.data[7], sc.data[8], 0.0));
    localO = param_6;
    lcg_state = param_7;
    eval = _7099;
    if (is_aniso)
    {
        pdf = mf_ggx_aniso_pdf(localI, localO, vec2(sc.data[0], sc.data[1]));
    }
    else
    {
        pdf = mf_ggx_pdf(localI, localO, sc.data[0]);
    }
    eval *= pdf;
    omega_in = ((X * localO.x) + (Y * localO.y)) + (Z * localO.z);
    domega_in_dx = (Z * (2.0 * dot(Z.xyz, dIdx.xyz))) - dIdx;
    domega_in_dy = (Z * (2.0 * dot(Z.xyz, dIdy.xyz))) - dIdy;
    return 10;
}

vec4 mf_sample_glass(vec4 wi, inout vec4 wo, vec4 color, float alpha_x, float alpha_y, inout uint lcg_state, float eta, bool use_fresnel, vec4 cspec0)
{
    vec2 alpha = vec2(alpha_x, alpha_y);
    vec4 throughput = vec4(1.0, 1.0, 1.0, 0.0);
    vec4 wr = -wi;
    float lambda_r = mf_lambda(wr, alpha);
    float hr = 1.0;
    float C1_r = 1.0;
    float G1_r = 0.0;
    bool outside = true;
    float param = 1.0;
    float param_1 = eta;
    float F0 = fresnel_dielectric_cos(param, param_1);
    if (use_fresnel)
    {
        vec4 param_2 = wi;
        vec4 param_3 = vec4(normalize((wi + wr).xyz), 0.0);
        float param_4 = eta;
        float param_5 = F0;
        vec4 param_6 = cspec0;
        throughput = interpolate_fresnel_color(param_2, param_3, param_4, param_5, param_6);
    }
    vec4 _6305;
    float _6352;
    bool next_outside;
    for (int order = 0; order < 10; order++)
    {
        uint param_7 = lcg_state;
        float _6284 = lcg_step_float_addrspace(param_7);
        lcg_state = param_7;
        float height_rand = _6284;
        float param_8 = hr;
        float param_9 = C1_r;
        float param_10 = G1_r;
        float param_11 = lambda_r;
        bool _6296 = mf_sample_height(wr, param_8, param_9, param_10, param_11, height_rand);
        hr = param_8;
        C1_r = param_9;
        G1_r = param_10;
        lambda_r = param_11;
        if (!_6296)
        {
            if (outside)
            {
                _6305 = wr;
            }
            else
            {
                _6305 = -wr;
            }
            wo = _6305;
            return throughput;
        }
        uint param_12 = lcg_state;
        float _6318 = lcg_step_float_addrspace(param_12);
        lcg_state = param_12;
        float vndf_rand_y = _6318;
        uint param_13 = lcg_state;
        float _6323 = lcg_step_float_addrspace(param_13);
        lcg_state = param_13;
        float vndf_rand_x = _6323;
        vec4 wm = mf_sample_vndf(-wr, alpha, vndf_rand_x, vndf_rand_y);
        if ((!use_fresnel) && (order > 0))
        {
            throughput *= color;
        }
        vec4 wi_prev = -wr;
        uint param_14 = lcg_state;
        float _6347 = lcg_step_float_addrspace(param_14);
        lcg_state = param_14;
        float phase_rand = _6347;
        if (outside)
        {
            _6352 = eta;
        }
        else
        {
            _6352 = 1.0 / eta;
        }
        bool param_15 = next_outside;
        vec4 _6363 = mf_sample_phase_glass(-wr, _6352, wm, phase_rand, param_15);
        next_outside = param_15;
        wr = _6363;
        if (!next_outside)
        {
            hr = -hr;
            wr = -wr;
            outside = !outside;
        }
        if (use_fresnel)
        {
            if (!next_outside)
            {
                throughput *= color;
            }
            else
            {
                vec4 param_16 = wi_prev;
                vec4 param_17 = wm;
                float param_18 = eta;
                float param_19 = F0;
                vec4 param_20 = cspec0;
                vec4 t_color = interpolate_fresnel_color(param_16, param_17, param_18, param_19, param_20);
                if (order == 0)
                {
                    throughput = t_color;
                }
                else
                {
                    throughput *= t_color;
                }
            }
        }
        lambda_r = mf_lambda(wr, alpha);
        G1_r = mf_G1(wr, C1_r, lambda_r);
    }
    wo = vec4(0.0, 0.0, 1.0, 0.0);
    return vec4(0.0);
}

int bsdf_microfacet_multi_ggx_glass_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf, inout uint lcg_state)
{
    vec4 Z = sc.N;
    if ((sc.data[0] * sc.data[1]) < 1.0000000116860974230803549289703e-07)
    {
        float param = sc.data[2];
        vec4 R;
        vec4 param_1 = R;
        vec4 T;
        vec4 param_2 = T;
        vec4 dRdx;
        vec4 param_3 = dRdx;
        vec4 dRdy;
        vec4 param_4 = dRdy;
        vec4 dTdx;
        vec4 param_5 = dTdx;
        vec4 dTdy;
        vec4 param_6 = dTdy;
        bool inside;
        bool param_7 = inside;
        float _7392 = fresnel_dielectric(param, Z, I, param_1, param_2, dIdx, dIdy, param_3, param_4, param_5, param_6, param_7);
        R = param_1;
        T = param_2;
        dRdx = param_3;
        dRdy = param_4;
        dTdx = param_5;
        dTdy = param_6;
        inside = param_7;
        float fresnel = _7392;
        pdf = 1000000.0;
        eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
        if (randu < fresnel)
        {
            omega_in = R;
            domega_in_dx = dRdx;
            domega_in_dy = dRdy;
            return 18;
        }
        else
        {
            omega_in = T;
            domega_in_dx = dTdx;
            domega_in_dy = dTdy;
            return 17;
        }
    }
    bool use_fresnel = sc.type == 27u;
    vec4 param_8 = Z;
    vec4 X;
    vec4 param_9 = X;
    vec4 param_10;
    make_orthonormals(param_8, param_9, param_10);
    X = param_9;
    vec4 Y = param_10;
    vec4 localI = vec4(dot(I.xyz, X.xyz), dot(I.xyz, Y.xyz), dot(I.xyz, Z.xyz), 0.0);
    vec4 param_11 = localI;
    vec4 localO;
    vec4 param_12 = localO;
    uint param_13 = lcg_state;
    bool param_14 = use_fresnel;
    vec4 _7474 = mf_sample_glass(param_11, param_12, vec4(sc.data[3], sc.data[4], sc.data[5], 0.0), sc.data[0], sc.data[1], param_13, sc.data[2], param_14, vec4(sc.data[6], sc.data[7], sc.data[8], 0.0));
    localO = param_12;
    lcg_state = param_13;
    eval = _7474;
    pdf = mf_glass_pdf(localI, localO, sc.data[0], sc.data[2]);
    eval *= pdf;
    omega_in = ((X * localO.x) + (Y * localO.y)) + (Z * localO.z);
    if ((localO.z * localI.z) > 0.0)
    {
        domega_in_dx = (Z * (2.0 * dot(Z.xyz, dIdx.xyz))) - dIdx;
        domega_in_dy = (Z * (2.0 * dot(Z.xyz, dIdy.xyz))) - dIdy;
        return 10;
    }
    else
    {
        float cosI = dot(Z.xyz, I.xyz);
        float dnp = max(sqrt(1.0 - ((sc.data[2] * sc.data[2]) * (1.0 - (cosI * cosI)))), 1.0000000116860974230803549289703e-07);
        domega_in_dx = (-(dIdx * sc.data[2])) + (Z * ((sc.data[2] - (((sc.data[2] * sc.data[2]) * cosI) / dnp)) * dot(dIdx.xyz, Z.xyz)));
        domega_in_dy = (-(dIdy * sc.data[2])) + (Z * ((sc.data[2] - (((sc.data[2] * sc.data[2]) * cosI) / dnp)) * dot(dIdy.xyz, Z.xyz)));
        return 9;
    }
}

void bsdf_ashikhmin_shirley_sample_first_quadrant(float n_x, float n_y, float randu, float randv, inout float phi, out float cos_theta)
{
    phi = atan(sqrt((n_x + 1.0) / (n_y + 1.0)) * tan(1.57079637050628662109375 * randu));
    float cos_phi = cos(phi);
    float sin_phi = sin(phi);
    cos_theta = pow(randv, 1.0 / ((((n_x * cos_phi) * cos_phi) + ((n_y * sin_phi) * sin_phi)) + 1.0));
}

int bsdf_ashikhmin_shirley_sample(vec4 Ng, vec4 I, vec4 dIdx, vec4 dIdy, float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout vec4 domega_in_dx, inout vec4 domega_in_dy, inout float pdf)
{
    vec4 N = sc.N;
    int label = 10;
    float NdotI = dot(N, I);
    if (NdotI > 0.0)
    {
        float param = sc.data[0];
        float n_x = bsdf_ashikhmin_shirley_roughness_to_exponent(param);
        float param_1 = sc.data[1];
        float n_y = bsdf_ashikhmin_shirley_roughness_to_exponent(param_1);
        vec4 X;
        vec4 Y;
        if (n_x == n_y)
        {
            vec4 param_2 = N;
            vec4 param_3 = X;
            vec4 param_4;
            make_orthonormals(param_2, param_3, param_4);
            X = param_3;
            Y = param_4;
        }
        else
        {
            vec4 param_5 = X;
            vec4 param_6 = Y;
            make_orthonormals_tangent(N, vec4(sc.data[13], sc.data[14], sc.data[15], 0.0), param_5, param_6);
            X = param_5;
            Y = param_6;
        }
        float phi;
        float cos_theta;
        if (n_x == n_y)
        {
            phi = 6.283185482025146484375 * randu;
            cos_theta = pow(randv, 1.0 / (n_x + 1.0));
        }
        else
        {
            if (randu < 0.25)
            {
                float remapped_randu = 4.0 * randu;
                float param_7 = n_x;
                float param_8 = n_y;
                float param_9 = remapped_randu;
                float param_10 = randv;
                float param_11 = phi;
                float param_12 = cos_theta;
                bsdf_ashikhmin_shirley_sample_first_quadrant(param_7, param_8, param_9, param_10, param_11, param_12);
                phi = param_11;
                cos_theta = param_12;
            }
            else
            {
                if (randu < 0.5)
                {
                    float remapped_randu_1 = 4.0 * (0.5 - randu);
                    float param_13 = n_x;
                    float param_14 = n_y;
                    float param_15 = remapped_randu_1;
                    float param_16 = randv;
                    float param_17 = phi;
                    float param_18 = cos_theta;
                    bsdf_ashikhmin_shirley_sample_first_quadrant(param_13, param_14, param_15, param_16, param_17, param_18);
                    phi = param_17;
                    cos_theta = param_18;
                    phi = 3.1415927410125732421875 - phi;
                }
                else
                {
                    if (randu < 0.75)
                    {
                        float remapped_randu_2 = 4.0 * (randu - 0.5);
                        float param_19 = n_x;
                        float param_20 = n_y;
                        float param_21 = remapped_randu_2;
                        float param_22 = randv;
                        float param_23 = phi;
                        float param_24 = cos_theta;
                        bsdf_ashikhmin_shirley_sample_first_quadrant(param_19, param_20, param_21, param_22, param_23, param_24);
                        phi = param_23;
                        cos_theta = param_24;
                        phi = 3.1415927410125732421875 + phi;
                    }
                    else
                    {
                        float remapped_randu_3 = 4.0 * (1.0 - randu);
                        float param_25 = n_x;
                        float param_26 = n_y;
                        float param_27 = remapped_randu_3;
                        float param_28 = randv;
                        float param_29 = phi;
                        float param_30 = cos_theta;
                        bsdf_ashikhmin_shirley_sample_first_quadrant(param_25, param_26, param_27, param_28, param_29, param_30);
                        phi = param_29;
                        cos_theta = param_30;
                        phi = 6.283185482025146484375 - phi;
                    }
                }
            }
        }
        float sin_theta = sqrt(max(0.0, 1.0 - (cos_theta * cos_theta)));
        float cos_phi = cos(phi);
        float sin_phi = sin(phi);
        vec4 h = vec4(sin_theta * cos_phi, sin_theta * sin_phi, cos_theta, 0.0);
        vec4 H = ((X * h.x) + (Y * h.y)) + (N * h.z);
        float HdotI = dot(H, I);
        if (HdotI < 0.0)
        {
            H = -H;
        }
        omega_in = (-I) + (H * (2.0 * HdotI));
        if (max(sc.data[0], sc.data[1]) <= 9.9999997473787516355514526367188e-05)
        {
            pdf = 1000000.0;
            eval = vec4(1000000.0, 1000000.0, 1000000.0, 0.0);
            label = 18;
        }
        else
        {
            float param_31 = pdf;
            vec4 _8046 = bsdf_ashikhmin_shirley_eval_reflect(I, omega_in, param_31);
            pdf = param_31;
            eval = _8046;
        }
        domega_in_dx = (N * (2.0 * dot(N, dIdx))) - dIdx;
        domega_in_dy = (N * (2.0 * dot(N, dIdy))) - dIdy;
    }
    return label;
}

float bsdf_get_specular_roughness_squared(ShaderClosure sc_1)
{
    bool _9129 = sc_1.type == 9u;
    bool _9136;
    if (!_9129)
    {
        _9136 = sc_1.type == 21u;
    }
    else
    {
        _9136 = _9129;
    }
    bool _9143;
    if (!_9136)
    {
        _9143 = sc_1.type == 33u;
    }
    else
    {
        _9143 = _9136;
    }
    if (_9143)
    {
        return 0.0;
    }
    bool _9150 = sc_1.type >= 10u;
    bool _9157;
    if (_9150)
    {
        _9157 = sc_1.type <= 16u;
    }
    else
    {
        _9157 = _9150;
    }
    bool _9171;
    if (!_9157)
    {
        bool _9163 = sc_1.type >= 22u;
        bool _9170;
        if (_9163)
        {
            _9170 = sc_1.type <= 24u;
        }
        else
        {
            _9170 = _9163;
        }
        _9171 = _9170;
    }
    else
    {
        _9171 = _9157;
    }
    bool _9178;
    if (!_9171)
    {
        _9178 = sc_1.type == 27u;
    }
    else
    {
        _9178 = _9171;
    }
    if (_9178)
    {
        return sc_1.data[0] * sc_1.data[1];
    }
    return 1.0;
}

int bsdf_sample(float randu, float randv, inout vec4 eval, inout vec4 omega_in, inout differential3 domega_in, inout float pdf)
{
    vec4 _9857;
    if ((uint(arg.sd.type) & 60u) != 0u)
    {
        _9857 = sc.N;
    }
    else
    {
        _9857 = arg.sd.Ng;
    }
    vec4 Ng = _9857;
    uint lcg_state = arg.sd.lcg_state;
    int label;
    switch (sc.type)
    {
        case 2u:
        case 31u:
        {
            vec4 param = Ng;
            vec4 param_1 = arg.sd.I;
            vec4 param_2 = arg.sd.dI.dx;
            vec4 param_3 = arg.sd.dI.dy;
            float param_4 = randu;
            float param_5 = randv;
            vec4 param_6 = eval;
            vec4 param_7 = omega_in;
            vec4 param_8 = domega_in.dx;
            vec4 param_9 = domega_in.dy;
            float param_10 = pdf;
            int _9915 = bsdf_diffuse_sample(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, param_10);
            eval = param_6;
            omega_in = param_7;
            domega_in.dx = param_8;
            domega_in.dy = param_9;
            pdf = param_10;
            label = _9915;
            break;
        }
        case 3u:
        {
            vec4 param_11 = Ng;
            vec4 param_12 = arg.sd.I;
            vec4 param_13 = arg.sd.dI.dx;
            vec4 param_14 = arg.sd.dI.dy;
            float param_15 = randu;
            float param_16 = randv;
            vec4 param_17 = eval;
            vec4 param_18 = omega_in;
            vec4 param_19 = domega_in.dx;
            vec4 param_20 = domega_in.dy;
            float param_21 = pdf;
            int _9951 = bsdf_oren_nayar_sample(param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21);
            eval = param_17;
            omega_in = param_18;
            domega_in.dx = param_19;
            domega_in.dy = param_20;
            pdf = param_21;
            label = _9951;
            break;
        }
        case 7u:
        {
            vec4 param_22 = Ng;
            vec4 param_23 = arg.sd.I;
            vec4 param_24 = arg.sd.dI.dx;
            vec4 param_25 = arg.sd.dI.dy;
            float param_26 = randu;
            float param_27 = randv;
            vec4 param_28 = eval;
            vec4 param_29 = omega_in;
            vec4 param_30 = domega_in.dx;
            vec4 param_31 = domega_in.dy;
            float param_32 = pdf;
            int _9987 = bsdf_diffuse_toon_sample(param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32);
            eval = param_28;
            omega_in = param_29;
            domega_in.dx = param_30;
            domega_in.dy = param_31;
            pdf = param_32;
            label = _9987;
            break;
        }
        case 19u:
        {
            vec4 param_33 = Ng;
            vec4 param_34 = arg.sd.I;
            vec4 param_35 = arg.sd.dI.dx;
            vec4 param_36 = arg.sd.dI.dy;
            float param_37 = randu;
            float param_38 = randv;
            vec4 param_39 = eval;
            vec4 param_40 = omega_in;
            vec4 param_41 = domega_in.dx;
            vec4 param_42 = domega_in.dy;
            float param_43 = pdf;
            int _10023 = bsdf_glossy_toon_sample(param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41, param_42, param_43);
            eval = param_39;
            omega_in = param_40;
            domega_in.dx = param_41;
            domega_in.dy = param_42;
            pdf = param_43;
            label = _10023;
            break;
        }
        case 8u:
        {
            vec4 param_44 = Ng;
            vec4 param_45 = arg.sd.I;
            vec4 param_46 = arg.sd.dI.dx;
            vec4 param_47 = arg.sd.dI.dy;
            float param_48 = randu;
            float param_49 = randv;
            vec4 param_50 = eval;
            vec4 param_51 = omega_in;
            vec4 param_52 = domega_in.dx;
            vec4 param_53 = domega_in.dy;
            float param_54 = pdf;
            int _10059 = bsdf_translucent_sample(param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54);
            eval = param_50;
            omega_in = param_51;
            domega_in.dx = param_52;
            domega_in.dy = param_53;
            pdf = param_54;
            label = _10059;
            break;
        }
        case 33u:
        {
            vec4 param_55 = Ng;
            vec4 param_56 = arg.sd.I;
            vec4 param_57 = arg.sd.dI.dx;
            vec4 param_58 = arg.sd.dI.dy;
            float param_59 = randu;
            float param_60 = randv;
            vec4 param_61 = eval;
            vec4 param_62 = omega_in;
            vec4 param_63 = domega_in.dx;
            vec4 param_64 = domega_in.dy;
            float param_65 = pdf;
            int _10095 = bsdf_transparent_sample(param_55, param_56, param_57, param_58, param_59, param_60, param_61, param_62, param_63, param_64, param_65);
            eval = param_61;
            omega_in = param_62;
            domega_in.dx = param_63;
            domega_in.dy = param_64;
            pdf = param_65;
            label = _10095;
            break;
        }
        case 17u:
        {
            vec4 param_66 = Ng;
            vec4 param_67 = arg.sd.I;
            vec4 param_68 = arg.sd.dI.dx;
            vec4 param_69 = arg.sd.dI.dy;
            float param_70 = randu;
            float param_71 = randv;
            vec4 param_72 = eval;
            vec4 param_73 = omega_in;
            vec4 param_74 = domega_in.dx;
            vec4 param_75 = domega_in.dy;
            float param_76 = pdf;
            int _10131 = bsdf_ashikhmin_velvet_sample(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75, param_76);
            eval = param_72;
            omega_in = param_73;
            domega_in.dx = param_74;
            domega_in.dy = param_75;
            pdf = param_76;
            label = _10131;
            break;
        }
        case 21u:
        {
            vec4 param_77 = Ng;
            vec4 param_78 = arg.sd.I;
            vec4 param_79 = arg.sd.dI.dx;
            vec4 param_80 = arg.sd.dI.dy;
            float param_81 = randu;
            float param_82 = randv;
            vec4 param_83 = eval;
            vec4 param_84 = omega_in;
            vec4 param_85 = domega_in.dx;
            vec4 param_86 = domega_in.dy;
            float param_87 = pdf;
            int _10167 = bsdf_refraction_sample(param_77, param_78, param_79, param_80, param_81, param_82, param_83, param_84, param_85, param_86, param_87);
            eval = param_83;
            omega_in = param_84;
            domega_in.dx = param_85;
            domega_in.dy = param_86;
            pdf = param_87;
            label = _10167;
            break;
        }
        case 10u:
        case 11u:
        case 12u:
        case 23u:
        {
            vec4 param_88 = Ng;
            vec4 param_89 = arg.sd.I;
            vec4 param_90 = arg.sd.dI.dx;
            vec4 param_91 = arg.sd.dI.dy;
            float param_92 = randu;
            float param_93 = randv;
            vec4 param_94 = eval;
            vec4 param_95 = omega_in;
            vec4 param_96 = domega_in.dx;
            vec4 param_97 = domega_in.dy;
            float param_98 = pdf;
            int _10203 = bsdf_microfacet_ggx_sample(param_88, param_89, param_90, param_91, param_92, param_93, param_94, param_95, param_96, param_97, param_98);
            eval = param_94;
            omega_in = param_95;
            domega_in.dx = param_96;
            domega_in.dy = param_97;
            pdf = param_98;
            label = _10203;
            break;
        }
        case 13u:
        case 22u:
        {
            vec4 param_99 = Ng;
            vec4 param_100 = arg.sd.I;
            vec4 param_101 = arg.sd.dI.dx;
            vec4 param_102 = arg.sd.dI.dy;
            float param_103 = randu;
            float param_104 = randv;
            vec4 param_105 = eval;
            vec4 param_106 = omega_in;
            vec4 param_107 = domega_in.dx;
            vec4 param_108 = domega_in.dy;
            float param_109 = pdf;
            int _10239 = bsdf_microfacet_beckmann_sample(param_99, param_100, param_101, param_102, param_103, param_104, param_105, param_106, param_107, param_108, param_109);
            eval = param_105;
            omega_in = param_106;
            domega_in.dx = param_107;
            domega_in.dy = param_108;
            pdf = param_109;
            label = _10239;
            break;
        }
        case 9u:
        {
            vec4 param_110 = Ng;
            vec4 param_111 = arg.sd.I;
            vec4 param_112 = arg.sd.dI.dx;
            vec4 param_113 = arg.sd.dI.dy;
            float param_114 = randu;
            float param_115 = randv;
            vec4 param_116 = eval;
            vec4 param_117 = omega_in;
            vec4 param_118 = domega_in.dx;
            vec4 param_119 = domega_in.dy;
            float param_120 = pdf;
            int _10275 = bsdf_reflection_sample(param_110, param_111, param_112, param_113, param_114, param_115, param_116, param_117, param_118, param_119, param_120);
            eval = param_116;
            omega_in = param_117;
            domega_in.dx = param_118;
            domega_in.dy = param_119;
            pdf = param_120;
            label = _10275;
            break;
        }
        case 14u:
        case 15u:
        {
            vec4 param_121 = Ng;
            vec4 param_122 = arg.sd.I;
            vec4 param_123 = arg.sd.dI.dx;
            vec4 param_124 = arg.sd.dI.dy;
            float param_125 = randu;
            float param_126 = randv;
            vec4 param_127 = eval;
            vec4 param_128 = omega_in;
            vec4 param_129 = domega_in.dx;
            vec4 param_130 = domega_in.dy;
            float param_131 = pdf;
            uint param_132 = lcg_state;
            int _10313 = bsdf_microfacet_multi_ggx_sample(param_121, param_122, param_123, param_124, param_125, param_126, param_127, param_128, param_129, param_130, param_131, param_132);
            eval = param_127;
            omega_in = param_128;
            domega_in.dx = param_129;
            domega_in.dy = param_130;
            pdf = param_131;
            lcg_state = param_132;
            label = _10313;
            break;
        }
        case 24u:
        case 27u:
        {
            vec4 param_133 = Ng;
            vec4 param_134 = arg.sd.I;
            vec4 param_135 = arg.sd.dI.dx;
            vec4 param_136 = arg.sd.dI.dy;
            float param_137 = randu;
            float param_138 = randv;
            vec4 param_139 = eval;
            vec4 param_140 = omega_in;
            vec4 param_141 = domega_in.dx;
            vec4 param_142 = domega_in.dy;
            float param_143 = pdf;
            uint param_144 = lcg_state;
            int _10352 = bsdf_microfacet_multi_ggx_glass_sample(param_133, param_134, param_135, param_136, param_137, param_138, param_139, param_140, param_141, param_142, param_143, param_144);
            eval = param_139;
            omega_in = param_140;
            domega_in.dx = param_141;
            domega_in.dy = param_142;
            pdf = param_143;
            lcg_state = param_144;
            label = _10352;
            break;
        }
        case 16u:
        {
            vec4 param_145 = Ng;
            vec4 param_146 = arg.sd.I;
            vec4 param_147 = arg.sd.dI.dx;
            vec4 param_148 = arg.sd.dI.dy;
            float param_149 = randu;
            float param_150 = randv;
            vec4 param_151 = eval;
            vec4 param_152 = omega_in;
            vec4 param_153 = domega_in.dx;
            vec4 param_154 = domega_in.dy;
            float param_155 = pdf;
            int _10389 = bsdf_ashikhmin_shirley_sample(param_145, param_146, param_147, param_148, param_149, param_150, param_151, param_152, param_153, param_154, param_155);
            eval = param_151;
            omega_in = param_152;
            domega_in.dx = param_153;
            domega_in.dy = param_154;
            pdf = param_155;
            label = _10389;
            break;
        }
        default:
        {
            label = 0;
            break;
        }
    }
    if ((uint(label) & 1u) != 0u)
    {
        float threshold_squared = _8902.kernel_data.background.transparent_roughness_squared_threshold;
        if (threshold_squared >= 0.0)
        {
            ShaderClosure param_156 = sc;
            if (bsdf_get_specular_roughness_squared(param_156) <= threshold_squared)
            {
                label |= 128;
            }
        }
    }
    else
    {
        float frequency_multiplier = push.data_ptr._objects.data[arg.sd.object].shadow_terminator_offset;
        if (frequency_multiplier > 1.0)
        {
            float param_157 = dot(arg.omega_in, sc.N);
            float _10445 = shift_cos_in(param_157, frequency_multiplier);
            eval *= _10445;
        }
        if ((uint(label) & 4u) != 0u)
        {
            if (!isequal_float3(sc.N, arg.sd.N))
            {
                vec4 _10466;
                if ((uint(label) & 1u) != 0u)
                {
                    _10466 = -arg.sd.N;
                }
                else
                {
                    _10466 = arg.sd.N;
                }
                vec4 param_158 = _10466;
                vec4 param_159 = sc.N;
                vec4 param_160 = omega_in;
                eval *= bump_shadowing_term(param_158, param_159, param_160);
            }
        }
    }
    arg.sd.lcg_state = lcg_state;
    memoryBarrier();
    return label;
}

int shader_bsdf_sample(inout float randu, float randv, inout vec4 omega_in, inout differential3 domega_in, inout float pdf)
{
    float param = randu;
    int _10615 = shader_bsdf_pick(param);
    randu = param;
    int sampled = _10615;
    if (sampled < 0)
    {
        pdf = 0.0;
        return 0;
    }
    ShaderClosure _10629;
    _10629.weight = push.pool_ptr.pool_sc.data[sampled].weight;
    _10629.type = push.pool_ptr.pool_sc.data[sampled].type;
    _10629.sample_weight = push.pool_ptr.pool_sc.data[sampled].sample_weight;
    _10629.N = push.pool_ptr.pool_sc.data[sampled].N;
    _10629.next = push.pool_ptr.pool_sc.data[sampled].next;
    _10629.data[0] = push.pool_ptr.pool_sc.data[sampled].data[0];
    _10629.data[1] = push.pool_ptr.pool_sc.data[sampled].data[1];
    _10629.data[2] = push.pool_ptr.pool_sc.data[sampled].data[2];
    _10629.data[3] = push.pool_ptr.pool_sc.data[sampled].data[3];
    _10629.data[4] = push.pool_ptr.pool_sc.data[sampled].data[4];
    _10629.data[5] = push.pool_ptr.pool_sc.data[sampled].data[5];
    _10629.data[6] = push.pool_ptr.pool_sc.data[sampled].data[6];
    _10629.data[7] = push.pool_ptr.pool_sc.data[sampled].data[7];
    _10629.data[8] = push.pool_ptr.pool_sc.data[sampled].data[8];
    _10629.data[9] = push.pool_ptr.pool_sc.data[sampled].data[9];
    _10629.data[10] = push.pool_ptr.pool_sc.data[sampled].data[10];
    _10629.data[11] = push.pool_ptr.pool_sc.data[sampled].data[11];
    _10629.data[12] = push.pool_ptr.pool_sc.data[sampled].data[12];
    _10629.data[13] = push.pool_ptr.pool_sc.data[sampled].data[13];
    _10629.data[14] = push.pool_ptr.pool_sc.data[sampled].data[14];
    _10629.data[15] = push.pool_ptr.pool_sc.data[sampled].data[15];
    _10629.data[16] = push.pool_ptr.pool_sc.data[sampled].data[16];
    _10629.data[17] = push.pool_ptr.pool_sc.data[sampled].data[17];
    _10629.data[18] = push.pool_ptr.pool_sc.data[sampled].data[18];
    _10629.data[19] = push.pool_ptr.pool_sc.data[sampled].data[19];
    _10629.data[20] = push.pool_ptr.pool_sc.data[sampled].data[20];
    _10629.data[21] = push.pool_ptr.pool_sc.data[sampled].data[21];
    _10629.data[22] = push.pool_ptr.pool_sc.data[sampled].data[22];
    _10629.data[23] = push.pool_ptr.pool_sc.data[sampled].data[23];
    _10629.data[24] = push.pool_ptr.pool_sc.data[sampled].data[24];
    sc = _10629;
    if (!(push.pool_ptr.pool_sc.data[sampled].type <= 33u))
    {
        // unimplemented ext op 12
    }
    vec4 eval = vec4(0.0);
    pdf = 0.0;
    float param_1 = randu;
    float param_2 = randv;
    vec4 param_3 = eval;
    vec4 param_4 = omega_in;
    differential3 param_5 = domega_in;
    float param_6 = pdf;
    int _10657 = bsdf_sample(param_1, param_2, param_3, param_4, param_5, param_6);
    eval = param_3;
    omega_in = param_4;
    domega_in = param_5;
    pdf = param_6;
    int label = _10657;
    if (!(pdf == 0.0))
    {
        uint param_7 = sc.type;
        vec4 param_8 = eval * sc.weight;
        bsdf_eval_init(param_7, param_8);
        if (arg.sd.num_closure > 1)
        {
            float sweight = sc.sample_weight;
            float param_9 = pdf;
            float param_10 = pdf * sweight;
            float param_11 = sweight;
            _shader_bsdf_multi_eval(omega_in, param_9, sampled, param_10, param_11);
            pdf = param_9;
        }
    }
    return label;
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
    STIR = double[](0.00078731139579309367734077929057435lf, -0.00022954996161337812548425274528086lf, -0.00268132617805781235317819088948lf, 0.0034722222160545866166680983866399lf, 0.083333333333348219573721848973946lf, 0.0lf, 0.0lf, 0.0lf);
    P = double[](0.0001601195224767518480914890721678lf, 0.0011913514700658638361535635041832lf, 0.010421379756176157860281250577827lf, 0.047636780045713721098987747382125lf, 0.20744822764843598439377103659353lf, 0.49421482680149708688333021200378lf, 1.0lf, 0.0lf);
    Q = double[](-2.315818733241201444485700411402e-05lf, 0.00053960558049330335003007652616702lf, -0.0044564191385179727916687753008773lf, 0.011813978522206043317299695161182lf, 0.03582363986054986487728157840138lf, -0.23459179571824334553653557122743lf, 0.071430491703027301775286161955592lf, 1.0lf);
    A = double[](0.00081161416747050848814054591073841lf, -0.00059506190428430143831567411538686lf, 0.00079365034045771694262011441978188lf, -0.0027777777773009969426720733309821lf, 0.08333333333333318992952598591728lf, 0.0lf, 0.0lf, 0.0lf);
    B = double[](-1378.2515256912085988005856052041lf, -38801.631513463784358464181423187lf, -331612.9927388711948879063129425lf, -1162370.9749276230577379465103149lf, -1721737.0082083966117352247238159lf, -853555.66424576542340219020843506lf, 0.0lf, 0.0lf);
    C = double[](-351.81570143652345450391294434667lf, -17064.210665188114944612607359886lf, -220528.59055385444662533700466156lf, -1139334.4436798251699656248092651lf, -2532523.0717758294194936752319336lf, -2018891.4143353276886045932769775lf, 0.0lf, 0.0lf);
    PROFI_IDX = arg.label;
    if (0 == arg.type)
    {
        int callFlag = floatBitsToInt(arg.eval.diffuse.z);
        if (callFlag == 1234)
        {
            arg = arg2;
        }
        int _10727 = atomicAdd(_10721.counter[1012], int(PROFI_IDX != int(0u)));
        int state_flag = floatBitsToInt(arg.eval.diffuse.x);
        shader_bsdf_eval();
    }
    else
    {
        if (1 == arg.type)
        {
            float bsdf_u = arg.eval.diffuse.x;
            float bsdf_v = arg.eval.diffuse.y;
            float param = bsdf_u;
            float param_1 = bsdf_v;
            vec4 omega_in;
            vec4 param_2 = omega_in;
            differential3 domega_in;
            differential3 param_3 = domega_in;
            float pdf;
            float param_4 = pdf;
            int _10758 = shader_bsdf_sample(param, param_1, param_2, param_3, param_4);
            omega_in = param_2;
            domega_in = param_3;
            pdf = param_4;
            arg.label = _10758;
            arg.omega_in = omega_in;
            arg.domega_in = domega_in;
            arg.pdf = pdf;
        }
    }
}

