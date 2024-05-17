
;  B G R A | B G R A | B G R A | B G R A | 
;  0 1 2 3 | 4 5 6 7 | 8 9 10 11 | 12 13 14 15
;  R B G A | R G B A | R G B A | R G B A |
;  2 0 1 3 | 6 4 5 7 | 10 8 9 11 |14 12 13 15
;  G R B A | G R B A | G R B A | G R B A |
;  1 2 0 3
;                       B     G    R      A    B      G     R    A     B     G     R     A     B     G     R     A

maskShiftAderecha: db 0x02, 0x00, 0x01, 0x03, 0x06, 0x04, 0x05, 0x07, 0x0A, 0x08, 0x09, 0x0B, 0x0E, 0x0C, 0x0D, 0x0F
maskTodoB:         db 0x00, 0x00, 0x00, 0x03, 0x04, 0x04, 0x04, 0x07, 0x08, 0x08, 0x08, 0x0B, 0x0C, 0x0C, 0x0C, 0x0F
maskTodoR:         db 0x02, 0x02, 0x02, 0x03, 0x06, 0x06, 0x06 ,0x07, 0x0A, 0x0A, 0x0A, 0x0B, 0x0E, 0x0E, 0x0E, 0x0F
maskTodoG:         db 0x01, 0x01, 0x01, 0x03, 0x05, 0x05, 0x05 ,0x07, 0x09, 0x09, 0x09, 0x0B, 0x0D, 0x0D, 0x0D, 0x0F
maskTransparencias:db 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF ,0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x00

maskTodoUno: times 16 db 0xFF
maskTodo128: times 16 db 128


; si b es mayor, se shiftea 1 para derecha
; si r es mayor, se shiftea 2 para derecha


global mezclarColores



;########### SECCION DE TEXTO (PROGRAMA)
section .text


; Y[ij]R = X[ij]B,
; Y [ij]G = X[ij]R,
; Y [ij]B = X[ij]G si         X[ij]R > X[ij]G > X[ij]B

; Y[ij]R = X[ij]G, 
; Y [ij]G = X[ij]B, 
; Y [ij]B = X[ij]R          si X[ij]R < X[ij]G < X[ij]B


; Y[ij] = X[ij] sino

;void mezclarColores( uint8_t *X, uint8_t *Y, uint32_t width, uint32_t height);
;rdi = puntero a x
;rsi = puntero a y
;rdx = width en pixeles
;rcx = height en pixeles




mezclarColores:
    push rbp
    mov rbp, rsp
    push r12

    mov rax, rdx 
    mul rcx
    ;en rax tengo ancho * alto
    mov r12, rax

    shr r12, 2 ;divido por 4 ya que traigo de a 4 pixeles

    movdqu xmm10 , [maskShiftAderecha]
    movdqu xmm11 , [maskTodoB]
    movdqu xmm12 , [maskTodoR]
    movdqu xmm13 , [maskTodoG]

    ;necesito un registro de contador, r12
    ;en xmm5 tendre el resultado

    xor rax, rax

    .ciclo:
        pxor xmm5, xmm5
        cmp r12, 0
        je .end

        movdqu xmm1, [rdi + rax] ; me traigo primeros cuatro pixeles
        movdqu xmm2, [rdi + rax]
        movdqu xmm3, [rdi + rax]
        movdqu xmm8, [rdi + rax]
        

        pshufb xmm2, xmm10 ; aca tengo shifteado una vez

        movdqu xmm3, xmm2
        pshufb xmm3, xmm10 ; aca tengo shifteado dos veces

        ;una vez que los tengo ahora tengo que empezar a jugar con cual comnponente es el maximo

        .primerCaso:    
        ;CASO R MAYOR A G, Y G MAYOR A B

        paddb xmm8, [maskTodo128] ; le saco los signos
        pshufb xmm8, [maskTodoR] ; en xmm8 tengo solo las componentes r
        movdqu xmm6, xmm1
        paddb xmm6, [maskTodo128]; le saco los signos
        pshufb xmm6, [maskTodoG]

        pcmpgtb xmm8, xmm6 ; en xmm8 voy a tener todos 1s donde R sea mayor a G

        movdqu xmm7, xmm1
        paddb xmm7, [maskTodo128]
        pshufb xmm7, [maskTodoB]

        pcmpgtb xmm6, xmm7 ; en xmm6 voy a tener 1s donde G sea mayor a B

        ;combino ambas mascaras con un and

        pand xmm8, xmm6 ; en xmm8 voy a tener mascara final de r > g  > b

        movdqu xmm14, xmm3 ; en xmm2 esta B G R A => G R B A

        pand xmm14, xmm8
        paddd xmm5, xmm14

        .segundoCaso:
        ;CASO B MAYOR A G, Y G MAYOR A R

        movdqu xmm9 , xmm1
        paddb xmm9, [maskTodo128]
        pshufb xmm9, [maskTodoB] ; en xmm8 tengo solo las componentes B
        movdqu xmm6, xmm1
        paddb xmm6, [maskTodo128]
        pshufb xmm6, [maskTodoG]

        pcmpgtb xmm9, xmm6 ; en xmm9 voy a tener todos 1s donde B sea mayor a G

        movdqu xmm7, xmm1
        paddb xmm7, [maskTodo128]
        pshufb xmm7, [maskTodoR] ; en xmm7 tengo las componentes R

        pcmpgtb xmm6, xmm7 ; en xmm6 voy a tener 1s donde G sea mayor a R

        ;combino ambas mascaras con un and

        pand xmm9, xmm6 ; en xmm9 voy a tener mascara final de b > g  > r

        movdqu xmm14, xmm2 ; en xmm2 esta B G R A => R B G A

        pand xmm14, xmm9
        paddd xmm5, xmm14

        .tercerCaso:
        ;este caso deja todo como esta,es decir tengo xmm8 el original todavia, es caso en que no es ni R ni B el mayor
        
        ;en xmm8 tengo mascara caso 1 y en xmm9 mascara caso 2

        pxor xmm8, [maskTodoUno]
        pxor xmm9, [maskTodoUno]

        pand xmm1, xmm8
        pand xmm1, xmm9
        ; pandn xmm8,xmm1 ; tengo mascara con xmm8 negado, y guarda en xmm8
        ; pandn xmm9, xmm8

        paddd xmm5, xmm1
        
        pand xmm5, [maskTransparencias]

        movdqu [rsi + rax], xmm5

        .siguiente:
        add rax, 16 ; 4 pixeles
        dec r12
        jmp .ciclo


    .end:
    pop r12
    pop rbp
    ret


