/*
 * assembler, first pass
 * as16 -- read/write argument
 */

.global arg1, arg2, mrm, putrm

arg2:   shl     (arg), 8
        shlb    (argsiz), 1
        call    lex
        cmp     ax, ',
        je      arg1
        call    error; ',
arg1:   movb    (arg), 0
        call    lex
        xor     dl, dl
        mov     cx, 1
        cmp     al, '(
        jne     2f
        jmp     mem
2:      cmp     al, 1
        jne     1f
        test    s.flags(bx), s.built
        jne     reg
1:      call    unlex
        call    expr
        call    lex
        inc     dl
        cmp     al, '(
        jne     2f
        jmp     mem
2:      call    unlex
        orb     (arg), a.imm
        ret

reg:    mov     cl, s.value(bx)
        mov     al, 1
        shl     al, cl
        test    al, ~3
        jne     1f
        mov     (arg), al
1:      cmp     s.flags(bx), sreg
        jne     1f
        mov     (nseg), cl
        orb     (arg), a.seg
        ret
1:      cmp     s.flags(bx), regb
        jne     1f
        mov     (nreg), cl
        orb     (arg), a.reg
        orb     (argsiz), 1
        ret
1:      cmp     s.flags(bx), regw
        je      1f
        call    error; 'r
1:      orb     (arg), a.reg
        mov     (nreg), cl
        ret

memend: call    lex
        cmp     al, ')
        jne     1f
        push    (v.flgs)
        pop     (x.flgs)
        push    (v.data)
        pop     (x.data)
        push    (v.symb)
        pop     (x.symb)
        test    dl, dl
        je      2f
        or      cx, 0200
2:      mov     ax, cx
        mov     cx, mlen
        mov     di, modes
        cld
3:      scas
        je      4f
        add     di, 2
        loop    3b
        call    error; 'M
4:      mov     ax, (di)
        push    (di)
        pop     (modrm)
        orb     (arg), a.mem
        ret
1:      cmp     al, ',
        je      mem
        call    error; ',
        call    unlex
/* dl = "had value?", cx=mode id */
mem:    call    lex
        cmp     al, 1
        jbe     1f
        call    error; 'm
        jmpb    mem
1:      test    al, al
        je      1f
        cmp     s.flags(bx), regw
        jne     1f
        shl     cx, 3
        or      cx, s.value(bx)
        jmp     memend
1:      call    unlex
        test    dl, dl
        je      1f
        call    error; 'd
1:      inc     dl
        call    expr
        jmp     memend

mrm:    test    (arg), a.reg
        je      1f
        push    (nreg)
        pop     (modrm)
        or      (modrm), 0300
1:      ret

putrm:  test    al, al
        js      1f
        shl     al, 3
        or      al, (modrm)
        call    putc
        and     al, 0307
        cmp     al, 6
        je      1f
        test    al, 0200
        je      2f
        test    al, 0100
        je      1f
2:      ret
1:      push    (v.flgs)
        push    (v.data)
        push    (v.symb)
1:      push    (x.flgs)
        push    (x.data)
        push    (x.symb)
        pop     (v.symb)
        pop     (v.data)
        pop     (v.flgs)
        push    (size)
        movb    (size), 1
        call    value
        pop     (size)
        pop     (v.symb)
        pop     (v.data)
        pop     (v.flgs)
        ret

modes:  0136;   0000            /* (bx,si) */
        0163;   0000            /* (si,bx) */
        0137;   0001            /* (bx,di) */
        0173;   0001            /* (di,bx) */
        0156;   0002            /* (bp,si) */
        0165;   0002            /* (si,bp) */
        0157;   0003            /* (bp,di) */
        0175;   0003            /* (di,bp) */
        0016;   0004            /* (si) */
        0017;   0005            /* (di) */
        0201;   0006            /* (disp) */
        0013;   0007            /* (bx) */
        0336;   0200            /* (bx,si,disp) */
        0363;   0200            /* (si,bx,disp) */
        0337;   0201            /* (bx,di,disp) */
        0373;   0201            /* (di,bx,disp) */
        0356;   0202            /* (bp,si,disp) */
        0365;   0202            /* (si,bp,disp) */
        0357;   0203            /* (bp,di,disp) */
        0375;   0203            /* (di,bp,disp) */
        0216;   0204            /* (si,disp) */
        0217;   0205            /* (di,disp) */
        0215;   0206            /* (bp,disp) */
        0213;   0207            /* (bx,disp) */
        0                       /* default mod r/m */
mlen = [.-modes-2]/4
