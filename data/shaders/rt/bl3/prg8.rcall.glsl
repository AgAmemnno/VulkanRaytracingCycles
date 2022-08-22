#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require

struct NodeIO_BSDF
{
    int offset;
    uint type;
    int num_closure_left;
    int num_closure;
    int alloc_offset;
    int flag;
    vec3 I;
    vec3 N;
    float param1;
    float param2;
    vec3 weight;
    float specular;
    float roughness;
    float specular_tint;
    float anisotropic;
    float sheen;
    float sheen_tint;
    float clearcoat;
    float clearcoat_roughness;
    float transmission;
    float anisotropic_rotation;
    float transmission_roughness;
    float eta;
    uint type_dist;
    uint type_ssr;
    vec3 T;
    vec4 base_color;
    vec3 clearcoat_normal;
    vec3 subsurface_radius;
    vec3 subsurface_color;
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

layout(buffer_reference) buffer ShaderClosurePool;
layout(buffer_reference) buffer pool_sc_;
layout(buffer_reference, std430) buffer ShaderClosurePool
{
    pool_sc_ pool_sc;
};

layout(buffer_reference, scalar) buffer pool_sc_
{
    ShaderClosure data[];
};

layout(push_constant, std430) uniform PushData2
{
    layout(offset = 8) ShaderClosurePool pool_ptr;
} push2;

layout(location = 2) callableDataInNV NodeIO_BSDF nio;

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
int rec_num;

vec3 rotate_around_axis(vec3 p, vec3 axis, float angle)
{
    float costheta = cos(angle);
    float sintheta = sin(angle);
    vec3 r;
    r.x = (((costheta + (((1.0 - costheta) * axis.x) * axis.x)) * p.x) + (((((1.0 - costheta) * axis.x) * axis.y) - (axis.z * sintheta)) * p.y)) + (((((1.0 - costheta) * axis.x) * axis.z) + (axis.y * sintheta)) * p.z);
    r.y = ((((((1.0 - costheta) * axis.x) * axis.y) + (axis.z * sintheta)) * p.x) + ((costheta + (((1.0 - costheta) * axis.y) * axis.y)) * p.y)) + (((((1.0 - costheta) * axis.y) * axis.z) - (axis.x * sintheta)) * p.z);
    r.z = ((((((1.0 - costheta) * axis.x) * axis.z) - (axis.y * sintheta)) * p.x) + (((((1.0 - costheta) * axis.y) * axis.z) + (axis.x * sintheta)) * p.y)) + ((costheta + (((1.0 - costheta) * axis.z) * axis.z)) * p.z);
    return r;
}

float fresnel_dielectric_cos(float cosi, float eta)
{
    float c = abs(cosi);
    float g = ((eta * eta) - 1.0) + (c * c);
    if (g > 0.0)
    {
        g = sqrt(g);
        float A = (g - c) / (g + c);
        float B = ((c * (g + c)) - 1.0) / ((c * (g - c)) + 1.0);
        return ((0.5 * A) * A) * (1.0 + (B * B));
    }
    return 1.0;
}

float reduce_add(vec3 a)
{
    return (a.x + a.y) + a.z;
}

float average(vec3 a)
{
    return reduce_add(a) * 0.3333333432674407958984375;
}

int closure_alloc(uint type, vec4 weight)
{
    if (nio.num_closure_left == 0)
    {
        return -1;
    }
    if (nio.num_closure < 63)
    {
        nio.alloc_offset++;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight = 0.0;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(0.0);
        for (int _i_ = 0; _i_ < 25; _i_++)
        {
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[_i_] = 0.0;
        }
    }
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = type;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight = weight;
    nio.num_closure++;
    nio.num_closure_left--;
    return nio.alloc_offset;
}

int bsdf_alloc(uint size, vec3 weight)
{
    uint param = 0u;
    vec4 param_1 = vec4(weight, 0.0);
    uint param_2 = param;
    vec4 param_3 = param_1;
    int _645 = closure_alloc(param_2, param_3);
    int n = _645;
    if (n < 0)
    {
        return -1;
    }
    float sample_weight = abs(average(weight));
    push2.pool_ptr.pool_sc.data[n].sample_weight = sample_weight;
    return (sample_weight >= 9.9999997473787516355514526367188e-06) ? n : (-1);
}

int bsdf_principled_diffuse_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 5u;
    return 12;
}

int bssrdf_alloc(vec3 weight)
{
    uint param = 48u;
    vec4 param_1 = vec4(weight, 0.0);
    int _2598 = closure_alloc(param, param_1);
    int n = _2598;
    if (n < 0)
    {
        return -1;
    }
    float sample_weight = abs(average(weight));
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight = sample_weight;
    return (sample_weight >= 9.9999997473787516355514526367188e-06) ? n : (-1);
}

int bsdf_diffuse_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 2u;
    return 12;
}

vec3 bssrdf_burley_compatible_mfp(vec3 r)
{
    return r * 0.079577468335628509521484375;
}

float bssrdf_burley_fitting(float A)
{
    return (1.89999997615814208984375 - A) + ((3.5 * (A - 0.800000011920928955078125)) * (A - 0.800000011920928955078125));
}

