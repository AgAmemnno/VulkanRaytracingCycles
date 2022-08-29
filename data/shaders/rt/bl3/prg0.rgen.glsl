#version 460
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require
#extension GL_KHR_shader_subgroup_basic : require

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
    Transform ob_tfm;
    Transform ob_itfm;
    int geometry;
    vec4 closure_emission_background;
    vec4 closure_transparent_extinction;
    int atomic_offset;
    int alloc_offset;
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

struct KernelGlobals_PROF
{
    uvec2 pixel;
    vec4 f3[960];
    float f1[960];
    uint u1[960];
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

struct PRG2ARG
{
    args_sd sd;
    args_acc_light L;
    int use_light_pass;
    int type;
    Ray ray;
    PathState state;
};

struct ARG_T2
{
    float v[12];
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

struct PathRadianceState
{
    vec4 diffuse;
    vec4 glossy;
    vec4 transmission;
    vec4 volume;
    vec4 direct;
};

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

struct SubsurfaceIndirectRays
{
    PathState state[4];
    int num_rays;
    Ray rays[4];
    vec4 throughputs[4];
    PathRadianceState L_state[4];
};

struct LocalIntersection_tiny
{
    int num_hits;
    vec4 rayP;
    vec4 rayD;
    Intersection isect[4];
    vec4 weight[4];
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer ShaderClosurePool;
layout(buffer_reference) buffer IntersectionPool;
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
layout(buffer_reference) buffer pool_is_;
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

layout(buffer_reference, std430) buffer IntersectionPool
{
    pool_is_ pool_is;
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

layout(buffer_reference, std430) readonly buffer pool_is_
{
    Intersection data[];
};

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals_PROF kg;
} _685;

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _1929;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _6660;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
    ShaderClosurePool pool_ptr;
    IntersectionPool pool_ptr2;
} push;

layout(location = 0) callableDataNV PRG2ARG arg;
layout(location = 2) callableDataNV ARG_T2 arg2;
layout(location = 1) callableDataNV ShaderData sd;
layout(location = 0) rayPayloadNV Intersection isect;
layout(set = 0, binding = 0) uniform accelerationStructureNV topLevelAS;
layout(set = 0, binding = 1, rgba8) uniform writeonly image2D image;

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
vec4 throughput;
PathRadiance L;
int PROFI_IDX;
SubsurfaceIndirectRays ss_indirect;
bool G_use_light_pass;
ShaderClosure null_sc;

void path_radiance_init()
{
    L.use_light_pass = _1929.kernel_data.film.use_light_pass;
    if (_1929.kernel_data.film.use_light_pass != 0)
    {
        L.indirect = vec4(0.0);
        L.direct_emission = vec4(0.0);
        L.color_diffuse = vec4(0.0);
        L.color_glossy = vec4(0.0);
        L.color_transmission = vec4(0.0);
        L.direct_diffuse = vec4(0.0);
        L.direct_glossy = vec4(0.0);
        L.direct_transmission = vec4(0.0);
        L.direct_volume = vec4(0.0);
        L.indirect_diffuse = vec4(0.0);
        L.indirect_glossy = vec4(0.0);
        L.indirect_transmission = vec4(0.0);
        L.indirect_volume = vec4(0.0);
        L.transparent = 0.0;
        L.emission = vec4(0.0);
        L.background = vec4(0.0);
        L.ao = vec4(0.0);
        L.shadow = vec4(0.0);
        L.mist = 0.0;
        L.state.diffuse = vec4(0.0);
        L.state.glossy = vec4(0.0);
        L.state.transmission = vec4(0.0);
        L.state.volume = vec4(0.0);
        L.state.direct = vec4(0.0);
    }
    else
    {
        L.transparent = 0.0;
        L.emission = vec4(0.0);
    }
    L.path_total = vec4(0.0);
    L.path_total_shaded = vec4(0.0);
    L.shadow_background_color = vec4(0.0);
    L.shadow_throughput = 0.0;
    L.shadow_transparency = 1.0;
    L.has_shadow_catcher = 0;
}

float lookup_table_read(inout float x, int offset, int size)
{
    x = clamp(x, 0.0, 1.0) * float(size - 1);
    int index = min(int(x), (size - 1));
    int nindex = min((index + 1), (size - 1));
    float t = x - float(index);
    float data0 = push.data_ptr._lookup_table.data[index + offset];
    if (t == 0.0)
    {
        return data0;
    }
    float data1 = push.data_ptr._lookup_table.data[nindex + offset];
    return ((1.0 - t) * data0) + (t * data1);
}

vec4 transform_perspective(ProjectionTransform t, vec4 a)
{
    vec4 b = vec4(a.xyz, 1.0);
    vec4 c = vec4(dot(t.x, b), dot(t.y, b), dot(t.z, b), 0.0);
    float w = dot(t.w, b);
    vec4 _1562;
    if (!(w == 0.0))
    {
        _1562 = c / vec4(w);
    }
    else
    {
        _1562 = vec4(0.0);
    }
    return _1562;
}

vec2 concentric_sample_disk(float u1, float u2)
{
    float a = (2.0 * u1) - 1.0;
    float b = (2.0 * u2) - 1.0;
    float r;
    float phi;
    if ((a == 0.0) && (b == 0.0))
    {
        return vec2(0.0);
    }
    else
    {
        if ((a * a) > (b * b))
        {
            r = a;
            phi = 0.785398185253143310546875 * (b / a);
        }
        else
        {
            r = b;
            phi = 1.57079637050628662109375 - (0.785398185253143310546875 * (a / b));
        }
    }
    return vec2(r * cos(phi), r * sin(phi));
}

vec2 regular_polygon_sample(float corners, inout float rotation, inout float u, inout float v)
{
    float corner = floor(u * corners);
    u = (u * corners) - corner;
    u = sqrt(u);
    v *= u;
    u = 1.0 - u;
    float angle = 3.1415927410125732421875 / corners;
    vec2 p = vec2((u + v) * cos(angle), (u - v) * sin(angle));
    rotation += ((corner * 2.0) * angle);
    float cr = cos(rotation);
    float sr = sin(rotation);
    return vec2((cr * p.x) - (sr * p.y), (sr * p.x) + (cr * p.y));
}

vec2 camera_sample_aperture(float u, float v)
{
    float blades = _1929.kernel_data.cam.blades;
    vec2 bokeh;
    if (blades == 0.0)
    {
        float param = u;
        float param_1 = v;
        bokeh = concentric_sample_disk(param, param_1);
    }
    else
    {
        float rotation = _1929.kernel_data.cam.bladesrotation;
        float param_2 = blades;
        float param_3 = rotation;
        float param_4 = u;
        float param_5 = v;
        vec2 _2544 = regular_polygon_sample(param_2, param_3, param_4, param_5);
        bokeh = _2544;
    }
    bokeh.x *= _1929.kernel_data.cam.inv_aperture_ratio;
    return bokeh;
}

vec4 transform_point(Transform t, vec4 a)
{
    vec4 c = vec4((((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z)) + t.x.w, (((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z)) + t.y.w, (((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z)) + t.z.w, 0.0);
    return c;
}

vec4 transform_direction(Transform t, vec4 a)
{
    vec4 c = vec4(((a.x * t.x.x) + (a.y * t.x.y)) + (a.z * t.x.z), ((a.x * t.y.x) + (a.y * t.y.y)) + (a.z * t.y.z), ((a.x * t.z.x) + (a.y * t.z.y)) + (a.z * t.z.z), 0.0);
    return c;
}

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

float safe_asinf(float a)
{
    return asin(clamp(a, -1.0, 1.0));
}

vec4 _cross(vec4 e1, vec4 e0)
{
    return vec4(cross(e1.xyz, e0.xyz), 0.0);
}

void spherical_stereo_transform(inout vec4 P, inout vec4 D)
{
    float interocular_offset = _1929.kernel_data.cam.interocular_offset;
    if (!(!(interocular_offset == 0.0)))
    {
        // unimplemented ext op 12
    }
    if (_1929.kernel_data.cam.pole_merge_angle_to > 0.0)
    {
        float pole_merge_angle_from = _1929.kernel_data.cam.pole_merge_angle_from;
        float pole_merge_angle_to = _1929.kernel_data.cam.pole_merge_angle_to;
        float param = D.z;
        float altitude = abs(safe_asinf(param));
        if (altitude > pole_merge_angle_to)
        {
            interocular_offset = 0.0;
        }
        else
        {
            if (altitude > pole_merge_angle_from)
            {
                float fac = (altitude - pole_merge_angle_from) / (pole_merge_angle_to - pole_merge_angle_from);
                float fade = cos(fac * 1.57079637050628662109375);
                interocular_offset *= fade;
            }
        }
    }
    vec4 up = vec4(0.0, 0.0, 1.0, 0.0);
    vec4 param_1 = D;
    vec4 param_2 = up;
    vec4 side = normalize(_cross(param_1, param_2));
    vec4 stereo_offset = side * interocular_offset;
    P += stereo_offset;
    float convergence_distance = _1929.kernel_data.cam.convergence_distance;
    if (!(convergence_distance == 3.4028234663852885981170418348452e+38))
    {
        vec4 screen_offset = D * convergence_distance;
        D = normalize(screen_offset - stereo_offset);
    }
}

void camera_sample_perspective(float raster_x, float raster_y, float lens_u, float lens_v, inout Ray ray)
{
    ProjectionTransform _2558;
    _2558.x = _1929.kernel_data.cam.rastertocamera.x;
    _2558.y = _1929.kernel_data.cam.rastertocamera.y;
    _2558.z = _1929.kernel_data.cam.rastertocamera.z;
    _2558.w = _1929.kernel_data.cam.rastertocamera.w;
    ProjectionTransform rastertocamera = _2558;
    vec4 raster = vec4(raster_x, raster_y, 0.0, 0.0);
    ProjectionTransform param = rastertocamera;
    vec4 Pcamera = transform_perspective(param, raster);
    vec4 P = vec4(0.0);
    vec4 D = Pcamera;
    float aperturesize = _1929.kernel_data.cam.aperturesize;
    if (aperturesize > 0.0)
    {
        float param_1 = lens_u;
        float param_2 = lens_v;
        vec2 lensuv = camera_sample_aperture(param_1, param_2) * aperturesize;
        float ft = _1929.kernel_data.cam.focaldistance / D.z;
        vec4 Pfocus = D * ft;
        P = vec4(lensuv.x, lensuv.y, 0.0, 0.0);
        D = normalize(Pfocus - P);
    }
    Transform _2612;
    _2612.x = _1929.kernel_data.cam.cameratoworld.x;
    _2612.y = _1929.kernel_data.cam.cameratoworld.y;
    _2612.z = _1929.kernel_data.cam.cameratoworld.z;
    Transform cameratoworld = _2612;
    Transform param_3 = cameratoworld;
    cameratoworld = param_3;
    P = transform_point(param_3, P);
    Transform param_4 = cameratoworld;
    cameratoworld = param_4;
    D = normalize(transform_direction(param_4, D));
    bool use_stereo = !(_1929.kernel_data.cam.interocular_offset == 0.0);
    if (!use_stereo)
    {
        ray.P = P;
        ray.D = D;
        Transform param_5 = cameratoworld;
        cameratoworld = param_5;
        vec4 Dcenter = transform_direction(param_5, Pcamera);
        ray.dP.dx = vec4(0.0);
        ray.dP.dy = vec4(0.0);
        ray.dD.dx = normalize(Dcenter + float4_to_float3(_1929.kernel_data.cam.dx)) - normalize(Dcenter);
        ray.dD.dy = normalize(Dcenter + float4_to_float3(_1929.kernel_data.cam.dy)) - normalize(Dcenter);
    }
    else
    {
        vec4 param_6 = P;
        vec4 param_7 = D;
        spherical_stereo_transform(param_6, param_7);
        P = param_6;
        D = param_7;
        ray.P = P;
        ray.D = D;
        Transform param_8 = cameratoworld;
        cameratoworld = param_8;
        vec4 Pnostereo = transform_point(param_8, vec4(0.0));
        vec4 Pcenter = Pnostereo;
        vec4 Dcenter_1 = Pcamera;
        Transform param_9 = cameratoworld;
        cameratoworld = param_9;
        Dcenter_1 = normalize(transform_direction(param_9, Dcenter_1));
        vec4 param_10 = Pcenter;
        vec4 param_11 = Dcenter_1;
        spherical_stereo_transform(param_10, param_11);
        Pcenter = param_10;
        Dcenter_1 = param_11;
        vec4 Px = Pnostereo;
        ProjectionTransform param_12 = rastertocamera;
        vec4 Dx = transform_perspective(param_12, vec4(raster_x + 1.0, raster_y, 0.0, 0.0));
        Transform param_13 = cameratoworld;
        cameratoworld = param_13;
        Dx = normalize(transform_direction(param_13, Dx));
        vec4 param_14 = Px;
        vec4 param_15 = Dx;
        spherical_stereo_transform(param_14, param_15);
        Px = param_14;
        Dx = param_15;
        ray.dP.dx = Px - Pcenter;
        ray.dD.dx = Dx - Dcenter_1;
        vec4 Py = Pnostereo;
        ProjectionTransform param_16 = rastertocamera;
        vec4 Dy = transform_perspective(param_16, vec4(raster_x, raster_y + 1.0, 0.0, 0.0));
        Transform param_17 = cameratoworld;
        cameratoworld = param_17;
        Dy = normalize(transform_direction(param_17, Dy));
        vec4 param_18 = Py;
        vec4 param_19 = Dy;
        spherical_stereo_transform(param_18, param_19);
        Py = param_18;
        Dy = param_19;
        ray.dP.dy = Py - Pcenter;
        ray.dD.dy = Dy - Dcenter_1;
    }
    float z_inv = 1.0 / normalize(Pcamera).z;
    float nearclip = _1929.kernel_data.cam.nearclip * z_inv;
    ray.P += (ray.D * nearclip);
    ray.dP.dx += (ray.dD.dx * nearclip);
    ray.dP.dy += (ray.dD.dy * nearclip);
    ray.t = _1929.kernel_data.cam.cliplength * z_inv;
}

void camera_sample_orthographic(float raster_x, float raster_y, float lens_u, float lens_v, inout Ray ray)
{
    ProjectionTransform _2804;
    _2804.x = _1929.kernel_data.cam.rastertocamera.x;
    _2804.y = _1929.kernel_data.cam.rastertocamera.y;
    _2804.z = _1929.kernel_data.cam.rastertocamera.z;
    _2804.w = _1929.kernel_data.cam.rastertocamera.w;
    ProjectionTransform rastertocamera = _2804;
    ProjectionTransform param = rastertocamera;
    vec4 Pcamera = transform_perspective(param, vec4(raster_x, raster_y, 0.0, 0.0));
    vec4 D = vec4(0.0, 0.0, 1.0, 0.0);
    float aperturesize = _1929.kernel_data.cam.aperturesize;
    vec4 P;
    if (aperturesize > 0.0)
    {
        float param_1 = lens_u;
        float param_2 = lens_v;
        vec2 lensuv = camera_sample_aperture(param_1, param_2) * aperturesize;
        vec4 Pfocus = D * _1929.kernel_data.cam.focaldistance;
        vec4 lensuvw = vec4(lensuv.x, lensuv.y, 0.0, 0.0);
        P = Pcamera + lensuvw;
        D = normalize(Pfocus - lensuvw);
    }
    else
    {
        P = Pcamera;
    }
    Transform _2852;
    _2852.x = _1929.kernel_data.cam.cameratoworld.x;
    _2852.y = _1929.kernel_data.cam.cameratoworld.y;
    _2852.z = _1929.kernel_data.cam.cameratoworld.z;
    Transform cameratoworld = _2852;
    Transform param_3 = cameratoworld;
    cameratoworld = param_3;
    ray.P = transform_point(param_3, P);
    Transform param_4 = cameratoworld;
    cameratoworld = param_4;
    ray.D = normalize(transform_direction(param_4, D));
    ray.dP.dx = float4_to_float3(_1929.kernel_data.cam.dx);
    ray.dP.dy = float4_to_float3(_1929.kernel_data.cam.dy);
    ray.dD.dx = vec4(0.0);
    ray.dD.dy = vec4(0.0);
    ray.t = _1929.kernel_data.cam.cliplength;
}

float safe_acosf(float a)
{
    return acos(clamp(a, -1.0, 1.0));
}

vec4 fisheye_equisolid_to_direction(inout float u, inout float v, float lens, float fov, float width, float height)
{
    u = (u - 0.5) * width;
    v = (v - 0.5) * height;
    float rmax = (2.0 * lens) * sin(fov * 0.25);
    float r = sqrt((u * u) + (v * v));
    if (r > rmax)
    {
        return vec4(0.0);
    }
    float _2282;
    if (!(r == 0.0))
    {
        _2282 = u / r;
    }
    else
    {
        _2282 = 0.0;
    }
    float param = _2282;
    float phi = safe_acosf(param);
    float theta = 2.0 * asin(r / (2.0 * lens));
    if (v < 0.0)
    {
        phi = -phi;
    }
    return vec4(cos(theta), (-cos(phi)) * sin(theta), sin(phi) * sin(theta), 0.0);
}

vec4 equirectangular_range_to_direction(float u, float v, vec4 range)
{
    float phi = (range.x * u) + range.y;
    float theta = (range.z * v) + range.w;
    float sin_theta = sin(theta);
    return vec4(sin_theta * cos(phi), sin_theta * sin(phi), cos(theta), 0.0);
}

vec4 mirrorball_to_direction(float u, float v)
{
    vec4 dir;
    dir.x = (2.0 * u) - 1.0;
    dir.z = (2.0 * v) - 1.0;
    if (((dir.x * dir.x) + (dir.z * dir.z)) > 1.0)
    {
        return vec4(0.0);
    }
    dir.y = -sqrt(max((1.0 - (dir.x * dir.x)) - (dir.z * dir.z), 0.0));
    vec4 I = vec4(0.0, -1.0, 0.0, 0.0);
    return (dir * (2.0 * dot(dir.xyz, I.xyz))) - I;
}

vec4 fisheye_to_direction(inout float u, inout float v, float fov)
{
    u = (u - 0.5) * 2.0;
    v = (v - 0.5) * 2.0;
    float r = sqrt((u * u) + (v * v));
    if (r > 1.0)
    {
        return vec4(0.0);
    }
    float _2212;
    if (!(r == 0.0))
    {
        _2212 = u / r;
    }
    else
    {
        _2212 = 0.0;
    }
    float param = _2212;
    float phi = safe_acosf(param);
    float theta = (r * fov) * 0.5;
    if (v < 0.0)
    {
        phi = -phi;
    }
    return vec4(cos(theta), (-cos(phi)) * sin(theta), sin(phi) * sin(theta), 0.0);
}

vec4 panorama_to_direction(float u, float v)
{
    switch (_1929.kernel_data.cam.panorama_type)
    {
        case 0:
        {
            float param = u;
            float param_1 = v;
            vec4 param_2 = _1929.kernel_data.cam.equirectangular_range;
            return equirectangular_range_to_direction(param, param_1, param_2);
        }
        case 3:
        {
            float param_3 = u;
            float param_4 = v;
            return mirrorball_to_direction(param_3, param_4);
        }
        case 1:
        {
            float param_5 = u;
            float param_6 = v;
            float param_7 = _1929.kernel_data.cam.fisheye_fov;
            vec4 _2406 = fisheye_to_direction(param_5, param_6, param_7);
            return _2406;
        }
        default:
        {
            float param_8 = u;
            float param_9 = v;
            float param_10 = _1929.kernel_data.cam.fisheye_lens;
            float param_11 = _1929.kernel_data.cam.fisheye_fov;
            float param_12 = _1929.kernel_data.cam.sensorwidth;
            float param_13 = _1929.kernel_data.cam.sensorheight;
            vec4 _2425 = fisheye_equisolid_to_direction(param_8, param_9, param_10, param_11, param_12, param_13);
            return _2425;
        }
    }
}

bool is_zero(vec4 a)
{
    bool _797 = a.x == 0.0;
    bool _812;
    if (!_797)
    {
        _812 = (int((floatBitsToUint(a.x) >> uint(23)) & 255u) - 127) < (-60);
    }
    else
    {
        _812 = _797;
    }
    bool _828;
    if (_812)
    {
        bool _816 = a.y == 0.0;
        bool _827;
        if (!_816)
        {
            _827 = (int((floatBitsToUint(a.y) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _827 = _816;
        }
        _828 = _827;
    }
    else
    {
        _828 = _812;
    }
    bool _844;
    if (_828)
    {
        bool _832 = a.z == 0.0;
        bool _843;
        if (!_832)
        {
            _843 = (int((floatBitsToUint(a.z) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _843 = _832;
        }
        _844 = _843;
    }
    else
    {
        _844 = _828;
    }
    return _844;
}

void camera_sample_panorama(float raster_x, float raster_y, float lens_u, float lens_v, inout Ray ray)
{
    ProjectionTransform _2882;
    _2882.x = _1929.kernel_data.cam.rastertocamera.x;
    _2882.y = _1929.kernel_data.cam.rastertocamera.y;
    _2882.z = _1929.kernel_data.cam.rastertocamera.z;
    _2882.w = _1929.kernel_data.cam.rastertocamera.w;
    ProjectionTransform rastertocamera = _2882;
    ProjectionTransform param = rastertocamera;
    vec4 Pcamera = transform_perspective(param, vec4(raster_x, raster_y, 0.0, 0.0));
    vec4 P = vec4(0.0);
    float param_1 = Pcamera.x;
    float param_2 = Pcamera.y;
    vec4 D = panorama_to_direction(param_1, param_2);
    if (is_zero(D))
    {
        ray.t = 0.0;
        return;
    }
    float aperturesize = _1929.kernel_data.cam.aperturesize;
    if (aperturesize > 0.0)
    {
        float param_3 = lens_u;
        float param_4 = lens_v;
        vec2 lensuv = camera_sample_aperture(param_3, param_4) * aperturesize;
        vec4 Dfocus = normalize(D);
        vec4 Pfocus = Dfocus * _1929.kernel_data.cam.focaldistance;
        vec4 U = normalize(vec4(1.0, 0.0, 0.0, 0.0) - (Dfocus * Dfocus.x));
        vec4 param_5 = Dfocus;
        vec4 param_6 = U;
        vec4 V = normalize(_cross(param_5, param_6));
        P = (U * lensuv.x) + (V * lensuv.y);
        D = normalize(Pfocus - P);
    }
    Transform _2959;
    _2959.x = _1929.kernel_data.cam.cameratoworld.x;
    _2959.y = _1929.kernel_data.cam.cameratoworld.y;
    _2959.z = _1929.kernel_data.cam.cameratoworld.z;
    Transform cameratoworld = _2959;
    Transform param_7 = cameratoworld;
    cameratoworld = param_7;
    P = transform_point(param_7, P);
    Transform param_8 = cameratoworld;
    cameratoworld = param_8;
    D = normalize(transform_direction(param_8, D));
    bool use_stereo = !(_1929.kernel_data.cam.interocular_offset == 0.0);
    if (use_stereo)
    {
        vec4 param_9 = P;
        vec4 param_10 = D;
        spherical_stereo_transform(param_9, param_10);
        P = param_9;
        D = param_10;
    }
    ray.P = P;
    ray.D = D;
    vec4 Pcenter = Pcamera;
    float param_11 = Pcenter.x;
    float param_12 = Pcenter.y;
    vec4 Dcenter = panorama_to_direction(param_11, param_12);
    Transform param_13 = cameratoworld;
    cameratoworld = param_13;
    Pcenter = transform_point(param_13, Pcenter);
    Transform param_14 = cameratoworld;
    cameratoworld = param_14;
    Dcenter = normalize(transform_direction(param_14, Dcenter));
    if (use_stereo)
    {
        vec4 param_15 = Pcenter;
        vec4 param_16 = Dcenter;
        spherical_stereo_transform(param_15, param_16);
        Pcenter = param_15;
        Dcenter = param_16;
    }
    ProjectionTransform param_17 = rastertocamera;
    vec4 Px = transform_perspective(param_17, vec4(raster_x + 1.0, raster_y, 0.0, 0.0));
    float param_18 = Px.x;
    float param_19 = Px.y;
    vec4 Dx = panorama_to_direction(param_18, param_19);
    Transform param_20 = cameratoworld;
    cameratoworld = param_20;
    Px = transform_point(param_20, Px);
    Transform param_21 = cameratoworld;
    cameratoworld = param_21;
    Dx = normalize(transform_direction(param_21, Dx));
    if (use_stereo)
    {
        vec4 param_22 = Px;
        vec4 param_23 = Dx;
        spherical_stereo_transform(param_22, param_23);
        Px = param_22;
        Dx = param_23;
    }
    ray.dP.dx = Px - Pcenter;
    ray.dD.dx = Dx - Dcenter;
    ProjectionTransform param_24 = rastertocamera;
    vec4 Py = transform_perspective(param_24, vec4(raster_x, raster_y + 1.0, 0.0, 0.0));
    float param_25 = Py.x;
    float param_26 = Py.y;
    vec4 Dy = panorama_to_direction(param_25, param_26);
    Transform param_27 = cameratoworld;
    cameratoworld = param_27;
    Py = transform_point(param_27, Py);
    Transform param_28 = cameratoworld;
    cameratoworld = param_28;
    Dy = normalize(transform_direction(param_28, Dy));
    if (use_stereo)
    {
        vec4 param_29 = Py;
        vec4 param_30 = Dy;
        spherical_stereo_transform(param_29, param_30);
        Py = param_29;
        Dy = param_30;
    }
    ray.dP.dy = Py - Pcenter;
    ray.dD.dy = Dy - Dcenter;
    float nearclip = _1929.kernel_data.cam.nearclip;
    ray.P += (ray.D * nearclip);
    ray.dP.dx += (ray.dD.dx * nearclip);
    ray.dP.dy += (ray.dD.dy * nearclip);
    ray.t = _1929.kernel_data.cam.cliplength;
}

void camera_sample(int x, int y, float filter_u, float filter_v, float lens_u, float lens_v, float time, inout Ray ray)
{
    int filter_table_offset = _1929.kernel_data.film.filter_table_offset;
    float param = filter_u;
    int param_1 = filter_table_offset;
    int param_2 = 1024;
    float _3153 = lookup_table_read(param, param_1, param_2);
    float raster_x = float(x) + _3153;
    float param_3 = filter_v;
    int param_4 = filter_table_offset;
    int param_5 = 1024;
    float _3163 = lookup_table_read(param_3, param_4, param_5);
    float raster_y = float(y) + _3163;
    if (uint(_1929.kernel_data.cam.type) == 0u)
    {
        float param_6 = raster_x;
        float param_7 = raster_y;
        float param_8 = lens_u;
        float param_9 = lens_v;
        Ray param_10 = ray;
        camera_sample_perspective(param_6, param_7, param_8, param_9, param_10);
        ray = param_10;
    }
    else
    {
        if (uint(_1929.kernel_data.cam.type) == 1u)
        {
            float param_11 = raster_x;
            float param_12 = raster_y;
            float param_13 = lens_u;
            float param_14 = lens_v;
            Ray param_15 = ray;
            camera_sample_orthographic(param_11, param_12, param_13, param_14, param_15);
            ray = param_15;
        }
        else
        {
            float param_16 = raster_x;
            float param_17 = raster_y;
            float param_18 = lens_u;
            float param_19 = lens_v;
            Ray param_20 = ray;
            camera_sample_panorama(param_16, param_17, param_18, param_19, param_20);
            ray = param_20;
        }
    }
}

void kernel_path_trace_setup(int x, int y, int sample_rsv, inout uint rng_hash, inout Ray ray)
{
    int num_samples = _1929.kernel_data.integrator.aa_samples;
    arg2.v[0] = uintBitsToFloat(rng_hash);
    arg2.v[1] = intBitsToFloat(sample_rsv);
    arg2.v[2] = intBitsToFloat(num_samples);
    arg2.v[3] = intBitsToFloat(0);
    arg2.v[4] = uintBitsToFloat(2u);
    arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
    arg2.v[6] = uintBitsToFloat(uint(x));
    arg2.v[7] = uintBitsToFloat(uint(y));
    arg2.v[8] = intBitsToFloat(_1929.kernel_data.integrator.seed);
    executeCallableNV(11u, 2);
    float filter_u = arg2.v[0];
    float filter_v = arg2.v[1];
    rng_hash = uint(floatBitsToInt(arg2.v[2]));
    float lens_u = 0.0;
    float lens_v = 0.0;
    if (_1929.kernel_data.cam.aperturesize > 0.0)
    {
        arg2.v[0] = uintBitsToFloat(rng_hash);
        arg2.v[1] = intBitsToFloat(sample_rsv);
        arg2.v[2] = intBitsToFloat(num_samples);
        arg2.v[3] = intBitsToFloat(2);
        arg2.v[4] = uintBitsToFloat(1u);
        arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
        executeCallableNV(11u, 2);
        lens_u = arg2.v[0];
        lens_v = arg2.v[1];
    }
    float time = 0.0;
    int param = x;
    int param_1 = y;
    float param_2 = filter_u;
    float param_3 = filter_v;
    float param_4 = lens_u;
    float param_5 = lens_v;
    float param_6 = time;
    Ray param_7 = ray;
    camera_sample(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7);
    ray = param_7;
}

void path_state_init(uint rng_hash, int sample_rsv)
{
    arg.state.flag = 540673;
    arg.state.rng_hash = rng_hash;
    arg.state.rng_offset = 10;
    arg.state.sample_rsv = sample_rsv;
    arg.state.num_samples = _1929.kernel_data.integrator.aa_samples;
    arg.state.branch_factor = 1.0;
    arg.state.bounce = 0;
    arg.state.diffuse_bounce = 0;
    arg.state.glossy_bounce = 0;
    arg.state.transmission_bounce = 0;
    arg.state.transparent_bounce = 0;
    arg.state.min_ray_pdf = 3.4028234663852885981170418348452e+38;
    arg.state.ray_pdf = 0.0;
    arg.state.ray_t = 0.0;
}

uint path_state_ray_visibility()
{
    uint flag = uint(arg.state.flag & 16383);
    if ((flag & 4u) != 0u)
    {
        flag &= 4294967271u;
    }
    if ((uint(arg.state.flag) & 4096u) != 0u)
    {
        flag |= 8u;
    }
    return flag;
}

bool path_state_ao_bounce()
{
    if (arg.state.bounce <= _1929.kernel_data.integrator.ao_bounces)
    {
        return false;
    }
    int bounce = (arg.state.bounce - arg.state.transmission_bounce) - int(arg.state.glossy_bounce > 0);
    return bounce > _1929.kernel_data.integrator.ao_bounces;
}

bool isfinite_safe(float f)
{
    uint x = floatBitsToUint(f);
    bool _706 = f == f;
    bool _724;
    if (_706)
    {
        bool _714 = (x == 0u) || (x == 2147483648u);
        bool _723;
        if (!_714)
        {
            _723 = !(f == (2.0 * f));
        }
        else
        {
            _723 = _714;
        }
        _724 = _723;
    }
    else
    {
        _724 = _706;
    }
    bool _733;
    if (_724)
    {
        _733 = !((x << uint(1)) > 4278190080u);
    }
    else
    {
        _733 = _724;
    }
    return _733;
}

float len_squared(vec4 a)
{
    return dot(a.xyz, a.xyz);
}

bool scene_intersect(Ray ray, uint visibility)
{
    float param = ray.P.x;
    bool _10504 = isfinite_safe(param);
    bool _10511;
    if (_10504)
    {
        float param_1 = ray.D.x;
        _10511 = isfinite_safe(param_1);
    }
    else
    {
        _10511 = _10504;
    }
    bool _10518;
    if (_10511)
    {
        _10518 = !(len_squared(ray.D) == 0.0);
    }
    else
    {
        _10518 = _10511;
    }
    if (_10518)
    {
        isect.type = 0;
        isect.t = uintBitsToFloat(visibility);
        isect.prim = -1;
        traceNV(topLevelAS, 0u, 255u, 0u, 0u, 0u, ray.P.xyz, 0.0, ray.D.xyz, ray.t, 0);
        if (isect.prim != (-1))
        {
            sd.geometry = isect.type;
            isect.type = int(push.data_ptr._prim_type.data[isect.prim]);
            return !(uint(isect.type) == 0u);
        }
    }
    return false;
}

bool kernel_path_scene_intersect(inout Ray ray)
{
    uint visibility = path_state_ray_visibility();
    if (path_state_ao_bounce())
    {
        visibility = 1920u;
        ray.t = _1929.kernel_data.background.ao_distance;
    }
    Ray param = ray;
    bool _10571 = scene_intersect(param, visibility);
    return _10571;
}

void kernel_path_lamp_emission(Ray ray)
{
    bool _10336 = _1929.kernel_data.integrator.use_lamp_mis != int(0u);
    bool _10345;
    if (_10336)
    {
        _10345 = !((uint(arg.state.flag) & 1u) != 0u);
    }
    else
    {
        _10345 = _10336;
    }
    if (_10345)
    {
        arg.ray.P = ray.P - (ray.D * arg.state.ray_t);
        arg.state.ray_t += isect.t;
        arg.ray.D = ray.D;
        arg.ray.t = arg.state.ray_t;
        arg.ray.time = ray.time;
        arg.ray.dD = ray.dD;
        arg.ray.dP = ray.dP;
        arg.type = 2;
        arg.use_light_pass = L.use_light_pass;
        arg.L.emission = L.emission;
        arg.L.direct_emission = L.direct_emission;
        arg.L.indirect = L.indirect;
        arg.L.path_total = L.path_total;
        arg.L.throughput = throughput;
        arg.L.direct_emission.w = float(PROFI_IDX);
        arg.L.indirect.w = float(rec_num);
        int _10403 = atomicAdd(_6660.counter[32], 1);
        executeCallableNV(0u, 0);
        L.emission = arg.L.emission;
        L.direct_emission = arg.L.direct_emission;
        L.indirect = arg.L.indirect;
        L.path_total = arg.L.path_total;
        throughput = arg.L.throughput;
        if (G_dump)
        {
            _685.kg.f3[0 + ((rec_num - 1) * 64)] = L.emission;
        }
        if (G_use_light_pass)
        {
            if (G_dump)
            {
                _685.kg.f3[1 + ((rec_num - 1) * 64)] = L.direct_emission;
            }
            if (G_dump)
            {
                _685.kg.f3[2 + ((rec_num - 1) * 64)] = L.indirect;
            }
        }
    }
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
    sd.shader = _1929.kernel_data.background.surface_shader;
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

uint lcg_step_uint(inout uint rng)
{
    rng = (1103515245u * rng) + 12345u;
    return rng;
}

uint lcg_init(uint seed)
{
    uint rng = seed;
    uint param = rng;
    uint _1888 = lcg_step_uint(param);
    rng = param;
    return rng;
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
        max_closures = _1929.kernel_data.integrator.max_closures;
    }
    sd.num_closure = int(state_flag);
    sd.num_closure_left = max_closures;
    sd.alloc_offset = rec_num;
    executeCallableNV(2u, 1);
    if ((uint(sd.flag) & 1024u) != 0u)
    {
        uint param = (arg.state.rng_hash + uint(arg.state.rng_offset)) + (uint(arg.state.sample_rsv) * 3032234323u);
        sd.lcg_state = lcg_init(param);
    }
}

bool background_portal_data_fetch_and_check_side(vec4 P, int index, inout vec4 lightpos, inout vec4 dir)
{
    int portal = _1929.kernel_data.background.portal_offset + index;
    KernelLight _4331;
    _4331.type = push.data_ptr._lights.data[portal].type;
    _4331.co[0] = push.data_ptr._lights.data[portal].co[0];
    _4331.co[1] = push.data_ptr._lights.data[portal].co[1];
    _4331.co[2] = push.data_ptr._lights.data[portal].co[2];
    _4331.shader_id = push.data_ptr._lights.data[portal].shader_id;
    _4331.samples = push.data_ptr._lights.data[portal].samples;
    _4331.max_bounces = push.data_ptr._lights.data[portal].max_bounces;
    _4331.random = push.data_ptr._lights.data[portal].random;
    _4331.strength[0] = push.data_ptr._lights.data[portal].strength[0];
    _4331.strength[1] = push.data_ptr._lights.data[portal].strength[1];
    _4331.strength[2] = push.data_ptr._lights.data[portal].strength[2];
    _4331.pad1 = push.data_ptr._lights.data[portal].pad1;
    _4331.tfm.x = push.data_ptr._lights.data[portal].tfm.x;
    _4331.tfm.y = push.data_ptr._lights.data[portal].tfm.y;
    _4331.tfm.z = push.data_ptr._lights.data[portal].tfm.z;
    _4331.itfm.x = push.data_ptr._lights.data[portal].itfm.x;
    _4331.itfm.y = push.data_ptr._lights.data[portal].itfm.y;
    _4331.itfm.z = push.data_ptr._lights.data[portal].itfm.z;
    _4331.uni[0] = push.data_ptr._lights.data[portal].uni[0];
    _4331.uni[1] = push.data_ptr._lights.data[portal].uni[1];
    _4331.uni[2] = push.data_ptr._lights.data[portal].uni[2];
    _4331.uni[3] = push.data_ptr._lights.data[portal].uni[3];
    _4331.uni[4] = push.data_ptr._lights.data[portal].uni[4];
    _4331.uni[5] = push.data_ptr._lights.data[portal].uni[5];
    _4331.uni[6] = push.data_ptr._lights.data[portal].uni[6];
    _4331.uni[7] = push.data_ptr._lights.data[portal].uni[7];
    _4331.uni[8] = push.data_ptr._lights.data[portal].uni[8];
    _4331.uni[9] = push.data_ptr._lights.data[portal].uni[9];
    _4331.uni[10] = push.data_ptr._lights.data[portal].uni[10];
    _4331.uni[11] = push.data_ptr._lights.data[portal].uni[11];
    KernelLight klight = _4331;
    lightpos = vec4(klight.co[0], klight.co[1], klight.co[2], 0.0);
    dir = vec4(klight.uni[8], klight.uni[9], klight.uni[10], 0.0);
    if (dot(dir.xyz, (P - lightpos).xyz) > 9.9999997473787516355514526367188e-05)
    {
        return true;
    }
    return false;
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
    bool _1089;
    if (ellipse)
    {
        _1089 = ((u * u) + (v * v)) > 0.25;
    }
    else
    {
        _1089 = ellipse;
    }
    if (_1089)
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

vec4 normalize_len(vec4 a, inout float t)
{
    t = length(a.xyz);
    float x = 1.0 / t;
    return vec4(a.xyz * x, 0.0);
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

float rect_light_sample(vec4 P, inout vec4 light_p, vec4 axisu, vec4 axisv, float randu, float randv, bool sample_coord)
{
    vec4 corner = (light_p - (axisu * 0.5)) - (axisv * 0.5);
    float axisu_len;
    float param = axisu_len;
    vec4 _3904 = normalize_len(axisu, param);
    axisu_len = param;
    vec4 x = _3904;
    float axisv_len;
    float param_1 = axisv_len;
    vec4 _3911 = normalize_len(axisv, param_1);
    axisv_len = param_1;
    vec4 y = _3911;
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
        float _4152;
        if (hv2 < 0.999998986721038818359375)
        {
            _4152 = (hv * d) / sqrt(1.0 - hv2);
        }
        else
        {
            _4152 = y1;
        }
        float yv = _4152;
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
    for (int p = 0; p < _1929.kernel_data.background.num_portals; p++)
    {
        if (p == ignore_portal)
        {
            continue;
        }
        vec4 param = P;
        int param_1 = p;
        vec4 param_2 = lightpos;
        vec4 param_3 = dir;
        bool _4388 = background_portal_data_fetch_and_check_side(param, param_1, param_2, param_3);
        lightpos = param_2;
        dir = param_3;
        if (!_4388)
        {
            continue;
        }
        if (is_possible)
        {
            is_possible = true;
        }
        num_possible++;
        int portal = _1929.kernel_data.background.portal_offset + p;
        KernelLight _4413;
        _4413.type = push.data_ptr._lights.data[portal].type;
        _4413.co[0] = push.data_ptr._lights.data[portal].co[0];
        _4413.co[1] = push.data_ptr._lights.data[portal].co[1];
        _4413.co[2] = push.data_ptr._lights.data[portal].co[2];
        _4413.shader_id = push.data_ptr._lights.data[portal].shader_id;
        _4413.samples = push.data_ptr._lights.data[portal].samples;
        _4413.max_bounces = push.data_ptr._lights.data[portal].max_bounces;
        _4413.random = push.data_ptr._lights.data[portal].random;
        _4413.strength[0] = push.data_ptr._lights.data[portal].strength[0];
        _4413.strength[1] = push.data_ptr._lights.data[portal].strength[1];
        _4413.strength[2] = push.data_ptr._lights.data[portal].strength[2];
        _4413.pad1 = push.data_ptr._lights.data[portal].pad1;
        _4413.tfm.x = push.data_ptr._lights.data[portal].tfm.x;
        _4413.tfm.y = push.data_ptr._lights.data[portal].tfm.y;
        _4413.tfm.z = push.data_ptr._lights.data[portal].tfm.z;
        _4413.itfm.x = push.data_ptr._lights.data[portal].itfm.x;
        _4413.itfm.y = push.data_ptr._lights.data[portal].itfm.y;
        _4413.itfm.z = push.data_ptr._lights.data[portal].itfm.z;
        _4413.uni[0] = push.data_ptr._lights.data[portal].uni[0];
        _4413.uni[1] = push.data_ptr._lights.data[portal].uni[1];
        _4413.uni[2] = push.data_ptr._lights.data[portal].uni[2];
        _4413.uni[3] = push.data_ptr._lights.data[portal].uni[3];
        _4413.uni[4] = push.data_ptr._lights.data[portal].uni[4];
        _4413.uni[5] = push.data_ptr._lights.data[portal].uni[5];
        _4413.uni[6] = push.data_ptr._lights.data[portal].uni[6];
        _4413.uni[7] = push.data_ptr._lights.data[portal].uni[7];
        _4413.uni[8] = push.data_ptr._lights.data[portal].uni[8];
        _4413.uni[9] = push.data_ptr._lights.data[portal].uni[9];
        _4413.uni[10] = push.data_ptr._lights.data[portal].uni[10];
        _4413.uni[11] = push.data_ptr._lights.data[portal].uni[11];
        KernelLight klight = _4413;
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
        bool _4458 = ray_quad_intersect(param_4, param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16);
        _n4 = param_12;
        _n0 = param_13;
        _n1 = param_14;
        _n2 = param_15;
        if (!_4458)
        {
            continue;
        }
        if (is_round)
        {
            float param_17 = t;
            vec4 _4477 = normalize_len(lightpos - P, param_17);
            t = param_17;
            vec4 D = _4477;
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
            float _4503 = rect_light_sample(param_19, param_20, param_21, param_22, param_23, param_24, param_25);
            lightpos = param_20;
            portal_pdf += _4503;
        }
    }
    if (ignore_portal >= 0)
    {
        num_possible++;
    }
    float _4517;
    if (num_possible > 0)
    {
        _4517 = portal_pdf / float(num_possible);
    }
    else
    {
        _4517 = 0.0;
    }
    return _4517;
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
    vec4 N = float4_to_float3(_1929.kernel_data.background.sun);
    float angle = _1929.kernel_data.background.sun.w;
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
    int res_x = _1929.kernel_data.background.map_res_x;
    int res_y = _1929.kernel_data.background.map_res_y;
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

float background_light_pdf(vec4 P, vec4 direction)
{
    float portal_method_pdf = _1929.kernel_data.background.portal_weight;
    float sun_method_pdf = _1929.kernel_data.background.sun_weight;
    float map_method_pdf = _1929.kernel_data.background.map_weight;
    float portal_pdf = 0.0;
    if (portal_method_pdf > 0.0)
    {
        bool is_possible = false;
        vec4 param = P;
        vec4 param_1 = direction;
        int param_2 = -1;
        bool param_3 = is_possible;
        float _4566 = background_portal_pdf(param, param_1, param_2, param_3);
        is_possible = param_3;
        portal_pdf = _4566;
        if (!is_possible)
        {
            portal_method_pdf = 0.0;
        }
    }
    float pdf_fac = (portal_method_pdf + sun_method_pdf) + map_method_pdf;
    if (pdf_fac == 0.0)
    {
        return _1929.kernel_data.integrator.pdf_lights / 12.56637096405029296875;
    }
    pdf_fac = 1.0 / pdf_fac;
    portal_method_pdf *= pdf_fac;
    sun_method_pdf *= pdf_fac;
    map_method_pdf *= pdf_fac;
    float pdf = portal_pdf * portal_method_pdf;
    if (!(sun_method_pdf == 0.0))
    {
        vec4 param_4 = direction;
        pdf += (background_sun_pdf(param_4) * sun_method_pdf);
    }
    if (!(map_method_pdf == 0.0))
    {
        vec4 param_5 = direction;
        pdf += (background_map_pdf(param_5) * map_method_pdf);
    }
    return pdf * _1929.kernel_data.integrator.pdf_lights;
}

float power_heuristic(float a, float b)
{
    return (a * a) / ((a * a) + (b * b));
}

vec4 indirect_background(Ray ray)
{
    int shader = _1929.kernel_data.background.surface_shader;
    if ((uint(shader) & 260046848u) != 0u)
    {
        bool _7774 = (uint(shader) & 134217728u) != 0u;
        bool _7782;
        if (_7774)
        {
            _7782 = (uint(arg.state.flag) & 8u) != 0u;
        }
        else
        {
            _7782 = _7774;
        }
        bool _7800;
        if (!_7782)
        {
            bool _7790 = (uint(shader) & 67108864u) != 0u;
            bool _7799;
            if (_7790)
            {
                _7799 = (uint(arg.state.flag) & 18u) == 18u;
            }
            else
            {
                _7799 = _7790;
            }
            _7800 = _7799;
        }
        else
        {
            _7800 = _7782;
        }
        bool _7817;
        if (!_7800)
        {
            bool _7808 = (uint(shader) & 33554432u) != 0u;
            bool _7816;
            if (_7808)
            {
                _7816 = (uint(arg.state.flag) & 4u) != 0u;
            }
            else
            {
                _7816 = _7808;
            }
            _7817 = _7816;
        }
        else
        {
            _7817 = _7800;
        }
        bool _7834;
        if (!_7817)
        {
            bool _7825 = (uint(shader) & 16777216u) != 0u;
            bool _7833;
            if (_7825)
            {
                _7833 = (uint(arg.state.flag) & 1u) != 0u;
            }
            else
            {
                _7833 = _7825;
            }
            _7834 = _7833;
        }
        else
        {
            _7834 = _7817;
        }
        bool _7851;
        if (!_7834)
        {
            bool _7842 = (uint(shader) & 8388608u) != 0u;
            bool _7850;
            if (_7842)
            {
                _7850 = (uint(arg.state.flag) & 4096u) != 0u;
            }
            else
            {
                _7850 = _7842;
            }
            _7851 = _7850;
        }
        else
        {
            _7851 = _7834;
        }
        if (_7851)
        {
            return vec4(0.0);
        }
    }
    vec4 L_1 = vec4(0.0);
    int param = shader;
    vec4 param_1 = L_1;
    bool _7860 = shader_constant_emission_eval(param, param_1);
    L_1 = param_1;
    if (!_7860)
    {
        Ray param_2 = ray;
        shader_setup_from_background(param_2);
        if (true)
        {
            arg.state.bounce++;
        }
        else
        {
            arg.state.bounce--;
        }
        uint param_3 = uint(arg.state.flag) | 4194304u;
        shader_eval_surface(param_3);
        if (false)
        {
            arg.state.bounce++;
        }
        else
        {
            arg.state.bounce--;
        }
        vec4 _7902;
        if ((uint(sd.flag) & 2u) != 0u)
        {
            _7902 = sd.closure_emission_background;
        }
        else
        {
            _7902 = vec4(0.0);
        }
        L_1 = _7902;
    }
    bool _7914 = !((uint(arg.state.flag) & 16384u) != 0u);
    bool _7920;
    if (_7914)
    {
        _7920 = _1929.kernel_data.background.use_mis != int(0u);
    }
    else
    {
        _7920 = _7914;
    }
    if (_7920)
    {
        vec4 param_4 = ray.P;
        vec4 param_5 = ray.D;
        float pdf = background_light_pdf(param_4, param_5);
        float param_6 = arg.state.ray_pdf;
        float param_7 = pdf;
        float mis_weight = power_heuristic(param_6, param_7);
        return L_1 * mis_weight;
    }
    return L_1;
}

void path_radiance_accum_background(vec4 value)
{
    if ((uint(arg.state.flag) & 262144u) != 0u)
    {
        L.path_total += (throughput * value);
        L.path_total_shaded += ((throughput * value) * L.shadow_transparency);
        if ((uint(arg.state.flag) & 131072u) != 0u)
        {
            return;
        }
    }
    vec4 contribution = throughput * value;
    float _5827;
    if ((arg.state.bounce - 1) > 0)
    {
        _5827 = _1929.kernel_data.integrator.sample_clamp_indirect;
    }
    else
    {
        _5827 = _1929.kernel_data.integrator.sample_clamp_direct;
    }
    float limit = _5827;
    float sum = reduce_add(abs(contribution));
    if (sum > limit)
    {
        contribution *= (limit / sum);
    }
    if (L.use_light_pass != 0)
    {
        if ((uint(arg.state.flag) & 524288u) != 0u)
        {
            L.background += contribution;
        }
        else
        {
            if (arg.state.bounce == 1)
            {
                L.direct_emission += contribution;
            }
            else
            {
                L.indirect += contribution;
            }
        }
    }
    else
    {
        L.emission += contribution;
    }
}

void kernel_path_background(Ray ray)
{
    bool _10453 = _1929.kernel_data.background.transparent != int(0u);
    bool _10461;
    if (_10453)
    {
        _10461 = (uint(arg.state.flag) & 524288u) != 0u;
    }
    else
    {
        _10461 = _10453;
    }
    if (_10461)
    {
        L.transparent += average(throughput);
        if (!((_1929.kernel_data.film.light_pass_flag & 4) != int(0u)))
        {
            return;
        }
    }
    if (path_state_ao_bounce())
    {
        throughput *= _1929.kernel_data.background.ao_bounces_factor;
    }
    Ray param = ray;
    vec4 _10488 = indirect_background(param);
    vec4 L_background = _10488;
    vec4 param_1 = L_background;
    path_radiance_accum_background(param_1);
    if (G_dump)
    {
        _685.kg.f3[17 + ((rec_num - 1) * 64)] = L_background;
    }
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
    float _1365;
    if (!(det == 0.0))
    {
        _1365 = 1.0 / det;
    }
    else
    {
        _1365 = 0.0;
    }
    det = _1365;
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
        Transform _3333;
        _3333.x = push.data_ptr._objects.data[object].itfm.x;
        _3333.y = push.data_ptr._objects.data[object].itfm.y;
        _3333.z = push.data_ptr._objects.data[object].itfm.z;
        Transform _3332 = _3333;
        return _3332;
    }
    else
    {
        Transform _3345;
        _3345.x = push.data_ptr._objects.data[object].tfm.x;
        _3345.y = push.data_ptr._objects.data[object].tfm.y;
        _3345.z = push.data_ptr._objects.data[object].tfm.z;
        Transform _3344 = _3345;
        return _3344;
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
        Transform _6475 = transform_quick_inverse(param_2);
        sd.ob_itfm = _6475;
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

vec4 triangle_normal()
{
    uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * sd.prim], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 1], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
    vec4 v0 = push.data_ptr._prim_tri_verts2.data[tri_vindex.x];
    vec4 v1 = push.data_ptr._prim_tri_verts2.data[tri_vindex.y];
    vec4 v2 = push.data_ptr._prim_tri_verts2.data[tri_vindex.z];
    if ((uint(sd.object_flag) & 8u) != 0u)
    {
        return vec4(normalize(cross(v2.xyz - v0.xyz, v1.xyz - v0.xyz)), 0.0);
    }
    else
    {
        return vec4(normalize(cross(v1.xyz - v0.xyz, v2.xyz - v0.xyz)), 0.0);
    }
}

vec4 triangle_refine(inout vec4 P, inout vec4 D, inout float t, int object, int prim, int geometry)
{
    if (!((object & 8388608) != int(0u)))
    {
        if (t == 0.0)
        {
            return P;
        }
        Transform tfm = sd.ob_itfm;
        Transform param = tfm;
        tfm = param;
        P = transform_point(param, P);
        Transform param_1 = tfm;
        tfm = param_1;
        D = transform_direction(param_1, D * t);
        float param_2 = t;
        vec4 _3701 = normalize_len(D, param_2);
        t = param_2;
        D = _3701;
    }
    P += (D * t);
    uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * prim], push.data_ptr._tri_vindex2.data[(3 * prim) + 1], push.data_ptr._tri_vindex2.data[(3 * prim) + 2]) + uvec3(push.data_ptr._prim_index.data[geometry]);
    vec4 tri_a = push.data_ptr._prim_tri_verts2.data[tri_vindex.x];
    vec4 tri_b = push.data_ptr._prim_tri_verts2.data[tri_vindex.y];
    vec4 tri_c = push.data_ptr._prim_tri_verts2.data[tri_vindex.z];
    vec4 edge1 = vec4(tri_a.x - tri_c.x, tri_a.y - tri_c.y, tri_a.z - tri_c.z, 0.0);
    vec4 edge2 = vec4(tri_b.x - tri_c.x, tri_b.y - tri_c.y, tri_b.z - tri_c.z, 0.0);
    vec4 tvec = vec4(P.x - tri_c.x, P.y - tri_c.y, P.z - tri_c.z, 0.0);
    vec3 qvec = cross(tvec.xyz, edge1.xyz);
    vec3 pvec = cross(D.xyz, edge2.xyz);
    float det = dot(edge1.xyz, pvec);
    if (!(det == 0.0))
    {
        float rt = dot(edge2.xyz, qvec) / det;
        P += (D * rt);
    }
    if (!((object & 8388608) != int(0u)))
    {
        Transform tfm_1 = sd.ob_tfm;
        Transform param_3 = tfm_1;
        tfm_1 = param_3;
        P = transform_point(param_3, P);
    }
    return P;
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

vec4 triangle_smooth_normal(vec4 Ng, int prim, float u, float v)
{
    uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * prim], push.data_ptr._tri_vindex2.data[(3 * prim) + 1], push.data_ptr._tri_vindex2.data[(3 * prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
    vec4 n0 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.x]);
    vec4 n1 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.y]);
    vec4 n2 = float4_to_float3(push.data_ptr._tri_vnormal.data[tri_vindex.z]);
    vec4 N = safe_normalize(((n2 * ((1.0 - u) - v)) + (n0 * u)) + (n1 * v));
    return is_zero(N) ? Ng : N;
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

void object_dir_transform(inout vec4 D)
{
    Transform param = sd.ob_tfm;
    sd.ob_tfm = param;
    D = transform_direction(param, D);
}

void shader_setup_from_ray(Ray ray)
{
    sd.object = isect.object & 8388607;
    sd.lamp = -1;
    sd.flag = 0;
    sd.type = isect.type;
    sd.object_flag = int(push.data_ptr._object_flag.data[sd.object]);
    float param = ray.time;
    shader_setup_object_transforms(param);
    sd.time = ray.time;
    sd.prim = isect.prim;
    sd.ray_length = isect.t;
    sd.u = isect.u;
    sd.v = isect.v;
    if ((uint(sd.type) & 1u) != 0u)
    {
        vec4 Ng = triangle_normal();
        sd.shader = int(push.data_ptr._tri_shader.data[sd.prim]);
        vec4 param_1 = ray.P;
        vec4 param_2 = ray.D;
        float param_3 = isect.t;
        int param_4 = isect.object;
        int param_5 = isect.prim;
        int param_6 = sd.geometry;
        vec4 _6630 = triangle_refine(param_1, param_2, param_3, param_4, param_5, param_6);
        sd.P = _6630;
        sd.Ng = Ng;
        sd.N = Ng;
        if ((uint(sd.shader) & 2147483648u) != 0u)
        {
            vec4 param_7 = Ng;
            int param_8 = sd.prim;
            float param_9 = sd.u;
            float param_10 = sd.v;
            sd.N = triangle_smooth_normal(param_7, param_8, param_9, param_10);
        }
        int _6662 = atomicAdd(_6660.counter[34], 1);
        if (G_dump)
        {
            _685.kg.f3[3 + ((rec_num - 1) * 64)] = sd.N;
        }
        uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * sd.prim], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 1], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
        vec4 p0 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.x]);
        vec4 p1 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.y]);
        vec4 p2 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.z]);
        sd.dPdu = p0 - p2;
        sd.dPdv = p1 - p2;
    }
    sd.I = -ray.D;
    sd.flag |= push.data_ptr._shaders.data[uint(sd.shader) & 8388607u].flags;
    if (!((isect.object & 8388608) != int(0u)))
    {
        vec4 param_11 = sd.N;
        object_normal_transform(param_11);
        sd.N = param_11;
        vec4 param_12 = sd.Ng;
        object_normal_transform(param_12);
        sd.Ng = param_12;
        vec4 param_13 = sd.dPdu;
        object_dir_transform(param_13);
        sd.dPdu = param_13;
        vec4 param_14 = sd.dPdv;
        object_dir_transform(param_14);
        sd.dPdv = param_14;
    }
    bool backfacing = dot(sd.Ng.xyz, sd.I.xyz) < 0.0;
    if (backfacing)
    {
        sd.flag |= 1;
        sd.Ng = -sd.Ng;
        sd.N = -sd.N;
        sd.dPdu = -sd.dPdu;
        sd.dPdv = -sd.dPdv;
    }
    vec4 tmp = ray.D / vec4(dot(ray.D.xyz, sd.Ng.xyz));
    vec4 tmpx = ray.dP.dx + (ray.dD.dx * isect.t);
    vec4 tmpy = ray.dP.dy + (ray.dD.dy * isect.t);
    sd.dP.dx = tmpx - (tmp * dot(tmpx.xyz, sd.Ng.xyz));
    sd.dP.dy = tmpy - (tmp * dot(tmpy.xyz, sd.Ng.xyz));
    sd.dI.dx = -ray.dD.dx;
    sd.dI.dy = -ray.dD.dy;
    differential3 dP = sd.dP;
    float xn = abs(sd.Ng.x);
    float yn = abs(sd.Ng.y);
    float zn = abs(sd.Ng.z);
    if ((zn < xn) || (zn < yn))
    {
        if ((yn < xn) || (yn < zn))
        {
            sd.dPdu.x = sd.dPdu.y;
            sd.dPdv.x = sd.dPdv.y;
            dP.dx.x = dP.dx.y;
            dP.dy.x = dP.dy.y;
        }
        sd.dPdu.y = sd.dPdu.z;
        sd.dPdv.y = sd.dPdv.z;
        dP.dx.y = dP.dx.z;
        dP.dy.y = dP.dy.z;
    }
    float det = (sd.dPdu.x * sd.dPdv.y) - (sd.dPdv.x * sd.dPdu.y);
    if (!(det == 0.0))
    {
        det = 1.0 / det;
    }
    sd.du.dx = ((dP.dx.x * sd.dPdv.y) - (dP.dx.y * sd.dPdv.x)) * det;
    sd.dv.dx = ((dP.dx.y * sd.dPdu.x) - (dP.dx.x * sd.dPdu.y)) * det;
    sd.du.dy = ((dP.dy.x * sd.dPdv.y) - (dP.dy.y * sd.dPdv.x)) * det;
    sd.dv.dy = ((dP.dy.y * sd.dPdu.x) - (dP.dy.x * sd.dPdu.y)) * det;
}

void shader_prepare_closures()
{
    bool _7088 = (arg.state.bounce + arg.state.transparent_bounce) == 0;
    bool _7094;
    if (_7088)
    {
        _7094 = sd.num_closure > 1;
    }
    else
    {
        _7094 = _7088;
    }
    if (_7094)
    {
        int it_begin = sd.alloc_offset;
        float sum = 0.0;
        for (int i = 0; i < sd.num_closure; i++)
        {
            if (push.pool_ptr.pool_sc.data[sd.alloc_offset].type <= 39u)
            {
                sum += push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight;
            }
            sd.alloc_offset--;
        }
        sd.alloc_offset = it_begin;
        for (int i_1 = 0; i_1 < sd.num_closure; i_1++)
        {
            if (push.pool_ptr.pool_sc.data[sd.alloc_offset].type <= 39u)
            {
                push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight = max(push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight, 0.125 * sum);
            }
            sd.alloc_offset--;
        }
        sd.alloc_offset = it_begin;
    }
    int _7192 = atomicAdd(_6660.counter[35], 1);
    int it_begin_1 = sd.alloc_offset;
    float sum_1 = 0.0;
    for (int i_2 = 0; i_2 < sd.num_closure; i_2++)
    {
        if (push.pool_ptr.pool_sc.data[sd.alloc_offset].type <= 39u)
        {
            sum_1 += push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight;
        }
        sd.alloc_offset--;
    }
    sd.alloc_offset = it_begin_1;
    vec4 f = vec4(sum_1, float(arg.state.bounce), float(sd.num_closure), 0.0);
    if (G_dump)
    {
        _685.kg.f3[4 + ((rec_num - 1) * 64)] = f;
    }
}

void path_radiance_accum_shadowcatcher(vec4 background)
{
    L.shadow_throughput += average(throughput);
    L.shadow_background_color += (throughput * background);
    L.has_shadow_catcher = 1;
}

vec4 shader_bsdf_transparency()
{
    if ((uint(sd.flag) & 524288u) != 0u)
    {
        return vec4(1.0, 1.0, 1.0, 0.0);
    }
    else
    {
        if ((uint(sd.flag) & 512u) != 0u)
        {
            return sd.closure_transparent_extinction;
        }
        else
        {
            return vec4(0.0);
        }
    }
}

void kernel_write_data_passes()
{
    int path_flag = arg.state.flag;
    if (!((uint(path_flag) & 1u) != 0u))
    {
        return;
    }
    int flag = _1929.kernel_data.film.pass_flag;
    int light_flag = _1929.kernel_data.film.light_pass_flag;
    if (!(((flag | light_flag) & (-1)) != int(0u)))
    {
        return;
    }
    if (!((uint(path_flag) & 65536u) != 0u))
    {
        arg.state.flag |= 65536;
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

float fast_acosf(float x)
{
    float f = abs(x);
    float _959;
    if (f < 1.0)
    {
        _959 = 1.0 - (1.0 - f);
    }
    else
    {
        _959 = 1.0;
    }
    float m = _959;
    float a = sqrt(1.0 - m) * (1.57079637050628662109375 + (m * ((-0.21330098807811737060546875) + (m * (0.077980481088161468505859375 + (m * (-0.02164095081388950347900390625)))))));
    float _987;
    if (x < 0.0)
    {
        _987 = 3.1415927410125732421875 - a;
    }
    else
    {
        _987 = a;
    }
    return _987;
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
    float pdf = _1929.kernel_data.integrator.pdf_triangles;
    float cos_pi = abs(dot(Ng.xyz, I.xyz));
    if (cos_pi == 0.0)
    {
        return 0.0;
    }
    return ((t * t) * pdf) / cos_pi;
}

float triangle_light_pdf(ShaderData sd_1, float t)
{
    int param = sd_1.object;
    int param_1 = sd_1.prim;
    float param_2 = sd_1.time;
    vec4 V[3];
    vec4 param_3[3] = V;
    bool _4728 = triangle_world_space_vertices(param, param_1, param_2, param_3);
    V = param_3;
    bool has_motion = _4728;
    vec4 e0 = V[1] - V[0];
    vec4 e1 = V[2] - V[0];
    vec4 e2 = V[2] - V[1];
    float longest_edge_squared = max(len_squared(e0), max(len_squared(e1), len_squared(e2)));
    vec4 param_4 = e0;
    vec4 param_5 = e1;
    vec4 N = _cross(param_4, param_5);
    float distance_to_plane = abs(dot(N.xyz, (sd_1.I * t).xyz)) / dot(N.xyz, N.xyz);
    if (longest_edge_squared > (distance_to_plane * distance_to_plane))
    {
        vec4 Px = sd_1.P + (sd_1.I * t);
        vec4 v0_p = V[0] - Px;
        vec4 v1_p = V[1] - Px;
        vec4 v2_p = V[2] - Px;
        vec4 param_6 = v0_p;
        vec4 param_7 = v1_p;
        vec4 u01 = safe_normalize(_cross(param_6, param_7));
        vec4 param_8 = v0_p;
        vec4 param_9 = v2_p;
        vec4 u02 = safe_normalize(_cross(param_8, param_9));
        vec4 param_10 = v1_p;
        vec4 param_11 = v2_p;
        vec4 u12 = safe_normalize(_cross(param_10, param_11));
        float param_12 = dot(u02.xyz, u01.xyz);
        float alpha = fast_acosf(param_12);
        float param_13 = -dot(u01.xyz, u12.xyz);
        float beta = fast_acosf(param_13);
        float param_14 = dot(u02.xyz, u12.xyz);
        float gamma = fast_acosf(param_14);
        float solid_angle = ((alpha + beta) + gamma) - 3.1415927410125732421875;
        if (solid_angle == 0.0)
        {
            return 0.0;
        }
        else
        {
            float area = 1.0;
            if (has_motion)
            {
                int param_15 = sd_1.object;
                int param_16 = sd_1.prim;
                float param_17 = -1.0;
                vec4 param_18[3] = V;
                bool _4881 = triangle_world_space_vertices(param_15, param_16, param_17, param_18);
                V = param_18;
                area = triangle_area(V[0], V[1], V[2]);
            }
            else
            {
                area = 0.5 * length(N.xyz);
            }
            float pdf = area * _1929.kernel_data.integrator.pdf_triangles;
            return pdf / solid_angle;
        }
    }
    else
    {
        float param_19 = t;
        float pdf_1 = triangle_light_pdf_area(sd_1.Ng, sd_1.I, param_19);
        if (has_motion)
        {
            float area_1 = 0.5 * length(N.xyz);
            if (area_1 == 0.0)
            {
                return 0.0;
            }
            int param_20 = sd_1.object;
            int param_21 = sd_1.prim;
            float param_22 = -1.0;
            vec4 param_23[3] = V;
            bool _4935 = triangle_world_space_vertices(param_20, param_21, param_22, param_23);
            V = param_23;
            float area_pre = triangle_area(V[0], V[1], V[2]);
            pdf_1 = (pdf_1 * area_pre) / area_1;
        }
        return pdf_1;
    }
}

vec4 indirect_primitive_emission(float t, int path_flag, float bsdf_pdf)
{
    vec4 L_1 = shader_emissive_eval();
    bool _7643 = !((uint(path_flag) & 16384u) != 0u);
    bool _7652;
    if (_7643)
    {
        _7652 = (uint(sd.flag) & 65536u) != 0u;
    }
    else
    {
        _7652 = _7643;
    }
    if (_7652)
    {
        ShaderData param = sd;
        float param_1 = t;
        float _7660 = triangle_light_pdf(param, param_1);
        sd = param;
        float pdf = _7660;
        float param_2 = bsdf_pdf;
        float param_3 = pdf;
        float mis_weight = power_heuristic(param_2, param_3);
        return L_1 * mis_weight;
    }
    return L_1;
}

void path_radiance_accum_emission(int state_flag, int state_bounce, vec4 throughput_1, vec4 value)
{
    if ((uint(state_flag) & 131072u) != 0u)
    {
        return;
    }
    vec4 contribution = throughput_1 * value;
    float _5712;
    if ((state_bounce - 1) > 0)
    {
        _5712 = _1929.kernel_data.integrator.sample_clamp_indirect;
    }
    else
    {
        _5712 = _1929.kernel_data.integrator.sample_clamp_direct;
    }
    float limit = _5712;
    float sum = reduce_add(abs(contribution));
    if (sum > limit)
    {
        contribution *= (limit / sum);
    }
    if (L.use_light_pass != int(0u))
    {
        if (state_bounce == 0)
        {
            L.emission += contribution;
        }
        else
        {
            if (state_bounce == 1)
            {
                L.direct_emission += contribution;
            }
            else
            {
                L.indirect += contribution;
            }
        }
    }
    else
    {
        L.emission += contribution;
    }
}

bool kernel_path_shader_apply(Ray ray)
{
    uint flag = uint(arg.state.flag);
    if (G_dump)
    {
        _685.kg.u1[0 + ((rec_num - 1) * 64)] = flag;
    }
    if ((uint(sd.object_flag) & 128u) != 0u)
    {
        if ((uint(arg.state.flag) & 524288u) != 0u)
        {
            arg.state.flag |= 393216;
            vec4 bg = vec4(0.0);
            if (!(_1929.kernel_data.background.transparent != int(0u)))
            {
                int _10198 = atomicAdd(_6660.counter[36], 1);
                Ray param = ray;
                vec4 _10201 = indirect_background(param);
                bg = _10201;
                if (G_dump)
                {
                    _685.kg.f3[5 + ((rec_num - 1) * 64)] = bg;
                }
            }
            vec4 param_1 = bg;
            path_radiance_accum_shadowcatcher(param_1);
        }
    }
    else
    {
        if ((uint(arg.state.flag) & 131072u) != 0u)
        {
            int _10224 = atomicAdd(_6660.counter[37], 1);
            L.shadow_transparency *= average(shader_bsdf_transparency());
        }
    }
    kernel_write_data_passes();
    if (!(_1929.kernel_data.integrator.filter_glossy == 3.4028234663852885981170418348452e+38))
    {
        float blur_pdf = _1929.kernel_data.integrator.filter_glossy * arg.state.min_ray_pdf;
        if (blur_pdf < 1.0)
        {
            float ply_tmp = sd.randb_closure;
            int ply_tmp2 = sd.num_closure_left;
            sd.num_closure_left = -1;
            int _10256 = atomicAdd(_6660.counter[38], 1);
            sd.num_closure_left = -rec_num;
            sd.randb_closure = blur_pdf;
            executeCallableNV(2u, 1);
            sd.randb_closure = ply_tmp;
            sd.num_closure_left = ply_tmp2;
        }
    }
    if ((uint(sd.flag) & 2u) != 0u)
    {
        int _10275 = atomicAdd(_6660.counter[39], 1);
        float param_2 = sd.ray_length;
        int param_3 = arg.state.flag;
        float param_4 = arg.state.ray_pdf;
        vec4 _10286 = indirect_primitive_emission(param_2, param_3, param_4);
        vec4 emission = _10286;
        int param_5 = arg.state.flag;
        int param_6 = arg.state.bounce;
        vec4 param_7 = throughput;
        vec4 param_8 = emission;
        path_radiance_accum_emission(param_5, param_6, param_7, param_8);
        if (G_dump)
        {
            _685.kg.f3[6 + ((rec_num - 1) * 64)] = L.emission;
        }
        if (G_use_light_pass)
        {
            if (G_dump)
            {
                _685.kg.f3[7 + ((rec_num - 1) * 64)] = L.direct_emission;
            }
            if (G_dump)
            {
                _685.kg.f3[8 + ((rec_num - 1) * 64)] = L.indirect;
            }
        }
    }
    return true;
}

float max3(vec4 a)
{
    return max(max(a.x, a.y), a.z);
}

float path_state_continuation_probability()
{
    if ((uint(arg.state.flag) & 1048576u) != 0u)
    {
        return 0.0;
    }
    else
    {
        if ((uint(arg.state.flag) & 64u) != 0u)
        {
            if (arg.state.transparent_bounce <= _1929.kernel_data.integrator.transparent_min_bounce)
            {
                return 1.0;
            }
            else
            {
                bool _5343 = (uint(arg.state.flag) & 131072u) != 0u;
                bool _5349;
                if (_5343)
                {
                    _5349 = arg.state.transparent_bounce <= 8;
                }
                else
                {
                    _5349 = _5343;
                }
                if (_5349)
                {
                    return 1.0;
                }
            }
        }
        else
        {
            if (arg.state.bounce <= _1929.kernel_data.integrator.min_bounce)
            {
                return 1.0;
            }
            else
            {
                bool _5367 = (uint(arg.state.flag) & 131072u) != 0u;
                bool _5373;
                if (_5367)
                {
                    _5373 = arg.state.bounce <= 3;
                }
                else
                {
                    _5373 = _5367;
                }
                if (_5373)
                {
                    return 1.0;
                }
            }
        }
    }
    vec4 param = abs(throughput);
    return min(sqrt(max3(param) * arg.state.branch_factor), 1.0);
}

void path_state_rng_2D(PathState STATE, int dimension, out float fx, out float fy)
{
    arg2.v[0] = uintBitsToFloat(STATE.rng_hash);
    arg2.v[1] = intBitsToFloat(STATE.sample_rsv);
    arg2.v[2] = intBitsToFloat(STATE.num_samples);
    arg2.v[3] = intBitsToFloat(STATE.rng_offset + dimension);
    arg2.v[4] = uintBitsToFloat(1u);
    arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
    executeCallableNV(11u, 2);
    fx = arg2.v[0];
    fy = arg2.v[1];
}

int shader_bssrdf_pick(inout vec4 throughput_1, inout float randu)
{
    int sampled = sd.atomic_offset;
    if (sd.num_closure > 1)
    {
        float sum_bsdf = 0.0;
        float sum_bssrdf = 0.0;
        int next = sampled;
        for (int i = 0; i < sd.num_closure; i++)
        {
            if (push.pool_ptr.pool_sc.data[next].type <= 33u)
            {
                sum_bsdf += push.pool_ptr.pool_sc.data[next].sample_weight;
            }
            else
            {
                bool _9752 = push.pool_ptr.pool_sc.data[next].type >= 34u;
                bool _9763;
                if (_9752)
                {
                    _9763 = push.pool_ptr.pool_sc.data[next].type <= 39u;
                }
                else
                {
                    _9763 = _9752;
                }
                if (_9763)
                {
                    sum_bssrdf += push.pool_ptr.pool_sc.data[next].sample_weight;
                }
            }
            next++;
        }
        float r = randu * (sum_bsdf + sum_bssrdf);
        float partial_sum = 0.0;
        sampled = sd.atomic_offset;
        for (int i_1 = 0; i_1 < sd.num_closure; i_1++)
        {
            if (push.pool_ptr.pool_sc.data[sampled + i_1].type <= 39u)
            {
                float next_sum = partial_sum + push.pool_ptr.pool_sc.data[sampled + i_1].sample_weight;
                if (r < next_sum)
                {
                    if (push.pool_ptr.pool_sc.data[sampled + i_1].type <= 33u)
                    {
                        throughput_1 *= ((sum_bsdf + sum_bssrdf) / sum_bsdf);
                        return -1;
                    }
                    else
                    {
                        throughput_1 *= ((sum_bsdf + sum_bssrdf) / sum_bssrdf);
                        sampled += i_1;
                        randu = (r - partial_sum) / push.pool_ptr.pool_sc.data[sampled].sample_weight;
                        break;
                    }
                }
                partial_sum = next_sum;
            }
        }
    }
    bool _9880 = push.pool_ptr.pool_sc.data[sampled].type >= 34u;
    bool _9891;
    if (_9880)
    {
        _9891 = push.pool_ptr.pool_sc.data[sampled].type <= 39u;
    }
    else
    {
        _9891 = _9880;
    }
    return _9891 ? sampled : (-1);
}

uint lcg_state_init_addrspace(PathState state, uint scramble)
{
    uint param = (state.rng_hash + uint(state.rng_offset)) + (uint(state.sample_rsv) * scramble);
    return lcg_init(param);
}

int subsurface_scatter_multi_intersect(int scN, uint lcg_state, float bssrdf_u, float bssrdf_v, bool _all)
{
    isect.t = intBitsToFloat(sd.atomic_offset);
    isect.v = uintBitsToFloat(lcg_state);
    isect.u = intBitsToFloat(-1);
    isect.prim = rec_num;
    int idx = sd.atomic_offset;
    push.pool_ptr2.pool_is.data[idx].t = sd.Ng.x;
    push.pool_ptr2.pool_is.data[idx].u = sd.Ng.y;
    push.pool_ptr2.pool_is.data[idx].v = sd.Ng.z;
    push.pool_ptr2.pool_is.data[idx].prim = floatBitsToInt(sd.time);
    push.pool_ptr2.pool_is.data[idx].object = sd.object;
    push.pool_ptr2.pool_is.data[idx].type = sd.type;
    idx++;
    push.pool_ptr2.pool_is.data[idx].t = sd.P.x;
    push.pool_ptr2.pool_is.data[idx].u = sd.P.y;
    push.pool_ptr2.pool_is.data[idx].v = sd.P.z;
    push.pool_ptr2.pool_is.data[idx].prim = floatBitsToInt(bssrdf_u);
    push.pool_ptr2.pool_is.data[idx].object = floatBitsToInt(bssrdf_v);
    push.pool_ptr2.pool_is.data[idx].type = scN;
    idx++;
    push.pool_ptr2.pool_is.data[idx].t = sd.dP.dx.x;
    push.pool_ptr2.pool_is.data[idx].u = sd.dP.dx.y;
    push.pool_ptr2.pool_is.data[idx].v = sd.dP.dx.z;
    push.pool_ptr2.pool_is.data[idx].type = sd.num_closure;
    idx++;
    push.pool_ptr2.pool_is.data[idx].t = sd.dP.dy.x;
    push.pool_ptr2.pool_is.data[idx].u = sd.dP.dy.y;
    push.pool_ptr2.pool_is.data[idx].v = sd.dP.dy.z;
    traceNV(topLevelAS, 8u, 255u, 2u, 0u, 2u, vec3(0.0), 0.0, vec3(0.0), 0.0, 0);
    int nums = push.pool_ptr2.pool_is.data[sd.atomic_offset + 4].prim;
    return nums;
}

void shader_setup_from_subsurface(vec4 rayP, vec4 rayD, Intersection lisect)
{
    sd.geometry = lisect.type;
    sd.type = int(push.data_ptr._prim_type.data[lisect.prim]);
    bool backfacing = (uint(sd.flag) & 1u) != 0u;
    sd.flag = 0;
    sd.object_flag = int(push.data_ptr._object_flag.data[sd.object]);
    sd.u = lisect.u;
    sd.v = lisect.v;
    sd.prim = lisect.prim;
    if (uint(sd.type) == 1u)
    {
        vec4 Ng = triangle_normal();
        sd.shader = int(push.data_ptr._tri_shader.data[sd.prim]);
        vec4 param = rayP;
        vec4 param_1 = rayD;
        float param_2 = lisect.t;
        int param_3 = lisect.object;
        int param_4 = lisect.prim;
        int param_5 = lisect.type;
        vec4 _8352 = triangle_refine(param, param_1, param_2, param_3, param_4, param_5);
        sd.P = _8352;
        if (G_dump)
        {
            _685.kg.f3[30 + ((rec_num - 1) * 64)] = sd.P;
        }
        sd.Ng = Ng;
        sd.N = Ng;
        if ((uint(sd.shader) & 2147483648u) != 0u)
        {
            vec4 param_6 = Ng;
            int param_7 = sd.prim;
            float param_8 = sd.u;
            float param_9 = sd.v;
            sd.N = triangle_smooth_normal(param_6, param_7, param_8, param_9);
        }
        uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * sd.prim], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 1], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
        vec4 p0 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.x]);
        vec4 p1 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.y]);
        vec4 p2 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.z]);
        sd.dPdu = p0 - p2;
        sd.dPdv = p1 - p2;
    }
    sd.flag |= push.data_ptr._shaders.data[uint(sd.shader) & 8388607u].flags;
    if (!((lisect.object & 8388608) != int(0u)))
    {
        vec4 param_10 = sd.N;
        object_normal_transform(param_10);
        sd.N = param_10;
        vec4 param_11 = sd.Ng;
        object_normal_transform(param_11);
        sd.Ng = param_11;
        vec4 param_12 = sd.dPdu;
        object_dir_transform(param_12);
        sd.dPdu = param_12;
        vec4 param_13 = sd.dPdv;
        object_dir_transform(param_13);
        sd.dPdv = param_13;
    }
    if (backfacing)
    {
        sd.flag |= 1;
        sd.Ng = -sd.Ng;
        sd.N = -sd.N;
        sd.dPdu = -sd.dPdu;
        sd.dPdv = -sd.dPdv;
    }
    sd.I = sd.N;
    float xn = abs(sd.Ng.x);
    float yn = abs(sd.Ng.y);
    float zn = abs(sd.Ng.z);
    if ((zn < xn) || (zn < yn))
    {
        if ((yn < xn) || (yn < zn))
        {
            sd.dPdu.x = sd.dPdu.y;
            sd.dPdv.x = sd.dPdv.y;
            sd.dP.dx.x = sd.dP.dx.y;
            sd.dP.dy.x = sd.dP.dy.y;
        }
        sd.dPdu.y = sd.dPdu.z;
        sd.dPdv.y = sd.dPdv.z;
        sd.dP.dx.y = sd.dP.dx.z;
        sd.dP.dy.y = sd.dP.dy.z;
    }
    float det = (sd.dPdu.x * sd.dPdv.y) - (sd.dPdv.x * sd.dPdu.y);
    if (!(det == 0.0))
    {
        det = 1.0 / det;
    }
    sd.du.dx = ((sd.dP.dx.x * sd.dPdv.y) - (sd.dP.dx.y * sd.dPdv.x)) * det;
    sd.dv.dx = ((sd.dP.dx.y * sd.dPdu.x) - (sd.dP.dx.x * sd.dPdu.y)) * det;
    sd.du.dy = ((sd.dP.dy.x * sd.dPdv.y) - (sd.dP.dy.y * sd.dPdv.x)) * det;
    sd.dv.dy = ((sd.dP.dy.y * sd.dPdu.x) - (sd.dP.dy.x * sd.dPdu.y)) * det;
    if (G_dump)
    {
        _685.kg.f3[31 + ((rec_num - 1) * 64)] = sd.I;
    }
}

