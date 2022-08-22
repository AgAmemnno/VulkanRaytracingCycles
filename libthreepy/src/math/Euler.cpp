#include "pch_three.h"
#include "common.hpp"

///static void VOIDFUNC(){};

static Matrix4      _matrix       = Matrix4();
static Quaternion _quaternion = Quaternion();


static void
Euler_dealloc(Euler *self)
{
    Py_TYPE(self)->tp_free((PyObject *) self);
}

void  testcb() {
	printf("testcb \n");
}

class testcbcls {
public:
	testcbcls():a(0) {};
	int a;
	void method() {
		printf("testcb  %d\n",a);
	}   
};

class testcbcls2 {
public:
	Euler* self;
	testcbcls2(Euler * _self) :self(_self){};
	void method() {
		///printf("testcb  x %Lf\n", self->v[0]);
	}
};

static int
Euler_init(Euler* self, PyObject* args, PyObject* kwds)
{
	char* str;
	if (!PyArg_ParseTuple(args, "dddds", &self->v[0], &self->v[1], &self->v[2], &self->order, &str))return -1;
	//self->name = std::string(str);
	//printf(" init  euler  %s    \n", str);



	return 0;
}


static PyObject *
Euler_new(PyTypeObject *type, PyObject *args, PyObject *kw)
{
    int rc = -1;

    Euler *self = NULL;
	

    self = (Euler *) type->tp_alloc(type, 0);
	
	testcbcls2 clscb = testcbcls2(self);

    if (!self) goto error;
    rc = 0;
    self->DefaultOrder = EulerOrder::XYZ;

	
	 self->cb = std::bind(&testcbcls2::method, clscb);
	
	 //self->cb();


	/*
	testcbcls clscb = testcbcls();
	auto callback2 = std::bind(&testcbcls::method);
	self->cb = callback(clscb, callback2);
	self->cb();
	*/


error:
    if(rc <0)Py_XDECREF(self);
    return (PyObject *) self;
}


static PyObject *
Euler_getx(Euler *self, void *closure)
{

    return PyFloat_FromFVAL(self->v[0]);
}


static int
Euler_setx(Euler *self, PyObject *value, void *closure)
{
    self->v[0] =  PyFloat_AsFVAL(value);
    self->cb();
	//printf("set x euler   \n");
	//printf("callback euler   %Lf \n",self->v[0]);
	
    return 0;
}


static PyObject *
Euler_gety(Euler *self, void *closure)
{
    return PyFloat_FromFVAL(self->v[1]);
}

static int
Euler_sety(Euler *self, PyObject *value, void *closure)
{
    self->v[1] =  PyFloat_AsFVAL(value);

	self->cb();
    return 0;
}

static PyObject *
Euler_getz(Euler *self, void *closure)
{
    return PyFloat_FromFVAL(self->v[2]);
}

static int
Euler_setz(Euler *self, PyObject *value, void *closure)
{
   self->v[2] =  PyFloat_AsFVAL(value);

   self->cb();
   return 0;
}


static PyObject *
Euler_getOrder(Euler *self, void *closure)
{
    return PyLong_FromLong((int)self->order);
}

static int
Euler_setOrder(Euler *self, PyObject *value, void *closure)
{
   self->order =  (EulerOrder)PyLong_AsLong(value);

   self->cb();
   return 0;
}


