AStack    SEGMENT  STACK
           DW 64 DUP(?)
 AStack    ENDS

 DATA  SEGMENT
     SECOND_INFO db "Custom interruption is already loaded.$"
     THIRD_INFO db "Interruption is changed to custom.$"
     FIRST_INFO db "Default interruption is set and can't be unloaded.$"
     FOURTH_INFO db "Custom interruption was unloaded.$"
 DATA  ENDS

 CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack

 PRINT_BUFFER proc near
     push ax
     mov ah, 9h
     int 21h
     pop ax
     ret
 PRINT_BUFFER endp


 START:
 ROUT proc far
    jmp start1
    key_value db 0
    KEEP_PSP dw 0
    KEEP_IP dw 0
  	KEEP_CS dw 0
    KEEP_SS DW 0
 	  KEEP_SP DW 0
 	  KEEP_AX DW 0
    MY_INT DB 0
    ROUT_INDEX dw 6666h
    TIMER_COUNTER db 'Timer: 0000$'
    BStack DW 64 DUP(?)
 start1:
     mov KEEP_SP, sp
     mov KEEP_AX, ax
     mov ax,ss
     mov KEEP_SS, ss

     mov MY_INT, 0h
     mov sp, offset start1

     mov ax, seg BStack
     mov ss, ax

     mov ax, KEEP_AX


     push ax
     push bx
     push cx
     push dx
     push si
     push es
     push ds

 	   mov cx, 040h
 	   mov es, cx
 	   mov cx, es:[0017h]
     mov ax, SEG key_value
     mov ds, ax

     and cx, 0100b
     jz check
     jmp good

check:
      mov MY_INT, 1h
      jmp re_reg
good:

     in al, 60h
     cmp al, 1Eh
     je key

     mov MY_INT, 1h
     jmp re_reg



key:
      mov key_value, '&'
      jmp next


 next:
     in al, 61h
     mov ah, al
     or al, 80h
     out 61h, al
     xchg ah, al
     out 61h, al
     mov al, 20H
     out 20h, al


print_key:

    mov ah, 05h
    mov cl, key_value
    mov ch, 00h
    int 16h
    or al,al
    jz re_reg
    mov ax, 040h
    mov es, ax
    mov ax, es:[1Ah]
    mov es:[1Ch], ax
    jmp print_key


 skip:
     mov al, es:[1Ah]
     mov es:[1Ch], al
     jmp print_key

 re_reg:
     pop ds
     pop es
     pop	si
     pop dx
     pop cx
     pop bx
     pop ax


     mov sp, KEEP_SP
     mov ax, KEEP_SS
     mov ss, ax
     mov ax, KEEP_AX

     mov al, 20H
     out 20H, al

     cmp MY_INT, 1h
     jne iiret
     jmp dword ptr cs:[KEEP_IP]
iiret:
     iret
 end_rout:
 ROUT endp


 UNLOAD proc near
    	push ax
      push es

    	mov al,es:[81h+1]
    	cmp al,'/'
    	jne need_unload

    	mov al,es:[81h+2]
    	cmp al,'u'
    	jne need_unload

    	mov al,es:[81h+3]
    	cmp al,'n'
    	jne need_unload

      mov cl,1h

 need_unload:
     pop es
  	 pop ax
  	 ret
 UNLOAD endp


 LOAD PROC near
  	 push ax
  	 push dx

     mov KEEP_PSP, es

    	mov ah,35h
 	mov al,09h
 	int 21h
     mov KEEP_IP, bx
     mov KEEP_CS, es

    	push ds
    	lea dx, ROUT
    	mov ax, SEG ROUT
    	mov ds,ax
    	mov ah,25h
    	mov al,09h
    	int 21h
    	pop ds

    	lea dx, end_rout
    	mov cl,4h
    	shr dx,cl
    	inc dx
    	add dx,100h
     xor ax, ax
    	mov ah,31h
    	int 21h

    	pop dx
    	pop ax
    	ret
 LOAD ENDP

 UNLOAD_ROUT PROC near
    	push ax
    	push si

     cli
    	push ds
    	mov ah,35h
 	mov al,09h
     int 21h

     mov si,offset KEEP_IP
     sub si,offset ROUT
     mov dx,es:[bx+si]
 	mov ax,es:[bx+si+2]
     mov ds,ax
     mov ah,25h
     mov al,09h
     int 21h
     pop ds

     mov ax,es:[bx+si-2]
     mov es,ax
     push es

     mov ax,es:[2ch]
     mov es,ax
     mov ah,49h
     int 21h

     pop es
     mov ah,49h
     int 21h
     sti

     pop si
     pop ax
     ret
 UNLOAD_ROUT endp

 CHECK_LOAD proc near
    	push ax
    	push si

     push es
     push dx

    	mov ah,35h
    	mov al,09h
    	int 21h

    	mov si, offset ROUT_INDEX
    	sub si, offset ROUT
    	mov dx,es:[bx+si]
    	cmp dx, ROUT_INDEX
    	jne end_check
    	mov ch,1h

 end_check:
     pop dx
     pop es
    	pop si
    	pop ax
    	ret
 CHECK_LOAD ENDP

 MAIN proc far
     push  DS
     push  AX
     mov   AX,DATA
     mov   DS,AX

     call UNLOAD
     cmp cl, 1h
     je start_unload

     call CHECK_LOAD
     cmp ch, 1h
     je marker_1
     mov dx, offset THIRD_INFO
     call PRINT_BUFFER
     call LOAD
     jmp exit

 start_unload:
     call CHECK_LOAD
     cmp ch, 1h
     jne marker_2
     call UNLOAD_ROUT
     mov dx, offset FOURTH_INFO
     call PRINT_BUFFER
     jmp exit

 marker_2:
     mov dx, offset FIRST_INFO
     call PRINT_BUFFER
     jmp exit
 marker_1:
     mov dx, offset SECOND_INFO
     call PRINT_BUFFER
     jmp exit

 exit:
     mov ah, 4ch
     int 21h
 MAIN endp
 CODE ends
 END Main
