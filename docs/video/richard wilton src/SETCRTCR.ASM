; LISTING 2
;Microsoft C:
;	void SetCRTCReg( n, value );
;		int n;			/* register number */
;		unsigned char value; 	/* value to store in register */
;
_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT
		PUBLIC	_SetCRTCReg
_SetCRTCReg	PROC	near  	
		push	bp
		mov	bp,sp
		mov	ax,40h	; get I/O port for CRTC index reg (40h ?)
		mov	es,ax	; from ROM BIOS data area
		mov	dx,es:[63h]
		mov	al,[bp+4]	; AL= register number
		mov	ah,[bp+6]	; AH= value
		out	dx,ax	; store register numder and value
		pop	bp
		ret
_SetCRTCReg	ENDP
_TEXT		ENDS
		END








