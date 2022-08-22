#pragma once
#ifndef  GROUP_VK_TYPES
#define  GROUP_VK_TYPES


#include "enum.hpp"
#include "types.hpp"
#include "util/log.hpp"

#ifdef  LOG_NO_gr
#define log_gr(...)
#else
#define log_gr(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif


#include "ext/nvMeshlet.h"
#include "core/common.hpp"
#include "scene/group.h"
#include "aeolus/materialsVk/common.h"
#include "working.h"


struct  QuarterMaster {
	QuarterMaster() {};

};

struct LayoutBuffer {

	VisibleObjectsVk* vobjVk;
	DescriptorVk* descVk;

	std::unordered_map<size_t, Bache> Ref;
	LayoutBuffer();
	~LayoutBuffer();

	template<class M>
	bool Allocate(M* mat) {

		long hash = mat->desc.hash;
		Bache& bach = Ref[hash];

		if (bach.reqSize == 0 && bach.refCnt > 0) {

			bach.size = (long)(bach.align * bach.refCnt * mat->desc.reserveRatio);
			vobjVk->$createBuffer$(bach);
			log_gr("QuarterMaster  UBO  memory Allocate  align %zu    refCnt %d   reserveRaio %.4f  \n ", bach.align, bach.refCnt, mat->desc.reserveRatio);
			MIBmvk _;
			vobjVk->get(_, &bach.buffer);
			bach.vkBuffer = _.buffer;
			return true;
		}

		return false;

	};

	bool DeAllocateAll();

	template<class T>
	void init(T& desc) {

		Bache b(desc.hash, desc.align, desc.type);
		Ref[desc.hash] = b;
		log_gr("QuarterMaster  %x   Init   hash  %zu  align %zu    \n ", this, Ref[desc.hash].buffer.hash, Ref[desc.hash].align);
		InitializeSRWLock(&Ref[desc.hash].excl);

	};

	template<class T>
	long  Borrow(T* obj  , LayoutType type ,std::vector<VkDescriptorSetLayoutBinding> dslb, bool appendLayout = false) {


		long hash = ((aeo::Material*)obj->material)->desc.hash;
		Bache& bach = Ref[hash];

		if (bach.reqSize < ((obj->uniform->ubo.id + 1) * bach.align))log_bad("Can't lend you  becourse of no reservation.\n");
		obj->uniform->swID = 0;
		obj->uniform->setMaterialProperty(&bach);
		obj->uniform->setUBO(bach.vkBuffer);

		if(dslb.size()==0)obj->uniform->createSet(descVk, type,appendLayout);
		else obj->uniform->createSet(descVk, type, dslb,appendLayout);

		///log_gr("UBO  create set and layout  MAP %x - %x  \n", bach.mapped, obj->uniform->ubo.mapped);

		return  0;

	};

	template<class T>
	long  Pay(T* obj) {

		long hash = ((aeo::Material*)obj->material)->desc.hash;
		if (hash != 0) {
			Bache& bach = Ref[hash];
			bach.Undo(obj->uniform->ubo);
			return true;
		};

		return false;
	};

	template<class T>
	long  Counting(T& desc) {
		if (Ref.count(hashLB(desc)) <= 0) {
			desc.hash = hashLB(desc);
			init(desc);
		}
		return  InterlockedAdd(&Ref[desc.hash].refCnt, 1) - 1;
	};

	template<class T>
	size_t hashLB(T const& s) noexcept
	{
		size_t h = 0;
		std::string type = s.type.data();
		size_t  i = 0;
		for (char t : s.type) {
			h |= (size_t(t) - 115) << i * 2;
		};
		h |= (s.align << 16);

		return h;
	};

};

struct VertexBuffer {

	ObjectsVk* objVk;
	ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk;

	VertexBuffer();


	template<class T>
	long  Borrow(T* obj) {

		_BufferAttribute* buf = obj->geometry->attributes->buffer;
		long ref = InterlockedAdd(&buf->refCnt, 1);
		if (ref == 1)obj->geometry->attributes->buffer->id = -1;
		if (ref <= 0)log_bad("Borrower is not positive.\n");

		return  ref;

	};

	template<class T>
	long  Pay(T* obj) {

		_BufferAttribute* buf = obj->geometry->attributes->buffer;
		long last = InterlockedDecrement(&buf->refCnt);
		if (last == 0) {
			objVk->Delete(buf);
			log_gr(" QuarterMaster[%x]::   Owner-geometry [%x] has   no  last of pay.    Delete vkBuffer  & vkMemory   \n", this, buf);
		};
		if (last < 0)log_bad("Borrower is not positive.\n");
		return last;
	};


};

