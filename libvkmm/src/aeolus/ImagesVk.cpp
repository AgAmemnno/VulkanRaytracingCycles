#include "pch_mm.h"
#include "working_mm.h"




extern front::DeallocatorVk     des;
extern front::oSyncoTank     otank;


void special::append(arth::SCALAR t, char* d) {

	VkSpecializationMapEntry e;
	e.constantID = fieldNum;

	uint32_t s = 1;
	uint32_t v = (uint32_t)t;
	while (s < 9) {
		if ((v >> s) & 1) {
			e.offset = memorySize;
			e.size = s;

			memorySize += s;
			break;
		}
		else  s += 1;
		if (s == 9) {
			log_bad("SCALAR unexpected size. ");
		}
	};

	entry.push_back(e);
	data.resize(memorySize);
	memcpy(data.data() + e.offset, d, e.size);

};

VkSpecializationInfo& special::get() {

	Info = {};
	Info.mapEntryCount = fieldNum;
	Info.pMapEntries = entry.data();
	Info.dataSize = memorySize;
	Info.pData = data.data();
	return  Info;
}

special::special() : Info({}), fieldNum(0), memorySize(0), data({}) { };

special::~special() {};



ImagesVk::ImagesVk( VkCommandPool cmdPool)
	: cmdPool(cmdPool) {};

ImagesVk::ImagesVk() {
	
};



ImagesVk::~ImagesVk() { dealloc(); }

void ImagesVk::dealloc() {

	
};





bool ImagesVk::create2D(MIVSIvk& _, VkFormat format, VkImageUsageFlags  flag, VkMemoryPropertyFlags properties)
{

	VkImageCreateInfo imageInfo{};
	imageInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
	imageInfo.imageType = VK_IMAGE_TYPE_2D;
	imageInfo.format = format;/// VK_FORMAT_R8_UNORM;
	imageInfo.extent.width = _.w;
	imageInfo.extent.height = _.h;
	imageInfo.extent.depth = 1;
	imageInfo.mipLevels      = 1;
	imageInfo.arrayLayers = _.l;
	imageInfo.samples = VK_SAMPLE_COUNT_1_BIT;

	if (properties == 0x1) imageInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
	else imageInfo.tiling = VK_IMAGE_TILING_LINEAR;

	imageInfo.usage = flag;
	imageInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
	imageInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;

	VK_CHECK_RESULT(vkCreateImage($device, &imageInfo, nullptr, &_.image));

	vkGetImageMemoryRequirements($device, _.image, &_.memReqs);

	VkMemoryAllocateInfo allocInfo = vka::plysm::memoryAllocateInfo();
	allocInfo.allocationSize = _.memReqs.size;
	allocInfo.memoryTypeIndex = vka::shelve::getMemoryType(_.memReqs.memoryTypeBits, properties,nullptr);

	VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, nullptr, &_.memory));
	VK_CHECK_RESULT(vkBindImageMemory($device, _.image, _.memory, 0));

	log_img("create2D  format  %u   w  %u  h %u   size %zu   \n", (UINT32)imageInfo.format, _.w, _.h, _.memReqs.size);
	
	_.Info = {};
	_.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;

	if (properties == 0x1) {


		VkImageViewCreateInfo imageViewInfo = vka::plysm::imageViewCreateInfo();
		imageViewInfo.image = _.image;
		imageViewInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
		imageViewInfo.format = imageInfo.format;
		imageViewInfo.components = { VK_COMPONENT_SWIZZLE_R, VK_COMPONENT_SWIZZLE_G, VK_COMPONENT_SWIZZLE_B,	VK_COMPONENT_SWIZZLE_A };
		imageViewInfo.subresourceRange = { VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1 };
		VK_CHECK_RESULT(vkCreateImageView($device, &imageViewInfo, nullptr, &_.view));


		VkSamplerCreateInfo samplerInfo = vka::plysm::samplerCreateInfo();
		samplerInfo.magFilter = VK_FILTER_LINEAR;
		samplerInfo.minFilter = VK_FILTER_LINEAR;
		samplerInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
		samplerInfo.addressModeU = VK_SAMPLER_ADDRESS_MODE_REPEAT;
		samplerInfo.addressModeV = VK_SAMPLER_ADDRESS_MODE_REPEAT;
		samplerInfo.addressModeW = VK_SAMPLER_ADDRESS_MODE_REPEAT;
		samplerInfo.mipLodBias = 0.0f;
		samplerInfo.compareOp = VK_COMPARE_OP_NEVER;
		samplerInfo.minLod = 0.0f;
		samplerInfo.maxLod = 1.0f;
		samplerInfo.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
		VK_CHECK_RESULT(vkCreateSampler($device, &samplerInfo, nullptr, &_.sampler));



		_.Info.sampler = _.sampler;
		_.Info.imageView = _.view;

	}

	return true;
};

