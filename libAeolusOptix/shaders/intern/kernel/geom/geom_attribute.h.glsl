#ifndef _GEOM_ATTR_H_
#define _GEOM_ATTR_H_

/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in_rsv compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in_rsv writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "kernel/geom/geom_subd_triangle.h.glsl"

CCL_NAMESPACE_BEGIN

/* Attributes
 *
 * We support an arbitrary number of attributes on various mesh elements.
 * On vertices, triangles, curve keys, curves, meshes and volume grids.
 * Most of the code for attribute reading is in_rsv the primitive files.
 *
 * Lookup of attributes is different between OSL and SVM, as OSL is ustring
 * based while for SVM we use integer ids. */





ccl_device_inline uint attribute_primitive_type()
{
    if (  ((GSD.type & PRIMITIVE_ALL_TRIANGLE) !=0 ) && subd_triangle_patch() != ~0) {
    return ATTR_PRIM_SUBD;
  }
  else {
    return ATTR_PRIM_GEOMETRY;
  }
}


#define  object_attribute_map_offset(object) uint(kernel_tex_fetch(_objects, object).attribute_map_offset)

ccl_device_inline AttributeDescriptor attribute_not_found()
{

   const AttributeDescriptor desc = AttributeDescriptor(ATTR_ELEMENT_NONE, uint(0), uint(0), int(ATTR_STD_NOT_FOUND) );

  return desc;
}



ccl_device_inline AttributeDescriptor find_attribute(
                                                     uint id)
{
  if (GSD.object == OBJECT_NONE) {
    return attribute_not_found();
  }

  /* for SVM, find attribute by unique id */
  uint attr_offset = object_attribute_map_offset(GSD.object);
  attr_offset += attribute_primitive_type();
  uint4 attr_map = kernel_tex_fetch(_attributes_map, attr_offset);

  while (attr_map.x != id) {
    if (UNLIKELY(attr_map.x == ATTR_STD_NONE)) {
      return attribute_not_found();
    }
    attr_offset += ATTR_PRIM_TYPES;
    attr_map = kernel_tex_fetch(_attributes_map, attr_offset);
  }

  AttributeDescriptor desc;
  desc.element = AttributeElement(attr_map.y);

  if (GSD.prim == PRIM_NONE && desc.element != ATTR_ELEMENT_MESH &&
      desc.element != ATTR_ELEMENT_VOXEL && desc.element != ATTR_ELEMENT_OBJECT) {
    return attribute_not_found();
  }

  /* return result */
  desc.offset = (attr_map.y == ATTR_ELEMENT_NONE) ? int(ATTR_STD_NOT_FOUND) : int(attr_map.z);
  desc.type = NodeAttributeType(attr_map.w & 0xff);
  desc.flags = AttributeFlag(attr_map.w >> 8);

  return desc;
}

/* Transform matrix attribute on meshes */

ccl_device Transform primitive_attribute_matrix(
                                                const AttributeDescriptor desc)
{
  Transform tfm;

  tfm.x = kernel_tex_fetch(_attributes_float3, desc.offset + 0);
  tfm.y = kernel_tex_fetch(_attributes_float3, desc.offset + 1);
  tfm.z = kernel_tex_fetch(_attributes_float3, desc.offset + 2);

  return tfm;
}

CCL_NAMESPACE_END
#endif