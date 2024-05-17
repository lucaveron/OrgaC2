
OFFSET_PAGO_MONTO: equ 0
OFFSET_PAGO_APROBADO: equ 1
OFFSET_PAGO_PAGADOR: equ 8
OFFSET_PAGO_COBRADOR: equ 16
PAGO_T_SIZE: equ 24

OFFSET_LISTA_FIRST: equ 0
OFFSET_LISTA_LAST: equ 8

OFFSET_LISTA_ELEM_DATA: equ 0
OFFSET_LISTA_ELEM_NEXT: equ 8
OFFSET_LISTA_ELEM_PREV: equ 16

OFFSET_PAGOS_SPLITTED_CANT_APROBADOS: equ 0
OFFSET_PAGOS_SPLITTED_CANT_RECHAZADOS: equ 1
OFFSET_PAGOS_SPLITTED_APROBADOS: equ 8
OFFSET_PAGOS_SPLITTED_RECHAZADOS: equ 16
PAGO_SPLITTED_SIZE: equ 24



section .text

global contar_pagos_aprobados_asm
global contar_pagos_rechazados_asm

global split_pagos_usuario_asm

extern malloc
extern free
extern strcmp


;########### SECCION DE TEXTO (PROGRAMA)

; NO VOLATILES RBX, RBP, R12, R13, R14 y R15
;RDI, RSI, RDX, RCX, R8, R9(


; uint8_t contar_pagos_aprobados_asm(list_t* pList, char* usuario);
;rdi = pList, puntero a lista de pagos
;rsi = puntero a usuario
contar_pagos_aprobados_asm:
    push rbp
    mov rbp,rsp
    push r12 ; r12 va a ser el que  tenga el puntero a usuario,ya quye es no volatil
    push r13; en r13 vy a tener pubntero a usuario, ALINEADA
    push r14 
    push r15
    ;Lo primero que hay que hacer es tener una variable contador
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15


    mov r12,[rdi] ; aqui estoy pasandole a r12, el puntero a first
    mov r13, rsi ; aqui estoy pasandole a r13, el puntero a usuario

    ;r15b sera el resultado


    .ciclo:
        cmp r12,0 ;comparo que el elem actual no sea nulo
        je .end

        mov r9, [r12] ; aqui le estoy pasando a r9 el puntero a data
        mov r10, [r9 + OFFSET_PAGO_COBRADOR] ; aqui tengo en r10 el puntero a cobrador

        mov rdi, r10 ; puntero a cobrador
        mov rsi, r13 ; puntero a usuario 

        push r9
        push r10
        call strcmp ; comparo cobrador y usuario
        pop r10
        pop r9

        cmp rax, 0
        jne .siguiente

        ;si estoy aca es porque eran iguales,debo corroborar que aprobado sea true
        
        mov r14b, [r9 + OFFSET_PAGO_APROBADO] ; ESTO ES UNO O CERO
        cmp r14b, 0
        je .siguiente

        ;si estoy aca es porque estaba aprobado
        inc r15b

        .siguiente:
        mov r12, [r12 + OFFSET_LISTA_ELEM_NEXT] ; le paso el siguiente
        jmp .ciclo

    .end:
    xor rax, rax
    mov al, r15b ; muevo el resultado a rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; uint8_t contar_pagos_rechazados_asm(list_t* pList, char* usuario);
contar_pagos_rechazados_asm:
    push rbp
    mov rbp,rsp
    push r12 ; r12 va a ser el que  tenga el puntero a usuario,ya quye es no volatil
    push r13; en r13 vy a tener pubntero a usuario, ALINEADA
    push r14 
    push r15
    ;Lo primero que hay que hacer es tener una variable contador
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15


    mov r12,[rdi] ; aqui estoy pasandole a r12, el puntero a first
    mov r13, rsi ; aqui estoy pasandole a r13, el puntero a usuario

    ;r15b sera el resultado


    .ciclo:
        cmp r12,0 ;comparo que el elem actual no sea nulo
        je .end

        mov r9, [r12] ; aqui le estoy pasando a r9 el puntero a data
        mov r10, [r9 + OFFSET_PAGO_COBRADOR] ; aqui tengo en r10 el puntero a cobrador

        mov rdi, r10 ; puntero a cobrador
        mov rsi, r13 ; puntero a usuario 

        push r9
        push r10
        call strcmp ; comparo cobrador y usuario
        pop r10
        pop r9

        cmp rax, 0 ; da 0 si son iguales
        jne .siguiente ; si son diferentes avanzo

        ;si estoy aca es porque eran iguales,debo corroborar que aprobado sea true
        
        mov r14b, [r9 + OFFSET_PAGO_APROBADO] ; ESTO ES UNO O CERO
        cmp r14b, 1
        je .siguiente

        ;si estoy aca es porque estaba rechazado
        inc r15b

        .siguiente:
        mov r12, [r12 + OFFSET_LISTA_ELEM_NEXT] ; le paso el siguiente
        jmp .ciclo

    .end:
    xor rax, rax
    mov al, r15b ; muevo el resultado a rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret

; pagoSplitted_t* split_pagos_usuario_asm(list_t* pList, char* usuario);
; rdi = pList , lista de elementos
; rsi = lista de usuarios
; NO VOLATILES RBX, RBP, R12, R13, R14 y R15

split_pagos_usuario_asm:
    push rbp
    mov rbp,rsp
    push r12
    push r13
    push r14
    push r15
    push rbx ; desalineada
    sub rsp, 8 ; alineada
 
    xor r12, r12 
    xor r13, r13
    xor r14, r14
    xor r15, r15
    xor rbx,rbx

    mov r12, rdi; me guardo en r12 la lista a elementos
    mov r13, rsi; me guardo en r13 el puntero al user

    call contar_pagos_aprobados_asm ;en rdi y rsi ya tengo los parametros
    mov r14b, al ; en r14 tengo la cantidad de pagos aprobados

    mov rdi, r12
    mov rsi, r13
    call contar_pagos_rechazados_asm
    mov r15b, al ; en r15 tengo la cantidad de pagos rechazados

    mov rdi, PAGO_SPLITTED_SIZE 
    call malloc 
    ;en rax ahora tengo el puntero a devovler,lo tengo que preservar
    mov rbx, rax ; rbx sera el puntero a devolver,es decir le puntero del struct

    mov byte [rbx + OFFSET_PAGOS_SPLITTED_CANT_APROBADOS], r14b
    mov byte [rbx + OFFSET_PAGOS_SPLITTED_CANT_RECHAZADOS], r15b
    ; ya tengo la cant aprobados y la cant rechazados,ahora toca armar los arreglos
    ; ya puedo pisar r14 y r15

    shl r14b, 3
    mov rdi, r14 ; ya que es un arreglo de puntero a pagos
    call malloc ; tengo aqui el arreglo de punteros de pagos aprobados
    mov r14,rax; en r14 tendre el puntero a punteros de pagos aprobados

    shl r15b, 3
    mov rdi, r15 ; ya que es un arreglo de puntero a pago
    call malloc
    mov r15,rax  ; en r15 tendre el puntero a punteros de pagos rechazado

    mov r12, [r12] ; entro al primer elemento de la lista

    ;rdx y rcx seran los offset de r14 y r15 respectivamente

    xor rcx,rcx ; offset de pagos aprobados
    xor rdx,rdx ; offset de pagos rechazados

    .ciclo_pagos:
        cmp r12,0
        je .end

        mov r9, [r12] ; aqui le estoy pasando a r9 el puntero a data
        mov r10, [r9 + OFFSET_PAGO_COBRADOR] ; aqui tengo en r10 el puntero a cobrador

        mov rdi, r10 ; puntero a cobrador
        mov rsi, r13 ; puntero a usuario 

        push r9
        push r10
        push rcx
        push rdx ; alineada
        call strcmp ; comparo cobrador y usuario
        pop rdx
        pop rcx
        pop r10
        pop r9

        cmp rax, 0 ; da 0 si son iguales
        jne .siguiente_pago ; si son diferentes avanzo

        ;si estoy aca es porque eran iguales,debo ver si es aprobado o no
        xor r10,r10
        mov r10b, [r9 + OFFSET_PAGO_APROBADO] ; ESTO ES UNO O CERO
        cmp r10b, 1
        jne .agregoApagosRechazados
        ; si es uno,es aprobado,debo guardar el pago en pagos_aprobados

        .agregoApagosAprobados:
            mov [r14 + rcx], r9 ; r9 tiene el puntero al pago
            add rcx,8
            jmp .siguiente_pago

        .agregoApagosRechazados:
            mov [r15 + rdx], r9
            add rdx, 8
            jmp .siguiente_pago

        .siguiente_pago:
        mov r12, [r12 + OFFSET_LISTA_ELEM_NEXT]
        jmp .ciclo_pagos
        
    .end:
    mov [rbx + OFFSET_PAGOS_SPLITTED_APROBADOS], r14
    mov [rbx + OFFSET_PAGOS_SPLITTED_RECHAZADOS], r15
    mov rax, rbx
    add rsp, 8
    pop rbx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret



