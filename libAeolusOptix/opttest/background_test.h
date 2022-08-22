#pragma once

#include "tbb/parallel_for.h"
#include "tbb/blocked_range.h"

static void background_cdf( int start, int end, int res_x, int res_y, const ccl::float3* pixels, ccl::float2* cond_cdf)
{
    int cdf_width = res_x + 1;
    /* Conditional CDFs (rows, U direction). */
    for (int i = start; i < end; i++) {
        float sin_theta = sinf(M_PI_F * (i + 0.5f) / res_y);
        ccl::float3 env_color = pixels[i * res_x];
        float ave_luminance = average(env_color);

        cond_cdf[i * cdf_width].x = ave_luminance * sin_theta;
        cond_cdf[i * cdf_width].y = 0.0f;

        for (int j = 1; j < res_x; j++) {
            env_color = pixels[i * res_x + j];
            ave_luminance = average(env_color);

            cond_cdf[i * cdf_width + j].x = ave_luminance * sin_theta;
            cond_cdf[i * cdf_width + j].y = cond_cdf[i * cdf_width + j - 1].y +
                cond_cdf[i * cdf_width + j - 1].x / res_x;
        }

        float cdf_total = cond_cdf[i * cdf_width + res_x - 1].y +
            cond_cdf[i * cdf_width + res_x - 1].x / res_x;
        float cdf_total_inv = 1.0f / cdf_total;

        /* stuff the total into the brightness value for the last entry, because
         * we are going to normalize the CDFs to 0.0 to 1.0 afterwards */
        cond_cdf[i * cdf_width + res_x].x = cdf_total;

        if (cdf_total > 0.0f)
            for (int j = 1; j < res_x; j++)
                cond_cdf[i * cdf_width + j].y *= cdf_total_inv;

        cond_cdf[i * cdf_width + res_x].y = 1.0f;
    }
}

struct lights_manager {

    bool updateBG = false;
    struct {
        BYTE* ptr;
        size_t        size;
    }  marg_cdf = { nullptr,0 },
        cond_cdf = { nullptr ,0 };
    std::vector<VkDescriptorBufferInfo> bginfo;
    int w=0, h=0;

    typedef uint32_t  u3[3];
    u3 dim = { 1,1,1 };
    uint32_t launchType = 0;

   bool    Dim(int w,int h) {
        if (w * h <= 1024) {
            dim[0] = uint32_t(w * h); dim[1] = 1u; dim[2] = 1u;
        }
        else if (w * h <= 1024 * 1024) { dim[0] = 1024u; dim[1] = uint32_t(w * h / 1024); dim[2] = 1u; }
        else if (w * h <= 1024 * 1024 * 64) {
            dim[0] = 1024; dim[1] = 1024; dim[2] =  uint32_t(w * h / 1024 / 1024);
        }
        else {
            dim[0] = 1024; dim[1] = 1024; dim[2] = 64;
            return false;
        }
        return true;
    }


