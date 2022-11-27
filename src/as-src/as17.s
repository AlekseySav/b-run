/*
 * assembler, first pass
 * as17 -- opcodes
 */

.global opcode

n: 0

siz0:   movb    (size), 0
        sub     bx, symsize
opcode: mov     ax, s.value(bx)
        mov     (n), ax
        mov     di, s.flags(bx)
        shl     di, 1
        jmp     optab(di)

.proc   setsiz:
        mov     ax, (bx)++
        testb   (argsiz), al
        je      1f
        movb    (size), 0
1:      rts

.proc   sw:
        mov     si, (bx)++
        mov     cx, (bx)++
        mov     dx, (arg)
        cld
1:      lods
        test    al, dl
        je      3f
        test    ah, dh
        jne     2f
3:      add     si, 2
        loop    1b
        jmp     bad             /* return from opcode, not from sw */
2:      lods
        rts

bad:    call    error; 'o
        ret

ifp:    call    cexpr
        test    ax, ax
        jne     endif
else:   call    lex
        cmp     al, 1
        jne     else
        cmp     bx, enifsym
        je      endif
        cmp     bx, elsesym
        jne     else
endif:  ret

/* opcodes */

put0:   call    expr
        movb    (size), 0
        call    value
        call    lex
        cmp     ax, ',
        je      put0
endl:   cmp     al, ';
        je      1f
        call    error; ';
1:      ret

seg0:   call    lex
        cmp     s.flags(bx), sreg
        je      1f
        call    error; 'o
        ret
1:      mov     al, s.value(bx)
        cmp     al, 4
        jge     1f
        shl     al, 3
        add     al, 0x26
        jmp     putc
1:      add     al, 0x64-4
        jmp     putc

/* add or cmp etc. */
mth0:   call    arg1
        call    mrm
        call    arg2
        call    setsiz; 3
        call    sw; t.mth0; 4
        push    ax
        or      al, (size)
        test    al, al
        js      1f              /* al=0x80 => rm, im */
        shlb    (n), 3
        or      al, (n)
        call    putc
        pop     ax
        cmp     al, 4           /* ax, im */
        jne     2f
        jmp     value
2:      mov     al, (nreg)
        jmp     putrm
1:      add     sp, 2
        call    putc
        mov     al, (n)
        call    putrm
        jmp     value

/* rol ror shl etc. */
mth1:   call    arg1
        call    mrm
        call    arg2
        call    setsiz; 2
        call    sw; t.mth1; 2
        xor     dl, dl          /* put value? */
        cmp     al, 0xd0
        jne     1f
        cmp     (v.data), 1
        je      1f
        mov     al, 0xc0
        inc     dl
1:      or      al, (size)
        call    putc
        mov     al, (n)
        call    putrm
        test    dl, dl
        je      1f
        movb    (size), 0
        jmp     value
1:      ret

/* inc dec */
mth2:   call    arg1
        call    mrm
        call    setsiz; 1
        mov     al, (arg)
        test    al, a.reg
        je      1f
        test    (size), 1
        je      1f
        mov     al, (n)
        shl     al, 3
        or      al, (nreg)
        or      al, 0x40
        jmp     putc            /* rw */
1:      test    al, a.mrm
        jne     1f
b1:     jmp     bad
1:      mov     al, 0xfe
        or      al, (size)
        call    putc
        mov     al, (n)
        jmp     putrm

/* mul div etc. */
mth3:   call    arg1
        call    mrm
        test    (arg), a.mrm
        je      b1
        mov     al, 0xf6
        or      al, (size)
        call    putc
        mov     al, (n)
        jmp     putrm

/* test */
mth4:   call    arg1
        call    mrm
        call    arg2
        call    setsiz; 3
        call    sw; t.mth4; 4
        mov     bx, ax
        mov     al, mth4.l(bx)
        or      al, (size)
        call    putc
        mov     bl, mth4.o(bx)
        xor     bh, bh
        add     bx, mth4
        jmp     bx
mth4.1: mov     al, (n)
        call    putrm
mth4.0: jmp     value
mth4.2: mov     al, (nreg)
        jmp     putrm

/* push pop */
stk0:   sub     (1f), ax
        mov     (arg), 0
        call    arg1
        call    mrm
        movb    (argx), 0xff
        call    setsiz; 1
        call    sw; t.stk; 1: 4
        jmp     ax
2:      call    error; 's
        ret
stk0.0: testb   (size), 1
        je      2b
        mov     al, (n)
        shl     al, 3
        or      al, 0x50
        or      al, (nreg)
        jmp     putc
stk0.1: mov     al, (nseg)
        cmp     al, 4
        jge     1f
        shl     al, 3
        or      al, (n)
        or      al, 0x06
        jmp     putc
1:      sub     al, 4
        shl     al, 3
        or      al, (n)
        or      al, 0xa0
        mov     ah, 0x0f
        xchg    al, ah
        jmp     putw
stk0.2: test    (n), 1
        je      1f
        mov     al, 0x8f
        call    putc
        xor     al, al
        jmp     putrm
1:      mov     al, 0xff
        call    putc
        mov     al, 6
        jmp     putrm
stk0.3: mov     al, 0x6a
        sub     al, (size)
        sub     al, (size)
        call    putc
        jmp     value

/* lea les lds */
adr0:   call    arg1
        call    arg2
        call    sw; t.adr0; 1
1:      mov     al, (n)
        call    putc
        mov     al, (nreg)
        jmp     putrm

