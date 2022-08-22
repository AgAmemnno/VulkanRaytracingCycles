#include "pch_three.h"
#include "common.hpp"

static void
Plane_dealloc(Plane* self)
{
	Py_TYPE(self)->tp_free((PyObject*)self);
}

static int
Plane_init(Plane* self, PyObject* args, PyObject* kwds)
{

	Py_ssize_t n = PyTuple_Size(args);
	if (n != 2) {
		printf("Plane ErrorArguments :: [Normal,constants]\n");
		return -1;
	}

	PyObject* o;
	PyArg_ParseTuple(args, "Od", &o, &self->_constant);

	self->_normal = (Vector3*)o;
	Py_INCREF((PyObject*)self->_normal);

	return 0;

}


static PyObject*
Plane_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;

	Plane* self = NULL;


	self = (Plane*)type->tp_alloc(type, 0);

	if (!self) goto error;
	rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;
}


Plane* Plane::setComponents(_FVAL x, _FVAL y, _FVAL z, _FVAL w) {
	_normal->v[0] = x;
	_normal->v[1] = y;
	_normal->v[2] = z;
	//printVector3("plane", _normal->v);
	_constant = w;
	return this;
};


Plane* Plane::normalize() {
	
	
	//printf("const  %Lf  length  %Lf \n", _constant, _normal->length());
	_FVAL inverseNormalLength = 1.0 / _normal->length();
	for (int i = 0; i < 3; i++)_normal->v[i] *= (inverseNormalLength);

	_constant *= inverseNormalLength;
	
	//printf("const  %Lf  length %Lf  \n", _constant, inverseNormalLength);
	return this;
};


static PyObject*
Plane_getConst(Plane* self, void* closure)
{
	return PyFloat_FromFVAL(self->_constant);
}

static int
Plane_setConst(Plane* self, PyObject* value, void* closure)
{
	self->_constant = PyFloat_AsFVAL(value);
	return 0;
}


static PyObject*
Plane_getNorm(Plane* self, void* closure)
{
	return  (PyObject*)self->_normal;
}


static int
Plane_setNorm(Plane* self, PyObject* vec, void* closure)
{

	Py_INCREF(vec);
	self->_normal = ((Vector3*)vec);
	return 0;
}


static PyObject*
Plane_getCtype(Plane* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


static PyGetSetDef Plane_getsetters[] = {
	{(char*)"constant", (getter)Plane_getConst, (setter)Plane_setConst,0,0},
	{(char*)"_normal", (getter)Plane_getNorm, (setter)Plane_setNorm,0,0},
	{(char*)"_", (getter)Plane_getCtype, 0,0,0},
	{0},
};

_FVAL Plane::distanceToPoint(Vector3* point) {
	return _normal->dot(point) + _constant;
};




PyTypeObject tp_Plane = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Plane";
	type.tp_doc = "Plane objects";
	type.tp_basicsize = sizeof(Euler);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Plane_new;
	type.tp_init = (initproc)Plane_init;
	type.tp_dealloc = (destructor)Plane_dealloc;
	type.tp_getset = Plane_getsetters;
	return type;
}();


int AddType_Plane(PyObject* m) {

	if (PyType_Ready(&tp_Plane) < 0)
		return -1;

	Py_XINCREF(&tp_Plane);
	PyModule_AddObject(m, "Plane", (PyObject*)&tp_Plane);
	return 0;
}