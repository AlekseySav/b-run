/*
 * assembler, first pass
 * as14 -- expression parser
 */

.global expr, cexpr

cexpr:  call    expr
        mov     ax, (v.data)
        test    (v.flgs), s.defin
        je      1f
        test    (v.flgs), s.firel
        je      2f
1:      call    error; 'c
2:      ret

expr:   pusha
        call    value
        mov     (v.flgs), cx
        mov     (v.data), ax
        mov     (v.symb), bx
3:      call    lex             /* binary */
        mov     di, btab
        mov     cx, bsiz
        cld
1:      scasb
        je      2f
        inc     di
        loop    1b
        call    unlex
        popa
        ret
2:      mov     al, (di)
        add     ax, x.bgn
        push    ax
        call    value
        pop     dx
        test    cx, s.defin
        jne     1f
        call    err             /* math with undefined bad */
1:      test    (v.flgs), s.defin
        jne     1f
        call    err
1:      call    dx
        jmpb    3b

/* ax=value, cx=flags, bx=symbol */
value:  call    lex
        cmp     al, 1
        jbe     1f
        cmp     al, '[
        jne     2f              /* bracket */
        push    (v.flgs)
        push    (v.data)
        push    (v.symb)
        call    expr
        call    lex
        cmp     al, ']
        je      3f
        call    unlex
        call    error; ']
3:      mov     ax, (v.data)
        mov     cx, (v.flgs)
        mov     bx, (v.symb)
        pop     (v.symb)
        pop     (v.data)
        pop     (v.flgs)
        ret
2:      push    ax              /* unary */
        call    value
        pop     dx
        call    unary
        ret
1:      test    al, al
        je      2f
        mov     cx, s.flags(bx) /* symbol */
        test    cx, s.built
        je      3f
        call    error; 'B       /* used builtin symbol */
        xor     bx, bx
        jmpb    2f
3:      mov     ax, s.value(bx)
        ret
2:      mov     cx, s.defin
        mov     ax, bx
        xor     bx, bx
        ret

err:    push    bx
        call    error; 'E
        pop     bx
        ret

tstrel: test    cx, s.firel
        je      1f
        call    err
1:      test    (v.flgs), s.firel
        je      1f
        call    err
1:      ret

unary:  test    cx, s.defin
        je      err
        push    cx
        mov     di, utab
        mov     cx, usiz
2:      cmp     dl, (di)
        je      3f
        add     di, 2
        loop    2b
        push    bx
        call    error; 'u
        pop     bx
3:      mov     dl, ++(di)
        xor     dh, dh
        add     dx, u.bgn
        pop     cx
        jmp     dx

u.bgn:
u.neg:  neg     ax
u.ret:  ret
u.inv:  not     ax
        ret
u.not:  test    ax, ax
        jz      1f
        xor     ax, ax
        ret
1:      mov     ax, 1
        ret

x.bgn:
x.add:  test    cx, s.firel
        je      1f
        test    (v.flgs), s.firel
        je      2f              /* const+filerel -> filerel */
        call    err             /* filerel+filerel -> bad */
2:      or      (v.flgs), s.firel
1:      add     (v.data), ax
        ret
x.sub:  test    cx, s.firel
        je      1f
        test    (v.flgs), s.firel
        jne     2f              /* const-filerel -> bad */
        call    err             /* filerel-filerel -> const */
2:      and     (v.flgs), s.norel
1:      sub     (v.data), ax
        ret
x.mul:  call    tstrel
        xchg    (v.data), ax
        mul     (v.data)
        xchg    (v.data), ax
        ret
x.div:  call    tstrel
        xor     dx, dx
        mov     (denum), ax
        mov     ax, (v.data)
        div     (denum)
        mov     (v.data), ax
        ret
x.mod:  call    tstrel
        xor     dx, dx
        mov     (denum), ax
        mov     ax, (v.data)
        div     (denum)
        mov     (v.data), dx
        ret
x.xor:  call    tstrel
        xor     (v.data), ax
        ret
x.and:  call    tstrel
        and     (v.data), ax
        ret
x.or:   call    tstrel
        or      (v.data), ax
        ret
x.eq:   call    tstrel
        cmp     ax, (v.data)
        jne     1f
        mov     (v.data), 1
        ret
1:      mov     (v.data), 0
        ret
denum:  0

usiz = 4
utab:   b '-,   u.neg-u.bgn
        b '!,   u.not-u.bgn
        b '~,   u.inv-u.bgn
        b '+,   u.ret-u.bgn
        b 0,    u.ret-u.bgn

bsiz = 9
btab:   b '+,   x.add-x.bgn
        b '-,   x.sub-x.bgn
        b '*,   x.mul-x.bgn
        b '/,   x.div-x.bgn
        b '%,   x.mod-x.bgn
        b '^,   x.xor-x.bgn
        b '&,   x.and-x.bgn
        b '|,   x.or-x.bgn
        b '=,   x.eq-x.bgn
