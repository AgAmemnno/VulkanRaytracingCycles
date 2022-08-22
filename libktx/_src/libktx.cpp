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


#define STB_TRUETYPE_IMPLEMENTATION
static void* fons__tmpalloc(size_t size, void* up);
static void  fons__tmpfree(void* ptr, void* up);
#define STBTT_malloc(x,u)    fons__tmpalloc(x,u)
#define STBTT_free(x,u)      fons__tmpfree(x,u)
#include "stb_truetype.h"

namespace fon {


    typedef struct FONSparams FONSparams;
    typedef struct FONSstate FONSstate;
    typedef struct  TT TT;

    template<class T>
    struct FONSparams {
        int width, height;
        unsigned char flags;
        void* userPtr;
        int (*renderCreate)(T* uptr, int width, int height);
        int (*renderResize)(T* uptr, int width, int height);
        void (*renderUpdate)(T* uptr, int* rect, const unsigned char* data);
        void (*renderDraw)(T* uptr, const float* verts, const float* tcoords, const unsigned int* colors, int nverts);
        void (*renderDelete)(T* uptr);
    };

    struct FONSstate
    {
        int font;
        int align;
        float size;
        unsigned int color;
        float blur;
        float spacing;
    };

#define FONS_UTF8_ACCEPT 0
#define FONS_UTF8_REJECT 12

    static unsigned int decodeUtf8(unsigned int* state, unsigned int* codep, unsigned int byte)
    {
        static const unsigned char utf8d[] = {
            // The first part of the table maps bytes to character classes that
            // to reduce the size of the transition table and create bitmasks.
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
            7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
            8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
            10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8,

            // The second part is a transition table that maps a combination
            // of a state of the automaton and a character class to a state.
            0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
            12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
            12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
            12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
            12,36,12,12,12,12,12,12,12,12,12,12,
        };

        unsigned int type = utf8d[byte];

        *codep = (*state != FONS_UTF8_ACCEPT) ?
            (byte & 0x3fu) | (*codep << 6) :
            (0xff >> type) & (byte);

        *state = utf8d[256 + *state + type];
        return *state;
    }
    static unsigned int hashInt(unsigned int a)
    {
        a += ~(a << 15);
        a ^= (a >> 10);
        a += (a << 3);
        a ^= (a >> 6);
        a += ~(a << 11);
        a ^= (a >> 16);
        return a;
    }

    typedef struct FONSglyph FONSglyph;
    struct FONSglyph
    {
        unsigned int codepoint;
        int index;
        int next;
        short size, blur;
        short x0, y0, x1, y1;
        short xadv, xoff, yoff;
    };
   

    struct FONScontext
    {
        FONSparams<void>  params;
        float itw, ith;
        unsigned char* texData;
        int dirtyRect[4];
        TT** fonts;
        ///FONSatlas* atlas;
        int cfonts;
        int nfonts;
        float verts[FONS_VERTEX_COUNT * 2];
        float tcoords[FONS_VERTEX_COUNT * 2];
        unsigned int colors[FONS_VERTEX_COUNT];
        int nverts;
        unsigned char* scratch;
        int nscratch;

       
        void (*handleError)(void* uptr, int error, int val);
        void* errorUptr;

        int               nstates;




        void setState(int nstates)
        {
            _state = &states[nstates - 1];
        };
        void SetSize(float size)
        {
            _state->size = size;
        }
        void SetColor(unsigned int color)
        {
            _state->color = color;
        }
        void SetSpacing(float spacing)
        {
            _state->spacing = spacing;
        }
        void SetBlur(float blur)
        {
            _state->blur = blur;
        }
        void SetAlign(int align)
        {
            _state->align = align;
        }
        void SetFont(int font)
        {
            _state->font = font;
        }
        void PushState()
        {
            if (nstates >= FONS_MAX_STATES) {
                if (handleError)
                    handleError(errorUptr, FONS_STATES_OVERFLOW, 0);
                return;
            }
            if (nstates > 0)
                memcpy(&states[nstates], &states[nstates - 1], sizeof(FONSstate));
            nstates++;
        }
        void PopState()
        {
            if (nstates <= 1) {
                if (handleError)
                    handleError(errorUptr, FONS_STATES_UNDERFLOW, 0);
                return;
            }
            nstates--;
        }


        void  ClearState(int nstates)
        {
            setState(nstates);
            _state->size = 12.0f;
            _state->color = 0xffffffff;
            _state->font = 0;
            _state->blur = 0;
            _state->spacing = 0;
            _state->align = FONS_ALIGN_LEFT | FONS_ALIGN_BASELINE;
        };

