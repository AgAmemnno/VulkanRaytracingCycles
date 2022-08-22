#pragma once
#ifndef  MATERIAL_VK_TYPES
#define  MATERIAL_VK_TYPES


#include "enum.hpp"
#include "types.hpp"
#include "util/log.hpp"
#include "aeolus/incomplete.h"
#include "working.h"
#include "materials/common.hpp"
//#include "aeolus/canvasVk/common.h"

#include <random>
#ifdef  LOG_MAT
#define log_mat(...)
#else
#define log_mat(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

#ifndef ROUND_UP
#define ROUND_UP(v, powerOf2Alignment) (((v) + (powerOf2Alignment)-1) & ~((powerOf2Alignment)-1))
#endif


struct  MaterialVk : public aeo::Material {	    
 	    Iache            iach;
};

struct __Blend {
	info::Blend_ADV                               blend;
	VkColorComponentFlags            component;
	float                             blendConstants[4];
};

static __Blend                   Blend0 = {
   .blend = {
	.advance = VK_BLEND_OP_SRC_OVER_EXT,//VK_BLEND_OP_SRC_IN_EXT,
	.overlap = VK_BLEND_OVERLAP_UNCORRELATED_EXT
	},
   .component = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT,
   .blendConstants = {1.f,1.f,1.f,1.f}
};

struct  Material2Vk : public BaseMaterial2Vk {


	Iache                        iach;

	SRWLOCK        slim;
	bool            scopedLock;

	eConfigu_PIPE      mode;

	struct PIPE {
		VkPipeline         pipe = VK_NULL_HANDLE;
	};

	struct PIPES {
		bool                                    active = false;
		PIPE                      Next[eConfigu_PIPE::ALL];
	};

	PIPES  pipeRoot[info::MAX_BLEND_OP][info::MAX_OVERLAP_OP];

	__Blend                           makeblend;

	struct Raster {
		VkPolygonMode     polygonMode;
		VkCullModeFlags   cullMode;
		VkFrontFace         frontFace;
		float                     lineWidth;
	};

	DescriptorVk* descVk;
	UniformVk            uniform;

	struct {
		VkDeviceSize    MaxSize;
		VkDeviceSize  alignment;
		long                     refCnt;
		VkDeviceSize          size;
	}cache;
	std::function<void(void)>                         updateCB;


	VkShaderModule                                          sh[2];
	PipelineStateCreateInfoVk                           PSci;

	void SetUp(Material2Vk::eConfigu_PIPE _mode) {
		mode = _mode;  ///FULLSCREEN2; ///
		init();
		arangeLayoutSet();
		createDraft();
	};
	void init();
	void initialState();
	void  loadPng(std::string name);
	long  Counting();
	long  Allocate();
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

	bool arangeLayoutSet();
	void writeout(VkDescriptorBufferInfo camera = VkDescriptorBufferInfo());

	template<typename T>
	void  writeout(T& desc) {

		std::vector<VkWriteDescriptorSet> write;
		write.clear();

		auto Set = uniform.descriptorSets[0];

		if ((mode == MODE_TONEMAPPING) | (mode == MODE_FULLSCREEN2)) {

			desc.Info.imageLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
			write.push_back({
			   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			   .dstSet = Set[0],
			   .dstBinding = 0,
			   .dstArrayElement = 0,
			   .descriptorCount = 1,
			   .descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			   .pImageInfo = &desc.Info
				});

		}
		else if (mode == MODE_TONEMAPPING2) {

			write.push_back({
			   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			   .dstSet = Set[0],
			   .dstBinding = 0,
			   .dstArrayElement = 0,
			   .descriptorCount = 1,
			   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			   .pBufferInfo = &desc.bInfo
				});
		}

		vkUpdateDescriptorSets($device, static_cast<uint32_t>(write.size()), write.data(), 0, nullptr);

	};

	void createDraft();
	std::vector<VkPipelineShaderStageCreateInfo>& setShaderState(eConfigu_PIPE   type);
	void  dealloc();
	void setCommonInformation(VkGraphicsPipelineCreateInfo& pipelineCreateInfo);

	bool get(VkPipeline*& pipeline, eConfigu_PIPE   prg, __Blend& blend = Blend0);
	bool bind(VkCommandBuffer cmd, eConfigu_PIPE type);

	bool createPipeline(PipelineConfigure& config);
	bool createPipeline(eConfigu_PIPE _type, PipelineConfigure& config, __Blend& blend = Blend0);
	bool $createExclusive(eConfigu_PIPE type, __Blend& blend,
		VkPrimitiveTopology topology,
		Raster& raster,
		VkGraphicsPipelineCreateInfo& pipelineCreateInfo
	);

	virtual bool make(VkCommandBuffer cmd, VkSemaphore sema) override;
	bool make_fullscreen(VkCommandBuffer cmd);
	bool make_tonemapping(VkCommandBuffer cmd);
	bool make(VkCommandBuffer cmd, const std::vector<Object3D*>& child, uint32_t drawCount);


};
#ifndef DEB

int  AddType_Materials(PyObject* m);

extern PyTypeObject tp_MaterialVk;
extern int AddType_MaterialVk(PyObject* m);
extern int AddType_Material2Vk(PyObject* m);
extern int AddType_MsdfMaterialVk(PyObject* m);
extern int AddType_GuiMaterialVk(PyObject* m);
///extern int AddType_MeshMaterialVk(PyObject* m);
extern int AddType_LodMaterialVk(PyObject* m);
extern int AddType_LodMaterial2Vk(PyObject* m);
extern int AddType_RTMaterialVk(PyObject* m);
extern int AddType_RTCMaterialVk(PyObject* m);
extern int AddType_GeomMaterialVk(PyObject* m);
extern int AddType_MeshMaterial2Vk(PyObject* m);
extern int AddType_MeshMaterialVk(PyObject* m);



struct RTMaterialVk :public RTMaterial {

public:
	Iache                 iach;
	SRWLOCK        slim;
	bool               scopedLock;
	size_t                                                    hash{ size_t(-1) };

	bool     ovrMode;

	eConfigu_PIPE               mode;
	DescriptorVk*            descVk;
	UniformVk                 uniform;



	VkDeviceSize _alignment;
	VkDeviceSize _structAlignment, _inindexAlignment;
	VkDeviceSize _maxStructChunk, _maxInIndexChunk;


	typedef  long InstaIndexTy;
	long InstaTypeNums = 1;




	ObjectsVk* objVk = nullptr;
	VisibleObjectsVk* vobjVk = nullptr;
	ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk;
	OVR* ovr = nullptr;


	std::vector<Object3D*>* child;

	StoBache sbt;

	struct AccelerationStructure {
		VkDeviceMemory memory;
		VkAccelerationStructureNV accelerationStructure;
		uint64_t handle;
	};
	struct GeometryInstance {
		float       transform[12];
		uint32_t instanceId : 24;
		uint32_t mask : 8;
		uint32_t instanceOffset : 24;
		uint32_t flags : 8;
		uint64_t accelerationStructureHandle;
	};

	/*
	PFN_vkCreateAccelerationStructureNV vkCreateAccelerationStructureNV;
	PFN_vkDestroyAccelerationStructureNV vkDestroyAccelerationStructureNV;
	PFN_vkBindAccelerationStructureMemoryNV vkBindAccelerationStructureMemoryNV;
	PFN_vkGetAccelerationStructureHandleNV vkGetAccelerationStructureHandleNV;
	PFN_vkGetAccelerationStructureMemoryRequirementsNV vkGetAccelerationStructureMemoryRequirementsNV;
	PFN_vkCmdBuildAccelerationStructureNV vkCmdBuildAccelerationStructureNV;
	PFN_vkCreateRayTracingPipelinesNV vkCreateRayTracingPipelinesNV;
	PFN_vkGetRayTracingShaderGroupHandlesNV vkGetRayTracingShaderGroupHandlesNV;
	PFN_vkCmdTraceRaysNV vkCmdTraceRaysNV;
	*/

	VkPhysicalDeviceRayTracingPropertiesNV rayTracingProperties{};

	AccelerationStructure bottomLevelAS;
	AccelerationStructure topLevelAS;

	VkPipeline pipeline;
	VkPipelineLayout pipelineLayout;
	VkDescriptorSet descriptorSet[2];
	VkDescriptorPool descriptorPool[2];

	VkDescriptorSet descU[2];
	VkDescriptorPool descP[2];
	VkDescriptorSetLayout descriptorSetLayout;
	VkDescriptorSetLayout descriptorSetLayoutU;

	uint32_t W, H;
	int  eyeId = 0;






	void init();

	template<class T>
	void buffer_process(std::vector<T>&& objs) {
		////



		RtObjectsVk robjVk(nullptr);
		///auto astruct =
		auto astruct = robjVk.createBTlas( std::move(objs));

		 ///createBuffer(obj);
		///auto astruct = topLevelAS.accelerationStructure;

		createRayTracingPipeline();
		createShaderBindingTable();
		createDescriptorSets(0,astruct);
		createDescriptorSets(1, astruct);


	};

	void createBottomLevelAccelerationStructure(const VkGeometryNV* geometries);
	void createTopLevelAccelerationStructure();

	void createBuffer(Object3D* obj);
	void createRayTracingPipeline();

	VkDeviceSize copyShaderIdentifier(uint8_t* data, const uint8_t* shaderHandleStorage, uint32_t groupIndex);
	void createShaderBindingTable();
	void createDescriptorSets(int i, const VkAccelerationStructureNV& astruct);
	void createDescriptorSets(int i, VkDescriptorBufferInfo&  camera, MIVSIvk& outImage);

	bool make(VkCommandBuffer cmd);
	virtual bool makeRT(VkCommandBuffer cmd) override;
	template<typename Im>
	bool make(VkCommandBuffer cmd, std::vector<Im>& images) {


		makeRT(cmd);

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = 1;


		VkImageMemoryBarrier imageMemoryBarrier = vka::plysm::imageMemoryBarrier();
		imageMemoryBarrier.oldLayout = VK_IMAGE_LAYOUT_GENERAL;
		imageMemoryBarrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		imageMemoryBarrier.image = images[0].image;
		imageMemoryBarrier.subresourceRange = subresourceRange;

		vkCmdPipelineBarrier(
			cmd,
			VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR| VK_ACCESS_SHADER_WRITE_BIT,
			VK_ACCESS_SHADER_READ_BIT,
			0,
			0, nullptr,
			0, nullptr,
			1, &imageMemoryBarrier);

		imageMemoryBarrier.image = images[1].image;
		vkCmdPipelineBarrier(
			cmd,
			VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR| VK_ACCESS_SHADER_WRITE_BIT,
			VK_ACCESS_SHADER_READ_BIT,
			0,
			0, nullptr,
			0, nullptr,
			1, &imageMemoryBarrier);



		return true;

	};


	RTMaterialVk(ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk):cmdVk(cmdVk) {
		    type = arth::eMATERIAL::RT;
	}

};




struct RTCMaterialVk :public RTMaterial {

public:
	Iache                 iach;
	SRWLOCK        slim;
	bool               scopedLock;
	size_t                                                    hash{ size_t(-1) };

	eConfigu_PIPE               mode;
	DescriptorVk*             descVk =nullptr;
	UniformVk                 uniform;

	struct {
		
		struct {
			StoBache  spheres;						// (Shader) storage buffer object with scene spheres
			StoBache  planes;						// (Shader) storage buffer object with scene planes
		} storageBuffers;
		UniformVk  uniformBuffer;					// Uniform buffer object containing scene data
		VkQueue queue;								// Separate queue for compute commands (queue family may differ from the one used for graphics)
		VkCommandPool commandPool;					// Use a separate command pool (queue family may differ from the one used for graphics)
		VkCommandBuffer commandBuffer;				// Command buffer storing the dispatch commands and barriers
		VkFence fence;								// Synchronization fence to avoid rewriting compute CB if still in use
		VkDescriptorSetLayout Layout[3];	// Compute shader binding layout
		VkDescriptorSet Set[2][3];				// Compute shader bindings
		VkPipelineLayout pipelineLayout;			// Layout of the compute pipeline
		VkPipeline pipeline;						// Compute raytracing pipeline
		
	} compute;


	struct Sphere {									// Shader uses std140 layout (so we only use vec4 instead of vec3)
		float pos[3];
		float radius;
		float  diffuse[3];
		float specular;
		int           id;								// Id used to identify sphere for raytracing
		int  _pad[3];
	};


	struct Plane {
		float normal[3];
		float distance;
		float diffuse[3];
		float specular;
		int          id;
		int  _pad[3];
	};



	VkDeviceSize _alignment;
	VkDeviceSize _structAlignment, _inindexAlignment;
	VkDeviceSize _maxStructChunk, _maxInIndexChunk;


	typedef  long InstaIndexTy;
	long InstaTypeNums = 1;




	ObjectsVk* objVk = nullptr;
	VisibleObjectsVk* vobjVk = nullptr;
	ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk;
	OVR* ovr = nullptr;


	std::vector<Object3D*>* child;

	StoBache sbt;



	VkPipeline pipeline;
	VkDescriptorPool descriptorPool;
	VkPipelineLayout pipelineLayout;

	struct Desc {
		VkDescriptorSet img,buffer;
	}desc;

	VkDescriptorSetLayout descriptorSetLayout;
	VkDescriptorSetLayout descriptorSetLayoutU;

	uint32_t W, H;
	int  eyeId = 0;
	void init();
	void dealloc();

	template<class T>
	void buffer_process(T* obj) {
		StorageBuffers();
		setupDescriptorSetLayout();
		writeDescriptorSet(0);
		writeDescriptorSet(1);
	};


	void StorageBuffers();

	void setupDescriptorSetLayout();

	void writeDescriptorSet(int i);
	template<typename T>
	void writeDescriptorSet(T& rt, VkDescriptorBufferInfo& uinfo, int i);

	bool make(VkCommandBuffer cmd);
	
	bool makeRT(VkCommandBuffer cmd) override;

};

#endif


struct RTShadowMaterialVk :public RTMaterial {

public:
	Iache                 iach;
	SRWLOCK        slim;
	bool               scopedLock;
	size_t                                                    hash{ size_t(-1) };


	eConfigu_PIPE               mode;
	DescriptorVk* descVk;
	UniformVk                 uniform;

	VkPipeline                       pipeline, bgpipeline, basepipeline;
	uint32_t W, H;



	VkPipelineCache  pipelineCache;
	VkDeviceSize _alignment, _structAlignment, _maxStructChunk;


	ObjectsVk* objVk = nullptr;
	VisibleObjectsVk* vobjVk = nullptr;
	ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk;
	OVR* ovr = nullptr;



	VkPhysicalDeviceRayTracingPropertiesNV rayTracingProperties{};

