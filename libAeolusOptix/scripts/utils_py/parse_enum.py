import sys
_PARSE_DEBUG = True
print(f" DEBUG     {_PARSE_DEBUG}")



test = """typedef enum PassType {
  PASS_NONE = 0,

  /* Main passes */
  PASS_COMBINED = 1,
  PASS_DEPTH,
  PASS_NORMAL,
  PASS_UV,
  PASS_OBJECT_ID,
  PASS_MATERIAL_ID,
  PASS_MOTION,
  PASS_MOTION_WEIGHT,
#ifdef __KERNEL_DEBUG__
  PASS_BVH_TRAVERSED_NODES,
  PASS_BVH_TRAVERSED_INSTANCES,
  PASS_BVH_INTERSECTIONS,
  PASS_RAY_BOUNCES,
#endif
  PASS_RENDER_TIME,
  PASS_CRYPTOMATTE,
  PASS_AOV_COLOR,
  PASS_AOV_VALUE,
  PASS_ADAPTIVE_AUX_BUFFER,
  PASS_SAMPLE_COUNT,
  PASS_CATEGORY_MAIN_END = 31,

  PASS_MIST = 32,
  PASS_EMISSION,
  PASS_BACKGROUND,
  PASS_AO,
  PASS_SHADOW,
  PASS_LIGHT, /* no real pass, used to force use_light_pass */
  PASS_DIFFUSE_DIRECT,
  PASS_DIFFUSE_INDIRECT,
  PASS_DIFFUSE_COLOR,
  PASS_GLOSSY_DIRECT,
  PASS_GLOSSY_INDIRECT,
  PASS_GLOSSY_COLOR,
  PASS_TRANSMISSION_DIRECT,
  PASS_TRANSMISSION_INDIRECT,
  PASS_TRANSMISSION_COLOR,
  PASS_VOLUME_DIRECT = 50,
  PASS_VOLUME_INDIRECT,
  /* No Scatter color since it's tricky to define what it would even mean. */
  PASS_CATEGORY_LIGHT_END = 63,

  PASS_BAKE_PRIMITIVE,
  PASS_BAKE_DIFFERENTIAL,
  PASS_CATEGORY_BAKE_END = 95
} PassType;




typedef enum AttributeStandard {
  ATTR_STD_NONE = 0,
  ATTR_STD_VERTEX_NORMAL,
  ATTR_STD_FACE_NORMAL,
  ATTR_STD_UV,
  ATTR_STD_UV_TANGENT,
  ATTR_STD_UV_TANGENT_SIGN,
  ATTR_STD_VERTEX_COLOR,
  ATTR_STD_GENERATED,
  ATTR_STD_GENERATED_TRANSFORM,
  ATTR_STD_POSITION_UNDEFORMED,
  ATTR_STD_POSITION_UNDISPLACED,
  ATTR_STD_MOTION_VERTEX_POSITION,
  ATTR_STD_MOTION_VERTEX_NORMAL,
  ATTR_STD_PARTICLE,
  ATTR_STD_CURVE_INTERCEPT,
  ATTR_STD_CURVE_RANDOM,
  ATTR_STD_PTEX_FACE_ID,
  ATTR_STD_PTEX_UV,
  ATTR_STD_VOLUME_DENSITY,
  ATTR_STD_VOLUME_COLOR,
  ATTR_STD_VOLUME_FLAME,
  ATTR_STD_VOLUME_HEAT,
  ATTR_STD_VOLUME_TEMPERATURE,
  ATTR_STD_VOLUME_VELOCITY,
  ATTR_STD_POINTINESS,
  ATTR_STD_RANDOM_PER_ISLAND,
  ATTR_STD_NUM,

  ATTR_STD_NOT_FOUND = ~0
} AttributeStandard;

"""

def log(s):
    print(s)

def debug(s):
    global _PARSE_DEBUG
    if _PARSE_DEBUG:print(s)
    

def Error(s):
    print(s)
    exit(-1)

def toInt(st):
    try:
        a = eval(st)
        if type(a) == int:
            return a
    except NameError as e:
        log(f"not Enumerate Value  ==> pass through exception  {st} ")
        return None
    except:
        if  st.find("~0") > 0:
            return -1
        print("Unexpected error:", sys.exc_info()[0])
        raise

    Error(f" can not evaluate  {st}  ")

import re
import functools

Definition = {}
def _TYPE2(t):
    return "uint  {}".format(t.rstrip())
attr = {
    "TYPE0" : "  typedef uint  {};\n",
    "TYPE" : "   const   uint  {} = {};\n",
   "TYPE2" : _TYPE2,
    "enum" : 0,
    "txt" :"",
    "name":""
}

attr = {
    "TYPE0" : "#define {} uint\n",
    "TYPE" :  "uint  {} = {};\n",
    "TYPE2" : _TYPE2,
    "TYPE3" : "const uint  {} = {};\n",
    "TYPE4" : "const uint  {};\n",
    "enum" : 0,
    "txt" :"",
    "name":""
}

def _TYPE2_1(t):
    q = t.split('=')
    q[1] = q[1].replace("\n","").replace(" ","").replace("(unsignedint)","")
    return "#define {} uint({})\n".format(q[0],q[1])

