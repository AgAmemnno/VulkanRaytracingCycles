#pragma once

#include "cuda.h"
#include "RedisUtils.h"

#define ALLOC_TEX_UNIT 128

#define TEX_DESC_COMBINED_SAMPLER 0
#define TEX_DESC_SEPARATE_SAMPLER 1

#define TEX_DESC_TYPE TEX_DESC_SEPARATE_SAMPLER


typedef struct  SIvk {

    VkSampler  sampler;
    VkDescriptorImageInfo  Info;

    bool                                valid;
    int version = { -1 };
    SIvk() :
        sampler(VK_NULL_HANDLE),
        Info({}),
        valid(false)
    {

    };
    void dealloc() {
        if (sampler != VK_NULL_HANDLE) vkDestroySampler($device, sampler, nullptr);
            sampler = VK_NULL_HANDLE;
    };
    bool isValid() {
        return sampler != VK_NULL_HANDLE;
    }
}SIvk;

struct  BLTextures {
    ImmidiateCmdPool       imcm;
    std::vector<VkDescriptorImageInfo>  iinfo;
    std::vector<MIVSIvk>  storeDesc;
    std::vector<SIvk>  samplerDesc;
    MIVSIvk          nullDesc;


    ImageManager* image_manager = nullptr;
    std::map<std::string, std::string> EnvNodes;
    std::map<uint32_t, std::pair<int,std::string>>  slotCache;


    BLTextures() {
        imcm.alloc();
        DeviceInfo  dinfo;
        image_manager = new ImageManager(dinfo);
    };
    ~BLTextures() {
        Flush();
        image_manager->device_free((Device*)0) ;
        delete image_manager;
        nullDesc.dealloc();
        for (auto& d : samplerDesc) {
            d.dealloc();
        }
        samplerDesc.clear();
        imcm.free();
    };
    void Flush() {
        for (auto& d : storeDesc) {
            d.dealloc();
        }
        storeDesc.clear();
       
    }
    template<typename T>
    bool getMap(T*& dst, MIVSIvk& miv,VkDeviceSize offset =0 ) {
        VK_CHECK_RESULT(vkMapMemory($device, miv.memory,  offset, miv.size, 0, (void**)&dst));
        return true;
    };

    void CopyArrayAfterX(VkBuffer src, MIVSIvk& dst, std::vector<VkBufferImageCopy> _bufferCopyRegion, VkImageLayout X) {


        std::vector<VkBufferImageCopy> bufferCopyRegion;
        int base = 0;
        for (auto& region : _bufferCopyRegion) {
            if ((UINT32)base > region.imageSubresource.baseArrayLayer) base = region.imageSubresource.baseArrayLayer;
            if (region.imageExtent.width != 0)bufferCopyRegion.push_back(region);
        };

        VkImageSubresourceRange subresourceRange = {};
        subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        subresourceRange.baseMipLevel = 0;
        subresourceRange.levelCount = 1;
        subresourceRange.layerCount = uint32_t(_bufferCopyRegion.size());
        subresourceRange.baseArrayLayer = base;

        imcm.begin();

        vka::shelve::setImageLayout(
            imcm.cmd,
            dst.image,
            dst.Info.imageLayout,
            VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            subresourceRange);

        vkCmdCopyBufferToImage(
            imcm.cmd,
            src,
            dst.image,
            VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            bufferCopyRegion.size(),
            bufferCopyRegion.data()
        );


        vka::shelve::setImageLayout(
            imcm.cmd,
            dst.image,
            VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
            X,
            subresourceRange);

        imcm.end();
        imcm.submit();
        imcm.wait();


        log_img("setImageLayout  %u   -->  %u   \n", dst.Info.imageLayout, X);


        dst.Info.imageLayout = X;

    };
    bool bridgeMap(MIVSIvk& _, void* src, VkImageLayout X) {

        imcm.allocStaging(_);

        char* dst;

        VK_CHECK_RESULT(vkMapMemory($device, imcm.staging.memory, 0, imcm.staging.allocInfo.allocationSize, 0, (void**)&dst));
        memcpy(dst, src, _.size);
        vkUnmapMemory($device, imcm.staging.memory);


        VkBufferImageCopy Region = {};
        Region.imageSubresource.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
        Region.imageSubresource.mipLevel = 0;
        Region.imageSubresource.layerCount = 1;
        Region.imageExtent.width = _.w;
        Region.imageExtent.height = _.h;
        Region.imageExtent.depth = 1;

        std::vector<VkBufferImageCopy> bufferCopyRegions;
        for (int i = 0; i < (int)_.l; i++) {
            Region.imageSubresource.baseArrayLayer = i;
            if (i > 0)Region.imageExtent.width = 0;
            bufferCopyRegions.push_back(Region);
        }

        CopyArrayAfterX(imcm.staging.buffer, _, std::move(bufferCopyRegions), X);


        return true;

    };
    VkFormat Cu2VulFormat(CUarray_format format, uint32_t numChannels,uint32_t& psize) {
#define RET_TYPE(ch,ty) \
            if (numChannels == 1)return VK_FORMAT_R ##ch ##_ ##ty;\
            if (numChannels == 2)return VK_FORMAT_R ##ch##G##ch ##_ ##ty;\
            if (numChannels == 3)return VK_FORMAT_R ##ch##G##ch##B##ch ##_ ##ty;\
            if (numChannels == 4)return VK_FORMAT_R ##ch##G##ch##B##ch##A##ch ##_ ##ty;

        switch (format)
        {
        case         CU_AD_FORMAT_UNSIGNED_INT8:
            psize = 1;
            RET_TYPE(8, UNORM) //UINT) //UNORM USCALED SRGB
                break;
        case        CU_AD_FORMAT_UNSIGNED_INT16: /**< Unsigned 16-bit integers */
            psize = 2;
            RET_TYPE(16, UINT) //UNORM USCALED SRGB
                break;
        case        CU_AD_FORMAT_UNSIGNED_INT32:  /**< Unsigned 32-bit integers */
            psize = 4;
            RET_TYPE(32, UINT) //UNORM USCALED SRGB
                break;
        case        CU_AD_FORMAT_SIGNED_INT8: /**< Signed 8-bit integers */
            psize = 1;
            RET_TYPE(8, SINT) //UNORM USCALED SRGB
                break;
        case        CU_AD_FORMAT_SIGNED_INT16:/**< Signed 16-bit integers */
            psize = 2;
            RET_TYPE(16, SINT) //UNORM USCALED SRGB
                break;
        case        CU_AD_FORMAT_SIGNED_INT32: /**< Signed 32-bit integers */
            psize = 4;
            RET_TYPE(32, SINT) //UNORM USCALED SRGB
                break;
        case       CU_AD_FORMAT_HALF:  /**< 16-bit floating point */
            psize = 2;
            RET_TYPE(16, SFLOAT) //UNORM USCALED SRGB
                break;
        case       CU_AD_FORMAT_FLOAT: /**< 32-bit floating point */
            psize = 4;
            RET_TYPE(32, SFLOAT) //UNORM USCALED SRGB
                break;
        default:
            log_bad("UnKnown Format   %u    Cuda Resource   \n", format);
            break;
        }

#undef RET_TYPE
        assert(false && "Enreachable. Cuda texture type not found.");
        return (VkFormat)0;
    }


