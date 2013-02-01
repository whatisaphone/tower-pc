		TITLE	'Listing 9-3'
		NAME	DisplayChar04
		PAGE	55,132

;
; Name:		DisplayChar04
;
; Function:	Display a character in 320x200 4-color graphics mode
;
; Caller:	Microsoft C:
;
;			void DisplayChar04(c,x,y,fgd,bkgd);
;
;			int c;			/* character code */
;
;			int x,y;		/* upper left pixel */
;
;			int fgd,bkgd;		/* foreground and background
;						    pixel values */
;

ARGc		EQU	word ptr [bp+4]	; stack frame addressing
ARGx		EQU	word ptr [bp+6]
ARGy		EQU	word ptr [bp+8]
ARGfgd		EQU	         [bp+10]
ARGbkgd		EQU	         [bp+12]

VARshift	EQU	word ptr [bp-2]
VARincr		EQU	word ptr [bp-4]


DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		EXTRN	PixelAddr04:near

		PUBLIC	_DisplayChar04
_DisplayChar04	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,4		; stack space for local variables
		push	si
		push	di
		push	ds

; propagate pixel values

		mov	bx,offset DGROUP:PropagatedPixel
		mov	al,ARGfgd
		xlat			; propagate foreground pixel value
		mov	ah,al
		mov	ARGfgd,ax

		mov	al,ARGbkgd
		xlat			; propagate background pixel value
		mov	ah,al
		mov	ARGbkgd,ax 

; calculate first pixel address

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr04	; ES:BX -> buffer
					; CL := # bits to shift left
					;  to mask pixel
		mov	ch,0FCh
		shl	ch,cl		; CH := bit mask for right side of char

		xor	cl,6		; CL := 6 - CL (# bits to rotate char
					;  into position)
		mov	VARshift,cx

; set up video buffer addressing

		mov	di,2000h	; increment for video buffer interleave
		mov	VARincr,80-2000h ; increment from last to first interleave

		test	bx,2000h	; set zero flag if BX in 1st interleave
		jz	L01

		xchg	VARincr,di	; exchange increment values if 1st pixel
					;  lies in 1st interleave

; set up character definition table addressing

L01:		push	bx		; preserve buffer address

		mov	ax,40h
		mov	ds,ax		; DS := segment of BIOS Video
					;  Display Data area
		mov	ch,ds:[85h]	; CH := POINTS (pixel rows in character)

		xor	ax,ax
		mov	ds,ax		; DS := absolute zero

		mov	ax,ARGc		; AL := character code
		cmp	al,80h
		jae	L02

		mov	bx,43h*4	; DS:BX -> int 43h vector if char < 80h
		jmp	short L03

L02:		mov	bx,1Fh*4	; DS:BX -> int 1Fh vector if char >= 80h
		sub	al,80h		; put character code in range of table 

L03:		lds	si,ds:[bx]	; DS:SI -> start of character table
		mul	ch		; AX := offset into char def table
					;  (POINTS * char code)
		add	si,ax		; SI := addr of char def

		pop	bx		; restore buffer address

		xchg	ch,cl		; CH := # bits to rotate
					; CL := POINTS
		
		test	ch,ch		; test # bits to rotate
		jnz	L20		; jump if character is not byte-aligned


; routine for byte-aligned characters

L10:		lodsb			; AL := bit pattern for next pixel row
		xor	dx,dx		; DX := initial value for doubled bits
		mov	ah,8		; AH := # of bits in pattern

L11:		shr	al,1		; cf := lo-order bit of AL
		rcr	dx,1		; hi-order bit of CX := cf
		sar	dx,1		; double hi-order bit of DX
		dec	ah		; loop 8 times
		jnz	L11

		mov	ax,dx		; AX,DX := doubled bit pattern
		and	ax,ARGfgd	; AX := foreground pixels
		not	dx
		and	dx,ARGbkgd	; DX := background pixels

		or	ax,dx		; AX := eight pixels
		xchg	ah,al		; put bytes in proper order
		mov	es:[bx],ax	; update video buffer

		add	bx,di		; BX := next row in buffer
		xchg	di,VARincr	; swap buffer increments

		loop	L10
		jmp	short Lexit


; routine for non-byte-aligned characters

L20:		xor	ch,ch		; CX := POINTS

L21:		push	cx		; preserve CX

		mov	cx,VARshift	; CH := mask for right side of char
					; CL := # bits to rotate

		lodsb			; AL := bit pattern for next pixel row
		xor	dx,dx		; DX := initial value for doubled bits
		mov	ah,8		; AH := # of bits in pattern

L22:		shr	al,1		; DX := double bits in AL
		rcr	dx,1		;  (same as above)
		sar	dx,1
		dec	ah
		jnz	L22

		xchg	dh,dl		; DH := bits for right half of char
					; DL := bits for left half of char
		mov	ax,dx
		and	ax,ARGfgd	; AX := foreground pixels
		not	dx
		and	dx,ARGbkgd	; DX := background pixels

		or	dx,ax		; DX := eight pixels
		ror	dx,cl		; DH := left and right side pixels
					; DL := middle pixels
		mov	al,ch
		xor	ah,ah		; AX := mask for left and middle
					;  bytes of char
		and	es:[bx],ax	; zero pixels in video buffer

		not	ax
		and	ax,dx
		or	es:[bx],ax	; update pixels in left and middle bytes

		mov	al,ch		; AL := mask for right-hand byte
		not	al
		and	es:[bx+2],al	; mask pixels in right-hand byte in buffer
		and	ch,dl
		or	es:[bx+2],ch	; update pixels in right-hand byte

		add	bx,di		; BX := next row in buffer
		xchg	di,VARincr	; swap buffer increments

		pop	cx		; restore CX
		loop	L21


Lexit:		pop	ds		; restore registers and return
		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_DisplayChar04	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

PropagatedPixel	DB	00000000b	; 0
		DB	01010101b	; 1
		DB	10101010b	; 2
		DB	11111111b	; 3

_DATA		ENDS

		END
