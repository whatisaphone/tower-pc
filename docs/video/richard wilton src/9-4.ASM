		TITLE	'Listing 9-4'
		NAME	DisplayCharHGC
		PAGE	55,132

;
; Name:		DisplayCharHGC
;
; Function:	Display a character in Hercules 720x348 monochrome graphics mode
;
; Caller:	Microsoft C:
;
;			void DisplayCharHGC(c,x,y,fgd,bkgd);
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

VARmask		EQU	         [bp-2]
VARtoggle	EQU	         [bp-4]
VAR9bits	EQU	byte ptr [bp-6]


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddrHGC:near

		PUBLIC	_DisplayCharHGC
_DisplayCharHGC	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,6		; stack space for local variables
		push	si
		push	di
		push	ds

; calculate first pixel address

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddrHGC	; ES:BX -> buffer
					; CL := # bits to shift left

		xor	cl,7		; CL := # bits to rotate right

; set up 8- or 9-bit mask

		mov	ax,40h
		mov	ds,ax		; DS := segment of BIOS Video
					;  Display Data area

		mov	ax,0FF00h	; AX := 8-bit mask
		mov	VAR9bits,0	; zero this flag

		cmp	byte ptr ds:[4Ah],90	; does CRT_COLS = 90?
		je	L01		; jump if characters are 8 pixels wide

		mov	ah,7Fh		; AX := 9-bit mask
		cmp	ARGc,0C0h
		jb	L01		; jump if character code ...

		cmp	ARGc,0DFh
		ja	L01		; ... outside of range 0C0-0DFh

		inc	VAR9bits	; set flag to extend to 9 bits

L01:		ror	ax,cl		; AX := bit mask in proper position
		mov	VARmask,ax

; set up foreground pixel toggle mask

		mov	ah,ARGfgd	; AH := 0 or 1 (foreground pixel value)
		ror	ah,1		; high-order bit of AH := 0 or 1
		cwd			; propagate high-order bit through DX
		not	dx		; DX :=     0 if foreground = 1
					;    or FFFFh if foreground = 0
		mov	ax,VARmask
		not	ax
		and	dx,ax		; zero unused bits of toggle mask in DX
		mov	VARtoggle,dx

; set up character definition table addressing

		push	bx		; preserve buffer address

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

; mask and set pixels in the video buffer

L20:		mov	ax,VARmask
		and	es:[bx],ax	; mask character pixels in buffer

		xor	ah,ah
		lodsb			; AX := bit pattern for next pixel row
		cmp	VAR9bits,0
		je	L21		; jump if character is 8 pixels wide

		ror	ax,1		; copy lo-order bit of AX into ...
		rcl	al,1		;  hi-order bit

L21:		ror	ax,cl		; rotate pixels into position
		xor	ax,VARtoggle	; toggle pixels if foreground = 0
		or	es:[bx],ax	; store pixels in buffer

		add	bx,2000h	; increment to next portion of interleave
		jns	L22

		add	bx,90-8000h	; increment to first portion of interleave

L22:		dec	ch
		jnz	L20


Lexit:		pop	ds		; restore registers and return
		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_DisplayCharHGC	ENDP

_TEXT		ENDS

		END
