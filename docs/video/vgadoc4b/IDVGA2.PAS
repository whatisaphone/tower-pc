
{$i VGADECL.INC}      {Common definitions}


type
  modetype=record
             md,xres,yres,bytes:word;
             memmode:byte;
             flags:byte;
           end;




type
  intarr=array[1..100] of word;



  {VESA VBE (VGA) record definitions}
  _vbe0=record
          sign  :longint;       {Must be 'VESA'}
          vers  :word;          {VBE version.}
          oemadr:^char;
          capab :longint;
          model :^intarr;       {Ptr to list of modes}
          mem   :byte;          {#64k blocks}
          xx:array[0..499] of byte;   {Buffer is too large, as some cards
                                         can return more than 256 bytes}
        end;


  _vbe1=record
          attr  :word;
          wina  :byte;
          winb  :byte;
          gran  :word;
          winsiz:word;
          sega  :word;
          segb  :word;
          pagefunc:pointer;
          bytes :word;
          width :word;
          height:word;
          charw :byte;
          charh :byte;
          planes:byte;
          bits  :byte;   {bits per pixel}
          nbanks:byte;
          model :byte;
          banks :byte;
          images:byte;
          res   :byte;
          redinf:word;   {red   - low byte = #bits, high byte = start pos}
          grninf:word;   {green - }
          bluinf:word;   {blue  - }
          resinf:word;

          x:array[0..255] of byte;    {might get trashed by 4F01h}
        end;
  _vbe1p=^_vbe1;


  {VESA VXE (XGA) record definitions}
  _xbe0=record
          sign:longint;    {must be 'VESA'}
          vers:word;
          oemadr:^char;
          capab:longint;
          xgas:word;
          xx:array[1..240] of byte;
        end;

  _xbe1=record
          oemadr:^char;
          capab:longint;
          romadr:longint;
          memreg:longint;
          iobase:word;
          vidadr:longint;  {32bit address of video memory}
          adr4MB:longint;
          adr1MB:longint;
          adr64k:longint;
          adroem:longint;
          sizoem:word;
          modep :^intarr;
          memory:word;
          manid :longint;
          xx:array[1..206] of byte;
        end;

  _xbe2=record
          attrib:word;
          bytes :word;
          pixels:word;
          lins  :word;
          charw :byte;
          charh :byte;
          planes:byte;
          bits  :byte;
          model :byte;
          images:byte;
          redinf:word;   {red   - low byte = #bits, high byte = start pos}
          grninf:word;   {green - }
          bluinf:word;   {blue  - }
          resinf:word;
          xx:array[1..234] of byte;
        end;

const
  ATTR= $3C0;
  SEQ = $3C4;
  GRC = $3CE;



const

  { Chip sub-versions }

  VS_VBE      =   90;
  VS_XBE      =   91;

  CL_Unk54    =  100;
  CL_AVGA1    =  101;
  CL_AVGA2    =  102;
  CL_GD5401   =  103;
  CL_GD5402   =  104;
  CL_GD5402r1 =  105;
  CL_GD5420   =  106;
  CL_GD5420r1 =  107;
  CL_GD5422   =  108;
  CL_GD5424   =  109;
  CL_GD5426   =  110;
  CL_GD5428   =  111;
  CL_GD5429   =  112;
  CL_GD5430   =  113;
  CL_GD5434   =  114;
  CL_GD7541   =  115;    {Nordic Lite}
  CL_GD7542   =  116;    {Nordic}
  CL_GD7543   =  117;    {Viking}


  CL_GD6205   =  201;
  CL_GD6215   =  202;
  CL_GD6225   =  203;
  CL_GD6235   =  204;

  CL_Unk64    =  300;
  CL_GD5410   =  301;
  CL_GD6410   =  302;
  CL_GD6412   =  303;
  CL_GD6420A  =  304;
  CL_GD6420B  =  305;
  CL_GD6440   =  306;

  WD_PVGA1A   =  401;
  WD_90c00    =  402;
  WD_90c10    =  403;
  WD_90c11    =  404;
  WD_90c20    =  405;
  WD_90c20A   =  406;
  WD_90c22    =  407;
  WD_90c24    =  408;
  WD_90c26    =  409;
  WD_90c30    =  410;
  WD_90c31    =  411;
  WD_90c33    =  412;

  CT_Unknown  =  500;
  CT_451      =  501;
  CT_455      =  502;
  CT_456      =  503;
  CT_457      =  504;
  CT_452      =  505;
  CT_450      =  506;
  CT_453      =  507;
  CT_65520    =  508;
  CT_65530    =  509;
  CT_65510    =  510;
  CT_65535    =  511;
  CT_65540    =  512;
  CT_65545    =  513;
  CT_64200    =  514;
  CT_64300    =  515;
  CT_64310    =  516;

  CL_old_unk  =  600;  {CL-GD410/420}
  CL_V7_OEM   =  601;
  CL_GD5x0    =  602;
  CL_GD6x0    =  603;

  NCR_Unknown =  700;
  NCR_77c21   =  701;
  NCR_77c22   =  702;
  NCR_77c22e  =  703;
  NCR_77c22ep =  704;
  NCR_77c32BLT=  705;

  OAK_Unknown =  800;
  OAK_037     =  801;
  OAK_057     =  802;
  OAK_067     =  803;
  OAK_077     =  804;
  OAK_083     =  805;
  OAK_087     =  806;

  RT_Unknown  =  900;
  RT_3103     =  901;
  RT_3105     =  902;
  RT_3106     =  903;

  S3_Unknown  = 1000;
  S3_911      = 1001;
  S3_924      = 1002;
  S3_801AB    = 1003;
  S3_805AB    = 1004;
  S3_801C     = 1005;
  S3_805C     = 1006;
  S3_801D     = 1007;
  S3_805D     = 1008;
  S3_801I     = 1009;
  S3_805I     = 1010;
  S3_801P     = 1011;
  S3_805P     = 1012;
  S3_928      = 1013;
  S3_928C     = 1014;
  S3_928D     = 1015;
  S3_928E     = 1016;
  S3_928PCI   = 1017;
  S3_864      = 1018;
  S3_864P     = 1019;
  S3_964      = 1020;
  S3_732      = 1021;  {Trio32}
  S3_764      = 1022;  {Trio64}
  S3_866      = 1023;
  S3_868      = 1024;  {Don't know if these should be above the Trio's yet?}
  S3_968      = 1025;

  TR_Unknown  = 1100;
  TR_8800BR   = 1101;
  TR_8800CS   = 1102;
  TR_8900B    = 1103;
  TR_8900C    = 1104;
  TR_9000     = 1105;
  TR_LCD9100B = 1106;
  TR_LX8200   = 1107;
  TR_LCD9320  = 1108;
  TR_IITAGX   = 1109;
  TR_9000i    = 1110;
  TR_9000C    = 1111;
  TR_8900CL   = 1112;
  TR_9200CXr  = 1113;
  TR_9400CXi  = 1114;
  TR_GUI9420  = 1115;
  TR_GUI9430  = 1116;
  TR_GUI9440  = 1117;
  TR_GUI9660  = 1118;
  TR_GUI9680  = 1119;

  AH_A        = 1201;
  AH_B        = 1202;

  ALG_Unknown = 1300;
  ALG_2101    = 1301;
  ALG_2201    = 1302;
  ALG_2228    = 1303;
  ALG_2301    = 1304;
  ALG_2302    = 1305;
  ALG_2364    = 1306;

  CPQ_Unknown = 1400;
  CPQ_AVPORT  = 1401;
  CPQ_IVGS    = 1402;
  CPQ_AVGA    = 1403;
  CPQ_QV      = 1404;   {The original}
  CPQ_QV1024  = 1405;
  CPQ_QV1280  = 1406;

  MX_86000    = 1501;
  MX_86010    = 1502;
  MX_86100    = 1503;

  GE_5100     = 1601;
  GE_5300     = 1602;
  GE_6100     = 1603;
  GE_6200     = 1604;
  GE_6400     = 1605;

  PR_2000     = 1701;

  IIT_AGX1x   = 1801;
  IIT_AGX14   = 1802;
  IIT_AGX15   = 1803;
  IIT_AGX16   = 1804;
  IIT_AGX17   = 1805;   {Does the AGX-017 really exist?}

  ET_4Unk     = 1900;
  ET_3000     = 1901;
  ET_4000     = 1902;
  ET_4W32     = 1903;
  ET_4W32i_a  = 1904;
  ET_4W32i_b  = 1905;
  ET_4W32i_c  = 1906;
  ET_4W32p_a  = 1907;
  ET_4W32p_b  = 1908;
  ET_4W32p_c  = 1909;
  ET_4W32p_d  = 1910;

  V7_Unknown  = 2000;
  V7_VEGA     = 2001;
  V7_208_13   = 2002;
  V7_208A     = 2003;
  V7_208B     = 2004;
  V7_208CD    = 2005;
  V7_216BC    = 2006;
  V7_216D     = 2007;
  V7_216E     = 2008;
  V7_216F     = 2009;

  WT_Unk      = 2110;
  WT_5086     = 2111;
  WT_5186     = 2112;
  WT_5286     = 2113;
  WT_P9100    = 2114;  {P9100 VGA part}

  YA_6388     = 2201;

  XGA_org     = 2301;
  XGA_NI      = 2302;

  UMC_408     = 2401;
  UMC_418     = 2402;

  ATI_Unknown = 2500;
  ATI_EGA     = 2501;
  ATI_18800   = 2502;
  ATI_18800_1 = 2503;
  ATI_28800_2 = 2504;
  ATI_28800_4 = 2505;
  ATI_28800_5 = 2506;
  ATI_28800_6 = 2507;
  ATI_GUP_3   = 2508;
  ATI_GUP_6   = 2509;
  ATI_GUP_AX  = 2510;
  ATI_GUP_LX  = 2511;
  ATI_M32_Unk = 2512;
  ATI_M64_GX  = 2513;
  ATI_M64_CX  = 2514;
  ATI_M64_Unk = 2515;

  HMC_304     = 2601;
  HMC_314     = 2602;

  MGA_Unknown = 2700;
  MGA_VGA     = 2701;  {The VGA part of the MGA chipset}
  MGA_Titan   = 2702;  {Ultima (Titan+Dubic)}
  MGA_Helena  = 2703;  {Impression Lite/Plus (Helena)}

  ARK_Unknown = 2800;
  ARK_1000VL  = 2801;
  ARK_1000PV  = 2802;
  ARK_2000PV  = 2803;

  AC_CAT32    = 2901;  {Acer ALi CAT/32 - M3135?}
  AC_CAT64    = 2902;                    {M3145?}

  SC_Unknown  = 3000;
  SC_15064    = 3001;  {Sierra Falcon/64}

  MV_PG1024   = 3101;  {Pro Graphics 1024}
  MV_PG1280   = 3102;

  ALi_3210    = 3201;  {Alliance Pro Motion 3210}

  IMG_128     = 3301;  {Imagine-128}

  SIS_201     = 3401;


    {Tseng 4000 subversions}
  TS_SpeedStar = 1;
  TS_Genoa7900 = 2;



  novgamodes=14;
  stdmodetbl:array[1..novgamodes] of modetype=
     ((md: 0;xres: 40;yres: 25;bytes: 80;memmode:_TEXT;flags:MFL_enVGA)
     ,(md: 1;xres: 40;yres: 25;bytes: 80;memmode:_TEXT;flags:MFL_enVGA)
     ,(md: 2;xres: 80;yres: 25;bytes:160;memmode:_TEXT;flags:MFL_enVGA)
     ,(md: 3;xres: 80;yres: 25;bytes:160;memmode:_TEXT;flags:MFL_enVGA)
     ,(md: 4;xres:320;yres:200;bytes: 80;memmode:_cga2;flags:MFL_enVGA)
     ,(md: 5;xres:320;yres:200;bytes: 80;memmode:_cga2;flags:MFL_enVGA)
     ,(md: 6;xres:640;yres:200;bytes: 80;memmode:_cga1;flags:MFL_enVGA)
     ,(md:13;xres:320;yres:200;bytes: 40;memmode:_pl4 ;flags:MFL_enGrVGA)
     ,(md:14;xres:640;yres:200;bytes: 80;memmode:_pl4 ;flags:MFL_enGrVGA)
     ,(md:15;xres:640;yres:350;bytes: 80;memmode:_pl1 ;flags:MFL_enVGA)
     ,(md:16;xres:640;yres:350;bytes: 80;memmode:_pl4 ;flags:MFL_enGrVGA)
     ,(md:17;xres:640;yres:480;bytes: 80;memmode:_pl1 ;flags:MFL_enVGA)
     ,(md:18;xres:640;yres:480;bytes: 80;memmode:_pl4 ;flags:MFL_enGrVGA)
     ,(md:19;xres:320;yres:200;bytes:320;memmode:_p8  ;flags:MFL_enGrVGA));

  colbits:array[1..max_mode] of integer=   {Bits of data per pixel}
               (0,0,0,1,1,1,1,2,2,2,4,4,4,4,8,15,16,24,24,24,24,24,24);
  usebits:array[1..max_mode] of integer=   {Bits used per pixel}
               (0,0,0,1,1,1,1,2,2,2,4,4,4,4,8,16,16,24,24,32,32,32,32);
  modecols:array[1..max_mode] of longint=
               (0,0,0,2,2,2,2,4,4,4,16,16,16,16,256,32768,65536
               ,16777216,16777216,16777216,16777216,16777216,16777216);

  mdtxt:array[1..max_mode] of string[20]=('Text','2 color Text','4 color Text'
                ,'Hercules','CGA 2 color','CGA 4 color','Monochrome','2 colors planar'
                ,'4 colors planar','4 colors packed','16 colors planar','16 colors packed'
                ,'16 colors packed','16 colors packed','256 colors packed','32K colors','64K colors'
                ,'16M colors','16M colors'
                ,'16M col(RGBa)','16M col(BGRa)','16M col(aRGB)','16M col(aBGR)');

  mmodenames:array[1..max_mode] of string[4]=('TXT ','TXT2','TXT4','HERC','CGA1','CGA2'
              ,'PL1 ','PL1E','PL2 ','PK2 ','PL4 ','PK4 ','PK4A;','PK4B','P8  ','P15 ','P16 '
              ,'P24 ','P24b','P32 ','P32b','P32c','P32d');





const






  dacSTDwrInx    =  0;  {3C8h}
  dacSTDpelData  =  1;  {3C9h}
  dacSTDpelMask  =  2;  {3C6h}
  dacSTDrdInx    =  3;  {3C7h}

  dacHIcmd      =  6;  {Command register}


  dacTVPindex   =  6;  {TI TVP 3020/5 index register}
  dacTVPdata    =  7;  {     --       data register}

  dacTVP6index  =  0;  {TI TVP 3026 index register}
  dacTVP6data   = 10;  {     --       data register}

  dacTLCtest    = 14;  {TI TLC 34075 test register}


  dacBT1cwrInx  =  4;  {Cursor Wr Addr}
  dacBT1cData   =  5;  {Cursor Data}
  dacBT1cmdA    =  6;  {Command Reg A}
  dacBT1crdInx  =  7;  {Cursor Rd Addr}
  dacBTIipixm   =  0;  {Indexed: Ind Pixel Mask}
  dacBTIovrl    =  1;  {Indexed: Overlay Mask}
  dacBTIcmdB    =  2;  {Indexed: Command B}
  dacBTIcur     =  3;  {Indexed: Cursor}
  dacBTIcurX    =  4;  {Indexed: Cursor X}
  dacBTIcurY    =  6;  {Indexed: Cursor Y}

      {Bt484/5, ATT504/5 series}
  dacBTcwrInx   =  4;
  dacBTcData    =  5;
  dacBTcmd0     =  6;  {Cmd reg 0}
  dacBTcrdInx   =  7;  {Cursor Rd Addr}
  dacBTcmd1     =  8;
  dacBTcmd2     =  9;
  dacBTstat     = 10;  {Status/Cmd3 register}
  dacBTcMap     = 11;  {Cursor Map data}
  dacBTcurX     = 12;  {Hardware cursor X position}
  dacBTcurY     = 14;

    {IBM RGB52x series}
  dacIBMind0    =  4;  {Index - low}
  dacIBMind1    =  5;  {Index - high}
  dacIBMdata    =  6;  {Indexed Data}
  dacIBMctrl    =  7;  {Index Control}

  dacIBMiRev    =  0;  {Indexed}
  dacIBMiId     =  1;



type
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
  nomodes:word;
  modetbl:array[1..60] of modetype;   {The complete mode list - disabled}

  noumodes:word;
  usermodes:array[1..50] of modetype;  {Xtra user modes}

  cv:vidinfo;    {The currently selected video system}
  dotest:array[1..max_CHIP] of boolean;
  rgs:regtype;
  vids:word;
  vid:array[1..5] of vidinfo;   {Max 5 video systems }


implementation
uses crt,dos,supervga;


const



  NBRCHIPS=215;

  CHIPSLIST:array[1..NBRCHIPS] of
    record
      nbr:integer;
      nam:string[35];
    end
    =((nbr:VS_VBE      ;nam:'VESA VBE (')
     ,(nbr:VS_XBE      ;nam:'VESA XBE (')

     ,(nbr:CL_Unk54    ;nam:'Unknown Cirrus 54xx (')
     ,(nbr:CL_AVGA1    ;nam:'Acumos AVGA1 (5401)')
     ,(nbr:CL_AVGA2    ;nam:'Acumos AVGA2 (5402)')
     ,(nbr:CL_GD5401   ;nam:'Cirrus CL-GD5401')
     ,(nbr:CL_GD5402   ;nam:'Cirrus CL-GD5402')
     ,(nbr:CL_GD5402r1 ;nam:'Cirrus CL-GD5402 rev 1')
     ,(nbr:CL_GD5420   ;nam:'Cirrus CL-GD5420')
     ,(nbr:CL_GD5420r1 ;nam:'Cirrus CL-GD5420 rev 1')
     ,(nbr:CL_GD5422   ;nam:'Cirrus CL-GD5422')
     ,(nbr:CL_GD5424   ;nam:'Cirrus CL-GD5424')
     ,(nbr:CL_GD5426   ;nam:'Cirrus CL-GD5426')
     ,(nbr:CL_GD5428   ;nam:'Cirrus CL-GD5428')
     ,(nbr:CL_GD5429   ;nam:'Cirrus CL-GD5429')
     ,(nbr:CL_GD5430   ;nam:'Cirrus CL-GD5430')
     ,(nbr:CL_GD5434   ;nam:'Cirrus CL-GD5434')
     ,(nbr:CL_GD7541   ;nam:'Cirrus CL-GD7541 (Nordic Lite)')
     ,(nbr:CL_GD7542   ;nam:'Cirrus CL-GD7542 (Nordic)')
     ,(nbr:CL_GD7543   ;nam:'Cirrus CL-GD7543 (Viking)')

     ,(nbr:CL_GD6205   ;nam:'Cirrus CL-GD6205')
     ,(nbr:CL_GD6215   ;nam:'Cirrus CL-GD6215')
     ,(nbr:CL_GD6225   ;nam:'Cirrus CL-GD6225')
     ,(nbr:CL_GD6235   ;nam:'Cirrus CL-GD6235')

     ,(nbr:CL_Unk64    ;nam:'Unknown Cirrus 64xx (')
     ,(nbr:CL_GD5410   ;nam:'Cirrus CL-GD5410')
     ,(nbr:CL_GD6410   ;nam:'Cirrus CL-GD6410')
     ,(nbr:CL_GD6412   ;nam:'Cirrus CL-GD6412')
     ,(nbr:CL_GD6420A  ;nam:'Cirrus CL-GD6420A')
     ,(nbr:CL_GD6420B  ;nam:'Cirrus CL-GD6420B')
     ,(nbr:CL_GD6440   ;nam:'Cirrus CL-GD6440')

     ,(nbr:WD_PVGA1A   ;nam:'Paradise PVGA1A')
     ,(nbr:WD_90c00    ;nam:'Paradise WD90c00')
     ,(nbr:WD_90c10    ;nam:'Paradise WD90c10')
     ,(nbr:WD_90c11    ;nam:'Paradise WD90c11')
     ,(nbr:WD_90c20    ;nam:'Paradise WD90c20')
     ,(nbr:WD_90c20A   ;nam:'Paradise WD90c20A')
     ,(nbr:WD_90c22    ;nam:'Paradise WD90c22')
     ,(nbr:WD_90c24    ;nam:'Paradise WD90c24')
     ,(nbr:WD_90c26    ;nam:'Paradise WD90c26')
     ,(nbr:WD_90c30    ;nam:'Paradise WD90c30')
     ,(nbr:WD_90c31    ;nam:'Paradise WD90c31')
     ,(nbr:WD_90c33    ;nam:'Paradise WD90c33')

     ,(nbr:CT_Unknown  ;nam:'Unknown Chips&Tech (')
     ,(nbr:CT_451      ;nam:'Chips&Tech 82c451')
     ,(nbr:CT_455      ;nam:'Chips&Tech 82c455')
     ,(nbr:CT_456      ;nam:'Chips&Tech 82c456')
     ,(nbr:CT_457      ;nam:'Chips&Tech 82c457')
     ,(nbr:CT_452      ;nam:'Chips&Tech 82c452')
     ,(nbr:CT_450      ;nam:'Chips&Tech 82c450')
     ,(nbr:CT_453      ;nam:'Chips&Tech 82c453')
     ,(nbr:CT_65520    ;nam:'Chips&Tech F65520')
     ,(nbr:CT_65530    ;nam:'Chips&Tech F65530')
     ,(nbr:CT_65510    ;nam:'Chips&Tech F65510')
     ,(nbr:CT_65535    ;nam:'Chips&Tech F65535')
     ,(nbr:CT_65540    ;nam:'Chips&Tech F65540')
     ,(nbr:CT_65545    ;nam:'Chips&Tech F65545')
     ,(nbr:CT_64200    ;nam:'Chips&Tech 64200')
     ,(nbr:CT_64300    ;nam:'Chips&Tech 64300')

     ,(nbr:CL_old_unk  ;nam:'Unknown Old Cirrus (')
     ,(nbr:CL_V7_OEM   ;nam:'Cirrus V7 OEM')
     ,(nbr:CL_GD5x0    ;nam:'Cirrus 510/520')
     ,(nbr:CL_GD6x0    ;nam:'Cirrus 610/620')

     ,(nbr:NCR_Unknown ;nam:'Unknown NCR (')
     ,(nbr:NCR_77c21   ;nam:'NCR 77c21')
     ,(nbr:NCR_77c22   ;nam:'NCR 77c22')
     ,(nbr:NCR_77c22e  ;nam:'NCR 77c22e')
     ,(nbr:NCR_77c22ep ;nam:'NCR 77c22e+')
     ,(nbr:NCR_77c32BLT;nam:'NCR 77c32BLT')

     ,(nbr:OAK_Unknown ;nam:'Unknown OAK (')
     ,(nbr:OAK_037     ;nam:'OAK-037C')
     ,(nbr:OAK_057     ;nam:'OAK-057')
     ,(nbr:OAK_067     ;nam:'OAK-067')
     ,(nbr:OAK_077     ;nam:'OAK-077')
     ,(nbr:OAK_083     ;nam:'OAK-083')
     ,(nbr:OAK_087     ;nam:'OAK-087')

     ,(nbr:RT_Unknown  ;nam:'Unknown Realtek (')
     ,(nbr:RT_3103     ;nam:'Realtek RT3103')
     ,(nbr:RT_3105     ;nam:'Realtek 3105')
     ,(nbr:RT_3106     ;nam:'Realtek 3106')

     ,(nbr:S3_Unknown  ;nam:'Unknown S3 (')
     ,(nbr:S3_911      ;nam:'S3 86c911')
     ,(nbr:S3_924      ;nam:'S3 86c911A/924')
     ,(nbr:S3_801AB    ;nam:'S3 86c801A/B')
     ,(nbr:S3_805AB    ;nam:'S3 86c805A/B')
     ,(nbr:S3_801C     ;nam:'S3 86c801C')
     ,(nbr:S3_805C     ;nam:'S3 86c805C')
     ,(nbr:S3_801D     ;nam:'S3 86c801D')
     ,(nbr:S3_805D     ;nam:'S3 86c805D')
     ,(nbr:S3_801I     ;nam:'S3 86c801i')
     ,(nbr:S3_805I     ;nam:'S3 86c805i')
     ,(nbr:S3_801P     ;nam:'S3 86c801p')
     ,(nbr:S3_805P     ;nam:'S3 86c805p')
     ,(nbr:S3_928      ;nam:'S3 86c928')
     ,(nbr:S3_928C     ;nam:'S3 86c928C')
     ,(nbr:S3_928D     ;nam:'S3 86c928D')
     ,(nbr:S3_928E     ;nam:'S3 86c928E')
     ,(nbr:S3_928PCI   ;nam:'S3 86c928P')
     ,(nbr:S3_864      ;nam:'S3 Vision864')
     ,(nbr:S3_864P     ;nam:'S3 Vision864P')
     ,(nbr:S3_964      ;nam:'S3 Vision964')
     ,(nbr:S3_732      ;nam:'S3 Trio32 (732)')
     ,(nbr:S3_764      ;nam:'S3 Trio64 (764)')
     ,(nbr:S3_866      ;nam:'S3 86c866')
     ,(nbr:S3_868      ;nam:'S3 86c868')
     ,(nbr:S3_968      ;nam:'S3 86c968')

     ,(nbr:TR_Unknown  ;nam:'Unknown Trident (')
     ,(nbr:TR_8800BR   ;nam:'Trident TVGA8800BR')
     ,(nbr:TR_8800CS   ;nam:'Trident TVGA8800CS')
     ,(nbr:TR_8900B    ;nam:'Trident TVGA8900B')
     ,(nbr:TR_8900C    ;nam:'Trident TVGA8900C')
     ,(nbr:TR_9000     ;nam:'Trident TVGA9000')
     ,(nbr:TR_9000i    ;nam:'Trident TVGA9000i')
     ,(nbr:TR_LCD9100B ;nam:'Trident LCD9100B')
     ,(nbr:TR_LX8200   ;nam:'Trident LX8200')
     ,(nbr:TR_LCD9320  ;nam:'Trident LCD9320')
     ,(nbr:TR_IITAGX   ;nam:'(IIT AGX builtin)')
     ,(nbr:TR_9000C    ;nam:'Trident TVGA9000C')
     ,(nbr:TR_8900CL   ;nam:'Trident TVGA8900CL')
     ,(nbr:TR_9200CXr  ;nam:'Trident TGUI9200CXr')
     ,(nbr:TR_9400CXi  ;nam:'Trident TGUI9400CXi')
     ,(nbr:TR_GUI9420  ;nam:'Trident TGUI9420DGi')
     ,(nbr:TR_GUI9430  ;nam:'Trident TGUI9430')
     ,(nbr:TR_GUI9440  ;nam:'Trident TGUI9440AGi')
     ,(nbr:TR_GUI9660  ;nam:'Trident TGUI9660XGi')

     ,(nbr:AH_A        ;nam:'Ahead V5000A')
     ,(nbr:AH_B        ;nam:'Ahead V5000B')

     ,(nbr:ALG_Unknown ;nam:'Unknown Avance Logic (')
     ,(nbr:ALG_2101    ;nam:'Avance Logic ALG2101')
     ,(nbr:ALG_2201    ;nam:'Avance Logic ALG2201')
     ,(nbr:ALG_2228    ;nam:'Avance Logic ALG2228')
     ,(nbr:ALG_2301    ;nam:'Avance Logic ALG2301')

     ,(nbr:CPQ_Unknown ;nam:'Unknown Compaq (')
     ,(nbr:CPQ_AVPORT  ;nam:'Compaq Adv VGA Port')
     ,(nbr:CPQ_IVGS    ;nam:'Compaq IVGS')
     ,(nbr:CPQ_AVGA    ;nam:'Compaq AVGA')
     ,(nbr:CPQ_QV      ;nam:'Compaq QVision')
     ,(nbr:CPQ_QV1024  ;nam:'Compaq QVision 1024')
     ,(nbr:CPQ_QV1280  ;nam:'Compaq QVision 1280')

     ,(nbr:MX_86000    ;nam:'MXIC MX86000')
     ,(nbr:MX_86010    ;nam:'MXIC MX86010')
     ,(nbr:MX_86100    ;nam:'MXIC MX86100')

     ,(nbr:GE_5100     ;nam:'Genoa 51/5200 (Tseng)')
     ,(nbr:GE_5300     ;nam:'Genoa 53/5400 (Tseng)')
     ,(nbr:GE_6100     ;nam:'Genoa 6100')
     ,(nbr:GE_6200     ;nam:'Genoa 62/6300')
     ,(nbr:GE_6400     ;nam:'Genoa 64/6600')

     ,(nbr:PR_2000     ;nam:'Primus P2000')

     ,(nbr:IIT_AGX1x   ;nam:'IIT AGX-010/1')
     ,(nbr:IIT_AGX14   ;nam:'IIT AGX-014')
     ,(nbr:IIT_AGX15   ;nam:'IIT AGX-015')
     ,(nbr:IIT_AGX16   ;nam:'IIT AGX-016')
     ,(nbr:IIT_AGX17   ;nam:'IIT AGX-017')

     ,(nbr:ET_4Unk     ;nam:'Unknown Tseng ET4000W32 (')
     ,(nbr:ET_3000     ;nam:'Tseng ET3000')
     ,(nbr:ET_4000     ;nam:'Tseng ET4000')
     ,(nbr:ET_4W32     ;nam:'Tseng ET4000W32')
     ,(nbr:ET_4W32i_a  ;nam:'Tseng ET4000W32i rev A')
     ,(nbr:ET_4W32i_b  ;nam:'Tseng ET4000W32i rev B')
     ,(nbr:ET_4W32i_c  ;nam:'Tseng ET4000W32i rev C')
     ,(nbr:ET_4W32p_a  ;nam:'Tseng ET4000W32p rev A')
     ,(nbr:ET_4W32p_b  ;nam:'Tseng ET4000W32p rev B')
     ,(nbr:ET_4W32p_c  ;nam:'Tseng ET4000W32p rev C')
     ,(nbr:ET_4W32p_d  ;nam:'Tseng ET4000W32p rev D')

     ,(nbr:V7_Unknown  ;nam:'Unknown Video7 (')
     ,(nbr:V7_VEGA     ;nam:'Video7 VEGA VGA')
     ,(nbr:V7_208_13   ;nam:'Video7 HT208 Version 1-3')
     ,(nbr:V7_208A     ;nam:'Video7 HT208 rev A')
     ,(nbr:V7_208B     ;nam:'Video7 HT208 rev B')
     ,(nbr:V7_208CD    ;nam:'Video7 HT208 rev C/D')
     ,(nbr:V7_216BC    ;nam:'Video7 HT216 rev B/C')
     ,(nbr:V7_216D     ;nam:'Video7 HT216 rev D')
     ,(nbr:V7_216E     ;nam:'Video7 HT216 rev E')
     ,(nbr:V7_216F     ;nam:'Video7 HT216 rev F')

     ,(nbr:WT_Unk      ;nam:'Unknown Weitek (')
     ,(nbr:WT_5086     ;nam:'Weitek 5086')
     ,(nbr:WT_5186     ;nam:'Weitek 5186')
     ,(nbr:WT_5286     ;nam:'Weitek 5286')
     ,(nbr:WT_P9100    ;nam:'Weitek P9100')

     ,(nbr:YA_6388     ;nam:'Yamaha VPD6388')

     ,(nbr:XGA_org     ;nam:'IBM XGA')
     ,(nbr:XGA_NI      ;nam:'IBM XGA-NI')

     ,(nbr:UMC_408     ;nam:'UMC UM85C408')
     ,(nbr:UMC_418     ;nam:'UMC UM85C418')

     ,(nbr:ATI_Unknown ;nam:'Unknown ATI (')
     ,(nbr:ATI_EGA     ;nam:'ATI EGA')
     ,(nbr:ATI_18800   ;nam:'ATI VGA Wonder (18800)')
     ,(nbr:ATI_18800_1 ;nam:'ATI VGA Wonder (18800-1)')
     ,(nbr:ATI_28800_2 ;nam:'ATI VGA Wonder (28800-2)')
     ,(nbr:ATI_28800_4 ;nam:'ATI VGA Wonder (28800-4)')
     ,(nbr:ATI_28800_5 ;nam:'ATI VGA Wonder XL (28800-5)')
     ,(nbr:ATI_28800_6 ;nam:'ATI VGA Wonder XL (28800-6)')
     ,(nbr:ATI_GUP_3   ;nam:'ATI Mach32 (68800-3)')
     ,(nbr:ATI_GUP_6   ;nam:'ATI Mach32 (68800-6)')
     ,(nbr:ATI_GUP_AX  ;nam:'ATI Mach32 (68800-AX)')
     ,(nbr:ATI_GUP_LX  ;nam:'ATI Mach32 (68800-LX)')
     ,(nbr:ATI_M32_Unk ;nam:'Unknown ATI Mach32 (')
     ,(nbr:ATI_M64_CX  ;nam:'ATI Mach64 (88800CX)')
     ,(nbr:ATI_M64_GX  ;nam:'ATI Mach64 (88800GX)')
     ,(nbr:ATI_M64_Unk ;nam:'Unknown ATI Mach64 (')

     ,(nbr:HMC_304     ;nam:'HMC HM86304')
     ,(nbr:HMC_314     ;nam:'HMC HM86314')

     ,(nbr:MGA_Unknown ;nam:'Unknown Matrox (')
     ,(nbr:MGA_VGA     ;nam:'Matrox VGA')
     ,(nbr:MGA_Titan   ;nam:'Matrox Ultima')
     ,(nbr:MGA_Helena  ;nam:'Matrox Imp Lite/Plus')

     ,(nbr:ARK_Unknown ;nam:'Unknown ARK (')
     ,(nbr:ARK_1000VL  ;nam:'ARK1000VL')
     ,(nbr:ARK_1000PV  ;nam:'ARK1000PV')
     ,(nbr:ARK_2000PV  ;nam:'ARK2000PV')

     ,(nbr:MV_PG1024   ;nam:'MediaVision Pro Graphics 1024')
     ,(nbr:MV_PG1280   ;nam:'MediaVision Pro Graphics 1280')

     ,(nbr:Ali_3210    ;nam:'Alliance Pro Motion 3210')

     ,(nbr:IMG_128     ;nam:'Imagine-128')

     ,(nbr:SIS_201     ;nam:'SiS SG86c201'));


  NBRMODES=727;
  MODELIST:array[1..NBRMODES] of
    record
      chp :byte;
      md  :word;
      mode:byte;
      xres:integer;
      yres:integer;
      size:integer;
    end
     =((chp:__Ahead   ;md:  $22;mode:_text;xres: 132;yres:  44;size:0)
      ,(chp:__Ahead   ;md:  $23;mode:_text;xres: 132;yres:  25;size:0)
      ,(chp:__Ahead   ;md:  $24;mode:_text;xres: 132;yres:  28;size:0)
      ,(chp:__Ahead   ;md:  $25;mode:_pl4 ;xres: 640;yres: 480;size:0)
      ,(chp:__Ahead   ;md:  $26;mode:_pl4 ;xres: 640;yres: 480;size:0)
      ,(chp:__Ahead   ;md:  $2F;mode:_text;xres: 160;yres:  50;size:0)
      ,(chp:__Ahead   ;md:  $34;mode:_text;xres:  80;yres:  66;size:0)
      ,(chp:__Ahead   ;md:  $50;mode:_txt2;xres: 132;yres:  25;size:0)
      ,(chp:__Ahead   ;md:  $52;mode:_txt2;xres: 132;yres:  44;size:0)
      ,(chp:__Ahead   ;md:  $60;mode:_p8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Ahead   ;md:  $61;mode:_p8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Ahead   ;md:  $62;mode:_p8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Ahead   ;md:  $63;mode:_p8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Ahead   ;md:  $6A;mode:_pl4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Ahead   ;md:  $70;mode:_pl4 ;xres: 720;yres: 396;size:0)
      ,(chp:__Ahead   ;md:  $71;mode:_pl4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Ahead   ;md:  $74;mode:_pl4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Ahead   ;md:  $75;mode:_pl2 ;xres:1024;yres: 768;size:0)
      ,(chp:__Ahead   ;md:  $76;mode:_pl1 ;xres:1024;yres: 768;size:0)

      ,(chp:__Alli    ;md:  $28;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Alli    ;md:  $29;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Alli    ;md:  $58;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Alli    ;md:  $5D;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Alli    ;md:  $38;mode:_PL4 ;xres:1280;yres:1024;size:0)

      ,(chp:__ATI     ;md:  $21;mode:_text;xres: 100;yres:  25;size:0)
      ,(chp:__ATI     ;md:  $22;mode:_text;xres: 100;yres:  30;size:0)
      ,(chp:__ATI     ;md:  $23;mode:_text;xres: 132;yres:  25;size:0)
      ,(chp:__ATI     ;md:  $27;mode:_txt2;xres: 132;yres:  25;size:0)
      ,(chp:__ATI     ;md:  $33;mode:_text;xres: 132;yres:  44;size:0)
      ,(chp:__ATI     ;md:  $37;mode:_txt2;xres: 132;yres:  44;size:0)
      ,(chp:__ATI     ;md:  $53;mode:_pl4 ;xres: 800;yres: 560;size:0)
      ,(chp:__ATI     ;md:  $54;mode:_pl4 ;xres: 800;yres: 600;size:0)
      ,(chp:__ATI     ;md:  $55;mode:_pl4 ;xres:1024;yres: 768;size:0)
      ,(chp:__ATI     ;md:  $58;mode:_text;xres:  80;yres:  33;size:0)
      ,(chp:__ATI     ;md:  $5B;mode:_text;xres:  80;yres:  30;size:0)
      ,(chp:__ATI     ;md:  $61;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__ATI     ;md:  $62;mode:_p8  ;xres: 640;yres: 480;size:0)
      ,(chp:__ATI     ;md:  $63;mode:_p8  ;xres: 800;yres: 600;size:0)
      ,(chp:__ATI     ;md:  $64;mode:_p8  ;xres:1024;yres: 768;size:0)
      ,(chp:__ATI     ;md:  $65;mode:_pk4 ;xres:1024;yres: 768;size:0)
      ,(chp:__ATI     ;md:  $67;mode:_pl2 ;xres:1024;yres: 768;size:0)
      ,(chp:__ATI     ;md:  $6A;mode:_pl4 ;xres: 800;yres: 600;size:0)
      ,(chp:__ATI     ;md:  $72;mode:_p15 ;xres: 640;yres: 480;size:0)
      ,(chp:__ATI     ;md:  $73;mode:_p15 ;xres: 800;yres: 600;size:0)
      ,(chp:__ATI     ;md:  $75;mode:_p24 ;xres: 640;yres: 480;size:2048)  {XL24}

      ,(chp:__ALG     ;md:  $20;mode:_text;xres: 132;yres:  25;size:0)
      ,(chp:__ALG     ;md:  $21;mode:_text;xres: 132;yres:  30;size:0)
      ,(chp:__ALG     ;md:  $22;mode:_text;xres: 132;yres:  43;size:0)
      ,(chp:__ALG     ;md:  $23;mode:_text;xres: 132;yres:  60;size:0)
      ,(chp:__ALG     ;md:  $24;mode:_text;xres:  80;yres:  30;size:0)
      ,(chp:__ALG     ;md:  $25;mode:_text;xres:  80;yres:  43;size:0)
      ,(chp:__ALG     ;md:  $26;mode:_text;xres:  80;yres:  60;size:0)
      ,(chp:__ALG     ;md:  $27;mode:_pl4 ;xres: 960;yres: 720;size:0)
      ,(chp:__ALG     ;md:  $28;mode:_P8  ;xres: 512;yres: 512;size:0)  {2101}
      ,(chp:__ALG     ;md:  $29;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__ALG     ;md:  $2A;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__ALG     ;md:  $2B;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__ALG     ;md:  $2C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__ALG     ;md:  $2D;mode:_PL4 ;xres: 768;yres:1024;size:0)
      ,(chp:__ALG     ;md:  $2E;mode:_P8  ;xres: 768;yres:1024;size:0)
      ,(chp:__ALG     ;md:  $2F;mode:_PL2 ;xres:1024;yres: 768;size:0)
      ,(chp:__ALG     ;md:  $30;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__ALG     ;md:  $31;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__ALG     ;md:  $36;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__ALG     ;md:  $37;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__ALG     ;md:  $40;mode:_P16 ;xres: 320;yres: 200;size:0)
      ,(chp:__ALG     ;md:  $41;mode:_P16 ;xres: 512;yres: 512;size:0)
      ,(chp:__ALG     ;md:  $42;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__ALG     ;md:  $43;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__ALG     ;md:  $44;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__ALG     ;md:  $45;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__ALG     ;md:  $48;mode:_P24 ;xres: 640;yres: 480;size:0)  {2228}
      ,(chp:__ALG     ;md:  $49;mode:_P24 ;xres: 800;yres: 600;size:0)     {2228}

      ,(chp:__chips   ;md:  $20;mode:_PK4 ;xres: 640;yres: 480;size:0)
      ,(chp:__chips   ;md:  $22;mode:_PK4 ;xres: 800;yres: 600;size:0)
      ,(chp:__chips   ;md:  $24;mode:_PK4 ;xres:1024;yres: 768;size:0)
      ,(chp:__chips   ;md:  $28;mode:_PK4 ;xres:1280;yres:1024;size:0)
      ,(chp:__chips   ;md:  $30;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__chips   ;md:  $32;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__chips   ;md:  $34;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__chips   ;md:  $38;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__chips   ;md:  $40;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__chips   ;md:  $41;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__chips   ;md:  $42;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__chips   ;md:  $43;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__chips   ;md:  $44;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__chips   ;md:  $45;mode:_P16 ;xres:1024;yres: 768;size:0)  {64300}
      ,(chp:__chips   ;md:  $50;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__chips   ;md:  $60;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__chips   ;md:  $61;mode:_TEXT;xres: 132;yres:  50;size:0)
      ,(chp:__chips   ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__chips   ;md:  $70;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__chips   ;md:  $71;mode:_PL4 ;xres: 960;yres: 720;size:0)
      ,(chp:__chips   ;md:  $72;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__chips   ;md:  $73;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__chips   ;md:  $74;mode:_PL4 ;xres:1280;yres: 960;size:0)
      ,(chp:__chips   ;md:  $78;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__chips   ;md:  $79;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__chips   ;md:  $7A;mode:_P8  ;xres: 720;yres: 540;size:0)
      ,(chp:__chips   ;md:  $7B;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__chips   ;md:  $7C;mode:_P8  ;xres: 800;yres: 600;size:0)  {c453}
      ,(chp:__chips   ;md:  $7E;mode:_P8  ;xres:1024;yres: 768;size:0)

      {Cirrus 4x0,5x0,5x0}
      ,(chp:__Cirrus  ;md:  $15;mode:_TXT2;xres: 132;yres:  25;size:0)
      ,(chp:__Cirrus  ;md:  $16;mode:_TXT2;xres: 132;yres:  44;size:0)
      ,(chp:__Cirrus  ;md:  $18;mode:_TXT2;xres: 132;yres:  30;size:0)
      ,(chp:__Cirrus  ;md:  $1E;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Cirrus  ;md:  $1F;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Cirrus  ;md:  $20;mode:_TEXT;xres: 132;yres:  44;size:0)
      ,(chp:__Cirrus  ;md:  $22;mode:_TEXT;xres: 132;yres:  30;size:0)
      ,(chp:__Cirrus  ;md:  $31;mode:_TXT2;xres: 100;yres:  37;size:0)
      ,(chp:__Cirrus  ;md:  $40;mode:_PL4 ;xres: 720;yres: 540;size:0)
      ,(chp:__Cirrus  ;md:  $50;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Cirrus  ;md:  $51;mode:_P8  ;xres: 512;yres: 480;size:0)
      ,(chp:__Cirrus  ;md:  $61;mode:_PL4 ;xres: 640;yres: 400;size:0)
      ,(chp:__Cirrus  ;md:  $62;mode:_PL4 ;xres: 640;yres: 450;size:0)
      ,(chp:__Cirrus  ;md:  $63;mode:_PL4 ;xres: 720;yres: 540;size:0)
      ,(chp:__Cirrus  ;md:  $64;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cirrus  ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cirrus  ;md:  $70;mode:_P8  ;xres: 360;yres: 480;size:0)
      ,(chp:__Cirrus  ;md:  $71;mode:_P8  ;xres: 528;yres: 400;size:0)
      ,(chp:__Cirrus  ;md:  $72;mode:_P8  ;xres: 528;yres: 480;size:0)
      ,(chp:__Cirrus  ;md:  $74;mode:_P8  ;xres: 320;yres: 240;size:0)
      ,(chp:__Cirrus  ;md:  $75;mode:_P8  ;xres: 640;yres: 400;size:0)

      {Cirrus 54xx and 62xx}
      ,(chp:__Cir54   ;md:  $14;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Cir54   ;md:  $54;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__Cir54   ;md:  $55;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Cir54   ;md:  $58;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir54   ;md:  $5C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir54   ;md:  $5D;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Cir54   ;md:  $5F;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Cir54   ;md:  $60;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Cir54   ;md:  $64;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__Cir54   ;md:  $65;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir54   ;md:  $66;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__Cir54   ;md:  $67;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir54   ;md:  $68;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__Cir54   ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir54   ;md:  $6C;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__Cir54   ;md:  $6D;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__Cir54   ;md:  $6F;mode:_P16 ;xres: 320;yres: 200;size:0)
      ,(chp:__Cir54   ;md:  $70;mode:_P24 ;xres: 320;yres: 200;size:2048)
      ,(chp:__Cir54   ;md:  $71;mode:_P24 ;xres: 640;yres: 480;size:2048)
      ,(chp:__Cir54   ;md:  $72;mode:_P32 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir54   ;md:  $73;mode:_P32 ;xres:1024;yres: 768;size:0)
      ,(chp:__Cir54   ;md:  $74;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__Cir54   ;md:  $75;mode:_P16 ;xres:1280;yres:1024;size:0)
      ,(chp:__Cir54   ;md:  $76;mode:_P32 ;xres: 640;yres: 480;size:0)
      ,(chp:__Cir54   ;md:  $77;mode:_P24 ;xres:1280;yres:1024;size:0)
      ,(chp:__Cir54   ;md:  $78;mode:_P8  ;xres:1600;yres:1200;size:0)
      ,(chp:__Cir54   ;md:  $79;mode:_P32 ;xres:1152;yres: 870;size:0)

      {Cirrus 64xx}
      ,(chp:__Cir64   ;md:  $2D;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Cir64   ;md:  $2E;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Cir64   ;md:  $2F;mode:_P8  ;xres: 648;yres: 480;size:0)
      ,(chp:__Cir64   ;md:  $30;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir64   ;md:  $37;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Cir64   ;md:  $41;mode:_TEXT;xres: 100;yres:  50;size:0)
      ,(chp:__Cir64   ;md:  $42;mode:_TEXT;xres: 100;yres:  60;size:0)
      ,(chp:__Cir64   ;md:  $44;mode:_TEXT;xres: 100;yres:  25;size:0)
      ,(chp:__Cir64   ;md:  $51;mode:_TEXT;xres: 132;yres:  50;size:0)
      ,(chp:__Cir64   ;md:  $52;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__Cir64   ;md:  $53;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__Cir64   ;md:  $54;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Cir64   ;md:  $64;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Cir64   ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)

      {Compaq}
      ,(chp:__COMPAQ  ;md:  $22;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__COMPAQ  ;md:  $23;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__COMPAQ  ;md:  $27;mode:_TEXT;xres: 132;yres:  50;size:0)
      ,(chp:__COMPAQ  ;md:  $28;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__COMPAQ  ;md:  $29;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__COMPAQ  ;md:  $2E;mode:_P8  ;xres: 640;yres: 480;size:1024)   {Last AVGA mode}
      ,(chp:__COMPAQ  ;md:  $32;mode:_P8  ;xres: 640;yres: 480;size:1024)
      ,(chp:__COMPAQ  ;md:  $33;mode:_P8  ;xres: 640;yres: 400;size:1024)
      ,(chp:__COMPAQ  ;md:  $34;mode:_P8  ;xres: 800;yres: 600;size:1024)
      ,(chp:__COMPAQ  ;md:  $37;mode:_PK4a;xres:1024;yres: 768;size:0)
      ,(chp:__COMPAQ  ;md:  $38;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__COMPAQ  ;md:  $39;mode:_PK4a;xres:1280;yres:1024;size:1024)
      ,(chp:__COMPAQ  ;md:  $3A;mode:_P8  ;xres:1280;yres:1024;size:2048)
      ,(chp:__COMPAQ  ;md:  $3B;mode:_P8  ;xres: 512;yres: 480;size:0)
      ,(chp:__COMPAQ  ;md:  $3C;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__COMPAQ  ;md:  $3E;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__COMPAQ  ;md:  $3E;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__COMPAQ  ;md:  $3F;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__COMPAQ  ;md:  $40;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__COMPAQ  ;md:  $4D;mode:_P32 ;xres: 512;yres: 480;size:0)
      ,(chp:__COMPAQ  ;md:  $4E;mode:_P32 ;xres: 640;yres: 400;size:0)
      ,(chp:__COMPAQ  ;md:  $4F;mode:_P32 ;xres: 640;yres: 480;size:0)

      {Everex}
      ,(chp:__Everex  ;md:  $00;mode:_PL4 ;xres: 640;yres: 480;size:0)
      ,(chp:__Everex  ;md:  $01;mode:_PL4 ;xres: 752;yres: 410;size:0)
      ,(chp:__Everex  ;md:  $02;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Everex  ;md:  $03;mode:_TEXT;xres:  80;yres:  34;size:0)
      ,(chp:__Everex  ;md:  $04;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__Everex  ;md:  $05;mode:_TEXT;xres:  94;yres:  29;size:0)
      ,(chp:__Everex  ;md:  $06;mode:_TEXT;xres:  94;yres:  51;size:0)
      ,(chp:__Everex  ;md:  $07;mode:_TEXT;xres: 100;yres:  43;size:0)
      ,(chp:__Everex  ;md:  $08;mode:_TEXT;xres: 100;yres:  75;size:0)
      ,(chp:__Everex  ;md:  $09;mode:_TEXT;xres:  80;yres:  44;size:0)
      ,(chp:__Everex  ;md:  $0A;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Everex  ;md:  $0B;mode:_TEXT;xres: 132;yres:  44;size:0)
      ,(chp:__Everex  ;md:  $0C;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Everex  ;md:  $0D;mode:_TXT2;xres:  80;yres:  44;size:0)
      ,(chp:__Everex  ;md:  $0E;mode:_TXT2;xres: 132;yres:  25;size:0)
      ,(chp:__Everex  ;md:  $0F;mode:_TXT2;xres: 132;yres:  44;size:0)
      ,(chp:__Everex  ;md:  $11;mode:_PL2 ;xres:1280;yres: 350;size:0)
      ,(chp:__Everex  ;md:  $12;mode:_PL2 ;xres:1280;yres: 600;size:0)
      ,(chp:__Everex  ;md:  $13;mode:_P8  ;xres: 640;yres: 350;size:0)
      ,(chp:__Everex  ;md:  $14;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Everex  ;md:  $15;mode:_P8  ;xres: 512;yres: 480;size:0)
      ,(chp:__Everex  ;md:  $16;mode:_TEXT;xres:  80;yres:  30;size:0)
      ,(chp:__Everex  ;md:  $18;mode:_TEXT;xres: 100;yres:  27;size:0)
      ,(chp:__Everex  ;md:  $20;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Everex  ;md:  $21;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__Everex  ;md:  $30;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Everex  ;md:  $31;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Everex  ;md:  $40;mode:_TEXT;xres: 132;yres:  30;size:0)
      ,(chp:__Everex  ;md:  $50;mode:_TXT2;xres: 132;yres:  32;size:0)
      ,(chp:__Everex  ;md:  $62;mode:_P15 ;xres: 320;yres: 200;size:0)
      ,(chp:__Everex  ;md:  $70;mode:_P15 ;xres: 512;yres: 480;size:0)
      ,(chp:__Everex  ;md:  $71;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__Everex  ;md:  $76;mode:_P24 ;xres: 512;yres: 480;size:0)
      ,(chp:__Everex  ;md:  $77;mode:_P24 ;xres: 640;yres: 480;size:0)

      {Genoa}
      ,(chp:__Genoa   ;md:  $43;mode:_TXT2;xres:  80;yres:  29;size:0)
      ,(chp:__Genoa   ;md:  $44;mode:_TXT2;xres:  80;yres:  32;size:0)
      ,(chp:__Genoa   ;md:  $45;mode:_TXT2;xres:  80;yres:  44;size:0)
      ,(chp:__Genoa   ;md:  $46;mode:_TXT2;xres: 132;yres:  25;size:0)
      ,(chp:__Genoa   ;md:  $47;mode:_TXT2;xres: 132;yres:  29;size:0)
      ,(chp:__Genoa   ;md:  $48;mode:_TXT2;xres: 132;yres:  32;size:0)
      ,(chp:__Genoa   ;md:  $49;mode:_TXT2;xres: 132;yres:  44;size:0)
      ,(chp:__Genoa   ;md:  $58;mode:_TEXT;xres:  80;yres:  32;size:0)
      ,(chp:__Genoa   ;md:  $59;mode:_PL4 ;xres: 720;yres: 512;size:0)
      ,(chp:__Genoa   ;md:  $5A;mode:_TEXT;xres: 100;yres:  42;size:0)
      ,(chp:__Genoa   ;md:  $5B;mode:_P8  ;xres: 640;yres: 350;size:0)
      ,(chp:__Genoa   ;md:  $5C;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Genoa   ;md:  $5D;mode:_P8  ;xres: 720;yres: 512;size:0)
      ,(chp:__Genoa   ;md:  $5E;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Genoa   ;md:  $5F;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Genoa   ;md:  $60;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Genoa   ;md:  $61;mode:_TEXT;xres: 132;yres:  29;size:0)
      ,(chp:__Genoa   ;md:  $62;mode:_TEXT;xres: 132;yres:  32;size:0)
      ,(chp:__Genoa   ;md:  $63;mode:_TEXT;xres: 132;yres:  44;size:0)
      ,(chp:__Genoa   ;md:  $64;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__Genoa   ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Genoa   ;md:  $6B;mode:_TEXT;xres: 100;yres:  75;size:0)
      ,(chp:__Genoa   ;md:  $6C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Genoa   ;md:  $72;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__Genoa   ;md:  $73;mode:_PL4 ;xres: 640;yres: 480;size:0)
      ,(chp:__Genoa   ;md:  $74;mode:_TEXT;xres:  80;yres:  66;size:0)
      ,(chp:__Genoa   ;md:  $78;mode:_TEXT;xres: 100;yres:  75;size:0)
      ,(chp:__Genoa   ;md:  $79;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Genoa   ;md:  $7D;mode:_P8  ;xres: 512;yres: 512;size:0)
      ,(chp:__Genoa   ;md:  $7E;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Genoa   ;md:  $7F;mode:_PL2 ;xres:1024;yres: 768;size:0)

      {MXIC}
      ,(chp:__MXIC    ;md:  $50;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__MXIC    ;md:  $51;mode:_TEXT;xres: 132;yres:  30;size:0)
      ,(chp:__MXIC    ;md:  $55;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__MXIC    ;md:  $56;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__MXIC    ;md:  $57;mode:_P8  ;xres: 640;yres: 350;size:0)
      ,(chp:__MXIC    ;md:  $58;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__MXIC    ;md:  $59;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__MXIC    ;md:  $5A;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__MXIC    ;md:  $5B;mode:_P8  ;xres:1024;yres: 768;size:0)

      {NCR}
      ,(chp:__NCR     ;md:  $40;mode:_PL4 ;xres:1600;yres:1200;size:0)
      ,(chp:__NCR     ;md:  $41;mode:_P8  ;xres:1600;yres:1200;size:0)
      ,(chp:__NCR     ;md:  $50;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__NCR     ;md:  $51;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__NCR     ;md:  $54;mode:_TEXT;xres: 132;yres:  50;size:0)
      ,(chp:__NCR     ;md:  $55;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__NCR     ;md:  $56;mode:_TXT4;xres: 132;yres:  50;size:0)
      ,(chp:__NCR     ;md:  $57;mode:_TXT4;xres: 132;yres:  25;size:0)
      ,(chp:__NCR     ;md:  $58;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__NCR     ;md:  $59;mode:_PL1 ;xres: 800;yres: 600;size:0)
      ,(chp:__NCR     ;md:  $5A;mode:_PL1 ;xres:1024;yres: 768;size:0)
      ,(chp:__NCR     ;md:  $5B;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__NCR     ;md:  $5C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__NCR     ;md:  $5D;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__NCR     ;md:  $5E;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__NCR     ;md:  $5F;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__NCR     ;md:  $61;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__NCR     ;md:  $62;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__NCR     ;md:  $67;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__NCR     ;md:  $6A;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__NCR     ;md:  $6B;mode:_P8  ;xres:1280;yres: 960;size:0)
      ,(chp:__NCR     ;md:  $70;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__NCR     ;md:  $71;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__NCR     ;md:  $72;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__NCR     ;md:  $78;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__NCR     ;md:  $79;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__NCR     ;md:  $7A;mode:_P16 ;xres:1024;yres: 768;size:0)

      {Oak}
      ,(chp:__OAK     ;md:  $4E;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__OAK     ;md:  $4F;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__OAK     ;md:  $50;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__OAK     ;md:  $51;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__OAK     ;md:  $52;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__OAK     ;md:  $53;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__OAK     ;md:  $54;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__OAK     ;md:  $55;mode:_PL2 ;xres:1024;yres: 768;size:0)
      ,(chp:__OAK     ;md:  $56;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__OAK     ;md:  $57;mode:_PL4 ;xres: 768;yres:1024;size:0)
      ,(chp:__OAK     ;md:  $58;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__OAK     ;md:  $59;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__OAK     ;md:  $5B;mode:_P15 ;xres: 640;yres: 400;size:0)
      ,(chp:__OAK     ;md:  $5B;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__OAK     ;md:  $5C;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__OAK     ;md:  $5C;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__OAK     ;md:  $5D;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__OAK     ;md:  $5D;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__OAK     ;md:  $5E;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__OAK     ;md:  $5F;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__OAK     ;md:  $61;mode:_P8  ;xres: 640;yres: 400;size:0)

      {Paradise}
      ,(chp:__WD      ;md:  $41;mode:_TEXT;xres:  80;yres:  34;size:0)
      ,(chp:__WD      ;md:  $47;mode:_TEXT;xres: 132;yres:  28;size:0)
      ,(chp:__WD      ;md:  $54;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__WD      ;md:  $55;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__WD      ;md:  $56;mode:_TXT4;xres: 132;yres:  43;size:0)
      ,(chp:__WD      ;md:  $57;mode:_TXT4;xres: 132;yres:  25;size:0)
      ,(chp:__WD      ;md:  $58;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__WD      ;md:  $59;mode:_PL1E;xres: 800;yres: 600;size:0)   {OLD MODELS}
      ,(chp:__WD      ;md:  $5A;mode:_PL1E;xres:1024;yres: 768;size:0)   {OLD MODELS}
      ,(chp:__WD      ;md:  $5B;mode:_PK2 ;xres:1024;yres: 768;size:0)   {OLD MODELS}
      ,(chp:__WD      ;md:  $5C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__WD      ;md:  $5D;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__WD      ;md:  $5E;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__WD      ;md:  $5F;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__WD      ;md:  $60;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__WD      ;md:  $61;mode:_P15 ;xres: 640;yres: 400;size:0)
      ,(chp:__WD      ;md:  $62;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__WD      ;md:  $63;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__WD      ;md:  $64;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__WD      ;md:  $66;mode:_TEXT;xres:  80;yres:  50;size:0)
      ,(chp:__WD      ;md:  $67;mode:_TEXT;xres:  80;yres:  43;size:0)
      ,(chp:__WD      ;md:  $68;mode:_P15 ;xres: 320;yres: 200;size:0)
      ,(chp:__WD      ;md:  $69;mode:_TEXT;xres: 132;yres:  50;size:0)
      ,(chp:__WD      ;md:  $6C;mode:_PL4 ;xres:1280;yres: 960;size:0)
      ,(chp:__WD      ;md:  $6E;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__WD      ;md:  $71;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__WD      ;md:  $72;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__WD      ;md:  $73;mode:_P16 ;xres: 800;yres: 600;size:0)

      {ZyMos Poach}
      ,(chp:__Poach   ;md:  $60;mode:_PL4 ;xres: 960;yres: 720;size:0)
      ,(chp:__Poach   ;md:  $61;mode:_PL4 ;xres:1280;yres: 640;size:0)
      ,(chp:__Poach   ;md:  $62;mode:_P8  ;xres: 512;yres: 512;size:0)
      ,(chp:__Poach   ;md:  $63;mode:_PL4 ;xres: 720;yres: 540;size:0)
      ,(chp:__Poach   ;md:  $64;mode:_P8  ;xres: 720;yres: 540;size:0)
      ,(chp:__Poach   ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)

      {Primus}
      ,(chp:__P2000   ;md:  $1E;mode:_TEXT;xres:  80;yres:  30;size:0)
      ,(chp:__P2000   ;md:  $1F;mode:_TEXT;xres:  80;yres:  43;size:0)
      ,(chp:__P2000   ;md:  $20;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__P2000   ;md:  $21;mode:_TEXT;xres: 100;yres:  75;size:0)
      ,(chp:__P2000   ;md:  $24;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__P2000   ;md:  $25;mode:_TEXT;xres: 132;yres:  30;size:0)
      ,(chp:__P2000   ;md:  $26;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__P2000   ;md:  $27;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__P2000   ;md:  $28;mode:_PL4 ;xres: 512;yres: 512;size:0)
      ,(chp:__P2000   ;md:  $29;mode:_P8  ;xres: 512;yres: 512;size:0)
      ,(chp:__P2000   ;md:  $2A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__P2000   ;md:  $2B;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__P2000   ;md:  $2C;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__P2000   ;md:  $2D;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__P2000   ;md:  $2E;mode:_PL4 ;xres: 768;yres:1024;size:0)
      ,(chp:__P2000   ;md:  $2F;mode:_P8  ;xres: 768;yres:1024;size:0)
      ,(chp:__P2000   ;md:  $30;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__P2000   ;md:  $31;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__P2000   ;md:  $32;mode:_PL4 ;xres:1024;yres:1024;size:0)
      ,(chp:__P2000   ;md:  $33;mode:_P8  ;xres:1024;yres:1024;size:0)
      ,(chp:__P2000   ;md:  $34;mode:_PL4 ;xres:1152;yres: 900;size:0)
      ,(chp:__P2000   ;md:  $35;mode:_P8  ;xres:1152;yres: 900;size:0)
      ,(chp:__P2000   ;md:  $36;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__P2000   ;md:  $37;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__P2000   ;md:  $41;mode:_P15 ;xres: 512;yres: 512;size:0)
      ,(chp:__P2000   ;md:  $42;mode:_P15 ;xres: 640;yres: 350;size:0)
      ,(chp:__P2000   ;md:  $43;mode:_P15 ;xres: 640;yres: 400;size:0)
      ,(chp:__P2000   ;md:  $44;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__P2000   ;md:  $45;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__P2000   ;md:  $41;mode:_P16 ;xres: 512;yres: 512;size:0)
      ,(chp:__P2000   ;md:  $42;mode:_P16 ;xres: 640;yres: 350;size:0)
      ,(chp:__P2000   ;md:  $43;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__P2000   ;md:  $44;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__P2000   ;md:  $45;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__P2000   ;md:  $4A;mode:_P24 ;xres: 640;yres: 480;size:0)

      {Realtek}
      ,(chp:__Realtek ;md:  $18;mode:_TEXT;xres:  80;yres:  30;size:0)
      ,(chp:__Realtek ;md:  $19;mode:_TEXT;xres:  80;yres:  43;size:0)
      ,(chp:__Realtek ;md:  $1A;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__Realtek ;md:  $1B;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Realtek ;md:  $1C;mode:_TEXT;xres: 132;yres:  30;size:0)
      ,(chp:__Realtek ;md:  $1D;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__Realtek ;md:  $1E;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__Realtek ;md:  $1F;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Realtek ;md:  $20;mode:_PL4 ;xres: 960;yres: 720;size:0)
      ,(chp:__Realtek ;md:  $21;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Realtek ;md:  $22;mode:_PL4 ;xres: 768;yres:1024;size:0)
      ,(chp:__Realtek ;md:  $23;mode:_PL2 ;xres:1024;yres: 768;size:0)
      ,(chp:__Realtek ;md:  $24;mode:_P8  ;xres: 512;yres: 512;size:0)
      ,(chp:__Realtek ;md:  $25;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Realtek ;md:  $26;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Realtek ;md:  $27;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Realtek ;md:  $28;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Realtek ;md:  $29;mode:_P8  ;xres:1024;yres:1024;size:0)
      ,(chp:__Realtek ;md:  $2A;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__Realtek ;md:  $38;mode:_P16 ;xres: 320;yres: 200;size:0)
      ,(chp:__Realtek ;md:  $39;mode:_P16 ;xres: 512;yres: 512;size:0)
      ,(chp:__Realtek ;md:  $3A;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__Realtek ;md:  $3B;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__Realtek ;md:  $3C;mode:_P16 ;xres: 800;yres: 600;size:0)

      {S3}
      ,(chp:__S3      ;md:  $54;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__S3      ;md:  $55;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__S3      ;md: $101;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__S3      ;md: $102;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__S3      ;md: $103;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__S3      ;md: $104;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__S3      ;md: $105;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__S3      ;md: $206;mode:_PK4a;xres:1280;yres: 960;size:1024)
      ,(chp:__S3      ;md: $208;mode:_PK4a;xres:1280;yres:1024;size:1024)
      ,(chp:__S3      ;md: $211;mode:_P16 ;xres: 640;yres: 480;size:2048)
      ,(chp:__S3      ;md: $212;mode:_P24 ;xres: 640;yres: 480;size:2048)
      ,(chp:__S3      ;md: $301;mode:_P15 ;xres: 640;yres: 480;size:2048)
      ,(chp:__S3      ;md: $301;mode:_P16 ;xres: 640;yres: 480;size:2048)
      ,(chp:__S3      ;md: $106;mode:_Pl4 ;xres:1280;yres:1024;size:0)
      ,(chp:__S3      ;md: $107;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__S3      ;md: $110;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__S3      ;md: $111;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__S3      ;md: $112;mode:_P32 ;xres: 640;yres: 480;size:2048)
      ,(chp:__S3      ;md: $113;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__S3      ;md: $114;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__S3      ;md: $115;mode:_P32 ;xres: 800;yres: 600;size:0)
      ,(chp:__S3      ;md: $116;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__S3      ;md: $117;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__S3      ;md: $118;mode:_P32 ;xres:1024;yres: 768;size:0)
      ,(chp:__S3      ;md: $119;mode:_P15 ;xres:1280;yres:1024;size:0)
      ,(chp:__S3      ;md: $11A;mode:_P16 ;xres:1280;yres:1024;size:0)
      ,(chp:__S3      ;md: $120;mode:_P8  ;xres:1600;yres:1200;size:0)
      ,(chp:__S3      ;md: $124;mode:_P8  ;xres:1152;yres: 864;size:0)
      ,(chp:__S3      ;md: $125;mode:_P15 ;xres:1152;yres: 864;size:0)
      ,(chp:__S3      ;md: $126;mode:_P16 ;xres:1152;yres: 864;size:0)
    {  ,(chp:__S3      ;md:  $45;mode:_P8  ;xres:1600;yres:1200;size:2048)}

      {SiS SG86c201}
      ,(chp:__SiS     ;md:  $22;mode:_TEXT;xres: 132;yres:  44;size:0)
      ,(chp:__SiS     ;md:  $23;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__SiS     ;md:  $24;mode:_TEXT;xres: 132;yres:  28;size:0)
      ,(chp:__SiS     ;md:  $26;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__SiS     ;md:  $29;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__SiS     ;md:  $2A;mode:_TEXT;xres: 100;yres:  40;size:0)
      ,(chp:__SiS     ;md:  $2D;mode:_P8  ;xres: 640;yres: 350;size:0)
      ,(chp:__SiS     ;md:  $2E;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__SiS     ;md:  $2F;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__SiS     ;md:  $30;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__SiS     ;md:  $37;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__SiS     ;md:  $38;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__SiS     ;md:  $39;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__SiS     ;md:  $40;mode:_P15 ;xres: 320;yres: 200;size:0)
      ,(chp:__SiS     ;md:  $41;mode:_P16 ;xres: 320;yres: 200;size:0)
      ,(chp:__SiS     ;md:  $42;mode:_P24 ;xres: 320;yres: 200;size:0)
      ,(chp:__SiS     ;md:  $43;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__SiS     ;md:  $44;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__SiS     ;md:  $45;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__SiS     ;md:  $46;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__SiS     ;md:  $47;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__SiS     ;md:  $48;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__SiS     ;md:  $49;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__SiS     ;md:  $4A;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__SiS     ;md:  $4B;mode:_P24 ;xres:1024;yres: 768;size:0)
      ,(chp:__SiS     ;md:  $4C;mode:_P15 ;xres:1280;yres:1024;size:0)
      ,(chp:__SiS     ;md:  $4D;mode:_P16 ;xres:1280;yres:1024;size:0)

      {Trident}
      ,(chp:__Trid    ;md:  $50;mode:_TEXT;xres:  80;yres:  30;size:0)
      ,(chp:__Trid    ;md:  $51;mode:_TEXT;xres:  80;yres:  43;size:0)
      ,(chp:__Trid    ;md:  $52;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__TRID    ;md:  $53;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__TRID    ;md:  $54;mode:_TEXT;xres: 132;yres:  30;size:0)
      ,(chp:__TRID    ;md:  $55;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__TRID    ;md:  $56;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__TRID    ;md:  $57;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__TRID    ;md:  $58;mode:_TEXT;xres: 132;yres:  30;size:0)
      ,(chp:__TRID    ;md:  $59;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__TRID    ;md:  $5A;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__TRID    ;md:  $5B;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__TRID    ;md:  $5C;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__TRID    ;md:  $5D;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__TRID    ;md:  $5E;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__TRID    ;md:  $5F;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__TRID    ;md:  $60;mode:_PL2 ;xres:1024;yres: 768;size:0)
      ,(chp:__TRID    ;md:  $61;mode:_PL4 ;xres: 768;yres:1024;size:0)
      ,(chp:__TRID    ;md:  $62;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__TRID    ;md:  $63;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__TRID    ;md:  $64;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__TRID    ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__TRID    ;md:  $6B;mode:_P24 ;xres: 320;yres: 200;size:0)
      ,(chp:__TRID    ;md:  $6C;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__TRID    ;md:  $6D;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__TRID    ;md:  $70;mode:_P15 ;xres: 512;yres: 480;size:0)
      ,(chp:__TRID    ;md:  $71;mode:_P16 ;xres: 512;yres: 480;size:0)
      ,(chp:__TRID    ;md:  $72;mode:_P15 ;xres: 640;yres: 400;size:0)
      ,(chp:__TRID    ;md:  $73;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__TRID    ;md:  $74;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__TRID    ;md:  $75;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__TRID    ;md:  $76;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__TRID    ;md:  $77;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__TRID    ;md:  $78;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__TRID    ;md:  $79;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__TRID    ;md:  $7E;mode:_P15 ;xres: 320;yres: 200;size:0)
      ,(chp:__TRID    ;md:  $7F;mode:_P16 ;xres: 320;yres: 200;size:0)

      {IIT AGX}
      ,(chp:__AGX     ;md:  $64;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__AGX     ;md:  $65;mode:_P8  ;xres:1024;yres: 768;size:0)

      {Tseng}
      ,(chp:__Tseng   ;md:  $18;mode:_TXT4;xres: 132;yres:  44;size:0)
      ,(chp:__Tseng   ;md:  $19;mode:_TXT4;xres: 132;yres:  25;size:0)
      ,(chp:__Tseng   ;md:  $1A;mode:_TXT4;xres: 132;yres:  28;size:0)
      ,(chp:__Tseng   ;md:  $22;mode:_TEXT;xres: 132;yres:  44;size:0)
      ,(chp:__Tseng   ;md:  $23;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Tseng   ;md:  $24;mode:_TEXT;xres: 132;yres:  28;size:0)
      ,(chp:__Tseng   ;md:  $25;mode:_PL4 ;xres: 640;yres: 480;size:0)
      ,(chp:__Tseng   ;md:  $26;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__Tseng   ;md:  $27;mode:_PL4 ;xres: 720;yres: 512;size:0)
      ,(chp:__Tseng   ;md:  $29;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Tseng   ;md:  $2A;mode:_TEXT;xres: 100;yres:  40;size:0)
      ,(chp:__Tseng   ;md:  $2D;mode:_P8  ;xres: 640;yres: 350;size:0)
      ,(chp:__Tseng   ;md:  $2E;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Tseng   ;md:  $2F;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Tseng   ;md:  $30;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Tseng   ;md:  $36;mode:_PL4 ;xres: 960;yres: 720;size:0)
      ,(chp:__Tseng   ;md:  $37;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Tseng   ;md:  $38;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Tseng   ;md:  $3D;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__Tseng   ;md:  $3E;mode:_PL4 ;xres:1280;yres: 960;size:0)
      ,(chp:__Tseng   ;md: $53E;mode:_P24 ;xres: 640;yres: 480;size:0)        {Genoa 16M}
      ,(chp:__Tseng   ;md:  $3F;mode:_P8  ;xres:1280;yres:1024;size:0)        {W32}
      ,(chp:__Tseng   ;md: $12E;mode:_P24 ;xres: 640;yres: 480;size:2048)     {SpeedStar 24}
      ,(chp:__Tseng   ;md: $22D;mode:_P24 ;xres: 640;yres: 350;size:2048)
      ,(chp:__Tseng   ;md: $22E;mode:_P24 ;xres: 640;yres: 480;size:2048)
      ,(chp:__Tseng   ;md: $22F;mode:_P24 ;xres: 640;yres: 400;size:2048)
      ,(chp:__Tseng   ;md: $230;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__Tseng   ;md: $313;mode:_P15 ;xres: 320;yres: 200;size:0)
      ,(chp:__Tseng   ;md: $32D;mode:_P15 ;xres: 640;yres: 350;size:0)
      ,(chp:__Tseng   ;md: $32E;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__Tseng   ;md: $32F;mode:_P15 ;xres: 640;yres: 400;size:0)
      ,(chp:__Tseng   ;md: $330;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__Tseng   ;md: $338;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__Tseng   ;md: $413;mode:_P16 ;xres: 320;yres: 200;size:0)
      ,(chp:__Tseng   ;md: $42D;mode:_P16 ;xres: 640;yres: 350;size:0)
      ,(chp:__Tseng   ;md: $42E;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__Tseng   ;md: $42F;mode:_P16 ;xres: 640;yres: 400;size:0)
      ,(chp:__Tseng   ;md: $430;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__Tseng   ;md: $438;mode:_P16 ;xres:1024;yres: 768;size:0)

      {UMC}
      ,(chp:__UMC     ;md:  $46;mode:_TXT2;xres: 132;yres:  25;size:0)
      ,(chp:__UMC     ;md:  $47;mode:_TXT2;xres: 132;yres:  29;size:0)
      ,(chp:__UMC     ;md:  $48;mode:_TXT2;xres: 132;yres:  32;size:0)
      ,(chp:__UMC     ;md:  $49;mode:_TXT2;xres: 132;yres:  44;size:0)
      ,(chp:__UMC     ;md:  $50;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__UMC     ;md:  $50;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__UMC     ;md:  $51;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__UMC     ;md:  $51;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__UMC     ;md:  $58;mode:_TEXT;xres:  80;yres:  32;size:0)
      ,(chp:__UMC     ;md:  $5C;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__UMC     ;md:  $5E;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__UMC     ;md:  $5F;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__UMC     ;md:  $60;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__UMC     ;md:  $61;mode:_TEXT;xres: 132;yres:  29;size:0)
      ,(chp:__UMC     ;md:  $62;mode:_TEXT;xres: 132;yres:  32;size:0)
      ,(chp:__UMC     ;md:  $63;mode:_TEXT;xres: 132;yres:  44;size:0)
      ,(chp:__UMC     ;md:  $64;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__UMC     ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__UMC     ;md:  $6B;mode:_TEXT;xres: 100;yres:  37;size:0)
      ,(chp:__UMC     ;md:  $6C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__UMC     ;md:  $72;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__UMC     ;md:  $73;mode:_PL4 ;xres: 640;yres: 480;size:0)
      ,(chp:__UMC     ;md:  $74;mode:_TEXT;xres:  80;yres:  66;size:0)
      ,(chp:__UMC     ;md:  $78;mode:_TEXT;xres: 100;yres:  37;size:0)
      ,(chp:__UMC     ;md:  $79;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__UMC     ;md:  $7A;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__UMC     ;md:  $7D;mode:_P8  ;xres: 512;yres: 512;size:0)
      ,(chp:__UMC     ;md:  $7E;mode:_P15 ;xres: 640;yres: 400;size:0)
      ,(chp:__UMC     ;md:  $7F;mode:_P8  ;xres:1024;yres: 768;size:0)

      {Video7}
      ,(chp:__Video7  ;md:  $40;mode:_TEXT;xres:  80;yres:  43;size:0)
      ,(chp:__Video7  ;md:  $41;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Video7  ;md:  $42;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__Video7  ;md:  $43;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__Video7  ;md:  $44;mode:_TEXT;xres: 100;yres:  60;size:0)
      ,(chp:__Video7  ;md:  $45;mode:_TEXT;xres: 132;yres:  28;size:0)
      ,(chp:__Video7  ;md:  $60;mode:_PL4 ;xres: 752;yres: 410;size:0)
      ,(chp:__Video7  ;md:  $61;mode:_PL4 ;xres: 720;yres: 540;size:0)
      ,(chp:__Video7  ;md:  $62;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Video7  ;md:  $63;mode:_PL1 ;xres:1024;yres: 768;size:0)
      ,(chp:__Video7  ;md:  $64;mode:_PL2 ;xres:1024;yres: 768;size:0)
      ,(chp:__Video7  ;md:  $65;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Video7  ;md:  $66;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Video7  ;md:  $67;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Video7  ;md:  $68;mode:_P8  ;xres: 720;yres: 540;size:0)
      ,(chp:__Video7  ;md:  $69;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Video7  ;md:  $6A;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Video7  ;md:  $70;mode:_PL4 ;xres:1280;yres:1024;size:0)   {Only newer boards}

      {Weitek}
      ,(chp:__Weitek  ;md:  $54;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__Weitek  ;md:  $55;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__Weitek  ;md:  $56;mode:_TXT4;xres: 132;yres:  43;size:0)
      ,(chp:__Weitek  ;md:  $57;mode:_TXT4;xres: 132;yres:  25;size:0)
      ,(chp:__Weitek  ;md:  $58;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Weitek  ;md:  $59;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Weitek  ;md:  $5A;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__Weitek  ;md:  $5C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Weitek  ;md:  $5D;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Weitek  ;md:  $5E;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Weitek  ;md:  $5F;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Weitek  ;md:  $64;mode:_TEXT;xres: 132;yres:  60;size:0)
      ,(chp:__Weitek  ;md:  $65;mode:_TEXT;xres: 132;yres:  50;size:0)
      ,(chp:__Weitek  ;md:  $66;mode:_TXT4;xres: 132;yres:  60;size:0)
      ,(chp:__Weitek  ;md:  $67;mode:_TXT4;xres: 132;yres:  50;size:0)
      ,(chp:__Weitek  ;md:  $68;mode:_TEXT;xres:  80;yres:  60;size:0)
      ,(chp:__Weitek  ;md:  $69;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__Weitek  ;md:  $6A;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Weitek  ;md:  $6C;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__Weitek  ;md:  $6D;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__Weitek  ;md:  $6E;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__Weitek  ;md:  $6F;mode:_P16 ;xres: 800;yres: 600;size:0)

      {HMC}
      ,(chp:__HMC     ;md:  $20;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__HMC     ;md:  $21;mode:_TEXT;xres: 132;yres:  44;size:0)
      ,(chp:__HMC     ;md:  $22;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__HMC     ;md:  $28;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__HMC     ;md:  $29;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__HMC     ;md:  $2A;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__HMC     ;md:  $2B;mode:_P8  ;xres: 640;yres: 200;size:0)
      ,(chp:__HMC     ;md:  $2C;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__HMC     ;md:  $2D;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__HMC     ;md:  $2E;mode:_P8  ;xres: 800;yres: 600;size:832)
      ,(chp:__HMC     ;md:  $31;mode:_PL2 ;xres:1024;yres: 768;size:0)
      ,(chp:__HMC     ;md:  $32;mode:_PL2 ;xres:1024;yres: 768;size:0)

      {Mach32}
      ,(chp:__Mach32  ;md: $101;mode:_PK4B;xres: 800;yres: 600;size:0)
      ,(chp:__Mach32  ;md: $111;mode:_PK4B;xres:1280;yres:1024;size:0)
      ,(chp:__Mach32  ;md: $121;mode:_PK4B;xres: 640;yres: 480;size:0)
      ,(chp:__Mach32  ;md: $141;mode:_PK4B;xres:1024;yres: 768;size:0)
      ,(chp:__Mach32  ;md: $301;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach32  ;md: $311;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach32  ;md: $321;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach32  ;md: $341;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Mach32  ;md: $501;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach32  ;md: $511;mode:_P15 ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach32  ;md: $521;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach32  ;md: $541;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__Mach32  ;md: $D01;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach32  ;md: $D11;mode:_P16 ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach32  ;md: $D21;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach32  ;md: $D41;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__Mach32  ;md: $701;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach32  ;md: $711;mode:_P24 ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach32  ;md: $721;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach32  ;md: $741;mode:_P24 ;xres:1024;yres: 768;size:0)

      {Mach64}
      ,(chp:__Mach64  ;md:$1281;mode:_PK4B;xres: 640;yres: 480;size:0)
      ,(chp:__Mach64  ;md:$6A81;mode:_PK4B;xres: 800;yres: 600;size:0)
      ,(chp:__Mach64  ;md:$5591;mode:_PK4B;xres:1024;yres: 768;size:0)
      ,(chp:__Mach64  ;md:$8381;mode:_PK4B;xres:1280;yres:1024;size:0)
      ,(chp:__Mach64  ;md:$8481;mode:_PK4B;xres:1600;yres:1200;size:0)
      ,(chp:__Mach64  ;md:$1292;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach64  ;md:$6A92;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach64  ;md:$5592;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Mach64  ;md:$8392;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach64  ;md:$8492;mode:_P8  ;xres:1600;yres:1200;size:0)
      ,(chp:__Mach64  ;md:$1293;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach64  ;md:$6A93;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach64  ;md:$5593;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__Mach64  ;md:$8393;mode:_P15 ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach64  ;md:$8493;mode:_P15 ;xres:1600;yres:1200;size:0)
      ,(chp:__Mach64  ;md:$1294;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach64  ;md:$6A94;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach64  ;md:$5594;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__Mach64  ;md:$8394;mode:_P16 ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach64  ;md:$8494;mode:_P16 ;xres:1600;yres:1200;size:0)
      ,(chp:__Mach64  ;md:$1295;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__Mach64  ;md:$6A95;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__Mach64  ;md:$5595;mode:_P24 ;xres:1024;yres: 768;size:0)
      ,(chp:__Mach64  ;md:$8395;mode:_P24 ;xres:1280;yres:1024;size:0)
      ,(chp:__Mach64  ;md:$8495;mode:_P24 ;xres:1600;yres:1200;size:0)
      ,(chp:__Mach64  ;md:$1296;mode:_P32b;xres: 640;yres: 480;size:0)
      ,(chp:__Mach64  ;md:$6A96;mode:_P32b;xres: 800;yres: 600;size:0)
      ,(chp:__Mach64  ;md:$5596;mode:_P32b;xres:1024;yres: 768;size:0)
      ,(chp:__Mach64  ;md:$8396;mode:_P32b;xres:1280;yres:1024;size:0)
      ,(chp:__Mach64  ;md:$8496;mode:_P32b;xres:1600;yres:1200;size:0)


      {Matrox MGA}
      ,(chp:__Matrox  ;md:  $27;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Matrox  ;md:  $2A;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Matrox  ;md:  $33;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__Matrox  ;md:  $34;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Matrox  ;md:  $38;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Matrox  ;md:  $3B;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Matrox  ;md:  $41;mode:_TEXT;xres:  90;yres:  25;size:0)
      ,(chp:__Matrox  ;md:  $43;mode:_TEXT;xres: 120;yres:  25;size:0)
      ,(chp:__Matrox  ;md:  $44;mode:_TEXT;xres: 132;yres:  25;size:0)

      ,(chp:__ARK     ;md:  $24;mode:_TEXT;xres: 132;yres:  25;size:0)
      ,(chp:__ARK     ;md:  $26;mode:_TEXT;xres: 132;yres:  43;size:0)
      ,(chp:__ARK     ;md:  $27;mode:_TEXT;xres: 132;yres:  50;size:0)
      ,(chp:__ARK     ;md:  $31;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__ARK     ;md:  $32;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__ARK     ;md:  $33;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__ARK     ;md:  $40;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__ARK     ;md:  $41;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__ARK     ;md:  $42;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__ARK     ;md:  $43;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__ARK     ;md:  $44;mode:_P8  ;xres:1600;yres:1200;size:0)
      ,(chp:__ARK     ;md:  $4F;mode:_P8  ;xres: 640;yres: 400;size:0)
      ,(chp:__ARK     ;md:  $50;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__ARK     ;md:  $51;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__ARK     ;md:  $52;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__ARK     ;md:  $54;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__ARK     ;md:  $55;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__ARK     ;md:  $56;mode:_P16 ;xres:1024;yres: 768;size:0)
      ,(chp:__ARK     ;md:  $58;mode:_P24 ;xres: 640;yres: 480;size:0)  {P32 for the 2000PV}
      ,(chp:__ARK     ;md:  $59;mode:_P24 ;xres: 800;yres: 600;size:0)

      ,(chp:__Acer    ;md:  $54;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__Acer    ;md:  $56;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__Acer    ;md:  $57;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__Acer    ;md:  $59;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__Acer    ;md:  $5A;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__Acer    ;md:  $5B;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__Acer    ;md:  $5E;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__Acer    ;md:  $70;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__Acer    ;md:  $71;mode:_P16 ;xres: 640;yres: 480;size:0)
      ,(chp:__Acer    ;md:  $72;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__Acer    ;md:  $73;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__Acer    ;md:  $74;mode:_P16 ;xres: 800;yres: 600;size:0)
      ,(chp:__Acer    ;md:  $75;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__Acer    ;md:  $76;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__Acer    ;md:  $77;mode:_P16 ;xres:1024;yres: 768;size:0)

      ,(chp:__SC      ;md:  $58;mode:_PL4 ;xres: 800;yres: 600;size:0)
      ,(chp:__SC      ;md:  $59;mode:_PL4 ;xres:1600;yres:1200;size:0)
      ,(chp:__SC      ;md:  $5A;mode:_PL4 ;xres:1280;yres:1024;size:0)
      ,(chp:__SC      ;md:  $5B;mode:_P8  ;xres:1280;yres:1024;size:0)
      ,(chp:__SC      ;md:  $5C;mode:_P8  ;xres: 800;yres: 600;size:0)
      ,(chp:__SC      ;md:  $5D;mode:_PL4 ;xres:1024;yres: 768;size:0)
      ,(chp:__SC      ;md:  $5E;mode:_P8  ;xres:1024;yres: 768;size:0)
      ,(chp:__SC      ;md:  $5F;mode:_P8  ;xres: 640;yres: 480;size:0)
      ,(chp:__SC      ;md:  $60;mode:_P8  ;xres:1600;yres:1200;size:0)
      ,(chp:__SC      ;md:  $69;mode:_P24 ;xres: 640;yres: 480;size:0)
      ,(chp:__SC      ;md:  $6E;mode:_P15 ;xres: 640;yres: 480;size:0)
      ,(chp:__SC      ;md:  $6F;mode:_P15 ;xres: 800;yres: 600;size:0)
      ,(chp:__SC      ;md:  $70;mode:_P24 ;xres: 800;yres: 600;size:0)
      ,(chp:__SC      ;md:  $71;mode:_P15 ;xres:1024;yres: 768;size:0)
      ,(chp:__SC      ;md:  $73;mode:_P24 ;xres:1024;yres: 768;size:0)
      ,(chp:__SC      ;md:  $75;mode:_P15 ;xres:1280;yres:1024;size:0));




