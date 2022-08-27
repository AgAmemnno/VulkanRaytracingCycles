
project(CircusRender)
cmake_minimum_required(VERSION 3.10.2)

#git rev-parse HEAD
# see "cmake --help-policy CMP0003"
# So library linking is more sane
cmake_policy(SET CMP0003 NEW)

# So BUILDINFO and BLENDERPATH strings are automatically quoted
cmake_policy(SET CMP0005 NEW)

# So syntax problems are errors
cmake_policy(SET CMP0010 NEW)

# Input directories must have CMakeLists.txt
cmake_policy(SET CMP0014 NEW)
cmake_policy(SET CMP0074 NEW)


#set(CMAKE_CXX_STANDARD 20)D:\C\vcpkg\scripts\buildsystems
set(CMAKE_CXX_STANDARD_REQUIRED ON)
option(VCPKG_MANIFEST_INSTALL "vcpkg manifest install"  ON)
option(VCPKG_MANIFEST_MODE  ON)
option(_VCPKG_INSTALLED_DIR  "${LIB_DIR}/out/build/vcpkg_installed")

set(VCPKG_INCLUDE_DIR  ${_VCPKG_INSTALLED_DIR}/x64-windows/include CACHE STRING "vcpkg include directory")



get_filename_component(PROJECT_PATH   "${CMAKE_BINARY_DIR}" PATH)
get_filename_component(PROJECT_ALIAS "${CMAKE_BINARY_DIR}" NAME)

set(CONFIG_H_IN ${CMAKE_CURRENT_SOURCE_DIR}/src/Configure)
set(APP_VERSION "1.0.0")
set(AEOLUS_CONFIG_HEADER  ${PROJECT_PATH}/include/config_aeolus.h  CACHE STRING "configuration header")

include_directories(${PROJECT_PATH}/include)
include_directories(${VCPKG_INCLUDE_DIR} ) 


################### OPTIONS

option(CMAKE_MODE_LOG  "message  mode  " ON) 
option(ENABLED_VULKAN_OVR  "enable vulkan Ovr " OFF) 
option(ENABLED_VULKAN_DEBUG  "enable vulkan debug " ON) 
option(DEFAULT_PATH_USE  "default path use" OFF) 
option(CMAKE_MODE_TEST  "aeolus test mode  " ON) 
mark_as_advanced(CLEAR CMAKE_MODE_TEST)
option(CMAKE_MODE_GTEST  "gtest mode  " OFF) 
mark_as_advanced(CLEAR CMAKE_MODE_GTEST)

option(CMAKE_MODE_CREATOR_BUILD  "project mode creator build  " ON) 
mark_as_advanced(CLEAR CMAKE_MODE_CREATOR_BUILD)

set(BLENDER_ROOT  "libblender"   CACHE STRING  "blender root directory"  FORCE)

################### OPTIONS

set(AEOLUS_BASE_DIR  "${CMAKE_CURRENT_SOURCE_DIR}")
set(LOG_THREAD_FILE  "${CMAKE_CURRENT_SOURCE_DIR}/log/")
set(AEOLUS_SHADER_BP_DEF  "${CMAKE_CURRENT_SOURCE_DIR}/libAeolusOptix/shaders/intern/kernel/prof/bp_def.h")


set(GPU_DEVICE_ID  1  CACHE STRING "GPU Device Enumerarion Number." FORCE)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/utils_macro.cmake)
unset_cache_force()


set(_PROJECT_ALIAS  ${PROJECT_ALIAS}  CACHE STRING "alias" FORCE)

