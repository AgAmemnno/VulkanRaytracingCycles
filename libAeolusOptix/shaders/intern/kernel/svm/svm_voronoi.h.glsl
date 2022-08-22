#ifndef _SVM_VORONOI_H_
#define _SVM_VORONOI_H_

/*
 * Copyright 2011-2013 Blender Foundation
 *
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
#include "kernel/svm/svm_callable.glsl"

CCL_NAMESPACE_BEGIN

#ifdef NODE_Caller


#define SVM_NODE_VOR_OUT_OFFSET(ofs) {nio.offset = ofs;}
#define SVM_NODE_VOR_OUT_DIMENTION(dim) {nio.type = dim;}
#define SVM_NODE_VOR_OUT_COORD(v4) {nio.data[0] = v4.x;nio.data[1] = v4.y;nio.data[2] = v4.z;}
#define SVM_NODE_VOR_OUT_W(f) {nio.data[3] = f;}
#define SVM_NODE_VOR_OUT_SCALE(f) {nio.data[4] = f;}
#define SVM_NODE_VOR_OUT_SMOOTHNESS(f) {nio.data[5] = f;}
#define SVM_NODE_VOR_OUT_EXPORNET(f) {nio.data[6] = f;}
#define SVM_NODE_VOR_OUT_RANDOMNESS(f) {nio.data[7] = f;}
#define SVM_NODE_VOR_OUT_FEATURE(f) {nio.data[8] = uintBitsToFloat(f);}
#define SVM_NODE_VOR_OUT_METRIC(f) {nio.data[9] = uintBitsToFloat(f);}


#define SVM_NODE_VOR_RET_COLOR vec4(nio.data[0], nio.data[1],nio.data[2],0.)
#define SVM_NODE_VOR_RET_W  nio.data[3]
#define SVM_NODE_VOR_RET_RADIUS  nio.data[4]
#define SVM_NODE_VOR_RET_DISTANCE  nio.data[5]
#define SVM_NODE_VOR_RET_POSITION vec4(nio.data[6], nio.data[7],nio.data[8],0.)



ccl_device void svm_node_tex_voronoi(
                                     uint dimensions,
                                     uint feature,
                                     uint metric,
                                     inout int offset)
{
  uint4 stack_offsets = read_node(offset);
  uint4 defaults = read_node(offset);

  uint coord_stack_offset, w_stack_offset, scale_stack_offset, smoothness_stack_offset;
  uint exponent_stack_offset, randomness_stack_offset, distance_out_stack_offset,
      color_out_stack_offset;
  uint position_out_stack_offset, w_out_stack_offset, radius_out_stack_offset;

  svm_unpack_node_uchar4(stack_offsets.x,
                         (coord_stack_offset),
                         (w_stack_offset),
                         (scale_stack_offset),
                         (smoothness_stack_offset));

  svm_unpack_node_uchar4(stack_offsets.y,
                         (exponent_stack_offset),
                         (randomness_stack_offset),
                         (distance_out_stack_offset),
                         (color_out_stack_offset));

  svm_unpack_node_uchar3(
      stack_offsets.z, (position_out_stack_offset), (w_out_stack_offset), (radius_out_stack_offset));

SVM_NODE_VOR_OUT_DIMENTION(dimensions) {nio.type = dimensions;}
SVM_NODE_VOR_OUT_COORD(stack_load_float3(coord_stack_offset)) 
SVM_NODE_VOR_OUT_W(stack_load_float_default(w_stack_offset, stack_offsets.w))
SVM_NODE_VOR_OUT_SCALE(stack_load_float_default(scale_stack_offset, defaults.x)) 
SVM_NODE_VOR_OUT_SMOOTHNESS(stack_load_float_default(smoothness_stack_offset, defaults.y))
SVM_NODE_VOR_OUT_EXPORNET(stack_load_float_default(exponent_stack_offset, defaults.z))
SVM_NODE_VOR_OUT_RANDOMNESS(stack_load_float_default(randomness_stack_offset, defaults.w))
SVM_NODE_VOR_OUT_FEATURE(NodeVoronoiFeature(feature)) 
SVM_NODE_VOR_OUT_METRIC(NodeVoronoiDistanceMetric(metric))

EXECUTION_VOR;


  if (stack_valid(distance_out_stack_offset))
    stack_store_float(distance_out_stack_offset, SVM_NODE_VOR_RET_DISTANCE);
  if (stack_valid(color_out_stack_offset))
    stack_store_float3(color_out_stack_offset, SVM_NODE_VOR_RET_COLOR);
  if (stack_valid(position_out_stack_offset))
    stack_store_float3(position_out_stack_offset,SVM_NODE_VOR_RET_POSITION);
  if (stack_valid(w_out_stack_offset))
    stack_store_float(w_out_stack_offset, SVM_NODE_VOR_RET_W);
  if (stack_valid(radius_out_stack_offset))
    stack_store_float(radius_out_stack_offset, SVM_NODE_VOR_RET_RADIUS);

}

#endif




#ifdef NODE_Callee


#define SVM_NODE_VOR_RET_COLOR(v3) { nio.coord = v3.xyz;}
#define SVM_NODE_VOR_RET_W(f)  { nio.w = f;}
#define SVM_NODE_VOR_RET_RADIUS(f)  { nio.scale = f;}
#define SVM_NODE_VOR_RET_DISTANCE(f)  { nio.smoothness = f;}
#define SVM_NODE_VOR_RET_POSITION(v3) { nio.exponent = v3.x; nio.randomness = v3.y;nio.feature = floatBitsToUint(v3.z);}



/*
 * Smooth Voronoi:
 *
 * - https://wiki.blender.org/wiki/User:OmarSquircleArt/GSoC2019/Documentation/Smooth_Voronoi
 *
 * Distance To Edge:
 *
 * - https://www.shadertoy.com/view/llG3zy
 *
 */

