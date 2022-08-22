#pragma once
#include "pch.h"
#include "working.h"
#include "aeolus/materialsVk/common.h"
#include "aeolus/groupVk/common.h"

using namespace aeo;

void LodBuffer::map(Object3D* obj) {

	eVIS_TYPE TYPE = (eVIS_TYPE)1000;
	auto Mode = ((LodMaterialVk*)obj->material)->mode;
	if (Mode == LodMaterialVk::eConfigu_MODE::MODE_TEXEL) {
		TYPE = eVIS_TYPE::TEX_BUFFER2;
	}
	else if (Mode == LodMaterialVk::eConfigu_MODE::MODE_INSTATEX) {
		TYPE = eVIS_TYPE::IMG_BUFFER;
	}


	if (!cache.allo)Allocate(obj);


	if (vis_type == eVIS_TYPE::INSTANCE_RATE) {
		_BufferAttribute& geom = *(obj->geometry->instance->buffer);

		objVk->$createBufferInstanced$(*cmdVk, obj->geometry, true);
		cache.insta.id = -1;
		cache.insta.offset = 0;
		cache.insta.info = geom.info.attr;
		cache.insta.size = geom.info.attr.range;
		cache.insta.format = float16 ? VK_FORMAT_R16G16B16A16_SFLOAT : VK_FORMAT_R32G32B32A32_SFLOAT;
		cache.insta.vkBuffer = geom.info.attr.buffer;
		objVk->createBufferView(cache.insta);
		geom.info.attrView = cache.insta.vkView;
	}
	else {


		objVk->$createBuffer$(*cmdVk, OBJ_GEOM(obj), true);

		if (TYPE != eVIS_TYPE::IMG_BUFFER) {
			_BufferAttribute& geom = *(obj->geometry->instance->buffer);
			geom.info.attr.buffer = cache.insta.vkBuffer;
			geom.info.attr.range = geom.array.structSize * geom.array.arraySize;
			struct F4 {
				float posSize[4];
				float color[4];
			};
			F4* f = (F4*)geom.array.data;
			for (int i = 0; i < 4; i++) {
				printf("No[%d]    posSize %f %f %f %f     ", i, f[i].posSize[0], f[i].posSize[1], f[i].posSize[2], f[i].posSize[3]);
				printf("           color  %f %f %f %f       \n ", f[i].color[0], f[i].color[1], f[i].color[2], f[i].color[3]);
			};
			objVk->$BridgeMapBuffer$(*cmdVk, geom.info.attr, geom.array.data);
		}
	};

	child.push_back(obj);

};

