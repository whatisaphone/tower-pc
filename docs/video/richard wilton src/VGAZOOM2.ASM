LISTING 1: VGAZOOM2.ASM

;*****************************************************************************
;File VGAZOOM2 - 1280*400 VGA driver procedures
;Written by Arun Johary & Bo Ericsson,
;Chips & Technologies Inc.

;This file is not executable as stand-alone7
;After assembling6 link it whith VGAZOOM7OBJ,
;then convert to .COM whith EXE2BIN.

;Resulting VGAZOOM.COM is a TSR for implementing 1280x480 mode, 
;with zooming to/from 640x480 mode and panning.
;******************************************************************************

LORES	equ 0
HIRES	equ 1

public	DRAWCHR
public	SETMODE
public	HORIZ_SCROLL_4
public	VERT_SCROLL
public	EndOfProgram

code	segment para public 'code'
	assume cs:code

;*****************************************************************************
SETMODE	proc near
;Thith procedure procrams the VGA registers for one of two
;modes depending on AX
;AX = HIRES - high resolution 1280x400 monochrome mode
;AX = LORES - 640x400 monochrome mode

	push 	cs	;DS = CS because parameter tables
	pop	ds	; are in the current segment
	cld		;clear for subsequent auto increment
	cmp	ax,HIRES	; Hires mode ?
	jne	SetMode01	; if no, test for LORES mode
	lea	bx,HTABLE	;HIRES table selected
	jmp	SetTheMode	;program the parametrs
SetMode01:			;Test for LORES mode
	cmp	ax,LORES	;LORES mode ?
	jne	SetMode_End1	;invalid parameter, return to caller
	lea	bx,LTABLE	;lores table selected
	jmp	SetTheMode	;program the parameters
SetMode_End1:
	jmp	SetMode_End
SetTheMode:			;Sync reset while programming mode
	mov	dx,3C4H		;sequencer address
	mov	ax,0200H	;sync. reset
	out	dx,ax		;write the register
				;Set miscellaneous output register 
	mov	dx,3C2H		;miscellaneous output register address
	mov	al,[bx+9]	;table value for Misc Output Register.
	out	dx,al		;write the register
				;Set sequencer registers 01-04
	mov	dx,3C4H		;sequencer address
	mov	cx,4		;4 registers to write
	mov	ah,1		;start with reguster 1
	mov	si,bx		;beginning of parameter table
	add	si,5		;point to sequencer params in table
	call	W_IndexRegs	;program the registers
				;Get out of synchronous reset
	mov	dx,3C4H		;sequencer address
	mov	ax,0300h	;out of reset mode
	out	dx,ax		;write register
				;Unprotect CRT controller
	mov	dx,3D4H		;crtc address
	mov	ax,011h		;vertical sync end register
	out	dx,ax		;set protect bit (D7) to 0
				;Set CRT controller registers 00-18
	mov	cx,25		;25 registers to write
	xor	ah,ah		;start with CRTC register 0
	mov	si,bx		;beginning of parametr table
	add	si,10		;point to CRTC parameters in the table
	call	W_IndexRegs	;program the registers
				;Set Graphics controller regs 00-08
	mov	dx,3CEH		;graphics ctrl address
	mov	cx,9		;9 registers to write
	xor	ah,ah		;start with GC register 0
	mov	si,bx		;beginning of parametr table
	add	si,55		;point to GC parameter in the table
	call	W_IndexRegs	;program the registers
				;Set Attribute controller regs 00-14
	mov	dx,3DAH		;Statua register address
	in	al,dx		;reset attribute flip-flop
	mov	dx,3c0h		;attribute ctrl address
	mov	cx,20		;20 registers to write
	xor	ah,ah		;start with register 0
	mov	si,bx		;beginning of parameter table
	add	si,35		;point to Attr. Ctrl params in table
	call	W_Attr_Regs	;program the registers
	mov	al,14h		;write to Attributecolor select reg
	out	dx,al		;(not stored in parameter table)
	xor	al,al		;data=0
	out	dx,al		;write data
	mov	al,20h		;reenable video
	out	dx,al		;write the index reg to reenable video
				;Set external palette
	mov	dx,3C6H		;Palette mask register
	mov	al,0ffh		;enable all 8 bits
	out	dx,al		;write the mask
	mov	dx,3c8h		;Palette address register
	lea	si,[bx+64]	;point to palette parms in table
	xor	ah,ah		;start at palette reg 0
	mov	cx,4		;set 4 colors
	call	W_Palette	;program the palette registers
	SetMode_End:	;end of this procedure
		ret

