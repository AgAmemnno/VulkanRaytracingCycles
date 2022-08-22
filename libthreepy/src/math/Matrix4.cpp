#include "pch_three.h"
#include "common.hpp"
///static  Vector3 _zero = Vector3(0, 0, 0);
///static  Vector3 _one   =  Vector3(1, 1, 1);
///static  Vector3 _v1     =  Vector3();
///static  Matrix4 _m1    =  Matrix4();
///static  Vector3  _x     = Vector3(0, 0, 0);
///static  Vector3  _y     = Vector3(0, 0, 0);
///static  Vector3  _z     = Vector3(0,0,0);

Matrix4* Matrix4::lookAt(Vector3* eye, Vector3* target, Vector3* up) {
	Vector3  _x = Vector3(0, 0, 0); Vector3  _y = Vector3(0, 0, 0); Vector3  _z = Vector3(0, 0, 0);

	_FVAL* te = elements;

	_z.set(eye->x - target->x, eye->y - target->y, eye->z - target->z);

	if (_z.lengthSq() == 0) {
		// eye and target are in the same position
		_z.z = 1;
	}

	_z.normalize();

	_x.crossVectors(up, &_z);

	if (_x.lengthSq() == 0.) {

		// up and z are parallel

		if (abs(up->z) == 1.) {

			_z.x += 0.0001;

		}
		else {

			_z.z += 0.0001;

		}

		_z.normalize();
		_x.crossVectors(up, &_z);

	}

	_x.normalize();
	_y.crossVectors(&_z, &_x);

	te[0] = _x.x; te[4] = _y.x; te[8] = _z.x;
	te[1] = _x.y; te[5] = _y.y; te[9] = _z.y;
	te[2] = _x.z; te[6] = _y.z; te[10] = _z.z;

	return this;

};
Matrix4* Matrix4::extractRotation(Matrix4* m) {

// this method does not support reflection matrices
	Vector3 _v1 = Vector3();
_FVAL* te = elements,*me = m->elements,
scaleX = 1 / _v1.setFromMatrixColumn(m, 0)->length(),
scaleY = 1 / _v1.setFromMatrixColumn(m, 1)->length(),
scaleZ = 1 / _v1.setFromMatrixColumn(m, 2)->length();

te[0] = me[0] * scaleX;
te[1] = me[1] * scaleX;
te[2] = me[2] * scaleX;
te[3] = 0;

te[4] = me[4] * scaleY;
te[5] = me[5] * scaleY;
te[6] = me[6] * scaleY;
te[7] = 0;

te[8] = me[8] * scaleZ;
te[9] = me[9] * scaleZ;
te[10] = me[10] * scaleZ;
te[11] = 0;

te[12] = 0;
te[13] = 0;
te[14] = 0;
te[15] = 1;

return this;

};
Matrix4* Matrix4::decompose(Vector3* position, Quaternion* quaternion, Vector3* scale) {
	
	Matrix4 _m1 = Matrix4();
	Vector3 _v1;
	_FVAL* te = elements;
	_FVAL	sx = _v1.set(te[0], te[1], te[2])->length(),
		sy = _v1.set(te[4], te[5], te[6])->length(),
		sz = _v1.set(te[8], te[9], te[10])->length(),
	   det = determinant();
	if (det < 0) sx = -sx;
	position->x = te[12];
	position->y = te[13];
	position->z = te[14];
	_m1.copy(this);
	_FVAL invSX = 1 / sx,
		invSY = 1 / sy,
		invSZ = 1 / sz;
	_m1.elements[0] *= invSX;
	_m1.elements[1] *= invSX;
	_m1.elements[2] *= invSX;
	_m1.elements[4] *= invSY;
	_m1.elements[5] *= invSY;
	_m1.elements[6] *= invSY;
	_m1.elements[8] *= invSZ;
	_m1.elements[9] *= invSZ;
	_m1.elements[10] *= invSZ;
	quaternion->setFromRotationMatrix(&_m1);
	scale->x = sx;
	scale->y = sy;
	scale->z = sz;

	return this;

};
Matrix4* Matrix4::extractSphere(Sphere* sp) {
	Vector3 _v1 = Vector3();
	_FVAL* te = elements;
	sp->_radius    = _v1.set(te[0], te[1], te[2])->length();
	sp->_center->set(te[12],te[13],te[14]);
	return this;
};

