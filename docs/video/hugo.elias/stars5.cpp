// Swirlstars:      Design: Matt Fairclough
//             Dos Version: Hugo Elias			1998


#define NonInt float
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream.h>
#include <fstream.h>
#include <dos.h>
#include <i86.h>
#include <math.h>
#include "d:\watcom\h\general\fixpt.h"
#include <pmode.h>

#define PALETTE_MASK 0x3c6
#define PALETTE_REGISTER_RD 0x3c7
#define PALETTE_REGISTER_WR 968
#define PALETTE_DATA 969
#define SCREEN_LINEAR 0xA0000

#define Field_MinX	-320.f
#define Field_MaxX	 320.f
#define Field_Wid	(Field_MaxX - Field_MinX)
#define Field_MinY	-320.f
#define Field_MaxY	 320.f
#define Field_Hei	(Field_MaxY - Field_MinY)
#define Field_MinZ	-128.f
#define Field_MaxZ	 640.f
#define Field_Len	(Field_MaxZ - Field_MinZ)

int ScrWid = 640, ScrHei=480;
int ScrMidX= 320, ScrMidY=240;

float ScrZoom;

int DataOut=0;
int NumStars=1000;
float MaxVelocity = 20.f;
float Velocity = 0.f;
float FieldExpanse = 1.5f;
float Brightness = 0.2f;
float Zoom = (3.f/2.f);

float GammaValue;

struct STAR
{
	float v;
	float x,y,z;
	float rx,ry,rz;
	float sx,sy;
	float osx,osy;
	char plot,oplot;
}Star[4096];

struct ROTATION
{
	float a,b,c;
	float avel,bvel,cvel;
	float aacc,bacc,cacc;
} Cam;

float BrightTable[256];

#define RangeRand(min,range) (min + (float)rand()/(float)RAND_MAX*range)

char *screen;     	// bytes
unsigned char offscreen[640*480];

void copymem(long src, long dest, long numchars);
#pragma aux copymem=\
"                  "\
"shr ecx,2         "\
"cld					 "\
"rep movsd         "\
"                  "\
parm caller [esi] [edi] [ecx]\
modify [esi edi ecx];

void setmem(long dest, long numbytes, long value);
#pragma aux setmem=\
"mov ah, al        "\
"shl eax, 8        "\
"mov al, ah        "\
"shl eax, 8        "\
"mov al, ah        "\
"                  "\
"shr ecx,2         "\
"cld					 "\
"rep stosd         "\
"                  "\
parm caller [edi] [ecx] [eax]\
modify [esi edi ecx eax];

#include "d:\watcom\h\graphics\trueboge.cpp"

#define VGA_STATUS 0x3DA
//bit 3=1 => retrace in progress
#define VGA_VSYNC_MASK 8

void waitvsync()
{
while(inp(VGA_STATUS) & VGA_VSYNC_MASK)
  ;        //wait for end of current retrace
while( !(inp(VGA_STATUS) & VGA_VSYNC_MASK))
  ;        //wait for end of drawing period
}

float max(float a, float b)
{if (a>b) return a; else return b;}

float min(float a, float b)
{if (a<b) return a; else return b;}

int max(int a, int b)
{if (a>b) return a; else return b;}

int min(int a, int b)
{if (a<b) return a; else return b;}

inline plot(int x,int y,char col)
{
 if ((x>-1) && (x<320) && (y>-1) && (y<200))
	 screen[x+(y<<8)+(y<<6)] = col;
}


// Unclipped pixel plotter
inline plot640(int x,int y,unsigned char col)
{
	 offscreen[x+(y<<9)+(y<<7)] = col;
}


char GammaCorrect(unsigned char c, float g)
{
	return (char)(pow(((float)c)/255., 1./g)*255.);
}

void setpalette(int index,int red,int green,int blue)
{
	outp(PALETTE_REGISTER_WR,index);
	outp(PALETTE_DATA,red);
	outp(PALETTE_DATA,green);
	outp(PALETTE_DATA,blue);
}

void setvidmode(char mode)
{
 union REGS inregs,outregs;

 inregs.h.ah=0;
 inregs.h.al=mode;
 int386(0x10,&inregs,&outregs);
}