    ///TODO reallocate slot more
#define MAX_TEXURE_SLOT 128
    void textureLoad_json(RedisUtils& rd, ccl::TextureInfo* tinfo, size_t size) {

        ///  SLOT MAX 128    allocated 64~  for large textures;
        using namespace macaron;

        auto tex  = bl.document["Tex"].GetObjectA();

        CUDA_RESOURCE_DESC  resDesc;
        CUDA_TEXTURE_DESC    texDesc;
        BYTE* dst = nullptr;
        static  std::string hash;
        Flush();
        initDescriptorsSlots();
        for (int i = 0; i < size / 96; i++) {
            ccl::TextureInfo& ti = tinfo[i];
            if (ti.width == (UINT)-1) break;
            if (ti.data >= 64) {
                log_bad("SLOT MAX out of range \n");
            }


            bool load_data = true;
            decltype(slotCache)::iterator it = slotCache.find(ti.cl_buffer);

            if (it != slotCache.end()) {
                load_data = false;
                hash = ("Texture::" + std::get<1>(slotCache[ti.cl_buffer]));
            }
            else
                hash = ("Texture::" + std::to_string(ti.cl_buffer));
            const char* HASH = hash.c_str();

            assert(tex.HasMember(HASH) );
            auto tdata  = tex[HASH].GetObjectA();

            std::string Jstr = tdata["rDesc"].GetString();
            bl.decodeJson(&resDesc, Jstr);
            Jstr = tdata["tDesc"].GetString();
            bl.decodeJson(&texDesc, Jstr);
           

            bool alloc = false;
            MIVSIvk miv;
            VkImageCreateInfo imageInfo{};
            if (SetImageAttributes(miv, imageInfo, resDesc, texDesc)) {
                /// try  to allocate on Device Local memory.
                if (create2D(miv, imageInfo)) {
                    iinfo[ti.data] = miv.Info;   //SLOT  NUM 
                    if (TEX_DESC_TYPE == TEX_DESC_SEPARATE_SAMPLER) {
                        iinfo[ti.data].sampler = VK_NULL_HANDLE;
                    }
                    storeDesc.push_back(miv);
                    void* data_ptr = nullptr;
                    if (load_data) {
                        std::string ptr = tdata["data"].GetString();
                        bridgeMap(miv, (void*)ptr.data(), VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
                    }
                    else {
                        auto img = image_manager->get_image(std::get<0>(slotCache[ti.cl_buffer]));
                        data_ptr = (void*)img->mem->host_pointer;
                        bridgeMap(miv, data_ptr, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
                    }

                    alloc = true;
                }
            }
            if (!alloc) {
                /// try  to allocate on Host Visible memory. 
                auto properties = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
                MIVSIvk* mmiv = &miv;
                auto slot = ti.data;
                BYTE* data_ptr = nullptr;
                BYTE* dst_ptr = nullptr;
                if (load_data) {
                    data_ptr = (BYTE*)tdata["data"].GetString();
                }
                else {
                    auto img = image_manager->get_image(i);
                    data_ptr = (BYTE*)img->mem->host_pointer;
                }
                size_t total = miv.size;
                size_t bsize;
                for (;;) {

                    bsize = (total > HOST_VISIBLE_SINGLE_ALLO_MAX) ? HOST_VISIBLE_SINGLE_ALLO_MAX : total;
                    imageInfo.extent.height = mmiv->h = (int)(bsize / miv.w / miv.c);
                    mmiv->size = mmiv->h * miv.w * miv.c;
                    total -= mmiv->size;
                    create2D(*mmiv, imageInfo, (VkMemoryPropertyFlagBits)properties);
                    iinfo[slot] = mmiv->Info;   //SLOT  NUM 
                    if (TEX_DESC_TYPE == TEX_DESC_SEPARATE_SAMPLER) {
                        iinfo[slot].sampler = VK_NULL_HANDLE;
                    }
                    VK_CHECK_RESULT(vkMapMemory($device, mmiv->memory, 0, mmiv->size, 0, (void**)&mmiv->mapped));
                    memcpy(mmiv->mapped, data_ptr, mmiv->size);
                    data_ptr += size;
                    slot += 64;
                    if (slot >= MAX_TEXURE_SLOT) {
                        log_bad("Texture size too big \n");
                    }
                    if (total <= 0)break;
                    mmiv->next = new MIVSIvk;
                    mmiv = mmiv->next;
                    mmiv->w = miv.w;
                    mmiv->d = 1;
                    mmiv->c = miv.c;
                }
                storeDesc.push_back(miv);
            }
        }
    }





bool  SetImageAttributes(MIVSIvk& miv,VkImageCreateInfo& imageInfo,CUDA_RESOURCE_DESC& resDesc, CUDA_TEXTURE_DESC& texDesc) {
       auto properties = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
       imageInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
       imageInfo.imageType = VK_IMAGE_TYPE_2D;
       uint32_t pixel = 1;
       switch (resDesc.resType) {
       case CU_RESOURCE_TYPE_PITCH2D:
           auto   pit = resDesc.res.pitch2D;
           imageInfo.format = Cu2VulFormat(pit.format, pit.numChannels, pixel);
           miv.w = imageInfo.extent.width = pit.width;
           miv.h = imageInfo.extent.height = pit.height;
           miv.d = imageInfo.extent.depth = 1;
           imageInfo.mipLevels = 1;
           miv.l = imageInfo.arrayLayers = 1;
           miv.c = pit.numChannels;
           miv.size = miv.w * miv.h * miv.c * pixel;
           break;
       default:
           log_bad("Unknown Resource Type   %u    \n ", resDesc.resType);
       }
       if (miv.size > HOST_VISIBLE_SINGLE_ALLO_MAX) {
           return false;
       }

       imageInfo.samples = VK_SAMPLE_COUNT_1_BIT;
       imageInfo.tiling = VK_IMAGE_TILING_LINEAR;
       imageInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
       imageInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
       //if (properties == 0x1) imageInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
       imageInfo.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_SAMPLED_BIT;
       return true;
   }
uint32_t MemoryTypeIndexToHeapIndex(uint32_t memTypeIndex) const
{
    assert(memTypeIndex < $memoryProperties.memoryTypeCount);
    return $memoryProperties.memoryTypes[memTypeIndex].heapIndex;
}
VkResult  AllocateVulkanMemory(VkMemoryAllocateInfo* pAllocateInfo, VkDeviceMemory* pMemory)
{
    const uint32_t heapIndex = MemoryTypeIndexToHeapIndex(pAllocateInfo->memoryTypeIndex);

    VkResult res;

        ///VmaMutexLock lock(m_HeapSizeLimitMutex, m_UseMutex);
        /// 
        if (vkmm::HeapLimit[heapIndex] >= pAllocateInfo->allocationSize)
        {
            res = vkAllocateMemory($device, pAllocateInfo, memVk.allocInfo.pAllocationCallbacks, pMemory);
            if (res == VK_SUCCESS)
            {
                vkmm::HeapLimit[heapIndex] -= pAllocateInfo->allocationSize;
            }
        }
        else
        {
            res = VK_ERROR_OUT_OF_DEVICE_MEMORY;
        }

    /*
    if (res == VK_SUCCESS && m_DeviceMemoryCallbacks.pfnAllocate != nullptr)
    {
        (*m_DeviceMemoryCallbacks.pfnAllocate)(this, pAllocateInfo->memoryTypeIndex, *pMemory, pAllocateInfo->allocationSize);
    }
    */

    return res;
}

    bool  create2D(MIVSIvk& miv, VkImageCreateInfo& imageInfo, VkMemoryPropertyFlagBits  properties = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
    {

        /*
        typedef enum CUresourcetype_enum {
            CU_RESOURCE_TYPE_ARRAY = 0x00,
            CU_RESOURCE_TYPE_MIPMAPPED_ARRAY = 0x01,
            CU_RESOURCE_TYPE_LINEAR = 0x02,
            CU_RESOURCE_TYPE_PITCH2D = 0x03
        } CUresourcetype;
        typedef struct CUDA_RESOURCE_DESC_st
{
    CUresourcetype resType;                   //< Resource type

        union {
            struct {
                CUarray hArray;                   //< CUDA array
            } array;
            struct {
                CUmipmappedArray hMipmappedArray; //< CUDA mipmapped array
            } mipmap;
            struct {
                CUdeviceptr devPtr;               //< Device pointer
                CUarray_format format;            //< Array format
                unsigned int numChannels;         //< Channels per array element
                size_t sizeInBytes;               //< Size in bytes
            } linear;
            struct {
                CUdeviceptr devPtr;               //< Device pointer
                CUarray_format format;            //< Array format
                unsigned int numChannels;         //< Channels per array element
                size_t width;                     //< Width of the array in elements
                size_t height;                    //< Height of the array in elements
                size_t pitchInBytes;              //< Pitch between two rows in bytes
            } pitch2D;
            struct {
                int reserved[32];
            } reserved;
        } res;

        unsigned int flags;                       //< Flags (must be zero)
    } CUDA_RESOURCE_DESC;
        */
        /*
              VkFormat format, VkImageUsageFlags  flag, VkMemoryPropertyFlags properties)
              typedef enum VkFormat {
          VK_FORMAT_UNDEFINED = 0,
          VK_FORMAT_R4G4_UNORM_PACK8 = 1,
          VK_FORMAT_R4G4B4A4_UNORM_PACK16 = 2,
          VK_FORMAT_B4G4R4A4_UNORM_PACK16 = 3,
          VK_FORMAT_R5G6B5_UNORM_PACK16 = 4,
          VK_FORMAT_B5G6R5_UNORM_PACK16 = 5,
          VK_FORMAT_R5G5B5A1_UNORM_PACK16 = 6,
          VK_FORMAT_B5G5R5A1_UNORM_PACK16 = 7,
          VK_FORMAT_A1R5G5B5_UNORM_PACK16 = 8,
          VK_FORMAT_R8_UNORM = 9,
          VK_FORMAT_R8_SNORM = 10,
          VK_FORMAT_R8_USCALED = 11,
          VK_FORMAT_R8_SSCALED = 12,
          VK_FORMAT_R8_UINT = 13,
          VK_FORMAT_R8_SINT = 14,
          VK_FORMAT_R8_SRGB = 15,
          VK_FORMAT_R8G8_UNORM = 16,
          VK_FORMAT_R8G8_SNORM = 17,
          VK_FORMAT_R8G8_USCALED = 18,
          VK_FORMAT_R8G8_SSCALED = 19,
          VK_FORMAT_R8G8_UINT = 20,
          VK_FORMAT_R8G8_SINT = 21,
          VK_FORMAT_R8G8_SRGB = 22,
          VK_FORMAT_R8G8B8_UNORM = 23,
          VK_FORMAT_R8G8B8_SNORM = 24,
          VK_FORMAT_R8G8B8_USCALED = 25,
          VK_FORMAT_R8G8B8_SSCALED = 26,
          VK_FORMAT_R8G8B8_UINT = 27,
          VK_FORMAT_R8G8B8_SINT = 28,
          VK_FORMAT_R8G8B8_SRGB = 29,
          VK_FORMAT_B8G8R8_UNORM = 30,
          VK_FORMAT_B8G8R8_SNORM = 31,
          VK_FORMAT_B8G8R8_USCALED = 32,
          VK_FORMAT_B8G8R8_SSCALED = 33,
          VK_FORMAT_B8G8R8_UINT = 34,
          VK_FORMAT_B8G8R8_SINT = 35,
          VK_FORMAT_B8G8R8_SRGB = 36,
          VK_FORMAT_R8G8B8A8_UNORM = 37,
          VK_FORMAT_R8G8B8A8_SNORM = 38,
          VK_FORMAT_R8G8B8A8_USCALED = 39,
          VK_FORMAT_R8G8B8A8_SSCALED = 40,
          VK_FORMAT_R8G8B8A8_UINT = 41,
          VK_FORMAT_R8G8B8A8_SINT = 42,
          VK_FORMAT_R8G8B8A8_SRGB = 43,
          VK_FORMAT_B8G8R8A8_UNORM = 44,
          VK_FORMAT_B8G8R8A8_SNORM = 45,
          VK_FORMAT_B8G8R8A8_USCALED = 46,
          VK_FORMAT_B8G8R8A8_SSCALED = 47,
          VK_FORMAT_B8G8R8A8_UINT = 48,
          VK_FORMAT_B8G8R8A8_SINT = 49,
          VK_FORMAT_B8G8R8A8_SRGB = 50,
          VK_FORMAT_A8B8G8R8_UNORM_PACK32 = 51,
          VK_FORMAT_A8B8G8R8_SNORM_PACK32 = 52,
          VK_FORMAT_A8B8G8R8_USCALED_PACK32 = 53,
          VK_FORMAT_A8B8G8R8_SSCALED_PACK32 = 54,
          VK_FORMAT_A8B8G8R8_UINT_PACK32 = 55,
          VK_FORMAT_A8B8G8R8_SINT_PACK32 = 56,
          VK_FORMAT_A8B8G8R8_SRGB_PACK32 = 57,
          VK_FORMAT_A2R10G10B10_UNORM_PACK32 = 58,
          VK_FORMAT_A2R10G10B10_SNORM_PACK32 = 59,
          VK_FORMAT_A2R10G10B10_USCALED_PACK32 = 60,
          VK_FORMAT_A2R10G10B10_SSCALED_PACK32 = 61,
          VK_FORMAT_A2R10G10B10_UINT_PACK32 = 62,
          VK_FORMAT_A2R10G10B10_SINT_PACK32 = 63,
          VK_FORMAT_A2B10G10R10_UNORM_PACK32 = 64,
          VK_FORMAT_A2B10G10R10_SNORM_PACK32 = 65,
          VK_FORMAT_A2B10G10R10_USCALED_PACK32 = 66,
          VK_FORMAT_A2B10G10R10_SSCALED_PACK32 = 67,
          VK_FORMAT_A2B10G10R10_UINT_PACK32 = 68,
          VK_FORMAT_A2B10G10R10_SINT_PACK32 = 69,
          VK_FORMAT_R16_UNORM = 70,
          VK_FORMAT_R16_SNORM = 71,
          VK_FORMAT_R16_USCALED = 72,
          VK_FORMAT_R16_SSCALED = 73,
          VK_FORMAT_R16_UINT = 74,
          VK_FORMAT_R16_SINT = 75,
          VK_FORMAT_R16_SFLOAT = 76,
          VK_FORMAT_R16G16_UNORM = 77,
          VK_FORMAT_R16G16_SNORM = 78,
          VK_FORMAT_R16G16_USCALED = 79,
          VK_FORMAT_R16G16_SSCALED = 80,
          VK_FORMAT_R16G16_UINT = 81,
          VK_FORMAT_R16G16_SINT = 82,
          VK_FORMAT_R16G16_SFLOAT = 83,
          VK_FORMAT_R16G16B16_UNORM = 84,
          VK_FORMAT_R16G16B16_SNORM = 85,
          VK_FORMAT_R16G16B16_USCALED = 86,
          VK_FORMAT_R16G16B16_SSCALED = 87,
          VK_FORMAT_R16G16B16_UINT = 88,
          VK_FORMAT_R16G16B16_SINT = 89,
          VK_FORMAT_R16G16B16_SFLOAT = 90,
          VK_FORMAT_R16G16B16A16_UNORM = 91,
          VK_FORMAT_R16G16B16A16_SNORM = 92,
          VK_FORMAT_R16G16B16A16_USCALED = 93,
          VK_FORMAT_R16G16B16A16_SSCALED = 94,
          VK_FORMAT_R16G16B16A16_UINT = 95,
          VK_FORMAT_R16G16B16A16_SINT = 96,
          VK_FORMAT_R16G16B16A16_SFLOAT = 97,
          VK_FORMAT_R32_UINT = 98,
          VK_FORMAT_R32_SINT = 99,
          VK_FORMAT_R32_SFLOAT = 100,
          VK_FORMAT_R32G32_UINT = 101,
          VK_FORMAT_R32G32_SINT = 102,
          VK_FORMAT_R32G32_SFLOAT = 103,
          VK_FORMAT_R32G32B32_UINT = 104,
          VK_FORMAT_R32G32B32_SINT = 105,
          VK_FORMAT_R32G32B32_SFLOAT = 106,
          VK_FORMAT_R32G32B32A32_UINT = 107,
          VK_FORMAT_R32G32B32A32_SINT = 108,
          VK_FORMAT_R32G32B32A32_SFLOAT = 109,
          VK_FORMAT_R64_UINT = 110,
          VK_FORMAT_R64_SINT = 111,
          VK_FORMAT_R64_SFLOAT = 112,
          VK_FORMAT_R64G64_UINT = 113,
          VK_FORMAT_R64G64_SINT = 114,
          VK_FORMAT_R64G64_SFLOAT = 115,
          VK_FORMAT_R64G64B64_UINT = 116,
          VK_FORMAT_R64G64B64_SINT = 117,
          VK_FORMAT_R64G64B64_SFLOAT = 118,
          VK_FORMAT_R64G64B64A64_UINT = 119,
          VK_FORMAT_R64G64B64A64_SINT = 120,
          VK_FORMAT_R64G64B64A64_SFLOAT = 121,
          VK_FORMAT_B10G11R11_UFLOAT_PACK32 = 122,
          VK_FORMAT_E5B9G9R9_UFLOAT_PACK32 = 123,
          VK_FORMAT_D16_UNORM = 124,
          VK_FORMAT_X8_D24_UNORM_PACK32 = 125,
          VK_FORMAT_D32_SFLOAT = 126,
          VK_FORMAT_S8_UINT = 127,
          VK_FORMAT_D16_UNORM_S8_UINT = 128,
          VK_FORMAT_D24_UNORM_S8_UINT = 129,
          VK_FORMAT_D32_SFLOAT_S8_UINT = 130,
          VK_FORMAT_BC1_RGB_UNORM_BLOCK = 131,
          VK_FORMAT_BC1_RGB_SRGB_BLOCK = 132,
          VK_FORMAT_BC1_RGBA_UNORM_BLOCK = 133,
          VK_FORMAT_BC1_RGBA_SRGB_BLOCK = 134,
          VK_FORMAT_BC2_UNORM_BLOCK = 135,
          VK_FORMAT_BC2_SRGB_BLOCK = 136,
          VK_FORMAT_BC3_UNORM_BLOCK = 137,
          VK_FORMAT_BC3_SRGB_BLOCK = 138,
          VK_FORMAT_BC4_UNORM_BLOCK = 139,
          VK_FORMAT_BC4_SNORM_BLOCK = 140,
          VK_FORMAT_BC5_UNORM_BLOCK = 141,
          VK_FORMAT_BC5_SNORM_BLOCK = 142,
          VK_FORMAT_BC6H_UFLOAT_BLOCK = 143,
          VK_FORMAT_BC6H_SFLOAT_BLOCK = 144,
          VK_FORMAT_BC7_UNORM_BLOCK = 145,
          VK_FORMAT_BC7_SRGB_BLOCK = 146,
          VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK = 147,
          VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK = 148,
          VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK = 149,
          VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK = 150,
          VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK = 151,
          VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK = 152,
          VK_FORMAT_EAC_R11_UNORM_BLOCK = 153,
          VK_FORMAT_EAC_R11_SNORM_BLOCK = 154,
          VK_FORMAT_EAC_R11G11_UNORM_BLOCK = 155,
          VK_FORMAT_EAC_R11G11_SNORM_BLOCK = 156,
          VK_FORMAT_ASTC_4x4_UNORM_BLOCK = 157,
          VK_FORMAT_ASTC_4x4_SRGB_BLOCK = 158,
          VK_FORMAT_ASTC_5x4_UNORM_BLOCK = 159,
          VK_FORMAT_ASTC_5x4_SRGB_BLOCK = 160,
          VK_FORMAT_ASTC_5x5_UNORM_BLOCK = 161,
          VK_FORMAT_ASTC_5x5_SRGB_BLOCK = 162,
          VK_FORMAT_ASTC_6x5_UNORM_BLOCK = 163,
          VK_FORMAT_ASTC_6x5_SRGB_BLOCK = 164,
          VK_FORMAT_ASTC_6x6_UNORM_BLOCK = 165,
          VK_FORMAT_ASTC_6x6_SRGB_BLOCK = 166,
          VK_FORMAT_ASTC_8x5_UNORM_BLOCK = 167,
          VK_FORMAT_ASTC_8x5_SRGB_BLOCK = 168,
          VK_FORMAT_ASTC_8x6_UNORM_BLOCK = 169,
          VK_FORMAT_ASTC_8x6_SRGB_BLOCK = 170,
          VK_FORMAT_ASTC_8x8_UNORM_BLOCK = 171,
          VK_FORMAT_ASTC_8x8_SRGB_BLOCK = 172,
          VK_FORMAT_ASTC_10x5_UNORM_BLOCK = 173,
          VK_FORMAT_ASTC_10x5_SRGB_BLOCK = 174,
          VK_FORMAT_ASTC_10x6_UNORM_BLOCK = 175,
          VK_FORMAT_ASTC_10x6_SRGB_BLOCK = 176,
          VK_FORMAT_ASTC_10x8_UNORM_BLOCK = 177,
          VK_FORMAT_ASTC_10x8_SRGB_BLOCK = 178,
          VK_FORMAT_ASTC_10x10_UNORM_BLOCK = 179,
          VK_FORMAT_ASTC_10x10_SRGB_BLOCK = 180,
          VK_FORMAT_ASTC_12x10_UNORM_BLOCK = 181,
          VK_FORMAT_ASTC_12x10_SRGB_BLOCK = 182,
          VK_FORMAT_ASTC_12x12_UNORM_BLOCK = 183,
          VK_FORMAT_ASTC_12x12_SRGB_BLOCK = 184,
          VK_FORMAT_G8B8G8R8_422_UNORM = 1000156000,
          VK_FORMAT_B8G8R8G8_422_UNORM = 1000156001,
          VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM = 1000156002,
          VK_FORMAT_G8_B8R8_2PLANE_420_UNORM = 1000156003,
          VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM = 1000156004,
          VK_FORMAT_G8_B8R8_2PLANE_422_UNORM = 1000156005,
          VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM = 1000156006,
          VK_FORMAT_R10X6_UNORM_PACK16 = 1000156007,
          VK_FORMAT_R10X6G10X6_UNORM_2PACK16 = 1000156008,
          VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16 = 1000156009,
          VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16 = 1000156010,
          VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16 = 1000156011,
          VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16 = 1000156012,
          VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16 = 1000156013,
          VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16 = 1000156014,
          VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16 = 1000156015,
          VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16 = 1000156016,
          VK_FORMAT_R12X4_UNORM_PACK16 = 1000156017,
          VK_FORMAT_R12X4G12X4_UNORM_2PACK16 = 1000156018,
          VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16 = 1000156019,
          VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16 = 1000156020,
          VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16 = 1000156021,
          VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16 = 1000156022,
          VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16 = 1000156023,
          VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16 = 1000156024,
          VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16 = 1000156025,
          VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16 = 1000156026,
          VK_FORMAT_G16B16G16R16_422_UNORM = 1000156027,
          VK_FORMAT_B16G16R16G16_422_UNORM = 1000156028,
          VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM = 1000156029,
          VK_FORMAT_G16_B16R16_2PLANE_420_UNORM = 1000156030,
          VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM = 1000156031,
          VK_FORMAT_G16_B16R16_2PLANE_422_UNORM = 1000156032,
          VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM = 1000156033,
          VK_FORMAT_PVRTC1_2BPP_UNORM_BLOCK_IMG = 1000054000,
          VK_FORMAT_PVRTC1_4BPP_UNORM_BLOCK_IMG = 1000054001,
          VK_FORMAT_PVRTC2_2BPP_UNORM_BLOCK_IMG = 1000054002,
          VK_FORMAT_PVRTC2_4BPP_UNORM_BLOCK_IMG = 1000054003,
          VK_FORMAT_PVRTC1_2BPP_SRGB_BLOCK_IMG = 1000054004,
          VK_FORMAT_PVRTC1_4BPP_SRGB_BLOCK_IMG = 1000054005,
          VK_FORMAT_PVRTC2_2BPP_SRGB_BLOCK_IMG = 1000054006,
          VK_FORMAT_PVRTC2_4BPP_SRGB_BLOCK_IMG = 1000054007,
          VK_FORMAT_ASTC_4x4_SFLOAT_BLOCK_EXT = 1000066000,
          VK_FORMAT_ASTC_5x4_SFLOAT_BLOCK_EXT = 1000066001,
          VK_FORMAT_ASTC_5x5_SFLOAT_BLOCK_EXT = 1000066002,
          VK_FORMAT_ASTC_6x5_SFLOAT_BLOCK_EXT = 1000066003,
          VK_FORMAT_ASTC_6x6_SFLOAT_BLOCK_EXT = 1000066004,
          VK_FORMAT_ASTC_8x5_SFLOAT_BLOCK_EXT = 1000066005,
          VK_FORMAT_ASTC_8x6_SFLOAT_BLOCK_EXT = 1000066006,
          VK_FORMAT_ASTC_8x8_SFLOAT_BLOCK_EXT = 1000066007,
          VK_FORMAT_ASTC_10x5_SFLOAT_BLOCK_EXT = 1000066008,
          VK_FORMAT_ASTC_10x6_SFLOAT_BLOCK_EXT = 1000066009,
          VK_FORMAT_ASTC_10x8_SFLOAT_BLOCK_EXT = 1000066010,
          VK_FORMAT_ASTC_10x10_SFLOAT_BLOCK_EXT = 1000066011,
          VK_FORMAT_ASTC_12x10_SFLOAT_BLOCK_EXT = 1000066012,
          VK_FORMAT_ASTC_12x12_SFLOAT_BLOCK_EXT = 1000066013,
          VK_FORMAT_G8B8G8R8_422_UNORM_KHR = VK_FORMAT_G8B8G8R8_422_UNORM,
          VK_FORMAT_B8G8R8G8_422_UNORM_KHR = VK_FORMAT_B8G8R8G8_422_UNORM,
          VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM_KHR = VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM,
          VK_FORMAT_G8_B8R8_2PLANE_420_UNORM_KHR = VK_FORMAT_G8_B8R8_2PLANE_420_UNORM,
          VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM_KHR = VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM,
          VK_FORMAT_G8_B8R8_2PLANE_422_UNORM_KHR = VK_FORMAT_G8_B8R8_2PLANE_422_UNORM,
          VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM_KHR = VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM,
          VK_FORMAT_R10X6_UNORM_PACK16_KHR = VK_FORMAT_R10X6_UNORM_PACK16,
          VK_FORMAT_R10X6G10X6_UNORM_2PACK16_KHR = VK_FORMAT_R10X6G10X6_UNORM_2PACK16,
          VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16_KHR = VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16,
          VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16_KHR = VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16,
          VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16_KHR = VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16,
          VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16_KHR = VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16,
          VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16_KHR = VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16,
          VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16_KHR = VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16,
          VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16_KHR = VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16,
          VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16_KHR = VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16,
          VK_FORMAT_R12X4_UNORM_PACK16_KHR = VK_FORMAT_R12X4_UNORM_PACK16,
          VK_FORMAT_R12X4G12X4_UNORM_2PACK16_KHR = VK_FORMAT_R12X4G12X4_UNORM_2PACK16,
          VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16_KHR = VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16,
          VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16_KHR = VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16,
          VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16_KHR = VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16,
          VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16_KHR = VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16,
          VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16_KHR = VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16,
          VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16_KHR = VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16,
          VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16_KHR = VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16,
          VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16_KHR = VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16,
          VK_FORMAT_G16B16G16R16_422_UNORM_KHR = VK_FORMAT_G16B16G16R16_422_UNORM,
          VK_FORMAT_B16G16R16G16_422_UNORM_KHR = VK_FORMAT_B16G16R16G16_422_UNORM,
          VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM_KHR = VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM,
          VK_FORMAT_G16_B16R16_2PLANE_420_UNORM_KHR = VK_FORMAT_G16_B16R16_2PLANE_420_UNORM,
          VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM_KHR = VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM,
          VK_FORMAT_G16_B16R16_2PLANE_422_UNORM_KHR = VK_FORMAT_G16_B16R16_2PLANE_422_UNORM,
          VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM_KHR = VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM,
          VK_FORMAT_MAX_ENUM = 0x7FFFFFFF
      } VkFormat;
      */


        VK_CHECK_RESULT(vkCreateImage($device, &imageInfo, nullptr, &miv.image));

        vkGetImageMemoryRequirements($device, miv.image, &miv.memReqs);

        VkMemoryAllocateInfo allocInfo = vka::plysm::memoryAllocateInfo();
        allocInfo.allocationSize = miv.memReqs.size;
        allocInfo.memoryTypeIndex = vka::shelve::getMemoryType(miv.memReqs.memoryTypeBits, properties, nullptr);


        if (AllocateVulkanMemory(&allocInfo, &miv.memory)== VK_ERROR_OUT_OF_DEVICE_MEMORY) {
            //log_bad(" VK_ERROR_OUT_OF_DEVICE_MEMORY \n ");
            return false;
        };


        VK_CHECK_RESULT(vkBindImageMemory($device, miv.image, miv.memory, 0));
        log_img("create2D  format  %u   w  %u  h %u   size %zu   \n", (UINT32)imageInfo.format, miv.w, miv.h, miv.memReqs.size);

        miv.Info = {};
        miv.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;

        {
            VkImageViewCreateInfo imageViewInfo = vka::plysm::imageViewCreateInfo();
            imageViewInfo.image = miv.image;
            imageViewInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
            imageViewInfo.format = imageInfo.format;
            imageViewInfo.components = { VK_COMPONENT_SWIZZLE_R, VK_COMPONENT_SWIZZLE_G, VK_COMPONENT_SWIZZLE_B,	VK_COMPONENT_SWIZZLE_A };
            imageViewInfo.subresourceRange = { VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1 };
            VK_CHECK_RESULT(vkCreateImageView($device, &imageViewInfo, nullptr, &miv.view));
            miv.Info.imageView = miv.view;

           if (TEX_DESC_TYPE == TEX_DESC_COMBINED_SAMPLER) {
#define ADDRESS_MODE  VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER
                    VkSamplerCreateInfo samplerInfo = vka::plysm::samplerCreateInfo();
                    samplerInfo.magFilter = VK_FILTER_LINEAR;
                    samplerInfo.minFilter = VK_FILTER_LINEAR;
                    samplerInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
                    samplerInfo.addressModeU   = ADDRESS_MODE;
                    samplerInfo.addressModeV   = ADDRESS_MODE;
                    samplerInfo.addressModeW  = ADDRESS_MODE;
                    samplerInfo.mipLodBias = 0.0f;
                    samplerInfo.compareOp = VK_COMPARE_OP_NEVER;
                    samplerInfo.minLod = 0.0f;
                    samplerInfo.maxLod = 1.0f;
                    samplerInfo.borderColor = VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
                    VK_CHECK_RESULT(vkCreateSampler($device, &samplerInfo, nullptr, &miv.sampler));
                    miv.Info.sampler = miv.sampler;
                   
                }
           cmcm::TransX(imcm, miv, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);

       }
        return true;
    };;

    void initDescriptorsSlots() {

        iinfo.resize(ALLOC_TEX_UNIT);
        if (nullDesc.w == 0) {
            CUDA_RESOURCE_DESC rdesc;
            rdesc.resType = CU_RESOURCE_TYPE_PITCH2D;
            rdesc.res.pitch2D.format = CU_AD_FORMAT_UNSIGNED_INT8;
            rdesc.res.pitch2D.numChannels = 1;
            rdesc.res.pitch2D.width = 1;
            rdesc.res.pitch2D.height = 1;
            rdesc.res.pitch2D.pitchInBytes = 1;
            CUDA_TEXTURE_DESC texDesc;

            VkImageCreateInfo imageInfo{};
            SetImageAttributes(nullDesc, imageInfo, rdesc, texDesc);
            create2D(nullDesc, imageInfo);
            cmcm::TransX(imcm, nullDesc, VK_IMAGE_LAYOUT_UNDEFINED, VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL);
        };

        if (TEX_DESC_TYPE == TEX_DESC_SEPARATE_SAMPLER && samplerDesc.size() == 0) {
           /*
            typedef enum VkFilter {
                VK_FILTER_NEAREST = 0,
                VK_FILTER_LINEAR = 1,
                VK_FILTER_CUBIC_IMG = 1000015000,
                VK_FILTER_CUBIC_EXT = VK_FILTER_CUBIC_IMG,
                VK_FILTER_MAX_ENUM = 0x7FFFFFFF
            } VkFilter;
            */
            VkFilter filter[2] = { VK_FILTER_LINEAR,VK_FILTER_NEAREST};

            VkSamplerCreateInfo samplerInfo = vka::plysm::samplerCreateInfo();
            samplerInfo.mipmapMode = VK_SAMPLER_MIPMAP_MODE_LINEAR;
            samplerInfo.mipLodBias = 0.0f;
            samplerInfo.compareOp = VK_COMPARE_OP_NEVER;
            samplerInfo.minLod = 0.0f;
            samplerInfo.maxLod = 1.0f;
            samplerInfo.borderColor = VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
            for (auto fmode : filter) {
                samplerInfo.magFilter = fmode;
                samplerInfo.minFilter  = fmode;
                VkSamplerAddressMode addressMode[3] = { VK_SAMPLER_ADDRESS_MODE_REPEAT,VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE, VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER };
                for (auto amode : addressMode) {
                    SIvk si;
                    samplerInfo.addressModeU = amode;
                    samplerInfo.addressModeV = amode;
                    samplerInfo.addressModeW = amode;
                    VK_CHECK_RESULT(vkCreateSampler($device, &samplerInfo, nullptr, &si.sampler));
                    si.Info.sampler = si.sampler;
                    si.Info.imageLayout = VK_IMAGE_LAYOUT_UNDEFINED;
                    si.Info.imageView = VK_NULL_HANDLE;
                    samplerDesc.push_back(si);
                }
            }
        }


        for (auto& d : iinfo) {
            d = nullDesc.Info;
        }



    }



    template<typename T>
    void image_update_json(T& bl) {


#define ENV_NODE(cs) \
        auto node = (EnvironmentTextureNode*)rStr.data();\
        node->colorspace = cs.c_str();\
        handle = image_manager->add_image2(filename, node->image_params());

#define IMAGE_NODE(cs) \
        auto node = (ImageTextureNode*)rStr.data();\
        node->colorspace = cs.c_str();\
        ccl::vector<int>  tiles;tiles.push_back(0);\
        handle = image_manager->add_image2(filename, node->image_params(),tiles);


        using namespace macaron;
        Base64  b64;
        auto svm  = bl.document["SVM"].GetObjectA();
   
        static const char* kTypeNames[] =
        { "Null", "False", "True", "Object", "Array", "String", "Number" };

        for (Value::ConstMemberIterator itr = svm.MemberBegin();
            itr != svm.MemberEnd(); ++itr)
        {
            auto key  = (std::string)itr->name.GetString();
            auto ary  = itr->value.GetArray();
            int  load = 0;
            if (key == "EnvironmentTextureNode") load = 1;
            else if (key == "ImageTextureNode")   load = 2;

            if (load > 0) {
                auto filesN = ary.Size();
                for (int i = 0; i < (int)filesN;i++) {
                    auto obj = ary[i].GetObjectA();
                    assert(obj.HasMember("name"));
                    assert(obj.HasMember("data"));
                    assert(obj.HasMember("colorspace"));

                    std::string  filename  =  (std::string) obj["name"].GetString();
                    auto crcID = bl.crc32_of_buffer((BYTE*)filename.data(), (int)filename.size());
                    if (slotCache.count(crcID) > 0) continue;

                    std::string rstr = obj["data"].GetString();
                    std::string rStr;
                    b64.Decode(rstr, rStr);

                    std::string cs = obj["colorspace"].GetString();
                    ImageHandle handle;
                    if (load == 1) {
                        ENV_NODE(cs)
                    }
                    else if (load == 2) {
                        IMAGE_NODE(cs)
                    }
                    slotCache[crcID] = std::make_pair(handle.slot_back(), filename);
                }
            }
        }

        image_manager->device_update2();
        printf(">>>>>>>>>>>>>>>>  image update <<<<<<<<<<<<<<<<<<<<<<<<<< \n");

    }

};