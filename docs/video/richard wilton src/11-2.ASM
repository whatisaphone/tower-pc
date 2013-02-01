		TITLE	'Listing 11-2'
		NAME	StoreBitBlock06
		PAGE	55,132

;
; Name:		StoreBitBlock06
;
; Function:	Copy bit block from video buffer to system RAM
;		 in 640x200 2-color mode
;
; Caller:	Microsoft C:
;
;			void StoreBitBlock06(buf,x,y);
;
;			     char far *buf;   /* buffer */
;			     int x,y;    /* upper left corner of bit block */
;


ADDRbuf		EQU	dword ptr [bp+4]
ARGx		EQU	word ptr [bp+8]
ARGy		EQU	word ptr [bp+10]

VARPixelRows	EQU	word ptr [bp-2]
VARPixelRowLen	EQU	word ptr [bp-4]
VARincr		EQU	word ptr [bp-6]


DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		EXTRN	PixelAddr06:near

		PUBLIC	_StoreBitBlock06
_StoreBitBlock06 PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,6		; establish stack frame
		push	ds
		push	si
		push	di

; establish addressing

		mov	ax,ARGy
		mov	bx,ARGx
		call	PixelAddr06	; ES:BX -> byte offset of x,y
		xor	cl,7		; CL := number of bits to shift right

		mov	di,bx		; ES:DI -> x,y in video buffer
		
		mov	bx,2000h	; BX := increment from 1st to 2nd
					;  interleave in CGA video buffer
		test	di,2000h
		jz	L01		; jump if x,y is in 1st interleave

		mov	bx,80-2000h	; increment from 2nd to 1st interleave

L01:		mov	VARincr,bx	; initialize this variable

		mov	bx,StoreBitBlockOp  ; BX := subroutine address

		lds	si,ADDRbuf	; ES:DI -> buffer in system RAM

; obtain dimensions of bit block from header

		lodsw			; AX := number of pixel rows
		mov	VARPixelRows,ax
		lodsw			; AX := bytes per pixel row
		mov	VARPixelRowLen,ax
		lodsb			; AL := bit mask for last byte in row
		mov	ch,al

		jmp	bx		; jump to subroutine


ReplaceBitBlock:
		cmp	cx,0FF00h	; if mask <> 0FFH or bits to shift <> 0
		jne	L15		;  jump if not byte-aligned

; routine for byte-aligned bit blocks

		mov	cx,VARPixelRowLen

L10:		push	di		; preserve DI and CX
		push	cx
		rep	movsb		; copy one pixel row into video buffer
		pop	cx		; restore DI and CX
		pop	di	
		add	di,VARincr	; ES:DI -> next pixel row in buffer
		xor	VARincr,2000h XOR (80-2000h) ; update increment
		dec	VARPixelRows
		jnz	L10		; loop down pixel rows

		jmp	Lexit

; routine for all other bit blocks

L15:		not	ch		; CH := mask for end of row
		mov	dx,0FF00h
		ror	dx,cl		; DX := rotated mask for each byte

		mov	bx,VARPixelRowLen
		dec	bx		; BX := bytes per row - 1

L16:		push	di
		test	bx,bx
		jz	L18		; jump if only one byte per row

		push	bx

L17:		and	es:[di],dx	; mask next 8 pixels in video buffer
		lodsb			; AL := pixels in bit block
		xor	ah,ah
		ror	ax,cl		; AX := pixels rotated into position
		or	es:[di],ax	; set pixels in video buffer
		inc	di		; ES:DI -> next byte in bit block
		dec	bx
		jnz	L17

		pop	bx

L18:		mov	al,ch
		mov	ah,0FFh		; AX := mask for last pixels in row
		ror	ax,cl		; AX := mask rotated into position
		and	es:[di],ax	; mask last pixels in video buffer
		lodsb			; AL := last byte in row
		xor	ah,ah
		ror	ax,cl		; AX := pixels rotated into position
		or	es:[di],ax	; set pixels in video buffer

		pop	di
		add	di,VARincr	; ES:DI -> next pixel row in buffer
		xor	VARincr,2000h XOR (80-2000h)
		dec	VARPixelRows
		jnz	L16		; loop down pixel rows

		jmp	Lexit


XORBitBlock:
		mov	bx,VARPixelRowLen

L20:		push	di
		push	bx

L21:		lodsb			; AL := pixels in bit block
		xor	ah,ah
		ror	ax,cl		; AX := pixels rotated into position
		xor	es:[di],ax	; XOR pixels into video buffer
		inc	di		; ES:DI -> next byte in bit block
		dec	bx
		jnz	L21

		pop	bx
		pop	di
		add	di,VARincr	; ES:DI -> next pixel row in buffer
		xor	VARincr,2000h XOR (80-2000h)
		dec	VARPixelRows
		jnz	L20		; loop down pixel rows

		jmp	Lexit

ANDBitBlock:
		not	ch		; CH := mask for end of row

		mov	bx,VARPixelRowLen
		dec	bx		; BX := bytes per row - 1

L30:		push	di
		test	bx,bx
		jz	L32		; jump if only one byte per row

		push	bx

L31:		lodsb			; AL := pixels in bit block
		mov	ah,0FFh
		ror	ax,cl		; AX := pixels rotated into position
		and	es:[di],ax	; AND pixels into video buffer
		inc	di		; ES:DI -> next byte in bit block
		dec	bx
		jnz	L31

		pop	bx

L32:		lodsb			; AL := last byte in row
		or	al,ch		; mask last pixels in row
		mov	ah,0FFh
		ror	ax,cl		; AX := pixels rotated into position
		and	es:[di],ax	; AND pixels into video buffer

		pop	di
		add	di,VARincr	; ES:DI -> next pixel row in buffer
		xor	VARincr,2000h XOR (80-2000h)
		dec	VARPixelRows
		jnz	L30		; loop down pixel rows

		jmp	Lexit


ORBitBlock:
		mov	bx,VARPixelRowLen

L40:		push	di
		push	bx

L41:		lodsb			; AL := pixels in bit block
		xor	ah,ah
		ror	ax,cl		; AX := pixels rotated into position
		or	es:[di],ax	; OR pixels into video buffer
		inc	di		; ES:DI -> next byte in bit block
		dec	bx
		jnz	L41

		pop	bx
		pop	di
		add	di,VARincr	; ES:DI -> next pixel row in buffer
		xor	VARincr,2000h XOR (80-2000h)
		dec	VARPixelRows
		jnz	L40		; loop down pixel rows


Lexit:		pop	di		; restore registers and exit
		pop	si
		pop	ds
		mov	sp,bp
		pop	bp
		ret

_StoreBitBlock06 ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

StoreBitBlockOp	DW	ReplaceBitBlock	; address of selected subroutine
					;  (Replace, XOR, AND, OR)

_DATA		ENDS

		END
