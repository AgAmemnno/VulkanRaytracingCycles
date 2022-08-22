#version 460
#extension GL_NV_ray_tracing : require

struct NodeIO_Utils
{
    int offset;
    uint type;
    uint type2;
    float fac;
    vec3 c1;
    vec3 c2;
};

layout(location = 2) callableDataInNV NodeIO_Utils nio;

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

vec3 svm_mix_blend(float t, vec3 col1, vec3 col2)
{
    return mix(col1, col2, vec3(t));
}

vec3 svm_mix_add(float t, vec3 col1, vec3 col2)
{
    return mix(col1, col1 + col2, vec3(t));
}

vec3 svm_mix_mul(float t, vec3 col1, vec3 col2)
{
    return mix(col1, col1 * col2, vec3(t));
}

vec3 svm_mix_screen(float t, vec3 col1, vec3 col2)
{
    float tm = 1.0 - t;
    vec3 one = vec3(1.0);
    vec3 tm3 = vec3(tm, tm, tm);
    return one - ((tm3 + ((one - col2) * t)) * (one - col1));
}

vec3 svm_mix_overlay(float t, vec3 col1, vec3 col2)
{
    float tm = 1.0 - t;
    vec3 outcol = col1;
    if (outcol.x < 0.5)
    {
        outcol.x *= (tm + ((2.0 * t) * col2.x));
    }
    else
    {
        outcol.x = 1.0 - ((tm + ((2.0 * t) * (1.0 - col2.x))) * (1.0 - outcol.x));
    }
    if (outcol.y < 0.5)
    {
        outcol.y *= (tm + ((2.0 * t) * col2.y));
    }
    else
    {
        outcol.y = 1.0 - ((tm + ((2.0 * t) * (1.0 - col2.y))) * (1.0 - outcol.y));
    }
    if (outcol.z < 0.5)
    {
        outcol.z *= (tm + ((2.0 * t) * col2.z));
    }
    else
    {
        outcol.z = 1.0 - ((tm + ((2.0 * t) * (1.0 - col2.z))) * (1.0 - outcol.z));
    }
    return outcol;
}

vec3 svm_mix_sub(float t, vec3 col1, vec3 col2)
{
    return mix(col1, col1 - col2, vec3(t));
}

vec3 svm_mix_div(float t, vec3 col1, vec3 col2)
{
    float tm = 1.0 - t;
    vec3 outcol = col1;
    if (!(col2.x == 0.0))
    {
        outcol.x = (tm * outcol.x) + ((t * outcol.x) / col2.x);
    }
    if (!(col2.y == 0.0))
    {
        outcol.y = (tm * outcol.y) + ((t * outcol.y) / col2.y);
    }
    if (!(col2.z == 0.0))
    {
        outcol.z = (tm * outcol.z) + ((t * outcol.z) / col2.z);
    }
    return outcol;
}

vec3 svm_mix_diff(float t, vec3 col1, vec3 col2)
{
    return mix(col1, abs(col1 - col2), vec3(t));
}

vec3 svm_mix_dark(float t, vec3 col1, vec3 col2)
{
    return mix(col1, min(col1, col2), vec3(t));
}

vec3 svm_mix_light(float t, vec3 col1, vec3 col2)
{
    return mix(col1, max(col1, col2), vec3(t));
}

vec3 svm_mix_dodge(float t, vec3 col1, vec3 col2)
{
    vec3 outcol = col1;
    if (!(outcol.x == 0.0))
    {
        float tmp = 1.0 - (t * col2.x);
        if (tmp <= 0.0)
        {
            outcol.x = 1.0;
        }
        else
        {
            float _670 = tmp;
            float _671 = outcol.x / _670;
            tmp = _671;
            if (_671 > 1.0)
            {
                outcol.x = 1.0;
            }
            else
            {
                outcol.x = tmp;
            }
        }
    }
    if (!(outcol.y == 0.0))
    {
        float tmp_1 = 1.0 - (t * col2.y);
        if (tmp_1 <= 0.0)
        {
            outcol.y = 1.0;
        }
        else
        {
            float _698 = tmp_1;
            float _699 = outcol.y / _698;
            tmp_1 = _699;
            if (_699 > 1.0)
            {
                outcol.y = 1.0;
            }
            else
            {
                outcol.y = tmp_1;
            }
        }
    }
    if (!(outcol.z == 0.0))
    {
        float tmp_2 = 1.0 - (t * col2.z);
        if (tmp_2 <= 0.0)
        {
            outcol.z = 1.0;
        }
        else
        {
            float _726 = tmp_2;
            float _727 = outcol.z / _726;
            tmp_2 = _727;
            if (_727 > 1.0)
            {
                outcol.z = 1.0;
            }
            else
            {
                outcol.z = tmp_2;
            }
        }
    }
    return outcol;
}

