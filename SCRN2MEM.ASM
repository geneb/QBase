;----- Scrn2Mem.Asm - copies data from screen memory to a far array

;Copyright (c) 1987 by Ethan Winer

;Syntax - Call Scrn2Mem(FromAddr%, ToSeg%, ToAddr%, Count%, Direction%)

;See the comments in Mem2Scrn.Asm for the meaning of these variables.


Code            Segment Byte Public 'Code'
                Assume  CS:Code
                Public  Scrn2Mem

Scrn2Mem        Proc    Far

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

Get_Params:     Push  BP                 ;save BP and DS for BASIC
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
                Mov   SI,[BP+14]         ;get the To segment
                Mov   ES,[SI]            ;put it into ES
                Mov   SI,[BP+16]         ;get the From address
                Mov   SI,[SI]            ;put it into SI
                Mov   DS,BX              ;make DS the current screen segment

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

Scrn2Mem        Endp
Code            Ends
                End   Begin
