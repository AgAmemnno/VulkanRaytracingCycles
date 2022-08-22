LGAMMA_LANCOZ = [ 76.18009172947146,
    -86.50532032941677, 24.01409824083091,
    -1.231739572450155, 0.1208650973866179E-2,
    -0.5395239384953E-5 
]

M_LN_SQR_2PI_F = 0.91893853320467274178
#/// https://jamesmccaffrey.wordpress.com/2013/06/19/the-log-gamma-function-with-c/
import numpy as np
import math

def lgamma(x):
  #// Log of Gamma from Lanczos with g=5, n=6/7
  #// not in A & S 
  denom  = x + 1
  y      = x + 5.5
  series = 1.000000000190015
  for  i in range(6):
    series += LGAMMA_LANCOZ[i] / denom
    denom  += 1.0
  print(f" x {x} series {series} denom {denom}")
  return (M_LN_SQR_2PI_F + (x + 0.5) * np.log(y) - y + np.log(series / x))


#define LG_g 5.0      // Lanczos parameter "g"
  #define LG_N 6        // Range of coefficients i=[0..N]
LG_N = 6
lct = [
     1.000000000190015,
    76.18009172947146,
   -86.50532032941677,
    24.01409824083091,
    -1.231739572450155,
     0.1208650973866179e-2,
    -0.5395239384953e-5
]
ln_sqrt_2_pi = 0.91893853320467274178
g_pi = 3.14159265358979323846
# Compute the logarithm of the Gamma function using the Lanczos method.
def ln_gamma(z):
    base = 0.
    rv = 0.
    i = 0
    if  z < 0.5 :
      #Use Euler's reflection formula:
      #Gamma(z) = Pi / [Sin[Pi*z] * Gamma[1-z]];
      return math.log(g_pi / math.sin(g_pi * z)) - ln_gamma(1.0 - z)
    z = z - 1.0;
    base = z + LG_g + 0.5;  # Base of the Lanczos exponential
    sum = 0;
    #We start with the terms that have the smallest coefficients and largest
    #denominator.
    for i in range(LG_N,0):
        sum += lct[i] / (z + (float(i)))
    sum += lct[0]
    # This printf is just for debugging
    #printf("ls2p %7g  l(b^e) %7g   -b %7g  l(s) %7g\n", ln_sqrt_2_pi,
    #          log(base)*(z+0.5), -base, log(sum));
    #// Gamma[z] = Sqrt(2*Pi) * sum * base^[z + 0.5] / E^base
    return ((ln_sqrt_2_pi + math.log(sum)) - base) + math.log(base)*(z+0.5)
import matplotlib.pyplot as plt
def plothist(d):
    fig = plt.figure()
    fig.subplots_adjust(top=0.8)
    ax1 = fig.add_subplot(211)
    ax1.set_ylabel('label')
    ax1.set_title('line')

    t = range(len(d))
    s = d
    line, = ax1.plot(t, s, color='blue', lw=2)

    ax2 = fig.add_axes([0.15, 0.1, 0.7, 0.3])
    n, bins, patches = ax2.hist(s, 50,
                                facecolor='yellow', edgecolor='yellow')
    ax2.set_xlabel('hist (s)')

a = [math.lgamma( -1 + i/500 + 0.01 ) for i in range(1000)]
plothist(a)
plt.show()
for i in range(1,100):
    x = -float(i)/100 
    print(f" sin    {math.sin(g_pi * x)}")

    #print(f" x {x}  {ln_gamma(x)}  {math.lgamma(x)} ")




