#include "pch_three.h"
#include "Loader.h"
#include "json.h"
#include "core/common.hpp"

///#define Log_NO_Loader
#ifdef   Log_NO_Loader
#define Log_Loader(...)
#else
#define Log_Loader(...) Log_out(__FILE__, __LINE__, Log_TRACE, __VA_ARGS__)
#endif

#if defined(TEST1_GLTF)
static const uint8_t from_base64[128] = {
	// 8 rows of 16 = 128
	// note: only require 123 entries, as we only lookup for <= z , which z=122
				255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
				255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,  62, 255,  62, 255,  63,
				 52,  53,  54,  55,  56,  57,  58,  59,  60,  61, 255, 255,   0, 255, 255, 255,
				255,   0,   1,   2,   3,   4,   5,   6,   7,   8,   9,  10,  11,  12,  13,  14,
				 15,  16,  17,  18,  19,  20,  21,  22,  23,  24,  25, 255, 255, 255, 255,  63,
				255,  26,  27,  28,  29,  30,  31,  32,  33,  34,  35,  36,  37,  38,  39,  40,
				 41,  42,  43,  44,  45,  46,  47,  48,  49,  50,  51, 255, 255, 255, 255, 255
};

static const char to_base64[65] =
"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
"abcdefghijklmnopqrstuvwxyz"
"0123456789+/";


void base64_encode(std::string& out, std::string const& buf)
{
	if (buf.empty())
		base64_encode(out, NULL, 0);
	else
		base64_encode(out, reinterpret_cast<uint8_t const*>(&buf[0]), buf.size());
}

void base64_encode(std::string& out, std::vector<uint8_t> const& buf)
{
	if (buf.empty())
		base64_encode(out, NULL, 0);
	else
		base64_encode(out, &buf[0], buf.size());
}

void base64_encode(std::string& ret, uint8_t const* buf, size_t bufLen)
{
	// Calculate how many bytes that needs to be added to get a multiple of 3
	size_t missing = 0;
	size_t ret_size = bufLen;
	while ((ret_size % 3) != 0)
	{
		++ret_size;
		++missing;
	}

	// Expand the return string size to a multiple of 4
	ret_size = 4 * ret_size / 3;

	ret.clear();
	ret.reserve(ret_size);

	for (size_t i = 0; i < ret_size / 4; ++i)
	{
		// Read a group of three bytes (avoid buffer overrun by replacing with 0)
		const size_t index = i * 3;
		const uint8_t b3_0 = (index + 0 < bufLen) ? buf[index + 0] : 0;
		const uint8_t b3_1 = (index + 1 < bufLen) ? buf[index + 1] : 0;
		const uint8_t b3_2 = (index + 2 < bufLen) ? buf[index + 2] : 0;

		// Transform into four base 64 characters
		const uint8_t b4_0 = ((b3_0 & 0xfc) >> 2);
		const uint8_t b4_1 = ((b3_0 & 0x03) << 4) + ((b3_1 & 0xf0) >> 4);
		const uint8_t b4_2 = ((b3_1 & 0x0f) << 2) + ((b3_2 & 0xc0) >> 6);
		const uint8_t b4_3 = ((b3_2 & 0x3f) << 0);

		// Add the base 64 characters to the return value
		ret.push_back(to_base64[b4_0]);
		ret.push_back(to_base64[b4_1]);
		ret.push_back(to_base64[b4_2]);
		ret.push_back(to_base64[b4_3]);
	}

	// Replace data that is invalid (always as many as there are missing bytes)
	for (size_t i = 0; i != missing; ++i)
		ret[ret_size - i - 1] = '=';
}
#endif





PyObject* decode_json(char* data){

	json_settings settings;
	memset(&settings, 0, sizeof(json_settings));
	settings.settings = json_enable_comments;
	char error[256];
	json_value* value = json_parse_ex(&settings, data, strlen(data), error);
	if (value == 0) {
		PyErr_BadInternalCall();
		Py_RETURN_NAN;
	}
	PyObject* converted = convert_value(value);
	json_value_free(value);
	return converted;
}

PyObject* get_exception_class()
{
	static PyObject* json_exception = PyErr_NewException("jsonparser.JSONException", NULL, NULL);

	return json_exception;
}


PyObject* convert_value(json_value* data)
{
	PyObject* value;
	switch (data->type) {
	case json_object:
		value = PyDict_New();
		for (int i = 0; i < int(data->u.object.length); i++) {
			PyObject* name = PyUnicode_FromString(data->u.object.values[i].name);
			PyObject* object_value = convert_value(data->u.object.values[i].value);
			PyDict_SetItem(value, name, object_value);
		}
		break;
	case json_array:
		value = PyList_New(0);
		for (int i = 0; i < int(data->u.array.length); i++) {
			PyObject* array_value = convert_value(
				data->u.array.values[i]);
			PyList_Append(value, array_value);
		}
		break;
	case json_integer:
		value = PyLong_FromLongLong(data->u.integer);
		break;
	case json_double:
		value = PyFloat_FromDouble(data->u.dbl);
		break;
	case json_string:
		value = PyUnicode_FromStringAndSize(data->u.string.ptr,
			data->u.string.length);
		break;
	case json_boolean:
		value = PyBool_FromLong((long)data->u.boolean);
		break;
	default:
		// covers json_null, json_none
		Py_INCREF(Py_None);
		value = Py_None;
		break;
	}
	return value;
}



