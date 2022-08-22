#pragma once
#ifndef ENUM_TYPES
#define ENUM_TYPES

#include <type_traits>   ///aeolus.cpp


namespace arth {
	///https://stackoverflow.com/questions/18803940/how-to-make-enum-class-to-work-with-the-bit-or-feature/18803980
	template <typename T, bool = std::is_enum<T>::value>
	struct is_flag;

	template <typename T>
	struct is_flag<T, true> : std::false_type { };

	template <typename T, typename std::enable_if<is_flag<T>::value>::type * = nullptr>
	T operator |(T lhs, T rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return static_cast<T>(static_cast<u_t>(lhs) | static_cast<u_t>(rhs));
	}

	template <typename T, typename std::enable_if<is_flag<T>::value>::type * = nullptr>
	T operator &(T lhs, T rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return static_cast<T>(static_cast<u_t>(lhs) & static_cast<u_t>(rhs));
	}

	template <typename T, typename std::enable_if<is_flag<T>::value>::type * = nullptr>
	T operator ~(T rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return static_cast<T>(~static_cast<u_t>(rhs));
	}

	template <typename T, typename std::enable_if<is_flag<T>::value>::type * = nullptr>
	bool operator >(T lhs, T rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return  static_cast<u_t>(lhs) > static_cast<u_t>(rhs);
	}
	template <typename T, typename std::enable_if<is_flag<T>::value>::type * = nullptr>
	bool operator >=(T lhs, T rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return  static_cast<u_t>(lhs) >= static_cast<u_t>(rhs);
	}

	template <typename T, typename std::enable_if<is_flag<T>::value>::type * = nullptr>
	bool operator <(T lhs, T rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return   static_cast<u_t>(lhs) < static_cast<u_t>(rhs);
	}
	template <typename T, typename std::enable_if<is_flag<T>::value>::type * = nullptr>
	bool operator <=(T lhs, T rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return   static_cast<u_t>(lhs) <= static_cast<u_t>(rhs);
	}

	template <typename T, typename T2, typename std::enable_if<is_flag<T>::value>::type* = nullptr>
	bool operator ==(T lhs, T2 rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return   static_cast<u_t>(lhs) == static_cast<u_t>(rhs);
	};
	template <typename T, typename T2, typename std::enable_if<is_flag<T>::value>::type* = nullptr>
	bool operator !=(T lhs, T2 rhs) {
		using u_t = typename std::underlying_type<T>::type;
		return   static_cast<u_t>(lhs) != static_cast<u_t>(rhs);
	};




	typedef  unsigned long ENUM_TYPE;
	
	enum class  Object : ENUM_TYPE {
		Scene = 0,
		Camera = 1,
		Light = 2,
		Mesh = 3,
		Line = 4,
		Points = 5,
		SkinnedMesh = 6,
		InstancedMesh = 7,
		Sprite = 8,
		Overlay = 9,
		Canvas = 10,
		OverlayMesh = 11
	};
	template <> struct is_flag<Object> : std::true_type { };

#ifdef VULKAN_THREE

	enum class  PASS : ENUM_TYPE {
		IMMUTABLE = 0,
		MUTABLE = 1,
		OVERLAY =2
	};
	template <> struct is_flag<PASS> : std::true_type { };

	enum class  DRAW : ENUM_TYPE {
		DIRECT                =   0,
		INDIRECT            =   1,
		INDIRECT_LOD   =   2,
		NONE                   =   3
	};
	template <> struct is_flag<DRAW> : std::true_type { };


	enum class  GEOMETRY : ENUM_TYPE {
		BUFFER = 0x001,
		SPRITE = 0x002,
		INSTANCED = 0x010,
		COMPUTE = 0x100,

		SUSPEND = 0x101,
		FILE         = 0x110,

		MUTABLE_BIT = 0x1000,     /// every make  with secondary command 
		BUFFER_MUTABLE = 0x1001,
		INSTANCED_MUTABLE = 0x1010,

		IMMUTABLE_BIT = 0x10000,   ///build and updateDescriptor
		RT_BIT                  = 0x1000000,
		OVERLAY_BIT      =  0x10000000,


		BUFFER_OVERLAY_MUTABLE = OVERLAY_BIT | BUFFER | MUTABLE_BIT,
		SPRITE_OVERLAY_MUTABLE = OVERLAY_BIT | SPRITE  | MUTABLE_BIT,
		BUFFER_OVERLAY_IMMUTABLE = OVERLAY_BIT | BUFFER | IMMUTABLE_BIT,
		SPRITE_OVERLAY_IMMUTABLE = OVERLAY_BIT | SPRITE  | IMMUTABLE_BIT,
		ALL_GEOMETRY
	};
	template <> struct is_flag<GEOMETRY> : std::true_type { };



