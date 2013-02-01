		TITLE	'Listing 3-9'
		NAME	DisplayText
		PAGE	55,132

;
; Name:		DisplayText
;
; Function:	Display an alphanumeric string without interference on the CGA
;
; Caller:	Microsoft C:
;
;			int DisplayText1(buf,n,offset);
;
;			char *buf;		/* buffer containing text in
;						   CGA alphanumeric format
;						   (alternating character codes
;						   and attribute bytes
;						*/
;
;			int n;			/* buffer length in bytes */
;
;			unsigned int offset;	/* offset into video buffer */
;

Set80X25	EQU	(1 SHL 0)	; bit masks for Mode Control Register
Set320X200	EQU	(1 SHL 1)
BlackAndWhite	EQU	(1 SHL 2)
EnableVideo	EQU	(1 SHL 3)
Set640X200	EQU	(1 SHL 4)
EnableBlink	EQU	(1 SHL 5)

ARGbuf		EQU	word ptr [bp+4]	; stack frame addressing
ARGn		EQU	word ptr [bp+6]
ARGoffset	EQU	word ptr [bp+8]
TIMEOUT		EQU	5		; Horizontal Retrace timeout loop limit


_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		PUBLIC	_DisplayText
_DisplayText	PROC	near

		push	bp		; usual C prologue to establish
		mov	bp,sp		;  stack frame and preserve registers
		push	si
		push	di

		mov	ax,0B800h
		mov	es,ax
		mov	di,ARGoffset	; ES:DI -> destination in video buffer
		mov	si,ARGbuf	; DS:SI -> source buffer
		mov	bx,ARGn
		shr	bx,1		; BX := buffer length in words

		mov	dx,3DAh		; DX := CGA Status Port

; wait for start of vertical blanking period

L01:		mov	cx,TIMEOUT	; CX := loop counter (timeout value)

L02:		in	al,dx		; AL := video status
		test	al,8
		jnz	L02		; loop if in vertical retrace
		test	al,1
		jz	L02		; loop if not in horizontal retrace

		cli			; disable interrupts during horiz retrace

L03:		in	al,dx
		test	al,1
		loopnz	L03		; loop until end of retrace or timeout

		sti			; re-enable interrupts

		jz	L01		; loop if no timeout

; blank the display

		mov	dl,0D8h		; DX := 3D8h (Mode Control register)
		mov	al,(Set80X25 OR EnableBlink)
		out	dx,al		; turn video off

; copy the data to the video buffer

		mov	cx,bx		; CX := buffer length in words
		rep	movsw

; re-enable the display

		or	al,EnableVideo
		out	dx,al

		pop	di		; usual C epilogue to restore registers
		pop	si		;  and discard stack frame
		mov	sp,bp
		pop	bp
		ret

_DisplayText	ENDP

_TEXT		ENDS

		END
