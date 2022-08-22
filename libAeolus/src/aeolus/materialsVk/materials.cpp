#include  "pch.h"
#include "types.hpp"
#include "common.h"
#include "core/common.hpp"
#include "working.h"
#ifdef INCLUDE_MATERIAL_VKVIDEO
#include "VidMaterialVk.h"
#endif
using namespace aeo;

namespace material_com {

	
	const std::regex sfxKtx("(.*)[.]+(.*)");
	int isKtx(std::string uri) {
		std::smatch Res;
		if (std::regex_match(uri, Res, sfxKtx)) {
			size_t size = Res.size();
			if (size == 3) {
				std::ssub_match base_sub_match = Res[2];
				if ("ktx" == base_sub_match.str())return 1;
				return 0;
			}
		}
		return -1;
		///std::ssub_match base_sub_match = Res[0];
		///base_sub_match.str();
	};


	const std::regex KtxType("(.*)_(.*)_(.*).ktx");
	VkFormat KtxFormat(std::string uri) {
		std::smatch Res;
		if (std::regex_match(uri, Res, KtxType)) {
			size_t size = Res.size();
			if (size == 4) {
				std::ssub_match base_sub_match = Res[2];

				if (base_sub_match.str() == "bc3") {
					return  VK_FORMAT_BC3_UNORM_BLOCK;
				}
				if (base_sub_match.str() == "astc") {
					return VK_FORMAT_ASTC_8x8_UNORM_BLOCK;
				}
				if (base_sub_match.str() == "etc2") {
					return  VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK;
				}
				else {
					log_bad("Device does not support any compressed texture format!", VK_ERROR_FEATURE_NOT_PRESENT);
				}
				return (VkFormat)0;
			}
		}
		return VK_FORMAT_R8G8B8A8_SRGB;
	};

	static size_t MATERIAL_STAMP = types::stollu_rand(__FILE__  __TIME__);
    #define MATERIAL_RESTAMP MATERIAL_STAMP  = types::stollu_rand(__FILE__ __TIME__);
	static  uint32_t MTRID = 0;
	static ImmidiateCmd<ImmidiateCmdPool>* imcmVk = nullptr;
	static ImagesVk* imgVk = nullptr;
	int init(Material* self, PyObject* args, PyObject* kwds)
	{
		if (imgVk == nullptr) {
			if (!$tank.takeout(imgVk, 0)) {
				log_bad("tank failed to take out . \n");
			};
		};

		if (imcmVk == nullptr) {

			imcmVk = new ImmidiateCmd<ImmidiateCmdPool>;

			des.ToDoList(
				[imcm = std::move(imcmVk)](bool del) mutable {
				log_mat(" MaterialVk Static ImmidiateCmd<ImmidiateCmdPool> %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), imcm);
				if (del) {
					types::deleteRaw(imcm);
				}
				return !(imcm == nullptr);
			});

		};


		PyObject* o;
		char* _str =(char*)"";
		
		o = PyTuple_GetItem(args, 0);
		PyArg_Parse(o, "s", &_str);
		self->names->spv = std::string(_str);
		if (self->names->spv == "") {
			self->names->spv = "default";
		};
		self->names->pipeName = "";

		self->names->spz.vert = 0;
		self->names->spz.frag = 0;


		self->desc.type = "";
		self->desc.align = 0;
		self->desc.hash = 0;
		self->desc.reserveRatio = 1.f;

		self->pipe = { -1,0,0 };



		return 0;
	};

	size_t getStamp() {
		MATERIAL_RESTAMP
			return  MATERIAL_STAMP;
	}

	int texArray(Iache& iach, Material* self, PyObject* args, int st,int ed) {
		char* _str;
		long len = 0;

		if(ed ==-1) ed = (int)PyTuple_Size(args);

		std::vector<std::string> keys;
		for (int i = st; i < ed; i++) {
			PyObject* o = PyTuple_GetItem(args, i);
			PyArg_Parse(o, "s#", &_str, &len);
			keys.push_back(_str);
		}

		iach = Iache::rehash(keys[0], material_com::MATERIAL_STAMP);
		iach.format = VK_FORMAT_R8G8B8A8_SRGB;
		iach.layout  = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		iach.type    = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
		material_com::imgVk->createFromFiles(*material_com::imcmVk, keys, iach);
		return 0;

	}
	int ktxImage(Iache& iach, Material* self, PyObject* args,int num,bool cube ) {

		const UINT SMAPLER             = 0;
		const UINT STORAGE             = 1;
		const UINT STORAGE_SWAP = 2;
		const UINT CUBEMAP             = 3;

		char*  _str;
		long    len = 0;
		ssize_t nums = PyTuple_Size(args);
		PyObject* o  = PyTuple_GetItem(args, num);
		PyArg_Parse(o, "s#", &_str,&len);
		if (len == 0)return -1;
		UINT memType = 0;
		if (nums > num+1) {
			PyObject* o2 = PyTuple_GetItem(args, num+ 1);
			PyArg_Parse(o2, "k", &memType);
		};

		self->names->imageName = std::string(_str);
		iach = Iache::rehash(self->names->imageName, material_com::MATERIAL_STAMP);
		iach.format = VK_FORMAT_R8G8B8A8_SRGB;
		iach.layout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		iach.type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
		long type = isKtx(self->names->imageName);
		if (type == 1) {

			iach.format = KtxFormat(self->names->imageName);
			if (memType == CUBEMAP) {
				iach.name = self->names->imageName;
				material_com::imgVk->createCubeMapFromKtx(*material_com::imcmVk, iach);
			}
			else {
				material_com::imgVk->createFromKtx(*material_com::imcmVk, self->names->imageName, iach);
			}

		}
		else if (type == 0) {
			if(memType== SMAPLER)material_com::imgVk->createFromFile(*material_com::imcmVk, self->names->imageName, iach);
			if (memType == STORAGE_SWAP) {
				iach.layout = VK_IMAGE_LAYOUT_GENERAL;
				iach.type    = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
				iach.format = VK_FORMAT_R8G8B8A8_UINT;// VK_FORMAT_R32G32B32A32_SFLOAT;
				material_com::imgVk->createFromFileStorage(*material_com::imcmVk, self->names->imageName, iach);
			};
		};
		

		return 0;
	};
	bool getThumbNalis(gui::thumbNails& tn, Iache& iach) {
		
		MIVSIvk  _;
		material_com::imgVk->getImage(iach, _);
		tn.w  = _.w;
		tn.h  = _.h;
		tn.l   = _.l;
		return true;
	};
	bool getInfo(Iache& iach, VkDescriptorImageInfo& info) {

		MIVSIvk  _;
		material_com::imgVk->getImage(iach, _);
		info = _.Info;
		return true;
	};

};



