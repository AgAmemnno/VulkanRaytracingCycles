import re
import regex
import functools
from parse_enum import *
class Directive:
    version    =""
    extensions = []
    defines     = {}
class GLSLstruct:
    def __init__(self):
        self.field  = {}
        self.refs   = []
        self.inst   = 0
        self.exp    =""

class parser:
    scope  = "global"
    for_it = 0
    if_it  = 0
    EXP    = []
    BRACE  =  r"{(?>[^{}]+|(?R))+}"
    def __init__(self):
        self.STRC = {}
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
        #print(member)
        return member
    def args(self,_clos):
        _clos = COMMENTOUT(_clos)
        (_clos,num) = re.subn(r"[ \t]*(#ifdef|#ifndef)(.*)\n","",_clos)
        (_clos,num) = re.subn(r"[ \t]*#endif(.*)\n","",_clos)
        (_clos,num) = re.subn(r"[\s]*ccl_[a-z_]+[\)\s]+"," ",_clos)
        #if num > 0:
        #    print(_clos)
        _clos = _clos.replace("\n","").split(",")
        _clos = [i for i in _clos if i != ""]
        member =[]
        for i in _clos:
            n = i.split(" ")
            n = [i for i in n if i != ""]
            if len(n) ==0:continue
            member.append(n)

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
    def append_exp(self,exp,_type = "line"):
        self.EXP.append({
                    "type" :_type,
                    "exp" : exp,
                    "scope":self.scope
                })
    def expression(self,code):
        it = re.match(r"(((?!;).|\n)*);" ,code)
        if hasattr(it,"group"):
            g = it.group(1)
            if re.search(r"(^|\s)+if([\s\(])+",g):
                return self.parse_if(code)
            elif re.search(r"(^|\s)+for([\s\(])+",g):
                return self.parse_for(code)
            else:
                LR = g.split("=")
                lr = []
                for i in LR:
                    e = i.strip()
                    if e != '':
                        lr.append(e)
                if not ( len(lr) == 2 or len(lr) == 1 ):
                    print(f"UnKwnoun exp {lr}")
                self.append_exp(lr)
                sp = it.span()
                return sp[1]
        else:
            return -1
    def parse_semicolon(self,code):
        st = 1
        while(True):
            stride = self.expression(code[st:])
            if stride > 0:
                st += stride
            else:
                break
        return st

    def parse_if(self,code):
        RG_ARG = r"[\s]*{}[\s]*(((?!{{|[\s}}]+else[\s{{]+).|\n)*){{"
        RG_BR  = r"\((?>[^\(\)]+|(?R))+\)"
        def cond_line(self,code):
            it =  regex.search(RG_BR , code)
            if it:
                self.append_exp( it.group(0),"cond")
                #print("if  line")
                _st = it.regs[0][1]
                return _st + self.expression(code[_st:])
            else:
                print("parse IF error ")
                exit(-1)
        st = 0
        it =  re.match(RG_ARG.format("if") ,code)
        if it == None:
            stride = cond_line(self,code)
        elif len(it.regs) == 3:
            args = it.regs[1]
            (ast,aed) = args[0],args[1]
            self.append_exp(code[ast:aed],"cond")
            st = it.regs[1][1]
            cont =  regex.search(r"{(?>[^{}]+|(?R))+}" , code[st:])
            if cont:
                #print(f"if scoped {cont[0]}")
                stride = cont.regs[0][1]
                self.parse_semicolon(cont[0]) 
            else:
                print("parse IF error ")
                exit(-1)
        else:
            print("parse IF error ")
            exit(-1)
        st +=    stride 
        while(True):
            matc = False
            els = re.match(r"[\s]*else[\s]+if" ,code[st:])
            if els:
                #it = re.search(r"^[\s]*else[\s]+if[\s]*\((((?!\)).|\n)*)\)[\s]*{",code[st:])
                it =  re.match(RG_ARG.format("else[\s]+if") ,code[st:])
                if it == None:
                    stride = cond_line(self,code)
                elif len(it.regs) == 3:
                    args = it.regs[1]
                    (ast,aed) = st + args[0], st + args[1]
                    self.append_exp(code[ast:aed],"cond")
                    st   = aed
                    cont =  regex.search(r"{(?>[^{}]+|(?R))+}" , code[st:])
                    if cont:
                        #print(f"else scoped {cont[0]}")
                        stride = cont.regs[0][1]
                        self.parse_semicolon(cont[0]) 
                    else:
                        print("parse IF error ")
                        exit(-1)
                else:
                    print("parse IF error ")
                    exit(-1)
                st += stride
                matc = True
            if not matc:
                els = re.match(r"[\s]*(else)[\s]*" ,code[st:]) 
                if els:
                    it = re.search(r"^[\s]*else[\s]*{",code[st:])
                    if it == None:
                        sp = els.span()[1]
                        #print("else  line")
                        stride = sp + self.expression(code[st + sp:])
                    elif len(it.regs) == 1:
                        cont =  regex.search(r"{(?>[^{}]+|(?R))+}" , code[st:])
                        if cont:
                            #print(f"else  scoped {cont[0]}")
                            stride = cont.regs[0][1]
                            self.parse_semicolon(cont[0]) 
                        else:
                            print("parse IF error ")
                            exit(-1)
                    else:
                        print("parse IF error ")
                        exit(-1)
                    st += stride
                else:break
        return st
    def parse_for(self,code):
        RG_ARG = r"[\s]*{}[\s]*(((?!{{|[\s}}]+else[\s{{]+).|\n)*){{"
        RG_BR  = r"\((?>[^\(\)]+|(?R))+\)"
        def cond_line(self,code):
            it =  regex.search(RG_BR , code)
            if it:
                self.append_exp( it.group(0),"for")
                #print("for  line")
                _st = it.regs[0][1]
                return _st + self.expression(code[_st:])
            else:
                print("parse FOR error ")
                exit(-1)
        st = 0
        it =  re.match(RG_ARG.format("for") ,code[st:])
        if it == None:
            stride = cond_line(self,code[st:])
        elif len(it.regs) == 3:
            args = it.regs[1]
            (ast,aed) = args[0],args[1]
            self.append_exp(code[ast:aed],"for")
            st = it.regs[1][1]
            cont =  regex.search(r"{(?>[^{}]+|(?R))+}" , code[st:])
            if cont:
                #print(f"for scoped {cont[0]}")
                scope = self.scope
                self.scope = f"for-{self.for_it}"
                self.for_it += 1
                stride = cont.regs[0][1]
                self.parse_semicolon(cont[0]) 
                self.for_it -= 1
                self.scope  = scope
            else:
                print("parse FOR error ")
                exit(-1)
        else:
            print("parse FOR error ")
            exit(-1)
        st +=  stride 
        return st
    def parse_layout(self,code):
        self.Layout = {}
        stride  = 0
        RG_LAYOUT = r"[\s]*layout[\s]*\(((?!\)).*)\)[\s]+([a-zA-Z_0-9\s]+);"
        for it in re.finditer(RG_LAYOUT,code):
            if len(it.regs) == 3:
                names = it.group(2).split(" ")
                if len(names) == 3:
                    self.Layout.update({
                       names[2]:
                        {
                            "location": it.group(1),
                            "type"    : names[0],
                            "type2"   : names[1],
                            "exp"     : it.group(0)
                        }
                    })
                elif len(names) == 4:
                    self.Layout.update({
                       names[3]:
                        {
                            "location":it.group(1),
                            "type"    : names[0],
                            "type2"   : names[2],
                            "modify"  : names[1],
                            "exp"     : it.group(0)
                        }
                    })
                #print(it.group(0))
            else:
                print("Error layout")
                exit(-1)
            if stride < it.span()[1]:
                stride = it.span()[1]
        for it  in re.finditer(r"[\s]*layout[\s]*\(((?!\)).*)\)[\s]+([a-zA-Z_0-9\s]+){(((?!}).|\n)*)}[\s]*([a-zA-Z0-9_]*);",code):
            if len(it.regs) == 6:
                names = it[2].strip().split(" ")
                Name = ""
                if len(names) == 2:
                    self.Layout.update({
                       names[1]:
                        {
                            "location": it.group(1),
                            "type"    : names[0],
                            "exp"     : it.group(0),
                            "name"    : it[5]
                        }
                    })
                    Name = names[1]
                elif len(names) == 3:
                    self.Layout.update({
                       names[2]:
                        {
                            "location":it.group(1),
                            "type"    : names[0],
                            "modify"  : names[1],
                            "exp"     : it.group(0),
                            "name"    : it[5]
                        }
                    })
                    Name = names[2]
                strc = GLSLstruct()
                for f in it.group(3).split(';'):
                    n = f.replace('\n','').lstrip(' ').split(' ')
                    n = [i for i in n if i!=""]
                    if len(n) == 2:
                        strc.field.update({n[1] : n[0]})
                        if n[0] in self.STRC:
                            strc.refs.append(n[1])
                strc.exp =  it.group(3)
                strc.inst = 0
                self.Layout[Name]["strc"] = strc
            else:
                print("Error layout")
                exit(-1)
            if stride < it.span()[1]:
                stride = it.span()[1]
        return stride
    def parse_sharp(self,code):
        self.Drcv = Directive()
        n = 0
        stride  = 0
        for it  in re.finditer(r"#(.*)\n" ,code):
            #print(f"VAL {n}   {it[0].split(' ')} ")
            l = it[0].split('\n')
            head = it[0].split(' ')
            Type = head[0].replace(' ','')
            if  Type == "#version":
                self.Drcv.version = head[1]
            elif  Type == "#extension":
                self.Drcv.extensions.append(head[1:])
            elif  Type == "#define":
                if len(l) != 2:
                    print("Error Define parse ") 
                    exit(-1)
                body  = head[2]
                if l[0].find('\\') >= 0:
                    body = body.replace('\\','')
                    for line in code[it.regs[0][1]:].split("\n"):
                        #print(f" multilines  {line} ")
                        if line.find('\\') == -1:
                            body += line
                            break
                        else:
                            body += line.replace('\\','\n')
                self.Drcv.defines.update({
                    head[1] : body
                })
            n+=1
            stride = it.regs[0][1]
        return stride
    def parse_global(self,code):
        self.VAR = {}
        stride = self.parse_sharp(code)
        stride += self.parse_struct(code[stride:])
        stride += self.parse_layout(code[stride:])
        n = 0
        strc = False
        for it  in re.finditer(r"(((?!;).|\n)*);" ,code[stride:]):
            v = it[0].split(' ')
            typ = v[0].replace('\n','')
            if len(v) == 2:
                if v[1].find(';') >= 0 and v[1].find('(') == -1:
                    name = v[1].replace(';','')
                    ex = it[0].strip()
                    self.VAR[name] = {  "type" :typ,"expr": ex}
                    ##print(f"VARS {typ}  {name}  ")
                    stride = it.span()[1]
            n+=1
        return stride
    def parse_struct(self,code):
        self.STRC = {}
        i = 0 
        stride = 0
        for fi  in re.finditer(r"[\s]*struct[\s]+([a-zA-z0-9_]+)[\s]*{(((?!}).|\n)*)}[\s]*;",code):
            #print("struct  ",fi)
            strc = GLSLstruct()
            fi.group(2).replace("\n",'')
            for f in fi.group(2).split(';'):
                n = f.replace('\n','').lstrip(' ').split(' ')
                if len(n) == 2:
                    strc.field.update({n[1] : n[0]})
                    if n[0] in self.STRC:
                        strc.refs.append(n[1])
                    strc.exp = fi.group(0)
            strc.inst = 0
            self.STRC[fi.group(1)] = strc
            stride = fi.span()[1]
        return stride
    def functions(cls,code):
        cls.FUNC = {}
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
            nameReg = it.regs[1]
            cont =  regex.search(r"{(?>[^{}]+|(?R))+}" , code[nameReg[1]:])
            name = code[nameReg[0]:nameReg[1]]
            if name == "for" or name == "if":continue
            if cont == None:
                Error(f"content None Error {__FILE__} {__LINE__}")
            funcscope = (it.regs[0][0],nameReg[1] + cont.regs[0][1])
            cls.FUNC.update({
                name : {
                    "args" :  code[ast:aed],
                    "body" :  cont[0],
                    "scope":  funcscope
                }
            })
            cls.EXP = []
            body = cont[0]
            cls.for_it = 0
            cls.if_it  = 0
            scope = cls.scope 
            cls.scope = f"function-{name}"
            cls.parse_semicolon(COMMENTOUT(body) )
            cls.scope = scope
            cls.FUNC[name]["expr"]  = cls.EXP
            st    = funcscope[1]
            if ast == aed :continue
            args = code[ast:aed]
            for a in cls.args(args):
                print(f"args {a}")
        
        for fu in cls.FUNC:
            print(f"func {fu}  scope {cls.FUNC[fu]['scope']}")
    def entry(cls,code):
        stride = cls.parse_global(code)
        cls.functions(code[stride:])