bool LodBuffer::Allocate(Object3D* obj) {


	eVIS_TYPE TYPE = (eVIS_TYPE)1000;;
	auto Mode = ((LodMaterialVk*)obj->material)->mode;
	if (Mode == LodMaterialVk::eConfigu_MODE::MODE_TEXEL) {
		TYPE = eVIS_TYPE::TEX_BUFFER2;
	}
	else if (Mode == LodMaterialVk::eConfigu_MODE::MODE_INSTATEX) {
		TYPE = eVIS_TYPE::IMG_BUFFER;
	}


	auto& push = ((LodMaterialVk*)(obj->material))->push;
	for (int i = 0; i < 2; i++)push.viewpixel[i] = (float)ovr->proj.viewpixel[i];

	if (TYPE == eVIS_TYPE::TEX_BUFFER) {

		BatchSize = 1024;
		SubGroup = size_t((Size.nums / 4 + (BatchSize - 1)) / BatchSize);
		Size.counter = sizeof(DrawCounters) * SubGroup;
		Size.counter = alignedSize(Size.counter, _inindexAlignment);
		Size.cmd = sizeof(VkDrawIndexedIndirectCommand) * SubGroup;
		Size.cmd = alignedSize(Size.cmd, _inindexAlignment);

	}
	else if (TYPE == eVIS_TYPE::TEX_BUFFER2) {

		BatchSize = 512;
		SubGroup = size_t((Size.nums / 4 + (BatchSize - 1)) / BatchSize);
		Size.cmd = sizeof(VkDrawIndexedIndirectCommand) * SubGroup;
		Size.cmd = alignedSize(Size.cmd, _inindexAlignment);

	}
	else if (TYPE == eVIS_TYPE::IMG_BUFFER) {

		BatchSize = 1024;
		SubGroup = size_t((Size.nums / 4 + (BatchSize - 1)) / BatchSize);
		Size.cmd = sizeof(VkDrawIndexedIndirectCommand) * SubGroup;
		Size.cmd = alignedSize(Size.cmd, _inindexAlignment);

		Size.stats = sizeof(mapStat);
		cache.stats.buffer.id = -1;
		cache.stats.buffer.version = 0;
		cache.stats.size = Size.stats;
		vobjVk->$createBuffer$(cache.stats, VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT);
		cache.stats.info = {
			.buffer = cache.stats.vkBuffer,
			.offset = 0,
			.range = Size.stats,
		};;
	}
	else {
		BatchSize = 512;
		Size.cmd = sizeof(VkDrawIndexedIndirectCommand) * InstaSize;
		Size.cmd = alignedSize(Size.cmd, _inindexAlignment);

	};


	if (STATIS)Size.stats = sizeof(StatsLod) * Size.nums / 4;// SubGroup;

	cache.mem.mem = { .id = -1,.version = 0 };
	cache.mem.id = -1;

	if (TYPE == eVIS_TYPE::TEX_BUFFER) cache.mem.sizeSet = { Size.insta, Size.nums,Size.counter,Size.cmd };
	else if (TYPE == eVIS_TYPE::TEX_BUFFER2) cache.mem.sizeSet = { Size.insta,Size.nums,Size.nums,Size.nums,  Size.cmd,Size.cmd, Size.cmd };
	else if (TYPE == eVIS_TYPE::IMG_BUFFER) cache.mem.sizeSet = { Size.nums,Size.nums, Size.cmd,Size.cmd };
	else cache.mem.sizeSet = { Size.cmd };

	long  offID = 0;

	objVk->$AllocMemory$(*cmdVk, cache.mem);

	Mvk Mem;
	objVk->getMemory(Mem, cache.mem.mem);
	VkBufferUsageFlags flags;


	if (TYPE == eVIS_TYPE::TEX_BUFFER || TYPE == eVIS_TYPE::TEX_BUFFER2) {

		flags = VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		cache.insta.id = -1;
		cache.insta.offset = cache.mem.sizeSet[offID++];
		cache.insta.size = Size.insta;
		cache.insta.format = float16 ? VK_FORMAT_R16G16B16A16_SFLOAT : VK_FORMAT_R32G32B32A32_SFLOAT;
		objVk->$createDeviceBufferSeparate$(cache.insta, Mem.memory, flags);
		objVk->createBufferView(cache.insta);
	};

	if (TYPE == eVIS_TYPE::TEX_BUFFER) {


		flags = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT;//  VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT;// 
		cache.inindex.id = -1;
		cache.inindex.offset = cache.mem.sizeSet[offID++];
		cache.inindex.size = Size.nums;
		cache.inindex.format = float16 ? VK_FORMAT_R16_SINT : VK_FORMAT_R32_SINT;
		objVk->$createDeviceBufferSeparate$(cache.inindex, Mem.memory, flags);
		objVk->createBufferView(cache.inindex);

		flags = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		cache.counter.id = -1;
		cache.counter.offset = cache.mem.sizeSet[offID++];
		cache.counter.size = Size.counter;
		objVk->$createDeviceBufferSeparate$(cache.counter, Mem.memory, flags);

	}
	else if (TYPE == eVIS_TYPE::TEX_BUFFER2 || TYPE == eVIS_TYPE::IMG_BUFFER) {

		flags = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;  // | VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT  VK_BUFFER_USAGE_STORAGE_TEXEL_BUFFER_BIT;// 
		cache.inindex.id = -1;
		cache.inindex.offset = cache.mem.sizeSet[offID++];
		cache.inindex.size = Size.nums;
		cache.inindex.format = float16 ? VK_FORMAT_R16_SINT : VK_FORMAT_R32_SINT;
		objVk->$createDeviceBufferSeparate$(cache.inindex, Mem.memory, flags);

		cache.inindex2.id = -1;
		cache.inindex2.offset = cache.mem.sizeSet[offID++];
		cache.inindex2.size = Size.nums;
		cache.inindex2.format = float16 ? VK_FORMAT_R16_SINT : VK_FORMAT_R32_SINT;
		objVk->$createDeviceBufferSeparate$(cache.inindex2, Mem.memory, flags);


		if (TYPE == eVIS_TYPE::TEX_BUFFER2) {
			cache.inindex3.id = -1;
			cache.inindex3.offset = cache.mem.sizeSet[offID++];
			cache.inindex3.size = Size.nums;
			cache.inindex3.format = float16 ? VK_FORMAT_R16_SINT : VK_FORMAT_R32_SINT;
			objVk->$createDeviceBufferSeparate$(cache.inindex3, Mem.memory, flags);
		}

		///objVk->createBufferView(cache.inindex);
		flags = VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		cache.cmd2.id = -1;
		cache.cmd2.offset = cache.mem.sizeSet[offID++];
		cache.cmd2.size = Size.cmd;
		objVk->$createDeviceBufferSeparate$(cache.cmd2, Mem.memory, flags);

		if (TYPE == eVIS_TYPE::TEX_BUFFER2) {
			///objVk->createBufferView(cache.inindex);
			flags = VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
			cache.cmd3.id = -1;
			cache.cmd3.offset = cache.mem.sizeSet[offID++];
			cache.cmd3.size = Size.cmd;
			objVk->$createDeviceBufferSeparate$(cache.cmd3, Mem.memory, flags);
		};
	};

	flags = VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
	cache.cmd.id = -1;
	cache.cmd.offset = cache.mem.sizeSet[offID++];
	cache.cmd.size = Size.cmd;
	objVk->$createDeviceBufferSeparate$(cache.cmd, Mem.memory, flags);


	if (STATIS) {
		cache.stats.buffer.id = -1;
		cache.stats.buffer.version = 0;
		cache.stats.size = Size.stats;
		vobjVk->$createBuffer$(cache.stats, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT);
		cache.stats.info = {
			.buffer = cache.stats.vkBuffer,
			.offset = 0,
			.range = Size.stats,
		};
	};

	child.clear();

	return true;

};

