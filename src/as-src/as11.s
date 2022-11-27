/*
 * assembler, first pass
 * as11 -- entry & i/o
 */

.global error, getc, putc, putw, quit

        xor     al, al
        mov     di, bss
        mov     cx, bsslen
        cld
        rep; stosb              /* zero bss */
        mov     cx, bsyms
        mov     si, symtab
1:      call    lookup          /* init builtins */
        add     si, symsize
        loop    1b
        mov     bx, relnm       /* open relocs */
        open    1
        mov     (relfd), ax
        mov     bx, txtnm       /* open .text */
        open    1
        mov     (txtfd), ax
1:      mov     (pc.adj), 0
        mov     (arg), 0
        movb    (argsiz), 0
        movb    (pcrel), 0
        movb    (size), 1
        call    assem
        mov     ax, (pc.adj)
        add     (pc.data), ax
        jmpb    1b
quit:   call    flush
        mov     bx, (relfd)
        close
        mov     bx, (txtfd)
        close
        mov     ax, (nsyms)
        sub     ax, bsyms
        mov     (e.syms), ax
        mov     bx, outnm
        open    1
        mov     di, ax
        mov     bx, ax
        write   header, 6
        call    copy; txtnm
        call    putsym
        call    copy; relnm
        mov     bx, di
        close
        mov     bx, as2
        exec    0, 0
panic:  exit

relnm:  <astmpR\0>
txtnm:  <astmpT\0>
outnm:  <astmpO\0>
as2:    <as2\0>
txtfd:  0
getp: 512
putp: 0

.proc   error:
        pusha
        mov     di, errbuf
        mov     ax, (line)
        push    2f
ln:     xor     dx, dx
        div     (n)
        push    dx
        test    ax, ax
        jz      1f
        call    ln
1:      pop     ax
        add     al, '0
        stosb
        ret
n:      10
2:      mov     ax, (bx)++
        cli
        stosb
        mov     al, '\n
        stosb
        mov     bx, 2
        mov     dx, di
        sub     dx, errbuf
        write   errbuf
        popa
        incb    (nerror)
        cmpb    (nerror), 10
        jge     panic
        add     bx, 2
        rts

getc:   xor     ah, ah
        mov     al, (char)
        test    al, al
        jz      1f
        movb    (char), 0
        ret
1:      cmp     (getp), 512
        jl      1f
        pusha
        xor     bx, bx
        read    getbuf, 512
        mov     bx, ax
        movb    getbuf(bx), '\d
        mov     (getp), 0
        popa
1:      push    bx
        mov     bx, (getp)
        inc     (getp)
        mov     al, getbuf(bx)
        pop     bx
        ret

putw:   call    putc
        mov     al, ah
putc:   pusha
        cmp     (putp), 512
        jl      1f
        push    ax
        call    flush
        pop     ax
1:      mov     bx, (putp)
        inc     (putp)
        inc     (e.text)
        mov     putbuf(bx), al
        popa
        inc     (pc.adj)
        ret

flush:  mov     bx, (txtfd)
        mov     dx, (putp)
        write   putbuf
        ret

.proc   copy:
        mov     ax, (bx)++
        push    bx
        mov     bx, ax
        open    0
        mov     si, ax
1:      mov     bx, si
        read    getbuf, 512
        mov     bx, di
        mov     dx, ax
        write   getbuf
        cmp     ax, 512
        je      1b
        mov     bx, si
        close
        ret
