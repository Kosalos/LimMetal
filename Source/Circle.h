/* -------------------------------------------------------------
 Please visit: https://dhushara.com/DarkHeart/quasif/quasi.htm
 This app is based on the ideas presented in "Depth First C-script Listing in Colour".
 I have done many little things in the process of porting it to the iPad,
 but the credit belongs to the author of that code.
 --------------------------------------------------------------- */

#pragma once

#include "CComplex.h"

typedef struct {
    int active;
    CComplex a,b,c,d;
} Matrix;

typedef struct {
    CComplex c;
    float r;
} Circle;

typedef struct {
    float x, y, z;
} vector;

/* Recognizing great circles */
#define VEPS 0.0000000001

CComplex det(Matrix x);
Matrix make_sl2(Matrix x);
Matrix conjmat(Matrix x);
Matrix inverse(Matrix x);
Matrix product(Matrix x,Matrix y);
Matrix circle_to_matrix(Circle circ);
Matrix line_to_matrix(Circle circ);
Circle matrix_to_circle(Matrix x);
Circle matrix_to_line(Matrix x);
Circle image_circle(Matrix x,Circle c);

/* Vector subroutines */
vector vadd(vector v,vector w);
vector vsub(vector v,vector w);
float vabs(vector v);

/* Line subroutines */
float cot(float a);

/* Return x so line contains (x,y) */
float meetx(Circle circ,float y);

/* Return y so line contains (x,y) */
float meety(Circle circ,float x);

/* Sphere subroutines */
vector complex_to_s2(CComplex z);


#ifdef ZORRO
/* Convert Circle in plane to Circle on S^2 */
/* Method is to find a pair of opposite points on Circle */
/* Return norm vector; put radius in R^3 in r*/
vector circle_to_s2(Circle circ,float *r);

/* Convert line in plane to Circle on S^2 */
vector line_to_s2(Circle circ,float *r);
#endif
