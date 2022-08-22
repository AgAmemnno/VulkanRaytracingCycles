import redis
import numpy as np
import base64
tex_dtype ={
"kg->__prim_tri_index":np.uint32,
"kg->__prim_object":np.uint32,
"kg->__prim_index":np.uint32,
"kg->__tri_vindex" :np.uint32,
"kg->__prim_tri_verts":np.float32,
"__tri_vindex2" :np.uint32,
"__prim_tri_verts2":np.float32,
"__voffset" :np.uint32,
"__ioffset" :np.uint32,
"__prim_index" :np.uint32,
"__prim_object" :np.uint32,
}
def b64Decode(enc):
    kDecodingTable = [
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
        64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
        64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
        64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
    ]

    in_len = len(enc)
    if (in_len % 4 != 0):
        print( "Input data size is not a multiple of 4")
        return

    out_len = in_len / 4 * 3
    if (enc[in_len - 1] == '='):
        out_len-=1
    if (enc[in_len - 2] == '='):
        out_len-=1
    out = [0]*int(out_len)
    j = 0
    i = 0
    while(i<in_len):
        a =  0 & i if enc[i] == '=' else kDecodingTable[ord(enc[i])]
        i += 1
        b =  0 & i if enc[i] == '=' else kDecodingTable[ord(enc[i])]
        i += 1
        c =  0 & i if enc[i] == '=' else kDecodingTable[ord(enc[i])]
        i += 1
        d =  0 & i if enc[i] == '=' else kDecodingTable[ord(enc[i])]
        i += 1
        triple = (a << 3 * 6) + (b << 2 * 6) + (c << 1 * 6) + (d << 0 * 6)
        if (j < out_len):
            out[j] = (triple >> 2 * 8) & 0xFF
            j+=1
        if (j < out_len):
            out[j] = (triple >> 1 * 8) & 0xFF
            j+=1
        if (j < out_len):
            out[j] = (triple >> 0 * 8) & 0xFF
            j+=1
    return bytes(out)
        
class geom_debug:
    def __init__(self):
        r = redis.Redis(host='localhost', port=6379, db=11)
        _keys = r.hkeys('KG:data')
        data  = {}
        for k in _keys:
            key= k.decode() 
            if key[:2] == "kg":
                if key[-4:] == "size":
                    size      =  int(r.hget('KG:data',key).decode())
                    key       =  key[:-6]
                    d = base64.b64decode(r.hget('KG:data',key))
                    data[key] =  np.frombuffer(d,dtype=tex_dtype[key])
                    if key == "kg->__prim_tri_verts" or key == "kg->__tri_vindex":
                        data[key] = data[key].reshape(len(data[key])//4,4)
                    print(f" {key}  size {len(data[key])} ")
                    #data[key] =  np.frombuffer(b64Decode(r.hget('KG:data',key).decode()),dtype=tex_dtype[key])
                    #print(data["kg->__prim_tri_verts"][:128])
        self.data = data
        self.r = r
    def getVulData(self):
        Hash = 'VUL:data'
        _keys = self.r.hkeys(Hash)
        data  = {}
        for k in _keys:
            key= k.decode() 
            if key[:2] == "__":
                if key[-4:] == "size":
                    size      =  int(self.r.hget(Hash,key).decode())
                    key       =  key[:-6]
                    d = base64.b64decode(self.r.hget(Hash,key))
                    data[key] =  np.frombuffer(d,dtype=tex_dtype[key])
                    if key == "__prim_tri_verts2":
                        data[key] = data[key].reshape(len(data[key])//4,4)
                    if key == "__tri_vindex2":
                        data[key] = data[key].reshape(len(data[key])//3,3)
                    print(f" {key}  size {len(data[key])} ")
                    #data[key] =  np.frombuffer(b64Decode(r.hget('KG:data',key).decode()),dtype=tex_dtype[key])
                    #print(data["kg->__prim_tri_verts"][:128])
        self.Vdata = data
        print(self.Vdata)

    def index1(self):
        assert len(self.data["kg->__prim_tri_index"]) == len(self.data["kg->__tri_vindex"]) , "size prim_tri_index != tri_vindex "
        for i in range(len(self.data["kg->__prim_tri_index"])):
            d0 = self.data["kg->__prim_tri_index"][i]
            d1 = self.data["kg->__tri_vindex"][i]
            #assert  d0 == d1, f" val[{i}] prim_tri_index {d0} != tri_vindex {d1[3]} "
            print(f" val[{i}] prim_tri_index {d0} == tri_vindex {d1} ")
    def index2(self):
        kg = "kg->__tri_vindex"
        kglen = len(self.data[kg])
        vul = "__tri_vindex2"
        vullen = len(self.Vdata[vul])
        iofs    = self.Vdata["__ioffset"]
        vofs    = self.Vdata["__voffset"]
        print(f" Index  Nums {len(iofs)} offset {iofs}  ")
        print(f" Vertex Nums {len(vofs)} offset {vofs}  ")
        assert kglen == vullen , "size tri_vindex != tri_vindex2"
        objectID = 1
        Vofs     = 0
        for i in range(vullen):
            d0 = self.data[kg][i][:3]
            d1 = self.Vdata[vul][i][:3].copy()
            if len(iofs) > objectID and iofs[objectID] <= i:
                Vofs = vofs[objectID]
                objectID += 1
            d1 +=  Vofs
            #print(f" val[{i}]  tri_vindex {d0}  tri_vindex2 {d1} ")
            assert  np.all(d0[:3] == d1[:3]), f" val[{i}] tri_vindex {d0} != tri_vindex2 {d1} "
   
        print("index 2 pass ")
    def index3(self):
        kg1 = "kg->__tri_vindex"
        kg1len = len(self.data[kg1])
        kg2 = "kg->__prim_index"
        kg2len = len(self.data[kg2])
        assert kg1len == kg2len ," kglen{kg1len} !=  kg2len{kg2len} "
        for i in range(kg1len):
            d1 = self.data[kg2][i]
            w  = self.data[kg1][d1][3]
            assert  i == w//3,f" non cyclic index  primID {i} => primIndex {d1} => vindex.w {w} "
            #print(f"   cyclic index  primID {i} => primIndex {d1} => vindex.w {w}/3 == {i}")
        print("index 3 pass ")
    def comp_CpuXVulkan(self,kg = "kg->__prim_index",vul = "__prim_index") :
        kglen = len(self.data[kg])
        vullen = len(self.Vdata[vul])
        assert kglen == vullen , f"size {kg} {kglen} != {vul}{vullen} "
        for i in range(vullen):
            d0 = self.data[kg][i]
            d1 = self.Vdata[vul][i]
            print(f" data[{i}]  {kg}{d0} == {vul}{d1}")
            #assert d0 == d1 , f" data[{i}]  {kg}{d0} != {vul}{d1}"


geom = geom_debug()
geom.getVulData()
pid =  208 #451
geom.index3()
geom.index2()
geom.comp_CpuXVulkan("kg->__prim_index","__prim_index")
#geom.comp_CpuXVulkan("kg->__prim_object","__prim_object")

"""
  const uint tri_vindex = kernel_tex_fetch(__prim_tri_index, isect->prim);
  const float4 tri_a = kernel_tex_fetch(__prim_tri_verts, tri_vindex + 0),
               tri_b = kernel_tex_fetch(__prim_tri_verts, tri_vindex + 1),
               tri_c = kernel_tex_fetch(__prim_tri_verts, tri_vindex + 2);
"""