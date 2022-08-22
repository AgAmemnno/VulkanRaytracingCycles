#pragma once
#ifndef CAMERA_H
#define CAMERA_H

#include "math/common.hpp"



struct _Camera {
	~_Camera();
	_Camera();

	PyObject_HEAD

	double   __near;
	double   __far;
	double   __fov;
	double   __aspect;
	double  __zoom;
	double __view;

	Object3D* obj3d;
	Matrix4*  matrixWorldInverse;
	Matrix4*  projectionMatrix;
	Matrix4*  projectionMatrixInverse;

	bool isOrthographicCamera;
	void updateMatrixWorld(bool force = false);
	void updateProjectionMatrix();
};

int AddType_Camera(PyObject* m);

#endif