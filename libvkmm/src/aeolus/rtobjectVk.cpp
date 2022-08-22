#include "pch_mm.h"
#include "working_mm.h"

using namespace  ray;
void RtObjectsVk::probeMemorySizeAS(AccelerationStructure& accel) {



	VkAccelerationStructureCreateInfoNV createinfo{ VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV };
	createinfo.info = accel.asInfo;
	VK_CHECK_RESULT(vkCreateAccelerationStructureNV($device, &createinfo, nullptr, &accel.astruct));

	


	VkMemoryRequirements2 reqMem{};

	VkAccelerationStructureMemoryRequirementsInfoNV memoryRequirementsInfo{};
	memoryRequirementsInfo.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_INFO_NV;
	memoryRequirementsInfo.accelerationStructure = accel.astruct;

	memoryRequirementsInfo.type = VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_BUILD_SCRATCH_NV;
	vkGetAccelerationStructureMemoryRequirementsNV($device, &memoryRequirementsInfo, &reqMem);
	accel.mem.req = reqMem.memoryRequirements.size;

	memoryRequirementsInfo.type = VK_ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_TYPE_OBJECT_NV;
	vkGetAccelerationStructureMemoryRequirementsNV($device, &memoryRequirementsInfo, &reqMem);
	accel.mem.origin = reqMem.memoryRequirements.size;
	cache.memTypeOrgin = reqMem.memoryRequirements.memoryTypeBits;

	
};

