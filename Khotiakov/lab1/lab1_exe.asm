AStack SEGMENT STACK
    DW 256 DUP(?)
AStack ENDS
DATA SEGMENT
; Данные
PC_TYPE db 'Type is PC',0DH,0AH,'$'
PC_XT_TYPE db 'Type is PC/XT',0DH,0AH,'$'
AT_TYPE db 'Type is AT',0DH,0AH,'$'
PS30_TYPE db 'Type is PS2 model 30',0DH,0AH,'$'
PS80_TYPE db 'Type is PS2 model 80',0DH,0AH,'$'
PCCON_TYPE db 'Type is PC Convertible',0DH,0AH,'$'
PCjr_TYPE db 'Type is PCjr',0DH,0AH,'$'
NO_TYPE db 'ERROR: No type in table: ',0DH,0AH,'$'

OS_VERSION db 'OS version is  .  ',0DH,0AH,'$'
OEM db 'OEM is   ',0DH,0AH,'$'
SERIAL db 'Serial nubmer is      ',0DH,0AH,'$'

DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack
; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:   add AL,30h
        ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шестн. числа AX
            push CX
            mov AH,AL
            call TETR_TO_HEX
            xchg AL,AH
            mov CL,4
            shr AL,CL
            call TETR_TO_HEX ; В AL Старшая цифра 
            pop CX           ; В AH младшая цифра
            ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
; Перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа   
        push BX
        mov BH,AH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        dec DI
        mov AL,BH
        call BYTE_TO_HEX
        mov [DI],AH
        dec DI
        mov [DI],AL
        pop BX
        ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; Перевод в 10с/с, SI - адрес поля младшей цифры 
        push CX
        push DX
        xor AH,AH
        xor DX,DX
        mov CX,10
loop_bd: div CX
        or DL,30h
        mov [SI],DL
        dec SI
        xor DX,DX
        cmp AX,10
        jae loop_bd
        cmp AL,00h
        je end_l
        or AL,30h
        mov [SI],AL
end_l: pop DX
      pop CX
      ret
BYTE_TO_DEC ENDP

WRITE_STRING PROC near; Вывод строки текста
        mov AH,09h
        int 21h
        ret
WRITE_STRING ENDP

WHAT_TYPE PROC near
      mov AX, 0f000h
      mov ES, AX
      mov AL, es:[0fffeh]

      cmp AL, 0FFh
      je pc_write
      cmp AL, 0FEh
      je pc_xt_write
      cmp AL, 0FBh
      je pc_xt_write
      cmp AL, 0FCh
      je at_write
      cmp AL, 0FAh
      je ps30_write
      cmp AL, 0F8h
      je ps80_write
      cmp AL, 0FDh
      je pcjr_write
      cmp AL, 0F9h
      je pccon_write
      mov dx, offset NO_TYPE
      jmp WRITE_STRING_TYPE



pc_write:
        mov dx, offset PC_TYPE
        jmp WRITE_STRING_TYPE
pc_xt_write:
        mov dx, offset PC_XT_TYPE
        jmp WRITE_STRING_TYPE
at_write:
        mov dx, offset AT_TYPE
        jmp WRITE_STRING_TYPE
ps30_write:
        mov dx, offset PS30_TYPE
        jmp WRITE_STRING_TYPE
ps80_write:
        mov dx, offset PS80_TYPE
        jmp WRITE_STRING_TYPE
pccon_write:
        mov dx, offset PCCON_TYPE
        jmp WRITE_STRING_TYPE
pcjr_write:
        mov dx, offset PCjr_TYPE
        jmp WRITE_STRING_TYPE
WRITE_STRING_TYPE:
        CALL WRITE_STRING
        ret
WHAT_TYPE ENDP


WHAT_OS_VERSION PROC near
        MOV AH, 30h
        INT 21h
        push AX

        mov SI, offset OS_VERSION
        add SI, 14
        call BYTE_TO_DEC
        pop AX
        mov AL, AH
        add SI, 3
        call BYTE_TO_DEC
        mov DX, offset OS_VERSION
        call WRITE_STRING

        mov SI, offset OEM
        add SI, 7
        mov AL, BH
        call BYTE_TO_DEC
        mov DX, offset OEM
        call WRITE_STRING

        mov DI, offset SERIAL
        add DI, 23
        mov AX, CX
        call WRD_TO_HEX
        mov AL, BL
        call BYTE_TO_HEX
        sub DI, 2
        mov [DI], AX
        mov DX, offset SERIAL
        call WRITE_STRING
        ret
WHAT_OS_VERSION ENDP

;-------------------------------
; КОД
MAIN PROC FAR
        mov AX, DATA
        mov DS, AX

        call WHAT_TYPE
        call WHAT_OS_VERSION

        xor AL, AL
        mov AH, 4Ch
        int 21h

MAIN ENDP

CODE ENDS
END MAIN