TESTPC  SEGMENT
        ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
        ORG 100H

START: JMP BEGIN



seg_memory db 'Memory address:       ',0DH,0AH,'$'
environment_seg_address db 'Environment segment address:       ',0DH,0AH,'$'
command_line_tail db 'Command-line_tail:$'
environment_content db 'Environment content:',0DH,0AH,'$'
path db 'Path: $'
endl db ' ',0DH,0AH,'$'



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

    ;SEGMENT MEMORY
    mov ax, ds:[02h]
    mov di, offset seg_memory+19
    call WRD_TO_HEX

    mov dx, offset seg_memory
    mov ah,09h
    int 21h




    ;Environment segment address
    mov ax, ds:[02ch]
    mov di, offset environment_seg_address+32
    call WRD_TO_HEX

    mov dx, offset environment_seg_address
    mov ah,09h
    int 21h



    xor cx, cx
    mov cl, ds:[080h]

    cmp cl, 00h
    je read_environment_content

    ;CMD Tail
    mov dx, offset command_line_tail
    mov ah,09h
    int 21h
    
    xor di, di
    mov ah, 02h
    cmd_tail_loop:
        mov dl, ds:[081h+di]
        int 21h
        inc di
    loop cmd_tail_loop

    ;new line
    mov dl, 0DH
    int 21h
    mov dl, 0AH
    int 21h



    read_environment_content:
    ;Environment content
    mov dx, offset environment_content
    mov ah,09h
    int 21h

    mov bx, [2ch]
    mov es, [bx]
    mov ah, 02h
    xor di, di

    env_content_loop:
        mov dl, es:[di]
        cmp dl, 00h
        je env_content_loop_end
        int 21h
        inc di
        jmp env_content_loop
    env_content_loop_end:
        inc di
        mov dl, es:[di]
        cmp dl, 00h
        je read_path
        ;new line
        mov dl, 0DH
        int 21h
        mov dl, 0AH
        int 21h
        jmp env_content_loop

    read_path:
        add di, 3
        ;new line
        mov dl, 0DH
        int 21h
        mov dl, 0AH
        int 21h

        mov dx, offset path
        mov ah, 09h
        int 21h
        mov ah, 02h
        read_path_loop:
            mov dl, es:[di]
            cmp dl, 00h
            je exit
            int 21h
            inc di
            jmp read_path_loop





exit:
    ; mov dx, offset endl
    ; mov ah, 09h
    ; int 21h

    xor al,al
    mov AH,01h
    int 21h

    mov ah,4ch
    int 21h
TESTPC ENDS
END START