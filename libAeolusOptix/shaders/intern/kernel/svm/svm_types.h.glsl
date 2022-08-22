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

#ifndef _SVM_TYPES_H_
#define _SVM_TYPES_H_

CCL_NAMESPACE_BEGIN

/* Stack */

/* SVM stack has a fixed size */
#define SVM_STACK_SIZE 255
/* SVM stack offsets with this value indicate that it's not on the stack */
#define SVM_STACK_INVALID 255

#define SVM_BUMP_EVAL_STATE_SIZE 9

/* Nodes */

/* Known frequencies of used nodes, used for selective nodes compilation
 * in the kernel. Currently only affects split OpenCL kernel.
 *
 * Keep as defines so it's easy to check which nodes are to be compiled
 * from preprocessor.
 *
 * Lower the number of group more often the node is used.
 */
#define NODE_GROUP_LEVEL_0 0
#define NODE_GROUP_LEVEL_1 1
#define NODE_GROUP_LEVEL_2 2
#define NODE_GROUP_LEVEL_3 3
#define NODE_GROUP_LEVEL_4 4
#define NODE_GROUP_LEVEL_MAX NODE_GROUP_LEVEL_4

#define NODE_FEATURE_VOLUME (1 << 0)
#define NODE_FEATURE_HAIR (1 << 1)
#define NODE_FEATURE_BUMP (1 << 2)
#define NODE_FEATURE_BUMP_STATE (1 << 3)
#define NODE_FEATURE_VORONOI_EXTRA (1 << 4)
/* TODO(sergey): Consider using something like ((uint)(-1)).
 * Need to check carefully operand types around usage of this
 * define first.
 */
#define NODE_FEATURE_ALL \
  (NODE_FEATURE_VOLUME | NODE_FEATURE_HAIR | NODE_FEATURE_BUMP | NODE_FEATURE_BUMP_STATE | \
   NODE_FEATURE_VORONOI_EXTRA)

#define NODES_GROUP(group) ((group) <= _NODES_MAX_GROUP_)
#define NODES_FEATURE(feature) ((_NODES_FEATURES_ & (feature)) != 0)

//modify => enum ShaderNodeType 
#define ShaderNodeType uint
#define NODE_END  uint(0)
#define NODE_SHADER_JUMP uint(1)
#define NODE_CLOSURE_BSDF uint(2)
#define NODE_CLOSURE_EMISSION uint(3)
#define NODE_CLOSURE_BACKGROUND uint(4)
#define NODE_CLOSURE_SET_WEIGHT uint(5)
#define NODE_CLOSURE_WEIGHT uint(6)
#define NODE_EMISSION_WEIGHT uint(7)
#define NODE_MIX_CLOSURE uint(8)
#define NODE_JUMP_IF_ZERO uint(9)
#define NODE_JUMP_IF_ONE uint(10)
#define NODE_GEOMETRY uint(11)
#define NODE_CONVERT uint(12)
#define NODE_TEX_COORD uint(13)
#define NODE_VALUE_F uint(14)
#define NODE_VALUE_V uint(15)
#define NODE_ATTR uint(16)
#define NODE_VERTEX_COLOR uint(17)
#define NODE_GEOMETRY_BUMP_DX uint(18)
#define NODE_GEOMETRY_BUMP_DY uint(19)
#define NODE_SET_DISPLACEMENT uint(20)
#define NODE_DISPLACEMENT uint(21)
#define NODE_VECTOR_DISPLACEMENT uint(22)
#define NODE_TEX_IMAGE uint(23)
#define NODE_TEX_IMAGE_BOX uint(24)
#define NODE_TEX_NOISE uint(25)
#define NODE_SET_BUMP uint(26)
#define NODE_ATTR_BUMP_DX uint(27)
#define NODE_ATTR_BUMP_DY uint(28)
#define NODE_VERTEX_COLOR_BUMP_DX uint(29)
#define NODE_VERTEX_COLOR_BUMP_DY uint(30)
#define NODE_TEX_COORD_BUMP_DX uint(31)
#define NODE_TEX_COORD_BUMP_DY uint(32)
#define NODE_CLOSURE_SET_NORMAL uint(33)
#define NODE_ENTER_BUMP_EVAL uint(34)
#define NODE_LEAVE_BUMP_EVAL uint(35)
#define NODE_HSV uint(36)
#define NODE_CLOSURE_HOLDOUT uint(37)
#define NODE_FRESNEL uint(38)
#define NODE_LAYER_WEIGHT uint(39)
#define NODE_CLOSURE_VOLUME uint(40)
#define NODE_PRINCIPLED_VOLUME uint(41)
#define NODE_MATH uint(42)
#define NODE_VECTOR_MATH uint(43)
#define NODE_RGB_RAMP uint(44)
#define NODE_GAMMA uint(45)
#define NODE_BRIGHTCONTRAST uint(46)
#define NODE_LIGHT_PATH uint(47)
#define NODE_OBJECT_INFO uint(48)
#define NODE_PARTICLE_INFO uint(49)
#define NODE_HAIR_INFO uint(50)
#define NODE_TEXTURE_MAPPING uint(51)
#define NODE_MAPPING uint(52)
#define NODE_MIN_MAX uint(53)
#define NODE_CAMERA uint(54)
#define NODE_TEX_ENVIRONMENT uint(55)
#define NODE_TEX_SKY uint(56)
#define NODE_TEX_GRADIENT uint(57)
#define NODE_TEX_VORONOI uint(58)
#define NODE_TEX_MUSGRAVE uint(59)
#define NODE_TEX_WAVE uint(60)
#define NODE_TEX_MAGIC uint(61)
#define NODE_TEX_CHECKER uint(62)
#define NODE_TEX_BRICK uint(63)
#define NODE_TEX_WHITE_NOISE uint(64)
#define NODE_NORMAL uint(65)
#define NODE_LIGHT_FALLOFF uint(66)
#define NODE_IES uint(67)
#define NODE_RGB_CURVES uint(68)
#define NODE_VECTOR_CURVES uint(69)
#define NODE_TANGENT uint(70)
#define NODE_NORMAL_MAP uint(71)
#define NODE_INVERT uint(72)
#define NODE_MIX uint(73)
#define NODE_SEPARATE_VECTOR uint(74)
#define NODE_COMBINE_VECTOR uint(75)
#define NODE_SEPARATE_HSV uint(76)
#define NODE_COMBINE_HSV uint(77)
#define NODE_VECTOR_ROTATE uint(78)
#define NODE_VECTOR_TRANSFORM uint(79)
#define NODE_WIREFRAME uint(80)
#define NODE_WAVELENGTH uint(81)
#define NODE_BLACKBODY uint(82)
#define NODE_MAP_RANGE uint(83)
#define NODE_CLAMP uint(84)
#define NODE_BEVEL uint(85)
#define NODE_AMBIENT_OCCLUSION uint(86)
#define NODE_TEX_VOXEL uint(87)
#define NODE_AOV_START uint(88)
#define NODE_AOV_COLOR uint(89)
#define NODE_AOV_VALUE uint(90)
//modified ==> ShaderNodeType




//modify => enum NodeAttributeType 
#define NodeAttributeType uint
#define NODE_ATTR_FLOAT  uint(0)
#define NODE_ATTR_FLOAT2 uint(1)
#define NODE_ATTR_FLOAT3 uint(2)
#define NODE_ATTR_RGBA uint(3)
#define NODE_ATTR_MATRIX uint(4)
//modified ==> NodeAttributeType




//modify => enum NodeGeometry 
#define NodeGeometry uint
#define NODE_GEOM_P  uint(0)
#define NODE_GEOM_N uint(1)
#define NODE_GEOM_T uint(2)
#define NODE_GEOM_I uint(3)
#define NODE_GEOM_Ng uint(4)
#define NODE_GEOM_uv uint(5)
//modified ==> NodeGeometry




//modify => enum NodeObjectInfo 
#define NodeObjectInfo uint
#define NODE_INFO_OB_LOCATION uint(0)
#define NODE_INFO_OB_COLOR uint(1)
#define NODE_INFO_OB_INDEX uint(2)
#define NODE_INFO_MAT_INDEX uint(3)
#define NODE_INFO_OB_RANDOM uint(4)
//modified ==> NodeObjectInfo




//modify => enum NodeParticleInfo 
#define NodeParticleInfo uint
#define NODE_INFO_PAR_INDEX uint(0)
#define NODE_INFO_PAR_RANDOM uint(1)
#define NODE_INFO_PAR_AGE uint(2)
#define NODE_INFO_PAR_LIFETIME uint(3)
#define NODE_INFO_PAR_LOCATION uint(4)
#define NODE_INFO_PAR_ROTATION uint(5)
#define NODE_INFO_PAR_SIZE uint(6)
#define NODE_INFO_PAR_VELOCITY uint(7)
#define NODE_INFO_PAR_ANGULAR_VELOCITY uint(8)
//modified ==> NodeParticleInfo




//modify => enum NodeHairInfo 
#define NodeHairInfo uint
#define NODE_INFO_CURVE_IS_STRAND uint(0)
#define NODE_INFO_CURVE_INTERCEPT uint(1)
#define NODE_INFO_CURVE_THICKNESS uint(2)
#define NODE_INFO_CURVE_FADE uint(3)
#define NODE_INFO_CURVE_TANGENT_NORMAL uint(4)
#define NODE_INFO_CURVE_RANDOM uint(5)
//modified ==> NodeHairInfo




//modify => enum NodeLightPath 
#define NodeLightPath uint
#define NODE_LP_camera  uint(0)
#define NODE_LP_shadow uint(1)
#define NODE_LP_diffuse uint(2)
#define NODE_LP_glossy uint(3)
#define NODE_LP_singular uint(4)
#define NODE_LP_reflection uint(5)
#define NODE_LP_transmission uint(6)
#define NODE_LP_volume_scatter uint(7)
#define NODE_LP_backfacing uint(8)
#define NODE_LP_ray_length uint(9)
#define NODE_LP_ray_depth uint(10)
#define NODE_LP_ray_diffuse uint(11)
#define NODE_LP_ray_glossy uint(12)
#define NODE_LP_ray_transparent uint(13)
#define NODE_LP_ray_transmission uint(14)
//modified ==> NodeLightPath




//modify => enum NodeLightFalloff 
#define NodeLightFalloff uint
#define NODE_LIGHT_FALLOFF_QUADRATIC uint(0)
#define NODE_LIGHT_FALLOFF_LINEAR uint(1)
#define NODE_LIGHT_FALLOFF_CONSTANT uint(2)
//modified ==> NodeLightFalloff




//modify => enum NodeTexCoord 
#define NodeTexCoord uint
#define NODE_TEXCO_NORMAL uint(0)
#define NODE_TEXCO_OBJECT uint(1)
#define NODE_TEXCO_CAMERA uint(2)
#define NODE_TEXCO_WINDOW uint(3)
#define NODE_TEXCO_REFLECTION uint(4)
#define NODE_TEXCO_DUPLI_GENERATED uint(5)
#define NODE_TEXCO_DUPLI_UV uint(6)
#define NODE_TEXCO_VOLUME_GENERATED uint(7)
//modified ==> NodeTexCoord




//modify => enum NodeMix 
#define NodeMix uint
#define NODE_MIX_BLEND  uint(0)
#define NODE_MIX_ADD uint(1)
#define NODE_MIX_MUL uint(2)
#define NODE_MIX_SUB uint(3)
#define NODE_MIX_SCREEN uint(4)
#define NODE_MIX_DIV uint(5)
#define NODE_MIX_DIFF uint(6)
#define NODE_MIX_DARK uint(7)
#define NODE_MIX_LIGHT uint(8)
#define NODE_MIX_OVERLAY uint(9)
#define NODE_MIX_DODGE uint(10)
#define NODE_MIX_BURN uint(11)
#define NODE_MIX_HUE uint(12)
#define NODE_MIX_SAT uint(13)
#define NODE_MIX_VAL uint(14)
#define NODE_MIX_COLOR uint(15)
#define NODE_MIX_SOFT uint(16)
#define NODE_MIX_LINEAR uint(17)
#define NODE_MIX_CLAMP /* used for the clamp UI option */ uint(18)
//modified ==> NodeMix




