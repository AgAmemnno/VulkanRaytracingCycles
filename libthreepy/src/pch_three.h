#pragma once

#ifndef   PRICON_THREE_H
#define   PRICON_THREE_H

#pragma warning(disable: 4100)

#include "Python.h"
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#include <intrin.h>

#include <crtdbg.h>
#endif




#include <cassert>
#include <algorithm> ///scene.cpp
#include <cmath>      ///math/common.cpp
#include <concepts>        ///aeolus.cpp ///CircusVk.h
#include <chrono>      ///AllocateVk

#include  <functional>    ///LoadingManager.cpp ///math/common.cpp  ///core/common.h
#include  <fstream>        ///FileLoader.cpp
#include  <iostream>   ///VkWindow.cpp ///math/common.cpp
#include  <sstream>         ///contextVK.cpp
#include "winnt.h"
#include "tchar.h"
#include "wchar.h"    ///global.cpp
#include  <stdint.h>    ///global.cpp ///Log.cpp ///VkWindow.cpp
#include  <string>    ///VkWindow.cpp
#include <stdexcept>///math/common.cpp
#include <stdio.h>       ///Log.cpp ///math/common.cpp
#include <stdarg.h>     ///Log.cpp
#include <inttypes.h>  ///Log.cpp
#include <math.h>       ///Log.cpp
#include <time.h>        ///Log.cpp


#include <unordered_map>   ///group.h
#include <map>               ///core/common.h
#include <vector>           ///contextVK.cpp ///math/common.cpp  ///core/common.h

#include <thread>           ///aeolus.cpp //AllocateVk

#ifdef  ENABLED_VULKAN_OVR 
#include <openvr.h>
#endif
#include "vulkan/vulkan.h"
#include <vulkan/vulkan_core.h>

#include "enum.hpp"
#include "types.hpp"



#include "aeolus/vthreepy_const.h"
#include "aeolus/vthreepy_types.h"

#include "util/Log0.hpp"







#endif