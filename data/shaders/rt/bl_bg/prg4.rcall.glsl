#version 460
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_nonuniform_qualifier : require
#extension GL_EXT_scalar_block_layout : require

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

struct NodeIO
{
    int offset;
    uint type;
    float data[62];
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
} _2360;

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals kg;
} _12092;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _12097;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    ShaderClosurePool pool_ptr;
} push;

layout(location = 1) callableDataInNV ShaderData sd;
layout(location = 2) callableDataNV NodeIO nio;
layout(set = 3, binding = 0) uniform texture2D _tex_[];
layout(set = 3, binding = 1) uniform sampler _samp_[];

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
bool alloc;
float stack[255];
int PROFI_IDX;
ShaderClosure null_sc;

vec4 _4809;

void bsdf_blur(int it_next, float roughness)
{
    switch (push.pool_ptr.pool_sc.data[it_next].type)
    {
        case 14u:
        case 15u:
        case 24u:
        case 27u:
        {
            push.pool_ptr.pool_sc.data[it_next].data[0] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[0]);
            push.pool_ptr.pool_sc.data[it_next].data[1] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[1]);
            break;
        }
        case 10u:
        case 11u:
        case 12u:
        case 23u:
        {
            push.pool_ptr.pool_sc.data[it_next].data[0] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[0]);
            push.pool_ptr.pool_sc.data[it_next].data[1] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[1]);
            break;
        }
        case 13u:
        case 22u:
        {
            push.pool_ptr.pool_sc.data[it_next].data[0] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[0]);
            push.pool_ptr.pool_sc.data[it_next].data[1] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[1]);
            break;
        }
        case 16u:
        {
            push.pool_ptr.pool_sc.data[it_next].data[0] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[0]);
            push.pool_ptr.pool_sc.data[it_next].data[1] = max(roughness, push.pool_ptr.pool_sc.data[it_next].data[1]);
            break;
        }
        default:
        {
            break;
        }
    }
}

void shader_bsdf_blur(float roughness)
{
    int it_next = sd.alloc_offset;
    for (int i = 0; i < sd.num_closure; i++)
    {
        if (push.pool_ptr.pool_sc.data[it_next].type <= 33u)
        {
            int param = it_next;
            float param_1 = roughness;
            bsdf_blur(param, param_1);
        }
        it_next = push.pool_ptr.pool_sc.data[it_next].next;
    }
}

void kernel_path_shader_apply(float blur_pdf)
{
    float blur_roughness = sqrt(1.0 - blur_pdf) * 0.5;
    float param = blur_roughness;
    shader_bsdf_blur(param);
}

int closure_alloc(uint type, vec4 weight)
{
    if (sd.num_closure_left == 0)
    {
        return -1;
    }
    if (sd.num_closure > 0)
    {
        sd.alloc_offset++;
        if (sd.alloc_offset >= (sd.atomic_offset + 64))
        {
            if (true)
            {
                // unimplemented ext op 12
            }
            return -1;
        }
        push.pool_ptr.pool_sc.data[sd.alloc_offset].weight = vec4(0.0);
        push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 0u;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight = 0.0;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].N = vec4(0.0);
        push.pool_ptr.pool_sc.data[sd.alloc_offset].next = 0;
        for (int _i_ = 0; _i_ < 25; _i_++)
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[_i_] = 0.0;
        }
        push.pool_ptr.pool_sc.data[sd.alloc_offset].next = sd.alloc_offset - 1;
    }
    else
    {
        sd.alloc_offset = sd.atomic_offset;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].weight = vec4(0.0);
        push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 0u;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight = 0.0;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].N = vec4(0.0);
        push.pool_ptr.pool_sc.data[sd.alloc_offset].next = 0;
        for (int _i_1 = 0; _i_1 < 25; _i_1++)
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[_i_1] = 0.0;
        }
        push.pool_ptr.pool_sc.data[sd.alloc_offset].next = -1;
    }
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = type;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].weight = weight;
    sd.num_closure++;
    sd.num_closure_left--;
    alloc = true;
    return sd.alloc_offset;
}

float reduce_add(vec4 a)
{
    return ((a.x + a.y) + a.z) + a.w;
}

float average(vec4 a)
{
    if (!(a.w == 0.0))
    {
        return reduce_add(a) * 0.25;
    }
    return reduce_add(a) * 0.3333333432674407958984375;
}

int bsdf_alloc(uint size, vec4 weight)
{
    uint param = 0u;
    vec4 param_1 = weight;
    int _2614 = closure_alloc(param, param_1);
    int n = _2614;
    if (n < 0)
    {
        return -1;
    }
    float sample_weight = abs(average(weight));
    push.pool_ptr.pool_sc.data[n].sample_weight = sample_weight;
    return (sample_weight >= 9.9999997473787516355514526367188e-06) ? n : (-1);
}

int bsdf_diffuse_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 2u;
    return 12;
}

int bsdf_oren_nayar_setup()
{
    float sigma = push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0];
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 3u;
    sigma = clamp(sigma, 0.0, 1.0);
    float div = 1.0 / (3.1415927410125732421875 + (0.904129683971405029296875 * sigma));
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = 1.0 * div;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = sigma * div;
    return 12;
}

int bsdf_diffuse_toon_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 7u;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1], 0.0, 1.0);
    return 12;
}

int bsdf_glossy_toon_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 19u;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1], 0.0, 1.0);
    return 12;
}

int bsdf_translucent_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 8u;
    return 12;
}

void bsdf_transparent_setup(vec4 weight, int path_flag)
{
    float sample_weight = abs(average(weight));
    if (!(sample_weight >= 9.9999997473787516355514526367188e-06))
    {
        return;
    }
    if ((uint(sd.flag) & 512u) != 0u)
    {
        sd.closure_transparent_extinction += weight;
        int it_begin = sd.alloc_offset;
        float sum = 0.0;
        for (int i = 0; i < sd.num_closure; i++)
        {
            if (push.pool_ptr.pool_sc.data[sd.alloc_offset].type == 33u)
            {
                push.pool_ptr.pool_sc.data[sd.alloc_offset].weight += weight;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight += sample_weight;
                break;
            }
            sd.alloc_offset = push.pool_ptr.pool_sc.data[sd.alloc_offset].next;
        }
        sd.alloc_offset = it_begin;
    }
    else
    {
        sd.flag |= 516;
        sd.closure_transparent_extinction = weight;
        if ((uint(path_flag) & 3145728u) != 0u)
        {
            sd.num_closure_left = 1;
        }
        uint param = 33u;
        vec4 param_1 = weight;
        int _3603 = closure_alloc(param, param_1);
        int n = _3603;
        if (n >= 0)
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight = sample_weight;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].N = sd.N;
        }
        else
        {
            if ((path_flag & 3145728) != int(0u))
            {
                sd.num_closure_left = 0;
            }
        }
    }
}

int bsdf_ashikhmin_velvet_setup()
{
    float sigma = max(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 0.00999999977648258209228515625);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = 1.0 / (sigma * sigma);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 17u;
    return 12;
}

int bsdf_refraction_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 21u;
    return 4;
}

float sqr(float a)
{
    return a * a;
}

int bsdf_microfacet_beckmann_refraction_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0];
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 22u;
    return 12;
}

int bsdf_microfacet_ggx_refraction_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0];
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 23u;
    return 12;
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

int bsdf_reflection_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 9u;
    return 4;
}

int bsdf_microfacet_beckmann_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 13u;
    return 12;
}

int bsdf_microfacet_ggx_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1], 0.0, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 10u;
    return 12;
}

void svm_node_glass_setup(int type, float eta, float roughness, bool _refract)
{
    if (uint(type) == 28u)
    {
        if (_refract)
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = 0.0;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = 0.0;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = eta;
            int _9122 = bsdf_refraction_setup();
            sd.flag |= _9122;
        }
        else
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = 0.0;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = 0.0;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = 0.0;
            int _9149 = bsdf_reflection_setup();
            sd.flag |= _9149;
        }
    }
    else
    {
        if (uint(type) == 25u)
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = roughness;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = eta;
            if (_refract)
            {
                int _9187 = bsdf_microfacet_beckmann_refraction_setup();
                sd.flag |= _9187;
            }
            else
            {
                int _9193 = bsdf_microfacet_beckmann_setup();
                sd.flag |= _9193;
            }
        }
        else
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = roughness;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = eta;
            if (_refract)
            {
                int _9226 = bsdf_microfacet_ggx_refraction_setup();
                sd.flag |= _9226;
            }
            else
            {
                int _9232 = bsdf_microfacet_ggx_setup();
                sd.flag |= _9232;
            }
        }
    }
}

vec4 saturate3(vec4 a)
{
    return clamp(a, vec4(0.0), vec4(1.0));
}

int bsdf_microfacet_multi_ggx_glass_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 9.9999997473787516355514526367188e-05, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0];
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = max(0.0, push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2]);
    vec4 tmp = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5], 0.0);
    vec4 param = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5], 0.0);
    tmp = saturate3(param);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = tmp.x;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4] = tmp.y;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5] = tmp.z;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 24u;
    return 1036;
}

vec4 rotate_around_axis(vec4 p, vec4 axis, float angle)
{
    float costheta = cos(angle);
    float sintheta = sin(angle);
    vec4 r;
    r.x = (((costheta + (((1.0 - costheta) * axis.x) * axis.x)) * p.x) + (((((1.0 - costheta) * axis.x) * axis.y) - (axis.z * sintheta)) * p.y)) + (((((1.0 - costheta) * axis.x) * axis.z) + (axis.y * sintheta)) * p.z);
    r.y = ((((((1.0 - costheta) * axis.x) * axis.y) + (axis.z * sintheta)) * p.x) + ((costheta + (((1.0 - costheta) * axis.y) * axis.y)) * p.y)) + (((((1.0 - costheta) * axis.y) * axis.z) - (axis.x * sintheta)) * p.z);
    r.z = ((((((1.0 - costheta) * axis.x) * axis.z) - (axis.y * sintheta)) * p.x) + (((((1.0 - costheta) * axis.y) * axis.z) + (axis.x * sintheta)) * p.y)) + ((costheta + (((1.0 - costheta) * axis.z) * axis.z)) * p.z);
    return r;
}

bool is_zero(vec4 a)
{
    bool _881 = a.x == 0.0;
    bool _886;
    if (_881)
    {
        _886 = a.y == 0.0;
    }
    else
    {
        _886 = _881;
    }
    bool _891;
    if (_886)
    {
        _891 = a.z == 0.0;
    }
    else
    {
        _891 = _886;
    }
    bool _896;
    if (_891)
    {
        _896 = a.w == 0.0;
    }
    else
    {
        _896 = _891;
    }
    return _896;
}

int bsdf_microfacet_multi_ggx_common_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 9.9999997473787516355514526367188e-05, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1], 9.9999997473787516355514526367188e-05, 1.0);
    vec4 tmp = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5], 0.0);
    vec4 param = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5], 0.0);
    tmp = saturate3(param);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = tmp.x;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4] = tmp.y;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5] = tmp.z;
    vec4 tmp_1 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[6], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[8], 0.0);
    vec4 param_1 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[6], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[8], 0.0);
    tmp_1 = saturate3(param_1);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[6] = tmp_1.x;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7] = tmp_1.y;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[8] = tmp_1.z;
    return 1036;
}

int bsdf_microfacet_multi_ggx_setup()
{
    if (is_zero(vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0)))
    {
        vec4 tmp = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
        tmp = vec4(1.0, 0.0, 0.0, 0.0);
        push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp.x;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp.y;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp.z;
    }
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 14u;
    int _3216 = bsdf_microfacet_multi_ggx_common_setup();
    return _3216;
}

int bsdf_ashikhmin_shirley_setup()
{
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0], 9.9999997473787516355514526367188e-05, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = clamp(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1], 9.9999997473787516355514526367188e-05, 1.0);
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 16u;
    return 12;
}

