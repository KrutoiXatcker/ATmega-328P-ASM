;include start
.include "m328def.inc"
;include end
.equ	TASK_REFERENS_Start_IN_SRAM	= 0x00





.list


;ESEG SEGMENT start
.eseg
;ESEG SEGMENT end


;CSEG SEGMENT start(тут пишется програма)
.cseg
ldi r27,2

.org 0x0000
  jmp reset    ; PC = 0x0000  RESET



;======================================
; initialization START

.org 0x0034



reset: 
  clr  r1      ; set the SREG to 0
  out  SREG, r1

  ldi  r28, LOW(RAMEND)  ; init the stack pointer to point to RAMEND
  ldi  r29, HIGH(RAMEND)
  out  SPL, r28
  out  SPH, r29

  rcall  USART_Init    ; initialize the serial communications
  sei        ; enable global interrupts
  rjmp  main
; initialization STOP
;======================================






;======================================
; Initialize the USART START
;
USART_Init:
  ; these values are for 9600 Baud with a 16MHz clock
  ldi  r16, 103
  clr  r17

  ; Set baud rate
  sts  UBRR0H, r17
  sts  UBRR0L, r16

  ; Enable receiver and transmitter
  ldi  r16, (1<<RXEN0)|(1<<TXEN0)
  sts  UCSR0B, r16

  ; Set frame format: Async, no parity, 8 data bits, 1 stop bit
  ldi  r16, 0b00001110
  sts  UCSR0C, r16
  ret
; Initialize the USART STOP
;======================================





;======================================
;USART_Transmit START
;Принимает регистрой r19, и отпровляет егона выход 
USART_Transmit:
  ; wait for empty transmit buffer
  lds  r16, UCSR0A
  sbrs  r16, UDRE0
  rjmp  USART_Transmit

  ; Put data (r19) into buffer, sends the data
  sts  UDR0, r19
  ret
;USART_Transmit STOP
;======================================





;======================================
;USART_Receive START
;В r19 записывет значение из USART
USART_Receive:
  ; wait for data to be received
  lds  r16, UCSR0A
  sbrs  r16, RXC0
  rjmp  USART_Receive

  ; read the data from the buffer
  lds  r19, UDR0
  ret
;USART_Receive STOP
;======================================





;======================================
;MAIN START
main:
	ldi r20,8
	LDI r21,0
	ldi ZH, HIGH(0x01)
	ldi ZL, LOW(0x01)
	ldi r19,0x00
	st Z,r19
	ldi ZH, HIGH(0x100)
	ldi ZL, LOW(0x100)
	ldi YH, HIGH(2048)
	ldi YL, LOW(2048)
	
	
	ldi r22,1
	ldi r17,1
	ldi r18,'-'
	;rcall TASK_CREATE
	rcall USART_Receive_STR


	LDI XH,0x02
	LDI XL,0x00
	ldi r16,0x01
	rcall Meneg_TASK_START

main_Loop:
	
	rcall USART_Receive
	mov XH,r19
	rcall USART_Receive
	mov XL,r19
	
	ld r19,X
	rcall USART_Transmit

	;rcall USART_Transmit
	rjmp main_Loop
;
;main STOP
;======================================


;======================================
;аргументом функции является количество 
;r20 = count
;Z = referens
;input r17
MemBlockAlloc:
	cp r20,r17
	BRLT MemBlockAlloc_error
	;BRGT MemBlockAlloc_GO
	;BREQ MemBlockAlloc_GO
	
	cpi r17,0x00
	breq MemBlockAlloc_error
	
	;Возврат в X

	mov XH,ZH
	mov XL,ZL
	
MemBlockAlloc_GO:
	SUB r20,r17
	push r26
	push r25
	ldi r25,0x00
	ldi r26,0x00
	
MemBlockAlloc_GO_Loop:
	ST Z+,r25
	inc r26
	cpi r26,0xff
	BRNE MemBlockAlloc_GO_Loop
	ST Z+,r26 ;r26==ff
	ldi r26,0x00
	dec r17
	cpi r17,0x00
	BRNE MemBlockAlloc_GO_Loop
	
	pop r25
	pop r26
	
	mov r19,ZH
	;rcall USART_Transmit
	mov r19,ZL
	;rcall USART_Transmit
ret

MemBlockAlloc_error:
	mov r19,r20
	rcall USART_Transmit
	ldi XH,0x00
	ldi XL,0x00
ret
;======================================




;======================================
;аргументом функции является размер требуемой памяти
;input r20 количество байт
;Y = голова  
MemHeapAlloc:
	push r18
	mov r18,r20
	cpi r18,0x00
	breq MemHeapAlloc_ERROR
	
	push r16
	ldi r16,0x00
	st Y,r16
	
	mov XH,YH
	mov XL,YL
	
	cpi r18,0x00
	BRNE MemHeapAlloc_Loop
MemHeapAlloc_Loop:
	
	st -Y,r16
	dec r18
	cpi r18,0x00
	BRNE MemHeapAlloc_Loop
	pop r16
	pop r18
	
	mov r19,YH
	;rcall USART_Transmit
	mov r19,YL
	;rcall USART_Transmit
	
	;mov r19,XH
	;rcall USART_Transmit
	;mov r19,XL
	;rcall USART_Transmit
	
