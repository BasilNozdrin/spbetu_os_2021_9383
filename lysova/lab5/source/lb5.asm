AStack  SEGMENT STACK
 DW  256 dup(?)
AStack  ENDS


DATA SEGMENT
    IS_LOAD         DB                                            0
    IS_UN           DB                                            0
    STR_LOAD        DB      "My interrupt has been loaded!", 0DH, 0AH, "$"
    STR_LOADED      DB      "My interrupt has been already loaded!", 0DH, 0AH, "$"
    STR_UNLOAD      DB      "My interrupt has been unloaded!", 0DH, 0AH, "$"
    STR_NOT_LOADED  DB      "My interrupt has not been loaded!", 0DH, 0AH, "$"
DATA ENDS

CODE SEGMENT
ASSUME  CS:CODE, DS:DATA, SS:AStack


MY_INTERRUPTION PROC FAR
    jmp  Start

intData:
    key_value DB 0
    key_code DB 01h
    signature DW 6666h
    keep_ip DW 0
    keep_cs DW 0
    keep_psp DW 0
    keep_ax DW 0
    keep_ss DW 0
    keep_sp DW 0
    
    new_stack DW 256 dup(?)

Start:
    mov keep_ax, AX
    mov keep_sp, SP
    mov keep_ss, SS
    mov AX, SEG new_stack
    mov SS, AX
    mov AX, OFFSET new_stack
    add AX, 256
    mov SP, AX

    push AX
    push BX
    push CX
    push DX
    push SI
    push ES
    push DS
    mov AX, SEG key_value
    mov DS, AX

    in AL, 60h
    cmp AL, key_code
    je key_esc
    cmp AL, 1Eh 
    je key_a
    cmp AL, 30h
    je key_b
    cmp AL, 2Eh
    je key_c

    pushf
    call dword ptr CS:keep_ip
    jmp end_interruption

key_esc:
    mov key_value, '*'
    jmp next_key
key_a:
    mov key_value, '1'
    jmp next_key
key_b:
    mov key_value, '2'
    jmp next_key
key_c:
    mov key_value, '3'

next_key:
    in AL, 61h
    mov AH, AL
    or AL, 80h
    out 61h, AL
    xchg AL, AL
    out 61h, AL
    mov AL, 20h
    out 20h, AL

print_key:
    mov AH, 05h
    mov CL, key_value
    mov CH, 00h
    int 16h
    or AL, AL
    jz end_interruption
    mov AX, 40h
    mov ES, AX
    mov AX, ES:[1Ah]
    mov ES:[1Ch], AX
    jmp print_key


end_interruption:
    pop  DS
    pop  ES
    pop  SI
    pop  DX
    pop  CX
    pop  BX
    pop  AX

    mov SP, keep_sp
    mov AX, keep_ss
    mov SS, AX
    mov AX, keep_ax

    mov  AL, 20h
    out  20h, AL
    iret
MY_INTERRUPTION ENDP
 _end:


is_int_loaded PROC near
    push AX
    push BX
    push SI

    mov  AH, 35h
    mov  AL, 09h
    int  21h
    mov  SI, OFFSET signature
    sub  SI, OFFSET MY_INTERRUPTION
    mov  AX, ES:[BX + SI]
    cmp  AX, signature
    jne  end_proc
    mov  is_load, 1

end_proc:
    pop  SI
    pop  BX
    pop  AX
    ret
is_int_loaded ENDP

int_load  PROC near
    push AX
    push BX
    push CX
    push DX
    push ES
    push DS

    mov AH, 35h
    mov AL, 09h
    int 21h
    mov keep_cs, ES
    mov keep_ip, BX
    mov AX, SEG MY_INTERRUPTION
    mov DX, OFFSET MY_INTERRUPTION
    mov DS, AX
    mov AH, 25h
    mov AL, 09h
    int 21h
    pop DS

    mov DX, OFFSET _end
    mov CL, 4h
    shr DX, CL
    add DX, 10Fh
    inc DX
    xor AX, AX
    mov AH, 31h
    int 21h

    pop ES
    pop DX
    pop CX
    pop BX
    pop AX
ret
int_load  ENDP


unload_interrupt PROC near
    cli
    push AX
    push BX
    push DX
    push DS
    push ES
    push SI

    mov AH, 35h
    mov AL, 09h
    int 21h
    mov SI, OFFSET keep_ip
    sub SI, OFFSET MY_INTERRUPTION
    mov DX, ES:[BX + SI]
    mov AX, ES:[BX + SI + 2]

    push DS
    mov DS, AX
    mov AH, 25h
    mov AL, 09h
    int 21h
    pop DS

    mov AX, ES:[BX + SI + 4]
    mov ES, AX
    push ES
    mov AX, ES:[2Ch]
    mov ES, AX
    mov AH, 49h
    int 21h
    pop ES
    mov AH, 49h
    int 21h

    sti

    pop SI
    pop ES
    pop DS
    pop DX
    pop BX
    pop AX

ret
unload_interrupt ENDP


is_unload_  PROC near
    push AX
    push ES

    mov AX, keep_psp
    mov ES, AX
    cmp byte ptr ES:[82h], '/'
    jne end_unload
    cmp byte ptr ES:[83h], 'u'
    jne end_unload
    cmp byte ptr ES:[84h], 'n'
    jne end_unload
    mov is_un, 1

end_unload:
    pop ES
    pop AX
 ret
is_unload_ ENDP


PRINT PROC near
    push AX
    mov AH, 09h
    int 21h
    pop AX
ret
PRINT ENDP


BEGIN PROC far
    push DS
    xor AX, AX
    push AX
    mov AX, DATA
    mov DS, AX
    mov keep_psp, ES

    call is_int_loaded
    call is_unload_
    cmp is_un, 1
    je unload
    mov AL, is_load
    cmp AL, 1
    jne load
    mov DX, OFFSET str_loaded
    call PRINT
    jmp end_begin

load:
    mov DX, OFFSET str_load
    call PRINT
    call int_load
    jmp  end_begin

unload:
    cmp  is_load, 1
    jne  not_loaded
    mov DX, OFFSET str_unload
    call PRINT
    call unload_interrupt
    jmp  end_begin

not_loaded:
    mov  DX, offset str_not_loaded
    call PRINT

end_begin:
    xor AL, AL
    mov AH, 4ch
    int 21h
BEGIN ENDP
CODE ENDS

END BEGIN
