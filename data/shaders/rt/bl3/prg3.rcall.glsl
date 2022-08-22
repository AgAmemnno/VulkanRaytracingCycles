#version 460
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require

struct NodeIO
{
    int offset;
    uint type;
    float data[62];
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _svm_nodes_;
layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[23];
    _svm_nodes_ _svm_nodes;
};

layout(buffer_reference, std430) readonly buffer _svm_nodes_
{
    uvec4 data[];
};

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

layout(location = 2) callableDataInNV NodeIO nio;

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

uint hash_uint(uint kx)
{
    uint c = 3735928576u;
    uint b = 3735928576u;
    uint a = 3735928576u;
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

float hash_uint_to_float(uint kx)
{
    uint param = kx;
    return float(hash_uint(param)) / 4294967296.0;
}

float hash_float_to_float(float k)
{
    uint param = floatBitsToUint(k);
    return hash_uint_to_float(param);
}

float random_float_offset(float seed)
{
    float param = seed;
    return 100.0 + (hash_float_to_float(param) * 100.0);
}

int quick_floor_to_int(float x)
{
    return int(x) - int(x < 0.0);
}

float floorfrac(float x, inout int i)
{
    float param = x;
    i = quick_floor_to_int(param);
    return x - float(i);
}

float fade(float t)
{
    return ((t * t) * t) * ((t * ((t * 6.0) - 15.0)) + 10.0);
}

float negate_if(float val, int condition)
{
    float _1076;
    if (condition != int(0u))
    {
        _1076 = -val;
    }
    else
    {
        _1076 = val;
    }
    return _1076;
}

float grad1(uint hash, float x)
{
    int h = int(hash) & 15;
    float g = float(1 + (h & 7));
    float param = g;
    int param_1 = h & 8;
    return negate_if(param, param_1) * x;
}

float perlin_1d(float x)
{
    float param = x;
    int X;
    int param_1 = X;
    float _1112 = floorfrac(param, param_1);
    X = param_1;
    float fx = _1112;
    float param_2 = fx;
    float u = fade(param_2);
    uint param_3 = uint(X);
    uint param_4 = hash_uint(param_3);
    float param_5 = fx;
    uint param_6 = uint(X + 1);
    uint param_7 = hash_uint(param_6);
    float param_8 = fx - 1.0;
    return mix(grad1(param_4, param_5), grad1(param_7, param_8), u);
}

bool isfinite_safe(float f)
{
    uint x = floatBitsToUint(f);
    bool _391 = f == f;
    bool _409;
    if (_391)
    {
        bool _399 = (x == 0u) || (x == 2147483648u);
        bool _408;
        if (!_399)
        {
            _408 = !(f == (2.0 * f));
        }
        else
        {
            _408 = _399;
        }
        _409 = _408;
    }
    else
    {
        _409 = _391;
    }
    bool _418;
    if (_409)
    {
        _418 = !((x << uint(1)) > 4278190080u);
    }
    else
    {
        _418 = _409;
    }
    return _418;
}

float ensure_finite(float v)
{
    float param = v;
    return isfinite_safe(param) ? v : 0.0;
}

float noise_scale1(float result)
{
    return 0.25 * result;
}

float snoise_1d(float p)
{
    float param = p;
    float param_1 = perlin_1d(param);
    float param_2 = ensure_finite(param_1);
    return noise_scale1(param_2);
}

float noise_1d(float p)
{
    float param = p;
    return (0.5 * snoise_1d(param)) + 0.5;
}

float fractal_noise_1d(float p, inout float octaves, float roughness)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;
    octaves = clamp(octaves, 0.0, 16.0);
    int n = int(octaves);
    for (int i = 0; i <= n; i++)
    {
        float param = fscale * p;
        float t = noise_1d(param);
        sum += (t * amp);
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= 2.0;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        float param_1 = fscale * p;
        float t_1 = noise_1d(param_1);
        float sum2 = sum + (t_1 * amp);
        sum /= maxamp;
        sum2 /= (maxamp + amp);
        return ((1.0 - rmd) * sum) + (rmd * sum2);
    }
    else
    {
        return sum / maxamp;
    }
}

