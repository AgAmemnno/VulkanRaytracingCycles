cmake_minimum_required(VERSION 3.10)

include(${CMAKE_HOME_DIRECTORY}/cmake/utils_macro.cmake)
set(FIRST_RUN TRUE)
if(NOT EXECUTABLE_OUTPUT_PATH)
  set(FIRST_RUN TRUE)
else()
  set(FIRST_RUN FALSE)
endif()
# avoid having empty buildtype
if(NOT DEFINED CMAKE_BUILD_TYPE_INIT)
  set(CMAKE_BUILD_TYPE_INIT "Release")
endif()
# Omit superfluous "Up-to-date" messages.
if(NOT DEFINED CMAKE_INSTALL_MESSAGE)
  set(CMAKE_INSTALL_MESSAGE "LAZY")
endif()

# quiet output for Makefiles, 'make -s' helps too
# set_property(GLOBAL PROPERTY RULE_MESSAGES OFF)
# global compile definitions since add_definitions() adds for all.
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
  $<$<CONFIG:Debug>:DEBUG;_DEBUG>
  $<$<CONFIG:Release>:NDEBUG>
  $<$<CONFIG:MinSizeRel>:NDEBUG>
  $<$<CONFIG:RelWithDebInfo>:NDEBUG>
)




set(MAKES_DNA_PATH  ${CMAKE_BINARY_DIR}/bin CACHE INTERNAL "" FORCE)
#message(STATUS   "Current directory " ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_SOURCE_DIR})


current_dir_modify(TRUE)

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  if(NOT DEFINED WITH_IN_SOURCE_BUILD)
    message(FATAL_ERROR
      "CMake generation for blender is not allowed within the source directory!"
      "\n Remove \"${CMAKE_SOURCE_DIR}/CMakeCache.txt\" and try again from another folder, e.g.:"
      "\n "
      "\n rm CMakeCache.txt"
      "\n cd .."
      "\n mkdir cmake-make"
      "\n cd cmake-make"
      "\n cmake ../blender"
      "\n "
      "\n Alternately define WITH_IN_SOURCE_BUILD to force this option (not recommended!)"
    )
  endif()
endif()



include(build_files/cmake/macros.cmake)



Check_Cached_Dirs()

configure_blender()

blender_project_hack_pre()

project(Blender)

blender_project_hack_post()

enable_testing()


set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}/bin CACHE INTERNAL "" FORCE)
set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib CACHE INTERNAL "" FORCE)
if(MSVC)
  set(TESTS_OUTPUT_DIR ${EXECUTABLE_OUTPUT_PATH}/tests/$<CONFIG>/ CACHE INTERNAL "" FORCE)
else()
  set(TESTS_OUTPUT_DIR ${EXECUTABLE_OUTPUT_PATH}/tests/ CACHE INTERNAL "" FORCE)
endif()

#-----------------------------------------------------------------------------
# Set default config options

get_blender_version()


if(NOT WITH_SYSTEM_EIGEN3)
  set(EIGEN3_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/extern/Eigen3)
endif()


set(LIBAEOLUS_DIRS  "${CMAKE_HOME_DIRECTORY}/lib" CACHE INTERNAL "Aeolus external Libraray " FORCE)
set(LIBDIR "D:/blender/src/lib/win64_vc15" CACHE INTERNAL "BLENDER SVN Libraray " FORCE)

# ----------------------------------------------------------------------------
# Main Platform Checks
#
# - UNIX
# - WIN32
# - APPLE

if(UNIX AND NOT APPLE)
  include(platform_unix)
elseif(WIN32)
  include(platform_win32)
elseif(APPLE)
  include(platform_apple)
endif()


message("                      ZLIBS    ${ZLIB_LIBRARIES}  ")



# set the endian define
if(MSVC)
  # for some reason this fails on msvc
  add_definitions(-D__LITTLE_ENDIAN__)

  # OSX-Note: as we do cross-compiling with specific set architecture,
  # endianess-detection and auto-setting is counterproductive
  # so we just set endianness according CMAKE_OSX_ARCHITECTURES

