#pragma once

#ifndef CONTEXT1_VK_H
#define CONTEXT1_VK_H
#include "types.hpp"
#ifndef ENABLED_VULKAN_OPTIX
#define ENABLED_VULKAN_OPTIX
#endif
#define   VK_ENABLE_DebugPrint 1

//#define NSIGHT_DEBUG
#ifdef NSIGHT_DEBUG
#undef VK_ENABLE_DebugPrint 
#endif


#ifdef AEOLUS_EXE
#include "aeolus/vthreepy_types.h"

#else
#include "incomplete.h"
#include "working_mm.h"
#endif 


#include  "vulkan/vulkan.hpp"
#include  "vulkan/vulkan_beta.h"
#include <vulkan/vulkan_core.h>




#ifdef  LOG_NO_ctx
#define log_ctx(...)
#else
//#define log_ctx(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#define log_ctx(...) log_out(__FILE__, __LINE__, LOG_INFO, __VA_ARGS__)
#endif
#define GetCTX(c) {if (c == nullptr) {if (!$tank.takeout(c, 0)) {log_bad(" not found  CTX.");};}};


#define  __defaultClearColor  { { 0.025f, 0.025f, 0.025f, 1.0f } }

const std::string getAssetPath();

bool GetVulkanInstanceExtensionsRequired(std::vector< std::string >& outInstanceExtensionList);
template<typename T>
bool GetVulkanDeviceExtensionsRequired(VkPhysicalDevice pPhysicalDevice, std::vector<T>& outDeviceExtensionList);

struct QueueGTVk {
	///G 3  T 1 C 4
	uint32_t  index[2];
	float         priorG[8] = { 0.5f,0.9f,0.2f,0.8f, 0.3f, 0.3f , 0.3f,0.3f };
	float         priorT[1] = { 0.5f };

	struct Size {
		uint32_t G, T;
	}size = { 8,1 };

	VkQueue  queue;
	VkQueue  queueVR;
	VkQueue  queueOL;
	VkQueue  queueTR;
	VkQueue  queueIM;
	VkQueue  queues[4];

	bool createInfo(std::vector<VkDeviceQueueCreateInfo>& vkQCI, std::vector<VkQueueFamilyProperties>& vkQFP);
	void getQ(VkDevice logical);

};

struct ExtensionEntry
{
	ExtensionEntry(const char* entryName, bool isOptional = false, void* pointerFeatureStruct = nullptr, uint32_t checkVersion = 0)
		: name(entryName)
		, optional(isOptional)
		, pFeatureStruct(pointerFeatureStruct)
		, version(checkVersion)
	{
	}
	const char* name{ nullptr };
	bool        optional{ false };
	void* pFeatureStruct{ nullptr };
	uint32_t    version{ 0 };
};
using EEntryArray = std::vector<ExtensionEntry>;
using NameArray = std::vector<const char*>;

struct VulkanFeatures
{

	VkPhysicalDeviceFeatures         features10{};
	VkPhysicalDeviceVulkan11Features features11{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES };
	VkPhysicalDeviceVulkan12Features features12{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES };

	VkPhysicalDeviceProperties         properties10{};
	VkPhysicalDeviceVulkan11Properties properties11{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_PROPERTIES };
	VkPhysicalDeviceVulkan12Properties properties12{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES };
	
	// Vulkan == 1.1 used individual structs
    // Vulkan >= 1.2  have per-version structs
	struct Features11Old
	{
		VkPhysicalDeviceMultiviewFeatures    multiview{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_FEATURES };
		VkPhysicalDevice16BitStorageFeatures t16BitStorage{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES };
		VkPhysicalDeviceSamplerYcbcrConversionFeatures samplerYcbcrConversion{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES };
		VkPhysicalDeviceProtectedMemoryFeatures protectedMemory{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_FEATURES };
		VkPhysicalDeviceShaderDrawParameterFeatures drawParameters{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_DRAW_PARAMETER_FEATURES };
		VkPhysicalDeviceVariablePointerFeatures variablePointers{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES };

		Features11Old()
		{
			multiview.pNext = &t16BitStorage;
			t16BitStorage.pNext = &samplerYcbcrConversion;
			samplerYcbcrConversion.pNext = &protectedMemory;
			protectedMemory.pNext = &drawParameters;
			drawParameters.pNext = &variablePointers;
			variablePointers.pNext = nullptr;
			
		};

