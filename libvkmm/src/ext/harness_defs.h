#pragma once
/*
    Copyright (c) 2005-2020 Intel Corporation

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#ifndef __TBB_harness_defs_H
#define __TBB_harness_defs_H

#include "tbb/tbb_config.h"
#if __FreeBSD__
#include <sys/param.h>  // for __FreeBSD_version
#endif

#if __TBB_TEST_PIC && !__PIC__
#define __TBB_TEST_SKIP_PIC_MODE 1
#else
#define __TBB_TEST_SKIP_PIC_MODE 0
#endif

// no need to test GCC builtins mode on ICC
#define __TBB_TEST_SKIP_GCC_BUILTINS_MODE ( __TBB_TEST_BUILTINS && (!__TBB_GCC_BUILTIN_ATOMICS_PRESENT || __INTEL_COMPILER) )

#define __TBB_TEST_SKIP_ICC_BUILTINS_MODE ( __TBB_TEST_BUILTINS && !__TBB_ICC_BUILTIN_ATOMICS_PRESENT )

#ifndef TBB_USE_GCC_BUILTINS
  // Force TBB to use GCC intrinsics port, but not on ICC, as no need
#define TBB_USE_GCC_BUILTINS         ( __TBB_TEST_BUILTINS && __TBB_GCC_BUILTIN_ATOMICS_PRESENT && !__INTEL_COMPILER )
#endif

#ifndef TBB_USE_ICC_BUILTINS
  // Force TBB to use ICC c++11 style intrinsics port
#define TBB_USE_ICC_BUILTINS         ( __TBB_TEST_BUILTINS && __TBB_ICC_BUILTIN_ATOMICS_PRESENT )
#endif

#if (_WIN32 && !__TBB_WIN8UI_SUPPORT) || (__linux__ && !__ANDROID__ && !__bg__) || __FreeBSD_version >= 701000
#define __TBB_TEST_SKIP_AFFINITY 0
#else
#define __TBB_TEST_SKIP_AFFINITY 1
#endif

#if __INTEL_COMPILER
#define __TBB_CPP11_REFERENCE_WRAPPER_PRESENT ( __INTEL_CXX11_MODE__ && __INTEL_COMPILER >= 1200 && \
    ( _MSC_VER >= 1600 || __TBB_GLIBCXX_VERSION >= 40400 || ( _LIBCPP_VERSION && __cplusplus >= 201103L ) ) )
#define __TBB_RANGE_BASED_FOR_PRESENT ( __INTEL_CXX11_MODE__ && __INTEL_COMPILER >= 1300 )
#define __TBB_SCOPED_ENUM_PRESENT ( __INTEL_CXX11_MODE__ && __INTEL_COMPILER > 1100 )
#elif __clang__
#define __TBB_CPP11_REFERENCE_WRAPPER_PRESENT ( __cplusplus >= 201103L && (__TBB_GLIBCXX_VERSION >= 40400 || _LIBCPP_VERSION) )
#define __TBB_RANGE_BASED_FOR_PRESENT ( __has_feature(__cxx_range_for) )
#define __TBB_SCOPED_ENUM_PRESENT ( __has_feature(cxx_strong_enums) )
#elif __GNUC__
#define __TBB_CPP11_REFERENCE_WRAPPER_PRESENT ( __GXX_EXPERIMENTAL_CXX0X__ && __TBB_GCC_VERSION >= 40400 )
#define __TBB_RANGE_BASED_FOR_PRESENT ( __GXX_EXPERIMENTAL_CXX0X__ && __TBB_GCC_VERSION >= 40500 )
#define __TBB_SCOPED_ENUM_PRESENT ( __GXX_EXPERIMENTAL_CXX0X__ && __TBB_GCC_VERSION >= 40400 )
#define __TBB_GCC_WARNING_IGNORED_ATTRIBUTES_PRESENT (__TBB_GCC_VERSION >= 60100)
#elif _MSC_VER
#define __TBB_CPP11_REFERENCE_WRAPPER_PRESENT ( _MSC_VER >= 1600 )
#define __TBB_RANGE_BASED_FOR_PRESENT ( _MSC_VER >= 1700 )
#define __TBB_SCOPED_ENUM_PRESENT ( _MSC_VER >= 1700 )
#endif

#define __TBB_CPP14_GENERIC_LAMBDAS_PRESENT  (__cpp_generic_lambdas >= 201304 )

#define __TBB_TEST_SKIP_LAMBDA (__TBB_ICC_13_0_CPP11_STDLIB_SUPPORT_BROKEN || !__TBB_CPP11_LAMBDAS_PRESENT)

#if __GNUC__ && __ANDROID__
// On Android* OS, GCC does not support _thread keyword
#define __TBB_THREAD_LOCAL_VARIABLES_PRESENT 0
#else
#define __TBB_THREAD_LOCAL_VARIABLES_PRESENT 1
#endif

// ICC has a bug in assumptions of the modifications made via atomic pointer
#define __TBB_ICC_BUILTIN_ATOMICS_POINTER_ALIASING_BROKEN (TBB_USE_ICC_BUILTINS &&  __INTEL_COMPILER < 1400 && __INTEL_COMPILER > 1200)

// clang on Android/IA-32 fails on exception thrown from static move constructor
#define __TBB_CPP11_EXCEPTION_IN_STATIC_TEST_BROKEN (__ANDROID__ && __SIZEOF_POINTER__==4 && __clang__)

// MSVC 2013 is unable to properly resolve call to overloaded operator= with std::initializer_list argument for std::pair list elements
// clang on Android/IA-32 fails on "std::vector<std::pair<int,int>> vd{{1,1},{1,1},{1,1}};" line in release mode
#define __TBB_CPP11_INIT_LIST_TEST_BROKEN (_MSC_VER <= 1800 && _MSC_VER && !__INTEL_COMPILER) || (__ANDROID__ && __TBB_x86_32 && __clang__)
// MSVC 2013 is unable to manage lifetime of temporary objects passed to a std::initializer_list constructor properly
#define __TBB_CPP11_INIT_LIST_TEMP_OBJS_LIFETIME_BROKEN (_MSC_FULL_VER < 180030501 && _MSC_VER && !__INTEL_COMPILER)

// Implementation of C++11 std::placeholders in libstdc++ coming with GCC prior to 4.5 reveals bug in Intel(R) C++ Compiler 13 causing "multiple definition" link errors.
#define __TBB_CPP11_STD_PLACEHOLDERS_LINKAGE_BROKEN ((__INTEL_COMPILER == 1300 || __INTEL_COMPILER == 1310) && __GXX_EXPERIMENTAL_CXX0X__ && __GLIBCXX__ && __TBB_GLIBCXX_VERSION < 40500)

// Intel C++ Compiler has an issue when a scoped enum with a specified underlying type has negative values.
#define __TBB_ICC_SCOPED_ENUM_WITH_UNDERLYING_TYPE_NEGATIVE_VALUE_BROKEN ( _MSC_VER && !__TBB_DEBUG && __INTEL_COMPILER && __INTEL_COMPILER <= 1500 )
// Intel C++ Compiler has an issue with __atomic_load_explicit from a scoped enum with a specified underlying type.
#define __TBB_ICC_SCOPED_ENUM_WITH_UNDERLYING_TYPE_ATOMIC_LOAD_BROKEN ( TBB_USE_ICC_BUILTINS && !__TBB_DEBUG && __INTEL_COMPILER && __INTEL_COMPILER <= 1500 )

// Unable to use constexpr member functions to initialize compile time constants
#define __TBB_CONSTEXPR_MEMBER_FUNCTION_BROKEN (__INTEL_COMPILER == 1500)
// Some versions of MSVC do not do compile-time initialization of static variables with constexpr constructors in debug mode
#define __TBB_STATIC_CONSTEXPR_INIT_BROKEN (_MSC_VER >= 1900 && _MSC_VER <= 1914 && !__INTEL_COMPILER && _DEBUG)

#if __GNUC__ && __ANDROID__
#define __TBB_EXCEPTION_TYPE_INFO_BROKEN ( __TBB_GCC_VERSION < 40600 )
#elif _MSC_VER
#define __TBB_EXCEPTION_TYPE_INFO_BROKEN ( _MSC_VER < 1400 )
#else
#define __TBB_EXCEPTION_TYPE_INFO_BROKEN 0
#endif

// a function ptr cannot be converted to const T& template argument without explicit cast
#define __TBB_FUNC_PTR_AS_TEMPL_PARAM_BROKEN ( ((__linux__ || __APPLE__) && __INTEL_COMPILER && __INTEL_COMPILER < 1100) || __SUNPRO_CC )

#define __TBB_UNQUALIFIED_CALL_OF_DTOR_BROKEN (__GNUC__==3 && __GNUC_MINOR__<=3)

#define __TBB_CAS_8_CODEGEN_BROKEN (__TBB_x86_32 && __PIC__ && __TBB_GCC_VERSION == 40102 && !__INTEL_COMPILER)

#define __TBB_THROW_FROM_DTOR_BROKEN (__clang__ && __apple_build_version__ && __apple_build_version__ < 5000279)

// std::uncaught_exception is broken on some version of stdlibc++ (it returns true with no active exception)
#define __TBB_STD_UNCAUGHT_EXCEPTION_BROKEN (__TBB_GLIBCXX_VERSION == 40407)

#if __TBB_LIBSTDCPP_EXCEPTION_HEADERS_BROKEN
#define _EXCEPTION_PTR_H /* prevents exception_ptr.h inclusion */
#define _GLIBCXX_NESTED_EXCEPTION_H /* prevents nested_exception.h inclusion */
#endif

