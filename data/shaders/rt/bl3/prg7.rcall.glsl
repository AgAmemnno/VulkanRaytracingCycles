#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_nonuniform_qualifier : require
#extension GL_EXT_scalar_block_layout : require

struct KernelGlobals_PROF
{
    uvec2 pixel;
    vec4 f3[960];
    float f1[960];
    uint u1[960];
};

struct Transform
{
    vec4 x;
    vec4 y;
    vec4 z;
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

struct NodeIO_SKY
{
    int offset;
    uint type;
    vec4 dir;
    uvec4 node;
};

layout(buffer_reference) buffer KernelTextures;
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

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals_PROF kg;
} _218;

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _1354;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _2583;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

layout(set = 3, binding = 0) uniform texture2D _tex_[];
layout(set = 3, binding = 1) uniform sampler _samp_[];
layout(location = 2) callableDataInNV NodeIO_SKY nio;

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
bool G_use_light_pass;
int PROFI_IDX;

float safe_acosf(float a)
{
    return acos(clamp(a, -1.0, 1.0));
}

vec2 direction_to_spherical(vec4 dir)
{
    float param = dir.z;
    float theta = safe_acosf(param);
    float phi = atan(dir.x, dir.y);
    return vec2(theta, phi);
}

float sky_angle_between(float thetav, float phiv, float theta, float phi)
{
    float cospsi = ((sin(thetav) * sin(theta)) * cos(phi - phiv)) + (cos(thetav) * cos(theta));
    float param = cospsi;
    return safe_acosf(param);
}

float sky_perez_function(float lam[9], float theta, float gamma)
{
    float ctheta = cos(theta);
    float cgamma = cos(gamma);
    return (1.0 + (lam[0] * exp(lam[1] / ctheta))) * ((1.0 + (lam[2] * exp(lam[3] * gamma))) + ((lam[4] * cgamma) * cgamma));
}

vec4 xyY_to_xyz(float x, float y, float Y)
{
    float X;
    if (!(y == 0.0))
    {
        X = (x / y) * Y;
    }
    else
    {
        X = 0.0;
    }
    float Z;
    if ((!(y == 0.0)) && (!(Y == 0.0)))
    {
        Z = (((1.0 - x) - y) / y) * Y;
    }
    else
    {
        Z = 0.0;
    }
    return vec4(X, Y, Z, 0.0);
}

vec4 xyz_to_rgb(vec4 xyz)
{
    return vec4(dot(_1354.kernel_data.film.xyz_to_r.xyz, xyz.xyz), dot(_1354.kernel_data.film.xyz_to_g.xyz, xyz.xyz), dot(_1354.kernel_data.film.xyz_to_b.xyz, xyz.xyz), 0.0);
}

vec4 sky_radiance_preetham(vec4 dir, float sunphi, float suntheta, float radiance_x, float radiance_y, float radiance_z, inout float config_x[9], inout float config_y[9], inout float config_z[9])
{
    vec4 param = dir;
    vec2 spherical = direction_to_spherical(param);
    float theta = spherical.x;
    float phi = spherical.y;
    float param_1 = theta;
    float param_2 = phi;
    float param_3 = suntheta;
    float param_4 = sunphi;
    float gamma = sky_angle_between(param_1, param_2, param_3, param_4);
    theta = min(theta, 1.5697963237762451171875);
    float param_5[9] = config_y;
    float param_6 = theta;
    float param_7 = gamma;
    config_y = param_5;
    float x = radiance_y * sky_perez_function(param_5, param_6, param_7);
    float param_8[9] = config_z;
    float param_9 = theta;
    float param_10 = gamma;
    config_z = param_8;
    float y = radiance_z * sky_perez_function(param_8, param_9, param_10);
    float param_11[9] = config_x;
    float param_12 = theta;
    float param_13 = gamma;
    config_x = param_11;
    float Y = radiance_x * sky_perez_function(param_11, param_12, param_13);
    float param_14 = x;
    float param_15 = y;
    float param_16 = Y;
    vec4 xyz = xyY_to_xyz(param_14, param_15, param_16);
    vec4 param_17 = xyz;
    return xyz_to_rgb(param_17);
}

