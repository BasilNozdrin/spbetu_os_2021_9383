CODE	SEGMENT
	ASSUME CS:CODE, DS:CODE, ES:NOTHING, SS:NOTHING
	begin = $
	ORG 100H
START:
	jmp MAINflag
	ENTER    db 0Dh, 0Ah, '$'
	AVAILABLE_MEM   db 'Size of available memory: $'
	EXPANDED_MEM   db 'Size of expanded memory: $'
	HEAD_TABLE   db '  ', 179, ' PSP address ', 179, ' Area size ', 179, ' SC/SD$'
	LINE_TABLE   db 2 dup (196), 197, 13 dup (196), 197, 11 dup (196), 197, 8 dup (196), '$'
	
PRINT_STRING	PROC near

        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
        ret
        
PRINT_STRING	ENDP


PRINT_CHAR	PROC near

        push    AX
        mov     AH, 02h
        int     21h
        pop     AX
        ret
        
PRINT_CHAR	ENDP


ENTR	PROC near

        push    AX
        push    DX
        mov     DX, OFFSET ENTER
        mov     AH, 09h
        int     21h
        pop     DX
        pop     AX
        ret
        
ENTR	ENDP


TABLE	PROC near

        push    AX
        push    CX
        push    DX
        xor     CH, CH
        mov     CL, AL
table_loop:  
	mov     AH, 02h
        mov     DL, 20h
        int     21h
        loop    table_loop
        
        mov     AH, 02h
        mov     DL, 179
        int     21h
        mov     AH, 02h
        mov     DL, 20h
        int     21h
        pop     DX
        pop     CX
        pop     AX
        ret
        
TABLE	ENDP


FREE	PROC near

        push    AX
        push    BX
        push    DX
        xor     DX, DX
        mov     AX, endproc - begin
        mov     BX, 16
        div     BX
        mov     BX, AX
        inc     BX
        mov     AH, 4Ah
        int     21h
        pop     DX
        pop     BX
        pop     AX
        ret
        
FREE	ENDP


HEX_TO_WRD	PROC near

        cmp     AL, 9
        ja      lttr
        add     AL, 30h
        jmp     ok
lttr:   
	add     AL, 37h
ok:     
	ret

HEX_TO_WRD	ENDP


PRINT_HEX	PROC near

        push    AX
        push    BX
        push    CX
        push    DX
        mov     BX, 0F000h
        mov     DL, 12
        mov     CX, 4
        
loop_hex: 
	push    CX
        push    AX
        and     AX, BX
        mov     CL, DL
        shr     AX, CL
        call    HEX_TO_WRD
        push    DX
        mov     DL, AL
        call    PRINT_CHAR
        pop     DX
        inc     SI
        pop     AX
        mov     CL, 4
        shr     BX, CL
        sub     DL, 4
        pop     CX
        loop    loop_hex
        pop     DX
        pop     CX
        pop     BX
        pop     AX
        ret
        
PRINT_HEX	ENDP


PRINT_DEC	PROC near

        push    AX
        push    BX
        push    CX
        push    DX
        mov     BX, 10
        xor     CX, CX
div_dec:  
	div     BX
	push    DX
        inc     CX
        xor     DX, DX
        cmp     AX, 0
        jne     div_dec
        mov     DI, CX
loop_dec:
	pop     DX
        xor     DH, DH
        add     DL, 30h
        call    PRINT_CHAR
        loop    loop_dec
        pop     DX
        pop     CX
        pop     BX
        pop     AX
        ret
        
PRINT_DEC	ENDP


MAINflag:
; available memory 
        mov     DX, OFFSET AVAILABLE_MEM
        call    PRINT_STRING
        mov     AH, 4Ah
        mov     BX, 0FFFFh
        int     21h
        mov     AX, BX
        mov     BX, 16
        mul     BX
        call    PRINT_DEC
        call    ENTR
; expanded memory
        mov     DX, OFFSET EXPANDED_MEM
        call    PRINT_STRING
        mov     AL, 30h
        out     70h, AL
        in      AL, 71h
        mov     AH, AL
        mov     AL, 31h
        out     70h, AL
        in      Al, 71h
        xchg    AH, AL
        mov     BX, 16
        mul     BX
        call    PRINT_DEC
        call    ENTR
        
        call    FREE
        
; list of MCB 
        call    ENTR
        mov     DX, OFFSET HEAD_TABLE
        call    PRINT_STRING
        call    ENTR
        mov     DX, OFFSET LINE_TABLE
        call    PRINT_STRING
        call    ENTR
        mov     AH, 52h
        int     21h
        mov     ES, ES:[BX-2]
        mov     CX, 1
list:   
	mov     AX, CX
        xor     DX, DX
        call    PRINT_DEC
        mov     AL, 1
        call    TABLE
        mov     AX, ES:[01h]
        call    PRINT_HEX
        mov     AL, 8
        call    TABLE
        mov     AX, ES:[03h]
        mov     DX, 16
        mul     DX
        call    PRINT_DEC
        mov     DX, 10
        sub     DX, DI
        mov     AX, DX
        call    TABLE
        push    CX
        push    DS
        mov     AX, ES
        mov     DS, AX
        mov     AH, 40h
        mov     BX, 1
        mov     CX, 8
        mov     DX, OFFSET ES:[08h]
        int     21h
        pop     DS
        pop     CX
        inc     CX
        mov     AL, ES:[00h]
        cmp     AL, 5Ah
        je      end_main
        cmp     AL, 4Dh
        jne     end_main
        mov     AX, ES:[03h]
        mov     DX, ES
        add     AX, DX
        inc     AX
        mov     ES, AX
        call    ENTR
        jmp     list

end_main:    
	mov     AX, 4C00h
        int     21h

endproc = $

CODE	ENDS
	END	START
