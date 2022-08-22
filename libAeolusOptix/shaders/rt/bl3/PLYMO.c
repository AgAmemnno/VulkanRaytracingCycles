KernelObject Get
{
object_dupli_uv  
object_dupli_generated
object_color

}



STAT_CLIENT
D:\C\Aeoluslibrary\libAeolusOptix\shaders\intern\kernel\prof

tfm 
x -0.268331021 ,0,0,-0.737309635
y 0, -0.268331021,0,-1.22707605
z  0,0,-0.268331021,0.447233051

mat4x3
a1 a2 a3 a4
b1 b2 b3 b4
c1 c2 c3 c4

a1 b1 c1  
a2 b2 c2
a3 b3 c3
a4 b4 c4

ByPixel, 226 ,146

if( gl_LaunchIDNV.xy == uvec2(DEBX,DEBY)){
   debugPrintfEXT(" BREAK POINNT   %d \n", rec_num) ;
}
>>>>>>>>>>>  indirect_lamp_emission_emission       [0.000000  0.000000 0.000000]      [0.097471  0.098789 0.034583]


ByTileRandom
  if(G_dump)debugPrintfEXT(" de  %f  %d  %u  %u \n",light_eval.x, int(rec_num),kg.pixel.x,kg.pixel.y);

  /*
  if( gl_LaunchIDNV.xy == uvec2(169, 44)){
    debugPrintfEXT(" Callee AHITNV launchNV   %v2u  hits %u  t %f \n",gl_LaunchIDNV.xy,iinfo.numhits,gl_HitTNV);
   }
     if( gl_LaunchIDNV.xy == uvec2(169, 44)){
    debugPrintfEXT(" Caller AHITNV launchNV   %v2u  hits %u  t %f \n",gl_LaunchIDNV.xy,PLYMO_ISECT_get_numhits,IS(PLYMO_ISECT_get_offset).t);
   }
  */
 float3 
 sum -> sum_float3
 avg -> avg_float3
 #define len(a) (sqrt(dot(a, a)))


[direct_emission]

  if (ls.pdf == 0.0f)
    return false;

  if (is_zero(light_eval))  <- direct_emissive_eval
    return false;

  if (PLYMO_bsdf_eval_is_zero()) <- EXECUTION_LIGHT_SAMPLE;
    return false;

  if (rand_terminate >= probability) {
        return false;
      }


 ls.shader -> shader_constant_emission_eval


 struct differential {
  float dx;
  float dy;
} ;
struct args_acc_light{
  vec4 emission;
  vec4 direct_emission;
  vec4 indirect;
  vec4 path_total;
  vec4 throughput;
};
 struct differential3 {
  float3 dx;
  float3 dy;
} ;
 struct Ray {

  float t;    /* length of the ray */
  float time; /* time (for motion blur) */
  float3 P;   /* origin */
  float3 D;   /* direction */
  differential3 dP;
  differential3 dD;

} ;
struct args_sd{

float3 P;
float3 N; 
float3 Ng;
float3 I;
int flag;
int type;
int object;
int        num_closure;
int      atomic_offset;
float             time; 
float       ray_length;
int       alloc_offset;
float             pad0;
uint         lcg_state;
float             pad1;

differential3       dI;

};
struct BsdfEval {
  float3 diffuse;
#ifdef _PASSES_
  float3 glossy;
  float3 transmission;
  float3 transparent;

#endif
#ifdef _SHADOW_TRICKS_
  float3 sum_no_mis;
#endif
} ;


struct PRG2ARG
{
args_sd    sd;     // 140
args_acc_light L;  // 80
int  use_light_pass;
int  type;
Ray ray; //104
PathState  state; //56
};

struct PLMO_SD_EVAL
{
args_sd    sd;   // 140
BsdfEval eval;   // 80

vec4 omega_in;    
differential3 domega_in; 

int      label;
int      use_light_pass;
int      type;
float    pdf;
};
/// Plymorph PRG2ARG = A  , PLMO_SD_EVAL = B        (location = 0)
A.sd  = B.sd
A.L   = B.eval
A.use_light_pass = B.omega_in.x
A.type  = B.omega_in.y
A.ray.t ,A.ray.time = B.omega_in.zw
A.ray.P = domega_in.dx
A.ray.D = domega_in.dy
A.ray.dP.dx = B.(label ,use_light_pass,type,pdf)

