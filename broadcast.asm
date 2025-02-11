; ┌──────────────────────────────────────────────────────────────────────────┐
; │  888                                 888                        888      │
; │  888                                 888                        888      │
; │  888                                 888                        888      │
; │  88888b. 888d888 .d88b.  8888b.  .d88888 .d8888b 8888b. .d8888b 888888   │
; │  888 "88b888P"  d88""88b    "88bd88" 888d88P"       "88b88K     888      │
; │  888  888888    888  888.d888888888  888888     .d888888"Y8888b.888      │
; │  888 d88P888    Y88..88P888  888Y88b 888Y88b.   888  888     X88Y88b.    │
; │  88888P" 888     "Y88P" "Y888888 "Y88888 "Y8888P"Y888888 88888P' "Y888   │
; │                                                                          │
; │                                                                          │
; │                                                                          │
; │                                                        888 .d888         │
; │                                                        888d88P"          │
; │                                                        888888            │
; │         888  888 .d88b. 888  888888d888.d8888b  .d88b. 888888888         │
; │         888  888d88""88b888  888888P"  88K     d8P  Y8b888888            │
; │         888  888888  888888  888888    "Y8888b.88888888888888            │
; │         Y88b 888Y88..88PY88b 888888         X88Y8b.    888888            │
; │          "Y88888 "Y88P"  "Y88888888     88888P' "Y8888 888888            │
; │              888                                                         │
; │         Y8b d88P                                                         │
; │          "Y88P"                                                          │
; ├──────────────────────────────────────────────────────────────────────────┤
; │ [bah / Feb 2025 / 120 bytes / GPL2]                                      │
; │ what: Linux ELF64 that sends itself around the LAN via a UDP broadcast   │
; │ build: nasm -f bin -o broadcast broadcast.asm && chmod +x broadcast      │
; │ usage: nc -q1 -vbul 0 60414 </dev/null > /tmp/out.elf                    │
; └──────────────────────────────────────────────────────────────────────────┘
        BITS    64

; ┌──────────────────────────────────────────────────────────────────────────┐
; │  The ELF Header is from:                                                 │
; │  https://www.muppetlabs.com/~breadbox/software/tiny/tiny-x64.asm.txt     │
; │  (Available under GPL2)                                                  │
; │  Extra code is added into it to save space.                              │
; └──────────────────────────────────────────────────────────────────────────┘
        org     0x500000000

        db      0x7F                    ; e_ident
        db      "ELF"                   ; 3 REX prefixes (no effect)
; ┌──────────────────────────────────────────────────────────────────────────┐
; │  We use the 12 bytes of free space here to call socket(), before jumping │
; │  to another free slot in the header.                                     │
; └──────────────────────────────────────────────────────────────────────────┘
        mov     al, 41                  ; 2 bytes - 41 is the syscall number
                                        ; for socket().
                                        ; This 2 byte mov to the lower bits
                                        ; works for the majority of registers.
        mov     di, 2                   ; 2 bytes - 2 is AF_INET
        mov     esi, edi                ; 2 bytes - SOCK_DGRAM is also 2.

        syscall                         ; 2 bytes for syscall.

        jmp     _next ; ─────────────────────────────────────────────────────┐
                                                                           ; │
        dw      2                       ; e_type                           ; │
        dw      62                      ; e_machine                        ; │
        dd      1                       ; e_version                        ; │
phdr:                                                                      ; │
        dd      1                       ; e_entry       ; p_type           ; │
        dd      5                                       ; p_flags          ; │
        dq      phdr - $$               ; e_phoff       ; p_offset         ; │
        dq      phdr                    ; e_shoff       ; p_vaddr          ; │
                                                                           ; │
; 6 bytes of free real estate                                              ; │
_next: ; ◀───────────────────────────────────────────────────────────────────┘
; ┌──────────────────────────────────────────────────────────────────────────┐
; │  This is the first part of our call to setsockopt(), which we have to    │
; │  call to set the SO_BROADCAST option.                                    │
; └──────────────────────────────────────────────────────────────────────────┘
        push    rax                     ; Just copying the socket id into rdi
        pop     rdi                     ; push / pop is the smallest reg swap
        mov     al, 54                  ; setsockopt() is syscall number 54
        jmp     _body ; ─────────────────────────────────────────────────────┐
                                                                           ; │
        dw      0x38                    ; e_phentsize                      ; │
        dw      1                       ; e_phnum       ; p_filesz         ; │
        dw      0x40                    ; e_shentsize                      ; │
        dw      0                       ; e_shnum                          ; │
        dw      0                       ; e_shstrndx                       ; │
        dq      0x00400001                              ; p_memsz          ; │
        ; p_align can be whatever                                          ; │
                                                                           ; │
