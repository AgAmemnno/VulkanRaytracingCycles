#pragma once
#ifndef  LOADER_H
#define  LOADER_H

//#include "pch.h"
#include "enum.hpp"


#include "core/common.hpp"
#include "json.h"
#include <unordered_map>
#include <vector>
#include <functional>
#include <map>
#include <regex>

typedef struct RegExp RegExp;
typedef struct Loader Loader;
typedef struct LoaderUtils  LoaderUtils;
typedef struct  LoadingManager LoadingManager;
typedef struct CallBackLoading CallBackLoading;
typedef char ResType;
typedef struct  Cache Cache;


PyObject* decode_json(char* data);

PyObject* get_exception_class();

PyObject* convert_value(json_value* data);


namespace expr {
	const std::regex dataUriRegex("^data:(.*?)(;base64)?,(.*)$");
};

struct RegExp {
	std::string pattern;
	std::regex  reg;
	RegExp(std::string pattern);
	bool test(std::string s)const;
	bool operator==(const RegExp& rhs) const;

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

struct LoadingManager {

	uint32_t itemsLoaded = 0, itemsTotal = 0;
	bool isLoading = false;

	Cache* cache = nullptr;
	bool hasCache = false;
	std::unordered_map<RegExp, Loader*>  handlers;
	///std::vector<std::pair< RegExp, Loader*>> handlers;

	LoadingManager();
	~LoadingManager();

	std::function<void(std::string, uint32_t, uint32_t)> onStart;
	std::function<void(void)> onLoad;
	std::function<void(std::string, uint32_t, uint32_t)> onProgress;
	std::function<void(std::string)> onError;
	std::function<std::string(std::string)> urlModifier;

	void init(std::function<void(void)> _onLoad = nullptr,
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

struct Loader {
	LoadingManager* manager;
	bool hasManager;
	std::string crossOrigin, path, resourcePath;
	Loader();
	Loader(LoadingManager* _manager);
	~Loader();

	void init();

	virtual void  load() {};
	virtual void  parse() {};

	Loader& setCrossOrigin(std::string crossO) { crossOrigin = crossO; return *this; }
	Loader& setPath(std::string pat) { path = pat; return *this; };
	Loader& setResourcePath(std::string Path) { resourcePath = Path; return *this; }

};

struct TextDecoder {
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
	std::map < std::string, std::vector<CallBackLoading>> loading;
	Cache();
	void add(std::string key, std::string file);

	std::string get(std::string key);

	void remove(std::string key);

	void clear();

};

struct DRACOLoader {};
struct DDSLoader {};


struct FileLoader : Loader {
	std::string responseType, withCredentials, mimeType, requestHeader;
	std::vector<ResType> response;
	FileLoader();
	FileLoader(LoadingManager* manger);

	std::string load(std::string url = "", std::function<void(std::vector<ResType>)> onLoad = nullptr,
		std::function<void(std::string, uint32_t, uint32_t)> onProgress = nullptr,
		std::function<void(std::string)> onError = nullptr);


	FileLoader& setResponseType(std::string value);

	FileLoader& setWithCredentials(std::string value);

	FileLoader& setMimeType(std::string value);

	FileLoader& setRequestHeader(std::string value);

	FileLoader& jsonParse(std::vector<char> raw);
};


struct _BufferView {
	arth::INPUT             input;
	int                               next;
	int                               GLtype;
	uint32_t                 fieldSize;
	uint32_t				   arraysize;
	uint32_t                     offset;
	uint32_t                  bytesize;
	std::vector<UINT8>       data;
};

struct _Accessor {

	int                                                  lod;
	int                                                next;
	std::vector<_BufferView>  bufferView;

};


#define  OBJ(t,__i) (t->u.object.values[__i])
#define  OBJ_LEN(t) (t->u.object.length)
#define  ARRAY(t,__i) (t->u.array.values[__i])
#define  ARRAY_LEN(t) (t->u.array.length)

#define GLTF_STAGE_asset 0
#define GLTF_STAGE_scene 1
#define GLTF_STAGE_scenes 2
#define GLTF_STAGE_nodes 3
#define GLTF_STAGE_meshes 4
#define GLTF_STAGE_accessors 5
#define GLTF_STAGE_bufferViews 6
#define GLTF_STAGE_buffers 7

#define GLTYPE_FLOAT   5126
#define GLTYPE_UINT16  5123

#define THROW_GLTF_NIL {\
Log_bad("Error GLTF Loader ::   Not Implemented.");\
}
#define THROW_ParseERROR {\
Log_bad("ParseError GLTF Loader :: ");\
}


struct GLTF_Loader {

	CarryAttribute* carry;
	
	
	arth::LOADER_TARGET  target;
	std::string              targetName;
	size_t                          ViewSize;
	mutable int                      NODE;

	json_value* data;
	std::vector<_Accessor> access;

	struct _VEC3 {
		float v[3];
	}VEC3;

	struct _IND1 {
		UINT16  v;
	}IND1;

	GLTF_Loader(CarryAttribute* carry);
	~GLTF_Loader();
	void _decode(std::vector<uint8_t>& ret, std::string::iterator beg, std::string::iterator  end);
	void parallel_base64(std::string::iterator beg, std::string::iterator  end);
	void debug_print(_BufferView& bv);
	int    toDigit(char c);
	uint32_t getItemSize(_BufferView& bv);
	void  parseScenes(json_value* tmp);
	void  parseNodes(json_value* obj, _Accessor& acs);
	void  parseTarget(std::string name, _Accessor& acs);
	void  parseAttr(_json_object_entry* obj,  _Accessor& acs);
	void  parseMeshes(json_value* obj, _Accessor& acs);
	uint32_t  parseType(std::string attr);
	void   parseSphere(json_value* min, json_value* max);
	void  parseAccessors(json_value* obj, _BufferView& bv, bool bounding = false);
	void  parsebufferViews(json_value* obj, _BufferView& bv);
	void  _mapBuffers(json_value* obj);
	void  mapBuffers(json_value* obj);
	void  load_lod(std::vector<char> raw, std::string              targetName = "LOD");
	void  map_lod();

};

#endif
