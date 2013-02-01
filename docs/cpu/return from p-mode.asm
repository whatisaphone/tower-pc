;---------------------------------------------------------------
; ELEGANT_RESET:  This is the elegant '286 RESET.  This code can
;                 be used on both '286, and '386 CPU's.  The
;                 '286 will be reset more efficiently than using
;                 the KBC, while the '386 exits protected mode
;                 in its native manner -- without being reset.
;
; !!! WARNING !!! This is NOT a subroutine.  This code should
;                 be placed in-line with other source code.  It
;                 should NOT be CALLed as a subroutine.
;                 
; !!! WARNING !!! It is assumed that when this is executed on a 
;                 '286, the programmer has programmed the CMOS  
;                 shutdown byte (offset 0F), and set the 
;                 appropriate FAR JMP address at 40:67.
;---------------------------------------------------------------
; Since the 286 doesn't give us a way out of protected mode, we
; need to reset the CPU.  The standard method for resetting the
; CPU is issuing a command to the keyboard controller, that
; yanks on the CPU RESET line.  But this method is very slow.
; A much faster way to reset the CPU is to load the CPU with an
; invalid interrupt descriptor table value (one whose LIMIT=0...
; thus telling the CPU we can't service ANY interrupts), and
; then generate an interrupt.  If the CPU faults during the
; inception of an interrupt routine, the CPU issues a DOUBLE
; FAULT interrupt (INT08).  If the CPU again faults during the
; inception of INT08, then it TRIPLE FAULTS, and enters a
; shutdown cycle, and RESET itself.  This method is about 33%
; faster than issuing a command to the KBC.
;---------------------------------------------------------------
; Prepare to TRIPLE-FAULT the 286 by setting the limit portion
; of the IDTR=0.  Then generate an interrupt.  This will cause
; the 286 to triple-fault, thus resetting itself.  Execution
; will resume @ F000:FFF0.
;---------------------------------------------------------------
        lidt    fword ptr CS:HOSE_IDTR  ; Limit=0 (illegal)

;---------------------------------------------------------------
; Now, if we are a '286, the next instruction will cause an 
; invalid op code exception (INT 06), because the '286 doesn't
; have a MOV EAX... instruction.  This exception won't be able
; to execute because IDTR is hosed, which will then cause a
; DOUBLE FAULT.  Again, since IDTR is hosed, the CPU can't    
; invoke the DOUBLE FAULT exception, which in turn generates 
; the desired TRIPLE FAULT.  The external hardware recognizes
; TRIPLE FAULT, and resets the system.  If we are a '386, then
; MOV EAX,CR0 will execute just fine, and we can begin the 
; process of exiting protected mode.
;---------------------------------------------------------------
        mov     eax,cr0         ; get CPU control register
                                ; The 286 will resume execution
                                ;   @ F000:FFF0, but the 386
                                ;   will fall through.
        lidt    fword ptr CS:Reset_IDTR ; restore w/ real-mode
                                ;   compatible value.  We MUST
                                ;   do this because real-mode
                                ;   interrupts are relocatable
                                ;   on the 386 via the IDT
                                ;   register!
        and     al,not 1        ; clear protected mode bit
	mov	cr0,eax 	; now, we are out of prot mode
	FarJMP	<@RM>,<seg CSEG>; Flush prefetch queue.

        Reset_IDTR      label   fword
                        dw      400h - 1
        Hose_IDTR       df      0
@RM:                            ; Execution continues here.
 
