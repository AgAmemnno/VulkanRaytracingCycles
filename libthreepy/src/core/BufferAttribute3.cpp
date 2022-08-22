#include "pch_three.h"
#include "math/common.hpp"
#include "common.hpp"


///#include "loader/Loader.h"

#define Log_NO_BUFFERATTRI
#ifdef   Log_NO_BUFFERATTRI
#define Log_bufattri(...)
#else
#define Log_bufattri(...) Log_out(__FILE__, __LINE__, Log_TRACE, __VA_ARGS__)
#endif

#define Log_NO_BUFFERATTRI2
#ifdef   Log_NO_BUFFERATTRI2
#define Log_buf2(...)
#else
#define Log_buf2(...) Log_out(__FILE__, __LINE__, Log_TRACE, __VA_ARGS__)
#endif

_BufferGeometry::_BufferGeometry() {
	id = -1; needsUpdate = false; drawRange.start = 0; drawRange.count = 0;
	attributes = nullptr; instance = nullptr;
	nums = 0;

};
_BufferGeometry::~_BufferGeometry() {
	
	if (attributes != nullptr) {
		Log_bufattri("delete attributes    %zd    \n", attributes->ob_base.ob_refcnt);
		Py_DECREF(attributes);
	}
	if (instance != nullptr) {
		Log_bufattri("delete instance   %zd    \n", instance->ob_base.ob_refcnt);
		Py_DECREF(instance);
	}
	
};


	carry::carry():
	data(nullptr),
	offset( nullptr),
	fieldSize(nullptr)
	{};
	carry::carry(std::vector<arth::INPUT> components, size_t size) :
		data(nullptr),
		offset(nullptr),
		fieldSize(nullptr),
		arraySize(size)
	{
		_struct = std::move(components);
		alloc(size);
	};
	carry::~carry() {
		dealloc();
	};
	void carry::set(std::vector<arth::INPUT> components) {
		/*
		_struct.resize(components.size());
		for (int i = 0; i < components.size();i++) {
			_struct[i] = components[i];
		}
		*/
		dealloc();
		_struct = std::move(components);
		fieldNum = _struct.size();
		format.resize(fieldNum);
		arth::INPUT _type = arth::INPUT(0);
		for (arth::INPUT f : _struct) {
			_type = _type | f;
		};


		static  arth::INPUT  PU2 = arth::INPUT::vertex_V2_POSITION | arth::INPUT::vertex_V2_UV;
		static  arth::INPUT  PUN = arth::INPUT::vertex_V3_POSITION | arth::INPUT::vertex_V2_UV | arth::INPUT::vertex_V3_NORMAL;
		static  arth::INPUT  PN = arth::INPUT::vertex_V3_POSITION | arth::INPUT::vertex_V3_NORMAL;
		static  arth::INPUT  PRS = arth::INPUT::vertex_V3_POSITION | arth::INPUT::vertex_V3_ROTATION | arth::INPUT::vertex_F_SCALE;
		static  arth::INPUT  PV = arth::INPUT::vertex_V4_POSITION | arth::INPUT::vertex_V4_VELOCITY;
		static  arth::INPUT  PNC = arth::INPUT::vertex_V4_POSITION | arth::INPUT::vertex_V3_NORMAL | arth::INPUT::vertex_V3_COLOR;
		static  arth::INPUT  PQS = arth::INPUT::vertex_V3_POSITION | arth::INPUT::vertex_V3_SCALE | arth::INPUT::vertex_V4_QUATERNION;
		static  arth::INPUT  PQS4 = arth::INPUT::vertex_V4_POSITION | arth::INPUT::vertex_V4_SCALE | arth::INPUT::vertex_V4_QUATERNION;


		if (_type == PUN)type = arth::INPUT::vertexPUN;
		else if (_type == PN)type = arth::INPUT::vertexPN;
		else if (_type == PRS)type = arth::INPUT::vertexPRS;
		else if (_type == PV)type = arth::INPUT::vertexPV;
		else if (_type == PNC)type = arth::INPUT::vertexPNC;
		else if (_type == PQS)type = arth::INPUT::vertexPQS;
		else if (_type == PQS4)type = arth::INPUT::vertexPQS4;
		else if (_type == arth::INPUT::vertex_V3_POSITION)type = arth::INPUT::vertexP;
		else if (_type == arth::INPUT::vertex_V4_POSITION)type = arth::INPUT::vertexSprite;
		else {
			Log_bad("CarryBuffer Unknown Type \n");
		}

		Log_bufattri("CarryBuffer Type  %zu \n", (UINT64)type);


		offset = new size_t[_struct.size()];
		fieldSize = new size_t[_struct.size()];
		///Log_bufattri(" fieldNum  %zd  \n", _struct.size());
		static size_t  typeSize = 8 * (sizeof(arth::ENUM_TYPE));
		size_t ofs = 0, eid = 0;
		arth::ENUM_TYPE  v = 0;
		unsigned int sf;
		size_t fieldSizeMAX = 0;
		for (auto& component : _struct)
		{
			v = (arth::ENUM_TYPE)component; sf = 4;
			///Log_bufattri(" elem  %u    TypeSize %u\n", v ,typeSize);
			while (sf < typeSize) {
				///Log_bufattri(" sf   %u   %u     %d \n", sf,v >> sf, (v >> sf) & 1);
				if ((v >> sf) & 1) {
					offset[eid] = (UINT64)ofs;
					fieldSize[eid] = (UINT64)sf;
					if (fieldSizeMAX < fieldSize[eid])fieldSizeMAX = fieldSize[eid];
					if (sf == 4) {
						format[eid] = (VK_FORMAT_R32_SFLOAT);
					}
					else if (sf == 8) {
						format[eid] = (VK_FORMAT_R32G32_SFLOAT);
					}
					else if (sf == 12) {
						format[eid] = (VK_FORMAT_R32G32B32_SFLOAT);
					}
					else if (sf == 16) {
						format[eid] = (VK_FORMAT_R32G32B32A32_SFLOAT);
					}
					Log_bufattri(" FIELD  %d    offset %zu  size %zu   format   %d  \n", eid, offset[eid], fieldSize[eid], (int)format[eid]);
					ofs += sf;
					eid++;
					break;
				}
				else  sf += 4;
			};
		}
		structSize = ofs;
		//size_t rem = fieldSizeMAX - (ofs % fieldSizeMAX);

		//structSize = ofs + rem;
		Log_bufattri(" structSize  %u \n", structSize);

	};
	void carry::set(std::vector<arth::INPUT> components, size_t size, bool empty) {
		set(components);
		alloc(size, empty);
	};
	void carry::alloc(size_t size, bool empty) {
		
		arraySize = size;
		memorySize = structSize * arraySize;
		Log_bufattri(" allocate   arraySize  %u    memorySize  %u\n", arraySize, memorySize);
		
		if (empty) {
			data = nullptr;
		}
		else {
			if (data != nullptr) {
				delete[] data; data = nullptr;
			}
			data = new char[memorySize];
		}
	
		
	}
	void carry::dealloc() {
		Log_bufattri(" dealloc Carry\n");
		if (data != nullptr) {
			delete[] data; data = nullptr;
		}
		if (offset != nullptr) {
			delete[] offset; offset = nullptr;
		}
		if (fieldSize != nullptr) {
			delete[] fieldSize; fieldSize = nullptr;
		}

	};
	void carry::copy(size_t stid, size_t fid, void* src) {
		memcpy((void*)(atField(stid, fid)), src, fieldSize[fid]);
	};
	void carry::copy(size_t stid, arth::INPUT  name, void* src) {
		size_t fid = 0;
		bool found = false;
		for (auto v : _struct) {
			if (v == name) {
				found = true; break;
			}
			fid++;
		}
		if (!found) Log_bad("Geometry Attribute not Found.   eNUM INPUT is  %u  \n",(UINT)name);

		memcpy((void*)(atField(stid, fid)), src, fieldSize[fid]);
	};

	void carry::copyStruct(size_t stid, void* src) {
		memcpy((void*)(atStruct(stid)), src, (size_t)structSize);
	};

	void carry::setVertexSize(bool _float16) {
		float16 = _float16;
		vertSize = float16 ? 4 * sizeof(unsigned short) : 4 * sizeof(float);
		attrSize = structSize - vertSize;
	};
	void carry::copyVertex(size_t idx,  void* src) {
		memcpy((void*)(data + idx*vertSize), src, vertSize);
	};

	void carry::copyAttr(size_t stid, size_t fid, void* src) {
		    void* ptr = (void*)(data + arraySize * vertSize + attrSize * stid + offset[fid] - vertSize);
			memcpy(ptr, src, fieldSize[fid]);
	};

	void  carry::UnionC4::copy(void* src) {
			memcpy(c, src, 4);
		};
	void carry::printFloatStruct(size_t stid) {

		float* v = new float[structSize/4];
		memcpy((void* )v, (void*)(atStruct(stid)), structSize);
		int ofs = 0;
		printf("PrintStruct[%d] \n", (int)stid);
		for (int i = 0; i < fieldNum; i++) {
			printf("field %d   type %u [ ", i, (UINT32)_struct[i]);
			for (int j = 0; j < fieldSize[i] / 4; j++) {
				printf("  %.6f , ", (float)v[ofs]);
				ofs++;
			}
			printf("]\n");
		};
		delete v;
		
	};

	void  carry::UnionC4::printFloat() {
			Log_bufattri("\t %f", f);
		};
	void  carry::UnionC4::printInt() {
			Log_bufattri("\t %d", i);
		};
	void  carry::UnionC4::printUint() {
			Log_bufattri("\t %u", u);
		};

	char* carry::atStruct(size_t i) {
		assert(i < arraySize);
		return  (data + structSize * i);
	};
	char* carry::atField(size_t stid, size_t fid) {

		assert(fid < fieldNum);
		return (atStruct(stid) + offset[fid]);
	};

