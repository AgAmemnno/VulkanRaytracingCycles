#version 460
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require

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

struct BG_prd
{
    ShaderData sd;
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

struct KernelGlobals
{
    Intersection hits_stack[64];
};

layout(buffer_reference) buffer KernelTextures;
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

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _168;

layout(set = 4, binding = 0, std430) buffer BG_IN
{
    uvec4 inpu[];
} _410;

layout(set = 4, binding = 1, std430) buffer BG_OUT
{
    vec4 outpu[];
} _464;

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals kg;
} _489;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _493;

layout(set = 1, binding = 0, std140) uniform CameraProperties
{
    mat4 view;
    mat4 proj;
    mat4 viewInverse;
    mat4 projInverse;
} cam;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

layout(location = 0) rayPayloadNV BG_prd prd;
layout(set = 0, binding = 0) uniform accelerationStructureNV topLevelAS;
layout(set = 0, binding = 1, rgba8) uniform readonly writeonly image2D image;

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

void shader_setup_from_background(Ray ray)
{
    prd.sd.P = ray.D;
    prd.sd.N = -ray.D;
    prd.sd.Ng = -ray.D;
    prd.sd.I = -ray.D;
    prd.sd.shader = _168.kernel_data.background.surface_shader;
    prd.sd.flag = push.data_ptr._shaders.data[uint(prd.sd.shader) & 8388607u].flags;
    prd.sd.object_flag = 0;
    prd.sd.time = ray.time;
    prd.sd.ray_length = 0.0;
    prd.sd.object = -1;
    prd.sd.lamp = -1;
    prd.sd.prim = -1;
    prd.sd.u = 0.0;
    prd.sd.v = 0.0;
    prd.sd.dPdu = vec4(0.0);
    prd.sd.dPdv = vec4(0.0);
    prd.sd.dP = ray.dD;
    prd.sd.dI.dx = -prd.sd.dP.dx;
    prd.sd.dI.dy = -prd.sd.dP.dy;
    prd.sd.du.dx = 0.0;
    prd.sd.du.dy = 0.0;
    prd.sd.dv.dx = 0.0;
    prd.sd.dv.dy = 0.0;
    prd.sd.ray_P = ray.P;
}

void shader_eval_surface(uint path_flag)
{
    int max_closures;
    if ((path_flag & 7341952u) != 0u)
    {
        max_closures = 0;
    }
    else
    {
        max_closures = _168.kernel_data.integrator.max_closures;
    }
    prd.sd.num_closure = int(path_flag);
    prd.sd.num_closure_left = max_closures;
    prd.sd.alloc_offset = PROFI_IDX;
    executeCallableNV(4u, 1);
    if ((uint(prd.sd.flag) & 1024u) != 0u)
    {
        // unimplemented ext op 12
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
    int i = int(gl_LaunchIDNV.x + (gl_LaunchSizeNV.x * gl_LaunchIDNV.y));
    uvec4 inp = _410.inpu[i];
    float u = uintBitsToFloat(inp.x);
    float v = uintBitsToFloat(inp.y);
    Ray ray;
    ray.P = vec4(0.0);
    float param = u;
    float param_1 = v;
    ray.D = equirectangular_to_direction(param, param_1);
    ray.t = 0.0;
    ray.time = 0.5;
    ray.dD.dx = vec4(0.0);
    ray.dD.dy = vec4(0.0);
    ray.dP.dx = vec4(0.0);
    ray.dP.dy = vec4(0.0);
    Ray param_2 = ray;
    shader_setup_from_background(param_2);
    uint path_flag = 0u;
    uint param_3 = path_flag | 4194304u;
    shader_eval_surface(param_3);
    vec4 _453;
    if ((uint(prd.sd.flag) & 2u) != 0u)
    {
        _453 = prd.sd.closure_emission_background;
    }
    else
    {
        _453 = vec4(0.0);
    }
    vec4 color = _453;
    _464.outpu[i] = vec4(color.x, color.y, color.z, 0.0);
}

