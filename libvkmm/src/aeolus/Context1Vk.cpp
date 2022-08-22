#include "pch_mm.h"

#ifdef AEOLUS_EXE
#include "stdafx.h"
#include "Context1Vk.h"
#include "util/log.hpp"
#else


#include "types.hpp"
#include "Context1Vk.h"
#include "ext/extensions_vk.hpp"

#endif


///#include "VkRenderer.hpp"
///#include "VkWindow.h"
///#define LOG_NO_ctx

VkResult fillFilteredNameArray(std::vector < const char*>& used,
	const std::vector<VkExtensionProperties>& properties,
	const std::vector<ExtensionEntry>& requested,
	std::vector<void*>& featureStructs)
{
	for (const auto& itr : requested)
	{
		bool found = false;
		for (const auto& property : properties)
		{
			if (strcmp(itr.name, property.extensionName) == 0 && (itr.version == 0 || itr.version == property.specVersion))
			{
				found = true;
				break;
			}
		}

		if (found)
		{
			used.push_back(itr.name);
			if (itr.pFeatureStruct)
			{
				featureStructs.push_back(itr.pFeatureStruct);
			}
		}
		else if (!itr.optional)
		{
			log_warning("VK_ERROR_EXTENSION_NOT_PRESENT: %s - %d\n", itr.name, itr.version);
			return VK_ERROR_EXTENSION_NOT_PRESENT;
		}
	}

	return VK_SUCCESS;
};

