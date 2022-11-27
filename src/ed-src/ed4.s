/*
 * ed4 -- special commands
 */

.global cmdline, command, printn


attr:   0x70
a_seq:  b 27; <24y2x16a;>
a_len = .-a_seq
b_seq:  b 27; <0y0x7a;>
b_len = .-b_seq
xbuf:   <                \0>
bufp:   xbuf
file:   <unnamed\0\0\0>

putc:   stos
        dec     bx
        jcxz    1f
        loop    putc
1:      ret

puts:   lodsb
        test    al, al
        je      1f
        stos
        dec     bx
        jmpb    puts
1:      ret

putn:   xor     dx, dx
        div     (1f)
        push    dx
        test    ax, ax
        je      2f
        call    putn
2:      pop     ax
        add     al, '0
        mov     ah, (attr)
        jmpb    putc
1:      10

printn: pusha
        mov     di, (bufp)
        call    1f
        inc     di
        mov     (bufp), di
        popa
        ret
1:      xor     dx, dx
        div     (1f)
        push    dx
        test    ax, ax
        je      2f
        call    1b
2:      pop     ax
        add     al, '0
        stosb
        ret
1:      10

cmdline:
        mov     bx, 80
        xor     cx, cx
        mov     ah, (attr)
        mov     al, '\s; call putc
        mov     al, ':; call putc
        mov     al, '\s
        mov     cx, 34
        call    putc
        mov     si, xbuf;       call    puts
        mov     al, '(;         call    putc
        mov     si, file;       call    puts
        mov     al, ':;         call    putc
        mov     ax, (y);        inc     ax; call putn
        mov     al, ':;         call    putc
        mov     ax, (x);        inc     ax; call putn
        mov     al, ');         call    putc
        mov     al, '\s;        call    putc
        mov     al, '(;         call    putc
        mov     ax, (n_lines);  call    putn
        mov     al, '/;         call    putc
        mov     ax, LINES;      call    putn
        mov     al, ');         call    putc
        mov     cx, bx
        mov     al, '\s
        call    putc
        ret

command:
        movb    (attr), 0x10
        call    render
        mov     bx, 1
        write   a_seq, a_len
        xor     bx, bx
        mov     si, line
1:      mov     dx, 1
        mov     cx, si
        read
        cld; lodsb
        cmpb    al, 27
        je      2f
        cmpb    al, '\b
        jne     3f
        sub     si, 2
3:      cmpb    al, '\n
        jne     1b
        sub     si, line
        je      2f
        mov     bx, 1
        write   b_seq, b_len
        mov     cx, si
        sub     cx, 2                           /* cx=arg len */
        mov     si, line
        inc     si                              /* si=arg ptr */
        movb    bl, (line)
        xor     bh, bh
        shl     bx, 1
        push    2f
        jmp     mtab(bx)
2:      movb    (attr), 0x70
        mov     bx, 1
        write   b_seq, b_len
        ret

unkc:   ret

filc:   mov     di, file
        cld; rep; movsb
        movb    (di), 0
        ret

colc:   xorb    (color), 1
        ret

exic:   incb    (quit)
        ret

gotc:   xor     bx, bx
1:      lodsb
        xor     ah, ah
        sub     al, '0
        xchg    ax, bx
        mul     (1f)
        add     ax, bx
        mov     bx, ax
        loop    1b
        dec     ax
        mov     (y), ax
        mov     (x), 0
        ret
1:      10

opec:   mov     bx, file
        mov     cx, 0
        open
        mov     bx, ax
        test    bx, bx
        js      1f
        call    clear                           /* clear prev file data */
3:      read    peekc, 1                        /* read char-by-char */
        cmp     ax, 0
        jle     2f
        push    bx
        call    run
        pop     bx
        jmpb    3b
2:      close
1:      ret

savc:   mov     bx, file
        mov     cx, 1
        open
        mov     bx, ax
        xor     bp, bp                          /* lines(bp)=curr line */
        mov     dx, (n_lines)
1:      mov     si, lines(bp)
        add     bp, 2
        mov     di, outbuf
        mov     cx, 80
2:      cld; lodsb
        test    al, al
        je      3f
        stosb
3:      loop    2b
        push    dx
        mov     cx, outbuf
        mov     dx, di
        sub     dx, cx
        write
        pop     dx
        dec     dx
        jne     1b
        close
        ret

clrc:   jmp     clear
delc:   jmp     delline

mtab:
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; clrc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; filc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; colc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; delc; unkc; unkc; unkc
        unkc; unkc; gotc; unkc; unkc; unkc; unkc; opec
        unkc; exic; unkc; savc; unkc; unkc; unkc; unkc
        unkc; unkc; unkc; unkc; unkc; unkc; unkc; unkc