		void read(const VkPhysicalDeviceVulkan11Features& features11)
		{
			multiview.multiview = features11.multiview;
			multiview.multiviewGeometryShader = features11.multiviewGeometryShader;
			multiview.multiviewTessellationShader = features11.multiviewTessellationShader;
			t16BitStorage.storageBuffer16BitAccess = features11.storageBuffer16BitAccess;
			t16BitStorage.storageInputOutput16 = features11.storageInputOutput16;
			t16BitStorage.storagePushConstant16 = features11.storagePushConstant16;
			t16BitStorage.uniformAndStorageBuffer16BitAccess = features11.uniformAndStorageBuffer16BitAccess;
			samplerYcbcrConversion.samplerYcbcrConversion = features11.samplerYcbcrConversion;
			protectedMemory.protectedMemory = features11.protectedMemory;
			drawParameters.shaderDrawParameters = features11.shaderDrawParameters;
			variablePointers.variablePointers = features11.variablePointers;
			variablePointers.variablePointersStorageBuffer = features11.variablePointersStorageBuffer;
		}

		void write(VkPhysicalDeviceVulkan11Features& features11)
		{
			features11.multiview = multiview.multiview;
			features11.multiviewGeometryShader = multiview.multiviewGeometryShader;
			features11.multiviewTessellationShader = multiview.multiviewTessellationShader;
			features11.storageBuffer16BitAccess = t16BitStorage.storageBuffer16BitAccess;
			features11.storageInputOutput16 = t16BitStorage.storageInputOutput16;
			features11.storagePushConstant16 = t16BitStorage.storagePushConstant16;
			features11.uniformAndStorageBuffer16BitAccess = t16BitStorage.uniformAndStorageBuffer16BitAccess;
			features11.samplerYcbcrConversion = samplerYcbcrConversion.samplerYcbcrConversion;
			features11.protectedMemory = protectedMemory.protectedMemory;
			features11.shaderDrawParameters = drawParameters.shaderDrawParameters;
			features11.variablePointers = variablePointers.variablePointers;
			features11.variablePointersStorageBuffer = variablePointers.variablePointersStorageBuffer;
		}
	};
	struct Properties11Old
	{
		VkPhysicalDeviceMaintenance3Properties maintenance3{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES };
		VkPhysicalDeviceIDProperties           deviceID{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES };
		VkPhysicalDeviceMultiviewProperties    multiview{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES };
		VkPhysicalDeviceProtectedMemoryProperties protectedMemory{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROTECTED_MEMORY_PROPERTIES };
		VkPhysicalDevicePointClippingProperties pointClipping{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES };
		VkPhysicalDeviceSubgroupProperties      subgroup{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES };

		Properties11Old()
		{
			maintenance3.pNext = &deviceID;
			deviceID.pNext = &multiview;
			multiview.pNext = &protectedMemory;
			protectedMemory.pNext = &pointClipping;
			pointClipping.pNext = &subgroup;
			subgroup.pNext = nullptr;
		}

		void write(VkPhysicalDeviceVulkan11Properties& properties11)
		{
			memcpy(properties11.deviceLUID, deviceID.deviceLUID, sizeof(properties11.deviceLUID));
			memcpy(properties11.deviceUUID, deviceID.deviceUUID, sizeof(properties11.deviceUUID));
			memcpy(properties11.driverUUID, deviceID.driverUUID, sizeof(properties11.driverUUID));
			properties11.deviceLUIDValid = deviceID.deviceLUIDValid;
			properties11.deviceNodeMask = deviceID.deviceNodeMask;
			properties11.subgroupSize = subgroup.subgroupSize;
			properties11.subgroupSupportedStages = subgroup.supportedStages;
			properties11.subgroupSupportedOperations = subgroup.supportedOperations;
			properties11.subgroupQuadOperationsInAllStages = subgroup.quadOperationsInAllStages;
			properties11.pointClippingBehavior = pointClipping.pointClippingBehavior;
			properties11.maxMultiviewViewCount = multiview.maxMultiviewViewCount;
			properties11.maxMultiviewInstanceIndex = multiview.maxMultiviewInstanceIndex;
			properties11.protectedNoFault = protectedMemory.protectedNoFault;
			properties11.maxPerSetDescriptors = maintenance3.maxPerSetDescriptors;
			properties11.maxMemoryAllocationSize = maintenance3.maxMemoryAllocationSize;
		}
	};

	void getFeatures(VkPhysicalDevice physical, VkPhysicalDeviceFeatures2&   features2, VkPhysicalDeviceProperties2& properties2) {

		// for queries and device creation
		features2 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2 };
		properties2 = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2 };

	
		features2.pNext = &features11;
		features11.pNext = &features12;
		features12.pNext = nullptr;

		properties12.driverID = VK_DRIVER_ID_NVIDIA_PROPRIETARY;
		properties12.supportedDepthResolveModes = VK_RESOLVE_MODE_MAX_BIT;
		properties12.supportedStencilResolveModes = VK_RESOLVE_MODE_MAX_BIT;

		properties2.pNext = &properties11;
		properties11.pNext = &properties12;
		properties12.pNext = nullptr;

		vkGetPhysicalDeviceFeatures2(physical, &features2);
		vkGetPhysicalDeviceProperties2(physical, &properties2);

		properties10 = properties2.properties;
		features10 = features2.features;


		/*
		Features11Old             features11old;
		features11old.read(features11);

		features2.pNext = &features11;
		features11.pNext = &features12;
	    features12.pNext = nullptr;
		*/

	};


};




