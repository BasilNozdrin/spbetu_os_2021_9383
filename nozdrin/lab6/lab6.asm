DATA SEGMENT
    PARAMETER_BLOCK dw 0
                    dd 0
                    dd 0
                    dd 0
    PROGRAM     db 'LAB2.COM', 0
    MEM_FLAG    db 0
    CMD_L       db 1h, 0dh
    CL_POS      db 128 dup(0)
    KEEP_SS     dw 0
    KEEP_SP     dw 0
    KEEP_PSP    dw 0
    MCB_CRASH_ERR   db 'ERR: MCB crashed', 0DH, 0AH, '$' 
    NO_MEM_ERR  db 'ERR: there is not enough memory to execute this function', 0DH, 0AH, '$' 
    ADDR_ERR    db 'ERR: invalid memory address', 0DH, 0AH, '$'
    FREE        db 'memory has been freed' , 0DH, 0AH, '$'
    FN_ERR      db 'ERR: invalid function number', 0DH, 0AH, '$' 
    FILE_ERR    db 'ERR: file not found', 0DH, 0AH, '$' 
    DISK_ERR    db 'ERR: disk error', 0DH, 0AH, '$' 
    MEM_ERR     db 'ERR: insufficient memory', 0DH, 0AH, '$' 
    ENVS_ERR    db 'ERR: wrong string of environment ', 0DH, 0AH, '$' 
    FORMAT_ERR  db 'ERR: wrong format', 0DH, 0AH, '$' 
    NORMAL_END  db 0DH, 0AH, 'Program ended with code    ' , 0DH, 0AH, '$'
    CTRL_END    db 0DH, 0AH, 'Program ended by Ctrl-Break' , 0DH, 0AH, '$'
    DEVICE_ERR  db 0DH, 0AH, 'Program ended by device error' , 0DH, 0AH, '$'
    INT_END     db 0DH, 0AH, 'Program ended by INT 31h' , 0DH, 0AH, '$'
    END_DATA db 0
DATA ENDS
;------------------------------------------------------------------------------
AStack SEGMENT STACK
    DW 128 DUP(?)
AStack ENDS
;------------------------------------------------------------------------------
CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack
;------------------------------------------------------------------------------
PRINT PROC 
     PUSH   AX
     MOV    AH, 09h
     INT    21h 
     POP    AX
     RET
PRINT ENDP 
;------------------------------------------------------------------------------
MEM_FREE PROC 
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    MOV     AX, offset END_DATA
    MOV     BX, offset _endC
    ADD     BX, AX
    MOV     CL, 4
    SHR     BX, CL
    ADD     BX, 2bh
    MOV     AH, 4Ah
    INT     21h 
    jnc     _endF
    MOV     MEM_FLAG, 1
_mcb_crash:
    CMP     AX, 7
    JNE     _no_mem
    MOV     DX, offset MCB_CRASH_ERR
    CALL    PRINT
    JMP     _freeE
_no_mem:
    CMP     AX, 8
    JNE     _addr
    MOV     DX, offset NO_MEM_ERR
    CALL    PRINT
    JMP     _freeE
_addr:
    CMP     AX, 9
    MOV     DX, offset ADDR_ERR
    CALL    PRINT
    JMP     _freeE
_endF:
    MOV     MEM_FLAG, 1
    MOV     DX, offset FREE
    CALL    PRINT
_freeE:
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
MEM_FREE ENDP
;------------------------------------------------------------------------------
LOAD PROC 
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    DS
    PUSH    ES
    MOV     KEEP_SP, SP
    MOV     KEEP_SS, SS
    MOV     AX, DATA
    MOV     ES, AX
    MOV     BX, offset PARAMETER_BLOCK
    MOV     DX, offset CMD_L
    MOV     [BX+2], DX
    MOV     [BX+4], DS
    MOV     DX, offset CL_POS
    MOV     AX, 4b00h
    INT     21h
    MOV     SS, KEEP_SS
    MOV     SP, KEEP_SP
    POP     ES
    POP     DS
    jnc     _loadS
_fn_err:
    CMP     AX, 1
    JNE     _file_err
    MOV     DX, offset FN_ERR
    CALL    PRINT
    JMP     _loadE
_file_err:
    CMP     AX, 2
    JNE     _disk_err
    MOV     DX, offset FILE_ERR
    CALL    PRINT
    JMP     _loadE
_disk_err:
    CMP     AX, 5
    JNE     _mem_err
    MOV     DX, offset DISK_ERR
    CALL    PRINT
    JMP     _loadE
_mem_err:
    CMP     AX, 8
    JNE     _envs_err
    MOV     DX, offset MEM_ERR
    CALL    PRINT
    JMP     _loadE
_envs_err:
    CMP     AX, 10
    JNE     _format_err
    MOV     DX, offset ENVS_ERR
    CALL    PRINT
    JMP     _loadE
_format_err:
    CMP     AX, 11
    MOV     DX, offset FORMAT_ERR
    CALL    PRINT
    JMP     _loadE
_loadS:
    MOV     AH, 4dh
    MOV     AL, 00h
    INT     21h 
_Nend:
    CMP     AH, 0
    JNE     _ctrlc
    PUSH    DI 
    MOV     DI, offset NORMAL_END
    MOV     [DI+26], AL 
    POP     SI
    MOV     DX, offset NORMAL_END
    CALL    PRINT
    JMP     _loadE
_ctrlc:
    CMP     AH, 1
    JNE     _device
    MOV     DX, offset CTRL_END 
    CALL    PRINT
    JMP     _loadE
_device:
    CMP     AH, 2
    JNE     _31h
    MOV     DX, offset DEVICE_ERR
    CALL    PRINT
    JMP _loadE
_31h:
    CMP     AH, 3
    MOV     DX, offset INT_END
    CALL    PRINT
_loadE:
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
LOAD ENDP
;------------------------------------------------------------------------------
PATH PROC 
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    DI
    PUSH    SI
    PUSH    ES
    MOV     AX, KEEP_PSP
    MOV     ES, AX
    MOV     ES, ES:[2ch]
    MOV     BX, 0
FINDZ:
    INC     BX
    CMP     byte ptr ES:[BX-1], 0
    JNE     FINDZ
    CMP     byte ptr ES:[BX+1], 0
    JNE     FINDZ
    ADD     BX, 2
    MOV     DI, 0
_loop:
    MOV     DL, ES:[BX]
    MOV     byte ptr [CL_POS+DI], DL
    INC     DI
    INC     BX
    CMP     DL, 0
    JE      _end_loop
    CMP     DL, '\'
    JNE     _loop
    MOV     CX, DI
    JMP     _loop
_end_loop:
    MOV     DI, CX
    MOV     SI, 0
_fn:
    MOV     DL, byte ptr [PROGRAM+SI]
    MOV     byte ptr [CL_POS+DI], DL
    INC     DI
    INC     SI
    CMP     DL, 0
    JNE     _fn
    POP     ES
    POP     SI
    POP     DI
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
PATH ENDP
;------------------------------------------------------------------------------
MAIN PROC FAR
    PUSH    DS
    XOR     AX, AX
    PUSH    AX
    MOV     AX, DATA
    MOV     DS, AX
    MOV     KEEP_PSP, ES
    CALL    MEM_FREE 
    CMP     MEM_FLAG, 0
    JE      _end
    CALL    PATH
    CALL    LOAD
_end:
    XOR     AL, AL
    MOV     AH, 4ch
    INT     21h
MAIN ENDP
;------------------------------------------------------------------------------
_endC:
CODE ENDS
END     MAIN
