import os
os.chdir("D:\\C\\Aeoluslibrary\\libAeolusOptix\\scripts\\utils_py")
import sys 
lib_path = "D:/blender/Lib/site-packages"
if lib_path not in sys.path:
    sys.path.append(lib_path)


from parse_enum import *
#(code1,num) = re.subn(r"[\s]+struct[\s]+(.*)[\s]+{(((?!\1).|\n)*)}[\s]*\1",r"\n\n struct _\1 { \2 }\1",code)  
#print(code1)

class converter():
    test = """
        
    """
    def __init__(self,dir = "D:/C/Aeoluslibrary/libAeolusOptix/shaders/intern"):
        self.BaseDir  =  dir
    def replace(self,f,code,Post = False):
        token = ["1$","REG$","REGEX$"]    
        mtoken = ["<~","~>"]
        if Post:
            mtoken = ["~<",">~"]
            token = ["2$","REGP$","REGEXP$"]    
        import codecs,regex
        file = self.BaseDir + f
        if os.path.exists(file):
            with codecs.open(file, 'r') as fp:
                multi = False
                ml    = []
                stack = ""
                for line in fp.readlines():
                    if(line[:2] == "36"):
                        print(" conv 36 ")
                    if line[:2] == mtoken[0]:
                        multi = True
                        stack = ""
                        continue
                    if multi:
                        if line[:2] == mtoken[1]:
                            ml.append(stack)
                            if len(ml) == 2:
                                code = code.replace(fr"{ml[0]}",fr"{ml[1]}")
                                ml = [] 
                            multi = False
                        else:
                            stack += line
                        continue
                    if line[0] == '#':continue
                    l =line.split(token[0])
                    if len(l) == 2:
                        #(code,num) = re.subn(fr"{l[0]}",fr"{l[1]}",code)
                        code = code.replace(fr"{l[0]}",fr"{l[1]}")
                    else:
                        l =line.split(token[1])
                        if len(l) == 2:
                            (code,num) = re.subn(fr"{l[0]}",fr"{l[1]}",code)
                        else:
                            l =line.split(token[2])
                            if len(l) == 2:
                                (code,num) = regex.subn(fr"{l[0]}",fr"{l[1]}",code)
                           
        return code
    def dotH(cls,code):
        (code,num)  = re.subn(r"[\s]+#[\s]+include([(?!\.h)\S ]*)\.h",r"\n#include \1.h.glsl ",code)
        debug(f"dotH .h to .h.glsl  NUMS {num}   ==>>   \n\n {code} \n\n")
        return code
    def compat(self):
        p      = preproc(self.BaseDir)
        p.open("/kernel_compat_vulkan.h")
        p.code = post_optional.underscore(p.code)
        p.write()
    def util_types(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix = "/util/util_types_"
        files  = ["uchar2","uchar3","uchar4","uint2","uint3","uint4","ushort4","int2","int3","int4","vector3","float2","float3","float4","float8"]
        for f in files:
            p.open(prefix + f + suffix)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.execall(p.code)
            p.write()
        p.open("/util/util_defines.h")
        p.code = post_optional.underscore(p.code)
        p.code = replace_type.execall(p.code)
        p.write()
        p.open("/util/util_types.h")
        p.code = post_optional.underscore(p.code)
        p.code = replace_type.execall(p.code)
        p.write()

    def util_math(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix = "/util/util_math_"
        files  = ["float2","float3","float4"]
        for f in files:
            p.open(prefix + f + suffix)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.execall(p.code)
            p.write()
        p.open("/util/util_rect.h")
        p.code = post_optional.underscore(p.code)
        p.code = replace_type.execall(p.code)
        p.write()    
        p.open("/util/util_math.h")
        p.code = post_optional.underscore(p.code)
        p.code = replace_type.execall(p.code)
        p.write()
        p.open("/util/util_math_intersect.h")
        p.code = post_optional.underscore(p.code)
        p.code = replace_type.execall(p.code)
        p.write()
    def kernel_math(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/util/util_"
        files  = ["color","math_fast","projection","texture","transform"]
        for f in files:
            p.open(prefix + f + suffix)
            if f == "texture":
                p.code = replace_type.enum2const(p.code)
            else:
                p.code = post_optional.underscore(p.code)
            p.code = replace_type.execall(p.code)
            p.write()
        p.open("/kernel/kernel_math.h")
        p.code = post_optional.underscore(p.code)
        p.write()
    def svm(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/svm/"
        files  = [   
        ("svm",""),
        ("svm_noise",""),
        ("svm_fractal_noise",""),
        ("svm_color_util",""),
        ("svm_mapping_util",""),
        ("svm_math_util",""),
        ("svm_aov",""),
        ("svm_attribute",""),
        ("svm_blackbody",""),
        ("svm_brick",""),
        ("svm_brightness",""),
        ("svm_bump",""),
        ("svm_camera",""),
        ("svm_checker",""),
        ("svm_clamp",""),
        ("svm_closure","closure"),
        ("svm_convert",""),
        ("svm_displace",""),
        ("svm_fresnel",""),
        ("svm_gamma",""),
        ("svm_geometry",""),
        ("svm_gradient",""),
        ("svm_hsv",""),
        ("svm_ies",""),
        ("svm_image",""),
        ("svm_invert",""),
        ("svm_light_path",""),
        ("svm_magic",""),
        ("svm_map_range",""),
        ("svm_mapping",""),
        ("svm_math",""),
        ("svm_mix",""),
        ("svm_musgrave",""),
        ("svm_noisetex",""),
        ("svm_normal",""),
        ("svm_ramp",""),
        ("svm_sepcomb_hsv",""),
        ("svm_sepcomb_vector",""),
        ("svm_sky",""),
        ("svm_tex_coord",""),
        ("svm_value",""),
        ("svm_vector_rotate",""),
        ("svm_vector_transform",""),
        ("svm_vertex_color",""),
        ("svm_voronoi",""),
        ("svm_voxel",""),
        ("svm_wave",""),
        ("svm_wavelength",""),
        ("svm_white_noise",""),
        ("svm_wireframe",""),
        ("svm_ao",""),
        ("svm_bevel","")
        ]


        for (f,name) in files:
            p.open(prefix + f + suffix)
            p.code = self.replace(prefix + f + ".rep",p.code)
            p.code = self.replace("/common.rep",p.code)


            p.code = replace_type.reserve(p.code)
            if name == "closure":
                svm_conv.cache_define["Microfacet_"] = True
                p.code = svm_conv.closure("Microfacet","Bsdf",p.code)
            (p.code,Names) = svm_conv.functions(p.code)
            if name == "defunc":
                (p.code,Names2) = svm_conv.def_functions(p.code)
                Names += Names2 
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.pointer2inout(p.code,Names)
            p.code = self.replace(prefix + f + ".rep",p.code,True)
            p.code = self.replace("/kernel/svm/common.rep",p.code,True)

            p.write()
        

    def bsdf(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/"
        files  = [   
        ("kernel_projection","",""),
        ("kernel_emission","",""),
        ("kernel_light","",""),
        ("kernel_light_common","",""),
        ("kernel_light_background","","")
        ]
        for (f,name,bsdf) in files:
            p.open(prefix + f + suffix)
            p.code = self.replace(prefix + f + ".rep",p.code)
            if name != "":
                p.code = svm_conv.closure(name,bsdf,p.code)
            (p.code,Names) = svm_conv.functions(p.code)
            if bsdf == "defunc":
                (p.code,Names2) = svm_conv.def_functions(p.code)
                Names += Names2 
            if f == "kernel_light":
                p.code = replace_type.enum2const(p.code)
            p.code = replace_type.reserve(p.code)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.pointer2inout(p.code,Names)
            p.code = self.replace(prefix + f + ".rep",p.code,True)
            p.write()

        prefix =  "/kernel/closure/"
        files  = [   
        ("emissive","",""),
        ("bsdf_util","",""),
        ("bsdf","","Bsdf"),
        ("bsdf_ashikhmin_velvet","Velvet","Bsdf"),
        ("bsdf_diffuse","Diffuse","Bsdf"),
        ("bsdf_oren_nayar","OrenNayar","Bsdf"),
        ("bsdf_microfacet","Microfacet","Bsdf"),
        ("bsdf_microfacet_multi_impl","","defunc"),
        ("bsdf_microfacet_multi","Microfacet","Bsdf"),
        ("bsdf_reflection","Microfacet","Bsdf"),
        ("bsdf_refraction","Microfacet","Bsdf"),
        ("bsdf_transparent","",""),
        ("bsdf_ashikhmin_shirley","Microfacet","Bsdf"),
        ("bsdf_toon","Toon","Bsdf"),
        ("bsdf_hair","Hair","Bsdf"),
        ("bsdf_hair_principled","PrincipledHair","BSDF") ,
        ("bsdf_principled_diffuse","PrincipledDiffuse","Bsdf"),
        ("bsdf_principled_sheen","PrincipledSheen","Bsdf"),
        ("bssrdf","Bssrdf","bssrdf"),
        ("volume","HenyeyGreensteinVolume","volume"),
                    ]
        for (f,name,bsdf) in files:
            p.open(prefix + f + suffix)
            p.code = self.replace(prefix + f + ".rep",p.code)
            if name != "":
                p.code = svm_conv.closure(name,bsdf,p.code)
            (p.code,Names) = svm_conv.functions(p.code)
            if bsdf == "defunc":
                (p.code,Names2) = svm_conv.def_functions(p.code)
                Names += Names2 
            p.code = replace_type.reserve(p.code)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.pointer2inout(p.code,Names)
            p.write()
    def kernel_types(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/"
        files  = ["kernel_types","svm/svm_types"]
        for f in files:
            p.open(prefix + f + suffix)
            p.code = replace_type.enum2const(p.code)
            p.code = post_optional.underscore(p.code)
            p.write()

    def kernel_pass(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix = "/util/util_"
        files  = ["hash"]
        for f in files:
            p.open(prefix + f + suffix)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.execall(p.code)
            p.write()
        prefix = "/kernel/kernel_"
        files  = ["jitter","random"]
        for f in files:
            p.open(prefix + f + suffix)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.execall(p.code)
            p.write()
    def kernel_acc(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/kernel_accumulate"
        Names = [("KernelGlobals","kg"),
            ("const PathRadiance","L_src"),
            ("PathRadiance","L"),
            ("const BsdfEval","eval"),
            ("BsdfEval" ,"eval"),
            ("const BsdfEval","bsdf_eval"),
            ("BsdfEval","bsdf_eval"),
            ("const ShaderData" , "sd"),
            ("PathRadianceState" ,"L_state"),
            ("PathState","state")
        ]
        p.open(prefix + suffix)
        p.code = post_optional.underscore(p.code)
        p.code = replace_type.pointer2inout(p.code,Names)
        p.write()
    def kernel_pathstate(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/kernel_path_state"
        Names = [("KernelGlobals","kg"),
        ("ShaderData" , "stack_sd"),
         ("PathState","state"),
         ("Ray" ,"ray")
        ]
        p.open(prefix + suffix)
        p.code = post_optional.underscore(p.code)
        p.code = replace_type.pointer2inout(p.code,Names)
        p.code = replace_type.resere(p.code)
        p.write()
    def kernel_globals(self,libs = False):

        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/kernel_"
        files  = ["globals"]
        if libs:
            files2 = ["differential","montecarlo","write_passes","camera","shader", "emission","passes"]
            files += files2
            p.open(prefix )
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.execall(p.code)
            p.writeccl()
            p.write()

        kernel_textures()
        
        for f in files:
            p.open(prefix + f + suffix)
            p.code = self.replace(prefix + f + ".rep",p.code)
            p.code = self.replace("/kernel/common.rep",p.code)

            p.code = replace_type.post_SubALL(p.code)
            p.code = post_optional.underscore(p.code)
            if f == "montecarlo" or f == "write_passes" or f == "camera" or f == "shader" or f == "emission":
                (p.code,Names) = svm_conv.functions(p.code)
            else:
                Names =[]
            p.code = replace_type.pointer2inout(p.code,Names)
            p.code = self.replace("/kernel/common.rep",p.code,True)
            p.code = self.replace(prefix + f + ".rep",p.code,True)

            p.write()

    def kernel_textures(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/kernel_"
        files  = ["textures"]
        p.open( prefix + "textures" + suffix)
        p.code = replace_type.execall(p.code)
        p.writeccl()
        p.code = post_optional.underscore(p.code)
        p.write()
        
    def bvh(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/bvh/"
        files  = ["bvh_types","bvh_nodes","bvh_traversal","bvh_local","bvh"]
        Names = [("KernelGlobals","kg"), 
                 ("const Ray" ,"ray"),
                 ("Intersection","isect"),
                 ("LocalIntersection","local_isect")
        ]
        for f in files:
            p.open(prefix + f + suffix)
            p.code = replace_type.post_SubALL(p.code)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.pointer2inout(p.code,Names)
            p.write()
    def geom(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/geom/"
        files  = ["geom_attribute",
                "geom_object",
                 "geom_triangle",
                 "geom_patch",
                 "geom_triangle_intersect",
                 "geom_motion_triangle",
                 "geom_motion_triangle_intersect",
                 "geom_motion_triangle_shader",
                 "geom_subd_triangle",
                 "geom_primitive",
                 "geom_motion_curve",
                 "geom_curve"]

        Names = [("KernelGlobals","kg"), 
                 ("const ShaderData" ,"sd"),
                 ("ShaderData", "sd"),
                 ("const Ray" ,"ray"),
                 ("const Intersection", "isect"),
                 ("Intersection", "isect"),
        ]

        for f in files:
            p.open(prefix + f + suffix)
            p.code = self.replace(prefix + f + ".rep",p.code)
            p.code = replace_type.reserve(p.code)
            if f == "geom_triangle":
                print(debug)
            (p.code,Names) = svm_conv.functions(p.code)
            p.code = replace_type.enum2const(p.code)
            p.code = replace_type.post_SubALL(p.code)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.pointer2inout(p.code,Names)
            p.code = self.replace(prefix + "common.rep",p.code,True)
            p.code = self.replace(prefix + f + ".rep",p.code,True)
            p.write()


    def kernel_light(self):
        p      = preproc(self.BaseDir)
        suffix = ".h"
        prefix =  "/kernel/"
        files  = ["kernel_emission"]
        Names = [("KernelGlobals","kg"), 
                 ("ShaderData" ,"emission_sd"),
                 ("LightSample", "ls"),
                 ("PathState", "state")
        ]
        for f in files:
            p.open(prefix + f + suffix)
            p.code = replace_type.post_SubALL(p.code)
            p.code = post_optional.underscore(p.code)
            p.code = replace_type.pointer2inout(p.code,Names)
            p.write()
    def parser(self,file):
        toPath = "D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders"
        p      = preproc("D:\\C\\Aeoluslibrary\\data\\shaders")
        files =  [file]
        cod = """
        layout(binding = 1, rgba8) uniform writeonly image2D image;
        layout(set =2,binding = 0, std430) buffer readonly KD
{
KernelData kernel_data;
int        data[];
ShaderData shader_data;
};

        """
        #par.parse_layout(cod)
        #elim = eliminate(par,"main",cod)
        #elim.setLayout("image 0 1 KD 3 1")
        #elim.replace_layout()

        par = parser()
        for f in files:
            p.openfullpath(f)
            par.entry(p.code)
            elim = eliminate(par,"main",p.code)
            elim.naive_var()
            elim.naive_struct()
            if len(self.SetBindings) >0:
                elim.setLayout(self.SetBindings)
                elim.replace_layout()
            p.code = elim.code
            p._write(f.replace(os.path.basename(f),os.path.basename(f).replace("_tmp1","")) ,p.code)
             
        

#_Large_string_engaged()
# randuv  0.970744 0.339828

COMPAT    = False
MATH      = False
KMATH     = False
STYPES      = False

KPASS       = False
KPATHSTATE  = False

#   2706531586
BVH          = False
BSDF         = False
GEOM         = False
SVM          = False

KGLOBALS     = False
KTEX         = False
KTYPES       = False
TYPES        = False


TESTEXE = False
TEST    = False

OPT          = False

COMPILE_SAHDOW     =False

COMPILE_ELIM_BG  = False





COMPILE      =  False
COMPILE_ELIM     = True
if COMPAT:
    
    #for file in files:
    #    ENUM2CONST(file)
    c = converter()
    c.compat()
if TYPES:
    #for file in files:
    #    ENUM2CONST(file)
    c = converter()
    c.compat()
    c.util_types()
if MATH:
    c = converter()
    c.util_math()
if KMATH:
    c = converter()
    c.kernel_math()
if STYPES:
    c = converter()
    c.svm_types()
if KTYPES:
    c = converter()
    c.kernel_types()
if KGLOBALS:
    c = converter()
    c.kernel_globals()
if KTEX:
    c = converter()
    c.kernel_textures()

if KPASS:
    c = converter()
    c.kernel_pass()
    c.kernel_acc()
if KPATHSTATE:
    c = converter()
    c.kernel_pathstate()
if BVH:
    c = converter()
    c.geom()   
    c.bvh()    
if BSDF:
   svm = converter()
   print( svm.bsdf())

if SVM:
   #c = converter()
   #p      = preproc(c.BaseDir)
   #p.open("/kernel/closure/bsdf_hair_principled.h")
   #svm_conv.functions(p.code)
   svm = converter()
   print( svm.svm())

if GEOM:
   svm = converter()
   svm.geom()


import subprocess
#import aeospirv
import struct
class spirvcross:
    def __init__(self):
        self.srcpath = "D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders"
        self.path = "D:\\C\\Aeoluslibrary\\data\\shaders"
        self.I =  "D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders\\intern"
        self.cacheDebug = {}
    def debugExt_store(self,f):
        p      = preproc("")
        p.openfullpath(f)
        
        DebugPrint = []
        for it in re.finditer(r"[\s]*debugPrintfEXT(((?!;).|\n)*);",p.code):
            DebugPrint.append(it)
        if len(DebugPrint) > 0:
            self.cacheDebug[f] = DebugPrint

        #// unimplemented ext op 12
    def debugExt_load(self,dst,src):
        if src in self.cacheDebug:
            p      = preproc("")
            p.openfullpath(dst)
            dp = self.cacheDebug[src]
            i = 0
            while(True):
                found = False
                for it in re.finditer(r"[\s]*\/\/[\s]*unimplemented ext op 12",p.code):
                    (st,ed) = it.regs[0]
                    p.code = p.code[:st] + dp[i][0] + p.code[ed:]
                    found = True
                    break
                i+=1
                if i == len(dp):
                    break
                if not found:
                    print("Error Unexpected Parse. ")
                    exit(-1)
            code   = p.code.split("\n") 
            p.code = code[0] + "\n#extension GL_EXT_debug_printf : enable\n" + "\n".join(code[1:])
            p._write(dst,p.code)
            del self.cacheDebug[src]


    def compile_elim(self,folder,name,stage,tmp= True):
        env           = "spirv1.5" # "vulkan1.2" # "vulkan1.2" #
        if tmp:
            glsl          =  self.srcpath + folder + "tmp\\" + name + "." + stage +  ".glsl"
        else:
            glsl          =  self.srcpath + folder + name + "." + stage +  ".glsl"

        spirv         =  self.path + folder  + name + "." + stage +  ".spv"
        
        cmd   = f"glslangValidator -V -S {stage} "
        if self.I != "":
            cmd += f" -I{self.I} "
        #cmd += f"  -Os  -g  -i "
        #cmd += f"  -g  -i "
        cmd  +=  self.Opt
        cmd += f" --target-env {env}"
        cmd += self.SetBinding
        cmd += f"  -o  {spirv} {glsl}"

        print(f"CMD1  {cmd}")
        subprocess.call(cmd.split())
        
        glsl_dis         =  self.path + folder  + name + "." + stage +  ".glsl"
        cmd          = f"spirv-cross -V --version 460 --no-es {spirv} --output {glsl_dis} "
        print(f"CMD2  {cmd}")
        subprocess.call(cmd.split())

    def toSpirv(self, folder, name, stage,inter= False):
        env   = "spirv1.5"
        glsl  = self.srcpath + folder  + name + "." + stage +  ".glsl"
        if inter:
            spirv         = self.srcpath + folder + "tmp\\" + name + "." + stage +  ".spv"
            glsl_tmp      = self.srcpath + folder + "tmp\\" + name + "_tmp1." + stage +  ".glsl"
            self.tmpfile  = glsl_tmp
        else:
            spirv         = self.path + folder  + name + "." + stage +  ".spv"

        cmd   = f"glslangValidator -V -S {stage} "
        if self.I != "":
            cmd += f" -I{self.I} "
        #cmd += f"  -Os  -g  -i "
        #cmd += f"  -g  -i "
        cmd  +=  self.Opt
        cmd += f" --target-env {env}"
        cmd += self.SetBinding
        cmd += f"  -o  {spirv} {glsl}"
  
        
        print(f"{cmd}")
        subprocess.call(cmd.split())

        self.debugExt_store(glsl)
        cmd = f"spirv-cross -V --version 460 --no-es {spirv} --output {glsl_tmp} "
        subprocess.call(cmd.split())
        self.debugExt_load(glsl_tmp,glsl)



        #spirv2 = path.replace(".glsl", "_opt.spv")
        #cmd  = f"spirv-opt --compact-ids -o {spirv2} {spirv} "
        #subprocess.call(cmd.split())
        #spirv3 = path.replace(".glsl", "_opt2.spv")
        #cmd = f"spirv-opt    --compact-ids --eliminate-dead-const  --eliminate-dead-variables  --eliminate-dead-branches  --eliminate-dead-code-aggressive   --eliminate-dead-functions  --eliminate-dead-inserts   -o {spirv3} {spirv2} "
        #subprocess.call(cmd.split())
    def compile(self,file,stage):
        #ret = aeospirv.echo(file,stage)
        if ret == 0:
            self.toGlsl(file,stage)
        return ret


    def toGlsl(self,file,stage):
        cmd = f"spirv-cross -V --version 460 --no-es {self.path}{file}.{stage}.spv --output {self.path}{file}.{stage}"
        subprocess.call(cmd.split())
    def shaderFlag(self,v = 1610612742):
        SHADER_SMOOTH_NORMAL = (1 << 31)
        SHADER_CAST_SHADOW = (1 << 30)
        SHADER_AREA_LIGHT = (1 << 29)
        SHADER_USE_MIS = (1 << 28)
        SHADER_EXCLUDE_DIFFUSE = (1 << 27)
        SHADER_EXCLUDE_GLOSSY = (1 << 26)
        SHADER_EXCLUDE_TRANSMIT = (1 << 25)
        SHADER_EXCLUDE_CAMERA = (1 << 24)
        SHADER_EXCLUDE_SCATTER = (1 << 23)
        SHADER_EXCLUDE_ANY = (SHADER_EXCLUDE_DIFFUSE | SHADER_EXCLUDE_GLOSSY | SHADER_EXCLUDE_TRANSMIT | SHADER_EXCLUDE_CAMERA | SHADER_EXCLUDE_SCATTER)

        SHADER_MASK = ~(SHADER_SMOOTH_NORMAL | SHADER_CAST_SHADOW | SHADER_AREA_LIGHT | SHADER_USE_MIS |SHADER_EXCLUDE_ANY)
        offset = v & SHADER_MASK
        print("shaderflags & SHADERMASK ",offset)
    def pathrayFlag(sefl,v):
        #PathRayFlag 
        PATH_RAY_CAMERA     =  ((1<<0))
        PATH_RAY_REFLECT     =  ((1<<1))
        PATH_RAY_TRANSMIT     =  ((1<<2))
        PATH_RAY_DIFFUSE     =  ((1<<3))
        PATH_RAY_GLOSSY     =  ((1<<4))
        PATH_RAY_SINGULAR     =  ((1<<5))
        PATH_RAY_TRANSPARENT     =  ((1<<6))
        PATH_RAY_SHADOW_OPAQUE_NON_CATCHER     =  ((1<<7))
        PATH_RAY_SHADOW_OPAQUE_CATCHER     =  ((1<<8))
        PATH_RAY_SHADOW_OPAQUE     =  ((PATH_RAY_SHADOW_OPAQUE_NON_CATCHER|PATH_RAY_SHADOW_OPAQUE_CATCHER))
        PATH_RAY_SHADOW_TRANSPARENT_NON_CATCHER     =  ((1<<9))
        PATH_RAY_SHADOW_TRANSPARENT_CATCHER     =  ((1<<10))
        PATH_RAY_SHADOW_TRANSPARENT     =  ((PATH_RAY_SHADOW_TRANSPARENT_NON_CATCHER|PATH_RAY_SHADOW_TRANSPARENT_CATCHER))
        PATH_RAY_SHADOW_NON_CATCHER     =  ((PATH_RAY_SHADOW_OPAQUE_NON_CATCHER|PATH_RAY_SHADOW_TRANSPARENT_NON_CATCHER))
        PATH_RAY_SHADOW     =  ((PATH_RAY_SHADOW_OPAQUE|PATH_RAY_SHADOW_TRANSPARENT))
        PATH_RAY_UNUSED     =  ((1<<11))
        PATH_RAY_VOLUME_SCATTER     =  ((1<<12))
        PATH_RAY_NODE_UNALIGNED     =  ((1<<13))
        PATH_RAY_ALL_VISIBILITY     =  (((1<<14)-1))
        PATH_RAY_MIS_SKIP     =  ((1<<14))
        PATH_RAY_DIFFUSE_ANCESTOR     =  ((1<<15))
        PATH_RAY_SINGLE_PASS_DONE     =  ((1<<16))
        PATH_RAY_SHADOW_CATCHER     =  ((1<<17))
        PATH_RAY_STORE_SHADOW_INFO     =  ((1<<18))
        PATH_RAY_TRANSPARENT_BACKGROUND     =  ((1<<19))
        PATH_RAY_TERMINATE_IMMEDIATE     =  ((1<<20))
        PATH_RAY_TERMINATE_AFTER_TRANSPARENT     =  ((1<<21))
        PATH_RAY_TERMINATE     =  ((PATH_RAY_TERMINATE_IMMEDIATE|PATH_RAY_TERMINATE_AFTER_TRANSPARENT))
        PATH_RAY_EMISSION     =  ((1<<22))

        print(f" shader_eval_surface  {v & (PATH_RAY_TERMINATE | PATH_RAY_SHADOW | PATH_RAY_EMISSION)}" )
    def sdFlag(self,v):
        
        #modify => enum ShaderDataFlag 
        #ShaderDataFlag uint
        SD_BACKFACING  = ((1<<0))
        SD_EMISSION  = ((1<<1))
        SD_BSDF  = ((1<<2))
        SD_BSDF_HAS_EVAL  = ((1<<3))
        SD_BSSRDF  = ((1<<4))
        SD_HOLDOUT  = ((1<<5))
        SD_EXTINCTION  = ((1<<6))
        SD_SCATTER  = ((1<<7))
        SD_TRANSPARENT  = ((1<<9))
        SD_BSDF_NEEDS_LCG  = ((1<<10))
        SD_CLOSURE_FLAGS  = ((SD_EMISSION|SD_BSDF|SD_BSDF_HAS_EVAL|SD_BSSRDF|SD_HOLDOUT|SD_EXTINCTION|SD_SCATTER|SD_BSDF_NEEDS_LCG))
        SD_USE_MIS  = ((1<<16))
        SD_HAS_TRANSPARENT_SHADOW  = ((1<<17))
        SD_HAS_VOLUME  = ((1<<18))
        SD_HAS_ONLY_VOLUME  = ((1<<19))
        SD_HETEROGENEOUS_VOLUME  = ((1<<20))
        SD_HAS_BSSRDF_BUMP  = ((1<<21))
        SD_VOLUME_EQUIANGULAR  = ((1<<22))
        SD_VOLUME_MIS  = ((1<<23))
        SD_VOLUME_CUBIC  = ((1<<24))
        SD_HAS_BUMP  = ((1<<25))
        SD_HAS_DISPLACEMENT  = ((1<<26))
        SD_HAS_CONSTANT_EMISSION  = ((1<<27))
        SD_NEED_VOLUME_ATTRIBUTES  = ((1<<28))
        SD_SHADER_FLAGS  = ((SD_USE_MIS|SD_HAS_TRANSPARENT_SHADOW|SD_HAS_VOLUME|SD_HAS_ONLY_VOLUME|SD_HETEROGENEOUS_VOLUME|SD_HAS_BSSRDF_BUMP|SD_VOLUME_EQUIANGULAR|SD_VOLUME_MIS|SD_VOLUME_CUBIC|SD_HAS_BUMP|SD_HAS_DISPLACEMENT|SD_HAS_CONSTANT_EMISSION|SD_NEED_VOLUME_ATTRIBUTES))
        #modified ==> ShaderDataFlag
        print(f"  SD_EMISSION  {SD_EMISSION&v} ")
        print(f"  SD_HOLDOUT   {SD_HOLDOUT&v} ")

    def intBitsToFloat(self,b):
        s = struct.pack('>l', b)
        return struct.unpack('>f', s)[0]
    def rgb(self,rgb):
        print(f" r {self.intBitsToFloat(rgb[0])} g {self.intBitsToFloat(rgb[1])} b {self.intBitsToFloat(rgb[2])} ")
    def removeTmp(self,folder):
        folder = self.srcpath + folder + "tmp"
        fileList = os.listdir(folder)
        for f in fileList:
            filePath = folder + '/' + f
            if os.path.isfile(filePath):
                os.remove(filePath)
    def objectFlag(self,v):
        # Holdout for camera rays. */
        SD_OBJECT_HOLDOUT_MASK = (1 << 0)
        # Has object motion blur. */
        SD_OBJECT_MOTION = (1 << 1)
        # Vertices have transform applied. */
        SD_OBJECT_TRANSFORM_APPLIED = (1 << 2)
        # Vertices have negative scale applied. */
        SD_OBJECT_NEGATIVE_SCALE_APPLIED = (1 << 3)
        # Object has a volume shader. */
        SD_OBJECT_HAS_VOLUME = (1 << 4)
        # Object intersects AABB of an object with volume shader. */
        SD_OBJECT_INTERSECTS_VOLUME = (1 << 5)
        # Has position for motion vertices. */
        SD_OBJECT_HAS_VERTEX_MOTION = (1 << 6)
        # object is used to catch shadows */
        SD_OBJECT_SHADOW_CATCHER = (1 << 7)
        # object has volume attributes */
        SD_OBJECT_HAS_VOLUME_ATTRIBUTES = (1 << 8)
        SD_OBJECT_FLAGS = (SD_OBJECT_HOLDOUT_MASK | SD_OBJECT_MOTION | SD_OBJECT_TRANSFORM_APPLIED |
                            SD_OBJECT_NEGATIVE_SCALE_APPLIED | SD_OBJECT_HAS_VOLUME |
                            SD_OBJECT_INTERSECTS_VOLUME | SD_OBJECT_SHADOW_CATCHER |
                            SD_OBJECT_HAS_VOLUME_ATTRIBUTES)
    def pseudo(self,size,n,loc,prdsize):
        code =  """
            #version 460
            #extension GL_NV_ray_tracing : require
            #extension GL_GOOGLE_include_directive : enable
            #define PUSH_POOL_SC
            #define SET_KERNEL 2
            #include "kernel_compat_vulkan.h.glsl"
            #include "kernel/_kernel_types.h.glsl"
            #undef LOOKUP
            #include "kernel/kernel_globals.h.glsl"
        """
        code += f"""
            struct hitPayload2
            {{
            vec4 throughput;
            float pad[{prdsize} -16];
            }};
            layout(location = {loc}) callableDataInNV hitPayload2 prd;
            void main(){{
            float a = 0.f;\n
            """

        for i in range(size):
            code += f" float aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{i};"
            for j in range(128):
                code += f" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{i} += {j};\n"
            code += f" a  += aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{i};\n"
        code += f" prd.throughput = vec4({float(n%10/10)},{n/10/5},0.2,a / (a + 1.0));}}\n\n"

        p      = preproc("D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders") 
        p._write(p.Dir + f"\\rt\\bl3\\tmp\\prg{n}.rcall.glsl",code)
    def pseudo2(self,size,n,loc,prdsize,income= True):
        code =  """
            #version 460
            #extension GL_NV_ray_tracing : require
            #extension GL_GOOGLE_include_directive : enable
            #define PUSH_POOL_SC
            #define SET_KERNEL 2

            #include "kernel_compat_vulkan.h.glsl"
            #include "kernel/_kernel_types.h.glsl"
            #undef LOOKUP
            #include "kernel/kernel_globals.h.glsl"
        """
        if income:
            code += f"""
                struct hitPayload0
                {{
                vec4 throughput;
                float pad[{prdsize[0]} -16];
                }};

                layout(location = {loc[0]})   callableDataInNV hitPayload0 prd1;
                //layout(location = {loc[1]}) callableDataInNV hitPayload0 prd0;

                void main(){{
                float a = 0.f;\n
                """
        else:
            code += f"""
                struct hitPayload0
                {{
                vec4 throughput;
                float pad[{prdsize[0]} -16];
                }};
                struct hitPayload1
                {{
                vec4 throughput;
                float pad[{prdsize[1]} -16];
                }};
                layout(location = {loc[0]}) callableDataInNV hitPayload0 prd0;
                layout(location = {loc[1]}) callableDataNV hitPayload1 prd1;

                void main(){{
                float a = 0.f;\n
                """


        for i in range(size):
            code += f" float aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{i};"
            for j in range(128):
                code += f" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{i} += {j};\n"
            code += f" a  += aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa{i};\n"
        if income:
            code += f"// prd0.throughput =  vec4({float(n%10/10)},{n/10/5},0.2,a / (a + 1.0));\n\n"
            code += f" prd1.throughput =  vec4({float(n%10/10)},{n/10/5},0.2,a / (a + 1.0));}}\n\n"
        else:
            code += f" executeCallableNV({loc[2]}, {loc[1]});\n\n"
            code += f" prd0.throughput =   mix( prd1.throughput, vec4({float(n%10/10)},{n/10/5},0.2,a / (a + 1.0)) ,0.3);}}\n\n"


        p      = preproc("D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders") 
        p._write(p.Dir + f"\\rt\\bl3\\tmp\\prg{n}.rcall.glsl",code)               

if COMPILE:   
    cross = spirvcross()
    #aeospirv.echo("\\rt\\bl2\\prg","rgen")
    #aeospirv.echo("\\rt\\bl2\\prg","rmiss")
    #aeospirv.echo("\\rt\\bl2\\shadow","rmiss")
    #aeospirv.echo("\\rt\\bl2\\hit1","rchit")
    #aeospirv.echo("\\rt\\bl2\\hit2","rchit")
    #aeospirv.echo("\\rt\\bl2\\svm1","rcall")
    #aeospirv.echo("\\rt\\bl2\\svm2","rcall")
    #aeospirv.echo("\\rt\\bl2\\svm3","rcall")

    #rt = [ ("tonemapping","frag")]
    #folder = "\\fullscreen"
    #cross.compile(folder + "tonemapping","frag")
 


    #rt = [("prg1","rcall")]
    cross.Opt = f" -Os "
    cross.Opt = f" "
    #cross.SetBinding = f" --rsb  topLevelAS 0 0 --rsb  image 0 1 --rsb  CameraProperties 1 0 --rsb KD 2 0 --rsb KG 2 1 "
    cross.SetBinding = f""
    #cross.Opt = f" "
    folder  = "\\fullscreen\\"
    cross.I =  "" #"D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders\\intern"
    cross.compile_elim(folder,"tonemapping","frag",tmp= False)   


    #aeospirv.echo("\\tmp\\bufferref4","vert")
    #aeospirv.echo("\\tmp\\bufferref4","frag")
    #aeospirv.echo("\\rt\\comp\\prg5","comp")
    #aeospirv.echo("\\rt\\comp\\prg6","comp")
    #aeospirv.echo("\\fullscreen\\prg4","frag")
    #aeospirv.echo("\\rt\\comp\\copy","comp")
    #aeospirv.echo("\\rt\\comp\\prg7","comp")
    import time
    time.sleep(2)

from parse_variables import *

if OPT:
    c = converter()
    c.parser("/rt/bl2/_svmTest.rcall")

if COMPILE_SAHDOW:
    cross = spirvcross()
    ELIM     = False
    SHORTCUT = True
    cross.Opt = f" -Os "
    cross.Opt = f" "
    #cross.SetBinding = f" --rsb  topLevelAS 0 0 --rsb  image 0 1 --rsb  CameraProperties 1 0 --rsb KD 2 0 --rsb KG 2 1 "
    cross.SetBinding  = f""
    rt = [
         ("prg0","rgen"),
         ("prg0","rmiss"),
         ("prg1","rmiss"),
         ("prg0","rchit"),
         ("prg0","rahit"),
         ("prg1","rchit"),
    ]
    #cross.Opt = f" "
    folder = "\\rt\\shadow\\"
    cross.I =  "D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders\\rt\\shadow"
    if SHORTCUT:
        for (name,stage) in rt:
            cross.compile_elim(folder,name,stage)

if COMPILE_ELIM:   

    cross = spirvcross()
    rgb = [0 ,1061997774  ,1017479904]
    cross.rgb(rgb)
    cross.shaderFlag(1610612742)
    cross.pathrayFlag(1342177280)
    cross.sdFlag(65548)

    PSU_GEN = False
    size  = 8
    num   = 24
    loc   = 0
    
    if PSU_GEN:
        for i in range(7,10):
            cross.pseudo2(size,i,[1,4],[128])
        for i in range(10,num):
            cross.pseudo(size + 4,i,2,512)


    ELIM     = False
    SHORTCUT = True

    #rt = [ ("prg5","rcall")]
    #150994944  152801280
    #]
    #rt  = [(f"prg{i}","rcall") for i in range(5,num)]
    #rt  = [(f"prg{i}","rcall") for i in [2,3,4]]
    #rt  += [("prg0","rgen"),("prg1","rchit")]

    rt = [
         ("prg0","rgen"),
         ("prg1","rgen"),
         ("prg0","rmiss"),
         ("prg1","rmiss"),
         ("prg2","rmiss"),
         ("prg0","rchit"),
         ("prg0","rahit"),
         ("prg1","rahit"),
         ("prg2","rahit"),
         ("prg0","rcall"),
         ("prg1","rcall"),
         ("prg2","rcall"),
         ("prg3","rcall"),
         ("prg4","rcall"),
         ("prg5","rcall"),
         ("prg6","rcall"),
         ("prg7","rcall"),
         ("prg8","rcall"),
         ("prg9","rcall"),
         ("prg10","rcall"),
         ("prg11","rcall")
    ]

    #rt = [("prg1","rcall")]
    cross.Opt = f" -Os "
    cross.Opt = f" "
    #cross.SetBinding = f" --rsb  topLevelAS 0 0 --rsb  image 0 1 --rsb  CameraProperties 1 0 --rsb KD 2 0 --rsb KG 2 1 "
    cross.SetBinding = f""
    #cross.Opt = f" "
    folder  = "\\rt\\bl3\\"
    cross.I =  "D:\\C\\Aeoluslibrary\\libAeolusOptix\\shaders\\intern"
    #cross.I =  "D:\\C\\Aeoluslibrary\\test\\blender\\intern"
    if SHORTCUT:
        for (name,stage) in rt:
            cross.compile_elim(folder,name,stage)
    else:
        cross.removeTmp(folder)
        for (name,stage) in rt:
            c = converter()
            cross.toSpirv(folder,name,stage,inter = ELIM)
            if ELIM :
                c.SetBindings = "topLevelAS 0 0 image 0 1 CameraProperties 1 0 KD 2 0 KG 2 1 Alloc 2 2 _tex_ 3 0 _samp_ 3 1"
                c.parser(cross.tmpfile)
                cross.compile_elim(folder,name,stage)

if COMPILE_ELIM_BG:   
    
    cross = spirvcross()
    ELIM     = False
    SHORTCUT = True

    rt = [

         ("prg1","rgen"),
         ("prg0","rmiss"),
         ("prg0","rchit"),
         ("prg0","rcall"),
         ("prg1","rcall"),
         ("prg2","rcall"),
         ("prg3","rcall"),
         ("prg4","rcall"),
         ("prg5","rcall"),
         ("prg6","rcall"),
         ("prg7","rcall"),
         ("prg8","rcall"),
         ("prg9","rcall"),
    ]
      
    #rt = [ ("prg5","rcall")]
    #150994944  152801280
    #]
    #rt  = [(f"prg{i}","rcall") for i in range(5,num)]
    #rt  = [(f"prg{i}","rcall") for i in [2,3,4]]
    #rt  += [("prg0","rgen"),("prg1","rchit")]
    rt = [ ("prg0","rgen")]

    cross.Opt = f" -Os "
    cross.Opt = f" "
    #cross.SetBinding = f" --rsb  topLevelAS 0 0 --rsb  image 0 1 --rsb  CameraProperties 1 0 --rsb KD 2 0 --rsb KG 2 1 "
    cross.SetBinding = f""
    #cross.Opt = f" "
    folder = "\\rt\\bl_bg\\"


    if SHORTCUT:
        for (name,stage) in rt:
            cross.compile_elim(folder,name,stage)
    else:
        cross.removeTmp(folder)
        for (name,stage) in rt:
            c = converter()
            cross.toSpirv(folder,name,stage,inter = ELIM)
            if ELIM :
                c.SetBindings = "topLevelAS 0 0 image 0 1 CameraProperties 1 0 KD 2 0 KG 2 1 Alloc 2 2 _tex_ 3 0 _samp_ 3 1 BG_IN 4 0 BG_IN 4 1 "
                c.parser(cross.tmpfile)
                cross.compile_elim(folder,name,stage)


import subprocess

class TextExe:
    def __init__(self):
        pass
    def testlibtestAeolus(self):
        #global f3_cache
        #if n in f3_cache: return f3_cache[n]
        dir = "D:\\C\\Aeoluslibrary\\out\\build\\AeolusDebug\\libtestAeolus\\Debug"
        cmd = f"{dir}/libtestAeolus.exe"
        subprocess.call(cmd.split())

if TESTEXE:
    t = TextExe()
    for i in range(100):
        t.testlibtestAeolus()