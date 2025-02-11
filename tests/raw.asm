; initial version without optimizations

BITS 64

%define SOL_SOCKET 1
%define AF_INET 2
%define SOCK_DGRAM 2
%define SO_BROADCAST 6

        org     0x500000000

_header:

        db      0x7F                    ; e_ident
_fake_start:
        db      "ELF"                   ; 3 REX prefixes (no effect)
        nop
        nop
        nop
        
        nop
        nop
        nop

        nop
        nop
        nop

        jmp     _start

        db      0

        dw      2                       ; e_type
        dw      62                      ; e_machine
        dd      1                       ; e_version
phdr:
        dd      1                       ; e_entry       ; p_type
        dd      5                                       ; p_flags
        dq      phdr - $$               ; e_phoff       ; p_offset
        dq      phdr                    ; e_shoff       ; p_vaddr

; 6 bytes we can use, down to 4 because of the jump we need to do, as there is
; no benefit from using it at the end, as that will require a long jump making
; the savings pointless.
; I learnt this trick from reading mndz's entry [5].
;
; [5] https://github.com/0x6d6e647a/bggp-2024/blob/main/elf64.asm
_header_save:
        nop
        nop
        nop
        nop
        nop
        nop

        dw      0x38                    ; e_phentsize
        dw      1                       ; e_phnum       ; p_filesz
        dw      0x40                    ; e_shentsize
        dw      0                       ; e_shnum
        dw      0                       ; e_shstrndx
        dq      0x00400001                              ; p_memsz
        ; p_align can be whatever


_start:

; socket
    mov rax, 41
    mov rdi, AF_INET
    mov rsi, SOCK_DGRAM
    syscall

; setsockopts
    mov rdi, rax
    mov rax, 54
    mov rsi, SOL_SOCKET
    mov rdx, SO_BROADCAST
    mov r10, rsp
    mov r8, 4

    syscall

; sendto
    mov rax, 44
    ; rdi should be set
    lea rsi, [rel _header]
    mov rdx, _end - _header
    mov r10, 0
    mov r8, 0xffffffff39050002
    push r8
    mov r8, rsp
    mov r9, 16

    syscall

; end
self:
    jmp self

_end:
