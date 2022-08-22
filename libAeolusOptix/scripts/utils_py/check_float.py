#-12345678.000000   uint 3409731918  SIGN 1 EXP 150 FRAC 3957070
def Float(s,e,f):
    a = 1
    for i in range(1,24):
        a += 2**(-i)*((f>>(23-i))&1)
    print(f" 2**{e-127} * {a}  ")    
    return -1**(s)*(2**(e-127))*a
print(Float(1,150,3957070))
print(Float(0,0b01111100,0b01000000000000000000000))
print(Float(0,59,2304149))
print(Float(0,70,0b10000000000000000000000))