void svm_node_closure_bsdf(uvec4 node, uint shader_type, int path_flag, inout int offset)
{
    uint type = node.y & 255u;
    uint param1_offset = (node.y >> uint(8)) & 255u;
    uint param2_offset = (node.y >> uint(16)) & 255u;
    uint mix_weight_offset = (node.y >> uint(24)) & 255u;
    float _9307;
    if (mix_weight_offset != 255u)
    {
        _9307 = stack[mix_weight_offset];
    }
    else
    {
        _9307 = 1.0;
    }
    float mix_weight = _9307;
    int _9320 = offset;
    offset = _9320 + 1;
    uvec4 data_node = push.data_ptr._svm_nodes.data[_9320];
    if ((mix_weight == 0.0) || (shader_type != 0u))
    {
        if (type == 44u)
        {
            offset += 4;
        }
        return;
    }
    vec4 _9343;
    if (data_node.x != 255u)
    {
        _9343 = vec4(stack[data_node.x + 0u], stack[data_node.x + 1u], stack[data_node.x + 2u], 0.0);
    }
    else
    {
        _9343 = sd.N;
    }
    vec4 N = _9343;
    float _9369;
    if (param1_offset != 255u)
    {
        _9369 = stack[param1_offset];
    }
    else
    {
        _9369 = uintBitsToFloat(node.z);
    }
    float param1 = _9369;
    float _9383;
    if (param2_offset != 255u)
    {
        _9383 = stack[param2_offset];
    }
    else
    {
        _9383 = uintBitsToFloat(node.w);
    }
    float param2 = _9383;
    switch (type)
    {
        case 2u:
        {
            vec4 weight = sd.svm_closure_weight * mix_weight;
            uint param = 12u;
            vec4 param_1 = weight;
            int _9416 = bsdf_alloc(param, param_1);
            int n = _9416;
            if (n >= 0)
            {
                push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
                float roughness = param1;
                if (roughness == 0.0)
                {
                    int _9435 = bsdf_diffuse_setup();
                    sd.flag = _9435;
                }
                else
                {
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness;
                    int _9446 = bsdf_oren_nayar_setup();
                    sd.flag = _9446;
                }
            }
            break;
        }
        case 19u:
        {
            bool _9452 = !(_2360.kernel_data.integrator.caustics_reflective != int(0u));
            bool _9459;
            if (_9452)
            {
                _9459 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _9459 = _9452;
            }
            if (_9459)
            {
                break;
            }
            vec4 _9465 = sd.svm_closure_weight;
            vec4 _9467 = _9465 * mix_weight;
            vec4 weight_1 = _9467;
            uint param_2 = 8u;
            vec4 _9471 = weight_1;
            vec4 param_3 = _9471;
            int _9472 = bsdf_alloc(param_2, param_3);
            int n_1 = _9472;
            int _9473 = n_1;
            bool _9474 = _9473 >= 0;
            if (_9474)
            {
                int _9482 = sd.alloc_offset;
                push.pool_ptr.pool_sc.data[_9482].N = N;
                int _9490 = sd.alloc_offset;
                push.pool_ptr.pool_sc.data[_9490].data[0] = param1;
                int _9498 = sd.alloc_offset;
                push.pool_ptr.pool_sc.data[_9498].data[1] = param2;
                bool _9502 = type == 7u;
                if (_9502)
                {
                    int _9505 = bsdf_diffuse_toon_setup();
                    int _9507 = sd.flag;
                    int _9508 = _9507 | _9505;
                    sd.flag = _9508;
                }
                else
                {
                    int _9511 = bsdf_glossy_toon_setup();
                    int _9513 = sd.flag;
                    int _9514 = _9513 | _9511;
                    sd.flag = _9514;
                }
            }
            break;
        }
        case 7u:
        {
            vec4 _9465 = sd.svm_closure_weight;
            vec4 _9467 = _9465 * mix_weight;
            vec4 weight_1 = _9467;
            uint param_2 = 8u;
            vec4 _9471 = weight_1;
            vec4 param_3 = _9471;
            int _9472 = bsdf_alloc(param_2, param_3);
            int n_1 = _9472;
            int _9473 = n_1;
            bool _9474 = _9473 >= 0;
            if (_9474)
            {
                int _9482 = sd.alloc_offset;
                push.pool_ptr.pool_sc.data[_9482].N = N;
                int _9490 = sd.alloc_offset;
                push.pool_ptr.pool_sc.data[_9490].data[0] = param1;
                int _9498 = sd.alloc_offset;
                push.pool_ptr.pool_sc.data[_9498].data[1] = param2;
                bool _9502 = type == 7u;
                if (_9502)
                {
                    int _9505 = bsdf_diffuse_toon_setup();
                    int _9507 = sd.flag;
                    int _9508 = _9507 | _9505;
                    sd.flag = _9508;
                }
                else
                {
                    int _9511 = bsdf_glossy_toon_setup();
                    int _9513 = sd.flag;
                    int _9514 = _9513 | _9511;
                    sd.flag = _9514;
                }
            }
            break;
        }
        case 8u:
        {
            vec4 weight_2 = sd.svm_closure_weight * mix_weight;
            uint param_4 = 0u;
            vec4 param_5 = weight_2;
            int _9526 = bsdf_alloc(param_4, param_5);
            int n_2 = _9526;
            if (n_2 >= 0)
            {
                push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
                int _9539 = bsdf_translucent_setup();
                sd.flag |= _9539;
            }
            break;
        }
        case 33u:
        {
            vec4 weight_3 = sd.svm_closure_weight * mix_weight;
            int param_6 = path_flag;
            bsdf_transparent_setup(weight_3, param_6);
            break;
        }
        case 17u:
        {
            vec4 weight_4 = sd.svm_closure_weight * mix_weight;
            uint param_7 = 8u;
            vec4 param_8 = weight_4;
            int _9564 = bsdf_alloc(param_7, param_8);
            int n_3 = _9564;
            if (n_3 >= 0)
            {
                push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = clamp(param1, 0.0, 1.0);
                int _9586 = bsdf_ashikhmin_velvet_setup();
                sd.flag |= _9586;
            }
            break;
        }
        case 21u:
        case 23u:
        case 22u:
        {
            bool _9595 = !(_2360.kernel_data.integrator.caustics_refractive != int(0u));
            bool _9602;
            if (_9595)
            {
                _9602 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _9602 = _9595;
            }
            if (_9602)
            {
                break;
            }
            vec4 weight_5 = sd.svm_closure_weight * mix_weight;
            uint param_9 = 64u;
            vec4 param_10 = weight_5;
            int _9615 = bsdf_alloc(param_9, param_10);
            int n_4 = _9615;
            if (n_4 >= 0)
            {
                push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
                vec4 tmp = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
                tmp = vec4(0.0);
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp.x;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp.y;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp.z;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
                float eta = max(param2, 9.9999997473787516355514526367188e-06);
                float _9703;
                if ((uint(sd.flag) & 1u) != 0u)
                {
                    _9703 = 1.0 / eta;
                }
                else
                {
                    _9703 = eta;
                }
                eta = _9703;
                if (type == 21u)
                {
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = 0.0;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = 0.0;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = eta;
                    int _9737 = bsdf_refraction_setup();
                    sd.flag |= _9737;
                }
                else
                {
                    float param_11 = param1;
                    float roughness_1 = sqr(param_11);
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness_1;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = roughness_1;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = eta;
                    if (type == 22u)
                    {
                        int _9775 = bsdf_microfacet_beckmann_refraction_setup();
                        sd.flag |= _9775;
                    }
                    else
                    {
                        int _9781 = bsdf_microfacet_ggx_refraction_setup();
                        sd.flag |= _9781;
                    }
                }
            }
            break;
        }
        case 28u:
        case 26u:
        case 25u:
        {
            bool _9790 = !(_2360.kernel_data.integrator.caustics_reflective != int(0u));
            bool _9797;
            if (_9790)
            {
                _9797 = !(_2360.kernel_data.integrator.caustics_refractive != int(0u));
            }
            else
            {
                _9797 = _9790;
            }
            bool _9804;
            if (_9797)
            {
                _9804 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _9804 = _9797;
            }
            if (_9804)
            {
                break;
            }
            vec4 weight_6 = sd.svm_closure_weight * mix_weight;
            float eta_1 = max(param2, 9.9999997473787516355514526367188e-06);
            float _9821;
            if ((uint(sd.flag) & 1u) != 0u)
            {
                _9821 = 1.0 / eta_1;
            }
            else
            {
                _9821 = eta_1;
            }
            eta_1 = _9821;
            float cosNO = dot(N, sd.I);
            float param_12 = cosNO;
            float param_13 = eta_1;
            float fresnel = fresnel_dielectric_cos(param_12, param_13);
            float param_14 = param1;
            float roughness_2 = sqr(param_14);
            bool _9846 = _2360.kernel_data.integrator.caustics_reflective != int(0u);
            bool _9855;
            if (!_9846)
            {
                _9855 = !((uint(path_flag) & 8u) != 0u);
            }
            else
            {
                _9855 = _9846;
            }
            if (_9855)
            {
                uint param_15 = 64u;
                vec4 param_16 = weight_6 * fresnel;
                int _9864 = bsdf_alloc(param_15, param_16);
                int n_5 = _9864;
                if (n_5 >= 0)
                {
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
                    vec4 tmp_1 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
                    tmp_1 = vec4(0.0);
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp_1.x;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp_1.y;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp_1.z;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
                    int param_17 = int(type);
                    float param_18 = eta_1;
                    float param_19 = roughness_2;
                    bool param_20 = false;
                    svm_node_glass_setup(param_17, param_18, param_19, param_20);
                }
            }
            bool _9955 = _2360.kernel_data.integrator.caustics_refractive != int(0u);
            bool _9964;
            if (!_9955)
            {
                _9964 = !((uint(path_flag) & 8u) != 0u);
            }
            else
            {
                _9964 = _9955;
            }
            if (_9964)
            {
                uint param_21 = 64u;
                vec4 param_22 = weight_6 * (1.0 - fresnel);
                int _9974 = bsdf_alloc(param_21, param_22);
                int n_6 = _9974;
                if (n_6 >= 0)
                {
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
                    vec4 tmp_2 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
                    tmp_2 = vec4(0.0);
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp_2.x;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp_2.y;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp_2.z;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
                    int param_23 = int(type);
                    float param_24 = eta_1;
                    float param_25 = roughness_2;
                    bool param_26 = true;
                    svm_node_glass_setup(param_23, param_24, param_25, param_26);
                }
            }
            break;
        }
        case 24u:
        {
            bool _10067 = !(_2360.kernel_data.integrator.caustics_reflective != int(0u));
            bool _10074;
            if (_10067)
            {
                _10074 = !(_2360.kernel_data.integrator.caustics_refractive != int(0u));
            }
            else
            {
                _10074 = _10067;
            }
            bool _10081;
            if (_10074)
            {
                _10081 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _10081 = _10074;
            }
            if (_10081)
            {
                break;
            }
            vec4 weight_7 = sd.svm_closure_weight * mix_weight;
            uint param_27 = 64u;
            vec4 param_28 = weight_7;
            int _10094 = bsdf_alloc(param_27, param_28);
            int n_7 = _10094;
            if (n_7 < 0)
            {
                break;
            }
            push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
            vec4 tmp_3 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
            tmp_3 = vec4(0.0);
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp_3.x;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp_3.y;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp_3.z;
            float param_29 = param1;
            float roughness_3 = sqr(param_29);
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness_3;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = roughness_3;
            float eta_2 = max(param2, 9.9999997473787516355514526367188e-06);
            float _10195;
            if ((uint(sd.flag) & 1u) != 0u)
            {
                _10195 = 1.0 / eta_2;
            }
            else
            {
                _10195 = eta_2;
            }
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = _10195;
            if (!(data_node.z != 255u))
            {
                // unimplemented ext op 12
            }
            vec4 tmp_4 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5], 0.0);
            tmp_4 = vec4(stack[data_node.z + 0u], stack[data_node.z + 1u], stack[data_node.z + 2u], 0.0);
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = tmp_4.x;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4] = tmp_4.y;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5] = tmp_4.z;
            vec4 tmp_5 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[6], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[8], 0.0);
            tmp_5 = vec4(0.0);
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[6] = tmp_5.x;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7] = tmp_5.y;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[8] = tmp_5.z;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 0.0;
            int _10341 = bsdf_microfacet_multi_ggx_glass_setup();
            sd.flag |= _10341;
            break;
        }
        case 9u:
        case 10u:
        case 13u:
        case 16u:
        case 14u:
        {
            bool _10350 = !(_2360.kernel_data.integrator.caustics_reflective != int(0u));
            bool _10357;
            if (_10350)
            {
                _10357 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _10357 = _10350;
            }
            if (_10357)
            {
                break;
            }
            vec4 weight_8 = sd.svm_closure_weight * mix_weight;
            uint param_30 = 64u;
            vec4 param_31 = weight_8;
            int _10370 = bsdf_alloc(param_30, param_31);
            int n_8 = _10370;
            if (n_8 < 0)
            {
                break;
            }
            float param_32 = param1;
            float roughness_4 = sqr(param_32);
            push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[2] = 0.0;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
            if (data_node.y == 255u)
            {
                vec4 tmp_6 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
                tmp_6 = vec4(0.0);
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp_6.x;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp_6.y;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp_6.z;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness_4;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = roughness_4;
            }
            else
            {
                vec4 tmp_7 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
                tmp_7 = vec4(stack[data_node.y + 0u], stack[data_node.y + 1u], stack[data_node.y + 2u], 0.0);
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp_7.x;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp_7.y;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp_7.z;
                float rotation = stack[data_node.z];
                if (!(rotation == 0.0))
                {
                    vec4 tmp_8 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
                    vec4 param_33 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15], 0.0);
                    vec4 param_34 = push.pool_ptr.pool_sc.data[sd.alloc_offset].N;
                    float param_35 = rotation * 6.283185482025146484375;
                    tmp_8 = rotate_around_axis(param_33, param_34, param_35);
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[13] = tmp_8.x;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[14] = tmp_8.y;
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[15] = tmp_8.z;
                }
                float anisotropy = clamp(param2, -0.9900000095367431640625, 0.9900000095367431640625);
                if (anisotropy < 0.0)
                {
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness_4 / (1.0 + anisotropy);
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = roughness_4 * (1.0 + anisotropy);
                }
                else
                {
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness_4 * (1.0 - anisotropy);
                    push.pool_ptr.pool_sc.data[sd.alloc_offset].data[1] = roughness_4 / (1.0 - anisotropy);
                }
            }
            if (type == 9u)
            {
                int _10713 = bsdf_reflection_setup();
                sd.flag |= _10713;
            }
            else
            {
                if (type == 13u)
                {
                    int _10723 = bsdf_microfacet_beckmann_setup();
                    sd.flag |= _10723;
                }
                else
                {
                    if (type == 10u)
                    {
                        int _10733 = bsdf_microfacet_ggx_setup();
                        sd.flag |= _10733;
                    }
                    else
                    {
                        if (type == 14u)
                        {
                            if (!(data_node.w != 255u))
                            {
                                // unimplemented ext op 12
                            }
                            vec4 tmp_9 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5], 0.0);
                            tmp_9 = vec4(stack[data_node.w + 0u], stack[data_node.w + 1u], stack[data_node.w + 2u], 0.0);
                            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[3] = tmp_9.x;
                            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[4] = tmp_9.y;
                            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[5] = tmp_9.z;
                            vec4 tmp_10 = vec4(push.pool_ptr.pool_sc.data[sd.alloc_offset].data[6], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7], push.pool_ptr.pool_sc.data[sd.alloc_offset].data[8], 0.0);
                            tmp_10 = vec4(0.0);
                            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[6] = tmp_10.x;
                            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7] = tmp_10.y;
                            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[8] = tmp_10.z;
                            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[12] = 0.0;
                            int _10880 = bsdf_microfacet_multi_ggx_setup();
                            sd.flag |= _10880;
                        }
                        else
                        {
                            int _10886 = bsdf_ashikhmin_shirley_setup();
                            sd.flag |= _10886;
                        }
                    }
                }
            }
            break;
        }
        default:
        {
            break;
        }
    }
}

void emission_setup(vec4 weight)
{
    if ((uint(sd.flag) & 2u) != 0u)
    {
        sd.closure_emission_background += weight;
    }
    else
    {
        sd.flag |= 2;
        sd.closure_emission_background = weight;
    }
}

void svm_node_closure_emission(uvec4 node)
{
    uint mix_weight_offset = node.y;
    vec4 weight = sd.svm_closure_weight;
    if (mix_weight_offset != 255u)
    {
        float mix_weight = stack[mix_weight_offset];
        if (mix_weight == 0.0)
        {
            return;
        }
        weight *= mix_weight;
    }
    emission_setup(weight);
}

void background_setup(vec4 weight)
{
    if ((uint(sd.flag) & 2u) != 0u)
    {
        sd.closure_emission_background += weight;
    }
    else
    {
        sd.flag |= 2;
        sd.closure_emission_background = weight;
    }
}

void svm_node_closure_background(uvec4 node)
{
    uint mix_weight_offset = node.y;
    vec4 weight = sd.svm_closure_weight;
    if (mix_weight_offset != 255u)
    {
        float mix_weight = stack[mix_weight_offset];
        if (mix_weight == 0.0)
        {
            return;
        }
        weight *= mix_weight;
    }
    background_setup(weight);
}

vec4 primitive_tangent()
{
    nio.type = 1u;
    nio.data[0] = sd.N.x;
    nio.data[1] = sd.N.y;
    nio.data[2] = sd.N.z;
    nio.data[4] = intBitsToFloat(sd.object_flag);
    nio.data[5] = intBitsToFloat(sd.prim);
    nio.data[6] = intBitsToFloat(sd.type);
    nio.data[7] = sd.u;
    nio.data[8] = sd.v;
    nio.data[9] = intBitsToFloat(sd.object);
    nio.data[10] = sd.du.dx;
    nio.data[11] = sd.du.dy;
    nio.data[12] = sd.dv.dx;
    nio.data[13] = sd.dv.dy;
    nio.data[14] = intBitsToFloat(sd.lamp);
    executeCallableNV(7u, 2);
    if (nio.type != 0u)
    {
        return vec4(nio.data[0], nio.data[1], nio.data[2], 0.0);
    }
    else
    {
        return normalize(sd.dPdu);
    }
}

void svm_node_geometry(uint type, uint out_offset)
{
    vec4 data;
    switch (type)
    {
        case 0u:
        {
            data = sd.P;
            break;
        }
        case 1u:
        {
            data = sd.N;
            break;
        }
        case 2u:
        {
            vec4 _8762 = primitive_tangent();
            data = _8762;
            break;
        }
        case 3u:
        {
            data = sd.I;
            break;
        }
        case 4u:
        {
            data = sd.Ng;
            break;
        }
        case 5u:
        {
            data = vec4(sd.u, sd.v, 0.0, 0.0);
            break;
        }
        default:
        {
            data = vec4(0.0);
            break;
        }
    }
    stack[out_offset + 0u] = data.x;
    stack[out_offset + 1u] = data.y;
    stack[out_offset + 2u] = data.z;
}

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

float linear_rgb_to_gray(vec4 c)
{
    return dot(c, float4_to_float3(_2360.kernel_data.film.rgb_to_y));
}

void svm_node_convert(uint type, uint from, uint to)
{
    switch (type)
    {
        case 1u:
        {
            float f = stack[from];
            stack[to] = intBitsToFloat(int(f));
            break;
        }
        case 0u:
        {
            float f_1 = stack[from];
            stack[to + 0u] = vec4(f_1, f_1, f_1, 0.0).x;
            stack[to + 1u] = vec4(f_1, f_1, f_1, 0.0).y;
            stack[to + 2u] = vec4(f_1, f_1, f_1, 0.0).z;
            break;
        }
        case 2u:
        {
            vec4 f_2 = vec4(stack[from + 0u], stack[from + 1u], stack[from + 2u], 0.0);
            vec4 param = f_2;
            float g = linear_rgb_to_gray(param);
            stack[to] = g;
            break;
        }
        case 3u:
        {
            vec4 f_3 = vec4(stack[from + 0u], stack[from + 1u], stack[from + 2u], 0.0);
            vec4 param_1 = f_3;
            int i = int(linear_rgb_to_gray(param_1));
            stack[to] = intBitsToFloat(i);
            break;
        }
        case 4u:
        {
            vec4 f_4 = vec4(stack[from + 0u], stack[from + 1u], stack[from + 2u], 0.0);
            float g_1 = average(f_4);
            stack[to] = g_1;
            break;
        }
        case 5u:
        {
            vec4 f_5 = vec4(stack[from + 0u], stack[from + 1u], stack[from + 2u], 0.0);
            int i_1 = int(average(f_5));
            stack[to] = intBitsToFloat(i_1);
            break;
        }
        case 6u:
        {
            float f_6 = float(floatBitsToInt(stack[from]));
            stack[to] = f_6;
            break;
        }
        case 7u:
        {
            float f_7 = float(floatBitsToInt(stack[from]));
            stack[to + 0u] = vec4(f_7, f_7, f_7, 0.0).x;
            stack[to + 1u] = vec4(f_7, f_7, f_7, 0.0).y;
            stack[to + 2u] = vec4(f_7, f_7, f_7, 0.0).z;
            break;
        }
    }
}

Transform object_fetch_transform(int object, uint type)
{
    if (type == 1u)
    {
        Transform _1914;
        _1914.x = push.data_ptr._objects.data[object].itfm.x;
        _1914.y = push.data_ptr._objects.data[object].itfm.y;
        _1914.z = push.data_ptr._objects.data[object].itfm.z;
        Transform _1913 = _1914;
        return _1913;
    }
    else
    {
        Transform _1926;
        _1926.x = push.data_ptr._objects.data[object].tfm.x;
        _1926.y = push.data_ptr._objects.data[object].tfm.y;
        _1926.z = push.data_ptr._objects.data[object].tfm.z;
        Transform _1925 = _1926;
        return _1925;
    }
}

