 (* This file holds all the BITBLT, Line draw, HW cursor and clock
    functions *)

  {Wait for WD engine ready}
procedure WD_wait;
begin
  if cv.version=WD_90c33 then
    repeat until (inp($23CE) and 15)=0
  else begin  {c31,c24}
    outpw($23C0,$1001);
    repeat until (inpw($23C2) and $800)=0;
  end;
end;

procedure WD_outl(index:word;l:longint);
begin
  outpw($23C2,index+(l and $FFF));
  outpw($23C2,index+$1000+(l shr 12));
end;

procedure setHWcurmap(VAR map:CursorType);
var x,y,z,w,lbank,x0,y0:word;
  l,curadr:longint;
  bm:array[0..127] of byte;
  mp:record
       case integer of
	0:(b:array[0..2047] of byte);
	1:(w:array[0..1023] of word);
	2:(l:array[0..511] of longint);
     end;

procedure copyCurMap(bytes:word);
var x,y:word;
   l:longint;
begin
  l:=curadr;
  if memmode=_PL4 then l:=l shr 2;
  setbank(l shr 16);
  if memmode=_PL4 then
  begin
    wrinx(GRC,3,0);
    clrinx(GRC,5,$3);
    wrinx(GRC,8,$FF);
    for x:=0 to bytes-1 do
    begin
      wrinx(SEQ,2,1 shl (x and 3));
      y0:=mem[SegA000:l];
      mem[SegA000:l]:=mp.b[x];
      if (x and 3)=3 then inc(l);
    end;
  end
  else move(mp,mem[SegA000:l],bytes);
end;

function al_packmap(map:byte):word;
var i,j:word;
begin
  j:=0;
  for i:=0 to 7 do
  begin
    j:=j shl 2+2;
    if ((map shr i) and 1)>0 then dec(j);
  end;
  al_packmap:=j;
end;

function al_packmap2(map:byte):longint;
var i:word;
    j:longint;
begin
  j:=0;
  for i:=0 to 7 do
  begin
    j:=j shl 4+$A;
    if ((map shr i) and 1)>0 then dec(j,5);
  end;
  al_packmap2:=j;
end;

function pack8to16(w:word):word;
var x,i:word;
begin
  i:=0;
  for x:=0 to 7 do
  begin
    i:=i shl 2;
    if ((w shl x) and 128)>0 then inc(i,3);
  end;
  pack8to16:=i;
end;

function swapb(b:word):word;
var i,j:word;
begin
  j:=0;
  for i:=0 to 7 do
    if ((b shr i) and 1)>0 then inc(j,128 shr i);
  swapb:=j;
end;

function swapl(l:longint):longint;
var
  x,y:array[0..3] of byte;
begin
  swapl:=(l and $FF0000FF)+((l shl 8) and $FF0000)
        +((l shr 8) and $FF00)
end;

