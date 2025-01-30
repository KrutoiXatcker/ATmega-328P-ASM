.include "m328def.inc"
.list


.cseg


.org 0x0000
  jmp reset    ; PC = 0x0000  RESET


;======================
; initialization

.org 0x0034
reset: 
  clr  r1      
  out  SREG, r1

  ldi  r28, LOW(RAMEND)  
  ldi  r29, HIGH(RAMEND)
  out  SPL, r28
  out  SPH, r29

  rcall  USART_Init    
  sei        
  rjmp  main

;=======================
; Initialize the USART
;
USART_Init:

  ldi  r16, 103
  clr  r17

  ; Set baud rate
  sts  UBRR0H, r17
  sts  UBRR0L, r16

  ; Enable receiver and transmitter
  ldi  r16, (1<<RXEN0)|(1<<TXEN0)
  sts  UCSR0B, r16

  ldi  r16, 0b00001110
  sts  UCSR0C, r16
  ret

;=======================


USART_Transmit:
  ; wait for empty transmit buffer
  lds  r16, UCSR0A
  sbrs  r16, UDRE0
  rjmp  USART_Transmit

  ; Put data (r19) into buffer, sends the data
  sts  UDR0, r19
  ret


;======================


USART_Receive:

  lds  r16, UCSR0A
  sbrs  r16, RXC0
  rjmp  USART_Receive


  lds  r19, UDR0
  ret


;======================
main:
	ldi r22,0x03
	rcall USART_Receive
	ADD r19,r22
	rcall USART_Transmit
	rjmp  main      
