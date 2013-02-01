		TITLE	'Listing 3-10'
		NAME	DisplayText
		PAGE	55,132

;
; Name:		DisplayText
;
; Function:	Display an alphanumeric string without interference on the CGA
;
; Caller:	Microsoft C:
;
;			int DisplayText(buf,n,offset);
;
;			char *buf;		/* buffer containing text in
;						   CGA alphanumeric format
;						   (alternating character codes
;						   and attribute bytes)
;						*/
;
;			int n;			/* buffer length in bytes */
;
;			unsigned int offset;	/* offset into video buffer */
;

ARGbuf		EQU	word ptr [bp+4]
ARGn		EQU	word ptr [bp+6]
ARGoffset	EQU	word ptr [bp+8]
TIMEOUT 	EQU	6		; horizontal timeout loop limit
VBcount 	EQU	250		; number of words to write during
					;  vertical blanking interval

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
		mov	cx,ARGn
		shr	cx,1		; CX := buffer length in words

		mov	dx,3DAh		; DX := CGA Status Port

; write during remaining vertical blanking interval

L01:		mov	bx,cx		; preserve buffer length in BX
		mov	cx,TIMEOUT	; CX := horizontal timeout
		cli			; disable interrupts during loop

L02:		in	al,dx		; AL := video status
		test	al,1
		loopnz	L02		; loop while Display Enable inactive
		jz	L03		; jump if loop did not time out

		movsw			; copy one word
		sti
		mov	cx,bx		; CX := buffer length
		loop	L01

		jmp	short L10	; exit (entire string copied)

; write during horizontal blanking intervals

L03:		sti
		mov	cx,bx		; restore CX

L04:		lodsw			; AL := character code
					; AH := attribute
		mov	bx,ax		; BX := character and attribute
		push	cx		; preserve word loop counter
		mov	cx,TIMEOUT	; CX := timeout loop limit

		cli			; clear interrupts during one scan line
L05:		in	al,dx
		test	al,1
		loopnz	L05		; loop during horizontal blanking
					;  until timeout occurs
		jnz	L07		; jump if timed out (vertical
					;  blanking has started)
L06:		in	al,dx
		test	al,1
		jz	L06		; loop while Display Enable is active

		xchg	ax,bx		; AX := character & attribute
		stosw			; copy 2 bytes to display buffer

		sti			; restore interrupts
		pop	cx		; CX := word loop counter
		loop	L04

		jmp	short L10	; exit (entire string copied)

; write during entire vertical blanking interval

L07:		pop	bx		; BX := word loop counter
		dec	si
		dec	si		; DS:SI -> word to copy from buffer

		mov	cx,VBcount	; CX := # of words to copy
		cmp	bx,cx
		jnb	L08		; jump if more than VBcount words remain
					;  in buffer
		mov	cx,bx		; CX := # of remaining words in buffer
		xor	bx,bx		; BX := 0
		jmp	short L09

L08:		sub	bx,cx		; BX := (# of remaining words) - VBcount

L09:		rep	movsw		; copy to video buffer

		mov	cx,bx		; CX := # of remaining words
		test	cx,cx
		jnz	L01		; loop until buffer is displayed

L10:		pop	di		; usual C epilogue to restore registers
		pop	si		;  and discard stack frame
		mov	sp,bp
		pop	bp
		ret

_DisplayText	ENDP

_TEXT		ENDS

		END
