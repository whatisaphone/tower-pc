uses dos;

{$i VGADECL.INC}
type

  rs=record    {Result data for each mode}
       tst:_AT2;
       com2:string;
       r:array[3..6] of
          record
            a:_AT3;
            com:string;
          end;
       wd:word;
       rg:array[1..1] of byte;   {Dummy array, actual size depends on allocation}
     end;

  prs=^rs;

var
  buf:array[0..2048] of byte;
  f:file;
  t:text;
  fofs:longint;
  fst,fbytes:word;
  eoff:boolean;

  ModeNam:string;
  clknames:word;
  clknam:array[1..20] of string[20];

  AT0:record
        r:_AT0;
        email,nam,vid,sys,mods:string;
      end;
  AT1:array[1..10] of vidinfo;

  res:array[1..100] of prs;
  ress,vds:word;

  mtxt:array[1..max_mode] of string[4];

function featt(feat:word):string;
var s:string[4];
begin
  s:='    ';
  if (feat and ft_cursor)>0 then s[1]:='C';
  if (feat and ft_blit)>0 then s[2]:='B';
  if (feat and ft_line)>0 then s[3]:='L';
  if (feat and ft_rwbank)>0 then s[4]:='R';
  featt:=s;
end;

function hex2(w:word):string;
const hx:array[0..15] of char='0123456789ABCDEF';
begin
  hex2:=hx[lo(w) shr 4]+hx[w and 15];
end;

function hex4(w:word):string;
const hx:array[0..15] of char='0123456789ABCDEF';
begin
  hex4:=hx[w shr 12]+hx[hi(w) and 15]+hx[lo(w) shr 4]+hx[w and 15];
end;

procedure fillbuf;
var x:word;
begin
  if  (fst>0) and not eoff then
  begin
    dec(fbytes,fst);
    move(buf[fst],buf,fbytes);
    inc(fofs,fst);
  end;
  fst:=0;
  if (fbytes<1500) and not eoff then
  begin
    blockread(f,buf[fbytes],2000-fbytes,x);
    inc(fbytes,x);
  end;
end;

procedure cp(var b;byt:word);
begin
  move(buf[fst],b,byt);
  inc(fst,byt);
end;

procedure rdstr(var s:string);
begin
  cp(s,buf[fst]+1);
end;

procedure rdat0(var a:_AT0;var nam,vid,sys:string);
var x:word;
begin
  move(buf[fst+1],x,2);
  inc(x,fst);
  inc(fst,3);
  cp(a,sizeof(_AT0));
  rdstr(nam);
  rdstr(vid);
  rdstr(sys);
  rdstr(ModeNam);
  clknames:=0;
  repeat            {Read the Clock type list}
    inc(clknames);
    rdstr(clknam[clknames]);
  until clknam[clknames]='';

  fst:=x;
  fillbuf;
end;

function opentstfil(nam:string):boolean;
var
  x,y,z:word;
  a2:_AT2;
  a3:_AT3;
  c2,s:string;
  mm:byte;