/* **** 1D Voronoi **** */

ccl_device float voronoi_distance_1d(float a,
                                     float b,
                                     NodeVoronoiDistanceMetric metric,
                                     float exponent)
{
  return fabsf(b - a);
}

ccl_device void voronoi_f1_1d(float w,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float outW)
{
  float cellPosition = floorf(w);
  float localPosition = w - cellPosition;

  float minDistance = 8.0f;
  float targetOffset = 0.0f;
  float targetPosition = 0.0f;
  for (int i = -1; i <= 1; i++) {
    float cellOffset = i;
    float pointPosition = cellOffset + hash_float_to_float(cellPosition + cellOffset) * randomness;
    float distanceToPoint = voronoi_distance_1d(pointPosition, localPosition, metric, exponent);
    if (distanceToPoint < minDistance) {
      targetOffset = cellOffset;
      minDistance = distanceToPoint;
      targetPosition = pointPosition;
    }
  }
  outDistance = minDistance;
  outColor = hash_float_to_float3(cellPosition + targetOffset);
  outW = targetPosition + cellPosition;
}

ccl_device void voronoi_smooth_f1_1d(float w,
                                     float smoothness,
                                     float exponent,
                                     float randomness,
                                     NodeVoronoiDistanceMetric metric,
                                     inout float outDistance,
                                     inout float3 outColor,
                                     inout float outW)
{
  float cellPosition = floorf(w);
  float localPosition = w - cellPosition;

  float smoothDistance = 8.0f;
  float smoothPosition = 0.0f;
  float3 smoothColor = make_float3(0.0f, 0.0f, 0.0f);
  for (int i = -2; i <= 2; i++) {
    float cellOffset = i;
    float pointPosition = cellOffset + hash_float_to_float(cellPosition + cellOffset) * randomness;
    float distanceToPoint = voronoi_distance_1d(pointPosition, localPosition, metric, exponent);
    float h = smoothstep(
        0.0f, 1.0f, 0.5f + 0.5f * (smoothDistance - distanceToPoint) / smoothness);
    float correctionFactor = smoothness * h * (1.0f - h);
    smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
    correctionFactor /= 1.0f + 3.0f * smoothness;
    float3 cellColor = hash_float_to_float3(cellPosition + cellOffset);
    smoothColor = mix(smoothColor, cellColor, h) - correctionFactor;
    smoothPosition = mix(smoothPosition, pointPosition, h) - correctionFactor;
  }
  outDistance = smoothDistance;
  outColor = smoothColor;
  outW = cellPosition + smoothPosition;
}

ccl_device void voronoi_f2_1d(float w,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float outW)
{
  float cellPosition = floorf(w);
  float localPosition = w - cellPosition;

  float distanceF1 = 8.0f;
  float distanceF2 = 8.0f;
  float offsetF1 = 0.0f;
  float positionF1 = 0.0f;
  float offsetF2 = 0.0f;
  float positionF2 = 0.0f;
  for (int i = -1; i <= 1; i++) {
    float cellOffset = i;
    float pointPosition = cellOffset + hash_float_to_float(cellPosition + cellOffset) * randomness;
    float distanceToPoint = voronoi_distance_1d(pointPosition, localPosition, metric, exponent);
    if (distanceToPoint < distanceF1) {
      distanceF2 = distanceF1;
      distanceF1 = distanceToPoint;
      offsetF2 = offsetF1;
      offsetF1 = cellOffset;
      positionF2 = positionF1;
      positionF1 = pointPosition;
    }
    else if (distanceToPoint < distanceF2) {
      distanceF2 = distanceToPoint;
      offsetF2 = cellOffset;
      positionF2 = pointPosition;
    }
  }
  outDistance = distanceF2;
  outColor = hash_float_to_float3(cellPosition + offsetF2);
  outW = positionF2 + cellPosition;
}

ccl_device void voronoi_distance_to_edge_1d(float w, float randomness, inout float outDistance)
{
  float cellPosition = floorf(w);
  float localPosition = w - cellPosition;

  float minDistance = 8.0f;
  for (int i = -1; i <= 1; i++) {
    float cellOffset = i;
    float pointPosition = cellOffset + hash_float_to_float(cellPosition + cellOffset) * randomness;
    float distanceToPoint = fabsf(pointPosition - localPosition);
    minDistance = min(distanceToPoint, minDistance);
  }
  outDistance = minDistance;
}

ccl_device void voronoi_n_sphere_radius_1d(float w, float randomness, inout float outRadius)
{
  float cellPosition = floorf(w);
  float localPosition = w - cellPosition;

  float closestPoint = 0.0f;
  float closestPointOffset = 0.0f;
  float minDistance = 8.0f;
  for (int i = -1; i <= 1; i++) {
    float cellOffset = i;
    float pointPosition = cellOffset + hash_float_to_float(cellPosition + cellOffset) * randomness;
    float distanceToPoint = fabsf(pointPosition - localPosition);
    if (distanceToPoint < minDistance) {
      minDistance = distanceToPoint;
      closestPoint = pointPosition;
      closestPointOffset = cellOffset;
    }
  }

  minDistance = 8.0f;
  float closestPointToClosestPoint = 0.0f;
  for (int i = -1; i <= 1; i++) {
    if (i == 0) {
      continue;
    }
    float cellOffset = i + closestPointOffset;
    float pointPosition = cellOffset + hash_float_to_float(cellPosition + cellOffset) * randomness;
    float distanceToPoint = fabsf(closestPoint - pointPosition);
    if (distanceToPoint < minDistance) {
      minDistance = distanceToPoint;
      closestPointToClosestPoint = pointPosition;
    }
  }
  outRadius = fabsf(closestPointToClosestPoint - closestPoint) / 2.0f;
}

