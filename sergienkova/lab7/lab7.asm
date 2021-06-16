ASSUME cs:CODE, ds:DATA, ss:STACK

STACK SEGMENT stack
	dw 128 dup(?)
STACK ends

DATA SEGMENT
	ovl_1 db "seg_1.ovl", 0
	ovl_2 db "seg_2.ovl", 0
	Program dw 0
	MemDTA db 43 dup(0)
	MemFlag db 0
	PosCL db 128 dup(0)
	AddrOVL dd 0
	PspKeep dw 0

	EOF db 0dh, 0ah, '$'
	Mcb_Crash_Error db 'Error: mcb crashed', 0dh, 0ah, '$'
	No_Memory_Error db 'Error: not enough memory for this function', 0dh, 0ah, '$'
	Addr_Error db 'Error: invalid memory address', 0dh, 0ah, '$'
	No_Func_Error db 'Error: unexistable function', 0dh, 0ah, '$'
	Not_Found_File_Error db 'Load error: file not found', 0dh, 0ah, '$'

	Route_Error db 'Load error: route not found', 0dh, 0ah, '$'
	Many_Files_Error db 'Error: too many files were opened', 0dh, 0ah, '$'
	No_Access_Error db 'Error: no access', 0dh, 0ah, '$'
	Not_Enough_Mem_Error db 'Error: not enough memory', 0dh, 0ah, '$'
	Env_Error db 'Error: wrong string of environment ', 0dh, 0ah, '$'
	str_all_file_error db  'Allocation memory error: file not found' , 0dh, 0ah, '$'
	str_all_route_error db  'Allocation memory error: route not found' , 0dh, 0ah, '$'

	Inf_Free_Memory db 'Memory was freed successfully!' , 0dh, 0ah, '$'
	Inf_Loaded db  'Loaded successfully!', 0dh, 0ah, '$'
	Inf_Allocated_Success db  'Allocation of memory was successfully!', 0dh, 0ah, '$'
	Data_End db 0
DATA ends

CODE segment

PRINT proc
 	push ax
 	mov ah, 09h
 	int 21h
 	pop ax
 	ret
PRINT endp

FREE_MEM proc
	push ax
	push bx
	push cx
	push dx

	lea ax, Data_End
	lea bx, EXIT
	add bx, ax

	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h

	jnc FreeMemoryEnd
	mov MemFlag, 1

CrashMCB:
	cmp ax, 7
	jne NoMemory
	lea dx, Mcb_Crash_Error
	call PRINT
	jmp EndFreeMemory

NoMemory:
	cmp ax, 8
	jne CheckAddress
  lea dx, No_Memory_Error
	call PRINT
	jmp EndFreeMemory

CheckAddress:
	cmp ax, 9
  lea dx, Addr_Error
	call PRINT
	jmp EndFreeMemory

FreeMemoryEnd:
	mov MemFlag, 1
  lea dx, Inf_Free_Memory
	call PRINT

EndFreeMemory:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
FREE_MEM endp

LOAD_PROC proc
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

	mov ax, data
	mov es, ax
	lea bx, AddrOVL
	lea dx, PosCL
	mov ax, 4b03h
	int 21h

	jnc LoadSuccess

WrongFunction:
	cmp ax, 1
	jne FileNotFound
	lea dx, EOF
	call PRINT
	lea dx, No_Func_Error
	call PRINT
	jmp LoadErrorExit

FileNotFound:
	cmp ax, 2
	jne RouteNotFound
	lea dx, Not_Found_File_Error
	call PRINT
	jmp LoadErrorExit

RouteNotFound:
	cmp ax, 3
	jne ManyFiles
  lea dx, EOF
	call PRINT
	lea dx, Route_Error
	call PRINT
	jmp LoadErrorExit

ManyFiles:
	cmp ax, 4
	jne NoAccess
	lea dx, Many_Files_Error
	call PRINT
	jmp LoadErrorExit

NoAccess:
	cmp ax, 5
	jne LittleMemory
	lea dx, No_Access_Error
	call PRINT
	jmp LoadErrorExit

LittleMemory:
	cmp ax, 8
	jne WrongEnv
	lea dx, Not_Enough_Mem_Error
	call PRINT
	jmp LoadErrorExit

WrongEnv:
	cmp ax, 10
	lea dx, Env_Error
	call PRINT
	jmp LoadErrorExit

LoadSuccess:
	lea dx, Inf_Loaded
	call PRINT

	mov ax, word ptr AddrOVL
	mov es, ax
	mov word ptr AddrOVL, 0
	mov word ptr AddrOVL + 2, ax

	call AddrOVL
	mov es, ax
	mov ah, 49h
	int 21h

LoadErrorExit:
	pop es
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret
LOAD_PROC endp

ROUTE proc
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov Program, dx

	mov ax, PspKeep
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0

FindROUTE:
	inc bx
	cmp byte ptr es:[bx - 1], 0
	jne FindROUTE

	cmp byte ptr es:[bx + 1], 0
	jne FindROUTE

	add bx, 2
	mov di, 0

RouteLOOP:
	mov dl, es:[bx]
	mov byte ptr [PosCL+di], dl
	inc di
	inc bx
	cmp dl, 0
	je EndRouteLOOP
	cmp dl, '\'
	jne RouteLOOP
	mov cx, di
	jmp RouteLOOP

EndRouteLOOP:
	mov di, cx
	mov si, Program

EndFN:
	mov dl, byte ptr [si]
	mov byte ptr [PosCL + di], dl
	inc di
	inc si
	cmp dl, 0
	jne EndFN

	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
ROUTE endp

ALLOCATION_MEM proc
	push ax
	push bx
	push cx
	push dx

	push dx
	lea dx, MemDTA
	mov ah, 1ah
	int 21h
	pop dx
	mov cx, 0
	mov ah, 4eh
	int 21h

	jnc AllocatedCuccess

LoadErrorFiles:
	cmp ax, 2
	je AllocateRouteError
	lea dx, str_all_file_error
	call PRINT
	jmp AllocateEnd

AllocateRouteError:
	cmp ax, 3
	lea dx, str_all_route_error
	call PRINT
	jmp AllocateEnd

AllocatedCuccess:
	push di
	mov di, offset MemDTA
	mov bx, [di + 1ah]
	mov ax, [di + 1ch]
	pop di
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	mov word ptr AddrOVL, ax
	lea dx, Inf_Allocated_Success
	call PRINT

AllocateEnd:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
ALLOCATION_MEM endp

LOAD_OVL proc
	push dx
	call ROUTE
	lea dx, PosCL
	call ALLOCATION_MEM
	call LOAD_PROC
	pop dx
	ret
LOAD_OVL endp

BEGIN proc far
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov PspKeep, es
	call FREE_MEM
	cmp MemFlag, 0
	je QUIT

	lea dx, ovl_1
	call LOAD_OVL
	lea dx, EOF
	call PRINT
	lea dx, ovl_2
	call LOAD_OVL

QUIT:
	xor al, al
	mov ah, 4ch
	int 21h

BEGIN endp

EXIT:
CODE ends
end BEGIN
