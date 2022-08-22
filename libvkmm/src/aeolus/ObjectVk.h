#pragma once

#ifndef OBJECTVK_H
#define OBJECTVK_H
#include "pch_mm.h"
#include "incomplete.h"



#ifdef  LOG_NO_obj
#define log_obj(...)
#else
#define log_obj(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif



#define SIZE_MDev     2048
#define SIZE_MVis      1024

#define SIZE_MB   4096
#define SIZE_MIB 100
#define SIZE_MIBm   4096

#define SIZE_IBmDev   100000
#define SIZE_IBmVis     50000


#define INDEXINDEX(idx) (idx + SIZE_MB/2)

MemExtern(MBvk, SIZE_MB);
MemExtern(MIBvk, SIZE_MIB);
MemExtern(MIBmvk, SIZE_MIBm);


MemExtern(Mvk, SIZE_MDev);
MemExtern(Mvk, SIZE_MVis);

MemExtern(IBmvk, SIZE_IBmDev);
MemExtern(IBmvk, SIZE_IBmVis);


struct vkPVISci
{

	std::vector<VkVertexInputBindingDescription> vertexInputBindings;
	std::vector<VkVertexInputAttributeDescription> vertexInputAttributes;
	VkPipelineVertexInputStateCreateInfo info;
	arth::INPUT                                          type;

};

#define COMBINE_INPUT(attr,insta) { ty = arth::INPUT(UINT(attr->array.type) << 4) | insta->array.type;sty = arth::INPUT_String(ty);};

struct vkPVISciMem {

	///vkPVISci                                           Info[arth::INPUT_TYPE_ALL];
	std::unordered_map<std::string, vkPVISci>        Info;
	SRWLOCK                                          SlimLock;
	vkPVISciMem();

	arth::INPUT  ty;
   std::string     sty;

	bool get(VkPipelineVertexInputStateCreateInfo*& info, arth::INPUT Ity);


	template<class Geom>
	bool get(VkPipelineVertexInputStateCreateInfo*& info, Geom* geom) {
		auto attr = geom->attributes->buffer;
		auto insta = geom->instance->buffer;
		COMBINE_INPUT(attr, insta)
		if (Info[sty].type == ty) {
			info = &Info[sty].info;
			log_obj(" Found   VertexInfo      %x    ", *info);
			return true;
		}
		return false;
	}


	template<class Geom>
	bool enterAttr(Geom* geometry) {

		ty = geometry->array.type;
		sty = arth::INPUT_String(ty);
		if (Info[sty].type == ty) return false;
		AcquireSRWLockExclusive(&SlimLock);
		if (Info[sty].type == ty) {
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		}

		return true;
	}

	template<class Geom>
	bool enterGeom(Geom* attr, Geom* insta) {


		COMBINE_INPUT(attr, insta)


		if (Info[sty].type == ty) return false;

		AcquireSRWLockExclusive(&SlimLock);
		if (Info[sty].type == ty) {
			ReleaseSRWLockExclusive(&SlimLock);
			return false;
		}

		return true;
	}

	template<class Geom>
	void $set$(Geom* geometry, VkVertexInputRate rate = VK_VERTEX_INPUT_RATE_VERTEX) {

		if (!enterAttr(geometry))return;

		vkPVISci mem;
		mem.type = ty;
	
		mem.vertexInputBindings = { {
			.binding = 0,
		   .stride = (uint32_t)geometry->array.structSize,
		   .inputRate = rate
		} };

		mem.vertexInputAttributes.clear();
		for (int i = 0; i < geometry->array.fieldNum; i++) {
			mem.vertexInputAttributes.push_back({
				.location = (UINT32)i,
				.binding = 0,
				.format = geometry->array.format[i],
				.offset = (UINT32)geometry->array.offset[i]
				});
		};

		mem.info = {
			 .sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
			 .vertexBindingDescriptionCount = static_cast<uint32_t>(mem.vertexInputBindings.size()),
			 .pVertexBindingDescriptions = mem.vertexInputBindings.data(),
			 .vertexAttributeDescriptionCount = static_cast<uint32_t>(mem.vertexInputAttributes.size()),
			 .pVertexAttributeDescriptions = mem.vertexInputAttributes.data()
		};
		log_obj(" Set VertexType   %x  \n", mem.info);
		Info[sty] = std::move(mem);

		ReleaseSRWLockExclusive(&SlimLock);
	};

	template<class Geom>
	void $setSprite$(Geom* geometry) {


		if (!enterAttr(geometry))return;

		vkPVISci mem;
		mem.type = ty;


		mem.vertexInputBindings = { {
			.binding = 0,
		    .stride = (uint32_t)4*4,
		    .inputRate = VK_VERTEX_INPUT_RATE_VERTEX
		  }
		};



		mem.vertexInputAttributes.clear();
		for (int i = 0; i < geometry->array.fieldNum; i++) {
			mem.vertexInputAttributes.push_back({
				.location = (UINT32)i,
				.binding = 0,
				.format = geometry->array.format[i],
				.offset = (UINT32)geometry->array.offset[i]
				});
		};

		mem.info = {
			 .sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
			 .vertexBindingDescriptionCount = static_cast<uint32_t>(mem.vertexInputBindings.size()),
			 .pVertexBindingDescriptions = mem.vertexInputBindings.data(),
			 .vertexAttributeDescriptionCount = static_cast<uint32_t>(mem.vertexInputAttributes.size()),
			 .pVertexAttributeDescriptions = mem.vertexInputAttributes.data()
		};


		log_obj(" Set VertexType   %x  \n", mem.info);
		Info[sty] = std::move(mem);

		ReleaseSRWLockExclusive(&SlimLock);
	};