struct MeshMaterialVk;
struct LodMaterialVk;

struct MeshletBuffer {


	ObjectsVk*    objVk = nullptr;
	ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk;

	
	bool   float16,uint16;

	struct _Cahce{

		Mache          mem;
		TexBache     vert;
		TexBache     attr;
		TexBache     index;
		StoBache    mesh;
	}cache;

	struct  _Size {
		VkDeviceSize      vert;
		VkDeviceSize      attr;
		VkDeviceSize    index;
		VkDeviceSize     mesh;
	}Size;


	NVMeshlet::Builder<uint32_t> meshletBuilder;
	//NVMeshlet::Builder<uint16_t> meshletBuilder;
	//MeshletBuffer();
	~MeshletBuffer();




	template<class Attr>
	void init(Attr& attr,long vertexCount= 64,long primCount= 126) {

		meshletBuilder.setup(vertexCount, primCount);

		const VkDeviceSize                 maxChunk = 512 * 1024 * 1024;

		float16 = attr.array.float16;

		VkPhysicalDeviceProperties properties;
		vkGetPhysicalDeviceProperties($physicaldevice, &properties);
		VkPhysicalDeviceLimits& limits = properties.limits;

		_alignment =  __max(limits.minTexelBufferOffsetAlignment, limits.minStorageBufferOffsetAlignment);
		// to keep vbo/abo "parallel" to each other, we need to use a common multiple
		// that means every offset of vbo/abo of the same sub-allocation can be expressed as "nth vertex" offset from the buffer

		VkDeviceSize multiple = 1;
		
		while (true)
		{
			if (((multiple * attr.array.vertSize) % _alignment == 0) && ((multiple * attr.array.attrSize) % _alignment == 0))
			{
				break;
			}
			multiple++;
		};

		_vboAlignment = multiple * attr.array.vertSize;
		_aboAlignment = multiple * attr.array.attrSize;

		// buffer allocation
		// costs of entire model, provide offset into large buffers per geometry
		VkDeviceSize tboSize = limits.maxTexelBufferElements;

		const VkDeviceSize vboMax = VkDeviceSize(tboSize) * sizeof(float) * 4;
		const VkDeviceSize iboMax = VkDeviceSize(tboSize) * sizeof(uint16_t);
		const VkDeviceSize meshMax = VkDeviceSize(tboSize) * sizeof(uint16_t);

		_maxVboChunk      =  __min(vboMax, maxChunk);
		_maxIboChunk      =  __min(iboMax, maxChunk);
		_maxMeshChunk   =  __min(meshMax, maxChunk);


		Size = { 0,0,0,0 };

		objVk = nullptr;
		if (!$tank.takeout(objVk, 0)) {
				log_bad(" not found  objVk.");
		};



	}

