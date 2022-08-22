import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

#device memory  dtype 5   element 4 size 15
prim_tri_verts = [ 
    0.36021 ,  -0.45222 ,  -0.95711 ,  1.00000 ,
    1.00326 , -0.17667 ,  0.46105 ,  1.00000 , 
    -0.36021 ,  0.45222 ,  0.95711 ,  1.00000 ,

    0.36021 ,  -0.45222 ,  -0.95711 , 1.00000 ,
    -0.36021 ,  0.45222 ,  0.95711 ,  1.00000 ,
    -1.00326 ,  0.17667 ,  -0.46105 ,  1.00000 , 

    1.04415 , 1.48083 ,  2.33018 ,  1.00000 ,
    -0.31933 ,  2.10972 , 2.82624 ,  1.00000 ,
    0.40109 ,  1.20528 ,  0.91201 ,  1.00000 , 

    -1.38237 ,  2.38197 ,  2.07454 ,  1.00000 , 
    -0.79592 ,  1.21624 ,  0.48907 ,  1.00000 ,
    -1.18156 , 1.06540 ,  0.07572 ,  1.00000 ,  
    
    -1.38237 ,  2.38197 , 2.07454 ,  1.00000 , 
    -1.18156 ,  1.06540 ,  0.07572 ,1.00000 ,
    -4.05696 ,  3.74572 ,  2.16708 ,  1.00000 
]

prim_tri_index = 
[
     0, 3,  6,  9,  12,
]
# device memory  dtype 4   element 1 size 5
prim_index = [0,1 , 2 , 3 , 4 ]
prim_object = [0 ,0 , 1 , 2 , 2]
#device memory  dtype 3   element 4 size 5
tri_vindex =[
 0,  1,  3,  0,
 0,  3,  2,  3,
 5,  6,  4,  6,
 8,  10,  9, 9, 
 8,  9,  7,  12
]



def scatter(D2,ax):
    print(f"  len  {len(D2)}")
    s  = []
    c  = []
    for d in D2:
        if d.tolist() not in s:
            s.append(d.tolist())
            c.append(1)  
        else:
            c[s.index(d.tolist())]+= 1
    xy = np.array(s)
    x = xy[:,0] 
    y = xy[:,1] 
    colors = np.random.rand(len(x))
    area = np.array(c)
    area = (30*area/np.max(area))**2

    ax.scatter(x, y, s=area, c=colors, alpha=0.5)
    
    c.sort()
    return c

def scatter2(x,y,ax):
    ax.scatter(x, y,  alpha=0.5)

def LEN_SET(d):
    d = np.array(d)
    print(f"  len  {len(d)}")
    d.sort()
    unique, counts = np.unique(d, return_counts=True)
    sd =  dict(zip(unique, counts))
    print(f"  set {len(sd)}")
    counts.sort()
    #print(f" count {counts}")
    #print(f" count {unique}")
    """
    sd = set(d)
    print(f"  set {len(sd)}")
    print(f"  {sd} ")
    hist, bin_edges = np.histogram(d)
    print(f"  hist  {hist}  bin {bin_edges} ")
    """
    return (unique,counts)
