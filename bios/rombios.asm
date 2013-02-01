%include "tower.inc"

[CPU 8086]
[BITS 16]
[ORG 0]

%substr __YEAR__ __DATE__ 1, 4

; Important memory address summary:
;   - 0040:006c (dword) timer ticks since midnight
;   - 0040:0070 (byte)  non-zero if midnight overflow since last INT8

%assign DEBUG_PORT 0xfade
%assign HLE_PORT 0xface
%assign FILLER_BYTE 0xff

%macro outdbg 2+	; %1 = LOG_ level, %2 = string
	jmp		%%the_code
%%the_str:
	db	%2,0
%%the_code:
	push	ds
	push	ax
	push	si

	push	cs
	pop		ds			; mov ds, cs
	mov		ax, %1
	mov		si, %%the_str
	call	debug_string

	pop		si
	pop		ax
	pop		ds
%endmacro



	db	"rombios written for Tower PC emulator by john simon",0
str_boot_msg:
	db	"Tower PC Emulator, copyright © 2008-",__YEAR__," by John Simon",0xd,0xa
	db	"BIOS Built ",__DATE__,0xd,0xa,0xd,0xa,0
str_floppy_msg:
	db	"Booting from floppy...",0
str_hd_msg:
	db	"Booting from hard disk...",0
str_cd_msg:
	db	"Booting from CD-ROM...",0
str_failed:
	db	"Failed.",0xd,0xa,0
str_success:
	db	0xd,0xa,0xd,0xa,0
str_boot_fail:
	db	0xd,0xa,"Failed to find a boot device.  System halted.",0

%define FORM_VECTOR(i) int %+ i

vector_table:
	dw	int00
	dw	int01
	dw	int02
	dw	int03
	dw	int04
	dw	int05
	dw	int06
	dw	int07		; DON'T TOUCH!!!
	dw	int08
	dw	int09
	dw	send_eoi
	dw	send_eoi
	dw	send_eoi
	dw	send_eoi
	dw	send_eoi
	dw	send_eoi
	dw	int10
	dw	int11
	dw	int12		; DON'T TOUCH!!!
	dw	int13
	dw	int14
	dw	int15
	dw	int16
	dw	int17
	dw	int18
	dw	int19
	dw	int1a
	dw	int1b		; DON'T TOUCH!!!
	dw	int1c
	dw	int1d
	dw	int1e
	dw	int1f
%assign	I	32
%rep	256 - 32	; likewise for 20-ff
	dw	FORM_VECTOR(I)
%assign	I	I + 1
%endrep
%undef	I

int00:	call near intxx
int01:	call near intxx
int02:	call near intxx
int03:	call near intxx
int04:	call near intxx
int05:	call near intxx
int06:	call near intxx
int07:	call near intxx
; 08-0f is pic0
int10:	call near intxx
int13:	call near intxx
int14:	call near intxx
int15:	call near intxx
int17:	call near intxx
int1b:	call near intxx
int1d:	call near intxx
int1f:	call near intxx
%assign	I	32
%rep	256 - 32	; likewise for 20-ff
FORM_VECTOR(I):	call near intxx
%assign	I	I + 1
%endrep
%undef	I

		;=================================;
		;|   print_string                |;
		;| input: ds:si points to string |;
		;=================================;
print_string:
	push	ax
	push	bx
.loop:
	lodsb						; al = next char
	test	al, al
	je		.done				; null-terminated
	mov		ah, 0x0e
	mov		bx, 0x0007			; page 0, attr 7
	int		0x10
	jmp		.loop
.done:
	pop		bx
	pop		ax
	ret
		;=================================;
		;|   debug_string                |;
		;| input: ax = LOG_ level        |;
		;|        ds:si points to string |;
		;=================================;
debug_string:
	push	dx
	mov		dx, DEBUG_PORT
	out		dx, ax				; send log level
.loop:
	lodsb
	test	al, al
	out		dx, al				; *DO* send null terminator
	je		.done
	jmp		.loop