float sky_radiance_internal(float configuration[9], float theta, float gamma)
{
    float ctheta = cos(theta);
    float cgamma = cos(gamma);
    float expM = exp(configuration[4] * gamma);
    float rayM = cgamma * cgamma;
    float mieM = (1.0 + rayM) / pow((1.0 + (configuration[8] * configuration[8])) - ((2.0 * configuration[8]) * cgamma), 1.5);
    float zenith = sqrt(ctheta);
    return (1.0 + (configuration[0] * exp(configuration[1] / (ctheta + 0.00999999977648258209228515625)))) * ((((configuration[2] + (configuration[3] * expM)) + (configuration[5] * rayM)) + (configuration[6] * mieM)) + (configuration[7] * zenith));
}

vec4 sky_radiance_hosek(vec4 dir, float sunphi, float suntheta, float radiance_x, float radiance_y, float radiance_z, inout float config_x[9], inout float config_y[9], inout float config_z[9])
{
    vec4 param = dir;
    vec2 spherical = direction_to_spherical(param);
    float theta = spherical.x;
    float phi = spherical.y;
    float param_1 = theta;
    float param_2 = phi;
    float param_3 = suntheta;
    float param_4 = sunphi;
    float gamma = sky_angle_between(param_1, param_2, param_3, param_4);
    theta = min(theta, 1.5697963237762451171875);
    float param_5[9] = config_x;
    float param_6 = theta;
    float param_7 = gamma;
    config_x = param_5;
    float x = sky_radiance_internal(param_5, param_6, param_7) * radiance_x;
    float param_8[9] = config_y;
    float param_9 = theta;
    float param_10 = gamma;
    config_y = param_8;
    float y = sky_radiance_internal(param_8, param_9, param_10) * radiance_y;
    float param_11[9] = config_z;
    float param_12 = theta;
    float param_13 = gamma;
    config_z = param_11;
    float z = sky_radiance_internal(param_11, param_12, param_13) * radiance_z;
    vec4 param_14 = vec4(x, y, z, 0.0);
    return xyz_to_rgb(param_14) * 0.009199392981827259063720703125;
}

vec4 geographical_to_direction(float lat, float lon)
{
    return vec4(cos(lat) * cos(lon), cos(lat) * sin(lon), sin(lat), 0.0);
}

float len(vec3 a)
{
    return length(a);
}

float precise_angle(vec4 a, vec4 b)
{
    vec3 param = (a - b).xyz;
    vec3 param_1 = (a + b).xyz;
    return 2.0 * atan(len(param), len(param_1));
}

float sqr(float a)
{
    return a * a;
}

float safe_sqrtf(float f)
{
    return sqrt(max(f, 0.0));
}