elseif(CMAKE_OSX_ARCHITECTURES MATCHES i386 OR CMAKE_OSX_ARCHITECTURES MATCHES x86_64 OR CMAKE_OSX_ARCHITECTURES MATCHES arm64)
  add_definitions(-D__LITTLE_ENDIAN__)
elseif(CMAKE_OSX_ARCHITECTURES MATCHES ppc OR CMAKE_OSX_ARCHITECTURES MATCHES ppc64)
  add_definitions(-D__BIG_ENDIAN__)

else()
  include(TestBigEndian)
  test_big_endian(_SYSTEM_BIG_ENDIAN)
  if(_SYSTEM_BIG_ENDIAN)
    add_definitions(-D__BIG_ENDIAN__)
  else()
    add_definitions(-D__LITTLE_ENDIAN__)
  endif()
  unset(_SYSTEM_BIG_ENDIAN)
endif()


#-----------------------------------------------------------------------------
# Configure GLog/GFlags

config_gtest()

configure_openGL()





















#-----------------------------------------------------------------------    internal  libraries  














#-----------------------------------------------------------------------
# Extra limits to number of jobs running in parallel for some kind os tasks.
# Only supported by Ninja build system currently.
if("${CMAKE_GENERATOR}" MATCHES "Ninja" AND WITH_NINJA_POOL_JOBS)
  if(NOT NINJA_MAX_NUM_PARALLEL_COMPILE_JOBS AND
     NOT NINJA_MAX_NUM_PARALLEL_COMPILE_HEAVY_JOBS AND
     NOT NINJA_MAX_NUM_PARALLEL_LINK_JOBS)
    # Try to define good default values.
    # Max mem of heavy cpp files compilation: about 2.5GB
    # Max mem during linking: about 3.3GB
    cmake_host_system_information(RESULT _NUM_CORES QUERY NUMBER_OF_LOGICAL_CORES)
    # Note: this gives mem in MB.
    cmake_host_system_information(RESULT _TOT_MEM QUERY TOTAL_PHYSICAL_MEMORY)

    # Heuristics... the more cores we have, the more free mem we have to keep for the non-heavy tasks too.
    if(${_TOT_MEM} LESS 8000 AND ${_NUM_CORES} GREATER 2)
      set(_compile_heavy_jobs "1")
    elseif(${_TOT_MEM} LESS 16000 AND ${_NUM_CORES} GREATER 4)
      set(_compile_heavy_jobs "2")
    elseif(${_TOT_MEM} LESS 24000 AND ${_NUM_CORES} GREATER 8)
      set(_compile_heavy_jobs "3")
    elseif(${_TOT_MEM} LESS 32000 AND ${_NUM_CORES} GREATER 16)
      set(_compile_heavy_jobs "4")
    elseif(${_TOT_MEM} LESS 64000 AND ${_NUM_CORES} GREATER 32)
      set(_compile_heavy_jobs "8")
    else()
      set(_compile_heavy_jobs "")
    endif()

    set(NINJA_MAX_NUM_PARALLEL_COMPILE_HEAVY_JOBS "${_compile_heavy_jobs}" CACHE STRING
        "Define the maximum number of concurrent heavy compilation jobs, for ninja build system (used for some targets which cpp files can take several GB each during compilation)." FORCE)
    mark_as_advanced(NINJA_MAX_NUM_PARALLEL_COMPILE_HEAVY_JOBS)
    set(_compile_heavy_jobs)

    # Only set regular compile jobs if we set heavy jobs, otherwise default (using all cores) if fine.
    if(NINJA_MAX_NUM_PARALLEL_COMPILE_HEAVY_JOBS)
      math(EXPR _compile_jobs "${_NUM_CORES} - 1")
    else()
      set(_compile_jobs "")
    endif()
    set(NINJA_MAX_NUM_PARALLEL_COMPILE_JOBS "${_compile_jobs}" CACHE STRING
        "Define the maximum number of concurrent compilation jobs, for ninja build system." FORCE)
    mark_as_advanced(NINJA_MAX_NUM_PARALLEL_COMPILE_JOBS)
    set(_compile_jobs)

    # In practice, even when there is RAM available, this proves to be quicker than running in parallel
    # (due to slow disks accesses).
    set(NINJA_MAX_NUM_PARALLEL_LINK_JOBS "1" CACHE STRING
        "Define the maximum number of concurrent link jobs, for ninja build system." FORCE)
    mark_as_advanced(NINJA_MAX_NUM_PARALLEL_LINK_JOBS)

    set(_NUM_CORES)
    set(_TOT_MEM)
  endif()

  if(NINJA_MAX_NUM_PARALLEL_COMPILE_JOBS)
    set_property(GLOBAL APPEND PROPERTY JOB_POOLS compile_job_pool=${NINJA_MAX_NUM_PARALLEL_COMPILE_JOBS})
    set(CMAKE_JOB_POOL_COMPILE compile_job_pool)
  endif()

  if(NINJA_MAX_NUM_PARALLEL_COMPILE_HEAVY_JOBS)
    set_property(GLOBAL APPEND PROPERTY JOB_POOLS compile_heavy_job_pool=${NINJA_MAX_NUM_PARALLEL_COMPILE_HEAVY_JOBS})
  endif()

  if(NINJA_MAX_NUM_PARALLEL_LINK_JOBS)
    set_property(GLOBAL APPEND PROPERTY JOB_POOLS link_job_pool=${NINJA_MAX_NUM_PARALLEL_LINK_JOBS})
    set(CMAKE_JOB_POOL_LINK link_job_pool)
  endif()