VkResult fillFilteredNameArray(std::vector < const char*>& used,
	const std::vector<VkExtensionProperties>& properties,
	const std::vector<ExtensionEntry>& requested,
	std::vector<void*>& featureStructs);





template<class Q>
struct DeviceMasterVk {


	VkInstance instance;
    VulkanFeatures vulkanFeatures;

	VkPhysicalDevice physical;
	VkDevice logical;

	Q            Qvillage;
	struct _ShaderProp {
		uint32_t subgroupSize, shaderSMCount, shaderWarpsPerSM;
	}ShaderProp;

	VkPhysicalDeviceMemoryProperties memoryProperties;
	VkPhysicalDeviceProperties   properties;

	VkPhysicalDeviceFeatures features;
	VkPhysicalDeviceFeatures enabledFeatures{};
	
	std::vector<ExtensionEntry>                                    requireDeviceExtensions;
	std::vector < const char*>                                        enabledDeviceExtensions;
	                              

	std::vector<std::string> supportedExtensions;

	_Vkformat  format;

	std::vector<VkQueueFamilyProperties> queueFamilyProperties;

	queueFamilyIndices queueFamilyIndices;

	VkCommandPool commandPool = VK_NULL_HANDLE;

	bool enableDebugMarkers;

	void  configuration() {

#ifdef  ENABLED_VULKAN_OVR 
		uint64_t pHMDPhysicalDevice = 0;
		GetVulkanDeviceExtensionsRequired(physical, requireDeviceExtensions);
		vr::VRSystem()->GetOutputDevice(&pHMDPhysicalDevice, vr::TextureType_Vulkan, (VkInstance_T*)instance);
		log_ctx("OVR physical device   %u  ", pHMDPhysicalDevice);
#endif

#ifndef ENABLED_VULKAN_HEADLESS
		requireDeviceExtensions.emplace_back(VK_KHR_SWAPCHAIN_EXTENSION_NAME);

#endif

#ifdef  ENABLED_VULKAN_DEBUG

		if (extensionSupported(VK_EXT_DEBUG_MARKER_EXTENSION_NAME))
		{
			requireDeviceExtensions.emplace_back(VK_EXT_DEBUG_MARKER_EXTENSION_NAME);
			enableDebugMarkers = true;
		};

#endif


#ifdef  ENABLED_VULKAN_OPENCL


		static VkPhysicalDevice8BitStorageFeaturesKHR PD8bitstorage = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES_KHR };
		PD8bitstorage.storageBuffer8BitAccess = VK_TRUE;
		PD8bitstorage.storagePushConstant8 = VK_TRUE;
		PD8bitstorage.uniformAndStorageBuffer8BitAccess = VK_TRUE;
		requireDeviceExtensions.emplace_back(VK_KHR_8BIT_STORAGE_EXTENSION_NAME, false, &PD8bitstorage);
		requireDeviceExtensions.emplace_back(VK_EXT_MEMORY_BUDGET_EXTENSION_NAME);


#endif





		static VkPhysicalDeviceDescriptorIndexingFeaturesEXT physicalDeviceDescriptorIndexingFeatures = { };
		physicalDeviceDescriptorIndexingFeatures.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT;
		physicalDeviceDescriptorIndexingFeatures.shaderSampledImageArrayNonUniformIndexing = VK_TRUE;
		physicalDeviceDescriptorIndexingFeatures.runtimeDescriptorArray = VK_TRUE;
		physicalDeviceDescriptorIndexingFeatures.descriptorBindingVariableDescriptorCount = VK_TRUE;
		physicalDeviceDescriptorIndexingFeatures.shaderStorageBufferArrayNonUniformIndexing = VK_TRUE;
		requireDeviceExtensions.emplace_back(VK_EXT_DESCRIPTOR_INDEXING_EXTENSION_NAME,false, &physicalDeviceDescriptorIndexingFeatures);
		requireDeviceExtensions.emplace_back(VK_KHR_MAINTENANCE3_EXTENSION_NAME);
		requireDeviceExtensions.emplace_back(VK_KHR_DEDICATED_ALLOCATION_EXTENSION_NAME);

		requireDeviceExtensions.emplace_back(VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME);
		requireDeviceExtensions.emplace_back(VK_KHR_EXTERNAL_SEMAPHORE_EXTENSION_NAME);
		requireDeviceExtensions.emplace_back(VK_KHR_EXTERNAL_FENCE_EXTENSION_NAME);
		requireDeviceExtensions.emplace_back(VK_KHR_SHADER_CLOCK_EXTENSION_NAME);


		

		requireDeviceExtensions.emplace_back(VK_KHR_MAINTENANCE1_EXTENSION_NAME);

