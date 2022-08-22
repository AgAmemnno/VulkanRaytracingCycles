#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require

struct Transform
{
    vec4 x;
    vec4 y;
    vec4 z;
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

struct KernelShader
{
    float constant_emission[3];
    float cryptomatte_id;
    int flags;
    int pass_id;
    int pad2;
    int pad3;
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _prim_tri_verts2_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer _objects_;
layout(buffer_reference) buffer _object_flag_;
layout(buffer_reference) buffer _tri_shader_;
layout(buffer_reference) buffer _tri_vnormal_;
layout(buffer_reference) buffer _tri_vindex2_;
layout(buffer_reference) buffer _lights_;
layout(buffer_reference) buffer _shaders_;
layout(buffer_reference, std430) buffer KernelTextures
{
    _prim_tri_verts2_ _prim_tri_verts2;
    int64_t pad[3];
    _prim_index_ _prim_index;
    _prim_object_ _prim_object;
    _objects_ _objects;
    _object_flag_ _object_flag;
    int64_t pad1[7];
    _tri_shader_ _tri_shader;
    _tri_vnormal_ _tri_vnormal;
    _tri_vindex2_ _tri_vindex2;
    int64_t pad2[3];
    _lights_ _lights;
    int64_t pad3[4];
    _shaders_ _shaders;
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

layout(buffer_reference, std430) readonly buffer _object_flag_
{
    uint data[];
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

layout(buffer_reference, std430) readonly buffer _lights_
{
    KernelLight data[];
};

layout(buffer_reference, std430) readonly buffer _shaders_
{
    KernelShader data[];
};

layout(set = 2, binding = 1, std430) buffer KG
{
    KernelGlobals_PROF kg;
} _141;

layout(set = 2, binding = 2, std430) buffer Alloc
{
    int counter[1024];
} _947;

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

layout(location = 1) callableDataInNV ShaderData sd;

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

vec4 normalize_len(vec4 a, inout float t)
{
    t = length(a.xyz);
    float x = 1.0 / t;
    return vec4(a.xyz * x, 0.0);
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
        vec4 _692 = normalize_len(D, param_2);
        t = param_2;
        D = _692;
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

vec4 float4_to_float3(vec4 a)
{
    return vec4(a.xyz, 0.0);
}

vec4 safe_normalize(vec4 a)
{
    float t = length(a.xyz);
    vec4 _173;
    if (!(t == 0.0))
    {
        _173 = a * (1.0 / t);
    }
    else
    {
        _173 = a;
    }
    return _173;
}

bool is_zero(vec4 a)
{
    bool _184 = a.x == 0.0;
    bool _199;
    if (!_184)
    {
        _199 = (int((floatBitsToUint(a.x) >> uint(23)) & 255u) - 127) < (-60);
    }
    else
    {
        _199 = _184;
    }
    bool _215;
    if (_199)
    {
        bool _203 = a.y == 0.0;
        bool _214;
        if (!_203)
        {
            _214 = (int((floatBitsToUint(a.y) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _214 = _203;
        }
        _215 = _214;
    }
    else
    {
        _215 = _199;
    }
    bool _231;
    if (_215)
    {
        bool _219 = a.z == 0.0;
        bool _230;
        if (!_219)
        {
            _230 = (int((floatBitsToUint(a.z) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _230 = _219;
        }
        _231 = _230;
    }
    else
    {
        _231 = _215;
    }
    return _231;
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

void shader_setup_from_ray()
{
    int object = sd.object;
    sd.object &= 8388607;
    if ((uint(sd.type) & 1u) != 0u)
    {
        vec4 Ng = triangle_normal();
        sd.shader = int(push.data_ptr._tri_shader.data[sd.prim]);
        vec4 param = sd.P;
        vec4 param_1 = sd.I;
        float param_2 = sd.ray_length;
        int param_3 = object;
        int param_4 = sd.prim;
        int param_5 = sd.geometry;
        vec4 _915 = triangle_refine(param, param_1, param_2, param_3, param_4, param_5);
        sd.P = _915;
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
        int _951 = atomicAdd(_947.counter[34], 1);
        if (G_dump)
        {
            _141.kg.f3[3 + ((rec_num - 1) * 64)] = sd.N;
        }
        uvec3 tri_vindex = uvec3(push.data_ptr._tri_vindex2.data[3 * sd.prim], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 1], push.data_ptr._tri_vindex2.data[(3 * sd.prim) + 2]) + uvec3(push.data_ptr._prim_index.data[sd.geometry]);
        vec4 p0 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.x]);
        vec4 p1 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.y]);
        vec4 p2 = float4_to_float3(push.data_ptr._prim_tri_verts2.data[tri_vindex.z]);
        sd.dPdu = p0 - p2;
        sd.dPdv = p1 - p2;
    }
    sd.flag |= push.data_ptr._shaders.data[uint(sd.shader) & 8388607u].flags;
    if (!((object & 8388608) != int(0u)))
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
    bool backfacing = dot(sd.Ng.xyz, (-sd.I).xyz) < 0.0;
    if (backfacing)
    {
        sd.flag |= 1;
        sd.Ng = -sd.Ng;
        sd.N = -sd.N;
        sd.dPdu = -sd.dPdu;
        sd.dPdv = -sd.dPdv;
    }
    vec4 tmp = sd.I / vec4(dot(sd.I.xyz, sd.Ng.xyz));
    vec4 tmpx = sd.dP.dx + (sd.dI.dx * sd.ray_length);
    vec4 tmpy = sd.dP.dy + (sd.dI.dy * sd.ray_length);
    sd.dP.dx = tmpx - (tmp * dot(tmpx.xyz, sd.Ng.xyz));
    sd.dP.dy = tmpy - (tmp * dot(tmpy.xyz, sd.Ng.xyz));
    sd.dI.dx = -sd.dI.dx;
    sd.dI.dy = -sd.dI.dy;
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
    sd.I *= (-1.0);
}

void shader_setup_from_subsurface()
{
    bool backfacing = (uint(sd.flag) & 1u) != 0u;
    sd.flag = 0;
    int object = sd.object;
    sd.object &= 8388607;
    float isect_t = sd.P.w;
    sd.P.w = 0.0;
    if (uint(sd.type) == 1u)
    {
        vec4 Ng = triangle_normal();
        sd.shader = int(push.data_ptr._tri_shader.data[sd.prim]);
        vec4 param = sd.P;
        vec4 param_1 = sd.I;
        float param_2 = isect_t;
        int param_3 = object;
        int param_4 = sd.prim;
        int param_5 = sd.geometry;
        vec4 _1382 = triangle_refine(param, param_1, param_2, param_3, param_4, param_5);
        sd.P = _1382;
        if (G_dump)
        {
            _141.kg.f3[30 + ((rec_num - 1) * 64)] = sd.P;
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
    if (!((object & 8388608) != int(0u)))
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
        _141.kg.f3[31 + ((rec_num - 1) * 64)] = sd.I;
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
    Dpixel = _141.kg.pixel;
    rec_num = 0;
    G_dump = false;
    if (all(equal(Dpixel, gl_LaunchIDNV.xy)))
    {
        G_dump = true;
    }
    rec_num = int(sd.Ng.x);
    switch (sd.shader)
    {
        case 0:
        {
            shader_setup_from_ray();
            break;
        }
        case 1:
        {
            shader_setup_from_subsurface();
            break;
        }
        default:
        {
            break;
        }
    }
}

