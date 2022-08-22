#pragma once

#ifndef LogBAD_H
#define LogBAD_H
#include  <stdio.h>       ///Log.cpp ///math/common.cpp
#include  <stdarg.h>     ///Log.cpp
#include  <inttypes.h>  ///Log.cpp
#include  <math.h>       ///Log.cpp
#include  <time.h>        ///Log.cpp
#include  <fstream>     ///Log.cpp

/*
#if defined(LIB_VTHREEPY)
#include  "aeolus/incomplete.h"
#include "aeolus/AllocatorVk.h"
extern front::DeallocatorVk des;
#endif
*/



/// DELETE ALL       ^((?!\w).)*Log_once\(.*;     ^((?!\w).)*Log_once\((.*\n)+?.*;
#define Log_once(...) Log__once(__FILE__, __LINE__, Log_ONCE, __VA_ARGS__)


#ifdef Log_NO_TRACE
#define Log_trace(...)
#else
#define Log_trace(...) Log_out(__FILE__, __LINE__, Log_TRACE, __VA_ARGS__)
#endif



#ifdef Log_NO_DEBUG
#define Log_debug(...)
#else
#define Log_debug(...) Log_out(__FILE__, __LINE__, Log_DEBUG, __VA_ARGS__)
#endif


#define Log_verbose(...) Log_out(__FILE__, __LINE__, Log_VERBOSE, __VA_ARGS__)

// we always want these messages
#define Log_info(...) Log_out(__FILE__, __LINE__, Log_INFO, __VA_ARGS__)
#define Log_warning(...) Log_out(__FILE__, __LINE__, Log_WARNING, __VA_ARGS__)
#define Log_error(...) Log_out(__FILE__, __LINE__, Log_ERROR, __VA_ARGS__)
#define Log_bad(...) Log__bad(__FILE__, __LINE__, Log_BAD, __VA_ARGS__)
#define Log_fatal(...) Log_out(__FILE__, __LINE__, Log_FATAL, __VA_ARGS__)





enum Log_LEVEL {
	Log_TRACE = 1,
	Log_DEBUG = 2,
	Log_VERBOSE = 4,
	Log_INFO = 8,
	Log_WARNING = 16,
	Log_ERROR = 32,
	Log_FATAL = 64,
	Log_BAD = 128,
	Log_VKABAD = 256,
	Log_ONCE = 512,
	Log_CPP = 1024,
	Log_THREAD = 2048,
	Log_FILE       = 4096,
};


void Log_init(void);
void Log_out(const char* file, int line, enum Log_LEVEL level, const char* fmt, ...);
void Log__bad(const char* file, int line, enum Log_LEVEL level, const char* fmt, ...);
void Log__once(const char* file, int line, enum Log_LEVEL level,const  char* fmt, ...);
void Log__thread(const char* file, int line, enum Log_LEVEL level, const char* fmt, ...);



void ExitFatal();




#endif