#version 460
#extension GL_NV_ray_tracing : require

struct NodeIO_MASG
{
    int offset;
    uint type;
    vec3 co;
    float w;
    float scale;
    float detail;
    float dimension;
    float lacunarity;
    float foffset;
    float gain;
    uint dimensions;
};

layout(location = 2) callableDataInNV NodeIO_MASG nio;

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

float negate_if(float val, int condition)
{
    float _891;
    if (condition != int(0u))
    {
        _891 = -val;
    }
    else
    {
        _891 = val;
    }
    return _891;
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
    float _927 = floorfrac(param, param_1);
    X = param_1;
    float fx = _927;
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
    bool _385 = f == f;
    bool _403;
    if (_385)
    {
        bool _393 = (x == 0u) || (x == 2147483648u);
        bool _402;
        if (!_393)
        {
            _402 = !(f == (2.0 * f));
        }
        else
        {
            _402 = _393;
        }
        _403 = _402;
    }
    else
    {
        _403 = _385;
    }
    bool _412;
    if (_403)
    {
        _412 = !((x << uint(1)) > 4278190080u);
    }
    else
    {
        _412 = _403;
    }
    return _412;
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

float noise_musgrave_multi_fractal_1d(float co, float H, float lacunarity, float octaves)
{
    float p = co;
    float value = 1.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        float param = p;
        value *= ((pwr * snoise_1d(param)) + 1.0);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        float param_1 = p;
        value *= (((rmd * pwr) * snoise_1d(param_1)) + 1.0);
    }
    return value;
}

float noise_musgrave_fBm_1d(float co, float H, float lacunarity, float octaves)
{
    float p = co;
    float value = 0.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        float param = p;
        value += (snoise_1d(param) * pwr);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        float param_1 = p;
        value += ((rmd * snoise_1d(param_1)) * pwr);
    }
    return value;
}

float noise_musgrave_hybrid_multi_fractal_1d(float co, float H, float lacunarity, float octaves, float offset, float gain)
{
    float p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    float param = p;
    float value = snoise_1d(param) + offset;
    float weight = gain * value;
    p *= lacunarity;
    int i = 1;
    for (;;)
    {
        bool _2328 = weight > 0.001000000047497451305389404296875;
        bool _2335;
        if (_2328)
        {
            _2335 = i < int(octaves);
        }
        else
        {
            _2335 = _2328;
        }
        if (_2335)
        {
            if (weight > 1.0)
            {
                weight = 1.0;
            }
            float param_1 = p;
            float signal = (snoise_1d(param_1) + offset) * pwr;
            pwr *= pwHL;
            value += (weight * signal);
            weight *= (gain * signal);
            p *= lacunarity;
            i++;
            continue;
        }
        else
        {
            break;
        }
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        float param_2 = p;
        value += (rmd * ((snoise_1d(param_2) + offset) * pwr));
    }
    return value;
}

float noise_musgrave_ridged_multi_fractal_1d(float co, float H, float lacunarity, float octaves, float offset, float gain)
{
    float p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    float param = p;
    float signal = offset - abs(snoise_1d(param));
    signal *= signal;
    float value = signal;
    float weight = 1.0;
    for (int i = 1; i < int(octaves); i++)
    {
        p *= lacunarity;
        weight = clamp(signal * gain, 0.0, 1.0);
        float param_1 = p;
        signal = offset - abs(snoise_1d(param_1));
        signal *= signal;
        signal *= weight;
        value += (signal * pwr);
        pwr *= pwHL;
    }
    return value;
}

