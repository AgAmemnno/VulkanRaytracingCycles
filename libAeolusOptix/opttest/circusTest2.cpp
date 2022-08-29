
//#undef FMT_USE_NONTYPE_TEMPLATE_ARGS


#include "pch.h"
#include "aeolus.hpp"
#include "vulkan/vulkan.hpp"
#define WITH_REDIS
#define TEST_NO 7


#include "working.h"
//#define TESTBUILD



#define FMT_USE_NONTYPE_TEMPLATE_ARGS 0

#ifdef TESTBUILD



#include <OpenImageIO/paramlist.h>
#include <OpenImageIO/typedesc.h>
#include <OpenImageIO/ustring.h>




using namespace OpenImageIO_v2_1;

std::string ustring::empty_std_string;


#include "rapidjson/document.h"
#include "rapidjson/istreamwrapper.h"
using namespace rapidjson;
#include  "circusTest2.h"
#include  "RedisUtils.h"


int rj1()
{
	std::string json_str = "{\"hello\": \"world\", "
		"\"t\": true, "
		"\"f\": false, "
		"\"n\": null, "
		"\"i\": 123, "
		"\"pi\": 3.1416, "
		"\"a\": [1, 2, 3, 4]}";

	Document doc;
	doc.Parse(json_str.c_str());

	return 0;
}


int rj2()
{

	//OCIO_VERSION_FULL_STR

	return 0;
}


int main(int argc, char** argv)
{
	rj1();
	rj2();

	/*using namespace OpenImageIO_v2_1;
	//ustring ust("asdfadf");


	TypeDesc type = TypeFloat;
	assert(type == TypeFloat);

	printf("dsafadsfadfadf  %s  ", ust.c_str());
	*/
	return 0;
}

#else


#define DATA_JSON


#include <OpenImageIO/ustring.h>
using namespace OpenImageIO_v2_1;

std::string ustring::empty_std_string;


#include "rapidjson/document.h"
#include "rapidjson/istreamwrapper.h"
using namespace rapidjson;
vkmm::MemoryVk memVk;


#include  "circusTest2.h"
#include  "RedisUtils.h"
RedisUtils bl;

#include  "BlTextures.h"
#include  "bvh_vulkan.h"
#include  "bufferreference2_t.h"

static STATS_AUX  stat_aux;
enum  class WaitMode {
	CREATOR_DEBUG,
	CONSOLE,
	SCREEN_SELF,
	ALL
};
WaitMode  WMODE = WaitMode::ALL;
char     InfoConsole = 'a';
#define KERNEL_TYPE  1




unsigned __stdcall DoConsole(LPVOID lpx)
{
	thread_local bool loop = true;
	thread_local LONG prev;
	thread_local char ch;
	while (loop) {
		bool ret = false;
		ch = getchar();
		printf("InfoConsole>>%c\n", ch);

		switch (ch)
		{
		case 'Q':
			InfoConsole = ch;
			WMODE = WaitMode::CONSOLE;
			loop = false;
			ReleaseSemaphore(bl.binfo.signalinner, 1, &prev);
			printf("Quit release  prev  %d \n", prev);
			break;
		case 'R':
		case 'T':
			InfoConsole = ch;
			WMODE = WaitMode::CONSOLE;
			ReleaseSemaphore(bl.binfo.signalinner, 1, &prev);
			/*
		case 'S':
			ret = ReleaseSemaphore(bl.binfo.signal12345, 1, &prev);
			printf(" release  %s   prev  %d   \n ", ret ? "true" : "false", prev);
			break;
		case 'W':
			ret = ReleaseSemaphore(bl.binfo.signal12345, 3, &prev);
			printf(" release  %s   prev  %d   \n ", ret ? "true" : "false", prev);
			break;
			*/
		default:
			break;
		};
	}
	return 0;
}



struct WaitManager {
	HANDLE  hnd_con;
	void  SetUp() {
	
		hnd_con = (HANDLE)_beginthreadex(
			NULL,
			1,
			DoConsole,
			(LPVOID)0,
			0,///CREATE_SUSPENDED,
			NULL
		);
	};
	void  Exit() {
		bl.binfo.br12345 = true;
		ReleaseSemaphore(bl.binfo.signal12345, 1, NULL);
		Sleep(100);
		
		CloseHandle(hnd_con);
	};
	typedef std::function<void(void)>  uf_type;
	typedef std::function<void(WPARAM wP)> wh_type;

