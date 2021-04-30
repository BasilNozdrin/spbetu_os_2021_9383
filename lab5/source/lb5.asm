AStack	SEGMENT STACK
	DB 256 DUP(?)
AStack ENDS

DATA	SEGMENT

    count DB '0000' 
	INT_LOAD DB 'My interrupt has been unloaded!', 13,  10, '$'
	INT_UNLOAD DB 'My interrupt has been unloaded!', 13,  10, '$'
	INT_NOT_LOAD DB 'My interrupt has not been loaded!', 13,  10, '$'
	INT_ALREADY_LOAD DB 'My interrupt has already been loaded!', 13,  10, '$'

DATA	ENDS

CODE	SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

MY_INTERRUPT	PROC far
	jmp start_interrupt

	PSP DW ?
	KEEP_IP DW 0
	KEEP_CS DW 0
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0
	KEY_CODE DB 01h
	KEY_VALUE DB 0
	
	INT_STACK DW 128 DUP (?)
END_INT_STACK:

start_interrupt:
	mov KEEP_AX, AX
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	mov AX, CS
	mov SS, AX
	mov SP, OFFSET END_INT_STACK
	mov AX, KEEP_AX
	push AX
	push DX
	push DS
	push ES
	
	 
	in AL, 60h
	cmp AL, KEY_CODE
	je key_esc
	cmp AL, 1Eh
	je key_a
	cmp AL, 30h
	je key_b
	cmp AL, 2Eh
	je key_c   
    pushf
    call dword ptr CS:KEEP_IP
    jmp end_interrupt

key_esc:
        mov KEY_VALUE, '*'
        jmp print_key

key_a:
        mov KEY_VALUE, '1'
        jmp print_key

key_b:
        mov KEY_VALUE, '2'
        jmp print_key

key_c:
        mov KEY_VALUE, '3'
        jmp print_key

next_key: 
	push AX
	in AL, 61h 
	mov AH, AL 
	or AL, 80h 
	out 61h, AL 
	xchg AH, AL 
	out 61h, AL 
	mov AL, 20h 
	out 20h, AL 
	pop AX
	
print_key: 
	mov AH, 05h 
	mov CL, KEY_VALUE 
	mov ch, 00h
	int 16h
	or AL, AL 
	jz end_interrupt 
	mov AX, 0040h
	mov ES, AX
	mov AX, ES:[1Ah] 
	mov ES:[1Ch], AX 
	jmp print_key

end_interrupt:
	pop ES 
	pop DS
	pop DX
	pop AX 
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	mov AX, KEEP_AX
	mov AL, 20h
	out 20h, AL
	iret
ending:
MY_INTERRUPT ENDP


SET_INTERRUPT PROC 
	push AX
	push DX
	push DS
	mov AH, 35h 
	mov AL, 09h 
	int 21h
	mov KEEP_IP, BX	
	mov KEEP_CS, ES 
	mov DX, OFFSET MY_INTERRUPT
	mov AX, SEG MY_INTERRUPT 
	mov DS, AX 
	mov AH, 25h 
	mov AL, 09h 
	int 21h 
	pop DS
	mov DX, OFFSET INT_LOAD
	call PRINT_STRING
	pop DX
	pop AX
	ret
SET_INTERRUPT ENDP 

DELETE_INTERRUPT PROC 
	push AX
	push DS
	CLI
	mov AH, 35h
	mov AL, 09h
	int 21h
	mov SI, OFFSET KEEP_IP
	sub SI, OFFSET MY_INTERRUPT
	mov DX, ES:[BX+SI]
	mov AX, ES:[BX+SI+2]
	mov DS, AX
	mov AH, 25h
	mov AL, 09h
	int 21h
	pop DS
	mov AX, ES:[BX+SI-2]
	mov ES, AX
	mov AX, ES:[2Ch]
	push ES
	mov ES, AX
	mov AH, 49h
	int 21h
	pop ES
	mov AH, 49h
	int 21h
	STI
	pop AX
	ret
DELETE_INTERRUPT ENDP 

MY_FUNC PROC 
	mov AH, 35h 
	mov AL, 09h 
	int 21h 
				
	mov SI, OFFSET count
	sub SI, OFFSET MY_INTERRUPT 
	
	mov AX, '00' 
	cmp AX, ES:[BX+SI] 
	jne NOT_LOADED 
	cmp AX, ES:[BX+SI+2] 
	jne NOT_LOADED
	jmp LOADED 
	
NOT_LOADED: 
	call SET_INTERRUPT 
	mov DX, OFFSET ending 
	mov CL, 4 
	shr DX, CL
	inc DX	
	add DX, CODE 
	sub DX, PSP 
	xor AL, AL
	mov AH, 31h 
	int 21h 
		
LOADED: 
	push ES
	push AX
	mov AX, PSP 
	mov ES, AX
	mov AL, ES:[81h+1]
	cmp AL, '/'
	jne NOT_UNLOAD 
	mov AL, ES:[81h+2]
	cmp AL, 'u'
	jne NOT_UNLOAD 
	mov AL, ES:[81h+3]
	cmp AL, 'n'
	je UNLOAD 
	
NOT_UNLOAD: 
	pop AX
	pop ES
	mov DX, OFFSET INT_ALREADY_LOAD
	call PRINT_STRING
	ret

UNLOAD: 
	pop AX
	pop ES
	call DELETE_INTERRUPT 	
	mov DX, OFFSET INT_UNLOAD
	call PRINT_STRING
	ret
MY_FUNC ENDP

PRINT_STRING PROC NEAR  
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT_STRING ENDP

MAIN PROC Far
	mov AX, DATA
	mov DS, AX
	mov PSP, ES 
	call MY_FUNC
	xor AL, AL
	mov AH, 4Ch 
	int 21H
MAIN ENDP
CODE ENDS

END MAIN 
