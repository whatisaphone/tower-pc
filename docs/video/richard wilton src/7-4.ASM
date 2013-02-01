		TITLE	'Listing 7-4'
		NAME	Ellipse10
		PAGE	55,132

;
; Name:		Ellipse10
;
; Function:	Draw an ellipse in native EGA/VGA graphics modes.
;
; Caller:	Microsoft C:
;
;			void Ellipse10(xc,yc,a,b,n);
;
;			int xc,yc;		/* center of ellipse */
;
;			int a,b;		/* major and minor axes */
;
;			int n;			/* pixel value */
;

ARGxc		EQU	word ptr [bp+4]	; stack frame addressing
ARGyc		EQU	word ptr [bp+6]
ARGa		EQU	word ptr [bp+8]
ARGb		EQU	word ptr [bp+10]
ARGn		EQU	byte ptr [bp+12]

ULAddr		EQU	word ptr [bp-2]
URAddr		EQU	word ptr [bp-4]
LLAddr		EQU	word ptr [bp-6]
LRAddr		EQU	word ptr [bp-8]
LMask		EQU	byte ptr [bp-10]
RMask		EQU	byte ptr [bp-12]

VARd		EQU	word ptr [bp-16]
VARdx		EQU	word ptr [bp-20]
VARdy		EQU	word ptr [bp-24]
Asquared	EQU	word ptr [bp-28]
Bsquared	EQU	word ptr [bp-32]
TwoAsquared	EQU	word ptr [bp-36]
TwoBsquared	EQU	word ptr [bp-40]

RMWbits		EQU	0		; read-modify-write bits
BytesPerLine	EQU	80


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_Ellipse10
_Ellipse10	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,40		; establish stack frame
		push	si
		push	di

; set Graphics Controller Mode register

		mov	dx,3CEh		; DX := Graphics Controller I/O port
		mov	ax,0005h	; AL := Mode register number
					; AH := Write Mode 0 (bits 0,1)
		out	dx,ax		;	Read Mode 0 (bit 4)

; set Data Rotate/Function Select register

		mov	ah,RMWbits	; AH := Read-Modify-Write bits
		mov	al,3		; AL := Data Rotate/Function Select reg
		out	dx,ax

; set Set/Reset and Enable Set/Reset registers

		mov	ah,ARGn		; AH := pixel value
		mov	al,0		; AL := Set/Reset reg number
		out	dx,ax

		mov	ax,0F01h	; AH := value for Enable Set/Reset (all
					;  bit planes enabled)
		out	dx,ax		; AL := Enable Set/Reset reg number

; initial constants

		mov	ax,ARGa
		mul	ax
		mov	Asquared,ax
		mov	Asquared+2,dx	; a^2
		shl	ax,1
		rcl	dx,1
		mov	TwoAsquared,ax
		mov	TwoAsquared+2,dx ; 2*a^2

		mov	ax,ARGb
		mul	ax
		mov	Bsquared,ax
		mov	Bsquared+2,dx	; b^2
		shl	ax,1
		rcl	dx,1
		mov	TwoBsquared,ax
		mov	TwoBsquared+2,dx ; 2*b^2
;
; plot pixels from (0,b) until dy/dx = -1
;

; initial buffer address and bit mask

		mov	ax,BytesPerLine	; AX := video buffer line length
		mul	ARGb		; AX := relative byte offset of b
		mov	si,ax
		mov	di,ax

		mov	ax,ARGyc	; AX := yc
		mov	bx,ARGxc	; BX := xc
		call	PixelAddr10	; AH := bit mask
					; ES:BX -> buffer
					; CL := # bits to shift left
		mov	ah,1
		shl	ah,cl		; AH := bit mask for first pixel
		mov	LMask,ah
		mov	RMask,ah

		add	si,bx		; SI := offset of (0,b)
		mov	ULAddr,si
		mov	URAddr,si
		sub	bx,di		; AX := offset of (0,-b)
		mov	LLAddr,bx
		mov	LRAddr,bx

