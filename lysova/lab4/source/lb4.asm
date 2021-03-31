AStack	SEGMENT STACK
	DB 256 DUP(?)
AStack ENDS

DATA	SEGMENT

	flag DB 0
	INT_LOAD DB 'My interrupt has been loaded!', 0DH, 0AH, '$'
	INT_UNLOAD DB 'My interrupt has been unloaded!', 0DH, 0AH, '$'
	INT_NOT_LOAD DB 'My interrupt has not been loaded!', 0DH, 0AH, '$'
	INT_ALREADY_LOAD DB 'My interrupt has already been loaded!', 0DH, 0AH, '$'

DATA	ENDS

CODE	SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack

MY_INTERRUPT	PROC far
	jmp start_interrupt
	
	SIGN DW 7777h
	PSP DW ?
	
	KEEP_IP DW 0
	KEEP_CS DW 0
	KEEP_SS DW 0
	KEEP_SP DW 0
	KEEP_AX DW 0

	INT_COUNTER DB 'My interrupt: 0000$'
	
	INT_STACK DW 128 DUP (?)
END_INT_STACK:
	
start_interrupt:
	mov KEEP_SS, SS
	mov KEEP_SP, SP
	mov KEEP_AX, AX
	
	mov AX, CS
	mov SS, AX
	mov SP, OFFSET END_INT_STACK
	
	push BX
	push CX
	push DX
	
	; get cursor
	
	mov AH, 3h
	mov BH, 0h
	int 10h
	push DX
	
	; set cursor
	
	mov AH, 2h
	mov BH, 0h
	mov DH, 2h
	mov DL, 5h
	int 10h
	
	; inc counter
	
	push BP
	push SI
	push CX
	push DS
	
	mov AX, SEG INT_COUNTER
	mov DS, AX
	mov SI, OFFSET INT_COUNTER
	add SI, 14
	mov CX, 4
	
int_loop:
	mov BP, CX
	
	;dec BP
	
	mov AH, [SI+BP]
	inc AH
	mov [SI+BP], AH
	cmp AH, 3Ah
	jne succes
	mov AH, 30h
	mov [SI+BP], AH
	
	loop int_loop
	
succes:
	pop DS
	pop CX
	pop SI
	
	push ES
	mov DX, SEG INT_COUNTER
	mov ES, DX
	mov BP, OFFSET INT_COUNTER
	mov AH, 13h
	mov AL, 0h
	mov CX, 18
	mov DX, 0h
	int 10h
	
	pop ES
	pop BP
	
	; return cursor
	
	mov AH, 2h
	mov BH, 0h
	pop DX
	int 10h
	
	; end resident program
	
	pop DX
	pop CX
	pop BX
	
	mov AX, KEEP_SS
	mov SS, AX
	mov AX, KEEP_AX
	mov SP, KEEP_SP
	mov AL, 20h
	out 20h, AL
	
	iret
end_interrupt:
MY_INTERRUPT	ENDP

;----------------------------------------------------------------

LOAD	PROC near
	
	push    AX
	push    CX
	push    DX
	
	; storing offset and segment 

	mov     AH, 35h
	mov     AL, 1Ch
	int     21h
	mov     KEEP_IP, BX
	mov     KEEP_CS, ES
	
	; Interrupt setting 
	
        push    DS
        mov     DX, OFFSET MY_INTERRUPT
        mov     AX, SEG MY_INTERRUPT
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h
        pop     DS
        
	; Resident program preservation 
	
        mov     DX, OFFSET END_INT_STACK
        mov     CL, 4
        shr     DX, CL
        inc     DX
        mov     AX, CS
        sub     AX, PSP
        add     DX, AX
        xor     AX, AX
        mov     AH, 31h
        int     21h
        pop     DX
        pop     CX
        pop     AX
        ret
        
LOAD	ENDP
	
;-------------------------------------------------------

UNLOAD	PROC near

        push    AX
        push    DX
        push    SI
        push    ES
        
	; Recovery offset and segment 
	
        cli
        push    DS
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET KEEP_CS
        sub     SI, OFFSET MY_INTERRUPT
        mov     DX, ES:[BX+SI+2]
        mov     AX, ES:[BX+SI]
        mov     DS, AX
        mov     AH, 25h
        mov     AL, 1Ch
        int     21h
        pop     DS
        mov     AX, ES:[BX+SI-2]
        mov     ES, AX
        push    ES
        mov     AX, ES:[2Ch]
        mov     ES, AX
        mov     AH, 49h
        int     21h
        pop     ES
        mov     AH, 49h
        int     21h
        sti
        pop     ES
        pop     SI
        pop     DX
        pop     AX
        ret
        
UNLOAD	ENDP

;-------------------------------------------------------------

LOAD_FLAG	PROC near

        push    AX
        mov     AL, ES:[82h]
        cmp     AL, '/'
        jne     end_load_flag
        mov     AL, ES:[83h]
        cmp     AL, 'u'
        jne     end_load_flag
        mov     AL, ES:[84h]
        cmp     AL, 'n'
        jne     end_load_flag
        mov     flag, 1
end_load_flag: 
	pop     AX

LOAD_FLAG	ENDP

;----------------------------------------------------------------

IS_LOAD	PROC near

        push    AX
        push    DX
        push    SI
        mov     flag, 1
        mov     AH, 35h
        mov     AL, 1Ch
        int     21h
        mov     SI, OFFSET SIGN
        sub     SI, OFFSET MY_INTERRUPT
        mov     DX, ES:[BX+SI]
        cmp     DX, 7777h
        je      loading
        
        mov     flag, 0
loading:     
	pop     SI
        pop     DX
        pop     AX
        ret
        
IS_LOAD	ENDP

;------------------------------------------------

PRINT_STRING	PROC near
        push    AX
        mov     AH, 09h
        int     21h
        pop     AX
        ret
PRINT_STRING	ENDP

;------------------------------------------------------

MAIN	PROC far

        mov     AX, DATA
        mov     DS, AX
        mov     PSP, ES
        mov     flag, 0
        call    LOAD_FLAG
        cmp     flag, 1
        je      un
        
	; loading
	
        call    IS_LOAD
        cmp     flag, 0
        je      notld
        mov     DX, OFFSET INT_ALREADY_LOAD
        call    PRINT_STRING
        jmp     fin
       
notld:  mov     DX, OFFSET INT_LOAD
        call    PRINT_STRING
        call    LOAD
        jmp     fin
        
	; unloading

un:     call    IS_LOAD
        cmp     flag, 0
        jne     alrld
        mov     DX, OFFSET INT_NOT_LOAD
        call    PRINT_STRING
        jmp     fin
        
        ; already loading
        
alrld:  call    UNLOAD
        mov     DX, OFFSET INT_UNLOAD
        call    PRINT_STRING
        
fin:    mov     AX, 4Ch
        int     21h
        
MAIN	ENDP
CODE	ENDS
	END	MAIN