endif()

#-----------------------------------------------------------------------------
# Extra compile flags

if(CMAKE_COMPILER_IS_GNUCC)

  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ALL -Wall)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_CAST_ALIGN -Wcast-align)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ERROR_IMPLICIT_FUNCTION_DECLARATION -Werror=implicit-function-declaration)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ERROR_RETURN_TYPE  -Werror=return-type)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ERROR_VLA -Werror=vla)
  # system headers sometimes do this, disable for now, was: -Werror=strict-prototypes
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_STRICT_PROTOTYPES  -Wstrict-prototypes)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_MISSING_PROTOTYPES -Wmissing-prototypes)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_CHAR_SUBSCRIPTS -Wno-char-subscripts)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_UNKNOWN_PRAGMAS -Wno-unknown-pragmas)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_POINTER_ARITH -Wpointer-arith)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_UNUSED_PARAMETER -Wunused-parameter)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_WRITE_STRINGS -Wwrite-strings)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_LOGICAL_OP -Wlogical-op)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_UNDEF -Wundef)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_INIT_SELF -Winit-self)  # needs -Wuninitialized
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_MISSING_INCLUDE_DIRS -Wmissing-include-dirs)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_DIV_BY_ZERO -Wno-div-by-zero)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_TYPE_LIMITS -Wtype-limits)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_FORMAT_SIGN -Wformat-signedness)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_RESTRICT -Wrestrict)

  # C-only.
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_NULL -Wnonnull)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ABSOLUTE_VALUE -Wabsolute-value)

  # gcc 4.2 gives annoying warnings on every file with this
  if(NOT "${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "4.3")
    ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_UNINITIALIZED -Wuninitialized)
  endif()

  # versions before gcc4.6 give many BLI_math warnings
  if(NOT "${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "4.6")
    ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_REDUNDANT_DECLS       -Wredundant-decls)
    ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_REDUNDANT_DECLS -Wredundant-decls)
  endif()

  # versions before gcc4.8 include global name-space.
  if(NOT "${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "4.8")
    ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_SHADOW -Wshadow)
  endif()

  # disable because it gives warnings for printf() & friends.
  # ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_DOUBLE_PROMOTION -Wdouble-promotion -Wno-error=double-promotion)

  if(NOT APPLE)
    ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_ERROR_UNUSED_BUT_SET_VARIABLE -Wno-error=unused-but-set-variable)
  endif()

  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_ALL -Wall)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_INVALID_OFFSETOF -Wno-invalid-offsetof)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_SIGN_COMPARE -Wno-sign-compare)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_LOGICAL_OP -Wlogical-op)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_INIT_SELF -Winit-self)  # needs -Wuninitialized
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_MISSING_INCLUDE_DIRS -Wmissing-include-dirs)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_DIV_BY_ZERO -Wno-div-by-zero)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_TYPE_LIMITS -Wtype-limits)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_ERROR_RETURN_TYPE  -Werror=return-type)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_CHAR_SUBSCRIPTS -Wno-char-subscripts)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_UNKNOWN_PRAGMAS -Wno-unknown-pragmas)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_POINTER_ARITH -Wpointer-arith)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_UNUSED_PARAMETER -Wunused-parameter)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_WRITE_STRINGS -Wwrite-strings)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_UNDEF -Wundef)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_FORMAT_SIGN -Wformat-signedness)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_RESTRICT -Wrestrict)

  # gcc 4.2 gives annoying warnings on every file with this
  if(NOT "${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "4.3")
    ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_UNINITIALIZED -Wuninitialized)
  endif()

  # causes too many warnings
  if(NOT APPLE)
    ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_UNDEF -Wundef)
    ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_MISSING_DECLARATIONS -Wmissing-declarations)
  endif()

  # Use 'ATTR_FALLTHROUGH' macro to suppress.
  if(CMAKE_COMPILER_IS_GNUCC AND (NOT "${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "7.0"))
    ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_IMPLICIT_FALLTHROUGH -Wimplicit-fallthrough=5)
    ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_IMPLICIT_FALLTHROUGH -Wimplicit-fallthrough=5)
  endif()

  # flags to undo strict flags
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_DEPRECATED_DECLARATIONS -Wno-deprecated-declarations)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_UNUSED_PARAMETER        -Wno-unused-parameter)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_UNUSED_FUNCTION         -Wno-unused-function)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_TYPE_LIMITS             -Wno-type-limits)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_INT_IN_BOOL_CONTEXT     -Wno-int-in-bool-context)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_FORMAT                  -Wno-format)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_SWITCH                  -Wno-switch)

  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_CLASS_MEMACCESS     -Wno-class-memaccess)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_COMMENT             -Wno-comment)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_UNUSED_TYPEDEFS     -Wno-unused-local-typedefs)

  if(CMAKE_COMPILER_IS_GNUCC AND (NOT "${CMAKE_C_COMPILER_VERSION}" VERSION_LESS "7.0"))
    ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_IMPLICIT_FALLTHROUGH    -Wno-implicit-fallthrough)
  endif()

  if(NOT APPLE)
    ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_ERROR_UNUSED_BUT_SET_VARIABLE -Wno-error=unused-but-set-variable)
  endif()

