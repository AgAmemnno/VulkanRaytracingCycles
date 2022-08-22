#version 460
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require

struct Transform
{
    vec4 x;
    vec4 y;
    vec4 z;
};

struct PatchHandle
{
    int array_index;
    int patch_index;
    int vert_index;
};

struct AttributeDescriptor
{
    uint element;
    uint type;
    uint flags;
    int offset;
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

struct differential
{
    float dx;
    float dy;
};

struct sd_geom_tiny
{
    int offset;
    uint call_type;
    vec4 N;
    int object_flag;
    int prim;
    int type;
    float u;
    float v;
    int object;
    differential du;
    differential dv;
    int lamp;
    uvec4 node;
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

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_tri_verts_;
layout(buffer_reference) buffer _prim_tri_index_;
layout(buffer_reference) buffer _objects_;
layout(buffer_reference) buffer _object_flag_;
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
layout(buffer_reference) buffer _lights_;
layout(buffer_reference, std430) buffer KernelTextures
{
    _prim_tri_verts_ _prim_tri_verts;
    _prim_tri_index_ _prim_tri_index;
    int64_t pad2[4];
    _objects_ _objects;
    _object_flag_ _object_flag;
    int64_t pad3[1];
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
    int64_t pad5;
    _lights_ _lights;
};

layout(buffer_reference, std430) readonly buffer _prim_tri_verts_
{
    vec4 data[];
};

layout(buffer_reference, std430) readonly buffer _prim_tri_index_
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

layout(buffer_reference, std430) readonly buffer _lights_
{
    KernelLight data[];
};

layout(set = 2, binding = 0, std430) buffer KD
{
    KernelData kernel_data;
} _7870;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

layout(location = 2) callableDataInNV sd_geom_tiny ioSD;

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

AttributeDescriptor attribute_not_found()
{
    return AttributeDescriptor(0u, 0u, 0u, -1);
}

uint attribute_primitive_type()
{
    bool _6066 = (uint(ioSD.type) & 3u) != 0u;
    bool _6086;
    if (_6066)
    {
        uint _6072;
        if (ioSD.prim != (-1))
        {
            _6072 = push.data_ptr._tri_patch.data[ioSD.prim];
        }
        else
        {
            _6072 = 4294967295u;
        }
        _6086 = _6072 != 4294967295u;
    }
    else
    {
        _6086 = _6066;
    }
    if (_6086)
    {
        return 1u;
    }
    else
    {
        return 0u;
    }
}

AttributeDescriptor find_attribute(uint id)
{
    if (ioSD.object == (-1))
    {
        return attribute_not_found();
    }
    uint attr_offset = push.data_ptr._objects.data[ioSD.object].attribute_map_offset;
    attr_offset += attribute_primitive_type();
    uvec4 attr_map = push.data_ptr._attributes_map.data[attr_offset];
    while (attr_map.x != id)
    {
        if (attr_map.x == 0u)
        {
            return attribute_not_found();
        }
        attr_offset += 2u;
        attr_map = push.data_ptr._attributes_map.data[attr_offset];
    }
    AttributeDescriptor desc;
    desc.element = attr_map.y;
    bool _6157 = ioSD.prim == (-1);
    bool _6163;
    if (_6157)
    {
        _6163 = desc.element != 2u;
    }
    else
    {
        _6163 = _6157;
    }
    bool _6170;
    if (_6163)
    {
        _6170 = desc.element != 11u;
    }
    else
    {
        _6170 = _6163;
    }
    bool _6176;
    if (_6170)
    {
        _6176 = desc.element != 1u;
    }
    else
    {
        _6176 = _6170;
    }
    if (_6176)
    {
        return attribute_not_found();
    }
    int _6184;
    if (attr_map.y == 0u)
    {
        _6184 = -1;
    }
    else
    {
        _6184 = int(attr_map.z);
    }
    desc.offset = _6184;
    desc.type = attr_map.w & 255u;
    desc.flags = attr_map.w >> uint(8);
    return desc;
}

vec2 triangle_attribute_float2(AttributeDescriptor desc, inout vec2 dx2, inout vec2 dy2)
{
    if (desc.element == 3u)
    {
        if (!(dx2.x == 3.4028234663852885981170418348452e+38))
        {
            dx2 = vec2(0.0);
        }
        if (!(dy2.x == 3.4028234663852885981170418348452e+38))
        {
            dy2 = vec2(0.0);
        }
        return push.data_ptr._attributes_float2.data[desc.offset + ioSD.prim];
    }
    else
    {
        bool _6521 = desc.element == 4u;
        bool _6527;
        if (!_6521)
        {
            _6527 = desc.element == 5u;
        }
        else
        {
            _6527 = _6521;
        }
        if (_6527)
        {
            uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
            vec2 f0 = push.data_ptr._attributes_float2.data[uint(desc.offset) + tri_vindex.x];
            vec2 f1 = push.data_ptr._attributes_float2.data[uint(desc.offset) + tri_vindex.y];
            vec2 f2 = push.data_ptr._attributes_float2.data[uint(desc.offset) + tri_vindex.z];
            if (!(dx2.x == 3.4028234663852885981170418348452e+38))
            {
                dx2 = ((f0 * ioSD.du.dx) + (f1 * ioSD.dv.dx)) - (f2 * (ioSD.du.dx + ioSD.dv.dx));
            }
            if (!(dy2.x == 3.4028234663852885981170418348452e+38))
            {
                dy2 = ((f0 * ioSD.du.dy) + (f1 * ioSD.dv.dy)) - (f2 * (ioSD.du.dy + ioSD.dv.dy));
            }
            // unimplemented ext op 12
            return ((f0 * ioSD.u) + (f1 * ioSD.v)) + (f2 * ((1.0 - ioSD.u) - ioSD.v));
        }
        else
        {
            if (desc.element == 6u)
            {
                int tri = desc.offset + (ioSD.prim * 3);
                vec2 f0_1;
                vec2 f1_1;
                vec2 f2_1;
                if (desc.element == 6u)
                {
                    f0_1 = push.data_ptr._attributes_float2.data[tri + 0];
                    f1_1 = push.data_ptr._attributes_float2.data[tri + 1];
                    f2_1 = push.data_ptr._attributes_float2.data[tri + 2];
                }
                if (!(dx2.x == 3.4028234663852885981170418348452e+38))
                {
                    dx2 = ((f0_1 * ioSD.du.dx) + (f1_1 * ioSD.dv.dx)) - (f2_1 * (ioSD.du.dx + ioSD.dv.dx));
                }
                if (!(dy2.x == 3.4028234663852885981170418348452e+38))
                {
                    dy2 = ((f0_1 * ioSD.du.dy) + (f1_1 * ioSD.dv.dy)) - (f2_1 * (ioSD.du.dy + ioSD.dv.dy));
                }
                return ((f0_1 * ioSD.u) + (f1_1 * ioSD.v)) + (f2_1 * ((1.0 - ioSD.u) - ioSD.v));
            }
            else
            {
                bool _6755 = desc.element == 1u;
                bool _6761;
                if (!_6755)
                {
                    _6761 = desc.element == 2u;
                }
                else
                {
                    _6761 = _6755;
                }
                if (_6761)
                {
                    if (!(dx2.x == 3.4028234663852885981170418348452e+38))
                    {
                        dx2 = vec2(0.0);
                    }
                    if (!(dy2.x == 3.4028234663852885981170418348452e+38))
                    {
                        dy2 = vec2(0.0);
                    }
                    return push.data_ptr._attributes_float2.data[desc.offset];
                }
                else
                {
                    if (!(dx2.x == 3.4028234663852885981170418348452e+38))
                    {
                        dx2 = vec2(0.0);
                    }
                    if (!(dy2.x == 3.4028234663852885981170418348452e+38))
                    {
                        dy2 = vec2(0.0);
                    }
                    return vec2(0.0);
                }
            }
        }
    }
}

uint object_patch_map_offset(int object)
{
    if (object == (-1))
    {
        return 0u;
    }
    return push.data_ptr._objects.data[object].patch_map_offset;
}

int patch_map_resolve_quadrant(float median, inout float u, inout float v)
{
    int quadrant = -1;
    if (u < median)
    {
        if (v < median)
        {
            quadrant = 0;
        }
        else
        {
            quadrant = 1;
            v -= median;
        }
    }
    else
    {
        if (v < median)
        {
            quadrant = 3;
        }
        else
        {
            quadrant = 2;
            v -= median;
        }
        u -= median;
    }
    return quadrant;
}

PatchHandle patch_map_find_patch(int object, int patch_rsv, inout float u, inout float v)
{
    if (!((((u >= 0.0) && (u <= 1.0)) && (v >= 0.0)) && (v <= 1.0)))
    {
        // unimplemented ext op 12
    }
    int param = object;
    int node = int((object_patch_map_offset(param) + uint(patch_rsv)) / 2u);
    float median = 0.5;
    PatchHandle handle;
    for (int depth = 0; depth < 255; depth++)
    {
        float delta = median * 0.5;
        float param_1 = median;
        float param_2 = u;
        float param_3 = v;
        int _525 = patch_map_resolve_quadrant(param_1, param_2, param_3);
        u = param_2;
        v = param_3;
        int quadrant = _525;
        if (!(quadrant >= 0))
        {
            // unimplemented ext op 12
        }
        uint child = push.data_ptr._patches.data[node + quadrant];
        if (!((child & 1073741824u) != 0u))
        {
            handle.array_index = -1;
            return handle;
        }
        uint index = child & 1073741823u;
        if ((child & 2147483648u) != 0u)
        {
            handle.array_index = int(push.data_ptr._patches.data[index + 0u]);
            handle.patch_index = int(push.data_ptr._patches.data[index + 1u]);
            handle.vert_index = int(push.data_ptr._patches.data[index + 2u]);
            return handle;
        }
        else
        {
            node = int(index);
        }
        median = delta;
    }
    if (true)
    {
        // unimplemented ext op 12
    }
    handle.array_index = -1;
    return handle;
}

vec2 patch_eval_float2(int offset, int patch_rsv, inout float u, inout float v, int channel, inout vec2 du2, inout vec2 dv2)
{
    int param = ioSD.object;
    int param_1 = patch_rsv;
    float param_2 = u;
    float param_3 = v;
    PatchHandle _1209 = patch_map_find_patch(param, param_1, param_2, param_3);
    PatchHandle handle = _1209;
    if (!(handle.array_index >= 0))
    {
        // unimplemented ext op 12
    }
    int index_base = int(push.data_ptr._patches.data[handle.array_index + 2] + uint(handle.vert_index));
    int indices[16];
    for (int i = 0; i < 16; i++)
    {
        indices[i] = int(push.data_ptr._patches.data[index_base + i]);
    }
    int num_control = 16;
    uint patch_bits = push.data_ptr._patches.data[handle.patch_index + 1];
    float d_scale = float(1 << int(patch_bits & 15u));
    bool non_quad_root = ((patch_bits >> uint(4)) & 1u) != 0u;
    if (non_quad_root)
    {
        d_scale *= 0.5;
    }
    bool non_quad_root_1 = ((patch_bits >> uint(4)) & 1u) != 0u;
    int depth = int(patch_bits & 15u);
    float frac;
    if (non_quad_root_1)
    {
        frac = 1.0 / float(1 << (depth - 1));
    }
    else
    {
        frac = 1.0 / float(1 << depth);
    }
    int iu = int((patch_bits >> uint(22)) & 1023u);
    int iv = int((patch_bits >> uint(12)) & 1023u);
    float pu = float(iu) * frac;
    float pv = float(iv) * frac;
    u = (u - pu) / frac;
    v = (v - pv) / frac;
    float inv_6 = 0.16666667163372039794921875;
    float t2 = u * u;
    float t3 = u * t2;
    float s[4];
    s[0] = inv_6 * ((1.0 - (3.0 * (u - t2))) - t3);
    s[1] = inv_6 * ((4.0 - (6.0 * t2)) + (3.0 * t3));
    s[2] = inv_6 * (1.0 + (3.0 * ((u + t2) - t3)));
    s[3] = inv_6 * t3;
    float ds[4];
    ds[0] = (((-0.5) * t2) + u) - 0.5;
    ds[1] = (1.5 * t2) - (2.0 * u);
    ds[2] = (((-1.5) * t2) + u) + 0.5;
    ds[3] = 0.5 * t2;
    float inv_6_1 = 0.16666667163372039794921875;
    float t2_1 = v * v;
    float t3_1 = v * t2_1;
    float t[4];
    t[0] = inv_6_1 * ((1.0 - (3.0 * (v - t2_1))) - t3_1);
    t[1] = inv_6_1 * ((4.0 - (6.0 * t2_1)) + (3.0 * t3_1));
    t[2] = inv_6_1 * (1.0 + (3.0 * ((v + t2_1) - t3_1)));
    t[3] = inv_6_1 * t3_1;
    float dt[4];
    dt[0] = (((-0.5) * t2_1) + v) - 0.5;
    dt[1] = (1.5 * t2_1) - (2.0 * v);
    dt[2] = (((-1.5) * t2_1) + v) + 0.5;
    dt[3] = 0.5 * t2_1;
    int boundary = int((patch_bits >> uint(8)) & 15u);
    if ((boundary & 1) != int(0u))
    {
        t[2] -= t[0];
        t[1] += (2.0 * t[0]);
        t[0] = 0.0;
    }
    if ((boundary & 2) != int(0u))
    {
        s[1] -= s[3];
        s[2] += (2.0 * s[3]);
        s[3] = 0.0;
    }
    if ((boundary & 4) != int(0u))
    {
        t[1] -= t[3];
        t[2] += (2.0 * t[3]);
        t[3] = 0.0;
    }
    if ((boundary & 8) != int(0u))
    {
        s[2] -= s[0];
        s[1] += (2.0 * s[0]);
        s[0] = 0.0;
    }
    int boundary_1 = int((patch_bits >> uint(8)) & 15u);
    if ((boundary_1 & 1) != int(0u))
    {
        dt[2] -= dt[0];
        dt[1] += (2.0 * dt[0]);
        dt[0] = 0.0;
    }
    if ((boundary_1 & 2) != int(0u))
    {
        ds[1] -= ds[3];
        ds[2] += (2.0 * ds[3]);
        ds[3] = 0.0;
    }
    if ((boundary_1 & 4) != int(0u))
    {
        dt[1] -= dt[3];
        dt[2] += (2.0 * dt[3]);
        dt[3] = 0.0;
    }
    if ((boundary_1 & 8) != int(0u))
    {
        ds[2] -= ds[0];
        ds[1] += (2.0 * ds[0]);
        ds[0] = 0.0;
    }
    float weights[16];
    float weights_du[16];
    float weights_dv[16];
    for (int k = 0; k < 4; k++)
    {
        for (int l = 0; l < 4; l++)
        {
            weights[(4 * k) + l] = s[l] * t[k];
            weights_du[(4 * k) + l] = (ds[l] * t[k]) * d_scale;
            weights_dv[(4 * k) + l] = (s[l] * dt[k]) * d_scale;
        }
    }
    vec2 val = vec2(0.0);
    if (!(du2.x == 3.4028234663852885981170418348452e+38))
    {
        du2 = vec2(0.0);
    }
    if (!(dv2.x == 3.4028234663852885981170418348452e+38))
    {
        dv2 = vec2(0.0);
    }
    for (int i_1 = 0; i_1 < num_control; i_1++)
    {
        vec2 v_1 = push.data_ptr._attributes_float2.data[offset + indices[i_1]];
        val += (v_1 * weights[i_1]);
        if (!(du2.x == 3.4028234663852885981170418348452e+38))
        {
            du2 += (v_1 * weights_du[i_1]);
        }
        if (!(dv2.x == 3.4028234663852885981170418348452e+38))
        {
            dv2 += (v_1 * weights_dv[i_1]);
        }
    }
    return val;
}

uvec4 subd_triangle_patch_indices(int patch_rsv)
{
    uvec4 indices;
    indices.x = push.data_ptr._patches.data[patch_rsv + 0];
    indices.y = push.data_ptr._patches.data[patch_rsv + 1];
    indices.z = push.data_ptr._patches.data[patch_rsv + 2];
    indices.w = push.data_ptr._patches.data[patch_rsv + 3];
    return indices;
}

int mod(int x, int m)
{
    return ((x % m) + m) % m;
}

vec2 subd_triangle_attribute_float2(AttributeDescriptor desc, inout vec2 dx2, inout vec2 dy2)
{
    uint _3776;
    if (ioSD.prim != (-1))
    {
        _3776 = push.data_ptr._tri_patch.data[ioSD.prim];
    }
    else
    {
        _3776 = 4294967295u;
    }
    int patch_rsv = int(_3776);
    if ((desc.flags & 2u) != 0u)
    {
        uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
        vec2 uv[3];
        uv[0] = push.data_ptr._tri_patch_uv.data[tri_vindex.x];
        uv[1] = push.data_ptr._tri_patch_uv.data[tri_vindex.y];
        uv[2] = push.data_ptr._tri_patch_uv.data[tri_vindex.z];
        vec2 dpdu = uv[0] - uv[2];
        vec2 dpdv = uv[1] - uv[2];
        vec2 p = ((dpdu * ioSD.u) + (dpdv * ioSD.v)) + uv[2];
        int param = desc.offset;
        int param_1 = patch_rsv;
        float param_2 = p.x;
        float param_3 = p.y;
        int param_4 = 0;
        vec2 dads;
        vec2 param_5 = dads;
        vec2 dadt;
        vec2 param_6 = dadt;
        vec2 _3875 = patch_eval_float2(param, param_1, param_2, param_3, param_4, param_5, param_6);
        dads = param_5;
        dadt = param_6;
        vec2 a = _3875;
        bool _3881 = !(dx2.x == 3.4028234663852885981170418348452e+38);
        bool _3889;
        if (!_3881)
        {
            _3889 = !(dy2.x == 3.4028234663852885981170418348452e+38);
        }
        else
        {
            _3889 = _3881;
        }
        if (_3889)
        {
            float dsdu = dpdu.x;
            float dtdu = dpdu.y;
            float dsdv = dpdv.x;
            float dtdv = dpdv.y;
            if (!(dx2.x == 3.4028234663852885981170418348452e+38))
            {
                float dudx = ioSD.du.dx;
                float dvdx = ioSD.dv.dx;
                float dsdx = (dsdu * dudx) + (dsdv * dvdx);
                float dtdx = (dtdu * dudx) + (dtdv * dvdx);
                dx2 = (dads * dsdx) + (dadt * dtdx);
            }
            if (!(dy2.x == 3.4028234663852885981170418348452e+38))
            {
                float dudy = ioSD.du.dy;
                float dvdy = ioSD.dv.dy;
                float dsdy = (dsdu * dudy) + (dsdv * dvdy);
                float dtdy = (dtdu * dudy) + (dtdv * dvdy);
                dy2 = (dads * dsdy) + (dadt * dtdy);
            }
        }
        return a;
    }
    else
    {
        if (desc.element == 3u)
        {
            if (!(dx2.x == 3.4028234663852885981170418348452e+38))
            {
                dx2 = vec2(0.0);
            }
            if (!(dy2.x == 3.4028234663852885981170418348452e+38))
            {
                dy2 = vec2(0.0);
            }
            return push.data_ptr._attributes_float2.data[uint(desc.offset) + push.data_ptr._patches.data[patch_rsv + 4]];
        }
        else
        {
            bool _4013 = desc.element == 4u;
            bool _4019;
            if (!_4013)
            {
                _4019 = desc.element == 5u;
            }
            else
            {
                _4019 = _4013;
            }
            if (_4019)
            {
                uvec4 tri_vindex_1 = push.data_ptr._tri_vindex.data[ioSD.prim];
                vec2 uv_1[3];
                uv_1[0] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.x];
                uv_1[1] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.y];
                uv_1[2] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.z];
                int param_7 = patch_rsv;
                uvec4 v = subd_triangle_patch_indices(param_7);
                vec2 f0 = push.data_ptr._attributes_float2.data[uint(desc.offset) + v.x];
                vec2 f1 = push.data_ptr._attributes_float2.data[uint(desc.offset) + v.y];
                vec2 f2 = push.data_ptr._attributes_float2.data[uint(desc.offset) + v.z];
                vec2 f3 = push.data_ptr._attributes_float2.data[uint(desc.offset) + v.w];
                if ((push.data_ptr._patches.data[patch_rsv + 5] & 65535u) != 4u)
                {
                    f1 = (f1 + f0) * 0.5;
                    f3 = (f3 + f0) * 0.5;
                }
                vec2 a_1 = mix(mix(f0, f1, vec2(uv_1[0].x)), mix(f3, f2, vec2(uv_1[0].x)), vec2(uv_1[0].y));
                vec2 b = mix(mix(f0, f1, vec2(uv_1[1].x)), mix(f3, f2, vec2(uv_1[1].x)), vec2(uv_1[1].y));
                vec2 c = mix(mix(f0, f1, vec2(uv_1[2].x)), mix(f3, f2, vec2(uv_1[2].x)), vec2(uv_1[2].y));
                if (!(dx2.x == 3.4028234663852885981170418348452e+38))
                {
                    dx2 = ((a_1 * ioSD.du.dx) + (b * ioSD.dv.dx)) - (c * (ioSD.du.dx + ioSD.dv.dx));
                }
                if (!(dy2.x == 3.4028234663852885981170418348452e+38))
                {
                    dy2 = ((a_1 * ioSD.du.dy) + (b * ioSD.dv.dy)) - (c * (ioSD.du.dy + ioSD.dv.dy));
                }
                return ((a_1 * ioSD.u) + (b * ioSD.v)) + (c * ((1.0 - ioSD.u) - ioSD.v));
            }
            else
            {
                if (desc.element == 6u)
                {
                    uvec4 tri_vindex_2 = push.data_ptr._tri_vindex.data[ioSD.prim];
                    vec2 uv_2[3];
                    uv_2[0] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.x];
                    uv_2[1] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.y];
                    uv_2[2] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.z];
                    uvec4 data;
                    data.x = push.data_ptr._patches.data[patch_rsv + 4];
                    data.y = push.data_ptr._patches.data[patch_rsv + 5];
                    data.z = push.data_ptr._patches.data[patch_rsv + 6];
                    data.w = push.data_ptr._patches.data[patch_rsv + 7];
                    int num_corners = int(data.y & 65535u);
                    int corners[4];
                    if (num_corners == 4)
                    {
                        corners[0] = int(data.z);
                        corners[1] = int(data.z) + 1;
                        corners[2] = int(data.z) + 2;
                        corners[3] = int(data.z) + 3;
                    }
                    else
                    {
                        int c_1 = int(data.y >> uint(16));
                        corners[0] = int(data.z) + c_1;
                        int param_8 = c_1 + 1;
                        int param_9 = num_corners;
                        corners[1] = int(data.z) + mod(param_8, param_9);
                        corners[2] = int(data.w);
                        int param_10 = c_1 - 1;
                        int param_11 = num_corners;
                        corners[3] = int(data.z) + mod(param_10, param_11);
                    }
                    vec2 f0_1 = push.data_ptr._attributes_float2.data[corners[0] + desc.offset];
                    vec2 f1_1 = push.data_ptr._attributes_float2.data[corners[1] + desc.offset];
                    vec2 f2_1 = push.data_ptr._attributes_float2.data[corners[2] + desc.offset];
                    vec2 f3_1 = push.data_ptr._attributes_float2.data[corners[3] + desc.offset];
                    if ((push.data_ptr._patches.data[patch_rsv + 5] & 65535u) != 4u)
                    {
                        f1_1 = (f1_1 + f0_1) * 0.5;
                        f3_1 = (f3_1 + f0_1) * 0.5;
                    }
                    vec2 a_2 = mix(mix(f0_1, f1_1, vec2(uv_2[0].x)), mix(f3_1, f2_1, vec2(uv_2[0].x)), vec2(uv_2[0].y));
                    vec2 b_1 = mix(mix(f0_1, f1_1, vec2(uv_2[1].x)), mix(f3_1, f2_1, vec2(uv_2[1].x)), vec2(uv_2[1].y));
                    vec2 c_2 = mix(mix(f0_1, f1_1, vec2(uv_2[2].x)), mix(f3_1, f2_1, vec2(uv_2[2].x)), vec2(uv_2[2].y));
                    if (!(dx2.x == 3.4028234663852885981170418348452e+38))
                    {
                        dx2 = ((a_2 * ioSD.du.dx) + (b_1 * ioSD.dv.dx)) - (c_2 * (ioSD.du.dx + ioSD.dv.dx));
                    }
                    if (!(dy2.x == 3.4028234663852885981170418348452e+38))
                    {
                        dy2 = ((a_2 * ioSD.du.dy) + (b_1 * ioSD.dv.dy)) - (c_2 * (ioSD.du.dy + ioSD.dv.dy));
                    }
                    return ((a_2 * ioSD.u) + (b_1 * ioSD.v)) + (c_2 * ((1.0 - ioSD.u) - ioSD.v));
                }
                else
                {
                    bool _4575 = desc.element == 1u;
                    bool _4581;
                    if (!_4575)
                    {
                        _4581 = desc.element == 2u;
                    }
                    else
                    {
                        _4581 = _4575;
                    }
                    if (_4581)
                    {
                        if (!(dx2.x == 3.4028234663852885981170418348452e+38))
                        {
                            dx2 = vec2(0.0);
                        }
                        if (!(dy2.x == 3.4028234663852885981170418348452e+38))
                        {
                            dy2 = vec2(0.0);
                        }
                        return push.data_ptr._attributes_float2.data[desc.offset];
                    }
                    else
                    {
                        if (!(dx2.x == 3.4028234663852885981170418348452e+38))
                        {
                            dx2 = vec2(0.0);
                        }
                        if (!(dy2.x == 3.4028234663852885981170418348452e+38))
                        {
                            dy2 = vec2(0.0);
                        }
                        return vec2(0.0);
                    }
                }
            }
        }
    }
}

