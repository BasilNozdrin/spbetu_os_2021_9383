TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START:  JMP BEGIN
; DATA
SEG_INAC_MEMORY DB 'Segment address of inaccessible memory:          '      ,0DH,0AH,'$'
SEG_ENV         DB 'Segment address of environment:          '              ,0DH,0AH,'$'
TAIL_COM        DB 'Tail of command string:                               ' ,0DH,0AH,'$'
ENV_SCOPE       DB 'Environment scope content: '                            ,0DH,0AH,'$'
LOAD_PATH       DB 'Loadable module path: '                                 ,0DH,0AH,'$'
NULL_TAIL       DB 'Tail of command is empty! '                             ,0DH,0AH,'$'
END_STRING      DB 0DH, 0AH, '$'

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
DATA_INAC_MEMORY PROC near
    MOV     AX, DS:[02h]
    MOV     DI, offset SEG_INAC_MEMORY
    ADD     DI, 43
    CALL    WRD_TO_HEX
    MOV     DX, offset SEG_INAC_MEMORY
    CALL    PRINT_STRING
    RET
DATA_INAC_MEMORY ENDP
;------------------------------------------------------------------------------
DATA_ENV PROC near
    MOV     AX, DS:[2Ch]
    MOV     DI, offset SEG_ENV
    ADD     DI, 35
    CALL    WRD_TO_HEX
    MOV     DX, offset SEG_ENV
    CALL    PRINT_STRING
    RET
DATA_ENV ENDP
;------------------------------------------------------------------------------
DATA_TAIL PROC near
    XOR     CX, CX
    MOV     CL, DS:[80h]
    MOV     SI, offset TAIL_COM
    ADD     SI, 25
    CMP     CL, 0h
    je      EMPTY
    XOR     DI, DI
    XOR     AX, AX
READ:
    MOV     AL, DS:[81h+DI]
    inc     DI
    MOV     [SI], AL
    inc     SI
    loop    read
    MOV     DX, offset TAIL_COM
    jmp     PRINT_TAIL
EMPTY:
    MOV     DX, offset NULL_TAIL
PRINT_TAIL:    
    CALL    PRINT_STRING
    RET
DATA_TAIL ENDP
;------------------------------------------------------------------------------
DATA_CONTENT PROC near
    MOV     DX, offset ENV_SCOPE
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
    inc     DI
    CMP     word ptr [DI], 0001h
    jz      PATH
    jmp     READ_STRING
PATH:
    PUSH    DS
    MOV     AX, CS
    MOV     DS, AX
    MOV     DX, offset LOAD_PATH
    CALL    PRINT_STRING
    POP     DS
    ADD     DI, 2
LOOP_PATH:
    CMP     byte ptr [DI], 00h
    jz      EXIT
    MOV     DL, [DI]
    MOV     AH, 02h
    INT     21h
    inc     DI
    jmp     LOOP_PATH
EXIT:
    RET
DATA_CONTENT ENDP
;------------------------------------------------------------------------------
; CODE
BEGIN:
; TASK
    XOR     AX, AX
    CALL    DATA_INAC_MEMORY
    CALL    DATA_ENV
    CALL    DATA_TAIL
    CALL    DATA_CONTENT
; EXIT TO MS_DOS
    XOR     AL, AL
    MOV     AH, 4Ch
    INT     21h

TESTPC    ENDS
    END START   ; конец модуля, START - точка входа

;----------------------------
UNAVAILABLE_MEMORY_ADDRESS DB 'Unavailable memory address:    ', 0DH, 0AH, '$'
ENV_ADDRESS DB 'Segment environment address:    ', 0DH, 0AH, '$'
COMMAND_TAIL DB 'Command tail:$'
COMMAND_TAIL_EMPTY DB 'Command tail: empty', 0DH, 0AH, '$'
ENV_CONTENT DB 'Segment environment content:', 0DH, 0AH, '$'
MODULE_PATH DB 'Module path:$'

