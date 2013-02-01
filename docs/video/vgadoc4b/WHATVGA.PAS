
uses dos,crt,supervga,idvga;

const
  copyright='   29/Sep/95    Copyright 1991-95  Finn Thoegersen';

  SWversion = 2000;    {1495 = 1.49e, 1500 = 1.50, 2000 = 2.00}

  menuchars:array[1..55] of char=
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&()[]{}-_=+/?';

  beta_ver=true;


  max_clk=17;
  clkname:array[0..max_clk] of string[20]=('','Internal','4 Ext Clks'
      ,'8 Ext Clks','16 Ext Clks','32 Ext Clks','64 Ext Clks'
      ,'32 Ext Clks (Sigma)','ICD20c61','ICD20c61A','S3 SDAC','TVP302x'
      ,'ICS2595','SC11412','CH8391/8','STG1703','MUSIC','IBM RGB52x');



var
  af_fil:file;
  af_buf:array[0..2048] of byte;
  af_pos:word;
  af_rec:_AT2;
  af_cmt:string;
  af_tst:_AT3;
  af_fail:boolean;
  af_filename:string[12];

  {Displays the copyright & version info}
function wrVersionNbr:string;
var s:string;
begin
  str(SWVersion div 1000,s);
  s:=s+'.'+chr((SWversion div 100) mod 10+48)+chr((SWversion div 10) mod 10+48);
  if (SWversion mod 10)>0 then s:=s+chr(SWversion mod 10+$60);
  if (beta_ver) then s:=s+' (BETA)';
  wrVersionNbr:='WHATVGA v. '+s;
end;

function freq(frq:longint):string;
var w:word;
  st:string[5];
begin
  w:=frq mod 1000;
  str(frq div 1000:3,st);
  freq:=st+'.'+chr((w div 100)+48)+chr(((w div 10) mod 10)+48)+chr((w mod 10)+48);
end;

  {Appends a datablock to the AF buffer}
procedure AddAFbuf(var b;bytes:word);
begin
  move(b,af_buf[af_pos],bytes);
  inc(af_pos,bytes);
end;

  {Writes an AF record to the AF file}
procedure WrAFbuf(typ:byte);
begin
  af_buf[0]:=typ;
  move(af_pos,af_buf[1],2);
  blockwrite(af_fil,af_buf,af_pos);
  close(af_fil);
  reset(af_fil,1);        {Flushes file output}
  seek(af_fil,filesize(af_fil));
  af_pos:=3;
end;

function Rtext(str:string;wid:integer):string;
begin
  while str[length(str)]=' ' do dec(str[0]);
  Rtext:=copy('             ',1,wid-length(str))+str;
end;

function getComment(tx:string):string;
var s,s1:string;
begin
  writeln('Please enter '+tx+' (max 3 lines):');
  s:='';s1:='';
  readln(s1);
  s1:=strip(s1);
  if s1<>'' then
  begin
    s:=s1;
    readln(s1);s1:=strip(s1);
    if s1<>'' then
    begin
      s:=s+' '+s1;
      readln(s1);s1:=strip(s1);
      if s1<>'' then
      begin
        s:=s+' '+s1;
        writeln;
      end;
    end;
  end;
  getComment:=s;
end;

function getYN:boolean;
const YN:array[0..1] of string[3]=('No','Yes');
var ret:integer;
begin
  ret:=-1;
  repeat
    case getkey of
      ord('y'),ord('Y'):ret:=1;
      ord('n'),ord('N'):ret:=0;
                 ch_esc:ret:=0;
    end;
  until ret>-1;
  getYn:=boolean(ret);
  writeln(YN[ret]);
  if ret=0 then af_fail:=true;
end;


procedure InitAFFile(cursel:word);
var x:word;
  hdr:_AT0;
  mm:byte;
begin
  x:=0;
  repeat
    inc(x);     {Find first free file number}
    af_filename:='WHVGA'+istr(x)+'.TST';
    assign(af_fil,af_filename);
    {$i-}
    reset(af_fil,1);
    {$i+}
    if ioresult=0 then close(af_fil) else x:=0;
  until x=0;
  rewrite(af_fil,1);
  af_pos:=3;
  af_fail:=false;

  hdr.SWvers := SWversion;
  hdr.vid_sys:= Vids;
  hdr.cur_vid:= cursel;
  getFtime(af_fil,hdr.curtime);
  AddAFbuf(hdr,sizeof(hdr));

  af_cmt:=getComment('your Email address');
  AddAFbuf(af_cmt,length(af_cmt)+1);

  af_cmt:=getComment('your name & address');
  AddAFbuf(af_cmt,length(af_cmt)+1);
  af_cmt:=getComment('your video&monitor description');
  AddAFbuf(af_cmt,length(af_cmt)+1);
  af_cmt:=getComment('your system description');
  AddAFbuf(af_cmt,length(af_cmt)+1);

  af_cmt:='';
  for mm:=_text to _p32d do   {Build the Mode Name table}
    af_cmt:=af_cmt+copy(mmodenames[mm]+'    ',1,4);
  AddAFbuf(af_cmt,length(af_cmt)+1);

  for x:=1 to max_clk do
    AddAFbuf(clkname[x],length(clkname[x])+1);

  af_cmt:='';
  AddAFbuf(af_cmt,1);

  WrAFbuf(AF_header);
end;


function getmenkey:integer;
var x,c:word;
begin
  c:=getkey;
  if (c>=ord('a')) and (c<=ord('z')) then c:=c-32;
  getmenkey:=0;
  for x:=1 to 55 do
    if chr(c)=menuchars[x] then getmenkey:=x;
  if c=Ch_Esc then getmenkey:=-1;
end;


procedure clearmemory;
var x,y,maxbank:word;
begin
  case memmode of
    _text,_txt2,_txt4:
          begin
            {mov es,[vseg]  cld  xor di,di  mov ax,$720  mov cx,$4000  rep stosw}
            inline($8e/6/>vseg/$fc/$31/$ff/$B8/>$720/$B9/>$4000/$f3/$ab);
          end;
     _cga1,_cga2:
          fillchar(mem[SegB800:0],$8000,0);
_pl2,_pl4:begin
            wrinx(GRC,0,0);
            wrinx(GRC,1,15);    (* planar modes *)
            wrinx(GRC,8,255);
            modinx(GRC,5,3,0);
            maxbank:=pred(cv.mm div 256);
          end;
  else maxbank:=pred(cv.mm div 64);
  end;
  if memmode>_cga2 then
    for x:=0 to maxbank do
    begin
      setbank(x);
      {mov es,[vseg]  cld  xor di,di  xor ax,ax  mov cx,$8000  rep stosw}
      inline($8e/6/>vseg/$fc/$31/$ff/$31/$C0/$B9/>$8000/$f3/$ab);
    end;
end;


procedure setpix(x,y:word;col:longint);
const
  msk:array[0..7] of byte=(128,64,32,16,8,4,2,1);
  plane :array[0..1] of byte=(5,10);
  plane4:array[0..3] of byte=(1,2,4,8);
  mscga4:array[0..3] of byte=($3f,$cf,$f3,$fc);
  shcga4:array[0..3] of byte=(6,4,2,0);
var l:longint;
    m,z:word;
begin
  case memmode of
   _cga1:begin
           z:=(y shr 1)*bytes+(x shr 3);
           if odd(y) then inc(z,8192);
           mem[SegB800:z]:=(mem[SegB800:z] and (255 xor msk[x and 7]))
                         or ((col and 1) shl (7-(x and 7)));
         end;
   _cga2:begin
           z:=(y shr 1)*bytes+(x shr 2);
           if odd(y) then inc(z,8192);
           mem[SegB800:z]:=(mem[SegB800:z] and mscga4[x and 3])
                         or (col and 3) shl shcga4[x and 3];
         end;
    _pl1:begin
           l:=y*bytes+(x shr 3);
           wrinx(GRC,3,0);
           wrinx(GRC,5,2);
           wrinx(SEQ,2,1);
           wrinx(GRC,8,msk[x and 7]);
           setbank(l shr 16);
           z:=mem[vseg:word(l)];
           mem[vseg:word(l)]:=col;
         end;
   _pl1e:begin
           l:=y*bytes+(x shr 3);
           modinx(GRC,5,3,0);
           wrinx(SEQ,2,15);
           wrinx(GRC,0,col*3);
           wrinx(GRC,1,3);
           wrinx(GRC,8,msk[x and 7]);
           z:=mem[vseg:word(l)];
           mem[vseg:word(l)]:=0;
         end;
    _pl2:begin
           l:=y*bytes+(x shr 4);
           wrinx(GRC,3,0);
           wrinx(GRC,5,2);
           wrinx(SEQ,2,plane[(x shr 3) and 1]);
           wrinx(GRC,8,msk[x and 7]);
           setbank(l shr 16);
           z:=mem[vseg:word(l)];
           mem[vseg:word(l)]:=col;
         end;
    _pk2:begin
           l:=y*bytes+(x shr 2);
           setbank(l shr 16);
           z:=mem[vseg:word(l)] and mscga4[x and 3];
           mem[vseg:word(l)]:=z or (col shl shcga4[x and 3]);
         end;
    _pl4:begin
           l:=y*bytes+(x shr 3);
           wrinx(GRC,3,0);
           wrinx(GRC,5,2);
           wrinx(GRC,8,msk[x and 7]);
           setbank(l shr 16);
           z:=mem[vseg:word(l)];
           mem[vseg:word(l)]:=col;
         end;
    _pk4:begin
           l:=y*bytes+(x shr 1);
           setbank(l shr 16);
           z:=mem[vseg:word(l)];
           if odd(x) then z:=z and $f0+col
                     else z:=z and $f+(col shl 4);
           mem[vseg:word(l)]:=z;
         end;
   _pk4a:begin
           l:=y*bytes+(x shr 1);
           setbank(l shr 16);
           z:=mem[vseg:word(l)];
           if odd(x) then z:=z and $f+(col shl 4)
                     else z:=z and $f0+col;
           mem[vseg:word(l)]:=z;
         end;
   _pk4b:begin
           case x and 6 of
            2:inc(x,2);
            4:dec(x,2);
           end;
           l:=y*bytes+(x shr 1);
           setbank(l shr 16);
           z:=mem[vseg:word(l)];
           if odd(x) then z:=z and $f+(col shl 4)
                     else z:=z and $f0+col;
           mem[vseg:word(l)]:=z;
         end;
     _p8:begin
           l:=y*bytes+x;
           setbank(l shr 16);
           mem[vseg:word(l)]:=col;
         end;
   _p15,_p16:
         begin
           l:=y*bytes+(x shl 1);
           setbank(l shr 16);
           memw[vseg:word(l)]:=col;
         end;
   _p24,_p24b:
         begin
           l:=y*bytes+(x*3);
           z:=word(l);
           m:=l shr 16;
           setbank(m);
           if z<$fffe then move(col,mem[vseg:z],3)
           else begin
             mem[vseg:z]:=lo(col);
             if z=$ffff then setbank(m+1);
             mem[vseg:z+1]:=lo(col shr 8);
             if z=$fffe then setbank(m+1);
             mem[vseg:z+2]:=col shr 16;
           end;
         end;
 _p32,_p32b,_p32c,_p32d:
         begin
           l:=y*bytes+(x shl 2);
           setbank(l shr 16);
           meml[vseg:word(l)]:=col;
         end;
    else ;
  end;
end;