vec4 transform_point(Transform t, vec4 a)
{
    vec4 c = vec4((((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z)) + t.x.w, (((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z)) + t.y.w, (((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z)) + t.z.w, 0.0);
    c.w = 1.0;
    return c;
}

void object_inverse_position_transform(inout vec4 P_1)
{
    int param = sd.object;
    uint param_1 = 1u;
    Transform tfm = object_fetch_transform(param, param_1);
    Transform param_2 = tfm;
    tfm = param_2;
    P_1 = transform_point(param_2, P_1);
}

vec4 transform_direction_transposed(Transform t, vec4 a)
{
    vec4 x = vec4(t.x.x, t.y.x, t.z.x, 0.0);
    vec4 y = vec4(t.x.y, t.y.y, t.z.y, 0.0);
    vec4 z = vec4(t.x.z, t.y.z, t.z.z, 0.0);
    return vec4(dot(x, a), dot(y, a), dot(z, a), 0.0);
}

Transform lamp_fetch_transform(int lamp, bool _inverse)
{
    if (_inverse)
    {
        Transform _1945;
        _1945.x = push.data_ptr._lights.data[lamp].itfm.x;
        _1945.y = push.data_ptr._lights.data[lamp].itfm.y;
        _1945.z = push.data_ptr._lights.data[lamp].itfm.z;
        Transform _1944 = _1945;
        return _1944;
    }
    else
    {
        Transform _1958;
        _1958.x = push.data_ptr._lights.data[lamp].tfm.x;
        _1958.y = push.data_ptr._lights.data[lamp].tfm.y;
        _1958.z = push.data_ptr._lights.data[lamp].tfm.z;
        Transform _1957 = _1958;
        return _1957;
    }
}

void object_inverse_normal_transform(inout vec4 N)
{
    if (sd.object != (-1))
    {
        int param = sd.object;
        uint param_1 = 0u;
        Transform tfm = object_fetch_transform(param, param_1);
        N = normalize(transform_direction_transposed(tfm, N));
    }
    else
    {
        if (uint(sd.type) == 64u)
        {
            int param_2 = sd.lamp;
            bool param_3 = false;
            Transform tfm_1 = lamp_fetch_transform(param_2, param_3);
            N = normalize(transform_direction_transposed(tfm_1, N));
        }
    }
}

vec4 camera_position()
{
    Transform _4766;
    _4766.x = _2360.kernel_data.cam.cameratoworld.x;
    _4766.y = _2360.kernel_data.cam.cameratoworld.y;
    _4766.z = _2360.kernel_data.cam.cameratoworld.z;
    Transform cameratoworld = _4766;
    return vec4(cameratoworld.x.w, cameratoworld.y.w, cameratoworld.z.w, 0.0);
}

vec4 transform_perspective(ProjectionTransform t, vec4 a)
{
    vec4 b = vec4(a.xyz, 1.0);
    vec4 c = vec4(dot(t.x, b), dot(t.y, b), dot(t.z, b), 0.0);
    float w = dot(t.w, b);
    vec4 _1768;
    if (!(w == 0.0))
    {
        _1768 = c / vec4(w);
    }
    else
    {
        _1768 = vec4(0.0);
    }
    return _1768;
}

vec4 camera_world_to_ndc(inout vec4 P_1)
{
    if (uint(_2360.kernel_data.cam.type) != 2u)
    {
        bool _4785 = sd.object == (-1);
        bool _4792;
        if (_4785)
        {
            _4792 = uint(_2360.kernel_data.cam.type) == 0u;
        }
        else
        {
            _4792 = _4785;
        }
        if (_4792)
        {
            P_1 += camera_position();
        }
        ProjectionTransform _4804;
        _4804.x = _2360.kernel_data.cam.worldtondc.x;
        _4804.y = _2360.kernel_data.cam.worldtondc.y;
        _4804.z = _2360.kernel_data.cam.worldtondc.z;
        _4804.w = _2360.kernel_data.cam.worldtondc.w;
        ProjectionTransform tfm = _4804;
        return transform_perspective(tfm, P_1);
    }
}

vec4 object_dupli_generated(int object)
{
    if (object == (-1))
    {
        return vec4(0.0);
    }
    KernelObject _2136;
    _2136.tfm.x = push.data_ptr._objects.data[object].tfm.x;
    _2136.tfm.y = push.data_ptr._objects.data[object].tfm.y;
    _2136.tfm.z = push.data_ptr._objects.data[object].tfm.z;
    _2136.itfm.x = push.data_ptr._objects.data[object].itfm.x;
    _2136.itfm.y = push.data_ptr._objects.data[object].itfm.y;
    _2136.itfm.z = push.data_ptr._objects.data[object].itfm.z;
    _2136.surface_area = push.data_ptr._objects.data[object].surface_area;
    _2136.pass_id = push.data_ptr._objects.data[object].pass_id;
    _2136.random_number = push.data_ptr._objects.data[object].random_number;
    _2136.color[0] = push.data_ptr._objects.data[object].color[0];
    _2136.color[1] = push.data_ptr._objects.data[object].color[1];
    _2136.color[2] = push.data_ptr._objects.data[object].color[2];
    _2136.particle_index = push.data_ptr._objects.data[object].particle_index;
    _2136.dupli_generated[0] = push.data_ptr._objects.data[object].dupli_generated[0];
    _2136.dupli_generated[1] = push.data_ptr._objects.data[object].dupli_generated[1];
    _2136.dupli_generated[2] = push.data_ptr._objects.data[object].dupli_generated[2];
    _2136.dupli_uv[0] = push.data_ptr._objects.data[object].dupli_uv[0];
    _2136.dupli_uv[1] = push.data_ptr._objects.data[object].dupli_uv[1];
    _2136.numkeys = push.data_ptr._objects.data[object].numkeys;
    _2136.numsteps = push.data_ptr._objects.data[object].numsteps;
    _2136.numverts = push.data_ptr._objects.data[object].numverts;
    _2136.patch_map_offset = push.data_ptr._objects.data[object].patch_map_offset;
    _2136.attribute_map_offset = push.data_ptr._objects.data[object].attribute_map_offset;
    _2136.motion_offset = push.data_ptr._objects.data[object].motion_offset;
    _2136.cryptomatte_object = push.data_ptr._objects.data[object].cryptomatte_object;
    _2136.cryptomatte_asset = push.data_ptr._objects.data[object].cryptomatte_asset;
    _2136.shadow_terminator_offset = push.data_ptr._objects.data[object].shadow_terminator_offset;
    _2136.pad1 = push.data_ptr._objects.data[object].pad1;
    _2136.pad2 = push.data_ptr._objects.data[object].pad2;
    _2136.pad3 = push.data_ptr._objects.data[object].pad3;
    KernelObject kobject = _2136;
    return vec4(kobject.dupli_generated[0], kobject.dupli_generated[1], kobject.dupli_generated[2], 0.0);
}

vec4 object_dupli_uv(int object)
{
    if (object == (-1))
    {
        return vec4(0.0);
    }
    KernelObject _2160;
    _2160.tfm.x = push.data_ptr._objects.data[object].tfm.x;
    _2160.tfm.y = push.data_ptr._objects.data[object].tfm.y;
    _2160.tfm.z = push.data_ptr._objects.data[object].tfm.z;
    _2160.itfm.x = push.data_ptr._objects.data[object].itfm.x;
    _2160.itfm.y = push.data_ptr._objects.data[object].itfm.y;
    _2160.itfm.z = push.data_ptr._objects.data[object].itfm.z;
    _2160.surface_area = push.data_ptr._objects.data[object].surface_area;
    _2160.pass_id = push.data_ptr._objects.data[object].pass_id;
    _2160.random_number = push.data_ptr._objects.data[object].random_number;
    _2160.color[0] = push.data_ptr._objects.data[object].color[0];
    _2160.color[1] = push.data_ptr._objects.data[object].color[1];
    _2160.color[2] = push.data_ptr._objects.data[object].color[2];
    _2160.particle_index = push.data_ptr._objects.data[object].particle_index;
    _2160.dupli_generated[0] = push.data_ptr._objects.data[object].dupli_generated[0];
    _2160.dupli_generated[1] = push.data_ptr._objects.data[object].dupli_generated[1];
    _2160.dupli_generated[2] = push.data_ptr._objects.data[object].dupli_generated[2];
    _2160.dupli_uv[0] = push.data_ptr._objects.data[object].dupli_uv[0];
    _2160.dupli_uv[1] = push.data_ptr._objects.data[object].dupli_uv[1];
    _2160.numkeys = push.data_ptr._objects.data[object].numkeys;
    _2160.numsteps = push.data_ptr._objects.data[object].numsteps;
    _2160.numverts = push.data_ptr._objects.data[object].numverts;
    _2160.patch_map_offset = push.data_ptr._objects.data[object].patch_map_offset;
    _2160.attribute_map_offset = push.data_ptr._objects.data[object].attribute_map_offset;
    _2160.motion_offset = push.data_ptr._objects.data[object].motion_offset;
    _2160.cryptomatte_object = push.data_ptr._objects.data[object].cryptomatte_object;
    _2160.cryptomatte_asset = push.data_ptr._objects.data[object].cryptomatte_asset;
    _2160.shadow_terminator_offset = push.data_ptr._objects.data[object].shadow_terminator_offset;
    _2160.pad1 = push.data_ptr._objects.data[object].pad1;
    _2160.pad2 = push.data_ptr._objects.data[object].pad2;
    _2160.pad3 = push.data_ptr._objects.data[object].pad3;
    KernelObject kobject = _2160;
    return vec4(kobject.dupli_uv[0], kobject.dupli_uv[1], 0.0, 0.0);
}

void svm_node_tex_coord(int path_flag, uvec4 node, inout int offset)
{
    uint type = node.y;
    uint out_offset = node.z;
    vec4 data;
    switch (type)
    {
        case 1u:
        {
            data = sd.P;
            if (node.w == 0u)
            {
                if (sd.object != (-1))
                {
                    vec4 param = data;
                    object_inverse_position_transform(param);
                    data = param;
                }
            }
            else
            {
                uvec4 node_1 = push.data_ptr._svm_nodes.data[offset];
                Transform tfm;
                tfm.x = vec4(uintBitsToFloat(node_1.x), uintBitsToFloat(node_1.y), uintBitsToFloat(node_1.z), uintBitsToFloat(node_1.w));
                offset++;
                uvec4 node_2 = push.data_ptr._svm_nodes.data[offset];
                tfm.y = vec4(uintBitsToFloat(node_2.x), uintBitsToFloat(node_2.y), uintBitsToFloat(node_2.z), uintBitsToFloat(node_2.w));
                offset++;
                uvec4 node_3 = push.data_ptr._svm_nodes.data[offset];
                tfm.z = vec4(uintBitsToFloat(node_3.x), uintBitsToFloat(node_3.y), uintBitsToFloat(node_3.z), uintBitsToFloat(node_3.w));
                offset++;
                Transform param_1 = tfm;
                tfm = param_1;
                data = transform_point(param_1, data);
            }
            break;
        }
        case 0u:
        {
            data = sd.N;
            vec4 param_2 = data;
            object_inverse_normal_transform(param_2);
            data = param_2;
            break;
        }
        case 2u:
        {
            Transform _4934;
            _4934.x = _2360.kernel_data.cam.worldtocamera.x;
            _4934.y = _2360.kernel_data.cam.worldtocamera.y;
            _4934.z = _2360.kernel_data.cam.worldtocamera.z;
            Transform tfm_1 = _4934;
            if (sd.object != (-1))
            {
                Transform param_3 = tfm_1;
                tfm_1 = param_3;
                data = transform_point(param_3, sd.P);
            }
            else
            {
                Transform param_4 = tfm_1;
                tfm_1 = param_4;
                data = transform_point(param_4, sd.P + camera_position());
            }
            break;
        }
        case 3u:
        {
            bool _4959 = (uint(path_flag) & 1u) != 0u;
            bool _4965;
            if (_4959)
            {
                _4965 = sd.object == (-1);
            }
            else
            {
                _4965 = _4959;
            }
            bool _4972;
            if (_4965)
            {
                _4972 = uint(_2360.kernel_data.cam.type) == 1u;
            }
            else
            {
                _4972 = _4965;
            }
            if (_4972)
            {
                vec4 param_5 = sd.ray_P;
                vec4 _4978 = camera_world_to_ndc(param_5);
                data = _4978;
            }
            else
            {
                vec4 param_6 = sd.P;
                vec4 _4983 = camera_world_to_ndc(param_6);
                data = _4983;
            }
            data.z = 0.0;
            break;
        }
        case 4u:
        {
            if (sd.object != (-1))
            {
                data = (sd.N * (2.0 * dot(sd.N, sd.I))) - sd.I;
            }
            else
            {
                data = sd.I;
            }
            break;
        }
        case 5u:
        {
            int param_7 = sd.object;
            data = object_dupli_generated(param_7);
            break;
        }
        case 6u:
        {
            int param_8 = sd.object;
            data = object_dupli_uv(param_8);
            break;
        }
        case 7u:
        {
            data = sd.P;
            break;
        }
    }
    stack[out_offset + 0u] = data.x;
    stack[out_offset + 1u] = data.y;
    stack[out_offset + 2u] = data.z;
}

void svm_node_attr(uvec4 node)
{
    nio.data[15] = uintBitsToFloat(node.x);
    nio.data[16] = uintBitsToFloat(node.y);
    nio.data[17] = uintBitsToFloat(node.z);
    nio.data[18] = uintBitsToFloat(node.w);
    nio.data[0] = sd.N.x;
    nio.data[1] = sd.N.y;
    nio.data[2] = sd.N.z;
    nio.data[4] = intBitsToFloat(sd.object_flag);
    nio.data[5] = intBitsToFloat(sd.prim);
    nio.data[6] = intBitsToFloat(sd.type);
    nio.data[7] = sd.u;
    nio.data[8] = sd.v;
    nio.data[9] = intBitsToFloat(sd.object);
    nio.data[10] = sd.du.dx;
    nio.data[11] = sd.du.dy;
    nio.data[12] = sd.dv.dx;
    nio.data[13] = sd.dv.dy;
    nio.data[14] = intBitsToFloat(sd.lamp);
    nio.type = 2u;
    executeCallableNV(7u, 2);
    uint type = nio.type;
    uint out_offset = uint(nio.offset);
    uint desc_type = uint(floatBitsToInt(nio.data[4]));
    if (desc_type == 0u)
    {
        float f = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]).x;
        if (type == 0u)
        {
            stack[out_offset] = f;
        }
        else
        {
            stack[out_offset + 0u] = vec4(f, f, f, 0.0).x;
            stack[out_offset + 1u] = vec4(f, f, f, 0.0).y;
            stack[out_offset + 2u] = vec4(f, f, f, 0.0).z;
        }
    }
    else
    {
        if (desc_type == 1u)
        {
            vec2 f_1 = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]).xy;
            if (type == 0u)
            {
                stack[out_offset] = f_1.x;
            }
            else
            {
                stack[out_offset + 0u] = vec4(f_1.x, f_1.y, 0.0, 0.0).x;
                stack[out_offset + 1u] = vec4(f_1.x, f_1.y, 0.0, 0.0).y;
                stack[out_offset + 2u] = vec4(f_1.x, f_1.y, 0.0, 0.0).z;
            }
        }
        else
        {
            if (desc_type == 3u)
            {
                vec4 f_2 = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
                if (type == 0u)
                {
                    stack[out_offset] = average(float4_to_float3(f_2));
                }
                else
                {
                    stack[out_offset + 0u] = float4_to_float3(f_2).x;
                    stack[out_offset + 1u] = float4_to_float3(f_2).y;
                    stack[out_offset + 2u] = float4_to_float3(f_2).z;
                }
            }
            else
            {
                vec4 f_3 = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
                if (type == 0u)
                {
                    stack[out_offset] = average(f_3);
                }
                else
                {
                    stack[out_offset + 0u] = f_3.x;
                    stack[out_offset + 1u] = f_3.y;
                    stack[out_offset + 2u] = f_3.z;
                }
            }
        }
    }
}

vec4 rgb_to_hsv(vec4 rgb)
{
    float cmax = max(rgb.x, max(rgb.y, rgb.z));
    float cmin = min(rgb.x, min(rgb.y, rgb.z));
    float cdelta = cmax - cmin;
    float v = cmax;
    float s;
    float h;
    if (!(cmax == 0.0))
    {
        s = cdelta / cmax;
    }
    else
    {
        s = 0.0;
        h = 0.0;
    }
    if (!(s == 0.0))
    {
        vec4 cmax3 = vec4(cmax, cmax, cmax, 0.0);
        vec4 c = (cmax3 - rgb) / vec4(cdelta);
        if (rgb.x == cmax)
        {
            h = c.z - c.y;
        }
        else
        {
            if (rgb.y == cmax)
            {
                h = (2.0 + c.x) - c.z;
            }
            else
            {
                h = (4.0 + c.y) - c.x;
            }
        }
        h /= 6.0;
        if (h < 0.0)
        {
            h += 1.0;
        }
    }
    else
    {
        h = 0.0;
    }
    return vec4(h, s, v, 0.0);
}

vec4 hsv_to_rgb(vec4 hsv)
{
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;
    vec4 rgb;
    if (!(s == 0.0))
    {
        if (h == 1.0)
        {
            h = 0.0;
        }
        h *= 6.0;
        float i = floor(h);
        float f = h - i;
        rgb = vec4(f, f, f, 0.0);
        float p = v * (1.0 - s);
        float q = v * (1.0 - (s * f));
        float t = v * (1.0 - (s * (1.0 - f)));
        if (i == 0.0)
        {
            rgb = vec4(v, t, p, 0.0);
        }
        else
        {
            if (i == 1.0)
            {
                rgb = vec4(q, v, p, 0.0);
            }
            else
            {
                if (i == 2.0)
                {
                    rgb = vec4(p, v, t, 0.0);
                }
                else
                {
                    if (i == 3.0)
                    {
                        rgb = vec4(p, q, v, 0.0);
                    }
                    else
                    {
                        if (i == 4.0)
                        {
                            rgb = vec4(t, p, v, 0.0);
                        }
                        else
                        {
                            rgb = vec4(v, p, q, 0.0);
                        }
                    }
                }
            }
        }
    }
    else
    {
        rgb = vec4(v, v, v, 0.0);
    }
    return rgb;
}