	template<class M>
	bool Allocate(M* mat) {

		long hash = mat->hash;
		mat->hash = 123;
		log_gr("Material  Hash  %zu  \n", hash);

		cache.mem.mem         = { .id = -1,.version = 0 };
		cache.mem.id             = -1;
		cache.mem.sizeSet = { Size.vert , Size.attr , Size.index ,Size.mesh };

		objVk->$AllocMemory$(*cmdVk, cache.mem);

		Mvk Mem;
		objVk->getMemory(Mem,cache.mem.mem);


		VkBufferUsageFlags flags = VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT;

		cache.vert.id    = -1;
		cache.vert.offset = cache.mem.sizeSet[0];
		cache.vert.size = Size.vert;
		cache.vert.format = float16 ? VK_FORMAT_R16G16B16A16_SFLOAT : VK_FORMAT_R32G32B32A32_SFLOAT;
		objVk->$createDeviceBufferSeparate$(cache.vert,  Mem.memory, VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | flags);
		objVk->createBufferView(cache.vert);

		cache.attr.id = -1;
		cache.attr.offset = cache.mem.sizeSet[1];
		cache.attr.size = Size.attr;
		cache.attr.format = float16 ? VK_FORMAT_R16G16B16A16_SFLOAT : VK_FORMAT_R32G32B32A32_SFLOAT;
		objVk->$createDeviceBufferSeparate$(cache.attr, Mem.memory, VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | flags);
		objVk->createBufferView(cache.attr);

		cache.index.id = -1;
		cache.index.offset = cache.mem.sizeSet[2];
		cache.index.size = Size.index;
		cache.index.format = uint16 ? VK_FORMAT_R16_UINT : VK_FORMAT_R32_UINT;
		objVk->$createDeviceBufferSeparate$(cache.index, Mem.memory, VK_BUFFER_USAGE_INDEX_BUFFER_BIT | flags);
		objVk->createBufferView(cache.index);



		cache.mesh.id = -1;
		cache.mesh.offset = cache.mem.sizeSet[3];
		cache.mesh.size = Size.mesh;
		cache.mesh.format = uint16 ? VK_FORMAT_R16_UINT : VK_FORMAT_R32_UINT;
		objVk->$createDeviceBufferSeparate$(cache.mesh, Mem.memory, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT );
		///objVk->createBufferView(cache.mesh);
		/*
		chunk.vert16View =
			nvvk::createBufferView(m_device, nvvk::makeBufferViewCreateInfo(chunk.mesh, VK_FORMAT_R16_UINT, chunk.meshSize));
		chunk.vert32View =
			nvvk::createBufferView(m_device, nvvk::makeBufferViewCreateInfo(chunk.mesh, VK_FORMAT_R32_UINT, chunk.meshSize));
			*/


		/*
		auto& bindingsScene = setup.container.at(DSET_SCENE);

		bindingsScene.addBinding(SCENE_UBO_VIEW, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1,
			VK_SHADER_STAGE_MESH_BIT_NV | VK_SHADER_STAGE_TASK_BIT_NV | VK_SHADER_STAGE_FRAGMENT_BIT, 0);
		bindingsScene.addBinding(SCENE_SSBO_STATS, VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1, stageTask | stageMesh, 0);
	

		auto& bindingsObject = setup.container.at(DSET_OBJECT);
		bindingsObject.addBinding(0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, 1,
			VK_SHADER_STAGE_MESH_BIT_NV | VK_SHADER_STAGE_TASK_BIT_NV | VK_SHADER_STAGE_FRAGMENT_BIT, 0);
			*/

		return true;

	};

	bool DeAllocateAll();

	
	void writeout(std::vector<VkWriteDescriptorSet> write) {

		assert(write.size() == 7);

		write[4].pTexelBufferView = &cache.index.vkView;
		write[5].pTexelBufferView = &cache.vert.vkView;
		write[6].pTexelBufferView = &cache.attr.vkView;
		   
		vkUpdateDescriptorSets($device, static_cast<uint32_t>(write.size()), write.data(), 0, nullptr);

	};

	template<class T>
	void map(T& obj) {


		MeshMaterialVk* mat =  static_cast<MeshMaterialVk*>(obj.material);
		if (mat->hash == -1) {
			Allocate(mat);
		}

		_BufferAttribute& geom = *obj.geometry->attributes->buffer;
		if (geom.meshlet.mapped)return;



		geom.info.vert.buffer = cache.vert.vkBuffer;
		geom.info.vert.range  = geom.array.vertSize * geom.array.arraySize;

		objVk->$BridgeMapBuffer$(*cmdVk, geom.info.vert, geom.array.data);


		geom.info.attr.buffer = cache.attr.vkBuffer;
	    geom.info.attr.range = geom.array.attrSize * geom.array.arraySize;

		objVk->$BridgeMapBuffer$(*cmdVk, geom.info.attr, geom.array.data + geom.info.vert.range);
		


		void* data = (geom.idxType == VK_INDEX_TYPE_UINT16)? (void*)geom.index_short.data() : (void*)geom.index.data() ;
		geom.info.index.range = (geom.idxType == VK_INDEX_TYPE_UINT16) ? geom.index_short.size() : geom.index.size();
		geom.info.index.buffer = cache.index.vkBuffer;
		objVk->$BridgeMapBuffer$(*cmdVk, geom.info.index, data);


	
		VkDescriptorBufferInfo& info = geom.meshlet.info.desc;

		info.buffer    =  cache.mesh.vkBuffer;
		info.range     =   geom.meshlet.descSize;

		objVk->$BridgeMapBuffer$(*cmdVk, info, geom.meshlet.descData );

		VkDescriptorBufferInfo& info2 = geom.meshlet.info.prim;

		info2.buffer = cache.mesh.vkBuffer;
		info2.offset =  info.offset + NVMeshlet::computeCommonAlignedSize(geom.meshlet.descSize);
		info2.range  = geom.meshlet.primSize;

		objVk->$BridgeMapBuffer$(*cmdVk, info2, geom.meshlet.primData);


		VkDescriptorBufferInfo& info3 = geom.meshlet.info.vert;

		info3.buffer  = cache.mesh.vkBuffer;
		info3.offset  =  info2.offset   + NVMeshlet::computeCommonAlignedSize(geom.meshlet.primSize);
		info3.range   = geom.meshlet.vertSize;

		objVk->$BridgeMapBuffer$(*cmdVk, info3, geom.meshlet.vertData);

		geom.meshlet.mapped = true;

	};

