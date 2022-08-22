macro(unset_cache_force)
unset(__PYTHON_INCLUDE CACHE)
endmacro()


macro(Check_Cached_Dirs) 

  if( NOT LIBBLENDER_BASE_DIR)
  #set(GTEST_INC_DIR  "D:/C/googletest/googletest/include"  CACHE STRING "gtest_local_directory")
  set(LIBBLENDER_BASE_DIR  "D:/C/Aeoluslibrary/libAeolusOptix/libblender" CACHE STRING "blender libraray base directory")
  message(STATUS  "you should specify  a local directory of googletest with LIBBLENDER_BASE_DIR.  Default ==>  ${LIBBLENDER_BASE_DIR}")
  endif( NOT LIBBLENDER_BASE_DIR)


endmacro()

macro(blender_ver_dir_modify arg1)


endmacro()

macro(current_dir_modify arg1)

if(${arg1})

set(_CMAKE_SOURCE_DIR   ${CMAKE_SOURCE_DIR})
set(CMAKE_SOURCE_DIR   ${LIBBLENDER_BASE_DIR})
message(STATUS   "MODIFY   CMAKE_SOURCE_DIR     ${_CMAKE_SOURCE_DIR}  =====>>>>>>>>>  "  ${CMAKE_SOURCE_DIR})

get_filename_component(BINARY_DIR_P   "${CMAKE_BINARY_DIR}" PATH)
set(BINARY_DIR  ${BINARY_DIR_P}/bin/${CMAKE_CONFIGURATION_TYPES})

message(STATUS  "  Output  BinaryDirectory --------------->>>>>>>>>>>>>>>>>>      ${BINARY_DIR}")


else()

set(CMAKE_SOURCE_DIR   ${_CMAKE_SOURCE_DIR})
message(STATUS   "MODIFY  POP  CMAKE_SOURCE_DIR       =====>>>>>>>>>  "  ${CMAKE_SOURCE_DIR})

endif()


endmacro()


macro(target_global_  name  libsOrExe)
   
    set (extra_macro_args ${ARGN})
    list(LENGTH extra_macro_args num_extra_args)



    get_filename_component(BINARY_DIR_P   "${CMAKE_BINARY_DIR}" PATH)
   string(TOUPPER ${CMAKE_CONFIGURATION_TYPES} OUTPUTCONFIG )
 

 message(STATUS  "TARGET_GLOBAL  ${name} LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG}    ${BINARY_DIR_P}/${libsOrExe}")
  

if (${num_extra_args} GREATER 0)

 list(GET extra_macro_args 0 project_name)
message(STATUS  "DEFINED  PROJECT_NAME   ${project_name}")
  set_target_properties(${name}
     PROPERTIES
           ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG}   "${BINARY_DIR_P}/${libsOrExe}/${CMAKE_CONFIGURATION_TYPES}/${project_name}"
          LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG}     "${BINARY_DIR_P}/${libsOrExe}/${CMAKE_CONFIGURATION_TYPES}/${project_name}"
          RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG}   "${BINARY_DIR_P}/${libsOrExe}/${CMAKE_CONFIGURATION_TYPES}/${project_name}"
   )

else()
message(STATUS  "NOT DEFINED  PROJECT_NAME")

  set_target_properties(${name}
     PROPERTIES
           ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG}   "${BINARY_DIR_P}/${libsOrExe}/${CMAKE_CONFIGURATION_TYPES}"
          LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG}     "${BINARY_DIR_P}/${libsOrExe}/${CMAKE_CONFIGURATION_TYPES}"
          RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG}   "${BINARY_DIR_P}/${libsOrExe}/${CMAKE_CONFIGURATION_TYPES}"
   )

endif()

endmacro()

macro(target_global_lib name)


    set (extra_macro_args ${ARGN})
    list(LENGTH extra_macro_args num_extra_args)
    if (${num_extra_args} GREATER 0)
        list(GET extra_macro_args 0 project_name)
        message (" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>target_global_lib ${name}    Got an optional arg: ${project_name}")
    endif ()


   target_global_(${name} "Lib" ${ARGN})
   #target_global_(${name} "Lib" "target")
endmacro()

macro(target_global_exe  name)
   target_global_(${name} "bin")
endmacro()


macro(Moo arg)
  message("arg = ${arg}")
  set(arg "abc")
  message("# After change the value of arg.")
  message("arg = ${arg}")
endmacro()


macro(append_almity arg1 arg2)
   
set(dir ${arg1})
set(apd_list ${${arg2}})



foreach(base_dir ${apd_list})
  
  file(GLOB_RECURSE _SOURCE_FILES_
        "${base_dir}/*.h"
       "${base_dir}/*.hpp"
      "${base_dir}/*.cpp"
       "${base_dir}/*.cc"
         "${base_dir}/*.c"
           "${base_dir}/*.cxx"
   )
   list( APPEND ${dir}  ${_SOURCE_FILES_})
endforeach()

endmacro()

macro(srcgroup_rel  dir)
list(APPEND _list ${ARGN})
if(NOT _list)
    list(APPEND _list   ${dir})
