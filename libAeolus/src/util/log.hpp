#pragma once

#ifndef LOGBAD_H
#define LOGBAD_H

#ifdef AEOLUS_EXE
#include "vulkan/vulkan.h"
#else
#include "pch.h"
#endif



/// DELETE ALL       ^((?!\w).)*log_once\(.*;     ^((?!\w).)*log_once\((.*\n)+?.*;
#define log_once(...) log__once(__FILE__, __LINE__, LOG_ONCE, __VA_ARGS__)


#ifdef LOG_NO_TRACE
#define log_trace(...)
#else
#define log_trace(...) log_out(__FILE__, __LINE__, LOG_TRACE, __VA_ARGS__)
#endif



#ifdef LOG_NO_DEBUG
#define log_debug(...)
#else
#define log_debug(...) log_out(__FILE__, __LINE__, LOG_DEBUG, __VA_ARGS__)
#endif


#define log_verbose(...) log_out(__FILE__, __LINE__, LOG_VERBOSE, __VA_ARGS__)

// we always want these messages
#define log_info(...) log_out(__FILE__, __LINE__, LOG_INFO, __VA_ARGS__)
#define log_warning(...) log_out(__FILE__, __LINE__, LOG_WARNING, __VA_ARGS__)
#define log_error(...) log_out(__FILE__, __LINE__, LOG_ERROR, __VA_ARGS__)
#define log_bad(...) log__bad(__FILE__, __LINE__, LOG_BAD, __VA_ARGS__)
#define log_vkabad(...) log__vkabad(__FILE__, __LINE__, LOG_VKABAD, __VA_ARGS__)
#define log_fatal(...) log_out(__FILE__, __LINE__, LOG_FATAL, __VA_ARGS__)





enum LOG_LEVEL {
	LOG_TRACE = 1,
	LOG_DEBUG = 2,
	LOG_VERBOSE = 4,
	LOG_INFO = 8,
	LOG_WARNING = 16,
	LOG_ERROR = 32,
	LOG_FATAL = 64,
	LOG_BAD = 128,
	LOG_VKABAD = 256,
	LOG_ONCE = 512,
	LOG_CPP = 1024,
	LOG_THREAD = 2048,
	LOG_FILE       = 4096,
};

void testit(char* fmt, ...);


void log_init(void);
void log_out(char* file, int line, enum LOG_LEVEL level, char* fmt, ...);
///void log__bad(char* file, int line, enum LOG_LEVEL level, char* fmt, ...);
void log__bad(const char* file, int line, enum LOG_LEVEL level, const char* fmt, ...);
void log__vkabad(char* file, int line, enum LOG_LEVEL level, VkResult code, char* fmt, ...);
void log__once(char* file, int line, enum LOG_LEVEL level, char* fmt, ...);
//void log__thread(char* file, int line, enum LOG_LEVEL level, char* fmt, ...);
void log__thread(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...);
void log__save(char* file, char* fmt);


void exitFatal();


const char* errorString(VkResult errorCode);

#endif