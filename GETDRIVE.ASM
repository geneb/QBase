;----- GetDrive.Asm - Retrieves the default drive

;Copyright (c) 1986 by Ethan Winer

;Syntax - Call GetDrive(Drive%)
;where Drive$ = Chr$(Drive%)

Code            Segment Byte Public 'Code'
                Assume  CS:Code
                Public  GetDrive

GetDrive        Proc Far

Begin:          Push BP                 ;save BP
                Mov  BP,SP              ;put stack address into BP
                Mov  SI,[BP+06]         ;put Drive% address into SI

                Mov  AH,19h             ;get default drive service
                Int  21h                ;call DOS

                Cbw                     ;throw away AH
                Add  AL,65              ;0 = "A", 1 = "B", etc.
                Mov  [SI],AL            ;assign Drive% = AL

                Pop  BP                 ;retore BP
                Ret  2                  ;return skipping parameters

GetDrive        Endp
Code            Ends
                End  Begin
