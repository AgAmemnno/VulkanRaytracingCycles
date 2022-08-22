#pragma once

#define PUSH_POOL_SC true


#define KERNEL_TEX(type ,name) type* name[S1]; 
template<size_t S1>
struct KT
{
#include "kernel/kernel_textures_ccl.h"
};
typedef KT<1>  KT_t;
struct  ShaderClosure_MAX
{
	ccl::float3 weight;
	ccl::ClosureType type;
	float sample_weight;
	ccl::float3 N;
	float data[26];
};
template<size_t Bs>
struct  Pool_Block
{
	float cap[Bs];
};
template<size_t Bs, size_t As>
struct SCPOOL
{
	Pool_Block<As>* sc;
	Pool_Block<Bs>* is;
};
template<size_t As>
struct Gate
{
	BYTE* block[As];
};


template<class T, class T0>
struct  DevicePointerVk {
public:
	T        cdata;
	T        gdata;
	T0* gate;
	bool hostV, commit;
	DevicePointerVk() {};
	DevicePointerVk(vkmm::BufferAllocation* ba) :ba(ba) {
		reset();
	};
	~DevicePointerVk() {
		dealloc();
	};
	void dealloc() {
		if (cmder != nullptr) {
			delete cmder;
			cmder = nullptr;
		}
	};

	VkBuffer getVkBuffer() { return ba->buffer; };
	VkDeviceSize getOffset() { return pivot; };

	void reset(vkmm::BufferAllocation* _ba, bool Host = true) {
		hostV = Host;
		ba = _ba;
		reset();
	};
	void reset(vkmm::BufferAllocation* _ba, size_t size) {
		hostV = false;
		ba = _ba;
		if (cmder == nullptr)cmder = new ImmidiateBufferCmd<ImmidiateCmdPool>;
		if (size == 0) cmder->freeStaging();
		else if (size > 0)cmder->allocStaging(size);
		reset();
	};
	void reset() {
		if (hostV)VK_CHECK_RESULT(vkmm::MapMemory($pallocator, ba->alloc, (void**)&cpuptr));
		gpuptr = tell(0);
		pivot = 0;
		total = 0;
		commit = false;
	};
	size_t distance() {
		if (!hostV) return 0;
		vkmm::UnmapMemory($pallocator, ba->alloc);
		byte* _cpuptr = cpuptr;
		VK_CHECK_RESULT(vkmm::MapMemory($pallocator, ba->alloc, (void**)&cpuptr));
		size_t dist = _cpuptr - cpuptr;
		cpuptr += pivot;
		assert(cpuptr == _cpuptr);
		byte* _gpuptr = tell(0);
		size_t dist2 = gpuptr - _gpuptr;
		assert(dist == dist2);

		return dist;
	};

	bool beginCmd(VkDeviceSize offset, VkDeviceSize size) {

		assert(!hostV);
		reset();
		assert(cmder->staging.bufferCreateInfo.size >= size);
		cpuptr = (byte*)cmder->GetMap(offset, size);
		commit = true;
		return  true;
	};
	void  endCmd(bool flush = true) {

		assert(!hostV && commit);

		cmder->begin();
		cmder->Copy(ba->buffer, cmder->stg_info.size, cmder->stg_info.offset, cmder->stg_info.offset);
		cmder->end();
		cmder->submit();
		cmder->wait();

		if (flush)cmder->freeStaging();
		commit = false;

	}


	template<class dT>
	void  upload_memset(dT*& gdst, dT*& cdst, int val, size_t size, int align) {

		assert((hostV || (!hostV && commit)));
		memset(cptr(), val, size);
		gdst = (dT*)gptr();
		cdst = (dT*)cptr();
		unison(size, align);

	};
	template<class dT, class sT>
	void upload(dT*& gdst, dT*& cdst, sT* src, int align, bool next = true) {

		assert((hostV || (!hostV && commit)));
		memcpy(cptr(), src, sizeof(sT));
		if (next) {
			gdst = (dT*)gptr();
			cdst = (dT*)cptr();
			unison(sizeof(sT), align);
		}

	};
	int  gid = 0;
	void _uploadGate() {};

