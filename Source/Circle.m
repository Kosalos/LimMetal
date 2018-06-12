/* -------------------------------------------------------------
 Please visit: https://dhushara.com/DarkHeart/quasif/quasi.htm
 This app is based on the ideas presented in "Depth First C-script Listing in Colour".
 I have done many little things in the process of porting it to the iPad,
 but the credit belongs to the author of that code.
 --------------------------------------------------------------- */

#include <math.h>
#include "Circle.h"
#include "Lim.h"

#define INF 1e20

CComplex det(Matrix x)
{
	return(sub(mult(x.a,x.d),mult(x.b,x.c)));
}

Matrix make_sl2(Matrix x)
{
	CComplex d;

	d = recip(cx_sqrt(det(x)));
	x.a = mult(x.a,d);
	x.b = mult(x.b,d);
	x.c = mult(x.c,d);
	x.d = mult(x.d,d);
	return(x);
}

Matrix conjmat(Matrix x)
{
	x.a = cx_conj(x.a);
	x.b = cx_conj(x.b);
	x.c = cx_conj(x.c);
	x.d = cx_conj(x.d);
	return(x);
}

Matrix inverse(Matrix x)
{
	Matrix z;
	CComplex d;
	d = det(x);
	z.a = x.d;
	z.b.x = -x.b.x;
	z.b.y = -x.b.y;
	z.c.x = -x.c.x;
	z.c.y = -x.c.y;
	z.d = x.a;
	if(d.x > 0) return(z);
	z.a.x = -z.a.x;
	z.b.x = -z.b.x;
	z.c.x = -z.c.x;
	z.d.x = -z.d.x;
	return(z);
}

Matrix product(Matrix x,Matrix y)
{
	Matrix z;
	CComplex d;

	d = det(x);
	if(d.x < 0) y = conjmat(y);
	z.a = add(mult(x.a,y.a),mult(x.b,y.c));
	z.b = add(mult(x.a,y.b),mult(x.b,y.d));
	z.c = add(mult(x.c,y.a),mult(x.d,y.c));
	z.d = add(mult(x.c,y.b),mult(x.d,y.d));
	return(z);
}

Matrix circle_to_matrix(Circle circ)
{
	Matrix z;
	if(circ.r <= 0) return(line_to_matrix(circ));
	z.a.x = circ.c.x/circ.r; 
	z.a.y = circ.c.y/circ.r;
	z.b.x = circ.r-(circ.c.x*circ.c.x+circ.c.y*circ.c.y)/circ.r;
	z.b.y = 0;
	z.c.x = 1/circ.r;
	z.c.y = 0;
	z.d.x = -circ.c.x/circ.r;
	z.d.y =  circ.c.y/circ.r;
	return(z);
}

Matrix line_to_matrix(Circle circ)
{
	Matrix z;
	CComplex unit;
	static CComplex i = {0.0,1.0};

	unit.x = cos(-PI*circ.r);
	unit.y = sin(-PI*circ.r);
	z.a = mult(i,unit);
	z.b = mult(i,sub(  mult(cx_conj(unit),circ.c),
			   mult(unit,cx_conj(circ.c))   ));
	z.c.x = 0.0; z.c.y = 0.0; 
	z.d = mult(i,cx_conj(unit));
	return(z);
}

Circle matrix_to_circle(Matrix x)
{
	Circle circ;

//	if(x.c.x < LINEFUZZ && x.c.x > -LINEFUZZ) return(matrix_to_line(x));
	circ.c = divide(x.a,x.c);
	circ.r = 1/x.c.x;
	if(circ.r < 0) circ.r = -circ.r;
	return(circ);
}

Circle matrix_to_line(Matrix x)
{
	Circle circ;

	circ.r =   -arg(x.a)/PI - 1.5;
	circ.c.x = -x.b.x/2; 
	circ.c.y = -x.b.y/2; 
	circ.c = mult(circ.c,x.a);
	return(circ);
}

Circle image_circle(Matrix x,Circle c)
{
	Matrix xi, y;

	y = circle_to_matrix(c);
	xi = inverse(x); 
	y = product(x,product(y,xi));
	c = matrix_to_circle(y);
	return(c);
}

/* Vector subroutines */
vector vadd(vector v,vector w)
{
	vector s;
	s.x = v.x + w.x; s.y = v.y + w.y; s.z = v.z + w.z;
	return(s);
}

vector vsub(vector v,vector w)
{
	vector s;
	s.x = v.x - w.x; s.y = v.y - w.y; s.z = v.z - w.z;
	return(s);
}

float vabs(vector v)
{
	return(sqrt(v.x*v.x + v.y*v.y + v.z*v.z));
}

/* Line subroutines */
float cot(float a)
{
	return(tan(PI/2-a));
}
	
/* Return x so line contains (x,y) */
float meetx(Circle circ,float y)
{
	float rots, x;

	rots = -circ.r;
	if(rots == 0.0 || rots == 1.0) return(INF);
	x = (y-circ.c.y)*cot(PI*rots) + circ.c.x; 
	return(x);
}

/* Return y so line contains (x,y) */
float meety(Circle circ,float x)
{
	float rots, y;

	rots = -circ.r;
	if(rots == 0.5) return(INF);
	y = (x-circ.c.x)*tan(PI*rots) + circ.c.y; 
	return(y);
}

/* Sphere subroutines */
vector complex_to_s2(CComplex z)
{
	vector v;
	float r;

	r = z.x*z.x + z.y*z.y;
	v.x = 2*z.x/(1+r);
	v.y = 2*z.y/(1+r);
	v.z = (1-r)/(1+r);
	return(v);
}

/* Convert Circle in plane to Circle on S^2 */
/* Method is to find a pair of opposite points on Circle */
/* Return norm vector; put radius in R^3 in r*/
vector circle_to_s2(Circle circ,float *r)
{
	float ac, s;
	CComplex w1, w2, c, cn;
	vector v, v1, v2;

//zorro	if(circ.r <= 0) return(line_to_s2(circ,r));

	c = circ.c; 
	s = circ.r;
	ac = cx_abs(c);
/* Circle centered at origin */
	if(ac == 0.0)
	{	v.x = v.y = 0; v.z = 1;
		if(s>1.0) v.z = -1;
		*r = 2*s/(1+s*s);
		return(v);
	}
/* Else find points closest and farthest from origin */
	cn.x = c.x/ac; cn.y = c.y/ac;
	w1.x = c.x+s*cn.x; w1.y = c.y+s*cn.y; 
	w2.x = c.x-s*cn.x; w2.y = c.y-s*cn.y; 

	v1 = complex_to_s2(w1);
	v2 = complex_to_s2(w2);
	v  = vadd(v1,v2);
	*r = vabs(vsub(v1,v2))/2;
/* Take care if we have a great Circle */
	if(vabs(v) < VEPS) {
		s = sqrt(v1.x*v1.x+v1.y*v1.y);
		v.x = -v1.x * v1.z / s;
		v.y = -v1.y * v1.z / s;
		v.z = s;
	}
	return(v);
}

/* Convert line in plane to Circle on S^2 */
vector line_to_s2(Circle circ,float *r)
{
	vector p, v;
	static vector north_pole = {0.0,0.0,-1.0};

	p = complex_to_s2(circ.c);
	if(p.x == 0.0 && p.y == 0.0) 
	{	v.x = cos(-PI*circ.r); 
		v.y = sin(-PI*circ.r);
		v.z = 0.0;
		*r  = 1.0;
	}
	else
	{	v  = vadd(p,north_pole);
		*r = vabs(vsub(p,north_pole))/2;
	}
	return(v);
}