vec4 kernel_tex_image_interp(int id, inout float x, inout float y)
{
    TextureInfo _544;
    _544.data = push.data_ptr._texture_info.data[id].data;
    _544.data_type = push.data_ptr._texture_info.data[id].data_type;
    _544.cl_buffer = push.data_ptr._texture_info.data[id].cl_buffer;
    _544.interpolation = push.data_ptr._texture_info.data[id].interpolation;
    _544.extension = push.data_ptr._texture_info.data[id].extension;
    _544.width = push.data_ptr._texture_info.data[id].width;
    _544.height = push.data_ptr._texture_info.data[id].height;
    _544.depth = push.data_ptr._texture_info.data[id].depth;
    _544.use_transform_3d = push.data_ptr._texture_info.data[id].use_transform_3d;
    _544.transform_3d.x = push.data_ptr._texture_info.data[id].transform_3d.x;
    _544.transform_3d.y = push.data_ptr._texture_info.data[id].transform_3d.y;
    _544.transform_3d.z = push.data_ptr._texture_info.data[id].transform_3d.z;
    _544.pad[0] = push.data_ptr._texture_info.data[id].pad[0];
    _544.pad[1] = push.data_ptr._texture_info.data[id].pad[1];
    TextureInfo info = _544;
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
            uint _843 = texSlot;
            uint _852 = sampID;
            uint _865 = texSlot;
            uint _869 = sampID;
            uint _899 = texSlot;
            uint _903 = sampID;
            uint _914 = texSlot;
            uint _918 = sampID;
            vec4 ret = (((textureLod(sampler2D(_tex_[_843], _samp_[_852]), vec2(x0, y0), 0.0) * g0x) + (textureLod(sampler2D(_tex_[_865], _samp_[_869]), vec2(x1, y0), 0.0) * g1x)) * ((0.16666667163372039794921875 * ((fy * ((fy * ((-fy) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy * fy) * ((3.0 * fy) - 6.0)) + 4.0)))) + (((textureLod(sampler2D(_tex_[_899], _samp_[_903]), vec2(x0, y1), 0.0) * g0x) + (textureLod(sampler2D(_tex_[_914], _samp_[_918]), vec2(x1, y1), 0.0) * g1x)) * ((0.16666667163372039794921875 * ((fy * ((fy * (((-3.0) * fy) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy * fy) * fy))));
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
            uint _947 = texSlot;
            uint _951 = sampID_1;
            return textureLod(sampler2D(_tex_[_947], _samp_[_951]), vec2(x, y), 0.0);
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
            uint _1208 = texSlot;
            uint _1212 = sampID_2;
            uint _1224 = texSlot;
            uint _1228 = sampID_2;
            uint _1259 = texSlot;
            uint _1263 = sampID_2;
            uint _1275 = texSlot;
            uint _1279 = sampID_2;
            f = (((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * ((-fy_1) + 3.0)) - 3.0)) + 1.0)) + (0.16666667163372039794921875 * (((fy_1 * fy_1) * ((3.0 * fy_1) - 6.0)) + 4.0))) * ((g0x_1 * textureLod(sampler2D(_tex_[_1208], _samp_[_1212]), vec2(x0_1, y0_1), 0.0).x) + (g1x_1 * textureLod(sampler2D(_tex_[_1224], _samp_[_1228]), vec2(x1_1, y0_1), 0.0).x))) + (((0.16666667163372039794921875 * ((fy_1 * ((fy_1 * (((-3.0) * fy_1) + 3.0)) + 3.0)) + 1.0)) + (0.16666667163372039794921875 * ((fy_1 * fy_1) * fy_1))) * ((g0x_1 * textureLod(sampler2D(_tex_[_1259], _samp_[_1263]), vec2(x0_1, y1_1), 0.0).x) + (g1x_1 * textureLod(sampler2D(_tex_[_1275], _samp_[_1279]), vec2(x1_1, y1_1), 0.0).x)));
        }
        else
        {
            uint sampID_3 = (info.interpolation * 3u) + info.extension;
            if (sampID_3 >= 6u)
            {
                // unimplemented ext op 12
                return vec4(0.0);
            }
            uint _1307 = texSlot;
            uint _1311 = sampID_3;
            f = textureLod(sampler2D(_tex_[_1307], _samp_[_1311]), vec2(x, y), 0.0).x;
        }
        return vec4(f, f, f, 1.0);
    }
}

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

