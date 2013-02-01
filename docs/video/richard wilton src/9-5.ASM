		TITLE	'Listing 9-5'
		NAME	DisplayChar13
		PAGE	55,132

;
; Name:		DisplayChar13
;
; Function:	Display a character in MCGA/VGA 320x200 256-color mode
;
; Caller:	Microsoft C:
;
;			void DisplayChar13(c,x,y,fgd,bkgd);
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

BytesPerLine	EQU	320

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr13:near

		PUBLIC	_DisplayChar13
_DisplayChar13	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si
		push	di
		push	ds

; calculate first pixel address

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr13	; ES:BX -> buffer
		mov	di,bx		; ES:DI -> buffer

; set up character definition table addressing

		mov	ax,40h
		mov	ds,ax		; DS := segment of BIOS Video
					;  Display Data area
		mov	cx,ds:[85h]	; CX := POINTS (pixel rows in character)

		xor	ax,ax
		mov	ds,ax		; DS := absolute zero

		mov	ax,ARGc		; AL := character code
		mov	bx,43h*4	; DS:BX -> int 43h vector if char < 80h
		lds	si,ds:[bx]	; DS:SI -> start of character table
		mul	cl		; AX := offset into char def table
					;  (POINTS * char code)
		add	si,ax		; SI := addr of char def
		
; store the character in the video buffer

		mov	bl,ARGfgd	; BL := foreground pixel value
		mov	bh,ARGbkgd	; BH := background pixel value

L10:		push	cx		; preserve CX across loop
		mov	cx,8		; CX := character width in pixels
		lodsb
		mov	ah,al		; AH := bit pattern for next pixel row

L11:		mov	al,bl		; AL := foreground pixel value
		shl	ah,1		; carry flag := high-order bit
		jc	L12		; jump if bit pattern specifies a
					;  foreground pixel (bit = 1)
		mov	al,bh		; AL := background pixel value

L12:		stosb			; update one pixel in the buffer
		loop	L11

		add	di,BytesPerLine-8 ; increment buffer address to next
					  ;  row of pixels
		pop	cx
		loop	L10		; loop down character

		pop	ds		; restore registers and return
		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_DisplayChar13	ENDP

_TEXT		ENDS

		END