	template<class T>
	long  Cummulative(T& obj) {

		_BufferAttribute& desc = *obj.geometry->attributes->buffer;
		if (desc.id != -1) return 0;

		
		desc.info.vert.offset = Size.vert;
		Size.vert  += alignedSize(desc.array.arraySize * desc.array.vertSize, _vboAlignment);

		desc.info.attr.offset = Size.attr;
		Size.attr  += alignedSize(desc.array.arraySize * desc.array.attrSize, _aboAlignment);

		desc.info.index.offset = Size.index;
		Size.index += alignedSize((desc.idxType == VK_INDEX_TYPE_UINT16) ? desc.index_short.size() : desc.index.size(), _alignment);

		///meshSize = alignedSize(meshSize, m_alignment);
		buildMeshletTopology(obj);


		desc.meshlet.uniform = new UniformVk;
		desc.meshlet.des->set([uniform = std::move(desc.meshlet.uniform)](void* no) mutable{
			if (uniform != nullptr) {
				types::deleteRaw(uniform);
				uniform = nullptr;
			};
			return 1;
		});

		auto mat = (MeshMaterialVk*)obj.material;
		bool appendLayout = (mat->descVk->layoutSet.size() != 3);


		if (mat->mode == MeshMaterialVk::eConfigu_PIPE::MODE_BBOX) {
			desc.meshlet.uniform->createSet(mat->descVk,"mesh2"sv, {
			{
		 .binding = 0,
		 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		 .descriptorCount = 1,
		 .stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
		 .pImmutableSamplers = NULL
			},
			{
		 .binding = 1,
		 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		 .descriptorCount = 1,
		  .stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
	     },
			{
		 .binding = 2,
		 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
		 .descriptorCount = 1,
		  .stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
		 .pImmutableSamplers = NULL
	},
			{
		 .binding = 3,
		 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
		 .descriptorCount = 1,
		  .stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
		 .pImmutableSamplers = NULL
	},
			{
		 .binding = 4,
		 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
		 .descriptorCount = 1,
		 .stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
		 .pImmutableSamplers = NULL
	},
				}, appendLayout
				);
		}
		else if (mat->mode == MeshMaterialVk::eConfigu_PIPE::MODE_TASK_MESH) {
			desc.meshlet.uniform->createSet(mat->descVk, "meshtask2"sv,{
				{
			 .binding = 0,
			 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			 .descriptorCount = 1,
			 .stageFlags = VK_SHADER_STAGE_MESH_BIT_NV | VK_SHADER_STAGE_TASK_BIT_NV,
			 .pImmutableSamplers = NULL
		},
				{
			 .binding = 1,
			 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			 .descriptorCount = 1,
			 .stageFlags = VK_SHADER_STAGE_MESH_BIT_NV,
			 .pImmutableSamplers = NULL
		},
				{
			 .binding = 2,
			 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
			 .descriptorCount = 1,
			 .stageFlags = VK_SHADER_STAGE_MESH_BIT_NV,
			 .pImmutableSamplers = NULL
		},
				{
			 .binding = 3,
			 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
			 .descriptorCount = 1,
			 .stageFlags = VK_SHADER_STAGE_MESH_BIT_NV,
			 .pImmutableSamplers = NULL
		},
				{
			 .binding = 4,
			 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
			 .descriptorCount = 1,
			 .stageFlags = VK_SHADER_STAGE_MESH_BIT_NV,
			 .pImmutableSamplers = NULL
		},
				}, appendLayout);
		}

		desc.id  = 54321;

		return 0;
	};

	size_t fillIndexBuffer(int useShorts, const std::vector<unsigned int>& vertexindices, void*& storage)
	{
		size_t vidxSize;

		if (useShorts)
		{
			vidxSize = sizeof(uint16_t) * vertexindices.size();

			uint16_t* vertexindices16 = (uint16_t*)malloc(vidxSize);
			for (size_t i = 0; i < vertexindices.size(); i++)
			{
				vertexindices16[i] = vertexindices[i];
			}

			storage = vertexindices16;
		}
		else
		{
			vidxSize = sizeof(uint32_t) * vertexindices.size();

			uint32_t* vertexindices32 = (uint32_t*)malloc(vidxSize);
			memcpy(vertexindices32, vertexindices.data(), vidxSize);

			storage = vertexindices32;
		}

		return vidxSize;
	}