static PyObject*
Euler_getCtype(Euler* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


static PyGetSetDef Euler_getsetters[] = {
    {(char *)"x", (getter)Euler_getx, (setter)Euler_setx,0,0},
    {(char *)"y", (getter)Euler_gety, (setter)Euler_sety,0,0},
    {(char *)"z", (getter)Euler_getz, (setter)Euler_setz,0,0},
    {(char *)"order", (getter)Euler_getOrder, (setter)Euler_setOrder,0,0},
	{(char*)"_", (getter)Euler_getCtype, 0,0,0},
    {0},
};

#define clamp(value, mn, mx) __max(mn, __min(mx, value))


Euler::Euler() {
	v[0] = 0.; v[1] = 0.; v[2] = 0.; order = EulerOrder::XYZ; DefaultOrder = EulerOrder::XYZ;
	ob_base = *Py_None; ob_base.ob_refcnt = -1;
	testcbcls2 clscb = testcbcls2(this);
	cb = std::bind(&testcbcls2::method, clscb);
};

Euler* Euler::setFromRotationMatrix( Matrix4* m, EulerOrder _order, bool update) {
	//clamp = _Math.clamp
	// assumes the upper 3x3 of m is a pure rotation matrix(i.e, unscaled)
	_FVAL* te = m->elements;
	_FVAL m11 = te[0], m12 = te[4], m13 = te[8], m21 = te[1], m22 = te[5], m23 = te[9], m31 = te[2], m32 = te[6], m33 = te[10];
	order = (_order < EulerOrder::ZYX) ? _order : this->DefaultOrder;
	switch (order)
	{
	case EulerOrder::XYZ:
		this->v[1] = asin(clamp(m13, -1., 1.));
		if (abs(m13) < 0.9999999) {
			this->v[1] = atan2(-m23, m33);
			this->v[2] = atan2(-m12, m11);
		}
		else {
			this->v[0] = atan2(m32, m22);
			this->v[2] = 0;
		}
		break;
	case EulerOrder::YXZ:
		this->v[0] = asin(-clamp(m23, -1, 1));
		if (abs(m23) < 0.9999999) {
			this->v[1] = atan2(m13, m33);
			this->v[2] = atan2(m21, m22);
		}
		else {

			this->v[1] = atan2(-m31, m11);
			this->v[2] = 0;
		}
		break;
	case EulerOrder::ZXY:
		this->v[0] = asin(clamp(m32, -1, 1));

		if (abs(m32) < 0.9999999) {

			this->v[1] = atan2(-m31, m33);
			this->v[2] = atan2(-m12, m22);

		}
		else {
			this->v[1] = 0;
			this->v[2] = atan2(m21, m11);
		}
		break;
	case  EulerOrder::ZYX:

		this->v[1] = asin(-clamp(m31, -1, 1));

		if (abs(m31) < 0.9999999) {

			this->v[0] = atan2(m32, m33);
			this->v[2] = atan2(m21, m11);

		}
		else {
			this->v[0] = 0;
			this->v[1] = atan2(-m12, m22);
		}
		break;
	case EulerOrder::YZX:
		this->v[2] = asin(clamp(m21, -1, 1));
		if (abs(m21) < 0.9999999) {

			this->v[0] = atan2(-m23, m22);
			this->v[1] = atan2(-m31, m11);

		}
		else {

			this->v[0] = 0;
			this->v[1] = atan2(m13, m33);
		}
		break;

	case EulerOrder::XZY:
		this->v[2] = asin(-clamp(m12, -1, 1));

		if (abs(m12) < 0.9999999) {

			this->v[0] = atan2(m32, m22);
			this->v[1] = atan2(m13, m11);

		}
		else {

			this->v[0] = atan2(-m23, m33);
			this->v[1] = 0;
		}
		break;


	default:
		printf("THREE.Euler: .setFromRotationMatrix() given unsupported order: %d", order);
		break;
	}



	if (update != false) this->cb();

	return this;
}

Euler* Euler::setFromQuaternion(Quaternion* q	,EulerOrder _order, bool  update) {
	
	_matrix.makeRotationFromQuaternion(q);

	return this->setFromRotationMatrix(&_matrix, _order, update);
};
Euler* Euler::toFloat() {
	for (int i = 0; i < 3; i++)f[i] = (float)v[i];
	return this;
}

Euler* Euler::set(_FVAL x, _FVAL y, _FVAL z, EulerOrder _order) {
	v[0] = x; v[1] = y; v[2] = z; order = _order; return this;
};

PyTypeObject tp_Euler = []() -> PyTypeObject  {
    PyTypeObject type = {PyVarObject_HEAD_INIT(0, 0)};
    type.tp_name = "cthreepy.Euler";
    type.tp_doc   = "Euler objects";
    type.tp_basicsize = sizeof(Euler);
    type.tp_itemsize = 0;
    type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    type.tp_new = Euler_new;
    type.tp_init = (initproc) Euler_init;
    type.tp_dealloc = (destructor) Euler_dealloc;
    type.tp_getset = Euler_getsetters;
    return type;
}();


int AddType_Euler(PyObject *m){

    if (PyType_Ready(&tp_Euler) < 0)
        return -1;

    Py_XINCREF(&tp_Euler);
    PyModule_AddObject(m, "Euler", (PyObject *) &tp_Euler);
    return 0;
}