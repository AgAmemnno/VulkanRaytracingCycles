/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __UTIL_DEBUG2_H__
#define __UTIL_DEBUG2_H__
#include "util/util_logging.h"
#include "util/util_string.h"

#define MAX_HIT 15


//#define STAT_CLIENT
#ifndef WITH_STAT_AUX 
#define WITH_STAT_AUX 
#endif


#ifndef WITH_STAT_ALL 
#define WITH_STAT_ALL 
#endif

#define WITH_REDIS

#ifdef WITH_REDIS

#ifdef WITH_STAT_ALL 

#define STAT_BUF_MAX 64

#include <unordered_map>

#define CNT_MISS 0
#define CNT_HIT  1
 //rec  2 ~ 31
#define CNT_REC  2
#define CNT_indirect_lamp_emission 32
#define CNT_ao_bounce 33
#define CNT_sd_N 34
#define CNT_shader_prepare_closures 35
#define CNT_kernel_path_shader_apply_bg 36
#define CNT_kernel_path_shader_apply_shadow_transparency 37
#define CNT_kernel_path_shader_apply_blur 38
#define CNT_kernel_path_shader_apply_emission 39
#define CNT_direct_emission 40
#define CNT_shadow_blocked 41
#define CNT_has_emission 42
#define CNT_kernel_path_surface_bounce 43
#define CNT_direct_emissive_eval_constant 44
#define CNT_direct_emissive_eval_bg 45
#define CNT_direct_emissive_eval_sample 46

#define CNT_MAX_ALO 64
#define CNT_ADD(n) stat_aux.add(&stat_aux.counter[n])

static std::unordered_map<std::string, int>   eSTAT = {
    {"indirect_lamp_emission" , 10},
    {"ao_bounce" , 11},
    {"sd_N" , 12},
    {"shader_prepare_closures",13 },
    {"kernel_path_shader_apply_bg",14},
    {"kernel_path_shader_apply_shadow_transparency",15},
    {"kernel_path_shader_apply_blur",16},
    {"kernel_path_shader_apply_emission",17},
    {"direct_emission",18},
    {"shadow_blocked_opaque",19},
    {"shadow_blocked",20},
    {"has_emission",21},
    {"kernel_path_surface_bounce",22}
};

#include "D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders\\intern\\kernel\\prof\\bp_def.h"

/*
///float3
#define indirect_lamp_emission_emission 0
#define indirect_lamp_emission_direct_emission 1 
#define indirect_lamp_emission_indirect  2
#define sd_N_f3  3
#define shader_prepare_closures_sum 4
#define kernel_path_shader_apply_bg 5
#define kernel_path_shader_apply_emission_emission 6
#define kernel_path_shader_apply_emission_direct_emission 7
#define kernel_path_shader_apply_emission_indirect 8
#define direct_emission_diffuse  9
#define direct_emission_glossy  10
#define direct_emission_transmission 11 
#define direct_emission_sum_no_mis 12 
#define has_emission_shadow 13 
#define has_emission_throughput 14
#define shader_bsdf_sample_eval 15
#define shader_bsdf_multi_eval_sum_no_mis 16
#define kernel_path_background_L 17
#define shadow_blocked_ray_P 18
#define kernel_path_surface_bounce_thr 19
#define kernel_path_surface_bounce_rayD 20
#define direct_emission_light_eval 21
#define shader_bsdf_sample_eval_diffuse 22
#define shader_bsdf_sample_eval_glossy 23
#define shader_bsdf_sample_eval_transmission 24
#define shader_bsdf_sample_eval_transparent 25


///float
#define kernel_path_background_transparent 0
#define direct_emission_light_pdf 1
#define kernel_path_surface_bounce_pdf 2
///uint
#define kernel_path_shader_apply_state_flag 0
#define kernel_path_surface_bounce_state_bounce 1
#define kernel_path_surface_bounce_flag 2
#define shader_bsdf_sample_eval_light_pass 3
#define has_emission_nums  4

*/


static std::unordered_map<std::string, int>   eSTATV3 = {
    {"indirect_lamp_emission_emission" , 10},
    {"indirect_lamp_emission_direct_emission" , 11},
    {"indirect_lamp_emission_indirect" , 12},
    {"sd_N" , 13},
    {"shader_prepare_closures",14},
    {"kernel_path_shader_apply_bg",15},
    {"kernel_path_shader_apply_emission_emission",16},
    {"kernel_path_shader_apply_emission_direct_emission",17},
    {"kernel_path_shader_apply_emission_indirect",18},
    {"direct_emission_diffuse", 19},
    {"direct_emission_glossy", 20},
    {"direct_emission_transmission", 21},
    {"direct_emission_sum_no_mis", 22},
    {"has_emission_shadow", 23 },
    {"has_emission_throughput", 24},
    {"shader_bsdf_sample_eval", 25},
    {"shader_bsdf_multi_eval_sum_no_mis", 26},
};


#define STAT_DUMP(name,v) stat_aux.pixel_dump(#name,name,v)
#define STAT_DUMP_ADD(name) {uint32_t  i = 1; stat_aux.pixel_dump(#name, name, i, true);}


#define  LIMIT12345 1
#define  LIMIT54321 1

#endif


#define DUMP_OPTIX
#define DUMP_SD_BUFFERS
#define DUMP_CUDA
#define DUMP_SESSION

#ifndef DUMP_GEOM
//#define DUMP_GEOM
#endif
#ifdef DUMP_GEOM
#define OPTIX_DEBUG
#endif


#include <hiredis/hiredis.h>
#ifndef CREATOR_BUILD
#ifdef _MSC_VER
//#include <winsock2.h> /* For struct timeval */
#endif
#endif

#include  <vector>
#include  <string>
namespace macaron {

    class Base64 {
    public:
        template<class T>
        static std::string Encode(const std::vector<T>& data) {
            return Encode((BYTE*)data.data(), data.size() * sizeof(T));
        }
        template<class T>
        static std::string Encode(T data, size_t in_len) {

            static constexpr char sEncodingTable[] = {
              'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
              'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
              'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
              'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
              'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
              'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
              'w', 'x', 'y', 'z', '0', '1', '2', '3',
              '4', '5', '6', '7', '8', '9', '+', '/'
            };


            size_t out_len = 4 * ((in_len + 2) / 3);
            std::string ret(out_len, '\0');
            size_t i = 0;
            char* p = const_cast<char*>(ret.c_str());

            if (in_len > 1) {
                for (i = 0; i < in_len - 2; i += 3) {
                    *p++ = sEncodingTable[(data[i] >> 2) & 0x3F];
                    *p++ = sEncodingTable[((data[i] & 0x3) << 4) | ((int)(data[i + 1] & 0xF0) >> 4)];
                    *p++ = sEncodingTable[((data[i + 1] & 0xF) << 2) | ((int)(data[i + 2] & 0xC0) >> 6)];
                    *p++ = sEncodingTable[data[i + 2] & 0x3F];
                }
            }

            if (i < in_len) {
                *p++ = sEncodingTable[(data[i] >> 2) & 0x3F];
                if (i == (in_len - 1)) {
                    *p++ = sEncodingTable[((data[i] & 0x3) << 4)];
                    *p++ = '=';
                }
                else {
                    *p++ = sEncodingTable[((data[i] & 0x3) << 4) | ((int)(data[i + 1] & 0xF0) >> 4)];
                    *p++ = sEncodingTable[((data[i + 1] & 0xF) << 2)];
                }
                *p++ = '=';
            }

            return ret;
        }

