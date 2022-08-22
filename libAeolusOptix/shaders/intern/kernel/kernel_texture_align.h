
#ifndef _KERNEL_TEX_ALIGN_H_
#define _KERNEL_TEX_ALIGN_H_

/* check size */
#define sizeof_BsdfEval   4*(6*4 + 1)




/*alignment must be a power of 2 for buffer reference.*/

#define sizeof_float  4
#define alignof_float  4
#define sizeof_float2 8
#define alignof_float2 8
#define sizeof_float3 16
#define alignof_float3 16
#define sizeof_float4 16
#define alignof_float4 16

#define sizeof_int  4
#define alignof_int  4
#define sizeof_int2 8
#define alignof_int2 8
#define sizeof_int3 12
#define alignof_int3 16
#define sizeof_int4 16
#define alignof_int4 16

#define sizeof_uint  4
#define alignof_uint  4
#define sizeof_uint2 8
#define alignof_uint2 8
#define sizeof_uint3 12
#define alignof_uint3 4
#define sizeof_uint4 16
#define alignof_uint4 16

#define sizeof_uchar  1
#define alignof_uchar  2
#define sizeof_uchar2 2
#define alignof_uchar2 2
#define sizeof_uchar3 3
#define alignof_uchar3 4
#define sizeof_uchar4 4
#define alignof_uchar4 4


#define sizeof_Transform 48
#define alignof_Transform 64

#define sizeof_DecomposedTransform 64
#define alignof_DecomposedTransform 64

#define  sizeof_KernelObject  192
#define  alignof_KernelObject 256


#define sizeof_KernelLightDistribution  16
#define alignof_KernelLightDistribution 16
#define sizeof_KernelLight  192
#define alignof_KernelLight 256

#define sizeof_KernelParticle  80
#define alignof_KernelParticle 128

#define sizeof_KernelShader  24
#define alignof_KernelShader 32


#define sizeof_ShaderClosure  144
#define alignof_ShaderClosure 256

#define sizeof_TextureInfo  96
#define alignof_TextureInfo 128


#define sizeof_Intersection  24
#define alignof_Intersection 8


#define isnullptr(a) (uint64_t(a) == 1095199817470UL)

#endif