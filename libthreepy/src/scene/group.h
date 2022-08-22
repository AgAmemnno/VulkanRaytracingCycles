#pragma once

#ifndef GROUP_H
#define GROUP_H

#include <unordered_map>
#include "types.hpp"
#include "core/common.hpp"



typedef struct  LayoutBuffer  LayoutBuffer;
typedef struct  VertexBuffer  VertexBuffer;
typedef struct MeshletBuffer MeshletBuffer;
typedef struct LodBuffer LodBuffer;

struct  callback_prop {
	std::string name;
};

struct Group {
	PyObject_HEAD


		struct {
		arth::GEOMETRY  geom;
		arth::DRAW          draw;
		long                          ID;
		long                        lisID;
	}type;

	bool update = false;

	struct {
		bool hide = false;
		long cnt = 0;
	}draw;

	callback_prop* callback = nullptr;
	Object3D* parent;
	std::vector<Object3D*> child;

	LayoutBuffer* lbMaster;
	VertexBuffer* vbMaster;
	MeshletBuffer* mbMaster;
	LodBuffer* ldMaster;

	Group() { child.clear(); };

};


#endif