	void fillMeshletTopology(NVMeshlet::Builder<uint32_t>::MeshletGeometry& geometry, MeshletTopology& topo, int useShorts)
	{
		if (geometry.meshletDescriptors.empty())
			return;

		topo.vertSize = fillIndexBuffer(useShorts, geometry.vertexIndices, topo.vertData);

		topo.descSize = sizeof(NVMeshlet::MeshletDesc) * geometry.meshletDescriptors.size();
		topo.primSize = sizeof(NVMeshlet::PrimitiveIndexType) * geometry.primitiveIndices.size();

		///DEBUG MESHLET
		topo.primSize = 15000 * 4;

		topo.descData = malloc(topo.descSize);
		topo.primData = malloc(topo.primSize);

		memcpy(topo.descData, geometry.meshletDescriptors.data(), geometry.meshletDescriptors.size() * sizeof(NVMeshlet::MeshletDesc));
		memcpy(topo.primData, geometry.primitiveIndices.data(), geometry.primitiveIndices.size()* sizeof(NVMeshlet::PrimitiveIndexType));
	}

	template<class T>
	void buildMeshletTopology(T& obj)
	{

		_BufferAttribute& geom = *obj.geometry->attributes->buffer;
		typedef   uint32_t indexType;
		bool verbose   = true;
		bool useShort = uint16 = (geom.idxType  == VK_INDEX_TYPE_UINT16);

		NVMeshlet::Stats statsGlobal;

		NVMeshlet::Builder<uint32_t>::MeshletGeometry meshletGeometry;
		uint32_t numMeshlets  = 0;
		uint32_t indexOffset   = 0;
		uint32_t numIndex = uint32_t( (useShort) ? geom.index_short.size() : geom.index.size());

		indexType* data = geom.index.data();

		///geom.parts[p].meshSolid.offset = numMeshlets;

		uint32_t processedIndices  = meshletBuilder.buildMeshlets(meshletGeometry, numIndex, data);
		if (processedIndices != numIndex)
		{
			log_bad("warning: geometry meshlet incomplete   procNum %u <==>  indexNum %u   \n", processedIndices, numIndex);
		};

		///uint32_t meshletCount = (uint32_t)meshletGeometry.meshletDescriptors.size() - numMeshlets;
		numMeshlets = (uint32_t)meshletGeometry.meshletDescriptors.size();
		indexOffset += numIndex;

		meshletBuilder.buildMeshletEarlyCulling(meshletGeometry, geom.bbox.mn.f, geom.bbox.mx.f, (float*)geom.array.data,sizeof(float) * 3);

		if (verbose)
		{
			NVMeshlet::Stats statsLocal;
			meshletBuilder.appendStats(meshletGeometry, statsLocal);
			statsGlobal.append(statsLocal);
		};

		fillMeshletTopology(meshletGeometry, geom.meshlet, useShort);

		

		geom.Size.mesh = uint32_t(NVMeshlet::computeCommonAlignedSize(geom.meshlet.descSize)
			+ NVMeshlet::computeCommonAlignedSize(geom.meshlet.primSize)
			+ NVMeshlet::computeCommonAlignedSize(geom.meshlet.vertSize));

	
		geom.meshlet.info.desc.offset = Size.mesh;
		Size.mesh += (VkDeviceSize)geom.Size.mesh;
		geom.meshlet.numMeshlets  =  numMeshlets;
	    //log_gr("meshlet config: %d vertices, %d primitives\n", m_cfg.meshVertexCount, m_cfg.meshPrimitiveCount);
		if (verbose)
		{
			statsGlobal.fprint(stdout);
		}

		log_gr("meshlet total: %d\n", numMeshlets);

	}


	template<class T>
	size_t hashTB(T const& s) noexcept
	{
		size_t h = 0;
		std::string type = s.type.data();
		size_t  i = 0;
		for (char t : s.type) {
			h |= (size_t(t) - 115) << i * 2;
		};
		h |= (s.align << 16);

		return h;
	};

	VkDeviceSize _alignment;
	VkDeviceSize _vboAlignment;
	VkDeviceSize _aboAlignment;
	VkDeviceSize _maxVboChunk;
	VkDeviceSize _maxIboChunk;
	VkDeviceSize _maxMeshChunk;

};

struct LodBuffer {

	typedef  long InstaIndexTy;
	const  long InstaTypeNums = 1;