// Antialiased line drawing
void WuLine(fixpt ox1, fixpt oy1, fixpt ox2, fixpt oy2, int Bright)
{
	fixpt grad, xd, yd, length,xm,ym;
	fixpt x1, y1, x2, y2;
	fixpt xgap, ygap, xend, yend, xf, yf;
	fixpt xgapL, xgapR;
	fixpt ygapT, ygapB;
	fixpt s1,s2;

	int x, y, ix1, ix2, iy1, iy2;

	unsigned char c1,c2;


	xd = (ox2-ox1);
	yd = (oy2-oy1);

	// check line gradient
	if (abs(xd) > abs(yd))
	{
	// horizontal(ish) lines

		// if line is back to front
		if (ox2<ox1)
		{
			// then swap
			x1=ox2; y1=oy2;
			x2=ox1; y2=oy1;
			xd = (x2-x1);
			yd = (y2-y1);
		}
		else
		{
			// otherwise don't swap
			x1=ox1; y1=oy1;
			x2=ox2; y2=oy2;
			xd = (x2-x1);
			yd = (y2-y1);
		}

		// Treat very short lines as unit length, horizontal.
		if (abs(xd) < (fixpt).1)
		{
			x2 = x1+(fixpt).5;
			x1-= (fixpt).5;
			grad=0;
		}
		else
		{
			grad = yd/xd;

			// if line length is less than 1, lengthen it to 1
			if (xd < (fixpt)1)
			{
				// find mid point of line
				xm = (x1+x2) >> 1;
				ym = (y1+y2) >> 1;

				//recalculate end points so that xd=1
				x1 = xm - (fixpt).5;
				x2 = xm + (fixpt).5;
				y1 = ym - (grad>>1);
				y2 = ym + (grad>>1);

				xd = (fixpt)1;
				yd = grad;

			}
		}
		// End Point 1
		// -----------

		// project to find coordinates of end point 1
		xend = trunc(x1+(fixpt).5);
		yend = y1 + grad*(xend-x1);


		// distance from begining of line to next pixel boundary
		xgap = invfracof(x1+(fixpt).5);


		// calc pixel coordinates for the top of the pixel pair
		ix1  = int(xend);
		iy1  = int(yend);
		// calc pixel intensities
		s1   = invfracof(yend) * xgap;
		s2   =    fracof(yend) * xgap;

		// plot pixel pair
		c1   = char((s1.x*Bright)>>16);
		c2   = char((s2.x*Bright)>>16);
		plot640(ix1,iy1, c1);
		plot640(ix1,iy1+1, c2);


		ix1++;
		yf = yend+grad;

		// End Point 2
		// -----------

		// project to find coordinates of end point 2
		xend = trunc(x2+(fixpt).5);
		yend = y2 + grad*(xend-x2);

		// distance from end of line to previous pixel boundary
		xgap = fracof(x2-(fixpt).5);

		// calc pixel coordinates for the top of the pixel pair
		ix2 = int(xend);
		iy2 = int(yend);

		// calc pixel intensities
		s1   = invfracof(yend) * xgap;
		s2   =    fracof(yend) * xgap;

		// plot pixel pair
		c1   = char((s1.x*Bright)>>16);
		c2   = char((s2.x*Bright)>>16);
		plot640(ix2,iy2, c1);
		plot640(ix2,iy2+1, c2);


		// MAIN LOOP
		for(x=ix1; x<ix2; x++)
		{
			c2 =  (unsigned char)(((yf.x & 0xffff)*Bright)>>16);
			c1 = ((unsigned char)Bright-c2);

			plot640(x, int(yf), c1);
			plot640(x, int(yf)+1, c2);
			yf += grad;
		}

	}
	else
	{
	// vertical(ish) lines
		// if line is back to front
		if (oy2<oy1)
		{
			// then swap
			x1=ox2; y1=oy2;
			x2=ox1; y2=oy1;
			xd = (x2-x1);
			yd = (y2-y1);
		}
		else
		{
			// otherwise don't swap
			x1=ox1; y1=oy1;
			x2=ox2; y2=oy2;
			xd = (x2-x1);
			yd = (y2-y1);
		}

		// Treat very short lines as unit length, horizontal.
		if (abs(yd) < (fixpt).1)
		{
			y2 = y1+(fixpt).5;
			y1-= (fixpt).5;
			grad=0;
		}
		else
		{
			grad = xd/yd;

			// if line length is less than 1, lengthen it to 1
			if (yd < (fixpt)1)
			{
				// find mid point of line
				xm = (x1+x2) >> 1;
				ym = (y1+y2) >> 1;

				// recalculate end points so that xd=1
				x1 = xm - (grad>>1);
				x2 = xm + (grad>>1);
				y1 = ym - (fixpt).5;
				y2 = ym + (fixpt).5;

				yd = (fixpt)1;
				xd = grad;
			}
		}

		// End Point 1
		// -----------

		// project to find coordinates of end point 1
		yend = trunc(y1+(fixpt).5);
		xend = x1 + grad*(yend-y1);

		// distance from begining of line to next pixel boundary
		ygap = invfracof(y1+(fixpt).5);


		// calc pixel coordinates for the top of the pixel pair
		ix1  = int(xend);
		iy1  = int(yend);
		// calc pixel intensities
		s1   = invfracof(xend);
		s2   =    fracof(xend);

		s1 *= ygap;
		s2 *= ygap;

		// plot pixel pair
		c1   = char((s1.x*Bright)>>16);
		c2   = char((s2.x*Bright)>>16);
		plot640(ix1,iy1, c1);
		plot640(ix1+1,iy1, c2);


		iy1++;
		xf = xend+grad;

		// End Point 2
		// -----------

		// project to find coordinates of end point 2
		yend = trunc(y2+(fixpt).5);
		xend = x2 + grad*(yend-y2);

		// distance from end of line to previous pixel boundary
		ygap = fracof(y2-(fixpt).5);

		// calc pixel coordinates for the top of the pixel pair
		ix2 = int(xend);
		iy2 = int(yend);

		// calc pixel intensities
		s1   = invfracof(xend);
		s2   =    fracof(xend);
		s1 *= ygap;
		s2 *= ygap;

		// plot pixel pair
		c1   = char((s1.x*Bright)>>16);
		c2   = char((s2.x*Bright)>>16);
		plot640(ix2,iy2, c1);
		plot640(ix2+1,iy2, c2);


		// MAIN LOOP
		for(y=iy1; y<iy2; y++)
		{
			c2 =  (unsigned char)(((xf.x & 0xffff)*Bright)>>16);
			c1 = ((unsigned char)Bright-c2);

			plot640(int(xf), y, c1);
			plot640(int(xf)+1, y, c2);
			xf += grad;
		}
	}
}

