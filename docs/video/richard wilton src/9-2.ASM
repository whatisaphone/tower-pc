		TITLE	'Listing 9-3'
		NAME	DisplayChar06
		PAGE	55,132

;
; Name:		DisplayChar06
;
; Function:	Display a character in 640x200 2-color mode
;
; Caller:	Microsoft C:
;
;			void DisplayChar06(c,x,y,fgd,bkgd);
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
ARGfgd		EQU	byte ptr [bp+10]
ARGbkgd		EQU	byte ptr [bp+12]

VARmask		EQU	[bp-2]
VARtoggle	EQU	[bp-4]


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr06:near

		PUBLIC	_DisplayChar06
_DisplayChar06	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,4		; stack space for local variables
		push	si
		push	di
		push	ds

; set up foreground pixel toggle mask

		mov	ah,ARGfgd	; AH := 0 or 1 (foreground pixel value)
		ror	ah,1		; high-order bit of AH := 0 or 1
		cwd			; propagate high-order bit through DX
		not	dx		; DX :=     0 if foreground = 1
					;    or FFFFh if foreground = 0
		mov	VARtoggle,dx

; calculate first pixel address

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr06	; ES:BX -> buffer
					; CL := # bits to shift left

		xor	cl,7		; CL := # bits to rotate right

		mov	ax,0FF00h
		ror	ax,cl		; AX := bit mask in proper position
		mov	VARmask,ax

; set up video buffer addressing

		mov	dx,2000h	; increment for video buffer interleave
		mov	di,80-2000h	; increment from last to first interleave

		test	bx,2000h	; set zero flag if BX in 1st interleave
		jz	L01

		xchg	di,dx		; exchange increment values if 1st pixel
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

		test	cl,cl		; test # bits to rotate
		jnz	L20		; jump if character is not byte-aligned


; routine for byte-aligned characters

		mov	ah,VARtoggle	; AH := foreground toggle mask
		xchg	ch,cl		; CX := POINTS
		
L10:		lodsb			; AL := bit pattern for next pixel row
		xor	al,ah		; toggle pixels if foreground = 0
		mov	es:[bx],al	; store pixels in buffer

		add	bx,dx		; BX := next row in buffer
		xchg	di,dx		; swap buffer increments
		loop	L10
		jmp	short Lexit


; routine for non-byte-aligned characters

L20:		mov	ax,VARmask
		and	es:[bx],ax	; mask character pixels in buffer

		xor	ah,ah
		lodsb			; AX := bit pattern for next pixel row
		xor	al,VARtoggle	; toggle pixels if foreground = 0

		ror	ax,cl		; rotate pixels into position
		or	es:[bx],ax	; store pixels in buffer

		add	bx,dx		; BX := next row in buffer
		xchg	di,dx		; swap buffer increments
		dec	ch
		jnz	L20


Lexit:		pop	ds		; restore registers and return
		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_DisplayChar06	ENDP

_TEXT		ENDS

		END
