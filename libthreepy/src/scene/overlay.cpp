#pragma once
#include "pch_three.h"
#include "scene.h"
#include "core/common.hpp"

uint32_t AxisHash::getID(float x, float y) {
	uint32_t  p = uint32_t(round(scale * (round(scale * x) + y)));
	if (Grid.count(p) > 0)return Grid[p];
	return uint32_t(-1);
};

static void
Overlay_dealloc(Overlay* self)
{
	delete self->axis;
	Py_TYPE(self)->tp_free((PyObject*)self);
};

static int
Overlay_init(Overlay* self, PyObject* args, PyObject* kwds)
{
	return 0;
}

static PyObject*
Overlay_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	//printf("<Overlay>  new \n");
	Overlay* self = NULL;
	self = (Overlay*)type->tp_alloc(type, 0);
	if (!self) goto error;
	rc = 0;
	self->axis = new AxisHash;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;
}

static int
Overlay_setRatio(Overlay* self, PyObject* val, void* closure)
{
	self->axis->scale = (float)PyFloat_AsFVAL(val);
	return 0;
};

static PyGetSetDef Overlay_getsetters[] = {
	{(char*)"ratio", 0,(setter)Overlay_setRatio,0,0},
	{0},
};

static PyObject*
Overlay_setGrid(Overlay* self, PyObject* args)
{
	uint32_t f;
	uint32_t id;
	PyArg_ParseTuple(args, "kk", &f, &id);
	self->axis->Grid[f] = id;

	Py_RETURN_NONE;

};

PyMethodDef Overlay_tp_methods[] = {
	{"grid", (PyCFunction)Overlay_setGrid, METH_VARARGS, 0},
	{0},
};

PyTypeObject tp_Overlay = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Overlay";
	type.tp_doc = "Overlay objects";
	type.tp_basicsize = sizeof(Overlay);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Overlay_new;
	type.tp_init = (initproc)Overlay_init;
	type.tp_methods = Overlay_tp_methods;
	type.tp_dealloc = (destructor)Overlay_dealloc;
	type.tp_getset = Overlay_getsetters;
	return type;
}();

int AddType_Overlay(PyObject* m) {

	if (PyType_Ready(&tp_Overlay) < 0)
		return -1;

	Py_XINCREF(&tp_Overlay);
	PyModule_AddObject(m, "Overlay", (PyObject*)&tp_Overlay);
	return 0;
}
