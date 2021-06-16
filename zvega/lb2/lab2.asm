TESTPC SEGMENT
		ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
		ORG 100H
START:  JMP BEGIN


NOT_AVAILABLE_STRING db "Not available memory:     ",0dh,0ah,'$'
ADDRESS_STRING db "Environment address:     ",0dh,0ah,'$'
COMMAND_EMPTY_STRING db "Command tail empty",'$'
COMMAND_TAIL_STRING  db "Command tail:",'$'
NEW_LINE_STRING db 0dh,0ah,'$'
CONTENT_STRING db "Content:",0dh,0ah,'$'
PATH_STRING db "Path:",'$'


TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
NEXT:   add AL,30h
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


WRITE_STR proc near
		push ax
		mov ah,9h
		int 21h
		pop ax
		ret
WRITE_STR ENDP


PATH proc near
		push ax
		push cx
		push dx
		push di
	
		mov dx,offset PATH_STRING
		call WRITE_STR
		add  di,3 
loop_path:
		mov dl,es:[di]
		cmp dl,0
		je end_of_path
		mov ah,02h
		int 21h
		inc di
		jmp loop_path

end_of_path:
		pop ax
		pop cx
		pop dx
		pop di
		ret
PATH ENDP


NOT_AVAILABLE_MEMORY proc near
		push ax
		push dx
		push di

		mov ax,ds:[02h]
		mov di,offset NOT_AVAILABLE_STRING
		add di,25
		call WRD_TO_HEX
		mov dx,offset NOT_AVAILABLE_STRING
		call WRITE_STR
		
		pop ax
		pop dx
		pop di
		ret
NOT_AVAILABLE_MEMORY ENDP


ENVIRONMENT_ADDRESS proc near
		push ax
		push dx
		push di

		mov ax,ds:[02ch]
		mov di,offset ADDRESS_STRING
		add di,24
		call WRD_TO_HEX
		mov dx,offset ADDRESS_STRING
		call WRITE_STR
		
		pop ax
		pop dx
		pop di
		ret
ENVIRONMENT_ADDRESS ENDP


TAIL proc near
		push ax
		push cx
		push dx
		push di
		
		mov cL,ds:[080h]
		cmp cL,0
		je print_empty

		mov dx,offset COMMAND_TAIL_STRING
		call WRITE_STR

		mov ch,0
		mov di,0
loop_tail:
		mov dl,ds:[081h+di]
		mov ah,02h 
		int 21h

		inc di
		loop loop_tail
		jmp end_of_tail

print_empty:
		mov dx,offset COMMAND_EMPTY_STRING
		call WRITE_STR

end_of_tail:
		mov dx,offset NEW_LINE_STRING
		call WRITE_STR
		
		pop ax
		pop cx
		pop dx
		pop di
		ret
TAIL ENDP

CONTENT proc near
		push ax
		push cx
		push dx
		push di
		
		mov dx,offset CONTENT_STRING
		call WRITE_STR
	
		mov ax,ds:[2ch]
		mov es,ax
		mov di,0
cmp_new_line:
		mov dl,es:[di]
		cmp dl,0
		jz new_line
loop_new_line:
		mov ah,02h
		int 21h
		inc di
		jmp cmp_new_line
new_line:
		mov dx,offset NEW_LINE_STRING
		call WRITE_STR
		
		inc di
		mov dl,es:[di]
		cmp dl,0
		jnz loop_new_line

		mov dx,offset NEW_LINE_STRING
		call WRITE_STR
		call PATH
		
		pop ax
		pop cx
		pop dx
		pop di
		ret
CONTENT ENDP


BEGIN:
		call NOT_AVAILABLE_MEMORY
		call ENVIRONMENT_ADDRESS
		call TAIL
		call CONTENT
		
		xor AL,AL
		mov AH,4Ch
		int 21H
TESTPC ENDS
 END START 