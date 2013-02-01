		TITLE	'Listing 10-14'
		NAME	AlphaModeSet
		PAGE	55,132

;
; Name:		AlphaModeSet
;
; Function:	Program the CRTC in alphanumeric modes on HGC+ or InColor card
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
ARGh		EQU	byte ptr [bp+6]		; must be 4-16 pixels high
ARGc		EQU	byte ptr [bp+8]		; must be 8 or 12 bits

CRT_COLS	EQU	4Ah
CRT_LEN		EQU	4Ch
CRT_MODE_SET	EQU	65h
ROWS		EQU	84h

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		PUBLIC	_AlphaModeSet
_AlphaModeSet	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	ds
		push	si

; Set Configuration Switch to bring RAM starting at B000:4000 into memory map

		mov	dx,3BFh		; DX := Configuration Switch port
		mov	al,1		; AL bit 1 := 0 (exclude 2nd 32K of
					;		  video buffer)
					; AL bit 0 := 1 (make RAM at B000:4000
		out	dx,ax		;		  addressable)

; Blank the screen to avoid interference during CRTC programming

		mov	dx,3B8h		; DX := CRTC Mode Control Register port
		xor	al,al		; AL bit 3 := 0 (disable video signal)
		out	dx,al		; blank the screen

; Program the CRTC

		mov	bh,ARGw		; BH := character width
		mov	bl,ARGh		; BL := character height
		call	SetHercCRTC

; Set the xModeReg

		mov	dx,3B4h		; DX := CRTC address port
		mov	ax,114h		; AH bit 0 := 1 (enable RAM-based
					;  character generator)
					; AL := 14h (xModeReg number)
		cmp	ARGw,9
		je	L01		; jump if 9-wide characters

		or	ah,2		; AH bit 1 := 1 (8-wide characters)

L01:		cmp	ARGc,8
		je	L02		; jump if 8-bit character codes

		or	ah,4		; AH bit 2 := 1 (12-bit character codes)

L02:		out	dx,ax		; update the register

; update video BIOS data area

		mov	ax,40h
		mov	ds,ax		; DS := video BIOS data segment

		mov	ax,720		; AX := displayed pixels per row
		div	ARGw		; AL := displayed character columns
		mov	ds:[CRT_COLS],al

		mov	ax,350		; AX := number of displayed scan lines
		div	ARGh		; AL := displayed character rows
		dec	al		; AL := (character rows) - 1
		mov	ds:[ROWS],al

		inc	al
		mul	byte ptr ds:[CRT_COLS]
		shl	ax,1		; AX := rows * columns * 2
		mov	ds:[CRT_LEN],ax

; re-enable display and exit

		mov	dx,3B8h		; DX := CRT Mode Control port
		mov	al,ds:[CRT_MODE_SET]	; restore previous value
		out	dx,al

		pop	si
		pop	ds
		pop	bp
		ret

_AlphaModeSet	ENDP


SetHercCRTC	PROC	near		; Caller:	BH = character width
					;		BL = character height

		push	dx
		mov	dx,3B4h		; DX := CRTC Address Reg port 3B4h

; establish cursor position in character matrix

		mov	ah,bl
		dec	ah		; AH := value for Max Scan Line reg
		mov	al,9		; AL := Max Scan Line register number
		out	dx,ax

		mov	al,0Bh		; AL := Cursor End reg number
		out	dx,ax		; set cursor to end on last line of
					;   character matrix

		sub	ax,101h		; AH := second-to-last line
					; AL := 0AH (Cursor Start reg number)
		out	dx,ax		; set cursor to start on second-to-
					;  last line

; compute offsets into parameter tables

		sub	bx,0804h	; BH := 0 or 1
					; BL := 0 through 12
		add	bx,bx
		add	bx,bx		; BH := 0 or 4
					; BL := 0 through 48
; establish CRTC horizontal timing

		push	bx		; preserve BX
		mov	bl,bh
		xor	bh,bh		; BX := 0 or 4
		add	bx,offset DGROUP:HorizParms	; DS:BX -> parameters

		mov	al,0		; AL := first CRTC reg to update
		call	UpdateCRTC

; establish vertical timing

		pop	bx
		xor	bh,bh		; BX := 0 through 48
		add	bx,offset DGROUP:VertParms	; DS:BX -> parameters

		mov	al,4		; AL := first CRTC reg to update
		call	UpdateCRTC

		pop	dx		; restore DX
		ret

SetHercCRTC	ENDP


UpdateCRTC	PROC	near		; Caller:	AL = first reg number
					;		DX = CRTC address port
					;		DS:BX -> parameters
					; Destroys:	AX,CX

		mov	cx,4		; CX := number of registers to update
		
L10:		mov	ah,[bx]		; AH := data for CRTC register in AL
		out	dx,ax		; update the register
		inc	ax		; AL := next register number
		inc	bx		; DS:BX -> next value in table
		loop	L10

		ret

UpdateCRTC	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

HorizParms	DB	6Dh,5Ah,5Ch,0Fh		; 8 pixels wide
		DB	61h,50h,52h,0Fh		; 9 pixels wide


VertParms	DB	5Ch,02h,58h,59h		; 4 scan lines high
		DB	4Ah,00h,46h,46h		; 5
		DB	3Dh,04h,3Ah,3Bh		; 6
		DB	34h,06h,32h,33h		; 7
		DB	2Dh,02h,2Bh,2Ch		; 8
		DB	28h,01h,26h,27h		; 9
		DB	24h,00h,23h,23h		; 10
		DB	20h,07h,1Fh,20h		; 11
		DB	1Dh,0Ah,1Dh,1Dh		; 12
		DB	1Bh,06h,1Ah,1Bh		; 13
		DB	19h,06h,19h,19h		; 14
		DB	17h,0Ah,17h,17h		; 15
		DB	16h,02h,15h,16h		; 16

_DATA		ENDS

		END
