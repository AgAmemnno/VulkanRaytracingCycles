
set(INTERN ${LIBBLENDER_BASE_DIR}/intern)
set(EXTERN ${LIBBLENDER_BASE_DIR}/extern)
link_blender()

sdk_add_package_Cuda()


set(INC
  ..
 ${INTERN}/intern/glew-mx
)

set(INC_SYS
  ${GLEW_INCLUDE_DIR}
)


message("CUDA  CONFIGURATION    inc  ${CUDA_TOOLKIT_INCLUDE}     libs   ${CUDA_LIBRARIES}    exe ${CUDA_NVCC_EXECUTABLE}  ")

if(WITH_CUDA_DYNLOAD)
  list(APPEND INC
   ${EXTERN}/cuew/include
  )
  add_definitions(-DWITH_CUDA_DYNLOAD)
  list(APPEND LIB
    extern_cuew
  )
else()
  list(APPEND INC_SYS
    ${CUDA_TOOLKIT_INCLUDE}
  )
  add_definitions(-DCYCLES_CUDA_NVCC_EXECUTABLE="${CUDA_NVCC_EXECUTABLE}")
endif()

add_definitions(${GL_DEFINITIONS})
add_definitions(-DWITH_VULKAN)
add_definitions(-DWITH_CUDA)
#add_definitions(-DWITH_OPTIX)
add_compile_options(
  "$<$<CONFIG:DEBUG>:-${MULTIMODE};-GS;-Gd;-Gm-;-Od>"
)
if(MULTIMODE STREQUAL  "MTd")
add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
endif(MULTIMODE STREQUAL  "MTd")


  set(_WARNINGS
    "/wd4200"  # zero-sized array in struct/union
  )
    warning_sup(${_WARNINGS})


set(SRC
device.cpp
device_cuda.cpp
device_memory.cpp
device_split_kernel.cpp
device_task.cpp
device_cpu.cpp
device_denoising.cpp
#device_multi.cpp
#device_opencl.cpp
#device_optix.cpp

)

set(SRC_CUDA
  cuda/device_cuda.h
  cuda/device_cuda_impl.cpp
)




set(SRC_HEADERS
device.h
device_memory.h
device_intern.h
device_split_kernel.h
device_task.h
device_utils.h
device_denoising.h
#device_network.h
)
 
list(APPEND CYCLES_LIB 
                        cycles_util 
                        cycles_bvh
                        cycles_render
                        cycles_subd
                        cycles_graph
        )


set(LIB
  ${BLENDER_LIBS}
  ${CYCLES_LIB}
 #  ${CUDA_LIBRARIES}
)






if(WITH_CYCLES_NETWORK)
  add_definitions(-DWITH_NETWORK)
    list(APPEND SRC
    device_network.cpp
  )
endif()

if(WITH_CYCLES_DEVICE_MULTI)
  add_definitions(-DWITH_MULTI)
endif()

if(WITH_OPENIMAGEDENOISE)
  add_definitions(-DWITH_OPENIMAGEDENOISE)
  add_definitions(-DOIDN_STATIC_LIB)
  list(APPEND INC_SYS
    ${OPENIMAGEDENOISE_INCLUDE_DIRS}
  )
  list(APPEND LIB
    ${OPENIMAGEDENOISE_LIBRARIES}
    ${TBB_LIBRARIES}
  )
endif()

 set(LIBCYCLES_DIR "${LIB_DIR}/libAeolusOptix/cycles")
 #set_vcpkg()
# import_boost()
  #import_oiio()

 link_directories(${LIB_DIR}/out/build/lib) 
 link_directories(${LIB_DIR}/out/build/AeolusOptixSrvProj/lib/Debug)
 include_directories(${LIBCYCLES_DIR})
include_directories(${INC} ${BLENDER_INCLUDE})
include_directories(SYSTEM ${INC_SYS})

 



add_library(aeolus_device STATIC  ${SRC}  ${SRC_CUDA}  ${SRC_HEADERS})
target_link_libraries(aeolus_device PUBLIC ${LIB} )
target_global_lib(aeolus_device) # ${_AEOLUS_LINK_DIR})


