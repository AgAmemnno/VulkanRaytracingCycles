#include "pch_three.h"
#include "common.hpp"

Vector4::Vector4(_FVAL _r, _FVAL _g, _FVAL  _b, _FVAL _a) {
	x = _r;
	y = _g;
	z = _b;
	w = _a;
};
void Vector4::set(_FVAL _r, _FVAL _g, _FVAL  _b, _FVAL _a) {
	x = _r; y = _g; z = _b; w = _a;
};

bool Vector4::equals(Vector4* _v) {
	return (x == _v->x) && (y == _v->y) && (z == _v->z) && (w == _v->w);
};

Vector4* Vector4::copy(Vector4* c) {
	x = c->x; y = c->y; z = c->z; w = c->w;
	return this;
};

Vector4* Vector4::multiplyScalar(_FVAL s) {
	x *= s; y *= s;	z *= s; w *= s;
	return this;
};

Vector4* Vector4::applyMatrix4(Matrix4* m) {

	/*array([[0, 4, 8, 12],
		[1, 5, 9, 13],
		[2, 6, 10, 14],
		[3, 7, 11, 15]])
		(rotate + shift) / normalize
	*/
	_FVAL* e = m->elements;

	v[0] = e[0] * x + e[4] * y + e[8] * z + e[12] * w;
	v[1] = e[1] * x + e[5] * y + e[9] * z + e[13] * w;
	v[2] = e[2] * x + e[6] * y + e[10] * z + e[14] * w;
	v[3] = e[3] * x + e[7] * y + e[11] * z + e[15] * w;

	return this;
}