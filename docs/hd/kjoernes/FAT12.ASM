;=-------------------------------------------------------------------------=
;
;			MZ Loader 2.0 FAT12 Boot Sector
;
;
;	Boot Sector Overview:
;	---------------------
;
;	- Support for multiple boot images. You can add more images
;	  between the szImageListDef/End labes. The first image found
;	  in the root directory will be loaded.
;
;	- Support for "MZ" executables as well as plain binaries.
;
;
;	Known limitations:
;	------------------
;
;	- Does not support FAT12 partitions beyond 8GB (INT13 extensions).
;	- Does not provide any error messages; calls INT18 on any errors.
;
;
;	Memory Map:
;	-----------
;
;	ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;	³ Interrupt Vector Table ³ 0000
;	ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;	³     BIOS Data Area     ³ 0040
;	ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;	³ PrtScr Status / Unused ³ 0050
;	ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;	³   Image Load Address   ³ 0060
;	ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;	³    Available Memory    ³ nnnn
;	ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;	³     2KB Boot Stack     ³ A000 - SizeOf(BootSector) - 2KB
;	ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;	³       Boot Sector      ³ A000 - SizeOf(BootSector)
;	ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´
;                                  A000
;
;
;	Boot Image Startup (register values):
;	-------------------------------------
;
;	ds = load segment, this is where the executable is loaded.
;	es = free segment, very first available paragraph above image.
;	ss = this is the stack segment somewhere near top of memory.
;
;	dl = boot drive number
;
;	dh = ??? (undoc)
;	cx = ??? (undoc)
;	si = ??? (undoc)
;	di = ??? (undoc)
;
;    ax:bx = CS:IP used to RETF to the image.
;
;    ss:sp = pointer to 2KB stack.
;    ss:bp = pointer to boot sector, with STD_VARS located below it.
;
;	The STD_VARS structure includes the relative LBA address of the
;	disk data area and the image load and FAT segment addresses.
;
;=-------------------------------------------------------------------------=

	.386p

	INCLUDE	fat.inc

codeSegment SEGMENT USE16 'boot'

	ASSUME	cs:codeSegment, ds:codeSegment, ss:codeSegment

	FAT12_BOOT <"MZLDR2.0">

	;=----------------------------------------------------------=
	; Detect memory, setup stack, buffers and relocate ourself
	;=----------------------------------------------------------=

	int	12h		; get conventional memory size
	shl	ax, 6		; and convert it to paragraphs

	sub	ax, 512 / 16	; es = ax - 512
	mov	es, ax		;

	; setup stack and base pointers

	sub	ax, 2048 / 16	; ss = ax - 2KB
	mov	ss, ax		;

	mov	sp, 2048	; 2KB stack
	mov	bp, sp		;

	mov	ax, 0060h	; ax = "load" segment

	; copy ourself to top of memory

	mov	cx, 256
	mov	si, 7C00h
	xor	di, di
	rep	movs WORD PTR es:[di], cs:[si]

	; jump to relocated code

	push	es
	push	OFFSET mainEntryPoint
	retf

mainEntryPoint:

	mov	BS.bsDriveNumber, dl

	;=----------------------------------------------------------=
	; Load entire FAT (maximum 6KB for FAT12)
	;=----------------------------------------------------------=

	push	ax		; ax = "load" segment

	mov	ax, BPB.bpbBytesPerSector
	mov	cx, BPB.bpbSectorsPerFAT
	mul	cx

	shr	ax, 4		; convert to paragraphs

	mov	di, ss		;
	sub	di, ax		; es = di = FAT buffer
	mov	es, di		;

	mov	ax, BPB.bpbReservedSectors
	call	int13ReadSector

	pop	es		; es = "load" segment

	;=----------------------------------------------------------=
	; Load entire Root Directory (maximum 16KB for FAT12/FAT16)
	;=----------------------------------------------------------=

	mov	ax, 32
	mov	si, BPB.bpbRootEntries
	mul	si
	div	BPB.bpbBytesPerSector

	xchg	ax, cx		; cx = root sectors, ax = zero

	mov	al, BPB.bpbNumberOfFATs
	mul	BPB.bpbSectorsPerFAT

	add	ax, BPB.bpbReservedSectors
	call	int13ReadSector

	push	dx		; stdDataAreaHi
	push	ax		; stdDataAreaLo
	push	di		; stdFATSegment	
	push	es		; stdBufSegment

	;=----------------------------------------------------------=
	; Look through list of "images" and load the first match
	;=----------------------------------------------------------=

	xchg	ax, si		; ax = root entries

	mov	si, OFFSET szImageListDef

bootFindNext:
	call	fat12FindFile	; found?
	jnc	bootLoadFile	;

	add	si, cx
	cmp	si, OFFSET szImageListEnd
	jb	bootFindNext

	int	18h

	; ToDo: add buffer overrun checking

bootLoadFile:
	call	fat12ReadCluster
	jnc	bootLoadFile

	;=----------------------------------------------------------=
	; Do some special checks on the image and transfer control
	;=----------------------------------------------------------=

	mov	ax, VAR.stdBufSegment
	mov	ds, ax

	xor	bx, bx
	xor	si, si

	; check for "MZ" executable signature

	cmp	WORD PTR ds:[si], "ZM"
	jne	bootExecFile

	add	ax, ds:[si][08h]	; ax = image base
	mov	cx, ds:[si][06h]	; cx = reloc items
	mov	bx, ds:[si][18h]	; bx = reloc table pointer

	jcxz	bootHackDone

