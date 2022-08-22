#include  "pch.h"
#include "types.hpp"
#include "common.h"
#include "core/common.hpp"
#include "working.h"

using namespace aeo;
void  Material2Vk::init() {

	memset(&pipeRoot, 0, sizeof(pipeRoot));
	memset(sh, 0, sizeof(sh));
	configu.multisample = 2;

	InitializeSRWLock(&slim);
	initialState();
	descVk = new DescriptorVk;

};
void  Material2Vk::initialState() {

	configu.vkRP = VK_NULL_HANDLE;

	makeblend = Blend0;


	PSci.Viewport = [](void*) { static auto info = vka::plysm::pipelineViewportStateCreateInfo(1, 1, 0); return &info; };
	/*PSci.ColorBlend = [](void* wcolor) {

		///bool tf = *((bool*)wcolor);
		static VkPipelineColorBlendAttachmentState blendAttachmentState = vka::plysm::pipelineColorBlendAttachmentState(0xf, VK_FALSE);

		static VkPipelineColorBlendStateCreateInfo  Info = {
.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
///.pNext = NULL,
.flags = 0 ,
.logicOpEnable = VK_FALSE,
///.logicOp,
.attachmentCount = 1,
.pAttachments = &blendAttachmentState,
.blendConstants = { 1.f,1.f,1.f,1.f}
		};
		return &Info;
	};*/

	PSci.ColorBlend =  [](void* args) mutable {

		__Blend* flag = (__Blend*)args;

		static VkPipelineColorBlendAttachmentState attach = {
 .blendEnable = VK_TRUE,
 ///.srcColorBlendFactor,
 ///.dstColorBlendFactor,
 .colorBlendOp = flag->blend.advance,
 ///.srcAlphaBlendFactor,
 /// .dstAlphaBlendFactor,
 .alphaBlendOp = flag->blend.advance,
 .colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT
		};
		attach.colorBlendOp = flag->blend.advance;
		attach.alphaBlendOp = flag->blend.advance;
		attach.colorWriteMask = flag->component;

		static VkPipelineColorBlendAdvancedStateCreateInfoEXT adInfo = {
		.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_ADVANCED_STATE_CREATE_INFO_EXT,
		.pNext = NULL,
		.srcPremultiplied = VK_TRUE,
		.dstPremultiplied = VK_TRUE,
		.blendOverlap = flag->blend.overlap
		};

		adInfo.blendOverlap = flag->blend.overlap;


		static VkPipelineColorBlendStateCreateInfo  Info = {
		.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
		.pNext = &adInfo ,
		.flags = 0 ,
		///.logicOpEnable,
		///.logicOp,
		.attachmentCount = 1,
		.pAttachments = &attach,
		.blendConstants = { 1.f,1.f,1.f,1.f}
		};

		Info.pNext = &adInfo;
		Info.pAttachments = &attach;

		memcpy(Info.blendConstants, flag->blendConstants, 4 * 4);

		return &Info;

	};
	PSci.DepthStencil = [](void* null) {
		static VkPipelineDepthStencilStateCreateInfo Info{
			 .sType = VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
			 .depthTestEnable = VK_TRUE,
			 .depthWriteEnable = VK_TRUE,
			 .depthCompareOp = VK_COMPARE_OP_LESS,
			 .depthBoundsTestEnable = VK_FALSE,
			.stencilTestEnable = VK_FALSE,
			.minDepthBounds = 0.0f,
			.maxDepthBounds = 1.0f,
		};
		return &Info;
	};
	PSci.Dynamic = [](void*) {
		static std::vector<VkDynamicState> dynamicStateEnables = { VK_DYNAMIC_STATE_VIEWPORT,VK_DYNAMIC_STATE_SCISSOR ,VK_DYNAMIC_STATE_LINE_WIDTH };
		static auto info = vka::plysm::pipelineDynamicStateCreateInfo(dynamicStateEnables);
		return &info;
	};



	PSci.Multisample = [](void*) {
		static uint32_t nSampleMask = 0xFFFFFFFF;
		uint32_t multisample = 2;
		static VkPipelineMultisampleStateCreateInfo Info{
			.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
			.rasterizationSamples = (VkSampleCountFlagBits)multisample,
			.sampleShadingEnable = VK_FALSE,
			.minSampleShading = 0.0f,
			.pSampleMask = &nSampleMask,
		};
		return &Info;

	};

	PSci.Rasterization = [](void* _conf) mutable {
		Raster* conf = (Raster*)_conf;
		///VkCullModeFlags* cullMode = (VkCullModeFlags*)cull;
		static VkPipelineRasterizationStateCreateInfo Info = vka::plysm::pipelineRasterizationStateCreateInfo(VK_POLYGON_MODE_FILL, VK_CULL_MODE_BACK_BIT, VK_FRONT_FACE_COUNTER_CLOCKWISE, 0);
		Info.depthClampEnable = VK_TRUE;
		Info.depthBiasEnable = VK_FALSE;
		Info.depthBiasConstantFactor = 0.0;
		Info.depthBiasSlopeFactor = 0.0f;
		Info.depthBiasClamp = 0.0f;

		Info.polygonMode = conf->polygonMode;
		Info.cullMode = conf->cullMode;
		Info.frontFace = conf->frontFace;
		Info.lineWidth = conf->lineWidth;

		return &Info;

	};
	PSci.InputAssembly = [](void* top) mutable {
		VkPrimitiveTopology* topology = (VkPrimitiveTopology*)top;
		static  VkPipelineInputAssemblyStateCreateInfo Info = {
		.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
		.flags = 0,
		.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
		.primitiveRestartEnable = VK_FALSE,
		};
		Info.topology = *topology;
		return &Info;
	};


};
void  Material2Vk::loadPng(std::string name) {

	names->imageName = name;
	iach = Iache::rehash(names->imageName, material_com::getStamp());
	iach.format = VK_FORMAT_R8G8B8A8_SRGB;
	iach.layout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
	iach.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;

	ImagesVk*  imgVk = nullptr;
	if (imgVk == nullptr) {
		if (!$tank.takeout(imgVk, 0)) {
			log_bad("tank failed to take out . \n");
		};
	};
	ImmidiateCmd<ImmidiateCmdPool>  imcmVk;
	imgVk->createFromFile(imcmVk, names->imageName, iach);

}
void  Material2Vk::createDraft() {

	VkPushConstantRange pushRange = {};
	if (mode == eConfigu_PIPE::MODE_SELECT || mode == eConfigu_PIPE::MODE_SKY) {
		pushRange = {
			.stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT,
			.offset = 0,
			.size = sizeof(push),
		};
	}
	else if ( mode == eConfigu_PIPE::MODE_FULLSCREEN) {
		pushRange = {
		   .stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT,
		   .offset = 0,
		   .size = sizeof(push2),
		};
	}
	else if (mode == MODE_FULLSCREEN2) {
		
		pushRange = {
			   .stageFlags = VK_SHADER_STAGE_VERTEX_BIT |  VK_SHADER_STAGE_FRAGMENT_BIT,
			   .offset = 0,
			   .size = sizeof(push3),
		};
	}
	else if (mode == MODE_TONEMAPPING) {

		pushRange = {
			   .stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT,
			   .offset = 0,
			   .size = sizeof(push4),
		};
	}
	else if (mode == MODE_TONEMAPPING2) {

		pushRange = {
			   .stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT,
			   .offset = 0,
			   .size = sizeof(push4) +sizeof(push5),
		};
	}

	descVk->createDraft({ pushRange });
};
long  Material2Vk::Counting() {
	return  InterlockedAdd(&cache.refCnt, 1) - 1;
};
long  Material2Vk::Allocate() {

	static VisibleObjectsVk* vobjVk = nullptr;
	if (vobjVk == nullptr) {
		if (!$tank.takeout(vobjVk, 0)) {
			log_bad(" not found  VisibleUniformObjectsVk.");
		};
	};

	const VkDeviceSize                 maxChunk = 512 * 1024 * 1024;
	VkPhysicalDeviceProperties properties;

	vkGetPhysicalDeviceProperties($physicaldevice, &properties);
	VkPhysicalDeviceLimits& limits = properties.limits;
	VkDeviceSize _alignment = limits.minUniformBufferOffsetAlignment;   //, limits.minStorageBufferOffsetAlignment);
	VkDeviceSize multiple = 1;

	while (true)
	{
		if(    desc.align <  (_alignment*multiple) )
		{
			break;
		}
		multiple++;
	};

	
	const VkDeviceSize structMax = VkDeviceSize(cache.refCnt) * desc.align;


	cache.alignment   = multiple * _alignment;
	cache.MaxSize    = __min(structMax, maxChunk);


	uniform.swID = 0;
	uniform.createUBO(vobjVk, cache.alignment * cache.refCnt);
	uniform.ubo.info.range = cache.alignment;

	return  0;

};
bool  Material2Vk::arangeLayoutSet() {


	if (mode == MODE_FULLSCREEN)return true;

	bool draft = (descVk->layoutSet.size() == 0);
	std::vector<VkDescriptorSetLayoutBinding > Set(1);

	if (   (mode == MODE_FULLSCREEN2) |
		    (mode == MODE_TONEMAPPING) ){

		Set[0] = {
				 .binding = 0,
				.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
				.descriptorCount = 1,
				.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT,
				.pImmutableSamplers = NULL
		};
		assert(0 == uniform.createSet(descVk, "CombFrag", Set, draft));
		return true;
	}
	else if (mode == MODE_TONEMAPPING2){

	Set[0] = {
			 .binding = 0,
			.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
			.descriptorCount = 1,
			.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT,
			.pImmutableSamplers = NULL
	};
	assert(0 == uniform.createSet(descVk, "Ssbo", Set, draft));
	return true;
	}

	Set[0] = {
.binding = 0,
.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
.descriptorCount = 1,
.stageFlags = VK_SHADER_STAGE_VERTEX_BIT ,
.pImmutableSamplers = NULL
	};

	assert(0 == uniform.createSet(descVk, "GLOBAL", Set, draft));

	Set[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC;
	Set[0].stageFlags = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT;
	if (mode == MODE_SKY) {
		Set.push_back( {
				.binding = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
				.descriptorCount = 1,
				.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT ,
				.pImmutableSamplers = NULL
		});
	}

	
	assert(1 == uniform.createSet(descVk, "OBJECT", Set, draft));

	desc.hash = hashLB(desc);

	return true;

};
void  Material2Vk::writeout(VkDescriptorBufferInfo camera) {



	if (mode == MODE_FULLSCREEN)return;

	static std::vector<VkWriteDescriptorSet> write;
	static VkDescriptorImageInfo info;
	auto Set = uniform.descriptorSets[0]; 


	if ( (mode == MODE_TONEMAPPING) | (mode == MODE_FULLSCREEN2) ){
	
		material_com::getInfo(iach, info);
		write.push_back({
		   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		   .dstSet = Set[0],
		   .dstBinding = 0,
		   .dstArrayElement = 0,
		   .descriptorCount = 1,
		   .descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
		   .pImageInfo = &info
			});
	
	}
	else {

		write.resize(2);


		write[0] = {
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = Set[0],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
				.pBufferInfo = &camera,
		};

		write[1] = {
				.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
				.dstSet = Set[1],
				.dstBinding = 0,
				.dstArrayElement = 0,
				.descriptorCount = 1,
				.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
				.pBufferInfo = &uniform.ubo.info
		};

		if (mode == MODE_SKY) {

			material_com::getInfo(iach, info);
			write.push_back({
			   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
			   .dstSet = Set[1],
			   .dstBinding = 1,
			   .dstArrayElement = 0,
			   .descriptorCount = 1,
			   .descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
			   .pImageInfo = &info
				});

		}
	}

	vkUpdateDescriptorSets($device, static_cast<uint32_t>(write.size()), write.data(), 0, nullptr);

};
std::vector<VkPipelineShaderStageCreateInfo>& Material2Vk::setShaderState(eConfigu_PIPE   mode) {
	

	if (!load_shader) {

		std::string spv;
		VkShaderModule* shaders = sh;
		uint32_t stages = 2;

		std::vector<eConfigu_PIPE>  pipes;
		pipes = {
			mode
		};

		for (auto type : pipes) {
			
			if ( (type ==  MODE_SKY || type == eConfigu_PIPE::MODE_SELECT) && sh[0] == VK_NULL_HANDLE) { shaders = sh; spv = getAssetPath() +  names->spv; }
			if ( (type == eConfigu_PIPE::MODE_FULLSCREEN) && sh[0] == VK_NULL_HANDLE) { shaders = sh; spv = getAssetPath() + "fullscreen//prg" ; }
			if ((type == eConfigu_PIPE::MODE_FULLSCREEN2) && sh[0] == VK_NULL_HANDLE) { shaders = sh; spv = getAssetPath() + "fullscreen//prg3"; }
			if ((type == eConfigu_PIPE::MODE_TONEMAPPING) && sh[0] == VK_NULL_HANDLE) { shaders = sh; spv = getAssetPath() + "fullscreen//tonemapping"; }
			if ((type == eConfigu_PIPE::MODE_TONEMAPPING2) && sh[0] == VK_NULL_HANDLE) { shaders = sh; spv = getAssetPath() + "fullscreen//prg4"; }

			int j = 0;
			shaders[j++] = PipelineVk::loadShader(spv + ".vert.spv", VK_SHADER_STAGE_VERTEX_BIT).module;
			if (stages == 3)shaders[j++] = PipelineVk::loadShader(spv + ".geom.spv", VK_SHADER_STAGE_GEOMETRY_BIT).module;
			if (stages == 4)shaders[j++] = PipelineVk::loadShader(spv + ".tesc.spv", VK_SHADER_STAGE_TESSELLATION_CONTROL_BIT).module;
			if (stages == 4)shaders[j++] = PipelineVk::loadShader(spv + ".tese.spv", VK_SHADER_STAGE_TESSELLATION_EVALUATION_BIT).module;
			shaders[j++] = PipelineVk::loadShader(spv + ".frag.spv", VK_SHADER_STAGE_FRAGMENT_BIT).module;
		};

		load_shader = true;
	}

	static std::vector<VkPipelineShaderStageCreateInfo>  shaderStages;

	switch (mode)
	{
	case MODE_SKY:
	case MODE_SELECT:
	case MODE_FULLSCREEN:
	case MODE_FULLSCREEN2:
	case MODE_TONEMAPPING:
	case MODE_TONEMAPPING2:
		shaderStages.resize(2);

		shaderStages[0].stage      = VK_SHADER_STAGE_VERTEX_BIT;
		shaderStages[0].module    = sh[0];
		shaderStages[1].stage      = VK_SHADER_STAGE_FRAGMENT_BIT;
		shaderStages[1].module    = sh[1];
		break;
     
	};

	for (auto& v : shaderStages) {
		v.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		v.pName = "main";
	};

	return shaderStages;

};
void Material2Vk::setCommonInformation(VkGraphicsPipelineCreateInfo& pipelineCreateInfo) {

	pipelineCreateInfo = {
		.sType          = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
		.layout         = configu.vkPL,
		.renderPass = configu.vkRP
	};

	pipelineCreateInfo.pVertexInputState = configu.vkPVISci;
	
	if ( (mode == eConfigu_PIPE::MODE_FULLSCREEN)
		| (mode == eConfigu_PIPE::MODE_FULLSCREEN2)
		| (mode == eConfigu_PIPE::MODE_TONEMAPPING)
		) {
		static VkPipelineMultisampleStateCreateInfo multisampleStateCI = vka::plysm::pipelineMultisampleStateCreateInfo(VK_SAMPLE_COUNT_1_BIT);
		pipelineCreateInfo.pMultisampleState = &multisampleStateCI;
	}
	else {
		pipelineCreateInfo.pMultisampleState = PSci.Multisample(nullptr);
	}


	pipelineCreateInfo.pViewportState = PSci.Viewport(nullptr);
	pipelineCreateInfo.pDynamicState = PSci.Dynamic(nullptr);
	//pipelineCreateInfo.pColorBlendState = PSci.ColorBlend(nullptr);
	pipelineCreateInfo.pDepthStencilState = PSci.DepthStencil(nullptr);
	log_mat("create GPci   %x     ", pipelineCreateInfo);

};
void  Material2Vk::dealloc() {

	for (auto& shaderModule : sh)
	{
		if (shaderModule != VK_NULL_HANDLE) {
			vkDestroyShaderModule($device, shaderModule, nullptr);
			shaderModule = VK_NULL_HANDLE;
		}
	};
	for (int i = 0; i < info::MAX_BLEND_OP; i++) {
		for (int j = 0; j < info::MAX_OVERLAP_OP; j++) {
			for (auto& p : pipeRoot[i][j].Next) {
				vkDestroyPipeline($device, p.pipe, nullptr);
				p.pipe = VK_NULL_HANDLE;
			};
		};
	};


	__Delete__(descVk);

};
bool Material2Vk::get(VkPipeline*& pipeline, eConfigu_PIPE   prg, __Blend& flag) {

	pipeline = &pipeRoot[info::getVkBlendOpNum(flag.blend.advance)][(UINT)flag.blend.overlap].Next[(UINT)prg].pipe;
	if (*pipeline == VK_NULL_HANDLE) {
		if(configu.vkRP == VK_NULL_HANDLE)return false;
		return createPipeline(prg, configu, flag);
	}
	return true;

};
bool Material2Vk::bind(VkCommandBuffer cmd, eConfigu_PIPE type) {

	VkPipeline* pipe;
	if (get(pipe, type)) {
		vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, *pipe);
	}
	else log_bad(" there is no valid pipeline. type %u  \n", (UINT)type);

	return true;

}
bool Material2Vk::createPipeline(PipelineConfigure& config) {
	return createPipeline(mode,config);
};
bool Material2Vk::createPipeline(eConfigu_PIPE _type, PipelineConfigure& config, __Blend& blend) {


	float supersample = 64.f;
	configu.vkPL = descVk->draft;
	configu.vkRP = config.vkRP;
	configu.vkPVISci = config.vkPVISci;
	configu.vkPC = config.vkPC;
	
	Material2Vk::Raster                    rsterFill = {
			.polygonMode = VK_POLYGON_MODE_FILL,
			.cullMode = VK_CULL_MODE_NONE,// VK_CULL_MODE_BACK_BIT,
			.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE,
	};

	Material2Vk::Raster                    rsterLine = {
			.polygonMode = VK_POLYGON_MODE_LINE,//VK_POLYGON_MODE_FILL,
			.cullMode = VK_CULL_MODE_BACK_BIT,
			.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE,
			.lineWidth  = supersample
	};

	VkGraphicsPipelineCreateInfo        pipelineCreateInfo = {
		.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
	};

	switch (mode)
	{
	case Material2Vk::MODE_SKY:
	case Material2Vk::MODE_SELECT:
		$createExclusive(mode,  blend,
			VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
			rsterFill,
			pipelineCreateInfo);
		break;

	case Material2Vk::MODE_FULLSCREEN:
		$createExclusive(mode, blend,
			VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP,
			rsterFill,
			pipelineCreateInfo);
		break;

	case Material2Vk::MODE_FULLSCREEN2:
	case Material2Vk::MODE_TONEMAPPING:
	case Material2Vk::MODE_TONEMAPPING2:
		$createExclusive(mode, blend,
			VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
			rsterFill,
			pipelineCreateInfo);
		break;
	};

	return true;
};
bool Material2Vk::$createExclusive(eConfigu_PIPE type, __Blend& blend,
	VkPrimitiveTopology topology,
	Raster& raster,
	VkGraphicsPipelineCreateInfo& pipelineCreateInfo
) {

	bool release = false;
	if (!scopedLock) {
		AcquireSRWLockExclusive(&slim);
		release = scopedLock = true;
	}

	VkPipeline* pipe = &pipeRoot[info::getVkBlendOpNum(blend.blend.advance)][(UINT)blend.blend.overlap].Next[(UINT)type].pipe;
	if (*pipe != VK_NULL_HANDLE) {
		if (release) {
			scopedLock = false;
			ReleaseSRWLockExclusive(&slim);
		}
		return true;
	}


	setCommonInformation(pipelineCreateInfo);
	auto& shader = setShaderState(type);

	pipelineCreateInfo.pColorBlendState = PSci.ColorBlend(&blend);
	if ( (type == eConfigu_PIPE::MODE_FULLSCREEN) | 
		  (type == eConfigu_PIPE::MODE_FULLSCREEN2) | 
		(type == eConfigu_PIPE::MODE_TONEMAPPING) |
		(type == eConfigu_PIPE::MODE_TONEMAPPING2)
		) {
		static VkPipelineVertexInputStateCreateInfo vinfo;
		vinfo = {
		   .sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
		   .vertexBindingDescriptionCount = 0,
		   .vertexAttributeDescriptionCount = 0,
		};
		pipelineCreateInfo.pVertexInputState = &vinfo;
	}
	else {
		pipelineCreateInfo.pVertexInputState = configu.vkPVISci;
	}
	pipelineCreateInfo.pStages = shader.data();
	pipelineCreateInfo.stageCount = (uint32_t)shader.size();
	pipelineCreateInfo.pInputAssemblyState = PSci.InputAssembly(&topology);
	pipelineCreateInfo.pRasterizationState = PSci.Rasterization(&raster);

	VK_CHECK_RESULT(vkCreateGraphicsPipelines($device, configu.vkPC, 1, &pipelineCreateInfo, nullptr, pipe));
	//VK_CHECK_RESULT(vkCreateGraphicsPipelines($device, VK_NULL_HANDLE, 1, &pipelineCreateInfo, nullptr, pipe));
	pipeRoot[info::getVkBlendOpNum(blend.blend.advance)][(UINT)blend.blend.overlap].Next[(UINT)type].pipe = *pipe;
	printf("Create Pipeline    %llx    %s     \n ",(long long)( *pipe ), info::String_VkBlendOp(blend.blend.advance));

	if (release) {
		release = scopedLock = false;
		ReleaseSRWLockExclusive(&slim);
	}

	return true;
};
bool Material2Vk::make(VkCommandBuffer cmd, VkSemaphore sema) {

	if (mode == eConfigu_PIPE::MODE_FULLSCREEN) make_fullscreen(cmd);
	if( (mode == eConfigu_PIPE::MODE_FULLSCREEN2) |
		(mode == eConfigu_PIPE::MODE_TONEMAPPING)|
		(mode == eConfigu_PIPE::MODE_TONEMAPPING2))make_tonemapping(cmd);

	return true;

}
bool Material2Vk::make_fullscreen(VkCommandBuffer cmd) {

	VkPipeline* pipe = nullptr;
	if (!(get(pipe, mode, makeblend))) log_bad("Not Found  Pipeline Instances  \n");

	VkPipelineLayout draft = descVk->draft;
	VkShaderStageFlags pushStage = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT;


	vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, *pipe);

		///align = (UINT)(obj->draw.pid * cache.alignment);
		///obj->draw.mapped = (void*)((char*)uniform.ubo.mapped + align);
		for (int i = 0; i < 3; i++)push2.color[i] = 0.5f;
		vkCmdPushConstants(
			cmd,
			draft,
			pushStage,
			0,
			sizeof(push2),
			&push2);
		vkCmdDraw(cmd, 4, 1, 0, 0);
		
	return true;
}
bool Material2Vk::make_tonemapping(VkCommandBuffer cmd) {

	VkPipeline* pipe = nullptr;
	if (!(get(pipe, mode, makeblend))) log_bad("Not Found  Pipeline Instances  \n");

	VkPipelineLayout         draft = descVk->draft;
	VkShaderStageFlags  pushStage = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT;

	vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, *pipe);

	vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, draft, 0, 1, &uniform.descriptorSets[0][0], 0, 0);
	size_t psize = 0;
	void* pptr = nullptr;
	if (mode == eConfigu_PIPE::MODE_FULLSCREEN2) {
		psize = sizeof(push3);
		pptr = &push3;

	}
	else if (mode == eConfigu_PIPE::MODE_TONEMAPPING || mode == eConfigu_PIPE::MODE_TONEMAPPING2) {
		psize = sizeof(push4);
		pptr = (void*)&push4;
	}


	vkCmdPushConstants(
		cmd,
		draft,
		pushStage,
		0,
		psize,
		pptr);

	if (mode == eConfigu_PIPE::MODE_TONEMAPPING2) {
		vkCmdPushConstants(
			cmd,
			draft,
			pushStage,
			sizeof(push4),
			sizeof(push5),
			(void*)&push5);
	};

	vkCmdDraw(cmd, 3, 1, 0, 0);

	return true;

}
bool Material2Vk::make(VkCommandBuffer cmd, const std::vector<Object3D*>& child,uint32_t drawcount) {

	VkPipeline* pipe = nullptr;
	uint32_t align = (uint32_t)desc.align;

	if (!(get(pipe, mode, makeblend))) log_bad("Not Found  Pipeline Instances  \n");

	VkPipelineLayout draft = descVk->draft;
	VkShaderStageFlags pushStage = VK_SHADER_STAGE_VERTEX_BIT | VK_SHADER_STAGE_FRAGMENT_BIT;

	vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, draft, 0, 1, &uniform.descriptorSets[0][0], 0, 0);

	vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, *pipe);
	printf("Bind  Pipeline %llx \n", (long long)*pipe);
	for (auto& obj : child) {

		align = (UINT)(obj->draw.pid * cache.alignment);
		obj->draw.mapped = (void*)((char*)uniform.ubo.mapped + align);
		for (int i = 0; i < 3;i++)push.color[i] = obj->color->v[i];
		vkCmdPushConstants(
			cmd,
			draft,
			pushStage,
			0,
			sizeof(push),
			&push);


		vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, draft, 1, 1, &uniform.descriptorSets[0][1], 1, &(align));
		vkCmdDrawIndexed(cmd, drawcount, 1, 0, 0, 0);
		///printf("Bind Descriptor pid   %u    offset  %u   Align %u  \n", (UINT)obj->draw.pid, align, (UINT)cache.alignment);
		//vkCmdDrawIndexedIndirect(cmd, master->cache.cmd2.vkBuffer, 0, master->SubGroup, sizeof(VkDrawIndexedIndirectCommand));
	};

	return true;
};