	template<class Geom>
	void $setInstanced$(Geom* geometry) {

		auto insta = geometry->instance->buffer;
		if (geometry->attributes == nullptr) {
			$set$(insta,  VK_VERTEX_INPUT_RATE_INSTANCE);
			return;
		}

		auto attr = geometry->attributes->buffer;
		if (!enterGeom(attr,insta))return;

		vkPVISci mem;
		mem.type = ty;


		mem.vertexInputBindings = { {
			.binding = 0,
			.stride = (uint32_t)attr->array.structSize,
			.inputRate = VK_VERTEX_INPUT_RATE_VERTEX
		  },
			 {
			.binding = 1,
			.stride = (uint32_t)insta->array.structSize,
			.inputRate = VK_VERTEX_INPUT_RATE_INSTANCE
		  },
		};



		mem.vertexInputAttributes.clear();
		int i = 0;
		for (i = 0; i < attr->array.fieldNum; i++) {
			mem.vertexInputAttributes.push_back({
				.location = (UINT32)i,
				.binding = 0,
				.format = attr->array.format[i],
				.offset = (UINT32)attr->array.offset[i]
				});
		};

		for (int j=0; j < insta->array.fieldNum; j++) {
			mem.vertexInputAttributes.push_back({
				.location = (UINT32)i++,
				.binding = 1,
				.format = insta->array.format[j],
				.offset = (UINT32)insta->array.offset[j]
			});
		};

		mem.info = {
			 .sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
			 .vertexBindingDescriptionCount = static_cast<uint32_t>(mem.vertexInputBindings.size()),
			 .pVertexBindingDescriptions = mem.vertexInputBindings.data(),
			 .vertexAttributeDescriptionCount = static_cast<uint32_t>(mem.vertexInputAttributes.size()),
			 .pVertexAttributeDescriptions = mem.vertexInputAttributes.data()
		};


		log_obj(" Set VertexType   %x  \n", mem.info);
		Info[sty] = std::move(mem);

		ReleaseSRWLockExclusive(&SlimLock);

	};


};



#define $VInfo  VInfo
extern  vkPVISciMem VInfo;


/*
template<class Pool>
struct ImmidiateBufferCmd : public Pool {

	ImmidiateBufferCmd() {   alloc(); };
	~ImmidiateBufferCmd() { free(); };

	void alloc() {
		Pool::alloc();
	}
	void free() {
		Pool::free();
	};
	bool Map(void* src, VkDeviceSize offset, VkDeviceSize size) {

		char* dst;
		VK_CHECK_RESULT(vkMapMemory($device, staging.memory, offset, size, 0, (void**)&dst));
		memcpy(dst, src,  size);
		vkUnmapMemory($device, staging.memory);

		return true;

	};
	template<class B>
	bool Copy(B& _, VkDeviceSize size, VkDeviceSize srcOffset = 0, VkDeviceSize dstOffset = 0) {

		VkBufferCopy copyRegion = { srcOffset ,dstOffset,size };
		vkCmdCopyBuffer(cmd, staging.buffer, _.buffer, 1, &copyRegion);
		return true;
	};


};
*/

struct TEST_AS {
	float v[12];
	int a;
};

struct  ObjectsVk {

	SRWLOCK                slim;
	///typedef tbb::concurrent_unordered_map<std::string, int, tbb::tbb_hash<std::string>, std::equal_to<std::string>, front::tbbTAllocator> tb_umapII;
	typedef tbb::concurrent_unordered_map<std::string, int, std::hash<std::string>, std::equal_to<std::string>, front::tbbTAllocator> tb_umapII;

	tb_umapII                           mth;
	tb_umapII                           inth;


	ObjectsVk();
	~ObjectsVk();
	void destroy();