void bssrdf_burley_setup()
{
    vec3 param = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2]);
    vec3 l = bssrdf_burley_compatible_mfp(param);
    vec3 A = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
    float param_1 = A.x;
    float param_2 = A.y;
    float param_3 = A.z;
    vec3 s = vec3(bssrdf_burley_fitting(param_1), bssrdf_burley_fitting(param_2), bssrdf_burley_fitting(param_3));
    vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2]);
    tmp = l / s;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = tmp.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = tmp.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = tmp.z;
}

int bssrdf_setup(uint type)
{
    int flag = 0;
    int bssrdf_channels = 3;
    vec3 diffuse_weight = vec3(0.0);
    int n0 = nio.alloc_offset;
    if (push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] < 9.9999999392252902907785028219223e-09)
    {
        diffuse_weight.x = push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight.x;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight.x = 0.0;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = 0.0;
        bssrdf_channels--;
    }
    if (push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] < 9.9999999392252902907785028219223e-09)
    {
        diffuse_weight.y = push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight.y;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight.y = 0.0;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = 0.0;
        bssrdf_channels--;
    }
    if (push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] < 9.9999999392252902907785028219223e-09)
    {
        diffuse_weight.z = push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight.z;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight.z = 0.0;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = 0.0;
        bssrdf_channels--;
    }
    if (bssrdf_channels < 3)
    {
        if ((type == 36u) || (type == 39u))
        {
            float roughness = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8];
            vec3 N = push2.pool_ptr.pool_sc.data[nio.alloc_offset].N.xyz;
            uint param = 4u;
            vec3 param_1 = diffuse_weight;
            int _2917 = bsdf_alloc(param, param_1);
            int n = _2917;
            if (n >= 0)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 32u;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(N, 0.0);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness;
                int _2950 = bsdf_principled_diffuse_setup();
                flag |= _2950;
            }
        }
        else
        {
            vec4 N_1 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].N;
            uint param_2 = 0u;
            vec3 param_3 = diffuse_weight;
            int _2967 = bsdf_alloc(param_2, param_3);
            int n_1 = _2967;
            if (n_1 >= 0)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 31u;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = N_1;
                int _2988 = bsdf_diffuse_setup();
                flag |= _2988;
            }
        }
    }
    int n1 = nio.alloc_offset;
    nio.alloc_offset = n0;
    if (bssrdf_channels > 0)
    {
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = type;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[9] = float(bssrdf_channels);
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight = abs(average(push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight.xyz)) * push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[9];
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], 0.0, 1.0);
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], 0.0, 1.0);
        if ((((type == 37u) || (type == 36u)) || (type == 38u)) || (type == 39u))
        {
            bssrdf_burley_setup();
        }
        flag |= 16;
    }
    else
    {
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = type;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight = 0.0;
    }
    nio.alloc_offset = n1;
    return flag;
}

float schlick_fresnel(float u)
{
    float m = clamp(1.0 - u, 0.0, 1.0);
    float m2 = m * m;
    return (m2 * m2) * m;
}

float calculate_avg_principled_sheen_brdf(vec3 N, vec3 I)
{
    float NdotI = dot(N, I);
    if (NdotI < 0.0)
    {
        return 0.0;
    }
    float param = NdotI;
    return schlick_fresnel(param) * NdotI;
}

int bsdf_principled_sheen_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 6u;
    vec3 param = push2.pool_ptr.pool_sc.data[nio.alloc_offset].N.xyz;
    vec3 param_1 = nio.I;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = calculate_avg_principled_sheen_brdf(param, param_1);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight *= push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0];
    return 12;
}

float safe_sqrtf(float f)
{
    return sqrt(max(f, 0.0));
}

vec3 saturate3(vec3 a)
{
    return clamp(a, vec3(0.0), vec3(1.0));
}

vec3 interpolate_fresnel_color(vec3 L, vec3 H, float ior, float F0, vec3 cspec0)
{
    float F0_norm = 1.0 / (1.0 - F0);
    float param = dot(L, H);
    float param_1 = ior;
    float FH = (fresnel_dielectric_cos(param, param_1) - F0) * F0_norm;
    return (cspec0 * (1.0 - FH)) + (vec3(1.0) * FH);
}

void bsdf_microfacet_fresnel_color()
{
    bool _1017 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].type == 15u;
    bool _1031;
    if (!_1017)
    {
        _1031 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].type == 27u;
    }
    else
    {
        _1031 = _1017;
    }
    bool _1045;
    if (!_1031)
    {
        _1045 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].type == 11u;
    }
    else
    {
        _1045 = _1031;
    }
    bool _1059;
    if (!_1045)
    {
        _1059 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].type == 12u;
    }
    else
    {
        _1059 = _1045;
    }
    if (!_1059)
    {
        // unimplemented ext op 12
    }
    float param = 1.0;
    float param_1 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2];
    float F0 = fresnel_dielectric_cos(param, param_1);
    vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[9], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[10], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[11]);
    vec3 param_2 = nio.I;
    vec3 param_3 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].N.xyz;
    float param_4 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2];
    float param_5 = F0;
    vec3 param_6 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    tmp = interpolate_fresnel_color(param_2, param_3, param_4, param_5, param_6);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[9] = tmp.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[10] = tmp.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[11] = tmp.z;
    if (push2.pool_ptr.pool_sc.data[nio.alloc_offset].type == 12u)
    {
        vec3 tmp_1 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[9], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[10], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[11]);
        tmp_1 *= (0.25 * push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12]);
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[9] = tmp_1.x;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[10] = tmp_1.y;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[11] = tmp_1.z;
    }
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight *= average(vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[9], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[10], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[11]));
}