        static std::string Decode(const std::string& input, std::string& out) {
            static constexpr unsigned char kDecodingTable[] = {
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
              52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
              64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
              15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
              64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
              41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
              64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
            };

            size_t in_len = input.size();
            if (in_len % 4 != 0) return "Input data size is not a multiple of 4";

            size_t out_len = in_len / 4 * 3;
            if (input[in_len - 1] == '=') out_len--;
            if (input[in_len - 2] == '=') out_len--;

            out.resize(out_len);

            for (size_t i = 0, j = 0; i < in_len;) {
                uint32_t a = input[i] == '=' ? 0 & i++ : kDecodingTable[static_cast<int>(input[i++])];
                uint32_t b = input[i] == '=' ? 0 & i++ : kDecodingTable[static_cast<int>(input[i++])];
                uint32_t c = input[i] == '=' ? 0 & i++ : kDecodingTable[static_cast<int>(input[i++])];
                uint32_t d = input[i] == '=' ? 0 & i++ : kDecodingTable[static_cast<int>(input[i++])];

                uint32_t triple = (a << 3 * 6) + (b << 2 * 6) + (c << 1 * 6) + (d << 0 * 6);

                if (j < out_len) out[j++] = (triple >> 2 * 8) & 0xFF;
                if (j < out_len) out[j++] = (triple >> 1 * 8) & 0xFF;
                if (j < out_len) out[j++] = (triple >> 0 * 8) & 0xFF;
            }

            return "";
        }

    };

}



#define  RD_ARRAY_PRINT(cmd,...){\
	redisReply* _reply = (redisReply*)redisCommand(c, cmd,__VA_ARGS__);\
	if( (_reply!=NULL) &  (_reply->type == REDIS_REPLY_ARRAY)) {\
		for (int j = 0; j < _reply->elements; j++) {\
			printf("%u) %s\n", j, _reply->element[j]->str);\
		}\
	};	freeReplyObject(_reply); }

#ifndef RD_CHECK
#define RD_CHECK(X) if ( !X || ((redisReply*)X)->type == REDIS_REPLY_ERROR ) { printf("Error\n"); exit(-1); }
#endif
#define RD_REPLY_PRINT(reply)printf("res: %s, num: %zu, type: %s\n", reply->str, reply->elements,reply_types[ reply->type ]);


#include "util/util_array.h"
#include "util/util_vector.h"
#include "util/util_texture.h"
#include "kernel/svm/svm_types.h"
#include <Windows.h>

using namespace ccl;


template<typename... Args>
std::string string_format(const char* fmt, Args... args)
{
    size_t size = snprintf(nullptr, 0, fmt, args...);
    std::string buf;
    buf.reserve(size + 1);
    buf.resize(size);
    snprintf(&buf[0], size + 1, fmt, args...);
    return buf;
}





#include <stdexcept>
#include <map>
inline unsigned int stoui(const std::string& s) 
{
    unsigned long lresult = stoul(s, 0, 10);
    unsigned int result = (unsigned int)lresult;
    if (result != lresult) throw -1;
    return result;
}


namespace dump {

    std::vector<std::string> split(std::string s, std::string delimiter);
    class RedisCli {
    private:
        
        struct BlednerInfo {
            HANDLE  signal12345;
            HANDLE  signal54321;
        }binfo = {NULL,NULL};

        int  currenyDB = 0;


        template<typename T>
        uint32_t Crc32_ComputeBuf(uint32_t crc32, T* pbuf, int buflen)