FileLoader::FileLoader() :Loader() {};
FileLoader::FileLoader(LoadingManager* manger) :Loader(manager) {};

std::string FileLoader::load(std::string url , std::function<void(std::vector<ResType>)> onLoad ,
	std::function<void(std::string, uint32_t, uint32_t)> onProgress ,
	std::function<void(std::string)> onError ) {

	if (path != "") url = path + url;

	//url = manager->resolveURL(url);

	/*
	std::string cached = manager->getCache(url);

	if (cached != "") {

		manager->itemStart(url);

		///setTimeout(function() {

			///if (onLoad) onLoad(cached);

		manager->itemEnd(url);

		///}, 0);

		return cached;

	}
	*/

	///std::map < std::string, std::vector<CallBackLoading>>& loading = manager->getLoading();
	std::vector<CallBackLoading>  loading;
	/*
	if (loading.count(url) != 0) {
		loading[url].push_back({
			onLoad,
			onProgress,
			onError }
		);
		return "";
	}
	*/

	// Check for data: URI

	//std::vector<ResType> response;

	std::smatch dataUriRegexResult;

	if (std::regex_match(url, dataUriRegexResult, expr::dataUriRegex)) {

		if (dataUriRegexResult.size() == 4) {

			std::ssub_match base_sub_match = dataUriRegexResult[1];
			std::string  mimeTy = dataUriRegexResult.str();

			base_sub_match = dataUriRegexResult[2];
			std::string   isBase64 = dataUriRegexResult.str();

			base_sub_match = dataUriRegexResult[3];
			std::string  data = dataUriRegexResult.str();

			if (isBase64 != "") {
				///base64_decode(response, data);
			}
			else {

				PyErr_BadInternalCall();
			}
			/*
			try {

				switch (responseType) {
					case 'arraybuffer':
					case 'blob':

						var view = new Uint8Array(data.length);

						for (var i = 0; i < data.length; i++) {

							view[i] = data.charCodeAt(i);

						}

					 else {

					  response = view.buffer;

					}

					break;
					case 'document':

						var parser = new DOMParser();
						response = parser.parseFromString(data, mimeType);

						break;

					case 'json':

						response = JSON.parse(data);

						break;

					default: // 'text' or other

						response = data;

						break;

					}
			*/
			// Wait for next browser tick like standard XMLHttpRequest event dispatching does
			///setTimeout(function() {

			if (onLoad) onLoad(response);

			manager->itemEnd(url);

			///}, 0);

		/*
					}
					catch (error) {


			 // Wait for next browser tick like standard XMLHttpRequest event dispatching does
					*/

		}
		else {
			///setTimeout(function() {

			if (onError) onError("base64ParseError");

			manager->itemError(url);
			manager->itemEnd(url);

			///}, 0);
		}

	}
	else {

		manager->itemStart(url);
		// Initialise array for duplicate requests
		/*
		loading.push_back({
			onLoad,
			onProgress,
			onError
			});
			*/

		///loading.erase(url);

		std::ifstream ifs(url.c_str(), std::ios::in | std::ios::binary | std::ios::ate);

		std::ifstream::pos_type fileSize = ifs.tellg();
		ifs.seekg(0, std::ios::beg);

		response.resize(fileSize);


		if (response.size() == 0) {
			
			if (onError != nullptr) onError("fileReadError");
			///for (auto& cb : loading) {
			///	if (cb.onError != nullptr) cb.onError("fileReadError");
			///}

			manager->itemError(url);
			manager->itemEnd(url);


		}
		else {

			ifs.read(response.data(), fileSize);
			///manager->setCache(url);
			if (onLoad != nullptr) onLoad(response);
			///for (auto& cb : loading) {
			///	if (cb.onLoad != nullptr) cb.onLoad(response);
			///}
	
			manager->itemEnd(url);

		}

		return "";
	}
	return "";
};


FileLoader& FileLoader::setResponseType(std::string value) {

	responseType = value;
	return *this;

};

FileLoader& FileLoader::setWithCredentials(std::string value) {

	withCredentials = value;
	return *this;

};

FileLoader& FileLoader::setMimeType(std::string value) {

	mimeType = value;
	return *this;

};

FileLoader& FileLoader::setRequestHeader(std::string value) {

	requestHeader = value;
	return *this;

};



FileLoader&  FileLoader::jsonParse(std::vector<char> raw)
{
	json_settings settings;
	memset(&settings, 0, sizeof(json_settings));
	settings.settings = json_enable_comments;
	char error[256];
	Log_trace("loadParser       %zu    \n",raw.size());
	json_value* data = json_parse_ex(&settings, raw.data(), raw.size(), error);
	Log_trace("JsonParse  %p  \n", data);
	if (data == 0) {
		///PyErr_Format(json_exception, error);
		PyErr_BadArgument();
	}
	Log_trace("JsonParse Free   \n");
	json_value_free(data);
	return *this;

}