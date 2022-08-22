#include "pch_three.h"

namespace types {

	size_t  stollu_rand(const char* c) {
		size_t hash = 0;
		for (int i = 0; i < strlen(c); i++) {
			hash |= INT64(c[i]) << 12;
			hash += 3;
			hash *= hash;
			hash ^= (hash + INT64(c[i])) << 4;
		};
		return hash;
		///printf(" %zu ", hash);
	};
};


namespace types {
#ifdef UNICODE
	std::wstring to_tchar(const char* text) {
		//const char* text_char = "example of mbstowcs";
		size_t length = strlen(text);
		std::wstring text_wchar(length, L'#');
		mbstowcs(&text_wchar[0], text, length);
		return  text_wchar;
	};
#else
	std::string to_tchar(const char* text) {
		return std::string(text);
	};

#endif

	const char* TypeString(char c)
	{
		switch (c)
		{
#define CASE(r) case r: return #r
			CASE(CONTEXTVK);
			CASE(WINDOWVK);
		}

		return "NoNameFound";
	}
#ifdef  ENABLED_VULKAN_OVR
	const char* errString_VrCompositor(vr::EVRCompositorError er) {

		switch (er)
		{
#define eVRCOMP(r) case vr::##r: return #r;

			eVRCOMP(VRCompositorError_None)
				eVRCOMP(VRCompositorError_RequestFailed)
				eVRCOMP(VRCompositorError_IncompatibleVersion)
				eVRCOMP(VRCompositorError_DoNotHaveFocus)
				eVRCOMP(VRCompositorError_InvalidTexture)
				eVRCOMP(VRCompositorError_IsNotSceneApplication)
				eVRCOMP(VRCompositorError_TextureIsOnWrongDevice)
				eVRCOMP(VRCompositorError_TextureUsesUnsupportedFormat)
				eVRCOMP(VRCompositorError_SharedTexturesNotSupported)
				eVRCOMP(VRCompositorError_IndexOutOfRange)
				eVRCOMP(VRCompositorError_AlreadySubmitted)
				eVRCOMP(VRCompositorError_InvalidBounds)
				eVRCOMP(VRCompositorError_AlreadySet)
		};
		return "UNDEFINED ERROR";

	}
#endif
	std::string   toNum(VkDescriptorType descTy, VkShaderStageFlags  flagTy)  noexcept {

		std::string ret = "desc:" + std::to_string((long)descTy);
		ret += ("flag:" + std::to_string((long)(flagTy)));
		return ret;
	};

	std::string toLayoutType(std::vector<VkDescriptorSetLayoutBinding>& DSLB) noexcept {
		std::string type = "";
		for (auto& t : DSLB) type += toNum(t.descriptorType, t.stageFlags);
		
		return type;
	};


	std::string format(const char* fmt, ...) {
		int size = 512;
		char* buffer = 0;
		buffer = new char[size];
		va_list vl;
		va_start(vl, fmt);
		int nsize = vsnprintf(buffer, size, fmt, vl);
		if (size <= nsize) { //fail delete buffer and try again
			delete[] buffer;
			buffer = 0;
			buffer = new char[nsize + 1]; //+1 for /0
			nsize = vsnprintf(buffer, size, fmt, vl);
		}
		std::string ret(buffer);
		va_end(vl);
		delete[] buffer;
		return ret;
	}


	void  format(string1& dst, const char* fmt, ...) {

		va_list vl;
		va_start(vl, fmt);
		size_t asize = (size_t)vsnprintf(nullptr, 0, fmt, vl) + 1;
		va_end(vl);


		va_list vl2;
		va_start(vl2, fmt);
		size_t cap = dst.capacity();
		size_t size = dst.size();
		size_t nsize = (size == 0) ? asize : size + asize - 1;
		if (nsize < cap) {
			dst.resize(nsize);
			vsnprintf(dst.data() + ((size == 0) ? 0 : size - 1), asize, fmt, vl2);
		}
		else printf("over capacity string format \n");
		va_end(vl2);

	}

	void  concat(string1& dst, const string1& src, size_t start) {

		size_t asize = src.size();
		size_t cap = dst.capacity();
		size_t size = start;// dst.size();
		size_t nsize = (size == 0) ? asize : size + asize - 1;

		if (nsize < cap) {

			dst.resize(nsize);
			memmove(dst.data() + ((size == 0) ? 0 : size - 1), src.data(), asize);

		}
		else printf("over capacity string format \n");

	};


};