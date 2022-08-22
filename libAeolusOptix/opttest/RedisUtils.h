#pragma once
#include "circusTest.h"


#include "render/geometry.h"
#include "render/mesh.h"
#include "render/object.h"
#include "render/nodes.h"


auto NOprint = []<class T>(const char* name, size_t size, T * ptr) {};
auto printfloat = [](const char* name, size_t size, float* ptr) {
	printf("\n kernel_tex  %s  \n[", name);
	for (int i = 0; i < size; i++) {
		printf("  %.4f  ", ptr[i]);
	}
	printf(" ] \n\n");
};

auto printfloat4 = []<class T>(const char* name, size_t size, T * ptr) {
	printf("\n kernel_tex  %s  \n[", name);
	for (int i = 0; i < size / sizeof(T); i++) {
		printf(" %.5f, %.5f, %.5f, %.5f , ", ptr[i].x, ptr[i].y, ptr[i].z, ptr[i].w);
		if (i % 128 == 0)printf("\n");
	}
	printf(" ] \n\n");
};
auto printint = []<class T>(const char* name, size_t size, T * ptr) {
	printf("\n kernel_tex  %s  \n[", name);
	for (int i = 0; i < size / sizeof(T); i++) {
		printf(" %d, ", ptr[i]);
		if (i % 128 == 0)printf("\n");
	}
	printf(" ] \n\n");
};
auto printuint = []<class T>(const char* name, size_t size, T * ptr) {
	printf("\n kernel_tex  %s  \n[", name);
	for (int i = 0; i < size; i++) {
		printf(" %u, ", ptr[i]);
	}
	printf(" ] \n\n");
};
//#define WITH_REDIS


#ifdef WITH_REDIS
#define STAT_CLIENT
#include <util/util_debug2.h>
//TODO Merge class RedisCli
dump::RedisCli* redis = nullptr;
#include "util/util_texture.h"
#include "kernel/svm/svm_types.h"


class RedisUtils {
private:
	static uint32_t Crc32_ComputeBuf(uint32_t crc32, BYTE* pbuf, int buflen)

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

#define KTDATA_PATH             AEOLUS_DATA_DIR  "\\data\\kerneltex\\"


public:

	Document document;
	bool          isLoad = false;

	void init() {
		isLoad = false;
		load_json("");
		
	}

	uint32_t crc32_of_buffer(BYTE* buf, int buflen)
	{
		return Crc32_ComputeBuf(0xFFFFFFFF, buf, buflen) ^ 0xFFFFFFFF;
	}
	redisContext* c;
	const char* CRLF = "\r\n";
	const char* USED = "used_memory_human:";
	const char* CMD = "total_commands_processed:";



	std::vector<std::string> split(std::string s, std::string delimiter) {
		size_t pos_start = 0, pos_end, delim_len = delimiter.length();
		std::string token;
		std::vector<std::string> res;

		while ((pos_end = s.find(delimiter, pos_start)) != std::string::npos) {
			token = s.substr(pos_start, pos_end - pos_start);
			pos_start = pos_end + delim_len;
			res.push_back(token);
		}

		res.push_back(s.substr(pos_start));
		return res;
	}
	struct BlednerInfo {
		HANDLE  signal12345;
		HANDLE  signal54321, signalinner, signalinner2;
		bool abort,br12345;
	}binfo = { NULL ,NULL,NULL,NULL,false,false};
	struct BlnetInfo {
		LONG TID;
		bool needsUpdate;
	}bnet;


	template<typename T>
	struct  _device_memory {
		typedef T  dataty;
		typedef T* dataptr;
		size_t memory_size()
		{
			return data_size * data_elements * datatype_size(data_type);
		}
		size_t memory_elements_size(int elements)
		{
			return elements * data_elements * datatype_size(data_type);
		}
		int                      pad[2];
		/* Data information. */
		ccl::DataType data_type;
		int data_elements;
		size_t data_size;
		size_t device_size;
		size_t data_width;
		size_t data_height;
		size_t data_depth;
		ccl::MemoryType type;
		const char* name;

