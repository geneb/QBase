;----- QPrint2.Asm - quick printing routine like QPrint, but leaves attribute byte intact

;Copyright (c) 1987 Ethan Winer

;Syntax - Locate V, H : Call QPrint2(X$)
;where X$ will be printed quickly at V, H


Code            Segment Byte Public 'Code'
                Assume  CS:Code
                Public  QPrint2

QPrint2         Proc    Far

Begin:          Mov   AH,3               ;specify BIOS service to read the current cursor position
                Mov   BH,0               ;specify text page zero
                Int   10h                ;this service returns with the row/column in DH/DL

                Mov   AL,DH              ;put the current row number into AL
                Mov   CL,160             ;muliply it times 160 to get base address of current row
                Mul   CL                 ;do the multiplication - answer ends up in AX
                Xor   DH,DH              ;clear DH for Add below, we only want DL
                Add   AX,DX              ;once for the character byte
                Add   AX,DX              ;and once for the attribute byte
                Mov   DI,AX              ;DI now holds starting memory position on the display screen

                Mov   DX,0               ;DX will tell us later whether to wait for a CGA retrace
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
                Push  BP                 ;save BP for BASIC
                Mov   BP,SP              ;find start of stack
                Mov   SI,[BP+06]         ;put descriptor to X$ into SI
                Mov   CX,[SI]            ;put Len(X$) into CX for loop counter
                Cmp   CX,0               ;is this a null string?
                JZ    Exit               ;yes, get out now
                Mov   SI,[SI+02]         ;put address of first character in X$ into SI
                Cld                      ;all string moves below will be in the forward direction
                Cmp   DL,0               ;are we doing monochrome or EGA?
                JZ    Mono               ;yes, go do it

No_Retrace:     In    AL,DX              ;get the video status byte
                Test  AL,1               ;test just the horizontal retrace bit
                JNZ   No_Retrace         ;if doing a retrace, wait until it's not
Retrace:        In    AL,DX              ;get the status byte again
                Test  AL,1               ;are we currently doing a retrace?
                JZ    Retrace            ;no wait until we are

                Lodsb                    ;get the current character from X$ and increment SI by 1
                Stosb                    ;store the character into screen memory and increment DI by 1
                Inc   DI                 ;increment one more to skip over the attribute byte
                Loop  No_Retrace         ;until done
                Jmp   Exit

Mono:           Lodsb                    ;get the current character from X$
                Stosb                    ;store the character into screen memory
                Inc   DI                 ;increment one more to skip over the attribute byte
                Loop  Mono               ;until done CX times

Exit:           Pop   BP                 ;restore BP for BASIC
                Ret   2                  ;return skipping the passed parameters

Qprint2         Endp
Code            Ends
                End   Begin