elseif(CMAKE_C_COMPILER_ID MATCHES "Clang")

  # strange, clang complains these are not supported, but then uses them.
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ALL -Wall)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ERROR_IMPLICIT_FUNCTION_DECLARATION -Werror=implicit-function-declaration)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ERROR_RETURN_TYPE  -Werror=return-type)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_AUTOLOGICAL_COMPARE -Wno-tautological-compare)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_UNKNOWN_PRAGMAS -Wno-unknown-pragmas)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_CHAR_SUBSCRIPTS -Wno-char-subscripts)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_STRICT_PROTOTYPES  -Wstrict-prototypes)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_MISSING_PROTOTYPES -Wmissing-prototypes)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_UNUSED_PARAMETER -Wunused-parameter)

  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_ALL -Wall)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_AUTOLOGICAL_COMPARE -Wno-tautological-compare)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_UNKNOWN_PRAGMAS     -Wno-unknown-pragmas)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_CHAR_SUBSCRIPTS     -Wno-char-subscripts)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_OVERLOADED_VIRTUAL  -Wno-overloaded-virtual)  # we get a lot of these, if its a problem a dev needs to look into it.
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_SIGN_COMPARE        -Wno-sign-compare)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_INVALID_OFFSETOF    -Wno-invalid-offsetof)

  # gives too many unfixable warnings
  # ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_UNUSED_MACROS      -Wunused-macros)
  # ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_UNUSED_MACROS          -Wunused-macros)

  # flags to undo strict flags
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_UNUSED_PARAMETER -Wno-unused-parameter)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_UNUSED_VARIABLE  -Wno-unused-variable)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_UNUSED_MACROS    -Wno-unused-macros)

  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_MISSING_VARIABLE_DECLARATIONS -Wno-missing-variable-declarations)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_INCOMPAT_PTR_DISCARD_QUAL -Wno-incompatible-pointer-types-discards-qualifiers)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_UNUSED_FUNCTION -Wno-unused-function)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_INT_TO_VOID_POINTER_CAST -Wno-int-to-void-pointer-cast)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_MISSING_PROTOTYPES -Wno-missing-prototypes)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_DUPLICATE_ENUM -Wno-duplicate-enum)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_UNDEF -Wno-undef)
  ADD_CHECK_C_COMPILER_FLAG(C_REMOVE_STRICT_FLAGS C_WARN_NO_MISSING_NORETURN -Wno-missing-noreturn)

  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_UNUSED_PRIVATE_FIELD -Wno-unused-private-field)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_CXX11_NARROWING -Wno-c++11-narrowing)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_NON_VIRTUAL_DTOR -Wno-non-virtual-dtor)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_UNUSED_MACROS -Wno-unused-macros)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_REORDER -Wno-reorder)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_COMMENT -Wno-comment)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_UNUSED_TYPEDEFS -Wno-unused-local-typedefs)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_UNDEFINED_VAR_TEMPLATE -Wno-undefined-var-template)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_REMOVE_STRICT_FLAGS CXX_WARN_NO_INSTANTIATION_AFTER_SPECIALIZATION -Wno-instantiation-after-specialization)