begin
  opentstfil:=true;
  eoff:=false;
  if pos('.',nam)=0 then nam:=nam+'.tst';
  assign(f,nam);
  {$i-}
  reset(f,1);
  {$i+}
  if ioresult<>0 then opentstfil:=false
  else begin
    fbytes:=0;fst:=0;fofs:=0;
    fillbuf;
  {  rdAT0(at0.r,at0.nam,at0.vid,at0.sys);
    for x:=1 to at0.r.vid_sys do
    begin
      move(buf[fst+1],y,2);
      move(buf[fst+3],at1[x],sizeof(_at1));
      inc(fst,y);
      fillbuf;
    end; }
    ress:=0;
    vds:=0;
    while (fbytes>0) and not eoff do
    begin
      x:=fst;
      move(buf[fst+1],z,2);
      inc(z,fst);
      inc(fst,3);
      case buf[x] of
        0:begin
            cp(at0.r,sizeof(_AT0));
            rdstr(at0.email);
            rdstr(at0.nam);
            rdstr(at0.vid);
            rdstr(at0.sys);
            rdstr(at0.mods);
            s:=at0.mods;
            if s='' then s:='TXT TXT2TXT4HERCCGA1CGA2PL1 PL1EPL2 PK2 PL4 PK4 P8  P15 P16 P24 P32 ';
            mm:=_text;
            while s<>'' do
            begin
              mtxt[mm]:=copy(s,1,4);
              delete(s,1,4);
              inc(mm);
            end;
            clknames:=0;
            repeat            {Read the Clock type list}
              inc(clknames);
              rdstr(clknam[clknames]);
            until clknam[clknames]='';
          end;
        1:begin
            inc(vds);
            cp(at1[vds],sizeof(vidinfo));
          end;
        2:begin
            cp(a2,sizeof(_AT2));
            rdstr(c2);
            y:=z-fst;
            inc(ress);
            getmem(res[ress],sizeof(rs)+y);
            fillchar(res[ress]^,sizeof(rs),0);
            res[ress]^.wd:=sizeof(rs)+y;
            move(a2,res[ress]^.tst,sizeof(a2));
            res[ress]^.com2:=c2;
            move(buf[fst],res[ress]^.rg,y);
          end;
     3..6:begin
            cp(a3,sizeof(_AT3));
            rdstr(c2);
            for y:=1 to ress do
              if (res[y]^.tst.mode=a3.mode) and
                (res[y]^.tst.Mmode=a3.Mmode) then
              begin
                move(a3,res[y]^.r[buf[x]].a,sizeof(a3));
                res[y]^.r[buf[x]].com:=c2;
              end;

          end;
      255:begin
            eoff:=true;
          end;
      end;
      fst:=z;
      fillbuf;
    end;
  end;
end;

procedure closetst;
var x:word;
begin
  close(f);
  for x:=1 to ress do
    freemem(res[x],res[x]^.wd);
end;

procedure wrdata(fnam:string);
begin
  if opentstfil(fnam) then
  begin
    closetst;
  end;
end;

procedure wrsumm;
var
  DI:searchrec;
  p:^vidinfo;
begin
  writeln('     File:     Chip:  Vers: Mem: Feat:      Dac:            Name:');
       {     WHVGA123.tst aabbccdd 5678  2048 C  R Sierra SC15025______ }
  findfirst('*.tst',0,DI);
  while doserror=0 do
  begin
    if opentstfil(DI.name) then
    begin
      p:=@AT1[AT0.r.cur_vid];

      writeln(DI.name:12,copy(' '+chipnam[p^.chip]+'         ',1,10)
             +hex4(p^.subvers),p^.mm:6,' '+featt(p^.features)+' '+copy(p^.dacname
             +'                     ',1,21)+p^.name);
      closetst;
    end;
    findnext(DI);
  end;
end;

function d2(w:word):string;
begin
  w:=w mod 100;
  d2:=chr(w div 10+48)+chr(w mod 10+48);
end;

function SWvers(swver:word):string;
var s:string;
begin
  str(swver div 1000,s);
  s:=s+'.'+d2(swver div 10);
  if (SWver mod 10)>0 then s:=s+chr(SWver mod 10+$60);
  SWvers:=s;
end;

function Wdate(dt:longint):string;
const
  mon:array[1..12] of string[3]=('jan','feb','mar','apr','may','jun'
                                ,'jul','aug','sep','oct','nov','dec');
var d:datetime;
begin
  unpacktime(dt,d);
  Wdate:=d2(d.hour)+':'+d2(d.min)+':'+d2(d.sec)+' '
        +d2(d.day)+'/'+mon[d.month]+'/'+d2(d.year div 100)+d2(d.year);
end;

function Clk(r:real):string;
var s:string;
begin
  if r<0.1 then Clk:='        '
  else begin
    str(r:8:3,s);
    Clk:=s;
  end;
end;

function freq(frq:longint):string;
var w:word;
  st:string[5];
