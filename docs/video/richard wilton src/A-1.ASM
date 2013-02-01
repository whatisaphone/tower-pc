		TITLE	'Listing A-1'
		NAME	EstablishPSA
		PAGE	55,132

;
; Name:		EstablishPSA
;
; Function:	Establish a Parameter Save Area for the EGA or VGA video BIOS.
;		This save area will reflect the current values of the Attribute
;		Controller's Palette and Overscan registers.
;
; Caller:	Microsoft C:
;
;			void EstablishPSA();
;

SAVE_PTR	EQU	0A8h

DGROUP		GROUP	_DATA

_TEXT		SEGMENT	byte public 'CODE'
		ASSUME	cs:_TEXT,ds:DGROUP,es:DGROUP

		PUBLIC	_EstablishPSA
_EstablishPSA	PROC	near

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

; update SAVE POINTER table with address of Parameter Save Area

		push	es
		pop	ds	; DS -> DGROUP

		mov	word ptr SP_TABLE1[4],offset DGROUP:PSA
		mov	word ptr SP_TABLE1[6],ds

; restore registers and exit

		pop	di
		pop	si
		mov	sp,bp
		pop	bp
		ret

_EstablishPSA	ENDP

_TEXT		ENDS


_DATA		SEGMENT	word public 'DATA'

Old_SAVE_PTR	DD	?		; previous value of SAVE_PTR

SP_TABLE1	DD	7 dup(?)	; RAM copy of SAVE POINTER table

PSA		DB	256 dup(0)	; Parameter Save Area

_DATA		ENDS

		END