// Cut down version of the WuLine procedure just for erasing them
void EraseWuLine(fixpt ox1, fixpt oy1, fixpt ox2, fixpt oy2)
{
	fixpt grad, xd, yd, length,xm,ym;
	fixpt x1, y1, x2, y2;
	fixpt xgap, ygap, xend, yend, xf, yf;
	fixpt xgapL, xgapR;
	fixpt ygapT, ygapB;
	fixpt s1,s2;

	int x, y, ix1, ix2, iy1, iy2;


	xd = (ox2-ox1);
	yd = (oy2-oy1);

	// check line gradient
	if (abs(xd) > abs(yd))
	{
	// horizontal(ish) lines

		// if line is back to front
		if (ox2<ox1)
		{
			// then swap
			x1=ox2; y1=oy2;
			x2=ox1; y2=oy1;
			xd = (x2-x1);
			yd = (y2-y1);
		}
		else
		{
			// otherwise don't swap
			x1=ox1; y1=oy1;
			x2=ox2; y2=oy2;
			xd = (x2-x1);
			yd = (y2-y1);
		}

		if (abs(xd) < (fixpt).1)
		{
			x2 = x1+(fixpt).5;
			x1-= (fixpt).5;
			grad=0;
		}
		else
		{
			grad = yd/xd;

			// if line is very short, lengthen it to 1
			if (xd < (fixpt)1)
			{
				// find mid point of line
				xm = (x1+x2) >> 1;
				ym = (y1+y2) >> 1;

				//recalculate end points so that xd=1
				x1 = xm - (fixpt).5;
				x2 = xm + (fixpt).5;
				y1 = ym - (grad>>1);
				y2 = ym + (grad>>1);

				xd = (fixpt)1;
				yd = grad;

			}
		}
		// End Point 1
		// -----------

		// project to find coordinates of end point 1
		xend = trunc(x1+(fixpt).5);
		yend = y1 + grad*(xend-x1);

		ix1 = int(xend);
		iy1 = int(yend);

		plot640(ix1,iy1, 0);
		plot640(ix1,iy1+1, 0);


		ix1++;
		yf = yend+grad;

		// End Point 2
		// -----------

		// project to find coordinates of end point 2
		xend = trunc(x2+(fixpt).5);
		yend = y2 + grad*(xend-x2);
		ix2 = int(xend);
		iy2 = int(yend);
		plot640(ix2,iy2, 0);
		plot640(ix2,iy2+1, 0);


		// MAIN LOOP
		for(x=ix1; x<ix2; x++)
		{
			plot640(x, int(yf), 0);
			plot640(x, int(yf)+1, 0);
			yf += grad;
		}

	}
	else
	{
	// vertical(ish) lines
		// if line is back to front
		if (oy2<oy1)
		{
			// then swap
			x1=ox2; y1=oy2;
			x2=ox1; y2=oy1;
			xd = (x2-x1);
			yd = (y2-y1);
		}
		else
		{
			// otherwise don't swap
			x1=ox1; y1=oy1;
			x2=ox2; y2=oy2;
			xd = (x2-x1);
			yd = (y2-y1);
		}

		if (abs(yd) < (fixpt).1)
		{
			y2 = y1+(fixpt).5;
			y1-= (fixpt).5;
			grad=0;
		}
		else
		{
			grad = xd/yd;

			// if line is very short, lengthen it to 1
			if (yd < (fixpt)1)
			{
				// find mid point of line
				xm = (x1+x2) >> 1;
				ym = (y1+y2) >> 1;

				// recalculate end points so that xd=1
				x1 = xm - (grad>>1);
				x2 = xm + (grad>>1);
				y1 = ym - (fixpt).5;
				y2 = ym + (fixpt).5;

				yd = (fixpt)1;
				xd = grad;
			}
		}

		// End Point 1
		// -----------

		// project to find coordinates of end point 1
		yend = trunc(y1+(fixpt).5);
		xend = x1 + grad*(yend-y1);
		ix1 = int(xend);
		iy1 = int(yend);

		plot640(ix1,iy1, 0);
		plot640(ix1+1,iy1, 0);

		iy1++;
		xf = xend+grad;

		// End Point 2
		// -----------

		// project to find coordinates of end point 2
		yend = trunc(y2+(fixpt).5);
		xend = x2 + grad*(yend-y2);

		ix2 = int(xend);
		iy2 = int(yend);
		plot640(ix2,iy2, 0);
		plot640(ix2+1,iy2, 0);


		// MAIN LOOP
		for(y=iy1; y<iy2; y++)
		{
			plot640(int(xf), y, 0);
			plot640(int(xf)+1, y, 0);
			xf += grad;
		}
	}

}