bootHackFile:
	mov	di, ds:[bx][0]		; di = item ofs
	mov	dx, ds:[bx][2]		; dx = item seg (rel)
	add	dx, ax			; dx = item seg (abs)

	push	ds			;
	mov	ds, dx			; ds = dx
	add	ds:[di], ax		; fixup
	pop	ds			;

	add	bx, 4			; point to next entry
	dec	cx			; more?
	jnz	bootHackFile		;

bootHackDone:

	; adjust CS:IP according to header

	mov	bx, ds:[si][14h]	; ip
	add	ax, ds:[si][16h]	; cs

bootExecFile:

	mov	dl, BS.bsDriveNumber

	push	ax
	push	bx
	retf

;---------------------------------------------------------------------------
;	fat12ReadCluster
;
;	Entry:
;		ch = 0
;	      	si = cluster number to read
;		es = segment of read buffer
;	Exit:
;	      	si = next cluster number in chain (if CF == 0)
;		es = next segment
;
fat12ReadCluster PROC NEAR

	lea	ax, [si-2]

	; cx = sectors per cluster

	mov	cl, BPB.bpbSectorsPerCluster
	mul	cx	

	; add start of dataarea

	add	ax, VAR.stdDataAreaLo
	adc	dx, VAR.stdDataAreaHi

	call	int13ReadSector

	shr	bx, 4		; convert bytes into paragraphs

	mov	ax, es		; ax = our buffer
	add	ax, bx		; ax = old buffer + bytes read
	mov	es, ax		; es = new buffer

	mov	ds, VAR.stdFATSegment

	mov	ax, 3		;
	mul	si		; ax = si * 3 / 2
	shr	ax, 1		;

	xchg	ax, si		;

	mov	si, ds:[si]	; get next cluster

	jnc	fat12ReadClusterEven

	shr	si, 4		; keep upper 4 bits

fat12ReadClusterEven:
	and	si, 0FFFh	; mask off junk, EOF?
	cmp	si, 0FF8h	;
	cmc
	ret

fat12ReadCluster ENDP

;---------------------------------------------------------------------------
;	fat12FindFile
;
;	Entry:
;	      	ax = number of directory entries
;	     cs:si = pointer to filename string
;	        es = segment of root directory
;	Exit:
;		cx = 0Bh
;		si = initial cluster number
;	     es:di = pointer to matching entry (if CF == 0)
;
fat12FindFile PROC NEAR

	mov	cx, 11
	mov	dx, ax
	xor	di, di

fat12FindFileNext:
	pusha
	rep	cmps BYTE PTR cs:[si], es:[di]
	popa
	je	fat12FindFileDone

	add	di, 32
	dec	dx
	jnz	fat12FindFileNext

	stc
	ret

fat12FindFileDone:
	mov	si, es:[di].dirCluster
	ret

fat12FindFile ENDP

;---------------------------------------------------------------------------
;	int13ReadSector
;
;	Entry:
;		ax = sector number (16-bit LBA)
;		cx = sector count
;		es = sector buffer segment
;	Exit:
;		bx = number of bytes read
;	     	cx = zero
;	     dx:ax = sector number (32-bit LBA) of next sector
;
int13ReadSector PROC NEAR

	push	di

	xor	bx, bx
	xor	dx, dx

int13ReadNext:
	mov	di, 5		; five retries

int13ReadMore:
	pusha

	; add start of partition (harddisks only)

	add	ax, WORD PTR BPB.bpbHiddenSectors[0]
	adc	dx, WORD PTR BPB.bpbHiddenSectors[2]

	xor	cx, cx		; cx = null

	xchg	ax, cx		; ax = null, cx = LBA[0]
	xchg	ax, dx		; ax = LBA[2], dx = null

	div	BPB.bpbSectorsPerTrack

	xchg	ax, cx		; ax = LBA[0], cx = Result[2]

	div	BPB.bpbSectorsPerTrack

	xchg	dx, cx		; dx = Result[2], cx = Sector#
	inc	cx		; cx = one-based Sector#

	div	BPB.bpbHeadsPerCylinder

	mov	ch, al		; ch = Cylinder# [7:0]
	shl	ah, 6		; ah = Cylinder# [9:8]
	or	cl, ah		; combine Cylinder & Sector fields

	mov	dh, dl		; dh = Head#

	mov	dl, BS.bsDriveNumber

	mov	ax, 0201h
	int	13h
	jnc	int13ReadDone

;*	mov	ah, 00h		; uncomment if you want DISK RESETs
;*	int	13h		;

	popa

	dec	di
	jnz	int13ReadMore

	int	18h		;*

int13ReadDone:
	popa

	add	bx, BPB.bpbBytesPerSector

	inc	ax
	jnz	int13ReadSkip
	inc	dx

int13ReadSkip:
	dec	cx
	jnz	int13ReadNext

	pop	di
	ret

int13ReadSector ENDP

; list of possible boot images

szImageListDef	LABEL	BYTE
	DB	"LOADER  EXE"
szImageListEnd	LABEL	BYTE

	BOOT_MAGIC_HERE

codeSegment ENDS

	END
