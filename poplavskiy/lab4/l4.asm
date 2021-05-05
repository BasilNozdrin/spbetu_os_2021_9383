CODE SEGMENT

ASSUME CS:CODE, DS:DATA, ES:NOTHING, SS:AStack

printSTR PROC 
	push AX
	push BX
	push CX
	mov AH, 09h
	mov BH, 0
	mov CX, 1
	int 10h
	pop CX
	pop BX
	pop AX
	ret
printSTR ENDP

getCurs  PROC
	push AX
	push BX
	mov AH, 03h
	mov BH, 0
	int 10h
	pop BX
	pop AX
	ret
getCurs  ENDP

setCurs  PROC
	push AX
	push BX
	mov AH, 02h
	mov BH, 0
	int 10h	
	pop BX
	pop AX
	ret
setCurs  ENDP

ROUT PROC FAR
	jmp ROUT_START
	flag DW 1274h
	KEEP_IP DW 0 
	KEEP_CS DW 0 
	KEEP_PSP dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw 0
	count db 48
	inter_stack dw 200 dup(?)

SET_INTERRUPT:

ROUT_START:
	mov KEEP_SS, ss 
	mov KEEP_SP, sp 
	mov KEEP_AX, ax 
	mov ax, seg inter_stack 
	mov ss, ax 
	mov sp, offset SET_INTERRUPT	
	push AX
	push BX
	push CX
	push DX
	push ES
	inc count
	cmp count, 57 
	jne END_COUNT
	mov count, 48

END_COUNT:
	call getCurs
	mov CX, DX
	mov DH, 23
	mov Dl, 33
	call setCurs
	push AX
	mov AL, count
	call printSTR
	pop AX
	mov DX, CX
	call setCurs
	mov AL, 20h
	out 20h, AL
	pop ES
	pop DX
	pop CX
	pop BX
	pop AX
	mov sp, KEEP_SP
	mov ax, KEEP_SS
	mov ss, ax
	mov ax, KEEP_AX
	mov al, 20h
	out 20h, al	
	iret 
	
ROUT ENDP

LAST_BYTE:

BASE_FUNC PROC
	push BX
	push DX
	push SI
	push ES
	mov AH, 35h
	mov AL, 1Ch
	int 21h
	lea SI, flag
	sub SI, offset ROUT 
	mov AX, 1
	mov BX, ES:[BX+SI]
	cmp BX, flag
	je END_ROUT
	mov AX, 0

END_ROUT:
	pop ES
	pop SI
	pop DX
	pop BX
	ret

BASE_FUNC ENDP

CHECK_UN PROC
	cmp byte ptr ES:[82h], '/'
	jne CHECK_TAIL
	cmp byte ptr ES:[83h], 'u'
	jne CHECK_TAIL
	cmp byte ptr ES:[84h], 'n'
	jne CHECK_TAIL
	mov BX, 1

CHECK_TAIL:
	ret

CHECK_UN ENDP

UNLOAD PROC 
	push ax
	push bx
	push dx
	push es
	push si
	cli
	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov si, offset KEEP_IP
	sub si, offset ROUT 
	push ds
	mov dx, es:[bx+si]
	mov ax, es:[bx+si+2]
	mov ds, ax
	mov ah, 25h
	mov al, 1Ch
	int 21h
	pop ds
	mov ax, es:[bx+si+4]
	mov es, ax
	push es
	mov ax, es:[2Ch]
	mov es, ax
	mov ah, 49h
	int 21h
	pop es
	mov ah, 49h
	int 21h
	sti
	pop si
	pop es
	pop dx
	pop bx
	pop ax
	ret
UNLOAD ENDP

LOAD PROC	
	push ax
	push bx
	push es
	push dx
	mov AH, 35h
	mov AL, 1Ch 
	int 21h
	mov KEEP_IP , BX
	mov KEEP_CS , ES
	push DS
	mov DX, offset ROUT
	mov AX, seg ROUT 	    
	mov DS, AX
	mov AH, 25h		 
	mov AL, 1Ch         	
    int 21h
	pop ds
	mov DX,offset LAST_BYTE
	mov CL,4
	shr DX,CL
	inc DX
	add dx,10h
	mov AH,31h
	int 21h
	pop dx
	pop es
	pop bx
	pop ax
	ret
LOAD ENDP

PRINT PROC
	push AX
	mov AH, 09h
	int 21h
	pop AX
	ret
PRINT ENDP

MAIN PROC
	PUSH DS
	SUB AX, AX
	SUB BX, BX
	PUSH AX
	MOV AX, DATA
	MOV DS, AX
	mov KEEP_PSP, ES
	call BASE_FUNC
	call CHECK_UN
	cmp BX, 1
	je unload_point
	cmp AX, 1
	je end_point3

load_point:
	lea dx, message_1
	call PRINT
	call LOAD
	jmp end_point

unload_point:
	cmp AX, 0
	je end_point2
	lea dx, message_2
	call PRINT
	call UNLOAD
	jmp end_point

end_point3:
	lea dx, message_3
	call PRINT
	jmp end_point

end_point2:
	lea dx, message_4
	call PRINT
	
end_point:
	xor AL, AL
	mov AH, 4Ch
	int 21h
MAIN ENDP

CODE ENDS

DATA SEGMENT
	message_1 db "Resident was loaded",0dh,0ah,'$'
	message_2 db "Resident was unloaded",0dh,0ah,'$'
	message_3 db "Resident has already been loaded",0dh,0ah,'$'
	message_4 db "Resident has already been unloaded",0dh,0ah,'$'
DATA ENDS

AStack SEGMENT STACK
	DW 200 DUP(?)
AStack ENDS

END MAIN