vec2 primitive_attribute_float2(AttributeDescriptor desc, inout vec2 dx2, inout vec2 dy2)
{
    if ((uint(ioSD.type) & 3u) != 0u)
    {
        uint _7437;
        if (ioSD.prim != (-1))
        {
            _7437 = push.data_ptr._tri_patch.data[ioSD.prim];
        }
        else
        {
            _7437 = 4294967295u;
        }
        if (_7437 == 4294967295u)
        {
            vec2 param = dx2;
            vec2 param_1 = dy2;
            vec2 _7457 = triangle_attribute_float2(desc, param, param_1);
            dx2 = param;
            dy2 = param_1;
            return _7457;
        }
        else
        {
            vec2 param_2 = dx2;
            vec2 param_3 = dy2;
            vec2 _7466 = subd_triangle_attribute_float2(desc, param_2, param_3);
            dx2 = param_2;
            dy2 = param_3;
            return _7466;
        }
    }
    else
    {
        if (!(dx2.x == 3.4028234663852885981170418348452e+38))
        {
            dx2 = vec2(0.0);
        }
        if (!(dy2.x == 3.4028234663852885981170418348452e+38))
        {
            dy2 = vec2(0.0);
        }
        return vec2(0.0);
    }
}

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

vec4 triangle_attribute_float3(AttributeDescriptor desc, inout vec4 dx3, inout vec4 dy3)
{
    if (desc.element == 3u)
    {
        if (!(dx3.x == 3.4028234663852885981170418348452e+38))
        {
            dx3 = vec4(0.0);
        }
        if (!(dy3.x == 3.4028234663852885981170418348452e+38))
        {
            dy3 = vec4(0.0);
        }
        return float4_to_float3(push.data_ptr._attributes_float3.data[desc.offset + ioSD.prim]);
    }
    else
    {
        bool _6829 = desc.element == 4u;
        bool _6835;
        if (!_6829)
        {
            _6835 = desc.element == 5u;
        }
        else
        {
            _6835 = _6829;
        }
        if (_6835)
        {
            uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
            vec4 f0 = float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + tri_vindex.x]);
            vec4 f1 = float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + tri_vindex.y]);
            vec4 f2 = float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + tri_vindex.z]);
            if (!(dx3.x == 3.4028234663852885981170418348452e+38))
            {
                dx3 = ((f0 * ioSD.du.dx) + (f1 * ioSD.dv.dx)) - (f2 * (ioSD.du.dx + ioSD.dv.dx));
            }
            if (!(dy3.x == 3.4028234663852885981170418348452e+38))
            {
                dy3 = ((f0 * ioSD.du.dy) + (f1 * ioSD.dv.dy)) - (f2 * (ioSD.du.dy + ioSD.dv.dy));
            }
            return ((f0 * ioSD.u) + (f1 * ioSD.v)) + (f2 * ((1.0 - ioSD.u) - ioSD.v));
        }
        else
        {
            if (desc.element == 6u)
            {
                int tri = desc.offset + (ioSD.prim * 3);
                vec4 f0_1 = float4_to_float3(push.data_ptr._attributes_float3.data[tri + 0]);
                vec4 f1_1 = float4_to_float3(push.data_ptr._attributes_float3.data[tri + 1]);
                vec4 f2_1 = float4_to_float3(push.data_ptr._attributes_float3.data[tri + 2]);
                if (!(dx3.x == 3.4028234663852885981170418348452e+38))
                {
                    dx3 = ((f0_1 * ioSD.du.dx) + (f1_1 * ioSD.dv.dx)) - (f2_1 * (ioSD.du.dx + ioSD.dv.dx));
                }
                if (!(dy3.x == 3.4028234663852885981170418348452e+38))
                {
                    dy3 = ((f0_1 * ioSD.du.dy) + (f1_1 * ioSD.dv.dy)) - (f2_1 * (ioSD.du.dy + ioSD.dv.dy));
                }
                return ((f0_1 * ioSD.u) + (f1_1 * ioSD.v)) + (f2_1 * ((1.0 - ioSD.u) - ioSD.v));
            }
            else
            {
                bool _7059 = desc.element == 1u;
                bool _7065;
                if (!_7059)
                {
                    _7065 = desc.element == 2u;
                }
                else
                {
                    _7065 = _7059;
                }
                if (_7065)
                {
                    if (!(dx3.x == 3.4028234663852885981170418348452e+38))
                    {
                        dx3 = vec4(0.0);
                    }
                    if (!(dy3.x == 3.4028234663852885981170418348452e+38))
                    {
                        dy3 = vec4(0.0);
                    }
                    return float4_to_float3(push.data_ptr._attributes_float3.data[desc.offset]);
                }
                else
                {
                    if (!(dx3.x == 3.4028234663852885981170418348452e+38))
                    {
                        dx3 = vec4(0.0);
                    }
                    if (!(dy3.x == 3.4028234663852885981170418348452e+38))
                    {
                        dy3 = vec4(0.0);
                    }
                    return vec4(0.0);
                }
            }
        }
    }
}

