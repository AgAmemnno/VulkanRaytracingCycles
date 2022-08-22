#include "pch_three.h"
#include "common.hpp"

SphericalHarmonics3::SphericalHarmonics3() {
	printf("constructor   SH \n");
};
SphericalHarmonics3::~SphericalHarmonics3() {
	printf("destructor   SH \n");
};

SphericalHarmonics3* SphericalHarmonics3::set(Vector3 _coefficients[9]) {

	for (int i = 0; i < 9; i++) {
		coefficients[i].copy(&_coefficients[i]);
	}
	return this;
};

SphericalHarmonics3* SphericalHarmonics3::zero() {

	for (int i = 0; i < 9; i++) {
		coefficients[i].set(0, 0, 0);
	}
	return this;
};

// get the radiance in the direction of the normal
// target is a Vector3
Vector3& SphericalHarmonics3::getAt(Vector3& normal, Vector3& target) {

	// normal is assumed to be unit length
	static _FVAL x, y, z;
	static Vector3* coeff;

	x = normal.x, y = normal.y, z = normal.z;

	coeff = &coefficients[0];

	// band 0
	target.copy(&coeff[0])->multiplyScalar(0.282095);  ///Y00

	// band 1
	target.addScaledVector(&coeff[1], 0.488603 * y);  ///Y1-1
	target.addScaledVector(&coeff[2], 0.488603 * z);///Y10
	target.addScaledVector(&coeff[3], 0.488603 * x);///Y11

	// band 2
	target.addScaledVector(&coeff[4], 1.092548 * (x * y));    ///Y2-2
	target.addScaledVector(&coeff[5], 1.092548 * (y * z));    ///Y2-1
	target.addScaledVector(&coeff[6], 0.315392 * (3.0 * z * z - 1.0)); ///Y20
	target.addScaledVector(&coeff[7], 1.092548 * (x * z));
	target.addScaledVector(&coeff[8], 0.546274 * (x * x - y * y));

	return target;

};

// get the irradiance (radiance convolved with cosine lobe) in the direction of the normal
// target is a Vector3
// https://graphics.stanford.edu/papers/envmap/envmap.pdf

Vector3& SphericalHarmonics3::getIrradianceAt(Vector3& normal, Vector3& target) {
	// normal is assumed to be unit length
	static _FVAL x, y, z;
	static Vector3* coeff;
	x = normal.x, y = normal.y, z = normal.z;

	coeff = &coefficients[0];

	// band 0
	target.copy(&coeff[0])->multiplyScalar(0.886227); // pi * 0.282095

	// band 1
	target.addScaledVector(&coeff[1], 2.0 * 0.511664 * y); // ( 2 * pi/ 3 ) * 0.488603
	target.addScaledVector(&coeff[2], 2.0 * 0.511664 * z);
	target.addScaledVector(&coeff[3], 2.0 * 0.511664 * x);

	// band 2
	target.addScaledVector(&coeff[4], 2.0 * 0.429043 * x * y); // ( pi / 4 ) * 1.092548
	target.addScaledVector(&coeff[5], 2.0 * 0.429043 * y * z);
	target.addScaledVector(&coeff[6], 0.743125 * z * z - 0.247708); // ( pi / 4 ) * 0.315392 * 3
	target.addScaledVector(&coeff[7], 2.0 * 0.429043 * x * z);
	target.addScaledVector(&coeff[8], 0.429043 * (x * x - y * y)); // ( pi / 4 ) * 0.546274

	return target;

};

SphericalHarmonics3* SphericalHarmonics3::add(SphericalHarmonics3* sh) {

	for (int i = 0; i < 9; i++) {
		coefficients[i].add(&(sh->coefficients[i]));
	}

	return this;

};


SphericalHarmonics3* SphericalHarmonics3::scale(_FVAL s) {

	for (int i = 0; i < 9; i++) {
		coefficients[i].multiplyScalar(s);
	}

	return this;

};

SphericalHarmonics3* SphericalHarmonics3::lerp(SphericalHarmonics3* sh, _FVAL alpha) {

	for (int i = 0; i < 9; i++) {
		coefficients[i].lerp(&(sh->coefficients[i]), alpha);
	};
	return this;

};

bool SphericalHarmonics3::equals(SphericalHarmonics3* sh) {

	for (int i = 0; i < 9; i++) {

		if (!coefficients[i].equals(&(sh->coefficients[i]))) {

			return false;

		}

	}

	return true;

};

SphericalHarmonics3* SphericalHarmonics3::copy(SphericalHarmonics3* sh) {

	return set(sh->coefficients);
};

SphericalHarmonics3* SphericalHarmonics3::fromArray(_FVAL* array, int offset) {

	for (int i = 0; i < 9; i++) {

		coefficients[i].fromArray(array, offset + (i * 3));

	}

	return this;

};

_FVAL* SphericalHarmonics3::toArray(_FVAL* array, int  offset) {

	for (int i = 0; i < 9; i++) {

		coefficients[i].toArray(array, offset + (i * 3));

	}

	return array;

};

void SphericalHarmonics3::getBasisAt(Vector3& normal, _FVAL  shBasis[9]) {

	// normal is assumed to be unit length
	static _FVAL x, y, z;
	x = normal.x, y = normal.y, z = normal.z;

	// band 0
	shBasis[0] = 0.282095;

	// band 1
	shBasis[1] = 0.488603 * y;
	shBasis[2] = 0.488603 * z;
	shBasis[3] = 0.488603 * x;

	// band 2
	shBasis[4] = 1.092548 * x * y;
	shBasis[5] = 1.092548 * y * z;
	shBasis[6] = 0.315392 * (3 * z * z - 1);
	shBasis[7] = 1.092548 * x * z;
	shBasis[8] = 0.546274 * (x * x - y * y);

};