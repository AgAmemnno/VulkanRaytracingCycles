#version 450
#extension GL_GOOGLE_include_directive : enable
#include "tonemapping.h"
layout(location = 0) in vec2 outUV;
layout(location = 0) out vec4 fragColor;

layout (set = 0,binding = 0) volatile buffer OUTBUFFERL { 
  float              noisyTxt[];
};
layout(push_constant) uniform shaderInformation
{
  int   tonemapper;
  float gamma;
  float exposure;
  float pad;
  vec2  size;
}
pushc;

float compSize =  4.f;

void main()
{

  int  idx     = int((outUV.x  + outUV.y*pushc.size.y)*pushc.size.x*compSize);
  /*
  if(idx >= 0 || idx+3 < int(pushc.size.x*pushc.size.y*compSize) ){
    vec4 color   = vec4(noisyTxt[idx],noisyTxt[idx+1],noisyTxt[idx+2],noisyTxt[idx+3]);
    fragColor    = vec4(toneMap(color.rgb, pushc.tonemapper, pushc.gamma, pushc.exposure), 1.0f);
  }else
     */
     fragColor   = vec4(outUV,0.f,1.);
   
}
