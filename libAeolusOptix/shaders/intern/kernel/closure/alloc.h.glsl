/*
 * Copyright 2011-2016 Blender Foundation
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
#ifndef _CLOSURE_ALLOC_H_
#define _CLOSURE_ALLOC_H_

CCL_NAMESPACE_BEGIN

/*
ccl_device int closure_alloc(ClosureType type, float3 weight)
{
  
  if (sd.num_closure_left == 0)
    return -1;
  if(sd.num_closure > 0){
    sd.alloc_offset += 1; 
    if(sd.alloc_offset >= (sd.atomic_offset+64)){
      kernel_assert("Alloc Max Limit  \n",false);
      return -1;
    }
    SC_zeros(getSC());
    getSC().next = sd.alloc_offset-1;
  }else{
    sd.alloc_offset = sd.atomic_offset;
    SC_zeros(getSC());
    getSC().next = -1;
  }
  
 
  
  getSC().type         =  type;
  getSC().weight       =  weight;
  
  sd.num_closure++;
  sd.num_closure_left--;


  return sd.alloc_offset;
}
*/
int closure_alloc(uint type, vec4 weight)
{
    if (GSD.num_closure_left == 0)
    {
        return -1;
    }
    if (GSD.num_closure < 63)
    {
        GSD.alloc_offset++;
        getSC().sample_weight = 0.0;
        getSC().N = vec4(0.0);
        for (int _i_ = 0; _i_ < 25; _i_++)
        {
            getSC().data[_i_] = 0.0;
        }
        
    }
    else
    {
      kernel_assert("Alloc Max Limit  \n",false);
      return -1;
    }

    getSC().type   = type;
    getSC().weight = weight;
    GSD.num_closure++;
    GSD.num_closure_left--;
    return GSD.alloc_offset;
}

ccl_device_inline int bsdf_alloc( uint size,float3 weight)
{

    int n  = closure_alloc(CLOSURE_NONE_ID, weight);
    if (n < 0)return -1;

    float sample_weight = fabsf(average(weight));
    _getSC(n).sample_weight = sample_weight;
    return (sample_weight >= CLOSURE_WEIGHT_CUTOFF) ? n : -1;

}


CCL_NAMESPACE_END

#endif