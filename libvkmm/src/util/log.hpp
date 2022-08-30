#pragma once

#ifndef LOGBAD_H
#define LOGBAD_H

#ifdef AEOLUS_EXE
#include "vulkan/vulkan.h"
#else
#include "pch_mm.h"
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
#define log_vs(...) log__vs(__FILE__, __LINE__, LOG_INFO, __VA_ARGS__)


#define ASSERT_PRINT(condition,...) \
    do { \
        if (! (condition)) { \
			log_out(__FILE__, __LINE__, LOG_INFO, __VA_ARGS__);\
            std::terminate(); \
        } \
    } while (false)



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
	LOG_FILE = 4096,
};

void testit(const  char* fmt, ...);


void log_init(void);
void log_out(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...);
void log__bad(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...);
void log__vkabad(const  char* file, int line, enum LOG_LEVEL level, VkResult code, const  char* fmt, ...);
void log__once(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...);
void log__thread(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...);
void log__save(const  char* file, const  char* fmt);
void log__vs(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...);

void exitFatal();


const char* errorString(VkResult errorCode);
static const char* log_label(enum LOG_LEVEL level)
{
	switch (level) {
	case LOG_TRACE:
		return "\x1b[37m[TRACE]\x1b[0m";	// bright white
	case LOG_DEBUG:
		return "\x1b[36m[DEBUG]\x1b[0m";	// cyan
	case LOG_VERBOSE:
		return "\x1b[34m[VERBOSE]\x1b[0m";	// blue
	case LOG_INFO:
		return "\x1b[32m[INFO]\x1b[0m";		// green
	case LOG_WARNING:
		return "\x1b[33m[WARN]\x1b[0m";		// yellow
	case LOG_ERROR:
		return "\x1b[35m[ERROR]\x1b[0m";	// magenta
	case LOG_BAD:
		return "\x1b[41m\x1b[1m[BAD]\x1b[0m";
	case LOG_VKABAD:
		return "\x1b[33m\x1b[1m[VKABAD]\x1b[0m";
	case LOG_ONCE:
		return "\x1b[42m[ONCE]\x1b[0m";
	case LOG_THREAD:
		return "\x1b[32m\x1b[1m[THREAD]\x1b[0m";
	case LOG_FILE:
		return "[FILE]";
	case LOG_CPP:
		return "\x1b[43m[CPP]\x1b[0m";	// red
	case LOG_FATAL:
		return "\x1b[31m[FATAL]\x1b[0m";	// red
	default:
		return "\x1b[0m";		// reset
	}
}

#endif