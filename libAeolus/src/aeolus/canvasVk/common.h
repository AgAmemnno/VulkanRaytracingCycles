#pragma once
#ifndef  CANVAS_VK_TYPES
#define  CANVAS_VK_TYPES


#include "enum.hpp"
#include "types.hpp"
#include "util/log.hpp"
#include "aeolus/incomplete.h"
#include "aeolus/groupVk/common.h"
#include "core/canvas.h"



extern PyTypeObject tp_CanvasVk;
extern int AddType_CanvasVk(PyObject* m);

typedef struct CanvasVk :Canvas {
	

	Object3D*              base;
	Iache                   iachCol;
	Iache                  iachDep;
	DescriptorVk* descVk;
	Group* group;



	CanvasVk(const char* _name);

	void setup();

	void init();

	void alloc();

	void update(Object3D* self, bool Dash);

	~CanvasVk();

	void dealloc();

	void copyColor(void* dst);



}CanvasVk;


#endif