  set(CYCLES_INSTALL_PATH "")

# External Libraries     include(cmake/external_libs.cmake)

###########################################################################
# Precompiled libraries tips and hints, for find_package().

include(cmake/macros.cmake)

# Build Flags
# todo: this code could be refactored a bit to avoid duplication
# note: CXX_HAS_SSE is needed in case passing SSE flags fails altogether (gcc-arm)

set(WITH_CYCLES_LOGGING OFF)

list(APPEND CYCLES_DEF 
-D_CRT_SECURE_NO_WARNINGS
-D_CRT_NONSTDC_NO_DEPRECATE
-D_CRT_SECURE_NO_DEPRECATE
-D_SCL_SECURE_NO_DEPRECATE
-DDEBUG
-D_DEBUG
-D_CONSOLE
-D_LIB
-D_ALLOW_KEYWORD_MACROS
-D_WIN32_WINNT=0x601
-DOIIO_STATIC_DEFINE
-DOIIO_NO_SSE=1
-DWITH_TBB_MALLOC
-D__SSE__
-D__MMX__
-D__SSE2__
-D__LITTLE_ENDIAN__
-DWITH_OPENGL
-DWITH_ASSERT_ABORT
-DWITH_KERNEL_SSE2
-DWITH_KERNEL_SSE3
-DWITH_KERNEL_SSE41
-DWITH_KERNEL_AVX
-DWITH_KERNEL_AVX2
-DBOOST_ALL_NO_LIB
-DUSE_TBB=0
#WITH_OSL
#OSL_STATIC_BUILD
#OSL_STATIC_LIBRARY
#WITH_OPTIX
#WITH_EMBREE
#EMBREE_STATIC_LIB
#WITH_OPENSUBDIV

#WITH_CYCLES_LOGGING
#GOOGLE_GLOG_DLL_DECL=
#CYCLES_GFLAGS_NAMESPACE=gflags

-DWITH_SYSTEM_PUGIXML
#WITH_BLENDER_GUARDEDALLOC
-DWITH_GL_PROFILE_CORE
-DGLEW_STATIC
-DGLEW_NO_ES
-DGLEW_NO_GLU
-DCMAKE_INTDIR="Debug"
)

