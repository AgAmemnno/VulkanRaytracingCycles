#ifndef _SVM_BRIGHTNESS_H_
#define _SVM_BRIGHTNESS_H_
CCL_NAMESPACE_BEGIN
#ifdef NOT_CALL
#define  svm_node_brightness(in_color, out_color, node)\
{\
  uint bright_offset, contrast_offset;\
  float3 color = stack_load_float3(in_color);\
  svm_unpack_node_uchar2(node, (bright_offset), (contrast_offset));\
  color = svm_brightness_contrast(color, stack_load_float(bright_offset), stack_load_float(contrast_offset));\
  if (stack_valid(out_color))stack_store_float3(out_color, color);\
}
#endif
CCL_NAMESPACE_END
#endif