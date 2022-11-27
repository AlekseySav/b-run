/*
 * assembler, first pass
 * as13 -- lexer
 */

.global unlex, lex, slash

unlex:  mov     (tok), al
        mov     (lval), bx
        ret

bad:    push    bx
        call    error; '?
        pop     bx
skip:
lex:    mov     al, (tok)
        test    al, al
        js      1f
        mov     (tok), -1
        mov     bx, (lval)
        ret
1:      call    getc
        push    ax
        mov     bx, ctab
        xlat
        mov     bx, ax
        shl     bx, 1
        pop     ax
        jmp     jmptab(bx)       

new:    cmp     al, '\n
        jne     1f
        inc     (line)
1:      mov     al, ';
op:     cmp     al, '/
        jne     1f
        call    getc
        cmp     al, '*
        je      comm
        mov     (char), al
        mov     al, '/
1:      ret

comm:   call    getc
2:      cmp     al, '\n
        jne     1f
        inc     (line)
1:      cmp     al, '*
        jne     comm
        call    getc
        cmp     al, '/
        jne     2b
        jmp     lex

quote:  call    getc
        cmp     al, '\\
        jne     1f
        call    slash
1:      mov     bx, ax
        xor     ax, ax
        ret

ident:  cld
        push    di
        mov     di, symbol
1:      stosb
        call    getc
        mov     bx, ctab
        push    ax
        xlat
        cmp     al, 5
        jne     2f
        pop     ax
        jmpb    1b
2:      xor     al, al
        stosb
        pop     (char)
        pop     di
        push    si
        mov     si, symbol
        call    lookup
        pop     si
        mov     ax, 1
        ret

number: push    dx
        xor     bx, bx
        mov     (base), 10
        cmp     al, '0
        jne     1f
        mov     (base), 8
        call    getc
        cmp     al, 'x
        jne     1f
        mov     (base), 16
        call    getc
1:      xchg    ax, bx
        cmpb    ctab(bx), 5
        jl      2f
        mul     (base)
        sub     bl, '0
        cmp     bl, 9
        jle     3f
        sub     bl, 'a-'0-10
3:      add     bx, ax
        call    getc
        jmpb    1b
2:      xchg    ax, bx
        pop     dx
        mov     (char), al
        xor     ax, ax
        ret

base:   0

slash:  call    getc
        push    di
        push    cx
        mov     di, ctrl
        mov     cx, 10
        cld
2:      scasb
        je      3f
        scasb
        loop    2b
        push    bx
        call    error; '\\
        pop     bx
3:      mov     al, (di)
        pop     cx
        pop     di
        ret

ctrl:   b '0,   '\0
        b 'n,   '\n
        b 't,   '\t
        b 'r,   '\r
        b 'b,   '\b
        b 'd,   '\d
        b 's,   '\s
        b 'e,   '\e
        b '>,   '>
        b '\\,  '\\
        b '\0

jmptab: bad
        new
        skip
        op
        quote
        ident
        number
