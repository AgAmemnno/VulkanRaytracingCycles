/*
 * Copyright 2011-2016 Blender Foundation
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

#ifndef _UTIL_TEXTURE_H_
#define _UTIL_TEXTURE_H_

#include "util_transform.h.glsl"

CCL_NAMESPACE_BEGIN

/* Texture limits on devices. */
#define TEX_NUM_MAX (INT_MAX >> 4)

/* Color to use when textures are not found. */
#define TEX_IMAGE_MISSING_R 1
#define TEX_IMAGE_MISSING_G 0
#define TEX_IMAGE_MISSING_B 1
#define TEX_IMAGE_MISSING_A 1

/* Texture type. */
#define kernel_tex_type(tex) (tex & IMAGE_DATA_TYPE_MASK)

/* Interpolation types for textures
 * cuda also use texture space to store other objects */
//modify => enum InterpolationType 
   #define InterpolationType uint
   uint  INTERPOLATION_NONE = -1;
   uint  INTERPOLATION_LINEAR = 0;
   uint  INTERPOLATION_CLOSEST = 1;
   uint  INTERPOLATION_CUBIC = 2;
   uint  INTERPOLATION_SMART = 3;
    uint  INTERPOLATION_NUM_TYPES = 4;
//modified ==> InterpolationType




/* Texture types
 * Since we store the type in the lower bits of a flat index,
 * the shift and bit mask constant below need to be kept in sync. */
//modify => enum ImageDataType 
   #define ImageDataType uint
   uint  IMAGE_DATA_TYPE_FLOAT4 = 0;
   uint  IMAGE_DATA_TYPE_BYTE4 = 1;
   uint  IMAGE_DATA_TYPE_HALF4 = 2;
   uint  IMAGE_DATA_TYPE_FLOAT = 3;
   uint  IMAGE_DATA_TYPE_BYTE = 4;
   uint  IMAGE_DATA_TYPE_HALF = 5;
   uint  IMAGE_DATA_TYPE_USHORT4 = 6;
   uint  IMAGE_DATA_TYPE_USHORT = 7;
    uint  IMAGE_DATA_NUM_TYPES = 8;
//modified ==> ImageDataType




/* Alpha types
 * How to treat alpha in images. */
//modify => enum ImageAlphaType 
   #define ImageAlphaType uint
   uint  IMAGE_ALPHA_UNASSOCIATED = 0;
   uint  IMAGE_ALPHA_ASSOCIATED = 1;
   uint  IMAGE_ALPHA_CHANNEL_PACKED = 2;
   uint  IMAGE_ALPHA_IGNORE = 3;
   uint  IMAGE_ALPHA_AUTO = 4;
    uint  IMAGE_ALPHA_NUM_TYPES = 5;
//modified ==> ImageAlphaType




#define IMAGE_DATA_TYPE_SHIFT 3
#define IMAGE_DATA_TYPE_MASK 0x7

/* Extension types for textures.
 *
 * Defines how the image is extrapolated past its original bounds. */
//modify => enum ExtensionType 
   #define ExtensionType uint
   uint  EXTENSION_REPEAT = 0;
   uint  EXTENSION_EXTEND = 1;
   uint  EXTENSION_CLIP = 2;
    uint  EXTENSION_NUM_TYPES = 3;
//modified ==> ExtensionType




 struct TextureInfo {
  /* Pointer, offset or texture depending on device. */
  uint64_t data;
  /* Data Type */
  uint data_type;
  /* Buffer number for OpenCL. */
  uint cl_buffer;
  /* Interpolation and extension type. */
  uint interpolation, extension;
  /* Dimensions. */
  uint width, height, depth;
  /* Transform for 3D textures. */
  uint use_transform_3d;
  Transform transform_3d;
  uint pad[2];
} ;

CCL_NAMESPACE_END

#endif /* _UTIL_TEXTURE_H_ */
