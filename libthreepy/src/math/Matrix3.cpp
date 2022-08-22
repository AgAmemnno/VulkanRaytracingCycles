#include "pch_three.h"
#include "common.hpp"

static  Vector3 _vector = Vector3(1, 1, 1);

Matrix3* Matrix3::std140() {
	std[0] = elements[0]; std[1] = elements[1]; std[2] = elements[2];
	std[4] = elements[3]; std[5] = elements[4]; std[6] = elements[5];
	std[8] = elements[6]; std[9] = elements[7]; std[10] = elements[8];
	return this;
};

Matrix3* Matrix3::setFromMatrix4(Matrix4* m) {

	_FVAL* me = m->elements;
	_FVAL* te = elements;

	te[0] = me[0]; te[3] = me[4]; te[6] = me[8];
	te[1] = me[1]; te[4] = me[5]; te[7] = me[9];
	te[2] = me[2]; te[5] = me[6];te[8]= me[10];

	return this;

};

Matrix3* Matrix3::getInverse(Matrix3* matrix, bool throwOnDegenerate)
	{

		_FVAL* me = matrix->elements;
		_FVAL* te = elements;

			_FVAL n11 = me[0], n21 = me[1], n31 = me[2],
			n12 = me[3], n22 = me[4], n32 = me[5],
			n13 = me[6], n23 = me[7], n33 = me[8],

			t11 = n33 * n22 - n32 * n23,
			t12 = n32 * n13 - n33 * n12,
			t13 = n23 * n12 - n22 * n13,

			det = n11 * t11 + n21 * t12 + n31 * t13;

		if (det == 0) {

			if (throwOnDegenerate ==  true) {

				///TODO ERROR  throw new Error(msg);
				printf("THREE.Matrix3: .getInverse() can't invert matrix, determinant is 0");
			}
			memcpy(elements, identity9, sizeof(identity9));
			return this;
		}

		_FVAL detInv = 1 / det;

		te[0] = t11 * detInv;
		te[1] = (n31 * n23 - n33 * n21) * detInv;
		te[2] = (n32 * n21 - n31 * n22) * detInv;

		te[3] = t12 * detInv;
		te[4] = (n33 * n11 - n31 * n13) * detInv;
		te[5] = (n31 * n12 - n32 * n11) * detInv;

		te[6] = t13 * detInv;
		te[7] = (n21 * n13 - n23 * n11) * detInv;
		te[8] = (n22 * n11 - n21 * n12) * detInv;

		return this;

	};

Matrix3* Matrix3::transpose() {

	_FVAL tmp;
	_FVAL* m = elements;

	tmp = m[1]; m[1] = m[3]; m[3] = tmp;
	tmp = m[2]; m[2] = m[6]; m[6] = tmp;
	tmp = m[5]; m[5] = m[7]; m[7] = tmp;

	return this;

};

Matrix3* Matrix3::getNormalMatrix(Matrix4* matrix4) {

	return  setFromMatrix4(matrix4)->getInverse(this,true)->transpose();

};
Matrix3* Matrix3::toFloat() {
	for (int i = 0; i < 9; i++)f[i] = float(elements[i]);
	return this;
};


Matrix3* Matrix3::set(_FVAL n11, _FVAL n12, _FVAL n13, _FVAL n21, _FVAL n22, _FVAL n23, _FVAL n31, _FVAL n32, _FVAL n33) {
	_FVAL* te = elements;

	te[0] = n11; te[1] = n21; te[2] = n31;
	te[3] = n12; te[4] = n22; te[5] = n32;
	te[6] = n13; te[7] = n23; te[8] = n33;
	return this;
}

void Matrix3::setUvTransform(_FVAL tx, _FVAL ty, _FVAL sx, _FVAL sy, _FVAL rotation, _FVAL cx, _FVAL cy) {

	static _FVAL c, s;
	c = cos(rotation);
	s = sin(rotation);

	set(
		sx * c, sx * s, -sx * (c * cx + s * cy) + cx + tx,
		-sy * s, sy * c, -sy * (-s * cx + c * cy) + cy + ty,
		0, 0, 1
	);

};

static void
Matrix3_dealloc(Matrix3* self)
{
	Py_TYPE(self)->tp_free((PyObject*)self);
}

