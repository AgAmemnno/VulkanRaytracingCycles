# ***** BEGIN GPL LICENSE BLOCK *****
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# The Original Code is Copyright (C) 2016, Blender Foundation
# All rights reserved.
# ***** END GPL LICENSE BLOCK *****

# Libraries configuration for Windows.

add_definitions(-DWIN32)

if(NOT MSVC)
  message(FATAL_ERROR "Compiler is unsupported")
endif()

if(CMAKE_C_COMPILER_ID MATCHES "Clang")
  set(MSVC_CLANG On)
  set(VC_TOOLS_DIR $ENV{VCToolsRedistDir} CACHE STRING "Location of the msvc redistributables")
  set(MSVC_REDIST_DIR ${VC_TOOLS_DIR})
  if(DEFINED MSVC_REDIST_DIR)
    file(TO_CMAKE_PATH ${MSVC_REDIST_DIR} MSVC_REDIST_DIR)
  else()
    message("Unable to detect the Visual Studio redist directory, copying of the runtime dlls will not work, try running from the visual studio developer prompt.")
  endif()
  # 1) CMake has issues detecting openmp support in clang-cl so we have to provide
  #    the right switches here.
  # 2) While the /openmp switch *should* work, it currently doesn't as for clang 9.0.0
  if(WITH_OPENMP)
    set(OPENMP_CUSTOM ON)
    set(OPENMP_FOUND ON)
    set(OpenMP_C_FLAGS "/clang:-fopenmp")
    set(OpenMP_CXX_FLAGS "/clang:-fopenmp")
    GET_FILENAME_COMPONENT(LLVMROOT "[HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\LLVM\\LLVM;]" ABSOLUTE CACHE)
    set(CLANG_OPENMP_DLL "${LLVMROOT}/bin/libomp.dll")
    set(CLANG_OPENMP_LIB "${LLVMROOT}/lib/libomp.lib")
    if(NOT EXISTS "${CLANG_OPENMP_DLL}")
      message(FATAL_ERROR "Clang OpenMP library (${CLANG_OPENMP_DLL}) not found.")
    endif()
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} \"${CLANG_OPENMP_LIB}\"")
  endif()
  if(WITH_WINDOWS_STRIPPED_PDB)
    message(WARNING "stripped pdb not supported with clang, disabling..")
    set(WITH_WINDOWS_STRIPPED_PDB Off)
  endif()
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ${WINDOWS_USE_VISUAL_STUDIO_PROJECT_FOLDERS})

if(NOT WITH_PYTHON_MODULE)
  set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT blender)
endif()

macro(warn_hardcoded_paths package_name
  )
  if(WITH_WINDOWS_FIND_MODULES)
    message(WARNING "Using HARDCODED ${package_name} locations")
  endif()
endmacro()

macro(windows_find_package package_name
  )
  if(WITH_WINDOWS_FIND_MODULES)
    find_package(${package_name})
  endif()
endmacro()

macro(find_package_wrapper)
  if(WITH_WINDOWS_FIND_MODULES)
    find_package(${ARGV})
  endif()
endmacro()

add_definitions(-DWIN32)

# Needed, otherwise system encoding causes utf-8 encoding to fail in some cases (C4819)
add_compile_options("$<$<C_COMPILER_ID:MSVC>:/utf-8>")
add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")

# Minimum MSVC Version
if(CMAKE_CXX_COMPILER_ID MATCHES MSVC)
  if(MSVC_VERSION EQUAL 1800)
    set(_min_ver "18.0.31101")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${_min_ver})
      message(FATAL_ERROR
        "Visual Studio 2013 (Update 4, ${_min_ver}) required, "
        "found (${CMAKE_CXX_COMPILER_VERSION})")
    endif()
  endif()
  if(MSVC_VERSION EQUAL 1900)
    set(_min_ver "19.0.24210")
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS ${_min_ver})
      message(FATAL_ERROR
        "Visual Studio 2015 (Update 3, ${_min_ver}) required, "
        "found (${CMAKE_CXX_COMPILER_VERSION})")
    endif()
  endif()
endif()
unset(_min_ver)

# needed for some MSVC installations
# 4099 : PDB 'filename' was not found with 'object/library'
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SAFESEH:NO /ignore:4099")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /SAFESEH:NO /ignore:4099")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /SAFESEH:NO /ignore:4099")

