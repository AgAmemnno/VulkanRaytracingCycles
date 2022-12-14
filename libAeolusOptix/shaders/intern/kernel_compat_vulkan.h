#ifndef __KERNEL_COMPAT_VULKAN_H__
#define __KERNEL_COMPAT_VULKAN_H__

#define OPTIX_DONT_INCLUDE_CUDA


#define __KERNEL_GPU__
#define __KERNEL_VULKAN__  


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


/* float16_t()
__device__ half __float2half(const float f)
{
  half val;
  asm("{  cvt.rn.f16.f32 %0, %1;}\n" : "=h"(val) : "f"(f));
  return val;
}
*/

/* Selective nodes compilation. */
#ifndef __NODES_MAX_GROUP__
#  define __NODES_MAX_GROUP__ NODE_GROUP_LEVEL_MAX
#endif
#ifndef __NODES_FEATURES__
#  define __NODES_FEATURES__ NODE_FEATURE_ALL
#endif

#define ccl_device 
#define ccl_device_inline ccl_device
#define ccl_device_forceinline ccl_device
#define ccl_device_noinline 
#define ccl_device_noinline_cpu ccl_device
#define ccl_global

/* constant push or buffer or emmbed
#define ccl_static_constant __constant__
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

/*#define kernel_data kd  // See kernel_globals.h*/
#define kernel_tex_array(t) push.data_ptr.t.data
#define kernel_tex_fetch(t, index) kernel_tex_array(t)[(index)]
#define kernel_tex_fetch_vindex(t,i) uvec3( kernel_tex_fetch(t,3*i), kernel_tex_fetch(t,3*i + 1) ,kernel_tex_fetch(t,3*i + 2 ))

//#extension GL_EXT_debug_printf : enable
//#define kernel_assert(cond) {if(!bool(cond))debugPrintfEXT(" !!!!!!!!!!!  assertion failed !!!!!!!!!!  TODO file line \n");};

#define kernel_assert(cond)
/* Types */

//#include "util/util_half.h"
//#include "util/util_types.h"

#endif /* __KERNEL_COMPAT_VULKAN_H__ */
