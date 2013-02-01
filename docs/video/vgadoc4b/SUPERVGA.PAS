unit supervga;

interface
uses dos,crt;



{$i defvga.pas}   {Definitions}


{$i bitblt.pas}

var
  curbank:word;   {The current bank number. Set by SetBank}
  vgran:word;


  {Sets the Bank registers in units of 64Kbytes. If the chip has separate
   Read/Write Bank registers, both are set}
procedure setbank(bank:word);
var x:word;
    l:longint;
begin
  if bank=curbank then exit;   {Only set bank if diff. from current value}
  vseg:=SegA000;
  curbank:=bank;
  case cv.chip of
      __Acer:begin      {Read/Write banks or 32K banks?}
               wrinx(GRC,$10,bank);
               wrinx(GRC,$11,bank);
             end;
     __ahead:if cv.version=AH_B then wrinx(GRC,13,bank*17)
             else begin
	       wrinx(GRC,13,bank shr 1);
	       x:=inp($3cc) and $df;
	       if odd(bank) then inc(x,32);
	       outp($3c2,x);
	     end;
       __ALG:begin
	       outp($3d7,bank);
	       outp($3D6,bank);
	     end;
      __Alli:begin
               if mem[SegA000:$D8]=0 then;
               outpw(SEQ,$1210);
               setinx(SEQ,$1C,8);
               modinx(SEQ,$1B,7,1);
               memw[SegA000:$C0]:=bank shl 4;
               clrinx(SEQ,$1B,7);
               clrinx(SEQ,$1C,8);
             end;
       __ARK:begin
               wrinx(SEQ,$15,bank);
               wrinx(SEQ,$16,bank);
             end;
    __Mach32:begin
	       x:=(bank and 15)*$22;          {Roll bank nbr into bit 0}
	       wrinx(cv.IOadr,$B2,hi(x) or lo(x));
	       modinx(cv.IOadr,$AE,$F,(bank shr 4)*5);
	     end;
    __Mach64:begin
               bank:=bank*2;
               outp($56EC,bank);
               outp($56EE,bank+1);
               outp($5AEC,bank);
               outp($56EE,bank+1);
             end;
       __ati:begin
	       if cv.version=ATI_18800 then
		 modinx(cv.IOadr,$B2,$1E,bank shl 1)
	       else begin
		 x:=(bank and 15)*$22;          {Roll bank nbr into bit 0}
		 wrinx(cv.IOadr,$B2,hi(x) or lo(x));
	       end;
	       if cv.version>=ATI_GUP_3 then
		 modinx(cv.IOadr,$AE,$F,(bank shr 4)*5);
	     end;
     __chips:if (cv.version<=CT_457) then wrinx(cv.IOadr,$B,bank)
	     else begin
	       if memmode<=_pl4 then bank:=bank shl 2;
	       if cv.version<>CT_452 then bank:=bank shl 2;
	       wrinx(cv.IOadr,$10,bank shl 2);
               if cv.Version=CT_64300 then
                 modinx(cv.IOadr,$C,$10,bank shr 2);
	     end;
     __cir54:begin
	       if (rdinx(GRC,$B) and 32)=0 then bank:=bank shl 2;
	       wrinx(GRC,9,bank shl 2);
	     end;
     __cir64:begin
	       bank:=bank shl 4;
	       wrinx(GRC,$E,bank);
	       wrinx(GRC,$F,bank);
	     end;
    __compaq:begin
	       wrinx(GRC,$F,5);
	       bank:=bank shl 1;
               if (cv.Version>=CPQ_QV1024) and
                 ((inp($23C7) and $10)>0) then x:=1
                                          else x:=3;
               if (cv.version=CPQ_AVGA) and (memmode=_PL4) then x:=5;
	       wrinx(GRC,$45,bank shl x);
	       if (rdinx(GRC,$40) and 1)>0 then inc(bank);
	       wrinx(GRC,$46,(bank) shl x);
	     end;
    __everex:begin
	       x:=inp($3CC) and $DF;
	       if (bank and 2)>0 then inc(x,32);
	       outp($3C2,x);
	       modinx(SEQ,8,$80,bank shl 7);
	     end;
     __genoa:wrinx(SEQ,6,bank*9+$40);
       __HMC:begin
	       if memmode=_p8 then modinx(SEQ,$EE,$70,bank shl 4)
	       else if bank=0 then vseg:=SegA000 else vseg:=SegB000;
	     end;
    __Matrox:begin
               if memmode<=_pl4 then bank:=bank*4;
               modinx($3DE,9,$F,bank);
             end;
      __mxic:wrinx(SEQ,$c5,bank*17);
       __ncr:begin
	       if memmode<=_pl4 then bank:=bank shl 2;
	       wrinx(SEQ,$18,bank shl 2);
	       wrinx(SEQ,$1C,bank shl 2);
	     end;
       __oak:if cv.Version<=OAK_083 then wrinx($3DE,$11,bank*17)
             else begin
	       wrinx($3DE,$23,bank);
	       wrinx($3DE,$24,bank);
	     end;
        __WD:begin
	       wrinx(GRC,9,bank shl 4);
	       wrinx(GRC,$A,bank shl 4);
	       if cv.version=WD_90c33 then
		 modinx(SEQ,$14,$C0,((bank shr 4) and 1)*$C0);
	     end;
     __p2000,
   __realtek:begin
	       outp($3d6,bank);
	       outp($3d7,bank);
	     end;
	__s3:begin
	       if memmode<=_pl4 then bank:=bank*4;
               wrinx(crtc,$39,$A5);
               if cv.Version>=S3_864 then wrinx(crtc,$6A,bank)
               else begin
	         wrinx(crtc,$38,$48);
	         setinx(crtc,$31,9);
                 modinx(crtc,$35,$F,bank);
                 if cv.version>S3_924 then modinx(crtc,$51,$C,bank shr 2);
                 wrinx(crtc,$38,0);
               end;
               wrinx(crtc,$39,$5A);
	     end;
        __SC:begin
               outp($3CD,bank shl 1);
               wrinx(SEQ,$15,bank shl 1);
             end;
       __SiS:begin
               outp($3CD,bank);
               outp($3CB,bank);
             end;
     __Poach,
      __trid:if cv.version=TR_8800BR then
             begin
               modinx(SEQ,$E,6,bank);
               if (bank and 1)>0 then vseg:=SegB000 else vseg:=SegA000;
             end
             else if cv.Version>=TR_9000C then
             begin
               outp($3D8,bank);
               outp($3D9,bank);
             end
             else begin
               wrinx(SEQ,$B,0);
               if rdinx(SEQ,$B)=0 then;  {New mode}
               if (memmode<=_pl4) and (bank>1) then inc(bank,2);
               modinx(SEQ,$E,$F,bank xor 2);
	     end;
     __Tseng:if cv.Version=ET_3000 then outp($3CD,bank*9+$40)
	     else begin
	       outp($3CD,(bank and 15)*17);
	       if cv.version<>ET_4000 then
		 outp($3CB,(bank shr 4)*17);
	     end;
    __video7:if cv.Version<V7_208A then
	     begin
	       if memmode>_pl4 then
	       begin
		 x:=inp($3CC) and $DF;
		 if (bank and 2)>0 then inc(x,32);
		 outp($3C2,x);
		 modinx(SEQ,$F9,1,bank);
		 bank:=bank shr 2;
	       end;
	       modinx(SEQ,$F6,$F,bank*5);
	     end
	     else begin
               if memmode<=_PL4 then bank:=bank*4;
	       wrinx(SEQ,$E8,bank shl 4);
	      { wrinx(SEQ,$E9,bank shl 4+8); {Don't work ?}
	     end;
       __UMC:wrinx(SEQ,6,bank*17);
    __Weitek:outp($3CD,bank*17);
      __vesa:begin
	       rp.bx:=0;
	       bank:=bank*longint(64) div vgran;
	       rp.dx:=bank;
	       vio($4f05);
	       rp.bx:=1;
	       rp.dx:=bank;
	       vio($4f05);
	     end;
       __AGX,__xbe,__xga:
             outp(cv.IOadr+8,bank);
  __WeitekP9:outp($3CD,bank or $20);  {Actually only the W5x86 Vipers}
  end;
end;

  {Sets the Read Bank register in units of 64Kbytes}
procedure setRbank(bank:word);
var x:word;
begin
  curbank:=$FFFF;    {always flush}
  case cv.chip of
    __ahead:if cv.version=AH_B then modinx(GRC,$D,$F,bank);
      __ALG:outp($3D6,bank);
    __Mach32:begin
	      x:=(bank and $F) shl 5;
	      modinx(cv.IOadr,$B2,$E1,hi(x) or lo(x));
	      modinx(cv.IOadr,$AE,$C,bank shr 2);
	    end;
   __Mach64:begin
              bank:=bank shl 1;
              mem[cv.Xseg:$B8]:=bank;
              mem[cv.Xseg:$BA]:=bank+1;
            end;
      __ARK:wrinx(SEQ,$16,bank);
      __ati:begin                {Roll bank nbr into bit 0}
	      x:=(bank and $F) shl 5;
	      modinx(cv.IOadr,$B2,$E1,hi(x) or lo(x));
	      if cv.version>=ATI_GUP_3 then
		modinx(cv.IOadr,$AE,$C,bank shr 2);
	    end;
    __cir64:wrinx(GRC,$E,bank shl 4);
    __Genoa:modinx(SEQ,6,7,bank);
     __mxic:modinx(SEQ,$C5,$F0,bank shl 4);
      __ncr:begin
	       if memmode<=_pl4 then bank:=bank shl 2;
	       wrinx(SEQ,$1C,bank shl 2);
	    end;
      __oak:if cv.Version<=OAK_083 then modinx($3DE,$11,$F,bank)
                                   else wrinx($3DE,$23,bank);
       __WD:begin
	      wrinx(GRC,9,bank shl 4);
	      if cv.version=WD_90c33 then
		modinx(SEQ,$14,$40,bank shl 2);
	    end;
    __p2000:outp($3D7,bank);
  __realtek:outp($3D6,bank);
      __SiS:outp($3CB,bank);
     __Trid:if cv.Version>=TR_9000C then outp($3D9,bank);

    __Tseng:if cv.Version=ET_3000 then modreg($3CD,$38,bank shl 3)
	    else begin
	      modreg($3CD,$F0,bank shl 4);
	      if cv.version<>ET_4000 then
		modreg($3CB,$30,bank);
	    end;
 {  __Video7:if cv.Version>=V7_208A then wrinx(SEQ,$E9,(bank shl 4)+8); }
      __UMC:modinx(SEQ,6,$F,bank);
   __Weitek:modreg($3CD,$F0,bank shl 4);
  end;
end;


procedure vesamodeinfo(md:word;var vbedata);
const
  width :array[$100..$11b] of word=
      (640,640,800,800,1024,1024,1280,1280,80,132,132,132,132
      ,320,320,320,640,640,640,800,800,800,1024,1024,1024,1280,1280,1280);
  height:array[$100..$11b] of word=
      (400,480,600,600, 768, 768,1024,1024,60, 25, 43, 50, 60
      ,200,200,200,480,480,480,600,600,600, 768, 768, 768,1024,1024,1024);
  bits  :array[$100..$11b] of byte=
      (  8,  8,  4,  8,   4,   8,   4,   8, 0,  0,  0,  0,  0
      , 15, 16, 24, 15, 16, 24, 15, 16, 24,  15,  16,  24,  15,  16,  24);

  swidth :array[0..$13] of word=
     ( 40, 40, 80, 80,320,320,640, 80,0,0,0,0,0,320,640,640,640,640,640,320);
  sheight:array[0..$13] of word=
     ( 25, 25, 25, 25,200,200,200, 25,0,0,0,0,0,200,200,350,350,480,480,200);
  sbytes :array[0..$13] of word=
     ( 80, 80,160,160, 80, 80, 80,160,0,0,0,0,0, 40, 80, 80, 80, 80, 80,320);
  sbits  :array[0..$13] of byte=
     (  1,  4,  1,  4,  2,  2,  1,  1,0,0,0,0,0,  4,  4,  1,  4,  1,  4,  8);
  smode  :array[0..$13] of byte=
     (  0,  0,  0,  0,  1,  1,  1,  0,0,0,0,0,0,  3,  3,  3,  3,  3,  3,  4);

var
  vbxx:_vbe1;
  vbe1:^_vbe1;
begin
  if @vbedata=NIL then vbe1:=@vbxx
                  else vbe1:=@vbedata;
  fillchar(vbe1^,sizeof(_vbe1),0);
  viop($4f01,0,md,0,vbe1);
  if rp.ax=$4F then
  begin
    if ((vbe1^.attr and 2)=0) then
      if (md>=$100) and (md<=$11b) then  { optional info missing }
      begin
        vbe1^.width :=width[md];
        vbe1^.height:=height[md];
        vbe1^.bits  :=bits[md];
      end;

    if (md>=0) and (md<=$13) then  {Standard VGA modes - Many VESAs screw
                                    up these modes, so always force them!!}
    begin
      vbe1^.width :=swidth[md];
      vbe1^.height:=sheight[md];
      vbe1^.bytes :=sbytes[md];
      vbe1^.bits  :=sbits[md];
      vbe1^.model :=smode[md];
      vbe1^.gran:=64;
    end;

    vgran :=vbe1^.gran;
    bytes :=vbe1^.bytes;
    pixels:=vbe1^.width;
    lins  :=vbe1^.height;
  end;
end;


procedure initxga;
var xbe1:_xbe1;
  x:word;
begin
  outp(cv.IOAdr+1,1);     {64K aperture at A000h}
  clrreg(cv.IOadr+9,8);   {Intel pixel format}

  x:=(bytes*8) div usebits[memmode];

  if pixels=1280 then setinx(cv.IOadr+10,$6D,$C);

  mem [cv.xseg:$12]:=1;
  meml[cv.xseg:$14]:=cv.phadr;
  memw[cv.xseg:$18]:=x-1;
  memw[cv.xseg:$1A]:=lins-1;
  case memmode of
   _pk4:x:=2;
    _p8:x:=3;
   _p16:x:=4;
   _p24:x:=5;  {Only AGX?}
  end;
  mem [cv.xseg:$1C]:=x;
  meml[cv.xseg:$50]:=$FFFFFF;  {Enable all planes}
  meml[cv.xseg:$54]:=$FFFFFF;  {Enable all carry planes}
end;

function safemode(md:word):boolean;
var x,y:word;
begin                 {Checks if we entered a Graph. mode}
  safemode:=false;
  wrinx(crtc,$11,0);
  wrinx(crtc,1,0);
  vio(lo(md));
  if (rdinx(crtc,1)<>0) or (rdinx(crtc,$11)<>0) then
  begin
    if (md<=$13) or (mem[Seg0040:$49]<>3) then safemode:=true;
  end;
end;

procedure setdacpal(r,g,b:word);
begin
  outp($3C9,r);
  outp($3C9,g);
  outp($3C9,b);
end;

function tsvio(ax,bx:word):boolean;   {Tseng 4000 Hicolor mode set}
begin
  rp.bx:=bx;
  vio(ax);
  tsvio:=(rp.ax=16);
end;

  {ATI mode set}
function setATImode(md:word):boolean;
begin
  rp.bx:=$5506;
  rp.bp:=$ffff;
  rp.si:=0;
  vio($1200+md);
  if rp.bp=$ffff then setATImode:=safemode(md)  {Try normal modeset}
  else begin
    vio(md);
    setATImode:=true;
  end;
end;

procedure SetRGBPal(inx,r,g,b:word);
var i,j:word;
begin
  if inp($3C6)=0 then;  {delay}
  outp(setDACpage(dacSTDwrInx),inx);
  if inp($3C6)=0 then;  {delay}
  inx:=setDACpage(dacSTDpelData);
  if inp($3C6)=0 then;
  outp(inx,r);
  if inp($3C6)=0 then;
  outp(inx,g);
  if inp($3C6)=0 then;
  outp(inx,b);
  clearDACpage;
end;


  {Halfs all the Horizontal CRTC timings (3d4h index 0/5)}
procedure HalfCRTC;
var r0,r1,r2,r3,r4,r5,old:integer;
begin
  old:=rdinx(crtc,$11);
  clrinx(crtc,$11,$80);
  r0:=rdinx(crtc,0)+5;
  r1:=rdinx(crtc,1)+1;
  r2:=rdinx(crtc,2);
  r3:=rdinx(crtc,3) and $1F;
  r4:=rdinx(crtc,4);
  r5:=rdinx(crtc,5) and $1F;
  if (rdinx(crtc,5) and $80)>0 then inc(r3,$20);
  r3:=(r2 and $FFC0)+r3;
  if r3<=r2 then inc(r3,$40);
  r5:=(r4 and $FFE0)+r5;
  if r5<=r4 then inc(r5,$20);

  r0:=r0 div 2;
  r1:=r1 div 2;
  r2:=r2 div 2;
  r3:=r3 div 2;
  r4:=r4 div 2;
  r5:=r5 div 2;
  if r3>=r0-1 then dec(r3);
  wrinx (crtc,0,r0-5);
  wrinx (crtc,1,r1-1);
  wrinx (crtc,2,r2);
  modinx(crtc,3,$1F,r3);
  wrinx (crtc,4,r4);
  modinx(crtc,5,$1F,r5);
  modinx(crtc,5,$80,r3 shl 2);
  wrinx(crtc,$11,old);
end;

const
  MachActive:boolean=false;
var
  tst:word;

function SetMode(md:word;clear:boolean):boolean;
const
  Red:  array[0..15] of byte=(0, 0, 0, 0,42,42,42,42,21,21,21,21,63,63,63,63);
  Green:array[0..15] of byte=(0, 0,42,42, 0, 0,21,42,21,21,63,63,21,21,63,63);
  Blue: array[0..15] of byte=(0,42, 0,42, 0,42, 0,42,21,63,21,63,21,63,21,63);

var x,y,prt:word;
  l2,l:longint;
  vbe1:_vbe1;
begin
  setmode:=true;
  dacHWcursor:=((cv.features and ft_cursor)=0) and ((DACflags and DFL_Cursor)>0);
  curmode:=md;
  if ((cv.flags and FLG_StdVGA)>0) and (md<=$13) then
    for x:=1 to novgamodes do
      if stdmodetbl[x].md=md then
      begin
        memmode:=stdmodetbl[x].memmode;
        bytes  :=stdmodetbl[x].bytes;
        pixels :=stdmodetbl[x].xres;
        lins   :=stdmodetbl[x].yres;
      end;

  case cv.chip of
	__ati:begin
                clrinx(cv.IOadr,$B3,$40);   {Mach64 doesn't clear this}
                setmode:=setATImode(md);
              end;
     __Mach32:begin
                cv.IOadr:=$1CE;
                if MachActive then
                begin
                  outp($42EE,0);
                    {mov ax,0 call c000h:64h  mov al,0  call C000h:68h}
	          inline($B8/>0/$9A/>$64/>SegC000/$B0/0/$9A/>$68/>SegC000);
                  MachActive:=false;
                  clrinx(cv.IOadr,$B6,1);
                  clrinx(cv.IOadr,$BE,8);
                end;
		if md>=$100 then
		begin
		  {mov ax,[BP+md]  mov bx,1  call C000h:64h  mov al,1  call C000h:68h}
		  inline($8B/$46/<md/$BB/>1/$9A/>$64/>SegC000/$B0/1/$9A/>$68/>SegC000);
		  setmode:=true;

                  case memmode of
                   _pk4b:bytes:=((pixels+127) and $FF80) div 2;
 		     _p8:bytes:=(bytes+127) and $FF80;
               _p15,_p16:bytes:=((pixels+127) and $FF80)*2;
                    _p24:bytes:=((pixels+127) and $FF80)*3;
                  end;
		  outp($5EEE,inp($5EEE) and $FC);   {Disable Memory Aperture}
                  outp($42EE,0);
                  inline($B8/>$62/$CD/$10);
                  setinx(cv.IOadr,$B6,1);
                  setinx(cv.IOadr,$BE,8);
                  MachActive:=true;
		end
		else setmode:=safemode(md);
	      end;
     __Mach64:begin
                if MachActive then
                begin
                  vio($100);
                    {mov al,1  mov cl,0  CALL C000h:64h}
                  inline($B0/0/$B1/1/$9A/>$64/>SegC000);
                  MachActive:=false;
                end;

                  {mov al,0  mov cx,[BP+md]  CALL C000h:64h}
                inline($B0/0/$8B/$4E/<md/$9A/>$64/>SegC000);
                VIO($E2);     {Set VGA mode}
                setreg($6AEC,4);
                  {mov al,1  mov cl,1  CALL C000h:64h}
                inline($B0/1/$B1/1/$9A/>$64/>SegC000);
                MachActive:=true;
                setmode:=true;
                case colbits[memmode] of
                  15:setmode:=setdac15;
                  16:setmode:=setdac16;
                  24:if memmode>=_P32 then setmode:=setdac32
                                      else setmode:=setdac24;
                else setmode:=true;
                end;
              end;
     __compaq:begin
		setmode:=safemode(md);      {HM, what a hack}
		if memmode=_p16 then setmode:=setdac16;
                 {outp($13C8,$38); {Force 64Kcolors}
	      end;
     __everex:begin
		rp.bl:=md;
		vio($70);
	      end;
     __Matrox:if (md>$13) then
              begin
                vio($BD00+md);
                if rp.ax<>-1 then setmode:=true;
              end
              else setmode:=safemode(md);
        __oak:if safemode(md) then
		case memmode of
		  _p15:setmode:=setdac15;
		  _p16:setmode:=setdac16;
		  _p24:setmode:=setdac24;   {Hm}
		end
	      else setmode:=false;
	 __s3:if md<$100 then setmode:=safemode(md)
	      else begin
		rp.bx:=md;
		vio($4f02);
		if rp.ax=$4f then
		begin
		  if md<$200 then vesamodeinfo(md,vbe1);
		  if (memmode=_p16) and setdac16 then;
		end
		else begin
		  setmode:=false;
		  dac2comm;
		  outp($3C6,0);
		  dac2pel;
		end;
	      end;
    __AGX,__Poach,
       __trid:if cv.version>=TR_GUI9420 then setmode:=safemode(md)
              else begin
		vio(md);
		if (rp.ah>=$80) then setmode:=false;
                if (cv.version=TR_9000i) then
  		  case memmode of   {9000i doesn't set HiColor modes}
		    _p15:if not setdac15 then setmode:=false;
		    _p16:if not setdac16 then setmode:=false;
		  end;
	      end;
      __Tseng:case hi(md) of
		0:setmode:=safemode(md);
		1:if tsvio($10E0,lo(md)) then
		  begin
		    {Diamond SpeedStar 24 does not clear memory}
		    for x:=0 to 15 do         {clear memory}
		    begin
		      setbank(x);
		      mem[SegA000:0]:=0;
		      fillchar(mem[SegA000:1],65535,0);
		    end;
		  end else setmode:=false;
		2:if tsvio($10f0,md shl 8+$ff) then
		  begin
		    if bytes=2048 then
		    begin         {Bug correction for the MEGAVGA BIOS}
		      outp($3bf,3);
		      outp(crtc+4,$a0);   {enable Tseng 4000 Extensions}
		      wrinx(crtc,$13,0);
		      setinx(crtc,$3f,$80);
		    end
		  end else setmode:=false;
		3:if tsvio($10F0,lo(md)) and setdac15 then

		  else setmode:=false;
		4:if tsvio($10F0,lo(md)) and setdac16 then
		  else setmode:=false;
		5:if not tsvio($10f0,md) then setmode:=false;
	      end;
     __video7:begin
		rp.bl:=md;
		vio($6f05);
	      end;
       __vesa:begin
                vesamodeinfo(md,vbe1);
		rp.bx:=md;
		vio($4f02);
		if rp.ax<>$4f then setmode:=false
		else begin
		 { vesamodeinfo(md,NIL);}
		  cv.chip:=__vesa;
		end;
	      end;
	__UMC:begin
                outp($3BF,$AC);
                case memmode of
                  _p15:clrinx(GRC,$A,4);
                  _p16:setinx(GRC,$A,4);
                end;

		setmode:=safemode(md);
                if cv.version=UMC_408 then
  	          case memmode of
                    _p15:setmode:=setdac15;
                    _p16:setmode:=setdac16;
                  end;
                if md=$51 then clrinx(SEQ,9,$80);
	      end;
         __WD:if (md=$13) and (cv.version=WD_90c33) then
              begin
                vio($5E);
                clrinx(GRC,$E,1);
                wrinx(crtc,$13,40);   {320 bytes/linbe}
                setinx(crtc,9,1);     {Double line}
              end
              else setmode:=safemode(md);
	__xbe:begin
		viop($4E03,md,0,cv.id,NIL);
		if rp.ax<>$4E then setmode:=false;
	      end;
  else setmode:=safemode(md);
  end;

  if (inp($3CC) and 1)=0 then crtc:=$3B4 else crtc:=$3D4;  {Mono/Color}
  case colbits[memmode] of
    8:begin
        if dacis8bit then prt:=4 else prt:=1;
        for x:=0 to 63 do
        begin
          y:=x*prt;
          SetRGBPal(x    ,y,0,0);    {  0- 63: Red}
          SetRGBPal(x+64 ,0,y,0);    { 64-127: Green}
          SetRGBPal(x+128,0,0,y);    {128-191: Blue}
          SetRGBPal(x+192,y,y,y);    {192-255: White}
        end;
        SetRGBPal(0,0,0,0);  {Some cards screw up the first palette entry}
      end;
    4:for x:=0 to 15 do
      begin
        SetRGBPal(x,Red[x],Green[x],Blue[x]);
        if (cv.flags and FLG_StdVGA)>0 then wrinx($3C0,x,x);
      end;
  end;
  case (rdinx(GRC,6) shr 2) and 3 of
    0,1:vseg:=SegA000;
      2:vseg:=SegB000;
      3:vseg:=SegB800;
  end;


   { Enable banks...  }

 { if memmode>_CGA2 then}
  case cv.chip of
	__AGX:if memmode>=_PL4 then
	      begin
		modinx(GRC,6,$C,4);
		cv.spcreg:=$1E0-(((rdinx(cv.IOadr+10,$75) and 7)-1) shl 4);
                initxga;
	      end;
      __ahead:begin
		setinx(GRC,$F,$20);
		if (memmode>_cga2) {and (md<>$13)} then setinx(GRC,$C,$20);
                if md=$13 then
                begin
                  HalfCRTC;
                  wrinx(crtc,$13,20);
                  setinx(GRC,$E,1);    {Switches from clock 8 (50.35MHz) to
                                        clock 12 (25.175MHz) - pure luck!!!}
                  clrinx($3C0,$10,$40);
                end;
	      end;
	__ALG:begin
		setinx(crtc,$1A,$10);    {Enable extensions}
		setinx(crtc,$19,2);      {Enable >256K}
		setinx(GRC,$F,4);        {Enable RWbank}
	      end;
       __Alli:begin
                wrinx(SEQ,$10,$12);
                clrinx(SEQ,$1C,$F);
              end;
        __ARK:begin
                setinx(SEQ,$1D,1);    {Enable extensions}
                clrinx(crtc,$31,1);   {256K wrap}
                clrinx(crtc,$43,8);
                case colbits[memmode] of
                  15,16:x:= 8;
                  24,32:x:=12;
                else    x:= 4;
                end;
                modinx(SEQ,$11,$C,x);
                case pixels of
                  800:x:=1;
                 1024:x:=2;
                 1280:x:=4;
                else x:=0;
                end;
                modinx(SEQ,$17,7,x);
                setinx(SEQ,$10,3);    {Enable all of Vmem}
              end;
	__ati:if memmode>_CGA2 then
              begin
                if cv.version>=ATI_M64_GX then
                begin
                  setinx(cv.IOadr,$B0,8);
                  clrreg($6AEC,7);
                end;
		if cv.version>=ATI_28800_4 then
		  setinx(cv.IOadr,$B6,1);    {enable display >256K}
                if cv.version>=ATI_18800_1 then
                  clrinx(cv.IOadr,$B3,$10);  {enable display >256K}
                if (cv.Version>=ATI_18800_1) {and (cv.version<ATI_GUP_3)} then
                begin
                  if ((rdinx(cv.IOadr,$B6) and $10)=0) and ((memmode=_pl4)
                    or (md=$13)) then
                  begin
                    if md=$13 then  {Fix mode 13h}
                    begin
                      setinx(crtc,$17,$40);
                      clrinx(crtc,$14,$40);
                      clrinx(GRC,5,$40);
                      clrinx($3C0,$10,$40);
                      setinx(SEQ,1,8);
                      if (cv.version=ATI_18800_1) then
                      begin
                        setinx(cv.IOadr,$B0,$30);
                      end
                      else begin
                        setinx(cv.IOadr,$B0,$20);
                        setinx(cv.IOadr,$B6,4);   {Linear addressing}
                      end;
                    end
                    else begin {16color modes (planar)}
                      setinx(cv.IOadr,$B3,$40);
                      setinx(cv.IOadr,$B6,$18);
                    end;
                    HalfCRTC;
                    wrinx(crtc,$13,rdinx(crtc,$13) div 2);
                    if (md=$D) and (cv.version<ATI_M64_GX) then {Mode 0Dh - Arghh}
                    begin
                      clrinx(SEQ,1,8);    {Switch from /4 to /3 - Arghh}
                      modinx(cv.IOadr,$B8,$C0,$80);  {--}
                      clrinx(crtc,$11,$80);  {Allow CRTC reprogramming}
                      wrinx(crtc,0,$19);
                      wrinx(crtc,3,$96);     {Reprogram Horizontal Timing}
                      wrinx(crtc,4,$17);
                    end;
                  end;
                end;
		if cv.version>ATI_18800 then
		  setinx(cv.IOAdr,$BE,8);    {enable RWbanks}
	      end;
      __chips:begin
		if cv.version<CT_450 then
		begin
		  prt:=$46E8;
		  x:=inp(prt);
		  outp(prt,x or $10);     {setup mode}
		  y:=inp($103);
		  outp($103,y or $80);    {Enable extensions}
		  outp(prt,x and $EF);
		  if (y and $40)=0 then cv.IOadr:=$3D6 else cv.IOadr:=$3B6;
		end
                else cv.IOadr:=$3D6;
		wrinx(cv.IOadr,$15,0);  {No write protection}
                clrinx(cv.IOadr,$14,1); {This bit, if set needs explicit clearing}
                setinx(cv.IOadr,$B,1);  {Enable banks}
		if memmode>_cga2 then
		begin
		  setinx(cv.IOadr,4,4);  {Enable bank access}
		  case cv.version of
		    CT_450,CT_452,CT_453:
			begin
			  modinx(cv.IOadr,$B,3,1);
			  clrinx(cv.IOadr,$C,3);
			end;
		    CT_65510,CT_65520,CT_65530:
			begin
			  setinx(cv.IOadr,4,8);
			  modinx(cv.IOadr,$B,3,1);
			  clrinx(cv.IOadr,$C,3);
			end;
               CT_64300:clrinx(cv.IOadr,$B,$10);
		  end;
		  if md=$13 then
		  begin
		    setinx(cv.IOadr,$B,4);   {By 4 addressing}
		    setinx(crtc,$17,$40);
		    clrinx(crtc,$14,$40);
		  end;
		end;
	      end;
      __cir54:begin
		wrinx(SEQ,6,$12);    {Enable Extensions}
		setinx(crtc,$1B,2);      {Enable mem >256K}
		if cv.mm>1024 then
		begin
		  setinx(GRC,11,$20);    {Set 16K banks}
		  setinx(SEQ,$f,$80);    {Enable Ext mem}
		end;
                if md=$13 then
                begin
                  setinx(SEQ,7,1);      {Extended Graph mode}
                  setinx(SEQ,1,8);      {Half VClk rate =12.6MHz}
                  {setinx(crtc,$1B,$20);} {Blanking Ctl ??}

                  HalfCRTC;
                end;
                if (cv.Version>=CL_GD5426) and (memmode>_pl4)
                  and (md<>$13) then    {Init BitBlt engine}
                begin
                  wrinx2(GRC,$24,bytes);
                  wrinx2(GRC,$26,bytes);
                  case memmode of
             _p15,_p16:x:=$10;
                  _P32:x:=$30;    {543x only}
                  else x:=0;
                  end;
                  wrinx(GRC,$30,x);
                  setbank(cv.mm div 64-1);   {Setup Mono image for Fill}
                  meml[SegA000:$FFF8]:=$FFFFFFFF;  {Fill Pattern}
                  meml[SegA000:$FFFC]:=$FFFFFFFF;
                end;
	      end;
      __cir64:begin
		wrinx(GRC,$A,$EC);       {Enable extensions}
		if memmode>_cga2 then setinx(GRC,$D,7);
	      end;
     __compaq:begin
		modinx(GRC,$F,$F,5);  {Enable extensions}
		setinx(GRC,$10,8);
                if memmode>=_PL4 then
                begin
                  if rdinx(GRC,$F)<>$A5 then
                  begin
                    setreg($23C7,$10);
                    if pixels>1024 then
                    begin
                      modreg($63CB,$C,8);
                      bytes:=256*usebits[memmode];
                    end
                    else if pixels>512 then
                    begin
                      modreg($63CB,$C,4);
                      bytes:=128*usebits[memmode];
                    end
                    else begin
                      modreg($63CB,$C,0);
                      bytes:=64*usebits[memmode];
                    end;
                    wrinx(crtc,$13,bytes shr 3);
                    modinx(GRC,$42,3,bytes shr 11);
                  end;
                  if ((md<>$13) or (cv.version=CPQ_AVGA))
                    and (memmode>=_P8) then setinx(GRC,$40,$1);
                  dacHWcursor:=(DACflags and DFL_cursor)>0;
                end;
	      end;
      __Genoa:begin
		setinx(SEQ,8,$40);    {Ext Addressing}
		setinx(SEQ,$10,4);    {RWbank}
	      end;
	__HMC:if memmode>=_cga2 then
	      begin
		if memmode=_pl4 then
		begin
		  setinx(SEQ,$E7,$4);
		  clrinx(GRC,6,$C);
		end;
                if (memmode=_P8) and ((rdinx(SEQ,$E7) and 2)=0) then
                begin   {Fix mode 13h}
                  HalfCrtc;
                  setinx(SEQ,$E7,2);
                  clrinx(GRC,5,$40);
                  clrinx($3C0,$10,$40);
                  setinx(SEQ,1,8);
                end;
       	      end;
     __Mach32:begin
                outpw($DAEE,0);     {Clipping}
                outpw($E2EE,2047);
                outpw($DEEE,0);
                outpw($E6EE,2047);
                outpw($6EEE,0);     {GE Offset}
                outpw($72EE,0);
                outpw($EEEE,0);     {Disable Color Compare}
                outpw($AAE8,$FFFF); {Write Mask}
                tst:=inpw($8EEE);
              end;
     __Mach64:begin
                modreg($6AEC,7,4);
                mem[cv.Xseg:$C5]:=(mem[cv.Xseg:$C5] and $DF); {non-VGA DAC}
                setreg($4EEE,$A0);  {Reset GUI engine}
                outpw($66EC,0);
                outpw($66EC,$100);

                write32($338,0);  {GUI_STAT (needed for PCI)}
                write32($310,0);  {FIFO_STAT}

                outp($4EEE,$FF);    {BUS_CNTL: Clear FIFO errors}

                outpl($66EC,0);
                outpl($66EC,$100);

                repeat until memw[cv.Xseg:$310]=0;
                case usebits[memmode] of
                   4:l:=$10101;
                   8:l:=$20202;
                  15:l:=$30303;
                  16:l:=$40404;
                  24:l:=$50505;   {Hm?}
                  32:l:=$60606;
                end;
                write32($2D0,l);           {Pixel Width}
                write32($320,$FFFFFFFF);   {Context MAsk}
                write32($108,0);
                write32($118,0);
                write32($124,0);
                write32($128,0);
                write32($12C,0);
                write32($130,3);

                write32($18C,0);   {Src Y_X}
                write32($198,0);
                write32($1A4,0);
                write32($1B0,0);
                write32($1B4,0);

                repeat until memw[cv.Xseg:$310]=0;
                write32($240,0);
                write32($280,0);
                write32($284,0);
                write32($288,0);
                write32w($2A8,pixels-1,0);  {Clip left/right}
                write32w($2B4,lins-1,0);    {Clip top/bot}
                write32($2C0,0);
                write32($2C4,0);
                write32($2C8,$FFFFFFFF);   {Write mask}
                write32($2D4,$70003);      {DP_MIX}
                write32($2D8,$100);        {Source}

                write32($300,0);
                write32($304,$FFFFFFFF);   {Color Cmp Mask}
                write32($308,0);           {Color Cmp off}
                write32($330,3);           {GUI trajetory}

                repeat until memw[cv.Xseg:$310]=0;
                l:=longint(pixels shr 3) shl 22;
                write32($100,l);    {Dest Offset & pitch}
                write32($180,l);
                repeat until (mem[cv.Xseg:$338] and 1)=0;
              end;
     __Matrox:begin
                if md=$13 then   {The mode is redefined, but with a 62kHz Hsync!}
                begin
                  setinx($3DE,1,9);   {Ext 256color & enable banks}
                  HalfCRTC;
                  wrinx(crtc,$13,20);
                end;
              end;
       __mxic:begin
		setinx(SEQ,$65,$40);
		wrinx(SEQ,$A7,$87);    {enable extensions}
		setinx(SEQ,$C3,4);     {Enable banks}
		setinx(SEQ,$F0,8);     {Enable display >256k}
	      end;
	__ncr:begin
		wrinx(SEQ,5,1);
		wrinx(SEQ,$18,0);
		wrinx(SEQ,$19,0);
		wrinx(SEQ,$1C,0);
		wrinx(SEQ,$1D,0);
		setinx(SEQ,$1E,$1C);
                if cv.version<NCR_77c32blt then
                begin
                  wrinx(SEQ,5,5);
                  wrinx(SEQ,$1A,0);
                  wrinx(SEQ,$1B,0);
                end;
                if md=$13 then
                begin
                  setinx(SEQ,$20,2);
                  setinx(SEQ,$21,1);
                  clrinx(GRC,5,$40);
                  clrinx(SEQ,4,8);
                  clrinx($3C0,$10,$40);
                  setinx(crtc,$17,$40);
                  clrinx(crtc,$14,$40);
                  setinx(SEQ,$1F,$10);
                  setinx(SEQ,1,8);
                end;
                if (cv.version=NCR_77c32BLT) and (memmode>=_PL4) then
                begin
                  wrinx3(SEQ,$31,$0b00);
                  setinx(SEQ,$30,1);      {ACM at BFF0:0}
                  case memmode of
                    _P15,_P16:x:=$10;
                   _P24,_P24b:x:=$20;
                  else x:=0;
                  end;
                  modinx(SEQ,$21,$30,x);  {Pixel Width}
                  cv.Xseg:=SegB000;
                end;
	      end;
	__oak:if cv.version<>OAK_037 then
              begin
		if (memmode>=_pl4) and (cv.mm>256) then
                begin
                  if (md<>$13) and (cv.Version<=OAK_083) then setinx($3DE,$D,$C);
                  if (memmode=_pl4) then setinx($3DE,$D,$10);
                end;
	       { if md=$13 then
		begin
		  wrinx(crtc,$14,0);
		  wrinx(crtc,$13,20);
		  wrinx(crtc,$17,$c3);
		  setinx($3DE,$21,5);
                  HalfCRTC;
		end;  Creates a 320x200 mode without 64K limitations
			however there is no pixel doubling, creating a
			"double screen"  }
	      end;
         __WD:begin
		modinx(GRC,$F,$17,5); {Enable extensions PR0-4}
		wrinx(crtc,$29,$85);  {Enable extensions 2}
		wrinx(SEQ,6,$48);     {Enable extended sequencers}
		clrinx(GRC,$B,8);
		if (md<>$13) or (cv.version<>WD_90c33) then clrinx(crtc,$2F,2);
                clrinx(crtc,$2F,$78);
		setinx(SEQ,$11,$80);  {enable dual bank}
                if (cv.Version=WD_90c33) and (memmode>=_pl4) then
                begin
                {  while (inpw($23CE) and $F)>0 do; }
                  outpw($23C0,3);    {Drw Eng Bank 2}
                  outpw($23C2,0);           {Map BAse}
                  outpw($23C2,$1000+pixels); {Row Pitch}
                  outpw($23C2,$AFFF);       {Enable all planes}
                  outpw($23C2,$BFFF);
                  outpw($23C0,1);        {Drw Eng Bank 1}
                  case memmode of
                     _pl4:outpw($23C2,$1000);
                      _p8:outpw($23C2,$1400);
                _p15,_p16:outpw($23C2,$1800);
                  end;
                  outpw($23C2,$9000);
                  outpw($23C2,$A000+pixels);
                  outpw($23C2,$B000);
                  outpw($23C2,$C000+lins);      {Set Clip}
                  outpw($23CE,$20);
                  while (inpw($23CE) and $F)>0 do;
                  outpw($23C2,0);

                end;
	      end;
      __p2000:begin
		if memmode=_p16 then
		begin
		  dac2comm;
		  outp($3C6,$C0);
		end;
	      end;
    __realtek:begin
		if memmode>=_pl1 then setinx(crtc,$19,$A2);   {display from upper 512k}
	       { setinx(GRC,$C,32); }
		setinx(GRC,$F,4);       {dual bank}
	      end;
	 __s3:if memmode>_CGA2 then
	      begin
                if cv.Version<S3_864 then S3accelOff;
		wrinx(crtc,$38,$48);
		wrinx(crtc,$39,$A5);
		modinx(crtc,$31,$39,9);   {Enable access >256K & banking}
                wrinx(crtc,$4E,0);    {zero cursor offset}
                wrinx(crtc,$4F,0);
		clrinx(crtc,$45,$3D);     {Cursor type}

                if bytes=800 then  {800x600 P8 appears busted in acc.}
                begin              {modes on the STB Pegasus, so fixit..}
                  bytes:=1024;
                  wrinx(crtc,$13,128);
                end;
		if cv.version>S3_924 then
		begin
 		  clrinx(crtc,$55,$30);     {Force MS-Windows cursor & int. DAC}
                  case memmode of
		 _p15,_p16:begin
                             if cv.version<S3_864 then
			       setinx(crtc,$45,4);  {16bit cursor pixels}
			     x:=$10;
			   end;
		 _p24,_p32:begin
                             if cv.version<S3_864 then
			       setinx(crtc,$45,8)   {32bit cursor pixels}
			     else
                               setinx(crtc,$45,4);  {16bit cursor pixels}
			     x:=$30;
			   end;
                  else x:=0;
		  end;
                  case (bytes*8) div usebits[memmode] of
                    640:x:=x+$40;
                    800:x:=x+$80;
                   1280:x:=x+$C0;
                   1152:x:=x+$01;   {1152/1600 do not work on 801/5 A/B & 928 A-D}
                   1600:x:=x+$81;
                  end;
                  modinx(crtc,$50,$F1,x);     {8bpp & 640/800/1024/1280 pixels/line}
                  if ((rdinx(crtc,$55) and 8)>0)
                   or ((cv.version>=S3_864) and ((rdinx(crtc,$65) and 2)>0)) then
                  begin                   {Piping VRAM directly to the DAC,
                                         internal cursor will NOT work}
                    dacHWcursor:=true;
                    setinx(crtc,$45,$20);    {Ext DAC Ctrl enable}
                    setinx(crtc,$55,$20);    {Enable Ext HW cur}
                  end;
                end;
                clrinx(crtc,$34,$80);     {allow Clock change}
		wrinx(crtc,$39,$5A);
		wrinx(crtc,$38,0);
	      end;
        __SiS:begin
                outpw(SEQ,$8605);
                setinx(SEQ,$B,8);   {Set 3CDh as Write bank, 3CBh as read}
                if memmode>_CGA2 then setinx(SEQ,6,2);  {Enable banks}
                if md=$13 then
                begin
                  clrinx($3C0,$10,$40);
                  setinx(SEQ,1,8);
                  HalfCRTC;
                end;
              end;
      __Poach,
       __trid:if memmode>_CGA2 then
	      begin
		setinx(crtc,$1E,$80);   { Enable 17bit display start }
		if (cv.Version=TR_8900C) or (cv.version>=TR_9000C) then
                begin
                  if (cv.mm>512) then
		  begin
		    wrinx(SEQ,$B,0);
		    x:=inp(SEQ+1);    {Switch to new mode}
		    x:=rdinx(SEQ,$E);
		    wrinx(SEQ,$E,$80);
		    setinx(SEQ,$C,$20);
		    wrinx(SEQ,$E,x);
                  end;
		  if cv.version<>TR_8900C then
		    setinx(GRC,$F,5);  {Enable ?? & Read/Write}
		end;
		if cv.version<>TR_8800BR then modinx(GRC,6,$C,4);
                if cv.version>=TR_GUI9440 then
                   wrinx(crtc,$36,$82);
	      end;
      __Tseng:begin
                outp($3BF,3);
                outp(crtc+4,$A0);
                case cv.version of
	      ET_3000:begin
			setinx(SEQ,4,2);
                        if (((md=$13) or (memmode=_PL4)) and (md<>$D)
                          and ((rdinx(SEQ,7) and $40)=0)) then
                        begin
                          HalfCRTC;
			  wrinx(crtc,$13,rdinx(crtc,$13) div 2);
                          if md=$13 then
                          begin
                            clrinx(crtc,$14,$40);
                            clrinx(SEQ,4,8);
                            wrinx(crtc,$17,$C3);
                          end
                          else for x:=0 to 15 do wrinx($3C0,x,x);
			  setinx($3C0,$16,$10);
			  clrinx(crtc,$11,$80);
			  setinx(SEQ,7,$40);
                        end;
		      end;
	      ET_4000:if (cv.dactype=_dacMU1880) and (memmode=_p24) then memmode:=_P24b;
	        else if memmode>=_pl4 then
                begin  {W32 series}
		  setinx(crtc,$36,$28);   {Enables MMU registers}
		  if vseg=SegA000 then cv.Xseg:=SegB800  {setup accelerator MMU}
			          else cv.Xseg:=SegA800;
                          {The 32K at either A800 or B800 is divided into
                           4 ranges: Offset 7F00h-7FFFh holds the memory
                           mapped registers, 4000h-5FFFh is controlled by MMU2
                           and is used to transfer CPU data, 2000h-3FFFh is
                           controlled by MMU1 and holds the Pattern data }
                  mem [cv.xseg:$7F30]:=0;
                  mem [cv.xseg:$7F30]:=$10;
                  while (mem [cv.xseg:$7F36] and 2)>0 do;
                  mem [cv.xseg:$7F30]:=0;

		  mem [cv.xseg:$7F35]:=$E; {clear Interrupts}
		  memw[cv.xseg:$7F34]:=$0; {Disable Interrupts}
		  mem [cv.xseg:$7F36]:=0;
		  mem [cv.xseg:$7F9D]:=0;    {Reload Off}
		  mem [cv.xseg:$7F32]:=1;    {Wait for Queue'd register to clear}

                  if cv.Version>=ET_4W32p_a then
                  begin
                    mem[cv.xseg:$7F8E]:=0;  {Pixel Depth - 8bit}
                    mem[cv.xseg:$7F31]:=$10;  {Startup}
                  end
                  else begin
                    write32($7F94,0);
                    {meml[cv.xseg:$7F94]:=0; {Reset X,Y position}
                    mem [cv.xseg:$7F31]:=0;
                  end;
                  l:=cv.mm*longint(1024)-8 {4};

                  write32($7F00,l);
                  write32($7F80,l);
                  {meml[cv.xseg:$7F00]:=l;    {Adr of pattern in Vmem}
                     {Had some trouble with two word writes failing to update
                      the full longword, thus the move() -> rep movsb}
                  l:=meml[cv.xseg:$7F00];
                  write32($7F08,0);
	          {meml[cv.xseg:$7F08]:=0;   {Start of Video Memory}
 	          mem [cv.xseg:$7F13]:=4;   {MM1 -> pattern (color), MM2 -> 0}
                  memw[cv.xseg:$7F88]:=3;         {Pattern Pitch}
                  memw[cv.xseg:$7F8A]:=bytes-1;         {Source Pitch}
                  memw[cv.xseg:$7F8C]:=bytes-1;         {Dest Width}
 	          mem [cv.xseg:$7F90]:=$12;               {4byte x 1line pattern}
 	          mem [cv.xseg:$7F92]:=$77;             {Source don't wrap}
	        end;
                end;
              end;
	__umc:begin
		OUTP($3BF,$AC);     {Enable extensions}
		setinx(SEQ,8,$80);    {Enable banks bit0}
		clrinx(crtc,$2F,$2);  {Enable >256K}
	      end;
     __video7:begin
		wrinx(SEQ,6,$EA);    {Enable extensions}
                if memmode>=_pl4 then
                begin
                  setinx(SEQ,$F6,$C0);  {prevent display wrap}
	  	  if memmode>=_P8 then modinx(SEQ,$FC,6,4); {Enable 256c banks}
                  if (cv.version>=V7_216BC) and (memmode=_P8)
                    and ((rdinx(GRC,5) and $40)>0) then
                  begin     {Force all 256c modes to Ext 256c}
                    clrinx(GRC,5,$40);
                    setinx(SEQ,$C8,$10);
                    modinx($3C0,$10,$C0,$80);
                    setinx(SEQ,1,8);
                    HalfCRTC;
                  end;

                  {if cv.Version>=V7_208A then
   	            setinx(SEQ,$E0,$80);  {Enable Dual bank }
                  if cv.version>=V7_208A then
 		    setinx(SEQ,$FF,$10);   {Enable banks & memory>256K}
                end;
	      end;
     __Weitek:begin
		x:=WeitekEnable(0);
	      end;
  __xbe,__xga:initxga;
  end;
  curbank:=$ffff;    {Set curbank invalid }
  planes:=1;
  setinx(SEQ,4,2);    {Set "more than 64K" flag}

  setvstart(0,0);   {Reset start of display}
  case memmode of
  _text,_txt2,_txt4,
  _pl1e,_pl2:planes:=2;
	_pl4:planes:=4;
  end;
  if clear and (vseg=SegA000) then
  begin
    l:=(cv.mm*longint(1024)-256) shr 1;    {#Words to clear}
    x:=0;                  {Leave a few bytes at the end for patterns etc}
    while (l>0) do
    begin
      setbank(x); inc(x);
      y:=32768;
      if l<y then y:=l;
      dec(l,y);
        {cld  mov cx,[BP+y]  mov ax,0A000  mov es,ax  xor ax,ax  xor di,di  rep stosw}
      inline($FC/$8B/$4E/<y/$B8/>SegA000/$8E/$C0/$31/$C0/$31/$FF/$F3/$AB);
    end;
  end;
  AnalyseMode;
end;


procedure SetTextMode;
begin
  case cv.chip of
      __ATI:clrinx(cv.IOadr,$B3,$40);   {Mach64 doesn't clear this}

   __Mach32:if MachActive then
            begin
              outp($42EE,0);
              {mov ax,0 call c000h:64h  mov al,0  call C000h:68h}
	      inline($B8/>0/$9A/>$64/>$C000/$B0/0/$9A/>$68/>SegC000);
              MachActive:=false;
              clrinx(cv.IOadr,$B6,1);
              clrinx(cv.IOadr,$BE,8);
            end;
  end;

  clearDACpage;
  if (DACflags and DFL_CmdReg)>0 then
  begin
    dac2comm;     {Reset DAC}
    outp($3c6,0);
    dac2pel;
  end;
  if setmode(3,false) then;
  textmode($103);
end;


{const
  set15:array[0..13] of byte=(0,0,$A0,$A0,$A0,$A0,$C1,0,$80,$F0,$A0,0,0,0);
  msk15:array[0..13] of byte=(0,0,$80,$C0,$FF,$E0,$C7,0,$C0,$FF,$E0,0,0,0);

  set16:array[0..13] of byte=(0,0,  0,$E0,$A6,$C0,$C5,0,$C0,$E1,$C0,0,0,0);
  msk16:array[0..13] of byte=(0,0,  0,$C0,$FF,$E0,$C7,0,$C0,$FF,$E0,0,0,0);

  set24:array[0..13] of byte=(0,0,  0,  0,$9E,$E0,$80,0,$60,$E5,$E0,0,0,0);
  msk24:array[0..13] of byte=(0,0,  0,  0,$FF,$E0,$C7,0,$E0,$FF,$E0,0,0,0); }



var
  dacpath:integer;

procedure GetDACpath;
begin
  dacpath:=8;
  case cv.chip of
     __ARK:if (cv.version>=ARK_2000PV) and ((rdinx(crtc,$46) and 4)>0) then dacpath:=16;
      __SC:if (rdinx(GRC,$C) and 3)=3 then dacpath:=16;
   __Tseng:if (cv.version>=ET_4000) and ((rdinx($3C0,$16) and $20)>0) then dacpath:=16;
  end;
end;


function prepDAC:word;     {Sets DAC up to receive command word}
var x:word;
begin
 { dac2comm; }
  {if cv.dactype=_dacss24 then
  begin
    dac2comm;
    x:=8;
    while (x>0) and (daccomm<>$8E) do
    begin
      daccomm:=inp($3C6);
      dec(x);
    end;
    prepDAC:=daccomm;
  end
  else} begin
    prepDAC:=getdaccomm{inp($3C6)};
    dac2comm;
  end;
end;

procedure dacmode(andmsk,ormsk:word);
var x,pel:word;
begin
  ormsk:=ormsk and (not andmsk);
 { if cv.DAC_RS2<>0 then
  begin
    outp($3C6+cv.DAC_RS2,(inp($3C6+cv.DAC_RS2) and andmsk) or ormsk);
  end
  else} begin
    if cv.chip=__cir54 then
    begin
      pel:=inp($3C6);
      outp($3C6,0);
    end;
    x:=getdaccomm{prepDAC};
    dac2comm;
    outp($3C6,(x and andmsk) or ormsk);
    dac2pel;
    if cv.chip=__cir54 then outp($3C6,pel);

  end;
end;



procedure setBt1DAC(mode:word);
begin
{  dac2comm;
  outp($3C6,mode);
  dac2pel;}
  outp(setDACpage(dacBt1cmdA),mode);
 { dacmode(0,mode);}
end;

procedure setSTGdac(mode:word);
var m:word;
begin
  m:=inp(SetDACpage(dacHIcmd));
  outp(SetDACpage(dacHIcmd),m or 16);
  dac2comm;
  m:=inp($3C6);
  outp($3C6,3);
  outp($3C6,0);
  outp($3C6,mode);
  outp($3C6,mode);
  outp($3C6,2);
  dacmode(0,$8);
end;

  {Sets the standard palette mode}
procedure setDACstd;
begin
  case cv.dactype of
  _dac15,_dac16,_dacADAC1,_dacATT490,_dacATT491,_dacATT492,_dacATT493,
  _dacICS5301,_dacSC15021,_dacSC15025,_dacMU1880,_dacMU4870,_dacMU4910,
  _dacMU9910,_dacTR8001,_dacUMC188:
      dacmode(0,0);
  _dacALG1201,_dacALG1301:
      dacmode(0,2);
  _dacATT498,_dacATT1498,_dacATT2498,_dacICW498,_dacICW516:
      if dacpath=8 then dacmode(0,0) else dacmode(0,$20);
  _dacS3_708,_dacS3_716:
      clrreg(SetDACpage(dacHIcmd),$60);
  _dacSTG1700,_dacSTG1702,_dacSTG1703:
      if (inp(SetDACpage(dacHIcmd)) and 8)=0 then dacmode(0,0)
                                             else setSTGdac(5);
  _dacBt481,_dacBt482:
      setBt1DAC(0);
  _dacBt484,_dacBt485,_dacATT504,_dacATT505:
      begin
        modreg(SetDACpage(dacBTcmd1),$78,$40);
        {clrreg(SetDACpage(dacBTcmd2),$20);}
      end;
  _dacCH8391,_dacCH8398:
      dacmode(0,4);
  _dacTVP3010,_dacTVP3020,_dacTVP3025:
      begin
        wrDACreg(dacTVPindex,$18);
        wrDACreg(dacTVPdata,$C6);
        wrDACreg(dacTVPindex,$E);
        setDACreg(dacTVPdata,1);
      end;
  _dacTVP3026:
      begin
        wrDACreg(dacTVP6index,$18);
        wrDACreg(dacTVP6data,$C6);
        wrDACreg(dacTVP6index,$E);
        setDACreg(dacTVP6data,1);
      end;
  _dacATI68860,_dacATI68880:
      outp(setDACpage(11),$83);
  _dacInt:
      case cv.chip of
      __chips:clrinx(cv.IOadr,6,$C);
      __Cir54:dacmode(0,0);
         __WD:clrinx(SEQ,$26,$C);
         __S3:begin
                outpw(crtc,$A039);
                clrinx(crtc,$67,$F0);
                outpw(crtc,$39);
              end;
        __SiS:clrinx(SEQ,6,$1C);
       __Trid:dacmode(0,0);
      end;
  _dacALG1101:
      clrinx(crtc,$19,$10);

    _dac0,_dac8,_dacCEG:;   {not supported/NOP}
  end;
  clearDACpage;
end;

  {Enable DAC Gamma correction}
function setDACgamma(on:boolean):word;
var x:word;
begin
  setDACgamma:=GAM_None;
  case cv.dactype of
    _dacBt484,_dacBt485,_dacATT504,_dacATT505:
        begin
          setDACreg(6,2);   {Enable 8bit LUT}
          setDACreg(9,4);   {Contigous Gamma curve}
          modDACreg(8,$10,$10*ord(not on));
          setDACgamma:=GAM_CanDo+GAM_8bit;
        end;
    _dacSC15021,_dacSC15025:
        begin
          dac2comm;
          x:=inp($3C6);
          outp($3C6,x or $10); {Index}
          outp($3C7,8);
          outp($3C8,1);    {8bit LUT}
          outp($3C6,(x and $F7) or 8*ord(on));   {Gamma}
          dac2pel;
          setDACgamma:=GAM_CanDo+GAM_LeftJ+GAM_Left8+GAM_8bit;
        end;
  end;
end;

  {Turns 8bit DAC mode on or off}
procedure setdac8(on:boolean);
var w,x:word;
begin
  if cv.chip=__VESA then
  begin
    if on then rp.bx:=$800
	  else rp.bx:=$600;
    vio($4F08);
  end
  else
    case cv.dactype of
    _dacALG1201,_dacALG1301:
        dacmode(2,128*ord(on));
    _dacATI68860,_dacATI68880:
        modreg(setDACpage(12),1,1-ord(on));
    _dacATT490,_dacATT491,_dacATT492,_dacATT493,_dacATT498,_dacATT1498,
    _dacATT2498,_dacICW498,_dacICW516,_dacSTG1700,_dacSTG1702,_dacSTG1703,
    _dacCH8391,_dacTr8001:
        dacmode($FD,2*ord(on));   {2:on, 0: off}
    _dacBt477,_dacBt484,_dacBt485,_dacATT504,_dacATT505:
        modreg(setDACpage(dacBTcmd0),2,2*ord(on));
    _dacBt481,_dacBt482:
        begin
          setreg(setDACpage(dacHIcmd),1);  {Indexed}
          outp(setDACpage(dacSTDwrInx),dacBtIcmdB);
          modreg(setDACpage(dacSTDpelMask),2,2*ord(on));
          clrreg(setDACpage(dacHIcmd),1);  {Normal}
        end;
    _dacIBM514,_dacIBM524,_dacIBM525,_dacIBM528:
        begin
        (*  wrDACreg(dacIBMind0,$71);
         { wrDACreg(dacIBMind1,0);}
          modDACreg(dacIBMdata,4,4*ord(on)); * )
          wrDACreg(dacIBMind0,$71);
          x:=rdDACreg(dacIBMdata);
          wrDACreg(dacIBMind0,$71);
          wrDACreg(dacIBMdata,(x and $FB) or 4*ord(on)); *)
        end;
    _dacSC15021,_dacSC15025:
        begin
          dac2comm;
          outp($3C6,$10);
          outp($3C7,8);
          outp($3C8,ord(on)); {1: on, 0: off}
		{outp($3C9,0);  }
          outp($3C6,0);
          dac2pel;
        end;
    _dacTVP3010,_dacTVP3020,_dacTVP3025:
        begin
          wrDACreg(dacTVPindex,$1E);
          modDACreg(dacTVPdata,$C,8*ord(on)+4);
        end;
    _dacTVP3026:
        begin
          wrDACreg(dacTVP6index,$1E);
          modDACreg(dacTVP6data,$C,8*ord(on)+4);
        end;
    else
      case cv.chip of
     __Mach64:modreg($62ED,1,ord(on));
     __Mach32,
	__ati:begin
		w:=inpw($8EEE) and $BFFF;
		if on then w:=w or $4000;
		outpw($7AEE,w);
	      end;
       __Trid:if cv.version>=TR_9200CXr{=TR_GUI9440} then
                dacmode($FD,2*ord(on));   {2:on, 0: off}
                   {dacmode($F7,8*ord(on));   {2:on, 0: off}
     __Video7:begin  {Don't know if this works yet}
                setinx(SEQ,$C1,1);
                outp($46E8,$16);
                inline($EE);
                outp(SEQ,$D0);
                modinx(SEQ,$B,3,ord(on)*2+1);
                outp($46E8,$E);
                inline($EE);
              end;
      end;
    end;
  clearDACpage;
end;

function setdac15:boolean;
var m:word;
begin
  setdac15:=true;
  GetDACpath;
  case cv.dactype of
  _dacALG1201,_dacALG1301:
      dacmode(0,$A2);
  _dac15,_dac16,_dacATT490,_dacATT491,_dacATT492,_dacATT493,_dacICS5301,
  _dacSC15021,_dacSC15025,_dacMU1880,_dacMU4910,_dacMU9910,_dacUMC188,
  _dacCH8391,_dacTR8001:
      dacmode(0,$A0);
  _dacADAC1:dacmode($38,$C1);
  _dacATT498,_dacATT1498,_dacATT2498,_dacICW498,_dacICW516:
      if dacpath=8 then dacmode(0,$A0) else dacmode(0,$10);
  _dacS3_708,_dacS3_716:
      begin
        if (inp(SetDACpage(dacHIcmd)) and $10)>0 then m:=$30
                                                 else m:=$20;
        modreg(SetDACpage(dacHIcmd),$F0,m);
      end;
  _dacSTG1700,_dacSTG1702,_dacSTG1703:
      if (inp(SetDACpage(dacHIcmd)) and 8)=0 then dacmode(0,$A0)
                                             else setSTGdac(2);
  _dacBt481,_dacBt482:
      setBt1DAC($A0);
  _dacBt484,_dacBt485,_dacATT504,_dacATT505:
      modreg(SetDACpage(dacBTcmd1),$78,$30);
  _dacCH8398:
      if dacpath=8 then dacmode(0,$C4) else dacmode(0,$14);
  _dacTVP3010,_dacTVP3020,_dacTVP3025:
      begin
        wrDACreg(dacTVPindex,$18);
        modDACreg(dacTVPdata,$CF,$C);
        wrDACreg(dacTVPindex,$E);
        clrDACreg(dacTVPdata,1);
      end;
  _dacTVP3026:
      begin
        wrDACreg(dacTVP6index,$18);
        modDACreg(dacTVP6data,$CF,$C);
        wrDACreg(dacTVP6index,$E);
        clrDACreg(dacTVP6data,1);
      end;
  _dacATI68860,_dacATI68880:
      outp(setDACpage(11),$A0);
  _dacInt:case cv.chip of
          __chips:modinx(cv.IOadr,6,$C,4);
          __Cir54:dacmode(0,$A0);
             __WD:modinx(SEQ,$26,$C,$C);
             __S3:begin
                    outpw(crtc,$A039);
                    modinx(crtc,$67,$F0,$30);
                    outpw(crtc,$39);
                  end;
            __SiS:modinx(SEQ,6,$1C,4);
           __Trid:if cv.version=TR_GUI9440 then dacmode(0,$10)
                                           else dacmode(0,$A0);
          end;

    _dac0,_dac8,_dacCEG,_dacALG1101:
        setdac15:=false;
  end;
  clearDACpage;
end;

function setdac16:boolean;
var m:word;
begin
  GetDACpath;
  setdac16:=true;
  case cv.dactype of
  _dac16,_dacUMC188,_dacTR8001,_dacSC15021,_dacSC15025:
      dacmode(0,$E0);
  _dacADAC1:
      dacmode($38,$C5);
  _dacALG1201,_dacALG1301:
      dacmode(0,$C2);
  _dacATI68860,_dacATI68880:
      outp(setDACpage(11),$A1);
  _dacCH8391,
  _dacATT490,_dacATT491,_dacATT492,_dacATT493,_dacICS5301,_dacMU4910,_dacMU9910:
      dacmode(0,$C0);
  _dacATT498,_dacATT1498,_dacATT2498:
      if dacpath=8 then dacmode(0,$60) else dacmode(0,$30);
  _dacBt481,_dacBt482:
      setBt1DAC($E0);
  _dacBt484,_dacBt485,_dacATT504,_dacATT505:
      modreg(SetDACpage(dacBTcmd1),$78,$38);
  _dacCH8398:
      if dacpath=8 then dacmode(0,$64) else dacmode(0,$34);
  _dacMU1880:
      dacmode(0,$A6);
  _dacS3_708,_dacS3_716:
      begin
        if (inp(SetDACpage(dacHIcmd)) and $10)>0 then m:=$50
                                                 else m:=$60;
        modreg(SetDACpage(dacHIcmd),$F0,m);
      end;
  _dacSTG1700,_dacSTG1702,_dacSTG1703:
      if (inp(SetDACpage(dacHIcmd)) and 8)=0 then dacmode(0,$C0)
                                             else setSTGdac(3);
  _dacTVP3010,_dacTVP3020,_dacTVP3025:
      begin
        wrDACreg(dacTVPindex,$18);
        modDACreg(dacTVPdata,$CF,$D);
        wrDACreg(dacTVPindex,$E);
        clrDACreg(dacTVPdata,1);
      end;
  _dacTVP3026:
      begin
        wrDACreg(dacTVP6index,$18);
        modDACreg(dacTVP6data,$CF,$D);
        wrDACreg(dacTVP6index,$E);
        clrDACreg(dacTVP6data,1);
      end;
  _dacInt:case cv.chip of
          __chips:modinx(cv.IOadr,6,$C,$C);
          __Cir54:dacmode(0,$E1);
             __WD:modinx(SEQ,$26,$C,4);
             __S3:begin
                    outpw(crtc,$A039);
                    modinx(crtc,$67,$F0,$50);
                    outpw(crtc,$39);
                  end;
            __SiS:modinx(SEQ,6,$1C,8);
           __Trid:if cv.version=TR_GUI9440 then dacmode(0,$30)
                                           else dacmode(0,$E0);
          else setdac16:=false;
          end;
  _dacALG1101:;  {Unknown}

    _dac0,_dac8,_dacCEG,_dac15:
        setdac16:=false;
  end;
  clearDACpage;
end;

function setdac24:boolean;
var m:word;
begin
  GetDACpath;
  setdac24:=true;
  case cv.dactype of
  _dacADAC1:
      dacmode($38,$80);
  _dacALG1201,_dacALG1301:
      dacmode(0,$E2);
  _dacATI68860,_dacATI68880:
      outp(setDACpage(11),$C0);
  _dacCH8391,
  _dacATT490,_dacATT491,_dacATT492,_dacATT493,_dacICS5301,_dacMU4910,_dacMU9910:
      dacmode(0,$E0);
  _dacATT498,_dacATT1498,_dacATT2498,_dacICW498,_dacICW516:
      dacmode(0,$50);
  _dacBt481,_dacBt482:
      setBt1DAC($F0);
  _dacBt484,_dacBt485,_dacATT504,_dacATT505:
      modreg(SetDACpage(dacBTcmd1),$78,$10);
  _dacCH8398:
      if dacpath=8 then dacmode(0,$74) else dacmode(0,$B4);
  _dacMU1880:
      dacmode(0,$9E);
  _dacSC15021,_dacSC15025:
      dacmode(0,$60);
  _dacS3_708,_dacS3_716:
      begin
        if (inp(SetDACpage(dacHIcmd)) and $10)>0 then m:=$70
                                                 else m:=$E0;
        modreg(SetDACpage(dacHIcmd),$F0,m);
      end;
  _dacSTG1700:
      if (inp(SetDACpage(dacHIcmd)) and 8)=0 then dacmode(0,$E0);
  _dacSTG1702,_dacSTG1703:
      if (inp(SetDACpage(dacHIcmd)) and 8)=0 then dacmode(0,$E0)
                                             else setSTGdac(9);   {1702/3 only!}
  _dacTR8001:
      dacmode(0,$C2);
  _dacUMC188:
      dacmode(0,$F0);
  _dacInt:case cv.chip of
          __chips:if (cv.chip=__chips) and (cv.Version=CT_64300) then
                    modinx(cv.IOadr,6,$C,8);
          __Cir54:begin
                    dacmode(0,$E5);
                    modinx(SEQ,7,$E,4);
                  end;
             __S3:begin
                    outpw(crtc,$A039);
                    modinx(crtc,$67,$F0,$D0);
                    outpw(crtc,$39);
                  end;
            __SiS:modinx(SEQ,6,$1C,$10);
           __Trid:if cv.version=TR_GUI9440 then dacmode(0,$D0)
                                           else dacmode(0,$C2);
          else setdac24:=false;
          end;
    _dacBt477,
    _dacALG1101,_dac0,_dac8,_dacCEG,_dac15,_dac16:setdac24:=false;
  else setdac24:=false;
  end;
  clearDACpage;
end;

function setdac32:boolean;
var m:word;
begin
  setdac32:=true;
  case cv.dactype of
  _dacATI68860,_dacATI68880:
      outp(setDACpage(11),$E3);
  _dacATT498,_dacATT1498,_dacATT2498,_dacICW498,_dacICW516:
      dacmode(0,$50);
  _dacBt484,_dacBt485,_dacATT504,_dacATT505:
      modreg(SetDACpage(dacBTcmd1),$78,$10);

  _dacS3_708,_dacS3_716:
      modreg(SetDACpage(dacHIcmd),$F0,$70);
  _dacSC15021,_dacSC15025:
      dacmode(0,$40);
  _dacSTG1700,_dacSTG1702,_dacSTG1703:
      if (inp(SetDACpage(dacHIcmd)) and 8)>0 then setSTGdac(4);
  _dacTR8001:
      dacmode(0,$C4);

  _dacInt:case cv.chip of
          __Cir54:begin
                    dacmode(0,$E5);
                    modinx(SEQ,7,$E,8);
                  end;
          end;


  (*   _dacMus,
  _dacATT:dacmode(0,$E0);
    _dacATT2:dacmode(0,$50);
    _dacSC24:dacmode(0,$60);
    _dacCL24:begin
               dacmode(0,$E5);
               setinx(SEQ,7,8);
             end;
      _dacS3:begin
               if (inp(SetDACpage(dacHIcmd)) and $10)>0 then m:=$70
                                                        else m:=$E0;
               modreg(SetDACpage(dacHIcmd),$F0,m);
             end;
   _dacCHRON:dacmode(0,$74); {or $54/$B4 for 16bit/clk?}
    _dacTVP:begin
              modinx(setDACpage(dacTVPindex),$18,$CF,$E);
              clrinx(setDACpage(dacTVPindex),$E,$1);
            end;
     _dacInt:case cv.chip of
             __chips:if (cv.chip=__chips) and (cv.Version=CT_64300) then
                       modinx(cv.IOadr,6,$C,8);
                __S3:begin
                       outpw(crtc,$A039);
                       modinx(crtc,$67,$F0,$D0);
                       outpw(crtc,$39);
                     end;
             else setdac32:=false;
             end; *)
    _dacBt477,
    _dacALG1101,_dac0,_dac8,_dacCEG,_dac15,_dac16:setdac32:=false;
  else setdac32:=false;
  end;
  clearDACpage;
end;


  {Returns the pixel BIT address}
function pixeladdress(x,y:word):longint;
begin
  case memmode of
_pk4,_pk4a,_pk4b:pixeladdress:=(bytes*y*2+x) shl 2;
             _p8:pixeladdress:=(bytes*y+x) shl 3;
       _p15,_p16:pixeladdress:=(bytes*y+x*2) shl 3;
      _p24,_p24b:pixeladdress:=(bytes*y+x*3) shl 3;
     _p32.._p32d:pixeladdress:=(bytes*y+x*4) shl 3;
  end;
end;


procedure setvstart(x,y:word);       {Set the display start address}
var
  adr:record       {The linear start address (l) is overlayed with
		    the individual bytes (pel, displ,disph and bank)}
	case byte of
	  0:(l:longint);
	  1:(pel:byte;disp:word;bank:byte);
      end;
  stdvga:boolean;
  shft:word;
begin

  stdvga:=(cv.flags and FLG_StdVGA)>0; {default, can be disabled}
  shft:=5;

  case cv.chip of
    __vesa:begin
	       rp.bx:=0;
	       rp.cx:=x;
	       rp.dx:=y;
	       vio($4F07);
	       if rp.ax=0 then;
	       stdvga:=false;
	     end;
  else
    case memmode of
	_text,_txt2,_txt4:
		  adr.l:=(bytes*y+x*2)*2;
	    _cga2:adr.l:=(bytes*y+(x shr 2))*4;
  _cga1,_pl1,_pl2,_pl4:
		  adr.l:=(bytes*y*8+x) shl 5;
 _pk4,_pk4a,_pk4b:adr.l:=(bytes*y*2+x) shl 5;
	      _p8:adr.l:=(bytes*y+x) shl 6;
	_p15,_p16:adr.l:=(bytes*y+x*2) shl 6;
       _p24,_p24b:adr.l:=(bytes*y+x*3) shl 6;
      _p32.._p32d:adr.l:=(bytes*y+x*4) shl 6;
    end;
    case cv.chip of
        __Acer:modinx(crtc,$81,$30,adr.bank shl 4);
       __ahead:begin    {Maybe this is only for the B??}
		 if (memmode=_p8) and ((rdinx(GRC,$C) and $20)>0) then
		   adr.l:=adr.l shr 1;
		 modinx(GRC,$1C,3,adr.bank);
	       end;
        __Alli:modinx(crtc,$1C,$F,adr.bank);
         __ARK:begin
                 if (rdinx(crtc,$46) and 4)>0 then adr.l:=adr.l shr 1;
                 modinx(crtc,$40,7,adr.bank);
               end;
	 __ati:begin
                 if ((cv.version=ATI_18800_1) and ((rdinx(cv.IOadr,$B3)
                   and $40)>0)) or ((cv.version>=ATI_18800_1)
                   and ((rdinx(cv.IOadr,$B0) and $20)>0)) then adr.l:=adr.l shr 1;
		 modinx(cv.IOadr,$B0,$40,adr.bank shl 6);  {DSA bit 16}
		 if (cv.version>ATI_18800_1) then
		   modinx(cv.IOadr,$A3,$10,adr.bank shl 3);  {DSA bit 17}
		 if cv.version>=ATI_GUP_3 then
		   modinx(cv.IOadr,$AD,$C,adr.bank);
                 if (cv.Version>=ATI_M64_GX) and (memmode<_P8) then shft:=6;
	       end;
	 __ALG:begin
		 if (rdinx(GRC,$C) and $10)<>0 then adr.l:=adr.l shr 1;
		 modinx(crtc,$20,7,adr.bank);
	       end;
       __chips:begin
                 wrinx(cv.IOadr,$C,adr.bank);
                 if (rdinx(cv.IOadr,$28) and $10)>0 then shft:=6;
               end;
       __cir54:begin
		 inc(adr.bank,adr.bank and 6);     {move bit 1-2 to 2-3}
		 modinx(crtc,$1B,$D,adr.bank);
		 if (rdinx(SEQ,7) and 1)>0 then inc(shft);
		 if (rdinx(SEQ,7) and 6)=6 then inc(shft);
	       end;
       __cir64:wrinx(GRC,$7C,adr.bank);
      __compaq:begin
                 modinx(GRC,$42,$1C,adr.bank shl 2);
                 if (memmode=_P8) and (curmode<>$13) then shft:=6;
               end;
	 __HMC:begin
		 if (rdinx(SEQ,$E7) and 1)>0 then adr.l:=adr.l shr 1;
		 modinx(SEQ,$ED,1,adr.bank);
	       end;
	 __AGX:begin
		 stdvga:=false;
		 wrinx3(cv.IOadr+10,$40,adr.l shr 8);
	       end;
      __Mach32:begin
                 outpw($2AEE,adr.disp);
                 outpw($2EEE,adr.bank);
                 stdvga:=false;
               end;
      __Mach64:begin
                 meml[cv.Xseg:$14]:=(meml[cv.Xseg:$14] and $FFF00000)
                                  or (adr.l shr 9);
                 stdvga:=false;
               end;
      __Matrox:begin
                 if memmode=_p8 then
                 begin
                   adr.l:=adr.l shr 1;
                   clrinx(crtc,$11,$80);
                   modinx(crtc,8,$60,adr.disp shl 5);
                 end;
                 modinx($3DE,$A,$13,adr.bank+$10);
               end;
	__mxic:begin
		 modinx(SEQ,$F1,3,adr.bank);
		 if (memmode>=_p8) and (curmode<>$13) then inc(shft);
	       end;
	 __ncr:modinx(crtc,$31,$F,adr.bank);
	 __oak:if cv.Version<=OAK_083 then
               begin
		 if (memmode>_pl4) and (curmode<>$13) then adr.l:=adr.l shr 1;
		 modinx($3DE,$14,8,adr.bank shl 3);  {lower bit}
		 modinx($3DE,$16,8,adr.bank shl 2);  {upper bit}
	       end
               else begin
		 if (memmode>_pl4) and ((rdinx($3DE,$21) and 4)>0) then
		   adr.l:=adr.l shr 1;
		 modinx($3DE,$17,7,adr.bank);
	       end;
       __p2000:begin
		 modinx(GRC,$21,$7,adr.bank);
		 if memmode>=_P8 then inc(shft);
	       end;
          __WD:begin
		 modinx(GRC,$D,$18,adr.bank shl 3);
		 if cv.version=WD_90c33 then
		 begin
		   x:=rdinx(crtc,$11);
		   clrinx(crtc,$11,$80);  {Must unlock}
		   modinx(crtc,$3E,$40,adr.bank shl 4);
		   wrinx(crtc,$11,x);
		 end;
	       end;
     __realtek:begin
		 if (rdinx(GRC,$C) and $10)<>0 then adr.l:=adr.l shr 1;
		 inc(adr.bank,adr.bank and 2);   {shift high bit one up.}
		 modinx(crtc,$19,$50,adr.bank shl 4);
	       end;
	  __s3:begin
		 wrinx(crtc,$38,$48);
		 modinx(crtc,$31,$30,adr.bank shl 4);
                 if cv.version>S3_924 then
                 begin
                   wrinx(crtc,$39,$A5);
                   modinx(crtc,$51,3,adr.bank shr 2);
                   wrinx(crtc,$39,$5A);
                 end;
		 wrinx(crtc,$38,0);
	       end;
          __SC:modinx(crtc,$1E,$F,adr.bank);
         __SiS:modinx(SEQ,$27,$F,adr.bank);
	__trid:begin
		 if cv.version>TR_8800CS then
		 begin
		   wrinx(SEQ,$B,0);          {select old mode regs}
		   if (rdinx(SEQ,$D) and $10)>0 then adr.l:=adr.l shr 1;
  		   if (cv.Version=TR_8900B) or (cv.Version=TR_8900C) then
		     modinx(SEQ,$E,1,adr.bank shr 1);
		   if rdinx(SEQ,$B)=0 then;  {Select new mode regs}
		 end;
		 modinx(crtc,$1E,$20,adr.bank shl 5);
                 if cv.Version>=TR_9000C then
                   modinx(crtc,$27,3,adr.bank shr 1);
                 if (cv.version>=TR_8900CL) and ((rdinx(GRC,$F) and 2)>0) then shft:=6;
	       end;
       __Tseng:if cv.version=ET_3000 then
	       begin
		 if (memmode=_p8) or ((rdinx(SEQ,7) and $40)>0) then
		 begin
		   adr.l:=adr.l shr 1;
		   inc(shft);
		 end;
		 modinx(crtc,$23,2,adr.bank shl 1);
	       end
	       else begin
		 if cv.version=ET_4000 then x:=3 else x:=$F;
		 modinx(crtc,$33,x,adr.bank);
		 if (memmode>=_p8) and (curmode<>$13) then inc(shft);
	       end;
	 __UMC:begin
		if (rgs.crtcregs.x[$33] and $10)>0 then adr.l:=adr.l shr 1;
		modinx(crtc,$33,3,adr.bank);
	       end;
      __video7:begin
                 modinx(SEQ,$F6,$30,adr.bank shl 4);
                 if (rdinx(SEQ,$C8) and $10)>0 then shft:=6;
               end;
     { __Weitek:begin   This doesn't work!!
                 modinx(SEQ,5,$84,$80+(adr.bank shl 2));
                 wrinx(crtc,$1A,hi(adr.disp));
                 wrinx(crtc,$1B,lo(adr.disp));
                 stdvga:=false;
               end; }
   __xbe,__xga:begin
		 stdvga:=false;
		 wrinx3(cv.IOadr+10,$40,adr.l shr 8);
	       end;
    end;
  end;
  if stdvga then
  begin
    clrinx(crtc,$11,$80);
    wrinx($3C0,$13,adr.pel shr shft);
    outp($3C0,$33);
    wrinx(crtc,$D,lo(adr.disp));
    wrinx(crtc,$C,hi(adr.disp));
  end;
end;

begin
end.
