ASSUME CS:CODE, DS:DATA, SS:MY_STACK

MY_STACK SEGMENT STACK
	DW 64 DUP(?)
MY_STACK ENDS

CODE SEGMENT


INTERRUPT PROC far
	jmp STARTF

	PSP_ADD_0 DW 0
	PSP_ADD_1 DW 0
	KEEP_CS DW 0
	KEEP_IP DW 0
	KEEP_SP DW 0
	KEEP_SS DW 0
	KEEP_AX DW 0
	INT_SET DW 0FEDCh
	INT_COUNT DB 'Interrupts call count: 0000  $'
	BStack DW 64 DUP(?)

STARTF:
	mov KEEP_SP, sp
	mov KEEP_AX, ax
	mov KEEP_SS, ss
	mov sp, offset STARTF
	mov ax, seg BStack
	mov ss, ax

	push ax
	push bx
	push cx
	push dx

	mov ah, 03h ;03h читает позицию и размер курсора
	mov bh, 00h ;bh - видео страница
	int 10h ;выполнение
	push dx
	mov ah, 02h ;позиция курсора
	mov bh, 00h ;bh - видео страница
	mov dx, 0220h
	int 10h ;выполнение

	push si
	push cx
	push ds

	mov ax, SEG INT_COUNT
	mov ds, ax
	mov si, offset INT_COUNT
	add si, 1Ah
	mov ah,[si]
	inc ah
	mov [si], ah
	cmp ah, 3Ah
	jne ENDF
	mov ah, 30h
	mov [si], ah

	mov bh, [si - 1]
	inc bh
	mov [si - 1], bh
	cmp bh, 3Ah
	jne ENDF
	mov bh, 30h
	mov [si - 1], bh

	mov ch, [si - 2]
	inc ch
	mov [si - 2], ch
	cmp ch, 3Ah
	jne ENDF
	mov ch, 30h
	mov [si - 2], ch

	mov dh, [si - 3]
	inc dh
	mov [si - 3], dh
	cmp dh, 3Ah
	jne ENDF
	mov dh, 30h
	mov [si - 3],dh

ENDF:
	pop ds
	pop cx
	pop si

	push es
	push bp

	mov ax, SEG INT_COUNT
	mov es, ax
	mov ax, offset INT_COUNT
	mov bp, ax
	mov ah, 13h ;функция вывода строки по адресу ES:BP
	mov al, 00h ;не двигать курсор
	mov cx, 1Dh ;длина строки
	mov bh, 0 ;bh - видео страница
	int 10h

	pop bp
	pop es

	pop dx
	mov ah, 02h ;позиция курсора
	mov bh, 0h ;bh - видео страница
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax

	mov ss, KEEP_SS
	mov ax, KEEP_AX
	mov sp, KEEP_SP

	iret

INTERRUPT endp


MEMORY_AREA PROC
MEMORY_AREA endp


IS_SET PROC near
	push bx
	push dx
	push es

	mov ah, 35h ;функция получения вектора
	mov al, 1Ch ;номер вектора
	int 21h

	mov dx, es:[bx + 17]
	cmp dx, 0FEDCh
	je IS_INT_SET
	mov al, 00h
	jmp POPR

IS_INT_SET:
	mov al, 01h
	jmp POPR

POPR:
	pop es
	pop dx
	pop bx

	ret

IS_SET endp


IS_PROMT PROC near
	push es

	mov ax, PSP_ADD_0
	mov es, ax

	mov bx, 0082h

	mov al, es:[bx]
	inc bx
	cmp al, '/'
	jne CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'U'
	jne CMD

	mov al, es:[bx]
	inc bx
	cmp al, 'N'
	jne CMD

	mov al, 0001h
CMD:
	pop es

	ret
IS_PROMT endp


LOAD_INT PROC near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h
	mov al, 1Ch
	int 21h
	mov KEEP_IP, bx
	mov KEEP_CS, es

	push ds
    	mov dx, offset INTERRUPT
   	mov ax, seg INTERRUPT
    	mov ds, ax
    	mov ah, 25h
   	mov al, 1Ch
    	int 21h
	pop ds

	mov dx, offset INT_LOADING
	call PRINT_STR

	pop es
	pop dx
	pop bx
	pop ax

	ret
LOAD_INT endp


UNLOAD_INT PROC near
	push ax
	push bx
	push dx
	push es

	mov ah, 35h ;функция получения вектора
	mov al, 1Ch ;номер вектора
	int 21h

	cli
	push ds
	mov dx, es:[bx + 9]
	mov ax, es:[bx + 7]
	mov ds, ax
	mov ah, 25h ;установка вектора
	mov al, 1Ch ;номер вектора
	int 21h

	pop ds
	sti

	mov dx, offset INT_RECOVER
	call PRINT_STR

	push es
	mov cx, es:[bx + 3]
	mov es, cx ;сегментный адрес освобождаемого блока памяти
	mov ah, 49h ;освобождает блок памяти
	int 21h
	pop es

	mov cx, es:[bx + 5]
	mov es, cx
	int 21h

	pop es
	pop dx
	pop bx
	pop ax

	ret

UNLOAD_INT endp


PRINT_STR PROC near
	push ax
   	mov ah, 09h
   	int 21h
	pop ax
   	ret
PRINT_STR endp


MAIN PROC FAR
	mov bx, 02Ch ;сегментный адрес среды
	mov ax, [bx]
	mov PSP_ADD_1, ax
	mov PSP_ADD_0, ds
	sub ax, ax
	sub bx, bx

	mov ax, DATA
	mov ds, ax

	call IS_PROMT
	cmp al, 01h
	je UNLOAD

	call IS_SET
	cmp al, 01h
	jne INT_NOT_LOADED

	mov dx, offset INT_LOAD
	call PRINT_STR
	jmp EXITF

	mov ah, 4Ch
	int 21h

INT_NOT_LOADED:
	call LOAD_INT

	mov dx, offset MEMORY_AREA
	mov cl, 04h ;перевод в параграфы
	shr dx, cl
	add dx, 1Bh ;размер в параграфах

	mov ax, 3100h
	int 21h

UNLOAD:
	call IS_SET
	cmp al, 00h
	je INTERRUPT_NOT_SET
	call UNLOAD_INT
	jmp EXITF

INTERRUPT_NOT_SET:
	mov dx, offset INT_NOT_LOAD
	call PRINT_STR
    	jmp EXITF

EXITF:
	mov ah, 4Ch
	int 21h

MAIN endp


CODE ENDS


DATA SEGMENT
	INT_NOT_LOAD DB 'Interruption did not load.', 0dh, 0ah, '$'
	INT_RECOVER DB 'Interruption was recovered.', 0dh, 0ah, '$'
	INT_LOAD DB 'Interruption is loaded.', 0dh, 0ah, '$'
	INT_LOADING DB 'Interruption is loading.', 0dh, 0ah, '$'
DATA ENDS


END MAIN
