#pragma once
#ifndef SCENE_H
#define SCNEN_H

#include <Python.h>
#include <unordered_map>

#include  "enum.hpp"
#include "types.hpp"

#include  "math/common.hpp"
#include  "core/common.hpp"


const _CVAR  FOG       =  0b01;
const _CVAR  FOGexp2  = 0b10;

typedef struct Fog {
	_CVAR            is;
	double       _near;
	double         _far;
	double   _density;
	Color* color;
} Fog;



const _CVAR  BG_COLOR              =  0b001;
const _CVAR  BG_TEXTURE          =  0b010;
const _CVAR  BG_TEXTURECUBE =  0b100;

struct BackGround {
	_CVAR            is;
	Color*        color;
	///Texture*      tex;
	BackGround():is(0) {
		color = nullptr; 
		//tex = nullptr;
	};

	~BackGround() {
		__Decrement__(color)
	    ///__Decrement__(tex)
	};

};

struct Pagination : public Object3D {
	_FVAL    opacity;
	Pagination();
	~Pagination();
	void alloc();
	void dealloc();
	void getRotationToPoint(Vector3* f_pointA, Vector3* f_pointB, Quaternion* f_rotationA, Quaternion* f_result);

};

namespace aeo {
	struct Scene {
		PyObject_HEAD
			bool                         isfog;
		Fog                            fog;
		bool            isbackground;
		BackGround* background;
		int                               id;
		bool             needsUpdate;
		arth::GEOMETRY     type;
		Pagination* page;
	};
};

int AddType_Scene(PyObject* m);


struct AxisHash {
	float  scale;
	std::unordered_map<uint32_t, uint32_t> Grid;
	uint32_t getID(float, float);
};

struct Overlay {
	PyObject_HEAD
	AxisHash* axis;
};

int AddType_Overlay(PyObject* m);




#endif