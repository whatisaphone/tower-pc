		TITLE	'Listing 5-17'
		NAME	SetPixel13
		PAGE	55,132

;
; Name:		SetPixel13
;
; Function:	Set the value of a pixel in VGA 320x200 256-color mode
;
; Caller:	Microsoft C:
;
;			void SetPixel(x,y,n);
;
;			int x,y;		/* pixel coordinates */
;
;			int n;			/* pixel value */
;

ARGx		EQU	word ptr [bp+4]	; stack frame addressing
ARGy		EQU	word ptr [bp+6]
ARGn		EQU	byte ptr [bp+8]

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		EXTRN	PixelAddr13:near

		PUBLIC	_SetPixel13
_SetPixel13	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr13	; ES:BX -> buffer

		mov	al,ARGn		; AL := pixel value

		jmp	word ptr SetPixelOp13	; jump to Replace, AND,
						;  OR or XOR routine


ReplacePixel13:	mov	es:[bx],al
		jmp	short L01

ANDPixel13:	and	es:[bx],al
		jmp	short L01

ORPixel13:	or	es:[bx],al
		jmp	short L01

XORPixel13:	xor	es:[bx],al


L01:		mov	sp,bp		; restore caller registers and return
		pop	bp
		ret

_SetPixel13	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

SetPixelOp13	DW	ReplacePixel13

_DATA		ENDS

		END
