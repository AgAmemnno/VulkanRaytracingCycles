#include "pch.h"
#include "working.h"


PipelineVk::PipelineVk() :pth(0) {};
PipelineVk::~PipelineVk() { destroy(); };
void PipelineVk::destroy() {

	for (int i = 0; i < pth; i++) {
		Mem(PvSvk,SIZE_PvS).cache[i].dealloc();
	};

};
