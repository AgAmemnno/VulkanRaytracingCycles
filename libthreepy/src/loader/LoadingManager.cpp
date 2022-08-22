#include "pch_three.h"
#include "Loader.h"


RegExp::RegExp(std::string pattern) :pattern(pattern) {
	reg = std::regex(pattern, std::regex_constants::ECMAScript | std::regex_constants::icase);
};

bool RegExp::test(std::string s)const {
	if (std::regex_search(s, reg)) {
		Log_trace("Text contains the phrase  %s \n", pattern.c_str());
		return true;
	}
	return false;
}
bool RegExp::operator==(const RegExp& rhs) const
{
	return (pattern == rhs.pattern);
}

CallBackLoading::CallBackLoading(std::function<void(std::vector<ResType>)> onLoad ,
	std::function<void(std::string, uint32_t, uint32_t)> onProgress ,
	std::function<void(std::string)> onError) :onLoad(onLoad), onProgress(onProgress), onError(onError) {};


LoadingManager::LoadingManager() {
	if (!hasCache) {
		cache = new Cache;
		hasCache = true;
	}
	
};

LoadingManager::~LoadingManager() {
	if (hasCache) {
		delete cache;
		hasCache = false;
	}
};

void LoadingManager::init(std::function<void(void)> _onLoad,
	std::function<void(std::string, uint32_t, uint32_t)> _onProgress,
	std::function<void(std::string)> _onError)
{

	///var scope = this;
		
	isLoading = false;
	handlers.clear();
	urlModifier = nullptr;
	onStart = nullptr;
	onLoad = _onLoad;
	onProgress = _onProgress;
	onError     = _onError;
		 
	itemsLoaded = 0;
	itemsTotal = 0;

};

void LoadingManager::itemStart(std::string url) {

	itemsTotal++;
		
	if (isLoading == false) {
		if (onStart != nullptr) {
			onStart(url, itemsLoaded, itemsTotal);
		}
	}

	isLoading = true;

};

void LoadingManager::itemEnd(std::string url) {

	itemsLoaded++;

	if (onProgress != nullptr) {

		onProgress(url, itemsLoaded, itemsTotal);

	}

	if (itemsLoaded == itemsTotal) {
		isLoading = false;
		if (onLoad != nullptr) {
			onLoad();
		}
	}
};

void LoadingManager::itemError(std::string url) {

	if (onError != nullptr) {
		onError(url);
	}
};

std::string LoadingManager::resolveURL(std::string url) {

	if (urlModifier) {

		return urlModifier(url);

	}

	return url;

};

LoadingManager& LoadingManager::setURLModifier(std::function<std::string(std::string)> transform) {

	urlModifier = transform;
	return *this;

};

LoadingManager& LoadingManager::addHandler(std::string regex, Loader* loader) {

	handlers[regex] = loader;
	///handlers.push_back(std::make_pair(regex, loader));

	return *this;

};

LoadingManager& LoadingManager::removeHandler(std::string  regex) {
		
	RegExp rg(regex);

	if (handlers.count(rg) > 0) {
		handlers.erase(rg);
	}
	return *this;
};

Loader* LoadingManager::getHandler(std::string file) {

	for (const auto [r, val] : handlers) {
			//if (regex.global) regex.lastIndex = 0; // see #17920
			///r.extended
		if ( r.test(file)) {
			std::cout << "FileName  contains the phrase 'regular expressions'\n";
			return val;
		}

	}

	/*
	auto it = std::find_if(handlers.begin(), handlers.end(),
		[&User](const std::pair<std::regex, Loader*>& element) { return element.first == User.name; });

	vector< pair<string, int> > sortList;
	vector< pair<string, int> >::iterator it;

	for (int i = 0; i < Users.size(); i++)
	{
		it = find(sortList.begin(), sortList.end(), findVal(Users.userName));

		//Item exists in map
		if (it != sortList.end())
		{
			//increment key in map
			it->second++;
		}
		//Item does not exist
		else
		{
			//Not found, insert in map
			sortList.push_back(pair<string, int>(Users.userName, 1));
		}
	}
	*/

		
	return nullptr;
};

std::string  LoadingManager::getCache(std::string key) {
	return cache->get(key);
}

void  LoadingManager::setCache(std::string key) {
	cache->files[key] = "testCache";
};

std::map < std::string, std::vector<CallBackLoading>>& LoadingManager::getLoading() {
	return cache->loading;
}
