#include "pch_mm.h"
#include "working_mm.h"


///#define LOG_NO_desc
#ifdef  LOG_NO_desc
#define log_desc(...)
#else
#define log_desc(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif

/*
void vkDSLMem::destroy() {
	for (int i = 0; i < types::SIZE_LAYOUT; i++) {
		if (Layout[i].type != "") {
			vkDestroyDescriptorSetLayout($device, Layout[i].layout, nullptr);
			Layout[i].layout = VK_NULL_HANDLE;
			Layout[i].type = "";
		}
	};
};
*/


void vkDSLMem::destroy() {
	AcquireSRWLockExclusive(&SlimLock);
	for(auto &[k,v] : Layout ){
		vkDestroyDescriptorSetLayout($device, v, nullptr);
	};
	Layout.clear();
	ReleaseSRWLockExclusive(&SlimLock);
};


	/*
   bool vkDSLMem::get(VkDescriptorSetLayout& layout, layoutType Lty) {
		
		size_t num = -1;
		if (!types::LayoutNum(Lty, num)) {
			log_bad("got  incorrect arguments.    %s   \n", Lty.data());
			return false;
		}

		if (Layout[(UINT32)num].type == Lty) {
			layout = Layout[(UINT32)num].layout;
			return true;
		}
		return false;
	};
	*/
	bool vkDSLMem::get(VkDescriptorSetLayout& layout, LayoutType Lty) {

		if( Layout.count(Lty.data()) > 0) {
			layout = Layout[Lty.data()];
			return true;
		};

		return false;
	};

	bool vkDSLMem::$set$(LayoutType type, std::vector<VkDescriptorSetLayoutBinding>& DSLB) {
	
		/*
		size_t num = -1;
		if (!types::LayoutNum(type, num)) {
			log_bad("got  incorrect arguments.    %s   \n", type.data());
			return false;
		}
		if (Layout[num].type == type) return true;
		*/

		AcquireSRWLockExclusive(&SlimLock);

	
		if (Layout.count(type.data()) > 0) {
			ReleaseSRWLockExclusive(&SlimLock);
			return true;
		}
		
		bool Default = false;
		size_t   size = DSLB.size();
		if (size == 0) {
			size = type.size();
			Default = true;
		};

		

		VkDescriptorSetLayoutCreateInfo descriptorSetLayoutCreateInfo{
			 .sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
			.pNext = NULL,
			.flags = 0,
			.bindingCount = (uint32_t)size
		};
	
		if (Default) {
			VkDescriptorSetLayoutBinding* setLayoutBindings = nullptr;
			setLayoutBindings = new VkDescriptorSetLayoutBinding[size];
			_PoolSize pSize = { (uint32_t)size,0,0,0 };
			for (int i = 0; i < size; i++) {
				if (type[i] == 's') {

					setLayoutBindings[i].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
					setLayoutBindings[i].stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT | VK_SHADER_STAGE_VERTEX_BIT;
					setLayoutBindings[i].binding = (uint32_t)i;
					setLayoutBindings[i].descriptorCount = 1;
					pSize.ssbo++;

				}
				else if (type[i] == 'u') {

					setLayoutBindings[i].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
					setLayoutBindings[i].stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
					setLayoutBindings[i].binding = (uint32_t)i;
					setLayoutBindings[i].descriptorCount = 1;
					pSize.ubo++;

				}
				else if (type[i] == 't') {

					setLayoutBindings[i].descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
					setLayoutBindings[i].stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;
					setLayoutBindings[i].binding = (uint32_t)i;
					setLayoutBindings[i].descriptorCount = 1;
					setLayoutBindings[i].pImmutableSamplers = NULL;
					pSize.tex++;

				}
				else {
					log_bad("Descriptor_CreateIO::ParseError  \n");
				};
			}
			descriptorSetLayoutCreateInfo.pBindings = &(setLayoutBindings[0]);
		}
		else {
			descriptorSetLayoutCreateInfo.pBindings = DSLB.data();
		};
		///uint32_t ID = createIO(type, pSize, setLayoutBindings);

		VkDescriptorSetLayout  _io;
		VK_CHECK_RESULT(vkCreateDescriptorSetLayout($device, &descriptorSetLayoutCreateInfo, NULL, &_io));

	

		Layout[type.data()]             =   _io;
		///Layout[num].type      = type;

		if (Default)delete[] descriptorSetLayoutCreateInfo.pBindings;

		ReleaseSRWLockExclusive(&SlimLock);

		log_desc("Create  DSL   %s     %p   \n", type.data(), Layout[type.data()]);
		return true;

	};



