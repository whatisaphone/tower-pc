
 {This file holds the public declarations for WHATVGA & utilities}

const
  {Memory Mode definitions}
  _text  =  1;
  _txt2  =  2;
  _txt4  =  3;
  _herc  =  4;   {Hercules mono, 4 "banks" of 8kbytes}
  _cga1  =  5;   {CGA 2 color, 2 "banks" of 16kbytes}
  _cga2  =  6;   {CGA 4 color, 2 "banks" of 16kbytes}
  _pl1   =  7;   {plain mono, 8 pixels per byte}
  _pl1e  =  8;   {mono odd/even, 8 pixels per byte, two planes}
  _pl2   =  9;   {4 color odd/even planes}
  _pk2   = 10;   {4 color "packed" pixels 4 pixels per byte}
  _pl4   = 11;   {std EGA/VGA 16 color: 4 planes, 8 pixels per byte}
  _pk4   = 12;   {ATI mode 65h two 16 color pixels per byte}
  _pk4a  = 13;   {As pk4, but reversed within byte}
  _pk4b  = 14;   {As pk4a, but planes 1&2 are reversed}
  _p8    = 15;   {one 256 color pixel per byte}
  _p15   = 16;   {Sierra 15 bit}
  _p16   = 17;   {Sierra 16bit/XGA}
  _p24   = 18;   {RGB 3bytes per pixel}
  _p24b  = 19;   {BGR 3bytes/pixel, but red first}
  _p32   = 20;   {RGBa 3+1 bytes per pixel }
  _p32b  = 21;   {BGRa 3+1 bytes per pixel }
  _p32c  = 22;   {aRGR 3+1 bytes per pixel }
  _p32d  = 23;   {aBGR 3+1 bytes per pixel }
  max_mode  = _p32d;


  {Primary chipset definitions}
  __none     =  0;
  __EGA      =  1;
  __VGA      =  2;
  __chips    =  3;
  __WD       =  4;   {Paradise/Western digital}
  __video7   =  5;
  __Tseng    =  6;
  __trid     =  7;
  __poach    =  8;
  __everex   =  9;
  __ati      = 10;
  __genoa    = 11;
  __oak      = 12;
  __cirrus   = 13;
  __ahead    = 14;
  __ncr      = 15;
  __yamaha   = 16;
  __s3       = 17;
  __ALG      = 18;   {Avance Logic}
  __mxic     = 19;
  __vesa     = 20;
  __realtek  = 21;
  __p2000    = 22;
  __cir54    = 23;
  __cir64    = 24;
  __Weitek   = 25;
  __WeitekP9 = 26;   {Weitek Power9000}
  __xga      = 27;
  __compaq   = 28;
  __AGX      = 29;
  __Mach32   = 30;
  __Mach64   = 31;
  __UMC      = 32;
  __HMC      = 33;
  __Matrox   = 34;  {Matrox VGA}
  __ARK      = 35;
  __Acer     = 36;
  __SC       = 37;
  __xbe      = 38;
  __MV       = 39;  {MediaVision Pro Graphics}
  __MGA      = 40;  {Matrox (Native)}
  __Alli     = 41;  {Alliance Pro Motion}
  __IMAG     = 42;  {#9 Imagine 128}
  __SiS      = 43;  {SiS Sg86c201}
  max_chip   = __SiS;

  {DAC types}
  _dac0        =   0;  {No DAC (MDA/CGA/EGA ..}
  _dac8        =   1;  {Std VGA DAC 256 cols.}

  _dacInt      =   2;  {Internal Hi/True color DAC}
  _dacCEG      =   3;  {Edsun CEG DAC}
  _dac15       =   4;  {Sierra 32k DAC (SC11483)}
  _dac16       =   5;  {Sierra 64k DAC}

  _dacADAC1    =  10;  {Acumos ADAC1  15/16/24 bit DAC}

  _dacALG1101  =  20;  {Avance Logic ALG1101 16bit DAC}
  _dacALG1201  =  21;  {Avance Logic ALG1201 24 bit DAC}
  _dacALG1301  =  22;  {Avance Logic ALG1301 24 bit DAC}

  _dacATI68860 =  30;  {ATI 68860 SpectraDAC}
  _dacATI68880 =  31;

  _dacATT490   =  40;  {ATT 20c490  15/16/24 bit DAC}
  _dacATT491   =  41;  {ATT 20c491  15/16/24 bit DAC}
  _dacATT492   =  42;  {ATT 20c492  15/16/24 bit DAC}
  _dacATT493   =  43;  {ATT 20c493  15/16/24 bit DAC}

  _dacATT504   =  50;  {ATT 20c504}
  _dacATT505   =  51;  {ATT 20c505}

  _dacATT498   =  60;  {ATT 20c498  15/16/24 bit DAC}
  _dacATT1498  =  61;  {ATT 21c498  15/16/24 bit DAC}
  _dacATT2498  =  62;  {ATT 22c498  15/16/24 bit DAC}

  _dacBt477    =  70;  {Bt477}
  _dacBt481    =  71;  {Bt481}
  _dacBt482    =  72;  {Bt482}
  _dacBt484    =  73;  {BrookTree Bt484/5 or ATT20c504/5 DAC}
  _dacBt485    =  74;  {BrookTree Bt484/5 or ATT20c504/5 DAC}

  _dacCH8391   =  80;  {CHRONTEL CH8391}
  _dacCH8398   =  81;  {CHRONTEL CH8398}

  _dacCL5200   =  90;  {Cirrus Logic CL-GD5200}

  _dacIBM514   = 100;
  _dacIBM524   = 101;
  _dacIBM525   = 102;  {IBM RGB525}
  _dacIBM526   = 103;
  _dacIBM528   = 104;
  _dacIBM530   = 105;
  _dacIBM561   = 106;
  _dacIBM624   = 107;

  _dacICW498   = 120;
  _dacICW516   = 121;

  _dacMU1880   = 130;  {MUSIC 9c1880/Diamond SS24 DAC}
  _dacMU4870   = 131;
  _dacMU4910   = 132;
  _dacMU9910   = 133;

  _dacS3_716   = 140;
  _dacS3_708   = 141;

  _dacSC486    = 150;  {Sierra SC11486 - 15bit DAC}
  _dacSC15021  = 151;  {Sierra SC15021}
  _dacSC15025  = 152;  {Sierra SC15025}

  _dacSTG1700  = 160;  {STG1700}
  _dacSTG1702  = 161;  {STG1702}
  _dacSTG1703  = 162;  {STG1703}

  _dacTLC34075 = 170;
  _dacTLC34076 = 171;

  _dacTR8001   = 180;  {Trident TKD8001}

  _dacTVP3010  = 190;
  _dacTVP3020  = 191;
  _dacTVP3025  = 192;
  _dacTVP3026  = 193;

  _dacUMC188   = 200;  {UMC UM70c188}

  _dacICS5301  = 210;  {ICS 5301}


   {Clock definitions}
  clk_unk        =  0;
  clk_internal   =  1;   {Cirrus, Acumos}
  clk_ext2       =  2;   {4 clks via 2 bits (Std VGA)}
  clk_ext3       =  3;   {8 clks via 3 bits}
  clk_ext4       =  4;   {16 clks via 4 bits}
  clk_ext5       =  5;   {32 clks via 5 bits}
  clk_ext6       =  6;   {64 clks via 3 bits}

  clk_sigma      =  7;   {Sigma Legend "buffered" 5 bit}
  clk_ICD2061    =  8;
  clk_ICD2061A   =  9;
  clk_sdac       = 10;   {S3 SDAC or GenDAC}
  clk_TVP302x    = 11;   {TI TVP 3020/3025}
  clk_ICS2595    = 12;   {ICS 2595}
  clk_SC11412    = 13;   {Sierra SC11412}
  clk_CHRON      = 14;   {Chrontel CH8391/8}
  clk_STG        = 15;   {STG1703}
  clk_MUSIC      = 16;   {MUSIC MU9c9910}
  clk_IBM52x     = 17;   {IBM RGB52x}


  {Flags for special features}
  ft_cursor = 1;   {Has hardware cursor}
  ft_blit   = 2;   {Can do BitBLTs}
  ft_line   = 4;   {Can do lines}
  ft_rwbank = 8;   {Suports seperate R/W banks}


    {Device Capabilities}
  FLG_StdVGA  = 1;    {Set for VGA type devices}
  FLG_ExtDAC  = 2;    {Set if we have RS2 or RS3 to the DAC}
  FLG_PCIbus  = 4;    {Set if teh card is in a PCI slot}

   {DAC Flag bits, from DACflags}
  DFL_cmdreg  =    1;  {The DAC has a Hidden Command Register}
  DFL_8bit    =    2;  {The DAC can do 8bit (256 of 16M)}
  DFL_clock   =    4;  {The DAC has onchip clock generator}
  DFL_cursor  =    8;  {The DAC has a cursor}


    {Flag options for ModeType}
  MFL_enabled  =  1;   {Set if the mode is enabled}
  MFL_graphics =  2;   {Set for graphics modes}
  MFL_vgamode  =  4;   {Set for standard VGA modes}

  MFL_enGr     =  MFL_enabled or MFL_graphics;  {Enabled Graphics modes}
  MFL_enVGA    =  MFL_enabled or MFL_vgamode;   {Enabled Standard VGA mode}
  MFL_enGrVGA  =  MFL_enVGA or MFL_graphics;    {Enabled Graphics Std VGA mode}


  header:array[0..max_chip] of string[14]=
	 ('','EGA','VGA','Chips&Tech','Paradise','Video7','Tseng','Trident'
         ,'Poach','Everex','ATI','Genoa','Oak','Cirrus','Ahead','NCR'
         ,'Yamaha','S3','ALG','MXIC','VESA','Realtek','PRIMUS','Cirrus54'
         ,'Cirrus64','Weitek','WeitekP9','XGA','COMPAQ','AGX','Mach32'
         ,'Mach64','UMC','HMC','Matrox','ARK','Acer','Sierra','XBE'
         ,'MediaVision','MGA','Alliance','Imagine','SiS');


      {Short name for chip families}
  chipnam:array[0..max_chip] of string[8]=
        ('','EGA','VGA','CT45x','WD','Video7','Tseng','Trident'
        ,'Poach','Everex','ATI','Genoa','OAK','Cirrus','Ahead','NCR'
        ,'Yamaha','S3','ALG','MXIC','VESA','Realtek','Primus','CL54xx'
        ,'CL64xx','Weitek','P9000','XGA','Compaq','AGX','Mach32'
        ,'Mach64','UMC','HMC','Matrox','ARK','ACER','SIERRA','XBE'
        ,'MVision','MGA','Alliance','Imagine','SiS');





  {AutoTest flags & structures}

    {AF test record IDs}
  AF_header   = 0;
  AF_videosys = 1;
  AF_modeinfo = 2;
  AF_tcursor  = 3;    {Cursor test record ID}
  AF_tbitblt  = 4;    {BitBLT test record ID}
  AF_tline    = 5;    {LineDrv test record ID}
  AF_trwbank  = 6;    {RWbank test record ID}
  AF_tzoom    = 7;    {Zoom test record ID}
  AF_BIOSdmp  = 255;

    {AF Flag values}
  AFF_testok   =  1;   {Set if the test was succesful}
  AFF_dispok   =  2;   {Set if the mode was displayed ok}
  AFF_scroll   =  4;   {Set if the mode can be scrolled}
  AFF_scrollok =  8;   {Set if the scroll test was ok}
  AFF_canceled = 16;   {Set if the mode was canceled}


type
  vidinfo=record
            chip:byte;
            flags:word;          {Flags (FLG_}
            id:word;             {instance}
            IOadr:word;          {I/O adr}
            spcreg:word;    {Special register offset (IIT)}
            Xseg:word;
            Phadr:longint;
            version:word;        {version}
            subvers:word;        {Subversion}
            dactype:word;            {The dac type}
            dacname:string[20];  {The Name of the DACtype}
            mm:word;             {#kilobytes of video memory}
            features:word;       {Flags for special features}
            sname:string[8];     {Short chip family name}
            name:string[40];     {Full chip name}
            clktype:word;        {Clock type (clk_)}
            clks:array[0..63] of longint;  {Clocks in Hz}
            PCIid:byte;
          end;

  _AT0=record
         SWvers:word;  {SW version}
         vid_sys,         {Number of video systems}
         cur_vid:word;    {Currently selected video system (1..)}
         curtime:longint; {Date & time of the test}
       end;
       {This record followed by: (Email),(Name&Address),(Video desc)
                    ,(System),(modenames),(clock names)}


    {AT1 is the VIDINFO record, one per Video Subsystem}

  _AT2=record
         mode:word;
        Mmode:byte;   {Memory Model}
       pixels,
         lins,
        bytes,
         crtc,
         vseg:word;
      Cpixels,
        Clins,
       Cbytes,
        Cvseg:word;
       CMmode:byte;   {Calculated mode}
      ChWidth,
     ChHeight,
      ExtPixf,
      ExtLinf:byte;
         Vclk,
         Hclk,
         Fclk:longint;    {Freqs in Hz (Fclk is in mHz)}
        iLace:boolean;
         Flag:byte;       {Test results (AFF_)}
       end;
       {This record followed by: (Comment), (reg values)}

  _AT3=record  {Used for }
         mode:word;
        Mmode:byte;
         Flag:byte;       {Test results (AFF_)}
       end;
       {This record followed by: (Comment)}

  _ATff=record
          int10,
          int6D,
          m4a8,   {0:4A8h}
          fnt8h,
          fnt8l,
          fnt14,
          fnt14x9,
          fnt16,
          fnt16x9:word;
          Base:word;
          size:byte;
        end;