/* **** 2D Voronoi **** */

ccl_device float voronoi_distance_2d(float2 a,
                                     float2 b,
                                     NodeVoronoiDistanceMetric metric,
                                     float exponent)
{
  if (metric == NODE_VORONOI_EUCLIDEAN) {
    return distance(a, b);
  }
  else if (metric == NODE_VORONOI_MANHATTAN) {
    return fabsf(a.x - b.x) + fabsf(a.y - b.y);
  }
  else if (metric == NODE_VORONOI_CHEBYCHEV) {
    return max(fabsf(a.x - b.x), fabsf(a.y - b.y));
  }
  else if (metric == NODE_VORONOI_MINKOWSKI) {
    return powf(powf(fabsf(a.x - b.x), exponent) + powf(fabsf(a.y - b.y), exponent),
                1.0f / exponent);
  }
  else {
    return 0.0f;
  }
}

ccl_device void voronoi_f1_2d(float2 coord,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float2 outPosition)
{
  float2 cellPosition = floor(coord);
  float2 localPosition = coord - cellPosition;

  float minDistance = 8.0f;
  float2 targetOffset = make_float2(0.0f, 0.0f);
  float2 targetPosition = make_float2(0.0f, 0.0f);
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      float2 cellOffset = make_float2(i, j);
      float2 pointPosition = cellOffset +
                             hash_float2_to_float2(cellPosition + cellOffset) * randomness;
      float distanceToPoint = voronoi_distance_2d(pointPosition, localPosition, metric, exponent);
      if (distanceToPoint < minDistance) {
        targetOffset = cellOffset;
        minDistance = distanceToPoint;
        targetPosition = pointPosition;
      }
    }
  }
  outDistance = minDistance;
  outColor = hash_float2_to_float3(cellPosition + targetOffset);
  outPosition = targetPosition + cellPosition;
}

ccl_device void voronoi_smooth_f1_2d(float2 coord,
                                     float smoothness,
                                     float exponent,
                                     float randomness,
                                     NodeVoronoiDistanceMetric metric,
                                     inout float outDistance,
                                     inout float3 outColor,
                                     inout float2 outPosition)
{
  float2 cellPosition = floor(coord);
  float2 localPosition = coord - cellPosition;

  float smoothDistance = 8.0f;
  float3 smoothColor = make_float3(0.0f, 0.0f, 0.0f);
  float2 smoothPosition = make_float2(0.0f, 0.0f);
  for (int j = -2; j <= 2; j++) {
    for (int i = -2; i <= 2; i++) {
      float2 cellOffset = make_float2(i, j);
      float2 pointPosition = cellOffset +
                             hash_float2_to_float2(cellPosition + cellOffset) * randomness;
      float distanceToPoint = voronoi_distance_2d(pointPosition, localPosition, metric, exponent);
      float h = smoothstep(
          0.0f, 1.0f, 0.5f + 0.5f * (smoothDistance - distanceToPoint) / smoothness);
      float correctionFactor = smoothness * h * (1.0f - h);
      smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
      correctionFactor /= 1.0f + 3.0f * smoothness;
      float3 cellColor = hash_float2_to_float3(cellPosition + cellOffset);
      smoothColor = mix(smoothColor, cellColor, h) - correctionFactor;
      smoothPosition = mix(smoothPosition, pointPosition, h) - correctionFactor;
    }
  }
  outDistance = smoothDistance;
  outColor = smoothColor;
  outPosition = cellPosition + smoothPosition;
}

ccl_device void voronoi_f2_2d(float2 coord,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float2 outPosition)
{
  float2 cellPosition = floor(coord);
  float2 localPosition = coord - cellPosition;

  float distanceF1 = 8.0f;
  float distanceF2 = 8.0f;
  float2 offsetF1 = make_float2(0.0f, 0.0f);
  float2 positionF1 = make_float2(0.0f, 0.0f);
  float2 offsetF2 = make_float2(0.0f, 0.0f);
  float2 positionF2 = make_float2(0.0f, 0.0f);
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      float2 cellOffset = make_float2(i, j);
      float2 pointPosition = cellOffset +
                             hash_float2_to_float2(cellPosition + cellOffset) * randomness;
      float distanceToPoint = voronoi_distance_2d(pointPosition, localPosition, metric, exponent);
      if (distanceToPoint < distanceF1) {
        distanceF2 = distanceF1;
        distanceF1 = distanceToPoint;
        offsetF2 = offsetF1;
        offsetF1 = cellOffset;
        positionF2 = positionF1;
        positionF1 = pointPosition;
      }
      else if (distanceToPoint < distanceF2) {
        distanceF2 = distanceToPoint;
        offsetF2 = cellOffset;
        positionF2 = pointPosition;
      }
    }
  }
  outDistance = distanceF2;
  outColor = hash_float2_to_float3(cellPosition + offsetF2);
  outPosition = positionF2 + cellPosition;
}

