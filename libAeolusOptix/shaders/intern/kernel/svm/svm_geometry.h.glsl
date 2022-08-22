#ifndef _GEOM_OBJ_H2_
#define _GEOM_OBJ_H2_
CCL_NAMESPACE_BEGIN





ccl_device int shader_pass_id()
{
  return kernel_tex_fetch(_shaders, (GSD.shader & SHADER_MASK)).pass_id;
}


void svm_node_geometry( uint type, uint out_offset)
{
  float3 data;
  switch (type) {
    case NODE_GEOM_P:
      data = sd.P;
      break;
    case NODE_GEOM_N:
      data = sd.N;
      break;
#ifdef _DPDU_
    case NODE_GEOM_T:
      data = primitive_tangent();
      break;
#endif
    case NODE_GEOM_I:
      data = sd.I;
      break;
    case NODE_GEOM_Ng:
      data = sd.Ng;
      break;
    case NODE_GEOM_uv:
      data = make_float3(sd.u, sd.v, 0.0f);
      break;
    default:
      data = make_float3(0.0f, 0.0f, 0.0f);
  }

  stack_store_float3(out_offset, data);
}
/* Object Info */

ccl_device void svm_node_object_info(uint type, uint out_offset)
{
  float data;
  switch (type) {
    case NODE_INFO_OB_LOCATION: {
      stack_store_float3(out_offset, object_location());
      return;
    }
    case NODE_INFO_OB_COLOR: {
      stack_store_float3(out_offset, object_color(GSD.object));
      return;
    }
    case NODE_INFO_OB_INDEX:
      data = object_pass_id(GSD.object);
      break;
    case NODE_INFO_MAT_INDEX:
      data = shader_pass_id();
      break;
    case NODE_INFO_OB_RANDOM: {
      if (GSD.lamp != LAMP_NONE) {
        data = lamp_random_number(GSD.lamp);
      }
      else {
        data = object_random_number(GSD.object);
      }
      break;
    }
    default:
      data = 0.0f;
      break;
  }

  stack_store_float(out_offset, data);
}


ccl_device void svm_node_geometry_bump_dx(uint type, uint out_offset)
{
#ifdef _RAY_DIFFERENTIALS_
  float3 data;
  switch (type) {
    case NODE_GEOM_P:
      data = sd.P + sd.dP.dx;
      break;
    case NODE_GEOM_uv:
      data = make_float3(sd.u + sd.du.dx, sd.v + sd.dv.dx, 0.0f);
      break;
    default:
      svm_node_geometry( type, out_offset);
      return;
  }

  stack_store_float3(out_offset, data);
#else
  svm_node_geometry( type, out_offset);
#endif
}

ccl_device void svm_node_geometry_bump_dy(uint type, uint out_offset)
{
#ifdef _RAY_DIFFERENTIALS_
  float3 data;

  switch (type) {
    case NODE_GEOM_P:
      data = sd.P + sd.dP.dy;
      break;
    case NODE_GEOM_uv:
      data = make_float3(sd.u + sd.du.dy, sd.v + sd.dv.dy, 0.0f);
      break;
    default:
      svm_node_geometry(type, out_offset);
      return;
  }

  stack_store_float3(out_offset, data);
#else
  svm_node_geometry(type, out_offset);
#endif
}


ccl_device void svm_node_particle_info(uint type, uint out_offset)
{
  switch (type) {
    case NODE_INFO_PAR_INDEX: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float(out_offset, particle_index(particle_id));
      break;
    }
    case NODE_INFO_PAR_RANDOM: {
      int particle_id = object_particle_id(sd.object);
      float random = hash_uint2_to_float(particle_index(particle_id), 0);
      stack_store_float(out_offset, random);
      break;
    }
    case NODE_INFO_PAR_AGE: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float(out_offset, particle_age(particle_id));
      break;
    }
    case NODE_INFO_PAR_LIFETIME: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float(out_offset, particle_lifetime(particle_id));
      break;
    }
    case NODE_INFO_PAR_LOCATION: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float3(out_offset, particle_location(particle_id));
      break;
    }
#if 0 /* XXX float4 currently not supported in_rsv SVM stack */
    case NODE_INFO_PAR_ROTATION: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float4(out_offset, particle_rotation(particle_id));
      break;
    }
#endif
    case NODE_INFO_PAR_SIZE: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float(out_offset, particle_size(particle_id));
      break;
    }
    case NODE_INFO_PAR_VELOCITY: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float3(out_offset, particle_velocity(particle_id));
      break;
    }
    case NODE_INFO_PAR_ANGULAR_VELOCITY: {
      int particle_id = object_particle_id(sd.object);
      stack_store_float3(out_offset, particle_angular_velocity(particle_id));
      break;
    }
  }
}

#ifdef _HAIR_

/* Hair Info */

ccl_device void svm_node_hair_info(
    inout KernelGlobals kg, inout ShaderData sd, inout float stack[SVM_STACK_SIZE]
, uint type, uint out_offset)
{
  float data;
  float3 data3;

  switch (type) {
    case NODE_INFO_CURVE_IS_STRAND: {
      data = (sd.type & PRIMITIVE_ALL_CURVE) != 0;
      stack_store_float(stack, out_offset, data);
      break;
    }
    case NODE_INFO_CURVE_INTERCEPT:
      break; /* handled as attribute */
    case NODE_INFO_CURVE_RANDOM:
      break; /* handled as attribute */
    case NODE_INFO_CURVE_THICKNESS: {
      data = curve_thickness(kg, sd);
      stack_store_float(stack, out_offset, data);
      break;
    }
    /*case NODE_INFO_CURVE_FADE: {
      data = sd.curve_transparency;
      stack_store_float(stack, out_offset, data);
      break;
    }*/
    case NODE_INFO_CURVE_TANGENT_NORMAL: {
      data3 = curve_tangent_normal(kg, sd);
      stack_store_float3(stack, out_offset, data3);
      break;
    }
  }
}
#endif

CCL_NAMESPACE_END

#endif
