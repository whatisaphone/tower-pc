		TITLE	'Listing B-3'
		NAME	ScreenDumpAlpha
		PAGE	55,132

;
; Name:		ScreenDumpAlpha
;
; Function:	Screen Dump for EGA alphanumeric modes with 350-line resolution
;
; Caller:	(undefined)
;
; Notes:	The main procedure of this program, ScreenDumpAlpha, may be
;		called from an application program or as part of a TSR
;		(Terminate-but-Stay Resident) handler for interrupt 5.
;

STDPRN		=	4		; MS-DOS standard printer handle


DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP,es:DGROUP

;
; PrintLine
;
;	Writes one line of characters to the standard printer device.  Ignores
;	errors.
;

PrintLine	PROC	near		; Caller:	DS:DX -> data
					;		CX = # of bytes
		mov	bx,STDPRN
		mov	ah,40h		; INT 21h function 40h:  Write
		int	21h
		ret

PrintLine	ENDP

;
; PrinterGraphics
;
;	Puts the printer in its "graphics mode."  This routine must be
;	customized for different printers.
;

PrinterGraphics	PROC	near		; Configures Epson MX-80 printer
					;  for 480 dots/line

		mov	ax,4401h	; set raw mode on STDPRN
		mov	bx,STDPRN
		mov	dx,0E0h
		int	21h 

		mov	dx,offset DGROUP:EpsonGraphics
		mov	cx,3
		call	PrintLine
		ret

PrinterGraphics	ENDP

;
; PrinterDefault
;
;	Puts the printer in its default (non-graphics) mode.  Again, this
;	routine must be customized for different printers.
;

PrinterDefault	PROC	near		; Configures Epson MX-80 for default
					;  alphanumeric output

		mov	dx,offset DGROUP:EpsonReset
		mov	cx,2
		call	PrintLine
		ret

PrinterDefault	ENDP

;
; ChopZeroes
;
;	Chops trailing zeros from the printer output buffer.
;

ChopZeroes	PROC	near		; Caller:	ES:DI -> buffer
					;		CX = buffer length
					; Returns:	CX = adjusted length

		jcxz	L01		; exit if buffer is empty

		add	di,cx
		dec	di		; ES:DI -> last byte in buffer

		xor	al,al		; AL := 0 (byte to scan for)

		std			; scan backwards
		repe	scasb
		cld			; restore direction flag
		je	L01		; jump if buffer filled with zeroes

		inc	cx		; adjust length past last nonzero byte

L01:		ret

ChopZeroes	ENDP

;
; PrintPixels
;
;	Prints one row of pixels on an Epson MX-80.
;

PrintPixels	PROC	near		; Caller:	DI = offset of buffer
					;		CX = buffer length

		push	ds
		pop	es		; ES := DS

		push	di		; preserve buffer offset
		call	ChopZeroes
		push	cx		; preserve length

		mov	word ptr DataHeader+2,cx  ; store buffer length
						  ;  in output data header
		mov	dx,offset DGROUP:DataHeader
		mov	cx,4
		call	PrintLine	; print data header

		pop	cx		; CX := buffer length
		pop	dx		; DX := buffer offset
		call	PrintLine	; print the pixels

		mov	dx,offset DGROUP:CRLF
		mov	cx,2
		call	PrintLine

		ret

PrintPixels	ENDP

;
; TranslatePixels
;
;	Copies one printable row of pixels from the first character definition
;	table in map 2 to the print buffer.
;
;	This routine formats the printer buffer for output to an Epson
;	MX-80.  The page is printed sideways, so the printed output is
;	350 pixels wide.
;

TranslatePixels	PROC	near		; Caller:	SI = video buffer offset
					;		ES:DI -> print buffer

		push	ds		; preserve DS
		mov	ds,VideoBufSeg	; DS:SI -> video buffer

		add	di,es:PrintBufSize
		dec	di		; ES:DI -> last byte in print buffer

		mov	dx,3CEh		; Graphics Controller I/O port

; fill the print buffer

		mov	cx,es:Rows	; CX := number of character rows

L11:		push	cx		; preserve CX and SI
		push	si

		mov	ax,0004h	; AH := value for Read Map Select reg
					; AL := Read Map Select reg number
		out	dx,ax		; select map 0 (character codes)

		lodsb			; AX := next char code in video buffer
		mov	cl,5
		shl	ax,cl		; AX := AX * 32
		mov	si,ax		; SI := offset of character definition
					;  in map 2
		mov	ax,0204h
		out	dx,ax		; select map 2 (bit patterns)

		mov	cx,es:Points	; CX := size of character definition