ccl_addr_space struct ShaderData
{
  /* position */
  float3 P;
  /* smooth normal for shading */
  float3 N;
  /* true geometric normal */
  float3 Ng;
  /* view/incoming direction */
  float3 I;
  /* shader id */
  int shader;
  /* booleans describing shader, see ShaderDataFlag */
  int flag;
  /* booleans describing object of the shader, see ShaderDataObjectFlag */
  int object_flag;

  /* primitive id if there is one, ~0 otherwise */
  int prim;

  /* combined type and curve segment for hair */
  int type;

  /* parametric coordinates
   * - barycentric weights for triangles */
  float u;
  float v;
  /* object id if there is one, ~0 otherwise */
  int object;
  /* lamp id if there is one, ~0 otherwise */
  int lamp;

  /* motion blur sample time */
  float time;

  /* length of the ray being shaded */
  float ray_length;

#ifdef _RAY_DIFFERENTIALS_
  /* differential of P. these are orthogonal to Ng, not N */
  differential3 dP;
  /* differential of I */
  differential3 dI;
  /* differential of u, v */
  differential du;
  differential dv;
#endif
#ifdef _DPDU_
  /* differential of P w.r.t. parametric coordinates. note that dPdu is
   * not readily suitable as a tangent for shading on triangles. */
  float3 dPdu;
  float3 dPdv;
#endif



  /* ray start position, only set for backgrounds */
  float3 ray_P;
  differential3 ray_dP;


  /* LCG state for closures that require additional random numbers. */
  uint lcg_state;

  /* Closure data, we store a fixed array of closures */
  int num_closure;
  int num_closure_left;
  float randb_closure;
  float3 svm_closure_weight;


#ifdef _OBJECT_MOTION_
  /* object <-> world space transformations, cached to avoid
   * re-interpolating them constantly for shading */
  Transform ob_tfm;
  Transform ob_itfm;
#endif


  /* Closure weights summed directly, so we can evaluate
   * emission and shadow transparency with MAX_CLOSURE 0. */
  float3 closure_emission_background;
  float3 closure_transparent_extinction;

  /* At the end so we can adjust size in ShaderDataTinyStorage. */
  //ShaderClosure closure[MAX_CLOSURE];
  int      atomic_offset;
  int      alloc_offset;


};

/// Plymorph ShaderData = A  , PLMO_SD_EVAL = B     (location = 1)
// B <=  B.sd
A.(P,N,Ng,I)  =  B.(P,N,Ng,I)
A.(shader,flag,object_flag,prim) =  
 B.(flag, type ,object,num_closure)
A.(type,u ,v ,object ) = 
 B.(atomic_offset,time, ray_length,alloc_offset)
A.(lamp,time, ray_length) = 
 B.(pad0,lcg_state,pad1)
A.dP =  B.dI
//B <= B.sd
//B <= B.eval
 A.dI.dx = B.diffuse
 A.dI.dy = B.glossy
 A.du.dx dy =  B.transmission.xy;
 A.dv.dx dy =  B.transmission.zw;
 A.dPdu     =  B.transparent;
 A.dPdv     =  B.sum_no_mis;
//B <= B.eval
A.ray_P =  B.omega_in;    
A.ray_dP = B.domega_in; 

A.(lcg_state,num_closure,num_closure_left,randb_closure) 
 = B.(label,use_light_pass,type,pdf);
/// Plymorph ShaderData = A  , PLMO_SD_EVAL = B     (location = 1)