list(APPEND PLATFORM_LINKLIBS
  ws2_32 vfw32 winmm kernel32 user32 gdi32 comdlg32 Comctl32 version
  advapi32 shfolder shell32 ole32 oleaut32 uuid psapi Dbghelp Shlwapi
)

if(WITH_INPUT_IME)
  list(APPEND PLATFORM_LINKLIBS imm32)
endif()

add_definitions(
  -D_CRT_NONSTDC_NO_DEPRECATE
  -D_CRT_SECURE_NO_DEPRECATE
  -D_SCL_SECURE_NO_DEPRECATE
  -D_CONSOLE
  -D_LIB
)

# MSVC11 needs _ALLOW_KEYWORD_MACROS to build
add_definitions(-D_ALLOW_KEYWORD_MACROS)

message("  CMAKE_MODULE_PATH   ${CMAKE_MODULE_PATH}  ")
set(cmake_crt  "${LIBBLENDER_BASE_DIR}/build_files/cmake/platform/platform_win32_bundle_crt.cmake")

# We want to support Windows 7 level ABI
if(NOT EXISTS ${cmake_crt})
   message(FATAL_EXRROR  "  platform_win32_bundle_crt.cmake not found  . ")
endif()
add_definitions(-D_WIN32_WINNT=0x601)
include(${cmake_crt})
#include(platform_win32_bundle_crt.cmake)
remove_cc_flag("/MDd" "/MD" "/Zi")

if(WITH_WINDOWS_PDB)
	set(PDB_INFO_OVERRIDE_FLAGS "/Z7")
	set(PDB_INFO_OVERRIDE_LINKER_FLAGS "/DEBUG /OPT:REF /OPT:ICF /INCREMENTAL:NO")
endif()

if(MSVC_CLANG) # Clangs version of cl doesn't support all flags
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_WARN_FLAGS} /nologo /J /Gd /EHsc -Wno-unused-command-line-argument -Wno-microsoft-enum-forward-reference ")
  set(CMAKE_C_FLAGS     "${CMAKE_C_FLAGS} /nologo /J /Gd -Wno-unused-command-line-argument -Wno-microsoft-enum-forward-reference")
else()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /nologo /J /Gd /MP /EHsc /bigobj")
  set(CMAKE_C_FLAGS     "${CMAKE_C_FLAGS} /nologo /J /Gd /MP /bigobj")
endif()

# C++ standards conformace (/permissive-) is available on msvc 15.5 (1912) and up
if(MSVC_VERSION GREATER 1911 AND NOT MSVC_CLANG)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /permissive-")
  # Two-phase name lookup does not place nicely with OpenMP yet, so disable for now
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zc:twoPhase-")
endif()

if(WITH_WINDOWS_SCCACHE AND CMAKE_VS_MSBUILD_COMMAND)
    message(WARNING "Disabling sccache, sccache is not supported with msbuild")
    set(WITH_WINDOWS_SCCACHE Off)
endif()

if(WITH_WINDOWS_SCCACHE)
    set(CMAKE_C_COMPILER_LAUNCHER sccache)
    set(CMAKE_CXX_COMPILER_LAUNCHER sccache)
    set(SYMBOL_FORMAT /Z7)
else()
    unset(CMAKE_C_COMPILER_LAUNCHER)
    unset(CMAKE_CXX_COMPILER_LAUNCHER)
    set(SYMBOL_FORMAT /ZI)
endif()

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MDd ${SYMBOL_FORMAT}")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MDd ${SYMBOL_FORMAT}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MD ${PDB_INFO_OVERRIDE_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MD ${PDB_INFO_OVERRIDE_FLAGS}")
set(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL} /MD ${PDB_INFO_OVERRIDE_FLAGS}")
set(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL} /MD ${PDB_INFO_OVERRIDE_FLAGS}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /MD ${SYMBOL_FORMAT}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} /MD ${SYMBOL_FORMAT}")
unset(SYMBOL_FORMAT)
# JMC is available on msvc 15.8 (1915) and up
if(MSVC_VERSION GREATER 1914 AND NOT MSVC_CLANG)
  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /JMC")
endif()

set(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} /SUBSYSTEM:CONSOLE /STACK:2097152")
#-#