ccl_device void voronoi_distance_to_edge_2d(float2 coord, float randomness, inout float outDistance)
{
  float2 cellPosition = floor(coord);
  float2 localPosition = coord - cellPosition;

  float2 vectorToClosest = make_float2(0.0f, 0.0f);
  float minDistance = 8.0f;
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      float2 cellOffset = make_float2(i, j);
      float2 vectorToPoint = cellOffset +
                             hash_float2_to_float2(cellPosition + cellOffset) * randomness -
                             localPosition;
      float distanceToPoint = dot(vectorToPoint, vectorToPoint);
      if (distanceToPoint < minDistance) {
        minDistance = distanceToPoint;
        vectorToClosest = vectorToPoint;
      }
    }
  }

  minDistance = 8.0f;
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      float2 cellOffset = make_float2(i, j);
      float2 vectorToPoint = cellOffset +
                             hash_float2_to_float2(cellPosition + cellOffset) * randomness -
                             localPosition;
      float2 perpendicularToEdge = vectorToPoint - vectorToClosest;
      if (dot(perpendicularToEdge, perpendicularToEdge) > 0.0001f) {
        float distanceToEdge = dot((vectorToClosest + vectorToPoint) / 2.0f,
                                   normalize(perpendicularToEdge));
        minDistance = min(minDistance, distanceToEdge);
      }
    }
  }
  outDistance = minDistance;
}

ccl_device void voronoi_n_sphere_radius_2d(float2 coord, float randomness, inout float outRadius)
{
  float2 cellPosition = floor(coord);
  float2 localPosition = coord - cellPosition;

  float2 closestPoint = make_float2(0.0f, 0.0f);
  float2 closestPointOffset = make_float2(0.0f, 0.0f);
  float minDistance = 8.0f;
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      float2 cellOffset = make_float2(i, j);
      float2 pointPosition = cellOffset +
                             hash_float2_to_float2(cellPosition + cellOffset) * randomness;
      float distanceToPoint = distance(pointPosition, localPosition);
      if (distanceToPoint < minDistance) {
        minDistance = distanceToPoint;
        closestPoint = pointPosition;
        closestPointOffset = cellOffset;
      }
    }
  }

  minDistance = 8.0f;
  float2 closestPointToClosestPoint = make_float2(0.0f, 0.0f);
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      if (i == 0 && j == 0) {
        continue;
      }
      float2 cellOffset = make_float2(i, j) + closestPointOffset;
      float2 pointPosition = cellOffset +
                             hash_float2_to_float2(cellPosition + cellOffset) * randomness;
      float distanceToPoint = distance(closestPoint, pointPosition);
      if (distanceToPoint < minDistance) {
        minDistance = distanceToPoint;
        closestPointToClosestPoint = pointPosition;
      }
    }
  }
  outRadius = distance(closestPointToClosestPoint, closestPoint) / 2.0f;
}

/* **** 3D Voronoi **** */

ccl_device float voronoi_distance_3d(float3 a,
                                     float3 b,
                                     NodeVoronoiDistanceMetric metric,
                                     float exponent)
{
  if (metric == NODE_VORONOI_EUCLIDEAN) {
    return distance(a, b);
  }
  else if (metric == NODE_VORONOI_MANHATTAN) {
    return fabsf(a.x - b.x) + fabsf(a.y - b.y) + fabsf(a.z - b.z);
  }
  else if (metric == NODE_VORONOI_CHEBYCHEV) {
    return max(fabsf(a.x - b.x), max(fabsf(a.y - b.y), fabsf(a.z - b.z)));
  }
  else if (metric == NODE_VORONOI_MINKOWSKI) {
    return powf(powf(fabsf(a.x - b.x), exponent) + powf(fabsf(a.y - b.y), exponent) +
                    powf(fabsf(a.z - b.z), exponent),
                1.0f / exponent);
  }
  else {
    return 0.0f;
  }
}

ccl_device void voronoi_f1_3d(float3 coord,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float3 outPosition)
{
  float3 cellPosition = floor(coord);
  float3 localPosition = coord - cellPosition;

  float minDistance = 8.0f;
  float3 targetOffset = make_float3(0.0f, 0.0f, 0.0f);
  float3 targetPosition = make_float3(0.0f, 0.0f, 0.0f);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        float3 cellOffset = make_float3(i, j, k);
        float3 pointPosition = cellOffset +
                               hash_float3_to_float3(cellPosition + cellOffset) * randomness;
        float distanceToPoint = voronoi_distance_3d(
            pointPosition, localPosition, metric, exponent);
        if (distanceToPoint < minDistance) {
          targetOffset = cellOffset;
          minDistance = distanceToPoint;
          targetPosition = pointPosition;
        }
      }
    }
  }
  outDistance = minDistance;
  outColor = hash_float3_to_float3(cellPosition + targetOffset);
  outPosition = targetPosition + cellPosition;
}