// TODO: Investigate the cases that require this macro.
#define __TBB_COMPLICATED_ADL_BROKEN ( __GNUC__ && __TBB_GCC_VERSION < 40400 )

// Intel C++ Compiler fails to compile the comparison of tuples in some cases
#if __INTEL_COMPILER && __INTEL_COMPILER < 1700
#define __TBB_TUPLE_COMPARISON_COMPILATION_BROKEN (__TBB_GLIBCXX_VERSION >= 40800 || __MIC__)
#endif

// Intel C++ Compiler fails to compile std::reference in some cases
#if __INTEL_COMPILER && __INTEL_COMPILER < 1600 || __INTEL_COMPILER == 1600 && __INTEL_COMPILER_UPDATE <= 1
#define __TBB_REFERENCE_WRAPPER_COMPILATION_BROKEN (__TBB_GLIBCXX_VERSION >= 40800 && __TBB_GLIBCXX_VERSION <= 50101 || __MIC__)
#endif

// Intel C++ Compiler fails to generate non-throwing move members for a class inherited from template
#define __TBB_NOTHROW_MOVE_MEMBERS_IMPLICIT_GENERATION_BROKEN \
    (__INTEL_COMPILER>=1600 && __INTEL_COMPILER<=1900 || __INTEL_COMPILER==1500 && __INTEL_COMPILER_UPDATE>3)

