;----- FCount.Asm - counts the number of files matching a particular spec

;Copyright (c) 1986 by Ethan Winer

;Syntax - Call FCount(File.Spec$, Count%)
;where File.Spec$ holds the file specification, and Count% returns with the number of files that match



Data            Segment Word Public 'Data'

DTA             DB      44 Dup (?)     ;Disk Data Transfer Area
File_Spec       DB      65 Dup (?)     ;holds copy of File.Spec$ to add Chr$(0) locally

Data            Ends

DGroup          Group   Data

Code            Segment Byte Public 'Code'
                Assume  CS:Code, DS:DGroup, ES:DGroup
                Public  FCount

FCount          Proc    Far

Begin:          Push BP               ;save BP
                Push DS
                Pop  ES               ;insure that ES holds Data Segment
                Lea  DX,DTA           ;put address of DTA into DS:DX for set DTA service below

                Mov  AH,1Ah           ;set DTA service - creates space where each file name will be put by DOS
                Int  21h

                Mov  BP,SP            ;get Stack Pointer so we can locate the address of File.Spec$
                Mov  SI,[BP+08]       ;SI holds address of File.Spec$ descriptor
                Mov  CX,[SI]          ;put Len(File.Spec$) into CX to copy it into local storage
                Mov  SI,[SI+02]       ;point Source Index to first character in File.Spec$
                Lea  DI,File_Spec     ;point Destination Index to beginning of local storage
                Cld                   ;prepare to move bytes in the forward direction
                Rep  Movsb            ;move CX bytes
                Mov  Byte Ptr [DI],0  ;make an ASCIIZ string by adding a Chr$(0) to the end of File.Spec$

                Lea  DX,File_Spec     ;Find_First expects search string in DS:DX
                Mov  BP,[BP+06]       ;put address of Count% into BP
                Mov  Word Ptr [BP],0  ;set Count% to zero initially

                Mov  AH,4Eh           ;find first matching file name service
Find_File:      Mov  CX,0             ;specify search to include only "normal" files (not hidden, system, subdirectories, etc.)
                Int  21h              ;call DOS
                JC   Exit             ;an error occured, DOS must be telling us there's no matching files

                Inc  Word Ptr [BP]    ;we found one, show Count% as being one higher
                Mov  AH,4Fh           ;find next matching file name service
                Jmp  Find_File        ;keep looking

Exit:           Pop  BP               ;restore BP for BASIC
                Ret  4                ;exit, discarding the passed parameters

FCount          Endp
Code            Ends
                End  Begin