//modify => enum NodeMathType 
#define NodeMathType uint
#define NODE_MATH_ADD uint(0)
#define NODE_MATH_SUBTRACT uint(1)
#define NODE_MATH_MULTIPLY uint(2)
#define NODE_MATH_DIVIDE uint(3)
#define NODE_MATH_SINE uint(4)
#define NODE_MATH_COSINE uint(5)
#define NODE_MATH_TANGENT uint(6)
#define NODE_MATH_ARCSINE uint(7)
#define NODE_MATH_ARCCOSINE uint(8)
#define NODE_MATH_ARCTANGENT uint(9)
#define NODE_MATH_POWER uint(10)
#define NODE_MATH_LOGARITHM uint(11)
#define NODE_MATH_MINIMUM uint(12)
#define NODE_MATH_MAXIMUM uint(13)
#define NODE_MATH_ROUND uint(14)
#define NODE_MATH_LESS_THAN uint(15)
#define NODE_MATH_GREATER_THAN uint(16)
#define NODE_MATH_MODULO uint(17)
#define NODE_MATH_ABSOLUTE uint(18)
#define NODE_MATH_ARCTAN2 uint(19)
#define NODE_MATH_FLOOR uint(20)
#define NODE_MATH_CEIL uint(21)
#define NODE_MATH_FRACTION uint(22)
#define NODE_MATH_SQRT uint(23)
#define NODE_MATH_INV_SQRT uint(24)
#define NODE_MATH_SIGN uint(25)
#define NODE_MATH_EXPONENT uint(26)
#define NODE_MATH_RADIANS uint(27)
#define NODE_MATH_DEGREES uint(28)
#define NODE_MATH_SINH uint(29)
#define NODE_MATH_COSH uint(30)
#define NODE_MATH_TANH uint(31)
#define NODE_MATH_TRUNC uint(32)
#define NODE_MATH_SNAP uint(33)
#define NODE_MATH_WRAP uint(34)
#define NODE_MATH_COMPARE uint(35)
#define NODE_MATH_MULTIPLY_ADD uint(36)
#define NODE_MATH_PINGPONG uint(37)
#define NODE_MATH_SMOOTH_MIN uint(38)
#define NODE_MATH_SMOOTH_MAX uint(39)
//modified ==> NodeMathType




//modify => enum NodeVectorMathType 
#define NodeVectorMathType uint
#define NODE_VECTOR_MATH_ADD uint(0)
#define NODE_VECTOR_MATH_SUBTRACT uint(1)
#define NODE_VECTOR_MATH_MULTIPLY uint(2)
#define NODE_VECTOR_MATH_DIVIDE uint(3)
#define NODE_VECTOR_MATH_CROSS_PRODUCT uint(4)
#define NODE_VECTOR_MATH_PROJECT uint(5)
#define NODE_VECTOR_MATH_REFLECT uint(6)
#define NODE_VECTOR_MATH_DOT_PRODUCT uint(7)
#define NODE_VECTOR_MATH_DISTANCE uint(8)
#define NODE_VECTOR_MATH_LENGTH uint(9)
#define NODE_VECTOR_MATH_SCALE uint(10)
#define NODE_VECTOR_MATH_NORMALIZE uint(11)
#define NODE_VECTOR_MATH_SNAP uint(12)
#define NODE_VECTOR_MATH_FLOOR uint(13)
#define NODE_VECTOR_MATH_CEIL uint(14)
#define NODE_VECTOR_MATH_MODULO uint(15)
#define NODE_VECTOR_MATH_FRACTION uint(16)
#define NODE_VECTOR_MATH_ABSOLUTE uint(17)
#define NODE_VECTOR_MATH_MINIMUM uint(18)
#define NODE_VECTOR_MATH_MAXIMUM uint(19)
#define NODE_VECTOR_MATH_WRAP uint(20)
#define NODE_VECTOR_MATH_SINE uint(21)
#define NODE_VECTOR_MATH_COSINE uint(22)
#define NODE_VECTOR_MATH_TANGENT uint(23)
//modified ==> NodeVectorMathType




//modify => enum NodeClampType 
#define NodeClampType uint
#define NODE_CLAMP_MINMAX uint(0)
#define NODE_CLAMP_RANGE uint(1)
//modified ==> NodeClampType




//modify => enum NodeMapRangeType 
#define NodeMapRangeType uint
#define NODE_MAP_RANGE_LINEAR uint(0)
#define NODE_MAP_RANGE_STEPPED uint(1)
#define NODE_MAP_RANGE_SMOOTHSTEP uint(2)
#define NODE_MAP_RANGE_SMOOTHERSTEP uint(3)
//modified ==> NodeMapRangeType




//modify => enum NodeMappingType 
#define NodeMappingType uint
#define NODE_MAPPING_TYPE_POINT uint(0)
#define NODE_MAPPING_TYPE_TEXTURE uint(1)
#define NODE_MAPPING_TYPE_VECTOR uint(2)
#define NODE_MAPPING_TYPE_NORMAL uint(3)
//modified ==> NodeMappingType