	template<class T3, typename... Args>
	void _uploadGate(T3&& s, Args&&... args)
	{
		gate->block[gid] = (BYTE*)s;
		gid++;
		_uploadGate(std::forward<Args>(args)...);
	};
	template<class T3, typename... Args>
	void uploadGate(T3&& s, Args&&... args) {

		gid = 0;
		gate = (T0*)cptr();
		_uploadGate(s, args ...);

	};

	byte* tell(size_t piv = 0) {
		VkBufferDeviceAddressInfoEXT info = { VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO_EXT };
		info.buffer = ba->buffer;
		VkDeviceAddress baseAddr = vkGetBufferDeviceAddressKHR($device, &info);
		return  (byte*)baseAddr + piv;    // not a valid cpu pointer but useful for avoiding casting
	}
	size_t size() { return total; }
	byte* cptr() { return cpuptr; };
	byte* gptr() { return gpuptr; };

	void stride(size_t n, int align) {
		assert(!hostV);
		gpuptr += n;
		pivot += n;
		gpuptr = AlignUpPtr(gpuptr, align);
		pivot = AlignUpPtr(pivot, align);
		if (pivot > total) total = pivot;
		assert(total < ba->alloc->GetSize());
		printf("stride %zu   pivot %zu  \n ", n, pivot);
	}
	void unison(size_t n, int align) {

		cpuptr += n;
		gpuptr += n;
		pivot += n;
		cpuptr = AlignUpPtr(cpuptr, align);
		gpuptr = AlignUpPtr(gpuptr, align);
		pivot = AlignUpPtr(pivot, align);
		if (pivot > total) total = pivot;
		assert(total < ba->alloc->GetSize());
		printf("unison   stride %zu   pivot %zu  \n ", n, pivot);
	}

	size_t alloc_size = 0;
private:
	size_t pivot, total;
	byte* cpuptr = NULL;
	byte* gpuptr = NULL;
	vkmm::BufferAllocation* ba;
	ImmidiateBufferCmd<ImmidiateCmdPool>* cmder = nullptr;

};

static DevicePointerVk<KT<1>, KT_t> dptr;

#ifdef PUSH_POOL_SC
typedef Gate<2> pool_t;
typedef DevicePointerVk<SCPOOL<36, 6>, pool_t> DPTR2_t;
static DevicePointerVk<SCPOOL<36, 6>, pool_t>* dptr2 = nullptr;
#endif