	enum eVIS_TYPE {
		   INSTANCE_RATE,
		   TEX_BUFFER,
		   TEX_BUFFER2,
		   IMG_BUFFER
	}vis_type;

	bool      STATIS;
	bool      TEX_MAP;
	size_t  SubGroup;
	size_t  InstaSize;
	size_t  BatchSize;

	struct DrawArrays {
		uint32_t  count;
		uint32_t  instanceCount;
		uint32_t  first;
		uint32_t  baseInstance;
	};

	struct DrawElements {
		uint32_t  count;
		uint32_t  instanceCount;
		uint32_t  first;
		uint32_t  baseVertex;
		uint32_t  baseInstance;
		uint32_t _pad[2];
	};

	struct DrawCounters {
		uint32_t  farCnt;
		uint32_t  medCnt;
		uint32_t  nearCnt;
		uint32_t  _pad;
	};

	struct StatsLod {
		uint32_t    u;
		int     i;
		float  f1;
		float  f2;
	};


	struct mapStat {
		float           trans[16];
		uint32_t           frame;
		float      PointSize;
		float            padd[2];
	};


	ObjectsVk* objVk = nullptr;
	VisibleObjectsVk* vobjVk = nullptr;
	ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk;
	OVR* ovr = nullptr;

	VkDeviceSize _alignment;
	VkDeviceSize _structAlignment, _inindexAlignment;
	VkDeviceSize _maxStructChunk, _maxInIndexChunk;

	bool   float16, uint16;

	struct _Cahce {
		bool              allo;
		Mache          mem;
		TexBache     insta;
		TexBache     inindex;
		TexBache     inindex2;
		TexBache     inindex3;
		StoBache     cmd;
		StoBache     cmd2;
		StoBache     cmd3;
		StoBache     counter;
		StoBache     stats;
		VkDescriptorImageInfo instatex;

	}cache;

	struct  _Size {
		VkDeviceSize      insta;
		VkDeviceSize      nums;
		VkDeviceSize      counter;
		VkDeviceSize      cmd;
		VkDeviceSize      stats;
	}Size;


	VkDescriptorSetLayoutBinding Set0 = {
.binding = 0,
.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
.descriptorCount = 1,
.stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_COMPUTE_BIT ,
.pImmutableSamplers = NULL
	};
	VkDescriptorSetLayoutBinding Set1 = {
.binding = 0,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = 1,
.stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_COMPUTE_BIT ,
.pImmutableSamplers = NULL
	};
	VkDescriptorSetLayoutBinding Set2[2] = {
		{
				 .binding = 0,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
				.descriptorCount = 1,
				.stageFlags = VK_SHADER_STAGE_VERTEX_BIT,
				.pImmutableSamplers = NULL
		},
	   {
	 .binding = 1,
	 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
	 .descriptorCount = 1,
	 .stageFlags = VK_SHADER_STAGE_VERTEX_BIT ,
	 .pImmutableSamplers = NULL
	},
	};
	VkDescriptorSetLayoutBinding CSet2[3] = {
				{
					.binding = 0,
						.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
						.descriptorCount = 1,
						.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT,
						.pImmutableSamplers = NULL
				},
			   {
				 .binding = 1,
				 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				 .descriptorCount = 1,
				 .stageFlags = VK_SHADER_STAGE_COMPUTE_BIT ,
				 .pImmutableSamplers = NULL
				},
				{
				 .binding = 2,
				 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				 .descriptorCount = 1,
				 .stageFlags = VK_SHADER_STAGE_COMPUTE_BIT ,
				 .pImmutableSamplers = NULL
				} 
	};


	std::vector<Object3D*>      child;

	~LodBuffer();

