;********** Extents.Asm - finds starting address and length of active portion of the screen

;Copyright (c) 1987 by Ethan Winer

;Syntax - Call Extents(Start.Addr%, Length.Bytes%)


Code       Segment Byte Public 'Code'
           Assume  CS:Code
           Public  Extents

Extents    Proc Far

Begin:     Push BP                  ;save BP for BASIC
           Mov  BP,SP

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

Mono_EGA1: Mov  DL,0                ;use DL as a flag to show that we're not on a CGA

Continue:  Mov  DI,[BP+06]          ;save address of Length.Bytes% in DI
           Mov  BX,[BP+08]          ;save address of Start.Address% in BX
           Mov  CX,DS               ;save DS in CX
           Mov  DS,AX               ;put the screen segment into DS

           Cld                      ;set direction to forward for now
           Mov  SI,0                ;we'll start by scanning for the first non-blank

Forward:   Cmp  DL,0                ;are we doing a mono or EGA screen?
           JZ   Mono_EGA2           ;yes, skip over retrace stuff

R1:        In   AL,DX               ;wait until not doing a horizontal retrace
           Test AL,1
           JNZ  R1
R2:        In   AL,DX               ;now wait until a retrace just begins
           Test AL,1                ;to avoid snow on a CGA screen
           JZ   R2

Mono_EGA2: Lodsw                    ;get the character and attribute from the screen
           Cmp  SI,4000             ;did we reach the end of the screen?
           JB   CoolSoFar           ;nah, we're cool so far
           Mov  AX,0                ;yup, set up the registers such that both BASIC variables will be set to zero
           Mov  SI,-4
           Mov  DS,CX               ;restore DS from CX
           Jmp  Cls                 ;and get outa here

CoolSoFar: Cmp  AL,32               ;looking at the character only, is it a blank space?
           JZ   Forward             ;yes, keep looking
           Sub  SI,2                ;a fudge factor because of the order in which SI is automatically incremented by Lodsw
           Push SI                  ;save the starting address now in SI on the stack for the moment

           Std                      ;the rest of our scanning will be backwards from the bottom of the screen
           Mov  SI,3998             ;starting at the bottom of the screen

Backward:  Cmp  DL,0                ;mono or EGA?
           JZ   Mono_EGA3           ;yes

R3:        In   AL,DX
           Test AL,1
           JNZ  R3
R4:        In   AL,DX
           Test AL,1
           JZ   R4

Mono_EGA3: Lodsw                    ;pretty much as above
           Cmp  AL,32
           JZ   Backward

           Mov  DS,CX               ;get DS back from CX
           Pop  AX                  ;retrieve the starting address from the stack
Cls:       Mov  [BX],AX             ;assign Start.Address% = AX
           Sub  SI,AX               ;subtract the start from the end to calculate the length
           Add  SI,4                ;another inevitable fudge factor
           Mov  [DI],SI             ;assign Length.Bytes% = SI

           Pop  BP                  ;restore BP
           Ret  4

Extents    Endp
Code       Ends
           End
