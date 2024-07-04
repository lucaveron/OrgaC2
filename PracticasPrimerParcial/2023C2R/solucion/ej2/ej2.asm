
shuffle_redXblue: DB 0x02,0x01,0x00,0x03,0x06,0x05,0x04,0x07,0x0A,0x09,0x08,0x0B,0x0E,0x0D,0x0C,0x0F
; BGRA
mascaraResGreen: DB 0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00
mascaraResAlpha: DB 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF
mascaraResRed: DB 0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00
mascaraResBlue: DB 0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00
; mascaraTodosUnos: times 16 db 0xFF
mascaraTodosUnos: DQ 0XFFFFFFFFFFFFFFFF, 0XFFFFFFFFFFFFFFFF


mascarablend1: DB 0x00,0x80,0x00,0x00,0x00,0x80,0x00,0x00,0x00,0x80,0x00,0x00,0x00,0x80,0x00,0x00
mascarablend2: DB 0x00,0x00,0x80,0x00,0x00,0x00,0x80,0x00,0x00,0x00,0x80,0x00,0x00,0x00,0x80,0x00

mascaraTodos128: times 16 db 128



global combinarImagenes_asm

;########### SECCION DE TEXTO (PROGRAMA)
section .text


;void combinarImagenes(uint8_t *src_a, uint8_t *src_b, uint8_t *dst, uint32_t width, uint32_t height)
;RDI, RSI, RDX, RCX, R8, R9
;A = rdi
;B = rsi
;DST = rdx
;width = rcx
;r8 = height

; argb tengo que hacer las mascaras
;res [ij]b = Ab + Br ,tengo que sumar blue de a mas red de B
;res [ij]r = Bb - Ar

; A R G B |A R G B |A R G B| A R G B
; 15141312 11109 8  7 6 5 4  3 2 1 0
; EN MASCARA VA DE 0 A 15 IZQ A DER

; 15 12 13 14 11 8 9 10 7 4 5 6 3 0 1 2

combinarImagenes_asm:
    push rbp
    mov rbp, rsp
    mov r10,rdx
    ;vamos a loopear de a 4 pixeles,cada pixel tiene 4 bytes,es decir cada pixel es una dword
    ;en un xmm son 16 bytes entonces entran 4 pixeles, cada componente es un byte

    mov rax, r8
    mul rcx ; entonces en rax me quedara la cantidad total de pixeles a looear
    shr rax, 2 ; divido por 4 ya que voy a loopear de a 4
    mov r8, rax; en r8 tendre la cantidad total de iteraciones 

    xor rax, rax ; offset para moverme 16 bytes,es decir 4 pixeles
    movdqu xmm4, [shuffle_redXblue]

    movdqu xmm12, [mascaraResAlpha] ;transparencias


;   A =   B G R A
;   B =   R G B A 

