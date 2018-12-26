;----- Mem2Scrn.Asm - copies data from a far array into screen memory

;Copyright (c) 1987 by Ethan Winer

;Syntax - Call Mem2Scrn(FromSeg%, FromAddr%, ToAddr%, Count%, Direction%)

;Where FromSeg% and FromAddr% show where the far array is located, ToAddr%
;is the offset into the screen memory to begin copying to (the program
;determines the segment automatically), Count% is the number of words to
;copy, and Direction% indicates in which direction the copy occur.


Code            Segment Byte Public 'Code'
                Assume  CS:Code
                Public  Mem2Scrn

Mem2Scrn        Proc    Far

Begin:          Mov   DX,0               ;DX will tell us later whether to wait for a CGA retrace
                Mov   ES,DX              ;look at page zero through ES
                Mov   BX,0B000h          ;assume mono screen segment initially
                Mov   AL,ES:[410h]       ;get equipment list
                And   AL,30h             ;just look at the monitor type
                Cmp   AL,30h             ;is it mono?
                JZ    Get_Params         ;yes, skip over adding 800h
                Add   BX,800h            ;no, adjust to point to color screen memory

                Mov   AL,ES:[487h]       ;if an EGA is installed, this byte will be non-zero
                Cmp   AL,0               ;is it an EGA?
                JNZ   Get_Params         ;yes, leave DX set to zero
                Mov   DX,3DAh            ;no, specify the port to check for retrace, while indicating a CGA

Get_Params:     Mov   ES,BX              ;set ES to point to the appropriate screen segment
                Push  BP                 ;save BP and DS for BASIC
                Push  DS
                Mov   BP,SP              ;find start of stack
                Cld                      ;set forward direction for now
                Mov   SI,[BP+08]         ;get the direction flag
                Cmp   Word Ptr [SI],0    ;is it indeed forward (0)?
                JZ    Forward            ;yup
                Std                      ;nope
Forward:        Mov   SI,[BP+10]         ;get the count that was passed
                Mov   CX,[SI]            ;put it into CX
                Mov   SI,[BP+12]         ;get the To address
                Mov   DI,[SI]            ;put it into DI
                Mov   SI,[BP+14]         ;get the From address
                Mov   SI,[SI]            ;put it into SI
                Mov   BX,[BP+16]         ;get the From segment
                Mov   DS,[BX]            ;make that the current Data Segment

                Cld                      ;all moves below will be forward
                Cmp   DL,0               ;are we doing monochrome or EGA?
                JZ    Mono               ;yes, go do it

No_Retrace:     In    AL,DX              ;get the video status byte
                Test  AL,1               ;test just the horizontal retrace bit
                JNZ   No_Retrace         ;if doing a retrace, wait until it's not
Retrace:        In    AL,DX              ;get the status byte again
                Test  AL,1               ;are we currently doing a retrace?
                JZ    Retrace            ;no wait until we are
                Lodsw                    ;get the current word from the array
                Stosw                    ;store it in screen memory
                Loop  No_Retrace         ;until done
                Jmp   Exit

Mono:           Rep   Movsw              ;do it in one shot

Exit:           Pop   DS                 ;restore BP and DS
                Pop   BP
                Ret   10                 ;return skipping the passed parameters

Mem2Scrn        Endp
Code            Ends
                End   Begin