void noise_texture_1d(float co, float detail, float roughness, float distortion, bool color_is_needed, inout float value, inout vec4 color)
{
    float p = co;
    if (!(distortion == 0.0))
    {
        float param = 0.0;
        float param_1 = p + random_float_offset(param);
        p += (snoise_1d(param_1) * distortion);
    }
    float param_2 = p;
    float param_3 = detail;
    float param_4 = roughness;
    float _2754 = fractal_noise_1d(param_2, param_3, param_4);
    value = _2754;
    if (color_is_needed)
    {
        float param_5 = 1.0;
        float param_6 = p + random_float_offset(param_5);
        float param_7 = detail;
        float param_8 = roughness;
        float _2768 = fractal_noise_1d(param_6, param_7, param_8);
        float param_9 = 2.0;
        float param_10 = p + random_float_offset(param_9);
        float param_11 = detail;
        float param_12 = roughness;
        float _2778 = fractal_noise_1d(param_10, param_11, param_12);
        color = vec4(value, _2768, _2778, 0.0);
    }
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

float hash_float2_to_float(vec2 k)
{
    uint param = floatBitsToUint(k.x);
    uint param_1 = floatBitsToUint(k.y);
    return hash_uint2_to_float(param, param_1);
}

vec2 random_float2_offset(float seed)
{
    vec2 param = vec2(seed, 0.0);
    vec2 param_1 = vec2(seed, 1.0);
    return vec2(100.0 + (hash_float2_to_float(param) * 100.0), 100.0 + (hash_float2_to_float(param_1) * 100.0));
}

float grad2(uint hash, float x, float y)
{
    int h = int(hash) & 7;
    float u = (h < 4) ? x : y;
    float v = 2.0 * ((h < 4) ? y : x);
    float param = u;
    int param_1 = h & 1;
    float param_2 = v;
    int param_3 = h & 2;
    return negate_if(param, param_1) + negate_if(param_2, param_3);
}

float bi_mix(float v0, float v1, float v2, float v3, float x, float y)
{
    float x1 = 1.0 - x;
    return ((1.0 - y) * ((v0 * x1) + (v1 * x))) + (y * ((v2 * x1) + (v3 * x)));
}

float perlin_2d(float x, float y)
{
    float param = x;
    int X;
    int param_1 = X;
    float _1394 = floorfrac(param, param_1);
    X = param_1;
    float fx = _1394;
    float param_2 = y;
    int Y;
    int param_3 = Y;
    float _1402 = floorfrac(param_2, param_3);
    Y = param_3;
    float fy = _1402;
    float param_4 = fx;
    float u = fade(param_4);
    float param_5 = fy;
    float v = fade(param_5);
    uint param_6 = uint(X);
    uint param_7 = uint(Y);
    uint param_8 = hash_uint2(param_6, param_7);
    float param_9 = fx;
    float param_10 = fy;
    uint param_11 = uint(X + 1);
    uint param_12 = uint(Y);
    uint param_13 = hash_uint2(param_11, param_12);
    float param_14 = fx - 1.0;
    float param_15 = fy;
    uint param_16 = uint(X);
    uint param_17 = uint(Y + 1);
    uint param_18 = hash_uint2(param_16, param_17);
    float param_19 = fx;
    float param_20 = fy - 1.0;
    uint param_21 = uint(X + 1);
    uint param_22 = uint(Y + 1);
    uint param_23 = hash_uint2(param_21, param_22);
    float param_24 = fx - 1.0;
    float param_25 = fy - 1.0;
    float param_26 = grad2(param_8, param_9, param_10);
    float param_27 = grad2(param_13, param_14, param_15);
    float param_28 = grad2(param_18, param_19, param_20);
    float param_29 = grad2(param_23, param_24, param_25);
    float param_30 = u;
    float param_31 = v;
    float r = bi_mix(param_26, param_27, param_28, param_29, param_30, param_31);
    return r;
}

float noise_scale2(float result)
{
    return 0.66159999370574951171875 * result;
}

float snoise_2d(vec2 p)
{
    float param = p.x;
    float param_1 = p.y;
    float param_2 = perlin_2d(param, param_1);
    float param_3 = ensure_finite(param_2);
    return noise_scale2(param_3);
}

float noise_2d(vec2 p)
{
    vec2 param = p;
    return (0.5 * snoise_2d(param)) + 0.5;
}

float fractal_noise_2d(vec2 p, inout float octaves, float roughness)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;
    octaves = clamp(octaves, 0.0, 16.0);
    int n = int(octaves);
    for (int i = 0; i <= n; i++)
    {
        vec2 param = p * fscale;
        float t = noise_2d(param);
        sum += (t * amp);
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= 2.0;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec2 param_1 = p * fscale;
        float t_1 = noise_2d(param_1);
        float sum2 = sum + (t_1 * amp);
        sum /= maxamp;
        sum2 /= (maxamp + amp);
        return ((1.0 - rmd) * sum) + (rmd * sum2);
    }
    else
    {
        return sum / maxamp;
    }
}

void noise_texture_2d(vec2 co, float detail, float roughness, float distortion, bool color_is_needed, inout float value, inout vec4 color)
{
    vec2 p = co;
    if (!(distortion == 0.0))
    {
        float param = 0.0;
        vec2 param_1 = p + random_float2_offset(param);
        float param_2 = 1.0;
        vec2 param_3 = p + random_float2_offset(param_2);
        p += vec2(snoise_2d(param_1) * distortion, snoise_2d(param_3) * distortion);
    }
    vec2 param_4 = p;
    float param_5 = detail;
    float param_6 = roughness;
    float _2811 = fractal_noise_2d(param_4, param_5, param_6);
    value = _2811;
    if (color_is_needed)
    {
        float param_7 = 2.0;
        vec2 param_8 = p + random_float2_offset(param_7);
        float param_9 = detail;
        float param_10 = roughness;
        float _2825 = fractal_noise_2d(param_8, param_9, param_10);
        float param_11 = 3.0;
        vec2 param_12 = p + random_float2_offset(param_11);
        float param_13 = detail;
        float param_14 = roughness;
        float _2835 = fractal_noise_2d(param_12, param_13, param_14);
        color = vec4(value, _2825, _2835, 0.0);
    }
}