endif()
message(STATUS  "append  ${_list}} ")
    foreach(_source IN ITEMS ${_list})
   
        if (IS_ABSOLUTE "${_source}")
            file(RELATIVE_PATH _source_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${_source}")
        else()
            set(_source_rel "${_source}")
        endif()
        get_filename_component(_source_path "${_source_rel}" PATH)
        string(REPLACE "/" "\\" _source_path_msvc "${_source_path}")
       #  message(STATUS  "append  ${_source_path_msvc}  > ${_source} ")
        source_group("${_source_path_msvc}" FILES "${_source}")
    endforeach()
 
    unset(_list)

endmacro()

macro(append_almity_python  arg1 arg2 )
   
set(dir ${arg1})
set(apd_list ${${arg2}})

foreach(base_dir ${apd_list})
  
  file(GLOB_RECURSE _SOURCE_FILES_
        "${base_dir}/*.py"
   )
   list( APPEND ${dir}  ${_SOURCE_FILES_})
endforeach()

srcgroup_rel(${${dir}})


endmacro()


macro(append_almity_shader  arg1 arg2 )
   
set(dir ${arg1})
set(apd_list ${${arg2}})



foreach(base_dir ${apd_list})
  
  file(GLOB_RECURSE _SOURCE_FILES_
        "${base_dir}/*.glsl"
        "${base_dir}/*.cl"
        "${base_dir}/*.h"
         "${base_dir}/*.hpp"
        "${base_dir}/*.csv"
   )
   list( APPEND ${dir}  ${_SOURCE_FILES_})
endforeach()
list(LENGTH ${dir} len_)

if( NOT  (${len_} LESS  1))
    srcgroup_rel(${${dir}})
endif()
endmacro()


macro(generate_proto arg0 arg1 arg2)
#get_target_property(Protobuf_PROTOC_EXECUTABLE protobuf::protoc
 # IMPORTED_LOCATION_RELEASE)
set(Protobuf_PROTOC_EXECUTABLE  "C:/wc/windows_msvc_debug_x64/protoc.exe")

set(Target_Name  ${arg0})
set(PROTO_SOURCE  ${arg1})
string(REPLACE "/proto" "/proto/include/proto" PROTO_OUT  ${PROTO_SOURCE})
string(REPLACE ".proto" ".pb.cc" PROTO_CPP_CPP  ${PROTO_OUT})
string(REPLACE ".proto" ".pb.h" PROTO_CPP_H  ${PROTO_OUT})

get_filename_component(SRC_DIR ${PROTO_SOURCE}  PATH)
get_filename_component(SRC_NAME ${PROTO_SOURCE}  NAME)
get_filename_component(OUT_DIR ${PROTO_OUT} PATH)
set(PYOUT_DIR "D:/blender/build/2.91/python/lib/site-packages/aeolus_cli")

#set(PROTO_PYTHON "${CMAKE_SOURCE_DIR}/render_ospray/messages_pb2.py")

 message(STATUS "PROTO    >>>>>>>>>>>>>> " ${PROTO_SOURCE}  "    cpp   " ${PROTO_CPP_CPP}  "    dir   "  ${SRC_DIR})
 add_custom_command(
     #TARGET ${Target_Name}  PRE_BUILD 
     OUTPUT ${PROTO_CPP_CPP} ${PROTO_CPP_H} 
      DEPENDS  ${PROTO_SOURCE}
      COMMAND ${Protobuf_PROTOC_EXECUTABLE}  ${PROTO_SOURCE}
      --cpp_out=${OUT_DIR}
      --python_out=${PYOUT_DIR}
      --proto_path=${SRC_DIR}
         COMMENT 
        "Generating C++ and Python protobuf sources ${PROTO_SOURCE} "
)
   set( ${arg2} ${PROTO_CPP_CPP} ${PROTO_CPP_H} )


endmacro()

macro(find_proto arg1)

set(ProjectName ${arg1})
set(ProtoBuf_DIR "C:/wc/windows_msvc_debug_x64/obj/third_party/protobuf")
set(ProtoBuf_INCDIR  "C:/wc/src/third_party/protobuf/src")

target_link_libraries(${ProjectName}  PRIVATE 
              ${ProtoBuf_DIR}/protobuf_full.lib
              ${ProtoBuf_DIR}/protobuf_lite.lib
              ${ProtoBuf_DIR}/protoc_lib.lib
              )

target_include_directories(${ProjectName}   PUBLIC ${ProtoBuf_INCDIR})
#target_link_libraries(libdc_${_target} PRIVATE protobuf::libprotoc protobuf::libprotobuf protobuf::libprotobuf-lite)

endmacro()

macro(set_python arg1)


set(NAME ${arg1})
if( ${NAME} )
set(NAME aeolus_cli)
endif( ${NAME} )



if( ${PYTHON_VER}  STREQUAL "37")

set(PYTHON_DIR  "D:/blender/src/lib/win64_vc15/python/37")
set(PYTHON_LIB  "${PYTHON_DIR}/libs/python37_d.lib")
set(PYTHON_INCLUDE  "${PYTHON_DIR}/include")
set(PYTHON_DST  "D:/blender/lib/site-packages")

elseif( ${PYTHON_VER}  STREQUAL "377")

set(PYTHON_DIR  "C:/Users/kaz38/AppData/Local/Programs/Python/Python37")
set(PYTHON_LIB  "${PYTHON_DIR}/libs/python37.lib")
set(PYTHON_INCLUDE  "${PYTHON_DIR}/include")
set(PYTHON_DST  "${PYTHON_DIR}/Lib/site-packages")


elseif(${PYTHON_VER} STREQUAL "38")

set(PYTHON_DIR  "D:/Python/Python-3.8.2")
set(PYTHON_LIB  "${PYTHON_DIR}/PCbuild/amd64/python38_d.lib")
set(PYTHON_INCLUDE  "${PYTHON_DIR}/Include" "${PYTHON_DIR}/PC" )
set(PYTHON_DST  "D:/Python/Aeolus/venv/Lib/site-packages/aeolus-0.0.1-py3.8.egg")

endif(${PYTHON_VER} STREQUAL "37")

message("PYTHON SETUP    ${__PYTHON_INCLUDE}   ===>   ${PYTHON_INCLUDE} ")

#if(NOT DEFINED __PYTHON_INCLUDE OR  ( (  NOT ${__PYTHON_INCLUDE})  EQUAL (${PYTHON_INCLUDE}) )
message("PYTHON SETUP    ${__PYTHON_INCLUDE}   ===>   ${PYTHON_INCLUDE} ")
remove_include_directories(${__PYTHON_INCLUDE} )

set(__PYTHON_INCLUDE  ${PYTHON_INCLUDE}  CACHE STRING "current python include" FORCE)
 set(PYTHON_VERSION ${PYTHON_VER})
#endif()

include_directories(${PYTHON_INCLUDE})
endmacro()


macro(findGtestLocal arg1 arg2)

    if( NOT GTEST_INCLUDE_DIRS)
       config_gtest()
        if( NOT GTEST_INCLUDE_DIRS)
           message(FATAL_ERROR "FIND_GTEST_LOCAL::   you havent specified GTEST_INCLUDE_DIRS."  )
        endif()
    endif()


  set(apd_list ${arg2})

list(APPEND ${apd_list}      
      # "gtest/gtestd"
      # "gtest/gtest_maind"
      "extern_gtest.lib"
      #"extern_gmock.lib"
      #"extern_glog.lib"
      #"extern_gflags.lib"
)

#message(STATUS  "GTEST MACRO  ${arg1}       ${arg2}   ${GTEST_INC_DIR}      ")
target_include_directories(${arg1}  PUBLIC  ${GTEST_INCLUDE_DIRS} ${GMOCK_INCLUDE_DIRS} ${GLOG_INCLUDE_DIRS} ${GFLAGS_INCLUDE_DIRS})

endmacro()


#####################################################################################
# Optional CUDA package
# see https://cmake.org/cmake/help/v3.3/module/FindCUDA.html
#
macro(_add_package_Cuda)
  find_package(CUDA QUIET)
  if(CUDA_FOUND)
      add_definitions("-DCUDA_PATH=R\"(${CUDA_TOOLKIT_ROOT_DIR})\"")
      Message(STATUS "--> using package CUDA (${CUDA_VERSION})")
      add_definitions(-DUSECUDA)
      include_directories(${CUDA_INCLUDE_DIRS})
      #LIST(APPEND LIBRARIES_CUDA ${CUDA_LIBRARIES} )
    
      # STRANGE: default CUDA package finder from cmake doesn't give anything to find cuda.lib
      if(WIN32)
        if((ARCH STREQUAL "x86"))
          LIST(APPEND CUDA_LIBRARIES "${CUDA_TOOLKIT_ROOT_DIR}/lib/Win32/cuda.lib" )
          LIST(APPEND CUDA_LIBRARIES "${CUDA_TOOLKIT_ROOT_DIR}/lib/Win32/cudart.lib" )
        
        else()
          LIST(APPEND CUDA_LIBRARIES "${CUDA_TOOLKIT_ROOT_DIR}/lib/x64/cuda.lib" )
          LIST(APPEND CUDA_LIBRARIES "${CUDA_TOOLKIT_ROOT_DIR}/lib/x64/cudart.lib" )
          LIST(APPEND CUDA_LIBRARIES "${CUDA_TOOLKIT_ROOT_DIR}/lib/x64/nvrtc.lib" )

        endif()
      else()
        LIST(APPEND CUDA_LIBRARIES "libcuda.so" )
        LIST(APPEND CUDA_LIBRARIES "${CUDA_TOOLKIT_ROOT_DIR}/lib64/libcudart.so" )
        LIST(APPEND CUDA_LIBRARIES "${CUDA_TOOLKIT_ROOT_DIR}/lib64/libnvrtc.so" )
       
      endif()
      #LIST(APPEND PACKAGE_SOURCE_FILES ${CUDA_HEADERS} ) Not available anymore with cmake 3.3... we might have to list them by hand
      # source_group(CUDA FILES ${CUDA_HEADERS} )  Not available anymore with cmake 3.3
 else()
     Message(FATAL_ERROR  "NOT FOUND CUDA") 
 endif()

endmacro()


macro(sdk_add_package_Cuda)
if(CUDA_REQ_11)
 set(CUDA_REQ "11.1")
  add_definitions(-DCUDA_VER=11)
else()
 set(CUDA_REQ "10.1")
 add_definitions(-DCUDA_VER=10)
endif()

set(CUDA_TOOLKIT_ROOT_DIR "C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v${CUDA_REQ}")

set(CMAKE_MODULE_PATH
  "${CMAKE_SOURCE_DIR}/libAeolusOptix/CMake"
  ${CMAKE_MODULE_PATH}
  )
  message("  cmake module pass     ${CMAKE_SOURCE_DIR}/libAeolusOptix/CMake  ${CMAKE_MODULE_PATH} " )
include(Macros)
# Determine information about the compiler
include (CompilerInfo)
# Check for specific machine/compiler options.
include (ConfigCompilerFlags)

# Turn off the warning that NVCC issues when generating PTX from our CUDA samples.  This
# is a custom extension to the FindCUDA code distributed by CMake.
OPTION(CUDA_REMOVE_GLOBAL_MEMORY_SPACE_WARNING "Suppress the \"Advisory: Cannot tell what pointer points to, assuming global memory space\" warning nvcc makes." ON)

# For Xcode 5, gcc is actually clang, so we have to tell CUDA to treat the compiler as
# clang, so that it doesn't mistake it for something else.
if(USING_CLANG_C)
  set(CUDA_HOST_COMPILER "clang" CACHE FILEPATH "Host side compiler used by NVCC")
endif()

# CUDA 8 is broken for generating dependencies during configure
option(CUDA_GENERATE_DEPENDENCIES_DURING_CONFIGURE "Generate dependencies during configure time instead of only during build time." OFF)

# Find at least a 5.0 version of CUDA.
find_package(CUDA 10.0 REQUIRED)

# Present the CUDA_64_BIT_DEVICE_CODE on the default set of options.
mark_as_advanced(CLEAR CUDA_64_BIT_DEVICE_CODE)

link_directories(${CUDA_TOOLKIT_ROOT_DIR}/lib/x64)

list(APPEND CUDA_LIBRARIES cuda.lib)



CUDA_ADD_CUDA_INCLUDE_ONCE()


endmacro()


macro(findOptixLocal arg1 )

  set(WITH_OPENEXR OFF)


  if( NOT OPTIX_INCLUDE_DIR)
  set(OPTIX_INCLUDE_DIR  "C:/ProgramData/NVIDIA Corporation/OptiX SDK 7.1.0/include"  CACHE STRING "Optix_local_directory")
  message(STATUS  "you should specify  a local directory of Optix  with OPTIX_INC_DIR.  Default ==>  ${OPTIX_INCLUDE_DIR}")
  endif( NOT OPTIX_INCLUDE_DIR)

  #target_include_directories(${arg1}  PUBLIC  ${OPTIX_INCLUDE_DIR} )
  include_directories(${OPTIX_INCLUDE_DIR} )
endmacro()


macro(set_vcpkg)
     set(USE_VCPKG ON)
    if(${CMAKE_CONFIGURATION_TYPES} STREQUAL "Debug")
        set(DEBUG_VCPKG TRUE)
    endif()

   if(NOT vcpkg_lib)
       get_filename_component(vcpkg  ${CMAKE_TOOLCHAIN_FILE} PATH)
       get_filename_component(vcpkg  ${vcpkg} PATH)
       get_filename_component(vcpkg  ${vcpkg} PATH)
       set(vcpkg_installed  ${vcpkg}/installed/${VCPKG_TARGET_TRIPLET})
       if(DEBUG_VCPKG)
            set(vcpkg_lib  ${vcpkg}/installed/${VCPKG_TARGET_TRIPLET}/debug/lib)
       else()
            set(vcpkg_lib  ${vcpkg}/installed/${VCPKG_TARGET_TRIPLET}/lib)
       endif()
       set(vcpkg_include  ${vcpkg}/installed/${VCPKG_TARGET_TRIPLET}/include)

       include_directories(SYSTEM   ${vcpkg_include})
       link_directories(PUBLIC  ${vcpkg_lib})

   endif()

endmacro()



macro(link_blender)

  list(LENGTH  BLENDER_INCLUDE len_inc)
  message("link_blender     >>>>>>>>>>>>>>>>>>>                        ${len_inc}  ")
  if( len_inc EQUAL 0)

         current_dir_modify(TRUE)
         set(WITH_OPTIX ON)
         set(WITH_OPENEXR ON)
         set(WITH_OPENIMAGEIO ON)
         include(platform_win32)

    list( APPEND   _BLENDER_LIBS 
    shlwapi  
    DbgHelp  
    Version
    )


     set(INTERN_DIR "${LIBBLENDER_BASE_DIR}/intern")
     list(APPEND BLENDER_INCLUDE  ${INTERN_DIR}/atomic)
     list(APPEND BLENDER_INCLUDE  ${INTERN_DIR}/sky/include)
      list(APPEND BLENDER_INCLUDE  ${INTERN_DIR}/guardedalloc)
    list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/python")
  list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/render/extern/include")
list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/makesdna")
list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/makesrna")
list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/editors/include")

find_package(OpenGL REQUIRED)
 add_definitions(${GL_DEFINITIONS})

 list( APPEND   BLENDER_LIBS   
opengl32.lib
${PLATFORM_LINKLIBS}
                   )


     endif()

endmacro()





macro(link_blender2)

  list(LENGTH  BLENDER_INCLUDE len_inc)
  message("link_blender     >>>>>>>>>>>>>>>>>>>                        ${len_inc}  ")
  if( len_inc EQUAL 0)

   current_dir_modify(TRUE)



         set(WITH_OPTIX ON)
         set(WITH_OPENEXR ON)
         set(WITH_OPENIMAGEIO ON)



  include(platform_win32)

list( APPEND   _BLENDER_LIBS 
bf_blenfont
bf_blenlib
bf_blenloader
bf_blentranslation
bf_bmesh
bf_depsgraph
bf_render
bf_draw
bf_functions
bf_gpencil_modifiers
bf_gpu
bf_ikplugin
bf_compositor
bf_modifiers
bf_nodes
bf_shader_fx
bf_simulation
bf_windowmanager
bf_blenkernel
bf_imbuf
bf_imbuf_openimageio
bf_python
bf_python_ext
bf_python_gpu
bf_python_bmesh
bf_python_mathutils


bf_intern_guardedalloc
bf_intern_clog
bf_intern_ghost
bf_intern_guardedalloc
bf_intern_libmv  # Uses stub when disabled.
bf_intern_mikktspace
bf_intern_opensubdiv  # Uses stub when disabled.
bf_intern_utfconv
bf_intern_opencolorio
bf_intern_eigen
bf_intern_memutil
bf_intern_numaapi
bf_intern_sky
bf_intern_locale
bf_intern_glew_mx
bf_ikplugin
bf_intern_iksolver
bf_intern_itasc

bf_editor_screen
bf_editor_lattice
bf_editor_metaball
bf_editor_interface
bf_editor_space_api
bf_editor_animation
bf_editor_armature
bf_editor_curve
bf_editor_gizmo_library
bf_editor_gpencil
bf_editor_io
bf_editor_mesh
bf_editor_object
bf_editor_physics
bf_editor_render
bf_editor_scene
bf_editor_sculpt_paint
bf_editor_sound
bf_editor_transform
bf_editor_undo
bf_editor_util
bf_editor_uvedit
bf_editor_mask
bf_editor_space_view3d
bf_editor_space_node
bf_editor_space_image
bf_editor_space_outliner
bf_editor_space_graph
bf_editor_space_clip
bf_editor_space_buttons
bf_editor_space_file
bf_editor_space_info
bf_editor_space_nla
bf_editor_space_action
bf_editor_space_sequencer
bf_editor_space_userpref
bf_editor_space_console
bf_editor_space_script
bf_editor_space_statusbar
bf_editor_space_text
bf_editor_space_topbar
bf_editor_datafiles

extern_glew
extern_clew
extern_curve_fit_nd
extern_rangetree
extern_wcwidth




          
shlwapi  
DbgHelp  
Version
)

#internal include
     set(INTERN_DIR "${LIBBLENDER_BASE_DIR}/intern")
     list(APPEND BLENDER_INCLUDE  ${INTERN_DIR}/atomic)
     list(APPEND BLENDER_INCLUDE  ${INTERN_DIR}/sky/include)


   set(PTHREADS_INCLUDE_DIRS ${LIBBL_SVN_DIR}/pthreads/x64/include)
   set(PTHREADS_LIBRARIES ${LIBBL_SVN_DIR}/pthreads/x64/lib/pthreadVC3.lib)
   

   list(APPEND BLENDER_INCLUDE ${PTHREADS_INC})
   list(APPEND BLENDER_LIBS ${PTHREADS_LIBRARIES})

  find_freetype()


   list(APPEND BLENDER_INCLUDE ${FREETYPE_INCLUDE_DIRS})
   list(APPEND BLENDER_LIBS ${FREETYPE_LIBRARY})

  find_tbb()

  if(WITH_TBB_MALLOC_PROXY)
    add_definitions(-DWITH_TBB_MALLOC)
  endif()
  
    list(APPEND BLENDER_INCLUDE  ${TBB_INCLUDE_DIRS})
    list(APPEND BLENDER_LIBS ${TBB_LIBRARIES})


     find_png()
    list(APPEND BLENDER_INCLUDE  ${PNG_INCLUDE_DIRS})
    list(APPEND BLENDER_LIBS ${PNG_LIBRARIES})
  
    find_jpeg()

   list(APPEND BLENDER_INCLUDE  ${JPEG_INCLUDE_DIRS})
   list(APPEND BLENDER_LIBS ${JPEG_LIBRARIES})

   find_zlib()


   list(APPEND BLENDER_INCLUDE  ${ZLIB_INCLUDE_DIRS})
   list(APPEND BLENDER_LIBS ${ZLIB_LIBRARIES})

   find_tiff()

   list(APPEND BLENDER_INCLUDE  ${TIFF_INCLUDE_DIRS})
   list(APPEND BLENDER_LIBS ${TIFF_LIBRARIES})


   if(WITH_IMAGE_OPENJPEG)
  set(OPENJPEG ${LIBBL_SVN_DIR}/openjpeg)
  set(OPENJPEG_INCLUDE_DIRS ${OPENJPEG}/include/openjpeg-2.3)
  set(OPENJPEG_LIBRARIES ${OPENJPEG}/lib/openjp2.lib)

     list(APPEND BLENDER_INCLUDE  ${OPENJPEG_INCLUDE_DIRS})
   list(APPEND BLENDER_LIBS ${OPENJPEG_LIBRARIES})
   endif()



     find_oexr()

      list(APPEND BLENDER_INCLUDE  ${OPENEXR_INCLUDE_DIRS})
      list(APPEND BLENDER_LIBS ${OPENEXR_LIBRARIES})


     find_boost()

      list(APPEND BLENDER_INCLUDE  ${BOOST_INCLUDE_DIRS})
      list(APPEND BLENDER_LIBS ${BOOST_LIBRARIES})


     find_oiio()
   list(APPEND BLENDER_INCLUDE  ${OPENIMAGEIO_INCLUDE_DIRS})
   list(APPEND BLENDER_LIBS ${OPENIMAGEIO_LIBRARIES})  


   find_opensubdv()

     list(APPEND BLENDER_INCLUDE  ${OPENSUBDIV_INCLUDE_DIRS})
     list(APPEND BLENDER_LIBS ${OPENSUBDIV_LIBRARIES})  


  foreach(_libs ${_BLENDER_LIBS})

    if(${_libs} MATCHES "bf_intern_.*")
        string(REGEX MATCH "bf_intern_(.*)"  _name ${_libs} )
        #message(STATUS  " match   ${CMAKE_MATCH_1}        " )
         list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/intern/${CMAKE_MATCH_1}") 
    elseif(${_libs} MATCHES "bf_editor_.*")
    elseif(${_libs} MATCHES "extern_.*")
        string(REGEX MATCH "extern_(.*)"  _name ${_libs} )
        #message(STATUS  " match   ${CMAKE_MATCH_1}        " )
        if(${CMAKE_MATCH_1} STREQUAL "glew")
         list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/extern/${CMAKE_MATCH_1}/include")
         endif()

    elseif(${_libs} MATCHES "bf_.*")
        string(REGEX MATCH "bf_(.*)"  _name ${_libs} )
         list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/${CMAKE_MATCH_1}")
    endif()
    list( APPEND   BLENDER_LIBS  ${_libs}.lib)
  endforeach()

    list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/python")
  list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/render/extern/include")
list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/makesdna")
list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/makesrna")
list( APPEND   BLENDER_INCLUDE "${LIBBLENDER_BASE_DIR}/source/blender/editors/include")

find_package(OpenGL REQUIRED)
 add_definitions(${GL_DEFINITIONS})


 message("PLATFORM_LINKLIBS     ${PLATFORM_LINKLIBS}")

 list( APPEND   BLENDER_LIBS   
bf_rna.lib 
bf_dna.lib 
bf_imbuf_openexr.lib
bf_imbuf_dds.lib
bf_imbuf_cineon.lib
opengl32.lib
${PLATFORM_LINKLIBS}
                   )


     endif()

endmacro()


macro(find_png)

 
if(NOT USE_VCPKG)

    set(PNG_PNG "${LIBBL_SVN_DIR}/png")
    set(PNG_INCLUDE_DIRS "${PNG_PNG}/include")
    set(PNG_LIBRARIES "${PNG_PNG}/lib/libpng.lib")
else()

    set(PNG_INCLUDE_DIRS ${vcpkg_include})
    if(DEBUG_VCPKG)
        set(PNG_LIBRARIES ${vcpkg_lib}/libpng16d.lib)
    else()
        set(PNG_LIBRARIES ${vcpkg_lib}/libpng16.lib)
    endif()
endif()


endmacro()



macro(find_oiio)

   if(WITH_OPENIMAGEIO)
      #windows_find_package(OpenImageIO)

      if(NOT USE_VCPKG)
           set(OPENIMAGEIO ${LIBBL_SVN_DIR}/OpenImageIO)
           set(OPENIMAGEIO_LIBPATH ${OPENIMAGEIO}/lib)
           set(OPENIMAGEIO_INCLUDE_DIRS ${OPENIMAGEIO}/include)
     else()
         set(OPENIMAGEIO_LIBPATH ${vcpkg_lib})
         set(OPENIMAGEIO_INCLUDE_DIRS ${vcpkg_include})
     endif()


    set(OPENIMAGEIO_LIBRARIES ${OPENIMAGEIO_LIBPATH}/OpenImageIO.lib  ${OPENIMAGEIO_LIBPATH}/OpenImageIO_Util.lib  )
    #set(OIIO_OPTIMIZED optimized ${OPENIMAGEIO_LIBPATH}/OpenImageIO.lib optimized ${OPENIMAGEIO_LIBPATH}/OpenImageIO_Util.lib)
    #set(OIIO_DEBUG debug ${OPENIMAGEIO_LIBPATH}/OpenImageIO_d.lib debug ${OPENIMAGEIO_LIBPATH}/OpenImageIO_Util_d.lib)
    #set(OPENIMAGEIO_LIBRARIES ${OIIO_OPTIMIZED} ${OIIO_DEBUG})

  set(OPENIMAGEIO_DEFINITIONS "-DUSE_TBB=0")
  set(OPENCOLORIO_DEFINITIONS "-DOCIO_STATIC_BUILD")
  set(OPENIMAGEIO_IDIFF "${LIBBL_SVN_DIR}/OpenImageIO/bin/idiff.exe")
  add_definitions(-DOIIO_STATIC_DEFINE)
  add_definitions(-DOIIO_NO_SSE=1)



endif()

endmacro()


macro(find_tbb)


    
    #message(" OPENEXR   ${CMAKE_CONFIGURATION_TYPES}  ${USE_VCPKG} ")
    if(NOT USE_VCPKG)
            set(TBB ${LIBBL_SVN_DIR}/tbb)
            set(TBB_LIBRARIES optimized ${LIBBL_SVN_DIR}/lib/tbb.lib debug ${LIBBL_SVN_DIR}/lib/debug/tbb_debug.lib)
            set(TBB_INCLUDE_DIRS ${TBB}/include)
            
    else()
            set(TBB ${CMAKE_HOME_DIRECTORY}/lib/tbb)
            set(TBB_INCLUDE_DIRS ${TBB}/include)
            #set(TBB_LIBRARIES optimized  ${vcpkg_installed}/lib/tbb.lib
           set(TBB_LIBRARIES ${TBB}/lib/tbb_debug.lib ${TBB}/lib/tbbmalloc_debug.lib)
   endif()

  




endmacro()



macro(find_zlib)


    
    #message(" OPENEXR   ${CMAKE_CONFIGURATION_TYPES}  ${USE_VCPKG} ")
    if(NOT USE_VCPKG)
            set(ZLIB ${LIBBL_SVN_DIR}/zlib)
            set(ZLIB_INCLUDE_DIRS ${ZLIB}/include)
             set(ZLIB_LIBRARIES ${ZLIB}/lib/libz_st_d.lib)
    else()
            set(ZLIB ${vcpkg_lib})
            set(ZLIB_INCLUDE_DIRS ${vcpkg_include})
            set(ZLIB_LIBRARIES ${ZLIB}/zlibd.lib)
   endif()

set(ZLIB_INCLUDE_DIR ${ZLIB_INCLUDE_DIRS})
set(ZLIB_LIBRARY ${ZLIB_LIBRARIES})
set(ZLIB_DIR ${ZLIB})

  
endmacro()



macro(find_opensubdv)

  set(OPENSUBDIV_HAS_OPENMP TRUE)
  set(OPENSUBDIV_HAS_TBB FALSE)
  set(OPENSUBDIV_HAS_OPENCL TRUE)
  set(OPENSUBDIV_HAS_CUDA FALSE)
  set(OPENSUBDIV_HAS_GLSL_TRANSFORM_FEEDBACK TRUE)
  set(OPENSUBDIV_HAS_GLSL_COMPUTE TRUE)
    
    #message(" OPENEXR   ${CMAKE_CONFIGURATION_TYPES}  ${USE_VCPKG} ")
    if(NOT USE_VCPKG)

              set(OPENSUBDIV_INCLUDE_DIR ${LIBBL_SVN_DIR}/opensubdiv/include)
             set(OPENSUBDIV_LIBPATH ${LIBBL_SVN_DIR}/opensubdiv/lib)
             set(OPENSUBDIV_LIBRARIES
    optimized ${OPENSUBDIV_LIBPATH}/osdCPU.lib
    optimized ${OPENSUBDIV_LIBPATH}/osdGPU.lib
    debug ${OPENSUBDIV_LIBPATH}/osdCPU_d.lib
    debug ${OPENSUBDIV_LIBPATH}/osdGPU_d.lib
  )
  #windows_find_package(OpenSubdiv)
    else()
            set(OPENSUBDIV ${vcpkg_lib})
            set(OPENSUBDIV_INCLUDE_DIR ${vcpkg_include})
            set(OPENSUBDIV_LIBRARIES ${OPENSUBDIV}/osdCPU.lib  ${OPENSUBDIV}/osdGPU.lib )
            message(" INCLUDE  OPENSUBDIV_LIBRARIES     ${OPENSUBDIV_LIBRARIES}  ")
   endif()

endmacro()

macro(find_freetype)


if(NOT USE_VCPKG)
    set(FREETYPE ${LIBBL_SVN_DIR}/freetype)
    set(FREETYPE_INCLUDE_DIRS
    ${LIBBL_SVN_DIR}/freetype/include
    ${LIBBL_SVN_DIR}/freetype/include/freetype2
    )
    set(FREETYPE_LIBRARY ${LIBBL_SVN_DIR}/freetype/lib/freetype2ST.lib)
#windows_find_package(freetype REQUIRED)
else()
     set(FREETYPE  ${vcpkg_lib})
     set(FREETYPE_INCLUDE_DIRS ${vcpkg_include})
    if(DEBUG_VCPKG)
        set(FREETYPE_LIBRARY  ${FREETYPE}/freetyped.lib ${FREETYPE}/bz2d.lib ${FREETYPE}/brotlicommon-static.lib  ${FREETYPE}/brotlidec-static.lib ${FREETYPE}/brotlienc-static.lib)
    else()
        set(FREETYPE_LIBRARY ${FREETYPE}/freetype.lib ${FREETYPE}/bz2.lib ${FREETYPE}/brotlicommon-static.lib  ${FREETYPE}/brotlidec-static.lib ${FREETYPE}/brotlienc-static.lib)
    endif()
endif()

endmacro()




macro(find_tiff)
    if(NOT USE_VCPKG)
      set(TIFF ${LIBBL_SVN_DIR}/tiff)
      set(TIFF_INCLUDE_DIRS ${TIFF}/include)
      set(TIFF_LIBRARIES ${TIFF}/lib/libtiff.lib)
      else()
             set(TIFF  ${vcpkg_lib})
             set(TIFF_INCLUDE_DIRS ${vcpkg_include})
            if(DEBUG_VCPKG)
            set(TIFF_LIBRARIES ${TIFF}/tiffd.lib ${TIFF}/lzmad.lib)
            else()
            set(TIFF_LIBRARIES ${TIFF}/tiff.lib ${TIFF}/lzma.lib)
            endif()
      endif()

endmacro()


macro(find_colorio)
    if(NOT USE_VCPKG)
if(WITH_OPENCOLORIO)
  set(OPENCOLORIO ${LIBDIR}/OpenColorIO)
  set(OPENCOLORIO_INCLUDE_DIRS ${OPENCOLORIO}/include)
  set(OPENCOLORIO_LIBPATH ${OPENCOLORIO}/lib)
  set(OPENCOLORIO_LIBRARIES
    optimized ${OPENCOLORIO_LIBPATH}/OpenColorIO.lib
    optimized ${OPENCOLORIO_LIBPATH}/tinyxml.lib
    optimized ${OPENCOLORIO_LIBPATH}/libyaml-cpp.lib
    debug ${OPENCOLORIO_LIBPATH}/OpencolorIO_d.lib
    debug ${OPENCOLORIO_LIBPATH}/tinyxml_d.lib
    debug ${OPENCOLORIO_LIBPATH}/libyaml-cpp_d.lib
  )
  set(OPENCOLORIO_DEFINITIONS)
endif()
else()
  set(OPENCOLORIO  ${vcpkg_include}/OpenColorIO)
   set(OPENCOLORIO_INCLUDE_DIRS ${OPENCOLORIO}/include)
   set(OPENCOLORIO_LIBPATH  ${vcpkg_lib})
   set(OPENCOLORIO_LIBRARIES
     ${OPENCOLORIO_LIBPATH}/static/OpencolorIO.lib
     ${OPENCOLORIO_LIBPATH}/tinyxml.lib
     ${OPENCOLORIO_LIBPATH}/libyaml-cppmdd.lib
  )
  
endif()

endmacro()


macro(find_jpeg)
    if(NOT USE_VCPKG)
           set(JPEG ${LIBBL_SVN_DIR}/jpeg)
           set(JPEG_INCLUDE_DIRS ${JPEG}/include)
           set(JPEG_LIBRARIES ${JPEG}/lib/libjpeg.lib)
      else()
            set(JPEG  ${vcpkg_lib})
            set(JPEG_INCLUDE_DIRS ${vcpkg_include})
            if(DEBUG_VCPKG)
            set(JPEG_LIBRARIES ${JPEG}/jpegd.lib)
            else()
            set(JPEG_LIBRARIES ${JPEG}/jpeg.lib)
            endif()
      endif()

endmacro()

macro(find_oexr)

    #set(OPENEXR ${LIBBL_SVN_DIR}/openexr)
  if(WITH_OPENEXR)
    
    #message(" OPENEXR   ${CMAKE_CONFIGURATION_TYPES}  ${USE_VCPKG} ")

    if(NOT USE_VCPKG)
         set(OPENEXR ${LIBBL_SVN_DIR}/openexr_mt)
         set(OPENEXR_INCLUDE_DIR ${OPENEXR}/include)
         list(APPEND OPENEXR_INCLUDE_DIRS OPENEXR_INCLUDE_DIR)
             set(OPENEXR_LIBPATH ${OPENEXR}/lib)
    else()
         set(OPENEXR_LIBPATH ${vcpkg_lib})
         set(OPENEXR_INCLUDE_DIR ${vcpkg_include})
    endif()

    set(EXR_SUFFIX "-2_5")
    #
    list(APPEND OPENEXR_INCLUDE_DIRS  ${OPENEXR_INCLUDE_DIR}/OpenEXR)
    if(${CMAKE_CONFIGURATION_TYPES} STREQUAL "Debug")
    
       set(OPENEXR_LIBRARIES
       ${OPENEXR_LIBPATH}/Iex${EXR_SUFFIX}_d.lib
       ${OPENEXR_LIBPATH}/Half${EXR_SUFFIX}_d.lib
       ${OPENEXR_LIBPATH}/IlmImf${EXR_SUFFIX}_d.lib
       ${OPENEXR_LIBPATH}/Imath${EXR_SUFFIX}_d.lib
       ${OPENEXR_LIBPATH}/IlmThread${EXR_SUFFIX}_d.lib
       )
    
    else()
       set(OPENEXR_LIBRARIES
       ${OPENEXR_LIBPATH}/Iex${EXR_SUFFIX}.lib
       ${OPENEXR_LIBPATH}/Half${EXR_SUFFIX}.lib
       ${OPENEXR_LIBPATH}/IlmImf${EXR_SUFFIX}.lib
       ${OPENEXR_LIBPATH}/Imath${EXR_SUFFIX}.lib
        ${OPENEXR_LIBPATH}/IlmThread${EXR_SUFFIX}.lib)
    
    endif()




   endif()

endmacro()




macro(configure_openGL)
#-----------------------------------------------------------------------------
# Configure OpenGL.

find_package(OpenGL)
blender_include_dirs_sys("${OPENGL_INCLUDE_DIR}")

if(WITH_OPENGL)
  add_definitions(-DWITH_OPENGL)
endif()

if(WITH_SYSTEM_GLES)
  find_package_wrapper(OpenGLES)
endif()

if(WITH_GL_PROFILE_ES20)
  if(WITH_SYSTEM_GLES)
    if(NOT OPENGLES_LIBRARY)
      message(FATAL_ERROR
        "Unable to find OpenGL ES libraries. "
        "Install them or disable WITH_SYSTEM_GLES."
      )
    endif()

    list(APPEND BLENDER_GL_LIBRARIES "${OPENGLES_LIBRARY}")

  else()
    set(OPENGLES_LIBRARY "" CACHE FILEPATH "OpenGL ES 2.0 library file")
    mark_as_advanced(OPENGLES_LIBRARY)

    list(APPEND BLENDER_GL_LIBRARIES "${OPENGLES_LIBRARY}")

    if(NOT OPENGLES_LIBRARY)
      message(FATAL_ERROR
        "To compile WITH_GL_EGL you need to set OPENGLES_LIBRARY "
        "to the file path of an OpenGL ES 2.0 library."
      )
    endif()

  endif()

  if(WIN32)
    # Setup paths to files needed to install and redistribute Windows Blender with OpenGL ES

    set(OPENGLES_DLL "" CACHE FILEPATH "OpenGL ES 2.0 redistributable DLL file")
    mark_as_advanced(OPENGLES_DLL)

    if(NOT OPENGLES_DLL)
      message(FATAL_ERROR
        "To compile WITH_GL_PROFILE_ES20 you need to set OPENGLES_DLL to the file "
        "path of an OpenGL ES 2.0 runtime dynamic link library (DLL)."
      )
    endif()

    if(WITH_GL_ANGLE)
      list(APPEND GL_DEFINITIONS -DWITH_ANGLE)

      set(D3DCOMPILER_DLL "" CACHE FILEPATH "Direct3D Compiler redistributable DLL file (needed by ANGLE)")

      get_filename_component(D3DCOMPILER_FILENAME "${D3DCOMPILER_DLL}" NAME)
      list(APPEND GL_DEFINITIONS "-DD3DCOMPILER=\"\\\"${D3DCOMPILER_FILENAME}\\\"\"")

      mark_as_advanced(D3DCOMPILER_DLL)

      if(D3DCOMPILER_DLL STREQUAL "")
        message(FATAL_ERROR
          "To compile WITH_GL_ANGLE you need to set D3DCOMPILER_DLL to the file "
          "path of a copy of the DirectX redistributable DLL file: D3DCompiler_46.dll"
        )
      endif()

    endif()

  endif()

else()
  if(OpenGL_GL_PREFERENCE STREQUAL "LEGACY" AND OPENGL_gl_LIBRARY)
    list(APPEND BLENDER_GL_LIBRARIES ${OPENGL_gl_LIBRARY})
  else()
    list(APPEND BLENDER_GL_LIBRARIES ${OPENGL_opengl_LIBRARY} ${OPENGL_glx_LIBRARY})
  endif()
endif()

if(WITH_GL_EGL)
  find_package(OpenGL REQUIRED EGL)
  list(APPEND BLENDER_GL_LIBRARIES OpenGL::EGL)

  list(APPEND GL_DEFINITIONS -DWITH_GL_EGL -DGLEW_EGL -DGLEW_INC_EGL)

  if(WITH_SYSTEM_GLES)
    if(NOT OPENGLES_EGL_LIBRARY)
      message(FATAL_ERROR
        "Unable to find OpenGL ES libraries. "
        "Install them or disable WITH_SYSTEM_GLES."
      )
    endif()

    list(APPEND BLENDER_GL_LIBRARIES ${OPENGLES_EGL_LIBRARY})

  else()
    set(OPENGLES_EGL_LIBRARY "" CACHE FILEPATH "EGL library file")
    mark_as_advanced(OPENGLES_EGL_LIBRARY)

    list(APPEND BLENDER_GL_LIBRARIES "${OPENGLES_LIBRARY}" "${OPENGLES_EGL_LIBRARY}")

    if(NOT OPENGLES_EGL_LIBRARY)
      message(FATAL_ERROR
        "To compile WITH_GL_EGL you need to set OPENGLES_EGL_LIBRARY "
        "to the file path of an EGL library."
      )
    endif()

  endif()

  if(WIN32)
    # Setup paths to files needed to install and redistribute Windows Blender with OpenGL ES

    set(OPENGLES_EGL_DLL "" CACHE FILEPATH "EGL redistributable DLL file")
    mark_as_advanced(OPENGLES_EGL_DLL)

    if(NOT OPENGLES_EGL_DLL)
      message(FATAL_ERROR
        "To compile WITH_GL_EGL you need to set OPENGLES_EGL_DLL "
        "to the file path of an EGL runtime dynamic link library (DLL)."
      )
    endif()

  endif()

endif()

if(WITH_GL_PROFILE_ES20)
  list(APPEND GL_DEFINITIONS -DWITH_GL_PROFILE_ES20)
else()
  list(APPEND GL_DEFINITIONS -DWITH_GL_PROFILE_CORE)
endif()


#-----------------------------------------------------------------------------
# Configure GLEW

if(WITH_SYSTEM_GLEW)
  find_package(GLEW)

  # Note: There is an assumption here that the system GLEW is not a static library.

  if(NOT GLEW_FOUND)
    message(FATAL_ERROR "GLEW is required to build Blender. Install it or disable WITH_SYSTEM_GLEW.")
  endif()

  set(GLEW_INCLUDE_PATH "${GLEW_INCLUDE_DIR}")
  set(BLENDER_GLEW_LIBRARIES ${GLEW_LIBRARY})
else()

  if(WITH_GLEW_ES)
    set(GLEW_INCLUDE_PATH "${CMAKE_SOURCE_DIR}/extern/glew-es/include")

    list(APPEND GL_DEFINITIONS -DGLEW_STATIC -DWITH_GLEW_ES)

    # These definitions remove APIs from glew.h, making GLEW smaller, and catching unguarded API usage
    if(WITH_GL_PROFILE_ES20)
      list(APPEND GL_DEFINITIONS -DGLEW_ES_ONLY)
    else()
      # No ES functions are needed
      list(APPEND GL_DEFINITIONS -DGLEW_NO_ES)
    endif()

    if(WITH_GL_PROFILE_ES20)
      if(WITH_GL_EGL)
        list(APPEND GL_DEFINITIONS -DGLEW_USE_LIB_ES20)
      endif()

      # ToDo: This is an experiment to eliminate ES 1 symbols,
      # GLEW doesn't really properly provide this level of control
      # (for example, without modification it eliminates too many symbols)
      # so there are lots of modifications to GLEW to make this work,
      # and no attempt to make it work beyond Blender at this point.
      list(APPEND GL_DEFINITIONS -DGL_ES_VERSION_1_0=0 -DGL_ES_VERSION_CL_1_1=0 -DGL_ES_VERSION_CM_1_1=0)
    endif()

    set(BLENDER_GLEW_LIBRARIES extern_glew_es bf_intern_glew_mx)

  else()
    set(GLEW_INCLUDE_PATH "${CMAKE_SOURCE_DIR}/extern/glew/include")

    list(APPEND GL_DEFINITIONS -DGLEW_STATIC)

    # This won't affect the non-experimental glew library,
    # but is used for conditional compilation elsewhere.
    list(APPEND GL_DEFINITIONS -DGLEW_NO_ES)

    set(BLENDER_GLEW_LIBRARIES extern_glew)

  endif()

endif()

list(APPEND GL_DEFINITIONS -DGLEW_NO_GLU)


endmacro()



macro(configure_blender )

   #set_vcpkg()
#-----------------------------------------------------------------------------
# Redirect output files
current_dir_modify(TRUE)

get_filename_component(BINARY_DIR_P   "${CMAKE_BINARY_DIR}" PATH)
set(EXECUTABLE_OUTPUT_PATH ${BINARY_DIR_P}/bin CACHE INTERNAL "" FORCE)
set(LIBRARY_OUTPUT_PATH ${BINARY_DIR_P}/Lib CACHE INTERNAL "" FORCE)
if(MSVC)
  set(TESTS_OUTPUT_DIR ${EXECUTABLE_OUTPUT_PATH}/tests/$<CONFIG>/ CACHE INTERNAL "" FORCE)
else()
  set(TESTS_OUTPUT_DIR ${EXECUTABLE_OUTPUT_PATH}/tests/ CACHE INTERNAL "" FORCE)
endif()


get_blender_version()
# By default we want to install to the directory we are compiling our executables
# unless specified otherwise, which we currently do not allow
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if(WIN32)
     #set(CMAKE_INSTALL_PREFIX ${EXECUTABLE_OUTPUT_PATH}/\${BUILD_TYPE} CACHE PATH "default install path" FORCE)
     set(CMAKE_INSTALL_PREFIX ${BINARY_DIR} CACHE PATH "default install path" FORCE)
  elseif(APPLE)
    set(CMAKE_INSTALL_PREFIX ${EXECUTABLE_OUTPUT_PATH}/\${BUILD_TYPE} CACHE PATH "default install path" FORCE)
  else()
    if(WITH_INSTALL_PORTABLE)
      set(CMAKE_INSTALL_PREFIX ${EXECUTABLE_OUTPUT_PATH} CACHE PATH "default install path" FORCE)
    endif()
  endif()
endif()

set(CMAKE_INSTALL_PREFIX ${BINARY_DIR}  CACHE PATH "default install path" FORCE)
message(STATUS "Install dir ====>>   ${CMAKE_INSTALL_PREFIX}   ")
set(WITH_WINDOWS_BUNDLE_CRT ON)
set(WITH_PYTHON ON)
set(WITH_CYCLES_DEVICE_OPTIX ON)
set(WITH_HEADLESS OFF)
set(WITH_TESTS OFF)
set(WITH_GTESTS ON)
option(WITH_OPENGL_RENDER_TESTS "Enable OpenGL render related unit testing (Experimental)" ON)
option(WITH_OPENGL_DRAW_TESTS "Enable OpenGL UI drawing related unit testing (Experimental)" ON)
set(WITH_SYSTEM_GFLAGS OFF)
set(WITH_SYSTEM_GLOG     OFF)
set(WITH_OPENSUBDIV ON)
set(WITH_IK_SOLVER ON)
set(WITH_IK_ITASC ON)
# Compositor
option(WITH_COMPOSITOR         "Enable the tile based nodal compositor" ON)
# Image format support
option(WITH_OPENIMAGEIO           "Enable OpenImageIO Support (http://www.openimageio.org)" ON)
option(WITH_OPENCOLORIO           "Enable OpenColorIO Support (http://www.openimageio.org)" ON)
option(WITH_IMAGE_OPENEXR       "Enable OpenEXR Support (http://www.openexr.com)" ON)
option(WITH_IMAGE_OPENJPEG      "Enable OpenJpeg Support (http://www.openjpeg.org)" OFF)
option(WITH_IMAGE_TIFF                "Enable LibTIFF Support" ON)
option(WITH_IMAGE_DDS                 "Enable DDS Image Support" ON)
option(WITH_IMAGE_CINEON          "Enable CINEON and DPX Image Support" ON)
option(WITH_IMAGE_HDR                 "Enable HDR Image Support" ON)
option(WITH_INTERNATIONAL       "Enable INTERNATIONAL Support" ON)
option(WITH_OPTIX       "Enable OPTIX Support" ON)
option(WITH_CUDA_DYNLOAD   "Enable CUDA_DYNLOAD  Support" OFF)

set(WITH_CUDA_DYNLOAD  OFF)

if(WITH_OPTIX)
  add_definitions(-DWITH_OPTIX)
endif()
# this starts out unset
if(WITH_INTERNATIONAL)
  add_definitions(-DWITH_INTERNATIONAL)
endif()

if(WITH_OPENCOLORIO)
add_definitions(-DWITH_OCIO)
endif()
list(APPEND CMAKE_MODULE_PATH "${LIBBLENDER_BASE_DIR}/build_files/cmake/Modules")
list(APPEND CMAKE_MODULE_PATH "${LIBBLENDER_BASE_DIR}/build_files/cmake/platform")
#message(STATUS  "CMAKE_MODULE_PATH  ${CMAKE_MODULE_PATH}")
#-----------------------------------------------------------------------------
# Set policy
# see "cmake --help-policy CMP0003"
# So library linking is more sane
cmake_policy(SET CMP0003 NEW)

# So BUILDINFO and BLENDERPATH strings are automatically quoted
cmake_policy(SET CMP0005 NEW)

# So syntax problems are errors
cmake_policy(SET CMP0010 NEW)

# Input directories must have CMakeLists.txt
cmake_policy(SET CMP0014 NEW)

# Silence draco warning on macOS, new policy works fine.
if(POLICY CMP0068)
  cmake_policy(SET CMP0068 NEW)
endif()

# find_package() uses <PackageName>_ROOT variables.
if(POLICY CMP0074)
  cmake_policy(SET CMP0074 NEW)
endif()

#-----------------------------------------------------------------------------
# Load some macros.
include(${LIBBLENDER_BASE_DIR}/build_files/cmake/macros.cmake)


# disable for now, but plan to support on all platforms eventually
option(WITH_MEM_JEMALLOC   "Enable malloc replacement (http://www.canonware.com/jemalloc)" ON)
mark_as_advanced(WITH_MEM_JEMALLOC)
# Debug
option(WITH_CXX_GUARDEDALLOC "Enable GuardedAlloc for C++ memory allocation tracking (only enable for development)" ON)
mark_as_advanced(WITH_CXX_GUARDEDALLOC)
option(WITH_ASSERT_ABORT "Call abort() when raising an assertion through BLI_assert()" ON)
mark_as_advanced(WITH_ASSERT_ABORT)
option(WITH_TBB   "Enable features depending on TBB (OpenVDB, OpenImageDenoise, sculpt multithreading)" ON)
# TBB malloc is only supported on for windows currently
if(WIN32)
  option(WITH_TBB_MALLOC_PROXY "Enable the TBB malloc replacement" ON)
endif()
# OpenGL
option(WITH_OPENGL              "When off limits visibility of the opengl headers to just bf_gpu and gawain (temporary option for development purposes)" ON)
option(WITH_GLEW_ES             "Switches to experimental copy of GLEW that has support for OpenGL ES. (temporary option for development purposes)" OFF)
option(WITH_GL_EGL              "Use the EGL OpenGL system library instead of the platform specific OpenGL system library (CGL, glX, or WGL)"       OFF)
option(WITH_GL_PROFILE_ES20     "Support using OpenGL ES 2.0. (through either EGL or the AGL/WGL/XGL 'es20' profile)"                               OFF)
mark_as_advanced(
  WITH_OPENGL
  WITH_GLEW_ES
  WITH_GL_EGL
  WITH_GL_PROFILE_ES20
)
if(WIN32)
  option(WITH_GL_ANGLE "Link with the ANGLE library, an OpenGL ES 2.0 implementation based on Direct3D, instead of the system OpenGL library." OFF)
  mark_as_advanced(WITH_GL_ANGLE)
endif()
if(WITH_GLEW_ES AND WITH_SYSTEM_GLEW)
  message(WARNING Ignoring WITH_SYSTEM_GLEW and using WITH_GLEW_ES)
  set(WITH_SYSTEM_GLEW OFF)
endif()
if(WIN32)
  getDefaultWindowsPrefixBase(CMAKE_GENERIC_PROGRAM_FILES)
  set(CPACK_INSTALL_PREFIX ${CMAKE_GENERIC_PROGRAM_FILES}/${})
endif()



endmacro()


macro(vcx_copy)


execute_process(COMMAND cmd /c "copy /Y ${UserVCX}  ${DstUserVCX}"
RESULT_VARIABLE CMD_ERROR 
        OUTPUT_FILE CMD_OUTPUT
        )
 if(${CMD_ERROR})
MESSAGE( FATAL_ERROR     "CMD_ERROR:" ${CMD_ERROR}:: CMD::   "copy /Y ${UserVCX}  ${DstUserVCX}     " )
endif(${CMD_ERROR})


execute_process(COMMAND cmd /c "copy /Y  ${srcName}  ${dstName}"
       RESULT_VARIABLE CMD_ERROR2 
           OUTPUT_FILE CMD_OUTPUT
        )
     
        if(${CMD_ERROR2})
MESSAGE( FATAL_ERROR     "CMD_ERROR:" ${CMD_ERROR2}:: CMD::   "copy /Y ${srcName}  ${dstName}    " )
endif(${CMD_ERROR2})


endmacro()

macro(configure_pyd  name vcx )

string(TOUPPER ${CMAKE_CONFIGURATION_TYPES} OUTPUTCONFIG )

if(${OUTPUTCONFIG} STREQUAL "DEBUG")
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${name}_d")
else()
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${name}")
endif()

set_target_properties(${PROJECT_NAME}  PROPERTIES SUFFIX ".pyd")


set_target_properties(${PROJECT_NAME} 
    PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG}  ${PYTHON_DST}
        RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG}  ${PYTHON_DST}
)

