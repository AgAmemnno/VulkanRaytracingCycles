project (libvkmm)

message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmade libvkmm $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

get_filename_component(LIB_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
include(${LIB_DIR}/cmake/utils_macro.cmake)

if(MSVC)
  set(_WARNINGS
    "/wd4200"  # zero-sized array in struct/union
  )
  warning_sup(${_WARNINGS})
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
add_definitions(-DWITH_CIRCUS)



message("Define WITH_CIRCUS")
if(MULTIMODE STREQUAL  "MTd")
add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
endif(MULTIMODE STREQUAL  "MTd")

get_filename_component(LIB_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(BUILD_DIR   "${LIB_DIR}/out/build")
set(LIBVKMM_DIR "${CMAKE_CURRENT_LIST_DIR}/src")
set(LIBTHREEPY_DIR "${LIB_DIR}/libthreepy/src")
set(LIBPACK_DIR "${LIB_DIR}/lib/packages")

include_directories(
       "${LIBVKMM_DIR}"
       "${LIBTHREEPY_DIR}"
       "${LIBPACK_DIR}/include"
)
include_directories(${Vulkan_INCLUDE_DIR})
if(${MULTIMODE} STREQUAL  "MTd")
list( APPEND   EXTRA_LIBS    libktx)
else()
list( APPEND   EXTRA_LIBS    ${LIBPACK_DIR}/lib/ktx.lib)
list( APPEND   EXTRA_LIBS    ${LIBPACK_DIR}/lib/libktx_d.lib)
endif(${MULTIMODE} STREQUAL  "MTd")


file(GLOB_RECURSE SOURCE_FILES
    "*.h"
    "*.hpp"
    "*.cpp"
)



set(EXTRA_LIBS ${EXTRA_LIBS} 
                             ${Vulkan_LIBRARY}
                             libthreepy
)

              
add_library(${PROJECT_NAME} STATIC ${SOURCE_FILES} ${AEOLUS_CONFIG_HEADER})
target_include_directories(${PROJECT_NAME} PRIVATE  ${LIB_DIR}/lib/VulkanMemoryAllocator )


message("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ cmade libvkmm $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