		static  VkPhysicalDeviceTimelineSemaphoreFeatures timelineFeature = {};
		timelineFeature.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES;
		timelineFeature.timelineSemaphore = VK_TRUE;
		requireDeviceExtensions.emplace_back(VK_KHR_TIMELINE_SEMAPHORE_EXTENSION_NAME,false,&timelineFeature);


		static VkPhysicalDeviceScalarBlockLayoutFeaturesEXT scalarFeature = {};
		scalarFeature.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES_EXT;
		scalarFeature.scalarBlockLayout = VK_TRUE;
		requireDeviceExtensions.emplace_back(VK_EXT_SCALAR_BLOCK_LAYOUT_EXTENSION_NAME, false, &scalarFeature);
		requireDeviceExtensions.emplace_back(VK_KHR_GET_MEMORY_REQUIREMENTS_2_EXTENSION_NAME);
		static VkPhysicalDeviceFloat16Int8FeaturesKHR float16int8Features = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FLOAT16_INT8_FEATURES_KHR };
		float16int8Features.shaderFloat16 = VK_TRUE;
		float16int8Features.shaderInt8 = VK_TRUE;
		requireDeviceExtensions.emplace_back(VK_KHR_SHADER_FLOAT16_INT8_EXTENSION_NAME,false,&float16int8Features);


		requireDeviceExtensions.emplace_back(VK_KHR_MULTIVIEW_EXTENSION_NAME);
		///TODO disappier Nv version 
		/*
		* 
		static VkPhysicalDeviceMeshShaderFeaturesNV meshFeatures = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MESH_SHADER_FEATURES_NV };
		requireDeviceExtensions.emplace_back(VK_NV_MESH_SHADER_EXTENSION_NAME,false,&meshFeatures);
		*/



		requireDeviceExtensions.emplace_back(VK_NV_RAY_TRACING_EXTENSION_NAME);
		//requireDeviceExtensions.emplace_back(VK_KHR_RAY_TRACING_EXTENSION_NAME);
		
#ifdef VK_ENABLE_DebugPrint
		requireDeviceExtensions.emplace_back(VK_KHR_SHADER_NON_SEMANTIC_INFO_EXTENSION_NAME);