vec4 random_float3_offset(float seed)
{
    vec2 param = vec2(seed, 0.0);
    vec2 param_1 = vec2(seed, 1.0);
    vec2 param_2 = vec2(seed, 2.0);
    return vec4(100.0 + (hash_float2_to_float(param) * 100.0), 100.0 + (hash_float2_to_float(param_1) * 100.0), 100.0 + (hash_float2_to_float(param_2) * 100.0), 0.0);
}

uint hash_uint3(uint kx, uint ky, uint kz)
{
    uint c = 3735928584u;
    uint b = 3735928584u;
    uint a = 3735928584u;
    c += kz;
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

float grad3(uint hash, float x, float y, float z)
{
    int h = int(hash) & 15;
    float u = (h < 8) ? x : y;
    float vt = ((h == 12) || (h == 14)) ? x : z;
    float v = (h < 4) ? y : vt;
    float param = u;
    int param_1 = h & 1;
    float param_2 = v;
    int param_3 = h & 2;
    return negate_if(param, param_1) + negate_if(param_2, param_3);
}

float tri_mix(float v0, float v1, float v2, float v3, float v4, float v5, float v6, float v7, float x, float y, float z)
{
    float x1 = 1.0 - x;
    float y1 = 1.0 - y;
    float z1 = 1.0 - z;
    return (z1 * ((y1 * ((v0 * x1) + (v1 * x))) + (y * ((v2 * x1) + (v3 * x))))) + (z * ((y1 * ((v4 * x1) + (v5 * x))) + (y * ((v6 * x1) + (v7 * x)))));
}

float perlin_3d(float x, float y, float z)
{
    float param = x;
    int X;
    int param_1 = X;
    float _1491 = floorfrac(param, param_1);
    X = param_1;
    float fx = _1491;
    float param_2 = y;
    int Y;
    int param_3 = Y;
    float _1499 = floorfrac(param_2, param_3);
    Y = param_3;
    float fy = _1499;
    float param_4 = z;
    int Z;
    int param_5 = Z;
    float _1507 = floorfrac(param_4, param_5);
    Z = param_5;
    float fz = _1507;
    float param_6 = fx;
    float u = fade(param_6);
    float param_7 = fy;
    float v = fade(param_7);
    float param_8 = fz;
    float w = fade(param_8);
    uint param_9 = uint(X);
    uint param_10 = uint(Y);
    uint param_11 = uint(Z);
    uint param_12 = hash_uint3(param_9, param_10, param_11);
    float param_13 = fx;
    float param_14 = fy;
    float param_15 = fz;
    uint param_16 = uint(X + 1);
    uint param_17 = uint(Y);
    uint param_18 = uint(Z);
    uint param_19 = hash_uint3(param_16, param_17, param_18);
    float param_20 = fx - 1.0;
    float param_21 = fy;
    float param_22 = fz;
    uint param_23 = uint(X);
    uint param_24 = uint(Y + 1);
    uint param_25 = uint(Z);
    uint param_26 = hash_uint3(param_23, param_24, param_25);
    float param_27 = fx;
    float param_28 = fy - 1.0;
    float param_29 = fz;
    uint param_30 = uint(X + 1);
    uint param_31 = uint(Y + 1);
    uint param_32 = uint(Z);
    uint param_33 = hash_uint3(param_30, param_31, param_32);
    float param_34 = fx - 1.0;
    float param_35 = fy - 1.0;
    float param_36 = fz;
    uint param_37 = uint(X);
    uint param_38 = uint(Y);
    uint param_39 = uint(Z + 1);
    uint param_40 = hash_uint3(param_37, param_38, param_39);
    float param_41 = fx;
    float param_42 = fy;
    float param_43 = fz - 1.0;
    uint param_44 = uint(X + 1);
    uint param_45 = uint(Y);
    uint param_46 = uint(Z + 1);
    uint param_47 = hash_uint3(param_44, param_45, param_46);
    float param_48 = fx - 1.0;
    float param_49 = fy;
    float param_50 = fz - 1.0;
    uint param_51 = uint(X);
    uint param_52 = uint(Y + 1);
    uint param_53 = uint(Z + 1);
    uint param_54 = hash_uint3(param_51, param_52, param_53);
    float param_55 = fx;
    float param_56 = fy - 1.0;
    float param_57 = fz - 1.0;
    uint param_58 = uint(X + 1);
    uint param_59 = uint(Y + 1);
    uint param_60 = uint(Z + 1);
    uint param_61 = hash_uint3(param_58, param_59, param_60);
    float param_62 = fx - 1.0;
    float param_63 = fy - 1.0;
    float param_64 = fz - 1.0;
    float param_65 = grad3(param_12, param_13, param_14, param_15);
    float param_66 = grad3(param_19, param_20, param_21, param_22);
    float param_67 = grad3(param_26, param_27, param_28, param_29);
    float param_68 = grad3(param_33, param_34, param_35, param_36);
    float param_69 = grad3(param_40, param_41, param_42, param_43);
    float param_70 = grad3(param_47, param_48, param_49, param_50);
    float param_71 = grad3(param_54, param_55, param_56, param_57);
    float param_72 = grad3(param_61, param_62, param_63, param_64);
    float param_73 = u;
    float param_74 = v;
    float param_75 = w;
    float r = tri_mix(param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74, param_75);
    return r;
}

float noise_scale3(float result)
{
    return 0.98199999332427978515625 * result;
}

float snoise_3d(vec4 p)
{
    float param = p.x;
    float param_1 = p.y;
    float param_2 = p.z;
    float param_3 = perlin_3d(param, param_1, param_2);
    float param_4 = ensure_finite(param_3);
    return noise_scale3(param_4);
}

float noise_3d(vec4 p)
{
    vec4 param = p;
    return (0.5 * snoise_3d(param)) + 0.5;
}

float fractal_noise_3d(vec4 p, inout float octaves, float roughness)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;
    octaves = clamp(octaves, 0.0, 16.0);
    int n = int(octaves);
    for (int i = 0; i <= n; i++)
    {
        vec4 param = p * fscale;
        float t = noise_3d(param);
        sum += (t * amp);
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= 2.0;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_1 = p * fscale;
        float t_1 = noise_3d(param_1);
        float sum2 = sum + (t_1 * amp);
        sum /= maxamp;
        sum2 /= (maxamp + amp);
        return ((1.0 - rmd) * sum) + (rmd * sum2);
    }
    else
    {
        return sum / maxamp;
    }
}

