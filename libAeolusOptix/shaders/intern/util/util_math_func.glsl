#ifndef  _UTIL_MATH_FUNC_H_
#define _UTIL_MATH_FUNC_H_

#define SCIPY_LGAMMA

#ifdef LANCOZ_LGAMMA
const double LGAMMA_LANCOZ[6] = double[6]( 76.18009172947146,
    -86.50532032941677, 24.01409824083091,
    -1.231739572450155, 0.1208650973866179E-2,
    -0.5395239384953E-5 );

#  define M_LN_SQR_2PI_F 0.91893853320467274178

/// https://jamesmccaffrey.wordpress.com/2013/06/19/the-log-gamma-function-with-c/
double lgamma(double x)
{
  // Log of Gamma from Lanczos with g=5, n=6/7
  // not in A & S 

  double denom = x + 1;
  double y = x + 5.5;
  double series = 1.000000000190015;
  for (int i = 0; i < 6; ++i)
   {
    series += LGAMMA_LANCOZ[i] / denom;
    denom += 1.0;
  }

  return (M_LN_SQR_2PI_F + (x + 0.5) * log(y) - y + log(series / x));
}
#endif

#ifdef SCIPY_LGAMMA
bool isfinite(double f)
{
  uint64_t hl =  doubleBitsToUint64(f);
  uint hx =  uint((hl >> 32) & 0xffffffff);
  uint lx =  uint(hl & 0xffffffff);

  int retval = -1;

  lx |= hx & 0xfffff;
  hx &= 0x7ff00000;
  if ((hx | lx) == 0)
    retval = 0;
  else if (hx == 0)
    retval = -2;
  else if (hx == 0x7ff00000)
    retval = lx != 0 ? 1 : 2;

  return !(retval == 1 || retval == 2);
}

double STIR[8] = double[8](
	7.87311395793093628397E-4,
	-2.29549961613378126380E-4,
	-2.68132617805781232825E-3,
	3.47222221605458667310E-3,
	8.33333333333482257126E-2,
  0,0,0
);
double P[8] = double[8](
	1.60119522476751861407E-4,
	1.19135147006586384913E-3,
	1.04213797561761569935E-2,
	4.76367800457137231464E-2,
	2.07448227648435975150E-1,
	4.94214826801497100753E-1,
	9.99999999999999996796E-1,0
);
double Q[8] = double[8](
	-2.31581873324120129819E-5,
	5.39605580493303397842E-4,
	-4.45641913851797240494E-3,
	1.18139785222060435552E-2,
	3.58236398605498653373E-2,
	-2.34591795718243348568E-1,
	7.14304917030273074085E-2,
	1.00000000000000000320E0
);
double A[8] = double[8](
	8.11614167470508450300E-4,
	-5.95061904284301438324E-4,
	7.93650340457716943945E-4,
	-2.77777777730099687205E-3,
	8.33333333333331927722E-2,
  0,0,0
);

double B[8] = double[8](
	-1.37825152569120859100E3,
	-3.88016315134637840924E4,
	-3.31612992738871184744E5,
	-1.16237097492762307383E6,
	-1.72173700820839662146E6,
	-8.53555664245765465627E5,
  0,0
);

double C[8] = double[8](
	/* 1.00000000000000000000E0, */
	-3.51815701436523470549E2,
	-1.70642106651881159223E4,
	-2.20528590553854454839E5,
	-1.13933444367982507207E6,
	-2.53252307177582951285E6,
	-2.01889141433532773231E6,0,0
);
#define MAXGAM 171.624376956302725LF
#define LOGPI  1.14472988584940017414LF
#define MAXSTIR 143.01608LF
#define SQTPI  2.50662827463100050242E0LF

double log(double v){return log(float(v));};

double polevl(double x,const double coef[8], int N)
{
	double ans;
	int i;
  int j = 0;

	ans = coef[j];
  j+=1;
	i = N;
	do
		ans = ans * x + coef[j++];
	while (bool(--i));

	return (ans);
}

double p1evl(double x, const double coef[8], int N)
{
	double ans;
	int i;
  int j = 0;
	ans = x + coef[j];
  j+=1;
	i = N - 1;

	do
		ans = ans * x +  coef[j++];
	while (bool(--i));

	return (ans);
}