float noise_musgrave_hetero_terrain_1d(float co, float H, float lacunarity, float octaves, float offset)
{
    float p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    float param = p;
    float value = offset + snoise_1d(param);
    p *= lacunarity;
    for (int i = 1; i < int(octaves); i++)
    {
        float param_1 = p;
        float increment = ((snoise_1d(param_1) + offset) * pwr) * value;
        value += increment;
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        float param_2 = p;
        float increment_1 = ((snoise_1d(param_2) + offset) * pwr) * value;
        value += (rmd * increment_1);
    }
    return value;
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
    float _1210 = floorfrac(param, param_1);
    X = param_1;
    float fx = _1210;
    float param_2 = y;
    int Y;
    int param_3 = Y;
    float _1218 = floorfrac(param_2, param_3);
    Y = param_3;
    float fy = _1218;
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

float noise_musgrave_multi_fractal_2d(vec2 co, float H, float lacunarity, float octaves)
{
    vec2 p = co;
    float value = 1.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        vec2 param = p;
        value *= ((pwr * snoise_2d(param)) + 1.0);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec2 param_1 = p;
        value *= (((rmd * pwr) * snoise_2d(param_1)) + 1.0);
    }
    return value;
}

float noise_musgrave_fBm_2d(vec2 co, float H, float lacunarity, float octaves)
{
    vec2 p = co;
    float value = 0.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        vec2 param = p;
        value += (snoise_2d(param) * pwr);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec2 param_1 = p;
        value += ((rmd * snoise_2d(param_1)) * pwr);
    }
    return value;
}

float noise_musgrave_hybrid_multi_fractal_2d(vec2 co, float H, float lacunarity, float octaves, float offset, float gain)
{
    vec2 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec2 param = p;
    float value = snoise_2d(param) + offset;
    float weight = gain * value;
    p *= lacunarity;
    int i = 1;
    for (;;)
    {
        bool _2670 = weight > 0.001000000047497451305389404296875;
        bool _2677;
        if (_2670)
        {
            _2677 = i < int(octaves);
        }
        else
        {
            _2677 = _2670;
        }
        if (_2677)
        {
            if (weight > 1.0)
            {
                weight = 1.0;
            }
            vec2 param_1 = p;
            float signal = (snoise_2d(param_1) + offset) * pwr;
            pwr *= pwHL;
            value += (weight * signal);
            weight *= (gain * signal);
            p *= lacunarity;
            i++;
            continue;
        }
        else
        {
            break;
        }
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec2 param_2 = p;
        value += (rmd * ((snoise_2d(param_2) + offset) * pwr));
    }
    return value;
}

float noise_musgrave_ridged_multi_fractal_2d(vec2 co, float H, float lacunarity, float octaves, float offset, float gain)
{
    vec2 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec2 param = p;
    float signal = offset - abs(snoise_2d(param));
    signal *= signal;
    float value = signal;
    float weight = 1.0;
    for (int i = 1; i < int(octaves); i++)
    {
        p *= lacunarity;
        weight = clamp(signal * gain, 0.0, 1.0);
        vec2 param_1 = p;
        signal = offset - abs(snoise_2d(param_1));
        signal *= signal;
        signal *= weight;
        value += (signal * pwr);
        pwr *= pwHL;
    }
    return value;
}

float noise_musgrave_hetero_terrain_2d(vec2 co, float H, float lacunarity, float octaves, float offset)
{
    vec2 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec2 param = p;
    float value = offset + snoise_2d(param);
    p *= lacunarity;
    for (int i = 1; i < int(octaves); i++)
    {
        vec2 param_1 = p;
        float increment = ((snoise_2d(param_1) + offset) * pwr) * value;
        value += increment;
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec2 param_2 = p;
        float increment_1 = ((snoise_2d(param_2) + offset) * pwr) * value;
        value += (rmd * increment_1);
    }
    return value;
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
    float _1307 = floorfrac(param, param_1);
    X = param_1;
    float fx = _1307;
    float param_2 = y;
    int Y;
    int param_3 = Y;
    float _1315 = floorfrac(param_2, param_3);
    Y = param_3;
    float fy = _1315;
    float param_4 = z;
    int Z;
    int param_5 = Z;
    float _1323 = floorfrac(param_4, param_5);
    Z = param_5;
    float fz = _1323;
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

float noise_musgrave_multi_fractal_3d(vec4 co, float H, float lacunarity, float octaves)
{
    vec4 p = co;
    float value = 1.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        vec4 param = p;
        value *= ((pwr * snoise_3d(param)) + 1.0);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_1 = p;
        value *= (((rmd * pwr) * snoise_3d(param_1)) + 1.0);
    }
    return value;
}