static	float            pos[4] = { 0.f,0.f,0.f,0.f };
static	float              uv[4] = { 0.f, 0.f, 0.f, 0.f };
static	float           nor[4] = { 0.f,0.f,0.f,0.f };
static	size_t      POSITION = 0;
static	size_t      UV = 1;
static	size_t      NORMAL = 2;


void generateTriangleBufferGeometry(CarryAttribute* carry) {

	carry->buffer->array.alloc(3);
	
	struct _st{
		float            pos[3];
		float              uv[3];
		float           nor[3];
	};
	
	_st st = { {  1.0f,  1.0f, -3.0f }, { 1.0f, 1.0f}, {1.f,0.f,0.0f } };
	carry->buffer->array.copyStruct(0,(void*)&st);
	st = { { -1.0f,  1.0f, -3.0f }, { 0.0f, 1.0f}, {1.f,0.f,0.0f } };
	carry->buffer->array.copyStruct(1, (void*)&st);
	st = { {  0.0f, -1.0f, -3.0f }, {0.0f,1.f}, {1.f,0.f,0.0f } };
	carry->buffer->array.copyStruct(1, (void*)&st);
		
	carry->buffer->index = { 0, 1, 2 };
	carry->buffer->Size.array = carry->buffer->array.memorySize;
	carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index.size());
	carry->buffer->Size.index = carry->buffer->updateRange.count * sizeof(uint32_t);

	Log_bufattri(" Params    None  size   (%zd , %zd ) \n", carry->buffer->array.arraySize, carry->buffer->index.size());

};

void generateTriangleBufferGeometry1(CarryAttribute* carry) {

	carry->buffer->array.alloc(3);

	struct Vertex {
		float pos[3];
	};

	Vertex st[3] = {
		{ {  1.0f,  1.0f, 0.0f } },
		{ { -1.0f,  1.0f, 0.0f } },
		{ {  0.0f, -1.0f, 0.0f } }
	};

	carry->buffer->array.copyStruct(0, (void*)&st[0]);
	carry->buffer->array.copyStruct(1, (void*)&st[1]);
	carry->buffer->array.copyStruct(1, (void*)&st[2]);

	carry->buffer->index = { 0, 1, 2 };
	carry->buffer->Size.array = carry->buffer->array.memorySize;
	carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index.size());
	carry->buffer->Size.index = carry->buffer->updateRange.count * sizeof(uint32_t);

	Log_bufattri(" Params    None  size   (%zd , %zd ) \n", carry->buffer->array.arraySize, carry->buffer->index.size());

};

#include <execution>