	template<class T, class Mem>
	bool $AllocMemory$(T& cmder, Mem&  mach)
	{

		long orig = InterlockedCompareExchange(&(mach.id), INT32_MAX, -1);
		if (orig != -1) return false;

		Mvk   mem;
		{

			VkMemoryRequirements memReqs = {};
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			VkBuffer buffer;

			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.usage = 0xff;
			VkDeviceSize  offset = 0;
			mach.memSize = 0; memAlloc.allocationSize = 0;
			for (auto& v : mach.sizeSet) {
				BufferInfo.size = v;
				VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &buffer));
				vkGetBufferMemoryRequirements($device, buffer, &memReqs);
				vkDestroyBuffer($device, buffer, nullptr);
				memAlloc.allocationSize += memReqs.size;
				mach.memSize += BufferInfo.size;
				v = offset;
				offset += memReqs.size;
			};
			mach.reqSize = memAlloc.allocationSize;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &mem.memory));

		};


		Mem(Mvk, SIZE_MDev).$set$(std::move(mem), &mach.mem);
		
		int c = (int)mth.size();
		mth["memory" + std::to_string(c)] = (mach.mem.id);


		return true;

	};

	template<class Geom>
	bool $createDeviceBufferSeparate$(Geom& bach, VkDeviceMemory memory, VkBufferUsageFlags usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT)
	{

		long orig = InterlockedCompareExchange(&(bach.id), INT32_MAX, -1);
		if (orig != -1) return false;

		IBmvk   input;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = bach.size;
			BufferInfo.usage = usage | VK_BUFFER_USAGE_TRANSFER_DST_BIT;

			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &input.buffer));
			vkGetBufferMemoryRequirements($device, input.buffer, &memReqs);
			bach.reqSize = memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);

			VK_CHECK_RESULT(vkBindBufferMemory($device, input.buffer, memory, bach.offset));

		};



		bach.vkBuffer = input.buffer;
		input.info.buffer = input.buffer;
		input.info.offset = 0;
		input.info.range = bach.size;
		bach.info = input.info;
		Mem(IBmvk, SIZE_IBmDev).$set$(std::move(input), &bach.buffer);

		int c = (int)mth.size();
		mth["memory" + std::to_string(c)] = (bach.buffer.id);



		return true;
	};

	template<class Geom>
	bool createBufferView(Geom& bach, VkDeviceSize offset = 0,VkBufferUsageFlags usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT)
	{
		
			VkBufferView texel_view;
			VkBufferViewCreateInfo view_info = {};
			view_info.sType   = VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO;
			view_info.pNext   = NULL;
			view_info.buffer  = bach.vkBuffer;
			view_info.format  = bach.format;/// VK_FORMAT_R32_SFLOAT;
			view_info.offset   = offset;
			view_info.range    =  bach.size;
			vkCreateBufferView($device, &view_info, NULL, &texel_view);
			bach.vkView = texel_view;
			log_obj("Create BufferView  on ObjectsVk.    bufferView  %p\n", texel_view);

		    return true;

	};
	

	template<class T>
	bool $createBuffer$(T& bach,  VkMemoryPropertyFlags memTy)
	{

		long orig = InterlockedCompareExchange(&(bach.id), INT32_MAX, -1);
		if (orig != -1) return false;

		MBvk   asMb;
		VkBufferCreateInfo BufferInfo = {};
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
			BufferInfo.sType  = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size     = bach.size;
			BufferInfo.usage  = VK_BUFFER_USAGE_RAY_TRACING_BIT_NV | VK_BUFFER_USAGE_TRANSFER_DST_BIT;


			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &asMb.buffer));
			vkGetBufferMemoryRequirements($device, asMb.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, memTy);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &asMb.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, asMb.buffer, asMb.memory, 0));

		}

		Mem(MBvk, SIZE_MB).$set$(std::move(asMb), &bach.buffer);
		bach.info.buffer = bach.vkBuffer = asMb.buffer;
		bach.info.range   = BufferInfo.size;
		bach.info.offset = 0;


		int c = (int)inth.size();
		inth["buffer" + std::to_string(c)] = (bach.buffer.id);


		return true;

	};
	template<class T, class B>
	bool $createBuffer$(T& cmder, StoBache& bach,std::vector<B>& src, VkMemoryPropertyFlags memTy, VkBufferUsageFlags usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT)
	{

		long orig = InterlockedCompareExchange(&(bach.id), INT32_MAX, -1);
		if (orig != -1) return false;

		MBvk   asMb;
		VkBufferCreateInfo BufferInfo = {};
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;


			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = sizeof(B)* src.size();
			BufferInfo.usage = usage | VK_BUFFER_USAGE_TRANSFER_DST_BIT;


			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &asMb.buffer));
			vkGetBufferMemoryRequirements($device, asMb.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, memTy);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &asMb.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, asMb.buffer, asMb.memory, 0));

		}

		cmder.allocStaging(BufferInfo.size);

		cmder.Map(src.data(), 0, BufferInfo.size);



		cmder.begin();
		cmder.Copy(asMb, BufferInfo.size, 0, 0);
		cmder.end();
		cmder.submit();

		cmder.wait();

		Mem(MBvk, SIZE_MB).$set$(std::move(asMb), &bach.buffer);
		bach.info.buffer = bach.vkBuffer = asMb.buffer;
		bach.info.range = BufferInfo.size;
		bach.info.offset = 0;

		int c = (int)inth.size();
		inth["buffer" + std::to_string(c)] = (bach.buffer.id);


		return true;

	};

	template<class T, class AS>
	bool $createBuffer$(T& cmder, StoBache& bach,AS& as, VkMemoryPropertyFlags memTy)
	{

		long orig = InterlockedCompareExchange(&(bach.id), INT32_MAX, -1);
		if (orig != -1) return false;

		MBvk   asMb;
		VkBufferCreateInfo BufferInfo = {};
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = sizeof(AS);
			BufferInfo.usage = VK_BUFFER_USAGE_RAY_TRACING_BIT_NV | VK_BUFFER_USAGE_TRANSFER_DST_BIT;


			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &asMb.buffer));
			vkGetBufferMemoryRequirements($device, asMb.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits,memTy);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &asMb.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, asMb.buffer, asMb.memory, 0));

		}
		
		cmder.allocStaging(BufferInfo.size);

		cmder.Map(&as, 0, BufferInfo.size);



		cmder.begin();
		cmder.Copy(asMb,BufferInfo.size, 0, 0);
		cmder.end();
		cmder.submit();

		cmder.wait();

		Mem(MBvk, SIZE_MB).$set$(std::move(asMb), &bach.buffer);
		bach.info.buffer = bach.vkBuffer = asMb.buffer;
		bach.info.range = BufferInfo.size;
		bach.info.offset = 0;
		int c = (int)inth.size();
		inth["buffer" + std::to_string(c)] = (bach.buffer.id);


		return true;

	};

	template<class T, class O>
	bool $createBuffer$(T& cmder, std::vector<O*>& objs, MBvk& input, MBvk& index)
	{



		VkDeviceSize size = 0;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = input.count;
			BufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;

			size = BufferInfo.size;

			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &input.buffer));
			vkGetBufferMemoryRequirements($device, input.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &input.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, input.buffer, input.memory, 0));


			BufferInfo.size = index.count;

			size += BufferInfo.size;
			BufferInfo.usage = VK_BUFFER_USAGE_INDEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &index.buffer));
			vkGetBufferMemoryRequirements($device, index.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &index.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, index.buffer, index.memory, 0));

		}

		cmder.allocStaging(size);
		printf(" total map   1  %u   2 %u   \n", input.count, index.count);
		for (auto& obj : objs) {

			auto g = OBJ_GEOM(obj);
			auto& info = g->info.vert;
			info.buffer = input.buffer;
			cmder.Map(g->map(1), info.offset, g->array.memorySize);
			printf(" Map  vertex(%p)    offset %zu   range %zu   \n ", input.buffer, info.offset, info.range);
			auto& info2 = g->info.index;
			info2.buffer = index.buffer;
			cmder.Map(g->map(0), input.count + info2.offset, g->Size.index);
			printf(" Map  index(%p)    offset %zu     range %zu\n ", index.buffer, info2.offset, info2.range);

		}




		cmder.begin();
		cmder.Copy(input, input.count, 0, 0);
		cmder.Copy(index, index.count, input.count, 0);
		cmder.end();
		cmder.submit();

		cmder.wait();

	
		return true;

	};

	template<class T,class Geom>
	bool $createBuffer$(T& cmder,  Geom*& geometry, bool _createInfo)
	{

		long orig = InterlockedCompareExchange(&(geometry->id), INT32_MAX, -1);
		if (orig != -1) return false;

		MBvk   input;
		MBvk   index;
		VkDeviceSize size = 0;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = geometry->array.memorySize;
			BufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
			
			size    = geometry->array.memorySize;

			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &input.buffer));
			vkGetBufferMemoryRequirements($device, input.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &input.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, input.buffer, input.memory, 0));


			BufferInfo.size = geometry->Size.index;

			size += geometry->Size.index;
			BufferInfo.usage = VK_BUFFER_USAGE_INDEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &index.buffer));
			vkGetBufferMemoryRequirements($device, index.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &index.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, index.buffer, index.memory, 0));

		}

		cmder.allocStaging(size);

		cmder.Map(geometry->map(1), 0, geometry->array.memorySize);
		cmder.Map(geometry->map(0), geometry->array.memorySize, geometry->Size.index);


		cmder.begin();
		cmder.Copy(input, geometry->array.memorySize, 0, 0);
		cmder.Copy(index, geometry->Size.index, geometry->array.memorySize, 0);
		cmder.end();
		cmder.submit();
		
		
		if (_createInfo)$createVertexInfo$(geometry);
		index.count = geometry->updateRange.count;

		cmder.wait();

		Mem(MBvk,SIZE_MB).$set$(std::move(input), geometry);
		geometry->ID.vert = geometry->id;
		geometry->info.vert = {
			 .buffer = input.buffer,
			 .offset = 0,
			 .range = geometry->array.memorySize
		};


		Mem(MBvk,SIZE_MB).$set$(std::move(index), geometry);
		geometry->ID.index = geometry->id;
		geometry->info.index = {
	 .buffer = index.buffer,
	 .offset = 0,
	 .range = geometry->Size.index
		};

		int c = (int)inth.size();
		inth["vertex" + std::to_string(c)] = geometry->ID.vert;
		 c = (int)inth.size();
		inth["index" + std::to_string(c)] = geometry->ID.index;

		return true;

	};


	template<class T, class Geom>
	bool $createBufferInstanced$(T& cmder, Geom*& geometry, bool _createInfo,VkBufferUsageFlags usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,   VkMemoryPropertyFlags mem= VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
	{

		assert(geometry->instance != nullptr);

		if (geometry->attributes != nullptr)  $createBuffer$(cmder, geometry->attributes->buffer, false);

		long orig = InterlockedCompareExchange(&(geometry->instance->buffer->id), INT32_MAX, -1);
		if (orig != -1) return false;

		MBvk   insta;
	
		auto buf = geometry->instance->buffer;
		VkDeviceSize size = buf->array.memorySize;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType    = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size       = size;
			BufferInfo.usage    = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | usage;

			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &insta.buffer));
			vkGetBufferMemoryRequirements($device, insta.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, mem);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &insta.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, insta.buffer, insta.memory, 0));

		}

		cmder.allocStaging(size);
		cmder.Map(buf->map(1), 0, size);
		cmder.begin();
		cmder.Copy(insta, size, 0, 0);
		cmder.end();
		cmder.submit();

		$VInfo.$setInstanced$(geometry);


		cmder.wait();

		geometry->instance->buffer->info.attr.buffer = insta.buffer;
		geometry->instance->buffer->info.attr.range = size;
		geometry->instance->buffer->info.attr.offset = 0;

		Mem(MBvk,SIZE_MB).$set$(std::move(insta), buf);
		int c = (int)inth.size();
		inth["instance" + std::to_string(c)] = buf->id;



		return true;

	};


	template<class T, class Geom>
	bool $createSpriteBuffer$(T& cmder, Geom*& geometry, bool _createInfo)
	{

		long orig = InterlockedCompareExchange(&(geometry->id), INT32_MAX, -1);
		if (orig != -1) return false;
		MBvk   input;
		log_obj("create Sprite Buffer  %d    %x \n", geometry->id, input.buffer);

	
		VkDeviceSize size = 16*4;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType  = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size     =   size;
			BufferInfo.usage   = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;


			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &input.buffer));
			vkGetBufferMemoryRequirements($device, input.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &input.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, input.buffer, input.memory, 0));

		}


		static float invf[16] = { -1.f, -1.f,  0.f, 1.f,
					  1.f, -1.f  ,  1.f, 1.f,
					-1.f, 1.f    ,  0.f, 0.f,
					  1.f, 1.f   ,   1.f, 0.f
		};
		static float f[16] = { -1.f, -1.f,  0.f, 0.f,
							  1.f, -1.f  ,  1.f, 0.f,
							-1.f, 1.f    ,  0.f, 1.f,
							  1.f, 1.f   ,   1.f, 1.f
		};

		///memcpy(data, f, 16 * 4);
		log_obj("create Sprite Buffer  %d    %x  updateRange %d \n", geometry->id, input.buffer, geometry->updateRange.count);

		cmder.allocStaging(size);

		cmder.Map( (void*)f, 0, size);
		cmder.begin();
		cmder.Copy(input, size, 0, 0);
		cmder.end();
		cmder.submit();


		if (_createInfo)$createVertexInfo$(geometry,1);
		input.count = geometry->updateRange.count;

		cmder.wait();

		Mem(MBvk,SIZE_MB).$set$(std::move(input), geometry);
		geometry->ID.vert = geometry->id;
		geometry->ID.index = -1;
		int c = (int)inth.size();
		inth["sprite" + std::to_string(c)] = (geometry->ID.vert);

		return true;

	};


	template<class Geom>
	bool $createDeviceBuffer$(Geom& geometry, bool _createInfo, VkBufferUsageFlags usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT)
	{

		long orig = InterlockedCompareExchange(&(geometry.id), INT32_MAX, -1);
		if (orig != -1) return false;

		MBvk   input;
		VkDeviceSize size = geometry.array.memorySize;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = size;
			BufferInfo.usage = usage | VK_BUFFER_USAGE_TRANSFER_DST_BIT;



			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &input.buffer));
			vkGetBufferMemoryRequirements($device, input.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &input.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, input.buffer, input.memory, 0));

			if (_createInfo)$createVertexInfo$(&geometry);

		};



		Mem(MBvk,SIZE_MB).$set$(std::move(input), &geometry);
		geometry.ID.vert = geometry.id;
		int c = (int)inth.size();
		inth["mbvk" + std::to_string(c)] = (geometry.ID.vert);


		return true;
	};

	template<class T,class B>
	bool $BridgeMapBuffer$(T& cmder, B& dev, void* data, VkDeviceSize size,  VkDeviceSize dstOffset=0, VkDeviceSize srcOffset = 0)
	{

		cmder.allocStaging(size);
		cmder.Map(data, srcOffset, size);
		cmder.begin();
		cmder.Copy(dev, size, srcOffset, dstOffset);
		cmder.end();
		cmder.submit();
		cmder.wait();

		return true;

	};

	template<class T>
	bool $BridgeMapBuffer$(T& cmder, VkDescriptorBufferInfo& dev, void* data, VkDeviceSize srcOffset = 0)
	{

		cmder.allocStaging(dev.range);
		cmder.Map(data, srcOffset, dev.range);
		cmder.begin();
		cmder.Copy(dev, dev.range, srcOffset, dev.offset);
		cmder.end();
		cmder.submit();
		cmder.wait();

		return true;

	};


	template<typename Geom>
	void $createVertexInfo$(Geom* geometry, int type = 0) {
		if (uint32_t(geometry->array.type) >= uint32_t(arth::INPUT::ALL_TYPE)) { log_bad("Bad Input Type Come.\n"); }
		if (type == 1) {
			$VInfo.$setSprite$(geometry);
		}
		else {
			$VInfo.$set$(geometry);
		};
	};

	bool getVertexInfo(VkPipelineVertexInputStateCreateInfo*& info, arth::INPUT Ity);

	template<class Geom>
	bool getMemory(Mvk& mem, Geom& geometry) {
		return Mem(Mvk, SIZE_MDev).get(mem, &geometry);
	};

	template<class Geom>
	bool getBuffer(MBvk& mem,Geom* geometry) {
		geometry->id = geometry->ID.vert;
		return Mem(MBvk,SIZE_MB).get(mem, geometry);
	};
	
	template<class Geom>
	bool getIndex(MBvk& mem, Geom* geometry) {
		geometry->id = geometry->ID.index;
		return Mem(MBvk,SIZE_MB).get(mem, geometry);
	};
	
	template<class Geom>
	bool Delete(Geom* geometry) {

		bool ok = true;
		if (geometry->ID.index >= 0) {
			geometry->id = geometry->ID.index;
			ok &= Mem(MBvk,SIZE_MB).$delete$(geometry);
			geometry->ID.index = -1;
		};

		if (geometry->ID.vert >= 0) {
			geometry->id = geometry->ID.vert;
			ok &= Mem(MBvk,SIZE_MB).$delete$(geometry);
			geometry->ID.vert = -1;
		};

		return ok;

	};


	template<class Geom>
	bool DeleteMB(Geom& hach) {

		bool ok = true;
		if (hach.id == -1)return ok;
		ok &= Mem(MBvk, SIZE_MB).$delete$(&hach);

		return ok;

	};

	template<class Geom>
	bool DeleteIBm(Geom& hach) {

		bool ok = true;
		if (hach.id == -1)return ok;
		ok &= Mem(IBmvk, SIZE_IBmDev).$delete$(&hach);

		return ok;

	};

	template<class Geom>
	bool DeleteM(Geom& hach) {

		bool ok = true;
		if (hach.id == -1)return ok;
		ok &= Mem(Mvk, SIZE_MDev).$delete$(&hach);

		return ok;

	};

	/*
	void createInfo(_BufferAttribute* geometry);
	void createBuffers(Object3D* scene, bool useStagingBuffers);
	void updateGeometry(_BufferGeometry* geometry);
	void updateBuffer(_BufferAttribute* attribute);
	void destroyBufferAll();
	void destroyBuffer(_BufferAttribute* attribute);
	*/
	
};

