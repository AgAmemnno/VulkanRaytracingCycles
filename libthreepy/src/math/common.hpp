#pragma once
#ifndef MATH_COMMON_H
#define MATH_COMMON_H
#pragma warning(disable: 4201)

#if defined(AEOLUSDLL_EXPORTS)
#include "pch_dll.h"
#include "types.hpp"
#elif defined(AEOLUS)
#include "pch_three.h"
#elif defined(AEOLUS_VID)
#include "working.h"
#endif
//#include "../core/common.hpp"



///#define LOG_NO_MATH
#ifdef   LOG_NO_MATH
#define Log_math(...)
#define Log_math_raw(...)
#else
#define Log_math(...) Log_out(__FILE__, __LINE__, Log_TRACE, __VA_ARGS__)
#define Log_math_raw(...) printf( __VA_ARGS__)
#endif
#define LOG_NO_MATH2
#ifdef   LOG_NO_MATH2
#define Log_math2(...)
#else
#define Log_math2(...) log_out(__FILE__, __LINE__, LOG_TRACE, __VA_ARGS__)
#endif

const _FVAL identity[16] = _Identity16
const _FVAL identity9[16] = _Identity9


#define printMatrix3(na,e) { Log_math("matrix4(%s)[",na);\
	for (int i = 0; i < 9; i++) { \
		Log_math(" %Lf ,", e[i]);\
	};\
	Log_math("]\n");}

#define printMatrix4(na,e) { Log_math("matrix4(%s)\n",na);\
	for (int i = 0; i < 4; i++) { \
			Log_math_raw(" [ ");\
		for (int j = 0; j < 4; j++) { \
			Log_math_raw(" %.6Lf ,", e[4*j + i]);\
		};  Log_math_raw(" ]\n");\
	};}


#define printMatrix34(na,e) { Log_math("matrix34(%s)\n",na);\
	for (int i = 0; i < 3; i++) { \
			Log_math_raw(" [ ");\
		for (int j = 0; j < 4; j++) { \
			Log_math_raw(" %.6f ,", e[i][j]);\
		};  Log_math_raw(" ]\n");\
	};}



#define printMatrix4f(na,e) { Log_math("matrix4(%s)\n",na);\
	for (int i = 0; i < 4; i++) { \
			Log_math_raw(" [ ");\
		for (int j = 0; j < 4; j++) { \
			Log_math_raw(" %.6f ,", e[4*j + i]);\
		};  Log_math_raw(" ]\n");\
	};}

#define printVector3(na,e) { Log_math("vector3(%s)[",na);\
	for (int i = 0; i < 3; i++) { \
		Log_math_raw(" %Lf ,", e[i]);\
	};\
	Log_math_raw("]\n");}

#define printVector3F(na,e) { Log_math("vector3(%s)[",na);\
	for (int i = 0; i < 3; i++) { \
		Log_math_raw(" %f ,", e[i]);\
	};\
	Log_math_raw("]\n");}

union Uc2f{ char c[4 * 4]; float  v[4]; };
#define printVector4FChar(na,e) {\
	Uc2f U;\
	for (int i = 0; i < 16; i++)U.c[i] = (e)[i];\
	printVector4F(na, U.v);}

#define printVector4F(na,e) { Log_math("vector4(%s)[",na);\
	for (int i = 0; i < 4; i++) { \
		Log_math_raw(" %f ,", e[i]);\
	};\
	Log_math_raw("]\n");}

#define printVector4(na,e) { Log_math("vector4(%s)[",na);\
	for (int i = 0; i < 4; i++) { \
		Log_math_raw(" %Lf ,", e[i]);\
	};\
	Log_math_raw("]\n");}




typedef struct Color {
	PyObject_HEAD
	union {
				struct {
					float v[3];
				};
				struct {
					float r, g, b;
				};
			};
	
	void set(float r,float g,float b);
	void set(Color c);
	Color& copy(const Color& c);
	Color& multiplyScalar(_FVAL);
} Color;


typedef struct Vector2{
	PyObject_HEAD
	union {
		struct {
			_FVAL x, y;
		};
		struct {
			_FVAL width, height;
		};
		struct {
			_FVAL v[2];
		};
	};

	float f[2];

	Vector2() {
		Vector2(0, 0);
	}
	Vector2(_FVAL _x, _FVAL _y) {
		set(_x, _y);
	};
	Vector2* set(_FVAL _x, _FVAL _y);
	bool equals(Vector2* v);
	Vector2* copy(Vector2* c);
	Vector2* multiply(Vector2* c);
	Vector2* toFloat();

}Vector2;

