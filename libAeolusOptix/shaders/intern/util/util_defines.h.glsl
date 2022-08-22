
/*
 * Copyright 2011-2017 Blender Foundation
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

/* clang-format off */

/* #define _forceinline triggers a bug in some clang-format versions, disable
 * format for entire file to keep results consistent. */

#ifndef _UTIL_DEFINES_H_
#define _UTIL_DEFINES_H_

/* Bitness */

#if defined(_ppc64_) || defined(_PPC64_) || defined(_x86_64_) || defined(_ia64_) || \
    defined(_M_X64)
#  define _KERNEL_64_BIT_
#endif

/* Qualifiers for kernel code shared by CPU and GPU */

#ifndef _KERNEL_GPU_
#  define ccl_device static inline
#  define ccl_device_noinline static
#  define ccl_device_noinline_cpu ccl_device_noinline
#  define ccl_global
#  define ccl_static_constant static const
#  define ccl_constant const
#  define ccl_local
#  define ccl_local_param
#  define ccl_private
#  define ccl_restrict _restrict
#  define ccl_ref &
#  define ccl_optional_struct_init
#  define ccl_loop_no_unroll
#  define _KERNEL_WITH_SSE_ALIGN_

#  if defined(_WIN32) && !defined(FREE_WINDOWS)
#    define ccl_device_inline static _forceinline
#    define ccl_device_forceinline static _forceinline
#    define ccl_align(...) _declspec(align(_VA_ARGS_))
#    ifdef _KERNEL_64_BIT_
#      define ccl_try_align(...) _declspec(align(_VA_ARGS_))
#    else /* _KERNEL_64_BIT_ */
#      undef _KERNEL_WITH_SSE_ALIGN_
/* No support for function arguments (error C2719). */
#      define ccl_try_align(...)
#    endif /* _KERNEL_64_BIT_ */
#    define ccl_may_alias
#    define ccl_always_inline _forceinline
#    define ccl_never_inline _declspec(noinline)
#    define ccl_maybe_unused
#  else /* _WIN32 && !FREE_WINDOWS */
#    define ccl_device_inline static inline _attribute_((always_inline))
#    define ccl_device_forceinline static inline _attribute_((always_inline))
#    define ccl_align(...) _attribute_((aligned(_VA_ARGS_)))
#    ifndef FREE_WINDOWS64
#      define _forceinline inline _attribute_((always_inline))
#    endif
#    define ccl_try_align(...) _attribute_((aligned(_VA_ARGS_)))
#    define ccl_may_alias _attribute_((_may_alias_))
#    define ccl_always_inline _attribute_((always_inline))
#    define ccl_never_inline _attribute_((noinline))
#    define ccl_maybe_unused _attribute_((used))
#  endif /* _WIN32 && !FREE_WINDOWS */

/* Use to suppress '-Wimplicit-fallthrough' (in place of 'break'). */
#  ifndef ATTR_FALLTHROUGH
#    if defined(_GNUC_) && (_GNUC_ >= 7) /* gcc7.0+ only */
#      define ATTR_FALLTHROUGH _attribute_((fallthrough))
#    else
#      define ATTR_FALLTHROUGH ((void)0)
#    endif
#  endif
#endif /* _KERNEL_GPU_ */

/* macros */

/* hints for branch prediction, only use in code that runs a _lot_ */
#if defined(_GNUC_) && defined(_KERNEL_CPU_)
#  define LIKELY(x) _builtin_expect(!!(x), 1)
#  define UNLIKELY(x) _builtin_expect(!!(x), 0)
#else
#  define LIKELY(x) (x)
#  define UNLIKELY(x) (x)
#endif

#if defined(_GNUC_) || defined(_clang_)
#  if defined(_cplusplus)
/* Some magic to be sure we don't have reference in the type. */
template<typename T> static inline T decltype_helper(T x)
{
  return x;
}
#    define TYPEOF(x) decltype(decltype_helper(x))
#  else
#    define TYPEOF(x) typeof(x)
#  endif
#endif

/* Causes warning:
 * incompatible types when assigning to type 'Foo' from type 'Bar'
 * ... the compiler optimizes away the temp var */
#ifdef _GNUC_
#  define CHECK_TYPE(var, type) \
    { \
      TYPEOF(var) * _tmp; \
      _tmp = (type *)NULL; \
      (void)_tmp; \
    } \
    (void)0

#  define CHECK_TYPE_PAIR(var_a, var_b) \
    { \
      TYPEOF(var_a) * _tmp; \
      _tmp = (typeof(var_b) *)NULL; \
      (void)_tmp; \
    } \
    (void)0
#else
#  define CHECK_TYPE(var, type)
#  define CHECK_TYPE_PAIR(var_a, var_b)
#endif

/* can be used in simple macros */
#ifndef _KERNEL_VULKAN_
#define CHECK_TYPE_INLINE(val, type) ((void)(((type)0) != (val)))
#else
#define CHECK_TYPE_INLINE(val, type)
#endif

#ifndef _KERNEL_GPU_
#  include <cassert>
#  define util_assert(statement) assert(statement)
#else
#  define util_assert(statement)
#endif

#endif /* _UTIL_DEFINES_H_ */