attr = {
    "TYPE0" : "#define {} uint\n",
    "TYPE" :  "#define {} uint({})\n",
    "TYPE2" : _TYPE2_1,
    "TYPE3" : "#define {} uint({})\n",
    "TYPE4" : "const uint  {};\n",
    "enum" : 0,
    "txt" :"",
    "name":""
}


se = re.search(r"enum (.*) {([\S\n ]+)}", test, flags=re.MULTILINE)
def COMMENTOUT(rec):
    rec = re.sub("(//.*[\n]+)","",rec)
    rec = re.sub("(/\*((?!\*/).|[\r\n])*\*/)","",rec)
    return rec

def IFDEF(tex):
    debug("< ifdef parse ")
    mod  = ""
    _tex = ""
    piv  = 0
    for block in  re.findall(r"#if[def]* (.*)\n([\s\S\n]*?)#endif", tex):
        if len(block) != 2:Error("ifdef 0")
        sp = re.search(r"#if[def]* (.*)\n([\s\S\n]*?)#endif", tex[piv:]).span()
        if block[0] in Definition:
            debug(f"  < match {block[0]} ")
            _tex += tex[piv:sp[1]]
        else:
            debug(f"  < elim  {block[0]}  \n {block[1]}")
            _tex += tex[piv:sp[0]]
        piv = sp[1]
    _tex += tex[piv:]
    debug(f"\n\n before =>>>> \n{tex}  \n\n after =>>>>  \n{ _tex }")
    return _tex

def ENUM_MEMBER(tex,pre):
    return tex.lstrip().startswith(pre)

def ENUM_PARSE(tex,attr):
    debug(f"parse line {tex}")
    lst = tex.split("=")
    if len(lst) == 1:
        attr["txt"] = attr["TYPE"].format( lst[0].rstrip() ,attr["enum"])
    elif  len(lst) == 2:
        attr["txt"]  = attr["TYPE2"](tex)
        num = toInt(lst[1])
        if num == None:
            attr["enum"] -= 1
        else:
            attr["enum"]  = num
    else:
        Error("enum_parse 0")
    attr["enum"] += 1
    attr["name"] = lst[0]
    return attr["txt"]
def ENUM_PARSE_CONST(tex,attr):
    debug(f"parse line {tex}")
    lst = tex.split("=")
    if len(lst) == 1:
        attr["txt"] = attr["TYPE3"].format( lst[0].rstrip() ,attr["enum"])
    elif  len(lst) == 2:
        attr["txt"]  = attr["TYPE4"].format(tex.rstrip())
        num = toInt(lst[1])
        if num == None:
            attr["enum"] -= 1
        else:
            attr["enum"]  = num
    else:
        Error("enum_parse 0")
    attr["enum"] += 1
    attr["name"] = lst[0]
    return attr["txt"]


def ENUM2CONST(file):
    with open(file) as fp:
        code = fp.read()
    piv = 0
    CODE  = ""
    for ma in  re.findall(r"\n[a-z ]*?enum (.*) {([\s\S\n]*?);", code):
        if len(ma) != 2:Error("enum 0 failed")
        sp    = re.search(r"\n[a-z ]*?enum (.*) {([\s\S\n]*?);", code[piv:]).span()
        CODE += code[piv:piv + sp[0]]
        piv   = piv + sp[1]
        block = IFDEF(ma[1])
        dst = f"\n//modify => enum {ma[0]} \n"
        dst += attr["TYPE0"].format(ma[0])
        first        =  re.search(r"([A-Z]+_[A-Z]+)[\s\S\n]*?,", block)
        pre          = first.group(0).lstrip().split("_")[0]
        log(f"=========== {first.group(0)}   prefix = {pre}")

        attr["enum"] = 0
        for line in  re.findall( fr"{pre}_([\s\S\n]*?),",block):
            line = f"{pre}_{line}"
            debug(f" this line  = {line}")
            if ENUM_MEMBER(line,pre):
                dst += ENUM_PARSE(line,attr)
        ltx = attr["name"]
        check = list(filter(('').__ne__, block.split(",")))
        for n,last in enumerate(check[-1::-1]):
           if last.find(ltx) > 0:
               tx = ""
               for i in check[(-n):]:
                   tx += i
               log(f" last  member check   {last}  ==  {ltx}   TX N{n}   {tx} ")
               add = False
               for reg in [pre,r"NUM" ,r"NBUILTIN"]:
                   last = re.search(r"([\s\S\n]*?)(" + reg + r"_[\s\S\n]*?)}", tx)
                   if last:
                       add = True
                       last = last.group(2)
                       break

               if add:
                   log(f" >>>>>>>>>>>>>>>>>>>>>>>>>>> final member check   {last}  ")
                   debug(f" last line  = {last}")
                   dst += ENUM_PARSE(last, attr)
               break
        dst += "//modified ==> " + ma[0] + "\n\n\n"
        print(dst)
        CODE += dst
    CODE   += code[piv:]
    tofile  = file.replace(".h",".h.glsl")
    import os
    if os.path.exists(tofile):
      os.remove(tofile)
    CODE = post_SubALL(CODE)
    
    with open(tofile, "x") as fp:
        fp.writelines(CODE)