	RtObjectsVk* robjVk = nullptr;
	struct Vertex
	{
		float pos[3];
		float nrm[3];
		float color[3];
		float texCoord[2];
	};

	struct Camera
	{
		float  view[16];
		float  proj[16];
		float  viewInverse[16];
		float projInverse[16];
	};

	struct WaveFrontMaterial
	{
		float  ambient[3];
		float  diffuse[3];
		float  specular[3];
		float  transmittance[3];
		float  emission[3];
		float  shininess;
		float  ior;       // index of refraction
		float  dissolve;  // 1 == opaque; 0 == fully transparent
		int      illum;     // illumination model (see http://www.fileformat.info/format/material/)
		int      textureId;
	};

	struct sceneDesc
	{
		int     objId;
		int     txtOffset;
		float  transfo[16];
		float  transfoIT[16];
		int      hitGroup;
	};

	struct _Cahce {
		bool              allo;
		Mache                          mem;
		StoBacheArray      material;
		StoBache                   scene;
		StoBacheArray         matId;
		StoBacheArray        vertex;
		StoBacheArray          index;
		StoBache                      sbt;
		StoBache                      sbt2;
		uint32_t               objNums;
		uint32_t               geomNums;
	}setBuffer;

	struct RtPushConstant
	{
		float   clearColor[4];
		float   lightPosition[3];
		float         lightIntensity;
		int           lightType;
	} rtPushConstants;

	std::function<void(void)> buffer_pre;
	std::function<void(VkCommandBuffer)> buffer_barrierBG;
	bool  PUSH_POOL = false;
	int  TEX_NONUNI = 0;

	struct  bg_info {
		bool bg_pipeline;
		bool bg_make;
		uint32_t dim[3];
	}bgInfo = { false,false,{0,0,0} };

	UINT rt_type = 0;
	std::string PRG;
	VkShaderStageFlags  RAY_ALL = VkShaderStageFlags(
		VK_SHADER_STAGE_RAYGEN_BIT_KHR |
		VK_SHADER_STAGE_ANY_HIT_BIT_KHR |
		VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR |
		VK_SHADER_STAGE_MISS_BIT_KHR |
		VK_SHADER_STAGE_INTERSECTION_BIT_KHR |
		VK_SHADER_STAGE_CALLABLE_BIT_KHR);

	void init(int texDescType = 0, int bgDescType = 0) {

		InitializeSRWLock(&slim);
		TEX_NONUNI = texDescType;
		if (bgDescType > 0) {
			bgInfo.bg_pipeline = true;
		};
		/*
		if (texDescType != 0 || bgDescType != 0) {
			if (robjVk != nullptr) delete robjVk;
			robjVk = nullptr;
		};
		*/

		rayTracingProperties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV;
		VkPhysicalDeviceProperties2 deviceProps2{};
		deviceProps2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
		deviceProps2.pNext = &rayTracingProperties;
		vkGetPhysicalDeviceProperties2($physicaldevice, &deviceProps2);
		bgpipeline = VK_NULL_HANDLE;
		pipeline = VK_NULL_HANDLE;
		descVk = new DescriptorVk;

	};
	void deinit() {
		delete 	descVk;
		//setBuffer.mem.deal		StoBacheArray      material;
		if (setBuffer.vertex.buffer.id != -1) {
			objVk->DeleteIBm(setBuffer.vertex.buffer);
			objVk->DeleteIBm(setBuffer.index.buffer);
			objVk->DeleteIBm(setBuffer.sbt.buffer);
			objVk->DeleteIBm(setBuffer.sbt2.buffer);
			objVk->DeleteIBm(setBuffer.scene.buffer);
			objVk->DeleteIBm(setBuffer.matId.buffer);
			objVk->DeleteM(setBuffer.mem.mem);
		}
		destroyPipelineCache();
		vkDestroyPipeline($device, pipeline, nullptr);
		if (bgpipeline != VK_NULL_HANDLE)vkDestroyPipeline($device, bgpipeline, nullptr);
		if (robjVk != nullptr)delete robjVk;

	};

	template<typename T>
	void alignment(T _size = 0) {

		const VkDeviceSize                 maxChunk = 512 * 1024 * 1024;
		VkPhysicalDeviceLimits& limits = $properties.limits;
		VkDeviceSize structSize = (VkDeviceSize)_size;

		_alignment = limits.minStorageBufferOffsetAlignment;
		VkDeviceSize multiple = 1;

		while (true)
		{
			if (((multiple * structSize) % _alignment == 0))
			{
				break;
			}
			multiple++;
		};

		_structAlignment = multiple * structSize;


		VkDeviceSize tboSize = limits.maxStorageBufferRange;

		const VkDeviceSize structMax = VkDeviceSize(tboSize) * structSize;
		_maxStructChunk = __min(structMax, maxChunk);


	};

	template<class U>
	bool arangeLayoutSet(U* uni) {

		bool draft = (descVk->layoutSet.size() == 0);

		std::vector<VkDescriptorSetLayoutBinding > Set;

		uniform.swID = 0;
		Set.resize(2);
		Set[0] = {
		.binding = 0,
		.descriptorType = VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_NV,
		.descriptorCount = 1,
		.stageFlags = VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR | VK_SHADER_STAGE_RAYGEN_BIT_NV | VK_SHADER_STAGE_ANY_HIT_BIT_KHR ,
		.pImmutableSamplers = NULL
		};
		Set[1] = {
		.binding = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		.descriptorCount = 1,
		.stageFlags = VK_SHADER_STAGE_RAYGEN_BIT_NV ,
		.pImmutableSamplers = NULL
		};


		assert(0 == uniform.createSet(descVk, "Set0RTShadow", Set, draft));
		/*
		layout(binding = 0, set = 1) uniform
		layout(binding = 1, set = 1, scalar) buffer MatColorBufferObject { WaveFrontMaterial m[]; } materials[];
		layout(binding = 2, set = 1, scalar) buffer ScnDesc { sceneDesc i[]; } scnDesc;
		layout(binding = 3, set = 1) uniform sampler2D textureSamplers[];
		layout(binding = 4, set = 1)  buffer MatIndexColorBuffer { int i[]; } matIndex[];
		layout(binding = 5, set = 1, scalar) buffer Vertices { Vertex v[]; } vertices[];
		layout(binding = 6, set = 1) buffer Indices { uint i[]; } indices[];
		*/
		Set.clear();
		Set.push_back({
				.binding = 0,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
				.descriptorCount = 1,
				.stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_RAYGEN_BIT_NV ,
				.pImmutableSamplers = NULL
			});
		Set.push_back({
		.binding = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		.descriptorCount = setBuffer.objNums,
		.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT | VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR | VK_SHADER_STAGE_ANY_HIT_BIT_KHR ,
		.pImmutableSamplers = NULL
			});
		Set.push_back({
		.binding = 2,
		.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		.descriptorCount = 1,
		.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT | VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR | VK_SHADER_STAGE_ANY_HIT_BIT_KHR ,
		.pImmutableSamplers = NULL
			});
		/*
		Set[3] = {
		.binding = 3,
		.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
		.descriptorCount = 1,
		.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT | VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR ,
		.pImmutableSamplers = NULL
		};
		*/
		Set.push_back({
.binding = 3,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = setBuffer.objNums,
.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT | VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR | VK_SHADER_STAGE_ANY_HIT_BIT_KHR ,
.pImmutableSamplers = NULL
			});
		Set.push_back({
.binding = 4,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = setBuffer.geomNums,
.stageFlags = VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR | VK_SHADER_STAGE_ANY_HIT_BIT_KHR ,
.pImmutableSamplers = NULL
			});
		Set.push_back({
.binding = 5,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = setBuffer.geomNums,
.stageFlags = VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR | VK_SHADER_STAGE_ANY_HIT_BIT_KHR ,
.pImmutableSamplers = NULL
			});

		assert(1 == uniform.createSet(descVk, "Set1RTShadow", Set, draft));




		return true;

	};


	template<class U>
	bool arangeLayoutSet2(U* uni) {

		bool draft = (descVk->layoutSet.size() == 0);

		std::vector<VkDescriptorSetLayoutBinding > Set;

		uniform.swID = 0;
		Set.resize(2);
		Set[0] = {
		.binding = 0,
		.descriptorType = VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_NV,
		.descriptorCount = 1,
		.stageFlags = RAY_ALL ,
		.pImmutableSamplers = NULL
		};
		Set[1] = {
		.binding = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		.descriptorCount = 1,
		.stageFlags = RAY_ALL,
		.pImmutableSamplers = NULL
		};


		assert(0 == uniform.createSet(descVk, "Set0RTShadow", Set, draft));
		Set.clear();
		Set.push_back({
				.binding = 0,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
				.descriptorCount = 1,
				.stageFlags = RAY_ALL ,
				.pImmutableSamplers = NULL
			});

		assert(1 == uniform.createSet(descVk, "Set1RTShadow", Set, draft));


		return true;

	};

	bool  arangeLayoutSet_Kernel(int expect) {

		uniform.swID = 0;

		std::vector<VkDescriptorSetLayoutBinding > Set;
		Set.push_back({
.binding = 0,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = 1,
.stageFlags = RAY_ALL,
.pImmutableSamplers = NULL
			});
		Set.push_back({
.binding = 1,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = 1,
.stageFlags = RAY_ALL,
.pImmutableSamplers = NULL
			});

		Set.push_back({
.binding = 2,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = 1,
.stageFlags = RAY_ALL,
.pImmutableSamplers = NULL
			});


		assert(expect == (int)uniform.createSet(descVk, "rtset_kernel", Set, true));

		return true;

	}

	bool  arangeLayoutSet_Tex(int expect) {

		uniform.swID = 0;

		std::vector<VkDescriptorSetLayoutBinding > Set;
		if (TEX_NONUNI == 1) {
			Set.push_back({
				.binding = 0,
				.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
				.descriptorCount = 128,
				.stageFlags = RAY_ALL,
				.pImmutableSamplers = NULL
				});
		}
		if (TEX_NONUNI == 2) {
			Set.push_back({
	.binding = 0,
	.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE,
	.descriptorCount = 128,
	.stageFlags = RAY_ALL,
	.pImmutableSamplers = NULL
				});
			Set.push_back({
	.binding = 1,
	.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLER,
	.descriptorCount = 6,
	.stageFlags = RAY_ALL,
	.pImmutableSamplers = NULL
				});
		}

		assert(expect == (int)uniform.createSet(descVk, "rtset_tex", Set, true));

		return true;

	}


	bool  arangeLayoutSet_BG(int expect) {

		uniform.swID = 0;

		std::vector<VkDescriptorSetLayoutBinding > Set;
		Set.push_back({
.binding = 0,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = 1,
.stageFlags = VK_SHADER_STAGE_RAYGEN_BIT_KHR,
.pImmutableSamplers = NULL
			});
		Set.push_back({
.binding = 1,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = 1,
.stageFlags = VK_SHADER_STAGE_RAYGEN_BIT_KHR,
.pImmutableSamplers = NULL
			});
		assert(expect == (int)uniform.createSet(descVk, "rtset_bg", Set, true));

		return true;

	}
	bool  arangeLayoutSet_BG2(int expect) {

		uniform.swID = 0;

		std::vector<VkDescriptorSetLayoutBinding > Set;
		Set.push_back({
.binding = 0,
.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
.descriptorCount = 1,
.stageFlags = VK_SHADER_STAGE_RAYGEN_BIT_KHR,
.pImmutableSamplers = NULL
			});
		assert(expect == (int)uniform.createSet(descVk, "rtset_bg", Set, true));

		return true;

	}



#ifndef AEOLUS_DEBUG
	template<class T>
	void  writeDescsriptorSet_Kernel(int setNo, T& memVk) {

		struct _KernelGlobals {
			ccl::float3 f3[32 * 30];

		};


		constexpr size_t ALLOCATE_BUFFER_INFO = 1024;

		constexpr size_t kd_size = sizeof(ccl::KernelData);
		constexpr size_t kg_size = sizeof(_KernelGlobals);
		constexpr size_t allo_size = sizeof(uint32_t) * ALLOCATE_BUFFER_INFO;

		VkDescriptorBufferInfo kdinfo = {
			 .offset = 0,
			 .range = kd_size
		};

		VkDescriptorBufferInfo kginfo;
		static VkDescriptorBufferInfo alloinfo;

		auto usage = (VkBufferUsageFlagBits)(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT);

		size_t size = vkmm::AlignUp((size_t)kd_size, usage);

		kginfo.range = kg_size;
		kginfo.offset = size;
		size += vkmm::AlignUp((size_t)kg_size, usage);


		alloinfo.range = allo_size;
		alloinfo.offset = size;
		size += vkmm::AlignUp((size_t)allo_size, usage);



		const uint32_t alloc_block_max = 786;
		static uint32_t zeros[ALLOCATE_BUFFER_INFO];
		static int check_sum = 0;
		for (uint32_t i = 0; i < alloc_block_max; i++) {
			zeros[i] = i;
			check_sum += int(i);
		}
		zeros[alloc_block_max] = 0;
		zeros[alloc_block_max + 1] = alloc_block_max;
		for (uint32_t i = alloc_block_max + 2; i < ALLOCATE_BUFFER_INFO; i++) {
			zeros[i] = 0;
		}





		memVk.createBuffer("kerneldata", size,
			VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
			vkmm::MEMORY_USAGE_CPU_TO_GPU,
			[&]<class T2>(T2 & a) {
			if (a.alloc->GetMemoryTypeIndex() == 1)
			{
				printf("need to hostvisible .  \n");
				exit(-1);
			}
			else if ((a.alloc->GetMemoryTypeIndex() == 2) | (a.alloc->GetMemoryTypeIndex() == 4)) {
				kdinfo.buffer = a.buffer;
				kginfo.buffer = a.buffer;
				alloinfo.buffer = a.buffer;
			}
		}
		);

		buffer_pre = [&]() {
			static bool ini = true;
			void* dst = memVk.bamp["kerneldata"].alloc->GetMappedData();
			static int32_t deb[ALLOCATE_BUFFER_INFO];
			if (!ini) {
				memcpy(deb, (BYTE*)dst + alloinfo.offset, allo_size);
				int sum = 0;
				for (int i = 0; i < ALLOCATE_BUFFER_INFO; i++) {
					if (i < 786) {
						sum += deb[i];
					}
					printf(" atomic Counter [%d]   [%d]    val  %d     uval   %u  \n", 1023 - i, i, deb[i], UINT(deb[i]));
				}
				printf(" atomic Counter Sum   %d    ===     %d  \n", sum, check_sum);

			}
			memcpy((BYTE*)dst + alloinfo.offset, zeros, allo_size);
			ini = false;
		};


		std::vector<VkWriteDescriptorSet> write;
		write.clear();
		auto Set = uniform.descriptorSets[0];
		write.push_back({
		   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		   .dstSet = Set[setNo],
		   .dstBinding = 0,
		   .dstArrayElement = 0,
		   .descriptorCount = 1,
		   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		   .pBufferInfo = &kdinfo
			});
		write.push_back({
		   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		   .dstSet = Set[setNo],
		   .dstBinding = 1,
		   .dstArrayElement = 0,
		   .descriptorCount = 1,
		   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		   .pBufferInfo = &kginfo
			});
		write.push_back({
	   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
	   .dstSet = Set[setNo],
	   .dstBinding = 2,
	   .dstArrayElement = 0,
	   .descriptorCount = 1,
	   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
	   .pBufferInfo = &alloinfo
			});
		vkUpdateDescriptorSets($device, write.size(), write.data(), 0, NULL);

	}


