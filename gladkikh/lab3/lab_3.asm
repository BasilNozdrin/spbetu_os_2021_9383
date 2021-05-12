TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
org 100h

start: jmp begin

AVAILABLE_MEM db 'Available Memory (bytes):$'
EXTENDED_MEM db 'Extended Memory (kbytes):$'
MCB_TABLE db 'MCB Table:', 0DH, 0AH, '$'
MCB_TABLE_NUMBER db 'MCB #  $'

MCB_ADDRESS db 'Address:      $'

PSP_TYPE db ' PSP TYPE: $'
PSP_FREE_AREA db 'free area            $'
PSP_OS_XMS_UMB db 'belongs to OS XMS UMB$'
PSP_RESERVED_FOR_DRIVERS db'reserved for drivers $'
PSP_BELONGS_MSDOS db 'belongs MSDOS        $'
PSP_BUSY_386MAX_UMB db 'busy with block 386MAX UMB$'
PSP_BLOCKED_386MAX db 'blocked 386MAX        $'
PSP_BELONGS_386MAX db 'belongs 386MAX        $'

DEFAULT_PSP_TYPE db '                     $'

MCB_TABLE_SIZE db 'Size:      $'

MCB_SC_SD db ' SC/SD: $'

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

WRITE_AVAILABLE_MEM PROC NEAR
    push ax
    push bx
    push cx
    push dx
    push di

    xor cx, cx

    mov bx, 010h
    mul bx
    mov di, dx

    mov bx, 0ah

division_loop_av:
    div bx
    push dx
    xor dx, dx
    inc cx
    cmp ax, 0h
    jne division_loop_av

print_symbol_loop_av:
    pop dx

    add dl, 30h

    call WRITEBYTE

    loop print_symbol_loop_av

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

WRITE_AVAILABLE_MEM ENDP

WRITE_EXTENDED_MEM PROC NEAR
    push ax
    push bx
    push cx
    push dx
    push di

    xor cx, cx
    xor dx, dx

    mov bx, 0ah

division_loop_ext:
    div bx
    push dx
    xor dx, dx
    inc cx
    cmp ax, 0h
    jne division_loop_ext

print_symbol_loop_ext:
    pop dx

    add dl, 30h

    call WRITEBYTE

    loop print_symbol_loop_ext

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

WRITE_EXTENDED_MEM ENDP

TASK_A PROC NEAR

    push ax
    push bx
    push dx

    mov dx, offset AVAILABLE_MEM
    call WRITEWRD

    mov ah, 4ah
    mov bx, 0ffffh
    int 21h
    mov ax, bx

    call WRITE_AVAILABLE_MEM
    call ENDLINE


    pop dx
    pop bx
    pop ax
    ret

TASK_A ENDP

TASK_B PROC NEAR

    push ax
    push bx
    push dx

    mov al, 30h
    out 70h, al
    in al, 71h

    mov bl, al
    mov al, 31h
    out 70h, al
    in al, 71h

    mov bh, al

    mov dx, offset EXTENDED_MEM
    call WRITEWRD

    mov ax, bx
    call WRITE_EXTENDED_MEM
    call ENDLINE

    pop dx
    pop bx
    pop ax
    ret

TASK_B ENDP

MCB_PSP_TYPE proc near
    push ax
    push dx
    push di

    ;mov dx, offset TAB
    ;call PRINT_BUF

    mov dx, offset PSP_TYPE
    call WRITEWRD

    cmp ax, 0000h
    je print_free_area

    cmp ax, 0006h
    je print_belongs_OS_XMS_UMB

    cmp ax, 0007h
    je print_reserved_for_drivers

    cmp ax, 0008h
    je print_belongs_MS_DOS

    cmp ax, 0FFFAh
    je print_busy_386MAX_UMB

    cmp ax, 0FFFDh
    je print_blocked_386MAX

    cmp ax, 0FFFEh
    je print_belongs_386MAX_UMB

    jmp print_psp_type

print_free_area:
    mov dx, offset PSP_FREE_AREA
    call WRITEWRD
    jmp end_psp_type

