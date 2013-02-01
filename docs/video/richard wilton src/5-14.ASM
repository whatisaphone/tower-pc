		TITLE	'Listing 5-14'
		NAME	SetPixel10
		PAGE	55,132

;
; Name:		SetPixel10
;
; Function:	Set the value of a pixel in native EGA graphics modes.
;
;		*** Write Mode 2 ***
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

RMWbits		EQU	18h		; read-modify-write bits


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_SetPixel10
_SetPixel10	PROC	near

		push	bp		; preserve stack frame
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> buffer
					; CL := # bits to shift left

; set Graphics Controller Bit Mask register

		shl	ah,cl		; AH := bit mask in proper position
		mov	dx,3CEh		; GC address register port
		mov	al,8		; AL := Bit Mask register number
		out	dx,ax

; set Graphics Controller Mode register

		mov	ax,205h		; AL :=  Mode register number
					; AH :=  Write Mode 2 (bits 0,1)
					;	 Read Mode 0 (bit 3)
		out	dx,ax

; set Data Rotate/Function Select register

		mov	ah,RMWbits	; AH := Read-Modify-Write bits
		mov	al,3		; AL := Data Rotate/Function Select reg
		out	dx,ax

; set the pixel value

		mov	al,es:[bx]	; latch one byte from each bit plane
		mov	al,ARGn		; AL := pixel value
		mov	es:[bx],al	; update all bit planes

; restore default Graphics Controller registers

		mov	ax,0FF08h	; default Bit Mask
		out	dx,ax

		mov	ax,0005		; default Mode register
		out	dx,ax

		mov	ax,0003		; default Function Select
		out	dx,ax

		mov	sp,bp		; restore stack frame and return
		pop	bp
		ret

_SetPixel10	ENDP

_TEXT		ENDS

		END
