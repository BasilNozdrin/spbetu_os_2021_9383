AStack    SEGMENT  STACK 
          DW 128 DUP(?)   
AStack    ENDS

DATA  SEGMENT
; ДАННЫЕ
    TYPE_PC             DB  'This PC type is PC'        ,0DH,0AH,'$'
    TYPE_PC_XT          DB  'This PC type is PC/XT'     ,0DH,0AH,'$'
    TYPE_AT             DB  'This PC type is AT'        ,0DH,0AH,'$'
    TYPE_PS2_M30        DB  'This PC type is PS2 m30'   ,0DH,0AH,'$'
    TYPE_PS2_M50_M60    DB  'This PC type is PS2 m50/60',0DH,0AH,'$'
    TYPE_PS2_M80        DB  'This PC type is PS2 m80: ' ,0DH,0AH,'$'
    TYPE_PС_jr          DB  'This PC type is PСjr'      ,0DH,0AH,'$'
    TYPE_PC_CNV         DB  'This PC type is PC Convertible',0DH,0AH,'$'
    DOS_VERSION         DB  'DOS Version:  .  '         ,0DH,0AH,'$'
    SERIAL_NUMBER_OEM   DB  'Serial number OEM:       ' ,0DH,0AH,'$'
    USER_NUMBER         DB  'Serial number:       '     ,0DH,0AH,'$'
    ERROR               DB  'ERROR'                     ,0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack

; ПРОЦЕДУРЫ
;------------------------------------------------------------------------------
TETR_TO_HEX PROC near 
    and     AL,0Fh
    cmp     AL,09
    jbe     NEXT
    ADD     AL,07
NEXT:
    ADD     AL,30h
    RET
TETR_TO_HEX ENDP
;------------------------------------------------------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шест. числа в AX
    PUSH    CX
    MOV     AH,AL
    CALL    TETR_TO_HEX
    xchg    AL,AH
    MOV     CL,4
    shr     AL,CL
    CALL    TETR_TO_HEX ; В AL старшая цифра
    pop     CX          ; В AH младшая
    RET
BYTE_TO_HEX ENDP
;------------------------------------------------------------------------------
WRD_TO_HEX PROC near
; Перевод в 16 с/с 16-ти разрядного числа
; В AX - число, DI - адрес последнего символа
    PUSH    BX
    MOV     BH,AH
    CALL    BYTE_TO_HEX
    MOV     [DI],AH
    dec     DI
    MOV     [DI],AL
    dec     DI
    MOV     AL,BH
    CALL    BYTE_TO_HEX
    MOV     [DI],AH
    dec     DI
    MOV     [DI],AL
    pop     BX
    RET
WRD_TO_HEX ENDP
;------------------------------------------------------------------------------
BYTE_TO_DEC PROC near
; Перевод в 10 с/с, SI - адрес поля младшей цифры
    PUSH    CX
    PUSH    DX
    xor     AH,AH
    xor     DX,DX
    MOV     CX,10
loop_bd:
    div     CX
    or      DL,30h
    MOV     [SI],DL
    dec     SI
    xor     DX,DX
    cmp     AX,10
    jae     loop_bd
    cmp     AL,00h
    je      end_l
    or      AL,30h
    MOV     [SI],AL
end_l:
    pop     DX
    pop     CX
    RET
BYTE_TO_DEC ENDP
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
PRINT_STRING PROC near
    PUSH    AX
    MOV     AH,09h
    INT     21h
    pop     AX
    RET
PRINT_STRING endp
;------------------------------------------------------------------------------
PRINT_PC_TYPE PROC near
; тип IBM PC хранится в байте по адресу 0F000:0FFFEh
; в предпоследнем байте ROM BIOS
    MOV     AX, 0F000h
    MOV     ES, AX
    MOV     AL, ES:[0FFFEh]
;------------------------------------------------------------------------------
    cmp     AL, 0ffh 
    je      print_pc
    cmp     AL, 0feh
    je      print_pc_xt
    cmp     AL, 0fbh
    je      print_pc_xt
    cmp     AL, 0fch
    je      print_pc_at
    cmp     AL, 0fah
    je      print_pc_ps2_m30
    cmp     AL, 0fch
    je      print_pc_ps2_m50_m60
    cmp     AL, 0f8h
    je      print_pc_ps2_m80
    cmp     AL, 0fdh
    je      print_pc_jr
    cmp     AL, 0f9h
    je      print_pc_cnv
    MOV     DX, offset ERROR
    jmp     print_type
print_pc:
    MOV     DX, offset TYPE_PC
    jmp     print_type
print_pc_xt:
    MOV     DX, offset TYPE_PC_XT
    jmp     print_type
print_pc_at:
    MOV     DX, offset TYPE_AT
    jmp     print_type
print_pc_ps2_m30:
    MOV     DX, offset TYPE_PS2_M30
    jmp     print_type
print_pc_ps2_m50_m60:
    MOV     DX, offset TYPE_PS2_M50_M60
    jmp     print_type
print_pc_ps2_m80:
    MOV     DX, offset TYPE_PS2_M80
    jmp     print_type
print_pc_jr:
    MOV     DX, offset TYPE_PС_jr
    jmp     print_type
print_pc_cnv:
    MOV     DX, offset TYPE_PC_CNV
    jmp     print_type
print_type:
    CALL    PRINT_STRING
    RET
PRINT_PC_TYPE ENDP
;------------------------------------------------------------------------------
PRINT_OS_VERSION PROC near
; Сохранение значений регистров
    PUSH    AX
    PUSH    BX
    PUSH    CX
    PUSH    DX
    PUSH    SI
    PUSH    DI
; Определении версии DOS 
    MOV     AH, 30h
    INT     21h
; Версия ОС
    MOV     SI, offset DOS_VERSION
    ADD     SI, 13
    CALL    BYTE_TO_DEC
    MOV     AL, AH
    ADD     SI, 3
    CALL    BYTE_TO_DEC
    MOV     DX, offset DOS_VERSION
    CALL    PRINT_STRING
; Серийный номер ОЕМ
    MOV SI, offset SERIAL_NUMBER_OEM
    ADD SI, 19
    MOV AL, bh
    CALL BYTE_TO_DEC
    MOV DX, offset SERIAL_NUMBER_OEM
    CALL PRINT_STRING
; Серийный номер пользователя
    MOV DI, offset USER_NUMBER
    ADD DI, 20
    MOV AX, CX
    CALL WRD_TO_HEX
    MOV AL, bl
    CALL BYTE_TO_HEX
    sub DI, 2
    MOV [DI], AX
    MOV DX, offset USER_NUMBER
    CALL PRINT_STRING
; Восстановление значений регистров
    pop DX
    pop CX
    pop BX
    pop AX
    pop SI
    pop DI
    RET
PRINT_OS_VERSION ENDP
;------------------------------------------------------------------------------
; КОД
Main PROC FAR
    MOV     AX, DATA
    mov     DS, AX
; Задание лабораторной работы
    CALL PRINT_PC_TYPE
    CALL PRINT_OS_VERSION
; Выход в MS_DOS
    xor     AL,AL
    MOV     AH,4Ch
    INT     21h
Main ENDP

CODE    ENDS
        END     Main
