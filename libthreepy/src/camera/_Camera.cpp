#pragma once
#include "pch_three.h"
#include "_camera.hpp"
#include "core/common.hpp"

const _FVAL DEG2RAD = M_PI / 180.;
const _FVAL RAD2DEG = 180. / M_PI;
#define getFilmWidth(gauge,aspect) (gauge * __min( aspect, 1. ))
#define getFilmHeight(gauge,aspect) (gauge * __max( aspect, 1. ))

struct viewObj{
	bool enabled;
	_FVAL fullWidth = 1;
		_FVAL fullHeight = 1;
		_FVAL offsetX = 0;
		_FVAL offsetY = 0;
		_FVAL width = 1;
		_FVAL height = 1;
};

void _Camera::updateMatrixWorld(bool force) {
	obj3d->updateMatrixWorld(force);
	printMatrix4("updateCamera", obj3d->matrixWorld->elements);
	matrixWorldInverse->getInverse(obj3d->matrixWorld, false);
};

void _Camera::updateProjectionMatrix() {

	static _FVAL  _near, top, height, width, left, skew;
	static  viewObj view;
	static _FVAL filmGauge = 35;	// width of the film (default in millimeters)
	static _FVAL filmOffset = 0;	// horizontal film offset (same unit as gauge)

	_near = __near, top = _near * tan(DEG2RAD * 0.5 * __fov) / __zoom, height = 2 * top, width = __aspect * height,
		left = -0.5 * width;

	if (__view != NULL && view.enabled) {
		static _FVAL    fullWidth, fullHeight;
		fullWidth = view.fullWidth,
			fullHeight = view.fullHeight;
		left += view.offsetX * width / fullWidth;
		top -= view.offsetY * height / fullHeight;
		width *= view.width / fullWidth;
		height *= view.height / fullHeight;
	}


	skew = filmOffset;
	if (skew != 0) left += _near * skew / getFilmWidth(filmGauge, __aspect);

	projectionMatrix->makePerspective(left, left + width, top, top - height, _near, __far);

	projectionMatrixInverse->getInverse(projectionMatrix,true);

};

_Camera::_Camera() :__near(0.01), __far(1000.) {
	obj3d = new Object3D;
	matrixWorldInverse = new Matrix4;
	projectionMatrix = new Matrix4;
	projectionMatrixInverse = new Matrix4;
};
_Camera::~_Camera() {
	if (obj3d != nullptr)delete obj3d;
	if (matrixWorldInverse != nullptr)delete matrixWorldInverse;
	if (projectionMatrix != nullptr)delete projectionMatrix;
	if (projectionMatrixInverse != nullptr)delete projectionMatrixInverse;
};


static void
Camera_dealloc(_Camera* self)
{

	if (self->obj3d != NULL) Py_DECREF((PyObject*)self->obj3d);
	if (self->matrixWorldInverse != NULL) Py_DECREF((PyObject*)self->matrixWorldInverse);
	if (self->projectionMatrix != NULL) Py_DECREF((PyObject*)self->projectionMatrix);
	if (self->projectionMatrixInverse != NULL) Py_DECREF((PyObject*)self->projectionMatrixInverse);

	Py_TYPE(self)->tp_free((PyObject*)self);
};


static int
Camera_init(_Camera* self, PyObject* args, PyObject* kwds)
{
	char* str;
	if (!PyArg_ParseTuple(args, "s", &str))return -1;
	self->__view = NULL;
	return 0;
}


static PyObject*
Camera_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	//printf("<Camera>  new \n");
	_Camera* self = NULL;
	self = (_Camera*)type->tp_alloc(type, 0);
	if (!self) goto error;

    rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;

}


static PyObject*
Camera_getObject3D(_Camera* self, void* closure)
{
	return  (PyObject*)self->obj3d;
}

static int
Camera_setObject3D(_Camera* self, PyObject* mat, void* closure)
{
	Py_INCREF(mat);
	self->obj3d = ((Object3D*)mat);
	return 0;
};


static PyObject*
Camera_getMatrixWorldInverse(_Camera* self, void* closure)
{
	return  (PyObject*)self->matrixWorldInverse;
}
static int
Camera_setMatrixWorldInverse(_Camera* self, PyObject* mat, void* closure)
{
	Py_INCREF(mat);
	self->matrixWorldInverse = ((Matrix4*)mat);
	return 0;
};

static PyObject*
Camera_getProjectionMatrix(_Camera* self, void* closure)
{
	return  (PyObject*)self->projectionMatrix;
};

static int
Camera_setProjectionMatrix(_Camera* self, PyObject* mat, void* closure)
{
	Py_INCREF(mat);
	self->projectionMatrix = ((Matrix4*)mat);
	return 0;
};

static PyObject*
Camera_getProjectionMatrixInverse(_Camera* self, void* closure)
{
	return  (PyObject*)self->projectionMatrixInverse;
};
static int
Camera_setProjectionMatrixInverse(_Camera* self, PyObject* mat, void* closure)
{
	Py_INCREF(mat);
	self->projectionMatrixInverse = ((Matrix4*)mat);
	return 0;
};