#endif


		static VkPhysicalDeviceBufferDeviceAddressFeatures bufaddrFeatures = {
VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES,
		};
		
		bufaddrFeatures.bufferDeviceAddress = VK_TRUE;
		bufaddrFeatures.bufferDeviceAddressCaptureReplay = VK_TRUE;
		///requireDeviceExtensions.emplace_back(VK_EXT_BUFFER_DEVICE_ADDRESS_EXTENSION_NAME,false, &bufaddrFeatures);
		requireDeviceExtensions.emplace_back(VK_KHR_BUFFER_DEVICE_ADDRESS_EXTENSION_NAME, false, &bufaddrFeatures);
		
		
		
		for (auto& v : requireDeviceExtensions) {
			log_ctx(">>>>>>>>>>>>>>>>>>>>>>>>>>      require  a device  extension [ %s ]   \n", v.name);
		 }

	}
	bool  setupPhysicalDevice(VkInstance _instance)
	{

		instance = _instance;
		VkResult err;


		// Physical device
		uint32_t gpuCount = 0;
		// Get number of available physical devices
		VK_CHECK_RESULT(vkEnumeratePhysicalDevices(instance, &gpuCount, nullptr));
		assert(gpuCount > 0);


		// Enumerate devices
		std::vector<VkPhysicalDevice> devicePhysicals(gpuCount);
		err = vkEnumeratePhysicalDevices(instance, &gpuCount, devicePhysicals.data());
		if (err) {
			log_vkabad(err, "Could not enumerate physical devices  \n");
			return false;
		}


		VkPhysicalDeviceIDPropertiesKHR pyid{};
		pyid.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_ID_PROPERTIES;
		VkPhysicalDeviceProperties            prop{};

		VkPhysicalDeviceProperties2 prop2{};
		prop2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
		prop2.properties = prop;

		uint32_t selectedDevice = static_cast<uint32_t>(std::stoul(GPU_DEVICE_ID));

		for (uint32_t d = 0; d < gpuCount; d++) {

			vkGetPhysicalDeviceProperties2(devicePhysicals[d], &prop2);

			log_ctx("device  Name  :: %s   \n", prop2.properties.deviceName);
			/*
			char c[16];
			for (int i = 0; i < 16; i++) c[i]  = char(pyid.deviceUUID[i] + 48);
			log_ctx("uuid ::    %s  \n",c);
			*/

			uint32_t low = 0;
			///int          high =0;
			log_ctx("luid :: VALID %s    \n", (pyid.deviceLUIDValid == VK_TRUE) ? "true" : "false");
			for (int i = 0; i < 4; i++) {
				uint32_t fl = pyid.deviceLUID[i];
				fl = fl << (i * 8);
				low = low | fl;
			}
			log_ctx("  lowpart  %u \n", low);

		}

		physical = devicePhysicals[selectedDevice];
		vkGetPhysicalDeviceProperties(physical, &properties);

		VkPhysicalDeviceShaderSMBuiltinsFeaturesNV Vkpdss = {};
		Vkpdss.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_FEATURES_NV;
		Vkpdss.pNext = NULL;

		VkPhysicalDeviceFeatures            fet={};
		VkPhysicalDeviceFeatures2          fet2={};
		fet2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
		fet2.pNext = &Vkpdss;
		fet2.features = fet;
		vkGetPhysicalDeviceFeatures2(physical, &fet2);
		


		VkPhysicalDeviceShaderSMBuiltinsPropertiesNV Vkpdssp = {};
		Vkpdssp.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_SM_BUILTINS_PROPERTIES_NV;
		Vkpdssp.pNext = NULL;

		prop2.pNext = &Vkpdssp;

		
		vkGetPhysicalDeviceProperties2(physical, &prop2);

		VkPhysicalDeviceFeatures2   features2_;
		VkPhysicalDeviceProperties2 properties2{};
		vulkanFeatures.getFeatures(physical, features2_, properties2);




		ASSERT_PRINT(Vkpdss.shaderSMBuiltins, "Configure failed.  shaderSMBuiltins is False.");
		ASSERT_PRINT(vulkanFeatures.properties11.subgroupSize <= 32, "Configure failed.  subgroupSize <= 32.");
		ASSERT_PRINT(Vkpdssp.shaderSMCount == 40, "Configure failed. shaderSMCount == 40.");
		ASSERT_PRINT(Vkpdssp.shaderWarpsPerSM >= 32, "Configure failed.shaderWarpsPerSM >= 32.");
		

		ShaderProp = { vulkanFeatures.properties11.subgroupSize ,Vkpdssp.shaderSMCount ,Vkpdssp.shaderWarpsPerSM };

		/*
		VkPhysicalDeviceSubgroupProperties subgroupProperties = {};
		subgroupProperties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES;
		subgroupProperties.pNext = NULL;

		VkPhysicalDeviceProperties2 physicalDeviceProperties = {};
		physicalDeviceProperties.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
		physicalDeviceProperties.pNext = &subgroupProperties;
		prop = {};
		physicalDeviceProperties.properties = prop;
		*/
		
		vkGetPhysicalDeviceFeatures(physical, &features);
		vkGetPhysicalDeviceMemoryProperties(physical, &memoryProperties);

		uint32_t extCount = 0;
		vkEnumerateDeviceExtensionProperties(physical, nullptr, &extCount, nullptr);
		if (extCount > 0)
		{
			std::vector<VkExtensionProperties> extensions(extCount);
			if (vkEnumerateDeviceExtensionProperties(physical, nullptr, &extCount, &extensions.front()) == VK_SUCCESS)
			{
				for (auto ext : extensions)
				{
					supportedExtensions.push_back(ext.extensionName);
				}
			}
		}


		uint32_t queueFamilyCount;
		vkGetPhysicalDeviceQueueFamilyProperties(physical, &queueFamilyCount, nullptr);
		assert(queueFamilyCount > 0);
		queueFamilyProperties.resize(queueFamilyCount);

		vkGetPhysicalDeviceQueueFamilyProperties(physical, &queueFamilyCount, queueFamilyProperties.data());


		int idx = 0;
		for (auto& q_family : queueFamilyProperties)
		{
			if (q_family.queueFlags == 15)queueFamilyIndices.stcg = idx;
			if (q_family.queueFlags == 14)queueFamilyIndices.stc = idx;
			if (q_family.queueFlags == 12)queueFamilyIndices.st = idx;
			log_ctx("Queue number: %d   Queue flags: %s    \n", q_family.queueCount, std::to_string(q_family.queueFlags).c_str());
			idx++;
		}

		VkBool32 validDepthFormat = vka::shelve::getSupportedDepthFormat(physical, &format.DEPTHFORMAT);
		assert(validDepthFormat);
		return true;

	};

	VkResult  createLogicalDevice(VkApplicationInfo& app, bool useSwapChain = true, VkQueueFlags requestedQueueTypes = VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT)
	{
		configuration();

		bool enableMeshShader = true;
		std::vector<void*> featureStructs;
		if (requireDeviceExtensions.size() > 0)
		{
			auto extensionProperties = getDeviceExtensions();
			if (fillFilteredNameArray(enabledDeviceExtensions, extensionProperties, requireDeviceExtensions, featureStructs) != VK_SUCCESS)
			{
				return VK_ERROR_VALIDATION_FAILED_EXT;
			}
		}


		std::vector<VkDeviceQueueCreateInfo> queueCreateInfos{};
		Qvillage.createInfo(queueCreateInfos, queueFamilyProperties);
		
		VkDeviceCreateInfo deviceCreateInfo = {};
		deviceCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
		deviceCreateInfo.queueCreateInfoCount = static_cast<uint32_t>(queueCreateInfos.size());;
		deviceCreateInfo.pQueueCreateInfos = queueCreateInfos.data();
		deviceCreateInfo.pEnabledFeatures = &enabledFeatures;
		deviceCreateInfo.enabledExtensionCount = 0;

		if (enabledDeviceExtensions.size() > 0)
		{
			deviceCreateInfo.enabledExtensionCount        = enabledDeviceExtensions.size();
			deviceCreateInfo.ppEnabledExtensionNames   = enabledDeviceExtensions.data();
		}

		VkResult result;

		if (enableMeshShader) {

			deviceCreateInfo.pEnabledFeatures = nullptr;
			VkPhysicalDeviceFeatures2   features2_;
			VkPhysicalDeviceProperties2 properties2{};
			vulkanFeatures.getFeatures(physical, features2_, properties2);

			VkPhysicalDeviceFeatures2 features2{ VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2 };
			
			features2.features = vulkanFeatures.features10;
			static VulkanFeatures::Features11Old             features11old;
			features11old.read(vulkanFeatures.features11);
			features2.pNext = &features11old.multiview;

	

			
			struct ExtensionHeader  // Helper struct to link extensions together
			{
				VkStructureType sType;
				void* pNext;
			};
			
			ExtensionHeader* lastCoreFeature = nullptr;
			if (!featureStructs.empty())
			{
				// build up chain of all used extension features
				for (size_t i = 0; i < featureStructs.size(); i++)
				{
					auto* header = reinterpret_cast<ExtensionHeader*>(featureStructs[i]);
					header->pNext = i < featureStructs.size() - 1 ? featureStructs[i + 1] : nullptr;
				}

				// append to the end of current feature2 struct
			    lastCoreFeature = (ExtensionHeader*)&features2;
				while (lastCoreFeature->pNext != nullptr)
				{
					lastCoreFeature = (ExtensionHeader*)lastCoreFeature->pNext;
				}
				lastCoreFeature->pNext = featureStructs[0];

				// query support
				
			}



			//vkGetPhysicalDeviceFeatures2(physical, &features2);

			features2.features.wideLines = VK_TRUE;
			features2.features.geometryShader = VK_TRUE;
			features2.features.vertexPipelineStoresAndAtomics = VK_TRUE;
			features2.features.robustBufferAccess = VK_FALSE;

			deviceCreateInfo.pNext = &features2;

			result = vkCreateDevice(physical, &deviceCreateInfo, nullptr, &logical);

			//VkPhysicalDeviceBufferDeviceAddressFeatures* bdaFeatures = (VkPhysicalDeviceBufferDeviceAddressFeatures*)requireDeviceExtensions[18].pFeatureStruct;
			//auto tf = bdaFeatures->bufferDeviceAddress;

		}else {

			result = vkCreateDevice(physical, &deviceCreateInfo, nullptr, &logical);

		};

		log_ctx(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Create Device  %x <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n", logical);

		
		Qvillage.getQ(logical);

		this->enabledFeatures = enabledFeatures;

		return result;

	};

	VkResult  createCommandPool(VkCommandPoolCreateFlags createFlags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
	{
		VkCommandPoolCreateInfo cmdPoolInfo = {};
		cmdPoolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
		cmdPoolInfo.queueFamilyIndex = queueFamilyIndices.stcg;
		cmdPoolInfo.flags = createFlags;

		return vkCreateCommandPool(logical, &cmdPoolInfo, nullptr, &commandPool);
	}

	void  destroyLogicalDevice() {

		if (logical)
		{
			log_ctx("ShutDown   Device  \n");
			vkDestroyDevice(logical, nullptr);
			logical = VK_NULL_HANDLE;
		}
	}

	void  destroyCommandPool() {
		if (commandPool)
		{
			log_ctx("ShutDown   CommandPool  \n");
			vkDestroyCommandPool(logical, commandPool, nullptr);
			commandPool = VK_NULL_HANDLE;
		}
	}

	bool  shutdown() {

		destroyCommandPool();

		destroyLogicalDevice();
		return true;
	}

	bool  extensionSupported(std::string extension)
	{
		return (std::find(supportedExtensions.begin(), supportedExtensions.end(), extension) != supportedExtensions.end());
	};

	std::vector<VkExtensionProperties> getDeviceExtensions()
	{
		uint32_t                           count;
		std::vector<VkExtensionProperties> extensionProperties;
		vkEnumerateDeviceExtensionProperties(physical, nullptr, &count, nullptr);
		extensionProperties.resize(count);
		vkEnumerateDeviceExtensionProperties(physical, nullptr, &count, extensionProperties.data());
		extensionProperties.resize(__min(extensionProperties.size(), size_t(count)));
		return extensionProperties;
	};



	uint32_t  getQueueFamilyIndex(VkQueueFlagBits queueFlags)
	{
		// Dedicated queue for compute
		// Try to find a queue family index that supports compute but not graphics
		if (queueFlags & VK_QUEUE_COMPUTE_BIT)
		{
			for (uint32_t i = 0; i < static_cast<uint32_t>(queueFamilyProperties.size()); i++)
			{
				if ((queueFamilyProperties[i].queueFlags & queueFlags) && ((queueFamilyProperties[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) == 0))
				{
					return i;
					break;
				}
			}
		}

		// Dedicated queue for transfer
		// Try to find a queue family index that supports transfer but not graphics and compute
		if (queueFlags & VK_QUEUE_TRANSFER_BIT)
		{
			for (uint32_t i = 0; i < static_cast<uint32_t>(queueFamilyProperties.size()); i++)
			{
				if ((queueFamilyProperties[i].queueFlags & queueFlags) && ((queueFamilyProperties[i].queueFlags & VK_QUEUE_GRAPHICS_BIT) == 0) && ((queueFamilyProperties[i].queueFlags & VK_QUEUE_COMPUTE_BIT) == 0))
				{
					return i;
					break;
				}
			}
		}

		// For other queue types or if no separate compute queue is present, return the first one to support the requested flags
		for (uint32_t i = 0; i < static_cast<uint32_t>(queueFamilyProperties.size()); i++)
		{
			if (queueFamilyProperties[i].queueFlags & queueFlags)
			{
				return i;
				break;
			}
		}

		throw std::runtime_error("Could not find a matching queue family index");
	};


};


enum eContext {
	  Prime,
	  External,
	  ALL
};
template<class T>
struct DebugMaster {

	PFN_vkCreateDebugUtilsMessengerEXT  createDebugUtilsMessengerEXT = nullptr;
	PFN_vkDestroyDebugUtilsMessengerEXT destroyDebugUtilsMessengerEXT = nullptr;
	VkDebugUtilsMessengerEXT           dbgMessenger = nullptr;
	std::unordered_set<int32_t>          dbgIgnoreMessages;
	void ignoreDebugMessage(int32_t msgID)
	{
		dbgIgnoreMessages.insert(msgID);
	}


	static void setEnabled(bool state) { s_enabled = state; }

	void setObjectName(const uint64_t object, const std::string& name, VkObjectType t)
	{
		if (s_enabled)
		{
			VkDebugUtilsObjectNameInfoEXT s{ VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT, nullptr, t, object, name.c_str() };
			vkSetDebugUtilsObjectNameEXT($device, &s);
		}
	}

#if VK_NV_ray_tracing
	void setObjectName(VkAccelerationStructureNV object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_ACCELERATION_STRUCTURE_NV); }
#endif
	void setObjectName(VkBuffer object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_BUFFER); }
	void setObjectName(VkBufferView object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_BUFFER_VIEW); }
	void setObjectName(VkCommandBuffer object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_COMMAND_BUFFER); }
	void setObjectName(VkCommandPool object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_COMMAND_POOL); }
	void setObjectName(VkDescriptorPool object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_DESCRIPTOR_POOL); }
	void setObjectName(VkDescriptorSet object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_DESCRIPTOR_SET); }
	void setObjectName(VkDescriptorSetLayout object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_DESCRIPTOR_SET_LAYOUT); }
	void setObjectName(VkDeviceMemory object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_DEVICE_MEMORY); }
	void setObjectName(VkFramebuffer object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_FRAMEBUFFER); }
	void setObjectName(VkImage object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_IMAGE); }
	void setObjectName(VkImageView object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_IMAGE_VIEW); }
	void setObjectName(VkPipeline object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_PIPELINE); }
	void setObjectName(VkPipelineLayout object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_PIPELINE_LAYOUT); }
	void setObjectName(VkQueryPool object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_QUERY_POOL); }
	void setObjectName(VkQueue object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_QUEUE); }
	void setObjectName(VkRenderPass object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_RENDER_PASS); }
	void setObjectName(VkSampler object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_SAMPLER); }
	void setObjectName(VkSemaphore object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_SEMAPHORE); }
	void setObjectName(VkShaderModule object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_SHADER_MODULE); }
	void setObjectName(VkSwapchainKHR object, const std::string& name) { setObjectName((uint64_t)object, name, VK_OBJECT_TYPE_SWAPCHAIN_KHR); }
	// clang-format on
	//
	//---------------------------------------------------------------------------
	//
	void beginLabel(VkCommandBuffer cmdBuf, const std::string& label)
	{
		if (s_enabled)
		{
			VkDebugUtilsLabelEXT s{ VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT, nullptr, label.c_str(), {1.0f, 1.0f, 1.0f, 1.0f} };
			vkCmdBeginDebugUtilsLabelEXT(cmdBuf, &s);
		}
	}
	void endLabel(VkCommandBuffer cmdBuf)
	{
		if (s_enabled)
		{
			vkCmdEndDebugUtilsLabelEXT(cmdBuf);
		}
}
	void insertLabel(VkCommandBuffer cmdBuf, const std::string& label)
	{
		if (s_enabled)
		{
			VkDebugUtilsLabelEXT s{ VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT, nullptr, label.c_str(), {1.0f, 1.0f, 1.0f, 1.0f} };
			vkCmdInsertDebugUtilsLabelEXT(cmdBuf, &s);
		}
	}
	//
	// Begin and End Command Label MUST be balanced, this helps as it will always close the opened label
	//
	struct ScopedCmdLabel
	{
		ScopedCmdLabel(VkCommandBuffer cmdBuf, const std::string& label)
			: m_cmdBuf(cmdBuf)
		{
			if (s_enabled)
			{
				VkDebugUtilsLabelEXT s{ VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT, nullptr, label.c_str(), {1.0f, 1.0f, 1.0f, 1.0f} };
				vkCmdBeginDebugUtilsLabelEXT(cmdBuf, &s);
			}
		}
		~ScopedCmdLabel()
		{
			if (s_enabled)
			{
				vkCmdEndDebugUtilsLabelEXT(m_cmdBuf);
			}
		}
		void setLabel(const std::string& label)
		{
			if (s_enabled)
			{
				VkDebugUtilsLabelEXT s{ VK_STRUCTURE_TYPE_DEBUG_UTILS_LABEL_EXT, nullptr, label.c_str(), {1.0f, 1.0f, 1.0f, 1.0f} };
				vkCmdInsertDebugUtilsLabelEXT(m_cmdBuf, &s);
			}
		}

	private:
		VkCommandBuffer m_cmdBuf;
	};

	ScopedCmdLabel scopeLabel(VkCommandBuffer cmdBuf, const std::string& label) { return ScopedCmdLabel(cmdBuf, label); }
	//static bool s_enabled;
