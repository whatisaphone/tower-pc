		TITLE	'Listing 9-7'
		NAME	DisplayCharInC
		PAGE	55,132

;
; Name:		DisplayCharInC
;
; Function:	Display a character in InColor 720x348 16-color mode
;
; Caller:	Microsoft C:
;
;			void DisplayCharInC(c,x,y,fgd,bkgd);
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

VARmask		EQU	word ptr [bp-2]
VAR9bits	EQU	byte ptr [bp-4]

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddrHGC:near

		PUBLIC	_DisplayCharInC
_DisplayCharInC	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,4		; stack space for local variables
		push	si
		push	di
		push	ds

; calculate first pixel address

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddrHGC	; ES:BX -> buffer
					; CL := # bits to shift left to mask
					;  pixel
		xor	cl,7		; CL := # bits to rotate right

		push	es		; preserve video buffer segment
		mov	si,bx		; DI := video buffer offset

; set up flag for 8- or 9-bit characters

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

; set up character definition table addressing

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

L03:		les	di,ds:[bx]	; ES:DI -> start of character table
		mul	ch		; AX := offset into char def table
					;  (POINTS * char code)
		add	di,ax		; DI := addr of char def

		pop	ds		; DS:SI -> video buffer

; set up control registers

		mov	dx,3B4h		; control register I/O port

		push	cx		; preserve CX
		mov	ah,ARGbkgd	; AH := background pixel value
		mov	cl,4
		shl	ah,cl		; AH bits 4-7 := background pixel value
		or	ah,ARGfgd	; AH bits 0-3 := foreground pixel value
		pop	cx		; restore CX

		mov	al,1Ah		; AL := Read/Write Color reg number
		out	dx,ax		; set Read/Write Color value

; mask and set pixels in the video buffer

L20:		xor	bh,bh
		mov	bl,es:[di]	; BX := bit pattern for next pixel row
		inc	di		; increment pointer to char def table
		cmp	VAR9bits,0

		je	L21		; jump if character is 8 pixels wide

		ror	bx,1		; copy lo-order bit of BX into ...
		rcl	bl,1		;  hi-order bit

L21:		ror	bx,cl		; rotate pixels into position

		mov	ax,5F19h	; AH bit 6 := 1 (mask polarity)
					; AH bits 4-5 := 01b (write mode 1)
					; AH bits 0-3 := 1111b (don't care bits)
					; AL := 19h (Read/Write Control reg)
		out	dx,ax		; set up Read/Write control reg

		or	[si],bl		; update foreground pixels
		or	[si+1],bh

		mov	ah,6Fh		; set up write mode 2
		out	dx,ax

		or	bx,VARmask	; BX := background pixel bit pattern
		or	[si],bl		; update background pixels
		or	[si+1],bh

		add	si,2000h	; increment to next portion of interleave
		jns	L22

		add	si,90-8000h	; increment to first portion of interleave

L22:		dec	ch
		jnz	L20

; restore default InColor register values

		mov	ax,4019h	; default Read/Write Control reg
		out	dx,ax

		mov	ax,071Ah	; default Read/Write Color reg
		out	dx,ax

		pop	ds		; restore registers and return
		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_DisplayCharInC	ENDP

_TEXT		ENDS

		END