typedef struct Vector3{
	PyObject_HEAD
		//std::string name;
	union {
		struct {
			_FVAL v[3];
		};
		struct {
			_FVAL x, y, z;
		};
	};
	float    f[3];
	Vector3() {
		v[0] =0; v[1] = 0; v[2] = 0;
		ob_base = PyObject();
	}
	Vector3(_FVAL _x, _FVAL _y, _FVAL _z){
	     v[0] = _x; v[1]= _y; v[2] =_z;
		 ob_base = PyObject();
	}
	Vector3* set(_FVAL _x, _FVAL _y, _FVAL _z) {
		v[0] = _x; v[1] = _y; v[2] = _z;
		return this;
	}
	Vector3* applyMatrix4(Matrix4* m);
	_FVAL dot(Vector3* e);
	Vector3* setFromMatrixPosition(Matrix4* m);
	Vector3* sub(Vector3* v);
	_FVAL length();
	_FVAL lengthSq();
	Vector3* transformDirection(Matrix4* m);
	Vector3* normalize();
	_FVAL distanceTo(Vector3* v);
	_FVAL distanceToSquared(Vector3* v);
	Vector3* toFloat() {
		for (int i = 0; i < 3; i++)f[i] = (float)v[i];
		return this;
	}
	Vector3* copy(Vector3* c);
	Vector3* crossVectors(Vector3* a, Vector3* b);
	Vector3* fromArray(_FVAL* array, int offset = 0);
	Vector3* setFromMatrixColumn(Matrix4* m, int  index);
	Vector3* applyQuaternion(Quaternion* q);
	Vector3* add(Vector3* v);
	Vector3* multiplyScalar(_FVAL scalar);
	Vector3* addScaledVector(Vector3* v,_FVAL  scalar);
	Vector3* lerp(Vector3* v,_FVAL a);
	bool equals(Vector3* v);
	_FVAL* toArray(_FVAL* array, int offset = 0.);
} Vector3;

typedef struct Vector4 {
	union {
		struct {
			_FVAL x, y, z, w;
		};
		struct {
			_FVAL v[4];
		};
	};
	Vector4() {
		///Log_math("constructor Vector4>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
		Vector4(0,0,1,1);
	}
	Vector4(_FVAL _r, _FVAL _g, _FVAL  _b, _FVAL _a);
	void set(_FVAL _r, _FVAL _g, _FVAL  _b, _FVAL _a);
	bool equals(Vector4* v);
	Vector4* copy(Vector4* c);
	Vector4* multiplyScalar(_FVAL s);
	Vector4* Floor() {
		x = floor(x);
		y = floor(y);
		z = floor(z);
		w = floor(w);
		return this;
	}

	Vector4* applyMatrix4(Matrix4* m);
}Vector4;

typedef struct Quaternion {
	PyObject_HEAD
		union {
		struct {
			_FVAL v[4];
		};
		struct {
			_FVAL x, y, z, w;
		};
	};
	float f[4];
	std::function<void(void)> cb;

	Quaternion();
	Quaternion(_FVAL, _FVAL, _FVAL, _FVAL);
	void copy(Quaternion*);
	//std::string name;
	Quaternion* setFromEuler(Euler* euler, bool  update);
	
	Quaternion* setFromRotationMatrix(Matrix4* m);
	Quaternion* setFromRotationMatrix(Vector3* v1, Vector3* v2, Vector3* v3);

	Quaternion* multiplyQuaternions(Quaternion* a, Quaternion* b);

	Quaternion* premultiply(Quaternion* q);

	Quaternion* inverse();

	Quaternion* conjugate();

	Quaternion* toFloat();
	
	Vector4* applyQuaternion(Quaternion& q);

	void rotateTo(Vector3* v, Vector3* ret);
	
} Quaternion;

enum class  EulerOrder {
	XYZ =0,
	YZX,
	ZXY,
	XZY,
	YXZ,
	ZYX
};


