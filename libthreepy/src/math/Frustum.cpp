#include "pch_three.h"
#include "common.hpp"
#ifndef VULKAN_THREE
#include "../core/common.hpp"
#endif

static void
Frustum_dealloc(Frustum* self)
{
	Py_TYPE(self)->tp_free((PyObject*)self);
}

static int
Frustum_init(Frustum* self, PyObject* args, PyObject* kwds)
{

	Py_ssize_t n = PyTuple_Size(args);
	if (n != 8) {
		Log_math("Frustum ErrorArguments :: [Plane x6,Sphere,Vector]\n");
		return -1;
	}

	for (int i = 0; i < 6; i++) {
		self->_planes[i] = (Plane*)PyTuple_GetItem(args, i);
		Py_INCREF((PyObject*)self->_planes[i]);
	}

	self->_sphere  = (Sphere*)PyTuple_GetItem(args, 6);
	Py_INCREF((PyObject*)self->_sphere);

	self->_vector  = (Vector3*)PyTuple_GetItem(args, 7);
	Py_INCREF((PyObject*)self->_vector);

	return 0;

}


static PyObject*
Frustum_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;

	Frustum* self = NULL;


	self = (Frustum*)type->tp_alloc(type, 0);

	if (!self) goto error;
	rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;
}


static PyObject*
Frustum_getCtype(Frustum* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


static PyGetSetDef Frustum_getsetters[] = {
	{(char*)"_", (getter)Frustum_getCtype, 0,0,0},
	{0},
};

bool Frustum::intersectsSphere(Sphere* sphere) {

	Vector3* center = sphere->_center;
	_FVAL negRadius = -sphere->_radius;
	//printVector3(">>>>>>>>>>point ", center->v);

	_FVAL distance = this->_planes[0]->distanceToPoint(center);
	//printVector3("normal ", this->_planes[0]->_normal->v);
	//Log_math("%p  distance %Lf  < %Lf \n", this->_planes[0], distance, negRadius);
	if (distance < negRadius) {
		return false;
	}
	distance = this->_planes[1]->distanceToPoint(center);
	//printVector3("normal ", this->_planes[1]->_normal->v);
	//Log_math("%p  distance %Lf  < %Lf \n", this->_planes[1], distance, negRadius);
	if (distance < negRadius) {
		return false;
	}
	distance = this->_planes[2]->distanceToPoint(center);
	//printVector3("normal ", this->_planes[2]->_normal->v);
	//Log_math("%p  distance %Lf  < %Lf \n", this->_planes[2], distance, negRadius);
	if (distance < negRadius) {
		return false;
	}
	distance = this->_planes[3]->distanceToPoint(center);
	//printVector3("normal ", this->_planes[3]->_normal->v);
	//Log_math("%p  distance %Lf  < %Lf \n", this->_planes[3], distance, negRadius);
	if (distance < negRadius) {
		return false;
	}
	
	distance = this->_planes[4]->distanceToPoint(center);
	//printVector3("normal ", this->_planes[4]->_normal->v);
	//Log_math("%p  distance %Lf  < %Lf \n", this->_planes[4], distance, negRadius);
	if (distance < negRadius) {
		return false;
	}
	
	distance = this->_planes[5]->distanceToPoint(center);
	//printVector3("normal ", this->_planes[5]->_normal->v);
	//Log_math("%p  distance %Lf  < %Lf \n", this->_planes[5], distance, negRadius);
	if (distance < negRadius) {
		return false;
	}
	
	/*
	for (int i = 0; i < 6; i++) {
		_FVAL distance = this->_planes[i]->distanceToPoint(center);
		printVector3("normal ", this->_planes[i]->_normal->v);
		Log_math("%p  distance %Lf  < %Lf \n", this->_planes[i],distance, negRadius);
		if (distance < negRadius) {
			return false;
		}
	}
	*/

	return true;
};


bool Frustum::intersectsObject(Object3D* object) {
#ifndef VULKAN_THREE
	_BufferGeometry* geometry = object->geometry;
	//if (geometry.boundingSphere == NULL)  geometry.computeBoundingSphere();
	_sphere->copy(geometry->boundingSphere)->applyMatrix4(object->matrixWorld);
	//Log_math("center %Lf %Lf %Lf  \n", _sphere->_center->v[0], _sphere->_center->v[1], _sphere->_center->v[2]);
	return intersectsSphere(_sphere);
#else
	return false;
#endif
};

Frustum* Frustum::setFromMatrix(Matrix4* m) {

	
	_FVAL* me = m->elements;
	_FVAL me0 = me[0], me1 = me[1], me2 = me[2], me3 = me[3],
		me4 = me[4], me5 = me[5], me6 = me[6], me7 = me[7],
		me8 = me[8], me9 = me[9], me10 = me[10], me11 = me[11],
		me12 = me[12], me13 = me[13], me14 = me[14], me15 = me[15];
	
	_planes[0]->setComponents(me3 - me0, me7 - me4, me11 - me8, me15 - me12)->normalize();
	  // printVector3("plane ", this->_planes[0]->_normal->v);
	_planes[1]->setComponents(me3 + me0, me7 + me4, me11 + me8, me15 + me12)->normalize();
	//printVector3("plane ", this->_planes[1]->_normal->v);
	_planes[2]->setComponents(me3 + me1, me7 + me5, me11 + me9, me15 + me13)->normalize();
	//printVector3("plane ", this->_planes[2]->_normal->v);
	_planes[3]->setComponents(me3 - me1, me7 - me5, me11 - me9, me15 - me13)->normalize();
	
	_planes[4]->setComponents(me3 - me2, me7 - me6, me11 - me10, me15 - me14)->normalize();
	/// printVector3("plane ", this->_planes[4]->_normal->v);
	 ///Log_math(" constant   %Lf   %Lf    \n", me15 - me14,this->_planes[4]->_constant);
	_planes[5]->setComponents(me3 + me2, me7 + me6, me11 + me10, me15 + me14)->normalize();
	
	//printMatrix4("frustum", me);
	//printVector3(_planes[5]->_normal->v);

	return this;
};
Frustum* Frustum::setFromMatrixVR(Matrix4* l,Matrix4* r) {


	_FVAL* le = l->elements;
	_FVAL* re = r->elements;
	/*
	0  4  8   12
    1   5  9   13
    2  6  10  14
	3   7 11  15
	*/

	_planes[0]->setComponents(le[12] + le[0], le[13] + le[1], le[14] + le[2], le[15] + le[3])->normalize();
	// printVector3("plane ", this->_planes[0]->_normal->v);
	_planes[1]->setComponents(re[12] - re[0], re[13] - re[1], re[14] - re[2], re[15] - re[3])->normalize();
	//printVector3("plane ", this->_planes[1]->_normal->v);
	_planes[2]->setComponents(re[12] - re[4], re[13] - re[5], re[14] - re[6], re[15] - re[7])->normalize();
	//printVector3("plane ", this->_planes[2]->_normal->v);
	_planes[3]->setComponents(le[12] + le[4], le[13] + le[5], le[14] + le[6], le[15] + le[7])->normalize();
	//printVector3("plane ", this->_planes[3]->_normal->v);
	_planes[4]->setComponents(le[12] + le[8], le[13] + le[9], le[14] + le[10], le[15] + le[11])->normalize();
	_planes[5]->setComponents(le[12] - le[8], le[13] - le[9], le[14] - le[10], le[15] - le[11])->normalize();

	//printMatrix4("frustum", me);
	//printVector3(_planes[5]->_normal->v);

	return this;
};

PyTypeObject tp_Frustum = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Frustum";
	type.tp_doc = "Frustum objects";
	type.tp_basicsize = sizeof(Euler);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Frustum_new;
	type.tp_init = (initproc)Frustum_init;
	type.tp_dealloc = (destructor)Frustum_dealloc;
	type.tp_getset = Frustum_getsetters;
	return type;
}();


int AddType_Frustum(PyObject* m) {

	if (PyType_Ready(&tp_Frustum) < 0)
		return -1;

	Py_XINCREF(&tp_Frustum);
	PyModule_AddObject(m, "Frustum", (PyObject*)&tp_Frustum);
	return 0;
}