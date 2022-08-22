#pragma once
#ifndef CORE_COMMON_H
#define CORE_COMMON_H



#include  <vector>
#include  "vulkan/vulkan.h"
#include "Python.h"


#include "enum.hpp"
#include "types.hpp"

#include "aeolus/vthreepy_const.h"
#include "aeolus/vthreepy_types.h"


#include "util/working.h"
#include "math/common.hpp"





typedef util::_descaller<int, void*> Desty;




typedef struct  Layers {
	int mask = 1;
	void set(int  channel);
	void enable(int channel);
	void enableAll();
	void toggle(int channel);
	void disable(int channel);
	void disableAll();
	bool test(Layers* layers);
}Layers;

typedef struct DrawRange {
	int start = 0;
	int count = 0;
}DrawRange;


struct carry {

	char* data;
	arth::INPUT       type;
	size_t     memorySize;
	size_t         arraySize;
	size_t       structSize;
	size_t*            offset;
	size_t*        fieldSize;
	size_t          fieldNum;

	
	size_t           vertSize;
	size_t           attrSize;

	bool               float16;
	
	std::vector<arth::INPUT> _struct;
	std::vector<VkFormat>       format;

	carry();
	carry(std::vector<arth::INPUT> components, size_t size);
	~carry();
	void set(std::vector<arth::INPUT> components);
	void set(std::vector<arth::INPUT> components, size_t size, bool empty = false);
	void alloc(size_t size, bool empty = false);
	void dealloc();
	void copy(size_t stid, size_t fid, void* src);
	void copy(size_t stid, arth::INPUT fid, void* src);
	void copyStruct(size_t stid, void* src);
	void copyVertex(size_t idx, void* src);
	void setVertexSize(bool _float16);
	void copyAttr(size_t stid, size_t fid, void* src);


	void printFloatStruct(size_t stid);
	union UnionC4{
		char c[4];
		float f;
		int     i;
		uint32_t u;
		void copy(void* src);
		void printFloat();
		void printInt();
		void printUint();
		
	}v4;


public:
	char* atStruct(size_t i);
	char* atField(size_t stid, size_t fid);

};

struct MeshletTopology
{

	bool    mapped{ false };
	size_t vertSize =0;
	size_t primSize =0;
	size_t descSize=0;

	int   numMeshlets = 0;
	void* primData = nullptr;
	void* vertData = nullptr;
	void* descData = nullptr;


	struct {
		VkDescriptorBufferInfo         desc;
		VkDescriptorBufferInfo         prim;
		VkDescriptorBufferInfo        vert;
	}info = { {},{},{} };


	UniformVk* uniform = nullptr;
	Desty* des = nullptr;
	MeshletTopology() {
		des = new Desty;
	}

	~MeshletTopology()
	{
		if (des != nullptr) {
			des->call(nullptr);
			delete des;
		};

		if (primData)
		{
			free(primData);
		}
		if (descData)
		{
			free(descData);
		}
		if (vertData)
		{
			free(vertData);
		}
	}

};



typedef struct _BufferAttribute {

	int                                 version{0};
	int                                    group{-1};
	long                                 id{ -1 };
	arth::GEOMETRY                  type;
	VkIndexType                    idxType;
	std::string                             name;
	long                                refCnt{0};
	
	struct {
		long    vert{-1};
		long  index{-1};
	}ID;


	Box                         bbox;
	MeshletTopology meshlet;
	struct {
		VkDeviceSize  vert;
		VkDeviceSize  attr;
		VkDeviceSize  index;
		VkDeviceSize  mesh;
	}Offset;

	struct {
		VkDescriptorBufferInfo         vert;
		VkDescriptorBufferInfo         attr; ///instance ,normal, etc..
		VkBufferView                          attrView;
		VkDescriptorBufferInfo        index;
	}info;

	carry array;

	std::vector<uint16_t> index_short;
	std::vector<uint32_t> index;

	struct {
		uint32_t array{ 0 }, index{ 0 }, mesh{0};
	}Size;

	struct updateRange {
		int offset{0};
		int count{0};
	}updateRange;
	bool     needsUpdate{false};

	_BufferAttribute() : needsUpdate(true), updateRange({ -1,-1 }), ID({-1,-1}) {
		idxType = VK_INDEX_TYPE_UINT32;
		id = -1;
		version = 0;
		refCnt = 0;
		info.attrView = VK_NULL_HANDLE;
	};

	void* map(int  i) {

		void* ptr = nullptr;
		if (i == 0) {

			if (idxType == VK_INDEX_TYPE_UINT32) {
				ptr = (void*)(index.data());
			}
			else if (idxType == VK_INDEX_TYPE_UINT16) {
				ptr = (void*)index_short.data();
			}
		}
		else {
			ptr = (void*)array.data;
		}

		return ptr;

	};

	bool operator == (_BufferAttribute& that)
	{
		return this == &that;
	}

}_BufferAttribute;