function whitecol:longint;
var col:longint;
begin
  case memmode of
    _cga1,_pl1e,
       _pl1:col:=1;
   _cga2,_pk2
      ,_pl2:col:=3;
    _pk4,_pl4,_PK4a,_pk4b:
            col:=15;
        _p8:col:=255;
       _p15:col:=$7fff;
       _p16:col:=$ffff;
 _p24,_p24b,_p32,_p32b:
            col:=$ffffff;
_p32c,_p32d:col:=$ffffff00;
  else
  end;
  whitecol:=col;
end;


procedure wrtext(x,y:word;txt:string);      {write TXT to pos (X,Y)}
type
  pchar=array[char] of array[0..15] of byte;
var
  p:^pchar;
  c:char;
  i,j,z,b,lns:integer;
  ad,bk:word;
  l,v,col:longint;
begin
  lns:=15;       {Assume full height chars}
  ad:=(cv.mm*longint(1024)) div bytes;
  if y+14>ad then lns:=ad-y;    {Check if we're past the bottom}
  rp.bh:=6;
  vio($1130);
  col:=whitecol;
  p:=ptr(rp.es,rp.bp);
  for z:=1 to length(txt) do
  begin
    c:=txt[z];
    for j:=0 to lns do
    begin
      b:=p^[c][j];
      for i:=0 to 7 do
      begin
        if (b and 128)<>0 then v:=col else v:=0;
        setpix(x+i,y+j,v);
        b:=b shl 1;
      end;
    end;
    inc(x,8);
  end;
end;




procedure plotchar(x,y,ch:word);
begin
  mem[vseg:(y*pixels+x) shl 1]:=ch;
end;

procedure plotchat(x,y,ch,at:word);
begin
  memw[vseg:(y*pixels+x) shl 1]:=at shl 8+ch;
end;

procedure plotstr(x,y:word;s:string);
var z:word;
begin
  for z:=1 to length(s) do
    plotchar(x+z-1,y,ord(s[z]));
end;


procedure drawtestpattern(nam:string);
                       {Draw Test pattern.}
var s:string;
  l:longint;
  x,y,yst:word;
  white:longint;

  procedure wline(stx,sty,ex,ey:integer;col:longint);
  var x,y,d,mx,my:longint;
     l:longint;
  begin
    if sty>ey then
    begin
      x:=stx;stx:=ex;ex:=x;
      x:=sty;sty:=ey;ey:=x;
    end;
    y:=0;
    mx:=abs(ex-stx);
    my:=ey-sty;
    d:=0;
    repeat
      if col=0 then l:=rgb(y,y,y) else l:=col;
      y:=(y+1) and 255;
      setpix(stx,sty,l);
      if abs(d+mx)<abs(d-my) then
      begin
        inc(sty);
        d:=d+mx;
      end
      else begin
        d:=d-my;
        if ex>stx then inc(stx)
                  else dec(stx);
      end;
    until (stx=ex) and (sty=ey);

  end;

begin
  if memmode<=_TXT4 then
  begin
    {Text modes}

  {  ClearMemory; }
    for x:=0 to pixels-1 do
    begin
      plotchar(x,0,(x mod 10)+ord('0'));
      if (x mod 10)=0 then
        plotchar(x,1,((x div 10) mod 10)+ord('0'));
      plotchar(x,lins-1,ord('.'));
    end;
    for x:=0 to lins-1 do
    begin
      plotchar(0,x,(x mod 10)+ord('0'));
      if (x mod 10)=0 then
        plotstr(0,x,istr(x));
      plotchar(pixels-1,x,ord('.'));
    end;
    plotstr(5,5,nam);
    for x:=0 to 255 do
      plotchat(x and 15+10,x shr 4+7,65,x);
    plotstr((pixels-30) div 2,lins,'This line shouldn''t be seen!!');
  end
  else begin

    white:=whitecol;

    wline(50,30,pixels-50,30 ,0);
    wline(50,lins-30,pixels-50,lins-30 ,0);

    wline(50,30,50,lins-30 ,0);
    wline(pixels-50,30,pixels-50,lins-30 ,0);
    wline(50,30,pixels-50,lins-30 ,0);

    wline(pixels-50,30,50,lins-30 ,0);

    if lins>200 then yst:=50 else yst:=18;
    wrtext(10,yst,cv.name+' with '+istr(cv.mm)+' Kb.');
    wrtext(10,yst+25,nam);

    for x:=1 to (pixels-10) div 100 do
    begin
      for y:=1 to 10 do
        setpix(x*100,y,white);
      wrtext(x*100+3,1,istr(x));
    end;

    for x:=1 to (lins-10) div 100 do
    begin
      for y:=1 to 10 do
        setpix(y,x*100,white);
      wrtext(1,x*100+2,istr(x));
    end;

    case colbits[memmode] of
          2:for x:=0 to 63 do
              for y:=0 to 63 do
                setpix(30+x,yst+y+50,y shr 3);
          4:for x:=0 to 127 do
              if lins<250 then
                for y:=0 to 63 do
                  setpix(30+x,yst+y+50,y shr 2)
              else
                for y:=0 to 127 do
                  setpix(30+x,yst+y+50,y shr 3);
          8:for x:=0 to 127 do
              if lins<250 then
                for y:=0 to 63 do
                  setpix(30+x,yst+50+y,((y shl 2) and 240) +(x shr 3))
              else
                for y:=0 to 127 do
                  setpix(30+x,yst+50+y,((y shl 1) and 240)+(x shr 3));

15,16,24,32:if pixels<600 then
            begin
              for x:=0 to 63 do
              begin
                for y:=0 to 63 do
                begin
                  setpix(30+x,100+y,rgb(x*4,y*4,0));
                  setpix(110+x,100+y,rgb(x*4,0,y*4));
                  setpix(190+x,100+y,rgb(0,x*4,y*4));
                end;
              end;
              for x:=0 to 255 do
                for y:=170 to 179 do
                begin
                  setpix(x,y   ,rgb(x,0,0));
                  setpix(x,y+10,rgb(0,x,0));
                  setpix(x,y+20,rgb(0,0,x));
                end;
            end
            else begin
              for x:=0 to 127 do
                for y:=0 to 127 do
                begin
                  setpix( 30+x,120+y,rgb(x*2,y*2,0));
                  setpix(200+x,120+y,rgb(x*2,0,y*2));
                  setpix(370+x,120+y,rgb(0,x*2,y*2));
                end;
              for x:=0 to 511 do
                for y:=260 to 269 do
                begin
                  setpix(x,y   ,rgb(x shr 1,0,0));
                  setpix(x,y+10,rgb(0,x shr 1,0));
                  setpix(x,y+20,rgb(0,0,x shr 1));
                end;
            end;

    end;
    wline(0,0,10, 0 ,whitecol);
    wline(0,0, 0,10 ,whitecol);
    wline(0,0,10,10 ,whitecol);

    wline(pixels-11, 0,pixels-1, 0 ,whitecol);
    wline(pixels-1 , 0,pixels-1,10 ,whitecol);
    wline(pixels-11,10,pixels-1, 0 ,whitecol);

    wline(0,lins-11, 0,lins-1  ,whitecol);
    wline(0,lins-1 ,10,lins-1  ,whitecol);
    wline(0,lins-1 ,10,lins-11 ,whitecol);

    wline(pixels-11,lins-1 ,pixels-1,lins-1 ,whitecol);
    wline(pixels-1 ,lins-11,pixels-1,lins-1 ,whitecol);
    wline(pixels-11,lins-11,pixels-1,lins-1 ,whitecol);
  end;
end;

           (* Writes the string s to 1. line of the mono. screen *)
procedure wrmono(s:string);
var x:word;
begin
  for x:=1 to length(s) do
    mem[SegB000:x+x]:=ord(s[x]);
end;

           (* Ensures that xlow<=x<=xhigh *)
procedure chkrange(var x:integer;xlow,xhigh:integer);
begin
  if x<xlow then x:=xlow
  else if x>xhigh then x:=xhigh;
end;


var
  CurModeIndex:integer;    {Index into the ModeTbl array for the current mode}

function testvmode:boolean;
const iltxt:array[boolean] of string[4]=('',' (i)');
var
  s:string;
  r13,sclins,scpixs,scbytes:word;
  x0,y0,x,dlay:integer;
  ch:word;
  stop,scrollable,nxt:boolean;

begin
  testvmode:=true;
  s:='Mode: '+hex4(curmode)+'h: '+istr(pixels)+'x'+istr(lins)+' '+mmodenames[memmode];
  drawtestpattern(s);

  if auto_test then af_rec.flag:=AFF_testok;    {Mode Supported}

  scrollable:=false;
  ch:=getkey;
  if (ch<>Ch_Esc) and not (chr(ch) in ['D','F','d','f']) then
  begin
    if memmode>=_pl4 then
    begin
      scrollable:=true;
      { Scroll test  }
      sclins:=lins;
      scpixs:=pixels;
      scbytes:=bytes;
      r13:=rdinx(crtc,$13);
      if ((cv.flags and FLG_StdVGA)>0) and ((bytes*lins*planes*5 div 2)<cv.mm*longint(1024))
        and (r13<128) and (r13>0) and ((bytes div r13) in [1,2,4,8,16])
        and (memmode<>_cga1) and (memmode<>_cga2) then
      begin            {Can we double the screen?}
        wrinx(crtc,$13,r13*2);
        bytes:=bytes*2;
        pixels:=pixels*2;
      end;
      case memmode of
        _text,_txt2,_txt4:
                lins:=32768 div bytes;
        _cga1,_cga2:
                lins:=16384 div bytes;
           _pl1:lins:=cv.mm*longint(256) div bytes;
      else lins:=cv.mm*longint(1024) div (bytes*planes);
      end;
      case memmode of
   _cga1,_pl1,
         _pl4:pixels:=bytes*8;
        _cga2:pixels:=bytes*4;
   _pk4,_PK4a,_pk4b:
              pixels:=bytes*2;
          _p8:pixels:=bytes;
    _p15,_p16:pixels:=bytes shr 1;
   _p24,_P24b:pixels:=bytes div 3;
   _p32,_p32b,_p32c,_p32d:
              pixels:=bytes shr 2;
      end;

      Clearmemory;

      drawtestpattern(s);
      x0:=0;
      y0:=0;
      stop:=false;

      dlay:=100;  {100ms}
      if auto_test then pushkey(ord('a'));
      repeat
        setvstart(x0,y0);
        case getkey of
           ord('>'):inc(x0);
           ord('<'):dec(x0);
            Ch_ArUp:y0:=y0-16;
          Ch_ArLeft:x0:=x0-16;
         Ch_ArRight:x0:=x0+16;
          Ch_ArDown:y0:=y0+16;
            Ch_PgUp:dec(y0);
            Ch_PgDn:inc(y0);
          ord('A'),ord('a'):begin
                              x0:=0;y0:=0;x:=0;
                              repeat
                                delay(dlay);
                                nxt:=false;
                                case x of
                                  0:if x0+16<=pixels-scpixs then inc(x0,16)
                                    else begin
                                      nxt:=true;
                                      x0:=pixels-scpixs;
                                    end;
                                  1:if y0+16<=lins-sclins then inc(y0,16)
                                    else begin
                                      nxt:=true;
                                      y0:=lins-sclins;
                                      dlay:=50;  {Speed up for return trip}
                                    end;
                                  2:if x0>=16 then dec(x0,16)
                                    else begin
                                      nxt:=true;
                                      x0:=0;
                                      dlay:=25;  {Speed up for return trip}
                                    end;
                                  3:if y0>=16 then dec(y0,16)
                                    else begin
                                      nxt:=true;
                                      stop:=true;
                                      y0:=0;
                                    end;
                                end;
                                setvstart(x0,y0);
                                if nxt then
                                begin
                                  inc(x);
                                  delay(500);
                                end;
                                if peekkey=Ch_Esc then stop:=true;
                              until stop;
                              delay(500);
                            end;
  ord('D'),ord('d'),ord('F'),ord('f'):begin
                                        stop:=true;
                                        repeatkey;
                                      end;

               Ch_Esc,Ch_Cr:stop:=true;
          ord('R'),ord('r'):begin
                              stop:=true;
                              repeatkey;
                            end;

        end;
        chkrange(x0,0,pixels-scpixs+10000);
        chkrange(y0,0,lins-sclins);

      until stop;
      setvstart(0,0);  {Reset start, some chipsets NEED this}
      pixels:=scpixs;
      lins:=sclins;
      bytes:=scbytes;
    end;
    SetTextMode;

    writeln('Values for mode '+hex4(curmode)+':');
    writeln;
    writeln('                       List:  Calc:  BlnkS: RetrS: RetrE: BlnkE: Frame:');
    writeln('Pixels per scan line:',pixels:6,calcpixels:7,calchblks:7,calchrtrs:7
                                   ,calchrtre:7,calchblke:7,calchtot:8);
    writeln('Lines in image:      ',lins:6  ,calclines:7,calcvblks:7,calcvrtrs:7
                                   ,calcvrtre:7,calcvblke:7,calcvtot:8,iltxt[ilace]);
    writeln('Bytes per scanline:  ',bytes:6 ,calcbytes:7);
    writeln('Memory mode:         ',strip(mmodenames[memmode]):6,strip(mmodenames[calcmmode]):7);
    if memmode<_herc then
      writeln('Character cell:      ',charwid,'x',charhigh);
    if vclk>0 then
    begin
      writeln;
      write('Clocks: Pixel: '+freq(vclk)+' MHz, Line: '+freq(hclk)
           ,' KHz, Frame: '+freq(fclk)+' Hz');
      if ilace then write(' (i)');
      writeln;
      writeln('Required bandwidth: '+freq(BWlow)+' -'+freq(BWhigh)+' Mb/s');
    end;
    if auto_test then
    begin
      pushkey(ch);
      writeln;
      write('Did the mode display properly (y/n): ');
      if getYN then inc(af_rec.flag,AFF_dispok);
      if scrollable then
      begin
        writeln;
        write('Did the mode scroll properly (y/n): ');
        if getYN then inc(af_rec.flag,AFF_scrollok)
                 else inc(af_rec.flag,AFF_scroll);
      end;
      if (af_rec.flag and AFF_dispok)=0 then
      begin
        write('Disable the mode (y/n): ');
        if getYN then inc(af_rec.flag,AFF_canceled);
      end;

      af_cmt:=GetComment('any comments to the test');

      af_rec.vseg    :=vseg;
      af_rec.Cpixels :=calcpixels;
      af_rec.Clins   :=calclines;
      af_rec.Cbytes  :=calcbytes;
      af_rec.CMmode  :=calcmmode;
      af_rec.ChWidth :=charwid;
      af_rec.ChHeight:=charhigh;
      af_rec.Cvseg   :=calcvseg;
      af_rec.ExtPixf :=Extpixfact;
      af_rec.Extlinf :=Extlinfact;
      af_rec.vclk    :=vclk;
      af_rec.hclk    :=hclk;
      af_rec.fclk    :=fclk;
      af_rec.ilace   :=ilace;

      pushkey(ch_cr);
    end;

    ch:=getkey;
  end;
  if (ch=ord('D')) or (ch=ord('d')) then ch:=dumpVGAregs;

  case ch of
     Ch_Esc:testvmode:=false;
    ord('f'),ord('F'):
            dumpVGAregfile;
    ord('r'),ord('R'):
            modetbl[CurModeIndex].flags:=
                     modetbl[CurModeIndex].flags and (not MFL_enabled);
  end;
end;


function InitMode(md:integer):boolean;
begin
  CurModeIndex:=md;
  memmode:=modetbl[md].memmode;
  pixels :=modetbl[md].xres;
  lins   :=modetbl[md].yres;
  bytes  :=modetbl[md].bytes;
  InitMode:=setmode(modetbl[md].md,true);
end;



procedure testcursor;           {Test HardWare Cursor}
var m,x:word;
  md:integer;

procedure setXY(x0,y0:word);
begin
  SetHWcurpos(x0,y0);
  SetHWcurcol(((x0*longint(256) div pixels)*256
          +(y0*longint(256) div lins))*256+$ff,0);
end;

procedure tmode(m:word);
const
  CurMap:CursorType=   {Snipers sight}
     ($00f81f00,$00800130,$00800130,$00800100
     ,$00f00f00,$008c3100,$00824100,$00818100
     ,$80800101,$40800102,$20800104,$21800184
     ,$11800188,$11800188,$11800188,$ffffffff
     ,$ffffffff,$11800188,$11800188,$11800188
     ,$21800184,$20800104,$40800102,$80800101
     ,$00818100,$00824100,$008C3100,$00f00f00
     ,$00800100,$00800100,$00800100,$00f81f00);

var x,x0,y0:integer;
  fgcol,bkcol:longint;
  stop:boolean;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Mode: '+hex4(curmode)+'h: '+istr(pixels)+'x'
        +istr(lins)+' '+istr(modecols[memmode])+' colors');

    SetHWcurmap(CurMap);

    if auto_test then pushkey(ord('A'));
    stop:=false;
    x0:=100;y0:=150;  {Place it in the palette}
    repeat
      if y0<0 then y0:=0;
      if x0+32>pixels then x0:=pixels-32;
      if y0+32>lins then y0:=lins-32;

      SetXY(x0,y0);
      case getkey of
          Ch_ArUp:dec(y0,17);
        Ch_ArLeft:dec(x0,17);
       Ch_ArRight:inc(x0,17);
        Ch_ArDown:inc(y0,17);
        ord('a'),ord('A'):
                  begin
                    x0:=0;
                    repeat
                      SetXY(x0,150);
                      delay(200);
                      inc(x0,17);
                    until x0>pixels-32;
                    x0:=0;
                    repeat
                      SetXY(200,x0);
                      delay(200);
                      inc(x0,17);
                    until x0>lins-32;
                    stop:=true;
                  end;
     Ch_Cr,Ch_Esc:stop:=true;
      end;
    until stop;
    HWcuronoff(false);
    if auto_test then
    begin
      repeat until keypressed;
      SetTextMode;
      write('Did the Hardware Cursor work properly (y/n) ?');
      af_tst.Flag :=ord(getYN)*AFF_testok;
      af_cmt:=getComment('any comments to the test');

      af_tst.mode :=modetbl[m].md;
      af_tst.Mmode:=modetbl[m].memmode;
      AddAFbuf(af_tst,sizeof(af_tst));
      AddAFbuf(af_cmt,length(af_cmt)+1);
      WrAFbuf(AF_Tcursor);
    end;
  end;
