		TITLE	'Listing 4-2'
		NAME	PixelAddr06
		PAGE	55,132

;
; Name:		PixelAddr06
;
; Function:	Determine buffer address of pixel in 640x200 2-color mode
;
; Caller:	AX = y-coordinate (0-199)
;		BX = x-coordinate (0-639)
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

		PUBLIC	PixelAddr06
PixelAddr06	PROC	near

		mov	cl,bl		; CL := low-order byte of x

		xchg	ah,al		; AX := 100h * y
		shr	bx,1		; BX := x/2
		shr	ax,1		; AL := 80h*(y&1)
		add	bh,al	  	; BX := x/2 + 8000h*(y&1)
		xor	al,al		; AX := 100h*(y/2)
		add	bx,ax	  	; BX := x/2 + 8000h*(y&1) + 100h*(y/2)
		shr	ax,1
		shr	ax,1		; AX := 40h*(y/2)
		add	bx,ax	  	; BX := x/2 + 8000h*(y&1) + 140h*(y/2)
		shr	bx,1
		shr	bx,1	   	; BX := x/8 + 2000h*(y&1) + 50h*(y/2)
		add	bx,OriginOffset	; BX := byte offset in video buffer

		mov	ax,VideoBufferSeg
		mov	es,ax		; ES:BX := byte address of pixel

		and	cl,7		; CL := x & 7
		xor	cl,7		; CL := number of bits to shift left
		mov	ah,1		; AH := unshifted bit mask

		ret

PixelAddr06	ENDP

_TEXT		ENDS

		END