	template<class Attr>
	void init(Attr& attr) {

		//vis_type = eVIS_TYPE::TEX_BUFFER;
		//vis_type  = eVIS_TYPE::INSTANCE_RATE;

		vis_type = eVIS_TYPE::TEX_BUFFER2;
		float16    = false;// attr.array.float16;
		STATIS = false;
		TEX_MAP = true;

		const VkDeviceSize                 maxChunk = 512 * 1024 * 1024;

		VkPhysicalDeviceProperties properties;
		vkGetPhysicalDeviceProperties($physicaldevice, &properties);
		VkPhysicalDeviceLimits& limits = properties.limits;

		_alignment = __max(limits.minTexelBufferOffsetAlignment, limits.minStorageBufferOffsetAlignment);
		VkDeviceSize multiple = 1;

		while (true)
		{
			if( ( (multiple * attr.array.structSize) % _alignment == 0) && ((multiple * sizeof(InstaIndexTy)) % _alignment == 0) )
			{
				break;
			}
			multiple++;
		};

		_structAlignment  = multiple * attr.array.structSize;
		_inindexAlignment = multiple * sizeof(InstaIndexTy);

		VkDeviceSize tboSize = limits.maxTexelBufferElements;

		const VkDeviceSize structMax = VkDeviceSize(tboSize) * attr.array.structSize;
		_maxStructChunk = __min(structMax, maxChunk);

		const VkDeviceSize  iiMax = VkDeviceSize(tboSize) * sizeof(InstaIndexTy);
		_maxInIndexChunk = __min(iiMax, maxChunk);

		/*
		const VkDeviceSize iboMax = VkDeviceSize(tboSize) * sizeof(uint16_t);
		_maxIboChunk = __min(iboMax, maxChunk);
		*/

		Size = { 0 ,0,0,0};

		objVk = nullptr;

	}