vec4 patch_eval_float3(int offset, int patch_rsv, inout float u, inout float v, int channel, inout vec4 du3, inout vec4 dv3)
{
    int param = ioSD.object;
    int param_1 = patch_rsv;
    float param_2 = u;
    float param_3 = v;
    PatchHandle _1776 = patch_map_find_patch(param, param_1, param_2, param_3);
    PatchHandle handle = _1776;
    if (!(handle.array_index >= 0))
    {
        // unimplemented ext op 12
    }
    int index_base = int(push.data_ptr._patches.data[handle.array_index + 2] + uint(handle.vert_index));
    int indices[16];
    for (int i = 0; i < 16; i++)
    {
        indices[i] = int(push.data_ptr._patches.data[index_base + i]);
    }
    int num_control = 16;
    uint patch_bits = push.data_ptr._patches.data[handle.patch_index + 1];
    float d_scale = float(1 << int(patch_bits & 15u));
    bool non_quad_root = ((patch_bits >> uint(4)) & 1u) != 0u;
    if (non_quad_root)
    {
        d_scale *= 0.5;
    }
    bool non_quad_root_1 = ((patch_bits >> uint(4)) & 1u) != 0u;
    int depth = int(patch_bits & 15u);
    float frac;
    if (non_quad_root_1)
    {
        frac = 1.0 / float(1 << (depth - 1));
    }
    else
    {
        frac = 1.0 / float(1 << depth);
    }
    int iu = int((patch_bits >> uint(22)) & 1023u);
    int iv = int((patch_bits >> uint(12)) & 1023u);
    float pu = float(iu) * frac;
    float pv = float(iv) * frac;
    u = (u - pu) / frac;
    v = (v - pv) / frac;
    float inv_6 = 0.16666667163372039794921875;
    float t2 = u * u;
    float t3 = u * t2;
    float s[4];
    s[0] = inv_6 * ((1.0 - (3.0 * (u - t2))) - t3);
    s[1] = inv_6 * ((4.0 - (6.0 * t2)) + (3.0 * t3));
    s[2] = inv_6 * (1.0 + (3.0 * ((u + t2) - t3)));
    s[3] = inv_6 * t3;
    float ds[4];
    ds[0] = (((-0.5) * t2) + u) - 0.5;
    ds[1] = (1.5 * t2) - (2.0 * u);
    ds[2] = (((-1.5) * t2) + u) + 0.5;
    ds[3] = 0.5 * t2;
    float inv_6_1 = 0.16666667163372039794921875;
    float t2_1 = v * v;
    float t3_1 = v * t2_1;
    float t[4];
    t[0] = inv_6_1 * ((1.0 - (3.0 * (v - t2_1))) - t3_1);
    t[1] = inv_6_1 * ((4.0 - (6.0 * t2_1)) + (3.0 * t3_1));
    t[2] = inv_6_1 * (1.0 + (3.0 * ((v + t2_1) - t3_1)));
    t[3] = inv_6_1 * t3_1;
    float dt[4];
    dt[0] = (((-0.5) * t2_1) + v) - 0.5;
    dt[1] = (1.5 * t2_1) - (2.0 * v);
    dt[2] = (((-1.5) * t2_1) + v) + 0.5;
    dt[3] = 0.5 * t2_1;
    int boundary = int((patch_bits >> uint(8)) & 15u);
    if ((boundary & 1) != int(0u))
    {
        t[2] -= t[0];
        t[1] += (2.0 * t[0]);
        t[0] = 0.0;
    }
    if ((boundary & 2) != int(0u))
    {
        s[1] -= s[3];
        s[2] += (2.0 * s[3]);
        s[3] = 0.0;
    }
    if ((boundary & 4) != int(0u))
    {
        t[1] -= t[3];
        t[2] += (2.0 * t[3]);
        t[3] = 0.0;
    }
    if ((boundary & 8) != int(0u))
    {
        s[2] -= s[0];
        s[1] += (2.0 * s[0]);
        s[0] = 0.0;
    }
    int boundary_1 = int((patch_bits >> uint(8)) & 15u);
    if ((boundary_1 & 1) != int(0u))
    {
        dt[2] -= dt[0];
        dt[1] += (2.0 * dt[0]);
        dt[0] = 0.0;
    }
    if ((boundary_1 & 2) != int(0u))
    {
        ds[1] -= ds[3];
        ds[2] += (2.0 * ds[3]);
        ds[3] = 0.0;
    }
    if ((boundary_1 & 4) != int(0u))
    {
        dt[1] -= dt[3];
        dt[2] += (2.0 * dt[3]);
        dt[3] = 0.0;
    }
    if ((boundary_1 & 8) != int(0u))
    {
        ds[2] -= ds[0];
        ds[1] += (2.0 * ds[0]);
        ds[0] = 0.0;
    }
    float weights[16];
    float weights_du[16];
    float weights_dv[16];
    for (int k = 0; k < 4; k++)
    {
        for (int l = 0; l < 4; l++)
        {
            weights[(4 * k) + l] = s[l] * t[k];
            weights_du[(4 * k) + l] = (ds[l] * t[k]) * d_scale;
            weights_dv[(4 * k) + l] = (s[l] * dt[k]) * d_scale;
        }
    }
    vec4 val = vec4(0.0);
    if (!(du3.x == 3.4028234663852885981170418348452e+38))
    {
        du3 = vec4(0.0);
    }
    if (!(dv3.x == 3.4028234663852885981170418348452e+38))
    {
        dv3 = vec4(0.0);
    }
    for (int i_1 = 0; i_1 < num_control; i_1++)
    {
        vec4 v_1 = float4_to_float3(push.data_ptr._attributes_float3.data[offset + indices[i_1]]);
        val += (v_1 * weights[i_1]);
        if (!(du3.x == 3.4028234663852885981170418348452e+38))
        {
            du3 += (v_1 * weights_du[i_1]);
        }
        if (!(dv3.x == 3.4028234663852885981170418348452e+38))
        {
            dv3 += (v_1 * weights_dv[i_1]);
        }
    }
    return val;
}