        {

            static const uint32_t crcTable[256] = {

                0x00000000,0x77073096,0xEE0E612C,0x990951BA,0x076DC419,0x706AF48F,0xE963A535,

                0x9E6495A3,0x0EDB8832,0x79DCB8A4,0xE0D5E91E,0x97D2D988,0x09B64C2B,0x7EB17CBD,

                0xE7B82D07,0x90BF1D91,0x1DB71064,0x6AB020F2,0xF3B97148,0x84BE41DE,0x1ADAD47D,

                0x6DDDE4EB,0xF4D4B551,0x83D385C7,0x136C9856,0x646BA8C0,0xFD62F97A,0x8A65C9EC,

                0x14015C4F,0x63066CD9,0xFA0F3D63,0x8D080DF5,0x3B6E20C8,0x4C69105E,0xD56041E4,

                0xA2677172,0x3C03E4D1,0x4B04D447,0xD20D85FD,0xA50AB56B,0x35B5A8FA,0x42B2986C,

                0xDBBBC9D6,0xACBCF940,0x32D86CE3,0x45DF5C75,0xDCD60DCF,0xABD13D59,0x26D930AC,

                0x51DE003A,0xC8D75180,0xBFD06116,0x21B4F4B5,0x56B3C423,0xCFBA9599,0xB8BDA50F,

                0x2802B89E,0x5F058808,0xC60CD9B2,0xB10BE924,0x2F6F7C87,0x58684C11,0xC1611DAB,

                0xB6662D3D,0x76DC4190,0x01DB7106,0x98D220BC,0xEFD5102A,0x71B18589,0x06B6B51F,

                0x9FBFE4A5,0xE8B8D433,0x7807C9A2,0x0F00F934,0x9609A88E,0xE10E9818,0x7F6A0DBB,

                0x086D3D2D,0x91646C97,0xE6635C01,0x6B6B51F4,0x1C6C6162,0x856530D8,0xF262004E,

                0x6C0695ED,0x1B01A57B,0x8208F4C1,0xF50FC457,0x65B0D9C6,0x12B7E950,0x8BBEB8EA,

                0xFCB9887C,0x62DD1DDF,0x15DA2D49,0x8CD37CF3,0xFBD44C65,0x4DB26158,0x3AB551CE,

                0xA3BC0074,0xD4BB30E2,0x4ADFA541,0x3DD895D7,0xA4D1C46D,0xD3D6F4FB,0x4369E96A,

                0x346ED9FC,0xAD678846,0xDA60B8D0,0x44042D73,0x33031DE5,0xAA0A4C5F,0xDD0D7CC9,

                0x5005713C,0x270241AA,0xBE0B1010,0xC90C2086,0x5768B525,0x206F85B3,0xB966D409,

                0xCE61E49F,0x5EDEF90E,0x29D9C998,0xB0D09822,0xC7D7A8B4,0x59B33D17,0x2EB40D81,

                0xB7BD5C3B,0xC0BA6CAD,0xEDB88320,0x9ABFB3B6,0x03B6E20C,0x74B1D29A,0xEAD54739,

                0x9DD277AF,0x04DB2615,0x73DC1683,0xE3630B12,0x94643B84,0x0D6D6A3E,0x7A6A5AA8,

                0xE40ECF0B,0x9309FF9D,0x0A00AE27,0x7D079EB1,0xF00F9344,0x8708A3D2,0x1E01F268,

                0x6906C2FE,0xF762575D,0x806567CB,0x196C3671,0x6E6B06E7,0xFED41B76,0x89D32BE0,

                0x10DA7A5A,0x67DD4ACC,0xF9B9DF6F,0x8EBEEFF9,0x17B7BE43,0x60B08ED5,0xD6D6A3E8,

                0xA1D1937E,0x38D8C2C4,0x4FDFF252,0xD1BB67F1,0xA6BC5767,0x3FB506DD,0x48B2364B,

                0xD80D2BDA,0xAF0A1B4C,0x36034AF6,0x41047A60,0xDF60EFC3,0xA867DF55,0x316E8EEF,

                0x4669BE79,0xCB61B38C,0xBC66831A,0x256FD2A0,0x5268E236,0xCC0C7795,0xBB0B4703,

                0x220216B9,0x5505262F,0xC5BA3BBE,0xB2BD0B28,0x2BB45A92,0x5CB36A04,0xC2D7FFA7,

                0xB5D0CF31,0x2CD99E8B,0x5BDEAE1D,0x9B64C2B0,0xEC63F226,0x756AA39C,0x026D930A,

                0x9C0906A9,0xEB0E363F,0x72076785,0x05005713,0x95BF4A82,0xE2B87A14,0x7BB12BAE,

                0x0CB61B38,0x92D28E9B,0xE5D5BE0D,0x7CDCEFB7,0x0BDBDF21,0x86D3D2D4,0xF1D4E242,

                0x68DDB3F8,0x1FDA836E,0x81BE16CD,0xF6B9265B,0x6FB077E1,0x18B74777,0x88085AE6,

                0xFF0F6A70,0x66063BCA,0x11010B5C,0x8F659EFF,0xF862AE69,0x616BFFD3,0x166CCF45,

                0xA00AE278,0xD70DD2EE,0x4E048354,0x3903B3C2,0xA7672661,0xD06016F7,0x4969474D,

                0x3E6E77DB,0xAED16A4A,0xD9D65ADC,0x40DF0B66,0x37D83BF0,0xA9BCAE53,0xDEBB9EC5,

                0x47B2CF7F,0x30B5FFE9,0xBDBDF21C,0xCABAC28A,0x53B39330,0x24B4A3A6,0xBAD03605,

                0xCDD70693,0x54DE5729,0x23D967BF,0xB3667A2E,0xC4614AB8,0x5D681B02,0x2A6F2B94,

                0xB40BBE37,0xC30C8EA1,0x5A05DF1B,0x2D02EF8D };



            int i;

            int iLookup;

            for (i = 0; i < buflen; i++) {

                iLookup = (crc32 & 0xFF) ^ (*pbuf++);

                crc32 = ((crc32 & 0xFFFFFF00) >> 8) & 0xFFFFFF;  // ' nasty shr 8 with vb :/

                crc32 = crc32 ^ crcTable[iLookup];

            }

            return crc32;

        }
        template<typename T>
        uint32_t  crc32_of_buffer(T* buf, int buflen)

        {

            return Crc32_ComputeBuf(0xFFFFFFFF, buf, buflen) ^ 0xFFFFFFFF;

        }


    public:
        std::string debugStr;
        std::string Status;
        redisContext* c = NULL;
        bool dump34;
        bool tex_dump = true;
        std::map<int,std::string> noDumpSlot;

        RedisCli();
        ~RedisCli();
        void connect();
        void disconnect();

        template<typename T>
        void Signal(T i) {
            LONG prev;
            if ((int)i == 12345) {
                ReleaseSemaphore(binfo.signal12345, 1, &prev);
            }
        }
        template<typename T>
        void Wait(T i) {
            LONG prev;
            if ((int)i == 54321) {
                WaitForSingleObject(binfo.signal54321, INFINITE);
            }
        }
    
        /*
            0x00000000 (WAIT_OBJECT_0)
            0x00000080 (WAIT_ABANDONED)
            0x00000102 (WAIT_TIMEOUT)
            0xFFFFFFFF (WAIT_FAILED)
        */
        template<typename T>
        void ConsumeWait(T i,LONG mx) {

            for(int i=0;i< mx;i++){
                DWORD ret = WaitForSingleObject(binfo.signal54321, 10);
               if(ret == WAIT_OBJECT_0) printf("Consume  semaphore%u   %u \n ", (UINT)i, ret);
            }

        }
        template<typename T>
        void  SelectDB(T n) {

            if (n != currenyDB) {

                redisReply* reply;
                reply = (redisReply*)redisCommand(c, "SELECT %d", n);
                RD_CHECK(reply);
                freeReplyObject(reply);
                currenyDB = n;
            }

        }
        template<typename T>
        void  FlushDB(T n) {

            redisReply* reply;
            reply = (redisReply*)redisCommand(c, "SELECT %d", n);
            RD_CHECK(reply);
            freeReplyObject(reply);

            reply = (redisReply*)redisCommand(c, "FLUSHDB");
            RD_CHECK(reply);
            freeReplyObject(reply);

            currenyDB = n;
        }

        template<class T>
        void write_tex_nodes(T* node, const char* name) {
            if (!dump34)return;
            if (node->filename == NULL) return;
            using namespace macaron;
            SelectDB(3);
            size_t size = sizeof(T);
            const char* KEY = "SVM::NODES";
            Base64  b64;
            auto enc  = b64.Encode((BYTE*)node, size);
            RD_CHECK(redisCommand(c, "HSET %s  %s  %s ", KEY,name,node->filename));
            RD_CHECK(redisCommand(c, "HSET %s  %s  %s ", name, node->filename,enc.data()));
            RD_CHECK(redisCommand(c, "HSET colorspace  %s  %s ", node->filename,node->colorspace));

        };