vec3 svm_mix_burn(float t, vec3 col1, vec3 col2)
{
    float tm = 1.0 - t;
    vec3 outcol = col1;
    float tmp = tm + (t * col2.x);
    if (tmp <= 0.0)
    {
        outcol.x = 0.0;
    }
    else
    {
        float _759 = tmp;
        float _761 = 1.0 - ((1.0 - outcol.x) / _759);
        tmp = _761;
        if (_761 < 0.0)
        {
            outcol.x = 0.0;
        }
        else
        {
            if (tmp > 1.0)
            {
                outcol.x = 1.0;
            }
            else
            {
                outcol.x = tmp;
            }
        }
    }
    tmp = tm + (t * col2.y);
    if (tmp <= 0.0)
    {
        outcol.y = 0.0;
    }
    else
    {
        float _790 = tmp;
        float _792 = 1.0 - ((1.0 - outcol.y) / _790);
        tmp = _792;
        if (_792 < 0.0)
        {
            outcol.y = 0.0;
        }
        else
        {
            if (tmp > 1.0)
            {
                outcol.y = 1.0;
            }
            else
            {
                outcol.y = tmp;
            }
        }
    }
    tmp = tm + (t * col2.z);
    if (tmp <= 0.0)
    {
        outcol.z = 0.0;
    }
    else
    {
        float _821 = tmp;
        float _823 = 1.0 - ((1.0 - outcol.z) / _821);
        tmp = _823;
        if (_823 < 0.0)
        {
            outcol.z = 0.0;
        }
        else
        {
            if (tmp > 1.0)
            {
                outcol.z = 1.0;
            }
            else
            {
                outcol.z = tmp;
            }
        }
    }
    return outcol;
}

vec3 rgb_to_hsv(vec3 rgb)
{
    float cmax = max(rgb.x, max(rgb.y, rgb.z));
    float cmin = min(rgb.x, min(rgb.y, rgb.z));
    float cdelta = cmax - cmin;
    float v = cmax;
    float s;
    float h;
    if (!(cmax == 0.0))
    {
        s = cdelta / cmax;
    }
    else
    {
        s = 0.0;
        h = 0.0;
    }
    if (!(s == 0.0))
    {
        vec3 cmax3 = vec3(cmax, cmax, cmax);
        vec3 c = (cmax3 - rgb) / vec3(cdelta);
        if (rgb.x == cmax)
        {
            h = c.z - c.y;
        }
        else
        {
            if (rgb.y == cmax)
            {
                h = (2.0 + c.x) - c.z;
            }
            else
            {
                h = (4.0 + c.y) - c.x;
            }
        }
        h /= 6.0;
        if (h < 0.0)
        {
            h += 1.0;
        }
    }
    else
    {
        h = 0.0;
    }
    return vec3(h, s, v);
}

vec3 hsv_to_rgb(vec3 hsv)
{
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;
    vec3 rgb;
    if (!(s == 0.0))
    {
        if (h == 1.0)
        {
            h = 0.0;
        }
        h *= 6.0;
        float i = floor(h);
        float f = h - i;
        rgb = vec3(f, f, f);
        float p = v * (1.0 - s);
        float q = v * (1.0 - (s * f));
        float t = v * (1.0 - (s * (1.0 - f)));
        if (i == 0.0)
        {
            rgb = vec3(v, t, p);
        }
        else
        {
            if (i == 1.0)
            {
                rgb = vec3(q, v, p);
            }
            else
            {
                if (i == 2.0)
                {
                    rgb = vec3(p, v, t);
                }
                else
                {
                    if (i == 3.0)
                    {
                        rgb = vec3(p, q, v);
                    }
                    else
                    {
                        if (i == 4.0)
                        {
                            rgb = vec3(t, p, v);
                        }
                        else
                        {
                            rgb = vec3(v, p, q);
                        }
                    }
                }
            }
        }
    }
    else
    {
        rgb = vec3(v, v, v);
    }
    return rgb;
}