ccl_device void voronoi_smooth_f1_3d(float3 coord,
                                     float smoothness,
                                     float exponent,
                                     float randomness,
                                     NodeVoronoiDistanceMetric metric,
                                     inout float outDistance,
                                     inout float3 outColor,
                                     inout float3 outPosition)
{
  float3 cellPosition = floor(coord);
  float3 localPosition = coord - cellPosition;

  float smoothDistance = 8.0f;
  float3 smoothColor = make_float3(0.0f, 0.0f, 0.0f);
  float3 smoothPosition = make_float3(0.0f, 0.0f, 0.0f);
  for (int k = -2; k <= 2; k++) {
    for (int j = -2; j <= 2; j++) {
      for (int i = -2; i <= 2; i++) {
        float3 cellOffset = make_float3(i, j, k);
        float3 pointPosition = cellOffset +
                               hash_float3_to_float3(cellPosition + cellOffset) * randomness;
        float distanceToPoint = voronoi_distance_3d(
            pointPosition, localPosition, metric, exponent);
        float h = smoothstep(
            0.0f, 1.0f, 0.5f + 0.5f * (smoothDistance - distanceToPoint) / smoothness);
        float correctionFactor = smoothness * h * (1.0f - h);
        smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
        correctionFactor /= 1.0f + 3.0f * smoothness;
        float3 cellColor = hash_float3_to_float3(cellPosition + cellOffset);
        smoothColor = mix(smoothColor, cellColor, h) - correctionFactor;
        smoothPosition = mix(smoothPosition, pointPosition, h) - correctionFactor;
      }
    }
  }
  outDistance = smoothDistance;
  outColor = smoothColor;
  outPosition = cellPosition + smoothPosition;
}

ccl_device void voronoi_f2_3d(float3 coord,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float3 outPosition)
{
  float3 cellPosition = floor(coord);
  float3 localPosition = coord - cellPosition;

  float distanceF1 = 8.0f;
  float distanceF2 = 8.0f;
  float3 offsetF1 = make_float3(0.0f, 0.0f, 0.0f);
  float3 positionF1 = make_float3(0.0f, 0.0f, 0.0f);
  float3 offsetF2 = make_float3(0.0f, 0.0f, 0.0f);
  float3 positionF2 = make_float3(0.0f, 0.0f, 0.0f);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        float3 cellOffset = make_float3(i, j, k);
        float3 pointPosition = cellOffset +
                               hash_float3_to_float3(cellPosition + cellOffset) * randomness;
        float distanceToPoint = voronoi_distance_3d(
            pointPosition, localPosition, metric, exponent);
        if (distanceToPoint < distanceF1) {
          distanceF2 = distanceF1;
          distanceF1 = distanceToPoint;
          offsetF2 = offsetF1;
          offsetF1 = cellOffset;
          positionF2 = positionF1;
          positionF1 = pointPosition;
        }
        else if (distanceToPoint < distanceF2) {
          distanceF2 = distanceToPoint;
          offsetF2 = cellOffset;
          positionF2 = pointPosition;
        }
      }
    }
  }
  outDistance = distanceF2;
  outColor = hash_float3_to_float3(cellPosition + offsetF2);
  outPosition = positionF2 + cellPosition;
}

ccl_device void voronoi_distance_to_edge_3d(float3 coord, float randomness, inout float outDistance)
{
  float3 cellPosition = floor(coord);
  float3 localPosition = coord - cellPosition;

  float3 vectorToClosest = make_float3(0.0f, 0.0f, 0.0f);
  float minDistance = 8.0f;
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        float3 cellOffset = make_float3(i, j, k);
        float3 vectorToPoint = cellOffset +
                               hash_float3_to_float3(cellPosition + cellOffset) * randomness -
                               localPosition;
        float distanceToPoint = dot3(vectorToPoint, vectorToPoint);
        if (distanceToPoint < minDistance) {
          minDistance = distanceToPoint;
          vectorToClosest = vectorToPoint;
        }
      }
    }
  }

  minDistance = 8.0f;
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        float3 cellOffset = make_float3(i, j, k);
        float3 vectorToPoint = cellOffset +
                               hash_float3_to_float3(cellPosition + cellOffset) * randomness -
                               localPosition;
        float3 perpendicularToEdge = vectorToPoint - vectorToClosest;
        if (dot3(perpendicularToEdge, perpendicularToEdge) > 0.0001f) {
          float distanceToEdge = dot3((vectorToClosest + vectorToPoint) / 2.0f,
                                     normalize(perpendicularToEdge));
          minDistance = min(minDistance, distanceToEdge);
        }
      }
    }
  }
  outDistance = minDistance;
}

ccl_device void voronoi_n_sphere_radius_3d(float3 coord, float randomness, inout float outRadius)
{
  float3 cellPosition = floor(coord);
  float3 localPosition = coord - cellPosition;

  float3 closestPoint = make_float3(0.0f, 0.0f, 0.0f);
  float3 closestPointOffset = make_float3(0.0f, 0.0f, 0.0f);
  float minDistance = 8.0f;
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        float3 cellOffset = make_float3(i, j, k);
        float3 pointPosition = cellOffset +
                               hash_float3_to_float3(cellPosition + cellOffset) * randomness;
        float distanceToPoint = distance(pointPosition, localPosition);
        if (distanceToPoint < minDistance) {
          minDistance = distanceToPoint;
          closestPoint = pointPosition;
          closestPointOffset = cellOffset;
        }
      }
    }
  }

  minDistance = 8.0f;
  float3 closestPointToClosestPoint = make_float3(0.0f, 0.0f, 0.0f);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        if (i == 0 && j == 0 && k == 0) {
          continue;
        }
        float3 cellOffset = make_float3(i, j, k) + closestPointOffset;
        float3 pointPosition = cellOffset +
                               hash_float3_to_float3(cellPosition + cellOffset) * randomness;
        float distanceToPoint = distance(closestPoint, pointPosition);
        if (distanceToPoint < minDistance) {
          minDistance = distanceToPoint;
          closestPointToClosestPoint = pointPosition;
        }
      }
    }
  }
  outRadius = distance(closestPointToClosestPoint, closestPoint) / 2.0f;
}

