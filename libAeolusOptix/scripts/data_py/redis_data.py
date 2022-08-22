import redis
"""
"overrides": [
    {
      "name": "openimageio",
      "version": "2.2.10.0",
    },
    {
      "name":"opencolorio",
      "version": "1.1.1",
    },
  ]
    "builtin-baseline": "e99d9a4facea9d7e15a91212364d7a12762b7512",
    "openexr",
    "libyaml",


    set(OutputDir ${CMAKE_HOME_DIRECTORY}/
add_custom_target(${targ}
  # todo: check if debug and release folder exist
  # debug version
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/libEGLd.dll          ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/libGLESv2d.dll       ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Cored.dll         ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Guid.dll          ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Declaratived.dll  ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Networkd.dll      ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5OpenGLd.dll       ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Scriptd.dll       ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Sqld.dll          ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Widgetsd.dll      ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Xmld.dll          ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5XmlPatternsd.dll  ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/icuin52.dll          ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/icuuc52.dll          ${CMAKE_BINARY_DIR}/Debug
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/icudt52.dll          ${CMAKE_BINARY_DIR}/Debug
  
  # release version
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/libEGL.dll           ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/libGLESv2.dll        ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Core.dll          ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Gui.dll           ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Declarative.dll   ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Network.dll       ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5OpenGL.dll        ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Script.dll        ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Sql.dll           ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Widgets.dll       ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5Xml.dll           ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/Qt5XmlPatterns.dll   ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/icuin52.dll          ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/icuuc52.dll          ${CMAKE_BINARY_DIR}/Release
  COMMAND ${CMAKE_COMMAND} -E copy ${Qt5Core_DIR}/../../../bin/icudt52.dll          ${CMAKE_BINARY_DIR}/Release

  # Output Message
  COMMENT "Copying Qt binaries from '${Qt5Core_DIR}/../../bin/' to '${CMAKE_BINARY_DIR}'" VERBATIM
)

"""


import json

PATH = "D:/C/CyclesVulkanRaytracing/data/kerneltex"


def JsonDump(data,name = "data.json" ):
    with open(f'{PATH}/{name}', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)


t={"Mesh":123}