if(${MULTIMODE} STREQUAL "MTd")
set(PLATFORM_LINKFLAGS_RELEASE "/NODEFAULTLIB:libcmt.lib /NODEFAULTLIB:libcmtd.lib /NODEFAULTLIB:msvcrtd.lib")
set(PLATFORM_LINKFLAGS_DEBUG "${PLATFORM_LINKFLAGS_DEBUG} /IGNORE:4099 /NODEFAULTLIB:libcmt.lib /NODEFAULTLIB:msvcrt.dll /NODEFAULTLIB:msvcrtd.lib")
  else()
set(PLATFORM_LINKFLAGS_RELEASE "/NODEFAULTLIB:libcmt.lib /NODEFAULTLIB:libcmtd.lib /NODEFAULTLIB:msvcrtd.lib")
set(PLATFORM_LINKFLAGS_DEBUG "${PLATFORM_LINKFLAGS_DEBUG} /IGNORE:4099 /NODEFAULTLIB:libcmt.lib /NODEFAULTLIB:msvcrt.lib /NODEFAULTLIB:libcmtd.lib")
endif()
message(STATUS "PLATFORM LINK FLAGS ${MULTIMODE}   ==>  ${PLATFORM_LINKFLAGS_DEBUG}    ")

# Ignore meaningless for us linker warnings.
set(PLATFORM_LINKFLAGS "${PLATFORM_LINKFLAGS} /ignore:4049 /ignore:4217 /ignore:4221")
set(PLATFORM_LINKFLAGS_RELEASE "${PLATFORM_LINKFLAGS} ${PDB_INFO_OVERRIDE_LINKER_FLAGS}")
set(CMAKE_STATIC_LINKER_FLAGS "${CMAKE_STATIC_LINKER_FLAGS} /ignore:4221")

if(CMAKE_CL_64)
  set(PLATFORM_LINKFLAGS "/MACHINE:X64 ${PLATFORM_LINKFLAGS}")
else()
  set(PLATFORM_LINKFLAGS "/MACHINE:IX86 /LARGEADDRESSAWARE ${PLATFORM_LINKFLAGS}")
endif()

if(NOT DEFINED LIBDIR)

  # Setup 64bit and 64bit windows systems
  if(CMAKE_CL_64)
    message(STATUS "64 bit compiler detected.")
    set(LIBDIR_BASE "win64")
  else()
    message(FATAL_ERROR "32 bit compiler detected, blender no longer provides pre-build libraries for 32 bit windows, please set the LIBDIR cmake variable to your own library folder")
  endif()
  # Can be 1910..1912
  if(MSVC_VERSION GREATER 1919)
    message(STATUS "Visual Studio 2019 detected.")
    set(LIBDIR ${CMAKE_SOURCE_DIR}/../lib/${LIBDIR_BASE}_vc15)
  elseif(MSVC_VERSION GREATER 1909)
    message(STATUS "Visual Studio 2017 detected.")
    set(LIBDIR ${CMAKE_SOURCE_DIR}/../lib/${LIBDIR_BASE}_vc15)
  elseif(MSVC_VERSION EQUAL 1900)
    message(STATUS "Visual Studio 2015 detected.")
    set(LIBDIR ${CMAKE_SOURCE_DIR}/../lib/${LIBDIR_BASE}_vc15)
  endif()
else()
  message(STATUS "Using pre-compiled LIBDIR: ${LIBDIR}")
endif()
if(NOT EXISTS "${LIBDIR}/")
  message(STATUS "\n\nWarning  pre-compiled libs at: '${LIBDIR}'.")
endif()

if( EXISTS "${LIBDIR}/")
# Mark libdir as system headers with a lower warn level, to resolve some warnings
# that we have very little control over
if(MSVC_VERSION GREATER_EQUAL 1914 AND NOT MSVC_CLANG AND NOT WITH_WINDOWS_SCCACHE)
  add_compile_options(/experimental:external /external:templates- /external:I "${LIBDIR}" /external:W0)
endif()

# Add each of our libraries to our cmake_prefix_path so find_package() could work
file(GLOB children RELATIVE ${LIBDIR} ${LIBDIR}/*)
foreach(child ${children})
  if(IS_DIRECTORY ${LIBDIR}/${child})
    list(APPEND CMAKE_PREFIX_PATH  ${LIBDIR}/${child})
  endif()
endforeach()

endif()

