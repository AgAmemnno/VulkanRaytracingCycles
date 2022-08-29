import os
import sys
import argparse
import subprocess
import struct
class spirvcross:
    def __init__(self,dir  = None):
        if dir:
            os.chdir(dir)
        Dirs  = os.listdir()
        assert ("libAeolus" in Dirs and "libAeolusOptix" in Dirs and "libvkmm" in Dirs) , f"Please Set current directory to VulkanRaytracingCycles Folder."
        self.cwd =  os.getcwd()
        self.srcpath = f"{self.cwd}\\libAeolusOptix\\shaders"
        self.path = f"{self.cwd}\\data\\shaders"
        self.I =  f"{self.cwd}\\libAeolusOptix\\shaders\\intern"
        self.cacheDebug = {}


    def compile_elim(self,folder,name,stage,tmp= True,namespv= None,):
        env           = "spirv1.5" # "vulkan1.2" # "vulkan1.2" #
        if tmp:
            glsl          =  self.srcpath + folder + "tmp\\" + name + "." + stage +  ".glsl"
        else:
            glsl          =  self.srcpath + folder + name + "." + stage +  ".glsl"

        if namespv is None:
            namespv = name

        spirv         =  self.path + folder  + namespv + "." + stage +  ".spv"
        
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



def Exec_RT(dir,mode = "RT"):

    cross = spirvcross(dir)
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

    if mode == "t1":
        rt[0] = ("test_dispatch","rgen","prg0")
    elif mode == "t2":
        rt[0] = ("test_sm","rgen","prg0")

    #rt = [("prg1","rcall")]
    cross.Opt = f" -Os "
    cross.Opt = f" "
    #cross.SetBinding = f" --rsb  topLevelAS 0 0 --rsb  image 0 1 --rsb  CameraProperties 1 0 --rsb KD 2 0 --rsb KG 2 1 "
    cross.SetBinding = f""
    #cross.Opt = f" "
    folder  = "\\rt\\bl3\\"

    if SHORTCUT:
        for d in rt:
            if len(d) == 3:
                cross.compile_elim(folder,d[0],d[1],namespv= d[2])
            else:
                cross.compile_elim(folder,d[0],d[1])

    else:
        assert False,f"NIL TODO Compile into datails."
        cross.removeTmp(folder)
        for (name,stage) in rt:
            c = converter()
            cross.toSpirv(folder,name,stage,inter = ELIM)
            if ELIM :
                c.SetBindings = "topLevelAS 0 0 image 0 1 CameraProperties 1 0 KD 2 0 KG 2 1 Alloc 2 2 _tex_ 3 0 _samp_ 3 1"
                c.parser(cross.tmpfile)
                cross.compile_elim(folder,name,stage)

if __name__ == '__main__':

    from enum import Enum
    class Mode(Enum):
        RT              = 'RT'
        TestDispatch    = 'TestDispatch'
        TestSM          = 'TestSM'

        def __str__(self):
            return self.value

    Dir_Current = os.getcwd()
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-m', '--mode', type= Mode, choices=list(Mode),default="RT")
    parser.add_argument('-d', '--dir',default=Dir_Current)

    args = parser.parse_args()

    if args.mode == Mode.RT:
        Exec_RT(args.dir)
    elif args.mode == Mode.TestDispatch:
        Exec_RT(args.dir,mode = "t1")
    elif args.mode == Mode.TestSM:
        Exec_RT(args.dir,mode = "t2")
    else:
        print(f"Not Found Mode {args.mode} ")


"""
python shaders/compile.py -m RT
python shaders/compile.py -m TestDispatch
python shaders/compile.py -m TestSM
"""
