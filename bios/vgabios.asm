%include "tower.inc"

[CPU 8086]
[BITS 16]
[ORG 0]

%substr ASS_YEAR __DATE__ 1, 4
%substr ASS_MONTH __DATE__ 6, 2
%substr ASS_DAY __DATE__ 9, 2

; Important memory address summary:
;   - 0040:0049 (byte)  current video mode
;   - 0040:004a (word)  columns on screen
;   - 0040:004c (word)  size of a page
;   - 0040:0050 (words) array of 8 (row, col) cursor positions per page
;   - 0040:0062 (byte)  current page
;   - 0040:0084 (byte)  rows on screen minus one
;   - 0040:0085 (word)  character height
;   - a000:0000-b800:0000 - video memory

%assign FILLER_BYTE 0xff
%assign ROM_BYTES 0x8000




	dw		0xaa55				; signature
	db		ROM_BYTES / 512		; how many 512-byte blocks
	jmp		0xc000:init			; entry point

	db	"vgabios written for Tower PC emulator by john simon",0
str_boot_msg:
	db	"Tower VGA BIOS built ",__DATE__,0xd,0xa,0xd,0xa,0

		;=================================;
		;|   print_string                |;
		;| input: ds:si points to string |;
		;=================================;
print_string:
	lodsb						; al = next char
	test	al, al
	je		.done				; null-terminated
	mov		ah, 0x0e
	mov		bx, 0x0007			; page 0, attr 7
	int		0x10
	jmp	print_string
.done:
	ret

		;========================;
		;|   wait_for_retrace   |;
		;========================;
wait_for_retrace:
	push	dx
	mov		dx, 0x3da
.again:
	in		al, dx
	and		al, 0x08			; bit 8 indicates vertical retrace
	jz		.again
	pop		dx
	ret

int10_table:
;	dw	int10_00, int10_01, int10_02, int10_03, int10_04, int10_05, int10_06, int10_07
;	dw	int10_08, int10_09, int10_0a, int10_0b, int10_0c, int10_0d, int10_0e, int10_0f
		;=======================================;
		;|                                     |;
		;|   I N T   0 x 1 0   -   V I D E O   |;
		;|                                     |;
int10:	;=======================================;
	hlint	0x10
	iret

			;========================================;
			;|   TELETYPE OUTPUT (ah=0x0e)          |;
			;| input:   al = character              |;
			;|          bh = page number            |;
			;|          bl = color (gfx modes only) |;
int10_0e:	;========================================;
	hlint	0x10
	iret

		;===============;
		;|             |;
		;|   I N I T   |;
		;|             |;
init:	;===============;
	xor		ax, ax
	mov		ds, ax
	mov		word[0x10 * 4], int10	; grab int 10
	mov		word[0x10 * 4 + 2], 0xc000

	or		word[0x410], 0x20	; initial video mode: mode 3, 80x25 color
	mov		ax, 3
	int		0x10				; and set it

; ----------- initialize video memory ------------------------------------------
	mov		bx, 0xa000
	mov		es, bx
	xor		di, di				; a000:0000		
	mov		cx, 0x8000			; thru a000:ffff
	xor		ax, ax
	rep		stosw

	mov		bx, 0xb000
	mov		es, bx				; b000:0000
	mov		cx, 0x8000			; thru b000:ffff
	rep		stosw

; ----------- print boot message, then color top row of screen -----------------
	mov		si, cs
	mov		ds, si
	mov		si, str_boot_msg
	call	print_string

	xor		ax, ax
	mov		ds, ax
	xor		ch, ch
	mov		cl, byte[0x44a]		; cx = columns on screen

	mov		ax, 0xb800
	mov		ds, ax
	mov		bx, 1				; attributes are located at b800:1, :3, :5, etc
.changing_colors:
	mov		byte[bx], 0x09		; the golden byte
	add		bx, 2
	loop	.changing_colors

	retf

	times ROM_BYTES-($-$$) db FILLER_BYTE