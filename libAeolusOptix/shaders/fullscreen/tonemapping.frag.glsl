#version 450
#extension GL_GOOGLE_include_directive : enable
// Tonemapping functions
#include "tonemapping.h"

layout(location = 0) in vec2 outUV;
layout(location = 0) out vec4 fragColor;

layout(set = 0, binding = 0) uniform sampler2D noisyTxt;

layout(push_constant) uniform shaderInformation
{
  int   tonemapper;
  float gamma;
  float exposure;
}
pushc;

void main()
{
  vec2 uv    = outUV;
  vec4 color = texture(noisyTxt, uv).rgba;

  fragColor = vec4(toneMap(color.rgb, pushc.tonemapper, pushc.gamma, pushc.exposure), color.a);
  //fragColor = vec4(1.0,0.0,1.0,1.);

}