static PyObject*
Camera_getNear(_Camera* self, void* closure)
{
	return  PyFloat_FromFVAL(self->__near);
	///return  PyFloat_FromFVAL(1.);
};


static int
Camera_setNear(_Camera* self, PyObject* val, void* closure)
{
	self->__near = PyFloat_AsFVAL(val);
	return 0;
};


static PyObject*
Camera_getFar(_Camera* self, void* closure)
{
	return  PyFloat_FromFVAL(self->__far);
	///return  PyFloat_FromFVAL(1.);
}

static int
Camera_setFar(_Camera* self, PyObject* val, void* closure)
{
	self->__far = PyFloat_AsFVAL(val);
	return 0;
};


static PyObject*
Camera_getFov(_Camera* self, void* closure)
{
	return  PyFloat_FromFVAL(self->__fov);
	///return  PyFloat_FromFVAL(1.);
}

static int
Camera_setFov(_Camera* self, PyObject* val, void* closure)
{
	self->__fov = PyFloat_AsFVAL(val);
	return 0;
};

static PyObject*
Camera_getAspect(_Camera* self, void* closure)
{
	return  PyFloat_FromFVAL(self->__aspect);
	///return  PyFloat_FromFVAL(1.);
}

static int
Camera_setAspect(_Camera* self, PyObject* val, void* closure)
{
	self->__aspect = PyFloat_AsFVAL(val);
	return 0;
};


static PyObject*
Camera_getZoom(_Camera* self, void* closure)
{
	return  PyFloat_FromFVAL(self->__zoom);
	///return  PyFloat_FromFVAL(1.);
}

static int
Camera_setZoom(_Camera* self, PyObject* val, void* closure)
{
	self->__zoom = PyFloat_AsFVAL(val);
	return 0;
};

static PyObject*
Camera_getView(_Camera* self, void* closure)
{
	return  PyFloat_FromFVAL(self->__view);
	///return  PyFloat_FromFVAL(1.);
}

static int
Camera_setView(_Camera* self, PyObject* val, void* closure)
{
	self->__view = NULL;/// PyFloat_AsFVAL(val);
	return 0;
};



static PyObject*
Camera_getIsOrthographicCamera(_Camera* self, void* closure)
{
	return  PyBool_FromLong((long)self->isOrthographicCamera);
	///return  PyFloat_FromFVAL(1.);
}

static int
Camera_setIsOrthographicCamera(_Camera* self, PyObject* val, void* closure)
{
	self->isOrthographicCamera =  (bool)PyLong_AsLong(val);
	return 0;
};




static PyObject*
Camera_getCtype(_Camera* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}



static PyGetSetDef Camera_getsetters[] = {
	{(char*)"_matrixWorldInverse", (getter)Camera_getMatrixWorldInverse, (setter)Camera_setMatrixWorldInverse,0,0},
	{(char*)"_projectionMatrix", (getter)Camera_getProjectionMatrix, (setter)Camera_setProjectionMatrix,0,0},
	{(char*)"_projectionMatrixInverse", (getter)Camera_getProjectionMatrixInverse, (setter)Camera_setProjectionMatrixInverse,0,0},
	{(char*)"isOrthographicCamera", (getter)Camera_getIsOrthographicCamera, (setter)Camera_setIsOrthographicCamera,0,0},
	 {(char*)"far", (getter)Camera_getFar, (setter)Camera_setFar,0,0},
	  {(char*)"near", (getter)Camera_getNear, (setter)Camera_setNear,0,0},
	   {(char*)"fov", (getter)Camera_getFov, (setter)Camera_setFov,0,0},
	  {(char*)"aspect", (getter)Camera_getAspect, (setter)Camera_setAspect,0,0},
		{(char*)"zoom", (getter)Camera_getZoom, (setter)Camera_setZoom,0,0},
			{(char*)"view", (getter)Camera_getView, (setter)Camera_setView,0,0},
    {(char*)"_obj3d", (getter)Camera_getObject3D, (setter)Camera_setObject3D,0,0},
	{(char*)"_camera", (getter)Camera_getCtype, 0,0,0},
	{0},
};


PyMethodDef Camera_tp_methods[] = {
	{0},
};

PyTypeObject tp_Camera = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Camera";
	type.tp_doc = "Camera objects";
	type.tp_basicsize = sizeof(_Camera);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Camera_new;
	type.tp_init = (initproc)Camera_init;
	type.tp_methods = Camera_tp_methods;
	type.tp_dealloc = (destructor)Camera_dealloc;
	type.tp_getset = Camera_getsetters;
	return type;
}();

int AddType_Camera(PyObject* m) {

	if (PyType_Ready(&tp_Camera) < 0)
		return -1;

	Py_XINCREF(&tp_Camera);
	PyModule_AddObject(m, "Camera", (PyObject*)&tp_Camera);
	return 0;
}