end;

begin
  textmode($103);   {43/50 line text mode}
  writeln('Hardware Cursor test.');
  writeln;

  if auto_test then
  begin
    delay(1000);
    pushkey(ord('*'));
  end
  else begin
    writeln('Modes:');
    writeln;
    for m:=1 to nomodes do
      if (modetbl[m].flags AND MFL_enGr)=MFL_enGr then
      writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
             +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
    writeln;

    writeln('  *  All modes');
    writeln;
  end;

  x:=getmenkey;
  for m:=1 to nomodes do
    if ((x=0) or (x=m)) and ((modetbl[m].flags AND MFL_enGr)=MFL_enGr) then
      tmode(m);

end;



procedure testblit;           {Test BitBLT functions}
var m,x:word;
  md:integer;

procedure tmode(m:word);
var x,y,x0,y0,siz:integer;
  stop:boolean;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Mode: '+hex4(curmode)+'h: '+istr(pixels)+'x'
        +istr(lins)+' '+istr(modecols[memmode])+' colors');
    if lins>=400 then siz:=8 else siz:=4;
    x0:=pixels div 2-8*siz;
    y0:=lins div 2-8*siz;

    case colbits[memmode] of
          4:for x:=0 to 15 do
              fillrect(x0,y0+x*siz,16*siz,siz,x);
          8:for x:=0 to 255 do
              fillrect(x0+(x and 15)*siz,y0+(x div 16)*siz,siz,siz,x);
15,16,24,32:for x:=0 to 63 do
            begin
              fillrect(x0+(x and 15)*siz,y0+(x div 16)*siz,siz,siz,rgb(x*4,0,0));
              fillrect(x0+(x and 15)*siz,y0+siz*4+(x div 16)*siz,siz,siz,rgb(0,x*4,0));
              fillrect(x0+(x and 15)*siz,y0+siz*8+(x div 16)*siz,siz,siz,rgb(0,0,x*4));
              fillrect(x0+(x and 15)*siz,y0+siz*12+(x div 16)*siz,siz,siz,rgb(x*4,x*4,x*4));
            end;
    end;
    copyrect(x0,y0,x0-siz*15,y0-5  ,siz*16-1,siz*16+1);
    copyrect(x0,y0,x0+5  ,y0-siz*15,siz*16-1,siz*16+1);
    copyrect(x0,y0,x0+siz*15,y0+5  ,siz*16-1,siz*16+1);
    copyrect(x0,y0,x0-5  ,y0+siz*15,siz*16-1,siz*16+1);


    if memmode<=_pl4 then   {special 16c test pattern}
    begin
      for y:=1 to 8 do
      begin
        y0:=y*10+250;
        fillrect(100,y0,y,8,y);
        x0:=101+y;
        for x:=1 to 15 do
        begin
          fillrect(x0,y0,x,8,y);
          x0:=x0+x+1;
        end;
        fillrect(x0,y0,9-y,8,y);
        y0:=y0+10;
      end;
    {  if readkey='' then;  }

      for x:=0 to 19 do
      begin
        x0:=96+x*8;
        for y:=0 to 8 do
          setpix(x0,259+10*y,15);
      end;
    end;

    if auto_test then
    begin
      repeat until keypressed;
      SetTextMode;
      write('Did the BitBLT test work properly (y/n) ?');
      af_tst.Flag :=ord(getYN)*AFF_testok;
      af_cmt:=getComment('any comments to the test');

      af_tst.mode :=modetbl[m].md;
      af_tst.Mmode:=modetbl[m].memmode;
      AddAFbuf(af_tst,sizeof(af_tst));
      AddAFbuf(af_cmt,length(af_cmt)+1);
      WrAFbuf(AF_Tbitblt);
    end
    else if getkey=0 then;
  end;
  settextmode;
end;

begin
  textmode($103);
  writeln('Hardware BitBLT test.');
  writeln;

  if auto_test then
  begin
    delay(1000);
    pushkey(ord('*'));
  end
  else begin
    writeln('Modes:');
    writeln;
    for m:=1 to nomodes do
      if (modetbl[m].flags AND MFL_enGr)=MFL_enGr then
      writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
             +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
    writeln;

    writeln('  *  All modes');
    writeln;
  end;

  x:=getmenkey;
  for m:=1 to nomodes do
    if ((x=0) or (x=m)) and ((modetbl[m].flags AND MFL_enGr)=MFL_enGr) then
      tmode(m);
end;



procedure testline;           {Test Line Draw functions}
var x,m:word;
  md:integer;