		/* Pointers. */
		ccl::Device* device;
		//ccl::device_ptr device_pointer;
		dataptr device_pointer;
		dataptr host_pointer;
		void* shared_pointer;
		/* reference counter for shared_pointer */
		int shared_counter;

		~_device_memory() {

		};

		///void swap_device(Device* new_device, size_t new_device_size, device_ptr new_device_ptr);
		void restore_device() {};

		///bool is_resident(Device* sub_device) const;


		//friend class CUDADevice;
		///friend class OptiXDevice;

		/* Only create through subclasses. */
		////device_memory(Device* device, const char* name, MemoryType type);

		/* No copying allowed. */
		_device_memory() :host_pointer(nullptr) , device_pointer(0){
			///printf("device_memory  construct  \n");
		};
		_device_memory(const _device_memory&) :host_pointer(nullptr), device_pointer(0) {};
		_device_memory& operator=(const _device_memory&){};
		dataptr host_alloc(size_t size) {
			host_pointer = (dataptr)malloc(size);
			printf("malloc  host_pointer   %zu  \n", size);
			return host_pointer;
		};

		void host_free() {
			/*
			if (host_pointer != nullptr) {
				free(host_pointer);
				host_pointer = nullptr;
			}
			*/
		};

		/* Device memory allocation and copying. */
		void device_alloc() {};
		void device_free() {};
		void device_copy_to() {};
		void device_copy_from(int y, int w, int h, int elem) {};
		void device_zero() {};

		ccl::device_ptr original_device_ptr;
		size_t original_device_size;
		ccl::Device* original_device;
	};

	template<typename T> class _device_vector : public _device_memory<T> {
	public:
		using mem = _device_memory<T>;
		_device_vector(ccl::Device* device = nullptr, const char* name = "", ccl::MemoryType type = (ccl::MemoryType)0)
			///: _device_memory(device, name, type)
		{
			mem::data_type = ccl::device_type_traits<T>::data_type;
			mem::data_elements = ccl::device_type_traits<T>::num_elements;
			mem::device_pointer = 0;
			assert(mem::data_elements > 0);
		}

		~_device_vector()
		{
			free();
		}

		size_t struct_size() {
			return sizeof(T);
		}
		/* Host memory allocation. */
		T* alloc(size_t width, size_t height = 0, size_t depth = 0)
		{
			size_t new_size = size(width, height, depth);

			if (new_size != mem::data_size) {
				mem::device_free();
				mem::host_free();
				mem::host_pointer = mem::host_alloc(sizeof(T) * new_size);
				assert(mem::device_pointer == 0);
			}

			mem::data_size = new_size;
			mem::data_width = width;
			mem::data_height = height;
			mem::data_depth = depth;

			return data();
		}

		/* Host memory resize. Only use this if the original data needs to be
		 * preserved, it is faster to call alloc() if it can be discarded. */
		T* resize(size_t width, size_t height = 0, size_t depth = 0)
		{
			size_t new_size = size(width, height, depth);

			if (new_size != data_size) {
				void* new_ptr = host_alloc(sizeof(T) * new_size);

				if (new_size && data_size) {
					size_t min_size = ((new_size < data_size) ? new_size : data_size);
					memcpy((T*)new_ptr, (T*)host_pointer, sizeof(T) * min_size);
				}

				device_free();
				host_free();
				host_pointer = new_ptr;
				assert(device_pointer == 0);
			}

			data_size = new_size;
			data_width = width;
			data_height = height;
			data_depth = depth;

			return data();
		}

		/* Take over data from an existing array. */
		void steal_data(ccl::array<T>& from)
		{
			device_free();
			host_free();

			data_size = from.size();
			data_width = 0;
			data_height = 0;
			data_depth = 0;
			host_pointer = from.steal_pointer();
			assert(device_pointer == 0);
		}

		/* Free device and host memory. */
		void free()
		{
			mem::device_free();
			mem::host_free();

			mem::data_size = 0;
			mem::data_width = 0;
			mem::data_height = 0;
			mem::data_depth = 0;
			mem::host_pointer = 0;
			//assert(mem::device_pointer == 0);
		}

		size_t size()
		{
			return mem::data_size;
		}

		T* data()
		{
			return (T*)mem::host_pointer;
		}

		T& operator[](size_t i)
		{
			assert(i < mem::data_size);
			return data()[i];
		}

		void copy_to_device()
		{
			mem::device_copy_to();
		}

		void copy_from_device()
		{
			mem::device_copy_from(0, mem::data_width, mem::data_height, sizeof(T));
		}

		void copy_from_device(int y, int w, int h)
		{
			mem::device_copy_from(y, w, h, sizeof(T));
		}

		void zero_to_device()
		{
			mem::device_zero();
		}

		bool null;

	protected:
		
		size_t size(size_t width, size_t height, size_t depth)
		{
			return width * ((height == 0) ? 1 : height) * ((depth == 0) ? 1 : depth);
		}
	};

#  define KERNEL_TEX(type, tname)  _device_vector<type>  tname;
	struct TexMemory {
#include "kernel/kernel_textures_ccl.h"
	}tex;

#undef KERNEL_TEX

