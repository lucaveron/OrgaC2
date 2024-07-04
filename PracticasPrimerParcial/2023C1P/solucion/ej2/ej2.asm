global miraQueCoincidencia



;########### SECCION DE TEXTO (PROGRAMA)
section .text

;  B G R A | B G R A | B G R A | B G R A | 
;  0 1 2 3 | 4 5 6 7 | 8 9 10 11 | 12 13 14 15
;  R B G A | R G B A | R G B A | R G B A |
;  2 0 1 3 | 6 4 5 7 | 10 8 9 11 |14 12 13 15
;  G R B A | G R B A | G R B A | G R B A |
;  1 2 0 3
; A R G B |A R G B |A R G B| A R G B
; 15141312 11109 8  7 6 5 4  3 2 1 0

maskShiftAderecha: db 0x02, 0x00, 0x01, 0x03, 0x06, 0x04, 0x05, 0x07, 0x0A, 0x08, 0x09, 0x0B, 0x0E, 0x0C, 0x0D, 0x0F
maskTodoB:         db 0x00, 0x00, 0x00, 0x03, 0x04, 0x04, 0x04, 0x07, 0x08, 0x08, 0x08, 0x0B, 0x0C, 0x0C, 0x0C, 0x0F
maskTodoR:         db 0x02, 0x02, 0x02, 0x03, 0x06, 0x06, 0x06 ,0x07, 0x0A, 0x0A, 0x0A, 0x0B, 0x0E, 0x0E, 0x0E, 0x0F
maskTodoG:         db 0x01, 0x01, 0x01, 0x03, 0x05, 0x05, 0x05 ,0x07, 0x09, 0x09, 0x09, 0x0B, 0x0D, 0x0D, 0x0D, 0x0F
maskTransparencias:db 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF ,0x00, 0xFF, 0xFF, 0xFF, 0x00, 0xFF, 0xFF, 0xFF, 0x00
maskPrimerComponente: db 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00
maskSegundoComponente:db 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00
maskTercerComponente: db 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00
maskCuartoComponente: db 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00

maskUltimos4255: db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF ,0xFF


shuflePrimerComponente: db  0x00, 0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00
shufleSegundoComponente: db 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00
shufleTercerComponente: db  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03 ,0x00, 0x00, 0x00 ,0x00
shufleCuartoComponente: db  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ,0x00, 0x01, 0x02, 0x03 

maskFloats: dd 0.114, 0.587, 0.299, 0 

maskTodoUno: times 16 db 0xFF
maskTodo128: times 16 db 128
maskTodo255: times 4 dd 255


;void miraQueCoincidencia( uint8_t *A, uint8_t *B, uint32_t N,uint8_t *laCoincidencia )
;RDI, RSI, RDX, RCX, R8, R9

; rdi = A
; rsi = B
; edx = N 
; rcx = laCoincidencia

