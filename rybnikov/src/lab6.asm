ASTACK segment stack
	dw 128 dup(?)
ASTACK ends

DATA SEGMENT
	param_block dw 0
					dd 0
					dd 0
					dd 0
	program db 'lab2.com', 0
	mem_flag db 0
	cmd_l db 1h, 0dh
	cl_pos db 128 dup(0)
	KEEP_SS dw 0
	KEEP_SP dw 0
	KEEP_PSP dw 0

	mcb_crash db 'Error: memory block crashed!', 0dh, 0ah, '$'
	no_mem_err db 'Erroe: there is not enough memory to execute this function!', 0dh, 0ah, '$'
	address_err db 'Error: invalid memory address!', 0dh, 0ah, '$'
	free_mem db 'Memory has been freed!' , 0dh, 0ah, '$'

	func_err db 'Error: invalid function number!', 0dh, 0ah, '$'
	file_err db 'Error: file not found!', 0dh, 0ah, '$'
	disk_err db 'Error: disk error!', 0dh, 0ah, '$'
	memory_err db 'Error: insufficient memory!', 0dh, 0ah, '$'
	envs_err db 'Error: wrong string of environment!', 0dh, 0ah, '$'
	format_err db 'Error: wrong format!', 0dh, 0ah, '$'

	good_end db 0dh, 0ah, 'Program ended with code    ' , 0dh, 0ah, '$'
	ctrl_end db 0dh, 0ah, 'Program ended by ctrl-break.' , 0dh, 0ah, '$'
	device_err db 0dh, 0ah, 'Program ended by device error.' , 0dh, 0ah, '$'
	int31_end db 0dh, 0ah, 'Program ended by int 31h.' , 0dh, 0ah, '$'

	end_data db 0
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:ASTACK

PRINT_STRING PROC near
 	push ax
 	mov ah, 09h
 	int 21h
 	pop ax
 	ret
PRINT_STRING ENDP

FREE_MEMORY PROC near
	push ax
	push bx
	push cx
	push dx

	mov ax, offset end_data
	mov bx, offset exit
	add bx, ax

	mov cl, 4
	shr bx, cl
	add bx, 2Bh
	mov ah, 4Ah
	int 21h

	jnc end_f
	mov mem_flag, 1

m_mcb_crash:
	cmp ax, 7
	jne not_enought_memory
	mov dx, offset mcb_crash
	call PRINT_STRING
	jmp m_free_mem
not_enought_memory:
	cmp ax, 8
	jne addr
	mov dx, offset no_mem_err
	call PRINT_STRING
	jmp m_free_mem
addr:
	cmp ax, 9
	mov dx, offset address_err
	call PRINT_STRING
	jmp m_free_mem
end_f:
	mov mem_flag, 1
	mov dx, offset free_mem
	call PRINT_STRING

m_free_mem:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEMORY ENDP

LOAD PROC near
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	mov KEEP_SP, sp
	mov KEEP_SS, ss

	mov ax, DATA
	mov es, ax
	mov bx, offset param_block
	mov dx, offset cmd_l
	mov [bx+2], dx
	mov [bx+4], ds
	mov dx, offset cl_pos

	mov ax, 4B00h
	int 21h

	mov ss, KEEP_SS
	mov sp, KEEP_SP
	pop es
	pop ds

	jnc loads

m_func_err:
	cmp ax, 1
	jne m_file_err
	mov dx, offset func_err
	call PRINT_STRING
	jmp load_end
m_file_err:
	cmp ax, 2
	jne m_disk_err
	mov dx, offset file_err
	call PRINT_STRING
	jmp load_end
m_disk_err:
	cmp ax, 5
	jne mem_err
	mov dx, offset disk_err
	call PRINT_STRING
	jmp load_end
mem_err:
	cmp ax, 8
	jne m_envs_err
	mov dx, offset memory_err
	call PRINT_STRING
	jmp load_end

m_envs_err:
	cmp ax, 10
	jne m_format_err
	mov dx, offset envs_err
	call PRINT_STRING
	jmp load_end

m_format_err:
	cmp ax, 11
	mov dx, offset format_err
	call PRINT_STRING
	jmp load_end

loads:
	mov ah, 4Dh
	mov al, 00h
	int 21h

_nend:
	cmp ah, 0
	jne ctrlc
	push di
	mov di, offset good_end
	mov [di+26], al
	pop si
	mov dx, offset good_end
	call PRINT_STRING
	jmp load_end
ctrlc:
	cmp ah, 1
	jne device
	mov dx, offset ctrl_end
	call PRINT_STRING
	jmp load_end
device:
	cmp ah, 2
	jne int_31h
	mov dx, offset device_err
	call PRINT_STRING
	jmp load_end
int_31h:
	cmp ah, 3
	mov dx, offset int31_end
	call PRINT_STRING

load_end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD ENDP

PATH PROC near
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov ax, keep_psp
	mov es, ax
	mov es, es:[2Ch]
	mov bx, 0

findz:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne findz

	cmp byte ptr es:[bx+1], 0
	jne findz

	add bx, 2
	mov di, 0

_loop:
	mov dl, es:[bx]
	mov byte ptr [cl_pos+di], dl
	inc di
	inc bx
	cmp dl, 0
	je _end_loop
	cmp dl, '\'
	jne _loop
	mov cx, di
	jmp _loop
_end_loop:
	mov di, cx
	mov si, 0

_fn:
	mov dl, byte ptr [program+si]
	mov byte ptr [cl_pos+di], dl
	inc di
	inc si
	cmp dl, 0
	jne _fn

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
PATH ENDP

Begin PROC FAR
	push ds
	xor ax, ax
	push ax
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es
	call free_memory
	cmp mem_flag, 0
	je _end
	call PATH
	call LOAD
_end:
	xor al, al
	mov ah, 4Ch
	int 21h

Begin ENDP

exit:
CODE ENDS
	END Begin