int setting[3]={1024, 10, 4};

//Give you those two squares to allow you to set the Gamma correctly
void AdjustGamma()
{
	int x,y,exiting=0,i;
	char k;
	unsigned char c;


	for (i=1; i<256; i++)
		setpalette(i,i>>2,i>>2,i>>2);


	while (exiting == 0)
	{
		c = GammaCorrect(127, GammaValue);

		for (y=0; y<256; y++)
			for (x=(y&1); x<256; x+=2)
				offscreen[y*640+x + 192] = (unsigned char)0xff;

		for (y=0; y<64; y++)
			for (x=0; x<64; x++)
				offscreen[y*640+x + 640*96 +288] = c;

		offscreen[(int)(GammaValue * 128) +640*257 + 192] = (unsigned char)255;
		offscreen[(int)(GammaValue * 128) +640*258 + 192] = (unsigned char)255;
		offscreen[(int)(GammaValue * 128) +640*259 + 192] = (unsigned char)255;
		offscreen[(int)(GammaValue * 128) +640*260 + 192] = (unsigned char)255;

		BlitScreen(640*260, 640*60);

		offscreen[(int)(GammaValue * 128) +640*257 + 192] = 0;
		offscreen[(int)(GammaValue * 128) +640*258 + 192] = 0;
		offscreen[(int)(GammaValue * 128) +640*259 + 192] = 0;
		offscreen[(int)(GammaValue * 128) +640*260 + 192] = 0;

		k = getch();

		switch (k)
		{
			case 'H':
				GammaValue += .02;
			break;

			case 'P':
				GammaValue -= .02;
			break;

			case 13:
				exiting = 1;
			break;
		}
	}
}


