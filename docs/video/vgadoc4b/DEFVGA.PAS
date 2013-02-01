
type
  str10 = string[10];

const

  hx:array[0..15] of char='0123456789ABCDEF';

  Debug:boolean=false;      {If set step through video tests one by one}
  Auto_test:boolean=false;  {If set run tests automatically}


  {Keys:}
  Ch_Cr       =  $0D;
  Ch_Esc      =  $1B;
  Ch_F1       = $13B;
  Ch_F2       = $13C;
  Ch_F3       = $13D;
  Ch_F4       = $13E;
  Ch_F5       = $13F;
  Ch_F6       = $140;
  Ch_F7       = $141;
  Ch_F8       = $142;
  Ch_Home     = $147;
  Ch_ArUp     = $148;
  Ch_PgUp     = $149;
  Ch_ArLeft   = $14B;
  Ch_ArRight  = $14D;
  Ch_End      = $14F;
  Ch_ArDown   = $150;
  Ch_PgDn     = $151;
  Ch_Ins      = $152;
  Ch_Del      = $153;


    {Standard segment defines}
  Seg0000 = $0000;    {Interupt table}
  Seg0040 = $0040;    {BIOS data segment}
  SegA000 = $A000;    {Graphics Video buffer}
  SegA800 = $A800;    {Graphics Video buffer - upper half}
  SegB000 = $B000;    {Mono Text mode buffer}
  SegB800 = $B800;    {Color Text mode buffer}
  SegC000 = $C000;    {BIOS ROM segment}

  {Gamma correction types}
  GAM_None  =  0;    {No Gamma correction}
  GAM_CanDo =  1;    {}
  GAM_LeftJ =  2;    {left justify Red&Blue 1bit each}
  GAM_Left8 =  4;    {Left justify to 8bits}
  GAM_8bit  =  8;    {DAC Gamma registers are 8bit (not 6)}

type
  CursorType=Array[0..31] of longint;  {32 lines of 32 pixels}
  charr =array[1..255] of char;
  chptr =^charr;


