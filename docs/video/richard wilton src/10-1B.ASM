		TITLE	'Listing 10-1b'
		NAME	CGenModeClear
		PAGE	55,132

;
; Name:		CGenModeClear
;
;		Restore EGA or VGA alphanumeric mode after accessing
;		 character generator RAM
;
; Caller:	Microsoft C:
;
;			void CGenModeClear();
;


DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		PUBLIC	_CGenModeClear
_CGenModeClear	PROC	near

		push	bp		; preserve caller registers
		mov	bp,sp
		push	si

; Program the Sequencer

		cli			; disable interrupts
		mov	dx,3C4h		; Sequencer port address
		mov	si,offset DGROUP:SeqParms
		mov	cx,4

L01:		lodsw			; AH := value for Sequencer register
					; AL := register number
		out	dx,ax		; program the register
		loop	L01
		sti			; enable interrupts

; Program the Graphics Controller

		mov	dl,0CEh		; DX := 3CEH (Graphics Controller port
					;		address)
		mov	si,offset DGROUP:GCParms
		mov	cx,3

L02:		lodsw			; program the Graphics Controller
		out	dx,ax
		loop	L02

		mov	ah,0Fh		; AH := INT 10H function number
		int	10h		; get video mode

		cmp	al,7
		jne	L03		; jump if not monochrome mode

		mov	ax,0806h	; program Graphics Controller
		out	dx,ax		;  to start map at B000:0000

L03:		pop	si
		pop	bp
		ret		

_CGenModeClear	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

; Format of the parameters is:  Lo-order byte:  Register number
;				Hi-order byte:  Value for reg

SeqParms	DW	0100h		; synchronous reset
		DW	0302h		; CPU writes to maps 0 and 1
		DW	0304h		; odd-even addressing
		DW	0300h		; clear synchronous reset

GCParms		DW	0004h		; select map 0 for CPU reads
		DW	1005h		; enable odd-even addressing
		DW	0E06h		; map starts at B800:0000

_DATA		ENDS

		END
