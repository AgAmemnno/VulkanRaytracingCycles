#version 460
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : require
#extension GL_EXT_shader_8bit_storage : require
#extension GL_EXT_shader_explicit_arithmetic_types_int16 : require
#extension GL_EXT_shader_16bit_storage : require
#extension GL_ARB_gpu_shader_int64 : require
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require

const uint _185[16] = uint[](4u, 3u, 2u, 2u, 1u, 1u, 1u, 1u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u);

struct ARG_RNG
{
    uint rng_hash;
    int sample_rsv;
    int num_samples;
    int dimension;
    uint type;
    int sampling;
    uint x;
    uint y;
    int seed;
};

layout(buffer_reference) buffer KernelTextures;
layout(buffer_reference) buffer _sample_pattern_lut_;
layout(buffer_reference, std430) buffer KernelTextures
{
    int64_t pad[28];
    _sample_pattern_lut_ _sample_pattern_lut;
};

layout(buffer_reference, std430) readonly buffer _sample_pattern_lut_
{
    uint data[];
};

layout(push_constant, std430) uniform PushData
{
    KernelTextures data_ptr;
} push;

layout(location = 2) callableDataInNV ARG_RNG arg;

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

float cmj_randfloat(uint i, uint p)
{
    uint param = i;
    uint param_1 = p;
    uint _588 = cmj_hash(param, param_1);
    return float(_588) * 2.3283061589829401327733648940921e-10;
}

uint cmj_hash_simple(inout uint i, uint p)
{
    i = (i ^ 61u) ^ p;
    i += (i << uint(3));
    i ^= (i >> uint(4));
    i *= 668265261u;
    return i;
}

float pmj_sample_1D(int sample_rsv, int rng_hash, int dimension)
{
    if (sample_rsv >= 4096)
    {
        int p = rng_hash + dimension;
        uint param = uint(sample_rsv);
        uint param_1 = uint(p);
        return cmj_randfloat(param, param_1);
    }
    else
    {
        uint param_2 = uint(dimension);
        uint param_3 = uint(rng_hash);
        uint _799 = cmj_hash_simple(param_2, param_3);
        uint mask_rsv = _799 & 8388607u;
        int index = ((((dimension % 48) * 64) * 64) + sample_rsv) * 2;
        return uintBitsToFloat(push.data_ptr._sample_pattern_lut.data[index] ^ mask_rsv) - 1.0;
    }
}

uint clz8(uint8_t x)
{
    uint upper = uint(x >> uint8_t(4));
    uint lower = uint(x & uint8_t(15));
    uint _180;
    if (upper != 0u)
    {
        _180 = _185[upper];
    }
    else
    {
        _180 = 4u + _185[lower];
    }
    return _180;
}

uint clz16(uint16_t x)
{
    uint8_t upper = uint8_t(x >> 8us);
    uint8_t lower = uint8_t(x & 255us);
    uint _215;
    if (int(uint(upper)) != 0)
    {
        uint8_t param = upper;
        _215 = clz8(param);
    }
    else
    {
        uint8_t param_1 = lower;
        _215 = 8u + clz8(param_1);
    }
    return _215;
}

uint count_leading_zeros(uint x)
{
    uint16_t upper = uint16_t(x >> 16u);
    uint16_t lower = uint16_t(x & 65535u);
    uint _242;
    if (int(uint(upper)) != 0)
    {
        uint16_t param = upper;
        _242 = clz16(param);
    }
    else
    {
        uint16_t param_1 = lower;
        _242 = 16u + clz16(param_1);
    }
    return _242;
}

uint cmj_w_mask(uint w)
{
    if (!(w > 1u))
    {
        // unimplemented ext op 12
    }
    uint param = w;
    return uint((1 << int(32u - count_leading_zeros(param))) - 1);
}

uint cmj_permute(inout uint i, uint l, uint p)
{
    uint w = l - 1u;
    if ((l & w) == 0u)
    {
        i ^= p;
        i *= 3782248765u;
        i ^= (p >> uint(16));
        i ^= ((i & w) >> uint(4));
        i ^= (p >> uint(8));
        i *= 153742143u;
        i ^= (p >> uint(23));
        i ^= ((i & w) >> uint(1));
        i *= (1u | (p >> uint(27)));
        i *= 1765145193u;
        i ^= ((i & w) >> uint(11));
        i *= 1960620803u;
        i ^= ((i & w) >> uint(2));
        i *= 2656050371u;
        i ^= ((i & w) >> uint(2));
        i *= 3361776607u;
        i &= w;
        i ^= (i >> uint(5));
        return (i + p) & w;
    }
    else
    {
        uint param = w;
        w = cmj_w_mask(param);
        do
        {
            i ^= p;
            i *= 3782248765u;
            i ^= (p >> uint(16));
            i ^= ((i & w) >> uint(4));
            i ^= (p >> uint(8));
            i *= 153742143u;
            i ^= (p >> uint(23));
            i ^= ((i & w) >> uint(1));
            i *= (1u | (p >> uint(27)));
            i *= 1765145193u;
            i ^= ((i & w) >> uint(11));
            i *= 1960620803u;
            i ^= ((i & w) >> uint(2));
            i *= 2656050371u;
            i ^= ((i & w) >> uint(2));
            i *= 3361776607u;
            i &= w;
            i ^= (i >> uint(5));
        } while (i >= l);
        return (i + p) % l;
    }
}