void noise_texture_3d(vec4 co, float detail, float roughness, float distortion, bool color_is_needed, inout float value, inout vec4 color)
{
    vec4 p = co;
    if (!(distortion == 0.0))
    {
        float param = 0.0;
        vec4 param_1 = p + random_float3_offset(param);
        float param_2 = 1.0;
        vec4 param_3 = p + random_float3_offset(param_2);
        float param_4 = 2.0;
        vec4 param_5 = p + random_float3_offset(param_4);
        p += vec4(snoise_3d(param_1) * distortion, snoise_3d(param_3) * distortion, snoise_3d(param_5) * distortion, 0.0);
    }
    vec4 param_6 = p;
    float param_7 = detail;
    float param_8 = roughness;
    float _2876 = fractal_noise_3d(param_6, param_7, param_8);
    value = _2876;
    if (color_is_needed)
    {
        float param_9 = 3.0;
        vec4 param_10 = p + random_float3_offset(param_9);
        float param_11 = detail;
        float param_12 = roughness;
        float _2890 = fractal_noise_3d(param_10, param_11, param_12);
        float param_13 = 4.0;
        vec4 param_14 = p + random_float3_offset(param_13);
        float param_15 = detail;
        float param_16 = roughness;
        float _2901 = fractal_noise_3d(param_14, param_15, param_16);
        color = vec4(value, _2890, _2901, 0.0);
    }
}

vec4 random_float4_offset(float seed)
{
    vec2 param = vec2(seed, 0.0);
    vec2 param_1 = vec2(seed, 1.0);
    vec2 param_2 = vec2(seed, 2.0);
    vec2 param_3 = vec2(seed, 3.0);
    return vec4(100.0 + (hash_float2_to_float(param) * 100.0), 100.0 + (hash_float2_to_float(param_1) * 100.0), 100.0 + (hash_float2_to_float(param_2) * 100.0), 100.0 + (hash_float2_to_float(param_3) * 100.0));
}