        void getQuad(TT* font,
            int prevGlyphIndex, FONSglyph* glyph,
            float scale, float spacing, float* x, float* y, FONSquad* q)
        {
            float rx, ry, xoff, yoff, x0, y0, x1, y1;
            if (prevGlyphIndex != -1) {
                float adv = font->getGlyphKernAdvance(prevGlyphIndex, glyph->index) * scale;
                *x += (int)(adv + spacing + 0.5f);
            }
            // Each glyph has 2px border to allow good interpolation,
            // one pixel to prevent leaking, and one to allow good interpolation for rendering.
            // Inset the texture region by one pixel for correct interpolation.
            xoff = (short)(glyph->xoff + 1);
            yoff = (short)(glyph->yoff + 1);
            x0 = (float)(glyph->x0 + 1);
            y0 = (float)(glyph->y0 + 1);
            x1 = (float)(glyph->x1 - 1);
            y1 = (float)(glyph->y1 - 1);

            if (params.flags & FONS_ZERO_TOPLEFT) {

                rx = (float)(int)(*x + xoff);
                ry = (float)(int)(*y + yoff);

                q->x0 = rx;
                q->y0 = ry;
                q->x1 = rx + x1 - x0;
                q->y1 = ry + y1 - y0;

                q->s0 = x0 * itw;
                q->t0 = y0 * ith;
                q->s1 = x1 * itw;
                q->t1 = y1 * ith;

            }
            else {
                rx = (float)(int)(*x + xoff);
                ry = (float)(int)(*y - yoff);

                q->x0 = rx;
                q->y0 = ry;
                q->x1 = rx + x1 - x0;
                q->y1 = ry - y1 + y0;

                q->s0 = x0 * itw;
                q->t0 = y0 * ith;
                q->s1 = x1 * itw;
                q->t1 = y1 * ith;
            }

            *x += (int)(glyph->xadv / 10.0f + 0.5f);
        };

        float TextBounds(int nstates,
            float x, float y,
            const char* str, const char* end,
            float* bounds)
        {
            setState(nstates);

            unsigned int codepoint;
            unsigned int utf8state = 0;

            FONSquad q;
           FONSglyph* glyph = NULL;

            int prevGlyphIndex = -1;
            short isize = (short)(_state->size * 10.0f);
            short iblur = (short)_state->blur;
            float scale;

            TT* font;
            float startx, advance;
            float minx, miny, maxx, maxy;

            if (_state->font < 0 || _state->font >= nfonts) return 0;

            font = fonts[_state->font];
            if (font->data == NULL) return 0;

            scale =  font->getPixelHeightScale((float)isize / 10.0f);
            y += font->getVertAlign(params.flags, _state->align, isize);

            minx = maxx = x;
            miny = maxy = y;
            startx = x;

            if (end == NULL)
                end = str + strlen(str);

            for (; str != end; ++str) {
                if (decodeUtf8(&utf8state, &codepoint, *(const unsigned char*)str))
                    continue;
                glyph = getGlyph(font, codepoint, isize, iblur, FONS_GLYPH_BITMAP_OPTIONAL);
                if (glyph != NULL) {
                    fons__getQuad(font, prevGlyphIndex, glyph, scale, state->spacing, &x, &y, &q);
                    if (q.x0 < minx) minx = q.x0;
                    if (q.x1 > maxx) maxx = q.x1;
                    if (stash->params.flags & FONS_ZERO_TOPLEFT) {
                        if (q.y0 < miny) miny = q.y0;
                        if (q.y1 > maxy) maxy = q.y1;
                    }
                    else {
                        if (q.y1 < miny) miny = q.y1;
                        if (q.y0 > maxy) maxy = q.y0;
                    }
                }
                prevGlyphIndex = glyph != NULL ? glyph->index : -1;
            }

            advance = x - startx;

            // Align horizontally
            if (state->align & FONS_ALIGN_LEFT) {
                // empty
            }
            else if (state->align & FONS_ALIGN_RIGHT) {
                minx -= advance;
                maxx -= advance;
            }
            else if (state->align & FONS_ALIGN_CENTER) {
                minx -= advance * 0.5f;
                maxx -= advance * 0.5f;
            }

            if (bounds) {
                bounds[0] = minx;
                bounds[1] = miny;
                bounds[2] = maxx;
                bounds[3] = maxy;
            }

            return advance;
        }


