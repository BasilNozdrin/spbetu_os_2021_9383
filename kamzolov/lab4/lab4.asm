AStack    SEGMENT  STACK
          DW 64 DUP(?)
AStack    ENDS

DATA  SEGMENT
    ROUT_LOADED db "Custom interruption is already loaded.$"
    ROUT_IS_LOADING db "Interruption is changed to custom.$"
    ROUT_IS_NOT_LOADED db "Default interruption is set and can't be unloaded.$"
    ROUT_IS_UNLOADED db "Custom interruption was unloaded.$"
DATA  ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack

PRINT_BUF proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
PRINT_BUF endp


start_rout:
ROUT proc far
    jmp start_proc
    KEEP_PSP dw 0
    KEEP_IP dw 0
   	KEEP_CS dw 0
    KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0

    ROUT_INDEX dw 1337h
    TIMER_COUNTER db 'Timer: 0000$'
    BStack DW 64 DUP(?)
start_proc:
    mov KEEP_SP, sp
    mov KEEP_AX, ax
    mov ax, ss
    mov KEEP_SS, ss

    mov ax, KEEP_AX

    mov sp, offset start_proc

    mov ax, seg BStack
    mov ss, ax

    push bx
   	push cx
   	push dx

    mov ah,3h
	mov bh,0h
	int 10h
    push dx


    push si
    push cx
    push ds
    push ax
    push bp


    mov ax, SEG TIMER_COUNTER
    mov ds,ax
    mov si, offset TIMER_COUNTER

    add si, 6
    mov cx, 4

timer_inc:
    mov bp, cx
    mov ah, [si+bp]
    inc ah
    cmp ah, 3ah
    jl timer_inc_end
    mov ah, 30h
    mov [si+bp], ah

    loop timer_inc

timer_inc_end:
    mov [si+bp], ah

    pop bp
    pop ax
    pop ds
    pop cx
    pop si

    push es
	push bp

    mov ax, SEG TIMER_COUNTER
	mov es,ax
	mov ax, offset TIMER_COUNTER
	mov bp,ax
	mov ah,13h
	mov al,00h
    mov dh,02h
   	mov dl,09h
	mov cx,11
	mov bh,0
	int 10h

	pop bp
	pop es

	;return cursor
	pop dx
	mov ah,02h
	mov bh,0h
	int 10h

	pop dx
	pop cx
	pop bx

    mov KEEP_AX, ax
    mov sp, KEEP_SP
    mov ax, KEEP_SS
    mov ss, ax
    mov ax, KEEP_AX

    mov al, 20H
    out 20H, al

    iret
end_rout:
ROUT endp


IF_NEED_UNLOAD proc near
   	push ax
    push es

   	mov al,es:[81h+1]
   	cmp al,'/'
   	jne end_if_need_unload

   	mov al,es:[81h+2]
   	cmp al,'u'
   	jne end_if_need_unload

   	mov al,es:[81h+3]
   	cmp al,'n'
   	jne end_if_need_unload

    mov cl,1h

end_if_need_unload:
    pop es
   	pop ax
   	ret
IF_NEED_UNLOAD endp


LOAD_ROUT PROC near
   	push ax
   	push dx

    mov KEEP_PSP, es

   	mov ah,35h
	mov al,1ch
	int 21h
    mov KEEP_IP, bx
    mov KEEP_CS, es

   	push ds
   	lea dx, ROUT
   	mov ax, SEG ROUT
   	mov ds,ax
   	mov ah,25h
   	mov al,1ch
   	int 21h
   	pop ds

   	lea dx, end_rout
   	mov cl,4h
   	shr dx,cl
   	inc dx
   	add dx,100h
    xor ax, ax
   	mov ah,31h
   	int 21h

   	pop dx
   	pop ax
   	ret
LOAD_ROUT endp

UNLOAD_ROUT PROC near
   	push ax
   	push si

    cli
   	push ds
   	mov ah,35h
	mov al,1ch
    int 21h

    mov si,offset KEEP_IP
    sub si,offset ROUT
    mov dx,es:[bx+si]
	mov ax,es:[bx+si+2]
    mov ds,ax
    mov ah,25h
    mov al,1ch
    int 21h
    pop ds

    mov ax,es:[bx+si-2]
    mov es,ax
    push es

    mov ax,es:[2ch]
    mov es,ax
    mov ah,49h
    int 21h

    pop es
    mov ah,49h
    int 21h
    sti

    pop si
    pop ax
    ret
UNLOAD_ROUT endp

IF_LOADED proc near
   	push ax
   	push si

    push es
    push dx

   	mov ah,35h
   	mov al,1ch
   	int 21h

   	mov si, offset ROUT_INDEX
   	sub si, offset ROUT
   	mov dx,es:[bx+si]
   	cmp dx, ROUT_INDEX
   	jne end_if_loaded
   	mov ch,1h

end_if_loaded:
    pop dx
    pop es
   	pop si
   	pop ax
   	ret
IF_LOADED ENDP

MAIN proc far
    push  DS
    push  AX
    mov   AX,DATA
    mov   DS,AX

    call IF_NEED_UNLOAD
    cmp cl, 1h
    je need_unload

    call IF_LOADED
    cmp ch, 1h
    je print_rout_is_already_set
    mov dx, offset ROUT_IS_LOADING
    call PRINT_BUF
    call LOAD_ROUT
    jmp exit

need_unload:
    call IF_LOADED
    cmp ch, 1h
    jne print_rout_cant_be_unloaded
    call UNLOAD_ROUT
    mov dx, offset ROUT_IS_UNLOADED
    call PRINT_BUF
    jmp exit

print_rout_cant_be_unloaded:
    mov dx, offset ROUT_IS_NOT_LOADED
    call PRINT_BUF
    jmp exit
print_rout_is_already_set:
    mov dx, offset ROUT_LOADED
    call PRINT_BUF
    jmp exit

exit:
    mov ah, 4ch
    int 21h
MAIN endp
CODE ends
END Main
