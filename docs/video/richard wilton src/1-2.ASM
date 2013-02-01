		TITLE	'Listing 1-2'
		NAME	GetVmode
		PAGE	55,132

;
; Name:		GetVmode
;
; Function:	Call IBM PC ROM BIOS to set a video display mode.
;
; Caller:	Microsoft C:
;
;			int	GetVmode();
;

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	_GetVmode
_GetVmode	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ah,0Fh		; AH := 0Fh (INT 10h function number)

		push	bp
		int	10h		; call ROM BIOS to get video mode number
		pop	bp

		xor	ah,ah		; AX := video mode number

		mov	sp,bp
		pop	bp
		ret

_GetVmode	ENDP

_TEXT		ENDS

		END
