#pragma once
#ifndef THREEPY_CONST
#define THREEPY_CONST

typedef const unsigned int _CONST;
typedef unsigned int _CVAR;


#define _Identity16  { 1,0,0,0,\
							 0,1,0,0,\
					         0,0,1,0,\
					         0,0,0,1 };

#define _Identity9  { 1,0,0,\
								0,1,0, \
							    0,0,1};


_CONST CullFaceNone = 0;
_CONST CullFaceBack = 1;
_CONST CullFaceFront = 2;
_CONST CullFaceFrontBack = 3;
_CONST FrontFaceDirectionCW = 0;
_CONST FrontFaceDirectionCCW = 1;
_CONST BasicShadowMap = 0;
_CONST PCFShadowMap = 1;
_CONST PCFSoftShadowMap = 2;
_CONST VSMShadowMap = 3;
_CONST FrontSide = 0;
_CONST BackSide = 1;
_CONST DoubleSide = 2;
_CONST FlatShading = 1;
_CONST SmoothShading = 2;
_CONST NoColors = 0;
_CONST FaceColors = 1;
_CONST VertexColors = 2;
_CONST NoBlending = 0;
_CONST NormalBlending = 1;
_CONST AdditiveBlending = 2;
_CONST SubtractiveBlending = 3;
_CONST MultiplyBlending = 4;
_CONST CustomBlending = 5;
_CONST AddEquation = 100;
_CONST SubtractEquation = 101;
_CONST ReverseSubtractEquation = 102;
_CONST MinEquation = 103;
_CONST MaxEquation = 104;
_CONST ZeroFactor = 200;
_CONST OneFactor = 201;
_CONST SrcColorFactor = 202;
_CONST OneMinusSrcColorFactor = 203;
_CONST SrcAlphaFactor = 204;
_CONST OneMinusSrcAlphaFactor = 205;
_CONST DstAlphaFactor = 206;
_CONST OneMinusDstAlphaFactor = 207;
_CONST DstColorFactor = 208;
_CONST OneMinusDstColorFactor = 209;
_CONST SrcAlphaSaturateFactor = 210;
_CONST NeverDepth = 0;
_CONST AlwaysDepth = 1;
_CONST LessDepth = 2;
_CONST LessEqualDepth = 3;
_CONST EqualDepth = 4;
_CONST GreaterEqualDepth = 5;
_CONST GreaterDepth = 6;
_CONST NotEqualDepth = 7;
_CONST MultiplyOperation = 0;
_CONST MixOperation = 1;
_CONST AddOperation = 2;
_CONST NoToneMapping = 0;
_CONST LinearToneMapping = 1;
_CONST ReinhardToneMapping = 2;
_CONST Uncharted2ToneMapping = 3;
_CONST CineonToneMapping = 4;
_CONST ACESFilmicToneMapping = 5;