int bsdf_microfacet_ggx_fresnel_setup()
{
    vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    vec3 param = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    tmp = saturate3(param);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp.z;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 11u;
    bsdf_microfacet_fresnel_color();
    return 12;
}

bool is_zero(vec3 a)
{
    bool _211 = a.x == 0.0;
    bool _226;
    if (!_211)
    {
        _226 = (int((floatBitsToUint(a.x) >> uint(23)) & 255u) - 127) < (-60);
    }
    else
    {
        _226 = _211;
    }
    bool _242;
    if (_226)
    {
        bool _230 = a.y == 0.0;
        bool _241;
        if (!_230)
        {
            _241 = (int((floatBitsToUint(a.y) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _241 = _230;
        }
        _242 = _241;
    }
    else
    {
        _242 = _226;
    }
    bool _258;
    if (_242)
    {
        bool _246 = a.z == 0.0;
        bool _257;
        if (!_246)
        {
            _257 = (int((floatBitsToUint(a.z) >> uint(23)) & 255u) - 127) < (-60);
        }
        else
        {
            _257 = _246;
        }
        _258 = _257;
    }
    else
    {
        _258 = _242;
    }
    return _258;
}

int bsdf_microfacet_multi_ggx_common_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 9.9999997473787516355514526367188e-05, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], 9.9999997473787516355514526367188e-05, 1.0);
    vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
    vec3 param = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
    tmp = saturate3(param);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp.z;
    vec3 tmp_1 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    vec3 param_1 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    tmp_1 = saturate3(param_1);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_1.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_1.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_1.z;
    return 1036;
}

int bsdf_microfacet_multi_ggx_fresnel_setup()
{
    if (is_zero(vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15])))
    {
        vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
        tmp = vec3(1.0, 0.0, 0.0);
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp.x;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp.y;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp.z;
    }
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 15u;
    bsdf_microfacet_fresnel_color();
    int _2117 = bsdf_microfacet_multi_ggx_common_setup();
    return _2117;
}

int bsdf_microfacet_ggx_refraction_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0];
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 23u;
    return 12;
}

int bsdf_microfacet_multi_ggx_glass_fresnel_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 9.9999997473787516355514526367188e-05, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0];
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = max(0.0, push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2]);
    vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
    vec3 param = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
    tmp = saturate3(param);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp.z;
    vec3 tmp_1 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    vec3 param_1 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    tmp_1 = saturate3(param_1);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_1.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_1.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_1.z;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 27u;
    bsdf_microfacet_fresnel_color();
    return 1036;
}

int bsdf_microfacet_ggx_clearcoat_setup()
{
    vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    vec3 param = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
    tmp = saturate3(param);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp.z;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0];
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 12u;
    bsdf_microfacet_fresnel_color();
    return 12;
}

int bsdf_oren_nayar_setup()
{
    float sigma = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0];
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 3u;
    sigma = clamp(sigma, 0.0, 1.0);
    float div = 1.0 / (3.1415927410125732421875 + (0.904129683971405029296875 * sigma));
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = 1.0 * div;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = sigma * div;
    return 12;
}

int bsdf_translucent_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 8u;
    return 12;
}

int bsdf_diffuse_toon_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 7u;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], 0.0, 1.0);
    return 12;
}

int bsdf_glossy_toon_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 19u;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], 0.0, 1.0);
    return 12;
}

void bsdf_transparent_setup(vec3 weight, uint path_flag)
{
    float sample_weight = abs(average(weight));
    if (!(sample_weight >= 9.9999997473787516355514526367188e-06))
    {
        return;
    }
    if ((uint(nio.flag) & 512u) != 0u)
    {
        nio.I += weight;
        float sum = 0.0;
        nio.alloc_offset -= nio.num_closure;
        for (int i = 0; i < nio.num_closure; i++)
        {
            nio.alloc_offset++;
            if (push2.pool_ptr.pool_sc.data[nio.alloc_offset].type == 33u)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].weight += vec4(weight, 0.0);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight += sample_weight;
                break;
            }
        }
    }
    else
    {
        nio.flag |= 516;
        nio.I = weight;
        if ((path_flag & 3145728u) != 0u)
        {
            nio.num_closure_left = 1;
        }
        uint param = 33u;
        vec4 param_1 = vec4(weight, 0.0);
        int _922 = closure_alloc(param, param_1);
        int n = _922;
        if (n >= 0)
        {
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].sample_weight = sample_weight;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
        }
        else
        {
            if ((path_flag & 3145728u) != 0u)
            {
                nio.num_closure_left = 0;
            }
        }
    }
}

