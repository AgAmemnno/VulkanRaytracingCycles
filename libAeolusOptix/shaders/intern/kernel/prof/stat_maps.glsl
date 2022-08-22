#define WITH_STAT_ALL

#if defined(WITH_STAT_ALL) 
bool G_use_light_pass;
bool G_dump = false;
int  rec_num = 0;
uvec2 Dpixel= kg.pixel;

#if defined(SET_KERNEL)
#define setDumpPixel() {\
    rec_num = 0;\
    G_dump = false;\
    if(Dpixel == gl_LaunchIDNV.xy){\
         G_dump = true;\
         G_use_light_pass = bool(kernel_data.film.use_light_pass);\
    }\
}
#else
#define setDumpPixel() {\
    rec_num = 0;\
    G_dump = false;\
    if(Dpixel == gl_LaunchIDNV.xy){\
         G_dump = true;\
    }\
}
#endif




#define STAT_DUMP_f3(n,v) if(G_dump)kg.f3[n + (rec_num-1)*STAT_BUF_MAX]  = v;
#define STAT_DUMP_f1(n,v) if(G_dump)kg.f1[n + (rec_num-1)*STAT_BUF_MAX]  = v;
#define STAT_DUMP_u1(n,v) if(G_dump)kg.u1[n + (rec_num-1)*STAT_BUF_MAX]  = v;
#define STAT_DUMP_u1_add(n) if(G_dump)atomicAdd(kg.u1[n],1);
#define STAT_CNT(n,v) if(G_dump)counter[n]  = v;

#include "kernel/prof/count_def.h"

#define CNT_ADD(n) atomicAdd(counter[n],1)

#include "kernel/prof/bp_def.h"

#endif