bool ImagesVk::create2DArray(MIVSIvk& _, VkFormat format) {
	// Create optimal tiled target image
	VkImageCreateInfo imageCreateInfo = vka::plysm::imageCreateInfo();
	imageCreateInfo.imageType = VK_IMAGE_TYPE_2D;
	imageCreateInfo.format = format;
	imageCreateInfo.mipLevels = 1;
	imageCreateInfo.samples = VK_SAMPLE_COUNT_1_BIT;
	imageCreateInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
	imageCreateInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
	imageCreateInfo.initialLayout =  VK_IMAGE_LAYOUT_UNDEFINED;
	imageCreateInfo.extent = { _.w,_.h, 1 };
	imageCreateInfo.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT;
	imageCreateInfo.arrayLayers = _.l;

	VK_CHECK_RESULT(vkCreateImage($device, &imageCreateInfo, nullptr, &_.image));

	vkGetImageMemoryRequirements($device, _.image, &_.memReqs);

	VkMemoryAllocateInfo allocInfo = vka::plysm::memoryAllocateInfo();
	allocInfo.allocationSize = _.memReqs.size;
	allocInfo.memoryTypeIndex = vka::shelve::getMemoryType(_.memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, nullptr);
	log_img("Bridge Test ==>>   NUMS == 0  generate memory    Size %zu   TypeBits  %u     TypeIndex  %u \n", _.memReqs.size, (uint32_t)_.memReqs.memoryTypeBits, allocInfo.memoryTypeIndex);

	VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, nullptr, &_.memory));
	VK_CHECK_RESULT(vkBindImageMemory($device, _.image, _.memory, 0));


	VkSamplerCreateInfo sampler = vka::plysm::samplerCreateInfo();
	sampler.magFilter = VK_FILTER_LINEAR;
	sampler.minFilter = VK_FILTER_LINEAR;
	sampler.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
	sampler.addressModeU = VK_SAMPLER_ADDRESS_MODE_REPEAT;// VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
	sampler.addressModeV = sampler.addressModeU;
	sampler.addressModeW = sampler.addressModeU;
	sampler.mipLodBias = 0.0f;
	sampler.maxAnisotropy = 8;
	sampler.compareOp = VK_COMPARE_OP_NEVER;
	sampler.minLod = 0.0f;
	sampler.maxLod = 0.0f;
	sampler.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
	VK_CHECK_RESULT(vkCreateSampler($device, &sampler, nullptr, &_.sampler));


	VkImageViewCreateInfo view = vka::plysm::imageViewCreateInfo();
	view.viewType = VK_IMAGE_VIEW_TYPE_2D_ARRAY;
	view.format = format;
	view.components = { VK_COMPONENT_SWIZZLE_R, VK_COMPONENT_SWIZZLE_G, VK_COMPONENT_SWIZZLE_B, VK_COMPONENT_SWIZZLE_A };
	view.subresourceRange = { VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1 };
	view.subresourceRange.layerCount = _.l;
	view.subresourceRange.levelCount = 1;
	view.image = _.image;
	VK_CHECK_RESULT(vkCreateImageView($device, &view, nullptr, &_.view));
	_.Info = {};
	_.Info.sampler = _.sampler;
	_.Info.imageView = _.view;
	_.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
	return true;

};