vec4 subd_triangle_attribute_float3(AttributeDescriptor desc, inout vec4 dx3, inout vec4 dy3)
{
    uint _4623;
    if (ioSD.prim != (-1))
    {
        _4623 = push.data_ptr._tri_patch.data[ioSD.prim];
    }
    else
    {
        _4623 = 4294967295u;
    }
    int patch_rsv = int(_4623);
    if ((desc.flags & 2u) != 0u)
    {
        uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
        vec2 uv[3];
        uv[0] = push.data_ptr._tri_patch_uv.data[tri_vindex.x];
        uv[1] = push.data_ptr._tri_patch_uv.data[tri_vindex.y];
        uv[2] = push.data_ptr._tri_patch_uv.data[tri_vindex.z];
        vec2 dpdu = uv[0] - uv[2];
        vec2 dpdv = uv[1] - uv[2];
        vec2 p = ((dpdu * ioSD.u) + (dpdv * ioSD.v)) + uv[2];
        int param = desc.offset;
        int param_1 = patch_rsv;
        float param_2 = p.x;
        float param_3 = p.y;
        int param_4 = 0;
        vec4 dads;
        vec4 param_5 = dads;
        vec4 dadt;
        vec4 param_6 = dadt;
        vec4 _4722 = patch_eval_float3(param, param_1, param_2, param_3, param_4, param_5, param_6);
        dads = param_5;
        dadt = param_6;
        vec4 a = _4722;
        bool _4728 = !(dx3.x == 3.4028234663852885981170418348452e+38);
        bool _4736;
        if (!_4728)
        {
            _4736 = !(dy3.x == 3.4028234663852885981170418348452e+38);
        }
        else
        {
            _4736 = _4728;
        }
        if (_4736)
        {
            float dsdu = dpdu.x;
            float dtdu = dpdu.y;
            float dsdv = dpdv.x;
            float dtdv = dpdv.y;
            if (!(dx3.x == 3.4028234663852885981170418348452e+38))
            {
                float dudx = ioSD.du.dx;
                float dvdx = ioSD.dv.dx;
                float dsdx = (dsdu * dudx) + (dsdv * dvdx);
                float dtdx = (dtdu * dudx) + (dtdv * dvdx);
                dx3 = (dads * dsdx) + (dadt * dtdx);
            }
            if (!(dy3.x == 3.4028234663852885981170418348452e+38))
            {
                float dudy = ioSD.du.dy;
                float dvdy = ioSD.dv.dy;
                float dsdy = (dsdu * dudy) + (dsdv * dvdy);
                float dtdy = (dtdu * dudy) + (dtdv * dvdy);
                dy3 = (dads * dsdy) + (dadt * dtdy);
            }
        }
        return a;
    }
    else
    {
        if (desc.element == 3u)
        {
            if (!(dx3.x == 3.4028234663852885981170418348452e+38))
            {
                dx3 = vec4(0.0);
            }
            if (!(dy3.x == 3.4028234663852885981170418348452e+38))
            {
                dy3 = vec4(0.0);
            }
            return float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + push.data_ptr._patches.data[patch_rsv + 4]]);
        }
        else
        {
            bool _4861 = desc.element == 4u;
            bool _4867;
            if (!_4861)
            {
                _4867 = desc.element == 5u;
            }
            else
            {
                _4867 = _4861;
            }
            if (_4867)
            {
                uvec4 tri_vindex_1 = push.data_ptr._tri_vindex.data[ioSD.prim];
                vec2 uv_1[3];
                uv_1[0] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.x];
                uv_1[1] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.y];
                uv_1[2] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.z];
                int param_7 = patch_rsv;
                uvec4 v = subd_triangle_patch_indices(param_7);
                vec4 f0 = float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + v.x]);
                vec4 f1 = float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + v.y]);
                vec4 f2 = float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + v.z]);
                vec4 f3 = float4_to_float3(push.data_ptr._attributes_float3.data[uint(desc.offset) + v.w]);
                if ((push.data_ptr._patches.data[patch_rsv + 5] & 65535u) != 4u)
                {
                    f1 = (f1 + f0) * 0.5;
                    f3 = (f3 + f0) * 0.5;
                }
                vec4 a_1 = mix(mix(f0, f1, vec4(uv_1[0].x)), mix(f3, f2, vec4(uv_1[0].x)), vec4(uv_1[0].y));
                vec4 b = mix(mix(f0, f1, vec4(uv_1[1].x)), mix(f3, f2, vec4(uv_1[1].x)), vec4(uv_1[1].y));
                vec4 c = mix(mix(f0, f1, vec4(uv_1[2].x)), mix(f3, f2, vec4(uv_1[2].x)), vec4(uv_1[2].y));
                if (!(dx3.x == 3.4028234663852885981170418348452e+38))
                {
                    dx3 = ((a_1 * ioSD.du.dx) + (b * ioSD.dv.dx)) - (c * (ioSD.du.dx + ioSD.dv.dx));
                }
                if (!(dy3.x == 3.4028234663852885981170418348452e+38))
                {
                    dy3 = ((a_1 * ioSD.du.dy) + (b * ioSD.dv.dy)) - (c * (ioSD.du.dy + ioSD.dv.dy));
                }
                return ((a_1 * ioSD.u) + (b * ioSD.v)) + (c * ((1.0 - ioSD.u) - ioSD.v));
            }
            else
            {
                if (desc.element == 6u)
                {
                    uvec4 tri_vindex_2 = push.data_ptr._tri_vindex.data[ioSD.prim];
                    vec2 uv_2[3];
                    uv_2[0] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.x];
                    uv_2[1] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.y];
                    uv_2[2] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.z];
                    uvec4 data;
                    data.x = push.data_ptr._patches.data[patch_rsv + 4];
                    data.y = push.data_ptr._patches.data[patch_rsv + 5];
                    data.z = push.data_ptr._patches.data[patch_rsv + 6];
                    data.w = push.data_ptr._patches.data[patch_rsv + 7];
                    int num_corners = int(data.y & 65535u);
                    int corners[4];
                    if (num_corners == 4)
                    {
                        corners[0] = int(data.z);
                        corners[1] = int(data.z) + 1;
                        corners[2] = int(data.z) + 2;
                        corners[3] = int(data.z) + 3;
                    }
                    else
                    {
                        int c_1 = int(data.y >> uint(16));
                        corners[0] = int(data.z) + c_1;
                        int param_8 = c_1 + 1;
                        int param_9 = num_corners;
                        corners[1] = int(data.z) + mod(param_8, param_9);
                        corners[2] = int(data.w);
                        int param_10 = c_1 - 1;
                        int param_11 = num_corners;
                        corners[3] = int(data.z) + mod(param_10, param_11);
                    }
                    vec4 f0_1 = float4_to_float3(push.data_ptr._attributes_float3.data[corners[0] + desc.offset]);
                    vec4 f1_1 = float4_to_float3(push.data_ptr._attributes_float3.data[corners[1] + desc.offset]);
                    vec4 f2_1 = float4_to_float3(push.data_ptr._attributes_float3.data[corners[2] + desc.offset]);
                    vec4 f3_1 = float4_to_float3(push.data_ptr._attributes_float3.data[corners[3] + desc.offset]);
                    if ((push.data_ptr._patches.data[patch_rsv + 5] & 65535u) != 4u)
                    {
                        f1_1 = (f1_1 + f0_1) * 0.5;
                        f3_1 = (f3_1 + f0_1) * 0.5;
                    }
                    vec4 a_2 = mix(mix(f0_1, f1_1, vec4(uv_2[0].x)), mix(f3_1, f2_1, vec4(uv_2[0].x)), vec4(uv_2[0].y));
                    vec4 b_1 = mix(mix(f0_1, f1_1, vec4(uv_2[1].x)), mix(f3_1, f2_1, vec4(uv_2[1].x)), vec4(uv_2[1].y));
                    vec4 c_2 = mix(mix(f0_1, f1_1, vec4(uv_2[2].x)), mix(f3_1, f2_1, vec4(uv_2[2].x)), vec4(uv_2[2].y));
                    if (!(dx3.x == 3.4028234663852885981170418348452e+38))
                    {
                        dx3 = ((a_2 * ioSD.du.dx) + (b_1 * ioSD.dv.dx)) - (c_2 * (ioSD.du.dx + ioSD.dv.dx));
                    }
                    if (!(dy3.x == 3.4028234663852885981170418348452e+38))
                    {
                        dy3 = ((a_2 * ioSD.du.dy) + (b_1 * ioSD.dv.dy)) - (c_2 * (ioSD.du.dy + ioSD.dv.dy));
                    }
                    return ((a_2 * ioSD.u) + (b_1 * ioSD.v)) + (c_2 * ((1.0 - ioSD.u) - ioSD.v));
                }
                else
                {
                    bool _5431 = desc.element == 1u;
                    bool _5437;
                    if (!_5431)
                    {
                        _5437 = desc.element == 2u;
                    }
                    else
                    {
                        _5437 = _5431;
                    }
                    if (_5437)
                    {
                        if (!(dx3.x == 3.4028234663852885981170418348452e+38))
                        {
                            dx3 = vec4(0.0);
                        }
                        if (!(dy3.x == 3.4028234663852885981170418348452e+38))
                        {
                            dy3 = vec4(0.0);
                        }
                        return float4_to_float3(push.data_ptr._attributes_float3.data[desc.offset]);
                    }
                    else
                    {
                        if (!(dx3.x == 3.4028234663852885981170418348452e+38))
                        {
                            dx3 = vec4(0.0);
                        }
                        if (!(dy3.x == 3.4028234663852885981170418348452e+38))
                        {
                            dy3 = vec4(0.0);
                        }
                        return vec4(0.0);
                    }
                }
            }
        }
    }
}