struct CarryAttribute {
	
	PyObject_HEAD;
	_BufferAttribute* buffer;
	Sphere*          boundingSphere;
	char*              frustumBuffer;
	LODInfo                    lod;
	void init(std::vector<arth::INPUT>& Struct);
};


typedef struct BufferAttribute {
	PyObject_HEAD;
	//std::shared_ptr <_BufferAttribute> buffer;
	///_BufferAttribute* buffer;
	CarryAttribute* buffer;
} BufferAttribute;


typedef struct _BufferGeometry {
	long   id{ -1 };
	int nums{0};
	arth::GEOMETRY type;
	bool needsUpdate = false;
	DrawRange drawRange;
	///_BufferAttribute* attributes = NULL;
	///_BufferAttribute* instance = NULL;

	CarryAttribute* attributes = nullptr;
	CarryAttribute* instance    = nullptr;

	
	_BufferGeometry();
	~_BufferGeometry();
	

}_BufferGeometry;



struct Object3D {

	PyObject_HEAD
	arth::Object                     type;
	arth::DRAW                 calltype;

	
	struct {
		long group;
		long order;
		bool    del;
	}commander;

	struct {
		long ID;
	}Type;

	
	struct {
		bool hide;
		int   gid;  //geometry
		int            pid;  //program
		void* mapped;
		bool needsBuild;
		bool needsSubmit;
		PyObject*     before;
		PyObject*              transform;
	}draw;

	Object3D();
	~Object3D() {
		if (position != nullptr)delete position;
		if (rotation != nullptr)delete rotation;
		if (quaternion != nullptr)delete quaternion;
		if (scale != nullptr)delete scale;
		if (matrix != nullptr)delete matrix;
		if (matrixWorld != nullptr)delete matrixWorld;
		if (modelViewMatrix != nullptr)delete modelViewMatrix;
		if (normalMatrix != nullptr)delete normalMatrix;
	}

	Vector3* position;
	Euler* rotation;
	Quaternion* quaternion;
	Vector3* scale;
	Matrix4* matrix;
	Matrix4* matrixWorld;
	Matrix4* modelViewMatrix;
	Matrix3* normalMatrix;
	Color* color;

	PyObject*     deriv;
	Object3D*   parent;
	std::vector<Object3D*> child;
	_BufferGeometry* geometry;

	int                              id;
	bool                     visible;
	int             renderOrder;
	bool         frustumCulled;
	bool         receiveShadow;
	bool             castShadow;

	_CVAR              drawMode;
	size_t                  drawIdx;
	size_t                  drawCnt;


	Layers                layers;

	bool matrixAutoUpdate;
	bool matrixWorldNeedsUpdate;


	PyObject*                               pymaterial;
	aeo::Material*                                material;

	uint32_t                                     locals;

	UniformVk* uniform;
	Desty*          des;


	void updateMatrixWorld(bool force = false);
	void updateWorldMatrix(bool, bool);
	void updateMatrix();
	void updateMatrix(Sphere* sp);
	void setMesh() {};
	void setCB();
	void lookAt(Vector3* v);
	Object3D* translateOnAxis(Vector3& axis, _FVAL distance);
	Object3D* translateX(_FVAL distance);
	Object3D* translateY(_FVAL distance);
	Object3D* translateZ(_FVAL distance);

	void  init();
};



extern PyTypeObject tp_Object3D;

#define PyObject3D_CheckExact(op) (Py_TYPE(op) == &tp_Object3D)


int AddType_Object3D(PyObject*);
int AddType_BufferAttribute(PyObject*);

namespace geom {

	void generateSphereBufferGeometry(CarryAttribute* carry, float  radius, float widthSegments, float  heightSegments, float  phiStart, float  phiLength, float thetaStart, float  thetaLength, arth::eGEOMETRY  _Type);
	void generatePlaneBufferGeometry(CarryAttribute* carry, float width, float  height, float  widthSegments, float heightSegments, arth::eGEOMETRY  _Type);

};


#endif