// std::is_copy_constructible<T>::value returns 'true' for non copyable type when MSVC compiler is used.
#define __TBB_IS_COPY_CONSTRUCTIBLE_BROKEN ( _MSC_VER && (_MSC_VER <= 1700 || _MSC_VER <= 1800 && !__INTEL_COMPILER) )

// GCC 4.7 and 4.8 might fail to take an address of overloaded template function (bug 57043)
#if __GNUC__ && !__INTEL_COMPILER && !__clang__
#define __TBB_GCC_OVERLOADED_TEMPLATE_FUNCTION_ADDRESS_BROKEN \
    (__TBB_GCC_VERSION>=40700 && __TBB_GCC_VERSION<40704 || __TBB_GCC_VERSION>=40800 && __TBB_GCC_VERSION<40803 )
#endif

// Swapping of scoped_allocator_adaptors is broken on GCC 4.9 and lower and on Android for Windows
// Allocator propagation into std::pair is broken for Apple clang, lower then 9.0
// Compilation of <scoped_allocator> header is broken for Visual Studio 2017 with ICC 17.8
#define __TBB_SCOPED_ALLOCATOR_BROKEN (__TBB_GCC_VERSION <= 50100 || (__APPLE__ && __TBB_CLANG_VERSION < 90000) || \
                                      (__FreeBSD__ && __TBB_CLANG_VERSION <= 60000) ||  \
                                      (__ANDROID__ && (_WIN32 || _WIN64)) || \
                                      (_MSC_VER && _MSC_VER == 1912 && __INTEL_COMPILER == 1700))