uint hash_uint4(uint kx, uint ky, uint kz, uint kw)
{
    uint c = 3735928588u;
    uint b = 3735928588u;
    uint a = 3735928588u;
    a += kx;
    b += ky;
    c += kz;
    a -= c;
    a ^= ((c << uint(4)) | (c >> uint(28)));
    c += b;
    b -= a;
    b ^= ((a << uint(6)) | (a >> uint(26)));
    a += c;
    c -= b;
    c ^= ((b << uint(8)) | (b >> uint(24)));
    b += a;
    a -= c;
    a ^= ((c << uint(16)) | (c >> uint(16)));
    c += b;
    b -= a;
    b ^= ((a << uint(19)) | (a >> uint(13)));
    a += c;
    c -= b;
    c ^= ((b << uint(4)) | (b >> uint(28)));
    b += a;
    a += kw;
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

float grad4(uint hash, float x, float y, float z, float w)
{
    int h = int(hash) & 31;
    float u = (h < 24) ? x : y;
    float v = (h < 16) ? y : z;
    float s = (h < 8) ? z : w;
    float param = u;
    int param_1 = h & 1;
    float param_2 = v;
    int param_3 = h & 2;
    float param_4 = s;
    int param_5 = h & 4;
    return (negate_if(param, param_1) + negate_if(param_2, param_3)) + negate_if(param_4, param_5);
}

float quad_mix(float v0, float v1, float v2, float v3, float v4, float v5, float v6, float v7, float v8, float v9, float v10, float v11, float v12, float v13, float v14, float v15, float x, float y, float z, float w)
{
    float param = v0;
    float param_1 = v1;
    float param_2 = v2;
    float param_3 = v3;
    float param_4 = v4;
    float param_5 = v5;
    float param_6 = v6;
    float param_7 = v7;
    float param_8 = x;
    float param_9 = y;
    float param_10 = z;
    float param_11 = v8;
    float param_12 = v9;
    float param_13 = v10;
    float param_14 = v11;
    float param_15 = v12;
    float param_16 = v13;
    float param_17 = v14;
    float param_18 = v15;
    float param_19 = x;
    float param_20 = y;
    float param_21 = z;
    return mix(tri_mix(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9, param_10), tri_mix(param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21), w);
}

float perlin_4d(float x, float y, float z, float w)
{
    float param = x;
    int X;
    int param_1 = X;
    float _1714 = floorfrac(param, param_1);
    X = param_1;
    float fx = _1714;
    float param_2 = y;
    int Y;
    int param_3 = Y;
    float _1722 = floorfrac(param_2, param_3);
    Y = param_3;
    float fy = _1722;
    float param_4 = z;
    int Z;
    int param_5 = Z;
    float _1730 = floorfrac(param_4, param_5);
    Z = param_5;
    float fz = _1730;
    float param_6 = w;
    int W;
    int param_7 = W;
    float _1738 = floorfrac(param_6, param_7);
    W = param_7;
    float fw = _1738;
    float param_8 = fx;
    float u = fade(param_8);
    float param_9 = fy;
    float v = fade(param_9);
    float param_10 = fz;
    float t = fade(param_10);
    float param_11 = fw;
    float s = fade(param_11);
    uint param_12 = uint(X);
    uint param_13 = uint(Y);
    uint param_14 = uint(Z);
    uint param_15 = uint(W);
    uint param_16 = hash_uint4(param_12, param_13, param_14, param_15);
    float param_17 = fx;
    float param_18 = fy;
    float param_19 = fz;
    float param_20 = fw;
    uint param_21 = uint(X + 1);
    uint param_22 = uint(Y);
    uint param_23 = uint(Z);
    uint param_24 = uint(W);
    uint param_25 = hash_uint4(param_21, param_22, param_23, param_24);
    float param_26 = fx - 1.0;
    float param_27 = fy;
    float param_28 = fz;
    float param_29 = fw;
    uint param_30 = uint(X);
    uint param_31 = uint(Y + 1);
    uint param_32 = uint(Z);
    uint param_33 = uint(W);
    uint param_34 = hash_uint4(param_30, param_31, param_32, param_33);
    float param_35 = fx;
    float param_36 = fy - 1.0;
    float param_37 = fz;
    float param_38 = fw;
    uint param_39 = uint(X + 1);
    uint param_40 = uint(Y + 1);
    uint param_41 = uint(Z);
    uint param_42 = uint(W);
    uint param_43 = hash_uint4(param_39, param_40, param_41, param_42);
    float param_44 = fx - 1.0;
    float param_45 = fy - 1.0;
    float param_46 = fz;
    float param_47 = fw;
    uint param_48 = uint(X);
    uint param_49 = uint(Y);
    uint param_50 = uint(Z + 1);
    uint param_51 = uint(W);
    uint param_52 = hash_uint4(param_48, param_49, param_50, param_51);
    float param_53 = fx;
    float param_54 = fy;
    float param_55 = fz - 1.0;
    float param_56 = fw;
    uint param_57 = uint(X + 1);
    uint param_58 = uint(Y);
    uint param_59 = uint(Z + 1);
    uint param_60 = uint(W);
    uint param_61 = hash_uint4(param_57, param_58, param_59, param_60);
    float param_62 = fx - 1.0;
    float param_63 = fy;
    float param_64 = fz - 1.0;
    float param_65 = fw;
    uint param_66 = uint(X);
    uint param_67 = uint(Y + 1);
    uint param_68 = uint(Z + 1);
    uint param_69 = uint(W);
    uint param_70 = hash_uint4(param_66, param_67, param_68, param_69);
    float param_71 = fx;
    float param_72 = fy - 1.0;
    float param_73 = fz - 1.0;
    float param_74 = fw;
    uint param_75 = uint(X + 1);
    uint param_76 = uint(Y + 1);
    uint param_77 = uint(Z + 1);
    uint param_78 = uint(W);
    uint param_79 = hash_uint4(param_75, param_76, param_77, param_78);
    float param_80 = fx - 1.0;
    float param_81 = fy - 1.0;
    float param_82 = fz - 1.0;
    float param_83 = fw;
    uint param_84 = uint(X);
    uint param_85 = uint(Y);
    uint param_86 = uint(Z);
    uint param_87 = uint(W + 1);
    uint param_88 = hash_uint4(param_84, param_85, param_86, param_87);
    float param_89 = fx;
    float param_90 = fy;
    float param_91 = fz;
    float param_92 = fw - 1.0;
    uint param_93 = uint(X + 1);
    uint param_94 = uint(Y);
    uint param_95 = uint(Z);
    uint param_96 = uint(W + 1);
    uint param_97 = hash_uint4(param_93, param_94, param_95, param_96);
    float param_98 = fx - 1.0;
    float param_99 = fy;
    float param_100 = fz;
    float param_101 = fw - 1.0;
    uint param_102 = uint(X);
    uint param_103 = uint(Y + 1);
    uint param_104 = uint(Z);
    uint param_105 = uint(W + 1);
    uint param_106 = hash_uint4(param_102, param_103, param_104, param_105);
    float param_107 = fx;
    float param_108 = fy - 1.0;
    float param_109 = fz;
    float param_110 = fw - 1.0;
    uint param_111 = uint(X + 1);
    uint param_112 = uint(Y + 1);
    uint param_113 = uint(Z);
    uint param_114 = uint(W + 1);
    uint param_115 = hash_uint4(param_111, param_112, param_113, param_114);
    float param_116 = fx - 1.0;
    float param_117 = fy - 1.0;
    float param_118 = fz;
    float param_119 = fw - 1.0;
    uint param_120 = uint(X);
    uint param_121 = uint(Y);
    uint param_122 = uint(Z + 1);
    uint param_123 = uint(W + 1);
    uint param_124 = hash_uint4(param_120, param_121, param_122, param_123);
    float param_125 = fx;
    float param_126 = fy;
    float param_127 = fz - 1.0;
    float param_128 = fw - 1.0;
    uint param_129 = uint(X + 1);
    uint param_130 = uint(Y);
    uint param_131 = uint(Z + 1);
    uint param_132 = uint(W + 1);
    uint param_133 = hash_uint4(param_129, param_130, param_131, param_132);
    float param_134 = fx - 1.0;
    float param_135 = fy;
    float param_136 = fz - 1.0;
    float param_137 = fw - 1.0;
    uint param_138 = uint(X);
    uint param_139 = uint(Y + 1);
    uint param_140 = uint(Z + 1);
    uint param_141 = uint(W + 1);
    uint param_142 = hash_uint4(param_138, param_139, param_140, param_141);
    float param_143 = fx;
    float param_144 = fy - 1.0;
    float param_145 = fz - 1.0;
    float param_146 = fw - 1.0;
    uint param_147 = uint(X + 1);
    uint param_148 = uint(Y + 1);
    uint param_149 = uint(Z + 1);
    uint param_150 = uint(W + 1);
    uint param_151 = hash_uint4(param_147, param_148, param_149, param_150);
    float param_152 = fx - 1.0;
    float param_153 = fy - 1.0;
    float param_154 = fz - 1.0;
    float param_155 = fw - 1.0;
    float param_156 = grad4(param_16, param_17, param_18, param_19, param_20);
    float param_157 = grad4(param_25, param_26, param_27, param_28, param_29);
    float param_158 = grad4(param_34, param_35, param_36, param_37, param_38);
    float param_159 = grad4(param_43, param_44, param_45, param_46, param_47);
    float param_160 = grad4(param_52, param_53, param_54, param_55, param_56);
    float param_161 = grad4(param_61, param_62, param_63, param_64, param_65);
    float param_162 = grad4(param_70, param_71, param_72, param_73, param_74);
    float param_163 = grad4(param_79, param_80, param_81, param_82, param_83);
    float param_164 = grad4(param_88, param_89, param_90, param_91, param_92);
    float param_165 = grad4(param_97, param_98, param_99, param_100, param_101);
    float param_166 = grad4(param_106, param_107, param_108, param_109, param_110);
    float param_167 = grad4(param_115, param_116, param_117, param_118, param_119);
    float param_168 = grad4(param_124, param_125, param_126, param_127, param_128);
    float param_169 = grad4(param_133, param_134, param_135, param_136, param_137);
    float param_170 = grad4(param_142, param_143, param_144, param_145, param_146);
    float param_171 = grad4(param_151, param_152, param_153, param_154, param_155);
    float param_172 = u;
    float param_173 = v;
    float param_174 = t;
    float param_175 = s;
    float r = quad_mix(param_156, param_157, param_158, param_159, param_160, param_161, param_162, param_163, param_164, param_165, param_166, param_167, param_168, param_169, param_170, param_171, param_172, param_173, param_174, param_175);
    return r;
}

float noise_scale4(float result)
{
    return 0.834399998188018798828125 * result;
}

float snoise_4d(vec4 p)
{
    float param = p.x;
    float param_1 = p.y;
    float param_2 = p.z;
    float param_3 = p.w;
    float param_4 = perlin_4d(param, param_1, param_2, param_3);
    float param_5 = ensure_finite(param_4);
    return noise_scale4(param_5);
}

float noise_4d(vec4 p)
{
    vec4 param = p;
    return (0.5 * snoise_4d(param)) + 0.5;
}

float fractal_noise_4d(vec4 p, inout float octaves, float roughness)
{
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;
    octaves = clamp(octaves, 0.0, 16.0);
    int n = int(octaves);
    for (int i = 0; i <= n; i++)
    {
        vec4 param = p * fscale;
        float t = noise_4d(param);
        sum += (t * amp);
        maxamp += amp;
        amp *= clamp(roughness, 0.0, 1.0);
        fscale *= 2.0;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_1 = p * fscale;
        float t_1 = noise_4d(param_1);
        float sum2 = sum + (t_1 * amp);
        sum /= maxamp;
        sum2 /= (maxamp + amp);
        return ((1.0 - rmd) * sum) + (rmd * sum2);
    }
    else
    {
        return sum / maxamp;
    }
}

void noise_texture_4d(vec4 co, float detail, float roughness, float distortion, bool color_is_needed, inout float value, inout vec4 color)
{
    vec4 p = co;
    if (!(distortion == 0.0))
    {
        float param = 0.0;
        vec4 param_1 = p + random_float4_offset(param);
        float param_2 = 1.0;
        vec4 param_3 = p + random_float4_offset(param_2);
        float param_4 = 2.0;
        vec4 param_5 = p + random_float4_offset(param_4);
        float param_6 = 3.0;
        vec4 param_7 = p + random_float4_offset(param_6);
        p += vec4(snoise_4d(param_1) * distortion, snoise_4d(param_3) * distortion, snoise_4d(param_5) * distortion, snoise_4d(param_7) * distortion);
    }
    vec4 param_8 = p;
    float param_9 = detail;
    float param_10 = roughness;
    float _2950 = fractal_noise_4d(param_8, param_9, param_10);
    value = _2950;
    if (color_is_needed)
    {
        float param_11 = 4.0;
        vec4 param_12 = p + random_float4_offset(param_11);
        float param_13 = detail;
        float param_14 = roughness;
        float _2964 = fractal_noise_4d(param_12, param_13, param_14);
        float param_15 = 5.0;
        vec4 param_16 = p + random_float4_offset(param_15);
        float param_17 = detail;
        float param_18 = roughness;
        float _2975 = fractal_noise_4d(param_16, param_17, param_18);
        color = vec4(value, _2964, _2975, 0.0);
    }
}

void svm_node_tex_noise()
{
    vec4 vector = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0);
    vector *= nio.data[4];
    nio.data[3] *= nio.data[4];
    float value;
    vec4 color;
    switch (uint(nio.data[8]))
    {
        case 1u:
        {
            float param = nio.data[3];
            float param_1 = nio.data[5];
            float param_2 = nio.data[6];
            float param_3 = nio.data[7];
            bool param_4 = uint(nio.offset) != 255u;
            float param_5 = value;
            vec4 param_6 = color;
            noise_texture_1d(param, param_1, param_2, param_3, param_4, param_5, param_6);
            value = param_5;
            color = param_6;
            break;
        }
        case 2u:
        {
            vec2 param_7 = vector.xy;
            float param_8 = nio.data[5];
            float param_9 = nio.data[6];
            float param_10 = nio.data[7];
            bool param_11 = uint(nio.offset) != 255u;
            float param_12 = value;
            vec4 param_13 = color;
            noise_texture_2d(param_7, param_8, param_9, param_10, param_11, param_12, param_13);
            value = param_12;
            color = param_13;
            break;
        }
        case 3u:
        {
            vec4 param_14 = vector;
            float param_15 = nio.data[5];
            float param_16 = nio.data[6];
            float param_17 = nio.data[7];
            bool param_18 = uint(nio.offset) != 255u;
            float param_19 = value;
            vec4 param_20 = color;
            noise_texture_3d(param_14, param_15, param_16, param_17, param_18, param_19, param_20);
            value = param_19;
            color = param_20;
            break;
        }
        case 4u:
        {
            vec4 param_21 = vec4(vector.xyz, nio.data[3]);
            float param_22 = nio.data[5];
            float param_23 = nio.data[6];
            float param_24 = nio.data[7];
            bool param_25 = uint(nio.offset) != 255u;
            float param_26 = value;
            vec4 param_27 = color;
            noise_texture_4d(param_21, param_22, param_23, param_24, param_25, param_26, param_27);
            value = param_26;
            color = param_27;
            break;
        }
    }
    nio.data[0] = color.x;
    nio.data[1] = color.y;
    nio.data[2] = color.z;
    nio.data[3] = value;
}

