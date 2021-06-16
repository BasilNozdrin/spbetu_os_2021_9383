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

    int_seg dw 256 dup(0)
    int_sig dw 0ffffh
    keep_ip dw 0
    keep_cs dw 0
    keep_psp dw 0
    keep_ax dw 0
    keep_ss dw 0
    keep_sp dw 0

start:
    mov keep_ax, ax
    mov keep_sp, sp
    mov keep_ss, ss
    mov ax, seg int_seg
    mov ss, ax
    mov ax, offset int_seg
    add ax, 256
    mov sp, ax

    push ax
    push bx
    push cx
    push dx
    push si
    push es
    push ds

    in al, 60h
	cmp al, 10h
	jl default_int
	cmp al, 13h
	jg default_int

	mov cl, '?'
	jmp change_key

default_int:
    pushf
    call dword ptr cs:keep_ip
    jmp end_interruption

change_key:
    in al, 61h
    mov ah, al
    or 	al, 80h
    out 61h, al
    xchg al, al
    out 61h, al
    mov al, 20h
    out 20h, al

print_key:
    mov ah, 05h
    mov ch, 00h
    int 16h
    or 	al, al
    jz 	end_interruption
    mov ax, 40h
    mov es, ax
    mov ax, es:[1ah]
    mov es:[1ch], ax
    jmp print_key


end_interruption:
    pop  ds
    pop  es
    pop	 si
    pop  dx
    pop  cx
    pop  bx
    pop	 ax
    mov sp, keep_sp
    mov ax, keep_ss
    mov ss, ax
    mov ax, keep_ax
    mov  al, 20h
    out  20h, al
    iret
CUSTOM_INTERRUPTION endp
LAST:





UNLOAD_CUSTOM_INTERRUPTION proc
    cli
    
    push ax
    push bx
    push dx
    push ds
    push es
    push si

    mov ah, 35h
    mov al, 09h
    int 21h
    mov si, offset keep_ip
    sub si, offset CUSTOM_INTERRUPTION
    mov dx, es:[bx + si]
    mov ax, es:[bx + si + 2]

    push ds
    mov ds, ax
    mov ah, 25h
    mov al, 09h
    int 21h
    pop ds

    mov ax, es:[bx + si + 4]
    mov es, ax
    push es
    mov ax, es:[2ch]
    mov es, ax
    mov ah, 49h
    int 21h
    pop es
    mov ah, 49h
    int 21h

    sti

	push dx
	mov dx,offset interruption_delete
	call PRINT
	pop dx


    pop si
    pop es
    pop ds
    pop dx
    pop bx
    pop ax

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

    push es
	mov ax, keep_psp
    mov es, ax

	
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
	pop es
    ret
CHECK_CMD endp





IS_LOADED proc far
	push bx
	push si

	mov ah, 35h
	mov al, 09h
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
	pop si
	pop bx

    ret
IS_LOADED endp





LOAD_CUSTOM_INTERRUPTION proc far
	push ax
    push bx
    push cx
    push dx
    push es
    push ds



	mov ah,35h
	mov al,09h
	int 21h
	
	mov KEEP_CS,es
	mov KEEP_IP,bx
	

	mov dx, offset CUSTOM_INTERRUPTION
	mov ax, seg CUSTOM_INTERRUPTION
	mov ds,ax
	
	mov ah,25h
	mov al,09h
	int 21h
	
	pop ds

	mov dx,offset interruption_loaded
	call PRINT
	
	mov dx, offset LAST
	mov cl,4h
	shr dx,cl
	inc dx
	
	add dx,100h
	xor ax,ax
	
	mov ah,31h
	int 21h


	pop es
    pop dx
    pop cx
    pop bx
    pop ax
	ret
LOAD_CUSTOM_INTERRUPTION endp




MAIN proc far
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es


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