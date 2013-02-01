; LISTING 6
; Microsoft C:
;	void SplitScreen( n );
;		int n;		/* scan line at which */
;				/* to split screen */
;
_TEXT		SEGMENT byte pablic 'CODE'
		ASSUME	cs:_TEXT
		PUBLIC	_SplitScreen
_SplitScreen	PROC	near
		push	bp	; preserve BP
		mov	bp,sp
		mov	ax,4Dh		;(40h ?)
		mov	es,ax	; ES -> video BIOS data area
		mov	dx,es:[63h]	; DX= port for CRTC index reg
; wait for vertical retrace
		add	dl,6	; DX= 3BAH or 3DAH (status port)
L01:		in	al,dx	; wait for end of vert. retrace
		test	al,8
		jnz	L01
L02:		in	al,dx	; wait for start of vert. retrace
		test	al,8
		jz	L02
		sub	dl,6	; DX= port for CRTC index reg
; isolate bits 0-7, bit 8, and bit 9 of the Line Compare value
		mov	ax,[bp+4]	; AX= scan line value
		mov	bh,ah	; BH bits 0-1 = bits 8-9 of
				; Line Compare value
		mov	bl,bh
		and	bx,0201h	; BH bit 1 = Line Compare bit 9
					; BL bit 0 = Line Compare bit 0
		mov	cl,4
		shl	bx,cl		; BH bit 5 = Line Compare bit 9
					; BL bit 4 = Line Compare bit 8
		shl	bh,1		; BH bit 6 = Line Compare bit 9
; update the CRTC register
		mov	ah,al	; AH= low-order 8 bits of value
		mov	al,18h	; AL= Line Compare register number
		out	dx,ax	; update Line Compare register
		mov	al,7	; AL= Overflow register number
		cli
		out	dx,al
		inc	dx
		in	al,dx	; AL= current Overflow reg value
		sti
		dec	dx
		mov	ah,al
		and	ah,11101111b	; AH bit 4 = 0
		or	ah,bl	; AH bit 4 = Line Compare bit 8
		mov	al,7	; AL= Overflow register number
		out	dx,ax	; update Overflow register
		mov	al,9	; AL= Max Scan Line register #
		cli
		out	dx,al
		inc	dx
		in	al,dx	; AL= current Max Scan Line value
		sti
		dec	dx
		mov	ah,al
		and	ah,10111111b	; AH bit 6 = 0
		or	ah,bh	; AH bit 6 = Line Compare bit 9
		mov	al,9	; AL= Max Scan Line reg number
		out	dx,ax	; update Max Scan Line register
; set bit 5 of the Attribute Controller Mode Control register
		mov	ax,1007h	; AH= 10h (int 10h function #)
					; AL= 7 (subfunction number)
		mov	bl,10h	; BL= Mode Control reg number
		int	10h	; BH= Mode Control reg value
		or	bh,20h	; set bit 5
		mov	ax,1000h	; AH= 10h
					; AL= 0
		mov	bl,10h
		int	10h	; update Mode Control register
		pop	bp	; restore BP and exit
		ret
_SplitScreen	ENDP
_TEXT		ENDS
		END