D:\blender\src\lib\win64_vc15\python\37\libs\python37_d.lib
C:\VulkanSDK\1.2.148.1\Lib\vulkan-1.lib
..\..\lib\Debug\libthreepy.lib
..\..\lib\Debug\libvkmm.lib
..\..\lib\Debug\libktx.lib
..\..\..\Lib\Debug\spv_compile.lib
..\..\..\Lib\Debug\opttest\aeolus_device.lib
D:\C\vcpkg\installed\x64-windows-static-custom\lib\freetype.lib
winmm.lib
dmoguids.lib
msdmo.lib
Secur32.lib
wmcodecdspuuid.lib
ws2_32.lib
strmiids.lib
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1\lib\x64\cudart_static.lib
cuda.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_date_time-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_filesystem-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_regex-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_system-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_thread-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_chrono-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_locale-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\static\OpencolorIO.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\tinyxml.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\libyaml-cppmdd.lib
..\..\..\..\..\lib\hiredis\lib\hiredis_staticd.lib
extern_cuew.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\pthreadVC3d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\freetyped.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\bz2d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlicommon-static.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlidec-static.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlienc-static.lib
..\..\..\..\..\lib\tbb\lib\tbb_debug.lib
..\..\..\..\..\lib\tbb\lib\tbbmalloc_debug.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\libpng16d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\jpegd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\zlibd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\tiffd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\lzmad.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Iex-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Half-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\IlmImf-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Imath-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\IlmThread-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO_Util.lib
shlwapi.lib
DbgHelp.lib
Version.lib
opengl32.lib
vfw32.lib
kernel32.lib
user32.lib
gdi32.lib
comdlg32.lib
Comctl32.lib
version.lib
advapi32.lib
shfolder.lib
shell32.lib
ole32.lib
oleaut32.lib
uuid.lib
psapi.lib
Dbghelp.lib
Shlwapi.lib
extern_gtest.lib
extern_gmock.lib
extern_glog.lib
extern_gflags.lib
GenericCodeGend.lib
glslangd.lib
MachineIndependentd.lib
OGLCompilerd.lib
OSDependentd.lib
SPIRVd.lib
SPVRemapperd.lib
spirv-cross-cored.lib
spirv-cross-glsld.lib
D:\C\openvr\lib\win64\openvr_api.lib
..\..\..\..\..\libthreepy\..\lib\packages\lib\Catcher_d.lib
..\..\..\..\..\libthreepy\..\lib\packages\lib\xrui_d.lib
winspool.lib
D:\C\Aeoluslibrary\lib\redis++\lib\redis++_static.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\event.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\event_core.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\event_extra.lib
Iphlpapi.lib
D:\C\Aeoluslibrary\lib\libev\lib\libev_static.lib







D:\blender\src\lib\win64_vc15\python\37\libs\python37_d.lib
C:\VulkanSDK\1.2.148.1\Lib\vulkan-1.lib
..\..\lib\Debug\libthreepy.lib
..\..\lib\Debug\libvkmm.lib
..\..\lib\Debug\libktx.lib
..\..\..\Lib\Debug\spv_compile.lib
..\..\..\Lib\Debug\opttest\cycles_util.lib
..\..\..\Lib\Debug\opttest\cycles_bvh.lib
..\..\..\Lib\Debug\opttest\cycles_render.lib
..\..\..\Lib\Debug\opttest\cycles_subd.lib
..\..\..\Lib\Debug\opttest\cycles_graph.lib
..\..\..\Lib\Debug\opttest\aeolus_device.lib
..\..\..\Lib\Debug\bf_intern_cycles.lib
D:\C\vcpkg\installed\x64-windows-static-custom\lib\freetype.lib
winmm.lib
dmoguids.lib
msdmo.lib
Secur32.lib
wmcodecdspuuid.lib
ws2_32.lib
strmiids.lib
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1\lib\x64\cudart_static.lib
cuda.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_date_time-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_filesystem-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_regex-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_system-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_thread-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_chrono-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_locale-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\static\OpencolorIO.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\tinyxml.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\libyaml-cppmdd.lib
..\..\..\..\..\lib\hiredis\lib\hiredis_staticd.lib
extern_cuew.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\pthreadVC3d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\freetyped.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\bz2d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlicommon-static.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlidec-static.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlienc-static.lib
..\..\..\..\..\lib\tbb\lib\tbb_debug.lib
..\..\..\..\..\lib\tbb\lib\tbbmalloc_debug.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\libpng16d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\jpegd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\zlibd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\tiffd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\lzmad.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Iex-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Half-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\IlmImf-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Imath-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\IlmThread-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO_Util.lib
bf_intern_guardedalloc.lib
bf_intern_clog.lib
bf_intern_ghost.lib
extern_glew.lib
extern_clew.lib
extern_curve_fit_nd.lib
extern_rangetree.lib
extern_wcwidth.lib
shlwapi.lib
DbgHelp.lib
Version.lib
bf_rna.lib
bf_dna.lib
bf_imbuf_openexr.lib
bf_imbuf_dds.lib
bf_imbuf_cineon.lib
opengl32.lib
vfw32.lib
kernel32.lib
user32.lib
gdi32.lib
comdlg32.lib
Comctl32.lib
version.lib
advapi32.lib
shfolder.lib
shell32.lib
ole32.lib
oleaut32.lib
uuid.lib
psapi.lib
Dbghelp.lib
Shlwapi.lib
extern_gtest.lib
extern_gmock.lib
extern_glog.lib
extern_gflags.lib
GenericCodeGend.lib
glslangd.lib
MachineIndependentd.lib
OGLCompilerd.lib
OSDependentd.lib
SPIRVd.lib
SPVRemapperd.lib
spirv-cross-cored.lib
spirv-cross-glsld.lib
D:\C\openvr\lib\win64\openvr_api.lib
..\..\..\..\..\libthreepy\..\lib\packages\lib\Catcher_d.lib
..\..\..\..\..\libthreepy\..\lib\packages\lib\xrui_d.lib
winspool.lib
D:\C\Aeoluslibrary\lib\redis++\lib\redis++_static.lib
Iphlpapi.lib




















