		TITLE	'Listing 11-4'
		NAME	StoreBitBlock10
		PAGE	55,132

;
; Name:		StoreBitBlock10
;
; Function:	Copy bit block from video buffer to system RAM
;		 in native EGA and VGA graphics modes
;
; Caller:	Microsoft C:
;
;			void StoreBitBlock10(buf,x,y);
;
;			     char far *buf;   /* buffer */
;			     int x,y;    /* upper left corner of bit block */
;


ADDRbuf		EQU	dword ptr [bp+4]
ARGx		EQU	word ptr [bp+8]
ARGy		EQU	word ptr [bp+10]

VARPixelRows	EQU	word ptr [bp-2]
VARPixelRowLen	EQU	word ptr [bp-4]
VARRowCounter	EQU	word ptr [bp-6]
VARStartMask	EQU	word ptr [bp-8]
VAREndMaskL	EQU	word ptr [bp-10]
VAREndMaskR	EQU	word ptr [bp-12]

BytesPerRow	EQU	80		; logical width of video buffer
ByteOffsetShift	EQU	3		; reflects number of pixels per byte
RMWbits		EQU	18h		; selects replace, XOR, AND, or OR

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr10:near

		PUBLIC	_StoreBitBlock10
_StoreBitBlock10	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		sub	sp,12		; establish stack frame
		push	ds
		push	si
		push	di

; establish addressing

		mov	ax,ARGy
		mov	bx,ARGx
		call	PixelAddr10	; ES:BX -> byte offset of x,y
		inc	cl
		and	cl,7		; CL := number of bits to shift left

		mov	di,bx		; ES:DI -> x,y in video buffer
		
		lds	si,ADDRbuf	; ES:DI -> buffer in system RAM

; obtain dimensions of bit block from header

		lodsw			; AX := number of pixel rows
		mov	VARPixelRows,ax
		lodsw			; AX := bytes per pixel row
		mov	VARPixelRowLen,ax
		lodsb			; AL := bit mask for last byte in row
		mov	ch,al