DescriptorVk::DescriptorVk() : draft(VK_NULL_HANDLE), Nums({ 0,0 }) {
	///memset(io,NULL, DESC_MAX * sizeof(ioSP));
	io.resize(0);
	layoutSet.resize(0);
	log_scr("Constructor   Descriptor   io  %zu   layoutSet  %x   \n", io.size(),layoutSet.size());

};

DescriptorVk::~DescriptorVk() {destroy();};


void  DescriptorVk::createDraft(std::vector<VkPushConstantRange> pushConstantRange) {

	VkPipelineLayoutCreateInfo pipelineLayoutCreateInfo{};

	uint32_t  pcSize = (uint32_t)(pushConstantRange.size());
	if (pcSize != 0) {
		pipelineLayoutCreateInfo.pushConstantRangeCount = pcSize;
		pipelineLayoutCreateInfo.pPushConstantRanges = pushConstantRange.data();
	}

	pipelineLayoutCreateInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
	pipelineLayoutCreateInfo.pSetLayouts =  layoutSet.data();
	pipelineLayoutCreateInfo.setLayoutCount =  (uint32_t)layoutSet.size();
	VK_CHECK_RESULT(vkCreatePipelineLayout($device, &pipelineLayoutCreateInfo, nullptr, &draft));
};


void DescriptorVk::destroy() {

	if (draft != VK_NULL_HANDLE) {
		vkDestroyPipelineLayout($device, draft, nullptr);
		draft = VK_NULL_HANDLE;
	}


	for (auto& [pool, set] : io) {
		if (pool != VK_NULL_HANDLE) {
			vkDestroyDescriptorPool($device, pool, nullptr);
			pool = VK_NULL_HANDLE;
		};
	};

	///if(Nums > 0)vkFreeDescriptorSets($device, Pool, Nums, ioSet.data());



	Nums = { 0,0 };

}






/*
void DescriptorVk::createPool() {

	std::for_each(std::execution::par_unseq, layout.begin(), layout.end(), [this](auto& p) {

		layoutType type = p.first;




		VkDescriptorSetAllocateInfo  allocInfo{};
		allocInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
		allocInfo.pSetLayouts = &p.second;
		allocInfo.descriptorSetCount = 1;

		static std::vector<VkDescriptorPoolSize> poolSizes;
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
		}

		VkDescriptorPoolCreateInfo descriptorPoolInfo{};
		descriptorPoolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
		descriptorPoolInfo.poolSizeCount = static_cast<uint32_t>(poolSizes.size());
		descriptorPoolInfo.pPoolSizes = poolSizes.data();
		descriptorPoolInfo.maxSets = 1;


		int i = 0;
		for (auto& [mat, t] : io) {

			if (std::get<0>(t) == type) {
				ioSP& sp = std::get<1>(t);
				VK_CHECK_RESULT(vkCreateDescriptorPool($device, &descriptorPoolInfo, nullptr, &sp.Pool));
				allocInfo.descriptorPool = sp.Pool;
				VK_CHECK_RESULT(vkAllocateDescriptorSets($device, &allocInfo, &sp.Set));
				i++;
			}

		}




   });

};
*/

