TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H

START: jmp BEGIN

MEMORY_ADDRESS db 'Unavailable memory:     h',13,10, 13, 10, '$'
ENV_ADDRESS db 'Environment address:     h',13,10,'$'
NOT_EMPTY_TAIL db 'Command line tail:        ',13,10,'$'
EMPTY_TAIL_STR db 'Command tail is empty',13,10,'$'
CONTENT_STR db 'Content:',13,10, '$'
END_OF_LINE db 13, 10, '$'
PATH db 'Loadable module path:  ',13,10,'$'



TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
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



WRITE_STRING PROC near
   mov AH,09h
   int 21h
   ret
WRITE_STRING ENDP



UNAVAILABLE_MEMORY PROC near
   mov ax,ds:[02h]
   mov di, offset MEMORY_ADDRESS
   add di, 26
   call WRD_TO_HEX
   mov dx, offset MEMORY_ADDRESS
   call WRITE_STRING
   ret
UNAVAILABLE_MEMORY ENDP


ENVIROMENT_ADDRESS  PROC near
   mov ax,ds:[2Ch]
   mov di, offset ENV_ADDRESS
   add di, 24
   call WRD_TO_HEX
   mov dx, offset ENV_ADDRESS
   call WRITE_STRING
   ret
ENVIROMENT_ADDRESS ENDP


COMMAND_LINE_TAIL PROC near
  xor cx, cx
	mov cl, ds:[80h]
	mov si, offset NOT_EMPTY_TAIL
	add si, 19
  cmp cl, 0h
  je empty_tail
	xor di, di
	xor ax, ax

next_tail:
	mov al, ds:[81h+di]
  inc di
  mov [si], al
	inc si
	loop next_tail

	mov dx, offset NOT_EMPTY_TAIL
	jmp TAIL_END

empty_tail:
		mov dx, offset EMPTY_TAIL_STR

TAIL_END:
   call WRITE_STRING
   ret

COMMAND_LINE_TAIL ENDP



CONTENT PROC near
   mov dx, offset CONTENT_STR
   call WRITE_STRING
   xor di,di
   mov ds, ds:[2Ch]

READ_LINE:
	cmp byte ptr [di], 00h
	jz END_LINE
	mov dl, [di]
	mov ah, 02h
	int 21h
	jmp find_end

END_LINE:
  cmp byte ptr [di+1],00h
  jz FIND_END
  push ds
  mov cx, cs
	mov ds, cx
	mov dx, offset END_OF_LINE
	call WRITE_STRING
	pop ds

FIND_END:
	inc di
	cmp word ptr [di], 0001h
	jz PATH_READING
	jmp READ_LINE

PATH_READING:
	push ds
	mov ax, cs
	mov ds, ax
	mov dx, offset PATH
	call WRITE_STRING
	pop ds
	add di, 2

LOOP_PATH:
	cmp byte ptr [di], 00h
	jz EXIT
	mov dl, [di]
	mov ah, 02h
	int 21h
	inc di
	jmp LOOP_PATH

EXIT:
	ret
CONTENT ENDP


BEGIN:
  call UNAVAILABLE_MEMORY
  call ENVIROMENT_ADDRESS
  call COMMAND_LINE_TAIL
  call CONTENT

  xor AL,AL
  mov AH,4Ch
  int 21H

TESTPC ENDS
END START
