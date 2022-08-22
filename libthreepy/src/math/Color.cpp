#include "pch_three.h"
#include "common.hpp"

static void
Color_dealloc(Color* self)
{
	///printf("\ndealloc Color\n");
	Py_TYPE(self)->tp_free((PyObject*)self);
}

static PyObject*
Color_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	//printf("Color  new \n");
	Color* self = NULL;
	self = (Color*)type->tp_alloc(type, 0);
	if (!self) goto error;
	rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;
}


static PyObject*
Color_getr(Color* self, void* closure)
{

	return PyFloat_FromDouble((double)self->v[0]);
}

static int
Color_setr(Color* self, PyObject* value, void* closure)
{
	self->v[0] = (float)PyFloat_AsDouble(value);
	return 0;
}


static PyObject*
Color_getg(Color* self, void* closure)
{

	return PyFloat_FromDouble((double)self->v[1]);
}

static int
Color_setg(Color* self, PyObject* value, void* closure)
{
	self->v[1] = (float)PyFloat_AsDouble(value);
	return 0;
}


static PyObject*
Color_getb(Color* self, void* closure)
{

	return PyFloat_FromDouble((double)self->v[2]);
}

static int
Color_setb(Color* self, PyObject* value, void* closure)
{
	self->v[2] = (float)PyFloat_AsDouble(value);
	return 0;
}


static PyObject*
Color_getCtype(Color* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


static int
Color_init(Color* self, PyObject* args, PyObject* kwds)
{
	if (!PyArg_ParseTuple(args, "ddd", &self->v[0], &self->v[1], &self->v[2]))return -1;
	return 0;
}

void Color::set(float _r, float _g, float _b) {
	v[0] = _r; v[1] = _g; v[2] = _b;
}
void Color::set(Color c) {
	v[0] = c.v[0]; v[1] = c.v[1]; v[2] = c.v[2];
};



Color& Color::copy(const Color& c) {
	this->set(c.v[0], c.v[1], c.v[2]);
	return *this;
};

Color& Color::multiplyScalar(_FVAL itsty) {
	for (int i = 0; i < 3; i++)v[i] *= (float)itsty;
	return *this;
};



static PyGetSetDef Color_getsetters[] = {
	{(char*)"r", (getter)Color_getr, (setter)Color_setr,0,0},
	{(char*)"g", (getter)Color_getg, (setter)Color_setg,0,0},
	{(char*)"b", (getter)Color_getb, (setter)Color_setb,0,0},
	{(char*)"_", (getter)Color_getCtype, 0,0,0},
	{0},
};




PyMethodDef Color_tp_methods[] = {
	//{"applyMatrix4", (PyCFunction)Color::applyMatrix4,  METH_VARARGS, 0},
	{0},
};


PyTypeObject tp_Color = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Color";
	type.tp_doc = "Color objects";
	type.tp_basicsize = sizeof(Color);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Color_new;
	type.tp_init = (initproc)Color_init;
	type.tp_dealloc = (destructor)Color_dealloc;
	type.tp_methods = Color_tp_methods,
		type.tp_getset = Color_getsetters;
	return type;
}();

int AddType_Color(PyObject* m) {

	if (PyType_Ready(&tp_Color) < 0)
		return -1;

	Py_XINCREF(&tp_Color);
	PyModule_AddObject(m, "Color", (PyObject*)&tp_Color);
	return 0;
}

