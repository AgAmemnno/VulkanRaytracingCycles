#include "pch_mm.h"
#include "working_mm.h"


MemExtern(MBvk, SIZE_MB);
MemExtern(MIBvk, SIZE_MIB);
MemExtern(MIBmvk, SIZE_MIBm);


MemExtern(Mvk, SIZE_MDev);
MemExtern(Mvk, SIZE_MVis);
MemExtern(IBmvk, SIZE_IBmDev);
MemExtern(IBmvk, SIZE_IBmVis);





vkPVISciMem::vkPVISciMem() { InitializeSRWLock(&SlimLock); }

bool vkPVISciMem::get(VkPipelineVertexInputStateCreateInfo*& info, arth::INPUT Ity) {

		if (Info[INPUT_String(Ity)].type == Ity) {
			info = &Info[INPUT_String(Ity)].info;
			log_obj(" Found   VertexInfo      %x    ", *info);
			return true;
		}
		return false;
}


///auto IndexType = []<typename  T>(const T & n) { return n.type; };
///static std::unordered_map<  arth::INPUT, vkPVISci, decltype(IndexType)>   VInfo(0, IndexType);





ObjectsVk::ObjectsVk() {
	InitializeSRWLock(&slim);


};
ObjectsVk::~ObjectsVk() { destroy(); };
void  ObjectsVk::destroy() {

	for (auto &[name,i] : inth) {
		Mem(MBvk, SIZE_MB).cache[i].dealloc();
	};

	for (auto& [name, i] : mth) {
		Mem(Mvk, SIZE_MDev).cache[i].dealloc();
	};


inth.clear();
mth.clear();

};
bool  ObjectsVk::getVertexInfo(VkPipelineVertexInputStateCreateInfo*& info, arth::INPUT Ity) {
	if (uint32_t(Ity) >= uint32_t(arth::INPUT::ALL_TYPE)) { log_bad("Bad Input Type Come.\n"); }
	return $VInfo.get(info, Ity);
};


VisibleObjectsVk::VisibleObjectsVk() :uth(0) ,ith(0),mth(0){
	InitializeSRWLock(&slim);
};
VisibleObjectsVk::~VisibleObjectsVk() { destroy(); };
void VisibleObjectsVk::destroy() {

	for (long i  :  uth) {
		Mem(MIBmvk, SIZE_MIBm).$kill$(i);
	};

	for (long i :ith){
		Mem(IBmvk, SIZE_IBmVis).$kill$(i);
	};

	for (long i : mth){
		Mem(Mvk, SIZE_MVis).$kill$(i);
	};

};





