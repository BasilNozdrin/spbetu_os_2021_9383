testpc	segment
	assume cs:testpc,ds:testpc,es:nothing,ss:nothing
	org 100h
start:
	jmp begin

segment_memory db 'segment_memory:    ',0dh,0ah,'$'
segment_environment_address db 'segment_environment_address:    ',0dh,0ah,'$'
cmd_line_tail db 'cmd_line_tail:','$'
empty_cmd_line_tail db 'empty_cmd_line',0dh,0ah,'$'
caret_transfer db 0dh,0ah,'$'
environment_symbolic_view db 'environment_symbolic_view:',0dh,0ah,'$'
module_path db 'module_path:','$'

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

print proc near
	push ax
	mov ah,09h
	int 21h
	pop ax
	ret
print endp

begin:
	mov ax,ds:[02h]
	mov di,offset segment_memory+18
	call wrd_to_hex
	mov dx,offset segment_memory
	call print
	
	
	
	
	
	mov ax,ds:[02ch]
	mov di,offset segment_environment_address+31
	call wrd_to_hex
	mov dx,offset segment_environment_address
	call print
	
	
	
	

	xor di,di
	mov cl,ds:[080h]
	cmp cl,00h
	je cmd_line_is_empty
	mov dx,offset cmd_line_tail
	call print
	mov ah,02h
	
line_loop:
	mov dl,ds:[081h+di]
	int 21h
	inc di
	loop line_loop
	mov dx,offset caret_transfer
	call print
	jmp exit_1
	
cmd_line_is_empty:
	mov dx,offset empty_cmd_line_tail
	call print





exit_1:
	xor di,di
	mov dx,offset environment_symbolic_view
	call print
	mov ax,ds:[2ch]
	mov es,ax
	
environment_loop:
	mov dl,es:[di]
	cmp dl,00h
	je environment_loop_end
	mov ah,02h
	int 21h
	inc di
	jmp environment_loop
	
environment_loop_end:
	inc di
	mov dl,es:[di]
	cmp dl,00h
	je exit_2
	mov dx,offset caret_transfer
	call print
	jmp environment_loop





exit_2:
	mov dx,offset caret_transfer
	call print
	mov dx,offset module_path
	call print
	add di,3
path_loop:
	mov dl,es:[di]
	cmp dl,00h
	je exit_3
	mov ah,02h
	int 21h
	inc di
	jmp path_loop




exit_3:
	xor al,al
	mov ah,01h
	int 21h
	mov ah,4ch
	int 21h
testpc ends
end start