vec3 svm_mix_hue(float t, vec3 col1, vec3 col2)
{
    vec3 outcol = col1;
    vec3 param = col2;
    vec3 hsv2 = rgb_to_hsv(param);
    if (!(hsv2.y == 0.0))
    {
        vec3 param_1 = outcol;
        vec3 hsv = rgb_to_hsv(param_1);
        hsv.x = hsv2.x;
        vec3 param_2 = hsv;
        vec3 tmp = hsv_to_rgb(param_2);
        outcol = mix(outcol, tmp, vec3(t));
    }
    return outcol;
}

vec3 svm_mix_sat(float t, vec3 col1, vec3 col2)
{
    float tm = 1.0 - t;
    vec3 outcol = col1;
    vec3 param = outcol;
    vec3 hsv = rgb_to_hsv(param);
    if (!(hsv.y == 0.0))
    {
        vec3 param_1 = col2;
        vec3 hsv2 = rgb_to_hsv(param_1);
        hsv.y = (tm * hsv.y) + (t * hsv2.y);
        vec3 param_2 = hsv;
        outcol = hsv_to_rgb(param_2);
    }
    return outcol;
}

vec3 svm_mix_val(float t, vec3 col1, vec3 col2)
{
    float tm = 1.0 - t;
    vec3 param = col1;
    vec3 hsv = rgb_to_hsv(param);
    vec3 param_1 = col2;
    vec3 hsv2 = rgb_to_hsv(param_1);
    hsv.z = (tm * hsv.z) + (t * hsv2.z);
    vec3 param_2 = hsv;
    return hsv_to_rgb(param_2);
}

vec3 svm_mix_color(float t, vec3 col1, vec3 col2)
{
    vec3 outcol = col1;
    vec3 param = col2;
    vec3 hsv2 = rgb_to_hsv(param);
    if (!(hsv2.y == 0.0))
    {
        vec3 param_1 = outcol;
        vec3 hsv = rgb_to_hsv(param_1);
        hsv.x = hsv2.x;
        hsv.y = hsv2.y;
        vec3 param_2 = hsv;
        vec3 tmp = hsv_to_rgb(param_2);
        outcol = mix(outcol, tmp, vec3(t));
    }
    return outcol;
}

vec3 svm_mix_soft(float t, vec3 col1, vec3 col2)
{
    float tm = 1.0 - t;
    vec3 one = vec3(1.0);
    vec3 scr = one - ((one - col2) * (one - col1));
    return (col1 * tm) + (((((one - col1) * col2) * col1) + (col1 * scr)) * t);
}

vec3 svm_mix_linear(float t, vec3 col1, vec3 col2)
{
    return col1 + (((col2 * 2.0) + vec3(-1.0)) * t);
}

vec3 saturate3(vec3 a)
{
    return clamp(a, vec3(0.0), vec3(1.0));
}

vec3 svm_mix_clamp(vec3 col)
{
    vec3 param = col;
    return saturate3(param);
}