#include "background_test.h"
static lights_manager lm;
struct KernelGlobals_PROF {
	ccl::uint2      pixel;
	ccl::float3 f3[STAT_BUF_MAX * MAX_HIT];
	float   f1[STAT_BUF_MAX * MAX_HIT];
	ccl::uint     u1[STAT_BUF_MAX * MAX_HIT];
};
struct KernelBuffer {
#define ALLOCATE_BUFFER_INFO 1024
	const size_t kd_size = sizeof(ccl::KernelData);
	const size_t kg_size = sizeof(KernelGlobals_PROF);
	const size_t allo_size = sizeof(uint32_t) * ALLOCATE_BUFFER_INFO;
	VkDescriptorBufferInfo kdinfo = {
	 .offset = 0,
	 .range = kd_size
	};
	VkDescriptorBufferInfo kginfo;
	VkDescriptorBufferInfo alloinfo;
	template<class T>
	void  writeDescsriptorSet_Kernel(int setNo, T& mat) {

		if (memVk.bamp.count("kerneldata") == 0) {
			auto usage = (VkBufferUsageFlagBits)(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT);
			size_t size = vkmm::AlignUp((size_t)kd_size, usage);
			usage = (VkBufferUsageFlagBits)(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT);
			kginfo.range = kg_size;
			kginfo.offset = size;
			size += vkmm::AlignUp((size_t)kg_size, usage);
			alloinfo.range = allo_size;
			alloinfo.offset = size;
			size += vkmm::AlignUp((size_t)allo_size, usage);

			memVk.createBuffer("kerneldata", size,
				VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
				vkmm::MEMORY_USAGE_CPU_TO_GPU,
				[&]<class T2>(T2 & a) {
				if (a.alloc->GetMemoryTypeIndex() == 1)
				{
					printf("need to hostvisible .  \n");
					exit(-1);
				}
				else if ((a.alloc->GetMemoryTypeIndex() == 2) | (a.alloc->GetMemoryTypeIndex() == 4)) {
					kdinfo.buffer = a.buffer;
					kginfo.buffer = a.buffer;
					alloinfo.buffer = a.buffer;
					void* dst = a.alloc->GetMappedData();
					memset((BYTE*)dst + alloinfo.offset, 0, allo_size);
				}
			}
			);
		}




		std::vector<VkWriteDescriptorSet> write;
		write.clear();
		auto Set = mat.uniform.descriptorSets[0];
		write.push_back({
		   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		   .dstSet = Set[setNo],
		   .dstBinding = 0,
		   .dstArrayElement = 0,
		   .descriptorCount = 1,
		   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		   .pBufferInfo = &kdinfo
			});
		write.push_back({
		   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		   .dstSet = Set[setNo],
		   .dstBinding = 1,
		   .dstArrayElement = 0,
		   .descriptorCount = 1,
		   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
		   .pBufferInfo = &kginfo
			});
		write.push_back({
	   .sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
	   .dstSet = Set[setNo],
	   .dstBinding = 2,
	   .dstArrayElement = 0,
	   .descriptorCount = 1,
	   .descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
	   .pBufferInfo = &alloinfo
			});
		vkUpdateDescriptorSets($device, write.size(), write.data(), 0, NULL);

	}

	void initialize() {
		static bool AC_DEBUG = false;
		static bool KG_DEBUG = true;
		void* dst = memVk.bamp["kerneldata"].alloc->GetMappedData();
		if (AC_DEBUG) {
			auto deb = (int*)((BYTE*)dst + alloinfo.offset);
			int sum = 0;
			for (int i = 0; i < ALLOCATE_BUFFER_INFO; i++) {
				printf(" atomic Counter [%d]   [%d]    val  %d     uval   %u  \n", 1023 - i, i, deb[i], UINT(deb[i]));
				deb[i] = 0;
			}
		}
		else  memset((BYTE*)dst + alloinfo.offset, 0, alloinfo.range);
		if (KG_DEBUG) memset((BYTE*)dst + kginfo.offset + offsetof(KernelGlobals_PROF, u1), 0, STAT_BUF_MAX * MAX_HIT * sizeof(ccl::uint));

	}

};
KernelBuffer kb;

