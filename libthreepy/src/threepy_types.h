#pragma once
#ifndef THREEPY_TYPES
#define THREEPY_TYPES
#include <string>

typedef double _FVAL;
#define PyFloat_AsFVAL(v) PyFloat_AsDouble(v)
#define PyFloat_FromFVAL(v) PyFloat_FromDouble(v)

typedef struct Object3D Object3D;
typedef struct Matrix4 Matrix4;
typedef struct Quaternion Quaternion;
typedef struct Euler Euler;
typedef struct Sphere Sphere;

#define    LOD_MODE
#define MAX_LOD 5
struct LODInfo
{
	uint32_t  lodMax;
	uint32_t  firstIndex[MAX_LOD];
	uint32_t  indexCount[MAX_LOD];
	float            distance[MAX_LOD];
	float _pad0[MAX_LOD];
};



const std::string   MARK_DesignedSprite = "D";
const std::string   MARK_CaptureSprite = "C";
const std::string   MARK_ObjFile = "O";
const int32_t       MARK_SHOW_DASH_ON = 1;
const int32_t       MARK_SHOW_DASH_OFF = -1;
const int32_t       MARK_SHOW_DASH_ONOFF = 0;






#endif
