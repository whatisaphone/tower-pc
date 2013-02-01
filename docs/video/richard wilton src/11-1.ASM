		TITLE	'Listing 11-1'
		NAME	GetBitBlock06
		PAGE	55,132

;
; Name:		GetBitBlock06
;
; Function:	Copy bit block from video buffer to system RAM
;		 in 640x200 2-color mode
;
; Caller:	Microsoft C:
;
;			int GetBitBlock06(x0,y0,x1,y1,buf);
;
;			     int x0,y0;    /* upper left corner of bit block */
;			     int x1,y1;       /* lower right corner */
;			     char far *buf;   /* buffer */
;
; Notes:	Returns size of bit block in system RAM.
;


ARGx0		EQU	word ptr [bp+4]
ARGy0		EQU	word ptr [bp+6]
ARGx1		EQU	word ptr [bp+8]
ARGy1		EQU	word ptr [bp+10]
ADDRbuf		EQU	         [bp+12]

VARPixelRows	EQU	word ptr [bp-2]
VARPixelRowLen	EQU	word ptr [bp-4]
VARincr		EQU	word ptr [bp-6]

ByteOffsetShift	EQU	3		; reflects number of pixels per byte


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr06:near

		PUBLIC	_GetBitBlock06
_GetBitBlock06	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,6		; establish stack frame
		push	ds
		push	si
		push	di

; compute dimensions of bit block

		mov	ax,ARGx1
		sub	ax,ARGx0
		mov	cx,0FF07h	; CH := unshifted bit mask
					; CL := AND mask for AL
		and	cl,al		; CL := number of pixels in last
					;  byte of row
		xor	cl,7		; CL := number of bits to shift
		shl	ch,cl		; CH := bit mask for last byte of row
		mov	cl,ch
		push	cx		; save on stack

		mov	cl,ByteOffsetShift
		shr	ax,cl
		inc	ax		; AX := number of bytes per row
		push	ax		; save on stack

		mov	ax,ARGy1
		sub	ax,ARGy0
		inc	ax		; AX := number of pixel rows
		push	ax		; save on stack

; establish addressing

		mov	ax,ARGy0
		mov	bx,ARGx0
		call	PixelAddr06	; ES:BX -> x0,y0 in video buffer
		xor	cl,7		; CL := number of bits to shift left
		push	es
		pop	ds
		mov	si,bx		; DS:SI -> video buffer

		mov	bx,2000h	; BX := increment from 1st to 2nd
					;  interleave in CGA video buffer
		test	si,2000h
		jz	L01		; jump if x0,y0 is in 1st interleave

		mov	bx,80-2000h	; increment from 2nd to 1st interleave

L01:		mov	VARincr,bx	; initialize this variable

		les	di,ADDRbuf	; ES:DI -> buffer in system RAM

; build 5-byte bit block header

		pop	ax
		mov	VARPixelRows,ax
		stosw			; byte 0-1 := number of pixel rows
		pop	ax
		mov	VARPixelRowLen,ax
		stosw			; byte 2-3 := bytes per pixel row
		pop	ax
		mov	ch,al		; CH := bit mask for last byte
		stosb			; byte 4 := bit mask for last byte

; copy from video buffer to system RAM

L02:		mov	bx,VARPixelRowLen
		push	si		; preserve SI at start of pixel row

L03:		lodsw			; AL := next byte in video buffer
					; AH := (next byte) + 1
		dec	si		; DS:SI -> (next byte) + 1
		rol	ax,cl		; AL := next 4 pixels in row
		stosb			; copy to system RAM
		dec	bx		; loop across row
		jnz	L03

		and	es:[di-1],ch	; mask last byte of row		
		pop	si		; DS:SI -> start of row
		add	si,VARincr	; DS:SI -> start of next row
		xor	VARincr,2000h XOR (80-2000H)  ; update increment

		dec	VARPixelRows
		jnz	L02		; loop down rows

		mov	ax,di
		sub	ax,ADDRbuf	; AX := return value (size of bit block
					;  in system RAM)

		pop	di		; restore registers and exit
		pop	si
		pop	ds
		mov	sp,bp
		pop	bp
		ret

_GetBitBlock06	ENDP

_TEXT		ENDS

		END