vec4 primitive_attribute_float3(AttributeDescriptor desc, inout vec4 dx3, inout vec4 dy3)
{
    if ((uint(ioSD.type) & 3u) != 0u)
    {
        uint _7495;
        if (ioSD.prim != (-1))
        {
            _7495 = push.data_ptr._tri_patch.data[ioSD.prim];
        }
        else
        {
            _7495 = 4294967295u;
        }
        if (_7495 == 4294967295u)
        {
            vec4 param = dx3;
            vec4 param_1 = dy3;
            vec4 _7515 = triangle_attribute_float3(desc, param, param_1);
            dx3 = param;
            dy3 = param_1;
            return _7515;
        }
        else
        {
            vec4 param_2 = dx3;
            vec4 param_3 = dy3;
            vec4 _7524 = subd_triangle_attribute_float3(desc, param_2, param_3);
            dx3 = param_2;
            dy3 = param_3;
            return _7524;
        }
    }
    else
    {
        if (!(dx3.x == 3.4028234663852885981170418348452e+38))
        {
            dx3 = vec4(0.0);
        }
        if (!(dy3.x == 3.4028234663852885981170418348452e+38))
        {
            dy3 = vec4(0.0);
        }
        return vec4(0.0);
    }
}

void svm_node_tangent()
{
    uint param = uint(ioSD.offset);
    AttributeDescriptor desc = find_attribute(param);
    vec4 attribute_value;
    if (uint(desc.offset) != 4294967295u)
    {
        if (desc.type == 1u)
        {
            vec2 param_1 = null_flt2;
            vec2 param_2 = null_flt2;
            vec2 _7684 = primitive_attribute_float2(desc, param_1, param_2);
            null_flt2 = param_1;
            null_flt2 = param_2;
            vec2 value = _7684;
            attribute_value.x = value.x;
            attribute_value.y = value.y;
            attribute_value.z = 0.0;
        }
        else
        {
            vec4 param_3 = null_flt3;
            vec4 param_4 = null_flt3;
            vec4 _7701 = primitive_attribute_float3(desc, param_3, param_4);
            null_flt3 = param_3;
            null_flt3 = param_4;
            attribute_value = _7701;
        }
        ioSD.call_type = 1u;
    }
    else
    {
        ioSD.call_type = 0u;
    }
    ioSD.N.x = attribute_value.x;
    ioSD.N.y = attribute_value.y;
    ioSD.N.z = attribute_value.z;
}

vec4 primitive_surface_attribute_float3(AttributeDescriptor desc, inout vec4 dx3, inout vec4 dy3)
{
    if ((uint(ioSD.type) & 3u) != 0u)
    {
        uint _7553;
        if (ioSD.prim != (-1))
        {
            _7553 = push.data_ptr._tri_patch.data[ioSD.prim];
        }
        else
        {
            _7553 = 4294967295u;
        }
        if (_7553 == 4294967295u)
        {
            vec4 param = dx3;
            vec4 param_1 = dy3;
            vec4 _7573 = triangle_attribute_float3(desc, param, param_1);
            dx3 = param;
            dy3 = param_1;
            return _7573;
        }
        else
        {
            vec4 param_2 = dx3;
            vec4 param_3 = dy3;
            vec4 _7582 = subd_triangle_attribute_float3(desc, param_2, param_3);
            dx3 = param_2;
            dy3 = param_3;
            return _7582;
        }
    }
    else
    {
        if (!(dx3.x == 3.4028234663852885981170418348452e+38))
        {
            dx3 = vec4(0.0);
        }
        if (!(dy3.x == 3.4028234663852885981170418348452e+38))
        {
            dy3 = vec4(0.0);
        }
        return vec4(0.0);
    }
}

Transform object_fetch_transform(int object, uint type)
{
    if (type == 1u)
    {
        Transform _397;
        _397.x = push.data_ptr._objects.data[object].itfm.x;
        _397.y = push.data_ptr._objects.data[object].itfm.y;
        _397.z = push.data_ptr._objects.data[object].itfm.z;
        Transform _396 = _397;
        return _396;
    }
    else
    {
        Transform _409;
        _409.x = push.data_ptr._objects.data[object].tfm.x;
        _409.y = push.data_ptr._objects.data[object].tfm.y;
        _409.z = push.data_ptr._objects.data[object].tfm.z;
        Transform _408 = _409;
        return _408;
    }
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
    int param = ioSD.object;
    uint param_1 = 1u;
    Transform tfm = object_fetch_transform(param, param_1);
    N = normalize(transform_direction_transposed(tfm, N));
}

void primitive_tangent()
{
    uint param = 7u;
    AttributeDescriptor desc = find_attribute(param);
    if (uint(desc.offset) != 4294967295u)
    {
        vec4 null1 = vec4(3.4028234663852885981170418348452e+38);
        vec4 null2 = vec4(3.4028234663852885981170418348452e+38);
        vec4 param_1 = null1;
        vec4 param_2 = null2;
        vec4 _7618 = primitive_surface_attribute_float3(desc, param_1, param_2);
        null1 = param_1;
        null2 = param_2;
        vec4 data = _7618;
        data = vec4(-(data.y - 0.5), data.x - 0.5, 0.0, 0.0);
        vec4 param_3 = data;
        object_normal_transform(param_3);
        data = param_3;
        vec3 ret = cross(ioSD.N.xyz, normalize(cross(data.xyz, ioSD.N.xyz)));
        ioSD.N.x = ret.x;
        ioSD.N.y = ret.y;
        ioSD.N.z = ret.z;
        ioSD.call_type = 1u;
    }
    else
    {
        ioSD.call_type = 0u;
    }
}

AttributeDescriptor svm_node_attr_init(out uint type, out uint out_offset)
{
    out_offset = ioSD.node.z;
    type = ioSD.node.w;
    AttributeDescriptor desc;
    if (ioSD.object != (-1))
    {
        uint param = ioSD.node.y;
        desc = find_attribute(param);
        if (uint(desc.offset) == 4294967295u)
        {
            desc = attribute_not_found();
            desc.offset = 0;
            desc.type = ioSD.node.w;
        }
    }
    else
    {
        desc = attribute_not_found();
        desc.offset = 0;
        desc.type = ioSD.node.w;
    }
    return desc;
}

float triangle_attribute_float(AttributeDescriptor desc, inout float dx, inout float dy)
{
    if (desc.element == 3u)
    {
        if (!(dx == 3.4028234663852885981170418348452e+38))
        {
            dx = 0.0;
        }
        if (!(dy == 3.4028234663852885981170418348452e+38))
        {
            dy = 0.0;
        }
        return push.data_ptr._attributes_float.data[desc.offset + ioSD.prim];
    }
    else
    {
        bool _6232 = desc.element == 4u;
        bool _6238;
        if (!_6232)
        {
            _6238 = desc.element == 5u;
        }
        else
        {
            _6238 = _6232;
        }
        if (_6238)
        {
            uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
            float f0 = push.data_ptr._attributes_float.data[uint(desc.offset) + tri_vindex.x];
            float f1 = push.data_ptr._attributes_float.data[uint(desc.offset) + tri_vindex.y];
            float f2 = push.data_ptr._attributes_float.data[uint(desc.offset) + tri_vindex.z];
            if (!(dx == 3.4028234663852885981170418348452e+38))
            {
                dx = ((ioSD.du.dx * f0) + (ioSD.dv.dx * f1)) - ((ioSD.du.dx + ioSD.dv.dx) * f2);
            }
            if (!(dy == 3.4028234663852885981170418348452e+38))
            {
                dy = ((ioSD.du.dy * f0) + (ioSD.dv.dy * f1)) - ((ioSD.du.dy + ioSD.dv.dy) * f2);
            }
            return ((ioSD.u * f0) + (ioSD.v * f1)) + (((1.0 - ioSD.u) - ioSD.v) * f2);
        }
        else
        {
            if (desc.element == 6u)
            {
                int tri = desc.offset + (ioSD.prim * 3);
                float f0_1 = push.data_ptr._attributes_float.data[tri + 0];
                float f1_1 = push.data_ptr._attributes_float.data[tri + 1];
                float f2_1 = push.data_ptr._attributes_float.data[tri + 2];
                if (!(dx == 3.4028234663852885981170418348452e+38))
                {
                    dx = ((ioSD.du.dx * f0_1) + (ioSD.dv.dx * f1_1)) - ((ioSD.du.dx + ioSD.dv.dx) * f2_1);
                }
                if (!(dy == 3.4028234663852885981170418348452e+38))
                {
                    dy = ((ioSD.du.dy * f0_1) + (ioSD.dv.dy * f1_1)) - ((ioSD.du.dy + ioSD.dv.dy) * f2_1);
                }
                return ((ioSD.u * f0_1) + (ioSD.v * f1_1)) + (((1.0 - ioSD.u) - ioSD.v) * f2_1);
            }
            else
            {
                bool _6452 = desc.element == 1u;
                bool _6458;
                if (!_6452)
                {
                    _6458 = desc.element == 2u;
                }
                else
                {
                    _6458 = _6452;
                }
                if (_6458)
                {
                    if (!(dx == 3.4028234663852885981170418348452e+38))
                    {
                        dx = 0.0;
                    }
                    if (!(dy == 3.4028234663852885981170418348452e+38))
                    {
                        dy = 0.0;
                    }
                    return push.data_ptr._attributes_float.data[desc.offset];
                }
                else
                {
                    if (!(dx == 3.4028234663852885981170418348452e+38))
                    {
                        dx = 0.0;
                    }
                    if (!(dy == 3.4028234663852885981170418348452e+38))
                    {
                        dy = 0.0;
                    }
                    return 0.0;
                }
            }
        }
    }
}