        template<typename U,typename T>
        void   write_ustring(U& str, T* Key, const char* name) {
            if (!dump34)return;
            using namespace macaron;
            redisReply* reply = nullptr;
            SelectDB(4);
            {
                size_t        size = str.size();
                printf(" %s   %s    size %zu   \n", Key, name, size);


                if (size > 0) {
                    RD_CHECK(redisCommand(c, " HSET %s  %s:char %b", Key, name, str.data(), str.size()));
                }
                else {
                    RD_CHECK(redisCommand(c, " HSET %s  %s:char none", Key, name));
                }

            }

        };

        template<typename T, typename TDesc, typename RDesc>
        uint32_t textureStore(T& mem, TDesc& tDesc, RDesc& rDesc) {

            std::string  HASH;
            uint32_t crcID;
            using namespace macaron;
            redisReply* reply = nullptr;
            Base64  b64;
            SelectDB(6);


            bool dump_Data = true;
            decltype(noDumpSlot)::iterator it = noDumpSlot.find(mem.slot);
            if (it != noDumpSlot.end()) { 
                std::string  ptr = noDumpSlot[mem.slot];
                crcID = crc32_of_buffer((BYTE*)ptr.data(), (int)ptr.size());
                std::cout << "no dump texture  found.    " <<    ptr   <<   "   crcID   " << crcID << std::endl;
                dump_Data = false;
            }


            if (dump_Data) {
                BYTE* ptr = (BYTE*)(mem.host_pointer);
                auto size = mem.memory_size();
                crcID = crc32_of_buffer(ptr, (int)size);
                HASH = "Texture::" + std::to_string(crcID);
                if (GetKeys<char*>(HASH.c_str()).size() == 0)
                {
                    printf("  Texture Storing [%s]    size %zu   \n", HASH.c_str(), size);
#define __print(t,form){\
            t* p = (t*)mem.host_pointer;int i = 0;\
            for (; i < ((mem.data_size<1024) ?mem.data_size:1024) ; i++){\
                printf("[%d] {   ", i);\
            for (int j = 0; j < mem.data_elements; j++)\
                printf(form, p[i * mem.data_elements + j]);\
              printf("}\n");}\
            }
   
                    auto eStr = b64.Encode(ptr, size);
                    RD_CHECK(redisCommand(c, " HSET %s  data %b", HASH.c_str(), eStr.data(), eStr.size()));
                }
            }
            else 
            {
                HASH = "Texture::" + noDumpSlot[mem.slot];
            }


            BYTE*  ptr = (BYTE*)&tDesc;
            auto size = sizeof(TDesc);
            auto eStr = b64.Encode(ptr, size);
            RD_CHECK(redisCommand(c, " HSET %s  tDesc %b", HASH.c_str(), eStr.data(), eStr.size()));

