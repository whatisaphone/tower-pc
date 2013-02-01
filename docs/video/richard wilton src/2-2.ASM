		TITLE	'Listing 2-2'
		NAME	HRTimeout
		PAGE	55,132

;
; Name:		HRTimeout
;
; Function:	Determine a timeout value for the horizontal blanking interval
;
; Caller:	Microsoft C:
;
;			int HRTimeout();
;

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	_HRTimeout
_HRTimeout	PROC	near

		push	bp		; usual C prologue to establish
		mov	bp,sp		;  stack frame

		mov	ax,40h
		mov	es,ax		; ES := video BIOS data segment

		mov	dx,es:[63h]	; DX := port for CRTC Address register
		add	dl,6		; DX := port for CRTC Status register

; synchronize with start of refresh cycle

L01:		in	al,dx		; AL := CRTC status
		test	al,8		; test bit 3
		jz	L01		; loop while NOT in vertical retrace

L02:		in	al,dx
		test	al,8
		jnz	L02		; loop during vertical retrace

; synchronize with a horizontal scan and time the horizontal blanking interval

		mov	cx,0FFFFh	; CX := loop counter

		cli			; disable interrupts

L03:		in	al,dx
		test	al,1
		jnz	L03		; loop while Display Enable is inactive

L04:		in	al,dx
		test	al,1
		jz	L04		; loop while Display Enable is active

L05:		in	al,dx
		test	al,1
		loopnz	L05		; decrement CX and loop while Display
					;  Enable is inactive

		sti			; enable interrupts again

		mov	ax,cx		; AX := loop counter
		neg	ax
		shl	ax,1		; AX := timeout value

		mov	sp,bp		; discard stack frame and return to C
		pop	bp
		ret

_HRTimeout	ENDP

_TEXT		ENDS

		END