struct  VisibleObjectsVk {

	SRWLOCK                slim;
	std::vector<long>                            uth;
	std::vector<long>                            mth;
	std::vector<long>                            ith;


	VisibleObjectsVk();
	~VisibleObjectsVk();
	void destroy();

	template<class O>
	bool get(MIBmvk& ubo, O* obj) {
		return Mem(MIBmvk, SIZE_MIBm).get(ubo,  obj);
	};
	
	template<class Mem>
	bool $AllocMemory$(Mem& mach)
	{

		long orig = InterlockedCompareExchange(&(mach.id), INT32_MAX, -1);
		if (orig != -1) return false;

		Mvk   mem;
		{

			VkMemoryRequirements memReqs = {};
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			VkBuffer buffer;

			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.usage = 0xff;
			VkDeviceSize  offset = 0;
			mach.memSize = 0; memAlloc.allocationSize = 0;
			for (auto& v : mach.sizeSet) {
				BufferInfo.size = v;
				VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &buffer));
				vkGetBufferMemoryRequirements($device, buffer, &memReqs);
				vkDestroyBuffer($device, buffer, nullptr);
				memAlloc.allocationSize += memReqs.size;
				mach.memSize += BufferInfo.size;
				v = offset;
				offset += memReqs.size;
			};
			mach.reqSize = memAlloc.allocationSize;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &mem.memory));


			VK_CHECK_RESULT(vkMapMemory($device, mem.memory, 0, mach.reqSize, 0, (void**)&mach.mapped));



		};

		Mem(Mvk, SIZE_MVis).$set$(std::move(mem), &mach.mem);
		

		AcquireSRWLockExclusive(&slim);
		mth.push_back(mach.mem.id);
		ReleaseSRWLockExclusive(&slim);
	
		return true;

	};


	template<class Geom>
	bool getMemory(Mvk& mem, Geom& geometry) {
		return Mem( Mvk, SIZE_MVis).get(mem,&geometry);
	};

	template<class Geom>
	bool $createBufferSeparate$(Geom& bach, VkDeviceMemory memory, VkBufferUsageFlags usage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT)
	{

		long orig = InterlockedCompareExchange(&(bach.id), INT32_MAX, -1);
		if (orig != -1) return false;

		IBmvk   input;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = bach.size;
			BufferInfo.usage = usage;

			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &input.buffer));
			vkGetBufferMemoryRequirements($device, input.buffer, &memReqs);
			bach.reqSize = memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

			VK_CHECK_RESULT(vkBindBufferMemory($device, input.buffer, memory, bach.offset));

		};


		bach.vkBuffer = input.buffer;
		input.info.buffer = input.buffer;
		input.info.offset = 0;
		input.info.range = bach.size;


		Mem(IBmvk,SIZE_IBmVis).$set$(std::move(input), &bach.buffer);
		AcquireSRWLockExclusive(&slim);
		ith.push_back(bach.buffer.id);
		ReleaseSRWLockExclusive(&slim);

		return true;
	};


	template<class O>
	void $createBuffer$(O& obj, VkBufferUsageFlags  usage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, VkMemoryPropertyFlags memTy= VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
	{

		long orig = InterlockedCompareExchange(&(obj.buffer.id), INT32_MAX, -1);
		if (orig != -1) return;

		MIBmvk   ubo;

		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo allocInfo = {};

			allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = obj.size;
			BufferInfo.usage = usage;
			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &ubo.buffer));
			vkGetBufferMemoryRequirements($device, ubo.buffer, &memReqs);
			allocInfo.allocationSize = memReqs.size;
			allocInfo.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits,memTy );


			obj.reqAlign = memReqs.alignment;
			obj.reqSize = memReqs.size;



			VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, &$Policy_AllocateMemory, &(ubo.memory)));
			VK_CHECK_RESULT(vkBindBufferMemory($device, ubo.buffer, ubo.memory, 0));

			ubo.info.buffer = obj.vkBuffer = ubo.buffer;
			ubo.info.offset = 0;
			ubo.info.range = obj.size;

			VK_CHECK_RESULT(vkMapMemory($device, ubo.memory, 0, obj.size, 0, (void**)&ubo.mapped));

			obj.mapped = ubo.mapped;
			log_obj(" Buffer Size %zu = [align %zu x ]  ReqSize %zu = [reqAlign %zu ]   \n", obj.size, obj.align, memReqs.size, memReqs.alignment);

		}

		Mem(MIBmvk, SIZE_MIBm).$set$(std::move(ubo), &obj.buffer);

		AcquireSRWLockExclusive(&slim);
		uth.push_back(obj.buffer.id);
		ReleaseSRWLockExclusive(&slim);


	};


	template<class O>
	void $createTexelBuffer$(O& obj)
	{

		long orig = InterlockedCompareExchange(&(obj.buffer.id), INT32_MAX, -1);
		if (orig != -1) return;

		MIBmvk   ubo;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo allocInfo = {};

			allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = obj.size;
			BufferInfo.usage = VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT;
			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &ubo.buffer));
			vkGetBufferMemoryRequirements($device, ubo.buffer, &memReqs);
			allocInfo.allocationSize = memReqs.size;
			allocInfo.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);


			obj.reqAlign = memReqs.alignment;
			obj.reqSize = memReqs.size;



			VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, &$Policy_AllocateMemory, &(ubo.memory)));
			VK_CHECK_RESULT(vkBindBufferMemory($device, ubo.buffer, ubo.memory, 0));


			///VkDeviceSize commit;
			///vkGetDeviceMemoryCommitment($device, ubo.memory, &commit);




			// Store information in the uniform's descriptor that is used by the descriptor set
			ubo.info.buffer = ubo.buffer;
			ubo.info.offset = 0;
			ubo.info.range = obj.size;

			VK_CHECK_RESULT(vkMapMemory($device, ubo.memory, 0, obj.size, 0, (void**)&ubo.mapped));
			obj.info = ubo.info;
			obj.mapped = ubo.mapped;
			log_obj(" Buffer Size %zu = [align %zu ]  ReqSize %zu = [reqAlign %zu ]   \n", obj.size, obj.align,  memReqs.size, memReqs.alignment);

		}



		Mem(MIBmvk, SIZE_MIBm).$set$(std::move(ubo), &obj.buffer);
		AcquireSRWLockExclusive(&slim);
		uth.push_back(obj.buffer.id);
		ReleaseSRWLockExclusive(&slim);
		
		{

			VkBufferView texel_view;
			VkBufferViewCreateInfo view_info = {};
			view_info.sType = VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO;
			view_info.pNext = NULL;
			view_info.buffer = ubo.buffer;
			view_info.format = obj.format;/// VK_FORMAT_R32_SFLOAT;
			view_info.offset = 0;
			view_info.range = obj.size;

			vkCreateBufferView($device, &view_info, NULL, &texel_view);

			obj.vkView = texel_view;


		};

	};

	template< class Geom>
	bool $createBufferInstanced$(Geom*& geometry, VkBufferUsageFlags usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_UNIFORM_TEXEL_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT)
	{

		assert(geometry->instance != nullptr);

		///if (geometry->attributes != nullptr)  $createBuffer$( geometry->attributes->buffer);

		long orig = InterlockedCompareExchange(&(geometry->instance->buffer->id), INT32_MAX, -1);
		if (orig != -1) return false;


		MIBmvk   insta;

		auto buf = geometry->instance->buffer;
		VkDeviceSize size = buf->array.memorySize;
		{

			VkMemoryRequirements memReqs;
			VkMemoryAllocateInfo memAlloc = {};
			memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;

			VkBufferCreateInfo BufferInfo = {};
			BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
			BufferInfo.size = size;
			BufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | usage;

			VK_CHECK_RESULT(vkCreateBuffer($device, &BufferInfo, nullptr, &insta.buffer));
			vkGetBufferMemoryRequirements($device, insta.buffer, &memReqs);
			memAlloc.allocationSize = memReqs.size;
			memAlloc.memoryTypeIndex = vka::shelve::getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
			VK_CHECK_RESULT(vkAllocateMemory($device, &memAlloc, nullptr, &insta.memory));
			VK_CHECK_RESULT(vkBindBufferMemory($device, insta.buffer, insta.memory, 0));

		}

		$VInfo.$setInstanced$(geometry);

		VK_CHECK_RESULT(vkMapMemory($device, insta.memory, 0, size, 0, (void**)&insta.mapped));



		geometry->instance->buffer->array.data =  (char*)insta.mapped;
		geometry->instance->buffer->info.attr.buffer = insta.buffer;
		geometry->instance->buffer->info.attr.range = size;
		geometry->instance->buffer->info.attr.offset = 0;

		Mem(MIBmvk, SIZE_MIBm).$set$(std::move(insta), geometry->instance->buffer);

		AcquireSRWLockExclusive(&slim);
		uth.push_back(geometry->instance->buffer->id);
		ReleaseSRWLockExclusive(&slim);

		return true;

	};
	


	template<class Geom>
	bool $delete$(Geom&  bach) {
		if (!erase(uth, bach.buffer))return false;
	   return Mem(MIBmvk, SIZE_MIBm).$delete$(&bach.buffer);
	};


	template<class Geom>
	bool $deleteIBM$(Geom& bach) {
		if (!erase(ith, bach.buffer))return false;
		return Mem(IBmvk, SIZE_IBmVis).$delete$(&bach.buffer);
	};


	template<class Geom>
	bool DeleteM(Geom& hach) {

		if(!erase(mth, hach))return false;
		bool ok = true;
		if (hach.id == -1)return ok;
		ok &= Mem(Mvk, SIZE_MVis).$delete$(&hach);

		return ok;

	};
	template<class B>
	bool erase(std::vector<long>& ve,B& ba) {
		bool found = false;
		AcquireSRWLockExclusive(&slim);
		size_t N = ve.size();
		int i = 0;
		for (; i < N; i++) {
			if (ve[i] == ba.id) {
				found = true;
				break;
			}
		}
	    ve.erase(ve.begin() + i);
		ReleaseSRWLockExclusive(&slim);
		return found;
	}

};

