		TITLE	'Listing 13-5'
		NAME	SetPixel
		PAGE	55,132

;
; Name:		SetPixel
;
; Function:	Set the value of a pixel in native EGA graphics modes.
;
; Caller:	Memory-resident routine invoked via interrupt 60H:
;
;			mov ax,PixelX	   ; pixel x-coordinate
;			mov bx,PixelY	   ; pixel y-coordinate
;			mov cx,PixelValue  ; pixel value
;
; Notes:	- Assemble and link to create SETPIXEL.EXE.
;		- Execute once to make SetPixel resident in memory and to point
;		   the INT 60H vector to the RAM-resident code.
;		- Requires MS-DOS version 2.0 or later.
;

RMWbits		EQU	0

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT

		EXTRN	PixelAddr:near

		PUBLIC	SetPixel
SetPixel	PROC	near		; RAM-resident interrupt 60H handler

		sti			; enable interrupts
		push	ax		; preserve caller registers on
		push	bx		;  caller's stack
		push	cx
		push	dx

		push	cx		; preserve pixel value on stack

		call	PixelAddr	; compute pixel address
		shl	ah,cl

		mov	dx,3CEh		; program the Graphics Controller
		mov	al,8		; AL := Bit Mask register number
		out	dx,ax

		mov	ax,0005h
		out	dx,ax

		mov	ah,RMWbits	; AH := Read-Modify-Write bits
		mov	al,3		; AL := Data Rotate/Function Select reg
		out	dx,ax

		pop	ax 
		mov	ah,al		; AH := pixel value
		mov	al,0
		out	dx,ax

		mov	ax,0F01h
		out	dx,ax

		or	es:[bx],al	; set the pixel value

		mov	ax,0FF08h	; restore default Graphics Controller
		out	dx,ax		;  values

		mov	ax,0005
		out	dx,ax

		mov	ax,0003
		out	dx,ax

		mov	ax,0001
		out	dx,ax

		pop	dx		; restore caller registers and return
		pop	cx
		pop	bx
		pop	ax
		iret

SetPixel	ENDP

_TEXT		ENDS


TRANSIENT_TEXT	SEGMENT	para
		ASSUME	cs:TRANSIENT_TEXT,ss:STACK

Install		PROC	near

		mov	ax,2560h	; AH := 25H (INT 21H function number)
					; AL := 60H (interrupt number)
		mov	dx,seg _TEXT
		mov	ds,dx
		mov	dx,offset _TEXT:SetPixel   ; DS:DX -> interrupt handler

		int	21h		; point INT 60H vector to
					;  SetPixel routine

		mov	dx,cs		; DX := segment of start of transient
					;  (discardable) portion of program
		mov	ax,es		; ES := Program Segment Prefix
		sub	dx,ax		; DX := size of RAM-resident portion
		mov	ax,3100h	; AH := 31H (INT 21H function number)
					; AL := 0 (return code)
		int	21h		; Terminate but Stay Resident

Install		ENDP

TRANSIENT_TEXT	ENDS

STACK		SEGMENT	para stack 'STACK'

		DB	80h dup(?)	; stack space for transient portion
					;  of program
STACK		ENDS

		END	Install
