#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require

struct LIsectInfo
{
    int offset;
    int max_hits;
    uint lcg_state;
    int num_hits;
    int local_object;
    int type;
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

struct ShaderClosure
{
    vec4 weight;
    uint type;
    float sample_weight;
    vec4 N;
    int next;
    float data[25];
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer IntersectionPool;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer pool_is_;
layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[5];
    _prim_object_ _prim_object;
};

layout(buffer_reference, std430) buffer IntersectionPool
{
    pool_is_ pool_is;
};

layout(buffer_reference, std430) readonly buffer _prim_object_
{
    uint data[];
};

layout(buffer_reference, std430) buffer pool_is_
{
    Intersection data[];
};

layout(push_constant, std430) uniform PushData
{
    layout(offset = 0) KernelTextures data_ptr;
    layout(offset = 16) IntersectionPool pool2_ptr;
} push;

layout(location = 1) rayPayloadInNV LIsectInfo linfo;
hitAttributeNV vec2 attribs;

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

uint lcg_step_uint(inout uint rng)
{
    rng = (1103515245u * rng) + 12345u;
    return rng;
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
    uint object = uint(gl_InstanceID);
    if (object != uint(linfo.local_object))
    {
        ignoreIntersectionNV();
    }
    int hit = 0;
    uint lcg_state = linfo.lcg_state;
    uint ISidx = uint(linfo.offset);
    if (lcg_state != 4294967295u)
    {
        uint max_hits = uint(linfo.max_hits);
        int _120 = int(min(max_hits, uint(linfo.num_hits))) - 1;
        for (int i = _120; i >= 0; i--)
        {
            if (gl_HitTNV == push.pool2_ptr.pool_is.data[ISidx + uint(i)].t)
            {
                ignoreIntersectionNV();
            }
        }
        int _166 = linfo.num_hits;
        linfo.num_hits = _166 + 1;
        hit = _166;
        if (uint(linfo.num_hits) > max_hits)
        {
            uint param = lcg_state;
            uint _177 = lcg_step_uint(param);
            lcg_state = param;
            hit = int(_177 % uint(linfo.num_hits));
            if (uint(hit) >= max_hits)
            {
                ignoreIntersectionNV();
            }
        }
    }
    else
    {
        bool _193 = linfo.num_hits != int(0u);
        bool _205;
        if (_193)
        {
            _205 = gl_HitTNV > push.pool2_ptr.pool_is.data[ISidx].t;
        }
        else
        {
            _205 = _193;
        }
        if (_205)
        {
            ignoreIntersectionNV();
        }
        linfo.num_hits = 1;
    }
    ISidx += uint(hit);
    push.pool2_ptr.pool_is.data[ISidx].t = gl_HitTNV;
    push.pool2_ptr.pool_is.data[ISidx].object = (gl_InstanceCustomIndexNV & 8388608) | gl_InstanceID;
    push.pool2_ptr.pool_is.data[ISidx].prim = int(uint(gl_PrimitiveID) + push.data_ptr._prim_object.data[gl_InstanceCustomIndexNV & 8388607]);
    push.pool2_ptr.pool_is.data[ISidx].type = gl_InstanceCustomIndexNV & 8388607;
    push.pool2_ptr.pool_is.data[ISidx].u = (1.0 - attribs.y) - attribs.x;
    push.pool2_ptr.pool_is.data[ISidx].v = attribs.x;
    ignoreIntersectionNV();
}

