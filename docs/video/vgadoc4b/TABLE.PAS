{$i VGADECL.INC}

const

  coltxt:array[1..max_mode] of string[4]=('TXT','TXT2','TXT4','HRC','CGA1'
       ,'CGA2','PL1','PL1E','PL2','PK2','PL4','PK4','PK4a','PK4b','P8','P15','P16'
       ,'P24','P24b','P32','P32b','P32c','P32d');




const
  colbits:array[1..max_mode] of integer=   {Bits of data per pixel}
               (0,0,0,1,1,1,1,2,2,2,4,4,4,4,8,15,16,24,24,24,24,24,24);
  usebits:array[1..max_mode] of integer=   {Bits used per pixel}
               (0,0,0,1,1,1,1,2,2,2,4,4,4,4,8,16,16,24,24,32,32,32,32);
  modecols:array[1..max_mode] of longint=
               (0,0,0,2,2,2,2,4,4,4,16,16,16,16,256,32768,65536
               ,16777216,16777216,16777216,16777216,16777216,16777216);



type
  modetype=record
             md,xres,yres,bytes:word;
             memmode:byte;
           end;

  regblk=record
           base:word;
           nbr:word;
           x:array[0..255] of byte;
         end;

  regtype=record
            chip:byte;
            mmode:byte;
            mode,pixels,lins,bytes,tridold0d,tridold0e:word;
            attregs:array[0..31] of byte;
            seqregs,grcregs,crtcregs,xxregs:regblk;
            stdregs:array[$3c0..$3df] of byte;
            xgaregs:array[0..15] of byte;
            dacregs:array[0..16] of byte;
            dacinxd:regblk;
          end;



var
  f:file of regtype;
  fo:text;
  s:string;

  xxs,ix,off:word;
  mxcrtc,mxseq,mxattr,mxgrf,mxxtra,xtraix:word;
  xx:array[1..40] of regtype;

const hx:array[0..15] of char='0123456789ABCDEF';

function hex2(w:word):string;
begin
  hex2:=hx[(w shr 4) and 15]+hx[w and 15];
end;

function hex4(w:word):string;
begin
  hex4:=hx[w shr 12]+hx[hi(w) and 15]+hx[(w shr 4) and 15]+hx[w and 15];
end;

function gtbyte(var s:string):word;
var i,j:word;
begin
  while copy(s,1,1)=' ' do delete(s,1,1);
  i:=(ord(s[1])-48) and 31;if i>9 then dec(i,7);
  j:=(ord(s[2])-48) and 31;if j>9 then dec(j,7);
  delete(s,1,2);
  gtbyte:=i*16+j;
end;

function gtword(var s:string):word;
var i,j:word;
begin
  i:=gtbyte(s);
  j:=gtbyte(s);
  gtword:=i*256+j;
end;

function gtval(var s:string):longint;
var x,z:word;
  y:longint;
begin
  x:=pos(': ',s);
  delete(s,1,x+1);
  x:=pos(' ',s);if x=0 then x:=length(s)+1;
  val(copy(s,1,x-1),y,z);
  delete(s,1,x);
  gtval:=y;
end;


var
  parms:word;
  parm:array[1..256] of word;
  parmsame:boolean;
  parmstr:string;

procedure setstr(s:string);
begin
  parms:=0;
  parmstr:=s;
  parmsame:=true;
end;

procedure adds(w:word);
begin
  inc(parms);
  parm[parms]:=w;
  if parm[1]<>w then parmsame:=false;
end;

function getstr:string;
var x:word;
begin
  if parmsame then parms:=1;
  for x:=1 to parms do
    parmstr:=parmstr+' '+hex4(parm[x]);
  getstr:=parmstr;
end;


var x,y:word;
    l:longint;

    dacix,mxdaci:word;