	uf_type updateFunc;
	template<class MatTy, class PMatTy, class RendTy, class BvhTy, class TexTy, class DbTy, class KerBufTy, class MemTy, class BgTy>
	void genUpdateFunc(MatTy& mat, PMatTy& tone, RendTy& rtVk, BvhTy& bvh, TexTy& bltex, DbTy& bl, KerBufTy& kb, MemTy& memVk, BgTy& lm) {
		static VisibleObjectsVk* vobjVk = nullptr;
		if (!vobjVk) {
			if (!$tank.takeout(vobjVk, 0)) {
				log_mat(" Not found vobjVk\n");
			};
		}
		UniformVk uniform;
		uniform.createUBO(vobjVk, 16);
		auto upload = pushReferences2(bvh);

#ifdef PUSH_POOL_SC
		static bool sc_pool = true;
#else
		static bool sc_bool = false;
#endif
		static WindowVk* win = nullptr;
		if (win == nullptr) {
			if (!$tank.takeout(win, 0)) {
				log_bad(" not found  WindowVk.");
			};
		};

		/// initial update
		{
			mat.cbpush = upload(bvh, bltex);

			if (KERNEL_TYPE == 0)mat.build_process3(bvh, sc_pool);
			else if (KERNEL_TYPE == 1)mat.build_process5(bvh, sc_pool);
			kb.writeDescsriptorSet_Kernel(2, mat);
			if (TEX_DESC_TYPE == TEX_DESC_SEPARATE_SAMPLER) {
				mat.writeOutDescriptorSets(bltex.iinfo, bltex.samplerDesc, 3);
			}
			else if (TEX_DESC_TYPE == TEX_DESC_COMBINED_SAMPLER) {
				mat.writeOutDescriptorSets(bltex.iinfo, 3);
			}

#ifdef DATA_JSON
			bl.upload_KD_json(memVk);
#else
			bl.upload_KD(memVk);
#endif

			lm.build(rtVk, mat, bl.kd.background);
			mat.bgInfo.bg_make = false;

#ifdef DATA_JSON
			bl.clean_json("");
#endif

			rtVk.createImage((UINT32)bl.kd.cam.width, (UINT32)bl.kd.cam.height, 1);
			mat.writeOutDescriptorSets<0>(uniform.ubo.info, rtVk.images[0]);
			rtVk.setMRT({ 0 });
			if ( (win->width != bl.kd.cam.width) | (win->height != bl.kd.cam.height)) {
				win->width = (UINT32)bl.kd.cam.width; win->height = (UINT32)bl.kd.cam.height;
				prepared = true;
			}
			mat.buffer_pre = [&]() { kb.initialize(); };

		}

		updateFunc = [&]() {

			mat.cbpush = upload(bvh, bltex);
			kb.writeDescsriptorSet_Kernel(2, mat);

			if (TEX_DESC_TYPE == TEX_DESC_SEPARATE_SAMPLER) {
				mat.writeOutDescriptorSets(bltex.iinfo, bltex.samplerDesc, 3);
			}
			else if (TEX_DESC_TYPE == TEX_DESC_COMBINED_SAMPLER) {
				mat.writeOutDescriptorSets(bltex.iinfo, 3);
			}


			bl.upload_KD_json(memVk);
			lm.build(rtVk, mat, bl.kd.background);
			mat.bgInfo.bg_make = false;

			if (!rtVk.extentImage(0, (UINT32)bl.kd.cam.width, (UINT32)bl.kd.cam.height)) {

				rtVk.createImage((UINT32)bl.kd.cam.width, (UINT32)bl.kd.cam.height, 1);
				rtVk.setMRT({ 0 });
				mat.writeOutDescriptorSets<0>(uniform.ubo.info, rtVk.images[0]);
				tone.writeout(rtVk.images[0]);
				if (schain_ready)prepared = true;
				win->width = (UINT32)bl.kd.cam.width; win->height = (UINT32)bl.kd.cam.height;
				SetWindowPos(win->window, 0, 0, 0,(int) bl.kd.cam.width, (int)bl.kd.cam.height, SWP_SHOWWINDOW | SWP_NOMOVE);

			}

			mat.rebuild_process2(bvh);
			mat.buffer_pre = [&]() { kb.initialize(); };


		};





	}
	template<class StatTy, class DbTy, class KerBufTy, class MemTy>
	uf_type genMatUpdateFunc(StatTy& stat_aux, DbTy& bl, KerBufTy& kb, MemTy& memVk, bool& loopBreak, bool& no_render) {
		static void* dst = nullptr;
		static KernelGlobals_PROF* kg = nullptr;
		static bool pixel_compare = true;
		static  int TestRender = 10000;
		return [&]() {

		
			if (pixel_compare) {
				dst = memVk.bamp["kerneldata"].alloc->GetMappedData();
				kg = (KernelGlobals_PROF*)((BYTE*)dst + kb.kginfo.offset);
				int* counter = (int*)((BYTE*)dst + kb.alloinfo.offset);
				stat_aux.pixel_compare(kg, counter);
				ReleaseSemaphore(bl.binfo.signalinner2, 1, NULL);
				pixel_compare = false;
			};
			if (TestRender > 0) {
				TestRender--;
			}
			else {
				if (!loopBreak)WaitForSingleObject(bl.binfo.signalinner, INFINITE);
				if (WMODE == WaitMode::CREATOR_DEBUG) {
					memset((BYTE*)dst + kb.alloinfo.offset, 0, kb.allo_size);
					kg->pixel.x = stat_aux.pixel.x; kg->pixel.y = stat_aux.pixel.y;
					/// break pixel
					if (kg->pixel.x == 302 && kg->pixel.y == 219) {
						while (true) {
							char ch = getchar();
							if (ch == 'q')break;
						}
					}
					pixel_compare = true;
				}
				if (WMODE == WaitMode::CONSOLE) {
					switch (InfoConsole) {
					case 'T':
						TestRender = 1000;
						break;
					case 'R':break;
					case 'Q':
						loopBreak = true;
						break;
					default:
						log_bad("Unknown Charactor come . \n");
						break;
					}
				}
			}

			no_render = false;
			/// <summary>
			/// TODO Update data
			/// </summary>
			if (false) {
				if (bl.bnet.needsUpdate) {
					updateFunc();
					bl.bnet.needsUpdate = false;
				}
			}
			else {
				no_render = true;
			}

		};
	};

