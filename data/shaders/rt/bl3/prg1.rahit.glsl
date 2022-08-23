#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require

struct KernelShader
{
    float constant_emission[3];
    float cryptomatte_id;
    int flags;
    int pass_id;
    int pad2;
    int pad3;
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

struct IsectInfo
{
    uint offset;
    uint numhits;
    uint max_hits;
    uint visibility;
    int terminate;
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
layout(buffer_reference) buffer _prim_type_;
layout(buffer_reference) buffer _prim_visibility_;
layout(buffer_reference) buffer _prim_index_;
layout(buffer_reference) buffer _prim_object_;
layout(buffer_reference) buffer _tri_shader_;
layout(buffer_reference) buffer _shaders_;
layout(buffer_reference) buffer pool_is_;
layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[2];
    _prim_type_ _prim_type;
    _prim_visibility_ _prim_visibility;
    _prim_index_ _prim_index;
    _prim_object_ _prim_object;
    int64_t pad1[9];
    _tri_shader_ _tri_shader;
    int64_t pad2[10];
    _shaders_ _shaders;
};

layout(buffer_reference, std430) buffer IntersectionPool
{
    pool_is_ pool_is;
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

layout(buffer_reference, std430) readonly buffer _tri_shader_
{
    uint data[];
};

layout(buffer_reference, std430) readonly buffer _shaders_
{
    KernelShader data[];
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

layout(location = 0) rayPayloadInNV IsectInfo iinfo;
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
ShaderClosure null_sc;
uint ISidx;

bool shader_transparent_shadow(int prim)
{
    int shader = 0;
    shader = int(push.data_ptr._tri_shader.data[prim]);
    int flag = push.data_ptr._shaders.data[uint(shader) & 8388607u].flags;
    return (uint(flag) & 131072u) != 0u;
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
    uint prim = uint(gl_PrimitiveID) + push.data_ptr._prim_object.data[gl_InstanceCustomIndexNV & 8388607];
    uint visibility = iinfo.visibility;
    if ((push.data_ptr._prim_visibility.data[prim] & visibility) == 0u)
    {
        ignoreIntersectionNV();
    }
    uint num = iinfo.numhits;
    iinfo.numhits++;
    uint ISidx_1 = iinfo.offset + num;
    push.pool2_ptr.pool_is.data[ISidx_1].t = gl_HitTNV;
    push.pool2_ptr.pool_is.data[ISidx_1].object = (gl_InstanceCustomIndexNV & 8388608) | gl_InstanceID;
    push.pool2_ptr.pool_is.data[ISidx_1].type = gl_InstanceCustomIndexNV & 8388607;
    push.pool2_ptr.pool_is.data[ISidx_1].prim = int(prim);
    push.pool2_ptr.pool_is.data[ISidx_1].u = (1.0 - attribs.y) - attribs.x;
    push.pool2_ptr.pool_is.data[ISidx_1].v = attribs.x;
    int param = int(prim);
    bool _261 = !shader_transparent_shadow(param);
    bool _270;
    if (!_261)
    {
        _270 = num >= (iinfo.max_hits - 1u);
    }
    else
    {
        _270 = _261;
    }
    if (_270)
    {
        iinfo.numhits--;
        iinfo.terminate = 1;
        terminateRayNV();
    }
    ignoreIntersectionNV();
}
