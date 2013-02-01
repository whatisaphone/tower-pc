		TITLE	'Listing 10-1a'
		NAME	CGenModeSet
		PAGE	55,132

;
; Name:		CGenModeSet
;
;		Direct access to EGA and VGA alphanumeric character generator RAM
;
; Caller:	Microsoft C:
;
;			void CGenModeSet();
;

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP

		PUBLIC	_CGenModeSet
_CGenModeSet	PROC	near

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

		pop	si
		pop	bp
		ret		

_CGenModeSet	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

; Format of the parameters is:  Lo-order byte:  Register number
;				Hi-order byte:  Value for reg

SeqParms	DW	0100h		; synchronous reset
		DW	0402h		; CPU writes only to map 2
		DW	0704h		; sequential addressing
		DW	0300h		; clear synchronous reset

GCParms		DW	0204h		; select map 2 for CPU reads
		DW	0005h		; disable odd-even addressing
		DW	0006h		; map starts at A000:0000

_DATA		ENDS

		END