def _ENUM2CONST(file):
    with open(file) as fp:
        code = fp.read()
    
    tofile = file.replace(".in","")
    import os
    if os.path.exists(tofile):
      os.remove(tofile)
    with open(tofile, "x") as fp:
        fp.writelines(code)


def post_SubALL(code):
    (code,num)  = re.subn(r"__","_",code)
    (code,num)  = re.subn(r"typedef[(?!struct)\S ]*struct[\s]+([_a-zA-Z0-9]*)(((?!\1).|\n)*)(\1)",r" struct \1\2",code) 
    (code,num)  = re.subn(r"[\s]+struct[\s]+(.*)[\s]+{(((?!\1).|\n)*)}[\s]*\1",r"\n\n struct _\1 { \2 }\1",code)  
    (code,num)  = re.subn(r"[\s]+struct[\s]+(((?!{).|\n)*);",r" \n \1;",code)  
    return code

import os

class preproc:
    def __init__(self,dir):
        self.Dir = dir
    def openfullpath(self,f):
        with open(f ,encoding='utf8') as fp:
            self.code = fp.read()
    def open(self,f):
        self.name  = f
        self.file =  self.Dir + f
        with open(self.file) as fp:
            self.code = fp.read()
    def write(self):
        tofile = self.file.replace(".h",".h.glsl")
        self._write(tofile,self.code)
    def writeccl(self):
        tofile = self.file.replace(".h","_ccl.h")
        code = self.code.replace("KERNEL_TEX(","KERNEL_TEX(ccl::")
        code = code.replace("KERNEL_TEX(ccl::type,","KERNEL_TEX(type,")
        self._write(tofile,code)
        self._write("D:\\C\\Aeoluslibrary\\libAeolusOptix\\cycles\\kernel\\kernel_textures_ccl.h",code)

    def writeraw(self):
        file = self.file
        self._write(file,self.code)
    def writeDir(self,dir,suf):
        tofile = dir + self.name + suf
        self._write(tofile,self.code)
    def _write(self,tofile,code):
        if os.path.exists(tofile):
            os.remove(tofile)
        with open(tofile, "x") as fp:
            fp.writelines(code)





class post_optional:
    test_code =  """/* Versions of functions which are safe for fast math. */
    #define __KERNEL_VULKAN__
    ccl_device_inline bool isnan_safe(float f)
{
  unsigned int x = __float_as_uint(f);
  return (x << 1) > 0xff000000u;
}
    """
    @classmethod
    def underscore(cls,code):
        (code,num)  = re.subn(r"__","_",code)
        debug(f"underscore __ to _  NUMS {num}   ==>>   \n\n {code} \n\n")
        return code