// The tuple-based tests with more inputs take a long time to compile.  If changes
// are made to the tuple implementation or any switch that controls it, or if testing
// with a new platform implementation of std::tuple, the test should be compiled with
// MAX_TUPLE_TEST_SIZE >= 10 (or the largest number of elements supported) to ensure
// all tuple sizes are tested.  Expect a very long compile time.
#ifndef MAX_TUPLE_TEST_SIZE
#if TBB_USE_DEBUG
#define MAX_TUPLE_TEST_SIZE 3
#else
#define MAX_TUPLE_TEST_SIZE 5
#endif
#else
#if _MSC_VER
// test sizes <= 8 don't get "decorated name length exceeded" errors. (disable : 4503)
#if MAX_TUPLE_TEST_SIZE > 8
#undef MAX_TUPLE_TEST_SIZE
#define MAX_TUPLE_TEST_SIZE 8
#endif
#endif
#if MAX_TUPLE_TEST_SIZE > __TBB_VARIADIC_MAX
#undef MAX_TUPLE_TEST_SIZE
#define MAX_TUPLE_TEST_SIZE __TBB_VARIADIC_MAX
#endif
#endif

#if __TBB_CPF_BUILD
#ifndef  TBB_PREVIEW_FLOW_GRAPH_FEATURES
#define TBB_PREVIEW_FLOW_GRAPH_FEATURES 1
#endif
#ifndef TBB_PREVIEW_FLOW_GRAPH_TRACE
#define TBB_PREVIEW_FLOW_GRAPH_TRACE 1
#endif
#ifndef TBB_PREVIEW_ALGORITHM_TRACE
#define TBB_PREVIEW_ALGORITHM_TRACE 1
#endif
#ifndef TBB_DEPRECATED_LIMITER_NODE_CONSTRUCTOR
#define TBB_DEPRECATED_LIMITER_NODE_CONSTRUCTOR 1
#endif
#endif



#ifndef harness_assert_H
#define harness_assert_H

/*
void ReportError(const char* filename, int line, const char* expression, const char* message);
void ReportWarning(const char* filename, int line, const char* expression, const char* message);

#define ASSERT_CUSTOM(p,message,file,line)  ((p)?(void)0:ReportError(file,line,#p,message))
#define ASSERT(p,message)                   ASSERT_CUSTOM(p,message,__FILE__,__LINE__)
#define ASSERT_WARNING(p,message)           ((p)?(void)0:ReportWarning(__FILE__,__LINE__,#p,message))
*/

#define ASSERT_CUSTOM(p,message,file,line)  
#define ASSERT(p,message)                
#define ASSERT_WARNING(p,message)

//! Compile-time error if x and y have different types
template<typename T>
void AssertSameType(const T& /*x*/, const T& /*y*/) {}

#endif 


