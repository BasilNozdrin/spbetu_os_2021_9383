TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H

START: JMP BEGIN


pc db 'IBM PC type: PC',0dh,0ah,'$'
pc_xt db 'IBM PC type: PC/XT',0dh,0ah,'$'
at db 'IBM PC type: AT',0dh,0ah,'$'
ps2_30 db 'IBM PC type: PS2 model 30',0dh,0ah,'$'
ps2_50_60 db 'IBM PC type: PS2 model 30 or 50',0dh,0ah,'$'
ps2_80 db 'IBM PC type: PS2 model 80',0dh,0ah,'$'
pcjr db 'IBM PC type: PCjr',0dh,0ah,'$'
pc_convertible db 'IBM PC type: PC Convertible',0dh,0ah,'$'
unknown db 'IBM PC type:    ',0dh,0ah,'$'
version db 'Version:  . ',0dh,0ah,'$'
oem db 'OEM:             ',0dh,0ah,'$'
user_serial_number db 'User serial number:       ',0dh,0ah,'$'


;------------------------------
BYTE_TO_DEC PROC near
    push AX
    push BX
    push CX
    push DX
    xor AH,AH
    xor DX,DX
    mov CX,10
loop_bd:
    div CX
    or DL,30h
    mov [SI],DL
    dec SI
    xor DX,DX
    cmp AX,10
    jae loop_bd
    cmp AL,00h
    je end_l
    or AL,30h
    mov [SI],AL
end_l: 
    pop DX
    pop CX 
    pop BX
    pop AX
    ret
BYTE_TO_DEC ENDP
;------------------------------
TETR_TO_HEX PROC near
    and AL,0Fh
    cmp AL,09
    jbe NEXT
    add AL,07
    NEXT: add AL,30h
    ret
TETR_TO_HEX ENDP
;------------------------------
BYTE_TO_HEX PROC near
    ; байт в AL переводится в два символа шестн. числа в AX
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX ;в AL старшая цифра
    pop CX ;в AH младшая
    ret
BYTE_TO_HEX ENDP
;------------------------------
WRD_TO_HEX PROC near
    push BX
    mov BH,AH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    dec DI
    mov AL,BH
    call BYTE_TO_HEX
    mov [DI],AH
    dec DI
    mov [DI],AL
    pop BX
    ret
WRD_TO_HEX ENDP
;------------------------------





BEGIN:
    xor ax,ax
    mov ax,0f000h
    mov es,ax
    mov al,es:[0fffeh]

    cmp al,0ffh
    je label_pc
    cmp al,0feh
    je label_pc_xt
    cmp al,0fbh
    je label_pc_xt
    cmp al,0fch
    je label_at
    cmp al,0fah
    je label_ps2_30
    cmp al,0fch
    je label_ps2_50_60
    cmp al,0f8h
    je label_ps2_80
    cmp al,0fdh
    je label_pcjr
    cmp al,0f9h
    je label_pc_convertible
    jne label_unknown

label_pc:
    mov dx,offset pc
    jmp print_ibm_pc_version
label_pc_xt:
    mov dx,offset pc_xt
    jmp print_ibm_pc_version
label_at:
    mov dx,offset at
    jmp print_ibm_pc_version
label_ps2_30:
    mov dx,offset ps2_30  
    jmp print_ibm_pc_version
label_ps2_50_60:
    mov dx,offset ps2_50_60
    jmp print_ibm_pc_version
label_ps2_80:
    mov dx,offset ps2_80
    jmp print_ibm_pc_version
label_pcjr:
    mov dx,offset pcjr
    jmp print_ibm_pc_version
label_pc_convertible:
    mov dx,offset pc_convertible
    jmp print_ibm_pc_version
label_unknown:
    call BYTE_TO_HEX
    mov di, offset unknown+13
    mov [di], ax
    mov dx,offset unknown


print_ibm_pc_version:
    mov ah,09h
    int 21h

    xor bx, bx
    xor ax, ax
    mov ah, 30h
    int 21h

    ;Version
    mov si, offset version+9
    call BYTE_TO_DEC

    mov al, ah
    mov si, offset version+11
    call BYTE_TO_DEC

    mov dx, offset version
    mov ah,09h
    int 21h

    ;OEM
    mov al, bh
    mov si, offset oem+7
    call BYTE_TO_DEC
    
    mov dx, offset oem
    mov ah,09h
    int 21h

    ;User serial number
    mov al, bl
    call BYTE_TO_HEX

    mov di, offset user_serial_number+20
    mov [di], ax

    mov ax, cx
    mov di, offset user_serial_number+25
    call WRD_TO_HEX

    mov dx, offset user_serial_number
    mov ah,09h
    int 21h

exit:
    xor al,al
    mov ah,4ch
    int 21h
TESTPC ENDS
END START