float svm_wave(uint type, uint bands_dir, uint rings_dir, uint profile, inout vec4 p, float distortion, float detail, float dscale, float droughness, float phase)
{
    p = (p + vec4(9.9999999747524270787835121154785e-07)) * 0.999998986721038818359375;
    float n;
    if (type == 0u)
    {
        if (bands_dir == 0u)
        {
            n = p.x * 20.0;
        }
        else
        {
            if (bands_dir == 1u)
            {
                n = p.y * 20.0;
            }
            else
            {
                if (bands_dir == 2u)
                {
                    n = p.z * 20.0;
                }
                else
                {
                    n = ((p.x + p.y) + p.z) * 10.0;
                }
            }
        }
    }
    else
    {
        vec4 rp = p;
        if (rings_dir == 0u)
        {
            rp *= vec4(0.0, 1.0, 1.0, 0.0);
        }
        else
        {
            if (rings_dir == 1u)
            {
                rp *= vec4(1.0, 0.0, 1.0, 0.0);
            }
            else
            {
                if (rings_dir == 2u)
                {
                    rp *= vec4(1.0, 1.0, 0.0, 0.0);
                }
            }
        }
        n = length(rp.xyz) * 20.0;
    }
    n += phase;
    if (!(distortion == 0.0))
    {
        vec4 param = p * dscale;
        float param_1 = detail;
        float param_2 = droughness;
        float _3224 = fractal_noise_3d(param, param_1, param_2);
        n += (distortion * ((_3224 * 2.0) - 1.0));
    }
    if (profile == 0u)
    {
        return 0.5 + (0.5 * sin(n - 1.57079637050628662109375));
    }
    else
    {
        if (profile == 1u)
        {
            n /= 6.283185482025146484375;
            return n - floor(n);
        }
        else
        {
            n /= 6.283185482025146484375;
            return abs(n - floor(n + 0.5)) * 2.0;
        }
    }
}

