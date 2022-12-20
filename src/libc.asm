; c runtime library

; system calls
_exit:  dw $+2
        xor     al, al
        int     0x20
        ret

_alloc: dw $+2
        mov     al, 1
        mov     bx, sp
        mov     bx, [bx+2]
        int     0x20
        ret

_free:  dw $+2
        mov     bx, sp
        mov     al, 2
        mov     bx, [bx+2]
        int     0x20
        ret

_open:  dw $+2
        mov     bx, sp
        mov     al, 3
        mov     cx, [bx+4]
        mov     bx, [bx+2]
        int     0x20
        ret

_close: dw $+2
        mov     bx, sp
        mov     al, 4
        mov     bx, [bx+2]
        int     0x20
        ret

_read:  dw $+2
        mov     bx, sp
        mov     al, 5
        mov     dx, [bx+6]
        mov     cx, [bx+4]
        mov     bx, [bx+2]
        int     0x20
        ret

_write: dw $+2
        mov     bx, sp
        mov     al, 6
        mov     dx, [bx+6]
        mov     cx, [bx+4]
        mov     bx, [bx+2]
        int     0x20
        ret

_seek:  dw $+2
        mov     bx, sp
        mov     al, 7
        mov     dx, [bx+6]
        mov     cx, [bx+4]
        mov     bx, [bx+2]
        int     0x20
        ret

_dup:   dw $+2
        mov     bx, sp
        mov     al, 8
        mov     bx, [bx+2]
        int     0x20
        ret

_dup2:  dw $+2
        mov     bx, sp
        mov     al, 9
        mov     cx, [bx+4]
        mov     bx, [bx+2]
        int     0x20
        ret

_execv: dw $+2
        mov     bx, sp
        mov     al, 10
        mov     dx, [bx+6]
        mov     cx, [bx+4]
        mov     bx, [bx+2]
        int     0x20
        ret

; getchar/putchar
_getchar: dw $+2
        mov     al, 5
        xor     bx, bx
        mov     cx, ibuf
        mov     dx, 1
        int     0x20
        mov     ax, [ibuf]
        ret
ibuf:   dw 0

_putchar: dw $+2
        mov     bx, sp
        push    word [bx+2]
        pop     word [ibuf]
        mov     al, 6
        mov     bx, 1
        mov     cx, ibuf
        mov     dx, 1
        int     0x20
        ret

; allocation
_brk:   dw $+2
        mov     bx, sp
        mov     cx, [bx+2]
        mov     di, [storage]
        push    di
        add     [storage], cx
        xor     al, al
        cld
        rep stosb
        pop     ax
        ret

; printning
_printn: dw $+2
        mov     bx, sp
        mov     ax, [bx+2]
        mov     bx, [bx+4]
.1:     xor     dx, dx
        idiv    bx
        add     dx, '0'
        push    dx
        test    ax, ax
        je      .2
        call    .1
.2:     call    [_putchar]
        add     sp, 2
        ret

_puts:  dw $+2
        mov     bx, sp
        mov     si, [bx+2]
.1:     lodsb
        test    al, al
        jz      .2
        push    ax
        call    [_putchar]
        add     sp, 2
        jmp     .1
.2:     ret

storage:
        dw      $