#include "core/common.hpp"
#include "math/common.hpp"

namespace ray {

	struct VkGeometryInstanceNV
	{
		/// Transform matrix, containing only the top 3 rows
		float transform[12];
		/// Instance index
		uint32_t instanceId : 24;
		/// Visibility mask
		uint32_t mask : 8;
		/// Index of the hit group which will be invoked when a ray hits the instance
		uint32_t hitGroupId : 24;
		/// Instance flags, such as culling
		uint32_t flags : 8;
		/// Opaque handle of the bottom-level acceleration structure
		uint64_t accelerationStructureHandle;
	};

	struct ASmemory {

		VkDeviceSize        req;
		VkDeviceSize        origin;

		VkDeviceMemory memory;

	};

	struct AccelerationStructure {

		VkAccelerationStructureInfoNV asInfo{ .sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_INFO_NV,  .pNext = nullptr,
									.type = VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV };

		ASmemory                                   mem;
		VkAccelerationStructureNV   astruct;
		uint64_t handle;
	};

	struct Instance
	{
		uint32_t                  blasId{ 0 };      // Index of the BLAS in m_blas
		uint32_t                  instanceId{ 0 };  // Instance Index (gl_InstanceID)
		uint32_t                  hitGroupId{ 0 };  // Hit group index in the SBT
		uint32_t                  mask{ 0xFF };     // Visibility mask, will be AND-ed with ray mask
		VkGeometryInstanceFlagsNV flags = VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV;
		Matrix4                   transform;  // Identity
	};