Matrix4* Matrix4::makePerspective(_FVAL left, _FVAL right, _FVAL top, _FVAL bottom, _FVAL _near, _FVAL _far) {

	if (_far == 0.)printf("THREE.Matrix4: .makePerspective() has been redefined and has a  signature. Please check the docs.");

	static _FVAL* te, x, y, a, b, c, d;
	te = elements;
	x = 2 * _near / (right - left);
	y = 2 * _near / (top - bottom);
	a = (right + left) / (right - left);
	b = (top + bottom) / (top - bottom);
	c = -(_far + _near) / (_far - _near);
	d = -2 * _far * _near / (_far - _near);
	te[0] = x; te[4] = 0; te[8] = a; te[12] = 0;
	te[1] = 0; te[5] = y; te[9] = b; te[13] = 0;
	te[2] = 0; te[6] = 0; te[10] = c; te[14] = d;
	te[3] = 0; te[7] = 0; te[11] = -1; te[15] = 0;
	return this;
};
Matrix4* Matrix4::makePerspectiveOVR(_FVAL left, _FVAL right, _FVAL top, _FVAL bottom, _FVAL _near, _FVAL _far) {

	if (_far == 0.)printf("THREE.Matrix4: .makePerspective() has been redefined and has a  signature. Please check the docs.");
	static _FVAL* te, x, y, a, b, c, d;
	te = elements;

float idx = 1.0f / float(right - left);
float idy = 1.0f / float(bottom - top);
float idz = 1.0f / float(_far - _near);
float sx = float(right + left);
float sy = float(bottom + top);

	te[0] = 2 * idx; te[4] = 0; te[8] = sx * idx;   te[12] = 0;
	te[1] = 0; te[5] = 2 * idy; te[9] = sy * idy;    te[13] = 0;
	te[2] = 0; te[6] = 0; te[10] = -_far * idz; te[14] = -_far * _near * idz;
	te[3] = 0; te[7] = 0; te[11] = -1; te[15] = 0;
	return this;
};


Matrix4* Matrix4::makePerspective(_FVAL fovy, _FVAL aspect, _FVAL zNear, _FVAL  zFar)
{
	assert(abs(aspect - std::numeric_limits<_FVAL>::epsilon()) > static_cast<_FVAL>(0));

	_FVAL  const tanHalfFovy = (_FVAL)tan(fovy / static_cast<_FVAL>(2));

	static _FVAL* te, x, y, a, b, c, d;
	te = elements;


	te[0] = static_cast<_FVAL>(1) / (aspect * tanHalfFovy); te[4] = 0.;                                                            te[8] = 0.;                                  te[12] = 0.;
	te[1] = 0.;                                                                          te[5] = static_cast<_FVAL>(1) / (tanHalfFovy); te[9] = 0.;                                  te[13] = 0.;
	te[2] = 0.;                                                                         te[6] =  0.;                                                           te[10] = zFar / (zNear - zFar);  te[14] = -(zFar * zNear) / (zFar - zNear);
	te[3] = 0.;                                                                         te[7] =  0.;                                                           te[11] = -1.;                                te[15] = 0.;

	return this;
}

