; /** defines bool y puntero **/
%define NULL 0
%define TRUE 1
%define FALSE 0


%define OFFSET_LIST_FIRST 0
%define OFFSET_LIST_LAST 8
%define STRUCT_SIZE_LIST 16
%define OFFSET_NODE_NEXT 0
%define OFFSET_NODE_PREVIOUS 8
%define OFFSET_NODE_TYPE 16
%define OFFSET_NODE_HASH 24
%define STRUCT_SIZE_NODE 32


section .data

section .text

global string_proc_list_create_asm
global string_proc_node_create_asm
global string_proc_list_add_node_asm
global string_proc_list_concat_asm

; FUNCIONES auxiliares que pueden llegar a necesitar:
extern malloc
extern free
extern str_concat


string_proc_list_create_asm:

    push rbp
    mov rbp, rsp

    mov rdi, 16
    call malloc ;devuelve en rax el puntero 

    mov qword [rax + OFFSET_LIST_FIRST], NULL
    mov qword [rax + OFFSET_LIST_LAST], NULL

    pop rbp
    ret
    
; • Los par´ametros enteros se pasan de izquierda a derecha en
; RDI, RSI, RDX, RCX, R8, R9 respectivamente
; • Los par´ametros flotantes se pasan de izquierda a derecha en
; XMM0, XMM1, XMM2, XMM3, XMM4, XMM5, XMM6, XMM7
; respectivamente
; • Si no hay registros disponibles para los par´ametros enteros
; y/o flotantes se pasar´an de derecha a izquierda a trav´es de
; la pila haciendo PUSH.
; • Las estructuras se tratan de una forma especial (ver
; referencia). Si son grandes se pasa un puntero a la misma
; como par´ametro.



; en dil esta el type y en rsi el hash
;string_proc_node* string_proc_node_create(uint8_t type, char* hash){
    ; rdi = type, rsi = hash

string_proc_node_create_asm:

    push rbp ; alineada
    mov rbp, rsp
    push rsi ; desalineada
    ;me guardo el type
    push rdi ; alineada

    ;primero hay que pedir memoria
    mov rdi, 32
    call malloc
    ;en rax estará el puntero
    
    pop rdi ; recupero el type
    pop rsi

    mov qword [rax + OFFSET_NODE_NEXT], NULL
    mov qword [rax + OFFSET_NODE_PREVIOUS], NULL
    mov [rax + OFFSET_NODE_TYPE], rdi
    mov [rax + OFFSET_NODE_HASH], rsi

    pop rbp
    ret


;void string_proc_list_add_node(string_proc_list* list, uint8_t type, char* hash){
; list = rdi  type = rsi  char =  rdx

 string_proc_list_add_node_asm:
    push rbp ;alineada la pila
    mov rbp, rsp

    push rdi ; preserva puntero a la lista
    sub rsp, 8 ; alinea pila

    mov rdi, rsi
    mov rsi, rdx
    call string_proc_node_create_asm
    ;en rax me queda el puntero al nuevo nodo

    add rsp, 8
    pop rdi

    xor r9,r9 
    mov r9, [rdi + OFFSET_LIST_FIRST]
    cmp r9, NULL
    je .hayunosolo

    mov r8, [rdi + OFFSET_LIST_LAST] ; ahora en r8 tengo el puntero que apunta al ultimo,el cual debo modificar
    mov qword [r8 + OFFSET_NODE_NEXT], rax ; muevo el puntero al ultimo
    mov qword [rax + OFFSET_NODE_PREVIOUS], r8 ; muevo el puntero a anteultimo 
    mov qword [rdi + OFFSET_LIST_LAST], rax ; ahora el último es el creado
    jmp .end
    
    .hayunosolo:
        mov [rdi + OFFSET_LIST_FIRST], rax ; ahora el primero es el nuevo
        mov [rdi + OFFSET_LIST_LAST], rax ; ahora el primero es el nuevo


    .end:
        pop rbp
        ret

; char* string_proc_list_concat(string_proc_list* list, uint8_t type , char* hash){
; lsit = rdi, type = rsi, hash = rdx
string_proc_list_concat_asm:
    push rbp
    mov rbp,rsp 
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi ; list
    mov r13, rdx ; hash
    mov r14, rsi ; type

    mov rdi, 1
    call malloc ; en rax voy a tener puntero a memoria
    mov byte [rax], NULL ; string vacio
    mov r15, rax ; puntero a string vacio
    mov rdi, rax
    mov rsi, r13 ; muevo el hash
    call str_concat ; llamo a string concat que me devuelve en rax el nuevo puntero
    mov r13, rax
    mov rdi, r15 ; vamos a limpiar memoria
    call free ; liberamos memoria

    ;veo si la lista es vacia
    cmp qword [r12 + OFFSET_LIST_FIRST], NULL 
    je .end
    ;else avanzo

    mov r12, [r12 + OFFSET_LIST_FIRST] 
    ; en r13 tengo el hash concatenado

    .while:
        cmp r12, 0
        je .end

        cmp [r12 + OFFSET_NODE_TYPE], r14 ; si son mismo tipo entonces tengo que concatenarlos
        jne .next 
        ; concateno

        mov rdi, r13 ; hash concatenado
        mov rsi, [r12 + OFFSET_NODE_HASH]; el hash del nodo
        call str_concat ; llamo a string concat que me devuelve en rax el nuevo
        mov rdi, r13 ; el anterior hash lo mato
        mov r13,rax ;vuelvo a guardar en r13 el resultado
        call free

        .next: 
        mov r12,[r12 + OFFSET_NODE_NEXT] ; avanzo
        jmp .while



    .end:
    mov rax, r13
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    ret
