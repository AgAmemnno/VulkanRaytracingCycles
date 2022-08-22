/*
 * Copyright 2011-2016 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "util/util_debug2.h"
#include "util/util_logging.h"
#include "util/util_string.h"

#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#include <intrin.h>

#ifdef WITH_REDIS
namespace dump {

    static const char* reply_types[] = {
    "REPLY0",
    "STRING",
     "ARRAY",
    "INTEGER",
    "NIL",
    "STATUS",
    "ERROR",
    "UNKNWON"
    };
    //#define  RD_DEB_PRINT 1
    RedisCli::RedisCli() { c = NULL;  connect(); }
    RedisCli::~RedisCli() { disconnect(); }

    void  RedisCli::connect() {
        if (c != NULL)return;
        unsigned int isunix = 0;

        const char* hostname = "127.0.0.1";
        int port = 6379;

        const struct timeval  timeout = { 1, 500000 }; // 1.5 seconds
        if (isunix) {
            c = redisConnectUnixWithTimeout(hostname, timeout);
        }
        else {
            c = redisConnectWithTimeout(hostname, port, timeout);
        }
        if (c == NULL || c->err) {
            if (c) {
                printf("Connection error: %s\n", c->errstr);
                redisFree(c);
            }
            else {
                printf("Connection error: can't allocate redis context\n");
            }
            exit(1);
        }

        if (binfo.signal12345 != NULL) { CloseHandle(binfo.signal12345); binfo.signal12345 = NULL; };
        binfo.signal12345 = CreateSemaphore(NULL, 0, LIMIT12345, (std::string("BLENDER_INFO") + std::to_string(12345)).c_str());

        if (binfo.signal54321 != NULL) { CloseHandle(binfo.signal54321); binfo.signal54321 = NULL; };
        binfo.signal54321 = CreateSemaphore(NULL, 0, LIMIT54321, (std::string("BLENDER_INFO") + std::to_string(54321)).c_str());

    };
    void  RedisCli::disconnect() {
        if (c != NULL)redisFree(c);
        c = NULL;
        if (binfo.signal12345 != NULL) { CloseHandle(binfo.signal12345); };
        binfo.signal12345 = NULL;
        if (binfo.signal54321 != NULL) { CloseHandle(binfo.signal54321); };
        binfo.signal54321 = NULL;
    }
};


std::vector<std::string> dump::split(std::string s, std::string delimiter) {
    size_t pos_start = 0, pos_end, delim_len = delimiter.length();
    std::string token;
    std::vector<std::string> res;

    while ((pos_end = s.find(delimiter, pos_start)) != std::string::npos) {
        token = s.substr(pos_start, pos_end - pos_start);
        pos_start = pos_end + delim_len;
        res.push_back(token);
    }

    res.push_back(s.substr(pos_start));
    return res;
}

std::string  dump::RedisCli::format(float3 val) {
    return  string_format("%.6f,%.6f,%.6f \n ", val.x, val.y, val.z);
}
std::string  dump::RedisCli::format(int2 val) {
    return  string_format("%d,%d \n ", val.x, val.y);
}
std::string  dump::RedisCli::format(float val) {
    return string_format("%.6f\n ", val);
}
std::string  dump::RedisCli::format(UINT val) {
    return string_format("%u\n ", val);
}

void  dump::RedisCli::send12345(int2 val,int recmx) {

    auto v = format(val);
    RD_CHECK(redisCommand(c, "HSET semaphore12345  status  %s ", Status.c_str()));
    RD_CHECK(redisCommand(c, "HSET semaphore12345 recMax %d ",recmx));
    RD_CHECK(redisCommand(c, "HSET semaphore12345  xy %s ", v.c_str()));
    Signal(12345);
    Status = "None";
}

void dump::RedisCli::wait54321(bool& abort) {
    Wait(54321);
    redisReply* reply = (redisReply*)redisCommand(c, "GET semaphore54321 ");
    printf("Waiting for signal 54321   ==>   reply %s  \n", reply->str);
    if (std::string(reply->str) != "ok") abort = true;
    freeReplyObject(reply);
};
#endif

#ifndef STAT_CLIENT
void STATS_AUX::init(std::string deb ) {
    sinfo.abort = true;
    use_rsend  = false;
    use_pixel = false;
    use_buffer_dump = false;
    if (deb == "BG")sinfo.abort = false;
    else {
        auto stv = dump::split(redis->debugStr, ",");
        if (stv.size() > 1) {
            if (stv[0] == "ByPixel") sinfo.abort = false;
            else if(stv[0] == "ByPixelDump"){
                sinfo.abort = false; use_buffer_dump = true;
            }
            else printf("Task Abort . Unknown Parameter Stat_AUX   [ByPixel ,x,y]  [ByTile]  [ByTileRandom] \n");
            if (!sinfo.abort) {
                assert(stv.size() >= 3);
                use_pixel = true;
                sinfo.rx = std::atoi(stv[1].c_str());
                sinfo.ry = std::atoi(stv[2].c_str());
            }
        }
        else {
            if (redis->debugStr == "ByTile")sinfo.abort = false;
            if (redis->debugStr == "ByTileRandom") {
                sinfo.abort = false;
                use_rsend = true;
            }
        }

        redis->FlushDB(5);
        redis->Status = "None";

    }

#ifdef WITH_REDIS
    redis->connect();
#endif
    amt = 0;
    hit = miss = 0;
    hit_rec = 0;
    for (int i = 0; i < MAX_HIT; i++)hit_rec_cnt[i] = 0;
    for (int i = 0; i < CNT_MAX_ALO; i++) counter[i] = 0;
    lampemi = 0;
    randu = randv = randw = 0;
    node_profi = 0;
    assert(amt == 0 && hit == 0 && hit_rec == 0 && lampemi == 0);

};
void STATS_AUX::end() {
    
    redis->SelectDB(2);
    std::string cnt = "HMSET CNT ";
    for (int i = 0; i < CNT_MAX_ALO; i++) cnt += string_format(" %d %d ", i, counter[i]);
    RD_CHECK(redisCommand(redis->c, cnt.c_str()));

};
bool STATS_AUX::getAtomicPrint(bool off) {
    static thread_local bool node_thr = false;
    if (off) node_thr = false;
    if (node_profi > 0)return node_thr;
    int  id = InterlockedAdd(&node_profi, 1);
    if (id == 1)node_thr = true;
    return node_thr;
}
void STATS_AUX::addV3(ccl::float3& v) {

    int x = (int)(precision * v.x);
    int y = (int)(precision * v.y);
    int z = (int)(precision * v.z);
    add(&randu, x);
    add(&randv, y);
    add(&randw, z);

};
long STATS_AUX::add(long* v) {
    return InterlockedAdd(v, 1);
};
long STATS_AUX::add(long* v, long val) {
    return InterlockedAdd(v, val);
};

#ifdef WITH_STAT_ALL 
void STATS_AUX::start(bool light_pass) {
    dump_num = 1;
    rec_num = 0;
    use_light_pass = light_pass;
};
long STATS_AUX::addMiss() {
     add(&counter[CNT_MISS]);
    long  v = InterlockedAdd(&tile_miss, 1) - 1;
    if (v==0) {
        sinfo.bg_send = true;
        redis->Status = "BG";
    }else
        sinfo.bg_send = false;
    return v;
};

long STATS_AUX::add(std::string n) {
    if(dump_num != -1 && dump_num != rec_num) return 0;
    /*
    if(eSTAT.count(n) > 0)return InterlockedAdd(&data[eSTAT[n]], 1);
    */
    return 0;
};