bool QueueGTVk::createInfo(std::vector<VkDeviceQueueCreateInfo>& vkQCI, std::vector<VkQueueFamilyProperties>& vkQFP) {

	///    STCG   15
	///    STC     14
	///    ST       12

	UINT32 qid = 0;
	for (auto& family : vkQFP)
	{
		if (family.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
			family.queueCount -= 8; break;
		}
		qid++;
	}

	index[0] = qid;

	log_ctx(" Qvillage   Graphycs x4   ID[%u]     priority[ 0.5f,0.9f,0.2f,0.8f  ,0.3fx4]  \n", qid);

	VkDeviceQueueCreateInfo queueInfo = {
		   .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
		   .queueFamilyIndex = qid,
		   .queueCount = 8,
		   .pQueuePriorities = priorG
	};

	vkQCI.push_back(queueInfo);

	qid = 0;
	for (auto& family : vkQFP)
	{
		if (family.queueFlags == 12) {
			family.queueCount -= 1; break;
		}
		qid++;
	};

	index[1] = qid;


	log_ctx(" Qvillage   Transfer x1   ID[%u]     priority[ 0.5 ]  \n", qid);


	queueInfo = {
		  .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
		  .queueFamilyIndex = qid,
		  .queueCount = 1,
		  .pQueuePriorities = &priorT[0]
	};

	vkQCI.push_back(queueInfo);






	return true;
};
void QueueGTVk::getQ(VkDevice logical) {

	vkGetDeviceQueue(logical, index[0], 0, &queue);
	vkGetDeviceQueue(logical, index[0], 1, &queueVR);
	vkGetDeviceQueue(logical, index[0], 2, &queueOL);
	vkGetDeviceQueue(logical, index[0], 3, &queueIM);
	vkGetDeviceQueue(logical, index[1], 0, &queueTR);
	for(int i =0;i<4;i++)vkGetDeviceQueue(logical, index[0], i + 4, &queues[i]);
	size = { 8,1 };

	log_ctx(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Qvillage  G0 %x   G1 %x  G2 %x  G3 %x T0  %x <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n", queue,queueVR,queueOL, queueIM,queueTR);

};


const std::string getAssetPath()
{
#if defined(VK_EXAMPLE_DATA_DIR)
	return VK_EXAMPLE_DATA_DIR;
#else
	return "./../data/";
#endif
}

bool GetVulkanInstanceExtensionsRequired(std::vector< std::string >& outInstanceExtensionList)
{
#ifdef  ENABLED_VULKAN_OVR 
	if (!vr::VRCompositor())
	{
		log_bad("Unable to init VR runtime");
		return false;
	}

	outInstanceExtensionList.clear();
	uint32_t nBufferSize = vr::VRCompositor()->GetVulkanInstanceExtensionsRequired(nullptr, 0);
	if (nBufferSize > 0)
	{
		// Allocate memory for the space separated list and query for it
		char* pExtensionStr = new char[nBufferSize];
		pExtensionStr[0] = 0;
		vr::VRCompositor()->GetVulkanInstanceExtensionsRequired(pExtensionStr, nBufferSize);

		// Break up the space separated list into entries on the CUtlStringList
		std::string curExtStr;
		uint32_t    nIndex = 0;
		while (pExtensionStr[nIndex] != 0 && (nIndex < nBufferSize))
		{
			if (pExtensionStr[nIndex] == ' ')
			{
				outInstanceExtensionList.push_back(curExtStr);
				curExtStr.clear();
			}
			else
			{
				curExtStr += pExtensionStr[nIndex];
			}
			nIndex++;
		}
		if (curExtStr.size() > 0)
		{
			outInstanceExtensionList.push_back(curExtStr);
		}

		delete[] pExtensionStr;
	}

	return true;
#else
	return false;
#endif
}


bool ContextVk::initialize() {

	settings.validation = true;
	VkResult err;
	err = createInstance(settings.validation);
	if (err) {
		log_vkabad(err, "Could not create Vulkan instance :  %s  \n");
		return false;
	};

	assert(device.setupPhysicalDevice(instance));
	VK_CHECK_RESULT(device.createLogicalDevice(appInfo))
	
	load_VK_EXTENSION_SUBSET(instance, vkGetInstanceProcAddr, device.logical, vkGetDeviceProcAddr);



	///	VK_CHECK_RESULT(device.createCommandPool());
    device.commandPool = VK_NULL_HANDLE;	return true;

};

void ContextVk::set$() {

	__instance = instance;
	__physicaldevice = device.physical;
	__device = device.logical;
	__queue = device.Qvillage.queue;
	__queueFamilyIndices = device.queueFamilyIndices;
	__format = device.format;
	__properties = device.properties;
	__features = device.features;
	__memoryProperties = device.memoryProperties;
	__format.COLORSPACE = VK_COLOR_SPACE_DISPLAY_P3_LINEAR_EXT;// VK_COLOR_SPACE_DOLBYVISION_EXT;// VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
	__format.COLORFORMAT = VK_FORMAT_R16G16B16A16_SFLOAT; //VK_FORMAT_R8G8B8A8_UNORM;//// VK_FORMAT_B8G8R8A8_UNORM;// VK_FORMAT_B8G8R8A8_SRGB;
	__format.COLORFORMAT = VK_FORMAT_B8G8R8A8_UNORM;  ///VK_FORMAT_R8G8B8A8_UNORM;
	__format.COLORFORMAT_VR = VK_FORMAT_B8G8R8A8_UNORM;;
	$Temperance.init();
};

bool   ContextVk::shutdown() {

	log_ctx("Shutdown VkContext \n");

	device.shutdown();
	destroyInstance();
	return true;
};

void ContextVk::configuration(std::vector<std::string>& layerExtensions,std::vector<std::string>&  instanceExtensions) {
	
#ifdef  ENABLED_VULKAN_DEBUG

	//layerExtensions.push_back("VK_LAYER_LUNARG_monitor");
	layerExtensions.push_back("VK_LAYER_KHRONOS_validation");

	instanceExtensions.push_back(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
	instanceExtensions.push_back(VK_EXT_DEBUG_REPORT_EXTENSION_NAME);

#endif

#ifdef  ENABLED_VULKAN_OVR 
		GetVulkanInstanceExtensionsRequired(instanceExtensions);
#endif

#ifndef ENABLED_VULKAN_HEADLESS
		instanceExtensions.push_back(VK_KHR_SURFACE_EXTENSION_NAME);
#if defined(_WIN32)
		instanceExtensions.push_back(VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
#elif defined(VK_USE_PLATFORM_ANDROID_KHR)
		instanceExtensions.push_back(VK_KHR_ANDROID_SURFACE_EXTENSION_NAME);
#elif defined(_DIRECT2DISPLAY)
		instanceExtensions.push_back(VK_KHR_DISPLAY_EXTENSION_NAME);
#elif defined(VK_USE_PLATFORM_WAYLAND_KHR)
		instanceExtensions.push_back(VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME);
#elif defined(VK_USE_PLATFORM_XCB_KHR)
		instanceExtensions.push_back(VK_KHR_XCB_SURFACE_EXTENSION_NAME);
#elif defined(VK_USE_PLATFORM_IOS_MVK)
		instanceExtensions.push_back(VK_MVK_IOS_SURFACE_EXTENSION_NAME);
#elif defined(VK_USE_PLATFORM_MACOS_MVK)
		instanceExtensions.push_back(VK_MVK_MACOS_SURFACE_EXTENSION_NAME);
#endif

#endif

		if (type == eContext::External) {
			///layerExtensions.push_back("VK_LAYER_LUNARG_monitor");
		}



		instanceExtensions.push_back(VK_KHR_GET_PHYSICAL_DEVICE_PROPERTIES_2_EXTENSION_NAME);
	//	instanceExtensions.push_back(VK_KHR_EXTERNAL_MEMORY_CAPABILITIES_EXTENSION_NAME);
	//	instanceExtensions.push_back(VK_KHR_EXTERNAL_SEMAPHORE_CAPABILITIES_EXTENSION_NAME);
	//	instanceExtensions.push_back(VK_KHR_EXTERNAL_FENCE_CAPABILITIES_EXTENSION_NAME);


}

VkResult   ContextVk::createInstance(bool enableValidation)
{


	settings.validation = true;// enableValidation;
	VkResult res = VK_INCOMPLETE;

#define DELETE_ContextVk_createInstance(Res,...)\
	if( ppEnableInstanceExtensionNames != nullptr)delete[] ppEnableInstanceExtensionNames;\
	if( pExtensionProperties != nullptr)delete[] pExtensionProperties;\
	if( ppEnableLayerExtensionNames != nullptr)delete[] ppEnableLayerExtensionNames;\
if (Res != VK_SUCCESS)\
{ \
	log__bad(__FILE__, __LINE__, LOG_BAD, __VA_ARGS__);\
}\
	return Res;



	appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
	appInfo.pApplicationName = "SingleContext";
	appInfo.pEngineName = "vkThreepy";
	appInfo.apiVersion = VK_API_VERSION_1_2;// VK_API_VERSION_1_2;

	std::vector<std::string> layerExtensions;
	std::vector<std::string> instanceExtensions;

	configuration(layerExtensions , instanceExtensions);


	char** ppEnableLayerExtensionNames = nullptr;
	char** ppEnableInstanceExtensionNames = nullptr;
	VkExtensionProperties* pExtensionProperties = nullptr;

	VkInstanceCreateInfo instanceCreateInfo = {};
	instanceCreateInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
	instanceCreateInfo.pNext = NULL;
	instanceCreateInfo.pApplicationInfo = &appInfo;

	if (instanceExtensions.size() > 0)
	{
		uint32_t nInstanceExtensionCount = 0;
		VkResult res;
		res = vkEnumerateInstanceExtensionProperties(NULL, &nInstanceExtensionCount, NULL);
		if (res != VK_SUCCESS)
		{
			DELETE_ContextVk_createInstance( res, "vkEnumerateInstanceExtensionProperties failed with error %d\n", res);
		}


		ppEnableInstanceExtensionNames = new char* [instanceExtensions.size()];
		int32_t nEnableInstanceExtensionNamesCount = 0;
		pExtensionProperties = new VkExtensionProperties[nInstanceExtensionCount];
		if (nInstanceExtensionCount > 0)
		{
			res = vkEnumerateInstanceExtensionProperties(NULL, &nInstanceExtensionCount, pExtensionProperties);
			if (res != VK_SUCCESS)
			{
				DELETE_ContextVk_createInstance(res, "vkEnumerateInstanceExtensionProperties failed with error %d\n", res);

			}

			for (size_t nExt = 0; nExt < instanceExtensions.size(); nExt++)
			{
				bool bFound = false;
				uint32_t nExtIndex = 0;
				for (nExtIndex = 0; nExtIndex < nInstanceExtensionCount; nExtIndex++)
				{
					if (strcmp(instanceExtensions[nExt].c_str(), pExtensionProperties[nExtIndex].extensionName) == 0)
					{
						bFound = true;

						ppEnableInstanceExtensionNames[nEnableInstanceExtensionNamesCount++] = pExtensionProperties[nExtIndex].extensionName;
						printf("Enabled Extension   {  %s   }  \n", pExtensionProperties[nExtIndex].extensionName);
						break;
					}
				}

				if (!bFound)
				{
					DELETE_ContextVk_createInstance(VK_ERROR_VALIDATION_FAILED_EXT, "Vulkan missing requested extension '%s'.\n", instanceExtensions[nExt].c_str());
				}
			}

			if (nEnableInstanceExtensionNamesCount != instanceExtensions.size())
			{
				DELETE_ContextVk_createInstance(VK_ERROR_VALIDATION_FAILED_EXT, "nEnableInstanceExtensionNamesCount != instanceExtensions.size() ");
			}
		}

		instanceCreateInfo.enabledExtensionCount = nEnableInstanceExtensionNamesCount;
		instanceCreateInfo.ppEnabledExtensionNames = ppEnableInstanceExtensionNames;
	}
	if (layerExtensions.size() > 0) {


			uint32_t instanceLayerCount;
			vkEnumerateInstanceLayerProperties(&instanceLayerCount, nullptr);
			std::vector<VkLayerProperties> instanceLayerProperties(instanceLayerCount);
			vkEnumerateInstanceLayerProperties(&instanceLayerCount, instanceLayerProperties.data());

			ppEnableLayerExtensionNames = new char* [layerExtensions.size()];
			int nEnableCount = 0;

			for (auto Name : layerExtensions) {
				bool exist = false;
				for (VkLayerProperties layer : instanceLayerProperties) {
					if (strcmp(layer.layerName, Name.c_str()) == 0) {
						exist = true;
						ppEnableLayerExtensionNames[nEnableCount++] = layer.layerName;
						printf("Enabled Layer   {  %s   }  \n", layer.layerName);
						break;
					}
				}
		        if(!exist) {
					DELETE_ContextVk_createInstance(VK_ERROR_VALIDATION_FAILED_EXT, "Validation layer  %s   not present, validation is disabled \n", Name.c_str());
			    }
			}

			instanceCreateInfo.ppEnabledLayerNames = ppEnableLayerExtensionNames;
			instanceCreateInfo.enabledLayerCount  = nEnableCount;


		}

	#ifdef VK_ENABLE_DebugPrint
	VkValidationFeatureEnableEXT printenables[] = { VK_VALIDATION_FEATURE_ENABLE_DEBUG_PRINTF_EXT };
	VkValidationFeatureDisableEXT printdisables[] = {
		VK_VALIDATION_FEATURE_DISABLE_THREAD_SAFETY_EXT, VK_VALIDATION_FEATURE_DISABLE_API_PARAMETERS_EXT,
		VK_VALIDATION_FEATURE_DISABLE_OBJECT_LIFETIMES_EXT, VK_VALIDATION_FEATURE_DISABLE_CORE_CHECKS_EXT };
		VkValidationFeaturesEXT features = {};
		features.sType = VK_STRUCTURE_TYPE_VALIDATION_FEATURES_EXT;
		features.enabledValidationFeatureCount = 1;
		features.disabledValidationFeatureCount = 4;
		features.pEnabledValidationFeatures = printenables;
		features.pDisabledValidationFeatures = printdisables;

		features.pNext = instanceCreateInfo.pNext;
		instanceCreateInfo.pNext = &features;
    #endif

	res = vkCreateInstance(&instanceCreateInfo, nullptr, &instance);

#ifdef  ENABLED_VULKAN_DEBUG
		createDebug();
#endif

		DELETE_ContextVk_createInstance(res,"Error Createinstance %d \n",res);

}

VKAPI_ATTR VkBool32 VKAPI_CALL dbgFunc(VkDebugReportFlagsEXT msgFlags, VkDebugReportObjectTypeEXT objType, uint64_t srcObject,
	size_t location, int32_t msgCode, const char* pLayerPrefix, const char* pMsg,
	void* pUserData) {
	std::ostringstream message;

	if (msgFlags & VK_DEBUG_REPORT_ERROR_BIT_EXT) {
		message << "ERROR: ";
	}
	else if (msgFlags & VK_DEBUG_REPORT_WARNING_BIT_EXT) {
		message << "WARNING: ";
	}
	else if (msgFlags & VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT) {
		message << "PERFORMANCE WARNING: ";
	}
	else if (msgFlags & VK_DEBUG_REPORT_INFORMATION_BIT_EXT) {
		message << "INFO: ";
	}
	else if (msgFlags & VK_DEBUG_REPORT_DEBUG_BIT_EXT) {
		message << "DEBUG: ";
	}
	message << "[" << pLayerPrefix << "] Code " << msgCode << " : " << pMsg;

#ifdef _WIN32
	MessageBoxA(NULL, message.str().c_str(), "Alert", MB_OK);
#else
	std::cout << message.str() << std::endl;
#endif

	/*
	 * false indicates that layer should not bail-out of an
	 * API call that had validation failures. This may mean that the
	 * app dies inside the driver due to invalid parameter(s).
	 * That's what would happen without validation layers, so we'll
	 * keep that behavior here.
	 */
	return false;
}


VKAPI_ATTR VkBool32 VKAPI_CALL debugUtilsMessengerCallback(VkDebugUtilsMessageSeverityFlagBitsEXT      messageSeverity,
	VkDebugUtilsMessageTypeFlagsEXT             messageType,
	const VkDebugUtilsMessengerCallbackDataEXT* callbackData,
	void* userData)
{
	DebugMaster1* ctx = reinterpret_cast<DebugMaster1*>(userData);

	if (ctx->dbgIgnoreMessages.find(callbackData->messageIdNumber) != ctx->dbgIgnoreMessages.end()) return VK_FALSE;

	// repeating nvprintfLevel to help with breakpoints : so we can selectively break right after the print
	if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT)
	{
		log_ctx("VERBOSE: %s \n --> %s\n", callbackData->pMessageIdName, callbackData->pMessage);
	}
	else if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT)
	{
		log_ctx("INFO: %s \n --> %s\n", callbackData->pMessageIdName, callbackData->pMessage);
	}
	else if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT)
	{
		log_ctx("WARNING: %s \n --> %s\n", callbackData->pMessageIdName, callbackData->pMessage);
	}
	else if (messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT)
	{
		log_ctx("ERROR: %s \n --> %s\n", callbackData->pMessageIdName, callbackData->pMessage);
	}
	else if (messageType & VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT)
	{
		log_ctx("GENERAL: %s \n --> %s\n", callbackData->pMessageIdName, callbackData->pMessage);
	}
	else
	{
		log_ctx("%s \n --> %s\n", callbackData->pMessageIdName, callbackData->pMessage);
	}

	// this seems redundant with the info already in callbackData->pMessage
#if 0

	if (callbackData->objectCount > 0)
	{
		for (uint32_t object = 0; object < callbackData->objectCount; ++object)
		{
			std::string otype = ObjectTypeToString(callbackData->pObjects[object].objectType);
			LOGI(" Object[%d] - Type %s, Value %p, Name \"%s\"\n", object, otype.c_str(),
				(void*)(callbackData->pObjects[object].objectHandle), callbackData->pObjects[object].pObjectName);
		}
	}
	if (callbackData->cmdBufLabelCount > 0)
	{
		for (uint32_t label = 0; label < callbackData->cmdBufLabelCount; ++label)
		{
			LOGI(" Label[%d] - %s { %f, %f, %f, %f}\n", label, callbackData->pCmdBufLabels[label].pLabelName,
				callbackData->pCmdBufLabels[label].color[0], callbackData->pCmdBufLabels[label].color[1],
				callbackData->pCmdBufLabels[label].color[2], callbackData->pCmdBufLabels[label].color[3]);
		}
#endif
		// Don't bail out, but keep going.
		return VK_FALSE;
	}


static const int MODE = 2;
void    ContextVk::createDebug() {

	if (MODE == 0)
	{
		// The report flags determine what type of messages for the layers will be displayed
		// For validating (debugging) an appplication the error and warning bits should suffice
		//VkDebugReportFlagsEXT debugReportFlags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT | VK_DEBUG_REPORT_INFORMATION_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT;
		// Additional flags include performance info, loader and layer debug messages, etc.
		///vks::debug::setupDebugging(instance, debugReportFlags, VK_NULL_HANDLE);
	}
	else if(MODE == 1){

		PFN_vkCreateDebugReportCallbackEXT dbgCreateDebugReportCallback;



		dbgCreateDebugReportCallback =
			(PFN_vkCreateDebugReportCallbackEXT)vkGetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT");
		if (!dbgCreateDebugReportCallback) {
			std::cout << "GetInstanceProcAddr: Unable to find "
				"vkCreateDebugReportCallbackEXT function."
				<< std::endl;
			exit(1);
		}

		VkDebugReportCallbackCreateInfoEXT create_info = {};
		create_info.sType = VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT;
		create_info.pNext = NULL;
		create_info.flags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT;
		create_info.pfnCallback = dbgFunc;
		create_info.pUserData = NULL;

		VkResult res = dbgCreateDebugReportCallback(instance, &create_info, NULL, &debug_report_callback);

		switch (res) {
		case VK_SUCCESS:
			break;
		case VK_ERROR_OUT_OF_HOST_MEMORY:
			std::cout << "dbgCreateDebugReportCallback: out of host memory\n" << std::endl;
			exit(1);
			break;
		default:
			std::cout << "dbgCreateDebugReportCallback: unknown failure\n" << std::endl;
			exit(1);
			break;
		}
		deb.setEnabled(true);

	}
	else if (MODE == 2) {
		VkResult res;
		VkDebugReportCallbackEXT cb1;
		VkDebugReportCallbackCreateInfoEXT callback1 = {
			VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
			NULL,
			VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT,
			dbgFunc,
			NULL };

		res = ((PFN_vkCreateDebugReportCallbackEXT)vkGetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT"))(instance, &callback1, nullptr, &cb1);
		 if (res != VK_SUCCESS) {
			 log_bad(" Failed to create DebugReport\n ");
		 }
			// Debug reporting system
			// Setup our pointers to the VK_EXT_debug_utils commands
		    deb.dbgIgnoreMessages.clear();
		    deb.createDebugUtilsMessengerEXT =
				(PFN_vkCreateDebugUtilsMessengerEXT)vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
		    deb.destroyDebugUtilsMessengerEXT =
				(PFN_vkDestroyDebugUtilsMessengerEXT)vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
			// Create a Debug Utils Messenger that will trigger our callback for any warning
			// or error.
			if (deb.createDebugUtilsMessengerEXT != nullptr)
			{
				VkDebugUtilsMessengerCreateInfoEXT dbg_messenger_create_info;
				dbg_messenger_create_info.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
				dbg_messenger_create_info.pNext = nullptr;
				dbg_messenger_create_info.flags = 0;
				dbg_messenger_create_info.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT |
					VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
				dbg_messenger_create_info.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT
					| VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
				dbg_messenger_create_info.pfnUserCallback = debugUtilsMessengerCallback;
				dbg_messenger_create_info.pUserData = &deb;
				VK_CHECK_RESULT(deb.createDebugUtilsMessengerEXT(instance, &dbg_messenger_create_info, nullptr, &deb.dbgMessenger));
			
			}
			deb.setEnabled(true);
	
	}
}

void   ContextVk::destroyInstance() {

	if (settings.validation)
	{
		if (MODE == 0) {
			///vks::debug::freeDebugCallback(instance);
		}
		else if (MODE == 1) {

			PFN_vkDestroyDebugReportCallbackEXT dbgDestroyDebugReportCallback = VK_NULL_HANDLE;
			dbgDestroyDebugReportCallback =
				(PFN_vkDestroyDebugReportCallbackEXT)vkGetInstanceProcAddr(instance, "vkDestroyDebugReportCallbackEXT");
			if (!dbgDestroyDebugReportCallback) {
				std::cout << "GetInstanceProcAddr: Unable to find "
					"vkDestroyDebugReportCallbackEXT function."
					<< std::endl;
				exit(1);
			}

			dbgDestroyDebugReportCallback(instance, debug_report_callback, NULL);

		}
		else if (MODE == 2) {
			if (deb.destroyDebugUtilsMessengerEXT)
			{
				// Destroy the Debug Utils Messenger
				deb.destroyDebugUtilsMessengerEXT(instance, deb.dbgMessenger, nullptr);
			}

			deb.createDebugUtilsMessengerEXT = nullptr;
			deb.destroyDebugUtilsMessengerEXT = nullptr;
			deb.dbgIgnoreMessages.clear();
			deb.dbgMessenger = nullptr;

		}
	}
	if (instance) {
	   vkDestroyInstance(instance, nullptr);
    	instance = VK_NULL_HANDLE;
    }
};