int bsdf_ashikhmin_velvet_setup()
{
    float sigma = max(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.00999999977648258209228515625);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = 1.0 / (sigma * sigma);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 17u;
    return 12;
}

int bsdf_refraction_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 21u;
    return 4;
}

float sqr(float a)
{
    return a * a;
}

int bsdf_microfacet_beckmann_refraction_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0];
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 22u;
    return 12;
}

int bsdf_reflection_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 9u;
    return 4;
}

int bsdf_microfacet_beckmann_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 13u;
    return 12;
}

int bsdf_microfacet_ggx_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], 0.0, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 10u;
    return 12;
}

void svm_node_glass_setup(int type, float eta, float roughness, bool _refract)
{
    if (uint(type) == 28u)
    {
        if (_refract)
        {
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = 0.0;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = 0.0;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = eta;
            int _3147 = bsdf_refraction_setup();
            nio.flag |= _3147;
        }
        else
        {
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = 0.0;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = 0.0;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = 0.0;
            int _3174 = bsdf_reflection_setup();
            nio.flag |= _3174;
        }
    }
    else
    {
        if (uint(type) == 25u)
        {
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = roughness;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = eta;
            if (_refract)
            {
                int _3212 = bsdf_microfacet_beckmann_refraction_setup();
                nio.flag |= _3212;
            }
            else
            {
                int _3218 = bsdf_microfacet_beckmann_setup();
                nio.flag |= _3218;
            }
        }
        else
        {
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = roughness;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = eta;
            if (_refract)
            {
                int _3251 = bsdf_microfacet_ggx_refraction_setup();
                nio.flag |= _3251;
            }
            else
            {
                int _3257 = bsdf_microfacet_ggx_setup();
                nio.flag |= _3257;
            }
        }
    }
}

int bsdf_microfacet_multi_ggx_glass_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 9.9999997473787516355514526367188e-05, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0];
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = max(0.0, push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2]);
    vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
    vec3 param = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
    tmp = saturate3(param);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp.x;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp.y;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp.z;
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 24u;
    return 1036;
}

int bsdf_microfacet_multi_ggx_setup()
{
    if (is_zero(vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15])))
    {
        vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
        tmp = vec3(1.0, 0.0, 0.0);
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp.x;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp.y;
        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp.z;
    }
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 14u;
    int _2025 = bsdf_microfacet_multi_ggx_common_setup();
    return _2025;
}