string(REPLACE "/" "\\" UserVCX  "${LIB_DIR}\\${PROJECT_NAME}\\${vcx}.vcxproj.user")
string(REPLACE "/" "\\" DstUserVCX "${BUILD_DIR}\\${_PROJECT_ALIAS}\\${PROJECT_NAME}\\")
string(REPLACE "/" "\\" srcName  "${DstUserVCX}\\${vcx}.vcxproj.user")
string(REPLACE "/" "\\" dstName "${DstUserVCX}\\${PROJECT_NAME}.vcxproj.user")
vcx_copy()



endmacro()






macro(import_oiio)


  set(VCPKG_TARGET_ARCHITECTURE x64 CACHE STRING "")
  set(VCPKG_CRT_LINKAGE static CACHE STRING "")
  set(VCPKG_LIBRARY_LINKAGE static CACHE STRING "")
  set(VCPKG_PLATFORM_TOOLSET v142 CACHE STRING "")
   add_definitions(-DOIIO_STATIC_DEFINE)

   #  get_filename_component(CMAKE_TOOLCHAIN   ${CMAKE_TOOLCHAIN_FILE} PATH)
   #  set(OPENIMAGEIO_ROOT_DIR "${CMAKE_TOOLCHAIN}/../../installed/x64-windows-static-custom/debug/lib")

       
         set_vcpkg()
         set(WITH_OPENEXR ON)
         set(WITH_OPENIMAGEIO ON)
         find_oiio()
         find_oexr()
        
         list(APPEND OPENIMAGEIO_LIBRARY  ${OPENIMAGEIO_LIBRARIES}  ${OPENEXR_LIBRARIES})

  message(STATUS  "   OIIO   library   ${OPENIMAGEIO_LIBRARY}  ")


  if(OPENIMAGEIO_PUGIXML_FOUND)
    set(PUGIXML_INCLUDE_DIR "${OPENIMAGEIO_INCLUDE_DIR}/OpenImageIO}")
    set(PUGIXML_LIBRARIES "")
  else()
    #find_package(PugiXML REQUIRED)

  endif()
  include_directories(SYSTEM ${OPENIMAGEIO_INCLUDE_DIR} )