begin
  w:=frq mod 1000;
  str(frq div 1000:3,st);
  freq:=st+'.'+chr((w div 100)+48)+chr(((w div 10) mod 10)+48)+chr((w mod 10)+48);
end;

procedure wrdetail(nam,tnam:string);
const
 ni:array[boolean] of string[2]=('  ',' i');
 tok1:array[0..1] of string[4]=(' No ',' Ok ');
 tok2:array[0..3] of string[4]=('    ',' No ',' Ok ',' Ok ');
var
  x,y:word;
  sok:string;
  t:text;
  p:^vidinfo;
begin
  if opentstfil(nam) then
  begin
    x:=pos('.',nam);
    if x>0 then nam[0]:=chr(x-1);
    assign(t,nam+'.txt');
    rewrite(t);
    writeln(t,'File: '+nam+' Whatvga version: '+SWvers(at0.r.SWvers)
              +' Date: '+Wdate(at0.r.curtime));
    writeln(t,'Tester:');
    writeln(t,at0.email);
    writeln(t);
    writeln(t,at0.nam);
    writeln(t);
    writeln(t,'Video System:');
    writeln(t,at0.vid);
    writeln(t);
    writeln(t,'System description:');
    writeln(t,at0.sys);
    writeln(t);

    if at0.r.vid_sys>1 then
    begin
      writeln(t,'Video systems:');
      for x:=1 to at0.r.vid_sys do
      begin
        p:=@AT1[x];
        writeln(t,copy(' '+chipnam[p^.chip]+'         ',1,10)
               +hex4(p^.subvers),p^.mm:6,' '+featt(p^.features)+' '+copy(p^.dacname
               +'                     ',1,21)+p^.name);
      end;
      writeln(t);
    end;

    writeln(t,'Active Video System:');
    p:=@AT1[AT0.r.cur_vid];

    writeln(t,chipnam[p^.chip]+' Revision: '+hex4(p^.subvers)
           +' '+p^.name+' with ',p^.mm,' Kbytes');
    writeln(t,'Instance: '+hex4(p^.id)+' IOadr: '+hex4(p^.IOadr)
           +' XGAseg: '+hex4(p^.xseg)+' Padr: '+hex4(p^.Phadr shr 16)+hex4(p^.phadr));
    if p^.features<>0 then
    begin
      write(t,'Features:');
      if (p^.features and ft_cursor)>0 then write(t,' Cursor');
      if (p^.features and ft_blit)>0 then write(t,' BitBLT');
      if (p^.features and ft_line)>0 then write(t,' Line');
      if (p^.features and ft_rwbank)>0 then write(t,' RW-bank');
      writeln(t);
    end;
    writeln(t,'DAC: '+p^.dacname);
    writeln(t,'CLK: '+ClkNam[p^.clktype]);

    writeln(t);
    writeln(t,'  Mode:     X    Y  Byte Drw Scr Ana Cur Blt Lin RW:   Vclk    Hclk    Fclk  i');
          {    0038 P8__ 1024  768 1024 Ok  Ok  Ok  Ok  Ok  Ok  Ok}
    for x:=1 to ress do
      with res[x]^ do
      begin
        if (tst.pixels<>tst.Cpixels) or (tst.lins<>tst.Clins)
         or (tst.bytes<>tst.Cbytes) or (tst.MMode<>tst.CMmode) then
           tst.flag:=tst.flag and 31
        else tst.flag:=tst.flag or 128;
        write(t,hex4(tst.mode)+' '+mtxt[tst.mmode],tst.pixels:5,tst.Lins:5,tst.Bytes:5);
        sok:='                            ';
        if (tst.flag and 1)>0 then
        begin
          sok:=tok1[(tst.flag and AFF_dispok) shr 1]
              +tok2[(tst.flag and (AFF_scroll+AFF_scrollok)) shr 2]
              +tok1[(tst.flag shr 7)];
          for y:=3 to 6 do
            if (tst.mode=r[y].a.mode) then sok:=sok+tok1[r[y].a.flag and AFF_testok]
            else sok:=sok+'    ';

          writeln(t,sok+' '+freq(tst.vclk)+' '+freq(tst.Hclk)+' '+freq(tst.Fclk)+ni[tst.ilace]);
          if (tst.flag and AFF_canceled)>0 then writeln(t,'   Mode was disabled by the user!!!!!');
          if (com2<>'') then writeln(t,'    Comment:  '+com2);
          if (tst.flag and 128)=0 then
            writeln(t,'    Analysis: Real: ',tst.pixels,'x',tst.lins
                   ,' '+mtxt[tst.mmode]+' (',tst.bytes,' bytes) Calc: '
                   ,tst.Cpixels,'x',tst.Clins,' '+mtxt[tst.Cmmode]+' ('
                   ,tst.Cbytes,' bytes)');
          if (r[3].com<>'') then writeln(t,'    Cursor:   '+r[3].com);
          if (r[4].com<>'') then writeln(t,'    BitBlt:   '+r[4].com);
          if (r[5].com<>'') then writeln(t,'    Linedraw: '+r[5].com);
          if (r[6].com<>'') then writeln(t,'    R/W bank: '+r[6].com);
        end
        else writeln(t,' - Mode did not set');

      end;
    close(t);
    closetst;
  end;
