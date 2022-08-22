#include "pch.h"
#include "SnapShot.h"

void
C_OStream::write(const char c[/*n*/], int n)
{
    clearerr(_file);

    if (n != static_cast<int>(fwrite(c, 1, n, _file)))
        IEX_NAMESPACE::throwErrnoExc();
}


IMATH::Int64
C_OStream::tellp()
{
    return ftell(_file);
}


void
C_OStream::seekp(IMATH::Int64 pos)
{
    clearerr(_file);
    fseek(_file, (long)pos, SEEK_SET);
}


void
writeRgbaFILE(FILE* cfile,
    const char fileName[],
    const IMF::Rgba* pixels,
    int width,
    int height)
{
    //
    // Store an RGBA image in a C stdio file that has already been opened:
    //
    //	- create a C_OStream object for writing to the file
    //	- create an RgbaOutputFile object, and attach it to the C_OStream
    //	- describe the memory layout of the pixels
    //	- store the pixels in the file
    //

    C_OStream ostr(cfile, fileName);
    IMF::RgbaOutputFile file(ostr, IMF::Header(width, height), IMF::WRITE_RGBA);
    file.setFrameBuffer(pixels, 1, width);
    file.writePixels(height);

}