void svm_node_hsv(uvec4 node, int offset)
{
    uint in_color_offset = node.y & 255u;
    uint fac_offset = (node.y >> uint(8)) & 255u;
    uint out_color_offset = (node.y >> uint(16)) & 255u;
    uint hue_offset = node.z & 255u;
    uint sat_offset = (node.z >> uint(8)) & 255u;
    uint val_offset = (node.z >> uint(16)) & 255u;
    float fac = stack[fac_offset];
    vec4 in_color = vec4(stack[in_color_offset + 0u], stack[in_color_offset + 1u], stack[in_color_offset + 2u], 0.0);
    vec4 color = in_color;
    float hue = stack[hue_offset];
    float sat = stack[sat_offset];
    float val = stack[val_offset];
    vec4 param = color;
    color = rgb_to_hsv(param);
    color.x = mod((color.x + hue) + 0.5, 1.0);
    color.y = clamp(color.y * sat, 0.0, 1.0);
    color.z *= val;
    vec4 param_1 = color;
    color = hsv_to_rgb(param_1);
    color.x = (fac * color.x) + ((1.0 - fac) * in_color.x);
    color.y = (fac * color.y) + ((1.0 - fac) * in_color.y);
    color.z = (fac * color.z) + ((1.0 - fac) * in_color.z);
    color.x = max(color.x, 0.0);
    color.y = max(color.y, 0.0);
    color.z = max(color.z, 0.0);
    if (out_color_offset != 255u)
    {
        stack[out_color_offset + 0u] = color.x;
        stack[out_color_offset + 1u] = color.y;
        stack[out_color_offset + 2u] = color.z;
    }
}

