		TITLE	'Listing A-2'
		NAME	EstablishUPP
		PAGE	55,132

;
; Name:		EstablishUPP
;
; Function:	Establish a User Palette Profile Save Area for the VGA video BIOS.
;		This save area overrides the usual default palette values for a
;		specified list of video modes.
;
; Caller:	Microsoft C:
;
;			void EstablishUPP();
;

SAVE_PTR	EQU	0A8h

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP,es:DGROUP

		PUBLIC	_EstablishUPP
_EstablishUPP	PROC	near

		push	bp
		mov	bp,sp
		push	si
		push	di

; preserve previous SAVE_PTR

		push	ds
		pop	es		; ES -> DGROUP
		mov	di,offset DGROUP:Old_SAVE_PTR

		mov	ax,40h
		mov	ds,ax		; DS -> video BIOS data area
		mov	si,SAVE_PTR	; DS:SI -> SAVE_PTR

		mov	cx,4
		rep	movsb

; copy SAVE POINTER table to RAM

		lds	si,es:Old_SAVE_PTR	; DS:SI -> SAVE POINTER table
		mov	di,offset DGROUP:SP_TABLE1
		mov	cx,7*4		; number of bytes to move
		rep	movsb

; update SAVE_PTR with the address of the new SAVE POINTER table

		mov	ds,ax		; DS -> video BIOS data area
		mov	si,SAVE_PTR
		mov	word ptr [si],offset DGROUP:SP_TABLE1
		mov	[si+2],es

; copy SECONDARY SAVE POINTER table to RAM

		lds	si,es:SP_TABLE1[16]	; DS:SI -> SEC SAVE POINTER table
		mov	di,offset DGROUP:SP_TABLE2
		mov	cx,[si]
		rep	movsb

; update new SAVE POINTER table with address of new SECONDARY SAVE POINTER table

		push	es
		pop	ds	; DS -> DGROUP

		mov	word ptr SP_TABLE1[16],offset DGROUP:SP_TABLE2
		mov	word ptr SP_TABLE1[18],ds

; update SECONDARY SAVE POINTER with address of User Palette Profile

		mov	word ptr SP_TABLE2[10],offset DGROUP:UPP
		mov	word ptr SP_TABLE2[12],ds

; restore registers and exit

		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_EstablishUPP	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

Old_SAVE_PTR	DD	?		; previous value of SAVE_PTR

SP_TABLE1	DD	7 dup(?)	; copy of SAVE POINTER table

SP_TABLE2	DW	?		; copy of SECONDARY SAVE POINTER table
		DD	6 dup(?)

UPP		DB	0		; underlining flag
		DB	0		; (reserved)
		DW	0		; (reserved)
		DW	17		; # of palette & overscan registers
		DW	0		; first register specified in table
		DW	DGROUP:PalTable	; pointer to palette table
		DW	seg DGROUP
		DW	0		; number of video DAC color regs
		DW	0		; first video DAC register
		DD	0		; pointer to video DAC color table
		DB	3,0FFh		; list of applicable video modes

PalTable	DB	30h,31h,32h,33h,34h,35h,36h,37h	; a custom palette
		DB	00h,01h,02h,03h,04h,05h,14h,07h
		DB	01h				; overscan reg

_DATA		ENDS

		END
