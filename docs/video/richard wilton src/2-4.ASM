		TITLE	'Listing 2-4'
		NAME	HercGraphMode
		PAGE	55,132

;
; Name:		HercGraphMode
;
; Function:	Establish Hercules 720x348 graphics mode on HGC, HGC+, InColor
;
; Caller:	Microsoft C:
;
;				void HercGraphMode();
;

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		PUBLIC	_HercGraphMode
_HercGraphMode	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si
		push	di

; Update Video BIOS Data Area with reasonable values

		mov	ax,40h
		mov	es,ax
		mov	di,49h		; ES:DI := 0040:0049 (BIOS data area)

		mov	si,offset DGROUP:BIOSData
		mov	cx,BIOSDataLen
		rep	movsb		; update BIOS data area

; Set Configuration Switch

		mov	dx,3BFh		; DX := Configuration Switch port
		mov	al,1		; AL bit 1 := 0 (exclude 2nd 32K of
					;		  video buffer)
					; AL bit 0 := 1 (allow graphics mode
		out	dx,al		;		 setting via 3B8h)

; Blank the screen to avoid interference during CRTC programming

		mov	dx,3B8h		; DX := CRTC Mode Control Register port
		xor	al,al		; AL bit 3 := 0 (disable video signal)
		out	dx,al		; blank the screen

; Program the CRTC

		sub	dl,4		; DX := CRTC Address Reg port 3B4h

		mov	si,offset DGROUP:CRTCParms
		mov	cx,CRTCParmsLen

L01:		lodsw			; AL := CRTC register number
					; AH := data for this register
		out	dx,ax
		loop	L01

; Set graphics mode

		add	dl,4		; DX := 3B8h (CRTC Mode Control Reg)
		mov	al,CRTMode	; AL bit 1 = 1 (enable graphics mode)
					;    bit 3 = 1 (enable video)
		out	dx,al

		pop	di		; restore registers and exit
		pop	si
		mov	sp,bp
		pop	bp
		ret

_HercGraphMode	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

				; These are the parameters recommended by Hercules.
				; They are based on 16 pixels/character and
				; 4 scan lines per character.

CRTCParms	DB	00h,35h	; Horizontal Total:  54 characters
		DB	01h,2Dh	; Horizontal Displayed:  45 characters
		DB	02h,2Eh	; Horizontal Sync Position:  at 46th character
		DB	03h,07h	; Horizontal Sync Width:  7 character clocks

		DB	04h,5Bh	; Vertical Total:  92 characters (368 lines)
		DB	05h,02h	; Vertical Adjust:  2 scan lines
		DB	06h,57h	; Vertical Displayed:  87 character rows (348 lines)
		DB	07h,57h	; Vertical Sync Position:  after 87th char row

		DB	09h,03h	; Max Scan Line:  4 scan lines per char

CRTCParmsLen	EQU	($-CRTCParms)/2

BIOSData	DB	7	; CRT_MODE
		DW	80	; CRT_COLS
		DW	8000h	; CRT_LEN
		DW	0	; CRT_START
		DW	8 dup(0) ; CURSOR_POSN
		DW	0	; CURSOR_MODE
		DB	0	; ACTIVE_PAGE
CRTCAddr	DW	3B4h	; ADDR_6845
CRTMode		DB	0Ah	; CRT_MODE_SET (value for port 3B8h)
		DB	0	; CRT_PALETTE (unused)

BIOSDataLen	EQU	$-BIOSData

_DATA		ENDS

		END