vec4 sky_radiance_nishita(vec4 dir, float nishita_data[10], uint texture_id)
{
    float sun_elevation = nishita_data[6];
    float sun_rotation = nishita_data[7];
    float angular_diameter = nishita_data[8];
    float sun_intensity = nishita_data[9];
    bool sun_disc = angular_diameter >= 0.0;
    vec4 param = dir;
    vec2 direction = direction_to_spherical(param);
    vec4 xyz;
    if (dir.z >= 0.0)
    {
        float param_1 = sun_elevation;
        float param_2 = sun_rotation + 1.57079637050628662109375;
        vec4 sun_dir = geographical_to_direction(param_1, param_2);
        vec4 param_3 = dir;
        vec4 param_4 = sun_dir;
        float sun_dir_angle = precise_angle(param_3, param_4);
        float half_angular = angular_diameter / 2.0;
        float dir_elevation = 1.57079637050628662109375 - direction.x;
        if (sun_disc && (sun_dir_angle < half_angular))
        {
            vec3 pixel_bottom = vec3(nishita_data[0], nishita_data[1], nishita_data[2]);
            vec3 pixel_top = vec3(nishita_data[3], nishita_data[4], nishita_data[5]);
            float y;
            if ((sun_elevation - half_angular) > 0.0)
            {
                if ((sun_elevation + half_angular) > 0.0)
                {
                    y = ((dir_elevation - sun_elevation) / angular_diameter) + 0.5;
                    vec3 _1760 = (pixel_bottom + ((pixel_top - pixel_bottom) * y)) * sun_intensity;
                    xyz.x = _1760.x;
                    xyz.y = _1760.y;
                    xyz.z = _1760.z;
                }
            }
            else
            {
                if ((sun_elevation + half_angular) > 0.0)
                {
                    y = dir_elevation / (sun_elevation + half_angular);
                    vec3 _1787 = (pixel_bottom + ((pixel_top - pixel_bottom) * y)) * sun_intensity;
                    xyz.x = _1787.x;
                    xyz.y = _1787.y;
                    xyz.z = _1787.z;
                }
            }
            float param_5 = sun_dir_angle / half_angular;
            float limb_darkening = 1.0 - (0.60000002384185791015625 * (1.0 - sqrt(1.0 - sqr(param_5))));
            vec4 _1807 = xyz;
            vec3 _1809 = _1807.xyz * limb_darkening;
            xyz.x = _1809.x;
            xyz.y = _1809.y;
            xyz.z = _1809.z;
        }
        else
        {
            float x = ((direction.y + 3.1415927410125732421875) + sun_rotation) / 6.283185482025146484375;
            float param_6 = dir_elevation / 1.57079637050628662109375;
            float y_1 = safe_sqrtf(param_6);
            if (x > 1.0)
            {
                x -= 1.0;
            }
            int param_7 = int(texture_id);
            float param_8 = x;
            float param_9 = y_1;
            vec4 _1844 = kernel_tex_image_interp(param_7, param_8, param_9);
            xyz = float4_to_float3(_1844);
        }
    }
    else
    {
        if (dir.z < (-0.4000000059604644775390625))
        {
            xyz = vec4(0.0);
        }
        else
        {
            float fade = 1.0 + (dir.z * 2.5);
            float param_10 = fade;
            fade = sqr(param_10) * fade;
            float x_1 = ((direction.y + 3.1415927410125732421875) + sun_rotation) / 6.283185482025146484375;
            if (x_1 > 1.0)
            {
                x_1 -= 1.0;
            }
            int param_11 = int(texture_id);
            float param_12 = x_1;
            float param_13 = -0.5;
            vec4 _1885 = kernel_tex_image_interp(param_11, param_12, param_13);
            xyz = float4_to_float3(_1885) * fade;
        }
    }
    vec4 param_14 = xyz;
    vec4 rgb = xyz_to_rgb(param_14);
    return rgb;
}