endmacro()



macro(find_boost)
set(Boost_NO_WARN_NEW_VERSIONS 1)
#set(Boost_USE_STATIC_LIBS        ON)  # only find static libs
#set(Boost_USE_DEBUG_LIBS        OFF)  # ignore debug libs and
#set(Boost_USE_RELEASE_LIBS       ON)  # only find release libs
#set(Boost_USE_MULTITHREADED      ON)
#set(Boost_USE_STATIC_RUNTIME    OFF)

find_package(Boost 1.70 REQUIRED COMPONENTS filesystem  regex system thread chrono locale date_time) 
set(BOOST_LIBRARIES Boost::filesystem
    Boost::regex
    Boost::system
    Boost::thread
    Boost::chrono
    Boost::locale
    Boost::date_time
  )
endmacro()



macro(find_boost2)


    if(NOT USE_VCPKG)

          if(WITH_BOOST)
           if(WITH_CYCLES_OSL)
            set(boost_extra_libs wave)
           endif()
          if(WITH_INTERNATIONAL)
            list(APPEND boost_extra_libs locale)
          endif()
          set(Boost_USE_STATIC_RUNTIME ON) # prefix lib
          set(Boost_USE_MULTITHREADED ON) # suffix -mt
          set(Boost_USE_STATIC_LIBS ON) # suffix -s
          if(WITH_WINDOWS_FIND_MODULES)
            find_package(Boost COMPONENTS date_time filesystem thread regex system ${boost_extra_libs})
          endif()
          if(NOT Boost_FOUND)
            warn_hardcoded_paths(BOOST)
            set(BOOST ${LIBBL_SVN_DIR}/boost)
            set(BOOST_INCLUDE_DIR ${BOOST}/include)
            set(BOOST_LIBPATH ${BOOST}/lib)
            if(CMAKE_CL_64)
              set(BOOST_POSTFIX "vc141-mt-x64-1_70.lib")
              set(BOOST_DEBUG_POSTFIX "vc141-mt-gd-x64-1_70.lib")
            endif()
            set(BOOST_LIBRARIES
              optimized ${BOOST_LIBPATH}/libboost_date_time-${BOOST_POSTFIX}
              optimized ${BOOST_LIBPATH}/libboost_filesystem-${BOOST_POSTFIX}
              optimized ${BOOST_LIBPATH}/libboost_regex-${BOOST_POSTFIX}
              optimized ${BOOST_LIBPATH}/libboost_system-${BOOST_POSTFIX}
              optimized ${BOOST_LIBPATH}/libboost_thread-${BOOST_POSTFIX}
              optimized ${BOOST_LIBPATH}/libboost_chrono-${BOOST_POSTFIX}
              debug ${BOOST_LIBPATH}/libboost_date_time-${BOOST_DEBUG_POSTFIX}
              debug ${BOOST_LIBPATH}/libboost_filesystem-${BOOST_DEBUG_POSTFIX}
              debug ${BOOST_LIBPATH}/libboost_regex-${BOOST_DEBUG_POSTFIX}
              debug ${BOOST_LIBPATH}/libboost_system-${BOOST_DEBUG_POSTFIX}
              debug ${BOOST_LIBPATH}/libboost_thread-${BOOST_DEBUG_POSTFIX}
              debug ${BOOST_LIBPATH}/libboost_chrono-${BOOST_DEBUG_POSTFIX}
            )
            if(WITH_CYCLES_OSL)
              set(BOOST_LIBRARIES ${BOOST_LIBRARIES}
                optimized ${BOOST_LIBPATH}/libboost_wave-${BOOST_POSTFIX}
                debug ${BOOST_LIBPATH}/libboost_wave-${BOOST_DEBUG_POSTFIX})
            endif()
            if(WITH_INTERNATIONAL)
              set(BOOST_LIBRARIES ${BOOST_LIBRARIES}
                optimized ${BOOST_LIBPATH}/libboost_locale-${BOOST_POSTFIX}
                debug ${BOOST_LIBPATH}/libboost_locale-${BOOST_DEBUG_POSTFIX})
            endif()
          else() # we found boost using find_package
            set(BOOST_INCLUDE_DIR ${Boost_INCLUDE_DIRS})
            set(BOOST_LIBRARIES ${Boost_LIBRARIES})
            set(BOOST_LIBPATH ${Boost_LIBRARY_DIRS})
          endif()
          set(BOOST_DEFINITIONS "-DBOOST_ALL_NO_LIB")
         endif()
    else()
        import_boost()
    endif()

