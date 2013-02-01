		TITLE	'Listing 4-5'
		NAME	PixelAddr13
		PAGE	55,132

;
; Name:		PixelAddr13
;
; Function:	Determine buffer address of pixel in 320x200 256-color mode
;
; Caller:	AX = y-coordinate (0-199)
;		BX = x-coordinate (0-319)
;
; Returns:	BX = byte offset in buffer
;		ES = video buffer segment
;


OriginOffset	EQU	0		; byte offset of (0,0)
VideoBufferSeg	EQU	0A000h

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	PixelAddr13
PixelAddr13	PROC	near

		xchg	ah,al		; AX := 256*y
		add	bx,ax		; BX := 256*y + x
		shr	ax,1
		shr	ax,1		; AX := 64*y
		add	bx,ax		; BX := 320*y + x

		add	bx,OriginOffset	; BX := byte offset in video buffer

		mov	ax,VideoBufferSeg
		mov	es,ax		; ES:BX := byte address of pixel
		ret

PixelAddr13	ENDP

_TEXT		ENDS

		END