void svm_node_tex_sky()
{
    uint dir_offset = nio.node.y;
    uint out_offset = nio.node.z;
    int sky_model = int(nio.node.w);
    vec4 data;
    vec4 f;
    if ((sky_model == 0) || (sky_model == 1))
    {
        uvec4 node = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node.x), uintBitsToFloat(node.y), uintBitsToFloat(node.z), uintBitsToFloat(node.w));
        nio.offset++;
        float sunphi = data.x;
        float suntheta = data.y;
        float radiance_x = data.z;
        float radiance_y = data.w;
        uvec4 node_1 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_1.x), uintBitsToFloat(node_1.y), uintBitsToFloat(node_1.z), uintBitsToFloat(node_1.w));
        nio.offset++;
        float radiance_z = data.x;
        float config_x[9];
        config_x[0] = data.y;
        config_x[1] = data.z;
        config_x[2] = data.w;
        uvec4 node_2 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_2.x), uintBitsToFloat(node_2.y), uintBitsToFloat(node_2.z), uintBitsToFloat(node_2.w));
        nio.offset++;
        config_x[3] = data.x;
        config_x[4] = data.y;
        config_x[5] = data.z;
        config_x[6] = data.w;
        uvec4 node_3 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_3.x), uintBitsToFloat(node_3.y), uintBitsToFloat(node_3.z), uintBitsToFloat(node_3.w));
        nio.offset++;
        config_x[7] = data.x;
        config_x[8] = data.y;
        float config_y[9];
        config_y[0] = data.z;
        config_y[1] = data.w;
        uvec4 node_4 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_4.x), uintBitsToFloat(node_4.y), uintBitsToFloat(node_4.z), uintBitsToFloat(node_4.w));
        nio.offset++;
        config_y[2] = data.x;
        config_y[3] = data.y;
        config_y[4] = data.z;
        config_y[5] = data.w;
        uvec4 node_5 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_5.x), uintBitsToFloat(node_5.y), uintBitsToFloat(node_5.z), uintBitsToFloat(node_5.w));
        nio.offset++;
        config_y[6] = data.x;
        config_y[7] = data.y;
        config_y[8] = data.z;
        float config_z[9];
        config_z[0] = data.w;
        uvec4 node_6 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_6.x), uintBitsToFloat(node_6.y), uintBitsToFloat(node_6.z), uintBitsToFloat(node_6.w));
        nio.offset++;
        config_z[1] = data.x;
        config_z[2] = data.y;
        config_z[3] = data.z;
        config_z[4] = data.w;
        uvec4 node_7 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_7.x), uintBitsToFloat(node_7.y), uintBitsToFloat(node_7.z), uintBitsToFloat(node_7.w));
        nio.offset++;
        config_z[5] = data.x;
        config_z[6] = data.y;
        config_z[7] = data.z;
        config_z[8] = data.w;
        if (sky_model == 0)
        {
            vec4 param = nio.dir;
            float param_1 = sunphi;
            float param_2 = suntheta;
            float param_3 = radiance_x;
            float param_4 = radiance_y;
            float param_5 = radiance_z;
            float param_6[9] = config_x;
            float param_7[9] = config_y;
            float param_8[9] = config_z;
            vec4 _2247 = sky_radiance_preetham(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8);
            config_x = param_6;
            config_y = param_7;
            config_z = param_8;
            f = _2247;
        }
        else
        {
            vec4 param_9 = nio.dir;
            float param_10 = sunphi;
            float param_11 = suntheta;
            float param_12 = radiance_x;
            float param_13 = radiance_y;
            float param_14 = radiance_z;
            float param_15[9] = config_x;
            float param_16[9] = config_y;
            float param_17[9] = config_z;
            vec4 _2271 = sky_radiance_hosek(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17);
            config_x = param_15;
            config_y = param_16;
            config_z = param_17;
            f = _2271;
        }
    }
    else
    {
        uvec4 node_8 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_8.x), uintBitsToFloat(node_8.y), uintBitsToFloat(node_8.z), uintBitsToFloat(node_8.w));
        nio.offset++;
        float nishita_data[10];
        nishita_data[0] = data.x;
        nishita_data[1] = data.y;
        nishita_data[2] = data.z;
        nishita_data[3] = data.w;
        uvec4 node_9 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_9.x), uintBitsToFloat(node_9.y), uintBitsToFloat(node_9.z), uintBitsToFloat(node_9.w));
        nio.offset++;
        nishita_data[4] = data.x;
        nishita_data[5] = data.y;
        nishita_data[6] = data.z;
        nishita_data[7] = data.w;
        uvec4 node_10 = push.data_ptr._svm_nodes.data[nio.offset];
        data = vec4(uintBitsToFloat(node_10.x), uintBitsToFloat(node_10.y), uintBitsToFloat(node_10.z), uintBitsToFloat(node_10.w));
        nio.offset++;
        nishita_data[8] = data.x;
        nishita_data[9] = data.y;
        uint texture_id = floatBitsToUint(data.z);
        vec4 param_18 = nio.dir;
        float param_19[10] = nishita_data;
        uint param_20 = texture_id;
        nishita_data = param_19;
        f = sky_radiance_nishita(param_18, param_19, param_20);
    }
    nio.dir = f;
}

