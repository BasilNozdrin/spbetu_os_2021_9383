CODE      SEGMENT
          ASSUME CS:CODE, DS:DATA, SS:ASTACK

;-------------------------------

MY_INTERRUPT PROC far
   jmp start_interrupt

   KEEP_PSP dw ?
   KEEP_IP dw 0
   KEEP_CS dw 0
   INTERRUPT_ID dw 6666h


   COUNTER db 'Count: 0000$' ; 6

   KEEP_AX dw ?
	 KEEP_SS dw ?
	 KEEP_SP dw ?
	 INTERRUPT_STACK dw 32 dup (?)
	 END_IT_STACK dw ?

start_interrupt:
   mov KEEP_SS,ss
   mov KEEP_SP,sp
   mov KEEP_AX,ax

   mov ax,cs
   mov ss,ax
   mov sp,offset END_IT_STACK

   push bx
   push cx
   push dx


	 mov ah,3h
   mov bh,0h
	 int 10h
	 push dx


	 mov ah,02h
	 mov bh,0h
   mov dh,02h
   mov dl,05h
	 int 10h


   push si
	 push cx
   push ds
   push bp

	 mov ax,SEG COUNTER
	 mov ds,ax
	 mov si,offset COUNTER
	 add si,6 ; и вот тут колво чаров включая двоеточие

   mov cx,4
interrapt_loop:
   mov bp,cx
   mov ah,[si+bp]
	 inc ah
	 mov [si+bp],ah
	 cmp ah,3Ah
	 jl m_number
   mov ah,30h
   mov [si+bp],ah

   loop interrapt_loop

m_number:
   pop bp
   pop ds
   pop cx
   pop si


   push es
	 push bp

	 mov ax,SEG COUNTER
	 mov es,ax
   mov ax,offset COUNTER
	 mov bp,ax
	 mov ah,13h
	 mov al,00h
	 mov cx,11 ; и вот тут прямо до конца строчки(вкл или не вкл $)
	 mov bh,0
	 int 10h

	 pop bp
	 pop es


	 pop dx
   mov ah,02h
	 mov bh,0h
   int 10h

	 pop dx
   pop cx
   pop bx

	 mov ax, KEEP_SS
	 mov ss, ax
   mov ax, KEEP_AX
   mov sp, KEEP_SP

   iret
interrapt_end:
MY_INTERRUPT ENDP

;-------------------------------

WRITE_STRING PROC near
   push ax
   mov ah, 09h
   int 21h
   pop ax
   ret
WRITE_STRING ENDP
;-------------------------------

LOAD_UN PROC near
   push ax
   mov KEEP_PSP,es
   mov al,es:[81h+1]
   cmp al,'/'
   jne load_un_end
   mov al,es:[81h+2]
   cmp al, 'u'
   jne load_un_end
   mov al,es:[81h+3]
   cmp al, 'n'
   jne load_un_end
   mov flag,1h

load_un_end:
   pop ax
   ret
LOAD_UN ENDP

;-------------------------------

IS_LOAD PROC near
   push ax
   push si

   mov ah,35h
   mov al,1Ch
   int 21h
   mov si,offset INTERRUPT_ID
   sub si,offset MY_INTERRUPT
   mov dx,es:[bx+si]
   cmp dx, 6666h
   jne is_load_end
   mov flag_load,1h
is_load_end:
   pop si
   pop ax
   ret
IS_LOAD ENDP

;-------------------------------

LOAD_INTERRAPT PROC near
   push ax
   push dx

   call IS_LOAD
   cmp flag_load,1h
   je already_load
   jmp start_load

already_load:
   lea dx,STR_ALR_LOAD
   call WRITE_STRING
   jmp end_load

start_load:
   mov ah,35h
   mov al,1Ch
   int 21h
   mov KEEP_CS, es
	 mov KEEP_IP, bx

   push ds
   lea dx, MY_INTERRUPT
   mov ax, seg MY_INTERRUPT
   mov ds,ax
   mov ah,25h
   mov al, 1Ch
   int 21h
   pop ds
   lea dx, STR_SUC_LOAD
   call WRITE_STRING

   lea dx, interrapt_end
   mov cl, 4h
   shr dx,cl
   inc dx
   mov ax,cs
   sub ax,KEEP_PSP
   add dx,ax
   xor ax,ax
   mov ah,31h
   int 21h

end_load:
   pop dx
   pop ax
   ret
LOAD_INTERRAPT ENDP

;-------------------------------

UNLOAD_INTERRAPT PROC near
   push ax
   push si

   call IS_LOAD
   cmp flag_load,1h
   jne cant_unload
   jmp start_unload

cant_unload:
   lea dx, STR_ISNT_LOAD
   call WRITE_STRING
   jmp unload_end


start_unload:
   CLI
   push ds
   mov ah,35h
	 mov al,1Ch
	 int 21h

   mov si,offset KEEP_IP
	 sub si,offset MY_INTERRUPT
   mov dx,es:[bx+si]
   mov ax,es:[bx+si+2]
   MOV ds, ax
   MOV ah,25h
   MOV al, 1Ch
   INT 21h
   POP ds


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
   STI

   lea dx, STR_IS_UNLOAD
   call WRITE_STRING
unload_end:
   pop si
   pop ax
   ret
UNLOAD_INTERRAPT ENDP

;-------------------------------
; Головная процедура
Main      PROC  FAR
   push  ds
   xor   ax, ax
   push  ax
   mov   ax,DATA
   mov   ds, ax

   call LOAD_UN
   cmp flag, 1h
   je unload_interrapt_1
   call LOAD_INTERRAPT
   jmp end_1

unload_interrapt_1:
   call UNLOAD_INTERRAPT

end_1:
   mov ah, 4ch
   int 21h

Main      ENDP
CODE      ENDS

ASTACK    SEGMENT  STACK
   DW 64 DUP(?)
ASTACK    ENDS

DATA      SEGMENT
   flag db 0
   flag_load db 0

   STR_ISNT_LOAD  DB 'Interrapt is not load', 0AH, 0DH,'$'
   STR_ALR_LOAD  DB 'Interrapt is already loaded', 0AH, 0DH,'$'
   STR_SUC_LOAD  DB 'Interrapt has been loaded', 0AH, 0DH,'$'
   STR_IS_UNLOAD  DB 'Interrapt is unloaded', 0AH, 0DH,'$'
DATA      ENDS
          END Main
