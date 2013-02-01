;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Enables/disables A20 gate, and tests if it's on or off
; Chris Giese <geezer@execpc.com>	http://www.execpc.com/~geezer
; Release date: ?
; This code is public domain (no copyright).
; You can do whatever you want with it.
;
; Usage:
;	a20		tests if gate is on or off
;	a20 on		tries to turn on gate
;	a20 off		tries to turn off gate
;
; Assemble this file with NASM:
;	nasm -f bin -o a20.com a20.asm
;
; NOTE: The most reliable way to control A20 is to let the BIOS do it:
; - INT 15h AH=87h (copy extended memory)
; - INT 15h AH=89h (enter protected mode)
;
; Thanks to chase@osdev.org, who not only tested this code thoroughly
; (on 8 different machines!), but told me how to fix it.
;
; This code has been rewritten since the testing mentioned above.
; 'PS/2' and 'fast' methods are not tested.
;
; The HIMEM.SYS that ships with DOS 7 (Win 95)
; - loads silently and automatically
; - loads DOS in the high memory area (at 1 meg)
; Thus, DOS 7 enables the A20 gate whenever an application exits.
; Try typing "a20 off" followed immediately by "a20" to see this.
;
; Here are the A20 gating methods used by HIMEM.SYS
; I don't know which HIMEM.SYS method numbers (if any)
; correspond to the methods I'm using.
;
; Code         Number  Computer type
; ---------------------------------------------------------------------------
; at           1       IBM AT or 100% compatible
; ps2          2       IBM PS/2
; ptlcascade   3       Phoenix Cascade BIOS
; hpvectra     4       HP Vectra (A & A+)
; att6300plus  5       AT&T 6300 Plus
; acer1100     6       Acer 1100
; toshiba      7       Toshiba 1600 & 1200XE
; wyse         8       Wyse 12.5 Mhz 286
; tulip        9       Tulip SX
; zenith       10      Zenith ZBIOS
; at1          11      IBM PC/AT (alternative delay)
; at2          12      IBM PC/AT (alternative delay)
; css          12      CSS Labs
; at3          13      IBM PC/AT (alternative delay)
; philips      13      Philips
; fasthp       14      HP Vectra
; ibm7552      15      IBM 7552 Industrial Computer
; bullmicral   16      Bull Micral 60
; dell         17      Dell XBIOS
;
; Tales of strange A20:
;
; http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=139774&repeatmerged=yes
; M919 motherboard w/ non-flashable BIOS dated 1996)
; Motherboard disables the keyboard controller, including
; A20 gate functionality. Code from Linux (SYSLINUX) works:
; port 92h method; don't change port 92h b1 unless you have to.
;
; http://www.win.tue.nl/~aeb/linux/kbd/A20.html
; Olivetti M4 with TRIDENT 9660 video integrated on the mainboard
; Fiddling with port 92h f*cks up the video.
; Changing port 92h b1 only when necessary may help.
;
; http://www.win.tue.nl/~aeb/linux/kbd/A20.html
; Sony PCG-Z600NE
; Spontaneous kernel (Linux) reboot after suspend/resume when
; A20 was enabled via port 92h but not via the keyboard controller.
; Apparently suspend/resume saves the A20 state of the keyboard
; controller, but not the port 92h state.
;
; http://www.win.tue.nl/~aeb/linux/kbd/A20.html
; Various SMSC super I/O chips will emulate the keyboard controller,
; but emulate port 92h only when that has been enabled.
;
; http://www.win.tue.nl/~aeb/linux/kbd/A20.html
; i386SL/i486SL and AMD Elan SC400
; A20 control via I/O port 0EEh
;
; http://www.win.tue.nl/~aeb/linux/kbd/A20.html
; Toshiba laptop, Asus P55TP5XE boards (Triton I chipset),
; 	Fujitsu 555T, Compudyne Pentium 60
; A20 gate via keyboard controller is very slow
;
; Other notes from
; http://www.win.tue.nl/~aeb/linux/kbd/A20.html
; - It may be necessary to do both the keyboard controller write
;   and the port 92h write (and the 0EEh write) to disable A20.
; - The system may hang if you reset it while A20 is disabled.
;   Reset vector is 0FFFFFFF0h, which becomes 0FFeFFFF0h if A20
;   is disabled.
;
; http://www.mail-archive.com/bug-grub%40gnu.org/msg05653.html
; Gigabyte motherboard GA-7VX-1 with AMI bios rev 7VX F7B
; USB support is turned on with legacy support (USB for keyboard/fdd)
; Any attempt to use the keyboard controller to enable A20 kills
; the keyboard. This board _must_ use the port 92h method.
; Unfortunately, INT 15h AX=2403h isn't available on this system.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	ORG 100h