	template<class PMatTy>
	wh_type genWindowHandleFunc(PMatTy& tone) {

		return  [&](WPARAM wP) {
			printf("  key  %u     \n", (UINT)wP);
			switch (wP)
			{
			case 'U':
				updateFunc();
				break;
			case 'W':
				tone.push4.tonemapper = (tone.push4.tonemapper + 1) % 4;
				printf("  W  toneMapper %d \n", tone.push4.tonemapper);
				break;
			case 'S':
				printf("  S  \n");
				break;
			case 'A':
				if (tone.push4.tonemapper == 2) {
					tone.push4.exposure -= 0.1f;
					printf("  A   exposure %f \n", tone.push4.exposure);
				}
				else {
					tone.push4.gamma -= 0.1f;
					printf("  A   gamma  %f \n", tone.push4.gamma);
				}
				materialNeedsUpdate = true;
				break;
			case 'D':
				if (tone.push4.tonemapper == 2) {
					tone.push4.exposure += 0.1f;
					printf("  A   exposure %f \n", tone.push4.exposure);
				}
				else {
					tone.push4.gamma += 0.1f;
					printf("  A   gamma  %f \n", tone.push4.gamma);
				}
				materialNeedsUpdate = true;

				break;
			}
		};
	};
};

void CircusTest::Main() {
	

#ifdef DATA_JSON
	bl.init();
#endif



	WaitManager wam;
	brunch::RTVkty                   rtVk;
	rtVk.SetFormat(VK_FORMAT_R8G8B8A8_UNORM);   ///rtVk.SetFormat(VK_FORMAT_R32G32B32A32_SFLOAT);
	RTShadowMaterialVk        mat(&rtVk.master.cmdVk, &$pallocator);
	mat.init(TEX_DESC_TYPE + 1, int(true));
	Material2Vk  tone;
	tone.SetUp(Material2Vk::eConfigu_PIPE::MODE_TONEMAPPING);
	
	auto mat_init = [&](PipelineConfigure& config) {
		tone.createPipeline(config);
		tone.writeout(rtVk.images[0]);
	};

	BLTextures                           bltex;
	ccl::BVHVulkan bvh(&$pallocator, &bl);
	///generate CallBacks 
	{
		wam.SetUp();
		wam.genUpdateFunc(mat, tone, rtVk, bvh, bltex, bl, kb, memVk, lm);
		//wam.updateFunc();
		mat.updateCB = wam.genMatUpdateFunc(stat_aux, bl, kb, memVk, loopBreak, no_render);
		key_handle = wam.genWindowHandleFunc(tone);
	}
	enterRT(tone, mat_init, mat, rtVk);
	{
#ifdef PUSH_POOL_SC
		if (dptr2 != nullptr)delete dptr2;
#endif

		wam.Exit();
		swapChain->cleanup();
		tone.dealloc();
		mat.deinit();
		rtVk.dealloc();
		memVk.deinitialize();
	}
};




int main(int argc, char** argv)
{
	CircusTest t;
	t.InitCircus();
	memVk.initialize();

	t.Main();
	
	t.TearDown();

	return 0;

}




#endif