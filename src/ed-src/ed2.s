/*
 * ed2 -- line allocator
 */

.global insline, delline

insline:
        cmp     (n_lines), LINES
        je      0f
        inc     (n_lines)
        pusha
        mov     di, -16
        mov     si, poolmap
1:      lods
        not     ax
        add     di, 16
        b 0x0f, 0xbc, 0xc8                      /* bsf cx, ax */
        je      1b
        sub     si, 2
        mov     ax, 1
        shl     ax, cl
        or      (si), ax                        /* mark line used */
        add     di, cx                          /* di=line number */
        mov     ax, di
        xor     dx, dx
        mul     (1f)
        add     ax, pool                        /* ax=line buffer */
        inc     (y)
        mov     si, (y)
        shl     si, 1
        add     si, lines
        mov     cx, e_lines
        sub     cx, si
        mov     di, 2
        call    memadj                          /* move lines */
        mov     (si), ax
        mov     si, ax
        movb    (si), '\n
        popa
0:      ret
1:      81

delline:
        cmp     (n_lines), 0
        je      0f
        pusha
        mov     si, (y)
        shl     si, 1
        mov     cx, lines(si)                   /* t = lines[y] */
        mov     di, cx
        shr     di, 4
        mov     ax, 1
        and     cx, 15
        shl     ax, cl
        not     ax
        and     poolmap(di), ax                 /* poolmap[t/16] &= (1<<(t%16)) */
        dec     (n_lines)
        add     si, lines
        add     si, 2
        mov     cx, e_lines
        sub     cx, si
        mov     di, -2
        call    memadj                          /* move lines */
        mov     si, (n_lines)
        mov     lines(si), 0
        popa
0:      ret
