CODE SEGMENT
    ASSUME CS:CODE, DS:NOTHING, SS:NOTHING
;------------------------------------------------------------------------------
MAIN PROC FAR
    PUSH    AX
    PUSH    DX
    PUSH    DS
    PUSH    DI
    MOV     AX, CS
    MOV     DS, AX
    MOV     DI, offset OVL
    ADD     DI, 23
    CALL    WRD_TO_HEX
    MOV     DX, offset OVL
    CALL    PRINT
    POP     DI
    POP     DS
    POP     DX
    POP     AX
    RETF
MAIN ENDP
;------------------------------------------------------------------------------
OVL     DB 13, 10, "FILE1_OVL ADDress:          ", 13, 10, '$'
;------------------------------------------------------------------------------
PRINT PROC 
    PUSH    DX
    PUSH    AX
    MOV     AH, 09h
    INT     21h
    POP     AX
    POP     DX
    RET
PRINT ENDP
;------------------------------------------------------------------------------
TETR_TO_HEX PROC 
    AND     AL,0Fh
    CMP     AL,09
    JBE     next
    ADD     AL,07
next:
    ADD AL,30h
    RET
TETR_TO_HEX ENDP
;------------------------------------------------------------------------------
BYTE_TO_HEX PROC
    PUSH    CX
    MOV     AH, AL
    CALL    TETR_TO_HEX
    XCHG    AL,AH
    MOV     CL,4
    SHR     AL,CL
    CALL    TETR_TO_HEX
    POP     CX
    RET
BYTE_TO_HEX ENDP
;------------------------------------------------------------------------------
WRD_TO_HEX PROC  
    PUSH    BX
    MOV     BH,AH
    CALL    BYTE_TO_HEX
    MOV     [DI],AH
    DEC     DI
    MOV     [DI],AL
    DEC     DI
    MOV     AL,BH
    XOR     AH,AH
    CALL    BYTE_TO_HEX
    MOV     [DI],AH
    DEC     DI
    MOV     [DI],AL
    POP     BX
    RET
WRD_TO_HEX ENDP
;------------------------------------------------------------------------------
CODE ENDS
END     MAIN