end;

procedure wrregs(nam,tnam:string;grfonly:boolean);
type
  iarr=array[1..1000] of integer;
  barr=array[1..1000] of byte;
  iarrp=^iarr;
var p:^vidinfo;
  x,y,z,u,v,w,rgs:word;
  i:integer;
  stop:boolean;
  rgg:array[1..1000] of
      record
        ofs:word;
        inx,
        typ:byte;   {1: special, 2: reg, 3: index}
      end;
  vll:array[1..100] of iarrp;
  bp:^barr;
  bpo:word;
  wp:iarrp;
  s:string;

const
  spcreg:array[1..2] of string[8]=('Old seqD','Old seqE');

function popb:word;
begin
  inc(bpo);
  popb:=bp^[bpo];
end;

function popw:word;
var w:word;
begin
  w:=popb;
  popw:=w+(popb shl 8);
end;

procedure addval(base,ix,typ,val:word);
var x:word;
begin
  if (base and $FFF0)=$3B0 then inc(base,$20);  {3Bx -> 3Dx}
  for x:=1 to rgs do
    if (rgg[x].ofs=base) and (rgg[x].typ=typ) and (rgg[x].inx=ix) then
      wp^[x]:=val;
end;

procedure addrg(base,ix,typ:word);
var x,y:word;
begin
  if (base and $FFF0)=$3B0 then inc(base,$20);  {3Bx -> 3Dx}
  x:=1;y:=rgs+1;
  while x<=rgs do
    if (base>rgg[x].ofs) or ((base=rgg[x].ofs) and
        ((typ>rgg[x].typ) or ((typ=rgg[x].typ) and
        (ix>rgg[x].inx)))) then inc(x)
    else begin
      y:=x;
      x:=maxint;
    end;

  if (base<>rgg[y].ofs) or (typ<>rgg[y].typ) or (ix<>rgg[y].inx) then
  begin
   { for x:=rgs downto y do rgg[x+1]:=rgg[x]; }

    if rgs>=y then
      move(rgg[y],rgg[y+1],(rgs-y+1)*sizeof(rgg[1]));
    rgg[y].ofs :=base;
    rgg[y].typ :=typ;
    rgg[y].inx :=ix;
    inc(rgs);
  end;

end;

var
  _rs:array[1..100] of prs;
  _rss:word;