void generateIcosahedronGeometry(CarryAttribute* carry) {
	// Sphere VBO/IBO
		/*
	std::vector<int> Faces = {
	2, 1, 0,
	3, 2, 0,
	4, 3, 0,
	5, 4, 0,
	1, 5, 0,
	11, 6,  7,
	11, 7,  8,
	11, 8,  9,
	11, 9,  10,
	11, 10, 6,
	1, 2, 6,
	2, 3, 7,
	3, 4, 8,
	4, 5, 9,
	5, 1, 10,
	2,  7, 6,
	3,  8, 7,
	4,  9, 8,
	5, 10, 9,
	1, 6, 10
	};

	const float Verts[] = {
	 0.000f,  0.000f,  1.000f, 1.0f,
	 0.894f,  0.000f,  0.447f, 1.0f,
	 0.276f,  0.851f,  0.447f, 1.0f,
	-0.724f,  0.526f,  0.447f, 1.0f,
	-0.724f, -0.526f,  0.447f, 1.0f,
	 0.276f, -0.851f,  0.447f, 1.0f,
	 0.724f,  0.526f, -0.447f, 1.0f,
	-0.276f,  0.851f, -0.447f, 1.0f,
	-0.894f,  0.000f, -0.447f, 1.0f,
	-0.276f, -0.851f, -0.447f, 1.0f,
	 0.724f, -0.526f, -0.447f, 1.0f,
	 0.000f,  0.000f, -1.000f, 1.0f };
	*/
	const float  Verts[] =
	{	0.0000f, -1.0000f, 0.0000f, 1.0f,
		0.7236f, -0.4472f, 0.5257f, 1.0f,
		-0.2764f, -0.4472f, 0.8506f, 1.0f,
		-0.8944f, -0.4472f, 0.0000f, 1.0f,
		-0.2764f, -0.4472f, -0.8506f, 1.0f,
		0.7236f, -0.4472f, -0.5257f, 1.0f,
		0.2764f, 0.4472f, 0.8506f, 1.0f,
		-0.7236f, 0.4472f, 0.5257f, 1.0f,
		-0.7236f, 0.4472f, -0.5257f, 1.0f,
		0.2764f, 0.4472f, -0.8506f, 1.0f,
		0.8944f, 0.4472f, 0.0000f, 1.0f,
		0.0000f, 1.0000f, 0.0000f, 1.0f,
    };

	std::vector<int> Faces = {
		0, 1, 2,
		1, 0, 5,
		0, 2, 3,
		0, 3, 4,
		0, 4, 5,
		1, 5, 10,
		2, 1, 6,
		3, 2, 7,
		4, 3, 8,
		5, 4, 9,
		1, 10, 6,
		2, 6, 7,
		3, 7, 8,
		4, 8, 9,
		5, 9, 10,
		6, 10, 11,
		7, 6, 11,
		8, 7, 11,
		9, 8, 11,
		10, 9, 11
	};


	int IndexCount  = Faces.size();
	int VertexCount = sizeof(Verts) / sizeof(Verts[0]);

	bool flip = false;
	if (flip) {
		for (size_t i = 0; i < IndexCount; i += 3) {
			int x = Faces[i]; Faces[i] = Faces[i + 2]; Faces[i + 2] = x;
		}
	}

	int PARTICLE_BATCHSIZE = 1;

	carry->buffer->array.alloc(VertexCount * PARTICLE_BATCHSIZE);
	carry->buffer->index.resize(IndexCount * PARTICLE_BATCHSIZE);

	char* ptr = (char*)carry->buffer->array.data;

	for (int i = 0; i < PARTICLE_BATCHSIZE; i++) {

		memcpy(ptr, Verts, sizeof(Verts));
		ptr += sizeof(Verts);
		std::copy(Faces.begin(), Faces.end(), carry->buffer->index.begin() + size_t(i * Faces.size()));
		std::for_each(std::execution::seq, Faces.begin(), Faces.end(), [&](auto& elem) { elem += (int)VertexCount / 4; });

	};


};
void generateCubeMapGeometry(CarryAttribute* carry) {
	

	const float Verts[] = { -0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  1.000000 ,  0.000000 ,  -0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  1.000000 ,  1.000000 ,  0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  0.000000 ,  1.000000 ,  0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  0.000000 ,  1.000000 ,  0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  0.000000 ,  0.000000 ,  -0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  1.000000 ,  0.000000 ,  -0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  0.000000 ,  0.000000 ,  0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  1.000000 ,  0.000000 ,  0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  1.000000 ,  1.000000 ,  0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  1.000000 ,  1.000000 ,  -0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  0.000000 ,  1.000000 ,  -0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  0.000000 ,  0.000000 ,  -0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  0.000000 ,  0.000000 ,  0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  1.000000 ,  0.000000 ,  0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  1.000000 ,  1.000000 ,  0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  1.000000 ,  1.000000 ,  -0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  0.000000 ,  1.000000 ,  -0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  0.000000 ,  0.000000 ,  0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  0.000000 ,  0.000000 ,  0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  1.000000 ,  0.000000 ,  0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  1.000000 ,  1.000000 ,  0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  1.000000 ,  1.000000 ,  0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  0.000000 ,  1.000000 ,  0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  0.000000 ,  0.000000 ,  0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  0.000000 ,  0.000000 ,  -0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  1.000000 ,  0.000000 ,  -0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  1.000000 ,  1.000000 ,  -0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  1.000000 ,  1.000000 ,  0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  0.000000 ,  1.000000 ,  0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  0.000000 ,  0.000000 ,  -0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  0.000000 ,  0.000000 ,  -0.250000 ,  0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -2.000000 ,  1.000000 ,  0.000000 ,  -0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  1.000000 ,  1.000000 ,  -0.250000 ,  0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  2.000000 ,  1.000000 ,  1.000000 ,  -0.250000 ,  -0.250000 ,  0.250000 ,  0.000000 ,  0.000000 ,  1.000000 ,  0.000000 ,  1.000000 ,  -0.250000 ,  -0.250000 ,  -0.250000 ,  0.000000 ,  -0.000000 ,  -1.000000 ,  0.000000 ,  0.000000  };
	std::vector<unsigned int>  Faces = { 2 ,  1 ,  0 ,  5 ,  4 ,  3 ,  8 ,  7 ,  6 ,  11 ,  10 ,  9 ,  14 ,  13 ,  12 ,  17 ,  16 ,  15 ,  20 ,  19 ,  18 ,  23 ,  22 ,  21 ,  26 ,  25 ,  24 ,  29 ,  28 ,  27 ,  32 ,  31 ,  30 ,  35 ,  34 ,  33 };


	int IndexCount = Faces.size();
	int VertexCount = sizeof(Verts) / sizeof(Verts[0]);

	bool flip = false;
	if (flip) {
		for (size_t i = 0; i < IndexCount; i += 3) {
			int x = Faces[i]; Faces[i] = Faces[i + 2]; Faces[i + 2] = x;
		}
	}

	int PARTICLE_BATCHSIZE = 1;

	carry->buffer->array.alloc(VertexCount /3);
	carry->buffer->index.resize(IndexCount * PARTICLE_BATCHSIZE);

	char* ptr = (char*)carry->buffer->array.data;

	for (int i = 0; i < PARTICLE_BATCHSIZE; i++) {

		memcpy(ptr, Verts, sizeof(Verts));
		ptr += sizeof(Verts);
		std::copy(Faces.begin(), Faces.end(), carry->buffer->index.begin() + size_t(i * Faces.size()));

	};
	carry->buffer->Size.array = carry->buffer->array.memorySize;
	carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index.size());
	carry->buffer->Size.index = carry->buffer->updateRange.count * sizeof(uint32_t);


};
namespace geom {
	void generateSphereBufferGeometry(CarryAttribute* carry, float  radius, float widthSegments, float  heightSegments, float  phiStart, float  phiLength, float thetaStart, float  thetaLength, arth::eGEOMETRY  _Type) {


		auto Type = (arth::eGEOMETRY)_Type;

		if __ENUM__(Type, arth::eGEOMETRY::LOD_BIT) {
			generateIcosahedronGeometry(carry);

		}
		else {


			Vector3 vertex = Vector3();
			Vector3 normal = Vector3();


			widthSegments = __max(3, floor(widthSegments));
			heightSegments = __max(2, floor(heightSegments));

			float thetaEnd = (float)__min(thetaStart + thetaLength, M_PI);

			static  float u, v, uOffset;
			static  int  idx, ix1, iy1;
			unsigned int index;
			idx = 0;
			index = 0;
			carry->buffer->array.alloc(int(heightSegments + 1) * int(widthSegments + 1));

			bool texel = false;
			if __ENUM__(Type, arth::eGEOMETRY::TEXELBUFFER_BIT) {
				carry->buffer->array.setVertexSize(false);
				texel = true;
			};


			std::vector<std::vector<unsigned int>>  grid;
			std::vector<unsigned int> verticesRow;
			///Log_bufattri("Size  %d   \n", int(heightSegments + 1) * int(widthSegments + 1));
			/*
			static	float            pos[4] = { 0.f,0.f,0.f,0.f };
			static	float              uv[4] = { 0.f,0.f,0.f,0.f };
			static	float           nor[4] = { 0.f,0.f,0.f,0.f };
			*/



			for (int iy = 0; iy < int(heightSegments + 1); iy++) {

				verticesRow.resize(0);
				v = float(iy) / heightSegments;
				uOffset = 0.;

				if (iy == 0 && thetaStart == 0.f) {

					uOffset = 0.5f / widthSegments;

				}
				else if (iy == int(heightSegments) && thetaEnd == M_PI) {

					uOffset = -0.5f / widthSegments;
				}

				for (int ix = 0; ix < widthSegments + 1; ix++) {

					u = float(ix) / widthSegments;

					pos[0] = -radius * cos(phiStart + u * phiLength) * sin(thetaStart + v * thetaLength);
					pos[1] = radius * cos(thetaStart + v * thetaLength);
					pos[2] = radius * sin(phiStart + u * phiLength) * sin(thetaStart + v * thetaLength);

					if (texel)carry->buffer->array.copyVertex(idx, (void*)pos);
					else carry->buffer->array.copy(idx, arth::INPUT::vertex_V3_POSITION, (void*)pos);

					vertex.set(double(pos[0]), double(pos[1]), double(pos[2]))->normalize()->toFloat();
					nor[0] = vertex.f[0];
					nor[1] = vertex.f[1];
					nor[2] = vertex.f[2];

					if (texel)carry->buffer->array.copyAttr(idx, NORMAL, (void*)nor);
					else carry->buffer->array.copy(idx, arth::INPUT::vertex_V3_NORMAL, (void*)nor);


					uv[0] = u + uOffset;
					uv[1] = 1 - v;

					if (texel)carry->buffer->array.copyAttr(idx, UV, (void*)uv);
					else carry->buffer->array.copy(idx, arth::INPUT::vertex_V2_UV, (void*)uv);


					///Log_bufattri("idx  %d position [%.3f  %.3f  %.3f]    normal [%.3f  %.3f  %.3f] uv [%.3f  %.3f]    \n", idx,p[0], p[1], p[2], n[0],n[1],n[2],uv[0], uv[1]);

					verticesRow.push_back(index);
					index += 1;
					idx++;
				}

				grid.push_back(verticesRow);
			};
			Log_bufattri("index\n");
			idx = 0;
			static unsigned int a, b, c, d;
			for (int iy = 0; iy < heightSegments; iy++) {
				for (int ix = 0; ix < widthSegments; ix++) {

					ix1 = ix + 1;
					iy1 = iy + 1;
					a = grid[iy][ix1];
					b = grid[iy][ix];
					c = grid[iy1][ix];
					d = grid[iy1][ix1];
					if (iy != 0 || thetaStart > 0.f) {
						carry->buffer->index.insert(carry->buffer->index.begin() + idx, { a,b,d }); idx += 3;
					}

					if (iy != heightSegments - 1 || thetaEnd < M_PI) {
						carry->buffer->index.insert(carry->buffer->index.begin() + idx, { b,c,d }); idx += 3;
					}
					///Log_bufattri("index [%u  %u  %u  %u]    \n", a,b,c,d);

				};
			};

		}


		carry->buffer->Size.array = carry->buffer->array.memorySize;
		carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index.size());
		carry->buffer->Size.index = carry->buffer->updateRange.count * sizeof(uint32_t);
		carry->boundingSphere->_center->set(0., 0., 0.);
		carry->boundingSphere->_radius = _FVAL(radius);