    template<typename T>
    void build_BackgroundMis(T& memVk) {


        static std::chrono::time_point<std::chrono::steady_clock>  now, start;
        


        ccl::float2* cond = (ccl::float2*) cond_cdf.ptr;
        ccl::float2* marg = (ccl::float2*) marg_cdf.ptr;

        /*
        auto dst = (ccl::float4*)memVk.bamp["kernelBG"].alloc->GetMappedData();
        dst         = dst +  w * h;
        // Create CDF in parallel. 
        const int rows_per_task = ccl::divide_up(h, 8);
        LONG cnt = 0;
        start = std::chrono::high_resolution_clock::now();
        tbb::parallel_for(tbb::blocked_range<size_t>(0, h, rows_per_task),
            [&](const tbb::blocked_range<size_t>& r) {
                InterlockedAdd(&cnt, 1);
                //printf("thread ID  %u    start %u  end %u  \n ", __threadid(), (UINT)r.begin(), (UINT)r.end());
                background_cdf(r.begin(), r.end(), w, h, (ccl::float3*)dst, (ccl::float2*)cond);
         });
        now = std::chrono::high_resolution_clock::now();
        printf("build_BackgroundMis [step 0]   execution Critical    time    %.5f    milli second     Nums %d  \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()),cnt);
        */
      
        start = std::chrono::high_resolution_clock::now();
        {
            int cdf_width = w + 1;
            /* marginal CDFs (column, V direction, sum of rows) */
            marg[0].x = cond[w].x;
            marg[0].y = 0.0f;

            for (int i = 1; i < h; i++) {
                marg[i].x = cond[i * cdf_width + w].x;
                marg[i].y = marg[i - 1].y + marg[i - 1].x / h;
            }

            float cdf_total = marg[h - 1].y + marg[h - 1].x / h;
            marg[h].x = cdf_total;

            if (cdf_total > 0.0f)
                for (int i = 1; i < h; i++)
                    marg[i].y /= cdf_total;

            marg[h].y = 1.0f;
        }
        now = std::chrono::high_resolution_clock::now();
        printf("build_BackgroundMis [step 1]   execution Critical    time    %.5f    milli second   \n ", (float)(std::chrono::duration<double, std::milli>(now - start).count()));


    }

