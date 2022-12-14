#extension GL_EXT_shader_explicit_arithmetic_types_float16 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_float32 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_float64 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int8 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int16 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int32 : enable
#extension GL_EXT_shader_explicit_arithmetic_types_int64 : enable

precision highp float;

void math_test()
{
     
   {
    float16_t a1 = float16_t(0x1);
    float16_t a2 = float16_t(float32_t(0x2));
    float16_t a3 = float16_t(float64_t(0x3));
    float16_t a4 = float16_t(int8_t   (0x4));
    float16_t a5 = float16_t(int16_t  (0x5));
    float16_t a6 = float16_t(int32_t  (0x6));
    float16_t a7 = float16_t(int64_t  (0x7));
    float16_t a8 = float16_t(uint8_t  (0x8));
    float16_t a9 = float16_t(uint16_t (0x9));
    float16_t a10 = float16_t(uint32_t (0xA));
    float16_t a11 = float16_t(uint64_t (0xB));
    float16_t a12 = float16_t(bool     (0xC));


   }
    float32_t(float16_t(0x11));
    float32_t(float32_t(0x12));
    float32_t(float64_t(0x13));
    float32_t(int8_t   (0x14));
    float32_t(int16_t  (0x15));
    float32_t(int32_t  (0x16));
    float32_t(int64_t  (0x17));
    float32_t(uint8_t  (0x18));
    float32_t(uint16_t (0x19));
    float32_t(uint32_t (0x1A));
    float32_t(uint64_t (0x1B));
    float32_t(bool     (0x1C));
    float64_t(float16_t(0x21));
    float64_t(float32_t(0x22));
    float64_t(float64_t(0x23));
    float64_t(int8_t   (0x24));
    float64_t(int16_t  (0x25));
    float64_t(int32_t  (0x26));
    float64_t(int64_t  (0x27));
    float64_t(uint8_t  (0x28));
    float64_t(uint16_t (0x29));
    float64_t(uint32_t (0x2A));
    float64_t(uint64_t (0x2B));
    float64_t(bool     (0x2C));
    int8_t(float16_t(0x31));
    int8_t(float32_t(0x32));
    int8_t(float64_t(0x33));
    int8_t(int8_t   (0x34));
    int8_t(int16_t  (0x35));
    int8_t(int32_t  (0x36));
    int8_t(int64_t  (0x37));
    int8_t(uint8_t  (0x38));
    int8_t(uint16_t (0x39));
    int8_t(uint32_t (0x3A));
    int8_t(uint64_t (0x3B));
    int8_t(bool     (0x3C));
    int16_t(float16_t(0x41));
    int16_t(float32_t(0x42));
    int16_t(float64_t(0x43));
    int16_t(int8_t   (0x44));
    int16_t(int16_t  (0x45));
    int16_t(int32_t  (0x46));
    int16_t(int64_t  (0x47));
    int16_t(uint8_t  (0x48));
    int16_t(uint16_t (0x49));
    int16_t(uint32_t (0x4A));
    int16_t(uint64_t (0x4B));
    int16_t(bool     (0x4C));
    int32_t(float16_t(0x51));
    int32_t(float32_t(0x52));
    int32_t(float64_t(0x53));
    int32_t(int8_t   (0x54));
    int32_t(int16_t  (0x55));
    int32_t(int32_t  (0x56));
    int32_t(int64_t  (0x57));
    int32_t(uint8_t  (0x58));
    int32_t(uint16_t (0x59));
    int32_t(uint32_t (0x5A));
    int32_t(uint64_t (0x5B));
    int32_t(bool     (0x5C));
    int64_t(float16_t(0x61));
    int64_t(float32_t(0x62));
    int64_t(float64_t(0x63));
    int64_t(int8_t   (0x64));
    int64_t(int16_t  (0x65));
    int64_t(int32_t  (0x66));
    int64_t(int64_t  (0x67));
    int64_t(uint8_t  (0x68));
    int64_t(uint16_t (0x69));
    int64_t(uint32_t (0x6A));
    int64_t(uint64_t (0x6B));
    int64_t(bool     (0x6C));
    uint8_t(float16_t(0x71));
    uint8_t(float32_t(0x72));
    uint8_t(float64_t(0x73));
    uint8_t(int8_t   (0x74));
    uint8_t(int16_t  (0x75));
    uint8_t(int32_t  (0x76));
    uint8_t(int64_t  (0x77));
    uint8_t(uint8_t  (0x78));
    uint8_t(uint16_t (0x79));
    uint8_t(uint32_t (0x7A));
    uint8_t(uint64_t (0x7B));
    uint8_t(bool     (0x7C));
    uint16_t(float16_t(0x81));
    uint16_t(float32_t(0x82));
    uint16_t(float64_t(0x83));
    uint16_t(int8_t   (0x84));
    uint16_t(int16_t  (0x85));
    uint16_t(int32_t  (0x86));
    uint16_t(int64_t  (0x87));
    uint16_t(uint8_t  (0x88));
    uint16_t(uint16_t (0x89));
    uint16_t(uint32_t (0x8A));
    uint16_t(uint64_t (0x8B));
    uint16_t(bool     (0x8C));
    uint32_t(float16_t(0x91));
    uint32_t(float32_t(0x92));
    uint32_t(float64_t(0x93));
    uint32_t(int8_t   (0x94));
    uint32_t(int16_t  (0x95));
    uint32_t(int32_t  (0x96));
    uint32_t(int64_t  (0x97));
    uint32_t(uint8_t  (0x98));
    uint32_t(uint16_t (0x99));
    uint32_t(uint32_t (0x9A));
    uint32_t(uint64_t (0x9B));
    uint32_t(bool     (0x9C));
    uint64_t(float16_t(0xA1));
    uint64_t(float32_t(0xA2));
    uint64_t(float64_t(0xA3));
    uint64_t(int8_t   (0xA4));
    uint64_t(int16_t  (0xA5));
    uint64_t(int32_t  (0xA6));
    uint64_t(int64_t  (0xA7));
    uint64_t(uint8_t  (0xA8));
    uint64_t(uint16_t (0xA9));
    uint64_t(uint32_t (0xAA));
    uint64_t(uint64_t (0xAB));
    uint64_t(bool     (0xAC));
    bool(float16_t(0xB1));
    bool(float32_t(0xB2));
    bool(float64_t(0xB3));
    bool(int8_t   (0xB4));
    bool(int16_t  (0xB5));
    bool(int32_t  (0xB6));
    bool(int64_t  (0xB7));
    bool(uint8_t  (0xB8));
    bool(uint16_t (0xB9));
    bool(uint32_t (0xBA));
    bool(uint64_t (0xBB));
    bool(bool     (0xBC));
}
