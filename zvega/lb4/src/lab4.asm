dosseg
.model small
.stack 400h

.data
    mstack dw 100h dup(?)
    int_is_load dw ?
    cmd_line_flag dw 0
    str_is_not_load db "Interruption didn't load",0dh,0ah,'$'
    str_load     db "Interruption loaded",0dh,0ah,'$' 
    str_unload   db "Interruption unloaded",0dh,0ah,'$'
    str_already_loaded db "Interruption is already loaded",0dh,0ah,'$'

.code
jmp m

WRITE_STR proc near
		push ax
		mov ah,9h
		int 21h
		pop ax
		ret
WRITE_STR ENDP


MY_INT PROC FAR
        jmp process
        _code dw 0abcdh
        keep_cs dw 0
        keep_ip dw 0
        temp_ss dw 0
        temp_sp dw 0
        PSP_0 dw 0
        PSP_1 dw 0
        str_count db "Call count:  0000                                                                                          "

process:
        cli
        mov temp_ss,ss
        mov temp_sp,sp
        mov ax,seg mstack
        mov ss,ax
        mov ax,offset mstack
        add ax,100H
        mov sp,ax
        sti 

        push ax
        push bx
        push cx
        push dx

        mov ah,3
        mov bh,0
        int 10h 

        push dx

        push ds
        mov ax,seg MY_INT
        mov ds,ax
        mov di,offset str_count
        add di,16

        mov cx,4
    for:
        mov bh,[di]
        inc bh
        mov [di],bh
        cmp bh,3ah
        jne output
        mov bh,30h
        mov [di],bh
        dec di
        loop for

    output:
        push es

        mov ax,ds
        mov es,ax
        mov bx,offset str_count
        mov bp,bx

        mov ah,13h
        mov al,0 
        mov bh,0
        mov dx,0 
        mov cx,80
        int 10h
        
        pop es
        pop ds


        pop dx
        mov ah,2
        mov bh,0
        int 10h 

        pop dx
        pop cx
        pop bx
        pop ax

        cli
        mov ax,temp_ss
        mov ss,ax
        mov sp,temp_sp
        sti
        iret
MY_INT ENDP

empty_func proc
empty_func endp

is_LOAD PROC NEAR
    mov ah,35h
    mov al,1ch
    int 21H

    mov dx,es:[bx+3]
    cmp dx,0abcdh
    je isLoad
    mov int_is_load,0
    jmp endOfIsLoad

isLoad:
    mov int_is_load,1

endofisload:
ret
is_LOAD endp


UNLOAD PROC NEAR
    call is_load
    cmp int_is_load,1
    jne metka1
    mov ah,35h
    mov al,1ch
    int 21h;получаем вектор
    cli
    push ds
    mov ax,es:[bx+5]
    mov ds,ax
    mov dx,es:[bx+7]
    mov ah,25h
    mov al,1ch
    int 21h ;восстанавливаем вектор
    pop ds
    sti

    mov dx,offset str_unload
    call write_str

    push es
    mov cx,es:[bx+13]
    mov es,cx
    mov ah,49h
    int 21h
    pop es
    mov cx,es:[bx+15]
    mov es,cx
    int 21h

    jmp metka2
metka1: 
    mov dx,offset str_is_not_load
    call write_str
metka2:
    ret
UNLOAD ENDP

LOAD PROC NEAR
        mov ah,35h
        mov al,1ch
        int 21h
        mov keep_cs,es
        mov keep_ip,bx
        
        push ds
        mov dx,offset MY_INT
        mov ax,seg MY_INT 
        mov DS,AX
        mov ah,25h
        mov al,1ch
        int 21h
        pop ds
        
ret
LOAD endp


CHECK_CMD_LINE PROC NEAR

    mov di,82h
    mov al,es:[di]
    cmp al,'-'
    jnz end_of_check
    inc di

    mov al,es:[di]
    cmp al,'e'
    jnz end_of_check
    inc di

    mov al,es:[di]
    cmp al,'x'
    jnz end_of_check
	inc di

    mov al,es:[di]
    cmp al,'i'
    jnz end_of_check
	inc di

    mov al,es:[di]
    cmp al,'t'
    jnz end_of_check

    call UNLOAD
    mov cmd_line_flag,1
    jmp ret_check
end_of_check:
    mov cmd_line_flag,0
ret_check:
    ret
CHECK_CMD_LINE ENDP



MAIN PROC FAR
m:
    mov bx,02ch
    mov ax,[bx]
    mov psp_0,ds
    mov psp_1,ax


    mov ax,@data
    mov ds,ax

    call CHECK_CMD_LINE
    cmp cmd_line_flag,0
    jne exit

    call is_load
    cmp int_is_load,1
    je alreadyLoaded

    call load
    mov dx,offset str_load
    call write_str

    mov dx,offset empty_func
    mov cl,04h
    shr dx,cl 
    add dx,1bh
    mov ah,31h
    mov al,00h
    int 21h
    jmp exit

alreadyLoaded:
    mov dx,offset str_already_loaded
    call  write_str
exit:
        mov ah,4ch
        int 21h
MAIN ENDP
end