    template<typename T>
    std::vector<VkDescriptorBufferInfo>& device_update_background(ccl::KernelBackground& kbackground,T& memVk) {

        bool realloc = false;
        if (w == 0) {
            realloc = true;
        }
        else if (w * h < kbackground.map_res_x * kbackground.map_res_y) {
            auto ba = memVk.bamp["kernelBG"];
            vkmm::UnmapMemory($pallocator, ba.alloc);
            vkmm::DestroyBuffer($pallocator, ba.buffer, ba.alloc);
            realloc = true;
        }

        w = kbackground.map_res_x, h = kbackground.map_res_y;
        if (w == 0){ w = 512; h = 256;}
        
        static std::vector<VkDescriptorBufferInfo> bginfo(2);
        if (realloc) {
            auto usage = (VkBufferUsageFlagBits)(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT);
            size_t size = (size_t)w *(size_t) h * 2 * sizeof(ccl::uint4);
            size = vkmm::AlignUp((size_t)size, usage);
            memVk.createBuffer("kernelBG", size,
                VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
                vkmm::MEMORY_USAGE_CPU_TO_GPU,
                [&]<class T2>(T2 & a) {
                if (a.alloc->GetMemoryTypeIndex() == 1)
                {
                    printf("need to hostvisible .  \n");
                    exit(-1);
                }
                else if ((a.alloc->GetMemoryTypeIndex() == 2) | (a.alloc->GetMemoryTypeIndex() == 4)) {
                    bginfo[0].buffer = a.buffer;
                    bginfo[0].range = w * h * sizeof(ccl::uint4);
                    bginfo[0].offset = 0;
                    bginfo[1].buffer = a.buffer;
                    bginfo[1].range = w * h * sizeof(ccl::float4);
                    bginfo[1].offset = bginfo[0].range;
                }
            }
            );
        }
        //shade_background_pixels(kbackground.map_res_x, kbackground.map_res_y);

        static bool ini = true;
        auto dst = (ccl::uint4*)memVk.bamp["kernelBG"].alloc->GetMappedData();
        int sumU = 0, sumV = 0;
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                float u = (x + 0.5f) / w;
                float v = (y + 0.5f) / h;
                sumU += int(1000.f * u);
                sumV += int(1000.f * v);
                ccl::uint4 in = ccl::make_uint4(ccl::__float_as_int(u), ccl::__float_as_int(v), x, y);
                dst[x + y * w] = in;
            }
        }





        return bginfo;
    }

    template<typename T>
    std::vector<VkDescriptorBufferInfo>& device_update_background2(ccl::KernelBackground& kbackground, T& memVk) {

#define LAUNCH_MAX_FLOAT4  (1*GB)
        
      

        bool realloc = false;
        if (w == 0) {
            realloc = true;
        }
        else if (w * h < kbackground.map_res_x * kbackground.map_res_y) {
            size_t size = (size_t)w * (size_t)h * sizeof(ccl::float4);
            if (size < LAUNCH_MAX_FLOAT4) {
                auto ba = memVk.bamp["kernelBG"];
                vkmm::UnmapMemory($pallocator, ba.alloc);
                vkmm::DestroyBuffer($pallocator, ba.buffer, ba.alloc);
                realloc = true;
            }
        }

        w = kbackground.map_res_x, h = kbackground.map_res_y;
        if (w == 0) { w = 512; h = 256; }

        
        if (realloc) {
            bginfo.clear();
            bginfo.resize(1);
            auto usage = (VkBufferUsageFlagBits)(VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT);
            size_t size = (size_t)w * (size_t)h  * sizeof(ccl::float4);
            if (size > LAUNCH_MAX_FLOAT4)size = LAUNCH_MAX_FLOAT4;
            else size = vkmm::AlignUp((size_t)size, usage);
            memVk.createBuffer("kernelBG", size,
                VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
                vkmm::MEMORY_USAGE_CPU_TO_GPU,
                [&]<class T2>(T2 & a) {
                if (a.alloc->GetMemoryTypeIndex() == 1)
                {
                    printf("need to hostvisible .  \n");
                    exit(-1);
                }
                else if ((a.alloc->GetMemoryTypeIndex() == 2) | (a.alloc->GetMemoryTypeIndex() == 4) | (a.alloc->GetMemoryTypeIndex() == 3)) {
                    bginfo[0].buffer = a.buffer;
                    bginfo[0].range = w * h * sizeof(ccl::float4);
                    bginfo[0].offset = 0;
                }
            }
            );
        }
        //shade_background_pixels(kbackground.map_res_x, kbackground.map_res_y);

        static bool ini = true;
        Dim(w, h);

        printf("  BG render  dimension  %u  %u %u  \n ", dim[0], dim[1], dim[2]);


        return bginfo;
    }
    template<class T, class T2>
    void build(T&rtVk,T2& mat, ccl::KernelBackground& kbackground) {

        std::vector<VkDescriptorBufferInfo>& binfos = device_update_background2(kbackground, memVk);
        mat.writeDescsriptorSet_BG2(4, binfos);
        mat.buffer_barrierBG = [&](VkCommandBuffer cmd) {

            VkBufferMemoryBarrier memoryBarrier = {
            .sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,
             .pNext = nullptr,
            .srcAccessMask = (VkAccessFlags)((launchType==0) ?VK_ACCESS_SHADER_WRITE_BIT: VK_ACCESS_SHADER_READ_BIT),
            .dstAccessMask = (VkAccessFlags)((launchType == 0) ?VK_ACCESS_SHADER_READ_BIT: VK_ACCESS_SHADER_WRITE_BIT),
            .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
            .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
            .buffer = bginfo[0].buffer,
            .offset = bginfo[0].offset,
            .size = bginfo[0].range,
            };
            vkCmdPipelineBarrier(cmd,
                VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_NV, // srcStageMask
                VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_NV, // dstStageMask
                VK_DEPENDENCY_DEVICE_GROUP_BIT,
                0,                                    // memoryBarrierCount
                nullptr,
                1,
                &memoryBarrier,
                0,
                nullptr
            );
        };

        if (lm.updateBG) {
            mat.bgInfo.bg_make = true;

            void* dst = memVk.bamp["kerneldata"].alloc->GetMappedData();
            int* counter = (int*)((BYTE*)dst + kb.alloinfo.offset);
            counter[1] = 0;
           
            if (!Dim(w, h)) {
                int lastY = h;
                counter[500] = 0;
                for(;;) {
                    int cH = (dim[0] * dim[1] * dim[2]) / w;
                    for (int i = 0; i < 3; i++)mat.bgInfo.dim[i] = lm.dim[i];
                    counter[1] = h - lastY;
                    launchType = counter[0] = 0;
                    rtVk.submitRayTracing(3, &mat);
                    launchType =  1;


/*//SubGroup Check
counter[0] = 1;
lm.Dim(cH, 1);
for (int i = 0; i < 3; i++)mat.bgInfo.dim[i] = lm.dim[i];
rtVk.submitRayTracing(3, &mat);

ccl::float2* cond = (ccl::float2*) cond_cdf.ptr;
std::vector<ccl::float2>    check;

for (int j = 0; j < lm.w+1; j++) {
    int i = 112;
    int k = i * (lm.w + 1) + j;
    check.push_back(cond[k]);
}
*///SubGroup Check



                    lm.Dim(cH, 32);
                    for (int i = 0; i < 3; i++)mat.bgInfo.dim[i] = lm.dim[i];
                    counter[0] = 6;
                    counter[2] = cH;
                    rtVk.submitRayTracing(3, &mat);

                    printf(" counter 500  [ %d ]\n", counter[500]);

/*//SubGroup Check
cond = (ccl::float2*) cond_cdf.ptr;
int cnt = 0;
for (int j = 0; j < lm.w + 1; j++) {
        int i  = 112;
        int k = i * (lm.w + 1) + j;
            printf("  [%d %d]  compare x %s  y %s     cond  %f %f  trueth  %f %f  \n", i, j,
                (cond[k].x == check[j].x) ? "T" : "F",
                (cond[k].y == check[j].y) ? "T" : "F",
                cond[k].x, cond[k].y, check[j].x, check[j].y
            );
        // if (cnt++ % 128 == 0)printf("\n");
}
*///SubGroup Check


                    counter[500] = h - lastY + cH;

                    lastY -= cH;
                    if (lastY <= 0)break;
                    Dim(w, lastY);
                }
                lm.build_BackgroundMis(memVk);
            }
            else {
                /* Check  Type 5
                ccl::float2* cond = (ccl::float2*) cond_cdf.ptr;
                for (int i = 0; i < 32 * 34; i++) {
                    cond[i] = make_float2(0., 0.);
                }
                mat.bgInfo.dim[0] = 32 * 32;
                mat.bgInfo.dim[1] = 34;
                mat.bgInfo.dim[2] = 1;
                launchType = 0;
                counter[0] = 5;
                rtVk.submitRayTracing(3, &mat);
                int sum = 0;
                for (int smID = 0; smID < 34; smID++) {
                    int sumsm = 0;
                    int j = 500 + smID;
                    for (int wID = 0; wID < 32; wID++) {
                        int ID = smID * 32 + wID;
                        sumsm +=( int(cond[ID].x));
                        printf("  smID %d  wID %d    x %f  y  %f      sum  %d \n ", smID, wID, cond[ID].x, cond[ID].y ,sumsm);
                    }
                    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>  sm SUM %d   mxID SUM %d    \n ", counter[j], sumsm);
                    assert(counter[j] == sumsm);
                    sum += counter[j];
                    counter[j] = 0;
                }
                printf("counter %d   \n", sum);
                assert(sum == 32 * 32 * 34);
                */
                for (int i = 0; i < 3; i++)mat.bgInfo.dim[i] = lm.dim[i];
                counter[0]  = 0;
                counter[1]  = 0;
                rtVk.submitRayTracing(3, &mat);

                
                lm.Dim(lm.h, 32);
                for (int i = 0; i < 3; i++)mat.bgInfo.dim[i] = lm.dim[i];
                counter[0]     =  8;
                counter[1]      =  0;
                counter[2]     =  lm.h;
                counter[500] =0;
                rtVk.submitRayTracing(3, &mat);

                printf(" counter 500  [ %d ]\n", counter[500]);




                lm.build_BackgroundMis(memVk);
            }
            printf("  BG render  dimension  %u  %u %u  \n ", dim[0], dim[1], dim[2]);


        }
    }



};
