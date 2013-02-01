		TITLE	'Listing 12-4'
		NAME	ScreenOrigin
		PAGE	55,132

;
; Name:		ScreenOrigin
;
; Function:	Set screen origin on EGA and VGA
;
; Caller:	Microsoft C:
;
;			void ScreenOrigin(x,y);
;
;				int	x,y;	/* pixel x,y coordinates */
;

ARGx		EQU	[bp+4]
ARGy		EQU	[bp+6]


CRT_MODE	EQU	49h		; addresses in video BIOS data area
ADDR_6845	EQU	63h
POINTS		EQU	85h
BIOS_FLAGS	EQU	89h

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		PUBLIC	_ScreenOrigin
_ScreenOrigin	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si
		push	di

		mov	ax,40h
		mov	es,ax		; ES -> video BIOS data area
		mov	cl,es:[CRT_MODE]

		mov	ax,ARGx		; AX := pixel x-coordinate
		mov	bx,ARGy		; BX := pixel y-coordinate

		cmp	cl,7
		ja	L01		; jump if graphics mode

		je	L02		; jump if monochrome alpha

		test	byte ptr es:[BIOS_FLAGS],1
		jnz	L02		; jump if VGA

		jmp	short L03

; setup for graphics modes (8 pixels per byte)

L01:		mov	cx,8		; CL := 8 (displayed pixels per byte)
					; CH := 0 (value for Preset Row Scan)
		div	cl		; AH := bit offset in byte
					; AL := byte offset in pixel row
		mov	cl,ah		; CL := bit offset (for Horiz Pel Pan)
		xor	ah,ah
		xchg	ax,bx		; AX := y
					; BX := byte offset in pixel row

		mul	word ptr _BytesPerRow
					; AX := byte offset of start of row
		jmp	short L05

; setup for VGA alphanumeric modes and EGA monochrome alphanumeric mode
;  (9 pixels per byte)

L02:					; routine for alpha modes
		mov	cx,9		; CL := 9 (displayed pixels per byte)
					; CH := 0
		div	cl		; AH := bit offset in byte
					; AL := byte offset in pixel row
		dec	ah		; AH := -1, 0-7
		jns	L04		; jump if bit offset 0-7
		mov	ah,8		; AH := 8
		jmp	short L04

; setup for EGA color alphanumeric modes (8 pixels per byte)

L03:		mov	cx,8		; CL := 8 (displayed pixels per byte)
					; CH := 0
		div	cl		; AH := bit offset in byte
					; AL := byte offset in pixel row

L04:		mov	cl,ah		; CL := value for Horiz Pel Pan reg
		xor	ah,ah
		xchg	ax,bx		; AX := y
					; BX := byte offset in row
		div	byte ptr es:[POINTS]  ; AL := character row
					      ; AH := scan line in char matrix
		xchg	ah,ch		; AX := character row
					; CH := scan line (value for Preset
					;		Row Scan register)
		mul	word ptr _BytesPerRow	; AX := byte offset of char row
		shr	ax,1		; AX := word offset of character row

L05:		call	SetOrigin

		pop	di		; restore registers and exit
		pop	si
		mov	sp,bp
		pop	bp
		ret

_ScreenOrigin	ENDP


SetOrigin	PROC	near		; Caller:  AX = offset of character row
					;	   BX = byte offset within row
					;	   CH = Preset Row Scan value
					;	   CL = Horizontal Pel Pan value

		add	bx,ax		; BX := buffer offset

		mov	dx,es:[ADDR_6845]  ; CRTC I/O port (3B4H or 3D4H)
		add	dl,6		; video status port (3BAH or 3DAH)

; update Start Address High and Low registers

L20:		in	al,dx		; wait for start of vertical retrace
		test	al,8
		jz	L20

L21:		in	al,dx		; wait for end of vertical retrace
		test	al,8
		jnz	L21

		cli			; disable interrupts
		sub	dl,6		; DX := 3B4H or 3D4H

		mov	ah,bh		; AH := value for Start Address High
		mov	al,0Ch		; AL := Start Address High reg number
		out	dx,ax		; update this register

		mov	ah,bl		; AH := value for Start Address Low
		inc	al		; AL := Start Address Low reg number
		out	dx,ax		; update this register
		sti			; enable interrupts

		add	dl,6		; DX := video status port

L22:		in	al,dx		; wait for start of vertical retrace
		test	al,8
		jz	L22

		cli			; disable interrupts

		sub	dl,6		; DX := 3B4H or 3D4H
		mov	ah,ch		; AH := value for Preset Row Scan reg
		mov	al,8		; AL := Preset Row Scan reg number
		out	dx,ax		; update this register

		mov	dl,0C0h		; DX := 3C0h (Attribute Controller port)
		mov	al,13h OR 20h	; AL bit 0-4 := Horiz Pel Pan reg number
					; AL bit 5 := 1
		out	dx,al		; write Attribute Controller Address reg
					;  (The Attribute Controller address
					;    flip-flop has been reset by the
					;    IN at L22.)
		mov	al,cl		; AL := value for Horiz Pel Pan reg
		out	dx,al		; update this register

		sti			; re-enable interrupts
		ret

SetOrigin	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

		EXTRN	_BytesPerRow:word	; bytes per pixel row

_DATA		ENDS

		END
