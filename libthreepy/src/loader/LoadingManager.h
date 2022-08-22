#pragma once
#ifndef  LOADER_MANAGER_H
#define LOADER_MANAGER_H

#include <unordered_map>
#include <regex>
#include <functional>

#include "types.hpp"
#include "util/Log.hpp"
#include "Loader.h"




/**
 * @author mrdoob / http://mrdoob.com/
 */

namespace expr {
	const std::regex dataUriRegex("^data:(.*?)(;base64)?,(.*)$");
};

struct RegExp {
	std::string pattern;
	std::regex  reg;
	RegExp(std::string pattern);
	bool test(std::string s)const;
	bool operator==(const RegExp & rhs) const;

};

namespace std {
	template<>
	class hash<RegExp> {
	public:
		size_t operator () (const RegExp& p) const {
			return std::hash<std::string>()(p.pattern);
		}
	};
}

struct CallBackLoading {
	CallBackLoading(std::function<void(std::vector<ResType>)> onLoad = nullptr,
		std::function<void(std::string, uint32_t, uint32_t)> onProgress = nullptr,
		std::function<void(std::string)> onError = nullptr);
	std::function<void(std::vector<ResType>)> onLoad = nullptr;
	std::function<void(std::string, uint32_t, uint32_t)> onProgress = nullptr;
	std::function<void(std::string)> onError = nullptr;
};

struct LoadingManager{

	uint32_t itemsLoaded = 0, itemsTotal = 0;
	bool isLoading = false;

	Cache* cache;
	std::unordered_map<RegExp,Loader*>  handlers;
    ///std::vector<std::pair< RegExp, Loader*>> handlers;

	LoadingManager();
	~LoadingManager();

	std::function<void(std::string,uint32_t,uint32_t)> onStart;
	std::function<void(void)> onLoad;
	std::function<void(std::string, uint32_t, uint32_t)> onProgress;
	std::function<void(std::string)> onError;
	std::function<std::string(std::string)> urlModifier;

	void init(std::function<void(void)> _onLoad= nullptr,
		std::function<void(std::string, uint32_t, uint32_t)> _onProgress = nullptr,
		std::function<void(std::string)> _onError = nullptr);

	void itemStart(std::string url);

	void itemEnd(std::string url);

	void itemError(std::string url);

	std::string resolveURL(std::string url);

	LoadingManager& setURLModifier(std::function<std::string(std::string)> transform);

	LoadingManager& addHandler(std::string regex, Loader* loader);

	LoadingManager& removeHandler(std::string  regex);

	Loader* getHandler(std::string file);

	std::string  getCache(std::string key);

	void  setCache(std::string key);
	std::map < std::string, std::vector<CallBackLoading>>& getLoading();
};

/*
var DefaultLoadingManager = new LoadingManager();
export { DefaultLoadingManager, LoadingManager };

*/
#endif