vec4 texco_remap_square(vec4 co)
{
    return (co - vec4(0.5, 0.5, 0.5, 0.0)) * 2.0;
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
        bool _1250 = co.x == 0.0;
        bool _1255;
        if (_1250)
        {
            _1255 = co.y == 0.0;
        }
        else
        {
            _1255 = _1250;
        }
        if (_1255)
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

vec2 map_to_tube(vec4 co)
{
    float len = sqrt((co.x * co.x) + (co.y * co.y));
    float u;
    float v;
    if (len > 0.0)
    {
        u = (1.0 - (atan(co.x / len, co.y / len) / 3.1415927410125732421875)) * 0.5;
        v = (co.z + 1.0) * 0.5;
    }
    else
    {
        v = 0.0;
        u = 0.0;
    }
    return vec2(u, v);
}

vec4 kernel_tex_image_interp(int id, inout float x, inout float y)
{
    TextureInfo _7387;
    _7387.data = push.data_ptr._texture_info.data[id].data;
    _7387.data_type = push.data_ptr._texture_info.data[id].data_type;
    _7387.cl_buffer = push.data_ptr._texture_info.data[id].cl_buffer;
    _7387.interpolation = push.data_ptr._texture_info.data[id].interpolation;
    _7387.extension = push.data_ptr._texture_info.data[id].extension;
    _7387.width = push.data_ptr._texture_info.data[id].width;
    _7387.height = push.data_ptr._texture_info.data[id].height;
    _7387.depth = push.data_ptr._texture_info.data[id].depth;
    _7387.use_transform_3d = push.data_ptr._texture_info.data[id].use_transform_3d;
    _7387.transform_3d.x = push.data_ptr._texture_info.data[id].transform_3d.x;
    _7387.transform_3d.y = push.data_ptr._texture_info.data[id].transform_3d.y;
    _7387.transform_3d.z = push.data_ptr._texture_info.data[id].transform_3d.z;
    _7387.pad[0] = push.data_ptr._texture_info.data[id].pad[0];
    _7387.pad[1] = push.data_ptr._texture_info.data[id].pad[1];
    TextureInfo info = _7387;
    uint texSlot = uint(info.data);
    uint texture_type = info.data_type;
    if (texSlot >= 128u)
    {
        // unimplemented ext op 12
        return vec4(0.0);
    }
    // unimplemented ext op 12
    if ((((texture_type == IMAGE_DATA_TYPE_FLOAT4) || (texture_type == IMAGE_DATA_TYPE_BYTE4)) || (texture_type == IMAGE_DATA_TYPE_HALF4)) || (texture_type == IMAGE_DATA_TYPE_USHORT4))
    {
        if (info.interpolation == INTERPOLATION_CUBIC)
        {
            uint sampID = info.extension;
            if (sampID >= 6u)
            {
                // unimplemented ext op 12
                return vec4(0.0);
            }
            x = (x * float(info.width)) - 0.5;
            y = (y * float(info.height)) - 0.5;
            float px = floor(x);
            float py = floor(y);
            float fx = x - px;
            float fy = y - py;
            float g0x = (0.16666667163372039794921875 * ((fx * ((fx * ((-fx) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fx * fx) * ((3.0 * fx) - 6.0)) + 4.0));
            float g1x = (0.16666667163372039794921875 * ((fx * ((fx * (((-3.0) * fx) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fx * fx) * fx));
            float x0 = (px + (((-1.0) + ((0.16666667163372039794921875 * (((fx * fx) * ((3.0 * fx) - 6.0)) + 4.0)) / ((0.16666667163372039794921875 * ((fx * ((fx * ((-fx) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fx * fx) * ((3.0 * fx) - 6.0)) + 4.0))))) + 0.5)) / float(info.width);
            float x1 = (px + ((1.0 + ((0.16666667163372039794921875 * ((fx * fx) * fx)) / ((0.16666667163372039794921875 * ((fx * ((fx * (((-3.0) * fx) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fx * fx) * fx))))) + 0.5)) / float(info.width);
            float y0 = (py + (((-1.0) + ((0.16666667163372039794921875 * (((fy * fy) * ((3.0 * fy) - 6.0)) + 4.0)) / ((0.16666667163372039794921875 * ((fy * ((fy * ((-fy) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy * fy) * ((3.0 * fy) - 6.0)) + 4.0))))) + 0.5)) / float(info.height);
            float y1 = (py + ((1.0 + ((0.16666667163372039794921875 * ((fy * fy) * fy)) / ((0.16666667163372039794921875 * ((fy * ((fy * (((-3.0) * fy) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy * fy) * fy))))) + 0.5)) / float(info.height);
            uint _7682 = texSlot;
            uint _7691 = sampID;
            uint _7704 = texSlot;
            uint _7708 = sampID;
            uint _7738 = texSlot;
            uint _7742 = sampID;
            uint _7753 = texSlot;
            uint _7757 = sampID;
            vec4 ret = (((textureLod(sampler2D(_tex_[nonuniformEXT(_7682)], _samp_[nonuniformEXT(_7691)]), vec2(x0, y0), 0.0) * g0x) + (textureLod(sampler2D(_tex_[nonuniformEXT(_7704)], _samp_[nonuniformEXT(_7708)]), vec2(x1, y0), 0.0) * g1x)) * ((0.16666667163372039794921875 * ((fy * ((fy * ((-fy) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy * fy) * ((3.0 * fy) - 6.0)) + 4.0)))) + (((textureLod(sampler2D(_tex_[nonuniformEXT(_7738)], _samp_[nonuniformEXT(_7742)]), vec2(x0, y1), 0.0) * g0x) + (textureLod(sampler2D(_tex_[nonuniformEXT(_7753)], _samp_[nonuniformEXT(_7757)]), vec2(x1, y1), 0.0) * g1x)) * ((0.16666667163372039794921875 * ((fy * ((fy * (((-3.0) * fy) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy * fy) * fy))));
            return ret;
        }
        else
        {
            uint sampID_1 = (info.interpolation * 3u) + info.extension;
            if (sampID_1 >= 6u)
            {
                // unimplemented ext op 12
                return vec4(0.0);
            }
            uint _7786 = texSlot;
            uint _7790 = sampID_1;
            return textureLod(sampler2D(_tex_[nonuniformEXT(_7786)], _samp_[nonuniformEXT(_7790)]), vec2(x, y), 0.0);
        }
    }
    else
    {
        float f;
        if (info.interpolation == INTERPOLATION_CUBIC)
        {
            uint sampID_2 = info.extension;
            if (sampID_2 >= 6u)
            {
                // unimplemented ext op 12
                return vec4(0.0);
            }
            x = (x * float(info.width)) - 0.5;
            y = (y * float(info.height)) - 0.5;
            float px_1 = floor(x);
            float py_1 = floor(y);
            float fx_1 = x - px_1;
            float fy_1 = y - py_1;
            float g0x_1 = (0.16666667163372039794921875 * ((fx_1 * ((fx_1 * ((-fx_1) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fx_1 * fx_1) * ((3.0 * fx_1) - 6.0)) + 4.0));
            float g1x_1 = (0.16666667163372039794921875 * ((fx_1 * ((fx_1 * (((-3.0) * fx_1) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fx_1 * fx_1) * fx_1));
            float x0_1 = (px_1 + (((-1.0) + ((0.16666667163372039794921875 * (((fx_1 * fx_1) * ((3.0 * fx_1) - 6.0)) + 4.0)) / ((0.16666667163372039794921875 * ((fx_1 * ((fx_1 * ((-fx_1) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fx_1 * fx_1) * ((3.0 * fx_1) - 6.0)) + 4.0))))) + 0.5)) / float(info.width);
            float x1_1 = (px_1 + ((1.0 + ((0.16666667163372039794921875 * ((fx_1 * fx_1) * fx_1)) / ((0.16666667163372039794921875 * ((fx_1 * ((fx_1 * (((-3.0) * fx_1) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fx_1 * fx_1) * fx_1))))) + 0.5)) / float(info.width);
            float y0_1 = (py_1 + (((-1.0) + ((0.16666667163372039794921875 * (((fy_1 * fy_1) * ((3.0 * fy_1) - 6.0)) + 4.0)) / ((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * ((-fy_1) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy_1 * fy_1) * ((3.0 * fy_1) - 6.0)) + 4.0))))) + 0.5)) / float(info.height);
            float y1_1 = (py_1 + ((1.0 + ((0.16666667163372039794921875 * ((fy_1 * fy_1) * fy_1)) / ((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * (((-3.0) * fy_1) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy_1 * fy_1) * fy_1))))) + 0.5)) / float(info.height);
            uint _8047 = texSlot;
            uint _8051 = sampID_2;
            uint _8063 = texSlot;
            uint _8067 = sampID_2;
            uint _8098 = texSlot;
            uint _8102 = sampID_2;
            uint _8114 = texSlot;
            uint _8118 = sampID_2;
            f = (((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * ((-fy_1) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy_1 * fy_1) * ((3.0 * fy_1) - 6.0)) + 4.0))) * ((g0x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_8047)], _samp_[nonuniformEXT(_8051)]), vec2(x0_1, y0_1), 0.0).x) + (g1x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_8063)], _samp_[nonuniformEXT(_8067)]), vec2(x1_1, y0_1), 0.0).x))) + (((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * (((-3.0) * fy_1) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy_1 * fy_1) * fy_1))) * ((g0x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_8098)], _samp_[nonuniformEXT(_8102)]), vec2(x0_1, y1_1), 0.0).x) + (g1x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_8114)], _samp_[nonuniformEXT(_8118)]), vec2(x1_1, y1_1), 0.0).x)));
        }
        else
        {
            uint sampID_3 = (info.interpolation * 3u) + info.extension;
            if (sampID_3 >= 6u)
            {
                // unimplemented ext op 12
                return vec4(0.0);
            }
            uint _8146 = texSlot;
            uint _8150 = sampID_3;
            f = textureLod(sampler2D(_tex_[nonuniformEXT(_8146)], _samp_[nonuniformEXT(_8150)]), vec2(x, y), 0.0).x;
        }
        return vec4(f, f, f, 1.0);
    }
}

float color_srgb_to_linear(float c)
{
    if (c < 0.040449999272823333740234375)
    {
        float _1287;
        if (c < 0.0)
        {
            _1287 = 0.0;
        }
        else
        {
            _1287 = c * 0.077399380505084991455078125;
        }
        return _1287;
    }
    else
    {
        return pow((c + 0.054999999701976776123046875) * 0.94786727428436279296875, 2.400000095367431640625);
    }
}

vec4 color_srgb_to_linear_v4(vec4 c)
{
    float param = c.x;
    float param_1 = c.y;
    float param_2 = c.z;
    return vec4(color_srgb_to_linear(param), color_srgb_to_linear(param_1), color_srgb_to_linear(param_2), c.w);
}

vec4 svm_image_texture(int id, float x, float y, uint flags)
{
    if (id == (-1))
    {
        return vec4(1.0, 0.0, 1.0, 1.0);
    }
    int param = id;
    float param_1 = x;
    float param_2 = y;
    vec4 _8178 = kernel_tex_image_interp(param, param_1, param_2);
    vec4 r = _8178;
    float alpha = r.w;
    if ((((flags & 2u) != 0u) && (!(alpha == 1.0))) && (!(alpha == 0.0)))
    {
        r /= vec4(alpha);
        r.w = alpha;
    }
    if ((flags & 1u) != 0u)
    {
        vec4 param_3 = r;
        r = color_srgb_to_linear_v4(param_3);
    }
    return r;
}

void svm_node_tex_image(uvec4 node, inout int offset)
{
    uint co_offset = node.z & 255u;
    uint out_offset = (node.z >> uint(8)) & 255u;
    uint alpha_offset = (node.z >> uint(16)) & 255u;
    uint flags = (node.z >> uint(24)) & 255u;
    vec4 co = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0);
    vec2 tex_co;
    if (node.w == 2u)
    {
        vec4 param = co;
        co = texco_remap_square(param);
        tex_co = map_to_sphere(co);
    }
    else
    {
        if (node.w == 3u)
        {
            vec4 param_1 = co;
            co = texco_remap_square(param_1);
            tex_co = map_to_tube(co);
        }
        else
        {
            tex_co = vec2(co.x, co.y);
        }
    }
    int id = -1;
    int num_nodes = int(node.y);
    if (num_nodes > 0)
    {
        int next_offset = offset + num_nodes;
        int tx = int(tex_co.x);
        int ty = int(tex_co.y);
        if (((tx >= 0) && (ty >= 0)) && (tx < 10))
        {
            int tile = (1001 + (10 * ty)) + tx;
            for (int i = 0; i < num_nodes; i++)
            {
                int _8329 = offset;
                offset = _8329 + 1;
                uvec4 tile_node = push.data_ptr._svm_nodes.data[_8329];
                if (tile_node.x == uint(tile))
                {
                    id = int(tile_node.y);
                    break;
                }
                if (tile_node.z == uint(tile))
                {
                    id = int(tile_node.w);
                    break;
                }
            }
            if (id != (-1))
            {
                tex_co.x -= float(tx);
                tex_co.y -= float(ty);
            }
        }
        offset = next_offset;
    }
    else
    {
        id = -num_nodes;
    }
    int param_2 = id;
    float param_3 = tex_co.x;
    float param_4 = tex_co.y;
    uint param_5 = flags;
    vec4 f = svm_image_texture(param_2, param_3, param_4, param_5);
    if (out_offset != 255u)
    {
        stack[out_offset + 0u] = vec4(f.x, f.y, f.z, 0.0).x;
        stack[out_offset + 1u] = vec4(f.x, f.y, f.z, 0.0).y;
        stack[out_offset + 2u] = vec4(f.x, f.y, f.z, 0.0).z;
    }
    if (alpha_offset != 255u)
    {
        stack[alpha_offset] = f.w;
    }
}

vec4 fetch_node_float(int offset)
{
    uvec4 node = push.data_ptr._svm_nodes.data[offset];
    return vec4(uintBitsToFloat(node.x), uintBitsToFloat(node.y), uintBitsToFloat(node.z), uintBitsToFloat(node.w));
}

vec4 rgb_ramp_lookup(int offset, inout float f, bool interpolate, bool extrapolate, int table_size)
{
    if (((f < 0.0) || (f > 1.0)) && extrapolate)
    {
        vec4 t0;
        vec4 dy;
        if (f < 0.0)
        {
            int param = offset;
            t0 = fetch_node_float(param);
            int param_1 = offset + 1;
            dy = t0 - fetch_node_float(param_1);
            f = -f;
        }
        else
        {
            int param_2 = (offset + table_size) - 1;
            t0 = fetch_node_float(param_2);
            int param_3 = (offset + table_size) - 2;
            dy = t0 - fetch_node_float(param_3);
            f -= 1.0;
        }
        return t0 + ((dy * f) * float(table_size - 1));
    }
    f = clamp(f, 0.0, 1.0) * float(table_size - 1);
    int i = clamp(int(f), 0, table_size - 1);
    float t = f - float(i);
    int param_4 = offset + i;
    vec4 a = fetch_node_float(param_4);
    if (interpolate && (t > 0.0))
    {
        int param_5 = (offset + i) + 1;
        a = (a * (1.0 - t)) + (fetch_node_float(param_5) * t);
    }
    return a;
}

void svm_node_rgb_ramp(uvec4 node, inout int offset)
{
    uint interpolate = node.z;
    uint fac_offset = node.y & 255u;
    uint color_offset = (node.y >> uint(8)) & 255u;
    uint alpha_offset = (node.y >> uint(16)) & 255u;
    int _4707 = offset;
    offset = _4707 + 1;
    uint table_size = push.data_ptr._svm_nodes.data[_4707].x;
    float fac = stack[fac_offset];
    int param = offset;
    float param_1 = fac;
    bool param_2 = interpolate != 0u;
    bool param_3 = false;
    int param_4 = int(table_size);
    vec4 _4727 = rgb_ramp_lookup(param, param_1, param_2, param_3, param_4);
    vec4 color = _4727;
    if (color_offset != 255u)
    {
        stack[color_offset + 0u] = float4_to_float3(color).x;
        stack[color_offset + 1u] = float4_to_float3(color).y;
        stack[color_offset + 2u] = float4_to_float3(color).z;
    }
    if (alpha_offset != 255u)
    {
        stack[alpha_offset] = color.w;
    }
    offset += int(table_size);
}

float safe_divide(float a, float b)
{
    float _1162;
    if (!(b == 0.0))
    {
        _1162 = a / b;
    }
    else
    {
        _1162 = 0.0;
    }
    return _1162;
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
    bool _1141 = a < 0.0;
    bool _1149;
    if (_1141)
    {
        _1149 = !(b == float(int(b)));
    }
    else
    {
        _1149 = _1141;
    }
    if (_1149)
    {
        return 0.0;
    }
    float param = a;
    float param_1 = b;
    return compatible_powf(param, param_1);
}

float safe_logf(float a, float b)
{
    if ((a <= 0.0) || (b <= 0.0))
    {
        return 0.0;
    }
    float param = log(a);
    float param_1 = log(b);
    return safe_divide(param, param_1);
}

float safe_sqrtf(float f)
{
    return sqrt(max(f, 0.0));
}

float inversesqrtf(float f)
{
    float _1082;
    if (f > 0.0)
    {
        _1082 = 1.0 / sqrt(f);
    }
    else
    {
        _1082 = 0.0;
    }
    return _1082;
}

float safe_modulo(float a, float b)
{
    float _1191;
    if (!(b == 0.0))
    {
        _1191 = mod(a, b);
    }
    else
    {
        _1191 = 0.0;
    }
    return _1191;
}

float wrapf(float value, float _max, float _min)
{
    float range = _max - _min;
    float _711;
    if (!(range == 0.0))
    {
        _711 = value - (range * floor((value - _min) / range));
    }
    else
    {
        _711 = _min;
    }
    return _711;
}

float pingpongf(float a, float b)
{
    float _731;
    if (!(b == 0.0))
    {
        _731 = abs(((fract((a - b) / (b * 2.0)) * b) * 2.0) - b);
    }
    else
    {
        _731 = 0.0;
    }
    return _731;
}

float safe_asinf(float a)
{
    return asin(clamp(a, -1.0, 1.0));
}

float signf(float f)
{
    return (f < 0.0) ? (-1.0) : 1.0;
}

float compatible_signf(float f)
{
    if (f == 0.0)
    {
        return 0.0;
    }
    else
    {
        float param = f;
        return signf(param);
    }
}

float smoothminf(float a, float b, float k)
{
    if (!(k == 0.0))
    {
        float h = max(k - abs(a - b), 0.0) / k;
        return min(a, b) - ((((h * h) * h) * k) * 0.16666667163372039794921875);
    }
    else
    {
        return min(a, b);
    }
}

float svm_math(uint type, float a, float b, float c)
{
    switch (type)
    {
        case 0u:
        {
            return a + b;
        }
        case 1u:
        {
            return a - b;
        }
        case 2u:
        {
            return a * b;
        }
        case 3u:
        {
            float param = a;
            float param_1 = b;
            return safe_divide(param, param_1);
        }
        case 10u:
        {
            float param_2 = a;
            float param_3 = b;
            return safe_powf(param_2, param_3);
        }
        case 11u:
        {
            float param_4 = a;
            float param_5 = b;
            return safe_logf(param_4, param_5);
        }
        case 23u:
        {
            float param_6 = a;
            return safe_sqrtf(param_6);
        }
        case 24u:
        {
            float param_7 = a;
            return inversesqrtf(param_7);
        }
        case 18u:
        {
            return abs(a);
        }
        case 27u:
        {
            return a * 0.01745329238474369049072265625;
        }
        case 28u:
        {
            return a * 57.295780181884765625;
        }
        case 12u:
        {
            return min(a, b);
        }
        case 13u:
        {
            return max(a, b);
        }
        case 15u:
        {
            return float(a < b);
        }
        case 16u:
        {
            return float(a > b);
        }
        case 14u:
        {
            return floor(a + 0.5);
        }
        case 20u:
        {
            return floor(a);
        }
        case 21u:
        {
            return ceil(a);
        }
        case 22u:
        {
            return a - floor(a);
        }
        case 17u:
        {
            float param_8 = a;
            float param_9 = b;
            return safe_modulo(param_8, param_9);
        }
        case 32u:
        {
            float _5861;
            if (a >= 0.0)
            {
                _5861 = floor(a);
            }
            else
            {
                _5861 = ceil(a);
            }
            return _5861;
        }
        case 33u:
        {
            float param_10 = a;
            float param_11 = b;
            return floor(safe_divide(param_10, param_11)) * b;
        }
        case 34u:
        {
            float param_12 = a;
            float param_13 = b;
            float param_14 = c;
            return wrapf(param_12, param_13, param_14);
        }
        case 37u:
        {
            float param_15 = a;
            float param_16 = b;
            return pingpongf(param_15, param_16);
        }
        case 4u:
        {
            return sin(a);
        }
        case 5u:
        {
            return cos(a);
        }
        case 6u:
        {
            return tan(a);
        }
        case 29u:
        {
            return sinh(a);
        }
        case 30u:
        {
            return cosh(a);
        }
        case 31u:
        {
            return tanh(a);
        }
        case 7u:
        {
            float param_17 = a;
            return safe_asinf(param_17);
        }
        case 8u:
        {
            float param_18 = a;
            return safe_acosf(param_18);
        }
        case 9u:
        {
            return atan(a);
        }
        case 19u:
        {
            return atan(a, b);
        }
        case 25u:
        {
            float param_19 = a;
            return compatible_signf(param_19);
        }
        case 26u:
        {
            return exp(a);
        }
        case 35u:
        {
            bool _5936 = a == b;
            bool _5948;
            if (!_5936)
            {
                _5948 = abs(a - b) <= max(c, 1.1920928955078125e-07);
            }
            else
            {
                _5948 = _5936;
            }
            return float(_5948);
        }
        case 36u:
        {
            return (a * b) + c;
        }
        case 38u:
        {
            float param_20 = a;
            float param_21 = b;
            float param_22 = c;
            return smoothminf(param_20, param_21, param_22);
        }
        case 39u:
        {
            float param_23 = -a;
            float param_24 = -b;
            float param_25 = c;
            return -smoothminf(param_23, param_24, param_25);
        }
        default:
        {
            return 0.0;
        }
    }
}

vec4 safe_divide_float3_float3(vec4 a, vec4 b)
{
    float _849;
    if (!(b.x == 0.0))
    {
        _849 = a.x / b.x;
    }
    else
    {
        _849 = 0.0;
    }
    float _859;
    if (!(b.y == 0.0))
    {
        _859 = a.y / b.y;
    }
    else
    {
        _859 = 0.0;
    }
    float _869;
    if (!(b.z == 0.0))
    {
        _869 = a.z / b.z;
    }
    else
    {
        _869 = 0.0;
    }
    return vec4(_849, _859, _869, 0.0);
}

vec4 cross(vec4 e1, vec4 e0)
{
    return vec4(cross(e1.xyz, e0.xyz), 0.0);
}

vec4 project(vec4 v, vec4 v_proj)
{
    float len_squared = dot(v_proj, v_proj);
    vec4 _820;
    if (!(len_squared == 0.0))
    {
        _820 = v_proj * (dot(v, v_proj) / len_squared);
    }
    else
    {
        _820 = vec4(0.0);
    }
    return _820;
}

vec4 safe_normalize(vec4 a)
{
    float t = sqrt(dot(a, a));
    vec4 _837;
    if (!(t == 0.0))
    {
        _837 = a * (1.0 / t);
    }
    else
    {
        _837 = a;
    }
    return _837;
}

void svm_vector_math(inout float value, inout vec4 vector, uint type, vec4 a, vec4 b, vec4 c, float scale)
{
    switch (type)
    {
        case 0u:
        {
            vector = a + b;
            break;
        }
        case 1u:
        {
            vector = a - b;
            break;
        }
        case 2u:
        {
            vector = a * b;
            break;
        }
        case 3u:
        {
            vector = safe_divide_float3_float3(a, b);
            break;
        }
        case 4u:
        {
            vec4 param = a;
            vec4 param_1 = b;
            vector = cross(param, param_1);
            break;
        }
        case 5u:
        {
            vector = project(a, b);
            break;
        }
        case 6u:
        {
            vector = reflect(a, b);
            break;
        }
        case 7u:
        {
            value = dot(a, b);
            break;
        }
        case 8u:
        {
            value = distance(a, b);
            break;
        }
        case 9u:
        {
            value = sqrt(dot(a, a));
            break;
        }
        case 10u:
        {
            vector = a * scale;
            break;
        }
        case 11u:
        {
            vector = safe_normalize(a);
            break;
        }
        case 12u:
        {
            vector = floor(safe_divide_float3_float3(a, b)) * b;
            break;
        }
        case 13u:
        {
            vector = floor(a);
            break;
        }
        case 14u:
        {
            vector = ceil(a);
            break;
        }
        case 15u:
        {
            float param_2 = a.x;
            float param_3 = b.x;
            float param_4 = a.y;
            float param_5 = b.y;
            float param_6 = a.z;
            float param_7 = b.z;
            vector = vec4(safe_modulo(param_2, param_3), safe_modulo(param_4, param_5), safe_modulo(param_6, param_7), 0.0);
            break;
        }
        case 20u:
        {
            float param_8 = a.x;
            float param_9 = b.x;
            float param_10 = c.x;
            float param_11 = a.y;
            float param_12 = b.y;
            float param_13 = c.y;
            float param_14 = a.z;
            float param_15 = b.z;
            float param_16 = c.z;
            vector = vec4(wrapf(param_8, param_9, param_10), wrapf(param_11, param_12, param_13), wrapf(param_14, param_15, param_16), 0.0);
            break;
        }
        case 16u:
        {
            vector = a - floor(a);
            break;
        }
        case 17u:
        {
            vector = abs(a);
            break;
        }
        case 18u:
        {
            vector = min(a, b);
            break;
        }
        case 19u:
        {
            vector = max(a, b);
            break;
        }
        case 21u:
        {
            vector = vec4(sin(a.x), sin(a.y), sin(a.z), 0.0);
            break;
        }
        case 22u:
        {
            vector = vec4(cos(a.x), cos(a.y), cos(a.z), 0.0);
            break;
        }
        case 23u:
        {
            vector = vec4(tan(a.x), tan(a.y), tan(a.z), 0.0);
            break;
        }
        default:
        {
            vector = vec4(0.0);
            value = 0.0;
            break;
        }
    }
}

vec4 svm_math_gamma_color(inout vec4 color, float gamma)
{
    if (gamma == 0.0)
    {
        return vec4(1.0, 1.0, 1.0, 0.0);
    }
    if (color.x > 0.0)
    {
        color.x = pow(color.x, gamma);
    }
    if (color.y > 0.0)
    {
        color.y = pow(color.y, gamma);
    }
    if (color.z > 0.0)
    {
        color.z = pow(color.z, gamma);
    }
    return color;
}

vec4 svm_brightness_contrast(inout vec4 color, float brightness, float contrast)
{
    float a = 1.0 + contrast;
    float b = brightness - (contrast * 0.5);
    color.x = max((a * color.x) + b, 0.0);
    color.y = max((a * color.y) + b, 0.0);
    color.z = max((a * color.z) + b, 0.0);
    return color;
}

vec4 object_location()
{
    if (sd.object == (-1))
    {
        return vec4(0.0);
    }
    int param = sd.object;
    uint param_1 = 0u;
    Transform tfm = object_fetch_transform(param, param_1);
    return vec4(tfm.x.w, tfm.y.w, tfm.z.w, 0.0);
}

vec4 object_color(int object)
{
    if (object == (-1))
    {
        return vec4(0.0);
    }
    KernelObject _2053;
    _2053.tfm.x = push.data_ptr._objects.data[object].tfm.x;
    _2053.tfm.y = push.data_ptr._objects.data[object].tfm.y;
    _2053.tfm.z = push.data_ptr._objects.data[object].tfm.z;
    _2053.itfm.x = push.data_ptr._objects.data[object].itfm.x;
    _2053.itfm.y = push.data_ptr._objects.data[object].itfm.y;
    _2053.itfm.z = push.data_ptr._objects.data[object].itfm.z;
    _2053.surface_area = push.data_ptr._objects.data[object].surface_area;
    _2053.pass_id = push.data_ptr._objects.data[object].pass_id;
    _2053.random_number = push.data_ptr._objects.data[object].random_number;
    _2053.color[0] = push.data_ptr._objects.data[object].color[0];
    _2053.color[1] = push.data_ptr._objects.data[object].color[1];
    _2053.color[2] = push.data_ptr._objects.data[object].color[2];
    _2053.particle_index = push.data_ptr._objects.data[object].particle_index;
    _2053.dupli_generated[0] = push.data_ptr._objects.data[object].dupli_generated[0];
    _2053.dupli_generated[1] = push.data_ptr._objects.data[object].dupli_generated[1];
    _2053.dupli_generated[2] = push.data_ptr._objects.data[object].dupli_generated[2];
    _2053.dupli_uv[0] = push.data_ptr._objects.data[object].dupli_uv[0];
    _2053.dupli_uv[1] = push.data_ptr._objects.data[object].dupli_uv[1];
    _2053.numkeys = push.data_ptr._objects.data[object].numkeys;
    _2053.numsteps = push.data_ptr._objects.data[object].numsteps;
    _2053.numverts = push.data_ptr._objects.data[object].numverts;
    _2053.patch_map_offset = push.data_ptr._objects.data[object].patch_map_offset;
    _2053.attribute_map_offset = push.data_ptr._objects.data[object].attribute_map_offset;
    _2053.motion_offset = push.data_ptr._objects.data[object].motion_offset;
    _2053.cryptomatte_object = push.data_ptr._objects.data[object].cryptomatte_object;
    _2053.cryptomatte_asset = push.data_ptr._objects.data[object].cryptomatte_asset;
    _2053.shadow_terminator_offset = push.data_ptr._objects.data[object].shadow_terminator_offset;
    _2053.pad1 = push.data_ptr._objects.data[object].pad1;
    _2053.pad2 = push.data_ptr._objects.data[object].pad2;
    _2053.pad3 = push.data_ptr._objects.data[object].pad3;
    KernelObject kobject = _2053;
    return vec4(kobject.color[0], kobject.color[1], kobject.color[2], 0.0);
}

float object_pass_id(int object)
{
    if (object == (-1))
    {
        return 0.0;
    }
    return push.data_ptr._objects.data[object].pass_id;
}

int shader_pass_id()
{
    return push.data_ptr._shaders.data[uint(sd.shader) & 8388607u].pass_id;
}

float lamp_random_number(int lamp)
{
    if (lamp == (-1))
    {
        return 0.0;
    }
    return push.data_ptr._lights.data[lamp].random;
}

float object_random_number(int object)
{
    if (object == (-1))
    {
        return 0.0;
    }
    return push.data_ptr._objects.data[object].random_number;
}

void svm_node_object_info(uint type, uint out_offset)
{
    float data;
    switch (type)
    {
        case 0u:
        {
            stack[out_offset + 0u] = object_location().x;
            stack[out_offset + 1u] = object_location().y;
            stack[out_offset + 2u] = object_location().z;
            return;
        }
        case 1u:
        {
            int param = sd.object;
            stack[out_offset + 0u] = object_color(param).x;
            int param_1 = sd.object;
            stack[out_offset + 1u] = object_color(param_1).y;
            int param_2 = sd.object;
            stack[out_offset + 2u] = object_color(param_2).z;
            return;
        }
        case 2u:
        {
            int param_3 = sd.object;
            data = object_pass_id(param_3);
            break;
        }
        case 3u:
        {
            data = float(shader_pass_id());
            break;
        }
        case 4u:
        {
            if (sd.lamp != (-1))
            {
                int param_4 = sd.lamp;
                data = lamp_random_number(param_4);
            }
            else
            {
                int param_5 = sd.object;
                data = object_random_number(param_5);
            }
            break;
        }
        default:
        {
            data = 0.0;
            break;
        }
    }
    stack[out_offset] = data;
}

int object_particle_id(int object)
{
    if (object == (-1))
    {
        return 0;
    }
    return push.data_ptr._objects.data[object].particle_index;
}

uint hash_uint2(uint kx, uint ky)
{
    uint c = 3735928580u;
    uint b = 3735928580u;
    uint a = 3735928580u;
    b += ky;
    a += kx;
    c ^= b;
    c -= ((b << uint(14)) | (b >> uint(18)));
    a ^= c;
    a -= ((c << uint(11)) | (c >> uint(21)));
    b ^= a;
    b -= ((a << uint(25)) | (a >> uint(7)));
    c ^= b;
    c -= ((b << uint(16)) | (b >> uint(16)));
    a ^= c;
    a -= ((c << uint(4)) | (c >> uint(28)));
    b ^= a;
    b -= ((a << uint(14)) | (a >> uint(18)));
    c ^= b;
    c -= ((b << uint(24)) | (b >> uint(8)));
    return c;
}

float hash_uint2_to_float(uint kx, uint ky)
{
    uint param = kx;
    uint param_1 = ky;
    return float(hash_uint2(param, param_1)) / 4294967296.0;
}

void svm_node_particle_info(uint type, uint out_offset)
{
    switch (type)
    {
        case 0u:
        {
            int param = sd.object;
            int particle_id = object_particle_id(param);
            stack[out_offset] = float(push.data_ptr._particles.data[particle_id].index);
            break;
        }
        case 1u:
        {
            int param_1 = sd.object;
            int particle_id_1 = object_particle_id(param_1);
            uint param_2 = uint(push.data_ptr._particles.data[particle_id_1].index);
            uint param_3 = 0u;
            float random = hash_uint2_to_float(param_2, param_3);
            stack[out_offset] = random;
            break;
        }
        case 2u:
        {
            int param_4 = sd.object;
            int particle_id_2 = object_particle_id(param_4);
            stack[out_offset] = push.data_ptr._particles.data[particle_id_2].age;
            break;
        }
        case 3u:
        {
            int param_5 = sd.object;
            int particle_id_3 = object_particle_id(param_5);
            stack[out_offset] = push.data_ptr._particles.data[particle_id_3].lifetime;
            break;
        }
        case 4u:
        {
            int param_6 = sd.object;
            int particle_id_4 = object_particle_id(param_6);
            stack[out_offset + 0u] = float4_to_float3(push.data_ptr._particles.data[particle_id_4].location).x;
            stack[out_offset + 1u] = float4_to_float3(push.data_ptr._particles.data[particle_id_4].location).y;
            stack[out_offset + 2u] = float4_to_float3(push.data_ptr._particles.data[particle_id_4].location).z;
            break;
        }
        case 6u:
        {
            int param_7 = sd.object;
            int particle_id_5 = object_particle_id(param_7);
            stack[out_offset] = push.data_ptr._particles.data[particle_id_5].size;
            break;
        }
        case 7u:
        {
            int param_8 = sd.object;
            int particle_id_6 = object_particle_id(param_8);
            stack[out_offset + 0u] = float4_to_float3(push.data_ptr._particles.data[particle_id_6].velocity).x;
            stack[out_offset + 1u] = float4_to_float3(push.data_ptr._particles.data[particle_id_6].velocity).y;
            stack[out_offset + 2u] = float4_to_float3(push.data_ptr._particles.data[particle_id_6].velocity).z;
            break;
        }
        case 8u:
        {
            int param_9 = sd.object;
            int particle_id_7 = object_particle_id(param_9);
            stack[out_offset + 0u] = float4_to_float3(push.data_ptr._particles.data[particle_id_7].angular_velocity).x;
            stack[out_offset + 1u] = float4_to_float3(push.data_ptr._particles.data[particle_id_7].angular_velocity).y;
            stack[out_offset + 2u] = float4_to_float3(push.data_ptr._particles.data[particle_id_7].angular_velocity).z;
            break;
        }
    }
}

Transform euler_to_transform(vec4 euler)
{
    float cx = cos(euler.x);
    float cy = cos(euler.y);
    float cz = cos(euler.z);
    float sx = sin(euler.x);
    float sy = sin(euler.y);
    float sz = sin(euler.z);
    Transform t;
    t.x.x = cy * cz;
    t.y.x = cy * sz;
    t.z.x = -sy;
    t.x.y = ((sy * sx) * cz) - (cx * sz);
    t.y.y = ((sy * sx) * sz) + (cx * cz);
    t.z.y = cy * sx;
    t.x.z = ((sy * cx) * cz) + (sx * sz);
    t.y.z = ((sy * cx) * sz) - (sx * cz);
    t.z.z = cy * cx;
    t.z.w = 0.0;
    t.y.w = 0.0;
    t.x.w = 0.0;
    return t;
}

vec4 transform_direction(Transform t, vec4 a)
{
    vec4 c = vec4(((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z), ((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z), ((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z), 0.0);
    return c;
}

vec4 svm_mapping(uint type, vec4 vector, vec4 location, vec4 rotation, vec4 scale)
{
    Transform rotationTransform = euler_to_transform(rotation);
    switch (type)
    {
        case 0u:
        {
            Transform param = rotationTransform;
            rotationTransform = param;
            return transform_direction(param, vector * scale) + location;
        }
        case 1u:
        {
            return safe_divide_float3_float3(transform_direction_transposed(rotationTransform, vector - location), scale);
        }
        case 2u:
        {
            Transform param_1 = rotationTransform;
            rotationTransform = param_1;
            return transform_direction(param_1, vector * scale);
        }
        case 3u:
        {
            Transform param_2 = rotationTransform;
            rotationTransform = param_2;
            return safe_normalize(transform_direction(param_2, safe_divide_float3_float3(vector, scale)));
        }
        default:
        {
            return vec4(0.0);
        }
    }
}

void svm_node_mapping(uint type, uint inputs_stack_offsets, uint result_stack_offset, int offset)
{
    uint vector_stack_offset = inputs_stack_offsets & 255u;
    uint location_stack_offset = (inputs_stack_offsets >> uint(8)) & 255u;
    uint rotation_stack_offset = (inputs_stack_offsets >> uint(16)) & 255u;
    uint scale_stack_offset = (inputs_stack_offsets >> uint(24)) & 255u;
    vec4 vector = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0);
    vec4 location = vec4(stack[location_stack_offset + 0u], stack[location_stack_offset + 1u], stack[location_stack_offset + 2u], 0.0);
    vec4 rotation = vec4(stack[rotation_stack_offset + 0u], stack[rotation_stack_offset + 1u], stack[rotation_stack_offset + 2u], 0.0);
    vec4 scale = vec4(stack[scale_stack_offset + 0u], stack[scale_stack_offset + 1u], stack[scale_stack_offset + 2u], 0.0);
    uint param = type;
    vec4 param_1 = vector;
    vec4 param_2 = location;
    vec4 param_3 = rotation;
    vec4 param_4 = scale;
    vec4 result = svm_mapping(param, param_1, param_2, param_3, param_4);
    stack[result_stack_offset + 0u] = result.x;
    stack[result_stack_offset + 1u] = result.y;
    stack[result_stack_offset + 2u] = result.z;
}

void svm_node_tex_noise(uint dimensions, uint offsets1, uint offsets2, inout int offset)
{
    nio.type = 0u;
    uint vector_stack_offset = offsets1 & 255u;
    uint w_stack_offset = (offsets1 >> uint(8)) & 255u;
    uint scale_stack_offset = (offsets1 >> uint(16)) & 255u;
    uint detail_stack_offset = (offsets1 >> uint(24)) & 255u;
    uint roughness_stack_offset = offsets2 & 255u;
    uint distortion_stack_offset = (offsets2 >> uint(8)) & 255u;
    uint value_stack_offset = (offsets2 >> uint(16)) & 255u;
    uint color_stack_offset = (offsets2 >> uint(24)) & 255u;
    int _6347 = offset;
    offset = _6347 + 1;
    uvec4 defaults1 = push.data_ptr._svm_nodes.data[_6347];
    int _6356 = offset;
    offset = _6356 + 1;
    uvec4 defaults2 = push.data_ptr._svm_nodes.data[_6356];
    nio.data[8] = float(dimensions);
    nio.offset = int(color_stack_offset);
    nio.data[0] = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0).x;
    nio.data[1] = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0).y;
    nio.data[2] = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0).z;
    float _6413;
    if (w_stack_offset == 255u)
    {
        _6413 = uintBitsToFloat(defaults1.x);
    }
    else
    {
        _6413 = stack[w_stack_offset];
    }
    nio.data[3] = _6413;
    float _6427;
    if (scale_stack_offset == 255u)
    {
        _6427 = uintBitsToFloat(defaults1.y);
    }
    else
    {
        _6427 = stack[scale_stack_offset];
    }
    nio.data[4] = _6427;
    float _6441;
    if (detail_stack_offset == 255u)
    {
        _6441 = uintBitsToFloat(defaults1.z);
    }
    else
    {
        _6441 = stack[detail_stack_offset];
    }
    nio.data[5] = _6441;
    float _6455;
    if (roughness_stack_offset == 255u)
    {
        _6455 = uintBitsToFloat(defaults1.w);
    }
    else
    {
        _6455 = stack[roughness_stack_offset];
    }
    nio.data[6] = _6455;
    float _6469;
    if (distortion_stack_offset == 255u)
    {
        _6469 = uintBitsToFloat(defaults2.x);
    }
    else
    {
        _6469 = stack[distortion_stack_offset];
    }
    nio.data[7] = _6469;
    executeCallableNV(5u, 2);
    if (value_stack_offset != 255u)
    {
        stack[value_stack_offset] = nio.data[3];
    }
    if (color_stack_offset != 255u)
    {
        stack[color_stack_offset + 0u] = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0).x;
        stack[color_stack_offset + 1u] = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0).y;
        stack[color_stack_offset + 2u] = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0).z;
    }
}

void svm_node_tex_voronoi(uint dimensions, uint feature, uint metric, inout int offset)
{
    int _6758 = offset;
    offset = _6758 + 1;
    uvec4 stack_offsets = push.data_ptr._svm_nodes.data[_6758];
    int _6767 = offset;
    offset = _6767 + 1;
    uvec4 defaults = push.data_ptr._svm_nodes.data[_6767];
    uint coord_stack_offset = stack_offsets.x & 255u;
    uint w_stack_offset = (stack_offsets.x >> uint(8)) & 255u;
    uint scale_stack_offset = (stack_offsets.x >> uint(16)) & 255u;
    uint smoothness_stack_offset = (stack_offsets.x >> uint(24)) & 255u;
    uint exponent_stack_offset = stack_offsets.y & 255u;
    uint randomness_stack_offset = (stack_offsets.y >> uint(8)) & 255u;
    uint distance_out_stack_offset = (stack_offsets.y >> uint(16)) & 255u;
    uint color_out_stack_offset = (stack_offsets.y >> uint(24)) & 255u;
    uint position_out_stack_offset = stack_offsets.z & 255u;
    uint w_out_stack_offset = (stack_offsets.z >> uint(8)) & 255u;
    uint radius_out_stack_offset = (stack_offsets.z >> uint(16)) & 255u;
    nio.type = dimensions;
    nio.type = dimensions;
    nio.data[0] = vec4(stack[coord_stack_offset + 0u], stack[coord_stack_offset + 1u], stack[coord_stack_offset + 2u], 0.0).x;
    nio.data[1] = vec4(stack[coord_stack_offset + 0u], stack[coord_stack_offset + 1u], stack[coord_stack_offset + 2u], 0.0).y;
    nio.data[2] = vec4(stack[coord_stack_offset + 0u], stack[coord_stack_offset + 1u], stack[coord_stack_offset + 2u], 0.0).z;
    float _6874;
    if (w_stack_offset == 255u)
    {
        _6874 = uintBitsToFloat(stack_offsets.w);
    }
    else
    {
        _6874 = stack[w_stack_offset];
    }
    nio.data[3] = _6874;
    float _6888;
    if (scale_stack_offset == 255u)
    {
        _6888 = uintBitsToFloat(defaults.x);
    }
    else
    {
        _6888 = stack[scale_stack_offset];
    }
    nio.data[4] = _6888;
    float _6902;
    if (smoothness_stack_offset == 255u)
    {
        _6902 = uintBitsToFloat(defaults.y);
    }
    else
    {
        _6902 = stack[smoothness_stack_offset];
    }
    nio.data[5] = _6902;
    float _6916;
    if (exponent_stack_offset == 255u)
    {
        _6916 = uintBitsToFloat(defaults.z);
    }
    else
    {
        _6916 = stack[exponent_stack_offset];
    }
    nio.data[6] = _6916;
    float _6930;
    if (randomness_stack_offset == 255u)
    {
        _6930 = uintBitsToFloat(defaults.w);
    }
    else
    {
        _6930 = stack[randomness_stack_offset];
    }
    nio.data[7] = _6930;
    nio.data[8] = uintBitsToFloat(feature);
    nio.data[9] = uintBitsToFloat(metric);
    executeCallableNV(6u, 2);
    if (distance_out_stack_offset != 255u)
    {
        stack[distance_out_stack_offset] = nio.data[5];
    }
    if (color_out_stack_offset != 255u)
    {
        stack[color_out_stack_offset + 0u] = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0).x;
        stack[color_out_stack_offset + 1u] = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0).y;
        stack[color_out_stack_offset + 2u] = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0).z;
    }
    if (position_out_stack_offset != 255u)
    {
        stack[position_out_stack_offset + 0u] = vec4(nio.data[6], nio.data[7], nio.data[8], 0.0).x;
        stack[position_out_stack_offset + 1u] = vec4(nio.data[6], nio.data[7], nio.data[8], 0.0).y;
        stack[position_out_stack_offset + 2u] = vec4(nio.data[6], nio.data[7], nio.data[8], 0.0).z;
    }
    if (w_out_stack_offset != 255u)
    {
        stack[w_out_stack_offset] = nio.data[3];
    }
    if (radius_out_stack_offset != 255u)
    {
        stack[radius_out_stack_offset] = nio.data[4];
    }
}

void svm_node_tex_wave(uvec4 node, inout int offset)
{
    nio.type = 1u;
    int _6532 = offset;
    offset = _6532 + 1;
    uvec4 node2 = push.data_ptr._svm_nodes.data[_6532];
    int _6541 = offset;
    offset = _6541 + 1;
    uvec4 node3 = push.data_ptr._svm_nodes.data[_6541];
    nio.data[9] = uintBitsToFloat(node.y);
    uint co_offset = node.z & 255u;
    uint scale_offset = (node.z >> uint(8)) & 255u;
    uint distortion_offset = (node.z >> uint(16)) & 255u;
    uint detail_offset = node.w & 255u;
    uint dscale_offset = (node.w >> uint(8)) & 255u;
    uint droughness_offset = (node.w >> uint(16)) & 255u;
    uint phase_offset = (node.w >> uint(24)) & 255u;
    uint color_offset = node2.x & 255u;
    uint fac_offset = (node2.x >> uint(8)) & 255u;
    nio.data[0] = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0).x;
    nio.data[1] = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0).y;
    nio.data[2] = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0).z;
    float _6638;
    if (scale_offset == 255u)
    {
        _6638 = uintBitsToFloat(node2.y);
    }
    else
    {
        _6638 = stack[scale_offset];
    }
    nio.data[3] = _6638;
    float _6652;
    if (distortion_offset == 255u)
    {
        _6652 = uintBitsToFloat(node2.z);
    }
    else
    {
        _6652 = stack[distortion_offset];
    }
    nio.data[4] = _6652;
    float _6666;
    if (detail_offset == 255u)
    {
        _6666 = uintBitsToFloat(node2.w);
    }
    else
    {
        _6666 = stack[detail_offset];
    }
    nio.data[5] = _6666;
    float _6680;
    if (dscale_offset == 255u)
    {
        _6680 = uintBitsToFloat(node3.x);
    }
    else
    {
        _6680 = stack[dscale_offset];
    }
    nio.data[6] = _6680;
    float _6694;
    if (droughness_offset == 255u)
    {
        _6694 = uintBitsToFloat(node3.y);
    }
    else
    {
        _6694 = stack[droughness_offset];
    }
    nio.data[7] = _6694;
    float _6708;
    if (phase_offset == 255u)
    {
        _6708 = uintBitsToFloat(node3.z);
    }
    else
    {
        _6708 = stack[phase_offset];
    }
    nio.data[8] = _6708;
    executeCallableNV(5u, 2);
    if (fac_offset != 255u)
    {
        stack[fac_offset] = nio.data[0];
    }
    if (color_offset != 255u)
    {
        stack[color_offset + 0u] = vec4(nio.data[0]).x;
        stack[color_offset + 1u] = vec4(nio.data[0]).y;
        stack[color_offset + 2u] = vec4(nio.data[0]).z;
    }
}

