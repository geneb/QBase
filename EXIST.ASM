;----- Exist.Asm - determine if named file exists

;Copyright (c) 1987 Ethan Winer

;Syntax - File.Name$ = "\Path\Filename.Ext"
;         Call Exist(File.Name$, X%) : If X% Then ...
;              where X% = -1 if the file or file spec exists, otherwise X% = 0



Data            Segment Word Public 'Data'

DTA             DB   44 Dup (?)       ;Disk Data Transfer Area
File_Spec       DB   64 Dup (?)       ;holds copy of File.Name$ to add Chr$(0) locally

Data            Ends

DGroup          Group   Data

Code            Segment Byte Public 'Code'
                Assume  CS:Code, DS:DGroup, ES:DGroup
                Public  Exist

Exist           Proc    Far

Begin:          Push BP               ;save BP
                Push DS
                Pop  ES               ;insure that ES holds Data Segment
                Lea  DX,DTA           ;put address of DTA into DS:DX for set DTA service below

                Mov  AH,1Ah           ;set DTA service - creates space where file name info will be put by DOS
                Int  21h              ;call DOS to do it

                Mov  BP,SP            ;get Stack Pointer so we can locate the addresses of File.Name$ and X%
                Mov  BX,[BP+08]       ;BX holds address of File.Name$ descriptor
                Mov  CX,[BX]          ;put Len(File.Name$) into CX to copy File.Name$ into local storage
                Mov  SI,[BX+02]       ;point Source Index to first character in File.Name$
                Lea  DI,File_Spec     ;point Destination Index to beginning of local storage
                Cld                   ;prepare to move bytes in the forward direction
                Rep  Movsb            ;move CX bytes
                Mov  Byte Ptr [DI],0  ;make an ASCIIZ string by adding a Chr$(0) to the end of File.Name$
                Lea  DX,File_Spec     ;Find_First expects the address of search string in DS:DX

                Mov  SI,[BP+06]       ;get address of X% so we can set it depending on whether file exists or not
                Mov  Word Ptr [SI],0  ;set X% = 0 to initially show file as not being there

                                      ;CX is already zero to specify which type of files to search for via attributes
                Mov  AH,4Eh           ;find first matching file name service

                Int  21h              ;call DOS to look for it
                JC   Exit             ;not there, leave X% set to zero
                Dec  Word Ptr [SI]    ;yes, set X% = -1 by decrementing it from zero

Exit:           Pop  BP
                Ret  4                ;exit, discarding the passed parameters

Exist           Endp
Code            Ends
                End  Begin