template<class Dty,class Blty>
void allocate_json(Dty& dp,Blty& bl) {

	using namespace macaron;
	
	auto kt  = bl.document["KT"].GetObjectA();

	
#define GetSizefromJson(hKEY,VAL,Size) {  \
	   if (kt.HasMember(#VAL)) {\
	      std::string Jstr = kt[#VAL].GetString();\
		  bl.decodeJson(&bl.tex.VAL, Jstr);\
		  bl.tex.VAL.null = false;\
	   }else{\
		   bl.tex.VAL.null = true;bl.tex.VAL.data_size = 0;}\
        bl.tex.VAL.name = nullptr;bl.tex.VAL.device = nullptr;\
       Size += bl.tex.VAL.data_size*bl.tex.VAL.struct_size();}

	static size_t ca_size = 0;
	dp.alloc_size = 0;
#define KERNEL_TEX(type ,name)  {\
        if(std::string(#name) == "__prim_tri_verts") dp.alloc_size += bl.prim_verts2.size() * sizeof(ccl::float4);\
		else  if (std::string(#name) == "__tri_vindex") dp.alloc_size += bl.tri_vindex2.size() * sizeof(ccl::uint3);\
        else  if (std::string(#name) == "__prim_index") dp.alloc_size += bl.vertOffset.size() * sizeof(uint32_t);\
        else  if (std::string(#name) == "__prim_object") dp.alloc_size += bl.idxOffset.size() * sizeof(uint32_t);\
		else GetSizefromJson(keys, name, dp.alloc_size)}
#include "kernel/kernel_textures_ccl.h"

	dp.alloc_size += 1024 * 1024;
	if (ca_size < dp.alloc_size) {
		memVk.deleteBuffer("kernel_textures");
		memVk.createBuffer("kernel_textures", dp.alloc_size,
			VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT_EXT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
			vkmm::MEMORY_USAGE_CPU_TO_GPU,
			[]<class T1>(T1 & t) {}
		);
		dp.reset(&memVk.bamp["kernel_textures"]);
		ca_size = dp.alloc_size;
	}
	else {
		dp.reset();
	}
#undef GetSizefromJson

}
template<class Dty, class BvhTy, class TexTy>
void UploadKernel_json(Dty& dp, BvhTy& bvh, TexTy& tex) {

		using namespace macaron;
		
		auto kt = bl.document["KT"].GetObjectA();

		size_t align = 256;
		bvh.infoV.resize(bl.infoV.size());
		bvh.infoI.resize(bl.infoI.size());
		
#define GetSizefromJson(hKEY,VAL,Size) {  \
	   if (kt.HasMember(#VAL)) {\
	      std::string Jstr = kt[#VAL].GetString();\
		  bl.decodeJson(&bl.tex.VAL, Jstr);\
		  bl.tex.VAL.null = false;\
	   }else{\
		   bl.tex.VAL.null = true;bl.tex.VAL.data_size = 0;}\
        bl.tex.VAL.name = nullptr;bl.tex.VAL.device = nullptr;\
       Size += bl.tex.VAL.data_size*bl.tex.VAL.struct_size();}


#define  UploadfromDB2(gdst,cdst,T,hKEY,VAL,Size,align,src) {  \
	    cdst = (T*)dp.cptr(); \
		gdst = (T*)dp.gptr(); \
        memcpy( (BYTE*)cdst, (BYTE*)src,Size); \
		dp.unison(Size, align); \
		printf("ptr %s  size %zu device_pointer %llx \n", bl.tex.VAL.name, Size, (uint64_t)gdst); \
	}

#define  UploadfromDB(gdst,cdst,T,hKEY,VAL,Size,align,print_) {  \
		cdst  = (T*)dp.cptr();\
        if(bl.tex.VAL.null){\
              gdst = (T*)0xfefefefefe;\
			  printf("null ptr %s  size %zu device_pointer %llx \n", bl.tex.VAL.name, Size,(uint64_t)gdst);\
		}\
		else {\
				assert( kt.HasMember(#VAL ":data"));\
				std::string Jstr = (std::string)kt[#VAL ":data"].GetString();\
				bl.decodeJson2(cdst, Jstr, Size);\
				print_(#VAL, size / bl.tex.VAL.struct_size(), cdst); \
				gdst = (T*)dp.gptr();\
				dp.unison(Size, align);\
			    printf("ptr %s  size %zu device_pointer %llx \n",bl.tex.VAL.name,Size,(uint64_t)gdst);\
		}}

#define  AllocfromDB2(gdst,cdst,T,hKEY,VAL,Size,align) {\
	             cdst = (T*)dp.cptr();\
				 gdst = (T*)dp.gptr();\
				 dp.unison(Size, align); \
				 printf("ptr %s  size %zu device_pointer %llx \n", bl.tex.VAL.name, Size, (uint64_t)gdst); \
	}



#define KERNEL_TEX(type ,name) {\
		   size_t size = 0;\
		   if (std::string(#name) == "__prim_tri_verts"){ \
					size = bl.prim_verts2.size() * sizeof(ccl::float4); \
                    for(int l =0; l < bvh.infoV.size() ;l++ ){\
							bvh.infoV[l].buffer = dp.getVkBuffer(); \
							bvh.infoV[l].offset = bl.infoV[l].offset  + dp.getOffset(); \
							bvh.infoV[l].range = bl.infoV[l].range;\
							}\
                    UploadfromDB2(dp.gdata.name[0], dp.cdata.name[0], type, keys, name, size, align, bl.prim_verts2.data()); }\
		   else  if (std::string(#name) == "__tri_vindex"){\
		           size = bl.tri_vindex2.size() * sizeof(ccl::uint3); \
                    for(int l =0; l < bvh.infoI.size() ;l++ ){\
							bvh.infoI[l].buffer = dp.getVkBuffer(); \
							bvh.infoI[l].offset  = bl.infoI[l].offset  + dp.getOffset(); \
							bvh.infoI[l].range   = bl.infoI[l].range;\
				   }\
			       UploadfromDB2(dp.gdata.name[0], dp.cdata.name[0], type, keys, name, size, align, bl.tri_vindex2.data());}\
		   else  if (std::string(#name) == "__prim_index"){\
		           size = bl.vertOffset.size() * sizeof(uint32_t); \
			       UploadfromDB2(dp.gdata.name[0], dp.cdata.name[0], type, keys, name, size, align, bl.vertOffset.data());}\
		   else  if (std::string(#name) == "__prim_object"){\
		           size = bl.idxOffset.size() * sizeof(uint32_t); \
			       UploadfromDB2(dp.gdata.name[0], dp.cdata.name[0], type, keys, name, size, align, bl.idxOffset.data());}\
		   else{\
				   GetSizefromJson(keys, name, size)\
					bool upload = true; \
					if (size != 0 && std::string(#name) == "__light_background_marginal_cdf") {\
						    upload = false; \
							lm.updateBG = true; lm.marg_cdf.ptr = (BYTE*)dp.cptr(); lm.marg_cdf.size = size; \
							AllocfromDB2(dp.gdata.name[0],dp.cdata.name[0], type, keys, name, size, align);}\
					if (size != 0 && std::string(#name) == "__light_background_conditional_cdf") {\
							upload = false; lm.updateBG = true; lm.cond_cdf.ptr = (BYTE*)dp.cptr(); lm.cond_cdf.size = size; \
								printf("  lm.cond_cdf.ptr   %p   size %zu   ", lm.cond_cdf.ptr ,lm.cond_cdf.size);\
								AllocfromDB2(dp.gdata.name[0], dp.cdata.name[0], type, keys, name, size, align);\
						}\
					if (upload)UploadfromDB(dp.gdata.name[0], dp.cdata.name[0], type, keys, name, size, align, NOprint); \
					if (std::string(#name) == "__texture_info") {\
										auto  ti = (ccl::TextureInfo*)(dp.cdata.name[0]); \
										tex.textureLoad_json(bl, ti, size); \
										for (int i = 0; i < size / 96; i++) {\
												ccl::TextureInfo& ld = ti[i]; \
												if (ld.width == (UINT)-1) break; \
													printf(" __texture_info [%zu]   ::  data   %zu   data_type  %u    cl_buffer %u  interpolation  %u    extension  %u    width  %u  height  %u   depth %u   use_transform_3d %u  \n", \
														sizeof(ccl::TextureInfo), ld.data, ld.data_type, ld.cl_buffer, ld.interpolation, ld.extension, ld.width, ld.height, ld.depth, ld.use_transform_3d); \
										}\
								}\
		   }\
          printf("  cptr  %p      %s   \n",dp.cptr(), #name);\
		 }
#include "kernel/kernel_textures_ccl.h"


};

template<class Dty>
void makePushReference(Dty& dp) {
	
	printf(" distance %zu \n ", dp.distance());
	dp.gate = (KT_t*)dp.cptr();
#define KERNEL_TEX(type ,name) dp.gate[0].name[0] = dp.gdata.name[0];
#include "kernel/kernel_textures_ccl.h"

}
template<class Dty>
void allocateSC(Dty& dp,size_t sc_size) {

	memVk.createBuffer("sc_pool", sc_size,
		VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT_EXT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
		vkmm::MEMORY_USAGE_GPU_ONLY,
		//vkmm::MEMORY_USAGE_CPU_TO_GPU,
		[&]<class T3>(T3 & a) {

		if (a.alloc->GetMemoryTypeIndex() == 1)
		{
			/// <summary>
			/// ShaderClosure  Pool Size  INIT 256MB.  
			/// bufferReference   8B.  
			/// </summary>
			///            SC_pool  +  SCdebug  + Intersection_pool     ==  501 MB
			size_t pool1 = 144 * 2228224 + 144 * 1024 * 1024;
			size_t pool2 = 24 * 2228224;
			//size_t pool2 = 36 * 2228224;
			size_t pool = pool1 + pool2;
			///       ptr1 SCpool  ptr2 ISpool
			size_t ptr_size = 8 + 8;
			size_t offset = 0;
			size_t align = 8;

			dp.reset(&a, pool + ptr_size);

			if (dp.beginCmd(0, pool + ptr_size)) {
				dp.upload_memset(dp.gdata.sc, dp.cdata.sc, 0, pool1, (int)align);
				dp.upload_memset(dp.gdata.is, dp.cdata.is, 0, pool2, (int)align);
				dp.uploadGate(dp.gdata.sc, dp.gdata.is);
				dp.endCmd();
			}
		}
		else if ((a.alloc->GetMemoryTypeIndex() == 2) | (a.alloc->GetMemoryTypeIndex() == 4)) {
			///  HostVisible    allocator pool ?
			log_bad("Device Local  out of memory. you can use host visible . NIL \n");
		};


	}
	);

}
template<class T>
auto  pushReferences2(T& bvh) {
	bvh.infoI.clear();
	bvh.infoV.clear();

	auto  Upload = [&](T& bvh, BLTextures& tex) {
		///prim_index = > vertOffset
	    ///prim_object = > idxOffset
		
		bl.remake_vertex_json(bvh);
		tex.image_update_json(bl);
		lm.updateBG = false;
		allocate_json(dptr, bl);
		UploadKernel_json(dptr, bvh, tex);
	    makePushReference(dptr);

#ifdef PUSH_POOL_SC
#define PUSH_POOL_IS
		static size_t sc_size = 0;
		if (sc_size == 0) {
			//sc_size = (512+16) * 1024 * 1024
			sc_size = 512 * 1024 * 1024;
			if (dptr2 == nullptr)dptr2 = new DPTR2_t;
			allocateSC(*dptr2,sc_size);
		}
#endif

		return [&](VkCommandBuffer cmd, VkPipelineLayout draft) {
			auto  bindptr = (KT_t*)dptr.gptr();
			vkCmdPushConstants(cmd, draft, VK_SHADER_STAGE_ALL, 0, 8, &bindptr);
#ifdef PUSH_POOL_SC
			auto  bindptr2 = dptr2->gptr();
			vkCmdPushConstants(cmd, draft, VK_SHADER_STAGE_ALL, 8, 8, &bindptr2);
#endif
#ifdef PUSH_POOL_IS
			auto  bindptr3 = (BYTE*)dptr2->gptr() + 8;
			vkCmdPushConstants(cmd, draft, VK_SHADER_STAGE_ALL, 16, 8, &bindptr3);
#endif
			return true;
		};


	};

	return Upload;

}





