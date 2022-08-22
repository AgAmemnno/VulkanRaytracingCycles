// libktx.cpp : スタティック ライブラリ用の関数を定義します。
//

#include "pch.h"
#include "log.hpp"
#include "libktx.h"
#include <stb_image.h>
#include <stdexcept>
#include <algorithm>

#pragma warning(disable:4702)  // unreachable code
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#define STBI_MALLOC(sz) malloc(sz)
#define STBI_REALLOC(p,newsz) realloc(p,newsz)
#define STBI_FREE(p) free(p)
#include <stb_image_resize.h>
#pragma warning(pop)



namespace ktx
{

    


    loadmap::loadmap() { images = nullptr; };
        loadmap::~loadmap() { dealloc(); };
        void loadmap::dealloc() {
            if (images != nullptr) {
                if (images->packed != nullptr) stbi_image_free(images->packed);
                delete images;
            }
        };
        size_t loadmap::load(const char* filename, int width, int height)
        {
            images = new ImagePixels;
            int base_width = 0, base_height = 0;
            int input_components = 4; // ispc_texcomp requires 32-bit RGBA input
            int original_components = 0;
   
            images->packed = stbi_load(filename, &base_width, &base_height, &original_components, input_components);
            log_once("load PNG  %d components  \n", original_components);

            if (!images->packed) {
                fprintf(stderr, "Error loading input '%s'\n", filename);
                return Flags::Error;
            }
            if (original_components == 0) {
                fprintf(stderr, "Error loading input '%s'\n", filename);
                return Flags::Error;
            }

            bool resize = false;
            if (width > 0 || height > 0) resize = true;

            if (resize) {
                int base_resize_width = (width > 0) ? width : base_width;
                int base_resize_height = (height > 0) ? height : base_height;

                stbi_uc* resized_packed = (stbi_uc*)STBI_MALLOC(base_resize_width * base_resize_height * input_components);
                stbir_resize_uint8(
                    images->packed, base_width, base_height, base_width * input_components,
                    resized_packed, base_resize_width, base_resize_height, base_resize_width * input_components,
                    input_components
                );
                stbi_image_free(images->packed);
                images->packed = resized_packed;

                log_once(" Resized inputs (old: width=%d height=%d, new: width=%d height=%d\n", base_width, base_height, base_resize_width, base_resize_height);
                base_width = base_resize_width;
                base_height = base_resize_height;
            }

            images->w = base_width;
            images->h = base_height;

            return   size_t(images->w) * size_t(images->h);
        };

        void loadmap::map(char* dst,size_t size) {
            size_t _size = size_t(images->w)* size_t(images->h);
            if (images->packed != nullptr && size <= _size )memcpy(dst, images->packed, size);
            else log_once("MAP:: cant map images.");
        };
         
         

}

#ifdef TEST_IMP
#define STBI_WINDOWS_UTF8

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#define STB_DEFINE
#include "stb.h"

namespace Test
{
    float hdr_data[200][200][3];

    void dummy_write(void* context, void* data, int len)
    {
        static char dummy[1024];
        if (len > 1024) len = 1024;
        memcpy(dummy, data, len);
    }


#if 0
    void test_ycbcr(void)
    {
        STBI_SIMD_ALIGN(unsigned char, y[256]);
        STBI_SIMD_ALIGN(unsigned char, cb[256]);
        STBI_SIMD_ALIGN(unsigned char, cr[256]);
        STBI_SIMD_ALIGN(unsigned char, out1[256][4]);
        STBI_SIMD_ALIGN(unsigned char, out2[256][4]);

        int i, j, k;
        int count = 0, bigcount = 0, total = 0;

        for (i = 0; i < 256; ++i) {
            for (j = 0; j < 256; ++j) {
                for (k = 0; k < 256; ++k) {
                    y[k] = k;
                    cb[k] = j;
                    cr[k] = i;
                }
                stbi__YCbCr_to_RGB_row(out1[0], y, cb, cr, 256, 4);
                stbi__YCbCr_to_RGB_sse2(out2[0], y, cb, cr, 256, 4);
                for (k = 0; k < 256; ++k) {
                    // inaccurate proxy for values outside of RGB cube
                    if (out1[k][0] == 0 || out1[k][1] == 0 || out1[k][2] == 0 || out1[k][0] == 255 || out1[k][1] == 255 || out1[k][2] == 255)
                        continue;
                    ++total;
                    if (out1[k][0] != out2[k][0] || out1[k][1] != out2[k][1] || out1[k][2] != out2[k][2]) {
                        int dist1 = abs(out1[k][0] - out2[k][0]);
                        int dist2 = abs(out1[k][1] - out2[k][1]);
                        int dist3 = abs(out1[k][2] - out2[k][2]);
                        ++count;
                        if (out1[k][1] > out2[k][1])
                            ++bigcount;
                    }
                }
            }
            printf("So far: %d (%d big) of %d\n", count, bigcount, total);
        }
        printf("Final: %d (%d big) of %d\n", count, bigcount, total);
    }
#endif

#define PNGSUITE_PRIMARY



