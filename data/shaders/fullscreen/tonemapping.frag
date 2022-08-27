#version 460

layout(push_constant, std430) uniform shaderInformation
{
    int tonemapper;
    float gamma;
    float exposure;
} pushc;

layout(set = 0, binding = 0) uniform sampler2D noisyTxt;

layout(location = 0) in vec2 outUV;
layout(location = 0) out vec4 fragColor;

vec3 gammaCorrection(vec3 color, float gamma)
{
    return pow(color, vec3(1.0 / gamma));
}

vec3 toneMapUncharted2Impl(vec3 color)
{
    return (((color * ((color * 0.1500000059604644775390625) + vec3(0.0500000007450580596923828125))) + vec3(0.0040000001899898052215576171875)) / ((color * ((color * 0.1500000059604644775390625) + vec3(0.5))) + vec3(0.0599999986588954925537109375))) - vec3(0.066666670143604278564453125);
}

vec3 toneMapUncharted(inout vec3 color, float gamma)
{
    vec3 param = color * 2.0;
    color = toneMapUncharted2Impl(param);
    vec3 param_1 = vec3(11.19999980926513671875);
    vec3 whiteScale = vec3(1.0) / toneMapUncharted2Impl(param_1);
    vec3 param_2 = color * whiteScale;
    float param_3 = gamma;
    return gammaCorrection(param_2, param_3);
}

vec3 toneMapHejlRichard(inout vec3 color)
{
    color = max(vec3(0.0), color - vec3(0.0040000001899898052215576171875));
    return (color * ((color * 6.19999980926513671875) + vec3(0.5))) / ((color * ((color * 6.19999980926513671875) + vec3(1.7000000476837158203125))) + vec3(0.0599999986588954925537109375));
}

vec3 toneMapACES(vec3 color, float gamma)
{
    vec3 param = clamp((color * ((color * 2.5099999904632568359375) + vec3(0.02999999932944774627685546875))) / ((color * ((color * 2.4300000667572021484375) + vec3(0.589999973773956298828125))) + vec3(0.14000000059604644775390625)), vec3(0.0), vec3(1.0));
    float param_1 = gamma;
    return gammaCorrection(param, param_1);
}

vec3 toneMap(inout vec3 color, int tonemap, float gamma, float exposure)
{
    color *= exposure;
    switch (tonemap)
    {
        case 1:
        {
            vec3 param = color;
            float param_1 = gamma;
            vec3 _162 = toneMapUncharted(param, param_1);
            return _162;
        }
        case 2:
        {
            vec3 param_2 = color;
            vec3 _166 = toneMapHejlRichard(param_2);
            return _166;
        }
        case 3:
        {
            vec3 param_3 = color;
            float param_4 = gamma;
            return toneMapACES(param_3, param_4);
        }
        default:
        {
            vec3 param_5 = color;
            float param_6 = gamma;
            return gammaCorrection(param_5, param_6);
        }
    }
}

void main()
{
    vec2 uv = outUV;
    vec4 color = texture(noisyTxt, uv);
    vec3 param = color.xyz;
    int param_1 = pushc.tonemapper;
    float param_2 = pushc.gamma;
    float param_3 = pushc.exposure;
    vec3 _220 = toneMap(param, param_1, param_2, param_3);
    fragColor = vec4(_220, color.w);
}

