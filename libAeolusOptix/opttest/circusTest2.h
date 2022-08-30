#pragma once

#ifndef CIRCUS_TEST2_VK_H
#define CIRCUS_TEST2_VK_H
#include "types.hpp"
#include "working.h"
#include  "circusTest.h"

#include "MEM_guardedalloc.h"
#define  TEST_LOOP   100000
#define globalW  512
#define globalH   512

#define GTEST_CIRCUS

#define VKMM_ALLOC
#define NUM_BLOCKS 10

static bool prepared = false;
static bool schain_ready  = false;
static bool resized   = true;
std::function<void(WPARAM)>   key_handle;
std::function<void(bool r,UINT w,UINT h)>  windowResize;

bool      materialNeedsUpdate = false;

static void mem_error_cb(const char* errorStr)
{
	fprintf(stderr, "%s", errorStr);
	fflush(stderr);
}
enum class SPIRVTarget
{
	opengl,
	vulkan,
	vulkan11,
	vulkan12,
};
enum class ShaderLang
{
	glsl,
	hlsl,
	spvasm,
};
enum class ShaderStage
{
	vert,
	tesscontrol,
	tesseval,
	geom,
	frag,
	comp
};

void CompileShaderToSpv(const std::string& source_text, SPIRVTarget target,
	ShaderLang lang, ShaderStage stage, const char* entry_point, std::string name,
	const std::map<std::string, std::string>& macros)
{
	std::vector<uint32_t> ret;


	const  std::string path = "D:/C/Aeoluslibrary/data/shaders/tmp/";

	std::string infile = path + name + ".glsl";
	std::string outfile = path + name + ".spv";

	std::string command_line;
	command_line = "glslangValidator  -g ";
	command_line += " --entry-point ";
	command_line += entry_point;

	if (lang == ShaderLang::hlsl)
		command_line += " -D";

	for (auto it : macros)
		command_line += " -D" + it.first + "=" + it.second;

	switch (stage)
	{
	case ShaderStage::vert: command_line += " -S vert"; break;
	case ShaderStage::frag: command_line += " -S frag"; break;
	case ShaderStage::tesscontrol: command_line += " -S tesscontrol"; break;
	case ShaderStage::tesseval: command_line += " -S tesseval"; break;
	case ShaderStage::geom: command_line += " -S geom"; break;
	case ShaderStage::comp: command_line += " -S comp"; break;
	}

	if (target == SPIRVTarget::opengl)
		command_line += " -G --target-env opengl";
	else if (target == SPIRVTarget::vulkan11)
		command_line += " -V --target-env vulkan1.1";
	else if (target == SPIRVTarget::vulkan12)
		command_line += " -V --target-env vulkan1.2";
	else if (target == SPIRVTarget::vulkan)
		command_line += " -V --target-env vulkan1.0";

	command_line += " -o ";
	command_line += outfile;
	command_line += " ";
	command_line += infile;

	{
		FILE* f = fopen(infile.c_str(), "wb");
		if (f)
		{
			fwrite(source_text.c_str(), 1, source_text.size(), f);
			fclose(f);
		}
	}


	FILE* pipe = _popen(command_line.c_str(), "r");

	if (!pipe)
	{
		printf("Couldn't run  to compile shaders.");
		return;
	}

	Sleep(100);


	int code = _pclose(pipe);

	if (code != 0)
	{
		printf("Invoking  failed.");
		return;
	}


	///unlink(infile.c_str());
	///unlink(outfile.c_str());

	return;
}

template <typename T>
inline T AlignUp(T x, T a)
{
	return (x + (a - 1)) & (~(a - 1));
}

template <typename T, typename A>
inline T AlignUpPtr(T x, A a)
{
	return (T)AlignUp<uintptr_t>((uintptr_t)x, (uintptr_t)a);
}

#ifndef WITH_KERNEL_SSE2
#define WITH_KERNEL_SSE2
#define WITH_KERNEL_SSE3
#define WITH_KERNEL_SSE41
#define WITH_KERNEL_AVX
#define WITH_KERNEL_AVX2
#endif

