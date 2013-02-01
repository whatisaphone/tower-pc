		TITLE	'Listing 6-10'
		NAME	LineInC
		PAGE	55,132

;
; Name:		LineInC
;
; Function:	Draw a line in Hercules InColor 720x348 16-color mode
;
; Caller:	Microsoft C:
;
;			void LineInC(x1,y1,x2,y2,n);
;
;			int x1,y1,x2,y2;	/* pixel coordinates */
;
;			int n;			/* pixel value */
;

ARGx1		EQU	word ptr [bp+4]	; stack frame addressing
ARGy1		EQU	word ptr [bp+6]
ARGx2		EQU	word ptr [bp+8]
ARGy2		EQU	word ptr [bp+10]
ARGn		EQU	byte ptr [bp+12]
VARleafincr	EQU	word ptr [bp-2]
VARincr1	EQU	word ptr [bp-4]
VARincr2	EQU	word ptr [bp-6]
VARroutine	EQU	word ptr [bp-8]

ByteOffsetShift	EQU	3		; used to convert pixels to byte offset
DefaultRWColor	EQU	0Fh		; default value for R/W Color register


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddrHGC:near

		PUBLIC	_LineInC
_LineInC	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,8		; stack space for local variables
		push	si
		push	di

		mov	si,2000h	; increment for video buffer interleave
		mov	di,90-8000h	; increment from last to first interleave

; set up InColor CRTC registers

		mov	dx,3B4h		; DX := CRTC I/O port
		mov	ax,5F19h	; AH bit 6 := 1 (Mask Polarity)
					; AH bits 5-4 := 1 (Write Mode)
					; AH bits 3-0 := "don't care" bits
					; AL := R/W Control Register number
		out	dx,ax		; set R/W Control Register

		inc	ax		; AL := 1Ah (R/W Color Reg number)
		mov	ah,ARGn		; AH := foreground value
		out	dx,ax		; set R/W color register


		mov	cx,ARGx2
		sub	cx,ARGx1	; CX := x2 - x1
		jz	VertLineInC	; jump if vertical line

; force x1 < x2

		jns	L01		; jump if x2 > x1

		neg	cx		; CX := x1 - x2
		
		mov	bx,ARGx2	; exchange x1 and x2
		xchg	bx,ARGx1
		mov	ARGx2,bx

		mov	bx,ARGy2	; exchange y1 and y2
		xchg	bx,ARGy1
		mov	ARGy2,bx

; calculate dy = ABS(y2-y1)

L01:		mov	bx,ARGy2
		sub	bx,ARGy1	; BX := y2 - y1
		jz	HorizLineInC	; jump if horizontal line

		jns	L03

		neg	bx		; BX := y1 - y2
		neg	si		; negate increments for buffer interleave
		neg	di

; select appropriate routine for slope of line

L03:		mov	VARleafincr,di	; save increment for buffer interleave

		mov	VARroutine,offset LoSlopeLineInC
		cmp	bx,cx
		jle	L04		; jump if dy <= dx (slope <= 1)
		mov	VARroutine,offset HiSlopeLineInC
		xchg	bx,cx		; exchange dy and dx

; calculate initial decision variable and increments

L04:		shl	bx,1		; BX := 2 * dy
		mov	VARincr1,bx	; incr1 := 2 * dy
		sub	bx,cx
		mov	di,bx		; DI := d = 2 * dy - dx
		sub	bx,cx
		mov	VARincr2,bx	; incr2 := 2 * (dy - dx)

; calculate first pixel address

		push	cx		; preserve this register
		mov	ax,ARGy1	; AX := y
		mov	bx,ARGx1	; BX := x
		call	PixelAddrHGC	; AH := bit mask
					; ES:BX -> buffer
					; CL := # bits to shift left

		shl	ah,cl
		mov	dh,ah		; DH := bit mask in proper position

		pop	cx		; restore this register
		inc	cx		; CX := # of pixels to draw

		jmp	VARroutine	; jump to appropriate routine for slope


; routine for vertical lines

VertLineInC:	mov	ax,ARGy1	; AX := y1
		mov	bx,ARGy2	; BX := y2
		mov	cx,bx
		sub	cx,ax		; CX := dy
		jge	L31		; jump if dy >= 0

		neg	cx		; force dy >= 0
		mov	ax,bx		; AX := y2

L31:		inc	cx		; CX := # of pixels to draw
		mov	bx,ARGx1	; BX := x
		push	cx		; preserve this register
		call	PixelAddrHGC	; AH := bit mask
					; ES:BX -> video buffer
					; CL := # bits to shift left
		shl	ah,cl		; AH := bit mask in proper position
		pop	cx		; restore this register

L32:		or	es:[bx],ah	; update pixel in buffer

		add	bx,si		; increment to next portion of interleave
		jns	L33

		add	bx,di		; increment to first portion of interleave

L33:		loop	L32

		jmp	Lexit