float safe_divide(float a, float b)
{
    float _943;
    if (!(b == 0.0))
    {
        _943 = a / b;
    }
    else
    {
        _943 = 0.0;
    }
    return _943;
}

vec4 shader_bssrdf_sum(inout vec4 N_, inout float texture_blur_)
{
    vec4 eval = vec4(0.0);
    vec4 N = vec4(0.0);
    float texture_blur = 0.0;
    float weight_sum = 0.0;
    int it_begin = sd.alloc_offset;
    for (int i = 0; i < sd.num_closure; i++)
    {
        bool _8802 = push.pool_ptr.pool_sc.data[sd.alloc_offset].type >= 34u;
        bool _8814;
        if (_8802)
        {
            _8814 = push.pool_ptr.pool_sc.data[sd.alloc_offset].type <= 39u;
        }
        else
        {
            _8814 = _8802;
        }
        if (_8814)
        {
            float avg_weight = abs(average(push.pool_ptr.pool_sc.data[sd.alloc_offset].weight));
            N += (push.pool_ptr.pool_sc.data[sd.alloc_offset].N * avg_weight);
            eval += push.pool_ptr.pool_sc.data[sd.alloc_offset].weight;
            texture_blur += (push.pool_ptr.pool_sc.data[sd.alloc_offset].data[7] * avg_weight);
            weight_sum += avg_weight;
        }
        sd.alloc_offset--;
    }
    sd.alloc_offset = it_begin;
    if (!(N_.x == 3.4028234663852885981170418348452e+38))
    {
        vec4 _8881;
        if (is_zero(N))
        {
            _8881 = sd.N;
        }
        else
        {
            _8881 = normalize(N);
        }
        N_ = _8881;
    }
    if (!(texture_blur_ == 3.4028234663852885981170418348452e+38))
    {
        float param = texture_blur;
        float param_1 = weight_sum;
        texture_blur_ = safe_divide(param, param_1);
    }
    return eval;
}