; CHECK FOR XMS (HIMEM.SYS)
	mov ax,4300h
	int 2Fh
	cmp al,80h
	jne no_xms

	inc byte [xms]
	mov si,got_xms		; DEBUG
	call cputs		; DEBUG

	mov ax,4310h		; get XMS driver address
	push es
		int 2Fh
		mov [xms_entry + 2],es
		mov [xms_entry + 0],bx
	pop es
no_xms:

; ASK BIOS IF 'FAST' (PORT 92h) CONTROL OF A20 IS SUPPORTED
	mov ax,2403h
	int 15h
	jc no_fast
	cmp ah,0
	jne no_fast
	and bx,2
	je no_fast

	inc byte [fast]
	mov si,got_fast		; DEBUG
	call cputs		; DEBUG
no_fast:

; GET COMMAND-LINE ARGS
	mov bl,10		; collect up to 10 command-line arguments...
	mov di,args		; ...at [args]

	mov si,80h		; point to command tail
	lodsb
	xor ch,ch
	mov cl,al		; CX=length of tail
	or cx,cx
	je no_args		; zero length means no command-line args
skip_spaces:
	lodsb			; skip spaces; find start of arg
	dec cx
	cmp al,' '
	jne found_arg_start
	cmp al,0Dh
	je no_args
	or cx,cx
	jne skip_spaces
	jmp short no_args
found_arg_start:
	lea ax,[si - 1]
	stosw			; save ptr to start of arg
find_end:
	lodsb			; skip non-spaces; find end of arg
	dec cx
	cmp al,' '
	je found_arg_end
	cmp al,0Dh
	je got_last_arg
	or cx,cx
	jne find_end
	inc si
got_last_arg:
	mov bl,1
found_arg_end:
	xor al,al
	mov [si - 1],al		; convert arg to ASCIZ (0-terminated)
	dec bl
	jne skip_spaces
no_args:

; CONVERT ARGS TO LOWER CASE
	mov bl,10
	mov di,args
smash1:
	mov si,[di]
	add di,2
	or si,si
	je smash2
	call strlwr
	dec bl
	jne smash1
smash2:

; COMPARE ARGS
	mov di,[args + 0]

	or di,di
	je test_a20

	mov si,on_string
	call strcmp
	je enable

	mov si,off_string
	call strcmp
	je disable

	mov si,usage_msg
	jmp short msg_and_exit

enable:
; ENABLE A20
	call enable_a20
	jmp short test_a20

disable:
; DISABLE A20
	call disable_a20

test_a20:
; SHOW A20 STATE
	mov si,on_msg
	call verify_a20
	jne msg_and_exit
	mov si,off_msg
msg_and_exit:
	call cputs
	mov ax,4C00h		; exit to DOS
	int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			enable_a20
; action:		tries to enable A20 using various methods
; in:			[xms], [xms_entry], and [fast] must be set
; out (A20 enabled):	ZF=0
; out (A20 NOT enabled):ZF=1
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

enable_a20:
	push bx
	push ax

; is it already enabled?
		call verify_a20
		jne ea4

		mov ah,1	; enable gate

		xor al,al
		or al,[xms]
		je ea1

; use XMS to enable A20
		call set_a20_xms
		jmp short ea3
ea1:
		or al,[fast]
		je ea2

; use 'fast' method (port 92h)
		call set_a20_fast
		call verify_a20
		jne ea4
ea2:
; use 'PS/2' method
		call set_a20_ps2
		call verify_a20
		jne ea4

; use 'AT' method
		call set_a20_at
		call verify_a20
		jne ea4

; use 'Vectra' method. This makes Bochs panic
		call set_a20_vectra
ea3:
		call verify_a20
ea4:
	pop ax
	pop bx
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			disable_a20
; action:		tries to disable A20 using various methods
; in:			[xms], [xms_entry], and [fast] must be set
; out (A20 enabled):	ZF=0
; out (A20 NOT enabled):ZF=1
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

disable_a20:
	push bx
	push ax