double stirf(double x)
{
	double y, w, v;

	if (x >= MAXGAM) {
    kernel_assert("assert MAXGAMMA line:228 util_math",false)
		return FLT_MAX;
	}
	w = 1.0 / x;
	w = 1.0 + w * polevl(w, STIR, 4);
	y = exp(x);
	if (x > MAXSTIR) {		/* Avoid overflow in pow() */
		v = pow(x, 0.5 * x - 0.25);
		y = v * (v / y);
	}
	else {
		y = pow(x, x - 0.5) / y;
	}
	y = SQTPI * y * w;
	return (y);
}
double Gamma(double x)
{
	double p, q, z;
	int i;
	int sgngam = 1;
  bool eret = false;
#define _small_ {\
	if (x == 0.0) {\
		kernel_assert("252 Gamma  SF_ERROR_OVERFLOW, NULL",false);\
		return DBL_MAX;\
	}\
	else\
		return (z / ((1.0 + 0.5772156649015329 * x) * x));\
}
	
  if (!isfinite(x)) {
		return x;
	}
	q = fabs(x);

	if (q > 33.0) {
		if (x < 0.0) {
			p = floor(q);
			if (p == q) {
        kernel_assert("Gamma  SF_ERROR_OVERFLOW, NULL",false);
				return DBL_MAX;
			}
			i = int(p);
			if ((i & 1) == 0)
				sgngam = -1;
			z = q - p;
			if (z > 0.5) {
				p += 1.0;
				z = q - p;
			}
			z = q * sin(M_PI * z);
			if (z == 0.0) {
				return (sgngam * DBL_MAX);
			}
			z = fabs(z);
			z = M_PI / (z * stirf(q));
		}
		else {
			z = stirf(x);
		}
		return (sgngam * z);
	}
			

	z = 1.0;
	while (x >= 3.0) {
		x -= 1.0;
		z *= x;
	}

	while (x < 0.0) {
		if (x > -1.E-9)
			_small_;
		z /= x;
		x += 1.0;
	}

	while (x < 2.0) {
		if (x < 1.e-9)
			_small_;
		z /= x;
		x += 1.0;
	}

	if (x == 2.0)
		return (z);

	x -= 2.0;
	p = polevl(x, P, 6);
	q = polevl(x, Q, 7);
	return (z * p / q);


}

#define LS2PI 0.91893853320467274178LF
#define MAXLGM 2.556348e305LF
double lgamma(double x,inout int sign)
{

 #define  lgsing \
			kernel_assert("lgam , SF_ERROR_SINGULAR, NULL",false);\
			return DBL_MAX; 

	double p, q, u, w, z;
	int i;
	sign = 1;
	if (!isfinite(x))
		return x;
	if (x < -34.0) {
    #ifdef MINUS34
		q = -x;
		w = lgamma(q, sign);
		p = floor(q);
		if (p == q) {
		    lgsing
		}
		i = int(p);
		if ((i & 1) == 0)
			sign = -1;
		else
			sign = 1;
		z = q - p;
		if (z > 0.5) {
			p += 1.0;
			z = p - q;
		}
		z = q * sin(M_PI * z);
		if (z == 0.0)
		 {
       lgsing;
      }
		/*     z = log(NPY_PI) - log( z ) - w; */
		z = LOGPI - log(z) - w;
		return (z);
    #else
    lgsing 
    #endif
	}

	if (x < 13.0) {
		z = 1.0;
		p = 0.0;
		u = x;
		while (u >= 3.0) {
			p -= 1.0;
			u = x + p;
			z *= u;
		}
		while (u < 2.0) {
			if (u == 0.0)
				{
           lgsing;
        }
			z /= u;
			p += 1.0;
			u = x + p;
		}
		if (z < 0.0) {
			sign = -1;
			z = -z;
		}
		else
			sign = 1;
		if (u == 2.0)
			return (log(z));
		p -= 2.0;
		x = x + p;
		p = x * polevl(x, B, 5) / p1evl(x, C, 6);
    //PROFI_DATA_012(x ,polevl(x, B, 5), p1evl(x, C, 6));
    //PROFI_DATA_345(p,log(z),z);
		return (log(z) + p);
	}

	if (x > MAXLGM) {
		return (sign * DBL_MAX);
	}

	q = (x - 0.5) * log(x) - x + LS2PI;
	if (x > 1.0e8)
		return (q);

	p = 1.0 / (x * x);
	if (x >= 1000.0)
		q += ((7.9365079365079365079365e-4 * p
			- 2.7777777777777777777778e-3) * p
			+ 0.0833333333333333333333) / x;
	else
		q += polevl(p, A, 4) / x;
	return (q);
}

#endif



float lgammaf(float v) 
{    int sign; return float(lgamma(double(v),sign)); }

ccl_device_inline float beta(float x, float y)
{
#if (!defined(_KERNEL_OPENCL_) | defined(_KERNEL_VULKAN_))
  return expf(lgammaf(x) + lgammaf(y) - lgammaf(x + y));
#else
  return expf(lgamma(x) + lgamma(y) - lgamma(x + y));
#endif
}


#endif