		carry->buffer->bbox.mn.set(-radius, -radius, -radius);
		carry->buffer->bbox.mx.set(radius, radius, radius);
		carry->buffer->bbox.mn.toFloat();
		carry->buffer->bbox.mx.toFloat();
		///Log_bufattri(" Params   radius %f widthSegments %f heightSegments %f  phiStart %f  phiLength %f  thetaStart %f  thetaLength %f size   (%zd , %zd ) \n", radius, widthSegments, heightSegments, phiStart, phiLength, thetaStart, thetaLength, geom->array.size(), geom->index.size());

	};

	void generatePlaneBufferGeometry(CarryAttribute* carry, float width,float  height,float  widthSegments, float heightSegments, arth::eGEOMETRY  _Type){


		static  float width_half, height_half, segment_width, segment_height;
		static  int  gridX, gridY, gridX1, gridY1;

		width_half = width / 2.f;
		height_half = height / 2.f;
		gridX = int(floor(widthSegments));
		gridY = int(floor(heightSegments));

		gridX1 = gridX + 1;
		gridY1 = gridY + 1;
		segment_width = width / gridX;
		segment_height = height / gridY;

		/// generate vertices, normals and uvs
		carry->buffer->array.alloc(gridY1 * gridX1);

		static float x, y;
		static int idx;

		idx = 0;
		for (int iy = 0; iy < gridY1; iy++) {

			y = iy * segment_height - height_half;

			for (int ix = 0; ix < gridX1; ix++) {

				x = ix * segment_width - width_half;

				pos[0] = x; pos[1] = -y; pos[2] = 0;
				carry->buffer->array.copy(idx, arth::INPUT::vertex_V3_POSITION, (void*)pos);

				uv[0] = float(ix) / float(gridX);
				uv[1] = 1 - (float(iy) / float(gridY));
				carry->buffer->array.copy(idx, arth::INPUT::vertex_V2_UV, (void*)uv);
				///Log_bufattri("position [%.3f  %.3f  %.3f]     uv [%.3f  %.3f]    \n", p[0], p[1], p[2], u[0], u[1]);

				nor[0] = 0; nor[1] = 0; nor[2] = 1;
				carry->buffer->array.copy(idx, arth::INPUT::vertex_V3_NORMAL, (void*)nor);

				idx++;
			}
		}


		carry->buffer->index.resize(gridY1 * gridX1 * 6);
		idx = 0;
		static unsigned int a, b, c, d;
		for (int iy = 0; iy < gridY; iy++) {
			for (int ix = 0; ix < gridX; ix++) {

				a = unsigned int(ix + gridX1 * iy);
				b = unsigned int(ix + gridX1 * (iy + 1));
				c = unsigned int((ix + 1) + gridX1 * (iy + 1));
				d = unsigned int((ix + 1) + gridX1 * iy);

				carry->buffer->index.insert(carry->buffer->index.begin() + idx, { a,b,d }); idx += 3;
				carry->buffer->index.insert(carry->buffer->index.begin() + idx, { b,c,d }); idx += 3;

			};
		};


		carry->buffer->Size.array = carry->buffer->array.memorySize;
		carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index.size());
		carry->buffer->Size.index = carry->buffer->updateRange.count * sizeof(uint32_t);
		carry->boundingSphere->_center->set(0, 0, 0);
		carry->boundingSphere->_radius = (_FVAL)((width > height) ? width / 2. : height / 2.);
		carry->buffer->bbox.mn.set(-width / 2., -height / 2., 0);
		carry->buffer->bbox.mx.set(width / 2., height / 2., 0);
		carry->buffer->bbox.mn.toFloat();
		carry->buffer->bbox.mx.toFloat();

		///Log_bufattri(" Params    %f %f %f %f     size   (%zd , %zd ) \n", width, height, widthSegments, heightSegments, carry->buffer->array.size(), carry->buffer->index.size());

	}
}
void generateSphereBufferGeometry(CarryAttribute * carry, PyObject * args) {

	static unsigned _Type;
	static float radius, widthSegments, heightSegments, phiStart, phiLength, thetaStart, thetaLength;
	if (!PyArg_ParseTuple(args, "Ifffffff", &_Type, &radius, &widthSegments, &heightSegments, &phiStart, &phiLength, &thetaStart, &thetaLength)) {
		printf("GLProgram    error Arguments");
		PyErr_BadArgument();
	};

	geom::generateSphereBufferGeometry(carry, radius, widthSegments, heightSegments, phiStart, phiLength, thetaStart, thetaLength, (arth::eGEOMETRY)_Type);


};



