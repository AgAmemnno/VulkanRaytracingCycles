#ifndef  _KERNEL_VULKAN_IMAGE_H_
#define  _KERNEL_VULKAN_IMAGE_H_
/*
 * Copyright 2017 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* w0, w1, w2, and w3 are the four cubic B-spline basis functions. */
#define  cubic_w0(a) ((1.0f / 6.0f) * (a * (a * (-a + 3.0f) - 3.0f) + 1.0f))
#define  cubic_w1(a) ((1.0f / 6.0f) * (a * a * (3.0f * a - 6.0f) + 4.0f))
#define  cubic_w2(a) ((1.0f / 6.0f) * (a * (a * (-3.0f * a + 3.0f) + 3.0f) + 1.0f))
#define  cubic_w3(a) ((1.0f / 6.0f) * (a * a * a))
/* g0 and g1 are the two amplitude functions. */
#define  cubic_g0(a) (cubic_w0(a) + cubic_w1(a))
#define  cubic_g1(a) (cubic_w2(a) + cubic_w3(a))
/* h0 and h1 are the two offset functions */
#define  cubic_h0(a) (-1.0f + cubic_w1(a) / (cubic_w0(a) + cubic_w1(a)) + 0.5f)
#define  cubic_h1(a) (1.0f + cubic_w3(a) / (cubic_w2(a) + cubic_w3(a)) + 0.5f)

#define TEX_RETURN_1 1
#define TEX_RETURN_4 4



#ifdef   SET_SAMPLERS

#define  _textureSize(slot, lod)   textureSize(_tex_[nonuniformEXT(uint(slot))], arg1)
// compute the number of accessible mipmap levels of a texture
#define  _textureQueryLevels(slot)        textureQueryLevels(_tex_[nonuniformEXT(uint(slot))])
#define  _texture_v(slot, tex_co)     texture(_tex_[nonuniformEXT(uint(slot))], tex_co)
#define  _texture(slot, x,y)     texture(_tex_[nonuniformEXT(uint(slot))], vec2(x,y))
#define  _texelFetch(slot, tex_ico, lod)  texelFetch(_tex_[nonuniformEXT(uint(slot))], tex_ico, lod)
/* Fast bicubic texture lookup using 4 bilinear lookups, adapted from CUDA samples. */

#define kernel_tex_image_interp_bicubic(ret,info,slot,x,y,ty)\
{\
  x = (x * info.width) - 0.5f;\
  y = (y * info.height) - 0.5f;\
  float px = floor(x);\
  float py = floor(y);\
  float fx = x - px;\
  float fy = y - py;\
  float g0x = cubic_g0(fx);\
  float g1x = cubic_g1(fx);\
  float x0 = (px + cubic_h0(fx)) / info.width;\
  float x1 = (px + cubic_h1(fx)) / info.width;\
  float y0 = (py + cubic_h0(fy)) / info.height;\
  float y1 = (py + cubic_h1(fy)) / info.height;\
  ret =  cubic_g0(fy) * (g0x * _texture(slot, x0, y0) + g1x * _texture(slot, x1, y0)) +\
         cubic_g1(fy) * (g0x * _texture(slot, x0, y1) + g1x * _texture(slot, x1, y1));\
}

#define kernel_tex_image_interp_bicubic1(ret,info,slot,x,y,ty)\
{\
  x = (x * info.width) - 0.5f;\
  y = (y * info.height) - 0.5f;\
  float px = floor(x);\
  float py = floor(y);\
  float fx = x - px;\
  float fy = y - py;\
  float g0x = cubic_g0(fx);\
  float g1x = cubic_g1(fx);\
  float x0 = (px + cubic_h0(fx)) / info.width;\
  float x1 = (px + cubic_h1(fx)) / info.width;\
  float y0 = (py + cubic_h0(fy)) / info.height;\
  float y1 = (py + cubic_h1(fy)) / info.height;\
  ret =  cubic_g0(fy) * (g0x * _texture(slot, x0, y0).x + g1x * _texture(slot, x1, y0).x) +\
         cubic_g1(fy) * (g0x * _texture(slot, x0, y1).x + g1x * _texture(slot, x1, y1).x);\
}

ccl_device float4 kernel_tex_image_interp(int id, float x, float y)
{
  const TextureInfo info = kernel_tex_fetch(_texture_info, id);
  uint  texSlot          =  uint(info.data);
  const uint texture_type = info.data_type;

   
  if(texSlot >= 128){
      debugPrintfEXT("assert TexSlot Error \n");
      return vec4(0.);
  }

 
  /* float4, byte4, ushort4 and half4 */
  
  if (texture_type == IMAGE_DATA_TYPE_FLOAT4 || texture_type == IMAGE_DATA_TYPE_BYTE4 ||
      texture_type == IMAGE_DATA_TYPE_HALF4 || texture_type == IMAGE_DATA_TYPE_USHORT4) {

    if (info.interpolation == INTERPOLATION_CUBIC) {
        vec4 ret;
        kernel_tex_image_interp_bicubic(ret,info, texSlot, x, y,TEX_RETURN_4);
        return ret;
    }
    else {
      return _texture(texSlot, x, y);
    }
  }
  // float, byte and half 
  else {
    float f;
    if (info.interpolation == INTERPOLATION_CUBIC) {
      kernel_tex_image_interp_bicubic1(f,info, texSlot, x, y ,TEX_RETURN_1);
    }
    else {
      f = _texture(texSlot, x, y).x;
    }
    return make_float4(f, f, f, 1.0f);
  }
  


}

