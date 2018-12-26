;----- FileInfo.Asm - retrieves full information on the named file

;Copyright (c) 1987 Ethan Winer

;Syntax - Dim Array%(8)
;         File.Name$ = "\Path\Filename.Ext"
;         Call FileInfo(File.Name$, Array%(0))

;where the information is returned in Array% as follows:         year  month day
;                                                               ______  ___  ____
;                                                              /      \/   \/    \
;         Array%(0) = Year    (80 - 99)        Date is packed: 1111 1111 1111 1111
;         Array%(1) = Month   (1 - 12)
;         Array%(2) = Day     (1 - 31)
;         Array%(3) = Hour    (1 - 24)         Time is packed: 1111 1111 1111 1111
;         Array%(4) = Minute  (1 - 60)                         \____/\_____/\____/
;         Array%(5) = Second  (1 - 60)                          hour   min   sec
;         Array%(6) = Size    (lo-word)
;         Array%(7) = Size    (hi-word)
;         Array%(8) = Attribute, bit coded as follows:

;                     if bit 0 = 1 read-only
;                        bit 1 = 1 hidden
;                        bit 2 = 1 system
;                        bit 3 = 1 volume label (not used in this routine)
;                        bit 4 = 1 subdirectory
;                        bit 5 = 1 archive
;                        bit 6 & 7 unused

;if a wildcard (? or *) is used, the first matching file is reported



Data            Segment Word Public 'Data'

DTA             DB   44 Dup (?)       ;Disk Data Transfer Area
File_Spec       DB   65 Dup (?)       ;holds copy of File.Name$ to add Chr$(0) locally

Data            Ends

DGroup          Group   Data

Code            Segment Byte Public 'Code'
                Assume  CS:Code, DS:DGroup, ES:DGroup
                Public  FileInfo

FileInfo        Proc    Far

Begin:          Push BP               ;save BP
                Push DS
                Pop  ES               ;insure that ES holds Data Segment
                Lea  DX,DTA           ;put address of DTA into DS:DX for set DTA service below

                Mov  AH,1Ah           ;set DTA service - creates space where file name info will be put by DOS
                Int  21h              ;call DOS to do it

                Mov  BP,SP            ;get Stack Pointer so we can locate the addresses of File.Name$ and Array%(0)
                Mov  BX,[BP+08]       ;BX holds address of File.Name$ descriptor
                Mov  CX,[BX]          ;put Len(File.Name$) into CX to copy File.Name$ into local storage
                Mov  SI,[BX+02]       ;point Source Index to first character in File.Name$
                Lea  DI,File_Spec     ;point Destination Index to beginning of local storage
                Cld                   ;prepare to move bytes in the forward direction
                Rep  Movsb            ;move CX bytes
                Mov  Byte Ptr [DI],0  ;make an ASCIIZ string by adding a Chr$(0) to the end of File.Name$
                Lea  DX,File_Spec     ;Find_First expects the address of search string in DS:DX

                Mov  SI,[BP+06]       ;get address of Array%(0)
                Mov  Word Ptr [SI],0  ;set Array%(0) = 0 to initially show file as not being there

                Mov  CL,00010110b     ;specify search to include normal files, hidden files, system files, and sub-directories
                Mov  AH,4Eh           ;find first matching file name service
                Int  21h              ;call DOS to look for it
                JC   Exit             ;if the Carry Flag is set then DOS is telling us that it wasn't there
                                      ;  so leave Array%(0) set to zero and exit

                Lea  DI,DTA           ;point DI to DTA for moving file info into Array%()
                Mov  AX,[DI+24]       ;get date stamp
                And  AX,0FE00h        ;mask all but the year
                Mov  CL,9             ;prepare to shift bits 9 places
                Shr  AX,CL            ;align the bits
                Add  AX,1980          ;adjust to the correct year 
                Mov  [SI],AX          ;put the year into Array%(0)

                Mov  AX,[DI+24]       ;get the date again
                And  AX,1E0h          ;mask all but the month
                Mov  CL,5             ;prepare to shift bits 5 places
                Shr  AX,CL            ;shift 'em
                Mov  [SI+02],AX       ;put the month into Array%(1)

                Mov  AX,[DI+24]       ;get the date again
                And  AX,1Fh           ;mask all but the day
                Mov  [SI+04],AX       ;put the day into Array%(2)

                Mov  AX,[DI+22]       ;get time stamp
                And  AX,0F800h        ;mask all but the hours
                Mov  CL,11            ;prepare to shift bits 11 places
                Shr  AX,CL            ;do it
                Mov  [SI+06],AX       ;put the hours into Array%(3)

                Mov  AX,[DI+22]       ;get the time again
                And  AX,7E0h          ;mask all but the minutes
                Mov  CL,5             ;5 places
                Shr  AX,CL
                Mov  [SI+08],AX       ;put minutes into Array%(4)

                Mov  AX,[DI+22]       ;get the time again
                And  AX,1Fh           ;mask all but the seconds
                Shl  AX,1             ;seconds are stored on disk divided by two, multiply to get actual seconds
                Mov  [SI+10],AX       ;put seconds into Array%(5)

                Mov  AX,[DI+26]       ;get file size (lo-word)
                Mov  [SI+12],AX       ;put it into Array%(6)

                Mov  AX,[DI+28]       ;get file size (hi-word)
                Mov  [SI+14],AX       ;put it into Array%(7)

                Mov  AL,[DI+21]       ;get attribute
                CBW                   ;convert byte to word in AX (same as Mov AH,0 but more efficient)
                Mov  [SI+16],AX       ;put attribute into Array%(8)

Exit:           Pop  BP
                Ret  4                ;exit, discarding the passed parameters

FileInfo        Endp
Code            Ends
                End  Begin
