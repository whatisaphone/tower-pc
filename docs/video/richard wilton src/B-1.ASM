		TITLE	'Listing B-1'
		NAME	ScreenDumpCGA
		PAGE	55,132

;
; Name:		ScreenDumpCGA
;
; Function:	Screen Dump for CGA 640x200 2-color and 320x200 4-color modes
;
; Caller:	(undefined)
;
; Notes:	The main procedure of this program, ScreenDumpCGA, may be
;		called from an application program or as part of a TSR
;		(Terminate-but-Stay Resident) handler for interrupt 5.
;

STDPRN		=	4		; MS-DOS standard printer handle


DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

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
;	Copies one printable row of pixels from the video buffer to the
;	print buffer.  This routine can be modified at will to change the
;	scaling or orientation of the printed image, to interpolate gray-
;	scale values for color pixels, etc.
;
;	This routine formats the printer buffer for output to an Epson
;	MX-80.  The page is printed sideways, with two horizontal printed pixels
;	for each vertical pixel in the video buffer.  Since the CGA screen
;	is 200 pixels high, the printed output is 400 pixels wide.
;

TranslatePixels	PROC	near		; Caller:	SI = video buffer offset
					;		ES:DI -> print buffer

		push	ds		; preserve DS
		mov	ds,VideoBufSeg	; DS:SI -> video buffer

		add	di,398		; ES:DI -> 2 bytes before end of buffer

		mov	cx,200		; CX := # of vertical pixels
		mov	bx,2000h+1	; BX := 1st video buffer increment
		mov	dx,81-2000h	; DX := 2nd video buffer increment

		std			; fill the print buffer backwards

L11:		lodsb			; AL := 8 pixels from video buffer
		mov	ah,al		; AX := 8 doubled pixels
		stosw			; write them to print buffer

		add	si,bx		; increment to next interleave of
		xchg	bx,dx		;  video buffer

		loop	L11

		cld			; clear direction flag
		pop	ds		; restore DS
		ret

TranslatePixels	ENDP

;
; ScreenDumpCGA
;

ScreenDumpCGA	PROC	near		; Caller:	DS = DGROUP

		call	PrinterGraphics	; configure the printer for graphics

		push	ds
		pop	es		; DS,ES := DGROUP

		xor	si,si		; SI := offset of start of video buffer

L21:		push	si
		mov	di,offset DGROUP:PrintBuf
		call	TranslatePixels	; copy one printable row of pixels

		mov	cx,400
		mov	di,offset DGROUP:PrintBuf
		call	PrintPixels	; print them

		pop	si
		inc	si
		cmp	si,80		; loop across all 80 columns in
		jb	L21		;  the video buffer
				
		call	PrinterDefault	; restore the printer to its default
					;  state
		ret

ScreenDumpCGA	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

PrintBuf	DB	400 dup(?)	; print output buffer

VideoBufSeg	DW	0B800h

EpsonGraphics	DB	1Bh,33h,18h
EpsonReset	DB	1Bh,40h
DataHeader	DB	1Bh,4Bh,00h,00h
CRLF		DB	0Dh,0Ah

_DATA		ENDS


;==============================================================================
;
; _ScreenDump
;
;	This is just a C-callable shell to test the damn thing.
;
;==============================================================================

_TEXT		SEGMENT	byte public 'CODE'

		PUBLIC	_ScreenDump
_ScreenDump	PROC	near

		push	bp
		mov	bp,sp		; stack frame

		push	ds
		push	si
		push	di

		call	ScreenDumpCGA

		pop	di
		pop	si
		pop	ds

		mov	sp,bp
		pop	bp
		ret

_ScreenDump	ENDP

_TEXT		ENDS

		END
