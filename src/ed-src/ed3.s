/*
 * ed3 -- editor
 */

.global run

run:
        call    getchar
        mov     bx, ax
        shl     bx, 1
        push    1f
        jmp     ctab(bx)                        /* avoid (call r/m) bug */
1:      mov     ax, (y)
        cmp     ax, (n_lines)
        jb      4f
        mov     ax, (n_lines)
        dec     ax
        mov     (y), ax
4:      mov     bx, (top)
        cmp     ax, bx
        jae     2f
        mov     (top), ax
2:      add     bx, 23
        cmp     ax, bx
        jb      3f
        sub     ax, 23
        mov     (top), ax
3:      call    render
        ret

cursor:
        mov     si, (y)
        shl     si, 1
        mov     si, lines(si)
        add     si, (x)
        ret

put:    call    cursor
        cmpb    (x), 79
        jge     unk
        mov     di, 1
        mov     cx, 79
        sub     cx, (x)
        call    memadj
        mov     (si), al
        inc     (x)
unk:    ret

bs:     cmpb    (x), 0
        je      1f
        dec     (x)
        call    cursor
        cmpb    (si), 0
        je      bs
del:
1:      call    cursor
        cmpb    (si), '\n
        je      0f
        mov     di, si
        inc     si
        mov     cx, 80
        sub     cx, (x)
        call    memmove
0:      ret

ht:     cmpb    (x), 72
        jge     0f
        call    cursor
        mov     ax, (x)
        add     al, 8
        and     al, 0xf8                        /* al=new x */
        mov     di, ax
        sub     di, (x)
        mov     (x), ax
        mov     cx, 72
        sub     cx, (x)
        call    memadj
        mov     (si), '\t
        mov     cx, di
        dec     cx
        mov     di, 1
        jcxz    0f
1:      inc     si
        movb    (si), 0
        loop    1b
0:      ret

nl:     call    insline
        movb    (x), 0
        ret

c1:     cmpb    (x), 0
        je      0f
        dec     (x)
c11:    call    cursor
        cmpb    (si), 0
        je      c1
0:      ret

c2:     cmpb    (x), 79
        je      0b
        inc     (x)
c21:    call    cursor
        cmpb    (si), 0
        je      c2
0:      ret

c3:     cmp     (y), 0
        je      0b
        dec     (y)
        jmp     c11

c4:     cmp     (y), LINES
        je      0b
        inc     (y)
        jmp     c11

esc:    jmp     command

ctab:
        unk; unk; unk; unk; unk; unk; unk; unk
        bs;  ht;  nl;  unk; unk; unk; unk; unk
        c1;  c2;  c3;  c4;  unk; unk; unk; unk
        unk; unk; unk; esc; unk; unk; unk; unk
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; put
        put; put; put; put; put; put; put; del