vec3 svm_mix(uint type, float fac, vec3 c1, vec3 c2)
{
    float t = clamp(fac, 0.0, 1.0);
    switch (type)
    {
        case 0u:
        {
            float param = t;
            vec3 param_1 = c1;
            vec3 param_2 = c2;
            return svm_mix_blend(param, param_1, param_2);
        }
        case 1u:
        {
            float param_3 = t;
            vec3 param_4 = c1;
            vec3 param_5 = c2;
            return svm_mix_add(param_3, param_4, param_5);
        }
        case 2u:
        {
            float param_6 = t;
            vec3 param_7 = c1;
            vec3 param_8 = c2;
            return svm_mix_mul(param_6, param_7, param_8);
        }
        case 4u:
        {
            float param_9 = t;
            vec3 param_10 = c1;
            vec3 param_11 = c2;
            return svm_mix_screen(param_9, param_10, param_11);
        }
        case 9u:
        {
            float param_12 = t;
            vec3 param_13 = c1;
            vec3 param_14 = c2;
            return svm_mix_overlay(param_12, param_13, param_14);
        }
        case 3u:
        {
            float param_15 = t;
            vec3 param_16 = c1;
            vec3 param_17 = c2;
            return svm_mix_sub(param_15, param_16, param_17);
        }
        case 5u:
        {
            float param_18 = t;
            vec3 param_19 = c1;
            vec3 param_20 = c2;
            return svm_mix_div(param_18, param_19, param_20);
        }
        case 6u:
        {
            float param_21 = t;
            vec3 param_22 = c1;
            vec3 param_23 = c2;
            return svm_mix_diff(param_21, param_22, param_23);
        }
        case 7u:
        {
            float param_24 = t;
            vec3 param_25 = c1;
            vec3 param_26 = c2;
            return svm_mix_dark(param_24, param_25, param_26);
        }
        case 8u:
        {
            float param_27 = t;
            vec3 param_28 = c1;
            vec3 param_29 = c2;
            return svm_mix_light(param_27, param_28, param_29);
        }
        case 10u:
        {
            float param_30 = t;
            vec3 param_31 = c1;
            vec3 param_32 = c2;
            return svm_mix_dodge(param_30, param_31, param_32);
        }
        case 11u:
        {
            float param_33 = t;
            vec3 param_34 = c1;
            vec3 param_35 = c2;
            return svm_mix_burn(param_33, param_34, param_35);
        }
        case 12u:
        {
            float param_36 = t;
            vec3 param_37 = c1;
            vec3 param_38 = c2;
            return svm_mix_hue(param_36, param_37, param_38);
        }
        case 13u:
        {
            float param_39 = t;
            vec3 param_40 = c1;
            vec3 param_41 = c2;
            return svm_mix_sat(param_39, param_40, param_41);
        }
        case 14u:
        {
            float param_42 = t;
            vec3 param_43 = c1;
            vec3 param_44 = c2;
            return svm_mix_val(param_42, param_43, param_44);
        }
        case 15u:
        {
            float param_45 = t;
            vec3 param_46 = c1;
            vec3 param_47 = c2;
            return svm_mix_color(param_45, param_46, param_47);
        }
        case 16u:
        {
            float param_48 = t;
            vec3 param_49 = c1;
            vec3 param_50 = c2;
            return svm_mix_soft(param_48, param_49, param_50);
        }
        case 17u:
        {
            float param_51 = t;
            vec3 param_52 = c1;
            vec3 param_53 = c2;
            return svm_mix_linear(param_51, param_52, param_53);
        }
        case 18u:
        {
            vec3 param_54 = c1;
            return svm_mix_clamp(param_54);
        }
    }
    return vec3(0.0);
}

vec3 svm_brightness_contrast(inout vec3 color, float brightness, float contrast)
{
    float a = 1.0 + contrast;
    float b = brightness - (contrast * 0.5);
    color.x = max((a * color.x) + b, 0.0);
    color.y = max((a * color.y) + b, 0.0);
    color.z = max((a * color.z) + b, 0.0);
    return color;
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
    switch (nio.type)
    {
        case 0u:
        {
            uint param = nio.type2;
            float param_1 = nio.fac;
            vec3 param_2 = nio.c1;
            vec3 param_3 = nio.c2;
            nio.c1 = svm_mix(param, param_1, param_2, param_3);
            break;
        }
        case 1u:
        {
            vec3 param_4 = nio.c1;
            float param_5 = nio.fac;
            float param_6 = nio.c2.x;
            vec3 _1264 = svm_brightness_contrast(param_4, param_5, param_6);
            nio.c1 = _1264;
            break;
        }
        default:
        {
            break;
        }
    }
}