endmacro()



macro(import_boost2)
  set(Boost_USE_STATIC_RUNTIME ON) # prefix lib
  set(Boost_USE_MULTITHREADED ON) # suffix -mt
  set(Boost_USE_STATIC_LIBS ON) # suffix -s


 # find_package(Boost COMPONENTS date_time filesystem thread regex system ${boost_extra_libs})



get_filename_component(vcpkg  ${CMAKE_TOOLCHAIN_FILE} PATH)
get_filename_component(vcpkg  ${vcpkg} PATH)
get_filename_component(vcpkg  ${vcpkg} PATH)
set(vcpkg_installed  ${vcpkg}/installed/${VCPKG_TARGET_TRIPLET})

    set(BOOST_INCLUDE_DIR ${vcpkg_installed}/include)
    set(BOOST_LIBPATH ${vcpkg_installed})
   set(BOOST_DEBLIBPATH ${vcpkg_installed}/debug/lib)
    set(BOOST_POSTFIX "vc140-mt.lib")
    set(BOOST_DEBUG_POSTFIX "vc140-mt-gd.lib")


    set(BOOST_LIBRARIES
      optimized ${BOOST_LIBPATH}/boost_date_time-${BOOST_POSTFIX}
      optimized ${BOOST_LIBPATH}/boost_filesystem-${BOOST_POSTFIX}
      optimized ${BOOST_LIBPATH}/boost_regex-${BOOST_POSTFIX}
      optimized ${BOOST_LIBPATH}/boost_system-${BOOST_POSTFIX}
      optimized ${BOOST_LIBPATH}/boost_thread-${BOOST_POSTFIX}
      optimized ${BOOST_LIBPATH}/boost_chrono-${BOOST_POSTFIX}
      debug ${BOOST_DEBLIBPATH}/boost_date_time-${BOOST_DEBUG_POSTFIX}
      debug ${BOOST_DEBLIBPATH}/boost_filesystem-${BOOST_DEBUG_POSTFIX}
      debug ${BOOST_DEBLIBPATH}/boost_regex-${BOOST_DEBUG_POSTFIX}
      debug ${BOOST_DEBLIBPATH}/boost_system-${BOOST_DEBUG_POSTFIX}
      debug ${BOOST_DEBLIBPATH}/boost_thread-${BOOST_DEBUG_POSTFIX}
      debug ${BOOST_DEBLIBPATH}/boost_chrono-${BOOST_DEBUG_POSTFIX}
    )


    if(WITH_CYCLES_OSL)
      set(boost_extra_libs wave)
      set(BOOST_LIBRARIES ${BOOST_LIBRARIES}
        optimized ${BOOST_LIBPATH}/libboost_wave-${BOOST_POSTFIX}
        debug ${BOOST_LIBPATH}/libboost_wave-${BOOST_DEBUG_POSTFIX})
    endif()
    if(WITH_INTERNATIONAL)
      set(BOOST_LIBRARIES ${BOOST_LIBRARIES}
        optimized ${BOOST_LIBPATH}/boost_locale-${BOOST_POSTFIX}
        debug ${BOOST_DEBLIBPATH}/boost_locale-${BOOST_DEBUG_POSTFIX})
    endif()


  
     include_directories(SYSTEM ${BOOST_INCLUDE_DIR} )

    set(BOOST_DEFINITIONS "-DBOOST_ALL_NO_LIB")



