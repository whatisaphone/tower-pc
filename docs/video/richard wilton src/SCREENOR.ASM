; LISTING 4
;Microsoft C:
;	void ScreenOrigin( x, y );
;		int x,y;		/* pixsel x, y coordinates */
;
_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT
		PUBLIC	_ScreenOrigin
_ScreenOrigin	PROC	near  	
		push	bp	; preserve caller register
		mov	bp,sp
; setup for pixel x-coordinates:
;	- determine 8 or 9 bits per pixel by examining bit 0 in
;	  Sequenser Cloking Mode register
;	- compute value for Horizontal Pel Pan register
		mov	dx,3C4H	; DX= port for Sequenser index reg
		mov	al,1
		cli		; disable interrupts
		out	dx,al	; select Clocking Mode reg
		jmp	$+2	; wait for Sequenser to respond
		inc	dx
		in	al,dx
		sti		; set interruppts
		and	al,1	; isolate low-order bit
		mov	cl,9
		sub	cl,al	; CL= 8 or 9 (# of pixels/byte)
		mov	ax,[bp+4]	; AX= pixels x-coordinate
		div	cl	; AH= bit offset in byte
				; AL= byte offset in row
		cmp	cl,8
		je	L01	; jamp if 8 pixels/byte
		dec	ah	; AH= -1, 0-7
		jns	L01	; if AH= -1 ...
		mov	ah,8	; ... set AH = 8
L01:		mov	cl,ah	; CL= Horizontal Pel Pan value
		mov	bl,al
		xor	bh,bh	; BX= byte offset in row
; setup for pixel y-coordinate:
;   - use value in CRTC Max Scan Line register to compute value
;     for CRTC Present Row Scan register
;   - read CRTC offset register to determine width of video buffer;
;     use this to compute value for CRTC Start Address registers
		mov	ax,4Dh		;(40h ?)
		mov	es,ax	; ES-> video BIOS data segment
		mov	dx,es:[63h]	; DX= port for CRTC index reg
		mov	al,9	; AL= Max Scan Line reg number
		cli
		out	dx,al
		push	bx	; preserve BX ( byte offset in row )
		push	dx	; preserve DX ( CRTC index reg port )
		inc	dx
		in	al,dx	; AL= Max Scan Line value
		sti
		and	ax,1Fh	; AX= value from bits 0-4
		inc	ax
		mov	bx,ax	; BX= scan lines per character
		xor	dx,dx
		mov	ax,[bp+6]	;AX= pixel y-coordinate
		div	bx	; AX= character row
				; DL= value for Preset Row Scan
		mov	ch,dl	; save in CH
		mov	bx,ax	; save character row in BX
		pop	dx	; DX= port for CRTC index reg
		push	dx
		mov	al,13h	; AL= offset reg number
		cli		; disable interapts
		out	dx,al
		jmp	$+2
		inc	dx
		in	al,dx	; AL= offset reg number
		sti		; enable interapts
		xor	ah,ah
		mul	bx	; AX= word offset of start of row
		shl	ax,1	; AX= byte offset of start of row
		pop	dx	; DX= port for CRTC index reg
		pop	bx	; BX= byte offset in row
		add	bx,ax	; BX= buffer offset
		add	dl,6	; video status port (3BAH or 3DAH)
; update CRTC Start Address registers
L02:		in	al,dx	; wait for vertical retrase
		test	al,8
		jz	L02
L03:		in	al,dx	; wait for end of retrase
		test	al,8
		jnz	L03
		cli		; disable interapts
		sub	dl,6	; DX= 3B4H or 3D4H
		mov	ah,bh	; AH= Start Address High
		mov	al,0Ch	; AL= Start Address High reg #
		out	dx,ax	; update this register
		mov	ah,bl	; AH= Start Address Low
		inc	al	; AL= Start Address Low reg #
		out	dx,ax	; update this register
		sti		; enable interapts
; update CRTC Preset Row Scan and
; Attribute Controller Horizontal Pel Pan registers
		add	dl,6	; DX= video status port
L04:		in 	al,dx	; wait for vertical retrase
		test	al,8
		jz	L04
		cli		; disable interapts
		sub	dl,6	; DX= 3B4H or 3D4H
		mov	ah,ch	; AH= value for Preset Row Scan reg
		mov	al,8	; AL= Preset Row Scan reg number
		out	dx,ax	; update this register
		
		mov	dl,0C0h	; DX= 3C0h (Attribute Cont. port)
		mov 	al,13h OR 20h	; AL bit 0-4 = Hor Pan reg #
					; AL bit 5 = 1
		out	dx,al	; write Attribute Cont. Address reg
				; ( The Attribute Controller
				;   address flip-flop has been
				;   reset by the IN at L04.)
		mov	al,cl	; AL= value for Horiz Pel Pan reg
		out	dx,al	; update this register
		sti		; re-enable interrupts
		mov	sp,bp
		pop	bp
		ret
_ScreenOrigin	ENDP
_TEXT		ENDS
		END

