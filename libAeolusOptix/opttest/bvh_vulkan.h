#pragma once
//#define __BVH_VULKAN_H__
#ifndef __BVH_VULKAN_H__
#define __BVH_VULKAN_H__
/*
 * Copyright 2019, NVIDIA Corporation.
 * Copyright 2019, Blender Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#include "RedisUtils.h"
#  include "bvh/bvh.h"
#  include "bvh/bvh_params.h"
#  include "device/device_memory.h"

CCL_NAMESPACE_BEGIN

class Geometry;
class Optix;
//VkAccelerationStructureInstanceNV
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


//class BVHVulkan : public BVH {
   // friend class BVH;
class BVHVulkan{

private:

	ObjectsVk* objVk = nullptr;

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



public:
	std::vector<ccl::Mesh*> meshs;
	std::vector<ccl::Object*> objs;
	std::vector<VkDescriptorBufferInfo>   infoV;
	std::vector<VkDescriptorBufferInfo>   infoI;
	std::vector<int>                             primOffset;

	StoBache insta;
    RedisUtils* rpack;
	BVHVulkan(vkmm::Allocator* allocator, RedisUtils* rd) :allocator(allocator) {
		rpack = rd;
		rayTracingProperties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV;
		VkPhysicalDeviceProperties2 deviceProps2{};
		deviceProps2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
		deviceProps2.pNext = &rayTracingProperties;
		vkGetPhysicalDeviceProperties2($physicaldevice, &deviceProps2);
		insta.vkBuffer = VK_NULL_HANDLE;
	}
	~BVHVulkan() {
		
		if(insta.vkBuffer != VK_NULL_HANDLE)
			objVk->DeleteMB(insta.buffer);

		for (auto& obj : objs) {
			memset(obj, 0, sizeof(obj));
			//delete obj;
		}
		for (auto& mesh : meshs) {
			memset(mesh, 0, sizeof(mesh));
		}

		vkFreeMemory($device, storage.memory, nullptr);
		for (auto& [k, s] : storage.asmap) {
			vkDestroyAccelerationStructureNV($device, s, nullptr);
		}

		vkFreeMemory($device, storageT.memory, nullptr);
		for (auto& [k, s] : storageT.asmap) {
			vkDestroyAccelerationStructureNV($device, s, nullptr);
		}


	};

    //virtual void build(Progress& progress, Stats*) override;
    //virtual void copy_to_device(Progress& progress, DeviceScene* dscene) override;
	void probeMemorySizeAS(AccelerationStructure& accel) {

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
	bool allocateAS(VkDeviceSize cumSize, uint32_t        memoryTypeBits, VkDeviceMemory& mem, std::vector<T>&& las) {

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

	bool buildBlas(std::vector<Blas>& _blas, const std::vector<std::vector<VkGeometryNV>>& geoms,
		VkBuildAccelerationStructureFlagsNV flags = VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV)
	{

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

		allocateAS(cumSize, cache.memTypeOrgin, _blas[0].accel.mem.memory, std::move(_blas));
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
		//cmds.allocCmd(1);
		cmds.setInfo(VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT);
		for (int i = 0; i < _blas.size(); i++) {

			auto& blas = _blas[i];
			//VkCommandBuffer cmdBuf = cmds.begin(0);
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
			//cmds.submit(0);
			//cmds.wait();
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



		return true;

	};
	Tlas buildTlas( VkBuffer insta, uint32_t count,
		VkBuildAccelerationStructureFlagsNV flags = VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_NV)
	{

		Tlas tlas;
		tlas.accel.asInfo.type = VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_NV;

		tlas.accel.asInfo.instanceCount = count;
		tlas.accel.asInfo.flags = flags;

		probeMemorySizeAS(tlas.accel);

		allocateAS(tlas.accel.mem.origin, cache.memTypeOrgin, tlas.accel.mem.memory, std::vector<Tlas>{ tlas });
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

	VkAccelerationStructureNV  build() {


		std::vector<std::vector<VkGeometryNV>> geoms;


		std::map< uint64_t, int> cacheGeom;
		int geomNum = 0;


		int i = 0;
		for (auto& mesh : meshs) {

			std::vector<VkGeometryNV> geom;
		
			VkGeometryNV geometry{};
			geometry.sType = VK_STRUCTURE_TYPE_GEOMETRY_NV;
			geometry.geometryType = VK_GEOMETRY_TYPE_TRIANGLES_NV;
			geometry.geometry.triangles.sType = VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV;

			geometry.geometry.triangles.vertexCount  = mesh->verts.size()/ sizeof(ccl::float3);
			geometry.geometry.triangles.vertexStride = sizeof(ccl::float3);
			geometry.geometry.triangles.vertexFormat = VK_FORMAT_R32G32B32_SFLOAT;

			geometry.geometry.triangles.indexCount = mesh->triangles.size() / sizeof(int);
			geometry.geometry.triangles.indexType = VK_INDEX_TYPE_UINT32;
			geometry.geometry.triangles.transformData = VK_NULL_HANDLE;
			geometry.geometry.triangles.transformOffset = 0;
			geometry.geometry.aabbs = {};
			geometry.geometry.aabbs.sType = { VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV };
			geometry.flags = VK_GEOMETRY_OPAQUE_BIT_NV;

			geometry.geometry.triangles.vertexData = infoV[i].buffer;
			geometry.geometry.triangles.vertexOffset = infoV[i].offset;
			geometry.geometry.triangles.indexData = infoI[i].buffer;
			geometry.geometry.triangles.indexOffset = infoI[i].offset;


			geom.push_back(geometry);
			geoms.push_back(geom);

			i++;
		}


		std::vector<Blas> blas;

		buildBlas(blas, geoms);

		StoBache insta; insta.id = -1;

		std::vector<VkGeometryInstanceNV> geometryInstances(objs.size());
		float transform[12] = {
			 1.f,0.f,0.f,0.f,
			 0.f,1.f,0.f,0.f,
			 0.f,0.f,1.f,0.f,
		};
		i = 0;
		for (auto& obj : objs) {
			auto idx = obj->get_device_index();
			VkGeometryInstanceNV& gInst = geometryInstances[i];
			memcpy(gInst.transform, &transform[0], sizeof(gInst.transform));
			//memcpy(gInst.transform, &obj->tfm, sizeof(gInst.transform));
			gInst.instanceId = i;
			gInst.mask = 0xAA;
			gInst.hitGroupId = 0;
			gInst.flags = static_cast<uint32_t>(VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV);
			gInst.accelerationStructureHandle = blas[idx].accel.handle;
			i++;
		}

		ImmidiateBufferCmd<ImmidiateCmdPool> cmd;

		insta.id = -1;
		if (objVk == nullptr) {
			if (!$tank.takeout(objVk, 0)) {
				log_bad(" not found  ObjectVk.");
			};
		};
		objVk->$createBuffer$(cmd, insta, geometryInstances, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV);

		auto tlas = buildTlas(insta.vkBuffer, static_cast<uint32_t>(geometryInstances.size()));

		return  tlas.accel.astruct;
	};


	VkAccelerationStructureNV  build2() {


		std::vector<std::vector<VkGeometryNV>> geoms;


		std::map< uint64_t, int> cacheGeom;
		int geomNum = 0;


		int i = 0;
		for (auto& info : infoV) {

			std::vector<VkGeometryNV> geom;

			VkGeometryNV geometry{};
			geometry.sType = VK_STRUCTURE_TYPE_GEOMETRY_NV;
			geometry.geometryType = VK_GEOMETRY_TYPE_TRIANGLES_NV;
			geometry.geometry.triangles.sType = VK_STRUCTURE_TYPE_GEOMETRY_TRIANGLES_NV;

			geometry.geometry.triangles.vertexCount = (uint32_t)infoV[i].range / sizeof(ccl::float4);
			geometry.geometry.triangles.vertexStride =  sizeof(ccl::float4);
			geometry.geometry.triangles.vertexFormat = VK_FORMAT_R32G32B32_SFLOAT;

			geometry.geometry.triangles.indexCount = (uint32_t)infoI[i].range / sizeof(int);
			geometry.geometry.triangles.indexType = VK_INDEX_TYPE_UINT32;
			geometry.geometry.triangles.transformData = VK_NULL_HANDLE;
			geometry.geometry.triangles.transformOffset = 0;
			geometry.geometry.aabbs = {};
			geometry.geometry.aabbs.sType = { VK_STRUCTURE_TYPE_GEOMETRY_AABB_NV };
			geometry.flags = VK_GEOMETRY_NO_DUPLICATE_ANY_HIT_INVOCATION_BIT_KHR;// VK_GEOMETRY_OPAQUE_BIT_NV;

			geometry.geometry.triangles.vertexData = infoV[i].buffer;
			geometry.geometry.triangles.vertexOffset = infoV[i].offset;
			geometry.geometry.triangles.indexData = infoI[i].buffer;
			geometry.geometry.triangles.indexOffset = infoI[i].offset;


			geom.push_back(geometry);
			geoms.push_back(geom);

			i++;
		}


		std::vector<Blas> blas;

		buildBlas(blas, geoms);


		if (insta.vkBuffer != VK_NULL_HANDLE) {
			objVk->DeleteMB(insta.buffer);
			insta.vkBuffer = VK_NULL_HANDLE;
		}
		insta.id = -1;
#if TEST_NO == 7
		std::vector<VkAccelerationStructureInstanceNV> geometryInstances;

#ifdef DATA_JSON
		bl.setUpInstances_json(geometryInstances, blas);
#else
		bl.setUpInstances(geometryInstances,blas);
#endif
		
#else
		std::vector<VkGeometryInstanceNV> geometryInstances(geoms.size());// objs.size());
		float transform[12] = {
			 1.f,0.f,0.f,0.f,
			 0.f,1.f,0.f,0.f,
			 0.f,0.f,1.f,0.f,
		};
		
		for (int i = 0; i < geometryInstances.size();i++) {
			VkGeometryInstanceNV& gInst = geometryInstances[i];
			memcpy(gInst.transform, &transform[0], sizeof(gInst.transform));
			//memcpy(gInst.transform, &obj->tfm, sizeof(gInst.transform));
			gInst.instanceId = i;
			gInst.mask = 0xFF;
			gInst.hitGroupId = 0;
			gInst.flags = static_cast<uint32_t>(VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV);
			gInst.accelerationStructureHandle = blas[i].accel.handle;

		}
#endif

		ImmidiateBufferCmd<ImmidiateCmdPool> cmd;
		if (objVk == nullptr) {
			if (!$tank.takeout(objVk, 0)) {
				log_bad(" not found  ObjectVk.");
			};
		};

		objVk->$createBuffer$(cmd, insta, geometryInstances, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV);

		auto tlas = buildTlas(insta.vkBuffer, static_cast<uint32_t>(geometryInstances.size()));

		return  tlas.accel.astruct;
	};
private:

	/*
    void pack_blas();
    void pack_tlas();
    virtual void pack_nodes(const BVHNode*) override;
    virtual void refit_nodes() override;
    virtual BVHNode* widen_children_nodes(const BVHNode*) override;
	*/

};

CCL_NAMESPACE_END


#endif /* __BVH_OPTIX_H__ */