//modify => enum NodeVectorRotateType 
#define NodeVectorRotateType uint
#define NODE_VECTOR_ROTATE_TYPE_AXIS uint(0)
#define NODE_VECTOR_ROTATE_TYPE_AXIS_X uint(1)
#define NODE_VECTOR_ROTATE_TYPE_AXIS_Y uint(2)
#define NODE_VECTOR_ROTATE_TYPE_AXIS_Z uint(3)
#define NODE_VECTOR_ROTATE_TYPE_EULER_XYZ uint(4)
//modified ==> NodeVectorRotateType




//modify => enum NodeVectorTransformType 
#define NodeVectorTransformType uint
#define NODE_VECTOR_TRANSFORM_TYPE_VECTOR uint(0)
#define NODE_VECTOR_TRANSFORM_TYPE_POINT uint(1)
#define NODE_VECTOR_TRANSFORM_TYPE_NORMAL uint(2)
//modified ==> NodeVectorTransformType




//modify => enum NodeVectorTransformConvertSpace 
#define NodeVectorTransformConvertSpace uint
#define NODE_VECTOR_TRANSFORM_CONVERT_SPACE_WORLD uint(0)
#define NODE_VECTOR_TRANSFORM_CONVERT_SPACE_OBJECT uint(1)
#define NODE_VECTOR_TRANSFORM_CONVERT_SPACE_CAMERA uint(2)
//modified ==> NodeVectorTransformConvertSpace




//modify => enum NodeConvert 
#define NodeConvert uint
#define NODE_CONVERT_FV uint(0)
#define NODE_CONVERT_FI uint(1)
#define NODE_CONVERT_CF uint(2)
#define NODE_CONVERT_CI uint(3)
#define NODE_CONVERT_VF uint(4)
#define NODE_CONVERT_VI uint(5)
#define NODE_CONVERT_IF uint(6)
#define NODE_CONVERT_IV uint(7)
//modified ==> NodeConvert




//modify => enum NodeMusgraveType 
#define NodeMusgraveType uint
#define NODE_MUSGRAVE_MULTIFRACTAL uint(0)
#define NODE_MUSGRAVE_FBM uint(1)
#define NODE_MUSGRAVE_HYBRID_MULTIFRACTAL uint(2)
#define NODE_MUSGRAVE_RIDGED_MULTIFRACTAL uint(3)
#define NODE_MUSGRAVE_HETERO_TERRAIN uint(4)
//modified ==> NodeMusgraveType




//modify => enum NodeWaveType 
#define NodeWaveType uint
#define NODE_WAVE_BANDS uint(0)
#define NODE_WAVE_RINGS uint(1)
//modified ==> NodeWaveType




//modify => enum NodeWaveBandsDirection 
#define NodeWaveBandsDirection uint
#define NODE_WAVE_BANDS_DIRECTION_X uint(0)
#define NODE_WAVE_BANDS_DIRECTION_Y uint(1)
#define NODE_WAVE_BANDS_DIRECTION_Z uint(2)
#define NODE_WAVE_BANDS_DIRECTION_DIAGONAL uint(3)
//modified ==> NodeWaveBandsDirection




//modify => enum NodeWaveRingsDirection 
#define NodeWaveRingsDirection uint
#define NODE_WAVE_RINGS_DIRECTION_X uint(0)
#define NODE_WAVE_RINGS_DIRECTION_Y uint(1)
#define NODE_WAVE_RINGS_DIRECTION_Z uint(2)
#define NODE_WAVE_RINGS_DIRECTION_SPHERICAL uint(3)
//modified ==> NodeWaveRingsDirection




//modify => enum NodeWaveProfile 
#define NodeWaveProfile uint
#define NODE_WAVE_PROFILE_SIN uint(0)
#define NODE_WAVE_PROFILE_SAW uint(1)
#define NODE_WAVE_PROFILE_TRI uint(2)
//modified ==> NodeWaveProfile




//modify => enum NodeSkyType 
#define NodeSkyType uint
#define NODE_SKY_PREETHAM uint(0)
#define NODE_SKY_HOSEK uint(1)
#define NODE_SKY_NISHITA uint(2)
//modified ==> NodeSkyType




