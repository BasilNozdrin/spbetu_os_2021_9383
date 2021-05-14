ASTACK SEGMENT STACK
   DW 256 DUP(?)
ASTACK ENDS

DATA SEGMENT
    pblock dw 0
    com_off dw 0
    com_seg dw 0
     dd 0
     dd 0

    next_com_line db 1h, 0dh
    file_name db 'lb2.com', 0h
    file_path db 128 DUP(0)

    keep_ss dw 0
    keep_sp dw 0

    freemem db 0
    freemem_mcb_err db 'Free memory error: MCB crashed', 0DH, 0AH, '$'
    freemem_not_enough_err db 'Free memory error: not enough memory', 0DH, 0AH, '$'
    freemem_address_err db 'Free memory error: wrong address', 0DH, 0AH, '$'
    freemem_success db 'Memory was successfully freed', 0DH, 0AH, '$'
    load_function_number_err db 'Load error: function number is wrong', 0DH, 0AH, '$'
    load_file_not_found_err db 'Load error: file not found', 0DH, 0AH, '$'
    load_disk_err db 'Load error: problem with disk', 0DH, 0AH, '$'
    load_memory_err db 'Load error: not enough memory', 0DH, 0AH, '$'
    load_path_err db 'Load error: wrong path param', 0DH, 0AH, '$'
    load_format_err db 'Load error: wrong Format', 0DH, 0AH, '$'
    ex db 'Programm was finished: exit with code:     ', 0DH, 0AH, '$'
    ex_ctrl_c db 'Exit with Ctrl+Break', 0DH, 0AH, '$'
    ex_err db 'Exit with device error', 0DH, 0AH, '$'
    ex_int31h db 'Exit with int 31h', 0DH, 0AH, '$'

    data_end db 0
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:ASTACK

    PRINT_STR  PROC  NEAR
        push ax
        mov ah, 9
        int 21h
        pop ax
        ret
    PRINT_STR  ENDP

    PRINT_EOF PROC NEAR
        push ax
        push dx
        mov dl, 0dh
        push ax
        mov ah, 02h
        int 21h
        pop ax
        mov dl, 0ah
        push ax
        mov ah, 02h
        int 21h
        pop ax
        pop dx
        pop ax
        ret
    PRINT_EOF ENDP

    MEM_PROC PROC FAR
        push ax
        push bx
        push cx
        push dx
        push es
        xor dx, dx
        mov freemem, 0h
        mov ax, offset data_end
        mov bx, offset finish
        add ax, bx
        mov bx, 10h
        div bx
        add ax, 100h
        mov bx, ax
        xor ax, ax
        mov ah, 4ah
        int 21h
        jnc mem_success
	      mov freemem, 1h
        cmp ax, 7
        jne mem_not_enough_err
        mov dx, offset freemem_mcb_err
        call PRINT_STR
        jmp mem_exit

    mem_not_enough_err:
        cmp ax, 8
        jne mem_address_err
        mov dx, offset freemem_not_enough_err
        call PRINT_STR
        jmp mem_exit

    mem_address_err:
        cmp ax, 9
        jne mem_exit
        mov dx, offset freemem_address_err
        call PRINT_STR
        jmp mem_exit

    mem_success:
        mov dx, offset freemem_success
        call PRINT_STR
		jmp mem_exit

    mem_exit:
        pop es
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    MEM_PROC ENDP

    LOAD PROC FAR
        push ax
        push bx
        push cx
        push dx
        push ds
        push es
        mov keep_sp, sp
        mov keep_ss, ss
        call PATH_START
        mov ax, data
        mov es, ax
        mov bx, offset pblock
        mov dx, offset next_com_line
        mov com_off, dx
        mov com_seg, ds
        mov dx, offset file_path
        mov ax, 4b00h
        int 21h
        mov ss, keep_ss
        mov sp, keep_sp
        pop es
        pop ds
        call PRINT_EOF
		    jnc l_success
		    cmp ax, 1
    		je l_function_number_err
    		cmp ax, 2
    		je l_file_not_found_err
    		cmp ax, 5
    		je l_disk_err
    		cmp ax, 8
    		je l_memory_err
    		cmp ax, 10
    		je l_path_err
    		cmp ax, 11
    		je l_format_err

	l_function_number_err:
    		mov dx, offset load_function_number_err
    		call PRINT_STR
    		jmp load_exit

	l_file_not_found_err:
    		mov dx, offset load_file_not_found_err
    		call PRINT_STR
    		jmp load_exit

	l_disk_err:
    		mov dx, offset load_disk_err
    		call PRINT_STR
    		jmp load_exit

	l_memory_err:
    		mov dx, offset load_memory_err
    		call PRINT_STR
    		jmp load_exit

	l_path_err:
    		mov dx, offset load_path_err
    		call PRINT_STR
    		jmp load_exit

	l_format_err:
    		mov dx, offset load_format_err
    		call PRINT_STR
    		jmp load_exit

  l_success:
        mov ax, 4d00h
	      int 21h
        cmp ah, 0
	      jne exit_ctrl_c
	      mov di, offset ex
        add di, 41
        mov [di], al
        mov dx, offset ex
	      call PRINT_STR
	      jmp load_exit

    exit_ctrl_c:
        cmp ah, 1
  	    jne exit_err
  	    mov dx, offset ex_ctrl_c
  	    call PRINT_STR
  	    jmp load_exit

    exit_err:
        cmp ah, 2
	      jne exit_int31h
	      mov dx, offset ex_err
	      call PRINT_STR
	      jmp load_exit

    exit_int31h:
        cmp ah, 3
	      jne load_exit
	      mov dx, offset ex_int31h
	      call PRINT_STR
	      jmp load_exit

    load_exit:
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    LOAD ENDP

    PATH_START PROC NEAR
        push ax
        push dx
        push es
        push di
        xor di, di
        mov ax, es:[2ch]
        mov es, ax

    loop_path_start:
        mov dl, es:[di]
        cmp dl, 0
        je go_path
        inc di
        jmp loop_path_start

    go_path:
        inc di
        mov dl, es:[di]
        cmp dl, 0
        jne loop_path_start
        call PATH
        pop di
        pop es
        pop dx
        pop ax
        ret
    PATH_START ENDP

    PATH PROC NEAR
        push ax
        push bx
        push bp
        push dx
        push es
        push di
        mov bx, offset file_path
        add di, 3

    loop_boot:
        mov dl, es:[di]
        mov [bx], dl
        cmp dl, '.'
        je loop_slash
        inc di
        inc bx
        jmp loop_boot

    loop_slash:
        mov dl, [bx]
        cmp dl, '\'
        je get_file_name
        mov dl, 0h
        mov [bx], dl
        dec bx
        jmp loop_slash

    get_file_name:
        mov di, offset file_name
        inc bx

    add_name:
        mov dl, [di]
        cmp dl, 0h
        je path_exit
        mov [bx], dl
        inc bx
        inc di
        jmp add_name

    path_exit:
        mov [bx], dl
        pop di
        pop es
        pop dx
        pop bp
        pop bx
        pop ax
        ret
    PATH ENDP

    MAIN PROC FAR
        mov ax, data
        mov ds, ax
        call MEM_PROC
        cmp freemem, 0h
        jne main_exit
        call PATH_START
        call LOAD

    main_exit:
        xor al, al
        mov ah, 4ch
        int 21h
    MAIN ENDP

finish:
CODE ENDS
END MAIN
