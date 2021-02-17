AStack    SEGMENT  STACK
          DW 64 DUP(?)
AStack    ENDS

DATA  SEGMENT
IBM_TYPE_PC db 'ТИП IBM PC:PC', 0DH, 0AH, '$'
IBM_TYPE_PC_XT db 'ТИП IBM PC:PC/XT', 0DH, 0AH, '$'
IBM_TYPE_AT db 'ТИП IBM PC:AT', 0DH, 0AH, '$'
IBM_TYPE_PS2_30 db 'ТИП IBM PC:PS2 модель 30', 0DH, 0AH, '$'
IBM_TYPE_PS2_80 db 'ТИП IBM PC:PS2 модель 80', 0DH, 0AH, '$'
IBM_TYPE_PC_JR db 'ТИП IBM PC:PCjr', 0DH, 0AH, '$'
IBM_TYPE_PC_CONV db 'ТИП IBM PC:PC Convertible', 0DH, 0AH, '$'
IBM_TYPE_UNKNOWN db 'ТИП модели IBM PC:                ', 0DH, 0AH, '$'
SYSTEM_VER db 'Версия MSDOS: .                      ', 0DH, 0AH, '$'
SYSTEM_VER_LOWER_2_0 db 'Версия MSDOS < 2.0.', 0DH, 0AH, '$'
OEM_NUMBER db 'Серийный номер OEM:                     ', 0DH, 0AH, '$'
SERIAL_NUMBER db 'Серийный номер пользователя:       ', 0DH, 0AH, '$'
DATA  ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack

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

    push ax
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
    pop ax
    ret

BYTE_TO_DEC endp

PC_TYPE proc near

    push ax
    push es
    push di
    push dx

    mov ax, 0f000h
    mov es, ax
    mov di, 0fffeh
    mov al, es:[di]

    xor ah,ah
    cmp al, 0ffh
    je pc_print

    cmp al, 0feh
    je pcxt_print

    cmp al, 0fbh
    je pcxt_print

    cmp al, 0fch
    je at_print

    cmp al, 0fah
    je ps2_model_30_print

    cmp al, 0f8h
    je ps2_model_80_print

    cmp al, 0fdh
    je pcjr_print

    cmp al, 0f9h
    je pc_conv_print

    mov di, offset IBM_TYPE_UNKNOWN
    call BYTE_TO_HEX
    mov [di+18], al
    mov [di+19], ah
    mov dx, offset IBM_TYPE_UNKNOWN
    jmp print_dx

pc_print:
    mov dx, offset IBM_TYPE_PC
    jmp print_dx
pcxt_print:
    mov dx, offset IBM_TYPE_PC_XT
    jmp print_dx
at_print:
    mov dx, offset IBM_TYPE_AT
    jmp print_dx
ps2_model_30_print:
    mov dx, offset IBM_TYPE_PS2_30
    jmp print_dx
ps2_model_80_print:
    mov dx, offset IBM_TYPE_PS2_80
    jmp print_dx
pcjr_print:
    mov dx, offset IBM_TYPE_PC_JR
    jmp print_dx
pc_conv_print:
    mov dx, offset IBM_TYPE_PC_CONV
    jmp print_dx
print_dx:
    mov ah, 9h
    int 21h

    pop dx
    pop di
    pop es
    pop ax
ret
PC_TYPE endp

PRINT_BUF proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
PRINT_BUF endp

MSDOS_VER_PRINT proc near
    push ax
    push bx
    push cx

    mov ah, 30h
    int 21h

    ;xor ax, ax

    cmp al, 0h
    jne greater_0
    mov dx, offset SYSTEM_VER_LOWER_2_0
    call PRINT_BUF
    jmp oem_print

greater_0:
    push ax
    mov di, offset SYSTEM_VER
    call BYTE_TO_DEC
    lodsw
    mov [di+13], ah
    pop ax
    xchg ah, al
    call BYTE_TO_DEC
    lodsw
    mov [di+15], ah
    mov dx, offset SYSTEM_VER
    call PRINT_BUF

oem_print:
    mov al, bh
    mov di, offset OEM_NUMBER
    call BYTE_TO_HEX
    mov [di+19], al
    mov [di+20], ah
    mov dx, offset OEM_NUMBER
    call PRINT_BUF

    mov al, bl
    mov di, offset SERIAL_NUMBER
    call BYTE_TO_HEX
    mov [di+28], al
    mov [di+29], ah
    mov ax, cx
    add di, 33
    call WRD_TO_HEX
    mov dx, offset SERIAL_NUMBER
    call PRINT_BUF

    pop cx
    pop bx
    pop ax
    ret
MSDOS_VER_PRINT endp


Main PROC far
    mov   ax, data
    mov   ds, ax
    call PC_TYPE

    call MSDOS_VER_PRINT


    xor al, al
    mov ah, 4ch
    int 21h

Main ENDP

CODE ENDS
      END Main