void ResetStar(STAR* pstar)
{
	pstar->v = 1.f / (float)pow(.1f + 9.9f*(float)rand()/(float)RAND_MAX, FieldExpanse);// * 16.f;
	pstar->x = RangeRand(Field_MinX,Field_Wid);
	pstar->y = RangeRand(Field_MinY,Field_Hei);
	pstar->z = Field_MaxZ;
	pstar->plot = 0;
}


void Swrl_Init()
{
	int i = 0, dist;
	float c;
	double br;

	for (dist = 0; dist < 256; dist ++)
	{
		br = pow(256/(double)max(dist,1),2) - pow(256/255. , 2);
		if (br<0.) br=0.;
		br = pow( 1. - pow((1.-Brightness),br) , .66);
		c = br*255.;
		BrightTable[i] = c;
		i ++;
	}

	for (int s = 0; s < NumStars; s ++)
	{
		ResetStar(&Star[s]);
		Star[s].z = RangeRand(Field_MinZ,Field_Len);
	}
}


	float sina;
	float cosa;
	float sinb;
	float cosb;
	float sinc;
	float cosc;

	float c;
	float nsx,nsy;


void Swrl_DoFrame()
{
	ScrZoom = ScrMidX * Zoom;

	Velocity += (MaxVelocity-Velocity)*.01f;

	Cam.aacc = (Cam.aacc + RangeRand(-.00001f,.00002f)) * .99f;
	Cam.bacc = (Cam.bacc + RangeRand(-.00001f,.00002f)) * .99f;
	Cam.cacc = (Cam.cacc + RangeRand(-.00001f,.00002f)) * .992f;
	Cam.avel = (Cam.avel + Cam.aacc) * .99f;
	Cam.bvel = (Cam.bvel + Cam.bacc) * .99f;
	Cam.cvel = (Cam.cvel + Cam.cacc) * .992f;
	Cam.a = (Cam.a + Cam.avel) * .99f;
	Cam.b = (Cam.b + Cam.bvel) * .99f;
	Cam.c = (Cam.c + Cam.cvel) * .992f;

	sina = (float)sin(-Cam.a);
	cosa = (float)cos(-Cam.a);
	sinb = (float)sin(-Cam.b);
	cosb = (float)cos(-Cam.b);
	sinc = (float)sin(-Cam.c);
	cosc = (float)cos(-Cam.c);

	STAR* pstar;

	for (int s = 0; s < NumStars; s ++)
	{
		pstar = &Star[s];
	//move star
		pstar->z -= pstar->v*Velocity;
		if (pstar->z < Field_MinZ) ResetStar(pstar);
	//rotate star
	//rotate wrt a
		pstar->rx = pstar->x*cosa + pstar->z*sina;
		pstar->rz = pstar->z*cosa - pstar->x*sina;
	//rotate wrt b
		pstar->ry = pstar->y*cosb + pstar->rz*sinb;
		pstar->rz = pstar->rz*cosb - pstar->y*sinb;
	//rotate wrt c
		float temprx = pstar->rx*cosc + pstar->ry*sinc;
		pstar->ry = pstar->ry*cosc - pstar->rx*sinc;
		pstar->rx = temprx;
	//prepare to plot
		nsx = (float)ScrMidX + pstar->rx/pstar->rz*ScrZoom;
		nsy = (float)ScrMidY - pstar->ry/pstar->rz*ScrZoom;

		//if (int(nsx)==int(pstar->sx) && int(nsy)==int(pstar->sy)) nsx++;

		int dist = (int)pstar->rz;

		float xd = nsx-pstar->sx;
		float yd = nsy-pstar->sy;

		float len = sqrt(xd*xd+yd*yd);
		//max(abs((int)nsx-(int)pstar->sx),abs((int)nsy-(int)pstar->sy));

		c = BrightTable[min(dist>>1,255)];
		//c = min(dist>>1,255);

		if (len>2)
			c /= (len*.5);

		// + (min(/*(int)sqrt*/(len),255)<<8)];

	//erase star
		if (pstar->oplot)
		{
			if ((pstar->sx>2) && (pstar->sx<640) && (pstar->sy>2) && (pstar->sy<478) &&
				 (pstar->osx>2) && (pstar->osx<640) && (pstar->osy>2) && (pstar->osy<478))
				EraseWuLine((fixpt)pstar->osx, (fixpt)pstar->osy, (fixpt)pstar->sx, (fixpt)pstar->sy);

		}
		pstar->osx=pstar->sx; pstar->osy=pstar->sy;
	//plot star
		if (pstar->rz>1.f)
		{
			if (pstar->plot)
			{
				if ((pstar->sx>2) && (pstar->sx<640) && (pstar->sy>2) && (pstar->sy<478) &&
					 (nsx>2) && (nsx<640) && (nsy>2) && (nsy<478))
					WuLine((fixpt)pstar->sx, (fixpt)pstar->sy, (fixpt)nsx, (fixpt)nsy, c);
			}
			pstar->oplot = pstar->plot;
			pstar->sx = nsx; pstar->sy = nsy;
			pstar->plot = 1;
		}
	}
}