#include "kernel/kernel.h"
#include "kernel/kernel_compat_cpu.h"
#include "kernel/kernel_types.h"
#include "kernel/split/kernel_split_data.h"
#include "kernel/kernel_globals.h"
#include "kernel/kernel_adaptive_sampling.h"
#include "kernel/filter/filter.h"

#include "render/buffers.h"
#include "render/coverage.h"

#include "device/device.h"
#include "device/device_denoising.h"
#include "device/device_intern.h"
#include <device/device_utils.h>

#include  "aeolus/SwapChain.h"



LRESULT CALLBACK WndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	static bool resizing = false;
	switch (uMsg)
	{
	case WM_CLOSE:
		prepared = false;
		DestroyWindow(hWnd);
		PostQuitMessage(0);
		break;
	case WM_SIZE:
		if ((prepared) && (wParam != SIZE_MINIMIZED))
		{
			if ((resizing) || ((wParam == SIZE_MAXIMIZED) || (wParam == SIZE_RESTORED)))
			{
				printf("resize  (%u %u)   resizing %d SIZE_MAXIMIZED %d  SIZE_RESTORED  %d  \n", LOWORD(lParam), HIWORD(lParam), (resizing), (wParam == SIZE_MAXIMIZED), (wParam == SIZE_RESTORED));
				windowResize(resizing,LOWORD(lParam) ,HIWORD(lParam));
			}
		}
		break;
	case WM_GETMINMAXINFO:
	{
		LPMINMAXINFO minMaxInfo = (LPMINMAXINFO)lParam;
		minMaxInfo->ptMinTrackSize.x = 64;
		minMaxInfo->ptMinTrackSize.y = 64;
		break;
	}
	case WM_ENTERSIZEMOVE:
		resizing = true;
		break;
	case WM_EXITSIZEMOVE:
		resizing = false;
		break;
	case WM_KEYDOWN:
		key_handle(wParam);
		break;
	}

	return (DefWindowProc(hWnd, uMsg, wParam, lParam));
}