L12:		cld
		lodsb			; AL := 8-bit pattern from character
					;  definition table
					; SI := SI + 1
		std
		stosb			; store bit pattern in print buffer
					; DI := DI - 1
		loop	L12		; loop down character definition

		pop	si		; restore SI and CX
		pop	cx

		add	si,es:Columns	; DS:SI -> next row of characters
		loop	L11		; loop down character rows

		cld			; clear direction flag

		pop	ds		; restore DS
		ret

TranslatePixels	ENDP

;
; ScreenDumpAlpha
;

ScreenDumpAlpha	PROC	near		; Caller:	DS = DGROUP

		call	PrinterGraphics	; configure the printer for graphics

		call	CGenModeSet	; address EGA memory maps in parallel:
					;  map 0 contains character codes
					;  map 2 contains character definitions

; copy screen dimensions from Video Display Data Area

		mov	ax,40h
		mov	es,ax		; ES -> video BIOS data area

		mov	al,es:[84h]	; AX := ROWS
		inc	ax
		mov	Rows,ax
		mov	ax,es:[4Ah]	; AX := CRT_COLS
		add	ax,ax		; * 2 for proper buffer addressing
		mov	Columns,ax
		mov	ax,es:[85h]	; AX := POINTS
		mov	Points,ax
		mul	Rows		; AX := ROWS * POINTS
		mov	PrintBufSize,ax

; print the screen

		push	ds
		pop	es		; DS,ES := DGROUP

		xor	si,si		; SI := offset of start of video buffer

L21:		push	si
		mov	di,offset DGROUP:PrintBuf
		call	TranslatePixels	; copy one printable row of pixels

		mov	cx,PrintBufSize
		mov	di,offset DGROUP:PrintBuf
		call	PrintPixels	; print them

		pop	si
		add	si,2		; increment to next character column
		cmp	si,Columns	; loop across all character columns
		jb	L21
				
		call	CGenModeClear	; restore previous alphanumeric mode

		call	PrinterDefault	; restore the printer to its default
					;  state
		ret

ScreenDumpAlpha	ENDP

;
; CGenModeSet (from Chapter 10)
;

CGenModeSet	PROC	near

		push	si		; preserve these registers
		push	cx

		cli			; disable interrupts
		mov	dx,3C4h		; Sequencer port address
		mov	si,offset DGROUP:SetSeqParms
		mov	cx,4

L31:		lodsw			; AH := value for Sequencer register
					; AL := register number
		out	dx,ax		; program the register
		loop	L31
		sti			; enable interrupts

		mov	dl,0CEh		; DX := 3CEH (Graphics Controller port
					;		address)
		mov	si,offset DGROUP:SetGCParms
		mov	cx,3

L32:		lodsw			; program the Graphics Controller
		out	dx,ax
		loop	L32

		pop	cx		; restore registers and return
		pop	si
		ret		

CGenModeSet	ENDP


;
; CGenModeClear (from Chapter 10)
;

CGenModeClear	PROC	near

		push	si		; preserve these registers
		push	cx

		cli			; disable interrupts
		mov	dx,3C4h		; Sequencer port address
		mov	si,offset DGROUP:ClearSeqParms
		mov	cx,4

L41:		lodsw			; AH := value for Sequencer register
					; AL := register number
		out	dx,ax		; program the register
		loop	L41
		sti			; enable interrupts

		mov	dl,0CEh		; DX := 3CEH (Graphics Controller port
					;		address)
		mov	si,offset DGROUP:ClearGCParms
		mov	cx,3

L42:		lodsw			; program the Graphics Controller
		out	dx,ax
		loop	L42

		mov	ah,0Fh		; AH := INT 10H function number
		int	10h		; get video mode

		cmp	al,7
		jne	L43		; jump if not monochrome mode

		mov	ax,0806h	; program Graphics Controller
		out	dx,ax		;  to start map at B000:0000

L43:		pop	cx		; restore registers and return
		pop	si
		ret		

CGenModeClear	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

PrintBuf	DB	400 dup(?)	; print output buffer

VideoBufSeg	DW	0A000h

EpsonGraphics	DB	1Bh,33h,18h
EpsonReset	DB	1Bh,40h
DataHeader	DB	1Bh,4Bh,00h,00h
CRLF		DB	0Dh,0Ah

Columns		DW	?		; number of displayed character columns
Rows		DW	?		; number of displayed character rows
Points		DW	?		; vertical size of character matrix
PrintBufSize	DW	?		; Rows * Points

SetSeqParms	DW	0100h		; parameters for CGenModeSet
		DW	0402h
		DW	0704h
		DW	0300h

SetGCParms	DW	0204h
		DW	0005h
		DW	0006h

ClearSeqParms	DW	0100h		; parameters for CGenModeClear
		DW	0302h
		DW	0304h
		DW	0300h

ClearGCParms	DW	0004h
		DW	1005h
		DW	0E06h

_DATA		ENDS

		END