endmacro()


macro(find_spirv arg1)

set(ProjectName ${arg1})
set(SPIRV_LIB_DIR "${AEOLUS_BASE_DIR}/lib/SPIRV/lib")
set(SPIRV_INC_DIR  "${AEOLUS_BASE_DIR}/lib/SPIRV/include")

target_link_libraries(${ProjectName}  PRIVATE 
              ${SPIRV_LIB_DIR}/SPIRV-Tools.lib
              ${SPIRV_LIB_DIR}/SPIRV-Tools-link.lib
              ${SPIRV_LIB_DIR}/SPIRV-Tools-opt.lib
              )
target_include_directories(${ProjectName}   PUBLIC ${SPIRV_INC_DIR}  ${SPIRV_INC_DIR}/spirv-tools)

endmacro()

macro(config_gtest)

if( WITH_GTESTS)
     set(GTEST_INCLUDE_DIRS  "${LIBBLENDER_BASE_DIR}/extern/gtest/include" CACHE   STRING "gtest_local_directory")
     set(GMOCK_INCLUDE_DIRS  "${LIBBLENDER_BASE_DIR}/extern/gmock/include" CACHE  STRING "gmock_local_directory")
 endif()

if(WITH_LIBMV OR WITH_GTESTS OR (WITH_CYCLES AND WITH_CYCLES_LOGGING))
  if(WITH_SYSTEM_GFLAGS)
    find_package(Gflags)
    if(NOT GFLAGS_FOUND)
      message(FATAL_ERROR "System wide Gflags is requested but was not found")
    endif()
    # FindGflags does not define this, and we are not even sure what to use here.
    set(GFLAGS_DEFINES)
  else()
    set(GFLAGS_DEFINES
      -DGFLAGS_DLL_DEFINE_FLAG=
      -DGFLAGS_DLL_DECLARE_FLAG=
      -DGFLAGS_DLL_DECL=
    )
    set(GFLAGS_NAMESPACE "gflags")
    set(GFLAGS_LIBRARIES extern_gflags)
    set(GFLAGS_INCLUDE_DIRS   "${LIBBLENDER_BASE_DIR}/extern/gflags/src" CACHE  STRING "gflags local external directory")
    #-# set(GFLAGS_INCLUDE_DIRS "${PROJECT_SOURCE_DIR}/extern/gflags/src")Sn
  endif()

  if(WITH_SYSTEM_GLOG)
    find_package(Glog)
    if(NOT GLOG_FOUND)
      message(FATAL_ERROR "System wide Glog is requested but was not found")
    endif()
    # FindGlog does not define this, and we are not even sure what to use here.
    set(GLOG_DEFINES)
  else()
    set(GLOG_DEFINES
      -DGOOGLE_GLOG_DLL_DECL=
    )
    set(GLOG_LIBRARIES extern_glog)
    if(WIN32)
      set(GLOG_INCLUDE_DIRS ${LIBBLENDER_BASE_DIR}/extern/glog/src/windows CACHE  STRING "glog  local external directory")
      #-# set(GLOG_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/extern/glog/src/windows)
    else()
      set(GLOG_INCLUDE_DIRS ${LIBBLENDER_BASE_DIR}/extern/glog/include CACHE  STRING "glog  local external directory")
      #-# set(GLOG_INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/extern/glog/include)
    endif()
  endif()
