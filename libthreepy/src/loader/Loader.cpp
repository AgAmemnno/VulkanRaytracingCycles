#include "pch_three.h"
#include "Loader.h"
#include "core/common.hpp"




Loader::Loader() {
	manager = new LoadingManager;
	manager->init();
	hasManager = true;
	init();
};
Loader::Loader(LoadingManager* _manager) {
	manager = _manager;
	hasManager = false;
	///_manager = nullptr;
	init();
	};
Loader::~Loader() {
	if (hasManager) {
		delete manager;
		hasManager = false;
	}
};

void Loader::init() {
	crossOrigin = "anonymous";
	path = "";
	resourcePath = "";
};



