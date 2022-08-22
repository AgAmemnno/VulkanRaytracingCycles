#include "pch_mm.h"
#include "types.hpp"
#include "working_mm.h"
#include "aeolus/incomplete.h"


Bache::Bache() :
	id(-1),
	refCnt(0),
	buffer({ -1,0,0}),
	align(0),
	reqAlign(0),
	size(0),
	reqSize(0),
	vacancy(),
	type(""),
	excl({}),
	vkBuffer(VK_NULL_HANDLE),
	mapped(nullptr)
{};

Bache::Bache(
	size_t    hash,
	VkDeviceSize                      align,
	LayoutType   type
) :
	id(-1),
	refCnt(0),
	buffer({-1,0,hash}),
	align(align),
    reqAlign(0),
	size(0),
	reqSize(0),
	vacancy(),
     type(type),
	excl({}),
	vkBuffer(VK_NULL_HANDLE),
	mapped(nullptr)
{};

Bache& Bache::operator=(const Bache& other)
{

	if (&other == this)
		return *this;
	
	this->align = other.align;
	this->buffer.hash = other.buffer.hash;
	this->type = other.type;

	return *this;
};



namespace brunch {

	void createComputePipeline(VkPipeline& pipe, const char* shader, VkPipelineLayout draft, VkPipelineCache cache, VkSpecializationInfo* specializationInfo) {

		VkComputePipelineCreateInfo computePipelineCreateInfo = {
		.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
		.flags = 0,
		.layout = draft,
		};


		VkPipelineShaderStageCreateInfo shaderStage = {};
		shaderStage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		shaderStage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
		shaderStage.module = vka::shelve::loadShader((std::string(COMSHADER_PATH) + std::string(shader) + std::string(".comp.spv")).c_str(), $device);
		shaderStage.pName = "main";
		if (specializationInfo != nullptr)shaderStage.pSpecializationInfo = specializationInfo;
		assert(shaderStage.module != VK_NULL_HANDLE);
		computePipelineCreateInfo.stage = shaderStage;

		VK_CHECK_RESULT(vkCreateComputePipelines($device, cache, 1, &computePipelineCreateInfo, nullptr, &pipe));
		vkDestroyShaderModule($device, shaderStage.module, nullptr);

	};

}


namespace arth {

	std::string INPUT_String(arth::INPUT type) {

#define CaseInputString(in) case in: return  std::string(#in);
		switch (type)
		{
			    CaseInputString(arth::INPUT::vertexPRS)
				CaseInputString(arth::INPUT::vertexPC)
				CaseInputString(arth::INPUT::vertexPUN)
				CaseInputString(arth::INPUT::vertexPV)
				CaseInputString(arth::INPUT::vertexPNC)
				CaseInputString(arth::INPUT::vertexPQS)
				CaseInputString(arth::INPUT::vertexPQS4)
				CaseInputString(arth::INPUT::vertexPN)
				CaseInputString(arth::INPUT::vertexSprite)
		default:
			break;
		};
		return std::to_string(UINT(type)) + "Unknown";
	};

};