            ptr = (BYTE*)&rDesc;
            size = sizeof(RDesc);
            eStr = b64.Encode(ptr, size);
            RD_CHECK(redisCommand(c, " HSET %s  rDesc %b", HASH.c_str(), eStr.data(), eStr.size()));


#undef __print
           return crcID;
            


        };
        template<typename T>
        void mesh_array(ccl::array<T>& ary, const char* name, int n) {
            if (!dump34)return;
            //kernel_global_memory_copy(&kernel_globals, mem.name, mem.host_pointer, mem.data_size);
            using namespace macaron;
            redisReply* reply = nullptr;
            SelectDB(4);

            const char* KEY = "Mesh";
            {
                size_t        size = ary.size() * sizeof(T);
                if (size <= 0) return;
                printf("  Mesh::array::   %s    size %zu   \n", name, size);
#define __print(t,form){\
            t* p = (t*)mem.host_pointer;int i = 0;\
            for (; i < ((mem.data_size<1024) ?mem.data_size:1024) ; i++){\
                printf("[%d] {   ", i);\
            for (int j = 0; j < mem.data_elements; j++)\
                printf(form, p[i * mem.data_elements + j]);\
              printf("}\n");}\
            }


                Base64  b64;
                RD_CHECK(redisCommand(c, " HSET %s::%u::array::%d  size:%s %d ", KEY, _threadid, n, name, size));

                if (size > 0) {
                    BYTE* ptr = (BYTE*)(ary.data());
                    RD_CHECK(redisCommand(c, " HSET %s::%u::array::%d  crc:%s  %u  ", KEY, _threadid, n, name, crc32_of_buffer(ptr, (int)size)));
                    auto eStr = b64.Encode(ptr, size);
                    RD_CHECK(redisCommand(c, " HSET %s::%u::array::%d  data:%s %b", KEY, _threadid, n, name, eStr.data(), eStr.size()));
                }


            }
#undef __print


        };
        template<class T>
        void mesh_body(T* geom, int n) {
            if (!dump34)return;
            if (
                (!geom) |
                (!(geom->type == Geometry::MESH || geom->type == Geometry::VOLUME))
                )return;

            Mesh* const mesh = static_cast<Mesh* const>(geom);
            SelectDB(4);

            const char* KEY = "Mesh";

            using namespace ccl;
            using namespace macaron;
#define FIELD(name) #name,name.data(),name.size()
#define struct_enc(ptr, str,name,size) auto name  = b64.Encode((BYTE*)ptr,sizeof(str)*size );

            Base64  b64;
            struct_enc(geom, Mesh, __mesh, 1)
                RD_CHECK(redisCommand(c, "HMSET %s::%u::body::%d %s %b ", KEY, _threadid, n,
                    FIELD(__mesh))
                );
                RD_CHECK(redisCommand(c, " HSET %s::%u::array::%d  hashID         %llu  ", KEY, _threadid, n, (uint64_t)geom));
                RD_CHECK(redisCommand(c, " HSET %s::%u::array::%d  isInstanced  %d  ", KEY, _threadid, n, (int)geom->is_instanced() ));
            /* Mesh Data */
#define dump_array(name) mesh_array(mesh->name,#name,n);
                dump_array(triangles)
                dump_array(verts)
                dump_array(shader)
                dump_array(smooth)
                dump_array(triangle_patch)
                dump_array(vert_patch_uv)
                dump_array(subd_faces)
                dump_array(subd_face_corners)
                dump_array(subd_creases)

#undef struct_enc
#undef FIELD

        }
        template<class T>
        void  object_body(T* obj) {

            if (
                (!obj)
                )return;





            std::string Key = "Obj::" + std::to_string(_threadid) + "::body::" + std::to_string(obj->get_device_index());

            using namespace ccl;
            using namespace macaron;
#define FIELD(name) #name,name.data(),name.size()
#define struct_enc(ptr, str,name,size) auto name  = b64.Encode((BYTE*)ptr,sizeof(str)*size );

            Base64  b64;
            struct_enc(obj, Object, __object, 1)
                RD_CHECK(redisCommand(c, "HMSET %s %s %b ", Key.c_str(),
                    FIELD(__object))
                );

            auto  key = Key.c_str();

            write_ustring(obj->asset_name, key, "asset_name");



#undef struct_enc
#undef FIELD

        }
        template<class T>
        void write_objects(ccl::vector<T*> objs) {
            if (!dump34)return;
            SelectDB(4);
            size_t size = objs.size();
            const char* KEY = "Obj";
            RD_CHECK(redisCommand(c, "SET %s::%u  %d ", KEY, _threadid, (int)size));

            foreach(Object * obj, objs) { object_body(obj); }

        };
        template<class T>
        void write_geoms(ccl::vector<T*> geoms) {
            if (!dump34)return;
            SelectDB(4);
            size_t size = geoms.size();
            const char* KEY = "Mesh";
            RD_CHECK(redisCommand(c, "SET %s::%u  %d ", KEY, _threadid, (int)size));
            int i = 0;

            foreach(T * geom, geoms) {
                mesh_body(geom, i++);
            }

        };
        template<class T>
        void kg_textures(T& mem) {
            if (!dump34)return;
            //kernel_global_memory_copy(&kernel_globals, mem.name, mem.host_pointer, mem.data_size);
            using namespace macaron;
            redisReply* reply = nullptr;
            SelectDB(3);


#  define KERNEL_TEX(type, tname) \
  else if (strcmp(mem.name, #tname) == 0) \
  { \
		size_t        size = mem.data_size *mem.data_elements;\
	    std::string key   = #tname; \
        if(size > 0){\
		    BYTE* ptr = (BYTE*)(mem.host_pointer); \
			Base64  b64; \
			auto eStr = b64.Encode(ptr,size); \
			reply = (redisReply*)redisCommand(c, "SET %b %b", key.c_str(), key.size(), eStr.data(), eStr.size()); \
		}else{\
             reply = (redisReply*)redisCommand(c, "SET %b 0", key.c_str(), key.size());}\
     printf("  redis::set   %s    size %zu   reply %d   \n", tname,size, reply->type);}


            const char* KEY = "KG:tex";
            {
                size_t        size = mem.data_size * mem.data_elements * datatype_size(mem.data_type);
                printf("  redis::set   %s    size %zu   \n", mem.name, size);
#define __print(t,form){\
            t* p = (t*)mem.host_pointer;int i = 0;\
            for (; i < ((mem.data_size<1024) ?mem.data_size:1024) ; i++){\
                printf("[%d] {   ", i);\
            for (int j = 0; j < mem.data_elements; j++)\
                printf(form, p[i * mem.data_elements + j]);\
              printf("}\n");}\
            }
                auto deb = [&]() {
                    switch (mem.data_type) {
                    case TYPE_UNKNOWN:
                        printf("TYPE UNKNOWN STRUCT \n");
                        break;
                    case TYPE_UCHAR:
                        __print(BYTE, " %u ");
                        break;
                    case TYPE_UINT16:
                        __print(UINT16, " %u ");
                        break;
                    case TYPE_UINT:
                        __print(UINT, " %u ");
                        break;
                    case TYPE_INT:
                        __print(INT, " %d ");
                        break;
                    case TYPE_FLOAT:
                        __print(float, " %.5f ");
                        break;
                    case TYPE_HALF:
                        __print(half, " %.4f ");
                        break;
                    case TYPE_UINT64:
                        __print(UINT64, " %zu ");
                        break;
                    default:
                        break;
                    };
                };



                Base64  b64;
                std::string eStr;
                eStr = b64.Encode((BYTE*)(&mem), sizeof(device_memory));
                RD_CHECK(redisCommand(c, " HSET %s:%u  %s %b", KEY, _threadid, mem.name, eStr.data(), eStr.size()));

                if (size > 3 && 
                        !(
                            std::string(mem.name) == "__light_background_conditional_cdf" ||
                            std::string(mem.name) == "__light_background_marginal_cdf"
                            )
                    ) {
                    BYTE* ptr = (BYTE*)(mem.host_pointer);
                    RD_CHECK(redisCommand(c, " HSET %s:%u  %s:crc  %u ", KEY, _threadid, mem.name, crc32_of_buffer(ptr, size)));
                    auto eStr = b64.Encode(ptr, size);
                    RD_CHECK(redisCommand(c, " HSET %s:%u  %s:data %b", KEY, _threadid, mem.name, eStr.data(), eStr.size()));
#ifdef RD_DEB_PRINT
                    deb();
#endif
                }
                else {
                    RD_CHECK(redisCommand(c, " HSET %s:%u %s:data 0", KEY, _threadid, mem.name));
                }

            }


#undef __print
#undef KERNEL_TEX

        };
        template<class T>
        void kg_body(T* kg) {
            if (!dump34)return;
            if (!kg) return;
            SelectDB(3);


            const char* KEY = "KG:body";

            using namespace ccl;
            using namespace macaron;
#define FIELD(name) #name,name.data(),name.size()
#define struct_enc(ptr, str,name,size) auto name  = b64.Encode((BYTE*)ptr,sizeof(str)*size );

            Base64  b64;
            struct_enc(kg, T, __KernelGlobals, 1)
                RD_CHECK(redisCommand(c, "HMSET %s:%u %s %b ", KEY, _threadid,
                    FIELD(__KernelGlobals))
                );

#undef struct_enc
#undef FIELD




        };

        template<class T>
        void kg_static_ptr(T* kg) {
            /*
            Intersection* transparent_shadow_intersections;
            // Storage for decoupled volume steps.
            VolumeStep* decoupled_volume_steps[2];
            int decoupled_volume_steps_index;
            // A buffer for storing per-pixel coverage for Cryptomatte.
            CoverageMap* coverage_object;
            CoverageMap* coverage_material;
            CoverageMap* coverage_asset;
            */
            if (!dump34)return;
#define struct_enc(ptr, str, size)  std::string ptr = "0"; if(kg->ptr != nullptr)ptr  = b64.Encode((BYTE*)(kg->ptr),sizeof(str)*size );
#define FIELD(name) #name, name.data() ,name.size()

            using namespace ccl;
            using namespace macaron;
            const char* KEY = "KG:body";
            Base64  b64;
            SelectDB(3);

            struct_enc(transparent_shadow_intersections, Intersection, 1)
                ///struct_enc(decoupled_volume_steps, VolumeStep,  2)
                RD_CHECK(redisCommand(c, "HMSET %s:%u %s %b ", KEY, _threadid,
                    FIELD(transparent_shadow_intersections)));

#undef struct_enc
#undef FIELD
        };

        template<class T>
        void kg_body_optix(T* kg) {
            if (!dump34)return;
            struct ShaderParams {
                uint4* input;
                float4* output;
                int type;
                int filter;
                int sx;
                int offset;
                int sample;
            };
            struct KernelParams {
                WorkTile tile;
                KernelData data;
                ShaderParams shader;
            };
            if (!kg) return;
            SelectDB(3);

            const char* KEY = "KG:params";

            using namespace ccl;
            using namespace macaron;
#define FIELD(name) #name,name.data(),name.size()
#define struct_enc(ptr, str,name,size) auto name  = b64.Encode((BYTE*)ptr,sizeof(str)*size );

            Base64  b64;
            if (sizeof(T) == sizeof(KernelData)) {
                struct_enc(kg, T, __KernelData, 1)
                    RD_CHECK(redisCommand(c, "HMSET %s:%u %s %b ", KEY, _threadid,
                        FIELD(__KernelData))
                    );
                    RD_CHECK(redisCommand(c, "HMSET %s:Update  TID  %u  ", KEY, _threadid));
            }
            else if (sizeof(T) == sizeof(ShaderParams)) {
                struct_enc(kg, T, __ShaderParams, 1)
                    RD_CHECK(redisCommand(c, "HMSET %s:%u %s %b ", KEY, _threadid,
                        FIELD(__ShaderParams))
                    );
            }
            else if (sizeof(T) == sizeof(WorkTile)) {
                struct_enc(kg, T, __WorkTile, 1)
                    RD_CHECK(redisCommand(c, "HMSET %s:%u %s %b ", KEY, _threadid,
                        FIELD(__WorkTile))
                    );
            }


#undef struct_enc
#undef FIELD




        };

        template<class T>
        void tile_rb(T tile) {
            if (!dump34)return;
            const char* KEY = "TILE";
            std::string pattern = std::string(KEY) + "*";

            using namespace ccl;
            using namespace macaron;
            redisReply* reply = nullptr;

            SelectDB(3);


#define FIELD(name) #name,name.data(),name.size()
#define struct_enc(ptr, str,name,size) auto name  = b64.Encode((BYTE*)ptr,sizeof(str)*size );



            Base64  b64;


            int i = 0;
            for (Pass p : tile.buffers->params.passes) {
                auto name = b64.Encode((BYTE*)(&p), sizeof(Pass));
                reply = (redisReply*)redisCommand(c, "HMSET %s:%u  Pass:%d %b ", KEY, _threadid, i++, name.data(), name.size());
            }


            struct_enc(tile.buffers, RenderBuffers, __RenderBuffers, 1)

                reply = (redisReply*)redisCommand(c, "HMSET %s:%u %s %b ", KEY, _threadid,
                    FIELD(__RenderBuffers));

            // RenderBuffers  _rb(nullptr);
            //decodeStruct(&_rb, pattern.c_str(), "__RenderBuffers");



            struct_enc(&tile, RenderTile, __RenderTile, 1)

                reply = (redisReply*)redisCommand(c, "HMSET %s:%u %s %b ", KEY, _threadid,
                    FIELD(__RenderTile));

            //RenderTile  _rt;
            //decodeStruct(&_rt, pattern.c_str(), "__RenderTile");


#undef struct_enc
#undef FIELD

        };

       
        std::string  format(float3 val);
        std::string  format(int2 val);
        std::string  format(float val);
        std::string  format(UINT val);

        template<typename T>
        void pixel_dump_incr(T name, int No) {

            SelectDB(5);
            std::string HASH = "tileInfo::UINT";
            RD_CHECK(redisCommand(c, "HSET %s  %s  %d  ", HASH.c_str(), name.c_str(), No));
            redisReply* reply = (redisReply*)redisCommand(c, "HGET %s %d  ", name.c_str(), No);
            if (reply->len > 0) {
                int   n = std::atoi(reply->str) + 1;
                RD_CHECK(redisCommand(c, "HSET %s  %d  %d ", name.c_str(), No,n));
            }else RD_CHECK(redisCommand(c, "HSET %s  %d  1 ", name.c_str(), No));

            freeReplyObject(reply);
           /// RD_CHECK(redisCommand(c, "HINCRBY %s  %d  1 ", name.c_str(), No));

        };

        template<typename T>
        void pixel_dump(std::string name, int No, T& val) {

            /// for  tile
            ///   hash   key value 
            ///   kernel_path_background_name    bufferNo   valuestring

            /// tileInfoF3 
            ///                   kernel_path_background_name bufferNo  ,kernel_path_background_name2 bufferNo2  ,kernel_path_background_name3 bufferNo3  ,
            /// tileInfoF1  kernel_path_background_name bufferNo
            /// tileInfoU1  kernel_path_background_name bufferNo
            /// 
            /// buffer    32*N
            SelectDB(5);
           // printf("typename %s \n ", typeid(T).name());
            std::string HASH;
            auto tname = std::string(typeid(T).name());
            if (tname != "unsigned int") {
                auto sv = split(tname, " ");
                HASH = "tileInfo::" + std::string((sv.size() > 1) ? sv[sv.size() - 1] : sv[0]);
            }
            else HASH = "tileInfo::UINT";
            std::string  VAL       = format(val);


            RD_CHECK(redisCommand(c, "HSET %s  %s  %d  ", HASH.c_str(), name.c_str(), No));
            RD_CHECK(redisCommand(c, "HSET %s  %d  %s ", name.c_str(), No, VAL.c_str()));

        };

        template<class T>
        void kg_data(const char* name,T* data,int width) {

            //kernel_global_memory_copy(&kernel_globals, mem.name, mem.host_pointer, mem.data_size);
            using namespace macaron;
            redisReply* reply = nullptr;
            SelectDB(11);

            const char* KEY = "KG:data";
            {
                size_t        size = sizeof(T) * width;
                if (size <= 0) return;
                printf(" Buffer Dump   size %zu   \n", size);
                Base64  b64;
                std::string eStr = b64.Encode((BYTE*)(data), size);
                RD_CHECK(redisCommand(c, " HSET %s  %s::size  %u ", KEY, name, uint32_t( size)));
                RD_CHECK(redisCommand(c, " HSET %s  %s  %b ", KEY, name, eStr.data(), eStr.size()));

            }

        };


        void send12345(int2 val, int recmx);
        void wait54321(bool& abort);
     
    protected:

        template<class T>
        void decodeStruct(T* strc, const char* hkey, const char* name, size_t size = 1) {
            using namespace macaron;
            Base64  b64;
            redisReply* reply = nullptr;
            for (auto key : GetKeys<char*>(hkey)) {
                reply = (redisReply*)redisCommand(c, "HGETALL %s", key);
                for (int i = 0; i < reply->elements; i += 2) {
                    printf("   HKEY   %s    ", reply->element[i]->str);
                    if (std::string(reply->element[i]->str) == name) {
                        std::string rStr;
                        std::string rstr = reply->element[i + 1]->str;
                        b64.Decode(rstr, rStr);
                        BYTE* ptr2 = (BYTE*)rStr.data();
                        printf(" hkey %s  struct  %s   memcpy to dst   \n ", key, name);
                        memcpy((BYTE*)strc, ptr2, sizeof(T) * size);
                    }
                }
            }
            freeReplyObject(reply);
        }

        template<class T>
        std::vector<T> GetKeys(const char* pattern) {

            std::vector<T> argv;

            redisReply* reply = (redisReply*)redisCommand(c, "KEYS %b ", pattern, strlen(pattern));
            if (reply->type == REDIS_REPLY_ARRAY) {
                for (int j = 0; j < reply->elements; j++) {
                    argv.push_back(const_cast<T>(reply->element[j]->str));
                }
            }
            return argv;
        }


    };
}


