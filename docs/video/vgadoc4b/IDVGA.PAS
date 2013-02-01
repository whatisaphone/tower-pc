unit idvga;
interface
procedure DumpRegisters;

procedure AnalyseMode;

procedure CalcRegisters;

function dumpVGAregs:word;

procedure dumpVGAregfile;

procedure loadmodes;

function FormatRgs(var b:byte):word;   {Format registers for dump}

  {Weitek W5x86 Enable function
   Sets the Extention & Bank enable flags in SEQ index $11}
function WeitekEnable(flag:word):word;

  {Check for PCI devices}
procedure findPCI;

 {Checks for a PCI card with ID=sign, returns index in PCIrec, 0 if not found
  start is the PCI device to start at (0 first time, last ID next time)}
function CheckPCI(start,vendor,device:word):integer;

procedure findvideo;

procedure testdac;

function dacis8bit:boolean;

function DACflags:word;

procedure wPCIbyte(index,val:word);
procedure wPCIword(index,val:word);
procedure wPCIlong(index:word;val:longint);
function rPCIbyte(index:word):word;
function rPCIword(index:word):word;
function rPCIlong(index:word):longint;



const
  PCIdevs:word=0;       {Number of PCI video devices}
var
  PCItype:word;
  PCIrec:array[1..10] of record
           PCIbase:word;
           case integer of
             0:(l:array[0..63] of longint);
             1:(vendor,device,command,status:word;
                rev,prog:byte;class:word;
                cache,latency,header,bist:byte;
                base0,base1,base2,base3,base4,base5
                     ,xx0,xx1,rom,xx2,xx3:longint;
                iline,ipin,mingnt,maxlat:byte);
         end;


{$i idvga2.pas}   {Holds all the Chipset, mode etc definitions.}


function DACflags:word;
var flag:word;
begin
  flag:=0;
  case cv.dactype of
  _dac0,_dac8,_dacCEG:;

  _dacInt:;
  _dac15,_dac16,_dacADAC1,_dacSC486,_dacUMC188:
       flag:=DFL_CmdReg;

  _dacALG1101:;
  _dacALG1201,_dacALG1301:
       flag:=DFL_CmdReg;

  _dacATI68860,_dacATI68880:
       flag:=DFL_8bit;

  _dacATT490,_dacATT491:
       flag:=DFL_CmdReg+DFL_8bit;
  _dacATT492,_dacATT493:
       flag:=DFL_CmdReg;
  _dacATT498,_dacATT1498,_dacATT2498:
       flag:=DFL_CmdReg+DFL_8bit;

  _dacBt477:
       flag:=DFL_8bit;
  _dacBt481,_dacBt482:
       flag:=DFL_CmdReg+DFL_8bit+DFL_cursor;
  _dacBt484,_dacBt485,_dacATT504,_dacATT505:
       flag:=DFL_8bit+DFL_cursor;

  _dacCH8391,
  _dacCH8398:
       flag:=DFL_CmdReg+DFL_8bit+DFL_Clock;

  _dacCL5200:
       flag:=DFL_CmdReg;

  _dacIBM514,_dacIBM524,_dacIBM525,_dacIBM528:
       flag:=DFL_cursor+DFL_8bit+DFL_Clock;

  _dacICS5301:
       flag:=DFL_CmdReg;

  _dacICW498,_dacICW516:
       flag:=DFL_CmdReg+DFL_8bit;

  _dacMU1880,_dacMU4870:
       flag:=DFL_CmdReg;
  _dacMU4910:
       flag:=DFL_CmdReg+DFL_8bit;
  _dacMU9910:
       flag:=DFL_CmdReg+DFL_8bit+DFL_Clock;

  _dacS3_716,_dacS3_708:
       flag:=DFL_CmdReg+DFL_8bit+DFL_Clock;
  _dacSC15021,_dacSC15025:
       flag:=DFL_CmdReg+DFL_8bit;
  _dacSTG1700,_dacSTG1702:
       flag:=DFL_CmdReg+DFL_8bit;
  _dacSTG1703:
       flag:=DFL_CmdReg+DFL_8bit+DFL_Clock;
  _dacTLC34075,_dacTLC34076:
       flag:=DFL_8bit;    {8bit DACs from input pin}
  _dacTR8001:
       flag:=DFL_CmdReg+DFL_8bit;
  _dacTVP3010,_dacTVP3020:
       flag:=DFL_8bit+DFL_Cursor;
  _dacTVP3025,_dacTVP3026:
       flag:=DFL_8bit+DFL_Cursor+DFL_Clock;
  end;
  DACflags:=flag;
end;

procedure loadmodes;              {Load extended modes for this chip}
var
  t:text;
  s,pat:string;
  md,x,xres,yres,err,mreq,byt:word;
  vbe0:_vbe0;
  vbe1:_vbe1;
  xbe1:_xbe1;
  xbe2:_xbe2;
  ok:boolean;

function VESAmemmode(model,bits,redinf,grninf,bluinf,resinf:word):integer;
const
  mode6s=8;
  mode:array[1..mode6s] of byte=(
       _p15,_p16,_p24 ,_p24b,_p32 ,_p32b,_p32c,_p32d);
  blui:array[1..mode6s] of word =(
          5,   5,    8,$1008,    8,$1008, $808,$1808);
  grni:array[1..mode6s] of word =(
       $505,$506, $808, $808, $808, $808,$1008,$1008);
  redi:array[1..mode6s] of word =(
       $A05,$B05,$1008,    8,$1008,    8,$1808, $808);
  resi:array[1..mode6s] of word =(
       $F01,   0,    0,    0,$1808,$1808,    8,    8);
var x:word;
begin
  VESAmemmode:=_text;  {catch weird modes}
  if (bits=15) and (resinf=0) then resinf:=$F01;   {Bloody ATI Vesa driver @#$}
  if (bits=15) and (bluinf=5) and (grninf=$405) then grninf:=$505;
                                                   {@#$ Mach64 VESA driver}
  case model of
    0:VESAmemmode:=_text;
    1:case bits of
        1:VESAmemmode:=_cga1;
        2:VESAmemmode:=_cga2;
      end;
    2:VESAmemmode:=_herc;
    3:case bits of
        2:VESAmemmode:=_pl2;
        4:VESAmemmode:=_pl4;
      end;
    4:case bits of
        4:VESAmemmode:=_pk4;
        8:VESAmemmode:=_p8;
       15:VESAmemmode:=_p15;
       16:VESAmemmode:=_p16;
       24:VESAmemmode:=_p24;
      end;
    5:; {YUV coding}
    6:for x:=1 to mode6s do
      if (redinf=redi[x]) and (grninf=grni[x]) and (bluinf=blui[x])
        and (resinf=resi[x]) then VESAmemmode:=mode[x];
    7:;
  end;
end;


procedure addmode(md,xres,yres,bytes:word;memmode:integer);
begin
  inc(nomodes);
  modetbl[nomodes].md     :=md;
  modetbl[nomodes].xres   :=xres;
  modetbl[nomodes].yres   :=yres;
  modetbl[nomodes].bytes  :=bytes;
  modetbl[nomodes].memmode:=memmode;
  modetbl[nomodes].flags  :=MFL_enabled;
  if memmode>=_PL4 then
    modetbl[nomodes].flags:=modetbl[nomodes].flags OR MFL_graphics;
end;

begin
  nomodes:=0;

  if (cv.flags and FLG_StdVGA)>0 then
  begin
    move(stdmodetbl,modetbl,novgamodes*sizeof(modetype));
    nomodes:=novgamodes;
  end;

  case cv.chip of
   __vesa:begin
            vbe0.sign:=$41534556;    (* VESA *)
            viop($4F00,0,0,0,@vbe0);

               {S3 VESA driver can return wrong segment if run with QEMM}
            IF seg(vbe0.model^)=$E000 then
              vbe0.model:=ptr($C000,ofs(vbe0.model^));
            x:=1;
            while vbe0.model^[x]<>$FFFF do
            begin
              vesamodeinfo(vbe0.model^[x],vbe1);
              if (vbe1.attr and 1)<>0 then
              begin
                memmode:=VESAmemmode(vbe1.model,vbe1.bits,vbe1.redinf
                   ,vbe1.grninf,vbe1.bluinf,vbe1.resinf);
                addmode(vbe0.model^[x],vbe1.width,vbe1.height,vbe1.bytes,memmode);
              end;
              inc(x);
            end;
          end;
    __xbe:begin
            viop($4E01,0,0,cv.id,@xbe1);
            x:=1;
            while xbe1.modep^[x]<>$FFFF do
            begin
              viop($4E02,0,xbe1.modep^[x],cv.id,@xbe2);
              if (rp.ax=$4E) and ((xbe2.attrib and 1)>0) then
              begin
                memmode:=VESAmemmode(xbe2.model,xbe2.bits,xbe2.redinf
                   ,xbe2.grninf,xbe2.bluinf,xbe2.resinf);
                if xbe2.bits=4 then memmode:=_pk4;
                addmode(xbe1.modep^[x],xbe2.pixels,xbe2.lins,xbe2.bytes,memmode);
              end;
              inc(x);
            end;

          end;
  else
    for x:=1 to NBRMODES do
      if MODELIST[x].chp=cv.chip then
      begin
        ok:=true;
        md     :=MODELIST[x].md;
        memmode:=MODELIST[x].mode;
        xres   :=MODELIST[x].xres;
        yres   :=MODELIST[x].yres;
        planes:=1;
        if memmode<_herc then bytes:=xres*2
            else bytes:=(xres*usebits[memmode]) shr 3;
        if memmode=_pl4 then
        begin
          bytes:=xres shr 3;
          planes:=4;
        end;

        case cv.dactype of
          _dacCEG,
            _dac8:if memmode>_p8 then ok:=false;
           _dac15:if memmode>_p15 then ok:=false;
           _dac16,_dacMU4870:
                  if memmode>_p16 then ok:=false;
      _dacALG1101:if (memmode=_p15) or (memmode>_p16) then ok:=false;
        end;
        case cv.chip of
         __ALG:if (md=$48) and (cv.Version=ALG_2228) then bytes:=2048;
         __ARK:if (memmode=_P24) and (cv.Version>=ARK_2000PV) then
               begin
                 memmode:=_P32;
                 bytes:=xres*4;
               end;
         __ATI:begin
                 if (md<$100) and (cv.Version<ATI_M64_GX) then
                 begin
                   rp.bx:=$5506;
                   rp.bp:=$FFFF;
                   rp.si:=0;
                   vio($1200+md);
                   if rp.bp=$FFFF then ok:=false;
                 end;
                       {The VGA chip can't handle the ATI dac yet}
                 if (cv.dactype=_dacATI68860) and (memmode>_P8) then ok:=false;
               end;
      __Compaq:if (cv.Version<CPQ_QV) and (md>$2E) then ok:=false;
       __Cir54:if (cv.Version<CL_GD5430) and ((memmode=_p32) or (xres>1280)) then ok:=false;

          __S3:if (cv.version<=S3_924) then
               begin
                 if ((md>$105) and (md<$200)) or (md=$212) or (md=$211) then ok:=false;
               end
               else begin
                 if md>$210 then ok:=false;
                 if (cv.version<S3_928) and (memmode=_p32) then memmode:=_p24;
                 if (cv.version=S3_928) and (memmode=_PK4a) then ok:=false;
               end;
        __Trid:if cv.version=TR_IITAGX then
                 if (md>=$60) then ok:=false;
       __Tseng:case cv.version of
                 ET_3000:if md=$2F then ok:=false;
                 ET_4000:case cv.subvers of
                           TS_SpeedStar:if (hi(md)=2) or (md=$53E) then ok:=false;
                           TS_Genoa7900:if (hi(md)=1) or (hi(md)=2) then ok:=false;
                         else
                           if (md=$53E) or (hi(md)=1) then ok:=false;
                         end;
               else if (md=$53E) or (hi(md)=1) then ok:=false;
               end;
        end;
        byt  :=MODELIST[x].size;
        if (byt>0) then bytes:=byt;
        mreq:=(longint(bytes*planes)*yres+1023) div 1024;
        if ok and (cv.mm>=mreq) then
          addmode(md,xres,yres,bytes,memmode);
      end;
    for x:=1 to noumodes do  {User overrides (.CFG)}
      if usermodes[x].flags=cv.chip then
        if usermodes[x].memmode=__None then
        begin
          for xres:=1 to nomodes do
            if modetbl[xres].md=usermodes[x].md then
              modetbl[xres].flags:=0;    {Disable}
        end
        else addmode(usermodes[x].md,usermodes[x].xres,usermodes[x].yres
                    ,usermodes[x].bytes,usermodes[x].memmode);
  end;
end;


procedure findPCI;
const ROMs:array[0..3] of string[4]=(' 32K',' 64K','128K','256K');
var
  i,j:word;
  PCIid:longint;
  tmp:longint;

procedure wrPCI(txt:string;base:longint);
begin
  write('      '+txt+': '+hex8(base)+'  at ');
  if (base and 1)>0 then write('I/O: '+hex4(base and $FF00)+'h')
  else write('Mem: '+hex8(base and $FFFFFF00)+'h (',base shr 20,'M)');
  if (base and 8)>0 then write(' Cachable');
  writeln;
end;

begin
  PCItype:=0;
  outp($CF8,0);
  outp($CFA,0);
  if (inp($CF8)=0) and (inp($CFA)=0) then PCItype:=2
  else begin
    tmp:=inplong($CF8);
    for i:=1 to 10 do;  {delay}
    outplong($CF8,$80000000);
    for i:=1 to 10 do;
    if inplong($CF8)=$80000000 then PCItype:=1;
    for i:=1 to 10 do;
    outplong($CF8,tmp);
  end;
  if PCItype>0 then
  begin
    clrscr;
    Writeln('PCI bus type ',PCItype,' Devices:');
    writeln(' Bus: Vendor: Device:');
    case PCItype of
      1:begin   {PCI type 1}
          for i:=0 to 127{511} do
          begin
            outplong($CF8,$80000000+i*longint(2048));
            tmp:=inplong($CFC);
            if (word(tmp)<>$FFFF) and ((tmp shr 16)<>$FFFF) then
            begin
              inc(PCIdevs);
              PCIrec[PCIdevs].PCIbase:=i;
              PCIrec[PCIdevs].l[0]:=tmp;
              for j:=1 to 63 do
              begin
                outplong($CF8,$80000000+i*longint(2048)+j*4);
                PCIrec[PCIdevs].l[j]:=inplong($CFC);
              end;
              if PCIrec[PCIdevs].class<>$300 then dec(PCIdevs);
            end;
          end;
        end;
      2:begin   {PCI type 2}
          outp($CF8,$80);
          outp($CFA,0);   {Bus select?}
          for i:=0 to 15 do
          begin
            tmp:=inplong($C000+i*256);
            if (word(tmp)<>$FFFF) and ((tmp shr 16)<>$FFFF) then
            begin
              inc(PCIdevs);
              PCIrec[PCIdevs].PCIbase:=i;
              PCIrec[PCIdevs].l[0]:=tmp;
              for j:=1 to 63 do PCIrec[PCIdevs].l[j]:=inplong($C000+i*256+j*4);
              if PCIrec[PCIdevs].class<>$300 then dec(PCIdevs);
            end;
          end;
          outp($CF8,0);
        end;
    end;
    if PCIdevs>0 then
    begin
      settextmode;
      for i:=1 to PCIdevs do
      begin
        writeln('  Vendor: '+hex4(PCIrec[i].vendor)+'  Device: '+hex4(PCIrec[i].device));
        if PCIrec[i].base0<>0 then wrPCI('Base0',PCIrec[i].base0);
        if PCIrec[i].base1<>0 then wrPCI('Base1',PCIrec[i].base1);
        if PCIrec[i].base2<>0 then wrPCI('Base2',PCIrec[i].base2);
        if PCIrec[i].base3<>0 then wrPCI('Base3',PCIrec[i].base3);
        if PCIrec[i].base4<>0 then wrPCI('Base4',PCIrec[i].base4);
        if PCIrec[i].base5<>0 then wrPCI('Base5',PCIrec[i].base5);
        if PCIrec[i].rom<>0   then wrPCI('ROM  ',PCIrec[i].rom);

        writeln;
      end;
      if readkey='' then;
    end;
  end;
end;


 {Checks for a PCI card with ID=sign, returns index in PCIrec, 0 if not found
  START is the }
function CheckPCI(start,vendor,device:word):integer;
var i:integer;
begin
  i:=start;
  repeat inc(i);
  until (i>PCIdevs) or ((PCIrec[i].vendor=vendor) and
      ((PCIrec[i].device=device) or (device=$FFFF)));
  if i<=PCidevs then CheckPCI:=i
                else CheckPCI:=0;  {Default: None found}
end;

procedure wPCIbyte(index,val:word);
begin
  case PCItype of
    1:begin
        outplong($CF8,$80000000+PCIrec[cv.PCIid].PCIbase*longint(2048)+index);
        outp($CFC,val);
      end;
    2:begin
        outp($CF8,$80);
        outp($CFA,0);   {Bus select?}
        outp($C000+PCIrec[cv.PCIid].PCIbase*256+index,val);
        outp($CF8,0);
      end;
  end;
end;

procedure wPCIword(index,val:word);
begin
  case PCItype of
    1:begin
        outplong($CF8,$80000000+PCIrec[cv.PCIid].PCIbase*longint(2048)+index);
        outpw($CFC,val);
      end;
    2:begin
        outp($CF8,$80);
        outp($CFA,0);   {Bus select?}
        outpw($C000+PCIrec[cv.PCIid].PCIbase*256+index,val);
        outp($CF8,0);
      end;
  end;
end;

procedure wPCIlong(index:word;val:longint);
begin
  case PCItype of
    1:begin
        outplong($CF8,$80000000+PCIrec[cv.PCIid].PCIbase*longint(2048)+index);
        outpl($CFC,val);
      end;
    2:begin
        outp($CF8,$80);
        outp($CFA,0);   {Bus select?}
        outpl($C000+PCIrec[cv.PCIid].PCIbase*256+index,val);
        outp($CF8,0);
      end;
  end;
end;

function rPCIbyte(index:word):word;
begin
  case PCItype of
    1:begin
        outplong($CF8,$80000000+PCIrec[cv.PCIid].PCIbase*longint(2048)+index);
        rPCIbyte:=inp($CFC);
      end;
    2:begin
        outp($CF8,$80);
        outp($CFA,0);   {Bus select?}
        rPCIbyte:=inp($C000+PCIrec[cv.PCIid].PCIbase*256+index);
        outp($CF8,0);
      end;
  end;
end;

function rPCIword(index:word):word;
begin
  case PCItype of
    1:begin
        outplong($CF8,$80000000+PCIrec[cv.PCIid].PCIbase*longint(2048)+index);
        rPCIword:=inpw($CFC);
      end;
    2:begin
        outp($CF8,$80);
        outp($CFA,0);   {Bus select?}
        rPCIword:=inpw($C000+PCIrec[cv.PCIid].PCIbase*256+index);
        outp($CF8,0);
      end;
  end;
end;

function rPCIlong(index:word):longint;
begin
  case PCItype of
    1:begin
        outplong($CF8,$80000000+PCIrec[cv.PCIid].PCIbase*longint(2048)+index);
        rPCIlong:=inpl($CFC);
      end;
    2:begin
        outp($CF8,$80);
        outp($CFA,0);   {Bus select?}
        rPCIlong:=inpl($C000+PCIrec[cv.PCIid].PCIbase*256+index);
        outp($CF8,0);
      end;
  end;
end;




    (* Analyse the current mode *)

var
  oldreg:boolean;

function getbios(offs,lnn:word):string;
var s:string;
begin
  s[0]:=chr(lnn);
  move(mem[biosseg:offs],s[1],lnn);
  getbios:=s;
end;


procedure checkmem(mx:word);
var
  fail:boolean;
  ma:array[0..99] of byte;
  x:word;
begin
  memmode:=_p8;

  fail:=true;
  while (mx>1) and fail do
  begin
    setbank(mx-1);
    move(mem[SegA000:0],ma,100);
    for x:=0 to 99 do
      mem[SegA000:x]:=ma[x] xor $aa;
    setbank(mx-1);
    fail:=false;
    for x:=0 to 99 do
      if mem[SegA000:x]<>ma[x] xor $aa then fail:=true;
    move(ma,mem[SegA000:0],100);
    if not fail then
    begin
      setbank((mx shr 1)-1);
      for x:=0 to 99 do
        mem[SegA000:x]:=ma[x] xor $55;
      setbank(mx-1);
      fail:=true;
      for x:=0 to 99 do
        if mem[SegA000:x]<>ma[x] xor $55 then fail:=false;
      move(ma,mem[SegA000:0],100);
    end;
    mx:=mx shr 1;
  end;
  cv.mm:=mx*128;
end;


procedure DumpRegisters;

procedure dumprg(base,start,ende:word;var rg:regblk);
var six,ix:word;
  same:boolean;
begin
  rg.base:=base;
  six:=inp(base);
  outp(base,0);
  ix:=inp(base) xor 255;
  outp(base,255);
  ix:=ix and inp(base);

  if ende=0 then
    if ix>127 then ende:=255
    else if ix>63 then ende:=127
    else if ix>31 then ende:=63
    else if ix>15 then ende:=31
    else if ix>7 then ende:=15
    else ende:=7;
  for ix:=start to ende do
    rg.x[ix]:=rdinx(base,ix);
  rg.nbr:=ende;
  outp(base,six);
  same:=true;
  while (rg.nbr>7) and same do    {Check for doubles}
  begin
    six:=succ(rg.nbr) div 2;
    for ix:=0 to six-1 do
      if rg.x[ix]<>rg.x[ix+six] then same:=false;
    if same then rg.nbr:=rg.nbr div 2;
  end;

end;

procedure DumpTridOldRegs;
begin
  wrinx(SEQ,$B,0);
  rgs.tridold0d:=rdinx(SEQ,$D);
  rgs.tridold0e:=rdinx(SEQ,$E);
  if rdinx(SEQ,$B)=0 then;  {New mode}
  oldreg:=true;
end;

procedure DumpXGAregs;
var x:word;
begin
  dumprg(cv.IOadr+10,0,0,rgs.xxregs);
  for x:=0 to 15 do
    rgs.xgaregs[x]:=inp(cv.IOadr+x);
end;

var x,y,m:word;
  VESAcheat:boolean;
begin
  if cv.chip=__VESA then
  begin
    cv.chip:=__Alli;
    cv.ioadr:=$1ce;
    cv.dactype:=_dacSTG1703;
    VESAcheat:=true;
  end
  else VESAcheat:=false;
  case cv.chip of  { Enable ext }
     __S3:begin
	    wrinx(crtc,$38,$48);
	    wrinx(crtc,$39,$A5);
            if (cv.version=S3_732) or (cv.Version=S3_764) then wrinx(SEQ,8,6);
	  end;
   __Trid:begin
            outpw(SEQ,$B);
            if inp(SEQ+1)=0 then;
            x:=rdinx(SEQ,$E) XOR 2;
            outp(SEQ+1,x OR $80);   {Enable extended registers}
          end;
 __Compaq:wrinx(GRC,$F,5);
 {__Video7:wrinx(SEQ,6,$EA); }
  end;
  fillchar(rgs,sizeof(rgs),0);
  oldreg:=false;
  vclk:=0;
  for x:=$3C2 to $3DF do rgs.stdregs[x]:=inp(x);
  rgs.stdregs[$3DA]:=inp(CRTC+6);
  rgs.stdregs[$3C0]:=inp($3C0);
  for x:=0 to 31 do rgs.attregs[x]:=rdinx($3C0,x);
  x:=rdinx($3C0,$30);
  rgs.mode:=curmode;
  dumprg(CRTC,0,0,rgs.crtcregs);
  dumprg(SEQ,0,0,rgs.seqregs);
  dumprg(GRC,0,0,rgs.grcregs);
  case cv.chip of
   __Alli:begin
            if mem[SegA000:$D8]=0 then;
            outpw(SEQ,$1210);
            setinx(SEQ,$1C,8);
            modinx(SEQ,$1B,7,1);

            rgs.xxregs.nbr:=255;
            rgs.xxregs.base:=1;
            move(mem[SegA000:0],rgs.xxregs.x,256);
            clrinx(SEQ,$1B,7);
            clrinx(SEQ,$1C,8);
          end;
    __ati:begin
            dumprg(cv.IOadr,$A0,$BF,rgs.xxregs);
            rgs.xxregs.x[0]:=inp($6AEC);
            rgs.xxregs.x[1]:=inp($6AED);
            rgs.xxregs.x[2]:=inp($6AEE);
            rgs.xxregs.x[3]:=inp($6AEF);
            rgs.xxregs.x[4]:=inp($72EC);
            rgs.xxregs.x[5]:=inp($72ED);
            rgs.xxregs.x[6]:=inp($72EE);
            rgs.xxregs.x[7]:=inp($72EF);
            rgs.xxregs.x[8]:=inp($62EC);
            rgs.xxregs.x[9]:=inp($62ED);
            rgs.xxregs.x[10]:=inp($62EE);
            rgs.xxregs.x[11]:=inp($62EF);
            rgs.xxregs.x[12]:=inp($1EEC);
            rgs.xxregs.x[13]:=inp($1EED);
            rgs.xxregs.x[14]:=inp($1EEE);
            rgs.xxregs.x[15]:=inp($1EEF);
          end;
  __chips:dumprg(cv.IOadr,0,0,rgs.xxregs);
   __VESA,
 __compaq:begin
	    for x:=1 to 15 do
	      for m:=0 to 15 do
		rgs.xxregs.x[(x-1)*16+m]:=inp(x*$1000+$3C0+m);
	    rgs.xxregs.base:=$3C;
	    rgs.xxregs.nbr:=240;
	  end;
     __WD:if cv.Version=WD_90c24 then
            begin
              wrinx(SEQ,$35,$50);  {Unlock clock regs}
              rgs.seqregs.x[$31]:=rdinx(SEQ,$31);
              wrinx(crtc,$34,$A6);
              wrinx(crtc,$35,$30);
              for x:=$31 to $3F do
                rgs.crtcregs.x[x]:=rdinx(crtc,x);
              wrinx(crtc,$34,0);
              wrinx(crtc,$35,0);
            end;
   __Mach64:begin
              move(mem[cv.Xseg:0],rgs.xxregs.x,256);
              rgs.xxregs.x[$D4]:=inp($6AEC);
              rgs.xxregs.x[$D5]:=inp($6AED);
              rgs.xxregs.x[$D6]:=inp($6AEE);
              rgs.xxregs.x[$D7]:=inp($6AEF);
              rgs.xxregs.base:=$2EC;
              rgs.xxregs.nbr:=256;
            end;
   __Mach32:begin
            rgs.xxregs.base:=$2E8;
            rgs.xxregs.nbr:=128;
            for x:=0 to 63 do    {Mach8 & 32}
            begin
              m:=inpw($2E8+(x shl 10));
              rgs.xxregs.x[x*2]:=lo(m);
              rgs.xxregs.x[x*2+1]:=hi(m);
            end;
            if cv.Version>=ATI_GUP_3 then  {Mach32}
            begin
              for x:=0 to 63 do
              begin
                m:=inpw($2EE+(x shl 10));
                rgs.xxregs.x[x*2+128]:=lo(m);
                rgs.xxregs.x[x*2+129]:=hi(m);
              end;
              rgs.xxregs.nbr:=256;
            end;
          end;
  __Tseng:if cv.version>=ET_4W32 then dumprg($217A,0,0,rgs.xxregs);
    __hmc:dumprg(SEQ,$0,$FF,rgs.xxregs);
    __Matrox,
    __oak:dumprg($3DE,0,0,rgs.xxregs);
   __trid:DumpTridOldRegs;
 (*   __agx:if (inp(cv.IOadr) and 4)=0 then DumpTridOldRegs
	  else DumpXGAregs;  *)
    __AGX,__xbe,__xga:
          DumpXGAregs;
  else rgs.xxregs.base:=0;
  end;

  for x:=0 to 15 do
    rgs.dacregs[x]:=rdDACreg(x);
  if (DACflags and DFL_CmdReg)>0 then
  begin
    dac2comm;
    rgs.dacregs[16]:=inp($3C6);
    dac2pel;
  end;
  rgs.dacinxd.nbr :=0;
  rgs.dacinxd.base:=0;
  case cv.dactype of
_dacCL5200:begin
             outp($3C6,0);
             dac2comm;
             rgs.dacregs[6]:=inp($3C6);
             dac2pel;
             outp($3C6,rgs.dacregs[2]);
           end;
_dacMU1880:begin
             dac2comm;
             dac2comm;
             x:=8;
             while (x>0) and (inp($3C6)<>$8E) do dec(x);
             rgs.dacinxd.x[6]:=inp($3C6);
             rgs.dacinxd.x[6]:=inp($3C6);
             dac2pel;

           end;
 _dacSC15021,_dacSc15025:
           begin    {Sierra SC15025 24bit DAC}
             y:=inp(SetDACpage(dacHIcmd));
             outp(SetDACpage(dacHIcmd),y or 16);
             dumprg($3C7,0,31,rgs.dacinxd);
             outp(SetDACpage(dacHIcmd),y);
           end;
 _dacSTG1700,_dacSTG1702,_dacSTG1703:
           begin
             rgs.dacinxd.base:=$3C6;
             rgs.dacinxd.nbr:=7;
             y:=inp(SetDACpage(dacHIcmd));
             outp(SetDACpage(dacHIcmd),y or 16);
             dac2comm;
             m:=inp($3C6);
             outp($3C6,0);
             outp($3C6,0);
             for x:=0 to 7 do
               rgs.dacinxd.x[x]:=inp($3C6);
             if cv.dactype=_dacSTG1703 then
             begin
               for x:=8 to $5F do
                 rgs.dacinxd.x[x]:=inp($3C6);
               rgs.dacinxd.nbr:=$5F;
             end;
             wrDACreg(dacHIcmd,y);
           end;
 _dacBt481,_dacBt482:
           begin
             if cv.chip=__AGX then outp(cv.IOadr,1);
           (*  outp(SetDACpage(dacBT1cmdA),1);
             for x:=0 to 15 do {This screws up the DAC, so we drop it for now}
             begin
               outp($3C8,x);
               rgs.dacinxd.x[x]:=inp($3C6);
             end;
             rgs.dacinxd.base:=$3C6;
             rgs.dacinxd.nbr:=15;
             outp(SetDACpage(dacBT1cmdA),rgs.dacregs[dacBT1cmdA]); *)
             if cv.chip=__AGX then outp(cv.IOadr,4);
           end;
 _dacBt484,_dacBt485,_dacATT504,_dacATT505:
           begin    {BrookTree Bt484/5 or ATT20c504/5 DAC}
             outp(SetDACpage(dacBTcmd0),rgs.dacregs[dacBTcmd0] or $80);
             outp(SetDACpage(0),0);
             rgs.dacregs[dacBTstat]:=inp(SetDACpage(dacBTstat));
             outp(SetDACpage(0),1);
             rgs.dacregs[16]:=inp(SetDACpage(dacBTstat));
             outp(SetDACpage(dacBTcmd0),rgs.dacregs[dacBTcmd0]);
           end;
_dacCH8391,
_dacCH8398:begin
             outp(SetDACpage(7),0);
             for x:=1 to 4 do y:=inp(SetDACpage(4));
             rgs.dacregs[16]:=inp(SetDACpage(4));
             outp(SetDACpage(7),0);
             for x:=0 to 47 do rgs.dacinxd.x[x]:=inp(SetDACpage(5));
             rgs.dacinxd.base:=$3C8;
             rgs.dacinxd.nbr :=47;
           end;
 _dacS3_708,_dacS3_716:
           begin  {S3 SDAC and GenDAC}
             outp(SetDACpage(7),0);
             for x:=0 to 31 do  {There are 16 16bit registers}
             begin
               {outp(SetDACpage(7),x);}
               rgs.dacinxd.x[x]:=inp(SetDACpage(5));
             end;
             rgs.dacinxd.base:=$3C6;
             rgs.dacinxd.nbr:=31;
           end;
 _dacTVP3010,_dacTVP3020,_dacTVP3025:
           begin    {TI TVP 302x DAC}
             y:=rdDACreg(dacTVPindex);
             for y:=0 to $3F do
             begin
               wrDACreg(dacTVPindex,y);
               rgs.dacinxd.x[y]:=rdDACreg(dacTVPdata);
             end;

             wrDACreg(dacTVPindex,$2C);
             wrDACreg(dacTVPdata,0);  {PLL 1st byte}
             wrDACreg(dacTVPindex,$2D);
             rgs.dacinxd.x[$40]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVP6index,$2E);
             rgs.dacinxd.x[$43]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVPindex,$2F);
             rgs.dacinxd.x[$46]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVPindex,$2C);
             wrDACreg(dacTVPdata,1);  {PLL 2nd byte}
             wrDACreg(dacTVPindex,$2D);
             rgs.dacinxd.x[$41]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVPindex,$2E);
             rgs.dacinxd.x[$44]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVPindex,$2F);
             rgs.dacinxd.x[$47]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVPindex,$2C);
             wrDACreg(dacTVPdata,2);  {PLL 3rd byte}
             wrDACreg(dacTVPindex,$2D);
             rgs.dacinxd.x[$42]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVPindex,$2E);
             rgs.dacinxd.x[$45]:=rdDACreg(dacTVPdata);
             wrDACreg(dacTVPindex,$2F);
             rgs.dacinxd.x[$48]:=rdDACreg(dacTVPdata);
             rgs.dacinxd.nbr:=$48;
             rgs.dacinxd.base:=$3C6;
             wrDACreg(dacTVP6index,y);
           end;
 _dacTVP3026:
           begin    {TI TVP 3026 DAC}
             y:=rdDACreg(dacTVP6index);
             for y:=0 to $3F do
             begin
               wrDACreg(dacTVP6index,y);
               rgs.dacinxd.x[y]:=rdDACreg(dacTVP6data);
             end;

             wrDACreg(dacTVP6index,$2C);
             wrDACreg(dacTVP6data,0);  {PLL 1st byte}
             wrDACreg(dacTVP6index,$2D);
             rgs.dacinxd.x[$40]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2E);
             rgs.dacinxd.x[$43]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2F);
             rgs.dacinxd.x[$46]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2C);
             wrDACreg(dacTVP6data,1);  {PLL 2nd byte}
             wrDACreg(dacTVP6index,$2D);
             rgs.dacinxd.x[$41]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2E);
             rgs.dacinxd.x[$44]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2F);
             rgs.dacinxd.x[$47]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2C);
             wrDACreg(dacTVP6data,2);  {PLL 3rd byte}
             wrDACreg(dacTVP6index,$2D);
             rgs.dacinxd.x[$42]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2E);
             rgs.dacinxd.x[$45]:=rdDACreg(dacTVP6data);
             wrDACreg(dacTVP6index,$2F);
             rgs.dacinxd.x[$48]:=rdDACreg(dacTVP6data);
             rgs.dacinxd.nbr:=$48;
             rgs.dacinxd.base:=$3C6;
             wrDACreg(dacTVP6index,y);
           end;
