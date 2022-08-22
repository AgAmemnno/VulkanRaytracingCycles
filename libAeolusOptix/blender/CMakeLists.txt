
message("internal cycle blender   ${PYTHON_LINKFLAGS}   ${PYTHON_LIBRARIES}  ${PYTHON_INCLUDE_DIRS} ")

set(INTER "${LIBBLENDER_BASE_DIR}/intern")
set(EXTER "${LIBBLENDER_BASE_DIR}/extern")
set(BLSRC "${LIBBLENDER_BASE_DIR}/source/blender")
 get_filename_component(BINARY_DIR_P   "${CMAKE_BINARY_DIR}" PATH)
set(CYCLES_INSTALL_PATH "${BINARY_DIR_P}/Lib/${CMAKE_CONFIGURATION_TYPES}")

add_compile_options(
  "$<$<CONFIG:DEBUG>:-${MULTIMODE};-GS;-Gd;-Gm-;-Od>"
)

if(MULTIMODE STREQUAL  "MTd")
add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
endif(MULTIMODE STREQUAL  "MTd")

set(INC
  ..
  ../cycles
    ${INTER}/atomic
  ${INTER}/glew-mx
  ${INTER}/guardedalloc
  ${INTER}/mikktspace
  ${BLSRC}/makesdna
  ${BLSRC}/makesrna
  ${BLSRC}/blenlib
  ${CMAKE_BINARY_DIR}/libblender/source/blender/makesrna/intern
)

set(INC_SYS
  ${GLEW_INCLUDE_DIR}
)

set(SRC
  CCL_api.h

    blender_viewport.h
    blender_id_map.h
    blender_util.h
    blender_texture.h
    blender_image.h
    blender_device.h
    blender_image.cpp
    blender_logging.cpp
    blender_texture.cpp
    blender_viewport.cpp
    blender_sync2.h
    blender_sync.cpp
    blender_device.cpp
    blender_camera.cpp
    blender_session2.h

    blender_shader.cpp

    blender_geometry.cpp
    blender_light.cpp
    blender_mesh.cpp
    blender_object.cpp
    blender_object_cull.cpp
    blender_curves.cpp
    blender_object_cull.h
  )

set(SRC2


  blender_volume.cpp
  blender_particles.cpp


  blender_python.cpp


)


set(LIB
  bf_intern_guardedalloc
  cycles_bvh
  #cycles_device
  cycles_graph
  #cycles_kernel
  cycles_render
  cycles_subd
  cycles_util
  ${_AEOLUS_DEVICE_NAME}
)



set(ADDON_FILES
  addon/__init__.py
  addon/engine.py
  addon/operators.py
  addon/osl.py
  addon/presets.py
  addon/properties.py
  addon/ui.py
  addon/version_update.py
)

add_definitions(${GL_DEFINITIONS})

if(WITH_CYCLES_DEVICE_OPENCL)
  add_definitions(-DWITH_OPENCL)
endif()

if(WITH_CYCLES_NETWORK)
  add_definitions(-DWITH_NETWORK)
endif()

if(WITH_MOD_FLUID)
  add_definitions(-DWITH_FLUID)
endif()

if(WITH_OPENVDB)
  add_definitions(-DWITH_OPENVDB ${OPENVDB_DEFINITIONS})
  list(APPEND INC_SYS
    ${OPENVDB_INCLUDE_DIRS}
  )
  list(APPEND LIB
    ${OPENVDB_LIBRARIES}
  )
endif()

if(WITH_OPENIMAGEDENOISE)
  add_definitions(-DWITH_OPENIMAGEDENOISE)
  list(APPEND INC_SYS
    ${OPENIMAGEDENOISE_INCLUDE_DIRS}
  )
endif()

if(WITH_EXPERIMENTAL_FEATURES)
  add_definitions(-DWITH_HAIR_NODES)
endif()




if(CREATOR_LIB)
add_definitions(-DCREATOR_LIB)
endif()



#blender_add_exe(bf_intern_cycles "${SRC}" "${INC}" "${INC_SYS}" "${LIB}")


sdk_add_package_Cuda()
  #import_boost()
  link_blender()
  
  list(APPEND INC_SYS
    ${BLENDER_INCLUDE}
    "${CMAKE_BINARY_DIR}/libAeolusOptix/src"
  )

  message(STATUS   "INCLUDE Intern===========BLENDER_INCLUDE======================== ${BLENDER_INCLUDE} " )
   message(STATUS   "INCLUDE Intern===========INC========================${INC}" )
      message(STATUS   "INCLUDE Intern===========INC_SYS ========================${INC_SYS}" )

  blender_add_lib(bf_intern_cycles "${SRC}" "${INC}" "${INC_SYS}" "${LIB}")
 target_link_libraries(bf_intern_cycles PUBLIC ${BLENDER_LIBS}   ) # ${CUDA_LIBRARIES})

# avoid link failure with clang 3.4 debug
if(CMAKE_C_COMPILER_ID MATCHES "Clang" AND NOT ${CMAKE_C_COMPILER_VERSION} VERSION_LESS '3.4')
  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -gline-tables-only")
endif()

#add_dependencies(bf_intern_cycles bf_rna)
message(" OUTPUT Delayed   ==>${CMAKE_CURRENT_SOURCE_DIR}  ${ADDON_FILES} ${CYCLES_INSTALL_PATH}")
delayed_install(${CMAKE_CURRENT_SOURCE_DIR} "${ADDON_FILES}" ${CYCLES_INSTALL_PATH})
