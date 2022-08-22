

add_definitions(-D__LITTLE_ENDIAN__)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/extern/gtest ${BINARY_DIR}/extern/gtest)

add_subdirectory(${LIBBLENDER_BASE_DIR}/intern/numaapi ${BINARY_DIR}/intern/numaapi)
add_subdirectory(${LIBBLENDER_BASE_DIR}/intern/sky ${BINARY_DIR}/intern/sky)
 set(WITH_CXX_GUARDEDALLOC OFF)
 set(WITH_GTESTS OFF)
add_subdirectory(${LIBBLENDER_BASE_DIR}/intern/guardedalloc ${BINARY_DIR}/intern/guardedalloc)

 set(WITH_GTESTS ON)

#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/windowmanager ${BINARY_DIR}/windowmanager)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/editors/interface  ${BINARY_DIR}/editors/interface)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/editors/space_api  ${BINARY_DIR}/editors/space_api)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/editors/space_node  ${BINARY_DIR}/editors/space_node)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/editors/mesh  ${BINARY_DIR}/editors/mesh)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/editors/screen  ${BINARY_DIR}/editors/screen)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/draw  ${BINARY_DIR}/draw)
#add_subdirectory(${LIBBLENDER_BASE_DIR}/source/blender/blenkernel  ${BINARY_DIR}/blenkernel)