endif()

endmacro()



macro(configure_glslang TGT)

set(SPIRV_LIB ${LIB_DIR}/lib/glslang)
target_link_directories(${TGT} PRIVATE  ${SPIRV_LIB}/lib)
target_include_directories(${TGT} PRIVATE  ${SPIRV_LIB}/include/glslang)



list(APPEND libs  
GenericCodeGend.lib
glslangd.lib
MachineIndependentd.lib
OGLCompilerd.lib
OSDependentd.lib
SPIRVd.lib
SPVRemapperd.lib
psapi.lib
)


set(SPIRV_CROSS_LIB ${LIB_DIR}/lib/spirv-cross)
target_link_directories(${TGT} PRIVATE  ${SPIRV_CROSS_LIB}/lib)
target_include_directories(${TGT} PRIVATE  ${SPIRV_CROSS_LIB}/include)


list(APPEND libs  
   spirv-cross-cored.lib
      spirv-cross-glsld.lib

      # spirv-cross-utild.lib
        #spirv-cross-reflectd.lib
        # spirv-cross-cppd.lib
)

target_link_libraries(${TGT}  PUBLIC ${libs})

message("CONFIGURE   GLSLANG   ${SPIRV_LIB}   ${SPIRV_CROSS_LIB}  ")
message("CONFIGURE   GLSLANG  Link libs   ####################    ${libs}    ####################  ")
unset(libs)





