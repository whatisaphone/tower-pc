		TITLE	'Listing 4-4'
		NAME	PixelAddr10
		PAGE	55,132

;
; Name:		PixelAddr10
;
; Function:	Determine buffer address of pixel in native EGA and VGA modes:
;			320x200 16-color
;			640x200 16-color
;			640x350 16-color
;			640x350 monochrome (4-color)
;			640x480 2-color
;			640x480 16-color
;
; Caller:	AX = y-coordinate
;		BX = x-coordinate
;
; Returns:	AH = bit mask
;		BX = byte offset in buffer
;		CL = number of bits to shift left
;		ES = video buffer segment
;


BytesPerLine	EQU	80		; bytes in one horizontal line
OriginOffset	EQU	0		; byte offset of (0,0)
VideoBufferSeg	EQU	0A000h

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	PixelAddr10
PixelAddr10	PROC	near

		mov	cl,bl		; CL := low-order byte of x

		push	dx		; preserve DX

		mov	dx,BytesPerLine	; AX := y * BytesPerLine
		mul	dx

		pop	dx
		shr	bx,1
		shr	bx,1
		shr	bx,1		; BX := x/8
		add	bx,ax		; BX := y*BytesPerLine + x/8
		add	bx,OriginOffset	; BX := byte offset in video buffer

		mov	ax,VideoBufferSeg
		mov	es,ax		; ES:BX := byte address of pixel

		and	cl,7		; CL := x & 7
		xor	cl,7		; CL := number of bits to shift left
		mov	ah,1		; AH := unshifted bit mask
		ret

PixelAddr10	ENDP

_TEXT		ENDS

		END