procedure tmode(m:word);
var x,x0,y0,linl:integer;
  stop:boolean;
  col:longint;
  zz:array[-10..10] of integer;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Mode: '+hex4(curmode)+'h: '+istr(pixels)+'x'
        +istr(lins)+' '+istr(modecols[memmode])+' colors');

    x0:=pixels div 2;
    y0:=lins div 2;
    linl:=lins div 3;
    for x:=-10 to 9 do
    begin
      case colbits[memmode] of
           4:col:=(x+11) and 15;
           8:col:=x*12+128;
 15,16,24,32:col:=rgb(128-x*10,x+128,128+x*5);
      end;
      line(x0,y0,x0+x*(linl div 10),y0-linl,col);
      line(x0,y0,x0+linl ,y0+x*(linl div 10),col);
      line(x0,y0,x0-x*(linl div 10),y0+linl,col);
      line(x0,y0,x0-linl ,y0-x*(linl div 10),col);
    end;
    if auto_test then
    begin
      repeat until keypressed;
      SetTextMode;
      write('Did the Line Draw test work properly (y/n): ?');
      af_tst.Flag :=ord(getYN)*AFF_testok;
      af_cmt:=getComment('any comments to the test');

      af_tst.mode :=modetbl[m].md;
      af_tst.Mmode:=modetbl[m].memmode;
      AddAFbuf(af_tst,sizeof(af_tst));
      AddAFbuf(af_cmt,length(af_cmt)+1);
      WrAFbuf(AF_Tline);
    end
    else if getkey=0 then;
  end;
  settextmode;
end;

begin
  textmode($103);
  writeln('Hardware Line Draw test.');
  writeln;

  if auto_test then
  begin
    delay(1000);
    pushkey(ord('*'));
  end
  else begin
    writeln('Modes:');
    writeln;
    for m:=1 to nomodes do
      if (modetbl[m].flags AND MFL_enGr)=MFL_enGr then
      writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
             +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
    writeln;

    writeln('  *  All modes');
    writeln;
  end;

  x:=getmenkey;
  for m:=1 to nomodes do
    if ((x=0) or (x=m)) and ((modetbl[m].flags AND MFL_enGr)=MFL_enGr) then
      tmode(m);
end;


procedure testRWbank;           {Test R/W bank functions}
var x,m:word;
  md:integer;

procedure CopyLin(x0,y0,x1,y1,pix:word);
var
 pxs,px,x,y:word;
 src,dst:longint;
begin
  x:=usebits[memmode] div planes;
  src:=y0*bytes+(x0*x) div 8;
  dst:=y1*bytes+(x1*x) div 8;
  pxs:=(pix*x) div 8;
  if planes>1 then
  begin
    wrinx(GRC,3,0);
    wrinx(GRC,5,1);
  end;
  repeat
    px:=pxs;
    x:=$8000-(src and $7FFF);
    if px>x then px:=x;
    x:=$8000-(dst and $7FFF);
    if px>x then px:=x;
    setbank(dst shr 16);
    setrbank(src shr 16);
    move(mem[vseg:src],mem[vseg:dst],px);
    inc(src,px);
    inc(dst,px);
    dec(pxs,px);
  until pxs=0;
end;

procedure tmode(m:word);
var x,wid:integer;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Mode: '+hex4(curmode)+'h: '+istr(pixels)+'x'
        +istr(lins)+' '+istr(modecols[memmode])+' colors');

    wid:=(pixels div 2)-40;
    for x:=0 to lins-1 do
      CopyLin(30,x,wid+50,lins-x,wid);

    if auto_test then
    begin
      repeat until keypressed;
      SetTextMode;
      write('Did the Read/Write bank test work properly (y/n) ?');
      af_tst.Flag :=ord(getYN)*AFF_testok;
      af_cmt:=getComment('any comments to the test');

      af_tst.mode :=modetbl[m].md;
      af_tst.Mmode:=modetbl[m].memmode;
      AddAFbuf(af_tst,sizeof(af_tst));
      AddAFbuf(af_cmt,length(af_cmt)+1);
      WrAFbuf(AF_TRWbank);
    end
    else if getkey=0 then;
  end;
  settextmode;
end;

begin
  textmode($103);
  writeln('Seperate Read/Write bank test.');

  if auto_test then
  begin
    delay(1000);
    pushkey(ord('*'));
  end
  else begin
    writeln('Modes:');
    writeln;
    for m:=1 to nomodes do
      if (modetbl[m].flags AND MFL_enGr)=MFL_enGr then
      writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
             +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
    writeln;

    writeln('  *  All modes');
    writeln;
  end;

  x:=getmenkey;
  for m:=1 to nomodes do
    if ((x=0) or (x=m)) and ((modetbl[m].flags AND MFL_enGr)=MFL_enGr) then
      tmode(m);
end;

procedure testZoom;           {Test Pan & Zoom functions}
var x,m:word;
  md:integer;

procedure tmode(m:word);
var Xf,Yf,wXs,wXe,wYs,wYe,srcX,srcY:integer;
    dirty,stop:boolean;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Mode: '+hex4(curmode)+'h: '+istr(pixels)+'x'
        +istr(lins)+' '+istr(modecols[memmode])+' colors');

    Xf:=0;Yf:=0;srcX:=0;srcY:=0;
    wXs:=100;wXe:=150;wYs:=50;wYe:=75;

    ZoomOnOff(true);
    stop:=false;dirty:=true;

    repeat
      if dirty then
      begin
        if Xf<0 then Xf:=0;
        if Xf>3 then Xf:=3;
        if Yf<0 then Yf:=0;
        if Yf>3 then Yf:=3;
        SetZoomFactor(Xf,Yf);

        if wXs>wXe then wXe:=wXs;
        if wYs>wYe then wYe:=wYs;
        SetZoomWindow(wXs,wYs,wXe,wYe);

        if srcX<0 then srcX:=0;
        if srcX>=pixels then srcX:=pixels-1;
        if srcY<0 then srcY:=0;
        if srcY>=lins then srcY:=lins-1;
        setZoomAdr(srcX,srcY);
      end;
      dirty:=true;
      case getkey of
      ord('-'):dec(Yf);
      ord('+'):inc(Yf);
      ord('/'):dec(Xf);
      ord('*'):inc(Xf);
       Ch_ArUp:dec(srcY);
     Ch_ArLeft:dec(srcX);
    Ch_ArRight:inc(srcX);
     Ch_ArDown:inc(srcY);
         Ch_F1:dec(wXs);
         Ch_F2:inc(wXs);
         Ch_F3:dec(wXe);
         Ch_F4:inc(wXe);
         Ch_F5:dec(wYs);
         Ch_F6:inc(wYs);
         Ch_F7:dec(wYe);
         Ch_F8:inc(wYe);
  Ch_Esc,Ch_Cr:stop:=true;
      else dirty:=false;
      end;

    until stop;
    ZoomOnOff(false);

    if auto_test then
    begin
      repeat until keypressed;
      SetTextMode;
      write('Did the Pan & Zoom test work properly (y/n) ?');
      af_tst.Flag :=ord(getYN)*AFF_testok;
      af_cmt:=getComment('any comments to the test');

      af_tst.mode :=modetbl[m].md;
      af_tst.Mmode:=modetbl[m].memmode;
      AddAFbuf(af_tst,sizeof(af_tst));
      AddAFbuf(af_cmt,length(af_cmt)+1);
      WrAFbuf(AF_Tzoom);
    end
    else if getkey=0 then;
  end;
end;

begin
  textmode($103);
  writeln('Pan & Zoom test.');

  if auto_test then
  begin
    delay(1000);
    pushkey(ord('*'));
  end
  else begin
    writeln('Modes:');
    writeln;
    for m:=1 to nomodes do
      if (modetbl[m].flags AND MFL_enGr)=MFL_enGr then
      writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
             +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
    writeln;

    writeln('  *  All modes');
    writeln;
  end;

  x:=getmenkey;
  for m:=1 to nomodes do
    if ((x=0) or (x=m)) and ((modetbl[m].flags AND MFL_enGr)=MFL_enGr) then
      tmode(m);
end;

procedure testbits;           {Test register bits}
var m,pt,ix,msk:word;
  md,x:integer;
  s:string;

function tmode(m:word):boolean;
const
  mask:array[0..7] of byte=(1,2,4,8,16,32,64,128);
var
  stop:boolean;
  x:word;
begin
  tmode:=true;
  if InitMode(m) then
  begin
    case memmode of
      _text,_txt2,_txt4:
              lins:=32768 div bytes;
      _cga1,_cga2:
              lins:=16384 div bytes;
         _pl1:lins:=cv.mm*longint(256) div bytes;
    else lins:=cv.mm*longint(1024) div (bytes*planes);
    end;

    Clearmemory;

    clrinx(crtc,$11,$80);
    drawtestpattern(s);
    stop:=false;
    repeat
      wrtext(10,180,'Reg '+hex4(pt)+'h index '+hex2(ix)+'h bit '+chr(msk+48));
      x:=rdinx(pt,ix);
      wrinx(pt,ix,x xor mask[msk]);
      wrtext(220,180,'= '+chr(48+(rdinx(pt,ix) shr msk) and 1));
      delay(500);
      wrinx(pt,ix,x);
      wrtext(220,180,'= '+chr(48+(rdinx(pt,ix) shr msk) and 1));
      delay(500);

      if keypressed then
        case getkey of
           ord('-'):if msk>0 then dec(msk)
                    else begin
                      msk:=7;
                      dec(ix);
                    end;
           ord('+'):begin
                      inc(msk);
                      if msk>7 then
                      begin
                        msk:=0;
                        inc(ix);
                      end;
                    end;
           ord('*'):begin
                      inc(ix);
                      msk:=0;
                    end;
             Ch_Esc:stop:=true;
        end;
    until stop;
    SetTextmode;
  end;
end;

begin
  textmode($103);
  writeln('Test register bits.');
  writeln;
  write('Base register (hex): ');
  readln(s);
  pt:=dehex(s);
  write('Start Index (hex 0-FFh): ');
  readln(s);
  ix:=dehex(s);
  write('Start Bit (0-7): ');
  readln(s);
  msk:=ord(s[1]) and 7;
  writeln;
  writeln('Testing register bits, starting with '+hex4(pt)+'h index '+hex2(ix)+'h bit '+chr(msk+48)+'.');
  writeln;
  writeln('  +  Steps up to the next bit (and possibly next index)');
  writeln('  -  Steps back to the last bit');
  writeln('  *  Steps to the next index, bit 0');
  writeln(' Esc Terminates the test');
  writeln;

  writeln('Modes:');
  writeln;
  for m:=1 to nomodes do
  begin
    writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
           +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
  end;
  writeln;
  x:=getmenkey;
  for m:=1 to nomodes do
    if (x=m) then
      if not tmode(m) then x:=-1;  {stop}

end;


procedure testregs;           {Test register Read/Writable}
var m,pt,ix,msk:word;
  md,x:integer;
  s,IM:string;

function tmode(md:word):boolean;
const
  bit:array[0..7] of byte=(1,2,4,8,16,32,64,128);
var
  x,y,z,i:word;
  msk:array[0..2047] of char;
  v0:array[0..255] of byte;
  imsk:array[0..7] of char;

procedure writelog;
var x:word;
begin
  wrlog('Register test for index '+hex4(pt)+'h  Index mask: '
       +imsk[0]+imsk[1]+imsk[2]+imsk[3]+imsk[4]+imsk[5]+imsk[6]+imsk[7]);
  writeln('     01234567 01234567 01234567 01234567 01234567 01234567 01234567 01234567');
  for x:=0 to 2047 do
  begin
    if (x and 63)=0 then s:=' '+hex2(x shr 3)+':';
    if (x and 7)=0 then s:=s+' ';
    s:=s+msk[x];
    if (x and 63)=63 then wrlog(s);
  end;
  closelog;
end;