.done:
	pop		dx
	ret

		;===================================================;
		;|                                                 |;       (don't yell at me.  this works fine.)
		;|   I N T   0 x ? ?   -   S E N D   T O   H L E   |;
		;| can be called two ways:                         |;
		;|   - automatically (int 0x13)                    |;
		;|   - manually (mov bp, 0x13/int 0xff)            |;
intxx:	;===================================================;
%ifdef	HLE_PORT
	cli

	push	dx
	mov		dx, HLE_PORT
; ------------ send general registers to Hle -----------------------------------
	out		dx, ax				; ax
	mov		ax, cx				; cx
	out		dx, ax
	pop		ax					; dx
	out		dx, ax
	mov		ax, bx				; bx
	out		dx, ax
	mov		ax, si				; si
	out		dx, ax
	mov		ax, di				; di
	out		dx, ax
	mov		ax, es				; es
	out		dx, ax
	mov		ax, ds				; ds
	out		dx, ax
	pushf						; flags
	pop		ax
	out		dx, ax
; ------------ locate and send vector number -----------------------------------
	pop		ax					; don't jump back to stubs
	sub		ax, (int01 - int00)	; ax = int## label we're searching for
	mov		di, cs
	mov		es, di
	mov		di, vector_table
	mov		cx, 256
	repne	scasw				; afterwards, cx == (255 - vector_index)
	jcxz	.manual_call		; remember, vector 0xff is manual too (could use jne.none to differentiate)
.called_from_stub:
	mov		ax, 255
	sub		ax, cx				; now cx = vector_index
	jmp		.continue
.manual_call:
	mov		ax, bp
.continue:
	out		dx, ax
; ------------ read modified registers back from Hle ---------------------------
	in		ax, dx				; ax -- saved for later
	push	ax
	in		ax, dx				; cx
	mov		cx, ax
	in		ax, dx				; dx -- saved for later
	push	ax
	in		ax, dx				; bx
	mov		bx, ax
	in		ax, dx				; si
	mov		si, ax
	in		ax, dx				; di
	mov		di, ax
	in		ax, dx				; es
	mov		es, ax
	in		ax, dx				; ds
	mov		ds, ax
	in		ax, dx				; flags
	push	ax
	popf
	pop		dx
	pop		ax

	sti
	retf	2					; like iret but preserves flags
%else	; if no HLE_PORT, dummy handler
	iret
%endif

send_eoi:
	push	ax
	outb	0x20, 0x20
	pop		ax
	iret

send_eoi_slave:
	push	ax
	outb	0x20, 0x20
	outb	0xa0, 0x20
	pop		ax
	iret

		;===============================================;
		;| INT 0x08                                    |;
		;|   I R Q   0   -   S Y S T E M   T I M E R   |;
		;| freq = about 18.2Hz                         |;
int08:	;===============================================;
	cli
	push	ds
	push	ax
	push	dx

	xor		ax, ax
	mov		ds, ax

; ----------- increment clock --------------------------------------------------
	mov		ax, word [0x46c]
	mov		dx, word [0x46e]
	add		ax, byte 1
	adc		dx, byte 0

	cmp		dx, byte 0x17		; 0x17fe80 ticks in a day
	jb		.skip_midnight
	cmp		ax, 0xfe80
	jb		.skip_midnight

	xor		ax, ax
	xor		dx, dx
	inc		byte [0x470]

.skip_midnight:
	mov		word [0x46c], ax
	mov		word [0x46e], dx

; ----------- turn floppy motor off? -------------------------------------------
	mov		al, byte [0x440]
	test	al, al
	jz		.skip_floppy
	dec		al
	mov		byte [0x440], al
	jnz		.skip_floppy

	; TODO: turn floppy motor off here

.skip_floppy:
	int		0x1c				; call alternate tick vector
	outb	0x20, 0x20			; end-of-interrupt

	pop		dx
	pop		ax
	pop		ds
	stc
int1c:	; --- the user timer interrupt -----------------------------------------
	iret

		;=======================================;
		;| INT 0x09                            |;
		;|   I R Q   1   -   K E Y B O A R D   |;
		;|                                     |;
int09:	;=======================================;
	cli
	hlint	0x09

	push	ax
	outb	0x20, 0x20			; send EOI
	pop		ax

	sti
	iret

		;=================================================================;
		;|                                                               |;
		;|   I N T   0 x 1 1   -   G E T   E Q U I P M E N T   L I S T   |;
		;| returns: ax = equipment list word at 0040:0010                |;
int11:	;=================================================================;
	push	ds

	xor		ax, ax
	mov		ds, ax
	mov		ax, word [0x410]	; load from bios area

	pop		ds
	iret

		;===========================================================;
		;|                                                         |;
		;|   I N T   0 x 1 2   -   G E T   M E M O R Y   S I Z E   |;
		;| returns: ax = KB of base memory (typically 640)         |;
int12:	;===========================================================;
	push	ds

	xor		ax, ax
	mov		ds, ax
	mov		ax, word [0x413]	; load from bios area

	pop		ds
	iret

int16_table: dw int16_00
		;=============================================;
		;|                                           |;
		;|   I N T   0 x 1 6   -   K E Y B O A R D   |;
		;| input: ah = function                      |;
int16:	;=============================================;
	push	bx
	push	ds
	cmp		ah, 00
	ja		int16_xx

	mov		bx, 0xf000
	mov		ds, bx
	xor		bx, bx
	mov		bl, ah				; swith(ah)
	shl		bx, 1
	jmp		word [int16_table+bx]

			;==================================;
			;|   WAIT FOR KEYSTROKE (ah=0x00) |;
			;| returns: ah = scan code        |;
			;|          al = ASCII code       |;
int16_00:	;==================================;
	mov		bx, 0x40
	mov		ds, bx
.keep_waiting:
	sti
	mov		bx, word [0x1a]		; get pointer to next character
	cmp		bx, word [0x1c]		; if same as pointer to free slot, loop
	jz		.keep_waiting
	mov		ax, word [bx]

	add		bx, 2
	cmp		bx, word [0x482]
	jb		.dont_reset_loop
	mov		bx, word [0x480]	; if beyond end, set back to beginning
.dont_reset_loop:
	mov		word [0x1a], bx		; store next character pointer
	jmp		int16_clear_zf

int16_xx:
	hlint	0x16
	jz		int16_set_zf
int16_clear_zf:
	pop		ds
	pop		bx
	push	bp
	mov		bp, sp
	and		byte [bp+6], 0xbf
	pop		bp
	iret
int16_set_zf:
	pop		ds
	pop		bx
	push	bp
	mov		bp, sp
	or		byte [bp+6], 0x40
	pop		bp
	iret

		;=====================================================;
		;|                                                   |;
		;|   I N T   0 x 1 8   -   B O O T   F A I L U R E   |;
		;|                                                   |;
int18:	;=====================================================;
	mov		si, cs
	mov		ds, si
	mov		si, str_boot_fail
	call	print_string
.freeze:
	jmp		.freeze

		;=================================================;
		;|                                               |;
		;|   I N T   0 x 1 9   -   B O O T L O A D E R   |;
		;|                                               |;
int19:	;=================================================;
	call	int19_hd
	call	int19_cd
	call	int19_floppy
	int		0x18				; failed
.freeze:
	jmp		.freeze				; nothing else we can try

; ----------- try floppy disk --------------------------------------------------
int19_floppy:
	mov		si, cs
	mov		ds, si
	mov		si, str_floppy_msg
	call	print_string

	mov		ax, 0x0201			; ah = command (read), al = sector count
	mov		cx, 0x0001			; ch = cylinder, cl = sector number
	xor		dx, dx				; dh = head, dl = drive
	mov		es, dx
	mov		bx, 0x7c00			; es:bx = 0000:7c00
	int		0x13				; read boot sector
	jnc		int19_success

	mov		si, cs
	mov		ds, si
	mov		si, str_failed		; failed
	call	print_string
	ret

; ----------- try hard disk ----------------------------------------------------
int19_hd:
	mov		si, cs
	mov		ds, si
	mov		si, str_hd_msg
	call	print_string

	mov		ax, 0x0201			; ah = read sectors, al = 1 sector
	mov		cx, 0x0001			; ch = cyl 0, cl = sector 1
	mov		dx, 0x0080			; dh = head 0, dl = hda
	xor		bx, bx
	mov		es, bx
	mov		bx, 0x7c00
	int		0x13
	;stc
	jnc		int19_success

	mov		si, cs
	mov		ds, si
	mov		si, str_failed		; failed
	call	print_string
	ret

; ----------- cd-rom -----------------------------------------------------------
int19_cd:
	mov		si, cs
	mov		ds, si
	mov		si, str_cd_msg
	call	print_string

	stc							; do cd junk later
	jnc		int19_success

	mov		si, cs
	mov		ds, si
	mov		si, str_failed		; failed
	call	print_string
	ret

; ----------- success!! --------------------------------------------------------
int19_success:
	push	dx					; save the boot drive
	mov		si, cs
	mov		ds, si
	mov		si, str_success
	call	print_string

	xor		ax, ax				; start as clean as possible
	xor		bx, bx
	xor		cx, cx
	pop		dx					; boot drive in dl, junk in dh
	xor		dh, dh				; bit 5 is 0 if device supported by int13, rest are 0 always
	xor		si, si
	xor		di, di
	xor		bp, bp
	mov		sp, 0x7bfc			; build a stack
	mov		ds, ax
	mov		es, ax
	mov		ss, ax
	add		ax, 0				; clear flags
	sahf
	jmp		0x0000:0x7c00

int1a_table: dw int1a_00, int1a_01
		;=====================================;
		;|                                   |;
		;|   I N T   0 x 1 A   -   T I M E   |;
		;| input: ah = function              |;
int1a:	;=====================================;
	push	bx
	push	ds
	cmp		ah, 01
	ja		int1a_xx

	mov		bx, 0xf000
	mov		ds, bx
	xor		bx, bx
	mov		bl, ah				; swith(ah)
	shl		bx, 1
	jmp		word [int1a_table+bx]

			;=========================================================;
			;|   GET SYSTEM TIME (ah=00)                             |;
			;| returns: cx:dx = number of timer ticks since midnight |;
int1a_00:	;=========================================================;
	xor		cx, cx
	mov		ds, cx
	mov		dx, word [0x46c]	; load from bios area
	mov		cx, word [0x46e]
	jmp		int1a_done

			;=============================================;
			;|   SET SYSTEM TIME (ah=01)                 |;
			;| input: cx:dx = clock ticks since midnight |;
int1a_01:	;=============================================;
	outdbg	LOG_INFO, "System time set by INT 0x1A"

	xor		bx, bx
	mov		ds, bx
	mov		word [0x46c], dx	; put into bios area
	mov		word [0x46e], cx
	jmp		int1a_done

int1a_xx:
	hlint	0x1a
int1a_done:
	pop		ds
	pop		bx
	iret

		;=====================================================;
		;|                                                   |;
		;|   I N T   0 x 1 E   -   F L O P P Y   T A B L E   |;
		;|                                                   |;
int1e:	;=====================================================;
	db	0xdf	; 6ms step rate, 240ms unload time
	db	0x02	; 4ms load time, DMA mode
	db	0x25	; 37 ticks until motor off
	db	0x02	; 512 bytes per sector
	db	0x12	; sectors per track
	db	0x1b	; 3.5" drive
	db	0xff	; data length
	db	0x6c	; 3.5"
	db	0xf6	; filler byte for formatting
	db	0x08	; head settle time
	db	0xe8	; motor start time in 1/8 second intervals

		;==============================;
		;|   EXPANSION ROM LOADER     |;
		;| input: ax = segment to try |;
		;==============================;
try_to_load_rom:
	mov		ds, ax
	cmp		word [0], 0xaa55	; aa55 is rom signature
	jnz		.not_found

	push	ax
	mov		ax, 3
	push	ax
	mov		bp, sp
	call	far [bp]			; call seg:0003
	add		sp, 4				; clean up stack

.not_found:
	ret

		;=========================================;
		;|                                       |;
		;|   B E G I N N I N G   O F   P O S T   |;
		;|                                       |;
		;=========================================;
post_start:
	cli
	xor		bx, bx				; first build a stack
	mov		ss, bx
	mov		sp, 0xfffc

; ------------ set up the int table --------------------------------------------
	mov		ax, cs
	mov		ds, ax
	mov		si, vector_table	; ds:si = f000:vector_table
	xor		di, di
	mov		es, di				; es:di = 0000:0000

	cld
	mov		cx, 0x100
.next_vector:
	movsw						; copy offset
	stosw						; store segment
	loop	.next_vector

	mov		di, 0x70 * 4
	mov		ax, send_eoi_slave
	mov		cx, 8
.second_pic_loop:
	stosw
	add		ax, 2
	loop	.second_pic_loop

; ----------- bios memory area -------------------------------------------------
	xor		ax, ax
	mov		es, ax
	mov		di, 0x400			; es:di = 0000:0400
	mov		cx, 0x80
	rep		stosw

	mov		ds, cx				; ds = 0
	mov		word [0x413], 640	; 640KB base memory

	mov		word [0x480], 0x1e	; keyboard buffer
	mov		word [0x482], 0x3e
	mov		word [0x41a], 0x1e
	mov		word [0x41c], 0x1e

; ----------- set up 8259 pic --------------------------------------------------
	outb	0x20, 0x11			; ICW1
	outb	0x21, 0x08			; IRQs start at 0x08
	outb	0x21, 0x04			; slave is on IR2
	outb	0x21, 0x01			; 8086 mode
	outb	0x21, 0x00			; unmask all ints

	outb	0xa0, 0x11			; ICW1
	outb	0xa1, 0x70			; IRQs start at 0x70
	outb	0xa1, 0x02			; slave of IR2
	outb	0xa1, 0x01			; 8086 mode
	outb	0xa1, 0x00			; unmask all ints

; ------------ set up 8254 pit/system timer ------------------------------------
	outb	0x43, 0x34			; timer 0, 16-bit binary, mode 2
	outb	0x40, 0x00			; count = 0x0000
	outb	0x40, 0x00

	outb	0x43, 0x74			; timer 1, 16-bit binary, mode 2
	outb	0x41, 0x00			; count = 0x0000
	outb	0x41, 0x00

	outb	0x43, 0xb4			; timer 2, 16-bit binary, mode 2
	outb	0x42, 0x00			; count = 0x0000
	outb	0x42, 0x00

; ----------- set up keyboard controller ---------------------------------------
%macro in_ack 0		; fails out if ACK not received
	in		al, 0x60
	cmp		al, 0xfa
;	jne		.kb_not_ok
%endmacro

;	outb	0x64, 0xa7			; turn off kb & mouse lines
;	outb	0x64, 0xad

	; TODO: flush buffers?

;	outb	0x64, 0xaa			; 8042 self-test
;	in		al, 0x60
;	cmp		al, 0x55
;	jne		.kbd_not_ok

;	oub		0x64, 0xab			; 8042 interface test
;	in		al, 0x60
;	and		al, al
;	jne		.kbd_not_ok

	outb	0x64, 0x60			; translation on, mouse off, irq1 on
	outb	0x60, 0x61

; ----------- set up actual keyboard -------------------------------------------
;	outb	0x64, 0xae			; turn kb/mouse lines back on
;	outb	0x64, 0xa8

;	outb	0x60, 0xff			; KB reset + self-teset
;	in_ack
;	in		al, 0x60
;	cmp		al, 0xaa
;	jne		.kb_not_ok

;	outb	0x60, 0xf5			; disable kbd
;	in_ack

	outb	0x60, 0xee			; diagnostic echo
	in		al, 0x60
	cmp		al, 0xee
;	jne		.kbd_not_ok

	outb	0x60, 0xf0			; set scancode set 2
	in_ack
	outb	0x60, 2

	outb	0x60, 0xed			; turn LEDs off
	in_ack
	outb	0x60, 0x00
	in_ack

;	outb	0x60, 0xf4			; re-enable kbd
;	in_ack

%undef in_ack

; ----------- set up floppy drive ----------------------------------------------
	;mov		

; ----------- load any other roms that may be present --------------------------
; TODO: ax=c000,c080,0100,c180,c200,c280... integrate above and skip parts of roms in [2].......
	mov		ax, 0xc000
	call	try_to_load_rom
	mov		ax, 0xc800
	call	try_to_load_rom
	mov		ax, 0xd000
	call	try_to_load_rom
	mov		ax, 0xd800
	call	try_to_load_rom
	mov		ax, 0xe000
	call	try_to_load_rom
	mov		ax, 0xe800
	call	try_to_load_rom

; ----------- identify the bios ------------------------------------------------
	mov		si, cs
	mov		ds, si
	mov		si, str_boot_msg
	call	print_string

	xor		ax, ax
	mov		es, ax

; ----------- detect COM/LPT ports ---------------------------------------------
	;[0e] = segment of extended bios data segment

								; 4 words for COM addrs (plus set in [0x10])
								; 3 words for LPT addrs (plus set in [0x10])

; ----------- detect floppy drives ---------------------------------------------
	or		word [es:0x410], 1	; floppies: 0->00, 1->01, 2->41, 3->81, 4->c1

; ----------- get this party started -------------------------------------------
	int		0x19				; call boot loader

	times 0xfff0-($-$$) db FILLER_BYTE
	jmp	0xf000:post_start
	db	"06/12/08",0
	dw	0x3713