extern  dump::RedisCli* redis;



#endif





#ifndef STAT_CLIENT

#include <random>


struct  RenderTileHeader {
    typedef enum { PATH_TRACE = (1 << 0), BAKE = (1 << 1), DENOISE = (1 << 2) } Task;
    Task task;
    int x, y, w, h;
    int start_sample;
    int num_samples;
    int sample;
    int resolution;
    int offset;
    int stride;
    int tile_index;
};

struct STATS_AUX {
    long   amt;
    long   hit, miss;
    long   hit_rec;
    long   hit_rec_cnt[MAX_HIT];
    long   counter[MAX_HIT*12];

    long lampemi;
    long randu, randv, randw;
    const float  precision = 1000.f;
    long  node_profi;
    bool  write;
    bool  init_off;
    int    rec_num;

#ifdef WITH_STAT_AUX 
    int   dump_num;
    bool  use_light_pass;
    long   obj_reg[MAX_HIT];
    long  tile_miss; 
   
    bool  use_rsend,use_pixel, use_buffer_dump;
    struct send_info {
        RenderTileHeader* tile = nullptr;
        int     dump_hitN;
        bool   obj_has_send;
        bool   obj_send;
        bool    bg_send;
        int              x,y;
        int             rx,ry;
        int     objectID;  //bg 1000
        /// tileXY   objectID  {x,y}
        bool  abort;
    }sinfo;
#endif  