uint32_t buildPlane(CarryAttribute* carry,uint32_t ofs ,int  u, int  v, int  w,float udir,float  vdir,float  width,float  height,float  depth,uint32_t  gridX,uint32_t  gridY) {

		///_ = { 'x':0,'y' : 1,'z' : 2 }
	float segmentWidth = width / float(gridX);
	float segmentHeight = height / float(gridY);

	float widthHalf = width / 2;
	float heightHalf = height / 2;
	float depthHalf = depth / 2;

	uint32_t gridX1 = gridX + 1;
	uint32_t gridY1 = gridY + 1;


	uint32_t idx = ofs;



	for (uint32_t iy = 0; iy < gridY1; iy++) {
		float y = float(iy) * segmentHeight - heightHalf;
		for (uint32_t ix = 0; ix < gridX1; ix++) {

			float x = ix * segmentWidth - widthHalf;
			pos[u] = x * udir; pos[v] = y * vdir; pos[w] = depthHalf;

			carry->buffer->array.copy(idx, POSITION, (void*)pos);

			uv[0] = float(ix) / float(gridX);
			uv[1] = (1.f - (float(iy) / float(gridY)));
			carry->buffer->array.copy(idx, UV, (void*)uv);

			nor[u] = 0; nor[v] = 0; nor[w] = (depth > 0) ? 1.f : -1.f;
			carry->buffer->array.copy(idx, NORMAL, (void*)nor);


			idx++;
		}
	}
	uint32_t ret = idx;

	idx = ofs/2*3;
	for (uint32_t iy = 0; iy < gridY; iy++) {
		for (uint32_t ix = 0; ix < gridX; ix++) {

			auto a = ofs + ix + gridX1 * iy;
			auto b = ofs + ix + gridX1 * (iy + 1);
			auto c = ofs + (ix + 1) + gridX1 * (iy + 1);
			auto d = ofs + (ix + 1) + gridX1 * iy;
			carry->buffer->index.insert(carry->buffer->index.begin() + idx, { a,b,d }); idx += 3;
			carry->buffer->index.insert(carry->buffer->index.begin() + idx, { b,c,d }); idx += 3;
			
		}
	}

	return ret;
}
void generateBoxBufferGeometry(CarryAttribute* carry, PyObject* args) {

	static  unsigned Type;
	static float width, height, depth;
	uint32_t   gridX, gridY, gridZ;
	if (!PyArg_ParseTuple(args, "Ifffkkk", &Type, &width, &height, &depth, &gridX, &gridY, &gridZ)) {
		Log_bufattri("GLProgram    error Arguments");
		PyErr_BadArgument();
	};

	carry->buffer->array.alloc(6 * (gridY + 1) * (gridX + 1));

	//{ 'x':0, 'y' : 1, 'z' : 2 }

	uint32_t ofs = buildPlane(carry, 0, 2, 1, 0, -1, -1, depth, height, width, gridZ, gridY);  // px
	ofs = buildPlane(carry, ofs, 2, 1, 0, 1, -1, depth, height, -width, gridZ, gridY);  // nx
	ofs = buildPlane(carry, ofs, 0, 2, 1, 1, 1, width, depth, height, gridX, gridZ);  // py
	ofs = buildPlane(carry, ofs, 0, 2, 1, 1, -1, width, depth, -height, gridX, gridZ);  // ny
	ofs = buildPlane(carry, ofs, 0, 1, 2, 1, -1, width, height, depth, gridX, gridY);  // pz
	ofs = buildPlane(carry, ofs, 0, 1, 2, -1, -1, width, height, -depth, gridX, gridY);  // nz

	carry->buffer->Size.array = carry->buffer->array.memorySize;
	carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index.size());
	carry->buffer->Size.index = carry->buffer->updateRange.count * sizeof(uint32_t);


};

