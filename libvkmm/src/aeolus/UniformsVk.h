#pragma once

#ifndef UNIFORM_H
#define UNIFORM_H

#include "types.hpp"
#include "pch_mm.h"
#include "working_mm.h"

#ifdef  LOG_NO_uni
#define log_uni(...)
#else
#define log_uni(...) log__thread(__FILE__, __LINE__, LOG_FILE, __VA_ARGS__)
#endif


MemExtern(MIBmvk, SIZE_MIBm);
MemExtern(Mvk, SIZE_MDev);
MemExtern(IBmvk, SIZE_IBmDev);
MemExtern(Mvk, SIZE_MVis);
MemExtern(IBmvk, SIZE_IBmVis);


#define INLINE_CREATE_UBO(ubo,si) {\
ubo = { .id = -1,.version = 0,.size = (si) };\
vobjVk->$createBuffer$(&ubo);\
MIBmvk _;vobjVk->$get$(_, &ubo);\
info.ubo = std::move(_.info);\
info.ubomap = _.mapped;\
}


struct UniformVk {

	struct Desc {
		Hache                                         hach;
		LayoutType                                 type;
		std::string                                 _type;
	}desc;

	bool                                      allocBach;
	Bache*                                    bach;

	struct {
		long                                            id;
		void*                                  mapped;
		VkDescriptorBufferInfo         info;
		VkBuffer                         vkBuffer;
	}ubo;

	VkDescriptorImageInfo        image;
	

	UniformVk();
	UniformVk(long id, long version, VkDeviceSize size);
	UniformVk(const UniformVk&) = delete;
	UniformVk& operator=(UniformVk other) = delete;
	~UniformVk();

	void dealloc();

	long                                                                      swID;
	bool                                                                    Upd[2];
	std::vector<VkDescriptorSet>           descriptorSets[2];
	std::vector<VkWriteDescriptorSet>  writeDescriptorSets[2];

	void setMaterialProperty(Bache* _bach) {
		bach                = _bach;
		desc.type        = bach->type;
		ubo.info.range = bach->align;
	};

    size_t createSet(DescriptorVk* descVk, std::string_view type ="", bool append = false);
	size_t createSet(DescriptorVk* descVk, std::string_view type, std::vector<VkDescriptorSetLayoutBinding> dslb,  bool append = false);
	
	bool createUBO(VisibleObjectsVk* vobjVk,    VkDeviceSize size = 0);
	bool createICBO(VisibleObjectsVk* vobjVk, long Cnt, VkDeviceSize size = 0);

	bool setUBO(VkBuffer buffer);

	bool push_back(VkDescriptorSet& set);

	bool createWriteSets();
	bool createWriteSets(std::vector<VkDescriptorBufferInfo> uinfo,  long update=1);
	bool createWriteSets(VkDescriptorSet set, std::vector<VkDescriptorBufferInfo> uinfo, std::vector<VkDescriptorImageInfo> iinfo, long update);
};


#endif