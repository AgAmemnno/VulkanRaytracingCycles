#include "pch_three.h"
#include "Log0.hpp"
#include "global.hpp"
#include <filesystem>

#if defined(LIB_VTHREEPY)
#include  "aeolus/incomplete.h"
#include "aeolus/AllocatorVk.h"
extern front::DeallocatorVk des;
#endif


extern  bool LivePrintOff;
extern  bool FilePrintOn;




#ifdef _WIN32
#define VC_EXTRALEAN
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include "Python.h"
#endif


void Log_init(void)
{

#ifdef _WIN32
	//	AllocConsole();
	//	AttachConsole(GetCurrentProcessId());
	//	freopen("CON", "w", stdout);
	//	freopen("CON", "w", stderr);

		// enable ANSI codes in windows console (conhost.exe)
		// http://www.nivot.org/bLog/post/2016/02/04/Windows-10-TH2-(v1511)-Console-Host-Enhancements
	DWORD mode;
	HANDLE console = GetStdHandle(  DWORD(-11) ); // STD_OUTPUT_HANDLE
	GetConsoleMode(console, &mode);
	mode = mode | 4; // ENABLE_VIRTUAL_TERMINAL_PROCESSING
	SetConsoleMode(console, mode);
#endif
	sys_time_init();
	///Log_info("Version     : %s", git_version);
}


void ExitFatal()
{

#if defined(LIB_VTHREEPY)
	//des.~DeallocatorVk();
	des.Holocaust();
#endif

	std::this_thread::sleep_for(std::chrono::milliseconds(1000));

	PyErr_SetString(PyExc_TypeError, "BAD");

	return;
}

static const char* Log_label(enum Log_LEVEL level)
{
	switch (level) {
	case Log_TRACE:
		return "\x1b[37m[TRACE]\x1b[0m";	// bright white
	case Log_DEBUG:
		return "\x1b[36m[DEBUG]\x1b[0m";	// cyan
	case Log_VERBOSE:
		return "\x1b[34m[VERBOSE]\x1b[0m";	// blue
	case Log_INFO:
		return "\x1b[32m[INFO]\x1b[0m";		// green
	case Log_WARNING:
		return "\x1b[33m[WARN]\x1b[0m";		// yellow
	case Log_ERROR:
		return "\x1b[35m[ERROR]\x1b[0m";	// magenta
	case Log_BAD:
		return "\x1b[41m\x1b[1m[BAD]\x1b[0m";	
	case Log_VKABAD:
		return "\x1b[33m\x1b[1m[VKABAD]\x1b[0m";
	case Log_ONCE:
		return "\x1b[42m[ONCE]\x1b[0m";
	case Log_THREAD:
		return "\x1b[32m\x1b[1m[THREAD]\x1b[0m";
	case Log_FILE:
		return "[FILE]";
	case Log_CPP:
		return "\x1b[43m[CPP]\x1b[0m";	// red
	case Log_FATAL:
		return "\x1b[31m[FATAL]\x1b[0m";	// red
	default:
		return "\x1b[0m";		// reset
	}
}

// https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
void Log_out(const char* file, int line, enum Log_LEVEL level, const char* fmt, ...)
{
	struct timespec tv;

	double now = (double)sys_time() / (double)sys_ticksecond;
	tv.tv_nsec = long(fmod(now, 1.0) * 1000000000.0f);
	tv.tv_sec = (uint64_t)now;

	printf("%s:%d %s %" PRIu64 ".%09ld  ", file, line,
		Log_label(level),
		(uint64_t)tv.tv_sec, tv.tv_nsec);

	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\x1b[0m\n");

}
#ifdef AEOLUS
class SynchronizedFile {

	SRWLOCK  SrwLock;
	std::ofstream stream;
public:
	SynchronizedFile() {

		InitializeSRWLock(&SrwLock);

		std::string path = std::string(Log_THREAD_FILE) + "threadID" + std::to_string(_threadid) + ".Log";
		std::filesystem::create_directories(Log_THREAD_FILE); //add directories based on the object path (without this line it will not work)

		stream.open(path);
		if (!stream.is_open() || !stream.good())
		{
			Log_bad("file failed to create   %s\n", path.c_str());
		}
		stream << "Open Log    " << path <<"\n";

	}

	void write(char* file, int line, enum Log_LEVEL level, char* message) {

		///printf("write   %s   %s  \n", file, message);
		AcquireSRWLockExclusive(&SrwLock);
		stream << file << "::" << line << "::" << Log_label(level) << "    " << message;
		stream.flush();
		ReleaseSRWLockExclusive(&SrwLock);

	}

private:
	std::string _path;
};

static auto  syncFile = std::make_shared<SynchronizedFile>();


void Log__thread(char* file, int line, enum Log_LEVEL level, char* fmt, ...)
{

#ifdef AEOLUS
	if (!LivePrintOff) {
#endif
		char message[512] = { 0 };
		va_list args;
		va_start(args, fmt);
		vsprintf_s(message, fmt, args);
		va_end(args);
		syncFile->write(file, line, level, message);

#ifdef AEOLUS
	}
#endif
}
#else
void Log__thread(char* file, int line, enum Log_LEVEL level, char* fmt, ...)
{


	printf("%s:%d %s ", file, line, Log_label(level));

	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\x1b[0m\n");

#ifdef AEOLUS
}
#endif
}

#endif



void Log__bad(const char* file, int line, enum Log_LEVEL level, const  char* fmt, ...)
{

#ifdef AEOLUS
	if (FilePrintOn) {
		char message[512] = { 0 };
		va_list args;
		va_start(args, fmt);
		vsprintf_s(message, fmt, args);
		va_end(args);
		syncFile->write((char*)file, line, level, message);
	}
	else {
#endif
		printf("%s:%d %s ", file, line, Log_label(level));

		va_list args;
		va_start(args, fmt);
		vprintf(fmt, args);
		va_end(args);

		printf("\x1b[0m\n");
#ifdef AEOLUS
	}
#endif
	ExitFatal();
	//PyErr_BadArgument();
	//PyErr_SetString(PyExc_TypeError, "BAD");
	//throw ;

}

void Log__once(const char* file, int line, enum Log_LEVEL level, const char* fmt, ...)
{
	

	printf("%s:%d %s ",file, line,Log_label(level));

	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\x1b[0m\n");

}