float noise_musgrave_fBm_3d(vec4 co, float H, float lacunarity, float octaves)
{
    vec4 p = co;
    float value = 0.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        vec4 param = p;
        value += (snoise_3d(param) * pwr);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_1 = p;
        value += ((rmd * snoise_3d(param_1)) * pwr);
    }
    return value;
}

float noise_musgrave_hybrid_multi_fractal_3d(vec4 co, float H, float lacunarity, float octaves, float offset, float gain)
{
    vec4 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec4 param = p;
    float value = snoise_3d(param) + offset;
    float weight = gain * value;
    p *= lacunarity;
    int i = 1;
    for (;;)
    {
        bool _3012 = weight > 0.001000000047497451305389404296875;
        bool _3019;
        if (_3012)
        {
            _3019 = i < int(octaves);
        }
        else
        {
            _3019 = _3012;
        }
        if (_3019)
        {
            if (weight > 1.0)
            {
                weight = 1.0;
            }
            vec4 param_1 = p;
            float signal = (snoise_3d(param_1) + offset) * pwr;
            pwr *= pwHL;
            value += (weight * signal);
            weight *= (gain * signal);
            p *= lacunarity;
            i++;
            continue;
        }
        else
        {
            break;
        }
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_2 = p;
        value += (rmd * ((snoise_3d(param_2) + offset) * pwr));
    }
    return value;
}

float noise_musgrave_ridged_multi_fractal_3d(vec4 co, float H, float lacunarity, float octaves, float offset, float gain)
{
    vec4 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec4 param = p;
    float signal = offset - abs(snoise_3d(param));
    signal *= signal;
    float value = signal;
    float weight = 1.0;
    for (int i = 1; i < int(octaves); i++)
    {
        p *= lacunarity;
        weight = clamp(signal * gain, 0.0, 1.0);
        vec4 param_1 = p;
        signal = offset - abs(snoise_3d(param_1));
        signal *= signal;
        signal *= weight;
        value += (signal * pwr);
        pwr *= pwHL;
    }
    return value;
}

float noise_musgrave_hetero_terrain_3d(vec4 co, float H, float lacunarity, float octaves, float offset)
{
    vec4 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec4 param = p;
    float value = offset + snoise_3d(param);
    p *= lacunarity;
    for (int i = 1; i < int(octaves); i++)
    {
        vec4 param_1 = p;
        float increment = ((snoise_3d(param_1) + offset) * pwr) * value;
        value += increment;
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_2 = p;
        float increment_1 = ((snoise_3d(param_2) + offset) * pwr) * value;
        value += (rmd * increment_1);
    }
    return value;
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
    float _1530 = floorfrac(param, param_1);
    X = param_1;
    float fx = _1530;
    float param_2 = y;
    int Y;
    int param_3 = Y;
    float _1538 = floorfrac(param_2, param_3);
    Y = param_3;
    float fy = _1538;
    float param_4 = z;
    int Z;
    int param_5 = Z;
    float _1546 = floorfrac(param_4, param_5);
    Z = param_5;
    float fz = _1546;
    float param_6 = w;
    int W;
    int param_7 = W;
    float _1554 = floorfrac(param_6, param_7);
    W = param_7;
    float fw = _1554;
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

float noise_musgrave_multi_fractal_4d(vec4 co, float H, float lacunarity, float octaves)
{
    vec4 p = co;
    float value = 1.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        vec4 param = p;
        value *= ((pwr * snoise_4d(param)) + 1.0);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_1 = p;
        value *= (((rmd * pwr) * snoise_4d(param_1)) + 1.0);
    }
    return value;
}