begin

  rgs:=0;
  if opentstfil(nam) then
  begin
    _rss:=0;
    for x:=1 to ress do
      if ((not grfonly) or (res[x]^.tst.mmode>_pl1))
       and ((res[x]^.tst.flag and 1)>0) then
      begin
        inc(_rss);
        _rs[_rss]:=res[x];
      end;

    x:=pos('.',nam);
    if x>0 then nam[0]:=chr(x-1);
    assign(t,nam+'.reg');
    rewrite(t);
    writeln(t,'File: '+nam+' Whatvga version: '+SWvers(at0.r.SWvers)
              +' Date: '+Wdate(at0.r.curtime));
    p:=@AT1[AT0.r.cur_vid];

    writeln(t,chipnam[p^.chip]+' Revision: '+hex4(p^.subvers)
           +' '+p^.name+' with ',p^.mm,' Kbytes');
    writeln(t);

    write(t,'Mode:    ');
    for x:=1 to _rss do write(t,' '+hex4(_rs[x]^.tst.mode));
    writeln(t);
    write(t,'Pixels:  ');
    for x:=1 to _rss do write(t,_rs[x]^.tst.pixels:5);
    writeln(t);
    write(t,' - Calc: ');
    for x:=1 to _rss do write(t,_rs[x]^.tst.Cpixels:5);
    writeln(t);
    write(t,'Lines:   ');
    for x:=1 to _rss do write(t,_rs[x]^.tst.lins:5);
    writeln(t);
    write(t,' - Calc: ');
    for x:=1 to _rss do write(t,_rs[x]^.tst.Clins:5);
    writeln(t);
    write(t,'Bytes:   ');
    for x:=1 to _rss do write(t,_rs[x]^.tst.bytes:5);
    writeln(t);
    write(t,' - Calc: ');
    for x:=1 to _rss do write(t,_rs[x]^.tst.Cbytes:5);
    writeln(t);
    write(t,'MemMode: ');
    for x:=1 to _rss do write(t,' '+mtxt[_rs[x]^.tst.Mmode]);
    writeln(t);
    write(t,' - Calc: ');
    for x:=1 to _rss do write(t,' '+mtxt[_rs[x]^.tst.CMmode]);
    writeln(t);

    for x:=1 to _rss do
    begin
      bp:=@_rs[x]^.rg;bpo:=0;stop:=false;
      repeat
        z:=popw;
        case z of
          0:stop:=true;
          1:begin
              w:=popw;
              u:=popb;v:=popb;
              for z:=u to v do addrg(w,z,3);
              inc(bpo,v-u+1);
            end;
        255:begin
              addrg(popw,0,1);
              inc(bpo);
            end;
        else
          if z<256 then
          begin
            w:=popw;
            for w:=w to w+z-1 do addrg(w,0,2);
            inc(bpo,z);
          end
          else begin
            addrg(z,0,2);
            inc(bpo);
          end;
        end;
      until stop;
    end;
    for x:=1 to _rss do
    begin
      getmem(wp,rgs*2);
      for y:=1 to rgs do wp^[y]:=-1;
      bp:=@_rs[x]^.rg;bpo:=0;stop:=false;
      repeat
        z:=popw;
        case z of
          0:stop:=true;
          1:begin
              w:=popw;
              u:=popb;v:=popb;
              for z:=u to v do addval(w,z,3,popb);
            end;
        255:begin
              w:=popw;
              addval(w,0,1,popb);
            end;
        else
          if z<256 then
          begin
            w:=popw;
            for w:=w to w+z-1 do addval(w,0,2,popb);
          end
          else addval(z,0,2,popb);
        end;
      until stop;
      vll[x]:=wp;
    end;
    for x:=1 to rgs do
    begin
      case rgg[x].typ of
        1:if rgg[x].ofs<$F000 then s:=spcreg[rgg[x].ofs+1]
          else s:='DAC '+hex2(rgg[x].ofs)+'  ';
        2:s:=hex4(rgg[x].ofs)+'    ';
        3:s:=hex4(rgg[x].ofs)+' i'+hex2(rgg[x].inx);
      end;
      write(t,s+':');
      w:=vll[1]^[x];
      stop:=(w>=0);
      for y:=1 to _rss do
        if (w<>vll[y]^[x]) and (vll[y]^[x]>=0) then stop:=false;
      if stop then
      begin
        write(t,'   '+hex2(w));
        for y:=2 to _rss do
        begin
          i:=vll[y]^[x];
          if i<0 then write(t,'   --')
          else if i=w then write(t,'    =')
                      else write(t,'   '+hex2(i));
        end;
      end
      else
        for y:=1 to _rss do
          if vll[y]^[x]<0 then write(t,'   --')
                          else write(t,'   '+hex2(vll[y]^[x]));
      writeln(t);

    end;

    closetst;
    for x:=1 to _rss do freemem(vll[x],rgs*2);
  end;
