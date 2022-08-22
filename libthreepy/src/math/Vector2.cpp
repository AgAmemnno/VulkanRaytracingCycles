#include "pch_three.h"
#include "common.hpp"

static void
Vector2_dealloc(Vector2* self)
{
	//printf("\ndealloc Vector2\n");
	Py_TYPE(self)->tp_free((PyObject*)self);
}

static PyObject*
Vector2_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	//printf("Vector2  new \n");
	Vector2* self = NULL;
	self = (Vector2*)type->tp_alloc(type, 0);
	if (!self) goto error;
	rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;
}


static PyObject*
Vector2_getx(Vector2* self, void* closure)
{

	return PyFloat_FromFVAL(self->v[0]);
}

static int
Vector2_setx(Vector2* self, PyObject* value, void* closure)
{
	self->v[0] = PyFloat_AsFVAL(value);
	return 0;
}


static PyObject*
Vector2_gety(Vector2* self, void* closure)
{
	return PyFloat_FromFVAL(self->v[1]);
}

static int
Vector2_sety(Vector2* self, PyObject* value, void* closure)
{
	self->v[1] = PyFloat_AsFVAL(value);
	return 0;
}



static PyObject*
Vector2_getCtype(Vector2* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


static int
Vector2_init(Vector2* self, PyObject* args, PyObject* kwds)
{
	if (!PyArg_ParseTuple(args, "dd", &self->v[0], &self->v[1]))return -1;

	return 0;
}

static PyGetSetDef Vector2_getsetters[] = {
	{(char*)"x", (getter)Vector2_getx, (setter)Vector2_setx,0,0},
	{(char*)"y", (getter)Vector2_gety, (setter)Vector2_sety,0,0},
	{(char*)"width", (getter)Vector2_getx, (setter)Vector2_setx,0,0},
	{(char*)"height", (getter)Vector2_gety, (setter)Vector2_sety,0,0},
	{(char*)"_", (getter)Vector2_getCtype, 0,0,0},
	{0},
};

/*
Vector2* Vector2::setFromMatrixColumn(Matrix4* m, int  index) {
	return fromArray(m->elements, index * 4);
};

Vector2* Vector2::fromArray(_FVAL* array, int offset) {

	x = array[offset];
	y = array[offset + 1];
	z = array[offset + 2];
	return this;

};

Vector2* Vector2::crossVectors(Vector2* a, Vector2* b) {

	_FVAL ax = a->x, ay = a->y, az = a->z;
	_FVAL bx = b->x, by = b->y, bz = b->z;

	x = ay * bz - az * by;
	y = az * bx - ax * bz;
	z = ax * by - ay * bx;

	return this;

};

_FVAL Vector2::lengthSq() {

	return x * x + y * y + z * z;

};

_FVAL Vector2::distanceTo(Vector2* v) {
	return sqrt(distanceToSquared(v));
}

_FVAL Vector2::distanceToSquared(Vector2* v) {
	_FVAL dx = x - v->x, dy = y - v->y, dz = z - v->z;
	return dx * dx + dy * dy + dz * dz;
}

_FVAL Vector2::dot(Vector2* e) {
	return v[0] * e->v[0] + v[1] * e->v[1] + v[2] * e->v[2];
};

Vector2* Vector2::applyMatrix4(Matrix4* m) {



	_FVAL x = v[0], y = v[1], z = v[2];

	_FVAL* e = m->elements;

	_FVAL w = 1 / (e[3] * x + e[7] * y + e[11] * z + e[15]);

	v[0] = (e[0] * x + e[4] * y + e[8] * z + e[12]) * w;
	v[1] = (e[1] * x + e[5] * y + e[9] * z + e[13]) * w;
	v[2] = (e[2] * x + e[6] * y + e[10] * z + e[14]) * w;

	return this;
}

Vector2* Vector2::setFromMatrixPosition(Matrix4* m) {

	v[0] = m->elements[12];
	v[1] = m->elements[13];
	v[2] = m->elements[14];
	return this;
};

Vector2* Vector2::sub(Vector2* v0) {
	for (int i = 0; i < 3; i++)v[i] -= v0->v[i];
	return this;
};

Vector2* Vector2::transformDirection(Matrix4* m) {

	_FVAL x = v[0], y = v[1], z = v[2];
	_FVAL* e = m->elements;
	v[0] = e[0] * x + e[4] * y + e[8] * z;
	v[1] = e[1] * x + e[5] * y + e[9] * z;
	v[2] = e[2] * x + e[6] * y + e[10] * z;

	return normalize();
};


Vector2* Vector2::normalize() {
	_FVAL l = length();
	if (l == 0)l = 1.;
	for (int i = 0; i < 3; i++)v[i] /= l;
	return this;
};

Vector2* Vector2::copy(Vector2* c) {
	x = c->x; y = c->y; z = c->z;
	return this;
};

_FVAL Vector2::length() {
	return sqrt(v[0] * v[0] + v[1] * v[1]);
}

Vector2* Vector2::multiplyScalar(_FVAL scalar) {
	x *= scalar; y *= scalar;
	return this;
}

Vector2* Vector2::add(Vector2* v) {
	x += v->x; y += v->y; 
	return this;
};
Vector2* Vector2::applyQuaternion(Quaternion* q) {
	static _FVAL ix, iy, iz, iw;

	ix = q->w * x + q->y * z - q->z * y;
	iy = q->w * y + q->z * x - q->x * z;
	iz = q->w * z + q->x * y - q->y * x;
	iw = -q->x * x - q->y * y - q->z * z;

	x = ix * q->w + iw * -q->x + iy * -q->z - iz * -q->y;
	y = iy * q->w + iw * -q->y + iz * -q->x - ix * -q->z;
	z = iz * q->w + iw * -q->z + ix * -q->y - iy * -q->x;
	return this;
};


*/

Vector2* Vector2::set(_FVAL _x, _FVAL _y) {
	x = _x; y = _y;
	return this;
};
bool Vector2::equals(Vector2* _v) {
	return x == _v->x && y == _v->y;
};
Vector2* Vector2::copy(Vector2* c) {
	x = c->x; y = c->y;
	return this;
};
Vector2* Vector2::multiply(Vector2* c) {
	x *= c->x; y *= c->y;
	return this;
};
Vector2* Vector2::toFloat() {
	f[0] = float(x);
	f[1] = float(y);
	return this;
}


PyMethodDef Vector2_tp_methods[] = {
	//{"applyMatrix4", (PyCFunction)Vector2::applyMatrix4,  METH_VARARGS, 0},
	{0},
};


PyTypeObject tp_Vector2 = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Vector2";
	type.tp_doc = "Vector2 objects";
	type.tp_basicsize = sizeof(Vector2);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Vector2_new;
	type.tp_init = (initproc)Vector2_init;
	type.tp_dealloc = (destructor)Vector2_dealloc;
	type.tp_methods = Vector2_tp_methods,
		type.tp_getset = Vector2_getsetters;
	return type;
}();

int AddType_Vector2(PyObject* m) {

	if (PyType_Ready(&tp_Vector2) < 0)
		return -1;

	Py_XINCREF(&tp_Vector2);
	PyModule_AddObject(m, "Vector2", (PyObject*)&tp_Vector2);
	return 0;
}

