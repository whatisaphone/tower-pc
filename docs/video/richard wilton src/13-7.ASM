		TITLE	'Listing 13-7'
		NAME	dgisrect
		PAGE	55,132

;
; Name: 	dgisrect
;
; Function:	draw a filled rectangle using DGIS
;
; Notes:	assemble and link to create DGISRECT.EXE
;

CR		EQU	0Dh
LF		EQU	0Ah

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:_DATA,ss:STACK

EntryPoint	PROC	far

		mov	ax,seg _DATA
		mov	ds,ax			; DS -> _DATA
		push	ss
		pop	es			; ES -> stack segment

; look for installed DGIS devices

		xor	dx,dx			; DX = 0 (buffer length)
		xor	cx,cx			; CX = 0
		xor	bx,bx			; BX = 0
		mov	ax,6A00h		; AX = DGIS opcode (Inquire
						;       Available Devices)
		int	10h
		or	cx,cx
		jnz	L01			; jump if device(s) installed

		mov	dx,offset _DATA:Msg0
		jmp	ErrorExit

; find a graphics output device in the list of installed DGIS devices

L01:		inc	cx			; CX = (# of bytes in list) + 1
		and	cx,0FFFEh		; CX = even number of bytes
		mov	bp,sp
		sub	sp,cx			; establish stack frame
						;  (SS:BP -> end of frame)
		mov	di,sp			; ES:DI -> start of stack frame

		push	di			; save for later
		mov	dx,cx			; DX = size of buffer
		xor	cx,cx
		xor	bx,bx
		mov	ax,6A00h		; AX = DGIS opcode (Inquire
						;       Available Devices)
		int	10h			; get device list at ES:DI
		pop	di			; ES:DI -> device list

L02:		cmp	word ptr es:[di+2],0	; is this a graphics device?
		je	L04			; jump if so

		sub	bx,es:[di]		; BX = bytes remaining in list
		jnz	L03			; jump if more devices in list

		mov	dx,offset _DATA:Msg1
		jmp	ErrorExit

L03:		add	di,es:[di]		; ES:DI -> next device in list
		jmp	L02

; establish a logical connection to the graphics device
;  using the first available configuration on the device

L04:		les	di,es:[di+6]		; ES:DI -> device entry point
		mov	word ptr GrDevEntry,di
		mov	word ptr GrDevEntry+2,es  ; save entry point

		mov	cx,0			; CX = first configuration index
		mov	ax,0027h		; AX = DGIS opcode (Connect)
		call	dword ptr GrDevEntry	; connect to graphics device
		cmp	bx,-1			; test returned handle
		jne	L05			; jump if connected

		mov	dx,offset _DATA:Msg2
		jmp	ErrorExit

L05:		mov	ChannelHandle,bx	; save the handle for later
		mov	ax,001Bh		; AX = DGIS opcode (Init DGI)
		call	dword ptr GrDevEntry	; initialize the device with
						;  default attributes

; draw a filled rectangle using default attributes

		mov	di,100			; DI = lower right corner y
		mov	si,100			; SI = lower right corner x
		mov	dx,0			; DX = upper left corner y
		mov	cx,0			; CX = upper left corner x
		mov	bx,ChannelHandle	; BX = handle
		mov	ax,003Fh		; AX = DGIS opcode (Output
						;       Filled Rectangle)
		call	dword ptr GrDevEntry

; disconnect and exit

		mov	bx,ChannelHandle	; BX = handle
		mov	ax,002Bh		; AX = DGIS opcode (Disconnect)
		call	dword ptr GrDevEntry		

Lexit:		mov	ax,4C00h
		int	21h			; return to DOS

ErrorExit:	mov	ah,9
		int	21h			; display error message
		mov	ax,4C01h
		int	21h			; return to DOS

EntryPoint	ENDP

_TEXT		ENDS


_DATA		SEGMENT	para public 'DATA'

GrDevEntry	DD	?			; graphics device entry point 
ChannelHandle	DW	?			; handle to connected device
						;  configuration

Msg0		DB	CR,LF,'No DGIS devices installed',CR,LF,'$'
Msg1		DB	CR,LF,'No graphics devices installed',CR,LF,'$'
Msg2		DB	CR,LF,'Can''t connect to graphics device',CR,LF,'$'

_DATA		ENDS


STACK		SEGMENT	stack 'STACK'

		DB	400h dup(?)

STACK		ENDS

		END	EntryPoint