long STATS_AUX::add(std::string n, ccl::float3&  f3,float prec) {
    if (dump_num != -1 && dump_num != rec_num) return 0;
    /*
    if (eSTATV3.count(n) > 0) {
        InterlockedAdd((LONG*)&(v3[eSTATV3[n]].x), abs(int(prec * f3.x)));
        InterlockedAdd((LONG*)&(v3[eSTATV3[n]].y), abs(int(prec * f3.y)));
        InterlockedAdd((LONG*)&(v3[eSTATV3[n]].z), abs(int(prec * f3.z)));
    }
    */
    return 0;
};

bool STATS_AUX::objectAdd(int i) {
    long flag = 1 << i;
    bool obj0  =  !bool(flag & InterlockedOr(&obj_reg[rec_num], flag));
    if ( !use_rsend && !use_pixel &&
         ( obj0 && !sinfo.obj_has_send )
       ){
        sinfo.obj_send = true;
       }
   if(sinfo.obj_send)redis->Status = "OBJ" + std::to_string(i);
   assert(!(sinfo.obj_has_send && sinfo.obj_send));
    return sinfo.obj_send;
};

void STATS_AUX::send_byObject() {
    if (!(sinfo.obj_send || sinfo.bg_send)) return;
    if (sinfo.abort) return;

    redis->SelectDB(5);
    redis->ConsumeWait(54321, LIMIT54321);
    if (sinfo.obj_send) {
        static int cnt = 0;
        printf(" Object Send   %d  %d     %d   \n", sinfo.x, sinfo.y, cnt++);
    }
    redis->send12345(make_int2(sinfo.x, sinfo.y), rec_num);
    redis->wait54321(sinfo.abort);

    if (use_pixel && sinfo.obj_send) {
        sinfo.abort = true;
        
    }

    redis->FlushDB(5);
    sinfo.obj_send = sinfo.bg_send = false;
    if(!use_rsend && !use_pixel)sinfo.obj_has_send = true;
};
void STATS_AUX::send_byPixel() {

    if (sinfo.obj_send || sinfo.bg_send) {

        send_byObject();
    }

};
#endif



   
void STATS_AUX::print() {

    printf(" #######################STATS#########################\n\n ");
    printf(" ####################### amt %d  hit %d  miss %d   #############\n", amt, hit, miss);
    printf(" ####################### hit_rec %d   lampemi %d  #############\n", hit_rec, lampemi);

    /*
     for (int i = 0; i < MAX_HIT; i++) {
        printf(" hitnums  %d   %d  \n", i, hit_rec_cnt[i]);
    }
    for (int i = 0; i < 10; i++) {
        printf(" data  %d   %d  \n", i, data[i]);
    };
    */

    printf(" ####################### randu %d  randv %d randw %d  #############\n", randu, randv, randw);
    printf(" #######################STATS#########################\n\n ");

}

#endif