_CONST UVMapping = 300;
_CONST CubeReflectionMapping = 301;
_CONST CubeRefractionMapping = 302;
_CONST EquirectangularReflectionMapping = 303;
_CONST EquirectangularRefractionMapping = 304;
_CONST SphericalReflectionMapping = 305;
_CONST CubeUVReflectionMapping = 306;
_CONST CubeUVRefractionMapping = 307;
_CONST RepeatWrapping = 1000;
_CONST ClampToEdgeWrapping = 1001;
_CONST MirroredRepeatWrapping = 1002;
_CONST NearestFilter = 1003;
_CONST NearestMipmapNearestFilter = 1004;
_CONST NearestMipMapNearestFilter = 1004;
_CONST NearestMipmapLinearFilter = 1005;
_CONST NearestMipMapLinearFilter = 1005;
_CONST LinearFilter = 1006;
_CONST LinearMipmapNearestFilter = 1007;
_CONST LinearMipMapNearestFilter = 1007;
_CONST LinearMipmapLinearFilter = 1008;
_CONST LinearMipMapLinearFilter = 1008;
_CONST UnsignedByteType = 1009;
_CONST ByteType = 1010;
_CONST ShortType = 1011;
_CONST UnsignedShortType = 1012;
_CONST IntType = 1013;
_CONST UnsignedIntType = 1014;
_CONST FloatType = 1015;
_CONST HalfFloatType = 1016;
_CONST UnsignedShort4444Type = 1017;
_CONST UnsignedShort5551Type = 1018;
_CONST UnsignedShort565Type = 1019;
_CONST UnsignedInt248Type = 1020;
_CONST AlphaFormat = 1021;
_CONST RGBFormat = 1022;
_CONST RGBAFormat = 1023;
_CONST LuminanceFormat = 1024;
_CONST LuminanceAlphaFormat = 1025;
_CONST RGBEFormat = RGBAFormat;
_CONST DepthFormat = 1026;
_CONST DepthStencilFormat = 1027;
_CONST RedFormat = 1028;
_CONST RGB_S3TC_DXT1_Format = 33776;
_CONST RGBA_S3TC_DXT1_Format = 33777;
_CONST RGBA_S3TC_DXT3_Format = 33778;
_CONST RGBA_S3TC_DXT5_Format = 33779;
_CONST RGB_PVRTC_4BPPV1_Format = 35840;
_CONST RGB_PVRTC_2BPPV1_Format = 35841;
_CONST RGBA_PVRTC_4BPPV1_Format = 35842;
_CONST RGBA_PVRTC_2BPPV1_Format = 35843;
_CONST RGB_ETC1_Format = 36196;
_CONST RGBA_ASTC_4x4_Format = 37808;
_CONST RGBA_ASTC_5x4_Format = 37809;
_CONST RGBA_ASTC_5x5_Format = 37810;
_CONST RGBA_ASTC_6x5_Format = 37811;
_CONST RGBA_ASTC_6x6_Format = 37812;
_CONST RGBA_ASTC_8x5_Format = 37813;
_CONST RGBA_ASTC_8x6_Format = 37814;
_CONST RGBA_ASTC_8x8_Format = 37815;
_CONST RGBA_ASTC_10x5_Format = 37816;
_CONST RGBA_ASTC_10x6_Format = 37817;
_CONST RGBA_ASTC_10x8_Format = 37818;
_CONST RGBA_ASTC_10x10_Format = 37819;
_CONST RGBA_ASTC_12x10_Format = 37820;
_CONST RGBA_ASTC_12x12_Format = 37821;
_CONST LoopOnce = 2200;
_CONST LoopRepeat = 2201;
_CONST LoopPingPong = 2202;
_CONST InterpolateDiscrete = 2300;
_CONST InterpolateLinear = 2301;
_CONST InterpolateSmooth = 2302;
_CONST ZeroCurvatureEnding = 2400;
_CONST ZeroSlopeEnding = 2401;
_CONST WrapAroundEnding = 2402;
_CONST TrianglesDrawMode = 0;
_CONST TriangleStripDrawMode = 1;
_CONST TriangleFanDrawMode = 2;
_CONST LinearEncoding = 3000;
_CONST sRGBEncoding = 3001;
_CONST GammaEncoding = 3007;
_CONST RGBEEncoding = 3002;
_CONST LogLuvEncoding = 3003;
_CONST RGBM7Encoding = 3004;
_CONST RGBM16Encoding = 3005;
_CONST RGBDEncoding = 3006;
_CONST BasicDepthPacking = 3200;
_CONST RGBADepthPacking = 3201;
_CONST TangentSpaceNormalMap = 0;
_CONST ObjectSpaceNormalMap = 1;

_CONST ZeroStencilOp = 0;
_CONST KeepStencilOp = 7680;
_CONST ReplaceStencilOp = 7681;
_CONST IncrementStencilOp = 7682;
_CONST DecrementStencilOp = 7683;
_CONST IncrementWrapStencilOp = 34055;
_CONST DecrementWrapStencilOp = 34056;
_CONST InvertStencilOp = 5386;

_CONST NeverStencilFunc = 512;
_CONST LessStencilFunc = 513;
_CONST EqualStencilFunc = 514;
_CONST LessEqualStencilFunc = 515;
_CONST GreaterStencilFunc = 516;
_CONST NotEqualStencilFunc = 517;
_CONST GreaterEqualStencilFunc = 518;
_CONST AlwaysStencilFunc = 519;

_CONST StaticDrawUsage = 35044;
_CONST DynamicDrawUsage = 35048;
_CONST StreamDrawUsage = 35040;
_CONST StaticReadUsage = 35045;
_CONST DynamicReadUsage = 35049;
_CONST StreamReadUsage = 35041;
_CONST StaticCopyUsage = 35046;
_CONST DynamicCopyUsage = 35050;
_CONST StreamCopyUsage = 35042;


_CONST DIRECTIONAL_UBO = 48;
_CONST SPOT_UBO = 80;


#endif