#pragma once
#ifndef   PRICON_MM_H
#define   PRICON_MM_H


#include "pch_three.h"


#include <conio.h>
#include <condition_variable>  ///AllocateVk
#include  <regex>             ///LoadingManager.cpp
#include <memory>       ///overlayVk.cpp
#include <execution>  ///overlayVk.cpp
#include <unordered_set>
#include <array>            ///Scriptor.h  ///overlayVk.cpp
#include <vector>

#include <mutex>       ///AllocateVk
#include <queue>        ///AllocateVk

#include <any>
#include <compare> 


using namespace std::string_view_literals;  ///types1.h




#include "Vk.h"
#include "Catcher.h"
///#pragma comment(lib, "Catcher.lib")
#include "xrui.h"
///#pragma comment(lib, "xrui.lib")

#include <ktx.h>
#include <ktxvulkan.h>
#include  "libktx.h"



#if __linux__ || __APPLE__ || __sun
#include <unistd.h>
#elif _WIN32

#include "tbb/tbb_config.h"
#include "ext/harness_defs.h"
#include "tbb/machine/windows_api.h"
#endif /* OS specific */
#include <memory>
#include <new>
#include <cstdio>
#include <stdexcept>
#include <utility>
#include __TBB_STD_SWAP_HEADER

///#include "tbb/atomic.h"
#include "tbb/tbb_allocator.h"
#include "tbb/parallel_for.h"
#include "tbb/concurrent_unordered_map.h"
//#include "tbb/concurrent_hash_map.h"
#include "tbb/concurrent_vector.h"

#define USE_HIREDIS

#ifndef USE_TBB
#define USE_TBB
#endif

#ifdef USE_HIREDIS
#include <hiredis/hiredis.h>
#ifdef _MSC_VER
#include <winsock2.h> /* For struct timeval */
#endif
static const char* reply_types[] = {
"REPLY0",
"STRING",
 "ARRAY",
"INTEGER",
"NIL",
"STATUS",
"ERROR",
"UNKNWON"
};
#define  RD_ARRAY_PRINT(cmd,...){\
	redisReply* _reply = (redisReply*)redisCommand(c, cmd,__VA_ARGS__);\
	if( (_reply!=NULL) &  (_reply->type == REDIS_REPLY_ARRAY)) {\
		for (int j = 0; j < _reply->elements; j++) {\
			printf("%u) %s\n", j, _reply->element[j]->str);\
		}\
	};	freeReplyObject(_reply); }
#define RD_CHECK(X) if ( !X || X->type == REDIS_REPLY_ERROR ) { printf("Error\n"); exit(-1); }
#define RD_REPLY_PRINT(reply)printf("res: %s, num: %zu, type: %s\n", reply->str, reply->elements,reply_types[ reply->type ]);


#endif
#endif