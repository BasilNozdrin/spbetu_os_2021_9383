TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; Данные
ACCESSED_MEMORY db 13,10,'Size of accessed memory:       $'
EXTENDED_MEMORY db 13,10,'Size of extended memory:       $'
STR_BYTE db ' byte $'
STR_MCB db 13,10,'MCB:0   $'
ADRESS db 'Adress:        $'
ADRESS_PSP db 'PSP adress:       $'
STR_SIZE db 'Size:        $'
MCB_SD_SC db ' SD/SC: $'
STR_ERROR db 13,10,'Memory Error!$'
STR_SUCCECC db 13,10,'Success!$'

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
WRITE_STRING PROC near
   push AX
   mov AH,09h
   int 21h
   pop AX
   ret
WRITE_STRING ENDP
;-------------------------------

WRITE_SIZE PROC
   push ax
   push bx
   push cx
   push dx
   push si

	mov bx,10h
	mul bx
	mov bx,0ah
	xor cx,cx

separation:
	div bx
	push dx
	inc cx
	xor dx,dx
	cmp ax,0h
	jnz separation

write_symbol:
	pop dx
	or dl,30h
	mov [si], dl
	inc si
	loop write_symbol

   pop si
   pop dx
   pop cx
   pop bx
   pop ax
	ret
WRITE_SIZE ENDP
;-------------------------------
PRINT_MCB PROC
   push ax
   push bx
   push cx
   push dx
   push si

   mov ah,52h
   int 21h
   mov ax,es:[bx-2]
   mov es,ax
   mov cl,1

pargraph_MCB:
	lea si, STR_MCB
	add si, 7

  mov al,cl
	push cx
	call BYTE_TO_DEC
	lea dx, STR_MCB
	call WRITE_STRING

	mov ax,es
	lea di,ADRESS
	add di,12
	call WRD_TO_HEX
	lea dx,ADRESS
	call WRITE_STRING

	xor ah,ah
	mov al,es:[0]
	push ax
	mov ax,es:[1]
	lea di, ADRESS_PSP
	add di, 15
	call WRD_TO_HEX
	lea dx, ADRESS_PSP
	call WRITE_STRING
	mov ax,es:[3]
	lea si,STR_SIZE
	add si, 6
	call WRITE_SIZE
	lea dx,STR_SIZE
	call WRITE_STRING
	xor dx, dx
	lea dx , MCB_SD_SC
	call WRITE_STRING
	mov cx,8
	xor di,di

write_char:
	mov dl,es:[di+8]
	mov ah,02h
	int 21h
	inc di
	loop write_char

	mov ax,es:[3]
	mov bx,es
	add bx,ax
	inc bx
	mov es,bx
	pop ax
	pop cx
	inc cx
	cmp al,5Ah ; проверка на не последний ли это сегмент
	je exit
	cmp al,4Dh
	jne exit
	jmp pargraph_MCB

	exit:
   pop si
   pop dx
   pop cx
   pop bx
   pop ax
	 ret
PRINT_MCB ENDP

PRINT_MEM_SIZE proc near

  push ax
  push bx
  push si

  mov  AL,30h
  out 70h,AL
  in AL,71h
  mov BL,AL
  mov AL,31h
  out 70h,AL
  in AL,71h

  mov bh,al
  mov ax,bx
  lea si,EXTENDED_MEMORY
  add si, 27
  call WRITE_SIZE
  lea dx,EXTENDED_MEMORY
  call WRITE_STRING
  lea dx,STR_BYTE
  call WRITE_STRING

  pop si
  pop bx
  pop ax
  ret

PRINT_MEM_SIZE ENDP

PRINT_AVAILABLE_MEM_SIZE PROC near

  push ax
  push bx
  push si

;доступная память
  mov ah,4ah
  mov bx,0ffffh
  int 21h
  mov ax,bx
  lea si, ACCESSED_MEMORY
  add si, 27 ;смещение для числа
  call WRITE_SIZE
  lea dx, ACCESSED_MEMORY
  call WRITE_STRING
  lea dx,STR_BYTE
  call WRITE_STRING

  pop si
  pop bx
  pop si
  ret

PRINT_AVAILABLE_MEM_SIZE ENDP

; Код
BEGIN:
   ;доступная память
   call PRINT_AVAILABLE_MEM_SIZE
   ; расширенная память
   call PRINT_MEM_SIZE
   ;MCB
   call PRINT_MCB

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START