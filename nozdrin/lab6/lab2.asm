TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START:  JMP BEGIN
; DATA
UNAVAILABLE_MEMORY_ADDRESS  DB 'Unavailable memory address:          '      ,0DH,0AH,'$'
ENV_ADDRESS                 DB 'Environment segment address:          '     ,0DH,0AH,'$'
COMMAND_TAIL                DB 'Command tail:                              ',0DH,0AH,'$'
COMMAND_TAIL_EMPTY          DB 'Command tail: empty'                        ,0DH,0AH,'$'
ENV_CONTENT                 DB 'Environment segment content:'               ,0DH,0AH,'$'
MODULE_PATH                 DB 'Module path:'                               ,0DH,0AH,'$'
END_STRING                  DB 0DH, 0AH, '$'

; PROCEDURES
;------------------------------------------------------------------------------
TETR_TO_HEX PROC near
    AND     AL, 0Fh
    CMP     AL, 09
    jbe     NEXT
    ADD     AL, 07
NEXT:    
    ADD     AL, 30h
    RET
TETR_TO_HEX ENDP
;------------------------------------------------------------------------------
BYTE_TO_HEX PROC near
    PUSH    CX
    MOV     AH, AL
    CALL    TETR_TO_HEX
    XCHG    AL, AH
    MOV     CL, 4
    shr     AL, CL
    CALL    TETR_TO_HEX
    POP     CX
    RET
BYTE_TO_HEX ENDP
;------------------------------------------------------------------------------
WRD_TO_HEX  PROC near
    PUSH    BX
    MOV     BH, AH
    CALL    BYTE_TO_HEX
    MOV     [DI], AH
    DEC     DI
    MOV     [DI], AL
    DEC     DI
    MOV     AL, BH
    CALL    BYTE_TO_HEX
    MOV     [DI], AH
    DEC     DI
    MOV     [DI], AL
    POP     BX
    RET
WRD_TO_HEX  ENDP
;------------------------------------------------------------------------------
BYTE_TO_DEC PROC near
    PUSH    CX
    PUSH    DX
    XOR     AH, AH
    XOR     DX, DX
    MOV     CX, 10
LOOP_BD:
    DIV     CX
    OR      DL, 30h
    MOV     [SI], DL
    DEC     SI
    XOR     DX, DX
    CMP     AX, 10
    jae     LOOP_BD
    CMP     AL, 00h
    je      END_1
    OR      AL, 30h
    MOV     [SI], AL
END_1:
    POP     DX
    POP     CX
    RET
BYTE_TO_DEC ENDP
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
PRINT_STRING PROC near
    PUSH    AX
    MOV     ah, 09h
    INT     21h
    POP     AX
    RET
PRINT_STRING ENDP
;------------------------------------------------------------------------------
UMA PROC near
    PUSH    AX
    PUSH    DI
    MOV     AX, DS:[02h]
    MOV     DI, offset UNAVAILABLE_MEMORY_ADDRESS
    ADD     DI, 30
    CALL    WRD_TO_HEX
    MOV     DX, offset UNAVAILABLE_MEMORY_ADDRESS
    CALL    PRINT_STRING
    POP     DI
    POP     AX
    RET
UMA ENDP
;------------------------------------------------------------------------------
ENV_A PROC near
    PUSH    AX
    PUSH    CX
    PUSH    DI
    MOV     AX, DS:[2Ch]
    MOV     DI, offset ENV_ADDRESS
    ADD     DI, 32
    CALL    WRD_TO_HEX
    MOV     DX, offset ENV_ADDRESS
    CALL    PRINT_STRING
    POP     DI
    POP     CX
    POP     AX
    RET
ENV_A ENDP
;------------------------------------------------------------------------------
C_TAIL PROC near
    XOR     CX, CX
    MOV     CL, DS:[80h]
    MOV     SI, offset COMMAND_TAIL
    ADD     SI, 15
    CMP     CL, 0h
    je      EMPTY
    XOR     DI, DI
    XOR     AX, AX
READ:
    MOV     AL, DS:[81h+DI]
    INC     DI
    MOV     [SI], AL
    INC     SI
    LOOP    READ
    MOV     DX, offset COMMAND_TAIL
    jmp     PRINT_TAIL
EMPTY:
    MOV     DX, offset COMMAND_TAIL_EMPTY
PRINT_TAIL:
    CALL    PRINT_STRING
    RET
C_TAIL ENDP
;------------------------------------------------------------------------------
ENV_C PROC near
    MOV     DX, offset ENV_CONTENT
    CALL    PRINT_STRING
    XOR     DI, DI
    MOV     DS, DS:[2Ch]
READ_STRING:    
    CMP     byte ptr [DI], 00h
    jz      END_CONTENT
    MOV     DL, [DI]
    MOV     AH, 02h
    INT     21h
    jmp     FIND
END_CONTENT:
    CMP     byte ptr [DI+1], 00h
    jz      FIND
    PUSH    DS
    MOV     CX, CS
    MOV     DS, CX
    MOV     DX, offset END_STRING
    CALL    PRINT_STRING
    POP     DS
FIND:
    INC     DI
    CMP     word ptr [DI], 0001h
    jz      PATH
    jmp     READ_STRING
PATH:
    PUSH    DS
    MOV     AX, CS
    MOV     DS, AX
    MOV     DX, offset MODULE_PATH
    CALL    PRINT_STRING
    POP     DS
    ADD     DI, 2
LOOP_PATH:
    CMP     byte ptr [DI], 00h
    jz      EXIT
    MOV     DL, [DI]
    MOV     AH, 02h
    INT     21h
    INC     DI
    jmp     LOOP_PATH
EXIT:
    RET
ENV_C ENDP
;------------------------------------------------------------------------------
; CODE
BEGIN:
; TASK
    XOR     AX, AX
    CALL    UMA
    CALL    ENV_A
    CALL    C_TAIL
    CALL    ENV_C
; EXIT TO MS_DOS
    XOR     AL, AL
    MOV     AH, 01h
    INT     21h
    MOV     AH, 4Ch
    INT     21h

TESTPC    ENDS
    END START   ; конец модуля, START - точка входа