void svm_node_tex_wave()
{
    uint type_offset = floatBitsToUint(nio.data[9]) & 255u;
    uint bands_dir_offset = (floatBitsToUint(nio.data[9]) >> uint(8)) & 255u;
    uint rings_dir_offset = (floatBitsToUint(nio.data[9]) >> uint(16)) & 255u;
    uint profile_offset = (floatBitsToUint(nio.data[9]) >> uint(24)) & 255u;
    uint param = type_offset;
    uint param_1 = bands_dir_offset;
    uint param_2 = rings_dir_offset;
    uint param_3 = profile_offset;
    vec4 param_4 = vec4(nio.data[0], nio.data[1], nio.data[2], 0.0) * nio.data[3];
    float param_5 = nio.data[4];
    float param_6 = nio.data[5];
    float param_7 = nio.data[6];
    float param_8 = nio.data[7];
    float param_9 = nio.data[8];
    float _3325 = svm_wave(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);
    float f = _3325;
    nio.data[0] = f;
}

vec4 hash_float_to_float3(float k)
{
    float param = k;
    vec2 param_1 = vec2(k, 1.0);
    vec2 param_2 = vec2(k, 2.0);
    return vec4(hash_float_to_float(param), hash_float2_to_float(param_1), hash_float2_to_float(param_2), 0.0);
}

