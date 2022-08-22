/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in_rsv compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in_rsv writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

CCL_NAMESPACE_BEGIN

/* Curve Primitive
 *
 * Curve primitive for rendering hair and fur. These can be render as flat
 * ribbons or curves with actual thickness. The curve can also be rendered as
 * line segments rather than curves for better performance.
 */

#ifdef _HAIR_

/* Reading attributes on various curve elements */

ccl_device float curve_attribute_float(
    inout KernelGlobals kg, in ShaderData sd, const AttributeDescriptor desc, inout float dx, inout float dy)
{
  if (desc.element == ATTR_ELEMENT_CURVE) {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;
#  endif

    return kernel_tex_fetch(_attributes_float, desc.offset + sd.prim);
  }
  else if (desc.element == ATTR_ELEMENT_CURVE_KEY ||
           desc.element == ATTR_ELEMENT_CURVE_KEY_MOTION) {
    float4 curvedata = kernel_tex_fetch(_curves, sd.prim);
    int k0 = _float_as_int(curvedata.x) + PRIMITIVE_UNPACK_SEGMENT(sd.type);
    int k1 = k0 + 1;

    float f0 = kernel_tex_fetch(_attributes_float, desc.offset + k0);
    float f1 = kernel_tex_fetch(_attributes_float, desc.offset + k1);

#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL(dx))

      dx = sd.du.dx * (f1 - f0);
    if(!isNULL(dy))

      dy = 0.0f;
#  endif

    return (1.0f - sd.u) * f0 + sd.u * f1;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;
#  endif

    return kernel_tex_fetch(_attributes_float, desc.offset);
  }
  else {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL(dx))

      dx = 0.0f;
    if(!isNULL(dy))

      dy = 0.0f;
#  endif

    return 0.0f;
  }
}

ccl_device float2 curve_attribute_float2(inout KernelGlobals kg,
                                         in ShaderData sd,
                                         const AttributeDescriptor desc,
                                         inout float2 dx2,
                                         inout float2 dy2)
{
  if (desc.element == ATTR_ELEMENT_CURVE) {
    /* idea: we can't derive any useful differentials here, but for tiled
     * mipmap image caching it would be useful to avoid reading the highest
     * detail level always. maybe a derivative based on the hair density
     * could be computed somehow? */
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);
#  endif

    return kernel_tex_fetch(_attributes_float2, desc.offset + sd.prim);
  }
  else if (desc.element == ATTR_ELEMENT_CURVE_KEY ||
           desc.element == ATTR_ELEMENT_CURVE_KEY_MOTION) {
    float4 curvedata = kernel_tex_fetch(_curves, sd.prim);
    int k0 = _float_as_int(curvedata.x) + PRIMITIVE_UNPACK_SEGMENT(sd.type);
    int k1 = k0 + 1;

    float2 f0 = kernel_tex_fetch(_attributes_float2, desc.offset + k0);
    float2 f1 = kernel_tex_fetch(_attributes_float2, desc.offset + k1);

#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL2(dx2))

      dx2 = sd.du.dx * (f1 - f0);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);
#  endif

    return (1.0f - sd.u) * f0 + sd.u * f1;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);
#  endif

    return kernel_tex_fetch(_attributes_float2, desc.offset);
  }
  else {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL2(dx2))

      dx2 = make_float2(0.0f, 0.0f);
    if(!isNULL2(dy2))

      dy2 = make_float2(0.0f, 0.0f);
#  endif

    return make_float2(0.0f, 0.0f);
  }
}

ccl_device float3 curve_attribute_float3(inout KernelGlobals kg,
                                         in ShaderData sd,
                                         const AttributeDescriptor desc,
                                         inout float3 dx3,
                                         inout float3 dy3)
{
  if (desc.element == ATTR_ELEMENT_CURVE) {
    /* idea: we can't derive any useful differentials here, but for tiled
     * mipmap image caching it would be useful to avoid reading the highest
     * detail level always. maybe a derivative based on the hair density
     * could be computed somehow? */
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);
#  endif

    return float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + sd.prim));
  }
  else if (desc.element == ATTR_ELEMENT_CURVE_KEY ||
           desc.element == ATTR_ELEMENT_CURVE_KEY_MOTION) {
    float4 curvedata = kernel_tex_fetch(_curves, sd.prim);
    int k0 = _float_as_int(curvedata.x) + PRIMITIVE_UNPACK_SEGMENT(sd.type);
    int k1 = k0 + 1;

    float3 f0 = float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + k0));
    float3 f1 = float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset + k1));

#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL3(dx3))

      dx3 = sd.du.dx * (f1 - f0);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);
#  endif

    return (1.0f - sd.u) * f0 + sd.u * f1;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);
#  endif

    return float4_to_float3(kernel_tex_fetch(_attributes_float3, desc.offset));
  }
  else {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL3(dx3))

      dx3 = make_float3(0.0f, 0.0f, 0.0f);
    if(!isNULL3(dy3))

      dy3 = make_float3(0.0f, 0.0f, 0.0f);
#  endif

    return make_float3(0.0f, 0.0f, 0.0f);
  }
}

