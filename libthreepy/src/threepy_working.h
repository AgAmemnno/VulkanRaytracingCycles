#pragma once
#ifndef __THREEPY_Working_H
#define __THREEPY_Working_H

#if defined(AEOLUS)
#include "pch_three.h"
#elif defined(AEOLUS_VID)
#include "working.h"
#endif




#ifdef AEOLUS
#ifdef  ENABLED_VULKAN_OVR
#include "openvr.h"
#endif


namespace gui {

	struct GUIcontext;
	struct GUIcontextVk;
	struct thumbNails {
		size_t w, h, l;
		long        id;
	};

	//typedef std::function<void(bool, bool, const vr::VREvent_t&)> ControlEventy;

	struct CallBackArgsControlEvent {
#ifdef  ENABLED_VULKAN_OVR
		const vr::VRControllerState_t* State;
#endif

		bool   submit, valid,menu;
		long   index;
		long   controlID;
		size_t  frame;
		string1  txt;
	};

	typedef CallBackArgsControlEvent cbInControlEventy;

	struct CallBackArgsOverlayEvent {
		//const vr::VRControllerState_t* State;
#ifdef  ENABLED_VULKAN_OVR
		const vr::VREvent_t* State;
#endif
		bool   submit, valid;
		long   index;

	};

	typedef CallBackArgsOverlayEvent cbInOverlayEventy;

	typedef std::function<void(cbInControlEventy&)> ControlEventy;
	typedef std::function<void(cbInOverlayEventy&)> OverlayEventy;

};

#endif



namespace brunch {
	const   UINT    GROUP_BIT = 1;
	const   UINT    COMMAND_BIT = 2;
	const   UINT    GROUP_COMMAND_BIT = 3;
	struct listnerData {
		char     mode;
		char   brunch;
		char       num;
		char     group;
	};

	struct Mission {
		bool   menu;
		arth::eMATERIAL                        type;
		UINT                                      frontBit;
		Group                                      group[2];
		VkCommandPool                              pool;
		VkCommandBuffer                    seco[2];
		string1                                             log;
		size_t                                          count;
		size_t                                         frame;
		long                                                  ID;
		listnerData                                lisData;
#ifdef AEOLUS
		std::function<void(gui::cbInControlEventy& event,Mission* mission)> cb = nullptr;
#endif
		//void ObjectStruct3(gui::cbInControlEventy& event, brunch::Mission* mission);
		Mission() :frame(0),count(0) {
			log.reserve(512);
			lisData.mode = ' ';
		};
	};

};


#endif