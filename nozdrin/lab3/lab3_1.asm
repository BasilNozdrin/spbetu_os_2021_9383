TESTPC SEGMENT
        ASSUME CS:TESTPC, DS: TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H
START: JMP BEGIN

; DATA
AVAILABLE_MEM   DB  'Available memory (B):        '                                         , 10, 13, '$'
EXTENDED_MEM    DB  'Extended memory (KB):        '                                         , 10, 13, '$'
TABLE_TITLE     DB  '| MCB Type | PSP Address | Size | SC/SD |'                             , 10, 13, '$'
TABLE_MCB_DATA  DB  '                                                                    '  , 10, 13, '$'

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
WRD_TO_DEC PROC near
    PUSH    CX
    PUSH    DX
    MOV     CX,10
LOOP_B:
    DIV     CX
    OR      DL,30h
    MOV     [SI],DL
    DEC     SI
    XOR     DX,DX
    CMP     AX,10
    JAE     LOOP_B
    CMP     AL,00h
    JE      ENDL
    OR      AL,30h
    MOV     [SI],AL
ENDL:
    POP     DX
    POP     CX
    RET
WRD_TO_DEC ENDP
;------------------------------------------------------------------------------
PRINT_STRING PROC near
    PUSH    AX
    MOV     AH, 09h
    INT     21h
    POP     AX
    RET
PRINT_STRING ENDP
;------------------------------------------------------------------------------
GET_AVAILABLE_MEMORY PROC near
    PUSH    AX
    PUSH    BX
    PUSH    DX
    PUSH    SI
    XOR     AX, AX
    MOV     AH, 04Ah
    MOV     BX, 0FFFFh
    INT     21h
    MOV     AX, 10h
    MUL     BX
    MOV     SI, OFFSET AVAILABLE_MEM
    ADD     SI, 27
    CALL    WRD_TO_DEC
    MOV     DX, OFFSET AVAILABLE_MEM
    CALL    PRINT_STRING
    POP     SI
    POP     DX
    POP     BX
    POP     AX
    RET
GET_AVAILABLE_MEMORY ENDP
;------------------------------------------------------------------------------
GET_EXTENDED_MEMORY PROC near
    PUSH    AX
    PUSH    BX
    PUSH    DX
    PUSH    SI
    XOR     DX, DX
    MOV     AL, 30h
    OUT     70h, AL
    IN      AL, 71h 
    MOV     BL, AL 
    MOV     AL, 31h  
    OUT     70h, AL
    IN      AL, 71h
    MOV     AH, AL
    MOV     AL, BL
    MOV     SI, OFFSET EXTENDED_MEM
    ADD     SI, 26
    CALL    WRD_TO_DEC
    MOV     DX, OFFSET EXTENDED_MEM
    CALL    PRINT_STRING
    POP     SI
    POP     DX
    POP     BX
    POP     AX
    RET
GET_EXTENDED_MEMORY ENDP
;------------------------------------------------------------------------------
GET_MCB_TYPE PROC near
    PUSH    AX
    PUSH    DI
    MOV     DI, OFFSET TABLE_MCB_DATA
    ADD     DI, 5
    XOR     AH, AH
    MOV     AL, ES:[00h]
    CALL    BYTE_TO_HEX
    MOV     [DI], AL
    INC     DI
    MOV     [DI], AH
    POP     DI
    POP     AX
    RET
GET_MCB_TYPE ENDP
;------------------------------------------------------------------------------
GET_PSP_ADDRESS PROC near
    PUSH    AX
    PUSH    DI
    MOV     DI, OFFSET TABLE_MCB_DATA
    MOV     AX, ES:[01h]
    ADD     DI, 19
    CALL    WRD_TO_HEX
    POP     DI
    POP     AX
    RET
GET_PSP_ADDRESS ENDP
;------------------------------------------------------------------------------
GET_MCB_SIZE PROC near
    PUSH    AX
    PUSH    BX
    PUSH    DI
    PUSH    SI
    MOV     DI, OFFSET TABLE_MCB_DATA
    MOV     AX, ES:[03h]
    MOV     BX, 10h
    MUL     BX
    ADD     DI, 29
    MOV     SI, DI
    CALL    WRD_TO_DEC
    POP     SI
    POP     DI
    POP     BX
    POP     AX
    RET
GET_MCB_SIZE ENDP
;------------------------------------------------------------------------------
GET_SC_SD PROC near
    PUSH    BX
    PUSH    DX
    PUSH    DI
    MOV     DI, OFFSET TABLE_MCB_DATA
    ADD     DI, 33
    MOV     BX, 0h
GET_8_BYTES:
    MOV     DL, ES:[BX+8]
    MOV     [DI], DL
    INC     DI
    INC     BX
    CMP     BX, 8h
    JNE     GET_8_BYTES
    POP     DI
    POP     DX
    POP     BX
    RET
GET_SC_SD ENDP
;------------------------------------------------------------------------------
GET_MCB_DATA PROC near
    MOV     AH, 52h
    INT     21h
    SUB     BX, 2h
    MOV     ES, ES:[BX]
FOR_EACH_MCB:
    CALL    GET_MCB_TYPE
    CALL    GET_PSP_ADDRESS
    CALL    GET_MCB_SIZE
    CALL    GET_SC_SD
    MOV     AX, ES:[03h]
    MOV     BL, ES:[00h]
    MOV     DX, OFFSET TABLE_MCB_DATA
    CALL    PRINT_STRING
    MOV     CX, ES
    ADD     AX, CX
    INC     AX
    MOV     ES, AX
    CMP     BL, 4Dh
    JE FOR_EACH_MCB
    RET
GET_MCB_DATA ENDP
;------------------------------------------------------------------------------
; CODE
BEGIN:
    CALL    GET_AVAILABLE_MEMORY
    CALL    GET_EXTENDED_MEMORY
    MOV     DX, OFFSET TABLE_TITLE
    CALL    PRINT_STRING
    CALL    GET_MCB_DATA
; EXIT TO MS_DOS
    XOR     AL, AL
    MOV     AH, 4Ch
    INT     21h

TESTPC  ENDS
    END START   ; конец модуля, START - точка входа