vec4 safe_divide_color(vec4 a, vec4 b)
{
    float _886;
    if (!(b.x == 0.0))
    {
        _886 = a.x / b.x;
    }
    else
    {
        _886 = 0.0;
    }
    float x = _886;
    float _900;
    if (!(b.y == 0.0))
    {
        _900 = a.y / b.y;
    }
    else
    {
        _900 = 0.0;
    }
    float y = _900;
    float _914;
    if (!(b.z == 0.0))
    {
        _914 = a.z / b.z;
    }
    else
    {
        _914 = 0.0;
    }
    float z = _914;
    return vec4(x, y, z, 0.0);
}

void subsurface_color_bump_blur(inout vec4 eval, vec4 N)
{
    vec4 param = null_flt3;
    float texture_blur;
    float param_1 = texture_blur;
    vec4 _8909 = shader_bssrdf_sum(param, param_1);
    null_flt3 = param;
    texture_blur = param_1;
    vec4 out_color = _8909;
    bool bump = (uint(sd.flag) & 2097152u) != 0u;
    if (bump || (texture_blur > 0.0))
    {
        uint param_2 = uint(arg.state.flag);
        shader_eval_surface(param_2);
        vec4 _N = bump ? N : null_flt3;
        vec4 param_3 = _N;
        float param_4 = null_flt;
        vec4 _8940 = shader_bssrdf_sum(param_3, param_4);
        _N = param_3;
        null_flt = param_4;
        vec4 in_color = _8940;
        if (texture_blur > 0.0)
        {
            out_color = max(out_color, vec4(0.0));
            if (texture_blur == 1.0)
            {
            }
            else
            {
                if (texture_blur == 0.5)
                {
                    out_color.x = sqrt(out_color.x);
                    out_color.y = sqrt(out_color.y);
                    out_color.z = sqrt(out_color.z);
                }
                else
                {
                    out_color.x = pow(out_color.x, texture_blur);
                    out_color.y = pow(out_color.y, texture_blur);
                    out_color.z = pow(out_color.z, texture_blur);
                }
            }
            in_color = max(in_color, vec4(0.0));
            if (texture_blur == 1.0)
            {
            }
            else
            {
                if (texture_blur == 0.5)
                {
                    in_color.x = sqrt(in_color.x);
                    in_color.y = sqrt(in_color.y);
                    in_color.z = sqrt(in_color.z);
                }
                else
                {
                    in_color.x = pow(in_color.x, texture_blur);
                    in_color.y = pow(in_color.y, texture_blur);
                    in_color.z = pow(in_color.z, texture_blur);
                }
            }
            vec4 param_5 = in_color;
            vec4 param_6 = out_color;
            eval *= safe_divide_color(param_5, param_6);
        }
    }
}

