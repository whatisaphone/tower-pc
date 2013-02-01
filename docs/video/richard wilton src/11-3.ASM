		TITLE	'Listing 11-3'
		NAME	GetBitBlock10
		PAGE	55,132

;
; Name:		GetBitBlock10
;
; Function:	Copy bit block from video buffer to system RAM
;		 in native EGA and VGA graphics modes
;
; Caller:	Microsoft C:
;
;			int GetBitBlock10(x0,y0,x1,y1,buf);
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

BytesPerRow	EQU	80
ByteOffsetShift	EQU	3		; reflects number of pixels per byte


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_GetBitBlock10
_GetBitBlock10	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,4		; establish stack frame
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
		call	PixelAddr10	; ES:BX -> x0,y0 in video buffer
		xor	cl,7		; CL := number of bits to shift left
		push	es
		pop	ds
		mov	si,bx		; DS:SI -> video buffer

		les	di,ADDRbuf	; ES:DI -> buffer in system RAM

; build 5-byte bit block header

		pop	ax
		mov	VARPixelRows,ax
		stosw			; byte 0-1 := number of pixel rows
		pop	ax
		mov	VARPixelRowLen,ax
		stosw			; byte 2-3 := bytes per pixel row
		pop	ax
		mov	ch,al		; CH := bit mask for last byte in row
		stosb			; byte 4 := bit mask for last byte

; set up Graphics Controller

		mov	dx,3CEh		; DX := Graphics Controller address port

		mov	ax,0005		; AH := 0 (read mode 0, write mode 0)
					; AL := 5 (Mode register number)
		out	dx,ax		; set up read mode 0
 
		mov	ax,0304h	; AH := 3 (first bit plane to read)
					; AL := 4 (Read Map Select reg number)

; copy from video buffer to system RAM

L01:		out	dx,ax		; select next memory map to read
		push	ax		; preserve memory map number
		push	VARPixelRows	; preserve number of pixel rows
		push	si		; preserve offset of x0,y0

L02:		mov	bx,VARPixelRowLen
		push	si		; preserve SI at start of pixel row

L03:		lodsw			; AL := next byte in video buffer
					; AH := (next byte) + 1
		dec	si		; DS:SI -> (next byte) + 1
		rol	ax,cl		; AL := next 4 pixels in row
		stosb			; copy to system RAM
		dec	bx		; loop across row
		jnz	L03

		and	es:[di-1],ch	; mask last byte in row
		pop	si		; DS:SI -> start of row
		add	si,BytesPerRow	; DS:SI -> start of next row

		dec	VARPixelRows
		jnz	L02		; loop down rows

		pop	si		; DS:SI -> start of bit block
		pop	VARPixelRows	; restore number of pixel rows
		pop	ax		; AH := last map read
					; AL := Read Map Select reg number
		dec	ah
		jns	L01		; loop across bit planes

		mov	ax,di
		sub	ax,ADDRbuf	; AX := return value (size of bit block
					;  in system RAM)

		pop	di		; restore registers and exit
		pop	si
		pop	ds
		mov	sp,bp
		pop	bp
		ret

_GetBitBlock10	ENDP

_TEXT		ENDS

		END