int bsdf_ashikhmin_shirley_setup()
{
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], 9.9999997473787516355514526367188e-05, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = clamp(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], 9.9999997473787516355514526367188e-05, 1.0);
    push2.pool_ptr.pool_sc.data[nio.alloc_offset].type = 16u;
    return 12;
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
    bool caustics = ((uint(nio.num_closure_left) >> 16u) & 1u) != 0u;
    rec_num = nio.num_closure >> int(16u);
    bool raydiff = (uint(nio.offset) & 8u) != 0u;
    nio.num_closure_left = int(uint(nio.num_closure_left) & 65535u);
    nio.num_closure = int(uint(nio.num_closure) & 65535u);
    switch (nio.type)
    {
        case 44u:
        {
            float metallic = nio.param1;
            float subsurface = nio.param2;
            float m_cdlum_gray = nio.base_color.w;
            vec3 base_color = nio.base_color.xyz;
            if (!(nio.anisotropic_rotation == 0.0))
            {
                vec3 param = nio.T;
                vec3 param_1 = nio.N;
                float param_2 = nio.anisotropic_rotation * 6.283185482025146484375;
                nio.T = rotate_around_axis(param, param_1, param_2);
            }
            float _3349;
            if ((uint(nio.flag) & 1u) != 0u)
            {
                _3349 = 1.0 / nio.eta;
            }
            else
            {
                _3349 = nio.eta;
            }
            float ior = _3349;
            float cosNO = dot(nio.N, nio.I);
            float param_3 = cosNO;
            float param_4 = ior;
            float fresnel = fresnel_dielectric_cos(param_3, param_4);
            float diffuse_weight = (1.0 - clamp(metallic, 0.0, 1.0)) * (1.0 - clamp(nio.transmission, 0.0, 1.0));
            float final_transmission = clamp(nio.transmission, 0.0, 1.0) * (1.0 - clamp(metallic, 0.0, 1.0));
            float specular_weight = 1.0 - final_transmission;
            vec3 mixed_ss_base_color = (nio.subsurface_color * subsurface) + (base_color * (1.0 - subsurface));
            vec3 subsurf_weight = (nio.weight * mixed_ss_base_color) * diffuse_weight;
            if ((uint(nio.offset) & 32768u) != 0u)
            {
                subsurface = 0.0;
                base_color = mixed_ss_base_color;
            }
            if (abs(average(mixed_ss_base_color)) > 9.9999997473787516355514526367188e-06)
            {
                if ((subsurface <= 9.9999997473787516355514526367188e-06) && (diffuse_weight > 9.9999997473787516355514526367188e-06))
                {
                    vec3 diff_weight = (nio.weight * base_color) * diffuse_weight;
                    uint param_5 = 4u;
                    vec3 param_6 = diff_weight;
                    int _3444 = bsdf_alloc(param_5, param_6);
                    int n = _3444;
                    if (n >= 0)
                    {
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = nio.roughness;
                        int _3471 = bsdf_principled_diffuse_setup();
                        nio.flag |= _3471;
                    }
                }
                else
                {
                    if (subsurface > 9.9999997473787516355514526367188e-06)
                    {
                        vec3 param_7 = subsurf_weight;
                        int _3484 = bssrdf_alloc(param_7);
                        int n_1 = _3484;
                        if (n_1 >= 0)
                        {
                            vec3 tmp = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2]);
                            tmp = nio.subsurface_radius * subsurface;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = tmp.x;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = tmp.y;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = tmp.z;
                            vec3 tmp_1 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
                            vec3 _3577;
                            if (nio.type_ssr == 36u)
                            {
                                _3577 = nio.subsurface_color;
                            }
                            else
                            {
                                _3577 = mixed_ss_base_color;
                            }
                            tmp_1 = _3577;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_1.x;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_1.y;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_1.z;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = 0.0;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = 0.0;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = nio.roughness;
                            uint param_8 = nio.type_ssr;
                            int _3651 = bssrdf_setup(param_8);
                            nio.flag |= _3651;
                        }
                    }
                }
            }
            bool _3657 = diffuse_weight > 9.9999997473787516355514526367188e-06;
            bool _3663;
            if (_3657)
            {
                _3663 = nio.sheen > 9.9999997473787516355514526367188e-06;
            }
            else
            {
                _3663 = _3657;
            }
            if (_3663)
            {
                float m_cdlum = m_cdlum_gray;
                vec3 _3671;
                if (m_cdlum > 0.0)
                {
                    _3671 = base_color / vec3(m_cdlum);
                }
                else
                {
                    _3671 = vec3(1.0);
                }
                vec3 m_ctint = _3671;
                vec3 sheen_color = (vec3(1.0) * (1.0 - nio.sheen_tint)) + (m_ctint * nio.sheen_tint);
                vec3 sheen_weight = ((nio.weight * nio.sheen) * sheen_color) * diffuse_weight;
                uint param_9 = 4u;
                vec3 param_10 = sheen_weight;
                int _3704 = bsdf_alloc(param_9, param_10);
                int n_2 = _3704;
                if (n_2 >= 0)
                {
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                    int _3722 = bsdf_principled_sheen_setup();
                    nio.flag |= _3722;
                }
            }
            if (caustics || (!raydiff))
            {
                bool _3734 = specular_weight > 9.9999997473787516355514526367188e-06;
                bool _3743;
                if (_3734)
                {
                    _3743 = (nio.specular > 9.9999997473787516355514526367188e-06) || (metallic > 9.9999997473787516355514526367188e-06);
                }
                else
                {
                    _3743 = _3734;
                }
                if (_3743)
                {
                    vec3 spec_weight = nio.weight * specular_weight;
                    uint param_11 = 64u;
                    vec3 param_12 = spec_weight;
                    int _3756 = bsdf_alloc(param_11, param_12);
                    int n_3 = _3756;
                    if (n_3 >= 0)
                    {
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                        float param_13 = 0.07999999821186065673828125 * nio.specular;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = (2.0 / (1.0 - safe_sqrtf(param_13))) - 1.0;
                        vec3 tmp_2 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                        tmp_2 = nio.T;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_2.x;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_2.y;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_2.z;
                        float param_14 = 1.0 - (nio.anisotropic * 0.89999997615814208984375);
                        float aspect = safe_sqrtf(param_14);
                        float r2 = nio.roughness * nio.roughness;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = r2 / aspect;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = r2 * aspect;
                        float m_cdlum_1 = ((0.300000011920928955078125 * base_color.x) + (0.60000002384185791015625 * base_color.y)) + (0.100000001490116119384765625 * base_color.z);
                        vec3 _3898;
                        if (m_cdlum_1 > 0.0)
                        {
                            _3898 = base_color / vec3(m_cdlum_1);
                        }
                        else
                        {
                            _3898 = vec3(0.0);
                        }
                        vec3 m_ctint_1 = _3898;
                        vec3 tmp_col = (vec3(1.0) * (1.0 - nio.specular_tint)) + (m_ctint_1 * nio.specular_tint);
                        vec3 tmp_3 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
                        tmp_3 = ((tmp_col * (nio.specular * 0.07999999821186065673828125)) * (1.0 - metallic)) + (base_color * metallic);
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_3.x;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_3.y;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_3.z;
                        vec3 tmp_4 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
                        tmp_4 = base_color;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_4.x;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_4.y;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_4.z;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 0.0;
                        bool _4046 = nio.type_dist == 26u;
                        bool _4054;
                        if (!_4046)
                        {
                            _4054 = nio.roughness <= 0.07500000298023223876953125;
                        }
                        else
                        {
                            _4054 = _4046;
                        }
                        if (_4054)
                        {
                            int _4057 = bsdf_microfacet_ggx_fresnel_setup();
                            nio.flag |= _4057;
                        }
                        else
                        {
                            int _4063 = bsdf_microfacet_multi_ggx_fresnel_setup();
                            nio.flag |= _4063;
                        }
                    }
                }
            }
            if (caustics || (!raydiff))
            {
                if (final_transmission > 9.9999997473787516355514526367188e-06)
                {
                    vec3 glass_weight = nio.weight * final_transmission;
                    vec3 cspec0 = (base_color * nio.specular_tint) + (vec3(1.0) * (1.0 - nio.specular_tint));
                    bool _4096 = nio.roughness <= 0.0500000007450580596923828125;
                    bool _4103;
                    if (!_4096)
                    {
                        _4103 = nio.type_dist == 26u;
                    }
                    else
                    {
                        _4103 = _4096;
                    }
                    if (_4103)
                    {
                        float refl_roughness = nio.roughness;
                        if (caustics)
                        {
                            uint param_15 = 64u;
                            vec3 param_16 = glass_weight * fresnel;
                            int _4118 = bsdf_alloc(param_15, param_16);
                            int n_4 = _4118;
                            if (n_4 >= 0)
                            {
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                                vec3 tmp_5 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                                tmp_5 = vec3(0.0);
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_5.x;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_5.y;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_5.z;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = refl_roughness * refl_roughness;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = refl_roughness * refl_roughness;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = ior;
                                vec3 tmp_6 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
                                tmp_6 = base_color;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_6.x;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_6.y;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_6.z;
                                vec3 tmp_7 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
                                tmp_7 = cspec0;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_7.x;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_7.y;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_7.z;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 0.0;
                                int _4332 = bsdf_microfacet_ggx_fresnel_setup();
                                nio.flag |= _4332;
                            }
                        }
                        if (caustics)
                        {
                            uint param_17 = 64u;
                            vec3 param_18 = (base_color * glass_weight) * (1.0 - fresnel);
                            int _4349 = bsdf_alloc(param_17, param_18);
                            int n_5 = _4349;
                            if (n_5 >= 0)
                            {
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                                vec3 tmp_8 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                                tmp_8 = vec3(0.0);
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_8.x;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_8.y;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_8.z;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
                                if (nio.type_dist == 26u)
                                {
                                    nio.transmission_roughness = 1.0 - ((1.0 - refl_roughness) * (1.0 - nio.transmission_roughness));
                                }
                                else
                                {
                                    nio.transmission_roughness = refl_roughness;
                                }
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = nio.transmission_roughness * nio.transmission_roughness;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = nio.transmission_roughness * nio.transmission_roughness;
                                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = ior;
                                int _4483 = bsdf_microfacet_ggx_refraction_setup();
                                nio.flag |= _4483;
                            }
                        }
                    }
                    else
                    {
                        uint param_19 = 64u;
                        vec3 param_20 = glass_weight;
                        int _4493 = bsdf_alloc(param_19, param_20);
                        int n_6 = _4493;
                        if (n_6 >= 0)
                        {
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                            vec3 tmp_9 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                            tmp_9 = vec3(0.0);
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_9.x;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_9.y;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_9.z;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = nio.roughness * nio.roughness;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = nio.roughness * nio.roughness;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = ior;
                            vec3 tmp_10 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
                            tmp_10 = base_color;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_10.x;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_10.y;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_10.z;
                            vec3 tmp_11 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
                            tmp_11 = cspec0;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_11.x;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_11.y;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_11.z;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 0.0;
                            int _4711 = bsdf_microfacet_multi_ggx_glass_fresnel_setup();
                            nio.flag |= _4711;
                        }
                    }
                }
            }
            if (caustics || (!raydiff))
            {
                if (nio.clearcoat > 9.9999997473787516355514526367188e-06)
                {
                    uint param_21 = 64u;
                    vec3 param_22 = nio.weight;
                    int _4733 = bsdf_alloc(param_21, param_22);
                    int n_7 = _4733;
                    if (n_7 >= 0)
                    {
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.clearcoat_normal, 0.0);
                        vec3 tmp_12 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                        tmp_12 = vec3(0.0);
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_12.x;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_12.y;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_12.z;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = 1.5;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = nio.clearcoat_roughness * nio.clearcoat_roughness;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = nio.clearcoat_roughness * nio.clearcoat_roughness;
                        vec3 tmp_13 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
                        tmp_13 = vec3(0.0);
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_13.x;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_13.y;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_13.z;
                        vec3 tmp_14 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
                        tmp_14 = vec3(0.039999999105930328369140625);
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_14.x;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_14.y;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_14.z;
                        push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = nio.clearcoat;
                        int _4955 = bsdf_microfacet_ggx_clearcoat_setup();
                        nio.flag |= _4955;
                    }
                }
            }
            break;
        }
        case 2u:
        {
            uint param_23 = 12u;
            vec3 param_24 = nio.weight;
            int _4966 = bsdf_alloc(param_23, param_24);
            int n_8 = _4966;
            if (n_8 >= 0)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                float roughness = nio.param1;
                if (roughness == 0.0)
                {
                    int _4991 = bsdf_diffuse_setup();
                    nio.flag |= _4991;
                }
                else
                {
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness;
                    int _5005 = bsdf_oren_nayar_setup();
                    nio.flag |= _5005;
                }
            }
            break;
        }
        case 8u:
        {
            uint param_25 = 12u;
            vec3 param_26 = nio.weight;
            int _5016 = bsdf_alloc(param_25, param_26);
            int n_9 = _5016;
            if (n_9 >= 0)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                int _5034 = bsdf_translucent_setup();
                nio.flag |= _5034;
            }
            break;
        }
        case 19u:
        case 7u:
        {
            uint param_27 = 8u;
            vec3 param_28 = nio.weight;
            int _5045 = bsdf_alloc(param_27, param_28);
            int n_10 = _5045;
            if (n_10 >= 0)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = nio.param1;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = nio.param2;
                if (nio.type == 7u)
                {
                    int _5086 = bsdf_diffuse_toon_setup();
                    nio.flag |= _5086;
                }
                else
                {
                    int _5092 = bsdf_glossy_toon_setup();
                    nio.flag |= _5092;
                }
            }
            break;
        }
        case 33u:
        {
            uint param_29 = uint(nio.offset);
            bsdf_transparent_setup(nio.weight, param_29);
            break;
        }
        case 17u:
        {
            uint param_30 = 8u;
            vec3 param_31 = nio.weight;
            int _5111 = bsdf_alloc(param_30, param_31);
            int n_11 = _5111;
            if (n_11 >= 0)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = clamp(nio.param1, 0.0, 1.0);
                int _5139 = bsdf_ashikhmin_velvet_setup();
                nio.flag |= _5139;
            }
            break;
        }
        case 21u:
        case 23u:
        case 22u:
        {
            uint param_32 = 64u;
            vec3 param_33 = nio.weight;
            int _5150 = bsdf_alloc(param_32, param_33);
            int n_12 = _5150;
            if (n_12 >= 0)
            {
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                vec3 tmp_15 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                tmp_15 = vec3(0.0);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_15.x;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_15.y;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_15.z;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
                float eta = max(nio.param2, 9.9999997473787516355514526367188e-06);
                float _5244;
                if ((uint(nio.flag) & 1u) != 0u)
                {
                    _5244 = 1.0 / eta;
                }
                else
                {
                    _5244 = eta;
                }
                eta = _5244;
                if (nio.type == 21u)
                {
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = 0.0;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = 0.0;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = eta;
                    int _5279 = bsdf_refraction_setup();
                    nio.flag |= _5279;
                }
                else
                {
                    float param_34 = nio.param1;
                    float roughness_1 = sqr(param_34);
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness_1;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = roughness_1;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = eta;
                    if (nio.type == 22u)
                    {
                        int _5319 = bsdf_microfacet_beckmann_refraction_setup();
                        nio.flag |= _5319;
                    }
                    else
                    {
                        int _5325 = bsdf_microfacet_ggx_refraction_setup();
                        nio.flag |= _5325;
                    }
                }
            }
            break;
        }
        case 28u:
        case 26u:
        case 25u:
        {
            float eta_1 = max(nio.param2, 9.9999997473787516355514526367188e-06);
            float _5340;
            if ((uint(nio.flag) & 1u) != 0u)
            {
                _5340 = 1.0 / eta_1;
            }
            else
            {
                _5340 = eta_1;
            }
            eta_1 = _5340;
            float cosNO_1 = dot(nio.N, nio.I);
            float param_35 = cosNO_1;
            float param_36 = eta_1;
            float fresnel_1 = fresnel_dielectric_cos(param_35, param_36);
            float param_37 = nio.param1;
            float roughness_2 = sqr(param_37);
            if (caustics || (!raydiff))
            {
                uint param_38 = 64u;
                vec3 param_39 = nio.weight * fresnel_1;
                int _5378 = bsdf_alloc(param_38, param_39);
                int n_13 = _5378;
                if (n_13 >= 0)
                {
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                    vec3 tmp_16 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                    tmp_16 = vec3(0.0);
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_16.x;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_16.y;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_16.z;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
                    int param_40 = int(nio.type);
                    float param_41 = eta_1;
                    float param_42 = roughness_2;
                    bool param_43 = false;
                    svm_node_glass_setup(param_40, param_41, param_42, param_43);
                }
            }
            if (caustics || (!raydiff))
            {
                uint param_44 = 64u;
                vec3 param_45 = nio.weight * (1.0 - fresnel_1);
                int _5488 = bsdf_alloc(param_44, param_45);
                int n_14 = _5488;
                if (n_14 >= 0)
                {
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                    vec3 tmp_17 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                    tmp_17 = vec3(0.0);
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_17.x;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_17.y;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_17.z;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
                    int param_46 = int(nio.type);
                    float param_47 = eta_1;
                    float param_48 = roughness_2;
                    bool param_49 = true;
                    svm_node_glass_setup(param_46, param_47, param_48, param_49);
                }
            }
            break;
        }
        case 24u:
        {
            uint param_50 = 64u;
            vec3 param_51 = nio.weight;
            int _5590 = bsdf_alloc(param_50, param_51);
            int n_15 = _5590;
            if (n_15 < 0)
            {
                break;
            }
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
            vec3 tmp_18 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
            tmp_18 = vec3(0.0);
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_18.x;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_18.y;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_18.z;
            float param_52 = nio.param1;
            float roughness_3 = sqr(param_52);
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness_3;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = roughness_3;
            float eta_2 = max(nio.param2, 9.9999997473787516355514526367188e-06);
            float _5698;
            if ((uint(nio.flag) & 1u) != 0u)
            {
                _5698 = 1.0 / eta_2;
            }
            else
            {
                _5698 = eta_2;
            }
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = _5698;
            vec3 tmp_19 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
            tmp_19 = nio.base_color.xyz;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_19.x;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_19.y;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_19.z;
            vec3 tmp_20 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
            tmp_20 = vec3(0.0);
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_20.x;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_20.y;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_20.z;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 0.0;
            int _5823 = bsdf_microfacet_multi_ggx_glass_setup();
            nio.flag |= _5823;
            break;
        }
        case 9u:
        case 10u:
        case 13u:
        case 16u:
        case 14u:
        {
            uint param_53 = 64u;
            vec3 param_54 = nio.weight;
            int _5834 = bsdf_alloc(param_53, param_54);
            int n_16 = _5834;
            if (n_16 < 0)
            {
                break;
            }
            float param_55 = nio.param1;
            float roughness_4 = sqr(param_55);
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = 0.0;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = 1.1754943508222875079687365372222e-38;
            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 1.1754943508222875079687365372222e-38;
            if (nio.type_dist == 255u)
            {
                vec3 tmp_21 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                tmp_21 = vec3(0.0);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_21.x;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_21.y;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_21.z;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness_4;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = roughness_4;
            }
            else
            {
                vec3 tmp_22 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                tmp_22 = nio.T;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_22.x;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_22.y;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_22.z;
                float rotation = nio.specular;
                if (!(rotation == 0.0))
                {
                    vec3 tmp_23 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                    vec3 param_56 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15]);
                    vec3 param_57 = push2.pool_ptr.pool_sc.data[nio.alloc_offset].N.xyz;
                    float param_58 = rotation * 6.283185482025146484375;
                    tmp_23 = rotate_around_axis(param_56, param_57, param_58);
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[13] = tmp_23.x;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[14] = tmp_23.y;
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[15] = tmp_23.z;
                }
                float anisotropy = clamp(nio.param2, -0.9900000095367431640625, 0.9900000095367431640625);
                if (anisotropy < 0.0)
                {
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness_4 / (1.0 + anisotropy);
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = roughness_4 * (1.0 + anisotropy);
                }
                else
                {
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = roughness_4 * (1.0 - anisotropy);
                    push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = roughness_4 / (1.0 - anisotropy);
                }
            }
            if (nio.type == 9u)
            {
                int _6169 = bsdf_reflection_setup();
                nio.flag |= _6169;
            }
            else
            {
                if (nio.type == 13u)
                {
                    int _6180 = bsdf_microfacet_beckmann_setup();
                    nio.flag |= _6180;
                }
                else
                {
                    if (nio.type == 10u)
                    {
                        int _6191 = bsdf_microfacet_ggx_setup();
                        nio.flag |= _6191;
                    }
                    else
                    {
                        if (nio.type == 14u)
                        {
                            vec3 tmp_24 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
                            tmp_24 = nio.base_color.xyz;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_24.x;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_24.y;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_24.z;
                            vec3 tmp_25 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8]);
                            tmp_25 = vec3(0.0);
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = tmp_25.x;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = tmp_25.y;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = tmp_25.z;
                            push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[12] = 0.0;
                            int _6318 = bsdf_microfacet_multi_ggx_setup();
                            nio.flag |= _6318;
                        }
                        else
                        {
                            int _6324 = bsdf_ashikhmin_shirley_setup();
                            nio.flag |= _6324;
                        }
                    }
                }
            }
            break;
        }
        case 34u:
        case 35u:
        case 37u:
        case 38u:
        {
            vec3 param_59 = nio.weight;
            int _6334 = bssrdf_alloc(param_59);
            int n_17 = _6334;
            if (n_17 >= 0)
            {
                if ((uint(nio.offset) & 32768u) != 0u)
                {
                    nio.param1 = 0.0;
                }
                vec3 tmp_26 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2]);
                tmp_26 = nio.I * nio.param1;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[0] = tmp_26.x;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[1] = tmp_26.y;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[2] = tmp_26.z;
                vec3 tmp_27 = vec3(push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4], push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5]);
                tmp_27 = nio.weight / vec3(nio.specular);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[3] = tmp_27.x;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[4] = tmp_27.y;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[5] = tmp_27.z;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[7] = nio.param2;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[6] = nio.roughness;
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].N = vec4(nio.N, 0.0);
                push2.pool_ptr.pool_sc.data[nio.alloc_offset].data[8] = 0.0;
                uint param_60 = nio.type;
                int _6505 = bssrdf_setup(param_60);
                nio.flag |= _6505;
            }
            break;
        }
        default:
        {
            break;
        }
    }
    memoryBarrierBuffer();
}

