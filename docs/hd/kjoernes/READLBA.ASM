;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;
; Description   :  OS Theory - Read sector using LBA
; Author        :  Thomas Kjoernes (thomas_kjoernes@hotmail.com)
; Date          :  20th September 1999
;
; Assemble      :  tasm readmbr
; Link          :  tlink readmbr
; Comment       :  produces a DOS executable file
;                  - you would generally organize this code into
;                    procedures to make it more useable... ;)
;                  - This example program will get the drive parameters,
;                    calculate the number of sectors on the drive, then
;                    divide it by two and read the middle sector.
;
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

CODE            SEGMENT

                ASSUME  CS:CODE, DS:CODE

Start:

                PUSH    CS              ; setup DS so we can access
                POP     DS              ; our codeseg variables without
                                        ; the CS segment override
                PUSH    CS
                POP     ES              ; While we're at it, fix ES too!                

                MOV     AH,08H          ; get drive parameters
                MOV     DL,80H          ; for drive 80H (harddisk1)
                INT     13H

                MOV     AL,DH
                XOR     AH,AH
                INC     AX
                MOV     Heads,AX        ; save head count

                MOV     AL,CL           ; put sector number in AL
                AND     AX,3FH          ; and mask off cylinder bits
                MOV     Sectors,AX      ; save sector count

                MOV     AL,CH           ; AL = cylinder LO
                MOV     AH,CL           ; AH = cylinder HI...
                MOV     CL,6
                SHR     AH,CL           ; shift the HI bits down
                INC     AX
                MOV     Cylinders,AX    ; save cylinder count

                MOV     AX,Sectors      ; multiply "sectors"
                MUL     Heads           ; byte "heads"
                MUL     Cylinders       ; and then by "cylinders"

        ; save total capacity in sectors!

                MOV     WORD PTR Capacity[0],AX
                MOV     WORD PTR Capacity[2],DX

        ; the value in DX:AX is one above the kast LBA sector,
        ; put we don't care about that...  just divide it by two.

                SHR     DX,1    ; DX[0] -> CF
                RCR     AX,1    ; CF -> AX[7], etc...

        ; now, here comes the LBA - CHS routine.

                MOV     BX,AX           ; save LBA LO in BX
                MOV     AX,DX           ; put LBA HI in AX
                XOR     DX,DX           ; clear DX
                DIV     Sectors         ; divide LBA HI by Sectors
                MOV     CX,AX           ; save HI part of result in CX
                MOV     AX,BX           ; restore AX to LBA LO
                DIV     Sectors         ; divide REMINDER:LBA LO by Sectors
                INC     DX              ; make sector one-based
                XCHG    CX,DX           ; swap sector and HI result
                DIV     Heads           ; divide by Heads

        ; after this code, the following is in AX, DX and CX:
        ;
        ;  AX = Cylinder Number
        ;  DX = Head Number
        ;  CX = Sector Number
        ;
        ; The next few lines, will map the values into
        ; the registers as need by INT13

                MOV     CH,AL
                ROR     AH,1
                ROR     AH,1
                OR      CL,AH
                MOV     DH,DL

                MOV     DL,80H          ; force drive 80H

                MOV     BX,OFFSET Buffer

                MOV     AX,0201H        ; READ - 1 sector
                INT     13H

        ; Here's the equivalent 386+ code snippet
        ;
        ; None of these procedures are optimized, they're just
        ; written this way to be easy to understand.
        ;
        ; This code will put "Capacity" into EAX, then calculate
        ; the proper CHS values...
        ;
                .386

                MOV     EAX,Capacity
                SHR     EAX,1

                MOVZX   EBX,Sectors
                XOR     EDX,EDX
                DIV     EBX
                INC     EDX
                MOV     ECX,EDX
                MOVZX   EBX,Heads
                XOR     EDX,EDX
                DIV     EBX

        ; Registers:
        ;
        ;  EAX = Cylinder Number
        ;  EDX = Head Number
        ;  ECX = Sector Number
        ;
        ;
        ; The next few lines, will map the values into
        ; the registers as need by INT13
        ;
        ; Of course, the regs are the same as above, so I just
        ; pasted the code ;)

                MOV     CH,AL
                ROR     AH,1
                ROR     AH,1
                OR      CL,AH
                MOV     DH,DL

                MOV     DL,80H          ; force drive 80H

                MOV     BX,OFFSET Buffer

                MOV     AX,0201H        ; READ - 1 sector
                INT     13H

                MOV     AX,4C00H        ; DOS - Terminate
                INT     21H

Capacity        DD      ?
Cylinders       DW      ?
Heads           DW      ?
Sectors         DW      ?

Buffer          DB      512 DUP (?)     ; 512-byte sector buffer

CODE            ENDS

                END     Start