/*
void UniformVk::TypeUT(DescriptorVk* descMan, size_t size, PyObject* o) {


	Object3D* obj = (Object3D*)o;

	ID.type = UT;
	ID.set = -1;
	descMan->registerIO(ID.type, *this);

	uniscriptor = new UniscriptorVk(descMan->$device, VK_NULL_HANDLE, VK_NULL_HANDLE);



	uniscriptor->createUniformBuffers(size);


	///VkWriteDescriptorSet* WriteOut = new VkWriteDescriptorSet[2];
	///delete[] WriteOut;

};


void UniformVk::TypeU(DescriptorVk* descMan, size_t size, PyObject* o) {

	Object3D* obj = (Object3D*)o;


	ID.type = UNI;
	ID.set = -1;
	descMan->registerIO(ID.type, *this);

	uniscriptor = new UniscriptorVk($device, VK_NULL_HANDLE, VK_NULL_HANDLE);



	uniscriptor->createUniformBuffers(size);


	///VkWriteDescriptorSet* WriteOut = new VkWriteDescriptorSet[2];
	///delete[] WriteOut;

};
UniformVk::UniformVk() {
	static int inst = 0;
	inst++;
	ID.local = inst;
};
void UniformVk::UpdateDesc(DescriptorVk* descMan, std::vector<DescUnion>& desc) {


	if (ini.desc) {
		descMan->factoryDescriptor(ID.type, ID.set, WriteOut);

		ini.desc = false;
	}

	int i = 0;
	for (auto& d : desc) {
		if (d.type == 'B') {

			WriteOut[i].pBufferInfo = &(uniscriptor->uniform.descriptor);// d.info.buffer;

		}
		else if (d.type == 'I') {

			WriteOut[i].pImageInfo = &d.info.image;
		}
		i++;
	}
	vkUpdateDescriptorSets($device, uint32_t(desc.size()), WriteOut, 0, NULL);

}

void UniformVk::UpdateDesc(DescriptorVk* descMan, VkDescriptorImageInfo* Iinfo) {


	if (ini.desc) {
		descMan->factoryDescriptor(ID.type, ID.set, WriteOut);

		ini.desc = false;
	}
	WriteOut[0].pBufferInfo = &(uniscriptor->uniform.descriptor);// d.info.buffer;
	WriteOut[1].pImageInfo = Iinfo;

	vkUpdateDescriptorSets($device, uint32_t(2), WriteOut, 0, NULL);

}


void UniformVk::UpdateDesc(DescriptorVk* descMan) {



	if (ini.desc) {

		descMan->factoryDescriptor(ID.type, ID.set, WriteOut);
		ini.desc = false;
	}


	WriteOut[0].pBufferInfo = &(uniscriptor->uniform.descriptor);// d.info.buffer;

	vkUpdateDescriptorSets($device, uint32_t(1), WriteOut, 0, NULL);


}

void UniformVk::LocalMatrix(VkDevice device, VkDescriptorPool pool, VkDescriptorSetLayout layout, UniscriptorVk* global) {

	uniscriptor = new UniscriptorVk(device, pool, layout);
	uniscriptor->createUniformBuffers(4 * 16);
	uniscriptor->createDescriptors();
	///log_trace("UNISCRIPTOR     %d    map  %p    \n", ID.local, (char*)uniscriptor->uniform.mapped);
	descriptorSets.resize(2);
	descriptorSets[0] = global->Set;
	descriptorSets[1] = uniscriptor->Set;

};

void UniformVk::GlobalMatrix(VkDevice device, VkDescriptorPool pool, VkDescriptorSetLayout layout, UniscriptorVk* global) {

	uniscriptor = nullptr;
	descriptorSets.resize(1);
	descriptorSets[0] = global->Set;

};

void UniformVk::mapLocal(Object3D* spri) {

};

VkDescriptorSetLayout UniformVk::getLayout() {
	return uniscriptor->Layout;
};

char* UniformVk::getMap() {
	return (char*)uniscriptor->uniform.mapped;
}

void UniformVk::dealloc() {
	if (uniscriptor == nullptr) {
		delete uniscriptor; uniscriptor = nullptr;
	}
}

*/

