;----- PrtSc.Asm - Calls the Print Screen Interrupt from within BASIC

;Copyright (c) 1986 by Ethan Winer

;Syntax - Call PrtSc

Code            Segment Byte Public 'Code'
                Assume  CS:Code
                Public  PrtSc

PrtSc           Proc Far

Begin:          Int  5                  ;call PrtSc routine in BIOS
                Ret                     ;return to BASIC

PrtSc           Endp
Code            Ends
                End  Begin