void svm_node_tex_checker(uvec4 node)
{
    uint co_offset = node.y & 255u;
    uint color1_offset = (node.y >> uint(8)) & 255u;
    uint color2_offset = (node.y >> uint(16)) & 255u;
    uint scale_offset = (node.y >> uint(24)) & 255u;
    uint color_offset = node.z & 255u;
    uint fac_offset = (node.z >> uint(8)) & 255u;
    vec4 co = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0);
    vec4 color1 = vec4(stack[color1_offset + 0u], stack[color1_offset + 1u], stack[color1_offset + 2u], 0.0);
    vec4 color2 = vec4(stack[color2_offset + 0u], stack[color2_offset + 1u], stack[color2_offset + 2u], 0.0);
    float _8640;
    if (scale_offset == 255u)
    {
        _8640 = uintBitsToFloat(node.w);
    }
    else
    {
        _8640 = stack[scale_offset];
    }
    float scale = _8640;
    vec4 cscale = co * scale;
    cscale.x = (cscale.x + 9.9999999747524270787835121154785e-07) * 0.999998986721038818359375;
    cscale.y = (cscale.y + 9.9999999747524270787835121154785e-07) * 0.999998986721038818359375;
    cscale.z = (cscale.z + 9.9999999747524270787835121154785e-07) * 0.999998986721038818359375;
    int xi = abs(int(floor(cscale.x)));
    int yi = abs(int(floor(cscale.y)));
    int zi = abs(int(floor(cscale.z)));
    float f = float(((xi % 2) == (yi % 2)) == ((zi % 2) != int(0u)));
    if (color_offset != 255u)
    {
        cscale = (f == 1.0) ? color1 : color2;
        stack[color_offset + 0u] = cscale.x;
        stack[color_offset + 1u] = cscale.y;
        stack[color_offset + 2u] = cscale.z;
    }
    if (fac_offset != 255u)
    {
        stack[fac_offset] = f;
    }
}

