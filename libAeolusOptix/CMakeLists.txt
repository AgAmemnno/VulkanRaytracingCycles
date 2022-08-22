project (libAeolusOptix)
message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmake libAeolusOptix $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

set(CMAKE_VERBOSE_MAKEFILE on)

set(CREATOR_LIB  OFF  CACHE BOOL  "creator as a libarary"  FORCE) 

include(${LIBBLENDER_BASE_DIR}/build_files/cmake/macros.cmake)
unset(BLENDER_INCLUDE)
unset(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS)

set(CMAKE_MODE_CREATOR_BUILD OFF)
set(CIRCUS_MODE ON)
set(TEST_TYPE "pylib")


include_directories(${Vulkan_INCLUDE_DIR})
set(LIB_DIR ${CMAKE_HOME_DIRECTORY})
include(${CMAKE_HOME_DIRECTORY}/cmake/utils_macro.cmake)



configure_blender()
message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmake libAeolusOptix configuration openGL $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
configure_openGL()
message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmake libAeolusOptix link  blender $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
link_blender()


list(APPEND CREATOR_DEF 
-DCREATOR_LIB
-D_CRT_SECURE_NO_WARNINGS
-D_CRT_NONSTDC_NO_DEPRECATE
-D_CRT_SECURE_NO_DEPRECATE
-D_SCL_SECURE_NO_DEPRECATE
-D_ALLOW_KEYWORD_MACROS
-D_WIN32_WINNT=0x601
-DOIIO_STATIC_DEFINE
-DOIIO_NO_SSE=1
-DWITH_TBB_MALLOC
-D__SSE__
-D__MMX__
-D__SSE2__
-D__LITTLE_ENDIAN__
-DWITH_ASSERT_ABORT
-DWITH_KERNEL_SSE2
-DWITH_KERNEL_SSE3
-DWITH_KERNEL_SSE41
-DWITH_KERNEL_AVX
-DWITH_KERNEL_AVX2
-DBOOST_ALL_NO_LIB
-DUSE_TBB=0
-DWITH_SYSTEM_PUGIXML
-DWITH_HEADLESS
-DNOMINMAX
)
 add_definitions(${CREATOR_DEF})

  add_definitions(
  -DCCL_NAMESPACE_BEGIN=namespace\ ccl\ {
  -DCCL_NAMESPACE_END=}
)



message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmake libAeolusOptix add cycles  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
    add_subdirectory(cycles)
    add_subdirectory(aeolus_device/device)
    include_directories( ${LIB_DIR}/libAeolusOptix/aeolus_device)

    add_subdirectory(blender)
    include_directories( ${LIB_DIR}/libAeolusOptix/blender)
      list(APPEND CYCLES_LIB 
                        cycles_util 
                        cycles_bvh
                        cycles_render
                        cycles_subd
                        cycles_graph
                        aeolus_device
                        bf_intern_cycles
                        bf_intern_numaapi
                        bf_intern_sky
                        bf_intern_guardedalloc
        )

set(LIBCYCLES_DIR "${LIB_DIR}/libAeolusOptix/cycles")
include_directories(${LIBCYCLES_DIR})


 #add_subdirectory(compile)
 compile_custom()

include(${CMAKE_HOME_DIRECTORY}/cmake/bpy_macro.cmake)


set(BUILD_DIR   "${LIB_DIR}/out/build")
set(LIBSRC_DIR "${CMAKE_CURRENT_LIST_DIR}/src")
set(LIBTHREEPY_DIR "${LIB_DIR}/libthreepy/src")
set(LIBVKMM_DIR "${LIB_DIR}/libvkmm/src")
set(LIBPACK_DIR "${LIB_DIR}/lib/packages")





link_directories(${LIB_DIR}/out/build/lib ) # "../lib/${CMAKE_CONFIGURATION_TYPES}")

#link_directories("D:/C/Aeoluslibrary/lib/glslang/lib" ) # "../lib/${CMAKE_CONFIGURATION_TYPES}")
#link_directories("D:/C/Aeoluslibrary/lib/spirv-cross/lib" ) # "../lib/${CMAKE_CONFIGURATION_TYPES}")






include_directories(
       "${LIBSRC_DIR}"
       "${LIBTHREEPY_DIR}"
       "${LIBVKMM_DIR}"
       "${LIBPACK_DIR}/include"
       "${LIB_DIR}/libAeolusOptix/shaders/intern/kernel/prof"
)




link_directories("${LIB_DIR}/lib/openexr/lib/")
include_directories(${LIB_DIR}/lib/openexr/include)
include_directories(${CUDA_TOOLKIT_INCLUDE})


                  



  string(TOUPPER ${CMAKE_CONFIGURATION_TYPES} OUTPUTCONFIG )






        add_definitions(-DGLOG_NO_ABBREVIATED_SEVERITIES)
        set(SRC_DIR ${LIB_DIR}/libAeolus/src)
        set(SHADERS_DIR ${LIB_DIR}/libAeolusOptix/shaders)
        set(PySCR_DIR ${LIB_DIR}/libAeolusOptix/scripts)
        set(OPTIXSRC_DIR ${LIB_DIR}/libAeolusOptix/src)


        include_directories(${SRC_DIR} ${BLENDER_INCLUDE})
        list( APPEND   SHADERS_   ${SHADERS_DIR})

        append_almity_shader(SOURCE_FILES_SHADER  SHADERS_)

        list( APPEND   SCRIPTS_   ${PySCR_DIR})
        append_almity_python(SOURCE_FILES_SCRIPT  SCRIPTS_)

        append_almity(SOURCE_FILES  SRC_DIR)
        append_almity(SOURCE_FILES  OPTIXSRC_DIR)

        message(STATUS  "  AeolusSrvOptix Mode  TEST= ${CMAKE_MODE_TEST} ")
         list(REMOVE_ITEM SOURCE_FILES 
                            "${LIB_DIR}/libAeolus/src/extMain.cpp"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/SnapShot.cpp"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/SnapShot.h"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/Canvas.cpp"
                            "${LIB_DIR}/libAeolus/src/aeolus/canvasVk/common.h"
                            "${LIB_DIR}/libAeolus/src/aeolus/groupVk/group.cpp"
                             "${OPTIXSRC_DIR}/extpy.cpp")
                 
                         add_definitions(-DPY_LIB)
                         #add_library(${PROJECT_NAME} STATIC  ${SOURCE_FILES} ${AEOLUS_CONFIG_HEADER}   ${SOURCE_FILES_SHADER} ${SOURCE_FILES_SCRIPT})
                         #target_global_lib(${PROJECT_NAME})
                        #
                         add_subdirectory(opttest)

  message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmake libAeolusOptix $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")