elseif(CMAKE_C_COMPILER_ID MATCHES "Intel")

  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_ALL -Wall)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_POINTER_ARITH -Wpointer-arith)
  ADD_CHECK_C_COMPILER_FLAG(C_WARNINGS C_WARN_NO_UNKNOWN_PRAGMAS -Wno-unknown-pragmas)

  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_ALL -Wall)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_INVALID_OFFSETOF -Wno-invalid-offsetof)
  ADD_CHECK_CXX_COMPILER_FLAG(CXX_WARNINGS CXX_WARN_NO_SIGN_COMPARE -Wno-sign-compare)

  # disable numbered, false positives
  set(C_WARNINGS "${C_WARNINGS} -wd188,186,144,913,556,858,597,177,1292,167,279,592,94,2722,3199")
  set(CXX_WARNINGS "${CXX_WARNINGS} -wd188,186,144,913,556,858,597,177,1292,167,279,592,94,2722,3199")

elseif(CMAKE_C_COMPILER_ID MATCHES "MSVC")
  # most msvc warnings are C & C++
  set(_WARNINGS
    # warning level:
    "/W3"
    "/w34062"  # switch statement contains 'default' but no 'case' labels
    "/w34115"  # 'type' : named type definition in parentheses
    "/w34189"  # local variable is initialized but not referenced
    # disable:
    "/wd4018"  # signed/unsigned mismatch
    "/wd4146"  # unary minus operator applied to unsigned type, result still unsigned
    "/wd4065"  # switch statement contains 'default' but no 'case' labels
    "/wd4127"  # conditional expression is constant
    "/wd4181"  # qualifier applied to reference type; ignored
    "/wd4200"  # zero-sized array in struct/union
    "/wd4244"  # conversion from 'type1' to 'type2', possible loss of data
    "/wd4267"  # conversion from 'size_t' to 'type', possible loss of data
    "/wd4305"  # truncation from 'type1' to 'type2'
    "/wd4800"  # forcing value to bool 'true' or 'false'
    "/wd4828"  # The file contains a character that is illegal
    "/wd4996"  # identifier was declared deprecated
    "/wd4661"  # no suitable definition provided for explicit template instantiation request
    # errors:
    "/we4013"  # 'function' undefined; assuming extern returning int
    "/we4133"  # incompatible pointer types
    "/we4431"  # missing type specifier - int assumed
  )

  if(MSVC_VERSION GREATER_EQUAL 1911)
    # see https://docs.microsoft.com/en-us/cpp/error-messages/compiler-warnings/c5038?view=vs-2017
    set(_WARNINGS "${_WARNINGS} /w35038") # order of initialization in c++ constructors
  endif()

  string(REPLACE ";" " " _WARNINGS "${_WARNINGS}")
  set(C_WARNINGS "${_WARNINGS}")
  set(CXX_WARNINGS "${_WARNINGS}")
  unset(_WARNINGS)
