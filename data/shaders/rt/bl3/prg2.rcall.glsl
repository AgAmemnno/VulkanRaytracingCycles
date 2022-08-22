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

struct KernelGlobals_PROF
{
    uvec2 pixel;
    vec4 f3[960];
    float f1[960];
    uint u1[960];
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
} _582;

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _2541;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _11878;

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
bool G_dump;
int rec_num;
uvec2 Dpixel;
double STIR[8];
double P[8];
double Q[8];
double A[8];
double B[8];
double C[8];
float stack[255];
bool G_use_light_pass;
int PROFI_IDX;
ShaderClosure null_sc;

vec4 _3360;

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
        it_next--;
    }
}

void kernel_path_shader_apply(float blur_pdf)
{
    float blur_roughness = sqrt(1.0 - blur_pdf) * 0.5;
    float param = blur_roughness;
    shader_bsdf_blur(param);
}

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

float linear_rgb_to_gray(vec4 c)
{
    return dot(c.xyz, float4_to_float3(_2541.kernel_data.film.rgb_to_y).xyz);
}

void svm_node_closure_bsdf(uvec4 node, uint shader_type, int path_flag, inout int offset)
{
    uint type = node.y & 255u;
    uint param1_offset = (node.y >> uint(8)) & 255u;
    uint param2_offset = (node.y >> uint(16)) & 255u;
    uint mix_weight_offset = (node.y >> uint(24)) & 255u;
    float _9936;
    if (mix_weight_offset != 255u)
    {
        _9936 = stack[mix_weight_offset];
    }
    else
    {
        _9936 = 1.0;
    }
    float mix_weight = _9936;
    int _9949 = offset;
    offset = _9949 + 1;
    uvec4 data_node = push.data_ptr._svm_nodes.data[_9949];
    if ((mix_weight == 0.0) || (shader_type != 0u))
    {
        if (type == 44u)
        {
            offset += 4;
        }
        return;
    }
    vec4 _9972;
    if (data_node.x != 255u)
    {
        _9972 = vec4(stack[data_node.x + 0u], stack[data_node.x + 1u], stack[data_node.x + 2u], 0.0);
    }
    else
    {
        _9972 = sd.N;
    }
    vec4 N = _9972;
    float _9998;
    if (param1_offset != 255u)
    {
        _9998 = stack[param1_offset];
    }
    else
    {
        _9998 = uintBitsToFloat(node.z);
    }
    float param1 = _9998;
    float _10012;
    if (param2_offset != 255u)
    {
        _10012 = stack[param2_offset];
    }
    else
    {
        _10012 = uintBitsToFloat(node.w);
    }
    float param2 = _10012;
    bool caustics = _2541.kernel_data.integrator.caustics_reflective != int(0u);
    if (type == 19u)
    {
        bool _10033 = !caustics;
        bool _10040;
        if (_10033)
        {
            _10040 = (uint(path_flag) & 8u) != 0u;
        }
        else
        {
            _10040 = _10033;
        }
        if (_10040)
        {
            return;
        }
    }
    nio.offset = path_flag;
    nio.type = type;
    uint caus = uint(caustics);
    nio.data[0] = uintBitsToFloat((uint(sd.num_closure_left) & 65535u) | (caus << 16u));
    nio.data[1] = uintBitsToFloat((uint(sd.num_closure) & 65535u) | uint(rec_num << int(16u)));
    nio.data[2] = intBitsToFloat(sd.alloc_offset);
    nio.data[3] = intBitsToFloat(sd.flag);
    nio.data[7] = N.x;
    nio.data[8] = N.y;
    nio.data[9] = N.z;
    nio.data[10] = param1;
    nio.data[11] = param2;
    vec3 v = (sd.svm_closure_weight * mix_weight).xyz;
    nio.data[12] = v.x;
    nio.data[13] = v.y;
    nio.data[14] = v.z;
    bool exec = false;
    bool trans = false;
    switch (type)
    {
        case 44u:
        {
            int _10128 = offset;
            offset = _10128 + 1;
            uvec4 data_node2 = push.data_ptr._svm_nodes.data[_10128];
            nio.data[4] = sd.I.x;
            nio.data[5] = sd.I.y;
            nio.data[6] = sd.I.z;
            vec4 T = vec4(stack[data_node.y + 0u], stack[data_node.y + 1u], stack[data_node.y + 2u], 0.0);
            nio.data[29] = T.x;
            nio.data[30] = T.y;
            nio.data[31] = T.z;
            int _10172 = offset;
            offset = _10172 + 1;
            uvec4 data_base_color = push.data_ptr._svm_nodes.data[_10172];
            vec4 _10180;
            if (data_base_color.x != 255u)
            {
                _10180 = vec4(stack[data_base_color.x + 0u], stack[data_base_color.x + 1u], stack[data_base_color.x + 2u], 0.0);
            }
            else
            {
                _10180 = vec4(uintBitsToFloat(data_base_color.y), uintBitsToFloat(data_base_color.z), uintBitsToFloat(data_base_color.w), 0.0);
            }
            vec4 v_1 = _10180;
            nio.data[32] = v_1.x;
            nio.data[33] = v_1.y;
            nio.data[34] = v_1.z;
            vec4 param = v_1;
            nio.data[35] = linear_rgb_to_gray(param);
            int _10231 = offset;
            offset = _10231 + 1;
            uvec4 data_cn_ssr = push.data_ptr._svm_nodes.data[_10231];
            vec4 _10239;
            if (data_cn_ssr.x != 255u)
            {
                _10239 = vec4(stack[data_cn_ssr.x + 0u], stack[data_cn_ssr.x + 1u], stack[data_cn_ssr.x + 2u], 0.0);
            }
            else
            {
                _10239 = sd.N;
            }
            vec4 clearcoat_normal = _10239;
            nio.data[36] = clearcoat_normal.x;
            nio.data[37] = clearcoat_normal.y;
            nio.data[38] = clearcoat_normal.z;
            vec4 _10278;
            if (data_cn_ssr.y != 255u)
            {
                _10278 = vec4(stack[data_cn_ssr.y + 0u], stack[data_cn_ssr.y + 1u], stack[data_cn_ssr.y + 2u], 0.0);
            }
            else
            {
                _10278 = vec4(1.0, 1.0, 1.0, 0.0);
            }
            vec4 subsurface_radius = _10278;
            nio.data[39] = subsurface_radius.x;
            nio.data[40] = subsurface_radius.y;
            nio.data[41] = subsurface_radius.z;
            int _10316 = offset;
            offset = _10316 + 1;
            uvec4 data_subsurface_color = push.data_ptr._svm_nodes.data[_10316];
            vec4 _10324;
            if (data_subsurface_color.x != 255u)
            {
                _10324 = vec4(stack[data_subsurface_color.x + 0u], stack[data_subsurface_color.x + 1u], stack[data_subsurface_color.x + 2u], 0.0);
            }
            else
            {
                _10324 = vec4(uintBitsToFloat(data_subsurface_color.y), uintBitsToFloat(data_subsurface_color.z), uintBitsToFloat(data_subsurface_color.w), 0.0);
            }
            vec4 subsurface_color = _10324;
            nio.data[42] = subsurface_color.x;
            nio.data[43] = subsurface_color.y;
            nio.data[44] = subsurface_color.z;
            uint specular_offset = data_node.z & 255u;
            uint roughness_offset = (data_node.z >> uint(8)) & 255u;
            uint specular_tint_offset = (data_node.z >> uint(16)) & 255u;
            uint anisotropic_offset = (data_node.z >> uint(24)) & 255u;
            uint sheen_offset = data_node.w & 255u;
            uint sheen_tint_offset = (data_node.w >> uint(8)) & 255u;
            uint clearcoat_offset = (data_node.w >> uint(16)) & 255u;
            uint clearcoat_roughness_offset = (data_node.w >> uint(24)) & 255u;
            uint eta_offset = data_node2.x & 255u;
            uint transmission_offset = (data_node2.x >> uint(8)) & 255u;
            uint anisotropic_rotation_offset = (data_node2.x >> uint(16)) & 255u;
            uint transmission_roughness_offset = (data_node2.x >> uint(24)) & 255u;
            nio.data[15] = stack[specular_offset];
            nio.data[16] = stack[roughness_offset];
            nio.data[17] = stack[specular_tint_offset];
            nio.data[18] = stack[anisotropic_offset];
            nio.data[19] = stack[sheen_offset];
            nio.data[20] = stack[sheen_tint_offset];
            nio.data[21] = stack[clearcoat_offset];
            nio.data[22] = stack[clearcoat_roughness_offset];
            nio.data[23] = stack[transmission_offset];
            nio.data[24] = stack[anisotropic_rotation_offset];
            nio.data[25] = stack[transmission_roughness_offset];
            nio.data[26] = max(stack[eta_offset], 9.9999997473787516355514526367188e-06);
            nio.data[27] = uintBitsToFloat(data_node2.y);
            nio.data[28] = uintBitsToFloat(data_node2.z);
            exec = true;
            break;
        }
        case 2u:
        case 8u:
        case 19u:
        case 7u:
        case 17u:
        {
            exec = true;
            break;
        }
        case 33u:
        {
            exec = true;
            trans = true;
            nio.data[4] = sd.closure_transparent_extinction.x;
            nio.data[5] = sd.closure_transparent_extinction.y;
            nio.data[6] = sd.closure_transparent_extinction.z;
            break;
        }
        case 21u:
        case 23u:
        case 22u:
        {
            bool _10496 = !caustics;
            bool _10503;
            if (_10496)
            {
                _10503 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _10503 = _10496;
            }
            if (_10503)
            {
                break;
            }
            exec = true;
            break;
        }
        case 28u:
        case 26u:
        case 25u:
        {
            bool _10509 = !caustics;
            bool _10516;
            if (_10509)
            {
                _10516 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _10516 = _10509;
            }
            if (_10516)
            {
                break;
            }
            nio.data[4] = sd.I.x;
            nio.data[5] = sd.I.y;
            nio.data[6] = sd.I.z;
            exec = true;
            break;
        }
        case 24u:
        {
            bool _10531 = !caustics;
            bool _10538;
            if (_10531)
            {
                _10538 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _10538 = _10531;
            }
            if (_10538)
            {
                break;
            }
            if (!(data_node.z != 255u))
            {
                // unimplemented ext op 12
            }
            vec4 color = vec4(stack[data_node.z + 0u], stack[data_node.z + 1u], stack[data_node.z + 2u], 0.0);
            nio.data[32] = color.x;
            nio.data[33] = color.y;
            nio.data[34] = color.z;
            exec = true;
            break;
        }
        case 9u:
        case 10u:
        case 13u:
        case 16u:
        case 14u:
        {
            bool _10578 = !caustics;
            bool _10585;
            if (_10578)
            {
                _10585 = (uint(path_flag) & 8u) != 0u;
            }
            else
            {
                _10585 = _10578;
            }
            if (_10585)
            {
                break;
            }
            nio.data[27] = uintBitsToFloat(data_node.y);
            vec4 v_2 = vec4(stack[data_node.y + 0u], stack[data_node.y + 1u], stack[data_node.y + 2u], 0.0);
            nio.data[29] = v_2.x;
            nio.data[30] = v_2.y;
            nio.data[31] = v_2.z;
            nio.data[15] = stack[data_node.z];
            if (type == 14u)
            {
                if (!(data_node.w != 255u))
                {
                    // unimplemented ext op 12
                }
                v_2 = vec4(stack[data_node.w + 0u], stack[data_node.w + 1u], stack[data_node.w + 2u], 0.0);
                nio.data[32] = v_2.x;
                nio.data[33] = v_2.y;
                nio.data[34] = v_2.z;
            }
            exec = true;
            break;
        }
        case 34u:
        case 35u:
        case 37u:
        case 38u:
        {
            nio.data[4] = stack[data_node.z + 0u];
            nio.data[5] = stack[data_node.z + 1u];
            nio.data[6] = stack[data_node.z + 2u];
            nio.data[15] = mix_weight;
            nio.data[16] = stack[data_node.w];
            exec = true;
            break;
        }
        default:
        {
            break;
        }
    }
    if (exec)
    {
        int n = sd.num_closure;
        executeCallableNV(8u, 2);
        sd.num_closure_left = floatBitsToInt(nio.data[0]);
        sd.num_closure = floatBitsToInt(nio.data[1]);
        sd.alloc_offset = floatBitsToInt(nio.data[2]);
        sd.flag = floatBitsToInt(nio.data[3]);
        if (trans)
        {
            sd.closure_transparent_extinction = vec4(nio.data[4], nio.data[5], nio.data[6], 0.0);
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
    nio.data[19] = intBitsToFloat(sd.geometry);
    executeCallableNV(5u, 2);
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
            vec4 _8512 = primitive_tangent();
            data = _8512;
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

vec4 transform_point(Transform t, vec4 a)
{
    vec4 c = vec4((((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z)) + t.x.w, (((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z)) + t.y.w, (((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z)) + t.z.w, 0.0);
    return c;
}

void object_inverse_position_transform(inout vec4 P_1)
{
    Transform param = sd.ob_itfm;
    sd.ob_itfm = param;
    P_1 = transform_point(param, P_1);
}

vec4 transform_direction_transposed(Transform t, vec4 a)
{
    vec4 x = vec4(t.x.x, t.y.x, t.z.x, 0.0);
    vec4 y = vec4(t.x.y, t.y.y, t.z.y, 0.0);
    vec4 z = vec4(t.x.z, t.y.z, t.z.z, 0.0);
    return vec4(dot(x.xyz, a.xyz), dot(y.xyz, a.xyz), dot(z.xyz, a.xyz), 0.0);
}

void object_inverse_normal_transform(inout vec4 N)
{
    bool _1787 = sd.object != (-1);
    bool _1797;
    if (!_1787)
    {
        _1797 = uint(sd.type) == 64u;
    }
    else
    {
        _1797 = _1787;
    }
    if (_1797)
    {
        N = normalize(transform_direction_transposed(sd.ob_tfm, N));
    }
}

vec4 camera_position()
{
    Transform _3317;
    _3317.x = _2541.kernel_data.cam.cameratoworld.x;
    _3317.y = _2541.kernel_data.cam.cameratoworld.y;
    _3317.z = _2541.kernel_data.cam.cameratoworld.z;
    Transform cameratoworld = _3317;
    return vec4(cameratoworld.x.w, cameratoworld.y.w, cameratoworld.z.w, 0.0);
}

vec4 transform_perspective(ProjectionTransform t, vec4 a)
{
    vec4 b = vec4(a.xyz, 1.0);
    vec4 c = vec4(dot(t.x, b), dot(t.y, b), dot(t.z, b), 0.0);
    float w = dot(t.w, b);
    vec4 _1757;
    if (!(w == 0.0))
    {
        _1757 = c / vec4(w);
    }
    else
    {
        _1757 = vec4(0.0);
    }
    return _1757;
}

vec4 camera_world_to_ndc(inout vec4 P_1)
{
    if (uint(_2541.kernel_data.cam.type) != 2u)
    {
        bool _3336 = sd.object == (-1);
        bool _3343;
        if (_3336)
        {
            _3343 = uint(_2541.kernel_data.cam.type) == 0u;
        }
        else
        {
            _3343 = _3336;
        }
        if (_3343)
        {
            P_1 += camera_position();
        }
        ProjectionTransform _3354;
        _3354.x = _2541.kernel_data.cam.worldtondc.x;
        _3354.y = _2541.kernel_data.cam.worldtondc.y;
        _3354.z = _2541.kernel_data.cam.worldtondc.z;
        _3354.w = _2541.kernel_data.cam.worldtondc.w;
        ProjectionTransform tfm = _3354;
        ProjectionTransform param = tfm;
        return transform_perspective(param, P_1);
    }
}

vec4 object_dupli_generated(int object)
{
    if (object == (-1))
    {
        return vec4(0.0);
    }
    KernelObject _2079;
    _2079.tfm.x = push.data_ptr._objects.data[object].tfm.x;
    _2079.tfm.y = push.data_ptr._objects.data[object].tfm.y;
    _2079.tfm.z = push.data_ptr._objects.data[object].tfm.z;
    _2079.itfm.x = push.data_ptr._objects.data[object].itfm.x;
    _2079.itfm.y = push.data_ptr._objects.data[object].itfm.y;
    _2079.itfm.z = push.data_ptr._objects.data[object].itfm.z;
    _2079.surface_area = push.data_ptr._objects.data[object].surface_area;
    _2079.pass_id = push.data_ptr._objects.data[object].pass_id;
    _2079.random_number = push.data_ptr._objects.data[object].random_number;
    _2079.color[0] = push.data_ptr._objects.data[object].color[0];
    _2079.color[1] = push.data_ptr._objects.data[object].color[1];
    _2079.color[2] = push.data_ptr._objects.data[object].color[2];
    _2079.particle_index = push.data_ptr._objects.data[object].particle_index;
    _2079.dupli_generated[0] = push.data_ptr._objects.data[object].dupli_generated[0];
    _2079.dupli_generated[1] = push.data_ptr._objects.data[object].dupli_generated[1];
    _2079.dupli_generated[2] = push.data_ptr._objects.data[object].dupli_generated[2];
    _2079.dupli_uv[0] = push.data_ptr._objects.data[object].dupli_uv[0];
    _2079.dupli_uv[1] = push.data_ptr._objects.data[object].dupli_uv[1];
    _2079.numkeys = push.data_ptr._objects.data[object].numkeys;
    _2079.numsteps = push.data_ptr._objects.data[object].numsteps;
    _2079.numverts = push.data_ptr._objects.data[object].numverts;
    _2079.patch_map_offset = push.data_ptr._objects.data[object].patch_map_offset;
    _2079.attribute_map_offset = push.data_ptr._objects.data[object].attribute_map_offset;
    _2079.motion_offset = push.data_ptr._objects.data[object].motion_offset;
    _2079.cryptomatte_object = push.data_ptr._objects.data[object].cryptomatte_object;
    _2079.cryptomatte_asset = push.data_ptr._objects.data[object].cryptomatte_asset;
    _2079.shadow_terminator_offset = push.data_ptr._objects.data[object].shadow_terminator_offset;
    _2079.pad1 = push.data_ptr._objects.data[object].pad1;
    _2079.pad2 = push.data_ptr._objects.data[object].pad2;
    _2079.pad3 = push.data_ptr._objects.data[object].pad3;
    KernelObject kobject = _2079;
    return vec4(kobject.dupli_generated[0], kobject.dupli_generated[1], kobject.dupli_generated[2], 0.0);
}

vec4 object_dupli_uv(int object)
{
    if (object == (-1))
    {
        return vec4(0.0);
    }
    KernelObject _2103;
    _2103.tfm.x = push.data_ptr._objects.data[object].tfm.x;
    _2103.tfm.y = push.data_ptr._objects.data[object].tfm.y;
    _2103.tfm.z = push.data_ptr._objects.data[object].tfm.z;
    _2103.itfm.x = push.data_ptr._objects.data[object].itfm.x;
    _2103.itfm.y = push.data_ptr._objects.data[object].itfm.y;
    _2103.itfm.z = push.data_ptr._objects.data[object].itfm.z;
    _2103.surface_area = push.data_ptr._objects.data[object].surface_area;
    _2103.pass_id = push.data_ptr._objects.data[object].pass_id;
    _2103.random_number = push.data_ptr._objects.data[object].random_number;
    _2103.color[0] = push.data_ptr._objects.data[object].color[0];
    _2103.color[1] = push.data_ptr._objects.data[object].color[1];
    _2103.color[2] = push.data_ptr._objects.data[object].color[2];
    _2103.particle_index = push.data_ptr._objects.data[object].particle_index;
    _2103.dupli_generated[0] = push.data_ptr._objects.data[object].dupli_generated[0];
    _2103.dupli_generated[1] = push.data_ptr._objects.data[object].dupli_generated[1];
    _2103.dupli_generated[2] = push.data_ptr._objects.data[object].dupli_generated[2];
    _2103.dupli_uv[0] = push.data_ptr._objects.data[object].dupli_uv[0];
    _2103.dupli_uv[1] = push.data_ptr._objects.data[object].dupli_uv[1];
    _2103.numkeys = push.data_ptr._objects.data[object].numkeys;
    _2103.numsteps = push.data_ptr._objects.data[object].numsteps;
    _2103.numverts = push.data_ptr._objects.data[object].numverts;
    _2103.patch_map_offset = push.data_ptr._objects.data[object].patch_map_offset;
    _2103.attribute_map_offset = push.data_ptr._objects.data[object].attribute_map_offset;
    _2103.motion_offset = push.data_ptr._objects.data[object].motion_offset;
    _2103.cryptomatte_object = push.data_ptr._objects.data[object].cryptomatte_object;
    _2103.cryptomatte_asset = push.data_ptr._objects.data[object].cryptomatte_asset;
    _2103.shadow_terminator_offset = push.data_ptr._objects.data[object].shadow_terminator_offset;
    _2103.pad1 = push.data_ptr._objects.data[object].pad1;
    _2103.pad2 = push.data_ptr._objects.data[object].pad2;
    _2103.pad3 = push.data_ptr._objects.data[object].pad3;
    KernelObject kobject = _2103;
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
            Transform _3485;
            _3485.x = _2541.kernel_data.cam.worldtocamera.x;
            _3485.y = _2541.kernel_data.cam.worldtocamera.y;
            _3485.z = _2541.kernel_data.cam.worldtocamera.z;
            Transform tfm_1 = _3485;
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
            bool _3510 = (uint(path_flag) & 1u) != 0u;
            bool _3516;
            if (_3510)
            {
                _3516 = sd.object == (-1);
            }
            else
            {
                _3516 = _3510;
            }
            bool _3523;
            if (_3516)
            {
                _3523 = uint(_2541.kernel_data.cam.type) == 1u;
            }
            else
            {
                _3523 = _3516;
            }
            if (_3523)
            {
                vec4 param_5 = sd.ray_P;
                vec4 _3529 = camera_world_to_ndc(param_5);
                data = _3529;
            }
            else
            {
                vec4 param_6 = sd.P;
                vec4 _3534 = camera_world_to_ndc(param_6);
                data = _3534;
            }
            data.z = 0.0;
            break;
        }
        case 4u:
        {
            if (sd.object != (-1))
            {
                data = (sd.N * (2.0 * dot(sd.N.xyz, sd.I.xyz))) - sd.I;
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
    nio.data[19] = intBitsToFloat(sd.geometry);
    nio.type = 2u;
    executeCallableNV(5u, 2);
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
    float l = length(co.xyz);
    float u;
    float v;
    if (l > 0.0)
    {
        bool _1231 = co.x == 0.0;
        bool _1236;
        if (_1231)
        {
            _1236 = co.y == 0.0;
        }
        else
        {
            _1236 = _1231;
        }
        if (_1236)
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
    TextureInfo _7165;
    _7165.data = push.data_ptr._texture_info.data[id].data;
    _7165.data_type = push.data_ptr._texture_info.data[id].data_type;
    _7165.cl_buffer = push.data_ptr._texture_info.data[id].cl_buffer;
    _7165.interpolation = push.data_ptr._texture_info.data[id].interpolation;
    _7165.extension = push.data_ptr._texture_info.data[id].extension;
    _7165.width = push.data_ptr._texture_info.data[id].width;
    _7165.height = push.data_ptr._texture_info.data[id].height;
    _7165.depth = push.data_ptr._texture_info.data[id].depth;
    _7165.use_transform_3d = push.data_ptr._texture_info.data[id].use_transform_3d;
    _7165.transform_3d.x = push.data_ptr._texture_info.data[id].transform_3d.x;
    _7165.transform_3d.y = push.data_ptr._texture_info.data[id].transform_3d.y;
    _7165.transform_3d.z = push.data_ptr._texture_info.data[id].transform_3d.z;
    _7165.pad[0] = push.data_ptr._texture_info.data[id].pad[0];
    _7165.pad[1] = push.data_ptr._texture_info.data[id].pad[1];
    TextureInfo info = _7165;
    uint texSlot = uint(info.data);
    uint texture_type = info.data_type;
    if (texSlot >= 128u)
    {
        // unimplemented ext op 12
        return vec4(0.0);
    }
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
            uint _7453 = texSlot;
            uint _7462 = sampID;
            uint _7475 = texSlot;
            uint _7479 = sampID;
            uint _7509 = texSlot;
            uint _7513 = sampID;
            uint _7524 = texSlot;
            uint _7528 = sampID;
            vec4 ret = (((textureLod(sampler2D(_tex_[nonuniformEXT(_7453)], _samp_[nonuniformEXT(_7462)]), vec2(x0, y0), 0.0) * g0x) + (textureLod(sampler2D(_tex_[nonuniformEXT(_7475)], _samp_[nonuniformEXT(_7479)]), vec2(x1, y0), 0.0) * g1x)) * ((0.16666667163372039794921875 * ((fy * ((fy * ((-fy) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy * fy) * ((3.0 * fy) - 6.0)) + 4.0)))) + (((textureLod(sampler2D(_tex_[nonuniformEXT(_7509)], _samp_[nonuniformEXT(_7513)]), vec2(x0, y1), 0.0) * g0x) + (textureLod(sampler2D(_tex_[nonuniformEXT(_7524)], _samp_[nonuniformEXT(_7528)]), vec2(x1, y1), 0.0) * g1x)) * ((0.16666667163372039794921875 * ((fy * ((fy * (((-3.0) * fy) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy * fy) * fy))));
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
            uint _7557 = texSlot;
            uint _7561 = sampID_1;
            return textureLod(sampler2D(_tex_[nonuniformEXT(_7557)], _samp_[nonuniformEXT(_7561)]), vec2(x, y), 0.0);
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
            uint _7818 = texSlot;
            uint _7822 = sampID_2;
            uint _7834 = texSlot;
            uint _7838 = sampID_2;
            uint _7869 = texSlot;
            uint _7873 = sampID_2;
            uint _7885 = texSlot;
            uint _7889 = sampID_2;
            f = (((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * ((-fy_1) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy_1 * fy_1) * ((3.0 * fy_1) - 6.0)) + 4.0))) * ((g0x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_7818)], _samp_[nonuniformEXT(_7822)]), vec2(x0_1, y0_1), 0.0).x) + (g1x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_7834)], _samp_[nonuniformEXT(_7838)]), vec2(x1_1, y0_1), 0.0).x))) + (((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * (((-3.0) * fy_1) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy_1 * fy_1) * fy_1))) * ((g0x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_7869)], _samp_[nonuniformEXT(_7873)]), vec2(x0_1, y1_1), 0.0).x) + (g1x_1 * textureLod(sampler2D(_tex_[nonuniformEXT(_7885)], _samp_[nonuniformEXT(_7889)]), vec2(x1_1, y1_1), 0.0).x)));
        }
        else
        {
            uint sampID_3 = (info.interpolation * 3u) + info.extension;
            if (sampID_3 >= 6u)
            {
                // unimplemented ext op 12
                return vec4(0.0);
            }
            uint _7917 = texSlot;
            uint _7921 = sampID_3;
            f = textureLod(sampler2D(_tex_[nonuniformEXT(_7917)], _samp_[nonuniformEXT(_7921)]), vec2(x, y), 0.0).x;
        }
        return vec4(f, f, f, 1.0);
    }
}

