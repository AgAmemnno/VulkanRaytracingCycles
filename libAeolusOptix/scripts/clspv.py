from aeolus.spirV.template import ConstRender
Dir  = "D:/C/Aeoluslibrary/libAeolusOptix/shaders/cl"

name =  ("/PushConstant/two_ints",1)
name =  ("/Reflection/constant_data_storage_buffer",2)
name =  ("/ProgramScopeConstants/constant",0)

names = [name]

c = ConstRender()
for (i,p) in names:
    c.renderCL(Dir+i,push = p)