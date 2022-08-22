#include "pch_mm.h"
#include "working_mm.h"

extern VkAllocationCallbacks  Callback_vkAllocateMemory;
typedef    Temperance Temperance;




typedef struct TemperanceStatInfo
{
	/// Number of `VkDeviceMemory` Vulkan memory blocks allocated.
	uint32_t blockCount;
	/// Number of #VmaAllocation allocation objects allocated.
	uint32_t allocationCount;
	/// Number of free ranges of memory between allocations.
	uint32_t unusedRangeCount;
	/// Total number of bytes occupied by all allocations.
	VkDeviceSize usedBytes;
	/// Total number of bytes occupied by unused ranges.
	VkDeviceSize unusedBytes;
	VkDeviceSize allocationSizeMin, allocationSizeAvg, allocationSizeMax;
	VkDeviceSize unusedRangeSizeMin, unusedRangeSizeAvg, unusedRangeSizeMax;
} TemperanceStatInfo;




void Temperance::init() {
	deviceLimit();
	heapBudget();
};

void Temperance::deviceLimit() {
	limits.memory = (long)$properties.limits.maxMemoryAllocationCount;
};

void Temperance::heapBudget() {


	log_ctx("   heapCount  %u    \n", $memoryProperties.memoryHeapCount);
	for (uint32_t i = 0; i < $memoryProperties.memoryHeapCount; i++) {
		log_ctx("   flags   %x    size   %zu    \n", $memoryProperties.memoryHeaps[i].flags, $memoryProperties.memoryHeaps[i].size);
	};

	log_ctx("   heapTypeCount  %u    \n", $memoryProperties.memoryTypeCount);
	for (uint32_t i = 0; i < $memoryProperties.memoryTypeCount; i++) {
		log_ctx("   flags   %x    heapIdx   %u    \n", $memoryProperties.memoryTypes[i].propertyFlags, $memoryProperties.memoryTypes[i].heapIndex);
	};


	budget = { VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT };

	VkPhysicalDeviceMemoryProperties2KHR memProps2 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2_KHR ,
		.pNext = &budget
	};

	vkGetPhysicalDeviceMemoryProperties2($physicaldevice, &memProps2);

	for (uint32_t heapIndex = 0; heapIndex < $memoryProperties.memoryHeapCount; heapIndex++)
	{
		log_ctx(" Heap[%u]   usage   %zu   budget   %zu    \n", heapIndex, budget.heapUsage[heapIndex], budget.heapBudget[heapIndex]);
	};

	heap.device = (long)budget.heapBudget[0];
	heap.visible = (long)budget.heapBudget[1];
	heap.devisible = (long)budget.heapBudget[2];


};

void PolicyAllocateFree()
{

	$Policy_AllocateMemory.pUserData = &$Temperance;   // I don't care
	$Policy_AllocateMemory.pfnAllocation = &VK_AllocationFunction;
	$Policy_AllocateMemory.pfnReallocation = &VK_ReallocationFunction;
	$Policy_AllocateMemory.pfnFree = &VK_FreeFunction;

	// I use my own memory tracer for that purpose
	$Policy_AllocateMemory.pfnInternalAllocation = nullptr;
	$Policy_AllocateMemory.pfnInternalFree = nullptr;

};