float patch_eval_float(int offset, int patch_rsv, inout float u, inout float v, int channel, inout float du, inout float dv)
{
    int param = ioSD.object;
    int param_1 = patch_rsv;
    float param_2 = u;
    float param_3 = v;
    PatchHandle _626 = patch_map_find_patch(param, param_1, param_2, param_3);
    PatchHandle handle = _626;
    if (!(handle.array_index >= 0))
    {
        // unimplemented ext op 12
    }
    int index_base = int(push.data_ptr._patches.data[handle.array_index + 2] + uint(handle.vert_index));
    int indices[16];
    for (int i = 0; i < 16; i++)
    {
        indices[i] = int(push.data_ptr._patches.data[index_base + i]);
    }
    int num_control = 16;
    uint patch_bits = push.data_ptr._patches.data[handle.patch_index + 1];
    float d_scale = float(1 << int(patch_bits & 15u));
    bool non_quad_root = ((patch_bits >> uint(4)) & 1u) != 0u;
    if (non_quad_root)
    {
        d_scale *= 0.5;
    }
    bool non_quad_root_1 = ((patch_bits >> uint(4)) & 1u) != 0u;
    int depth = int(patch_bits & 15u);
    float frac;
    if (non_quad_root_1)
    {
        frac = 1.0 / float(1 << (depth - 1));
    }
    else
    {
        frac = 1.0 / float(1 << depth);
    }
    int iu = int((patch_bits >> uint(22)) & 1023u);
    int iv = int((patch_bits >> uint(12)) & 1023u);
    float pu = float(iu) * frac;
    float pv = float(iv) * frac;
    u = (u - pu) / frac;
    v = (v - pv) / frac;
    float inv_6 = 0.16666667163372039794921875;
    float t2 = u * u;
    float t3 = u * t2;
    float s[4];
    s[0] = inv_6 * ((1.0 - (3.0 * (u - t2))) - t3);
    s[1] = inv_6 * ((4.0 - (6.0 * t2)) + (3.0 * t3));
    s[2] = inv_6 * (1.0 + (3.0 * ((u + t2) - t3)));
    s[3] = inv_6 * t3;
    float ds[4];
    ds[0] = (((-0.5) * t2) + u) - 0.5;
    ds[1] = (1.5 * t2) - (2.0 * u);
    ds[2] = (((-1.5) * t2) + u) + 0.5;
    ds[3] = 0.5 * t2;
    float inv_6_1 = 0.16666667163372039794921875;
    float t2_1 = v * v;
    float t3_1 = v * t2_1;
    float t[4];
    t[0] = inv_6_1 * ((1.0 - (3.0 * (v - t2_1))) - t3_1);
    t[1] = inv_6_1 * ((4.0 - (6.0 * t2_1)) + (3.0 * t3_1));
    t[2] = inv_6_1 * (1.0 + (3.0 * ((v + t2_1) - t3_1)));
    t[3] = inv_6_1 * t3_1;
    float dt[4];
    dt[0] = (((-0.5) * t2_1) + v) - 0.5;
    dt[1] = (1.5 * t2_1) - (2.0 * v);
    dt[2] = (((-1.5) * t2_1) + v) + 0.5;
    dt[3] = 0.5 * t2_1;
    int boundary = int((patch_bits >> uint(8)) & 15u);
    if ((boundary & 1) != int(0u))
    {
        t[2] -= t[0];
        t[1] += (2.0 * t[0]);
        t[0] = 0.0;
    }
    if ((boundary & 2) != int(0u))
    {
        s[1] -= s[3];
        s[2] += (2.0 * s[3]);
        s[3] = 0.0;
    }
    if ((boundary & 4) != int(0u))
    {
        t[1] -= t[3];
        t[2] += (2.0 * t[3]);
        t[3] = 0.0;
    }
    if ((boundary & 8) != int(0u))
    {
        s[2] -= s[0];
        s[1] += (2.0 * s[0]);
        s[0] = 0.0;
    }
    int boundary_1 = int((patch_bits >> uint(8)) & 15u);
    if ((boundary_1 & 1) != int(0u))
    {
        dt[2] -= dt[0];
        dt[1] += (2.0 * dt[0]);
        dt[0] = 0.0;
    }
    if ((boundary_1 & 2) != int(0u))
    {
        ds[1] -= ds[3];
        ds[2] += (2.0 * ds[3]);
        ds[3] = 0.0;
    }
    if ((boundary_1 & 4) != int(0u))
    {
        dt[1] -= dt[3];
        dt[2] += (2.0 * dt[3]);
        dt[3] = 0.0;
    }
    if ((boundary_1 & 8) != int(0u))
    {
        ds[2] -= ds[0];
        ds[1] += (2.0 * ds[0]);
        ds[0] = 0.0;
    }
    float weights[16];
    float weights_du[16];
    float weights_dv[16];
    for (int k = 0; k < 4; k++)
    {
        for (int l = 0; l < 4; l++)
        {
            weights[(4 * k) + l] = s[l] * t[k];
            weights_du[(4 * k) + l] = (ds[l] * t[k]) * d_scale;
            weights_dv[(4 * k) + l] = (s[l] * dt[k]) * d_scale;
        }
    }
    float val = 0.0;
    if (!(du == 3.4028234663852885981170418348452e+38))
    {
        du = 0.0;
    }
    if (!(dv == 3.4028234663852885981170418348452e+38))
    {
        dv = 0.0;
    }
    for (int i_1 = 0; i_1 < num_control; i_1++)
    {
        float v_1 = push.data_ptr._attributes_float.data[offset + indices[i_1]];
        val += (v_1 * weights[i_1]);
        if (!(du == 3.4028234663852885981170418348452e+38))
        {
            du += (v_1 * weights_du[i_1]);
        }
        if (!(dv == 3.4028234663852885981170418348452e+38))
        {
            dv += (v_1 * weights_dv[i_1]);
        }
    }
    return val;
}

float subd_triangle_attribute_float(AttributeDescriptor desc, inout float dx, inout float dy)
{
    uint _2947;
    if (ioSD.prim != (-1))
    {
        _2947 = push.data_ptr._tri_patch.data[ioSD.prim];
    }
    else
    {
        _2947 = 4294967295u;
    }
    int patch_rsv = int(_2947);
    if ((desc.flags & 2u) != 0u)
    {
        uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
        vec2 uv[3];
        uv[0] = push.data_ptr._tri_patch_uv.data[tri_vindex.x];
        uv[1] = push.data_ptr._tri_patch_uv.data[tri_vindex.y];
        uv[2] = push.data_ptr._tri_patch_uv.data[tri_vindex.z];
        vec2 dpdu = uv[0] - uv[2];
        vec2 dpdv = uv[1] - uv[2];
        vec2 p = ((dpdu * ioSD.u) + (dpdv * ioSD.v)) + uv[2];
        int param = desc.offset;
        int param_1 = patch_rsv;
        float param_2 = p.x;
        float param_3 = p.y;
        int param_4 = 0;
        float dads;
        float param_5 = dads;
        float dadt;
        float param_6 = dadt;
        float _3056 = patch_eval_float(param, param_1, param_2, param_3, param_4, param_5, param_6);
        dads = param_5;
        dadt = param_6;
        float a = _3056;
        bool _3061 = !(dx == 3.4028234663852885981170418348452e+38);
        bool _3068;
        if (!_3061)
        {
            _3068 = !(dy == 3.4028234663852885981170418348452e+38);
        }
        else
        {
            _3068 = _3061;
        }
        if (_3068)
        {
            float dsdu = dpdu.x;
            float dtdu = dpdu.y;
            float dsdv = dpdv.x;
            float dtdv = dpdv.y;
            if (!(dx == 3.4028234663852885981170418348452e+38))
            {
                float dudx = ioSD.du.dx;
                float dvdx = ioSD.dv.dx;
                float dsdx = (dsdu * dudx) + (dsdv * dvdx);
                float dtdx = (dtdu * dudx) + (dtdv * dvdx);
                dx = (dads * dsdx) + (dadt * dtdx);
            }
            if (!(dy == 3.4028234663852885981170418348452e+38))
            {
                float dudy = ioSD.du.dy;
                float dvdy = ioSD.dv.dy;
                float dsdy = (dsdu * dudy) + (dsdv * dvdy);
                float dtdy = (dtdu * dudy) + (dtdv * dvdy);
                dy = (dads * dsdy) + (dadt * dtdy);
            }
        }
        return a;
    }
    else
    {
        if (desc.element == 3u)
        {
            if (!(dx == 3.4028234663852885981170418348452e+38))
            {
                dx = 0.0;
            }
            if (!(dy == 3.4028234663852885981170418348452e+38))
            {
                dy = 0.0;
            }
            return push.data_ptr._attributes_float.data[uint(desc.offset) + push.data_ptr._patches.data[patch_rsv + 4]];
        }
        else
        {
            bool _3188 = desc.element == 4u;
            bool _3194;
            if (!_3188)
            {
                _3194 = desc.element == 5u;
            }
            else
            {
                _3194 = _3188;
            }
            if (_3194)
            {
                uvec4 tri_vindex_1 = push.data_ptr._tri_vindex.data[ioSD.prim];
                vec2 uv_1[3];
                uv_1[0] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.x];
                uv_1[1] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.y];
                uv_1[2] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.z];
                int param_7 = patch_rsv;
                uvec4 v = subd_triangle_patch_indices(param_7);
                float f0 = push.data_ptr._attributes_float.data[uint(desc.offset) + v.x];
                float f1 = push.data_ptr._attributes_float.data[uint(desc.offset) + v.y];
                float f2 = push.data_ptr._attributes_float.data[uint(desc.offset) + v.z];
                float f3 = push.data_ptr._attributes_float.data[uint(desc.offset) + v.w];
                if ((push.data_ptr._patches.data[patch_rsv + 5] & 65535u) != 4u)
                {
                    f1 = (f1 + f0) * 0.5;
                    f3 = (f3 + f0) * 0.5;
                }
                float a_1 = mix(mix(f0, f1, uv_1[0].x), mix(f3, f2, uv_1[0].x), uv_1[0].y);
                float b = mix(mix(f0, f1, uv_1[1].x), mix(f3, f2, uv_1[1].x), uv_1[1].y);
                float c = mix(mix(f0, f1, uv_1[2].x), mix(f3, f2, uv_1[2].x), uv_1[2].y);
                if (!(dx == 3.4028234663852885981170418348452e+38))
                {
                    dx = ((ioSD.du.dx * a_1) + (ioSD.dv.dx * b)) - ((ioSD.du.dx + ioSD.dv.dx) * c);
                }
                if (!(dy == 3.4028234663852885981170418348452e+38))
                {
                    dy = ((ioSD.du.dy * a_1) + (ioSD.dv.dy * b)) - ((ioSD.du.dy + ioSD.dv.dy) * c);
                }
                return ((ioSD.u * a_1) + (ioSD.v * b)) + (((1.0 - ioSD.u) - ioSD.v) * c);
            }
            else
            {
                if (desc.element == 6u)
                {
                    uvec4 tri_vindex_2 = push.data_ptr._tri_vindex.data[ioSD.prim];
                    vec2 uv_2[3];
                    uv_2[0] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.x];
                    uv_2[1] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.y];
                    uv_2[2] = push.data_ptr._tri_patch_uv.data[tri_vindex_2.z];
                    uvec4 data;
                    data.x = push.data_ptr._patches.data[patch_rsv + 4];
                    data.y = push.data_ptr._patches.data[patch_rsv + 5];
                    data.z = push.data_ptr._patches.data[patch_rsv + 6];
                    data.w = push.data_ptr._patches.data[patch_rsv + 7];
                    int num_corners = int(data.y & 65535u);
                    int corners[4];
                    if (num_corners == 4)
                    {
                        corners[0] = int(data.z);
                        corners[1] = int(data.z) + 1;
                        corners[2] = int(data.z) + 2;
                        corners[3] = int(data.z) + 3;
                    }
                    else
                    {
                        int c_1 = int(data.y >> uint(16));
                        corners[0] = int(data.z) + c_1;
                        int param_8 = c_1 + 1;
                        int param_9 = num_corners;
                        corners[1] = int(data.z) + mod(param_8, param_9);
                        corners[2] = int(data.w);
                        int param_10 = c_1 - 1;
                        int param_11 = num_corners;
                        corners[3] = int(data.z) + mod(param_10, param_11);
                    }
                    float f0_1 = push.data_ptr._attributes_float.data[corners[0] + desc.offset];
                    float f1_1 = push.data_ptr._attributes_float.data[corners[1] + desc.offset];
                    float f2_1 = push.data_ptr._attributes_float.data[corners[2] + desc.offset];
                    float f3_1 = push.data_ptr._attributes_float.data[corners[3] + desc.offset];
                    if ((push.data_ptr._patches.data[patch_rsv + 5] & 65535u) != 4u)
                    {
                        f1_1 = (f1_1 + f0_1) * 0.5;
                        f3_1 = (f3_1 + f0_1) * 0.5;
                    }
                    float a_2 = mix(mix(f0_1, f1_1, uv_2[0].x), mix(f3_1, f2_1, uv_2[0].x), uv_2[0].y);
                    float b_1 = mix(mix(f0_1, f1_1, uv_2[1].x), mix(f3_1, f2_1, uv_2[1].x), uv_2[1].y);
                    float c_2 = mix(mix(f0_1, f1_1, uv_2[2].x), mix(f3_1, f2_1, uv_2[2].x), uv_2[2].y);
                    if (!(dx == 3.4028234663852885981170418348452e+38))
                    {
                        dx = ((ioSD.du.dx * a_2) + (ioSD.dv.dx * b_1)) - ((ioSD.du.dx + ioSD.dv.dx) * c_2);
                    }
                    if (!(dy == 3.4028234663852885981170418348452e+38))
                    {
                        dy = ((ioSD.du.dy * a_2) + (ioSD.dv.dy * b_1)) - ((ioSD.du.dy + ioSD.dv.dy) * c_2);
                    }
                    return ((ioSD.u * a_2) + (ioSD.v * b_1)) + (((1.0 - ioSD.u) - ioSD.v) * c_2);
                }
                else
                {
                    bool _3732 = desc.element == 1u;
                    bool _3738;
                    if (!_3732)
                    {
                        _3738 = desc.element == 2u;
                    }
                    else
                    {
                        _3738 = _3732;
                    }
                    if (_3738)
                    {
                        if (!(dx == 3.4028234663852885981170418348452e+38))
                        {
                            dx = 0.0;
                        }
                        if (!(dy == 3.4028234663852885981170418348452e+38))
                        {
                            dy = 0.0;
                        }
                        return push.data_ptr._attributes_float.data[desc.offset];
                    }
                    else
                    {
                        if (!(dx == 3.4028234663852885981170418348452e+38))
                        {
                            dx = 0.0;
                        }
                        if (!(dy == 3.4028234663852885981170418348452e+38))
                        {
                            dy = 0.0;
                        }
                        return 0.0;
                    }
                }
            }
        }
    }
}

