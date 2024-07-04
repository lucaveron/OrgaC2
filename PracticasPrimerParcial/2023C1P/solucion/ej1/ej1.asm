
TEMPLO_SIZE: equ 24
TEMPLO_OFFSET_COLUMN_CORTO: equ 16
TEMPLO_OFFSET_COLUMN_LARGO: equ 0
TEMPLO_OFFSET_NOMBRE: equ 8

global templosClasicos
global cuantosTemplosClasicos

extern malloc



;########### SECCION DE TEXTO (PROGRAMA)
section .text
;templo* templosClasicos_c(templo *temploArr, size_t temploArr_len){
;rdi = temploArr
;rsi = temploArrLen

; NO VOLATILES RBX, RBP, R12, R13, R14 y R15
;RDI, RSI, RDX, RCX, R8, R9
templosClasicos:
    push rbp
    mov rbp,rsp
    push r12
    push r13

    mov r12, rdi ; en r12 tengo el arreglo
    mov r13, rsi ; en r13 tengo la cantidad

    call cuantosTemplosClasicos
    mov r8,rax ; en r8 tendré la cantidad de templos Clasicos

    mov rax, TEMPLO_SIZE
    mul r8 ; aca tendre RAX =rax * r8 = 24 * cantidad de templos casicos

    call malloc ; rax tendre el puntero al arreglo y vamos a dejarlo en rax

    xor r8,r8 ; offset
    xor r9, r9
    xor rdx, rdx
    xor rcx, rcx

    .ciclo:
        cmp r13,0
        je .end

        xor r10,r10
        xor r11,r11

        mov r10b, byte [r12 + r8 + TEMPLO_OFFSET_COLUMN_CORTO] ; me traigo el templo actual 
        ;en r10 tengo column_corto

        mov r11b, byte [r12 + r8 + TEMPLO_OFFSET_COLUMN_LARGO]
        ;en r11 tengo column corto

        shl r10, 1; multiplico por 2 column corto
        add r10, 1 ; le sumo 1

        cmp r10, r11 ; comparo si 2n + 1 = m
        jne .siguiente

        ; si son iguales lo agrego al arreglo
        ;copio parte por pate ya que no me enctra todo en un registor de 8 bytes
        mov r11b, byte [r12 + r8 + TEMPLO_OFFSET_COLUMN_LARGO]
        mov [rax + rcx + TEMPLO_OFFSET_COLUMN_LARGO], r11b ; lo copio a memoria

        mov r10b, byte [r12 + r8 + TEMPLO_OFFSET_COLUMN_CORTO] ; me traigo el templo actual 
        mov [rax + rcx + TEMPLO_OFFSET_COLUMN_CORTO], r10b

        mov r9, [r12 + r8 + TEMPLO_OFFSET_NOMBRE]
        mov[rax + rcx + TEMPLO_OFFSET_NOMBRE],r9
        add rcx, TEMPLO_SIZE ;avanzo el offset del arreglo resultado


        .siguiente:
            dec r13
            add r8, TEMPLO_SIZE
            jmp .ciclo   



    .end:
    pop r13
    pop r12
    pop rbp
    ret


;uint32_t cuantosTemplosClasicos_c(templo *temploArr, size_t temploArr_len){
cuantosTemplosClasicos:
    push rbp
    mov rbp,rsp
    push r12
    sub rsp,8

    mov r12,rsi ; en r12 tengo la cantidad

    xor r8,r8
    xor r10,r10
    xor r11,r11
    xor rax, rax

    .ciclo:
        cmp r12,0
        je .end

        xor r10,r10
        xor r11,r11

        mov r10b, byte [rdi + r8 + TEMPLO_OFFSET_COLUMN_CORTO] ; me traigo el templo actual 
        ;en r10 tengo column_corto

        mov r11b, byte [rdi + r8 + TEMPLO_OFFSET_COLUMN_LARGO]
        ;en r11 tengo column corto

        shl r10, 1; multiplico por 2 column corto
        add r10, 1 ; le sumo 1

        cmp r10, r11 ; comparo si 2n + 1 = m
        jne .siguiente

        inc rax


        .siguiente:
        dec r12
        add r8, TEMPLO_SIZE
        jmp .ciclo
        

    .end:
    add rsp, 8
    pop r12
    pop rbp
    ret


