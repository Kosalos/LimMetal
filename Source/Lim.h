/* -------------------------------------------------------------
 Please visit: https://dhushara.com/DarkHeart/quasif/quasi.htm
 This app is based on the ideas presented in "Depth First C-script Listing in Colour".
 I have done many little things in the process of porting it to the iPad,
 but the credit belongs to the author of that code.
 --------------------------------------------------------------- */

#pragma once

#include "Circle.h"

#define MAXC  1000 // 300000  /* Circle stack */
#define MAXG  8      /* Generator stack */

typedef struct {
    int version;

    int depth;
    float eps;
    Matrix gens[MAXG];
    float xscale;
    float yscale;
    float ratio;

    float unused[12];
} Control;

typedef struct {
    int nfinal;
    Circle final[MAXC];
} FinalCircles;

#ifndef __METAL_VERSION__

void limReset(void);
void limGenerate(FinalCircles *fPtr);

void setControlPointer(Control *ptr);

void setActive(int index, int onoff);
int  getActive(int index);

float* AxPointer(int index);
float* AyPointer(int index);
float* BxPointer(int index);
float* ByPointer(int index);
float* CxPointer(int index);
float* CyPointer(int index);
float* DxPointer(int index);
float* DyPointer(int index);

#endif

