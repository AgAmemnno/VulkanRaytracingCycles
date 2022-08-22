#pragma once
#ifndef __THREEPY_H
#define __THREEPY_H

#include "enum.hpp"

#include "math/common.hpp"
#include "core/common.hpp"


#include "loader/Loader.h"


#ifdef AEOLUS
#include "core/canvas.h"
#include "core/topics.h"

#endif

#include "scene/scene.h"
#include "scene/group.h"

#ifdef AEOLUS
#include "materials/common.hpp"
#endif


#include "camera/_camera.hpp"



#endif

/*

#pragma warning(disable : 4201)   /// UNION  anonymus definition
int AddType_ColorPy(PyObject* m);
typedef struct ColorPy {
	PyObject_HEAD
     union {
		float v[3];
		struct {
			float r, g, b;
		};
	};

	void repr();

} ColorPy;

void fnlibthreepy(ColorPy& a);

void testcb_B_I(int a);
#pragma warning(default : 4201)
*/
