		TITLE	'Listing 5-4'
		NAME	ReadPixel10
		PAGE	55,132

;
; Name:		ReadPixel10
;
; Function:	Read the value of a pixel in native EGA graphics modes
;
; Caller:	Microsoft C:
;
;			int ReadPixel10(x,y);
;
;			int x,y;		/* pixel coordinates */
;

ARGx		EQU	word ptr [bp+4]	; stack frame addressing
ARGy		EQU	word ptr [bp+6]


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_ReadPixel10
_ReadPixel10	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> buffer
					; CL := #bits to shift

		mov	ch,ah
		shl	ch,cl		; CH := bit mask in proper position

		mov	si,bx		; ES:SI -> regen buffer byte
		xor	bl,bl		; BL is used to accumulate the pixel value

		mov	dx,3CEh		; DX := Graphics Controller port
		mov	ax,304h		; AH := initial bit plane number
					; AL := Read Map Select register number

L01:		out	dx,ax		; select bit plane
		mov	bh,es:[si]	; BH := byte from current bit plane
		and	bh,ch		; mask one bit
		neg	bh		; bit 7 of BH := 1 (if masked bit = 1)
					; bit 7 of BH := 0 (if masked bit = 0)
		rol	bx,1		; bit 0 of BL := next bit from pixel value
		dec	ah		; AH := next bit plane number
		jge	L01

		mov	al,bl		; AL := pixel value
		xor	ah,ah		; AX := pixel value

		pop	si		; restore caller registers and return
		mov	sp,bp
		pop	bp
		ret

_ReadPixel10	ENDP

_TEXT		ENDS

		END