var
  rp:registers;

  video:string[20];
  _crt:string[20];
  secondary:string[20];

  planes:word;     {number of video planes}


  dacHWcursor:boolean;   {True if we use the DAC cursor, rather than the VGA one}


  vseg:word;         {Video buffer base segment}
  biosseg:word;

  curmode:word;      {Current mode number}
  memmode:byte;      {current memory mode}
  crtc:word;         {I/O address of CRTC registers}
  pixels:word;       {Pixels in a scanline in current mode}
  lins:word;         {lines in current mode}
  bytes:longint;     {bytes in a scanline}

  force_chip:byte;
  force_mm:word;       {Forced memory size in Kbytes}
  force_version:word;  {Forced chip version}
  clocktest:boolean;   {Set false to disable clocktesting.}


  extpixfact:word;  {The number of times each pixel is shown}
  extlinfact:word;  {The number of times each scan line is shown}
  charwid   :word;  {Character width in pixels}
  charhigh  :word;  {Character height in scanlines}
  calcvseg:word;
  calcpixels,       {Calculated displayed pixels per scanline}
  calclines,        {    "      displayed scanlines}
  calchtot,         {    "      total pixels/scanline}
  calcvtot,         {    "      total lines/frame}
  calchblks,        {    "      Hor. Blanking Start}
  calchblke,        {    "      Hor Blanking End (see hblkmask)}
  calchrtrs,        {    "      Hor Retrace Start}
  calchrtre,        {    "      Hor Retrace End (see hrtrmask)}
  calcvblks,        {    "      Vert Blanking Start}
  calcvblke,        {    "      Vert Blanking End (see vblkmask)}
  calcvrtrs,        {    "      Vert Retrace Start}
  calcvrtre,        {    "      Vert Retrace End (see vrtrmask)}
  hblkmask,         {    "      }
  hrtrmask,         {    "      }
  vblkmask,         {    "      }
  vrtrmask,         {    "      }
  calcbytes:word;
  calcmmode:byte;


  vclk,hclk,fclk:longint;  {Pixel (kHz), Line (Hz) & Frame (mHz) clocks}
  ilace:boolean;


  daccomm:word;      {The result of the last dac2comm}


  BWlow,BWhigh:longint;  {Bandwidth requirement - low & high in Kbytes/sec}


  (* Interface declarations for functions. In DEFVGA.PAS *)


  (* Utility & User interfrace functions*)
procedure disable; {Disable interupts}

procedure enable;  {Enable interrupts}

function gtstr(var cp:char):string;

function getkey:word;              {Waits for a key, and returns the keyID}

function peekkey:word;             {Checks for a key, and returns the keyID}

procedure pushkey(k:word);         {Simulates a keystroke}

  {Pretend the last key was pushed again}
procedure repeatkey;

function strip(s:string):string;   {strip leading and trailing spaces}

function upstr(s:string):string;   {convert a string to upper case}

function istr(w:longint):str10;    {convert number to string}

function dehex(s:string):longint;  {Hex string to number}

function hex2(w:word):str10;       {convert number to 2digit hex string}

function hex4(w:word):str10;       {convert number to 4digit hex string}

function hex8(w:longint):str10;       {convert number to 4digit hex string}

procedure swapbyte(var a,b:byte);  {Swap the 2 bytes}

function clipstr(var s:string):string;   {Cuts & returns the first non-space
                                          substring from s}

  {BIOS & lowlevel I/O functions}

procedure vio(ax:word);         {INT 10h reg ax=AX. other reg. set from RP
                                 on return rp.ax=reg AX}

procedure viop(ax,bx,cx,dx:word;p:pointer);
                                {INT 10h reg AX-DX, ES:DI = p}

function inp(reg:word):byte;      {Reads a byte from I/O port REG}

function inpw(reg:word):word;     {Reads a word from I/O port REG}

function inpl(reg:word):longint;  {Reads a DWORD from I/O port REG}

procedure outp(reg,val:word);    {Write the low byte of VAL to I/O port REG}

procedure outpw(reg,val:word);    {Write the word byte of VAL to I/O port REG}

procedure outpl(reg:word;val:longint);    {Write the word byte of VAL to I/O port REG}

  {Outputs a 32bit value as a single OUT DX,EAX - requires 386 or better}
procedure outplong(reg:word;val:longint);

  {Inputs a 32bit value as a single IN EAX,DX - requires 386 or better}
function inplong(reg:word):longint;


function rdinx(pt,inx:word):word;       {read register PT index INX}

procedure wrinx(pt,inx,val:word);       {write VAL to register PT index INX}

procedure wrinx2(pt,inx,val:word);       {write VAL to register PT index INX}

procedure wrinx2m(pt,inx,val:word);       {write VAL to register PT index INX}

procedure wrinx3(pt,inx:word;val:longint);       {write VAL to register PT index INX}

procedure wrinx3m(pt,inx:word;val:longint);       {write VAL to register PT index INX}

procedure modinx(pt,inx,mask,nwv:word);  {In register PT index INX sets
                                          the bits in MASK as in NWV
                                          the other are left unchanged}

procedure setinx(pt,inx,val:word);

procedure clrinx(pt,inx,val:word);

procedure modreg(reg,mask,nwv:word);  {In register PT index INX sets
                                          the bits in MASK as in NWV
                                          the other are left unchanged}

procedure setreg(reg,val:word);

procedure clrreg(reg,val:word);

procedure modregw(reg,mask,nwv:word);  {In register PT index INX sets
                                          the bits in MASK as in NWV
                                          the other are left unchanged}

procedure setregw(reg,val:word);

procedure clrregw(reg,val:word);

  {Lowlevel DAC stuff}
function trigdac:word;  {Reads $3C6 4 times}

procedure setDACstd;
procedure setdac8(on:boolean);
function setdac15:boolean;
function setdac16:boolean;
function setdac24:boolean;
function setdac32:boolean;

function setDACgamma(on:boolean):word;


function setDACpage(index:word):word;

procedure clearDACpage;

function rdDACreg(index:word):word;

procedure wrDACreg(index,val:word);

procedure clrDACreg(index,val:word);

procedure setDACreg(index,val:word);

procedure modDACreg(index,msk,val:word);


function getdaccomm:word;

procedure dac2comm;

procedure dac2pel;


  {Probe clocks, should really be in IDVGA ??}
procedure findclocks;


  {The LOG functions writes output data to both the screen and the file
   WHATVGA.TXT, to provide a log in case of lockup}

procedure openlog(scr:boolean);

procedure wrlog(s:string);

procedure closelog;





  (* HW cursor, BitBLT, linedraw and clock function in BITBLT.PAS *)

procedure setHWcurmap(VAR map:CursorType);

procedure HWcuronoff(on:boolean);

procedure setHWcurpos(X,Y:word);

procedure setHWcurcol(fgcol,bkcol:longint);


procedure setZoomWindow(Xs,Ys,Xe,Ye:word);

procedure setZoomAdr(AdrX,AdrY:word);

procedure ZoomOnOff(On:boolean);

procedure setZoomFactor(Fx,Fy:word);

procedure vesamodeinfo(md:word;var vbedata);


procedure fillrect(xst,yst,dx,dy:word;col:longint);

procedure copyrect(srcX,srcY,dstX,dstY,dx,dy:word);

procedure line(x0,y0,x1,y1:integer;col:longint);

procedure setclk(Nbr,divi:word);

function getclk(var divisor,divid:word):word;

function getClockFreq:longint;    {Effective pixel clock in kHz}




  (* Bank, mode and Vstart rutines, in SUPERVGA.PAS *)

procedure setbank(bank:word);

procedure setRbank(bank:word);

procedure setvstart(x,y:word);       {Set the display start to (x,y)}

function setmode(md:word;clear:boolean):boolean;

procedure SetTextMode;



procedure SetRGBPal(inx,r,g,b:word);

procedure SelectVideo(Item:word);

function rgb(r,g,b:word):longint;    {Converts RGB values to pixel in the
                                      current pixelformat }

  {Returns the pixel BIT address}
function pixeladdress(x,y:word):longint;

implementation
uses idvga;


var

  clocktbl:array[0..31] of longint;


procedure disable; (* Disable interupts *)
begin
  inline($fa);  (* CLI instruction *)
end;


procedure enable;  (* Enable interrupts *)
begin
  inline($fb);  (* STI instruction *)
end;


function gtstr(var cp:char):string;
var x:word;
  s:string;
  str:chptr;
begin
  str:=chptr(@cp);
  s:='';x:=1;
  if str<>NIL then
    while (x<255) and (str^[x]<>#0) do
    begin
      if str^[x]<>#7 then s:=s+str^[x];
      inc(x);
    end;
  gtstr:=s;
end;

const
  key_stack:word=0;    {Stored key stroke 0=none}
  lastkey:word=0;

function getkey:word;
var c:char;
begin
  if key_stack<>0 then
  begin
    lastkey:=key_stack;
    key_stack:=0;
  end
  else begin
    c:=readkey;
    if c=#0 then lastkey:=$100+ord(readkey)
            else lastkey:=ord(c);
  end;
  getkey:=lastkey;
end;

function peekkey:word;
begin
  if (key_stack=0) and not keypressed then peekkey:=0
                                      else peekkey:=getkey;
end;

procedure pushkey(k:word);  {Simulates a key stroke}
var ch:char;
begin
  key_stack:=k;
  while keypressed do ch:=readkey;
end;

  {Pretend the last key was pushed again}
procedure repeatkey;
begin
  pushkey(lastkey);
end;

  {Swap the 2 bytes}
procedure swapbyte(var a,b:byte);
var c:byte;
begin
  c:=a;
  a:=b;
  b:=c;
end;


function strip(s:string):string;       {strip leading and trailing spaces}
begin
  while s[length(s)]=' ' do dec(s[0]);
  while copy(s,1,1)=' ' do delete(s,1,1);
  strip:=s;
end;

function upstr(s:string):string;       {convert a string to upper case}
var x:word;
begin
  for x:=1 to length(s) do
    s[x]:=upcase(s[x]);
  upstr:=s;
end;

function istr(w:longint):str10;
var s:str10;
begin
  str(w,s);
  istr:=s;
end;


function hex2(w:word):str10;
begin
  hex2:=hx[(w shr 4) and 15]+hx[w and 15];
end;

function hex4(w:word):str10;
begin
  hex4:=hex2(hi(w))+hex2(lo(w));
end;

function hex8(w:longint):str10;
begin
  hex8:=hex4(w shr 16)+hex4(w);
end;

function dehex(s:string):longint;
var x:word;
    l:longint;
    c:char;
begin
  l:=0;
  for x:=1 to length(s) do
  begin
    c:=s[x];
    case c of
      '0'..'9':l:=(l shl 4)+(ord(c) and 15);
      'a'..'f','A'..'F':
               l:=(l shl 4)+(ord(c) and 15 +9);
    end;
  end;
  dehex:=l;
end;

function clipstr(var s:string):string;   {Cuts & returns the first non-space
                                          substring from s}
var
  i:integer;
begin
  i:=0;
  while s[i+1]=' ' do inc(i);
  delete(s,1,i);
  i:=0;
  while (i<length(s)) and (s[i+1]>' ') do inc(i);
  clipstr:=copy(s,1,i);
  delete(s,1,i);
end;


procedure vio(ax:word);         {INT 10h reg ax=AX. other reg. set from RP
                                 on return rp.ax=reg AX}
begin
  rp.ax:=ax;
  intr($10,rp);
end;

procedure viop(ax,bx,cx,dx:word;p:pointer);
begin                            {INT 10h reg AX-DX, ES:DI = p}
  rp.ax:=ax;
  rp.bx:=bx;
  rp.cx:=cx;
  rp.dx:=dx;
  rp.di:=ofs(p^);
  rp.es:=seg(p^);
  intr($10,rp);
end;

function inp(reg:word):byte;     {Reads a byte from I/O port REG}
begin
  reg:=port[reg];
  inp:=reg;
end;


function inpw(reg:word):word;    {Reads a word from I/O port REG}
begin
  reg:=portw[reg];
  inpw:=reg;
end;

function inpl(reg:word):longint;    {Reads a word from I/O port REG}
var l:longint;
begin
  l:=portw[reg];
  inpl:=l+(longint(portw[reg+2]) shl 16);
end;

  {Inputs a 32bit value as a single IN EAX,DX - requires 386 or better}
function inplong(reg:word):longint;
var l:longint;
begin
  inline($8B/$56/<reg/$66/$ED/$66/$89/$46/<l);
  inplong:=l;
end;

procedure outp(reg,val:word);    {Write the low byte of VAL to I/O port REG}
begin
  port[reg]:=val;
end;

procedure outpw(reg,val:word);
begin
  portw[reg]:=val;
end;

procedure outpl(reg:word;val:longint);    {Write the Dword of VAL to I/O port REG}
begin
  portw[reg]  :=val;
  portw[reg+2]:=val shr 16;
end;

  {Outputs a 32bit value as a single OUT DX,EAX - requires 386 or better}
procedure outplong(reg:word;val:longint);
begin
    {mov dx,[BP+reg] mov eax,[BP+val]  out dx,eax}
  inline($8B/$56/<reg/$66/$8B/$46/<val/$66/$EF);
end;


function rdinx(pt,inx:word):word;       {read register PT index INX}
var x:word;
begin
  if pt=$3C0 then
  begin
    x:=inp(CRTC+6);    {Reset Attribute Data/Address Flip-Flop}
    outp($3C0,inx and $DF);    {Clear bit 5 of index}
    for x:=1 to 10 do;
    rdinx:=inp($3C1);    {delay}
    x:=inp(CRTC+6);    {Reset Attribute Data/Address Flip-Flop}
    for x:=1 to 10 do;   {delay}
    outp($3C0,$20);    {Set index bit 5 to keep display alive}
    x:=inp(CRTC+6);    {Reset Attribute Data/Address Flip-Flop}
  end
  else begin
    outp(pt,inx);
    rdinx:=inp(pt+1);
  end;
end;

procedure wrinx(pt,inx,val:word);       {write VAL to register PT index INX}
var x:word;
begin
  if pt=$3C0 then
  begin
    x:=inp(CRTC+6);
    outp($3C0,inx and $DF);
    outp($3C0,val);
    x:=inp(CRTC+6);    {If Attribute Register then reset Flip-Flop}
    outp($3C0,$20);
    x:=inp(CRTC+6);
  end
  else begin
    outp(pt,inx);
    outp(pt+1,val);
  end;
end;

procedure wrinx2(pt,inx,val:word);
begin
  wrinx(pt,inx,lo(val));
  wrinx(pt,inx+1,hi(val));
end;

procedure wrinx3(pt,inx:word;val:longint);
begin
  wrinx(pt,inx,lo(val));
  wrinx(pt,inx+1,hi(val));
  wrinx(pt,inx+2,val shr 16);
end;

procedure wrinx2m(pt,inx,val:word); {Write VAL to the index pair (INX,INX+1)}
begin                               {in motorola (big endian) format}
  wrinx(pt,inx,hi(val));
  wrinx(pt,inx+1,lo(val));
end;

procedure wrinx3m(pt,inx:word;val:longint);
begin
  wrinx(pt,inx+2,lo(val));
  wrinx(pt,inx+1,hi(val));
  wrinx(pt,inx,val shr 16);
end;

procedure modinx(pt,inx,mask,nwv:word);  {In register PT index INX sets
                                          the bits in MASK as in NWV
                                          the other are left unchanged}
var temp:word;
begin
  temp:=(rdinx(pt,inx) and (not mask))+(nwv and mask);
  wrinx(pt,inx,temp);
end;

procedure modreg(reg,mask,nwv:word);  {In register REG sets the bits in
                                       MASK as in NWV other are left unchanged}
var temp:word;
begin
  temp:=(inp(reg) and (not mask))+(nwv and mask);
  outp(reg,temp);
end;


procedure setinx(pt,inx,val:word);
var x:word;
begin
  x:=rdinx(pt,inx);
  wrinx(pt,inx,x or val);
end;

procedure clrinx(pt,inx,val:word);
var x:word;
begin
  x:=rdinx(pt,inx);
  wrinx(pt,inx,x and (not val));
end;

procedure setreg(reg,val:word);
begin
  outp(reg,inp(reg) or val);
end;

procedure clrreg(reg,val:word);
begin
  outp(reg,inp(reg) and (not val));
end;

procedure modregw(reg,mask,nwv:word);  {In register REG sets the bits in
                                       MASK as in NWV other are left unchanged}
var temp:word;
begin
  temp:=(inpw(reg) and (not mask))+(nwv and mask);
  outpw(reg,temp);
end;

procedure setregw(reg,val:word);
begin
  outpw(reg,inpw(reg) or val);
end;

procedure clrregw(reg,val:word);
begin
  outpw(reg,inpw(reg) and (not val));
end;


  {The LOG functions writes output data to both the screen and the file
   WHATVGA.TXT, to provide a log in case of lockup}
var
  logfile:text;
  wrscr:boolean;

procedure openlog(scr:boolean);
begin
  assign(logfile,'whatvga.txt');
  rewrite(logfile);
  wrscr:=scr;
  if scr then SetTextMode;
end;

procedure wrlog(s:string);
begin
  if wrscr then writeln(s);
  writeln(logfile,s);
end;

procedure closelog;
begin
  close(logfile);
end;




  {Select the mode to use for the clock test, preferable a 25.175MHz one!
   Returns the frequency (in kHz for the base freq}
function setstdmode:longint;
var md:integer;
begin
  setstdmode:=25175;
  case cv.chip of
    __Mach32:md:=$321;
    __Mach64:begin
               md:=$1292;
               setstdmode:=28322;
             end;
  {  __Compaq:if cv.version>=CPQ_QV then md:=$32
                                   else md:=$12; }
       __AGX:begin
               md:=$64;
               setstdmode:=44900;
             end;
  else md:=$12;
  end;
  if setmode(md,false) then;
end;


function Vretrace:boolean;
begin
  case cv.chip of
    __Mach64:VRetrace:=memw[cv.Xseg:$12]>=memw[cv.Xseg:$0A];
    __Mach32:VRetrace:=inpw($CEEE)>=inpw($CAEE);   {Hm!!}
       __AGX:if (inp(cv.IOadr+5) and 1)>0 then
             begin
               outp(cv.IOadr+5,1);  {Reset blanking flag}
               VRetrace:=true;
             end
             else Vretrace:=false;
  else
    VRetrace:=(inp(crtc+6) and 8)>0;     {3D4h/3B4h}
  end;
end;


function getticks:longint;
var cnt,stp:longint;
    stat,x:word;
begin
  stat:=crtc+6;
  disable;
  stp:=200000;
  cnt:=0;

  while not VRetrace and (stp>0) do dec(stp);
  while VRetrace and (stp>0) do dec(stp);
  while not VRetrace and (stp>0) do dec(stp);

  if stp>0 then
    for x:=1 to 5 do
    begin
      while VRetrace and (cnt<1000000) do inc(cnt);
      while not VRetrace and (cnt<1000000) do inc(cnt);
    end;

  enable;
  getticks:=cnt;
end;


procedure progICD2061reg(clk:longint);
const
  ser_clk=4;
  ser_dta=8;
var
  old,dta,bit:word;
procedure setbits(bits:word);
begin
  outp($3C2,bits);
  for bits:=1 to 5 do;   {delay}
end;

begin
  if cv.chip=__S3 then  {Needs to enable the ICD for the STB Pegasus...}
  begin
    outpw(crtc,$4838);
    outpw(crtc,$A539);    {Enable S3 Ext}
    modinx(crtc,$42,$F,3);
  end;
  old:=inp($3CC);
  outpw(SEQ,$100);
  dta:=(old and $F3)+ser_dta;
  for bit:=1 to 6 do
  begin
    setbits(dta+ser_clk);
    setbits(dta);
  end;
  dta:=dta and $F3;
  setbits(dta);
  setbits(dta+ser_clk);
  setbits(dta);
  setbits(dta+ser_clk);

  for bit:=1 to 24 do
  begin
    dta:=dta and $F3;
    if (clk and 1)=0 then dta:=dta+ser_dta;
    setbits(dta+ser_clk);
    setbits(dta);
    dta:=dta xor ser_dta;
    setbits(dta);
    setbits(dta+ser_clk);
    clk:=clk shr 1;
  end;
  dta:=dta or ser_dta;
  setbits(dta+ser_clk);
  setbits(dta);
  setbits(dta+ser_clk);
  setbits(dta);
  outp($3C2,old);
  if cv.chip=__S3 then
  begin
    modinx(crtc,$5C,3,2);
    outpw(crtc,$5A39);    {Disable S3 Ext}
    outpw(crtc,$38);
  end;
  outpw(SEQ,$300);
  delay(15);
end;


const
  clkperm:integer=0;

function ClockPermission:boolean;
begin
  if clkperm=0 then
  begin
    settextmode;
    writeln('WHATVGA is about to test the clock chip or crystals on your');
    writeln('board. This can cause strange behavior on the display.');
    writeln('If your monitor is fixed-frequency (MDA, CGA, EGA or original');
    writeln('VGA, in fact anything that can''t handle at least 800x600) this');
    writeln('could in extreme situations potentionally hurt your monitor.');
    writeln('Press Y to continue clock testing, any other key to skip it:');
    if (getkey and $DF)=ord('Y') then clkperm:=1
                                 else clkperm:=2;
  end;
  ClockPermission:=clkperm=1;
end;

procedure findclocks;
var clks,x,y,divi,divid:word;
  basefreq,baselevel,l,l0,l1:longint;
  progcheck:boolean;    {Should we check for programmable clocks??}
begin
  if (inp($3CC) and 1)>0 then crtc:=$3D4 else crtc:=$3B4;
  progcheck:=true;
  clks:=4;
  case cv.clktype of
     clk_ext3:clks:=8;
     clk_ext4:clks:=16;
     clk_ext5:clks:=32;
     clk_ext6:clks:=64;
     clk_sdac:progcheck:=false;
  clk_TVP302x:begin
                progcheck:=false;
                clks:=0;
              end;
  end;

  if (clks>0) and ClockPermission then
  begin
    memmode:=_PL4;
    basefreq:=SetStdMode;   {Usually mode 12h, but...}
    y:=getclk(divi,divid);
    baselevel:=getticks;
    if baselevel>0 then
      for x:=0 to clks-1 do
      begin
        if (x=8) and (cv.chip=__compaq) and (cv.version>=CPQ_QV) then
           vio($32); {Hack to get at last 8 clock of QVision}
        setclk(x,divid);
        delay(50);   {Let clock settle}
        l:=getticks;
        if l>0 then cv.clks[x]:=((basefreq*baselevel) div l)*(divi div 12);
      end;
    setclk(y,divid);
  end;
  if progcheck and ClockPermission then
  begin
    outp($3C2,(inp($3CC) and $F3) or $8);   {Clk 2}
    delay(150);
    progICD2061reg($C00000);
    progICD2061reg($41A83C);  {14.318MHz* 2 * 109/62 = 50.35 MHz}
    l0:=getticks;
    progICD2061reg($41A8BC);  {14.318MHz* 2/2 * 109/62 = 25.175 MHz}
    l1:=getticks;

    if (l0<>0) and (abs(l1-l0*2)<25) then
    begin                    {Found an ICD2061}
      cv.clktype:=clk_ICD2061;
      progICD2061reg($C04000);  {Set prescale bit to *4}
      progICD2061reg($59A8BC);  {14.318MHz* 4/2 * 109/62 = 50.35 MHz}
      l:=getticks;
      if abs(l1-l*2)<25 then  {Prescale bit exists = ICD2061A}
        cv.clktype:=clk_ICD2061A;
      progICD2061reg($C00000);  {Restore ?}
    end;
    setclk(y,divid);
  end;

end;


procedure SelectVideo(item:word);
begin
  cv:=vid[item];
  loadmodes;
  video:=header[cv.chip];
  settextmode;
end;


procedure dac2pel;    {Force DAC back to PEL mode}
begin
  if inp($3c8)=0 then;
end;

function trigdac:word;  {Reads $3C6 4 times}
var x:word;
begin
  x:=inp($3c6);
  x:=inp($3c6);
  x:=inp($3c6);
  if (cv.dactype=_dacMU1880) then x:=inp($3C6);
  trigdac:=inp($3c6);
end;

procedure dac2comm;    {Enter command mode of HiColor DACs}
begin
  dac2pel;
  daccomm:=trigdac;
end;

function getdaccomm:word;
begin
  {if cv.DAC_RS2<>0 then getdaccomm:=inp($3C6+cv.DAC_RS2)
  else} begin
    dac2comm;
    getdaccomm:=inp($3C6);
    dac2pel;
  end;
end;

const
  SavedDACpage:word=0;  {DAC page state saved by SaveDACpage, reset by clearDACpage}

procedure SaveDACpage;
begin
  SavedDACpage:=0;   {default}
  if (cv.flags and FLG_ExtDAC)>0 then   {RS2/3 addressing ?}
    case cv.chip of
      __S3:begin
             outpw(crtc,$4838);  {Unlock S3 regs}
             outpw(crtc,$A539);
             SavedDACpage:=(rdinx(crtc,$43) and 2) shl 1;
             if (cv.version>S3_924) and (SavedDACpage=0) then
               SavedDACpage:=(rdinx(crtc,$55) and 3) shl 2;
             if (rdinx(crtc,$5C) and $20)>0 then inc(SavedDACpage,16);
             outpw(crtc,$5A39);
             outpw(crtc,$38);  {Lock S3 regs}
           end;
    end;
end;


const
  DACpage:boolean=false;  {Set if DAC registers enabled (MGA,Weitek..)}

  {Returns the address of the DAC register selected by index (0..3
   for standard DACs, 0..7 or 0..15 for advanced DACs), and sets
   any necessary flags. }
function setDACpage(index:word):word;
const
  DACadr:array[0..3] of word=($3C8,$3C9,$3C6,$3C7);
  M32DACadr:array[0..3] of word=($2EC,$2ED,$2EA,$2EB);
var ret,x:word;
    found:boolean;
begin
  found:=true;
  ret:=DACadr[index and 3];
  if cv.chip=__AGX then outp(cv.IOadr,1);   {Enable VGA regs}
  if (cv.flags and FLG_ExtDAC)>0 then   {RS2/3 addressing ?}
    case cv.chip of
       __AGX:begin
               if index>7 then ret:=cv.spcreg+(index and 3);
               if (index and 4)>0 then outp(cv.IOadr+10,$51)
                                  else outp(cv.IOadr+10,0);
             end;
       __ATI:if cv.Version<ATI_GUP_3 then found:=false
             else modinx(cv.IOadr,$A0,$60,index shl 3);
    __Compaq:begin
               if (index and 4)>0 then inc(ret,$8000);
               if (index and 8)>0 then inc(ret,$1000);
             end;
    __Mach32:begin
              { modinx(cv.IOadr,$A0,$60,index shl 3);}
               x:=inp($8EEF) and $CF;
               outp($7AEF,x+((index and $C) shl 2));
               ret:=ret-$DC;   {3C8 -> 2EC}
             end;
    __Mach64:begin
               outp($62EC,index shr 2);
               ret:=$5EEC+(index and 3);
             end;
       __MGA:begin
               if (not DACpage) and (cv.PCIid>0) then
               begin
                 wPCIlong($10,$AC000);  {Map ACC regs at AC000h}
                 cv.Xseg:=$AC00;
                 DACpage:=true;
               end;
               ret:=0;
             end;
       __NCR:ret:=ret+((index and 4) shl 13);    {A15 = $8000}
        __S3:begin
               outpw(crtc,$4838);  {Unlock S3 regs}
               outpw(crtc,$A539);
               if cv.version>S3_924 then
               begin
                 clrinx(crtc,$43,2);    {Just in case}
                 modinx(crtc,$55,3,index shr 2);
                 modinx(crtc,$5C,$20,index shl 1);   {TVP3025 control}
               end
               else modinx(crtc,$43,2,index shr 1);
               outpw(crtc,$5A39);
               outpw(crtc,$38);  {Lock S3 regs}
             end;
     __Tseng:begin
               outp($3BF,3);
               outp(crtc+4,$A0);
               modinx(crtc,$31,$40,index shl 4);   {Chrontel DAC}
             end;
            {Diamond Viper w/ OAK }
       __OAK:ret:=ret+(index and $C) shl 12;
    __Weitek,__WeitekP9:
             if (cv.version<WT_P9100) and (cv.PCIid=0) then
               ret:=ret+(index and $C) shl 12  {Non-PCI P9000s}
             else begin
               if not DACpage then
               begin
                 outp($9100,$41);
                 x:=inp($9104);
                 outp($9100,$41);
                 outp($9104,(x and $F3) or 4);   {Enable Acc regs at A000h}
                 DACpage:=true;
               end;
               ret:=0;
             end;
    else found:=false;
    end
  else found:=false;
  if not found and (index=dacHIcmd) then dac2comm;
  setDACpage:=ret;
end;

  {Clears any bits set by setDACpage. Should be used after a sequence
   of extended DAC register accesses to avoid problems with accessess
   to the standard DAC registers}
procedure clearDACpage;
var x:word;
begin
  if cv.chip=__AGX then outp(cv.IOadr,4);   {Disable VGA regs}
  if SavedDACpage>0 then
    x:=setDACpage(SavedDACpage)
  else begin
  if (cv.flags and FLG_ExtDAC)>0 then   {RS2/3 addressing ?}
    case cv.chip of
       __AGX:outp(cv.IOadr+10,0);
       __ATI:clrinx(cv.IOadr,$A0,$60);
    __Mach64:outp($62EC,0);
       __MGA:if DACpage then
               wPCIlong($10,PCIrec[cv.PCIid].l[4]);
        __S3:begin
               outpw(crtc,$4838);  {Unlock S3 regs}
               outpw(crtc,$A539);
               if cv.version>S3_924 then clrinx(crtc,$55,3);
               clrinx(crtc,$43,2);
               outpw(crtc,$5A39);
               outpw(crtc,$38);  {Lock S3 regs}
             end;
     __Tseng:begin
               outp($3BF,3);
               outp(crtc+4,$A0);
               clrinx(crtc,$31,$40);   {Chrontel DAC}
             end;
    __Weitek,__WeitekP9:
             if DACpage then
             begin
               outp($9100,$41);
               x:=inp($9104);
               outp($9100,$41);
               outp($9104,x and $F3);  {Disable Acc regs at A000h}
             end;
    else dac2pel;
    end
  else dac2pel;
  end;
  DACpage:=false;
end;



function rdDACreg(index:word):word;
var inx:word;
begin
  inx:=SetDACpage(index);
  if inx=0 then
    case cv.chip of
      __MGA:rdDACreg:=mem[cv.Xseg:$3C00+index*4];
      __Weitek,__WeitekP9:
            begin
              if mem[SegA000:$198]=0 then;    {Wait ?}
              rdDACreg:=mem[SegA000:$200+4*index];
            end;
    end
  else rdDACreg:=inp(inx);
end;

procedure wrDACreg(index,val:word);
var inx:word;
begin
  inx:=SetDACpage(index);
  if inx=0 then
    case cv.chip of
      __MGA:mem[cv.Xseg:$3C00+index*4]:=val;
      __Weitek,__WeitekP9:
            mem[SegA000:$200+4*index]:=val;
    end
  else outp(inx,val);
end;


procedure clrDACreg(index,val:word);
begin
  wrDACreg(index,rdDACreg(index) and not val);
end;

procedure setDACreg(index,val:word);
begin
  wrDACreg(index,rdDACreg(index) or val);
end;

procedure modDACreg(index,msk,val:word);
begin
  wrDACreg(index,(rdDACreg(index) and not msk) or (msk and val));
end;


function rgb(r,g,b:word):longint;
begin
  r:=lo(r);g:=lo(g);b:=lo(b);
  case memmode of
       _PL1,_PL1E,_CGA1:
            rgb:=r and 1;
       _PL2,_CGA2:
            rgb:=r and 3;
  _PL4,_PK4:rgb:=r and 15;
        _P8:rgb:=r;
       _P15:rgb:=((r shr 3) shl 5+(g shr 3)) shl 5+(b shr 3);
       _P16:rgb:=((r shr 3) shl 6+(g shr 2)) shl 5+(b shr 3);
  _P24,_P32:rgb:=(longint(r) shl 8+g) shl 8 +b;
_P24b,_P32b:rgb:=(longint(b) shl 8+g) shl 8 +r;
      _p32c:rgb:=((longint(r) shl 8+g) shl 8 +b) shl 8;
      _P32d:rgb:=((longint(b) shl 8+g) shl 8 +r) shl 8;
  end;
end;


  {Writes a 32bit value to a DWORD at offset ADR in Xseg}
procedure write32(adr:word;val:longint);
var w:word;
begin
  w:=cv.Xseg;
    {mov es,[cv.Xseg]  mov di,[BP+adr]  mov eax,[BP+val]  mov es:[di],eax}
  inline($8E/$46/<w/$8B/$7E/<adr/$66/$8B/$46/<val/$66/$26/$89/5);
end;

  {Writes a two 16bit values to a DWORD at offset ADR in Xseg as one MOVL}
procedure write32w(adr:word;hiw,low:word);
var w:word;
  l:longint;
begin
  l:=(longint(hiw) shl 16)+low;
  w:=cv.Xseg;
    {mov es,[cv.Xseg]  mov di,[BP+adr]  mov eax,[BP+l]  mov es:[di],eax}
  inline($8E/$46/<w/$8B/$7E/<adr/$66/$8B/$46/<l/$66/$26/$89/5);
end;

