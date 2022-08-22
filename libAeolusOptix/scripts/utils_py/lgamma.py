import numpy as np
STIR = [
	7.87311395793093628397E-4,
	-2.29549961613378126380E-4,
	-2.68132617805781232825E-3,
	3.47222221605458667310E-3,
	8.33333333333482257126E-2,
  0,0,0
]

P   = [
	1.60119522476751861407E-4,
	1.19135147006586384913E-3,
	1.04213797561761569935E-2,
	4.76367800457137231464E-2,
	2.07448227648435975150E-1,
	4.94214826801497100753E-1,
	9.99999999999999996796E-1,0
]

Q  = [
	-2.31581873324120129819E-5,
	5.39605580493303397842E-4,
	-4.45641913851797240494E-3,
	1.18139785222060435552E-2,
	3.58236398605498653373E-2,
	-2.34591795718243348568E-1,
	7.14304917030273074085E-2,
	1.00000000000000000320E0
]

A  = [
	8.11614167470508450300E-4,
	-5.95061904284301438324E-4,
	7.93650340457716943945E-4,
	-2.77777777730099687205E-3,
	8.33333333333331927722E-2,
  0,0,0
]

B = [
	-1.37825152569120859100E3,
	-3.88016315134637840924E4,
	-3.31612992738871184744E5,
	-1.16237097492762307383E6,
	-1.72173700820839662146E6,
	-8.53555664245765465627E5,
  0,0
]

C = [
	#/* 1.00000000000000000000E0, */
	-3.51815701436523470549E2,
	-1.70642106651881159223E4,
	-2.20528590553854454839E5,
	-1.13933444367982507207E6,
	-2.53252307177582951285E6,
	-2.01889141433532773231E6,0,0
]
FLT_MIN  = 1.175494350822287507969e-38
FLT_MAX  = 340282346638528859811704183484516925440.0
FLT_EPSILON = 1.192092896e-07
DBL_MAX  = 1.7976931348623158e+308
MAXGAM   = 171.624376956302725
LOGPI    = 1.14472988584940017414
MAXSTIR  = 143.01608
SQTPI    =  2.50662827463100050242E0
M_PI     = 3.14159265358979323846  

import ctypes
def doubleBitsToUint64(f):
    return ctypes.c_uint64.from_buffer(ctypes.c_double(f)).value

def isfinite(f):
    hl =  doubleBitsToUint64(f)
    hx =  (hl >> 32) & 0xffffffff
    lx =  hl & 0xffffffff
    retval = -1
    lx |= hx & 0xfffff
    hx &= 0x7ff00000
    if ((hx | lx) == 0):
        retval = 0
    elif (hx == 0):
        retval = -2
    elif (hx == 0x7ff00000):
        retval =  1 if lx != 0 else 2
    return not (retval == 1 or retval == 2)


def polevl(x,coef,N):
    j = 0
    ans = coef[j]
    i = N
    i-=1
    while(i):
        i -=1
        ans = ans * x + coef[j]
        j+=1
    return ans

def p1evl(x,coef, N):
    j = 0
    ans = x + coef[j]
    i = N - 1
    while(i):
        i-=1
        ans = ans * x +  coef[j]
        j +=1
    return (ans)


def stirf(x):
    if (x >= MAXGAM) :
        print("assert MAXGAMMA line:228 util_math False")
        return FLT_MAX
    w = 1.0/x
    w = 1.0 + w * polevl(w, STIR, 4)
    y = exp(x)
    if (x > MAXSTIR):
        v = pow(x, 0.5 * x - 0.25)
        y = v * (v / y)
    else:
        y = pow(x, x - 0.5) / y
    y = SQTPI * y * w
    return (y)

def Gamma(x):
    sgngam = 1
    eret = False
    def _small_(x):
        if (x == 0.0):
            print("252 Gamma  SF_ERROR_OVERFLOW, NULL",false)
            return DBL_MAX
        else:
            return (z / ((1.0 + 0.5772156649015329 * x) * x))
    if ( not isfinite(x)):
        return x
	
    q = np.abs(x)
    if (q > 33.0):
        if(x < 0.0):
            p = floor(q)
            if (p == q):
                print("Gamma  SF_ERROR_OVERFLOW, NULL false")
                return DBL_MAX
            i = int(p)
            if (i & 1 ) == 0:
                sgngam = -1
            z = q - p
            if(z > 0.5):
                p += 1.0
                z = q - p
            z = q * np.sin(M_PI * z)
            if z == 0.0:
                return sgngam * DBL_MAX
            z =  np.abs(z)
            z =  M_PI / (z * stirf(q))
        else:
            z = stirf(x)
        return (sgngam * z)
    z = 1.0
    while (x >= 3.0):
        x -= 1.0
        z *= x
    while (x < 0.0):
        if (x > -1.E-9):
            _small_(x)
        z /= x
        x += 1.0
    while x < 2.0:
        if x < 1.e-9 :
            _small_(x)
        z /= x
        x += 1.0
    if (x == 2.0):
        return (z)
    x -= 2.0
    p = polevl(x, P, 6)
    q = polevl(x, Q, 7)
    return (z * p / q)





LS2PI  = 0.91893853320467274178
MAXLGM = 2.556348e305
def  lgamma(x,sign):
    def lgsing():
        print("lgam , SF_ERROR_SINGULAR, NULL False")
        return DBL_MAX
    sign = 1
    if not isfinite(x) :
        return x
    if (x < -34.0):
        return lgsing()
    if (x < 13.0):
        z = 1.0
        p = 0.0
        u = x
        while (u >= 3.0):
            p -= 1.0
            u = x + p
            z *= u
        while (u < 2.0):
            if(u == 0.0):
                return lgsing()
            z /= u
            p += 1.0
            u = x + p
        if (z < 0.0):
            sign = -1
            z = -z
        else:
            sign = 1
        if (u == 2.0):
            return (np.log(z))
        p -= 2.0
        x = x + p
        p = x * polevl(x, B, 5) / p1evl(x, C, 6)
        return (np.log(z) + p)
    if (x > MAXLGM):
        return (sign * DBL_MAX)
    q = (x - 0.5) * log(x) - x + LS2PI
    if (x > 1.0e8):
        return (q)
    p = 1.0 / (x * x)
    if (x >= 1000.0):
        q += ((7.9365079365079365079365e-4 * p
        - 2.7777777777777777777778e-3) * p
        + 0.0833333333333333333333) / x
    else:
        q += polevl(p, A, 4) / x
    return (q)