D:\blender\src\lib\win64_vc15\python\37\libs\python37_d.lib
C:\VulkanSDK\1.2.162.1\Lib\vulkan-1.lib
..\..\lib\Debug\libthreepy.lib
..\..\lib\Debug\libvkmm.lib
..\..\lib\Debug\libktx.lib
..\..\..\Lib\Debug\spv_compile.lib
..\..\..\Lib\Debug\opttest\cycles_util.lib
..\..\..\Lib\Debug\opttest\cycles_bvh.lib
..\..\..\Lib\Debug\opttest\cycles_render.lib
..\..\..\Lib\Debug\opttest\cycles_subd.lib
..\..\..\Lib\Debug\opttest\cycles_graph.lib
..\..\..\Lib\Debug\opttest\aeolus_device.lib
..\..\..\Lib\Debug\bf_intern_cycles.lib
..\..\..\..\..\lib\webrtc\server\libdc_srv.lib
winmm.lib
dmoguids.lib
msdmo.lib
Secur32.lib
wmcodecdspuuid.lib
ws2_32.lib
strmiids.lib
..\..\..\..\..\lib\webrtc\lib\libwebrtc_d.lib
..\..\..\..\..\lib\webrtc\lib\command_line_parser.lib
..\..\..\..\..\lib\webrtc\lib\system_wrappers.lib
..\..\..\..\..\lib\webrtc\lib\rtc_base.lib
..\..\..\..\..\lib\webrtc\lib\video_capture_module.lib
..\..\..\..\..\lib\webrtc\lib\libwebrtc.lib
C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1\lib\x64\cudart_static.lib
cuda.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_date_time-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_filesystem-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_regex-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_system-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_thread-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_chrono-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_locale-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\static\OpencolorIO.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\tinyxml.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\libyaml-cppmdd.lib
..\..\..\..\..\lib\hiredis\lib\hiredis_staticd.lib
extern_cuew.lib
D:\blender\src\lib\win64_vc15\pthreads\x64\lib\pthreadVC3.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\freetyped.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\bz2d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlicommon-static.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlidec-static.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\brotlienc-static.lib
..\..\..\..\..\lib\tbb\lib\tbb_debug.lib
..\..\..\..\..\lib\tbb\lib\tbbmalloc_debug.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\libpng16d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\jpegd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\zlibd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\tiffd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\lzmad.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Iex-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Half-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\IlmImf-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\Imath-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\IlmThread-2_5_d.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO_Util.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\osdCPU.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\osdGPU.lib
bf_blenfont.lib
bf_blenlib.lib
bf_blenloader.lib
bf_blentranslation.lib
bf_bmesh.lib
bf_depsgraph.lib
bf_render.lib
bf_draw.lib
bf_functions.lib
bf_gpencil_modifiers.lib
bf_gpu.lib
bf_ikplugin.lib
bf_compositor.lib
bf_modifiers.lib
bf_nodes.lib
bf_shader_fx.lib
bf_simulation.lib
bf_windowmanager.lib
bf_blenkernel.lib
bf_imbuf.lib
bf_imbuf_openimageio.lib
bf_python.lib
bf_python_ext.lib
bf_python_gpu.lib
bf_python_bmesh.lib
bf_python_mathutils.lib
bf_intern_guardedalloc.lib
bf_intern_clog.lib
bf_intern_ghost.lib
bf_intern_libmv.lib
bf_intern_mikktspace.lib
bf_intern_opensubdiv.lib
bf_intern_utfconv.lib
bf_intern_opencolorio.lib
bf_intern_eigen.lib
bf_intern_memutil.lib
bf_intern_numaapi.lib
bf_intern_sky.lib
bf_intern_locale.lib
bf_intern_glew_mx.lib
bf_intern_iksolver.lib
bf_intern_itasc.lib
bf_editor_screen.lib
bf_editor_lattice.lib
bf_editor_metaball.lib
bf_editor_interface.lib
bf_editor_space_api.lib
bf_editor_animation.lib
bf_editor_armature.lib
bf_editor_curve.lib
bf_editor_gizmo_library.lib
bf_editor_gpencil.lib
bf_editor_io.lib
bf_editor_mesh.lib
bf_editor_object.lib
bf_editor_physics.lib
bf_editor_render.lib
bf_editor_scene.lib
bf_editor_sculpt_paint.lib
bf_editor_sound.lib
bf_editor_transform.lib
bf_editor_undo.lib
bf_editor_util.lib
bf_editor_uvedit.lib
bf_editor_mask.lib
bf_editor_space_view3d.lib
bf_editor_space_node.lib
bf_editor_space_image.lib
bf_editor_space_outliner.lib
bf_editor_space_graph.lib
bf_editor_space_clip.lib
bf_editor_space_buttons.lib
bf_editor_space_file.lib
bf_editor_space_info.lib
bf_editor_space_nla.lib
bf_editor_space_action.lib
bf_editor_space_sequencer.lib
bf_editor_space_userpref.lib
bf_editor_space_console.lib
bf_editor_space_script.lib
bf_editor_space_statusbar.lib
bf_editor_space_text.lib
bf_editor_space_topbar.lib
bf_editor_datafiles.lib
extern_glew.lib
extern_clew.lib
extern_curve_fit_nd.lib
extern_rangetree.lib
extern_wcwidth.lib
shlwapi.lib
DbgHelp.lib
Version.lib
bf_rna.lib
bf_dna.lib
bf_imbuf_openexr.lib
bf_imbuf_dds.lib
bf_imbuf_cineon.lib
opengl32.lib
vfw32.lib
kernel32.lib
user32.lib
gdi32.lib
comdlg32.lib
Comctl32.lib
version.lib
advapi32.lib
shfolder.lib
shell32.lib
ole32.lib
oleaut32.lib
uuid.lib
psapi.lib
Dbghelp.lib
Shlwapi.lib
extern_gtest.lib
extern_gmock.lib
extern_glog.lib
extern_gflags.lib
GenericCodeGend.lib
glslangd.lib
MachineIndependentd.lib
OGLCompilerd.lib
OSDependentd.lib
SPIRVd.lib
SPVRemapperd.lib
spirv-cross-cored.lib
spirv-cross-glsld.lib
D:\C\openvr\lib\win64\openvr_api.lib
..\..\..\..\..\libthreepy\..\lib\packages\lib\Catcher_d.lib
..\..\..\..\..\libthreepy\..\lib\packages\lib\xrui_d.lib
winspool.lib



D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_date_time-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_filesystem-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_regex-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_system-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_thread-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_chrono-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\boost_locale-vc140-mt-gd.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO.lib
D:\C\vcpkg\installed\x64-windows-static-custom\debug\lib\OpenImageIO_Util.lib