long  LodBuffer::Cummulative(Object3D& obj) {

	eVIS_TYPE TYPE = (eVIS_TYPE)1000;
	auto Mode = ((LodMaterialVk*)obj.material)->mode;
	if (Mode == LodMaterialVk::eConfigu_MODE::MODE_TEXEL) {
		TYPE = eVIS_TYPE::TEX_BUFFER2;
	}
	else if (Mode == LodMaterialVk::eConfigu_MODE::MODE_INSTATEX) {
		TYPE = eVIS_TYPE::IMG_BUFFER;
	}

	if (TYPE == eVIS_TYPE::TEX_BUFFER2) {

		_BufferAttribute& desc = *obj.geometry->instance->buffer;
		if (desc.id != -1) return 0;

		desc.info.attr.offset = Size.insta;
		Size.insta += alignedSize(desc.array.arraySize * desc.array.structSize, _structAlignment);
		desc.id = 54321;

		desc.info.index.offset = Size.nums;
		Size.nums += alignedSize(desc.array.arraySize * sizeof(InstaIndexTy) * InstaTypeNums, _inindexAlignment);
		InstaSize = obj.geometry->instance->buffer->array.arraySize;

	}
	else if (TYPE == eVIS_TYPE::IMG_BUFFER) {

		const size_t size = 1024 * 1024;

		Size.nums += alignedSize(size * sizeof(InstaIndexTy) * InstaTypeNums, _inindexAlignment);
		InstaSize = size;

	};

	cache.allo = false;

	return 0;
};



