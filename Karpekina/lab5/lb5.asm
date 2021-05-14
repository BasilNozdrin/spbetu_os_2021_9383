AStack SEGMENT  STACK
          DW 128 DUP(?)
AStack ENDS

DATA SEGMENT
	IS_L DB 0
	IS_UNL DB 0
	STR_LOAD db "Custom interrupt was loaded.$"
	STR_LOADED db "Custom interrupt is already loaded.$"
	STR_UNLOAD db "Custom interrupt was unloaded.$"
	STR_NOT_LOADED db "Custom interrupt not loaded.$"
DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack


PRINT_STR PROC NEAR
    	push ax
    	mov ah, 09h
    	int 21h
    	pop ax
	ret
PRINT_STR ENDP


INTER PROC FAR
	jmp inter_start

inter_data:
	keep_ip DW 0
	keep_cs DW 0
	keep_psp DW 0
	keep_ax DW 0
	keep_ss DW 0
	keep_sp DW 0
	inter_stack DW 128 DUP(0)
	key DB 0
	sign DW 1234h

inter_start:
	mov keep_ax, ax
	mov keep_sp, sp
	mov keep_ss, ss
	mov ax, seg inter_stack
	mov ss, ax
	mov ax, offset inter_stack
	add ax, 256
	mov sp, ax

  push ax
  push bx
  push cx
  push dx
  push si
  push es
  push ds

	mov ax, seg key
	mov ds, ax

	in al, 60h
  cmp al, 20h
  je key_d
  cmp al, 11h
  je key_w
  cmp al, 23h
  je key_h

	pushf
	call dword ptr cs:keep_ip
	jmp inend

key_d:
    	mov key, '@'
    	jmp next
key_w:
    	mov key, '%'
    	jmp next
key_h:
    	mov key, '&'

next:
    	in al, 61h
    	mov ah, al
    	or al, 80h
    	out 61h, al
    	xchg al, al
    	out 61h, al
    	mov al, 20h
    	out 20h, al

print_key:
    	mov ah, 05h
    	mov cl, key
    	mov ch, 00h
    	int 16h
    	or al, al
    	jz inend
    	mov ax, 0040h
    	mov es, ax
    	mov ax, es:[1ah]
    	mov es:[1ch], ax
    	jmp print_key

inend:
    	pop ds
    	pop es
    	pop si
    	pop dx
    	pop cx
    	pop bx
    	pop ax

	mov sp, keep_sp
	mov ax, keep_ss
	mov ss, ax
	mov ax, keep_ax
	mov al, 20h
	out 20h, al

	iret

INTER endp


iend:

CHECKL PROC NEAR
	push ax
	push bx
	push si
	mov ah, 35h
	mov al, 09h
	int 21h

	mov si, offset sign
	sub si, offset INTER
	mov ax, es:[bx + si]
	cmp ax, sign
	jne lend
	mov IS_L, 1

lend:
	pop  si
	pop  bx
	pop  ax

	ret

CHECKL ENDP


CHECKUNL PROC NEAR
    	push ax
    	push es
   	mov ax, keep_psp
   	mov es, ax
    	cmp byte ptr es:[82h], '/'
    	jne cend
    	cmp byte ptr es:[83h], 'u'
    	jne cend
    	cmp byte ptr es:[84h], 'n'
    	jne cend
    	mov IS_UNL, 1

cend:
    	pop es
   	pop ax

	ret

CHECKUNL ENDP


INTER_LOAD PROC NEAR
	push ax
	push bx
	push cx
	push dx
	push ds
	push es

 	mov ah, 35h
    	mov al, 09h
    	int 21h
   	mov keep_cs, es
    	mov keep_ip, bx
    	mov ax, seg INTER
    	mov dx, offset INTER
    	mov ds, ax
    	mov ah, 25h
    	mov al, 09h
    	int 21h

    	pop ds
    	mov dx, offset iend
    	mov cl, 4h
    	shr dx, cl
    	add dx, 10fh
    	inc dx
    	xor ax, ax
    	mov ah, 31h
    	int 21h

    	pop es
    	pop dx
    	pop cx
    	pop bx
    	pop ax

	ret
INTER_LOAD ENDP


INTER_UNLOAD PROC NEAR
   	  cli
    	push ax
    	push bx
     	push dx
    	push ds
    	push es
    	push si

    	mov ah, 35h
    	mov al, 09h
    	int 21h
    	mov si, offset keep_ip
    	sub si, offset INTER
    	mov dx, es:[bx+si]
    	mov ax, es:[bx+si+2]

    	push ds
    	mov ds, ax
    	mov ah, 25h
    	mov al, 09h
    	int 21h
    	pop ds

    	mov ax, es:[bx+si+4]
    	mov es, ax
    	push es
    	mov ax, es:[2ch]
    	mov es, ax
    	mov ah, 49h
    	int 21h
    	pop es
    	mov ah, 49h
    	int 21h

    	sti

    	pop si
    	pop es
    	pop ds
    	pop dx
    	pop bx
    	pop ax

	ret

INTER_UNLOAD ENDP


BEGIN PROC
    	push ds
    	xor ax, ax
   	  push ax

    	mov ax, data
    	mov ds, ax
    	mov keep_psp, es

    	call CHECKL
    	call CHECKUNL
    	cmp IS_UNL, 1
    	je unload
    	mov al, IS_L
    	cmp al, 1
    	jne load
    	mov dx, offset STR_LOADED
    	call PRINT_STR
    	jmp bend

load:
    	mov dx, offset STR_LOAD
    	call PRINT_STR
    	call INTER_LOAD
    	jmp  bend

unload:
    	cmp  IS_L, 1
    	jne  not_loaded
    	mov dx, offset STR_UNLOAD
    	call PRINT_STR
    	call INTER_UNLOAD
    	jmp  bend

not_loaded:
    	mov  dx, offset STR_NOT_LOADED
    	call PRINT_STR

bend:
    	xor al, al
    	mov ah, 4ch
    	int 21h

BEGIN ENDP


CODE ENDS
END BEGIN
