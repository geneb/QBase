;********** PaintBox.Asm - Paints a colored box on the screen without disturbing the text

;Copyright (c) 1986 by Ethan Winer

;Call PaintBox(UL.Row%, UL.Col%, LR.Row%, LR.Col%, Clr%)
;     range:    1-25     1-80     1-25     1-80    0-255


Code       Segment Byte Public 'Code'
           Assume  CS:Code
           Public  PaintBox

PaintBox   Proc Far

Begin:     Push BP                  ;save BP and DS for BASIC
           Mov  BP,SP

           Mov  SI,[BP+14]          ;put address of UL.Row% into SI
           Mov  AL,[SI]             ;put UL.Row% into AL
           Dec  AL                  ;adjust 1-25 to 0-24 for calculations below

           Mov  CL,160              ;prepare to multiply AL by 160
           Mul  CL                  ;now AX holds beginning address of upper row in screen memory

           Mov  SI,[BP+12]          ;put address of UL.Col% into SI
           Mov  BX,[SI]             ;put UL.Col% into BX
           Dec  BX                  ;adjust for addition below
           Add  AX,BX               ;add column offset to AX to determine actual start address of screen portion to be saved
           Add  AX,BX               ;once more to include the attribute bytes
           Mov  BX,AX               ;now BX, which will hold the destination address, is the same as the source address

           Mov  DX,0                ;set ES to 0 through DX to look at the equipment list in low memory
           Mov  ES,DX
           Mov  AX,0B000h           ;set AX to hold mono screen segment initially, we'll add 800h later if color
           Mov  CL,ES:[410h]        ;get equipment list byte - bit coded to indicate monitor type etc.
           And  CL,30h              ;keep only the bits we care about
           Cmp  CL,30h              ;is it mono?
           JZ   Continue            ;yes, skip over adding 800h to AX
           Add  AX,800h             ;adjust AX to segment of color screen

           Mov  CL,ES:[487h]        ;if an EGA is installed, this byte will be non-zero
           Cmp  CL,0                ;is it an EGA?
           JNZ  Continue            ;yes, leave DX set to zero
           Mov  DX,3DAh             ;no, specify the port to check for retrace, and also indicate a CGA for later

Continue:  Mov  SI,[BP+10]          ;put address of LR.Row% into SI
           Mov  CH,[SI]             ;put LR.Row% into CH
           Mov  SI,[BP+14]          ;get address for UL.Row%
           Sub  CH,[SI]             ;subtract it from CH to get the number of rows to be processed
           Inc  CH                  ;add 1 because Number_Of_Rows = (LR.Row% - UL.Row%) + 1

           Mov  SI,[BP+08]          ;put address of LR.Col% into SI
           Mov  CL,[SI]             ;put LR.Col% into CL
           Mov  SI,[BP+12]          ;get address for UL.Col%
           Sub  CL,[SI]             ;subtract it from CL to get the number of columns to do for each row processed
           Inc  CL                  ;add 1 because Number_Of_Columns = (LR.Col% - UL.Col%) + 1

           Mov  ES,AX               ;set ES to point at screen memory
           Mov  SI,[BP+06]          ;get address for Clr%
           Mov  AH,[SI]             ;put the color into AH
           Mov  BP,BX               ;BP will be holding our beginning destination addresses
           Mov  BL,CL               ;save column counter in BL

Next_Row:  Mov  CL,BL               ;retrieve column counter
           Mov  DI,BP               ;point Destination Index to screen

Next_Col:  Cmp  DL,0                ;are we doing a mono or EGA screen?
           JZ   Mono_EGA            ;yes, skip over retrace stuff

R1:        In   AL,DX               ;wait until not doing a retrace
           Test AL,1
           JNZ  R1
R2:        In   AL,DX               ;wait until retrace has just begun
           Test AL,1
           JZ   R2

Mono_EGA:  Inc  DI                  ;skip over the character byte
           Mov  AL,AH               ;move the color into AL for Stosb below
           Stosb                    ;put the color on the screen
           Dec  CL                  ;show that we just did another column
           JNZ  Next_Col            ;still more to do

           Add  BP,160              ;consider the next row down
           Dec  CH                  ;show that we just did another row
           JNZ  Next_Row            ;still more

Done:      Pop  BP                  ;restore BP
           Ret  10

PaintBox   Endp

Code       Ends
           End