unsigned char* TextScreen=(unsigned char*)0xB8000;

void WriteText(char text[], int x, int y, char fore, char back)
{
	int p=(y*80+x)<<1;
	char colour = fore + (back<<4);
	char t=0;


	while (text[t] != 0)
	{
		TextScreen[p] = text[t];
		TextScreen[p+1] = colour;

		p+=2;
		t++;
	}
}

void EndScreen()
{
	int i;

	setpalette(7,0,0,0);

	for (i=0; i<23; i++)
		cout << endl;

	if (rand()>=16384)
	{
		WriteText("http://freespace.virgin.net/hugo.elias/", 5, 10,7,0);
		WriteText("http://planetside.base.org/",             5, 12,7,0);
	}
	else
	{
		WriteText("http://freespace.virgin.net/hugo.elias/", 5, 12,7,0);
		WriteText("http://planetside.base.org/",             5, 10,7,0);
	}

	for(i=0; i<70; i++)
		waitvsync();

	for(i=0; i<40; i++)
	{
		waitvsync();
		setpalette(7,i,i,i);
	}

	exit(0);
}



int InitScreen()
{
	int Entered=0, i, option=0;

	int steps[3] = {  16,   1,  1};
	int   min[3] = {  16,   1,  1};
	int   max[3] = {8192, 100, 20};

	char k;
	char box[9];
	float f;


	outp(0x60, (char)0xF3);

	box[8] = 0;

	setvidmode(0x03);
	setpalette(3,63,63,63);
	setpalette(2, 0, 0,20);

	WriteText("                               SwirlStars for DOS                               ", 0, 0,7,1);

	WriteText("  This is a DOS version of Matt Fairclough's SwirlStars screensaver for   ", 0, 3,7,0);
	WriteText("Windows. It has been enhanced a bit with antialiasing and motion blur.    ", 0, 4,7,0);
	WriteText("  It was written to illustrate the making of a good starfield, for my web site:", 0, 5,7,0);
	WriteText("site: The Good Looking Textured Light Sourced Bouncy Fun Smart And Stretchy Page", 0, 6,7,0);

	WriteText(" Number of Stars:                                                         ", 0,10,7,0);
	WriteText(" Velocity:                                                                ", 0,11,7,0);
	WriteText(" Brightness:                                                              ", 0,12,7,0);

	WriteText(" Important:                               ",17,16,3,2);
	WriteText("   On the next screen you must set        ",17,17,7,2);
	WriteText(" the Gamma value for your monitor.        ",17,18,7,2);
	WriteText("   Use the Up / Down arrow keys until the ",17,19,7,2);
	WriteText(" two squares are the same brightness.     ",17,20,7,2);

	for (option=0; option<3; option++)
	{
		sprintf(box, "[%d] ", setting[option]);
		WriteText(box, 18,10+option,7,0);
	}

	option=0;

	sprintf(box, "[%d] ", setting[option]);
	WriteText(box, 18,10+option,15,1);

	outp(0x60, (char)0x0);

	while (!Entered)
	{
		k = getch();

		WriteText(box, 18,10+option,7,0);

		switch (k)
		{
			case 'H':   // up
				if (option>0) option--;
			break;

			case 'P':   // down
				if (option<2) option++;
			break;

			case 'M':   // inc
				setting[option] += steps[option];

				if (setting[option]>max[option])
					setting[option] = max[option];
			break;

			case 'K':   // dec
				setting[option] -= steps[option];

				if (setting[option]<min[option])
					setting[option] = min[option];
			break;

			case 13:

				Entered=1;
			break;

			case 27:
				for (i=63; i>0; i--)
				{
					f = (float)i / 63.;

					waitvsync();
					setpalette(2,0,0,char(20.*f));
					setpalette(3,char(63.*f),char(63.*f),char(63.*f));
					setpalette(7,char(40.*f),char(40.*f),char(40.*f));
					setpalette(1,0,0,char(40.*f));
					setpalette(4,char(40.*f),0,0);
				}
				setvidmode(0x03);
				//setmem(0xb8000, 80*25*2,0);

				EndScreen();
				return 1;
		}

		sprintf(box, "[%d] ", setting[option]);
		WriteText(box, 18,10+option,15,1);
	}
	NumStars    =        setting[0];
	MaxVelocity = (float)setting[1];
	Brightness  = (float)setting[2]/20.;
	cout << NumStars << endl;
	cout << MaxVelocity << endl;
	cout << Brightness << endl;

	return 0;
}


