;********** Wind.Asm - Window manager

;Copyright (c) 1986 by Ethan Winer

;Syntax -  Call Wind(UL.Row%, UL.Col%, LR.Row%, LR.Col%, Param%)
                      1-25     1-80     1-25     1-80    0-281

;to clear window:        Param% = 0
;to scroll X lines up:   Param% = X
;to scroll X lines down: Param% = 256 + X


Code       Segment Byte Public 'Code'
           Assume  CS:Code
           Public  Wind

Wind       Proc Far

Begin:     Push BP
           Mov  BP,SP

           Mov  SI,[BP+14]          ;UL.Row%
           Mov  CH,[SI]
           Dec  CH                  ;Adjust 1-25  -->  0-24

           Mov  SI,[BP+12]          ;UL.Col%
           Mov  CL,[SI]
           Dec  CL

           Mov  SI,[BP+10]          ;LR.Row%
           Mov  DH,[SI]
           Dec  DH

           Mov  SI,[BP+08]          ;LR.Col%
           Mov  DL,[SI]
           Dec  DL

           Mov  SI,[BP+06]          ;Param%
           Mov  AX,[SI]
           Add  AX,0600h            ;adjust to simplify BASIC Calling

           Mov  BH,07
           Int  10h

           Pop  BP
           Ret  10

Wind       Endp
Code       Ends
           End   Begin