endif()

# ensure python header is found since detection can fail, this could happen
# with _any_ library but since we used a fixed python version this tends to
# be most problematic.
if(WITH_PYTHON)
  if(NOT EXISTS "${PYTHON_INCLUDE_DIR}/Python.h")
    message(FATAL_ERROR
      "Missing: \"${PYTHON_INCLUDE_DIR}/Python.h\",\n"
      "Set the cache entry 'PYTHON_INCLUDE_DIR' to point "
      "to a valid python include path. Containing "
      "Python.h for python version \"${PYTHON_VERSION}\""
    )
  endif()

  if(WIN32 OR APPLE)
    # Windows and macOS have this bundled with Python libraries.
  elseif((WITH_PYTHON_INSTALL AND WITH_PYTHON_INSTALL_NUMPY) OR (WITH_AUDASPACE AND NOT WITH_SYSTEM_AUDASPACE))
    if(("${PYTHON_NUMPY_PATH}" STREQUAL "") OR (${PYTHON_NUMPY_PATH} MATCHES NOTFOUND))
      find_python_package(numpy)
      unset(PYTHON_NUMPY_INCLUDE_DIRS CACHE)
      set(PYTHON_NUMPY_INCLUDE_DIRS ${PYTHON_NUMPY_PATH}/numpy/core/include CACHE PATH "Path to the include directory of the numpy module")
      mark_as_advanced(PYTHON_NUMPY_INCLUDE_DIRS)
    endif()
  endif()

  if(WIN32 OR APPLE)
    # pass, we have this in lib/python/site-packages
  elseif(WITH_PYTHON_INSTALL_REQUESTS)
    find_python_package(requests)
  endif()
endif()

if(MSVC)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++17")
elseif(
  CMAKE_COMPILER_IS_GNUCC OR
  CMAKE_C_COMPILER_ID MATCHES "Clang" OR
  CMAKE_C_COMPILER_ID MATCHES "Intel"
)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
else()
  message(FATAL_ERROR "Unknown compiler ${CMAKE_C_COMPILER_ID}, can't enable C++17 build")
endif()

# Visual Studio has all standards it supports available by default
# Clang on windows copies this behavior and does not support these switches
if(
  CMAKE_COMPILER_IS_GNUCC OR
  (CMAKE_C_COMPILER_ID MATCHES "Clang" AND (NOT MSVC)) OR
  (CMAKE_C_COMPILER_ID MATCHES "Intel")
)
  # Use C11 + GNU extensions, works with GCC, Clang, ICC
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu11")
endif()

if(UNIX AND NOT APPLE)
  if(NOT WITH_CXX11_ABI)
    set(PLATFORM_CFLAGS "${PLATFORM_CFLAGS} -D_GLIBCXX_USE_CXX11_ABI=0")
  endif()
endif()

# Include warnings first, so its possible to disable them with user defined flags
# eg: -Wno-uninitialized
set(CMAKE_C_FLAGS "${C_WARNINGS} ${CMAKE_C_FLAGS} ${PLATFORM_CFLAGS}")
set(CMAKE_CXX_FLAGS "${CXX_WARNINGS} ${CMAKE_CXX_FLAGS} ${PLATFORM_CFLAGS}")

