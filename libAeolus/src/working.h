#pragma once

#ifndef WORKING_H
#define WORKING_H


#include "working_mm.h"


namespace gui {

	struct GUIcolor {
		union {
			float rgba[4];
			struct {
				float r, g, b, a;
			};
		};
	};

	typedef struct style1 { float x, y, w, h; GUIcolor col; char* txt; }style1;
	typedef struct style2 { float x, y, size; int32_t col; char* txt; }style2;
};
namespace fon {


	struct  VpushR {
		float x;
		float y;
		float color;
		float key;
		///uint32_t color;
		///int key;
		float size;
		float offset;
		float skew;
		float strength;

	};
	typedef std::vector<VpushR> vGlyphty;


};
namespace brunch {

	template<class T>
	struct overQ {

		PSLIST_HEADER  header;
		long                              last;
		typedef  T dataty;
		typedef struct Item {
			SLIST_ENTRY entry;
			dataty    data;
		} Item, * pItem;
		overQ() :last(0) {};
		int alloc() {
			header = (PSLIST_HEADER)_aligned_malloc(sizeof(SLIST_HEADER),
				MEMORY_ALLOCATION_ALIGNMENT);
			if (NULL == header)
			{
				printf("Memory allocation failed.\n");
				return -1;
			}
			InitializeSListHead(header);
			return 0;
		};

		int dealloc() {
			InterlockedFlushSList(header);
			PSLIST_ENTRY entry = InterlockedPopEntrySList(header);
			if (entry != NULL)
			{
				printf("Error: List is not empty.\n");
				return -1;
			}

			_aligned_free(header);
			return 0;

		};

		bool push(dataty&& x) {

			InterlockedIncrement(&last);

			pItem item = (pItem)_aligned_malloc(sizeof(Item),
				MEMORY_ALLOCATION_ALIGNMENT);
			if (NULL == item)
			{
				printf("Memory allocation failed.\n");
				return false;
			}
			item->data = x;
			InterlockedPushEntrySList(header, &(item->entry));
			return true;
		};

		bool pop(dataty& x) {

			InterlockedDecrement(&last);
			PSLIST_ENTRY entry = InterlockedPopEntrySList(header);

			if (NULL == entry)
			{
				///printf("List is empty.\n");
				return false;
			}

			x = ((pItem)entry)->data;
			_aligned_free(entry);
			return true;
		};

	};

	union trafficlight {
		HANDLE     BlueLight;
		HANDLE     RedLight;
	};

	void createComputePipeline(VkPipeline& pipe, const char* shader, VkPipelineLayout draft, VkPipelineCache cache = VK_NULL_HANDLE, VkSpecializationInfo* specializationInfo = nullptr);


	typedef overQ<listnerData*> QlistnerDataty;
};

#define DEB

#include "aeolus/PipelineVk.h"
#include "aeolus/BrunchVk.h"
#include "aeolus/ImmutableVk.h"
#include "aeolus/CircusVk.h"
/*
#include "callback_types.h"

#include "aeolus/OVR.h"
#include "aeolus/groupVk/common.h"
#include "aeolus/materialsVk/common.h"
#include "aeolus/canvasVk/common.h"


#include "aeolus/MutableVk.h"
#include "aeolus/OverlayVk.h"
#include "aeolus/ListnerVk.h"
*/
 

#endif