	enum class  GEOMETRY_NAME : ENUM_TYPE {
		TRIANGLE = 0b0001,
		PLANE        = 0b0010,
		SPHERE      = 0b0011,

		LOD_BIT             = 0b100000000,
		TRIANGLE_LOD  = 0b100000001,
		PLANE_LOD		    = 0b100000010,
		SPHERE_LOD      = 0b100000011,

	};
	template <> struct is_flag<GEOMETRY_NAME> : std::true_type { };


	enum class  SCALAR : ENUM_TYPE {

		B8    = 0b0000000000000010,
		B16   = 0b0000000000000100,
		B32  = 0b0000000000010000,
		B64  = 0b0000000100000000,

		REAL   =   0b0000001000000000,
		INT     =   0b0000010000000000,
		UINT =     0b0000100000000000,

	};
	template <> struct is_flag<SCALAR> : std::true_type { };

	enum class  INPUT : ENUM_TYPE {

		vertexPRS = 0b000001,
		vertexPC = 0b000010,
		vertexPUN = 0b000011,
		vertexPV = 0b000100,
		vertexPNC = 0b000101,
		vertexPQS = 0b000110,
		vertexPQS4 = 0b000111,
		vertexPN = 0b001000,
		vertexSprite = 0b001001,
		vertexP        = 0b001010,
		ALL_TYPE,

		vertex_F = 0b0000000000010000,
		vertex_F_SCALE,
		vertex_V2 = 0b0000000100000000,
		vertex_V2_UV,
		vertex_V2_POSITION,
		vertex_V3 = 0b0001000000000000,
		vertex_V3_POSITION,
		vertex_V3_NORMAL,
		vertex_V3_COLOR,
		vertex_V3_TANGENT,
		vertex_V3_BITANGENT,
		vertex_V3_ROTATION,
		vertex_V3_SCALE,
		vertex_V4 = 0b10000000000000000,
		vertex_V4_POSITION,
		vertex_V4_QUATERNION,
		vertex_V4_VELOCITY,
		vertex_V4_SCALE,
		vertex_INDEX,
		ALL

	};
	template <> struct is_flag<INPUT> : std::true_type { };

	const uint32_t INPUT_TYPE_ALL = uint32_t(INPUT::ALL_TYPE);


	enum class  TEST_SHADER : ENUM_TYPE {
		multiview   = 0,
		instancing  = 1,
		compute    = 2,
		AMT,
	};
	template <> struct is_flag<TEST_SHADER> : std::true_type { };


	enum class  LOADER_TARGET : ENUM_TYPE {
		MESH_1           =  0x000000000,
		MESH_MULTI =  0x000010000,
		MESH_LOD,  
		ALL
	};
	template <> struct is_flag< LOADER_TARGET> : std::true_type {};


	enum class  TEXTURE : ENUM_TYPE {
		STB            = 0,
	    TEXT_KTX = 1,
	};
	template <> struct is_flag<TEXTURE> : std::true_type { };

};



#define arth_GEOMETRY_NAME_LOD(t)  ((arth::GEOMETRY_NAME::LOD_BIT& (t))==arth::GEOMETRY_NAME::LOD_BIT)


namespace arth {

	enum class  COM_TYPE : ENUM_TYPE {
			UINT32  = 0,
			INT32    = 1,
			CARRY    = 2,
			RAW      = 3
	};
	template <> struct is_flag<COM_TYPE> : std::true_type {};

	///pipeline layout type enumeration
	enum class  COM_SYS : ENUM_TYPE {
		Type1 = 0b10000,
		Type1_SU = 0b1000010,
		Type1_FRUSTUM = 0b1000011,
		Type2 = 0b100000,
		Type2_S,
		Type3   = 0b1000000,
		Type3_S,
		Type4 = 0b10000000,
		Type5 = 0b100000000,
	};
	template <> struct is_flag<COM_SYS> : std::true_type {};

	///descripter layout type enumeration
	enum class  COM_IO : ENUM_TYPE {
		UNIFORM = 0b10000,
		UNIFORM2 = 0b10001,
		UNIFORM3,
		SSBO = 0b100000,
		SSBO2,
		SSBO3,
		SAMPLER = 0b1000000,
	};
	/*
	enum class  COM_IO : ENUM_TYPE {
		UINT32 = 0b00001,
		FLOAT32,

		Dim0 = 0b1000000,
		Dim1 = 0b10000000,
		Dim2 = 0b100000000,
		Dim3 = 0b1000000000,
	};
	*/
	template <> struct is_flag<COM_IO> : std::true_type {};

	enum class  COM_BUFFER {
		DEV_SSBO = 0,
		DEV_SSBO_VERT = 1,
		DEBUG = 2,
	};
	template <> struct is_flag<COM_BUFFER> : std::true_type {};
};