/*
    Copyright (c) 2005-2020 Intel Corporation

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

// Just the tracing portion of the harness.
//
// This header defines TRACE and TRACENL macros, which use REPORT like syntax and
// are useful for duplicating trace output to the standard debug output on Windows.
// It is possible to add the ability of automatic extending messages with additional
// info (file, line, function, time, thread ID, ...).
//
// Macros output nothing when test app runs in non-verbose mode (default).
//

#ifndef tbb_tests_harness_report_H
#define tbb_tests_harness_report_H

#if defined(MAX_TRACE_SIZE) && MAX_TRACE_SIZE < 1024
#undef MAX_TRACE_SIZE
#endif
#ifndef MAX_TRACE_SIZE
#define MAX_TRACE_SIZE  1024
#endif

#if __SUNPRO_CC
#include <stdio.h>
#else
#include <cstdio>
#endif

#include <cstdarg>

// Need to include "tbb/tbb_config.h" to obtain the definition of __TBB_DEFINE_MIC.
#include "tbb/tbb_config.h"

#if __TBB_DEFINE_MIC
#include "harness_mic.h"
#endif

#ifdef HARNESS_INCOMPLETE_SOURCES
#error Source files are not complete. Check the build environment
#endif

#if _MSC_VER
#define snprintf _snprintf
#if _MSC_VER<=1400
#define vsnprintf _vsnprintf
#endif
#endif

namespace Harness {
    namespace internal {

#ifndef TbbHarnessReporter
        struct TbbHarnessReporter {
            void Report(const char* msg) {
                printf("%s", msg);
                fflush(stdout);
#ifdef _WINDOWS_
                OutputDebugStringA(msg);
#endif
            }
        }; // struct TbbHarnessReporter
#endif /* !TbbHarnessReporter */

        class Tracer {
            int         m_flags;
            const char* m_file;
            const char* m_func;
            size_t      m_line;

            TbbHarnessReporter m_reporter;

        public:
            enum {
                prefix = 1,
                need_lf = 2
            };

            Tracer() : m_flags(0), m_file(NULL), m_func(NULL), m_line(0) {}

            Tracer* set_trace_info(int flags, const char* file, size_t line, const char* func) {
                m_flags = flags;
                m_line = line;
                m_file = file;
                m_func = func;
                return  this;
            }

            void  trace(const char* fmt, ...) {
                char    msg[MAX_TRACE_SIZE];
                char    msg_fmt_buf[MAX_TRACE_SIZE];
                const char* msg_fmt = fmt;
                if (m_flags & prefix) {
                    snprintf(msg_fmt_buf, MAX_TRACE_SIZE, "[%s] %s", m_func, fmt);
                    msg_fmt = msg_fmt_buf;
                }
                std::va_list argptr;
                va_start(argptr, fmt);
                int len = vsnprintf(msg, MAX_TRACE_SIZE, msg_fmt, argptr);
                va_end(argptr);
                if (m_flags & need_lf &&
                    len < MAX_TRACE_SIZE - 1 && msg_fmt[len - 1] != '\n')
                {
                    msg[len] = '\n';
                    msg[len + 1] = 0;
                }
                m_reporter.Report(msg);
            }
        }; // class Tracer

        static Tracer tracer;

        template<int>
        bool not_the_first_call() {
            static bool first_call = false;
            bool res = first_call;
            first_call = true;
            return res;
        }

    } // namespace internal
} // namespace Harness

#if defined(_MSC_VER)  &&  _MSC_VER >= 1300  ||  defined(__GNUC__)  ||  defined(__GNUG__)
#define HARNESS_TRACE_ORIG_INFO __FILE__, __LINE__, __FUNCTION__
#else
#define HARNESS_TRACE_ORIG_INFO __FILE__, __LINE__, ""
#define __FUNCTION__ ""
#endif


//! printf style tracing macro
/** This variant of TRACE adds trailing line-feed (new line) character, if it is absent. **/
#define TRACE Harness::internal::tracer.set_trace_info(Harness::internal::Tracer::need_lf, HARNESS_TRACE_ORIG_INFO)->trace

//! printf style tracing macro without automatic new line character adding
#define TRACENL Harness::internal::tracer.set_trace_info(0, HARNESS_TRACE_ORIG_INFO)->trace

//! printf style tracing macro with additional information prefix (e.g. current function name)
#define TRACEP Harness::internal::tracer.set_trace_info(Harness::internal::Tracer::prefix | \
                                    Harness::internal::Tracer::need_lf, HARNESS_TRACE_ORIG_INFO)->trace

//! printf style remark macro
/** Produces output only when the test is run with the -v (verbose) option. **/
#define REMARK  !Verbose ? (void)0 : TRACENL

//! printf style remark macro
/** Produces output only when invoked first time.
    Only one instance of this macro is allowed per source code line. **/
#define REMARK_ONCE (!Verbose || Harness::internal::not_the_first_call<__LINE__>()) ? (void)0 : TRACE

    //! printf style reporting macro
    /** On heterogeneous platforms redirects its output to the host side. **/
#define REPORT TRACENL

//! printf style reporting macro
/** Produces output only when invoked first time.
    Only one instance of this macro is allowed per source code line. **/
#define REPORT_ONCE (Harness::internal::not_the_first_call<__LINE__>()) ? (void)0 : TRACENL

#endif /* tbb_tests_harness_report_H */