if(MULTIMODE STREQUAL  "MTd")
add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
endif(MULTIMODE STREQUAL  "MTd")

  message(" CMAKE_CXX_COMPILER_ID  ${CMAKE_CXX_COMPILER_ID}")


  set(CXX_HAS_SSE TRUE)
  set(CXX_HAS_AVX TRUE)
  set(CXX_HAS_AVX2 TRUE)
  set(CYCLES_AVX_ARCH_FLAGS "/arch:AVX") 
  set(CYCLES_AVX2_ARCH_FLAGS "/arch:AVX /arch:AVX2")
  # Unlike GCC/clang we still use fast math, because there is no fine
  # grained control and the speedup we get here is too big to ignore.
  set(CYCLES_KERNEL_FLAGS "/fp:fast -D_CRT_SECURE_NO_WARNINGS /GS-")

  # there is no /arch:SSE3, but intrinsics are available anyway
  if(CMAKE_CL_64)
    set(CYCLES_SSE2_KERNEL_FLAGS "${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_SSE3_KERNEL_FLAGS "${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_SSE41_KERNEL_FLAGS "${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_AVX_KERNEL_FLAGS "${CYCLES_AVX_ARCH_FLAGS} ${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_AVX2_KERNEL_FLAGS "${CYCLES_AVX2_ARCH_FLAGS} ${CYCLES_KERNEL_FLAGS}")
  else()
    set(CYCLES_SSE2_KERNEL_FLAGS "/arch:SSE2 ${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_SSE3_KERNEL_FLAGS "/arch:SSE2 ${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_SSE41_KERNEL_FLAGS "/arch:SSE2 ${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_AVX_KERNEL_FLAGS "${CYCLES_AVX_ARCH_FLAGS} ${CYCLES_KERNEL_FLAGS}")
    set(CYCLES_AVX2_KERNEL_FLAGS "${CYCLES_AVX2_ARCH_FLAGS} ${CYCLES_KERNEL_FLAGS}")
  endif()

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CYCLES_KERNEL_FLAGS}")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Ox")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /Ox")
  set(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} /Ox")


# LLVM and OSL need to build without RTTI
if(WIN32 AND MSVC)
  set(RTTI_DISABLE_FLAGS "/GR- -DBOOST_NO_RTTI -DBOOST_NO_TYPEID")
elseif(CMAKE_COMPILER_IS_GNUCC OR (CMAKE_C_COMPILER_ID MATCHES "Clang"))
  set(RTTI_DISABLE_FLAGS "-fno-rtti -DBOOST_NO_RTTI -DBOOST_NO_TYPEID")
endif()






if(WITH_CYCLES_STANDALONE_GUI)
  add_definitions(-DWITH_CYCLES_STANDALONE_GUI)
endif()

if(WITH_CYCLES_PTEX)
  add_definitions(-DWITH_PTEX)
endif()

if(WITH_CYCLES_OSL)
  add_definitions(-DWITH_OSL)
  # osl 1.9.x
  add_definitions(-DOSL_STATIC_BUILD)
  # pre 1.9
  add_definitions(-DOSL_STATIC_LIBRARY)
  include_directories(
    SYSTEM
    ${OSL_INCLUDE_DIR}
  )
endif()

if(WITH_CYCLES_DEVICE_OPTIX)
  find_package(OptiX)
   message(STATUS "WITH_CYCLES_DEVICE_OPTIX ON ==> find optix ${OPTIX_FOUND}")
  if(OPTIX_FOUND)
    add_definitions(-DWITH_OPTIX)
    include_directories(
      SYSTEM
      ${OPTIX_INCLUDE_DIR}
      )
  else()
    message(STATUS "OptiX not found, disabling it from Cycles")
    set(WITH_CYCLES_DEVICE_OPTIX OFF)
  endif()
endif()

if(WITH_CYCLES_EMBREE)
  add_definitions(-DWITH_EMBREE)
  add_definitions(-DEMBREE_STATIC_LIB)
  include_directories(
    SYSTEM
    ${EMBREE_INCLUDE_DIRS}
  )
endif()

if(WITH_OPENSUBDIV)
  add_definitions(-DWITH_OPENSUBDIV)
  include_directories(
    SYSTEM
    ${OPENSUBDIV_INCLUDE_DIR}
  )
endif()

if(WITH_CYCLES_STANDALONE)
  set(WITH_CYCLES_DEVICE_OPENCL TRUE)
  set(WITH_CYCLES_DEVICE_CUDA TRUE)
  # Experimental and unfinished.
  set(WITH_CYCLES_NETWORK FALSE)
endif()
# TODO(sergey): Consider removing it, only causes confusion in interface.
set(WITH_CYCLES_DEVICE_MULTI TRUE)

# Logging capabilities using GLog library.
if(WITH_CYCLES_LOGGING)
  add_definitions(-DWITH_CYCLES_LOGGING)
  add_definitions(-DGOOGLE_GLOG_DLL_DECL=
                           -DCYCLES_GFLAGS_NAMESPACE=gflags)

  include_directories(
    SYSTEM
    ${GLOG_INCLUDE_DIRS}
    ${GFLAGS_INCLUDE_DIRS}
  )
endif()

# Debugging capabilities (debug passes etc).
if(WITH_CYCLES_DEBUG)
  add_definitions(-DWITH_CYCLES_DEBUG)
endif()


#import_oiio()

if(NOT OPENIMAGEIO_PUGIXML_FOUND)
  add_definitions(-DWITH_SYSTEM_PUGIXML)
endif()

include_directories(
  SYSTEM
  ${BLENDER_INCLUDE}
)

if(CYCLES_STANDALONE_REPOSITORY)
  include_directories(../third_party/atomic)
else()
  include_directories(../atomic)
endif()

# Warnings
if(CMAKE_COMPILER_IS_GNUCXX)
  ADD_CHECK_CXX_COMPILER_FLAG(CMAKE_CXX_FLAGS _has_cxxflag_float_conversion "-Werror=float-conversion")
  ADD_CHECK_CXX_COMPILER_FLAG(CMAKE_CXX_FLAGS _has_cxxflag_double_promotion "-Werror=double-promotion")
  ADD_CHECK_CXX_COMPILER_FLAG(CMAKE_CXX_FLAGS _has_no_error_unused_macros "-Wno-error=unused-macros")
  unset(_has_cxxflag_float_conversion)
  unset(_has_cxxflag_double_promotion)
  unset(_has_no_error_unused_macros)
endif()

if(WITH_CYCLES_CUDA_BINARIES AND (NOT WITH_CYCLES_CUBIN_COMPILER))
  if(MSVC)
    set(MAX_MSVC 1800)
    if(${CUDA_VERSION} EQUAL "8.0")
      set(MAX_MSVC 1900)
    elseif(${CUDA_VERSION} EQUAL "9.0")
      set(MAX_MSVC 1910)
    elseif(${CUDA_VERSION} EQUAL "9.1")
      set(MAX_MSVC 1911)
    elseif(${CUDA_VERSION} LESS "11.0")
      set(MAX_MSVC 1999)
    endif()
    if(NOT MSVC_VERSION LESS ${MAX_MSVC} OR CMAKE_C_COMPILER_ID MATCHES "Clang")
      message(STATUS "nvcc not supported for this compiler version, using cycles_cubin_cc instead.")
      set(WITH_CYCLES_CUBIN_COMPILER ON)
    endif()
    unset(MAX_MSVC)
  elseif(APPLE)
    if(NOT (${XCODE_VERSION} VERSION_LESS 10.0))
      message(STATUS "nvcc not supported for this compiler version, using cycles_cubin_cc instead.")
      set(WITH_CYCLES_CUBIN_COMPILER ON)
    endif()
  endif()
endif()

# NVRTC gives wrong rendering result in CUDA 10.0, so we must use NVCC.
if(WITH_CYCLES_CUDA_BINARIES AND WITH_CYCLES_CUBIN_COMPILER AND NOT WITH_CYCLES_CUBIN_COMPILER_OVERRRIDE)
  if(NOT (${CUDA_VERSION} VERSION_LESS 10.0))
    message(STATUS "cycles_cubin_cc not supported for CUDA 10.0+, using nvcc instead.")
    set(WITH_CYCLES_CUBIN_COMPILER OFF)
  endif()
endif()

# Subdirectories

if(WITH_CYCLES_BLENDER)
  add_definitions(-DWITH_BLENDER_GUARDEDALLOC)
  add_subdirectory(blender)
endif()

if(WITH_CYCLES_NETWORK)
  add_definitions(-DWITH_NETWORK)
endif()

if(WITH_CYCLES_STANDALONE OR WITH_CYCLES_NETWORK OR WITH_CYCLES_CUBIN_COMPILER)
  add_subdirectory(app)
endif()



add_compile_options(
  "$<$<CONFIG:DEBUG>:-${MULTIMODE};-GS;-Gd;-Gm-;-Od>"
)
 
add_definitions(${CYCLES_DEF})
add_definitions(
  -DCCL_NAMESPACE_BEGIN=namespace\ ccl\ {
  -DCCL_NAMESPACE_END=}
)




add_subdirectory(bvh)
add_subdirectory(graph)

#add_subdirectory(doc)
#
add_subdirectory(kernel)
add_subdirectory(render)
add_subdirectory(subd)
add_subdirectory(util)

# TODO(sergey): Make this to work with standalone repository.
#if(WITH_GTESTS)
# add_subdirectory(test)
#endif()

if(NOT WITH_BLENDER AND WITH_CYCLES_STANDALONE)
  delayed_do_install(${CMAKE_BINARY_DIR}/bin)
endif()
