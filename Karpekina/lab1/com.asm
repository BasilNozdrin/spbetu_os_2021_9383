TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING    
   ORG 100H    
START: JMP BEGIN

PC db  'My PC: PC',0DH,0AH,'$'
XT db 'My PC: PC/XT',0DH,0AH,'$'
AT db  'My PC: AT',0DH,0AH,'$'
M30 db 'My PC: PS2 model 30',0DH,0AH,'$'
M50_M60 db 'My PC: PS2 model 50 or 60',0DH,0AH,'$'
M80 db 'My PC: PS2 model 80',0DH,0AH,'$'
JR db 'My PC: PCjr',0DH,0AH,'$'
C db 'My PC: PC Convertible',0DH,0AH,'$'
VER db 'Version Dos:  .  ',0DH,0AH,'$'
OEM_NUM db  'OEM number:  ',0DH,0AH,'$'
USER_NUM db  'User number:        $'

TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
next:
   add AL,30h
   ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
    push CX
    mov AH,AL
    call TETR_TO_HEX
    xchg AL,AH
    mov CL,4
    shr AL,CL
    call TETR_TO_HEX
    pop CX 
    ret
BYTE_TO_HEX ENDP

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

BYTE_TO_DEC PROC near
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
    ret
BYTE_TO_DEC ENDP

PC_T PROC near
    mov ax, 0f000h      
    mov es, ax
    mov al, es:[0fffeh]  

    cmp al, 0ffh         
    je pc_pc

    cmp al, 0feh
    je xt_pc

    cmp al, 0fbh
    je xt_pc

    cmp al, 0fch
    je at_pc

    cmp al, 0fah
    je m30_pc2

    cmp al, 0fch
    je m50_m60_2pc

    cmp al, 0f8h
    je m80_pc2

    cmp al, 0fdh
    je jr_pc
 
    cmp al, 0f9h
    je c_pc

pc_pc:
    mov dx, offset PC
    jmp print

xt_pc:
    mov dx, offset XT
    jmp print

at_pc:
    mov dx, offset AT
    jmp print

m30_pc2:
    mov dx, offset M30
    jmp print

m50_m60_2pc:
    mov dx, offset M50_M60
    jmp print

m80_pc2:
    mov dx, offset M80
    jmp print

jr_pc:
    mov dx, offset JR
    jmp print

c_pc:
    mov dx, offset C
    jmp print

print:
    mov AH,09h
    int 21h
    ret
PC_T ENDP

OS_T PROC near
    mov ah, 30h
    int 21h

    mov si, offset VER
    add si, 13       
    call BYTE_TO_DEC
    mov al, ah
    add si, 3       
    call BYTE_TO_DEC
    mov dx, offset VER
    mov AH,09h
    int 21h
	
    mov si, offset OEM_NUM
    add si, 12      
    mov al, bh
    call BYTE_TO_DEC
    mov dx, offset OEM_NUM
    mov AH,09h    
    int 21h
	
    mov di, offset USER_NUM
    add di, 18   
    mov ax, cx
    call WRD_TO_HEX
    mov al, bl
    call BYTE_TO_HEX
    sub di, 2
    mov [di], ax
    mov dx, offset USER_NUM
    mov AH,09h   
    int 21h
    ret

OS_T ENDP

BEGIN:
   call PC_T
   call OS_T

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START