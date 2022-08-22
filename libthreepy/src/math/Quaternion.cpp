#include "pch_three.h"
#include "common.hpp"

static void VOIDFUNC(){
	///printf("void qua\n");
};
static void
Quaternion_dealloc(Quaternion *self)
{
    Py_TYPE(self)->tp_free((PyObject *) self);
}


static int
Quaternion_init(Quaternion* self, PyObject* args, PyObject* kwds)
{
	char* str;
	if (!PyArg_ParseTuple(args, "dddds", &self->v[0], &self->v[1], &self->v[2], &self->v[3], &str))return -1;
	//self->name = std::string(str);
	//printf(" init  Quaternion  %s    \n", str);
	return 0;
}

static PyObject *
Quaternion_new(PyTypeObject *type, PyObject *args, PyObject *kw)
{
    int rc = -1;
    Quaternion *self = NULL;
    self = (Quaternion *) type->tp_alloc(type, 0);
    if (!self) goto error;
    rc = 0;
    self->cb =VOIDFUNC;

error:
    if(rc <0)Py_XDECREF(self);
    return (PyObject *) self;
}


static PyObject *
Quaternion_getx(Quaternion *self, void *closure)
{

    return PyFloat_FromFVAL(self->v[0]);
}

static int
Quaternion_setx(Quaternion *self, PyObject *value, void *closure)
{
    self->v[0] =  PyFloat_AsFVAL(value);
	self->cb();
    return 0;
}


static PyObject *
Quaternion_gety(Quaternion *self, void *closure)
{
    return PyFloat_FromFVAL(self->v[1]);
}

static int
Quaternion_sety(Quaternion *self, PyObject *value, void *closure)
{
    self->v[1] =  PyFloat_AsFVAL(value);
	self->cb();
    return 0;
}

static PyObject *
Quaternion_getz(Quaternion *self, void *closure)
{
    return PyFloat_FromFVAL(self->v[2]);
}

static int
Quaternion_setz(Quaternion *self, PyObject *value, void *closure)
{
   self->v[2] =  PyFloat_AsFVAL(value);
   self->cb();
   return 0;
}


static PyObject *
Quaternion_getw(Quaternion *self, void *closure)
{
    return PyFloat_FromFVAL(self->v[3]);

	
}

static int
Quaternion_setw(Quaternion *self, PyObject *value, void *closure)
{
   self->v[3] =  PyFloat_AsFVAL(value);
   self->cb();
   return 0;
}


static PyObject*
Quaternion_getCtype(Quaternion* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}

static PyGetSetDef Quaternion_getsetters[] = {
    {(char *)"x", (getter)Quaternion_getx, (setter)Quaternion_setx,0,0},
    {(char *)"y", (getter)Quaternion_gety, (setter)Quaternion_sety,0,0},
    {(char *)"z", (getter)Quaternion_getz, (setter)Quaternion_setz,0,0},
    {(char *)"w", (getter)Quaternion_getw, (setter)Quaternion_setw,0,0},
	{(char*)"_", (getter)Quaternion_getCtype, 0,0,0},
    {0},
};

