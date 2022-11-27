/*
 * assembler, second pass
 * as22 -- error i/o
 */

.global print, err.u

ten: 10
printn: xor     dx, dx
        div     (ten)
        push    dx
        test    ax, ax
        je      1f
        call    printn
1:      pop     ax
        add     al, '0
        stosb
        ret

print:  pop     si
        mov     di, errbuf
        cld
        call    1f
        mov     bx, 2
        mov     cx, errbuf
        mov     dx, di
        sub     dx, errbuf
        write
        jmp     si
1:      lodsb
        test    al, al
        je      3f
        cmp     al, '%
        jne     4f
        mov     ax, dx
        call    printn
        jmpb    1b
4:      cmp     al, '$
        jne     2f
        push    si
        mov     si, bx
        call    1b
        pop     si
        jmpb    1b
2:      stosb
        jmpb    1b
3:      ret


err.u:  pusha
        mov     dx, di
        sub     dx, text
        call    print; <text+%: undefined reference to '$'\n\0>
error:  popa
        ret