VertexBuffer::VertexBuffer() : objVk(nullptr), cmdVk(nullptr) {};
LayoutBuffer::LayoutBuffer() :vobjVk(nullptr), descVk(nullptr) {};

bool LayoutBuffer::DeAllocateAll() {
	bool ok = true;
	for (auto& [k, bach] : Ref) ok &= vobjVk->$delete$(bach);
	return ok;
};

LayoutBuffer::~LayoutBuffer() {
	DeAllocateAll();
};

LodBuffer::~LodBuffer() {
	DeAllocateAll();
};

bool LodBuffer::DeAllocateAll() {
	bool ok = true;
	ok &= objVk->DeleteIBm(cache.counter.buffer);
	ok &= objVk->DeleteIBm(cache.cmd.buffer);
	ok &= objVk->DeleteIBm(cache.insta.buffer);
	ok &= objVk->DeleteIBm(cache.cmd2.buffer);
	ok &= objVk->DeleteIBm(cache.cmd3.buffer);
	ok &= objVk->DeleteIBm(cache.inindex.buffer);
	ok &= objVk->DeleteIBm(cache.inindex2.buffer);
	ok &= objVk->DeleteIBm(cache.inindex3.buffer);
	ok &= objVk->DeleteIBm(cache.stats.buffer);
	/*
	ok &= objVk->DeleteIBm(cache.cmd.buffer);
	ok &= objVk->DeleteIBm(cache.insta.buffer);
	*/
	ok &= objVk->DeleteM(cache.mem.mem);
	return ok;
};