	void  writeDescsriptorSet_BG(int setNo, uint32_t dim[3], std::vector<VkDescriptorBufferInfo>& infos) {

		std::vector<VkWriteDescriptorSet> write;
		write.clear();
		auto Set = uniform.descriptorSets[0];
		write.push_back({
		   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		   .dstSet = Set[setNo],
		   .dstBinding = 0,
		   .dstArrayElement = 0,
		   .descriptorCount = 1,
		   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		   .pBufferInfo = &infos[0]
			});
		write.push_back({
		   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		   .dstSet = Set[setNo],
		   .dstBinding = 1,
		   .dstArrayElement = 0,
		   .descriptorCount = 1,
		   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		   .pBufferInfo = &infos[1]
			});

		vkUpdateDescriptorSets($device, write.size(), write.data(), 0, NULL);
		static std::vector<VkDescriptorBufferInfo> binfos;
		binfos.clear();
		binfos.push_back(infos[1]);
		getInfo = [&]() {
			return binfos;
		};

		for (int i = 0; i < 3; i++)bgInfo.dim[i] = dim[i];

	}

#endif
	void  writeDescsriptorSet_BG2(int setNo, std::vector<VkDescriptorBufferInfo>& infos) {

		std::vector<VkWriteDescriptorSet> write;
		write.clear();
		auto Set = uniform.descriptorSets[0];
		uint32_t i = 0;
		for (auto inf : infos) {
			write.push_back({
			   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			   .dstSet = Set[setNo],
			   .dstBinding = i,
			   .dstArrayElement = 0,
			   .descriptorCount = 1,
			   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			   .pBufferInfo = &infos[i++]
				});
		}
		vkUpdateDescriptorSets($device, write.size(), write.data(), 0, NULL);
	}
	template<class T>
	void build_process(std::vector<T>&& objs) {

		rt_type = 0;
		PRG = "rt/shadow/";
		create_buffers(std::move(objs));

		auto astruct = robjVk->createBTlas(std::move(objs));

		createRayTracingPipeline4();

		writeOutDescriptorSets<0>(astruct);


		makeCB = std::bind(&RTShadowMaterialVk::makeRT, this, std::placeholders::_1);
	};


	template<class T>
	void build_process2(T& bvh) {
		rt_type = 1;
		PRG = "rt/bl2/";

		create_buffers2(bvh);
		auto astruct = bvh.build();

		createRayTracingPipeline2();

		writeOutDescriptorSets<0>(astruct);
		if (rt_type == 1) {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT3, this, std::placeholders::_1);
		}
		else {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT2, this, std::placeholders::_1);
		}
	};

	template<class T>
	void build_process3(T& bvh, bool pool = false) {
		rt_type = 1;
		PRG = "rt/bl3/";
		PUSH_POOL = pool;
		//create_buffers2(bvh);
		setBuffer.vertex.buffer.id = -1;
		auto astruct = bvh.build2();
		// 1 SamplerCombined   2 SeparateSampler

		createRayTracingPipeline3();

		writeOutDescriptorSets<0>(astruct);
		if (rt_type == 1) {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT3, this, std::placeholders::_1);
		}
		else {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT2, this, std::placeholders::_1);
		}
	};

	template<class T>
	void build_process4(T& bvh, bool pool = false) {
		rt_type = 1;
		PRG = "rt/bl3/";
		PUSH_POOL = pool;
		//create_buffers2(bvh);
		setBuffer.vertex.buffer.id = -1;
		auto astruct = bvh.build2();
		// 1 SamplerCombined   2 SeparateSampler

		createRayTracingPipeline3();

		writeOutDescriptorSets<0>(astruct);
		if (rt_type == 1) {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT3, this, std::placeholders::_1);
		}
		else {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT2, this, std::placeholders::_1);
		}
	};

	template<class T>
	void build_process5(T& bvh, bool pool = false) {
		rt_type = 1;
		PRG = "rt/bl3/";
		PUSH_POOL = pool;
		//create_buffers2(bvh);
		setBuffer.vertex.buffer.id = -1;
		auto astruct = bvh.build2();
		// 1 SamplerCombined   2 SeparateSampler

		createRayTracingPipeline5();

		writeOutDescriptorSets<0>(astruct);
		if (rt_type == 1) {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT3, this, std::placeholders::_1);
		}
		else {
			makeCB = std::bind(&RTShadowMaterialVk::makeRT2, this, std::placeholders::_1);
		}
	};

	void createPipelineCache()
	{
		VkPipelineCacheCreateInfo pipelineCacheCreateInfo = {};
		pipelineCacheCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
		VK_CHECK_RESULT(vkCreatePipelineCache($device, &pipelineCacheCreateInfo, nullptr, &pipelineCache));

	};
	void destroyPipelineCache()
	{
		vkDestroyPipelineCache($device, pipelineCache, nullptr);
	};
	template<class T>
	void build_process_test(T& bvh, bool pool = false) {

		rt_type = 1;
		PRG = "rt/bl3/";
		PUSH_POOL = pool;
		//create_buffers2(bvh);
		setBuffer.vertex.buffer.id = -1;
		createPipelineCache();
		createRayTracingPipeline_der();


	};


	template<class T>
	void rebuild_process(T& bvh) {

		if (setBuffer.vertex.vkBuffer != VK_NULL_HANDLE) {
			for (auto& obj : bvh.objs) {
				memset(obj, 0, sizeof(obj));
				//delete obj;
			}
			for (auto& mesh : bvh.meshs) {
				memset(mesh, 0, sizeof(mesh));
			}
			bvh.objs.clear();
			bvh.meshs.clear();
			bvh.infoV.clear();
			bvh.infoI.clear();

			objVk->DeleteIBm(setBuffer.vertex.buffer);
			objVk->DeleteIBm(setBuffer.index.buffer);
			objVk->DeleteIBm(setBuffer.sbt.buffer);
			objVk->DeleteIBm(setBuffer.scene.buffer);
			objVk->DeleteIBm(setBuffer.matId.buffer);
			objVk->DeleteM(setBuffer.mem.mem);
		}

		create_buffers2(bvh);
		auto astruct = bvh.build();
		writeOutDescriptorSets<0>(astruct);

	};

	template<class T>
	void rebuild_process2(T& bvh) {


		auto astruct = bvh.build2();
		writeOutDescriptorSets<0>(astruct);

	};

#ifndef AEOLUS_DEBUG
	template<class T>
	void create_buffers2(T& bvh) {

		bvh.rpack->read_mesh(bvh.meshs);
		bvh.rpack->read_object(bvh.objs);
		auto& meshs = bvh.meshs;
		auto& objs = bvh.objs;


		if (objVk == nullptr) {
			if (!$tank.takeout(objVk, 0)) {
				log_bad(" not found  VisibleUniformObjectsVk.");
			};
		};

		std::vector<std::vector<WaveFrontMaterial>> materials;
		std::vector<sceneDesc> scenes;
		std::vector<std::vector<int>>  matFaceIdxs;

		setBuffer.mem.sizeSet.clear();

#define STOBACHE_MAP(stbuf,ptr){ \
    			stbuf.id = -1;\
				objVk->$createDeviceBufferSeparate$(stbuf, Mem.memory, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT);\
				stbuf.info = {\
						 .buffer = stbuf.vkBuffer,\
						 .offset = 0,\
						 .range = stbuf.size\
				};\
				objVk->$BridgeMapBuffer$(*cmdVk, stbuf.info, (void*)(ptr));};
#define STOBACHE_INIT(stbuf) {\
		stbuf.size = 0;stbuf.infos.clear();\
		}
#define STOBACHE_INIT2(stbuf) {\
		stbuf.size = 0;\
		}
#define STOBACHE_ALIGN(stbuf){\
			stbuf.align =  DescUniform::alignmentSB(stbuf, stbuf.size);\
			setBuffer.mem.sizeSet.push_back(stbuf.align);}


		STOBACHE_INIT(setBuffer.material);
		STOBACHE_INIT2(setBuffer.scene);
		STOBACHE_INIT(setBuffer.matId);
		STOBACHE_INIT(setBuffer.vertex);
		STOBACHE_INIT(setBuffer.index);
		_structAlignment = 0;
		Matrix4 tmp;
		int objId = 0;
		std::random_device seed_gen;
		std::mt19937 engine(seed_gen());
		std::uniform_real_distribution<> dist1(0.0, 1.0);
		///std::normal_distribution<> dist2(0.0, 0.5);
		for (auto& obj : objs) {

			Matrix4 mat;
			mat.set(obj->tfm.x.x, obj->tfm.x.y, obj->tfm.x.z, obj->tfm.x.w,
				obj->tfm.y.x, obj->tfm.y.y, obj->tfm.y.z, obj->tfm.y.w,
				obj->tfm.z.x, obj->tfm.z.y, obj->tfm.z.z, obj->tfm.z.w,
				0, 0, 0, 1)->toDouble();
			tmp.getInverse(&mat, true)->transpose()->toFloat();

			sceneDesc scene;
			scene.objId = objId++;
			scene.txtOffset = 0;
			scene.hitGroup = 0;
			memcpy(&scene.transfo[0], &mat.f[0], 16 * sizeof(float));
			memcpy(&scene.transfoIT[0], &tmp.f[0], 16 * sizeof(float));
			scenes.push_back(scene);

			setBuffer.scene.size += sizeof(sceneDesc);


			std::vector<WaveFrontMaterial>  WFmat = { {
						.ambient = {0.1,0.1,0.1} ,
						.diffuse = { (float)dist1(engine),(float)dist1(engine),(float)dist1(engine)},
						.specular = {0.2,0.4,0.2},
						.transmittance = {0.,0.,0.},
						.emission = {0.,0.,0.},
						.shininess = 3.f * (float)dist1(engine),
						.ior = 1.45,       // index of refraction
						.dissolve = 1.f,  // 1 == opaque; 0 == fully transparent
						.illum = 1,     // illumination model (see http://www.fileformat.info/format/material/)
						.textureId = 0
			} };

			materials.push_back(WFmat);
			DescUniform::appendAlignScalar(setBuffer.material, sizeof(WaveFrontMaterial), objId);

			auto gid = obj->get_device_index();
			auto mesh = meshs[gid];
			if (_structAlignment == 0) alignment(sizeof(ccl::float3));


			DescUniform::appendAlignScalar(setBuffer.vertex, mesh->verts.size(), objId);
			DescUniform::appendAlignScalar(setBuffer.index, mesh->triangles.size(), objId);


			std::vector<int> matFaceIdx;
			matFaceIdx.resize(mesh->triangles.size() / 3 / sizeof(INT));
			for (auto& v : matFaceIdx)v = 0;// scene.objId;

			matFaceIdxs.push_back(matFaceIdx);
			DescUniform::appendAlignScalar(setBuffer.matId, matFaceIdx.size() * sizeof(int), objId);

		}


		setBuffer.objNums = uint32_t(objs.size());

		{
			STOBACHE_ALIGN(setBuffer.material);
			STOBACHE_ALIGN(setBuffer.scene);
			STOBACHE_ALIGN(setBuffer.matId);
			STOBACHE_ALIGN(setBuffer.vertex);
			STOBACHE_ALIGN(setBuffer.index);

			setBuffer.mem.id = -1;

			objVk->$AllocMemory$(cmdVk, setBuffer.mem);
			setBuffer.material.offset = setBuffer.mem.sizeSet[0];
			setBuffer.scene.offset = setBuffer.mem.sizeSet[1];
			setBuffer.matId.offset = setBuffer.mem.sizeSet[2];
			setBuffer.vertex.offset = setBuffer.mem.sizeSet[3];
			setBuffer.index.offset = setBuffer.mem.sizeSet[4];

			Mvk Mem;
			objVk->getMemory(Mem, setBuffer.mem.mem);


			{
				char* buf = new char[setBuffer.material.size];
				char* ptr = buf;
				size_t itemSize = sizeof(WaveFrontMaterial);
				for (int i = 0; i < setBuffer.objNums; i++) {
					auto v = materials[i];
					auto info = setBuffer.material.infos[i];
					memcpy(ptr, &v[0], itemSize);
					ptr += info.range;
				};
				STOBACHE_MAP(setBuffer.material, buf);
				delete[]  buf;
				DescUniform::setAlignScalar(setBuffer.material);
			}
			{
				char* buf = new char[setBuffer.scene.size];
				char* ptr = buf;
				size_t itemSize = sizeof(sceneDesc);
				for (auto v : scenes) {
					memcpy(ptr, &(v.objId), itemSize);
					ptr += itemSize;
				};
				STOBACHE_MAP(setBuffer.scene, buf);
				delete[]  buf;
			}
			{
				char* buf = new char[setBuffer.matId.size];
				char* ptr = buf;
				for (int i = 0; i < setBuffer.objNums; i++) {
					auto v = matFaceIdxs[i];
					auto info = setBuffer.matId.infos[i];
					size_t itemSize = sizeof(int) * v.size();
					memcpy(ptr, v.data(), itemSize);
					ptr += info.range;
				};
				STOBACHE_MAP(setBuffer.matId, buf);
				delete[]  buf;
				DescUniform::setAlignScalar(setBuffer.matId);
			}
			{

				char* buf = new char[setBuffer.vertex.size];
				char* buf2 = new char[setBuffer.index.size];
				char* ptr = buf;
				char* ptr2 = buf2;

				for (int i = 0; i < setBuffer.objNums; i++) {

					auto& desc = meshs[i];
					auto info = setBuffer.vertex.infos[i];
					size_t itemSize = desc->verts.size();;
					memcpy(ptr, desc->verts.data(), itemSize);
					ptr += info.range;

					auto info2 = setBuffer.index.infos[i];
					size_t itemSize2 = desc->triangles.size();
					memcpy(ptr2, desc->triangles.data(), itemSize2);
					ptr2 += info2.range;

				};


				STOBACHE_MAP(setBuffer.vertex, buf);
				STOBACHE_MAP(setBuffer.index, buf2);
				delete[] buf;
				delete[] buf2;
				DescUniform::setAlignScalar(setBuffer.vertex);
				DescUniform::setAlignScalar(setBuffer.index);

			}




		}


		bvh.infoV = setBuffer.vertex.infos;
		bvh.infoI = setBuffer.index.infos;

