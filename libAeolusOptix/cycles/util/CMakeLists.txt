

  #import_oiio()

set(INC
     ..
    ${LIBBLENDER_BASE_DIR}/intern/glew-mx
    ${LIBBLENDER_BASE_DIR}/intern/atomic
    ${LIBBLENDER_BASE_DIR}/intern/numaapi/include
)

set(INC_SYS
  #${OPENIMAGEIO_INCLUDE_DIR}
  #${GLEW_INCLUDE_DIR}
)

set(SRC
  util_aligned_malloc.cpp
  util_debug.cpp
  util_debug2.cpp
  util_ies.cpp
  util_logging.cpp
  util_math_cdf.cpp
  util_md5.cpp
  util_murmurhash.cpp
  util_path.cpp
  util_profiling.cpp
  util_string.cpp
  util_simd.cpp
  util_system.cpp
  util_task.cpp
  util_thread.cpp
  util_time.cpp
  util_transform.cpp
  util_windows.cpp
)



if(WITH_CYCLES_STANDALONE)
  if(WITH_CYCLES_STANDALONE_GUI)
    list(APPEND SRC
      util_view.cpp
    )
  endif()
endif()

if(CYCLES_STANDALONE_REPOSITORY)
  list(APPEND INC_SYS
    ../../third_party/numaapi/include
  )
else()
  list(APPEND INC_SYS
     ${LIBBLENDER_BASE_DIR}/intern/numaapi/include
  )
endif()

set(SRC_HEADERS
  util_algorithm.h
  util_aligned_malloc.h
  util_args.h
  util_array.h
  util_atomic.h
  util_boundbox.h
  util_debug.h
  util_debug2.h
  util_defines.h
  util_deque.h
  util_disjoint_set.h
  util_guarded_allocator.cpp
  util_foreach.h
  util_function.h
  util_guarded_allocator.h
  util_half.h
  util_hash.h
  util_ies.h
  util_image.h
  util_image_impl.h
  util_list.h
  util_logging.h
  util_map.h
  util_math.h
  util_math_cdf.h
  util_math_fast.h
  util_math_intersect.h
  util_math_float2.h
  util_math_float3.h
  util_math_float4.h
  util_math_int2.h
  util_math_int3.h
  util_math_int4.h
  util_math_matrix.h
  util_md5.h
  util_murmurhash.h
  util_openimagedenoise.h
  util_opengl.h
  util_openvdb.h
  util_optimization.h
  util_param.h
  util_path.h
  util_profiling.h
  util_progress.h
  util_projection.h
  util_queue.h
  util_rect.h
  util_set.h
  util_simd.h
  util_avxf.h
  util_avxb.h
  util_avxi.h
  util_semaphore.h
  util_sseb.h
  util_ssef.h
  util_ssei.h
  util_stack_allocator.h
  util_static_assert.h
  util_stats.h
  util_string.h
  util_system.h
  util_task.h
  util_tbb.h
  util_texture.h
  util_thread.h
  util_time.h
  util_transform.h
  util_types.h
  util_types_float2.h
  util_types_float2_impl.h
  util_types_float3.h
  util_types_float3_impl.h
  util_types_float4.h
  util_types_float4_impl.h
  util_types_float8.h
  util_types_float8_impl.h
  util_types_int2.h
  util_types_int2_impl.h
  util_types_int3.h
  util_types_int3_impl.h
  util_types_int4.h
  util_types_int4_impl.h
  util_types_uchar2.h
  util_types_uchar2_impl.h
  util_types_uchar3.h
  util_types_uchar3_impl.h
  util_types_uchar4.h
  util_types_uchar4_impl.h
  util_types_uint2.h
  util_types_uint2_impl.h
  util_types_uint3.h
  util_types_uint3_impl.h
  util_types_uint4.h
  util_types_uint4_impl.h
  util_types_ushort4.h
  util_types_vector3.h
  util_types_vector3_impl.h
  util_unique_ptr.h
  util_vector.h
  util_version.h
  util_view.h
  util_windows.h
  util_xml.h
)



include_directories(${INC})

set(LIB
     OpenImageIO::OpenImageIO
     OpenImageIO::OpenImageIO_Util
)
cycles_add_library(cycles_util "${LIB}" ${SRC} ${SRC_HEADERS})
target_global_lib(cycles_util ) # ${_AEOLUS_LINK_DIR})



