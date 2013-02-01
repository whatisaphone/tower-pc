		TITLE	'Listing 5-10'
		NAME	SetPixel06
		PAGE	55,132

;
; Name:		SetPixel06
;
; Function:	Set the value of a pixel in 640x200 2-color mode
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

		EXTRN	PixelAddr06:near

		PUBLIC	_SetPixel06
_SetPixel06	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr06	; AH := bit mask
					; ES:BX -> buffer
					; CL := # bits to shift left

		mov	al,ARGn		; AL := unshifted pixel value
		shl	ax,cl		; AH := bit mask in proper position
					; AL := pixel value in proper position

		jmp	word ptr SetPixelOp06	; jump to Replace, AND,
						;  OR or XOR routine


					; routine to Replace pixel value

ReplacePixel06:	not	ah		; AH := inverse bit mask
		and	es:[bx],ah	; zero the pixel value
		or	es:[bx],al	; set the pixel value
		jmp	short L02


					; routine to AND pixel value
ANDPixel06:	test	al,al
		jnz	L02		; do nothing if pixel value = 1

L01:		not	ah		; AH := inverse of bit mask
		and	es:[bx],ah	; set bit in video buffer to 0
		jmp	short L02
				

					; routine to OR pixel value
ORPixel06:	test	al,al
		jz	L02		; do nothing if pixel value = 0

		or	es:[bx],al	; set bit in video buffer
		jmp	short L02


					; routine to XOR pixel value
XORPixel06:	test	al,al
		jz	L02		; do nothing if pixel value = 0

		xor	es:[bx],al	; XOR bit in video buffer

		
L02:		mov	sp,bp		; restore caller registers and return
		pop	bp
		ret

_SetPixel06	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

SetPixelOp06	DW	ReplacePixel06	; contains addr of pixel operation

_DATA		ENDS

		END