#undef STOBACHE_ALIGN
#undef STOBACHE_MAP
#undef STOBACHE_INIT
		return;

	}
#endif

	int geomN = 0;
	template<class T>
	void create_buffers(std::vector<T>&& objs) {

#define STOBACHE_MAP(stbuf,ptr){ \
    			stbuf.id = -1;\
				objVk->$createDeviceBufferSeparate$(stbuf, Mem.memory, VK_BUFFER_USAGE_STORAGE_BUFFER_BIT);\
				stbuf.info = {\
						 .buffer = stbuf.vkBuffer,\
						 .offset = 0,\
						 .range = stbuf.size\
				};\
				objVk->$BridgeMapBuffer$(*cmdVk, stbuf.info, (void*)(ptr));};
#define STOBACHE_INIT(stbuf)  stbuf.size = 0;
#define STOBACHE_ALIGN(stbuf){\
			stbuf.align =  DescUniform::alignmentSB(stbuf, stbuf.size);\
			setBuffer.mem.sizeSet.push_back(stbuf.align);}

		if (objVk == nullptr) {
			if (!$tank.takeout(objVk, 0)) {
				log_bad(" not found  VisibleUniformObjectsVk.");
			};
		};

		setBuffer.geomNums = geomN;
		std::vector<_BufferAttribute*> vertexies(geomN);

		std::map< uint64_t, int> cacheGeom;
		int geomNum = 0;
		for (auto& obj : objs) {
			if (cacheGeom.count(uint64_t(obj->geometry->attributes)) == 0) {
				cacheGeom[uint64_t(obj->geometry->attributes)]++;
				_BufferAttribute& desc = *obj->geometry->attributes->buffer;
				vertexies[obj->draw.gid] = obj->geometry->attributes->buffer;
				geomNum++;
				if (geomNum == geomN)break;
			}
		}

		STOBACHE_INIT(setBuffer.vertex);
		STOBACHE_INIT(setBuffer.index);

		for (auto& _desc : vertexies) {
			_BufferAttribute& desc = *_desc;
			if (_structAlignment == 0) alignment(desc.array.structSize);
			DescUniform::appendAlignScalar(setBuffer.vertex, desc.array.arraySize * desc.array.structSize);
			DescUniform::appendAlignScalar(setBuffer.index, desc.index.size() * sizeof(UINT32));
		}

		std::vector<std::vector<WaveFrontMaterial>> materials;
		std::vector<sceneDesc> scenes;
		std::vector<std::vector<int>>  matFaceIdxs;






		STOBACHE_INIT(setBuffer.material);
		STOBACHE_INIT(setBuffer.scene);
		STOBACHE_INIT(setBuffer.matId);

		_structAlignment = 0;
		Matrix4 tmp;
		int objId = 0;
		std::random_device seed_gen;
		std::mt19937 engine(seed_gen());
		std::uniform_real_distribution<> dist1(0.0, 1.0);
		///std::normal_distribution<> dist2(0.0, 0.5);
		for (auto& obj : objs) {

			obj->updateMatrix();
			obj->matrix->toFloat();
			tmp.getInverse(obj->matrix, true)->transpose()->toFloat();

			sceneDesc scene;
			scene.objId = objId++;
			scene.txtOffset = obj->draw.gid;
			scene.hitGroup = obj->draw.pid;


			memcpy(&scene.transfo[0], &obj->matrix->f[0], 16 * sizeof(float));
			memcpy(&scene.transfoIT[0], &tmp.f[0], 16 * sizeof(float));
			scenes.push_back(scene);

			setBuffer.scene.size += sizeof(sceneDesc);




			std::vector<WaveFrontMaterial>  WFmat = { {
						.ambient = {0.1,0.1,0.1} ,
						.diffuse = { (float)dist1(engine),(float)dist1(engine),(float)dist1(engine)},
						.specular = {0.2,0.4,0.2},
						.transmittance = {0.,0.,0.},
						.emission = {0.,0.,0.},
						.shininess = 3.f * (float)dist1(engine),
						.ior = 1.45,       // index of refraction
						.dissolve = 1.f,  // 1 == opaque; 0 == fully transparent
						.illum = 1,     // illumination model (see http://www.fileformat.info/format/material/)
						.textureId = 0
			} };

			materials.push_back(WFmat);
			DescUniform::appendAlignScalar(setBuffer.material, sizeof(WaveFrontMaterial), objId);


			_BufferAttribute& desc = *obj->geometry->attributes->buffer;
			std::vector<int> matFaceIdx;
			matFaceIdx.resize(desc.index.size() / 3);
			for (auto& v : matFaceIdx)v = 0;// scene.objId;

			matFaceIdxs.push_back(matFaceIdx);
			DescUniform::appendAlignScalar(setBuffer.matId, matFaceIdx.size() * sizeof(int), objId);

		}


		setBuffer.objNums = uint32_t(objs.size());

		{
			STOBACHE_ALIGN(setBuffer.material);
			STOBACHE_ALIGN(setBuffer.scene);
			STOBACHE_ALIGN(setBuffer.matId);
			STOBACHE_ALIGN(setBuffer.vertex);
			STOBACHE_ALIGN(setBuffer.index);

			setBuffer.mem.id = -1;
			objVk->$AllocMemory$(cmdVk, setBuffer.mem);
			setBuffer.material.offset = setBuffer.mem.sizeSet[0];
			setBuffer.scene.offset = setBuffer.mem.sizeSet[1];
			setBuffer.matId.offset = setBuffer.mem.sizeSet[2];
			setBuffer.vertex.offset = setBuffer.mem.sizeSet[3];
			setBuffer.index.offset = setBuffer.mem.sizeSet[4];

			Mvk Mem;
			objVk->getMemory(Mem, setBuffer.mem.mem);


			{
				char* buf = new char[setBuffer.material.size];
				char* ptr = buf;
				size_t itemSize = sizeof(WaveFrontMaterial);
				for (int i = 0; i < setBuffer.objNums; i++) {
					auto v = materials[i];
					auto info = setBuffer.material.infos[i];
					memcpy(ptr, &v[0], itemSize);
					ptr += info.range;
				};
				STOBACHE_MAP(setBuffer.material, buf);
				delete[]  buf;
				DescUniform::setAlignScalar(setBuffer.material);
			}
			{
				char* buf = new char[setBuffer.scene.size];
				char* ptr = buf;
				size_t itemSize = sizeof(sceneDesc);
				for (auto v : scenes) {
					memcpy(ptr, &(v.objId), itemSize);
					ptr += itemSize;
				};
				STOBACHE_MAP(setBuffer.scene, buf);
				delete[]  buf;
			}
			{
				char* buf = new char[setBuffer.matId.size];
				char* ptr = buf;
				for (int i = 0; i < setBuffer.objNums; i++) {
					auto v = matFaceIdxs[i];
					auto info = setBuffer.matId.infos[i];
					size_t itemSize = sizeof(int) * v.size();
					memcpy(ptr, v.data(), itemSize);
					ptr += info.range;
				};
				STOBACHE_MAP(setBuffer.matId, buf);
				delete[]  buf;
				DescUniform::setAlignScalar(setBuffer.matId);
			}
			{

				char* buf = new char[setBuffer.vertex.size];
				char* buf2 = new char[setBuffer.index.size];
				char* ptr = buf;
				char* ptr2 = buf2;

				for (int i = 0; i < int(vertexies.size()); i++) {

					auto desc = vertexies[i];
					auto info = setBuffer.vertex.infos[i];
					size_t itemSize = desc->array.arraySize * desc->array.structSize;
					memcpy(ptr, desc->array.data, itemSize);
					ptr += info.range;

					auto info2 = setBuffer.index.infos[i];
					size_t itemSize2 = desc->index.size() * sizeof(UINT32);
					memcpy(ptr2, desc->index.data(), itemSize2);
					ptr2 += info2.range;

				};


				STOBACHE_MAP(setBuffer.vertex, buf);
				STOBACHE_MAP(setBuffer.index, buf2);
				delete[] buf;
				delete[] buf2;
				DescUniform::setAlignScalar(setBuffer.vertex);
				DescUniform::setAlignScalar(setBuffer.index);

			}




		}