Quaternion* Quaternion::setFromEuler(Euler* euler, bool update) {

	_FVAL _x = euler->v[0], _y = euler->v[1], _z = euler->v[2];
	EulerOrder order = euler->order;
#// http://www._Mathworks.com/matlabcentral/fileexchange/
#// 	20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
#//	content/SpinCalc.m

	_FVAL c1 = cos(_x / 2), c2 = cos(_y / 2), c3 = cos(_z / 2), s1 = sin(_x / 2), s2 = sin(_y / 2), s3 = sin(_z / 2);
	switch (order)
	{
	case EulerOrder::XYZ:
		this->v[0] = s1 * c2 * c3 + c1 * s2 * s3;
		this->v[1] = c1 * s2 * c3 - s1 * c2 * s3;
		this->v[2] = c1 * c2 * s3 + s1 * s2 * c3;
		this->v[3] = c1 * c2 * c3 - s1 * s2 * s3;
		break;
	case EulerOrder::YXZ:
		this->v[0] = s1 * c2 * c3 + c1 * s2 * s3;
		this->v[1] = c1 * s2 * c3 - s1 * c2 * s3;
		this->v[2] = c1 * c2 * s3 - s1 * s2 * c3;
		this->v[3] = c1 * c2 * c3 + s1 * s2 * s3;
	case EulerOrder::ZXY:
		this->v[0] = s1 * c2 * c3 - c1 * s2 * s3;
		this->v[1] = c1 * s2 * c3 + s1 * c2 * s3;
		this->v[2] = c1 * c2 * s3 + s1 * s2 * c3;
		this->v[3] = c1 * c2 * c3 - s1 * s2 * s3;
		break;
	case EulerOrder::ZYX:
		this->v[0] = s1 * c2 * c3 - c1 * s2 * s3;
		this->v[1] = c1 * s2 * c3 + s1 * c2 * s3;
		this->v[2] = c1 * c2 * s3 - s1 * s2 * c3;
		this->v[3] = c1 * c2 * c3 + s1 * s2 * s3;
		break;
	case EulerOrder::YZX:
		this->v[0] = s1 * c2 * c3 + c1 * s2 * s3;
		this->v[1] = c1 * s2 * c3 + s1 * c2 * s3;
		this->v[2] = c1 * c2 * s3 - s1 * s2 * c3;
		this->v[3] = c1 * c2 * c3 - s1 * s2 * s3;
		break;
	case EulerOrder::XZY:
		this->v[0] = s1 * c2 * c3 - c1 * s2 * s3;
		this->v[1] = c1 * s2 * c3 - s1 * c2 * s3;
		this->v[2] = c1 * c2 * s3 + s1 * s2 * c3;
		this->v[3] = c1 * c2 * c3 + s1 * s2 * s3;
		break;
	default:
		break;
	}
	if (update != false)this->cb();

	return this;
}


Quaternion* Quaternion::setFromRotationMatrix(Matrix4* m) {

	// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm

	// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

	_FVAL* te = m->elements;

	_FVAL m11 = te[0], m12 = te[4], m13 = te[8],
		m21 = te[1], m22 = te[5], m23 = te[9],
		m31 = te[2], m32 = te[6], m33 = te[10],
		trace = m11 + m22 + m33,
		s;

	if (trace > 0) {

		s = 0.5 / sqrt(trace + 1.0);

		w = 0.25 / s;
		x = (m32 - m23) * s;
		y = (m13 - m31) * s;
		z = (m21 - m12) * s;

	}
	else if (m11 > m22&& m11 > m33) {

		s = 2.0 * sqrt(1.0 + m11 - m22 - m33);

		w = (m32 - m23) / s;
		x = 0.25 * s;
		y = (m12 + m21) / s;
		z = (m13 + m31) / s;

	}
	else if (m22 > m33) {

		s = 2.0 * sqrt(1.0 + m22 - m11 - m33);

		w = (m13 - m31) / s;
		x = (m12 + m21) / s;
		y = 0.25 * s;
		z = (m23 + m32) / s;

	}
	else {

		s = 2.0 * sqrt(1.0 + m33 - m11 - m22);

		w = (m21 - m12) / s;
		x = (m13 + m31) / s;
		y = (m23 + m32) / s;
		z = 0.25 * s;

	}

	///cb();

	return this;

};