class eliminate:
    def __init__(self,par,entry,code):
        self.token = par
        self.entry = entry
        self.code = code
    def setLayout(self,layout):
        """
        string :: name set binding name set binding ... 
        """
        self.nsb = {}
        N = 0
        for i in layout.split(" "):
            if i != "":
                if N == 2:
                    sb.append(i)
                    N -=1
                elif N == 1:
                    sb.append(i)
                    N -=1
                    self.nsb[name] = sb
                elif N == 0:
                    name = i
                    N   = 2
                    sb = []
            
        
    def strip(self,co):
        code = ""
        for i in co.split("\n"):
            l = i.strip()
            if l != "":
                code += l +"\n"
        return code
    def naive_struct(self):
        strc    = self.token.STRC
        co = self.code
        for name in strc:
            dupli = name.split("_")
            if re.match(r"^[\d]+$",dupli[-1]):
                co       = co.replace(strc[name].exp,"")
                orig     = "".join(dupli[:-1])
                (co,num) = re.subn(fr"[\s]*struct[\s]+({name})[\s]*{{(((?!}}).|\n)*)}}[\s]*;",r"",co)
                #co       = co.replace(strc[name].exp.strip(),"")
                (co,num) = re.subn(fr"([\s]+){name}([\s]+)",fr"\1{orig}\2",co)
                print(f"duplicate struct {name} orig {orig}  replace {num} ")


        for name in strc:
            used = re.findall( fr"[\n\s\+\-\/\(\=\;\,\|\&]+({name})[\n\s\,\+\-\/\)\=\;\|\&]+",co)
            if len(used) == 1:
                co   = co.replace(strc[name].exp,"")
        self.code = self.strip(co)
        #print(self.code)
    def naive_var(self):
        RD_VAR = r"[\s]+{}[\s]+=[\s]*(((?!;).|\n)*);"
        co     = self.code
        exp    = self.token.FUNC[self.entry]["expr"]
        exp.reverse()
        body   = self.token.FUNC[self.entry]["body"]
        nexp = []
        for e in exp:
            if len(e['exp']) == 2:
                name = e['exp'][0]
                if name in self.token.VAR:
                    used = re.findall( fr"[\n\s\+\-\/\(\=\;\,\|\&]+({name})[\n\s\,\+\-\/\)\=\;\|\&]+",co)
                    if len(used) == 2:
                        g = re.search(RD_VAR.format(e['exp'][0]),co)
                        if g:
                            #print(f"eliminate  {name}    exp1 {self.token.VAR[name]['expr']}  exp2 {g.group(0)} ")
                            co   = co.replace(self.token.VAR[name]["expr"],"")
                            co   = co.replace(g.group(0),"")
                            body = body.replace(g.group(0),"")
                            del self.token.VAR[name]
                            res = re.findall( fr"[\n\s\+\-\/\(\=\;\,\|\&]+({name})[\n\s\,\+\-\/\)\=\;\|\&]+",co)
                            #print(f"eliminate  {name}    after {res} ")
                            continue
            nexp.append(e)

        nexp.reverse()
        self.token.FUNC[self.entry]["expr"] = nexp
        self.token.FUNC[self.entry]["body"] = self.strip(body)
        self.code = self.strip(co)
        #print(self.code)
    def replace_layout(self):
        def rep(it,Name,co):
            r = False
            if Name in self.nsb:
                sb = self.nsb[Name]
                layout  = it.group(1).split(",")
                _layout = []
                sb_  = [False,False]
                for i in layout:
                    if i != "":
                        if i.find("set") >= 0:
                            _layout.append(f"set={sb[0]}")
                            sb_[0] = True
                        elif i.find("binding") >= 0:
                            _layout.append(f"binding={sb[1]}")
                            sb_[1] = True
                        else:
                            _layout.append(i)
                for i,tf in enumerate(sb_):
                    if not tf:
                        if i == 0:_layout.append(f"set={sb[0]}")
                        elif i == 1:_layout.append(f"binding={sb[1]}")

                _layout = ",".join(_layout)
                group0 = it.group(0).replace(it.group(1),_layout)
                co= co.replace(it.group(0),group0)
                r = True
            return (co,r)

        stride  = 0
        RG_LAYOUT = r"[\s]*layout[\s]*\(((?!\)).*)\)[\s]+([a-zA-Z_0-9\s]+);"
        co   = self.code
        code = self.code
        for it in re.finditer(RG_LAYOUT,code):
            if len(it.regs) == 3:
                Name = ""
                names = it.group(2).split(" ")
                if len(names) == 3:
                    Name = names[2]
                elif len(names) == 4:
                    Name = names[3]
                (co,r)  = rep(it,Name,co)
            else:
                print("Error layout")
                exit(-1)
            if stride < it.span()[1]:
                stride = it.span()[1]
        #print(co)
        for it  in re.finditer(r"[\s]*layout[\s]*\(((?!\)).*)\)[\s]+([a-zA-Z_0-9\s]+){(((?!}).|\n)*)}[\s]*([a-zA-Z0-9_]*);",code):
            if len(it.regs) == 6:
                names = it[2].strip().split(" ")
                Name  = ""
                Name2 =  it[5]
                if len(names) == 2:
                    Name  = names[1]
                elif len(names) == 3:
                    Name = names[2]
                (co,r) = rep(it,Name,co)
                if not r and Name2 != "":
                    (co,r) = rep(it,Name2,co)
            else:
                print("Error layout")
                exit(-1)
            if stride < it.span()[1]:
                stride = it.span()[1]
        #print(co)
        self.code = co
        return stride