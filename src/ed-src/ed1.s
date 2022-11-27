/*
 * ed1 -- init & i/o
 */

.global render, getchar, memmove, memadj, clear

ed:     call    clear
        call    render                          /* clear screen */
1:      call    run
        testb   (quit), -1
        je      1b
        call    clear                           /* exit sequence */
        call    render
        mov     bx, 1
        write   e_seq, e_len
        exit

e_seq:  b 27; <0x0y7a;>
e_len = .-e_seq

clear:
        mov     di, bss                         /* clear bss */
        mov     cx, bsslen
        xor     al, al
        cld; rep; stosb
        mov     (n_lines), 1
        mov     (lines), pool
        movb    (poolmap), 1                    /* alloc 1 line */
        movb    (pool), '\n
        ret

setcur: mov     ax, (y)                         /* set cursor pos */
        sub     ax, (top)
        mulb    (1f)
        add     ax, (x)
        mov     bx, ax
        cli
        mov     al, 14
        mov     dx, 0x3d4
        outb
        mov     al, bh
        mov     dx, 0x3d5
        outb
        mov     al, 15
        mov     dx, 0x3d4
        outb
        mov     al, bl
        mov     dx, 0x3d5
        outb
        sti
        ret
1:      b 80

skip:   mov     ax, 0x0720
        rep; stos
        ret

render:
        pusha
        push    es                              /* copy lines to video mem */
        push    0xb800
        pop     es
        xor     di, di
        mov     bx, (top)
        shl     bx, 1
        mov     dx, 24
        add     dx, (quit)                      /* erase command line on quit */
        cld
1:      mov     si, lines(bx)                   /* current line */
        add     bx, 2
        mov     cx, 80
        test    si, si
        jne     2f
        call    skip
        jmpb    4f
2:      mov     ah, 7
        lodsb
        cmp     al, '\s
        jge     3f
        testb   (color), 1
        je      6f
        mov     ah, al
        and     ah, 7
        shl     ah, 4
        or      ah, 7
6:      mov     al, '\s
3:      stos
        loop    2b
4:      dec     dx
        jne     1b
        cmpb    (quit), 0
        jne     5f
        call    cmdline
5:      pop     es
        call    setcur
        popa
        ret

getchar:
        mov     ax, (peekc)
        test    ax, ax
        jne     0f
        push    bx
        xor     bx, bx                          /* read char */
        read    1f, 1
        inc     bx
        write   e_seq, e_len                    /* keep cursor */
        mov     al, (1f)
        xor     ah, ah
        pop     bx
0:      mov     (peekc), 0
        and     al, 0x7f
        ret
1:      0

/* forward copy of cx bytes from si to di */
copy_f:
        cld; rep; movsb
        popa
        ret

/* backward copy of cx bytes from si to di */
copy_b:
        add     si, cx
        add     di, cx
        dec     si
        dec     di
        std; rep; movsb
        popa
        ret

memmove:
        pusha
        cmp     si, di
        ja      copy_f
        jmpb    copy_b

memadj:
        push    di
        add     di, si
        call    memmove
        pop     di
        ret