static int
Matrix3_init(Matrix3* self, PyObject* args, PyObject* kwds)
{
	char* str;
	if (!PyArg_ParseTuple(args, "s", &str))return -1;
	//self->name = std::string(str);
	//printf(" init  Matrix3  %s    \n", str);

	return 0;
}


static PyObject*
Matrix3_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{

	int rc = -1;
	Matrix3* self = NULL;
	self = (Matrix3*)type->tp_alloc(type, 0);
	if (!self) goto error;
	rc = 0;
	memcpy(self->elements, identity9, sizeof(identity9));


error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;

}


static int
Matrix3_assign(Matrix3* self, PyObject* list, void* closure)
{
	//set: function ( n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44 ) {

	_FVAL* te = self->elements;

	PyObject* item = NULL, * iter = NULL;
	int result = -1;
	int i = 0;

	if (!PyList_Check(list))
		goto error;

	iter = PyObject_GetIter(list);
	if (!iter)
		goto error;


	while ((item = PyIter_Next(iter)) != NULL) {
		//PY_PRINTF(item);
		te[i] = PyFloat_AsFVAL(item);
		Py_XDECREF(item);
		i++;
	}
	result = 0;
error:
	Py_XDECREF(iter);
	return result;
}

static PyObject* Matrix3_get(Matrix3* self, void* closure)
{
	PyObject* dlist = PyList_New(16);
	for (int i = 0; i < 9; i++) {
		PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->elements[i]));
	}
	return dlist;
}

static PyObject*
Matrix3_getCtype(Matrix3* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}

static PyGetSetDef Matrix3_getsetters[] = {
	{(char*)"elements",(getter)Matrix3_get, (setter)Matrix3_assign,0,0},
	{(char*)"_",(getter)Matrix3_getCtype, 0,0,0},
	{0},
};


static PyObject*
Matrix3_set(Matrix3* self, PyObject* args)
{
	///   n11, n12, n13, n21, n22, n23, n31, n32, n33
	///   11  12   13                0   3   6
	///   21  22  23    ====>>  1   4   7
	///   31  32  33               2   5   8
	   
	
	Py_ssize_t n = PyTuple_Size(args);
	if (n != 9) {
		printf("list size not 9 %d \n", (int)n);
		Py_RETURN_NONE;
	}

	    _FVAL* me = self->elements;
	    me[0] = PyFloat_AsFVAL(PyTuple_GetItem(args, 0));
		me[3] = PyFloat_AsFVAL(PyTuple_GetItem(args, 1));
		me[6] = PyFloat_AsFVAL(PyTuple_GetItem(args, 2));

		me[1] = PyFloat_AsFVAL(PyTuple_GetItem(args, 3));
		me[4] = PyFloat_AsFVAL(PyTuple_GetItem(args, 4));
		me[7] = PyFloat_AsFVAL(PyTuple_GetItem(args, 5));

		me[2] = PyFloat_AsFVAL(PyTuple_GetItem(args, 6));
		me[5] = PyFloat_AsFVAL(PyTuple_GetItem(args, 7));
		me[8] = PyFloat_AsFVAL(PyTuple_GetItem(args, 8));

	//printf("child add %d  checksum posiiton.x %Lf \n",i,sb->position.v[0]);
	    Py_RETURN_NONE;
};

PyMethodDef Matrix3_tp_methods[] = {
	{"set", (PyCFunction)Matrix3_set, METH_VARARGS, 0},
	{0},
};

PyTypeObject tp_Matrix3 = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Matrix3";
	type.tp_doc = "Matrix3 objects";
	type.tp_basicsize = sizeof(Matrix3);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Matrix3_new;
	type.tp_init = (initproc)Matrix3_init;
	type.tp_dealloc = (destructor)Matrix3_dealloc;
	type.tp_getset = Matrix3_getsetters;
	type.tp_methods = Matrix3_tp_methods;
	return type;
}();


int AddType_Matrix3(PyObject* m) {

	if (PyType_Ready(&tp_Matrix3) < 0)
		return -1;

	Py_XINCREF(&tp_Matrix3);
	PyModule_AddObject(m, "Matrix3", (PyObject*)&tp_Matrix3);
	return 0;
}