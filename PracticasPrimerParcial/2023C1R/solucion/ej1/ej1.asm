PAGO_SIZE equ 24
PAGO_MONTO_OFFSET equ 0
PAGO_COMERCIO_OFFSET equ 8
PAGO_CLIENTE_OFFSET equ 16
PAGO_APROBADO_OFFSET equ 17
CANTIDAD_CLIENTES equ 10
SIZE_INT_32 equ 4

; NO VOLATILES RBX, RBP, R12, R13, R14 y R15

global acumuladoPorCliente_asm
global en_blacklist_asm
global blacklistComercios_asm

;########### SECCION DE TEXTO (PROGRAMA)
section .text

extern calloc
extern strcmp
extern malloc

; uint32_t* acumuladoPorCliente(uint8_t cantidadDePagos, pago_t* arr_pagos){
; rdi = cantidadDePagos, rsi = *arr_pagos
acumuladoPorCliente_asm:
	push rbp ; alineada
	mov rbp, rsp 
	; primero deberia crear el array de 10 elementos,una posicion por cliente, cada elemento son 4 bytes como maximo, entonces tengo que hacer 40 bytes?

	push r12 
	push r13 

	xor r12, r12
	xor r13, r13

	mov r12b, dil ; en r12 tengo la cantidad de pagos
	mov r13, rsi ; en r12 tengo el puntero al arreglo de pagos

	mov rdi, CANTIDAD_CLIENTES
	mov rsi, SIZE_INT_32
	call calloc
	xor r10, r10
	xor r11,r11
	xor rcx, rcx


	.ciclo:
		cmp r12,0
		je .end

		mov r10b, byte [r13 + PAGO_APROBADO_OFFSET] ; le ponmgo byte porque sino traigo cosas de más
		cmp r10b, 1 ; me fijo si esta aprobado
		jne .siguiente

		;aca tengo que cargar el monto en el cliente
		mov r11b, [r13 + PAGO_CLIENTE_OFFSET] ; me traigo el NUMERO de cliente
		mov cl, [r13 + PAGO_MONTO_OFFSET] ; me traigo el monto que tambien es byte
		add dword [rax + r11 * 4], ecx ; lo muevo a memoria, esa es la posicion ya que es le numero de cliente * 4 debido a que por cada cliente tengo 4 byets
		

		.siguiente:
	    add r13, PAGO_SIZE ; me muevp en el puntero de pagos
		dec r12
		jmp .ciclo

	.end:
	pop r13
	pop r12
	pop rbp
	ret


; uint8_t en_blacklist(char* comercio, char** lista_comercios, uint8_t n){

;rdi : puntero a comercio
;rsi : puntero a lista de comercios
;rdx = dl : tamaño de la lista, parte baja de rdx
en_blacklist_asm:
    push rbp
	mov rbp, rsp

	push r12
    push r13
	push r14
	sub rsp, 8

	xor r12, r12
	xor r13, r13
	xor r14,r14

	mov r12, rdi ;r12 : puntero a comercio
	mov r13, rsi ;r13 : puntero a lista de comercios

	mov r14b, dl

	.ciclo:
		mov rdi, [r13]
		mov rsi, r12 
		call strcmp ; cmpara los strings, devuleve 0 SI SON IGUALES
		cmp rax,0
		jne .siguiente

		mov rax, 1
		jmp .fin

		.siguiente:
		add r13, 8
		dec r14b
		cmp r14b, 0
		jne .ciclo
	.fin:
	add rsp, 8
	pop r14
    pop r13
    pop r12
	pop rbp
	ret

;RDI, RSI, RDX, RCX, R8, R9(

; pago_t** blacklistComercios(uint8_t cantidad_pagos, pago_t* arr_pagos, char** arr_comercios, uint8_t size_comercios){
; rdi = cantidad pagos,pero en realidad no es rdi compalero, es dil
; rsi : arreglo de pagos
; rdx = arreglo de comercios
; rcx = cl size comercios

blacklistComercios_asm:
    push rbp
	mov rbp, rsp

	push r12
    push r13
    push r14
	push r15 ; alineada
	push rbx ; va a ser el contador de cantidad de punteros a devolver
	sub rsp, 8

	xor r12, r12
    xor r13, r13
	xor r14, r14
    xor r15, r15
	xor rbx, rbx ; contador

	mov r12b, dil ; cantidad pagos
	mov r13, rsi ; arreglo de pagos
    mov r14, rdx ; arreglo de comercios
	mov r15b, cl ; cl size comercios


	mov r8, r12 ; iterador de la cantidad de pagos
	mov r9, r13; me guardo en r9 el arreglo de pagos para ir avanzando,de offset
	.ciclo_contador:

		mov rdi, [r9 + PAGO_COMERCIO_OFFSET] ;comercio actual
		mov rsi, r14 ; lista de comercios
		mov rdx, r15 ; cantidad de comercios

		push r8
		push r9
		call en_blacklist_asm ; llamo a ver si esta el comercio en la lista de comercios 
		pop r9
		pop r8

		cmp rax, 1
		jne .siguiente

		;en este caso hay que aumentar el contador

		inc rbx

		.siguiente:
		add r9, PAGO_SIZE; ya que iteramos en el pago
		dec r8
		cmp r8, 0
		jne .ciclo_contador


	;aca ya sabemos la cantidadd de memoria a pedir

	shl rbx, 3 ; ya que es la cantidad de comercios * 8 debido a que cada uno es un puntero
	mov rdi, rbx
	call malloc ; en rax tengo el puintero al arreglo de punteros de pagos a devovler

	mov rbx, rax ; pisamos rbx ya que es no volatil para guardar el puntero al arreglo respuesta
	
	xor r10,r10 ; va a ser el indice del arrelgo de punteross

	xor r8, r8
	xor r9, r9
	mov r8, r12 ; iterador de la cantidad de pagos
	mov r9, r13; me guardo en r9 el arreglo de pagos para ir avanzando,de offset

	.ciclo_respuesta:

		mov rdi, [r9 + PAGO_COMERCIO_OFFSET] ;comercio actual
		mov rsi, r14 ; lista de comercios
		mov rdx, r15 ; cantidad de comercios

		push r8
		push r9
		push r10
		sub rsp, 8
		call en_blacklist_asm ; llamo a ver si esta el comercio en la lista de comercios 
		add rsp, 8
		pop r10
		pop r9
		pop r8

		cmp rax, 1
		jne .siguiente_pago

		;en este caso hay que crear el pago y agregarlo

		push r8
		push r9
		push r10
		sub rsp, 8

		mov rdi, PAGO_SIZE ;Hay que pedir memoria para que el puntero apunte al pago
		call malloc

		add rsp, 8
		pop r10
		pop r9
		pop r8

		xor r11, r11
		mov r11b, byte [r9 + PAGO_MONTO_OFFSET];me traigo el monto
		mov byte [rax + PAGO_MONTO_OFFSET], r11b

		mov r11, [r9 + PAGO_COMERCIO_OFFSET];me traigo el monto
		mov [rax + PAGO_COMERCIO_OFFSET], r11
		
		mov r11b, byte [r9 + PAGO_CLIENTE_OFFSET];me traigo el monto
		mov byte [rax + PAGO_CLIENTE_OFFSET], r11b

		mov r11b,byte [r9 + PAGO_APROBADO_OFFSET];me traigo el monto
		mov byte [rax + PAGO_APROBADO_OFFSET], r11b

		mov [rbx + r10], rax ; agrego el puntero
		add r10, 8


		.siguiente_pago:
		add r9, PAGO_SIZE; ya que iteramos en el pago
		dec r8
		cmp r8, 0
		jne .ciclo_respuesta	


	mov rax,rbx
	add rsp, 8
	pop rbx
	pop r15
	pop r14
    pop r13
	pop r12
	pop rbp
	ret
