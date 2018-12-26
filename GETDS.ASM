;----- GetDS.Asm - retrieves QuickBASIC's data segment

;Copyright (c) 1986 by Ethan Winer

;Syntax - Call GetDS(DS%) : Print "QuickBASIC's data segment is" DS%


Code            Segment Byte Public 'Code'
                Assume  CS:Code
                Public  GetDS
GetDS           Proc Far

Begin:          Push BP                 ;save BP
                Mov  BP,SP              ;put address of stack into BP
                Mov  SI,[BP+06]         ;put address of DS% into SI

                Push DS                 ;put the segment on the stack
                Pop  AX                 ;retrieve it in AX
                Mov  [SI],AX            ;put it into DS%

                Pop  BP                 ;restore BP
                Ret  2                  ;return to BASIC

GetDS           Endp
Code            Ends
                End  Begin
