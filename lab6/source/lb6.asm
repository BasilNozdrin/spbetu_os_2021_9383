AStack segment stack
	DW 128 DUP(?)
AStack ENDS

DATA SEGMENT

	BLOCK DW 0
			DD 0
			DD 0
			DD 0

	SOURCE DB 'lb2.com', 0	
	MEMORY_FLAG DB 0
	CMD_L DB 1h, 0Dh
	CL_POSITION DB 128 dup(0)
	KEEP_SS DW 0
	KEEP_SP DW 0
	PSP DW 0

	CRASH_ERROR DB 'ERROR: mcb crashed', 0dh, 0AH, '$' 
	NO_MEMORY_ERROR DB 'ERROR: there is not enough memory to execute this function', 0dh, 0AH, '$' 
	ADDRESS_ERROR DB 'ERROR: invalid memory address', 0dh, 0AH, '$'
	FREE_MEMORY DB 'Memory has been successfully freed' , 0dh, 0AH, '$'

	FUNCTION_NUMBER_ERROR DB 'ERROR: invalid function number', 0dh, 0AH, '$' 
	FILE_ERROR DB 'ERROR: file not found', 0Dh, 0Ah, '$' 
	DISK_ERROR DB 'ERROR: disk ERROR', 0dh, 0AH, '$' 
	MEMORY_ERROR DB 'ERROR: insufficient memory', 0dh, 0AH, '$' 
	ENV_ERROR DB 'ERROR: wrong string of environment ', 0dh, 0AH, '$' 
	FORMAT_ERROR DB 'ERROR: wrong format', 0dh, 0AH, '$' 
	
	STANDART_END DB 0dh, 0AH, 'Program ended with code    ' , 0dh, 0AH, '$'
	CTRL_END DB 0dh, 0AH, 'Program ended by ctrl-break' , 0dh, 0AH, '$'
	DEVICE_ERROR DB 0dh, 0AH, 'Program ended by device ERROR' , 0dh, 0AH, '$'
	INTERRUPT_END DB 0dh, 0AH, 'Program ended by int 31h' , 0dh, 0AH, '$'

	END_DATA DB 0
DATA ENDS

CODE SEGMENT

ASSUME CS:CODE, DS:DATA, SS:AStack

PRINT_STR PROC 
 	push AX
 	mov AH, 09h
 	int 21h 
 	pop AX
 	ret
PRINT_STR ENDP 

FREE_MEMORY_FUNCTION PROC 
	push AX
	push BX
	push CX
	push DX
	
	mov AX, offset END_DATA
	mov BX, offset ending
	add BX, AX
	
	mov CL, 4
	shr BX, CL
	add BX, 2Bh
	mov AH, 4Ah
	int 21h 

	jnc end_free
	mov MEMORY_FLAG, 1
	
mcb_crash:
	cmp AX, 7
	jne not_enought_memory
	mov DX, offset CRASH_ERROR
	call PRINT_STR
	jmp free	

not_enought_memory:
	cmp AX, 8
	jne addr
	mov DX, offset NO_MEMORY_ERROR
	call PRINT_STR
	jmp free	

addr:
	cmp AX, 9
	mov DX, offset ADDRESS_ERROR
	call PRINT_STR
	jmp free

end_free:
	mov MEMORY_FLAG, 1
	mov DX, offset FREE_MEMORY
	call PRINT_STR
	
free:
	pop DX
	pop CX
	pop BX
	pop AX
	ret
FREE_MEMORY_FUNCTION ENDP

LOAD PROC 
	push AX
	push BX
	push CX
	push DX
	push DS
	push ES
	mov KEEP_SP, SP
	mov KEEP_SS, SS
	mov AX, data
	mov ES, AX
	mov BX, offset BLOCK
	mov DX, offset CMD_L
	mov [BX+2], DX
	mov [BX+4], DS 
	mov DX, offset CL_POSITION
	
	mov AX, 4b00h 
	int 21h 
	
	mov SS, KEEP_SS
	mov SP, KEEP_SP
	pop ES
	pop DS
	
	jnc loads
	
	cmp AX, 1
	jne _FILE_ERROR
	mov DX, offset FUNCTION_NUMBER_ERROR
	call PRINT_STR
	jmp load_end

_FILE_ERROR:
	cmp AX, 2
	jne _DISK_ERROR
	mov DX, offset FILE_ERROR
	call PRINT_STR
	jmp load_end

_DISK_ERROR:
	cmp AX, 5
	jne _MEMORY_ERROR
	mov DX, offset DISK_ERROR
	call PRINT_STR
	jmp load_end

_MEMORY_ERROR:
	cmp AX, 8
	jne _ENV_ERROR
	mov DX, offset MEMORY_ERROR
	call PRINT_STR
	jmp load_end

_ENV_ERROR:
	cmp AX, 10
	jne _FORMAT_ERROR
	mov DX, offset ENV_ERROR
	call PRINT_STR
	jmp load_end

_FORMAT_ERROR:
	cmp AX, 11
	mov DX, offset FORMAT_ERROR
	call PRINT_STR
	jmp load_end

loads:
	mov AH, 4Dh
	mov AL, 00h
	int 21h 
	
_nend:
	cmp AH, 0
	jne ctrlc
	push DI 
	mov DI, offset STANDART_END
	mov [DI+26], AL 
	pop SI
	mov DX, offset STANDART_END
	call PRINT_STR 
	jmp load_end

ctrlc:
	cmp AH, 1
	jne device
	mov DX, offset CTRL_END 
	call PRINT_STR 
	jmp load_end

device:
	cmp AH, 2 
	jne int_31h
	mov DX, offset DEVICE_ERROR
	call PRINT_STR 
	jmp load_end

int_31h:
	cmp AH, 3
	mov DX, offset INTERRUPT_END
	call PRINT_STR 

load_end:
	pop DX
	pop CX
	pop BX
	pop AX
	ret
LOAD ENDP

PATH PROC 
	push AX
	push BX
	push CX 
	push DX
	push DI
	push SI
	push ES
	
	mov AX, PSP
	mov ES, AX
	mov ES, ES:[2ch]
	mov BX, 0
	
findz:
	inc BX
	cmp byte ptr ES:[BX-1], 0
	jne findz
	cmp byte ptr ES:[BX+1], 0 
	jne findz
	
	add BX, 2
	mov DI, 0
	
_loop:
	mov dl, ES:[BX]
	mov byte ptr [CL_POSITION+DI], dl
	inc DI
	inc BX
	cmp dl, 0
	je end_loop 
	cmp dl, '\'
	jne _loop
	mov CX, DI
	jmp _loop
end_loop:
	mov DI, CX
	mov SI, 0
	
_fn:
	mov dl, byte ptr [SOURCE + SI]
	mov byte ptr [CL_POSITION+DI], dl
	inc DI 
	inc SI
	cmp dl, 0 
	jne _fn
		
	
	pop ES
	pop SI
	pop DI
	pop DX
	pop CX
	pop BX
	pop AX
	ret
PATH ENDP

MAIN PROC FAR
	push DS
	xor AX, AX
	push AX
	mov AX, DATA
	mov DS, AX
	mov PSP, ES
	call FREE_MEMORY_FUNCTION 
	cmp MEMORY_FLAG, 0
	je _end
	call PATH
	call LOAD
_end:
	xor AL, AL
	mov AH, 4Ch
	int 21h
	
ending:

MAIN      ENDP
CODE ENDS
END MAIN