#define HARNESS_NO_ASSERT 1
namespace Harness {
    //! Utility template function to prevent "unused" warnings by various compilers.
    template<typename T> void suppress_unused_warning(const T&) {}

    //TODO: unify with one in tbb::internal
    //! Utility helper structure to ease overload resolution
    template<int > struct int_to_type {};
}

const unsigned MByte = 1024 * 1024;




#if !HARNESS_NO_ASSERT
#include <exception> //for set_terminate

#if TEST_USES_TBB
#include <tbb/tbb_stddef.h> /*set_assertion_handler*/
#endif

struct InitReporter {
    void (*default_terminate_handler)();
    InitReporter() : default_terminate_handler(NULL) {
#if TEST_USES_TBB
#if TBB_USE_ASSERT
        tbb::set_assertion_handler(ReportError);
#endif
        ASSERT_WARNING(TBB_INTERFACE_VERSION <= tbb::TBB_runtime_interface_version(), "runtime version mismatch");
#endif
#if TBB_USE_EXCEPTIONS
        default_terminate_handler = std::set_terminate(handle_terminate);
#endif
    }
    static void handle_terminate();
};
static InitReporter InitReportError;

void InitReporter::handle_terminate() {
    REPORT("std::terminate called.\n");
    print_call_stack();
    if (InitReportError.default_terminate_handler) {
        InitReportError.default_terminate_handler();
    }
}

typedef void (*test_error_extra_t)(void);
static test_error_extra_t ErrorExtraCall;
//! Set additional handler to process failed assertions
void SetHarnessErrorProcessing(test_error_extra_t extra_call) {
    ErrorExtraCall = extra_call;
}

//! Reports errors issued by failed assertions
void ReportError(const char* filename, int line, const char* expression, const char* message) {
    print_call_stack();
#if __TBB_ICL_11_1_CODE_GEN_BROKEN
    printf("%s:%d, assertion %s: %s\n", filename, line, expression, message ? message : "failed");
#else
    REPORT_FATAL_ERROR("%s:%d, assertion %s: %s\n", filename, line, expression, message ? message : "failed");
#endif

    if (ErrorExtraCall)
        (*ErrorExtraCall)();
    fflush(stdout); fflush(stderr);
#if HARNESS_TERMINATE_ON_ASSERT
    TerminateProcess(GetCurrentProcess(), 1);
#elif HARNESS_EXIT_ON_ASSERT
    exit(1);
#elif HARNESS_CONTINUE_ON_ASSERT
    // continue testing
#elif _MSC_VER && _DEBUG
    // aligned with tbb_assert_impl.h behavior
    if (1 == _CrtDbgReport(_CRT_ASSERT, filename, line, NULL, "%s\r\n%s", expression, message ? message : ""))
        _CrtDbgBreak();
#else
    abort();
#endif /* HARNESS_EXIT_ON_ASSERT */
}
//! Reports warnings issued by failed warning assertions
void ReportWarning(const char* filename, int line, const char* expression, const char* message) {
    REPORT("Warning: %s:%d, assertion %s: %s\n", filename, line, expression, message ? message : "failed");
}

#else /* !HARNESS_NO_ASSERT */
#ifndef  ASSERT
#define ASSERT(p,msg) (Harness::suppress_unused_warning(p), (void)0)
#define ASSERT_WARNING(p,msg) (Harness::suppress_unused_warning(p), (void)0)
#endif
#endif /* !HARNESS_NO_ASSERT */
//! Base class for types that should not be assigned.
class NoAssign {
public:
    void operator=(const NoAssign&) = delete;
    NoAssign(const NoAssign&) = default;
    NoAssign() = default;
};

//! Base class for types that should not be copied or assigned.
class NoCopy : NoAssign {
public:
    NoCopy(const NoCopy&) = delete;
    NoCopy() = default;
};


//! For internal use by template function NativeParallelFor
template<typename Index, typename Body>
class NativeParallelForTask : NoCopy {
public:
    NativeParallelForTask(Index index_, const Body& body_) :
        index(index_),
        body(body_)
    {}

