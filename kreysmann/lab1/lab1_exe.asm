AStack SEGMENT STACK
    DW 256 DUP(?)
AStack ENDS

DATA SEGMENT
        PC db 'Type of PC : PC' , 0dh, 0ah,'$'
        PCXT db 'Type of PC : PC/XT' , 0dh, 0ah, '$'
        AT db 'Type of PC : AT', 0dh, 0ah, '$'
        PS230 db 'Type of PC : PS2 model 30', 0dh, 0ah, '$'
        PS250 db 'Type of PC : PS2 model 50 or 60', 0dh,0ah,'$'
        PS280 db 'Type of PC : PS2 model 80', 0dh,0ah,'$'
        PCjr  db 'Type of PC : PCjr',0dh,0ah,'$'
        PCCONVERTIBLE db 'Type of PC: PC Convertible' , 0dh, 0ah, '$'
        ERROR db 'Error ', 0dh,0ah,'$'
        DOS_VERSION db 'DOS version:  .  ',0dh,0ah,'$'
        OEM_SERIAL db 'OEM number:   ',0dh,0ah,'$'
        USER_SERIAL db 'User serial number:       h',0dh,0ah,'$'

DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack

TETR_TO_HEX PROC near
		and AL,0Fh
		cmp AL,09
		jbe NEXT
		add AL,07
NEXT:   add AL,30h
		ret
TETR_TO_HEX ENDP

BYTE_TO_HEX PROC near
		push CX
		mov AH,AL
		call TETR_TO_HEX
		xchg AL,AH
		mov CL,4
		shr AL,CL
		call TETR_TO_HEX ;в AL старшая цифра
		pop CX			 ;в AH младшая
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
loop_bd: div CX
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
end_l:  pop DX
		pop CX
		ret
BYTE_TO_DEC ENDP


PC_TYPE proc near
		mov ax, 0f000h
		mov es,ax
		mov di, 0fffeh
		mov ah, es:[di]

		;PC
		cmp ah, 0FFh
		jne PCXTmetka1
		mov dx, offset PC
		jmp print_type

	PCXTmetka1:
		cmp ah, 0FEh
		jne PCXTmetka2
		mov dx,offset PCXT
		jmp print_type

	PCXTmetka2:
		cmp ah,0FBh
		jne ATmetka
		mov dx, offset PCXT
		jmp print_type

	ATmetka:
		cmp ah,0FCh
		jne Model30metka
		mov dx,offset AT
		jmp print_type

	Model30metka:
		cmp ah,0FAh
		jne Model50or60metka
		mov dx, offset PS230
		jmp print_type

	Model50or60metka:
		cmp ah,0FCh
		jne Model80metka
		mov dx,offset PS250
		jmp print_type

	Model80metka:
		cmp ah,0F8h
		jne PCjrmetka
		mov dx,offset PCjr
		jmp print_type

	PCjrmetka:
		cmp ah,0FDh
		jne PCConvertiblemetka
		mov dx, offset PCConvertible
		jmp print_type

	PCConvertiblemetka:
		cmp ah,0FDh
		jne Errormetka
		mov dx, offset PCConvertible
		jmp print_type

	Errormetka:
		mov dx,offset Error
		jmp print_type

	print_type:
		mov ah,9h
		int 21h


		ret
PC_TYPE endp

OS_TYPE proc near

		mov ah,30h
		int 21h

		mov si,offset dos_version
		add si,13
		push ax
		call BYTE_TO_DEC
		
		pop ax
		add si,3
		mov al,ah
		call BYTE_TO_DEC

		mov dx,offset dos_version
		mov ah,9h
		int 21h

		mov si,offset oem_serial
		add si,14
		mov al,bh
		call BYTE_TO_DEC

		mov dx, offset oem_serial
		mov ah,9h
		int 21h

		mov di, offset user_serial
		add di,25
		mov ax,cx
		call WRD_TO_HEX
		mov al,bl
		call BYTE_TO_HEX
		mov [di-2],ax
		
		mov dx,offset user_serial
		mov ah,9h
		int 21h

		ret
OS_TYPE endp


MAIN PROC FAR
		sub ax,ax
		push ax
		mov ax,data
		mov ds,ax

		call PC_TYPE
		call OS_TYPE

		xor AL,AL
		mov AH,4Ch
		int 21H
MAIN ENDP

CODE ENDS
END MAIN