; mi raQueCoincidencia[ij] = (   convertirEscalaGrises(A[ij]) si A[ij] = B[ij]
;                                255                          si no               
; 

miraQueCoincidencia:
    push rbp
    mov rbp, rsp

    xor rax,rax ;la idea es multiplicar nxn
    mov eax, edx
    mul edx ; multiplico rax * rdx = n * n

    shr rax, 2 ; divido por 4;ya que opero de a 4 pixeles

    xor r10,r10
    mov r10, rax ; en r10 tenemos la cantidad de iteraciones

    xor r8,r8 ;el offset de la imagen que traigo
    xor r9, r9

    ;genero ciclo,traigo de a 4 pixles
    ;Tener en cuenta que para convertir a escala de grises cada pixel es representado por un unico byte
    ; que se obtiene a partir de operar sobre el pixel de la imagen a color de la siguiente manera: 
    ; 0.299 * Rojo (R) + 0.587 * Verde (G) + 0.114 * Azul (B). Notar que el byte de la transparencia (A) será
    ; ignorado.


    .ciclo:
        cmp r10,0
        je .end

        movdqu xmm1, [rdi + r8] ; A
        movdqu xmm2, [rsi + r8] ; B

        ; VEO SI SON IGUALES
        movdqu xmm3, xmm1 ; me guardo xmm1

        pcmpeqd xmm3,xmm2 ;me quedara en xmm3 todos aquellos 1s donde a y b sean iguales

        pxor xmm3, [maskTodoUno] ; niego la mascara asi me quedo con los distintos ya que si a != b = 255

        movdqu xmm4, [maskTodo255] ; muevo 4 veces  255 a xmm4
        pand xmm4, xmm3; tendre todos 255 en los doubles donde los pixeles hayan sido iguales

        packusdw xmm4, xmm4
        packuswb xmm4, xmm4 ; me quedaran en los 4 bytes mas bajo 255 donde eran iguales ejemplo | 0 0 0 0 | 0 0 0 0| 0 0 0 0| 255 0 255 0
        psrldq xmm4, 12 ; me quedo solo con los primeros 4

        .pixelesIguales:
        pxor xmm3,[maskTodoUno] ; recupero la mascara

        .primerpixel:
        ;,debo dejar el primer byte con el resultado de las operaciones del pixel
        movdqu xmm0, xmm1
        pmovzxbd xmm0,xmm0 ;muevo las cuatro componentes del primer pixel a double words
        cvtdq2ps xmm0,xmm0 ; las convierto en double

        mulps xmm0, [maskFloats] ;las multiplico por lo que tengo que multiplicar

        haddps xmm0, xmm0 ; 
        haddps xmm0, xmm0 ; hago las dos sumas horizontales entonces el resultado me va a quedar en los primeros 4 bytes, es decir 4 doublewords con el resultado
        cvttps2dq xmm0, xmm0 ; los paso a integer asi puedo hacer la suma horizontal
        ;tengo el resultado del primer pixel en todo un xmm0
        packusdw xmm0, xmm0 ; ahora tengo en | A | A | A | A | res0 | res0 | res0 | res0
        packuswb xmm0, xmm0 ; ahora tengo ya en los 4 bytes mas bajo el pixel entero,es hora de pasarlo al resultado ya que lo tengo en bytes
        pand xmm0, [maskPrimerComponente] ; solo dejo el resultado en la primer componente
        pxor xmm15,xmm15
        paddb xmm15, xmm0

        .segundoPixel:
        ;,debo dejar el primer byte con el resultado de las operaciones del pixel
        movdqu xmm0, xmm1
        psrldq xmm0, 4 ; me quedo con la segunda componente en los primeros 4 bytes
        pmovzxbd xmm0,xmm0 ;muevo las cuatro componentes del primer pixel a double words
        cvtdq2ps xmm0,xmm0 ; las convierto en double

        mulps xmm0, [maskFloats] ;las multiplico por lo que tengo que multiplicar

        haddps xmm0, xmm0 ; 
        haddps xmm0, xmm0 ; hago las dos sumas horizontales entonces el resultado me va a quedar en los primeros 4 bytes, es decir 4 doublewords con el resultado
        cvttps2dq xmm0, xmm0 ; los paso a integer asi puedo hacer la suma horizontal
        ;tengo el resultado del primer pixel en todo un xmm0
        packusdw xmm0, xmm0 ; ahora tengo en | A | A | A | A | res0 | res0 | res0 | res0
        packuswb xmm0, xmm0 ; ahora tengo ya en los 4 bytes mas bajo el pixel entero,es hora de pasarlo al resultado ya que lo tengo en bytes
        pand xmm0, [maskSegundoComponente] ; solo dejo el resultado en la segunda componente
        paddb xmm15, xmm0

        .tercerPixel:
        ;,debo dejar el primer byte con el resultado de las operaciones del pixel
        movdqu xmm0, xmm1
        psrldq xmm0, 8 ; me quedo con la tercer componente en los primeros 4 bytes
        pmovzxbd xmm0,xmm0 ;muevo las cuatro componentes del primer pixel a double words
        cvtdq2ps xmm0,xmm0 ; las convierto en double

        mulps xmm0, [maskFloats] ;las multiplico por lo que tengo que multiplicar

        haddps xmm0, xmm0 ; 
        haddps xmm0, xmm0 ; hago las dos sumas horizontales entonces el resultado me va a quedar en los primeros 4 bytes, es decir 4 doublewords con el resultado
        cvttps2dq xmm0, xmm0 ; los paso a integer asi puedo hacer la suma horizontal
        ;tengo el resultado del primer pixel en todo un xmm0
        packusdw xmm0, xmm0 ; ahora tengo en | A | A | A | A | res0 | res0 | res0 | res0
        packuswb xmm0, xmm0 ; ahora tengo ya en los 4 bytes mas bajo el pixel entero,es hora de pasarlo al resultado ya que lo tengo en bytes
        pand xmm0, [maskTercerComponente] ; solo dejo el resultado en la segunda componente
        paddb xmm15, xmm0

        .cuarto:
        ;,debo dejar el primer byte con el resultado de las operaciones del pixel
        movdqu xmm0, xmm1
        psrldq xmm0, 12 ; me quedo con la cuarta componente en los primeros 4 bytes
        pmovzxbd xmm0,xmm0 ;muevo las cuatro componentes del primer pixel a double words
        cvtdq2ps xmm0,xmm0 ; las convierto en double

        mulps xmm0, [maskFloats] ;las multiplico por lo que tengo que multiplicar

        haddps xmm0, xmm0 ; 
        haddps xmm0, xmm0 ; hago las dos sumas horizontales entonces el resultado me va a quedar en los primeros 4 bytes, es decir 4 doublewords con el resultado
        cvttps2dq xmm0, xmm0 ; los paso a integer asi puedo hacer la suma horizontal
        ;tengo el resultado del primer pixel en todo un xmm0
        packusdw xmm0, xmm0 ; ahora tengo en | A | A | A | A | res0 | res0 | res0 | res0
        packuswb xmm0, xmm0 ; ahora tengo ya en los 4 bytes mas bajo el pixel entero,es hora de pasarlo al resultado ya que lo tengo en bytes
        pand xmm0, [maskCuartoComponente] ; solo dejo el resultado en la segunda componente
        paddb xmm15, xmm0

        ;en xmm15 tengo en los ultimos 4 bytes los resultados de los calculos,ahora debo dejar pasar solo aquellos que no estan en 255 arriba EN XMM4

        movdqu xmm9,xmm4 ; en xmm4 estan en 255 los primeros 4 donde eran distintos
        pand xmm9, [maskUltimos4255] ; entonces ahora solo pasaron aquellos que eran 255 en los primeros 4 bytes,
        pxor xmm9, [maskTodoUno] ; ahora va a quedar en 1 los bytes que tengo que pasar

        pand xmm15, xmm9 ; aca pasaron solo los resultados de los bytes en los que a = b

        por xmm4, xmm15

        .siguiente:
        movd [rcx + r9], xmm4
        add r8, 16 ; 16 bytes porque estoy trayendo de a 4 pixeles
        add r9, 4
        dec r10
        jmp .ciclo

    .end:
    pop rbp
    ret

