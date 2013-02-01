		TITLE	'Listing 5-2'
		NAME	ReadPixel06
		PAGE	55,132

;
; Name:		ReadPixel06
;
; Function:	Read the value of a pixel in 640x200 2-color mode
;
; Caller:	Microsoft C:
;
;			int ReadPixel06(x,y);
;
;			int x,y;		/* pixel coordinates */
;

ARGx		EQU	word ptr [bp+4]	; stack frame addressing
ARGy		EQU	word ptr [bp+6]


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr06:near

		PUBLIC	_ReadPixel06
_ReadPixel06	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr06	; AH := bit mask
					; ES:BX -> buffer
					; CL := #bits to shift

		mov	al,es:[bx]	; AL := byte containing pixel
		shr	al,cl		; shift pixel value to low-order bits
		and	al,ah		; AL := pixel value
		xor	ah,ah		; AX := pixel value

		mov	sp,bp		; restore caller registers and return
		pop	bp
		ret

_ReadPixel06	ENDP

_TEXT		ENDS

		END