class svm_conv:
    test_code =  """/* Versions of functions which are safe for fast math. */
    #  ifdef __HAIR__
/* Set up the hair closure. */
ccl_device int bsdf_principled_hair_setup(ShaderData *sd, PrincipledHairBSDF *bsdf)
{
  bsdf->type = CLOSURE_BSDF_HAIR_PRINCIPLED_ID;
  bsdf->v = clamp(bsdf->v, 0.001f, 1.0f);
  bsdf->s = clamp(bsdf->s, 0.001f, 1.0f);
  /* Apply Primary Reflection Roughness modifier. */
  bsdf->m0_roughness = clamp(bsdf->m0_roughness * bsdf->v, 0.001f, 1.0f);

  /* Map from roughness_u and roughness_v to variance and scale factor. */
  bsdf->v = sqr(0.726f * bsdf->v + 0.812f * sqr(bsdf->v) + 3.700f * pow20(bsdf->v));
  bsdf->s = (0.265f * bsdf->s + 1.194f * sqr(bsdf->s) + 5.372f * pow22(bsdf->s)) * M_SQRT_PI_8_F;
  bsdf->m0_roughness = sqr(0.726f * bsdf->m0_roughness + 0.812f * sqr(bsdf->m0_roughness) +
                           3.700f * pow20(bsdf->m0_roughness));

  /* Compute local frame, aligned to curve tangent and ray direction. */
  float3 X = safe_normalize(sd->dPdu);
  float3 Y = safe_normalize(cross(X, sd->I));
  float3 Z = safe_normalize(cross(X, Y));

  /* h -1..0..1 means the rays goes from grazing the hair, to hitting it at
   * the center, to grazing the other edge. This is the sine of the angle
   * between sd->Ng and Z, as seen from the tangent X. */

  /* TODO: we convert this value to a cosine later and discard the sign, so
   * we could probably save some operations. */
  float h = (sd->type & (PRIMITIVE_CURVE_RIBBON | PRIMITIVE_MOTION_CURVE_RIBBON)) ?
                -sd->v :
                dot(cross(sd->Ng, X), Z);

  kernel_assert(fabsf(h) < 1.0f + 1e-4f);
  kernel_assert(isfinite3_safe(Y));
  kernel_assert(isfinite_safe(h));

  bsdf->extra->geom = make_float4(Y.x, Y.y, Y.z, h);

  return SD_BSDF | SD_BSDF_HAS_EVAL | SD_BSDF_NEEDS_LCG;
}

#  endif /* __HAIR__ */

/* Given the Fresnel term and transmittance, generate the attenuation terms for each bounce. */
ccl_device_inline void hair_attenuation(KernelGlobals *kg, float f, float3 T, float4 *Ap)
{
  /* Primary specular (R). */
  Ap[0] = make_float4(f, f, f, f);

  /* Transmission (TT). */
  float3 col = sqr(1.0f - f) * T;
  Ap[1] = combine_with_energy(kg, col);

  /* Secondary specular (TRT). */
  col *= T * f;
  Ap[2] = combine_with_energy(kg, col);

  /* Residual component (TRRT+). */
  col *= safe_divide_color(T * f, make_float3(1.0f, 1.0f, 1.0f) - T * f);
  Ap[3] = combine_with_energy(kg, col);

  /* Normalize sampling weights. */
  float totweight = Ap[0].w + Ap[1].w + Ap[2].w + Ap[3].w;
  float fac = safe_divide(1.0f, totweight);

  Ap[0].w *= fac;
  Ap[1].w *= fac;
  Ap[2].w *= fac;
  Ap[3].w *= fac;
}
    """
  
    test_code2 = """

    typedef ccl_addr_space struct PrincipledHairExtra {
  /* Geometry data. */
  float4 geom;
} PrincipledHairExtra;

    typedef ccl_addr_space struct PrincipledHairBSDF {
  SHADER_CLOSURE_BASE;
  // Absorption coefficient. 
  float3 sigma;
  // Variance of the underlying logistic distribution. 
  float v;
  // Scale factor of the underlying logistic distribution. 
  float s;
  // Cuticle tilt angle. 
  float alpha
  ;
  // IOR. 
  float eta;
  // Effective variance for the diffuse bounce only. 
  float m0_roughness;
  // Extra closure. 
  PrincipledHairExtra* extra;
} PrincipledHairBSDF;
"""
    test_code3 =  """  delta_phi(int p, float gamma_o, float gamma_t)
    {
  while (a > M_PI_F) {
    a -= M_2PI_F;
  }
  while (a < -M_PI_F) {
    a += M_2PI_F;
  }
  return a;
}

        
    """
    BRACE  =  r"{(?>[^{}]+|(?R))+}"
    SIZE4  = "#define {0}{1}(bsdf) bsdf.data[{2}]\n" #.format(n[1],stride)
    SIZE12 = "#define {0}{1}(bsdf) vec4(bsdf.data[{2}], bsdf.data[{2}+1], bsdf.data[{2}+2],0.f)\n" #.format(n[1],stride)
    SIZE12_lval = "#define {0}{1}_lval(bsdf) {{ vec4 tmp =  {0}{1}(bsdf); tmp \n" #.format(n[1],stride)
    SIZE12_assign = "#define {0}{1}_assign(bsdf) bsdf.data[{2}] = tmp.x, bsdf.data[{2}+1] = tmp.y, bsdf.data[{2}+2] = tmp.z;}}\n" #.format(n[1],stride)
    SIZE16 = "#define {0}{1}(bsdf) vec4(bsdf.data[{2}], bsdf.data[{2}+1], bsdf.data[{2}+2], bsdf.data[{2}+3])\n" #.format(n[1],stride)
    SIZE16_lval = SIZE12_lval
    SIZE16_assign = "#define {0}{1}_assign(bsdf) bsdf.data[{2}] = tmp.x, bsdf.data[{2}+1] = tmp.y, bsdf.data[{2}+2] = tmp.z,bsdf.data[{2}+3] = tmp.w;}}\n" 
    EXTRA_NULL    =  "#define {0}_extra_NULL(bsdf) {{ bsdf.data[{1}]=FLT_MIN;  bsdf.data[{2}]=FLT_MIN;  }} \n"
    IS_EXTRA_NULL    =  "#define {0}is_extra_NULL(bsdf) (bsdf.data[{1}]==FLT_MIN && bsdf.data[{2}]==FLT_MIN )\n"
    cache_define    = {}
    def _extra_null(self,code,e0,e1):
        if self.func_render:
            self.code += self.EXTRA_NULL.format(self.stName,e0,e1-1)
            self.code += self.IS_EXTRA_NULL.format(self.stName,e0,e1-1)
        return re.subn(fr"([\s]*)({self.bsdf}|{self.bsdf}_a|{self.bsdf}_b)->extra[\s]*=[\s]*NULL",fr"{self.stName}_extra_NULL(\2)",code)
    def _size4(self,n,srd):
        if self.func_render:self.code += self.SIZE4.format(self.stName,n[1],srd)
        return 1
    def _size12(self,n,srd):
        if self.func_render:
            self.code += self.SIZE12.format(self.stName,n[1],srd)
            self.code += self.SIZE12_lval.format(self.stName,n[1],srd)
            self.code += self.SIZE12_assign.format(self.stName,n[1],srd)
        return 3 
    def _size16(self,n,srd):
        if self.func_render:
            self.code += self.SIZE16.format(self.stName,n[1],srd)
            self.code += self.SIZE16_lval.format(self.stName,n[1],srd)
            self.code += self.SIZE16_assign.format(self.stName,n[1],srd)
        return 4
    SIZEOF = {
            "float" :  _size4,
            "int"   :  _size4,
            "uint"  :  _size4,
            "float3" : _size12,
            "float4" : _size16,
        }
    def pointer(self,c):
        r = []
        for i in c:r += i.split("*")
        return r
    def members(self,_clos):
        member = []
        _clos = COMMENTOUT(_clos)
        _clos = _clos.replace("\n","").replace("{","").replace("}","").split(";")
        _clos = [i for i in _clos if i != ""]
        print(_clos)
        for i in _clos:
            n = i.split(" ")
            n = [i for i in n if i != ""]
            if len(n) == 2:
                member.append(self.pointer(self,n))
            elif len(n) == 3:
                member.append(n)
            elif len(n) ==0:continue
            elif n[0] == "SHADER_CLOSURE_BASE":continue
            else:
                Error(f" {n} closure struct parse")
        print(member)
        return member
    def args(self,_clos):
        _clos = COMMENTOUT(_clos)
        (_clos,num) = re.subn(r"[ \t]*(#ifdef|#ifndef)(.*)\n","",_clos)
        (_clos,num) = re.subn(r"[ \t]*#endif(.*)\n","",_clos)
        (_clos,num) = re.subn(r"[\s]*ccl_[a-z_]+[\)\s]+"," ",_clos)
        if num > 0:
            print(_clos)
        _clos = _clos.replace("\n","").split(",")
        _clos = [i for i in _clos if i != ""]
        member =[]
        for i in _clos:
            n = i.split(" ")
            n = [i for i in n if i != ""]
            if len(n) ==0:continue
            elif (n[0] == "const" and len(n) ==3) or (len(n) == 2):
                member.append(self.pointer(self,n))
            elif len(n) == 3:
                member.append(n)
            else:
                Error(f" {n} closure struct parse")
        return member
    def args_replace(self,co,body = False ):
        SC = "ShaderClosure"
        elem = []
        if hasattr(self,"bsdf"):
            elem.append(("sc",self.bsdf))
        if len(elem) ==0:return (co,0)
        if body:
            for e in elem:
                (co,num)  =  re.subn(fr"([,\s\(;]+){e[0]}([\s\.\-,;\)]+)",fr"\1{e[1]}\2",co)
        else:
            for e in elem:
                (co,num)  =  re.subn(fr"{SC}[\s]*\*[\s]*{e[0]}",fr"{SC} *{e[1]}",co) 
        return (co,num)
    @classmethod
    def functions(cls,code):
        import regex
        i = 0
        Names = []
        PLIST = []
        PCLIST = []
        CODE  = ""
        st = 0
        for it  in re.finditer(r"([a-zA-Z_0-9]+)\((((?!\)).|\n)*)\)[\s]*{" ,code):
            i += 1
            args = it.regs[2]
            (ast,aed) = args[0],args[1]
            if ast == aed :continue
            args = code[ast:aed]
            (args,anum) = cls.args_replace(cls,args)
            end  = it.regs[3][1]
            name = it.regs[1]
            name = code[name[0]:name[1]]
            if "_lval" in name or "_extra_NULL" in name: 
                continue
            cont =  regex.search(r"{(?>[^{}]+|(?R))+}" ,code[end:])
            if cont == None:
                Error(f"content None Error {__FILE__} {__LINE__}")
            (bst,bed) = (end+cont.regs[0][0],end+cont.regs[0][1])
            body = cont[0]
            if anum > 0:
                CODE += code[st:ast] + args
                st    = aed
                (body,anum) = cls.args_replace(cls,body,True)

            Names.append(name)
            print(name)
            for a in cls.args(cls,args):
                if a[0] == "const" and len(a) ==4:
                    (body,num)  = re.subn(fr"\*{a[3]}",fr"{a[3]}",body)
                    PCLIST.append( (a[0] +" " + a[1] + a[2],a[3]))
                elif a[0] != "const" and len(a) == 3:
                    (body,num)  = re.subn(fr"\*{a[2]}",fr"{a[2]}",body)
                    PLIST.append( (a[0],a[2]))

            CODE += code[st:bst] + body
            st    = bed
        CODE += code[st:]
        print(Names)
        print(f"nums {i}")
        return (CODE,list(set(PCLIST)) +  list(set(PLIST)) )
    @classmethod
    def def_functions(cls,code):
        import regex
        i = 0
        Names = []
        PLIST = []
        PCLIST = []
        CODE  = ""
        st = 0
        for it  in re.finditer(r"([A-Z_0-9]+)\((((?!\)).|\n)*)\)[\s]*\((((?!\)).|\n)*)\)[\s]*{" ,code):
            i += 1
            end  = it.regs[4][1]
            name = it.regs[1]
            name = code[name[0]:name[1]]
            if "_lval" in name or "_extra_NULL" in name: 
                continue
            args = it.regs[4]
            (ast,aed) = args[0],args[1]
            args = code[ast:aed]
            (args,anum) = cls.args_replace(cls,args)
            
            cont =  regex.search(r"{(?>[^{}]+|(?R))+}" ,code[end:])
            (bst,bed) = (end+cont.regs[0][0],end+cont.regs[0][1])
            body = cont[0]
            if anum > 0:
                CODE += code[st:ast] + args
                st    = aed
                (body,anum) = cls.args_replace(cls,body,True)

            Names.append(name)
            print(name)
            for a in cls.args(cls,args):
                if a[0] == "const" and len(a) ==4:
                    (body,num)  = re.subn(fr"\*{a[3]}",fr"{a[3]}",body)
                    PCLIST.append( (a[0] +" " + a[1] + a[2],a[3]))
                elif a[0] != "const" and len(a) == 3:
                    (body,num)  = re.subn(fr"\*{a[2]}",fr"{a[2]}",body)
                    PLIST.append( (a[0],a[2]))

            CODE += code[st:bst] + body
            st    = bed
        CODE += code[st:]
        print(Names)
        print(f"nums {i}")
        return (CODE,list(set(PCLIST)) +  list(set(PLIST)) )  
    @classmethod
    def closure(cls,NAME ,bsdf,code):
        PRECHAR = r"([\s\.\-\+\*\/(]+)"
        ExNAME =  NAME + "Extra"
        if  bsdf.lower() ==  "bsdf":
          STNAME =  NAME + bsdf
          bsdf   = bsdf.lower()
        else:
          STNAME =  NAME 
        cls.bsdf   =  bsdf
        cls.stName =  NAME + "_"
        cls.func_render = False
        if cls.stName not in cls.cache_define:
            cls.func_render = True
            cls.cache_define[cls.stName] = True
        
        i = 0 
        for fi  in re.findall(fr"typedef[(?!struct)\S ]*struct[\s]+{ExNAME}(((?!{ExNAME}).|\n)*){ExNAME};(.*)",code):
            exmember = cls.members(cls,fi[0])
            if i != 0:Error(f" STRUCT Parse {fi}  ")
            i+= 1
        i = 0 
        for fi  in re.findall(fr"typedef[(?!struct)\S ]*struct[\s]+{STNAME}(((?!{STNAME}).|\n)*){STNAME};",code):
            member = cls.members(cls,fi[0])
            if i != 0:Error(f" STRUCT Parse {fi}  ")
            i+= 1

        cls.code = ""
        stride   = 0

        for n in member:
            if len(n) ==2:
                size = cls.SIZEOF[n[0]](cls,n,stride)
                stride += size
                if size > 1:
                    (code,num)  = re.subn(fr"{PRECHAR}({bsdf}|{bsdf}_a|{bsdf}_b)->{n[1]}[\s]*([\*\+\-\/]*=)(((?!;).|\n)*);",fr"\1 {cls.stName}{n[1]}_lval(\2) \3 \4; {cls.stName}{n[1]}_assign(\2) ",code)
                (code,num)  = re.subn(fr"{PRECHAR}({bsdf}|{bsdf}_a|{bsdf}_b)->{n[1]}",fr"\1{cls.stName}{n[1]}(\2)",code)
                if num > 0:
                    print(f" match  bsdf->{n[1]}  ")
            elif len(n) == 3 and n[2] == "extra":
                if len(exmember) ==0:Error("EXTRA PARSE ")
                ex_0 = stride
                for ex in exmember:
                    if len(ex) ==2:
                        size = cls.SIZEOF[ex[0]](cls,ex,stride)
                        stride += size
                        if size > 1:
                             (code,num)  = re.subn(fr"{PRECHAR}({bsdf}|{bsdf}_a|{bsdf}_b)->extra->{ex[1]}[\s]*([\*\+\-\/]*=)(((?!;).|\n)*);",fr"\1 {cls.stName}{ex[1]}_lval(\2) \3 \4; {cls.stName}{ex[1]}_assign(\2) ",code)
                        (code,num)  = re.subn(fr"{PRECHAR}({bsdf}|{bsdf}_a|{bsdf}_b)->extra->{ex[1]}",fr"\1{cls.stName}{ex[1]}(\2)",code)
                        if num > 0:
                            print(f" match  bsdf->{ex[1]}  ")
                    else:Error(f" Extra Member parse  {ex} ")
                ex_1 = stride
                (code,num)  =cls._extra_null(cls,code ,ex_0,ex_1)
            else:
                Error(f"Member Parse {n} ")
        #SC = "ShaderClosure"
        #(code,num)  =  re.subn(fr"{SC}[\s]*\*[\s]*sc",fr"{SC} *{bsdf}",code) 
        (code,num)  =  re.subn(fr"{STNAME}[\s]*\*[\s]*({bsdf}|{bsdf}_a|{bsdf}_b)[\s]*=[\s]*\([\s]*{STNAME}[\s]*\*[\s]*\)[\s]*sc[\s]*;",r"",code)
        (code,num)  =  re.subn(fr"const[\s]*{STNAME}[\s]*\*[\s]*({bsdf}|{bsdf}_a|{bsdf}_b)[\s]*=[\s]*\([\s]*const[\s]*{STNAME}[\s]*\*[\s]*\)[\s]*(a|b)[\s]*;",r"",code) 
        (code,num)  =  re.subn(fr"const[\s]*{STNAME}[\s]*\*[\s]*({bsdf}|{bsdf}_a|{bsdf}_b)[\s]*=[\s]*\([\s]*const[\s]*{STNAME}[\s]*\*[\s]*\)[\s]*sc[\s]*;",r"",code)
       
        cod  = code.split("CCL_NAMESPACE_BEGIN")
        return cod[0] + f"\nCCL_NAMESPACE_BEGIN\n\n\n#define {STNAME} ShaderClosure\n" + cls.code + "\n\n\n" + cod[1]

