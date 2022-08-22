/*
 * Copyright 2011-2013 Blender Foundation
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

CCL_NAMESPACE_BEGIN

/* See "Tracing Ray Differentials", Homan Igehy, 1999. */

#define differential_transfer(agdP_,agdP,agD,agdD,agNg,agt){\
  float3 tmp = agD / dot3(agD, agNg);float3 tmpx = agdP.dx + agt * agdD.dx;float3 tmpy = agdP.dy + agt * agdD.dy;\
  agdP_.dx = tmpx - dot3(tmpx, agNg) * tmp;agdP_.dy = tmpy - dot3(tmpy, agNg) * tmp;}



#define  differential_incoming(dI,dD) dI.dx = -dD.dx;dI.dy = -dD.dy;


#define differential_dudv( agdu, agdv, agdPdu,agdPdv, agdP, agNg)\
{\
  float xn = fabsf(agNg.x);float yn = fabsf(agNg.y);float zn = fabsf(agNg.z);\
  if (zn < xn || zn < yn) { if (yn < xn || yn < zn) {agdPdu.x = agdPdu.y;agdPdv.x = agdPdv.y;agdP.dx.x = agdP.dx.y;agdP.dy.x = agdP.dy.y;}\
    agdPdu.y = agdPdu.z;agdPdv.y = agdPdv.z;agdP.dx.y = agdP.dx.z;agdP.dy.y = agdP.dy.z;}\
  float det = (agdPdu.x * agdPdv.y - agdPdv.x * agdPdu.y);\
  if (det != 0.0f)det = 1.0f / det;\
  agdu.dx = (agdP.dx.x * agdPdv.y - agdP.dx.y * agdPdv.x) * det;\
  agdv.dx = (agdP.dx.y * agdPdu.x - agdP.dx.x * agdPdu.y) * det;\
  agdu.dy = (agdP.dy.x * agdPdv.y - agdP.dy.y * agdPdv.x) * det;\
  agdv.dy = (agdP.dy.y * agdPdu.x - agdP.dy.x * agdPdu.y) * det;\
}

#define differential_zero(agd) agd.dx = 0.0f;agd.dy = 0.0f;
#define differential3_zero(agd) agd.dx = make_float3(0.0f, 0.0f, 0.0f); agd.dy = make_float3(0.0f, 0.0f, 0.0f);


CCL_NAMESPACE_END