private:
	static bool s_enabled;

};


typedef DebugMaster<int> DebugMaster1;
__declspec(selectany) bool DebugMaster1::s_enabled;

#ifndef ENABLED_VULKAN_OPTIX


struct Context0Vk {

	const eContext type = eContext::Prime;
	VkApplicationInfo appInfo = {};
	VkInstance instance;

	DeviceMasterVk<QueueGTVk> device;

	VkSubmitInfo submitInfo;

	VkFormat depthFormat;

	void* deviceCreatepNextChain = nullptr;


	VkDebugReportCallbackEXT debug_report_callback;

	struct Settings {
		bool validation = false;
		/// @brief Set to true if fullscreen mode has been requested via command line 
		bool fullscreen = false;
		/// @brief Set to true if v-sync will be forced for the swapchain 
		bool vsync = false;
		/// @brief Enable UI overlay 
		bool overlay = false;
	} settings;

	struct {
		uint32_t w, h;
	}config;

	DebugMaster1   deb;

	///Context0Vk(uint32_t w, uint32_t h);
	Context0Vk(uint32_t w, uint32_t h) :config({ w,h }) {};
	
	~Context0Vk(){
		log_ctx(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Deconstructor VkContext  \n");
		///shutdown();
	};

	
	void set$();

	bool    initialize();
	bool   shutdown();
	void configuration(std::vector<std::string>& layerExtensions, std::vector<std::string>& instanceExtensions);
	VkResult  createInstance(bool enableValidation);
	void         destroyInstance();
	void         createDebug();

};

#else

struct ContextExVk {