; initial decision variables

		xor	ax,ax
		mov	VARdx,ax
		mov	VARdx+2,ax	; dx = 0

		mov	ax,TwoAsquared
		mov	dx,TwoAsquared+2
		mov	cx,ARGb
		call	LongMultiply	; perform 32-bit by 16-bit mulitply
		mov	VARdy,ax
		mov	VARdy+2,dx	; dy = TwoAsquared * b

		mov	ax,Asquared
		mov	dx,Asquared+2	; DX:AX = Asquared
		sar	dx,1
		rcr	ax,1
		sar	dx,1
		rcr	ax,1		; DX:AX = Asquared/4

		add	ax,Bsquared
		adc	dx,Bsquared+2	; DX:AX = Bsquared + Asquared/4
		mov	VARd,ax
		mov	VARd+2,dx

		mov	ax,Asquared
		mov	dx,Asquared+2
		mov	cx,ARGb
		call	LongMultiply	; DX:AX = Asquared*b
		sub	VARd,ax
		sbb	VARd+2,dx	; d = Bsquared - Asquared*b + Asquared/4

; loop until dy/dx >= -1

		mov	bx,ARGb		; BX := initial y-coordinate

		xor	cx,cx		; CH := 0 (initial y-increment)
					; CL := 0 (initial x-increment)
L10:		mov	ax,VARdx
		mov	dx,VARdx+2
		sub	ax,VARdy
		sbb	dx,VARdy+2
		jns	L20		; jump if dx>=dy

		call	Set4Pixels

		mov	cx,1		; CH := 0 (y-increment)
					; CL := 1 (x-increment)
		cmp	VARd+2,0
		js	L11		; jump if d < 0

		mov	ch,1		; increment in y direction
		dec	bx		; decrement current y-coordinate

		mov	ax,VARdy
		mov	dx,VARdy+2
		sub	ax,TwoAsquared
		sbb	dx,TwoAsquared+2 ; DX:AX := dy - TwoAsquared
		mov	VARdy,ax
		mov	VARdy+2,dx	; dy -= TwoAsquared

		sub	VARd,ax
		sbb	VARd+2,dx	; d -= dy

L11:		mov	ax,VARdx
		mov	dx,VARdx+2
		add	ax,TwoBsquared
		adc	dx,TwoBsquared+2 ; DX:AX := dx + TwoBsquared
		mov	VARdx,ax
		mov	VARdx+2,dx	; dx += TwoBsquared

		add	ax,Bsquared
		adc	dx,Bsquared+2	; DX:AX := dx + Bsquared
		add	VARd,ax
		adc	VARd+2,dx	; d += dx + Bsquared

		jmp	L10
;
; plot pixels from current (x,y) until y < 0
;

; initial buffer address and bit mask

L20:		push	bx		; preserve current y-coordinate
		push	cx		; preserve x- and y-increments

		mov	ax,Asquared
		mov	dx,Asquared+2
		sub	ax,Bsquared
		sbb	dx,Bsquared+2	; DX:AX := Asquared-Bsquared

		mov	bx,ax
		mov	cx,dx		; CX:BX := (Asquared-Bsquared)

		sar	dx,1
		rcr	ax,1		; DX:AX := (Asquared-Bsquared)/2
		add	ax,bx
		adc	dx,cx		; DX:AX := 3*(Asquared-Bsquared)/2

		sub	ax,VARdx
		sbb	dx,VARdx+2
		sub	ax,VARdy
		sbb	dx,VARdy+2	; DX:AX := 3*(Asquared-Bsquared)/2 - (dx+dy)

		sar	dx,1
		rcr	ax,1		; DX:AX :=
					;  ( 3*(Asquared-Bsquared)/2 - (dx+dy) )/2
		add	VARd,ax
		adc	VARd+2,dx	; update d

; loop until y < 0

		pop	cx		; CH,CL := y- and x-increments
		pop	bx		; BX := y

L21:		call	Set4Pixels

		mov	cx,100h		; CH := 1 (y-increment)
					; CL := 0 (x-increment)

		cmp	VARd+2,0
		jns	L22		; jump if d >= 0

		mov	cl,1		; increment in x direction

		mov	ax,VARdx
		mov	dx,VARdx+2
		add	ax,TwoBsquared
		adc	dx,TwoBsquared+2 ; DX:AX := dx + TwoBsquared
		mov	VARdx,ax
		mov	VARdx+2,dx	; dx += TwoBsquared

		add	VARd,ax
		adc	VARd+2,dx	; d += dx