float cmj_sample_1D(int s, int N, int p)
{
    if (!(s < N))
    {
        // unimplemented ext op 12
    }
    uint param = uint(s);
    uint param_1 = uint(N);
    uint param_2 = uint(p * 1757159915);
    uint _614 = cmj_permute(param, param_1, param_2);
    uint x = _614;
    uint param_3 = uint(s);
    uint param_4 = uint(p * (-1770354533));
    float jx = cmj_randfloat(param_3, param_4);
    float invN = 1.0 / float(N);
    return (float(x) + jx) * invN;
}

uint find_first_set(uint x)
{
    uint _268;
    if (x != 0u)
    {
        uint param = x & (-x);
        _268 = 32u - count_leading_zeros(param);
    }
    else
    {
        _268 = 0u;
    }
    return _268;
}

uint sobol_dimension(int index, int dimension)
{
    uint result = 0u;
    uint i = uint(index + 64);
    int j = 0;
    int x;
    for (;;)
    {
        uint param = i;
        uint _1028 = find_first_set(param);
        int _1029 = int(_1028);
        x = _1029;
        if (_1029 != int(0u))
        {
            j += x;
            result ^= push.data_ptr._sample_pattern_lut.data[((32 * dimension) + j) - 1];
            i = i >> uint(x);
            continue;
        }
        else
        {
            break;
        }
    }
    return result;
}

float path_rng_1D(uint rng_hash)
{
    if (uint(arg.sampling) == 2u)
    {
        int param = arg.sample_rsv;
        int param_1 = int(rng_hash);
        int param_2 = arg.dimension;
        return pmj_sample_1D(param, param_1, param_2);
    }
    if (uint(arg.sampling) == 1u)
    {
        int p = int(rng_hash) + arg.dimension;
        int param_3 = arg.sample_rsv;
        int param_4 = arg.num_samples;
        int param_5 = p;
        return cmj_sample_1D(param_3, param_4, param_5);
    }
    int param_6 = arg.sample_rsv;
    int param_7 = arg.dimension;
    uint result = sobol_dimension(param_6, param_7);
    float r = float(result) * 2.3283064365386962890625e-10;
    uint param_8 = uint(arg.dimension);
    uint param_9 = rng_hash;
    uint _1117 = cmj_hash_simple(param_8, param_9);
    uint tmp_rng = _1117;
    float shift = float(tmp_rng) * 2.3283064365386962890625e-10;
    return (r + shift) - floor(r + shift);
}

vec2 pmj_sample_2D(int sample_rsv, int rng_hash, int dimension)
{
    if (sample_rsv >= 4096)
    {
        int p = rng_hash + dimension;
        uint param = uint(sample_rsv);
        uint param_1 = uint(p);
        float fx = cmj_randfloat(param, param_1);
        uint param_2 = uint(sample_rsv);
        uint param_3 = uint(p + 1);
        float fy = cmj_randfloat(param_2, param_3);
        return vec2(fx, fy);
    }
    else
    {
        int index = ((((dimension % 48) * 64) * 64) + sample_rsv) * 2;
        uint param_4 = uint(dimension);
        uint param_5 = uint(rng_hash);
        uint _884 = cmj_hash_simple(param_4, param_5);
        uint maskx = _884 & 8388607u;
        uint param_6 = uint(dimension + 1);
        uint param_7 = uint(rng_hash);
        uint _894 = cmj_hash_simple(param_6, param_7);
        uint masky = _894 & 8388607u;
        float fx_1 = uintBitsToFloat(push.data_ptr._sample_pattern_lut.data[index] ^ maskx) - 1.0;
        float fy_1 = uintBitsToFloat(push.data_ptr._sample_pattern_lut.data[index + 1] ^ masky) - 1.0;
        return vec2(fx_1, fy_1);
    }
}

int cmj_isqrt(int value)
{
    return int(sqrt(float(value)));
}