Quaternion* Quaternion::setFromRotationMatrix(Vector3* v1, Vector3* v2, Vector3* v3){

	// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm

	// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

	_FVAL m11 = v1->x, m12 = v2->x, m13 = v3->x,
		       m21 = v1->y, m22 = v2->y, m23 = v3->y,
		       m31 = v1->z, m32 = v2->z, m33 = v3->z,
		trace = m11 + m22 + m33,
		s;

	if (trace > 0) {

		s = 0.5 / sqrt(trace + 1.0);

		w = 0.25 / s;
		x = (m32 - m23) * s;
		y = (m13 - m31) * s;
		z = (m21 - m12) * s;

	}
	else if (m11 > m22&& m11 > m33) {

		s = 2.0 * sqrt(1.0 + m11 - m22 - m33);

		w = (m32 - m23) / s;
		x = 0.25 * s;
		y = (m12 + m21) / s;
		z = (m13 + m31) / s;

	}
	else if (m22 > m33) {

		s = 2.0 * sqrt(1.0 + m22 - m11 - m33);

		w = (m13 - m31) / s;
		x = (m12 + m21) / s;
		y = 0.25 * s;
		z = (m23 + m32) / s;

	}
	else {

		s = 2.0 * sqrt(1.0 + m33 - m11 - m22);

		w = (m21 - m12) / s;
		x = (m13 + m31) / s;
		y = (m23 + m32) / s;
		z = 0.25 * s;

	}

	cb();

	return this;

};

Quaternion* Quaternion::premultiply(Quaternion* q) {

	return multiplyQuaternions(q, this);

};
Quaternion* Quaternion::toFloat() {
	for (int i = 0; i < 4; i++)f[i] = (float)v[i];
	return this;
}

Quaternion* Quaternion::multiplyQuaternions(Quaternion* a, Quaternion* b) {

	// from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm

	_FVAL qax = a->x, qay = a->y, qaz = a->z, qaw = a->w;
	_FVAL qbx = b->x, qby = b->y, qbz = b->z, qbw = b->w;

	x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby;
	y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz;
	z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx;
	w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz;


	cb();

	return this;

};

void Quaternion::rotateTo(Vector3* _v, Vector3* ret) {
	// Extract the vector part of the quaternion
	Vector3 u(x, y, z);

	// Extract the scalar part of the quaternion
	float s = float(w);

	// Do the math
	ret->copy(u.multiplyScalar(2. * u.dot(_v))->add(_v->multiplyScalar(s * s - u.dot(&u)))->add(u.crossVectors(&u, _v)->multiplyScalar(2. * s)));

}
Quaternion* Quaternion::inverse() {
	// quaternion is assumed to have unit length
	return conjugate();
};

Quaternion* Quaternion::conjugate() {

	x *= -1;
	y *= -1;
	z *= -1;

	cb();

	return this;

};


Quaternion::Quaternion() {
	x = y = z = 0.; w = 1.; cb = VOIDFUNC; ob_base = *Py_None; ob_base.ob_refcnt = -1;
};

Quaternion::Quaternion(_FVAL x, _FVAL y, _FVAL z, _FVAL w):x(x),y(y),z(z),w(w) {
      cb = VOIDFUNC; ob_base = *Py_None; ob_base.ob_refcnt = -1;
};
void Quaternion::copy(Quaternion* q) {
	x = q->x; y = q->y; z = q->z; w = q->w;
}; 

PyTypeObject tp_Quaternion = []() -> PyTypeObject  {
    PyTypeObject type = {PyVarObject_HEAD_INIT(0, 0)};
    type.tp_name = "cthreepy.Quaternion";
    type.tp_doc = "Quaternion objects";
    type.tp_basicsize = sizeof(Quaternion);
    type.tp_itemsize = 0;
    type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    type.tp_new = Quaternion_new;
    type.tp_init = (initproc)Quaternion_init;
    type.tp_dealloc = (destructor) Quaternion_dealloc;
    type.tp_getset = Quaternion_getsetters;
    return type;
}();


int AddType_Quaternion(PyObject *m){

    if (PyType_Ready(&tp_Quaternion) < 0)
        return -1;

    Py_XINCREF(&tp_Quaternion);
    PyModule_AddObject(m, "Quaternion", (PyObject *) &tp_Quaternion);
    return 0;
}