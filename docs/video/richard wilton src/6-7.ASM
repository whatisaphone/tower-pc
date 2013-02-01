		TITLE	'Listing 6-7'
		NAME	Line10
		PAGE	55,132

;
; Name:		Line10
;
; Function:	Draw a line in the following EGA and VGA graphics modes:
;			200-line 16-color modes
;			350-line modes
;			640x480 16-color
;
; Caller:	Microsoft C:
;
;			void Line10(x1,y1,x2,y2,n);
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
VARvertincr	EQU	word ptr [bp-2]
VARincr1	EQU	word ptr [bp-4]
VARincr2	EQU	word ptr [bp-6]
VARroutine	EQU	word ptr [bp-8]

ByteOffsetShift	EQU	3		; used to convert pixels to byte offset
BytesPerLine	EQU	80
RMWbits		EQU	0		; value for Data Rotate/Func Select reg


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_Line10
_Line10		PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,8		; stack space for local variables
		push	si
		push	di

; configure the Graphics Controller

		mov	dx,3CEh		; DX := Graphics Controller port addr

		mov	ah,ARGn		; AH := pixel value
		xor	al,al		; AL := Set/Reset Register number
		out	dx,ax

		mov	ax,0F01h	; AH := 1111b (bit plane mask for
					;  Enable Set/Reset
		out	dx,ax		; AL := Enable Set/Reset Register #

		mov	ah,RMWbits	; bits 3 and 4 of AH := function
		mov	al,3		; AL := Data Rotate/Func Select reg #
		out	dx,ax
		
; check for vertical line

		mov	si,BytesPerLine	; increment for video buffer

		mov	cx,ARGx2
		sub	cx,ARGx1	; CX := x2 - x1
		jz	VertLine10	; jump if vertical line

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
		jz	HorizLine10	; jump if horizontal line

		jns	L03		; jump if slope is positive

		neg	bx		; BX := y1 - y2
		neg	si		; negate increment for buffer interleave

; select appropriate routine for slope of line

L03:		mov	VARvertincr,si	; save vertical increment

		mov	VARroutine,offset LoSlopeLine10
		cmp	bx,cx
		jle	L04		; jump if dy <= dx (slope <= 1)
		mov	VARroutine,offset HiSlopeLine10
		xchg	bx,cx		; exchange dy and dx

; calculate initial decision variable and increments

L04:		shl	bx,1		; BX := 2 * dy
		mov	VARincr1,bx	; incr1 := 2 * dy
		sub	bx,cx
		mov	si,bx		; SI := d = 2 * dy - dx
		sub	bx,cx
		mov	VARincr2,bx	; incr2 := 2 * (dy - dx)

; calculate first pixel address

		push	cx		; preserve this register
		mov	ax,ARGy1	; AX := y
		mov	bx,ARGx1	; BX := x
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> buffer
					; CL := # bits to shift left

		mov	di,bx		; ES:DI -> buffer
		shl	ah,cl		; AH := bit mask in proper position
		mov	bl,ah		; AH,BL := bit mask
		mov	al,8		; AL := Bit Mask Register number

		pop	cx		; restore this register
		inc	cx		; CX := # of pixels to draw

		jmp	VARroutine	; jump to appropriate routine for slope


; routine for vertical lines

VertLine10:	mov	ax,ARGy1	; AX := y1
		mov	bx,ARGy2	; BX := y2
		mov	cx,bx
		sub	cx,ax		; CX := dy
		jge	L31		; jump if dy >= 0

		neg	cx		; force dy >= 0
		mov	ax,bx		; AX := y2

L31:		inc	cx		; CX := # of pixels to draw
		mov	bx,ARGx1	; BX := x
		push	cx		; preserve this register
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> video buffer
					; CL := # bits to shift left
; set up Graphics Controller

		shl	ah,cl		; AH := bit mask in proper position
		mov	al,8		; AL := Bit Mask reg number
		out	dx,ax

		pop	cx		; restore this register

; draw the line

L32:		or	es:[bx],al	; set pixel
		add	bx,si		; increment to next line
		loop	L32

		jmp	Lexit



; routine for horizontal lines (slope = 0)

HorizLine10:
		push	ds		; preserve DS

		mov	ax,ARGy1
		mov	bx,ARGx1
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> video buffer
					; CL := # bits to shift left
		mov	di,bx		; ES:DI -> buffer

		mov	dh,ah		; DH := unshifted bit mask for leftmost
					;        byte
		not	dh
		shl	dh,cl		; DH := reverse bit mask for first byte
		not	dh		; DH := bit mask for first byte

		mov	cx,ARGx2
		and	cl,7
		xor	cl,7		; CL := number of bits to shift left
		mov	dl,0FFh		; DL := unshifted bit mask for
					;	 rightmost byte
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

; get Graphics Controller port address into DX

		mov	bx,dx		; BH := bit mask for first byte
					; BL := bit mask for last byte
		mov	dx,3CEh		; DX := Graphics Controller port
		mov	al,8		; AL := Bit Mask Register number

; make video buffer addressible through DS:SI

		push	es
		pop	ds
		mov	si,di		; DS:SI -> video buffer

; set pixels in leftmost byte of the line

		or	bh,bh
		js	L43		; jump if byte-aligned (x1 is leftmost
					;  pixel in byte)
		or	cx,cx
		jnz	L42		; jump if more than one byte in the line

		and	bl,bh		; BL := bit mask for the line
		jmp	short L44

L42:		mov	ah,bh		; AH := bit mask for 1st byte
		out	dx,ax		; update Graphics Controller

		movsb			; update bit planes
		dec	cx

; use a fast 8086 machine instruction to draw the remainder of the line

L43:		mov	ah,11111111b	; AH := bit mask
		out	dx,ax		; update Bit Mask Register

		rep	movsb		; update all pixels in the line

; set pixels in the rightmost byte of the line

L44:		mov	ah,bl		; AH := bit mask for last byte
		out	dx,ax		; update Graphics Controller

		movsb			; update bit planes

		pop	ds		; restore DS
		jmp	short Lexit


; routine for dy <= dx (slope <= 1)	; ES:DI -> video buffer
					; AL = Bit Mask Register number
					; BL = bit mask for 1st pixel
					; CX = # pixels to draw
					; DX = Graphics Controller port addr
					; SI = decision variable
LoSlopeLine10:

L10: 		mov	ah,bl		; AH := bit mask for next pixel

L11:		or	ah,bl		; mask current pixel position
		ror	bl,1		; rotate pixel value
		jc	L14		; jump if bit mask rotated to
					;  leftmost pixel position

; bit mask not shifted out

		or	si,si		; test sign of d
		jns	L12		; jump if d >= 0

		add	si,VARincr1	; d := d + incr1
		loop	L11

		out	dx,ax		; update Bit Mask Register
		or	es:[di],al	; set remaining pixel(s)
		jmp	short Lexit

L12:		add	si,VARincr2	; d := d + incr2
		out	dx,ax		; update Bit Mask Register

		or	es:[di],al	; update bit planes

		add	di,VARvertincr	; increment y
		loop	L10
		jmp	short Lexit

; bit mask shifted out

L14:		out	dx,ax		; update Bit Mask Register ...

		or	es:[di],al	; update bit planes
		inc	di		; increment x

		or	si,si		; test sign of d
		jns	L15		; jump if non-negative

		add	si,VARincr1	; d := d + incr1
		loop	L10 
		jmp	short Lexit

L15:		add	si,VARincr2	; d := d + incr2
		add	di,VARvertincr	; vertical increment
		loop	L10
		jmp	short Lexit


; routine for dy > dx (slope > 1)	; ES:DI -> video buffer
					; AH = bit mask for 1st pixel
					; AL = Bit Mask Register number
					; CX = # pixels to draw
					; DX = Graphics Controller port addr
					; SI = decision variable
HiSlopeLine10:
		mov	bx,VARvertincr	; BX := y-increment

L21:		out	dx,ax		; update Bit Mask Register
		or	es:[di],al	; update bit planes

		add	di,bx		; increment y

L22:		or	si,si		; test sign of d
		jns	L23		; jump if d >= 0

		add	si,VARincr1	; d := d + incr1
		loop	L21
		jmp	short Lexit


L23:		add	si,VARincr2	; d := d + incr2

		ror	ah,1		; rotate bit mask
		adc	di,0		; increment DI if when mask rotated to
					;  leftmost pixel position

		loop	L21


; restore default Graphics Controller state and return to caller

Lexit:		xor	ax,ax		; AH := 0, AL := 0
		out	dx,ax		; restore Set/Reset Register

		inc	ax		; AH := 0, AL := 1
		out	dx,ax		; restore Enable Set/Reset Register

		mov	al,3		; AH := 0, AL := 3
		out	dx,ax		; AL := Data Rotate/Func Select reg #

		mov	ax,0FF08h	; AH := 11111111b, AL := 8
		out	dx,ax		; restore Bit Mask Register

		pop	di		; restore registers and return
		pop	si
		mov	sp,bp
		pop	bp
		ret

_Line10		ENDP

_TEXT		ENDS

		END
