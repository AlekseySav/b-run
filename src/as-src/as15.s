/*
 * assembler, first pass
 * as15 -- parse instruction
 */

.global assem

assem:  call    lex
        mov     di, a.tab
        mov     dx, a.len
        cld
1:      scasb
        je      2f
        inc     di
        dec     dx
        jne     1b
putval: call    unlex
        call    expr
        jmp     value
2:      mov     dl, (di)
        add     dx, a.bgn
        jmp     dx

a.bgn:
a.symb: call    getc            /* try to find '=' or ':' */
        cmp     al, '\s
        je      a.symb
        cmp     al, '=
        je      const
        cmp     al, ':
        je      label
        mov     (char), al
        mov     al, 1
        test    s.flags(bx), s.built
        je      putval
        jmp     opcode
a.doll: jmp     dollar
a.asci: call    getc
        cmp     al, '>
        je      a.skip
        cmp     al, '\n
        jne     1f
        call    error; '\'
        jmp     a.skip
1:      cmp     al, '\\
        jne     1f
        call    slash
1:      call    putc
        jmp     a.asci
a.skip: ret
a.quit: jmp     quit

const:  call    undef
        call    expr
        test    (v.flgs), s.defin
        jne     1f
        push    bx
        call    error; '=
        pop     bx
1:      push    (v.flgs)
        pop     s.flags(bx)
        push    (v.data)
        pop     s.value(bx)
        ret

label:  call    undef
        or      s.flags(bx), s.defin
        test    (pc.flgs), s.firel
        je      1f
        or      s.flags(bx), s.firel
1:      push    (pc.data)
        pop     s.value(bx)
        ret

undef:  test    s.flags(bx), s.mutab
        jne     1f
        test    s.flags(bx), s.defin
        je      1f
        push    bx
        call    error; 'D
        pop     bx
1:      ret

dollar: call    expr            /* temporary */
        mov     ax, (v.data)
        call    ntrace
        test    (v.flgs), s.firel
        je      1f
        mov     si, 2f
        call    strace
1:      ret
2:      <+..\0>

a.len = 5
a.tab:  b 1,    a.symb-a.bgn
        b ';,   a.skip-a.bgn
        b '\d,  a.quit-a.bgn
        b '$,   a.doll-a.bgn
        b '<,   a.asci-a.bgn