;*****************************************************************************
; These two tables provide parameters for programming VGA hardwere
; in each of two modes

;*****************************************************************************
HTABLE label byte	; parameter table for 1280*400 mono mode

db 000h, 000h, 000h, 000h, 000h	;Dymmy header
db 005h, 00Fh, 000h, 00eh	;Sequencer offsets 01-04
db 063h				;Miscellaneous register

			; CRT Controller offsets 00-18h
db 05Fh, 04Fh, 050h, 082h, 054h, 080h, 0bFh, 01Fh
db 020h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 09ch, 00eh, 08Fh, 014h, 060h, 096h, 0b9h, 0abh, 0FFh

			; Attribute Controller offsets 00-13h
db 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
db 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00Fh
db 001h, 000h, 003h, 000h

			; Graphics Controller offsets 00-08
db 000h, 000h, 000h, 000h, 000h, 020h, 005h, 00Fh, 0FFh

			; DAC Palette registers 0-3
db 000h, 000h, 000h		;reg 0: black
db 01ah, 01ah, 01ah		;reg 1: grey
db 01ah, 01ah, 01ah		;reg 2: grey
db 02ah, 02ah, 02ah		;reg 3: white

;*****************************************************************************
LTABLE label byte	; parameter table for 640*400 mode

db 000h, 000h, 000h, 000h, 000h	;Dymmy header
db 011h, 00Fh, 000h, 00eh	;Sequencer offsets 01-04
db 063h				;Miscellaneous register

			; CRT Controller offsets 00-18h
db 05Fh, 050h, 052h, 0e2h, 054h, 0e0h, 0bFh, 01Fh
db 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
db 09ch, 00eh, 08Fh, 014h, 060h, 096h, 0b9h, 0a3h, 0FFh

			; Attribute Controller offsets 00-13h
db 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
db 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00Fh
db 001h, 000h, 001h, 000h

			; Graphics Controller offsets 00-08
db 000h, 000h, 000h, 000h, 000h, 000h, 005h, 00Fh, 0FFh

			; DAC Palette registers 0-3
db 000h, 000h, 000h		;reg 0: black
db 02ah, 02ah, 02ah		;reg 1: white
db 02ah, 02ah, 02ah		;reg 2: white
db 02ah, 02ah, 02ah		;reg 3: white

SETMODE endp

;*****************************************************************************
DRAWCHR proc near
; this procedure draws a character on the screen in the graphics
; mode; parametrs are expected to be as follows:
;AL: - char code
;BX: - bit map width
;DX: - font height (8 bits only)
;DS:SI - Disp Mem pointer
;ES:DI - Font pointer

	push	cx		;save CX
	mov	cx,dx		;get char height in CX
	mul	dl		;AX gets font offset for character
	add	di,ax		;ES:DI gets font address for font
LABL0:
	mov	ah,es:[di]	;read font pattern
	mov	ds:[si],ah	;write into display memory
	inc	di		;next line of font pattern
	add	si,bx		;next line in display memory
	loop	LABL0		;repeat for every scan line
	pop	cx		;retrieve CX
	ret
DRAWCHR endp

;*****************************************************************************
W_INDEXREGS proc near
;This procedure read a byte from the parameter table and then
;writes it to a index/data register.
;AH = index number of first register to receive parameter
;CX = # of index registers to be loaded
;DX - I/O port address
;DS:SI - points to parameters

	lodsb			;load parameter from table into AL
	xchg	al,ah		;get index in AL, data in AH
	out	dx,ax		;write index/data register pair
	xchg	al,ah		;get index in AH
	inc	ah		;next index
	loop	W_IndexRegs	;repeat
	ret
W_INDEXREGS ehdp

;*****************************************************************************
W_ATTR_REGS proc near
;This procedure reads a byte from the parameter table and then
; writes it to a self index/data register.
; AH = index number of first register to receive parameter
; CX = # of index registers to be loaded
; DX - I/O port address,
; DS:SI - points to parameters

	xchg	al,ah		;get index in AL
	out	dx,al		;write index
	xchg	al,ah		;get index in AH
	lodsb			;get data from table in AL
	out	dx,al		;write data
	inc	ah		;next index
	loop	W_Attr_Regs	;repeat
	ret
