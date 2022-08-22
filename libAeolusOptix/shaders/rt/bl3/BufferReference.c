///prim_index  => vertOffset
///prim_object => idxOffset

ShaderData 
// InstanceID (buildin automatic ordered)
// InstanceCustomID customaizedID  0 ~ 0x7fffff    objectNone = 0x800000
object      <-  ObjectID  <- (InstanceCustomID& 0x800000)|InstanceID) <== object array index (sequence) [others]
+geometry   <-  InstanceCustomID&0x7fffff  <== geometryID   [ tri_vindex2 ]
references         
 [ 
     shader_setup_from_ray
 ]



uvec3 geometry index buffer

uvec4 tri_vindex 
   [w]     ->  sequence( w,w + 1,w + 2)   
   [x,y,z] ->  minimal size vertex

uint3 tri_vindex2 -> geometry index buffer [reuse]
    [x,y,z] ->  minimal size vertex

uint  <=> uvec3
0 - 0
1 - 3
2 - 6
3 - 9





float4 prim_verts2
   

tri_vindex2             memory0 <- allocate on bufferreference 
geom_a = [0...Na]       bufferInfo_a
geom_b = [Na...Nb]      bufferInfo_b
.
.
.

primCustomID   <- primOffset [0,Na,Nb...]
prim <- primID + primCustomID   

1 0 2 1
2 3 0
