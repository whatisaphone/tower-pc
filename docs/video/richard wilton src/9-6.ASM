		TITLE	'Listing 9-6'
		NAME	DisplayChar10
		PAGE	55,132

;
; Name:		DisplayChar10
;
; Function:	Display a character in native EGA and VGA graphics modes
;
; Caller:	Microsoft C:
;
;			void DisplayChar10(c,x,y,fgd,bkgd);
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

VARshift	EQU	         [bp-2]

BytesPerLine	=	80		; (must 40 in 320x200 16-color mode)
RMWbits		=	18h		; Read-Modify-Write bits

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_DisplayChar10
_DisplayChar10	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,2		; stack space for local variable
		push	si
		push	di
		push	ds

; calculate first pixel address

		mov	ax,ARGy		; AX := y
		mov	bx,ARGx		; BX := x
		call	PixelAddr10	; ES:BX -> buffer
					; CL := # bits to shift left to mask
					;  pixel
		inc	cx
		and	cl,7		; CL := # bits to shift to mask char

		mov	ch,0FFh
		shl	ch,cl		; CH := bit mask for right side of char
		mov	VARshift,cx

		push	es		; preserve video buffer segment
		mov	si,bx		; SI := video buffer offset

; set up character definition table addressing

		mov	ax,40h
		mov	ds,ax		; DS := segment of BIOS Video
					;  Display Data area
		mov	cx,ds:[85h]	; CX := POINTS (pixel rows in character)

		xor	ax,ax
		mov	ds,ax		; DS := absolute zero

		mov	ax,ARGc		; AL := character code
		mov	bx,43h*4	; DS:BX -> int 43h vector
		les	di,ds:[bx]	; ES:DI -> start of character table
		mul	cl		; AX := offset into char def table
					;  (POINTS * char code)
		add	di,ax		; DI := addr of char def

		pop	ds		; DS:SI -> video buffer

; set up Graphics Controller registers

		mov	dx,3CEh		; Graphics Controller address reg port

		mov	ax,0A05h	; AL :=  Mode register number
					; AH :=  Write Mode 2 (bits 0-1)
					;	 Read Mode 1 (bit 4)
		out	dx,ax

		mov	ah,RMWbits	; AH := Read-Modify-Write bits
		mov	al,3		; AL := Data Rotate/Function Select reg
		out	dx,ax

		mov	ax,0007		; AH := Color Don't Care bits
					; AL := Color Don't Care reg number
		out	dx,ax		; "don't care" for all bit planes 

; select output routine depending on whether character is byte-aligned

		mov	bl,ARGfgd	; BL := foreground pixel value
		mov	bh,ARGbkgd	; BH := background pixel value

		cmp	byte ptr VARshift,0   ; test # bits to shift
		jne	L20		; jump if character is not byte-aligned


; routine for byte-aligned characters

		mov	al,8		; AL := Bit Mask register number 

L10:		mov	ah,es:[di]	; AH := pattern for next row of pixels
		out	dx,ax		; update Bit Mask register
		and	[si],bl		; update foreground pixels

		not	ah
		out	dx,ax
		and	[si],bh		; update background pixels

		inc	di		; ES:DI -> next byte in char def table
		add	si,BytesPerLine	; increment to next line in video buffer
		loop	L10
		jmp	short Lexit


; routine for non-byte-aligned characters

L20:		push	cx		; preserve loop counter
		mov	cx,VARshift	; CH := mask for left side of character
					; CL := # bits to shift left
; left side of character

		mov	al,es:[di]	; AL := bits for next row of pixels
		xor	ah,ah
		shl	ax,cl		; AH := bits for left side of char
					; AL := bits for right side of char
		push	ax		; save bits for right side on stack
		mov	al,8		; AL := Bit Mask Register number
		out	dx,ax		; set bit mask for foreground pixels

		and	[si],bl		; update foreground pixels

		not	ch		; CH := mask for left side of char
		xor	ah,ch		; AH := bits for background pixels
		out	dx,ax		; set bit mask

		and	[si],bh		; update background pixels

; right side of character

		pop	ax
		mov	ah,al		; AH := bits for right side of char
		mov	al,8
		out	dx,ax		; set bit mask

		inc	si		; DS:SI -> right side of char in buffer

		and	[si],bl		; update foreground pixels

		not	ch		; CH := mask for right side of char
		xor	ah,ch		; AH := bits for background pixels
		out	dx,ax		; set bit mask

		and	[si],bh		; update background pixels

; increment to next row of pixels in character

		inc	di		; ES:DI -> next byte in char def table
		dec	si
		add	si,BytesPerLine	; DS:SI -> next line in video buffer

		pop	cx
		loop	L20


; restore default Graphics Controller registers

Lexit:		mov	ax,0FF08h	; default Bit Mask
		out	dx,ax

		mov	ax,0005		; default Mode register
		out	dx,ax

		mov	ax,0003		; default Data Rotate/Function Select
		out	dx,ax

		mov	ax,0F07h	; default Color Don't Care
		out	dx,ax

		pop	ds		; restore caller registers and return
		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_DisplayChar10	ENDP

_TEXT		ENDS

		END
