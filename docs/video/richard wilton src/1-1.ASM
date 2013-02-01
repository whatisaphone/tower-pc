		TITLE	'Listing 1-1'
		NAME	SetVmode
		PAGE	55,132

;
; Name:		SetVmode
;
; Function:	Call IBM PC ROM BIOS to set a video display mode.
;
; Caller:	Microsoft C:
;
;			void SetVmode(n);
;
;			int n;			/* video mode */
;

ARGn		EQU	byte ptr [bp+4]	; stack frame addressing

EQUIP_FLAG	EQU	byte ptr ds:[10h]

CGAbits		EQU	00100000b	; bits for EQUIP_FLAG
MDAbits		EQU	00110000b

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	_SetVmode
_SetVmode	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	ds

		mov	ax,40h
		mov	ds,ax		; DS -> Video Display Data Area

		mov	bl,CGAbits	; BL := bits indicating presence of CGA

		mov	al,ARGn		; AL := desired video mode number

		mov	ah,al		; test if desired mode is monochrome
		and	ah,7
		cmp	ah,7
		jne	L01		; jump if desired mode not 7 or 0Fh

		mov	bl,MDAbits	; BL := bits indicating presence of MDA

L01:		and	EQUIP_FLAG,11001111b
		or	EQUIP_FLAG,bl	; set bits in EQUIP_FLAG

		xor	ah,ah		; AH := 0 (INT 10h function number)

		push	bp
		int	10h		; call ROM BIOS to set the video mode
		pop	bp

		pop	ds		; restore caller registers and return
		mov	sp,bp
		pop	bp
		ret

_SetVmode	ENDP

_TEXT		ENDS

		END