void generatePlaneBufferGeometry(CarryAttribute* carry, PyObject* args) {

	static  unsigned Type;
	static float width, height, widthSegments, heightSegments;
	if (!PyArg_ParseTuple(args, "Iffff", &Type, &width, &height, &widthSegments, &heightSegments)) {
		Log_bufattri("GLProgram    error Arguments");
		PyErr_BadArgument();
	};
	geom::generatePlaneBufferGeometry(carry, width, height, widthSegments, heightSegments, (arth::eGEOMETRY)Type);


};

static void dealloc(CarryAttribute* self)
{
	Log_bufattri(" dealloc CarryAttribute\n");

	if (self->boundingSphere != nullptr) {
		if (self->buffer->type == arth::GEOMETRY::BUFFER)delete self->boundingSphere;
	}

	if (self->buffer != nullptr) {
		self->buffer->array.dealloc();
		delete self->buffer;
	}




	if (self->frustumBuffer != nullptr) {
		delete[] self->frustumBuffer;
	}

	Log_bufattri(" dealloc Partisioner\n");
	Py_TYPE(self)->tp_free((PyObject*)self);

};

static int init(CarryAttribute* self, PyObject* args, PyObject* kwds)
{

	self->buffer->id = -1;
	self->buffer->refCnt = 0;


	size_t len = PyTuple_Size(args),count = 0;
	arth::GEOMETRY  TypeGeom = arth::GEOMETRY::ALL_GEOMETRY;
	std::vector<arth::INPUT> Struct; 

	for (int i = 0; i < len; i++) {
		if (i == 0)TypeGeom = (arth::GEOMETRY)PyLong_AsUnsignedLong(PyTuple_GetItem(args, 0));
		else if (i == 1) count = PyLong_AsUnsignedLongLong(PyTuple_GetItem(args, 1));
		else {
			arth::INPUT  type = (arth::INPUT)PyLong_AsUnsignedLongLong(PyTuple_GetItem(args, i));
			Log_bufattri("type  %zu  \n", UINT64(type));
			Struct.push_back(type);
		}
	};

	self->buffer->type = TypeGeom;
	self->buffer->idxType = VK_INDEX_TYPE_UINT32;
	self->frustumBuffer = nullptr;
	

	switch (TypeGeom) {
	case arth::GEOMETRY::BUFFER:
		self->buffer->array.set(Struct);
		Log_bufattri("BufferGeometryAttribute    Type   %u   %zu    \n", arth::ENUM_TYPE(self->buffer->array.type),count); break;
	case	arth::GEOMETRY::INSTANCED:
		self->buffer->array.set(Struct, count);
		self->buffer->Size.array = self->buffer->array.memorySize;
		///self->frustumBuffer = new char[16*count];
		Log_bufattri("InstancedBufferAttribute    Type   %u    %zu    \n", arth::ENUM_TYPE(self->buffer->array.type), count); break;
	case arth::GEOMETRY::COMPUTE:
		self->buffer->array.set(Struct, count, true);
		self->buffer->updateRange.count = count;
		Log_bufattri("ComputeBufferAttribute    Type %u    %zu ", arth::ENUM_TYPE(self->buffer->array.type), count);
	default:
		self->buffer->array.set(Struct);
		Log_bufattri("DefaultGeometryAttribute    Type   %u   %zu    \n", arth::ENUM_TYPE(self->buffer->array.type), count); break;
	}

	return 0;


};

void CarryAttribute::init(std::vector<arth::INPUT>& Struct) {


	buffer = new _BufferAttribute;
	boundingSphere = new Sphere;
	frustumBuffer = nullptr;


	buffer->array.set(Struct);
	buffer->type = arth::GEOMETRY::BUFFER;
	buffer->idxType = VK_INDEX_TYPE_UINT32;


};

PyObject* New(PyTypeObject* type, PyObject* args, PyObject* kw)
{

	int rc = -1;
	CarryAttribute* self = NULL;
	self = (CarryAttribute*)type->tp_alloc(type, 0);
	if (!self) goto error;
	rc = 0;

	self->buffer = new _BufferAttribute;
	self->boundingSphere = new Sphere;
	self->frustumBuffer = nullptr;

error:

	if (rc < 0)Py_XDECREF(self);
	Log_bufattri("New    CarryBufferAttribute   %zu   \n",self->ob_base.ob_refcnt);
	return (PyObject*)self;

};


static PyObject*
BufferAttribute_getArray(CarryAttribute* self, PyObject* idx)
{
	Log_bufattri(" Array   %zd     \n ", self->buffer->Size.array);
	Py_RETURN_NONE;
}


static const unsigned int  TRIANGLE = 0b0000;
static const unsigned int   PLANE = 0b0001;
static const unsigned int   SPHERE = 0b0010;

static PyObject* BufferAttribute_lodload(CarryAttribute* self, PyObject* args)
{

	const char* file;
	const char* target = "none";
	PyArg_ParseTuple(args, "s|s", &file,&target);
	std::string    targetName = std::string(target);
	
	/*

	FileLoader loader;
	GLTF_Loader gltf(self);

	loader.setPath(MODEL_PATH);
	loader.load(std::string(file));// onLoad);
	

	if (targetName != "none")gltf.load_lod(loader.response, targetName);
	else gltf.load_lod(loader.response);



	gltf.map_lod();

	*/


	self->buffer->version++;

	Py_RETURN_NONE;

};

