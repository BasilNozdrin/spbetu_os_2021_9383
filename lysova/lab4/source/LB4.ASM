AStack   SEGMENT STACK
        DB 256 dup (?)
AStack   ENDS

DATA	SEGMENT
flag    DB 0
sld     DB 'My interrupt has been loaded!$'
sun     DB 'My interrupt has been unloaded!$'
uld     DB 'My interrupt has already been loaded!$'
uun     DB 'My interrupt has not been loaded!$'
DATA ENDS

CODE   SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:AStack

MY_INTERRURTION  PROC far
        jmp     begint
; --- Data SEGMENT of the resident program ---
        ID      DW 7777h
        PSP     DW ?
        keepCS  DW 0
        keepIP  DW 0
        keepSS  DW 0
        keepSP  DW 0
        keepAX  DW 0
        intstr  DB 'My interrupt: 0000'
        lenstr = $ - intstr
        intstk  DB 128 dup (?)
        endstk:
; --- Begin of the resident program ---
begint: 
        mov     keepSS, SS
        mov     keepSP, SP
        mov     keepAX, AX
        mov     AX, CS
        mov     SS, AX
        mov     SP, OFFSET endstk
        push    BX
        push    CX
        push    DX
        push    DS
        push    ES
        push    SI
        push    DI
        push    BP
; --- Getting cursor ---
        mov     AH, 03h
        mov     BH, 0
        int     10h
        push    DX
; --- Setting cursor ---
        mov     AH, 02h
        mov     BH, 0
        mov     DX, 0
        int     10h
; --- Сounter increment ---
        push    BP
        push    DS
        push    SI
        mov     DX, SEG intstr
        mov     DS, DX
        mov     SI, OFFSET intstr
        mov     CX, 5
incr:  
        mov     BP, CX
        dec     BP
        mov     AL, byte ptr [SI+BP+13]
        inc     AL
        mov     [SI+BP+13], AL
        cmp     AL, 3Ah
        jne     good
        mov     AL, 30h
        mov     byte ptr [SI+BP+13], AL
        loop    incr
good:   
        pop     SI
        pop     DS
; --- Counter writing ---
        push    ES
        mov     DX, SEG intstr
        mov     ES, DX
        mov     BP, OFFSET intstr
        mov     AH, 13h
        mov     AL, 1
        mov     BH, 0
        mov     CX, lenstr
        mov     DX, 0
        int     10h
        pop     ES
        pop     BP
; --- Cursor return ---
        mov     AH, 02h
        mov     BH, 0
        pop     DX
        int     10h
; --- ENDof the resident program ---
        pop     BP
        pop     DI
        pop     SI
        pop     ES
        pop     DS
        pop     DX
        pop     CX
        pop     BX
        mov     AX, keepSS
        mov     SS, AX
        mov     SP, keepSP
        mov     AX, keepAX
        mov     AL, 20h
        out     20h, AL
        iret
endint:
MY_INTERRURTION  ENDP

LOAD    PROC
        push    AX
        push    CX
        push    DX
; --- Storing OFFSET and SEGMENT ---
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     keepIP, BX
        mov     keepCS, ES
; --- Interrupt setting ---
        push    DS
        mov     DX, OFFSET MY_INTERRURTION
        mov     AX, SEG MY_INTERRURTION
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h
        pop     DS
; --- Resident program preservation ---
        mov     DX, OFFSET endint
        mov     CL, 4
        shr     DX, CL
        inc     DX
        mov     AX, CS
        sub     AX, PSP
        add     DX, AX
        xor     AX, AX
        mov     AH, 31h
        int     21h
        pop     DX
        pop     CX
        pop     AX
        ret
LOAD    ENDP

UNLOAD  PROC
        push    AX
        push    DX
        push    SI
        push    ES
; --- Recovery OFFSET and SEGMENT ---
        cli
        push    DS
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET keepCS
        sub     SI, OFFSET MY_INTERRURTION
        mov     DX, ES:[BX+SI+2]
        mov     AX, ES:[BX+SI]
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h
        pop     DS
        mov     AX, ES:[BX+SI-2]
        mov     ES, AX
        push    ES
        mov     AX, ES:[2Ch]
        mov     ES, AX
        mov     AH, 49h
        int     21h
        pop     ES
        mov     AH, 49h
        int     21h
        sti
        pop     ES
        pop     SI
        pop     DX
        pop     AX
        ret
UNLOAD  ENDP

IS_PARAM PROC
        push    AX
        mov     AL, ES:[82h]
        cmp     AL, '/'
        jne     nparam
        mov     AL, ES:[83h]
        cmp     AL, 'u'
        jne     nparam
        mov     AL, ES:[84h]
        cmp     AL, 'n'
        jne     nparam
        mov     flag, 1
nparam: 
        pop     AX
        ret
IS_PARAM ENDP

IS_LOAD PROC
        push    AX
        push    DX
        push    SI
        mov     flag, 1
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET ID
        sub     SI, OFFSET MY_INTERRURTION
        mov     DX, ES:[BX+SI]
        cmp     DX, 7777h
        je      ld
        mov     flag, 0
ld:     
        pop     SI
        pop     DX
        pop     AX
        ret
IS_LOAD ENDP

PRINT_STRING   PROC
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
        ret
PRINT_STRING   ENDP

MAIN   PROC far
        mov     AX, data
        mov     DS, AX
        mov     PSP, ES
        mov     flag, 0
        call    IS_PARAM
        cmp     flag, 1
        je      un
; --- Loading ---
        call    IS_LOAD
        cmp     flag, 0
        je      notld
        mov     DX, OFFSET uld
        call    PRINT_STRING
        jmp     fin
notld:  
        mov     DX, OFFSET sld
        call    PRINT_STRING
        call    LOAD
        jmp     fin
; --- Unloading ---
un:     
        call    IS_LOAD
        cmp     flag, 0
        jne     alrld
        mov     DX, OFFSET uun
        call    PRINT_STRING
        jmp     fin
alrld:  
        call    UNLOAD
        mov     DX, OFFSET sun
        call    PRINT_STRING
; --- End---
fin:    
        mov     AX, 4C00h
        int     21h
MAIN   ENDP
CODE  ENDS
        END    MAIN