W_ATTR_REGS endp

;*****************************************************************************
W_PALETTE proc near
; This procedure reads a byte from parameter table and then
; writes it to the G171 palette/DAC. DS:SI - point to parameters,
; AH = starting index number,
; CX = # of index registers,
; DX - I/O addr of DAC address reg,
; DS:SI pointer to data area

	mov	al,ah
	out	dx,al
	inc	dx
W_pal1: lodsb
	out	dx,al
	lodsb
	out	dx,al
	lodsb
	out	dx,al
	loop	W_Pal1
	ret
W_PALETTE endp

;*****************************************************************************
RD_INDEXREG proc near
;This procedure reads an indexed VGA register
; Input: AL = index number of register
;	 DX = I/O address of register
; Ouput: register contents returned in AL

	out	dx,al
	inc	dx
	in	al,dx
	dec	dx
	ret
RD_INDEXREG endp

;*****************************************************************************
VERT_SCROLL proc near
; This procedure scrolls the screen up or down by a specified number
; of lines; parameters are expected to be as follows:
;	AX - scroll count, # scan lines in 2's complement form,
;	     negative for scroll down
;	BX - bit map width

	imul	bx		;AX = bytes to scroll
	mov	bx,ax		;save start address change in BX
	mov	dx,3d4h		; CRT address
	mov	al,0ch		; start address high
	call	Rd_IndexReg	;read register
	mov	ah,al		;move to AH
	mov	dx,3d4h		; CRT address
	mov	al,0ch		;start address low
	call	Rd_IndexReg	;read register
	add	bx,ax		;add change to old start address
	mov	ah,bh		;to get new start address, write the
	mov	al,0ch		;high byte back to CRTC
	out	dx,ax		;write new start address (HIGH)
	inc	al		;point to start address LOW register
	mov	ah,bl		;get lower byte of start address
	out	dx,ax		;write new start address (LOW)
	ret
VERT_SCROLL endp

;*****************************************************************************
HORIZ_SCROLL_4 proc near
; This procedure scrolls the screen left or right by a specified
; number of pixels. Parameters are expected to be as follows:
;	AX - scroll count, # pixels in 2's complement form,
;	     positive - scroll right, negative, scroll left.

	mov	bx,ax		;save scroll count
	mov	dx,3d4h		; CRT address
	mov	al,0ch		; start address high
	call	Rd_IndexReg	;read register
	mov	ah,al		;move to AH
	mov	dx,3d4h		; CRT address
	mov	al,0dh		; start address low
	call	Rd_IndexReg	;read register
	mov	bp,ax		;save current start address
	mov	dx,3d4h		; CRT address
	mov	al,08h		; byte panning control
	call	Rd_IndexReg	;read register
	mov	cl,2
	shr	al,cl		;divide by 4
	and	al,18h		;retain bits D3 and D4 only
	mov	ah,al		;save in AH
	mov	dx,3DAH		;Status register address
	in	al,dx		;reset attribute flip flop
	mov	dx,3C0H		;address for attribute controller
	mov	al,33h		;Panning Control
	out	dx,al		;point to attribute panning register
	inc	dx		;point to data register
	in	al,dx		;read current byte panning control
	dec	dx		;point back to Attr Ctrl address
	and	al,7		;retain bits D0-D2
	add	ah,al		;get old absolute panning control
	mov	al,ah		;move to AL, 0 into AH
	xor	ah,ah		;Absolute panning in AX
	add	bx,ax		;compute new absolute panning
	mov	ax,bx		;get it into AX
	and	al,7		;retain bits D0-D2
	out	dx,al		;write new attribute pan control
	mov	ax,bx		;new absolute pan control in AX
	mov	cl,2
	shl	ax,cl		;multiply by 4
	mov	ah,al		;save in AH
	and	ah,60h		;retain bits D6-D5
	mov	dx,3D4H		;CRTC address
	mov	al,8		;index for byte panning control reg
	out	dx,ax		;write new byte panning control
	mov	cl,5
	sar	bx,cl		;start address adjust
	add	bx,bp		;new start address
	mov	ah,bh		;upper bits go into start address
	mov	al,0ch		;Start Address high register index
	out	dx,ax		;Write start address high
	inc	al		;Start Address low index
	mov	ah,bl		;low byte of start address
	out	dx,ax		;Write start addres low
	ret
HORIZ_SCROLL_4 endp

EndOfProgram label byte
code	ends
	end


