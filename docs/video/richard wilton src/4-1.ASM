		TITLE	''Listing 4-1'
		NAME	PixelAddr04
		PAGE	55,132

;
; Name:		PixelAddr04
;
; Function:	Determine buffer address of pixel in 320x200 4-color mode
;
; Caller:	AX = y-coordinate (0-199)
;		BX = x-coordinate (0-319)
;
; Returns:	AH = bit mask
;		BX = byte offset in buffer
;		CL = number of bits to shift left
;		ES = video buffer segment
;


OriginOffset	EQU	0		; byte offset of (0,0)
VideoBufferSeg	EQU	0B800h

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	PixelAddr04
PixelAddr04	PROC	near

		mov	cl,bl		; CL := low-order byte of x

		xchg	ah,al		; AX := 100h * y
		shr	ax,1		; AL := 80h * (y&1)
		add	bh,al	  	; BX := x + 8000h*(y&1)
		xor	al,al		; AX := 100h*(y/2)
		add	bx,ax	  	; BX := x + 8000h*(y&1) + 100h*(y/2)
		shr	ax,1
		shr	ax,1		; AX := 40h*(y/2)
		add	bx,ax	  	; BX := x + 8000h*(y&1) + 140h*(y/2)
		shr	bx,1
		shr	bx,1	   	; BX := x/4 + 2000h*(y&1) + 50h*(y/2)
		add	bx,OriginOffset	; BX := byte offset in video buffer

		mov	ax,VideoBufferSeg
		mov	es,ax		; ES:BX := byte address of pixel

		mov	ah,3		; AH := unshifted bit mask
		and	cl,ah		; CL := x & 3
		xor	cl,ah		; CL := 3 - (x & 3)
		shl	cl,1		; CL := # bits to shift left

		ret

PixelAddr04	ENDP

_TEXT		ENDS

		END
