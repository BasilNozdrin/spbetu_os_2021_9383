Astack SEGMENT STACK
   DB 512 DUP (?) 
Astack ENDS

DATA SEGMENT
; Данные
PC_T db 'Type is PC',0DH,0AH,'$'
PC_XT_T db 'Type is PC/XT',0DH,0AH,'$'
AT_TY db 'Type is AT',0DH,0AH,'$'
PS30_T db 'Type is PS2 model 30',0DH,0AH,'$'
PS80_T db 'Type is PS2 model 80',0DH,0AH,'$'
PCCON_T db 'Type is PC Convertible',0DH,0AH,'$'
PCjr_T db 'Type is PCjr',0DH,0AH,'$'
NO_T db 'ERROR: No type in table: ',0DH,0AH,'$'

VERSION db 'Version:  .  ',0DH,0AH,'$'
OEM db  'OEM:  ',0DH,0AH,'$'
USER db  'User:        $'

DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:Astack
START: JMP BEGIN    
; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ;в AL старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
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
; перевод в 10с/с, SI - адрес поля младшей цифры
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd:
    div CX
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
end_l:
    pop DX
    pop CX
    ret
BYTE_TO_DEC ENDP
;-------------------------------
PC_TYPE PROC near
    mov AX, 0f000h ;получаем тип пк
    mov ES, AX
    mov AL, es:[0fffeh]

      cmp AL, 0FFh
      je pc
	  
      cmp AL, 0FEh
      je pc_xt
	  
      cmp AL, 0FBh
      je pc_xt
	  
      cmp AL, 0FCh
      je at_t
	  
      cmp AL, 0FAh
      je ps30
	  
      cmp AL, 0F8h
      je ps80
	  
      cmp AL, 0FDh
      je pcjr
	  
      cmp AL, 0F9h
      je pccon
	  
      mov dx, offset NO_T
      jmp WRITE_STRING



	pc:
			mov dx, offset PC_T
			jmp WRITE_STRING
	pc_xt:
			mov dx, offset PC_XT_T
			jmp WRITE_STRING
	at_t:
			mov dx, offset AT_TY
			jmp WRITE_STRING
	ps30:
			mov dx, offset PS30_T
			jmp WRITE_STRING
	ps80:
			mov dx, offset PS80_T
			jmp WRITE_STRING
	pccon:
			mov dx, offset PCCON_T
			jmp WRITE_STRING
	pcjr:
			mov dx, offset PCjr_T
			jmp WRITE_STRING_T
			
	WRITE_STRING_T:
		call WRITE_STRING
		ret

PC_TYPE ENDP

OS PROC near
    ;версия
    mov ah, 30h
    int 21h
    push ax
    mov si, offset VERSION
    add si, 9       ;смещение
    call BYTE_TO_DEC
    pop ax
    mov al, ah
    add si, 3       ;смещение
    call BYTE_TO_DEC
    mov dx, offset VERSION
    call WRITE_STRING
	
    ;серийный номер OEM
    mov si, offset OEM
    add si, 5      ;смещение 
    mov al, bh
    call BYTE_TO_DEC
    mov dx, offset OEM
    call WRITE_STRING
	
    ;серийный номер пользователя
    mov di, offset USER
    add di, 11     ;смещение
    mov ax, cx
    call WRD_TO_HEX
    mov al, bl
    call BYTE_TO_HEX
    sub di, 2
    mov [di], ax
    mov dx, offset USER
    call WRITE_STRING
    ret

OS ENDP

WRITE_STRING PROC near
	; Вывод строки текста из поля STRING
	 mov AH,09h
	 int 21h
	 ret
WRITE_STRING ENDP

; Код
BEGIN:
    mov AX, DATA
    mov DS, AX
   call PC_TYPE
   call OS

   xor AL,AL
   mov AH,4Ch
   int 21H
CODE ENDS
END START; конец модуля, START - точка выхода