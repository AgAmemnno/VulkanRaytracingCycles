#pragma once

#ifndef SCRIPTOR_H
#define SCRIPTOR_H

#include  "types.hpp"
#include  "working_mm.h"
#ifdef  LOG_NO_scr
#define log_scr(...)
#else
#define log_scr(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

#define DESC_MAX  300000


struct _PoolSize {
	uint32_t   size;
	uint32_t  ssbo;
	uint32_t   ubo;
	uint32_t   tex;
};




struct vkDSL
{

	LayoutType                                         type = "";
	VkDescriptorSetLayout                      layout;

};



struct vkDSLMem {

	///vkDSL                                                 Layout[types::SIZE_LAYOUT];
	///std::unordered_map<const char*, VkDescriptorSetLayout>           Layout;
	std::unordered_map<std::string, VkDescriptorSetLayout>           Layout;

	SRWLOCK                                                       SlimLock;
	vkDSLMem() { InitializeSRWLock(&SlimLock); }

	void destroy();

	bool get(VkDescriptorSetLayout& layout, LayoutType Lty);

	bool $set$(LayoutType type, std::vector<VkDescriptorSetLayoutBinding>&);


};

extern  vkDSLMem DSL;
#define $DSL  DSL

///#include <set>

struct DescriptorVk {

	protected:
	public:

		struct ioSP {
			VkDescriptorPool        Pool;
			VkDescriptorSet         Set;
		};

		typedef std::tuple<LayoutType, ioSP>  ioType;
		VkPipelineLayout                                                                               draft;
		std::vector<ioSP>                                                                                    io;
		///std::unordered_set<layoutType>                                                  layoutSet;
		std::vector<VkDescriptorSetLayout>                                           layoutSet;


		struct {
			long        Layout;
			long             Set;
		}Nums  = { 0,0 };

		_PoolSize PoolSize = { 0,0 };

		DescriptorVk();
		~DescriptorVk();

		/*
		template<class De>
		void  $createLayout$(De& desc) {
			VkDescriptorSetLayout  layout;
			layoutType type = desc.type;
			std::vector<VkDescriptorSetLayoutBinding> _ = {};
			if ($DSL.$set$(type, _)) {
				$DSL.get(layout, type);
				layoutSet.push_back(layout);
			};
			///for (auto& v : layoutSet) if (v == layout)return;

		};
		*/

		bool $createLayout$(LayoutType type) {
			std::vector<VkDescriptorSetLayoutBinding> _ = {};
			if ($DSL.$set$(type, _)) {
				VkDescriptorSetLayout  layout;
				$DSL.get(layout, type);
				layoutSet.push_back(layout);
			}
			else {
				log_bad("Failed to create DSL.  \n");
			}
			return true;
		};

		size_t  $createLayout$(LayoutType type, std::vector<VkDescriptorSetLayoutBinding>& dslb) {
			
			VkDescriptorSetLayout  layout;


			if ($DSL.$set$(type, dslb)) {
				$DSL.get(layout, type);
				layoutSet.push_back(layout);
				return layoutSet.size() - 1;
			};
			///for (auto& v : layoutSet) if (v == layout)return;
			return -1;
		};


		///template<Interface_desc Ma>
		template<class De>
		bool $createPuddle$(De& desc) {

			long orig = InterlockedCompareExchange(&(desc.hach.id), INT32_MAX, -1);
			if (orig != -1) return false;
			LayoutType type =desc.type;

			///log_scr("LOCK_OPERATOR CreatePuddle      %s  \n ", type.data());
			VkDescriptorSetLayout  layout;
		
			std::vector<VkDescriptorSetLayoutBinding> _ = {};
			if ($DSL.$set$(type, _)) {
				desc.hach.id = io.size();
				if (desc.hach.id >= DESC_MAX) {
					log_bad("Create Layout  OVER Limit. \n");
				};
				$DSL.get(layout, type);
				///appendLayoutSet(layout);
			}
			else {
				log_bad("Failed to create DSL.  \n");
			}
			
			
			VkDescriptorSetAllocateInfo  allocInfo{};
			allocInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
			allocInfo.descriptorSetCount = 1;
			allocInfo.pSetLayouts = &layout;

			std::vector<VkDescriptorPoolSize> poolSizes;
			poolSizes.clear();
			size_t     size = type.size();
			for (int i = 0; i < size; i++) {
				if (type[i] == 's') {
					poolSizes.push_back(vka::plysm::descriptorPoolSize(VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, 1));
				}
				else if (type[i] == 'u') {
					poolSizes.push_back(vka::plysm::descriptorPoolSize(VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1));
				}
				else if (type[i] == 't') {
					poolSizes.push_back(vka::plysm::descriptorPoolSize(VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1));
				}
				else {
					log_bad("Descriptor_CreateIO::ParseError  \n");
				};
			};

			VkDescriptorPoolCreateInfo descriptorPoolInfo{};
			descriptorPoolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
			descriptorPoolInfo.poolSizeCount = static_cast<uint32_t>(poolSizes.size());
			descriptorPoolInfo.pPoolSizes = poolSizes.data();
			descriptorPoolInfo.maxSets = 1;


			ioSP puddle = {};
			VK_CHECK_RESULT(vkCreateDescriptorPool($device, &descriptorPoolInfo, nullptr, &puddle.Pool));
			allocInfo.descriptorPool = puddle.Pool;
			VK_CHECK_RESULT(vkAllocateDescriptorSets($device, &allocInfo, &puddle.Set));
			io.push_back(puddle);

			return true;

		};