_dacMU9910:begin
             rgs.dacinxd.base:=$83C9;
             rgs.dacinxd.nbr:=$1F;
             outp(SetDACpage(7),0);
             for y:=0 to $1F do
               rgs.dacinxd.x[y]:=inp(SetDACpage(5));
           end;
_dacIBM514,_dacIBM524,_dacIBM525,_dacIBM528:
           begin
             rgs.dacinxd.base:=$3C6;
             rgs.dacinxd.nbr:=255;

           (*  wrDACreg(dacIBMind1,0);
             for x:=0 to 255 do
             begin
               wrDACreg(dacIBMind0,x);
               rgs.dacinxd.x[x]:=rdDACreg(dacIBMdata);
             end;
             wrDACreg(dacIBMind0,rgs.dacregs[dacIBMind0]); *)
           end;
  end;
  clearDACpage;
  case cv.chip of  { Disable ext }
     __S3:begin
            if (cv.version=S3_732) or (cv.Version=S3_764) then
              wrinx(SEQ,8,rgs.seqregs.x[8]);
	    wrinx(crtc,$38,0);
	    wrinx(crtc,$39,$5A);
	  end;
   __Trid:if cv.version>=TR_GUI9440 then
          begin
            setinx(SEQ,$C,$60);
            rgs.dacregs[ 8]:=inp($43C8);
            rgs.dacregs[ 9]:=inp($43C9);
            rgs.dacregs[10]:=inp($43C6);
            rgs.dacregs[11]:=inp($43C7);
            wrinx(SEQ,$C,rgs.seqregs.x[$C]);
          end;
  end;
  if VESAcheat then cv.chip:=__VESA;
end;

procedure CalcRegisters;
{const
  wd24clk:array[0..15] of real=(29.979,77.408,0,80.092,25.175,28.322
          ,65,36,39.822,50.114,42.060,44.297,31.5,35.501,75.166,50.114); }
var x,m,wid,wordadr,pixwid,clksel,vclkdiv:word;
    force256,graph,isilace:boolean;
    hfreqfact:word;

  VESAcheat,
  SerialDAC:boolean;     {If set the DAC takes one byte at a time}
