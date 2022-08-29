import os
import argparse
import json
import numpy as np
"""


Test Workflow

   * Check Configuration Extensions .
   * Check Gpu Memory Spec.
   * Check Gpu SM ,SG size.  
   * Test Unit Callable Shader (check payload)
   * Test Render Kerneltexture data ready.

     gl_WarpsPerSMNV   32    gl_SubgroupSize  32

reference document
 +https://github.com/KhronosGroup/GLSL/blob/master/extensions/nv/GLSL_NV_ray_tracing.txt
 +https://github.com/KhronosGroup/GLSL/blob/master/extensions/nv/GLSL_NV_shader_sm_builtins.txt
 +https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf (Compute Capability P.43)
"""

class ProfileMan:
    SIZE = (512,512)
    def __init__(self,dir  = None):
        if dir:
            os.chdir(dir)
        Dirs  = os.listdir()
        assert ("libAeolus" in Dirs and "libAeolusOptix" in Dirs and "libvkmm" in Dirs) , f"Please Set current directory to VulkanRaytracingCycles Folder."
        self.cwd =  os.getcwd()
        self.srcpath = f"{self.cwd}\\libAeolusOptix\\shaders"
        self.path = f"{self.cwd}\\data\\profile"
    def parse(self,file = "example.json"):
        data = []
        with open( f"{self.path}//{file}", 'r') as s:
            data = json.load(s)
        return data
    def check_dispatch(self,file):
        self.data = self.parse(file)
        assert len(self.data) ==  (self.SIZE[0] * self.SIZE[1] ),f"LengthError Expect {(self.SIZE[0] * self.SIZE[1] )} !=  {len(self.data)}"
       
        data = np.array(self.data)

        xdata = data.reshape((self.SIZE[0]*self.SIZE[1] ,4 ))

        VAL = np.sum(np.arange(0,self.SIZE[0]))
        for d in xdata[:,0].reshape((self.SIZE[0],self.SIZE[1])):
            assert np.sum(d) == VAL ,f"DispatchError dimension X Expect {VAL} != {np.sum(d)}."

        ydata = data.reshape((self.SIZE[0]*self.SIZE[1] ,4 ))
        for i,d in enumerate(ydata[:,1].reshape((self.SIZE[0],self.SIZE[1]))):
            VAL = self.SIZE[0]*i
            assert np.sum(d) == VAL ,f"DispatchError dimension Y Expect {VAL} != {np.sum(d)}."

        print(f"TestPass check_dispatch.")

    def check_sm(self,file1,file2):
        """
        Data Expected  ===> [offset,gl_SMIDNV,gl_WarpIDNV,gl_SubgroupInvocationID]

        All memory for ShaderClosures is allocated in advance and then indexed per SM,
        counting atomically and used in sequence to make it available in the SM. 
        The formula is as follows.
        
        atomic_offset  =  int((( gl_SMIDNV *  gl_WarpsPerSMNV  + gl_WarpIDNV ) * gl_SubgroupSize  +  gl_SubgroupInvocationID ) * MAX_CLOSURE);
        
        SM spec is as follows.
         [gl_SMCountNV,gl_WarpsPerSMNV , gl_SubgroupSize , MAX_CLOSURE];

        !TODO Need more details about WARPSize per SM.
        As for the WARP size per SM, there are some details unknown, so if it is not less than 32, it shall be 32.
        """

        self.data = self.parse(file1)
        self.spec = self.parse(file2)
        print(self.spec)

        SMCount,WarpPerSM,SgSize,MaxSC = self.spec
        
        assert len(self.data) ==  (self.SIZE[0] * self.SIZE[1] ),f"LengthError Expect {(self.SIZE[0] * self.SIZE[1] )} !=  {len(self.data)}"
       
        data = np.array(self.data)

        data = data.reshape((self.SIZE[0]*self.SIZE[1] ,4 ))
    
        smid  = data[:,1]
        smids = list(set(smid))

        wid  = data[:,2]
        wids = list(set(wid))

        sgid  = data[:,3]
        sgids = list(set(sgid))


        print(f"Check_sm  MaxSMID {max(smids)}.")
        assert SMCount <= 40, f"SMError max sm  {WarpPerSM} > 40"
        assert max(smids) < SMCount,f"SMError max sm {SMCount} < {max(smids)}"

        print(f"Check_sm  MaxWarpID {max(wids)}.")
        assert WarpPerSM >= 32, f"SMError max warp {WarpPerSM} < 32"
        assert max(wids) < 32,f"SMError max warp {WarpPerSM} < {max(wids)}"

        print(f"Check_sm  MaxSGID {max(sgids)}.")
        assert SgSize <= 32, f"SMError max Sgsize {SgSize} > 32"
        assert max(sgids) < SgSize,f"SMError max warp {SgSize} < {max(sgids)}"


        print(f"TestPass check_sm.")


if __name__ == '__main__':
    from enum import Enum
    class Mode(Enum):
        Dispatch    = 'Dispatch'
        SM          = 'SM'
        def __str__(self):
            return self.value

    Dir_Current = os.getcwd()
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-m', '--mode', type= Mode, choices=list(Mode),default="Dispatch")
    parser.add_argument('-d', '--dir',default=Dir_Current)
    parser.add_argument('-f', '--file',default= "weight.json")
    
    args = parser.parse_args()

    pman  = ProfileMan(args.dir)
    if args.mode == Mode.Dispatch:
        pman.check_dispatch(args.file)
    elif args.mode == Mode.SM:
        pman.check_sm(args.file,"index.json")
    else:
        print(f"Not Found Mode {args.mode} ")


"""
python profile.py -m Dispatch -f weight.json
python profile.py -m SM -f weight.json
"""