float color_srgb_to_linear(float c)
{
    if (c < 0.040449999272823333740234375)
    {
        float _1268;
        if (c < 0.0)
        {
            _1268 = 0.0;
        }
        else
        {
            _1268 = c * 0.077399380505084991455078125;
        }
        return _1268;
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
    vec4 _7949 = kernel_tex_image_interp(param, param_1, param_2);
    vec4 r = _7949;
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
                int _8100 = offset;
                offset = _8100 + 1;
                uvec4 tile_node = push.data_ptr._svm_nodes.data[_8100];
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

void svm_node_curves(uvec4 node, inout int offset)
{
    uint fac_offset = node.y & 255u;
    uint color_offset = (node.y >> uint(8)) & 255u;
    uint out_offset = (node.y >> uint(16)) & 255u;
    int _3199 = offset;
    offset = _3199 + 1;
    uint table_size = push.data_ptr._svm_nodes.data[_3199].x;
    float fac = stack[fac_offset];
    vec4 color = vec4(stack[color_offset + 0u], stack[color_offset + 1u], stack[color_offset + 2u], 0.0);
    float min_x = uintBitsToFloat(node.z);
    float max_x = uintBitsToFloat(node.w);
    float range_x = max_x - min_x;
    vec4 relpos = (color - vec4(min_x, min_x, min_x, 0.0)) / vec4(range_x);
    int param = offset;
    float param_1 = relpos.x;
    bool param_2 = true;
    bool param_3 = true;
    int param_4 = int(table_size);
    vec4 _3255 = rgb_ramp_lookup(param, param_1, param_2, param_3, param_4);
    float r = _3255.x;
    int param_5 = offset;
    float param_6 = relpos.y;
    bool param_7 = true;
    bool param_8 = true;
    int param_9 = int(table_size);
    vec4 _3268 = rgb_ramp_lookup(param_5, param_6, param_7, param_8, param_9);
    float g = _3268.y;
    int param_10 = offset;
    float param_11 = relpos.z;
    bool param_12 = true;
    bool param_13 = true;
    int param_14 = int(table_size);
    vec4 _3281 = rgb_ramp_lookup(param_10, param_11, param_12, param_13, param_14);
    float b = _3281.z;
    color = (color * (1.0 - fac)) + (vec4(r, g, b, 0.0) * fac);
    stack[out_offset + 0u] = color.x;
    stack[out_offset + 1u] = color.y;
    stack[out_offset + 2u] = color.z;
    offset += int(table_size);
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

float len_squared(vec4 a)
{
    return dot(a.xyz, a.xyz);
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

void svm_node_vector_rotate(uint input_stack_offsets, uint axis_stack_offsets, uint result_stack_offset)
{
    uint type = input_stack_offsets & 255u;
    uint vector_stack_offset = (input_stack_offsets >> uint(8)) & 255u;
    uint rotation_stack_offset = (input_stack_offsets >> uint(16)) & 255u;
    uint invert = (input_stack_offsets >> uint(24)) & 255u;
    uint center_stack_offset = axis_stack_offsets & 255u;
    uint axis_stack_offset = (axis_stack_offsets >> uint(8)) & 255u;
    uint angle_stack_offset = (axis_stack_offsets >> uint(16)) & 255u;
    if (result_stack_offset != 255u)
    {
        vec4 vector = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0);
        vec4 center = vec4(stack[center_stack_offset + 0u], stack[center_stack_offset + 1u], stack[center_stack_offset + 2u], 0.0);
        vec4 result = vec4(0.0);
        if (type == 4u)
        {
            vec4 rotation = vec4(stack[rotation_stack_offset + 0u], stack[rotation_stack_offset + 1u], stack[rotation_stack_offset + 2u], 0.0);
            Transform rotationTransform = euler_to_transform(rotation);
            if (invert != 0u)
            {
                result = transform_direction_transposed(rotationTransform, vector - center) + center;
            }
            else
            {
                Transform param = rotationTransform;
                rotationTransform = param;
                result = transform_direction(param, vector - center) + center;
            }
        }
        else
        {
            vec4 axis;
            switch (type)
            {
                case 1u:
                {
                    axis = vec4(1.0, 0.0, 0.0, 0.0);
                    break;
                }
                case 2u:
                {
                    axis = vec4(0.0, 1.0, 0.0, 0.0);
                    break;
                }
                case 3u:
                {
                    axis = vec4(0.0, 0.0, 1.0, 0.0);
                    break;
                }
                default:
                {
                    axis = normalize(vec4(stack[axis_stack_offset + 0u], stack[axis_stack_offset + 1u], stack[axis_stack_offset + 2u], 0.0));
                    break;
                }
            }
            float angle = stack[angle_stack_offset];
            float _9398;
            if (invert != 0u)
            {
                _9398 = -angle;
            }
            else
            {
                _9398 = angle;
            }
            angle = _9398;
            vec4 _9409;
            if (!(len_squared(axis) == 0.0))
            {
                vec4 param_1 = vector - center;
                vec4 param_2 = axis;
                float param_3 = angle;
                _9409 = rotate_around_axis(param_1, param_2, param_3) + center;
            }
            else
            {
                _9409 = vector;
            }
            result = _9409;
        }
        stack[result_stack_offset + 0u] = result.x;
        stack[result_stack_offset + 1u] = result.y;
        stack[result_stack_offset + 2u] = result.z;
    }
}

void object_inverse_dir_transform(inout vec4 D)
{
    Transform param = sd.ob_itfm;
    sd.ob_itfm = param;
    D = transform_direction(param, D);
}

void object_dir_transform(inout vec4 D)
{
    Transform param = sd.ob_tfm;
    sd.ob_tfm = param;
    D = transform_direction(param, D);
}

void object_position_transform(inout vec4 P_1)
{
    Transform param = sd.ob_tfm;
    sd.ob_tfm = param;
    P_1 = transform_point(param, P_1);
}

void svm_node_vector_transform(uvec4 node)
{
    uint itype = node.y & 255u;
    uint ifrom = (node.y >> uint(8)) & 255u;
    uint ito = (node.y >> uint(16)) & 255u;
    uint vector_in = node.z & 255u;
    uint vector_out = (node.z >> uint(8)) & 255u;
    vec4 in_rsv = vec4(stack[vector_in + 0u], stack[vector_in + 1u], stack[vector_in + 2u], 0.0);
    uint type = itype;
    uint from = ifrom;
    uint to = ito;
    bool is_object = sd.object != (-1);
    bool is_direction = (type == 0u) || (type == 2u);
    Transform tfm;
    if (from == 0u)
    {
        if (to == 2u)
        {
            Transform _9505;
            _9505.x = _2541.kernel_data.cam.worldtocamera.x;
            _9505.y = _2541.kernel_data.cam.worldtocamera.y;
            _9505.z = _2541.kernel_data.cam.worldtocamera.z;
            tfm = _9505;
            if (is_direction)
            {
                Transform param = tfm;
                tfm = param;
                in_rsv = transform_direction(param, in_rsv);
            }
            else
            {
                Transform param_1 = tfm;
                tfm = param_1;
                in_rsv = transform_point(param_1, in_rsv);
            }
        }
        else
        {
            if ((to == 1u) && is_object)
            {
                if (is_direction)
                {
                    vec4 param_2 = in_rsv;
                    object_inverse_dir_transform(param_2);
                }
                else
                {
                    vec4 param_3 = in_rsv;
                    object_inverse_position_transform(param_3);
                    in_rsv = param_3;
                }
            }
        }
    }
    else
    {
        if (from == 2u)
        {
            if ((to == 0u) || (to == 1u))
            {
                Transform _9552;
                _9552.x = _2541.kernel_data.cam.cameratoworld.x;
                _9552.y = _2541.kernel_data.cam.cameratoworld.y;
                _9552.z = _2541.kernel_data.cam.cameratoworld.z;
                tfm = _9552;
                if (is_direction)
                {
                    Transform param_4 = tfm;
                    tfm = param_4;
                    in_rsv = transform_direction(param_4, in_rsv);
                }
                else
                {
                    Transform param_5 = tfm;
                    tfm = param_5;
                    in_rsv = transform_point(param_5, in_rsv);
                }
            }
            if ((to == 1u) && is_object)
            {
                if (is_direction)
                {
                    vec4 param_6 = in_rsv;
                    object_inverse_dir_transform(param_6);
                }
                else
                {
                    vec4 param_7 = in_rsv;
                    object_inverse_position_transform(param_7);
                    in_rsv = param_7;
                }
            }
        }
        else
        {
            if (from == 1u)
            {
                if (((to == 0u) || (to == 2u)) && is_object)
                {
                    if (is_direction)
                    {
                        vec4 param_8 = in_rsv;
                        object_dir_transform(param_8);
                        in_rsv = param_8;
                    }
                    else
                    {
                        vec4 param_9 = in_rsv;
                        object_position_transform(param_9);
                        in_rsv = param_9;
                    }
                }
                if (to == 2u)
                {
                    Transform _9616;
                    _9616.x = _2541.kernel_data.cam.worldtocamera.x;
                    _9616.y = _2541.kernel_data.cam.worldtocamera.y;
                    _9616.z = _2541.kernel_data.cam.worldtocamera.z;
                    tfm = _9616;
                    if (is_direction)
                    {
                        Transform param_10 = tfm;
                        tfm = param_10;
                        in_rsv = transform_direction(param_10, in_rsv);
                    }
                    else
                    {
                        Transform param_11 = tfm;
                        tfm = param_11;
                        in_rsv = transform_point(param_11, in_rsv);
                    }
                }
            }
        }
    }
    if (type == 2u)
    {
        in_rsv = normalize(in_rsv);
    }
    if (vector_out != 255u)
    {
        stack[vector_out + 0u] = in_rsv.x;
        stack[vector_out + 1u] = in_rsv.y;
        stack[vector_out + 2u] = in_rsv.z;
    }
}

void svm_node_set_normal(uint in_direction, uint out_normal)
{
    vec4 normal = vec4(stack[in_direction + 0u], stack[in_direction + 1u], stack[in_direction + 2u], 0.0);
    sd.N = normal;
    stack[out_normal + 0u] = normal.x;
    stack[out_normal + 1u] = normal.y;
    stack[out_normal + 2u] = normal.z;
}

void svm_node_set_displacement(uint fac_offset)
{
    vec4 dP = vec4(stack[fac_offset + 0u], stack[fac_offset + 1u], stack[fac_offset + 2u], 0.0);
    sd.P += dP;
}

void svm_node_displacement(uvec4 node)
{
    uint height_offset = node.y & 255u;
    uint midlevel_offset = (node.y >> uint(8)) & 255u;
    uint scale_offset = (node.y >> uint(16)) & 255u;
    uint normal_offset = (node.y >> uint(24)) & 255u;
    float height = stack[height_offset];
    float midlevel = stack[midlevel_offset];
    float scale = stack[scale_offset];
    vec4 _9191;
    if (normal_offset != 255u)
    {
        _9191 = vec4(stack[normal_offset + 0u], stack[normal_offset + 1u], stack[normal_offset + 2u], 0.0);
    }
    else
    {
        _9191 = sd.N;
    }
    vec4 normal = _9191;
    uint space = node.w;
    vec4 dP = normal;
    if (space == 1u)
    {
        vec4 param = dP;
        object_inverse_normal_transform(param);
        dP = param;
        dP *= ((height - midlevel) * scale);
        vec4 param_1 = dP;
        object_dir_transform(param_1);
        dP = param_1;
    }
    else
    {
        dP *= ((height - midlevel) * scale);
    }
    stack[node.z + 0u] = dP.x;
    stack[node.z + 1u] = dP.y;
    stack[node.z + 2u] = dP.z;
}

void svm_node_enter_bump_eval(uint offset)
{
    stack[(offset + 0u) + 0u] = sd.P.x;
    stack[(offset + 0u) + 1u] = sd.P.y;
    stack[(offset + 0u) + 2u] = sd.P.z;
    stack[(offset + 3u) + 0u] = sd.dP.dx.x;
    stack[(offset + 3u) + 1u] = sd.dP.dx.y;
    stack[(offset + 3u) + 2u] = sd.dP.dx.z;
    stack[(offset + 6u) + 0u] = sd.dP.dy.x;
    stack[(offset + 6u) + 1u] = sd.dP.dy.y;
    stack[(offset + 6u) + 2u] = sd.dP.dy.z;
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
    nio.data[19] = intBitsToFloat(sd.geometry);
    nio.type = 9u;
    executeCallableNV(5u, 2);
    if (uint(nio.offset) != 4294967295u)
    {
        vec4 P_1 = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0);
        vec4 dPdx = vec4(nio.data[3], nio.data[4], nio.data[5], 0.0);
        vec4 dPdy = vec4(nio.data[6], nio.data[7], nio.data[8], 0.0);
        vec4 param = P_1;
        object_position_transform(param);
        P_1 = param;
        vec4 param_1 = dPdx;
        object_dir_transform(param_1);
        dPdx = param_1;
        vec4 param_2 = dPdy;
        object_dir_transform(param_2);
        dPdy = param_2;
        sd.P = P_1;
        sd.dP.dx = dPdx;
        sd.dP.dy = dPdy;
    }
}

void svm_node_leave_bump_eval(uint offset)
{
    sd.P = vec4(stack[(offset + 0u) + 0u], stack[(offset + 0u) + 1u], stack[(offset + 0u) + 2u], 0.0);
    sd.dP.dx = vec4(stack[(offset + 3u) + 0u], stack[(offset + 3u) + 1u], stack[(offset + 3u) + 2u], 0.0);
    sd.dP.dy = vec4(stack[(offset + 6u) + 0u], stack[(offset + 6u) + 1u], stack[(offset + 6u) + 2u], 0.0);
}

void svm_node_geometry_bump_dx(uint type, uint out_offset)
{
    vec4 data;
    switch (type)
    {
        case 0u:
        {
            data = sd.P + sd.dP.dx;
            break;
        }
        case 5u:
        {
            data = vec4(sd.u + sd.du.dx, sd.v + sd.dv.dx, 0.0, 0.0);
            break;
        }
        default:
        {
            uint param = type;
            uint param_1 = out_offset;
            svm_node_geometry(param, param_1);
            return;
        }
    }
    stack[out_offset + 0u] = data.x;
    stack[out_offset + 1u] = data.y;
    stack[out_offset + 2u] = data.z;
}

void svm_node_geometry_bump_dy(uint type, uint out_offset)
{
    vec4 data;
    switch (type)
    {
        case 0u:
        {
            data = sd.P + sd.dP.dy;
            break;
        }
        case 5u:
        {
            data = vec4(sd.u + sd.du.dy, sd.v + sd.dv.dy, 0.0, 0.0);
            break;
        }
        default:
        {
            uint param = type;
            uint param_1 = out_offset;
            svm_node_geometry(param, param_1);
            return;
        }
    }
    stack[out_offset + 0u] = data.x;
    stack[out_offset + 1u] = data.y;
    stack[out_offset + 2u] = data.z;
}

vec4 cross(vec4 e1, vec4 e0)
{
    return vec4(cross(e1.xyz, e0.xyz), 0.0);
}

float signf(float f)
{
    return (f < 0.0) ? (-1.0) : 1.0;
}

vec4 safe_normalize(vec4 a)
{
    float t = length(a.xyz);
    vec4 _786;
    if (!(t == 0.0))
    {
        _786 = a * (1.0 / t);
    }
    else
    {
        _786 = a;
    }
    return _786;
}

bool is_zero(vec4 a)
{
    bool _830 = a.x == 0.0;
    bool _845;
    if (!_830)
    {
        _845 = (int((floatBitsToUint(a.x) >> uint(23)) & 255u) - 127) < (-60);
    }
    else
    {
        _845 = _830;
    }
    bool _861;
    if (_845)
    {
        bool _849 = a.y == 0.0;
        bool _860;
        if (!_849)
        {
            _860 = (int((floatBitsToUint(a.y) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _860 = _849;
        }
        _861 = _860;
    }
    else
    {
        _861 = _845;
    }
    bool _877;
    if (_861)
    {
        bool _865 = a.z == 0.0;
        bool _876;
        if (!_865)
        {
            _876 = (int((floatBitsToUint(a.z) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _876 = _865;
        }
        _877 = _876;
    }
    else
    {
        _877 = _861;
    }
    return _877;
}

void object_normal_transform(inout vec4 N)
{
    N = normalize(transform_direction_transposed(sd.ob_itfm, N));
}

float sqr(float a)
{
    return a * a;
}

float safe_sqrtf(float f)
{
    return sqrt(max(f, 0.0));
}

vec4 ensure_valid_reflection(vec4 Ng, vec4 I, vec4 N)
{
    vec4 R = (N * (2.0 * dot(N.xyz, I.xyz))) - I;
    float threshold = min(0.89999997615814208984375 * dot(Ng.xyz, I.xyz), 0.00999999977648258209228515625);
    if (dot(Ng.xyz, R.xyz) >= threshold)
    {
        return N;
    }
    float NdotNg = dot(N.xyz, Ng.xyz);
    vec4 X = vec4(normalize((N - (Ng * NdotNg)).xyz), 0.0);
    float Ix = dot(I.xyz, X.xyz);
    float Iz = dot(I.xyz, Ng.xyz);
    float param = Ix;
    float Ix2 = sqr(param);
    float param_1 = Iz;
    float Iz2 = sqr(param_1);
    float a = Ix2 + Iz2;
    float param_2 = threshold;
    float param_3 = Ix2 * (a - sqr(param_2));
    float b = safe_sqrtf(param_3);
    float c = (Iz * threshold) + a;
    float fac = 0.5 / a;
    float N1_z2 = fac * (b + c);
    float N2_z2 = fac * ((-b) + c);
    bool valid1 = (N1_z2 > 9.9999997473787516355514526367188e-06) && (N1_z2 <= 1.000010013580322265625);
    bool valid2 = (N2_z2 > 9.9999997473787516355514526367188e-06) && (N2_z2 <= 1.000010013580322265625);
    vec2 N_new;
    if (valid1 && valid2)
    {
        float param_4 = 1.0 - N1_z2;
        float param_5 = N1_z2;
        vec2 N1 = vec2(safe_sqrtf(param_4), safe_sqrtf(param_5));
        float param_6 = 1.0 - N2_z2;
        float param_7 = N2_z2;
        vec2 N2 = vec2(safe_sqrtf(param_6), safe_sqrtf(param_7));
        float R1 = ((2.0 * ((N1.x * Ix) + (N1.y * Iz))) * N1.y) - Iz;
        float R2 = ((2.0 * ((N2.x * Ix) + (N2.y * Iz))) * N2.y) - Iz;
        valid1 = R1 >= 9.9999997473787516355514526367188e-06;
        valid2 = R2 >= 9.9999997473787516355514526367188e-06;
        if (valid1 && valid2)
        {
            N_new = (R1 < R2) ? N1 : N2;
        }
        else
        {
            N_new = (R1 > R2) ? N1 : N2;
        }
    }
    else
    {
        if (valid1 || valid2)
        {
            float Nz2 = valid1 ? N1_z2 : N2_z2;
            float param_8 = 1.0 - Nz2;
            float param_9 = Nz2;
            N_new = vec2(safe_sqrtf(param_8), safe_sqrtf(param_9));
        }
        else
        {
            return Ng;
        }
    }
    return (X * N_new.x) + (Ng * N_new.y);
}

void svm_node_set_bump(uvec4 node)
{
    uint normal_offset = node.y & 255u;
    uint scale_offset = (node.y >> uint(8)) & 255u;
    uint invert = (node.y >> uint(16)) & 255u;
    uint use_object_space = (node.y >> uint(24)) & 255u;
    vec4 _8955;
    if (normal_offset != 255u)
    {
        _8955 = vec4(stack[normal_offset + 0u], stack[normal_offset + 1u], stack[normal_offset + 2u], 0.0);
    }
    else
    {
        _8955 = sd.N;
    }
    vec4 normal_in = _8955;
    vec4 dPdx = sd.dP.dx;
    vec4 dPdy = sd.dP.dy;
    if (use_object_space != 0u)
    {
        vec4 param = normal_in;
        object_inverse_normal_transform(param);
        normal_in = param;
        vec4 param_1 = dPdx;
        object_inverse_dir_transform(param_1);
        vec4 param_2 = dPdy;
        object_inverse_dir_transform(param_2);
    }
    vec4 param_3 = dPdy;
    vec4 param_4 = normal_in;
    vec4 Rx = cross(param_3, param_4);
    vec4 param_5 = normal_in;
    vec4 param_6 = dPdx;
    vec4 Ry = cross(param_5, param_6);
    uint c_offset = node.z & 255u;
    uint x_offset = (node.z >> uint(8)) & 255u;
    uint y_offset = (node.z >> uint(16)) & 255u;
    uint strength_offset = (node.z >> uint(24)) & 255u;
    float h_c = stack[c_offset];
    float h_x = stack[x_offset];
    float h_y = stack[y_offset];
    float det = dot(dPdx.xyz, Rx.xyz);
    vec4 surfgrad = (Rx * (h_x - h_c)) + (Ry * (h_y - h_c));
    float absdet = abs(det);
    float strength = stack[strength_offset];
    float scale = stack[scale_offset];
    if (invert != 0u)
    {
        scale *= (-1.0);
    }
    strength = max(strength, 0.0);
    float param_7 = det;
    vec4 normal_out = safe_normalize((normal_in * absdet) - (surfgrad * (scale * signf(param_7))));
    if (is_zero(normal_out))
    {
        normal_out = normal_in;
    }
    else
    {
        normal_out = normalize((normal_out * strength) + (normal_in * (1.0 - strength)));
    }
    if (use_object_space != 0u)
    {
        vec4 param_8 = normal_out;
        object_normal_transform(param_8);
        normal_out = param_8;
    }
    vec4 param_9 = sd.Ng;
    vec4 param_10 = sd.I;
    vec4 param_11 = normal_out;
    normal_out = ensure_valid_reflection(param_9, param_10, param_11);
    stack[node.w + 0u] = normal_out.x;
    stack[node.w + 1u] = normal_out.y;
    stack[node.w + 2u] = normal_out.z;
}

void svm_node_attr_bump_dx(uvec4 node)
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
    nio.data[19] = intBitsToFloat(sd.geometry);
    nio.type = 4u;
    executeCallableNV(5u, 2);
    uint type = nio.type;
    uint out_offset = uint(nio.offset);
    uint desc_type = uint(floatBitsToInt(nio.data[4]));
    vec4 f = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
    if (desc_type == 0u)
    {
        if (type == 0u)
        {
            stack[out_offset] = f.x;
        }
        else
        {
            stack[out_offset + 0u] = f.x;
            stack[out_offset + 1u] = f.y;
            stack[out_offset + 2u] = f.z;
        }
    }
    else
    {
        if (desc_type == 1u)
        {
            if (type == 0u)
            {
                stack[out_offset] = f.x;
            }
            else
            {
                stack[out_offset + 0u] = f.x;
                stack[out_offset + 1u] = f.y;
                stack[out_offset + 2u] = f.z;
            }
        }
        else
        {
            if (desc_type == 3u)
            {
                if (type == 0u)
                {
                    stack[out_offset] = f.x;
                }
                else
                {
                    stack[out_offset + 0u] = f.x;
                    stack[out_offset + 1u] = f.y;
                    stack[out_offset + 2u] = f.z;
                }
            }
            else
            {
                if (type == 0u)
                {
                    stack[out_offset] = f.x;
                }
                else
                {
                    stack[out_offset + 0u] = f.x;
                    stack[out_offset + 1u] = f.y;
                    stack[out_offset + 2u] = f.z;
                }
            }
        }
    }
}

void svm_node_attr_bump_dy(uvec4 node)
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
    nio.data[19] = intBitsToFloat(sd.geometry);
    nio.type = 5u;
    executeCallableNV(5u, 2);
    uint type = nio.type;
    uint out_offset = uint(nio.offset);
    uint desc_type = uint(floatBitsToInt(nio.data[4]));
    vec4 f = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
    if (desc_type == 0u)
    {
        if (type == 0u)
        {
            stack[out_offset] = f.x;
        }
        else
        {
            stack[out_offset + 0u] = f.x;
            stack[out_offset + 1u] = f.y;
            stack[out_offset + 2u] = f.z;
        }
    }
    else
    {
        if (desc_type == 1u)
        {
            if (type == 0u)
            {
                stack[out_offset] = f.x;
            }
            else
            {
                stack[out_offset + 0u] = f.x;
                stack[out_offset + 1u] = f.y;
                stack[out_offset + 2u] = f.z;
            }
        }
        else
        {
            if (desc_type == 3u)
            {
                if (type == 0u)
                {
                    stack[out_offset] = f.x;
                }
                else
                {
                    stack[out_offset + 0u] = f.x;
                    stack[out_offset + 1u] = f.y;
                    stack[out_offset + 2u] = f.z;
                }
            }
            else
            {
                if (type == 0u)
                {
                    stack[out_offset] = f.x;
                }
                else
                {
                    stack[out_offset + 0u] = f.x;
                    stack[out_offset + 1u] = f.y;
                    stack[out_offset + 2u] = f.z;
                }
            }
        }
    }
}

void svm_node_vertex_color(uint layer_id, uint color_offset, uint alpha_offset)
{
    nio.data[3] = uintBitsToFloat(layer_id);
    nio.data[4] = intBitsToFloat(sd.object_flag);
    nio.data[5] = intBitsToFloat(sd.prim);
    nio.data[6] = intBitsToFloat(sd.type);
    nio.data[7] = sd.u;
    nio.data[8] = sd.v;
    nio.data[9] = intBitsToFloat(sd.object);
    nio.data[19] = intBitsToFloat(sd.geometry);
    nio.type = 6u;
    executeCallableNV(5u, 2);
    uint desc_offset = nio.type;
    if (desc_offset != 4294967295u)
    {
        vec4 vertex_color = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
        stack[color_offset + 0u] = vertex_color.x;
        stack[color_offset + 1u] = vertex_color.y;
        stack[color_offset + 2u] = vertex_color.z;
        stack[alpha_offset] = vertex_color.w;
    }
    else
    {
        stack[color_offset + 0u] = 0.0;
        stack[color_offset + 1u] = 0.0;
        stack[color_offset + 2u] = 0.0;
        stack[alpha_offset] = 0.0;
    }
}

void svm_node_vertex_color_bump_dx(uint layer_id, uint color_offset, uint alpha_offset)
{
    nio.type = 7u;
    nio.data[3] = uintBitsToFloat(layer_id);
    nio.data[4] = intBitsToFloat(sd.object_flag);
    nio.data[5] = intBitsToFloat(sd.prim);
    nio.data[6] = intBitsToFloat(sd.type);
    nio.data[7] = sd.u;
    nio.data[8] = sd.v;
    nio.data[9] = intBitsToFloat(sd.object);
    nio.data[19] = intBitsToFloat(sd.geometry);
    nio.data[10] = sd.du.dx;
    nio.data[11] = sd.du.dy;
    nio.data[12] = sd.dv.dx;
    nio.data[13] = sd.dv.dy;
    executeCallableNV(5u, 2);
    uint desc_offset = nio.type;
    if (desc_offset != 4294967295u)
    {
        vec4 vertex_color = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
        stack[color_offset + 0u] = vertex_color.x;
        stack[color_offset + 1u] = vertex_color.y;
        stack[color_offset + 2u] = vertex_color.z;
        stack[alpha_offset] = vertex_color.w;
    }
    else
    {
        stack[color_offset + 0u] = 0.0;
        stack[color_offset + 1u] = 0.0;
        stack[color_offset + 2u] = 0.0;
        stack[alpha_offset] = 0.0;
    }
}

void svm_node_vertex_color_bump_dy(uint layer_id, uint color_offset, uint alpha_offset)
{
    nio.type = 8u;
    nio.data[3] = uintBitsToFloat(layer_id);
    nio.data[4] = intBitsToFloat(sd.object_flag);
    nio.data[5] = intBitsToFloat(sd.prim);
    nio.data[6] = intBitsToFloat(sd.type);
    nio.data[7] = sd.u;
    nio.data[8] = sd.v;
    nio.data[9] = intBitsToFloat(sd.object);
    nio.data[19] = intBitsToFloat(sd.geometry);
    nio.data[10] = sd.du.dx;
    nio.data[11] = sd.du.dy;
    nio.data[12] = sd.dv.dx;
    nio.data[13] = sd.dv.dy;
    executeCallableNV(5u, 2);
    uint desc_offset = nio.type;
    if (desc_offset != 4294967295u)
    {
        vec4 vertex_color = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
        stack[color_offset + 0u] = vertex_color.x;
        stack[color_offset + 1u] = vertex_color.y;
        stack[color_offset + 2u] = vertex_color.z;
        stack[alpha_offset] = vertex_color.w;
    }
    else
    {
        stack[color_offset + 0u] = 0.0;
        stack[color_offset + 1u] = 0.0;
        stack[color_offset + 2u] = 0.0;
        stack[alpha_offset] = 0.0;
    }
}

void svm_node_separate_hsv(uint color_in, uint hue_out, uint saturation_out, inout int offset)
{
    int _5814 = offset;
    offset = _5814 + 1;
    uvec4 node1 = push.data_ptr._svm_nodes.data[_5814];
    uint value_out = node1.y;
    vec4 color = vec4(stack[color_in + 0u], stack[color_in + 1u], stack[color_in + 2u], 0.0);
    vec4 param = color;
    color = rgb_to_hsv(param);
    if (hue_out != 255u)
    {
        stack[hue_out] = color.x;
    }
    if (saturation_out != 255u)
    {
        stack[saturation_out] = color.y;
    }
    if (value_out != 255u)
    {
        stack[value_out] = color.z;
    }
}

void svm_node_combine_hsv(uint hue_in, uint saturation_in, uint value_in, inout int offset)
{
    int _5764 = offset;
    offset = _5764 + 1;
    uvec4 node1 = push.data_ptr._svm_nodes.data[_5764];
    uint color_out = node1.y;
    float hue = stack[hue_in];
    float saturation = stack[saturation_in];
    float value = stack[value_in];
    vec4 param = vec4(hue, saturation, value, 0.0);
    vec4 color = hsv_to_rgb(param);
    if (color_out != 255u)
    {
        stack[color_out + 0u] = color.x;
        stack[color_out + 1u] = color.y;
        stack[color_out + 2u] = color.z;
    }
}

void svm_node_rgb_ramp(uvec4 node, inout int offset)
{
    uint interpolate = node.z;
    uint fac_offset = node.y & 255u;
    uint color_offset = (node.y >> uint(8)) & 255u;
    uint alpha_offset = (node.y >> uint(16)) & 255u;
    int _3125 = offset;
    offset = _3125 + 1;
    uint table_size = push.data_ptr._svm_nodes.data[_3125].x;
    float fac = stack[fac_offset];
    int param = offset;
    float param_1 = fac;
    bool param_2 = interpolate != 0u;
    bool param_3 = false;
    int param_4 = int(table_size);
    vec4 _3145 = rgb_ramp_lookup(param, param_1, param_2, param_3, param_4);
    vec4 color = _3145;
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
    float _1143;
    if (!(b == 0.0))
    {
        _1143 = a / b;
    }
    else
    {
        _1143 = 0.0;
    }
    return _1143;
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
    bool _1122 = a < 0.0;
    bool _1130;
    if (_1122)
    {
        _1130 = !(b == float(int(b)));
    }
    else
    {
        _1130 = _1122;
    }
    if (_1130)
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

float inversesqrtf(float f)
{
    float _1063;
    if (f > 0.0)
    {
        _1063 = 1.0 / sqrt(f);
    }
    else
    {
        _1063 = 0.0;
    }
    return _1063;
}

float safe_modulo(float a, float b)
{
    float _1172;
    if (!(b == 0.0))
    {
        _1172 = mod(a, b);
    }
    else
    {
        _1172 = 0.0;
    }
    return _1172;
}

float wrapf(float value, float _max, float _min)
{
    float range = _max - _min;
    float _657;
    if (!(range == 0.0))
    {
        _657 = value - (range * floor((value - _min) / range));
    }
    else
    {
        _657 = _min;
    }
    return _657;
}

float pingpongf(float a, float b)
{
    float _677;
    if (!(b == 0.0))
    {
        _677 = abs(((fract((a - b) / (b * 2.0)) * b) * 2.0) - b);
    }
    else
    {
        _677 = 0.0;
    }
    return _677;
}

float safe_asinf(float a)
{
    return asin(clamp(a, -1.0, 1.0));
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
            float _5454;
            if (a >= 0.0)
            {
                _5454 = floor(a);
            }
            else
            {
                _5454 = ceil(a);
            }
            return _5454;
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
            bool _5529 = a == b;
            bool _5541;
            if (!_5529)
            {
                _5541 = abs(a - b) <= max(c, 1.1920928955078125e-07);
            }
            else
            {
                _5541 = _5529;
            }
            return float(_5541);
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
    float _798;
    if (!(b.x == 0.0))
    {
        _798 = a.x / b.x;
    }
    else
    {
        _798 = 0.0;
    }
    float _808;
    if (!(b.y == 0.0))
    {
        _808 = a.y / b.y;
    }
    else
    {
        _808 = 0.0;
    }
    float _818;
    if (!(b.z == 0.0))
    {
        _818 = a.z / b.z;
    }
    else
    {
        _818 = 0.0;
    }
    return vec4(_798, _808, _818, 0.0);
}

vec4 project(vec4 v, vec4 v_proj)
{
    float len_squared_1 = dot(v_proj.xyz, v_proj.xyz);
    vec4 _767;
    if (!(len_squared_1 == 0.0))
    {
        _767 = v_proj * (dot(v.xyz, v_proj.xyz) / len_squared_1);
    }
    else
    {
        _767 = vec4(0.0);
    }
    return _767;
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
            vector = vec4(cross(a.xyz, b.xyz), 0.0);
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
            value = dot(a.xyz, b.xyz);
            break;
        }
        case 8u:
        {
            value = distance(a, b);
            break;
        }
        case 9u:
        {
            value = length(a.xyz);
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
            float param = a.x;
            float param_1 = b.x;
            float param_2 = a.y;
            float param_3 = b.y;
            float param_4 = a.z;
            float param_5 = b.z;
            vector = vec4(safe_modulo(param, param_1), safe_modulo(param_2, param_3), safe_modulo(param_4, param_5), 0.0);
            break;
        }
        case 20u:
        {
            float param_6 = a.x;
            float param_7 = b.x;
            float param_8 = c.x;
            float param_9 = a.y;
            float param_10 = b.y;
            float param_11 = c.y;
            float param_12 = a.z;
            float param_13 = b.z;
            float param_14 = c.z;
            vector = vec4(wrapf(param_6, param_7, param_8), wrapf(param_9, param_10, param_11), wrapf(param_12, param_13, param_14), 0.0);
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

vec4 object_location()
{
    if (sd.object == (-1))
    {
        return vec4(0.0);
    }
    return vec4(sd.ob_tfm.x.w, sd.ob_tfm.y.w, sd.ob_tfm.z.w, 0.0);
}

vec4 object_color(int object)
{
    if (object == (-1))
    {
        return vec4(0.0);
    }
    KernelObject _1994;
    _1994.tfm.x = push.data_ptr._objects.data[object].tfm.x;
    _1994.tfm.y = push.data_ptr._objects.data[object].tfm.y;
    _1994.tfm.z = push.data_ptr._objects.data[object].tfm.z;
    _1994.itfm.x = push.data_ptr._objects.data[object].itfm.x;
    _1994.itfm.y = push.data_ptr._objects.data[object].itfm.y;
    _1994.itfm.z = push.data_ptr._objects.data[object].itfm.z;
    _1994.surface_area = push.data_ptr._objects.data[object].surface_area;
    _1994.pass_id = push.data_ptr._objects.data[object].pass_id;
    _1994.random_number = push.data_ptr._objects.data[object].random_number;
    _1994.color[0] = push.data_ptr._objects.data[object].color[0];
    _1994.color[1] = push.data_ptr._objects.data[object].color[1];
    _1994.color[2] = push.data_ptr._objects.data[object].color[2];
    _1994.particle_index = push.data_ptr._objects.data[object].particle_index;
    _1994.dupli_generated[0] = push.data_ptr._objects.data[object].dupli_generated[0];
    _1994.dupli_generated[1] = push.data_ptr._objects.data[object].dupli_generated[1];
    _1994.dupli_generated[2] = push.data_ptr._objects.data[object].dupli_generated[2];
    _1994.dupli_uv[0] = push.data_ptr._objects.data[object].dupli_uv[0];
    _1994.dupli_uv[1] = push.data_ptr._objects.data[object].dupli_uv[1];
    _1994.numkeys = push.data_ptr._objects.data[object].numkeys;
    _1994.numsteps = push.data_ptr._objects.data[object].numsteps;
    _1994.numverts = push.data_ptr._objects.data[object].numverts;
    _1994.patch_map_offset = push.data_ptr._objects.data[object].patch_map_offset;
    _1994.attribute_map_offset = push.data_ptr._objects.data[object].attribute_map_offset;
    _1994.motion_offset = push.data_ptr._objects.data[object].motion_offset;
    _1994.cryptomatte_object = push.data_ptr._objects.data[object].cryptomatte_object;
    _1994.cryptomatte_asset = push.data_ptr._objects.data[object].cryptomatte_asset;
    _1994.shadow_terminator_offset = push.data_ptr._objects.data[object].shadow_terminator_offset;
    _1994.pad1 = push.data_ptr._objects.data[object].pad1;
    _1994.pad2 = push.data_ptr._objects.data[object].pad2;
    _1994.pad3 = push.data_ptr._objects.data[object].pad3;
    KernelObject kobject = _1994;
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
    int _6044 = offset;
    offset = _6044 + 1;
    uvec4 defaults1 = push.data_ptr._svm_nodes.data[_6044];
    int _6053 = offset;
    offset = _6053 + 1;
    uvec4 defaults2 = push.data_ptr._svm_nodes.data[_6053];
    nio.data[8] = float(dimensions);
    nio.offset = int(color_stack_offset);
    nio.data[0] = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0).x;
    nio.data[1] = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0).y;
    nio.data[2] = vec4(stack[vector_stack_offset + 0u], stack[vector_stack_offset + 1u], stack[vector_stack_offset + 2u], 0.0).z;
    float _6110;
    if (w_stack_offset == 255u)
    {
        _6110 = uintBitsToFloat(defaults1.x);
    }
    else
    {
        _6110 = stack[w_stack_offset];
    }
    nio.data[3] = _6110;
    float _6124;
    if (scale_stack_offset == 255u)
    {
        _6124 = uintBitsToFloat(defaults1.y);
    }
    else
    {
        _6124 = stack[scale_stack_offset];
    }
    nio.data[4] = _6124;
    float _6138;
    if (detail_stack_offset == 255u)
    {
        _6138 = uintBitsToFloat(defaults1.z);
    }
    else
    {
        _6138 = stack[detail_stack_offset];
    }
    nio.data[5] = _6138;
    float _6152;
    if (roughness_stack_offset == 255u)
    {
        _6152 = uintBitsToFloat(defaults1.w);
    }
    else
    {
        _6152 = stack[roughness_stack_offset];
    }
    nio.data[6] = _6152;
    float _6166;
    if (distortion_stack_offset == 255u)
    {
        _6166 = uintBitsToFloat(defaults2.x);
    }
    else
    {
        _6166 = stack[distortion_stack_offset];
    }
    nio.data[7] = _6166;
    executeCallableNV(3u, 2);
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
    int _6537 = offset;
    offset = _6537 + 1;
    uvec4 stack_offsets = push.data_ptr._svm_nodes.data[_6537];
    int _6546 = offset;
    offset = _6546 + 1;
    uvec4 defaults = push.data_ptr._svm_nodes.data[_6546];
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
    float _6653;
    if (w_stack_offset == 255u)
    {
        _6653 = uintBitsToFloat(stack_offsets.w);
    }
    else
    {
        _6653 = stack[w_stack_offset];
    }
    nio.data[3] = _6653;
    float _6667;
    if (scale_stack_offset == 255u)
    {
        _6667 = uintBitsToFloat(defaults.x);
    }
    else
    {
        _6667 = stack[scale_stack_offset];
    }
    nio.data[4] = _6667;
    float _6681;
    if (smoothness_stack_offset == 255u)
    {
        _6681 = uintBitsToFloat(defaults.y);
    }
    else
    {
        _6681 = stack[smoothness_stack_offset];
    }
    nio.data[5] = _6681;
    float _6695;
    if (exponent_stack_offset == 255u)
    {
        _6695 = uintBitsToFloat(defaults.z);
    }
    else
    {
        _6695 = stack[exponent_stack_offset];
    }
    nio.data[6] = _6695;
    float _6709;
    if (randomness_stack_offset == 255u)
    {
        _6709 = uintBitsToFloat(defaults.w);
    }
    else
    {
        _6709 = stack[randomness_stack_offset];
    }
    nio.data[7] = _6709;
    nio.data[8] = uintBitsToFloat(feature);
    nio.data[9] = uintBitsToFloat(metric);
    executeCallableNV(4u, 2);
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
    int _6311 = offset;
    offset = _6311 + 1;
    uvec4 node2 = push.data_ptr._svm_nodes.data[_6311];
    int _6320 = offset;
    offset = _6320 + 1;
    uvec4 node3 = push.data_ptr._svm_nodes.data[_6320];
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
    float _6417;
    if (scale_offset == 255u)
    {
        _6417 = uintBitsToFloat(node2.y);
    }
    else
    {
        _6417 = stack[scale_offset];
    }
    nio.data[3] = _6417;
    float _6431;
    if (distortion_offset == 255u)
    {
        _6431 = uintBitsToFloat(node2.z);
    }
    else
    {
        _6431 = stack[distortion_offset];
    }
    nio.data[4] = _6431;
    float _6445;
    if (detail_offset == 255u)
    {
        _6445 = uintBitsToFloat(node2.w);
    }
    else
    {
        _6445 = stack[detail_offset];
    }
    nio.data[5] = _6445;
    float _6459;
    if (dscale_offset == 255u)
    {
        _6459 = uintBitsToFloat(node3.x);
    }
    else
    {
        _6459 = stack[dscale_offset];
    }
    nio.data[6] = _6459;
    float _6473;
    if (droughness_offset == 255u)
    {
        _6473 = uintBitsToFloat(node3.y);
    }
    else
    {
        _6473 = stack[droughness_offset];
    }
    nio.data[7] = _6473;
    float _6487;
    if (phase_offset == 255u)
    {
        _6487 = uintBitsToFloat(node3.z);
    }
    else
    {
        _6487 = stack[phase_offset];
    }
    nio.data[8] = _6487;
    executeCallableNV(3u, 2);
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
    float _8389;
    if (scale_offset == 255u)
    {
        _8389 = uintBitsToFloat(node.w);
    }
    else
    {
        _8389 = stack[scale_offset];
    }
    float scale = _8389;
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
    int _6876 = offset;
    offset = _6876 + 1;
    uvec4 defaults1 = push.data_ptr._svm_nodes.data[_6876];
    int _6885 = offset;
    offset = _6885 + 1;
    uvec4 defaults2 = push.data_ptr._svm_nodes.data[_6885];
    nio.data[0] = vec4(stack[co_stack_offset + 0u], stack[co_stack_offset + 1u], stack[co_stack_offset + 2u], 0.0).x;
    nio.data[1] = vec4(stack[co_stack_offset + 0u], stack[co_stack_offset + 1u], stack[co_stack_offset + 2u], 0.0).y;
    nio.data[2] = vec4(stack[co_stack_offset + 0u], stack[co_stack_offset + 1u], stack[co_stack_offset + 2u], 0.0).z;
    float _6936;
    if (w_stack_offset == 255u)
    {
        _6936 = uintBitsToFloat(defaults1.x);
    }
    else
    {
        _6936 = stack[w_stack_offset];
    }
    nio.data[3] = _6936;
    float _6950;
    if (scale_stack_offset == 255u)
    {
        _6950 = uintBitsToFloat(defaults1.y);
    }
    else
    {
        _6950 = stack[scale_stack_offset];
    }
    nio.data[4] = _6950;
    float _6964;
    if (detail_stack_offset == 255u)
    {
        _6964 = uintBitsToFloat(defaults1.z);
    }
    else
    {
        _6964 = stack[detail_stack_offset];
    }
    nio.data[5] = _6964;
    float _6978;
    if (dimension_stack_offset == 255u)
    {
        _6978 = uintBitsToFloat(defaults1.w);
    }
    else
    {
        _6978 = stack[dimension_stack_offset];
    }
    nio.data[6] = _6978;
    float _6992;
    if (lacunarity_stack_offset == 255u)
    {
        _6992 = uintBitsToFloat(defaults2.x);
    }
    else
    {
        _6992 = stack[lacunarity_stack_offset];
    }
    nio.data[7] = _6992;
    float _7006;
    if (offset_stack_offset == 255u)
    {
        _7006 = uintBitsToFloat(defaults2.y);
    }
    else
    {
        _7006 = stack[offset_stack_offset];
    }
    nio.data[8] = _7006;
    float _7020;
    if (gain_stack_offset == 255u)
    {
        _7020 = uintBitsToFloat(defaults2.z);
    }
    else
    {
        _7020 = stack[gain_stack_offset];
    }
    nio.data[9] = _7020;
    executeCallableNV(6u, 2);
    stack[fac_stack_offset] = nio.data[0];
}

void svm_node_tex_white_noise(uint dimensions, uint inputs_stack_offsets, uint ouptuts_stack_offsets, int offset)
{
    uint vector_stack_offset = inputs_stack_offsets & 255u;
    uint w_stack_offset = (inputs_stack_offsets >> uint(8)) & 255u;
    uint value_stack_offset = ouptuts_stack_offsets & 255u;
    uint color_stack_offset = (ouptuts_stack_offsets >> uint(8)) & 255u;
    bool cstore = color_stack_offset != 255u;
    bool vstore = value_stack_offset != 255u;
    if (cstore || vstore)
    {
        nio.type = 4u;
        nio.data[0] = stack[vector_stack_offset + 0u];
        nio.data[1] = stack[vector_stack_offset + 1u];
        nio.data[2] = stack[vector_stack_offset + 2u];
        nio.data[3] = stack[w_stack_offset + 0u];
        nio.data[4] = uintBitsToFloat(dimensions);
        nio.data[5] = float(int(cstore) | (vstore ? 2 : 0));
        executeCallableNV(3u, 2);
        if (cstore)
        {
            stack[color_stack_offset + 0u] = nio.data[0];
            stack[color_stack_offset + 1u] = nio.data[1];
            stack[color_stack_offset + 2u] = nio.data[2];
        }
        if (vstore)
        {
            stack[value_stack_offset + 0u] = nio.data[3];
        }
    }
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
    executeCallableNV(7u, 2);
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
    vec4 co = vec4(stack[co_offset + 0u], stack[co_offset + 1u], stack[co_offset + 2u], 0.0);
    nio.data[0] = co.x;
    nio.data[1] = co.y;
    nio.data[2] = co.z;
    nio.data[4] = uintBitsToFloat(node.w);
    nio.data[5] = uintBitsToFloat(id);
    nio.data[6] = uintBitsToFloat(flags);
    nio.type = 3u;
    executeCallableNV(7u, 2);
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
    int _4936 = offset;
    offset = _4936 + 1;
    uvec4 defaults = push.data_ptr._svm_nodes.data[_4936];
    int _4945 = offset;
    offset = _4945 + 1;
    uvec4 defaults2 = push.data_ptr._svm_nodes.data[_4945];
    float value = stack[value_stack_offset];
    float _4956;
    if (from_min_stack_offset == 255u)
    {
        _4956 = uintBitsToFloat(defaults.x);
    }
    else
    {
        _4956 = stack[from_min_stack_offset];
    }
    float from_min = _4956;
    float _4970;
    if (from_max_stack_offset == 255u)
    {
        _4970 = uintBitsToFloat(defaults.y);
    }
    else
    {
        _4970 = stack[from_max_stack_offset];
    }
    float from_max = _4970;
    float _4984;
    if (to_min_stack_offset == 255u)
    {
        _4984 = uintBitsToFloat(defaults.z);
    }
    else
    {
        _4984 = stack[to_min_stack_offset];
    }
    float to_min = _4984;
    float _4998;
    if (to_max_stack_offset == 255u)
    {
        _4998 = uintBitsToFloat(defaults.w);
    }
    else
    {
        _4998 = stack[to_max_stack_offset];
    }
    float to_max = _4998;
    float _5012;
    if (steps_stack_offset == 255u)
    {
        _5012 = uintBitsToFloat(defaults2.x);
    }
    else
    {
        _5012 = stack[steps_stack_offset];
    }
    float steps = _5012;
    float result;
    if (!(from_max == from_min))
    {
        float factor = value;
        switch (type_stack_offset)
        {
            case 1u:
            {
                factor = (value - from_min) / (from_max - from_min);
                float _5053;
                if (steps > 0.0)
                {
                    _5053 = floor(factor * (steps + 1.0)) / steps;
                }
                else
                {
                    _5053 = 0.0;
                }
                factor = _5053;
                break;
            }
            case 2u:
            {
                float _5069;
                if (from_min > from_max)
                {
                    _5069 = 1.0 - smoothstep(from_max, from_min, factor);
                }
                else
                {
                    _5069 = smoothstep(from_min, from_max, factor);
                }
                factor = _5069;
                break;
            }
            case 3u:
            {
                float _5087;
                if (from_min > from_max)
                {
                    float param = from_max;
                    float param_1 = from_min;
                    float param_2 = factor;
                    float _5096 = smootherstep(param, param_1, param_2);
                    _5087 = 1.0 - _5096;
                }
                else
                {
                    float param_3 = from_min;
                    float param_4 = from_max;
                    float param_5 = factor;
                    float _5105 = smootherstep(param_3, param_4, param_5);
                    _5087 = _5105;
                }
                factor = _5087;
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

void svm_node_mix(uint fac_offset, uint c1_offset, uint c2_offset, inout int offset)
{
    int _2758 = offset;
    offset = _2758 + 1;
    uvec4 node1 = push.data_ptr._svm_nodes.data[_2758];
    nio.type = 0u;
    nio.data[0] = uintBitsToFloat(node1.y);
    nio.data[1] = stack[fac_offset + 0u];
    nio.data[2] = stack[c1_offset + 0u];
    nio.data[3] = stack[c1_offset + 1u];
    nio.data[4] = stack[c1_offset + 2u];
    nio.data[5] = stack[c2_offset + 0u];
    nio.data[6] = stack[c2_offset + 1u];
    nio.data[7] = stack[c2_offset + 2u];
    executeCallableNV(9u, 2);
    stack[node1.z + 0u] = nio.data[2];
    stack[node1.z + 1u] = nio.data[3];
    stack[node1.z + 2u] = nio.data[4];
}

void svm_node_tangent(uvec4 node)
{
    uint tangent_offset = node.y & 255u;
    uint direction_type = (node.y >> uint(8)) & 255u;
    uint axis = (node.y >> uint(16)) & 255u;
    nio.type = 0u;
    nio.offset = int(node.z);
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
    nio.data[19] = intBitsToFloat(sd.geometry);
    executeCallableNV(5u, 2);
    vec4 attribute_value = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0);
    vec4 tangent;
    if (direction_type == 1u)
    {
        if (!(nio.type != 0u))
        {
            tangent = vec4(0.0);
        }
        else
        {
            tangent = attribute_value;
        }
    }
    else
    {
        vec4 generated;
        if (!(nio.type != 0u))
        {
            generated = sd.P;
        }
        else
        {
            generated = attribute_value;
        }
        if (axis == 0u)
        {
            tangent = vec4(0.0, -(generated.z - 0.5), generated.y - 0.5, 0.0);
        }
        else
        {
            if (axis == 1u)
            {
                tangent = vec4(-(generated.z - 0.5), 0.0, generated.x - 0.5, 0.0);
            }
            else
            {
                tangent = vec4(-(generated.y - 0.5), generated.x - 0.5, 0.0, 0.0);
            }
        }
    }
    vec4 param = tangent;
    object_normal_transform(param);
    tangent = param;
    vec4 param_1 = tangent;
    vec4 param_2 = sd.N;
    tangent = vec4(cross(sd.N.xyz, normalize(cross(param_1, param_2)).xyz), 0.0);
    stack[tangent_offset + 0u] = tangent.x;
    stack[tangent_offset + 1u] = tangent.y;
    stack[tangent_offset + 2u] = tangent.z;
}

void svm_node_normal_map(uvec4 node)
{
    uint color_offset = node.y & 255u;
    uint strength_offset = (node.y >> uint(8)) & 255u;
    uint normal_offset = (node.y >> uint(16)) & 255u;
    uint space = (node.y >> uint(24)) & 255u;
    vec4 color = vec4(stack[color_offset + 0u], stack[color_offset + 1u], stack[color_offset + 2u], 0.0);
    color = vec4(color.x - 0.5, color.y - 0.5, color.z - 0.5, 0.0) * 2.0;
    bool is_backfacing = (uint(sd.flag) & 1u) != 0u;
    vec4 N;
    if (space == 0u)
    {
        if (sd.object == (-1))
        {
            stack[normal_offset + 0u] = 0.0;
            stack[normal_offset + 1u] = 0.0;
            stack[normal_offset + 2u] = 0.0;
            return;
        }
        nio.data[0] = sd.Ng.x;
        nio.data[1] = sd.Ng.y;
        nio.data[2] = sd.Ng.z;
        nio.data[3] = intBitsToFloat(sd.shader);
        nio.data[4] = intBitsToFloat(sd.object_flag);
        nio.data[5] = intBitsToFloat(sd.prim);
        nio.data[6] = intBitsToFloat(sd.type);
        nio.data[7] = sd.u;
        nio.data[8] = sd.v;
        nio.data[9] = intBitsToFloat(sd.object);
        nio.data[10] = color.x;
        nio.data[11] = color.y;
        nio.data[12] = color.z;
        nio.data[13] = intBitsToFloat(int(is_backfacing));
        nio.data[14] = intBitsToFloat(sd.lamp);
        nio.data[19] = intBitsToFloat(sd.geometry);
        nio.data[15] = uintBitsToFloat(node.x);
        nio.data[16] = uintBitsToFloat(node.y);
        nio.data[17] = uintBitsToFloat(node.z);
        nio.data[18] = uintBitsToFloat(node.w);
        nio.type = 3u;
        executeCallableNV(5u, 2);
        if (!(nio.type != 0u))
        {
            stack[normal_offset + 0u] = 0.0;
            stack[normal_offset + 1u] = 0.0;
            stack[normal_offset + 2u] = 0.0;
            return;
        }
        N = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0);
    }
    else
    {
        if ((space == 3u) || (space == 4u))
        {
            color.y = -color.y;
            color.z = -color.z;
        }
        N = color;
        if ((space == 1u) || (space == 3u))
        {
            vec4 param = N;
            object_normal_transform(param);
            N = param;
        }
        else
        {
            N = safe_normalize(N);
        }
    }
    if (is_backfacing)
    {
        N = -N;
    }
    float strength = stack[strength_offset];
    if (!(strength == 1.0))
    {
        strength = max(strength, 0.0);
        N = safe_normalize(sd.N + ((N - sd.N) * strength));
    }
    vec4 param_1 = sd.Ng;
    vec4 param_2 = sd.I;
    vec4 param_3 = N;
    N = ensure_valid_reflection(param_1, param_2, param_3);
    if (is_zero(N))
    {
        N = sd.N;
    }
    stack[normal_offset + 0u] = N.x;
    stack[normal_offset + 1u] = N.y;
    stack[normal_offset + 2u] = N.z;
}

void svm_eval_nodes(uint type, int path_flag)
{
    int offset = int(uint(sd.shader) & 8388607u);
    float _10991;
    float value;
    vec4 vector;
    while (true)
    {
        int _10819 = offset;
        offset = _10819 + 1;
        uvec4 node = push.data_ptr._svm_nodes.data[_10819];
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
                    _10991 = stack[in_weight_offset];
                }
                else
                {
                    _10991 = 1.0;
                }
                float in_weight = _10991;
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
                int _11085 = offset;
                offset = _11085 + 1;
                uvec4 node1 = push.data_ptr._svm_nodes.data[_11085];
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
            case 68u:
            case 69u:
            {
                uvec4 param_19 = node;
                int param_20 = offset;
                svm_node_curves(param_19, param_20);
                offset = param_20;
                break;
            }
            case 78u:
            {
                uint param_21 = node.y;
                uint param_22 = node.z;
                uint param_23 = node.w;
                svm_node_vector_rotate(param_21, param_22, param_23);
                break;
            }
            case 79u:
            {
                uvec4 param_24 = node;
                svm_node_vector_transform(param_24);
                break;
            }
            case 33u:
            {
                uint param_25 = node.y;
                uint param_26 = node.z;
                svm_node_set_normal(param_25, param_26);
                break;
            }
            case 20u:
            {
                uint param_27 = node.y;
                svm_node_set_displacement(param_27);
                break;
            }
            case 21u:
            {
                uvec4 param_28 = node;
                svm_node_displacement(param_28);
                break;
            }
            case 34u:
            {
                uint param_29 = node.y;
                svm_node_enter_bump_eval(param_29);
                break;
            }
            case 35u:
            {
                uint param_30 = node.y;
                svm_node_leave_bump_eval(param_30);
                break;
            }
            case 18u:
            {
                uint param_31 = node.y;
                uint param_32 = node.z;
                svm_node_geometry_bump_dx(param_31, param_32);
                break;
            }
            case 19u:
            {
                uint param_33 = node.y;
                uint param_34 = node.z;
                svm_node_geometry_bump_dy(param_33, param_34);
                break;
            }
            case 26u:
            {
                uvec4 param_35 = node;
                svm_node_set_bump(param_35);
                break;
            }
            case 27u:
            {
                uvec4 param_36 = node;
                svm_node_attr_bump_dx(param_36);
                break;
            }
            case 28u:
            {
                uvec4 param_37 = node;
                svm_node_attr_bump_dy(param_37);
                break;
            }
            case 17u:
            {
                uint param_38 = node.y;
                uint param_39 = node.z;
                uint param_40 = node.w;
                svm_node_vertex_color(param_38, param_39, param_40);
                break;
            }
            case 29u:
            {
                uint param_41 = node.y;
                uint param_42 = node.z;
                uint param_43 = node.w;
                svm_node_vertex_color_bump_dx(param_41, param_42, param_43);
                break;
            }
            case 30u:
            {
                uint param_44 = node.y;
                uint param_45 = node.z;
                uint param_46 = node.w;
                svm_node_vertex_color_bump_dy(param_44, param_45, param_46);
                break;
            }
            case 76u:
            {
                uint param_47 = node.y;
                uint param_48 = node.z;
                uint param_49 = node.w;
                int param_50 = offset;
                svm_node_separate_hsv(param_47, param_48, param_49, param_50);
                offset = param_50;
                break;
            }
            case 77u:
            {
                uint param_51 = node.y;
                uint param_52 = node.z;
                uint param_53 = node.w;
                int param_54 = offset;
                svm_node_combine_hsv(param_51, param_52, param_53, param_54);
                offset = param_54;
                break;
            }
            case 44u:
            {
                uvec4 param_55 = node;
                int param_56 = offset;
                svm_node_rgb_ramp(param_55, param_56);
                offset = param_56;
                break;
            }
            case 42u:
            {
                uint a_stack_offset = node.z & 255u;
                uint b_stack_offset = (node.z >> uint(8)) & 255u;
                uint c_stack_offset = (node.z >> uint(16)) & 255u;
                uint param_57 = node.y;
                float param_58 = stack[a_stack_offset];
                float param_59 = stack[b_stack_offset];
                float param_60 = stack[c_stack_offset];
                stack[node.w] = svm_math(param_57, param_58, param_59, param_60);
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
                    int _11367 = offset;
                    offset = _11367 + 1;
                    uvec4 extra_node = push.data_ptr._svm_nodes.data[_11367];
                    c = vec4(stack[extra_node.x + 0u], stack[extra_node.x + 1u], stack[extra_node.x + 2u], 0.0);
                }
                float param_61 = value;
                vec4 param_62 = vector;
                uint param_63 = node.y;
                vec4 param_64 = vec4(stack[a_stack_offset_1 + 0u], stack[a_stack_offset_1 + 1u], stack[a_stack_offset_1 + 2u], 0.0);
                vec4 param_65 = vec4(stack[b_stack_offset_1 + 0u], stack[b_stack_offset_1 + 1u], stack[b_stack_offset_1 + 2u], 0.0);
                vec4 param_66 = c;
                float param_67 = stack[scale_stack_offset];
                svm_vector_math(param_61, param_62, param_63, param_64, param_65, param_66, param_67);
                value = param_61;
                vector = param_62;
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
                vec4 param_68 = color;
                float param_69 = gamma;
                vec4 _11486 = svm_math_gamma_color(param_68, param_69);
                color = _11486;
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
                if (node.z != 255u)
                {
                    nio.type = 1u;
                    nio.data[2] = stack[node.y + 0u];
                    nio.data[3] = stack[node.y + 1u];
                    nio.data[4] = stack[node.y + 2u];
                    uint bright_offset = node.w & 255u;
                    uint contrast_offset = (node.w >> uint(8)) & 255u;
                    nio.data[1] = stack[bright_offset + 0u];
                    nio.data[5] = stack[contrast_offset + 0u];
                    executeCallableNV(9u, 2);
                    stack[node.z + 0u] = nio.data[2];
                    stack[node.z + 1u] = nio.data[3];
                    stack[node.z + 2u] = nio.data[4];
                }
                break;
            }
            case 48u:
            {
                uint param_70 = node.y;
                uint param_71 = node.z;
                svm_node_object_info(param_70, param_71);
                break;
            }
            case 49u:
            {
                uint param_72 = node.y;
                uint param_73 = node.z;
                svm_node_particle_info(param_72, param_73);
                break;
            }
            case 52u:
            {
                uint param_74 = node.y;
                uint param_75 = node.z;
                uint param_76 = node.w;
                int param_77 = offset;
                svm_node_mapping(param_74, param_75, param_76, param_77);
                offset = param_77;
                break;
            }
            case 25u:
            {
                uint param_78 = node.y;
                uint param_79 = node.z;
                uint param_80 = node.w;
                int param_81 = offset;
                svm_node_tex_noise(param_78, param_79, param_80, param_81);
                offset = param_81;
                break;
            }
            case 58u:
            {
                uint param_82 = node.y;
                uint param_83 = node.z;
                uint param_84 = node.w;
                int param_85 = offset;
                svm_node_tex_voronoi(param_82, param_83, param_84, param_85);
                offset = param_85;
                break;
            }
            case 60u:
            {
                uvec4 param_86 = node;
                int param_87 = offset;
                svm_node_tex_wave(param_86, param_87);
                offset = param_87;
                break;
            }
            case 62u:
            {
                uvec4 param_88 = node;
                svm_node_tex_checker(param_88);
                break;
            }
            case 59u:
            {
                uint param_89 = node.y;
                uint param_90 = node.z;
                uint param_91 = node.w;
                int param_92 = offset;
                svm_node_tex_musgrave(param_89, param_90, param_91, param_92);
                offset = param_92;
                break;
            }
            case 64u:
            {
                uint param_93 = node.y;
                uint param_94 = node.z;
                uint param_95 = node.w;
                int param_96 = offset;
                svm_node_tex_white_noise(param_93, param_94, param_95, param_96);
                offset = param_96;
                break;
            }
            case 56u:
            {
                uvec4 param_97 = node;
                int param_98 = offset;
                svm_node_tex_sky(param_97, param_98);
                offset = param_98;
                break;
            }
            case 55u:
            {
                uvec4 param_99 = node;
                svm_node_tex_environment(param_99);
                break;
            }
            case 83u:
            {
                uint param_100 = node.y;
                uint param_101 = node.z;
                uint param_102 = node.w;
                int param_103 = offset;
                svm_node_map_range(param_100, param_101, param_102, param_103);
                offset = param_103;
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
                uint param_104 = node.y;
                uint param_105 = node.z;
                uint param_106 = node.w;
                int param_107 = offset;
                svm_node_mix(param_104, param_105, param_106, param_107);
                offset = param_107;
                break;
            }
            case 70u:
            {
                uvec4 param_108 = node;
                svm_node_tangent(param_108);
                break;
            }
            case 71u:
            {
                uvec4 param_109 = node;
                svm_node_normal_map(param_109);
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
    G_dump = false;
    rec_num = 0;
    Dpixel = _582.kg.pixel;
    STIR = double[](0.00078731139579309367734077929057435lf, -0.00022954996161337812548425274528086lf, -0.00268132617805781235317819088948lf, 0.0034722222160545866166680983866399lf, 0.083333333333348219573721848973946lf, 0.0lf, 0.0lf, 0.0lf);
    P = double[](0.0001601195224767518480914890721678lf, 0.0011913514700658638361535635041832lf, 0.010421379756176157860281250577827lf, 0.047636780045713721098987747382125lf, 0.20744822764843598439377103659353lf, 0.49421482680149708688333021200378lf, 1.0lf, 0.0lf);
    Q = double[](-2.315818733241201444485700411402e-05lf, 0.00053960558049330335003007652616702lf, -0.0044564191385179727916687753008773lf, 0.011813978522206043317299695161182lf, 0.03582363986054986487728157840138lf, -0.23459179571824334553653557122743lf, 0.071430491703027301775286161955592lf, 1.0lf);
    A = double[](0.00081161416747050848814054591073841lf, -0.00059506190428430143831567411538686lf, 0.00079365034045771694262011441978188lf, -0.0027777777773009969426720733309821lf, 0.08333333333333318992952598591728lf, 0.0lf, 0.0lf, 0.0lf);
    B = double[](-1378.2515256912085988005856052041lf, -38801.631513463784358464181423187lf, -331612.9927388711948879063129425lf, -1162370.9749276230577379465103149lf, -1721737.0082083966117352247238159lf, -853555.66424576542340219020843506lf, 0.0lf, 0.0lf);
    C = double[](-351.81570143652345450391294434667lf, -17064.210665188114944612607359886lf, -220528.59055385444662533700466156lf, -1139334.4436798251699656248092651lf, -2532523.0717758294194936752319336lf, -2018891.4143353276886045932769775lf, 0.0lf, 0.0lf);
    rec_num = 0;
    G_dump = false;
    if (all(equal(Dpixel, gl_LaunchIDNV.xy)))
    {
        G_dump = true;
        G_use_light_pass = _2541.kernel_data.film.use_light_pass != int(0u);
    }
    if (sd.num_closure_left < 0)
    {
        rec_num = -sd.num_closure_left;
        float param = sd.randb_closure;
        kernel_path_shader_apply(param);
    }
    else
    {
        rec_num = sd.alloc_offset;
        sd.alloc_offset = sd.atomic_offset - 1;
        int flag = sd.num_closure;
        sd.num_closure = 0;
        uint param_1 = 0u;
        int param_2 = flag;
        svm_eval_nodes(param_1, param_2);
    }
}

