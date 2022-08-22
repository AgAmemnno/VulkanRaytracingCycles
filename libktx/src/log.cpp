#include "pch.h"
#include "log.hpp"
#include <stdio.h>
#include <stdarg.h>


static const char* log_label(LOG_LEVEL level)
{
	switch (level) {
	case LOG_LEVEL::LOG_TRACE:
		return "\x1b[37m[TRACE]\x1b[0m";	// bright white
	case LOG_LEVEL::LOG_DEBUG:
		return "\x1b[36m[DEBUG]\x1b[0m";	// cyan
	case LOG_LEVEL::LOG_VERBOSE:
		return "\x1b[34m[VERBOSE]\x1b[0m";	// blue
	case LOG_LEVEL::LOG_INFO:
		return "\x1b[32m[INFO]\x1b[0m";		// green
	case LOG_LEVEL::LOG_WARNING:
		return "\x1b[33m[WARN]\x1b[0m";		// yellow
	case LOG_LEVEL::LOG_ERROR:
		return "\x1b[35m[ERROR]\x1b[0m";	// magenta
	case LOG_LEVEL::LOG_BAD:
		return "\x1b[41m[KTX::BAD]\x1b[0m";
	case LOG_LEVEL::LOG_ONCE:
		return "\x1b[42m[KTX::ONCE]\x1b[0m";
	case LOG_LEVEL::LOG_CPP:
		return "\x1b[43m[KTX::CPP]\x1b[0m";	// red
	case LOG_LEVEL::LOG_FATAL:
		return "\x1b[31m[KTX::FATAL]\x1b[0m";	// red
	default:
		return "\x1b[0m";		// reset
	}
}

void log__once(const char* file, int line,LOG_LEVEL level,const char* fmt, ...)
{

	printf("%s:%d %s ", file, line, log_label(level));
	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\x1b[0m\n");

}