ret
MemHeapAlloc_ERROR:
	ldi r19,0x00
	rcall USART_Transmit
ret
;======================================




;======================================
;аргументом функции является начала блока в X
MemBlockFree:
	
	push YH
	push YL
		;сохроняем начало сектора
		mov YH,XH
		mov YL,XL
	
MemBlockFree_LOOP:
	ld r19,Y+
	
	cpi r19,0xff
	BREQ FREE_BLOCK_BETVEN
	
	cp YH,ZH
	BREQ FREE_LAST_BLOCK

	rjmp MemBlockFree_LOOP
		
MemBlockFree_end:
	pop YL
	pop YH
	
ret 

FREE_LAST_BLOCK:

	ldi r19,0x01
	rcall USART_Transmit
	mov ZH,XH
	mov ZL,XL
	;ldi r19,0x01
	;mov r19,YH
	;rcall USART_Transmit
	rjmp MemBlockFree_end

FREE_BLOCK_BETVEN:
	
	ldi r19,0x02
	rcall USART_Transmit

FREE_BLOCK_BETVEN_LOOP:
	ld r19,Y+
	st X+,r19
	
	cp YH,ZH
	BREQ FREE_BLOCK_BETVEN_END
	rjmp FREE_BLOCK_BETVEN_LOOP
	
FREE_BLOCK_BETVEN_END:

	mov ZH,XH
	mov ZL,XL
	rjmp MemBlockFree_end
;======================================





;======================================
;task counter  r21 
;input TASK N = r22
TASK_CREATE:
	
	
	cpi r22,0x01
	;BREQ 
	rcall TASK0x01_create
	
	cpi XH,0x00
	BREQ TASK_CREATE_ERROR 
	
	cpi r21,0x00
	BREQ First_Task
	
	
TASK_CREATE_START:	
	;rcall cout
	;Запись адреса задачи 
	push ZH
	push ZL
	push r18
	ldi ZH,0x00
	ldi ZL,0x00
	ld r18,Z

	mov r19,r18
	inc r19
	inc r19
	inc r19
	st Z,r19
	mov ZL,r18
	st Z+,r22
	st Z+,XH
	st Z+,XL
	ldi r19,0xff
	st Z,r19
	inc r21
	pop r18
	pop ZL
	pop ZH
	;Конец записи задачи 
	
	
ret 

First_Task:
	push ZH
	push ZL
	push r18
	ldi ZH,0x00
	ldi ZL,0x00
	ldi r18,0x01
	st Z,r18
	

	pop r18
	pop ZL
	pop ZH
	;rcall cout

	rjmp TASK_CREATE_START
	
TASK_CREATE_ERROR:
	rcall cout
ret 
;
;=====================================




;======================================
;input r17
TASK:
	cpi r17,0x01
	BREQ TASK0x01


ret 
;======================================





;======================================
;принимает адрес памяти в X
TASK0x01:
	push r17
	push ZH
	push ZL
	mov ZH,XH
	mov ZL,XL
	;Смотрим где остоновиись 
	ld r17,X
	inc r17
	st X,r17 
	
	add XL,r17
	
	ld r17,X
	
	cpi r17,0xff
	BREQ TASK0x01_end
	cpi r17,0x00
	BREQ TASK0x01_end
	
	mov r19,r17
	rcall USART_Transmit
	mov XH,ZH
	mov XL,ZL
	pop r17
	pop ZL
	pop ZH
ret 
	
TASK0x01_end:
	mov XH,ZH
	mov XL,ZL
	rcall TASK_DELETE0x01
	pop r17
	pop ZL
	pop ZH
ret 
;конец TASK0x01
;======================================





;======================================
;начало TASK0x01_create
TASK0x01_create:
	
	push YH
	push YL
	;принимает r17
	rcall MemBlockAlloc
	;возврат X
	;rcall cout 
	mov YH,XH
	mov YL,XL

	push r16
	ldi r16,0x00
	st Y+,r16;for jmp
	push r20
	;ldi r20,0x00
TASK0x01_create_LOOP:
	
	ld r16,Y
	cpi r16,0xff
	BREQ TASK0x01_create_END
	;ldi r16,'+'
	;inc r20
	st Y+,r18
	
	rjmp TASK0x01_create_LOOP

	
TASK0x01_create_END:
	pop r16
	pop r20
	pop YL
	pop YH
	;rcall cout
ret
;конец TASK0x01_create
;======================================




;======================================
;начало Meneg_TASK_START
Meneg_TASK_START:
	push ZH
	push ZL
	push XH
	push XL
	push r18

	ldi ZH,0x00
	ldi ZL,0x01
Meneg_TASK_START_LOOP:	
	ld r17,Z+
	ld XH,Z+
	ld XL,Z+
	
	push ZH
	push ZL
	rcall TASK0x01
	pop ZL
	pop ZH
	
	ld r18,Z
	cpi r18,0xff
	BREQ Meneg_TASK_START_LOOP_RESET
	
	rjmp Meneg_TASK_START_LOOP

