project (libktx)




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


add_definitions(-DVK_USE_PLATFORM_WIN32_KHR)
add_definitions(-DVK_PROTOTYPES)
add_definitions(-D_CRT_SECURE_NO_WARNINGS)
add_definitions(-D_USE_MATH_DEFINES)
add_definitions(-D_MBCS)

 add_definitions(-DKTX_OPENGL)
if(MULTIMODE STREQUAL  "MTd")
add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
endif(MULTIMODE STREQUAL  "MTd")

get_filename_component(LIB_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
set(BUILD_DIR   "${LIB_DIR}/out/build")
set(LIBKTX_DIR "${LIB_DIR}/${PROJECT_NAME}/src")
set(KTX_DIR "${LIB_DIR}/${PROJECT_NAME}/ktx/lib")

find_package(Vulkan REQUIRED)
include_directories(${Vulkan_INCLUDE_DIR})

include_directories(
       "${LIBKTX_DIR}"
       "${LIB_DIR}/${PROJECT_NAME}/ktx/include"
       "${LIB_DIR}/${PROJECT_NAME}/stb"
)


foreach(base_dir ${LIBKTX_DIR}  ${KTX_DIR})
  
  file(GLOB_RECURSE KTX_SOURCE_FILES_
        "${base_dir}/*.h"
       "${base_dir}/*.hpp"
      "${base_dir}/*.cpp"
       "${base_dir}/*.cc"
         "${base_dir}/*.c"
           "${base_dir}/*.cxx"
   )

   list( APPEND KTX_SOURCE_FILES  ${KTX_SOURCE_FILES_})
endforeach()

#message("ktx library: base_dir : ${KTX_SOURCE_FILES}")


add_library(${PROJECT_NAME}  STATIC  ${KTX_SOURCE_FILES})
#target_link_libraries(libdc_srv  PRIVATE ${EXTRA_LIBS})
#target_include_directories(ktx  PUBLIC ${LIBKTX_DIR}  ${KTX_DIR}/include  ${KTX_DIR}/stb )



