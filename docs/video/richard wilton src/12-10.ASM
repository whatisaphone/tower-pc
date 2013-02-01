		TITLE	'Listing 12-10'
		NAME	GetHercMode
		PAGE	55,132

;
; Name:		GetHercMode
;
; Function:	Determine video mode on Hercules adapters by estimating the size
;		of the displayed portion of the video buffer.
;
; Caller:	Microsoft C:
;
;			int GetHercMode(n);	/* returns approximate size */
;						/*  of displayed portion of */
;						/*  video buffer in words   */
;

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	_GetHercMode
_GetHercMode	PROC	near

		push	bp		; preserve BP
		mov	bp,sp

; reset CRTC light pen latch

		mov	dx,3BBh		; DX := light pen reset port
		out	dx,al		; OUT to this port clears the latch
					;  (the value in AL doesn't matter)

; wait for start of next vertical retrace

		dec	dx		; DX := 3BAH (CRT status port)
L01:		in	al,dx		; wait for start of vertical retrace
		test	al,80h
		jnz	L01

L02:		in	al,dx		; wait for end of vertical retrace
		test	al,80h
		jz	L02

		cli			; disable interrupts
L03:		in	al,dx		; wait for start of vertical retrace
		test	al,80h
		jnz	L03

; latch the current CRTC address counter in the Light Pen registers

		dec	dx		; DX := 3B9H
		out	dx,al		; OUT to this port loads the latch
		sti			; re-enable interrupts

; return the value in the Light Pen registers

		mov	dl,0B4h		; DX := 3B4H (CRTC address port)
		mov	al,10h		; AL := Light Pen High register number
		out	dx,al
		inc	dx
		in	al,dx		; read this register
		dec	dx
		mov	ah,al		; AH := current Light Pen High value

		mov	al,11h		; AL := Light Pen Low register number
		out	dx,al
		inc	dx
		in	al,dx		; AX := current light pen latch value
					;  (i.e., value of CRTC address counter
					;   at start of vertical retrace)
		pop	bp
		ret		

_GetHercMode	ENDP

_TEXT		ENDS

		END
