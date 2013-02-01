		TITLE	'Listing 5-11'
		NAME	SetPixel04
		PAGE	55,132

;
; Name:		SetPixel04
;
; Function:	Set the value of a pixel in 320x200 4-color mode
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

		EXTRN	PixelAddr04:near

		PUBLIC	_SetPixel04
_SetPixel04	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr04	; AH := bit mask
					; ES:BX -> buffer
					; CL := #bits to shift left

		mov	al,ARGn
		shl	ax,cl		; AH := bit mask in proper position
					; AL := pixel value in proper position

		jmp	word ptr SetPixelOp04	; jump to Replace, AND,
						;  OR or XOR routine


					; routine to Replace pixel value

ReplacePixel04:	not	ah		; AH := inverse bit mask
		and	es:[bx],ah	; zero the pixel value
		or	es:[bx],al	; set the pixel value
		jmp	short L02

					; routine to AND pixel value

ANDPixel04:	not	ah		; AH := inverse bit mask
		or	al,ah		; AL := all 1's except pixel value
		and	es:[bx],al
		jmp	short L02
				
					
ORPixel04:	or	es:[bx],al	; routine to OR pixel value
		jmp	short L02


XORPixel04:	xor	es:[bx],al	; routine to XOR pixel value
		

L02:		mov	sp,bp		; restore caller registers and return
		pop	bp
		ret

_SetPixel04	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

SetPixelOp04	DW	ReplacePixel04	; contains addr of pixel operation

_DATA		ENDS

		END