class replace_type:
    test_code =  """/* Versions of functions which are safe for fast math. */
    ccl_device_inline bool isnan_safe(float f)
{
  unsigned int x = __float_as_uint(f);
  return (x << 1) > 0xff000000u;
}
    """
    test_code2 = """ccl_device_inline float3 bsdf_eval_sum(const BsdfEval *eval)
{
#ifdef __PASSES__
  if (eval->use_light_pass) {
    return eval->diffuse + eval->glossy + eval->transmission + eval->volume;
  }
  else
#endif
    return eval->diffuse;
}

ccl_device_inline void path_radiance_accum_total_light(inout PathRadiance L,
                                                       ccl_addr_space PathState *state,
                                                       float3 throughput,
                                                       const BsdfEval *bsdf_eval)
{
#ifdef _SHADOW_TRICKS_
  if (state.flag & PATH_RAY_STORE_SHADOW_INFO) {
    L.path_total += throughput * bsdf_eval.sum_no_mis;
  }
#else
  (void)L;
  (void)state;
  (void)throughput;
  (void)bsdf_eval;
#endif
}

/* Path Radiance
 *
 * We accumulate different render passes separately. After summing at the end
 * to get the combined result, it should be identical. We definite directly
 * visible as the first non-transparent hit, while indirectly visible are the
 * bounces after that. */

ccl_device_inline void path_radiance_init(KernelGlobals *kg, PathRadiance *L)
{
  /* clear all */
#ifdef __PASSES__
  L->use_light_pass = kernel_data.film.use_light_pass;

  if (kernel_data.film.use_light_pass) {
    L->indirect = make_float3(0.0f, 0.0f, 0.0f);
    L->direct_emission = make_float3(0.0f, 0.0f, 0.0f);

    L->color_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    L->color_glossy = make_float3(0.0f, 0.0f, 0.0f);
    L->color_transmission = make_float3(0.0f, 0.0f, 0.0f);

    L->direct_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    L->direct_glossy = make_float3(0.0f, 0.0f, 0.0f);
    L->direct_transmission = make_float3(0.0f, 0.0f, 0.0f);
    L->direct_volume = make_float3(0.0f, 0.0f, 0.0f);

    L->indirect_diffuse = make_float3(0.0f, 0.0f, 0.0f);
    L->indirect_glossy = make_float3(0.0f, 0.0f, 0.0f);
    L->indirect_transmission = make_float3(0.0f, 0.0f, 0.0f);
    L->indirect_volume = make_float3(0.0f, 0.0f, 0.0f);

    L->transparent = 0.0f;
    L->emission = make_float3(0.0f, 0.0f, 0.0f);
    L->background = make_float3(0.0f, 0.0f, 0.0f);
    L->ao = make_float3(0.0f, 0.0f, 0.0f);
    L->shadow = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    L->mist = 0.0f;

    L->state.diffuse = make_float3(0.0f, 0.0f, 0.0f);
    L->state.glossy = make_float3(0.0f, 0.0f, 0.0f);
    L->state.transmission = make_float3(0.0f, 0.0f, 0.0f);
    L->state.volume = make_float3(0.0f, 0.0f, 0.0f);
    L->state.direct = make_float3(0.0f, 0.0f, 0.0f);
  }
  else
#endif
  {
    L->transparent = 0.0f;
    L->emission = make_float3(0.0f, 0.0f, 0.0f);
  }

#ifdef __SHADOW_TRICKS__
  L->path_total = make_float3(0.0f, 0.0f, 0.0f);
  L->path_total_shaded = make_float3(0.0f, 0.0f, 0.0f);
  L->shadow_background_color = make_float3(0.0f, 0.0f, 0.0f);
  L->shadow_throughput = 0.0f;
  L->shadow_transparency = 1.0f;
  L->has_shadow_catcher = 0;
#endif

#ifdef __DENOISING_FEATURES__
  L->denoising_normal = make_float3(0.0f, 0.0f, 0.0f);
  L->denoising_albedo = make_float3(0.0f, 0.0f, 0.0f);
  L->denoising_depth = 0.0f;
#endif

#ifdef __KERNEL_DEBUG__
  L->debug_data.num_bvh_traversed_nodes = 0;
  L->debug_data.num_bvh_traversed_instances = 0;
  L->debug_data.num_bvh_intersections = 0;
  L->debug_data.num_ray_bounces = 0;
#endif
}
"""
    @classmethod
    def reserve(cls,code):

        (code,num)  = re.subn(fr"([\,\s\(]+)ccl_global[\s]+float[\s]+\*[\s]*buffer([\s\,\)]+)",fr"\1int ofs/*global ssbo offset*/\2",code)
        (code,num)  = re.subn(fr"([,\s.\(\*]+)buffer([\s,;\)]+)",fr"\1ofs\2",code)

        words = ["sample","filter","out","in","common","smooth","patch"]
        for i in range(2):
            for w in words:
                (code,num)  = re.subn(fr"([,\s.\(\*]+){w}([\s,;\)\+]+)",fr"\1{w}_rsv\2",code)
        return code
    @classmethod
    def pointer2inout(cls,code,Names):
        for (N,n) in Names:
            _N = N.split()
            if _N[0] == 'const':
                (code,num)  = re.subn(fr"(({N}\*[\s]+)|({N}[\s]+\*))[\s]*{n}",fr"in {_N[1]} {n}",code)
            else:
                (code,num)  = re.subn(fr"(({N}\*[\s]+)|({N}[\s]+\*))[\s]*{n}",fr"inout {N} {n}",code)
        code = code.replace('->','.')
        return code
    @classmethod
    def post_SubALL(cls,code):
        (code,num)  = re.subn(r"__","_",code)
        (code,num)  = re.subn(r"typedef[(?!struct)\S ]*struct[\s]+([_a-zA-Z0-9]*)(((?!\1).|\n)*)(\1)",r" struct \1\2",code) 
        (code,num)  = re.subn(r"[\s]+struct[\s]+(.*)[\s]+{(((?!\1).|\n)*)}[\s]*\1",r"\n\n struct _\1 { \2 }\1",code)  
        (code,num)  = re.subn(r"[\s]+struct[\s]+(((?!{).|\n)*);",r" \n \1;",code)  
        return code
    @classmethod
    def enum2const(cls,code,const = False):
        CODE  = ""
        piv = 0
        for ma in  re.findall(r"\n[a-z ]*?enum (.*) {([\s\S\n]*?);", code):
            if len(ma) != 2:Error("enum 0 failed")
            sp    = re.search(r"\n[a-z ]*?enum (.*) {([\s\S\n]*?);", code[piv:]).span()
            CODE += code[piv:piv + sp[0]]
            piv   = piv + sp[1]
            block = IFDEF(ma[1])
            dst = f"\n//modify => enum {ma[0]} \n"
            dst += attr["TYPE0"].format(ma[0])
            first        =  re.search(r"([A-Z]+_[A-Z]+)[\s\S\n]*?,", block)
            pre          = first.group(0).lstrip().split("_")[0]
            log(f"=========== {first.group(0)}   prefix = {pre}")
            attr["enum"] = 0
            for line in  re.findall( fr"{pre}_([\s\S\n]*?),",block):
                line = f"{pre}_{line}"
                debug(f" this line  = {line}")
                if ENUM_MEMBER(line,pre):
                    if const :
                        dst += ENUM_PARSE_CONST(line,attr)
                    else:
                        dst += ENUM_PARSE(line,attr)
            ltx = attr["name"]
            check = list(filter(('').__ne__, block.split(",")))
            for n,last in enumerate(check[-1::-1]):
                if last.find(ltx) > 0:
                    tx = ""
                    for i in check[(-n):]:
                        tx += i
                    log(f" last  member check   {last}  ==  {ltx}   TX N{n}   {tx} ")
                    add = False
                    for reg in [pre,r"NUM" ,r"NBUILTIN"]:
                        last = re.search(r"([\s\S\n]*?)(" + reg + r"_[\s\S\n]*?)}", tx)
                        if last:
                            add = True
                            last = last.group(2)
                            break
                    if add:
                        log(f" >>>>>>>>>>>>>>>>>>>>>>>>>>> final member check   {last}  ")
                        debug(f" last line  = {last}")
                        if const :
                            dst += ENUM_PARSE_CONST(last, attr)
                        else:
                            dst += ENUM_PARSE(last, attr)
                    break
            dst += "//modified ==> " + ma[0] + "\n\n\n"
            print(dst)
            CODE += dst
        CODE   += code[piv:]
        CODE = cls.post_SubALL(CODE)
        return CODE
    @classmethod
    def exec(cls,code,src,dst):
        (code,num)  = re.subn(fr"[\s]+{src}[\s]+",fr"\n {dst} ",code)
        debug(f"post_TypeName {src} to {dst}  NUMS {num}   ==>>   \n\n {code} \n\n")
        return code
    @classmethod
    def execall(cls,code):
        
        code = cls.exec(code,"signed char","int8_t")
        code = cls.exec(code,"unsigned char","uint8_t")

        code = cls.exec(code,"signed short","int16_t")
        code = cls.exec(code,"unsigned short","uint16_t")

        code = cls.exec(code,"signed int","int")
        code = cls.exec(code,"unsigned int","uint")


        code = cls.exec(code,"long long","int64_t")
        code = cls.exec(code,"unsigned long long","uint64_t")


        code = cls.exec(code,"unsigned","uint")

        return code




EXAM = False
if EXAM:
    import regex
    regex.findall(r'(?>.*)[ac]',"bbbbaafdadsfabbbcbc")      
    regex.findall(r'(.*)[ac]',"bbbbaafdadsfabbbcbc") 
    regex.findall(r'\(([^\(\)]+)\)',"bbbbaafdadsfo1(i3(i1(i0)i1)i2)i3)o1") 
    #i0
    regex.findall(r'\((?>[^\(\)]+)\)',"bbbbaafdadsfo1(i3(i1(i0)i1)i2)i3)o1") 
    #(i0)
    regex.findall(r'\(([^\(\)]+|(?R))+\)',"bbbbaafdadsfo1(i3(i2(i1(i0)i1)i2)i3)o1") 
    #i3
    regex.findall(r'\((?>[^\(\)]+|(?R))+\)',"bbbbaafdadsfo1(i3(i2(i1(i0)i1)i2)i3)o1") 
    #(i3(i2(i1(i0)i1)i2)i3)