begin
  tmode:=true;
  if setMode(md,true) then
  begin
    clrinx(crtc,$11,$80);
    drawtestpattern(s);
    fillchar(imsk,8,'W');
    y:=inp(pt);z:=0;
    for x:=0 to 7 do  {Check if each bit of the index register is RW}
    begin
      outp(pt,y and not bit[x and 7]);
      if (inp(pt) and bit[x and 7])>0 then imsk[x]:='1';
      outp(pt,y or bit[x and 7]);
      if (inp(pt) and bit[x and 7])=0 then imsk[x]:='0';
      outp(pt,y);
      if IM[x+1]=' ' then im[x+1]:=imsk[x];
    end;

    z:=0;y:=0;
    for x:=1 to 8 do
    begin
      if (im[x]='0') or (im[x]='1') then z:=z or bit[x-1]*8;
      if (im[x]='1') then y:=y or bit[x-1]*8;
    end;



    fillchar(msk,sizeof(msk),'W');  {Set all bits off}
    for x:=0 to 2047 do
      if ((x xor y) and z)>0 then msk[x]:='.';

    for y:=0 to 255 do v0[y]:=rdinx(pt,y);
    for x:=1 to 10 do
      for y:=0 to 255 do   {Find any bits that changes if read again}
      begin
        z:=v0[y] xor rdinx(pt,y);
        for i:=0 to 7 do                   {Check each bit}
          if (z and bit [i])>0 then msk[y*8+i]:='A';
      end;
    openlog(false);
    wrlog('After re-read test');
    writelog;

    for x:=0 to 2047 do  {Check that each bit is R/W}
      if msk[x]='W' then
      begin
        y:=x shr 3;
        wrinx(pt,y,v0[y] and not bit[x and 7]);
        if (rdinx(pt,y) and bit[x and 7])>0 then msk[x]:='1';
        wrinx(pt,y,v0[y] or bit[x and 7]);
        if (rdinx(pt,y) and bit[x and 7])=0 then msk[x]:='0';
        wrinx(pt,y,v0[y]);
      end;
    openlog(false);
    wrlog('After R/W test');
    writelog;

    for x:=1 to 2047 do   {Try to change one of the other bits}
      if msk[x]='W' then      {and see if we changes with it}
      begin
        y:=x shr 3;
        wrinx(pt,y,v0[y] xor bit[x and 7]);
        for z:=0 to x-1 do
          if (msk[z]='W') and (((v0[z shr 3] xor rdinx(pt,z shr 3))
             and bit[z and 7])>0) then msk[z]:='C';
        wrinx(pt,y,v0[y]);
        for z:=0 to x-1 do
          if (msk[z]='W') and (((v0[z shr 3] xor rdinx(pt,z shr 3))
             and bit[z and 7])>0) then msk[z]:='C';
      end;
    openlog(true);
    writelog;
    if readkey='' then;
  end;
end;

begin
  SetTextMode;
  writeln('Test register bits.');
  writeln;
  write('Base register (hex): ');
  readln(s);
  pt:=dehex(s);
  writeln;
  Write('Index mask (low bit first: 0/1/x/ ): ');
  readln(IM);IM:=copy(IM+'        ',1,8);
  for m:=1 to 8 do
    if (IM[m]<>'x') and (IM[m]<>'0') and (IM[m]<>'1') then IM[m]:=' ';

  writeln('Testing indexed registers for base='+hex4(pt)+'h.');
  writeln;

  if (nomodes=0) and tmode($12) then
  else begin
    writeln('Modes:');
    writeln;
    for m:=1 to nomodes do
    begin
      writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
             +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
    end;
    writeln;
    x:=getmenkey;
    if (x>0) and (x<=nomodes) and tmode(modetbl[x].md) then;  {stop}
  end;
end;


procedure testDACgamma;
var i,j,x,colorsh,
  redi,redc,grni,grnc,blui,bluc,
  gamm,oldgam:integer;
  stop:boolean;
  red,grn,blu:array[0..255] of byte;
begin
  SetTextMode;
  writeln('Mode for gamma test:');
  for i:=1 to nomodes do
    if ((modetbl[i].flags and MFL_enGr)=MFL_enGr)
      and (modetbl[i].memmode>_P8) then
    writeln('  '+menuchars[i]+' '+hex4(modetbl[i].md)+'h '
           +istr(modetbl[i].xres)+'x'+istr(modetbl[i].yres)
           +' '+mdtxt[modetbl[i].memmode]);
  write('Select mode: ');
  i:=getmenkey;
  if (i<=0) or (i>nomodes) or (modetbl[i].memmode<=_P8) then i:=0;
  if InitMode(i) then
  begin
    drawtestpattern('Test DAC gamma correction');
    wrtext(30,120,'Press + to toggle the gamma correction off/red/green/blue');
    wrtext(30,140,'One of the scales will be inverted, the other two unchanged.');
    stop:=false;
    gamm:=0;
    oldgam:=-1;
    repeat
      if gamm<>oldgam then
      begin
        if gamm=0 then x:=setDACgamma(false)
        else begin
          x:=setDACgamma(true);
          if (x and GAM_8bit)=0 then colorsh:=4 else colorsh:=1;
          redi:=0;grni:=0;
          if memmode>=_P24 then
          begin
            redc:=1;grnc:=1;
          end
          else begin
            redc:=8;grnc:=8;
            if (memmode=_P16) then grnc:=4;
            if (x and GAM_Left8)>0 then redi:=3;
            if (x and GAM_Left8)>0 then redi:=1;
            grni:=redi;
            if (grni>0) and (memmode=_P16) then dec(grni);

          end;

          blui:=redi;bluc:=redc;
          for i:=0 to 255 do
          begin
            if gamm=1 then j:=255-i else j:=i;    {Check for inversion}
            red[i]:=((j shr redi)*redc) div colorsh;
            if gamm=2 then j:=255-i else j:=i;
            grn[i]:=((j shr grni)*grnc) div colorsh;
            if gamm=3 then j:=255-i else j:=i;
            blu[i]:=((j shr blui)*bluc) div colorsh;
          end;
          SetRGBPal(0,0,0,0);  {Keep (0,0,0) as black for background}
          for i:=1 to 255 do
            SetRGBPal(i,red[i],grn[i],blu[i]);
        end;
        oldgam:=gamm;
      end;
      if keypressed then
        case getkey of
           ord('+'):gamm:=(gamm+1) and 3;
       Ch_Esc,Ch_Cr:stop:=true;
        end;
    until stop;
    x:=setDACgamma(false);   {Remove Gamma}
    setdac8(false);  {Return to 6bit DAC mode}

    SetTextMode;
  end;
end;


procedure testdac8(m:word);           {Test 8bit DAC mode}
var
  stop,dac8,olddac:boolean;
  x,y,cmd:word;
  mm:byte;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Test 6/8 bit DAC');
    wrtext(30,230,'Press + to toggle the DAC mode');
    wrtext(30,245,'6bit DAC mode should show the color scales breaking 3 times each');
    wrtext(30,260,'8bit DAC mode should show unbroken color scales');
    for y:=0 to 127 do
      for x:=0 to 255 do
        setpix(x+30,y+100,(x shr 2)+(y and $60)*2);
    cmd:=0;
    stop:=false;
    dac8:=false;
    olddac:=not dac8;
    repeat
      if dac8<>olddac then
      begin
        setdac8(dac8);

        for x:=0 to 63 do SetRGBPal(x,x*4,0,0);
        for x:=0 to 63 do SetRGBPal(x+$40,0,x*4,0);
        for x:=0 to 63 do SetRGBPal(x+$80,0,0,x*4);
        for x:=0 to 63 do SetRGBPal(x+$C0,x*4,x*4,x*4);
        olddac:=dac8;
      end;
      if keypressed then
        case getkey of
           ord('+'):dac8:=not dac8;
       Ch_Esc,Ch_Cr:stop:=true;
        end;
    until stop;
    setdac8(false);

    SetTextMode;
  end;
end;


procedure testdac15(m:word);           {Test 8bit DAC mode}
var
  stop,dac8,olddac:boolean;
  x,y,cmd:word;
  mm:byte;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Test 15bit (32Kcolor) DAC mode');
    wrtext(30,230,'Press + to toggle the DAC mode');
    wrtext(30,248,'The image above is for normal (palette) mode and the one');
    wrtext(30,266,'below is for 15bit mode. Both should have the Red stripe');
    wrtext(30,284,'at the top, then green, blue and finally white.');
    for y:=0 to 127 do
      for x:=0 to 255 do
        setpix(x+30,y+100,(x shr 2)+(y and $60)*2);
    memmode:=_p15;
    for y:=0 to 15 do
      for x:=0 to 255 do
      begin
        setpix(x+30,y+305,RGB(x,0,0));
        setpix(x+30,y+321,RGB(0,x,0));
        setpix(x+30,y+337,RGB(0,0,x));
        setpix(x+30,y+353,RGB(x,x,x));
      end;

    memmode:=_P8;
    stop:=false;
    dac8:=false;
    olddac:=not dac8;
    repeat
      if dac8<>olddac then
      begin
        if not dac8 then setDACstd
        else if setdac15 then;
        olddac:=dac8;
      end;
      if keypressed then
        case getkey of
           ord('+'):dac8:=not dac8;
       Ch_Esc,Ch_Cr:stop:=true;
        end;
    until stop;
    setdacstd;

    SetTextMode;
  end;
end;

procedure testdac16(m:word);           {Test 8bit DAC mode}
var
  stop,dac8,olddac:boolean;
  x,y,cmd:word;
  mm:byte;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Test 16bit (64Kcolor) DAC mode');
    wrtext(30,230,'Press + to toggle the DAC mode');
    wrtext(30,248,'The image above is for normal (palette) mode and the one');
    wrtext(30,266,'below is for 16bit mode. Both should have the Red stripe');
    wrtext(30,284,'at the top, then green, blue and finally white.');
    for y:=0 to 127 do
      for x:=0 to 255 do
        setpix(x+30,y+100,(x shr 2)+(y and $60)*2);
    memmode:=_p16;
    for y:=0 to 15 do
      for x:=0 to 255 do
      begin
        setpix(x+30,y+305,RGB(x,0,0));
        setpix(x+30,y+321,RGB(0,x,0));
        setpix(x+30,y+337,RGB(0,0,x));
        setpix(x+30,y+353,RGB(x,x,x));
      end;

    memmode:=_P8;
    stop:=false;
    dac8:=false;
    olddac:=not dac8;
    repeat
      if dac8<>olddac then
        if not dac8 then setDACstd
        else if setdac16 then;
      olddac:=dac8;
      case getkey of
         ord('+'):dac8:=not dac8;
     Ch_Esc,Ch_Cr:stop:=true;
      end;
    until stop;
    setdacstd;
    SetTextMode;
  end;
end;

procedure testdac24(m:word);           {Test 8bit DAC mode}
var
  stop,dac8,olddac:boolean;
  x,y,cmd:word;
  mm:byte;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Test 24bit (16Mcolor) DAC mode');
    wrtext(30,230,'Press + to toggle the DAC mode');
    wrtext(30,248,'The image above is for normal (palette) mode and the one');
    wrtext(30,266,'below is for 24bit mode. Both should have the Red stripe');
    wrtext(30,284,'at the top, then green, blue and finally white.');
    for y:=0 to 127 do
      for x:=0 to 255 do
        setpix(x+30,y+100,(x shr 2)+(y and $60)*2);
    memmode:=_p24;
    for y:=0 to 15 do
      for x:=0 to 255 do
      begin
        setpix(x+30,y+305,RGB(x,0,0));
        setpix(x+30,y+321,RGB(0,x,0));
        setpix(x+30,y+337,RGB(0,0,x));
        setpix(x+30,y+353,RGB(x,x,x));
      end;

    memmode:=_P8;
    stop:=false;
    dac8:=false;
    olddac:=not dac8;
    repeat
      if dac8<>olddac then
      begin
        if not dac8 then setDACstd
        else if setdac24 then;
        olddac:=dac8;
      end;
      if keypressed then
        case getkey of
           ord('+'):dac8:=not dac8;
       Ch_Esc,Ch_Cr:stop:=true;
        end;
    until stop;
    setdacstd;

    SetTextMode;
  end;