    //! Start task
    void start() {
#if _WIN32||_WIN64
        unsigned thread_id;
#if __TBB_WIN8UI_SUPPORT
        std::thread* thread_tmp = new std::thread(thread_function, this);
        thread_handle = thread_tmp->native_handle();
        thread_id = 0;
#else
        unsigned stack_size = 0;
#if HARNESS_THREAD_STACK_SIZE
        stack_size = HARNESS_THREAD_STACK_SIZE;
#endif
        thread_handle = (HANDLE)_beginthreadex(NULL, stack_size, thread_function, this, 0, &thread_id);
#endif
        ASSERT(thread_handle != 0, "NativeParallelFor: _beginthreadex failed");
#else
#if __ICC==1100
#pragma warning (push)
#pragma warning (disable: 2193)
#endif /* __ICC==1100 */
        // Some machines may have very large hard stack limit. When the test is
        // launched by make, the default stack size is set to the hard limit, and
        // calls to pthread_create fail with out-of-memory error.
        // Therefore we set the stack size explicitly (as for TBB worker threads).
#if !defined(HARNESS_THREAD_STACK_SIZE)
#if __i386__||__i386||__arm__
        const size_t stack_size = 1 * MByte;
#elif __x86_64__
        const size_t stack_size = 2 * MByte;
#else
        const size_t stack_size = 4 * MByte;
#endif
#else
        const size_t stack_size = HARNESS_THREAD_STACK_SIZE;
#endif /* HARNESS_THREAD_STACK_SIZE */
        pthread_attr_t attr_stack;
        int status = pthread_attr_init(&attr_stack);
        ASSERT(0 == status, "NativeParallelFor: pthread_attr_init failed");
        status = pthread_attr_setstacksize(&attr_stack, stack_size);
        ASSERT(0 == status, "NativeParallelFor: pthread_attr_setstacksize failed");
        status = pthread_create(&thread_id, &attr_stack, thread_function, this);
        ASSERT(0 == status, "NativeParallelFor: pthread_create failed");
        pthread_attr_destroy(&attr_stack);
#if __ICC==1100
#pragma warning (pop)
#endif
#endif /* _WIN32||_WIN64 */
    }

    //! Wait for task to finish
    void wait_to_finish() {
#if _WIN32||_WIN64
        DWORD status = WaitForSingleObjectEx(thread_handle, INFINITE, FALSE);
        ASSERT(status != WAIT_FAILED, "WaitForSingleObject failed");
        CloseHandle(thread_handle);
#else
        int status = pthread_join(thread_id, NULL);
        ASSERT(!status, "pthread_join failed");
#endif
#if HARNESS_NO_ASSERT
        (void)status;
#endif
    }

private:
#if _WIN32||_WIN64
    HANDLE thread_handle;
#else
    pthread_t thread_id;
#endif

    //! Range over which task will invoke the body.
    const Index index;

    //! Body to invoke over the range.
    const Body body;

#if _WIN32||_WIN64
    static unsigned __stdcall thread_function(void* object)
#else
    static void* thread_function(void* object)
#endif
    {
        NativeParallelForTask& self = *static_cast<NativeParallelForTask*>(object);
        (self.body)(self.index);
#if HARNESS_TBBMALLOC_THREAD_SHUTDOWN && __TBB_SOURCE_DIRECTLY_INCLUDED && (_WIN32||_WIN64)
        // in those cases can't release per-thread cache automatically,
        // so do it manually
        // TODO: investigate less-intrusive way to do it, for example via FLS keys
        __TBB_mallocThreadShutdownNotification();
#endif
        return 0;
    }
};

template<typename Index, typename Body>
void NativeParallelFor(Index n, const Body& body) {
    typedef NativeParallelForTask<Index, Body> task;

    if (n > 0) {
        // Allocate array to hold the tasks
        task* array = static_cast<task*>(operator new(n * sizeof(task)));

        // Construct the tasks
        for (Index i = 0; i != n; ++i)
            new(&array[i]) task(i, body);

        // Start the tasks
        for (Index i = 0; i != n; ++i)
            array[i].start();

        // Wait for the tasks to finish and destroy each one.
        for (Index i = n; i; --i) {
            array[i - 1].wait_to_finish();
            array[i - 1].~task();
        }

        // Deallocate the task array
        operator delete(array);
    }
}

#endif /* __TBB_harness_defs_H */
