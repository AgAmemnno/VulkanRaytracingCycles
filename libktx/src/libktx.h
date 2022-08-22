#pragma once

#define WIN32_LEAN_AND_MEAN             // Windows ヘッダーからほとんど使用されていない部分を除外する
#pragma warning(push,3)
#define STB_IMAGE_IMPLEMENTATION


#define TEST_IMP



namespace fon {

#define FONS_INVALID -1

#ifndef FONS_SCRATCH_BUF_SIZE
#	define FONS_SCRATCH_BUF_SIZE 96000
#endif
#ifndef FONS_HASH_LUT_SIZE
#	define FONS_HASH_LUT_SIZE 256
#endif
#ifndef FONS_INIT_FONTS
#	define FONS_INIT_FONTS 4
#endif
#ifndef FONS_INIT_GLYPHS
#	define FONS_INIT_GLYPHS 256
#endif
#ifndef FONS_INIT_ATLAS_NODES
#	define FONS_INIT_ATLAS_NODES 256
#endif
#ifndef FONS_VERTEX_COUNT
#	define FONS_VERTEX_COUNT 1024
#endif
#ifndef FONS_MAX_STATES
#	define FONS_MAX_STATES 20
#endif
#ifndef FONS_MAX_FALLBACKS
#	define FONS_MAX_FALLBACKS 20
#endif


	enum FONSflags {
		FONS_ZERO_TOPLEFT = 1,
		FONS_ZERO_BOTTOMLEFT = 2,
	};

	enum FONSalign {
		// Horizontal align
		FONS_ALIGN_LEFT = 1 << 0,	// Default
		FONS_ALIGN_CENTER = 1 << 1,
		FONS_ALIGN_RIGHT = 1 << 2,
		// Vertical align
		FONS_ALIGN_TOP = 1 << 3,
		FONS_ALIGN_MIDDLE = 1 << 4,
		FONS_ALIGN_BOTTOM = 1 << 5,
		FONS_ALIGN_BASELINE = 1 << 6, // Default
	};

	enum FONSglyphBitmap {
		FONS_GLYPH_BITMAP_OPTIONAL = 1,
		FONS_GLYPH_BITMAP_REQUIRED = 2,
	};

	enum FONSerrorCode {
		// Font atlas is full.
		FONS_ATLAS_FULL = 1,
		// Scratch memory used to render glyphs is full, requested size reported in 'val', you may need to bump up FONS_SCRATCH_BUF_SIZE.
		FONS_SCRATCH_FULL = 2,
		// Calls to fonsPushState has created too large stack, if you need deep state stack bump up FONS_MAX_STATES.
		FONS_STATES_OVERFLOW = 3,
		// Trying to pop too many states fonsPopState().
		FONS_STATES_UNDERFLOW = 4,
	};

	struct FONSquad
	{
		float x0, y0, s0, t0;
		float x1, y1, s1, t1;
	};
	typedef struct FONSquad FONSquad;

};

namespace ktx
{
    typedef  unsigned long long ENUM_TYPE;
    enum class flags : ENUM_TYPE {
         Error = 0
    };
    namespace Flags
    {
        const size_t Error = -1; 
    };

    struct MipLevel {
        std::vector<uint8_t> bytes;
    };
    struct ImagePixels {
        uint8_t* packed;  // base mip level only, tightly packed
        uint32_t w, h;
        std::vector<MipLevel> input_mips;  // padded
        std::vector<MipLevel> output_mips;
    };
    struct loadmap {
        ImagePixels* images;
        loadmap();
        ~loadmap();
        void dealloc();
        size_t load(const char* filename,int width = -1, int height = -1);
        void map(char* dst, size_t size);
    };


};

#ifdef TEST_IMP

namespace Test
{
    void test1();
}

#endif