"""
    "SVM::NODES" : {
        "ENVIRONMENT":  {
            "name" :"str",
            "data" :"str"
        } 
    }
"""
class MeshJson:
    def __init__(self):
        self.r  = redis.Redis(host='localhost', port=6379, db=0)
        self.Mesh ={
            "size" :0,
            "body" :[],
            "array":[]
            }
    def Dump(self):
        D ={
            "Mesh":self.Mesh,
            "Obj":self.Obj,
            "SVM":self.SVM,
            "KT":self.KT,
            "Tex":self.Tex,
            "KG":self.KG,
            "CNT":self.CNT
        }
        JsonDump(D)
    
    def CNT_dump(self):
        self.r.select(2)
        data     = self.r.hgetall("CNT")
        self.CNT = []
        for i in data:
            self.CNT.append( int(data[i].decode()) )

    def KG_dump(self):
        self.r.select(3)
        TID   = self.r.hget("KG:params:Update","TID").decode()
        keys  = self.r.keys("KG:params:*") 
        self.KG = {}
        attr = {}
        for k in keys:
            k1 = k.decode()
            suf = k1.split(":")[-1]
            if suf =="Update":continue
            data    = self.r.hgetall(k1)
            if b"__ShaderParams" in data:
                assert "__ShaderParams" not in attr,f"ShaderParams duplicated {data}"
                attr["__ShaderParams"] = data[b"__ShaderParams"].decode()
            
            if b"__KernelData" in data:
                assert "__KernelData" not in attr,f"__KernelData duplicated {data}"
                attr["__KernelData"] = data[b"__KernelData"].decode()

        self.KG["params"] = attr

    def Texture_dump(self):
        self.r.select(6)
        keys  = self.r.keys("Texture::*") 
        self.Tex = {}
        for key in keys:
            ret = self.r.hgetall(key)
            if ret:
                attr = {}
                attr["data"] = ret[b"data"].decode()
                attr["tDesc"] = ret[b"tDesc"].decode()
                attr["rDesc"]  = ret[b"rDesc"].decode()
                self.Tex[key.decode()] = attr

    def KernelTex(self):
        KTNames = [  ("float4","__prim_tri_verts"),
                ("uint", "__prim_tri_index"),
                ("uint", "__prim_type"),
                ("uint", "__prim_visibility"),
                ("uint", "__prim_index"),
                ("uint", "__prim_object"),
                #/* objects */
                ("KernelObject", "__objects"),
                #//"Transform, __object_motion_pass"
                #//"DecomposedTransform, __object_motion"
                ("uint", "__object_flag"),
                #"float, "__object_volume_step)
                #// patches 
                ("uint", "__patches"),
                #/* attributes */
                ("uint4", "__attributes_map"),
                ("float", "__attributes_float"),
                ("float2", "__attributes_float2"),
                ("float4", "__attributes_float3"),
                ("uchar4", "__attributes_uchar4"),
                #/* triangles */
                ("uint","__tri_shader"),
                ("float4", "__tri_vnormal"),
                ("uint", "__tri_vindex"),
                ("uint", "__tri_patch"),
                ("float2", "__tri_patch_uv"),
                #// lights 
                ("KernelLightDistribution", "__light_distribution"),
                ("KernelLight", "__lights"),
                ("float2", "__light_background_marginal_cdf"),
                ("float2", "__light_background_conditional_cdf"),
                #// particles 
                ("KernelParticle", "__particles"),
                ("uint4", "__svm_nodes"),
                ("KernelShader", "__shaders"),
                #// lookup tables 
                ("float", "__lookup_table"),
                #// sobol 
                ("uint", "__sample_pattern_lut"),
                #/* image textures */
                ("TextureInfo", "__texture_info")]
        self.r.select(3)
        TID   = self.r.hget("KG:params:Update","TID").decode()
        self.KT = {}
        for ty,name in KTNames:
            ret    = self.r.hget(f"KG:tex:{TID}",name)
            if ret:
                self.KT[name] = ret.decode()
            ret    = self.r.hget(f"KG:tex:{TID}",f"{name}:data")
            if ret:
                self.KT[f"{name}:data"] = ret.decode()

            ret    = self.r.hget(f"KG:tex:{TID}",f"{name}:crc")
            if ret:
                self.KT[f"{name}:crc"] = ret.decode()



    def SVM_dump(self):
        self.r.select(3)
        cs   = self.r.hgetall("colorspace")
        a   = self.r.hgetall("SVM::NODES")
        self.SVM = {}
        attr = { "name" : "", "data": "","colorspace":""}
        for k in a:
            node   = self.r.hgetall(k.decode())
            attr["name"] = a[k].decode()
            assert a[k] in node,f"NotFound {a[k]} "
            attr["data"] = node[a[k]].decode()
            assert a[k] in cs,f"NotFoundcolorspace {a[k]}"
            attr["colorspace"] = cs[a[k]].decode()
            if k.decode() not in self.SVM:
                self.SVM[k.decode()] =[]
            self.SVM[k.decode()].append(attr.copy())


    def Mesh_dump(self):
        n = self.Mesh_size()
        assert n > 0,f"NotFoundMesh"
        for i in range(n):
            self.Mesh_array(i)
            self.Mesh_body(i)
        

    def Mesh_size(self):
        self.r.select(4)
        keys = [key.decode() for key in self.r.keys("Mesh*")]
        for k in keys:
            if len(k.split("::"))==2:
                size= int(self.r.get(k).decode())
                self.Mesh["size"] = size
                self.Mesh["body"] = []
                self.Mesh["array"] = []
                self.Hash = k
                return size
        return -1

    def Mesh_body(self,i):
        key = f'{self.Hash}::body::{i}'
        a   = self.r.hgetall(key)
        assert b"__mesh" in a,f"NotFoundHash __mesh {a}"
        assert len(self.Mesh["body"])==i,f"LengthError {self.Mesh} != {i}"
        self.Mesh["body"].append( a[b"__mesh"].decode())

    def Mesh_array(self,i):
        key = f'{self.Hash}::array::{i}'
        a   = self.r.hgetall(key) 
       
        attr = {"size":0,"crc":0,"data":""}
        attrD = {}
        for name in ["triangles","verts","shader","smooth","triangle_patch","vert_patch_uv","subd_faces","subd_face_corners","subd_creases"]:
            sizeName = f"size:{name}".encode()
            crcName  = f"crc:{name}".encode()
            dataName = f"data:{name}".encode()
            if sizeName not in a:
                attr = {"size":0,"crc":0,"data":""}
            else:
                attr["size"]  = int(a[sizeName].decode())
                attr["crc"]   = int(a[crcName].decode())
                attr["data"]  = a[dataName].decode()
            attrD[name] = attr.copy()
        
        assert b"hashID" in a,f"NotFoundHashID"
        attrD["hashID"] = int(a[b"hashID"].decode())
        assert b"isInstanced" in a,f"NotFoundHashID"
        attrD["isInstanced"] = int(a[b"isInstanced"].decode())
        
        
        self.Mesh["array"].append(attrD)
        
    def Obj_dump(self):
        n = self.Obj_size()
        assert n > 0,f"NotFoundObj"
        for i in range(n):
            self.Obj_body(i)
       
    def Obj_size(self):
        self.Obj = {}
        self.r.select(4)
        keys = [key.decode() for key in self.r.keys("Obj*")]
        for k in keys:
            if len(k.split("::"))==2:
                size= int(self.r.get(k).decode())
                self.Obj["size"]  = size
                self.Obj["body"]  = []
                self.Obj["asset_name:char"] = []
                self.ObjHash = k
                return size
        return -1

    def Obj_body(self,i):
        key = f'{self.ObjHash}::body::{i}'
        a   = self.r.hgetall(key)
        assert b"__object" in a,f"NotFoundHash __object {a}"
        assert len(self.Obj["body"])==i,f"LengthError {self.Obj} != {i}"
        self.Obj["body"].append( a[b"__object"].decode())
        assert b"asset_name:char" in a,f"NotFoundHash asset_name:char {a}"
        self.Obj["asset_name:char"].append(a[b"asset_name:char"].decode())