float hash_uint3_to_float(uint kx, uint ky, uint kz)
{
    uint param = kx;
    uint param_1 = ky;
    uint param_2 = kz;
    return float(hash_uint3(param, param_1, param_2)) / 4294967296.0;
}

float hash_float3_to_float(vec4 k)
{
    uint param = floatBitsToUint(k.x);
    uint param_1 = floatBitsToUint(k.y);
    uint param_2 = floatBitsToUint(k.z);
    return hash_uint3_to_float(param, param_1, param_2);
}

vec4 hash_float2_to_float3(vec2 k)
{
    vec2 param = k;
    vec4 param_1 = vec4(k.x, k.y, 1.0, 0.0);
    vec4 param_2 = vec4(k.x, k.y, 2.0, 0.0);
    return vec4(hash_float2_to_float(param), hash_float3_to_float(param_1), hash_float3_to_float(param_2), 0.0);
}

float hash_uint4_to_float(uint kx, uint ky, uint kz, uint kw)
{
    uint param = kx;
    uint param_1 = ky;
    uint param_2 = kz;
    uint param_3 = kw;
    return float(hash_uint4(param, param_1, param_2, param_3)) / 4294967296.0;
}

float hash_float4_to_float(vec4 k)
{
    uint param = floatBitsToUint(k.x);
    uint param_1 = floatBitsToUint(k.y);
    uint param_2 = floatBitsToUint(k.z);
    uint param_3 = floatBitsToUint(k.w);
    return hash_uint4_to_float(param, param_1, param_2, param_3);
}

vec4 hash_float3_to_float3(vec4 k)
{
    vec4 param = k;
    vec4 param_1 = vec4(k.x, k.y, k.z, 1.0);
    vec4 param_2 = vec4(k.x, k.y, k.z, 2.0);
    return vec4(hash_float3_to_float(param), hash_float4_to_float(param_1), hash_float4_to_float(param_2), 0.0);
}

vec4 hash_float4_to_float3(vec4 k)
{
    vec4 param = k;
    vec4 param_1 = vec4(k.z, k.x, k.w, k.y);
    vec4 param_2 = vec4(k.w, k.z, k.y, k.x);
    return vec4(hash_float4_to_float(param), hash_float4_to_float(param_1), hash_float4_to_float(param_2), 0.0);
}

void svm_node_tex_white_noise()
{
    uint dimensions = floatBitsToUint(nio.data[4]);
    vec4 vector = vec4(nio.data[0], nio.data[1], nio.data[2], nio.data[3]);
    if ((uint(nio.data[5]) & 1u) != 0u)
    {
        vec4 color;
        switch (dimensions)
        {
            case 1u:
            {
                float param = vector.w;
                color = hash_float_to_float3(param);
                break;
            }
            case 2u:
            {
                vec2 param_1 = vector.xy;
                color = hash_float2_to_float3(param_1);
                break;
            }
            case 3u:
            {
                vec4 param_2 = vector;
                color = hash_float3_to_float3(param_2);
                break;
            }
            case 4u:
            {
                vec4 param_3 = vector;
                color = hash_float4_to_float3(param_3);
                break;
            }
            default:
            {
                color = vec4(1.0, 0.0, 1.0, 0.0);
                if (true)
                {
                    // unimplemented ext op 12
                }
                break;
            }
        }
        nio.data[0] = color.x;
        nio.data[1] = color.y;
        nio.data[2] = color.z;
    }
    if ((uint(nio.data[5]) & 2u) != 0u)
    {
        switch (dimensions)
        {
            case 1u:
            {
                float param_4 = vector.w;
                nio.data[3] = hash_float_to_float(param_4);
                break;
            }
            case 2u:
            {
                vec2 param_5 = vector.xy;
                nio.data[3] = hash_float2_to_float(param_5);
                break;
            }
            case 3u:
            {
                vec4 param_6 = vector;
                nio.data[3] = hash_float3_to_float(param_6);
                break;
            }
            case 4u:
            {
                vec4 param_7 = vector;
                nio.data[3] = hash_float4_to_float(param_7);
                break;
            }
            default:
            {
                nio.data[3] = 0.0;
                if (true)
                {
                    // unimplemented ext op 12
                }
                break;
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
    if (nio.type == 0u)
    {
        svm_node_tex_noise();
    }
    else
    {
        if (nio.type == 1u)
        {
            svm_node_tex_wave();
        }
        else
        {
            if (nio.type == 4u)
            {
                svm_node_tex_white_noise();
            }
        }
    }
}