end;

procedure wrBIOS(nam,tnam:string);
var rhdr:_ATFF;
  z,x,y:word;
  l:longint;
  o:file;
  t:text;

begin
  if opentstfil(nam) then
  begin
    x:=pos('.',nam);
    if x>0 then nam[0]:=chr(x-1);
    assign(o,nam+'.rom');
    rewrite(o,1);
    assign(t,nam+'.vct');
    rewrite(t);
    seek(f,fofs);
    blockread(f,buf,512);
    move(buf[1],z,2);
    move(buf[3],rhdr,sizeof(rhdr));
    writeln(t,'Int 10h:  '+hex4(rhdr.int10));
    writeln(t,'Int 6Dh:  '+hex4(rhdr.int6d));
    writeln(t,'Save Vct: '+hex4(rhdr.m4a8));
    writeln(t,'Fnt 8h:   '+hex4(rhdr.fnt8h));
    writeln(t,'Fnt 8l:   '+hex4(rhdr.fnt8l));
    writeln(t,'Fnt 14:   '+hex4(rhdr.fnt14));
    writeln(t,'Fnt 14x9: '+hex4(rhdr.fnt14x9));
    writeln(t,'Fnt 16:   '+hex4(rhdr.fnt16));
    writeln(t,'Fnt 16x9: '+hex4(rhdr.fnt16x9));
    close(t);
    seek(f,fofs+z);
    l:=rhdr.size*longint(512);
    z:=0;
    while l>0 do
    begin
      x:=2048;
      if x>l then x:=l;
      blockread(f,buf,x,y);
      for y:=0 to x-1 do
      begin
        z:=lo(z+buf[y]);
        buf[y]:=z;
      end;
      blockwrite(o,buf,x);
      dec(l,x);
    end;
    closetst;
    close(o);
  end;
end;

var
  fill:array[1..10] of string;
  fills,x:word;
  s:string;
const
  bdump:boolean=false;
  regs:boolean=false;
  grfonly:boolean=false;
  listfil:boolean=false;

begin
 { if then directvideo:=false;}
  fills:=0;fillchar(fill,sizeof(fill),0);
  for x:=1 to paramcount do
  begin
    s:=paramstr(x);
    if (s[1]='/') or (s[1]='-') then
      case s[2] of
        'b','B':bdump:=true;
        'g','G':grfonly:=true;
        'r','R':regs:=true;
        'l','L':listfil:=true;

    '?','h','H':begin
                  writeln('SHOWTEST analyses WHATVGA test files (WHVGA*.TST).');
                  writeln('SHOWTEST /? or /h      displays this message');
                  writeln('SHOWTEST /b file1 [file2]       Decodes the BIOS dump in testfile FILE1 to');
                  writeln('                                FILE2 (default FILE1.rom & FILE1.vec)');
                  writeln('SHOWTEST /r [/g] file1 [file2]  Writes a register dump of the modes in testfile');
                  writeln('                                FILE1 to FILE2 (default FILE1.reg). If /g is');
                  writeln('                                used only graphics modes are dumped.');
                  writeln('SHOWTEST file1 [file2]          Writes a detailed test report of the testfile');
                  writeln('                                FILE1 to FILE2 (default FILE1.txt)');
                  writeln('SHOWTEST /l                     Lists the testfiles (*.TST)');
                  halt;
                end;
      end
    else begin
      inc(fills);
      fill[fills]:=s;
    end;
  end;
  if listfil or (fills=0) then wrsumm
  else if bdump then wrBIOS(fill[1],fill[2])
       else if regs then wrregs(fill[1],fill[2],grfonly)
            else wrdetail(fill[1],fill[2]);
end.
