#ifndef _KERNEL_COMPAT_VULKAN_H_
#define _KERNEL_COMPAT_VULKAN_H_

#define OPTIX_DONT_INCLUDE_CUDA


#define _KERNEL_GPU_
#define _KERNEL_VULKAN_  


#define CCL_NAMESPACE_BEGIN
#define CCL_NAMESPACE_END

#ifndef ATTR_FALLTHROUGH
#  define ATTR_FALLTHROUGH
#endif


/* Python Convert
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef unsigned short half;
typedef unsigned long long CUtexObject;
*/


#define FLT_MIN 1.175494350822287507969e-38f
#define FLT_MAX 340282346638528859811704183484516925440.0f
#define FLT_EPSILON 1.192092896e-07F
#define DBL_MAX          1.7976931348623158e+308 

/* float16_t()
_device_ half _float2half(const float f)
{
  half val;
  asm("{  cvt.rn.f16.f32 %0, %1;}\n" : "=h"(val) : "f"(f));
  return val;
}
*/

/* Selective nodes compilation. */
#ifndef _NODES_MAX_GROUP_
#  define _NODES_MAX_GROUP_ NODE_GROUP_LEVEL_MAX
#endif
#ifndef _NODES_FEATURES_
#  define _NODES_FEATURES_ NODE_FEATURE_ALL
#endif

#define ccl_device 
#define ccl_device_inline ccl_device
#define ccl_device_forceinline ccl_device
#define ccl_device_noinline 
#define ccl_device_noinline_cpu ccl_device
#define ccl_global

/* constant push or buffer or emmbed
#define ccl_static_constant _constant_
*/

#define ccl_constant const
#define ccl_local
#define ccl_local_param
#define ccl_private
#define ccl_may_alias
#define ccl_addr_space
#define ccl_loop_no_unroll
#define ccl_restrict 
#define ccl_ref
//  layout  offset
#define ccl_align(n) 


// Zero initialize structs to help the compiler figure out scoping
#define ccl_optional_struct_init 

///#define kernel_data kd  // See kernel_globals.h
#define kernel_tex_array(t) push.data_ptr.t.data
#define kernel_tex_fetch(t, index) kernel_tex_array(t)[(index)]
#define kernel_tex_fetch_vindex(t,i) uvec3( kernel_tex_fetch(t,3*i), kernel_tex_fetch(t,3*i + 1) ,kernel_tex_fetch(t,3*i + 2 ))


//Format for specifier is "%"precision <d, i, o, u, x, X, a, A, e, E, f, F, g, G, or ul>
//Format for vector specifier is "%"precision"v" [2, 3, or 4] [specifiers list above]  
//https://github.com/KhronosGroup/Vulkan-ValidationLayers/blob/master/tests/vklayertests_gpu.cpp
#extension GL_EXT_debug_printf : enable
#define kernel_assert(msg,cond) {if(!bool(cond))debugPrintfEXT(msg);};

//#define kernel_assert(cond)
/* Types */

//#include "util/util_half.h"
//#include "util/util_types.h"

#endif /* _KERNEL_COMPAT_VULKAN_H_ */
