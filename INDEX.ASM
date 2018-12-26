;----- Index.Asm - searches an integer array for a word match, =>, or <=

;Copyright (c) 1987 Ethan Winer

;Syntax - Call Index(Segment%, StartAddr%, Size%, Match%, Found%, Direction%, Code%)

;where Segment% is the segment to search, StartAddr% is the starting address,
;      Size% is the number of words (elements) to examine, Match% is the
;      integer value to search for, and Found% is how many words into the
;      array it was found.  If not found, then Found% will be set to -1.
;      The direction is specified by placing a value in Direction% when the
;      routine is called.  A 1 indicates to search forward, and a -1 means
;      to go backward.  In either case, Found% returns with a positive
;      number to tell how far it searched, unless a match wasn't found.
;      Code% specifies whether to search for an exact match (0), equal or
;      less (-1), or equal or greater (1).

;Register usage:

;      ES - segment to search if doing an exact match
;      DS - segment to search if doing a relative match
;      DI - address to search if doing an exact match
;      SI - address to search if doing a relative match
;      BX - original starting count, to allow computing how far the search went later
;      CX - number of words to search
;      AX - search value if doing an exact match
;      BP - search value if doing a relative match
;      DX - type of comparison (exact, less/equal, greater/equal)


Code     Segment Byte Public 'Code'
         Assume  CS:Code
         Public  Index
Index    Proc Far

Begin:   Push BP                 ;save registers
         Push DS
         Mov  BP,SP              ;put address of stack into BP
         Cld                     ;assume scanning will be forward for now

         Mov  SI,[BP+20]         ;put address of Segment% into SI
         Mov  ES,[SI]            ;now ES holds the segment to scan

         Mov  SI,[BP+18]         ;address of StartAddr% into SI
         Mov  DI,[SI]            ;now DI points to the beginning address

         Mov  SI,[BP+16]         ;address of Size% into SI
         Mov  CX,[SI]            ;now CX holds the number of words to search
         Mov  BX,CX              ;save the count in BX too, so we can can see how far we searched later

         Mov  SI,[BP+14]         ;address of Match% into SI
         Mov  AX,[SI]            ;now AX holds the value to scan for

         Mov  SI,[BP+10]         ;address of Direction% into SI
         Cmp  Byte Ptr [SI],1    ;are we supposed to search forward?
         JZ   More               ;yes, and the Direction flag is already correct
         Std                     ;no set it to backwards

More:    Mov  SI,[BP+08]         ;address of Code% into SI
         Mov  DX,[SI]            ;now DX holds the comparison code

         Mov  SI,[BP+12]         ;address of Found% in SI
         Mov  Word Ptr [SI],-1   ;show it being not found for now

         Cmp  DX,0               ;what kind of comparison are we doing?
         JZ   Exact              ;an exact one
         Xchg SI,DI              ;a relative one, we'll have to use DS:SI instead of ES:DI
         Mov  BP,AX              ;and we'll trash AX with each compare, so keep the comparison value in BP
         Push ES
         Pop  DS
         JL   L_Or_Eq            ;we're doing a less or equal comparison
                                 ;fall through to greater or equal

G_Or_Eq: Lodsw                   ;get the byte at DS:SI
         Cmp  AX,BP              ;compare it against the search value
         JGE  Almost             ;we found a match so we're almost done, but first swap DI and SI below
         Loop G_Or_Eq            ;keep searching
         Jmp  Exit               ;not found, but Found% already shows this, so just exit

L_Or_Eq: Lodsw                   ;get the byte at DS:SI
         Cmp  AX,BP              ;compare it against the search value
         JLE  Almost             ;a match, go swap DI and SI
         Loop L_Or_Eq            ;keep searching
         Jmp  Exit               ;not found, but Found% already shows this, so just exit

Almost:  Xchg SI,DI              ;put SI and DI back to what they must be
         Dec  CX                 ;a fudge to make Lodsw behave like Repne Scasw
         Jmp  Done               ;and go calculate where we found the match

Exact:   Repne Scasw             ;let the 8088 do the work now
         JNE  Exit               ;no match, and Found% already shows this

Done:    Sub  BX,CX              ;now calculate how many bytes we just examined
         Dec  BX                 ;because CX is always decremented at least once, even if it was found at the first element examined
         Pop  DS                 ;we need DS to set Found%
         Push DS                 ;  but we also need it to be on the stack again
         Mov  [SI],BX            ;put the result in Found%

Exit:    Pop  DS
         Pop  BP                 ;restore BP
         Ret  14                 ;return to BASIC

Index    Endp
Code     Ends
         End  Begin
