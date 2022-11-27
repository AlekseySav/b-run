/*
 * assembler, second pass
 * as21 -- main stuff here
 */

/*
 * note: as2 yet unable to link multiple files
 */

        mov     bx, outnm
        open    0
        mov     bx, ax
        push    bx
        read    header, 32000
        pop     bx
        close
        mov     si, text
        add     si, (e.text)
        mov     (o.syms), si    /* symtab offset */
        mov     ax, (e.syms)
        mul     (n)
        add     si, ax
        mov     (o.rels), si    /* reloc offset */
        mov     cx, (e.rels)
        test    cx, cx
        je      end
rels:   lods
        push    ax
        mov     dx, ax
        and     ax, r.symb
        mul     (n)
        add     ax, (o.syms)
        mov     bx, ax          /* bx=symbol */
        lods
        mov     di, ax
        add     di, text        /* di=addr */
        pop     dx              /* dx=flags */
        test    s.flgs(bx), s.defin
        jne     1f
        call    err.u
1:      mov     ax, s.value(bx)
        test    dx, r.pcrel
        je      1f
        add     ax, text
        sub     ax, di
        dec     ax
        test    dx, r.size
        je      1f
        dec     ax
1:      test    dx, r.size
        je      2f
        stos
        jmpb    3f
2:      stosb
3:      loop    rels
end:    mov     bx, 1
        mov     cx, text
        mov     dx, (e.text)
        write
        exit


n:      symsize

outnm:  <astmpO\0>
