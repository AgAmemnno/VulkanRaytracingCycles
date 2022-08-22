#pragma once
#include "pch_mm.h"
#include "working_mm.h"


	UniformVk::UniformVk() {
		desc = {
			.hach = {.id = -1,.version = -1,.hash = size_t(-1)},
			.type = ""
		};
		ubo.id = -1;
		ubo.mapped = nullptr;
		allocBach = false;
		bach = nullptr;
	};

	UniformVk::UniformVk(long id, long version, VkDeviceSize size) :desc({
			.hach = {.id = -1,.version = -1,.hash = size_t(-1)},
			.type = ""
		}) {
		ubo.id = -1;
		ubo.mapped = nullptr; allocBach = false;
		bach = nullptr;
		Upd[0] = Upd[1] = false;
	};

	UniformVk::~UniformVk() { dealloc(); }

	void  UniformVk::dealloc() {
		if (allocBach) {
			__Delete__(bach);
			allocBach = false;
		}

		for (auto& v : descriptorSets) v.clear();
		for (auto& v : writeDescriptorSets)v.clear();


	};

	size_t UniformVk::createSet(DescriptorVk* descVk, std::string_view type, bool append) {

		desc.hach = { .id = -1,.version = -1 };
		
		if (type != "") {
			desc.type = type;
		}
		else {
			desc.type = bach->type;
		}

		log_uni("Create puddle %s    \n", desc.type.data(), desc.hach.id);

		descVk->$createPuddle$(desc);

		descriptorSets[swID].push_back(descVk->getSet(desc.hach.id));

		if (append)descVk->$createLayout$(desc.type);

		return descriptorSets[swID].size() - 1;

	};

	size_t  UniformVk::createSet(DescriptorVk* descVk, std::string_view type, std::vector<VkDescriptorSetLayoutBinding> dslb,bool append) {

		if (swID != 1) swID = 0;

		desc.hach   = { .id = -1,.version = -1 };
		desc._type = type;
		desc.type = desc._type;
		log_uni("Create puddle  %d    %s    \n", desc.hach.id,desc.type.data());

		descVk->$createPuddle$(desc,dslb);
		descriptorSets[swID].push_back(descVk->getSet(desc.hach.id));

		if (append)descVk->$createLayout$(desc.type, dslb);

		return descriptorSets[swID].size() - 1;

	};

	bool UniformVk::createUBO(VisibleObjectsVk* vobjVk, VkDeviceSize size) {
		
		if (allocBach) {log_bad("CreateUBO    NIL   aleady allocated. \n");};
		allocBach = true;
		bach = new Bache;

		bach->buffer.id = -1; bach->buffer.version = 0;
		bach->align      = size;
		bach->refCnt   = 1;
		bach->size = size;
		vobjVk->$createBuffer$(*bach);
		MIBmvk _;
		vobjVk->get(_, &bach->buffer);
		
		
		ubo.info = std::move(_.info);
		ubo.mapped   = _.mapped;
		ubo.vkBuffer = _.buffer;

		return true;
	};

	bool UniformVk::createICBO(VisibleObjectsVk* vobjVk, long Cnt,VkDeviceSize size) {

		if (allocBach) { log_bad("CreateICBO    NIL   aleady allocated. \n"); };
		allocBach = true;
		bach = new Bache;

		bach->buffer.id = -1; bach->buffer.version = 0;
		bach->align = size;
		bach->refCnt = Cnt;
		bach->size = size;
		vobjVk->$createBuffer$(*bach, VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT);
		MIBmvk _;
		vobjVk->get(_, &bach->buffer);


		ubo.info = std::move(_.info);
		ubo.mapped = _.mapped;
		ubo.vkBuffer = _.buffer;

		return true;
	};

	bool UniformVk::setUBO(VkBuffer buffer) {

		ubo.info.buffer  = buffer;
		ubo.info.offset  = ubo.id * bach->align;
		ubo.info.range   = bach->align;
		char* begin = (char*)(bach->mapped);
		ubo.mapped = (void*)(begin + ubo.info.offset);

		return true;
	};

	bool UniformVk::push_back(VkDescriptorSet& set) {
		descriptorSets[swID].push_back(set);
		return true;
	};

	bool UniformVk::createWriteSets() {
		createWriteSets({ ubo.info });
		return true;
	};

	bool UniformVk::createWriteSets(std::vector<VkDescriptorBufferInfo> uinfo,long update) {

		if (desc.hach.id < 0)log_bad("there is no descriptorSets.\n");

		if ( (update > 0) || (update < 0) ) {

			struct {
				uint32_t u;
				uint32_t t;
				uint32_t s;
			}idx = { uint32_t(-1),uint32_t(-1),uint32_t(-1) };


			size_t     size = uinfo.size();
		
			writeDescriptorSets[swID].resize(size);

			for (int i = 0; i < (int)size; i++) {

				/*
				if (desc.type[i] == 's') {
					idx.s++;
				}
				else if (desc.type[i] == 'u') {
					*/
					idx.u++;
					///if (idx.u == 1) log_bad(" NIL  Create UBO   over limit. \n");
					writeDescriptorSets[swID][i] = {
						.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
						.dstSet = descriptorSets[swID][i],
						.dstBinding = 0,
						.descriptorCount = 1,
						.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
						.pBufferInfo = &(uinfo[idx.u]),
					};

			    /*
				}
				else if (desc.type[i] == 't') {
					idx.t++;
				}
				else {
					log_bad("Descriptor_CreateIO::ParseError  \n");
				};
				*/

			}

		}

		if (update >= 0) {
			Upd[swID] = true;
			vkUpdateDescriptorSets($device, static_cast<uint32_t>(writeDescriptorSets[swID].size()), writeDescriptorSets[swID].data(), 0, nullptr);
		};

		///delete[] writeDescriptorSets;
		return true;
	};
	
	bool UniformVk::createWriteSets(VkDescriptorSet set,std::vector<VkDescriptorBufferInfo> uinfo, std::vector<VkDescriptorImageInfo> iinfo, long update) {

		if (desc.hach.id < 0)log_bad("there is no descriptorSets.\n");

		if ((update > 0) || (update < 0)) {

			struct {
				uint32_t u;
				uint32_t t;
				uint32_t s;
			}idx = { uint32_t(-1),uint32_t(-1),uint32_t(-1) };

			size_t     size = desc.type.size();

			writeDescriptorSets[swID].resize(size);

			log_uni("Descriptor WriteOut   Set %x   \n", set);

			for (uint32_t i = 0; i < size; i++) {

				if (desc.type[i] == 's') {
					idx.s++;
				}
				else if (desc.type[i] == 'u') {
					idx.u++;
					///if (idx.u == 1) log_bad(" NIL  Create UBO   over limit. \n");
					writeDescriptorSets[swID][i] = {
						.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
						.dstSet = set,
						.dstBinding = i,
						.descriptorCount = 1,
						.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
						.pBufferInfo = &(uinfo[idx.u]),
					};
					log_uni("Descriptor WriteOut   Buffer %x   \n", uinfo[idx.u].buffer);
				}
				else if (desc.type[i] == 't') {
					idx.t++;
					writeDescriptorSets[swID][i] = {
					.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
					.dstSet = set,
					.dstBinding = i,
					.descriptorCount = 1,
					.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
					.pImageInfo = &(iinfo[idx.t]),
					};
					log_uni("Descriptor WriteOut   Image %u   %x   \n", iinfo[idx.t].imageLayout, iinfo[idx.t].imageView);
				
				}
				else {
					log_bad("Descriptor_CreateIO::ParseError  \n");
				};

			}

		}

		if (update >= 0) {
			Upd[swID] = true;
			vkUpdateDescriptorSets($device, static_cast<uint32_t>(writeDescriptorSets[swID].size()), writeDescriptorSets[swID].data(), 0, nullptr);

			log_uni("UPdateDescriptor [%s]   %zu  %x   \n", desc.type.data(),writeDescriptorSets[swID].size(), writeDescriptorSets[swID].data());
		};
		
		///delete[] writeDescriptorSets;
		return true;
	};

	