void LodBuffer::writeout(std::vector<VkDescriptorSet> set,VkDescriptorBufferInfo camera) {

	static std::vector<VkWriteDescriptorSet> write;
	if (vis_type == eVIS_TYPE::INSTANCE_RATE) write.resize(3);
	else if (vis_type == eVIS_TYPE::TEX_BUFFER2) write.resize(8 + 1 + 3 );
	else if (vis_type == eVIS_TYPE::IMG_BUFFER) write.resize(7 + 1 + 2);
	else write.resize(7);

	write[0] =
	{
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = set[0],
			.dstBinding = 0,
			.dstArrayElement = 0,
			.descriptorCount = 1,
			.descriptorType = Set0.descriptorType,
			.pBufferInfo = &camera,
	};

	write[1] =
	{
			.sType         = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet       = set[1],
			.dstBinding =   0,
			.dstArrayElement   = 0,
			.descriptorCount    = 1,
			.descriptorType     = Set1.descriptorType,
			.pBufferInfo         = &cache.cmd.info
	};


	if (vis_type != eVIS_TYPE::IMG_BUFFER) {
		write[2] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[2],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = CSet2[0].descriptorType,
				.pBufferInfo = &cache.insta.info,
				.pTexelBufferView = &cache.insta.vkView
		};
	}

	
	if (vis_type == eVIS_TYPE::TEX_BUFFER2) {

			write[3] = {
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = set[1],
			.dstBinding = 1,
			.dstArrayElement = 0,
			.descriptorCount = 1,
			.descriptorType = Set1.descriptorType,
			.pBufferInfo = &cache.cmd2.info
			};
			write[4] =
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[2],
					.dstBinding = 1,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
					.pBufferInfo = &cache.inindex.info,
			};
			write[5] =
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[2],
					.dstBinding = 2,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
					.pBufferInfo = &cache.inindex2.info,
			};
			write[6] =
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[3],
					.dstBinding = 0,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER,
					.pBufferInfo = &cache.insta.info,
					.pTexelBufferView = &cache.insta.vkView
			};
			write[7] =
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[4],
					.dstBinding = 0,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = Set1.descriptorType,
					.pBufferInfo = &cache.inindex.info
			};
			write[8] =
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[5],
					.dstBinding = 0,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = Set1.descriptorType,
					.pBufferInfo = &cache.inindex2.info
			};
			write[9] =
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[6],
					.dstBinding = 0,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = Set1.descriptorType,
					.pBufferInfo = &cache.inindex3.info
			};

			write[10] = {
.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
.dstSet = set[1],
.dstBinding = 2,
.dstArrayElement = 0,
.descriptorCount = 1,
.descriptorType = Set1.descriptorType,
.pBufferInfo = &cache.cmd3.info
			};
			write[11] =
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[2],
					.dstBinding = 3,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
					.pBufferInfo = &cache.inindex3.info,
			};


		};
    if (vis_type == eVIS_TYPE::TEX_BUFFER) {
		
		write[3] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[2],
				.dstBinding = 1,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = CSet2[1].descriptorType,
				.pBufferInfo = &cache.counter.info,
		};

		write[4] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[2],
				.dstBinding = 2,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = CSet2[2].descriptorType,
				.pBufferInfo = &cache.inindex.info,
		};


		write[5] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[3],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount  = 1,
				.descriptorType      = Set2[0].descriptorType,
				.pBufferInfo          = &cache.insta.info,
				.pTexelBufferView = &cache.insta.vkView
		};

		write[6] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[3],
				.dstBinding = 1,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = Set2[1].descriptorType,
				.pBufferInfo = &cache.inindex.info,
				.pTexelBufferView = &cache.inindex.vkView
		};

	}



	if (vis_type == eVIS_TYPE::IMG_BUFFER) {
		write[2] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[1],
				.dstBinding = 1,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = Set1.descriptorType,
				.pBufferInfo = &cache.cmd2.info
		};
		write[3] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[2],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				.pBufferInfo = &cache.inindex.info,
		};
		write[4] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[2],
				.dstBinding = 1,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				.pBufferInfo = &cache.inindex2.info,
		};
		write[5] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[3],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
				.pImageInfo = &cache.instatex,
		};
		write[6] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[3],
				.dstBinding = 1,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
				.pBufferInfo = &cache.stats.info,
		};

		write[7] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[4],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
				.pBufferInfo = &cache.stats.info,
		};

		write[8] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[5],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				.pBufferInfo = &cache.inindex.info,
		};

		write[9] =
		{
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = set[6],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
				.pBufferInfo = &cache.inindex2.info,
		};

	};


	if (STATIS) {
		write.push_back(
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[2],
					.dstBinding = 3,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = Set1.descriptorType,
					.pBufferInfo = &cache.stats.info
			});

		write.push_back(
			{
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set[3],
					.dstBinding = 2,
					.dstArrayElement = 0,
					.descriptorCount = 1,
					.descriptorType = Set1.descriptorType,
					.pBufferInfo = &cache.stats.info
			});
	
	}
	///for (auto& l : set) { printf(" Write  Set       %x    \n", l); };

	vkUpdateDescriptorSets($device, static_cast<uint32_t>(write.size()), write.data(), 0, nullptr);

};


bool MeshletBuffer::DeAllocateAll() {
	bool ok = true;
	ok &= objVk->DeleteIBm(cache.vert.buffer);
	ok &= objVk->DeleteIBm(cache.attr.buffer);
	ok &= objVk->DeleteIBm(cache.index.buffer);
	ok &= objVk->DeleteIBm(cache.mesh.buffer);
	ok &= objVk->DeleteM(cache.mem.mem);
	return ok;
};

MeshletBuffer::~MeshletBuffer() {
	DeAllocateAll();
};



static void
Group_dealloc(Group* self)
{
	for (int i = 0; i < self->child.size(); i++) {
		Py_DECREF((PyObject*)self->child.at(i));
	}

	__Delete__(self->ldMaster)
	__Delete__(self->lbMaster)
	__Delete__(self->vbMaster)
	__Delete__(self->mbMaster)

	Py_TYPE(self)->tp_free((PyObject*)self);
};