; is it already disabled?
		call verify_a20
		je da4

		mov ah,0	; disable gate

		xor al,al
		or al,[xms]
		je da1

; use XMS to disable A20
		call set_a20_xms
		jmp short da3
da1:
		or al,[fast]
		je da2

; use 'fast' method (port 92h)
		call set_a20_fast
		call verify_a20
		je da4
da2:
; use 'PS/2' method
		call set_a20_ps2
		call verify_a20
		je da4

; use 'AT' method
		call set_a20_at
		call verify_a20
		je da4

; use 'Vectra' method. This makes Bochs panic
		call set_a20_vectra
da3:
		call verify_a20
da4:
	pop ax
	pop bx
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			set_a20_xms
; action:		enables/disables A20 using XMS (HIMEM.SYS)
; in:			AH=0 to disable A20, AH != 0 to enable A20
; out:			(nothing)
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xms_msg:			; DEBUG
	db "Using 'XMS' method...", 13, 10, 0

set_a20_xms:
	push si			; DEBUG
	push bx
	push ax
		mov si,xms_msg	; DEBUG
		call cputs	; DEBUG

		or ah,ah
		jne sax1

; I tried "Global disable/enable A20" (XMS functions 3 and 4)
; bu they didn't work. I'm not sure what the difference is...
		mov ah,6	; "Local disable A20"
		jmp short sax2
sax1:
		mov ah,5	; "Local enable A20"
sax2:
		call far [xms_entry]
		cmp ax,0	; 0=failure, 1=success
	pop ax
	pop bx
	pop si			; DEBUG
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			set_a20_fast
; action:		enables/disables A20 using b1 of I/O port 92h
; in:			AH=0 to disable A20, AH != 0 to enable A20
; out:			(nothing)
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

fast_msg:			; DEBUG
	db "Using 'fast' method...", 13, 10, 0

set_a20_fast:
	push si			; DEBUG
	push ax
		mov si,fast_msg	; DEBUG
		call cputs	; DEBUG

		in al,92h
		or ah,ah
		jne saf1

; chipset bug: do NOT clear b1 if it's already clear
		test al,02h
		je saf3
		and al,0FDh
		jmp short saf2
saf1:
; chipset bug: do NOT set b1 if it's already set
		test al,02h
		jne saf3
		or al,02h
saf2:
		out 92h,al
saf3:
	pop ax
	pop si			; DEBUG
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			set_a20_at
; action:		enables/disables A20 at 8042 output port,
;			using D0h (read output port) and D1h
;			(write output port) command bytes to
;			toggle bit b1 of the output port
; in:			AH=0 to disable A20, AH != 0 to enable A20
; out:			(nothing)
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

at_msg:				; DEBUG
	db "Using 'AT' method...", 13, 10, 0

set_a20_at:
	push si			; DEBUG
	push ax
	pushf
		mov si,at_msg	; DEBUG
		call cputs	; DEBUG

; Yay, feedback! Chase told me it works better if I shut off interrupts:
		cli
		call kbd
		mov al,0D0h	; 8042 command byte to read output port
		out 64h,al
saa1:
		in al,64h
		test al,1	; output buffer (data _from_ keyboard) full?
		jz saa1	; no, loop

		in al,60h	; read output port
		or ah,ah
		jne saa2
		and al,0FDh	; AND ~2 to disable
		jmp saa3
saa2:
		or al,2		; OR 2 to enable
saa3:
		mov ah,al

		call kbd
		mov al,0D1h	; 8042 command byte to write output port
		out 64h,al

		call kbd
		mov al,ah	; the value to write
		out 60h,al

		call kbd
	popf
	pop ax
	pop si			; DEBUG
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			set_a20_vectra
; action:		enables/disables A20 at 8042 output port,
;			using DFh command byte/DDh command byte
; in:			AH=0 to disable A20, AH != 0 to enable A20
; out:			(nothing)
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

vectra_msg:			; DEBUG
	db "Using 'Vectra' method...", 13, 10, 0

set_a20_vectra:
	push si			; DEBUG
	push ax
	pushf
		mov si,vectra_msg ; DEBUG
		call cputs	; DEBUG

		cli
		call kbd
		or ah,ah
		jne sav1
		mov al,0DDh	; disable
		jmp short sav2
sav1:
		mov al,0DFh	; enable