float primitive_attribute_float(AttributeDescriptor desc, inout float dx, inout float dy)
{
    if ((uint(ioSD.type) & 3u) != 0u)
    {
        uint _7381;
        if (ioSD.prim != (-1))
        {
            _7381 = push.data_ptr._tri_patch.data[ioSD.prim];
        }
        else
        {
            _7381 = 4294967295u;
        }
        if (_7381 == 4294967295u)
        {
            float param = dx;
            float param_1 = dy;
            float _7401 = triangle_attribute_float(desc, param, param_1);
            dx = param;
            dy = param_1;
            return _7401;
        }
        else
        {
            float param_2 = dx;
            float param_3 = dy;
            float _7410 = subd_triangle_attribute_float(desc, param_2, param_3);
            dx = param_2;
            dy = param_3;
            return _7410;
        }
    }
    else
    {
        if (!(dx == 3.4028234663852885981170418348452e+38))
        {
            dx = 0.0;
        }
        if (!(dy == 3.4028234663852885981170418348452e+38))
        {
            dy = 0.0;
        }
        return 0.0;
    }
}

vec4 color_uchar4_to_float4(u8vec4 c)
{
    return vec4(float(c.x) * 0.0039215688593685626983642578125, float(c.y) * 0.0039215688593685626983642578125, float(c.z) * 0.0039215688593685626983642578125, float(c.w) * 0.0039215688593685626983642578125);
}

vec4 triangle_attribute_float4(AttributeDescriptor desc, inout vec4 dx4, inout vec4 dy4)
{
    bool _7105 = desc.element == 7u;
    bool _7111;
    if (!_7105)
    {
        _7111 = desc.element == 4u;
    }
    else
    {
        _7111 = _7105;
    }
    if (_7111)
    {
        vec4 f0;
        vec4 f1;
        vec4 f2;
        if (desc.element == 7u)
        {
            int tri = desc.offset + (ioSD.prim * 3);
            u8vec4 param = push.data_ptr._attributes_uchar4.data[tri + 0];
            f0 = color_uchar4_to_float4(param);
            u8vec4 param_1 = push.data_ptr._attributes_uchar4.data[tri + 1];
            f1 = color_uchar4_to_float4(param_1);
            u8vec4 param_2 = push.data_ptr._attributes_uchar4.data[tri + 2];
            f2 = color_uchar4_to_float4(param_2);
        }
        else
        {
            uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
            f0 = push.data_ptr._attributes_float3.data[uint(desc.offset) + tri_vindex.x];
            f1 = push.data_ptr._attributes_float3.data[uint(desc.offset) + tri_vindex.y];
            f2 = push.data_ptr._attributes_float3.data[uint(desc.offset) + tri_vindex.z];
        }
        if (!(dx4.x == 3.4028234663852885981170418348452e+38))
        {
            dx4 = ((f0 * ioSD.du.dx) + (f1 * ioSD.dv.dx)) - (f2 * (ioSD.du.dx + ioSD.dv.dx));
        }
        if (!(dy4.x == 3.4028234663852885981170418348452e+38))
        {
            dy4 = ((f0 * ioSD.du.dy) + (f1 * ioSD.dv.dy)) - (f2 * (ioSD.du.dy + ioSD.dv.dy));
        }
        return ((f0 * ioSD.u) + (f1 * ioSD.v)) + (f2 * ((1.0 - ioSD.u) - ioSD.v));
    }
    else
    {
        bool _7267 = desc.element == 1u;
        bool _7273;
        if (!_7267)
        {
            _7273 = desc.element == 2u;
        }
        else
        {
            _7273 = _7267;
        }
        if (_7273)
        {
            if (!(dx4.x == 3.4028234663852885981170418348452e+38))
            {
                dx4 = vec4(0.0);
            }
            if (!(dy4.x == 3.4028234663852885981170418348452e+38))
            {
                dy4 = vec4(0.0);
            }
            u8vec4 param_3 = push.data_ptr._attributes_uchar4.data[desc.offset];
            return color_uchar4_to_float4(param_3);
        }
        else
        {
            if (!(dx4.x == 3.4028234663852885981170418348452e+38))
            {
                dx4 = vec4(0.0);
            }
            if (!(dy4.x == 3.4028234663852885981170418348452e+38))
            {
                dy4 = vec4(0.0);
            }
            return vec4(0.0);
        }
    }
}

vec4 patch_eval_uchar4(int offset, int patch_rsv, inout float u, inout float v, int channel, inout vec4 du4, inout vec4 dv4)
{
    int param = ioSD.object;
    int param_1 = patch_rsv;
    float param_2 = u;
    float param_3 = v;
    PatchHandle _2344 = patch_map_find_patch(param, param_1, param_2, param_3);
    PatchHandle handle = _2344;
    if (!(handle.array_index >= 0))
    {
        // unimplemented ext op 12
    }
    int index_base = int(push.data_ptr._patches.data[handle.array_index + 2] + uint(handle.vert_index));
    int indices[16];
    for (int i = 0; i < 16; i++)
    {
        indices[i] = int(push.data_ptr._patches.data[index_base + i]);
    }
    int num_control = 16;
    uint patch_bits = push.data_ptr._patches.data[handle.patch_index + 1];
    float d_scale = float(1 << int(patch_bits & 15u));
    bool non_quad_root = ((patch_bits >> uint(4)) & 1u) != 0u;
    if (non_quad_root)
    {
        d_scale *= 0.5;
    }
    bool non_quad_root_1 = ((patch_bits >> uint(4)) & 1u) != 0u;
    int depth = int(patch_bits & 15u);
    float frac;
    if (non_quad_root_1)
    {
        frac = 1.0 / float(1 << (depth - 1));
    }
    else
    {
        frac = 1.0 / float(1 << depth);
    }
    int iu = int((patch_bits >> uint(22)) & 1023u);
    int iv = int((patch_bits >> uint(12)) & 1023u);
    float pu = float(iu) * frac;
    float pv = float(iv) * frac;
    u = (u - pu) / frac;
    v = (v - pv) / frac;
    float inv_6 = 0.16666667163372039794921875;
    float t2 = u * u;
    float t3 = u * t2;
    float s[4];
    s[0] = inv_6 * ((1.0 - (3.0 * (u - t2))) - t3);
    s[1] = inv_6 * ((4.0 - (6.0 * t2)) + (3.0 * t3));
    s[2] = inv_6 * (1.0 + (3.0 * ((u + t2) - t3)));
    s[3] = inv_6 * t3;
    float ds[4];
    ds[0] = (((-0.5) * t2) + u) - 0.5;
    ds[1] = (1.5 * t2) - (2.0 * u);
    ds[2] = (((-1.5) * t2) + u) + 0.5;
    ds[3] = 0.5 * t2;
    float inv_6_1 = 0.16666667163372039794921875;
    float t2_1 = v * v;
    float t3_1 = v * t2_1;
    float t[4];
    t[0] = inv_6_1 * ((1.0 - (3.0 * (v - t2_1))) - t3_1);
    t[1] = inv_6_1 * ((4.0 - (6.0 * t2_1)) + (3.0 * t3_1));
    t[2] = inv_6_1 * (1.0 + (3.0 * ((v + t2_1) - t3_1)));
    t[3] = inv_6_1 * t3_1;
    float dt[4];
    dt[0] = (((-0.5) * t2_1) + v) - 0.5;
    dt[1] = (1.5 * t2_1) - (2.0 * v);
    dt[2] = (((-1.5) * t2_1) + v) + 0.5;
    dt[3] = 0.5 * t2_1;
    int boundary = int((patch_bits >> uint(8)) & 15u);
    if ((boundary & 1) != int(0u))
    {
        t[2] -= t[0];
        t[1] += (2.0 * t[0]);
        t[0] = 0.0;
    }
    if ((boundary & 2) != int(0u))
    {
        s[1] -= s[3];
        s[2] += (2.0 * s[3]);
        s[3] = 0.0;
    }
    if ((boundary & 4) != int(0u))
    {
        t[1] -= t[3];
        t[2] += (2.0 * t[3]);
        t[3] = 0.0;
    }
    if ((boundary & 8) != int(0u))
    {
        s[2] -= s[0];
        s[1] += (2.0 * s[0]);
        s[0] = 0.0;
    }
    int boundary_1 = int((patch_bits >> uint(8)) & 15u);
    if ((boundary_1 & 1) != int(0u))
    {
        dt[2] -= dt[0];
        dt[1] += (2.0 * dt[0]);
        dt[0] = 0.0;
    }
    if ((boundary_1 & 2) != int(0u))
    {
        ds[1] -= ds[3];
        ds[2] += (2.0 * ds[3]);
        ds[3] = 0.0;
    }
    if ((boundary_1 & 4) != int(0u))
    {
        dt[1] -= dt[3];
        dt[2] += (2.0 * dt[3]);
        dt[3] = 0.0;
    }
    if ((boundary_1 & 8) != int(0u))
    {
        ds[2] -= ds[0];
        ds[1] += (2.0 * ds[0]);
        ds[0] = 0.0;
    }
    float weights[16];
    float weights_du[16];
    float weights_dv[16];
    for (int k = 0; k < 4; k++)
    {
        for (int l = 0; l < 4; l++)
        {
            weights[(4 * k) + l] = s[l] * t[k];
            weights_du[(4 * k) + l] = (ds[l] * t[k]) * d_scale;
            weights_dv[(4 * k) + l] = (s[l] * dt[k]) * d_scale;
        }
    }
    vec4 val = vec4(0.0);
    if (!(du4.x == 3.4028234663852885981170418348452e+38))
    {
        du4 = vec4(0.0);
    }
    if (!(dv4.x == 3.4028234663852885981170418348452e+38))
    {
        dv4 = vec4(0.0);
    }
    for (int i_1 = 0; i_1 < num_control; i_1++)
    {
        u8vec4 param_4 = push.data_ptr._attributes_uchar4.data[offset + indices[i_1]];
        vec4 v_1 = color_uchar4_to_float4(param_4);
        val += (v_1 * weights[i_1]);
        if (!(du4.x == 3.4028234663852885981170418348452e+38))
        {
            du4 += (v_1 * weights_du[i_1]);
        }
        if (!(dv4.x == 3.4028234663852885981170418348452e+38))
        {
            dv4 += (v_1 * weights_dv[i_1]);
        }
    }
    return val;
}

