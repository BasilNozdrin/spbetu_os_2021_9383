testpc	segment
	assume cs:testpc,ds:testpc,es:nothing,ss:nothing
	org 100h
start:
	jmp begin

pc db 'Type - PC',0dh,0ah,'$'
pcxt db 'Type - PC/XT',0dh,0ah,'$'
pcat db 'Type - AT',0dh,0ah,'$'
ps2_30 db 'Type - PS2 model 30',0dh,0ah,'$'
ps2_50_60 db 'Type - PS2 model 50 or 60',0dh,0ah,'$'
ps2_80 db 'Type - PS2 model 80',0dh,0ah,'$'
pcjr db 'Type - PCjr',0dh,0ah,'$'
pc_convertible db 'Type - PC Convertible',0dh,0ah,'$'
version db 'Version - x.y',0dh,0ah,'$'
oem db 'OEM - ?',0dh,0ah,'$'
user db 'User - ??????',0dh,0ah,'$'

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
	mov ax,0f000h
	mov es,ax
	mov al,es:[0fffeh]
	cmp al,0ffh
	je type_pc
	cmp al,0feh
	je type_pcxt
	cmp al,0fbh
	je type_pcxt
	cmp al,0fch
	je type_at
	cmp al,0fah
	je type_ps2_30
	cmp al,0fch
	je type_ps2_50_or_60
	cmp al,0f8h
	je type_ps2_80
	cmp al,0fdh
	je type_pcjr
	cmp al,0f9h
	je type_pc_convertible
type_pc:
	mov dx,offset pc
	call print
	jmp exit
type_pcxt:
	mov dx,offset pcxt
	call print
	jmp exit
type_at:
	mov dx,offset pcat
	call print
	jmp exit
type_ps2_30:
	mov dx,offset ps2_30
	call print
	jmp exit
type_ps2_50_or_60:
	mov dx,offset ps2_50_60
	call print
	jmp exit
type_ps2_80:
	mov dx,offset ps2_80
	call print
	jmp exit
type_pcjr:
	mov dx,offset pcjr
	call print
	jmp exit
type_pc_convertible:
	mov dx,offset pc_convertible
	call print

exit:
	mov ah,30h
	int 21h
	mov si,offset version
	add si,10
	push ax
	call byte_to_dec
	pop ax
	mov al,ah
	add si,3
	call byte_to_dec
	mov dx,offset version
	call print
	
	mov si,offset oem
	add si,6
	mov al,bh
	call byte_to_dec
	mov dx,offset oem
	call print
	
	mov di,offset user
	add di,12
	call wrd_to_hex
	mov ax,cx
	mov al,bl
	call byte_to_hex
	sub di,2
	mov [di],ax
	mov dx,offset user
	call print
	
	xor al,al
	mov ah,4ch
	int 21h
testpc ends
end start