end;

procedure testdac32(m:word);           {Test 8bit DAC mode}
var
  stop,dac8,olddac:boolean;
  x,y,cmd:word;
  mm:byte;
begin
  if InitMode(m) then
  begin
    drawtestpattern('Test 32bit (16Mcolor - RGBa) DAC mode');
    wrtext(30,230,'Press + to toggle the DAC mode');
    wrtext(30,248,'The image above is for normal (palette) mode and the one');
    wrtext(30,266,'below is for 32bit mode. Both should have the Red stripe');
    wrtext(30,284,'at the top, then green, blue and finally white.');
    for y:=0 to 127 do
      for x:=0 to 255 do
        setpix(x+30,y+100,(x shr 2)+(y and $60)*2);
    memmode:=_p32;
    for y:=0 to 15 do
      for x:=0 to 255 do
      begin
        setpix(x+30,y+305,RGB(x,0,0));
        setpix(x+30,y+321,RGB(0,x,0));
        setpix(x+30,y+337,RGB(0,0,x));
        setpix(x+30,y+353,RGB(x,x,x));
      end;

    memmode:=_P8;
    stop:=false;
    dac8:=false;
    olddac:=not dac8;
    repeat
      if dac8<>olddac then
      begin
        if not dac8 then setDACstd
        else if setdac32 then;
        olddac:=dac8;
      end;
      if keypressed then
        case getkey of
           ord('+'):dac8:=not dac8;
       Ch_Esc,Ch_Cr:stop:=true;
        end;
    until stop;
    setdacstd;

    SetTextMode;
  end;
end;



  {Test the DAC Cmd register}
procedure testdaccmd(m:word);
var
  stop:boolean;
  x,y,cmd,pel:word;
function bin(w:word):string;
var s:string[10];
  i:integer;
begin
  s:='';
  for i:=7 downto 0 do
    s:=s+chr(((w shr i) and 1) +48);
  bin:=s;
end;

procedure newcmd(cmd:word);
var x,pel:word;
begin
  if cv.chip=__cir54 then
  begin
    pel:=inp($3C6);
    outp($3C6,0);
  end;

  outp(setDACpage(dacHIcmd),cmd);
  clearDACpage;
  x:=inp(setDACpage(dacHIcmd)) xor cmd;
  clearDACpage;
  wrtext(10,10,'DAC Command: '+hex2(cmd)+'h, '+bin(cmd)+'b  XOR: '+hex2(x)+'h, '+bin(x)+'b:');
  for x:=0 to 63 do
  begin
    SetRGBPal(x,x*4,0,0);
    SetRGBPal(x+$40,0,x*4,0);
    SetRGBPal(x+$80,0,0,x*4);
    SetRGBPal(x+$C0,x*4,x*4,x*4);
  end;
  if cv.chip=__cir54 then outp($3C6,pel);
end;

begin
  if InitMode(m) then
  begin
    drawtestpattern('Test DAC Command register');

    for y:=100 to 230 do
      for x:=30 to 170 do
        setpix(x,y,0);

    for y:=0 to 63 do
      for x:=0 to 255 do
        setpix(x+30,y+100,(x shr 2)+(y and $30)*4);

    memmode:=_p15;
    for y:=0 to 15 do
      for x:=0 to 255 do
      begin
        setpix(x+30,y+180,RGB(x,0,0));
        setpix(x+30,y+196,RGB(0,x,0));
        setpix(x+30,y+212,RGB(0,0,x));
        setpix(x+30,y+228,RGB(x,x,x));
      end;

    memmode:=_p16;
    for y:=0 to 15 do
      for x:=0 to 255 do
      begin
        setpix(x+30,y+260,RGB(x,0,0));
        setpix(x+30,y+276,RGB(0,x,0));
        setpix(x+30,y+292,RGB(0,0,x));
        setpix(x+30,y+308,RGB(x,x,x));
      end;

    memmode:=_p24;
    for y:=0 to 15 do
      for x:=0 to 127 do
      begin
        setpix(x+24,y+340,RGB(x*2,0,0));
        setpix(x+24,y+356,RGB(0,x*2,0));
        setpix(x+24,y+372,RGB(0,0,x*2));
        setpix(x+24,y+388,RGB(x*2,x*2,x*2));
      end;

    memmode:=_p32;
    for y:=0 to 15 do
      for x:=0 to 127 do
      begin
        setpix(x+24,y+420,RGB(x*2,0,0));
        setpix(x+24,y+436,RGB(0,x*2,0));
        setpix(x+24,y+452,RGB(0,0,x*2));
        setpix(x+24,y+468,RGB(x*2,x*2,x*2));
      end;

    memmode:=_P8;
    wrtext(5,180,'15');
    wrtext(5,260,'16');
    wrtext(5,340,'24');
    wrtext(5,420,'32');
    wrtext(50,30,'Press F1..F8 to toggle the DAC mode bits 0..7');

    stop:=false;

    if cv.chip=__cir54 then
    begin
      pel:=inp($3C6);
      outp($3C6,0);
    end;
    cmd:=inp(SetDACpage(dacHIcmd));
    clearDACpage;
    if cv.chip=__cir54 then outp($3C6,pel);
    repeat
      newcmd(cmd);
      case getkey of
        Ch_F1:cmd:=cmd xor 1;
        Ch_F2:cmd:=cmd xor 2;
        Ch_F3:cmd:=cmd xor 4;
        Ch_F4:cmd:=cmd xor 8;
        Ch_F5:cmd:=cmd xor 16;
        Ch_F6:cmd:=cmd xor 32;
        Ch_F7:cmd:=cmd xor 64;
        Ch_F8:cmd:=cmd xor 128;
   ord('A'),ord('a'):for x:=0 to 255 do
                     begin
                       newcmd(x);
                       delay(1000);
                     end;
        Ch_Esc,Ch_Cr:stop:=true;
      end;
    until stop;
    clearDACpage;
    setdacstd;

    SetTextMode;
  end;
end;


  {Analyse the DAC Cmd register}
procedure testdaccmdAnal(m:word);
const
  msk:array[0..3] of byte=($55,$AA,$5A,$A5);
var
  stop:boolean;
  mask,x,y,z,i,mk,cmd,chg:word;
  res0:array[0..39] of byte;
  res:array[byte] of byte;
  t:text;
  s:string;

function DacBit(cmd:integer):integer;
begin
  dac2comm;
  outp($3C6,cmd);
  dac2pel;
  dac2comm;
  DacBit:=inp($3C6);
  dac2pel;
end;

begin
  if InitMode(m) then
  begin
    for x:=0 to 3 do
    begin
      dac2pel;
      outp($3C6,msk[x]);
      dac2pel;
      for y:=0 to 9 do res0[x*10+y]:=inp($3C6);
      dac2pel;
    end;
    dac2pel;
    outp($3C6,$FF);
    setdacstd;
    SetTextMode;

    x:=DacBit(0);
    mk:=0;
    for x:=0 to 7 do
    begin
      y:=1 shl x;
      z:=DacBit(y);
      mk:=mk+(z and y);
    end;
    clearDACpage;
    setdacstd;      {Write the data several times in case we lock up...}
    SetTextMode;

    if cv.chip=__cir54 then i:=$FD else i:=$FF;
    if cv.dactype=_dacTR8001 then i:=$FB;
    x:=0;y:=255;z:=255;
    for cmd:=0 to 255 do
    begin
      res[cmd]:=DacBit(cmd and i);
      x:=x or  res[cmd];
      y:=y and res[cmd];
      z:=z and (res[cmd] xor not cmd);
    end;
    chg:=z and (x and not y);
    mask:=i;
  end;
  clearDACpage;
  setdacstd;
  SetTextMode;
  OpenLog(true);
  wrlog(  '  DAC Command register read test:');
  wrlog(  'Read:  $55  $AA  $5A  $A5');
  for i:=0 to 9 do
    wrlog('  '+chr(i+48)+'    '+hex2(res0[i])+'   '+hex2(res0[i+10])
                      +'   '+hex2(res0[i+20])+'   '+hex2(res0[i+30]));
  wrlog('');
  wrlog('Dac Single Bit Mask: '+hex2(mk));
  wrlog('');
  wrlog('DAC mask: '+hex2(mask)+'h R/W: '+hex2(z)+'h Chg: '+hex2(chg)
           +' Set: '+hex2(y)+'h Clear: '+hex2(not x)+'h');
  z:=z or chg;
  s:='';
  for i:=0 to 255 do
    if ((res[i] xor i) and z)<>0 then
      s:=s+'  '+hex2(i)+' = '+hex2(res[i])+' ';
  wrlog(s);
  closelog;
  if readkey='' then;
end;

  {DAC test master menu}
procedure testdac;
var i,md:word;
   stop:boolean;
begin
  md:=0;
  for i:=1 to nomodes do
    if ((modetbl[i].flags AND MFL_enGr)=MFL_enGr) AND (modetbl[i].memmode=_p8)
     and (modetbl[i].xres=640) and (modetbl[i].yres=480) then md:=i;
  stop:=false;
  repeat
    SetTextMode;
    writeln('DAC test options:');
    writeln('  2 - Test 24bit (16Mcolor) mode');
    writeln('  3 - Test 32bit (16Mcolor RGBa) mode');
    writeln('  5 - Test 15bit (32Kcolor) mode');
    writeln('  6 - Test 16bit (64Kcolor) mode');
    writeln('  8 - Test 6/8bit mode');
    writeln('  A - DAC Cmd register Analysis');
    writeln('  C - Test Command register');
    writeln('  G - Test Gamma Correction');
    writeln('  M - Select base mode');
    writeln('  0 - Return to main menu');

    case getkey of
           ord('2'):testdac24(md);
           ord('3'):testdac32(md);
           ord('5'):testdac15(md);
           ord('6'):testdac16(md);
           ord('8'):testdac8(md);
  ord('a'),ord('A'):testdaccmdAnal(md);
  ord('c'),ord('C'):testdaccmd(md);
  ord('g'),ord('G'):testDACgamma;
  ord('m'),ord('M'):begin
                      writeln;
                      for i:=1 to nomodes do
                        if ((modetbl[i].flags and MFL_enGr)=MFL_enGr)
                          and (modetbl[i].memmode=_P8) then
                        writeln('  '+menuchars[i]+' '+hex4(modetbl[i].md)+'h '
                               +istr(modetbl[i].xres)+'x'+istr(modetbl[i].yres)
                               +' '+mdtxt[modetbl[i].memmode]);
                      write('Select mode: ');
                      i:=getmenkey;
                      if (i>0) and (i<=nomodes) and (modetbl[i].memmode=_P8) then md:=i;
                    end;
    ord('0'),Ch_Esc:stop:=true;
    end;
  until stop;

end;


procedure testvgamodes;           {Test extended modes}
var m:word;
  md,x:integer;

