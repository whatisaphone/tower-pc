; LISTING 8
; Microsoft C:
;
;			void SetPixel( x, y, v, n );
;			int x,y;	/* pixel coordinates */
;			int v;		/* video page ( 0 or 1 ) */
;			int n;		/* pixel value */
;
; Code based on routines in " Programmer's Guide to PC and PS/2 video
; Systems " by Richrd Wilton, published by Microsoft Press (1987).
;
_TEXT		SEGMENT byte public 'CODE'
		ASSUME	cs:_TEXT
		PUBLIC 	_SetPixel
_SetPixel	PROC	near
		push	bp
		mov	bp,sp
; compute pixel address in video buffer
		mov	ax,80
		mul	word ptr [bp+6]	; AX= y*(bytes per scan line)
		mov	bx,[bp+4]	; BX= x
		mov	cl,bl		; CL= low-order word of x
		shr	bx,1
		shr	bx,1
		shr	bx,1		; BX= x/8
		add	bx,ax		; BX= y*(bytes per line)+x/8
		cmp	byte ptr [bp+8],0
		je	L01		; jump if video page 0
		mov	ax,4Dh
		mov	es,ax		; ES= BIOS data segment
		add	bx,es:[4Ch]	; add CRT_LEN for video page 1
L01:		mov	ax,0A000h
		mov	es,ax		; ES.BX= byte address of pixel
		and	cl,7		; CL= x & 7
		xor	cl,7		; CL= # of bits to shift left
; set Graphics Controller write mode 2
		mov	dx,3CEh		; GC address register port
		mov	ah,1		; AH= unshifted bit mask
		shl	ah,cl		; AH= bit mask in proper pos.
		mov	al,8		; AL= Bit register #
		out	dx,ax
		mov	ax,205h		; AL= Mode register number
		out	dx,ax		; AH= Write Mode 2(bits 0,1)
					;     Read Mode 0 (bit 3)
		mov	ax,0003		; AL= Function Select reg. #
		out	dx,ax		; AH= read-modify-write bits
; set the pixel value
		mov	al,[bp+10]	; AL= pixel value
		xchg	al,es:[bx]	; rd-modify-write 4 bit planes
; restore default Graphics Controller register value
		mov	ax,0FF08h	; default Bit Mask
		out	dx,ax
		mov	ax,0005		; default Mode register
		out	dx,ax
		mov	ax,0003		; default Function Select
		out	dx,ax
		mov	sp,bp		; restore stack fname & return
		pop	bp
		ret
_SetPixel	ENDP
_TEXT		ENDS
		END
