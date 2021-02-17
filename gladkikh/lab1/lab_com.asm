TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
org 100h

start: jmp begin

PC_STRING db 'IBM PC Type: PC', 0DH, 0AH, '$'
PCXT_STRING db 'IBM PC Type: PC/XT', 0DH, 0AH, '$'
AT_STRING db 'IBM PC Type: AT', 0DH, 0AH, '$'
PS2_MODEL_30_STRING db 'IBM PC Type: PS2 Model 30', 0DH, 0AH, '$'
PS2_MODEL_50_or_60_STRING db 'IBM PC Type: PS2 Model 50 or 60', 0DH, 0AH, '$'
PS2_MODEL_80_STRING db 'IBM PC Type: PS2 Model 80', 0DH, 0AH, '$'
PCjr_STRING db 'IBM PC Type: PCjr', 0DH, 0AH, '$'
PC_Convertible_STRING db 'IBM PC Type: PC Convertible', 0DH, 0AH, '$'
PC_TYPE_UNKNOWN db 'IBM PC Type Unknown, code:  ', 0DH, 0AH, '$'

VERSION_LESS_2_NUM_STRING db 'MS DOS Version: < 2.0', 0DH, 0AH, '$'
VERSION_NUM_STRING db 'MS DOS Version: . ', 0DH, 0AH, '$'
OEM_NUM_STRING db 'MS DOS OEM:                       ', 0DH, 0AH, '$'
SERIAL_NUM_STRING db 'MS DOS Serial number:      ', 0DH, 0AH, '$'


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

WRITEMSG  PROC  NEAR
    push ax
    mov ah, 9
    int 21h
    pop ax
    ret
WRITEMSG  ENDP

TASK_1 PROC NEAR

    push ax
    push bx
    push dx
    push es
    push di

    mov ax, 0F000h
    mov es, ax
    mov di, 0FFFEh
    mov al, es:[di]

    cmp al, 0FFh
    je pc

    cmp al, 0FEh
    je pc_xt

    cmp al, 0FBh
    je pc_xt

    cmp al, 0FCh
    je at

    cmp al, 0FAh
    je ps2_model_30

    cmp al, 0FCh
    je ps2_model_50_or_60

    cmp al, 0F8h
    je ps2_model_80

    cmp al, 0FDh
    je pcjr

    cmp al, 0F9h
    je pc_convertible


    call BYTE_TO_HEX
    mov di, offset PC_TYPE_UNKNOWN
    mov [di + 26], al
    mov [di + 27], ah
    mov dx, di
    call WRITEMSG
    jmp end_task1


pc:
    mov dx, offset PC_STRING
    call WRITEMSG
    jmp end_task1

pc_xt:
    mov dx, offset PCXT_STRING
    call WRITEMSG
    jmp end_task1

at:
    mov dx, offset AT_STRING
    call WRITEMSG
    jmp end_task1

ps2_model_30:
    mov dx, offset PS2_MODEL_30_STRING
    call WRITEMSG
    jmp end_task1

ps2_model_50_or_60:
    mov dx, offset PS2_MODEL_50_or_60_STRING
    call WRITEMSG
    jmp end_task1

ps2_model_80:
    mov dx, offset PS2_MODEL_80_STRING
    call WRITEMSG
    jmp end_task1

pcjr:
    mov dx, offset PCjr_STRING
    call WRITEMSG
    jmp end_task1

pc_convertible:
    mov dx, offset PC_Convertible_STRING
    call WRITEMSG
    jmp end_task1

end_task1:
    pop di
    pop es
    pop dx
    pop bx
    pop ax

    ret

TASK_1 ENDP

TASK_2 PROC NEAR

    push ax
    push bx
    push dx
    push es
    push di

    mov ah, 30h
    int 21h

    ;al - version number
    ;ah - mod number
    ;bh - OEM number
    ;bl:cx - serial number
    
    cmp al, 0h
    je less_than_2

    push ax
    call BYTE_TO_DEC
    lodsw

    mov di, offset VERSION_NUM_STRING
    mov [di + 15], ah

    pop ax

    xchg ah, al
    call BYTE_TO_DEC
    lodsw
    mov [di + 17], ah
    mov dx, di
    call WRITEMSG
    jmp after_version

less_than_2:

    mov dx, offset VERSION_LESS_2_NUM_STRING
    call WRITEMSG

after_version:

    mov al, bh
    call BYTE_TO_HEX
    mov di, offset OEM_NUM_STRING
    mov [di + 11], al
    mov [di + 12], ah

    mov dx, di
    call WRITEMSG

    mov al, bl
    call BYTE_TO_HEX
    mov di, offset SERIAL_NUM_STRING
    mov [di + 21], al
    mov [di + 22], ah

    mov ax, cx
    add di, 26
    call WRD_TO_HEX

    mov dx, offset SERIAL_NUM_STRING
    call WRITEMSG

    pop di
    pop es
    pop dx
    pop bx
    pop ax

    ret

TASK_2 ENDP


begin:

    call TASK_1

    call TASK_2

    ; Выход в DOS
    xor al, al
    mov ah, 4ch
    int 21h

TESTPC  ENDS
        END start