; mezclarColores:
;     push rbp
;     mov rbp, rsp
;     push r12

;     mov rax, rdx 
;     mul rcx
;     ;en rax tengo ancho * alto
;     mov r12, rax

;     shr r12, 2 ;divido por 4 ya que traigo de a 4 pixeles

;     movdqu xmm10 , [maskShiftAderecha]
;     movdqu xmm11 , [maskTodoB]
;     movdqu xmm12 , [maskTodoR]
;     movdqu xmm13 , [maskTodoG]

;     ;necesito un registro de contador, r12
;     ;en xmm5 tendre el resultado

;     xor rax, rax

;     .ciclo:
;         pxor xmm5, xmm5
;         cmp r12, 0
;         je .end

;         movdqu xmm1, [rdi + rax] ; me traigo primeros cuatro pixeles
;         movdqu xmm2, [rdi + rax]
;         movdqu xmm3, [rdi + rax]
;         movdqu xmm8, [rdi + rax]
        

;         pshufb xmm2, xmm10 ; aca tengo shifteado una vez

;         movdqu xmm3, xmm2
;         pshufb xmm3, xmm10 ; aca tengo shifteado dos veces

;         ;una vez que los tengo ahora tengo que empezar a jugar con cual comnponente es el maximo


;         pmaxub xmm1, xmm2
;         pmaxub xmm1, xmm3 ; en xmm1 me quedaron los máximos en todas las componentes
;         ;en xmm1 tengo todos los máximos
;         movdqu xmm4, xmm1 ; lo muevo aca asi no pierdo los maximos

;         .primerCaso:
;         ;CASO R MAYOR A G, Y G MAYOR A B

;         movdqu xmm15,xmm8
;         pshufb xmm15, xmm12
;         pcmpeqb xmm4, xmm15 ; es decir comparo si son todos R los maximos(obviando transparencias),entonces ahora voy a tener unos donde se cumplió

;         ;ahora tengo que ver si g es mayor a r
;         ;en xmm2 tengo R G B A , Y EN XMM1 TENGO B G R A
;         movdqu xmm15, xmm8
;         pshufb xmm15, xmm13 ;ahora xmm15 es todo R
;         movdqu xmm6, xmm8 ; en xmm2 tengo el resultado del primer if

;         ;en xmm4 me quedo una mascara con 1s donde r es el mas grande,ahora puedo tener aca el primer resutlado

;         movdqu xmm6, xmm3 ; en xmm3 tengto el resultado del primer if es decir tengo B = G, G = R, R = B ,A=A
;         pand xmm6, xmm4 ; le aplique la mascara,solo pasaron aquellos en los que R era el mayor 
;         paddd xmm5, xmm6 ; en xmm5 tengo el resultado parcial

;         .segundoCaso:
;         ;CASO B MAYOR A G, Y G MAYOR A R
;         movdqu xmm7,xmm1 ; recuperamos los maximos

;         movdqu xmm15,xmm8
;         pshufb xmm15, xmm11
;         pcmpeqb xmm7, xmm15 ; me quedan 1s en xmm7 los pixeles donde B era el componente mayor

;         movdqu xmm6, xmm2  ; ; en xmm2 tengto el resultado del primer if es decir tengo B G R A => R B G A
;         pand xmm6, xmm7 ; le aplique la mascara,solo pasaron aquellos en los que B era el mayor
;         paddd xmm5, xmm6 ; se supone que en xmm5 había 0s donde pasaron los otros

;         .tercerCaso:
;         ;este caso deja todo como esta,es decir tengo xmm8 el original todavia, es caso en que no es ni R ni B el mayor
        
;         pandn xmm4, xmm8 ; hago un nand con la mascara negadad en la que los mayores eran R
;         pandn xmm7, xmm4; hago un nand ocn la mascara negada de los que los mayores eran B, en xmm7 me quedaron los valores originales donde los mayhores no eran ni R ni B

;         paddd xmm5, xmm7
;         pand xmm5, [maskTransparencias]

;         movdqu [rsi + rax], xmm5

;         .siguiente:
;         add rax, 16 ; 4 pixeles
;         dec r12
;         jmp .ciclo


;     .end:
;     pop r12
;     pop rbp
;     ret