vec4 subd_triangle_attribute_float4(AttributeDescriptor desc, inout vec4 dx4, inout vec4 dy4)
{
    uint _5480;
    if (ioSD.prim != (-1))
    {
        _5480 = push.data_ptr._tri_patch.data[ioSD.prim];
    }
    else
    {
        _5480 = 4294967295u;
    }
    int patch_rsv = int(_5480);
    if ((desc.flags & 2u) != 0u)
    {
        uvec4 tri_vindex = push.data_ptr._tri_vindex.data[ioSD.prim];
        vec2 uv[3];
        uv[0] = push.data_ptr._tri_patch_uv.data[tri_vindex.x];
        uv[1] = push.data_ptr._tri_patch_uv.data[tri_vindex.y];
        uv[2] = push.data_ptr._tri_patch_uv.data[tri_vindex.z];
        vec2 dpdu = uv[0] - uv[2];
        vec2 dpdv = uv[1] - uv[2];
        vec2 p = ((dpdu * ioSD.u) + (dpdv * ioSD.v)) + uv[2];
        int param = desc.offset;
        int param_1 = patch_rsv;
        float param_2 = p.x;
        float param_3 = p.y;
        int param_4 = 0;
        vec4 dads;
        vec4 param_5 = dads;
        vec4 dadt;
        vec4 param_6 = dadt;
        vec4 _5579 = patch_eval_uchar4(param, param_1, param_2, param_3, param_4, param_5, param_6);
        dads = param_5;
        dadt = param_6;
        vec4 a = _5579;
        bool _5585 = !(dx4.x == 3.4028234663852885981170418348452e+38);
        bool _5593;
        if (!_5585)
        {
            _5593 = !(dy4.x == 3.4028234663852885981170418348452e+38);
        }
        else
        {
            _5593 = _5585;
        }
        if (_5593)
        {
            float dsdu = dpdu.x;
            float dtdu = dpdu.y;
            float dsdv = dpdv.x;
            float dtdv = dpdv.y;
            if (!(dx4.x == 3.4028234663852885981170418348452e+38))
            {
                float dudx = ioSD.du.dx;
                float dvdx = ioSD.dv.dx;
                float dsdx = (dsdu * dudx) + (dsdv * dvdx);
                float dtdx = (dtdu * dudx) + (dtdv * dvdx);
                dx4 = (dads * dsdx) + (dadt * dtdx);
            }
            if (!(dy4.x == 3.4028234663852885981170418348452e+38))
            {
                float dudy = ioSD.du.dy;
                float dvdy = ioSD.dv.dy;
                float dsdy = (dsdu * dudy) + (dsdv * dvdy);
                float dtdy = (dtdu * dudy) + (dtdv * dvdy);
                dy4 = (dads * dsdy) + (dadt * dtdy);
            }
        }
        return a;
    }
    else
    {
        if (desc.element == 7u)
        {
            uvec4 tri_vindex_1 = push.data_ptr._tri_vindex.data[ioSD.prim];
            vec2 uv_1[3];
            uv_1[0] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.x];
            uv_1[1] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.y];
            uv_1[2] = push.data_ptr._tri_patch_uv.data[tri_vindex_1.z];
            uvec4 data;
            data.x = push.data_ptr._patches.data[patch_rsv + 4];
            data.y = push.data_ptr._patches.data[patch_rsv + 5];
            data.z = push.data_ptr._patches.data[patch_rsv + 6];
            data.w = push.data_ptr._patches.data[patch_rsv + 7];
            int num_corners = int(data.y & 65535u);
            int corners[4];
            if (num_corners == 4)
            {
                corners[0] = int(data.z);
                corners[1] = int(data.z) + 1;
                corners[2] = int(data.z) + 2;
                corners[3] = int(data.z) + 3;
            }
            else
            {
                int c = int(data.y >> uint(16));
                corners[0] = int(data.z) + c;
                int param_7 = c + 1;
                int param_8 = num_corners;
                corners[1] = int(data.z) + mod(param_7, param_8);
                corners[2] = int(data.w);
                int param_9 = c - 1;
                int param_10 = num_corners;
                corners[3] = int(data.z) + mod(param_9, param_10);
            }
            u8vec4 param_11 = push.data_ptr._attributes_uchar4.data[corners[0] + desc.offset];
            vec4 f0 = color_uchar4_to_float4(param_11);
            u8vec4 param_12 = push.data_ptr._attributes_uchar4.data[corners[1] + desc.offset];
            vec4 f1 = color_uchar4_to_float4(param_12);
            u8vec4 param_13 = push.data_ptr._attributes_uchar4.data[corners[2] + desc.offset];
            vec4 f2 = color_uchar4_to_float4(param_13);
            u8vec4 param_14 = push.data_ptr._attributes_uchar4.data[corners[3] + desc.offset];
            vec4 f3 = color_uchar4_to_float4(param_14);
            if ((push.data_ptr._patches.data[patch_rsv + 5] & 65535u) != 4u)
            {
                f1 = (f1 + f0) * 0.5;
                f3 = (f3 + f0) * 0.5;
            }
            vec4 a_1 = mix(mix(f0, f1, vec4(uv_1[0].x)), mix(f3, f2, vec4(uv_1[0].x)), vec4(uv_1[0].y));
            vec4 b = mix(mix(f0, f1, vec4(uv_1[1].x)), mix(f3, f2, vec4(uv_1[1].x)), vec4(uv_1[1].y));
            vec4 c_1 = mix(mix(f0, f1, vec4(uv_1[2].x)), mix(f3, f2, vec4(uv_1[2].x)), vec4(uv_1[2].y));
            if (!(dx4.x == 3.4028234663852885981170418348452e+38))
            {
                dx4 = ((a_1 * ioSD.du.dx) + (b * ioSD.dv.dx)) - (c_1 * (ioSD.du.dx + ioSD.dv.dx));
            }
            if (!(dy4.x == 3.4028234663852885981170418348452e+38))
            {
                dy4 = ((a_1 * ioSD.du.dy) + (b * ioSD.dv.dy)) - (c_1 * (ioSD.du.dy + ioSD.dv.dy));
            }
            return ((a_1 * ioSD.u) + (b * ioSD.v)) + (c_1 * ((1.0 - ioSD.u) - ioSD.v));
        }
        else
        {
            bool _6016 = desc.element == 1u;
            bool _6022;
            if (!_6016)
            {
                _6022 = desc.element == 2u;
            }
            else
            {
                _6022 = _6016;
            }
            if (_6022)
            {
                if (!(dx4.x == 3.4028234663852885981170418348452e+38))
                {
                    dx4 = vec4(0.0);
                }
                if (!(dy4.x == 3.4028234663852885981170418348452e+38))
                {
                    dy4 = vec4(0.0);
                }
                u8vec4 param_15 = push.data_ptr._attributes_uchar4.data[desc.offset];
                return color_uchar4_to_float4(param_15);
            }
            else
            {
                if (!(dx4.x == 3.4028234663852885981170418348452e+38))
                {
                    dx4 = vec4(0.0);
                }
                if (!(dy4.x == 3.4028234663852885981170418348452e+38))
                {
                    dy4 = vec4(0.0);
                }
                return vec4(0.0);
            }
        }
    }
}

vec4 primitive_attribute_float4(AttributeDescriptor desc, inout vec4 dx4, inout vec4 dy4)
{
    if ((uint(ioSD.type) & 3u) != 0u)
    {
        uint _7323;
        if (ioSD.prim != (-1))
        {
            _7323 = push.data_ptr._tri_patch.data[ioSD.prim];
        }
        else
        {
            _7323 = 4294967295u;
        }
        if (_7323 == 4294967295u)
        {
            vec4 param = dx4;
            vec4 param_1 = dy4;
            vec4 _7343 = triangle_attribute_float4(desc, param, param_1);
            dx4 = param;
            dy4 = param_1;
            return _7343;
        }
        else
        {
            vec4 param_2 = dx4;
            vec4 param_3 = dy4;
            vec4 _7352 = subd_triangle_attribute_float4(desc, param_2, param_3);
            dx4 = param_2;
            dy4 = param_3;
            return _7352;
        }
    }
    else
    {
        if (!(dx4.x == 3.4028234663852885981170418348452e+38))
        {
            dx4 = vec4(0.0);
        }
        if (!(dy4.x == 3.4028234663852885981170418348452e+38))
        {
            dy4 = vec4(0.0);
        }
        return vec4(0.0);
    }
}

void svm_node_attr()
{
    uint type = 0u;
    uint out_offset = 0u;
    uint param = type;
    uint param_1 = out_offset;
    AttributeDescriptor _7757 = svm_node_attr_init(param, param_1);
    type = param;
    out_offset = param_1;
    AttributeDescriptor desc = _7757;
    ioSD.object_flag = int(desc.type);
    ioSD.call_type = type;
    ioSD.offset = int(out_offset);
    vec4 ret;
    if (desc.type == 0u)
    {
        float param_2 = null_flt;
        float param_3 = null_flt;
        float _7780 = primitive_attribute_float(desc, param_2, param_3);
        null_flt = param_2;
        null_flt = param_3;
        ret.x = _7780;
    }
    else
    {
        if (desc.type == 1u)
        {
            vec2 param_4 = null_flt2;
            vec2 param_5 = null_flt2;
            vec2 _7795 = primitive_attribute_float2(desc, param_4, param_5);
            null_flt2 = param_4;
            null_flt2 = param_5;
            ret = vec4(_7795.x, _7795.y, ret.z, ret.w);
        }
        else
        {
            if (desc.type == 3u)
            {
                vec4 param_6 = null_flt4;
                vec4 param_7 = null_flt4;
                vec4 _7811 = primitive_attribute_float4(desc, param_6, param_7);
                null_flt4 = param_6;
                null_flt4 = param_7;
                ret = _7811;
            }
            else
            {
                vec4 param_8 = null_flt3;
                vec4 param_9 = null_flt3;
                vec4 _7820 = primitive_attribute_float3(desc, param_8, param_9);
                null_flt3 = param_8;
                null_flt3 = param_9;
                ret = _7820;
            }
        }
    }
    ioSD.N.x = ret.x;
    ioSD.N.y = ret.y;
    ioSD.N.z = ret.z;
    ioSD.N.w = ret.w;
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
    if (ioSD.call_type == 0u)
    {
        svm_node_tangent();
    }
    else
    {
        if (ioSD.call_type == 1u)
        {
            primitive_tangent();
        }
        else
        {
            if (ioSD.call_type == 2u)
            {
                svm_node_attr();
            }
        }
    }
}

