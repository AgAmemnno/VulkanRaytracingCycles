#pragma once
#ifndef VTHREEPY_CONST
#define VTHREEPY_CONST
#include <stdint.h>
#include <string>
using namespace std::string_view_literals;

const  uint32_t     OP_LOAD = 0;
const  uint32_t     OP_CLEAR = 1;


#define Per(photon)  int(90 * 100 * (photon))
constexpr uint64_t  Hz1G = 1;             ///nano second
constexpr uint64_t  Hz100M = 10;
constexpr uint64_t  Hz10M = 100;
constexpr uint64_t  Hz1M = 1000;       ///micro second
constexpr uint64_t  Hz100K = 10000;
constexpr uint64_t  Hz90K = 11111;  ///1/90000 second      0.1%
constexpr uint64_t  Hz10K = 100000;
constexpr uint64_t  Hz9K = 111111;   ///1/9000 second      1%
constexpr uint64_t  Hz1K = 1000000;   ///milli second
constexpr uint64_t  Hz900 = 1111111;  ///1/900 second     10%
constexpr uint64_t  Hz90 = 11111111;  ///1/90 second    100%
constexpr uint64_t operator"" _fr(long double per)
{
	return uint64_t(1000000000.L / 9000 * per);
}




typedef  std::string_view LayoutType;

constexpr LayoutType SU = "su"sv;
constexpr LayoutType SSS = "sss"sv;
constexpr LayoutType SSSS = "ssss"sv;
constexpr LayoutType SSUU = "ssuu"sv;
constexpr LayoutType SSUS = "ssus"sv;

constexpr LayoutType  TEX = "t"sv;
constexpr LayoutType  UNI = "u"sv;
constexpr LayoutType  UT = "ut"sv;
constexpr LayoutType  UUT = "uut"sv;
constexpr LayoutType  UTT = "utt"sv;
constexpr LayoutType  UUTT = "uutt"sv;
constexpr LayoutType  UTTT = "uttt"sv;




#endif
