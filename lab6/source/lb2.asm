TESTPC	SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:	JMP BEGIN

SEG_INAC_MEMORY db 'Segment address of inaccessible memory:          ', 0DH, 0AH, '$'
SEG_ENV db 'Segment address of environment:          ', 0DH, 0AH, '$'
TAIL_COM db 'Tail of command string:                               ', 0DH, 0AH, '$'
ENV_SCOPE db 'Environment scope content: ', 0DH, 0AH, '$'
LOAD_PATH db 'Loadable module path: ', 0DH, 0AH, '$'
NULL_TAIL db 'Tail of command is empty! ', 0DH, 0AH, '$'
END_STRING db 0DH, 0AH, '$'

TETR_TO_HEX	PROC near
	and AL, 0Fh	
	cmp AL, 09
	jbe NEXT
	add AL, 07
NEXT:	
	add AL, 30h
	ret
	
TETR_TO_HEX	ENDP

BYTE_TO_HEX	PROC near
	push CX
	mov AH, AL
	call TETR_TO_HEX
	xchg AL, AH
	mov CL, 4
	shr AL, CL
	call TETR_TO_HEX
	pop CX
	ret
BYTE_TO_HEX	ENDP

WRD_TO_HEX	PROC near
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
WRD_TO_HEX	ENDP

BYTE_TO_DEC	PROC near
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
	je end_1
	or AL, 30h
	mov [SI], AL
end_1:
	pop DX
	pop CX
	ret
BYTE_TO_DEC	ENDP

PRINT_STRING	PROC near
	push AX
	mov ah, 09h
	int 21h
	pop AX
	ret
PRINT_STRING	ENDP

DATA_INAC_MEMORY	PROC near
	mov AX, DS:[02h]
	mov DI, offset SEG_INAC_MEMORY
	add DI, 43
	call WRD_TO_HEX
	mov DX, offset SEG_INAC_MEMORY
	call PRINT_STRING
	ret
DATA_INAC_MEMORY	ENDP

DATA_ENV	PROC near
	mov AX, DS:[2Ch]
	mov DI, offset SEG_ENV
	add DI, 35
	call WRD_TO_HEX
	mov DX, offset SEG_ENV
	call PRINT_STRING
	ret
DATA_ENV	ENDP

DATA_TAIL	PROC near
	xor CX, CX
	mov CL, DS:[80h]
	mov SI, offset TAIL_COM
	add SI, 25
	cmp CL, 0h
	je EMPTY
	xor DI, DI
	xor AX, AX
READ:
	mov AL, DS:[81h+DI]
	inc DI
	mov [SI], AL
	inc SI
	loop read
	mov DX, offset TAIL_COM
	jmp PRINT_TAIL
EMPTY:
	mov DX, offset NULL_TAIL
PRINT_TAIL:	
	call PRINT_STRING
	ret
DATA_TAIL	ENDP

DATA_CONTENT	PROC near
mov DX, offset ENV_SCOPE
	call PRINT_STRING
	xor DI, DI
	mov DS, DS:[2Ch]

READ_STRING:	
	cmp byte ptr [DI], 00h
	jz END_CONTENT
	mov DL, [DI]
	mov AH, 02h
	int 21h
	jmp FIND
	
END_CONTENT:
	cmp byte ptr [DI+1], 00h
	jz FIND
	push DS
	mov CX, CS
	mov DS, CX
	mov DX, offset END_STRING
	call PRINT_STRING
	pop DS

FIND:
	inc DI
	cmp word ptr [DI], 0001h
	jz PATH
	jmp READ_STRING
	
PATH:
	push DS
	mov AX, CS
	mov DS, AX
	mov DX, offset LOAD_PATH
	call PRINT_STRING
	pop DS
	add DI, 2
LOOP_PATH:
	cmp byte ptr [DI], 00h
	jz EXIT
	mov DL, [DI]
	mov AH, 02h
	int 21h
	inc DI
	jmp LOOP_PATH

EXIT:
	ret
DATA_CONTENT	ENDP

BEGIN:	
	xor AX, AX
	
	call DATA_INAC_MEMORY
	call DATA_ENV
	call DATA_TAIL
	call DATA_CONTENT

	xor AL, AL
    mov AH, 01h
    int 21h
	mov AH, 4Ch
	int 21h
	
TESTPC	ENDS
END START