	std::vector<ccl::float4> prim_verts2;
	std::vector<ccl::uint3>   tri_vindex2;
	std::vector<VkDescriptorBufferInfo>   infoV;
	std::vector<VkDescriptorBufferInfo>   infoI;
	std::vector<uint32_t> idxOffset;
	std::vector<uint32_t> vertOffset;
	std::unordered_map<uint64_t, std::pair<int,bool>>   geomHash;
	ccl::KernelData kd;

	void read_mesh_json(std::vector<ccl::Mesh*>& meshs) {

		using namespace macaron;
		std::ifstream ifs(KTDATA_PATH "data.json");
		IStreamWrapper isw(ifs);

		Document document;
		document.ParseStream(isw);
		assert(document.HasMember("Mesh"));
		assert(document["Mesh"].IsObject());

		auto mesh = document["Mesh"].GetObjectA();
		assert(mesh.HasMember("size"));
		assert(mesh.HasMember("body"));
		assert(mesh.HasMember("array"));
		int size = mesh["size"].GetInt();


		meshs.resize((size_t)size);

	
#define DECODE_ARRAY(aname){\
			redisReply*  reply = (redisReply*)redisCommand(c, "HGET %s  size:%s", hkey.c_str(), #aname);\
			size_t size = (size_t)std::stoll(reply->str);\
			printf(" HKEY  %s  struct  %s  size %zu    \n ", hkey, #aname,size);\
			freeReplyObject(reply);\
			if (size > 0) {\
                memset(&(me->aname), 0, sizeof(me->aname));\
				me->aname.resize(size);	\
				reply = (redisReply*)redisCommand(c, "HGET %s  data:%s", hkey.c_str(), #aname);\
				std::string rstr = reply->str;\
				std::string rStr;\
				b64.Decode(rstr, rStr);\
				BYTE* ptr2 = (BYTE*)rStr.data();\
				memcpy((BYTE*)me->aname.data(), ptr2, size);\
				freeReplyObject(reply);\
				printf(" HKEY  %s  struct  %s   memcpy to dst   \n ", hkey.c_str(), #aname);\
				checkCRC(hkey.c_str(), "crc:" #aname, (BYTE*)me->aname.data(), size);\
             }};

		auto body = mesh["body"].GetArray();
		auto ary = mesh["array"].GetArray();
		assert(body.Size() == ary.Size());

		for (int i = 0; i < meshs.size(); i++) {

			ccl::Mesh* me = new ccl::Mesh();
			std::string bodyStr = body[i].GetString();

			decodeJson(me, bodyStr);
			meshs[i] = me;

		}


	};
	template<typename  T>
	void clean_json(T& name) {

		Document sub;
		auto ary = document["CNT"].GetArray();
		document.RemoveAllMembers();
		document.AddMember("CNT", ary, document.GetAllocator());



	};
	template<typename  T>
	void load_json(T& name) {

		std::ifstream ifs(KTDATA_PATH "cube_diffuse.json");
		IStreamWrapper isw(ifs);


		document.ParseStream(isw);
		assert(document.HasMember("Mesh"));
		assert(document["Mesh"].IsObject());
		assert(document.HasMember("Obj"));
		assert(document["Obj"].IsObject());
		assert(document.HasMember("SVM"));
		assert(document["SVM"].IsObject());
		assert(document.HasMember("KT"));
		assert(document["KT"].IsObject());
		assert(document.HasMember("KG"));
		assert(document["KG"].IsObject());

		isLoad = true;



	};
	template<class B>
	void remake_vertex_json(B& bvh) {

		geomHash.clear();
		prim_verts2.clear();
		tri_vindex2.clear();
		bvh.primOffset.clear();
		idxOffset.clear();
		vertOffset.clear();

		infoV.clear();
		infoI.clear();

		auto mesh = document["Mesh"].GetObjectA();
		assert(mesh.HasMember("size"));
		assert(mesh.HasMember("body"));
		assert(mesh.HasMember("array"));
		int size = mesh["size"].GetInt();
		auto body = mesh["body"].GetArray();
		auto ary = mesh["array"].GetArray();
		assert(body.Size() == ary.Size());
		assert(size == body.Size());



		using namespace macaron;
#define FIELD(name) #name,name.data(),name.size()
#define struct_enc(ptr, str,name,size) auto name  = b64.Encode((BYTE*)ptr,sizeof(str)*size );


		Base64  b64;
#define DECODE_ARRAY(aname){\
			redisReply*  reply = (redisReply*)redisCommand(c, "HGET %s  size:%s", hkey.c_str(), #aname);\
			size_t size = (size_t)std::stoll(reply->str);\
			printf(" HKEY  %s  struct  %s  size %zu    \n ", hkey, #aname,size);\
			freeReplyObject(reply);\
			if (size > 0) {\
                memset(&(me->aname), 0, sizeof(me->aname));\
				me->aname.resize(size);	\
				reply = (redisReply*)redisCommand(c, "HGET %s  data:%s", hkey.c_str(), #aname);\
				std::string rstr = reply->str;\
				std::string rStr;\
				b64.Decode(rstr, rStr);\
				BYTE* ptr2 = (BYTE*)rStr.data();\
				memcpy((BYTE*)me->aname.data(), ptr2, size);\
				freeReplyObject(reply);\
				printf(" HKEY  %s  struct  %s   memcpy to dst   \n ", hkey.c_str(), #aname);\
				checkCRC(hkey.c_str(), "crc:" #aname, (BYTE*)me->aname.data(), size);\
             }};



		struct jsonD {
			size_t size = 0;
			size_t crc = 0;
			std::string data = "";
		};
#define GetJsonSize(name,J) {\
			 assert(mem.HasMember(name) && "NotFound mesh array");\
			auto   data = mem[name].GetObjectA();\
			J.size =	data["size"].GetInt();}

#define GetJsonData(name,J) {\
			 assert(mem.HasMember(name) && "NotFound mesh array");\
			auto   data = mem[name].GetObjectA();\
			J.data  =	data["data"].GetString();}



		size_t size_idx = 0;
		size_t size_vert = 0;
		int       prim_ofs = 0;

		int gid = 0;
		std::vector<int>   arid;
		jsonD tri, ver;
		for (int i = 0; i < size; i++) {
			auto  mem = ary[i].GetObjectA();

			GetJsonSize("triangles", tri);
			GetJsonSize("verts", ver);


			assert(tri.size > 0);
			VkDescriptorBufferInfo info;
			info.offset = size_idx;
			info.range = tri.size;
			infoI.push_back(info);
			idxOffset.push_back(int(size_idx / 4 / 3));
			size_idx += tri.size;



			assert(ver.size > 0);
			info.offset = size_vert;
			info.range = ver.size;
			infoV.push_back(info);
			vertOffset.push_back(int(size_vert / 4 / 4));
			size_vert += ver.size;



			assert(mem.HasMember("hashID") && "NotFound mesh array" );
			auto   hashID = (uint64_t)mem["hashID"].GetInt64();
			assert(geomHash.count(hashID) == 0);

			assert(mem.HasMember("isInstanced") &&  "NotFound mesh array");
			auto   isInstanced = (bool)mem["isInstanced"].GetInt64();

			geomHash[hashID] = std::make_pair(gid++, isInstanced);
			arid.push_back(i);


		}

		bvh.primOffset.resize(infoV.size());
		prim_verts2.resize(size_vert / 4 / 4);
		tri_vindex2.resize(size_idx / 4 / 3);
		/// get Data
		/// 
		for (auto hash : geomHash) {
			auto i = std::get<0>(hash.second);

			auto  mem = ary[i].GetObjectA();
			GetJsonData("triangles", tri);
			GetJsonData("verts", ver);

			{
				std::string rstr = tri.data;
				std::string rStr;
				b64.Decode(rstr, rStr);
				BYTE* ptr2 = (BYTE*)rStr.data();
				memcpy((BYTE*)(tri_vindex2.data() + infoI[i].offset / 4 / 3), ptr2, infoI[i].range);
			}
			{
				std::string rstr = ver.data;
				std::string rStr;
				b64.Decode(rstr, rStr);
				BYTE* ptr2 = (BYTE*)rStr.data();
				memcpy((BYTE*)(prim_verts2.data() + infoV[i].offset / 4 / 4), ptr2, infoV[i].range);
			}
			i++;
		};





	}
	template<class Bla>
	void setUpInstances_json(std::vector<VkAccelerationStructureInstanceNV>& insta, std::vector<Bla>& blas) {
		/*
		typedef struct VkAccelerationStructureInstanceKHR {
			VkTransformMatrixKHR          transform;
			uint32_t                      instanceCustomIndex : 24;
			uint32_t                      mask : 8;
			uint32_t                      instanceShaderBindingTableRecordOffset : 24;
			VkGeometryInstanceFlagsKHR    flags : 8;
			uint64_t                      accelerationStructureReference;
		} VkAccelerationStructureInstanceKHR;
		*/

		using namespace macaron;

		Base64  b64;
		auto Obj = bl.document["Obj"].GetObjectA();
		auto body = Obj["body"].GetArray();
		auto names = Obj["asset_name:char"].GetArray();

		insta.resize((size_t)Obj["size"].GetInt());
		printf(">>>>>>>>>>>>>>>>>>>>>>InstanceSize   %zu  \n", (UINT64)insta.size());

		ccl::Object obj;
		std::string rStr;
		std::string rstr;

		std::string hkey;
		BYTE* ptr2 = nullptr;
		/// Retrieve instances
		for (int i = 0; i < insta.size(); i++) {
			rstr = body[i].GetString();
			b64.Decode(rstr, rStr);
			ptr2 = (BYTE*)rStr.data();
			memcpy((BYTE*)&obj, ptr2, rStr.size());

			printf(">>>>>>>>>>>>>>>>>>>>>>Get  instance of %s  \n", names[i].GetString());

			auto hashID = (uint64_t)obj.geometry;
			if (!obj.is_traceable())continue;
			if (geomHash.count(hashID) <= 0)continue;
			/* [vulkan auto generate] TODO  manually set
			OptixAabb& aabb = aabbs[num_instances];
			aabb.minX = ob->bounds.min.x;
			aabb.minY = ob->bounds.min.y;
			aabb.minZ = ob->bounds.min.z;
			aabb.maxX = ob->bounds.max.x;
			aabb.maxY = ob->bounds.max.y;
			aabb.maxZ = ob->bounds.max.z;
			*/

			int gid = std::get<0>(geomHash[hashID]);

			auto& gInst = insta[i];
			// Clear transform to identity matrix
			gInst.transform.matrix[0][0] = 1.0f;
			gInst.transform.matrix[1][1] = 1.0f;
			gInst.transform.matrix[2][2] = 1.0f;

			// Set user instance custom ID   =>   array index  of vertexOfs ,indexOfs  == geometry Index
			//instance.instanceId = ob->get_device_index();
			gInst.instanceCustomIndex = gid;

			/// TODO Hair Volume MotionBlur

			gInst.accelerationStructureReference = blas[gid].accel.handle;
			gInst.flags = static_cast<uint32_t>(VK_GEOMETRY_INSTANCE_TRIANGLE_CULL_DISABLE_BIT_NV);
			gInst.mask = 0xFF;
			gInst.instanceShaderBindingTableRecordOffset = 0;

			if (std::get<1>(geomHash[hashID])) {
				// Set transform matrix
				memcpy((void*)&gInst.transform.matrix[0][0], &obj.tfm, sizeof(gInst.transform));
			}
			else {
				/*
				Disable instance transform if geometry already has it applied to vertex data
				instance.flags = OPTIX_INSTANCE_FLAG_DISABLE_TRANSFORM;
				// Non-instanced objects read ID from prim_object, so
				// distinguish them from instanced objects with high bit set
				*/
				gInst.instanceCustomIndex |= 0x800000;
			}
		}

	}
	template<class MemTy>
	void upload_KD_json(MemTy& memVk) {
		void* dst = memVk.bamp["kerneldata"].alloc->GetMappedData();
		const size_t kd_size = sizeof(ccl::KernelData);

		using namespace macaron;
	
		auto kg = bl.document["KG"].GetObjectA();
		assert(kg.HasMember("params"));
		auto params = kg["params"].GetObjectA();

		assert(params.HasMember("__KernelData"));
		std::string Jstr = params["__KernelData"].GetString();
		decodeJson(&kd, Jstr);
		memcpy((BYTE*)dst, (void*)&kd, kd_size);
	}


	template<class T>
	void decodeJson(T* strc, std::string& Jstr,size_t size = 1) {
		using namespace macaron;
		Base64  b64;
		std::string rStr;
		std::string rstr = Jstr;
		b64.Decode(rstr, rStr);
		BYTE* ptr2 = (BYTE*)rStr.data();
		printf(" decodeJson   memcpy to dst   \n ");
		memcpy((BYTE*)strc, ptr2, sizeof(T) * size);
	}
	void decodeJson2(void* strc, std::string& Jstr, size_t size) {
		using namespace macaron;
		Base64  b64;
		std::string rStr;
		std::string rstr = Jstr;
		b64.Decode(rstr, rStr);
		BYTE* ptr2 = (BYTE*)rStr.data();
		printf(" decodeJson   memcpy to dst   \n ");
		memcpy((BYTE*)strc, ptr2,  size);

	}
	bool  indexBuffer(void* strc, const char* hkey, const char* name, size_t size) {

		std::vector<UINT> u(size / 4);
		for (int i = 0; i < size / 4; i++)u[i] = i;
		memcpy((BYTE*)strc, u.data(), size);
		return true;
	}
	bool  checkCRC(const char* hkey, const char* name, BYTE* ptr, size_t size) {
		using namespace macaron;
	
		/*	Base64  b64;
		redisReply* reply = nullptr;
		if (HExists(hkey, name)) {

			reply = (redisReply*)redisCommand(c, "HGET %s  %s", hkey, name);
			UINT hash  = static_cast<unsigned int>(std::stoul(std::string(reply->str)));
			UINT crc    = crc32_of_buffer(ptr, size);
			printf(" CheckSum(%s   %s)  ==  %s   \n ", hkey, name,(hash==crc)?"TRUE":"FALSE");
			assert(hash == crc);
			freeReplyObject(reply);
			return true;
		}
		else  printf(" not exists   HKEY   %s   %s  ", hkey, name);
		*/
		return false;
	}


};


#endif

