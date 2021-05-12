AStack    SEGMENT  STACK
          DW 128 DUP(?)
AStack    ENDS

DATA  SEGMENT
   TYPE_PC db  'Type: PC',0DH,0AH,'$'
   TYPE_PC_XT db 'Type: PC/XT',0DH,0AH,'$'
   TYPE_AT db  'Type: AT',0DH,0AH,'$'
   TYPE_PS2_MODEL_30 db 'Type: PS2 модель 30',0DH,0AH,'$'
   TYPE_PS2_MODEL_50_60 db 'Type: PS2 модель 50 или 60',0DH,0AH,'$'
   TYPE_PS2_MODEL_80 db 'Type: PS2 модель 80',0DH,0AH,'$'
   TYPE_PС_JR db 'Type: PСjr',0DH,0AH,'$'
   TYPE_PC_CONV db 'Type: PC Convertible',0DH,0AH,'$'

   VERSIONS db 'Version MS-DOS:  .  ',0DH,0AH,'$'
   SERIAL_NUMBER db  'Serial number OEM:  ',0DH,0AH,'$'
   USER_NUMBER db  'User serial number:       H $'
   ERROR db 'Error ', 0dh,0ah,'$'
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack

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

WSTRING PROC near
   mov AH,09h
   int 21h
   ret
WSTRING ENDP

PC_TYPE PROC near
   mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]

    cmp al, 0ffh
    jne pc_xt1
		mov dx, offset TYPE_PC
		jmp wtype
pc_xt1:
    cmp al, 0feh
    jne pc_xt2
		mov dx, offset TYPE_PC_XT
		jmp wtype
pc_xt2:
    cmp al, 0fbh
    jne pc_at
    mov dx, offset TYPE_PC_XT
    jmp wtype
pc_at:
    cmp al, 0fch
    jne pc_ps2_model_30
		mov dx, offset TYPE_AT
		jmp wtype
pc_ps2_model_30:
    cmp al, 0fah
    jne pc_ps2_model_50_60
		mov dx, offset TYPE_PS2_MODEL_30
		jmp wtype
pc_ps2_model_50_60:
    cmp al, 0fch
    jne pc_ps2_model_80
		mov dx, offset TYPE_PS2_MODEL_50_60
		jmp wtype
pc_ps2_model_80:
    cmp al, 0f8h
    jne pc_jr
		mov dx, offset TYPE_PS2_MODEL_80
		jmp wtype
pc_jr:
    cmp al, 0fdh
    jne pc_conv
		mov dx, offset TYPE_PС_JR
		jmp wtype
pc_conv:
    cmp al, 0fdh
    jne Err
		mov dx, offset TYPE_PC_CONV
		jmp wtype
Err:
    mov dx, offset ERROR
    jmp wtype

wtype:
		call WSTRING
	ret
PC_TYPE ENDP

OS_VER PROC near
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
	call WSTRING


	mov si, offset SERIAL_NUMBER
	add si, 19
	mov al, bh
	call BYTE_TO_DEC

	mov dx, offset SERIAL_NUMBER
	call WSTRING

	mov di, offset USER_NUMBER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX

	mov al, bl
	call BYTE_TO_HEX

	sub di, 2
	mov [di], ax
	mov dx, offset USER_NUMBER
	call WSTRING
	ret
OS_VER ENDP

Main PROC FAR
   sub   AX,AX
   push  AX
   mov   AX,DATA
   mov   DS,AX
   call PC_TYPE
   call OS_VER
   xor AL,AL
   mov AH,4Ch
   int 21H
  
Main ENDP
CODE ENDS
      END Main
