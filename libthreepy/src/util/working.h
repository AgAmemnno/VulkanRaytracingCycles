#pragma once
#ifndef UTIL_H
#define UTIL_H
#include <utility>
#include "enum.hpp"





struct NameString {
	int                                     id;

	std::string                       spv;
	std::string             pipeName;
	std::string          imageName;

	struct {
		uint32_t vert;
		uint32_t frag;
	}spz;

};

namespace aeo {

	class Material {

	public:

		PyObject_HEAD

			arth::eMATERIAL                              type;
		arth::TEXTURE                            texType;
		size_t                             HASH{ size_t(-1) };

		struct Desc {
			LayoutType           type;
			VkDeviceSize       align;
			size_t                  hash;
			float                reserveRatio;
		}desc;

		arth::INPUT                              pipeInput;
		Hache                                                pipe;

		NameString* names = nullptr;

		Material() {
			names = new NameString;
		};
		virtual ~Material() {
			__Delete__(names);
		};
		virtual int update() { return 0; };

		bool operator == (Material& that)
		{
			return this == &that;
		}
	};

}


namespace util {

	template<typename  Fnty, typename T, typename Out, typename... In>
	auto _TypeBullet(T*&& _aho, Out(*)(In...))
	{
		return  [](void* aho, In... arguments) -> Out
		{
			return (*((T*)aho))(arguments...);
		};
	};

	template<typename Fnty, class T>
	auto TypeBullet(T*&& c) {
		return _TypeBullet<Fnty, T>(std::forward<T*>(c), (Fnty*)nullptr);
	};


	template<typename Out, typename... In >
	struct descaller {

		typedef Out(*Fnty)(In...);

		Out(*bull)(void*, In...) = nullptr;
		void* voidp = nullptr;

		template <class Aho>
		void set(Aho*&& aho) {

			if (voidp != nullptr) {
				if (next == nullptr) next = new  descaller<Out, In...>;
				return next->set(std::forward<Aho*>(aho));
			};
			voidp = (void*)aho;
			bull = TypeBullet<Out(In...), Aho>(std::forward<Aho*>(aho));
		};

		template<typename... In>
		void call(In...  arg) {
			if (voidp != nullptr)bull(voidp, arg ...);
			if (next != nullptr)next->call(arg ...);
		};

		descaller* next = nullptr;
		~descaller() {
			if (next != nullptr) {
				delete next; next = nullptr;
			};
		};

	};


	template<typename Out, typename... In >
	struct _descaller {

		typedef Out(*Fnty)(In...);

		std::function<Out(In...)>  bull= nullptr;

		template <class Aho>
		void set(Aho&& aho) {
			if (bull  != nullptr) {
				if (next == nullptr) next = new  _descaller<Out, In...>;
				return next->set(std::forward<Aho>(aho));
			};
			bull = std::move(aho);  ///std::forward<Aho>(aho);
		};

		template<typename... In>
		void call(In...  arg) {
			if (bull != nullptr)bull(arg ...);
			if (next != nullptr)next->call(arg ...);
		};

		_descaller* next = nullptr;
		~_descaller() {
			if (next != nullptr) {
				delete next; next = nullptr;
			};
		};

	};
};

#endif