float noise_musgrave_fBm_4d(vec4 co, float H, float lacunarity, float octaves)
{
    vec4 p = co;
    float value = 0.0;
    float pwr = 1.0;
    float pwHL = pow(lacunarity, -H);
    for (int i = 0; i < int(octaves); i++)
    {
        vec4 param = p;
        value += (snoise_4d(param) * pwr);
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_1 = p;
        value += ((rmd * snoise_4d(param_1)) * pwr);
    }
    return value;
}

float noise_musgrave_hybrid_multi_fractal_4d(vec4 co, float H, float lacunarity, float octaves, float offset, float gain)
{
    vec4 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec4 param = p;
    float value = snoise_4d(param) + offset;
    float weight = gain * value;
    p *= lacunarity;
    int i = 1;
    for (;;)
    {
        bool _3354 = weight > 0.001000000047497451305389404296875;
        bool _3361;
        if (_3354)
        {
            _3361 = i < int(octaves);
        }
        else
        {
            _3361 = _3354;
        }
        if (_3361)
        {
            if (weight > 1.0)
            {
                weight = 1.0;
            }
            vec4 param_1 = p;
            float signal = (snoise_4d(param_1) + offset) * pwr;
            pwr *= pwHL;
            value += (weight * signal);
            weight *= (gain * signal);
            p *= lacunarity;
            i++;
            continue;
        }
        else
        {
            break;
        }
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_2 = p;
        value += (rmd * ((snoise_4d(param_2) + offset) * pwr));
    }
    return value;
}

float noise_musgrave_ridged_multi_fractal_4d(vec4 co, float H, float lacunarity, float octaves, float offset, float gain)
{
    vec4 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec4 param = p;
    float signal = offset - abs(snoise_4d(param));
    signal *= signal;
    float value = signal;
    float weight = 1.0;
    for (int i = 1; i < int(octaves); i++)
    {
        p *= lacunarity;
        weight = clamp(signal * gain, 0.0, 1.0);
        vec4 param_1 = p;
        signal = offset - abs(snoise_4d(param_1));
        signal *= signal;
        signal *= weight;
        value += (signal * pwr);
        pwr *= pwHL;
    }
    return value;
}

float noise_musgrave_hetero_terrain_4d(vec4 co, float H, float lacunarity, float octaves, float offset)
{
    vec4 p = co;
    float pwHL = pow(lacunarity, -H);
    float pwr = pwHL;
    vec4 param = p;
    float value = offset + snoise_4d(param);
    p *= lacunarity;
    for (int i = 1; i < int(octaves); i++)
    {
        vec4 param_1 = p;
        float increment = ((snoise_4d(param_1) + offset) * pwr) * value;
        value += increment;
        pwr *= pwHL;
        p *= lacunarity;
    }
    float rmd = octaves - floor(octaves);
    if (!(rmd == 0.0))
    {
        vec4 param_2 = p;
        float increment_1 = ((snoise_4d(param_2) + offset) * pwr) * value;
        value += (rmd * increment_1);
    }
    return value;
}

