		TITLE	'Listing 5-13'
		NAME	SetPixel10
		PAGE	55,132

;
; Name:		SetPixel10
;
; Function:	Set the value of a pixel in native EGA graphics modes.
;
;		*** Write Mode 0, Sequencer Map Mask ***
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


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_SetPixel10
_SetPixel10	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> buffer
					; CL := # bits to shift left

; set Graphics Controller Bit Mask register

		shl	ah,cl		; AH := bit mask in proper position
		mov	dx,3CEh		; Graphics Controller address reg port
		mov	al,8		; AL := Bit Mask register number
		out	dx,ax

; zero the pixel value

		mov	al,es:[bx]	; latch one byte from each bit plane
		mov	byte ptr es:[bx],0  ; zero masked bits in all planes

; set Sequencer Map Mask register

		mov	dl,0C4h		; DX := 3C4h (Sequencer addr reg port)
		mov	ah,ARGn		; AH := value for Map Mask register
					;  (nonzero bits in pixel value select
					;    enabled bit planes for Sequencer)
		mov	al,2		; AL := Map Mask register number
		out	dx,ax

; set the nonzero bits in the pixel value

		mov	byte ptr es:[bx],0FFh ; set bits in enabled bit planes

; restore default Sequencer registers

		mov	ah,0Fh		; AH := value for Map Mask reg (all bit
					;  planes enabled)
		out	dx,ax

; restore default Graphics Controller registers

		mov	dl,0CEh		; DX := 3CEh (Graphics Controller port)
		mov	ax,0FF08h	; default Bit Mask
		out	dx,ax

		mov	sp,bp		; restore caller registers and return
		pop	bp
		ret

_SetPixel10	ENDP

_TEXT		ENDS

		END
