;LISTING 1
;Microsoft C:
;	unsigned char GetCRTCReg( n );
;		unsigned char n; /* register number */
;
_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT
		PUBLIC	_GetCRTCReg
_GetCRTCReg	PROC	near  	
		push	bp
		mov	bp,sp
		mov	ax,4Dh	; get I/O port for CRTC index reg ;(40h ?)
		mov	es,ax	; from ROM BIOS data area
		mov	dx,es:[63h]
		mov	al,[bp+4]	; AL= register number
		cli		; clear interrupts
		out	dx,al	; write to CRTC index reg
		jmp	$+2
		inc	dx	; DX= I/O port for CRTC data reg
		in	al,dx	; AL= register value
		sti		; enable interrupts
		xor	ah,ah	; AX= return value
		pop	bp
		ret
_GetCRTCReg	ENDP
_TEXT		ENDS
		END


