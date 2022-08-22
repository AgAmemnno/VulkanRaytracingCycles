#pragma once
#include "pch_three.h"
#include "scene.h"
#include "core/common.hpp"
using namespace aeo;

#define getFilmWidth(gauge,aspect) (gauge * __min( aspect, 1. ))
#define getFilmHeight(gauge,aspect) (gauge * __max( aspect, 1. ))

static uint32_t SCID =  0;


static void
Scene_dealloc(Scene* self)
{
	if (self->fog.color != nullptr)Py_DECREF(self->fog.color);

	if (self->background != nullptr) delete self->background;

	Py_TYPE(self)->tp_free((PyObject*)self);
};


static int
Scene_init(Scene* self, PyObject* args, PyObject* kwds)
{

	uint32_t type;
	PyArg_ParseTuple(args, "|k", &type);

	self->type = (arth::GEOMETRY)type;
	self->needsUpdate = true;
	return 0;
}


static PyObject*
Scene_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	//printf("<Scene>  new \n");
	Scene* self = NULL;
	self = (Scene*)type->tp_alloc(type, 0);
	if (!self) goto error;
	self->isfog = false;
	self->fog.is = 0;
	self->fog.color = nullptr;
	self->isbackground = false;
	self->background   = new BackGround;
	self->id  = SCID;
	SCID++;
	rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;

}



static PyObject*
Scene_getFogNear(Scene* self, void* closure)
{
	return  PyFloat_FromFVAL(self->fog._near);
	///return  PyFloat_FromFVAL(1.);
};


static int
Scene_setFogNear(Scene* self, PyObject* val, void* closure)
{
	self->fog._near = PyFloat_AsFVAL(val);
	return 0;
};


static PyObject*
Scene_getFogFar(Scene* self, void* closure)
{
	return  PyFloat_FromFVAL(self->fog._far);
	///return  PyFloat_FromFVAL(1.);
}

static int
Scene_setFogFar(Scene* self, PyObject* val, void* closure)
{
	self->fog._far = PyFloat_AsFVAL(val);
	return 0;
};


static PyObject*
Scene_getFogDensity(Scene* self, void* closure)
{
	return  PyFloat_FromFVAL(self->fog._density);
	///return  PyFloat_FromFVAL(1.);
}

static int
Scene_setFogDensity(Scene* self, PyObject* val, void* closure)
{
	self->fog._density  = PyFloat_AsFVAL(val);
	return 0;
};

static PyObject*
Scene_getFogColor(Scene* self, void* closure)
{
	Py_INCREF(self->fog.color);
	///printf("FOGCOLOR  refCnt  %zd    \n", self->fog.color->ob_base.ob_refcnt);
	return  (PyObject*)(self->fog.color);
};

static int
Scene_setFogColor(Scene* self, PyObject* val, void* closure)
{
	if (self->fog.color != nullptr)Py_DECREF(self->fog.color);
	self->fog.color = (Color*)val;
	Py_INCREF(val);
	return 0;
};


static PyObject*
Scene_getBGColor(Scene* self, void* closure)
{
	if (self->background->color == nullptr) Py_RETURN_NONE;
	Py_INCREF(self->background->color);
	///printf(" COLOR  refCnt  %zd    \n", self->background->color->ob_base.ob_refcnt);
	return  (PyObject*)(self->background->color);
};

static int
Scene_setBGColor(Scene* self, PyObject* val, void* closure)
{
	///printf(" setBG   \n");
	if (self->background->color != nullptr)Py_DECREF(self->background->color);
	self->background->color = (Color*)val;
	self->isbackground =  true;
	self->background->is = BG_COLOR;
	Py_INCREF(val);
	return 0;
};



PyObject*
Scene_getISFOG(Scene* self, void* closure)
{
	static bool fog = false;
	fog = false;
	if (self->isfog && self->fog.is == FOG)fog = true;
	return PyBool_FromLong(fog);
};

int
Scene_setISFOG(Scene* self, PyObject* value, void* closure)
{
	self->isfog = (PyLong_AsLong(value) == 0) ? false : true;
	if (self->isfog)self->fog.is = FOG;

	return 0;
};

PyObject*
Scene_getBGis(Scene* self, void* closure)
{
	return PyLong_FromLong((long)self->background->is);
};


PyObject*
Scene_getISFOGEXP2(Scene* self, void* closure)
{
	static bool fog = false;
	fog = false;
	if (self->isfog && self->fog.is == FOGexp2)fog = true;
	return PyBool_FromLong(fog);

};

int
Scene_setISFOGExp2(Scene* self, PyObject* value, void* closure)
{
	self->isfog = (PyLong_AsLong(value) == 0) ? false : true;
	if (self->isfog)self->fog.is = FOGexp2;

	return 0;
};



static PyObject*
Scene_getCtype(Scene* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}



static PyGetSetDef Scene_getsetters[] = {
	 {(char*)"isfog", (getter)Scene_getISFOG, (setter)Scene_setISFOG,0,0},
	  {(char*)"isfogExp2", (getter)Scene_getISFOGEXP2, (setter)Scene_setISFOGExp2,0,0},
	 {(char*)"fog_far", (getter)Scene_getFogFar, (setter)Scene_setFogFar,0,0},
	 {(char*)"fog_near", (getter)Scene_getFogNear, (setter)Scene_setFogNear,0,0},
	  {(char*)"fog_density", (getter)Scene_getFogDensity, (setter)Scene_setFogDensity,0,0},
	{(char*)"fog_color", (getter)Scene_getFogColor, (setter)Scene_setFogColor,0,0},
	 {(char*)"bg_color", (getter)Scene_getBGColor, (setter)Scene_setBGColor,0,0},
	  {(char*)"bg_is", (getter)Scene_getBGis, 0,0,0},
	 {(char*)"_Scene", (getter)Scene_getCtype, 0,0,0},
	{0},
};


PyMethodDef Scene_tp_methods[] = {
	{0},
};

PyTypeObject tp_Scene = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Scene";
	type.tp_doc = "Scene objects";
	type.tp_basicsize = sizeof(Scene);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Scene_new;
	type.tp_init = (initproc)Scene_init;
	type.tp_methods = Scene_tp_methods;
	type.tp_dealloc = (destructor)Scene_dealloc;
	type.tp_getset = Scene_getsetters;
	return type;
}();

int AddType_Scene(PyObject* m) {

	if (PyType_Ready(&tp_Scene) < 0)
		return -1;

	Py_XINCREF(&tp_Scene);
	PyModule_AddObject(m, "Scene", (PyObject*)&tp_Scene);
	return 0;
}

