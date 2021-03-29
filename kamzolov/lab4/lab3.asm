TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
org 100h

start: jmp begin

MCB_TABLE_DECLORATION db 'MCB TABLE: ', 0DH, 0AH, '$'
AVAILABLE_MEMORY_STRING db 'Available memory: $'
EXTENDED_MEMORY_STRING db 'Extended memory: $'
BYTES_STRING db ' bytes$'
KILOBYTES_STRING db ' Kbytes$'
MCB_SIZE_STRING db 'Size:     $'
FREE_AREA db 'free area                $'
OS_XMS_UMB db 'belongs to OS XMS UMB    $'
EXCLUDED_HIGH db'excluded high memory     $'
BELONGS_MSDOS db 'belongs MSDOS           $'
BUSY_386MAX_UMB db 'busy with block 386MAX UMB$'
BLOCKED_386MAX db 'blocked 386MAX            $'
BELONGS_386MAX db 'belongs 386MAX            $'
ADDRESS_STRING db 'Address:     $'
MCB_SC_SD_STRING db 'SC/SD: $'
TAB db ' $'
STRING_FOR_PSP_TYPE db '                         $'
PSP_TYPE_DECLORATION db 'PSP TYPE:$'

MCB_NUMBER db 'MCB_  $'

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

PRINT_NEW_LINE proc near
    push ax
    push dx

    mov dl, 0Dh
    mov ah, 02h
    int 21h

    mov dl, 0Ah
    mov ah, 02h
    int 21h

    pop dx
    pop ax
    ret
PRINT_NEW_LINE endp

PRINT_BUF proc near
    push ax
    mov ah, 9h
    int 21h
    pop ax
    ret
PRINT_BUF endp

PRINT_PARAGRAPH proc near
    push ax
    push bx
    push cx
    push dx
    push si


    mov si, dx
    mov bx, 0ah
    xor cx, cx

division_loop_ax:
    div bx
    push dx
    xor dx, dx
    inc cx
    cmp ax, 0h
    jne division_loop_ax

print_symbol_loop:
    pop dx
    add dx, 30h ;нужно не число, а код символа
    mov ah, 02h
    int 21h
    loop print_symbol_loop

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PRINT_PARAGRAPH endp

AVAILABLE_MEMORY proc near
    push ax
    push bx
    push dx

    mov dx, offset AVAILABLE_MEMORY_STRING
    call PRINT_BUF

    mov ah, 4ah
    mov bx, 0ffffh
    int 21h
    mov ax, bx

    xor dx, dx
    mov bx, 010h ;переводим из параграфов в байты
    mul bx

    call PRINT_PARAGRAPH
    mov dx, offset BYTES_STRING
    call PRINT_BUF
    call PRINT_NEW_LINE


    pop dx
    pop bx
    pop ax
    ret
AVAILABLE_MEMORY endp

EXTENDED_MEMORY proc near
    push ax
    push bx
    push dx

    mov al,30h
    out 70h,al
    in al,71h
    mov bl,al
    mov al,31h
    out 70h,al
    in al,71h
    mov bh, al

    mov dx, offset EXTENDED_MEMORY_STRING
    call PRINT_BUF

    mov ax, bx
    xor dx, dx
    call PRINT_PARAGRAPH
    mov dx, offset KILOBYTES_STRING
    call PRINT_BUF
    call PRINT_NEW_LINE

    pop dx
    pop bx
    pop ax
    ret
EXTENDED_MEMORY endp

MCB_ADDRESS proc near
    push dx
    push ax
    push es
    push di

    mov ax, es
    mov di, offset ADDRESS_STRING
    add di, 12
    call WRD_TO_HEX

    mov dx, offset ADDRESS_STRING
    call PRINT_BUF
    pop di
    pop es
    pop ax
    pop dx
    ret
MCB_ADDRESS endp

MCB_PSP_TYPE proc near
    push ax
    push dx
    push di
    mov ax, es:[1]
    mov dx, offset TAB
    call PRINT_BUF
    mov dx, offset PSP_TYPE_DECLORATION
    call PRINT_BUF

    cmp ax, 0000h
    je print_1

    cmp ax, 0006h
    je print_2

    cmp ax, 0007h
    je print_3

    cmp ax, 0008h
    je print_4

    cmp ax, 0FFFAh
    je print_5

    cmp ax, 0FFFDh
    je print_6

    cmp ax, 0FFFEh
    je print_7

    jmp print_8
print_1:
    mov dx, offset FREE_AREA
    call PRINT_BUF
    jmp exit2
print_2:
    mov dx, offset OS_XMS_UMB
    call PRINT_BUF
    jmp exit2
print_3:
    mov dx, offset EXCLUDED_HIGH
    call PRINT_BUF
    jmp exit2
print_4:
    mov dx, offset BELONGS_MSDOS
    call PRINT_BUF
    jmp exit2
print_5:
    mov dx, offset BUSY_386MAX_UMB
    call PRINT_BUF
    jmp exit2
print_6:
    mov dx, offset BLOCKED_386MAX
    call PRINT_BUF
    jmp exit2
print_7:
    mov dx, offset BELONGS_386MAX
    call PRINT_BUF
print_8:
    mov di, offset STRING_FOR_PSP_TYPE
    add di, 3
    call WRD_TO_HEX
    mov dx, offset STRING_FOR_PSP_TYPE
    call PRINT_BUF
exit2:
    pop di
    pop dx
    pop ax
    ret
MCB_PSP_TYPE endp

MCB_SIZE proc near
    push ax
    push dx
    push es
    push di

    mov dx, offset TAB
    call PRINT_BUF
    mov ax, es:[3]
    mov di, offset MCB_SIZE_STRING
    add di, 8
    call WRD_TO_HEX
    mov dx, offset MCB_SIZE_STRING
    call PRINT_BUF

    pop di
    pop es
    pop dx
    pop ax
    ret
MCB_SIZE endp

MCB_SC_SD proc near
    push dx
    push ax
    push es
    push di
    push cx

    mov dx, offset MCB_SC_SD_STRING
    call PRINT_BUF

    mov bx, 8
    mov cx, 08h
scsd_loop:
        mov dl, es:[bx]
        mov ah, 02h
        int 21h
        inc bx
        loop scsd_loop
exit3:
    pop cx
    pop di
    pop es
    pop ax
    pop dx
    ret
MCB_SC_SD endp

MCB_TABLE proc near
    push ax
    push bx
    push dx
    push cx
    push si

    call PRINT_NEW_LINE
    mov dx, offset MCB_TABLE_DECLORATION
    call PRINT_BUF


    mov ah, 52h
    int 21h
    mov ax, es:[bx-2]
    mov es, ax
    mov cl, 01h

mcb_line_loop:
    mov al, cl
    mov si, offset MCB_NUMBER
    add si, 4
    call BYTE_TO_DEC
    mov dx, offset MCB_NUMBER
    call PRINT_BUF


    call MCB_ADDRESS
    call MCB_SIZE
    call MCB_SC_SD
    call MCB_PSP_TYPE
    call PRINT_NEW_LINE

    mov ah, es:[0]
    cmp ah, 5ah
    je exit

    mov bx, es:[3]
    inc bx
    mov ax, es
    add ax, bx
    mov es, ax
    inc cl
    jmp mcb_line_loop

exit:
    pop si
    pop cx
    pop dx
    pop bx
    pop ax
    ret
MCB_TABLE endp

begin:
    
    call AVAILABLE_MEMORY
    call EXTENDED_MEMORY
    call MCB_TABLE


    xor al, al
    mov ah, 4ch
    int 21h

TESTPC  ENDS
        END start
