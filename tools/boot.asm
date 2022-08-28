        jmp     word init
        resb    0x50
init:   jmp     0x07c0:init2
init2:  mov     si, msg
        mov     cx, msglen
print:  mov     bx, 1
        mov     ah, 0x0e
        cs lodsb
        int     0x10
        loop    print
        mov     ax, 0x1000
        mov     ds, ax
        mov     es, ax
        cli
        mov     ss, ax
        mov     sp, 0xfff0
        mov     bp, sp
        sti
        mov     di, bp
        mov     cx, 8
        mov     ax, 0xaaaa
        cld
        rep
        stosw
        mov     ax, 0x0201
        mov     cx, 2
        mov     dh, 0
        push    dx
        xor     bx, bx
        int     0x13
        jnc     meta
perr:   mov     si, err
        mov     cx, errlen
error:  mov     bx, 1
        mov     ah, 0x0e
        cld
        cs lodsb
        int     0x10
        loop    error
        jmp     $
meta:   mov     ax, [4]
        shl     al, 1
        mov     ah, 0x02
        mov     cx, [2]
        shl     cx, 1
        inc     cx
        pop     dx
        xor     bx, bx
        int     0x13
        jc      perr
        jmp     0x1000:0

msg:    db      13, 10, "Loading sysyem ...", 13, 10, 13, 10
msglen: equ     $-msg
err:    db      "error", 13, 10
errlen: equ     $-err 

        times   510-($-$$) db 0
        dw      0xaa55
