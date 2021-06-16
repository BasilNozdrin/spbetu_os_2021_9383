TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START: JMP BEGIN

PC_TYPE_PC DB 'Your PC type is -> PC', 0DH, 0AH, '$'
PC_TYPE_PCXT DB 'Your PC type is -> PC/XT', 0DH, 0AH, '$'
PC_TYPE_AT DB 'Your PC type is -> AT', 0DH, 0AH, '$'
PC_TYPE_PS2MODEL30 DB 'Your PC type is -> PS2 model 30', 0DH, 0AH, '$'
PC_TYPE_PS2MODEL50OR60 DB 'Your PC type is -> PS2 model 50 or 60', 0DH, 0AH, '$'
PC_TYPE_PS2MODEL80 DB 'Your PC type is -> PS2 model 80', 0DH, 0AH, '$'
PC_TYPE_PCJR DB 'Your PC type is -> PCjr', 0DH, 0AH, '$'
PC_TYPE_PCCONVERTIBLE DB 'Your PC type is -> PC Convertible', 0DH, 0AH, '$'
PC_TYPE_UNKNOWN DB 'Your PC Type is unknown. Code -> ', 0DH, 0AH, '$'

DOS_VERSION DB 'MS DOS version-> . ', 0DH, 0AH, '$'
DOS_VERSION_LESS2 DB 'Your MS DOS version < 2.0', 0DH, 0AH, '$'
DOS_OEM DB 'MS DOS OEM->                       ', 0DH, 0AH, '$'
DOS_SERIAL DB 'MS DOS serial number->      ', 0DH, 0AH, '$'

TETR_TO_HEX PROC near
    and AL, 0Fh
    cmp AL, 09
    jbe NEXT
    add AL, 07
NEXT:
    add AL, 30h
    ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX
    mov AH, AL
    call TETR_TO_HEX
    xchg AL, AH
    mov CL, 4
    shr AL, CL
    call TETR_TO_HEX
    pop CX
    ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
    push BX
    mov BH, AH
    call BYTE_TO_HEX
    mov [DI], AH
    dec DI
    mov [DI], AL
    dec DI
    mov AL, BH
    call BYTE_TO_HEX
    mov [DI], AH
    dec DI
    mov [DI], AL
    pop BX
    ret
WRD_TO_HEX ENDP

BYTE_TO_DEC PROC near
    push CX
    push DX
    xor AH, AH
    xor DX, DX
    mov CX, 10
loop_bd:
    div CX
    or DL, 30h
    mov [SI], DL
    dec SI
    xor DX, DX
    cmp AX, 10
    jae loop_bd
    cmp AL, 00h
    je end_l
    or AL, 30h
    mov [SI], AL
end_l:
    pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP

PRINT_MESSAGE PROC near
	push AX
    mov AH, 9
    int 21h
	pop AX
    ret
PRINT_MESSAGE ENDP

PC_TYPE_TASK PROC near
    push AX
    push BX
    push DX
    push ES
    push DI

    mov AX, 0F000h
    mov ES, AX
    mov DI, 0FFFEh
    mov AL, ES:[DI]

	;TYPE PC
    cmp AL, 0FFh
    je pc

	;TYPE PC/XT
    cmp AL, 0FEh
    je pc_xt

	;TYPE PC/XT
    cmp AL, 0FBh
    je pc_xt

	;TYPE AT
    cmp AL, 0FCh
    je pc_at

	;TYPE PS2 MODEL 30
    cmp AL, 0FAh
    je ps2_model_30

	;TYPE PS2 MODEL 50 OR 60
    cmp AL, 0FCh
    je ps2_model_50_or_60

	;TYPE PS2 MODEL 80
    cmp AL, 0F8h
    je ps2_model_80

	;TYPE PCJR
    cmp AL, 0FDh
    je pcjr

	;TYPE PC CONVERTIBLE
    cmp AL, 0F9h
    je pc_convertible

	;TYPE PC UNKNOWN
    call BYTE_TO_HEX
    mov DI, offset PC_TYPE_UNKNOWN
    mov [DI + 26], AL
    mov [DI + 27], AH
    mov DX, DI
    call PRINT_MESSAGE
    jmp end_pc_type_task


pc:
    mov DX, offset PC_TYPE_PC
    call PRINT_MESSAGE
    jmp end_pc_type_task

pc_xt:
    mov DX, offset PC_TYPE_PCXT
    call PRINT_MESSAGE
    jmp end_pc_type_task

pc_at:
    mov DX, offset PC_TYPE_AT
    call PRINT_MESSAGE
    jmp end_pc_type_task

ps2_model_30:
    mov DX, offset PC_TYPE_PS2MODEL30
    call PRINT_MESSAGE
    jmp end_pc_type_task

ps2_model_50_or_60:
    mov DX, offset PC_TYPE_PS2MODEL50OR60
    call PRINT_MESSAGE
    jmp end_pc_type_task

ps2_model_80:
    mov DX, offset PC_TYPE_PS2MODEL80
    call PRINT_MESSAGE
    jmp end_pc_type_task

pcjr:
    mov DX, offset PC_TYPE_PCJR
    call PRINT_MESSAGE
    jmp end_pc_type_task

pc_convertible:
    mov DX, offset PC_TYPE_PCCONVERTIBLE
    call PRINT_MESSAGE
    jmp end_pc_type_task

end_pc_type_task:
    pop DI
    pop ES
    pop DX
    pop BX
    pop AX
    ret
PC_TYPE_TASK ENDP

DOS_TASK PROC NEAR
    push AX
    push BX
    push DX
    push ES
    push DI

    mov AH, 30h
    int 21h

    ;AL - version number
    ;AH - modification number
    ;DH - OEM number
    ;BL:CX - users serial number
    
    cmp AL, 0h
    je less_2
	
    push AX
    call BYTE_TO_DEC
    lodsw
    mov DI, offset DOS_VERSION
    mov [DI + 16], AH
    pop AX

    xchg AH, AL
    call BYTE_TO_DEC
    lodsw
    mov [DI + 18], ah
    mov DX, DI
    call PRINT_MESSAGE
    jmp version

less_2:
    mov DX, offset DOS_VERSION_LESS2
    call PRINT_MESSAGE

version:
    mov AL, BH
    call BYTE_TO_HEX
    mov di, offset DOS_OEM
    mov [DI + 12], AL
    mov [DI + 13], AH
    mov DX, DI
    call PRINT_MESSAGE

    mov AL, BL
    call BYTE_TO_HEX
    mov DI, offset DOS_SERIAL
    mov [DI + 22], AL
    mov [DI + 23], AH
    mov AX, CX
    add DI, 27
    call WRD_TO_HEX
    mov DX, offset DOS_SERIAL
    call PRINT_MESSAGE

    pop DI
    pop ES
    pop DX
    pop BX
    pop AX
    ret
DOS_TASK ENDP

BEGIN:
    call PC_TYPE_TASK
    call DOS_TASK

    ; Выход в DOS
    xor AL, AL
    mov AH, 4ch
    int 21h

TESTPC ENDS
    END START


