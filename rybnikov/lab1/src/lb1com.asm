TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
TYPE_PC db  'Type: PC',0DH,0AH,'$'
TYPE_PC_XT db 'Type: PC/XT',0DH,0AH,'$'
TYPE_AT db  'Type: AT',0DH,0AH,'$'
TYPE_PS2_M30 db 'Type: PS2 модель 30',0DH,0AH,'$'
TYPE_PS2_M50_60 db 'Type: PS2 модель 50 или 60',0DH,0AH,'$'
TYPE_PS2_M80 db 'Type: PS2 модель 80',0DH,0AH,'$'
TYPE_PС_JR db 'Type: PСjr',0DH,0AH,'$'
TYPE_PC_CONV db 'Type: PC Convertible',0DH,0AH,'$'

VERSIONS db 'Version MS-DOS:  .  ',0DH,0AH,'$'
SERIAL_NUMBER db  'Serial number OEM:  ',0DH,0AH,'$'
USER_NUMBER db  'User serial number:       H $'


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


WRITESTRING PROC near
   mov AH,09h
   int 21h
   ret
WRITESTRING ENDP

T_PC PROC near
  mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh
	je pc

	cmp al, 0feh
  je xt

	cmp al, 0fbh
  je xt

	cmp al, 0fch
	je at

	cmp al, 0fah
	je ps2_m30

	cmp al, 0f8h
	je ps2_m80

	cmp al, 0fdh
	je jr

	cmp al, 0f9h
	je conv

pc:
		mov dx, offset TYPE_PC
		jmp write

xt:
		mov dx, offset TYPE_PC_XT
		jmp write

at:
		mov dx, offset TYPE_AT
		jmp write

ps2_m30:
		mov dx, offset TYPE_PS2_M30
		jmp write

ps2_m50_60:
		mov dx, offset TYPE_PS2_M50_60
		jmp write

ps2_m80:
		mov dx, offset TYPE_PS2_M80
		jmp write

jr:
		mov dx, offset TYPE_PС_JR
		jmp write

conv:
		mov dx, offset TYPE_PC_CONV
		jmp write

write:
		call WRITESTRING
    ret

T_PC ENDP

CHECK_OS_VER PROC near
	mov ah, 30h
	int 21h
	push ax

	mov si, offset VERSIONS
	add si, 16
	call BYTE_TO_DEC
   pop ax
   mov al, ah
   add si, 3
	call BYTE_TO_DEC
	mov dx, offset VERSIONS
	call WRITESTRING

	mov si, offset SERIAL_NUMBER
	add si, 19
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL_NUMBER
	call WRITESTRING

	mov di, offset USER_NUMBER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER_NUMBER
	call WRITESTRING
	ret
CHECK_OS_VER ENDP


BEGIN:
   call T_PC
   call CHECK_OS_VER

   xor al, al
   mov ah, 4Ch
   int 21h
TESTPC ENDS
END START
