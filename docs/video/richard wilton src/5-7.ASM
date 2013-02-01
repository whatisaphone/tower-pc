		TITLE	'Listing 5-7'
		NAME	ReadPixelInC
		PAGE	55,132

;
; Name:		ReadPixelInC
;
; Function:	Read the value of a pixel in InColor 720x348 16-color mode
;
; Caller:	Microsoft C:
;
;			int	ReadPixelInC(x,y);
;
;			int x,y;
;

ARGx		EQU	word ptr [bp+4]	; stack frame addressing
ARGy		EQU	word ptr [bp+6]

DefaultRWColor	EQU	0Fh		; default value for R/W Color Register


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddrHGC:near

		PUBLIC	_ReadPixelInC
_ReadPixelInC	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddrHGC	; AH := bit mask
					; ES:BX -> buffer
					; CL := #bits to shift

; set up to examine each bit plane separately

		mov	si,bx		; ES:SI -> buffer

		shl	ah,cl
		mov	cl,ah		; CL := bit mask in proper position

		mov	dx,3B4h		; DX := graphics control port

		mov	ax,0F01Ah	; AH bits 4-7 := 1111b (background value)
					; AL := 1Ah (R/W Color Register)
		out	dx,ax		; set background value

		mov	bx,800h		; BH := 1000b (initial "don't care" bits)
					; BL := 0 (initial value for result)

		dec	ax		; AL := 19h (R/W Control Register number)

; loop across bit planes by updating "don't care" bits

L01:		mov	ah,bh		; AH bits 0-3 := next "don't care" bits
					; AH bit 6 := 0 (Mask Polarity bit)
		xor	ah,1111b	; invert "don't care" bits
		out	dx,ax		; set R/W Control Register

		mov	ch,cl		; CH := bit mask
		and	ch,es:[si]	; latch bit planes
					; CH <> 0 if bit in latch is set

		neg	ch		; cf set if CH <> 0
		rcl	bl,1		; accumulate result in BL

		shr	bh,1		; BH := shifted "don't care" bits
		jnz	L01		; loop until shifted out of BH,
					;  at which point BX = pixel value
; restore default state

		mov	ah,40h		; AH := default R/W Control Register value
		out	dx,ax

		inc	ax		; AL := 1Ah (R/W Color Register number)
		mov	ah,DefaultRWColor
		out	dx,ax

		mov	ax,bx		; AX := pixel value

		pop	si		; restore caller registers and return
		mov	sp,bp
		pop	bp
		ret

_ReadPixelInC	ENDP

_TEXT		ENDS

		END