;----------------------- PRINT_STRING
PRINT_MESSAGE PROC near
    PUSH AX
    MOV AH, 9
    INT 21h
    POP AX
    RET
PRINT_MESSAGE ENDP

PRINT_MESSAGE_BYTE  PROC  near
    PUSH AX
    MOV AH, 02h
    INT 21h
    POP AX
    RET
PRINT_MESSAGE_BYTE  ENDP

PRINT_EOF PROC near
    PUSH AX
    PUSH DX
    MOV DL, 0dh
    CALL PRINT_MESSAGE_BYTE
    MOV DL, 0ah
    CALL PRINT_MESSAGE_BYTE
    POP DX
    POP AX
    RET
PRINT_EOF ENDP

;-----------------------
UMA_TASK PROC near
    PUSH AX
    PUSH DI
    MOV AX,DS:[02h]
    MOV DI, offset UNAVAILABLE_MEMORY_ADDRESS
    ADD DI, 30
    CALL WRD_TO_HEX
    MOV DX, offset UNAVAILABLE_MEMORY_ADDRESS
    CALL PRINT_MESSAGE
    POP DI
    POP AX
    RET
UMA_TASK ENDP

ENV_ADDRESS_TASK PROC near
    PUSH AX
    PUSH cx
    PUSH DI
    MOV AX,DS:[2ch]
    MOV DI, offset ENV_ADDRESS
    ADD DI, 31
    CALL WRD_TO_HEX
    MOV DX, offset ENV_ADDRESS
    CALL PRINT_MESSAGE
    POP DI
    POP CX
    POP AX
    RET
ENV_ADDRESS_TASK ENDP

COMMAND_TAIL_TASK PROC near
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH DI
    XOR CX, CX
    XOR DI, DI
    MOV CL, DS:[80h]
    CMP CL, 0
    je empty
    MOV DX, offset COMMAND_TAIL
    CALL PRINT_MESSAGE
for_loop:
    MOV DL, DS:[81h + DI]
    CALL PRINT_MESSAGE_BYTE
    inc DI
    loop for_loop
    CALL PRINT_EOF
    jmp restore
empty:
    MOV DX, offset COMMAND_TAIL_EMPTY
    CALL PRINT_MESSAGE
restore:
    POP DI
    POP DX
    POP CX
    POP AX
    RET
COMMAND_TAIL_TASK ENDP

ENV_CONTENT_TASK PROC near
    PUSH AX
    PUSH DX
    PUSH ES
    PUSH DI
    MOV DX, offset ENV_CONTENT
    CALL PRINT_MESSAGE
    XOR DI, DI
    MOV AX, ds:[2ch]
    MOV ES, AX
for_loop_2:
    MOV DL, ES:[DI]
    CMP DL, 0
    je end_2
    CALL PRINT_MESSAGE_BYTE
    inc DI
    jmp for_loop_2
end_2:
    CALL PRINT_EOF
    inc DI
    MOV DL, ES:[DI]
    CMP DL, 0
    jne for_loop_2
    CALL MODULE_PATH_TASK
    POP DI
    POP ES
    POP DX
    POP AX
    RET
ENV_CONTENT_TASK ENDP

MODULE_PATH_TASK PROC near
    PUSH AX
    PUSH DX
    PUSH ES
    PUSH DI
    MOV DX, offset MODULE_PATH
    CALL PRINT_MESSAGE
    ADD DI, 3
for_loop_3:
    MOV DL, ES:[DI]
    CMP DL,0
    je restore_2
    CALL PRINT_MESSAGE_BYTE
    inc DI
    jmp for_loop_3
restore_2:
    CALL PRINT_EOF
    POP DI
    POP ES
    POP DX
    POP AX
    RET
MODULE_PATH_TASK ENDP

BEGIN:
    CALL UMA_TASK
    CALL ENV_ADDRESS_TASK
    CALL COMMAND_TAIL_TASK
    CALL ENV_CONTENT_TASK