		template<class De>
		bool $createPuddle$(De& desc, std::vector<VkDescriptorSetLayoutBinding>& dslb) {

			long orig = InterlockedCompareExchange(&(desc.hach.id), INT32_MAX, -1);
			if (orig != -1) return false;
			LayoutType type = desc.type;
			

			std::vector<VkDescriptorPoolSize> poolSizes;
			for (auto& v : dslb) poolSizes.push_back(vka::plysm::descriptorPoolSize(v.descriptorType, 1));

			VkDescriptorSetLayout  layout = VK_NULL_HANDLE;

			if ($DSL.$set$(type, dslb)) {
				$DSL.get(layout, type);
				desc.hach.id = io.size();
				//appendLayoutSet(layout);
				if (desc.hach.id >= DESC_MAX) {
					log_bad("Create Layout  OVER Limit. \n");
				};
			}
			else {
				log_bad("Failed to create DSL.  \n");
			}

			VkDescriptorSetAllocateInfo  allocInfo{};
			allocInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
			allocInfo.descriptorSetCount = 1;
			allocInfo.pSetLayouts = &layout;

			VkDescriptorPoolCreateInfo descriptorPoolInfo{};
			descriptorPoolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
			descriptorPoolInfo.poolSizeCount = static_cast<uint32_t>(poolSizes.size());
			descriptorPoolInfo.pPoolSizes = poolSizes.data();
			descriptorPoolInfo.maxSets = 1;


			ioSP puddle = {};
			VK_CHECK_RESULT(vkCreateDescriptorPool($device, &descriptorPoolInfo, nullptr, &puddle.Pool));
			allocInfo.descriptorPool = puddle.Pool;
			VK_CHECK_RESULT(vkAllocateDescriptorSets($device, &allocInfo, &puddle.Set));
			io.push_back(puddle);

			return true;

		};

		///template<Interface_desc Ma>
		template<class Ma>
		void destroyPuddle(Ma& mat) {
			ioSP& sp = io[&mat].Pool;
			if (sp.Pool != VK_NULL_HANDLE) {
				vkDestroyDescriptorPool($device, sp.Pool, nullptr);
				sp.Pool == VK_NULL_HANDLE;
				mat.active.desc = -1;
			};
		};


		VkDescriptorSet& getSet(long id) {
			return io[id].Set;
		};

		void createDraft(std::vector<VkPushConstantRange> pushConstantRange = {});
		void destroy();


		//
		//template<class I>

		/*
		template<Interface_desc I>
		bool  registerIO(I* inter) {

			//input   material  Id    out   layoutId 
			//input   UniformVk Id  out  layoutId
			//input  Object3dUniform Id  out  Layout

 
			///if (io.count((uintptr_t)inter) > 0)return true;

			if (inter->id > -1)return true;

			if (factoryIO(inter->type)) {

				inter->id = io.size();
				io[inter->id] = ioType{ inter->type , {} };
 

				return true;
			};

			log_bad("DescriptorManager:: factoryIO failed to create  with this type [ %s ].\n", inter->type.data());
			return false;

		};


		template<Interface_desc I>
		bool factoryDescriptor(I* inter, VkWriteDescriptorSet* WriteOut) {

			static  VkDescriptorType  DType[3] = { VK_DESCRIPTOR_TYPE_STORAGE_BUFFER ,VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER ,VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER };

			if (io.count(inter) <= 0) return false;

			auto& t = io[inter];

			layoutType type = Tuple(t, 0);
			size_t  size = type.size();

			if (WriteOut[0].dstSet == Tuple(t, 1).Set)return true;

			for (int i = 0; i < size; i++) {

				uint32_t dtype = (type[i] == 's') ? 0 : ((type[i] == 'u') ? 1 : 2);
				WriteOut[i] = {};
				WriteOut[i].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
				WriteOut[i].descriptorCount = 1;
				WriteOut[i].dstSet = Tuple(t, 1).Set;
				WriteOut[i].descriptorType = DType[dtype];
				WriteOut[i].dstBinding = i;

			}

			return true;

		};


		template<Interface_desc I>
		bool bind(VkCommandBuffer cmd, I& inter) {
			vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_GRAPHICS, draft, 0, 1, &(Tuple(io[inter], 1).Set), 0, NULL);
			return true;
		}
		///void drawSpriteImmutable(Object3D* obj);
		*/


	};




/*





struct UniscriptorPool {
	VkDescriptorPool descriptorPool;
	VkDescriptorSetLayout descriptorSetLayout;
	VkDevice device;

	UniscriptorPool(VkDevice _device, UINT32 MaxSize);
	~UniscriptorPool();
};



*/

#endif
