DATA SEGMENT
    FILE1       DB "FILE1.OVL", 0
    FILE2       DB "FILE2.OVL", 0
    PROGRAM     dw 0    
    DTA_MEM     DB 43 dup(0)
    MEM_FLAG    DB 0
    CL_POS      DB 128 dup(0)
    OVLS_ADDR   dd 0
    KEEP_PSP    dw 0
    EOF         DB 0DH, 0AH, '$'
    MCB_CRASH_ERR   DB 'ERR: MCB crashed', 0DH, 0AH, '$'
    NO_MEM_ERR  DB 'ERR: there is not enough memory to execute this function', 0DH, 0AH, '$'
    ADDR_ERR        DB 'ERR: invalid memory address', 0DH, 0AH, '$'
    FREE            DB 'memory has been freed' , 0DH, 0AH, '$'
    FN_ERR          DB 'ERR: function doesnt exist', 0DH, 0AH, '$' 
    FILE_ERR        DB 'ERR: file not found(load err)', 0DH, 0AH, '$'
    ROUTE_ERR       DB 'ERR: route not found(load err)', 0DH, 0AH, '$'
    FILES_ERR       DB 'ERR: you opened too many files', 0DH, 0AH, '$'
    ACCESS_ERR      DB 'ERR: no access', 0DH, 0AH, '$' 
    MEM_ERR         DB 'ERR: insufficient memory', 0DH, 0AH, '$' 
    ENVS_ERR        DB 'ERR: wrong string of environment ', 0DH, 0AH, '$'
    NORMAL_END      DB  'Load was successful' , 0DH, 0AH, '$'
    ALLOCATION_END  DB  'Allocation was successful' , 0DH, 0AH, '$'
    ALL_FILE_ERR    DB  'ERR: file not found(allocation err)' , 0DH, 0AH, '$'
    ALL_ROUTE_ERR   DB  'ERR: route not found(allocation err)' , 0DH, 0AH, '$'
    END_DATA DB 0
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
    JNC     _endF
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
    MOV     AX, DATA
    MOV     ES, AX
    MOV     BX, offset OVLS_ADDR
    MOV     DX, offset CL_POS
    MOV     AX, 4b03h
    INT     21h 
    JNC     _loadS
_fn_err:
    CMP     AX, 1
    JNE     _file_err
    MOV     DX, offset EOF
    CALL    PRINT
    MOV     DX, offset FN_ERR
    CALL    PRINT
    JMP     _loadE
_file_err:
    CMP     AX, 2
    JNE     _route_err
    MOV     DX, offset FILE_ERR
    CALL    PRINT
    JMP     _loadE
_route_err:
    CMP     AX, 3
    JNE     _fileS_err
    MOV     DX, offset EOF
    CALL    PRINT
    MOV     DX, offset ROUTE_ERR
    CALL    PRINT
    JMP     _loadE
_fileS_err:
    CMP     AX, 4
    JNE     _access_err
    MOV     DX, offset FILES_ERR
    CALL    PRINT
    JMP     _loadE
_access_err:
    CMP     AX, 5
    JNE     _mem_err
    MOV     DX, offset ACCESS_ERR
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
    MOV     DX, offset ENVS_ERR
    CALL    PRINT
    JMP     _loadE
_loadS:
    MOV     DX, offset NORMAL_END
    CALL    PRINT
    MOV     AX, WORD PTR OVLS_ADDR
    MOV     ES, AX
    MOV     WORD PTR OVLS_ADDR, 0
    MOV     WORD PTR OVLS_ADDR+2, AX
    CALL    OVLS_ADDR
    MOV     ES, AX
    MOV     AH, 49h
    INT     21h
_loadE:
    POP     ES
    POP     DS
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
    MOV     PROGRAM, DX
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
    je      _end_loop
    CMP     DL, '\'
    JNE     _loop
    MOV     CX, DI
    JMP     _loop
_end_loop:
    MOV     DI, CX
    MOV     SI, PROGRAM
_fn:
    MOV     DL, byte ptr [SI]
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
ALLOCATION PROC
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    DX
    MOV     DX, offset DTA_MEM
    MOV     AH, 1Ah
    INT     21h
    POP     DX 
    MOV     CX, 0
    MOV     AH, 4Eh
    INT     21h
    JNC     _all_success
_all_file_err:
    CMP     AX, 2
    je      _all_route_err
    MOV     DX, offset ALL_FILE_ERR
    CALL    PRINT
    JMP     _all_end
_all_route_err:
    CMP     AX, 3
    MOV     DX, offset ALL_ROUTE_ERR
    CALL    PRINT
    JMP     _all_end
_all_success:
    PUSH    DI
    MOV     DI, offset DTA_MEM
    MOV     BX, [DI+1Ah]
    MOV     AX, [DI+1Ch]
    POP     DI
    PUSH    CX
    MOV     CL, 4
    SHR     BX, Cl
    MOV     CL, 12
    shl     AX, CL
    POP     CX
    ADD     BX, AX
    ADD     BX, 1
    MOV     AH, 48h
    INT     21h
    MOV     WORD PTR OVLS_ADDR, AX
    MOV     DX, offset ALLOCATION_END
    CALL    PRINT
_all_end:
    POP     DX
    POP     CX
    POP     BX
    POP     AX
    RET
ALLOCATION ENDP
;------------------------------------------------------------------------------
OVL_START PROC
    PUSH    DX
    CALL    PATH
    MOV     DX, offset CL_POS
    CALL    ALLOCATION
    CALL    LOAD
    POP     DX
    RET
OVL_START ENDP
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
    je      _end
    MOV     DX, offset FILE1
    CALL    OVL_START
    MOV     DX, offset EOF
    CALL    PRINT
    MOV     DX, offset FILE2
    CALL    OVL_START
_end:
    XOR     AL, AL
    MOV     AH, 4ch
    INT     21h
MAIN ENDP
_endC:
;------------------------------------------------------------------------------
CODE ENDS
END     MAIN
