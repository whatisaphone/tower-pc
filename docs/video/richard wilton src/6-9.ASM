		TITLE	'Listing 6-9'
		NAME	Line13
		PAGE	55,132

;
; Name:		Line13
;
; Function:	Draw a line in MCGA/VGA 320x200 256-color mode
;
; Caller:	Microsoft C:
;
;			void Line13(x1,y1,x2,y2,n);
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
VARincr1	EQU	word ptr [bp-2]
VARincr2	EQU	word ptr [bp-4]
VARroutine	EQU	word ptr [bp-6]

BytesPerLine	EQU	320


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr13:near

		PUBLIC	_Line13
_Line13		PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,6		; stack space for local variables
		push	si
		push	di

; check for vertical line

		mov	si,BytesPerLine	; initial y-increment

		mov	cx,ARGx2
		sub	cx,ARGx1	; CX := x2 - x1
		jz	VertLine13	; jump if vertical line

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
		jz	HorizLine13	; jump if horizontal line

		jns	L03		; jump if slope is positive

		neg	bx		; BX := y1 - y2
		neg	si		; negate y-increment

; select appropriate routine for slope of line

L03:		push	si		; preserve y-increment

		mov	VARroutine,offset LoSlopeLine13
		cmp	bx,cx
		jle	L04		; jump if dy <= dx (slope <= 1)
		mov	VARroutine,offset HiSlopeLine13
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
		call	PixelAddr13	; ES:BX -> buffer

		mov	di,bx		; ES:DI -> buffer

		pop	cx		; restore this register
		inc	cx		; CX := # of pixels to draw

		pop	bx		; BX := y-increment
		jmp	VARroutine	; jump to appropriate routine for slope


; routine for vertical lines

VertLine13:	mov	ax,ARGy1	; AX := y1
		mov	bx,ARGy2	; BX := y2
		mov	cx,bx
		sub	cx,ax		; CX := dy
		jge	L31		; jump if dy >= 0

		neg	cx		; force dy >= 0
		mov	ax,bx		; AX := y2

L31:		inc	cx		; CX := # of pixels to draw
		mov	bx,ARGx1	; BX := x
		push	cx		; preserve this register
		call	PixelAddr13	; ES:BX -> video buffer
		pop	cx		; restore this register

		mov	di,bx		; ES:DI -> video buffer
		dec	si		; SI := bytes/line - 1

		mov	al,ARGn		; AL := pixel value

L32:		stosb			; set pixel value in buffer
		add	di,si		; increment to next line
		loop	L32

		jmp	Lexit



; routine for horizontal lines (slope = 0)

HorizLine13:
		push	cx		; preserve CX
		mov	ax,ARGy1
		mov	bx,ARGx1
		call	PixelAddr13	; ES:BX -> video buffer
		mov	di,bx		; ES:DI -> buffer

		pop	cx
		inc	cx		; CX := number of pixels to draw

		mov	al,ARGn		; AL := pixel value

		rep	stosb		; update the video buffer

		jmp	short Lexit


; routine for dy <= dx (slope <= 1)	; ES:DI -> video buffer
					; BX = y-increment
					; CX = # pixels to draw
					; SI = decision variable
LoSlopeLine13:

		mov	al,ARGn		; AL := pixel value

L11:		stosb			; store pixel, increment x

		or	si,si		; test sign of d
		jns	L12		; jump if d >= 0

		add	si,VARincr1	; d := d + incr1
		loop	L11
		jmp	short Lexit

L12:		add	si,VARincr2	; d := d + incr2
		add	di,bx		; increment y
		loop	L11
		jmp	short Lexit


; routine for dy > dx (slope > 1)	; ES:DI -> video buffer
					; BX = y-increment
					; CX = # pixels to draw
					; SI = decision variable
HiSlopeLine13:
		mov	al,ARGn		; AL := pixel value

L21:		stosb			; update next pixel, increment x

		add	di,bx		; increment y

L22:		or	si,si		; test sign of d
		jns	L23		; jump if d >= 0

		add	si,VARincr1	; d := d + incr1
		dec	di		; decrement x (already incremented
					;  by stosb)
		loop	L21
		jmp	short Lexit


L23:		add	si,VARincr2	; d := d + incr2
		loop	L21


Lexit:		pop	di		; restore registers and return
		pop	si
		mov	sp,bp
		pop	bp
		ret

_Line13		ENDP

_TEXT		ENDS

		END