	const eContext type = eContext::External;

	VkInstance           instance;
	VkApplicationInfo appInfo = {};
	DeviceMasterVk<QueueGTVk> device;

	VkSubmitInfo submitInfo;

	VkFormat depthFormat;

	void* deviceCreatepNextChain = nullptr;

	DebugMaster1   deb;
	VkDebugReportCallbackEXT debug_report_callback;

	struct Settings {
		bool validation = false;
		/// @brief Set to true if fullscreen mode has been requested via command line 
		bool fullscreen = false;
		/// @brief Set to true if v-sync will be forced for the swapchain 
		bool vsync = false;
		/// @brief Enable UI overlay 
		bool overlay = false;
	} settings;

	struct {
		uint32_t w, h;
	}config;
	
	// ----------------------------------------------------------------------
	// Construction, initialization, and destruction
	// ----------------------------------------------------------------------

	/**
	* \brief construct ContextExVk.
	* \param w: window width
	* \param h: window height
	*/
	ContextExVk(uint32_t w, uint32_t h) :config({ w,h }) {};
	~ContextExVk() {
		shutdown();
	};


	/**
	* \brief Set Extern Global Variables.
	* 
	* 
	* @emoji :zap: 
	* named by prefix $.
	*/
	void set$();

	bool    initialize();
	bool   shutdown();
	void configuration(std::vector<std::string>& layerExtensions, std::vector<std::string>& instanceExtensions);
	VkResult  createInstance(bool enableValidation);
	void         destroyInstance();
	void         createDebug();

};

#endif



#endif