function tmode(m:word):boolean;
begin
  tmode:=true;

  if auto_test then
  begin
    fillchar(af_rec,sizeof(af_rec),0);
    af_cmt:='';
  end;

  if InitMode(m) then tmode:=testvmode;

  if auto_test then
  begin
    af_rec.mode  :=modetbl[m].md;
    af_rec.Mmode :=memmode;
    af_rec.pixels:=pixels;
    af_rec.lins  :=lins;
    af_rec.bytes :=bytes;
    af_rec.crtc  :=crtc;
    AddAFBuf(af_rec,sizeof(af_rec));
    AddAFbuf(af_cmt,length(af_cmt)+1);
    inc(af_pos,FormatRgs(af_buf[af_pos]));

    WrAFbuf(AF_modeinfo);
  end;
end;

begin
  textmode($103);
  writeln('Test extended VGA modes.');
  writeln('Modes:');
  writeln;
  for m:=1 to nomodes do  {Not the Std VGA modes}
    if ((modetbl[m].flags and MFL_enVGA)=MFL_enabled) then
      writeln('  '+menuchars[m]+' '+hex4(modetbl[m].md)+'h '+istr(modetbl[m].xres)
             +'x'+istr(modetbl[m].yres)+' '+mdtxt[modetbl[m].memmode]);
  writeln;

  writeln('  *  All modes');
  if auto_test then pushkey(ord('*'));
  writeln;
  x:=getmenkey;
  for m:=1 to nomodes do
    if ((x=0) or (x=m)) and ((modetbl[m].flags and MFL_enGrVGA)=MFL_enGr) then
      if not tmode(m) then x:=-1;  {stop}
end;

procedure teststdvgamodes;          {Test standard VGA modes}
var m:word;
  md,x:integer;

function tmode(m:word):boolean;
begin

  if auto_test then
  begin
    fillchar(af_rec,sizeof(af_rec),0);
    af_cmt:='';
  end;


  if InitMode(m) then tmode:=testvmode;

  if auto_test then
  begin
    af_rec.mode  :=stdmodetbl[m].md;
    af_rec.Mmode :=memmode;
    af_rec.pixels:=pixels;
    af_rec.lins  :=lins;
    af_rec.bytes :=bytes;
    af_rec.crtc  :=crtc;
    AddAFBuf(af_rec,sizeof(af_rec));
    AddAFbuf(af_cmt,length(af_cmt)+1);
    inc(af_pos,FormatRgs(af_buf[af_pos]));
    WrAFbuf(AF_modeinfo);
  end;
end;

begin
  textmode($103);
  writeln('Standard VGA mode test.');
  writeln;
  writeln('Modes:');
  writeln;
  for m:=1 to novgamodes do
  begin
    writeln('  '+menuchars[m]+' '+hex4(stdmodetbl[m].md)+'h '+istr(stdmodetbl[m].xres)
           +'x'+istr(stdmodetbl[m].yres)+' '+mdtxt[stdmodetbl[m].memmode]);
  end;
  writeln;
  writeln('  *  All modes');

  writeln;
  if auto_test then pushkey(ord('*'));
  x:=getmenkey;
  for m:=1 to novgamodes do
    if (x=0) or (x=m) then
      if not tmode(m) then x:=-1;

end;


procedure searchformodes;      {Run through all possible modes
                                and try to id any new ones}
type
  regblk=record
           base:word;
           nbr:word;
           x:array[0..255] of byte;
         end;
var
  md,m,hig,wid,x,y,oldbytes,wordadr:word;
  c:char;
  ofil:text;
  attregs:array[0..31] of byte;
  seqregs,grcregs,crtcregs,xxregs:regblk;
  stdregs:array[$3C0..$3DF] of byte;
  l:longint;
  s:string;
  stop:boolean;


procedure dumprg(base:word;var rg:regblk);
var six,ix:word;
begin
  rg.base:=base;
  six:=inp(base);
  outp(base,0);
  ix:=inp(base) xor 255;
  outp(base,255);
  ix:=ix and inp(base);

  if ix>127 then rg.nbr:=255
  else if ix>63 then rg.nbr:=127
  else if ix>31 then rg.nbr:=63
  else if ix>15 then rg.nbr:=31
  else if ix>7 then rg.nbr:=15
  else rg.nbr:=7;
  for ix:=0 to rg.nbr do
    rg.x[ix]:=rdinx(base,ix);
  outp(base,six);
end;




begin
  md:=$14;
  stop:=false;
  while (md<$80) and not stop do
  begin
    textmode(3);
    gotoxy(10,10);
    write('Testing mode: '+hex2(md));
    delay(500);
    if setmode(md,true) then
    begin
      pixels :=calcpixels;
      lins   :=calclines;
      bytes  :=calcbytes;
      vseg   :=calcvseg;
      memmode:=calcmmode;
      repeat
        oldbytes:=bytes;

        if setmode(md,true) and testvmode then
        begin
        {  drawtestpattern('Mode: '+hex2(md)+' ('+istr(pixels)+'x'+istr(lins)+' '
                   +mmodenames[memmode]+') '+istr(bytes)+' bytes.'); }
        end;

      (*  case getkey of
          Ch_PgUp:bytes:=bytes shl 1;
          Ch_PgDn:bytes:=bytes shr 1;
          Ch_ArUp:inc(bytes);
        Ch_ArDown:dec(bytes);
           Ch_Esc:stop:=true;
        end; *)
      until bytes=oldbytes;
    end;
    inc(md);
  end;
  textmode(3);
end;



var
  stop:boolean;

function ljust(s:string;lnn:word):string;
begin
  ljust:=copy(s+'          ',1,lnn);
end;

function rjust(s:string;lnn:word):string;
begin
  if length(s)<lnn then s:=copy('          ',1,lnn-length(s))+s;
  rjust:=s;
end;

function chkptr(w:word):word;
begin
  if memw[Seg0000:w+2]=biosseg then chkptr:=memw[Seg0000:w]
                               else chkptr:=0;
end;

function fntadr(BH:word):word;
begin
  rp.bh:=BH;
  vio($1130);
  if rp.es=biosseg then fntadr:=rp.bp
  else fntadr:=0;
end;

procedure wrAFff;
var
  rhdr:_ATff;
  x,y,z,v:word;
begin
  if {af_fail and} (biosseg<>0) then
  begin
    fillchar(rhdr,sizeof(rhdr),0);
    rhdr.base :=biosseg;
    rhdr.size :=mem[biosseg:2];
    rhdr.int10:=chkptr($40);
    rhdr.int6D:=chkptr($1B4);
    rhdr.m4A8 :=chkptr($4A8);
    rhdr.fnt14  :=fntadr(2);
    rhdr.fnt8l  :=fntadr(3);
    rhdr.fnt8h  :=fntadr(4);
    rhdr.fnt14x9:=fntadr(5);
    rhdr.fnt16  :=fntadr(6);
    rhdr.fnt16x9:=fntadr(7);
    AddAFbuf(rhdr,sizeof(rhdr));
    WrAFbuf(AF_BIOSdmp);
    y:=0;z:=0;
    for x:=0 to (rhdr.size*512-1) do
    begin
      v:=mem[biosseg:x];
      af_buf[z]:=v-y;
      y:=v;
      inc(z);
      if z>=2000 then
      begin
        blockwrite(af_fil,af_buf,z);
        z:=0;
      end;
    end;
    blockwrite(af_fil,af_buf,z);
  end;
end;


procedure ReCalc(rfil:string);
var f:file;
    t:text;
  at0:_AT0;
  at2:_AT2;
  buf:array[0..2000] of byte;
  hdr:record
        typ:byte;
        lnn:word;
      end;
 fpos:longint;
   ix,x,y,z,w:word;
   s:string[5];

function popb:word;
begin
  popb:=buf[ix];
  inc(ix);
end;

function popw:word;
var w:word;
begin
  move(buf[ix],w,2);
  inc(ix,2);
  popw:=w;
end;

procedure stinx(base,ix,vl:word);
begin
  case base of
   $3C0:rgs.attregs[ix]:=vl;
   $3C4:begin
          rgs.seqregs.x[ix]:=vl;
          if ix>rgs.seqregs.nbr then rgs.seqregs.nbr:=ix;
        end;
   $3CE:begin
          rgs.grcregs.x[ix]:=vl;
          if ix>rgs.grcregs.nbr then rgs.grcregs.nbr:=ix;
        end;
   $3B4,
   $3D4:begin
          rgs.crtcregs.x[ix]:=vl;
          if ix>rgs.crtcregs.nbr then rgs.crtcregs.nbr:=ix;
        end;
  else
    rgs.xxregs.base:=base;
    rgs.xxregs.x[ix]:=vl;
    if ix>rgs.xxregs.nbr then rgs.xxregs.nbr:=ix;
  end;
end;

begin
  if pos('.',rfil)=0 then rfil:=rfil+'.tst';
  assign(f,rfil);
  {$i-}
  reset(f,1);
  {$i+}
  if ioresult=0 then
  begin
    rfil[0]:=chr(pred(pos('.',rfil)));
    assign(t,rfil+'.tt');
    rewrite(t);
    fpos:=0;vids:=0;
    repeat
      blockread(f,hdr,3);
      case hdr.typ of
        0:blockread(f,at0,sizeof(_AT0));
        1:begin
            inc(vids);
            blockread(f,vid[vids],sizeof(vid[1]));
            if vids=at0.cur_vid then SelectVideo(vids);
          end;
        2:begin
            blockread(f,at2,sizeof(at2));
            blockread(f,buf,hdr.lnn-sizeof(at2)-3);
            ix:=buf[0]+1;
            repeat
              w:=popw;
              case w of
                1:begin
                    w:=popw;
                    x:=popb;y:=popb;
                    for x:=x to y do stinx(w,x,popb);
                  end;
           2..$FE:begin
                    x:=popw;
                    for x:=x to x+w-1 do
                    begin
                      y:=popb;
                      if (x>=$3C0) and (x<$3DF) then rgs.stdregs[x]:=y;
                      if (x>=$3B0) and (x<$3BF) then rgs.stdregs[x+$20]:=y;
                    end;
                  end;
              $ff:begin
                    w:=popw;
                    x:=popb;
                    case w of
                      0:rgs.tridold0d:=x;
                      1:rgs.tridold0e:=x;
                    end;
                  end;
              else
                x:=popb;
                if (w>=$3C0) and (w<$3DF) then rgs.stdregs[w]:=x;
                if (w>=$3B0) and (w<$3BF) then rgs.stdregs[w+$20]:=x;
              end;
            until w=0;
            if (at2.flag and 1)>0 then
            begin
              CalcRegisters;
              if (at2.mmode=rgs.mmode) and (at2.pixels=rgs.pixels)
               and (at2.lins=rgs.lins) and (at2.bytes=rgs.bytes) then s:=' Ok' else s:='';
              writeln(t,hex4(at2.mode),at2.pixels:5,at2.lins:5,at2.bytes:5
                       ,' '+mmodenames[at2.mmode]+' vs. '
                       ,rgs.pixels:5,rgs.lins:5,rgs.bytes:5
                       ,' '+mmodenames[rgs.mmode]+s);
            end;
          end;
      end;
      inc(fpos,hdr.lnn);
      seek(f,fpos);
    until hdr.typ>2;
    close(t);
    close(f);
  end;
end;


procedure testdacbits;
var
  dac0,dac1,dac2,dac3:byte;
  pt,ix,i,old:integer;
  s:string;