//modify => enum NodeGradientType 
#define NodeGradientType uint
#define NODE_BLEND_LINEAR uint(0)
#define NODE_BLEND_QUADRATIC uint(1)
#define NODE_BLEND_EASING uint(2)
#define NODE_BLEND_DIAGONAL uint(3)
#define NODE_BLEND_RADIAL uint(4)
#define NODE_BLEND_QUADRATIC_SPHERE uint(5)
#define NODE_BLEND_SPHERICAL uint(6)
//modified ==> NodeGradientType




//modify => enum NodeVoronoiDistanceMetric 
#define NodeVoronoiDistanceMetric uint
#define NODE_VORONOI_EUCLIDEAN uint(0)
#define NODE_VORONOI_MANHATTAN uint(1)
#define NODE_VORONOI_CHEBYCHEV uint(2)
#define NODE_VORONOI_MINKOWSKI uint(3)
//modified ==> NodeVoronoiDistanceMetric




//modify => enum NodeVoronoiFeature 
#define NodeVoronoiFeature uint
#define NODE_VORONOI_F1 uint(0)
#define NODE_VORONOI_F2 uint(1)
#define NODE_VORONOI_SMOOTH_F1 uint(2)
#define NODE_VORONOI_DISTANCE_TO_EDGE uint(3)
#define NODE_VORONOI_N_SPHERE_RADIUS uint(4)
//modified ==> NodeVoronoiFeature




//modify => enum NodeBlendWeightType 
#define NodeBlendWeightType uint
#define NODE_LAYER_WEIGHT_FRESNEL uint(0)
#define NODE_LAYER_WEIGHT_FACING uint(1)
//modified ==> NodeBlendWeightType




//modify => enum NodeTangentDirectionType 
#define NodeTangentDirectionType uint
#define NODE_TANGENT_RADIAL uint(0)
#define NODE_TANGENT_UVMAP uint(1)
//modified ==> NodeTangentDirectionType




//modify => enum NodeTangentAxis 
#define NodeTangentAxis uint
#define NODE_TANGENT_AXIS_X uint(0)
#define NODE_TANGENT_AXIS_Y uint(1)
#define NODE_TANGENT_AXIS_Z uint(2)
//modified ==> NodeTangentAxis




//modify => enum NodeNormalMapSpace 
#define NodeNormalMapSpace uint
#define NODE_NORMAL_MAP_TANGENT uint(0)
#define NODE_NORMAL_MAP_OBJECT uint(1)
#define NODE_NORMAL_MAP_WORLD uint(2)
#define NODE_NORMAL_MAP_BLENDER_OBJECT uint(3)
#define NODE_NORMAL_MAP_BLENDER_WORLD uint(4)
//modified ==> NodeNormalMapSpace




//modify => enum NodeImageProjection 
#define NodeImageProjection uint
#define NODE_IMAGE_PROJ_FLAT  uint(0)
#define NODE_IMAGE_PROJ_BOX  uint(1)
#define NODE_IMAGE_PROJ_SPHERE  uint(2)
#define NODE_IMAGE_PROJ_TUBE  uint(3)
//modified ==> NodeImageProjection




//modify => enum NodeImageFlags 
#define NodeImageFlags uint
#define NODE_IMAGE_COMPRESS_AS_SRGB  uint(1)
#define NODE_IMAGE_ALPHA_UNASSOCIATE  uint(2)
//modified ==> NodeImageFlags




//modify => enum NodeEnvironmentProjection 
#define NodeEnvironmentProjection uint
#define NODE_ENVIRONMENT_EQUIRECTANGULAR  uint(0)
#define NODE_ENVIRONMENT_MIRROR_BALL  uint(1)
//modified ==> NodeEnvironmentProjection




//modify => enum NodeBumpOffset 
#define NodeBumpOffset uint
#define NODE_BUMP_OFFSET_CENTER uint(0)
#define NODE_BUMP_OFFSET_DX uint(1)
#define NODE_BUMP_OFFSET_DY uint(2)
//modified ==> NodeBumpOffset




//modify => enum NodeTexVoxelSpace 
#define NodeTexVoxelSpace uint
#define NODE_TEX_VOXEL_SPACE_OBJECT  uint(0)
#define NODE_TEX_VOXEL_SPACE_WORLD  uint(1)
//modified ==> NodeTexVoxelSpace




//modify => enum NodeAO 
#define NodeAO uint
#define NODE_AO_ONLY_LOCAL  uint((1<<0))
#define NODE_AO_INSIDE  uint((1<<1))
#define NODE_AO_GLOBAL_RADIUS  uint((1<<2))
//modified ==> NodeAO




