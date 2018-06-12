/* -------------------------------------------------------------
 Please visit: https://dhushara.com/DarkHeart/quasif/quasi.htm
 This app is based on the ideas presented in "Depth First C-script Listing in Colour".
 I have done many little things in the process of porting it to the iPad,
 but the credit belongs to the author of that code.
 --------------------------------------------------------------- */

#pragma once

#define PI 3.1415926 //535897932384

typedef struct {
    float x,y;
} CComplex;

/* Complex arithmetic and utilities */

CComplex add (CComplex z, CComplex w);
CComplex sub (CComplex z, CComplex w);
CComplex mult (CComplex z, CComplex w);
CComplex recip (CComplex z);
CComplex divide (CComplex z, CComplex w);
CComplex cx_conj(CComplex z);
CComplex cx_sqrt(CComplex z);
CComplex contsqrt(CComplex z, CComplex w);

float cx_abs (CComplex z);
float infnorm (CComplex z);

CComplex polar (float radius, float angle);

float arg(CComplex z);

CComplex cx_exp(CComplex z);
CComplex cx_log(CComplex z);
CComplex cx_sin(CComplex z);
CComplex cx_cos(CComplex z);
CComplex cx_sinh(CComplex z);
CComplex cx_cosh(CComplex z);
CComplex power(CComplex z, float t);
CComplex disk_to_sphere(CComplex z);
CComplex mobius(CComplex a,CComplex b,CComplex c,CComplex d,CComplex z);
