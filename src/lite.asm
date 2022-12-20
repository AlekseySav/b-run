;
; low level code for lite
;

init:   mov     ax, cs
        mov     di, [databgn]
        stosw                                           ; KERNSEG
        mov     ax, [codesiz]
        add     ax, deqkey-init+codeadj
        stosw
        add     ax, rwblk-deqkey
        stosw
        mov     ax, [codesiz]
        mov     bx, ax
        mov     cx, ax
        add     bx, docz-init+codeadj
        add     cx, sdone-init+codeadj
        mov     [bx], cx                                ; for docall util
        push    ds
        push    0
        pop     ds
        add     ax, sys-init+codeadj
        mov     [0x20*4], ax                            ; set system call
        mov     [0x20*4+2], cs
        add     ax, bsys-sys
        mov     [0x21*4], ax                            ; set system call
        mov     [0x21*4+2], cs
        add     ax, kbint-bsys                          ; keyboard int
        mov     [0x09*4], ax
        mov     [0x09*4+2], cs
        pop     ds
        jmp     brun

%include "tools/b-run.asm"

;
; disk i/o
; input:        bx=block, dx=mode, di:0=buffer
;
rwblk:  push    si
        push    bp
        push    es
        push    ds
        shl     bx, 1
        mov     es, di
        mov     ds, di
        xor     di, di
        xor     si, si
        push    dx
        push    dx
        mov     dx, 0x1f6
        mov     al, 11100000b        
        out     dx, al                                  ; bits 24-27 + use LBA
        mov     dx, 0x1f2
        mov     al, 2
        out     dx, al                                  ; 2 sectors = 1KiB
        inc     dx
        mov     al, bl
        out     dx, al                                  ; bits 0-7
        inc     dx
        mov     al, bh
        out     dx, al                                  ; bits 8-15
        inc     dx
        xor     al, al
        out     dx, al                                  ; bits 16-23
        pop     dx
        shl     dl, 4
        mov     al, 0x20
        or      al, dl                                  ; 0x20 for read, 0x30 for write
        mov     dx, 0x1f7
        out     dx, al
        mov     bx, 2                                   ; 2 sectors = 1 KiB
        pop     bp
.sleep: mov     dx, 0x1f7
        in      al, dx
        test    al, 8
        jz      .sleep
        mov     cx, 256
        mov     dx, 0x1f0
        cld
        test    bp, bp
        jnz     .write
        rep insw
        jmp     .cont
.write: outsw
        loop    .write
.cont:  dec     bx
        test    bx, bx
        jnz     .sleep
        pop     ds
        pop     es
        pop     bp
        pop     si
        ret

bsys:   int     0x20
        pop     dx
        pop     cx
        pop     bx
        push    ax
        push    bx
        push    cx
        push    dx
        iret

sys:    push    ds
        push    es
        pusha
        cli
        mov     bp, ss
        mov     di, sp
        mov     si, cs
        push    cs
        pop     ss                                      ; get kernel ss
        cmp     bp, si
        jz      .nosp
        mov     sp, [-2]                                ; get kernel sp
.nosp:  sti
        push    bp                                      ; save old ss
        push    di                                      ; save old sp
        mov     bp, sp
        push    0                                       ; b function ptr
        push    bx                                      ; push args
        push    cx
        push    dx
        push    ds
        mov     cx, cs
        mov     ds, cx
        mov     es, cx
        mov     bx, [databgn]
        add     bx, 6                                   ; syscall table
        xor     ah, ah
        shl     ax, 1
        add     bx, ax                                  ; systab[ax]
        mov     bx, [bx]
        mov     [bp-2], bx
        mov     si, [codesiz]
        add     si, docall-next+codeadj                 ; docall
        jmp     next
sdone:  pop     ax
        cli
        pop     di                                      ; get old sp
        pop     ss                                      ; get old ss
        mov     sp, di
        sti
        mov     [ss:di+14], ax
        popa
        pop     es
        pop     ds
        iret

docall: db      12, 4, 2
docz:   dw      0
        db      1, 1
        ret

kbint:  push    ds
        push    es
        pusha
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        in      al, 0x60
        call    addr
        dw      shift
        test    byte [bx], 1
        jnz     .sh
        call    addr
        dw      klmap
        jmp     .proc
.sh:    call    addr
        dw      kumap
.proc:  mov     cl, al
        and     al, 0x7f
        xlat
        test    al, 0x80                                ; shift ?
        jz      .raw
        call    addr
        dw      shift
        test    cl, 0x80                                ; pressed/released ?
        jnz     .rel
        or      [bx], al
        jmp     .done
.rel:   not     al
        and     [bx], al
        jmp     .done
.raw:   test    cl, 0x80
        jnz     .done
        call    addr
        dw      shift
        test    byte [bx], 2                            ; ctrl ?
        jz      .enq
        and     al, ~0x20
        sub     al, '@'
.enq:   call    enqkey
.done:  mov     al, 0x20
        out     0x20, al
        popa
        pop     es
        pop     ds
        iret

bufelm: inc     byte [bx]
        and     byte [bx], 127
        mov     bl, [bx]
        cbw
        mov     di, bx
        call    addr
        dw      buf
        add     di, bx
        ret

enqkey: call    addr
        dw      keyend
        call    bufelm
        stosb
        ret

deqkey: cli
        call    addr
        dw      keyend
        mov     ax, [bx]
        call    addr
        dw      keybgn
        cmp     al, [bx]
        sti
        jz      deqkey
        call    bufelm
        mov     al, [di]
        ret

addr:   pop     bx
        add     bx, 2
        push    bx
        mov     bx, [bx-2]
        add     bx, [codesiz]
        add     bx, codeadj-next
        ret

keybgn: db      128
keyend: db      128
buf:    resb    128
shift:  db      0                                       ; 1: shift pressed, 2: ctrl pressed

klmap:  db      0, 27, "1234567890-=", 8, 9
        db      "qwertyuiop[]", 10, 0x82                ; 0x82 = ctrl
        db      "asdfghjkl;'`", 0x81                    ; 0x81 = left shift
        db      "\zxcvbnm,./", 0x81                     ; 0x81 = right shift
        db      "*", 0x83, " ", 0x84                    ; 0x83 = alt, 0x84 = caps
        db      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     ; F1-F10, numlock, scrolllock
        db      0, 18, 0, "-", 16, 0, 17, "+", 0, 19, 0, 0   ; numpad
        db      0x7f                                    ; delete
        db      0, 0, 0, 0, 0                           ; ---, F11, F12
kumap:  db      0, 27, "!@#$%^&*()_+", 8, 9
        db      "QWERTYUIOP{}", 10, 0x82                ; 0x82 = ctrl
        db      "ASDFGHJKL:", '"', "~", 0x81            ; 0x81 = left shift
        db      "|ZXCVBNM<>?", 0x81                     ; 0x81 = right shift
        db      "*", 0x83, " ", 0x84                    ; 0x83 = alt, 0x84 = caps
        db      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,     ; F1-F10, numlock, scrolllock
        db      "789-456+1230"                          ; numpad
        db      0x7f                                    ; delete
        db      0, 0, 0, 0, 0                           ; ---, F11, F12
