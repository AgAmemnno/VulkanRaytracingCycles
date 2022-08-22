#pragma once

#ifndef  TOPICS_H
#define TOPICS_H

#include "Python.h"

#include "enum.hpp"
#include "types.hpp"
#include "math/common.hpp"


#include <mutex>
#include <concepts>

#include <future>
#ifdef  ENABLED_VULKAN_OVR 
#include "openvr.h"
#endif







struct Topics {
	
	PyObject_HEAD
	arth::TOPICS    type;
#ifdef  ENABLED_VULKAN_OVR 
	vr::VROverlayHandle_t      Main;
	vr::VROverlayHandle_t      Logo;
	vr::HmdMatrix34_t     Transform;
	vr::IVROverlay* OVov;
	void update(Object3D* self, vr::Texture_t* texture);
#endif
	struct {
		uint32_t                 INIT;
		uint32_t                 CACHE;
	} FLAG;

	uint32_t fuid = 2;

	bool                     visible;
	bool                       show = false;
	bool                       dash;
	bool                    rmodel;
	uint32_t         deviceID;
	int32_t     visible_mode;
	float                    width;

	std::string   title;
	std::string    tip;




	std::future<void>     cap;

	void init(uint32_t did = 0);

	void update(Object3D* self, bool Dash);
	float transform1(Object3D* self, Object3D* head, Object3D* hand);
	void getRotationToPoint(Vector3* f_pointA, Vector3* f_pointB, Quaternion* f_rotationA, Quaternion* f_result);

};


int AddType_Topics(PyObject* m);
int AddType_TOPICS(PyObject* m);


#endif