#undef STOBACHE_ALIGN
#undef STOBACHE_MAP
#undef STOBACHE_INIT
		return;

	}

	template<size_t i>
	void writeOutDescriptorSets(const VkAccelerationStructureNV& astruct) {


		VkWriteDescriptorSetAccelerationStructureNV descriptorAccelerationStructureInfo{};
		descriptorAccelerationStructureInfo.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_NV;
		descriptorAccelerationStructureInfo.accelerationStructureCount = 1;
		descriptorAccelerationStructureInfo.pAccelerationStructures = &astruct;

		VkWriteDescriptorSet accelerationStructureWrite{};
		accelerationStructureWrite.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
		accelerationStructureWrite.pNext = &descriptorAccelerationStructureInfo;
		accelerationStructureWrite.dstSet = uniform.descriptorSets[0][0];
		accelerationStructureWrite.dstBinding = 0;
		accelerationStructureWrite.descriptorCount = 1;
		accelerationStructureWrite.descriptorType = VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_NV;


		std::vector<VkWriteDescriptorSet> writeDescriptorSets = {
		accelerationStructureWrite,
		};
		vkUpdateDescriptorSets($device, static_cast<uint32_t>(writeDescriptorSets.size()), writeDescriptorSets.data(), 0, VK_NULL_HANDLE);
	};

	template<size_t i, class T>
	void writeOutDescriptorSets(VkDescriptorBufferInfo& camera, T& outImage) {

		static std::vector<VkWriteDescriptorSet> write;

		write.clear();

		auto Set = uniform.descriptorSets[i];

		W = outImage.w, H = outImage.h;
		outImage.Info.imageLayout = VK_IMAGE_LAYOUT_GENERAL;
		write.push_back({
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = Set[0],
		.dstBinding = 1,
		.dstArrayElement = 0,
		.descriptorCount = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		.pImageInfo = &outImage.Info
			});
		write.push_back({
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = Set[1],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
				.pBufferInfo = &camera
			});

		if (rt_type == 0) {
			write.push_back({
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = Set[1],
					.dstBinding = 1,
					.dstArrayElement = 0,
					.descriptorCount = setBuffer.objNums,
					.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER ,
					.pBufferInfo = setBuffer.material.infos.data()
				});
			write.push_back({
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = Set[1],
			.dstBinding = 2,
			.dstArrayElement = 0,
			.descriptorCount = 1,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER ,
			.pBufferInfo = &setBuffer.scene.info
				});
			write.push_back({
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = Set[1],
			.dstBinding = 3,
			.dstArrayElement = 0,
			.descriptorCount = setBuffer.objNums,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER ,
			.pBufferInfo = setBuffer.matId.infos.data()
				});
			write.push_back({
	.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
	.dstSet = Set[1],
	.dstBinding = 4,
	.dstArrayElement = 0,
	.descriptorCount = uint32_t(setBuffer.vertex.infos.size()),
	.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER ,
	.pBufferInfo = setBuffer.vertex.infos.data()
				});
			write.push_back({
	.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
	.dstSet = Set[1],
	.dstBinding = 5,
	.dstArrayElement = 0,
	.descriptorCount = uint32_t(setBuffer.index.infos.size()),
	.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER ,
	.pBufferInfo = setBuffer.index.infos.data()
				});

		}
		vkUpdateDescriptorSets($device, static_cast<uint32_t>(write.size()), write.data(), 0, nullptr);


	};

	template<typename T>
	void writeOutDescriptorSets(std::vector<T>& iinfo, uint32_t  i) {

		static std::vector<VkWriteDescriptorSet> write;

		write.clear();

		auto Set = uniform.descriptorSets[0];
		enum  eTEX_BIND {
			SAMPLER2D,
			TEXTURE2D,
			All
		};

		write.push_back({
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = Set[i],
					.dstBinding = SAMPLER2D,
					.dstArrayElement = 0,
					.descriptorCount = (uint32_t)iinfo.size(),
					.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER ,
					.pImageInfo = iinfo.data()
			});
	};

	template<typename T, typename T2>
	void writeOutDescriptorSets(std::vector<T>& iinfo, std::vector<T2>& sdesc, uint32_t  i) {

		static std::vector<VkWriteDescriptorSet> write;

		write.clear();

		auto Set = uniform.descriptorSets[0];
		enum  eTEX_BIND {
			TEXTURE2D,
			SAMPLER,
			All
		};

		write.push_back({
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = Set[i],
			.dstBinding = TEXTURE2D,
			.dstArrayElement = 0,
			.descriptorCount = (uint32_t)iinfo.size(),
			.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE ,
			.pImageInfo = iinfo.data()
			});
		std::vector<VkDescriptorImageInfo> sinfo;
		for (auto& desc : sdesc) {
			sinfo.push_back(desc.Info);
		};
		assert(sinfo.size() == 6);
		write.push_back({
			.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			.dstSet = Set[i],
			.dstBinding = SAMPLER,
			.dstArrayElement = 0,
			.descriptorCount = (uint32_t)sinfo.size(),
			.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLER ,
			.pImageInfo = sinfo.data()
			});

		vkUpdateDescriptorSets($device, static_cast<uint32_t>(write.size()), write.data(), 0, nullptr);


	};


	void createDraft() {
		VkPushConstantRange pushConstantRange;
		if (rt_type == 1) {
			arangeLayoutSet2(&uniform);
			arangeLayoutSet_Kernel(2);
			if (TEX_NONUNI > 0) arangeLayoutSet_Tex(3);
			if (bgInfo.bg_pipeline) arangeLayoutSet_BG2(4);


			pushConstantRange = {
				.stageFlags = VK_SHADER_STAGE_ALL,
				.offset = 0 };

			if (PUSH_POOL)
				pushConstantRange.size = 16;
			else
				pushConstantRange.size = 8;

		}
		else {
			arangeLayoutSet(&uniform);
			pushConstantRange = {
				.stageFlags = VK_SHADER_STAGE_RAYGEN_BIT_KHR |
				VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR |
				VK_SHADER_STAGE_MISS_BIT_KHR,
				.offset = 0,
				.size = sizeof(RtPushConstant),
			};
		}

		descVk->createDraft({ pushConstantRange });


	};

	void createRayTracingPipeline()
	{

		createDraft();

		enum  rtGroup {
			Raygen,
			Miss,
			Miss2,
			ClosestHit,
			ClosestHit2,

			ALL
		};

		std::array<VkPipelineShaderStageCreateInfo, ALL> shaderStages;


		shaderStages[Raygen] = PipelineVk::loadShader(getAssetPath() + PRG + "prg.rgen.spv", VK_SHADER_STAGE_RAYGEN_BIT_NV);
		shaderStages[Miss] = PipelineVk::loadShader(getAssetPath() + PRG + "prg.rmiss.spv", VK_SHADER_STAGE_MISS_BIT_NV);
		shaderStages[Miss2] = PipelineVk::loadShader(getAssetPath() + PRG + "shadow.rmiss.spv", VK_SHADER_STAGE_MISS_BIT_NV);
		shaderStages[ClosestHit] = PipelineVk::loadShader(getAssetPath() + PRG + "hit1.rchit.spv", VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV);
		shaderStages[ClosestHit2] = PipelineVk::loadShader(getAssetPath() + PRG + "hit2.rchit.spv", VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV);



		std::array<VkRayTracingShaderGroupCreateInfoNV, ALL> groups{};
		for (auto& group : groups) {

			group.sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV;
			group.generalShader = VK_SHADER_UNUSED_NV;
			group.closestHitShader = VK_SHADER_UNUSED_NV;
			group.anyHitShader = VK_SHADER_UNUSED_NV;
			group.intersectionShader = VK_SHADER_UNUSED_NV;

		}


		groups[Raygen].type = VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV;
		groups[Raygen].generalShader = Raygen;
		groups[Miss].type = VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV;
		groups[Miss].generalShader = Miss;
		groups[Miss2].type = VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV;
		groups[Miss2].generalShader = Miss2;
		groups[ClosestHit].type = VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV;
		groups[ClosestHit].generalShader = VK_SHADER_UNUSED_NV;
		groups[ClosestHit].closestHitShader = ClosestHit;
		groups[ClosestHit2].type = VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV;
		groups[ClosestHit2].generalShader = VK_SHADER_UNUSED_NV;
		groups[ClosestHit2].closestHitShader = ClosestHit2;


		VkRayTracingPipelineCreateInfoNV rayPipelineInfo{};
		rayPipelineInfo.sType = VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV;
		rayPipelineInfo.stageCount = static_cast<uint32_t>(shaderStages.size());
		rayPipelineInfo.pStages = shaderStages.data();
		rayPipelineInfo.groupCount = static_cast<uint32_t>(groups.size());
		rayPipelineInfo.pGroups = groups.data();
		rayPipelineInfo.maxRecursionDepth = 2;
		rayPipelineInfo.layout = descVk->draft;
		VK_CHECK_RESULT(vkCreateRayTracingPipelinesNV($device, VK_NULL_HANDLE, 1, &rayPipelineInfo, nullptr, &pipeline));

		for (auto& s : shaderStages)
			vkDestroyShaderModule($device, s.module, nullptr);




		float HitRecordBuffer[4] = { 0.1f,0.0f,0.1f,1.f };

		uint32_t rayGenSize = rayTracingProperties.shaderGroupBaseAlignment;
		uint32_t missSize = rayTracingProperties.shaderGroupBaseAlignment;

		uint32_t hitSize =
			ROUND_UP(rayTracingProperties.shaderGroupHandleSize + static_cast<int>(sizeof(HitRecordBuffer)), rayTracingProperties.shaderGroupBaseAlignment);


		if (vobjVk == nullptr) {
			if (!$tank.takeout(vobjVk, 0)) {
				log_bad(" not found  VisibleObjectVk.");
			};
		};

		setBuffer.sbt.size = rayGenSize + 2 * missSize + 3 * hitSize;
		setBuffer.sbt.buffer.id = -1;
		vobjVk->$createBuffer$(setBuffer.sbt, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

		size_t handlesSize = rayTracingProperties.shaderGroupBaseAlignment * ALL;
		auto shaderHandleStorage = new uint8_t[handlesSize];
		VK_CHECK_RESULT(vkGetRayTracingShaderGroupHandlesNV($device, pipeline, 0, ALL, handlesSize, shaderHandleStorage));
		auto* data = static_cast<uint8_t*>(setBuffer.sbt.mapped);

		const uint32_t shaderGroupHandleSize = rayTracingProperties.shaderGroupBaseAlignment;// ;
		memcpy(data, shaderHandleStorage + Raygen * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;


		memcpy(data, shaderHandleStorage + Miss * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;

		memcpy(data, shaderHandleStorage + Miss2 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;


		memcpy(data, shaderHandleStorage + ClosestHit * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += hitSize;


		memcpy(data, shaderHandleStorage + ClosestHit2 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		memcpy(data + rayTracingProperties.shaderGroupHandleSize, &HitRecordBuffer[0], sizeof(HitRecordBuffer));  // Hit 1 data
		data += hitSize;

		float HitRecordBuffer2[4] = { 1.f, 1.f,0.2f ,1.f };
		memcpy(data, shaderHandleStorage + ClosestHit2 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		memcpy(data + rayTracingProperties.shaderGroupHandleSize, &HitRecordBuffer2[0], sizeof(HitRecordBuffer2));  // Hit 2 data




		delete[] shaderHandleStorage;

		GetCTX($ctx)
			$ctx->deb.setObjectName(setBuffer.sbt.vkBuffer, "SBT_CHIT");

		//robjVk.createShaderBindingTable(setBuffer.sbt, pipeline, (uint32_t)ALL);

	}

	void createRayTracingPipeline2() {


		createDraft();

		typedef float HitRecordBuffer[4];


		std::vector<HitRecordBuffer> hit2(2);
		hit2[0][0] = 0.5f, hit2[0][1] = 0.0f, hit2[0][2] = 0.1f, hit2[0][3] = 1.f;
		hit2[1][0] = 0.1f, hit2[1][1] = 0.5f, hit2[1][2] = 0.1f, hit2[1][3] = 1.f;

		const uint32_t SPV_TYPES = 4;
		auto align_sbt = [&]<typename T>(T t) { return ROUND_UP(rayTracingProperties.shaderGroupHandleSize + static_cast<int>(sizeof(T)), rayTracingProperties.shaderGroupBaseAlignment); };
		union rtGroup {
			struct {
				uint32_t rgen, rmiss, rchit, rcall;
			};
			struct {
				uint32_t i[SPV_TYPES];
			};
			uint32_t size() { return  rgen + rmiss + rchit + rcall; }
			constexpr uint32_t nums() { return SPV_TYPES; }

		}spv = { 2,2,2,24 }, align = {
					rayTracingProperties.shaderGroupBaseAlignment,
					rayTracingProperties.shaderGroupBaseAlignment,
					align_sbt(hit2[0]),
					rayTracingProperties.shaderGroupBaseAlignment
		};

		struct sbtData {
			void* data = nullptr;
			uint32_t data_size;
			uint32_t array_size;
			sbtData() :array_size(0), data_size(0), data(nullptr) {};
			sbtData(uint32_t asize, uint32_t dsize = 0, void* data = nullptr) :array_size(asize), data_size(dsize), data(data) {};
		};


		std::vector<std::vector<sbtData>> inst(spv.nums());
		//int i = 0;
		//for (auto& in: inst) in.resize(spv.i[i++]);
		inst = {
			{ {1},{1}},
			{ {1},{1}},
			{ {1},{2, sizeof(HitRecordBuffer) , hit2.data() } },
			{
				{1},{1} ,{1},{1},{1} ,{1},
					{1},{1} ,{1},{1},{1} ,{1},
						{1},{1} ,{1},{1},{1} ,{1},
				{1},{1} ,{1},{1},{1} ,{1}
				}
		};



		const std::tuple<VkShaderStageFlagBits, VkRayTracingShaderGroupTypeNV, std::string> flags[spv.nums()]
			= {
			   {VK_SHADER_STAGE_RAYGEN_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rgen"},
				{VK_SHADER_STAGE_MISS_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rmiss"},
				{VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV,"rchit"},
				{VK_SHADER_STAGE_CALLABLE_BIT_KHR,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rcall"}
		};

		std::vector<VkPipelineShaderStageCreateInfo> shaderStages(spv.size());
		std::vector<VkRayTracingShaderGroupCreateInfoNV> groups(spv.size());
		for (auto& group : groups) {
			group.sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV;
			group.generalShader = VK_SHADER_UNUSED_NV;
			group.closestHitShader = VK_SHADER_UNUSED_NV;
			group.anyHitShader = VK_SHADER_UNUSED_NV;
			group.intersectionShader = VK_SHADER_UNUSED_NV;
		}



#define ShaderName(stage,n) getAssetPath() + PRG + "prg" + std::to_string(n) + "." + stage  + ".spv"
		uint32_t  cur = 0;
		uint32_t  gid = 0;
		uint32_t   idx = 0;
		for (auto& s : shaderStages) {
			if (cur < spv.i[gid]) {
				groups[idx].type = std::get<1>(flags[gid]);
				if (gid == 2) groups[idx].closestHitShader = idx;
				else groups[idx].generalShader = idx;
				shaderStages[idx++] = PipelineVk::loadShader(ShaderName(std::get<2>(flags[gid]), cur), std::get<0>(flags[gid]));
				cur++;
			}

			if (cur == spv.i[gid]) {
				gid++; cur = 0;
			}
		}
#undef ShaderName

		std::vector <int>   traceID;

		uint32_t  trace_handle_size = 0;
		std::vector <int>  bgID;
		uint32_t bg_handle_size = 0;

		setBuffer.sbt.size = 0;
		setBuffer.sbt2.size = 0;

		/*
		for (int i = 0; i < spv.nums(); i++) {
			uint32_t asize = 0;
			for (auto& el : inst[i])asize += el.array_size;
			setBuffer.sbt.size += align.i[i] * asize;
			handle_size += rayTracingProperties.shaderGroupHandleSize * spv.i[i];
		}
		*/
		int SHID = 0;
		for (int i = 0; i < inst.size(); i++) {
			if (i == 0) {
				traceID.push_back(0);
				bgID.push_back(1);
				trace_handle_size += rayTracingProperties.shaderGroupHandleSize;
				bg_handle_size += rayTracingProperties.shaderGroupHandleSize;
				setBuffer.sbt.size += align.i[i];
				setBuffer.sbt2.size += align.i[i];
				SHID += 2;
			}
			if (i == 1 || i == 2) {

				traceID.push_back(SHID + 0);
				bgID.push_back(SHID + 0);

				setBuffer.sbt.size += align.i[i] * inst[i][0].array_size;
				setBuffer.sbt2.size += align.i[i] * inst[i][0].array_size;
				trace_handle_size += rayTracingProperties.shaderGroupHandleSize;
				bg_handle_size += rayTracingProperties.shaderGroupHandleSize;

				traceID.push_back(SHID + 1);
				setBuffer.sbt.size += align.i[i] * inst[i][1].array_size;
				trace_handle_size += rayTracingProperties.shaderGroupHandleSize;

				SHID += 2;
			}
			if (i == 3) {
				for (int j = 0; j < inst[i].size(); j++) {
					traceID.push_back(SHID + j);
					setBuffer.sbt.size += align.i[i] * inst[i][0].array_size;
					trace_handle_size += rayTracingProperties.shaderGroupHandleSize;
					if (j < 10) {
						bgID.push_back(SHID + j);
						setBuffer.sbt2.size += align.i[i] * inst[i][0].array_size;
						bg_handle_size += rayTracingProperties.shaderGroupHandleSize;
					}
				}

			}
		}


		std::vector<VkPipelineShaderStageCreateInfo> traceshaderStages;
		std::vector<VkRayTracingShaderGroupCreateInfoNV> tracegroups;



		uint32_t geID = 0;
		for (int i : traceID) {
			traceshaderStages.push_back(shaderStages[i]);
			tracegroups.push_back(groups[i]);
			if (groups[i].generalShader != VK_SHADER_UNUSED_NV) {
				tracegroups.back().generalShader = geID++;
			};
			if (groups[i].closestHitShader != VK_SHADER_UNUSED_NV) {
				tracegroups.back().closestHitShader = geID++;
			};
		}





		VkRayTracingPipelineCreateInfoNV rayPipelineInfo{};
		rayPipelineInfo.sType = VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV;
		rayPipelineInfo.stageCount = static_cast<uint32_t>(traceshaderStages.size());
		rayPipelineInfo.pStages = traceshaderStages.data();
		rayPipelineInfo.groupCount = static_cast<uint32_t>(tracegroups.size());
		rayPipelineInfo.pGroups = tracegroups.data();
		rayPipelineInfo.maxRecursionDepth = 5;
		rayPipelineInfo.layout = descVk->draft;
		rayPipelineInfo.flags = VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT;



		auto now = std::chrono::high_resolution_clock::now();
		VK_CHECK_RESULT(vkCreateRayTracingPipelinesNV($device, VK_NULL_HANDLE, 1, &rayPipelineInfo, nullptr, &pipeline));
		printf(" execution  vkCreateRayTracingPipelinesNV  Critical    time    %.5f    ms    \n ", (float)(std::chrono::duration<double, std::milli>(std::chrono::high_resolution_clock::now() - now).count()));



		if (bgInfo.bg_pipeline) {

			std::vector<VkPipelineShaderStageCreateInfo> bgshaderStages;
			std::vector<VkRayTracingShaderGroupCreateInfoNV> bggroups;
			geID = 0;
			for (int i : bgID) {
				bgshaderStages.push_back(shaderStages[i]);
				bggroups.push_back(groups[i]);
				if (groups[i].generalShader != VK_SHADER_UNUSED_NV) {
					bggroups.back().generalShader = geID++;
				};
				if (groups[i].closestHitShader != VK_SHADER_UNUSED_NV) {
					bggroups.back().closestHitShader = geID++;
				};
			}
			rayPipelineInfo.stageCount = static_cast<uint32_t>(bgshaderStages.size());
			rayPipelineInfo.pStages = bgshaderStages.data();
			rayPipelineInfo.groupCount = static_cast<uint32_t>(bggroups.size());
			rayPipelineInfo.pGroups = bggroups.data();
			now = std::chrono::high_resolution_clock::now();
			VK_CHECK_RESULT(vkCreateRayTracingPipelinesNV($device, VK_NULL_HANDLE, 1, &rayPipelineInfo, nullptr, &bgpipeline));
			printf(" execution  vkCreateRayTracingPipelinesNV  Critical    time    %.5f    ms    \n ", (float)(std::chrono::duration<double, std::milli>(std::chrono::high_resolution_clock::now() - now).count()));

		}



		for (auto& s : shaderStages)
			vkDestroyShaderModule($device, s.module, nullptr);

		if (vobjVk == nullptr) {
			if (!$tank.takeout(vobjVk, 0)) {
				log_bad(" not found  VisibleObjectVk.");
			};
		};



		setBuffer.sbt.buffer.id = -1;
		vobjVk->$createBuffer$(setBuffer.sbt, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

		auto mapSbt = [&](uint8_t* handle, uint8_t*& data, uint32_t gid, uint32_t spvId, void* t = nullptr, uint32_t size = 0) {
			const uint32_t hsize = rayTracingProperties.shaderGroupHandleSize;
			memcpy(data, handle + spvId * hsize, hsize);
			if (t != nullptr) {
				memcpy(data + hsize, t, size);
			}
			data += align.i[gid];
		};

		gid = 0;
		uint32_t spvId = 0;
		uint8_t* handle = new uint8_t[trace_handle_size];

		VK_CHECK_RESULT(vkGetRayTracingShaderGroupHandlesNV($device, pipeline, 0, traceID.size(), trace_handle_size, handle));
		auto* dataSBT = static_cast<uint8_t*>(setBuffer.sbt.mapped);
		for (uint32_t gid = 0; gid < spv.nums(); gid++) {
			sbtData in;
			for (int i = 0; i < inst[gid].size(); i++) {
				if (gid == 0) {
					if (i > 0)continue;
					in = inst[gid][i];
				}
				else in = inst[gid][i];

				BYTE* data = (BYTE*)in.data;
				for (uint32_t num = 0; num < in.array_size; num++) {
					mapSbt(handle, dataSBT, gid, spvId, (void*)data, in.data_size);
					if (data != nullptr)data += in.data_size;
				}
				spvId++;
			}
		}

		delete[] handle;


		if (bgInfo.bg_pipeline) {

			setBuffer.sbt2.buffer.id = -1;
			vobjVk->$createBuffer$(setBuffer.sbt2, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
			uint8_t* handle2 = new uint8_t[bg_handle_size];
			VK_CHECK_RESULT(vkGetRayTracingShaderGroupHandlesNV($device, bgpipeline, 0, bgID.size(), bg_handle_size, handle2));
			auto* dataSBT2 = static_cast<uint8_t*>(setBuffer.sbt2.mapped);
			spvId = 0;
			for (uint32_t gid = 0; gid < spv.nums(); gid++) {
				sbtData in;
				for (int i = 0; i < inst[gid].size(); i++) {
					if (gid == 0) {
						if (i == 0)continue;
						in = inst[gid][i];
					}
					else if (gid == 1 || gid == 2) {
						if (i == 1)continue;
						in = inst[gid][i];
					}
					else if (gid == 3) {
						if (i >= 10)continue;
						in = inst[gid][i];
					}

					BYTE* data = (BYTE*)in.data;
					for (uint32_t num = 0; num < in.array_size; num++) {
						mapSbt(handle2, dataSBT2, gid, spvId, (void*)data, in.data_size);
						if (data != nullptr)data += in.data_size;
					}
					spvId++;
				}
			}
			delete[] handle2;
		}


		GetCTX($ctx)
			$ctx->deb.setObjectName(setBuffer.sbt.vkBuffer, "SBT_CHIT");
		if (bgInfo.bg_pipeline)$ctx->deb.setObjectName(setBuffer.sbt2.vkBuffer, "SBT2_CHIT");


		/*
		const uint32_t shaderGroupHandleSize = rayTracingProperties.shaderGroupBaseAlignment;// ;
		memcpy(data, shaderHandleStorage + Raygen * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;


		memcpy(data, shaderHandleStorage + Miss * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;

		memcpy(data, shaderHandleStorage + Miss2 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;


		memcpy(data, shaderHandleStorage + ClosestHit * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += hitSize;


		memcpy(data, shaderHandleStorage + ClosestHit2 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		memcpy(data + rayTracingProperties.shaderGroupHandleSize, &HitRecordBuffer[0], sizeof(HitRecordBuffer));  // Hit 1 data
		data += hitSize;

		float HitRecordBuffer2[4] = { 1.f, 1.f,0.2f ,1.f };
		memcpy(data, shaderHandleStorage + ClosestHit2 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		memcpy(data + rayTracingProperties.shaderGroupHandleSize, &HitRecordBuffer2[0], sizeof(HitRecordBuffer2));  // Hit 2 data
		data += hitSize;

		memcpy(data, shaderHandleStorage + Call1 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;
		memcpy(data, shaderHandleStorage + Call2 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;
		memcpy(data, shaderHandleStorage + Call3 * rayTracingProperties.shaderGroupHandleSize, rayTracingProperties.shaderGroupHandleSize);// , rayTracingProperties.shaderGroupHandleSize);
		data += shaderGroupHandleSize;
		*/


	}

	void createRayTracingPipeline_der() {


		createDraft();

		typedef float HitRecordBuffer[4];


		std::vector<HitRecordBuffer> hit2(2);
		hit2[0][0] = 0.5f, hit2[0][1] = 0.0f, hit2[0][2] = 0.1f, hit2[0][3] = 1.f;
		hit2[1][0] = 0.1f, hit2[1][1] = 0.5f, hit2[1][2] = 0.1f, hit2[1][3] = 1.f;


		auto align_sbt = [&]<typename T>(T t) { return ROUND_UP(rayTracingProperties.shaderGroupHandleSize + static_cast<int>(sizeof(T)), rayTracingProperties.shaderGroupBaseAlignment); };
		union rtGroup {
			struct {
				uint32_t rgen, rmiss, rchit, rcall;
			};
			struct {
				uint32_t i[4];
			};
			uint32_t size() { return  rgen + rmiss + rchit + rcall; }
			constexpr uint32_t nums() { return 4; }

		}spv = { 1,2,2,24 }, align = {
					rayTracingProperties.shaderGroupBaseAlignment,
					rayTracingProperties.shaderGroupBaseAlignment,
					align_sbt(hit2[0]),
					rayTracingProperties.shaderGroupBaseAlignment
		};

		struct sbtData {
			void* data = nullptr;
			uint32_t data_size;
			uint32_t array_size;
			sbtData() :array_size(0), data_size(0), data(nullptr) {};
			sbtData(uint32_t asize, uint32_t dsize = 0, void* data = nullptr) :array_size(asize), data_size(dsize), data(data) {};
		};


		std::vector<std::vector<sbtData>> inst(spv.nums());
		inst = {
			{ {1} },
			{ {1},{1}},
			{ {1},{2, sizeof(HitRecordBuffer) , hit2.data() } },
			{
				{1},{1} ,{1},{1},{1} ,{1},
					{1},{1} ,{1},{1},{1} ,{1},
						{1},{1} ,{1},{1},{1} ,{1},
				{1},{1} ,{1},{1},{1} ,{1}
				}
		};



		const std::tuple<VkShaderStageFlagBits, VkRayTracingShaderGroupTypeNV, std::string> flags[spv.nums()]
			= {
			   {VK_SHADER_STAGE_RAYGEN_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rgen"},
				{VK_SHADER_STAGE_MISS_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rmiss"},
				{VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV,"rchit"},
				{VK_SHADER_STAGE_CALLABLE_BIT_KHR,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rcall"}
		};

		std::vector<VkPipelineShaderStageCreateInfo> shaderStages(spv.size());
		std::vector<VkRayTracingShaderGroupCreateInfoNV> groups(spv.size());
		for (auto& group : groups) {
			group.sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV;
			group.generalShader = VK_SHADER_UNUSED_NV;
			group.closestHitShader = VK_SHADER_UNUSED_NV;
			group.anyHitShader = VK_SHADER_UNUSED_NV;
			group.intersectionShader = VK_SHADER_UNUSED_NV;
		}



#define ShaderName(stage,n) getAssetPath() + PRG + "prg" + std::to_string(n) + "." + stage  + ".spv"
		uint32_t  cur = 0;
		uint32_t  gid = 0;
		uint32_t   idx = 0;
		for (auto& s : shaderStages) {
			if (cur < spv.i[gid]) {
				groups[idx].type = std::get<1>(flags[gid]);
				if (gid == 2) groups[idx].closestHitShader = idx;
				else groups[idx].generalShader = idx;
				shaderStages[idx++] = PipelineVk::loadShader(ShaderName(std::get<2>(flags[gid]), cur), std::get<0>(flags[gid]));
				cur++;
			}

			if (cur == spv.i[gid]) {
				gid++; cur = 0;
			}
		}
#undef ShaderName
		/*
		typedef enum VkPipelineCreateFlagBits {
			VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT = 0x00000001,
			VK_PIPELINE_CREATE_ALLOW_DERIVATIVES_BIT = 0x00000002,
			VK_PIPELINE_CREATE_DERIVATIVE_BIT = 0x00000004,
			VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT = 0x00000008,
			VK_PIPELINE_CREATE_DISPATCH_BASE_BIT = 0x00000010,
			VK_PIPELINE_CREATE_RAY_TRACING_NO_NULL_ANY_HIT_SHADERS_BIT_KHR = 0x00004000,
			VK_PIPELINE_CREATE_RAY_TRACING_NO_NULL_CLOSEST_HIT_SHADERS_BIT_KHR = 0x00008000,
			VK_PIPELINE_CREATE_RAY_TRACING_NO_NULL_MISS_SHADERS_BIT_KHR = 0x00010000,
			VK_PIPELINE_CREATE_RAY_TRACING_NO_NULL_INTERSECTION_SHADERS_BIT_KHR = 0x00020000,
			VK_PIPELINE_CREATE_RAY_TRACING_SKIP_TRIANGLES_BIT_KHR = 0x00001000,
			VK_PIPELINE_CREATE_RAY_TRACING_SKIP_AABBS_BIT_KHR = 0x00002000,
			VK_PIPELINE_CREATE_DEFER_COMPILE_BIT_NV = 0x00000020,
			VK_PIPELINE_CREATE_CAPTURE_STATISTICS_BIT_KHR = 0x00000040,
			VK_PIPELINE_CREATE_CAPTURE_INTERNAL_REPRESENTATIONS_BIT_KHR = 0x00000080,
			VK_PIPELINE_CREATE_INDIRECT_BINDABLE_BIT_NV = 0x00040000,
			VK_PIPELINE_CREATE_LIBRARY_BIT_KHR = 0x00000800,
			VK_PIPELINE_CREATE_FAIL_ON_PIPELINE_COMPILE_REQUIRED_BIT_EXT = 0x00000100,
			VK_PIPELINE_CREATE_EARLY_RETURN_ON_FAILURE_BIT_EXT = 0x00000200,
			VK_PIPELINE_CREATE_DISPATCH_BASE = VK_PIPELINE_CREATE_DISPATCH_BASE_BIT,
			VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT_KHR = VK_PIPELINE_CREATE_VIEW_INDEX_FROM_DEVICE_INDEX_BIT,
			VK_PIPELINE_CREATE_DISPATCH_BASE_KHR = VK_PIPELINE_CREATE_DISPATCH_BASE,
			VK_PIPELINE_CREATE_FLAG_BITS_MAX_ENUM = 0x7FFFFFFF
		} VkPipelineCreateFlagBits;
		typedef VkFlags VkPipelineCreateFlags;
		typedef struct VkRayTracingPipelineCreateInfoNV {
			VkStructureType                               sType;
			const void* pNext;
			VkPipelineCreateFlags                         flags;
			uint32_t                                      stageCount;
			const VkPipelineShaderStageCreateInfo* pStages;
			uint32_t                                      groupCount;
			const VkRayTracingShaderGroupCreateInfoNV* pGroups;
			uint32_t                                      maxRecursionDepth;
			VkPipelineLayout                              layout;
			VkPipeline                                    basePipelineHandle;
			int32_t                                       basePipelineIndex;
		} VkRayTracingPipelineCreateInfoNV;
		*/


		std::vector<int>   baseID = {
			0,1,2,3,4
		};
		std::vector<int>   derivID;
		for (int i = 5; i < 25; i++)derivID.push_back(i);



		std::vector<VkPipelineShaderStageCreateInfo> baseshaderStages;
		std::vector<VkRayTracingShaderGroupCreateInfoNV> basegroups;
		for (int i : baseID) {
			baseshaderStages.push_back(shaderStages[i]);
			basegroups.push_back(groups[i]);
		}

		std::vector<VkPipelineShaderStageCreateInfo> derivshaderStages;
		std::vector<VkRayTracingShaderGroupCreateInfoNV> derivgroups;

		for (int i : derivID) {
			derivshaderStages.push_back(shaderStages[i]);
			derivgroups.push_back(groups[i]);
		}




		VkRayTracingPipelineCreateInfoNV rayPipelineInfo{};

		rayPipelineInfo.flags = VK_PIPELINE_CREATE_ALLOW_DERIVATIVES_BIT;

		rayPipelineInfo.sType = VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV;
		rayPipelineInfo.stageCount = static_cast<uint32_t>(derivshaderStages.size());
		rayPipelineInfo.pStages = derivshaderStages.data();
		rayPipelineInfo.groupCount = static_cast<uint32_t>(derivgroups.size());
		rayPipelineInfo.pGroups = derivgroups.data();
		rayPipelineInfo.maxRecursionDepth = 5;
		rayPipelineInfo.layout = descVk->draft;


		auto now = std::chrono::high_resolution_clock::now();
		VK_CHECK_RESULT(vkCreateRayTracingPipelinesNV($device, pipelineCache, 1, &rayPipelineInfo, nullptr, &basepipeline));
		printf(" execution  Base vkCreateRayTracingPipelinesNV  Critical    time    %.5f    ms    \n ", (float)(std::chrono::duration<double, std::milli>(std::chrono::high_resolution_clock::now() - now).count()));

		/*
		rayPipelineInfo.flags = VK_PIPELINE_CREATE_DERIVATIVE_BIT;
		rayPipelineInfo.basePipelineHandle = basepipeline;
		rayPipelineInfo.basePipelineIndex = -1;
		rayPipelineInfo.stageCount = static_cast<uint32_t>(baseshaderStages.size());
		rayPipelineInfo.pStages = baseshaderStages.data();
		rayPipelineInfo.groupCount = static_cast<uint32_t>(basegroups.size());
		rayPipelineInfo.pGroups = basegroups.data();

		now = std::chrono::high_resolution_clock::now();
		VK_CHECK_RESULT(vkCreateRayTracingPipelinesNV($device, pipelineCache, 1, &rayPipelineInfo,nullptr,  &pipeline));
		printf(" execution  Deriv vkCreateRayTracingPipelinesNV  Critical    time    %.5f    ms    \n ", (float)(std::chrono::duration<double, std::milli>(std::chrono::high_resolution_clock::now() - now).count()));

		*/
		for (auto& s : shaderStages)vkDestroyShaderModule($device, s.module, nullptr);





	}

	static const uint32_t SPV_TYPES = 4;    // template
	enum class GROUP_TY : uint32_t {
		RGEN, RMISS, RCHIT, RCALL, ALL_RAY_GROUPE_TYPE
	};
	struct hitgroup {
		bool closehit;
		bool intersect;
		bool anyhit;
	};
	union rtGroup {
		struct {
			uint32_t rgen, rmiss, rchit, rcall;
		};
		struct {
			uint32_t i[SPV_TYPES];
		};
		uint32_t size() { return  rgen + rmiss + rchit + rcall; }
		uint32_t offset(uint32_t n) { uint32_t sum = 0; for (int j = 0; j < (int)n; j++) sum += i[j]; return sum; }
		constexpr uint32_t nums() { return SPV_TYPES; }
	};

	template<typename HRB>
	struct rayGroups {
		typedef  HRB HitRecordBuffer;
		std::vector<HitRecordBuffer> hitRB;

		const std::tuple<VkShaderStageFlagBits, VkRayTracingShaderGroupTypeNV, std::string> flags[SPV_TYPES + 2]
			= {
			   {VK_SHADER_STAGE_RAYGEN_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rgen"},
				{VK_SHADER_STAGE_MISS_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rmiss"},
				{VK_SHADER_STAGE_CLOSEST_HIT_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV,"rchit"},
				{VK_SHADER_STAGE_CALLABLE_BIT_KHR,VK_RAY_TRACING_SHADER_GROUP_TYPE_GENERAL_NV,"rcall"},
				{VK_SHADER_STAGE_INTERSECTION_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV,"rint"},
				{VK_SHADER_STAGE_ANY_HIT_BIT_NV,VK_RAY_TRACING_SHADER_GROUP_TYPE_TRIANGLES_HIT_GROUP_NV,"rahit"},
		};
		VkPhysicalDeviceRayTracingPropertiesNV& rayTracingProperties;

		rtGroup spv, align;


		std::vector<hitgroup> hg;

		template<typename T>
		uint32_t align_sbt() { return (uint32_t)ROUND_UP(rayTracingProperties.shaderGroupHandleSize + static_cast<int>(sizeof(T)), rayTracingProperties.shaderGroupBaseAlignment); };
		struct sbtData {
			void* data = nullptr;
			uint32_t data_size;
			uint32_t array_size;
			sbtData() :array_size(0), data_size(0), data(nullptr) {};
			sbtData(uint32_t asize, uint32_t dsize = 0, void* data = nullptr) :array_size(asize), data_size(dsize), data(data) {};
		};
		std::vector<std::vector<sbtData*>> inst;
		std::function<void()> updateHRB;

		void setGroupArange(uint32_t rgen, uint32_t  rmiss, uint32_t  rchit, uint32_t  rcall) {
			spv.rgen = rgen; spv.rmiss = rmiss; spv.rchit = rchit; spv.rcall = rcall;
			hg.resize(rchit);
			align.rgen = rayTracingProperties.shaderGroupBaseAlignment;
			align.rmiss = rayTracingProperties.shaderGroupBaseAlignment;
			align.rchit = align_sbt<HitRecordBuffer>();
			align.rcall = rayTracingProperties.shaderGroupBaseAlignment;
			inst.resize(spv.nums());
			int i = 0;
			for (auto& sbt : inst) {
				for (int j = 0; j < (int)spv.i[i]; j++)sbt.push_back(nullptr);
				i++;
			}
		};

		void setHG(uint32_t n, bool isect, bool ahit, bool chit = true) {
			hg[n].intersect = isect; hg[n].anyhit = ahit; hg[n].closehit = chit;
		}
		void setHRBreplicant(uint32_t spvN, uint32_t asize) {
			hitRB.resize(asize);
			inst[uint32_t(GROUP_TY::RCHIT)][spvN] = new sbtData(asize, sizeof(HitRecordBuffer), hitRB.data());
		}

		struct shadergroup {
			VkPipelineShaderStageCreateInfo  main;
			VkPipelineShaderStageCreateInfo  isect;
			VkPipelineShaderStageCreateInfo   ahit;
		};
		std::vector<shadergroup> shaderStages;
		std::vector<VkRayTracingShaderGroupCreateInfoNV> groups;

		void createShader(std::string PRGPATH) {
			shaderStages.resize(spv.size());
			groups.resize(spv.size());
			for (auto& group : groups) {
				group.sType = VK_STRUCTURE_TYPE_RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV;
				group.generalShader = VK_SHADER_UNUSED_NV;
				group.closestHitShader = VK_SHADER_UNUSED_NV;
				group.anyHitShader = VK_SHADER_UNUSED_NV;
				group.intersectionShader = VK_SHADER_UNUSED_NV;
			}
#define ShaderName(stage,n) getAssetPath() + PRGPATH + "prg" + std::to_string(n) + "." + stage  + ".spv"
			uint32_t  cur = 0;
			uint32_t  gid = 0;
			uint32_t   idx = 0;
			uint32_t   shidx = 0;
			for (auto& s : shaderStages) {
				if (cur < spv.i[gid]) {

					shaderStages[idx].isect.module = VK_NULL_HANDLE;
					shaderStages[idx].ahit.module = VK_NULL_HANDLE;
					shaderStages[idx].main.module = VK_NULL_HANDLE;

					groups[idx].type = std::get<1>(flags[gid]);
					if (gid == 2) {

						if (hg[cur].intersect) {
							groups[idx].intersectionShader = shidx++;
							shaderStages[idx].isect = PipelineVk::loadShader(ShaderName(std::get<2>(flags[4]), cur), std::get<0>(flags[4]));
						}
						if (hg[cur].anyhit) {
							groups[idx].anyHitShader = shidx++;
							shaderStages[idx].ahit = PipelineVk::loadShader(ShaderName(std::get<2>(flags[5]), cur), std::get<0>(flags[5]));
						}
						if (hg[cur].closehit) {
							groups[idx].closestHitShader = shidx++;
							shaderStages[idx].main = PipelineVk::loadShader(ShaderName(std::get<2>(flags[gid]), cur), std::get<0>(flags[gid]));
						}
					}
					else {
						groups[idx].generalShader = shidx++;
						shaderStages[idx].main = PipelineVk::loadShader(ShaderName(std::get<2>(flags[gid]), cur), std::get<0>(flags[gid]));
					}
					idx++;
					cur++;
				}
				if (cur == spv.i[gid]) {
					gid++; cur = 0;
				}
			}
#undef ShaderName
		}

		StoBache* sbt;
		std::vector <int>   pipeMemberID;
		std::vector <std::vector<int>>   pipeGroupID;
		uint32_t              handle_size = 0;
		void registerbegin(StoBache* _sbt) {
			pipeMemberID.clear();
			pipeGroupID.clear();
			pipeGroupID.resize(uint32_t(GROUP_TY::ALL_RAY_GROUPE_TYPE));
			sbt = _sbt;
			sbt->size = 0;
			handle_size = 0;
		};
		void registerID(GROUP_TY g, uint32_t n) {
			uint32_t gid = uint32_t(g);
			uint32_t  ofs = spv.offset(gid);
			pipeMemberID.push_back(ofs + n);
			pipeGroupID[gid].push_back(n);
			handle_size += rayTracingProperties.shaderGroupHandleSize;
			if (inst[gid][n] != nullptr) {
				sbt->size += align.i[gid] * inst[gid][n]->array_size;
			}
			else sbt->size += align.i[gid];
		};

		void createPipeline(VkPipeline& pipe, VkPipelineLayout draft) {

			std::vector<VkPipelineShaderStageCreateInfo>                   Stages;
			std::vector<VkRayTracingShaderGroupCreateInfoNV>        Groups;
			uint32_t geID = 0;
			for (int i : pipeMemberID) {

				Groups.push_back(groups[i]);
				if (groups[i].generalShader != VK_SHADER_UNUSED_NV) {
					Stages.push_back(shaderStages[i].main);
					Groups.back().generalShader = geID++;
				};
				if (groups[i].closestHitShader != VK_SHADER_UNUSED_NV) {
					Stages.push_back(shaderStages[i].main);
					Groups.back().closestHitShader = geID++;
				};
				if (groups[i].intersectionShader != VK_SHADER_UNUSED_NV) {
					Groups.back().intersectionShader = geID++;
					Stages.push_back(shaderStages[i].isect);
				};
				if (groups[i].anyHitShader != VK_SHADER_UNUSED_NV) {
					Groups.back().anyHitShader = geID++;
					Stages.push_back(shaderStages[i].ahit);
				};
			}


			VkRayTracingPipelineCreateInfoNV rayPipelineInfo{};
			rayPipelineInfo.sType = VK_STRUCTURE_TYPE_RAY_TRACING_PIPELINE_CREATE_INFO_NV;
			rayPipelineInfo.stageCount = static_cast<uint32_t>(Stages.size());
			rayPipelineInfo.pStages = Stages.data();
			rayPipelineInfo.groupCount = static_cast<uint32_t>(Groups.size());
			rayPipelineInfo.pGroups = Groups.data();
			rayPipelineInfo.maxRecursionDepth = 5;
			rayPipelineInfo.layout = draft;
			rayPipelineInfo.flags = VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT;

			auto now = std::chrono::high_resolution_clock::now();
			VK_CHECK_RESULT(vkCreateRayTracingPipelinesNV($device, VK_NULL_HANDLE, 1, &rayPipelineInfo, nullptr, &pipe));
			printf(" execution  vkCreateRayTracingPipelinesNV  Critical    time    %.5f    ms    \n ", (float)(std::chrono::duration<double, std::milli>(std::chrono::high_resolution_clock::now() - now).count()));

			updateHRB();
			mapSBT(pipe);

		}

		VisibleObjectsVk* vobjVk = nullptr;
		void mapSBT(VkPipeline pipe) {
			if (vobjVk == nullptr) {
				if (!$tank.takeout(vobjVk, 0)) {
					log_bad(" not found  VisibleObjectVk.");
				};
			};
			sbt->buffer.id = -1;
			vobjVk->$createBuffer$(*sbt, VK_BUFFER_USAGE_RAY_TRACING_BIT_NV, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);



			uint32_t gid = 0;
			uint32_t spvId = 0;
			uint8_t* handle = new uint8_t[handle_size];

			VK_CHECK_RESULT(vkGetRayTracingShaderGroupHandlesNV($device, pipe, 0, pipeMemberID.size(), handle_size, handle));
			auto* dataSBT = static_cast<uint8_t*>(sbt->mapped);
			uint64_t data_ofs = 0;

			auto mapSbt = [&](uint64_t& data_ofs, uint32_t gid, uint32_t spvId, void* t = nullptr, uint32_t size = 0) {
				const uint32_t hsize = rayTracingProperties.shaderGroupHandleSize;
				memcpy(dataSBT + data_ofs, handle + spvId * hsize, hsize);
				if (t != nullptr) {
					memcpy(dataSBT + data_ofs + hsize, t, size);
				}
				data_ofs += (uint64_t)align.i[gid];
			};
			sbtData in;
			for (int g = 0; g < pipeGroupID.size(); g++) {
				for (int n : pipeGroupID[g]) {
					in.data = nullptr;
					in.array_size = 1;
					in.data_size = 0;
					if (inst[g][n] != nullptr) {
						in.data = (BYTE*)inst[g][n]->data;
						in.array_size = inst[g][n]->array_size;
						in.data_size = inst[g][n]->data_size;
					}
					for (uint32_t num = 0; num < in.array_size; num++) {
						mapSbt(data_ofs, g, spvId, in.data, in.data_size);
						if (in.data != nullptr)in.data = (BYTE*)in.data + in.data_size;
					}
					spvId++;
				}
			}
			delete[] handle;

		}

		rayGroups(VkPhysicalDeviceRayTracingPropertiesNV rayTracingProperties) :
			rayTracingProperties(rayTracingProperties)
		{};
		~rayGroups() {
			for (auto& group : inst) {
				for (auto& sbt : group) {
					if (sbt != nullptr) delete sbt;
				}
				group.clear();
			}
			inst.clear();

			for (auto& s : shaderStages) {
				vkDestroyShaderModule($device, s.main.module, nullptr);
				if (s.isect.module != VK_NULL_HANDLE)vkDestroyShaderModule($device, s.isect.module, nullptr);
				if (s.ahit.module != VK_NULL_HANDLE)vkDestroyShaderModule($device, s.ahit.module, nullptr);
			}
		}

	};

	rtGroup traceGroup, AlignSBT;
	std::vector<int> tracehg;

	void createRayTracingPipeline3() {


		createDraft();

		typedef struct HitRecordBuffer {
			float v[4];
			void setValue(float  r, float  g, float  b, float  a) {
				v[0] = r; v[1] = g; v[2] = b; v[3] = a;
			};
		}HitRecordBuffer;
		typedef rayGroups<HitRecordBuffer> rayGty;


		auto rgroup = rayGty(rayTracingProperties);

		rgroup.setGroupArange(2, 2, 2, 8);
		rgroup.setHG(0, false, false);
		rgroup.setHG(1, false, true);
		rgroup.setHRBreplicant(1, 2);

		rgroup.updateHRB = [&]() {
			auto recordBuf = rgroup.hitRB;
			recordBuf[0].setValue(0.2f, 0., 0.3f, 1.f);
			recordBuf[1].setValue(0.2f, 0.5f, 0.f, 1.f);
		};

		rgroup.createShader(PRG);

		rgroup.registerbegin(&setBuffer.sbt);
		rgroup.registerID(GROUP_TY::RGEN, 0);
		rgroup.registerID(GROUP_TY::RMISS, 0);
		rgroup.registerID(GROUP_TY::RMISS, 1);
		rgroup.registerID(GROUP_TY::RCHIT, 0);
		rgroup.registerID(GROUP_TY::RCHIT, 1);
		for (int i = 0; i < 8; i++)rgroup.registerID(GROUP_TY::RCALL, i);


		rgroup.createPipeline(pipeline, descVk->draft);

		//cache group info;
		traceGroup = { 1,2,2,8 };
		tracehg.push_back(1);
		tracehg.push_back(2);
		AlignSBT = rgroup.align;

		if (bgInfo.bg_pipeline) {
			rgroup.registerbegin(&setBuffer.sbt2);
			rgroup.registerID(GROUP_TY::RGEN, 1);
			rgroup.registerID(GROUP_TY::RMISS, 0);
			rgroup.registerID(GROUP_TY::RCHIT, 0);
			for (int i = 0; i < 8; i++)rgroup.registerID(GROUP_TY::RCALL, i);
			rgroup.createPipeline(bgpipeline, descVk->draft);
		}




		GetCTX($ctx)
			$ctx->deb.setObjectName(setBuffer.sbt.vkBuffer, "SBT_CHIT");
		if (bgInfo.bg_pipeline)$ctx->deb.setObjectName(setBuffer.sbt2.vkBuffer, "SBT2_CHIT");


	}


	void createRayTracingPipeline4() {
		createDraft();
		typedef struct HitRecordBuffer {
			float v[4];
			void setValue(float  r, float  g, float  b, float  a) {
				v[0] = r; v[1] = g; v[2] = b; v[3] = a;
			};
		}HitRecordBuffer;

		typedef rayGroups<HitRecordBuffer> rayGty;


		auto rgroup = rayGty(rayTracingProperties);

		rgroup.setGroupArange(1, 2, 2, 0);
		rgroup.setHG(0, false, true);
		rgroup.setHG(1, false, false);
		rgroup.setHRBreplicant(1, 2);

		rgroup.updateHRB = [&]() {
			auto recordBuf = rgroup.hitRB;
			recordBuf[0].setValue(0.2f, 0., 0.3f, 1.f);
			recordBuf[1].setValue(0.2f, 0.5f, 0.f, 1.f);
		};

		rgroup.createShader(PRG);

		rgroup.registerbegin(&setBuffer.sbt);
		rgroup.registerID(GROUP_TY::RGEN, 0);
		rgroup.registerID(GROUP_TY::RMISS, 0);
		rgroup.registerID(GROUP_TY::RMISS, 1);
		rgroup.registerID(GROUP_TY::RCHIT, 0);
		rgroup.registerID(GROUP_TY::RCHIT, 1);

		rgroup.createPipeline(pipeline, descVk->draft);

		GetCTX($ctx)
			$ctx->deb.setObjectName(setBuffer.sbt.vkBuffer, "SBT_CHIT");



	}

	void createRayTracingPipeline5() {

		createDraft();
		typedef struct HitRecordBuffer {
			float v[4];
			void setValue(float  r, float  g, float  b, float  a) {
				v[0] = r; v[1] = g; v[2] = b; v[3] = a;
			};
		}HitRecordBuffer;
		typedef rayGroups<HitRecordBuffer> rayGty;
		auto rgroup = rayGty(rayTracingProperties);

		const int RGEN_NUMS = 2;
		const int RMISS_NUMS = 3;
		const int RHIT_NUMS = 3;
		const int CALL_NUMS = 12;
		const int TR_RGEN_NUMS = 1;
		const int TR_RMISS_NUMS = 3;
		const int TR_RCHIT_NUMS = 3;
		const int TR_CALL_NUMS = 12;




		rgroup.setGroupArange(RGEN_NUMS, RMISS_NUMS, RHIT_NUMS, CALL_NUMS);
		rgroup.setHG(0, false, true);
		rgroup.setHG(1, false, true, false);
		rgroup.setHG(2, false, true, false);

		rgroup.setHRBreplicant(0, 1);

		rgroup.updateHRB = [&]() {
			auto recordBuf = rgroup.hitRB;
			recordBuf[0].setValue(0.2f, 0., 0.3f, 1.f);
		};

		rgroup.createShader(PRG);

		rgroup.registerbegin(&setBuffer.sbt);

		for (int i = 0; i < TR_RGEN_NUMS; i++) rgroup.registerID(GROUP_TY::RGEN, i);
		for (int i = 0; i < TR_RMISS_NUMS; i++)rgroup.registerID(GROUP_TY::RMISS, i);
		for (int i = 0; i < TR_RCHIT_NUMS; i++)rgroup.registerID(GROUP_TY::RCHIT, i);
		for (int i = 0; i < TR_CALL_NUMS; i++)rgroup.registerID(GROUP_TY::RCALL, i);


		rgroup.createPipeline(pipeline, descVk->draft);


		//cache group info;
		traceGroup = { TR_RGEN_NUMS,
							   TR_RMISS_NUMS,
							   TR_RCHIT_NUMS,
							   TR_CALL_NUMS };

		tracehg.push_back(1);
		tracehg.push_back(1);
		tracehg.push_back(1);

		AlignSBT = rgroup.align;
		if (bgInfo.bg_pipeline) {
			rgroup.registerbegin(&setBuffer.sbt2);
			rgroup.registerID(GROUP_TY::RGEN, 1);
			rgroup.registerID(GROUP_TY::RMISS, 0);
			rgroup.registerID(GROUP_TY::RCHIT, 0);
			for (int i = 0; i < CALL_NUMS; i++)rgroup.registerID(GROUP_TY::RCALL, i);
			rgroup.createPipeline(bgpipeline, descVk->draft);
		}

		GetCTX($ctx)
			$ctx->deb.setObjectName(setBuffer.sbt.vkBuffer, "SBT_CHIT");

	}

	virtual bool makeRT(VkCommandBuffer cmd) override {

		int Id = 0;
		GetCTX($ctx)
			$ctx->deb.beginLabel(cmd, "Ray trace");

		vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_RAY_TRACING_NV, pipeline);
		vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_RAY_TRACING_NV, descVk->draft, 0, 2, uniform.descriptorSets[Id].data(), 0, 0);

		enum {
			INDEX_RAYGEN, INDEX_MISS, INDEX_MISS2, INDEX_CLOSEST_HIT, INDEX_CLOSEST_HIT2
		};
		VkDeviceSize align = rayTracingProperties.shaderGroupBaseAlignment;
		VkDeviceSize bindingOffsetRayGenShader = align * INDEX_RAYGEN;
		VkDeviceSize bindingOffsetMissShader = align * INDEX_MISS;
		VkDeviceSize bindingOffsetHitShader = align * INDEX_CLOSEST_HIT;
		//VkDeviceSize bindingStride = rayTracingProperties.shaderGroupHandleSize;
		float HitRecordBuffer[4] = { 0.1f,0.0f,0.1f,1.f };
		uint32_t hitSize =
			ROUND_UP(rayTracingProperties.shaderGroupHandleSize + static_cast<int>(sizeof(HitRecordBuffer)), rayTracingProperties.shaderGroupBaseAlignment);


		float* f = rtPushConstants.clearColor;
		f[0] = 0.1f, f[1] = 0.7f, f[2] = 0.1f; f[3] = 1.0f;

		static float time = 0.f;

		f = rtPushConstants.lightPosition;
		f[0] = (float)sin(time), f[1] = 4.f, f[2] = (float)cos(time);
		time += 0.01f;

		rtPushConstants.lightIntensity = 1.5;
		rtPushConstants.lightType = 1;

		vkCmdPushConstants(
			cmd,
			descVk->draft,
			VK_SHADER_STAGE_RAYGEN_BIT_KHR |
			VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR |
			VK_SHADER_STAGE_MISS_BIT_KHR,
			0,
			sizeof(rtPushConstants),
			&rtPushConstants);

		vkCmdTraceRaysNV(cmd,
			setBuffer.sbt.vkBuffer, bindingOffsetRayGenShader,
			setBuffer.sbt.vkBuffer, bindingOffsetMissShader, align,
			setBuffer.sbt.vkBuffer, bindingOffsetHitShader, hitSize,
			VK_NULL_HANDLE, 0, 0,
			W, H, 1);

		$ctx->deb.endLabel(cmd);
		return true;
	};


	bool makeRT2(VkCommandBuffer cmd) {

		int Id = 0;
		GetCTX($ctx)
			$ctx->deb.beginLabel(cmd, "Ray trace");

		vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_RAY_TRACING_NV, pipeline);
		vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_RAY_TRACING_NV, descVk->draft, 0, 2, uniform.descriptorSets[Id].data(), 0, 0);

		enum {
			INDEX_RAYGEN, INDEX_MISS, INDEX_MISS2, INDEX_CLOSEST_HIT, INDEX_CLOSEST_HIT2_1, INDEX_CLOSEST_HIT2_2
			, INDEX_CALL1, INDEX_CALL2, INDEX_CALL3
		};

		VkDeviceSize align = rayTracingProperties.shaderGroupBaseAlignment;
		VkDeviceSize bindingOffsetRayGenShader = align * INDEX_RAYGEN;
		VkDeviceSize bindingOffsetMissShader = align * INDEX_MISS;
		VkDeviceSize bindingOffsetHitShader = align * INDEX_CLOSEST_HIT;
		VkDeviceSize bindingOffsetCallShader = align * INDEX_CALL1;
		//VkDeviceSize bindingStride = rayTracingProperties.shaderGroupHandleSize;
		float HitRecordBuffer[4] = { 0.1f,0.0f,0.1f,1.f };
		uint32_t hitSize =
			ROUND_UP(rayTracingProperties.shaderGroupHandleSize + static_cast<int>(sizeof(HitRecordBuffer)), rayTracingProperties.shaderGroupBaseAlignment);


		float* f = rtPushConstants.clearColor;
		f[0] = 0.1f, f[1] = 0.7f, f[2] = 0.1f; f[3] = 1.0f;

		static float time = 0.f;

		f = rtPushConstants.lightPosition;
		f[0] = (float)sin(time), f[1] = 4.f, f[2] = (float)cos(time);
		time += 0.01f;

		rtPushConstants.lightIntensity = 1.5;
		rtPushConstants.lightType = 1;

		vkCmdPushConstants(
			cmd,
			descVk->draft,
			VK_SHADER_STAGE_RAYGEN_BIT_KHR |
			VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR |
			VK_SHADER_STAGE_MISS_BIT_KHR,
			0,
			sizeof(rtPushConstants),
			&rtPushConstants);

		vkCmdTraceRaysNV(cmd,
			setBuffer.sbt.vkBuffer, bindingOffsetRayGenShader,
			setBuffer.sbt.vkBuffer, bindingOffsetMissShader, align,
			setBuffer.sbt.vkBuffer, bindingOffsetHitShader, hitSize,
			setBuffer.sbt.vkBuffer, bindingOffsetCallShader, align,
			W, H, 1);

		$ctx->deb.endLabel(cmd);
		return true;
	};

	std::function<bool(VkCommandBuffer cmd, VkPipelineLayout draft)> cbpush;

	bool makeRT3(VkCommandBuffer cmd) {

		int Id = 0;
		GetCTX($ctx)
			$ctx->deb.beginLabel(cmd, "Ray trace");


		vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_RAY_TRACING_NV, descVk->draft, 0, uniform.descriptorSets[Id].size(), uniform.descriptorSets[Id].data(), 0, 0);

		static float time = 0.f;


		cbpush(cmd, descVk->draft);

		if (pipeline_flags == 1) {
			//if (TEX_BG > 6) {
			vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_RAY_TRACING_NV, bgpipeline);
			enum {
				INDEX_RAYGEN, INDEX_MISS, INDEX_CLOSEST_HIT
				, INDEX_CALL1, INDEX_CALL2, INDEX_CALL3
			};
			VkDeviceSize align = rayTracingProperties.shaderGroupBaseAlignment;
			VkDeviceSize bindingOffsetRayGenShader = align * INDEX_RAYGEN;
			VkDeviceSize bindingOffsetMissShader = align * INDEX_MISS;
			VkDeviceSize bindingOffsetHitShader = align * INDEX_CLOSEST_HIT;
			VkDeviceSize bindingOffsetCallShader = align * INDEX_CALL1;

			vkCmdTraceRaysNV(cmd,
				setBuffer.sbt2.vkBuffer, bindingOffsetRayGenShader,
				setBuffer.sbt2.vkBuffer, bindingOffsetMissShader, align,
				setBuffer.sbt2.vkBuffer, bindingOffsetHitShader, align,
				setBuffer.sbt2.vkBuffer, bindingOffsetCallShader, align,

				bgInfo.dim[0], bgInfo.dim[1], bgInfo.dim[2]);
			buffer_barrierBG(cmd);

		}
		if (pipeline_flags == 0) {

			buffer_pre();
			vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_RAY_TRACING_NV, pipeline);


			VkDeviceSize bindingOffsetRayGenShader = 0;
			VkDeviceSize bindingOffsetMissShader = AlignSBT.rgen * traceGroup.rgen;
			VkDeviceSize bindingOffsetHitShader = bindingOffsetMissShader + AlignSBT.rmiss * traceGroup.rmiss;
			VkDeviceSize bindingOffsetCallShader = bindingOffsetHitShader;
			for (auto& i : tracehg)  bindingOffsetCallShader += AlignSBT.rchit * i;

			vkCmdTraceRaysNV(cmd,
				setBuffer.sbt.vkBuffer, bindingOffsetRayGenShader,
				setBuffer.sbt.vkBuffer, bindingOffsetMissShader, AlignSBT.rmiss,
				setBuffer.sbt.vkBuffer, bindingOffsetHitShader, AlignSBT.rchit,
				setBuffer.sbt.vkBuffer, bindingOffsetCallShader, AlignSBT.rcall,
				W, H, 1);
		}

		$ctx->deb.endLabel(cmd);
		return true;
	};
	template<typename Im>
	bool make(VkCommandBuffer cmd, std::vector<Im>& images) {

		if (rt_type == 0)
			makeRT(cmd);
		else if (rt_type == 1)
			makeRT2(cmd);

		VkImageSubresourceRange subresourceRange = {};
		subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
		subresourceRange.baseMipLevel = 0;
		subresourceRange.levelCount = 1;
		subresourceRange.layerCount = 1;



		VkImageMemoryBarrier imageMemoryBarrier = vka::plysm::imageMemoryBarrier();
		imageMemoryBarrier.oldLayout = VK_IMAGE_LAYOUT_GENERAL;
		imageMemoryBarrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		imageMemoryBarrier.image = images[0].image;
		imageMemoryBarrier.subresourceRange = subresourceRange;

		vkCmdPipelineBarrier(
			cmd,
			VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR | VK_ACCESS_SHADER_WRITE_BIT,
			VK_ACCESS_SHADER_READ_BIT,
			0,
			0, nullptr,
			0, nullptr,
			1, &imageMemoryBarrier);


		/*
		imageMemoryBarrier.image = images[1].image;
		vkCmdPipelineBarrier(
			cmd,
			VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR | VK_ACCESS_SHADER_WRITE_BIT,
			VK_ACCESS_SHADER_READ_BIT,
			0,
			0, nullptr,
			0, nullptr,
			1, &imageMemoryBarrier);
		*/


		return true;

	};


	RTShadowMaterialVk(ImmidiateBufferCmd<ImmidiateCmdPool>* cmdVk, vkmm::Allocator* allo, bool rob = true) :cmdVk(cmdVk) {
		type = arth::eMATERIAL::RT;
		if (rob)robjVk = new RtObjectsVk(allo);
		else robjVk = nullptr;
	}




};


namespace material_com {

	int init(aeo::Material* self, PyObject* args, PyObject* kwds);
	int ktxImage(Iache& iach, aeo::Material* self, PyObject* args, int num, bool cube = false);
	int texArray(Iache& iach, aeo::Material* self, PyObject* args, int st = 0, int ed = -1);

	bool getThumbNalis(gui::thumbNails& tn, Iache& iach);
	bool getInfo(Iache& iach,VkDescriptorImageInfo& info);
	size_t getStamp();

};




#endif
