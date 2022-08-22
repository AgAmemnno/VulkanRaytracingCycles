#pragma once
#include <stdio.h>
#include <stdarg.h>


enum class LOG_LEVEL {
	LOG_TRACE = 1,
	LOG_DEBUG = 2,
	LOG_VERBOSE = 4,
	LOG_INFO = 8,
	LOG_WARNING = 16,
	LOG_ERROR = 32,
	LOG_FATAL = 64,
	LOG_BAD = 128,
	LOG_ONCE = 256,
	LOG_CPP = 512,
};


/// DELETE ALL       ^((?!\w).)*log_once\(.*;     ^((?!\w).)*log_once\((.*\n)+?.*;
#define log_once(...) log__once(__FILE__, __LINE__, LOG_LEVEL::LOG_ONCE, __VA_ARGS__)

#define log_bad(...) log__once(__FILE__, __LINE__, LOG_LEVEL::LOG_BAD, __VA_ARGS__)

void log__once(const char* file, int line, LOG_LEVEL level,const char* fmt, ...);