int  Aeolus_CreateOtank(std::string  Mode) {

	static std::unordered_map< uintptr_t, uint32_t>  map;
	static long  mutex = 0;
	using cis = std::pair<const uintptr_t, uint32_t>;
	static  bool ini = true;
	static  bool VRINIT = false;
	static  int   version = 0;

	version++;
	if (ini) {
		map.reserve(100);
		mutex = 0;
		ini = false;
	}
	if (Mode == "CTX") {

		ContextVk* ctx = nullptr;
		if ($ctx == nullptr) {
			ctx = new ContextVk(globalW, globalH);
			{
				ctx->initialize();
				ctx->set$();
			}
		}

		if ($ctx != nullptr)  	$tank.add(std::move($ctx));
		else	$tank.add(std::move(ctx));


	}
	else if (Mode == "ALL") {

		{

			HINSTANCE  hInstance;
			hInstance = ::GetModuleHandle(NULL);
			WindowVk* win = new WindowVk;
			win->setSize(globalW, globalH);
			win->setupWindow(hInstance, &WndProc, "develop_" + std::to_string(version));
			$tank.add(std::move(win));

			ContextVk* ctx = nullptr;
			if ($ctx == nullptr) {
				ctx = new ContextVk(globalW, globalH);
				{
					ctx->initialize();
					ctx->set$();
				}
			}
			ObjectsVk* obj = new  ObjectsVk;
			ImagesVk* img = new  ImagesVk;
			VisibleObjectsVk* vobj = new  VisibleObjectsVk;
			AttachmentsVk* atta = new  AttachmentsVk(globalW, globalH, 2);
			{
				atta->createMultiViewColorDepthWithResolution();
			}


			{

				if ($ctx != nullptr)  	$tank.add(std::move($ctx));
				else	$tank.add(std::move(ctx));

				$tank.add(std::move(obj));
				$tank.add(std::move(img));
				$tank.add(std::move(vobj));
				$tank.add(std::move(atta));

			}



			{

				des.ToDoList(
					[atta = std::move(atta)](bool del) mutable {
					log_cirt(" AttachmentsVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), atta);
					if (del) {
						atta->destroy();
						types::deleteRaw(atta);
					}
					return !(atta == nullptr);
				});

				des.ToDoList(
					[img = std::move(img)](bool del) mutable {
					log_cirt("ImagesVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), img);
					if (del) {
						types::deleteRaw(img);
					}
					return !(img == nullptr);
				});

				des.ToDoList(
					[vobj = std::move(vobj)](bool del) mutable {
					log_cirt("VisibleObjectsVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), vobj);
					if (del) {

						types::deleteRaw(vobj);
					}
					return !(vobj == nullptr);
				});
				des.ToDoList(
					[obj = std::move(obj)](bool del) mutable {
					log_cirt("ObjectsVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), obj);
					if (del) {
						types::deleteRaw(obj);
					}
					return !(obj == nullptr);
				});

				des.ToDoList(
					[win = std::move(win)](bool del) mutable {
					log_cirt("WindowVk do %s .  Contents  %p  \n", ((del) ? "Delete" : "Valid"), &win);
					if (del) {
						types::deleteRaw(win);
					}
					return !(win == nullptr);
				});

			}

		}


		return 0;

	}


	return 0;
};
inline Matrix4* Look_at(Matrix4& mat, const Vector3& eye, const Vector3& center, const Vector3& up)
{
	///matrix4<T> M;
	Vector3  x, y, z;

	// make rotation matrix

	// Z vector
	z.x = eye.x - center.x;
	z.y = eye.y - center.y;
	z.z = eye.z - center.z;
	z.normalize();

	// Y vector
	y.x = up.x;
	y.y = up.y;
	y.z = up.z;

	// X vector = Y cross Z
	x.crossVectors(&y, &z);

	// Recompute Y = Z cross X
	y.crossVectors(&z, &x);

	// cross product gives area of parallelogram, which is < 1.0 for
	// non-perpendicular unit-length vectors; so normalize x, y here
	x.normalize();
	y.normalize();
	_FVAL* a = mat.elements;
	a[0] = x.x; a[4] = x.y; a[8] = x.z; a[12] = -x.x * eye.x - x.y * eye.y - x.z * eye.z;
	a[1] = y.x; a[5] = y.y; a[9] = y.z; a[13] = -y.x * eye.x - y.y * eye.y - y.z * eye.z;
	a[2] = z.x; a[6] = z.y; a[10] = z.z; a[14] = -z.x * eye.x - z.y * eye.y - z.z * eye.z;
	a[3] = _FVAL(0); a[7] = _FVAL(0); a[11] = _FVAL(0); a[15] = _FVAL(1);
	return &mat;
}


class CircusTest{
	public:
				SwapChainVk * swapChain = nullptr;
				bool    tearDown = false;
				bool    ctxDestroy = false;
				bool    loopBreak  = false;
				bool    no_render = false;

		void Main();
		template<class T>
		int DumpSC(int sizeX = 512,int sizeY= 512)
		{

			uintptr_t sizeT = ShaderClosure_MAX_Size;
			const char* file = AEOLUS_DATA_DIR "\\data\\profile\\weight.json";

			auto dst = memVk.bamp["sc_pool"].alloc->GetMappedData();
			auto scptr = (T*)((BYTE*)dst + sizeT * 2228224);



			std::ofstream csv(file);
#define FORMAT_WEIGHT csv << std::format("[ {:6.3f},  {:6.3f}, {:6.3f}, {:6.3f} ] ,\n",  scptr->weight.x, scptr->weight.y, scptr->weight.z, scptr->weight.w);
#define FORMAT_WEIGHT_END csv << std::format("[ {:6.3f},  {:6.3f}, {:6.3f}, {:6.3f} ] ]\n",  scptr->weight.x, scptr->weight.y, scptr->weight.z, scptr->weight.w);
			if (csv)
			{
				int idx = 0;
				csv << "[\n";
				for (int y = 0; y < sizeX; y++) {	
					idx = sizeX * y;
					for (int x = 0; x < sizeY; x++) {
						//printf("INDEX  %d  X %d Y %d    [ %f , %f , %f  ,%f ] \n", idx, x, y, scptr->weight.x, scptr->weight.y, scptr->weight.z, scptr->weight.w);
						if (y == sizeY - 1) {
							if (x == sizeX - 1) FORMAT_WEIGHT_END
							else  FORMAT_WEIGHT
						}
						else FORMAT_WEIGHT
						
						scptr  = (T*)((BYTE*)scptr + sizeT);
						idx++;
					}	
				}
			}
			else {
				printf("Error Not Found  Directory  %c \n", file);
			}
		
			csv.close();
#undef  FORMAT_WEIGHT
#undef  FORMAT_WEIGHT_END
			return 0;
		}

		template<class T>
		int DumpSCByIndex(uintptr_t index)
		{
			uintptr_t sizeT = ShaderClosure_MAX_Size;
			
			const char* file = AEOLUS_DATA_DIR "\\data\\profile\\index.json";
			auto dst = memVk.bamp["sc_pool"].alloc->GetMappedData();
			auto scptr = (T*)((BYTE*)dst + sizeT * 2228224);
			
			std::ofstream csv(file);
#define FORMAT_WEIGHT csv << std::format("[ {:6.3f},  {:6.3f}, {:6.3f}, {:6.3f} ]\n",  scptr->weight.x, scptr->weight.y, scptr->weight.z, scptr->weight.w);
			if (csv)
			{
				scptr = (T*)((BYTE*)scptr + sizeT*index );
			    FORMAT_WEIGHT
			}
			else {
				printf("Error Not Found  Directory  %c \n", file);
			}
			csv.close();
#undef  FORMAT_WEIGHT
			return 0;
		}


		template<class T>
		int DumpDeviceProp(T& prop)
		{
			const char* file = AEOLUS_DATA_DIR "\\data\\profile\\deviceprop.json";
			std::ofstream csv(file);
			if (csv)
			{
					csv << std::format(" {{ \"subgroupSize\" : {:d}, \"shaderSMCount\" :{:d}, \"shaderWarpsPerSM\" :{:d}  }} \n", prop.subgroupSize, prop.shaderSMCount, prop.shaderWarpsPerSM);
			}
			else {
				printf("Error Not Found  Directory  %c \n", file);
			}
			csv.close();
			return 0;
		}

		void SetUp() {
			
			log_cirt("<<<<<<<<<<<<<<<<<<<< SetUP >>>>>>>>>>>>>>>>>>>>>>>\n");
			swapChain = nullptr;
			tearDown = false;;
		};

		void TearDown() {
			if (swapChain)
			{

				delete swapChain;
			}
			if (tearDown) {
				$des.Holocaust();
				GetCTX($ctx)
					$tank.flush();

				if (ctxDestroy) {
					$ctx->shutdown();
					types::deleteRaw($ctx);

				}
			}
		}
		void  InitCircus() {
			tearDown = true;
			loopBreak = false;
			no_render = false;
			printf(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   Init Circus   ");
			$des.Dispatch();
			PolicyAllocateFree();
			Aeolus_CreateOtank("ALL");
			printf(" >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   Otank Stored  ");

		};

		ImmidiateRTCmd<ImmidiateCmdPool3>* rtcm;
		template<class M>
		bool  makeRT(M & mat, std::vector<MIVSIvk> & images)
		{
			static bool init = true;
			if (init) {
				rtcm.allocCmd(2);
				init = false;
			}

			rtcm.cmdSet(0);


			VkCommandBuffer cmd = rtcm.begin(0,{.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
																			 .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT });

			mat.make(cmd, images);

			VK_CHECK_RESULT(vkEndCommandBuffer(cmd));


			return true;
		};
		VkInstance getInstance() {
			return $instance;
		}
		bool  nextFrame()
		{
			// Acquire the next image from the swap chain

			VkResult result = swapChain->acquireNextImage(&swapChain->current.frame);
			if ((result == VK_ERROR_OUT_OF_DATE_KHR) || (result == VK_SUBOPTIMAL_KHR)) {
				////printf("Next Frame Error or Suboptimal  \n");
				return false;
			}
			else {
				VK_CHECK_RESULT(result);
			}
			return true;
		}
		void  submitFrame()
		{



			static VkPipelineStageFlags graphicsWaitStageMasks[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
			VkSemaphore graphicsWaitSemaphores[] = { swapChain->semaphores.presentComplete };

			//VK_CHECK_RESULT(vkWaitForFences($device, 1, &swapChain->waitFences[swapChain->current.frame], VK_TRUE, UINT64_MAX));

			VkSubmitInfo submitInfo{};
			submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
			submitInfo.pWaitDstStageMask = graphicsWaitStageMasks;


			VK_CHECK_RESULT(vkResetFences($device, 1, &swapChain->waitFences[swapChain->current.frame]));
			submitInfo.pWaitSemaphores = graphicsWaitSemaphores;
			submitInfo.waitSemaphoreCount = 1;/// static_cast<uint32_t>(wire.size());
			submitInfo.signalSemaphoreCount = 1;
			submitInfo.pSignalSemaphores = &swapChain->semaphores.renderComplete;
			submitInfo.commandBufferCount = 1;
			submitInfo.pCommandBuffers = &swapChain->drawCmdBuffers[swapChain->current.frame];
			VK_CHECK_RESULT(vkQueueSubmit($queue, 1, &submitInfo, swapChain->waitFences[swapChain->current.frame]));

			VkResult result = swapChain->queuePresent($queue, swapChain->current.frame, swapChain->semaphores.renderComplete);
			if (!((result == VK_SUCCESS) || (result == VK_SUBOPTIMAL_KHR))) {
				if (result == VK_ERROR_OUT_OF_DATE_KHR) {
					printf("Next Frame Error or Suboptimal  \n");
					return;
				}
				else {
					VK_CHECK_RESULT(result);
				}
			}


			do {
				result = vkWaitForFences($device, 1, &swapChain->waitFences[swapChain->current.frame], VK_TRUE, 0.1_fr);
			} while (result == VK_TIMEOUT);


			VK_CHECK_RESULT(vkQueueWaitIdle($queue));

		}
		void  submitFrameRT()
		{
			VkResult result;



			VkSubmitInfo submitInfo{};
			submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
			VkCommandBuffer cmd = (*rtcm->cmds)[0];

			submitInfo.waitSemaphoreCount = 0;/// static_cast<uint32_t>(wire.size());
			submitInfo.signalSemaphoreCount = 0;
			submitInfo.commandBufferCount = 1;
			submitInfo.pCommandBuffers = &cmd;

			VK_CHECK_RESULT(vkResetFences($device, 1, &rtcm->fence));
			VK_CHECK_RESULT(vkQueueSubmit($queue, 1, &submitInfo, rtcm->fence));

			do {
				result = vkWaitForFences($device, 1, &rtcm->fence, VK_TRUE, 0.1_fr);
			} while (result == VK_TIMEOUT);



			static VkPipelineStageFlags graphicsWaitStageMasks[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
			VkSemaphore graphicsWaitSemaphores[] = { swapChain->semaphores.presentComplete };



			VK_CHECK_RESULT(vkResetFences($device, 1, &swapChain->waitFences[swapChain->current.frame]));
			submitInfo.pWaitDstStageMask = graphicsWaitStageMasks;
			submitInfo.pWaitSemaphores = graphicsWaitSemaphores;
			submitInfo.waitSemaphoreCount = 1;/// static_cast<uint32_t>(wire.size());
			submitInfo.signalSemaphoreCount = 1;
			submitInfo.pSignalSemaphores = &swapChain->semaphores.renderComplete;
			submitInfo.commandBufferCount = 1;
			submitInfo.pCommandBuffers = &swapChain->drawCmdBuffers[swapChain->current.frame];
			VK_CHECK_RESULT(vkQueueSubmit($queue, 1, &submitInfo, swapChain->waitFences[swapChain->current.frame]));

			 result = swapChain->queuePresent($queue, swapChain->current.frame, swapChain->semaphores.renderComplete);
			if (!((result == VK_SUCCESS) || (result == VK_SUBOPTIMAL_KHR))) {
				if (result == VK_ERROR_OUT_OF_DATE_KHR) {
					printf("Next Frame Error or Suboptimal  \n");
					return;
				}
				else {
					VK_CHECK_RESULT(result);
				}
			}


			do {
				result = vkWaitForFences($device, 1, &swapChain->waitFences[swapChain->current.frame], VK_TRUE, 0.1_fr);
			} while (result == VK_TIMEOUT);


			VK_CHECK_RESULT(vkQueueWaitIdle($queue));

		}
		template<class TMap,class Mat>
		bool enterRT(TMap & mat, std::function<void(PipelineConfigure&)> mat_init,Mat & rtmat, brunch::RTVkty & rtvk) {

			log_cirt(" ...................................Enter Circus [%p] \n", this);


			int cnt = -1;
			std::chrono::time_point<std::chrono::steady_clock>  now, start;

			thread_local LONG prev;

			thread_local  long long routine = 0;
			thread_local UINT32 tID = _threadid;

			///process();

			thread_local uint32_t eyeId = 0;

			WindowVk* win = nullptr;
			if (win == nullptr) {
				if (!$tank.takeout(win, 0)) {
					log_bad(" not found  WindowVk.");
				};
			};

			static bool ini = true;
			MSG msg;
			bool quitMessageReceived = false;


			swapChain = new SwapChainVk;
			swapChain->connect();
			swapChain->initSurface(win->windowInstance, win->window);
			bool  vsync = false;
		
			schain_ready = true;
			windowResize = [&](bool r,UINT w, UINT h) {

				if (!prepared)return;
				prepared = false;
				resized = true;
				// Ensure all operations on the device have been finished before destroying resources
				vkDeviceWaitIdle($device);
				if(r)swapChain->create(w, h, false);
				else swapChain->create(win->width, win->height, false);
				vkDeviceWaitIdle($device);

				prepared = true;

			};

			if (prepared) {
				SetWindowPos(win->window, 0, 0, 0, win->width, win->height, SWP_SHOWWINDOW | SWP_NOMOVE);
			}else	 swapChain->create(win->width, win->height, vsync);

			PipelineConfigure   config = {
				   .vkRP = swapChain->renderPass,
				   .vkPC = swapChain->pipelineCache,
			};

			mat_init(config);

			int cmdNums = 3;
			materialNeedsUpdate = true;

			rtvk.setRenderGroup(arth::eSUBMIT_MODE::Inline | arth::eSUBMIT_MODE::OneTime, swapChain, { &rtmat}, { &mat});

			prepared = true;
			while (cnt < 60 * TEST_LOOP) {
				if (!no_render) {
					cnt++;
					if (cnt % 60 == 0) {

						now = std::chrono::high_resolution_clock::now();
						if (routine > 0) {
							log_cirt(" [%x] execution Critical    time    %.5f    ms     routine  %d \n ", tID, (float)(std::chrono::duration<double, std::milli>(now - start).count()), routine);
							routine = 0;
						}
						start = now;
					};
					while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
						TranslateMessage(&msg);
						DispatchMessage(&msg);
						///printf(" msg  %u     min %u   max %u \n ", msg.message, EVENT_MIN, EVENT_MAX);
						if (msg.message == WM_QUIT) {
							quitMessageReceived = true;
							delete rtcm;
							log_cirt("QUIT MESSAGE COME.");
							return true;
						}
					}
					if (materialNeedsUpdate) {
						for (int i = 0; i < 3; i++)swapChain->cmdUpdate[i] = true; materialNeedsUpdate = false;
					}
					if (nextFrame()) {

						rtvk.submitSwapChain();
						DumpSCByIndex<ShaderClosure_MAX>(512*512);
						DumpSC<ShaderClosure_MAX>();
					};
					routine++;
					eyeId = (eyeId + 1) % 2;
				}
				if (loopBreak)break;
				rtmat.updateCB();
			}


			delete rtcm;

			return true;
		};
	};


#endif