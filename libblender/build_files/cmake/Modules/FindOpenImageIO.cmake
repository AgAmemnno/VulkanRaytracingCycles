# - Find OpenImageIO library
# Find the native OpenImageIO includes and library
# This module defines
#  OPENIMAGEIO_INCLUDE_DIRS, where to find openimageio.h, Set when
#                            OPENIMAGEIO_INCLUDE_DIR is found.
#  OPENIMAGEIO_LIBRARIES, libraries to link against to use OpenImageIO.
#  OPENIMAGEIO_ROOT_DIR, The base directory to search for OpenImageIO.
#                        This can also be an environment variable.
#  OPENIMAGEIO_FOUND, If false, do not try to use OpenImageIO.
#  OPENIMAGEIO_PUGIXML_FOUND, Indicates whether OIIO has biltin PuguXML parser.
#  OPENIMAGEIO_IDIFF, full path to idiff application if found.
#
# also defined, but not for general use are
#  OPENIMAGEIO_LIBRARY, where to find the OpenImageIO library.

#=============================================================================
# Copyright 2011 Blender Foundation.
#
# Distributed under the OSI-approved BSD 3-Clause License,
# see accompanying file BSD-3-Clause-license.txt for details.
#=============================================================================

# If OPENIMAGEIO_ROOT_DIR was defined in the environment, use it.

get_filename_component(vcpkg  ${CMAKE_TOOLCHAIN_FILE} PATH)
get_filename_component(vcpkg  ${vcpkg} PATH)
get_filename_component(vcpkg  ${vcpkg} PATH)
set(vcpkg_installed  ${vcpkg}/installed/${VCPKG_TARGET_TRIPLET})


IF(NOT OPENIMAGEIO_ROOT_DIR)
    IF(NOT $ENV{OPENIMAGEIO_ROOT_DIR} STREQUAL "")
          SET(OPENIMAGEIO_ROOT_DIR $ENV{OPENIMAGEIO_ROOT_DIR})
    ELSE()
          IF(NOT VCPKG_TARGET_TRIPLET)
              MESSAGE(FATAL_ERROR " NOT FOUND OIIO   ")
        ENDIF()
          SET(OPENIMAGEIO_ROOT_DIR ${VCPKG_TARGET_TRIPLET})
    ENDIF()
ENDIF()












FIND_FILE(OPENIMAGEIO_IDIFF
  NAMES
    idiff
  HINTS
    ${_openimageio_SEARCH_DIRS}
  PATH_SUFFIXES
    bin
)




#INCLUDE(FindPackageHandleStandardArgs)
#FIND_PACKAGE_HANDLE_STANDARD_ARGS(OpenImageIO DEFAULT_MSG
#    OPENIMAGEIO_LIBRARY OPENIMAGEIO_INCLUDE_DIR)



SET(OPENIMAGEIO_LIBRARY "${vcpkg_installed}/debug/lib/OpenImageIO.lib" )
SET(OPENIMAGEIO_INCLUDE_DIR "${vcpkg_installed}/include" )

IF(EXISTS ${OPENIMAGEIO_INCLUDE_DIR}/OpenImageIO/pugixml.hpp)
SET(OPENIMAGEIO_PUGIXML_FOUND TRUE)
ELSE()
SET(OPENIMAGEIO_PUGIXML_FOUND FALSE)
ENDIF()



MARK_AS_ADVANCED(
  OPENIMAGEIO_INCLUDE_DIR
  OPENIMAGEIO_LIBRARY
  OPENIMAGEIO_IDIFF
)
message(STATUS "  OIIO LIBS  ${OPENIMAGEIO_PUGIXML_FOUND}  ${OPENIMAGEIO_LIBRARY}  ${OPENIMAGEIO_INCLUDE_DIR} )")

UNSET(_openimageio_SEARCH_DIRS)