    void test1() {

        //#define PNGSUITE_PRIMARY

        int w, h;
        //test_ycbcr();

#if 0
        // test hdr asserts
        for (h = 0; h < 100; h += 2)
            for (w = 0; w < 200; ++w)
                hdr_data[h][w][0] = (float)rand(),
                hdr_data[h][w][1] = (float)rand(),
                hdr_data[h][w][2] = (float)rand();

        stbi_write_hdr("output/test.hdr", 200, 200, 3, hdr_data[0][0]);
#endif


        int i;
#ifdef PNGSUITE_PRIMARY

        log_once("D: / C / libktx / stb / tests / pngsuite / primary    TEST PNGs  \n");

        char** files = stb_readdir_files((char*)("D:/C/libktx/stb/tests/pngsuite/primary"));
#else
        char** files = stb_readdir_files("images");
#endif
        for (i = 0; i < stb_arr_len(files); ++i) {
            printf("%s\n", files[i]);


            int n;
            char** failed = NULL;
            unsigned char* data;
            printf("<-");
         
            data = stbi_load(files[i], &w, &h, &n, 0); if (data) {
                printf("->"); free(data);
            }
            else stb_arr_push(failed, (char*)"&n");
            printf("<-");
            data = stbi_load(files[i], &w, &h, 0, 1); if (data) {
                printf("->"); free(data);
            }
            else stb_arr_push(failed, (char*)"1");
            printf("<-");
            data = stbi_load(files[i], &w, &h, 0, 2); if (data) {
                printf("->"); free(data);
            }
            else stb_arr_push(failed, (char*)"2");
            printf("<-");
            data = stbi_load(files[i], &w, &h, 0, 3); if (data) {
                printf("->"); free(data);
            }
            else stb_arr_push(failed, (char*)"3");
            printf("<-");
            data = stbi_load(files[i], &w, &h, 0, 4); if (data) {
                printf("->");
            }
            else stb_arr_push(failed, (char*)"4");
            printf("  <load> ");
            if (failed) {
                int j;
                printf("  <FAILED: ");
                for (j = 0; j < stb_arr_len(failed); ++j)
                    printf("  %s   ", failed[j]);
                printf(" -- %s>\n", files[i]);
            }

            if (data) {
                printf("\n <ReadChar  %d %d > \n",w,h);
                char fname[512];

#ifdef PNGSUITE_PRIMARY
                ///int w2, h2;
                ///unsigned char* data2;
               /// stb_splitpath(fname, files[i], STB_FILE_EXT);
               /// printf("Check    %s   \n", stb_sprintf("D:/C/libktx/stb/tests/pngsuite/primary_check/%s", fname));

                for (int y = 0; y < h; ++y)
                    for (int x = 0; x < w; ++x)
                        for (int c = 0; c < 4; ++c) {
                            if ((y * w * 4 + x * 4 + c) % (4*w) == 0)printf("\n");
                            if(c==0)printf("%c", (data[y * w * 4 + x * 4 + c] == 0)?'*':' ');
                        }
               }
#else
                stb_splitpath(fname, files[i], STB_FILE);
                stbi_write_png(stb_sprintf("output/%s.png", fname), w, h, 4, data, w * 4);
#endif
                printf("\n <free Data > \n");
                stbi_image_free(data);
                printf("<Tested %d files.>\n", i);

            }

            printf("<Tested fin.>\n");
    };
};

#endif