/* **** 4D Voronoi **** */

ccl_device float voronoi_distance_4d(float4 a,
                                     float4 b,
                                     NodeVoronoiDistanceMetric metric,
                                     float exponent)
{
  if (metric == NODE_VORONOI_EUCLIDEAN) {
    return distance(a, b);
  }
  else if (metric == NODE_VORONOI_MANHATTAN) {
    return fabsf(a.x - b.x) + fabsf(a.y - b.y) + fabsf(a.z - b.z) + fabsf(a.w - b.w);
  }
  else if (metric == NODE_VORONOI_CHEBYCHEV) {
    return max(fabsf(a.x - b.x), max(fabsf(a.y - b.y), max(fabsf(a.z - b.z), fabsf(a.w - b.w))));
  }
  else if (metric == NODE_VORONOI_MINKOWSKI) {
    return powf(powf(fabsf(a.x - b.x), exponent) + powf(fabsf(a.y - b.y), exponent) +
                    powf(fabsf(a.z - b.z), exponent) + powf(fabsf(a.w - b.w), exponent),
                1.0f / exponent);
  }
  else {
    return 0.0f;
  }
}

ccl_device void voronoi_f1_4d(float4 coord,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float4 outPosition)
{
  float4 cellPosition = floor(coord);
  float4 localPosition = coord - cellPosition;

  float minDistance = 8.0f;
  float4 targetOffset = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  float4 targetPosition = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  for (int u = -1; u <= 1; u++) {
    for (int k = -1; k <= 1; k++) {
      ccl_loop_no_unroll for (int j = -1; j <= 1; j++)
      {
        for (int i = -1; i <= 1; i++) {
          float4 cellOffset = make_float4(i, j, k, u);
          float4 pointPosition = cellOffset +
                                 hash_float4_to_float4(cellPosition + cellOffset) * randomness;
          float distanceToPoint = voronoi_distance_4d(
              pointPosition, localPosition, metric, exponent);
          if (distanceToPoint < minDistance) {
            targetOffset = cellOffset;
            minDistance = distanceToPoint;
            targetPosition = pointPosition;
          }
        }
      }
    }
  }
  outDistance = minDistance;
  outColor = hash_float4_to_float3(cellPosition + targetOffset);
  outPosition = targetPosition + cellPosition;
}

ccl_device void voronoi_smooth_f1_4d(float4 coord,
                                     float smoothness,
                                     float exponent,
                                     float randomness,
                                     NodeVoronoiDistanceMetric metric,
                                     inout float outDistance,
                                     inout float3 outColor,
                                     inout float4 outPosition)
{
  float4 cellPosition = floor(coord);
  float4 localPosition = coord - cellPosition;

  float smoothDistance = 8.0f;
  float3 smoothColor = make_float3(0.0f, 0.0f, 0.0f);
  float4 smoothPosition = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  for (int u = -2; u <= 2; u++) {
    for (int k = -2; k <= 2; k++) {
      ccl_loop_no_unroll for (int j = -2; j <= 2; j++)
      {
        for (int i = -2; i <= 2; i++) {
          float4 cellOffset = make_float4(i, j, k, u);
          float4 pointPosition = cellOffset +
                                 hash_float4_to_float4(cellPosition + cellOffset) * randomness;
          float distanceToPoint = voronoi_distance_4d(
              pointPosition, localPosition, metric, exponent);
          float h = smoothstep(
              0.0f, 1.0f, 0.5f + 0.5f * (smoothDistance - distanceToPoint) / smoothness);
          float correctionFactor = smoothness * h * (1.0f - h);
          smoothDistance = mix(smoothDistance, distanceToPoint, h) - correctionFactor;
          correctionFactor /= 1.0f + 3.0f * smoothness;
          float3 cellColor = hash_float4_to_float3(cellPosition + cellOffset);
          smoothColor = mix(smoothColor, cellColor, h) - correctionFactor;
          smoothPosition = mix(smoothPosition, pointPosition, h) - correctionFactor;
        }
      }
    }
  }
  outDistance = smoothDistance;
  outColor = smoothColor;
  outPosition = cellPosition + smoothPosition;
}

ccl_device void voronoi_f2_4d(float4 coord,
                              float exponent,
                              float randomness,
                              NodeVoronoiDistanceMetric metric,
                              inout float outDistance,
                              inout float3 outColor,
                              inout float4 outPosition)
{
  float4 cellPosition = floor(coord);
  float4 localPosition = coord - cellPosition;

  float distanceF1 = 8.0f;
  float distanceF2 = 8.0f;
  float4 offsetF1 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  float4 positionF1 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  float4 offsetF2 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  float4 positionF2 = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  for (int u = -1; u <= 1; u++) {
    for (int k = -1; k <= 1; k++) {
      ccl_loop_no_unroll for (int j = -1; j <= 1; j++)
      {
        for (int i = -1; i <= 1; i++) {
          float4 cellOffset = make_float4(i, j, k, u);
          float4 pointPosition = cellOffset +
                                 hash_float4_to_float4(cellPosition + cellOffset) * randomness;
          float distanceToPoint = voronoi_distance_4d(
              pointPosition, localPosition, metric, exponent);
          if (distanceToPoint < distanceF1) {
            distanceF2 = distanceF1;
            distanceF1 = distanceToPoint;
            offsetF2 = offsetF1;
            offsetF1 = cellOffset;
            positionF2 = positionF1;
            positionF1 = pointPosition;
          }
          else if (distanceToPoint < distanceF2) {
            distanceF2 = distanceToPoint;
            offsetF2 = cellOffset;
            positionF2 = pointPosition;
          }
        }
      }
    }
  }
  outDistance = distanceF2;
  outColor = hash_float4_to_float3(cellPosition + offsetF2);
  outPosition = positionF2 + cellPosition;
}

