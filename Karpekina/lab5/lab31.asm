TESTPC  SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 	ORG 100H
START:  JMP BEGIN

AVAILABLE_MEMORY DB 'Available memory: ', '$'
EXTENDED_MEMORY DB 'Extended memory: ', '$'
STR_BYTE DB ' byte ', '$'
MCB_TABLE DB 'MCB table: ', 0DH, 0AH, '$'
ADDRESS DB 'Address:     ', '$'
PSP_ADD DB 'PSP address:      ', '$'
STR_SIZE DB 'Size: ', '$'
SC_SD DB 'SC/SD: ', '$'
NEW_STR DB 0DH,0AH,'$'
SPACE_STR DB ' ', '$'

TETR_TO_HEX PROC near
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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

BYTE_TO_DEC PROC near
 	push CX
 	push DX
 	xor AH,AH
 	xor DX,DX
 	mov CX,10
loop_bd:div CX
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
end_l:  pop DX
 	pop CX
 	ret
BYTE_TO_DEC ENDP

PRINT_STR PROC near
	push ax
  mov ah, 09h
  int 21h
	pop ax
  ret
PRINT_STR endp

PAR_BYTE PROC
	mov bx, 0ah
	mov cx, 0
loop1:
	div bx
	push dx
	inc cx
	xor dx,dx
	cmp ax, 0
	jne loop1
print:
	pop dx
	add dl,30h
	mov ah,02h
	int 21h
	loop print
	ret
PAR_BYTE endp

MEMORY_AVAILABLE PROC near
	mov dx, offset AVAILABLE_MEMORY
	call PRINT_STR
	mov ah, 4ah
	mov bx, 0ffffh
	int 21h
	mov ax, bx
	mov bx, 16
	mul bx
	call PAR_BYTE
	mov dx, offset STR_BYTE
	call PRINT_STR
	mov dx, offset NEW_STR
	call PRINT_STR
	ret
MEMORY_AVAILABLE endp

MEMORY_EXTENDED proc near
	mov dx, offset EXTENDED_MEMORY
	call PRINT_STR

    mov al, 30h
    out 70h, al
   	in al, 71h
   	mov al, 31h
    out 70h, al
    in al, 71h

    mov ah, al
	mov bh, al
	mov ax, bx

	mov bx, 16
	mul bx

	call PAR_BYTE

	mov dx, offset NEW_STR
	call PRINT_STR

	ret
MEMORY_EXTENDED endp


MCB PROC near
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	mov dx, offset MCB_TABLE
	call PRINT_STR

MCB_loop:
    	mov ax, es
    	mov di, offset ADDRESS
    	add di, 12
    	call WRD_TO_HEX
    	mov dx, offset ADDRESS
    	call PRINT_STR
			mov dx, offset SPACE_STR
			call PRINT_STR

	mov ax, es:[1]
	mov di, offset PSP_ADD
	add di, 16
	call WRD_TO_HEX
	mov dx, offset PSP_ADD
	call PRINT_STR

	mov dx, offset STR_SIZE
	call PRINT_STR
	mov ax, es:[3]
	mov di, offset STR_SIZE
	add di, 6
	mov bx, 16
	mul bx
	call PAR_BYTE
	mov dx, offset SPACE_STR
	call PRINT_STR

	mov bx, 8
	mov dx, offset SC_SD
	call PRINT_STR
	mov cx, 7

loop2:
	mov dl, es:[bx]
	mov ah, 02h
	int 21h
	inc bx
	loop loop2
	mov dx, offset NEW_STR
 	call PRINT_STR
	mov bx, es:[3h]
	mov al, es:[0h]
	cmp al, 5ah
	je END_F
	mov ax, es
	inc ax
	add ax, bx
	mov es, ax
	jmp MCB_loop
END_F:
	ret
MCB endp



BEGIN:
	call MEMORY_AVAILABLE
	call MEMORY_EXTENDED
	call MCB
	mov al,0
  mov ah, 4ch
  int 21h
TESTPC ENDS

END START