L22:		mov	ax,VARdy
		mov	dx,VARdy+2
		sub	ax,TwoAsquared
		sbb	dx,TwoAsquared+2 ; DX:AX := dy - TwoAsquared
		mov	VARdy,ax
		mov	VARdy+2,dx	; dy -= TwoAsquared

		sub	ax,Asquared
		sbb	dx,Asquared+2	; DX:AX := dy - Asquared
		sub	VARd,ax
		sbb	VARd+2,dx	; d += Asquared - dy

		dec	bx		; decrement y
		jns	L21		; loop if y >= 0


; restore default Graphics Controller registers

Lexit:		mov	ax,0FF08h	; default Bit Mask
		mov	dx,3CEh
		out	dx,ax

		mov	ax,0003		; default Function Select
		out	dx,ax

		mov	ax,0001		; default Enable Set/Reset
		out	dx,ax

		pop	di		; restore registers and return
		pop	si
		mov	sp,bp
		pop	bp
		ret

_Ellipse10	ENDP


Set4Pixels	PROC	near		; Call with:  CH := y-increment (0, -1)
					;	      CL := x-increment (0, 1)

		push	ax		; preserve these regs
		push	bx
		push	dx

		mov	dx,3CEh		; DX := Graphics Controller port

		xor	bx,bx		; BX := 0
		test	ch,ch
		jz	L30		; jump if y-increment = 0

		mov	bx,BytesPerLine	; BX := positive increment
		neg	bx		; BX := negative increment

L30:		mov	al,8		; AL := Bit Mask reg number

; pixels at (xc-x,yc+y) and (xc-x,yc-y)

		xor	si,si		; SI := 0
		mov	ah,LMask

		rol	ah,cl		; AH := bit mask rotated horizontally
		rcl	si,1		; SI := 1 if bit mask rotated around
		neg	si		; SI := 0 or -1

		mov	di,si		; SI,DI := left horizontal increment

		add	si,ULAddr	; SI := upper left addr + horiz incr
		add	si,bx		; SI := new upper left addr
		add	di,LLAddr
		sub	di,bx		; DI := new lower left addr

		mov	LMask,ah	; update these variables
		mov	ULAddr,si
		mov	LLAddr,di

		out	dx,ax		; update Bit Mask register

		mov	ch,es:[si]	; update upper left pixel
		mov	es:[si],ch
		mov	ch,es:[di]	; update lower left pixel
		mov	es:[di],ch


; pixels at (xc+x,yc+y) and (xc+x,yc-y)

		xor	si,si		; SI := 0
		mov	ah,RMask

		ror	ah,cl		; AH := bit mask rotated horizontally
		rcl	si,1		; SI := 1 if bit mask rotated around

		mov	di,si		; SI,DI := right horizontal increment

		add	si,URAddr	; SI := upper right addr + horiz incr
		add	si,bx		; SI := new upper right addr
		add	di,LRAddr
		sub	di,bx		; DI := new lower right addr

		mov	RMask,ah	; update these variables
		mov	URAddr,si
		mov	LRAddr,di

		out	dx,ax		; update Bit Mask register

		mov	ch,es:[si]	; update upper right pixel
		mov	es:[si],ch
		mov	ch,es:[di]	; update lower right pixel
		mov	es:[di],ch

		pop	dx		; restore these regs
		pop	bx
		pop	ax
		ret

Set4Pixels	ENDP


LongMultiply	PROC	near		; Caller:	DX = u1 (hi-order word
					;		 of 32-bit number)
					;		AX = u2 (lo-order word)
					;		CX = v1 (16-bit number)
					; Returns:	DX:AX = 32-bit result)

		push	ax		; preserve u2
		mov	ax,dx		; AX := 
		mul	cx		; AX := high-order word of result
		xchg	ax,cx		; AX := v1, CX := high-order word
		pop	dx		; DX := u2
		mul	dx		; AX := low-order word of result
					; DX := carry
		add	dx,cx		; CX := high-order word of result
		ret

LongMultiply	ENDP

_TEXT		ENDS

		END