int closure_alloc(uint type, vec4 weight)
{
    if (sd.num_closure_left == 0)
    {
        return -1;
    }
    if (sd.num_closure < 63)
    {
        sd.alloc_offset++;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].sample_weight = 0.0;
        push.pool_ptr.pool_sc.data[sd.alloc_offset].N = vec4(0.0);
        for (int _i_ = 0; _i_ < 25; _i_++)
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[_i_] = 0.0;
        }
    }
    push.pool_ptr.pool_sc.data[sd.alloc_offset].type = type;
    push.pool_ptr.pool_sc.data[sd.alloc_offset].weight = weight;
    sd.num_closure++;
    sd.num_closure_left--;
    return sd.alloc_offset;
}

int bsdf_alloc(uint size, vec4 weight)
{
    uint param = 0u;
    vec4 param_1 = weight;
    int _8753 = closure_alloc(param, param_1);
    int n = _8753;
    if (n < 0)
    {
        return -1;
    }
    float sample_weight = abs(average(weight));
    push.pool_ptr.pool_sc.data[n].sample_weight = sample_weight;
    return (sample_weight >= 9.9999997473787516355514526367188e-06) ? n : (-1);
}

void subsurface_scatter_setup_diffuse_bsdf(uint type, float roughness, vec4 weight, vec4 N)
{
    sd.flag = int(uint(sd.flag) & 4294966017u);
    sd.num_closure = 0;
    sd.num_closure_left = _1929.kernel_data.integrator.max_closures;
    sd.alloc_offset = sd.atomic_offset - 1;
    if ((type == 36u) || (type == 39u))
    {
        uint param = 0u;
        vec4 param_1 = weight;
        int _9059 = bsdf_alloc(param, param_1);
        int n = _9059;
        if (n >= 0)
        {
            push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].data[0] = roughness;
            push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 32u;
            sd.flag |= 12;
        }
    }
    else
    {
        bool _9097 = (type == 31u) || (type == 32u);
        bool _9106;
        if (!_9097)
        {
            _9106 = (type >= 34u) && (type <= 39u);
        }
        else
        {
            _9106 = _9097;
        }
        if (_9106)
        {
            uint param_2 = 0u;
            vec4 param_3 = weight;
            int _9113 = bsdf_alloc(param_2, param_3);
            int n_1 = _9113;
            if (n_1 >= 0)
            {
                push.pool_ptr.pool_sc.data[sd.alloc_offset].N = N;
                push.pool_ptr.pool_sc.data[sd.alloc_offset].type = 31u;
                sd.flag |= 12;
            }
        }
    }
}

