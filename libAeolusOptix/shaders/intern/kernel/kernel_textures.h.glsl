/*
 * Copyright 2011-2013 Blender Foundation
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

#ifndef KERNEL_TEX
#  define KERNEL_TEX(type, name)
#endif

KERNEL_TEX(float4, _prim_tri_verts2)
KERNEL_TEX(uint, _prim_tri_index)
KERNEL_TEX(uint, _prim_type)
KERNEL_TEX(uint, _prim_visibility)
KERNEL_TEX(uint, _prim_index)
KERNEL_TEX(uint, _prim_object)




/* objects */
KERNEL_TEX(KernelObject, _objects)
//KERNEL_TEX(Transform, _object_motion_pass)
//KERNEL_TEX(DecomposedTransform, _object_motion)
KERNEL_TEX(uint, _object_flag)
KERNEL_TEX(float, _object_volume_step)


// patches 
KERNEL_TEX(uint, _patches)
/* attributes */
KERNEL_TEX(uint4, _attributes_map)
KERNEL_TEX(float, _attributes_float)
KERNEL_TEX(float2, _attributes_float2)
KERNEL_TEX(float4, _attributes_float3)
KERNEL_TEX(uchar4, _attributes_uchar4)

/* triangles */
KERNEL_TEX(uint, _tri_shader)
KERNEL_TEX(float4, _tri_vnormal)
KERNEL_TEX(uint, _tri_vindex2)
KERNEL_TEX(uint, _tri_patch)
KERNEL_TEX(float2, _tri_patch_uv)
// lights 
KERNEL_TEX(KernelLightDistribution, _light_distribution)
KERNEL_TEX(KernelLight, _lights)

KERNEL_TEX(float2, _light_background_marginal_cdf)
KERNEL_TEX(float2, _light_background_conditional_cdf)

// particles 
KERNEL_TEX(KernelParticle, _particles)


KERNEL_TEX(uint4, _svm_nodes)
KERNEL_TEX(KernelShader, _shaders)

// lookup tables 
KERNEL_TEX(float, _lookup_table)

// sobol 
KERNEL_TEX(uint, _sample_pattern_lut)

/* image textures */
KERNEL_TEX(TextureInfo, _texture_info)

/* ies lights 
KERNEL_TEX(float, __ies)
*/

#ifdef PUSH_POOL_SC
KERNEL_TEX(ShaderClosure,pool_sc)
#endif


#ifdef PUSH_POOL_IS
KERNEL_TEX(Intersection,pool_is)
#endif

#undef KERNEL_TEX
