#pragma once
#pragma warning(disable : 4267)
///#pragma warning(default:4267)
#ifndef __TYPES
#define __TYPES
#include "config_aeolus.h"



#define __Decrement__(obj) {if(obj !=nullptr)Py_DECREF(obj);}
#define __Delete__(obj) {if(obj !=nullptr){delete obj;obj = nullptr;};}
#define __Void__(p)  (void*)(&p)
#define __ENUM__(type,en)  ((type& en) == en)


#define  PRll_POLICY std::execution::par
#define  PRll_MAP_POLICY std::execution::seq
#define  PRll_VECTOR_POLICY std::execution::par_unseq
#define Tuple(t,i)  (std::get<(i)>(t)) 



#define GetByteArray(obj,view){\
view.len = -1;\
if (PyObject_GetBuffer(obj, &view, PyBUF_SIMPLE) != 0) {\
	PyErr_Format(PyExc_TypeError, " cant read %.100s ", Py_TYPE(obj)->tp_name);\
	PyBuffer_Release(&view);\
	Py_RETURN_NONE;\
}\
}\

#define ReleaseView(view) {if(view.len != -1)PyBuffer_Release(&view);}


namespace std {
	typedef basic_string<TCHAR>   tstring;
};

#ifdef UNICODE
#define   to_tstring  to_wstring
#else
#define  to_tstring  to_string
#endif


namespace types {
	size_t  stollu_rand(const char* c);
};

namespace types {

#ifdef UNICODE
	std::wstring to_tchar(const char* text);
#else
	std::string to_tchar(const char* text);
#endif

	constexpr size_t MAX_LAYOUT_TYPE = 3;  ///  { u : ubo  , t : texture , s: ssbo  }
	constexpr size_t MAX_LAYOUT_SET = 5;   /// "uuuuu"  or "suttu" or "sut" ....

	constexpr size_t sizelayout() {
		size_t b = 1;
		size_t n = 0;
		for (int i = 1; i <= MAX_LAYOUT_SET; i++) {
			b = b * MAX_LAYOUT_TYPE;
			n += b;
		};
		return n;
	};

	const size_t  SIZE_LAYOUT = sizelayout();

	template<class T>
	bool LayoutNum(T  type, size_t& N) {
		size_t s = type.size();
		if (s > MAX_LAYOUT_SET)return false;
		size_t n = 0;
		size_t b = 1;
		for (int i = 0; i < s; i++) {
			char c = type[i];
			size_t x = (c == 'u') ? 0 : ((c == 't') ? 1 : ((c == 's') ? 2 : SIZE_LAYOUT));
			n += b * (x + ((i == s - 1) ? 0 : MAX_LAYOUT_TYPE));
			b *= MAX_LAYOUT_TYPE;
		};
		N = n;
		return (SIZE_LAYOUT <= n) ? false : true;
	};


	template<class T>
	extern bool  deleteRaw(_Inout_ T*& p) {
		if (p != nullptr) {
			delete p;
			p = nullptr;
		}
		return true;
	};

	const char* TypeString(char c);

	template<class T>
	inline void* Vo(T p) {
#define voi(p) static T _##p;
#define ret_voi(p){_##p = p; return &_##p;}
		voi(p);
		ret_voi(p);
	};


};

namespace types {


	struct reference {
		long          id = -1;
		uint32_t cnt = 0;
	};
#ifdef  ENABLED_VULKAN_OVR 
	const char* errString_VrCompositor(vr::EVRCompositorError er);
#endif
	std::string  toNum(VkDescriptorType descTy, VkShaderStageFlags  flagTy)  noexcept;
	std::string toLayoutType(std::vector<VkDescriptorSetLayoutBinding>&)  noexcept;

};


typedef std::vector<char> string1;

namespace types {

	extern size_t  LOG_CAPACITY;

	std::string format(const char* fmt, ...);


	void  format(string1& dst, const char* fmt, ...);

	void  concat(string1& dst, const string1& src, size_t start);

};



#include "threepy_const.h"
#include "threepy_path.h"
#include "threepy_types.h"






#endif