        FONSglyph* getGlyph(TT* _font, unsigned int codepoint,
            short isize, short iblur, int bitmapOption)
        {
            int i, g, advance, lsb, x0, y0, x1, y1, gw, gh, gx, gy, x, y;
            float scale;
            FONSglyph* glyph = NULL;
            unsigned int h;
            float size = isize / 10.0f;
            int pad, added;
            unsigned char* bdst;
            unsigned char* dst;
            TT* font = _font;

            if (isize < 2) return NULL;
            if (iblur > 20) iblur = 20;
            pad = iblur + 2;

            // Reset allocator.
            nscratch = 0;

            // Find code point and size.
            h = hashInt(codepoint) & (FONS_HASH_LUT_SIZE - 1);
            i = font->lut[h];

            while (i != -1) {
                if (font->glyphs[i].codepoint == codepoint && font->glyphs[i].size == isize && font->glyphs[i].blur == iblur) {
                    glyph = &font->glyphs[i];
                    if (bitmapOption == FONS_GLYPH_BITMAP_OPTIONAL || (glyph->x0 >= 0 && glyph->y0 >= 0)) {
                        return glyph;
                    }
                    // At this point, glyph exists but the bitmap data is not yet created.
                    break;
                }
                i = font->glyphs[i].next;
            };

            
            g = font->getGlyphIndex(codepoint);
            // Try to find the glyph in fallback fonts.
            if (g == 0) {
                for (i = 0; i < font->nfallbacks; ++i) {
                    TT* fallbackFont = fonts[font->fallbacks[i]];
                    int fallbackIndex = font->getGlyphIndex(codepoint);
                    if (fallbackIndex != 0) {
                        g = fallbackIndex;
                        font = fallbackFont;
                        break;
                    }
                }
                // It is possible that we did not find a fallback glyph.
                // In that case the glyph index 'g' is 0, and we'll proceed below and cache empty glyph.
            }

            scale = font->getPixelHeightScale(size);
            font->buildGlyphBitmap(g, size, scale, &advance, &lsb, &x0, &y0, &x1, &y1);
            gw  = x1 - x0 + pad * 2;
            gh  = y1 - y0 + pad * 2;

            // Init glyph.
            if (glyph == NULL) {

                glyph = allocGlyph(font);
                glyph->codepoint = codepoint;
                glyph->size = isize;
                glyph->blur = iblur;
                glyph->next = 0;

                // Insert char to hash lookup.
                glyph->next = font->lut[h];
                font->lut[h] = font->nglyphs - 1;
            }
            glyph->index = g;
            glyph->x0 = (short)gx;
            glyph->y0 = (short)gy;
            glyph->x1 = (short)(glyph->x0 + gw);
            glyph->y1 = (short)(glyph->y0 + gh);
            glyph->xadv = (short)(scale * advance * 10.0f);
            glyph->xoff = (short)(x0 - pad);
            glyph->yoff = (short)(y0 - pad);

            if (bitmapOption == FONS_GLYPH_BITMAP_OPTIONAL) {
                return glyph;
            }

            // Rasterize
            dst = &stash->texData[(glyph->x0 + pad) + (glyph->y0 + pad) * stash->params.width];
            fons__tt_renderGlyphBitmap(&renderFont->font, dst, gw - pad * 2, gh - pad * 2, stash->params.width, scale, scale, g);

            // Make sure there is one pixel empty border.
            dst = &stash->texData[glyph->x0 + glyph->y0 * stash->params.width];
            for (y = 0; y < gh; y++) {
                dst[y * stash->params.width] = 0;
                dst[gw - 1 + y * stash->params.width] = 0;
            }
            for (x = 0; x < gw; x++) {
                dst[x] = 0;
                dst[x + (gh - 1) * stash->params.width] = 0;
            }

            // Debug code to color the glyph background
        /*	unsigned char* fdst = &stash->texData[glyph->x0 + glyph->y0 * stash->params.width];
            for (y = 0; y < gh; y++) {
                for (x = 0; x < gw; x++) {
                    int a = (int)fdst[x+y*stash->params.width] + 20;
                    if (a > 255) a = 255;
                    fdst[x+y*stash->params.width] = a;
                }
            }*/

            // Blur
            if (iblur > 0) {
                stash->nscratch = 0;
                bdst = &stash->texData[glyph->x0 + glyph->y0 * stash->params.width];
                fons__blur(stash, bdst, gw, gh, stash->params.width, iblur);
            }

            stash->dirtyRect[0] = fons__mini(stash->dirtyRect[0], glyph->x0);
            stash->dirtyRect[1] = fons__mini(stash->dirtyRect[1], glyph->y0);
            stash->dirtyRect[2] = fons__maxi(stash->dirtyRect[2], glyph->x1);
            stash->dirtyRect[3] = fons__maxi(stash->dirtyRect[3], glyph->y1);

            return glyph;
        }

            int allocFont()
        {
            TT* font = NULL;
            if (nfonts + 1 >  cfonts) {
                cfonts = cfonts == 0 ? 8 : cfonts * 2;
                fonts = (TT**)realloc(fonts, sizeof(TT*) *cfonts);
                if (fonts == NULL)
                    return -1;
            }
            font = (TT*)malloc(sizeof(TT));
            if (font == NULL) goto error;
            memset(font, 0, sizeof(TT));

            font->glyphs = (FONSglyph*)malloc(sizeof(FONSglyph) * FONS_INIT_GLYPHS);
            if (font->glyphs == NULL) goto error;
            font->cglyphs = FONS_INIT_GLYPHS;
            font->nglyphs = 0;

            fonts[nfonts++] = font;
            return nfonts - 1;

        error:

            font->freeFont();
            free(font);

            return FONS_INVALID;
        }

