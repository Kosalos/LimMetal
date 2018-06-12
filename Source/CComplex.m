/* -------------------------------------------------------------
 Please visit: https://dhushara.com/DarkHeart/quasif/quasi.htm
 This app is based on the ideas presented in "Depth First C-script Listing in Colour".
 I have done many little things in the process of porting it to the iPad,
 but the credit belongs to the author of that code.
 --------------------------------------------------------------- */

#include <math.h>
#include "CComplex.h"

/* Complex arithmetic and utilities */

CComplex add (CComplex z, CComplex w)
{
    CComplex t;
    t.x = z.x + w.x;
    t.y = z.y + w.y;
    return(t);
}

CComplex sub (CComplex z, CComplex w)
{
    CComplex t;
    t.x = z.x - w.x;
    t.y = z.y - w.y;
    return(t);
}

CComplex mult (CComplex z, CComplex w)
{
    CComplex t;
    t.x = z.x*w.x - z.y*w.y;
    t.y = z.x*w.y + z.y*w.x;
    return(t);
}

CComplex recip (CComplex z)
{
    CComplex w;
    float r;
    r = z.x*z.x + z.y*z.y;
    w.x = z.x / r;
    w.y = -z.y / r;
    return(w);
}

CComplex divide (CComplex z, CComplex w)
{
    //CComplex mult(), recip();
    return(mult(z,recip(w)));
}

CComplex cx_conj(CComplex z)
{
    CComplex t;
    t = z;
    t.y = -t.y;
    return(t);
}

CComplex cx_sqrt(CComplex z)
{
    CComplex w;
    //float fabs(), sqrt();
    
    /* Worry about numerical stability */
    if (z.x == 0.0 && z.y == 0.0) return(z);
    else
        if (z.x > fabs(z.y))
        {
            w.x = sqrt((z.x+sqrt(z.x*z.x+z.y*z.y))/2);
            w.y = z.y/(2*w.x);
        }
        else
        {
            w.y = sqrt((-z.x+sqrt(z.x*z.x+z.y*z.y))/2);
            w.x = z.y/(2*w.y);
        }
    return(w);
}

/* Compute sqrt(z) in the half-plane perpendicular to w. */

CComplex contsqrt(CComplex z, CComplex w)
{
    CComplex t;
    
    t = cx_sqrt(z);
    if (0 > (t.x*w.x + t.y*w.y))
    {t.x = -t.x; t.y = -t.y;}
    return(t);
}

float cx_abs (CComplex z)       /* L 2 norm of z */
{
    return (sqrt (z.x*z.x + z.y*z.y));
}

float infnorm (CComplex z)   /* L infinity norm of z */
{
    float a,b;
    a = (z.x > 0) ? z.x : -z.x;
    b = (z.y > 0) ? z.y : -z.y;
    return ((a>b) ? a : b);
}

CComplex polar (float radius, float angle) /*Convert to CComplex. */
{
    CComplex z;
    z.x = cos (angle) * radius;
    z.y = sin (angle) * radius;
    return(z);
}

/* Values in [-pi,pi]. */
float arg(CComplex z)
{
    return(atan2(z.y,z.x));
}

CComplex cx_exp(CComplex z)
{
    CComplex w;
    float m;
    
    m = exp(z.x);
    w.x = m * cos(z.y);
    w.y = m * sin(z.y);
    return(w);
}

CComplex cx_log(CComplex z)
{
    CComplex w;
    
    w.x = log(cx_abs(z));
    w.y = arg(z);
    return(w);
}

CComplex cx_sin(CComplex z)
{
    CComplex w;
    
    w.x = sin(z.x) * cosh(z.y);
    w.y = cos(z.x) * sinh(z.y);
    return(w);
}

CComplex cx_cos(CComplex z)
{
    CComplex w;
    
    w.x = cos(z.x) * cosh(z.y);
    w.y = -sin(z.x) * sinh(z.y);
    return(w);
}

CComplex cx_sinh(CComplex z)
{
    CComplex w;
    
    w.x = sinh(z.x) * cos(z.y);
    w.y = cosh(z.x) * sin(z.y);
    return(w);
}

CComplex cx_cosh(CComplex z)
{
    CComplex w;
    
    w.x = cosh(z.x) * cos(z.y);
    w.y = sinh(z.x) * sin(z.y);
    return(w);
}

CComplex power(CComplex z, float t)   /* Raise z to a real power t */
{
    //float arg(), cx_abs(), pow();
    //CComplex polar();
    
    return(polar(pow(cx_abs(z),t), t*arg(z)));
}

/*  Map points in the unit disk onto the lower hemisphere of the
 Riemann sphere by inverse stereographic projection.
 Projecting, r -> s = 2r/(r^2 + 1);  inverting this,
 s -> r = (1 - sqrt(1-s^2))/s.   */

CComplex disk_to_sphere(CComplex z)
{
    CComplex w;
    float r, s;
    
    s = cx_abs(z);
    if (s == 0) return(z);
    else r = (1 - sqrt(1-s*s))/s;
    w.x = (r/s)*z.x;
    w.y = (r/s)*z.y;
    return(w);
}

CComplex mobius(CComplex a,CComplex b,CComplex c,CComplex d,CComplex z)
{
    return(divide(add(mult(a,z),b),
                  add(mult(c,z),d)));
}