Meneg_TASK_START_LOOP_RESET:
	ldi ZH,0x00
	ldi ZL,0x00
	ld r19,Z+
	
	cpi r19,0x01
	BREQ Meneg_TASK_END
	
	
	rjmp Meneg_TASK_START_LOOP


Meneg_TASK_END:
	
	ret
;конец Meneg_TASK_START
;======================================





;======================================
;ВЫВОД X
cout:
	mov r19,XH
	rcall USART_Transmit
	mov r19,XL
	rcall USART_Transmit
ret
;======================================



;======================================
;Принимает X как адрес 
;принимает тип задачи в r16
TASK_DELETE:
	cpi r16,0x01
	BREQ TASK_DELETE0x01
ret
;======================================




;======================================
;Принимает X как адрес задачи  
TASK_DELETE0x01:
	push r20
	push r21
	mov r20,XH
	mov r21,XL
	rcall MemBlockFree
	mov XH,r20
	mov XL,r21
	;rcall cout
	rcall FIND_TASK
	rcall Meneg_TASK_DEFROGMENTESHEN
	pop r21
	pop r20
ret
;конец TASK_DELETE0x01
;======================================





;======================================
;приниает Y начало задачи для clr
;Принимает адрес памяти задачи находит ссылку на него в диспечере задач 
;Посде удаляет его и коректирует адреса в памяти у задач 
Meneg_TASK_DEFROGMENTESHEN:
	mov YH,XH
	mov YL,XL
	;rcall USART_Transmit
	push ZH
	push ZL
	push r16
	push r19
	ldi XH,0x00
	ldi XL,0x00
	mov ZH,YH
	mov ZL,YL
	inc ZL
	inc ZL
	inc ZL
	
	push r22
	clr r22
Meneg_TASK_DEFROGMENTESHEN_LOOP:
	ld r16,Z+

	cpi r16,0xff
	BREQ Meneg_TASK_DEFROGMENTESHEN_end
	
	inc r22
	cpi r22,0x02
	BREQ Meneg_TASK_DEFROGMENTESHEN_COONTROL
Cekpoint:	
	
	st Y+,r16
	
	rjmp Meneg_TASK_DEFROGMENTESHEN_LOOP
Meneg_TASK_DEFROGMENTESHEN_end:
	st Y+,r16
	ld r16,X
	dec r16
	dec r16
	dec r16
	st X,r16
	
	pop r22
	pop r19
	pop r16
	pop ZL
	pop ZH
ret

;Меняет адрес начала памяти задачи 
Meneg_TASK_DEFROGMENTESHEN_COONTROL:
	dec r16
	clr r22
	rjmp Cekpoint


;конец Meneg_TASK_DEFROGMENTESHEN
;======================================






;======================================
;Прием строки на usart
USART_Receive_STR:
	rcall USART_Receive
	rcall chek_open_port
	
	
	cpi r19,0x02
	BRNE PORT_CLOSS
	
	
	ldi r16,1
	ldi r17,1
	ldi r18,0x00
	rcall TASK_CREATE
	
	ld r16,X+
USART_Receive_STR_LOOP:
	
	rcall USART_Receive
	
	cpi r19,0x00
	BREQ USART_Receive_STR_END
	st X+,r19
	
	rjmp USART_Receive_STR_LOOP
	
	
USART_Receive_STR_END:

	clr XL
ret
;Конец приема строки 
;======================================

;======================================
;Проверка открытости порта 
chek_open_port:

ret
;======================================




;======================================
;ВЫВОД ОШИБКИ 
PORT_CLOSS:
	ldi r19,'P'
	rcall USART_Transmit
	ldi r19,'o'
	rcall USART_Transmit
	ldi r19,'r'
	rcall USART_Transmit
	ldi r19,'t'
	rcall USART_Transmit
	ldi r19,'_'
	rcall USART_Transmit
	ldi r19,'c'
	rcall USART_Transmit
	ldi r19,'l'
	rcall USART_Transmit
	ldi r19,'s'
	rcall USART_Transmit
	ldi r19,'e'
	rcall USART_Transmit
ret
;PORT_CLOSS конец
;======================================





;======================================
;получает адрес задачи в памяти в X
FIND_TASK:

	push ZH
	push ZL
	push r16
	push r17
	ldi ZH,0x00
	ldi ZL,0x01
FIND_TASK_LOOP:
	ld r16,Z+
	cpi r16,0xff
	BREQ FIND_TASK_END_RETURN
	
	ld r16,Z+
	ld r17,Z+
	
	cp r16,XH
	BREQ FIND_TASK_END_RETURN
	
	rjmp FIND_TASK_LOOP
	
FIND_TASK_END_RETURN:

	dec ZL
	dec ZL
	dec Zl
	mov XH,ZH
	mov XL,ZL
	pop r17
	pop r16
	pop ZL
	pop ZH
ret 
;FIND_TASK конец
;======================================






;======================================
;CSEG SEGMENT end
;======================================