begin
  if cv.chip=__VESA then
  begin
    cv.chip:=__Alli;
    VESAcheat:=true;
  end
  else VESAcheat:=false;
  SerialDAC:=true;
  m:=rgs.grcregs.x[6];
  case (m shr 2) and 3 of
  0,1:calcvseg:=SegA000;
    2:calcvseg:=SegB000;
    3:calcvseg:=SegB800;
  end;
  clksel:=(rgs.stdregs[$3CC] shr 2) and 3;
  vclkdiv:=12;     {Base 12.}
  begin
    ilace:=false;
    isilace:=false;  {Interlaced, but do not double lines!!}
    extpixfact:=1;
    extlinfact:=1;

    hfreqfact:=1;
    calclines:=rgs.crtcregs.x[$12]+1;
    pixwid:=8;
    calcpixels:=rgs.crtcregs.x[1]+1;
    force256:=false;
    calchtot:=rgs.crtcregs.x[0]+5;
    calcvtot:=rgs.crtcregs.x[6]+2;

    calchblks:=rgs.crtcregs.x[2];
    calchrtrs:=rgs.crtcregs.x[4];
    calchblke:=rgs.crtcregs.x[3] and 31;
    calchrtre:=rgs.crtcregs.x[5] and 31;
    hrtrmask:=$1F;   {Retrace and blanking masks (valid bits)}
    hblkmask:=$3F;
    calcvblks:=rgs.crtcregs.x[$15];
    calcvrtrs:=rgs.crtcregs.x[$10];
    calcvblke:=rgs.crtcregs.x[$16] and 127;
    calcvrtre:=rgs.crtcregs.x[$11] and 15;
    vblkmask:=$7F;
    vrtrmask:=$F;

    if (rgs.crtcregs.x[7] and   1)>0 then inc(calcvtot, 256);
    if (rgs.crtcregs.x[7] and   2)>0 then inc(calclines,256);
    if (rgs.crtcregs.x[7] and   4)>0 then inc(calcvrtrs,256);
    if (rgs.crtcregs.x[7] and   8)>0 then inc(calcvblks,256);
    if (rgs.crtcregs.x[7] and $20)>0 then inc(calcvtot, 512);
    if (rgs.crtcregs.x[7] and $40)>0 then inc(calclines,512);
    if (rgs.crtcregs.x[7] and $80)>0 then inc(calcvrtrs,512);
    if (rgs.crtcregs.x[5] and $80)>0 then inc(calchblke, 32);
    if (rgs.crtcregs.x[9] and $20)>0 then inc(calcvblks,512);

    if (rgs.seqregs.x[1] and 8)>0 then vclkdiv:=vclkdiv*2;

    graph:=(rgs.attregs[$10] and 1)>0;
    if graph then
    begin
      extlinfact:=(rgs.crtcregs.x[9] and $1F)+1;
      if (rgs.crtcregs.x[9] and $80)>0 then extlinfact:=extlinfact*2;
    end
    else begin
      if {((rgs.attregs[$10] and 4)>0) or} ((rgs.seqregs.x[1] and 1)=0) then charwid:=9 else charwid:=8;
      charhigh:=(rgs.crtcregs.x[9] and $1f)+1;
    end;

    wid:=rgs.crtcregs.x[$13];
    wordadr:=2;
    if (rgs.crtcregs.x[$14] and 64)<>0 then wordadr:=8
    else if (rgs.crtcregs.x[$17] and 64)=0 then wordadr:=4;
    case cv.chip of
      __Acer:wid:=wid+(rgs.crtcregs.x[$81] and 3) shl 8;
       __AGX:begin
	       calcpixels:=rgs.xxregs.x[$13]*256+rgs.xxregs.x[$12]+1;
	       calchtot:=rgs.xxregs.x[$11]*256+rgs.xxregs.x[$10]+1;
	       pixwid:=8;
	       calclines :=rgs.xxregs.x[$23]*256+rgs.xxregs.x[$22]+1;
	       calcvtot:=rgs.xxregs.x[$21]*256+rgs.xxregs.x[$20]+1;
	       wid :=rgs.xxregs.x[$44]*256+rgs.xxregs.x[$43];
	       wordadr:=8;
               vclkdiv:=12;  {Nominal}
               if (rgs.xxregs.x[$50] and 8)>0 then ilace:=true;
	     end;
     __ahead:begin
	       if (rgs.grcregs.x[$1c] and 12)=12 then ilace:=true;
	       if (rgs.seqregs.x[4] and 8)<>0 then wordadr:=16;
	     end;
       __ALG:begin
	       if (rgs.grcregs.x[$C] and $10)>0 then wordadr:=wordadr shl 1
               else if (rgs.crtcregs.x[$14] and 64)>0 then  {Packed mode}
               begin
                 pixwid:=4;
                 vclkdiv:=vclkdiv*2;
               end;
	       if (rgs.crtcregs.x[$19] and 1)>0 then
	       begin
		 ilace:=true;
		 wordadr:=wordadr shr 1;
	       end;
               if (cv.version>ALG_2101) and ((rgs.crtcregs.x[$19] and $80)>0) then
               begin
                 if (rdinx(crtc,$2A) and 1)>0 then inc(calchtot,256);
                 if (rdinx(crtc,$28) and $80)>0 then inc(wid,256);
               end;
	     end;
      __Alli:begin
               if (rgs.grcregs.x[5] and $40)>0 then
               begin
                 force256:=true;
                 wordadr:=8;
               end;
               inc(wid,(rgs.crtcregs.x[$1C] shr 4)*256);
               if (rgs.crtcregs.x[$1A] and 1)>0 then inc(calcvtot,1024);
               if (rgs.crtcregs.x[$1A] and 2)>0 then inc(calclines,1024);
               if (rgs.crtcregs.x[$1A] and 4)>0 then inc(calcvrtrs,1024);
               if (rgs.crtcregs.x[$1A] and 8)>0 then inc(calcvblks,1024);
               if (rgs.crtcregs.x[$1B] and 1)>0 then inc(calchtot,256);
               if (rgs.crtcregs.x[$1B] and 4)>0 then inc(calchblks,256);
               if (rgs.crtcregs.x[$1B] and 8)>0 then inc(calchrtrs,256);
             end;
       __ARK:begin
               if (rgs.crtcregs.x[$44] and 4)>0 then ilace:=true;
               if (rgs.crtcregs.x[$41] and 128)>0 then inc(calchtot,256);
               if (rgs.crtcregs.x[$41] and  64)>0 then inc(calcpixels,256);
               if (rgs.crtcregs.x[$41] and  32)>0 then inc(calchblks,256);
               if (rgs.crtcregs.x[$41] and  16)>0 then inc(calchrtrs,256);
               if (rgs.crtcregs.x[$41] and   8)>0 then inc(wid,256);
               if (rgs.crtcregs.x[$40] and 128)>0 then inc(calcvtot,1024);
               if (rgs.crtcregs.x[$40] and  64)>0 then inc(calclines,1024);
               if (rgs.crtcregs.x[$40] and  32)>0 then inc(calcvblks,1024);
               if (rgs.crtcregs.x[$40] and  16)>0 then inc(calcvrtrs,1024);
             end;
       __ati:begin
               if cv.Version=ATI_18800 then
               begin
                 if (rgs.xxregs.x[$B2] and 1)<>0 then ilace:=true;
               end
  	       else if (rgs.xxregs.x[$BE] and 2)<>0 then ilace:=true;
	       if (rgs.xxregs.x[$B0] and $20)>0 then
	       begin
		 force256:=true;
		 if cv.Version=ATI_18800 then wordadr:=8
                                         else wordadr:=16;
	       end;
               if ((rgs.xxregs.x[$B3] and $40)>0) and (cv.Version>ATI_18800) then
               begin
                 pixwid:=pixwid*2;
                 wordadr:=wordadr*2;
               end;
               if ((rgs.xxregs.x[$B6] and $10)>0) and ((cv.version<ATI_GUP_3)
                   or (cv.Version>=ATI_M64_GX)) then
               begin
                 force256:=false;
               end;
               if ((rgs.xxregs.x[$B1] and $40)>0) then
               begin
                 calclines:=calclines div 2;
                 calcvtot:=calcvtot div 2;
               end;
               if ((rgs.seqregs.x[4] and 8)>0) and not force256 then
                  pixwid:=pixwid*2;   {Mode 65h (PK4) fix}


               if (cv.Version=ATI_28800_6) and ((rgs.xxregs.x[$AD] and 8)>0) then
               begin
                 if (rgs.xxregs.x[$AD] and 1)>0 then inc(calchtot,256);
                 if (rgs.xxregs.x[$AD] and 2)>0 then inc(calchblks,256);
                 if (rgs.xxregs.x[$AD] and 4)>0 then inc(calchrtrs,256);
               end;
	     end;
     __chips:begin
	       if (rgs.xxregs.x[$D] and 1)<>0 then inc(wid,256);
               if (rgs.xxregs.x[$17] and 1)>0 then inc(calchtot,256);
               if (rgs.xxregs.x[$D] and 4)>0 then inc(wid,256);
	       if (rgs.xxregs.x[$B] and 4)>0 then
	       begin
                 force256:=true;
		 wordadr:=8;
	         if cv.version<CT_65520 then
                 begin
                   pixwid:=4;
                   vclkdiv:=vclkdiv*2;
                 end;
	       end;
               if (rgs.xxregs.x[$28] and $20)>0 then ilace:=true;
	     end;
     __cir54:begin
	       if (rgs.seqregs.x[4] and 8)>0 then wordadr:=8;
	       if (rgs.crtcregs.x[$1B] and 16)>0 then inc(wid,256);
	       if (rgs.crtcregs.x[$1A] and 1)>0 then ilace:=true;
               if (rgs.crtcregs.x[$1B] and $80)>0 then
               begin
                 inc(calchblke,(rgs.crtcregs.x[$1A] and $30) shl 2);
                 hblkmask:=$FF;
                 calcvblke:=rgs.crtcregs.x[$16]+((rgs.crtcregs.x[$1A] and $C0) shl 2);
                 vblkmask:=$3FF;
               end;
	     end;
     __cir64:begin
	       if (rgs.seqregs.x[4] and 8)<>0 then wordadr:=8;
	       if (rgs.grcregs.x[$82] and 7)=2 then pixwid:=4;
	       if (rgs.grcregs.x[$79] and  1)>0 then inc(calchtot,1024);
	       if (rgs.grcregs.x[$79] and  2)>0 then inc(calclines,1024);
	       if (rgs.grcregs.x[$79] and 16)>0 then inc(calchrtrs,1024);
               inc(calchblks,(rgs.grcregs.x[$79] and $C) shl 7);
	     end;
    __compaq:begin
	       if (rgs.grcregs.x[$F] and $F0)=0 then wordadr:=8;
               inc(wid,(rgs.grcregs.x[$42] and 3)*256);
	       if (rgs.crtcregs.x[$14] and 64)>0 then pixwid:=4;
               if (rgs.grcregs.x[$51] and $40)>0 then inc(calcvtot,1024);
               if (rgs.grcregs.x[$51] and $80)>0 then inc(calcvrtrs,1024);
              { if (rgs.grcregs.x[$51] and $20)>0 then inc(calchrtre,32);
               hrtrmask:=$3F; }
               if cv.version>CPQ_QV then
               begin
                 SerialDAC:=false;   {Dirty Hack!!}
                 if memmode>=_PK4 then pixwid:=pixwid shr 2;
               end;
	     end;
     __genoa:begin
               if (rgs.crtcregs.x[$2F] and 1)<>0 then ilace:=true;
               if (rgs.crtcregs.x[$2F] and 2)<>0 then wordadr:=16;
               if (rgs.seqregs.x[4] and 8)>0 then pixwid:=4;
             end;
       __hmc:begin
               IF (rgs.xxregs.x[$E7] and 1)>0 then ilace:=true;
               if (rgs.xxregs.x[$E7] and 2)>0 then force256:=true;
              { if (rgs.xxregs.x[$E7] and 64)>0 then inc(clksel,4);
               vclk:=HMCclk[clksel]; }
             end;
    __Mach32:begin
               calcpixels:=rgs.xxregs.x[$D8]+1;   {B2EE}
               calchtot  :=rgs.xxregs.x[$D9]+1;   {B2EF}
               calcvtot  :=(rgs.xxregs.x[$E0]+rgs.xxregs.x[$E1]*256)+1; {C2EE}
               calclines :=(rgs.xxregs.x[$E2]+rgs.xxregs.x[$E3]*256)+1; {C6EE}
               calchrtrs :=rgs.xxregs.x[$DA];   {B6EE}
               calchrtre :=calchrtrs+(rgs.xxregs.x[$DC] and $1F);   {BAEE}
               calcvrtrs :=(rgs.xxregs.x[$E4]+rgs.xxregs.x[$E5]*256)+1; {CAEE}
               calcvrtre :=calcvrtrs+(rgs.xxregs.x[$E8] and $1F);   {D2EE}
               pixwid:=8;
               case rgs.xxregs.x[$C6] and $30 of   {8EEE}
                   0:calcmmode:=_pk4;
                 $10:calcmmode:=_p8;
                 $20:case rgs.xxregs.x[$C6] and $C0 of
                        0:calcmmode:=_p15;
                      $40:calcmmode:=_p16;
                     end;
                 $30:case rgs.xxregs.x[$C7] and 6 of
                       0:calcmmode:=_p24;
                       2:calcmmode:=_p32c;
                       4:calcmmode:=_p24b;
                       6:calcmmode:=_p32b;
                     end;
               end;
               {There is no way to determine the bytes/scanline (Write only)}
             end;
    __Mach64:begin
               calchtot  :=(rgs.xxregs.x[$0]+rgs.xxregs.x[$1]*256)+1;
               calcpixels:=(rgs.xxregs.x[$2]+rgs.xxregs.x[$3]*256)+1;
               calcvtot  :=(rgs.xxregs.x[$8]+rgs.xxregs.x[$9]*256)+1;
               calclines :=(rgs.xxregs.x[$A]+rgs.xxregs.x[$B]*256)+1;
               wid       :=(rgs.xxregs.x[$16]+rgs.xxregs.x[$17]*256) shr 6;
               calchrtrs :=rgs.xxregs.x[$4];
               calchrtre :=calchrtrs+(rgs.xxregs.x[$6] and $1F);
               calcvrtrs :=(rgs.xxregs.x[$C]+rgs.xxregs.x[$D]*256)+1;
               calcvrtre :=calcvrtrs+(rgs.xxregs.x[$E] and $1F);
               pixwid:=8;
               calcmmode:=_P8;
               if (rgs.xxregs.x[$1C] and 2)>0 then ilace:=true;
               case rgs.xxregs.x[$1D] and 7 of
                 1:calcmmode:=_PK4;
                 2:calcmmode:=_P8;
                 3:calcmmode:=_P15;
                 4:calcmmode:=_P16;
                 5:calcmmode:=_P24;
                 6:calcmmode:=_P32;
               end;
               wordadr:=usebits[calcmmode];
               SerialDAC:=false;
             end;
    __Matrox:begin
               if (rgs.xxregs.x[$D] and $40)>0 then
               begin
                 ilace:=true;
                 if (rgs.xxregs.x[1] and 8)=0 then   {not Ext 256c}
                   wordadr:=wordadr shr 1;
               end;
               if (rgs.xxregs.x[1] and 8)>0 then   {Ext 256c}
                 wordadr:=wordadr shl 2;

             end;
      __mxic:if (rgs.seqregs.x[$F0] and 3)=3 then ilace:=true;
       __NCR:begin
	       if (rgs.seqregs.x[$20] and 2)<>0 then
	       begin
		 force256:=true;
		 wordadr:=8;
	       end;
	       if (rgs.seqregs.x[$1F] and $10)<>0 then
		 case rgs.seqregs.x[$1F] and 15 of
		   0:pixwid:=4;
		  11:pixwid:=16;
		 else pixwid:=(rgs.seqregs.x[$1F] and 15)+6;
		 end;
	       if (rgs.crtcregs.x[$30] and $10)<>0 then
	       begin
		 ilace:=true;
		 extlinfact:=1;
	       end;
               if (rgs.crtcregs.x[$30] and  1)>0 then inc(calchtot,256);
	       if (rgs.crtcregs.x[$30] and  2)>0 then inc(calcpixels,256);
               if (rgs.crtcregs.x[$30] and  4)>0 then inc(calchblks,256);
               if (rgs.crtcregs.x[$30] and  8)>0 then inc(calchrtrs,256);
	       if (rgs.crtcregs.x[$31] and 16)>0 then inc(wid,256);
               if cv.version>=NCR_77c22Ep then
               begin
                 if (rgs.crtcregs.x[$32] and 1)>0 then inc(calchtot,512);
                 if (rgs.crtcregs.x[$32] and 2)>0 then inc(calcpixels,512);
                 if (rgs.crtcregs.x[$32] and 4)>0 then inc(calchblks,512);
                 if (rgs.crtcregs.x[$32] and 8)>0 then inc(calchrtrs,512);
                 if (rgs.crtcregs.x[$33] and 1)>0 then inc(calcvtot,1024);
                 if (rgs.crtcregs.x[$33] and 2)>0 then inc(calclines,1024);
                 if (rgs.crtcregs.x[$33] and 4)>0 then inc(calcvblks,1024);
                 if (rgs.crtcregs.x[$33] and 8)>0 then inc(calcvrtrs,1024);
                 if (rgs.crtcregs.x[$30] and 32)>0 then
                 begin
                   inc(calchblke,(rgs.crtcregs.x[$32] and $30) shl 2);
                   hblkmask:=$FF;
                   inc(calchrtre,(rgs.crtcregs.x[$32] and $C0) shr 1);
                   hrtrmask:=$7F;
                   calcvblke:=rgs.crtcregs.x[$16]+((rgs.crtcregs.x[$33] and $60) shl 3);
                   vblkmask:=$3FF;
                   inc(calchrtre,(rgs.crtcregs.x[$33] and $80) shr 3);
                   vrtrmask:=$1F;
                 end;
               end;
	     end;
       __oak:if cv.version<>OAK_037 then
             begin
	       if (rgs.xxregs.x[$14] and 128)<>0 then ilace:=true;
               if (rgs.xxregs.x[$14] and 1)>0 then inc(calcvtot,1024);
               if (rgs.xxregs.x[$14] and 2)>0 then inc(calclines,1024);
               if (rgs.xxregs.x[$14] and 4)>0 then inc(calcvrtrs,1024);
               if cv.Version<=OAK_083 then
               begin
                 if (rgs.seqregs.x[4] and 8)<>0 then wordadr:=16;
					  {Cheat for 256 color mode}
               end
               else begin
                 if (rgs.seqregs.x[4] and 8)<>0 then
                   if (rgs.xxregs.x[$21] and 4)>0 then wordadr:=16
                                                  else pixwid:=4;
               end;
	     end;
     __p2000:begin
	       if (rgs.grcregs.x[$13] and $40)<>0 then
	       begin
		 wordadr:=wordadr shr 1;
		 ilace:=true;
	       end;
	       if (rgs.grcregs.x[$21] and $20)<>0 then inc(wid,256);
	     end;
        __WD:begin
	       if (cv.version>=WD_90c00) then
                 if (rgs.crtcregs.x[$2D] and $20)>0 then ilace:=true;
	       if (cv.version>=WD_90c30) then
               begin
                 if (rgs.crtcregs.x[$3D] and 1)>0 then inc(calcvtot,1024);
                 if (rgs.crtcregs.x[$3D] and 2)>0 then inc(calclines,1024);
                 if (rgs.crtcregs.x[$3D] and 4)>0 then inc(calcvrtrs,1024);
                 if (rgs.crtcregs.x[$3D] and 8)>0 then inc(calcvblks,1024);
               end;
	       if (rgs.seqregs.x[4] and 8)>0 then wordadr:=8;
					  {Cheat for 256 color mode}
	     {  if (rgs.grcregs.x[$C] and 2)>0 then inc(clksel,4);
	       vclk:=WDclk[clksel];  }
	       if (cv.version>=WD_90c33) and ((rgs.crtcregs.x[$3E] and $20)>0) then inc(calchtot,256);
	     end;
   __realtek:begin
	       if (rgs.seqregs.x[4] and 8)<>0 then
               begin
                 pixwid:=4;
                 hfreqfact:=2;
               end;
	       if (rgs.grcregs.x[$C] and $10)<>0 then
	       begin
		 pixwid:=pixwid*2;
		 wid:=wid*2;
	       end;
	       if (rgs.crtcregs.x[$19] and 1)<>0 then
	       begin
		 ilace:=true;
		 wid:=wid div 2;
	       end;
	     end;
	__s3:begin
	       if (rgs.crtcregs.x[$42] and $20)<>0 then ilace:=true;
	       if (rgs.crtcregs.x[$43] and 4)<>0   then inc(wid,256);
	       if (rgs.crtcregs.x[$43] and $80)<>0 then pixwid:=pixwid*2;
	       if (rgs.seqregs.x[4] and 8)<>0 then wordadr:=8 else wordadr:=2;
	       if (rgs.attregs[$10] and 1)=0 then wid:=wid*2;
               if (rgs.crtcregs.x[$3A] and $10)>0 then force256:=true;
               if (cv.Version>S3_924) then
               begin
                 if (rgs.crtcregs.x[$5D] and  1)>0 then inc(calchtot,256);
                 if (rgs.crtcregs.x[$5D] and  2)>0 then inc(calcpixels,256);
                 if (rgs.crtcregs.x[$5D] and  4)>0 then inc(calchblks,256);
                 if (rgs.crtcregs.x[$5D] and 16)>0 then inc(calchrtrs,256);
                 if (rgs.crtcregs.x[$5E] and  1)>0 then inc(calcvtot,1024);
                 if (rgs.crtcregs.x[$5E] and  2)>0 then inc(calclines,1024);
                 if (rgs.crtcregs.x[$5E] and  4)>0 then inc(calcvblks,1024);
                 if (rgs.crtcregs.x[$5E] and 16)>0 then inc(calcvrtrs,1024);
                 if (rgs.crtcregs.x[$51] and $30)>0 then
                   wid:=(wid and $FF)+(rgs.crtcregs.x[$51] and $30) shl 4;
               end;
	     end;
        __SC:wid:=wid+(rgs.crtcregs.x[$1E] and $30) shl 4;
       __SiS:begin
               wid:=wid+(rgs.seqregs.x[$A] and $F0) shl 4;
               if (rgs.seqregs.x[6] and $20)>0 then
               begin
                 ilace:=true;
                 wid:=wid shr 1;
               end;
             end;
      __trid:begin
               if memmode>=_P8 then wordadr:=8;   {Req'd for 9440 800x600 16bit}
	       if (rgs.tridold0d and 16)<>0 then wordadr:=wordadr*2
	       else if cv.version<TR_GUI9440 then
               begin
                 if (rgs.seqregs.x[4] and 8)>0 then pixwid:=pixwid div 2;
                 if memmode>=_p8 then vclkdiv:=vclkdiv*2;
               end;
	       if (rgs.crtcregs.x[$1e] and 4)<>0 then
                 if cv.version=TR_IITAGX then isilace:=true
                 else begin
                   ilace:=true;
                   if cv.version<TR_GUI9440 then wordadr:=wordadr div 2;
                 end;
               if (cv.mm=512) and (memmode>=_p8) and
                 (cv.version<TR_IITAGX) then hfreqfact:=2;
               if (rgs.grcregs.x[$F] and 8)>0 then pixwid:=pixwid*2;
               if (rgs.crtcregs.x[$29] and $10)>0 then inc(wid,256);
	     end;
     __Tseng:if cv.version=ET_3000 then
             begin
	       if (rgs.crtcregs.x[$25] and $80)>0 then ilace:=true;
               if (rgs.crtcregs.x[$25] and 1)>0 then inc(calcvblks,1024);
               if (rgs.crtcregs.x[$25] and 2)>0 then inc(calcvtot,1024);
               if (rgs.crtcregs.x[$25] and 4)>0 then inc(calclines,1024);
               if (rgs.crtcregs.x[$25] and 8)>0 then inc(calcvrtrs,1024);
	       if (rgs.grcregs.x[5] and $40)>0 then wordadr:=16;
	       if (rgs.seqregs.x[7] and $40)>0 then
	       begin
		 pixwid:=pixwid*2;
		 wordadr:=wordadr*2;
	       end;
	     end
             else begin
               if (rgs.crtcregs.x[$3F] and $80)>0 then inc(wid,256);
               if (rgs.crtcregs.x[$3F] and  1)>0 then inc(calchtot,256);
               if (rgs.crtcregs.x[$3F] and  4)>0 then inc(calchblks,256);
               if (rgs.crtcregs.x[$3F] and 16)>0 then inc(calchrtrs,256);
               if (rgs.crtcregs.x[$35] and 1)>0 then inc(calcvblks,1024);
               if (rgs.crtcregs.x[$35] and 2)>0 then inc(calcvtot,1024);
               if (rgs.crtcregs.x[$35] and 4)>0 then inc(calclines,1024);
               if (rgs.crtcregs.x[$35] and 8)>0 then inc(calcvrtrs,1024);
               if (rgs.crtcregs.x[$35] and $80)>0 then isilace:=true;
               if (rgs.attregs[$10] and $40)>0 then pixwid:=4;
           {    if ((rgs.attregs[$16] and $20)>0) and (cv.version>=ET_4W32P) then pixwid:=pixwid*2; }
             end;
       __UMC:begin
	       if (rgs.crtcregs.x[$33] and $10)>0 then wordadr:=16
               else if ((rgs.attregs[$10] and 64)>0) then
               begin
                 pixwid:=4;
                 hfreqfact:=2;
               end;
	       if (rgs.crtcregs.x[$2F] and 1)>0 then
	       begin
		 ilace:=true;
		 wordadr:=wordadr div 2;
                 dec(calclines);
	       end;
	     end;
    __video7:begin
	       if (rgs.seqregs.x[$E0] and 1)<>0 then ilace:=true;
               if (rgs.attregs[$10] and $40)>0 then
               begin
                 pixwid:=4;
                 wordadr:=8;
                 hfreqfact:=2;
               end;
               if (rgs.seqregs.x[$C8] and $10)>0 then
               begin
                 force256:=true;
                 wordadr:=8;
               end;
	     end;
    __Weitek:begin
               if (rgs.grcregs.x[$C] and 4)>0 then
               begin
                 wordadr:=8;
                 force256:=true;
               end;
             end;
 __xbe,__xga:begin
	       calchtot  :=rgs.xxregs.x[$11]*256+rgs.xxregs.x[$10]+1;
	       calcpixels:=rgs.xxregs.x[$13]*256+rgs.xxregs.x[$12]+1;
	       calchblks :=rgs.xxregs.x[$15]*256+rgs.xxregs.x[$14]+1;
	       calchblke :=rgs.xxregs.x[$17]*256+rgs.xxregs.x[$16]+1;
	       calchrtrs :=rgs.xxregs.x[$19]*256+rgs.xxregs.x[$18]+1;
	       calchrtre :=rgs.xxregs.x[$1B]*256+rgs.xxregs.x[$1A]+1;
	       pixwid:=8;
	       calclines :=rgs.xxregs.x[$23]*256+rgs.xxregs.x[$22]+1;
	       calcvtot  :=rgs.xxregs.x[$21]*256+rgs.xxregs.x[$20]+1;
	       calcvblks :=rgs.xxregs.x[$25]*256+rgs.xxregs.x[$24]+1;
	       calcvblke :=rgs.xxregs.x[$27]*256+rgs.xxregs.x[$26]+1;
	       calcvrtrs :=rgs.xxregs.x[$29]*256+rgs.xxregs.x[$28]+1;
	       calcvrtre :=rgs.xxregs.x[$2B]*256+rgs.xxregs.x[$2A]+1;  {Hm!!}
	       wid :=rgs.xxregs.x[$44]*256+rgs.xxregs.x[$43];
	       wordadr:=8;
               case rgs.xxregs.x[$51] and 7 of
                 2:calcmmode:=_pk4;
                 3:calcmmode:=_p8;
                 4:calcmmode:=_p16;  {or _p15}
                 5:calcmmode:=_p24;
               end;
               if (rgs.xxregs.x[$50] and 8)>0 then isilace:=true;
	     end;
    end;

    if (cv.flags and FLG_StdVGA)>0 then
    begin
      calchblke:=(calchblks and (not hblkmask))+calchblke;
      if calchblke<=calchblks then inc(calchblke,hblkmask+1);
      if calchblke>calchtot then calchblke:=calchtot+(hblkmask and calchblke);
      calchrtre:=(calchrtrs and (not hrtrmask))+calchrtre;
      if calchrtre<=calchrtrs then inc(calchrtre,hrtrmask+1);
      if calchrtre>calchtot then calchrtre:=calchtot+(hrtrmask and calchrtre);
      calcvblke:=(calcvblks and (not vblkmask))+calcvblke;
      if calcvblke<=calcvblks then inc(calcvblke,vblkmask+1);
      calcvrtre:=(calcvrtrs and (not vrtrmask))+calcvrtre;
      if calcvrtre<=calcvrtrs then inc(calcvrtre,vrtrmask+1);

      if (rgs.crtcregs.x[$17] and 4)>0 then
      begin
        calclines:=calclines*2;
        calcvtot:=calcvtot*2;
      end;
      if ilace then calclines:=calclines*2;
      if isilace then ilace:=true;
      if (rgs.attregs[$10] and 1)=0 then  {Text}
      begin
        calclines:=calclines div ((rgs.crtcregs.x[9] and $1F)+1);
        if (rgs.attregs[$10] and 2)=0 then calcmmode:=_TEXT
				      else calcmmode:=_TXT4;
        pixwid:=charwid;
      end
      else begin
        if ((rgs.crtcregs.x[$17] and 1)=0)
          and ((rgs.attregs[$10] and 64)=0) then {CGA}
        begin
	  if (rgs.crtcregs.x[$17] and $40)>0 then calcmmode:=_cga1
					     else calcmmode:=_cga2;
	  extlinfact:=extlinfact shr 1;
        end
        else if ((rgs.attregs[$10] and 64)=0) and ((rgs.grcregs.x[5] and 64)=0)
          and not force256 then  {16 color}
        begin
	  if ((rgs.attregs[$10] and 2)>0) then calcmmode:=_pl1
	  else if (rgs.attregs[$12]=5) then
	  begin
	    calcmmode:=_pl2;
	    pixwid:=pixwid*2;
	  end
	  else if (rgs.seqregs.x[4] and 8)>0 then calcmmode:=_pk4
					     else calcmmode:=_pl4;
        end
        else calcmmode:=_p8;
      end;
    end;


    if (calcmmode>=_PK4) and (cv.dactype>_dac8) then
    begin
      x:=rgs.dacregs[6]{getdaccomm};

      case cv.dactype of
   _dac15:if x>127 then calcmmode:=_p15;
   _dac16:case (x and $c0) of
           $80:calcmmode:=_p15;
           $c0:calcmmode:=_p16;
          end;
 _dacALG1101:
          if (cv.chip=__ALG) and ((rgs.crtcregs.x[$19] and 16)>0) then
            calcmmode:=_p16;     {Only used on ALG chips ??}
 _dacMU1880:
          begin
            outp($3C8,0);
            for m:=1 to 4 do x:=inp($3C6);
              while x<>$8e do x:=inp($3C6);
              x:=inp($3C6);
              rgs.stdregs[$3c1]:=x;
              case x of
                $A6:calcmmode:=_p16;
                $A0:calcmmode:=_p15;
                $9E:calcmmode:=_p24b;
              end;
          end;
 _dacICS5301,_dacMU4910,_dacMU9910,_dacATT490,_dacATT491,_dacATT492,
 _dacATT493,_dacCH8391:
          case (x and $E0) of
         $80,$A0:calcmmode:=_p15;
             $C0:calcmmode:=_p16;
             $E0:calcmmode:=_p24;
          end;
 _dacATT498,_dacATT1498,_dacATT2498:
          case x shr 4 of
            1:begin
                calcmmode:=_p15;
                pixwid:=pixwid*2;
                vclkdiv:=vclkdiv div 2;
              end;
            2:begin
                pixwid:=pixwid*2;
                vclkdiv:=vclkdiv div 2;
              end;
            3:begin
                calcmmode:=_p16;
                pixwid:=pixwid*2;
                vclkdiv:=vclkdiv div 2;
              end;
            5:begin
                calcmmode:=_p32;
                pixwid:=pixwid*2;
                vclkdiv:=vclkdiv div 2;
              end;
            6:calcmmode:=_p16;
           10:calcmmode:=_p15;
          end;
 _dacALG1201,_dacALG1301:
          case (x and $E0) of
            $A0:calcmmode:=_p15;
            $C0:calcmmode:=_p16;
            $E0:calcmmode:=_p24;
          end;
 _dacADAC1:
          case (x and $C7) of
            $C1:calcmmode:=_p16;
            $C5:calcmmode:=_p24;
            $80:calcmmode:=_p15;
          end;
 _dacSC15021,_dacSC15025:
          begin
            case (x and $E1) of
              $41:calcmmode:=_p32b;
              $40:calcmmode:=_p32;
              $61:calcmmode:=_p24b;
              $60:calcmmode:=_p24;
  $80,$81,$A0,$A1:calcmmode:=_p15;
          $C0,$E0:calcmmode:=_p16;
            end;
            if rgs.dacinxd.x[$10]>0 then
            begin
              pixwid:=pixwid*2;
              vclkdiv:=vclkdiv div 2;
            end;
          end;
_dacTR8001:case x and $E0 of
             $A0:calcmmode:=_p15;
             $E0:calcmmode:=_p16;
             $C0:calcmmode:=_p24;
           end;
_dacUMC188:case (x and $D0) of
             $80:calcmmode:=_p15;
             $C0:calcmmode:=_p16;
 $10,$50,$90,$D0:calcmmode:=_p24;
           end;
  _dacSTG1700,_dacSTG1702,_dacSTG1703:
           if (x and 8)>0 then
             case rgs.dacinxd.x[3] of
               1:begin
                   calcmmode:=_P15;
                   pixwid:=pixwid*2;
                 end;
               2:begin
                   calcmmode:=_p15;
                   pixwid:=pixwid*2;
                   vclkdiv:=vclkdiv div 2;
                 end;
               3:begin
                   calcmmode:=_p16;
                   pixwid:=pixwid*2;
                   vclkdiv:=vclkdiv div 2;
                 end;
               4:begin
                   calcmmode:=_P32;
                   pixwid:=pixwid*2;
                   vclkdiv:=vclkdiv div 2;
                 end;
               5:begin  {P8 - two pixels/clock}
                   calcmmode:=_P8;
                   vclkdiv:=vclkdiv div 2;
                 end;
               6:begin
                   calcmmode:=_P16;
                   pixwid:=pixwid*2;
                 end;
               9:begin
                   calcmmode:=_p24;
                   pixwid:=pixwid*2;
                   vclkdiv:=vclkdiv div 2;
                 end;
             end
             else
               case x and $E0 of
                 $A0:calcmmode:=_p15;
                 $C0:calcmmode:=_p16;
                 $E0:calcmmode:=_p24;
               end;
_dacCH8398:case rgs.dacregs[dacHIcmd] shr 4 of
             6:calcmmode:=_p16;
             3:begin
                 calcmmode:=_p16;
                 pixwid:=pixwid*2;
                 vclkdiv:=vclkdiv div 2;
               end;
             7:calcmmode:=_p24;  {24bpp = 2pixels/3VCLKs}
            $B:begin  {24bpp = 2pixels/3VCLKs}
                 calcmmode:=_p24;
                 pixwid:=pixwid*2;
                 vclkdiv:=vclkdiv div 2;
               end;
            $C:calcmmode:=_p15;
             1:begin  {15bit 1VCLK/pixel}
                 calcmmode:=_p15;
                 pixwid:=pixwid*2;
                 vclkdiv:=vclkdiv div 2;
               end;
           end;
 _dacS3_708,_dacS3_716:
           case rgs.dacregs[dacHIcmd] and $F0 of
               (*  $10:begin  {2 8bpp pixels/VCLK}
                       vclkdiv:=vclkdiv div 2;
                     end; *)
             $20:calcmmode:=_p15;
             $30:begin
                   calcmmode:=_p15;
                   vclkdiv:=vclkdiv div 2;
                 end;
             $50:begin
                   calcmmode:=_p16;
                   vclkdiv:=vclkdiv div 2;
                 end;
             $60:calcmmode:=_p16;
             $70:begin  {32bpp = 2 VCLKs}
                   calcmmode:=_p32;
                   vclkdiv:=vclkdiv div 2;
                 end;
             $E0:calcmmode:=_p24;
           end;
 _dacBt481,_dacBt482:
           case rgs.dacregs[6] and $F0 of
             $A0:calcmmode:=_P15;
             $E0:calcmmode:=_P16;
             $F0:calcmmode:=_P24;
           end;
 _dacBt484,_dacBt485,_dacATT504,_dacATT505:
           if (rgs.dacregs[9] and $20)>0 then
           begin
             case rgs.dacregs[8] and $78 of
               $10:calcmmode:=_p32;
               $30:calcmmode:=_p15;
               $38:calcmmode:=_p16;
               $60:calcmmode:=_pk4;
             end;
             pixwid:=pixwid*4;
             if (cv.dactype=_dacBt485) or (cv.dactype=_dacATT505) then
               if (rgs.dacregs[16] and 8)>0 then vclkdiv:=vclkdiv div 2; {clk*2}
           end;
 _dacTVP3010,_dacTVP3020,_dacTVP3025,_dacTVP3026:
           begin
             case rgs.dacinxd.x[$18] and $CF of
               $C:calcmmode:=_P15;
               $D:calcmmode:=_P16;
             6,$E:calcmmode:=_P32;
             end;
             if (rgs.dacinxd.x[$1A] and $10)>0 then
             begin
               vclkdiv:=vclkdiv div 2;
               pixwid:=pixwid*2;
             end;
             SerialDAC:=false;
           end;
 _dacTLC34075:
           begin    {TLC34075}
             if (rgs.dacregs[9]=1) then {On the ATI Mach32 the VCLK is
                                         looped back to CLK1, really should
                                         test explicitly for such loops }
               case (rgs.dacregs[10] shr 3) and 7 of
                 1:vclkdiv:=vclkdiv*2;
                 2:vclkdiv:=vclkdiv*4;
                 3:vclkdiv:=vclkdiv*8;
                 4:vclkdiv:=vclkdiv*16;
                 5:vclkdiv:=vclkdiv*32;
               end;
             SerialDAC:=false;
           end;
   _dacInt:case cv.chip of
             __chips:case rdinx(cv.IOadr,6) and $C of
                       0:if (cv.Version=CT_64300) and
                           ((rgs.xxregs.x[$28] and $10)=0) then calcmmode:=_pk4;
                       4:calcmmode:=_p15;
                       8:calcmmode:=_p24;
                      $C:calcmmode:=_p16;
                     end;
             __cir54:begin
                       case x and $CF of
                     $80,$C0:calcmmode:=_p15;
                         $C1:calcmmode:=_p16;
                         $C5:if (cv.Version>=CL_GD5430) and
                               ((rgs.seqregs.x[7] and 8)>0) then calcmmode:=_p32
                             else calcmmode:=_p24;
                         $C8:;  {8bit Grey scale}
                         $C9:;  {3-3-2 RGB}
                       end;
                       SerialDAC:=false;
                     end;
                __WD:case rdinx(SEQ,$26) and $C of
                       4:calcmmode:=_P16;
                     {  8:calcmmode:=_p16b;  }
                      $C:calcmmode:=_P15;
                     end;
                __S3:case rgs.crtcregs.x[$67] shr 4 of
                      { 1:vclkdiv:=vclkdiv div 2;  {2px/VCLK}
                       3:begin
                           calcmmode:=_P15;
                           vclkdiv:=vclkdiv div 2;  {1px/VCLK}
                         end;
                       5:begin
                           calcmmode:=_P16;
                           vclkdiv:=vclkdiv div 2;  {1px/VCLK}
                         end;
                       7:begin
                           calcmmode:=_P32;
                           vclkdiv:=vclkdiv div 2;  {1px/2VCLK}
                         end;
                      13:begin
                           calcmmode:=_P32;    {1px/VCLK}
                           SerialDAC:=false;
                         end;
                     end;
               __SiS:begin
                       case rgs.seqregs.x[6] and $1C of
                          4:calcmmode:=_P15;
                          8:calcmmode:=_P16;
                         16:calcmmode:=_P24;
                       end;
                       SerialDAC:=false;
                     end;
              __Trid:if cv.version<TR_GUI9440 then
                       case rgs.dacregs[6] shr 5 of
                         5:calcmmode:=_p15;
                         7:calcmmode:=_p16;
                         6:calcmmode:=_p24;
                       end
                     else begin
                       case rgs.dacregs[6] shr 4 of
                         1:calcmmode:=_p15;
                         3:calcmmode:=_p16;
                        13:begin
                             calcmmode:=_p24;
                             SerialDAC:=false;
                             vclkdiv:=vclkdiv*3;
                           end;
                       end;
                     end;
           end;
      end;
      if SerialDAC then
	case calcmmode of               {Adjust for HiColor}
      _p15,_p16:begin
                  pixwid:=pixwid div 2;
                  vclkdiv:=vclkdiv*2;
                end;
     _P24,_P24b:begin
                  calcpixels:=calcpixels div 3;
                  calchtot:=calchtot div 3;
                  calchblks:=calchblks div 3;
                  calchblke:=calchblke div 3;
                  calchrtrs:=calchrtrs div 3;
                  calchrtre:=calchrtre div 3;
                  vclkdiv:=vclkdiv*3;
                end;
           _p32:begin
                  pixwid:=pixwid div 4;
                  vclkdiv:=vclkdiv*4;
                end;
	end;
    end;
  end;
  if calcmmode>=_herc then calcpixels:=calcpixels*pixwid;
  calcbytes:=wid*wordadr;

  vclk:=GetClockFreq;


  calchtot :=calchtot*pixwid;
  calchblks:=calchblks*pixwid;
  calchblke:=calchblke*pixwid;
  calchrtrs:=calchrtrs*pixwid;
  calchrtre:=calchrtre*pixwid;
  vclk:=(vclk*12) div vclkdiv;
  if vclk>0 then
  begin
    hclk:=(vclk*1000) div (calchtot*hfreqfact);
    fclk:=(hclk*1000) div calcvtot;
  end;
  if extlinfact>0 then calclines:=calclines div extlinfact;
  BWlow :=hclk;
  case memmode of
 _PL4,_PK4,_PK4a:BWlow:=BWlow div 2;
       _P15,_P16:BWlow:=BWlow*2;
      _P24,_P24b:BWlow:=BWlow*3;
     _P32.._P32d:BWlow:=BWlow*4;
  end;

  BWhigh:=(BWlow*calchtot) div 1000;
  BWlow :=(BWlow*calcpixels) div 1000;

  if memmode<=_TXT4 then
  begin
    BWlow :=BWlow*3;
    BWhigh:=(BWhigh*3) div 8;
  end;

  if VESAcheat then cv.chip:=__VESA;
  rgs.bytes :=calcbytes;
  rgs.pixels:=calcpixels;
  rgs.lins  :=calclines;
  rgs.mmode :=calcmmode;
  rgs.chip  :=cv.chip;
end;


procedure AnalyseMode;
begin
  DumpRegisters;
  CalcRegisters;
end;

procedure wrregs(var rg:regblk);
var x:word;
begin
  write(hex4(rg.base)+':');
  for x:=0 to rg.nbr do
  begin
    if (x mod 25=0) and (x>0) then
      write('('+hex2(x)+'):');

    write(' '+hex2(rg.x[x]));
  end;
  writeln;
end;

function dumpVGAregs:word;
var x,y:word;
begin
  settextmode;  {Set 43/50 line text mode}
  writeln('Mode: '+hex2(rgs.mode)+'h Pixels: '+istr(rgs.pixels)+' lines: '+istr(rgs.lins)
       +' bytes: '+istr(rgs.bytes)+' colors: '+istr(modecols[rgs.mmode]));
  writeln;
  if oldreg then writeln('SEQ (OLD): 0Dh: ',hex2(rgs.tridold0d)
				  ,' 0Eh: ',hex2(rgs.tridold0e));

  for x:=$3C0 to $3CF do write(' '+hex2(rgs.stdregs[x]));
  writeln;
  for x:=$3D0 to $3DF do write(' '+hex2(rgs.stdregs[x]));
  writeln;
  write('03C0:');
  for x:=0 to 31 do
  begin
    if x=25 then write('(19):');
    write(' '+hex2(rgs.attregs[x]));
  end;
  writeln;
  wrregs(rgs.seqregs);
  wrregs(rgs.grcregs);
  wrregs(rgs.crtcregs);
  if rgs.xxregs.base<>0 then
  begin
    if (rgs.xxregs.base and $ff8f)=$210A then
    begin
      write(hex4(rgs.xxregs.base and $fff0)+':');
      for x:=0 to 15 do write(' '+hex2(rgs.xgaregs[x]));
      writeln;
    end;
    wrregs(rgs.xxregs);
  end;
  writeln;
  write('DAC: ');
  for x:=0 to 16 do
    write(' '+hex2(rgs.dacregs[x]));
  writeln;
  if rgs.dacinxd.base<>0 then wrregs(rgs.dacinxd);
  dumpVGAregs:=getkey;
end;

function FormatRgs(var b:byte):word;   {Format registers for dump}
type
  barr=array[1..2000] of byte;
var
  blk:^barr;
  bts,x:word;

procedure appb(b:byte);
begin
  inc(bts);
  blk^[bts]:=b;
end;

procedure appw(w:word);
begin
  appb(lo(w));
  appb(hi(w));
end;

procedure apprgs(var r:regblk);
var x:word;
begin
  appw(1);
  appw(r.base);
  appb(0);
  appb(r.nbr);
  for x:=0 to r.nbr do appb(r.x[x]);
end;

begin
  blk:=@b;
  bts:=0;
  appw(1);
  appw($3C0);
  appb(0);
  appb(31);
  for x:=0 to 31 do appb(rgs.attregs[x]);
  apprgs(rgs.seqregs);
  apprgs(rgs.grcregs);
  apprgs(rgs.crtcregs);
  if rgs.xxregs.base<>0 then apprgs(rgs.xxregs);
  if oldreg then
  begin
    appw($FF);
    appw(0);
    appb(rgs.tridold0d);
    appw($FF);
    appw(1);
    appb(rgs.tridold0e);
  end;
  for x:=0 to 16 do {DAC registers 0-10h}
  begin
    appw($FF);
    appw($F000+x);
    appb(rgs.dacregs[x]);
  end;
  if rgs.dacinxd.nbr>0 then apprgs(rgs.dacinxd);
  if (rgs.xxregs.base and $FF8F)=$210A then
  begin
    appw(16);
    appw(rgs.xxregs.base-$A);
    for x:=0 to 15 do appb(rgs.xgaregs[x]);
  end;
  appw($3C2);
  appb(rgs.stdregs[$3C2]);
  appw(4);
  appw($3CA);
  for x:=$3CA to $3CD do appb(rgs.stdregs[x]);
  appw(8);
  appw(crtc+4);
  for x:=$3D8 to $3DF do appb(rgs.stdregs[x]);
  appw(0);
  FormatRgs:=bts;
end;


procedure dumpVGAregfile;
var
  f:file of regtype;
begin
  assign(f,'register.vga');
  {$i-}
  reset(f);
  {$i+}
  if ioresult=0 then seek(f,filesize(f)) else rewrite(f);
  write(f,rgs);
  close(f);
end;





function tstrg(pt,msk:word):boolean;       {Returns true if the bits in MSK
                                            of register PT are read/writable}
var old,nw1,nw2:word;
begin
  old:=inp(pt);
  outp(pt,old and not msk);
  nw1:=inp(pt) and msk;
  outp(pt,old or msk);
  nw2:=inp(pt) and msk;
  outp(pt,old);
  tstrg:=(nw1=0) and (nw2=msk);
end;

function testinx2(pt,rg,msk:word):boolean;   {Returns true if the bits in MSK
                                              of register PT index RG are
                                              read/writable}
var old,nw1,nw2:word;
begin
  old:=rdinx(pt,rg);
  wrinx(pt,rg,old and not msk);
  nw1:=rdinx(pt,rg) and msk;
  wrinx(pt,rg,old or msk);
  nw2:=rdinx(pt,rg) and msk;
  wrinx(pt,rg,old);
  testinx2:=(nw1=0) and (nw2=msk);
end;

function testinx(pt,rg:word):boolean;     {Returns true if all bits of
                                           register PT index RG are
                                           read/writable.}
var old,nw1,nw2:word;
begin
  testinx:=testinx2(pt,rg,$ff);
end;

procedure UNK(vers,code:word);
begin
  cv.version:=vers;
  cv.subvers:=code;
end;

procedure SetVersion(vers:word;nam:string);
begin
  cv.Version:=vers;
  cv.name:=nam;
end;


procedure SetDAC(typ:word;Name:string);
begin
  cv.dactype:=typ;
  cv.dacname:=name;
end;


procedure addvideo;
var nam,s:string;
    x,nr,err:word;
    ok:boolean;
begin
  nam:='';
  if force_version<>0 then cv.version:=force_version;
  if cv.version<>0 then
  begin
    for x:=1 to NBRCHIPS do
    begin
      if cv.version=CHIPSLIST[x].nbr then
      begin
        nam:=CHIPSLIST[x].nam;
        if nam[length(nam)]='(' then nam:=nam+hex4(cv.subvers)+')';
      end;
    end;
  end;
  if cv.Version=ET_4000 then
    case cv.Subvers of
      TS_SpeedStar:nam:=nam+' (SpeedStar)';
      TS_Genoa7900:nam:=nam+' (Genoa7900)';
    end;
  cv.flags:=cv.flags or FLG_ExtDAC;    {Allow Ext DAC addressing}
  if (cv.flags and FLG_StdVGA)>0 then ok:=setmode($12,false);  {Set std mode}
  if cv.dactype=_dac0 then testdac;
  if (cv.chip=__ALG) and (cv.dactype=_dac8) then SetDAC(_dacALG1101,'ALG1101');

  if (DACflags and DFL_CmdReg)>0 then   {Must have CMD register}
  begin
    x:=inp(SetDACpage(dacHIcmd));      {test if RS2/3 works}
    clearDACpage;
    if x<>getdaccomm then cv.flags:=cv.flags and (not FLG_ExtDAC);
  end;

  if cv.dactype=_dacInt then cv.dacname:='Internal';
  if force_mm<>0 then cv.mm:=force_mm;
  fillchar(cv.clks,sizeof(cv.clks),0);
  if (cv.chip<>__vesa) and clocktest then findclocks;
  inc(vids);
  vid[vids]:=cv;
  vid[vids].name :=nam+' '+cv.name;
  vid[vids].sname:=chipnam[cv.chip];
  SetTextMode;    {Reset any special bits}
end;





   (*  Tests for various adapters  *)


procedure _Acer;
var old:word;
begin
  old:=rdinx(GRC,$FF);
  clrinx(GRC,$FF,7);
  if not testinx2(GRC,$10,$9F) then
  begin
    clrinx(GRC,$FF,7);
    if testinx2(GRC,$10,$9F) then
    begin
      cv.chip:=__Acer;
      case rdinx(GRC,$E) and $C of
        0:cv.mm:=256;
        1:cv.mm:=512;
        2:cv.mm:=1024;
        3:cv.mm:=2048;
      end;
      addvideo;
    end;
  end;
  wrinx(GRC,$FF,old);
end;

procedure _ahead;
var old:word;
begin
  old:=rdinx(GRC,$F);
  wrinx(GRC,$F,0);
  if not testinx2(GRC,$C,$FB) then
  begin
    wrinx(GRC,$F,$20);
    if testinx2(GRC,$C,$FB) then
    begin
      cv.chip:=__ahead;
      case rdinx(GRC,$F) and 15 of
	0:cv.Version:=AH_A;
	1:begin
	    cv.Version:=AH_B;
	    cv.features:=ft_rwbank;
            cv.clktype:=clk_ext4;
	  end;
      end;
      case rdinx(GRC,$1F) and 3 of
	0:cv.mm:=256;
	1:cv.mm:=512;
	2:;
	3:cv.mm:=1024;
      end;
      addvideo;
    end;
  end;
  wrinx(GRC,$F,old);
end;

procedure _ALG;
var old:integer;
begin
  old:=rdinx(crtc,$1A);
  clrinx(crtc,$1A,$10);
  if not testinx2(crtc,$19,$CF) then
  begin
    setinx(crtc,$1A,$10);
    if testinx2(crtc,$19,$CF) and testinx2(crtc,$1A,$3F) then
    begin
      cv.chip:=__ALG;
      cv.subvers:=rdinx(crtc,$1A);
      case cv.subvers shr 6 of
        3:begin
            cv.Version:=ALG_2101;
            {SetDAC(_dacalg,'ALG1101');}
           end;
        2:if (rdinx(crtc,$1B) and 4)>0 then cv.Version:=ALG_2228
                                       else cv.Version:=ALG_2301;
           {The 2228/2301/230x should probably be ID'd from the PCI ID ?}
        1:cv.version:=ALG_2201;
      else cv.Version:=ALG_Unknown;
      end;
      cv.clktype:=clk_ext4;
      cv.features:=ft_rwbank+ft_blit+ft_cursor+ft_line;
      if cv.version>ALG_2101 then cv.features:=ft_rwbank;  {CBL don't work yet!}
      case rdinx(crtc,$1E) and 3 of
	0:cv.mm:=256;
	1:cv.mm:=512;
	2:cv.mm:=1024;
	3:cv.mm:=2048;
      end;
      addvideo;
    end;
  end;
  wrinx(crtc,$1A,old);
end;

procedure _Alliance;
begin
  if (rdinx(SEQ,$11)=$41) and (rdinx(SEQ,$12)=$53) then
  begin
    cv.chip:=__Alli;
    cv.version:=ALi_3210;

    if mem[SegA000:$D8]=0 then;
    outpw(SEQ,$1210);
    setinx(SEQ,$1C,8);
    modinx(SEQ,$1B,7,1);
    cv.mm:=mem[SegA000:$F0]*64;   {Video Memory}
    clrinx(SEQ,$1B,7);
    clrinx(SEQ,$1C,8);
    addvideo;
  end;
end;

procedure _ARK;
var old:word;
begin
  old:=rdinx(SEQ,$1D);
  wrinx(SEQ,$1D,0);    {Lock the ext registers}
  if not (testinx(SEQ,$11) and testinx(SEQ,$12)) then
  begin
    wrinx(SEQ,$1D,old);
    if testinx(SEQ,$11) and testinx(SEQ,$12) then
    begin
      cv.chip:=__ARK;
      cv.SubVers:=rdinx(crtc,$50);
      case cv.SubVers and $F8 of
        $88:cv.Version:=ARK_1000VL;
        $90:cv.Version:=ARK_1000PV;
        $98:cv.Version:=ARK_2000PV;
      else cv.version:=ARK_Unknown;
      end;
      cv.clktype:=clk_ext4;
      cv.features:=ft_rwbank+ft_cursor;
      if cv.Version=ARK_2000PV then
        case rdinx(SEQ,$10) shr 6 of
          0:cv.mm:=1024;
          1:cv.mm:=2048;
          2:cv.mm:=4096;
          3:cv.mm:=8192;
        end
      else
        if (rdinx(SEQ,$10) and $40)>0 then cv.mm:=2048
                                      else cv.mm:=1024;
      addvideo;
    end;
  end;
  wrinx(SEQ,$1D,old);
end;


procedure _ati;
var w,mall,mvga:word;
  l:longint;
begin
  if getbios($31,9)='761295520' then
  begin
    case memw[biosseg:$40] of
     $3133:begin
	     cv.IOadr:={memw[biosseg:$10]}$1CE;
	     w:=rdinx(cv.IOadr,$BB);
	     case w and 15 of
	       0:_crt:='EGA';
	       1:_crt:='Analog Monochrome';
	       2:_crt:='Monochrome';
	       3:_crt:='Analog Color';
	       4:_crt:='CGA';
	       6:_crt:='';
	       7:_crt:='IBM 8514/A';
	     else _crt:='Multisync';
	     end;
	     cv.chip:=__ati;
	     cv.SubVers:=mem[biosseg:$43];
	     case cv.SubVers of
	      $31:cv.Version:=ATI_18800;
	      $32:cv.Version:=ATI_18800_1;
	      $33:cv.Version:=ATI_28800_2;
	      $34:cv.Version:=ATI_28800_4;
          $35,$36:if (rdinx(cv.IOadr,$AA) and 15)=6 then
                       cv.Version:=ATI_28800_6
                  else cv.Version:=ATI_28800_5;
              $20:begin
		    cv.SubVers:=inpw($6EEC);
                    case cv.Subvers of
                      $57:cv.Version:=ATI_M64_CX;
                      $D7:cv.Version:=ATI_M64_GX;
                    else  cv.Version:=ATI_M64_Unk;
                    end;
                    cv.Xseg:=$BFC0;  {Memory mapped regs at BFC00h}
                    if (inpw($72EC) and $E00)=$A00 then
                      SetDAC(_dacATI68860,'ATI 68860');  {Hack!}
                  end;
         $61..$63:begin  {Mach32}
		    cv.SubVers:=inpw($FAEE);
		    case cv.SubVers and $3FF of
		     $2F7:cv.Version:=ATI_GUP_6;
		     $177:cv.Version:=ATI_GUP_LX;
		     $017:cv.Version:=ATI_GUP_AX;
			0:cv.Version:=ATI_GUP_3;
                    else  cv.Version:=ATI_M32_Unk;
		    end;
		  end;
	     else cv.Version:=ATI_Unknown;
	     end;
             if cv.Version=ATI_18800 then cv.clktype:=clk_ext3
                                     else cv.clktype:=clk_ext4;
	     if cv.Version>=ATI_18800_1 then cv.features:=ft_rwbank;
	     case cv.Version of
	   ATI_18800,ATI_18800_1:
		       if (rdinx(cv.IOadr,$BB) and $20)<>0 then cv.mm:=512;
	   ATI_28800_2:if (rdinx(cv.IOadr,$B0) and $10)<>0 then cv.mm:=512;
	   ATI_28800_4,ATI_28800_5,ATI_28800_6:
		       case rdinx(cv.IOadr,$B0) and $18 of
			   0:cv.mm:=256;
			 $10:cv.mm:=512;
		       8,$18:cv.mm:=1024;
		       end;
	   ATI_GUP_3..ATI_GUP_LX:
                       begin
		         case inp($36EE) and $C of
			   0:mall:=512;
			   4:mall:=1024;
			   8:mall:=2048;
			  12:mall:=4096;
		         end;
                         mvga:=mall;
                         if (inp($42EE) and $10)>0 then   {Split VGA/Mach mem}
                         begin
                           mvga:=(inp($42EE) and $F)*256;
                           if mvga>mall then mvga:=mall;
                         end;
                         cv.mm:=mvga;
                       end;
            ATI_M64_GX:begin
                         l:=inpl($52EC);
                         case l and 7 of
                           0:mall:=512;
                           1:mall:=1024;
                           2:mall:=2048;
                           3:mall:=4096;
                           4:mall:=6144;
                           5:mall:=8192;
                         end;
                         mvga:=mall;
                         if (l and $40000)>0 then
                         begin
                           case (l shr 16) and 3 of
                             0:mvga:=0;
                             1:mvga:=256;
                             2:mvga:=512;
                             3:mvga:=1024;
                           end;
                           if mvga>mall then mvga:=mall;
                         end;
                         cv.mm:=mvga;
                         if cv.mm>1024 then cv.mm:=1024;
                       end;
	     end;
	   end;
     $3233:begin
	     cv.Version:=ATI_EGA;
	     video:='EGA';
	     cv.chip:=__ega;
	   end;
    end;
    addvideo;
    if cv.version>=ATI_GUP_3 then  {Now add the VGA part}
    begin
      if cv.Version>=ATI_M64_GX then cv.chip:=__Mach64
                                else cv.chip:=__Mach32;
      cv.flags:=cv.flags and (not FLG_StdVGA);
      cv.mm:=mall;
      if mvga<mall then cv.mm:=mall-mvga;
      cv.features:=cv.features or ft_cursor or ft_line or ft_blit;
                    if (inpw($72EC) and $E00)=$A00 then
                      SetDAC(_dacATI68860,'ATI 68860');  {Hack!}
      addvideo;
    end;
  end;
end;

procedure _chipstech;
var prt,old,x:word;
begin
  vio($5F00);
  if rp.al=$5F then
  begin
    cv.subvers:=rp.bl;
    case cv.SubVers shr 4 of
      0:cv.Version:=CT_451;
      1:cv.Version:=CT_452;
      2:cv.Version:=CT_455;
      3:cv.Version:=CT_453;
      4:cv.Version:=CT_450;
      5:cv.Version:=CT_456;
      6:cv.Version:=CT_457;
      7:cv.Version:=CT_65520;
      8:cv.Version:=CT_65530;
      9:cv.Version:=CT_65510;
     10:cv.Version:=CT_64200;
     11:if cv.subvers>=$B8 then cv.Version:=CT_64310
                           else cv.Version:=CT_64300;
     12:cv.Version:=CT_65535;
     13:if cv.subvers>=$D8 then cv.Version:=CT_65545
                           else cv.Version:=CT_65540;
    else cv.Version:=CT_Unknown;
    end;
    cv.clktype:=clk_ext3;
    if cv.version<CT_450 then
    begin
      prt:=$46E8;     {Should be $94 for MCA systems}
      outp(prt,$1E);    {Setup mode}

      x:=inp($103);
      outp($103,x or $80);  {Enable extensions}
      outp(prt,$E);
      if (x and $40)=0 then cv.IOadr:=$3D6 else cv.IOadr:=$3B6;
    end
    else begin
      cv.IOadr:=$3D6;
      if cv.version=CT_64300 then
      begin
        cv.clktype:=clk_internal;
        setDAC(_dacInt,'CT 24bit DAC');
      end
      else setDAC(_dacInt,'CT 15/16bit DAC');
    end;
    cv.SubVers:=rdinx(cv.IOadr,0);
    cv.chip:=__chips;
    if cv.version=CT_452 then cv.features:=ft_cursor;
    case rdinx(cv.IOadr,4) and 3 of
       1:cv.mm:=512;
     2,3:begin
           cv.mm:=1024;
           if (cv.Version>=CT_64300) and ((rdinx(cv.IOadr,$F) and 3)=3) then
             cv.mm:=2048
         end;
    end;
    addvideo;
  end;
end;

procedure _cirrus;
var old,old6:word;
begin
  old6:=rdinx(SEQ,6);
  old:=rdinx(crtc,$C);
  outp(crtc+1,0);
  cv.SubVers:=rdinx(crtc,$1F);
  wrinx(SEQ,6,lo(cv.Subvers shr 4) or lo(cv.Subvers shl 4));
                         {The SubVers value is rotated by 4}
  if inp(SEQ+1)=0 then
  begin
    outp($3c5,cv.SubVers);
    if inp($3c5)=1 then
    begin
      case cv.SubVers of
	$EC:cv.Version:=CL_GD5x0;
	$CA:cv.Version:=CL_GD6x0;
	$EA:cv.Version:=CL_V7_OEM;
      else cv.Version:=CL_old_unk;
      end;
      cv.chip:=__cirrus;
      cv.features:=ft_cursor;
      addvideo;
    end;
  end;
  wrinx(crtc,$C,old);
  wrinx(SEQ,6,old6);
end;


procedure _cirrus54;
var x,old:word;
begin
  old:=rdinx(SEQ,6);
  wrinx(SEQ,6,0);
  if (rdinx(SEQ,6)=$F) then
  begin
    wrinx(SEQ,6,$12);
    if (rdinx(SEQ,6)=$12) and testinx2(SEQ,$1E,$3F) {and testinx2(crtc,$1B,$ff)} then
    begin
      case rdinx(SEQ,$A) and $18 of      {Alternate method:}
	0:cv.mm:=256;                    { case rdinx(SEQ,$F) and $18}
	8:cv.mm:=512;                    {   $10: cv.mm:=1024; }
       16:cv.mm:=1024;                   {   $18: cv.mm:=2048;  May not work}
       24:cv.mm:=2048;                   { else cv.mm:=512}
      end;
      cv.SubVers:=rdinx(crtc,$27);
      if testinx(GRC,9) then
      begin
        cv.features:=ft_cursor;
	case cv.SubVers of
            $18:cv.Version:=CL_AVGA2;
            $88:cv.Version:=CL_GD5402;
            $89:cv.Version:=CL_GD5402r1;
            $8A:cv.Version:=CL_GD5420;
            $8B:cv.Version:=CL_GD5420r1;
       $8C..$8F:cv.Version:=CL_GD5422;
       $90..$93:cv.Version:=CL_GD5426;
       $94..$97:cv.Version:=CL_GD5424;
       $98..$9B:cv.Version:=CL_GD5428;
       $9C..$9F:cv.Version:=CL_GD5429;   {Might not get here ??}
       $A0..$A3:cv.Version:=CL_GD5430;
  {     $A4..$A7:cv.Version:=CL_GD543x;  Probably does not exist}
       $A8..$AB:cv.version:=CL_GD5434;
       $2C..$2F:cv.version:=CL_GD7542;   {Nordic}
       $30..$33:cv.version:=CL_GD7543;   {Viking}
       $34..$37:cv.version:=CL_GD7541;   {Nordic Lite}
	else cv.Version:=CL_Unk54;
	end;
	SetDAC(_dacInt,'Cirrus Internal');
        if cv.Version>=CL_GD5426 then
          cv.features:=ft_cursor+ft_blit;
        if cv.Version>=CL_GD7541 then
          case rdinx(SEQ,$A) and 15 of
            0:cv.mm:=256;
            1:cv.mm:=512;
            2:cv.mm:=1024;
            3:cv.mm:=2048;
            4:cv.mm:=4096;
          end;
        if cv.Version>=CL_GD5430 then
          case rdinx(SEQ,$15) and 15 of    {Alternate method:}
            0:cv.mm:=256;              { case rdinx(SEQ,$F) and $18}
            1:cv.mm:=512;              {   $10: cv.mm:=1024; }
            2:cv.mm:=1024;             {   $18: cv.mm:=2048; }
            3:cv.mm:=2048;             { else cv.mm:=512;    }
            4:cv.mm:=4096;             { end;                }
          end;                         { if (rdinx(SEQ,$F) and $80)>0 then }
      end                                                { cv.mm:=cv.mm*2; }
      else if testinx(SEQ,$19) then
      begin
	case cv.SubVers shr 6 of
	  0:cv.Version:=CL_GD6205;
	  1:cv.Version:=CL_GD6235;
	  2:cv.Version:=CL_GD6215;
	  3:cv.Version:=CL_GD6225;
	end;
        cv.mm:=512;
        cv.features:=0;
      end
      else begin
	cv.Version:=CL_AVGA2;
        cv.features:=ft_cursor;
	case rdinx(SEQ,$A) and 3 of
	  0:cv.mm:=256;
	  1:cv.mm:=512;
	  2:cv.mm:=1024;
	end;
      end;
      cv.chip:=__cir54;
      cv.clktype:=clk_internal;
      addvideo;
    end;
  end
  else wrinx(SEQ,6,old);
end;

procedure _cirrus64;
var x,old:word;
begin
  old:=rdinx(GRC,$A);
  wrinx(GRC,$A,$CE);  {Lock}
  if (rdinx(GRC,$A)=0) then
  begin
    wrinx(GRC,$A,$EC);  {unlock}
    if (rdinx(GRC,$A)=1) then
    begin
      cv.SubVers:=rdinx(GRC,$AA);
      case cv.SubVers shr 4 of
	4:cv.Version:=CL_GD6440;
	5:cv.Version:=CL_GD6412;
	6:cv.Version:=CL_GD5410;
	7:if testinx2(GRC,$87,$90) then cv.Version:=CL_GD6420B
                                   else cv.Version:=CL_GD6420A;
	8:cv.Version:=CL_GD6410;
      else cv.Version:=CL_Unk64;
      end;
      case rdinx(GRC,$BB) shr 6 of
	0:cv.mm:=256;
	1:cv.mm:=512;
	2:cv.mm:=768;
	3:cv.mm:=1024;
      end;
      cv.chip:=__cir64;
      cv.clktype:=clk_internal;
      addvideo;
    end;
  end;
  wrinx(GRC,$A,old);
end;


procedure _compaq;
var old,x:word;
begin
  old:=rdinx(GRC,$F);
  wrinx(GRC,$F,0);
  if not testinx(GRC,$45) then
  begin
    wrinx(GRC,$F,5);
    if testinx(GRC,$45) then
    begin
      cv.chip:=__compaq;
      cv.features:=ft_blit;
      cv.SubVers:=rdinx(GRC,$C) shr 3;
      case cv.SubVers of
	3:cv.Version:=CPQ_IVGS;
	5:cv.Version:=CPQ_AVGA;
	6:cv.Version:=CPQ_QV1024;
       $E:if (rdinx(GRC,$56) and 4)<>0 then cv.Version:=CPQ_QV1280
                                       else cv.Version:=CPQ_QV1024;
      $10:cv.Version:=CPQ_AVPort;  {What is this ?}
      else cv.Version:=CPQ_Unknown;
      end;
      if (rdinx(GRC,$C) and $B8)=$30 then  {QVision}
      begin
	cv.features:=cv.features + ft_cursor;
	wrinx(GRC,$F,5);
	case rdinx(GRC,$54) of
	  0:cv.mm:=1024;  {old QV1024 fix}
	  2:cv.mm:=512;
	  4:cv.mm:=1024;
	  8:cv.mm:=2048;
	end;
        cv.clktype:=clk_ext4;
      end
      else begin
	rp.bx:=0;
	rp.cx:=0;
	vio($BF03);
	if (rp.ch and 64)=0 then cv.mm:=512;
        cv.clktype:=clk_ext3;
      end;
      addvideo;
    end
  end;
  wrinx(GRC,$F,old);
end;

procedure _everex;
var x:word;
begin
  rp.bx:=0;
  vio($7000);
  if rp.al=$70 then
  begin
    x:=rp.dx shr 4;
    if  (x<>$678) and (x<>$236)
    and (x<>$620) and (x<>$673) then     {Some Everex boards use Trident chips.}
    begin
      case rp.ch shr 6 of
	0:cv.mm:=256;
	1:cv.mm:=512;
	2:cv.mm:=1024;
	3:cv.mm:=2048;
      end;
      cv.name:='Everex Ev'+hx[x shr 8]+hx[(x shr 4) and 15]+hx[x and 15];
      cv.chip:=__everex;
      addvideo;
    end;
  end;
end;

procedure _genoa;
var ad:word;
begin
  ad:=memw[biosseg:$37];
  if (memw[biosseg:ad+2]=$6699) and (mem[biosseg:ad]=$77) then
  begin
    case mem[biosseg:ad+1] of
      0:cv.Version:=GE_6200;
    $11:begin
	  cv.Version:=GE_6400;
	  cv.mm:=512;
	end;
    $22:cv.Version:=GE_6100;
    $33:cv.Version:=GE_5100;  {Do we need to detect the Tseng versions ??}
    $55:begin
	  cv.Version:=GE_5300;
	  cv.mm:=512;
	end;
    end;
    cv.clktype:=clk_ext3;
    if mem[biosseg:ad+1]<$33 then cv.chip:=__genoa {else cv.chip:=__ET3000};
    addvideo;
  end
end;

procedure _hmc;
begin
(*  if testinx(SEQ,$E7) and testinx(SEQ,$EE) then *)

  if testinx2(SEQ,$E7,$7F) and testinx2(SEQ,$EE,$F1) then
  begin
    if (rdinx(SEQ,$E7) and $10)>0 then cv.mm:=512;
    cv.chip:=__HMC;
    cv.clktype:=clk_ext4;
    if testinx(SEQ,$E7) and testinx(SEQ,$EE) then cv.Version:=HMC_304
                                             else cv.Version:=HMC_314;
    addvideo;
  end;
end;

procedure _Imagine;
var inx:integer;
begin
  inx:=CheckPCI(0,$105D,$2309);
  if inx>0 then
  begin
    cv.IOadr:=PCIrec[inx].base5 and $FFFE;
    case inp(cv.IOadr+$18) and $C0 of
        0:cv.mm:=4096;
      $40:cv.mm:=8192;
      $80:cv.mm:=16384;
      $C0:cv.mm:=32768;
    end;
    cv.version:=IMG_128;
    cv.chip:=__IMAG;
    cv.name:='';
    addvideo;
  end;
end;


procedure _matrox;
const
  segm:array[1..7] of word=($AC00,$C800,$CC00,$D000,$D400,$D800,$DC00);

  procedure addMGA(sgm:word);
  var l:longint;
  begin
    cv.mm:=2048;       {Still have to figure out memory, 2048 for now}
    cv.Xseg:=sgm;
    cv.chip:=__MGA;
    cv.subvers:=memw[sgm:$1E48];
    case cv.subvers of
      $1700:cv.version:=MGA_Titan;
      $1702:cv.version:=MGA_Helena;
    else cv.Version:=MGA_Unknown;
    end;
    cv.flags:=cv.flags and (not FLG_StdVGA);
    addvideo;
  end;

var i,j,inx:word;
begin    {First check for the Matrox VGA}
  if testinx(crtc,$E1) and testinx($3DE,0) then
  begin
    cv.chip:=__Matrox;
    cv.version:=MGA_VGA;   {Hm}
    cv.mm:=1024;
    addvideo;
  end;

  cv.dactype:=_dac0;   {Force DAC test}
  j:=0;
  for i:=1 to 7 do  {Check for MGA-II (Ultima)}
    if memw[segm[i]:$1E4A]=$A268 then
      addMGA(segm[i]);
  if getbios($78,3)='_VB' then
    addMGA($AC00);

  inx:=0;
  repeat
    inx:=CheckPCI(inx,$102B,$FFFF);  {Look for any Matrox}
    if (inx>0) and ((PCIrec[inx].device=$518) or (PCIrec[inx].device=$D10)) then
    begin
      cv.PCIid:=inx;
      wPCIlong($10,$AC000);  {MAP Matrox regs at AC000h}
      addMGA($AC00);
      wPCIlong($10,PCIrec[inx].l[4]);  {remap}
    end;
  until inx=0;
end;

procedure _MediaVis;   {MediaVision}
const
  IObase:array[0..4] of word=($538,$E88,$F48,$60C,$148);
var
  i,j,w:integer;
begin
  j:=0;i:=0;
  while (i<5) do
    if inp(IObase[i])=$38 then i:=i+100  {found one, now stop}
                          else inc(i);
 (*  - While this will detect an uninitialised PG1024, it will also falsely
       claim that about every second VGA card is a PG!!
  if i<100 then
  begin
    i:=0;
    while (i<5) do
      if (inp(IObase[i])=$FF) and (inp(IObase[i]+1)=$FF) then
         i:=i+100  {found one, now stop}
      else inc(i);
  end; *)
  if i>=100 then  {Found a PG1024}
  begin
    cv.IOadr  :=IObase[i-100];
    cv.chip   :=__MV;
    cv.mm     :=2304; {2.25Mb = 9*256K}
    cv.version:=MV_PG1024;
    addvideo;
  end

(* The 1280 detection does not work yet!
  else begin {Now try for a 1280}

    if (inp($539) and $CF)=$0A then outp($539,0);
    if (inp($E89) and $CF)=$4A then outp($E89,0);
    if (inp($F49) and $CF)=$8A then outp($F49,0);
    if (inp($60D) and $CF)=$CA then outp($60D,0);
    for i:=0 to 3 do
    begin
      w:=IObase[i]+1;
      if inp(w)=$FF then
      begin
        outp(w,$8A);
        for j:=1 to 100 do;
        if inp(w)=$FF then
        begin
          for j:=1 to 100 do;
          outp(w,$54);
          for j:=1 to 100 do;
          if inp(w)=$FF then
          begin
            outp(w,1);
            if inp(w)=$0A then;

            i:=999;   {Stop the loop}
          end;
        end;
        outp(w,$FF);
      end;
    end;
  end; *)
end;

procedure _mxic;
var old:integer;
begin
  old:=rdinx(SEQ,$A7);
  wrinx(SEQ,$A7,0);       {disable extensions}
  if not testinx(SEQ,$C5) then
  begin
    wrinx(SEQ,$A7,$87);   {enable extensions}
    if testinx(SEQ,$C5) then
    begin
      cv.chip:=__mxic;
      cv.clktype:=clk_ext3;
      if (rdinx(SEQ,$26) and 1)=0 then cv.Version:=MX_86010
      else cv.Version:=MX_86000;   {Does this work, else test 85h bit 1 ??}
      case (rdinx(SEQ,$C2)  shr 2) and 3 of
	0:cv.mm:=256;
	1:cv.mm:=512;
	2:cv.mm:=1024;
      end;
      addvideo;
    end;
  end;
  wrinx(SEQ,$A7,old);
end;

procedure _ncr;
var x:word;
begin
  if testinx2(SEQ,5,5) then
  begin
    wrinx(SEQ,5,0);        {Disable extended registers}
    if not testinx(SEQ,$10) then
    begin
      wrinx(SEQ,5,1);        {Enable extended registers}
      if testinx(SEQ,$10) then
      begin
	cv.chip:=__ncr;
        cv.clktype:=clk_ext3;
	cv.SubVers:=rdinx(SEQ,8);
	case cv.SubVers shr 4 of
	  0:cv.Version:=NCR_77C22;
	  1:cv.Version:=NCR_77C21;
	  2:if (cv.SubVers and 15)<8 then cv.Version:=NCR_77C22E
                                     else cv.Version:=NCR_77C22Ep;
          3:cv.Version:=NCR_77c32BLT;
	else cv.Version:=NCR_Unknown;
	end;
	cv.features:=ft_rwbank+ft_cursor;
        if cv.Version>=NCR_77c32BLT then cv.features:=cv.features+ft_blit;
	cv.name:=cv.name+' Rev. '+istr(rdinx(SEQ,8) and 15);
        memmode:=_P8;
	if setmode($13,false) then;
	checkmem(64);
	addvideo;
      end;
    end;
  end;
end;

procedure _oak;
var old:word;

begin
  if testinx($3DE,9) or testinx2($3DE,$D,$38) then
  begin
    cv.chip:=__oak;
    cv.features:=ft_rwbank;
    if testinx2($3DE,$23,$1F) then
    begin
      case rdinx($3DE,2) and 6 of
	0:cv.mm:=256;
	2:cv.mm:=512;
	4:cv.mm:=1024;
	6:cv.mm:=2048;
      end;
      if (rdinx($3DE,0) and 2)=0 then cv.Version:=OAK_087
				 else cv.version:=OAK_083;
      {SetDAC(_dac16,'OAK OTI-066HC');  {Cheat}
      cv.clktype:=clk_ext4;
    end
    else begin
      cv.clktype:=clk_ext3;
      cv.SubVers:=inp($3DE) shr 5;
      case cv.SubVers of
	0:cv.Version:=OAK_037;
	2:cv.Version:=OAK_067;
	5:cv.Version:=OAK_077;
	7:cv.Version:=OAK_057;
      else cv.Version:=OAK_Unknown;
      end;

      case rdinx($3DE,$D) shr 6 of
	2:cv.mm:=512;
      1,3:cv.mm:=1024;    {1 might not give 1M??}
      end;
    end;
    addvideo;
  end;
end;

procedure _p2000;
begin
  if testinx2(GRC,$3D,$3F) and tstrg($3D6,$1F) and tstrg($3D7,$1F) then
  begin
    cv.Version:=PR_2000;
    cv.chip:=__p2000;
    cv.features:=ft_rwbank+ft_blit;
    memmode:=_P8;
    if setmode($13,false) then;
    checkmem(32);
    cv.clktype:=clk_ext4;
    addvideo;
  end;
end;

procedure _paradise;
var old,old2:word;
begin
  old:=rdinx(GRC,$F);
  setinx(GRC,$F,$17);   {Lock registers}

  if not testinx2(GRC,9,$7F) then
  begin
    wrinx(GRC,$F,5);      {Unlock them again}
    if testinx2(GRC,9,$7F) then
    begin
      cv.clktype:=clk_ext3;
      old2:=rdinx(crtc,$29);
      modinx(crtc,$29,$8F,$85);   {Unlock WD90Cxx registers}
      if not testinx(crtc,$2B) then cv.Version:=WD_PVGA1A
      else begin
	wrinx(SEQ,6,$48);   {Enable C1x extensions}
	if not testinx2(SEQ,7,$F0) then cv.Version:=WD_90C00
	else if not testinx(SEQ,$10) then
	begin
          if testinx2(crtc,$31,$68) then cv.Version:=WD_90c22
          else if testinx2(crtc,$31,$90) then cv.Version:=WD_90c20A
          else cv.Version:=WD_90C20;
	  wrinx(crtc,$34,$A6);
	  if (rdinx(crtc,$32) and $20)<>0 then wrinx(crtc,$34,0);
	end
	else begin
          cv.clktype:=clk_ext4;
	  cv.features:=ft_rwbank;
	  if testinx2(SEQ,$14,$F) then
	  begin
            wrinx(crtc,$34,0);   {Disable c2x registers}
            wrinx(crtc,$35,0);   {Disable c2x registers}
	    cv.SubVers:=(rdinx(crtc,$36) shl 8)+rdinx(crtc,$37);
	    case cv.SubVers of
	      $3234:begin
                      cv.Version:=WD_90c24;
                      cv.features:=cv.features+ft_cursor+ft_blit;
                      cv.clktype:=clk_internal;
                      SetDAC(_dacInt,'WD 16bit');
                    end;
	      $3236:cv.Version:=WD_90C26;
	      $3330:cv.Version:=WD_90c30;
	      $3331:begin
                      cv.Version:=WD_90C31;
                      cv.features:=cv.features+ft_cursor+ft_blit;
                    end;
	      $3333:begin
                      cv.Version:=WD_90C33;
                      cv.features:=cv.features+ft_cursor+ft_blit+ft_line;
                    end;
	    end;
	  end
	  else if not testinx2(SEQ,$10,4) then cv.Version:=WD_90C10
					  else cv.Version:=WD_90C11;
	end;
      end;
      wrinx(GRC,$F,5);      {Unlock them again}
      case rdinx(GRC,$B) shr 6 of
        2:cv.mm:=512;
        3:cv.mm:=1024;
      end;
      if (cv.Version>=WD_90c33) and ((rdinx(crtc,$3E) and $80)>0) then cv.mm:=2048;
      wrinx(crtc,$29,old2);
      cv.chip:=__WD;
      addvideo;
    end;
  end;
  wrinx(GRC,$F,old);
end;

procedure _realtek;
begin
  if testinx2(crtc,$1F,$3F) and tstrg($3D6,$F) and tstrg($3D7,$F) then
  begin
    cv.chip:=__realtek;
    cv.clktype:=clk_ext3;
    cv.SubVers:=rdinx(crtc,$1A) shr 6;
    case cv.SubVers of
      0:cv.Version:=RT_3103;
      1:cv.Version:=RT_3105;
      2:cv.Version:=RT_3106;
    else cv.Version:=RT_unknown;
    end;
    case rdinx(crtc,$1E) and 15 of
      0:cv.mm:=256;
      1:cv.mm:=512;
      2:if cv.SubVers=0 then cv.mm:=768  else cv.mm:=1024;
      3:if cv.SubVers=0 then cv.mm:=1024 else cv.mm:=2048;
    end;
    cv.features:=ft_rwbank;
    addvideo;
  end;
end;

procedure _s3;
begin
  wrinx(crtc,$38,0);
  if not testinx2(crtc,$35,$F) then
  begin
    wrinx(crtc,$38,$48);
    if testinx2(crtc,$35,$F) then
    begin
      cv.features:=ft_blit+ft_line+ft_cursor;
      cv.SubVers:=rdinx(crtc,$30);
      cv.clktype:=clk_ext4;
      case cv.SubVers of
	$81:cv.Version:=S3_911;
	$82:cv.Version:=S3_924;    {Also known as 911A}
	$90:cv.Version:=S3_928;
	$91:cv.Version:=S3_928C;
	$94:cv.Version:=S3_928D;
        $95:cv.Version:=S3_928E;
	$A0:if (rdinx(crtc,$36) and 2)>0 then cv.Version:=S3_801AB
				         else cv.Version:=S3_805AB;
   $A2..$A4:if (rdinx(crtc,$36) and 2)>0 then cv.Version:=S3_801C
                                         else cv.Version:=S3_805C;
    $A5,$A7:if (rdinx(crtc,$36) and 2)>0 then cv.Version:=S3_801D
				         else cv.Version:=S3_805D;
        $A6:if (rdinx(crtc,$36) and 2)>0 then cv.Version:=S3_801P
					 else cv.Version:=S3_805P;
        $A8:if (rdinx(crtc,$36) and 2)>0 then cv.Version:=S3_801I
					 else cv.Version:=S3_805I;
	$B0:cv.Version:=S3_928PCI;
	$C0:cv.Version:=S3_864;
	$C1:cv.Version:=S3_864P;
	$D0:cv.Version:=S3_964;
    $E0,$E1:case rdinx(crtc,$2E) of   {Not sure of this yet}
              $10:cv.Version:=S3_732;
              $11:cv.Version:=S3_764;
              $80:cv.Version:=S3_866;
              $90:cv.Version:=S3_868;
          $B0,$F0:cv.Version:=S3_968;
            end;
      else cv.Version:=S3_Unknown;
      end;
      if (cv.Version=S3_732) or  (cv.Version=S3_764) then
      begin
        cv.clktype:=clk_internal;
        SetDAC(_dacInt,'S3 Trio');
      end;
      cv.mm:=512;
      if (rdinx(crtc,$36) and $20)=0 then
        if (cv.subvers<$90) then cv.mm:=1024   {911 and 924}
        else case rdinx(crtc,$36) shr 6 of
               0:cv.mm:=4096;
               1:cv.mm:=3072;
               2:cv.mm:=2048;
               3:cv.mm:=1024;
             end;
      cv.chip:=__S3;
      addvideo;
    end;
  end;
end;

procedure _Sierra;
var old,i:word;
begin
  old:=rdinx(SEQ,$11);
  setinx(SEQ,$11,$20);
  if not testinx(SEQ,$15) then
  begin
    i:=rdinx(SEQ,$11);
    outp(SEQ+1,i);
    outp(SEQ+1,i);
    outp(SEQ+1,i and $DF);
    if testinx(SEQ,$15) then
    begin
      setinx(SEQ,$11,$20);
      cv.chip:=__Acer;
      case rdinx(SEQ,7) shr 5 of
        4:cv.version:=SC_15064;
      else cv.version:=SC_Unknown;
      end;
      if setmode($13,false) then;
      checkmem(64);
      addvideo;
    end;
  end;
  wrinx(SEQ,$11,old);
end;

procedure _SiS;
var old:word;
begin
  old:=rdinx(SEQ,5);
  wrinx(SEQ,5,0);
  if rdinx(SEQ,5)=$21 then
  begin
    wrinx(SEQ,5,$86);
    if rdinx(SEQ,5)=$A1 then
    begin
      cv.chip:=__SiS;
      cv.Version:=SIS_201;
      case rdinx(SEQ,$F) and 3 of
        0:cv.mm:=1024;
        1:cv.mm:=2048;
        2:cv.mm:=4096;
      end;
      cv.dactype:=_dacInt;
      cv.clktype:=clk_ext4;
      cv.features:=ft_cursor+ft_rwbank;
      addvideo;
    end;
  end;
  wrinx(SEQ,5,old);
end;

procedure _trident;
var old,val,Xseg,x:word;
  Phadr:longint;
begin
  wrinx(SEQ,$B,0);           {Force old mode}
  cv.SubVers:=inp(SEQ+1);    { ---  new mode}
  old:=rdinx(SEQ,$E);
  outp(SEQ+1,old xor $55);
  val:=inp(SEQ+1);
  outp(SEQ+1,old);
  if ((val xor old) and 15)=7 then  {Check for inverting bit 1}
  begin
    outp($3c5,old xor 2);   (* Trident should restore bit 1 reversed *)
    case cv.SubVers of
        1:cv.Version:=TR_8800BR;   {This'll never happen - no new mode}
        2:cv.Version:=TR_8800CS;
        3:cv.Version:=TR_8900B;
    4,$13:cv.Version:=TR_8900C;
      $23:cv.Version:=TR_9000;
      $33:if (rdinx(crtc,$28) and $80)>0 then cv.Version:=TR_8900CL
                {Does this work?}        else cv.Version:=TR_9000C;
      $43:cv.Version:=TR_9000i;
      $53:cv.Version:=TR_9200CXr;
      $63:cv.Version:=TR_LCD9100B;
      $73:cv.Version:=TR_GUI9420;   {Haven't seen this yet ?}
      $83:cv.Version:=TR_LX8200;
      $93:cv.Version:=TR_9400CXi;
      $A3:cv.Version:=TR_LCD9320;
      $C3:cv.Version:=TR_GUI9420;
      $D3:cv.Version:=TR_GUI9660;
      $E3:cv.Version:=TR_GUI9440;
      $F3:cv.Version:=TR_GUI9430;  {not quite sure}
          {The $63, $73, $83, $A3 entries are still in doubt}
    else cv.Version:=TR_Unknown;
    end;
    case cv.version of
      TR_8800BR,
      TR_8800CS,
       TR_8900B:cv.clktype:=clk_ext3;
      TR_9200CXr,TR_9400CXi,TR_GUI9420,TR_GUI9430
               :begin
                  cv.clktype:=clk_ext4;
                  cv.dactype:=_dacInt;
                end;
     TR_GUI9440:begin
                  cv.clktype:=clk_internal;
                  cv.dactype:=_dacInt;
                end;
    else cv.clktype:=clk_ext4;
    end;
    if (cv.version>=TR_9000C) then cv.features:=cv.features+ft_rwbank;
    if (cv.version>=TR_GUI9440) then cv.features:=cv.features+ft_cursor;
    if cv.version=TR_9000i then setDAC(_dac16,'Trident 9000i');
    cv.chip:=__trid;
    if (pos('Zymos Poach 51',getbios(0,255))>0) or
       (pos('Zymos Poach 51',getbios(230,255))>0) then
    begin
      cv.name:=cv.name+' (Zymos Poach)';
      cv.chip:=__poach;
    end;
    case rdinx(crtc,$1F) and 3 of
      0:cv.mm:=256;
      1:cv.mm:=512;
      2:cv.mm:=768;
      3:if (cv.Version>=TR_8900CL) and ((rdinx(crtc,$1F) and 4)>0) then
             cv.mm:=2048
        else cv.mm:=1024;
    end;
    if (cv.SubVers=2) and (tstrg($2168,$F)) then
    begin
      cv.clktype:=clk_ext2;
      cv.Version:=TR_IITAGX;
      cv.mm:=512;   {Might be able to address 1Mb, but scroll etc only works}
      addvideo;     {in the first 512K anyhow !}

      cv.IOadr:=$2160;
      cv.chip:=__AGX;
      old:=inp(cv.IOadr);
      modreg(cv.IOadr,7,4); {Enable XGA mode}
      if testinx2(cv.IOadr+10,$7F,$30) then cv.version:=IIT_AGX1x
      else if testinx2(cv.IOadr+10,$71,$F) then cv.version:=IIT_AGX16
      else if (rdinx(cv.IOadr+10,$6C) and 1)>0 then cv.version:=IIT_AGX15
                                               else cv.Version:=IIT_AGX14;
      if (rdinx(cv.IOadr+10,$6D) and 1)>0 then cv.Xseg:=$B1F0 else cv.Xseg:=$D1F0;
      outp(cv.IOadr,old);
      if cv.Version>=IIT_AGX14 then cv.clktype:=clk_ext5
                               else cv.clktype:=clk_ext4;
      memmode:=_p8;
      if setmode($65,false) then;
      checkmem(32);
      cv.features:=ft_blit+ft_line+ft_cursor;
      Phadr:=$FF800000;
      cv.flags:=cv.flags and (not FLG_StdVGA);
    end;
    addvideo;
  end
  else begin  {Trident 8800BR tests}
    if (cv.subvers=1) and testinx2(SEQ,$E,6) then
    begin
      cv.Version:=TR_8800BR;
      cv.chip:=__trid;
      if (rdinx(crtc,$1F) and 2)>0 then cv.mm:=512;
      addvideo;
    end;
  end;
end;

procedure _tseng;
var x,vs:word;
  s:string;
begin
  outp($3BF,3);
  outp(crtc+4,$A0);    {Enable Tseng 4000 extensions}
  if tstrg($3CD,$3F) then
  begin
    cv.chip:=__Tseng;
    cv.features:=ft_rwbank;
    cv.clktype:=clk_ext5;
    if testinx2(crtc,$33,$F) then
    begin
      if tstrg($3CB,$33) then
      begin
        cv.features:=cv.features+ft_cursor+ft_blit;
	cv.SubVers:=rdinx($217A,$EC);
	case cv.SubVers shr 4 of
	  0:cv.Version:=ET_4W32;
          1:cv.Version:=ET_4W32i_a;
          2:cv.Version:=ET_4W32p_a;
          3:cv.Version:=ET_4W32i_b;
          5:cv.Version:=ET_4W32p_b;
          6:cv.Version:=ET_4W32p_d;
          7:cv.Version:=ET_4W32p_c;
         11:cv.Version:=ET_4W32i_c;
	else Unk(ET_4Unk,cv.SubVers);
	end;
	case rdinx(crtc,$37) and $9 of
           0:cv.mm:=2048;
	   1:cv.mm:=4096;
	 {  9:mm:=256;}
	   8:cv.mm:=512;
	   9:cv.mm:=1024;
	end;
        if cv.version>=ET_4W32p_a then cv.features:=cv.features or ft_line;
        if (cv.Version<>ET_4W32) and ((rdinx(crtc,$32) and $80)>0) then
          cv.mm:=cv.mm*2;
      end
      else begin
	cv.Version:=ET_4000;
	case rdinx(crtc,$37) and $B of
	 3,9:cv.mm:=256;
	  10:cv.mm:=512;
	  11:cv.mm:=1024;
	end;
        cv.subvers:=0;
        for x:=0 to 10 do
        begin
          s:=getbios(x*230,255);
          if pos('Genoa Systems',s)>0 then cv.subvers:=TS_Genoa7900
          else if pos('SpeedSTAR',s)>0 then cv.subvers:=TS_SpeedStar;
        end;
      end;
    end
    else begin
      cv.Version:=ET_3000;
      if setmode($13,false) then;
      x:=inp(CRTC+6);
      x:=rdinx($3C0,$36);
      outp($3C0,x or $10);
      case (rdinx(GRC,6) shr 2) and 3 of
       0,1:vs:=SegA000;
	 2:vs:=SegB000;
	 3:vs:=SegB800;
      end;

      meml[vs:1]:=$12345678;
      if memw[vs:2]=$3456 then cv.mm:=512;

      wrinx($3C0,$36,x);     {reset value and reenable DAC}
    end;
    addvideo;
  end;
end;

procedure _UMC;
var old:integer;
begin
  old:=inp($3BF);
  outp($3BF,3);
  if not testinx(SEQ,6) then
  begin
    outp($3BF,$AC);
    if testinx(SEQ,6) then
    begin
      cv.chip:=__UMC;
      cv.clktype:=clk_ext3;
      case rdinx(SEQ,7) shr 6 of
	1:cv.mm:=512;
      2,3:cv.mm:=1024;
      end;
      if testinx2(crtc,$35,$F) then
      begin
        cv.version:=UMC_418;
        if ((rdinx(GRC,$B) and $7F)=$2A) then cv.mm:=1024;
      end
      else cv.version:=UMC_408;
      cv.features:=ft_rwbank;
      addvideo;
    end;
  end;
  outp($3BF,old);
end;


procedure _video7;
var ram:string[10];
  old:integer;
begin
  vio($6f00);
  if rp.bx=$5637 then
  begin
    vio($6f07);
    if rp.ah<128 then ram:='VRAM' else ram:='FASTWRITE';

 (* old:=rdinx(crtc,$C);
  wrinx(crtc,$C,old);
  wrinx($3C4,6,$EA);    {Enable Extensions}
  if rdinx(crtc,$1F)=(old XOR $EA) then
  begin
    wrinx(crtc,$C,old XOR $FF);
    if rdinx(crtc,$1F)=(old XOR $15) then
    begin
      cv.SubVers:=(rdinx($3C4,$8F) shl 8)+rdinx($3C4,$8E);

  wrinx(crtc,$C,old); *)

    wrinx(SEQ,6,$EA);  {Enable extensions}
    cv.Subvers:=(rdinx(SEQ,$8F) shl 8)+rdinx(SEQ,$8E);
    case cv.Subvers of
  $8000..$FFFF:cv.Version:=V7_VEGA;
  $7000..$70FF:cv.Version:=V7_208_13;    {Fastwrite}
  $7140..$714F:cv.Version:=V7_208A;      {1024i}
	 $7151:cv.Version:=V7_208B;      {VRAm II b}
	 $7152:cv.Version:=V7_208CD;     {VRAm II c}
	 $7760:cv.Version:=V7_216BC;
	 $7763:cv.Version:=V7_216D;
	 $7764:cv.Version:=V7_216E;
	 $7765:cv.Version:=V7_216F;
    else cv.Version:=V7_Unknown;
    end;
    case rp.ah and 127 of
      2:cv.mm:=512;
      4:cv.mm:=1024;
    end;
    cv.chip:=__video7;
    cv.features:=ft_cursor;
    if cv.Version>=V7_208A then
    begin
    {  cv.Features:=cv.features+ft_rwbank; {Don't work }
      cv.clktype:=clk_ext4;
    end;
    addvideo;
  end;
end;


  {Sets the Extention & Bank enable flags in SEQ index $11}
function WeitekEnable(flag:word):word;
var x,y:word;
begin
  disable;
  x:=rdinx(SEQ,$11);
  for y:=1 to 10 do; {delay}
  outp(SEQ+1,x);
  for y:=1 to 10 do;
  outp(SEQ+1,x);
  for y:=1 to 10 do;
  WeitekEnable:=x;
  x:=inp(SEQ+1);
  for y:=1 to 10 do;
  outp(SEQ+1,(x and $9F) or flag);
  WeitekEnable:=x;
  enable;
end;


procedure _Weitek;
var old,x,y,z:word;
  rr:array[0..$1FF] of byte;
begin
  old:=WeitekEnable($60);   {Disable}
  if not testinx(SEQ,$12) then
  begin
    x:=WeitekEnable(0);     {Enable}
    if testinx(SEQ,$12) and tstrg($3CD,$FF) then
    begin
      cv.chip:=__Weitek;
      cv.features:=ft_rwbank;
      cv.SubVers:=rdinx(SEQ,7);
      cv.clktype:=clk_ext3;
      case cv.subvers shr 5 of
        1:begin
            cv.Version:=WT_5186;  {Should check for version and memory}
          (*  if (rdinx(SEQ,$12) and $80)>0 then
               cv.mm:=512;   {Untested} *)
          end;
        2:begin
            outp($9100,0);
            z:=inp($9104);
            outp($9100,1);
            z:=(inp($9104) shl 8)+z;
            if (z=$100E) then
            begin
              cv.Version:=WT_P9100;
              cv.mm:=1024;   {Hm}
            end
            else begin
              cv.Version:=WT_5286;
              case rdinx(SEQ,$12) shr 6 of
                0:cv.mm:=256;
                1:cv.mm:=512;
                2:cv.mm:=1024;
              end;
            end;
          end;
      else cv.Version:=WT_Unk;
      end;
      addvideo;
      x:=WeitekEnable($60);  {dis. VGA}
      z:=rdinx(SEQ,$12);
      clrinx(SEQ,$12,$80);
      setinx(SEQ,$12,$10);
      outp($3CD,$10);

      move(mem[SegA000:0],rr,$200);
      wrinx(SEQ,$12,z);
    end;
  end;
  wrinx(SEQ,$11,old);
end;

procedure _XGA;
var p:pointer;
 posbase,cardid,xga_base,x,cx:word;
 temp0,temp1,temp2,temp3:byte;
begin
  getintvec($15,p);
  if (seg(p^)<>0) then
  begin
    rp.ax:=$C400;
    rp.dx:=$ffff;
    intr($15,rp);
    if not odd(rp.flags) and (rp.dx<>$ffff) then
    begin
      posbase:=rp.dx;
      for cx:=0 to 9 do
      begin
	disable;   (* CLI -  Disable interrupts *)
	if cx=0 then outp($94,$DF)
	else begin
	  rp.ax:=$C401;
	  rp.bx:=cx;
	  intr($15,rp);
	end;
	cardid:=inpw(posbase);
	temp0:=inp(posbase+2);
	temp1:=inp(posbase+3);
	temp2:=inp(posbase+4);
	temp3:=inp(posbase+5);
	if cx=0 then outp($94,$FF)
	else begin
	  rp.ax:=$C402;
	  rp.bx:=cx;
	  intr($15,rp);
	end;
	enable;   (* STI -  Enable interrupts *)
	if (cardid>=$8FD8) and (cardid<=$8FDB) then
	begin
	  cv.IOadr:=$2100+(temp0 and $E)*8;
	  x:=rdinx(cv.IOadr+10,$52) and 15;
	  if (x<>0) and (x<>15) then
	  begin
	    cv.chip:=__XGA;
	    outp(cv.IOadr+4,0);
	  {  outp(cv.IOadr,4);
	    checkmem(16); }
            cv.mm:=1024;
	    case cardid of
	     $8FDA:cv.Version:=XGA_NI;
	     $8FDB:cv.Version:=XGA_org;
	    end;

	    cv.Xseg:=(temp0 shr 4)*$2000+$C1C0+(temp0 and $E)*4;
	    cv.Phadr:=((temp2 and $FE)*word(8)+(temp0 and $E))*longint($200000);
	    addvideo;
	  end;
	end;
      end;
    end;
  end;
end;

procedure _yamaha;
begin
  if testinx2(crtc,$7C,$7C) then
  begin
    cv.Version:=YA_6388;
    addvideo;
  end;
end;

procedure _xbe;
var
  x:word;
  xbe0:_xbe0;
  xbe1:_xbe1;

begin
  viop($4E00,0,0,0,@xbe0);
  if (rp.ax=$4E) and (xbe0.sign=$41534556) then
  begin
    for x:=0 to xbe0.xgas-1 do
    begin
      viop($4E01,0,0,x,@xbe1);
      if (rp.ax=$4E) then
      begin
	cv.chip:=__xbe;
        cv.features:=ft_blit+ft_line;
	cv.mm:=xbe1.memory*longint(64);
	cv.id:=x;
	cv.IOadr :=xbe1.iobase;
	cv.Xseg  :=xbe1.memreg shr 16;
	cv.Phadr :=xbe1.vidadr;
	cv.name  :=gtstr(xbe1.oemadr^);
	UNK(VS_XBE,xbe0.vers);
	addvideo;
      end;
    end;
  end;
end;

procedure _vesa;
var
  vesarec:_vbe0;
  x:word;
begin
  viop($4f00,0,0,0,@vesarec);
  if (rp.ax=$4f) and (vesarec.sign=$41534556) then
  begin
    cv.chip:=__vesa;
    cv.mm:=vesarec.mem*longint(64);
    cv.name:=gtstr(vesarec.oemadr^);
    UNK(VS_VBE,vesarec.vers);
    cv.dactype:=_dac8;    {Dummy, to keep Cirrus 542x out of trouble}
    addvideo;
  end;
end;


type
  pel=record
	index,red,green,blue:byte;
      end;

procedure readpelreg(index:word;var p:pel);
begin
  p.index:=index;
  disable;
  outp($3C7,index);
  p.red  :=inp($3C9);
  p.blue :=inp($3C9);
  p.green:=inp($3C9);
  enable;
end;

procedure writepelreg(var p:pel);
begin
  disable;
  outp($3C8,p.index);
  outp($3C9,p.red);
  outp($3C9,p.blue);
  outp($3C9,p.green);
  enable;
end;

function setcomm(cmd:word):word;
begin
  dac2comm;
  outp($3c6,cmd);
  dac2comm;
  setcomm:=inp($3c6);
end;

function dacis8bit:boolean;
var
  pel2,x,y,z,v:word;
  pel1:pel;
begin
  pel2:=inp($3C8);
  readpelreg(255,pel1);
  v:=pel1.red;
  pel1.red:=255;
  writepelreg(pel1);
  readpelreg(255,pel1);
  x:=pel1.red;
  pel1.red:=v;
  writepelreg(pel1);
  outp($3C8,pel2);
  dacis8bit:=(x=255);
end;

procedure testdac;      {Test for type of DAC}
var
  x,y,z,v,oldcomm,oldpel,notcomm:word;
  dac8,dac8now:boolean;
  data:array[9..12] of byte;

procedure waitforretrace;
begin
  repeat until (inp(CRTC+6) and 8)=0;
  repeat until (inp(CRTC+6) and 8)>0;    {Wait until we're in retrace}
end;

procedure SetDACCmd(cmd:integer);
begin
  dac2comm;
  outp($3C6,cmd);
  dac2pel;
end;


function testdacbit(bit:word):boolean;
var v:word;
begin
  dac2pel;
  outp($3C6,oldpel and (bit xor $FF));
  dac2comm;
  disable;
  outp($3C6,oldcomm or bit);
  dac2comm;
  v:=inp($3C6);
  outp($3C6,v and (bit xor $FF));
  enable;
  testdacbit:=(v and bit)<>0;
end;

function rdSCdac(Inx:word):word;
begin
  dac2comm;
  outp($3C6,inp($3C6) or $10);
  rdSCdac:=rdinx($3C7,inx);
  dac2comm;
  outp($3C6,inp($3C6) and $EF);
  dac2pel;
end;

procedure wrBTinx(inx,val:word);
var x:word;
begin
  dac2comm;
  x:=daccomm;
  outp($3C6,1);
 { dac2pel;}
  outp($3C8,Inx);
  outp($3C6,val);
  dac2comm;
  outp($3C6,x and $FE);
  dac2pel;
end;

function rdBTinx(Inx:word):word;
var x:word;
begin
  dac2comm;
  x:=daccomm;
  outp($3C6,1);
 { dac2pel;}
  outp($3C8,Inx);
  rdBTinx:=inp($3C6);
  dac2comm;
  outp($3C6,x and $FE);
  dac2pel;
end;


var zz:integer;
  t:text;
begin
  setDAC(_dac8,'Normal');
  dac2comm;
  oldcomm:=inp($3c6);
  dac2pel;
  oldpel:=inp($3c6);

  if cv.dactype=_dac8 then
  begin
    dac2comm;
    outp($3C6,0);
    dac8:=dacis8bit;
    dac2pel;

    notcomm:=oldcomm xor 255;
    outp($3C6,notcomm);
    dac2comm;
    v:=inp($3C6);
    if v<>notcomm then    {We have a "Hidden Command" register}
    begin
      dac2pel;
      dac2comm;
      x:=inp($3C6);
      x:=inp($3C6);
      y:=inp($3C6);
      z:=inp($3C6);
      dac2pel;
      if (x=$84) and (y=$98) then
      begin
        if z=$4F then setDAC(_dacICW516,'IC Works W30c516')
        else if setcomm($A)=0 then setDAC(_dacATT2498,'ATT 22c498')
                              else setDAC(_dacATT1498,'ATT 21c498');
      end
      else begin
        setDACcmd($10);
        if rdinx($3C7,9)=$53 then
        begin
          x:=rdinx($3C7,10);
          x:=x*256+rdinx($3C7,11);
          case x of     {Looks like the 15021 & 25 are the only values}
            15021:setDAC(_dacSC15021,'SC15021');
            15025:setDAC(_dacSC15025,'SC15025');
          else setDAC(_dacSC15021,'Unknown SC 15xxx');
          end;
        end;
        setDACcmd(oldcomm);
      end;
      if cv.dactype=_dac8 then
      begin
        setDACcmd($10);
        dac2comm;
        x:=inp($3C6);
        outp($3C6,0);
        outp($3C6,0);
        if inp($3C6)=$44 then
          case inp($3C6) of
            0:setDAC(_dacSTG1700,'STG1700');
            2:setDAC(_dacSTG1702,'STG1702');
            3:begin
                setDAC(_dacSTG1703,'STG1703');
                cv.clktype:=clk_STG;
              end;
          else setDAC(_dacSTG1700,'Unknown STG');
          end;
        setDACcmd(oldcomm);
      end;
      if cv.dactype=_dac8 then
      begin
        dac2pel;
        x:=inp($3C6);
        x:=inp($3C6);
        x:=inp($3C6);
        x:=inp($3C6);
        if (x and $F0)=$70 then
        begin
          setDAC(_dacS3_716,'S3 86c716 (SDAC)');
          cv.clktype:=clk_sdac;
        end;
        dac2pel;
      end;
      if cv.dactype=_dac8 then
      begin
        dac2comm;
        if daccomm=$31 then setDAC(_dacALG1301,'ALG1301');
        dac2pel;
      end;
      if cv.dactype=_dac8 then
        if (setcomm($E0) and $E0)<>$E0 then
        begin
          dac2pel;
          x:=inp($3C6);
          repeat
	    y:=x;         {wait for the same value twice}
	    x:=inp($3C6);
          until (x=y);
          z:=x;
          dac2comm;
          if daccomm<>$8E then
          begin                 {If command register=$8e, we've got an SS24}
	    y:=8;
	    repeat
	      x:=inp($3C6);
	      dec(y);
	    until (x=$8E) or (y=0);
          end
          else x:=daccomm;
          if x=$8e then setDAC(_dacMU1880,'SS24')
	           else setDAC(_dacSC486,'Sierra SC11486');
          dac2pel;
        end
        else begin
          if (setcomm($60) and $E0)=0 then
          begin
            if (setcomm(2) and 2)>0 then setDAC(_dacATT490,'ATT 20c490')
                                    else setDAC(_dacATT493,'ATT 20c493');
          end
          else begin  {Bit 5-7 fully r/w}
            dac2pel;
            outp($3C6,notcomm);     {PEL register}
	    x:=setcomm(oldcomm);
	    if inp($3C6)=notcomm then     {Falls back to PEL register}
	    begin                         {after 1st read}
              x:=setcomm($FC);
              if x<>$FC then
                case x of
                  $E2:setDAC(_dacALG1201,'ALG1201');
                  $E0:setDAC(_dacICS5301,'ICS 5301');
                  $F4:setDAC(_dacS3_708,'S3/ICS 86c708 GenDAC');
                else
                  if testdacbit($F0) then setDAC(_dacUMC188,'UMC UM70c188')
                                     else setDAC(_dacADAC1,'Acumos ADAC1');
                end
	      else begin  {All 8 bits fully r/w}
	        dac8now:=dacis8bit;
	        dac2comm;
	        outp($3C6,(oldcomm or 2) and $FE);
	        dac8now:=dacis8bit;
	        if dac8now then
                begin
	          if dacis8bit then
                  begin
                    x:=setcomm(oldcomm or $10);
                    dac2comm;
                    x:=inp($3C6);
                    outp($3C6,1);
                    x:=x;  {delay}
                    outp($3C6,0);
                    if inp($3C6)=0 then setDAC(_dacATT491,'ATT 20c491')
                  end
                end
                 { else setDAC(_dacCL24,'Cirrus 24bit DAC')}
	        else
                  if trigdac=$B3 then
                  begin
                    setDAC(_dacCH8391,'CHRONTEL CH8391');
                    cv.clktype:=clk_CHRON;
                  end
                  else setDAC(_dacATT492,'ATT 20c492');
	      end;
	    end
	    else begin
	      {if trigdac=notcomm then setDAC(_dacCL24,'Cirrus 24bit DAC')
	      else} begin
	        dac2pel;
	        outp($3C6,$FF);
	        case trigdac of
                  $44:begin
                        setDAC(_dacMU9910,'MUSIC MU9C9910');
                        cv.clktype:=CLK_MUSIC;
                      end;
	          $82:setDAC(_dacMU4910,'MUSIC MU9C4910');
	          $8E:setDAC(_dacMU1880,'MUSIC MU9C1880 (SS2410)');
	        else begin
                  if setcomm(1)=$AA then setDAC(_dacALG1201,'ALG1201')
                  else begin
                         dac2comm;
                         if daccomm=$C0 then
                         begin
                           setDAC(_dacCH8398,'CH8398');
                           cv.clktype:=clk_CHRON;
                         end
                         else
                           if testdacbit($10) then
                           begin
                             outp($3C8,2);
                             SetDACcmd(oldcomm or 2);
                             dac8now:=dacis8bit;
                             SetDACcmd(oldcomm and $FD);
                             if dac8now then    {The Bt481 ends here too}
                             begin
                               outp($3C8,0);
                               SetDACcmd(oldcomm or 2);
                               dac8now:=dacis8bit;
                               SetDACcmd(oldcomm and $FD);
                               if dac8now then setDAC(_dacTR8001,'Trident TKD8001')
                                          else setDAC(_dacBt481,'Bt481');
                             end
                             else setDAC(_dac16,'OAK 66HC');
                           end
                           else begin
                             dac2pel;
                             outp($3C6,$FF);
                             dac2comm;
                             outp($3C6,0);
                             dac2pel;
                             dac2comm;
                             outp($3C6,$7F);
                             dac2comm;
                             x:=inp($3C6);
                             dac2comm;
                             dac2comm;
                             outp($3C6,$FF);
                             dac2comm;
                             v:=inp($3C6);
                             dac2comm;
                             outp($3C6,oldcomm);
                             dac2pel;
                             if (x=$60) and (v=$E0) then setDAC(_dac16,'UMC 70c178')
                             else if (x=$7F) and (v=$FE) then setDAC(_dac16,'Sierra SC11487')
                                                    else setDAC(_dac15,'Sierra Sc11483');
                           end;
                       end;
	        end;
	      end;
	    end;
          end;
        end;

      end;

      dac2comm;
      outp($3c6,oldcomm);
    end;
    dac2pel;
    outp($3c6,oldpel);

  end;

  if (cv.dactype=_dac8) then
  begin
    oldpel :=rdDACreg(dacSTDpelMask) xor $FF;
    oldcomm:=rdDACreg(dacSTDpelMask+4);
    x      :=rdDACreg(dacSTDpelMask+8);
    wrDACreg(dacSTDpelMask,oldpel);
    y :=rdDACreg(dacSTDpelMask+4);
    z :=rdDACreg(dacSTDpelMask+8);
    zz:=rdDACreg(dacSTDpelMask);
    if (zz=oldpel) and (y<>oldpel) or (z<>oldpel) then
    begin   { Either RS2 or RS3 finds a register <> $3C6,
              We have an advanced DAC and access to it! }
      wrDACreg(dacSTDpelMask,0);
      wrDACreg(dacTLCtest,3);
      case rdDACreg(dacTLCtest) of
        $75:setDAC(_dacTLC34075,'TLC34075');
        $76:setDAC(_dacTLC34076,'TLC34076');
      else
        if cv.chip=__S3 then
        begin
          outpw(crtc,$A539);
          y:=rdinx(crtc,$5C);   {Force TI mode}
          clrinx(crtc,$5C,$20);
          wrDACreg(dacTVPindex,6);
          z:=rdDACreg(dacTVPdata);
          wrDACreg(dacTVPdata,z and $7F);
        end;
        x:=rdDACreg(dacTVPindex);
        wrDACreg(dacTVPindex,$3F);
        y:=rdDACreg(dacTVPdata);
        wrDACreg(dacTVPdata,y xor $FF);
        z:=rdDACreg(dacTVPdata);
        if z<>y then  {Must be read-only for TVP}
          wrDACreg(dacTVPdata,y)
        else
          case y of
            $10:setDAC(_dacTVP3010,'TVP 3010');
            $20:setDAC(_dacTVP3020,'TVP 3020');
            $25:begin
                  setDAC(_dacTVP3025,'TVP 3025');
                  cv.clktype:=clk_TVP302x;
                end;
          end;
        wrDACreg(dacTVPindex,x);
        if cv.dactype=_dac8 then
        begin
          x:=rdDACreg(dacTVP6index);
          wrDACreg(dacTVP6index,$3F);
          y:=rdDACreg(dacTVP6data);
          wrDACreg(dacTVP6data,y xor $FF);
          z:=rdDACreg(dacTVP6data);
          if z<>y then  {Must be read-only for TVP}
            wrDACreg(dacTVP6data,y)
          else
            case y of
              $26:begin
                    setDAC(_dacTVP3026,'TVP 3026');
                    cv.clktype:=clk_TVP302x;
                  end;
            end;
          wrDACreg(dacTVP6index,x);
        end;
        if cv.chip=__S3 then
        begin
          wrDACreg(dacTVPindex,6);
          wrDACreg(dacTVPdata,z);
          outpw(crtc,$A539);
          wrinx(crtc,$5C,y);
        end;
        if (cv.dactype=_dac8) then
        begin
          x:=rdDACreg(dacHIcmd);
          wrDACreg(dacHIcmd,x and $FE);
          y:=rdDACreg(dacSTDpelMask);
          wrDACreg(dacHIcmd,x or 1);   {Switch to Bt481 Indexed}
          wrDACreg(dacSTDwrInx,dacBTIipixm);
          wrDACreg(dacSTDpelMask,y xor $55);
          z:=rdDACreg(dacSTDpelMask);
          wrDACreg(dacSTDwrInx,dacBTIcurX);
          wrDACreg(dacSTDpelMask,y xor $AA);
          v:=rdDACreg(dacSTDpelMask);
          wrDACreg(dacSTDwrInx,dacBTIipixm);
          zz:=rdDACreg(dacSTDpelMask);
          wrDACreg(dacHIcmd,x and $FE); {Back to std regs}
          if (y=rdDACreg(dacSTDpelMask)) and (z=(y xor $55)) then
          begin
            if v=(y xor $AA) then setDAC(_dacBt481,'Bt482')
                             else setDAC(_dacBt482,'Bt481');
          end
          else begin
            x:=rdDACreg(dacIBMind0);
            wrDACreg(dacIBMind1,0);
            wrDACreg(dacIBMind0,dacIBMiRev);
            y:=rdDACreg(dacIBMdata);
            wrDACreg(dacIBMind0,dacIBMiId);
            y:=y+256*rdDACreg(dacIBMdata);
            if (y>$FF) and (y<$2FF) then  {Range ??}
            begin
              wrDACreg(dacIBMind0,dacIBMiRev);
              wrDACreg(dacIBMdata,y xor $FF);
              wrDACreg(dacIBMind0,dacIBMiId);
              wrDACreg(dacIBMdata,hi(y) xor $FF);
              wrDACreg(dacIBMind0,dacIBMiRev);
              z:=rdDACreg(dacIBMdata);
              wrDACreg(dacIBMind0,dacIBMiId);
              z:=z+256*rdDACreg(dacIBMdata);
              if (y=z) then
              begin
                case y of
                  $2F0:SetDAC(_dacIBM524,'IBM RGB524');
                else SetDAC(_dacIBM524,'Unknown IBM RGB');
                end;
                cv.clktype:=clk_IBM52x;
              end
              else begin
                wrDACreg(dacIBMind0,dacIBMiRev);
                wrDACreg(dacIBMdata,y);
                wrDACreg(dacIBMind0,dacIBMiId);
                wrDACreg(dacIBMdata,hi(y));
              end;
            end
          end;
        end;
      end;

      if cv.dactype=_dac8 then
      begin
        wrDACreg(dacSTDwrInx,0);  {Force the Bt485 status register}
        wrDACreg(dacBTcmd0,rdDACreg(dacBTcmd0) and $7F);
        x:=rdDACreg(dacBTstat);
        case x and $F0 of
          $40:setDAC(_dacATT504,'AT&T20c504');
          $D0:setDAC(_dacATT505,'AT&T20c505');
     $80..$B0:begin
                y:=rdDACreg(dacBTcmd0);
                wrDACreg(dacBTcmd0,y or $80);  {Enable STat/Cmd3}
                wrDACreg(dacSTDwrInx,1);  {Force the cmd3 reg}
                z:=rdDACreg(dacBTstat);
                if z=x then
                begin
                  wrDACreg(dacBTstat,x xor $55);
                  wrDACreg(dacSTDwrInx,0);  {Force the stat reg}
                  v:=rdDACreg(dacBTstat);
                  wrDACreg(dacSTDwrInx,1);  {Force the stat reg}
                  wrDACreg(dacBTstat,z);
                  if v=x then z:=x+1;  {Ie. Bt485}
                end;
                wrDACreg(dacBTcmd0,y);
                if x=z then setDAC(_dacBT484,'Bt484')
                       else setDAC(_dacBT485,'Bt485');
              end;
        else
          x:=rdDACreg(0);
          y:=rdDACreg(4);
          wrDACreg(0,x XOR $FF);
          if rdDACreg(4)<>y then setDAC(_dacBT477,'Bt477');
                            {else setDAC(_dacIBM525,'IBM RGB525')}

        end;
      end;
    end;
    wrDACreg(dacSTDpelMask,oldpel);
  end;
  clearDACpage;



  if cv.dactype=_dac8 then
  begin
    WaitforRetrace;
    outp($3C8,222);
    outp($3C9,$43);
    outp($3C9,$45);
    outp($3C9,$47);    {Write 'CEGEDSUN' + mode to DAC index 222}
    outp($3C8,222);
    outp($3C9,$45);
    outp($3C9,$44);
    outp($3C9,$53);
    outp($3C8,222);
    outp($3C9,$55);
    outp($3C9,$4E);
    outp($3C9,13);     {Should be in CEG mode now}
    outp($3C6,255);
    x:=(inp($3c6) shr 4) and 7;
    if x<7 then
    begin
      setDAC(_dacCEG,'Edsun CEG rev. '+chr(x+48));
      WaitforRetrace;
      outp($3C8,223);
      outp($3C9,0);    {Back in normal dac mode}
    end;
  end;
end;


procedure findbios;     {Finds the most likely BIOS segment}
var
  score:array[0..7] of byte;
  x,y:word;
begin
  biosseg:=$c000;
  for x:=0 to 6 do score[x]:=1;
  for x:=0 to 7 do
  begin
    rp.bh:=x;
    vio($1130);
    if (rp.es>=$c000) and ((rp.es and $7ff)=0) then
      inc(score[(rp.es-$c000) shr 11]);
  end;

  for x:=0 to 6 do
  begin
    y:=$c000+(x shl 11);
    if (memw[y:0]<>$aa55) or (mem[y:2]<48) then
      score[x]:=0;                       {fail if no rom}
  end;
  for x:=6 downto 0 do
    if score[x]>0 then
      biosseg:=$c000+(x shl 11);
end;

type
  fnctyp=procedure;

const
  chps=30;
  chptype:array[1..chps] of byte=(__chips,__WD,__Video7
            ,__Everex,__Trid,__ati,__Ahead,__NCR,__S3,__ALG,__ARK
            ,__Cir54,__Cir64,__MXIC,__UMC,__Genoa,__Weitek,__SIS
            ,__Tseng,__Realtek,__P2000,__Acer,__SC,__Alli
            ,__Yamaha ,__Matrox,__Oak,__Cirrus,__Compaq,__HMC);

(* Known test ordering requirements:

  UMC before Genoa, otherwise the UMC will be ID'd as Genoa 6400
  C&T before HMC, as HMC test disturbs C&T
  MXIC before Tseng, as Tseng test disturbs MXIC
  SiS before Tseng, as the SiS will be ID'd as a Tseng
*)


procedure findvideo;
var  old,chp,vid1:word;

begin
  vids:=0;
  cv.dactype:=_dac0;
  cv.features:=0;
  cv.flags:=0;
  if odd(inp($3CC)) then CRTC:=$3D4 else CRTC:=$3B4;
  if dotest[__VESA] then _vesa;
  if dotest[__XBE] then _xbe;
  if dotest[__XGA] then _XGA;
  _Imagine;

  _crt:='';
  cv.chip:=__none;
  secondary:='';
  cv.name:='';
  video:='none';
  rp.bx:=$1010;
  vio($1200);
  if rp.bh<=1 then
  begin
    video:='EGA';
    cv.chip:=__ega;

    cv.mm:=rp.bl;
    vio($1a00);
    if rp.al=$1a then
    begin
      if (rp.bl<4) and (rp.bh>3) then
      begin
	old:=rp.bl;
	rp.bl:=rp.bh;
	rp.bh:=old;
      end;
      video:='MCGA';
      case rp.bl of
	2,4,6,10:_crt:='TTL Color';
	1,5,7,11:_crt:='Monochrome';
	    8,12:_crt:='Analog Color';
      end;
      case rp.bh of
	1:secondary:='Monochrome';
	2:secondary:='CGA';
      end;
      findbios;
      if (getbios($31,9)='') and (getbios($40,2)='22') then
      begin
	video:='EGA';       {@#%@  lying ATI EGA Wonder !}
	cv.name:='ATI EGA Wonder';
	addvideo;
      end else
      if (rp.bl<10) or (rp.bl>12) then
      begin
        _MediaVis;
	chp:=0;vid1:=vids;
	while (vids=vid1) and (chp<chps) do
	begin
	  inc(chp);

	  video:='VGA';
	  cv.chip:=__vga;
	  cv.mm:=256;
	  cv.features:=0;
	  cv.dactype:=_dac0;
	  cv.version:=0;
	  cv.subvers:=0;
          cv.clktype:=clk_ext2;
          cv.flags:=FLG_StdVGA;
	  if debug then
	  begin
	    writeln('Testing: '+header[chptype[chp]]);
	    if readkey='' then;
	  end;
	  if dotest[chptype[chp]] then
            case chptype[chp] of
                __Acer:_Acer;
               __Ahead:_Ahead;
                 __ALG:_ALG;
                __Alli:_Alliance;
                 __ARK:_ARK;
                 __ati:_Ati;
               __chips:_chipstech;
               __Cir54:_Cirrus54;
               __Cir64:_Cirrus64;
              __Cirrus:_Cirrus;
              __Compaq:_Compaq;
              __Everex:_Everex;
               __Genoa:_Genoa;
                 __HMC:_HMC;
                __MXIC:_MXIC;
                 __NCR:_NCR;
                 __Oak:_Oak;
               __P2000:_P2000;
                  __WD:_paradise;
             __Realtek:_Realtek;
                  __S3:_S3;
                  __SC:_Sierra;
                 __SiS:_SiS;
                __Trid:_Trident;
               __Tseng:_Tseng;
                 __UMC:_UMC;
              __Video7:_Video7;
              __Weitek:_weitek;
              __Yamaha:_Yamaha;
              __Matrox:_matrox;
            end;
	end;
	if vids=vid1 then
        begin
          if force_chip<>__none then cv.chip:=force_chip;
          addvideo;
        end;
      end;
    end;
  end;
end;

begin
end.
