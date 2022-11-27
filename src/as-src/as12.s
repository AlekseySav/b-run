/*
 * assembler, first pass
 * as12 -- hash table + reloc table
 */

.global lookup, value, putsym

n: 31; k: symsize               /* we will 'mul' by them */

lookup: push    ax
        push    cx
        push    dx
        push    di
        push    si
        xor     ax, ax
        xor     ch, ch
        mov     bx, si
hash:   mov     cl, (si)++
        test    cl, cl
        jz      1f
        sub     cl, '.-1
        mul     (n)             /* mul prime */
        and     ax, hshmsk
        mov     ax, dx
        add     ax, cx
        jmpb    hash
1:      mul     (k)             /* ax=hash */
        mov     dx, bx          /* dx=name */
        mov     bx, ax
        add     bx, hshtab      /* bx=entry */
        cld
find:   mov     si, dx
        mov     di, (bx)++
        sub     bx, hshtab
        and     bx, hshmsk
        add     bx, hshtab
        test    di, di
        jz      new
1:      lodsb
        scasb
        jne     find
        test    al, al
        jne     1b
        sub     bx, 2           /* (bx) is entry */
        jmpb    end
new:    mov     ax, (nsyms)
        push    dx
        mul     (k)
        pop     dx
        mov     di, ax
        inc     (nsyms)
        add     di, symtab      /* di=new sym entry */
        mov     --(bx), di
        mov     si, dx
        cld
1:      lodsb
        stosb
        test    al, al
        jnz     1b
end:    mov     bx, (bx)        /* bx points to entry */
        pop     si
        pop     di
        pop     dx
        pop     cx
        pop     ax
        ret

value:  push    dx
        push    cx
        push    ax
        mov     cl, (pcrel)
        test    cl, cl
        jne     rel
        test    (v.flgs), s.defin
        je      rel
        test    (v.flgs), s.firel
        jne     rel
        mov     ax, (v.data)
put:    call    putc
        testb   (size), 1
        je      1f
        mov     al, ah
        call    putc
1:      pop     ax
        pop     cx
        pop     dx
        ret
rel:    push    bx
        /* todo(?): make temp symbol if no symbol or symbol is mutable */
        mov     ax, (v.symb)
        sub     ax, usyms
        push    dx
        xor     dx, dx
        div     (k)
        pop     dx
        mov     (r.flgs), ax
        test    cl, cl
        je      1f
        or      (r.flgs), r.pcrel
1:      testb   (size), 1
        je      1f
        or      (r.flgs), r.size
1:      mov     ax, (pc.data)
        add     ax, (pc.adj)
        mov     (r.addr), ax
        mov     bx, (relfd)
        write   reloc, relsize
        inc     (e.rels)
        pop     bx
        xor     ax, ax
        jmpb    put

putsym: mov     si, usyms
        mov     cx, (nsyms)
        sub     cx, bsyms
        test    cx, cx
        je      2f
1:      push    cx
        mov     bx, di
        mov     cx, si
        mov     dx, symsize
        add     si, dx
        write
        pop     cx
        loop    1b
        mov     bx, di
2:      ret
