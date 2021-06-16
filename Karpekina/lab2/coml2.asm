TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING    
   ORG 100H
START: JMP BEGIN


UN_MEM_AD db  'Unavailable memory segment adress:     ',0DH,0AH,'$'
SEG_ENV_AD db 'Segment address of the environment:    ',0DH,0AH,'$'
STR_TAIL db 'Tail of command line:          ',0DH,0AH,'$'
TAIL_EMPTY db 'Tail of command line is empty    ',0DH,0AH,'$'
CONTENT_ENV db 'Content of the environment area:',0DH,0AH, '$'
STR_END db 0DH,0AH, '$'
PATH db 'Path:  ',0DH,0AH, '$'



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

MEM_AD PROC near
    mov ax, ds:[02h]     
    mov di, offset UN_MEM_AD
    add di, 37
    call WRD_TO_HEX
    mov dx, offset UN_MEM_AD
    mov AH,09h
    int 21h
    ret
MEM_AD	ENDP

ENV_AD PROC near
    mov ax, ds:[02Ch]     
    mov di, offset SEG_ENV_AD
    add di, 38
    call WRD_TO_HEX
    mov dx, offset SEG_ENV_AD
    mov AH,09h
    int 21h
    ret
ENV_AD ENDP

TAIL PROC near
    xor cx, cx
    mov cl, ds:[80h]   
    mov si, offset STR_TAIL
    add si, 21
    cmp cl, 0h
    je empty 
    mov di, 0
    mov ax, 0
	
read: 
    mov al, ds:[81h+di]
    inc di
    mov [si], al
    inc si
    loop read
    mov dx, offset STR_TAIL
    jmp print
	
empty:
    mov dx, offset TAIL_EMPTY
	
print: 
    mov AH,09h
    int 21h
    ret
TAIL ENDP

ENV PROC near
    mov dx, offset CONTENT_ENV
    mov AH,09h
    int 21h
    xor di, di
    mov ds, ds:[2Ch]
r_str:
    cmp byte ptr [di], 0
    je s_end
    mov dl, [di]
    mov ah, 02h
    int 21h
    jmp find
s_end:
    cmp byte ptr [di+1],00h
    je find
    push ds
    mov cx, cs
    mov ds, cx
    mov dx, offset STR_END
    mov AH,09h
    int 21h
    pop ds
find:
    inc di
    cmp word ptr [di], 0001h
    je r_path
    jmp r_str
r_path:
    push ds
    mov ax, cs
    mov ds, ax
    mov dx, offset PATH
    mov AH,09h
    int 21h
    pop ds
    add di, 2
loop_p:
    cmp byte ptr [di], 0
    je break
    mov dl, [di]
    mov ah, 02h
    int 21h
    inc di
    jmp loop_p
break:
    ret
ENV ENDP

BEGIN:
    call MEM_AD
    call ENV_AD
    call TAIL
    call ENV    

    xor AL,AL
    mov AH,4Ch
    int 21H
TESTPC ENDS
END START