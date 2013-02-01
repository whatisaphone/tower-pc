		TITLE	'Listing 10-13'
		NAME	AlphaModeSet
		PAGE	55,132

;
; Name:		AlphaModeSet
;
;		Program the CRTC in 80-column VGA alphanumeric modes
;
; Caller:	Microsoft C:
;
;			void AlphaModeSet(w,h,c);
;
;			int	w;	/* width of character matrix */
;			int	h;	/* height of character matrix */
;			int	c;	/* character code size */
;

ARGw		EQU	byte ptr [bp+4]		; must be 8 or 9 pixels wide
ARGh		EQU	byte ptr [bp+6]		; must be 2-32 pixels high
ARGc		EQU	byte ptr [bp+8]		; must be 8 or 9 bits

CRT_COLS	EQU	4Ah		; addresses in video BIOS data area
ADDR_6845	EQU	63h

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		PUBLIC	_AlphaModeSet
_AlphaModeSet	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si

; Program the CRTC

		mov	bx,40h
		mov	es,bx		; ES := video BIOS data segment

		mov	bl,ARGw		; BL := character width
		mov	bh,ARGh		; BH := character height
		call	SetCRTC

; Program the Sequencer and Attribute Controller for 8 or 9 dots per character

		mov	dx,3C4h
		mov	ax,0100h	; AH bit 1 := 0 (synchronous reset)
					; AL := 0 (Reset register number)
		cli			; disable interrupts
		out	dx,ax		; Sequencer synchronous reset

		mov	bx,1		; BH,BL := values for 8-wide chars:
					;  BH := 0 (value for Horiz Pel Pan)
					;  BL := 1 (value for Clocking Mode)
		cmp	ARGw,8
		je	L01		; jump if 8-wide characters

		mov	bx,0800h	; BH,BL := values for 9-wide characters

L01:		mov	ah,bl		; AH := value for Clocking Mode reg
		mov	al,1		; AL := Clocking Mode reg number
		out	dx,ax		; program the Sequencer

		mov	ax,0300h	; AH := 3 (disable reset)
					; AL := 0 (Sequencer register number)
		out	dx,ax		; disable Sequencer reset
		sti			; enable interrupts

		mov	bl,13h		; BL := Horizontal Pel Pan reg number
		mov	ax,1000h	; AH := 10H (INT 10H function number)
					; AL := 0 (set specified register)
		int	10h		; program Attribute Controller

; Program the Attribute Controller for 8- or 9-bit character codes

		mov	ax,1000h	; AH := 10H (INT 10H function number)
					; AL := 0 (set specified register)
		mov	bx,0F12h	; BH := 0FH (Color Plane Enable value)
					; BL := 12H (Color Plane Enable reg #)
		cmp	ARGc,8
		je	L02		; jump if 8-bit character codes

		mov	bh,7		; BH bit 3 := 0 (ignore bit 3 of all
					;  attributes)
L02:		int	10h		; update Color Plane Enable register

; update video BIOS data area

		mov	ax,720		; AX := displayed pixels per row
		div	ARGw		; AL := displayed character columns
		mov	es:[CRT_COLS],al

		pop	si
		pop	bp
		ret

_AlphaModeSet	ENDP


SetCRTC         PROC	near		; Caller:	BH = character height
					;		BL = character width

		push	dx
		mov	dx,es:[ADDR_6845]  ; CRTC I/O port

; establish CRTC vertical timing and cursor position in character matrix

		push	bx		; preserve char height and width 
		mov	ax,1110h	; AH := 11H (INT 10H function number)
					; AL := 0 (user alpha load)
		xor	cx,cx		; CX := 0 (store no characters)
		int	10h		; call BIOS to program CRTC
		pop	bx

; enable I/O writes to CRTC registers

		mov	al,11h		; AL := Vertical Retrace End reg number
		out	dx,al
		inc	dx
		in	al,dx		; AL := current value of this register
		dec	dx

		mov	ah,al		; AH := current value
		mov	al,11h		; AL := register number
		push	ax		; save on stack

		and	ah,01111111b	; zero bit 7
		out	dx,ax		; update this register

; establish CRTC horizontal timing

		xor	bh,bh		; BX := character width
		sub	bl,8		; BX := 0 or 1
		neg	bx		; BX := 0 or 0FFFFH
		and	bx,14		; BX := 0 or 14 (offset into table)
		mov	si,bx		; SI := offset into table

		add	si,offset DGROUP:HorizParms	; DS:SI -> parameters
		call	UpdateCRTC

; write-protect CRTC registers

		pop	ax		; AX := previous VR End register data
		out	dx,ax		; restore this register

		pop	dx
		ret

SetCRTC         ENDP


UpdateCRTC	PROC	near		; Caller:	DX = CRTC address port
					;		DS:SI -> parameters
					; Destroys:	AX,CX

		mov	cx,7		; CX := number of registers to update
		
L10:		lodsw			; AH := data for CRTC register in AL
		out	dx,ax		; update the register
		loop	L10

		ret

UpdateCRTC	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

HorizParms	DW	6B00h,5901h,5A02h,8E03h,5F04h,8C05h,2D13h  ; 8-wide
		DW	5F00h,4F01h,5002h,8203h,5504h,8105h,2813h  ; 9-wide

_DATA		ENDS

		END