template<typename T >
bool RtObjectsVk::allocateAS(VkDeviceSize cumSize, uint32_t        memoryTypeBits, VkDeviceMemory& mem, std::vector<T>&& las) {



	VkMemoryAllocateInfo memoryAllocateInfo = {}; memoryAllocateInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
	memoryAllocateInfo.allocationSize = cumSize;
	memoryAllocateInfo.memoryTypeIndex = vka::shelve::getMemoryType(memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
	VK_CHECK_RESULT(vkAllocateMemory($device, &memoryAllocateInfo, nullptr, &mem));
;

	VkDeviceSize ofs = 0;

	for (auto& as : las) {
		VkBindAccelerationStructureMemoryInfoNV accelerationStructureMemoryInfo{};
		accelerationStructureMemoryInfo.sType = VK_STRUCTURE_TYPE_BIND_ACCELERATION_STRUCTURE_MEMORY_INFO_NV;
		accelerationStructureMemoryInfo.accelerationStructure = as.accel.astruct;
		accelerationStructureMemoryInfo.memory = mem;
		accelerationStructureMemoryInfo.memoryOffset = ofs;
		VK_CHECK_RESULT(vkBindAccelerationStructureMemoryNV($device, 1, &accelerationStructureMemoryInfo));
		VK_CHECK_RESULT(vkGetAccelerationStructureHandleNV($device, as.accel.astruct, sizeof(uint64_t), &as.accel.handle));
		ofs += as.accel.mem.origin;
	};
	return true;

}
template bool RtObjectsVk::allocateAS(VkDeviceSize cumSize, uint32_t        memoryTypeBits, VkDeviceMemory& mem, std::vector<Blas>&& las);
template bool RtObjectsVk::allocateAS(VkDeviceSize cumSize, uint32_t        memoryTypeBits, VkDeviceMemory& mem,std::vector<Tlas>&& las);

template<typename T>
void RtObjectsVk::createShaderBindingTable(T& sbt, VkPipeline pipe, uint32_t groupN) {
	if (vobjVk == nullptr) {
		if (!$tank.takeout(vobjVk, 0)) {
			log_bad(" not found  VisibleObjectVk.");
		};
	};

	sbt.size = rayTracingProperties.shaderGroupBaseAlignment * groupN;
	sbt.buffer.id = -1;
	vobjVk->$createBuffer$(sbt, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

	auto shaderHandleStorage = new uint8_t[sbt.size];
	VK_CHECK_RESULT(vkGetRayTracingShaderGroupHandlesNV($device, pipe, 0, groupN, sbt.size, shaderHandleStorage));
	auto* data = static_cast<uint8_t*>(sbt.mapped);
	for (uint32_t i = 0; i < groupN; i++) {
		data += copyShaderIdentifier(data, shaderHandleStorage, i);
	}

	delete[] shaderHandleStorage;

}

template void RtObjectsVk::createShaderBindingTable(StoBache& sbt, VkPipeline pipe, uint32_t groupN);


 bool RtObjectsVk::buildBlas(std::vector<Blas> & _blas,const std::vector<std::vector<VkGeometryNV>>& geoms,
	VkBuildAccelerationStructureFlagsNV flags)
{
	///m_blas.resize(geoms.size());
	/// 	std::vector<Blas> _blas;
	/// 
	 _blas.resize(geoms.size());

	VkDeviceSize maxScratch{ 0 };
	VkDeviceSize cumSize{ 0 };
	/* Is compaction requested?
	bool doCompaction = (flags & VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_NV)
		== VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_NV;
	///originalSizes.resize(m_blas.size());
	*/
	// Iterate over the groups of geometries, creating one BLAS for each group
	for (size_t i = 0; i < geoms.size(); i++)
	{
		Blas& blas{ _blas[i] };
		AccelerationStructure& accel = blas.accel;
		// Set the geometries that will be part of the BLAS
		accel.asInfo.geometryCount = static_cast<uint32_t>(geoms[i].size());
		accel.asInfo.pGeometries = geoms[i].data();
		accel.asInfo.flags = flags;

		probeMemorySizeAS(accel);
		storage.asmap["geom" + std::to_string(i)] = accel.astruct;
		///m_debug.setObjectName(blas.as.accel, (std::string("Blas" + std::to_string(i)).c_str()));
		maxScratch = __max(maxScratch, accel.mem.req);
		cumSize += accel.mem.origin;
	}

	allocateAS(cumSize, cache.memTypeOrgin, _blas[0].accel.mem.memory,std::move(_blas));
	storage.memory = _blas[0].accel.mem.memory;


	// Allocate the scratch buffers holding the temporary data of the acceleration structure builder

	StoBache    tmp;

	vkmm::Allocation_T* alloc = {};	
	VkBufferCreateInfo BufferInfo = {};
	BufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
	BufferInfo.size = maxScratch;
	BufferInfo.usage = VK_BUFFER_USAGE_RAY_TRACING_BIT_NV | VK_BUFFER_USAGE_TRANSFER_DST_BIT;

	vkmm::AllocationCreateInfo ainfo;
	ainfo.flags = vkmm::ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;/// | vkmm::ALLOCATION_CREATE_MAPPED_BIT;
	ainfo.usage = vkmm::MEMORY_USAGE_GPU_ONLY;  //vkmm::MEMORY_USAGE_CPU_TO_GPU;
	ainfo.pool = VK_NULL_HANDLE;
	ainfo.memoryTypeBits = 0;
	ainfo.requiredFlags = 0;
	ainfo.preferredFlags = 0;

	strcpy(ainfo.name, "rtobj_temp1");
	vkmm::CreateBuffer(*allocator, &BufferInfo, ainfo, &tmp.vkBuffer, &alloc, NULL);

	/*
	tmp.id = -1;
	tmp.size = maxScratch;
	objVk->$createBuffer$(tmp, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
	*/

	/* Query size of compact BLAS
	VkQueryPoolCreateInfo qpci{ VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO };
	qpci.queryCount = (uint32_t)m_blas.size();
	qpci.queryType = VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_NV;
	VkQueryPool queryPool;
	vkCreateQueryPool(m_device, &qpci, nullptr, &queryPool);
	*/
	// Create a command buffer containing all the BLAS builds
	/*
	nvvk::CommandPool            genCmdBuf(m_device, m_queueIndex);
	std::vector<VkCommandBuffer> allCmdBufs;
	allCmdBufs.reserve(m_blas.size());
	*/
	///int                          ctr{ 0 };
	ImmidiateBufferCmd<ImmidiateCmdPool3> cmds;
	cmds.allocCmd(_blas.size());
	cmds.setInfo(VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT);
	for (int i = 0; i < _blas.size(); i++) {

		auto& blas = _blas[i];
		VkCommandBuffer cmdBuf = cmds.begin(i);
		vkCmdBuildAccelerationStructureNV(cmdBuf, &blas.accel.asInfo, nullptr, 0, VK_FALSE, blas.accel.astruct, nullptr, tmp.vkBuffer, 0);

		// Since the scratch buffer is reused across builds, we need a barrier to ensure one build
		// is finished before starting the next one
		VkMemoryBarrier barrier{ VK_STRUCTURE_TYPE_MEMORY_BARRIER };
		barrier.srcAccessMask = VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_NV;
		barrier.dstAccessMask = VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_NV;
		vkCmdPipelineBarrier(cmdBuf, VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_NV,
			VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_NV, 0, 1, &barrier, 0, nullptr, 0, nullptr);
		/*Query the compact size
		if (doCompaction)
		{
			vkCmdWriteAccelerationStructuresPropertiesNV(cmdBuf, 1, &blas.as.accel,
				VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_NV, queryPool, ctr++);
		}
		*/
		cmds.end();
	}
	
	cmds.submit(-1);
	cmds.wait();



	/* Compacting all BLAS
	if (doCompaction)
	{
		VkCommandBuffer cmdBuf = genCmdBuf.createCommandBuffer();

		// Get the size result back
		std::vector<VkDeviceSize> compactSizes(m_blas.size());
		vkGetQueryPoolResults(m_device, queryPool, 0, (uint32_t)compactSizes.size(), compactSizes.size() * sizeof(VkDeviceSize),
			compactSizes.data(), sizeof(VkDeviceSize), VK_QUERY_RESULT_WAIT_BIT);


		// Compacting
		std::vector<nvvk::AccelNV> cleanupAS(m_blas.size());
		uint32_t                   totOriginalSize{ 0 }, totCompactSize{ 0 };
		for (int i = 0; i < m_blas.size(); i++)
		{
			LOGI("Reducing %i, from %d to %d \n", i, originalSizes[i], compactSizes[i]);
			totOriginalSize += (uint32_t)originalSizes[i];
			totCompactSize += (uint32_t)compactSizes[i];

			// Creating a compact version of the AS
			VkAccelerationStructureInfoNV asInfo{ VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_INFO_NV };
			asInfo.type = VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_NV;
			asInfo.flags = flags;
			VkAccelerationStructureCreateInfoNV asCreateInfo{ VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_NV };
			asCreateInfo.compactedSize = compactSizes[i];
			asCreateInfo.info = asInfo;
			auto as = m_alloc->createAcceleration(asCreateInfo);

			// Copy the original BLAS to a compact version
			vkCmdCopyAccelerationStructureNV(cmdBuf, as.accel, m_blas[i].as.accel, VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_NV);

			cleanupAS[i] = m_blas[i].as;
			m_blas[i].as = as;
		}
		genCmdBuf.submitAndWait(cmdBuf);

		// Destroying the previous version
		for (auto as : cleanupAS)
			m_alloc->destroy(as);

		LOGI("------------------\n");
		LOGI("Total: %d -> %d = %d (%2.2f%s smaller) \n", totOriginalSize, totCompactSize,
			totOriginalSize - totCompactSize, (totOriginalSize - totCompactSize) / float(totOriginalSize) * 100.f, "%%");
	}
			vkDestroyQueryPool(m_device, queryPool, nullptr);
	*/

	vkmm::DestroyBuffer(*allocator, tmp.vkBuffer, alloc);
	//objVk->DeleteMB(tmp.buffer);



	return true;

};

bool RtObjectsVk::createInstances(StoBache& bach, std::vector<Instance>& instances, std::vector<Blas>& _blas)
{
	std::vector<VkGeometryInstanceNV> geometryInstances;

	geometryInstances.reserve(instances.size());
	Matrix4 transp;
	for (auto& instance : instances)
	{

		Blas& blas{ _blas[instance.blasId] };
		// For each BLAS, fetch the acceleration structure handle that will allow the builder to
		// directly access it from the device
		VkGeometryInstanceNV gInst{};
		// The matrices for the instance transforms are row-major, instead of column-major in the
		// rest of the application
		transp.copy(&(instance.transform))->transpose()->toFloat();


		// The gInst.transform value only contains 12 values, corresponding to a 4x3 matrix, hence
		// saving the last row that is anyway always (0,0,0,1). Since the matrix is row-major,
		// we simply copy the first 12 values of the original 4x4 matrix
		memcpy(gInst.transform, &transp.f[0], sizeof(gInst.transform));
		gInst.instanceId = instance.instanceId;
		gInst.mask = instance.mask;
		gInst.hitGroupId = instance.hitGroupId;
		gInst.flags = static_cast<uint32_t>(instance.flags);
		gInst.accelerationStructureHandle = blas.accel.handle;

		geometryInstances.push_back(gInst);

	}

	ImmidiateBufferCmd<ImmidiateCmdPool> cmd;

	bach.id = -1;
	objVk->$createBuffer$(cmd, bach, geometryInstances, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV);
	//m_debug.setObjectName(m_instBuffer.buffer, "TLASInstances");
	return  true;
}


Tlas RtObjectsVk::buildTlas(const std::vector<Instance>& instances, VkBuffer insta,
	VkBuildAccelerationStructureFlagsNV flags)
{

	Tlas tlas;
	tlas.accel.asInfo.type = VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV;

	tlas.accel.asInfo.instanceCount = static_cast<uint32_t>(instances.size());
	tlas.accel.asInfo.flags = flags;

	probeMemorySizeAS(tlas.accel);

	allocateAS(tlas.accel.mem.origin, cache.memTypeOrgin, tlas.accel.mem.memory,std::vector<Tlas>{ tlas });
	storageT.asmap["tlas1"] = tlas.accel.astruct;
	storageT.memory = tlas.accel.mem.memory;



	///m_debug.setObjectName(m_tlas.as.accel, "Tlas");
	// Allocate the scratch memory
	StoBache    tmp;
	tmp.id = -1;
	tmp.size = tlas.accel.mem.req;
	//objVk->$createBuffer$(tmp, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
	objVk->$createBuffer$(tmp, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT);

	// Building the TLAS


	ImmidiateBufferCmd<ImmidiateCmdPool> cmds;
	cmds.begin();
	// Make sure the copy of the instance buffer are copied before triggering the
	// acceleration structure build
	VkMemoryBarrier barrier{ VK_STRUCTURE_TYPE_MEMORY_BARRIER };
	barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
	barrier.dstAccessMask = VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR;
	vkCmdPipelineBarrier(cmds.cmd, VK_PIPELINE_STAGE_TRANSFER_BIT, VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_NV,
		0, 1, &barrier, 0, nullptr, 0, nullptr);


	// Build the TLAS
	vkCmdBuildAccelerationStructureNV(cmds.cmd, &tlas.accel.asInfo, insta, 0, VK_FALSE, tlas.accel.astruct, nullptr, tmp.vkBuffer, 0);

	cmds.end();
	cmds.submit();
	cmds.wait();


	objVk->DeleteMB(tmp.buffer);


	return tlas;

}


VkAccelerationStructureNV RtObjectsVk::createBTlas(std::vector<Object3D*>&&  objs) {

	if (objVk == nullptr) {
		if (!$tank.takeout(objVk, 0)) {
			log_bad(" not found  ObjectVk.");
		};
	};


	std::vector<std::vector<VkGeometryNV>> geoms;
	std::vector<int> geomID;

	std::map< uint64_t, int> cacheGeom;
	int geomNum = 0;
	for (auto& obj : objs) {
	
		std::vector<VkGeometryNV> geom;

		if (cacheGeom.count(uint64_t(obj->geometry->attributes)) > 0) {
			cacheGeom[uint64_t(obj->geometry->attributes)]++;
			obj->Type.ID = cacheGeom[uint64_t(obj->geometry->attributes)];
			continue;
		}

		obj->geometry->nums = geomNum++;
		cacheGeom[uint64_t(obj->geometry->attributes)] = 1;


		auto  vary = obj->geometry->attributes->buffer->array;
	
		VkGeometryNV geometry{};
		geometry.sType = VK_STRUCTURE_TYPE_GEOMETRY_NV;
		geometry.geometryType = VK_GEOMETRY_TYPE_TRIANGLES_NV;
		geometry.geometry.triangles.sType = VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV;

		geometry.geometry.triangles.vertexCount = vary.arraySize;
		geometry.geometry.triangles.vertexStride = vary.structSize;
		geometry.geometry.triangles.vertexFormat = VK_FORMAT_R32G32B32_SFLOAT;

		geometry.geometry.triangles.indexCount = obj->geometry->attributes->buffer->updateRange.count;
		geometry.geometry.triangles.indexType = VK_INDEX_TYPE_UINT32;
		geometry.geometry.triangles.transformData = VK_NULL_HANDLE;
		geometry.geometry.triangles.transformOffset = 0;
		geometry.geometry.aabbs = {};
		geometry.geometry.aabbs.sType = { VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV };
		geometry.flags = VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_KHR;// VK_GEOMETRY_OPAQUE_BIT_NV;

		obj->Type.ID = 1;
#ifndef VKMM_ALLOC
		auto vinfo = obj->geometry->attributes->buffer->info.vert;
		auto iinfo = obj->geometry->attributes->buffer->info.index;
		geometry.geometry.triangles.vertexData = vinfo.buffer;
		geometry.geometry.triangles.vertexOffset = vinfo.offset;
		geometry.geometry.triangles.indexData = iinfo.buffer;
		geometry.geometry.triangles.indexOffset = iinfo.offset;
		/*
		MBvk       vert;
		MBvk       index;
		obj->Type.ID = 1;
		if (!objVk->getBuffer(vert, obj->geometry->attributes->buffer))log_bad("Mutable Group can't get Buffer Information.\n");
		if (!objVk->getIndex(index, obj->geometry->attributes->buffer))log_bad("Mutable Group can't get Index Buffer Information.\n");
		geometry.geometry.triangles.vertexData = vert.buffer;
		geometry.geometry.triangles.vertexOffset = 0;
		geometry.geometry.triangles.indexData = index.buffer;
		geometry.geometry.triangles.indexOffset = 0;
		*/
#else


		auto vinfo = obj->geometry->attributes->buffer->info.vert;
		auto iinfo = obj->geometry->attributes->buffer->info.index;
		geometry.geometry.triangles.vertexData = vinfo.buffer;
		geometry.geometry.triangles.vertexOffset  = vinfo.offset;
		geometry.geometry.triangles.indexData       = iinfo.buffer;
		geometry.geometry.triangles.indexOffset   = iinfo.offset;

#endif

		geom.push_back(geometry);
		geoms.push_back(geom);
		geomID.push_back(obj->draw.gid);

	}

	std::vector<std::vector<VkGeometryNV>> _geoms(geomID.size());
	int i = 0;
	for (auto& id : geomID) _geoms[id] = geoms[i++];
	
	std::vector<Blas> blas;

    buildBlas(blas,_geoms);

	StoBache insta; insta.id = -1;
	std::vector<Instance> instances;

	instances.resize(objs.size());
	i = 0;
	std::vector<int> IID(geomID.size(),0);

	for (auto& obj : objs) {
		auto& inst = instances[i];

		inst.mask = 0xFF;
		inst.transform.copy(obj->matrix);
		inst.instanceId = obj->draw.gid;// obj->draw.gid * 100 + IID[obj->draw.gid]++;//0x800000 | (50 - uint32_t(i++));// uint32_t(i++);
		inst.blasId = obj->draw.gid;
		inst.hitGroupId = obj->draw.pid;
		i++;
	}
	createInstances(insta, instances, blas);

	auto tlas = buildTlas(instances, insta.vkBuffer);

	return  tlas.accel.astruct;
};

VkDeviceSize RtObjectsVk::copyShaderIdentifier(uint8_t* data, const uint8_t* shaderHandleStorage, uint32_t groupIndex) {
	const uint32_t shaderGroupHandleSize = rayTracingProperties.shaderGroupBaseAlignment;// ;
	memcpy(data, shaderHandleStorage + groupIndex * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
	return shaderGroupHandleSize;
}