namespace arth {
	enum class EV_BUTTON : ENUM_TYPE {
		Button_System = 0b00000001,
		Button_ApplicationMenu = 0b00000010,
		Button_Grip = 0b00000100,
		Button_Pad = 0b00001000,
		Button_Trigger = 0b00010000,
	};
	template <> struct is_flag<EV_BUTTON> : std::true_type {};
}

namespace arth {
	enum class MATERIAL : ENUM_TYPE {
		RAW  = 0,
		TEXT = 1
	};
	template <> struct is_flag<MATERIAL> : std::true_type {};

	enum class TOPICS : ENUM_TYPE {
		RAW      = 0x0,
		SERVER = 0x1,
		MODEL  = 0x2,
		POLLING_BIT = 0x1000, 
	};
	template <> struct is_flag<TOPICS> : std::true_type {};
}


#define arth_MODE_SPRITE_AUTO(t)  ((arth::mode::SPRITE::AUTODRAW_BIT& (t))==arth::mode::SPRITE::AUTODRAW_BIT)
#define arth_MODE_SPRITE_CB(t)  ((arth::mode::SPRITE::PyCALLBACK_BIT& (t))==arth::mode::SPRITE::PyCALLBACK_BIT)

namespace arth {

	enum class TEXTMODE : ENUM_TYPE {

			FRAME = 0b1,
			TIME = 0b10,
			CPU_RAM = 0b11,
			GPU_RAM = 0b100,
			PyCALLBACK_BIT = 0b000010000,
			PyCB_FRAME = PyCALLBACK_BIT | FRAME,
			AUTODRAW_BIT = 0b100000000,
			AUTO_FRAME = AUTODRAW_BIT | FRAME,

		};

	template <> struct is_flag<TEXTMODE> : std::true_type {};
}

struct vertexPRS;
struct vertexPC;
struct vertexPUN;
struct vertexPV;


namespace arth {

	enum class CmdType : ENUM_TYPE {
		Main  = 0b0,
		Immidiate,
		Secondary,
		ALL
	};

	template <> struct is_flag<CmdType> : std::true_type {};
}

namespace arth {

	enum class  eGEOMETRY : ENUM_TYPE {

		TRIANGLE = 1,
		PLANE = 1 << 1,
		SPHERE = 1 << 2,
		BOX = 1 << 3,


		LOD_BIT = 1 << 29,
		TEXELBUFFER_BIT = 1 << 30,


	};
	template <> struct is_flag<eGEOMETRY> : std::true_type { };

	enum class eMATERIAL : ENUM_TYPE {
		RAW = 0,
		GUI = 1 << 1,
		MSDF = 1 << 2,
		MESH = 1 << 3,
		LOD = 1 << 4,
		RAW2 = 1 << 5,
		CONV = 1 << 6,
		LOD2 = 1 << 7,
		RT     = 1 << 8,
		RTC   = 1 << 9,
		VID   = 1 << 10,
		GEO  = 1 << 11,
		MESH2 = 1 << 12,
		ALL
	};
	template <> struct is_flag<eMATERIAL> : std::true_type {};

};

#define EQ_ARTH(type,artho) ( ( (type) & artho) == (artho))

#define EQ_ANY_ARTH(type,artho) ( ( (type) & artho) != 0)
#define LEQ_ANY_ARTH(type,artho)  (  ( ((type) & artho) != 0 ) && (type <=  artho )  )
#define LEQ_ANY_MASK_ARTH(type,artho,mask)  (  ( ((type) & artho) != 0 ) && (  (type&(mask)) <=  artho )  )

namespace arth {

	enum class  BRUNCH_PROC : ENUM_TYPE {


		UPDATE = 0x0,
		DEL = 0x1,
		DEBUT = 0x2,
		RESHARD = 0x3,
		MAKE = 0x4,
		RETIRE = 0x5,
		WILD = 0x10,
		NAIVE = 0x20,
		NONE = 0x30,
		CANVAS = 0x40,
		GUI = 0x50,
		FON = 0x60,


		OBJ3D = 0x100,
		GROUP = 0x200,
		MESH = 0x300,

		MUTABLE = 0x1000,
		OVERLAY = 0x2000,
		IMMUTABLE = 0x3000,
		RT = 0x4000,
		ALL,
	};

	template <> struct is_flag< BRUNCH_PROC> : std::true_type {};


	enum class eSUBMIT_MODE:ENUM_TYPE {
		Separate,
		Inline,
		OneTime,
		Simulataneos,
		ALL
	};
	template <> struct is_flag<eSUBMIT_MODE> : std::true_type {};

};


#endif 

#endif

