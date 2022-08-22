#pragma once

#ifndef SNAPSHOT_VK_H_
#define SNAPSHOT_VK_H_
#undef OPENEXR_DLL
#ifdef _DEBUG


#pragma comment(lib, "Half-2_5_d.lib")
#pragma comment(lib, "Iex-2_5_d.lib")
#pragma comment(lib, "IexMath-2_5_d.lib")
#pragma comment(lib, "IlmImf-2_5_d.lib")
#pragma comment(lib, "IlmImfUtil-2_5_d.lib")
#pragma comment(lib, "IlmThread-2_5_d.lib")
#pragma comment(lib, "Imath-2_5_d.lib")


#else 

#pragma comment(lib, "Half-2_5.lib")
#pragma comment(lib, "lex-2_5.lib")
#pragma comment(lib, "lexMath-2_5.lib")
#pragma comment(lib, "IlmImf-2_5.lib")
#pragma comment(lib, "IlmImfUtil-2_5.lib")
#pragma comment(lib, "IlmThread-2_5.lib")
#pragma comment(lib, "Imath-2_5.lib")

#endif

#include <ImfRgbaFile.h>
#include <ImfIO.h>
#include "Iex.h"

#ifndef NAMESPACEALIAS_H_
#define NAMESPACEALIAS_H_

#include <ImfNamespace.h>

namespace IMF = OPENEXR_IMF_NAMESPACE;
namespace IMATH = IMATH_NAMESPACE;
#endif /* NAMESPACEALIAS_H_ */

class C_OStream : public IMF::OStream
{
public:

    C_OStream(FILE* file, const char fileName[]) :
        IMF::OStream(fileName), _file(file) {}

    virtual void	write(const char c[/*n*/], int n);
    virtual IMATH::Int64	tellp();
    virtual void	seekp(IMATH::Int64 pos);

private:

    FILE* _file;
};

void
writeRgbaFILE(FILE* cfile,
    const char fileName[],
    const IMF::Rgba* pixels,
    int width,
    int height);

#endif