    void init(std::string deb = "");
    void end();
    void start(bool);
    void addV3(ccl::float3& v);
    long add(long* v);
    long add(long* v, long val);

#ifdef WITH_STAT_ALL 
    long addMiss();
    long add(std::string n);
    long add(std::string n, ccl::float3& f3, float prec = 1000.f);
    bool objectAdd(int i);
#endif

    void print();
    bool getAtomicPrint(bool off = false);

#if defined(WITH_REDIS) && defined(WITH_STAT_AUX)

    void node_print(int offset , uint4 node) {
        if (!sinfo.obj_send)return;
        //printf(" NODE offset %d   node x %u  y %u  z %u  w %u  \n ", offset - 1, node.x, node.y, node.z, node.w);
    }

    template<class T>
    void pixel_dump(std::string name, int No, T& val, bool add = false) {
        if (!(sinfo.bg_send || sinfo.obj_send)) return;
        if (sinfo.abort)return;

        //if (sinfo.obj_send && sinfo.dump_hitN != rec_num)return;
        
        if (add) {
            redis->pixel_dump_incr(name, No);
        }
        else {
            No = No + (rec_num - 1) * STAT_BUF_MAX;
            redis->pixel_dump(name, No, val);
        }

    };

#define DUMP_KG_DATA(mem) redis->kg_data(#mem,mem.data,(int)mem.width);
    template<typename T,typename T2>
    void pixel_init(T x, T y, T2* kg = nullptr) {
        sinfo.x = (int)x; sinfo.y = (int)y;
        if (x == 369  && y == 192) {
            printf("debug ");
        }
        if (use_rsend) {
            if ((sinfo.rx == (sinfo.x % sinfo.tile->w)) && (sinfo.ry == (sinfo.y % sinfo.tile->h))) {
                sinfo.obj_send = true;
            }
        }
        else if (use_pixel) {
            if ((sinfo.rx == sinfo.x) && (sinfo.ry == sinfo.y)) {
                sinfo.obj_send = true;
                if (use_buffer_dump) {
                    assert(kg->__prim_tri_verts.data);
                    DUMP_KG_DATA(kg->__prim_tri_verts);
                    assert(kg->__prim_tri_index.data);
                    DUMP_KG_DATA(kg->__prim_tri_index);
                    assert(kg->__tri_vindex.data);
                    DUMP_KG_DATA(kg->__tri_vindex);
                    assert(kg->__prim_object.data);
                    DUMP_KG_DATA(kg->__prim_object);
                    assert(kg->__prim_index.data);
                    DUMP_KG_DATA(kg->__prim_index);

                    use_buffer_dump = false;
                }
            }
        }
    }


    template<class T>
    void tile_init(T* tile){

        tile_miss = 0;
        sinfo.dump_hitN = 1;
        sinfo.obj_send = false;
        sinfo.obj_has_send = false;
        sinfo.bg_send = false;
        sinfo.objectID = 0;  //bg 1000
        for (int i = 0; i < MAX_HIT; i++)obj_reg[i] = 0;

        if (use_rsend) {
            static  std::random_device seed_gen;
            static  std::mt19937 engine(seed_gen());


            sinfo.tile = (RenderTileHeader*)tile;
            std::uniform_int_distribution<int> distW(0, tile->w);
            sinfo.rx = distW(engine);
            std::uniform_int_distribution<int> distH(0, tile->h);
            sinfo.ry = distH(engine);

        }
    };

    void send_byPixel();
    void send_byObject();
#endif

};

#else
#define REDIS_ASSERT(reply,msg) if( (reply->len) <= 0) log_bad(msg);


struct STATS_AUX {

    typedef   std::unordered_map<std::string, int> mapty;
    typedef   std::pair<std::string, std::string>     str2;
    mapty    bpf3_name;// breakPoint;
    mapty    bpf1_name;// breakPoint;
    mapty    bpu1_name;// breakPoint;

    typedef   std::unordered_map< int ,str2> mapty2;
    typedef   std::vector<mapty2>  vty;
    vty  bpf3, bpf1,bpu1;
    int rec_num;
    std::string Status;
    ccl::uint2 pixel;
    template<typename T>
    int getCNT(T& rd,int i) {

        rd.SelectDB(2);
        redisReply* reply = (redisReply*)redisCommand(rd.c, "HGET CNT %d ",i);
        REDIS_ASSERT(reply, "getCNT");
        int n  = std::stoi(reply->str);
        return n;
    }