/*
_BufferGeometry* VkObjects::update(Object3D* object) {


	_BufferGeometry* geometry = (object->geometry);
	if (geometry->id < 0) {
		geometry->id = gid++;
		//printf("Add geometry    id::%d  \n", geometry->id);
	};

	if (geometry->needsUpdate)updateGeometry(geometry);

	return geometry;
};

void VkObjects::updateGeometry(_BufferGeometry* geometry) {


	geometry->needsUpdate = false;
	return;
};


void VkObjects::createBufferSprite(_BufferAttribute* geometry, bool _createInfo) {


	if (geometry->id >= 0)return;


	int idx = int(inputBuffer.size());

	inputBuffer.resize(idx + 1);
	indexBuffer.resize(idx + 1);

	geometry->id = idx;

	MBvk& input = inputBuffer[idx];
	MBvk& index = indexBuffer[idx];

	VkDeviceSize bufferSize = 4 * 4 * 4;  //TEXTOVERLAY_MAX_CHAR_COUNT * 4 * 4;

	VkBufferCreateInfo bufferInfo = vka::plysm::bufferCreateInfo(VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, bufferSize);
	VK_CHECK_RESULT(vkCreateBuffer(device, &bufferInfo, nullptr, &input.buffer));

	VkMemoryRequirements memReqs;
	VkMemoryAllocateInfo  allocInfo = vka::plysm::memoryAllocateInfo();

	vkGetBufferMemoryRequirements(device, input.buffer, &memReqs);
	allocInfo.allocationSize = memReqs.size;
	allocInfo.memoryTypeIndex = getMemoryType(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

	void* data;
	VK_CHECK_RESULT(vkAllocateMemory(device, &allocInfo, nullptr, &input.memory));
	VK_CHECK_RESULT(vkMapMemory(device, input.memory, 0, allocInfo.allocationSize, 0, &data));
	float invf[16] = { -1.f, -1.f,  0.f, 1.f,
						  1.f, -1.f  ,  1.f, 1.f,
						-1.f, 1.f    ,  0.f, 0.f,
						  1.f, 1.f   ,   1.f, 0.f
	};
	float f[16] = { -1.f, -1.f,  0.f, 0.f,
						  1.f, -1.f  ,  1.f, 0.f,
						-1.f, 1.f    ,  0.f, 1.f,
						  1.f, 1.f   ,   1.f, 1.f
	};
	memcpy(data, f, 16 * 4);
	///memcpy(data, vertexBuffer.data(), vertexBufferSize);
	vkUnmapMemory(device, input.memory);

	VK_CHECK_RESULT(vkBindBufferMemory(device, input.buffer, input.memory, 0));





	static arth::INPUT structType;

	structType = geometry->array.type;


	if (Info.count(structType) > 0) return;



	std::vector<VkVertexInputBindingDescription> Sprite_Bindings = {
	   vka::plysm::vertexInputBindingDescription(0,4 * 4, VK_VERTEX_INPUT_RATE_VERTEX),
	   vka::plysm::vertexInputBindingDescription(1,4 * 4, VK_VERTEX_INPUT_RATE_VERTEX)
	};

	Bindings[structType] = Sprite_Bindings;

	std::vector<VkVertexInputAttributeDescription> Sprite_Attributes = {
				vka::plysm::vertexInputAttributeDescription(0,  0, VK_FORMAT_R32G32_SFLOAT, 0),
				vka::plysm::vertexInputAttributeDescription(1,   1, VK_FORMAT_R32G32_SFLOAT, 4 * 2),
	};

	Attributes[structType] = Sprite_Attributes;

	VkPipelineVertexInputStateCreateInfo info = vka::plysm::pipelineVertexInputStateCreateInfo();
	info.vertexBindingDescriptionCount = static_cast<uint32_t>(Bindings[structType].size());
	info.pVertexBindingDescriptions = Bindings[structType].data();
	info.vertexAttributeDescriptionCount = static_cast<uint32_t>(Attributes[structType].size());
	info.pVertexAttributeDescriptions = Attributes[structType].data();

	Info[structType] = info;



}

void VkObjects::createBuffers(Object3D* scene, bool useStagingBuffers)
{


	void* data;


	struct StagingBuffer {
		VkDeviceMemory memory;
		VkBuffer buffer;
	};

	struct _stagingBuffers {
		StagingBuffer vertices;
		StagingBuffer indices;
		VkMemoryAllocateInfo memAlloc;
		VkMemoryRequirements memReqs;
	};

	std::unordered_map<uint32_t, _stagingBuffers*> cache;

	VkCommandBuffer copyCmd = beginCommandBuffer(false);
	VkCommandBufferBeginInfo cmdBufInfo = vka::plysm::commandBufferBeginInfo();
	VkSubmitInfo submitInfo = {};
	submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
	submitInfo.commandBufferCount = 1;
	submitInfo.pCommandBuffers = &copyCmd;

	// Create fence to ensure that the command buffer has finished executing
	VkFenceCreateInfo fenceCreateInfo = {};
	fenceCreateInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
	fenceCreateInfo.flags = 0;
	VkFence fence;


	///log_trace(">>>>>>>>>>>>>>>>>>>>create Fence<<<<<<<<<<<<<<<<<<<<<<<<<\n");
	VK_CHECK_RESULT(vkCreateFence(device, &fenceCreateInfo, nullptr, &fence));


	VkBufferCreateInfo vertexBufferInfo = {};
	vertexBufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;


	VkBufferCreateInfo indexbufferInfo = {};
	indexbufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;


	for (auto const& obj : scene->child) {

		_BufferAttribute* geom = obj->geometry->attributes->buffer;
		if (geom->id >= 0)continue;

		int idx = int(inputBuffer.size());

		inputBuffer.resize(idx + 1);
		indexBuffer.resize(idx + 1);

		geom->id = idx;

		MBvk& input = inputBuffer[idx];
		MBvk& index = indexBuffer[idx];

		input.version = geom->version;

		size_t size = geom->array.memorySize;
		vertexBufferInfo.size = size;
		indexbufferInfo.size = geom->Size.index;

		if (cache.count(size) == 0) {

			_stagingBuffers* stagingBuffers = new _stagingBuffers;
			vertexBufferInfo.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
			indexbufferInfo.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;

			VK_CHECK_RESULT(vkCreateBuffer(device, &vertexBufferInfo, nullptr, &stagingBuffers->vertices.buffer));
			vkGetBufferMemoryRequirements(device, stagingBuffers->vertices.buffer, &(stagingBuffers->memReqs));

			stagingBuffers->memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
			stagingBuffers->memAlloc.allocationSize = stagingBuffers->memReqs.size;
			stagingBuffers->memAlloc.memoryTypeIndex = getMemoryTypeIndex(stagingBuffers->memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

			VK_CHECK_RESULT(vkAllocateMemory(device, &stagingBuffers->memAlloc, nullptr, &stagingBuffers->vertices.memory));

			VK_CHECK_RESULT(vkCreateBuffer(device, &indexbufferInfo, nullptr, &stagingBuffers->indices.buffer));
			vkGetBufferMemoryRequirements(device, stagingBuffers->indices.buffer, &stagingBuffers->memReqs);
			stagingBuffers->memAlloc.allocationSize = stagingBuffers->memReqs.size;
			stagingBuffers->memAlloc.memoryTypeIndex = getMemoryTypeIndex(stagingBuffers->memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
			VK_CHECK_RESULT(vkAllocateMemory(device, &stagingBuffers->memAlloc, nullptr, &stagingBuffers->indices.memory));


			cache[size] = stagingBuffers;


		}

		_stagingBuffers& stg = *cache[size];

		VK_CHECK_RESULT(vkMapMemory(device, stg.vertices.memory, 0, stg.memAlloc.allocationSize, 0, &data));
		geom->map(data, 1);
		///memcpy(data, vertexBuffer.data(), vertexBufferSize);

		vkUnmapMemory(device, stg.vertices.memory);
		VK_CHECK_RESULT(vkBindBufferMemory(device, stg.vertices.buffer, stg.vertices.memory, 0));


		vertexBufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		VK_CHECK_RESULT(vkCreateBuffer(device, &vertexBufferInfo, nullptr, &input.buffer));
		vkGetBufferMemoryRequirements(device, input.buffer, &stg.memReqs);

		stg.memAlloc.allocationSize = stg.memReqs.size;
		stg.memAlloc.memoryTypeIndex = getMemoryTypeIndex(stg.memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
		VK_CHECK_RESULT(vkAllocateMemory(device, &stg.memAlloc, nullptr, &input.memory));
		VK_CHECK_RESULT(vkBindBufferMemory(device, input.buffer, input.memory, 0));


		VK_CHECK_RESULT(vkMapMemory(device, stg.indices.memory, 0, geom->Size.index, 0, &data));
		geom->map(data, 0);
		///memcpy(data, indexBuffer.data(),indexBufferSize);
		vkUnmapMemory(device, stg.indices.memory);
		VK_CHECK_RESULT(vkBindBufferMemory(device, stg.indices.buffer, stg.indices.memory, 0));

		indexbufferInfo.usage = VK_BUFFER_USAGE_INDEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		VK_CHECK_RESULT(vkCreateBuffer(device, &indexbufferInfo, nullptr, &index.buffer));
		vkGetBufferMemoryRequirements(device, index.buffer, &stg.memReqs);
		stg.memAlloc.allocationSize = stg.memReqs.size;
		stg.memAlloc.memoryTypeIndex = getMemoryTypeIndex(stg.memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
		VK_CHECK_RESULT(vkAllocateMemory(device, &stg.memAlloc, nullptr, &index.memory));
		VK_CHECK_RESULT(vkBindBufferMemory(device, index.buffer, index.memory, 0));


		VK_CHECK_RESULT(vkBeginCommandBuffer(copyCmd, &cmdBufInfo));
		VkBufferCopy copyRegion = {};
		copyRegion.size = geom->Size.array;
		vkCmdCopyBuffer(copyCmd, stg.vertices.buffer, input.buffer, 1, &copyRegion);
		copyRegion.size = geom->Size.index;
		vkCmdCopyBuffer(copyCmd, stg.indices.buffer, index.buffer, 1, &copyRegion);
		VK_CHECK_RESULT(vkEndCommandBuffer(copyCmd));


		VK_CHECK_RESULT(vkQueueSubmit(queue, 1, &submitInfo, fence));
		VK_CHECK_RESULT(vkWaitForFences(device, 1, &fence, VK_TRUE, DEFAULT_FENCE_TIMEOUT));
		VK_CHECK_RESULT(vkResetFences(device, 1, &fence));


		index.count = geom->updateRange.count;
		createInfo(geom);

		log_obj("buffer  initialized    %d ", geom->id);
	}

	vkDestroyFence(device, fence, nullptr);
	vkFreeCommandBuffers(device, cmdPool, 1, &copyCmd);

	for (const auto& [size, stg] : cache) {
		vkDestroyBuffer(device, stg->vertices.buffer, nullptr);
		vkFreeMemory(device, stg->vertices.memory, nullptr);
		vkDestroyBuffer(device, stg->indices.buffer, nullptr);
		vkFreeMemory(device, stg->indices.memory, nullptr);
	}


};

void VkObjects::updateBuffer(_BufferAttribute* attribute) {

	if (attribute->id < 0) {

		createBuffer(attribute, true);
		attribute->id = (int)inputBuffer.size() - 1;
		//printf("create buffer %s \n", attribute->name.c_str());

	}
	else {

		MBvk& data = inputBuffer[attribute->id];
		if (data.version < attribute->version) {
			log_error(" TODO :: updateBuffer  %zd  version %d\n", attribute->type, data.version);
			data.version = attribute->version;

		};

	};

};


void VkObjects::destroyBuffer(_BufferAttribute* attribute) {

	MBvk& data = inputBuffer[attribute->id];

	if (data.version != -1) {
		vkDestroyBuffer(device, data.buffer, nullptr);
		vkFreeMemory(device, data.memory, nullptr);
		data.version = -1;

		MBvk& data = indexBuffer[attribute->id];
		vkDestroyBuffer(device, data.buffer, nullptr);
		vkFreeMemory(device, data.memory, nullptr);
		data.version = -1;


	};

};


VkIObjects::VkIObjects()  {
	
};

VkIObjects::~VkIObjects() {
	dealloc();
};

void VkIObjects::dealloc() {

	for (const auto& i : instance) {
		vkDestroyBuffer(device, i.buffer, nullptr);
		vkFreeMemory(device, i.memory, nullptr);
	};

};
void VkIObjects::createBuffer(_BufferAttribute* geom, _BufferAttribute* insta, bool culling)
{
	if (geom->type != arth::GEOMETRY::BUFFER) {
		PyErr_BadArgument();
	};


	vertex.createBuffer(geom, false);

	if (insta->type != arth::GEOMETRY::INSTANCED) {
		PyErr_BadArgument();
	};

	VkMemoryAllocateInfo memAlloc = {};
	memAlloc.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
	VkMemoryRequirements memReqs;


	int idx = int(instance.size());

	instance.resize(idx + 1);

	insta->id = idx;


	MIBvk& _instance = instance[idx];

	insta->id = 0;
	_instance.version = insta->version;

	void* data;

	struct StagingBuffer {
		VkDeviceMemory memory;
		VkBuffer buffer;
	}stg;

	///log_trace("CreateBuffer   %zu", insta->array.memorySize);

	VkBufferCreateInfo vertexBufferInfo = {};
	vertexBufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
	vertexBufferInfo.size = insta->array.memorySize;
	vertexBufferInfo.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
	VK_CHECK_RESULT(vkCreateBuffer(device, &vertexBufferInfo, nullptr, &stg.buffer));
	vkGetBufferMemoryRequirements(device, stg.buffer, &memReqs);
	memAlloc.allocationSize = memReqs.size;

	memAlloc.memoryTypeIndex = getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
	VK_CHECK_RESULT(vkAllocateMemory(device, &memAlloc, nullptr, &stg.memory));
	// Map and copy
	VK_CHECK_RESULT(vkMapMemory(device, stg.memory, 0, memAlloc.allocationSize, 0, &data));
	insta->map(data, 1);
	///memcpy(data, vertexBuffer.data(), vertexBufferSize);
	vkUnmapMemory(device, stg.memory);
	VK_CHECK_RESULT(vkBindBufferMemory(device, stg.buffer, stg.memory, 0));
	if (culling) {
		vertexBufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
	}
	else {
		vertexBufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT;
	}

	VK_CHECK_RESULT(vkCreateBuffer(device, &vertexBufferInfo, nullptr, &_instance.buffer));
	vkGetBufferMemoryRequirements(device, _instance.buffer, &memReqs);
	memAlloc.allocationSize = memReqs.size;
	memAlloc.memoryTypeIndex = getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
	VK_CHECK_RESULT(vkAllocateMemory(device, &memAlloc, nullptr, &_instance.memory));
	VK_CHECK_RESULT(vkBindBufferMemory(device, _instance.buffer, _instance.memory, 0));


	VkCommandBuffer copyCmd = beginCommandBuffer(true);
	VkBufferCopy copyRegion = {};

	copyRegion.size = insta->array.memorySize;
	vkCmdCopyBuffer(copyCmd, stg.buffer, _instance.buffer, 1, &copyRegion);

	endCommandBuffer(copyCmd);


	vkDestroyBuffer(device, stg.buffer, nullptr);
	vkFreeMemory(device, stg.memory, nullptr);

	_instance.size = insta->array.arraySize;
	_instance.info.range = VK_WHOLE_SIZE;//  insta->array.memorySize;
	_instance.info.buffer = _instance.buffer;
	_instance.info.offset = 0;

	log_obj2("InstancedObjects  Create   Geometry Nums {%u}  Index {%u}  Instance Nums {%u}   \n", geom->Size.array, geom->Size.index, insta->Size.array);


	createInfo(geom, insta);
	///log_trace("CreateBuffer Instanced    %zu", insta->array.arraySize);
};


void VkIObjects::createInfo(_BufferAttribute* geom, _BufferAttribute* insta) {

	static arth::INPUT structType;
	///structType = (std::string(geom->repr()) + std::string(insta->repr())).c_str();
	structType = geom->array.type | insta->array.type;

	if (Info.count(structType) > 0) return;

	VkPipelineVertexInputStateCreateInfo info = vka::plysm::pipelineVertexInputStateCreateInfo();


	std::vector<VkVertexInputBindingDescription> vertexInputBindings = {
			vka::plysm::vertexInputBindingDescription(0,  geom->array.structSize, VK_VERTEX_INPUT_RATE_VERTEX),
			vka::plysm::vertexInputBindingDescription(1,   insta->array.structSize, VK_VERTEX_INPUT_RATE_INSTANCE)
	};

	Bindings[structType] = vertexInputBindings;


	std::vector<VkVertexInputAttributeDescription> vertexInputAttributes;

	int i = 0;
	for (i = 0; i < geom->array.fieldNum; i++) {
		vertexInputAttributes.push_back(vka::plysm::vertexInputAttributeDescription(0, i, geom->array.format[i], geom->array.offset[i]));
	};

	for (int i1 = 0; i1 < insta->array.fieldNum; i1++) {
		vertexInputAttributes.push_back(vka::plysm::vertexInputAttributeDescription(1, i + i1, insta->array.format[i1], insta->array.offset[i1]));
	};


	log_obj2("InstancedObjects  Information   GeometryBlock Nums %zu    InstanceBlock Nums %zu   \n", geom->array.fieldNum, insta->array.fieldNum);


	Attributes[structType] = vertexInputAttributes;

	info.vertexBindingDescriptionCount = static_cast<uint32_t>(Bindings[structType].size());
	info.pVertexBindingDescriptions = Bindings[structType].data();
	info.vertexAttributeDescriptionCount = static_cast<uint32_t>(Attributes[structType].size());
	info.pVertexAttributeDescriptions = Attributes[structType].data();

	Info[structType] = info;

};


VkCommandBuffer VkIObjects::beginCommandBuffer(bool begin)
{
	VkCommandBuffer cmdBuffer;

	VkCommandBufferAllocateInfo cmdBufAllocateInfo = {};
	cmdBufAllocateInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
	cmdBufAllocateInfo.commandPool = cmdPool;
	cmdBufAllocateInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
	cmdBufAllocateInfo.commandBufferCount = 1;

	VK_CHECK_RESULT(vkAllocateCommandBuffers(device, &cmdBufAllocateInfo, &cmdBuffer));

	// If requested, also start the new command buffer
	if (begin)
	{
		VkCommandBufferBeginInfo cmdBufInfo = vka::plysm::commandBufferBeginInfo();
		VK_CHECK_RESULT(vkBeginCommandBuffer(cmdBuffer, &cmdBufInfo));
	}

	return cmdBuffer;
}
void VkIObjects::endCommandBuffer(VkCommandBuffer commandBuffer)
{
	assert(commandBuffer != VK_NULL_HANDLE);
	VK_CHECK_RESULT(vkEndCommandBuffer(commandBuffer));

	VkSubmitInfo submitInfo = {};
	submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
	submitInfo.commandBufferCount = 1;
	submitInfo.pCommandBuffers = &commandBuffer;

	// Create fence to ensure that the command buffer has finished executing
	VkFenceCreateInfo fenceCreateInfo = {};
	fenceCreateInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
	fenceCreateInfo.flags = 0;
	VkFence fence;

	///log_trace(">>>>>>>>>>>>>>>>>>>>End  PassVk createCommandBuffers Fence<<<<<<<<<<<<<<<<<<<<<<<<<\n");
	VK_CHECK_RESULT(vkCreateFence(device, &fenceCreateInfo, nullptr, &fence));

	// Submit to the queue
	VK_CHECK_RESULT(vkQueueSubmit(queue, 1, &submitInfo, fence));
	// Wait for the fence to signal that command buffer has finished executing
	VK_CHECK_RESULT(vkWaitForFences(device, 1, &fence, VK_TRUE, DEFAULT_FENCE_TIMEOUT));


	log_obj("Destroy     CommandBuffer  %p   \n", commandBuffer);
	log_obj("Destroy     Fence  %p   \n", fence);

	vkDestroyFence(device, fence, nullptr);
	vkFreeCommandBuffers(device, cmdPool, 1, &commandBuffer);
}


MIBvk& VkIObjects::getInstance(_BufferAttribute* attribute) {
	if (attribute->id < 0) {
		PyErr_BadInternalCall();
	}
	return instance[attribute->id];
};
MBvk& VkIObjects::getInput(_BufferAttribute* attribute) {
	if (attribute->id < 0) {
		PyErr_BadInternalCall();
	}
	return vertex.inputBuffer[attribute->id];
};

MBvk& VkIObjects::getIndex(_BufferAttribute* attribute) {
	if (attribute->id < 0) {
		PyErr_BadInternalCall();
	}
	return vertex.indexBuffer[attribute->id];
};

*/