begin
  assign(f,'register.vga');
  reset(f);
  xxs:=0;ix:=0;off:=0;xtraix:=0;dacix:=0;mxdaci:=0;
  mxcrtc:=0;mxattr:=31;mxseq:=0;mxgrf:=0;mxxtra:=0;
  fillchar(xx,sizeof(xx),0);
  while not eof(f) do
  begin
    inc(xxs);
    read(f,xx[xxs]);
    if xx[xxs].seqregs.nbr>mxseq then mxseq:=xx[xxs].seqregs.nbr;
    if xx[xxs].grcregs.nbr>mxgrf then mxgrf:=xx[xxs].grcregs.nbr;
    if xx[xxs].crtcregs.nbr>mxcrtc then mxcrtc:=xx[xxs].crtcregs.nbr;
    if xx[xxs].xxregs.base<>0 then
    begin
      xtraix:=xx[xxs].xxregs.base;
      if xx[xxs].xxregs.nbr>mxxtra then mxxtra:=xx[xxs].xxregs.nbr;
    end;
    if xx[xxs].dacinxd.base<>0 then
    begin
      dacix:=xx[xxs].dacinxd.base;
      if xx[xxs].dacinxd.nbr>mxdaci then mxdaci:=xx[xxs].dacinxd.nbr;
    end;
  end;
  close(f);

  assign(fo,'register.tbl');
  rewrite(fo);
  write(fo,'Mode:   ');
  for y:=1 to xxs do write(fo,hex4(xx[y].mode):5);
  writeln(fo);
  write(fo,'Pixels: ');
  for y:=1 to xxs do write(fo,xx[y].pixels:5);
  writeln(fo);
  write(fo,'Lines:  ');
  for y:=1 to xxs do write(fo,xx[y].lins:5);
  writeln(fo);
  write(fo,'Bytes:  ');
  for y:=1 to xxs do write(fo,xx[y].bytes:5);
  writeln(fo);
  write(fo,'Colors: ');
  for y:=1 to xxs do write(fo,coltxt[xx[y].mmode]:5);
  writeln(fo);
  setstr('3CCh   :');
  for y:=1 to xxs do adds(xx[y].stdregs[$3CC]);
  writeln(fo,getstr);

  if xx[1].chip=__Trid then
  begin
    setstr('SEQ_0D :');
    for y:=1 to xxs do adds(xx[y].tridold0D);
    writeln(fo,getstr);
    setstr('SEQ_0E :');
    for y:=1 to xxs do adds(xx[y].tridold0E);
    writeln(fo,getstr);
  end;

  for x:=0 to mxattr do
  begin
    setstr('ATTR '+hex2(x)+':');
    for y:=1 to xxs do adds(xx[y].attregs[x]);
    writeln(fo,getstr);
  end;
  for x:=0 to mxSEQ do
  begin
    setstr('SEQ '+hex2(x)+': ');
    for y:=1 to xxs do adds(xx[y].seqregs.x[x]);
    writeln(fo,getstr);
  end;
  for x:=0 to mxgrf do
  begin
    setstr('GRF '+hex2(x)+': ');
    for y:=1 to xxs do adds(xx[y].grcregs.x[x]);
    writeln(fo,getstr);
  end;
  for x:=0 to mxcrtc do
  begin
    setstr('CRTC '+hex2(x)+':');
    for y:=1 to xxs do adds(xx[y].crtcregs.x[x]);
    writeln(fo,getstr);
  end;
  if xtraix<>0 then
    for x:=0 to mxxtra do
    begin
      setstr(hex4(xtraix)+' '+hex2(x)+':');
      for y:=1 to xxs do adds(xx[y].xxregs.x[x]);
      writeln(fo,getstr);
    end;
  for x:=0 to 16 do
  begin
    setstr('DAC  '+hex2(x)+':');
    for y:=1 to xxs do adds(xx[y].dacregs[x]);
    writeln(fo,getstr);
  end;
  if dacix<>0 then
    for x:=0 to mxdaci do
    begin
      setstr('DACi '+hex2(x)+':');
      for y:=1 to xxs do adds(xx[y].dacinxd.x[x]);
      writeln(fo,getstr);
    end;
  close(fo);
end.