ccl_device void voronoi_distance_to_edge_4d(float4 coord, float randomness, inout float outDistance)
{
  float4 cellPosition = floor(coord);
  float4 localPosition = coord - cellPosition;

  float4 vectorToClosest = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  float minDistance = 8.0f;
  for (int u = -1; u <= 1; u++) {
    for (int k = -1; k <= 1; k++) {
      ccl_loop_no_unroll for (int j = -1; j <= 1; j++)
      {
        for (int i = -1; i <= 1; i++) {
          float4 cellOffset = make_float4(i, j, k, u);
          float4 vectorToPoint = cellOffset +
                                 hash_float4_to_float4(cellPosition + cellOffset) * randomness -
                                 localPosition;
          float distanceToPoint = dot(vectorToPoint, vectorToPoint);
          if (distanceToPoint < minDistance) {
            minDistance = distanceToPoint;
            vectorToClosest = vectorToPoint;
          }
        }
      }
    }
  }

  minDistance = 8.0f;
  for (int u = -1; u <= 1; u++) {
    for (int k = -1; k <= 1; k++) {
      ccl_loop_no_unroll for (int j = -1; j <= 1; j++)
      {
        for (int i = -1; i <= 1; i++) {
          float4 cellOffset = make_float4(i, j, k, u);
          float4 vectorToPoint = cellOffset +
                                 hash_float4_to_float4(cellPosition + cellOffset) * randomness -
                                 localPosition;
          float4 perpendicularToEdge = vectorToPoint - vectorToClosest;
          if (dot(perpendicularToEdge, perpendicularToEdge) > 0.0001f) {
            float distanceToEdge = dot((vectorToClosest + vectorToPoint) / 2.0f,
                                       normalize(perpendicularToEdge));
            minDistance = min(minDistance, distanceToEdge);
          }
        }
      }
    }
  }
  outDistance = minDistance;
}

ccl_device void voronoi_n_sphere_radius_4d(float4 coord, float randomness, inout float outRadius)
{
  float4 cellPosition = floor(coord);
  float4 localPosition = coord - cellPosition;

  float4 closestPoint = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  float4 closestPointOffset = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  float minDistance = 8.0f;
  for (int u = -1; u <= 1; u++) {
    for (int k = -1; k <= 1; k++) {
      ccl_loop_no_unroll for (int j = -1; j <= 1; j++)
      {
        for (int i = -1; i <= 1; i++) {
          float4 cellOffset = make_float4(i, j, k, u);
          float4 pointPosition = cellOffset +
                                 hash_float4_to_float4(cellPosition + cellOffset) * randomness;
          float distanceToPoint = distance(pointPosition, localPosition);
          if (distanceToPoint < minDistance) {
            minDistance = distanceToPoint;
            closestPoint = pointPosition;
            closestPointOffset = cellOffset;
          }
        }
      }
    }
  }

  minDistance = 8.0f;
  float4 closestPointToClosestPoint = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  for (int u = -1; u <= 1; u++) {
    for (int k = -1; k <= 1; k++) {
      ccl_loop_no_unroll for (int j = -1; j <= 1; j++)
      {
        for (int i = -1; i <= 1; i++) {
          if (i == 0 && j == 0 && k == 0 && u == 0) {
            continue;
          }
          float4 cellOffset = make_float4(i, j, k, u) + closestPointOffset;
          float4 pointPosition = cellOffset +
                                 hash_float4_to_float4(cellPosition + cellOffset) * randomness;
          float distanceToPoint = distance(closestPoint, pointPosition);
          if (distanceToPoint < minDistance) {
            minDistance = distanceToPoint;
            closestPointToClosestPoint = pointPosition;
          }
        }
      }
    }
  }
  outRadius = distance(closestPointToClosestPoint, closestPoint) / 2.0f;
}