#endif

#ifdef   SET_TEXTURES

#define SMAPLER_LIN_REP 0
#define SMAPLER_LIN_EXT 1
#define SMAPLER_LIN_CLI 2
#define SMAPLER_CLO_REP 3
#define SMAPLER_CLO_EXT 4
#define SMAPLER_CLO_CLI 5
  //pay.sd.P = vec4( texture( sampler2D(_tex_[nonuniformEXT(uint(1))],_samp_[nonuniformEXT(uint(0))]),uv).rgb,1.);

#define  _sampler(sID)  _samp_[nonuniformEXT(uint(sID))]
#define  _tex(slot)      _tex_[nonuniformEXT(uint(slot))]
#define  _textureSize(slot, lod)    textureSize(_tex_[nonuniformEXT(uint(slot))], arg1)
// compute the number of accessible mipmap levels of a texture
#define  _textureQueryLevels(slot)  textureQueryLevels(_tex_[nonuniformEXT(uint(slot))])
#define  _texture_v(slot,smpID, tex_co)   texture(sampler2D(_tex(slot), _sampler(smpID)), tex_co)
#define  _texture(slot,smpID, x,y)     texture(sampler2D(_tex(slot), _sampler(smpID)), vec2(x,y))
#define  _texelFetch(slot,smpID, tex_ico, lod)  texelFetch(sampler2D(_tex(slot), _sampler(smpID)), tex_ico, lod)

/* Fast bicubic texture lookup using 4 bilinear lookups, adapted from CUDA samples. */

#define kernel_tex_image_interp_bicubic(ret,info,slot,sampID,x,y)\
{\
  x = (x * info.width) - 0.5f;\
  y = (y * info.height) - 0.5f;\
  float px = floor(x);\
  float py = floor(y);\
  float fx = x - px;\
  float fy = y - py;\
  float g0x = cubic_g0(fx);\
  float g1x = cubic_g1(fx);\
  float x0 = (px + cubic_h0(fx)) / info.width;\
  float x1 = (px + cubic_h1(fx)) / info.width;\
  float y0 = (py + cubic_h0(fy)) / info.height;\
  float y1 = (py + cubic_h1(fy)) / info.height;\
  ret =  cubic_g0(fy) * (g0x * _texture(slot,sampID, x0, y0) + g1x * _texture(slot,sampID, x1, y0)) +\
         cubic_g1(fy) * (g0x * _texture(slot,sampID, x0, y1) + g1x * _texture(slot,sampID, x1, y1));\
}

#define kernel_tex_image_interp_bicubic1(ret,info,slot,sampID,x,y)\
{\
  x = (x * info.width) - 0.5f;\
  y = (y * info.height) - 0.5f;\
  float px = floor(x);\
  float py = floor(y);\
  float fx = x - px;\
  float fy = y - py;\
  float g0x = cubic_g0(fx);\
  float g1x = cubic_g1(fx);\
  float x0 = (px + cubic_h0(fx)) / info.width;\
  float x1 = (px + cubic_h1(fx)) / info.width;\
  float y0 = (py + cubic_h0(fy)) / info.height;\
  float y1 = (py + cubic_h1(fy)) / info.height;\
  ret =  cubic_g0(fy) * (g0x * _texture(slot,sampID, x0, y0).x + g1x * _texture(slot,sampID, x1, y0).x) +\
         cubic_g1(fy) * (g0x * _texture(slot,sampID, x0, y1).x + g1x * _texture(slot,sampID,x1, y1).x);\
}

ccl_device float4 kernel_tex_image_interp(int id, float x, float y)
{
  const TextureInfo info  = kernel_tex_fetch(_texture_info, id);
  uint  texSlot           =  uint(info.data);
  const uint texture_type = info.data_type;
   

  if(texSlot >= 128){
      debugPrintfEXT("assert TexSlot Error \n");
      return vec4(0.);
  }

   //uint sampID = info.interpolation*3 + info.extension;
  #define checkSampID \
  if(sampID >= 6){\
      debugPrintfEXT("assert SamplerSlot Error \n");\
      return vec4(0.);\
  }

   //debugPrintfEXT("Info Textures ID %u TexSlot %u Extension %u interpolation %u  u  %.3f v %.3f  \n",id,texSlot,info.extension,info.interpolation,x,y);
   //return _texture(texSlot,sampID, x, y);
   //return vec4( texture( sampler2D(_tex_[nonuniformEXT(uint(texSlot))],_samp_[nonuniformEXT(uint(sampID))]),vec2(x,y)).rgb,1.);

  // float4, byte4, ushort4 and half4

  if (texture_type == IMAGE_DATA_TYPE_FLOAT4 || texture_type == IMAGE_DATA_TYPE_BYTE4 ||
      texture_type == IMAGE_DATA_TYPE_HALF4 || texture_type == IMAGE_DATA_TYPE_USHORT4) {

    if (info.interpolation == INTERPOLATION_CUBIC) {

        uint sampID =  info.extension;
        checkSampID
        vec4 ret;
        kernel_tex_image_interp_bicubic(ret,info, texSlot,sampID, x, y);
        return ret;
    }
    else {
      uint sampID = info.interpolation*3 + info.extension;
       checkSampID
      return _texture(texSlot,sampID, x, y);
    }
  }
  // float, byte and half 
  else {
    float f;
    if (info.interpolation == INTERPOLATION_CUBIC) {
       uint sampID =  info.extension;
      checkSampID
      kernel_tex_image_interp_bicubic1(f,info, texSlot,sampID, x, y );
    }
    else {
      uint sampID = info.interpolation*3 + info.extension;
       checkSampID
      f = _texture(texSlot,sampID, x, y).x;
    }
    return make_float4(f, f, f, 1.0f);
  }

}