Matrix4* Matrix4::set(_FVAL* e) {
	memcpy(elements, e, sizeof(elements));
	return this;
};
Matrix4* Matrix4::set(_FVAL n11, _FVAL n12, _FVAL n13, _FVAL n14, _FVAL n21, _FVAL n22, _FVAL n23, _FVAL n24, _FVAL n31, _FVAL n32, _FVAL n33, _FVAL n34, _FVAL n41, _FVAL n42, _FVAL n43, _FVAL n44) {

	_FVAL* te = elements;

	te[0] = n11; te[4] = n12; te[8] = n13; te[12] = n14;
	te[1] = n21; te[5] = n22; te[9] = n23; te[13] = n24;
	te[2] = n31; te[6] = n32; te[10] = n33; te[14] = n34;
	te[3] = n41; te[7] = n42; te[11] = n43; te[15] = n44;

	return this;

};
Matrix4* Matrix4::set(float n11, float n12, float n13, float n14, float n21, float n22, float n23, float n24, float n31, float n32, float n33, float n34, float n41, float n42, float n43, float n44) {
	float* te = f;

	te[0] = n11; te[4] = n12; te[8] = n13; te[12] = n14;
	te[1] = n21; te[5] = n22; te[9] = n23; te[13] = n24;
	te[2] = n31; te[6] = n32; te[10] = n33; te[14] = n34;
	te[3] = n41; te[7] = n42; te[11] = n43; te[15] = n44;

	return this;
};


Matrix4* Matrix4::transpose() {
	return transpose(this);
};

Matrix4*  Matrix4::transpose(Matrix4* mat) {

	_FVAL* te = mat->elements;
	_FVAL tmp;

	tmp = te[1]; te[1] = te[4]; te[4] = tmp;
	tmp = te[2]; te[2] = te[8]; te[8] = tmp;
	tmp = te[6]; te[6] = te[9]; te[9] = tmp;

	tmp = te[3]; te[3] = te[12]; te[12] = tmp;
	tmp = te[7]; te[7] = te[13]; te[13] = tmp;
	tmp = te[11]; te[11] = te[14]; te[14] = tmp;

	return mat;
};

Matrix4* Matrix4::multiply(Matrix4* m) {
	return multiplyMatrices(this, m);
};
Matrix4* Matrix4::toFloat() {
	for (int i = 0; i < 16; i++)f[i] = float(elements[i]);
	return this;
};
void Matrix4::toFloat(float* v) {
	for (int i = 0; i < 16; i++)v[i] = float(elements[i]);
};

Matrix4* Matrix4::toDouble() {
	for (int i = 0; i < 16; i++)elements[i] = _FVAL(f[i]);
	return this;
};

static void
Matrix4_dealloc(Matrix4 *self)
{
	//printf("\ndealloc matrix4\n");
    Py_TYPE(self)->tp_free((PyObject *) self);
}

static int
Matrix4_init(Matrix4* self, PyObject* args, PyObject* kwds)
{
	char* str;
	if (!PyArg_ParseTuple(args, "s",&str))return -1;
	//self->name = std::string(str);
	//printf(" init  matrix4  %s    \n", str);
	////printf("Init    Matrix   %zu   \n", self->ob_base.ob_refcnt);
	return 0;
}


static PyObject *
Matrix4_new(PyTypeObject *type, PyObject *args, PyObject *kw)
{

    int rc = -1;
    Matrix4 *self = NULL;
    self = (Matrix4 *) type->tp_alloc(type, 0);
    if (!self) goto error;
    rc = 0;
    memcpy(self->elements,identity,sizeof(identity));
	

error:
    if(rc <0)Py_XDECREF(self);

	///printf("New    MAtrix   %zu   \n", self->ob_base.ob_refcnt);
    return (PyObject *) self;

}

static int
Matrix4_assign(Matrix4 *self, PyObject *list, void *closure)
{
    //set: function ( n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44 ) {

	_FVAL* te = self->elements;

	PyObject *item = NULL, *iter = NULL;
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
	///printMatrix4("elements set ", te);
error:
    Py_XDECREF(iter);
    return result;
}


static PyObject* Matrix4_get(Matrix4 *self, void *closure)
{
    PyObject *dlist = PyList_New(16);
    for(int i=0;i<16;i++){
        PyList_SetItem(dlist, i, PyFloat_FromFVAL(self->elements[i]));
    }
    return dlist;
}

