TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
org 100h

start: jmp begin

UNAVAILABLE_MEM db 'Unavailable Memory:    ', 0DH, 0AH, '$'
ENV_SEG db 'Environment Segment:    ', 0DH, 0AH, '$'
COMMAND_LINE_ARGS db 'Command Line Args:$'
COMMAND_LINE_ARGS_EMPTY db 'Command Line Args: empty', 0DH, 0AH, '$'
ENV_SEG_CONTENT db 'Environment Segment Content:', 0DH, 0AH, '$'
BOOT_PATH db 'Boot Path:$'


TETR_TO_HEX proc near
    and al, 0fh
    cmp al, 09
    jbe next
    add al, 07

next:
    add al, 30h
    ret

TETR_TO_HEX endp

BYTE_TO_HEX proc near
    push cx
    mov ah, al
    call TETR_TO_HEX
    xchg al, ah
    mov cl, 4
    shr al, cl
    call TETR_TO_HEX
    pop cx
    ret
BYTE_TO_HEX endp

WRD_TO_HEX proc near
    push bx
    mov bh, ah
    call BYTE_TO_HEX
    mov [di], ah
    dec di
    mov [di], al
    dec di
    mov al, bh
    call BYTE_TO_HEX
    mov [di], ah
    dec di
    mov [di], al
    pop bx
    ret
WRD_TO_HEX endp

BYTE_TO_DEC proc near

    push cx
    push dx
    xor ah, ah
    xor dx, dx
    mov cx, 10

loop_bd:
    div cx
    or dl, 30h
    mov [si], dl
    dec si
    xor dx, dx
    cmp ax, 10
    jae loop_bd
    cmp al, 00h
    je end_l
    or al, 30h
    mov [si], al

end_l:
    pop dx
    pop cx
    ret

BYTE_TO_DEC endp

WRITEWRD  PROC  NEAR
    push ax
    mov ah, 9
    int 21h
    pop ax
    ret
WRITEWRD  ENDP

WRITEBYTE  PROC  NEAR
    push ax
    mov ah, 02h
    int 21h
    pop ax
    ret
WRITEBYTE  ENDP

ENDLINE PROC NEAR
    push ax
    push dx

    mov dl, 0dh
    call WRITEBYTE

    mov dl, 0ah
    call WRITEBYTE

    pop dx
    pop ax
    ret
ENDLINE ENDP

TASK_1 PROC NEAR

    push ax
    push di

    mov ax,ds:[02h]
	mov di, offset UNAVAILABLE_MEM
	add di, 22
	call WRD_TO_HEX

	mov dx, offset UNAVAILABLE_MEM
	call WRITEWRD

    pop di
    pop ax
	ret


TASK_1 ENDP

TASK_2 PROC NEAR

    push ax
    push cx
    push di

    mov ax,ds:[2ch]
	mov di, offset ENV_SEG
	add di, 23
	call WRD_TO_HEX

	mov dx, offset ENV_SEG
	call WRITEWRD

    pop di
    pop cx
    pop ax
	ret


TASK_2 ENDP

TASK_3 PROC NEAR

    push ax
    push cx
    push dx
    push di

    xor cx, cx
    xor di, di

    mov cl, ds:[80h]
    cmp cl, 0
    je no_args

    mov dx, offset COMMAND_LINE_ARGS
    call WRITEWRD

for_loop:
    mov dl, ds:[81h + di]
    call WRITEBYTE

    inc di

    loop for_loop
    call ENDLINE
    jmp restore

no_args:
    mov dx, offset COMMAND_LINE_ARGS_EMPTY
    call WRITEWRD

restore:
    pop di
    pop dx
    pop cx
    pop ax
	ret

TASK_3 ENDP

TASK_4 PROC NEAR

    push ax
    push dx
    push es
    push di

    mov dx, offset ENV_SEG_CONTENT
    call WRITEWRD

    xor di, di
    mov ax, ds:[2ch]
    mov es, ax

content_loop:
    mov dl, es:[di]
    cmp dl, 0
    je end_string2

    call WRITEBYTE

    inc di
    jmp content_loop

end_string2:
    call ENDLINE

    inc di

    mov dl, es:[di]
    cmp dl, 0
    jne content_loop

    call TASK_5

    pop di
    pop es
    pop dx
    pop ax
	ret

TASK_4 ENDP

TASK_5 PROC NEAR

    push ax
    push dx
    push es
    push di

    mov dx, offset BOOT_PATH
	call WRITEWRD

	add di, 3

boot_loop:
	mov dl, es:[di]
	cmp dl,0
	je restore2

	call WRITEBYTE

	inc di

	jmp boot_loop

restore2:
    call ENDLINE

    pop di
    pop es
    pop dx
    pop ax
	ret

TASK_5 ENDP

begin:

    call TASK_1
    call TASK_2
    call TASK_3
    call TASK_4
    
    ; запросить символ с клавиатуры
    xor al, al
    mov ah, 01h
    int 21h

    ; Выход в DOS
    mov ah, 4ch
    int 21h

TESTPC  ENDS
        END start
