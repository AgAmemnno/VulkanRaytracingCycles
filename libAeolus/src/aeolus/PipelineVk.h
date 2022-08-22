#pragma once

#ifndef PIPELINEVK_H
#define PIPELINEVK_H
#include "pch.h"
#include "aeolus/incomplete.h"
#include "materials/common.hpp"



#ifdef  LOG_NO_obj
#define log_pipe(...)
#else
#define log_pipe(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

#define SIZE_PvS   1000


MemExtern(PvSvk, SIZE_PvS);


namespace std
{
	template<> struct hash<PipelineConfigure>
	{
		std::size_t operator()(PipelineConfigure const& s) const noexcept
		{
			static  std::hash<std::string> h_str{};
			static  std::hash<VkPipelineVertexInputStateCreateInfo*>             h_ci{};
			static  std::hash<VkRenderPass>             h_rp{};
			static  std::hash<arth::GEOMETRY>             h_enum{};
			static  std::hash<VkPipelineLayout>             h_pl{};
			
			std::size_t  hash = 0;
			hash += h_str(s.spv);
			hash += hash << 10;
			hash ^= hash >> 6;
			hash += h_ci(s.vkPVISci);
			hash += hash << 10;
			hash ^= hash >> 6;
			hash += h_enum(s.defulettype);
			hash += h_pl(s.vkPL);
			hash += hash << 10;
			hash ^= hash >> 6;
			hash += h_rp(s.vkRP);
			hash += hash << 10;
			hash ^= hash >> 6;

			hash += hash << 3;
			hash ^= hash >> 11;
			hash += hash << 15;
			return hash;
		}
	};
}


struct PipelineVk {

	std::hash<PipelineConfigure> hfunc{};
	std::unordered_map<size_t, types::reference> idx;

	long                            pth;

	PipelineVk();
	~PipelineVk();
	void destroy();
	 
	static VkPipelineShaderStageCreateInfo  loadShader(std::string fileName, VkShaderStageFlagBits stage, PvSvk& p)
	{
		return loadShader(fileName, stage, p.shaderModules);
	};

	static VkPipelineShaderStageCreateInfo  loadShader(std::string fileName, VkShaderStageFlagBits stage, std::vector<VkShaderModule>& shaderModules)
	{
		VkPipelineShaderStageCreateInfo shaderStage = {};
		shaderStage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		shaderStage.stage = stage;

		shaderStage.module = vka::shelve::loadShader(fileName.c_str(), $device);
		shaderStage.pName = "main"; // todo : make param
		shaderModules.push_back(shaderStage.module);
		assert(shaderStage.module != VK_NULL_HANDLE);
		return shaderStage;
	};
	static VkPipelineShaderStageCreateInfo  loadShader(std::string fileName, VkShaderStageFlagBits stage)
	{
		VkPipelineShaderStageCreateInfo shaderStage = {};
		shaderStage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
		shaderStage.stage = stage;

		shaderStage.module = vka::shelve::loadShader(fileName.c_str(), $device);
		shaderStage.pName = "main"; // todo : make param
		assert(shaderStage.module != VK_NULL_HANDLE);
		return shaderStage;
	};

