;----- GetDir.Asm - retrieves current directory

;Copyright (c) 1986 by Ethan Winer

;Syntax - Dir$ = Space$(64) : Drive$ = "A" : Call GetDir(Drive$, Dir$)
;where Dir$ receives the returned path,
;      and Drive$ = "" for the default drive, or "A" or "a" or "B", etc.

Code            Segment Byte Public 'Code'
                Assume  CS:Code
                Public  GetDir

GetDir          Proc    Far

Begin:          Push BP
                Mov  BP,SP

                Mov  SI,[BP+06]       ;SI holds address of Dir$ descriptor
                Cmp  Word Ptr [SI],64 ;is Dir$ long enough to hold returned information?
                JB   Exit             ;no, get out now!
                Mov  SI,[SI+02]       ;yes, point SI to first character in Dir$ for DOS service 47h below

                Mov  DI,[BP+08]       ;put address of Drive$ into DI
                Mov  DX,[DI]          ;put Len(Drive$) into DX
                Cmp  DX,0             ;null indicating default drive?
                JZ   Do_It            ;yes, leave DL holding 0 and call DOS

                Mov  DI,[DI+02]       ;put address of first character in Drive$ into DI
                Mov  DL,[DI]          ;put Asc(Drive$) into DL

                Cmp  DL,'a'           ;is it less than "a"?
                JB   Continue         ;yes, skip
                Sub  DL,32            ;no, convert to upper case

Continue:       Sub  DL,64            ;"A" now equals 1, "B" = 2, etc.

Do_It:          Mov  AH,47h           ;get current directory service
                Int  21h              ;call DOS

Exit:           Pop  BP
                Ret  4                ;exit, discarding the passed parameters

GetDir          Endp
Code            Ends
                End  Begin