typedef struct Euler{
    PyObject_HEAD
    _FVAL v[3];
	float    f[3];
	//std::string name;
    EulerOrder order;
    EulerOrder DefaultOrder;
	Euler* setFromQuaternion(Quaternion* quaternion, EulerOrder order, bool  update);
	Euler* setFromRotationMatrix(Matrix4* m, EulerOrder order, bool update);  
	std::function<void(void)> cb;
	Euler* toFloat();
	Euler();
	Euler* set(_FVAL x, _FVAL y, _FVAL z, EulerOrder _order = EulerOrder::XYZ);
} Euler;


typedef struct Matrix3 {
	PyObject_HEAD
	_FVAL elements[9];
	_FVAL std[12];
	float        f[9];
	
	Matrix3* set(_FVAL n11, _FVAL n12, _FVAL n13, _FVAL n21, _FVAL n22, _FVAL n23, _FVAL n31, _FVAL n32, _FVAL n33);
	Matrix3* setFromMatrix4(Matrix4* m);
	Matrix3* getInverse(Matrix3* matrix, bool throwOnDegenerate);
	Matrix3* transpose();
	Matrix3* getNormalMatrix(Matrix4* matrix4);
	Matrix3* std140();
	Matrix3* toFloat();
	void setUvTransform(_FVAL tx, _FVAL ty, _FVAL sx, _FVAL sy, _FVAL rotation, _FVAL cx, _FVAL cy);

	Matrix3() {
		memcpy(elements,identity9, sizeof(identity9));
	}

} Matrix3;


typedef struct Matrix4 {
	PyObject_HEAD

		Matrix4() {
		memcpy(elements, identity, sizeof(identity));
	    }
	_FVAL elements[16];
	float      f[16];
	//std::string name;
	Matrix4* set(_FVAL* e);
	Matrix4* set(float n11, float n12, float n13, float n14, float n21, float n22, float n23, float n24, float n31, float n32, float n33, float n34, float n41, float n42, float n43, float n44);
	Matrix4* set(_FVAL n11, _FVAL n12, _FVAL n13, _FVAL n14, _FVAL n21, _FVAL n22, _FVAL n23, _FVAL n24, _FVAL n31, _FVAL n32, _FVAL n33, _FVAL n34, _FVAL n41, _FVAL n42, _FVAL n43, _FVAL n44);
	Matrix4* makeTranslation(_FVAL x, _FVAL y, _FVAL z);
    Matrix4* copy(Matrix4* m);
    Matrix4* compose(Vector3 *position,Quaternion* quaternion,Vector3* scale);
	Matrix4*  multiply(Matrix4* m);
    Matrix4 *  multiplyMatrices(Matrix4 * a,Matrix4 * b );
	Matrix4* makeRotationFromQuaternion(Quaternion* q);
	Matrix4* getInverse(Matrix4* m, bool throwOnDegenerate);
	Matrix4* getInversef(Matrix4* m, bool throwOnDegenerate);
	Matrix4* decompose(Vector3* position, Quaternion* quaternion, Vector3* scale);
	Matrix4* extractSphere(Sphere* sp);
	_FVAL determinant();
	_FVAL  getMaxScaleOnAxis();
	Matrix4* transpose();
	Matrix4* transpose(Matrix4* mat);
	Matrix4* lookAt(Vector3* eye, Vector3* target, Vector3* up);
	Matrix4* extractRotation(Matrix4* m);
	Matrix4* makePerspective(_FVAL left, _FVAL right, _FVAL top, _FVAL bottom, _FVAL near, _FVAL far = 0.);
	Matrix4* makePerspectiveOVR(_FVAL left, _FVAL right, _FVAL top, _FVAL bottom, _FVAL _near, _FVAL _far);
	Matrix4* makePerspective(_FVAL fovy, _FVAL aspect, _FVAL zNear, _FVAL  zFar);
	Matrix4* toFloat();
	Matrix4* toDouble();
	void toFloat(float v[16]);
	
} Matrix4;

typedef struct Sphere {
	PyObject_HEAD

	Vector3*      _center;
	_FVAL          _radius;
	Sphere* copy(Sphere* sphere);
	Sphere* applyMatrix4(Matrix4* matrix);
	bool alloc;
	Sphere() {
		_center = new Vector3;
		alloc = true;
	}
	~Sphere() {
		if (alloc) {
			delete _center;
		}
	}
}Sphere;


