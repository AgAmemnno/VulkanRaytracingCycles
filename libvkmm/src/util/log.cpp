#include "pch_mm.h"
#include "working_mm.h"

#include "log.hpp"
#include "global.hpp"



#ifdef AEOLUS
#include  "aeolus/incomplete.h"
#include <filesystem>
extern  bool LivePrintOff;

#include "aeolus/AllocatorVk.h"
extern front::DeallocatorVk des;
#endif
extern  bool FilePrintOn;

void testit(const  char* fmt, ...)
{

	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\x1b[0m\n");

}



#ifdef _WIN32
#define VC_EXTRALEAN
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#if     AEOLUS
#include "Python.h"
#endif
#endif


void log_init(void)
{

#ifdef _WIN32
	//	AllocConsole();
	//	AttachConsole(GetCurrentProcessId());
	//	freopen("CON", "w", stdout);
	//	freopen("CON", "w", stderr);

		// enable ANSI codes in windows console (conhost.exe)
		// http://www.nivot.org/blog/post/2016/02/04/Windows-10-TH2-(v1511)-Console-Host-Enhancements
	DWORD mode;
	HANDLE console = GetStdHandle(-11); // STD_OUTPUT_HANDLE
	GetConsoleMode(console, &mode);
	mode = mode | 4; // ENABLE_VIRTUAL_TERMINAL_PROCESSING
	SetConsoleMode(console, mode);
#endif
	sys_time_init();
	///log_info("Version     : %s", git_version);
}


void exitFatal()
{


	std::this_thread::sleep_for(std::chrono::milliseconds(1000));
#ifdef AEOLUS
	//des.~DeallocatorVk();
	//des.Holocaust();
	PyErr_SetString(PyExc_TypeError, "BAD");
	PyErr_NoMemory();
#else
	exit(-1);
#endif
	//

}



// https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
void log_out(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...)
{
	struct timespec tv;

	double now = (double)sys_time() / (double)sys_ticksecond;
	tv.tv_nsec = long(fmod(now, 1.0) * 1000000000.0f);
	tv.tv_sec = (uint64_t)now;

	printf("%s:%d %s %" PRIu64 ".%09ld  ", file, line,
		log_label(level),
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

		std::string path = std::string(LOG_THREAD_FILE) + "threadID" + std::to_string(_threadid) + ".log";
		std::filesystem::create_directories(LOG_THREAD_FILE); //add directories based on the object path (without this line it will not work)

		stream.open(path);
		if (!stream.is_open() || !stream.good())
		{
			log_bad("file failed to create   %s\n", path);
		}
		stream << "Open Log    " << path << "\n";

	}

	void write(const  char* file, int line, enum LOG_LEVEL level, const  char* message) {

		///printf("write   %s   %s  \n", file, message);
		AcquireSRWLockExclusive(&SrwLock);
		stream << file << "::" << line << "::" << log_label(level) << "    " << message;
		stream.flush();
		ReleaseSRWLockExclusive(&SrwLock);

	}
	void save(const  char* file, const  char* message) {

		///printf("write   %s   %s  \n", file, message);
		AcquireSRWLockExclusive(&SrwLock);

		std::string path = std::string(LOG_THREAD_FILE) + std::string(file) + ".save";
		std::filesystem::create_directories(LOG_THREAD_FILE); //add directories based on the object path (without this line it will not work)
		std::ofstream _stream;
		_stream.open(path);
		if (!_stream.is_open() || !_stream.good())
		{
			log_bad("file failed to create   %s\n", path);
		}
		_stream << message;
		_stream.flush();
		_stream.close();
		ReleaseSRWLockExclusive(&SrwLock);

	}
private:
	std::string _path;
};

static auto  syncFile = std::make_shared<SynchronizedFile>();

void log__save(const  char* file, const  char* fmt)
{
	syncFile->save(file, fmt);
}
void log__thread(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...)
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
void log__thread(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...)
{


	printf("%s:%d %s ", file, line, log_label(level));

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


inline std::wstring to_wchar(const char* text) {
	//const char* text_char = "example of mbstowcs";
	size_t length = strlen(text);
	std::wstring text_wchar(length, L'#');
	//#pragma warning (disable : 4996)
	// Or add to the preprocessor: _CRT_SECURE_NO_WARNINGS
	mbstowcs(&text_wchar[0], text, length);
	return  text_wchar;
};

void log__bad(const char* file, int line, enum LOG_LEVEL level, const char* fmt, ...)
{


	char message[512] = { 0 };

	va_list args;
	va_start(args, fmt);
	vsprintf_s(message, fmt, args);
	va_end(args);

	int on_button;
#ifdef UNICODE
	on_button = MessageBox(NULL, to_wchar((std::string(file) + ":" + std::to_string(line) + "  \n " + message).c_str()).c_str(),
#else
	on_button = MessageBox(NULL, (std::string(file) + ":" + std::to_string(line) + "  \n " + message).c_str(),
#endif
		TEXT("!Bad!"), MB_YESNO | MB_ICONQUESTION);

	if (on_button == IDYES)
		MessageBox(NULL, TEXT("Be Killed!"),
			TEXT("exit."), MB_OK);
	else MessageBox(NULL, TEXT("Be Killed!"),
		TEXT("exit."), MB_OK);

	exitFatal();


}

void log__vkabad(const  char* file, int line, enum LOG_LEVEL level, VkResult code, const  char* fmt, ...)
{


	printf("%s:%d %s  VkaCode::%s ", file, line, log_label(level), errorString(code));

	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\x1b[0m\n");

	exitFatal();
	//PyErr_BadArgument();
	//PyErr_SetString(PyExc_TypeError, "BAD");
	//throw ;

}

void log__once(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...)
{


	printf("%s:%d %s ", file, line, log_label(level));

	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);

	printf("\x1b[0m\n");

}


void log__vs(const  char* file, int line, enum LOG_LEVEL level, const  char* fmt, ...)
{


	char message[512] = { 0 };
	std::string mg = std::string(file) + "::" + std::to_string(line);


	va_list args;
	va_start(args, fmt);
	vsprintf_s(message, fmt, args);
	va_end(args);

	mg += std::string("     ") + message;

	OutputDebugString(mg.c_str());

}



const char* errorString(VkResult errorCode)
{
	switch (errorCode)
	{
#define STR(r) case VK_ ##r: return #r
		STR(NOT_READY);
		STR(TIMEOUT);
		STR(EVENT_SET);
		STR(EVENT_RESET);
		STR(INCOMPLETE);
		STR(ERROR_OUT_OF_HOST_MEMORY);
		STR(ERROR_OUT_OF_DEVICE_MEMORY);
		STR(ERROR_INITIALIZATION_FAILED);
		STR(ERROR_DEVICE_LOST);
		STR(ERROR_MEMORY_MAP_FAILED);
		STR(ERROR_LAYER_NOT_PRESENT);
		STR(ERROR_EXTENSION_NOT_PRESENT);
		STR(ERROR_FEATURE_NOT_PRESENT);
		STR(ERROR_INCOMPATIBLE_DRIVER);
		STR(ERROR_TOO_MANY_OBJECTS);
		STR(ERROR_FORMAT_NOT_SUPPORTED);
		STR(ERROR_SURFACE_LOST_KHR);
		STR(ERROR_NATIVE_WINDOW_IN_USE_KHR);
		STR(SUBOPTIMAL_KHR);
		STR(ERROR_OUT_OF_DATE_KHR);
		STR(ERROR_INCOMPATIBLE_DISPLAY_KHR);
		STR(ERROR_VALIDATION_FAILED_EXT);
		STR(ERROR_INVALID_SHADER_NV);
#undef STR
	default:
		return "UNKNOWN_ERROR_";
	}
}