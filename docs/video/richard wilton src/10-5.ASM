		TITLE	'Listing 10-5'
		NAME	SetFontPages
		PAGE	55,132

;
; Name:		SetFontPages
;
;		Update MCGA Font Pages
;
; Caller:	Microsoft C:
;
;			void SetFontPages(n0,n1);
;
;			int	n0,n1;	/* font page values */
;

ARGn0		EQU	[bp+4]
ARGn1		EQU	[bp+6]

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	_SetFontPages
_SetFontPages	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,1103h	; AH := INT 10H function number
					; AL := 3 (Set Block Specifier)
		mov	bl,ARGn1	; BL := value for bits 2-3
		shl	bl,1
		shl	bl,1		; BL bits 2-3 := n1
		or	bl,ARGn0	; BL bits 0-1 := n0
		int	10h		; load font pages

		pop	bp
		ret		

_SetFontPages	ENDP

_TEXT		ENDS

		END