; set up Graphics Controller

		mov	dx,3CEh		; DX := Graphics Controller I/O port

		mov	ah,RMWbits	; AH := value for Data Rotate/Function
		mov	al,3		;  Select register
		out	dx,ax		; update this register

		mov	ax,0805h	; AH := 8 (read mode 1, write mode 0)
					; AL := 5 (Mode register number)
		out	dx,ax		; set up read mode 0

		mov	ax,0007		; AH := 0 (don't care for all maps;
					;  CPU reads always return 0FFH)
					; AL := 7 (Color Don't Care reg number)
		out	dx,ax		; set up Color Don't Care reg

		mov	ax,0FF08h	; AH := 0FFH (value for Bit Mask reg)
		out	dx,ax		; set up Bit Mask reg

		mov	dl,0C4h		; DX := 3C4H (Sequencer I/O port)
		mov	ax,0802h	; AH := 1000B (value for Map Mask reg)
					; AL := 2 (Map Mask register number)

		cmp	cx,0FF00h	; if mask <> 0FFH or bits to shift <> 0
		jne	L15		;  jump if not byte-aligned

; routine for byte-aligned bit blocks

		mov	cx,VARPixelRowLen

L10:		out	dx,ax		; enable one bit plane for writes
		push	ax		; preserve Map Mask value
		push	di		; preserve video buffer offset of x,y
		mov	bx,VARPixelRows

L11:		push	di		; preserve DI and CX
		push	cx

L12:		lodsb			; AL := next byte of pixels
		and	es:[di],al	; update bit plane
		inc	di
		loop	L12
		
		pop	cx		; restore DI and CX
		pop	di	
		add	di,BytesPerRow	; ES:DI -> next pixel row in buffer
		dec	bx
		jnz	L11		; loop down pixel rows

		pop	di		; ES:DI -> video buffer offset of x,y
		pop	ax		; AH := current Map Mask reg value
		shr	ah,1		; AH := new Map Mask value
		jnz	L10		; loop across all bit planes

		jmp	Lexit

; routine for non-aligned bit blocks

L15:		push	ax		; preserve Map Mask reg values

		mov	bx,0FFh		; BH := 0 (mask for first byte in row)
					; BL := 0FFh
		mov	al,ch		; AL := mask for last byte in pixel row
		cbw			; AH := 0FFh (mask for last-1 byte)

		cmp	VARPixelRowLen,1
		jne	L16		; jump if more than one byte per row

		mov	bl,ch
		mov	ah,ch		; AH := mask for last-1 byte
		xor	al,al		; AL := 0 (mask for last byte)

L16:		shl	ax,cl		; shift masks into position
		shl	bx,cl

		mov	bl,al		; save masks along with ..
		mov	al,8		; .. Bit Mask register number
		mov	VAREndMaskL,ax
		mov	ah,bl
		mov	VAREndMaskR,ax
		mov	ah,bh		
		mov	VARStartMask,ax
		
		mov	bx,VARPixelRowLen
		pop	ax		; restore Map Mask reg values

; set pixels row by row in the bit planes

L17:		out	dx,ax		; enable one bit plane for writes
		push	ax		; preserve Map Mask value
		push	di		; preserve video buffer offset of x,y
		mov	dl,0CEh		; DX := 3CEH (Graphics Controller port)

		mov	ax,VARPixelRows
		mov	VARRowCounter,ax  ; initialize loop counter

; set pixels at start of row in currently enabled bit plane

L18:		push	di		; preserve offset of start of pixel row
		push	si		; preserve offset of row in bit block 
		push	bx		; preserve bytes per pixel row

		mov	ax,VARStartMask
		out	dx,ax		; set Bit Mask reg for first byte of row

		lodsw			; AH := 2nd byte of pixels
					; AL := 1st byte of pixels
		dec	si		; DS:SI -> 2nd byte of pixels
		test	cl,cl
		jnz	L19		; jump if not left-aligned

		dec	bx		; BX := bytes per row - 1
		jnz	L20		; jump if at least 2 bytes per row
		jmp	short L22	; jump if only one byte per row

L19:		rol	ax,cl		; AH := left part of 1st byte,
					;	 right part of 2nd byte
					; AL := right part of 1st byte,
					;	 left part of 2nd byte
		and	es:[di],ah	; set pixels for left part of first byte
		inc	di
		dec	bx		; BX := bytes per row - 2

L20:		push	ax		; preserve pixels
		mov	ax,0FF08h
		out	dx,ax		; set Bit Mask reg for succeeding bytes
		pop	ax

		dec	bx
		jng	L22		; jump if only 1 or 2 bytes in pixel row

; set pixels in middle of row

L21:		and	es:[di],al	; set pixels in right part of current
		inc	di		;  byte and left part of next byte

		lodsw			; AH := next+1 byte of pixels
		dec	si		; AL := next byte of pixels
		rol	ax,cl		; AH := left part of next byte, right
					;	 part of next+1 byte
					; AL := right part of next byte, left
					;	 part of next+1 byte
		dec	bx
		jnz	L21		; loop across pixel row

; set pixels at end of row

L22:		mov	bx,ax		; BH := right part of last byte, left
					;	 part of last-1 byte
					; BL := left part of last byte, right
					;	 part of last-1 byte
		mov	ax,VAREndMaskL	; AH := mask for last-1 byte
					; AL := Bit Mask reg number
		out	dx,ax		; set Bit Mask register
		and	es:[di],bl	; set pixels for last-1 byte

		mov	ax,VAREndMaskR	; mask for last byte in pixel row
		out	dx,ax		; .. last byte in pixel row
		and	es:[di+1],bh	; set pixels for last byte

		pop	bx		; BX := bytes per pixel row
		pop	si
		add	si,bx		; DS:SI -> next row in bit block
		pop	di
		add	di,BytesPerRow	; ES:DI -> next pixel row in buffer
		dec	VARRowCounter
		jnz	L18		; loop down pixel rows

		pop	di		; ES:DI -> video buffer offset of x,y
		pop	ax		; AX := current Map Mask value
		mov	dl,0C4h		; DX := 3C4H
		shr	ah,1		; AH := next Map Mask value
		jnz	L17		; loop across bit planes

; restore Graphics Controller and Sequencer to their default states

Lexit:		mov	ax,0F02h	; default Map Mask value
		out	dx,ax

		mov	dl,0CEh		; DX := 3CEh
		mov	ax,0003		; default Data Rotate/Function Select
		out	dx,ax

		mov	ax,0005		; default Mode value
		out	dx,ax

		mov	ax,0F07h	; default Color Compare value
		out	dx,ax

		mov	ax,0FF08h	; default Bit Mask value
		out	dx,ax

		pop	di		; restore registers and exit
		pop	si
		pop	ds
		mov	sp,bp
		pop	bp
		ret

_StoreBitBlock10 ENDP

_TEXT		ENDS

		END
