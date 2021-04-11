ASTACK segment stack
	dw 256 dup(?)
ASTACK ends





DATA segment
	int_already_loaded db 'Interruption_already_load',0dh,0ah,0dh,0ah,'$'
	interruption_loaded db 'Interruption_load',0dh,0ah,0dh,0ah,'$'
	interruption_delete db 'Interruption_was_delete',0dh,0ah,0dh,0ah,'$'
DATA ends





CODE segment 
    assume cs:CODE, ds:DATA, ss:ASTACK


CUSTOM_INTERRUPTION proc far
	jmp start
	
	KEEP_CS dw 0
	KEEP_IP dw 0
	KEEP_PSP dw 0
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_AX dw 0
	int_counter db 'interruption_counter: 0000$'
	int_sig dw 9999h
	int_seg dw 16 dup(?)

start:
	mov KEEP_SP,sp
	mov KEEP_AX,ax
	mov ax,ss
	mov KEEP_SS,ax
	
	mov ax,KEEP_AX
	mov sp,offset start
	mov ax,seg int_seg
	mov ss,ax
	
	push ax
	push cx
	push dx
	
	call getCurs
	push dx
	call setCurs
	
	push si
	push cx
	push ds
	push bp
	
	mov ax,seg int_counter
	mov ds,ax
	mov si,offset int_counter
	add si,21
	mov cx,4
	
loop_:
	mov bp,cx
	mov ah,[si+bp]
	inc ah
	mov [si+bp],ah
	cmp ah,3ah
	jne update
	mov ah,30h
	mov [si+bp],ah
	loop loop_

update:
	pop bp
	pop ds
	pop cx
	pop si
	
	push es
	push bp
	
	mov ax,seg int_counter
	mov es,ax
	mov ax,offset int_counter
	mov bp,ax
	
	mov ah,13h
    mov al,0
    mov bh,0
    mov cx,26
    int 10h

	pop bp
	pop es
	pop dx
	mov ah,2
	mov bh,0
	int 10h
	
	pop dx
	pop cx
	pop ax
	mov KEEP_AX,ax
	mov sp,KEEP_SP
	mov ax,KEEP_SS
	mov ss,ax
	mov ax,KEEP_AX
	
	mov al,20h
	out 20h,al
	iret
LAST:
CUSTOM_INTERRUPTION endp





outputAL proc
	push ax
	push bx
	push cx
	mov ah,09h
	mov bh,0
	mov cx,1
	int 10h
	pop cx
	pop bx
	pop ax
	ret
outputAL endp





outputBP proc
	push ax
	push bx
	push dx
	push cx
	mov ah,13h
	mov al,1
	mov bh,0
	mov dh,22
	mov dl,0
	int 10h
	pop cx
	pop dx
	pop bx
	pop ax
	ret
outputBP endp





setCurs proc
	mov ah,02h
	mov bh,0
	mov dh,22
	mov dl,0
	int 10h
	ret
setCurs endp





getCurs proc
	mov ah,03h
	mov bh,0
	int 10h
	ret
getCurs endp





UNLOAD_CUSTOM_INTERRUPTION proc
	cli
	push ds
	push es
	
	mov ah,35h
	mov al,1ch
	int 21h
	
	mov si,offset KEEP_IP
	sub si,offset CUSTOM_INTERRUPTION
	mov dx,es:[bx + si]
	mov ax,es:[bx + si + 2]
	mov ds,ax
	
	mov ah,25h
	mov al,1ch
	int 21h
	
	mov ax,es:[bx + si + 4]
    mov es,ax
    push es
	
	mov ax,es:[2ch]
    mov es,ax
    mov ah,49h
    int 21h
	
	pop es
	mov ah,49h
	int 21h
	
	pop es
	pop ds
	sti
	
	mov dx,offset interruption_delete
	call PRINT
	ret
UNLOAD_CUSTOM_INTERRUPTION endp





PRINT proc near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
PRINT endp




CHECK_CMD proc far
    mov al, es:[81h+1]
	cmp al, '/'
	jne set_zero
	
	mov al, es:[81h+2]
	cmp al, 'u'
	jne set_zero
	
	mov al, es:[81h+3]
	cmp al, 'n'
	jne set_zero

    mov ax, 1h
    jmp check_cmd_exit

set_zero:
    mov ax, 0h

check_cmd_exit:
    ret
CHECK_CMD endp





IS_LOADED proc far
	mov ah, 35h
	mov al, 1ch
	int 21h
	
	mov si, offset int_sig
	sub si, offset CUSTOM_INTERRUPTION
	mov dx, es:[bx + si]
	cmp dx, int_sig
	jne not_loaded
	mov ax, 1h
    jmp is_loaded_exit

not_loaded:
    mov ax, 0h

is_loaded_exit:
    ret
IS_LOADED endp





LOAD_CUSTOM_INTERRUPTION proc far
	mov KEEP_PSP, es
	mov ah,35h
	mov al,1ch
	int 21h
	
	mov KEEP_CS,es
	mov KEEP_IP,bx
	
	push es
	push bx
	push ds
	
	lea dx,CUSTOM_INTERRUPTION
	mov ax,seg CUSTOM_INTERRUPTION
	mov ds,ax
	
	mov ah,25h
	mov al,1ch
	int 21h
	
	pop ds
	pop bx
	pop es
	
	mov dx,offset interruption_loaded
	call PRINT
	
	lea dx,LAST
	mov cl,4h
	shr dx,cl
	inc dx
	
	add dx,100h
	xor ax,ax
	
	mov ah,31h
	int 21h

	ret
LOAD_CUSTOM_INTERRUPTION endp




MAIN proc far
	mov ax, DATA
	mov ds, ax

    push es
    call IS_LOADED
    cmp ax, 0h
    jne check_cmd_un

    call LOAD_CUSTOM_INTERRUPTION
    pop es
    jmp exit

check_cmd_un:
    pop es
    call CHECK_CMD
    cmp ax, 0h
    je already_loaded
    call UNLOAD_CUSTOM_INTERRUPTION
    jmp exit

already_loaded:
	mov dx,offset int_already_loaded
	call PRINT

exit:
	xor al,al
	mov ah,4ch
	int 21h
MAIN endp

CODE ends
end main 