_body: ; ◀───────────────────────────────────────────────────────────────────┘
; ┌──────────────────────────────────────────────────────────────────────────┐
; │  Now onto our second part of the setsockopt() call.                      │
; └──────────────────────────────────────────────────────────────────────────┘
        xor     esi, esi                ; 4 bytes, with these two instructions
        inc     esi                     ; being just mov esi, SOL_SOCKET.
        
        mov     dl, 6                   ; 2 bytes, setting rdx to SO_BROADCAST
        mov     r10, rsp                ; 3 bytes, justing the stack as free
                                        ; space.
        mov     r8b, 4                  ; 3 bytes, as we just need to pass any
                                        ; size for the option.
        syscall                         ; 2 bytes

; ┌──────────────────────────────────────────────────────────────────────────┐
; │  Now lets call sendto() and broadcast our code to the LAN.               │
; └──────────────────────────────────────────────────────────────────────────┘
        mov     al, 44                  ; 2 bytes, 44 for sendto()

; ┌──────────────────────────────────────────────────────────────────────────┐
; │  Push our sockaddr struct to the stack, which will contain:              │
; │  >>> 0xfffffffffeeb0002                                                  │
; │                                                                          │
; │  Which means:                                                            │
; │  * 0x02 (AF_INET)                                                        │
; │  * 0xebfe (port 60414)                                                   │
; │  * 255.255.255.255 (the broadcast address)                               │
; │                                                                          │
; │  We do this by subtracting a value from ebp, which should be 0 at this   │
; │  point.                                                                  │
; │                                                                          │
; │  The constant we use for the subtraction was derived with:               │
; │  >>> hex(2**64 - 0xff_ff_ff_ff_fe_eb_00_02)                              │
; │                                                                          │
; │  The port needs to have the top bit of the 0xfe set as otherwise we      │
; │  can't use the constant as an intermediate value for sub.                │
; └──────────────────────────────────────────────────────────────────────────┘             
        sub     rbp, 0x114fffe          ; 7 bytes.
        push    rbp                     ; 1 byte.

        lea     rsi, [rel $$]           ; 6 bytes, getting rsi to be a pointer
                                        ; to the start of our code.

        mov     dl, _end - $$           ; 2 bytes, just mov in the size of the
                                        ; binary.

        xor     r10, r10                ; 3 bytes. we don't want any flags set.
        mov     r8, rsp                 ; 3 bytes. we put the sockaddr struct
                                        ; on the stack.
        mov     r9, rax                 ; 3 bytes, just need r9 to be larger
                                        ; than 16 for the struct size. Linux
                                        ; doesn't care that much beyond that.

        syscall                         ; 2 bytes

; ┌──────────────────────────────────────────────────────────────────────────┐
; │  Finally, do a clean exit() and avoid a crash (or an infloop).           │
; └──────────────────────────────────────────────────────────────────────────┘
        mov     al, 60                  ; 2 bytes
        syscall                         ; 2 bytes

_end:
; ┌──────────────────────────────────────────────────────────────────────────┐
; │  00000000: 7f45 4c46 b029 66bf 0200 89fe 0f05 eb20  .ELF.)f........      │
; │  00000010: 0200 3e00 0100 0000 0100 0000 0500 0000  ..>.............     │
; │  00000020: 1800 0000 0000 0000 1800 0000 0500 0000  ................     │
; │  00000030: 505f b036 eb12 3800 0100 4000 0000 0000  P_.6..8...@.....     │
; │  00000040: 0100 4000 0000 0000 31f6 ffc6 b206 4989  ..@.....1.....I.     │
; │  00000050: e241 b004 0f05 b02c 4881 edfe ff14 0155  .A.....,H......U     │
; │  00000060: 488d 3599 ffff ffb2 784d 31d2 4989 e049  H.5.....xM1.I..I     │
; │  00000070: 89c1 0f05 b03c 0f05                      .....<..             │
; └──────────────────────────────────────────────────────────────────────────┘
; EOT