void main()
{
	int exiting,k,i;
	char c;

	// Load the last settings you chose
	ifstream IFile;
	IFile.open("gamma.dat", ios::in | ios::binary);
	if (!IFile)
		GammaValue = 1.;
	else
	{
		IFile.read((char*)(&GammaValue), 4);
		IFile.read((char*)(setting), 4*3);
		IFile.close();
	}

	InitScreen();

	SetSVGA(0x101);

	Swrl_Init();

	AdjustGamma();

	// Save the settings for next time
	ofstream OFile;
	OFile.open("gamma.dat", ios::out | ios::binary);
	OFile.write( (char*)(&GammaValue), 4);
	OFile.write( (char*)(setting), 4*3);
	OFile.close();

	setmem((long)offscreen,640*480,0);

	for (i=1; i<256; i++)
	{
		c=GammaCorrect(i,GammaValue) >> 2;
		setpalette(i,c,c,c);
	}

	exiting=0;

	while (exiting!=1)
	{

		if (exiting)
		{
			for (i=1; i<256; i++)
			{
				c=GammaCorrect(i,GammaValue)*exiting >> 8;
				setpalette(i,c,c,c);
			}
			exiting--;
		}

		if (kbhit())
		{
			k=getch();

			switch(k)
			{
				case 'H':
					GammaValue += .05;
					for (i=1; i<256; i++)
					{
						c=GammaCorrect(i,GammaValue) >> 2;
						setpalette(i,c,c,c);
					}
				break;

				case 'P':
					GammaValue -= .05;
					for (i=1; i<256; i++)
					{
						c=GammaCorrect(i,GammaValue) >> 2;
						setpalette(i,c,c,c);
					}
				break;

				case 27:
					exiting=63;
				break;

				case ' ':
					OFile.open("stars5.raw", ios::out | ios::binary);
					OFile.write( (char*)(offscreen), 640*480);
					OFile.close();
				break;
			}
		}
		Swrl_DoFrame();
		BlitScreen(640*480,0);
	}
	for (i=1; i<256; i++)
		setpalette(i,0,0,0);

	ClearVidMem(5);
	//setvidmode(0x13);
	setvidmode(0x03);
	EndScreen();
}