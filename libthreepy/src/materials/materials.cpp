#pragma once
#include "pch_three.h"
#include "common.hpp"
#include  "aeolus/vthreepy_const.h"
#include  "aeolus/vthreepy_types.h"


namespace info {

	const char* String_VkBlendOp(VkBlendOp op) {

        #define string_VkBlendOp(op) case op:return  #op;
		switch (op) {
		default:
			string_VkBlendOp(VK_BLEND_OP_ADD)
				string_VkBlendOp(VK_BLEND_OP_SUBTRACT)
				string_VkBlendOp(VK_BLEND_OP_REVERSE_SUBTRACT)
				string_VkBlendOp(VK_BLEND_OP_MIN)
				string_VkBlendOp(VK_BLEND_OP_MAX)
				string_VkBlendOp(VK_BLEND_OP_ZERO_EXT)
				string_VkBlendOp(VK_BLEND_OP_SRC_EXT)
				string_VkBlendOp(VK_BLEND_OP_DST_EXT)
				string_VkBlendOp(VK_BLEND_OP_SRC_OVER_EXT)
				string_VkBlendOp(VK_BLEND_OP_DST_OVER_EXT)
				string_VkBlendOp(VK_BLEND_OP_SRC_IN_EXT)
				string_VkBlendOp(VK_BLEND_OP_DST_IN_EXT)
				string_VkBlendOp(VK_BLEND_OP_SRC_OUT_EXT)
				string_VkBlendOp(VK_BLEND_OP_DST_OUT_EXT)
				string_VkBlendOp(VK_BLEND_OP_SRC_ATOP_EXT)
				string_VkBlendOp(VK_BLEND_OP_DST_ATOP_EXT)
				string_VkBlendOp(VK_BLEND_OP_XOR_EXT)
				string_VkBlendOp(VK_BLEND_OP_MULTIPLY_EXT)
				string_VkBlendOp(VK_BLEND_OP_SCREEN_EXT)
				string_VkBlendOp(VK_BLEND_OP_OVERLAY_EXT)
				string_VkBlendOp(VK_BLEND_OP_DARKEN_EXT)
				string_VkBlendOp(VK_BLEND_OP_LIGHTEN_EXT)
				string_VkBlendOp(VK_BLEND_OP_COLORDODGE_EXT)
				string_VkBlendOp(VK_BLEND_OP_COLORBURN_EXT)
				string_VkBlendOp(VK_BLEND_OP_HARDLIGHT_EXT)
				string_VkBlendOp(VK_BLEND_OP_SOFTLIGHT_EXT)
				string_VkBlendOp(VK_BLEND_OP_DIFFERENCE_EXT)
				string_VkBlendOp(VK_BLEND_OP_EXCLUSION_EXT)
				string_VkBlendOp(VK_BLEND_OP_INVERT_EXT)
				string_VkBlendOp(VK_BLEND_OP_INVERT_RGB_EXT)
				string_VkBlendOp(VK_BLEND_OP_LINEARDODGE_EXT)
				string_VkBlendOp(VK_BLEND_OP_LINEARBURN_EXT)
				string_VkBlendOp(VK_BLEND_OP_VIVIDLIGHT_EXT)
				string_VkBlendOp(VK_BLEND_OP_LINEARLIGHT_EXT)
				string_VkBlendOp(VK_BLEND_OP_PINLIGHT_EXT)
				string_VkBlendOp(VK_BLEND_OP_HARDMIX_EXT)
				string_VkBlendOp(VK_BLEND_OP_HSL_HUE_EXT)
				string_VkBlendOp(VK_BLEND_OP_HSL_SATURATION_EXT)
				string_VkBlendOp(VK_BLEND_OP_HSL_COLOR_EXT)
				string_VkBlendOp(VK_BLEND_OP_HSL_LUMINOSITY_EXT)
				string_VkBlendOp(VK_BLEND_OP_PLUS_EXT)
				string_VkBlendOp(VK_BLEND_OP_PLUS_CLAMPED_EXT)
				string_VkBlendOp(VK_BLEND_OP_PLUS_CLAMPED_ALPHA_EXT)
				string_VkBlendOp(VK_BLEND_OP_PLUS_DARKER_EXT)
				string_VkBlendOp(VK_BLEND_OP_MINUS_EXT)
				string_VkBlendOp(VK_BLEND_OP_MINUS_CLAMPED_EXT)
				string_VkBlendOp(VK_BLEND_OP_CONTRAST_EXT)
				string_VkBlendOp(VK_BLEND_OP_INVERT_OVG_EXT)
				string_VkBlendOp(VK_BLEND_OP_RED_EXT)
				string_VkBlendOp(VK_BLEND_OP_GREEN_EXT)
				string_VkBlendOp(VK_BLEND_OP_BLUE_EXT)
				string_VkBlendOp(VK_BLEND_OP_MAX_ENUM)

		};
		///return "NOT-FONUD";
	};

	//constexpr 
	VkBlendOp  getVkBlendOp(const uint32_t N)  noexcept {
		return    VkBlendOp(N + (UINT)0x3b9d0c20);
	};

	//constexpr 
	UINT  getVkBlendOpNum(const VkBlendOp op)  noexcept {
		return  (UINT)op - (UINT)0x3b9d0c20;
	};

	const char* String_VkBlendOverlap(VkBlendOverlapEXT op) {
#define string_VkBlendOverlap(op) case op:return  #op;
		switch (op) {
		default:
			string_VkBlendOverlap(VK_BLEND_OVERLAP_UNCORRELATED_EXT)
				string_VkBlendOverlap(VK_BLEND_OVERLAP_DISJOINT_EXT)
				string_VkBlendOverlap(VK_BLEND_OVERLAP_CONJOINT_EXT)
				string_VkBlendOverlap(VK_BLEND_OVERLAP_MAX_ENUM_EXT)
		};
	};


};