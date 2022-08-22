
set(targ "opttest")
current_dir_modify(TRUE)
  set(_WARNINGS
    "/wd4200"  # zero-sized array in struct/union
  )
    warning_sup(${_WARNINGS})

 append_optTest(${targ})

include(FetchContent)
FetchContent_Declare(
    rapidjson
    GIT_REPOSITORY https://github.com/Tencent/rapidjson.git
    GIT_TAG        v1.1.0
)
FetchContent_GetProperties(rapidjson)
if(NOT rapidjson_POPULATED)
  FetchContent_Populate(rapidjson)
endif()

 target_include_directories(${targ}  PRIVATE ${rapidjson_SOURCE_DIR}/include)
 set_target_properties(${targ} PROPERTIES LINK_DEPENDS_NO_SHARED true)
 target_include_directories(${targ} PRIVATE ${TBB_INCLUDE_DIRS})
target_compile_definitions(${targ} PRIVATE ${TBB_DEFINITIONS})
target_link_libraries(${targ}  PRIVATE                   
                                  libthreepy
                                  libvkmm
                                  libktx
                                  ${CYCLES_LIB}
                                  winmm.lib
                                  dmoguids.lib
                                  msdmo.lib
                                 Secur32.lib
                                 wmcodecdspuuid.lib
                                 ws2_32.lib
                                 strmiids.lib

  )
target_link_libraries(${targ}
  PRIVATE
    ${PTHREAD_LIBRARY}
    PNG::PNG
    TIFF::TIFF
    ${LIBLZMA_LIBRARIES}
    ${JPEG_LIBRARIES}
    Boost::filesystem
    Boost::regex
    Boost::system
    Boost::thread
    Boost::chrono
    Boost::locale
    Boost::date_time
    TBB::tbb
    TBB::tbbmalloc
    IlmBase::Half
    OpenEXR::IlmImf
    IlmBase::Imath
    IlmBase::IlmThread
   IlmBase::Iex
   OpenImageIO::OpenImageIO
   OpenImageIO::OpenImageIO_Util
   Vulkan::Vulkan
   ${VCPKG_ROOT}/osdCPU.lib
   #${VCPKG_ROOT}/osdGPU.lib
   ${VCPKG_ROOT}/OpenColorIO.lib
   ${VCPKG_ROOT}/yaml-cpp.lib
   ${VCPKG_ROOT}/tinyxml.lib
  ${VCPKG_ROOT}/hiredis.lib
  ${Python_LIBRARIES}
   )


set_target_properties(${targ} PROPERTIES LINK_FLAGS "/ignore:4217")



 get_filename_component(BINARY_DIR_P   "${CMAKE_BINARY_DIR}" PATH)
 set(OutputDir "${BINARY_DIR_P}/bin/${CMAKE_CONFIGURATION_TYPES}")
#if(${CMAKE_CONFIGURATION_TYPES} STREQUAL "Debug")
#    set(VCPKG_BIN_DIR "${_VCPKG_INSTALLED_DIR}/x64-windows/debug/bin" )
#else()
#    set(VCPKG_BIN_DIR "${_VCPKG_INSTALLED_DIR}/x64-windows/bin" )
#endif()

    set(VCPKG_BIN_DIR "${_VCPKG_INSTALLED_DIR}/x64-windows/bin" )
    file(GLOB SRC_FILES ${VCPKG_BIN_DIR}/python*.dll)

   message(STATUS  ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>.copy dll ${SRC_FILES} >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  ${OutputDir} ")
 add_custom_target(copyDll
    COMMAND ${CMAKE_COMMAND} -E copy   ${SRC_FILES}   ${OutputDir}
)
add_dependencies(${targ} copyDll)