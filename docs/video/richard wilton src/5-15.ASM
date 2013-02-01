		TITLE	'Listing 5-15'
		NAME	SetPixelInC
		PAGE	55,132

;
; Name:		SetPixelInC
;
; Function:	Set the value of a pixel in 720x348 16-color mode
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

DefaultRWColor	EQU	0Fh		; default value for R/W Color Register


DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		EXTRN	PixelAddrHGC:near

		PUBLIC	_SetPixelInC
_SetPixelInC	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddrHGC	; AH := bit mask
					; ES:BX -> buffer
					; CL := # bits to shift left

		shl	ah,cl		; AH := bit mask in proper position

		mov	dx,3B4h		; DX := CRTC port

		jmp	word ptr SetPixelOpInC	; jump to Replace, AND,
						;  OR or XOR routine


ReplacePixelInC:			; routine to Replace pixel value

		mov	ch,ah		; CH := bit mask for pixel
		mov	ax,1F19h	; AH bit 6 := 0 (Mask Polarity)
					; AH bits 5-4 := 1 (Write Mode)
					; AH bits 3-0 := "don't care" bits
					; AL := R/W Control Register number
		out	dx,ax		; set R/W Control Register

		inc	ax		; AL := 1Ah (R/W Color Reg number)
		mov	ah,ARGn		; AH := foreground value
		out	dx,ax		; set R/W color register

		and	es:[bx],ch	; update bit planes
		jmp	short L01

ANDPixelInC:				; routine to AND pixel value

		mov	ch,ah		; CH := bit mask for pixel
		mov	ax,1F19h	; AH bit 6 := 0 (Mask Polarity)
					; AH bits 5-4 := 1 (Write Mode)
					; AH bits 3-0 := "don't care" bits
					; AL := R/W Control Register number
		out	dx,ax		; set R/W Control Register

		dec	ax		; AL := 18h (Plane Mask Register number)
		mov	ah,ARGn		; AH := pixel value
		mov	cl,4
		shl	ah,cl		; AH bits 7-4 := writeable plane mask
		or	ah,0Fh		; AH bits 3-0 := visible plane mask
		out	dx,ax		; set Plane Mask Register

		mov	ax,001Ah	; AH := 0 (foreground value)
					; AL := 1Ah (R/W Color reg)
		out	dx,ax		; set R/W Color Register

		and	es:[bx],ch	; update bit planes
		jmp	short L01

					; routine to OR pixel value
ORPixelInC:	
		mov	ch,ah		; CH := bit mask for pixel
		mov	ax,1F19h	; AH bit 6 := 0 (Mask Polarity)
					; AH bits 5-4 := 1 (Write Mode)
					; AH bits 3-0 := "don't care" bits
					; AL := R/W Control Register number
		out	dx,ax		; set R/W Control Register

		dec	ax		; AL := 18h (Plane Mask Register number)
		mov	ah,ARGn		; AH := pixel value
		not	ah		; AH := complement of pixel value
		mov	cl,4
		shl	ah,cl		; AH bits 7-4 := writeable plane mask
		or	ah,0Fh		; AH bits 3-0 := visible plane mask
		out	dx,ax		; set Plane Mask Register

		mov	ax,0F1Ah	; AH := 0 (foreground value)
					; AL := 1Ah (R/W Color reg)
		out	dx,ax		; set R/W Color Register

		and	es:[bx],ch	; update bit planes
		jmp	short L01

XORPixelInC:				; routine to XOR pixel value
		mov	ch,ah		; CH := bit mask for pixel
		mov	ax,3F19h	; AH bit 6 := 0 (Mask Polarity)
					; AH bits 5-4 := 3 (Write Mode)
					; AH bits 3-0 := "don't care" bits
					; AL := R/W Control Register number
		out	dx,ax		; set R/W Control Register

		dec	ax		; AL := 18h (Plane Mask Register number)
		mov	ah,ARGn		; AH := pixel value
		not	ah		; AH := complement of pixel value
		mov	cl,4
		shl	ah,cl		; AH bits 7-4 := writeable plane mask
		or	ah,0Fh		; AH bits 3-0 := visible plane mask
		out	dx,ax		; set Plane Mask Register

		xor	es:[bx],ch	; update bit planes

L01:		mov	ax,0F18h
		out	dx,ax		; restore default Plane Mask value

		mov	ax,4019h	; restore default R/W Control value
		out	dx,ax

		inc	ax		; restore default R/W Color value
		mov	ah,DefaultRWColor
		out	dx,ax

		mov	sp,bp		; restore caller registers and return
		pop	bp
		ret

_SetPixelInC	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

SetPixelOpInC	DW	ReplacePixelInc	; contains addr of pixel operation

_DATA		ENDS

		END
