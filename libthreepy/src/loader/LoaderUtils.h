#pragma once
#ifndef  LOADER_UTIL_H
#define LOADER_UTIL_H

#include <vector>
#include <unordered_map>
#include "types.hpp"

#include "LoadingManager.h"




struct TextDecoder{
	void decode(std::vector<char>  c) {};
};

struct LoaderUtils {

	TextDecoder* decoder;
	void decodeText(std::vector<char> array);

	std::string extractUrlBase(std::string url);

};



struct Cache {

	bool enabled = false;
	std::unordered_map<std::string, std::string> files;
	std::unordered_map< std::string, std::vector<CallBackLoading>> loading;
	Cache();
	void add(std::string key, std::string file);

	std::string get(std::string key);

	void remove(std::string key);

	void clear();

};

#endif