mj = MeshJson()
mj.Mesh_dump()
mj.Obj_dump()
mj.SVM_dump()
mj.KernelTex()
mj.Texture_dump()
mj.KG_dump()
mj.CNT_dump()
mj.Dump()


"""
{ "Mesh"  : 
  {
   "size"  : int,
   "body"  : [str,str,str.....],
   "array" : [ 
    {
      "triangles"  : str,
      "verts"      : str,
        ....
    },
    {
      "triangles"  : str,
      "verts"      : str,
        ....
    },
     {
      "triangles"  : str,
      "verts"      : str,
        ....
    }......
    ]
}

"""


"""
r.set('foo', 'bar')
#　1Valueをセット
r.hset("user:1000", "username", "antirez")
r.hgetall("user:1000")
#=> {b'username': b'antirez'}

# まとめてセット
dict = {}
dict["birthyear"]   = 1977
dict["verified"]    = 1
r.hmset("user:1000",dict)
r.hgetall("user:1000")
#=> {b'username': b'antirez', b'birthyear': b'1977', b'verified': b'1'}

# ちなみに、同じKeyで別値をセットすると値上書き
r.hset("user:1000", "username", "antirez2")
r.hgetall("user:1000")
#=> {b'username': b'antirez2', b'birthyear': b'1977', b'verified': b'1'}

# 削除
r.flushall()

"""