//modify => enum ShaderType 
#define ShaderType uint
#define SHADER_TYPE_SURFACE uint(0)
#define SHADER_TYPE_VOLUME uint(1)
#define SHADER_TYPE_DISPLACEMENT uint(2)
#define SHADER_TYPE_BUMP uint(3)
//modified ==> ShaderType




//modify => enum NodePrincipledHairParametrization 
#define NodePrincipledHairParametrization uint
#define NODE_PRINCIPLED_HAIR_REFLECTANCE  uint(0)
#define NODE_PRINCIPLED_HAIR_PIGMENT_CONCENTRATION  uint(1)
#define NODE_PRINCIPLED_HAIR_DIRECT_ABSORPTION  uint(2)
#define NODE_PRINCIPLED_HAIR_NUM uint(3)
//modified ==> NodePrincipledHairParametrization




/* Closure */

//modify => enum ClosureType 
#define ClosureType uint
#define CLOSURE_NONE_ID uint(0)
#define CLOSURE_BSDF_ID uint(1)
#define CLOSURE_BSDF_DIFFUSE_ID uint(2)
#define CLOSURE_BSDF_OREN_NAYAR_ID uint(3)
#define CLOSURE_BSDF_DIFFUSE_RAMP_ID uint(4)
#define CLOSURE_BSDF_PRINCIPLED_DIFFUSE_ID uint(5)
#define CLOSURE_BSDF_PRINCIPLED_SHEEN_ID uint(6)
#define CLOSURE_BSDF_DIFFUSE_TOON_ID uint(7)
#define CLOSURE_BSDF_TRANSLUCENT_ID uint(8)
#define CLOSURE_BSDF_REFLECTION_ID uint(9)
#define CLOSURE_BSDF_MICROFACET_GGX_ID uint(10)
#define CLOSURE_BSDF_MICROFACET_GGX_FRESNEL_ID uint(11)
#define CLOSURE_BSDF_MICROFACET_GGX_CLEARCOAT_ID uint(12)
#define CLOSURE_BSDF_MICROFACET_BECKMANN_ID uint(13)
#define CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID uint(14)
#define CLOSURE_BSDF_MICROFACET_MULTI_GGX_FRESNEL_ID uint(15)
#define CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID uint(16)
#define CLOSURE_BSDF_ASHIKHMIN_VELVET_ID uint(17)
#define CLOSURE_BSDF_PHONG_RAMP_ID uint(18)
#define CLOSURE_BSDF_GLOSSY_TOON_ID uint(19)
#define CLOSURE_BSDF_HAIR_REFLECTION_ID uint(20)
#define CLOSURE_BSDF_REFRACTION_ID uint(21)
#define CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID uint(22)
#define CLOSURE_BSDF_MICROFACET_GGX_REFRACTION_ID uint(23)
#define CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID uint(24)
#define CLOSURE_BSDF_MICROFACET_BECKMANN_GLASS_ID uint(25)
#define CLOSURE_BSDF_MICROFACET_GGX_GLASS_ID uint(26)
#define CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_FRESNEL_ID uint(27)
#define CLOSURE_BSDF_SHARP_GLASS_ID uint(28)
#define CLOSURE_BSDF_HAIR_PRINCIPLED_ID uint(29)
#define CLOSURE_BSDF_HAIR_TRANSMISSION_ID uint(30)
#define CLOSURE_BSDF_BSSRDF_ID uint(31)
#define CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID uint(32)
#define CLOSURE_BSDF_TRANSPARENT_ID uint(33)
#define CLOSURE_BSSRDF_CUBIC_ID uint(34)
#define CLOSURE_BSSRDF_GAUSSIAN_ID uint(35)
#define CLOSURE_BSSRDF_PRINCIPLED_ID uint(36)
#define CLOSURE_BSSRDF_BURLEY_ID uint(37)
#define CLOSURE_BSSRDF_RANDOM_WALK_ID uint(38)
#define CLOSURE_BSSRDF_PRINCIPLED_RANDOM_WALK_ID uint(39)
#define CLOSURE_HOLDOUT_ID uint(40)
#define CLOSURE_VOLUME_ID uint(41)
#define CLOSURE_VOLUME_ABSORPTION_ID uint(42)
#define CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID uint(43)
#define CLOSURE_BSDF_PRINCIPLED_ID uint(44)
#define NBUILTIN_CLOSURES uint(45)
//modified ==> ClosureType