bool ImagesVk::createCubeMap(MIVSIvk& _, VkFormat format) {

	VkImageCreateInfo imageInfo{};
	imageInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
	imageInfo.imageType = VK_IMAGE_TYPE_2D;
	imageInfo.format = format;/// VK_FORMAT_R8_UNORM;
	imageInfo.extent.width = _.w;
	imageInfo.extent.height = _.h;
	imageInfo.extent.depth = 1;
	imageInfo.mipLevels = _.mipLevel;
	imageInfo.arrayLayers = _.l;
	imageInfo.samples = VK_SAMPLE_COUNT_1_BIT;
	imageInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
	imageInfo.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_SAMPLED_BIT;
	imageInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
	imageInfo.flags = VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT;

	VK_CHECK_RESULT(vkCreateImage($device, &imageInfo, nullptr, &_.image));

	vkGetImageMemoryRequirements($device, _.image, &_.memReqs);


	VkMemoryAllocateInfo allocInfo = vka::plysm::memoryAllocateInfo();
	allocInfo.allocationSize        = _.memReqs.size;
	allocInfo.memoryTypeIndex = vka::shelve::getMemoryType(_.memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, nullptr);

	VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, nullptr, &_.memory));
	VK_CHECK_RESULT(vkBindImageMemory($device, _.image, _.memory, 0));

	log_img("createCubemap  format  %u   w  %u  h %u   size %zu   \n", (UINT32)imageInfo.format, _.w, _.h, _.memReqs.size);

	VkSamplerCreateInfo sampler = vka::plysm::samplerCreateInfo();
	sampler.magFilter = VK_FILTER_LINEAR;
	sampler.minFilter = VK_FILTER_LINEAR;
	sampler.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
	sampler.addressModeU = VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
	sampler.addressModeV = sampler.addressModeU;
	sampler.addressModeW = sampler.addressModeU;
	sampler.mipLodBias = 0.0f;
	sampler.compareOp = VK_COMPARE_OP_NEVER;
	sampler.minLod = 0.0f;
	sampler.maxLod =float( _.mipLevel);
	sampler.borderColor = VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
	sampler.maxAnisotropy = 1.0f;

	if ($features.samplerAnisotropy)
	{
		sampler.maxAnisotropy = $properties.limits.maxSamplerAnisotropy;
		sampler.anisotropyEnable = VK_TRUE;
	}
	VK_CHECK_RESULT(vkCreateSampler($device, &sampler, nullptr, &_.sampler));



	VkImageViewCreateInfo imageViewInfo = vka::plysm::imageViewCreateInfo();
	imageViewInfo.image = _.image;
	imageViewInfo.viewType = VK_IMAGE_VIEW_TYPE_CUBE;
	imageViewInfo.format = imageInfo.format;
	imageViewInfo.components = { VK_COMPONENT_SWIZZLE_R, VK_COMPONENT_SWIZZLE_G, VK_COMPONENT_SWIZZLE_B,	VK_COMPONENT_SWIZZLE_A };
	imageViewInfo.subresourceRange = { VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1 };
	imageViewInfo.subresourceRange.layerCount = _.l;
	// Set number of mip levels
	imageViewInfo.subresourceRange.levelCount = _.mipLevel;
	VK_CHECK_RESULT(vkCreateImageView($device, &imageViewInfo, nullptr, &_.view));


	_.Info = {};
	_.Info.sampler = _.sampler;
	_.Info.imageView = _.view;
	_.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;

	return true;
};


VkPipelineShaderStageCreateInfo  ImagesVk::loadShader(std::string fileName, VkShaderStageFlagBits stage, PvSvk& p)
{
	VkPipelineShaderStageCreateInfo shaderStage = {};
	shaderStage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
	shaderStage.stage = stage;

	shaderStage.module = vka::shelve::loadShader(fileName.c_str(), $device);
	shaderStage.pName = "main"; // todo : make param
	p.shaderModules.push_back(shaderStage.module);
	assert(shaderStage.module != VK_NULL_HANDLE);
	return shaderStage;
};


