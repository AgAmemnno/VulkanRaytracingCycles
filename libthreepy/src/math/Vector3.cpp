#include "pch_three.h"
#include "common.hpp"
///#include "util/log.h"

static void
Vector3_dealloc(Vector3 *self)
{
	//printf("\ndealloc vector3\n");
    Py_TYPE(self)->tp_free((PyObject *) self);
}

static PyObject *
Vector3_new(PyTypeObject *type, PyObject *args, PyObject *kw)
{
    int rc = -1;
    //printf("Vector3  new \n");
    Vector3 *self = NULL;
    self = (Vector3 *) type->tp_alloc(type, 0);
    if (!self) goto error;
    rc = 0;

error:
    if(rc <0)Py_XDECREF(self);
    return (PyObject *) self;
}


static PyObject *
Vector3_getx(Vector3 *self, void *closure)
{

    return PyFloat_FromFVAL(self->v[0]);
}

static int
Vector3_setx(Vector3 *self, PyObject *value, void *closure)
{
    self->v[0] =  PyFloat_AsFVAL(value);
    return 0;
}


/*
    int rc = -1;

    if (!value || !PyFloat_Check(value)) {
        PyErr_SetString(PyExc_TypeError, "value should be PyFloat");
        goto error;
    }

    self->x =  PyFloat_AsFVAL(value);
    rc = 0;
error:
    return rc;
}
*/

static PyObject *
Vector3_gety(Vector3 *self, void *closure)
{
    return PyFloat_FromFVAL(self->v[1]);
}

static int
Vector3_sety(Vector3 *self, PyObject *value, void *closure)
{
    self->v[1] =  PyFloat_AsFVAL(value);
    return 0;
}

static PyObject *
Vector3_getz(Vector3 *self, void *closure)
{
    return PyFloat_FromFVAL(self->v[2]);
}

static int
Vector3_setz(Vector3 *self, PyObject *value, void *closure)
{
   self->v[2] =  PyFloat_AsFVAL(value);
   return 0;
}