static PyObject*
Matrix4_getCtype(Matrix3* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}

static PyGetSetDef Matrix4_getsetters[] = {
    {(char *)"elements",(getter)Matrix4_get, (setter)Matrix4_assign,0,0},
	{(char*)"_",(getter)Matrix4_getCtype, 0,0,0},
    {0},
};

Matrix4 *  Matrix4::compose(Vector3 *position,Quaternion* quaternion,Vector3* scale ){
	    

        _FVAL* te = this->elements;
        _FVAL* q = quaternion->v;
        _FVAL x2,y2,z2,xx,xy,xz,yy,yz,zz,wx,wy,wz;

        x2 =  q[0] + q[0];y2 = q[1] + q[1]; z2 = q[2] + q[2];
        xx =  q[0] * x2;xy = q[0] * y2; xz = q[0] * z2;
        yy =  q[1]  * y2; yz = q[1]* z2; zz = q[2]* z2;
        wx = q[3] * x2; wy = q[3] * y2; wz = q[3] * z2;

        _FVAL* s = scale->v;

        te[ 0 ]  = ( 1 - ( yy + zz ) ) * s[0];
        te[ 1 ]  = ( xy + wz ) * s[0];
        te[ 2 ]  = ( xz - wy ) * s[0];
        te[ 3 ]  = 0;
        te[ 4 ]  = ( xy - wz ) * s[1];
        te[ 5 ]  = ( 1 - ( xx + zz ) ) * s[1];
        te[ 6 ]  = ( yz + wx ) * s[1];
        te[ 7 ]  = 0;
        te[ 8 ]  = ( xz + wy ) * s[2];
        te[ 9 ]  = ( yz - wx ) * s[2];
        te[ 10 ] = ( 1 - ( xx + yy ) ) * s[2];
        te[ 11 ] = 0;
        te[ 12 ] = position->v[0];
        te[ 13 ] = position->v[1];
        te[ 14 ] = position->v[2];
        te[ 15 ] = 1;

        ///printf("compose  print  pos x %Lf y %Lf z %Lf w %Lf\n",te[0],te[5],te[10],te[15]);
        return this;
}

Matrix4 * Matrix4::multiplyMatrices(Matrix4 * a,Matrix4 * b ){
        _FVAL* ae = a->elements;
        _FVAL* be = b->elements;
       
        _FVAL* te = this->elements;
        _FVAL a11 = ae[ 0 ], a12 = ae[ 4 ], a13 = ae[ 8 ], a14 = ae[ 12 ],
        a21 = ae[ 1 ], a22 = ae[ 5 ], a23 = ae[ 9 ], a24 = ae[ 13 ],
        a31 = ae[ 2 ], a32 = ae[ 6 ], a33 = ae[ 10 ], a34 = ae[ 14 ],
        a41 = ae[ 3 ], a42 = ae[ 7 ], a43 = ae[ 11 ], a44 = ae[ 15 ],
        b11 = be[ 0 ], b12 = be[ 4 ], b13 = be[ 8 ], b14 = be[ 12 ],
        b21 = be[ 1 ], b22 = be[ 5 ], b23 = be[ 9 ], b24 = be[ 13 ],
        b31 = be[ 2 ], b32 = be[ 6 ], b33 = be[ 10 ], b34 = be[ 14 ],
        b41 = be[ 3 ], b42 = be[ 7 ], b43 = be[ 11 ], b44 = be[ 15 ];

        te[ 0 ] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
        te[ 4 ] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
        te[ 8 ] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
        te[ 12 ] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

        te[ 1 ] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
        te[ 5 ] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
        te[ 9 ] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
        te[ 13 ] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

        te[ 2 ] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
        te[ 6 ] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
        te[ 10 ] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
        te[ 14 ] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

        te[ 3 ] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
        te[ 7 ] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
        te[ 11 ] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
        te[ 15 ] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
        /*#if __debug__:
        #    A = ae.reshape(4, 4).T
        #    B = be.reshape(4, 4).T
        #    T = A.dot(B)
        #    assert np.all(T == te.reshape(4,4).T),"MatMul Error"
        */

       // printf("this print MatrixWorl pos x %Lf y %Lf z %Lf\n",this->elements[12],this->elements[13],this->elements[14]);

        return this;
}