vec4 safe_normalize(vec4 a)
{
    float t = length(a.xyz);
    vec4 _238;
    if (!(t == 0.0))
    {
        _238 = a * (1.0 / t);
    }
    else
    {
        _238 = a;
    }
    return _238;
}

bool is_zero(vec4 a)
{
    bool _250 = a.x == 0.0;
    bool _265;
    if (!_250)
    {
        _265 = (int((floatBitsToUint(a.x) >> uint(23)) & 255u) - 127) < (-60);
    }
    else
    {
        _265 = _250;
    }
    bool _281;
    if (_265)
    {
        bool _269 = a.y == 0.0;
        bool _280;
        if (!_269)
        {
            _280 = (int((floatBitsToUint(a.y) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _280 = _269;
        }
        _281 = _280;
    }
    else
    {
        _281 = _265;
    }
    bool _297;
    if (_281)
    {
        bool _285 = a.z == 0.0;
        bool _296;
        if (!_285)
        {
            _296 = (int((floatBitsToUint(a.z) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _296 = _285;
        }
        _297 = _296;
    }
    else
    {
        _297 = _281;
    }
    return _297;
}

vec2 direction_to_equirectangular_range(vec4 dir, vec4 range)
{
    if (is_zero(dir))
    {
        return vec2(0.0);
    }
    float u = (atan(dir.y, dir.x) - range.y) / range.x;
    vec3 param = dir.xyz;
    float v = (acos(dir.z / len(param)) - range.w) / range.z;
    return vec2(u, v);
}

vec2 direction_to_equirectangular(vec4 dir)
{
    vec4 param = dir;
    vec4 param_1 = vec4(-6.283185482025146484375, 3.1415927410125732421875, -3.1415927410125732421875, 3.1415927410125732421875);
    return direction_to_equirectangular_range(param, param_1);
}

vec2 direction_to_mirrorball(inout vec4 dir)
{
    dir.y -= 1.0;
    float div = 2.0 * sqrt(max((-0.5) * dir.y, 0.0));
    if (div > 0.0)
    {
        dir /= vec4(div);
    }
    float u = 0.5 * (dir.x + 1.0);
    float v = 0.5 * (dir.z + 1.0);
    return vec2(u, v);
}

float color_srgb_to_linear(float c)
{
    if (c < 0.040449999272823333740234375)
    {
        float _340;
        if (c < 0.0)
        {
            _340 = 0.0;
        }
        else
        {
            _340 = c * 0.077399380505084991455078125;
        }
        return _340;
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
    vec4 _2411 = kernel_tex_image_interp(param, param_1, param_2);
    vec4 r = _2411;
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

void svm_node_tex_environment()
{
    vec4 co = nio.dir;
    co = safe_normalize(co);
    vec2 uv;
    if (nio.node.x == 0u)
    {
        vec4 param = co;
        uv = direction_to_equirectangular(param);
    }
    else
    {
        vec4 param_1 = co;
        vec2 _2541 = direction_to_mirrorball(param_1);
        uv = _2541;
    }
    int param_2 = int(nio.node.y);
    float param_3 = uv.x;
    float param_4 = uv.y;
    uint param_5 = nio.node.z;
    nio.dir = svm_image_texture(param_2, param_3, param_4, param_5);
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
    Dpixel = _218.kg.pixel;
    rec_num = 0;
    G_dump = false;
    if (all(equal(Dpixel, gl_LaunchIDNV.xy)))
    {
        G_dump = true;
        G_use_light_pass = _1354.kernel_data.film.use_light_pass != int(0u);
    }
    if (nio.type == 2u)
    {
        int _2586 = atomicAdd(_2583.counter[1018], 1);
        svm_node_tex_sky();
    }
    else
    {
        if (nio.type == 3u)
        {
            svm_node_tex_environment();
        }
    }
}