# defined above, platform specific but shared names
mark_as_advanced(
  CYCLES_OSL
  OSL_LIB_EXEC
  OSL_COMPILER
  OSL_LIB_COMP
  OSL_LIB_QUERY
  OSL_INCLUDE_DIR
)

mark_as_advanced(
  LLVM_CONFIG
  LLVM_ROOT_DIR
  LLVM_LIBRARY
  LLVM_VERSION
)


#-------------------------------------------------------------------------------
# Global Defines

# better not set includes here but this debugging option is off by default.
if(WITH_CXX_GUARDEDALLOC)
  include_directories(${CMAKE_SOURCE_DIR}/intern/guardedalloc)
  add_definitions(-DWITH_CXX_GUARDEDALLOC)
endif()

if(WITH_ASSERT_ABORT)
  add_definitions(-DWITH_ASSERT_ABORT)
endif()

# message(STATUS "Using CFLAGS: ${CMAKE_C_FLAGS}")
# message(STATUS "Using CXXFLAGS: ${CMAKE_CXX_FLAGS}")








#-----------------------------------------------------------------------------
# Libraries

message(STATUS  "Blender build type standalone ${WITH_CYCLES_STANDALONE}   Withblender  ${WITH_BLENDER}    ext ${WITH_BLENDER_EXTENSION}   lib ${WITH_BLENDER_LIB}")


if(WITH_BLENDER)


  add_subdirectory(intern)
  add_subdirectory(extern)

  # source after intern and extern to gather all
  # internal and external library information first, for test linking
  add_subdirectory(source)
  
elseif(WITH_BLENDER_LIB)

compile_flag_RTC()
  add_subdirectory(intern)
  add_subdirectory(extern)
  add_subdirectory(source)

elseif(WITH_BLENDER_EXTENSION)

message(STATUS  "Blender build type WITH_BLENDER_EXTENSION ")
compile_flag_RTC()
  add_subdirectory(source)

elseif(WITH_CYCLES_STANDALONE)

  add_subdirectory(intern/cycles)
  add_subdirectory(extern/clew)

  if(WITH_CUDA_DYNLOAD)

    add_subdirectory(extern/cuew)

  endif()
  if(NOT WITH_SYSTEM_GLEW)
    add_subdirectory(extern/glew)
  endif()
endif()



#-----------------------------------------------------------------------------
# Blender Application
if(WITH_BLENDER)
  add_subdirectory(source/creator)
endif()


#-----------------------------------------------------------------------------
# Testing
if(WITH_TESTS)
add_subdirectory(tests)
endif()


#-----------------------------------------------------------------------------
# Define 'heavy' submodules (for Ninja builder when using pools).
setup_heavy_lib_pool()


#-----------------------------------------------------------------------------
# CPack for generating packages
include(build_files/cmake/packaging.cmake)

#-----------------------------------------------------------------------------
# Use dynamic loading for OpenMP
if(WITH_BLENDER)
  openmp_delayload(blender)
endif()













#-----------------------------------------------------------------------------
# Print Final Configuration