begin
  settextmode;
  write('Base register (hex): ');
  readln(s);
  pt:=dehex(s);
  write('Index (hex 0-FFh): ');
  readln(s);
  ix:=dehex(s);
  dac0:=inp($3C8);
  dac1:=inp($3C9);
  dac2:=inp($3C6);
  dac3:=inp($3C7);
  old:=rdinx(pt,Ix);
  writeln('Original: '+hex2(dac0)+' '+hex2(dac1)+' '+hex2(dac2)+' '+hex2(dac3));
  for i:=0 to 7 do
  begin
    wrinx(pt,Ix,old xor (1 shl i));
    dac0:=inp($3C8);
    dac1:=inp($3C9);
    dac2:=inp($3C6);
    dac3:=inp($3C7);
    wrinx(pt,Ix,old);
    writeln('  Bit  ',i,': '+hex2(dac0)+' '+hex2(dac1)+' '+hex2(dac2)+' '+hex2(dac3));
  end;
  if readkey='' then;
end;





var
  chp:byte;
  md,x,y,b:integer;
  s,fea:string;
  iteration,err,sel,clks:word;
  t:text;
  ok:boolean;
  devs:array[1..10] of string[80];

  rcfil:string;
  ignlist:string;  {Chips we ignore}
  PCIenable:boolean;

function mmode(s:string):integer;
var x:byte;
begin
  mmode:=__None;
  for x:=_text to _p32d do     {Remember to update}
    if s=strip(mmodenames[x]) then
      mmode:=x;
end;

function FindChp(s:string):integer;
var chp:integer;
begin
  FindChp:=__None;
  s:=strip(upstr(s));
  for chp:=__none to max_chip do
    if upstr(header[chp])=s then
      FindChp:=chp;
end;

procedure initcfg;  {Reset the configuration}
begin
  force_mm:=0;
  force_chip:=__none;
  force_version:=0;
  auto_test:=false;
  clocktest:=true;   {allow clock testing}
  debug:=false;
  PCIenable:=true;
  ignlist:='';
  fillchar(dotest,sizeof(dotest),ord(true));   {allow test for all chips}
  noumodes:=0;
end;

begin
  {$ifdef ver70}
    test8086:=1;    {force 286, 386 mode buggy}
  {$endif}
  initcfg;

  clrscr;
  assign(t,'whatvga.cfg');
  {$i-}
  reset(t);   {Check if the file exists}
  {$i+}
  if ioresult=0 then
  begin
    cv.chip:=__None;
    writeln('Configuration file found!');
    while not eof(t) do
    begin
      readln(t,s);
      if cv.chip=__None then    {Initial section}
      begin
        x:=pos('=',s);
        if x>0 then
        begin
          fea:=upstr(strip(copy(s,1,x-1)));  {keyword}
          s:=strip(copy(s,x+1,255));         {value}
          if (upstr(s)='YES') or (upstr(s)='ON') or
             (upstr(s)='Y') or (upstr(s)='1') then ok:=true
                                              else ok:=false;
          if fea='AUTOTEST'  then auto_test:=ok;
          if fea='CLOCKTEST' then clocktest:=ok;
          if fea='DEBUG'     then debug:=ok;
          if fea='PCITEST'   then PCIenable:=ok;
          if fea='MEMORY'    then val(s,force_mm,err);
          if fea='IGNORE'    then
          begin
            chp:=FindChp(upstr(s));
            if chp<>__None then
            begin
              dotest[chp]:=false;
              ignlist:=ignlist+' '+header[chp];
            end;
          end;
          if fea='CHIPSET'   then
          begin
            chp:=FindChp(upstr(s));
            fillchar(dotest,sizeof(dotest),ord(false));  {Disable all tests}
            if chp<>__None then
            begin
              dotest[chp]:=true;
              force_chip:=chp;
            end;
          end;
        end;
      end
      else
        if s[1]='-' then
        begin
          delete(s,1,1);
          md:=dehex(clipstr(s));
          inc(noumodes);
          usermodes[noumodes].md     :=md;
          usermodes[noumodes].memmode:=__None;  {Disable}
          usermodes[noumodes].flags  :=cv.chip;
        end
        else if s[1]='+' then
        begin
          delete(s,1,1);
          md:=dehex(clipstr(s));
          val(clipstr(s),x,err);
          val(clipstr(s),y,err);
          chp:=mmode(clipstr(s));
          val(clipstr(s),b,err);
          inc(noumodes);
          usermodes[noumodes].md     :=md;
          usermodes[noumodes].xres   :=x;
          usermodes[noumodes].yres   :=y;
          usermodes[noumodes].bytes  :=b;
          usermodes[noumodes].memmode:=chp;
          usermodes[noumodes].flags  :=cv.chip;
        end;

      if s[1]='[' then
        cv.chip:=FindChp(copy(s,2,pos(']',s)-2));
    end;
    close(t);
  end;

  rcfil:='';
  for x:=1 to paramcount do
  begin
    s:=upstr(paramstr(x))+'  ';
    case s[1] of
     '-':begin
           chp:=FindChp(copy(s,2,255));
           if chp<>__None then
           begin
             dotest[chp]:=false;
             ignlist:=ignlist+' '+header[chp];
           end;
         end;
     '+':begin
           chp:=FindChp(copy(s,2,255));
           fillchar(dotest,sizeof(dotest),ord(false));
           if chp<>__None then
           begin
             dotest[chp]:=true;
             force_chip:=chp;
           end;
         end;
     '=':val(strip(copy(s,2,255)),force_mm,err);
     '/':case upcase(s[2]) of
          'A':auto_test:=true;
          'C':clocktest:=false;
          'I':initcfg;
          'D':debug:=true;
          'T':rcfil:=strip(copy(s,3,255));
          'V':begin
                val(strip(copy(s,3,255)),y,err);
                if err=0 then force_version:=y;
              end;
          'P':PCIenable:=false;
         end;
    end;
  end;

  if rcfil<>'' then
  begin
    ReCalc(rcfil);
    halt(0);
  end;

  if (force_mm<>0) or (force_chip<>__none) or (force_version<>0)
     or (ignlist<>'') then
  begin
    if force_mm<>0 then writeln('Memory forced to: '+istr(force_mm)+'K');
    if force_chip<>__none then writeln('Chip forced to: '+header[force_chip]);
    if force_version<>0 then writeln('Chips version forced to: ',force_version);
    if ignlist<>'' then writeln('Chips to ignore:'+ignlist);
    writeln;
    writeln('Press a key to continue...');
    if readkey='' then;
    clrscr;
  end;



  if PCIenable then findPCI;
  findvideo;
  settextmode;

  for x:=1 to vids do
  begin
    SelectVideo(x);
    fea:='';
    if (cv.features and ft_cursor)>0 then fea:=' C';
    if (cv.features and ft_blit  )>0 then fea:=fea+' B';
    if (cv.features and ft_line  )>0 then fea:=fea+' L';
    if (cv.features and ft_rwbank)>0 then fea:=fea+' R';
    devs[x]:='  '+istr(x)+'  '+ljust(chipnam[cv.chip],9)
               +rjust(istr(cv.mm),8)+ljust(fea,8)+'  '+vid[x].name;
  end;


  iteration:=0;
  repeat
    stop:=false;
    if vids<>1 then
    begin
      SetTextMode;
      writeln(wrVersionNbr+copyright);
      writeln;
      writeln('Multiple Video Interfaces or Adapters found!!');
      writeln('Please select the one to test:');
      writeln('       Chip:    Memory:  Feat:  Name:');
      for x:=1 to vids do writeln(devs[x]);
      writeln;
      writeln(' 0  Stop');
      writeln;
      sel:=getkey-ord('0');
      if sel=0 then stop:=true;
    end
    else sel:=1;
    if (sel>0) and (sel<=vids) then SelectVideo(sel);

    while not stop do
    begin
      SetTextMode;
      writeln(wrVersionNbr+copyright);
      writeln;

      write('Video system: ',chipnam[cv.chip],' with '+istr(cv.mm)+' Kbytes');
      if cv.SubVers<>0 then write(' Version: '+hex4(cv.SubVers));
      writeln;
      if cv.name<>'' then writeln('Name: '+cv.name);
      writeln('Dac: '+cv.dacname);
      writeln('Clock: '+clkname[cv.clktype]);
      case cv.clktype of
        clk_ext2:clks:=4;
        clk_ext3:clks:=8;
        clk_ext4:clks:=16;
        clk_ext5:clks:=32;
        clk_ext6:clks:=64;
      else clks:=4;
      end;
      if clks>0 then
      begin
        for x:=0 to clks-1 do
        begin
          if (x and 7)=0 then
          begin
            if x>0 then writeln;
            write('      ');
          end;
          write(cv.clks[x]/1000:8:3);
        end;
        writeln;
      end;

      if cv.features<>0 then
      begin
        write('Special features:');
        if (cv.features and ft_cursor)<>0 then write(' Cursor');
        if (cv.features and ft_blit)<>0 then write(' BitBlt');
        if (cv.features and ft_line)<>0 then write(' Line');
        if (cv.features and ft_rwbank)<>0 then write(' RW-bank');
        writeln;
      end;

      writeln;
      if (cv.flags and FLG_StdVGA)>0 then
        writeln('     1  Test Standard VGA modes');
      writeln('     2  Test Extended modes');
      if (cv.chip<>__vesa) and (cv.chip<>__XBE) then
        writeln('     3  Search for video modes');
      if (cv.features and ft_cursor)<>0 then
        writeln('     5  HardWare Cursor test');
      if (cv.features and ft_blit)<>0 then
        writeln('     6  HardWare BitBLT test');
      if (cv.features and ft_line)<>0 then
        writeln('     7  Line Draw test');
      if (cv.features and ft_rwbank)<>0 then
        writeln('     8  R/W bank test');

      writeln;
      writeln('     B  Individual bit functionality');
      writeln('     D  DAC test submenu');
      writeln('     R  Read/Writable registers');

      writeln;
      writeln('     0  Stop');
      writeln;

      if auto_test then
      begin
        inc(iteration);
        pushkey(Ch_Cr);  {No Operation, just step on}
        case iteration of
          1:begin
              InitAFfile(sel);
              for x:=1 to vids do
              begin
                AddAFbuf(vid[x],sizeof(vid[1]));
                WrAFbuf(AF_videosys);
              end;
              if (cv.chip<>__vesa) and (cv.chip<>__XBE) then pushkey(ord('1'));
            end;
          2:pushkey(ord('2'));
          3:if (cv.features and ft_cursor)<>0 then pushkey(ord('5'));
          4:if (cv.features and ft_blit)<>0 then pushkey(ord('6'));
          5:if (cv.features and ft_line)<>0 then pushkey(ord('7'));
          6:if (cv.features and ft_rwbank)<>0 then pushkey(ord('8'));
          7:pushkey(ch_esc);

        end;
      end;

      case getkey of
             ord('1'):teststdvgamodes;
             ord('2'):testvgamodes;
             ord('3'):searchformodes;
             ord('5'):testcursor;
             ord('6'):testblit;
             ord('7'):testline;
             ord('8'):testrwbank;
             ord('9'):testzoom;
    ord('a'),ord('A'):auto_test:=true;
    ord('b'),ord('B'):testbits;
    ord('d'),ord('D'):testdac;
    ord('r'),ord('R'):testregs;
    ord('t'),ord('T'):testdacbits;


              ord('0'):stop:=true;
      Ch_Esc:begin
               stop:=true;
               sel:=0;
             end;
      end;
    end;
    if vids<=1 then sel:=0;
  until sel=0;

  SetTextMode;
  vio(3);     {Standard mode 3  80x25 text}

  if auto_test then
  begin
    wrAFff;
    close(af_fil);
    writeln;
    writeln('The test results are in the file: ',af_filename);
    writeln;
    writeln('For e-mail, modem etc the test file should be compressed');
    writeln('(ZIP, ARJ...) savings of >40% are not uncommon.');
    writeln;
    writeln('For Email transport, remember that the test file is BINARY.');

  end;
end.