static int
Group_init(Group* self, PyObject* args, PyObject* kwds)
{
	
	uint32_t typeG;
	uint32_t typeD;
	///static char keywords[][20] = { "geom", "draw", NULL };
	///PyArg_ParseTupleAndKeywords(args, kwds, "kk", (char**)keywords, &typeG, &typeD);
	if (!PyArg_ParseTuple(args, "kk", &typeG, &typeD)){
		return NULL;
	}
	self->type.geom = (arth::GEOMETRY)typeG;
	self->type.draw = (arth::DRAW)typeD;


	self->callback = new callback_prop;
	self->vbMaster  = nullptr;
	self->lbMaster   = nullptr;
	self->mbMaster = nullptr;
	self->ldMaster   = nullptr;

	return 0;

}


static PyObject*
Group_new(PyTypeObject* type, PyObject* args, PyObject* kw)
{
	int rc = -1;
	//printf("<Group>  new \n");
	Group* self = NULL;
	self = (Group*)type->tp_alloc(type, 0);
	std::vector<Object3D*> child;
	self->child.swap(child);
	if (!self) goto error;
	rc = 0;

error:
	if (rc < 0)Py_XDECREF(self);
	return (PyObject*)self;

}



PyObject* Group_add(Group* self, PyObject* args)
{
	static OVR* ovr = nullptr;
	if (ovr == nullptr) {
		if (!$tank.takeout(ovr, 0)) {
			log_bad(" not found  OVR.");
		};
	};

	

	Py_ssize_t n = PyTuple_Size(args);

	for (int i = 0; i < n; i++) {

		Object3D* o = (Object3D*)PyTuple_GetItem(args, i);
		Material* mat = (Material*)(o->material);
		_BufferAttribute& buf = *o->geometry->attributes->buffer;
		MeshMaterialVk*  mesh =nullptr;

		printf("Group   Memeber  Add   %llx-ref%zd   TYPE %u   \n", (unsigned long long)o, o->ob_base.ob_refcnt, (UINT)o->geometry->type);

		if (mat->type == arth::eMATERIAL::MESH) mesh = ((MeshMaterialVk*)mat);
		
		if (  mesh !=nullptr || (mat->type == arth::eMATERIAL::RAW) ){
			
			if (mat->desc.align > 0) {

				o->uniform = new UniformVk;
				o->des->set([uniform = std::move(o->uniform)](void* no) mutable{
					if (uniform != nullptr) {
						types::deleteRaw(uniform);
						uniform = nullptr;
					};
					return 1;
				});

				if (mesh !=nullptr && mesh->mode == MeshMaterialVk::eConfigu_PIPE::MODE_TASK_MESH2) {
					o->uniform->ubo.id =  mesh->Counting();
				}
				else {
					if (self->lbMaster == nullptr)self->lbMaster = new LayoutBuffer;
					o->uniform->ubo.id = self->lbMaster->Counting(mat->desc);
				}
			};

			if (mesh != nullptr && mesh->mode != MeshMaterialVk::eConfigu_PIPE::MODE_TASK_MESH2) {

				if (self->mbMaster == nullptr) {
					self->mbMaster = new MeshletBuffer;
					self->mbMaster->init(buf);
				};
				self->mbMaster->Cummulative(*o);
			}

		}
		else if (mat->type == arth::eMATERIAL::RAW2) {

			 Material2Vk* mat2 = (Material2Vk*)mat;
			 o->draw.pid =  mat2->Counting();

		} else if (mat->type == arth::eMATERIAL::LOD) {

			LodMaterialVk* mat = (LodMaterialVk*)o->material;
			if (o->uniform == nullptr)o->uniform = new UniformVk;
			o->uniform->swID  = 0;
			mat->Cummulative(o);
			mat->arangeLayoutSet(o->uniform);

		}
		else if (mat->type == arth::eMATERIAL::LOD2) {

			LodMaterial2Vk* mat = (LodMaterial2Vk*)o->material;
			mat->Cummulative(o);

		}
		else if (mat->type == arth::eMATERIAL::VID ) {
#ifdef INCLUDE_MATERIAL_VKVIDEO
			VidMaterial3* mat = (VidMaterial3*)o->material;
			mat->Cummulative(o);
#endif
			} else if ( mat->type == arth::eMATERIAL::GEO ) {

			GeomMaterialVk* mat = (GeomMaterialVk*)o->material;
			mat->Cummulative(o);

	    }else if (mat->type == arth::eMATERIAL::MESH2) {

			MeshMaterial2Vk* mat = (MeshMaterial2Vk*)o->material;
			mat->Cummulative(o);

	    };

		if (buf.type == arth::GEOMETRY::SUSPEND) {
			if (buf.name == "VrCtrl-l") {
				ovr->LoadRenderModel(o, 0);
				o->updateMatrixWorld(false);
			};
		};

		if (
			(self->type.draw == arth::DRAW::NONE) ||
			LEQ_ANY_MASK_ARTH(o->geometry->type, self->type.geom, (arth::GEOMETRY)~0xfff)
		 ) {

			log_gr("Group   Memeber  Add   %x-ref%zd   TYPE %u   \n", o, o->ob_base.ob_refcnt, (UINT)o->geometry->type);
			Py_INCREF(o);
			o->parent = self->parent;
			o->id = (int)self->child.size();
			self->child.emplace_back(o);
		}
		else {
			log_bad("Group requires the same type of geometry.  this[%u]  that[%u] \n ", UINT(self->type.geom), UINT(o->geometry->type));
		};

		if ( ((mat->type != arth::eMATERIAL::MESH2) &&  (mat->type != arth::eMATERIAL::GEO ) &&  (mat->type != arth::eMATERIAL::LOD)  && (mat->type != arth::eMATERIAL::LOD2) && (mat->type != arth::eMATERIAL::RT) && (mat->type != arth::eMATERIAL::RTC) &&  EQ_ARTH(o->geometry->type, arth::GEOMETRY::BUFFER) )  || ( mesh!=nullptr && mesh->mode == MeshMaterialVk::eConfigu_PIPE::MODE_TASK_MESH2)) {
				if (self->vbMaster == nullptr)self->vbMaster = new VertexBuffer;
				self->vbMaster->Borrow(o);
		};

	}
	

	Py_RETURN_NONE;

}

