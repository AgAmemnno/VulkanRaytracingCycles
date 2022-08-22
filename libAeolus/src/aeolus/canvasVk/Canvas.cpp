#pragma once
#include  "pch.h"
#include "working.h"

#ifndef DEB

#include "aeolus/groupVk/common.h"
#include "core/topics.h"
#include "aeolus/canvasVk/common.h"



static size_t CanvasVk_STAMP = types::stollu_rand(__FILE__  __TIME__);
#define CanvasVk_RESTAMP CanvasVk_STAMP  = types::stollu_rand(__FILE__ __TIME__);
static  uint32_t CVSID = 0;

static void
CanvasVk_dealloc(CanvasVk* self)
{
	self->dealloc();
	Py_TYPE(self)->tp_free((PyObject*)self);
};


static int
CanvasVk_init(CanvasVk* self, PyObject* args, PyObject* kwds)
{

	uint32_t w, h;
	char* name;
	PyArg_ParseTuple(args, "kks", &w, &h, &name);

	self->h = h;
	self->w = w;

	memcpy(self->name, name, strlen(name));
	printf("CanvasVk Name %s   \n", self->name);
	self->setup();

	self->alloc();
	return 0; 

};


static PyObject*
CanvasVk_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	printf("<CanvasVk>  new \n");
	CanvasVk* self = NULL;
	self = (CanvasVk*)type->tp_alloc(type, 0);
	if (!self) goto error;

	rc = 0;
error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;

}


static PyObject*
CanvasVk_getBase(CanvasVk* self, void* closure)
{
	//Py_INCREF( (PyObject *) self);

	if (self->base == nullptr) Py_RETURN_NONE;
	return  (PyObject*)self->base;
}

static int
CanvasVk_setBase(CanvasVk* self, PyObject* vec, void* closure)
{
	log_cvs("CanvasVk setBase Object3D   %x  \n", vec);
	//Py_INCREF(vec);
	self->base = ((Object3D*)vec);
	return 0;

}

static PyObject*
CanvasVk_getTopic(CanvasVk* self, void* closure)
{
	//Py_INCREF( (PyObject *) self);

	if (self->topic == nullptr) Py_RETURN_NONE;
	return  (PyObject*)self->topic;
}

static int
CanvasVk_setTopic(CanvasVk* self, PyObject* vec, void* closure)
{
	log_cvs("CanvasVk setTopic   %x  \n", vec);
	Py_INCREF(vec);
	self->topic = ((Topics*)vec);
	self->needsUpdate = true;
	return 0;

}


static PyObject*
CanvasVk_getCURRSCENE(CanvasVk* self, void* closure)
{
	//Py_INCREF( (PyObject *) self);
	return  (PyObject*)PyLong_FromLong(self->currScene);
}


static int
CanvasVk_setCURRSCENE(CanvasVk* self, PyObject* vec, void* closure)
{
	self->currScene = PyLong_AsUnsignedLong(vec);
	return 0;

}

static PyGetSetDef CanvasVk_getsetters[] = {
	 {(char*)"currScene", (getter)CanvasVk_getCURRSCENE, (setter)CanvasVk_setCURRSCENE,0,0},
	 {(char*)"topic", (getter)CanvasVk_getTopic, (setter)CanvasVk_setTopic,0,0},
	  {(char*)"base", (getter)CanvasVk_getBase, (setter)CanvasVk_setBase,0,0},
	{0},
};

static PyObject*
CanvasVk_setGrid(CanvasVk* self, PyObject* args)
{
	Py_RETURN_NONE;

};

static PyObject*
CanvasVk_addGroup(CanvasVk* self, PyObject* args)
{
	if PyGroup_CheckExact(args) {

		Py_INCREF(args);
		self->group = (Group*)args;
		log_once(" CanvasVk  Group Add %x  \n", self->group);

	};
	
	Py_RETURN_NONE;

};

static PyObject*
CanvasVk_setBrunch(CanvasVk* self, PyObject* args)
{

	self->base->Type.ID = PyLong_AsLong(args);
	Py_RETURN_NONE;

};


PyMethodDef CanvasVk_tp_methods[] = {
	{"setBrunch", (PyCFunction)CanvasVk_setBrunch, METH_O, 0},
	{"addGroup", (PyCFunction)CanvasVk_addGroup, METH_O, 0},
	{"grid", (PyCFunction)CanvasVk_setGrid, METH_VARARGS, 0},
	{0},
};

PyTypeObject tp_CanvasVk = []() -> PyTypeObject {

	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.CanvasVk";
	type.tp_doc = "CanvasVk objects";
	type.tp_basicsize = sizeof(CanvasVk);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = CanvasVk_new;
	type.tp_init = (initproc)CanvasVk_init;
	type.tp_methods = CanvasVk_tp_methods;
	type.tp_dealloc = (destructor)CanvasVk_dealloc;
	type.tp_getset = CanvasVk_getsetters;
	return type;

}();

int AddType_CanvasVk(PyObject* m) {

	if (PyType_Ready(&tp_CanvasVk) < 0)
		return -1;
	Py_XINCREF(&tp_CanvasVk);
	PyModule_AddObject(m, "Canvas", (PyObject*)&tp_CanvasVk);
	return 0;
}


CanvasVk::CanvasVk(const char* _name) {

	memcpy(name, _name, strlen(_name));
	setup();

};

void CanvasVk::setup() {

	CVSID++;
	id = CVSID;
	needsUpdate = false;
	currScene = 0;
	state.make = false;
	
	iachCol = Iache::rehash(name, CanvasVk_STAMP);
	iachDep = Iache::rehash(std::string(name) + "depth", CanvasVk_STAMP);
	topic     = nullptr;
	group    = nullptr;
	descVk = nullptr;
	base     = nullptr;
	log_cvs("CanvasVk Create   %u   %u   name  %s  hash  %x   %x  \n", w, h, name,iachCol.hash, iachDep.hash);

};

void CanvasVk::alloc() {
	descVk = new DescriptorVk;
};

void CanvasVk::init() {
	if (topic != nullptr) {
		topic->init();
	};
};

void CanvasVk::update(Object3D* self, bool Dash) {

	if (topic != nullptr) {

		///log_top("  Topics needsUpadte [%x]   dash  %x Dash %x  \n", needsUpdate, topic->dash,Dash);
	
		if (needsUpdate) {
			topic->update(self, &state.texture);
		};
	
	}
}

CanvasVk::~CanvasVk() {
	dealloc();
};

void CanvasVk::dealloc() {

	__Delete__(descVk);
	__Decrement__(topic);
	__Decrement__(group);
	///__Decrement__(base);

};

void CanvasVk::copyColor(void* dst) {
	memcpy(dst, color.v, 4 * 3);
};


#endif