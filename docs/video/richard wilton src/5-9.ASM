		TITLE	'Listing 5-9'
		NAME	ReadPixel13
		PAGE	55,132

;
; Name:		ReadPixel13
;
; Function:	Read the value of a pixel in 320x200 256-color mode (MCGA and VGA)
;
; Caller:	Microsoft C:
;
;			int ReadPixel13(x,y);
;
;			int x,y;		/* pixel coordinates */
;

ARGx		EQU	word ptr [bp+4]	; stack frame addressing
ARGy		EQU	word ptr [bp+6]


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr13:near

		PUBLIC	_ReadPixel13
_ReadPixel13	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr13	; ES:BX -> buffer

		mov	al,es:[bx]	; AL := pixel value
		xor	ah,ah		; AX := pixel value

		mov	sp,bp
		pop	bp
		ret

_ReadPixel13	ENDP

_TEXT		ENDS

		END