int ceil_to_int(float f)
{
    return int(ceil(f));
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

bool scene_intersect_shadow_all(uint visibility, uint max_hits)
{
    isect.t = uintBitsToFloat(uint(sd.atomic_offset));
    isect.u = uintBitsToFloat(0u);
    isect.v = uintBitsToFloat(max_hits);
    isect.prim = int(visibility);
    isect.object = 0;
    traceNV(topLevelAS, 8u, 255u, 1u, 0u, 1u, arg.ray.P.xyz, 0.0, arg.ray.D.xyz, arg.ray.t, 0);
    if (!(uint(isect.object) == 0u))
    {
        int _7373 = atomicAdd(_6660.counter[41], 1);
    }
    if (G_dump)
    {
        _685.kg.f3[18 + ((rec_num - 1) * 64)] = arg.ray.P;
    }
    if (G_dump)
    {
        _685.kg.u1[5 + ((rec_num - 1) * 64)] = floatBitsToUint(isect.u);
    }
    return isect.object != int(0u);
}

void sort_intersections(inout uint num_hits)
{
    int offset = int(floatBitsToUint(isect.t));
    bool swapped;
    do
    {
        swapped = false;
        for (int j = 0; uint(j) < (num_hits - 1u); j++)
        {
            int i = offset + j;
            if (push.pool_ptr2.pool_is.data[i].t > push.pool_ptr2.pool_is.data[i + 1].t)
            {
                Intersection _7308;
                _7308.t = push.pool_ptr2.pool_is.data[i].t;
                _7308.u = push.pool_ptr2.pool_is.data[i].u;
                _7308.v = push.pool_ptr2.pool_is.data[i].v;
                _7308.prim = push.pool_ptr2.pool_is.data[i].prim;
                _7308.object = push.pool_ptr2.pool_is.data[i].object;
                _7308.type = push.pool_ptr2.pool_is.data[i].type;
                Intersection tmp = _7308;
                push.pool_ptr2.pool_is.data[i] = push.pool_ptr2.pool_is.data[i + 1];
                Intersection _7331;
                _7331.t = tmp.t;
                _7331.u = tmp.u;
                _7331.v = tmp.v;
                _7331.prim = tmp.prim;
                _7331.object = tmp.object;
                _7331.type = tmp.type;
                push.pool_ptr2.pool_is.data[i + 1] = _7331;
                swapped = true;
            }
        }
        num_hits--;
    } while (swapped);
}

bool shadow_handle_transparent_isect(int is, inout vec4 throughput_1)
{
    ShaderData cacheSD = sd;
    Intersection _7409;
    _7409.t = push.pool_ptr2.pool_is.data[is].t;
    _7409.u = push.pool_ptr2.pool_is.data[is].u;
    _7409.v = push.pool_ptr2.pool_is.data[is].v;
    _7409.prim = push.pool_ptr2.pool_is.data[is].prim;
    _7409.object = push.pool_ptr2.pool_is.data[is].object;
    _7409.type = push.pool_ptr2.pool_is.data[is].type;
    isect = _7409;
    sd.geometry = isect.type;
    sd.type = int(push.data_ptr._prim_type.data[isect.prim]);
    isect.type = sd.type;
    Ray param = arg.ray;
    shader_setup_from_ray(param);
    if (!((uint(sd.flag) & 524288u) != 0u))
    {
        if (true)
        {
            arg.state.bounce++;
        }
        else
        {
            arg.state.bounce--;
        }
        uint param_1 = 1920u;
        shader_eval_surface(param_1);
        if (false)
        {
            arg.state.bounce++;
        }
        else
        {
            arg.state.bounce--;
        }
        throughput_1 *= shader_bsdf_transparency();
    }
    if (is_zero(throughput_1))
    {
        sd = cacheSD;
        return true;
    }
    sd = cacheSD;
    return false;
}

bool shadow_blocked_transparent_all_loop(uint visibility, uint max_hits, inout vec4 shadow)
{
    uint param = visibility;
    uint param_1 = max_hits;
    bool _7482 = scene_intersect_shadow_all(param, param_1);
    bool blocked = _7482;
    uint num_hits = floatBitsToUint(isect.u);
    if ((!blocked) && (num_hits > 0u))
    {
        vec4 throughput_1 = vec4(1.0, 1.0, 1.0, 0.0);
        vec4 Pend = arg.ray.P + (arg.ray.D * arg.ray.t);
        float last_t = 0.0;
        int bounce = arg.state.transparent_bounce;
        int _7512 = int(floatBitsToUint(isect.t));
        uint param_2 = num_hits;
        sort_intersections(param_2);
        for (int is = _7512, hit = 0; uint(hit) < num_hits; hit++, is++)
        {
            float new_t = push.pool_ptr2.pool_is.data[is].t;
            push.pool_ptr2.pool_is.data[is].t -= last_t;
            if (last_t == new_t)
            {
                continue;
            }
            last_t = new_t;
            int param_3 = is;
            vec4 param_4 = throughput_1;
            bool _7555 = shadow_handle_transparent_isect(param_3, param_4);
            throughput_1 = param_4;
            if (_7555)
            {
                return true;
            }
            arg.ray.P = sd.P;
            if (!(arg.ray.t == 3.4028234663852885981170418348452e+38))
            {
                float param_5 = arg.ray.t;
                vec4 _7575 = normalize_len(Pend - arg.ray.P, param_5);
                arg.ray.t = param_5;
                arg.ray.D = _7575;
            }
            bounce++;
        }
        shadow = throughput_1;
        return is_zero(throughput_1);
    }
    return blocked;
}

bool shadow_blocked(inout vec4 shadow)
{
    shadow = vec4(1.0, 1.0, 1.0, 0.0);
    if (arg.ray.t == 0.0)
    {
        return false;
    }
    uint visibility = ((uint(arg.state.flag) & 131072u) != 0u) ? 640u : 1920u;
    int transparent_max_bounce = _1929.kernel_data.integrator.transparent_max_bounce;
    if (arg.state.transparent_bounce >= transparent_max_bounce)
    {
        return true;
    }
    uint max_hits = uint((transparent_max_bounce - arg.state.transparent_bounce) - 1);
    max_hits = min(max_hits, 63u);
    uint param = visibility;
    uint param_1 = max_hits;
    vec4 param_2 = shadow;
    bool _7632 = shadow_blocked_transparent_all_loop(param, param_1, param_2);
    shadow = param_2;
    return _7632;
}

vec4 PLYMO_bsdf_eval_sum()
{
    if (floatBitsToInt(arg.ray.dP.dx.y) != 0)
    {
        return (arg.L.emission + arg.L.direct_emission) + arg.L.indirect;
    }
    else
    {
        return arg.L.emission;
    }
}

void path_radiance_accum_light(vec4 shadow, float shadow_fac, bool is_lamp)
{
    if ((uint(arg.state.flag) & 262144u) != 0u)
    {
        vec4 light = throughput * arg.L.throughput;
        L.path_total += light;
        L.path_total_shaded += (shadow * light);
        if ((uint(arg.state.flag) & 131072u) != 0u)
        {
            return;
        }
    }
    vec4 shaded_throughput = throughput * shadow;
    if (L.use_light_pass != 0)
    {
        vec4 full_contribution = shaded_throughput * PLYMO_bsdf_eval_sum();
        float _6027;
        if (arg.state.bounce > 0)
        {
            _6027 = _1929.kernel_data.integrator.sample_clamp_indirect;
        }
        else
        {
            _6027 = _1929.kernel_data.integrator.sample_clamp_direct;
        }
        float limit = _6027;
        float sum = reduce_add(abs(full_contribution));
        if (sum > limit)
        {
            float clamp_factor = limit / sum;
            full_contribution *= clamp_factor;
            shaded_throughput *= clamp_factor;
        }
        if (arg.state.bounce == 0)
        {
            L.direct_diffuse += (shaded_throughput * arg.L.emission);
            L.direct_glossy += (shaded_throughput * arg.L.direct_emission);
            L.direct_transmission += (shaded_throughput * arg.L.indirect);
            if (is_lamp)
            {
                L.shadow.x += (shadow.x * shadow_fac);
                L.shadow.y += (shadow.y * shadow_fac);
                L.shadow.z += (shadow.z * shadow_fac);
            }
        }
        else
        {
            L.indirect += full_contribution;
        }
    }
    else
    {
        vec4 contribution = shaded_throughput * arg.L.emission;
        float _6127;
        if (arg.state.bounce > 0)
        {
            _6127 = _1929.kernel_data.integrator.sample_clamp_indirect;
        }
        else
        {
            _6127 = _1929.kernel_data.integrator.sample_clamp_direct;
        }
        float limit_1 = _6127;
        float sum_1 = reduce_add(abs(contribution));
        if (sum_1 > limit_1)
        {
            contribution *= (limit_1 / sum_1);
        }
        L.emission += contribution;
    }
}

void path_radiance_accum_total_light(int state_flag, vec4 throughput_1, vec4 sum_no_mis)
{
    if ((uint(state_flag) & 262144u) != 0u)
    {
        L.path_total += (throughput_1 * sum_no_mis);
    }
}

void kernel_path_surface_connect_light(float num_samples_adjust, int sample_all_lights)
{
    arg.type = 0;
    arg.sd.type = sd.type;
    arg.sd.flag = sd.flag;
    arg.sd.time = sd.time;
    arg.sd.object = sd.object;
    arg.sd.P = sd.P;
    arg.sd.N = sd.N;
    arg.sd.I = sd.I;
    arg.sd.Ng = sd.Ng;
    arg.sd.dI = sd.dI;
    arg.sd.num_closure = sd.num_closure;
    arg.sd.atomic_offset = sd.atomic_offset;
    arg.sd.alloc_offset = sd.alloc_offset;
    arg.sd.lcg_state = sd.lcg_state;
    arg.L.direct_emission.w = float(PROFI_IDX);
    arg.L.indirect.w = float(rec_num);
    int num_lights = 0;
    if (_1929.kernel_data.integrator.use_direct_light != int(0u))
    {
        if (sample_all_lights != int(0u))
        {
            num_lights = _1929.kernel_data.integrator.num_all_lights;
            if (!(_1929.kernel_data.integrator.pdf_triangles == 0.0))
            {
                num_lights++;
            }
        }
        else
        {
            num_lights = 1;
        }
    }
    vec4 shadow;
    for (int i = 0; i < num_lights; i++)
    {
        int num_samples = 1;
        int num_all_lights = 1;
        uint lamp_rng_hash = arg.state.rng_hash;
        bool double_pdf = false;
        bool is_mesh_light = false;
        bool is_lamp = false;
        if (sample_all_lights != int(0u))
        {
            is_lamp = i < _1929.kernel_data.integrator.num_all_lights;
            if (is_lamp)
            {
                if (float(arg.state.bounce) > push.data_ptr._lights.data[i].max_bounces)
                {
                    continue;
                }
                float param = num_samples_adjust * float(push.data_ptr._lights.data[i].samples);
                num_samples = ceil_to_int(param);
                num_all_lights = _1929.kernel_data.integrator.num_all_lights;
                uint param_1 = arg.state.rng_hash;
                uint param_2 = uint(i);
                uint _8073 = cmj_hash(param_1, param_2);
                lamp_rng_hash = _8073;
                double_pdf = !(_1929.kernel_data.integrator.pdf_triangles == 0.0);
            }
            else
            {
                float param_3 = num_samples_adjust * float(_1929.kernel_data.integrator.mesh_light_samples);
                num_samples = ceil_to_int(param_3);
                double_pdf = _1929.kernel_data.integrator.num_all_lights != 0;
                is_mesh_light = true;
            }
        }
        float num_samples_inv = num_samples_adjust / float(num_samples * num_all_lights);
        for (int j = 0; j < num_samples; j++)
        {
            arg.ray.t = 0.0;
            bool has_emission = false;
            bool _8108 = _1929.kernel_data.integrator.use_direct_light != int(0u);
            bool _8116;
            if (_8108)
            {
                _8116 = (uint(arg.sd.flag) & 8u) != 0u;
            }
            else
            {
                _8116 = _8108;
            }
            if (_8116)
            {
                arg2.v[0] = uintBitsToFloat(lamp_rng_hash);
                arg2.v[1] = intBitsToFloat((arg.state.sample_rsv * num_samples) + j);
                arg2.v[2] = intBitsToFloat(arg.state.num_samples * num_samples);
                arg2.v[3] = intBitsToFloat(arg.state.rng_offset + 2);
                arg2.v[4] = uintBitsToFloat(1u);
                arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
                executeCallableNV(11u, 2);
                float light_u = arg2.v[0];
                float light_v = arg2.v[1];
                float terminate = 0.0;
                if (_1929.kernel_data.integrator.light_inv_rr_threshold > 0.0)
                {
                    arg2.v[0] = uintBitsToFloat(lamp_rng_hash);
                    arg2.v[1] = intBitsToFloat((arg.state.sample_rsv * num_samples) + j);
                    arg2.v[2] = intBitsToFloat(arg.state.num_samples * num_samples);
                    arg2.v[3] = intBitsToFloat(arg.state.rng_offset + 4);
                    arg2.v[4] = uintBitsToFloat(0u);
                    arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
                    executeCallableNV(11u, 2);
                    terminate = arg2.v[0];
                }
                bool _8195;
                if (is_mesh_light)
                {
                    _8195 = double_pdf;
                }
                else
                {
                    _8195 = is_mesh_light;
                }
                if (_8195)
                {
                    light_u = 0.5 * light_u;
                }
                arg.use_light_pass = is_lamp ? i : (-1);
                arg.L.emission = vec4(light_u, light_v, terminate, float(double_pdf));
                executeCallableNV(0u, 0);
                has_emission = arg.type != int(0u);
            }
            vec4 param_4 = shadow;
            bool _8218 = shadow_blocked(param_4);
            shadow = param_4;
            bool blocked = _8218;
            if (has_emission)
            {
                if (!blocked)
                {
                    vec4 param_5 = shadow;
                    float param_6 = num_samples_inv;
                    bool param_7 = is_lamp;
                    path_radiance_accum_light(param_5, param_6, param_7);
                }
                else
                {
                    int param_8 = arg.state.flag;
                    vec4 param_9 = throughput * num_samples_inv;
                    vec4 param_10 = arg.L.throughput;
                    path_radiance_accum_total_light(param_8, param_9, param_10);
                }
                int _8248 = atomicAdd(_6660.counter[42], 1);
                if (G_dump)
                {
                    uint _8253 = atomicAdd(_685.kg.u1[4], 1u);
                }
                if (G_dump)
                {
                    _685.kg.f3[13 + ((rec_num - 1) * 64)] = shadow;
                }
                if (G_dump)
                {
                    _685.kg.f3[14 + ((rec_num - 1) * 64)] = throughput;
                }
            }
        }
    }
    sd.lcg_state = arg.sd.lcg_state;
}

bool PLYMO_bsdf_eval_is_zero()
{
    if (floatBitsToInt(arg.ray.dP.dx.y) != 0)
    {
        bool _1785 = is_zero(arg.L.emission);
        bool _1791;
        if (_1785)
        {
            _1791 = is_zero(arg.L.direct_emission);
        }
        else
        {
            _1791 = _1785;
        }
        bool _1797;
        if (_1791)
        {
            _1797 = is_zero(arg.L.indirect);
        }
        else
        {
            _1797 = _1791;
        }
        bool _1803;
        if (_1797)
        {
            _1803 = is_zero(arg.L.path_total);
        }
        else
        {
            _1803 = _1797;
        }
        return _1803;
    }
    else
    {
        return is_zero(arg.L.emission);
    }
}

void path_radiance_bsdf_bounce_local(int idx, float bsdf_pdf, int bounce, int bsdf_label)
{
    float inverse_pdf = 1.0 / bsdf_pdf;
    if (_1929.kernel_data.film.use_light_pass != int(0u))
    {
        bool _9333 = bounce == 0;
        bool _9341;
        if (_9333)
        {
            _9341 = !((uint(bsdf_label) & 32u) != 0u);
        }
        else
        {
            _9341 = _9333;
        }
        if (_9341)
        {
            vec4 value = ss_indirect.throughputs[idx] * inverse_pdf;
            ss_indirect.L_state[idx].diffuse = arg.L.emission * value;
            ss_indirect.L_state[idx].glossy = arg.L.direct_emission * value;
            ss_indirect.L_state[idx].transmission = arg.L.indirect * value;
            ss_indirect.throughputs[idx] = (ss_indirect.L_state[idx].diffuse + ss_indirect.L_state[idx].glossy) + ss_indirect.L_state[idx].transmission;
        }
        else
        {
            vec4 sum = (PLYMO_bsdf_eval_sum() + arg.L.path_total) * inverse_pdf;
            ss_indirect.throughputs[idx] *= sum;
        }
    }
    else
    {
        ss_indirect.throughputs[idx] *= (arg.L.emission * inverse_pdf);
    }
}

void path_state_next(inout PathState STATE, int label)
{
    if ((uint(label) & 32u) != 0u)
    {
        STATE.flag |= 64;
        STATE.transparent_bounce++;
        if (STATE.transparent_bounce >= _1929.kernel_data.integrator.transparent_max_bounce)
        {
            STATE.flag |= 1048576;
        }
        if (!(_1929.kernel_data.integrator.transparent_shadows != int(0u)))
        {
            STATE.flag |= 16384;
        }
        STATE.rng_offset += 8;
        return;
    }
    STATE.bounce++;
    if (STATE.bounce >= _1929.kernel_data.integrator.max_bounce)
    {
        STATE.flag |= 2097152;
    }
    STATE.flag &= (-32768);
    if ((uint(label) & 2u) != 0u)
    {
        STATE.flag |= 2;
        STATE.flag &= (-524289);
        if ((uint(label) & 4u) != 0u)
        {
            STATE.diffuse_bounce++;
            if (STATE.diffuse_bounce >= _1929.kernel_data.integrator.max_diffuse_bounce)
            {
                STATE.flag |= 2097152;
            }
        }
        else
        {
            STATE.glossy_bounce++;
            if (STATE.glossy_bounce >= _1929.kernel_data.integrator.max_glossy_bounce)
            {
                STATE.flag |= 2097152;
            }
        }
    }
    else
    {
        if (!((uint(label) & 1u) != 0u))
        {
            // unimplemented ext op 12
        }
        STATE.flag |= 4;
        if (!((uint(label) & 128u) != 0u))
        {
            STATE.flag &= (-524289);
        }
        STATE.transmission_bounce++;
        if (STATE.transmission_bounce >= _1929.kernel_data.integrator.max_transmission_bounce)
        {
            STATE.flag |= 2097152;
        }
    }
    if ((uint(label) & 4u) != 0u)
    {
        STATE.flag |= 32776;
    }
    else
    {
        if ((uint(label) & 8u) != 0u)
        {
            STATE.flag |= 16;
        }
        else
        {
            if (!((uint(label) & 16u) != 0u))
            {
                // unimplemented ext op 12
            }
            STATE.flag |= 16432;
        }
    }
    STATE.rng_offset += 8;
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

bool kernel_path_surface_bounce_local()
{
    if (G_dump)
    {
        _685.kg.u1[2 + ((rec_num - 1) * 64)] = uint(sd.flag);
    }
    int idx = ss_indirect.num_rays;
    if ((uint(sd.flag) & 4u) != 0u)
    {
        arg2.v[0] = uintBitsToFloat(ss_indirect.state[idx].rng_hash);
        arg2.v[1] = intBitsToFloat(ss_indirect.state[idx].sample_rsv);
        arg2.v[2] = intBitsToFloat(ss_indirect.state[idx].num_samples);
        arg2.v[3] = intBitsToFloat(ss_indirect.state[idx].rng_offset + 0);
        arg2.v[4] = uintBitsToFloat(1u);
        arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
        executeCallableNV(11u, 2);
        float randu = arg2.v[0];
        float randv = arg2.v[1];
        arg.L.direct_emission.w = float(PROFI_IDX);
        arg.L.indirect.w = float(rec_num);
        arg.ray.dP.dx.z = intBitsToFloat(1);
        arg.L.emission = vec4(randu, randv, 123.0, 456.0);
        executeCallableNV(1u, 0);
        if (G_dump)
        {
            _685.kg.f1[2 + ((rec_num - 1) * 64)] = arg.ray.dP.dx.w;
        }
        if (G_dump)
        {
            _685.kg.u1[3 + ((rec_num - 1) * 64)] = uint(floatBitsToInt(arg.ray.dP.dx.y));
        }
        if (G_dump)
        {
            _685.kg.f3[22 + ((rec_num - 1) * 64)] = arg.L.emission;
        }
        if (floatBitsToInt(arg.ray.dP.dx.y) != int(0u))
        {
            if (G_dump)
            {
                _685.kg.f3[23 + ((rec_num - 1) * 64)] = arg.L.direct_emission;
            }
            if (G_dump)
            {
                _685.kg.f3[24 + ((rec_num - 1) * 64)] = arg.L.indirect;
            }
            if (G_dump)
            {
                _685.kg.f3[25 + ((rec_num - 1) * 64)] = arg.L.path_total;
            }
        }
        bool _9549 = arg.ray.dP.dx.w == 0.0;
        bool _9554;
        if (!_9549)
        {
            _9554 = PLYMO_bsdf_eval_is_zero();
        }
        else
        {
            _9554 = _9549;
        }
        if (_9554)
        {
            return false;
        }
        int label = floatBitsToInt(arg.ray.dP.dx.x);
        int param = idx;
        float param_1 = arg.ray.dP.dx.w;
        int param_2 = ss_indirect.state[idx].bounce;
        int param_3 = label;
        path_radiance_bsdf_bounce_local(param, param_1, param_2, param_3);
        if (G_dump)
        {
            _685.kg.f3[19 + ((rec_num - 1) * 64)] = ss_indirect.throughputs[idx];
        }
        if (!((uint(label) & 32u) != 0u))
        {
            ss_indirect.state[idx].ray_pdf = arg.ray.dP.dx.w;
            ss_indirect.state[idx].ray_t = 0.0;
            ss_indirect.state[idx].min_ray_pdf = min(arg.ray.dP.dx.w, ss_indirect.state[idx].min_ray_pdf);
        }
        PathState param_4 = ss_indirect.state[idx];
        int param_5 = label;
        path_state_next(param_4, param_5);
        ss_indirect.state[idx] = param_4;
        vec4 _9621;
        if ((uint(label) & 1u) != 0u)
        {
            _9621 = -sd.Ng;
        }
        else
        {
            _9621 = sd.Ng;
        }
        vec4 param_6 = sd.P;
        vec4 param_7 = _9621;
        ss_indirect.rays[idx].P = ray_offset(param_6, param_7);
        ss_indirect.rays[idx].D = vec4(normalize(vec4(intBitsToFloat(arg.use_light_pass), intBitsToFloat(arg.type), arg.ray.t, arg.ray.time).xyz), 0.0);
        if (idx == 0)
        {
            if (G_dump)
            {
                _685.kg.f3[32 + ((rec_num - 1) * 64)] = ss_indirect.rays[idx].D;
            }
        }
        if (arg.state.bounce == 0)
        {
            ss_indirect.rays[idx].t -= sd.ray_length;
        }
        else
        {
            ss_indirect.rays[idx].t = 3.4028234663852885981170418348452e+38;
        }
        ss_indirect.rays[idx].dP = sd.dP;
        ss_indirect.rays[idx].dD.dx = arg.ray.P;
        ss_indirect.rays[idx].dD.dy = arg.ray.D;
        return true;
    }
    return false;
}

bool kernel_path_subsurface_scatter(Ray ray)
{
    PathState param = arg.state;
    int param_1 = 0;
    float bssrdf_u;
    float param_2 = bssrdf_u;
    float bssrdf_v;
    float param_3 = bssrdf_v;
    path_state_rng_2D(param, param_1, param_2, param_3);
    bssrdf_u = param_2;
    bssrdf_v = param_3;
    vec4 param_4 = throughput;
    float param_5 = bssrdf_u;
    int _9914 = shader_bssrdf_pick(param_4, param_5);
    throughput = param_4;
    bssrdf_u = param_5;
    int n = _9914;
    if (n >= 0)
    {
        if (!(!((uint(arg.state.flag) & 32768u) != 0u)))
        {
            // unimplemented ext op 12
        }
        PathState param_6 = arg.state;
        uint param_7 = 1757159915u;
        arg.state = param_6;
        uint lcg_state = lcg_state_init_addrspace(param_6, param_7);
        int param_8 = n;
        uint param_9 = lcg_state;
        float param_10 = bssrdf_u;
        float param_11 = bssrdf_v;
        bool param_12 = false;
        int _9952 = subsurface_scatter_multi_intersect(param_8, param_9, param_10, param_11, param_12);
        lcg_state = param_9;
        int num_hits = _9952;
        LocalIntersection_tiny ss_isect;
        for (int hit = 0; hit < num_hits; hit++)
        {
            int idx = sd.atomic_offset + hit;
            Intersection _9981;
            _9981.t = push.pool_ptr2.pool_is.data[idx].t;
            _9981.u = push.pool_ptr2.pool_is.data[idx].u;
            _9981.v = push.pool_ptr2.pool_is.data[idx].v;
            _9981.prim = push.pool_ptr2.pool_is.data[idx].prim;
            _9981.object = push.pool_ptr2.pool_is.data[idx].object;
            _9981.type = push.pool_ptr2.pool_is.data[idx].type;
            ss_isect.isect[hit] = _9981;
            idx += 4;
            vec3 _10006 = vec3(push.pool_ptr2.pool_is.data[idx].t, push.pool_ptr2.pool_is.data[idx].u, push.pool_ptr2.pool_is.data[idx].v);
            ss_isect.weight[hit].x = _10006.x;
            ss_isect.weight[hit].y = _10006.y;
            ss_isect.weight[hit].z = _10006.z;
            if (hit == 0)
            {
                vec3 _10023 = vec3(isect.t, isect.u, isect.v);
                ss_isect.rayP.x = _10023.x;
                ss_isect.rayP.y = _10023.y;
                ss_isect.rayP.z = _10023.z;
                vec3 _10039 = vec3(intBitsToFloat(isect.prim), intBitsToFloat(isect.object), intBitsToFloat(isect.type));
                ss_isect.rayD.x = _10039.x;
                ss_isect.rayD.y = _10039.y;
                ss_isect.rayD.z = _10039.z;
            }
        }
        uint bssrdf_type = push.pool_ptr.pool_sc.data[n].type;
        float bssrdf_roughness = push.pool_ptr.pool_sc.data[n].data[8];
        for (int hit_1 = 0; hit_1 < num_hits; hit_1++)
        {
            vec4 param_13 = ss_isect.rayP;
            vec4 param_14 = ss_isect.rayD;
            Intersection param_15 = ss_isect.isect[hit_1];
            shader_setup_from_subsurface(param_13, param_14, param_15);
            vec4 weight = ss_isect.weight[hit_1];
            vec4 N = sd.N;
            vec4 param_16 = weight;
            vec4 param_17 = N;
            subsurface_color_bump_blur(param_16, param_17);
            weight = param_16;
            N = param_17;
            uint param_18 = bssrdf_type;
            float param_19 = bssrdf_roughness;
            vec4 param_20 = weight;
            vec4 param_21 = N;
            subsurface_scatter_setup_diffuse_bsdf(param_18, param_19, param_20, param_21);
            int _all = arg.state.flag & 131072;
            float param_22 = 1.0;
            int param_23 = _all;
            kernel_path_surface_connect_light(param_22, param_23);
            ss_indirect.state[ss_indirect.num_rays] = arg.state;
            ss_indirect.rays[ss_indirect.num_rays] = ray;
            ss_indirect.throughputs[ss_indirect.num_rays] = throughput;
            ss_indirect.L_state[ss_indirect.num_rays] = L.state;
            ss_indirect.state[ss_indirect.num_rays].rng_offset += 8;
            bool _10142 = kernel_path_surface_bounce_local();
            if (_10142)
            {
                ss_indirect.state[ss_indirect.num_rays].ray_t = 0.0;
                ss_indirect.num_rays++;
            }
        }
        return true;
    }
    return false;
}

void path_radiance_bsdf_bounce(float bsdf_pdf, int bounce, int bsdf_label)
{
    float inverse_pdf = 1.0 / bsdf_pdf;
    if (_1929.kernel_data.film.use_light_pass != int(0u))
    {
        bool _5922 = bounce == 0;
        bool _5930;
        if (_5922)
        {
            _5930 = !((uint(bsdf_label) & 32u) != 0u);
        }
        else
        {
            _5930 = _5922;
        }
        if (_5930)
        {
            vec4 value = throughput * inverse_pdf;
            L.state.diffuse = arg.L.emission * value;
            L.state.glossy = arg.L.direct_emission * value;
            L.state.transmission = arg.L.indirect * value;
            throughput = (L.state.diffuse + L.state.glossy) + L.state.transmission;
        }
        else
        {
            vec4 sum = (PLYMO_bsdf_eval_sum() + arg.L.path_total) * inverse_pdf;
            throughput *= sum;
        }
    }
    else
    {
        throughput *= (arg.L.emission * inverse_pdf);
    }
}

bool kernel_path_surface_bounce(inout Ray ray)
{
    if (G_dump)
    {
        _685.kg.u1[2 + ((rec_num - 1) * 64)] = uint(sd.flag);
    }
    if ((uint(sd.flag) & 4u) != 0u)
    {
        arg2.v[0] = uintBitsToFloat(arg.state.rng_hash);
        arg2.v[1] = intBitsToFloat(arg.state.sample_rsv);
        arg2.v[2] = intBitsToFloat(arg.state.num_samples);
        arg2.v[3] = intBitsToFloat(arg.state.rng_offset + 0);
        arg2.v[4] = uintBitsToFloat(1u);
        arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
        executeCallableNV(11u, 2);
        float randu = arg2.v[0];
        float randv = arg2.v[1];
        arg.L.direct_emission.w = float(PROFI_IDX);
        arg.L.indirect.w = float(rec_num);
        arg.ray.dP.dx.z = intBitsToFloat(1);
        arg.L.emission = vec4(randu, randv, 123.0, 456.0);
        executeCallableNV(1u, 0);
        if (G_dump)
        {
            _685.kg.f1[2 + ((rec_num - 1) * 64)] = arg.ray.dP.dx.w;
        }
        if (G_dump)
        {
            _685.kg.u1[3 + ((rec_num - 1) * 64)] = uint(floatBitsToInt(arg.ray.dP.dx.y));
        }
        if (G_dump)
        {
            _685.kg.f3[22 + ((rec_num - 1) * 64)] = arg.L.emission;
        }
        if (floatBitsToInt(arg.ray.dP.dx.y) != int(0u))
        {
            if (G_dump)
            {
                _685.kg.f3[23 + ((rec_num - 1) * 64)] = arg.L.direct_emission;
            }
            if (G_dump)
            {
                _685.kg.f3[24 + ((rec_num - 1) * 64)] = arg.L.indirect;
            }
            if (G_dump)
            {
                _685.kg.f3[25 + ((rec_num - 1) * 64)] = arg.L.path_total;
            }
        }
        bool _6289 = arg.ray.dP.dx.w == 0.0;
        bool _6294;
        if (!_6289)
        {
            _6294 = PLYMO_bsdf_eval_is_zero();
        }
        else
        {
            _6294 = _6289;
        }
        if (_6294)
        {
            return false;
        }
        int label = floatBitsToInt(arg.ray.dP.dx.x);
        float param = arg.ray.dP.dx.w;
        int param_1 = arg.state.bounce;
        int param_2 = label;
        path_radiance_bsdf_bounce(param, param_1, param_2);
        if (G_dump)
        {
            _685.kg.f3[19 + ((rec_num - 1) * 64)] = throughput;
        }
        if (!((uint(label) & 32u) != 0u))
        {
            arg.state.ray_pdf = arg.ray.dP.dx.w;
            arg.state.ray_t = 0.0;
            arg.state.min_ray_pdf = min(arg.ray.dP.dx.w, arg.state.min_ray_pdf);
        }
        PathState param_3 = arg.state;
        int param_4 = label;
        path_state_next(param_3, param_4);
        arg.state = param_3;
        vec4 _6350;
        if ((uint(label) & 1u) != 0u)
        {
            _6350 = -sd.Ng;
        }
        else
        {
            _6350 = sd.Ng;
        }
        vec4 param_5 = sd.P;
        vec4 param_6 = _6350;
        ray.P = ray_offset(param_5, param_6);
        ray.D = vec4(normalize(vec4(intBitsToFloat(arg.use_light_pass), intBitsToFloat(arg.type), arg.ray.t, arg.ray.time).xyz), 0.0);
        if (arg.state.bounce == 0)
        {
            ray.t -= sd.ray_length;
        }
        else
        {
            ray.t = 3.4028234663852885981170418348452e+38;
        }
        ray.dP = sd.dP;
        ray.dD.dx = arg.ray.P;
        ray.dD.dy = arg.ray.D;
        return true;
    }
    return false;
}

void path_radiance_sum_indirect()
{
    if (L.use_light_pass != 0)
    {
        vec4 param = L.direct_emission;
        vec4 param_1 = L.state.direct;
        L.direct_emission = safe_divide_color(param, param_1);
        L.direct_diffuse += (L.state.diffuse * L.direct_emission);
        L.direct_glossy += (L.state.glossy * L.direct_emission);
        L.direct_transmission += (L.state.transmission * L.direct_emission);
        vec4 param_2 = L.indirect;
        vec4 param_3 = L.state.direct;
        L.indirect = safe_divide_color(param_2, param_3);
        L.indirect_diffuse += (L.state.diffuse * L.indirect);
        L.indirect_glossy += (L.state.glossy * L.indirect);
        L.indirect_transmission += (L.state.transmission * L.indirect);
    }
}

void path_radiance_reset_indirect()
{
    if (L.use_light_pass != 0)
    {
        L.state.diffuse = vec4(0.0);
        L.state.glossy = vec4(0.0);
        L.state.transmission = vec4(0.0);
        L.direct_emission = vec4(0.0);
        L.indirect = vec4(0.0);
    }
}

void path_radiance_sum_shadowcatcher(inout vec4 L_sum, inout float alpha)
{
    float path_total = average(L.path_total);
    float param = path_total;
    float shadow;
    if (!isfinite_safe(param))
    {
        if (true)
        {
            // unimplemented ext op 12
        }
        shadow = 0.0;
    }
    else
    {
        if (path_total == 0.0)
        {
            shadow = L.shadow_transparency;
        }
        else
        {
            float path_total_shaded = average(L.path_total_shaded);
            shadow = path_total_shaded / path_total;
        }
    }
    if (_1929.kernel_data.background.transparent != 0)
    {
        alpha -= (L.shadow_throughput * shadow);
    }
    else
    {
        L.shadow_background_color *= shadow;
        L_sum += L.shadow_background_color;
    }
}

vec4 path_radiance_clamp_and_sum(inout float alpha)
{
    vec4 L_sum;
    if (L.use_light_pass != 0)
    {
        path_radiance_sum_indirect();
        vec4 L_direct = ((L.direct_diffuse + L.direct_glossy) + L.direct_transmission) + L.emission;
        vec4 L_indirect = (L.indirect_diffuse + L.indirect_glossy) + L.indirect_transmission;
        if (_1929.kernel_data.background.transparent == 0)
        {
            L_direct += L.background;
        }
        L_sum = L_direct + L_indirect;
        float sum = (abs(L_sum.x) + abs(L_sum.y)) + abs(L_sum.z);
        float param = sum;
        if (!isfinite_safe(param))
        {
            if (true)
            {
                // unimplemented ext op 12
            }
            L_sum = vec4(0.0);
            L.direct_diffuse = vec4(0.0);
            L.direct_glossy = vec4(0.0);
            L.direct_transmission = vec4(0.0);
            L.indirect_diffuse = vec4(0.0);
            L.indirect_glossy = vec4(0.0);
            L.indirect_transmission = vec4(0.0);
            L.emission = vec4(0.0);
        }
    }
    else
    {
        L_sum = L.emission;
        float sum_1 = (abs(L_sum.x) + abs(L_sum.y)) + abs(L_sum.z);
        float param_1 = sum_1;
        if (!isfinite_safe(param_1))
        {
            L_sum = vec4(1.0, 0.0, 0.0, 0.0);
        }
    }
    alpha = 1.0 - L.transparent;
    if (L.has_shadow_catcher != 0)
    {
        vec4 param_2 = L_sum;
        float param_3 = alpha;
        path_radiance_sum_shadowcatcher(param_2, param_3);
        L_sum = param_2;
        alpha = param_3;
    }
    return L_sum;
}

void kernel_write_pass_float4(int ofs, vec4 value)
{
    ivec2 dim = imageSize(image);
    imageStore(image, ivec2(int(gl_LaunchIDNV.x), int(uint(dim.y) - gl_LaunchIDNV.y)), value);
}

void kernel_write_result(int buffer_ofs, int sample_rsv)
{
    float alpha;
    float param = alpha;
    vec4 _7703 = path_radiance_clamp_and_sum(param);
    alpha = param;
    vec4 L_sum = _7703;
    if ((_1929.kernel_data.film.pass_flag & 2) != int(0u))
    {
        int param_1 = buffer_ofs;
        vec4 param_2 = vec4(L_sum.x, L_sum.y, L_sum.z, alpha);
        kernel_write_pass_float4(param_1, param_2);
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
    Dpixel = _685.kg.pixel;
    rec_num = 0;
    G_dump = false;
    if (all(equal(Dpixel, gl_LaunchIDNV.xy)))
    {
        G_dump = true;
        G_use_light_pass = _1929.kernel_data.film.use_light_pass != int(0u);
    }
    PROFI_IDX = int(gl_LaunchIDNV.x + (gl_LaunchIDNV.y * 512u));
    int atomic_offset = int(((((gl_BuiltIn_5377 * gl_BuiltIn_5374) + gl_BuiltIn_5376) * gl_SubgroupSize) + gl_SubgroupInvocationID) * 64u);
    push.pool_ptr.pool_sc.data[PROFI_IDX + 2228224].weight = vec4(float(atomic_offset), float(gl_BuiltIn_5376), float(gl_SubgroupInvocationID), float(PROFI_IDX));
    path_radiance_init();
    int sample_rsv = 0;
    uint rng_hash = 0u;
    int param = int(gl_LaunchIDNV.x);
    int param_1 = int(gl_LaunchIDNV.y);
    int param_2 = sample_rsv;
    uint param_3 = rng_hash;
    Ray ray;
    Ray param_4 = ray;
    kernel_path_trace_setup(param, param_1, param_2, param_3, param_4);
    rng_hash = param_3;
    ray = param_4;
    if (ray.t == 0.0)
    {
        return;
    }
    uint param_5 = rng_hash;
    int param_6 = sample_rsv;
    path_state_init(param_5, param_6);
    sd.atomic_offset = int(((((gl_BuiltIn_5377 * 32u) + gl_BuiltIn_5376) * gl_SubgroupSize) + gl_SubgroupInvocationID) * 64u);
    throughput = vec4(1.0);
    ss_indirect.num_rays = 0;
    while (true)
    {
        while (true)
        {
            Ray param_7 = ray;
            bool _10684 = kernel_path_scene_intersect(param_7);
            bool hit = _10684;
            if (rec_num == 0)
            {
                if (!hit)
                {
                    int _10694 = atomicAdd(_6660.counter[0], 1);
                }
                else
                {
                    int _10697 = atomicAdd(_6660.counter[1], 1);
                }
            }
            int _10701 = atomicAdd(_6660.counter[2 + rec_num], 1);
            rec_num++;
            Ray param_8 = ray;
            kernel_path_lamp_emission(param_8);
            if (!hit)
            {
                Ray param_9 = ray;
                kernel_path_background(param_9);
                break;
            }
            else
            {
                if (path_state_ao_bounce())
                {
                    int _10720 = atomicAdd(_6660.counter[33], 1);
                    break;
                }
            }
            Ray param_10 = ray;
            shader_setup_from_ray(param_10);
            uint param_11 = uint(arg.state.flag);
            shader_eval_surface(param_11);
            shader_prepare_closures();
            Ray param_12 = ray;
            bool _10733 = kernel_path_shader_apply(param_12);
            if (!_10733)
            {
                break;
            }
            float probability = path_state_continuation_probability();
            if (probability == 0.0)
            {
                break;
            }
            else
            {
                if (!(probability == 1.0))
                {
                    arg2.v[0] = uintBitsToFloat(arg.state.rng_hash);
                    arg2.v[1] = intBitsToFloat(arg.state.sample_rsv);
                    arg2.v[2] = intBitsToFloat(arg.state.num_samples);
                    arg2.v[3] = intBitsToFloat(arg.state.rng_offset + 5);
                    arg2.v[4] = uintBitsToFloat(0u);
                    arg2.v[5] = uintBitsToFloat(uint(_1929.kernel_data.integrator.sampling_pattern));
                    executeCallableNV(11u, 2);
                    float terminate = arg2.v[0];
                    if (terminate >= probability)
                    {
                        break;
                    }
                    throughput /= vec4(probability);
                }
            }
            if ((uint(sd.flag) & 16u) != 0u)
            {
                Ray param_13 = ray;
                bool _10796 = kernel_path_subsurface_scatter(param_13);
                if (_10796)
                {
                    break;
                }
            }
            int _all = arg.state.flag & 131072;
            float param_14 = 1.0;
            int param_15 = _all;
            kernel_path_surface_connect_light(param_14, param_15);
            Ray param_16 = ray;
            bool _10810 = kernel_path_surface_bounce(param_16);
            ray = param_16;
            if (!_10810)
            {
                int _10817 = atomicAdd(_6660.counter[43], 1);
                break;
            }
            uint bounce = uint(arg.state.bounce);
            if (G_dump)
            {
                _685.kg.u1[1 + ((rec_num - 1) * 64)] = bounce;
            }
            if (G_dump)
            {
                _685.kg.f3[20 + ((rec_num - 1) * 64)] = ray.D;
            }
        }
        if (ss_indirect.num_rays != int(0u))
        {
            ss_indirect.num_rays--;
            path_radiance_sum_indirect();
            path_radiance_reset_indirect();
            arg.state = ss_indirect.state[ss_indirect.num_rays];
            ray = ss_indirect.rays[ss_indirect.num_rays];
            L.state = ss_indirect.L_state[ss_indirect.num_rays];
            throughput = ss_indirect.throughputs[ss_indirect.num_rays];
            arg.state.rng_offset += int(uint(ss_indirect.num_rays) * 8u);
            if (G_dump)
            {
                _685.kg.f3[33 + ((rec_num - 1) * 64)] = throughput;
            }
        }
        else
        {
            break;
        }
    }
    if (G_dump)
    {
        _6660.counter[1000] = rec_num;
    }
    int param_17 = 0;
    int param_18 = sample_rsv;
    kernel_write_result(param_17, param_18);
}

