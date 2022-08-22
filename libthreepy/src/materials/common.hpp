#pragma once
#ifndef  MATERIAL_TYPES
#define  MATERIAL_TYPES


#include "enum.hpp"
#include "types.hpp"
#include "util/Log0.hpp"


#if defined( AEOLUS)
#include "core/canvas.h"
#elif defined(AEOLUS_VID)
#include "vulkan/vulkan.h"
#endif




#include "aeolus/vthreepy_const.h"
#include "aeolus/vthreepy_types.h"


#include "threepy_working.h"


///#define Log_NO_MAT
#ifdef  Log_NO_MAT
#define Log_mat(...)
#else
#define Log_mat(...) Log__thread(__FILE__, __LINE__, Log_FILE, __VA_ARGS__)
#endif


constexpr static size_t  FRAME_SIZE = 28;
static const char* FRAME_FORMAT = "Total %6.2f%%/ Capacity %3d%%";




class MsdfMaterial : public aeo::Material {


public:

	enum eConfigu_PIPE {
		MSDF,
		FONT,
		ALL
	};
	struct PIPE {
		VkPipeline         pipe = VK_NULL_HANDLE;
	};
	struct PIPES {
		bool                                    active = false;
		PIPE                      Next[eConfigu_PIPE::ALL];
	};
	struct Raster {
		VkCullModeFlags cullMode;
		VkFrontFace      frontFace;
	};

	PIPES                                                     pipeRoot;
	PipelineConfigure                                      configu;
	VkShaderModule                                 sh_msdf[2];
	VkShaderModule                                 sh_font[3];
	PipelineStateCreateInfoVk                           PSci;
	Canvas* font;

	///SRWLOCK  slim;
	///bool            scopedLock;
	///fon::MSDFfont* fontMaster;

};

class GuiMaterial : public aeo::Material {

public:

	enum eConfigu_GUI {
		DEFAULT,
		FILL_SAMPLE,
		FILL_ANTIALIAS,
		FILL,
		CONVEXFILL,
		CONVEXFILL_FRINGE,
		STROKE_FILL,
		STROKE_ANTIALIAS,
		STROKE_CLEAR,
		TRIANGLES,
		ALL
	};

	struct PIPE {
		VkPipeline         pipe = VK_NULL_HANDLE;
	};

	struct PIPES {
		bool                                    active = false;
		PIPE                      Next[eConfigu_GUI::ALL];
	};

	PIPES  pipeRoot[info::MAX_BLEND_OP][info::MAX_OVERLAP_OP];

	PipelineConfigure                                            configu;
	PipelineStateCreateInfoVk                                  PSci;
	VkShaderModule                             shaderModules[2];
	
	
	///MsdfMaterial* msdf;
	///gui::GUIcontext* ctx;

};


struct  BaseMaterial2Vk : public aeo::Material {

	PipelineConfigure                                      configu;
	bool load_shader = false;
	BaseMaterial2Vk() :load_shader(false) {};
	enum eConfigu_PIPE {
		MODE_SELECT,
		MODE_SKY,
		MODE_FULLSCREEN,
		MODE_FULLSCREEN2,
		MODE_TONEMAPPING,
		MODE_TONEMAPPING2,
		ALL
	};


	struct push {
		float   model[16];
		float   color[4];
	}push;

	struct push2 {
		float   model[16];
		float   color[4];
		uint32_t flag[4];
	}push2;

	struct push3 {
		float   aspect;
	}push3;

	struct push4
	{
		int   tonemapper;
		float gamma;
		float exposure;
		float pad;
	}push4 = { 2,1.,1.,0.f };

	struct push5
	{
		float size[2];
	}push5 = {{512.f,512.f} };

	virtual bool make(VkCommandBuffer cmd, VkSemaphore sema) = 0;

};

struct RTMaterial : public aeo::Material {

public:

	bool         bg_make;
	int        pipeline_flags;
	enum eConfigu_PIPE {
		MODE_PRIM,
		ALL
	};

	struct PIPE {
		VkPipeline         pipe = VK_NULL_HANDLE;
	};

	struct PIPES {
		bool                                    active = false;
		PIPE                      Next[eConfigu_PIPE::ALL];
	};

	struct Raster {
		VkPolygonMode     polygonMode;
		VkCullModeFlags   cullMode;
		VkFrontFace         frontFace;
	};

	PIPES                                                     pipeRoot;
	PipelineConfigure                                      configu;
	VkShaderModule                                      sh_rt[3];
	PipelineStateCreateInfoVk                           PSci;

	std::function<void(void)>                         updateCB;
	std::function<bool(VkCommandBuffer cmd)> makeCB;
	std::function<std::vector<VkDescriptorBufferInfo>()> getInfo;

	virtual bool makeRT(VkCommandBuffer cmd) = 0;

};



typedef  BaseMaterial2Vk PostMaterialVk;


#endif