#endif


//vec4 texelFetch(texture2D_u16 s, ivec2 arg1, int arg2){return texelFetch(dit_texture2D[nonuniformEXT(uint(s.idx))], arg1, arg2); }
//uvec4 texelFetch(usamplerBuffer_u16 s, int arg1){return texelFetch(dit_usamplerBuffer[nonuniformEXT(uint(s.idx))], arg1); }
//int textureQueryLevels(texture2D_u16 s){return textureQueryLevels(dit_texture2D[nonuniformEXT(uint(s.idx))]); }
//ivec2 textureSize(texture2D_u16 s, int arg1){return textureSize(dit_texture2D[nonuniformEXT(uint(s.idx))], arg1); }





#ifdef TODO_KERNEL_IMAGE__
/* Fast tricubic texture lookup using 8 trilinear lookups. */
template<typename T>
ccl_device T kernel_tex_image_interp_bicubic_3d(
    const TextureInfo &info, CUtexObject tex, float x, float y, float z)
{
  x = (x * info.width) - 0.5f;
  y = (y * info.height) - 0.5f;
  z = (z * info.depth) - 0.5f;

  float px = floor(x);
  float py = floor(y);
  float pz = floor(z);
  float fx = x - px;
  float fy = y - py;
  float fz = z - pz;

  float g0x = cubic_g0(fx);
  float g1x = cubic_g1(fx);
  float g0y = cubic_g0(fy);
  float g1y = cubic_g1(fy);
  float g0z = cubic_g0(fz);
  float g1z = cubic_g1(fz);

  float x0 = (px + cubic_h0(fx)) / info.width;
  float x1 = (px + cubic_h1(fx)) / info.width;
  float y0 = (py + cubic_h0(fy)) / info.height;
  float y1 = (py + cubic_h1(fy)) / info.height;
  float z0 = (pz + cubic_h0(fz)) / info.depth;
  float z1 = (pz + cubic_h1(fz)) / info.depth;

  return g0z * (g0y * (g0x * tex3D<T>(tex, x0, y0, z0) + g1x * tex3D<T>(tex, x1, y0, z0)) +
                g1y * (g0x * tex3D<T>(tex, x0, y1, z0) + g1x * tex3D<T>(tex, x1, y1, z0))) +
         g1z * (g0y * (g0x * tex3D<T>(tex, x0, y0, z1) + g1x * tex3D<T>(tex, x1, y0, z1)) +
                g1y * (g0x * tex3D<T>(tex, x0, y1, z1) + g1x * tex3D<T>(tex, x1, y1, z1)));
}

ccl_device float4 kernel_tex_image_interp_3d(KernelGlobals *kg,
                                             int id,
                                             float3 P,
                                             InterpolationType interp)
{
  const TextureInfo &info = kernel_tex_fetch(__texture_info, id);

  if (info.use_transform_3d) {
    P = transform_point(&info.transform_3d, P);
  }

  const float x = P.x;
  const float y = P.y;
  const float z = P.z;

  CUtexObject tex = (CUtexObject)info.data;
  uint interpolation = (interp == INTERPOLATION_NONE) ? info.interpolation : interp;

  const int texture_type = info.data_type;
  if (texture_type == IMAGE_DATA_TYPE_FLOAT4 || texture_type == IMAGE_DATA_TYPE_BYTE4 ||
      texture_type == IMAGE_DATA_TYPE_HALF4 || texture_type == IMAGE_DATA_TYPE_USHORT4) {
    if (interpolation == INTERPOLATION_CUBIC) {
      return kernel_tex_image_interp_bicubic_3d<float4>(info, tex, x, y, z);
    }
    else {
      return tex3D<float4>(tex, x, y, z);
    }
  }
  else {
    float f;

    if (interpolation == INTERPOLATION_CUBIC) {
      f = kernel_tex_image_interp_bicubic_3d<float>(info, tex, x, y, z);
    }
    else {
      f = tex3D<float>(tex, x, y, z);
    }

    return make_float4(f, f, f, 1.0f);
  }
}
#endif
#endif