if (${PROJECT_ALIAS} STREQUAL "x64-Debug")

   option(CUDA_REQ_11   "enable CUDA 11"  ON) 
   mark_as_advanced(CUDA_REQ_11)

  #set(VCPKG_TARGET_TRIPLET "") # "x64-windows-static-custom" )
  #set(PYTHON_VER  "37"  CACHE STRING "Python_version")
   set(LIBBLENDER_BASE_DIR  "${AEOLUS_BASE_DIR}/${BLENDER_ROOT}" CACHE STRING "blender directory absolute path" FORCE)
  # set(LIBBL_SVN_DIR "D:/blender/src/lib/win64_vc15" CACHE INTERNAL "BLENDER SVN Library " FORCE)
  set(CURRENT_BASE_DIR  "${AEOLUS_BASE_DIR}/libAeolusOptix")
  set(MULTIMODE  "MDd"  CACHE STRING "MultiMode")
  set(ENABLED_VULKAN_HEADLESS   OFF) 
  set(ENABLED_VULKAN_OPTIX ON)
  set(INCLUDE_MATERIAL_VKVIDEO  OFF)
  set(ENABLED_VULKAN_OPENCL   ON) 

      configure_file(
         "${CONFIG_H_IN}/config_aeolus.h.in"
         "${PROJECT_PATH}/include/config_aeolus.h"
      )

          option(WITH_BLENDER_EXTENSION  "blender extension mode   " OFF) 
              mark_as_advanced(WITH_BLENDER_EXTENSION)
           option(WITH_BLENDER_LIB  "blender lib  mode   " OFF) 
              mark_as_advanced(WITH_BLENDER_LIB)



     set(_AEOLUS_LINK_DIR  "opttest"  CACHE STRING "AEOLUS_LINK_DIR"  FORCE)
     message(STATUS "PROJECT_NAME =====  "  ${PROJECT_ALIAS}   " =======  CMAKE_MODE_TEST_BUILD  FLAGS [   ${MULTIMODE} ]")
     set(WITH_BLENDER_EXTENSION  ON  CACHE BOOL  ""  FORCE) 
     set(WITH_BLENDER_LIB  OFF  CACHE BOOL  ""  FORCE) 
     
    # set(BL_PREBUILD "D:/C/CyclesVulkanRaytracing/out/build/Lib"  CACHE STRING   "extern libarary"  FORCE) # )
     #link_directories(${BL_PREBUILD})

   #set(VCPKG_TARGET_TRIPLET "x64-windows-static")
     add_definitions(-DOIIO_STATIC_DEFINE)
     add_definitions(-DOIIO_NO_SSE=1)
    find_package(OpenImageIO CONFIG REQUIRED)
     find_package(OpenColorIO)

    # find_package(OpenImageIO 2.1.16 REQUIRED)
     find_package(PNG REQUIRED)  
     find_package(TIFF REQUIRED )
     find_package (jpeg REQUIRED) 
     find_package(LibLZMA REQUIRED)

     set(Boost_NO_WARN_NEW_VERSIONS 1)
     find_package(Boost 1.70 REQUIRED COMPONENTS filesystem  regex system thread  chrono locale date_time)#  regex system thread  chrono locale)
     find_package(TBB COMPONENTS tbb tbbmalloc tbbmalloc_proxy)
    find_package(pthreads REQUIRED)
     find_package(OpenEXR 2.5 REQUIRED)
   
    find_package(TinyXML REQUIRED)
    find_package(Yaml-cpp REQUIRED )
    find_package(OpenSubdiv)
     find_package(Hiredis)
     find_package(Vulkan REQUIRED)
   
     message("*****************************************")
message("Python_ROOT " ${Python_ROOT})
#find_package(Python REQUIRED COMPONENTS Interpreter Development)
find_package(Python REQUIRED COMPONENTS Development)
message("Python_FOUND " ${Python_FOUND})
message("Python_Interpreter_FOUND " ${Python_Interpreter_FOUND})
message("Python_Development_FOUND " ${Python_Development_FOUND})
   
message("Python_LIBRARIES " ${Python_LIBRARIES})
message("Python_LIBRARY_DIRS " ${Python_LIBRARY_DIRS})
message("Python_INCLUDE_DIRS " ${Python_INCLUDE_DIRS})
message("Python_LINK_OPTIONS " ${Python_LINK_OPTIONS})
message("Python_EXECUTABLE " ${Python_EXECUTABLE})
message("Python_INTERPRETER_ID " ${Python_INTERPRETER_ID})
  
message("Python_VERSION " ${Python_VERSION})
message("Python_VERSION_MAJOR " ${Python_VERSION_MAJOR})
message("Python_VERSION_MINOR " ${Python_VERSION_MINOR})
    message("*****************************************")
    include_directories(${Python_INCLUDE_DIRS})


     set(VCPKG_ROOT  "${_VCPKG_INSTALLED_DIR}/x64-windows/debug/lib" CACHE STRING "VCPKG_ROOT_DIR"  FORCE)





     add_subdirectory(libthreepy)
     add_subdirectory(libvkmm)
     add_subdirectory(libktx)
     add_subdirectory(libAeolusOptix)




endif()
 

if(CMAKE_MODE_LOG)
message(STATUS "\n\n\n\n PROJECT_NAME       =====  ${PROJECT_ALIAS} \n" 
                               "MultiMode                    == ${MULTIMODE}\n"
                              "AEOLUS_BASE_DIR     == ${CMAKE_CURRENT_SOURCE_DIR}  \n"
              )
endif()




