ASTACK SEGMENT STACK
	db 256 DUP(?)
ASTACK ENDS

DATA SEGMENT

	SYSTEM_VERSION db '	SYSTEM VERSION:  .   ',0DH, 0AH, '$'
	OEM db '	OEM SERIAL NUMBER:    ',0DH, 0AH, '$'
	SERIAL_NUMBER db '	USER SERIAL NUMBER:             ',0DH, 0AH, '$'
	VERSION db 'VERSION MS DOS: ', 0DH, 0AH, '$'
	
	TYPE_PC db 'TYPE OF IBM PC:	PC', 0DH, 0AH, '$'
	TYPE_PC_XT db 'TYPE OF IBM PC:	PC/XT', 0DH, 0AH, '$'
	TYPE_AT db 'TYPE OF IBM PC:	AT', 0DH, 0AH, '$'
	TYPE_PS2 db 'TYPE OF IBM PC:	PS2 model 30', 0DH, 0AH, '$'
	TYPE_PS2_80 db 'TYPE OF IBM PC:	PS2 model 80', 0DH, 0AH, '$'
	TYPE_PCjr db 'TYPE OF IBM PC:	PCjr', 0DH, 0AH, '$'
	TYPE_PC_conv db 'TYPE OF IBM PC:	PC Convertible', 0DH, 0AH, '$'

	ERROR db 'Error: The received byte does not match any type! ', 0DH, 0AH, '$'

DATA ENDS

TESTPC	SEGMENT
	ASSUME CS:TESTPC, DS:DATA, SS:ASTACK

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

PRINT_TYPE	PROC near
	push AX
	push ES
	push DX
	
	mov AX, 0F000h
	mov ES, AX
	mov AL, ES:[0FFFEh]
	
	cmp al, 0FFh
	je PC
	
	cmp al, 0FEh
	je PC_XT
	
	cmp al, 0FBh
	je PC_XT
	
	cmp al, 0FCh
	je AT

	cmp al, 0FAh
	je PS2_30
	
	cmp al, 0F8h
	je PS2_80
	
	cmp al, 0FDh
	je PCjr
	
	cmp al, 0F9h
	je PC_Conv
	
PC:
	mov DX, offset TYPE_PC
	jmp END_PRINT
	
PC_XT:
	mov DX, offset TYPE_PC_XT
	jmp END_PRINT
	
AT:
	mov DX, offset TYPE_AT
	jmp END_PRINT
	
PS2_30:
	mov DX, offset TYPE_PS2
	jmp END_PRINT
	
PS2_80:
	mov DX, offset TYPE_PS2_80
	jmp END_PRINT
	
PCjr:
	mov DX, offset TYPE_PCjr
	jmp END_PRINT
	
PC_Conv:
	mov DX, offset TYPE_PC_Conv
	jmp END_PRINT
	
	mov DX, offset ERROR
	
END_PRINT:
	call PRINT_STRING
	pop DX
	pop ES
	pop AX
	ret
	
PRINT_TYPE	ENDP

VERSION_DOS	PROC near
	push AX
	push DX
	
	mov AH, 30h
	int 21h
	
	push AX
	push SI
	
	lea SI, SYSTEM_VERSION
	add SI, 17
	call BYTE_TO_DEC
	add SI, 3
	mov AL, AH
	call BYTE_TO_DEC
	
	mov DX, offset SYSTEM_VERSION
	call PRINT_STRING
	
	pop SI
	pop AX
	
	
	;----------------------------------------
	push AX
	push SI
	
	mov AL, BH
	lea SI, OEM
	add SI, 22
	call BYTE_TO_DEC
	
	mov DX, offset OEM
	call PRINT_STRING
	
	pop SI
	pop AX
	;----------------------------------------
	push AX
	push DI
	
	mov AL, BL
	call BYTE_TO_HEX
	lea DI, SERIAL_NUMBER
	add DI, 21
	mov [DI], AX
	mov AX, CX
	lea DI, SERIAL_NUMBER
	add DI, 25
	call WRD_TO_HEX
	
	mov DX, offset SERIAL_NUMBER
	call PRINT_STRING
	
	pop DI
	pop AX
	;----------------------------------------
	
	pop DX
	pop AX
	ret

VERSION_DOS	ENDP
	

BEGIN PROC far	

	sub AX, AX
	mov AX, DATA
	mov DS, AX
	
	call PRINT_TYPE
	mov DX, offset VERSION
	call PRINT_STRING
	call VERSION_DOS
	
	xor AL, AL
	mov AH, 4Ch
	int 21h
	ret
	
BEGIN	ENDP
TESTPC	ENDS
	END BEGIN
	