static PyObject* BufferAttribute_setlod(CarryAttribute* self, PyObject* obj)
{

	Py_buffer view;

	GetByteArray(obj, view);

	if (view.len != sizeof(LODInfo)) {
		Log_bad(" your struct is not LODInfo.");
	}
	




	///(" offset     distance   %zu   \n",  (size_t)(&(((struct LODInfo*)NULL)->distance[0])));
		
	size_t ofs = (size_t)offsetof(LODInfo, distance[0]);
	
	char* ptr = (char*)(&(self->lod));
	memcpy(ptr + ofs, (char*)view.buf + ofs,   sizeof(LODInfo) - ofs);
	

	ReleaseView(view)
	Py_RETURN_NONE;

};

static PyObject* BufferAttribute_setArray(CarryAttribute* self, PyObject* args)
{
	arth::eGEOMETRY Type;
	Type = (arth::eGEOMETRY)PyLong_AsUnsignedLong(PyTuple_GetItem(args, 0));

	if __ENUM__(Type, arth::eGEOMETRY::TRIANGLE) {
		///generateTriangleBufferGeometry(self);
		generateTriangleBufferGeometry1(self);
	}
	else if  __ENUM__(Type, arth::eGEOMETRY::PLANE) {
		generatePlaneBufferGeometry(self, args);
	}
	else if  __ENUM__(Type, arth::eGEOMETRY::SPHERE){
		generateSphereBufferGeometry(self, args);
	}
	else if  __ENUM__(Type, arth::eGEOMETRY::BOX) {
		///generateCubeMapGeometry(self);
		generateBoxBufferGeometry(self, args);
	};

	if ( !__ENUM__(Type, arth::eGEOMETRY::LOD_BIT)  ) {
		self->lod.lodMax = 0;
		self->lod.firstIndex[0] = 0;
		self->lod.indexCount[0] = self->buffer->Size.index;
	}

	Log_bufattri("VkThree    setArray %u \n", Type);
	self->buffer->version++;

	Py_RETURN_NONE;
};

/*
static PyObject* BufferAttribute_setArray2(BufferAttribute* self, PyObject* args)
{

	static unsigned int Type;
	Type = PyLong_AsUnsignedLong(PyTuple_GetItem(args, 0));
	Log_bufattri("VkThree    setArray %u \n", Type);
	__BufferAttribute<vertexPUN>* buf = (__BufferAttribute<vertexPUN>*)(self->buffer->buffer);
	buf->version++;
	switch (Type)
	{
	case TRIANGLE:
		generateTriangleBufferGeometry2(buf);
		break;
	case PLANE:
		generatePlaneBufferGeometry(buf, args);
		break;
	case SPHERE:
		generateSphereBufferGeometry(buf, args);
		break;
	default:
		break;
	}

	Py_RETURN_NONE;
};
*/

static PyObject* BufferAttribute_setBounding(CarryAttribute* self, PyObject* args)
{
	CarryAttribute* geom = (CarryAttribute*)(PyTuple_GetItem(args, 0));
	self->boundingSphere = geom->boundingSphere;
	Py_RETURN_NONE;
}

static PyObject* BufferAttribute_setMatrixAt(CarryAttribute* self, PyObject* args)
{

	float f[4];

	static unsigned int idx;
	idx    = PyLong_AsUnsignedLong(PyTuple_GetItem(args, 0));
	static Vector3* _pos;
	_pos    = (Vector3*)(PyTuple_GetItem(args, 1)); 
	for (int i = 0; i < 3; i++) {
		f[i] = (float)_pos->v[i];
	};
	self->buffer->array.copy(idx, 0, (void*)f);
	///printVector4F("i_position", f);


	static Euler* rot;
	rot    = (Euler*)(PyTuple_GetItem(args, 2));
	static Quaternion q;
	q.setFromEuler(rot, false); 
	for (int i = 0; i < 4; i++) {
		f[i] = (float)q.v[i];
	};
	self->buffer->array.copy(idx, 1, (void*)f);

	static Vector3* scale;
	scale = (Vector3*)(PyTuple_GetItem(args, 3)); scale->toFloat();
	for (int i = 0; i < 3; i++) {
		f[i] = (float)scale->v[i];
	};
	self->buffer->array.copy(idx, 2, (void*)f);
	//printVector4F("i_scale", f);

	/*
	Matrix4* model = (Matrix4*)PyTuple_GetItem(args, 4);
	///Log_bufattri("Matrix model  %p \n", model);

	Matrix4 mat,_m;
	mat.compose(_pos, &q, scale);
	_m.multiplyMatrices(model, &mat);
	


	///Log_bufattri("Matrix Multiply \n");
	Vector3 v3,r3;

	self->buffer->array.Log_o3dloatStruct(idx);
	printMatrix4("compose", mat.elements);
	printMatrix4("model", model->elements);
	Log_bufattri("Bounding   [ ");
	for (int i = 0; i < 3; i++) {
		f[i] = (float)self->boundingSphere->_center->v[i];
		Log_bufattri("  %.5f   ", f[i]);
	};
	Log_bufattri("  %.5f   ]\n", (float)self->boundingSphere->_radius);
	


	v3.copy(self->boundingSphere->_center)->applyMatrix4(&_m);
	r3.copy(self->boundingSphere->_center);
	r3.x += self->boundingSphere->_radius;
	r3.applyMatrix4(&_m);
	///Log_bufattri("Matrix Bounding \n");

	///Log_bufattri("Matrix x Bounding   [ ");
	for (int i = 0; i < 3; i++) {
		f[i] = (float)v3.v[i];
		///Log_bufattri("  %.5f   ", f[i]);
	};
	f[3]  = (float)v3.distanceTo(&r3);
	///Log_bufattri("  %.5f   ]\n", f[3]);
	

	//UINT64 ofs =  (UINT64)idx * 16;

	///Log_trace("Memcpy   %p \n", self->frustumBuffer);
	//memcpy(self->frustumBuffer + ofs, f, 16);



	self->buffer->array.v4.copy((void*)(&pos->f[0]));
	self->buffer->array.v4.Log_o3dloat();
	self->buffer->array.v4.copy((void*)(&pos->f[1]));
	self->buffer->array.v4.Log_o3dloat();
	self->buffer->array.v4.copy((void*)(&pos->f[2]));
	self->buffer->array.v4.Log_o3dloat();
	Log_o3d(" pos  [0] %f  pos [1] %f pos [2] %f   \n", pos->f[0], pos->f[1], pos->f[2]);
	*/

	Py_RETURN_NONE;

};

