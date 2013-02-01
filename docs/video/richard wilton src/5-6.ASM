		TITLE	'Listing 5-6'
		NAME	ReadPixel10
		PAGE	55,132

;
; Name:		ReadPixel10
;
; Function:	Read the value of a pixel in 640x350 modes on 64K EGA
;
; Caller:	Microsoft C:
;
;			int	ReadPixel10(x,y);
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

; concatenate bits from bit planes 2 and 0 (even byte address)
;  or 3 and 1 (odd byte address)

		mov	ch,ah
		shl	ch,cl		; CH := bit mask in proper position

		mov	si,bx		; ES:SI -> regen buffer byte

		mov	ah,bl		; AH := low-order byte of address
		and	ax,100h		; AH := low-order bit of address
					; AL := 0
		add	ax,204h		; AH := initial bit plane number (2 or 3)
					; AL := Read Map Select register number

		mov	dx,3CEh		; DX := Graphics Controller port
		xor	bl,bl		; BL is used to accumulate the pixel value

L01:		out	dx,ax		; (same as before)
		mov	bh,es:[si]
		and	bh,ch
		neg	bh

		rol	bx,1
		sub	ah,2
		jge	L01

		mov	al,bl
		xor	ah,ah

		pop	si
		mov	sp,bp
		pop	bp
		ret

_ReadPixel10	ENDP

_TEXT		ENDS

		END