sav2:
		out 64h,al

		call kbd
	popf
	pop ax
	pop si			; DEBUG
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			set_a20_ps2
; action:		enables/disables A20 using INT 15h AX=2400h/2401h
; in:			AH=0 to disable A20, AH != 0 to enable A20
; out:			(nothing)
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ps2_msg:			; DEBUG
	db "Using 'PS/2' method...", 13, 10, 0

set_a20_ps2:
	push si			; DEBUG
	push ax
		mov si,ps2_msg	; DEBUG
		call cputs	; DEBUG

		or ah,ah
		jne sap1
		mov ax,2400h	; disable
		jmp short sap2
sap1:
		mov ax,2401h	; enable
sap2:
		int 15h
	pop ax
	pop si			; DEBUG
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			kbd
; action:		waits until 8042 keyboard controller ready
;			to accept a command or data byte
; modifies:		AL
; out:			(nothing)
; modifies:		(nothing)
; minimum CPU:		'286 for 8042 chip
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

kbd0:
	jmp short $+2	; a delay (probably not effective nor necessary)
	in al,60h	; read and discard data/status from 8042
kbd:
	jmp short $+2	; delay
	in al,64h
	test al,1	; output buffer (data _from_ keyboard) full?
	jnz kbd0	; yes, read and discard
	test al,2	; input buffer (data _to_ keyboard) empty?
	jnz kbd		; no, loop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:			verify_a20
; action:		tests if A20 enabled
; in:			(nothing)
; out (A20 enabled):	ZF=0
; out (A20 NOT enabled):ZF=1
; modifies:		(nothing)
; minimum CPU:		'286 for A20 gate
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

verify_a20:
	push ax
	push ds
	push es
		xor ax,ax
		mov ds,ax
		dec ax
		mov es,ax

		mov ax,[es:10h]		; read word at FFFF:0010 (1 meg)
		not ax			; 1's complement
		push word [0]		; save word at 0000:0000 (0)
			mov [0],ax	; word at 0 = ~(word at 1 meg)
			mov ax,[0]	; read it back
			cmp ax,[es:10h]	; fail if word at 0 == word at 1 meg
		pop word [0]
	pop es
	pop ds
	pop ax
	ret		; if ZF=1, the A20 gate is NOT enabled

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:		strcmp
; action:	compares 0-terminated strings
; in:		strings at SI and DI
; out (equal):	ZF=1
; out (not):	ZF=0
; modifies:	(nothing)
; minimum CPU:	8088
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

strcmp:
	push di
	push si
	push ax
		jmp strcmp2
strcmp1:
		inc si
		inc di
strcmp2:
		mov al,[si]
		cmp al,[di]
		jne strcmp3
		or al,al
		jne strcmp1
strcmp3:
	pop ax
	pop si
	pop di
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:		strlwr
; action:	converts 0-terminated string to lower case
; in:		SI->string
; out:		(nothing)
; modifies:	(nothing)
; minimum CPU:	8088
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

strlwr:
	push si
	push ax
		jmp short strlwr3
strlwr1:
		cmp al,'A'
		jb strlwr2
		cmp al,'Z'
		ja strlwr2
		add al,20h
		mov [si],al
strlwr2:
		inc si
strlwr3:
		mov al,[si]
		or al,al
		jne strlwr1
	pop ax
	pop si
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; name:		cputs
; action:	writes 0-terminated string to screen
; in:		SI -> string
; out:		(nothing)
; modifies:	(nothing)
; minimum CPU:	8088
; notes:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cputs:
	push si
	push bx
	push ax
		cld			; string operations go up
		mov ah,0Eh		; INT 10h: teletype output
		xor bx,bx		; video page 0
		jmp short cputs2
cputs1:
		int 10h
cputs2:
		lodsb
		or al,al
		jne cputs1
	pop ax
	pop bx
	pop si
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

got_xms:
	db "XMS detected", 13, 10, 0	; DEBUG
got_fast:
	db "BIOS says 'fast' A20 is supported", 13, 10	; DEBUG

xms:
	db 0
xms_entry:
	dw 0, 0
fast:
	db 0
args:
	times 10 dw 0
usage_msg:
	db "Say 'a20', 'a20 on', or 'a20 off'", 13, 10, 0
on_msg:
	db "A20 gate is on (enabled)", 13, 10, 0
off_msg:
	db "A20 gate is DISABLED (off)", 13, 10, 0
on_string:
	db "on", 0
off_string:
	db "off", 0