static PyObject*
Vector3_getCtype(Vector3* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


static int
Vector3_init(Vector3* self, PyObject* args, PyObject* kwds)
{
	char* str;
	if (!PyArg_ParseTuple(args, "ddds", &self->v[0], &self->v[1], &self->v[2],&str))return -1;
	//self->name = std::string(str);
	//printf(" init  vector3  %s    \n",str);
	
	/*
	static char* kwlist[] = { "first", "last", "number", NULL };
	PyObject* first = NULL, * last = NULL, * tmp;

	if (!PyArg_ParseTupleAndKeywords(args, kwds, "|OOi", kwlist,
		&first, &last,
		&self->number))
		return -1;

	if (first) {
		tmp = self->first;
		Py_INCREF(first);
		self->first = first;
		Py_XDECREF(tmp);
	}
	if (last) {
		tmp = self->last;
		Py_INCREF(last);
		self->last = last;
		Py_XDECREF(tmp);
	}
	*/
	return 0;
}

static PyGetSetDef Vector3_getsetters[] = {
    {(char *)"x", (getter)Vector3_getx, (setter)Vector3_setx,0,0},
    {(char *)"y", (getter)Vector3_gety, (setter)Vector3_sety,0,0},
    {(char *)"z", (getter)Vector3_getz, (setter)Vector3_setz,0,0},
	{(char*)"_", (getter)Vector3_getCtype, 0,0,0},
    {0},
};


Vector3* Vector3::setFromMatrixColumn(Matrix4* m, int  index) {
	 return fromArray(m->elements, index * 4);
};

Vector3* Vector3::fromArray(_FVAL* array, int offset) {

	x = array[offset];
	y = array[offset + 1];
	z = array[offset + 2];
	return this;

};

Vector3* Vector3::crossVectors(Vector3* a, Vector3* b) {

	_FVAL ax = a->x, ay = a->y, az = a->z;
	_FVAL bx = b->x, by = b->y, bz = b->z;

	x = ay * bz - az * by;
	y = az * bx - ax * bz;
	z = ax * by - ay * bx;

	return this;

};

_FVAL Vector3::lengthSq() {

	return x * x +  y * y +  z * z;

};

_FVAL Vector3::distanceTo(Vector3* _v) {
	return sqrt(distanceToSquared(_v));
}

_FVAL Vector3::distanceToSquared(Vector3* _v) {
	_FVAL dx = x - _v->x, dy = y - _v->y, dz = z - _v->z;
	return dx * dx + dy * dy + dz * dz;
}

_FVAL Vector3::dot(Vector3* e) {
	return v[0] * e->v[0] + v[1] * e->v[1] + v[2] * e->v[2];
};

Vector3* Vector3::applyMatrix4(Matrix4* m){

	/*array([[0, 4, 8, 12],
		[1, 5, 9, 13],
		[2, 6, 10, 14],
		[3, 7, 11, 15]])
		(rotate + shift) / normalize
	*/

	_FVAL _x = v[0], _y = v[1], _z = v[2];

	_FVAL* e = m->elements;

	_FVAL w = 1 / (e[3] * _x + e[7] * _y + e[11] * _z + e[15]);

	v[0] = (e[0] * _x + e[4] *_y + e[8] * _z + e[12]) * w;
	v[1] = (e[1] * _x + e[5] * _y + e[9] * _z + e[13]) * w;
	v[2] = (e[2] * _x + e[6] * _y + e[10] * _z + e[14]) * w;

	return this;
}

Vector3* Vector3::setFromMatrixPosition(Matrix4* m) {
	
	v[0] = m->elements[12];
	v[1] = m->elements[13];
	v[2] = m->elements[14];
	return this;
};

Vector3* Vector3::sub(Vector3* v0) {
	for (int i = 0; i < 3;i++)v[i] -= v0->v[i];
	return this;
};

Vector3* Vector3::transformDirection(Matrix4* m) {

	_FVAL _x = v[0],_y = v[1], _z = v[2];
	_FVAL* e = m->elements;
	v[0] = e[0] * _x + e[4] * _y + e[8] * _z;
	v[1] = e[1] * _x + e[5] * _y + e[9] * _z;
	v[2] = e[2] * _x + e[6] * _y + e[10] * _z;

	return normalize();
};


Vector3* Vector3::normalize() {
	_FVAL l = length();
	if(l == 0)l = 1.;
	for (int i = 0; i < 3; i++)v[i] /= l;
	return this;
};

Vector3* Vector3::copy(Vector3* c) {
	x = c->x; y = c->y; z = c->z;
	return this;
};

_FVAL Vector3::length() {
	return sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
}

Vector3* Vector3::multiplyScalar(_FVAL scalar) {
	x *= scalar; y *= scalar; z *= scalar;
	return this;
}

Vector3* Vector3::add(Vector3* _v) {
	x += _v->x; y += _v->y; z += _v->z;
	return this;
};

Vector3* Vector3::applyQuaternion(Quaternion* q){
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

Vector3* Vector3::addScaledVector(Vector3* _v, _FVAL  s) {
	x += _v->x * s;
	y += _v->y * s;
	z += _v->z * s;
	return this;
};


Vector3* Vector3::lerp(Vector3* _v, _FVAL alpha) {
	x += (_v->x - x) * alpha;
	y += (_v->y - y) * alpha;
	z += (_v->z - z) * alpha;
	return this;
};

bool Vector3::equals(Vector3* _v) {

	return ((_v->x == x) && (_v->y == y) && (_v->z == z));

};

_FVAL* Vector3::toArray(_FVAL* array, int  offset) {

	array[offset] = x;
	array[offset + 1] = y;
	array[offset + 2] = z;
	
	return array;

};



PyMethodDef Vector3_tp_methods[] = {
	//{"applyMatrix4", (PyCFunction)Vector3::applyMatrix4,  METH_VARARGS, 0},
	{0},
};


PyTypeObject tp_Vector3 = []() -> PyTypeObject  {
    PyTypeObject type = {PyVarObject_HEAD_INIT(0, 0)};
    type.tp_name = "cthreepy.Vector3";
    type.tp_doc = "Vector3 objects";
    type.tp_basicsize = sizeof(Vector3);
    type.tp_itemsize = 0;
    type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    type.tp_new = Vector3_new;
   type.tp_init = (initproc) Vector3_init;
    type.tp_dealloc = (destructor) Vector3_dealloc;
	type.tp_methods = Vector3_tp_methods,
    type.tp_getset = Vector3_getsetters;
    return type;
}();

int AddType_Vector3(PyObject *m){

    if (PyType_Ready(&tp_Vector3) < 0)
        return -1;

    Py_XINCREF(&tp_Vector3);
    PyModule_AddObject(m, "Vector3", (PyObject *) &tp_Vector3);
    return 0;
}