endmacro()




macro(append_optTest targ)

         set(_SOURCE_FILES_SHADER)
        set( _SOURCE_FILES)
         set(SHADERS_DIR ${LIB_DIR}/libAeolusOptix/shaders/rt)
        list( APPEND   _SHADERS_   ${SHADERS_DIR})
        append_almity_shader(_SOURCE_FILES_SHADER  _SHADERS_)

        set(SRC_DIR ${LIB_DIR}/libAeolus/src)
        append_almity(_SOURCE_FILES  SRC_DIR)
        list(REMOVE_ITEM _SOURCE_FILES 
                              "${LIB_DIR}/libAeolus/src/util/global.hpp"
                            "${LIB_DIR}/libAeolus/src/util/global.cpp"
                             "${LIB_DIR}/libAeolus/src/util/log.hpp"
                            "${LIB_DIR}/libAeolus/src/util/log.cpp"
          )

 set(LIBTEST_DIR "${CMAKE_CURRENT_LIST_DIR}")
 append_almity(_SOURCE_FILES  LIBTEST_DIR)

list(REMOVE_ITEM _SOURCE_FILES 
                       "${LIBTEST_DIR}/circusTest.cpp"
                     
 )
          list(REMOVE_ITEM _SOURCE_FILES 
                            "${LIB_DIR}/libAeolus/src/extMain.cpp"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/SnapShot.cpp"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/SnapShot.h"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/Canvas.cpp"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/common.h"
                            "${LIB_DIR}/libAeolus/src/aeolus/groupVk/group.cpp"
                             "${OPTIXSRC_DIR}/extpy.cpp")


 message("target append OPTTEST    ${_SOURCE_FILES}  ")

  message("target append OPTTEST    ${AEOLUS_CONFIG_HEADER} ")





enable_testing()
add_executable(${targ}  ${_SOURCE_FILES} ${AEOLUS_CONFIG_HEADER} ${_SOURCE_FILES_SHADER}  ${LIB_DIR}/lib/VulkanMemoryAllocator/vk_mem_alloc.h)
target_global_exe(${targ})
target_include_directories(${targ}  PRIVATE  
     ${LIB_DIR}/lib/VulkanMemoryAllocator
     ${LIB_DIR}/libAeolusOptix/shaders
     )


unset(_SOURCE_FILES)
unset(_SOURCE_FILES_SHADER)
unset(_SHADERS_)

add_test(${targ} ${targ})

endmacro()




macro(link_main_libs targ)



#import_boost()
#import_oiio()
  message(STATUS  "  BOOST Library  ${BOOST_LIBRARIES} ")
  message(STATUS  "CUDA_LIBRARIES  ${CUDA_LIBRARIES}")



if(WITH_CUDA_DYNLOAD)
target_include_directories(${targ} PRIVATE  ${LIBBLENDER_BASE_DIR}/extern/cuew/include)
add_definitions(-DWITH_CUDA_DYNLOAD)
endif()


message("########################### ${targ}  link_main_libs targ ######################### ")

target_link_libraries(${targ}  PUBLIC ${EXTRA_LIBS}   
                                                              #${CUDA_LIBRARIES} 
                                                              ${OPENIMAGEIO_LIBRARY} 
                                                              ${OPENCOLORIO_LIBRARIES} 
                                                              ${OPENGLES_LIBRARY}
                                                              #${HIREDIS_LIBRARIES} 
                                                              #extern_cuew
                                                              )
set_target_properties(${targ} PROPERTIES LINK_DEPENDS_NO_SHARED true)
target_link_libraries(${targ}  PUBLIC ${BLENDER_LIBS}  )

target_link_libraries(${targ} 
  PRIVATE
    Boost::filesystem
    Boost::regex
    Boost::system
    Boost::thread
    Boost::chrono
    Boost::locale
    Boost::date_time
   )



message("########################### ${targ}  link_main_libs    ${BLENDER_LIBS} ######################### ")
message("########################### ${targ}  link_main_libs    ${EXTRA_LIBS} ######################### ")

endmacro()



macro(compile_custom)
if(MSVC)

add_compile_options(
    "-JMC"
    "-std:c++latest"
    "-Zc:wchar_t"
    "-Zc:inline"
    "-Zc:forScope"
    "-ZI"
    "-MP"
    "-sdl"
    "-RTC1"
)

add_compile_options(
  "$<$<CONFIG:DEBUG>:-W4;-WX-;-permissive-;>"
)

add_compile_options(
  "$<$<CONFIG:DEBUG>:-${MULTIMODE};-GS;-Gd;-Gm-;-Od>"
)

add_compile_options(
"-fp:precise"
"-FC"
"-Fax64/Debug"
"-Fox64/Debug"
"-errorReport:prompt"
"-EHsc"
"-nologo"
"-diagnostics:column"
)
endif()


add_definitions(-DAEOLUS)
add_definitions(-DWITH_VULKAN)
add_definitions(-DAEOLUS_MM=1)
add_definitions(-DVULKAN_THREE)
add_definitions(-DVK_USE_PLATFORM_WIN32_KHR)
add_definitions(-DVK_PROTOTYPES)
add_definitions(-D_CRT_SECURE_NO_WARNINGS)
add_definitions(-D_USE_MATH_DEFINES)
add_definitions(-D_WINDLL)
add_definitions(-D_MBCS)

add_definitions(-DRTC_EXPORTS_srv)
if(MULTIMODE STREQUAL  "MTd")
add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
endif(MULTIMODE STREQUAL  "MTd")

endmacro()








macro (warning_sup _WARNINGS)


  if(MSVC_VERSION GREATER_EQUAL 1911)
  endif()

  #string(REPLACE ";" " " _WARNINGS "${_WARNINGS}")
  #set(C_WARNINGS "${_WARNINGS}")
  #set(CXX_WARNINGS "${_WARNINGS}")
  add_compile_options(${_WARNINGS})
  message("warning  suppress   ${_WARNINGS} ")
  unset(_WARNINGS)

endmacro()



macro(remove_include_directories)

get_directory_property (the_include_dirs INCLUDE_DIRECTORIES)

#list(APPEND rmv "D:/blender/src/lib/win64_vc15/python/37/include" "D:/C/Aeoluslibrary/libAeolusOptix/aeolus_device")
if(ARGC GREATER  0)
message("<<<<<<<<<<<<<<<<<<<<<<<  Remove directories   >>>>>>>>>>>>>>>>>>>>>>>>>>>>  " , ${ARGC} ,"      ", ${ARGN})
string(JOIN "|" rmv ${ARGN})
foreach(arg ${the_include_dirs})
   string(REGEX MATCH ${rmv} nval  "${arg}")
   if( NOT nval )
     list(APPEND nlist ${arg})
   endif()
endforeach()
message("INCLUDE DIRECTORIES  :  "  ${nlist} )
set_directory_properties(PROPERTIES INCLUDE_DIRECTORIES "${nlist}")

endif()

endmacro()


macro(print_list)
list(APPEND LST  ${ARGN})
string(REPLACE ";"  "  \n" str "${LST}")
message(STATUS ${str})
endmacro()