/*
UniscriptorPool::UniscriptorPool(VkDevice _device, UINT32 MaxSize) {

	std::array<VkDescriptorSetLayoutBinding, 1> setLayoutBindings{};


	setLayoutBindings[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
	setLayoutBindings[0].binding = 0;
	setLayoutBindings[0].stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
	setLayoutBindings[0].descriptorCount = 1; /// ARRAY Length





	VkDescriptorSetLayoutCreateInfo descriptorLayoutCI{};
	descriptorLayoutCI.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
	descriptorLayoutCI.bindingCount = static_cast<uint32_t>(setLayoutBindings.size());
	descriptorLayoutCI.pBindings = setLayoutBindings.data();

	VK_CHECK_RESULT(vkCreateDescriptorSetLayout($device, &descriptorLayoutCI, nullptr, &descriptorSetLayout));



	std::array<VkDescriptorPoolSize, 1> descriptorPoolSizes{};

	// Uniform buffers : 1 for scene and 1 per object (scene and local matrices)
	descriptorPoolSizes[0].type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
	descriptorPoolSizes[0].descriptorCount = 1 + MaxSize;


	// Create the global descriptor pool
	VkDescriptorPoolCreateInfo descriptorPoolCI = {};
	descriptorPoolCI.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
	descriptorPoolCI.poolSizeCount = static_cast<uint32_t>(descriptorPoolSizes.size());
	descriptorPoolCI.pPoolSizes = descriptorPoolSizes.data();
	// Max. number of descriptor sets that can be allocted from this pool (one per object)
	descriptorPoolCI.maxSets = MaxSize;

	VK_CHECK_RESULT(vkCreateDescriptorPool($device, &descriptorPoolCI, nullptr, &descriptorPool));

};

UniscriptorPool::~UniscriptorPool() {

	if (descriptorPool) {
		vkDestroyDescriptorPool($device, descriptorPool, nullptr);
		vkDestroyDescriptorSetLayout($device, descriptorSetLayout, nullptr);
	}

};



UniscriptorVk::UniscriptorVk(VkDevice dev, VkDescriptorPool pool, VkDescriptorSetLayout layout) :Device(dev), Pool(pool), Layout(layout), Set(nullptr) {

};

UniscriptorVk::~UniscriptorVk() {
	destroyUniformBuffers();
	destroyDescriptors();
};


void UniscriptorVk::createDescriptors(VkShaderStageFlags ssflags)
{
	// Allocates an empty descriptor set without actual descriptors from the pool using the set layout
	VkDescriptorSetAllocateInfo allocateInfo{};
	allocateInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
	allocateInfo.descriptorPool = Pool;
	allocateInfo.descriptorSetCount = 1;
	allocateInfo.pSetLayouts = &Layout;
	VK_CHECK_RESULT(vkAllocateDescriptorSets($device, &allocateInfo, &Set));



	std::array<VkWriteDescriptorSet, 1> writeDescriptorSets{};


	writeDescriptorSets[0].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
	writeDescriptorSets[0].dstSet = Set;
	writeDescriptorSets[0].dstBinding = 0;
	writeDescriptorSets[0].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
	writeDescriptorSets[0].pBufferInfo = &(uniform.descriptor);
	writeDescriptorSets[0].descriptorCount = 1;



	vkUpdateDescriptorSets($device, static_cast<uint32_t>(writeDescriptorSets.size()), writeDescriptorSets.data(), 0, nullptr);

}

void UniscriptorVk::destroyDescriptors() {
	/// if(Set!=nullptr)vkFreeDescriptorSets(Device, Pool, 1, &Set);
};

void UniscriptorVk::createUniformBuffers(VkDeviceSize size)
{

	VkMemoryRequirements memReqs;
	VkBufferCreateInfo bufferInfo = {};
	VkMemoryAllocateInfo allocInfo = {};


	allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
	allocInfo.pNext = nullptr;
	allocInfo.allocationSize = 0;
	allocInfo.memoryTypeIndex = 0;

	bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
	bufferInfo.size = size;
	// This buffer will be used as a uniform buffer
	bufferInfo.usage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
	VK_CHECK_RESULT(vkCreateBuffer($device, &bufferInfo, nullptr, &uniform.buffer));
	vkGetBufferMemoryRequirements($device, uniform.buffer, &memReqs);
	allocInfo.allocationSize = memReqs.size;
	allocInfo.memoryTypeIndex = getMemoryTypeIndex(memReqs.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

	VK_CHECK_RESULT(vkAllocateMemory($device, &allocInfo, nullptr, &(uniform.memory)));
	VK_CHECK_RESULT(vkBindBufferMemory($device, uniform.buffer, uniform.memory, 0));

	// Store information in the uniform's descriptor that is used by the descriptor set
	uniform.descriptor.buffer = uniform.buffer;
	uniform.descriptor.offset = 0;
	uniform.descriptor.range = size;

	VK_CHECK_RESULT(vkMapMemory($device, uniform.memory, 0, size, 0, (void**)&uniform.mapped));

	///updateUniformBuffers();
}

void UniscriptorVk::destroyUniformBuffers() {
	vkDestroyBuffer($device, uniform.buffer, nullptr);
	vkFreeMemory($device, uniform.memory, nullptr);
};

*/

