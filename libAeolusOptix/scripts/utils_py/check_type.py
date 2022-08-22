import ctypes
def floatBitsToUint(f):return ctypes.c_uint.from_buffer(ctypes.c_float(f)).value
def uintBitsToFloat(u):return ctypes.c_float.from_buffer(ctypes.c_uint(u)).value
def floatBitsToInt(f):return ctypes.c_int.from_buffer(ctypes.c_float(f)).value
def intBitsToFloat(u):return ctypes.c_float.from_buffer(ctypes.c_int(u)).value

def svm_unpack_node_uchar4(i):
    x = (i & 0xFF)
    y = ((i >> 8) & 0xFF)
    z = ((i >> 16) & 0xFF)
    w = ((i >> 24) & 0xFF)
    return (x,y,z,w)


den = ctypes.c_float(1.0 / ctypes.c_float(0xFFFFFFFF).value)
val = ctypes.c_uint(1784416675)
i   = ctypes.c_int(2**31)
"""
  NODE offset 3   node x 1  y 21  z 27  w 28
  NODE offset 21   node x 11  y 0  z 0  w 0
  NODE offset 22   node x 55  y 0  z 16712448  w 0
  NODE offset 23   node x 14  y 1065353216  z 0  w 0
  NODE offset 24   node x 7  y 3  z 0  w 0
  NODE offset 25   node x 4  y 255  z 0  w 0
  NODE offset 26   node x 0  y 0  z 0  w 0
"""
node = 16712448
x,y,z,w = svm_unpack_node_uchar4(node)
print(x,y,z,w)