#include <metal_stdlib>
#include <simd/simd.h>
#include "Source/Lim.h"

using namespace metal;

void drawCircle
(
  float x,  // center
  float y,
  float rx, // X,Y radii (to counteract effect of stretching UIImageView)
  float ry,
  texture2d<float, access::write> dst)
{
    float angle = 0;
    float aHop = 0.003;
    float ss,cc,fx,fy,fdx,fdy;
    uint2 qq;
    
    if(rx < 50) aHop *= 10;
    
    for(;;) {
        
        ss = sin(angle) * rx;
        cc = cos(angle) * ry;
        
        for(int dx = -1;dx < 2; dx += 2) {          // do sin()/cos() for 1 quadrant, replicate coord for other quadrants
            fdx = float(dx);
            fx = x + ss * fdx;
            if(fx < 0 || fx >= 1024) continue;
            qq.x = uint(fx);

            for(int dy = -1;dy < 2; dy += 2) {
                fdy = float(dy);
                fy = y + cc * fdy;
                if(fy >= 0 && fy < 1024) {
                    qq.y = uint(fy);
                    dst.write(float4(1,1,1,1),qq);
                }
            }
        }
        
        angle += aHop;
        if(angle >= 1.57) break; // 1 quadrant of rotation
    }
}

kernel void drawCirclesShader
(
 texture2d<float, access::write> dst [[texture(0)]],
 constant FinalCircles &circles [[ buffer(0) ]],
 constant Control &control      [[ buffer(1) ]],
 uint p [[thread_position_in_grid]])
{
    if(int(p) >= circles.nfinal) return;
    
    Circle crc = circles.final[p];
    
    drawCircle(512 + crc.c.x * control.xscale,  // 512 = center of 1024x1024 image
               512 + crc.c.y * control.yscale,
               crc.r * control.xscale,
               crc.r * control.yscale,
               dst);
}