ccl_device void svm_node_tex_voronoi(){

  float distance_out = 0.0f, w_out = 0.0f, radius_out = 0.0f;
  float3 color_out = make_float3(0.0f, 0.0f, 0.0f);
  float4 position_out = vec4(0.0f, 0.0f, 0.0f,0.0f);



  float randomness = clamp(nio.randomness, 0.0f, 1.0f);
  float smoothness = clamp(nio.smoothness / 2.0f, 0.0f, 0.5f);

  nio.w *= nio.scale;
  nio.coord *= nio.scale;

  switch (nio.dimensions) {
    case 1: {
      switch (nio.feature) {
        case NODE_VORONOI_F1:
          voronoi_f1_1d(nio.w, nio.exponent, randomness, nio.metric, (distance_out), (color_out), (w_out));
          break;
        case NODE_VORONOI_SMOOTH_F1:
          voronoi_smooth_f1_1d(nio.w,
                               smoothness,
                               nio.exponent,
                               randomness,
                               nio.metric,
                               (distance_out),
                               (color_out),
                               (w_out));

          break;
        case NODE_VORONOI_F2:
          voronoi_f2_1d(
              nio.w, nio.exponent, randomness, nio.metric, (distance_out), (color_out), (w_out));
          break;
        case NODE_VORONOI_DISTANCE_TO_EDGE:
          voronoi_distance_to_edge_1d(nio.w, randomness, (distance_out));
          break;
        case NODE_VORONOI_N_SPHERE_RADIUS:
          voronoi_n_sphere_radius_1d(nio.w, randomness, (radius_out));
          break;
        default:
          kernel_assert("assert svm voronoi :: 1062",0);
          break;
      }
      w_out = safe_divide(w_out, nio.scale);
      break;
    }
    case 2: {
      float2 coord_2d = make_float2(nio.coord.x, nio.coord.y);
      float2 position_out_2d;
      switch (nio.feature) {
        case NODE_VORONOI_F1:
          voronoi_f1_2d(coord_2d,
                        nio.exponent,
                        randomness,
                        nio.metric,
                        (distance_out),
                        (color_out),
                        (position_out_2d));

          break;
#if NODES_FEATURE(NODE_FEATURE_VORONOI_EXTRA)
        case NODE_VORONOI_SMOOTH_F1:
          voronoi_smooth_f1_2d(coord_2d,
                               smoothness,
                               nio.exponent,
                               randomness,
                               nio.metric,
                               (distance_out),
                               (color_out),
                               (position_out_2d));

          break;
#endif
        case NODE_VORONOI_F2:
          voronoi_f2_2d(coord_2d,
                        nio.exponent,
                        randomness,
                        nio.metric,
                        (distance_out),
                        (color_out),
                        (position_out_2d));

          break;
        case NODE_VORONOI_DISTANCE_TO_EDGE:
          voronoi_distance_to_edge_2d(coord_2d, randomness, (distance_out));
          break;
        case NODE_VORONOI_N_SPHERE_RADIUS:
          voronoi_n_sphere_radius_2d(coord_2d, randomness, (radius_out));
          break;
        default:
          kernel_assert("assert svm voronoi 1111 ",0);
      }
      position_out_2d = safe_divide_float2_float(position_out_2d, nio.scale);
      position_out = make_float3(position_out_2d.x, position_out_2d.y, 0.0f);
      break;
    }
    case 3: {
      switch (nio.feature) {
        case NODE_VORONOI_F1:
          voronoi_f1_3d(vec4(nio.coord,0.),
                        nio.exponent,
                        randomness,
                        nio.metric,
                        (distance_out),
                        (color_out),
                        (position_out));

          break;
#if NODES_FEATURE(NODE_FEATURE_VORONOI_EXTRA)
        case NODE_VORONOI_SMOOTH_F1:
          voronoi_smooth_f1_3d(vec4(nio.coord,0.),
                               smoothness,
                               nio.exponent,
                               randomness,
                               nio.metric,
                               (distance_out),
                               (color_out),
                               (position_out));

          break;
#endif
        case NODE_VORONOI_F2:
          voronoi_f2_3d(vec4(nio.coord,0.),
                        nio.exponent,
                        randomness,
                        nio.metric,
                        (distance_out),
                        (color_out),
                        (position_out));
          break;
        case NODE_VORONOI_DISTANCE_TO_EDGE:
          voronoi_distance_to_edge_3d(vec4(nio.coord,0.), randomness, (distance_out));
          break;
        case NODE_VORONOI_N_SPHERE_RADIUS:
          voronoi_n_sphere_radius_3d(vec4(nio.coord ,0.), randomness, (radius_out));
          break;
        default:
          kernel_assert("assert svm voronoi 1158 ",0);
      }
      position_out = safe_divide_float3_float(position_out, nio.scale);
      break;
    }

#if NODES_FEATURE(NODE_FEATURE_VORONOI_EXTRA)
    case 4: {
      float4 coord_4d = make_float4(nio.coord.x, nio.coord.y, nio.coord.z, nio.w);
      float4 position_out_4d;
      switch (nio.feature) {
        case NODE_VORONOI_F1:
          voronoi_f1_4d(coord_4d,
                        nio.exponent,
                        randomness,
                        nio.metric,
                        (distance_out),
                        (color_out),
                        (position_out_4d));

          break;
        case NODE_VORONOI_SMOOTH_F1:
          voronoi_smooth_f1_4d(coord_4d,
                               smoothness,
                               nio.exponent,
                               randomness,
                               nio.metric,
                               (distance_out),
                               (color_out),
                               (position_out_4d));

          break;
        case NODE_VORONOI_F2:
          voronoi_f2_4d(coord_4d,
                        nio.exponent,
                        randomness,
                        nio.metric,
                        (distance_out),
                        (color_out),
                        (position_out_4d));
          break;
        case NODE_VORONOI_DISTANCE_TO_EDGE:
          voronoi_distance_to_edge_4d(coord_4d, randomness, (distance_out));
          break;
        case NODE_VORONOI_N_SPHERE_RADIUS:
          voronoi_n_sphere_radius_4d(coord_4d, randomness, (radius_out));
          break;
        default:
          kernel_assert("assert svm voronoi 1206",0);
      }
      position_out_4d = safe_divide_float4_float(position_out_4d, nio.scale);
      position_out = make_float3(position_out_4d.x, position_out_4d.y, position_out_4d.z);
      w_out = position_out_4d.w;
      break;
    }
#endif
    default:
      //kernel_assert("assert vornoi :: 1195 default",0);
      break;
  }

SVM_NODE_VOR_RET_COLOR(color_out )
SVM_NODE_VOR_RET_W(w_out)
SVM_NODE_VOR_RET_RADIUS(radius_out)
SVM_NODE_VOR_RET_DISTANCE(distance_out)
SVM_NODE_VOR_RET_POSITION(position_out) 

}


#endif


CCL_NAMESPACE_END
#endif