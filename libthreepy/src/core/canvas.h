#pragma once
#ifndef CANVAS_H
#define CANVAS_H

#include  <Python.h>


#include  "types.hpp"

#include "aeolus/vthreepy_const.h"
#include "aeolus/vthreepy_types.h"


///#define Log_NO_MATH
#ifdef   Log_NO_MATH
#define Log_cvs(...)
#else
#define Log_cvs(...) Log__thread(__FILE__, __LINE__, Log_FILE, __VA_ARGS__)
#endif


#include  "topics.h"
#include  "math/common.hpp"
#include  "scene/group.h"


#include "vulkan/vulkan.h"
#ifdef  ENABLED_VULKAN_OVR
#include "openvr.h"
#endif

#ifdef  LOG_NO_CVS
#define log_cvc(...)
#else
#define log_cvs(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)

#endif



struct Canvas {

	PyObject_HEAD

	uint32_t 	        id;
	uint32_t       w, h;

	Color            color;
	Topics*        topic;

	char                         name[25];
	bool    needsUpdate;
	uint32_t currScene;

	struct {

		std::atomic<bool>                                        busy;
		std::atomic<bool>                                      debut;
		bool                                                           make;
		uint32_t                                               passID;

#ifdef  ENABLED_VULKAN_OVR
		vr::VRVulkanTextureData_t               texData;
		vr::Texture_t                                     texture;
		vr::HmdVector2_t                         mouseScale;
#endif
	}state;


};


#endif