            int  AddFontMem(const char* name, unsigned char* data, int dataSize, int freeData)
            {
                int i, ascent, descent, fh, lineGap;

                int idx = allocFont();
                if (idx == FONS_INVALID)
                    return FONS_INVALID;

                TT* font = fonts[idx];

                strncpy(font->name, name, sizeof(font->name));
                font->name[sizeof(font->name) - 1] = '\0';

                // Init hash lookup.
                for (i = 0; i < FONS_HASH_LUT_SIZE; ++i)
                    font->lut[i] = -1;

                // Read in the font data.
                font->dataSize = dataSize;
                font->data = data;
                font->freeData = (unsigned char)freeData;

                // Init font
                nscratch = 0;
                if (!font->loadFont(data)) goto error;

                // Store normalized line height. The real line height is got
                // by multiplying the lineh by font size.
                font->getFontVMetrics(&ascent, &descent, &lineGap);
                fh = ascent - descent;
                font->ascender = (float)ascent / (float)fh;
                font->descender = (float)descent / (float)fh;
                font->lineh = (float)(fh + lineGap) / (float)fh;

                return idx;

            error:
                font->freeFont();
                free(font);
                nfonts--;
                return FONS_INVALID;
            }

    private:
        FONSstate states[FONS_MAX_STATES];
        FONSstate* _state;

    };

    struct TT {

        stbtt_fontinfo info;
        char name[64];
        unsigned char* data;
        int dataSize;
        unsigned char freeData;
        float ascender;
        float descender;
        float lineh;
        
        FONSglyph* glyphs;
        int lut[FONS_HASH_LUT_SIZE];
        int cglyphs;
        int nglyphs;
        
        int fallbacks[FONS_MAX_FALLBACKS];
        int nfallbacks;

    void  freeFont()
    {
            if (glyphs) free(glyphs);
            if (freeData && data) free(data);
    };

    int    loadFont(unsigned char* name)
    {
        int stbError;
        ///font.info.userdata = context;
        stbError = stbtt_InitFont(&info, name, 0);
        return stbError;
    };

    void  getFontVMetrics(int* ascent, int* descent, int* lineGap)
    {
        stbtt_GetFontVMetrics(&info, ascent, descent, lineGap);
    };

    float getPixelHeightScale(float size)
    {
        return stbtt_ScaleForPixelHeight(&info, size);
    };

    int    getGlyphIndex(int codepoint)
    {
        return stbtt_FindGlyphIndex(&info, codepoint);
    };

    int    buildGlyphBitmap(int glyph, float size, float scale,
        int* advance, int* lsb, int* x0, int* y0, int* x1, int* y1)
    {
        stbtt_GetGlyphHMetrics(&info, glyph, advance, lsb);
        stbtt_GetGlyphBitmapBox(&info, glyph, scale, scale, x0, y0, x1, y1);
        return 1;
    };

    void  renderGlyphBitmap(unsigned char* output, int outWidth, int outHeight, int outStride,
        float scaleX, float scaleY, int glyph)
    {
        stbtt_MakeGlyphBitmap(&info, output, outWidth, outHeight, outStride, scaleX, scaleY, glyph);
    };

    int   getGlyphKernAdvance(int glyph1, int glyph2)
    {
        return stbtt_GetGlyphKernAdvance(&info, glyph1, glyph2);
    };

    template<typename T>
    float getVertAlign(T flags, int align, short isize)
    {
        if (flags & (T)FONS_ZERO_TOPLEFT) {
            if (align & FONS_ALIGN_TOP) {
                return ascender * (float)isize / 10.0f;
            }
            else if (align & FONS_ALIGN_MIDDLE) {
                return (ascender + descender) / 2.0f * (float)isize / 10.0f;
            }
            else if (align & FONS_ALIGN_BASELINE) {
                return 0.0f;
            }
            else if (align & FONS_ALIGN_BOTTOM) {
                return descender * (float)isize / 10.0f;
            }
        }
        else {
            if (align & FONS_ALIGN_TOP) {
                return -ascender * (float)isize / 10.0f;
            }
            else if (align & FONS_ALIGN_MIDDLE) {
                return -(ascender + descender) / 2.0f * (float)isize / 10.0f;
            }
            else if (align & FONS_ALIGN_BASELINE) {
                return 0.0f;
            }
            else if (align & FONS_ALIGN_BOTTOM) {
                return -descender * (float)isize / 10.0f;
            }
        }

        return 0.0;

    };


    };

};


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