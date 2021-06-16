AStack SEGMENT STACK
	DW 128h DUP (0)
AStack ENDS

DATA SEGMENT
	PSP DW 0
    
	OVL_SEGMENT DW 0
	ADDRESS_OVL 	DD 0

	NO_PATH  DB 13, 10, "Path wasn't found$"
	LOAD_ERROR  DB 13, 10, "Overlay wasn't load$"
	OVERLAY1  DB 13, 10, "Overlay1: $"
	OVERLAY2  DB 13, 10, "Overlay2: $"
	MEMORY_FREE	 DB 13, 10, "Memory successfully free$"
	SIZE_ERROR  DB 13, 10, "Overlay size wasn't get$"
	NO_FILE  DB 13, 10, "File wasn't found$"
	OVL1  DB "ovl1.ovl", 0
	OVL2  DB "ovl2.ovl", 0

	PATH  DB 128h DUP(0)

	OFFSET_OVL_NAME  DW 0
	NAME_POS  DW 0
	MEMORY_ERROR  DW 0
	
	DTA_BUFFER  DB 43 DUP(0)
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

PRINT_STRING  PROC	near
	push 	AX
	mov 	AH, 09h
	int		21h
	pop 	AX
	ret
PRINT_STRING	ENDP

MEM_FREE	PROC near
	lea 	BX, PROGEND
	mov 	AX, ES
	sub 	BX, AX
	mov 	CL, 8
	shr 	BX, CL
	sub 	AX, AX
	mov 	AH, 4Ah
	int 	21h
	jc 		MCATCH
	mov 	DX, offset MEMORY_FREE
	call	PRINT_STRING
	jmp 	MDEFAULT
MCATCH:
	mov 	MEMORY_ERROR, 1
MDEFAULT:
    ret
MEM_FREE	ENDP


OVERLAY PROC near
	push	AX
	push	BX
	push	CX
	push	DX
	push	SI

	mov 	OFFSET_OVL_NAME, AX
	mov 	AX, PSP
	mov 	ES, AX
	mov 	ES, ES:[2Ch]
	mov 	SI, 0
zero_find:
	mov 	AX, ES:[SI]
	inc 	SI
	cmp 	AX, 0
	jne 	zero_find
	add 	SI, 3
	mov 	DI, 0
write_path:
	mov 	AL, ES:[SI]
	cmp 	AL, 0
	je 		write_name_of_path
	cmp 	AL, '\'
	jne 	new_symbol
	mov 	NAME_POS, DI
new_symbol:
	mov 	BYTE PTR [PATH + DI], AL
	inc 	DI
	inc 	SI
	jmp 	write_path
write_name_of_path:
	cld
	mov 	DI, NAME_POS
	inc 	DI
	add 	DI, offset PATH
	mov 	SI, OFFSET_OVL_NAME
	mov 	AX, DS
	mov 	ES, AX
UPDATE:
	lodsb
	stosb
	cmp 	AL, 0
	jne 	UPDATE
	mov 	AX, 1A00h
	mov 	DX, offset DTA_BUFFER
	int 	21h
	
	mov 	AH, 4Eh
	mov 	CX, 0
	mov 	DX, offset PATH
	int 	21h
	
	jnc 	no_error
	mov 	DX, offset SIZE_ERROR
	call 	PRINT_STRING
	cmp 	AX, 2
	je 		jmp_no_file
	cmp 	AX, 3
	je 		jmp_no_path
	jmp 	path_end
jmp_no_file:
	mov 	DX, offset NO_FILE
	call 	PRINT_STRING
	jmp 	path_end
jmp_no_path:
	mov 	DX, offset NO_PATH
	call 	PRINT_STRING
	jmp 	path_end
no_error:
	mov 	SI, offset DTA_BUFFER
	add 	SI, 1Ah
	mov 	BX, [SI]
	mov 	AX, [SI + 2]
	mov		CL, 4
	shr 	BX, CL
	mov		CL, 12
	shl 	AX, CL
	add 	BX, AX
	add 	BX, 2
	mov 	AX, 4800h
	int 	21h
	
	jnc 	set_segment
	jmp 	path_end
set_segment:
	mov 	OVL_SEGMENT, AX
	mov 	DX, offset PATH
	push 	DS
	pop 	ES
	mov 	BX, offset OVL_SEGMENT
    mov 	AX, 4B03h
	int 	21h

	jnc 	load_success		
	mov 	DX, offset LOAD_ERROR
	call 	PRINT_STRING
	jmp		path_end

load_success:
	mov		AX, OVL_SEGMENT
	mov 	ES, AX
	mov 	WORD PTR ADDRESS_OVL + 2, AX
	call 	ADDRESS_OVL
	mov 	ES, AX
	mov 	AH, 49h
	int 	21h

path_end:
	pop 	SI
	pop 	DX
	pop 	CX
	pop 	BX
	pop 	AX
	ret
OVERLAY ENDP
	
MAIN PROC 
	mov 	AX, DATA
	mov 	DS, AX
	mov 	PSP, ES
	call 	MEM_FREE
	cmp 	MEMORY_ERROR, 1
	je 		ending
	mov 	DX, offset OVERLAY1
	call	PRINT_STRING
	mov 	AX, offset OVL1
	call 	OVERLAY
	mov 	DX, offset OVERLAY2
	call	PRINT_STRING
	mov 	AX, offset OVL2
	call 	OVERLAY
		
ending:
	mov AX, 4C00h
	int 21h
PROGEND:

MAIN ENDP
CODE ENDS
END     MAIN