typedef struct Plane {
	PyObject_HEAD
	Vector3* _normal;
	_FVAL  _constant;
	_FVAL distanceToPoint(Vector3* point);
	Plane* setComponents(_FVAL x, _FVAL y, _FVAL z, _FVAL w);
	Plane* normalize();
	bool alloc;
	Plane() {
		_normal = new Vector3;
		alloc = true;
	}
	~Plane() {
		if (alloc) {
			delete _normal;
		}
	}
}Plane;

typedef struct Frustum {

	PyObject_HEAD
	Sphere* _sphere;
	Vector3* _vector;
	Plane* _planes[6];
	
	bool    alloc;
	Frustum* setFromMatrix(Matrix4* m);
	Frustum* setFromMatrixVR(Matrix4* ,Matrix4* );
	bool intersectsSphere(Sphere* sphere);
	bool intersectsObject(Object3D* object);
	void dealloc() {
		if (alloc) {
			for (int i = 0; i < 6; i++) { delete _planes[i]; }
			delete _sphere;
			delete _vector;
			alloc = false;
		}
	}
	Frustum() {
		Log_math2("<<<<<<<<<<<<<<<<<<<<Frustum  New \n");
		for (int i = 0; i < 6; i++) { _planes[i] = new Plane; }
		_sphere = new Sphere;
		_vector = new Vector3;
		alloc = true;
	};
	~Frustum() {
		dealloc();
	}
}Frustum;

typedef struct Box {
	PyObject_HEAD

	Vector3 mn;
	Vector3 mx;
	Box() {
		mn.x = mn.y = mn.z = pow(2, 127);
		mx.x = mx.y = mx.z = -pow(2, 127);
		mn.toFloat(); mx.toFloat();
	};
	void set(Vector3* b) {
		mn.x = __min(mn.x, b->x); mn.y = __min(mn.y, b->y); mn.x = __min(mn.y, b->y);
		mx.x = __max(mx.x, b->x); mx.y = __max(mx.y, b->y); mx.z = __max(mx.z, b->z);
	};
	void set(float* b) {
		for (int i = 0; i < 3; i++) {
			mn.f[i]  = __min(mn.f[i], b[i]);
			mx.f[i] = __max(mx.f[i], b[i]);
		};
	};

}Box;


/**
 * @author bhouston / http://clara.io
 * @author WestLangley / http://github.com/WestLangley
 *
 * Primary reference:
 *   https://graphics.stanford.edu/papers/envmap/envmap.pdf
 *
 * Secondary reference:
 *   https://www.ppsloan.org/publications/StupidSH36.pdf
 */

typedef struct SphericalHarmonics3 {
	
	Vector3 coefficients[9];
	SphericalHarmonics3();
	~SphericalHarmonics3();
	SphericalHarmonics3* set(Vector3 _coefficients[9]);

	SphericalHarmonics3* zero();

		// get the radiance in the direction of the normal
		// target is a Vector3
	Vector3& getAt(Vector3& normal, Vector3& target);

// get the irradiance (radiance convolved with cosine lobe) in the direction of the normal
// target is a Vector3
// https://graphics.stanford.edu/papers/envmap/envmap.pdf

	Vector3& getIrradianceAt(Vector3& normal, Vector3& target);

	SphericalHarmonics3* add(SphericalHarmonics3* sh);


	SphericalHarmonics3* scale(_FVAL s);

	SphericalHarmonics3* lerp(SphericalHarmonics3* sh, _FVAL alpha);

	bool equals(SphericalHarmonics3* sh);

	SphericalHarmonics3* copy(SphericalHarmonics3* sh);

	SphericalHarmonics3* fromArray(_FVAL* array, int offset = 0);

	_FVAL* toArray(_FVAL* array, int  offset = 0);
		// evaluate the basis functions
		// shBasis is an Array[ 9 ]
	void getBasisAt(Vector3& normal, _FVAL  shBasis[9]);

	
}SphericalHarmonics3;


extern PyTypeObject tp_Vector3;
extern PyTypeObject tp_Quaternion;
extern PyTypeObject tp_Euler;
extern PyTypeObject tp_Matrix4;

int AddType_Vector2(PyObject*);
int AddType_Vector3(PyObject*);
int AddType_Quaternion(PyObject*);
int AddType_Euler(PyObject*);
int AddType_Matrix4(PyObject*);
int AddType_Sphere(PyObject*);
int AddType_Plane(PyObject*);
int AddType_Frustum(PyObject*);
int AddType_Matrix3(PyObject* m);
int AddType_Color(PyObject* m);

#endif