;           <- ARRANCA DE ACA       
maskPares: dd 0x00FFFFFF,0x00000000,0x00FFFFFF,0x00000000
maskImpares:  dd 0x00000000,0x00FFFFFF,0x00000000,0x00FFFFFF
maskShiftADerecha:  db 0x02, 0x00, 0x01, 0x03, 0x06, 0x04, 0x05, 0x07, 0x0A, 0x08, 0x09, 0x0B, 0x0E, 0x0C, 0x0D, 0x0F

; A R G B |A R G B |A R G B| A R G B
; 15141312 11109 8  7 6 5 4  3 2 1 0
; EN MASCARA VA DE 0 A 15 IZQ A DER

; 15 12 13 14 11 8 9 10 7 4 5 6 3 0 1 2

; BGRA
mascaraResGreen: DB 0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00
mascaraResAlpha: DB 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF
mascaraResRed: DB 0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00
mascaraResBlue: DB 0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00
;                   B   G    R    A    B    G    R     A   B    G    R    A    B    G    R    A

; PMAXUB
; PMAXSB
; PMINUB
; PMINSB

global maximosYMinimos_asm

;########### SECCION DE TEXTO (PROGRAMA)
section .text

;void maximosYMinimos_asm(uint8_t *src, uint8_t *dst, uint32_t width, uint32_t height)
; src = dl rdi
; dst = sil  rsi
; width = edx rdx 
; height = ecx rcx

;RDI, RSI, RDX, RCX, R8, R9(

maximosYMinimos_asm:   
    push rbp
    mov rbp, rsp
    
    mov eax,  edx ; rax -> width
    mul ecx ; en rax va a estar ancho * alto
    mov r8d, eax ; r8 -> registro acumulador de iteraciones
    shr r8d, 2 ; divido por 4, ya que traemos de a 4 pixeles

    movdqu xmm8, [maskPares]
    movdqu xmm9, [maskImpares]
    movdqu xmm10, [maskShiftADerecha]

    xor rax, rax ; rax -> offset imagen
    ; cada pixel son 4 bytes, cada componente un byte, en un xmm entran 4 pixeles,16 componentes
    .ciclo:
        cmp r8d, 0
        je .end

        movdqu xmm1, [rdi + rax] ; traigo 4 pixeles
        movdqu xmm4, xmm1 ; xmm1 -> imagen original (esta no se modifica)
        movdqu xmm2, xmm1 ; xmm2 -> imagen original, se shiftea 1 vez
        movdqu xmm3, xmm1 ; xmm3 -> imagen original, se shiftea 2 veces

        pshufb xmm2, xmm10 ; xmm2 -> imagen shifteada 1 vez

        pshufb xmm3, xmm10 
        pshufb xmm3, xmm10 ; xmm3 -> imagen shifteada 2 veces
        
        pminub xmm4, xmm2 ; xmm4 -> minimo entre imagen shifteda 1 vez y imagen original
        pminub xmm4, xmm3 ; xmm4 -> minimo entre las 3

        pmaxub xmm1, xmm2 ; xmm1 -> maximo entre imagen shifteda 1 vez y imagen original
        pmaxub xmm1, xmm3 ; xmm1 -> maximo entre las 3

        pand xmm1, xmm8 ; xmm1 -> solo conserva posiciones pares
        pand xmm4, xmm9 ; xmm4 -> solo conserva posiciones impares

        paddd xmm1, xmm4

        movdqu [rsi + rax], xmm1 ; movemos resultado a memoria.
        
        add rax, 16
        dec r8d
        jmp .ciclo

    .end:

    pop rbp
    ret