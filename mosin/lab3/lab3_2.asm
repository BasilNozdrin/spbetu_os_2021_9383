testpc	segment
	assume cs:testpc,ds:testpc,es:nothing,ss:nothing
	org 100h
start:
	jmp begin_ptr

avilable_memory db 'avilable_memory:        bytes',0dh,0ah,'$'
extended_memory db 'extended_memory:        Kbytes',0dh,0ah,'$'
table db 'table:',0dh,0ah,'$'
table_data db '                                                                    ',0dh,0ah,'$'

tetr_to_hex proc near
	and al,0fh
	cmp al,09
	jbe next
	add al,07
next:
	add al,30h
	ret
tetr_to_hex endp

byte_to_hex proc near
	push cx
	mov ah,al
	call tetr_to_hex
	xchg al,ah
	mov cl,4
	shr al,cl
	call tetr_to_hex
	pop cx
	ret
byte_to_hex endp

wrd_to_hex proc near
	push bx
	mov bh,ah
	call byte_to_hex
	mov [di],ah
	dec di
	mov [di],ah
	dec di
	mov al,bh
	call byte_to_hex
	mov [di],ah
	dec di
	mov [di],al
	pop bx
	ret
wrd_to_hex endp

byte_to_dec proc near
	push cx
	push dx
	xor ah,ah
	xor dx,dx
	mov cx,10
loop_bd:
	div cx
	or dl,30h
	mov [si],dl
	dec si
	xor dx,dx
	cmp ax,10
	jae loop_bd
	cmp al,00h
	je end_l
	or al,30h
	mov [si],al
end_l:
	pop dx
	pop cx
	ret
byte_to_dec endp

wrd_to_byte proc near
	mov bx,10h
	mul bx
	mov bx,0ah
	xor cx,cx
	
divide:
	div bx
	push dx
	inc cx
	xor dx,dx
	cmp ax,0h
	jnz divide

print_symbol:
	pop dx
	or dl,30h
	mov [si],dl
	inc si
	loop print_symbol

	ret
wrd_to_byte endp

get_mcb_type proc near
	mov di, offset table_data
	add di, 5
	xor ah, ah
	mov al, es:[00h]
	call byte_to_hex
	mov [di], al
	inc di
	mov [di], ah
	
	ret
get_mcb_type endp

get_psp_address proc near

	mov di,offset table_data+19
	mov ax,es:[01h]
	call wrd_to_hex
	
	ret
get_psp_address endp

get_mcb_size proc near
	push bx
	mov di,offset table_data+29
	mov ax,es:[03h]
	mov si,di
	call wrd_to_byte
	
	pop bx
	ret
get_mcb_size endp

sc_sd proc near
	mov di,offset table_data+37
    mov bx,0h
	
jmp_next:
    mov dl,es:[bx + 8]
	mov [di],dl
	inc di
	inc bx
	cmp bx,8h
	jne jmp_next
	
	ret
sc_sd endp

print proc near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
print endp

begin_ptr:
	mov ah,04ah
	mov bx,0ffffh
	int 21h
	
	mov ax,bx

	mov si,offset avilable_memory+17
	call wrd_to_byte
	
	mov dx,offset avilable_memory
	call print
	
	mov al,30h
	out 70h,al
	in al,71h
	mov bl,al
	mov al,31h
	out 70h,al
	in al,71h
	
	mov si,offset extended_memory+17
	call wrd_to_byte
	
	mov dx,offset extended_memory
	call print
	
	lea ax,end_ptr
	mov bx,10h
	xor dx,dx
	div bx
	inc ax
	mov bx,ax
	mov al,0
	mov ah,4ah
	int 21h
	
	mov ah,52h
	int 21h
	mov es,es:[bx-2h]
	
	mov dx,offset table
	call print
print_mcb_data:
	call get_mcb_type
	call get_psp_address
	call get_mcb_size
	call sc_sd
	
	mov ax,es:[03h] 
    mov bl,es:[00h]
    mov dx,offset table_data
    call print
	
	mov cx,es
    add ax,cx
    inc ax
    mov es,ax
	
	cmp bl,4Dh
	je print_mcb_data

	xor al,al
	mov ah,4ch
	int 21h
end_ptr:
testpc ends
end start 