if(FIRST_RUN)

  set(_config_msg "\nBlender Configuration\n=====================")

  function(info_cfg_option
    _setting
    )

    set(_msg "  - ${_setting}")
    string(LENGTH "${_msg}" _len)
    while("32" GREATER "${_len}")
      set(_msg "${_msg} ")
      math(EXPR _len "${_len} + 1")
    endwhile()

    set(_config_msg "${_config_msg}\n${_msg}${${_setting}}" PARENT_SCOPE)
  endfunction()

  function(info_cfg_text
    _text
    )

    set(_config_msg "${_config_msg}\n\n  ${_text}" PARENT_SCOPE)
  endfunction()

  message(STATUS "C Compiler:   \"${CMAKE_C_COMPILER_ID}\"")
  message(STATUS "C++ Compiler: \"${CMAKE_CXX_COMPILER_ID}\"")

  info_cfg_text("Build Options:")
  info_cfg_option(WITH_BULLET)
  info_cfg_option(WITH_IK_SOLVER)
  info_cfg_option(WITH_IK_ITASC)
  info_cfg_option(WITH_OPENCOLLADA)
  info_cfg_option(WITH_FFTW3)
  info_cfg_option(WITH_INTERNATIONAL)
  info_cfg_option(WITH_INPUT_NDOF)
  info_cfg_option(WITH_CYCLES)
  info_cfg_option(WITH_FREESTYLE)
  info_cfg_option(WITH_OPENCOLORIO)
  info_cfg_option(WITH_XR_OPENXR)
  info_cfg_option(WITH_OPENIMAGEDENOISE)
  info_cfg_option(WITH_OPENVDB)
  info_cfg_option(WITH_ALEMBIC)
  info_cfg_option(WITH_QUADRIFLOW)
  info_cfg_option(WITH_USD)
  info_cfg_option(WITH_TBB)

  info_cfg_text("Compiler Options:")
  info_cfg_option(WITH_BUILDINFO)
  info_cfg_option(WITH_OPENMP)

  info_cfg_text("System Options:")
  info_cfg_option(WITH_INSTALL_PORTABLE)
  info_cfg_option(WITH_X11_ALPHA)
  info_cfg_option(WITH_X11_XF86VMODE)
  info_cfg_option(WITH_X11_XFIXES)
  info_cfg_option(WITH_X11_XINPUT)
  info_cfg_option(WITH_MEM_JEMALLOC)
  info_cfg_option(WITH_MEM_VALGRIND)
  info_cfg_option(WITH_SYSTEM_GLEW)

  info_cfg_text("Image Formats:")
  info_cfg_option(WITH_OPENIMAGEIO)
  info_cfg_option(WITH_IMAGE_CINEON)
  info_cfg_option(WITH_IMAGE_DDS)
  info_cfg_option(WITH_IMAGE_HDR)
  info_cfg_option(WITH_IMAGE_OPENEXR)
  info_cfg_option(WITH_IMAGE_OPENJPEG)
  info_cfg_option(WITH_IMAGE_TIFF)

  info_cfg_text("Audio:")
  info_cfg_option(WITH_OPENAL)
  info_cfg_option(WITH_SDL)
  info_cfg_option(WITH_SDL_DYNLOAD)
  info_cfg_option(WITH_JACK)
  info_cfg_option(WITH_JACK_DYNLOAD)
  info_cfg_option(WITH_CODEC_AVI)
  info_cfg_option(WITH_CODEC_FFMPEG)
  info_cfg_option(WITH_CODEC_SNDFILE)

  info_cfg_text("Compression:")
  info_cfg_option(WITH_LZMA)
  info_cfg_option(WITH_LZO)

  info_cfg_text("Python:")
  info_cfg_option(WITH_PYTHON_INSTALL)
  info_cfg_option(WITH_PYTHON_INSTALL_NUMPY)
  info_cfg_option(WITH_PYTHON_MODULE)
  info_cfg_option(WITH_PYTHON_SAFETY)
  if(APPLE)
    info_cfg_option(WITH_PYTHON_FRAMEWORK)
  endif()

  info_cfg_text("Modifiers:")
  info_cfg_option(WITH_MOD_REMESH)
  info_cfg_option(WITH_MOD_FLUID)
  info_cfg_option(WITH_MOD_OCEANSIM)

  info_cfg_text("OpenGL:")
  info_cfg_option(WITH_GLEW_ES)
  info_cfg_option(WITH_GL_EGL)
  info_cfg_option(WITH_GL_PROFILE_ES20)
  if(WIN32)
    info_cfg_option(WITH_GL_ANGLE)
  endif()

  info_cfg_text("")

  message("${_config_msg}")
endif()

if(0)
  print_all_vars()
endif()