begin
  curadr:=cv.mm*longint(1024)-2048;
 { if memmode=_pl4 then curadr:=curadr shr 2;}

  move(map,mp,128);
  move(map,bm,128);
  if dacHWcursor then
    case cv.dactype of
    _dacBT484,_dacBt485:
        begin
          outp(setDACpage(dacSTDwrInx),$80);
          for x:=0 to 127 do outp(setDACpage(dacBTcMap),not mp.b[x]);
          outp(setDACpage(dacSTDwrInx),0);
          for x:=0 to 127 do outp(setDACpage(dacBTcMap),mp.b[x]);
          modreg(setDACpage(dacBTcmd2),3,2);
        end;
    _dacTVP3010,_dacTVP3020,_dacTVP3025:
        begin
          fillchar(mp,1024,$AA);
          y:=124;
          for x:=127 downto 0 do  {repack from 32x32x1 to 64x64x2 map}
          begin
            mp.w[y+x]:=swap(pack8to16(bm[x])) or $AAAA;
            if (x and 3)=0 then dec(y,4);
          end;

          wrDACreg(dacTVPindex,6);
          modDACreg(dacTVPdata,$C0,$40);   {TVP302x mode & MS-Win cursor}
          wrDACreg(dacTVPindex,8);
          wrDACreg(dacTVPdata,0);
          wrDACreg(dacTVPindex,9);
          wrDACreg(dacTVPdata,0);
          wrDACreg(dacTVPindex,$A);  {Select Cursor RAm index}
          for x:=0 to $3FF do wrDACreg(dacTVPdata,mp.b[x]);
          wrDACreg(dacTVPindex,4);
          wrDACreg(dacTVPdata,0);
          wrDACreg(dacTVPindex,5);
          wrDACreg(dacTVPdata,0);
        end;
    _dacTVP3026:
        begin
          fillchar(mp,1024,$AA);
          y:=124;
          for x:=127 downto 0 do  {repack from 32x32x1 to 64x64x2 map}
          begin
            mp.w[y+x]:=swap(pack8to16(bm[x])) or $AAAA;
            if (x and 3)=0 then dec(y,4);
          end;

          wrDACreg(dacTVP6index,6);
          modDACreg(dacTVP6data,$C0,$40);   {TVP302x mode & MS-Win cursor}
          wrDACreg(dacTVP6index,8);
          wrDACreg(dacTVP6data,0);
          wrDACreg(dacTVP6index,9);
          wrDACreg(dacTVP6data,0);
          wrDACreg(dacTVP6index,$A);  {Select Cursor RAm index}
          for x:=0 to $3FF do wrDACreg(dacTVP6data,mp.b[x]);
          wrDACreg(dacTVP6index,4);
          wrDACreg(dacTVP6data,0);
          wrDACreg(dacTVP6index,5);
          wrDACreg(dacTVP6data,0);
        end;
    end
  else
    case cv.chip of
	 __AGX:begin
		 wrinx(cv.IOadr+10,$36,0);
		 wrinx(cv.IOadr+10,$32,32);
		 wrinx(cv.IOadr+10,$35,32);
		 x:=((cv.mm shr 1)-1) xor $1DF;
		 wrinx(cv.IOadr+10,$6E,x);
		 modinx(cv.IOadr+10,$6F,3,hi(x));
		 wrinx2(cv.IOadr+10,$60,512);
		 y:=128;
		 for x:=127 downto 0 do
		 begin
		   mp.w[x+y]:=pack8to16(swapb(bm[x])) xor $AAAA;
		   if (x and 3)=0 then dec(y,4);
		 end;
		 for x:=0 to 511 do wrinx(cv.IOadr+10,$6A,mp.b[x]);
		 wrinx(cv.IOadr+10,$36,1);
	       end;
	 __ALG:begin
		 x0:=0;
		 fillchar(mp,1024,$AA);
		 if memmode<=_p8 then
		 begin
		   y:=0;
		   for x:=0 to 127 do
		   begin
		     mp.w[y+x]:=al_packmap(bm[x]);
		     if (x and 3)=3 then inc(y,4);
		   end;
		 end
		 else
		   for x:=0 to 127 do  {Double size for 64k mode}
		     mp.l[x]:=al_packmap2(bm[x]);
                 curadr:=(cv.mm-1)*longint(1024);
		 CopyCurMap(1024);
                 w:=cv.mm-1{curadr shr 10};
		 if cv.version=ALG_2101 then
		 begin
		   wrinx2(crtc,$27,w);
		 end
		 else begin
		   outpw($82C8,w);
		 end;
		 x:=inp(crtc+6);     {force ATTR to address mode}
		 x:=inp($3C0);
		 y:=rdinx($3C0,$31);    {Must preserve index 11h and 12h}
		 z:=rdinx($3C0,$32);
		 wrinx($3C0,$35,$FF);   {Foreground index #}
		 wrinx($3C0,$36,0);
		 wrinx($3C0,$31,y);
		 wrinx($3C0,$32,z);
		 outp($3C0,x);
	       end;
        __Alli:begin
                 curadr:=2048;
                 for x:=0 to 255 do mp.l[x]:=$55AAFF;
                 CopyCurMap(1024);
                 if mem[SegA000:$D8]=0 then;
                 outpw(SEQ,$1210);
                 setinx(SEQ,$1C,8);
                 modinx(SEQ,$1B,15,1);

                 memw[SegA000:$7944]:=curadr shr 10;
                 memw[SegA000:$794C]:=$2020;
                 mem [SegA000:$7940]:=1;

                 clrinx(SEQ,$1B,7);
                 clrinx(SEQ,$1C,8);
               end;
         __ARK:begin         {Doesn't work yet}
                 curadr:=cv.mm*longint(1024)-256;
                 for x:=0 to 127 do mp.w[x]:=(bm[x]*$101) xor $FF;
                 CopyCurMap(256);
                 case colbits[memmode] of
                 15,16:x:=1;
                 24,32:x:=2;
                 else  x:=0;
                 end;
                 wrinx(SEQ,$20,x or 8);
                 wrinx(SEQ,$25,$3F);
                 wrinx2(SEQ,$2C,$0);   {Hotspot}
               end;
       __chips:if cv.version=CT_452 then
	       begin
		 for x:=255 downto 0 do
		   mp.w[x]:=mp.w[x div 4];
		 CopyCurMap(512);

		 wrinx(cv.IOadr,$A,0);
		 wrinx2m(cv.IOadr,$30,{cv.mm*longint(64)-$20}curadr shr 4);
		 wrinx(cv.IOadr,$32,$ff);
		 wrinx(cv.IOadr,$37,1);
		 wrinx(cv.IOadr,$38,$FF);
		 wrinx(cv.IOadr,$39,0);
		 wrinx(cv.IOadr,$3A,$FF);  {Cursor FG color index}
	       end;
       __cir54:begin
		 clrinx(SEQ,$12,3);
		 wrinx(GRC,11,$24);
		 move(mp,mp.b[128],128);
		 CopyCurMap(256);
		 setHWcurcol($ff0000,$ff);
		 wrinx(SEQ,$13,$38);  {Cursor at End of Ram -2K}
	       end;
      __Mach32:begin
		 outp($1AEF,255);
		 outpw($1EEE,0);
                 fillchar(mp,1024,$AA);
                 y:=0;
                 for x:=0 to 127 do
                 begin
                   mp.w[y+x]:=al_packmap(bm[x]);
                   if (x and 3)=3 then inc(y,4);
                 end;

                 CopyCurMap(1024);

		 l:={(cv.mm*longint(1024)-1024) div 4}curadr shr 2;
		 outpw($AEE,l);
		 outpw($EEE,(l shr 16) or $8000);
	       end;
      __Mach64:begin
                 meml[cv.Xseg:$70]:=$200020;
                 meml[cv.Xseg:$68]:=curadr shr 3;
                 y:=4;
                 for x:=0 to 127 do
                 begin
                   mp.w[y+x]:=al_packmap(bm[x]);
                   if (x and 3)=3 then inc(y,4);
                 end;
                 {for x:=0 to 127 do mp.l[x]:=$55AAFF; }
                 CopyCurMap(1024);
                 setreg($66EC,$80);
               end;
	 __ncr:begin
		 w:=curadr shr 6;
                      {(cv.mm*longint(16))-4;    {256 bytes from the end of Vmem.}
		 y:=128;
		 for x:=127 downto 0 do
		 begin
		   mp.b[x+y]:=swapb(mp.b[x]);
		   if (x and 3)=0 then dec(y,4);
		 end;
		 for x:=0 to 31 do
		   mp.l[x*2]:=mp.l[x*2+1] xor $FFFFFFFF;

		 wrinx2m(SEQ,$11,$101);
		 CopyCurMap(256);

                 wrinx(SEQ,$A,$FF);   {Fg color}
		 wrinx(SEQ,$B,$0);
		 wrinx2m(SEQ,$13,0);
		 wrinx2m(SEQ,$15,w);
		 wrinx(SEQ,$17,$FF);
                 w:=3;  {Enable & 32x32}
                 if cv.version>=NCR_77c22ep then
                   case memmode of
                     _P15,_P16:w:=w or $20;
                    _P24,_P24b:w:=w or $40;
        _P32,_P32b,_P32c,_P32d:w:=w or $60;
                   end;
		 wrinx(SEQ,$C,w);
	       end;
         __Oak:if cv.Version>=OAK_083 then
               begin
		 for x:=0 to 255 do mp.l[x]:=0;
		 y:=384;
                 for x:=127 downto 0 do
                 begin
                   mp.b[x+y]:=swapb(bm[x] xor 255);
                   if (x and 3)=0 then dec(y,12);
                 end;

                 CopyCurMap(1024);

                 wrinx2($3DE,$44,$1f20);    {Limit to 32x32}
                 l:=curadr shr 3;
                 wrinx2($3DE,$47,l);
                 wrinx2($3DE,$49,l shr 16);
                 wrinx($3DE,$4A,255);
                 wrinx($3DE,$4B,254);
                 wrinx($3DE,$4C,1);
               end;
	  __S3:begin
		 wrinx(crtc,$39,$A0);
		 if (memmode>_p8) and (cv.Version<=S3_924) then
		 begin
		   for x:=0 to 127 do
		   begin
		     y:=pack8to16(bm[x]);
		     mp.l[x]:=(longint(lo(y)) shl 24)+(y and $FF00)+$FF00FF;
		   end;
		   for x:=256 to 511 do mp.w[x]:=$ff;
		 end
		 else begin
		   for x:=0 to 255 do mp.l[x]:=$ffff;  {Transparent}
		   y:=376;
		   for x:=127 downto 0 do
		   begin
		     mp.b[x+y]:=bm[x];
		     mp.b[x+y-2]:=not bm[x];
		     if (x and 1)=0 then dec(y,2);
		     if (x and 3)=0 then dec(y,8);
		   end;
		   if memmode=_pk4a then
                     for x:=0 to 511 do
                       mp.b[x]:=lo((mp.b[x] shl 4)+(mp.b[x] shr 4));
                   if (cv.Version=S3_801AB) and ((rdinx(crtc,$58) and $10)=0) then
                     for x:=0 to 255 do                 {What a hack....}
                       mp.l[x]:=(mp.l[x] and $FF0000FF)
                              +((mp.l[x] shl 8) and $FF0000)
                              +((mp.l[x] shr 8) and $FF00);
		 end;
		 CopyCurMap(1024);
                 wrinx(crtc,$39,$A0);  {CurMap turns off Ext Regs}
                 if cv.Version>S3_924 then wrinx(crtc,$58,x);
		 wrinx2(crtc,$4E,0);
		 wrinx2m(crtc,$4C,curadr shr 10);
		 wrinx(crtc,$39,0);
	       end;
         __SiS:begin
                 curadr:=cv.mm*longint(1024)-$4000;
                 for x:=0 to 255 do mp.l[x]:=$AAAAAAAA;
		 y:=124;
                 for x:=127 downto 0 do
                 begin
                   w:=0;
                   for z:=7 downto 0 do
                   begin
                     w:=w shl 2;
                     if ((bm[x] shr z) and 1)=0 then inc(w,2);
                   end;
                   mp.w[x+y]:=swap(w);
                   if (x and 3)=0 then dec(y,4);
                 end;
                 CopyCurMap(1024);
                 if (rdinx(SEQ,6) and $20)>0 then  {Interlace}
                 begin
                   inc(curadr,$400);
                   CopyCurMap(1024);
                 end;
                 setinx(SEQ,6,$40);
                 wrinx(SEQ,$1C,0);
                 wrinx(SEQ,$1F,0);
               end;
       __Tseng:if cv.version>=ET_4W32 then
	       begin
		 for x:=0 to 255 do mp.l[x]:=$AAAAAAAA;
		 y:=384;
		 begin
		   for x:=127 downto 0 do
		   begin
		     mp.w[x+y]:=al_packmap(bm[x]);
		     if (x and 3)=0 then dec(y,4);
		   end;
		   CopyCurMap(1024);
		   wrinx($217A,$EE,1);
		   wrinx2($217A,$EB,2);
		   {l:=cv.mm*longint(256)-256;}
		 end;
		 wrinx3($217A,$E8,curadr shr 2);

		 wrinx($217A,$EF,2);
		 wrinx($217A,$ED,0);
		 wrinx2($217A,$E2,32);
		 wrinx2($217A,$E6,32);
		 setinx($217A,$F7,$80);
	       end;
        __Trid:begin
                 for x:=0 to 31 do
                 begin
                   mp.l[x*2  ]:=not map[x];
                   mp.l[x*2+1]:=map[x];
                 end;
                 CopyCurMap(256);
                 wrinx2(crtc,$44,curadr shr 10);
                 wrinx2(crtc,$46,0);     {Hotspot = 0,0}
                 wrinx(crtc,$50,$80);
               end;
          __WD:begin   {WD90c24,31,33}
		 WD_wait;
		 outp($23C0,2);
		 for x:=127 downto 0 do
		   mp.w[x]:=mp.b[x] shl 8+$ff;  {XOR cursor, how to set
						 fore&bkground colors ?}

		 CopyCurMap(256);
		{ l:=cv.mm*longint(256)-64; }
		 WD_outl($1000,curadr shr 2);

		 if cv.version=WD_90c33 then w:=$C000
					else w:=$5000;
		 outpw($23C2,w);
		 if memmode>_p8 then w:=$810 else w:=$860;   {Mode 3}
		 outpw($23C2,w);
		 outpw($23C0,1);
	       end;
      __Cirrus,
      __Video7:begin
		 for x:=0 to 63 do mp.w[x]:=mp.w[x] xor $FFFF;
		 move(map,mp.b[128],128);
		 CopyCurMap(256);
		 wrinx(SEQ,$94,curadr shr 8);
		 modinx(SEQ,$FF,$60,curadr shr 13);
		 setinx(SEQ,$A5,$80); {Enable cursor}
	       end;
   __xbe,__xga:begin
		 wrinx(cv.IOadr+10,$36,0);
		 fillchar(mp,1024,$ff);
		 wrinx2(cv.IOadr+10,$60,0);
		 for x:=0 to 1024 do wrinx(cv.IOadr+10,$6A,mp.b[x]);
		 setHWcurcol($ff0000,$ff);
		 wrinx(cv.IOadr+10,$32,0);
		 wrinx(cv.IOadr+10,$35,0);
		 wrinx(cv.IOadr+10,$36,1);
	       end;
    end;
  clearDACpage;
end;

procedure setHWcurcol(fgcol,bkcol:longint);
var fgc,bkc:longint;
  w:word;
begin
  fgc:=rgb(fgcol shr 16,hi(fgcol),lo(fgcol));
  bkc:=rgb(bkcol shr 16,hi(bkcol),lo(bkcol));
  if dacHWcursor then
    case cv.dactype of
    _dacBt484,_dacBt485:
        begin
          outp(setDACpage(dacBTcwrInx),1);
          w:=setDACpage(dacBTcData);
          outp(w,bkcol shr 16);
          outp(w,hi(bkcol));
          outp(w,lo(bkcol));
          outp(w,fgcol shr 16);
          outp(w,hi(fgcol));
          outp(w,lo(fgcol));
        end;
    _dacTVP3010,_dacTVP3020,_dacTVP3025:
        begin
          wrDACreg(dacTVPindex,$23);
          wrDACreg(dacTVPdata,bkcol shr 16);
          wrDACreg(dacTVPindex,$24);
          wrDACreg(dacTVPdata,hi(bkcol));
          wrDACreg(dacTVPindex,$25);
          wrDACreg(dacTVPdata,lo(bkcol));
          wrDACreg(dacTVPindex,$26);
          wrDACreg(dacTVPdata,fgcol shr 16);
          wrDACreg(dacTVPindex,$27);
          wrDACreg(dacTVPdata,hi(fgcol));
          wrDACreg(dacTVPindex,$28);
          wrDACreg(dacTVPdata,lo(fgcol));
        end;
    _dacTVP3026:
        begin
          wrDACreg(dacTVP6index,$23);
          wrDACreg(dacTVP6data,bkcol shr 16);
          wrDACreg(dacTVP6index,$24);
          wrDACreg(dacTVP6data,hi(bkcol));
          wrDACreg(dacTVP6index,$25);
          wrDACreg(dacTVP6data,lo(bkcol));
          wrDACreg(dacTVP6index,$26);
          wrDACreg(dacTVP6data,fgcol shr 16);
          wrDACreg(dacTVP6index,$27);
          wrDACreg(dacTVP6data,hi(fgcol));
          wrDACreg(dacTVP6index,$28);
          wrDACreg(dacTVP6data,lo(fgcol));
        end;
    end
  else
    case cv.chip of
         __ARK:begin
                 if (memmode=_P15) or (memmode=_P16) then
                 begin
                   fgcol:=rgb(fgcol shr 16,hi(fgcol),lo(fgcol));
                   bkcol:=rgb(bkcol shr 16,hi(bkcol),lo(bkcol));
                 end;
                 wrinx(SEQ,$26,lo(fgcol));
                 wrinx(SEQ,$27,hi(fgcol));
                 wrinx(SEQ,$28,fgcol shr 16);
                 wrinx(SEQ,$29,lo(bkcol));
                 wrinx(SEQ,$2A,hi(bkcol));
                 wrinx(SEQ,$2B,bkcol shr 16);
               end;
       __cir54:begin
		 modinx(SEQ,$12,3,2);
		 outp($3C8,$ff);
		 outp($3C9,lo(fgcol) shr 2);
		 outp($3C9,hi(fgcol) shr 2);
		 outp($3C9,fgcol shr 18);
		 outp($3C8,0);
		 outp($3C9,lo(bkcol) shr 2);
		 outp($3C9,hi(bkcol) shr 2);
		 outp($3C9,bkcol shr 18);
		 modinx(SEQ,$12,3,1);
	       end;
      __Mach32:begin
		 outp($1AEE,lo(bkcol));
		 outp($1AEF,lo(fgcol));
		 if memmode>_p8 then
		 begin
		   outpw($3AEE,bkcol shr 8);
		   outpw($3EEE,fgcol shr 8);
		 end
	       end;
      __Mach64:begin
                 meml[cv.Xseg:$60]:=(fgcol shl 8)+lo(fgcol);
                 meml[cv.Xseg:$64]:=(bkcol shl 8)+lo(bkcol);
               end;
	  __S3:begin
               {  wrinx(crtc,$38,$48); }
		 wrinx(crtc,$39,$A0);
		 if memmode>_p8 then
		 begin
		   if rdinx(crtc,$45)=0 then;
		   wrinx(crtc,$4A,fgc);
		   wrinx(crtc,$4A,fgc shr 8);
		   if memmode>=_p24 then wrinx(crtc,$4A,fgc shr 16);
		   if rdinx(crtc,$45)=0 then;
		   wrinx(crtc,$4B,bkc);
		   wrinx(crtc,$4B,bkc shr 8);
		   if memmode>=_p24 then wrinx(crtc,$4B,bkc shr 16);
		 end
		 else begin
		   wrinx(crtc,$E,fgcol);
		   wrinx(crtc,$F,bkcol);
		 end;
		 wrinx(crtc,$39,0);
	       end;
         __SiS:begin
                 wrinx3(SEQ,$14,fgcol);
                 wrinx3(SEQ,$17,bkcol);
               end;
          __WD:begin
		 outp($23C0,2);
                 outpw($23C2,$8000+lo(fgcol));
		 outp($23C0,1);
               end;
        __Oak,
        __NCR,
        __AGX,
       __Tseng:(*if cv.version>=ET_4W32 then *)
	       begin
		 outp($3C8,$FF);
		 outp($3C9,lo(fgcol) shr 2);
		 outp($3C9,hi(fgcol) shr 2);
		 outp($3C9,fgcol shr 18);
	       end;
(*	 __AGX:;  *)
   __xbe,__XGA:begin
		 wrinx3m(cv.IOadr+10,$38,fgcol);
		 wrinx3m(cv.IOadr+10,$3B,bkcol);
	       end;
    end;
  clearDACpage;
end;

procedure HWcuronoff(on:boolean);
begin
  if dacHWcursor then
    case cv.dactype of
    _dacBt484,_dacBt485:
        modreg(setDACpage(dacBTcmd2),3,2*ord(on));
    _dacTVP3010,_dacTVP3020,_dacTVP3025:
        begin
          wrDACreg(dacTVPindex,6);
          modDACreg(dacTVPdata,$40,$40*ord(on));
        end;
    _dacTVP3026:
        begin
          wrDACreg(dacTVP6index,6);
          modDACreg(dacTVP6data,$40,$40*ord(on));
        end;
    end
  else
    case cv.chip of
       __Alli:begin
               if mem[SegA000:$D8]=0 then;
               outpw(SEQ,$1210);
               setinx(SEQ,$1C,8);
               modinx(SEQ,$1B,7,1);

               mem[SegA000:$7940]:=ord(on);

               clrinx(SEQ,$1B,7);
               clrinx(SEQ,$1C,8);
              end;
        __ARK:modinx(SEQ,$20,8,8*ord(on));
     __Mach32:outp($EEF,$80*ord(on));
     __Mach64:modreg($66EC,$80,$80*ord(on));
        __oak:if cv.version>=OAK_083 then
                modinx($3DE,$4C,1,ord(on));
	 __S3:begin
               { wrinx(crtc,$38,$48); }
		wrinx(crtc,$39,$A0);
		modinx(crtc,$45,3,2+ord(on));
		wrinx(crtc,$39,0);
	      end;
        __SiS:modinx(SEQ,6,$40,ord(on)*$40);
       __Trid:modinx(crtc,$50,$80,ord(on)*$80);
         __WD:begin
		outp($23C0,2);
		outpw($23C2,ord(on)*$800);
	      end;
      __AGX,
  __xbe,__xga:wrinx(cv.IOadr+10,$36,ord(on));
     __Cirrus,
     __Video7:modinx(SEQ,$A5,$80,ord(on)*$80);

    end;
  clearDACpage;
end;

procedure setHWcurpos(X,Y:word);
var l:longint;
  w:word;
begin

  if extpixfact>1 then x:=x*extpixfact;
  if extlinfact>1 then Y:=Y*extlinfact;
  if dacHWcursor then
    case cv.dactype of
    _dacBt484,_dacBt485:
        begin
          inline($fa);
          outpw(setDACpage(dacBTcurX),x+32);
          outpw(setDACpage(dacBTcurY),y+32);
          inline($fb);
        end;
    _dacTVP3010,_dacTVP3020,_dacTVP3025:
        begin
          wrDACreg(dacTVPindex,0);
          wrDACreg(dacTVPdata,lo(x));
          wrDACreg(dacTVPindex,1);
          wrDACreg(dacTVPdata,hi(x));
          wrDACreg(dacTVPindex,2);
          wrDACreg(dacTVPdata,lo(y));
          wrDACreg(dacTVPindex,3);
          wrDACreg(dacTVPdata,hi(y));
        end;
    _dacTVP3026:
        begin
          wrDACreg(dacTVP6index,0);
          wrDACreg(dacTVP6data,lo(x));
          wrDACreg(dacTVP6index,1);
          wrDACreg(dacTVP6data,hi(x));
          wrDACreg(dacTVP6index,2);
          wrDACreg(dacTVP6data,lo(y));
          wrDACreg(dacTVP6index,3);
          wrDACreg(dacTVP6data,hi(y));
        end;
    end
  else
    case cv.chip of
	 __ALG:if cv.version=ALG_2101 then
	       begin
		 if (rdinx(crtc,$19) and 1)=0 then y:=y*2;
		 if ((memmode=_P8) and ((rdinx(GRC,$C) and $10)=0))
                   or (memmode>_P8)  then x:=x*2;
		 wrinx(crtc,$21,x shr 3);
		 wrinx(crtc,$23,y shr 1);
		 modinx(crtc,$25,$7f,((x and 7) shl 2) + (y shr 9)
				+((y and 1) shl 6) or $20);
	       end
	       else begin
		 clrinx(crtc,$1A,4);
                 setinx(GRC,$F,$25);
		 outpw($82CA,x);
		 outpw($82CC,y);
                 clrinx(GRC,$F,1);
		 setinx(crtc,$1A,$54);
	       end;
       __Alli:begin
               if mem[SegA000:$D8]=0 then;
               outpw(SEQ,$1210);
               setinx(SEQ,$1C,8);
               modinx(SEQ,$1B,15,1);

               memw[SegA000:$7948]:=x;
               memw[SegA000:$794A]:=y;

               clrinx(SEQ,$1B,7);
               clrinx(SEQ,$1C,8);
              end;
         __ARK:begin
                 wrinx2m(SEQ,$21,x);
                 wrinx2m(SEQ,$23,y);
               end;
       __chips:if cv.version=CT_452 then
	       begin
		 wrinx2m(cv.IOadr,$33,x);
		 wrinx2m(cv.IOadr,$35,y);
	       end;
       __CIR54:BEGIN
		 outpw(SEQ,(x shl 5) or $10);
		 outpw(SEQ,(y shl 5) or $11);
	       END;
      __Mach32:begin
		 outpw($12EE,x);
		 outpw($16EE,y);
	       end;
      __Mach64:begin
                 memw[cv.Xseg:$6C]:=x;
                 memw[cv.Xseg:$6E]:=y;
               end;
	 __ncr:begin
		 wrinx2m(SEQ,$D,x);
		 wrinx2m(SEQ,$F,y);
	       end;
         __Oak:if cv.Version>=OAK_083 then
               begin
                 wrinx2m($3DE,$40,x and $FFFC);
                 wrinx2m($3DE,$42,y);
               end;
	  __S3:begin
                 if (curmode=$13) or (curmode=$D) then x:=x*2
                 else if cv.version<S3_864 then
                 begin
                   if memmode>=_P24 then x:=x*3
                   else if (memmode>=_P15) then x:=x*2;
                 end
                 else if (memmode>=_P32) and (cv.version<S3_732) then x:=x*2;
		 wrinx(crtc,$39,$A0);
		 wrinx2m(crtc,$46,x);
		 wrinx(crtc,$49,y);
		 wrinx(crtc,$48,y shr 8);  {this byte registers the new
					    cursor position - must be last
                                            byte written}
		 setinx(crtc,$45,1);
		 wrinx(crtc,$39,0);
	       end;
         __SiS:begin
                 wrinx2(SEQ,$1A,x);
                 if (rdinx(SEQ,6) and $20)>0 then  {Interlace}
                 begin
                   if (y and 1)>0 then y:=y+$2000;
                   y:=y shr 1;
                 end;
                 wrinx2(SEQ,$1D,y);
               end;
        __Trid:begin
                 wrinx2(crtc,$40,x);
                 wrinx2(crtc,$42,y);
               end;
       __Tseng:if cv.version>=ET_4W32 then
	       begin
                 if cv.version<ET_4W32p_A then
		   case memmode of
	        _p15,_p16:x:=x*2;
		     _p24:x:=x*3;
		   end;
                 if (cv.subvers>=$20) and (cv.subvers<$40) then
                 begin
                   repeat until (inp(crtc+6) and 2)>0;
                   repeat w:=inp(crtc+6) until (w and 2)=0;
                   wrinx2($217A,$E4,y);
                   if (w and $40)=0 then
                   begin
                     outp($3BF,3);
                     outp($3D8,$A0);
                     modinx(crtc,$37,$40,$40);
                     modinx(crtc,$37,$40,0);
                     outp($3D8,$29);
                     outp($3BF,1);
                   end;
                 end
                 else wrinx2($217A,$E4,y);
		 wrinx2($217A,$E6,32);
		 wrinx2($217A,$E0,x);
		 wrinx2($217A,$E2,32);
	       end;
	(* __AGX:if (inp(cv.IOadr) and 4)>0 then
	       begin
		 wrinx2(cv.IOadr+10,$30,x);
		 wrinx2(cv.IOadr+10,$33,y);
	       end; *)
          __WD:begin
		 outp($23C0,2);
		 if cv.version=WD_90c33 then
		 begin
		   if (memmode=_p15) or (memmode=_p16) then
		     x:=(x*2) div 3;
		   outpw($23C2,$D000+x);
		   outpw($23C2,$E000+y);
		 end
		 else begin
		   case memmode of
		_p15,_p16:x:=x*2;
		     _p24:x:=x*3;
		   end;
		   outpw($23C2,$6000+x);
		   outpw($23C2,$7000+y);
		 end;
	       end;
      __Cirrus,
      __Video7:begin
		 wrinx2m(SEQ,$9C,X);
		 wrinx2m(SEQ,$9E,Y);
	       end;
   __AGX,__xbe,__XGA:begin
		 wrinx2(cv.IOadr+10,$30,x);
		 wrinx2(cv.IOadr+10,$33,y);
	       end;
    end;
  clearDACpage;
end;


const
  S3accelmode:byte=0;   {0: unknown, 1: Accell, 2: Frame}

  {If possible sets up the mode for acceleration ad returns true, false if not}
function S3accelON:boolean;
begin
  S3accelON:=true;
  if (cv.version>S3_924) and (memmode>_PL4) then
  begin
    wrinx(crtc,$38,$48);
    wrinx(crtc,$39,$A5);
    clrinx(crtc,$58,$14);    {Disable Linear adr. & RAC}
    modinx(crtc,$40,9,1);
    clrinx(crtc,$53,$F);
    wrinx(crtc,$54,$A0);
    outpw($BEE8,$E000);
    outpw($AAE8,$FFFF);   {Enable all planes - }
    outpw($AEE8,$FFFF);
    if memmode>=_p24 then
    begin
      outpw($BEE8,$E010);
      outpw($AAE8,$FFFF);   {Enable all planes - }
      outpw($AEE8,$FFFF);
    end;
    S3accelmode:=1;
  end
  else begin
    wrinx(crtc,$38,$48);
    wrinx(crtc,$39,$A5);
    if (rdinx(crtc,$40) and 1)=0 then S3accelON:=false;
    wrinx(crtc,$39,0);
  end;
end;


procedure S3accelOFF;
begin
  if (cv.version>S3_924) and (memmode>_PL4) then
  begin
    wrinx(crtc,$38,$48);
    wrinx(crtc,$39,$A5);
    if (rdinx(crtc,$40) and 1)>0 then
      repeat until (inpw($9AE8) and $200)=0;
    clrinx(crtc,$40,1);
    setinx(crtc,$40,8);
    if (memmode>_pl4) and (curmode<>$13) then setinx(crtc,$58,$10);
    wrinx(crtc,$39,$5A);
    wrinx(crtc,$38,$00);
    S3accelmode:=2;
  end;
end;


procedure TridOutB(index,val:word);
begin
  outp(cv.IOadr,index);
  outp(cv.IOadr+2,val);
end;

procedure TridOutW(index,val:word);
begin
  outp(cv.IOadr,index);
  outpw(cv.IOadr+2,val);
end;

procedure TridOutL(index:word;val:longint);
begin
  outp(cv.IOadr,index);
  outpw(cv.IOadr+2,val);
  outpw(cv.IOadr+4,val shr 16);
end;


  (* Wait til ALG ready *)
procedure ALG_wait;
begin
  if cv.version=ALG_2101 then
    repeat until (inp($82AA) and $F)=0
  else
    repeat until (inp($82BA) and $80)=0;
end;

procedure AL_DstCoor(xst,yst:word);
var l:longint;
    w:word;
begin
  l:=yst*longint(pixels)+xst;
  ALG_wait;
  if memmode>_p8 then
  begin
    l:=l*2;
    outpw($828A,pixels*2);
  end
  else outpw($828A,pixels);
  outpw($8286,l);
  outp( $8288,l shr 16);
  outpw($829C,xst);
  outpw($829E,yst);
end;

procedure AL_BlitArea(dx,dy:word);
begin
  if memmode>_p8 then dx:=dx*2;
  outpw($828C,dx);
  outpw($828E,dy);
end;

procedure AL_SrcCoor(xst,yst:word);
var l:longint;
    w:word;
begin
  l:=yst*longint(pixels)+xst;
  if memmode>_p8 then
  begin
    l:=l*2;
    outpw($8284,pixels*2);
  end
  else outpw($8284,pixels);
  outpw($8280,l);
  outp( $8282,l shr 16);
end;

procedure WD_coor(index,x,y:word);
var l,b:longint;
begin
  b:=bytes;
  if memmode<=_pl4 then b:=b*8;
  case memmode of
  _p15,_p16:x:=x*2;
       _p24:x:=x*3;
  end;
  l:=b*y+x;
  WD_outl(index,l);
end;

procedure WD_DstCoor(X,Y,dx,dy:word);
var b:longint;
begin
  WD_coor($4000,X,Y);
  b:=bytes;
  if memmode<=_pl4 then b:=b*8;
  case memmode of
  _p15,_p16:dx:=dx*2;
       _p24:dx:=dx*3;
  end;
  outpw($23C2,$6000+dx);
  outpw($23C2,$7000+dy);
  outpw($23C2,$8000+b);
end;

procedure P2000_DstCoor(X,Y,dx,dy,dir:word);
var l:longint;
begin
  l:=longint(pixels)*y+x;
  if memmode>_p8 then
  begin
    dx:=dx*2;
    l:=l*2;
    wrinx2(GRC,$3A,pixels*2);
  end
  else wrinx2(GRC,$3A,pixels);
  if dir>0 then dy:=dy or $C000;
  wrinx2(GRC,$33,dx);
  wrinx3(GRC,$37,l);
  wrinx2(GRC,$35,dy);
end;

procedure P2000_SrcCoor(X,Y:word);
var l:longint;
begin
  l:=longint(pixels)*y+x;
  if memmode>_p8 then l:=l*2;
  if memmode=_pl4 then wrinx(GRC,5,0);  {set write mode 0}
  wrinx3(GRC,$30,l);
  wrinx2(GRC,$1E,pixels);
end;

procedure P2000_cmd(cmd:word);
begin
  wrinx(GRC,$3D,cmd);
  repeat until (rdinx(GRC,$3D) and 1)=0;
  wrinx(GRC,$3D,0);
end;

procedure S3_fill(xst,yst,dx,dy:integer;col:longint);
begin
  if (pixels>1024) and (memmode>=_p8) and
    (cv.Version>=S3_928) and (cv.Version<S3_864) then  {Argh...}
  begin
    yst:=yst*2;
    dy:=dy*2;
  end;

  repeat until (inp($9AE8) and $FF)=0;
  outpw($82E8,yst);
  outpw($86E8,Xst);
  outpw($96E8,dx);
  outpw($BEE8,$E000);
  outpw($A6E8,col);
  if (memmode>=_p24) then
  begin
    outpw($BEE8,$E010);
    outpw($A6E8,col shr 16);
  end;
  repeat until (inp($9AE8) and $FF)=0;
  outpw($BAE8,$27);
  outpw($BEE8,dy-1);
  outpw($BEE8,$A000);
  outpw($9AE8,$40F1);
  clrinx(crtc,$40,1);
end;

procedure fillrect(xst,yst,dx,dy:word;col:longint);
const
  masks:array[0..3] of byte=(0,7,3,1);
  maske:array[0..3] of byte=($F8,$FC,$FE,$FF);
  masks4:array[0..7] of byte=(0,$7F,$3F,$1F,$F,7,3,1);
  maske4:array[0..7] of byte=($80,$C0,$E0,$F0,$F8,$FC,$FE,$FF);
var w,w1:word;
    l:longint;
begin
  case cv.chip of
       __ALG:begin
	       AL_DstCoor(xst,yst);
	       AL_BlitArea(dx,dy);
	       wrinx(GRC,$D,col);
	       outp( $8290,7);
	       outp( $8292,$D);
	       outp( $82AA,1);
	     end;
       __ARK:begin
               repeat until (inp($3CB) and $F)>=7;
               setinx(SEQ,$10,$1C);
               wrinx(SEQ,$13,$00);
               wrinx(SEQ,$14,$C0);
               memw[SegA800:$02]:=0;
               memw[SegA800:$08]:=col;
               memw[SegA800:$18]:=$300;
               memw[SegA800:$1A]:=$FFFF;
               meml[SegA800:$58]:=0;
               meml[SegA800:$5C]:=$FFFFFFFF;
               repeat until (inp($3CB) and $F)>=7;
               memw[SegA800:$70]:=Xst;
               memw[SegA800:$72]:=Yst;
               memw[SegA800:$74]:=dx;
               memw[SegA800:$76]:=dy;
               meml[SegA800:$7C]:=$20400000;
               clrinx(SEQ,$10,$1C);
             end;
    __compaq:begin
	       case usebits[memmode] of
                  4:col:=(col and 15)*$11111111;
                  8:col:=lo(col)*$1010101;
              15,16:col:=(col and $FFFF)*$10001;
	       end;
	       repeat until (inp($33CE) and 1)=0;
	       if (cv.Version=CPQ_AVGA) or (rdinx(GRC,$F)=$A5) then
	       begin
		 if memmode=_p8 then
		 begin
		   l:=(yst*bytes+xst) shr 2;
		   w:=bytes shr 2;
		   outp($33C0,masks[xst and 3]);
		   outp($33C1,maske[((xst+dx-1) and 3)]);
		   outp($33C8,(-dx) and 3);
		   outp($33C9,masks[dx and 3]);
		   if ((xst and 3)=0) and ((dx and 3)=0) then inc(dx,4);
		   outpw($23C2,(dx +(xst and 3) +3) shr 2);
		 end
		 else begin
		   l:=yst*bytes+(xst shr 3);
		   w:=bytes;
		   outp($33C0,masks4[xst and 7]);
		   outp($33C1,maske4[(xst+dx-1) and 7]);
		   outp($33C8,(-dx) and 7);
		   outp($33C9,masks4[dx and 7]);
		   if ((xst and 7)=0) and ((dx and 7)=0) then inc(dx,8);
		   outpw($23C2,(dx +(xst and 7) +7) shr 3);
		 end;
		 outpw($23C0,l);
		 outpw($23CA,w);
		 outpw($23CC,w);
		{ outpw($33C0,$ffff); }
		 outp($33c7,$c);
		{ outpw($33c8,0); }
		 w:=(l shr 2) and $C000;
		 w:=w or ((dy shl 4) and $3000);
		 outpw($23C4,dy+w);
	      {   if (xst and 3)>0 then inc(dx,4);
		 if ((xst+dx-1) and 3)>0 then inc(dx,4); }
		 outp($33CF,$30);
	       end
	       else begin
		 outpw($63CC,xst);
		 outpw($63CE,yst);
		 outpw($23C2,dx);
		 outpw($23C4,dy);
		 outp($33CF,$C0);
		 wrinx(GRC,$5A,2);
	       end;
	       outpw($33CA,col);
	       outpw($33CA,col);
	       outpw($33CC,col shr 16);
	       outpw($33CC,col shr 16);
	       outp($33CE,9);
	     end;
     __cir54:begin
	       repeat until (rdinx(GRC,$31) and 1)=0;
	       case memmode of
	     _p15,_p16:w:=2;
		  _p24:w:=3;
	       else w:=1;
	       end;
               wrinx(GRC,1,col);
               wrinx(GRC,$11,hi(col));
	       wrinx2(GRC,$20,dx*w);
	       wrinx2(GRC,$22,dy);
	       wrinx3(GRC,$28,Yst*bytes+Xst*w);
	       wrinx3(GRC,$2C,cv.mm*longint(1024)-8);
               modinx(GRC,$30,$CF,$C0);   {PatternCopy + Color Expand}
	       wrinx(GRC,$32,$D);
	       wrinx(GRC,$31,2);
	     end;
    __Mach32:begin
               repeat until inpw($9AEE)=0;
               outpw($A6E8,col);
               outpw($BAEE,7);
               outpw($CEEE,$3391);
               outpw($82E8,yst);
               outpw($86E8,xst);
               outpw($A6EE,xst);
               outpw($AAEE,xst+dx);
               outpw($AEEE,yst+dy);
             end;
    __Mach64:begin
               repeat until (mem[cv.Xseg:$338] and 1)=0;
               repeat until memw[cv.Xseg:$310]=0;
               write32($2C4,col);         {Fill color}
               write32($2D4,$70003);      {}
               write32($2C8,$FFFFFFFF);   {Write mask}
               write32($2D8,$100);        {}
               write32($130,3);           {Dest Cntl}

               write32w($10C,xst,yst);    {Dest start X,Y}
               write32w($118,dy,dx);      {Size}
             end;
       __NCR:begin
               repeat until (mem[cv.Xseg:$32] and 1)=1;
               write32($50,col);
               write32($4C,col);
               write32($48,0);
               write32($44,0);
               write32($40,pixeladdress(Xst,Yst));
               write32w($3C,dy,dx);
               write32($38,$cc0000);
               write32($34,$C8C0); {Color Expand, Down&Right}
               write32($30,1);    {Start}
             end;
     __P2000:begin
	       wrinx(GRC,$3E,col);
	       P2000_DstCoor(xst,yst,dx,dy,0);
	       P2000_cmd($19);
	     end;
	__S3:if S3accelON then
             begin
	       S3_fill(xst,yst,dx,dy,col);
	       if (memmode>_p8) and (cv.version<=S3_924) then
		 S3_fill(xst+1024,yst,dx,dy,hi(col));
	       S3accelOFF;
	     end;
       __SiS:begin
               setinx(SEQ,$B,1);
               while (mem[SegA000:$82AB] and $80)>0 do;
               meml[SegA000:$8284]:=xst*bytes+yst;
               memw[SegA000:$828A]:=bytes;
               memw[SegA000:$828C]:=8;
               memw[SegA000:$828E]:=4;
               mem [SegA000:$8290]:=col;
               mem [SegA000:$8293]:=$F0;
               memw[SegA000:$82AA]:=$30;
               clrinx(SEQ,$B,1);
             end;
      __Trid:if cv.Version>=TR_9200CXr then
             begin
             while (mem [$BFF0:$20] and $20)>0 do;
               mem [$BFF0:$27]:=$F0;
               memw[$BFF0:$2C]:=col;
               memw[$BFF0:$30]:=col;
               memw[$BFF0:$38]:=Xst;
               memw[$BFF0:$3A]:=Yst;
               memw[$BFF0:$40]:=dx-1;
               memw[$BFF0:$42]:=dy-1;
               memw[$BFF0:$28]:=$4000;
               mem [$BFF0:$24]:=1;

             end;
     __Tseng:if cv.version>=ET_4W32 then
	     begin
               case colbits[memmode] of
                   8:l:=col*$1010101;
               15,16:begin
                       l:=col*$10001;
                       dx:=dx*2;
                       Xst:=Xst*2;
                     end;
                  24:begin
                       l:=col*$1000001;{Bug!!}
                       dx:=dx*3;
                       Xst:=Xst*3;
                     end;
                  32:begin
                       l:=col;
                       dx:=dx*4;
                       Xst:=Xst*4;
                     end;
               end;
               write32(0,l);write32(4,l);
               {memL[cv.xseg:0]:=l;  {Fill Color}
             {  write32($7F80,cv.mm*longint(1024)-8);
               {meml[cv.xseg:$7F80]:=cv.mm*longint(1024)-4;    {Pattern/Color Data}
	       mem [cv.xseg:$7F8F]:=0;    {Direction}
	       memw[cv.xseg:$7F98]:=dx-1;
	       memw[cv.xseg:$7F9A]:=dy-1;
	       mem [cv.xseg:$7F9C]:=0;
	       mem [cv.xseg:$7F9F]:=$F0;
               write32($7FA0,Yst*bytes+Xst);
	       {meml[cv.xseg:$7FA0]:=Yst*bytes+Xst;}
               if cv.version<ET_4W32p_a then mem [cv.xseg:$7F31]:=9;

	     end;
        __WD:if cv.Version=WD_90c33 then
             begin
	       WD_wait;
	       outp($23C0,3);
               outpw($23C2,$2000+lo(col));
               outpw($23C2,$3000+hi(col));
	       outp($23C0,1);
               outpw($23C2,$4000+xst);
               outpw($23C2,$5000+yst);
	       outpw($23C2,$6000+dx-1);
	       outpw($23C2,$7000+dy-1);
	       outpw($23C2,$8300);
	       outpw($23C2,$210);
             end
             else begin {c24,c31}
	       outp($23C0,1);
	       outpw($23C2,$1000);
	       outpw($23C2,$E0FF);
	       outpw($23C2,$9300);
	       outpw($23C2,$A000+col);
	    {   outpw($23C2,$2000);
	       outpw($23C2,$3000); }
	       if (memmode<=_pl4) and ((xst and 7)+dx=10) then
	       begin
		 w1:=1;
		 dec(dx);
	       end else w1:=0;

	       WD_DstCoor(xst,yst,dx,dy);
	       if cv.version=WD_90c33 then w:=$208 else w:=$808;
	       if memmode>_pl4 then w:=w+$100;
	       outpw($23C2,w);
	       WD_wait;
	       if w1>0 then
	       begin
		 WD_DstCoor(xst+dx-1,yst,1,dy);
		{ if cv.version=WD_90c33 then w:=$208 else} w:=$808;
		 if memmode>_pl4 then w:=w+$100;
		 outpw($23C2,w);
		 WD_wait;
	       end;
	     end;
        __AGX,__xbe,__xga:
             begin
	       repeat until (mem[cv.xseg:$11] and $80)=0;
	       mem [cv.xseg:$12]:=1;
	       mem [cv.xseg:$48]:=3;     {Always Src}
	       meml[cv.xseg:$58]:=col;
	       memw[cv.xseg:$78]:=xst;
	       memw[cv.xseg:$7A]:=yst;
	       memw[cv.xseg:$60]:=dx-1;
	       memw[cv.xseg:$62]:=dy-1;
	       meml[cv.xseg:$7C]:=$8118000;   {Cmd (Bitblt)}
	     end;
  end;
end;

procedure S3_copy(srcX,srcY,dstX,dstY,dx,dy,dir:word);
begin
  if (pixels>1024) and (memmode>=_p8) and
    (cv.Version>=S3_928) and (cv.Version<S3_864) then  {Argh...}
  begin
    srcY:=srcY*2;
    dstY:=dstY*2;
    dY:=dY*2;
  end;

  repeat until (inp($9AE8) and $FF)=0;
  outpw($BAE8,$67);
  outpw($BEE8,$A000);
  outpw($86E8,SrcX);
  outpw($82E8,SrcY);
  outpw($8EE8,DstX);
  outpw($8AE8,DstY);

  outpw($96E8,dx-1);
  outpw($BEE8,dy-1);
  repeat until (inp($9AE8) and $FF)=0;
 { outpw($BEE8,$E040); }
  if dir<>0 then outpw($9AE8,$C013)
            else outpw($9AE8,$C0F3);
end;

procedure copyrect(srcX,srcY,dstX,dstY,dx,dy:word);
var l:longint;
    w,dir:word;
    i1,i2:integer;
begin
  if (DstY<SrcY) or ((SrcY=DstY) and (DstX<SrcX)) then dir:=0
  else begin
    dir:=1;
    SrcX:=SrcX+dx-1;
    SrcY:=SrcY+dy-1;
    DstX:=DstX+dx-1;
    DstY:=DstY+dy-1;
  end;
  case cv.chip of
       __ALG:begin
               if dir>0 then
               begin
                 SrcX:=SrcX-dx+1;
                 DstX:=DstX-dx+1;
               end;
	       AL_DstCoor(DstX,DstY);
	       AL_BlitArea(dx,dy);
	       AL_SrcCoor(SrcX,SrcY);
               w:=7;
               if dir>0 then w:=1;
	       outp( $8290,w);
	       outpw($8292,w);
	       outp( $82AA,2);
	     end;
    __compaq:begin
	       repeat until (inp($33CE) and 1)=0;
	       if (cv.Version=CPQ_AVGA) or (rdinx(GRC,$F)=$A5) then   {AVGA}
	       begin
		 l :=srcy*bytes+srcx;
		 w:=256;
		 if (dir>0) then w:=$FF00;
	    {     begin
		   l:=l+(dy-1)*bytes+(dx-1);
		   w:=$ff00;
		 end; }
		 i1:=dsty-srcy;
		 i2:=dstx-srcx;
		 outpw($23C0,l shr 2);
		 outpw($23CC,lo(i1)*256+lo(i2 shr 2));
		 outp($23C2,dx shr 2);
		 outpw($23CA,w{bytes shr 2});
		 outpw($33C0,$FFFF);
		 outp($33C7,$C);
		 outpw($33C8,0);
		 w:=(w and $C00) or ((l shr 4) and $C000);
		 w:=w or ((i1 shl 4) and $3000);
		 outpw($23C4,dy+w);
		 outp($33CF,$30);
	       end
	       else begin            {QVision}
		 outpw($63CC,DstX);
		 outpw($63CE,DstY);
		 outpw($63C0,SrcX);
		 outpw($63C2,SrcY);
		 outpw($23C2,dx);
		 outpw($23C4,dy);
		 outpw($23CC,bytes shr 2);
		 outp($33CF,$C0);
		 wrinx(GRC,$5A,1);
	       end;
	       outp($33CE,$11+(dir shl 6));
	     end;
     __cir54:begin
	       repeat until (rdinx(GRC,$31) and 1)=0;
	       case memmode of
	     _p15,_p16:w:=2;
		  _p24:w:=3;
	       else w:=1;
	       end;
	       wrinx2(GRC,$20,dx*w);
	       wrinx2(GRC,$22,dy);
	       wrinx3(GRC,$28,dstY*bytes+dstX*w);
	       wrinx3(GRC,$2C,srcY*bytes+srcX*w);
	       wrinx (GRC,$32,$D);
               modinx(GRC,$30,$CF,dir);
	       wrinx (GRC,$31,2);
	     end;
    __Mach32:begin
               repeat until inpw($9AEE)=0;
               outpw($BAEE,$7);
               outpw($CEEE,$7391);
               outpw($8EE8,SrcX);
               outpw($8AE8,SrcY);
               outpw($B2EE,SrcX);
               outpw($82E8,DstY);
               outpw($86E8,DstX);
               outpw($A6EE,DstX);
               if dir=0 then
               begin
                 outpw($C2EE,1);
                 outpw($BEEE,SrcX+dx);
                 outpw($AAEE,DstX+dx);
                 outpw($AEEE,DstY+dy);
               end
               else begin
                 outpw($C2EE,0);
                 outpw($BEEE,SrcX-dx);
                 outpw($AAEE,DstX-dx);
                 outpw($AEEE,DstY-dy);
               end;
             end;
    __Mach64:begin
               repeat until (mem[cv.Xseg:$338] and 1)=0;
               repeat until memw[cv.Xseg:$310]=0;
               write32($2D4,$70003);      {}
               write32($2C8,$FFFFFFFF);   {Write mask}
               write32($2D8,$300);        {}
               write32($1B4,0);           {Src Cntl}

               write32w($18C,SrcX,SrcY);  {Src start X,Y}
               write32($190,dy);          {Src width1}
               if dir=0 then w:=3 else w:=0;
               write32($130,w);           {Dest Cntl}
               write32w($10C,DstX,DstY);  {Dest start X,Y}
               write32w($118,dy,dx);      {Size}
             end;
       __NCR:begin
               repeat until (mem[cv.Xseg:$32] and 1)=1;
               write32($44,pixeladdress(SrcX,SrcY));
               write32($40,pixeladdress(DstX,DstY));
               write32w($3C,dy,dx);
               write32($38,$CC0000);
               w:=$C0C0;
               if dir>0 then w:=$C000;
               write32($34,w);    {Copy, Down&Right}
               write32($30,1);    {Start}
             end;
     __P2000:begin
               if dir>0 then
               begin
                 SrcX:=SrcX-dx+1;
                 DstX:=DstX-dx+1;
               end;
	       P2000_SrcCoor(SrcX,SrcY);
	       P2000_DstCoor(DstX,DstY,dx,dy,dir);
	       P2000_Cmd(5);
	     end;
        __WD:if cv.Version=WD_90c33 then
             begin
	       WD_wait;
	       outp($23C0,1);
               outpw($23C2,$2000+SrcX);
               outpw($23C2,$3000+SrcY);
               outpw($23C2,$4000+DstX);
               outpw($23C2,$5000+DstY);
	       outpw($23C2,$6000+dx-1);
	       outpw($23C2,$7000+dy-1);
	       outpw($23C2,$8300);
               if dir>0 then w:=$380 else w:=$200;
	       outpw($23C2,w);
             end
             else begin
	       WD_wait;
	       outpw($23C2,$1000);
	       outpw($23C2,$E0FF);
	       WD_DstCoor(DstX,DstY,dx,dy);
	       WD_Coor($2000,SrcX,SrcY);
	       outpw($23C2,$9300);
	       w:=$800;
	       if memmode>_pl4 then w:=w+$100;
	       if dir>0 then w:=w+$400;
	       outpw($23C2,w);
	       WD_wait;
	     end;
	__S3:if S3accelON then
	     begin
	       S3_copy(SrcX,SrcY,DstX,DstY,dx,dy,dir);
	       if (memmode>_p8) and (cv.version<=S3_924) then
		 S3_copy(SrcX+1024,SrcY,DstX+1024,DstY,dx,dy,dir);
	       S3accelOFF;
	     end;
      __Trid:if cv.Version>=TR_9200CXr then
             begin
               while (mem [$BFF0:$20] and $20)>0 do;
               mem [$BFF0:$27]:=$CC;
               memw[$BFF0:$38]:=DstX;
               memw[$BFF0:$3A]:=DstY;
               memw[$BFF0:$3C]:=SrcX;
               memw[$BFF0:$3E]:=SrcY;
               memw[$BFF0:$40]:=dx-1;
               memw[$BFF0:$42]:=dy-1;
               memw[$BFF0:$28]:=0;
               mem [$BFF0:$24]:=1;
             end;
     __Tseng:if cv.version>=ET_4W32 then
	     begin
               case colbits[memmode] of
                 15,16:begin
                         dx:=dx*2;
                         SrcX:=SrcX*2;
                         DstX:=DstX*2;
                       end;
                    24:begin
                         dx:=dx*3;
                         SrcX:=SrcX*3;
                         DstX:=DstX*3;
                       end;
                    32:begin
                         dx:=dx*4;
                         SrcX:=SrcX*4;
                         DstX:=DstX*4;
                       end;
               end;
	       mem [cv.xseg:$7F9F]:=$CC;      {Copy}
	       mem [cv.xseg:$7F8F]:=3*dir;    {Direction}
	       mem [cv.xseg:$7F9C]:=0;
	       memw[cv.xseg:$7F98]:=dx-1;
	       memw[cv.xseg:$7F9A]:=dy-1;
               write32($7F84,SrcY*bytes+SrcX);
               write32($7FA0,DstY*bytes+DstX);
               if cv.version<ET_4W32p_a then mem[cv.xseg:$7F31]:=9;
	     end;
       __AGX,__xbe,__xga:
             begin
	       repeat until (mem[cv.xseg:$11] and $80)=0;
	       mem [cv.xseg:$48]:=3;
	       memw[cv.xseg:$70]:=SrcX;
	       memw[cv.xseg:$72]:=SrcY;
	       memw[cv.xseg:$78]:=DstX;
	       memw[cv.xseg:$7A]:=DstY;
	       memw[cv.xseg:$60]:=dx-1;
	       memw[cv.xseg:$62]:=dy-1;

               l:=$28118000;
               if dir>0 then inc(l,6);
	       meml[cv.xseg:$7C]:=l;    {BitBlt cmd}
	     end;
  end;
end;

procedure swp(var i,j:integer);
var z:integer;
begin
  z:=i;
  i:=j;
  j:=z;
end;

procedure S3_line(x0,y0,x1,y1:integer;col:longint);
var w,z:word;
begin
  if (pixels>1024) and (memmode>=_p8) and
    (cv.Version>=S3_928) and (cv.Version<S3_864) then  {Argh...}
  begin       {urgh! - is there a better way?}
    y0:=y0*2;
    y1:=y1*2;
  end;
  repeat until (inp($9AE8) and $FF)=0;
  outpw($82E8,Y0);
  outpw($86E8,X0);
  w:=0;z:=0;
  x1:=x1-x0;
  if x1<0 then
  begin
    x1:=-x1;
    w:=w or $20;
    z:=1;
  end;
  y1:=y1-y0;
  if y1<0 then
  begin
    y1:=-y1;
    w:=w or $80;
  end;
  if x1<y1 then
  begin
    swp(x1,y1);
    w:=w or $40;
  end;
  outpw($8AE8,2*y1);
  outpw($8EE8,2*(y1-x1));
  outpw($92E8,2*y1-x1-z);
  outpw($96E8,x1);
  outpw($BEE8,$E000);
  outpw($A6E8,col);
  repeat until (inp($9AE8) and $FF)=0;
  if (memmode>_p16) then
  begin
    outpw($BEE8,$E010);
    outpw($A6E8,col shr 16);
  end;
  outpw($BAE8,$27);
  outpw($BEE8,$A000);
  outpw($9AE8,$2017+w);
end;


procedure line(x0,y0,x1,y1:integer;col:longint);
var l:longint;
  z,w:word;
  dx,dy,mi,ma:integer;
begin
  case cv.chip of
       __ALG:begin
	       AL_DstCoor(x0,y0);
	       wrinx(GRC,$D,col);
	       outpw($82A8,$FFFF);
	       w:=0;
	       x1:=x1-x0;
	       if x1<0 then
	       begin
		 x1:=-x1;
		 w:=w or $100;
	       end;
	       if memmode>_p8 then x1:=x1*2;
	       y1:=y1-y0;
	       if y1<0 then
	       begin
		 y1:=-y1;
		 w:=w or $200;
	       end;
	       if x1<y1 then
	       begin
		 swp(x1,y1);
		 w:=w or $400;
	       end;
	       outpw($82A2,2*y1);
	       outpw($82A6,2*y1-x1);
	       outpw($82A4,2*(y1-x1));
	       outpw($828E,x1+1);
	       outpw($8292,$80D+w);
	       outp ($8290,0);
	       outp ($82AA,8);
	     end;
    __Mach32:begin
               repeat until inpw($9AEE)=0;
               outpw($A6E8,col);
               outpw($A2EE,0);
            {   outpw($BEE8,$A000); }
               outpw($BAE8,$27);
              { outp ($B6E8,$27); }
               outpw($9AEE,0);
               outpw($FEEE,x0);    {Start}
               outpw($FEEE,y0);
               outpw($FEEE,x1);    {Stop}
               outpw($FEEE,y1);
             end;
    __Mach64:begin
               repeat until memw[cv.Xseg:$310]=0;
               write32($2C4,col);          {Fg Color}
               write32($2D4,$70003);
               write32($2C8,$FFFFFFFF);    {Write mask}
               write32($2D8,$100);
               write32w($2A8,pixels-1,0);  {Clip left/right}
               write32w($2B4,lins-1,0);    {Clip top/bot}


	       dx:=abs(x0-x1);
	       dy:=abs(y0-y1);
	       mi:=dx;
	       ma:=dy;
	       if mi>ma then swp(mi,ma);
               write32w($10C,x0,y0);
               if x1>x0 then w:=1 else w:=0;
               if y0<y1 then inc(w,2);
               if dx<dy then inc(w,4);
               write32($130,w);
               write32($124,2*mi-ma);
               write32($128,2*mi);
               write32($12C,2*(mi-ma));
               write32($120,ma+1);

             (*  case memmode of
                _PK4:l:=$10101;
            _P8,_P24:l:=$20202;
                _P15:l:=$30303;
                _P16:l:=$40404;
                _P32:l:=$60606;
               end;
               meml[cv.Xseg:$2D0]:=l;    {Pixel Width}
               meml[cv.Xseg:$308]:=0;           {Color Cmp off}
               meml[cv.Xseg:$330]:=3;           {GUI trajetory}

               repeat until memw[cv.Xseg:$310]=0;

               meml[cv.Xseg:$100]:=(pixels shr 3) shl 22;   {} *)


               l:=meml[cv.Xseg:$310];

             end;
        __WD:if cv.Version=WD_90c33 then
             begin
	       WD_wait;
	       dx:=abs(x0-x1);
	       dy:=abs(y0-y1);
	       mi:=dx;
	       ma:=dy;
	       if mi>ma then swp(mi,ma);
	       outpw($23C8,2*mi);
	       outpw($23CA,2*(mi-ma));
	       if x0>x1 then inc(ma);
	       outpw($23CC,2*mi-ma);
	       outp($23C0,3);
               outpw($23C2,$2000+lo(col));
               outpw($23C2,$3000+hi(col));
	       outp($23C0,1);
	       WD_wait;
               outpw($23C2,$4000+x0);
               outpw($23C2,$5000+y0);
	       outpw($23C2,$6000+ma);
	       outpw($23C2,$8300);
               w:=$810;
               if x0>x1 then w:=w+$100;
               if y0>y1 then w:=w+$80;
               if dx<dy then w:=w+$40;
	       outpw($23C2,w);
               w:=w;
             end
             else begin
	       WD_wait;
	       dx:=abs(x0-x1);
	       dy:=abs(y0-y1);
	       mi:=dx;
	       ma:=dy;
	       if mi>ma then swp(mi,ma);
	       outpw($23C2,$4000+x0);
	       outpw($23C2,$5000+y0);
	       outpw($23C2,$6000+dx);
	       outpw($23C2,$7000+dy);
	       outpw($23C2,$9300);
	       outpw($23C2,$A000+lo(col));
	       outpw($23C8,2*mi);
	       outpw($23CA,2*(mi-ma));
	       if x0>x1 then inc(ma);
	       outpw($23CC,2*mi-ma);
	       w:=$1800;
	      { if x0>x1 then inc(w,$100); }
	       if y0>y1 then inc(w,$100);
	       if dx>dy then inc(w,$200);
	       outpw($23C2,w);
	       outpw($23C2,$910);
	       WD_wait;
	     end;
	__S3:if S3accelON then
	     begin
	       S3_line(x0,y0,x1,y1,col);
	       if (memmode>_p8) and (cv.Version<=S3_924) then
		 S3_line(x0+1024,y0,x1+1024,y1,hi(col));
	       S3accelOFF;
	     end;
     __Tseng:if (cv.version>=ET_4W32) {and (x0<>x1) and (y0<>y1)} then
	     begin
               case colbits[memmode] of
                   8:l:=col*$1010101;
               15,16:begin
                       l:=col*$10001;
                       X0:=X0*2;
                       X1:=X1*2;
                     end;
                  24:begin
                       l:=col*$1000001;{Bug!!}
                       X0:=X0*3;
                       X1:=X1*3;
                     end;
                  32:begin
                       l:=col;
                       X1:=X1*4;
                       X0:=X0*4;
                     end;
               end;
               write32(0,l);
               {memL[cv.xseg:0]:=l;  {Fill Color}
               write32(4,l);
               {memL[cv.xseg:4]:=l;  {Fill Color}
               l:=cv.mm*longint(1024)-4;    {Pattern/Color Data}
               w:=0;
               y1:=y1-y0;
               x1:=x1-x0;
               if y1=0 then
               begin
                 if x1<0 then
                 begin
                   x1:=-x1;
                   inc(x0);
                 end;
                 dx:=x1-1;
                 dy:=0;
               end
               else if x1=0 then
               begin
                 if Y1<0 then
                 begin
                   Y1:=-Y1;
                   inc(Y0);
                 end;
                 dx:=0;
                 dy:=y1-1;
               end
               else begin
                 w:=$80;
                 if Y1<0 then
                 begin
                   Y1:=-Y1;
                   w:=w or $12;
                 end;
                 if x1<0 then
                 begin
                   x1:=-X1;
                   w:=w or 1;
                   inc(l,3);
                 end;
                 if X1<Y1 then
                 begin
                   z :=X1;
                   X1:=Y1;
                   Y1:=z;
                   w:=w or 4;
                   dx:=Y1-1;
                   dy:=$FFF;
                 end
                 else begin
                   dx:=$FFF;
                   dy:=Y1-1;
                 end;
	         memw[cv.xseg:$7FAC]:=X1;
	         memw[cv.xseg:$7FAE]:=Y1;
               end;
               write32($7F80,l);
               {meml[cv.xseg:$7F80]:=l;    {Pattern/Color Data}
	       mem [cv.xseg:$7F8F]:=w;    {Direction}
               mem [cv.xseg:$7F9C]:=0;
               mem [cv.xseg:$7F9F]:=$F0;
	       memw[cv.xseg:$7F98]:=dx;
	       memw[cv.xseg:$7F9A]:=dy;
               write32($7FA0,Y0*bytes+X0);
	       {meml[cv.xseg:$7FA0]:=Y0*bytes+X0;}
	     end;
       __AGX,__xbe,__xga:
             begin
	       repeat until (mem[cv.xseg:$11] and $80)=0;
               dx:=abs(X0-X1);
               dy:=abs(Y0-Y1);
	       mi:=dx;
	       ma:=dy;
	       if mi>ma then swp(mi,ma);
               meml[cv.xseg:$58]:=col;
               mem [cv.xseg:$48]:=3;
               memw[cv.xseg:$78]:=X0;
               memw[cv.xseg:$7A]:=Y0;
               memw[cv.xseg:$24]:=2*mi;
               memw[cv.xseg:$28]:=2*(mi-ma);
               if x0>x1 then inc(ma);
               memw[cv.xseg:$20]:=2*mi-ma;
               memw[cv.xseg:$60]:=ma-1;
               memw[cv.xseg:$62]:=dy-1;

               l:=$5118000;
               if dy>dx then inc(l,1);
               if Y0>Y1 then inc(l,2);
               if X0>X1 then inc(l,4);
	       meml[cv.xseg:$7C]:=l;
	     end;
  end;
end;

var
  ZwinOfs:longint;
  Zxstep:word;


procedure setZoomWindow(Xs,Ys,Xe,Ye:word);
begin
  case cv.chip of
     __Tseng:if cv.version=ET_3000 then
	     begin
	       case memmode of
		   _Pl4:Xs:=Xs div 8;
		   _pk4:Xs:=Xs shr 1;
	    {  _p15,_p16:Xs:=Xs*2;
		   _P24:Xs:=Xs*3; }
	       end;
	       ZwinOfs:=bytes*Ys+Xs;
	       wrinx(crtc,$1B,Xs shr 3);
	       wrinx(crtc,$1C,Xe shr 3);
	       wrinx(crtc,$1D,Ys);
	       wrinx(crtc,$1E,Ye);
	       wrinx(crtc,$1F,hi(Ye)+(hi(Ys) shl 3));
	     end
	     else if cv.version>=ET_4W32 then
	     begin
	       wrinx2($217A,$E0,Xs);
	       wrinx2($217A,$E2,Xe-Xs+1);
	       wrinx2($217A,$E4,Ys);
	       wrinx2($217A,$E6,Ye-Ys+1);
	     end;
  end;
end;

procedure setZoomAdr(AdrX,AdrY:word);
var l:longint;
begin
  case memmode of
       _Pl4:AdrX:=AdrX div 8;
       _pk4:AdrX:=AdrX shr 1;
  _p15,_p16:AdrX:=AdrX*2;
 _P24,_p24b:AdrX:=AdrX*3;
  end;
  l:=(bytes*AdrY+AdrX);
  case cv.chip of
    __Tseng:if cv.version=ET_3000 then
	    begin
	      l:=(l shr 3)-(ZwinOfs shr 3);
	      wrinx2(crtc,$20,l);
	      modinx(crtc,$23,4,l shr 14);
	    end
	    else if cv.version>=ET_4W32 then
		   wrinx3($217A,$E8,l);
  end;

end;

procedure ZoomOnOff(On:boolean);
begin
  case cv.chip of
    __Tseng:if cv.version=ET_3000 then
	    begin
	      modinx(SEQ,6,$80,ord(On) shl 7);
	      Zxstep:=8;
	    end
	    else if cv.version>=ET_4W32 then
	    begin
	      wrinx($217A,$EF,3);
	      wrinx2($217A,$EB,bytes div 8);
	      modinx($217A,$F7,$80,ord(On) shl 7);
	    end;
  end;
end;

procedure setZoomFactor(Fx,Fy:word);
begin
  case cv.chip of
    __Tseng:if cv.version=ET_3000 then modinx(SEQ,6,$77,Fy+(Fx shl 4))
	    else if cv.version>=ET_4W32 then
		   wrinx($217A,$EE,3+(Fx shl 6)+(Fy shl 4));
  end;
end;


  (* Clock Selection *)

procedure setclk(Nbr,divi:word);
var x:word;
begin

  if (cv.flags and FLG_StdVGA)>0 then clrinx(crtc,$11,$80);

  case cv.chip of
      __AGX:begin
              if (cv.Version=IIT_AGX1x) then x:=$7F else x:=$77;
              if Nbr>15 then
              begin
                modinx(cv.IOadr+10,x,$30,nbr shl 4);
                modinx(cv.IOadr+10,$6F,$70,(nbr shl 2) or $40);
                clrinx(cv.IOadr+10,$70,$80);
              end
              else if Nbr>7 then
              begin
                modinx(cv.IOadr+10,x,$30,nbr shl 4);
                clrinx(cv.IOadr+10,$6F,$70);
                setinx(cv.IOadr+10,$54,$0C);
                clrinx(cv.IOadr+10,$70,$80);
              end
              else begin
                modinx(cv.IOadr+10,$54,$0C,nbr shl 2);
                clrinx(cv.IOadr+10,$6F,$70);
                modinx(cv.IOadr+10,$70,$80,nbr shl 5);
              end;
              modinx(cv.IOadr+10,x,$40,divi shl 6);
	    end;

    __Ahead:begin  {Only for the B ??}
              modinx(GRC,$E,$3,nbr shr 2);
              if divi>0 then x:=$F0 else x:=0;
              modinx(GRC,$E,$F0,x);
            end;
      __ALG:begin
	      modinx(GRC,$C,$20,Nbr shl 3);
	      modinx(GRC,$1F,$4,Nbr shr 1);
	      modinx(GRC,$B,3,divi);
	    end;
      __ARK:begin
              modinx(SEQ,$11,$C0,nbr shl 4);
            end;
      __ati:begin
	      if cv.version=ATI_18800 then
                modinx(cv.IOadr,$B2,64,nbr shl 4)
	      else begin
		modinx(cv.IOadr,$B9,2,Nbr shr 1);
		modinx(cv.IOadr,$BE,$10,Nbr shl 1);
	      end;
	      if cv.version<ATI_GUP_3 then x:=$C0 else x:=$40;
	      modinx(cv.IOadr,$B8,x,divi shl 6);
	    end;
    __chips:if cv.Version<CT_65520 then
            begin
              if nbr>3 then nbr:=(nbr-4)*4+2;
              outp(crtc+6,(inp($3CA) and $FC)+nbr shr 2);
            end
	    else begin
              if Nbr>3 then
              begin
                x:=Nbr-4;
                Nbr:=2;
              end;
              if (rdinx(cv.IOadr,$51) and 4)>0 then {Panel}
                modinx(cv.IOadr,$54,$C3,(nbr+(x shl 2)) shl 2)
	      else    {CRT}
		outp(crtc+6,inp($3CA) and $FC + (x and 3));
            end;
   __Compaq:outp($3C2,(inp($3CC) and $EF) + ((nbr and 4) shl 2));
    __Genoa:modinx(SEQ,7,1,nbr shr 2);
      __HMC:modinx(SEQ,$E7,$C0,Nbr shl 4);
   __Mach32:modreg($4AEE,$3C,nbr shl 2);
   __Mach64:modreg($4AEC,$7F,(nbr and $F)+((divi and 3) shl 4)+$40);
     __MXIC:modinx(SEQ,$C4,1,Nbr shr 2);
      __NCR:if cv.version=NCR_77c32BLT then
              modinx(SEQ,$1F,$60,Nbr shl 3)
            else modinx(SEQ,$1F,$60,(Nbr shl 4) or $20);
      __oak:begin
              modinx($3DE,$D,$20,Nbr shl 3);
              modinx($3DE,$6,8,nbr);
            end;
    __p2000:modinx(GRC,$14,$30,Nbr shl 2);
       __WD:begin
	      modinx(GRC,$C,2,Nbr shr 1);
	      if cv.version>WD_90c00 then
		modinx(SEQ,$12,4,nbr shr 1);
              if cv.version=WD_90c24 then
              begin
                wrinx(SEQ,$35,$50);  {Unlock clock regs}
                modinx(SEQ,$31,$18,nbr shl 1);
              end;
	    end;
  __realtek:modinx(GRC,$C,$20,Nbr shl 3);
       __S3:if nbr<>3 then
            begin
	      wrinx(crtc,$38,$48);
	      wrinx(crtc,$39,$A5);
	      modinx(crtc,$42,$F,Nbr);
	      outp($3C2,inp($3CC) or $C);
	      wrinx(crtc,$39,$5A);
	      wrinx(crtc,$38,$0);
              nbr:=3;   {Fool std vga}
	    end;
      __SiS:begin
              modinx(SEQ,$7,$F,nbr);
              nbr:=3;
            end;
    __Tseng:if cv.version=ET_3000 then modinx(crtc,$24,2,Nbr shr 1)
	    else begin
	      outp($3BF,3);
	      outp(crtc+4,$A0);
	      modinx(crtc,$34,2,Nbr shr 1);
	      modinx(crtc,$31,$C0,Nbr shl 3);
	    end;
    __Poach,
     __Trid:begin
	      wrinx(SEQ,$B,0);  {Old mode}
	      case cv.version of
		TR_8900C,TR_9000C,TR_8900CL..TR_GUI9430:
		    modinx(SEQ,$E,$10,Nbr shl 1);
	      end;
	      if rdinx(SEQ,$B)=0 then;  {New mode}
	      modinx(SEQ,$D,1,Nbr shr 2);
	      if ((cv.version=TR_9000) or (cv.version=TR_9000i)) then
		modinx(SEQ,$D,$40,nbr shl 3);
	      modinx(SEQ,$D,6,divi shr 1);
	    end;
      __UMC:modinx(SEQ,7,1,Nbr shr 2);
   __Video7:begin
              modinx(SEQ,$A4,$1C,Nbr shl 2);
              modinx(SEQ,$F8,1,Nbr shr 3);
            end;
  end;
  if (cv.flags and FLG_StdVGA)>0 then
    outp($3C2,(inp($3CC) and $F3)+((Nbr and 3) shl 2));
end;

   {Returns the id of the selected clock and the divisor used on it.
    The divisor is in 1/12th, Ie. 12 = /1, 24 = /2, 18 = /1.5
    divid is an ID for the divisor (0,1..)}
function getclk(var divisor,divid:word):word;
var x,clknbr:word;
const
  _1_  = 12;
  _1_5 = 18;
  _2_  = 24;
  _3_  = 36;
  _4_  = 48;

  triddiv:array[0..3] of word=(_1_,_2_ ,_4_,_1_5);
   atidiv:array[0..3] of word=(_1_,_2_ ,_3_,_4_);
   otidiv:array[0..3] of word=(_1_,_2_ ,_3_,_3_);
 P2000div:array[0..3] of word=(_1_,_4_ ,_2_,_4_);
   RTGdiv:array[0..3] of word=(_1_,_1_5,_2_,_4_);
   ALGdiv:array[0..3] of word=(_1_,_2_ ,_4_,_4_);
begin
  divisor:=12;   {standard no division}
  clknbr:=(inp($3CC) shr 2) and 3;
  divid:=0;
  case cv.chip of
      __AGX:begin
              if (cv.Version=IIT_AGX1x) then x:=$7F else x:=$77;
              if (rdinx(cv.IOadr+10,$6F) and $40)>0 then
              begin
                clknbr:=((rdinx(cv.IOadr+10,x) shr 4) and 3)+16;
                inc(clknbr,(rdinx(cv.IOadr+10,$6F) and $30) shr 2);
              end
              else begin
                clknbr:=(rdinx(cv.IOadr+10,$54) shr 2) and 3;
                if (rdinx(cv.IOadr+10,$70) and $80)>0 then inc(clknbr,4);
                if clknbr=3 then
                  clknbr:=((rdinx(cv.IOadr+10,x) shr 4) and 3)+8;
              end;
              if (rdinx(cv.IOadr+10,x) and $40)>0 then
              begin
                divisor:=_2_;
                divid:=1;
              end;
	    end;
    __Ahead:begin    {Only for the B ??}
              x:=rdinx(GRC,$E);
              if ((x shr clknbr) and $10)>0 then
              begin
                divid:=1;
                divisor:=_2_;
              end;
              inc(clknbr,(x and 3) shl 2)
            end;
      __ALG:begin
	      if (rdinx(GRC,$C) and $20)>0 then inc(clknbr,4);
	    (*  if (rdinx(GRC,$B) and 2)>0 then divisor:=24;*)
	      if (rdinx(GRC,$1F) and $4)>0 then inc(clknbr,8);
	      divid:=rdinx(GRC,$B) and 3;
	      if cv.version=ALG_2101 then divisor:=RTGdiv[divid]
				     else divisor:=ALGdiv[divid];
	    end;
     __Alli:if clknbr=3 then clknbr:=rgs.xxregs.x[$D8] and $F;
      __ARK:begin
              inc(clknbr,(rdinx(SEQ,$11) and $C0) shr 4);
            end;
      __ati:begin
	      if cv.version=ATI_18800 then
              begin
                if (rdinx(cv.IOadr,$B2) and $40)>0 then inc(clknbr,4);
              end
	      else begin
		if (rdinx(cv.IOadr,$B9) and 2)>0 then inc(clknbr,4);
		if (rdinx(cv.IOadr,$BE) and $10)>0 then inc(clknbr,8);
	      end;
	      if cv.version<ATI_GUP_3 then x:=$C0 else x:=$40;
	      divid:=(rdinx(cv.IOadr,$B8) and x) shr 6;
	      divisor:=atidiv[divid];
	    end;
    __chips:if cv.Version<CT_65520 then
            begin
              if clknbr=2 then clknbr:=(inp($3CA) and 3)+4;
	    end
            else if cv.Version<CT_64300 then
            begin
              if (rdinx(cv.IOadr,$51) and 4)>0 then {Panel}
              begin
                clknbr:=(rdinx(cv.IOadr,$54) shr 2) and 3;
                x  :=(rdinx(cv.IOadr,$54) shr 4) and 3;
              end
	      else    {CRT}
		x:=inp($3CA) and 3;
              if clknbr>=2 then clknbr:=x+4;
            end;
   __Compaq:begin
              clknbr:=(inp($3CC) shr 2) and 7;
              if rdinx(GRC,$F)<>$A5 then inc(clknbr,8);
            end;
    __Genoa:if (rdinx(SEQ,7) and 1)>0 then inc(clknbr,4);
      __HMC:inc(clknbr,(rdinx(SEQ,$E7) and $C0) shr 4);
   __Mach32:begin
              clknbr:=(inp($4AEE) shr 2) and $F;
              if (inp($4AEE) and $40)>0 then divisor:=_2_;
            end;
   __Mach64:begin
              clknbr:=inp($4AEC);
              divid:=(clknbr shr 4) and 3;
              case divid of
                1:divisor:=_2_;
                2:divisor:=_4_;
              end;
              clknbr:=clknbr and 15;
            end;
     __MXIC:if (rdinx(SEQ,$C4) and 1)>0 then inc(clkNbr,4);
      __NCR:if cv.version=NCR_77c32BLT then
              inc(ClkNbr,(rdinx(SEQ,$1F) and $60) shr 3)
            else if (rdinx(SEQ,$1F) and $40)>0 then inc(ClkNbr,4);
      __oak:begin
              if (rdinx($3DE,$D) and $20)>0 then inc(clknbr,4);
              if cv.Version>=OAK_083 then
              begin
                if (rdinx($3DE,6) and 8)>0 then inc(clknbr,8);
                divisor:=otidiv[rdinx($3DE,$21) and 3];
               { if (rdinx($3DE,$14) and 1)>0 then divisor:=divisor*3; }
              end;
	    end;
    __p2000:begin
	      inc(clknbr,(rdinx(GRC,$14) and $30) shr 2);
	      divisor:=p2000div[(rdinx(GRC,$14) shr 2) and 3];
	    end;
       __WD:begin
	      if (rdinx(GRC,$C) and 2)>0 then inc(clknbr,4);
	      if cv.version>WD_90c00 then
		if (rdinx(SEQ,$12) and 4)>0 then inc(clknbr,8);
              if cv.version=WD_90c24 then
                clknbr:=(clknbr and 3)+(rgs.seqregs.x[$31] and $18) shr 1;
	    end;
  __Realtek:begin
	      if (rdinx(GRC,$C) and $20)>0 then inc(clknbr,4);
	      divisor:=rtgdiv[rdinx(GRC,$B) and 3];
	    end;
       __S3:if clknbr=3 then
	    begin
	      wrinx(crtc,$38,$48);
	      wrinx(crtc,$39,$A5);
	      clknbr:=rdinx(crtc,$42) and $F;
	      wrinx(crtc,$39,$5A);
	      wrinx(crtc,$38,$0);
	    end;
      __SiS:if clknbr=3 then clknbr:=rdinx(SEQ,7) and $F;
    __Tseng:if cv.version=ET_3000 then
	    begin
	      if (rdinx(crtc,$24) and 2)>0 then inc(clknbr,4);
	   {   if (rdinx(SEQ,7) and $40)>0 then divisor:=24; }
	    end
	    else begin
	      if (rdinx(crtc,$34) and 2)>0 then inc(clknbr,4);
	      inc(clknbr,(rdinx(crtc,$31) and $C0) shr 3);
	      case rdinx(SEQ,7) and $42 of
	       $40:divisor:=24;
	       $42:divisor:=48;
	      end;
	    end;
    __Poach,
     __Trid:begin
	      wrinx(SEQ,$B,0);  {Old mode}
	      case cv.version of
       		TR_8900C,TR_9000C,TR_8900CL..TR_GUI9430:
		    if (rdinx(SEQ,$E) and $10)>0 then inc(clknbr,8);
	      end;
	      if rdinx(SEQ,$B)=0 then;  {New mode}
	      if (rdinx(SEQ,$D) and 1)>0 then inc(clknbr,4);
	      if ((cv.version=TR_9000) or (cv.version=TR_9000i))
		and ((rdinx(SEQ,$D) and $40)>0) then inc(clknbr,8);
	      divisor:=triddiv[(rdinx(SEQ,$D) shr 1) and 3];
	    end;
      __UMC:begin
	      if (rdinx(SEQ,7) and 1)>0 then inc(clkNbr,4);
	      if (rdinx(SEQ,9) and $80)>0 then divisor:=24;
	    end;
   __Video7:if cv.version>=V7_208A then
            begin
              clknbr:=(rdinx(SEQ,$A4) shr 2) and 7;
              if (rdinx(SEQ,$F8) and 1)>0 then inc(clkNbr,8);
            end;
  end;
  getclk:=clknbr;
end;

function getClockFreq:longint;    {Effective pixel clock in kHz}
const
  wd24clk:array[0..15] of longint=(29979,77408,0,80092,25175,28322
          ,65000,36000,39822,50114,42060,44297,31500,35501,75166,50114);

var clknbr,divisor,x,reg:word;
    clk,ref:longint;
begin
  clknbr:=getclk(divisor,x);
  clk:=(cv.clks[clknbr]*12) div divisor;
  ref:=(14318*12) div divisor;
  case cv.clktype of
       clk_unk:;
       clk_ICD2061,clk_ICD2061A:
               if (clknbr and 3)=3 then clk:=0; {Prog clock - Can't read}
      clk_sdac:(*if clknbr=2 then*)
               begin
                 clknbr:=(clknbr and 3)*2;
                 clk:=(ref*((rgs.dacinxd.x[clknbr] and 127)+2))
                   div (((rgs.dacinxd.x[clknbr+1] and 31)+2) shl (rgs.dacinxd.x[clknbr+1] shr 5));
               end;
       clk_STG:begin
                 clknbr:=clknbr*2+$20;
                 clk:=ref*(rgs.dacinxd.x[clknbr]+2) div
                      (((rgs.dacinxd.x[clknbr+1] and $1F)+2)
                      shl (rgs.dacinxd.x[clknbr+1] shr 5));
               end;
   clk_TVP302x:case clknbr and 3 of
                  0:clk:=(25175*12) div divisor;
                  1:clk:=(28322*12) div divisor;
                2,3:clk:=(ref*8*((rgs.dacinxd.x[$41] and 127)+2)) div
                     (((rgs.dacinxd.x[$40] and 31)+2) shl (rgs.dacinxd.x[$42] and 3));
               end;
     clk_CHRON:begin
                 clknbr:=(clknbr and 15)*2;
                 clk:=(ref*(rgs.dacinxd.x[clknbr]+8)) div ((((rgs.dacinxd.x[clknbr+1]
                    and 63)+2) shl (rgs.dacinxd.x[clknbr+1] shr 6)));
               end;
     clk_MUSIC:begin
                 clknbr:=(clknbr and 7)*2;
                 clk:=(ref*((rgs.dacinxd.x[clknbr] and 127)+1)) div
                   ((((rgs.dacinxd.x[clknbr+1] and 15)+1) shl
                    ((rgs.dacinxd.x[clknbr+1] shr 4) and 3)));
               end;
    clk_IBM52x:if (rgs.dacinxd.x[$10] and 1)>0 then
               begin
                 clknbr:=((clknbr and 7)*2)+$20;
                 clk:=(ref*((rgs.dacinxd.x[clknbr] and 63)+65)) div
                   ((rgs.dacinxd.x[clknbr+1] and $1F) shl
                    (3-(rgs.dacinxd.x[clknbr] shr 6)));
               end
               else begin
                (* clknbr:=(clknbr and 15)+$20;
                 clk:=(ref*((rgs.dacinxd.x[clknbr] and 63)+65)) div
                   ((rgs.dacinxd.x[$14] and $1F) shl
                    (3-(rgs.dacinxd.x[clknbr] shr 6))); *)
               end;
  else
    case cv.chip of
     __Cir54:if (clknbr=0) and (cv.version<=CL_GD5402) then clk:=25175
             else begin
	       clk:=(ref*rgs.seqregs.x[$B+clknbr]) div (rgs.seqregs.x[$1B+clknbr] shr 1);
	       if (rgs.seqregs.x[$1B+clknbr] and 1)>0 then clk:=clk div 2;
	       case (rgs.seqregs.x[7] and 6) of
		 2:clk:=clk div 2;
		 4:clk:=clk div 3;
	       end;
             end;
     __chips:if (cv.version=CT_64300) and (clknbr>=2) then
               clk:=(ref*2*(rgs.xxregs.x[$31]+2)) div (rgs.xxregs.x[$32]+2);
        __S3:if (cv.Version=S3_732) or (cv.Version=S3_764) then
               case clknbr of
                 0:clk:=(25175*12) div divisor;
                 1:clk:=(28322*12) div divisor;
               else
                 clk:=(ref*((rgs.seqregs.x[$13] and $7F)+2)) div
                    (((rgs.seqregs.x[$12] and $1F)+2) shl (rgs.seqregs.x[$12] shr 5));
               end;
      __Trid:if cv.version=TR_GUI9440 then   {Not there yet}
               case clknbr and 3 of
                 0:clk:=(25175*12) div divisor;
                 1:clk:=(28322*12) div divisor;
                 2:begin
                     clknbr:=(((rgs.dacregs[9] shl 1)+(rgs.dacregs[8] shr 7)) and $1F)+1;
                     clk:=((ref*((rgs.dacregs[8] and $7F)+3)) div
                          (clknbr shl (rgs.dacregs[9] shr 4)));
                   end;
               end;
        __WD:if cv.version=WD_90c24 then
             begin    {WD90c24 internal clock}
               if clknbr<>2 then clk:=WD24clk[clknbr]
               else clk:=(rgs.seqregs.x[$32]*longint(447443)) div 1000;
             end;
    end;
  end;
  getClockFreq:=clk;
end;

