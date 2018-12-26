;********** ReadScrn.Asm - reads characters from the screen into a string

;Copyright (c) 1987 Ethan Winer

;to read 15 characters from the screen starting at location 2,50:
;  X$ = Space$(15) : Call ReadScrn(UL.Row%, UL.Col%, X$)


Code       Segment Byte Public 'Code'
           Assume  CS:Code
           Public  ReadScrn

ReadScrn   Proc Far

Begin:     Push BP                  ;save BP for BASIC
           Mov  BP,SP

           Mov  SI,[BP+10]          ;put address of UL.Row% into SI
           Mov  AL,[SI]             ;put UL.Row% into AL
           Dec  AL                  ;adjust 1-25 to 0-24 for calculations below

           Mov  CL,160              ;prepare to multiply AL by 160
           Mul  CL                  ;now AX holds beginning address of upper row in screen memory

           Mov  SI,[BP+08]          ;put address of UL.Col% into SI
           Mov  BX,[SI]             ;put UL.Col% into BX
           Dec  BX                  ;adjust 1-80 to 0-79 for addition below
           Add  AX,BX               ;add column offset to AX to determine actual start address of screen portion to be saved
           Add  AX,BX               ;once more to include the attribute bytes
           Mov  BX,AX               ;save it in BX for later

           Mov  AX,0                ;set ES to 0 through AX to look at the equipment list in low memory
           Mov  ES,AX
           Mov  AX,0B000h           ;set AX to hold mono screen segment initially, we'll add 800h later if color
           Mov  DL,ES:[410h]        ;get equipment list byte - bit coded to indicate monitor type etc.
           And  DL,30h              ;keep only the bits we care about
           Cmp  DL,30h              ;is it mono?
           JZ   Mono_EGA1           ;yes, skip over adding 800h to AX
           Add  AX,800h             ;adjust AX to segment of color screen

           Mov  DL,ES:[487h]        ;if an EGA is installed, this byte will be non-zero
           Cmp  DL,0                ;well is it?
           JNZ  Mono_EGA1           ;yes, skip to the part that puts a 0 in DX to indicate that for later
           Mov  DX,3DAh             ;no, put CGA port to test in DX
           Jmp  Continue            ;skip over zeroing out DX below

Mono_EGA1: Mov  DL,0                ;use DX as a flag to show that we don't have to worry about CGA snow

Continue:  Cld                      ;character moves will be in the forward direction
           Mov  SI,[BP+06]          ;put address of X$ descriptor into SI
           Mov  CX,[SI]             ;put Len(X$) into CX, to determine how many characters to read
           JCXZ Done                ;Oops - somebody forgot to set aside space in X$!
           Mov  DI,[SI+02]          ;put address of X$ into DI
           Mov  SI,BX               ;put start address saved earlier in BX into SI
           Mov  BX,DS               ;make ES QB's current data segment - the "to" segment
           Mov  ES,BX
           Mov  DS,AX               ;put the "from" segment (screen) into DS

           Cmp  DL,0                ;are we doing a mono or EGA screen?
           JZ   Mono_EGA2           ;yes, skip over retrace stuff

Retrace:   In   AL,DX               ;wait until not doing a horizontal retrace
           Test AL,1
           JNZ  Retrace
R2:        In   AL,DX               ;now wait until a retrace just begins
           Test AL,1                ;to avoid snow on a CGA screen
           JZ   R2

           Lodsw
           Stosb
           Loop Retrace
           Jmp  Done

Mono_EGA2: Lodsw                    ;get the character and attribute
           Stosb                    ;and place just the character into X$
           Loop Mono_EGA2           ;'til done

Done:      Mov  DS,BX               ;get DS back from BX
           Pop  BP                  ;restore BP
           Ret  6

ReadScrn   Endp
Code       Ends
           End
