#pragma once

#define WIN32_LEAN_AND_MEAN             // Windows ヘッダーからほとんど使用されていない部分を除外する
#pragma warning(push,3)
#define STB_IMAGE_IMPLEMENTATION


#define TEST_IMP

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