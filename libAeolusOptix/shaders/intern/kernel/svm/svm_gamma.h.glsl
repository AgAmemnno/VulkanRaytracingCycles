#ifndef _SVM_GAMMA_H_
#define _SVM_GAMMA_H_
CCL_NAMESPACE_BEGIN
#define  svm_node_gamma(in_gamma,  in_color,  out_color)\
{\
  float3 color = stack_load_float3(in_color);\
  float gamma = stack_load_float(in_gamma);\
  color = svm_math_gamma_color(color, gamma);\
  if (stack_valid(out_color))stack_store_float3(out_color, color);\
}
CCL_NAMESPACE_END
#endif