static PyObject* BufferAttribute_setMatrixAt2(CarryAttribute* self, PyObject* args)
{

	float f[4];

	unsigned int idx;
	idx = PyLong_AsUnsignedLong(PyTuple_GetItem(args, 0));
	
	Vector3* _pos;
	_pos = (Vector3*)(PyTuple_GetItem(args, 1));
	for (int i = 0; i < 3; i++) {
		f[i] = (float)_pos->v[i];
	};

	f[3]  =  (float)PyFloat_AsDouble(PyTuple_GetItem(args, 2));
	
	self->buffer->array.copy(idx, 0, (void*)f);

	Color* col;

	col = (Color*)(PyTuple_GetItem(args, 3));
	self->buffer->array.copy(idx, 1, (void*)col->v);



	/*
   Matrix4* model = (Matrix4*)PyTuple_GetItem(args, 4);
	///Log_bufattri("Matrix model  %p \n", model);

	Vector3 scale;
	scale.v[0] = scale.v[1] = scale.v[2] = (double)f[3];
	Quaternion q;

	Matrix4 mat, _m;
	mat.compose(_pos, &q, &scale);
	_m.multiplyMatrices(model, &mat);

	Vector3 v3, r3;
	v3.copy(self->boundingSphere->_center)->applyMatrix4(&_m);
	r3.copy(self->boundingSphere->_center);
	r3.x += self->boundingSphere->_radius;
	r3.applyMatrix4(&_m);

	for (int i = 0; i < 3; i++) {
		f[i] = (float)v3.v[i];
	};
	f[3] = (float)v3.distanceTo(&r3);
	UINT64 ofs = (UINT64)idx * 16;
	memcpy(self->frustumBuffer + ofs, f, 16);
	*/

	Py_RETURN_NONE;

};


static PyObject*
BufferAttribute_getNeedsUpdate(CarryAttribute* self, void* closure)
{

	return PyBool_FromLong(long(self->buffer->needsUpdate));
}

static int
BufferAttribute_setNeedsUpdate(CarryAttribute* self, PyObject* value, void* closure)
{
	self->buffer->needsUpdate = (PyLong_AsLong(value) == 0) ? false : true;
	if (self->buffer->needsUpdate)self->buffer->version++;

	return 0;
}

static PyObject*
BufferAttribute_getArraySize(CarryAttribute* self, void* closure)
{

	return PyLong_FromUnsignedLong(self->buffer->array.arraySize);    
}

static PyObject*
BufferAttribute_getSizeIndex(CarryAttribute* self, void* closure)
{

	return PyLong_FromUnsignedLong(self->buffer->Size.index);
}

static PyObject*
BufferAttribute_getSizeStruct(CarryAttribute* self, void* closure)
{

	return PyLong_FromUnsignedLongLong(self->buffer->array.structSize);
}

static PyObject*
BufferAttribute_getSizeMemory(CarryAttribute* self, void* closure)
{

	return PyLong_FromUnsignedLongLong(self->buffer->array.memorySize);
}

static PyObject*
BufferAttribute_getName(CarryAttribute* self, void* closure)
{
	return   PyUnicode_FromString(self->buffer->name.c_str());
}

static int
BufferAttribute_setName(CarryAttribute* self, PyObject* value, void* closure)
{
	char* name;
	PyArg_Parse(value, "s", &name);
	self->buffer->name = std::string(name);
	return 0;
}

static PyObject*
getCtype(CarryAttribute* self, void* closure)
{
	Py_INCREF(self);
	return  (PyObject*)(self);
}


static PyGetSetDef BufferAttribute_getsetters[] = {
	{(char*)"needsUpdate", (getter)BufferAttribute_getNeedsUpdate,(setter)BufferAttribute_setNeedsUpdate,0,0},
	{(char*)"bufferName", (getter)BufferAttribute_getName,(setter)BufferAttribute_setName,0,0},
	{(char*)"sizeMemory", (getter)BufferAttribute_getSizeMemory,0,0,0},
	{(char*)"sizeStruct", (getter)BufferAttribute_getSizeStruct,0,0,0},
	{(char*)"sizeArray", (getter)BufferAttribute_getArraySize,0,0,0},
	{(char*)"sizeIndex", (getter)BufferAttribute_getSizeIndex,0,0,0},
	{(char*)"_", (getter)getCtype,0,0,0},
	{0},
};


static PyMethodDef MethodDef[] = {

			{"setLodInfo", (PyCFunction)BufferAttribute_setlod, METH_O, "set LodInfo struct."},
	        {"load_lod", (PyCFunction)BufferAttribute_lodload, METH_VARARGS, "loadFromFile :(string)"},
		    {"setArray", (PyCFunction)BufferAttribute_setArray, METH_VARARGS, "set array:(list,int,bool)"},
			{"getArray", (PyCFunction)BufferAttribute_getArray, METH_NOARGS, 0},
			{"setMatrixAt",  (PyCFunction)BufferAttribute_setMatrixAt, METH_VARARGS, "ARGS (int index,Vector3 pos, Euler rot,Vector3 scale)"},
			{"setMatrixAt2", (PyCFunction)BufferAttribute_setMatrixAt2, METH_VARARGS, "ARGS (int index,Vector3 pos, Size size,Color color)"},
			{"setBounding", (PyCFunction)BufferAttribute_setBounding, METH_VARARGS, "ARGS()"},
			{0}, 
};


PyTypeObject tp_BufferAttribute = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.CarryBufferAttribute";
	type.tp_doc   = "CarryBufferAttribute objects";
	type.tp_basicsize = sizeof(CarryAttribute);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = (newfunc)New;
	type.tp_init = (initproc)init;
	type.tp_methods = MethodDef,
	type.tp_dealloc = (destructor)dealloc;
	type.tp_getset = BufferAttribute_getsetters;
	return type;
}();


int _AddType_BufferAttribute(PyObject* m, const char* name) {


	if (PyType_Ready(&tp_BufferAttribute) < 0)
		return -1;

	Py_XINCREF(&(tp_BufferAttribute));
	PyModule_AddObject(m, name, (PyObject*)&tp_BufferAttribute);

	return 0;
};

int AddType_BufferAttribute(PyObject* m) {
	if (_AddType_BufferAttribute(m, "CarryBufferAttribute") != 0)return -1;
	return 0;
};