	struct Blas
	{
		AccelerationStructure      accel;
		VkGeometryNV                  geometry;
	};
	struct Tlas
	{
		AccelerationStructure      accel;

	};



};


struct  RtObjectsVk {
	SRWLOCK                slim;
	ObjectsVk* objVk = nullptr;
	VisibleObjectsVk* vobjVk = nullptr;
	vkmm::Allocator* allocator = VK_NULL_HANDLE;
	VkPhysicalDeviceRayTracingPropertiesNV rayTracingProperties{};

	
	struct AsCache {
		VkDeviceMemory memory;
#ifdef USE_TBB
		typedef tbb::concurrent_unordered_map<std::string, VkAccelerationStructureNV, std::hash<std::string>, std::equal_to<std::string>, front::tbbTAllocator> Map;
		Map asmap;
#else
		std::unordered_map<std::string, VkAccelerationStructureNV> asmap;
#endif
	};


	AsCache storage;
	AsCache storageT;



	struct {

		uint32_t memTypeOrgin;
	}cache;

	RtObjectsVk(vkmm::Allocator* allocator):allocator(allocator) {

		rayTracingProperties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV;
		VkPhysicalDeviceProperties2 deviceProps2{};
		deviceProps2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
		deviceProps2.pNext = &rayTracingProperties;
		vkGetPhysicalDeviceProperties2($physicaldevice, &deviceProps2);
		storage.memory = VK_NULL_HANDLE;
		storageT.memory = VK_NULL_HANDLE;
	}
	~RtObjectsVk() {

		if(storage.memory != VK_NULL_HANDLE)vkFreeMemory($device,storage.memory, nullptr);
		for (auto&[k,s ] : storage.asmap) {
			vkDestroyAccelerationStructureNV($device, s, nullptr);
		}

		if (storageT.memory != VK_NULL_HANDLE)vkFreeMemory($device, storageT.memory, nullptr);
		for (auto& [k, s] : storageT.asmap) {
			vkDestroyAccelerationStructureNV($device, s, nullptr);
		}
	
	};
	void probeMemorySizeAS(ray::AccelerationStructure& accel);
	template<typename T >
	bool allocateAS(VkDeviceSize cumSize, uint32_t        memoryTypeBits, VkDeviceMemory& mem,std::vector<T>&& las);

	 bool buildBlas(std::vector<ray::Blas>& blas,const std::vector<std::vector<VkGeometryNV>>& geoms,
		VkBuildAccelerationStructureFlagsNV flags = VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV);
	bool createInstances(StoBache& bach, std::vector<ray::Instance>& instances, std::vector<ray::Blas>& _blas);
	ray::Tlas buildTlas(const std::vector<ray::Instance>& instances, VkBuffer insta,
		VkBuildAccelerationStructureFlagsNV flags = VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV);

	VkAccelerationStructureNV  createBTlas(std::vector<Object3D*>&&  objs);

	VkDeviceSize copyShaderIdentifier(uint8_t* data, const uint8_t* shaderHandleStorage, uint32_t groupIndex);

	template<typename T>
	void createShaderBindingTable(T& sbt, VkPipeline pipe, uint32_t groupN);



};
/*




	







	//--------------------------------------------------------------------------------------------------
// Creating the top-level acceleration structure from the vector of Instance
// - See struct of Instance
// - The resulting TLAS will be stored in m_tlas
//




	

}
*/

#endif