print_belongs_OS_XMS_UMB:
    mov dx, offset PSP_OS_XMS_UMB
    call WRITEWRD
    jmp end_psp_type

print_reserved_for_drivers:
    mov dx, offset PSP_RESERVED_FOR_DRIVERS
    call WRITEWRD
    jmp end_psp_type

print_belongs_MS_DOS:
    mov dx, offset PSP_BELONGS_MSDOS
    call WRITEWRD
    jmp end_psp_type

print_busy_386MAX_UMB:
    mov dx, offset PSP_BUSY_386MAX_UMB
    call WRITEWRD
    jmp end_psp_type

print_blocked_386MAX:
    mov dx, offset PSP_BLOCKED_386MAX
    call WRITEWRD
    jmp end_psp_type

print_belongs_386MAX_UMB:
    mov dx, offset PSP_BELONGS_386MAX
    call WRITEWRD
    jmp end_psp_type

print_psp_type:
    mov di, offset DEFAULT_PSP_TYPE
    add di, 3
    call WRD_TO_HEX
    mov dx, offset DEFAULT_PSP_TYPE
    call WRITEWRD

end_psp_type:
    pop di
    pop dx
    pop ax
    ret
MCB_PSP_TYPE endp

TASK_C PROC NEAR


    push ax
    push bx
    push dx
    push cx
    push si
    push di

    call ENDLINE
    mov dx, offset MCB_TABLE
    call WRITEWRD


    mov ah, 52h
    int 21h
    mov ax, es:[bx-2]
    mov es, ax

    xor cx, cx
    mov cl, 01h

mcb_for_each_loop:
    mov al, cl
    mov si, offset MCB_TABLE_NUMBER
    add si, 5

    call BYTE_TO_DEC

    mov dx, offset MCB_TABLE_NUMBER
    call WRITEWRD

    mov ax, es
    mov di, offset MCB_ADDRESS
    add di, 12
    call WRD_TO_HEX

    mov dx, offset MCB_ADDRESS
    call WRITEWRD

    mov ax, es:[1]

    call MCB_PSP_TYPE

    mov ax, es:[3]
    mov di, offset MCB_TABLE_SIZE
    add di, 9
    call WRD_TO_HEX

    mov dx, offset MCB_TABLE_SIZE
    call WRITEWRD

    mov bx, 8
    mov dx, offset MCB_SC_SD
    call WRITEWRD

    push cx
    mov cx, 7

    print_scsd_loop:
        mov dl, es:[bx]
        call WRITEBYTE

        inc bx
        loop print_scsd_loop

    call ENDLINE

    pop cx

    mov ah, es:[0]
    cmp ah, 5ah
    je end_task_1_c

    mov bx, es:[3]
    inc bx

    mov ax, es
    add ax, bx
    mov es, ax

    inc cl

    jmp mcb_for_each_loop

end_task_1_c:
    pop di
    pop si
    pop cx
    pop dx
    pop bx
    pop ax
    ret

TASK_C ENDP

ALLOC_MEMORY PROC NEAR

    push ax
    push bx
    push dx

    mov bx, 1000h
    mov ah, 48h
    int 21h

    pop dx
    pop bx
    pop ax

ALLOC_MEMORY ENDP

FREE_UNUSED_MEMORY PROC NEAR
    push ax
    push bx
    push dx

    xor dx, dx

    lea ax, lafin
    mov bx, 10h
    div bx

    add ax, dx
    mov bx,ax
    xor ax, ax

    mov ah,4Ah
    int 21h

    pop dx
    pop bx
    pop ax
    ret

FREE_UNUSED_MEMORY ENDP

begin:

    mov ah, 4ah
    mov bx, 0ffffh
    int 21h

    call TASK_A
    call TASK_B

    call FREE_UNUSED_MEMORY
    call ALLOC_MEMORY

    call TASK_C

    ; Выход в DOS
    xor al, al
    mov ah, 4ch
    int 21h
lafin:
TESTPC  ENDS
        END start