bool cmj_is_pow2(int i)
{
    bool _285 = i > 1;
    bool _293;
    if (_285)
    {
        _293 = (i & (i - 1)) == 0;
    }
    else
    {
        _293 = _285;
    }
    return _293;
}

uint count_trailing_zeros(uint x)
{
    uint param = x & (-x);
    return 31u - count_leading_zeros(param);
}

int cmj_fast_div_pow2(int a, int b)
{
    if (!(b > 1))
    {
        // unimplemented ext op 12
    }
    uint param = uint(b);
    return a >> int(count_trailing_zeros(param));
}

int cmj_fast_mod_pow2(int a, int b)
{
    return a & (b - 1);
}

void cmj_sample_2D(inout int s, int N, int p, out float fx, out float fy)
{
    if (!(s < N))
    {
        // unimplemented ext op 12
    }
    int param = N;
    int m = cmj_isqrt(param);
    int n = ((N - 1) / m) + 1;
    float invN = 1.0 / float(N);
    float invm = 1.0 / float(m);
    float invn = 1.0 / float(n);
    uint param_1 = uint(s);
    uint param_2 = uint(N);
    uint param_3 = uint(p * 1365458477);
    uint _685 = cmj_permute(param_1, param_2, param_3);
    s = int(_685);
    int param_4 = m;
    int sdivm;
    int smodm;
    if (cmj_is_pow2(param_4))
    {
        int param_5 = s;
        int param_6 = m;
        sdivm = cmj_fast_div_pow2(param_5, param_6);
        int param_7 = s;
        int param_8 = m;
        smodm = cmj_fast_mod_pow2(param_7, param_8);
    }
    else
    {
        sdivm = s / m;
        smodm = s - (sdivm * m);
    }
    uint param_9 = uint(smodm);
    uint param_10 = uint(m);
    uint param_11 = uint(p * 1757159915);
    uint _724 = cmj_permute(param_9, param_10, param_11);
    uint sx = _724;
    uint param_12 = uint(sdivm);
    uint param_13 = uint(n);
    uint param_14 = uint(p * 48610963);
    uint _737 = cmj_permute(param_12, param_13, param_14);
    uint sy = _737;
    uint param_15 = uint(s);
    uint param_16 = uint(p * (-1770354533));
    float jx = cmj_randfloat(param_15, param_16);
    uint param_17 = uint(s);
    uint param_18 = uint(p * 915196087);
    float jy = cmj_randfloat(param_17, param_18);
    fx = (float(sx) + ((float(sy) + jx) * invn)) * invm;
    fy = (float(s) + jy) * invN;
}

void path_rng_2D(uint rng_hash)
{
    if (uint(arg.sampling) == 2u)
    {
        int param = arg.sample_rsv;
        int param_1 = int(rng_hash);
        int param_2 = arg.dimension;
        vec2 f = pmj_sample_2D(param, param_1, param_2);
        arg.rng_hash = floatBitsToUint(f.x);
        arg.sample_rsv = floatBitsToInt(f.y);
        return;
    }
    if (uint(arg.sampling) == 1u)
    {
        int p = int(rng_hash) + arg.dimension;
        int param_3 = arg.sample_rsv;
        int param_4 = arg.num_samples;
        int param_5 = p;
        float fx;
        float param_6 = fx;
        float fy;
        float param_7 = fy;
        cmj_sample_2D(param_3, param_4, param_5, param_6, param_7);
        fx = param_6;
        fy = param_7;
        arg.rng_hash = floatBitsToUint(fx);
        arg.sample_rsv = floatBitsToInt(fy);
        return;
    }
    uint param_8 = rng_hash;
    arg.rng_hash = floatBitsToUint(path_rng_1D(param_8));
    arg.dimension++;
    uint param_9 = rng_hash;
    arg.sample_rsv = floatBitsToInt(path_rng_1D(param_9));
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
    switch (arg.type)
    {
        case 0u:
        {
            uint param = arg.rng_hash;
            arg.rng_hash = floatBitsToUint(path_rng_1D(param));
            break;
        }
        case 1u:
        {
            uint param_1 = arg.rng_hash;
            path_rng_2D(param_1);
            break;
        }
        case 2u:
        {
            uint param_2 = arg.x;
            uint param_3 = arg.y;
            arg.rng_hash = hash_uint2(param_2, param_3);
            arg.rng_hash ^= uint(arg.seed);
            arg.num_samples = int(arg.rng_hash);
            if (arg.sample_rsv == 0)
            {
                arg.rng_hash = floatBitsToUint(0.5);
                arg.sample_rsv = floatBitsToInt(0.5);
            }
            else
            {
                uint param_4 = arg.rng_hash;
                path_rng_2D(param_4);
            }
            break;
        }
        default:
        {
            break;
        }
    }
}

