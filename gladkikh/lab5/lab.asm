ASTACK SEGMENT STACK
   DW 200 DUP(?)
ASTACK ENDS

DATA SEGMENT
    interruption_already_loaded_string db 'Interruption is already loaded', 0DH, 0AH, '$'
    interruption_loaded_successfully_string db 'Interruption is loaded successfully', 0DH, 0AH, '$'
    interruption_not_loaded_string db 'Interruption is not loaded', 0DH, 0AH, '$'
    interruption_restored_string db 'Interruption is restored', 0DH, 0AH, '$'
    test_string db 'test', 0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:ASTACK

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

    OUTPUTAL PROC NEAR
        push ax
        push bx
        push cx
        mov ah, 09h ;писать символ с текущей позиции курсора
        mov bh, 0 ;номер видео страницы
        mov cx, 1 ;число экземпляров символа для записи
        int 10h ;выполнить функцию
        pop cx
        pop bx
        pop ax
        ret
    OUTPUTAL ENDP

    OUTPUTBP PROC NEAR
        push ax
        push bx
        push dx
        push CX
        mov ah,13h ; функция
        mov al, 0 ; sub function code
        ; 1 = use attribute in BL; leave cursor at end of string
        mov bh,0 ; видео страница
        mov dh,22 ; DH,DL = строка, колонка (считая от 0)
        mov dl,0
        int 10h
        pop CX
        pop dx
        pop bx
        pop ax
        ret
    OUTPUTBP ENDP

    MY_INTERRUPTION PROC FAR
        jmp start

        STD_KEY db 0h
        SHIFT_PRESSED db 0
        interruption_signature dw 7777h

        int_keep_ip dw 0
        int_keep_cs dw 0
        psp_address dw ?
        int_keep_ss dw 0
        int_keep_sp dw 0
        int_keep_ax dw 0
        IntStack dw 64 dup(?)

    start:
        mov int_keep_sp, sp
        mov int_keep_ax, ax
        mov ax, ss
        mov int_keep_ss, ax

        mov sp, OFFSET start
        mov ax, seg IntStack
        mov ss, ax

        mov ax, int_keep_ax

        push ax ;сохранение изменяемого регистра
        push cx ;сохранение изменяемого регистра
        push dx ;сохранение изменяемого регистра

        ;Само прерывание

        mov STD_KEY, 0h
        mov SHIFT_PRESSED, 0h

        mov ax, 40h
        mov es, ax
        mov ax, es:[17h]
        and ax, 11b
        cmp ax, 0h
        je read_symbol
        mov SHIFT_PRESSED, 1h

    read_symbol:
        in al, 60h ;читать ключ
        cmp al, 10h ;это требуемый код?
        je key_q ; да, активизировать обработку
        cmp al, 11h
        je key_w

        ; нет, уйти на исходный обработчик
        mov STD_KEY, 1h
        jmp interuption_end

    key_q:
        mov al, 'a'
        jmp do_req
    
    key_w:
        mov al, 'z'
        jmp do_req

    do_req:
        push ax
        ;следующий код необходим для отработки аппаратного прерывания
        in al, 61H  ; взять значение порта управления клавиатурой
        mov ah, al  ; сохранить его
        or al, 80h  ; установить бит разрешения для клавиатуры
        out 61H, al ; и вывести его в управляющий порт
        xchg ah, al ; извлечь исходное значение порта
        out 61H, al ; и записать его обратно
        mov al, 20H ; послать сигнал "конец прерывания"
        out 20H, al ; контроллеру прерываний 8259
        pop ax

        cmp SHIFT_PRESSED, 0h
        je print_key
        sub al, 20h
        
    print_key:
        mov ah, 05h ; Код функции
        mov cl, al ; Пишем символ в буфер клавиатуры
        mov ch, 00h ;
        int 16h ;
        or al, al ; проверка переполнения буфера
        jz interuption_end ; если не переполнен идем в конец прерывания
        mov ax, 0040h
        mov es, ax
        mov ax, es:[1ah]
        mov es:[1ch], ax
        jmp print_key

    interuption_end:
        ;Конец прерывания

        pop dx ;восстановление регистра
        pop cx ;восстановление регистра
        pop ax ;восстановление регистра

        mov sp, int_keep_sp
        mov ax, int_keep_ss
        mov ss, ax
        mov ax, int_keep_ax

        mov al, 20h	;разрешаем обработку прерываний
        out 20h, al	;с более низкими уровнями

        cmp STD_KEY, 1h
        jne interuption_iret

        jmp dword ptr cs:[int_keep_ip] ;переход на первоначальный обработчик
    interuption_iret:
        iret ;конец прерывания

    MY_INTERRUPTION ENDP
    interruption_last_byte:

    CHECK_CLI_OPT PROC near
       	push ax
        push bp

        mov cl, 0h

        mov bp, 81h

       	mov al,es:[bp + 1]
       	cmp al,'/'
       	jne lafin

       	mov al,es:[bp + 2]
       	cmp al,'u'
       	jne lafin

       	mov al,es:[bp + 3]
       	cmp al,'n'
       	jne lafin

       	mov cl, 1h

    lafin:
        pop bp
       	pop ax
       	ret
    CHECK_CLI_OPT ENDP

    CHECK_LOADED PROC NEAR
        push ax
        push dx
        push es
        push si

        mov cl, 0h

        mov ah, 35h
        mov al, 09h
        int 21h

        mov si, offset interruption_signature
        sub si, offset MY_INTERRUPTION
        mov dx, es:[bx + si]
        cmp dx, interruption_signature
        jne checked

        mov cl, 1h ;already loaded

    checked:
        pop si
        pop es
        pop dx
        pop ax
        ret
    CHECK_LOADED ENDP

    LOAD_INTERRUPTION PROC near
       	push ax
        push cx
       	push dx


       	call CHECK_LOADED
       	cmp cl, 1h
       	je int_already_loaded

        mov psp_address, es

       	mov ah, 35h
    	mov al, 09h
    	int 21h

        mov int_keep_cs, es
	    mov int_keep_ip, bx

    	push es
        push bx
       	push ds

       	lea dx, MY_INTERRUPTION
       	mov ax, SEG MY_INTERRUPTION
       	mov ds, ax

       	mov ah, 25h
       	mov al, 09h
       	int 21h

       	pop ds
        pop bx
        pop es

        mov dx, offset interruption_loaded_successfully_string
       	call WRITEWRD

       	lea dx, interruption_last_byte
       	mov cl, 4h
       	shr dx, cl
       	inc dx ;dx - size in paragraphs

       	add dx, 100h

       	xor ax,ax

       	mov ah, 31h
       	int 21h

        jmp fin_load_interruption

    int_already_loaded:
     	mov dx, offset interruption_already_loaded_string
        call WRITEWRD

    fin_load_interruption:
       	pop dx
        pop cx
       	pop ax
       	ret
    LOAD_INTERRUPTION ENDP

    UNLOAD_INTERRUPTION PROC near
       	push ax
       	push si

       	call CHECK_LOADED
       	cmp cl, 1h
       	jne interruption_is_not_loaded

        cli

        push ds
        push es

        mov ah, 35h
        mov al, 09h
        int 21h

        mov si, offset int_keep_ip
	    sub si, offset MY_INTERRUPTION
	    mov dx, es:[bx + si]
	    mov ax, es:[bx + si + 2]
   	    mov ds, ax

        mov ah, 25h
        mov al, 09h
        int 21h

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

        pop es
        pop ds

        sti

        mov dx, offset interruption_restored_string
       	call WRITEWRD



        jmp int_unloaded

    interruption_is_not_loaded:
        mov dx, offset interruption_not_loaded_string
        call WRITEWRD

    int_unloaded:
       	pop si
       	pop ax
       	ret
    UNLOAD_INTERRUPTION ENDP

    MAIN PROC FAR
       	mov   ax, DATA
       	mov   ds, ax

        call CHECK_CLI_OPT
        cmp cl, 0h
        jne opt_unload

        call LOAD_INTERRUPTION
        jmp main_end

    opt_unload:

        call UNLOAD_INTERRUPTION

    main_end:
        xor al, al
        mov ah, 4ch
        int 21h

    MAIN ENDP


CODE ENDS

END MAIN
