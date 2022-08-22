#include "pch_three.h"
#include "Loader.h"
#include "core/common.hpp"
#include <memory>
#include <execution>

#define Log_NO_GLTF
#ifdef   Log_NO_GLTF
#define Log_gltf(...)
#else
#define Log_gltf(...) Log_out(__FILE__, __LINE__, Log_TRACE, __VA_ARGS__)
#endif



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

int existINPUT(std::vector<arth::INPUT>& v, arth::INPUT input) {
	for (int i = 0; i < v.size(); i++) {
		if (v[i] == input)return i;
	};
	return -1;
}


	GLTF_Loader::GLTF_Loader(CarryAttribute* carry):carry(carry) {};
	GLTF_Loader::~GLTF_Loader() {
		Log_gltf(" deallocate  \n");
	};
	void  GLTF_Loader::_decode(std::vector<uint8_t>& ret, std::string::iterator beg, std::string::iterator  end)
	{

		const size_t N = (end - beg);
		ret.clear();
		ret.reserve(3 * N / 4);

		for (size_t i = 0; i < N; i += 4)
		{
			const uint8_t b4_0 = (*beg <= 'z') ? from_base64[static_cast<uint8_t>(*beg)] : 0xff;	beg++;
			const uint8_t b4_1 = ((i + 1 < N) && (*beg) <= 'z') ? from_base64[static_cast<uint8_t>(*beg)] : 0xff; beg++;
			const uint8_t b4_2 = ((i + 2 < N) && (*beg) <= 'z') ? from_base64[static_cast<uint8_t>(*beg)] : 0xff; beg++;
			const uint8_t b4_3 = ((i + 3 < N) && (*beg) <= 'z') ? from_base64[static_cast<uint8_t>(*beg)] : 0xff;	beg++;

			const uint8_t b3_0 = ((b4_0 & 0x3f) << 2) + ((b4_1 & 0x30) >> 4);
			const uint8_t b3_1 = ((b4_1 & 0x0f) << 4) + ((b4_2 & 0x3c) >> 2);
			const uint8_t b3_2 = ((b4_2 & 0x03) << 6) + ((b4_3 & 0x3f) >> 0);

			// Add the byte to the return value if it isn't part of an '=' character (indicated by 0xff)
			if (b4_1 != 0xff) ret.push_back(static_cast<uint8_t>(b3_0));
			if (b4_2 != 0xff) ret.push_back(static_cast<uint8_t>(b3_1));
			if (b4_3 != 0xff) ret.push_back(static_cast<uint8_t>(b3_2));
		}

        Log_gltf("Level0   :Level1 : Level2 :Level 3   %zu  \n",N);
		/*
		std::cout << "   decode     " << "   ";
		for (auto& v : ret) {
			std::cout << v << "  ";
		};
		std::cout << std::endl;
		*/

	};
	void  GLTF_Loader::parallel_base64(std::string::iterator beg, std::string::iterator  end)
	{
		/*
		auto len = (end - beg) / 4;
		if (len < 1000)
			return _decode(beg, end);
		std::string::iterator mid = beg + 4 * floor(len / 2);
		auto handle = std::async(std::launch::async, parallel_base64, mid, end);
		parallel_base64(beg, mid);
		*/
		return;
	};
	void  GLTF_Loader::debug_print(_BufferView& bv) {

		if (bv.GLtype == GLTYPE_FLOAT) {
			std::vector<_VEC3> v;
			v.resize(bv.arraysize);
			memcpy(v.data(), bv.data.data(), bv.arraysize * sizeof(_VEC3));
			for (int i = 0; i < 3; i++) {
				printf(" %d   %.5f  %.5f  %.5f     \n", i, v[i].v[0], v[i].v[1], v[i].v[2]);
			};
			for (int i = 0; i < 3; i++) {
				int idx = bv.arraysize - 1 - i;
				printf(" %d   %.5f  %.5f  %.5f     \n", idx, v[idx].v[0], v[idx].v[1], v[idx].v[2]);
			};
		}
		else if (bv.GLtype == GLTYPE_UINT16) {
			std::vector<uint16_t> v;
			v.resize(bv.arraysize);
			memcpy(v.data(), bv.data.data(), bv.arraysize * sizeof(_IND1));
			for (int i = 0; i < 15; i++) {
				printf(" %d   %u    \n", i, v[i]);
			};
			for (int i = 0; i < 15; i++) {
				int idx = bv.arraysize - 1 - i;
				printf(" %d   %u    \n", idx, v[idx]);
			};
		}

	};
	int    GLTF_Loader::toDigit(char c) {
		if (c >= '0' && c <= '9')return c - '0';
		return -1;
	};
	void  GLTF_Loader::parseScenes(json_value* tmp) {

		if (tmp->type == json_array) {
			tmp = ARRAY(tmp, 0);
			if (tmp->type == json_object) {
				if (std::string(OBJ(tmp, 1).name) == "nodes") {
					tmp = OBJ(tmp, 1).value;
					if (tmp->type == json_array) {
						NODE = ARRAY_LEN(tmp);
						access.resize(NODE);
						for (int i2 = 0; i2 < NODE; i2++) {
							access[i2].bufferView.resize(ViewSize);
							Log_gltf("Level0     :  Level 1  create view    %zu  \n", access[i2].bufferView.size());
						}
						for (int i2 = 0; i2 < NODE; i2++) {
							access[i2].next = (long)(ARRAY(tmp, i2)->u.integer);
						}
						Log_gltf("Level0     :  Level 1  NODE  %d  \n", NODE);
					}
				};
			}
		}
		else {
			PyErr_BadInternalCall();
		}

	}
	void  GLTF_Loader::parseNodes(json_value* obj, _Accessor& acs) {
		Log_gltf("Level0     : Level 1   Node %d\n", acs.next);
		///int next = acs.next;
		acs.next = -1;
		if (obj->type == json_object) {
			for (int i3 = 0; i3 < int(OBJ_LEN(obj)); i3++) {
				std::string  elem = std::string(OBJ(obj, i3).name);
				if (elem == "mesh") {
					acs.next = long(OBJ(obj, i3).value->u.integer);
				}
				else if (elem == "name") {
					std::string  _targetName = std::string(OBJ(obj, i3).value->u.string.ptr);
					Log_gltf("Level0     : Level 1     :Level 2   nodeView  %d =>  TargetName %s    \n", next, _targetName.c_str());
					parseTarget(_targetName, acs);
				}
				else if (elem == "rotation") {

				}
				else if (elem == "scale") {

				}
				else if (elem == "position") {

				}
			}
		}
	};
	void  GLTF_Loader::parseTarget(std::string name, _Accessor& acs) {

		if (target == arth::LOADER_TARGET::MESH_LOD) {

			if ("LOD" == name.substr(0, 3)) {
				acs.lod = toDigit(*(name.substr(4, 1).c_str()));
				Log_gltf("Level0     : Level 1     :Level 2   LODObjects  %s    view %d    ==> LOD %d    \n", name.c_str(), acs.next, acs.lod);
				
			}
			else {
				acs.next = -1;
			}
		}
		else if (target == arth::LOADER_TARGET::MESH_1) {
			if (targetName == name ) {
				acs.lod = 0;
				Log_gltf("Level0     : Level 1     :Level2  Target Mesh_1  %s    view %d    ==> LOD %d    \n", name.c_str(), acs.next, acs.lod);
			}
			else {
				acs.next = -1;
			}
		}
		else {
			THROW_GLTF_NIL
		}
	};
	void  GLTF_Loader::parseAttr(_json_object_entry* obj, _Accessor& acs) {

		int found = -1;
		arth::INPUT input = arth::INPUT::ALL;
		std::string attr = std::string(obj->name);


		if (attr == "POSITION") input = arth::INPUT::vertex_V3_POSITION;
		else if (attr == "NORMAL") input = arth::INPUT::vertex_V3_NORMAL;
		else if (attr == "TEXCOORD_0") input = arth::INPUT::vertex_V2_UV;

		found = existINPUT(carry->buffer->array._struct, input);

		Log_gltf("Level0     : Level 1  : Level 2  attributes   type   %d     %zu  \n", found, acs.bufferView.size());

		if (found >= 0) {
			_BufferView& bv = acs.bufferView[found];
			bv.input = input;
			bv.next = long(obj->value->u.integer);
			Log_gltf("Level0     : Level 1  : Level 2 found attributes   type   %s[%u] \n", attr.c_str(),(UINT32)input);
		}

	};
	void  GLTF_Loader::parseMeshes(json_value* obj, _Accessor& acs) {
		if (obj->type == json_object) {
			if (std::string(OBJ(obj, 1).name) == "primitives") {
				json_value* ary = OBJ(obj, 1).value;
				if (ary->type == json_array) {
					json_value* obj2 = ARRAY(ary, 0);
					if (obj2->type == json_object) {
						if (std::string(OBJ(obj2, 0).name) == "attributes") {
							json_value* attr = OBJ(obj2, 0).value;
							Log_gltf("Level0     : Level 1  attributes   Nums  %d  \n", int(OBJ_LEN(attr)));
							for (int i3 = 0; i3 < int(OBJ_LEN(attr)); i3++) parseAttr(&OBJ(attr, i3) ,acs);
						}
						else { THROW_ParseERROR }
						if (std::string(OBJ(obj2, 1).name) == "indices") {
							_BufferView bv;
							bv.input = arth::INPUT::vertex_INDEX;
							bv.next = long(OBJ(obj2, 1).value->u.integer);
							Log_gltf("Level0     : Level 1  Index  next  %d  \n", bv.next);
							acs.bufferView.push_back(bv);
						}
						else { THROW_ParseERROR }
					}
					else { THROW_ParseERROR }
				}
				else { THROW_ParseERROR }
			};
		}
	};
	uint32_t  GLTF_Loader::parseType(std::string attr) {
		if (attr == "VEC3") {
			return 3;
		}
		else if (attr == "SCALAR") {
			return 1;
		}
		else if (attr == "VEC2") {
			return 2;
		};
		return uint32_t(-1);
	};
	uint32_t  GLTF_Loader::getItemSize(_BufferView& bv) {
		if (bv.GLtype == GLTYPE_FLOAT) {
			return bv.fieldSize*4;
		}
		else if (bv.GLtype == GLTYPE_UINT16) {
			return bv.fieldSize * 2;
		}
		return uint32_t(-1);
	};
	void  GLTF_Loader::parseSphere(json_value* min, json_value* max) {
		if (min != nullptr && max != nullptr) {
			double mn, mx, p[3], d[3];
			

			for (int i2 = 0; i2 < 3; i2++) {
				mn = ARRAY(min ,i2)->u.dbl;
				mx = ARRAY(max,i2)->u.dbl;
				if (isnan(mn)) mn = (double)(ARRAY(min, i2)->u.integer);
				if (isnan(mx)) mx = (double)(ARRAY(max, i2)->u.integer);

				p[i2] = (mx + mn) / 2.;
				d[i2] = abs(mx - mn);
				d[i2] *= d[i2];
			};
			carry->boundingSphere->_center->set(p[0], p[1], p[2]);
			carry->boundingSphere->_radius = sqrt(d[0] + d[1] + d[2]) / 2.;

		}
		else THROW_ParseERROR

	};
	void  GLTF_Loader::parseAccessors(json_value* obj, _BufferView& bv, bool bounding) {
		Log_gltf("Level0     : Level 1  Accessors    \n");
		json_value* min, * max;
		min = nullptr;  max = nullptr;
		for (int i3 = 0; i3 < int(OBJ_LEN(obj)); i3++) {
			std::string  elem = std::string(OBJ(obj, i3).name);
			if (elem == "bufferView") {
				bv.next = long(OBJ(obj, i3).value->u.integer);
			}
			else if (elem == "componentType") {
				bv.GLtype = long(OBJ(obj, i3).value->u.integer);
			}
			else if (elem == "count") {
				bv.arraysize = uint32_t(OBJ(obj, i3).value->u.integer);
			}
			else if (elem == "type") {
				bv.fieldSize = parseType(OBJ(obj, i3).value->u.string.ptr);
			}
			if (bounding) {
				if (elem == "max") {

					max = OBJ(obj, i3).value;
				}
				else if (elem == "min") {

					min = OBJ(obj, i3).value;
				}
			}

		}
		if (bounding) {
			parseSphere(min, max);
		}
	};
	void  GLTF_Loader::parsebufferViews(json_value* obj, _BufferView& bv) {
		
		bv.bytesize = uint32_t(OBJ(obj, 1).value->u.integer);
		bv.offset = uint32_t(OBJ(obj, 2).value->u.integer);
		bv.data.resize(bv.arraysize * getItemSize(bv));

	};
	void  GLTF_Loader::_mapBuffers(json_value* obj) {

		Log_gltf("Level0     :Level1 :Buffers \n");
		///size_t         size = (size_t)(OBJ(obj, 0).value->u.integer);
		std::string  URI = std::string(OBJ(obj, 1).value->u.string.ptr);
		std::smatch dataUriRegexResult;
		if (std::regex_match(URI, dataUriRegexResult, expr::dataUriRegex)) {
			if (dataUriRegexResult.size() == 4) {

				std::ssub_match base_sub_match = dataUriRegexResult[1];
				std::string  mimeType = base_sub_match.str();

				base_sub_match = dataUriRegexResult[2];
				std::string   isBase64 = base_sub_match.str();

				base_sub_match = dataUriRegexResult[3];
				std::string  base64 = base_sub_match.str();


				Log_gltf("parse base64   Size     %zu \n", base64.size());
				{

					const auto BEGIN = base64.begin();
					std::chrono::time_point<std::chrono::steady_clock>  start = std::chrono::high_resolution_clock::now();

					std::for_each(PRll_POLICY, access.begin(), access.end(), [&](auto& elem) {
						if (elem.next >= 0) {
							std::for_each(PRll_POLICY, elem.bufferView.begin(), elem.bufferView.end(), [&](auto& bv) {
								auto iter = BEGIN + bv.offset;
								_decode(bv.data, iter, iter + bv.bytesize);
								});
						}
				    });

					std::chrono::time_point<std::chrono::steady_clock>  now = std::chrono::high_resolution_clock::now();
					Log_gltf(" execution::par_unseq     time    %.5f    ms \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()));
				}
				{
					std::chrono::time_point<std::chrono::steady_clock>  start = std::chrono::high_resolution_clock::now();

					for (int i = 0; i < access.size(); i++) {
						std::vector<_BufferView>& bv = access[i].bufferView;
						for (int j = 0; j < bv.size(); j++) {
							if (bv[j].next >= 0) {
								auto iter = base64.begin() + bv[j].offset;
								_decode(bv[j].data, iter, iter + bv[j].bytesize);
							};
						};
					};

					std::chrono::time_point<std::chrono::steady_clock>  now = std::chrono::high_resolution_clock::now();
					Log_gltf(" execution::seq     time    %.5f    ms \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()));
				}



				_BufferView bv = access[0].bufferView[0];

				static_assert(std::atomic<int>::is_always_lock_free);
				std::atomic<int> index{ 0 };
				int  SIZE_TASK = 100000;
				int  SIZE_SRC = SIZE_TASK * 10;

				std::vector<char> src(SIZE_SRC, 1);
				///std::for_each(PRll_POLICY_unseq, src.begin(), src.end(), [&](auto& v) {  v = 1; });

				{
					int   worker = SIZE_SRC / SIZE_TASK + 1;
					std::vector<int> r(worker, SIZE_TASK);

					Log_gltf("dispatch  Worker  %d  TASK %d \n", worker, SIZE_TASK);
					char* dst = new char[SIZE_SRC * 2];
					memset(dst, 0, SIZE_SRC * 2);

					std::chrono::time_point<std::chrono::steady_clock>  start = std::chrono::high_resolution_clock::now();
					int offset = 0;
					for (int i = 0; i < SIZE_SRC; i++) {
						memcpy(dst + offset * 2, src.data() + offset, 1);
						offset++;
					};

					///Log_gltf(" task fin\n");

					std::chrono::time_point<std::chrono::steady_clock>  now = std::chrono::high_resolution_clock::now();
					Log_gltf(" execution::seq     time    %.5f    ms \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()));

					int sum = 0;
					for (int i = 0; i < SIZE_SRC * 2; i++) {
						sum += (int)dst[i];
					}
					Log_gltf(" execution::seq    Sum   %d   \n ", sum);
					delete dst;

				}


				{


					char* dst = new char[SIZE_SRC * 2];
					memset(dst, 0, SIZE_SRC * 2);


					int worker = SIZE_SRC / SIZE_TASK;
					std::vector<int> r(worker, 0);

					auto BEGIN = &r[0];
					Log_gltf("dispatch  Worker  %d  TASK %d \n", worker, SIZE_TASK);
					char* SRC = src.data();
					char* DST = dst;

					std::chrono::time_point<std::chrono::steady_clock>  start = std::chrono::high_resolution_clock::now();


					std::for_each(PRll_POLICY, r.begin(), r.end(), [&](auto& value) {
						size_t offset = (&value - BEGIN) * SIZE_TASK;
						for (int i = 0; i < SIZE_TASK; i++) {
							*(DST + 2 * (offset + i)) = *(SRC + (offset + i));
						}
						});


					std::chrono::time_point<std::chrono::steady_clock>  now = std::chrono::high_resolution_clock::now();
					Log_gltf(" execution::par     time    %.5f    ms \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()));

					int sum = 0;
					for (int i = 0; i < SIZE_SRC * 2; i++) {
						sum += (int)dst[i];
					}
					Log_gltf(" execution::par   Sum   %d   \n ", sum);
					delete dst;

				}
				/*

				*/
			}
		}

	}
	void  GLTF_Loader::mapBuffers(json_value* obj) {

		Log_gltf("Level0     :Level1 :Buffers \n");
		///size_t         size = (size_t)(OBJ(obj, 0).value->u.integer);

		std::string  URI = std::string(OBJ(obj, 1).value->u.string.ptr);

		std::string uri = URI.substr(0,40);

		std::smatch dataUriRegexResult;
		if (std::regex_match(uri, dataUriRegexResult, expr::dataUriRegex)) {
			if (dataUriRegexResult.size() == 4) {

				std::ssub_match base_sub_match = dataUriRegexResult[1];
				std::string  mimeType = base_sub_match.str();



				base_sub_match = dataUriRegexResult[2];
				std::string   isBase64 = base_sub_match.str();


				base_sub_match = dataUriRegexResult[3];
				std::string _base64 = base_sub_match.str();



				std::string base64 = URI.substr(37);



				const auto BEGIN = base64.begin();
				std::for_each(PRll_POLICY, access.begin(), access.end(), [&](auto& elem) {
					if (elem.next >= 0) {
						std::for_each(PRll_POLICY, elem.bufferView.begin(), elem.bufferView.end(), [&](auto& bv) {
							auto iter = BEGIN + bv.offset;
							Log_gltf("Level0     :Level1 : Level2   BEGIN %p  END %p  \n",iter,(iter + bv.bytesize ));
							_decode(bv.data, iter, iter + bv.bytesize);
							});
					}
			   });
			}
		}

	}
	void  GLTF_Loader::load_lod(std::vector<char> raw ,std::string _targetName ) {

		if (_targetName == "LOD") {
			target = arth::LOADER_TARGET::MESH_LOD;
		}
		else {
			target = arth::LOADER_TARGET::MESH_1;
			targetName = _targetName;
		}

		ViewSize = 0;
		ViewSize = carry->buffer->array._struct.size();// carry->buffer->array.fieldNum;
		if (ViewSize == 0)Log_bad("AttributeStruct::Bad.\n");

		json_settings settings;
		memset(&settings, 0, sizeof(json_settings));
		settings.settings = 1;
		char error[256];
		Log_gltf("loadParser      length  %zu   ViewNums  %zu \n", raw.size(),ViewSize);

#ifdef   Log_NO_GLTF
		std::chrono::time_point<std::chrono::steady_clock>  start = std::chrono::high_resolution_clock::now();
#endif
		data = json_parse_ex(&settings, raw.data(), raw.size(), error);

		std::string stage;
		json_value* ary;
		if (data->type == json_object) {
			for (int i = 0; i < int(data->u.object.length); i++) {
				stage = std::string(OBJ(data, i).name);
				Log_gltf("Level0     : %s  \n", stage.c_str());
				switch (i) {
				case GLTF_STAGE_scenes:
					parseScenes(OBJ(data, i).value);
					break;
				case GLTF_STAGE_nodes:
					ary = OBJ(data, i).value;
					if (ary->type == json_array) {
						std::mutex m;
						std::for_each(PRll_POLICY, access.begin(), access.end(), [&](auto& elem) {
							parseNodes(ARRAY(ary, elem.next), elem);
							});
					}
					break;

				case GLTF_STAGE_meshes:
					ary = OBJ(data, i).value;
					if (ary->type == json_array) {
						std::mutex m;
						std::for_each(PRll_POLICY, access.begin(), access.end(), [&](auto& elem) {
							if (elem.next >= 0) {
							    parseMeshes(ARRAY(ary, elem.next), elem);

							    if (ViewSize != (elem.bufferView.size() - 1)) {
								    Log_bad(" ParseMeshesError::BufferView Size Not match. \n");
							    }
							}
						});
					}
					break;

				case GLTF_STAGE_accessors:
					ary = OBJ(data, i).value;
					if (ary->type == json_array) {
						std::mutex m;
						std::for_each(PRll_POLICY, access.begin(), access.end(), [&](auto& elem) {
							if (elem.next >= 0) {
								std::for_each(PRll_POLICY, elem.bufferView.begin(), elem.bufferView.end(), [&](auto& bv) {
									if (elem.lod == 0 && bv.input == arth::INPUT::vertex_V3_POSITION)parseAccessors(ARRAY(ary, bv.next), bv, true);
									else parseAccessors(ARRAY(ary, bv.next), bv);
									});
							}
							});
					}
					break;

				case GLTF_STAGE_bufferViews:
					ary = OBJ(data, i).value;
					if (ary->type == json_array) {
						std::mutex m;
						std::for_each(PRll_POLICY, access.begin(), access.end(), [&](auto& elem) {
							if (elem.next >= 0) {
								std::for_each(PRll_POLICY, elem.bufferView.begin(), elem.bufferView.end(), [&](auto& bv) {
									parsebufferViews(ARRAY(ary, bv.next), bv);
									});
							}
							});
					}
					break;
				case GLTF_STAGE_buffers:
					ary = OBJ(data, i).value;
					if (ary->type == json_array) {
						mapBuffers(ARRAY(ary, 0));
					}
					std::for_each(PRll_POLICY, access.begin(), access.end(), [&](auto& elem) {
						Log_gltf("_bufferViews  IDX   %d    \n", elem.next);
						for (auto v : elem.bufferView) {
							Log_gltf("_bufferViews    ATTRIBUTE     next   %d   count %u  \n", v.next, v.bytesize);
						}
						});
					break;
				}
			};
		};

#ifdef   Log_NO_GLTF
		std::chrono::time_point<std::chrono::steady_clock>  now = std::chrono::high_resolution_clock::now();
		Log_info("GLTF LOAD     time    %.5f    ms \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()));
#endif

		if (data == 0) {
			Log_gltf("JsonParse  Nullptr %p \n", data);
			PyErr_BadArgument();
		}
		Log_gltf("JsonParse Free   \n");
		json_value_free(data);

		Log_gltf("JsonParse Fin   \n");

	}
	void  GLTF_Loader::map_lod() {

		Log_gltf("map_lod   \n");
		uint32_t arraySize = 0;
		uint32_t indexSize = 0;

		size_t meshSize = 0;
        for (int i = 0; i < access.size(); i++) {
		    if(access[i].next <0)continue;
		    meshSize++;
		}

        Log_gltf("Map  meshSize  %zu   \n",meshSize);

		std::vector<uint32_t> offset(meshSize);
		std::vector<uint32_t> offsetIndex(meshSize);
		size_t structSize = carry->buffer->array.structSize;

		std::vector<uint32_t> aid(meshSize);
		carry->lod.lodMax = 0;


		for (int i = 0; i < access.size(); i++) {
		    if(access[i].next <0)continue;
			aid[access[i].lod] = i;
			Log_gltf("Map  lod %u ==>  %d   \n",access[i].lod ,i);
			if (carry->lod.lodMax < uint32_t(access[i].lod))carry->lod.lodMax = access[i].lod;

		}

		for (int i = 0; i < meshSize; i++) {
			_Accessor&acs = access[aid[i]];
			std::vector<_BufferView>& bv = acs.bufferView;
			for(int j = 0; j < bv.size(); j++) {
				if (bv[j].input == arth::INPUT::vertex_V3_POSITION) {
					offset[i] = arraySize *uint32_t(structSize); arraySize += bv[j].arraysize;
				}
				if (bv[j].input == arth::INPUT::vertex_INDEX) {
					size_t iSize = sizeof(UINT32);
					if (bv[j].GLtype == GLTYPE_UINT16) {
						carry->buffer->idxType = VK_INDEX_TYPE_UINT16;
						iSize = sizeof(UINT16);
						Log_gltf("INDEX TYPE 16   \n" );
					}
					offsetIndex[i] = indexSize*uint32_t( iSize);
					carry->lod.firstIndex[i] = indexSize;
					carry->lod.indexCount[i] = bv[j].arraysize;
					indexSize += bv[j].arraysize;
				}
			}
		};
		carry->buffer->array.alloc(arraySize);
		VkIndexType TypeIdx = carry->buffer->idxType;


		if (arraySize >= UINT16_MAX) {

			carry->buffer->idxType = TypeIdx = VK_INDEX_TYPE_UINT32;
		}

		if (TypeIdx == VK_INDEX_TYPE_UINT16) {
			carry->buffer->index_short.resize(indexSize);
		}
		else {
			carry->buffer->index.resize(indexSize);
		}
		
		const auto  BEGIN = &aid[0];
		#define   IDX(e)  (&(e) - BEGIN)

		char* dst = carry->buffer->array.data;


#ifdef   Log_NO_GLTF
		std::chrono::time_point<std::chrono::steady_clock>  start = std::chrono::high_resolution_clock::now();
#endif
		
		std::for_each(PRll_MAP_POLICY, aid.begin(), aid.end(), [&](auto& elem) {


			uint32_t idx = (uint32_t)IDX(elem);
			
			const size_t ofs = offset[idx];
			if (access[elem].next > 0) {
				Log_gltf("INTERLEAVE         MAP   lOD IDX [%u == %u]  OFFSET   %u   \n", idx, access[elem].lod, ofs);
				std::vector<_BufferView>& Bv = access[elem].bufferView;
				const auto  BEGIN2 = &Bv[0];
#define   IDX2(e)  (&(e) - BEGIN2)
				const size_t* fieldSize = carry->buffer->array.fieldSize;
				const size_t* fieldoffset = carry->buffer->array.offset;


				std::for_each(PRll_MAP_POLICY, Bv.begin(), Bv.end(), [&](_BufferView& bv) {
					uint32_t idx2 = (uint32_t)IDX2(bv);

					if (ViewSize == idx2) {

						UINT_PTR iofs = (UINT_PTR)offsetIndex[idx];
						Log_gltf("INTERLEAVE  IDX %u   MEMCPY   ofs  %zu      dstSize %zu  <=  srcSize  %zu   \n", idx2, iofs, carry->buffer->index_short.size(), bv.data.size());

						if (bv.GLtype == GLTYPE_UINT16) {
							size_t vofs = (ofs / structSize);
							iofs /= 2;
							std::vector<uint16_t> v;
							v.resize(bv.arraysize);
							memcpy(v.data(), bv.data.data(), bv.arraysize * sizeof(uint16_t));
							if (TypeIdx == VK_INDEX_TYPE_UINT32) {
								UINT32 vofs32 = (UINT32)vofs;
								std::vector<uint32_t> v2(bv.arraysize);

								for (int i = 0; i < (int)bv.arraysize; i++) { v2[i] = (UINT32)v[i] + vofs32; };
								carry->buffer->index.insert(carry->buffer->index.begin() + iofs, v2.begin(), v2.end());

							}
							else {
								UINT16 vofs16 = (UINT16)vofs;
								std::for_each(PRll_VECTOR_POLICY, v.begin(), v.end(), [&](auto& v) { v += vofs16; });
								carry->buffer->index_short.insert(carry->buffer->index_short.begin() + iofs, v.begin(), v.end());
							}
						}
						else {
							UINT32  vofs = (UINT32)(ofs / structSize);
							iofs /= 4;
							std::vector<uint32_t> v;
							v.resize(bv.arraysize);
							memcpy(v.data(), bv.data.data(), bv.arraysize * sizeof(uint32_t));
							std::for_each(PRll_VECTOR_POLICY, v.begin(), v.end(), [&](auto& v) { v += vofs; });
							carry->buffer->index.insert(carry->buffer->index.begin() + iofs, v.begin(), v.end());

						}
						Log_gltf("INTERLEAVE      MEMCPY   ofs  %zu  =>  size  %zu   \n", iofs, bv.data.size());

					}
					else {
						int ofs2 = 0;
						for (int i = 0; i < int(bv.arraysize); i++) {
							memcpy(dst + ofs + structSize * i + fieldoffset[idx2], bv.data.data() + ofs2, fieldSize[idx2]);
							ofs2 += (int)fieldSize[idx2];
						};
						Log_gltf(" INTERLEAVE      MEMCPY  LOD %u   ofs %zu  ATTRIBUTE [%u]    structArray  %u  \n", idx, ofs, idx2, bv.arraysize);
					}
					});
			}
		});
		
#ifdef   Log_NO_GLTF
		std::chrono::time_point<std::chrono::steady_clock>  now = std::chrono::high_resolution_clock::now();
		Log_info(" INTERLEAVE      time    %.5f    ms \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()));
#endif


		carry->buffer->Size.array = carry->buffer->array.memorySize;
		if (TypeIdx == VK_INDEX_TYPE_UINT16) {
			carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index_short.size());
		}else carry->buffer->updateRange.count = static_cast<uint32_t>(carry->buffer->index.size());
		carry->buffer->Size.index = carry->buffer->updateRange.count * sizeof(uint32_t);

///#define PRINTSTRUCT


#ifdef  PRINTSTRUCT

        int ofs = 0;
       for( int o =0;o<offset.size();o++){

            for (int i = 0; i < 30; i++) {
               carry->buffer->array.printFloatStruct(i + ofs);
            }
            if(o < offset.size()-1)ofs = offset[o+1] / structSize;
		}
		

		for (int i = 0; i < offsetIndex.size(); i++) {
			size_t  idx = offsetIndex[i] / sizeof(UINT16);
			printf("index    %d \n", i);
			for (int j = 0; j < 30; j++) {
				printf("   %u    ", carry->buffer->index_short[idx+j]);
			}
			printf("\n");
		}
		for (int i = 0; i < 30; i++) {
			int  idx = int(indexSize - 1 - i);
			printf("[ %d   %u ]    ", idx, carry->buffer->index_short[idx]);
		}
		printf("\n");

#endif
#define PRINTLOD
#ifdef  PRINTLOD
		LODInfo&dol  =carry->lod;
		for (uint32_t i = 0; i <= dol.lodMax; i++) {
			printf("GLTF LOADER                 LOD%u  offset %u   count %u   \n", i, dol.firstIndex[i], dol.indexCount[i]);
		}
#endif
	}



#ifdef TEST2_GLTF
GLTFLoader::GLTFLoader() {

	dracoLoader = nullptr;
	ddsLoader = nullptr;

}



void GLTFLoader::load(
	std::string url,
	std::function<void(std::vector<ResType>)> _onLoad,
	std::function<void(std::string, uint32_t, uint32_t)> _onProgress ,
	std::function<void(std::string)> onError ) {

	std::string Path;
	if (resourcePath != "") {
		Path = resourcePath;
	}
	else if (path != "") {
		Path = path;
	}
	else {
		Path = utils.extractUrlBase(url);
	}

	manager->itemStart(url);


	std::function<void(std::string)>_onError = [=](std::string e) {

		if (onError) {
			onError(e);
		}
		else {
			Log_error("%s   \n", e.c_str());
		}

		manager->itemError(url);
		manager->itemEnd(url);
	};

	FileLoader* loader = new FileLoader(manager);

	loader->setPath(path);
	loader->setResponseType("arraybuffer");

	if (crossOrigin == "use-credentials") {
		loader->setWithCredentials("true");
	}
	std::function< void(std::vector<ResType>) > onLoad = [=](std::vector<ResType> data) {
		///try {

		parse(data, resourcePath, [=](std::vector<ResType> gltf) {

			_onLoad(gltf);

			manager->itemEnd(url);

			}, _onError);

		///}
	   ///catch (e) {

		///	_onError(e);

		///  }
	};

	loader->load(url, onLoad, _onProgress, _onError);

};

GLTFLoader& GLTFLoader::setDRACOLoader(DRACOLoader* dracoLoader) {
	dracoLoader = dracoLoader;
	return *this;
};

GLTFLoader& GLTFLoader::setDDSLoader(DDSLoader* ddsLoader) {
	ddsLoader = ddsLoader;
	return *this;
};

void GLTFLoader::parse(std::vector<ResType> data, std::string path, std::function<void(std::vector<ResType>)>  onLoad, std::function<void(std::string)> onError) {


	std::string  magic = std::string(data.data(), 0, 4);
	PyObject* content;

	if (magic == BINARY_EXTENSION_HEADER_MAGIC) {
		/*
		 try {

			 extensions[EXTENSIONS.KHR_BINARY_GLTF] = new GLTFBinaryExtension(data);


		 }catch (error) {

			 if (onError) onError(error);
			 return;

		  }
			content = extensions[EXTENSIONS.KHR_BINARY_GLTF].content;
		  */

	}
	else {
		content = decode_json(data.data());
	}

}

#endif