Matrix4* Matrix4::makeRotationFromQuaternion(Quaternion* q) {
	Vector3 _zero = Vector3(0, 0, 0);
	Vector3 _one   =  Vector3(1, 1, 1);
	return this->compose(&_zero, q, &_one);
}

_FVAL Matrix4::getMaxScaleOnAxis(){

	_FVAL* te = elements;
	_FVAL 	scaleXSq = te[0] * te[0] + te[1] * te[1] + te[2] * te[2];
	_FVAL	scaleYSq = te[4] * te[4] + te[5] * te[5] + te[6] * te[6];
	_FVAL	scaleZSq = te[8] * te[8] + te[9] * te[9] + te[10] * te[10];
	return sqrt(__max(__max(scaleXSq, scaleYSq), scaleZSq));
}

Matrix4* Matrix4::getInverse(Matrix4* m, bool throwOnDegenerate) {

	// based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm

	_FVAL* te = elements;
	_FVAL* me = m->elements;

	_FVAL n11 = me[0], n21 = me[1], n31 = me[2], n41 = me[3],
		n12 = me[4], n22 = me[5], n32 = me[6], n42 = me[7],
		n13 = me[8], n23 = me[9], n33 = me[10], n43 = me[11],
		n14 = me[12], n24 = me[13], n34 = me[14], n44 = me[15],

		t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44,
		t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44,
		t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44,
		t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

	_FVAL  det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;

	if (det == 0) {

		printf("THREE.Matrix4: .getInverse() can't invert matrix, determinant is 0");

		if (throwOnDegenerate == true) {
			///TODO  throw new Error(msg);
			printf("Error  ");
		}
		memcpy(elements, identity, sizeof(identity));
		return this;
	}

	_FVAL detInv = 1 / det;

	te[0] = t11 * detInv;
	te[1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * detInv;
	te[2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * detInv;
	te[3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * detInv;

	te[4] = t12 * detInv;
	te[5] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * detInv;
	te[6] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * detInv;
	te[7] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * detInv;

	te[8] = t13 * detInv;
	te[9] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * detInv;
	te[10] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * detInv;
	te[11] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * detInv;

	te[12] = t14 * detInv;
	te[13] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * detInv;
	te[14] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * detInv;
	te[15] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * detInv;

	return this;

};
Matrix4* Matrix4::getInversef(Matrix4* m, bool throwOnDegenerate) {

	// based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm

	float* te = f;
	float* me = m->f;

	float n11 = me[0], n21 = me[1], n31 = me[2], n41 = me[3],
		n12 = me[4], n22 = me[5], n32 = me[6], n42 = me[7],
		n13 = me[8], n23 = me[9], n33 = me[10], n43 = me[11],
		n14 = me[12], n24 = me[13], n34 = me[14], n44 = me[15],

		t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44,
		t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44,
		t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44,
		t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

	float  det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;

	if (det == 0) {

		printf("THREE.Matrix4: .getInverse() can't invert matrix, determinant is 0");

		if (throwOnDegenerate == true) {
			///TODO  throw new Error(msg);
			printf("Error  ");
		}
		memcpy(elements, identity, sizeof(identity));
		return this;
	}

	float detInv = 1 / det;

	te[0] = t11 * detInv;
	te[1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * detInv;
	te[2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * detInv;
	te[3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * detInv;

	te[4] = t12 * detInv;
	te[5] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * detInv;
	te[6] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * detInv;
	te[7] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * detInv;

	te[8] = t13 * detInv;
	te[9] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * detInv;
	te[10] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * detInv;
	te[11] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * detInv;

	te[12] = t14 * detInv;
	te[13] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * detInv;
	te[14] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * detInv;
	te[15] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * detInv;

	return this;

};

_FVAL Matrix4::determinant(){

_FVAL* te = elements;

_FVAL n11 = te[0], n12 = te[4], n13 = te[8], n14 = te[12];
_FVAL n21 = te[1], n22 = te[5], n23 = te[9], n24 = te[13];
_FVAL n31 = te[2], n32 = te[6], n33 = te[10], n34 = te[14];
_FVAL n41 = te[3], n42 = te[7], n43 = te[11], n44 = te[15];

//TODO: make this more efficient
//( based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm )

return (
	n41 * (
		+n14 * n23 * n32
		- n13 * n24 * n32
		- n14 * n22 * n33
		+ n12 * n24 * n33
		+ n13 * n22 * n34
		- n12 * n23 * n34
		) +
	n42 * (
		+n11 * n23 * n34
		- n11 * n24 * n33
		+ n14 * n21 * n33
		- n13 * n21 * n34
		+ n13 * n24 * n31
		- n14 * n23 * n31
		) +
	n43 * (
		+n11 * n24 * n32
		- n11 * n22 * n34
		- n14 * n21 * n32
		+ n12 * n21 * n34
		+ n14 * n22 * n31
		- n12 * n24 * n31
		) +
	n44 * (
		-n13 * n22 * n31
		- n11 * n23 * n32
		+ n11 * n22 * n33
		+ n13 * n21 * n32
		- n12 * n21 * n33
		+ n12 * n23 * n31
		)

	);

};

Matrix4* Matrix4::copy(Matrix4* m){
          memcpy(this->elements,m->elements,sizeof(this->elements));
          return this;
};

Matrix4* Matrix4::makeTranslation(_FVAL x, _FVAL y, _FVAL z) {
	set(
		1, 0, 0, x,
		0, 1, 0, y,
		0, 0, 1, z,
		0, 0, 0, 1
	);
	return this;
};

static PyObject*
Matrix4_set(Matrix4* self, PyObject* args)
{

	Py_ssize_t n = PyTuple_Size(args);
	if (n != 16) {
		printf("list size not 16 %d \n", (int)n);
		Py_RETURN_NONE;
	}

	_FVAL* te = self->elements;
	int i = 0;
	for (int j = 0; j < n; j++) {
		te[i] = PyFloat_AsFVAL(PyTuple_GetItem(args, j));
		if (i > 11)i = i - 11;
		else i += 4;
	};
	//printf("child add %d  checksum posiiton.x %Lf \n",i,sb->position.v[0]);
	Py_RETURN_NONE;

};

PyMethodDef Matrix4_tp_methods[] = {
	{"set", (PyCFunction)Matrix4_set, METH_VARARGS, 0},
	{0},
};


PyTypeObject tp_Matrix4 = []() -> PyTypeObject  {
    PyTypeObject type = {PyVarObject_HEAD_INIT(0, 0)};
    type.tp_name = "cthreepy.Matrix4";
    type.tp_doc = "Matrix4 objects";
    type.tp_basicsize = sizeof(Matrix4);
    type.tp_itemsize = 0;
    type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
    type.tp_new = Matrix4_new;
    type.tp_init = (initproc) Matrix4_init;
    type.tp_dealloc = (destructor) Matrix4_dealloc;
    type.tp_getset = Matrix4_getsetters;
	type.tp_methods = Matrix4_tp_methods;
    return type;
}();


int AddType_Matrix4(PyObject *m){

    if (PyType_Ready(&tp_Matrix4) < 0)
        return -1;

    Py_XINCREF(&tp_Matrix4);
    PyModule_AddObject(m, "Matrix4", (PyObject *) &tp_Matrix4);
    return 0;

}