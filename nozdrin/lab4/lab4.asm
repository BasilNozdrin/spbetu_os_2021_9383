CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack
;------------------------------------------------------------------------------
ROUT PROC FAR
    JMP     _start
    ROUTDATA:
    COUNTER     DB  "000 Interruptions"
    SIGNATURE   DW  2228h
    KEEP_IP     DW  0
    KEEP_CS     DW  0
    KEEP_PSP    DW  0
    KEEP_AX     DW  0
    KEEP_SS     DW  0
    KEEP_SP     DW  0
    _STACK      DW 128 DUP(0)
_start:
    MOV     KEEP_AX, AX
    MOV     KEEP_SP, SP
    MOV     KEEP_SS, SS
    MOV     AX, SEG _STACK
    MOV     SS, AX
    MOV     AX, offset _STACK
    ADD     AX, 256
    MOV     SP, AX  ;
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    ES
    PUSH    DS
    MOV     AX, SEG COUNTER
    MOV     DS, AX  ;
    MOV     AH, 03h
    MOV     BH, 0h
    INT     10h
    PUSH    DX      ;
    MOV     AH, 02h
    MOV     BH, 0h
    MOV     DX, 1820h 
    INT     10h     ;
    MOV     AX, SEG COUNTER
    PUSH    DS
    MOV     DS, AX
    MOV     SI, offset COUNTER
    ADD        SI, 2
    MOV     CX, 3
_icycle:
    MOV     AH, [SI]
    INC     AH
    MOV     [SI], AH
    CMP     AH, ':'
    JNE     _end_icycle
    MOV     AH, '0'
    MOV     [SI], AH
    DEC     SI
    LOOP    _icycle
_end_icycle:
    POP     DS
    PUSH    ES
    PUSH    BP
    MOV     AX, SEG COUNTER
    MOV     ES, AX
    MOV     BP, offset COUNTER
    MOV     AH, 13h
    MOV     AL, 1h
    MOV     BL, 6h
    MOV     BH, 0
    MOV     CX, 17
    INT     10h
    POP     BP
    POP     ES
    POP     DX
    MOV     AH, 02h
    MOV     BH, 0h
    INT     10h
    POP     DS
    POP     ES
    POP     SI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    MOV     SP, KEEP_SP
    MOV     AX, KEEP_SS
    MOV     SS, AX
    MOV     AX, KEEP_AX
    MOV     AL, 20h
    OUT     20h, AL
    IRET
ROUT ENDP
_end:
;------------------------------------------------------------------------------
IS_INT_L PROC
    PUSH    AX
    PUSH    BX
    PUSH    SI
    MOV     AH, 35h
    MOV     AL, 1Ch
    INT     21h
    MOV     SI, offset SIGNATURE
    sub     SI, offset ROUT
    MOV     AX, ES:[BX+SI]
    CMP     AX, SIGNATURE
    JNE     _exit_is_l
    MOV     IS_L, 1
_exit_is_l:
    POP     SI
    POP     BX
    POP     AX
    RET
IS_INT_L ENDP
;------------------------------------------------------------------------------
INT_LOAD PROC
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    ES
    PUSH    DS
    MOV     AH, 35h
    MOV     AL, 1Ch
    INT     21h
    MOV     KEEP_CS, ES
    MOV     KEEP_IP, BX
    MOV     AX, SEG ROUT
    MOV     DX, offset ROUT
    MOV     DS, AX
    MOV     AH, 25h
    MOV     AL, 1Ch
    INT     21h
    POP     DS
    MOV     DX, offset _end
    MOV     CL, 4h
    shr     DX, CL
    ADD     DX, 10Fh
    INC     DX
    XOR     AX, AX
    MOV     AH, 31h
    INT     21h
    POP     ES
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
INT_LOAD ENDP
;------------------------------------------------------------------------------
INT_UNLOAD PROC
    CLI
    PUSH    AX
    PUSH    BX
    PUSH    DX
    PUSH    DS
    PUSH    ES
    PUSH    SI
    MOV     AH, 35h
    MOV     AL, 1Ch
    INT     21h
    MOV     SI, offset KEEP_IP
    sub     SI, offset ROUT
    MOV     DX, ES:[BX+SI]
    MOV     AX, ES:[BX+SI+2]
    PUSH    DS
    MOV     DS, AX
    MOV     AH, 25h
    MOV     AL, 1Ch
    INT     21h
    POP     DS
    MOV     AX, ES:[BX+SI+4]
    MOV     ES, AX
    PUSH    ES
    MOV     AX, ES:[2Ch]
    MOV     ES, AX
    MOV     AH, 49h
    INT     21h
    POP     ES
    MOV     AH, 49h
    INT     21h
    STI
    POP     SI
    POP     ES
    POP     DS
    POP     DX
    POP     BX
    POP     AX
    RET
INT_UNLOAD ENDP
;------------------------------------------------------------------------------
IS_FLAG_UN PROC
    PUSH    AX
    PUSH    ES
    MOV     AX, KEEP_PSP
    MOV     ES, AX
    CMP     byte ptr ES:[82h], '/'
    JNE     _exit_un
    CMP     byte ptr ES:[83h], 'u'
    JNE     _exit_un
    CMP     byte ptr ES:[84h], 'n'
    JNE     _exit_un
    MOV     IS_UN, 1
_exit_un:
    POP     ES
    POP     AX
    RET
IS_FLAG_UN ENDP
;------------------------------------------------------------------------------
PRINT PROC NEAR
    PUSH    AX
    MOV     AH, 09h
    INT     21h
    POP     AX
    RET
PRINT ENDP
;------------------------------------------------------------------------------
MAIN PROC
    PUSH    DS
    XOR     AX, AX
    PUSH    AX
    MOV     AX, DATA
    MOV     DS, AX
    MOV     KEEP_PSP, ES
    CALL    IS_INT_L
    CALL    IS_FLAG_UN
    CMP     IS_UN, 1
    JE      _unload
    MOV     AL, IS_L
    CMP     AL, 1
    JNE     _load
    MOV     DX, offset LOADED
    CALL    PRINT
    JMP     _exit_
_load:
    MOV     DX, offset LOAD
    CALL     PRINT
    CALL    INT_LOAD
    JMP     _exit_
_unload:
    CMP     IS_L, 1
    JNE     _not_loaded
    MOV     DX, offset UNLOAD
    CALL     PRINT
    CALL    INT_UNLOAD
    JMP     _exit_
_not_loaded:
    MOV     DX, offset NOT_LOADED
    CALL    PRINT
_exit_:
    XOR     AL, AL
    MOV     AH, 4Ch
    INT     21h
MAIN ENDP
;------------------------------------------------------------------------------
CODE ENDS
;------------------------------------------------------------------------------
ASTACK  SEGMENT STACK
    DW  128 DUP(0)
ASTACK  ENDS
;------------------------------------------------------------------------------
DATA    SEGMENT
    LOAD        DB  "Interruption is loaded"                ,10,13,"$"
    LOADED      DB  "Interruption has already been loaded"  ,10,13,"$"
    UNLOAD      DB  "Interruption has been unloaded"        ,10,13,"$"
    NOT_LOADED  DB  "Interruption is not loaded"            ,10,13,"$"
    IS_L        DB  0
    IS_UN       DB  0
DATA    ENDS
END     MAIN
