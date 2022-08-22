# First generate the manifest for tests since it will not need the dependency on the CRT.


set(BASE_DIR "${CMAKE_SOURCE_DIR}/release/windows")
get_filename_component(BINARY_DIR_P   "${CMAKE_BINARY_DIR}" PATH)
set(OUT_DIR "${CMAKE_BINARY_DIR}/libAeolusOptix")
message(" PLATFORM CONFIGURE  ${BASE_DIR} => ${OUT_DIR} ")




if(WITH_WINDOWS_BUNDLE_CRT)


#if(NOT EXISTS ${OUT_DIR}/creator.exe.manifest)
  configure_file(${BASE_DIR}/manifest/blender.exe.manifest.in ${OUT_DIR}/tests.exe.manifest @ONLY)
  set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP TRUE)
  set(CMAKE_INSTALL_UCRT_LIBRARIES TRUE)
  set(CMAKE_INSTALL_OPENMP_LIBRARIES ${WITH_OPENMP})
  include(InstallRequiredSystemLibraries)
  # Generating the manifest is a relativly expensive operation since
  # it is collecting an sha1 hash for every file required. so only do
  # this work when the libs have either changed or the manifest does
  # not exist yet.

    list(LENGTH  CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS  _len_before)
    list(REMOVE_DUPLICATES  CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS)
    list(LENGTH   CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS  _len_after)


  string(SHA1 libshash "${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}")
  set(manifest_trigger_file "${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/crt_${libshash}")

   message("  configure sha1_trigger     ${manifest_trigger_file}   CRTLIBS_nums_libs       ${_len_before}     duplicate    ${_len_after}    \n\n\n ")

  if(NOT EXISTS ${manifest_trigger_file})

     
      # Install the CRT to the blender.crt Sub folder.
    install(FILES ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS} DESTINATION  ${BINARY_DIR}/blender.crt COMPONENT Libraries)

       
    set(CRTLIBS "")
    set(VAR 0)
    foreach(lib ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS})
      get_filename_component(filename ${lib} NAME)
      file(SHA1 "${lib}" sha1_file)
      set(CRTLIBS "${CRTLIBS}    <file name=\"${filename}\" hash=\"${sha1_file}\"  hashalg=\"SHA1\" />\n")
      message("  <file name=\"${filename}\" hash=\"${sha1_file}\"  hashalg=\"SHA1\" />\n")
      MATH(EXPR VAR "${VAR}+1")
    endforeach()

    message("  configure      CRTLIBS        ${_len_after}   count    ${VAR}  \n\n\n")




    configure_file(${BASE_DIR}/manifest/blender.crt.manifest.in ${OUT_DIR}/blender.crt.manifest @ONLY)
    file(TOUCH ${manifest_trigger_file})


  install(FILES ${OUT_DIR}/blender.crt.manifest DESTINATION ${BINARY_DIR}/blender.crt)
  set(BUNDLECRT "<dependency><dependentAssembly><assemblyIdentity type=\"win32\" name=\"blender.crt\" version=\"1.0.0.0\" /></dependentAssembly></dependency>")
  configure_file(${BASE_DIR}/manifest/blender.exe.manifest.in ${OUT_DIR}/creator.exe.manifest @ONLY)
  message("Configure .In.manifest    =>           ${OUT_DIR}/creator.exe.manifest    ")

  endif()
#endif()
endif()