void svm_node_tex_musgrave(uint offsets1, uint offsets2, uint offsets3, inout int offset)
{
    uint type = offsets1 & 255u;
    uint dimensions = (offsets1 >> uint(8)) & 255u;
    uint co_stack_offset = (offsets1 >> uint(16)) & 255u;
    uint w_stack_offset = (offsets1 >> uint(24)) & 255u;
    uint scale_stack_offset = offsets2 & 255u;
    uint detail_stack_offset = (offsets2 >> uint(8)) & 255u;
    uint dimension_stack_offset = (offsets2 >> uint(16)) & 255u;
    uint lacunarity_stack_offset = (offsets2 >> uint(24)) & 255u;
    uint offset_stack_offset = offsets3 & 255u;
    uint gain_stack_offset = (offsets3 >> uint(8)) & 255u;
    uint fac_stack_offset = (offsets3 >> uint(16)) & 255u;
    nio.data[10] = uintBitsToFloat(dimensions);
    nio.type = type;
    int _7097 = offset;
    offset = _7097 + 1;
    uvec4 defaults1 = push.data_ptr._svm_nodes.data[_7097];
    int _7106 = offset;
    offset = _7106 + 1;
    uvec4 defaults2 = push.data_ptr._svm_nodes.data[_7106];
    nio.data[0] = vec4(stack[co_stack_offset + 0u], stack[co_stack_offset + 1u], stack[co_stack_offset + 2u], 0.0).x;
    nio.data[1] = vec4(stack[co_stack_offset + 0u], stack[co_stack_offset + 1u], stack[co_stack_offset + 2u], 0.0).y;
    nio.data[2] = vec4(stack[co_stack_offset + 0u], stack[co_stack_offset + 1u], stack[co_stack_offset + 2u], 0.0).z;
    float _7157;
    if (w_stack_offset == 255u)
    {
        _7157 = uintBitsToFloat(defaults1.x);
    }
    else
    {
        _7157 = stack[w_stack_offset];
    }
    nio.data[3] = _7157;
    float _7171;
    if (scale_stack_offset == 255u)
    {
        _7171 = uintBitsToFloat(defaults1.y);
    }
    else
    {
        _7171 = stack[scale_stack_offset];
    }
    nio.data[4] = _7171;
    float _7185;
    if (detail_stack_offset == 255u)
    {
        _7185 = uintBitsToFloat(defaults1.z);
    }
    else
    {
        _7185 = stack[detail_stack_offset];
    }
    nio.data[5] = _7185;
    float _7199;
    if (dimension_stack_offset == 255u)
    {
        _7199 = uintBitsToFloat(defaults1.w);
    }
    else
    {
        _7199 = stack[dimension_stack_offset];
    }
    nio.data[6] = _7199;
    float _7213;
    if (lacunarity_stack_offset == 255u)
    {
        _7213 = uintBitsToFloat(defaults2.x);
    }
    else
    {
        _7213 = stack[lacunarity_stack_offset];
    }
    nio.data[7] = _7213;
    float _7227;
    if (offset_stack_offset == 255u)
    {
        _7227 = uintBitsToFloat(defaults2.y);
    }
    else
    {
        _7227 = stack[offset_stack_offset];
    }
    nio.data[8] = _7227;
    float _7241;
    if (gain_stack_offset == 255u)
    {
        _7241 = uintBitsToFloat(defaults2.z);
    }
    else
    {
        _7241 = stack[gain_stack_offset];
    }
    nio.data[9] = _7241;
    executeCallableNV(8u, 2);
    stack[fac_stack_offset] = nio.data[0];
}

void svm_node_tex_sky(uvec4 node, inout int offset)
{
    nio.offset = offset;
    nio.type = 2u;
    nio.data[0] = vec4(stack[node.y + 0u], stack[node.y + 1u], stack[node.y + 2u], 0.0).x;
    nio.data[1] = vec4(stack[node.y + 0u], stack[node.y + 1u], stack[node.y + 2u], 0.0).y;
    nio.data[2] = vec4(stack[node.y + 0u], stack[node.y + 1u], stack[node.y + 2u], 0.0).z;
    nio.data[4] = uintBitsToFloat(node.x);
    nio.data[5] = uintBitsToFloat(node.y);
    nio.data[6] = uintBitsToFloat(node.z);
    nio.data[7] = uintBitsToFloat(node.w);
    executeCallableNV(9u, 2);
    stack[node.z + 0u] = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]).x;
    stack[node.z + 1u] = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]).y;
    stack[node.z + 2u] = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]).z;
    offset = nio.offset;
}

void svm_node_tex_environment(uvec4 node)
{
    uint id = node.y;
    uint co_offset = node.z & 255u;
    uint out_offset = (node.z >> uint(8)) & 255u;
    uint alpha_offset = (node.z >> uint(16)) & 255u;
    uint flags = (node.z >> uint(24)) & 255u;
    nio.data[0] = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0).x;
    nio.data[1] = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0).y;
    nio.data[2] = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0).z;
    nio.data[4] = uintBitsToFloat(node.w);
    nio.data[5] = uintBitsToFloat(id);
    nio.data[6] = uintBitsToFloat(flags);
    nio.type = 3u;
    executeCallableNV(9u, 2);
    vec4 f = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
    if (out_offset != 255u)
    {
        stack[out_offset + 0u] = vec4(f.x, f.y, f.z, 0.0).x;
        stack[out_offset + 1u] = vec4(f.x, f.y, f.z, 0.0).y;
        stack[out_offset + 2u] = vec4(f.x, f.y, f.z, 0.0).z;
    }
    if (alpha_offset != 255u)
    {
        stack[alpha_offset] = f.w;
    }
}

float smootherstep(float edge0, float edge1, inout float x)
{
    float param = x - edge0;
    float param_1 = edge1 - edge0;
    x = clamp(safe_divide(param, param_1), 0.0, 1.0);
    return ((x * x) * x) * ((x * ((x * 6.0) - 15.0)) + 10.0);
}

void svm_node_map_range(uint value_stack_offset, uint parameters_stack_offsets, uint results_stack_offsets, inout int offset)
{
    uint from_min_stack_offset = parameters_stack_offsets & 255u;
    uint from_max_stack_offset = (parameters_stack_offsets >> uint(8)) & 255u;
    uint to_min_stack_offset = (parameters_stack_offsets >> uint(16)) & 255u;
    uint to_max_stack_offset = (parameters_stack_offsets >> uint(24)) & 255u;
    uint type_stack_offset = results_stack_offsets & 255u;
    uint steps_stack_offset = (results_stack_offsets >> uint(8)) & 255u;
    uint result_stack_offset = (results_stack_offsets >> uint(16)) & 255u;
    int _5348 = offset;
    offset = _5348 + 1;
    uvec4 defaults = push.data_ptr._svm_nodes.data[_5348];
    int _5357 = offset;
    offset = _5357 + 1;
    uvec4 defaults2 = push.data_ptr._svm_nodes.data[_5357];
    float value = stack[value_stack_offset];
    float _5368;
    if (from_min_stack_offset == 255u)
    {
        _5368 = uintBitsToFloat(defaults.x);
    }
    else
    {
        _5368 = stack[from_min_stack_offset];
    }
    float from_min = _5368;
    float _5382;
    if (from_max_stack_offset == 255u)
    {
        _5382 = uintBitsToFloat(defaults.y);
    }
    else
    {
        _5382 = stack[from_max_stack_offset];
    }
    float from_max = _5382;
    float _5396;
    if (to_min_stack_offset == 255u)
    {
        _5396 = uintBitsToFloat(defaults.z);
    }
    else
    {
        _5396 = stack[to_min_stack_offset];
    }
    float to_min = _5396;
    float _5410;
    if (to_max_stack_offset == 255u)
    {
        _5410 = uintBitsToFloat(defaults.w);
    }
    else
    {
        _5410 = stack[to_max_stack_offset];
    }
    float to_max = _5410;
    float _5424;
    if (steps_stack_offset == 255u)
    {
        _5424 = uintBitsToFloat(defaults2.x);
    }
    else
    {
        _5424 = stack[steps_stack_offset];
    }
    float steps = _5424;
    float result;
    if (!(from_max == from_min))
    {
        float factor = value;
        switch (type_stack_offset)
        {
            case 1u:
            {
                factor = (value - from_min) / (from_max - from_min);
                float _5465;
                if (steps > 0.0)
                {
                    _5465 = floor(factor * (steps + 1.0)) / steps;
                }
                else
                {
                    _5465 = 0.0;
                }
                factor = _5465;
                break;
            }
            case 2u:
            {
                float _5481;
                if (from_min > from_max)
                {
                    _5481 = 1.0 - smoothstep(from_max, from_min, factor);
                }
                else
                {
                    _5481 = smoothstep(from_min, from_max, factor);
                }
                factor = _5481;
                break;
            }
            case 3u:
            {
                float _5499;
                if (from_min > from_max)
                {
                    float param = from_max;
                    float param_1 = from_min;
                    float param_2 = factor;
                    float _5508 = smootherstep(param, param_1, param_2);
                    _5499 = 1.0 - _5508;
                }
                else
                {
                    float param_3 = from_min;
                    float param_4 = from_max;
                    float param_5 = factor;
                    float _5517 = smootherstep(param_3, param_4, param_5);
                    _5499 = _5517;
                }
                factor = _5499;
                break;
            }
            default:
            {
                factor = (value - from_min) / (from_max - from_min);
                break;
            }
        }
        result = to_min + (factor * (to_max - to_min));
    }
    else
    {
        result = 0.0;
    }
    stack[result_stack_offset] = result;
}

vec4 svm_mix_blend(float t, vec4 col1, vec4 col2)
{
    return mix(col1, col2, vec4(t));
}

vec4 svm_mix_add(float t, vec4 col1, vec4 col2)
{
    return mix(col1, col1 + col2, vec4(t));
}

vec4 svm_mix_mul(float t, vec4 col1, vec4 col2)
{
    return mix(col1, col1 * col2, vec4(t));
}

vec4 svm_mix_screen(float t, vec4 col1, vec4 col2)
{
    float tm = 1.0 - t;
    vec4 one = vec4(1.0, 1.0, 1.0, 0.0);
    vec4 tm3 = vec4(tm, tm, tm, 0.0);
    return one - ((tm3 + ((one - col2) * t)) * (one - col1));
}

vec4 svm_mix_overlay(float t, vec4 col1, vec4 col2)
{
    float tm = 1.0 - t;
    vec4 outcol = col1;
    if (outcol.x < 0.5)
    {
        outcol.x *= (tm + ((2.0 * t) * col2.x));
    }
    else
    {
        outcol.x = 1.0 - ((tm + ((2.0 * t) * (1.0 - col2.x))) * (1.0 - outcol.x));
    }
    if (outcol.y < 0.5)
    {
        outcol.y *= (tm + ((2.0 * t) * col2.y));
    }
    else
    {
        outcol.y = 1.0 - ((tm + ((2.0 * t) * (1.0 - col2.y))) * (1.0 - outcol.y));
    }
    if (outcol.z < 0.5)
    {
        outcol.z *= (tm + ((2.0 * t) * col2.z));
    }
    else
    {
        outcol.z = 1.0 - ((tm + ((2.0 * t) * (1.0 - col2.z))) * (1.0 - outcol.z));
    }
    return outcol;
}

vec4 svm_mix_sub(float t, vec4 col1, vec4 col2)
{
    return mix(col1, col1 - col2, vec4(t));
}

vec4 svm_mix_div(float t, vec4 col1, vec4 col2)
{
    float tm = 1.0 - t;
    vec4 outcol = col1;
    if (!(col2.x == 0.0))
    {
        outcol.x = (tm * outcol.x) + ((t * outcol.x) / col2.x);
    }
    if (!(col2.y == 0.0))
    {
        outcol.y = (tm * outcol.y) + ((t * outcol.y) / col2.y);
    }
    if (!(col2.z == 0.0))
    {
        outcol.z = (tm * outcol.z) + ((t * outcol.z) / col2.z);
    }
    return outcol;
}

vec4 svm_mix_diff(float t, vec4 col1, vec4 col2)
{
    return mix(col1, abs(col1 - col2), vec4(t));
}

vec4 svm_mix_dark(float t, vec4 col1, vec4 col2)
{
    return mix(col1, min(col1, col2), vec4(t));
}

vec4 svm_mix_light(float t, vec4 col1, vec4 col2)
{
    return mix(col1, max(col1, col2), vec4(t));
}

vec4 svm_mix_dodge(float t, vec4 col1, vec4 col2)
{
    vec4 outcol = col1;
    if (!(outcol.x == 0.0))
    {
        float tmp = 1.0 - (t * col2.x);
        if (tmp <= 0.0)
        {
            outcol.x = 1.0;
        }
        else
        {
            float _3962 = tmp;
            float _3963 = outcol.x / _3962;
            tmp = _3963;
            if (_3963 > 1.0)
            {
                outcol.x = 1.0;
            }
            else
            {
                outcol.x = tmp;
            }
        }
    }
    if (!(outcol.y == 0.0))
    {
        float tmp_1 = 1.0 - (t * col2.y);
        if (tmp_1 <= 0.0)
        {
            outcol.y = 1.0;
        }
        else
        {
            float _3990 = tmp_1;
            float _3991 = outcol.y / _3990;
            tmp_1 = _3991;
            if (_3991 > 1.0)
            {
                outcol.y = 1.0;
            }
            else
            {
                outcol.y = tmp_1;
            }
        }
    }
    if (!(outcol.z == 0.0))
    {
        float tmp_2 = 1.0 - (t * col2.z);
        if (tmp_2 <= 0.0)
        {
            outcol.z = 1.0;
        }
        else
        {
            float _4018 = tmp_2;
            float _4019 = outcol.z / _4018;
            tmp_2 = _4019;
            if (_4019 > 1.0)
            {
                outcol.z = 1.0;
            }
            else
            {
                outcol.z = tmp_2;
            }
        }
    }
    return outcol;
}

vec4 svm_mix_burn(float t, vec4 col1, vec4 col2)
{
    float tm = 1.0 - t;
    vec4 outcol = col1;
    float tmp = tm + (t * col2.x);
    if (tmp <= 0.0)
    {
        outcol.x = 0.0;
    }
    else
    {
        float _4051 = tmp;
        float _4053 = 1.0 - ((1.0 - outcol.x) / _4051);
        tmp = _4053;
        if (_4053 < 0.0)
        {
            outcol.x = 0.0;
        }
        else
        {
            if (tmp > 1.0)
            {
                outcol.x = 1.0;
            }
            else
            {
                outcol.x = tmp;
            }
        }
    }
    tmp = tm + (t * col2.y);
    if (tmp <= 0.0)
    {
        outcol.y = 0.0;
    }
    else
    {
        float _4082 = tmp;
        float _4084 = 1.0 - ((1.0 - outcol.y) / _4082);
        tmp = _4084;
        if (_4084 < 0.0)
        {
            outcol.y = 0.0;
        }
        else
        {
            if (tmp > 1.0)
            {
                outcol.y = 1.0;
            }
            else
            {
                outcol.y = tmp;
            }
        }
    }
    tmp = tm + (t * col2.z);
    if (tmp <= 0.0)
    {
        outcol.z = 0.0;
    }
    else
    {
        float _4113 = tmp;
        float _4115 = 1.0 - ((1.0 - outcol.z) / _4113);
        tmp = _4115;
        if (_4115 < 0.0)
        {
            outcol.z = 0.0;
        }
        else
        {
            if (tmp > 1.0)
            {
                outcol.z = 1.0;
            }
            else
            {
                outcol.z = tmp;
            }
        }
    }
    return outcol;
}

vec4 svm_mix_hue(float t, vec4 col1, vec4 col2)
{
    vec4 outcol = col1;
    vec4 param = col2;
    vec4 hsv2 = rgb_to_hsv(param);
    if (!(hsv2.y == 0.0))
    {
        vec4 param_1 = outcol;
        vec4 hsv = rgb_to_hsv(param_1);
        hsv.x = hsv2.x;
        vec4 param_2 = hsv;
        vec4 tmp = hsv_to_rgb(param_2);
        outcol = mix(outcol, tmp, vec4(t));
    }
    return outcol;
}

vec4 svm_mix_sat(float t, vec4 col1, vec4 col2)
{
    float tm = 1.0 - t;
    vec4 outcol = col1;
    vec4 param = outcol;
    vec4 hsv = rgb_to_hsv(param);
    if (!(hsv.y == 0.0))
    {
        vec4 param_1 = col2;
        vec4 hsv2 = rgb_to_hsv(param_1);
        hsv.y = (tm * hsv.y) + (t * hsv2.y);
        vec4 param_2 = hsv;
        outcol = hsv_to_rgb(param_2);
    }
    return outcol;
}

vec4 svm_mix_val(float t, vec4 col1, vec4 col2)
{
    float tm = 1.0 - t;
    vec4 param = col1;
    vec4 hsv = rgb_to_hsv(param);
    vec4 param_1 = col2;
    vec4 hsv2 = rgb_to_hsv(param_1);
    hsv.z = (tm * hsv.z) + (t * hsv2.z);
    vec4 param_2 = hsv;
    return hsv_to_rgb(param_2);
}

vec4 svm_mix_color(float t, vec4 col1, vec4 col2)
{
    vec4 outcol = col1;
    vec4 param = col2;
    vec4 hsv2 = rgb_to_hsv(param);
    if (!(hsv2.y == 0.0))
    {
        vec4 param_1 = outcol;
        vec4 hsv = rgb_to_hsv(param_1);
        hsv.x = hsv2.x;
        hsv.y = hsv2.y;
        vec4 param_2 = hsv;
        vec4 tmp = hsv_to_rgb(param_2);
        outcol = mix(outcol, tmp, vec4(t));
    }
    return outcol;
}

vec4 svm_mix_soft(float t, vec4 col1, vec4 col2)
{
    float tm = 1.0 - t;
    vec4 one = vec4(1.0, 1.0, 1.0, 0.0);
    vec4 scr = one - ((one - col2) * (one - col1));
    return (col1 * tm) + (((((one - col1) * col2) * col1) + (col1 * scr)) * t);
}

vec4 svm_mix_linear(float t, vec4 col1, vec4 col2)
{
    return col1 + (((col2 * 2.0) + vec4(-1.0, -1.0, -1.0, 0.0)) * t);
}

vec4 svm_mix_clamp(vec4 col)
{
    vec4 param = col;
    return saturate3(param);
}