/* conditionals */
jmp0:   call    arg1
        testb   (arg), a.imm
        jne     1f
jbad:   call    error; 'o
        ret
1:      mov     al, (n)
        call    putc
        incb    (pcrel)
        movb    (size), 0
        jmp     value

/* jmp call */
jmp1:   call    arg1
        testb   (arg), a.imm
        jne     1f
        testb   (arg), a.mrm
        je      jbad
        mov     al, 0xff
        call    putc
        mov     al, (n)
        jmp     putrm
1:      test    (size), 1
        jne     1f
        mov     al, 0xeb
        jmpb    2f
1:      mov     al, (n)
        shr     al, 2
        or      al, 0xe8
2:      call    putc
        incb    (pcrel)
        jmp     value

/* ljmp lcall */
jmp2:   call    arg1
        push    (v.flgs)
        push    (v.data)
        push    (v.symb)
        call    arg2
        cmp     (arg), 0x8080
        je      1f
        add     sp, 6
        jmpb    jbad
1:      mov     al, (n)
        call    putc
        call    value
        pop     (v.symb)
        pop     (v.data)
        pop     (v.flgs)
        jmp     value

/* ret retf */
ret0:   call    lex
        cmp     al, ';
        jne     1f
        mov     al, (n)
        or      al, 1
        jmp     putc
1:      call    unlex
        call    expr
        mov     al, (n)
        call    putc
        jmp     value

/* in out */
sio0:   call    lex
        cmp     al, ';
        jne     1f
        mov     al, 0xec
        or      al, (size)
        or      al, (n)
        jmp     putc
1:      call    unlex
        call    expr
        mov     al, 0xe4
        or      al, (size)
        or      al, (n)
        call    putc
        jmp     value

/* mov */
mov0:   call    arg1
        call    mrm
        call    arg2
        call    setsiz; 3
        call    sw; t.mov0; 6
        mov     bx, ax
        mov     al, mov0.l(bx)
        mov     bl, mov0.o(bx)
        add     bx, mov0
        jmp     bx
mov1:   mov     bl, (size)
        shl     bl, 3
        or      al, bl
        or      al, (nreg)
        call    putc
        jmp     value
mov2:   call    putc
        mov     al, (nseg)
        jmp     putrm
mov4:   testb   (nreg), 7
        jne     1f
        cmpb    (modrm), 6
        jne     1f
        or      al, 0xa0
        or      al, (size)
        call    putc
        mov     al, -1
        jmp     putrm
1:      neg     al
        add     al, 0x8a
        or      al, (size)
        call    putc
        mov     al, (nreg)
        jmp     putrm
mov6:   or      al, (size)
        call    putc
        xor     al, al
        call    putrm
        jmp     value

/* xchg */
xcg0:   call    arg1
        call    mrm
        call    arg2
        call    setsiz; 3
        call    sw; t.xcg0; 4
        jmp     ax
xcg1:   test    (size), 1
        je      xcg2
        mov     al, 0x90
        or      al, (nreg)
        jmp     putc
xcg2:   mov     al, (size)
        or      al, 0x86
        call    putc
        mov     al, (nreg)
        jmp     putrm

/* system calls */
sys0:   mov     al, 0xb8
        call    putc
        mov     ax, (n)
        call    putw
        mov     dl, 0xb9
1:      call    lex
        cmp     al, ';
        je      3f
        cmp     al, ',
        je      1b
        call    unlex
        call    expr
        mov     al, dl
        inc     dl
        call    putc
        call    value
        jmpb    1b
3:      mov     ax, 0x20cd
        jmp     putw

t.mth0: 0x5010; 0               /* rm, rr */
        0x1050; 2               /* rr, rm */
        0x0180; 4               /* ax, im */
        0x5080; 0x80            /* rm, im */

t.mth1: 0x5080; 0xd0            /* rm, im */
        0x5002; 0xd2            /* rm, cl */

t.mth4: 0x0180; 0               /* ax, im */
        0x5080; 1               /* rm, im */
        0x5010; 2               /* rm, rr */
        0x1050; 2               /* rr, rm */
mth4.l: b 0xa8, 0xf6, 0x84
mth4.o: b mth4.0-mth4, mth4.1-mth4, mth4.2-mth4, mth4.2-mth4

t.stk:  0xff10;   stk0.0        /* rr */
        0xff20;   stk0.1        /* seg */
        0xff50;   stk0.2        /* rm */
        0xff80;   stk0.3        /* imm -- for push only */

t.adr0: 0x1040; 0               /* rr mm */

t.mov0: 0x1080; 0               /* rr im */
        0x1020; 1               /* rr sr */
        0x2010; 2               /* sr rr */
        0x5010; 3               /* rm rr */
        0x1050; 4               /* rr rm */
        0x5080; 5               /* rm im */
mov0.l: b 0xb0, 0x8c, 0x8e, 2, 0, 0xc6
mov0.o: b mov1-mov0, mov2-mov0, mov2-mov0, mov4-mov0, mov4-mov0, mov6-mov0

t.xcg0: 0x0110; xcg1            /* ax rr */
        0x1001; xcg1
        0x1050; xcg2            /* rr rm */
        0x5010; xcg2

optab:  0
        ifp
        else
        endif
        bad
        bad
        bad
        siz0
        putc
        put0
        seg0
        mth0
        mth1
        mth2
        mth3
        mth4
        stk0
        adr0
        jmp0
        jmp1
        jmp2
        ret0
        sio0
        mov0
        xcg0
        sys0
