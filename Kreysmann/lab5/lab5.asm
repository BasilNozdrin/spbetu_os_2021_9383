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
        keep_ip dw 0
        keep_cs dw 0
        temp_ss dw 0
        temp_sp dw 0
        PSP_0 dw 0
        PSP_1 dw 0
        keep_ax DW 0

process:
        cli
        mov keep_ax,ax
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
        
        in al,60h  
        cmp al,25h ;скан-код - k?
        jnz STANDARD ;если нет то переходим к стандартному
        ;проверяем нажат ли Ins 
        mov ax,0040h
        mov es,ax
        mov al,es:[18h]
        and al,10000000b
        je STANDARD ;если не нажат то переходим к стандартному
        
        ;следующий ход необходим для отработки аппаратного прерывания

        in al,61h ; взять значение порта управления клавиатурой
        mov ah,al ;сохранить его
        or al,80h ;установить бит разрешения для клавиатуры
        out 61h,al ; и вывести его в управляющий порт
        xchg ah,al ;извлесь исходное значение порта
        out 61h,al ;и записать его обратно
        mov al,20h ;послать сигнал о конце прерывания
        out 20h,al ;контроллеру прерываний 8259


PUSH_SYMB:       ;запись символа в буфер клавиатуры
        mov ah,05h ;код функции
        mov cl,'D' ;пишем символ в буфер клавиатуры
        mov ch,00h 
        int 16h
        or al,al ;проверка переполнения бефера
        jnz skip; если переполнен идем skip
        jmp end_p
skip:           ;очистить буфер и повторить
        cli 
        mov ax,es:[1ah] ;адрес начала буфера
		mov es:[1ch],ax ;в адрес конца буфера
		sti		
        jmp push_symb

STANDARD:

        pop dx
        pop cx
        pop bx
        pop ax
        mov ax,keep_ax
        mov ss,temp_ss
        mov sp,temp_sp
        jmp dword ptr keep_ip

end_p:

        pop dx
        pop cx
        pop bx
        pop ax

        mov ax,keep_ax
        mov al,20h
	    out 20h,al
        mov ss,temp_ss
        mov sp,temp_sp
        iret
MY_INT ENDP

empty_func proc
empty_func endp

is_LOAD PROC NEAR
        mov ah,35h
        mov al,09h
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
        mov al,09h
        int 21h;получаем вектор
        cli
        push ds
        mov dx,es:[bx+5]
        mov ax,es:[bx+7]
        mov ds,ax
        mov ah,25h
        mov al,09h
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
        mov al,09h
        int 21h
        mov keep_cs,es
        mov keep_ip,bx
        
        push ds
        mov dx,offset MY_INT
        mov ax,seg MY_INT 
        mov ds,ax
        mov ah,25h
        mov al,09h
        int 21h
        pop ds
        
ret
LOAD endp


CHECK_CMD_LINE PROC NEAR

        mov di,82h
        mov al,es:[di]
        cmp al,'/'
        jnz end_of_check
        inc di

        mov al,es:[di]
        cmp al,'u'
        jnz end_of_check
        inc di

        mov al,es:[di]
        cmp al,'n'
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

        ;оставим резидентной в памяти
        mov dx,offset empty_func
        mov cl,04h
        shr dx,cl ;в параграфы
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