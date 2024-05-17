%define SYS_EXIT 60

extern print_uint64

section	.data

section	.text
	global _start

_start:                

    xor rbx,rbx
    mov rbx, 0xFFFFFFFFFFFFFFFF
    xor rcx,rcx
    mov rcx, 0xFFFFFFFFFFFFFFFF

    add rcx,rbx 

_tmp:
    xor rdi,rdi

    mov dil, cl
    call print_uint64

    mov	eax, 1	    
	int	0x80 

_end:
    mov rax, SYS_EXIT
    mov rdi, 0
    syscall
    
Overflow flag — Set if the integer result is too large a positive number or too small a negative
number (excluding the sign-bit) to fit in the destination operand; cleared otherwise. This flag
indicates an overflow condition for signed-integer (two’s complement) arithmetic.