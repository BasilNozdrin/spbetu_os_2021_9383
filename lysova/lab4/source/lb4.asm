AStack SEGMENT STACK
	db 256 DUP(?)
AStack ENDS

DATA SEGMENT
	Not_loaded db "My interrupt has not been loaded!", 0DH, 0AH, '$'
	Restored db "My interrupt has been unloaded!", 0DH, 0AH, '$'
	Loaded db "My interrupt has been loaded!", 0DH, 0AH, '$'
	Load_process db "My interrupt has already been loaded!", 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

NEW_INTERRUPTION PROC FAR
	jmp START_FUNC

	PSP_ADDRESS_0 DW 0
	PSP_ADDRESS_1 DW 0
	KEEP_CS DW 0
	KEEP_IP DW 0
	NEW_INTERRUPTION_SET DW 7777h
	INT_COUNT DB 'My interrupt: 0000 $'

	KEEP_SS DW ?
	KEEP_SP DW ?
	KEEP_AX DW ?
	INT_STACK DW 64 dup (?)
	END_INT_STACK DW ?

START_FUNC:

	mov KEEP_SS, SS
	mov KEEP_SP, SP
	mov KEEP_AX, AX
	mov AX, CS
	mov SS, AX
	mov SP, OFFSET END_INT_STACK

	push AX
	push BX
	push CX
	push DX

	mov AH, 03h
	mov BH, 00h
	int 10h
	push DX

	mov AH, 02h
	mov BH, 00h
	mov DH, 2h
	mov DL, 5h
	int 10h

	push SI
	push CX
	push DS
	mov AX, SEG INT_COUNT
	mov DS, AX
	mov SI, OFFSET INT_COUNT
	add SI, 11h

	mov AH, [SI]
	inc AH
	mov [SI], AH
	cmp AH, 3Ah
	jne END_CALC
	mov AH, 30h
	mov [SI], AH

	mov BH, [SI - 1]
	inc BH
	mov [SI - 1], BH
	cmp BH, 3Ah
	jne END_CALC
	mov BH, 30h
	mov [SI - 1], BH

	mov CH, [SI - 2]
	inc CH
	mov [SI - 2], CH
	cmp CH, 3Ah
	jne END_CALC
	mov CH, 30h
	mov [SI - 2], CH

	mov DH, [SI - 3]
	inc DH
	mov [SI - 3], DH
	cmp DH, 3Ah
	jne END_CALC
	mov DH, 30h
	mov [SI - 3], DH

END_CALC:
    pop DS
    pop CX
    pop SI

    push ES
    push BP
	
    mov AX, SEG INT_COUNT
    mov es, ax
    mov ax, offset INT_COUNT
    mov bp, ax
    mov ah, 13h
    mov al, 00h
    mov cx, 1Dh
    mov bh, 0
    int 10h
    pop bp
    pop es

    pop dx
    mov ah, 02h
    mov bh, 0h
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax

    mov ss, KEEP_SS
    mov ax, KEEP_AX
    mov sp, KEEP_SP
    mov AL, 20H
    out 20H, AL

    iret
NEW_INTERRUPTION ENDP

NEED_MEM_AREA PROC
NEED_MEM_AREA ENDP

IS_INTERRUPTION_SET PROC NEAR
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov dx, es:[bx + 11]
	cmp dx, 0FEDCh
	je INT_IS_SET
	mov al, 00h
	jmp POP_REG

INT_IS_SET:
	mov al, 01h
	jmp POP_REG

POP_REG:
	pop es
	pop dx
	pop bx

	ret
IS_INTERRUPTION_SET ENDP

CHECK_COMMAND_PROMT PROC NEAR
	push es

	mov ax, PSP_ADDRESS_0
	mov es, ax

	mov bx, 0082h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'u'
	jne NULL_CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'n'
	jne NULL_CMD

	mov al, 0001h
NULL_CMD:
	pop es

	ret
CHECK_COMMAND_PROMT ENDP

LOAD_INTERRUPTION PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	mov KEEP_IP, bx
	mov KEEP_CS, es

	push ds
		mov dx, offset NEW_INTERRUPTION
		mov ax, seg NEW_INTERRUPTION
		mov ds, ax

		mov ah, 25h
		mov al, 1Ch
		int 21h
	pop ds

	mov dx, offset Load_process
	call PRINT_STRING

	pop es
	pop dx
	pop bx
	pop ax

	ret
LOAD_INTERRUPTION ENDP

UNLOAD_INTERRUPTION PROC NEAR
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h

	cli
	push ds
		mov dx, es:[bx + 9]
		mov ax, es:[bx + 7]

		mov ds, ax
		mov ah, 25h
		mov al, 1Ch
		int 21h
	pop ds
	sti

	mov dx, offset Restored
	call PRINT_STRING

	push es
		mov cx, es:[bx + 3]
		mov es, cx
		mov ah, 49h
		int 21h
	pop es

	mov cx, es:[bx + 5]
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax

	ret
UNLOAD_INTERRUPTION ENDP

PRINT_STRING PROC NEAR
	push ax
	mov ah, 09h
	int	21h
	pop ax
	ret
PRINT_STRING ENDP

MAIN PROC FAR
	mov bx, 02Ch
	mov ax, [bx]
	mov PSP_ADDRESS_1, ax
	mov PSP_ADDRESS_0, ds
	sub ax, ax
	xor bx, bx

	mov ax, DATA
	mov ds, ax

	call CHECK_COMMAND_PROMT
	cmp al, 01h
	je UNLOAD_START

	call IS_INTERRUPTION_SET
	cmp al, 01h
	jne INTERRUPTI0N_IS_NOT_LOADED

	mov dx, offset Loaded
	call PRINT_STRING
	jmp EXIT

	mov ah,4Ch
	int 21h

INTERRUPTI0N_IS_NOT_LOADED:
	call LOAD_INTERRUPTION

	mov dx, offset NEED_MEM_AREA
	mov cl, 04h
	shr dx, cl
	add dx, 1Bh

	mov ax, 3100h
	int 21h

UNLOAD_START:
	call IS_INTERRUPTION_SET
	cmp al, 00h
	je INT_IS_NOT_SET
	call UNLOAD_INTERRUPTION
	jmp EXIT

INT_IS_NOT_SET:
	mov dx, offset Not_loaded
	call PRINT_STRING
    jmp EXIT

EXIT:
	mov ah, 4Ch
	int 21h
MAIN ENDP

CODE ENDS

END MAIN

