		TITLE	'Listing 5-5'
		NAME	ReadPixel0F
		PAGE	55,132

;
; Name:		ReadPixel0F
;
; Function:	Read the value of a pixel in 640x350 monochrome mode
;
; Caller:	Microsoft C:
;
;			int	ReadPixel0F(x,y);
;
;			int x,y;		/* pixel coordinates */
;

ARGx		EQU	word ptr [bp+4]	; stack frame addressing
ARGy		EQU	word ptr [bp+6]


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_ReadPixel0F
_ReadPixel0F	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> buffer
					; CL := #bits to shift

; concatenate bits from bit planes 2 and 0

		mov	ch,ah
		shl	ch,cl		; CH := bit mask in proper position
		mov	si,bx		; ES:SI -> regen buffer byte

		mov	dx,3CEh		; DX := Graphics Controller port
		mov	ax,204h		; AH := initial bit plane number
					; AL := Read Map Select register number

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

_ReadPixel0F	ENDP

_TEXT		ENDS

		END