	template<class Ma>
	bool  $createPipelines$(const PipelineConfigure& conf,Ma& mat)
	{

		long orig = InterlockedCompareExchange(&(mat.pipe.id), INT32_MAX, -1);
		if (orig !=  -1) return false;

		PvSvk   p;

		mat.pipe.hash = hfunc(conf);

		Mem(PvSvk,SIZE_PvS).enter();
		if (idx.count(mat.pipe.hash) > 0) {
			mat.pipe.id = idx[mat.pipe.hash].id;
			idx[mat.pipe.hash].cnt++;

			Mem(PvSvk,SIZE_PvS).leave();
			if (mat.pipe.id == -1) {
				log_bad(" insufficinecy of Logic. batting pipeline access. \n ");
				return false;
			};
			if (Mem(PvSvk,SIZE_PvS).get(p, &(mat.pipe))) return true;
			log_warning("circumnavigate the global mem.   capacity is %u ", SIZE_PvS);
		};

		idx[mat.pipe.hash].id = -1;

		{


			/*
			VkPhysicalDeviceProperties2KHR deviceProps2{};
			VkPhysicalDeviceMultiviewPropertiesKHR extProps{};
			extProps.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES_KHR;
			deviceProps2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2_KHR;
			deviceProps2.pNext = &extProps;
			PFN_vkGetPhysicalDeviceProperties2KHR vkGetPhysicalDeviceProperties2KHR = reinterpret_cast<PFN_vkGetPhysicalDeviceProperties2KHR>(vkGetInstanceProcAddr($instance, "vkGetPhysicalDeviceProperties2KHR"));
			vkGetPhysicalDeviceProperties2KHR($physicaldevice, &deviceProps2);
			*/

			VkPipelineInputAssemblyStateCreateInfo inputAssemblyStateCI;
			VkPipelineColorBlendAttachmentState blendAttachmentState = vka::plysm::pipelineColorBlendAttachmentState(0xf, VK_FALSE);

			if (conf.defulettype == arth::GEOMETRY::COMPUTE) {
				inputAssemblyStateCI = vka::plysm::pipelineInputAssemblyStateCreateInfo(VK_PRIMITIVE_TOPOLOGY_POINT_LIST, 0, VK_FALSE);
				blendAttachmentState.colorWriteMask = 0xF;
				blendAttachmentState.blendEnable = VK_TRUE;
				blendAttachmentState.colorBlendOp = VK_BLEND_OP_ADD;
				blendAttachmentState.srcColorBlendFactor = VK_BLEND_FACTOR_ONE;
				blendAttachmentState.dstColorBlendFactor = VK_BLEND_FACTOR_ONE;
				blendAttachmentState.alphaBlendOp = VK_BLEND_OP_ADD;
				blendAttachmentState.srcAlphaBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA;
				blendAttachmentState.dstAlphaBlendFactor = VK_BLEND_FACTOR_DST_ALPHA;
			}
			else {
				inputAssemblyStateCI = vka::plysm::pipelineInputAssemblyStateCreateInfo(VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST, 0, VK_FALSE);
			}


			VkPipelineRasterizationStateCreateInfo rasterizationStateCI = vka::plysm::pipelineRasterizationStateCreateInfo(VK_POLYGON_MODE_FILL, VK_CULL_MODE_BACK_BIT, VK_FRONT_FACE_COUNTER_CLOCKWISE);// VK_FRONT_FACE_CLOCKWISE);
			//VkPipelineRasterizationStateCreateInfo rasterizationStateCI = vka::plysm::pipelineRasterizationStateCreateInfo(VK_POLYGON_MODE_FILL, VK_CULL_MODE_BACK_BIT,  VK_FRONT_FACE_CLOCKWISE);


			VkPipelineColorBlendStateCreateInfo colorBlendStateCI = vka::plysm::pipelineColorBlendStateCreateInfo(1, &blendAttachmentState);
			VkPipelineDepthStencilStateCreateInfo depthStencilStateCI = vka::plysm::pipelineDepthStencilStateCreateInfo(VK_TRUE, VK_TRUE, VK_COMPARE_OP_LESS_OR_EQUAL);// VK_COMPARE_OP_GREATER_OR_EQUAL);// VK_COMPARE_OP_ALWAYS);// 
			VkPipelineViewportStateCreateInfo viewportStateCI = vka::plysm::pipelineViewportStateCreateInfo(1, 1, 0);


			//VkPipelineMultisampleStateCreateInfo multisampleStateCI = vka::plysm::pipelineMultisampleStateCreateInfo(VK_SAMPLE_COUNT_1_BIT);
			VkPipelineMultisampleStateCreateInfo multisampleStateCI{};
			multisampleStateCI.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
			multisampleStateCI.rasterizationSamples = (VkSampleCountFlagBits)conf.multisample;
			multisampleStateCI.minSampleShading = 0.0f;
			uint32_t nSampleMask = 0xFFFFFFFF;
			multisampleStateCI.pSampleMask = &nSampleMask;

			std::vector<VkDynamicState> dynamicStateEnables = { VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };
			VkPipelineDynamicStateCreateInfo dynamicStateCI = vka::plysm::pipelineDynamicStateCreateInfo(dynamicStateEnables);

			VkGraphicsPipelineCreateInfo pipelineCI = vka::plysm::pipelineCreateInfo(conf.vkPL, conf.vkRP);
			pipelineCI.pVertexInputState =  conf.vkPVISci;
			pipelineCI.pInputAssemblyState = &inputAssemblyStateCI;
			pipelineCI.pRasterizationState = &rasterizationStateCI;
			pipelineCI.pColorBlendState = &colorBlendStateCI;
			pipelineCI.pMultisampleState = &multisampleStateCI;
			pipelineCI.pViewportState = &viewportStateCI;
			pipelineCI.pDepthStencilState = &depthStencilStateCI;
			pipelineCI.pDynamicState = &dynamicStateCI;


			///log_mtPass("  SPV      %s    %u  \n", mat->pipeName.c_str(), (UINT32)type);
			///arth::TEST_SHADER Shader = arth::TEST_SHADER::multiview;

			std::array<VkPipelineShaderStageCreateInfo, 2> shaderStages;


			std::string spvName = getAssetPath();
			if (conf.spv == "default"){
				if (conf.defulettype == arth::GEOMETRY::INSTANCED_MUTABLE)  spvName += "mutable/insta/default/insta";
				else if (conf.defulettype == arth::GEOMETRY::BUFFER_MUTABLE)   spvName += "mutable/mt/default/mtBuffer";
				else if (conf.defulettype == arth::GEOMETRY::COMPUTE)                  spvName += "mutable/compute/default/particle2";
				else if (conf.defulettype == arth::GEOMETRY::SPRITE_OVERLAY_MUTABLE) spvName += "mutable/mt/textoverlay/text";
			}else  spvName += conf.spv;


			log_pipe("<<<< Pipeline  Program  spirv     %s   >>>>> \n",spvName.c_str());
			shaderStages[0] = loadShader( spvName  + ".vert.spv", VK_SHADER_STAGE_VERTEX_BIT, p);
			shaderStages[1] = loadShader( spvName   + ".frag.spv", VK_SHADER_STAGE_FRAGMENT_BIT, p);

			pipelineCI.stageCount = 2;
			pipelineCI.pStages = shaderStages.data();
			VK_CHECK_RESULT(vkCreateGraphicsPipelines($device, conf.vkPC, 1, &pipelineCI, nullptr, &(p.pipeline)));
			
		}

		///log_mtPass("pipeline Create  %p   %p      Shader   %s  \n", &pipelines[mat->pipeName], pipelines[mat->pipeName].pipeline, mat->spv.c_str());		
		Mem(PvSvk,SIZE_PvS).idx = (Mem(PvSvk,SIZE_PvS).idx + 1) % Mem(PvSvk,SIZE_PvS).size;
		mat.pipe.id = Mem(PvSvk,SIZE_PvS).idx;
		if (Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx].isValid()) {
			log_bad(" Buffer is not created  for  Over limit  Nums. \n");
			Mem(PvSvk,SIZE_PvS).leave();
			return false;
		};
		Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx] = p;
		//Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx].version = ++mat.pipe.version;
		Mem(PvSvk,SIZE_PvS).owner[mat.pipe.id] = mat.pipe.hash;
		idx[mat.pipe.hash].id = mat.pipe.id;
		idx[mat.pipe.hash].cnt++;

		log_pipe("PvSvk     hash %zu   id %d    \n", mat.pipe.hash, mat.pipe.id);
		Mem(PvSvk,SIZE_PvS).leave();

		return true;
	};

	template<class Ma>
	bool  $createPipelinesOv$(const PipelineConfigure& conf, Ma& mat)
	{
		bool alphaBlend = false;

		long orig = InterlockedCompareExchange(&(mat.pipe.id), INT32_MAX, -1);
		if (orig != -1) return false;

		PvSvk   p;

		mat.pipe.hash = hfunc(conf);

		Mem(PvSvk,SIZE_PvS).enter();
		if (idx.count(mat.pipe.hash) > 0) {
			mat.pipe.id = idx[mat.pipe.hash].id;
			idx[mat.pipe.hash].cnt++;

			Mem(PvSvk,SIZE_PvS).leave();
			if (mat.pipe.id == -1) {
				log_bad(" insufficinecy of Logic. batting pipeline access. \n ");
				return false;
			};

			if (Mem(PvSvk,SIZE_PvS).get(p, &(mat.pipe))) return true;
			log_warning("circumnavigate the global mem.   capacity is %u ", SIZE_PvS);
		};

		idx[mat.pipe.hash].id = -1;

		{
			
			VkPipelineInputAssemblyStateCreateInfo inputAssemblyState = vka::plysm::pipelineInputAssemblyStateCreateInfo(VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP, 0, VK_FALSE);
		    VkPipelineRasterizationStateCreateInfo rasterizationState = vka::plysm::pipelineRasterizationStateCreateInfo(VK_POLYGON_MODE_FILL, VK_CULL_MODE_BACK_BIT, VK_FRONT_FACE_CLOCKWISE, 0);
			VkPipelineColorBlendAttachmentState blendAttachmentState = vka::plysm::pipelineColorBlendAttachmentState(0xf, VK_FALSE);

			if (alphaBlend) {

				rasterizationState.cullMode = VK_CULL_MODE_NONE;
				blendAttachmentState.blendEnable = VK_TRUE;
				blendAttachmentState.colorBlendOp = VK_BLEND_OP_ADD;
				blendAttachmentState.srcColorBlendFactor = VK_BLEND_FACTOR_SRC_COLOR;
				blendAttachmentState.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
			}

			VkPipelineColorBlendStateCreateInfo colorBlendState = vka::plysm::pipelineColorBlendStateCreateInfo(1, &blendAttachmentState);
			VkPipelineDepthStencilStateCreateInfo depthStencilState = vka::plysm::pipelineDepthStencilStateCreateInfo(VK_TRUE, VK_TRUE, VK_COMPARE_OP_LESS_OR_EQUAL);
			VkPipelineViewportStateCreateInfo viewportState = vka::plysm::pipelineViewportStateCreateInfo(1, 1, 0);
			VkPipelineMultisampleStateCreateInfo multisampleState = vka::plysm::pipelineMultisampleStateCreateInfo(VK_SAMPLE_COUNT_1_BIT, 0);
			std::vector<VkDynamicState> dynamicStateEnables = { VK_DYNAMIC_STATE_VIEWPORT, VK_DYNAMIC_STATE_SCISSOR };
			VkPipelineDynamicStateCreateInfo dynamicState = vka::plysm::pipelineDynamicStateCreateInfo(dynamicStateEnables);



		


			VkGraphicsPipelineCreateInfo pipelineCreateInfo = vka::plysm::pipelineCreateInfo(conf.vkPL, conf.vkRP, 0);
			//VkGraphicsPipelineCreateInfo pipelineCreateInfo = vka::plysm::pipelineCreateInfo(pipelineLayout, renderPass, 0);
			pipelineCreateInfo.pVertexInputState = conf.vkPVISci;
			pipelineCreateInfo.pInputAssemblyState = &inputAssemblyState;
			pipelineCreateInfo.pRasterizationState = &rasterizationState;
			pipelineCreateInfo.pColorBlendState = &colorBlendState;
			pipelineCreateInfo.pMultisampleState = &multisampleState;
			pipelineCreateInfo.pViewportState = &viewportState;
			pipelineCreateInfo.pDepthStencilState = &depthStencilState;
			pipelineCreateInfo.pDynamicState = &dynamicState;





			std::array<VkPipelineShaderStageCreateInfo, 2> shaderStages;

			std::string spvName = getAssetPath();
			if (conf.spv == "default") {
				if (conf.defulettype == arth::GEOMETRY::INSTANCED_MUTABLE)  spvName += "mutable/insta/default/insta";
				else if (conf.defulettype == arth::GEOMETRY::BUFFER_MUTABLE)   spvName += "mutable/mt/default/mtBuffer";
				else if (conf.defulettype == arth::GEOMETRY::COMPUTE)                  spvName += "mutable/compute/default/particle2";
				else if (conf.defulettype == arth::GEOMETRY::SPRITE_OVERLAY_MUTABLE) spvName += "mutable/mt/textoverlay/text";
			}
			else  spvName += conf.spv;


			log_pipe("<<<< Pipeline  Program  spirv     %s   >>>>> \n", spvName.c_str());
			shaderStages[0] = loadShader(spvName + ".vert.spv", VK_SHADER_STAGE_VERTEX_BIT, p);
			shaderStages[1] = loadShader(spvName + ".frag.spv", VK_SHADER_STAGE_FRAGMENT_BIT, p);

			pipelineCreateInfo.stageCount = 2;
			pipelineCreateInfo.pStages = shaderStages.data();


			VK_CHECK_RESULT(vkCreateGraphicsPipelines($device, conf.vkPC, 1, &pipelineCreateInfo, nullptr, &(p.pipeline)));

		}

		///log_mtPass("pipeline Create  %p   %p      Shader   %s  \n", &pipelines[mat->pipeName], pipelines[mat->pipeName].pipeline, mat->spv.c_str());		
		Mem(PvSvk,SIZE_PvS).idx = (Mem(PvSvk,SIZE_PvS).idx + 1) % Mem(PvSvk,SIZE_PvS).size;
		mat.pipe.id = Mem(PvSvk,SIZE_PvS).idx;
		if (Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx].isValid()) {
			log_bad(" Buffer is not created  for  Over limit  Nums. \n");
			Mem(PvSvk,SIZE_PvS).leave();
			return false;
		};
		Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx] = p;
		//Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx].version = ++mat.pipe.version;
		Mem(PvSvk,SIZE_PvS).owner[mat.pipe.id] = mat.pipe.hash;
		idx[mat.pipe.hash].id = mat.pipe.id;
		idx[mat.pipe.hash].cnt++;

		log_pipe("PvSvk     hash %zu   id %d    \n", mat.pipe.hash, mat.pipe.id);
		Mem(PvSvk,SIZE_PvS).leave();

		return true;

			/*
			special sp;
			if (mat.names->spz.vert > 0) {
				float f = (float)cvs->w;
				sp.append((arth::SCALAR::B32 | arth::SCALAR::REAL), (char*)&f);
				f = (float)cvs->h;
				sp.append((arth::SCALAR::B32 | arth::SCALAR::REAL), (char*)&f);
				shaderStages[0].pSpecializationInfo = &sp.get();
			}
			*/

	};



	types::reference& isExist(PipelineConfigure& conf) {

		size_t hash = hfunc(conf);
		Mem(PvSvk,SIZE_PvS).enter();
		if (idx.count(hash) > 0) {
			Mem(PvSvk,SIZE_PvS).leave();
			return idx[hash];
		};
		Mem(PvSvk,SIZE_PvS).leave();
		auto ret = types::reference{ .id = -1, .cnt = 0 };
		return ret;;

	};
	bool  get(PvSvk& mem, Hache* pipe) {
		return Mem(PvSvk,SIZE_PvS).get(mem, pipe);
	};
	bool  Set(PvSvk& mem,Hache* pipe){

			Mem(PvSvk,SIZE_PvS).enter();
			Mem(PvSvk,SIZE_PvS).idx = (Mem(PvSvk,SIZE_PvS).idx + 1) % Mem(PvSvk,SIZE_PvS).size;
			if (Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx].isValid()) {
				log_bad(" Buffer is not created  for  Over limit  Nums. \n");
				Mem(PvSvk,SIZE_PvS).leave();
				return false;
			};

			Mem(PvSvk,SIZE_PvS).cache[Mem(PvSvk,SIZE_PvS).idx] = mem;
			Mem(PvSvk,SIZE_PvS).owner[pipe->id]  =  pipe->hash;

			idx[pipe->hash].id = pipe->id;
			idx[pipe->hash].cnt++;
			log_pipe("PvSvk     hash %zu   id %d    \n", pipe->hash, pipe->id);

			Mem(PvSvk,SIZE_PvS).leave();

    };

	template<class Ma>
	bool  $Delete$(Ma& mat)
	{
		Mem(PvSvk,SIZE_PvS).enter();
		if (idx.count(mat.pipe.hash) > 0) {
			idx[mat.pipe.hash].cnt--;
			if (idx[mat.pipe.hash].cnt == 0) {
				MemType(PvSvk, SIZE_PvS)::MemTy&   cache = Mem(PvSvk,SIZE_PvS).cache;
				if (!cache[mat.pipe.id].isValid()) {
					log_bad("you can't delete buffer becouse of being not Valid.\n");
					Mem(PvSvk,SIZE_PvS).leave();
					return false;
				};
				MemType(PvSvk, SIZE_PvS)::OwnTy&    owner = Mem(PvSvk,SIZE_PvS).owner;
				if (owner[mat.pipe.id] != mat.pipe.hash) {
					log_bad("Owner is  exclusive. you are'nt owner.");
					return false;
				};
				cache[mat.pipe.id].dealloc();
				owner[mat.pipe.id] = (uintptr_t)(-1);
				Mem(PvSvk,SIZE_PvS).vacancy.push(mat.pipe.id);
			}
		}
	
		Mem(PvSvk,SIZE_PvS).leave();
		return  true;
	};

};


#endif