/* -------------------------------------------------------------
 Please visit: https://dhushara.com/DarkHeart/quasif/quasi.htm
 This app is based on the ideas presented in "Depth First C-script Listing in Colour".
 I have done many little things in the process of porting it to the iPad,
 but the credit belongs to the author of that code.
 --------------------------------------------------------------- */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "Lim.h"

Control *cPtr = NULL;

// ===================================================

void setControlPointer(Control *ptr) { cPtr = ptr; }

void setActive(int index, int onoff) { cPtr->gens[index].active = onoff; }
int  getActive(int index) { return cPtr->gens[index].active; }

float* AxPointer(index) { return &(cPtr->gens[index].a.x); }
float* AyPointer(index) { return &(cPtr->gens[index].a.y); }
float* BxPointer(index) { return &(cPtr->gens[index].b.x); }
float* ByPointer(index) { return &(cPtr->gens[index].b.y); }
float* CxPointer(index) { return &(cPtr->gens[index].c.x); }
float* CyPointer(index) { return &(cPtr->gens[index].c.y); }
float* DxPointer(index) { return &(cPtr->gens[index].d.x); }
float* DyPointer(index) { return &(cPtr->gens[index].d.y); }

// ===================================================

static int nstack;
static Circle stack[MAXC];

static float small;

void addGens(float v1,float v2,float v3,float v4,float v5,float v6,float v7,float v8) {
    int index;
    for(index=0;index < MAXC;++index) {
        if(!(cPtr->gens[index].active)) break;
    }
    if(index == MAXG) return;   // all filled
    
    cPtr->gens[index].a.x = v1;
    cPtr->gens[index].a.y = v2;
    cPtr->gens[index].b.x = v3;
    cPtr->gens[index].b.y = v4;
    cPtr->gens[index].c.x = v5;
    cPtr->gens[index].c.y = v6;
    cPtr->gens[index].d.x = v7;
    cPtr->gens[index].d.y = v8;
    
    cPtr->gens[index] = make_sl2(cPtr->gens[index]);
    cPtr->gens[index].active = 1;
}

/* Return code: 0) OK 1) too small or far 2) full */
int push_circle(Circle circ) {
    const float huge = 500.0;
    
    if(nstack == MAXC) return(2);
    if(circ.r < cPtr->eps && circ.r > 0) return(1);
    if(circ.r > huge || cx_abs(circ.c) > huge) return(1);
    
    stack[nstack++] = circ;
    return(0);
}

void pushUnitCircle() {
    nstack = 0;
    
    Circle cc;
    cc.c.x = 0;
    cc.c.y = 0;
    cc.r = 1;
    push_circle(cc);
}

void limReset() {
    for(int i=0;i<MAXG;++i) cPtr->gens[i].active = 0;
    cPtr->eps = 0.00325;
    cPtr->depth = 10;
    
    const float agree = 100.0; /* 1/AGREE to match circles */
    small = cPtr->eps / agree;
    
    pushUnitCircle();
    addGens(1,1, 0, 1, 0, -1, 1, -1);
    addGens(1,-1, 0, -1, 0, 1, 1, 1);
    addGens(0.955, -0.025,  0.045,  0.025, -1.955,  0.025, 0.955, -0.025);
    addGens(0.955, -0.025, -0.045, -0.025,  1.955, -0.025, 0.955, -0.025);
}

int compare_circles(const void *cc,const void *dd)
{
    Circle *c = (Circle *)cc;
    Circle *d = (Circle *)dd;

    float dr, dx, dy;
    
    /* Lines precede circles */
    if(c->r <= 0 && d->r > 0) return(-1);
    if(d->r <= 0 && c->r > 0) return(1);
    
    dx = c->c.x-d->c.x;
    if(dx < -small) return(-1);
    if(dx > small) return(1);
    
    dy = c->c.y-d->c.y;
    if(dy < -small) return(-1);
    if(dy > small) return(1);
    
    dr = c->r-d->r;
    if(dr < -small) return(-1);
    if(dr > small) return(1);
    return(0);
}

void sort_circles(Circle stack[],int nstack)
{
    size_t circle_bytes = sizeof(Circle);
    qsort(stack,nstack,circle_bytes,compare_circles);
}

/* Sort a list of circles and eliminate dups */

void unique_circles(Circle stack[],int *nstack)
{
    int i, n;
    
    if(*nstack<2) return;
    sort_circles(stack,*nstack);
    i=n=1;
    while(i<*nstack)
    {	if(0==compare_circles(&stack[i],&stack[i-1]))	i++;
    else {stack[n]=stack[i]; n++; i++;}
    }
    *nstack = n;
}

/* Move circles from stack to final, skipping dups */
/* Returns 1 if run out of room */
int merge_circles(FinalCircles *fPtr)
{
    int c, i, ifinal, istack, nold;
    
    unique_circles(stack,&nstack);
    if(nstack + fPtr->nfinal > MAXC) return(1);
    
    ifinal = istack = 0;
    nold = fPtr->nfinal;
    while(ifinal < nold && istack < nstack)
    {	c =compare_circles(&(fPtr->final[ifinal]),&stack[istack]);
        if(c<0) ifinal++;
        if(c==0) istack++;
        if(c>0)
        {	fPtr->final[fPtr->nfinal] = stack[istack];
            fPtr->nfinal++;
            istack++;
        }
    }
    while(istack < nstack) {
        fPtr->final[fPtr->nfinal] = stack[istack];
        fPtr->nfinal++;
        istack++;
    }
    for(i=nold; i< fPtr->nfinal; i++)
        stack[i-nold] = fPtr->final[i];
    
    nstack = fPtr->nfinal - nold;
    sort_circles(fPtr->final,fPtr->nfinal);
    return(0);
}

void evolve(Circle c)
{
    Circle d;
    
    for(int i=0; i < MAXG; ++i) {
        if(!cPtr->gens[i].active) continue;
        d = image_circle(cPtr->gens[i],c);
        push_circle(d);
    }
}

void limGenerate(FinalCircles *fPtr)
{
    int nevo;
    
    pushUnitCircle();

    /* Put original circles on final list */
    for(int i=0; i<nstack; ++i) fPtr->final[i] = stack[i];
    
    fPtr->nfinal = nstack;
    unique_circles(fPtr->final,&(fPtr->nfinal));
    
    for(int i=1; i <= cPtr->depth; i++) {
       if(nstack==0) break;

       nevo = nstack;
       
       int nold = nstack;
       for(int j=0; j < nold; ++j) {
           evolve(stack[j]);
       }
       
        if(merge_circles(fPtr)) {
            //fprintf(stderr,"Stack full\n");
            break;
        }
    }
}