; RES =   B G R A


    .ciclo:
        cmp r8 , 0
        je .end

        movdqu xmm1 , [rdi + rax] ; A 
        movdqu xmm2 , [rsi + rax] ; B

        .blue:
        movdqu xmm5 , xmm1 ; xmm5 = A
        movdqu xmm6 , xmm2 ; xmm6 = B
        pshufb xmm6, xmm4 ; ahora xmm6= B es abgr

        paddusb xmm5,xmm6 ; ahora sume a con b ,con a y b intercalados,me faltaria quedarme solo con los red de res
        movdqu xmm6, [mascaraResBlue] ; muevo la mascara para quuedarme solo con los BLUE
        pand xmm5, xmm6 ; hago el and entoences ahora tengo en xmm5 el resultado de red
        movdqu xmm3, xmm5 ; resultado en xmm5


        .red:;res [ij]r = Bb - Ar
        movdqu xmm5 , xmm1 ; xmm5 = A
        movdqu xmm6 , xmm2 ; xmm6 = B
        pshufb xmm6, xmm4 ; ahora xmm6 es abgr,es B cambiado
        psubusb xmm6, xmm5 ; ahora resto B normal con A intercambiado
        pand xmm6,[mascaraResRed] ; tengo los resultados de solo los red
        paddd xmm3,xmm6 ; sumo los resultados a xmm3,total se supone que en el rsto tengo 0s

        .green:
        movdqu xmm5 , xmm1 ; xmm5 = A
        movdqu xmm6 , xmm2 ; xmm6 = B

        pavgb xmm5,xmm6 ; en xmm5 tengo el promedio de ambos,ahora toca ver caso en que a[g] > b[g]
        movdqu xmm9, xmm5 ;paso el resultado a xmm9 del promedio
        movdqu xmm5, xmm1 ; recupero xmm5 = A

        psubusb xmm5, xmm6 ; en xmm6 rtendre b - a
        movdqu xmm10, xmm5 ; en xmm10 tendre el resultado
        movdqu xmm5, xmm1 ; recupero xmm6

        paddb xmm5, [mascaraTodos128]
        paddb xmm6, [mascaraTodos128]
        pcmpgtb xmm5,xmm6 ;si los commponentes de a son mas grandes que los de b

        pand xmm10, xmm5
        pxor xmm5, [mascaraTodosUnos]
        pand xmm9, xmm5
        por xmm9,xmm10

        pand xmm9, [mascaraResGreen]
        paddd xmm3, xmm9

        por xmm3, xmm12

        .siguiente:
        movdqu [r10 + rax], xmm3 ; muevo a memoria el resultado
        add rax, 16
        dec r8 ; decremenmto el contador
        jmp .ciclo


    .end:
    pop rbp
    ret

    ; combinarImagenes_asm:

    ; push rbp
    ; mov rbp,rsp
    ; mov r10, rdx

    ; mov rax, r8
    ; mul rcx ; entonces en rax me quedara la cantidad total de pixeles a looear
    ; shr rax, 2 ; divido por 4 ya que voy a loopear de a 4
    ; mov r8, rax; en r8 tendre la cantidad total de iteraciones 

    ; xor rax, rax ; offset para moverme 16 bytes

    ; movdqu xmm7, [mascaraResAlpha] ;transparencias
    ; movdqu xmm8, [mascaraTodos128] ; traigo los 128 para quitar signo
    ; movdqu xmm9, [shuffle_redXblue] ; aca tengo la mascara para intercambiar red por blue

    ; .ciclo:
    ; cmp r8, 0 
    ; je .end
    ;     movdqu xmm1, [rdi + rax]; xmm1 = A
    ;     movdqu xmm2, [rsi + rax]; xmm2 = B

    ;     pshufb xmm2, xmm9 ; en xmm2 tengo B PERO A B G R

    ;     .blue:
    ;     movdqu xmm3, xmm1 ; xmm3 = A
    ;     movdqu xmm4, xmm2 ; xmm4 = B
    ;     paddusb xmm3,xmm2 ; sumo saturado Add Packed Unsigned Integers With Unsigned Saturation
    ;     pand xmm3, [mascaraResBlue] ;hago que pasen solo los green
    ;     ;en xmm3 me quedo el resultado de a + b en todos los componentes
    ;     movdqu xmm2, xmm4 ; recupero xmm2 = B
        
    ;     ;componente green
    ;     .green:
    ;     movdqu xmm4, xmm1 ; xmm4 = A
    ;     movdqu xmm0, xmm1 ; xmm0 = A
    ;     movdqu xmm6, xmm1 ; xmm6 = A

    ;     pavgb xmm4,xmm2 ; en xmm4 me quedo el promedio de a con b

    ;     psubusb xmm6, xmm2 ; en xmm6 me quedo el resultado de a - b en todas las componentes

    ;     movdqu xmm5,xmm2 ; me guardo B
    ;     paddb xmm5,xmm8 ; le agrego el signo a B para poder hacer la resta
    ;     paddb xmm0,xmm8 ; tambien le agrego el signo a A
        
    ;     ;comparo a conn b SIGNADO
    ;     pcmpgtb xmm0, xmm5 ;hago la comparacion y la guardo en xmm0 y aqui me queda la mascara
    ;     pblendvb xmm4, xmm6 ; xmm4 = dst, xmm6 = src

    ;     ;en xmm4 tengo los resultados de blue
    ;     pand xmm4,[mascaraResGreen]
    ;     paddd xmm3,xmm4 ; hago que pasen solo los green
    ;     ;PBLENDVB — Variable Blend Packed Bytes, 
    ;     ;si en xmm0 el bit mas significativo del byte es 1,agarra el src ,si es 0 agara el dst
    ;     ;por lo tanto si es 1,es porque A > B y agarra el src es decir el xmm6
    ;     ;por lo tanto pondra la resta,caso contrario es porque A<= b y colocara el porcentaje

    ;     .red:
    ;     movdqu xmm5,xmm2 ; muevo a xmm5 B
    ;     pshufb xmm2, xmm9 ; en xmm2 tengo B PERO A B G R ya que vuelvo a hacer el shuffle
    ;     psubusb xmm5,xmm1 ; le resto a xmm5 xmm2
    ;     pand xmm5,[mascaraResRed]
    ;     paddd xmm3,xmm5 ; hago que pasen solo los red

    ;     por xmm3, xmm7 ;lo hago para las transparencias, ya que siempre sera 1 en las componetnes alpha
    ;     movdqu [r10 + rax], xmm3
    ;     add rax, 16
    ;     dec r8
    ;     jmp .ciclo

    ; .end:
    ; pop rbp
    ; ret


    ;para negar un xmm0
;   Cargar xmm0 con el valor a negar
; movdqu xmm0, [valor_a_negar]

;   Cargar xmm2 con una máscara de todos unos
; movdqu xmm2, [mascara_todos_unos]

;   Negar xmm0 utilizando XOR con la máscara
; pxor xmm0, xmm2

 ; si hay un 0,el xor con 1 va a dar 1, y si hay un 1 el xor con 1 va a dar 0