    template<typename T>
    int getCNT_json(T& bl, int i) {

        auto cnt  = bl.document["CNT"].GetArray();
        return cnt[i].GetInt();

    }

    template<typename T>
    void getHash(T& rd) {
        
        rd.SelectDB(5);


        redisReply* reply = (redisReply*)redisCommand(rd.c, "HGET semaphore12345 xy");
        REDIS_ASSERT(reply, "getHash");
        std::string stst = reply->str;
        std::vector<std::string> val = bl.split(stst, ",");
        pixel.x  = UINT( std::stoi(val[0]));
        pixel.y  = UINT( std::stoi(val[1]));
        freeReplyObject(reply);

        printf("\n\n\n============================  Profile Pixel  %u %u  =============================== \n\n", pixel.x,pixel.y);


        reply = (redisReply*)redisCommand(rd.c, "HGET semaphore12345 status");
        REDIS_ASSERT(reply, "getHashStatus");
        Status  = std::string(reply->str);
        freeReplyObject(reply);

        bpf3_name.clear();
        bpf1_name.clear();
        bpu1_name.clear();
        bpf3.clear();
        bpf1.clear();
        bpu1.clear();



            std::unordered_map<std::string, mapty*> maps = {
                 {"tileInfo::ccl::float3",&bpf3_name},
                 {"tileInfo::float",  &bpf1_name},
                 { "tileInfo::UINT",&bpu1_name}
            };
            for (auto& key : maps) {
                reply = (redisReply*)redisCommand(rd.c, "HGETALL %s", std::string(key.first).c_str());
                for (int i = 0; i < reply->elements; i += 2) {
                    auto  fname = std::string(reply->element[i]->str);
                    auto& bp = *key.second;
                    if (bp.count(fname) == 0) {
                        bp[fname] = 1;
                    }
                    else  bp[fname] = bp[fname] + 1;
                }
                freeReplyObject(reply);
            }

            reply = (redisReply*)redisCommand(rd.c, "HGET semaphore12345 recMax");
            REDIS_ASSERT(reply, "getHash2");
            rec_num  = std::stoi(reply->str);
            bpf3.resize(rec_num);
            bpf1.resize(rec_num);
            bpu1.resize(rec_num);
            std::unordered_map<std::string, vty*> maps2 = {
                     {"tileInfo::ccl::float3", &bpf3},
                     {"tileInfo::float",  &bpf1},
                     { "tileInfo::UINT",&bpu1}
            };
            freeReplyObject(reply);

            for (auto& k : maps) {
                auto& bp  = *maps2[k.first];
                for (auto  val  : (*k.second) ) {
                    reply = (redisReply*)redisCommand(rd.c, "HGETALL %s", std::string(val.first).c_str());
                    auto FUNCNAME = std::string(val.first);
                    for (int i = 0; i < reply->elements; i += 2) {
                        REDIS_ASSERT( (reply->element[i]), "getHash3");
                        auto  No = std::stoi(reply->element[i]->str);   //std::stoi(str);
                        int    vidx = No / STAT_BUF_MAX;
                        assert(vidx < bp.size());
                        auto& bpmap = bp[vidx];
                        auto VALUE = std::string(reply->element[i + 1]->str);
                        bpmap[No] = std::make_pair(FUNCNAME,VALUE);
                    }
                    freeReplyObject(reply);
                }
            }




    }

    template<class T,class T2>
    bool pixel_compare(T* kb,T2* counter ) {



#ifdef DATA_JSON
#define CNT_READER(n) printf("%s    %d <==> BL(%d)  \n",#n,counter[n],getCNT_json(bl,n));
#else
#define CNT_READER(n) printf("%s    %d <==> BL(%d)  \n",#n,counter[n],getCNT(bl,n));
#endif

#include "count_def.h"

        CNT_ALL;
        printf("Pixel Compare  [ %s]  \n ", Status.c_str());
        printf("\nType Float3 Comparing  \n");
        

        int Rec_num = 0;
        for (auto& ma : bpf3) {
            printf("\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  VALUE Inspect  Recursive [%d]  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< \n", Rec_num++);
            for (auto& k : ma) {
                float3 vk = kb->f3[k.first];
                std::string name = k.second.first;
                std::string v       = k.second.second; 
                float3 b = {0.f,0.f,0.f};
                int i = 0;
                for (auto v1 : bl.split(v, ",")) {
                      b[i++] = std::stof(v1);
                }
                printf(">>>>>>>>>>>  %s       [%.6f  %.6f %.6f]      [%.6f  %.6f %.6f]    \n", name.c_str(),vk.x,vk.y,vk.z, b.x,b.y,b.z);
            }
        }
        Rec_num = 0;
        printf("\n\nType Float Comparing  \n");
        for (auto& ma : bpf1) {
            printf("\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  VALUE Inspect  Recursive [%d]  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< \n", Rec_num++);
            for (auto& k : ma) {
                float vk = kb->f1[k.first];
                std::string name = k.second.first;
                std::string v = k.second.second;
                float b = std::stof(v);
                printf(">>>>>>>>>>>  %s       [%.6f]      [%.6f]    \n", name.c_str(), vk, b);
            }
        }

        bool U1_NEQ = false;
        Rec_num = 0;
        printf("\n\nType UINT Comparing  \n");
        for (auto& ma : bpu1) {
            printf("\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  VALUE Inspect  Recursive [%d]  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< \n", Rec_num++);
            for (auto& k : ma) {
                UINT vk = kb->u1[k.first];
                std::string name = k.second.first;
                std::string v = k.second.second;
                UINT  b;
                b = UINT(std::stoll(v));
                printf(">>>>>>>>>>>  %s       [%u]      [%u]    \n", name.c_str(), vk, b);
                if (name == "has_emission_nums") {
                    U1_NEQ = vk != b;
                }
            }
        }

        bool err = false;

        int _rec_num = counter[CNT_HIT_REC];
        if (_rec_num != rec_num) {
            printf("<<<<<<<<<<<<NOT EQUAL>>>>>>>>>   rec_num  %d <=>  BL(%d) \n", _rec_num, rec_num);
            err  = true;
        }

        if (U1_NEQ) {
            printf("<<<<<<<<<<<<UINT NOT EQUAL>>>>>>>>\n");
            err = true;
        }

        

        while (err) {
            char ch = getchar();
            switch (ch)
            {
            case 'q':
                err = false;
                log_bad(" pixel compare quit \n");
                break;
            case 'a':
                printf(" [%c] next loop \n", ch);
                err = false;
                break;
            }
        }
        return err;
    };

};

#endif
#endif