; routine for horizontal lines (slope = 0)

HorizLineInC:	mov	ax,ARGy1
		mov	bx,ARGx1
		call	PixelAddrHGC	; AH := bit mask
					; ES:BX -> video buffer
					; CL := # bits to shift left
		mov	di,bx		; ES:DI -> buffer

		mov	dh,ah
		not	dh		; DH := unshifted bit mask for leftmost
					;        byte
		mov	dl,0FFh		; DL := unshifted bit mask for
					;	 rightmost byte

		shl	dh,cl		; DH := reverse bit mask for first byte
		not	dh		; DH := bit mask for first byte

		mov	cx,ARGx2
		and	cl,7
		xor	cl,7		; CL := number of bits to shift left
		shl	dl,cl		; DL := bit mask for last byte

; determine byte offset of first and last pixel in the line

		mov	ax,ARGx2	; AX := x2
		mov	bx,ARGx1	; BX := x1

		mov	cl,ByteOffsetShift	; number of bits to shift to
						;  convert pixels to bytes

		shr	ax,cl		; AX := byte offset of x2
		shr	bx,cl		; BX := byte offset of x1
		mov	cx,ax
		sub	cx,bx		; CX := (# bytes in line) - 1

; set pixels in leftmost byte of the line

		or	dh,dh
		js	L43		; jump if byte-aligned (x1 is leftmost
					;  pixel in byte)
		or	cx,cx
		jnz	L42		; jump if more than one byte in the line

		and	dl,dh		; bit mask for the line
		jmp	short L44

L42:		or	es:[di],dh	; update masked pixels in buffer
		inc	di
		dec	cx

; use a fast 8086 machine instruction to draw the remainder of the line

L43:		mov	al,0FFh		; 8-pixel bit mask
		rep	stosb		; update all pixels in the line

; set pixels in the rightmost byte of the line

L44:		or	es:[di],dl	; update masked pixels in buffer
		jmp	Lexit


; routine for dy <= dx (slope <= 1)	; ES:BX -> video buffer
					; CX = # pixels to draw
					; DH = bit mask
					; SI = buffer interleave increment
					; DI = decision variable
LoSlopeLineInC:	

L10:		mov	ah,es:[bx]	; latch bit planes
					; AH := 0 because all planes
					;  are "don't care"

L11:		or	ah,dh		; set pixel value in byte

		ror	dh,1		; rotate bit mask
		jc	L14		; jump if bit mask rotated to
					;  leftmost pixel position

; bit mask not shifted out

		or	di,di		; test sign of d
		jns	L12		; jump if d >= 0

		add	di,VARincr1	; d := d + incr1
		loop	L11

		mov	es:[bx],ah	; store remaining pixels in buffer
		jmp	short Lexit

L12:		add	di,VARincr2	; d := d + incr2
		mov	es:[bx],ah	; update buffer
		
		add	bx,si		; increment y
		jns	L13		; jump if not in last interleave

		add	bx,VARleafincr	; increment into next interleave

L13:		loop	L10
		jmp	short Lexit

; bit mask shifted out

L14:		mov	es:[bx],ah	; update buffer
		inc	bx		; BX := offset of next byte

		or	di,di		; test sign of d
		jns	L15		; jump if non-negative

		add	di,VARincr1	; d := d + incr1
		loop	L10
		jmp	short Lexit

L15:		add	di,VARincr2	; d := d + incr2

		add	bx,si		; increment y
		jns	L16		; jump if not in last interleave

		add	bx,VARleafincr	; increment into next interleave

L16:		loop	L10		; loop until all pixels are set
		jmp	short Lexit


; routine for dy > dx (slope > 1)	; ES:BX -> video buffer
					; CX = # pixels to draw
					; DH = bit mask
					; SI = buffer interleave increment
					; DI = decision variable
HiSlopeLineInC:

L21:		or	es:[bx],dh	; set pixel value in video buffer

		add	bx,si		; increment y
		jns	L22		; jump if not in last interleave

		add	bx,VARleafincr	; increment into next interleave

L22:		or	di,di
		jns	L23		; jump if d >= 0

		add	di,VARincr1	; d := d + incr1
		loop	L21
		jmp	short Lexit


L23:		add	di,VARincr2	; d := d + incr2

		ror	dh,1		; rotate bit mask
		adc	bx,0		; BX := offset of next byte (incremented
					;  if bit mask rotated to
					;  leftmost pixel position

		loop	L21


Lexit:		mov	dx,3B4h		; DX := CRTC I/O port
		mov	ax,0F18h
		out	dx,ax		; restore default Plane Mask value

		mov	ax,4019h	; restore default R/W Control value
		out	dx,ax

		inc	ax		; restore default R/W Color value
		mov	ah,DefaultRWColor
		out	dx,ax

		pop	di		; restore registers and return
		pop	si
		mov	sp,bp
		pop	bp
		ret

_LineInC	ENDP

_TEXT		ENDS

		END
