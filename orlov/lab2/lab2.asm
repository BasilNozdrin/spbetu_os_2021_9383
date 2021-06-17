TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING    
   ORG 100H    
   
   
START: JMP BEGIN   

; Данные
MEMORY_S db  'Memory segment:     ',0DH,0AH,'$'      
ENV_ADRESS db 'Environment address:    ',0DH,0AH,'$' 
TAIL db 'Tail of command line:    ','$'     
EMPTY_T db 'Tail of command line: EMPTY','$'
ENV_CONTENT db 0DH,0AH,'Environment scope content:',0DH,0AH, '$'
END_STRING db 0DH,0AH, '$'
PATH db 'Path:  ',0DH,0AH, '$'


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
;-------------------------------

MEMORY_DEFINITION PROC near
    mov ax, ds:[02h]     

    mov di, offset MEMORY_S
    add di, 19
    call WRD_TO_HEX
    mov dx, offset MEMORY_S
    mov AH,09h
    int 21h
    ret
MEMORY_DEFINITION ENDP


ENV_ADRESS_DEFINITION PROC near
    mov ax, ds:[2Ch]     

    mov di, offset ENV_ADRESS
    add di, 24
    call WRD_TO_HEX
    mov dx, offset ENV_ADRESS
    mov AH,09h
    int 21h
    ret
	
ENV_ADRESS_DEFINITION ENDP


TAIL_DEFINITION PROC near
    mov cx, 0
    mov cl, ds:[80h]   
    cmp cl, 0          ;если пусто
    je empty_tail 
	
	mov dx, offset TAIL
    mov AH,09h
    int 21h
	
	
    mov di, 0
    mov ax, 0
	
read_tail: 
    mov dl, ds:[81h+di]
    mov ah, 02h
    int 21h
    inc di
    loop read_tail   

	
	
ret 

empty_tail:
    mov dx, offset EMPTY_T
	mov AH,09h
    int 21h
	
ret
	
TAIL_DEFINITION ENDP


CONTENT_DEFINITION PROC near

    mov dx, offset ENV_CONTENT
    mov AH,09h
    int 21h
    mov di, 0
    mov ds, ds:[2Ch]
	
read_str:
    cmp byte ptr [di], 0
    je end_str
    mov dl, [di]
    mov ah, 02h
    int 21h
    jmp find_end
	
end_str:
    cmp byte ptr [di+1],00h
    je find_end
    push ds
    mov cx, cs
    mov ds, cx
    mov dx, offset END_STRING
    mov AH,09h
    int 21h
    pop ds
	
find_end:
    inc di
    cmp word ptr [di], 0001h
    je read_path
    jmp read_str
	
read_path:
    push ds
    mov ax, cs
    mov ds, ax
	
    mov dx, offset PATH
    mov AH,09h
    int 21h
	
    pop ds
    add di, 2
	
loop2:
    cmp byte ptr [di], 0
    je break
    mov dl, [di]
    mov ah, 02h
    int 21h
    inc di
    jmp loop2
	
break:
    ret
	
CONTENT_DEFINITION ENDP

; Код
BEGIN:
    call MEMORY_DEFINITION    
    call ENV_ADRESS_DEFINITION   
    call TAIL_DEFINITION    
    call CONTENT_DEFINITION  

    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
END START; конец модуля, START - точка выхода