vec4 svm_mix(uint type, float fac, vec4 c1, vec4 c2)
{
    float t = clamp(fac, 0.0, 1.0);
    switch (type)
    {
        case 0u:
        {
            float param = t;
            vec4 param_1 = c1;
            vec4 param_2 = c2;
            return svm_mix_blend(param, param_1, param_2);
        }
        case 1u:
        {
            float param_3 = t;
            vec4 param_4 = c1;
            vec4 param_5 = c2;
            return svm_mix_add(param_3, param_4, param_5);
        }
        case 2u:
        {
            float param_6 = t;
            vec4 param_7 = c1;
            vec4 param_8 = c2;
            return svm_mix_mul(param_6, param_7, param_8);
        }
        case 4u:
        {
            float param_9 = t;
            vec4 param_10 = c1;
            vec4 param_11 = c2;
            return svm_mix_screen(param_9, param_10, param_11);
        }
        case 9u:
        {
            float param_12 = t;
            vec4 param_13 = c1;
            vec4 param_14 = c2;
            return svm_mix_overlay(param_12, param_13, param_14);
        }
        case 3u:
        {
            float param_15 = t;
            vec4 param_16 = c1;
            vec4 param_17 = c2;
            return svm_mix_sub(param_15, param_16, param_17);
        }
        case 5u:
        {
            float param_18 = t;
            vec4 param_19 = c1;
            vec4 param_20 = c2;
            return svm_mix_div(param_18, param_19, param_20);
        }
        case 6u:
        {
            float param_21 = t;
            vec4 param_22 = c1;
            vec4 param_23 = c2;
            return svm_mix_diff(param_21, param_22, param_23);
        }
        case 7u:
        {
            float param_24 = t;
            vec4 param_25 = c1;
            vec4 param_26 = c2;
            return svm_mix_dark(param_24, param_25, param_26);
        }
        case 8u:
        {
            float param_27 = t;
            vec4 param_28 = c1;
            vec4 param_29 = c2;
            return svm_mix_light(param_27, param_28, param_29);
        }
        case 10u:
        {
            float param_30 = t;
            vec4 param_31 = c1;
            vec4 param_32 = c2;
            return svm_mix_dodge(param_30, param_31, param_32);
        }
        case 11u:
        {
            float param_33 = t;
            vec4 param_34 = c1;
            vec4 param_35 = c2;
            return svm_mix_burn(param_33, param_34, param_35);
        }
        case 12u:
        {
            float param_36 = t;
            vec4 param_37 = c1;
            vec4 param_38 = c2;
            return svm_mix_hue(param_36, param_37, param_38);
        }
        case 13u:
        {
            float param_39 = t;
            vec4 param_40 = c1;
            vec4 param_41 = c2;
            return svm_mix_sat(param_39, param_40, param_41);
        }
        case 14u:
        {
            float param_42 = t;
            vec4 param_43 = c1;
            vec4 param_44 = c2;
            return svm_mix_val(param_42, param_43, param_44);
        }
        case 15u:
        {
            float param_45 = t;
            vec4 param_46 = c1;
            vec4 param_47 = c2;
            return svm_mix_color(param_45, param_46, param_47);
        }
        case 16u:
        {
            float param_48 = t;
            vec4 param_49 = c1;
            vec4 param_50 = c2;
            return svm_mix_soft(param_48, param_49, param_50);
        }
        case 17u:
        {
            float param_51 = t;
            vec4 param_52 = c1;
            vec4 param_53 = c2;
            return svm_mix_linear(param_51, param_52, param_53);
        }
        case 18u:
        {
            vec4 param_54 = c1;
            return svm_mix_clamp(param_54);
        }
    }
    return vec4(0.0);
}

void svm_node_mix(uint fac_offset, uint c1_offset, uint c2_offset, inout int offset)
{
    int _4518 = offset;
    offset = _4518 + 1;
    uvec4 node1 = push.data_ptr._svm_nodes.data[_4518];
    float fac = stack[fac_offset];
    vec4 c1 = vec4(stack[c1_offset + 0u], stack[c1_offset + 1u], stack[c1_offset + 2u], 0.0);
    vec4 c2 = vec4(stack[c2_offset + 0u], stack[c2_offset + 1u], stack[c2_offset + 2u], 0.0);
    uint param = node1.y;
    float param_1 = fac;
    vec4 param_2 = c1;
    vec4 param_3 = c2;
    vec4 result = svm_mix(param, param_1, param_2, param_3);
    stack[node1.z + 0u] = result.x;
    stack[node1.z + 1u] = result.y;
    stack[node1.z + 2u] = result.z;
}

void svm_eval_nodes(uint type, int path_flag)
{
    int offset = int(uint(sd.shader) & 8388607u);
    float _11242;
    float value;
    vec4 vector;
    while (true)
    {
        int _11091 = offset;
        offset = _11091 + 1;
        uvec4 node = push.data_ptr._svm_nodes.data[_11091];
        switch (node.x)
        {
            case 0u:
            {
                return;
            }
            case 1u:
            {
                offset = int(node.y);
                break;
            }
            case 2u:
            {
                uvec4 param = node;
                uint param_1 = type;
                int param_2 = path_flag;
                int param_3 = offset;
                svm_node_closure_bsdf(param, param_1, param_2, param_3);
                offset = param_3;
                break;
            }
            case 3u:
            {
                uvec4 param_4 = node;
                svm_node_closure_emission(param_4);
                break;
            }
            case 4u:
            {
                uvec4 param_5 = node;
                svm_node_closure_background(param_5);
                break;
            }
            case 5u:
            {
                sd.svm_closure_weight = vec4(uintBitsToFloat(node.y), uintBitsToFloat(node.z), uintBitsToFloat(node.w), 0.0);
                break;
            }
            case 6u:
            {
                sd.svm_closure_weight = vec4(stack[node.y + 0u], stack[node.y + 1u], stack[node.y + 2u], 0.0);
                break;
            }
            case 7u:
            {
                sd.svm_closure_weight = vec4(stack[node.y + 0u], stack[node.y + 1u], stack[node.y + 2u], 0.0) * stack[node.z];
                break;
            }
            case 8u:
            {
                uint weight_offset = node.y & 255u;
                uint in_weight_offset = (node.y >> uint(8)) & 255u;
                uint weight1_offset = (node.y >> uint(16)) & 255u;
                uint weight2_offset = (node.y >> uint(24)) & 255u;
                float weight = stack[weight_offset];
                weight = clamp(weight, 0.0, 1.0);
                if (in_weight_offset != 255u)
                {
                    _11242 = stack[in_weight_offset];
                }
                else
                {
                    _11242 = 1.0;
                }
                float in_weight = _11242;
                if (weight1_offset != 255u)
                {
                    stack[weight1_offset] = in_weight * (1.0 - weight);
                }
                if (weight2_offset != 255u)
                {
                    stack[weight2_offset] = in_weight * weight;
                }
                break;
            }
            case 9u:
            {
                if (stack[node.z] == 0.0)
                {
                    offset += int(node.y);
                }
                break;
            }
            case 10u:
            {
                if (stack[node.z] == 1.0)
                {
                    offset += int(node.y);
                }
                break;
            }
            case 11u:
            {
                uint param_6 = node.y;
                uint param_7 = node.z;
                svm_node_geometry(param_6, param_7);
                break;
            }
            case 12u:
            {
                uint param_8 = node.y;
                uint param_9 = node.z;
                uint param_10 = node.w;
                svm_node_convert(param_8, param_9, param_10);
                break;
            }
            case 13u:
            {
                int param_11 = path_flag;
                uvec4 param_12 = node;
                int param_13 = offset;
                svm_node_tex_coord(param_11, param_12, param_13);
                offset = param_13;
                break;
            }
            case 14u:
            {
                stack[node.z] = uintBitsToFloat(node.y);
                break;
            }
            case 15u:
            {
                int _11336 = offset;
                offset = _11336 + 1;
                uvec4 node1 = push.data_ptr._svm_nodes.data[_11336];
                stack[node.y + 0u] = vec4(uintBitsToFloat(node1.y), uintBitsToFloat(node1.z), uintBitsToFloat(node1.w), 0.0).x;
                stack[node.y + 1u] = vec4(uintBitsToFloat(node1.y), uintBitsToFloat(node1.z), uintBitsToFloat(node1.w), 0.0).y;
                stack[node.y + 2u] = vec4(uintBitsToFloat(node1.y), uintBitsToFloat(node1.z), uintBitsToFloat(node1.w), 0.0).z;
                break;
            }
            case 16u:
            {
                uvec4 param_14 = node;
                svm_node_attr(param_14);
                break;
            }
            case 36u:
            {
                uvec4 param_15 = node;
                int param_16 = offset;
                svm_node_hsv(param_15, param_16);
                offset = param_16;
                break;
            }
            case 23u:
            {
                uvec4 param_17 = node;
                int param_18 = offset;
                svm_node_tex_image(param_17, param_18);
                offset = param_18;
                break;
            }
            case 44u:
            {
                uvec4 param_19 = node;
                int param_20 = offset;
                svm_node_rgb_ramp(param_19, param_20);
                offset = param_20;
                break;
            }
            case 42u:
            {
                uint a_stack_offset = node.z & 255u;
                uint b_stack_offset = (node.z >> uint(8)) & 255u;
                uint c_stack_offset = (node.z >> uint(16)) & 255u;
                uint param_21 = node.y;
                float param_22 = stack[a_stack_offset];
                float param_23 = stack[b_stack_offset];
                float param_24 = stack[c_stack_offset];
                stack[node.w] = svm_math(param_21, param_22, param_23, param_24);
                break;
            }
            case 43u:
            {
                uint a_stack_offset_1 = node.z & 255u;
                uint b_stack_offset_1 = (node.z >> uint(8)) & 255u;
                uint scale_stack_offset = (node.z >> uint(16)) & 255u;
                uint value_stack_offset = node.w & 255u;
                uint vector_stack_offset = (node.w >> uint(8)) & 255u;
                vec4 c = vec4(0.0);
                if (node.y == 20u)
                {
                    int _11480 = offset;
                    offset = _11480 + 1;
                    uvec4 extra_node = push.data_ptr._svm_nodes.data[_11480];
                    c = vec4(stack[extra_node.x + 0u], stack[extra_node.x + 1u], stack[extra_node.x + 2u], 0.0);
                }
                float param_25 = value;
                vec4 param_26 = vector;
                uint param_27 = node.y;
                vec4 param_28 = vec4(stack[a_stack_offset_1 + 0u], stack[a_stack_offset_1 + 1u], stack[a_stack_offset_1 + 2u], 0.0);
                vec4 param_29 = vec4(stack[b_stack_offset_1 + 0u], stack[b_stack_offset_1 + 1u], stack[b_stack_offset_1 + 2u], 0.0);
                vec4 param_30 = c;
                float param_31 = stack[scale_stack_offset];
                svm_vector_math(param_25, param_26, param_27, param_28, param_29, param_30, param_31);
                value = param_25;
                vector = param_26;
                if (value_stack_offset != 255u)
                {
                    stack[value_stack_offset] = value;
                }
                if (vector_stack_offset != 255u)
                {
                    stack[vector_stack_offset + 0u] = vector.x;
                    stack[vector_stack_offset + 1u] = vector.y;
                    stack[vector_stack_offset + 2u] = vector.z;
                }
                break;
            }
            case 45u:
            {
                vec4 color = vec4(stack[node.z + 0u], stack[node.z + 1u], stack[node.z + 2u], 0.0);
                float gamma = stack[node.y];
                vec4 param_32 = color;
                float param_33 = gamma;
                vec4 _11599 = svm_math_gamma_color(param_32, param_33);
                color = _11599;
                if (node.w != 255u)
                {
                    stack[node.w + 0u] = color.x;
                    stack[node.w + 1u] = color.y;
                    stack[node.w + 2u] = color.z;
                }
                break;
            }
            case 46u:
            {
                vec4 color_1 = vec4(stack[node.y + 0u], stack[node.y + 1u], stack[node.y + 2u], 0.0);
                uint bright_offset = node.w & 255u;
                uint contrast_offset = (node.w >> uint(8)) & 255u;
                vec4 param_34 = color_1;
                float param_35 = stack[bright_offset];
                float param_36 = stack[contrast_offset];
                vec4 _11660 = svm_brightness_contrast(param_34, param_35, param_36);
                color_1 = _11660;
                if (node.z != 255u)
                {
                    stack[node.z + 0u] = color_1.x;
                    stack[node.z + 1u] = color_1.y;
                    stack[node.z + 2u] = color_1.z;
                }
                break;
            }
            case 48u:
            {
                uint param_37 = node.y;
                uint param_38 = node.z;
                svm_node_object_info(param_37, param_38);
                break;
            }
            case 49u:
            {
                uint param_39 = node.y;
                uint param_40 = node.z;
                svm_node_particle_info(param_39, param_40);
                break;
            }
            case 52u:
            {
                uint param_41 = node.y;
                uint param_42 = node.z;
                uint param_43 = node.w;
                int param_44 = offset;
                svm_node_mapping(param_41, param_42, param_43, param_44);
                offset = param_44;
                break;
            }
            case 25u:
            {
                uint param_45 = node.y;
                uint param_46 = node.z;
                uint param_47 = node.w;
                int param_48 = offset;
                svm_node_tex_noise(param_45, param_46, param_47, param_48);
                offset = param_48;
                break;
            }
            case 58u:
            {
                uint param_49 = node.y;
                uint param_50 = node.z;
                uint param_51 = node.w;
                int param_52 = offset;
                svm_node_tex_voronoi(param_49, param_50, param_51, param_52);
                offset = param_52;
                break;
            }
            case 60u:
            {
                uvec4 param_53 = node;
                int param_54 = offset;
                svm_node_tex_wave(param_53, param_54);
                offset = param_54;
                break;
            }
            case 62u:
            {
                uvec4 param_55 = node;
                svm_node_tex_checker(param_55);
                break;
            }
            case 59u:
            {
                uint param_56 = node.y;
                uint param_57 = node.z;
                uint param_58 = node.w;
                int param_59 = offset;
                svm_node_tex_musgrave(param_56, param_57, param_58, param_59);
                offset = param_59;
                break;
            }
            case 56u:
            {
                uvec4 param_60 = node;
                int param_61 = offset;
                svm_node_tex_sky(param_60, param_61);
                offset = param_61;
                break;
            }
            case 55u:
            {
                uvec4 param_62 = node;
                svm_node_tex_environment(param_62);
                break;
            }
            case 83u:
            {
                uint param_63 = node.y;
                uint param_64 = node.z;
                uint param_65 = node.w;
                int param_66 = offset;
                svm_node_map_range(param_63, param_64, param_65, param_66);
                offset = param_66;
                break;
            }
            case 74u:
            {
                vec4 vector_1 = vec4(stack[node.y + 0u], stack[node.y + 1u], stack[node.y + 2u], 0.0);
                if (node.w != 255u)
                {
                    if (node.z == 0u)
                    {
                        stack[node.w] = vector_1.x;
                    }
                    else
                    {
                        if (node.z == 1u)
                        {
                            stack[node.w] = vector_1.y;
                        }
                        else
                        {
                            stack[node.w] = vector_1.z;
                        }
                    }
                }
                break;
            }
            case 75u:
            {
                if (node.w != 255u)
                {
                    stack[node.w + node.z] = stack[node.y];
                }
                break;
            }
            case 73u:
            {
                uint param_67 = node.y;
                uint param_68 = node.z;
                uint param_69 = node.w;
                int param_70 = offset;
                svm_node_mix(param_67, param_68, param_69, param_70);
                offset = param_70;
                break;
            }
            default:
            {
                return;
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
    STIR = double[](0.00078731139579309367734077929057435lf, -0.00022954996161337812548425274528086lf, -0.00268132617805781235317819088948lf, 0.0034722222160545866166680983866399lf, 0.083333333333348219573721848973946lf, 0.0lf, 0.0lf, 0.0lf);
    P = double[](0.0001601195224767518480914890721678lf, 0.0011913514700658638361535635041832lf, 0.010421379756176157860281250577827lf, 0.047636780045713721098987747382125lf, 0.20744822764843598439377103659353lf, 0.49421482680149708688333021200378lf, 1.0lf, 0.0lf);
    Q = double[](-2.315818733241201444485700411402e-05lf, 0.00053960558049330335003007652616702lf, -0.0044564191385179727916687753008773lf, 0.011813978522206043317299695161182lf, 0.03582363986054986487728157840138lf, -0.23459179571824334553653557122743lf, 0.071430491703027301775286161955592lf, 1.0lf);
    A = double[](0.00081161416747050848814054591073841lf, -0.00059506190428430143831567411538686lf, 0.00079365034045771694262011441978188lf, -0.0027777777773009969426720733309821lf, 0.08333333333333318992952598591728lf, 0.0lf, 0.0lf, 0.0lf);
    B = double[](-1378.2515256912085988005856052041lf, -38801.631513463784358464181423187lf, -331612.9927388711948879063129425lf, -1162370.9749276230577379465103149lf, -1721737.0082083966117352247238159lf, -853555.66424576542340219020843506lf, 0.0lf, 0.0lf);
    C = double[](-351.81570143652345450391294434667lf, -17064.210665188114944612607359886lf, -220528.59055385444662533700466156lf, -1139334.4436798251699656248092651lf, -2532523.0717758294194936752319336lf, -2018891.4143353276886045932769775lf, 0.0lf, 0.0lf);
    alloc = true;
    if (sd.num_closure_left < 0)
    {
        float param = sd.randb_closure;
        kernel_path_shader_apply(param);
    }
    else
    {
        int flag = sd.num_closure;
        sd.num_closure = 0;
        PROFI_IDX = sd.alloc_offset;
        sd.alloc_offset = 0;
        uint param_1 = 0u;
        int param_2 = flag;
        svm_eval_nodes(param_1, param_2);
    }
}