	template<class M>
	bool arangeLayoutSet(M* lod, UniformVk* uni) {

		eVIS_TYPE TYPE;
		auto Mode = lod->mode;
		if (Mode == M::eConfigu_MODE::MODE_TEXEL) {
			vis_type = eVIS_TYPE::TEX_BUFFER2;
		}
		else if (Mode == M::eConfigu_MODE::MODE_INSTATEX) {
			vis_type = eVIS_TYPE::IMG_BUFFER;
			static ImagesVk* imgVk = nullptr;
			if (imgVk == nullptr) {
				if (!$tank.takeout(imgVk, 0)) {
					log_bad(" not found  ImagesVk.");
				};
			};
			MIVSIvk  _;
			if (!imgVk->getImage(lod->iach, _)) {
				log_bad("Not Found Instanced Map Texture.\n");
			};

			cache.instatex.imageView    = _.view;
			cache.instatex.sampler        = _.sampler;
			cache.instatex.imageLayout = _.Info.imageLayout;

		};


		bool draft = (lod->descVk->layoutSet.size() == 0);
		static const  LayoutType  set0 = "lodSet0"sv;
		static const  LayoutType  set1 = "lodSet1"sv;
		static const  LayoutType  set20 = "lodSet20"sv;
		static const  LayoutType  set21 = "lodSet21"sv;

		std::vector<VkDescriptorSetLayoutBinding > Set(1);
		
		if (vis_type == eVIS_TYPE::TEX_BUFFER2 || vis_type == eVIS_TYPE::IMG_BUFFER) {
			Set0.stageFlags |= VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT | VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT;
		};
		Set[0] = Set0;
		assert(0 == uni->createSet(lod->descVk, set0, Set, draft));
		if (draft)assert(0 == lod->cdescVk->$createLayout$(set0, Set));

		

		if (vis_type == eVIS_TYPE::INSTANCE_RATE) {
			Set[0] = Set1;
			assert(1 == uni->createSet(lod->cdescVk, set1, Set, draft));
			Set[0] = CSet2[0];
			assert(2 == uni->createSet(lod->cdescVk, set21, Set, draft));
		}
		else if (vis_type == eVIS_TYPE::TEX_BUFFER) {
			Set[0] = Set1;
			assert(1 == uni->createSet(lod->cdescVk, set1, Set, draft));
			//if(draft)assert(1 == lod->descVk->$createLayout$(set1, Set));
			Set.resize(3);
			Set[0] = CSet2[0];	Set[1] = CSet2[1];  Set[2] = CSet2[2];

			if (STATIS) { Set1.binding = 3; Set.push_back(Set1); }
			assert(2 == uni->createSet(lod->cdescVk, set21, Set, draft));

			Set.resize(2);
			Set[0] = Set2[0];	Set[1] = Set2[1];

			if (STATIS) { Set1.binding = 2; Set.push_back(Set1); }
			assert(3 == uni->createSet(lod->descVk, set20, Set, draft));


		}
		else if (vis_type == eVIS_TYPE::TEX_BUFFER2) {

			Set.resize(3);
			Set[0] = Set1; Set[1] = Set1; Set[1].binding = 1; Set[2] = Set1; Set[2].binding = 2;
			assert(1 == uni->createSet(lod->cdescVk, "compSet1"sv, Set, draft));

			Set.resize(4);
			Set[0]  = {
					.binding = 0,
						.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
						.descriptorCount = 1,
						.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT | VK_SHADER_STAGE_VERTEX_BIT,
						.pImmutableSamplers = NULL
			};
			Set[1]  = Set[2] = Set[3] = {
				 .binding = 1,
				 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				 .descriptorCount = 1,
				 .stageFlags = VK_SHADER_STAGE_COMPUTE_BIT | VK_SHADER_STAGE_VERTEX_BIT,
				 .pImmutableSamplers = NULL
			};
			Set[2].binding = 2; Set[3].binding = 3;
			assert(2 == uni->createSet(lod->cdescVk, "compSet2"sv, Set, draft));

			Set.resize(1);
			Set[0] = {
					.binding = 0,
						.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
						.descriptorCount = 1,
						.stageFlags = VK_SHADER_STAGE_VERTEX_BIT |  VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT | VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT,
						.pImmutableSamplers = NULL
			};
			assert(3 == uni->createSet(lod->descVk, "graphSet1"sv, Set, draft));

			Set[0] = {
				 .binding = 0,
				 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				 .descriptorCount = 1,
				 .stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT | VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT,
				 .pImmutableSamplers = NULL
			};
			assert(4 == uni->createSet(lod->descVk, "graphInstaSet2"sv, Set, draft));
			assert(5 == uni->createSet(lod->descVk, "graphPointSet2"sv, Set, false));
			assert(6 == uni->createSet(lod->descVk, "graphTessSet2"sv, Set, false));
		}
		else if (vis_type == eVIS_TYPE::IMG_BUFFER) {

			Set.resize(2);
			Set[0] = Set1; Set[1] = Set1; Set[1].binding = 1;
			assert(1 == uni->createSet(lod->cdescVk, "icompSet1"sv, Set, draft));

			Set.resize(2);
			Set[0] = Set[1] =  {
				 .binding = 0,
				 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				 .descriptorCount = 1,
				 .stageFlags = VK_SHADER_STAGE_COMPUTE_BIT,
				 .pImmutableSamplers = NULL
			};
			Set[1].binding = 1; 
			assert(2 == uni->createSet(lod->cdescVk, "icompSet2"sv, Set, draft));


			Set.resize(2);
			Set[0] = {
				 .binding = 0,
				 .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
				 .descriptorCount = 1,
				 .stageFlags = VK_SHADER_STAGE_COMPUTE_BIT ,
				 .pImmutableSamplers = NULL
			};
			Set[1] = {
				 .binding = 1,
				 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
				 .descriptorCount = 1,
				 .stageFlags = VK_SHADER_STAGE_COMPUTE_BIT ,
				 .pImmutableSamplers = NULL
			};
			assert(3 == uni->createSet(lod->cdescVk, "icompSet3"sv, Set, draft));

			Set.resize(1);
			Set[0] = {
	 .binding = 0,
	 .descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
	 .descriptorCount = 1,
	 .stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT | VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT,
	 .pImmutableSamplers = NULL
			};
			assert(4 == uni->createSet(lod->descVk, "igraphPointSet2"sv, Set, draft));


			Set[0] = {
					.binding = 0,
						.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
						.descriptorCount = 1,
						.stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT | VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT,
						.pImmutableSamplers = NULL
			};
			assert(5 == uni->createSet(lod->descVk, "igraphPointSet1"sv, Set, draft));
			assert(6 == uni->createSet(lod->descVk, "graphTessSet1"sv, Set, false));


			//assert(5 == uni->createSet(lod->descVk, "graphTessSet2"sv, Set, false));
		};
		return true;

	};
	void writeout(std::vector<VkDescriptorSet> set, VkDescriptorBufferInfo camera);

	bool DeAllocateAll();


	void map(Object3D* obj);

	bool Allocate(Object3D* obj);

	long  Cummulative(Object3D& obj);

	template<class T>
	size_t hashTB(T const& s) noexcept
	{
		size_t h = 0;
		std::string type = s.type.data();
		size_t  i = 0;
		for (char t : s.type) {
			h |= (size_t(t) - 115) << i * 2;
		};
		h |= (s.align << 16);

		return h;
	};


	void update() {
		if (vis_type == eVIS_TYPE::IMG_BUFFER) {
			//static  mapStat stat = { 0, 10., { -1500.,605} ,{ -25000.f,-25000.f,50000.f,50000.f} };

			//memcpy(cache.stats.mapped, &stat, sizeof(stat));
			//stat.frame++;
		};
	}

};



extern PyTypeObject tp_Group;

#define PyGroup_CheckExact(op) (Py_TYPE(op) == &tp_Group)

PyObject* Group_add(Group* self, PyObject* args);
int AddType_Group(PyObject* m);

#endif
