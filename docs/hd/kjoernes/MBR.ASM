;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;
; Description   :  OS Theory - MBR replacement
; Author        :  "The Bass Demon"
; Date          :  5. September 1998
;
; Assemble      :  tasm mbr
; Link          :  tlink mbr
; Comment       :  produces a DOS executable file
;
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

CODE            SEGMENT

                ASSUME  CS:CODE

                XOR     AX,AX           ; DS=ES=SS=AX=0
                MOV     DS,AX           ; 
                MOV     ES,AX
                MOV     SS,AX
                MOV     SP,7C00H        ; Stack at 0000:7C00
                MOV     SI,SP           
                MOV     DI,0600H        
                MOV     CX,256          ; copy 256 WORDs from
                CLD                     
                REP     MOVSW           ; 0000:7C00 to 0000:0600

                DB      0EAH            ; insert opcode for FAR JMP

                DW      OFFSET NewLoc   ; point to instrcution after JMP
                DW      0060H           ; segment 0060
NewLoc:
        ; at this point, the processor's CS:IP is 0060:NewLoc

                PUSH    CS              ; DS=CS=0060
                POP     DS

                MOV     SI,OFFSET PTable; point to Partition Table
                MOV     BL,4            ; check "four" entries
CheckNext:
                TEST    BYTE PTR [SI],80H ; test for "active"
                JNZ     LoadIt          ; OK, load the boot sector

                ADD     SI,16           ; skip to next entry
                DEC     BL              ; decrement entry counter
                JNZ     CheckNext       ; if non-zero, check next entry

                INT     18H             ; if none of the entries were
                                        ; "active", try ROM BASIC.
LoadIt:
                MOV     BX,7C00H        ; ES:BX -> 0000:7C00H

                PUSH    ES              ; push the addres on the stack
                PUSH    BX              ; for later use by RETF

                MOV     AX,0201H        ; READ - 1 sector
                MOV     CX,[SI][2]      ; cylinder/sector at BYTE 2 and 3
                MOV     DX,[SI]         ; drive/head at BYTE 0 and 1
                INT     13H             ; read it...

                RETF                    ; "return" to 0000:7C00

                ORG     512 - 64 - 2

PTable          DB      64 DUP (?)

                DW      0AA55H
ReplaceIt:
                PUSH    CS
                POP     DS

                PUSH    CS              ; Our MBR buffer is in
                POP     ES              ; the code segment too!

                MOV     AX,0201H        ; READ - 1 sector
                MOV     BX,OFFSET Buffer; Point BX to buffer
                MOV     CX,0001H        ; Cylinder 0, Sector 1
                MOV     DX,0080H        ; Head 0, Drive 80H
                INT     13H             ; Do it!

                MOV     SI,OFFSET Buffer + 512 - 64 - 2
                MOV     DI,512 - 64 - 2
                MOV     CX,32
                CLD
                REP     MOVSW

                MOV     AX,0301H        ; WRITE - 1 sector
                XOR     BX,BX           ; Point BX to our new MBR
                MOV     CX,0001H        ; Cylinder 0, Sector 1
                MOV     DX,0080H        ; Head 0, Drive 80H
                INT     13H             ; Do it!

                MOV     AX,4C00H        ; DOS - Terminate
                INT     21H

Buffer          DB      512 DUP (?)     ; 512-byte sector buffer

CODE            ENDS

                END     ReplaceIt