/* watch this, being lazy with memory usage */
#define CLOSURE_IS_BSDF(type) (type <= CLOSURE_BSDF_TRANSPARENT_ID)
#define CLOSURE_IS_BSDF_DIFFUSE(type) \
  (type >= CLOSURE_BSDF_DIFFUSE_ID && type <= CLOSURE_BSDF_TRANSLUCENT_ID)
#define CLOSURE_IS_BSDF_GLOSSY(type) \
  ((type >= CLOSURE_BSDF_REFLECTION_ID && type <= CLOSURE_BSDF_HAIR_REFLECTION_ID) || \
   (type == CLOSURE_BSDF_HAIR_PRINCIPLED_ID))
#define CLOSURE_IS_BSDF_TRANSMISSION(type) \
  (type >= CLOSURE_BSDF_REFRACTION_ID && type <= CLOSURE_BSDF_HAIR_TRANSMISSION_ID)
#define CLOSURE_IS_BSDF_BSSRDF(type) \
  (type == CLOSURE_BSDF_BSSRDF_ID || type == CLOSURE_BSDF_BSSRDF_PRINCIPLED_ID)
#define CLOSURE_IS_BSDF_SINGULAR(type) \
  (type == CLOSURE_BSDF_REFLECTION_ID || type == CLOSURE_BSDF_REFRACTION_ID || \
   type == CLOSURE_BSDF_TRANSPARENT_ID)
#define CLOSURE_IS_BSDF_TRANSPARENT(type) (type == CLOSURE_BSDF_TRANSPARENT_ID)
#define CLOSURE_IS_BSDF_MULTISCATTER(type) \
  (type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_ID || \
   type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID)
#define CLOSURE_IS_BSDF_MICROFACET(type) \
  ((type >= CLOSURE_BSDF_MICROFACET_GGX_ID && type <= CLOSURE_BSDF_ASHIKHMIN_SHIRLEY_ID) || \
   (type >= CLOSURE_BSDF_MICROFACET_BECKMANN_REFRACTION_ID && \
    type <= CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID) || \
   (type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_FRESNEL_ID))
#define CLOSURE_IS_BSDF_MICROFACET_FRESNEL(type) \
  (type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_FRESNEL_ID || \
   type == CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_FRESNEL_ID || \
   type == CLOSURE_BSDF_MICROFACET_GGX_FRESNEL_ID || \
   type == CLOSURE_BSDF_MICROFACET_GGX_CLEARCOAT_ID)
#define CLOSURE_IS_BSDF_OR_BSSRDF(type) (type <= CLOSURE_BSSRDF_PRINCIPLED_RANDOM_WALK_ID)
#define CLOSURE_IS_BSSRDF(type) \
  (type >= CLOSURE_BSSRDF_CUBIC_ID && type <= CLOSURE_BSSRDF_PRINCIPLED_RANDOM_WALK_ID)
#define CLOSURE_IS_DISK_BSSRDF(type) \
  (type >= CLOSURE_BSSRDF_CUBIC_ID && type <= CLOSURE_BSSRDF_BURLEY_ID)
#define CLOSURE_IS_VOLUME(type) \
  (type >= CLOSURE_VOLUME_ID && type <= CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID)
#define CLOSURE_IS_VOLUME_SCATTER(type) (type == CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID)
#define CLOSURE_IS_VOLUME_ABSORPTION(type) (type == CLOSURE_VOLUME_ABSORPTION_ID)
#define CLOSURE_IS_HOLDOUT(type) (type == CLOSURE_HOLDOUT_ID)
#define CLOSURE_IS_PHASE(type) (type == CLOSURE_VOLUME_HENYEY_GREENSTEIN_ID)
#define CLOSURE_IS_GLASS(type) \
  (type >= CLOSURE_BSDF_MICROFACET_MULTI_GGX_GLASS_ID && type <= CLOSURE_BSDF_SHARP_GLASS_ID)
#define CLOSURE_IS_PRINCIPLED(type) (type == CLOSURE_BSDF_PRINCIPLED_ID)

#define CLOSURE_WEIGHT_CUTOFF 1e-5f

CCL_NAMESPACE_END

#endif /*  _SVM_TYPES_H_ */
