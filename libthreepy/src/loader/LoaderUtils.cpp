#include "pch_three.h"
#include "Loader.h"


void LoaderUtils::decodeText(std::vector<char> array) {

	if (decoder != nullptr) {
		return decoder->decode(array);
	}

	// Avoid the String.fromCharCode.apply(null, array) shortcut, which
	// throws a "maximum call stack size exceeded" error for large arrays.

	std::string  s = "";

	for (char c : array) {
		// Implicitly assumes little-endian.
		///s += String.fromCharCode(c);
		s += std::string(&c);

	}

};

std::string LoaderUtils::extractUrlBase(std::string url) {

	const std::string str("/");
	size_t i = url.find_last_of('/');
	if (i == -1)  return "./";
	return str.substr(0, i + 1);

}

void Cache::add(std::string key, std::string file) {

	if (enabled == false) return;

	// console.Log( 'THREE.Cache', 'Adding key:', key );
	files[key] = file;
};

std::string Cache::get(std::string key) {

	if (enabled == false) return "";
	// console.Log( 'THREE.Cache', 'Checking key:', key );
	return files[key];
};

void Cache::remove(std::string key) {
	files.erase(key);
};

void Cache::clear() {
	files.clear();
};

Cache::Cache() {
	files.clear();
	loading.clear();
};