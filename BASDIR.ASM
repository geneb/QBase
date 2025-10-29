;----- BasDir.Asm - retrieves directory information into a BASIC string array

; Copyright (c) 1987 Ethan Winer
; Released to the Public Domain on 10/26/18.

;Syntax - File.Name$(0) = "*.*" : Call BasDir(File.Name$(0))
;   where File.Name$(0) holds the file specification, and subsequent elements receive the directory entries



Data            Segment Word Public 'Data'

DTA             DB      44 Dup (?)     ;Disk Data Transfer Area
File_Spec       DB      65 Dup (?)     ;holds copy of File.Name$(0) file spec to add Chr$(0) locally

Data            Ends

DGroup          Group   Data

Code            Segment Byte Public 'Code'
                Assume  CS:Code, DS:DGroup, ES:DGroup
                Public  BasDir

BasDir          Proc    Far

Begin:          Push BP               ;save BP
                Push DS
                Pop  ES               ;insure that ES holds Data Segment
                Lea  DX,DTA           ;put address of DTA into DS:DX for set DTA service below
                Mov  BX,DX            ;and into BX for Move_Chars
                Add  BX,30            ;point to start of file name area in DTA

                Mov  AH,1Ah           ;set DTA service - creates space where each file name will be put by DOS
                Int  21h

                Mov  BP,SP            ;get Stack Pointer so we can locate the address of File.Name$(0)
                Mov  SI,[BP+06]       ;SI holds address of File.Name$(0) descriptor (search string)
                Mov  CX,[SI]          ;put Len(File.Name$(0)) into CX to copy it into local storage
                Push SI               ;save address of File.Name$(0) so we can find successive elements later
                Mov  SI,[SI+02]       ;point Source Index to first character in File.Name$(0)
                Lea  DI,File_Spec     ;point Destination Index to beginning of local storage
                Cld                   ;prepare to move bytes in the forward direction
                Rep  Movsb            ;move CX bytes
                Mov  Byte Ptr [DI],0  ;make an ASCIIZ string by adding a Chr$(0) to the end of File.Name$(0)
                Lea  DX,File_Spec     ;Find_First expects search string in DS:DX
                Pop  BP               ;retrieve address of File.Name$(0) descriptor - was SI when pushed

                Mov  AH,4Eh           ;find first matching file name service
Find_File:      Mov  CX,0             ;specify search to include only "normal" files (not hidden, system, subdirectories, etc.)
                Int  21h              ;call DOS
                JC   Exit             ;no more files (or invalid file name)

                Add  BP,4             ;now BP holds address of next File.Name$() descriptor
                Mov  DI,[BP+02]       ;Destination Index holds address of first character in that File.Name$()
                Mov  SI,BX            ;Source Index now points to file name area in DTA
                Mov  CX,12            ;CX will keep track of how many characters are transferred from DTA to File.Name$()
Move_Chars:     Lodsb                 ;get character in file name from DTA
                Test AL,AL            ;is it a Chr$(0) indicating the end of this name?
                JZ   Pad_Spc          ;yes, fill remainder of File.Name$() with spaces and continue on to the next file name
                Stosb                 ;no, put it into File.Name$()
                Dec  CX               ;show that another character was placed into File.Name$()
                Jmp  Move_Chars       ;continue

Pad_Spc:        Mov  AL,32            ;prepare to fill remainder of File.Name$ with blanks (to clear any previous names)
                Rep  Stosb            ;the count remaining in CX specifies how many blanks to move into File.Name$
                Mov  AH,4Fh           ;find next matching file name service
                Jmp  Find_File

Exit:           Add  BP,4             ;BP holds address of the next descriptor in File.Name$()
                Mov  DI,[BP+02]       ;DI holds address of first character in next File.Name$() element
                Mov  Byte Ptr [DI],0  ;show that there are no more files - put a Chr$(0) into first character of next element

                Pop  BP               ;restore BP for BASIC
                Ret  2                ;exit, discarding the passed parameter

BasDir          Endp

Code            Ends
                End  Begin