PyObject* Group_setBrunch(Group* self, PyObject* args)
{
	long   id = 0;
	PyArg_Parse(args, "i", &id);
	self->type.ID = id;
	log_gr(" set Brunch %d  this group %x  \n ", id, self);

	Py_RETURN_NONE;
};

PyObject* Group_setCallback(Group* self, PyObject* args)
{
	char* name = nullptr;
	PyArg_Parse(args, "s", &name);
	self->callback->name  = name;

	Py_RETURN_NONE;
};



static PyGetSetDef Group_getsetters[] = {
	{0},
};


PyMethodDef Group_tp_methods[] = {

	{"setCallback", (PyCFunction)Group_setCallback, METH_VARARGS, 0},
	{"add", (PyCFunction)Group_add, METH_VARARGS, 0},
	{"setBrunch", (PyCFunction)Group_setBrunch, METH_O, 0},
	{0},
};


PyTypeObject tp_Group = []() -> PyTypeObject {
	PyTypeObject type = { PyVarObject_HEAD_INIT(0, 0) };
	type.tp_name = "cthreepy.Group";
	type.tp_doc = "Group objects";
	type.tp_basicsize = sizeof(Group);
	type.tp_itemsize = 0;
	type.tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE;
	type.tp_new = Group_new;
	type.tp_init = (initproc)Group_init;
	type.tp_methods = Group_tp_methods;
	type.tp_dealloc = (destructor)Group_dealloc;
	type.tp_getset = Group_getsetters;
	return type;
}();


int AddType_Group(PyObject* m) {

	if (PyType_Ready(&tp_Group) < 0)
		return -1;

	Py_XINCREF(&tp_Group);
	PyModule_AddObject(m, "Group", (PyObject*)&tp_Group);
	return 0;
}

