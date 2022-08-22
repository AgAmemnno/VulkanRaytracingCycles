#include "pch_three.h"
#include "common.hpp"

static void
Sphere_dealloc(Sphere* self)
{
	Py_TYPE(self)->tp_free((PyObject*)self);
}

static int
Sphere_init(Sphere* self, PyObject* args, PyObject* kwds)
{

	Py_ssize_t n = PyTuple_Size(args);
	if (n != 2) {
		printf("Sphere ErrorArguments :: [Center,radius]\n");
		return -1;
	}

	PyObject* o;
	PyArg_ParseTuple(args, "Od", &o,&self->_radius);

	self->_center = (Vector3*)o;
	Py_INCREF((PyObject*)self->_center);

	return 0;

}


static PyObject*
Sphere_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;

	Sphere* self = NULL;


	self = (Sphere*)type->tp_alloc(type, 0);

	if (!self) goto error;
	rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;
}




static PyObject*
Sphere_getR(Sphere* self, void* closure)
{
	return PyFloat_FromFVAL(self->_radius);
}

static int
Sphere_setR(Sphere* self, PyObject* value, void* closure)
{
	self->_radius = PyFloat_AsFVAL(value);
	return 0;
}


static PyObject*
Sphere_getC(Sphere* self, void* closure)
{
	return  (PyObject*)self->_center;
}

static int
Sphere_setC(Sphere* self, PyObject* vec, void* closure)
{

	Py_INCREF(vec);
	self->_center = ((Vector3*)vec);
	return 0;
}



static PyObject*
Sphere_getCtype(Sphere* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


Sphere* Sphere::copy(Sphere* sphere) {
	for (int i = 0; i < 3;i++ ) _center->v[i] = sphere->_center->v[0];
	_radius = sphere->_radius;
	return this;
};
Sphere* Sphere::applyMatrix4(Matrix4* matrix) {
	_center->applyMatrix4(matrix);
	_radius = _radius * matrix->getMaxScaleOnAxis();
	return this;
}

static PyGetSetDef Sphere_getsetters[] = {
	{(char*)"radius", (getter)Sphere_getR, (setter)Sphere_setR,0,0},
	{(char*)"center", (getter)Sphere_getC, (setter)Sphere_setC,0,0},
	{(char*)"_", (getter)Sphere_getCtype, 0,0,0},
	{0},
};



PyTypeObject tp_Sphere = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Sphere";
	type.tp_doc = "Sphere objects";
	type.tp_basicsize = sizeof(Euler);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Sphere_new;
	type.tp_init = (initproc)Sphere_init;
	type.tp_dealloc = (destructor)Sphere_dealloc;
	type.tp_getset = Sphere_getsetters;
	return type;
}();


int AddType_Sphere(PyObject* m) {

	if (PyType_Ready(&tp_Sphere) < 0)
		return -1;

	Py_XINCREF(&tp_Sphere);
	PyModule_AddObject(m, "Sphere", (PyObject*)&tp_Sphere);
	return 0;
}