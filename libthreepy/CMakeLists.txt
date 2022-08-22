project (libthreepy)
get_filename_component(LIB_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
include(${LIB_DIR}/cmake/utils_macro.cmake)

message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmake libthreepy   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_CXX_FLAGS_RELEASE "-O2 -Werror")

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

#/Yc"pch.h" 
#/Fp"x64\Debug\libthreepy_d.pch" 

add_definitions(-D_LIB)
add_definitions(-D_CRT_SECURE_NO_WARNINGS)
add_definitions(-D_USE_MATH_DEFINES)
add_definitions(-D_WINDLL)
add_definitions(-D_MBCS)
add_definitions(-DLIB_THREEPY)
add_definitions(-DAEOLUS)
add_definitions(-DVULKAN_THREE)
add_definitions(-DVK_USE_PLATFORM_WIN32_KHR)
add_definitions(-DVK_PROTOTYPES)


if(MULTIMODE STREQUAL  "MTd")
add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
endif(MULTIMODE STREQUAL  "MTd")




get_filename_component(LIBTHREEPY_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)
set(SRC_DIR "${LIBTHREEPY_DIR}/src")
set(AEOLUS_DIR  "${CMAKE_CURRENT_LIST_DIR}/../libAeolus/src")
set(LIBPACK_DIR  "${CMAKE_CURRENT_LIST_DIR}/../lib/packages")

include_directories(
       "${CMAKE_CURRENT_LIST_DIR}"
       "${AEOLUS_DIR}"
       "${LIBPACK_DIR}/include"
       "${SRC_DIR}"
)


include_directories(${Vulkan_INCLUDE_DIR})
include_directories(${_Python3_INCLUDE_DIR})

message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmade libthreepy      ${_Python3_INCLUDE_DIR}    ${Vulkan_LIBRARY} $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
file(GLOB_RECURSE SOURCE_FILES
    "*.h"
    "*.hpp"
    "*.cpp"
)


add_library(${PROJECT_NAME} STATIC ${SOURCE_FILES})
target_link_libraries(${PROJECT_NAME}  PRIVATE ${EXTRA_LIBS})


message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmade libthreepy $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")