TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H

START: JMP BEGIN



memory_size db 'Available memory:                 ',0DH,0AH,'$'
extended_size db 'Extended memory:       ',0DH,0AH,'$'
MCB_Type db 'MCB Type:      $'
PSP_Segment_Address db 'PSP Segment Address:        $'
MCB_Size db 'MCB Size:           $'
SCCD db 'SC/CD: $'
;------------------------------
BYTE_TO_DEC PROC near
    push CX
    push DX
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
    ; Memory
    mov ah,4ah
    mov bx,0ffffh
    int 21h

    xor ax,ax
    mov ax, bx
    mov cx, 10h
    mul cx

    mov si, offset memory_size+23
    call BYTE_TO_DEC


    mov DX,offset memory_size
    mov AH,09h
    int 21h
    
    ;clean memory
    mov ax, offset _end
    mov bx, 10h
    xor dx, dx
    div bx
    inc ax
    mov bx, ax
    mov al, 0h
    mov ah, 4ah
    int 21h


    ; Extended
    mov AL,30h
    out 70h,AL
    in AL,71h
    mov BL,AL
    mov AL,31h 
    out 70h,AL
    in AL,71h

    mov ah, al
    mov al, bl

    mov si, offset extended_size+21
    xor dx, dx
    call BYTE_TO_DEC

    mov DX,offset extended_size
    mov AH,09h
    int 21h


    ;MCB
    mov ah, 52h
    int 21h
    mov ax, es:[bx-2]    
    mov es, ax

    read_mcb:
    ;MCB Type
    mov al, es:[0h]
    call BYTE_TO_HEX
    mov si, offset MCB_Type+10

    mov [si], ax
    mov DX,offset MCB_Type
    mov AH,09h
    int 21h

    ;PSP Segment
    mov ax, es:[1h]
    mov di, offset PSP_Segment_Address+24
    call WRD_TO_HEX

    mov DX,offset PSP_Segment_Address
    mov AH,09h
    int 21h

    ;Size
    mov ax, es:[3h]
    mov cx, 10h
    mul cx
    mov si, offset MCB_Size+14
    xor dx, dx
    call BYTE_TO_DEC

    mov DX,offset MCB_Size
    mov AH,09h
    int 21h

    ;Symbols
    mov DX,offset SCCD
    mov AH,09h
    int 21h

    mov ah, 02h
    mov cx, 8
    xor bx, bx
    print_symbols:
        mov dl, es:[8h+bx]
        int 21h
        inc bx
    loop print_symbols

    mov dl, 0dh
    int 21h
    mov dl, 0ah
    int 21h

    cmp byte ptr es:[0000h], 05Ah
    je exit
    mov ax, es
    add ax, es:[3h]
    inc ax
    mov es, ax
    jmp read_mcb
    
exit:
    xor al,al
    mov ah,4ch
    int 21h

_end:
TESTPC ENDS
END START