void svm_node_tex_musgrave()
{
    nio.dimension = max(nio.dimension, 9.9999997473787516355514526367188e-06);
    nio.detail = clamp(nio.detail, 0.0, 16.0);
    nio.lacunarity = max(nio.lacunarity, 9.9999997473787516355514526367188e-06);
    float fac;
    switch (nio.dimensions)
    {
        case 1u:
        {
            float p = nio.w * nio.scale;
            switch (nio.type)
            {
                case 0u:
                {
                    float param = p;
                    float param_1 = nio.dimension;
                    float param_2 = nio.lacunarity;
                    float param_3 = nio.detail;
                    fac = noise_musgrave_multi_fractal_1d(param, param_1, param_2, param_3);
                    break;
                }
                case 1u:
                {
                    float param_4 = p;
                    float param_5 = nio.dimension;
                    float param_6 = nio.lacunarity;
                    float param_7 = nio.detail;
                    fac = noise_musgrave_fBm_1d(param_4, param_5, param_6, param_7);
                    break;
                }
                case 2u:
                {
                    float param_8 = p;
                    float param_9 = nio.dimension;
                    float param_10 = nio.lacunarity;
                    float param_11 = nio.detail;
                    float param_12 = nio.foffset;
                    float param_13 = nio.gain;
                    fac = noise_musgrave_hybrid_multi_fractal_1d(param_8, param_9, param_10, param_11, param_12, param_13);
                    break;
                }
                case 3u:
                {
                    float param_14 = p;
                    float param_15 = nio.dimension;
                    float param_16 = nio.lacunarity;
                    float param_17 = nio.detail;
                    float param_18 = nio.foffset;
                    float param_19 = nio.gain;
                    fac = noise_musgrave_ridged_multi_fractal_1d(param_14, param_15, param_16, param_17, param_18, param_19);
                    break;
                }
                case 4u:
                {
                    float param_20 = p;
                    float param_21 = nio.dimension;
                    float param_22 = nio.lacunarity;
                    float param_23 = nio.detail;
                    float param_24 = nio.foffset;
                    fac = noise_musgrave_hetero_terrain_1d(param_20, param_21, param_22, param_23, param_24);
                    break;
                }
                default:
                {
                    fac = 0.0;
                    break;
                }
            }
            break;
        }
        case 2u:
        {
            vec2 p_1 = vec2(nio.co.x, nio.co.y) * nio.scale;
            switch (nio.type)
            {
                case 0u:
                {
                    vec2 param_25 = p_1;
                    float param_26 = nio.dimension;
                    float param_27 = nio.lacunarity;
                    float param_28 = nio.detail;
                    fac = noise_musgrave_multi_fractal_2d(param_25, param_26, param_27, param_28);
                    break;
                }
                case 1u:
                {
                    vec2 param_29 = p_1;
                    float param_30 = nio.dimension;
                    float param_31 = nio.lacunarity;
                    float param_32 = nio.detail;
                    fac = noise_musgrave_fBm_2d(param_29, param_30, param_31, param_32);
                    break;
                }
                case 2u:
                {
                    vec2 param_33 = p_1;
                    float param_34 = nio.dimension;
                    float param_35 = nio.lacunarity;
                    float param_36 = nio.detail;
                    float param_37 = nio.foffset;
                    float param_38 = nio.gain;
                    fac = noise_musgrave_hybrid_multi_fractal_2d(param_33, param_34, param_35, param_36, param_37, param_38);
                    break;
                }
                case 3u:
                {
                    vec2 param_39 = p_1;
                    float param_40 = nio.dimension;
                    float param_41 = nio.lacunarity;
                    float param_42 = nio.detail;
                    float param_43 = nio.foffset;
                    float param_44 = nio.gain;
                    fac = noise_musgrave_ridged_multi_fractal_2d(param_39, param_40, param_41, param_42, param_43, param_44);
                    break;
                }
                case 4u:
                {
                    vec2 param_45 = p_1;
                    float param_46 = nio.dimension;
                    float param_47 = nio.lacunarity;
                    float param_48 = nio.detail;
                    float param_49 = nio.foffset;
                    fac = noise_musgrave_hetero_terrain_2d(param_45, param_46, param_47, param_48, param_49);
                    break;
                }
                default:
                {
                    fac = 0.0;
                    break;
                }
            }
            break;
        }
        case 3u:
        {
            vec4 p_2 = vec4(nio.co, 0.0) * nio.scale;
            switch (nio.type)
            {
                case 0u:
                {
                    vec4 param_50 = p_2;
                    float param_51 = nio.dimension;
                    float param_52 = nio.lacunarity;
                    float param_53 = nio.detail;
                    fac = noise_musgrave_multi_fractal_3d(param_50, param_51, param_52, param_53);
                    break;
                }
                case 1u:
                {
                    vec4 param_54 = p_2;
                    float param_55 = nio.dimension;
                    float param_56 = nio.lacunarity;
                    float param_57 = nio.detail;
                    fac = noise_musgrave_fBm_3d(param_54, param_55, param_56, param_57);
                    break;
                }
                case 2u:
                {
                    vec4 param_58 = p_2;
                    float param_59 = nio.dimension;
                    float param_60 = nio.lacunarity;
                    float param_61 = nio.detail;
                    float param_62 = nio.foffset;
                    float param_63 = nio.gain;
                    fac = noise_musgrave_hybrid_multi_fractal_3d(param_58, param_59, param_60, param_61, param_62, param_63);
                    break;
                }
                case 3u:
                {
                    vec4 param_64 = p_2;
                    float param_65 = nio.dimension;
                    float param_66 = nio.lacunarity;
                    float param_67 = nio.detail;
                    float param_68 = nio.foffset;
                    float param_69 = nio.gain;
                    fac = noise_musgrave_ridged_multi_fractal_3d(param_64, param_65, param_66, param_67, param_68, param_69);
                    break;
                }
                case 4u:
                {
                    vec4 param_70 = p_2;
                    float param_71 = nio.dimension;
                    float param_72 = nio.lacunarity;
                    float param_73 = nio.detail;
                    float param_74 = nio.foffset;
                    fac = noise_musgrave_hetero_terrain_3d(param_70, param_71, param_72, param_73, param_74);
                    break;
                }
                default:
                {
                    fac = 0.0;
                    break;
                }
            }
            break;
        }
        case 4u:
        {
            vec4 p_3 = vec4(nio.co.x, nio.co.y, nio.co.z, nio.w) * nio.scale;
            switch (nio.type)
            {
                case 0u:
                {
                    vec4 param_75 = p_3;
                    float param_76 = nio.dimension;
                    float param_77 = nio.lacunarity;
                    float param_78 = nio.detail;
                    fac = noise_musgrave_multi_fractal_4d(param_75, param_76, param_77, param_78);
                    break;
                }
                case 1u:
                {
                    vec4 param_79 = p_3;
                    float param_80 = nio.dimension;
                    float param_81 = nio.lacunarity;
                    float param_82 = nio.detail;
                    fac = noise_musgrave_fBm_4d(param_79, param_80, param_81, param_82);
                    break;
                }
                case 2u:
                {
                    vec4 param_83 = p_3;
                    float param_84 = nio.dimension;
                    float param_85 = nio.lacunarity;
                    float param_86 = nio.detail;
                    float param_87 = nio.foffset;
                    float param_88 = nio.gain;
                    fac = noise_musgrave_hybrid_multi_fractal_4d(param_83, param_84, param_85, param_86, param_87, param_88);
                    break;
                }
                case 3u:
                {
                    vec4 param_89 = p_3;
                    float param_90 = nio.dimension;
                    float param_91 = nio.lacunarity;
                    float param_92 = nio.detail;
                    float param_93 = nio.foffset;
                    float param_94 = nio.gain;
                    fac = noise_musgrave_ridged_multi_fractal_4d(param_89, param_90, param_91, param_92, param_93, param_94);
                    break;
                }
                case 4u:
                {
                    vec4 param_95 = p_3;
                    float param_96 = nio.dimension;
                    float param_97 = nio.lacunarity;
                    float param_98 = nio.detail;
                    float param_99 = nio.foffset;
                    fac = noise_musgrave_hetero_terrain_4d(param_95, param_96, param_97, param_98, param_99);
                    break;
                }
                default:
                {
                    fac = 0.0;
                    break;
                }
            }
            break;
        }
        default:
        {
            fac = 0.0;
            break;
        }
    }
    nio.co.x = fac;
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
    svm_node_tex_musgrave();
}