ccl_device float4 curve_attribute_float4(inout KernelGlobals kg,
                                         in ShaderData sd,
                                         const AttributeDescriptor desc,
                                         inout float4 dx4,
                                         inout float4 dy4)
{
  if (desc.element == ATTR_ELEMENT_CURVE) {
    /* idea: we can't derive any useful differentials here, but for tiled
     * mipmap image caching it would be useful to avoid reading the highest
     * detail level always. maybe a derivative based on the hair density
     * could be computed somehow? */
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL4(dx4))

      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if(!isNULL4(dy4))

      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
#  endif

    return kernel_tex_fetch(_attributes_float3, desc.offset + sd.prim);
  }
  else if (desc.element == ATTR_ELEMENT_CURVE_KEY ||
           desc.element == ATTR_ELEMENT_CURVE_KEY_MOTION) {
    float4 curvedata = kernel_tex_fetch(_curves, sd.prim);
    int k0 = _float_as_int(curvedata.x) + PRIMITIVE_UNPACK_SEGMENT(sd.type);
    int k1 = k0 + 1;

    float4 f0 = kernel_tex_fetch(_attributes_float3, desc.offset + k0);
    float4 f1 = kernel_tex_fetch(_attributes_float3, desc.offset + k1);

#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL4(dx4))

      dx4 = sd.du.dx * (f1 - f0);
    if(!isNULL4(dy4))

      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
#  endif

    return (1.0f - sd.u) * f0 + sd.u * f1;
  }
  else if (desc.element == ATTR_ELEMENT_OBJECT || desc.element == ATTR_ELEMENT_MESH) {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL4(dx4))

      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if(!isNULL4(dy4))

      dy4= make_float4(0.0f, 0.0f, 0.0f, 0.0f);
#  endif

    return kernel_tex_fetch(_attributes_float3, desc.offset);
  }
  else {
#  ifdef _RAY_DIFFERENTIALS_
    if(!isNULL4(dx4))

      dx4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    if(!isNULL4(dy4))

      dy4 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
#  endif

    return make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  }
}

/* Curve thickness */

ccl_device float curve_thickness(inout KernelGlobals kg, inout ShaderData sd)
{
  float r = 0.0f;

  if (bool(sd.type & PRIMITIVE_ALL_CURVE)) {

    float4 curvedata = kernel_tex_fetch(_curves, sd.prim);
    int k0 = _float_as_int(curvedata.x) + PRIMITIVE_UNPACK_SEGMENT(sd.type);
    int k1 = k0 + 1;

    float4 P_curve[2];

    if (!(bool(sd.type & PRIMITIVE_ALL_MOTION))) {

      P_curve[0] = kernel_tex_fetch(_curve_keys, k0);
      P_curve[1] = kernel_tex_fetch(_curve_keys, k1);
    }
    else {
      motion_curve_keys_linear(kg, sd.object, sd.prim, sd.time, k0, k1, P_curve);
    }

    r = (P_curve[1].w - P_curve[0].w) * sd.u + P_curve[0].w;
  }

  return r * 2.0f;
}

/* Curve location for motion pass, linear interpolation between keys and
 * ignoring radius because we do the same for the motion keys */

ccl_device float3 curve_motion_center_location(inout KernelGlobals kg, inout ShaderData sd)
{
  float4 curvedata = kernel_tex_fetch(_curves, sd.prim);
  int k0 = _float_as_int(curvedata.x) + PRIMITIVE_UNPACK_SEGMENT(sd.type);
  int k1 = k0 + 1;

  float4 P_curve[2];

  P_curve[0] = kernel_tex_fetch(_curve_keys, k0);
  P_curve[1] = kernel_tex_fetch(_curve_keys, k1);

  return float4_to_float3(P_curve[1]) * sd.u + float4_to_float3(P_curve[0]) * (1.0f - sd.u);
}

/* Curve tangent normal */

ccl_device float3 curve_tangent_normal(inout KernelGlobals kg, inout ShaderData sd)
{
  float3 tgN = make_float3(0.0f, 0.0f, 0.0f);

  if (bool(sd.type & PRIMITIVE_ALL_CURVE)) {


    tgN = -(-sd.I - sd.dPdu * (dot3(sd.dPdu, -sd.I) / len_squared(sd.dPdu)));
    tgN = normalize(tgN);

    /* need to find suitable scaled gd for corrected normal */
#  if 0
    tgN = normalize(tgN - gd * sd.dPdu);
#  endif
  }

  return tgN;
}

/* Curve bounds utility function */

ccl_device_inline void curvebounds(inout float lower,
                                   inout float upper,
                                   inout float extremta,
                                   inout float extrema,
                                   inout float extremtb,
                                   inout float extremb,
                                   float p0,
                                   float p1,
                                   float p2,
                                   float p3)
{
  float halfdiscroot = (p2 * p2 - 3 * p3 * p1);
  float ta = -1.0f;
  float tb = -1.0f;

  extremta = -1.0f;
  extremtb = -1.0f;
  upper = p0;
  lower = (p0 + p1) + (p2 + p3);
  extrema = upper;
  extremb = lower;

  if (lower >= upper) {
    upper = lower;
    lower = p0;
  }

  if (halfdiscroot >= 0) {
    float inv3p3 = (1.0f / 3.0f) / p3;
    halfdiscroot = sqrtf(halfdiscroot);
    ta = (-p2 - halfdiscroot) * inv3p3;
    tb = (-p2 + halfdiscroot) * inv3p3;
  }

  float t2;
  float t3;

  if (ta > 0.0f && ta < 1.0f) {
    t2 = ta * ta;
    t3 = t2 * ta;
    extremta = ta;
    extrema = p3 * t3 + p2 * t2 + p1 * ta + p0;

    upper = fmaxf(extrema, upper);
    lower = fminf(extrema, lower);
  }

  if (tb > 0.0f && tb < 1.0f) {
    t2 = tb * tb;
    t3 = t2 * tb;
    extremtb = tb;
    extremb = p3 * t3 + p2 * t2 + p1 * tb + p0;

    upper = fmaxf(extremb, upper);
    lower = fminf(extremb, lower);
  }
}

#endif /* _HAIR_ */

CCL_NAMESPACE_END
