
set(INC
  ..
)

set(INC_SYS

)

set(SRC
  subd_dice.cpp
  subd_patch.cpp
  subd_split.cpp
  subd_patch_table.cpp
)

set(SRC_HEADERS
  subd_dice.h
  subd_patch.h
  subd_patch_table.h
  subd_split.h
  subd_subpatch.h
)
include_directories( ${LIB_DIR}/libAeolusOptix/aeolus_device)

set(LIB
 aeolus_device
)

include_directories(${INC})
include_directories(SYSTEM ${INC_SYS})

cycles_add_library(cycles_subd "${LIB}" ${SRC} ${SRC_HEADERS})
target_global_lib(cycles_subd ) # ${_AEOLUS_LINK_DIR})