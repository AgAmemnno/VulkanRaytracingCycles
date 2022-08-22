project (libAeolus)




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
"-Fdlibvkmm.dir/Debug/libvkmm.pdb"
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
add_definitions(-DAEOLUS_MM=1)
add_definitions(-DVULKAN_THREE)
add_definitions(-DVK_USE_PLATFORM_WIN32_KHR)
add_definitions(-DVK_PROTOTYPES)
add_definitions(-D_CRT_SECURE_NO_WARNINGS)
add_definitions(-D_USE_MATH_DEFINES)
add_definitions(-D_WINDLL)
add_definitions(-D_MBCS)


get_filename_component(LIB_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(BUILD_DIR   "${LIB_DIR}/out/build")
set(LIBSRC_DIR "${CMAKE_CURRENT_LIST_DIR}/src")
set(LIBTHREEPY_DIR "${LIB_DIR}/libthreepy/src")
set(LIBVKMM_DIR "${LIB_DIR}/libvkmm/src")
set(LIBVKVIDEO_DIR "${LIB_DIR}/libvkvideo/include")
set(LIBPACK_DIR "${LIB_DIR}/lib/packages")
set(LIB_PYTHON  "D:/Python/Python-3.8.2/PCbuild/amd64/python38_d.lib")






include_directories(
       "${LIBSRC_DIR}"
       "${LIBTHREEPY_DIR}"
       "${LIBVKMM_DIR}"
        "${LIBVKVIDEO_DIR}"
       "${LIBPACK_DIR}/include"
       "D:/Python/Python-3.8.2/PC"
       "D:/Python/Python-3.8.2/Include"
       "D:/C/openvr/headers"
       "D:/C/AeolusDLL/AeolusDLL/script"
)

find_package(Vulkan REQUIRED)
include_directories(${Vulkan_INCLUDE_DIR})


find_library(
    ap4_lib  
    ap4
    PATH
   "${LIB_DIR}/lib/packages"
)

if(NOT  ap4_lib  )
  message(FATAL_ERROR " ap4_lib    not found")
endif()
list( APPEND EXTRA_LIBS  ${ap4_lib})


find_library(
    ft_lib  
    freetype
    PATH
   ${LIBPACK_DIR}/lib
)
if(NOT  ft_lib  )
  message(FATAL_ERROR "ft_lib    not found")
endif()
list( APPEND EXTRA_LIBS  ${ft_lib})



list( APPEND   EXTRA_LIBS    ${LIBPACK_DIR}/lib/ktx.lib)

list( APPEND   EXTRA_LIBS    ${LIBPACK_DIR}/lib/libktx_d.lib)

  
link_directories("${LIB_DIR}/lib/openexr/lib/")
include_directories(${LIB_DIR}/lib/openexr/include)



if(${MULTIMODE} STREQUAL  "MTd")
include_directories(${LIB_DIR}/lib/webrtc/include)
list( APPEND   EXTRA_LIBS    ${LIB_DIR}/lib/webrtc/lib/libwebrtc_d.lib)
endif(${MULTIMODE} STREQUAL  "MTd")




set(EXTRA_LIBS    ${LIB_PYTHON}
                                ${Vulkan_LIBRARY}
                                  libthreepy
                                  libvkmm
                                 libvkvideo
                               ${EXTRA_LIBS} 
  )
                            


file(GLOB_RECURSE SOURCE_FILES
    "*.h"
    "*.hpp"
    "*.cpp"
)

set(DST_PYTHON D:/Python/Aeolus/venv/Lib/site-packages/aeolus-0.0.1-py3.8.egg)

add_library(${PROJECT_NAME} SHARED ${SOURCE_FILES})
set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "cthreepy_d")
set_target_properties(${PROJECT_NAME}  PROPERTIES SUFFIX ".pyd")

string(TOUPPER ${CMAKE_CONFIGURATION_TYPES} OUTPUTCONFIG )

set_target_properties(${PROJECT_NAME} 
    PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG}  ${DST_PYTHON}
        RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG}  ${DST_PYTHON}
)

target_link_libraries(${PROJECT_NAME}  PRIVATE ${EXTRA_LIBS})


string(REPLACE "/" "\\" UserVCX  "${LIB_DIR}\\libAeolus\\libAeolus.vcxproj.user")
string(REPLACE "/" "\\" DstUserVCX "${BUILD_DIR}\\x64-Debug\\libAeolus\\")



execute_process(COMMAND cmd /c "copy /Y ${UserVCX}  ${DstUserVCX}"
RESULT_VARIABLE CMD_ERROR 
        OUTPUT_FILE CMD_OUTPUT
        )
      
if(${CMD_ERROR})
MESSAGE( FATAL_ERROR     "CMD_ERROR:" ${CMD_ERROR}:: CMD::   "copy /Y ${UserVCX}  ${DstUserVCX}     " )
endif(${CMD_ERROR})


