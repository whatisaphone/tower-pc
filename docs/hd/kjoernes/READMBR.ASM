;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;
; Description   :  OS Theory - Read MBR using INT13
; Author        :  Thomas Kjoernes (thomas_kjoernes@hotmail.com)
; Date          :  20th September 1999
;
; Assemble      :  tasm readmbr
; Link          :  tlink readmbr
; Comment       :  produces a DOS executable file
;                  - run the program in a debugger and watch the "buffer"
;
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

CODE            SEGMENT

                ASSUME  CS:CODE

                PUSH    CS              ; Our MBR buffer is in
                POP     ES              ; the code segment too!

                MOV     AX,0201H        ; READ - 1 sector
                MOV     BX,OFFSET Buffer; Point BX to buffer
                MOV     CX,0001H        ; Cylinder 0, Sector 1
                MOV     DX,0080H        ; Head 0, Drive 80H
                INT     13H             ; Do it!

                MOV     AX,4C00H        ; DOS - Terminate
                INT     21H

Buffer          DB      512 DUP (?)     ; 512-byte sector buffer

CODE            ENDS

                END

