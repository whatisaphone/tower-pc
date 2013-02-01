		TITLE	'Listing 4-3'
		NAME	PixelAddrHGC
		PAGE	55,132

;
; Name:		PixelAddrHGC
;
; Function:	Determine buffer address of pixel in 720x348 Hercules graphics
;
; Caller:	AX = y-coordinate (0-347)
;		BX = x-coordinate (0-719)
;
; Returns:	AH = bit mask
;		BX = byte offset in buffer
;		CL = number of bits to shift left
;		ES = video buffer segment
;

BytesPerLine	EQU	90
OriginOffset	EQU	0		; byte offset of (0,0)
VideoBufferSeg	EQU	0B000h

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	PixelAddrHGC
PixelAddrHGC	PROC	near

		mov	cl,bl		; CL := low-order byte of x

		shr	ax,1		; AX := y/2
		rcr	bx,1		; BX := 8000h*(y&1) + x/2
		shr	ax,1		; AX := y/4
		rcr	bx,1		; BX := 4000h*(y&3) + x/4
		shr	bx,1		; BX := 2000h*(y&3) + x/8
		mov	ah,BytesPerLine
		mul	ah		; AX := BytesPerLine*(y/4)
		add	bx,ax		; BX := 2000h*(y&3) + x/8 + BytesPerLine*(y/4)
		add	bx,OriginOffset	; BX := byte offset in video buffer

		mov	ax,VideoBufferSeg
		mov	es,ax		; ES:BX := byte address of pixel

		and	cl,7		; CL := x & 7
		xor	cl,7		; CL := number of bits to shift left
		mov	ah,1		; AH := unshifted bit mask

		ret

PixelAddrHGC	ENDP

_TEXT		ENDS

		END
