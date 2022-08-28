;
; B Runtime -- B Programming Language Interpreter
;
; b program structure: [ header, text, data, b-run ]
;   header [8 bytes]:
;       n byte          contains
;       0..1            90 e9
;       2..3            textsiz + datasiz + 4   ((!) in bytes)
;       4..5            textsiz + 8             ((!) in bytes)
;       6..7            address of main*
;   text: user-defined functions
;   data: user-defined data, data[0] must be pointer to main fuction
;   b-run: this file, but assembled (~500 bytes)
;
;       (*) main must be noreturn-function
;
; e.g. program
;       main(){}
; ( textsiz=1, datasiz=2 )
; represented as:       header                   text  data  b-run
;                       90 e9 08 00 0a 00 08 00  09 00 08 00  ...
;
; register usage:
;       si -- program counter, sp -- stack pointer,
;       bp -- base pointer, bx -- opcode table,
;       ax,cx,dx,di -- for general purpose
;

codeadj equ     4                                       ; offset of b-run is [codesiz]-next+codeadj

codesiz equ     2                                       ; textsiz+datasiz+4
databgn equ     4                                       ; textsiz+8
textbgn equ     6                                       ; &main

brun:   mov     si, [textbgn]                           ; si = main
        add     word [codesiz], next-init
        mov     bp, sp
next:   mov     bx, [codesiz]                           ; bx points to optable
        add     bx, optab-next+codeadj
        cld
        cmp     byte [bx-1], 0
        jz      ndebug
        call    debug
ndebug: lodsb
        test    al, 0x80                                ; high bit for debug
        jz      nsetd
        and     al, 0x7f
        not     byte [bx-1]                             ; debug
nsetd:  cmp     al, pop2
        jl      skip2
        pop     cx                                      ; pop arg #2
skip2:  cmp     al, pop1
        jl      skip1
        pop     dx                                      ; pop arg #1
skip1:  xlat
        xor     ah, ah
        add     ax, b-next+codeadj
        add     ax, [codesiz]                           ; bytecode to coroutine displacement
        xchg    ax, dx                                  ; ax=arg #1, cx=arg #2, dx=coroutine displacement
        cmp     ax, cx                                  ; set flags for eq/neq/leq/geq/les/ges
        jmp     dx

b:
bconst: lodsw
pushax: push    ax
bnop:   jmp     next
bauto:  lodsb
        cbw
        call    lval
        push    word [bp+di]
bpop:   jmp     bnop
bvauto: lodsb
        cbw
        shl     ax, 1
        add     ax, bp
        shr     ax, 1
        jmp     pushax
bxtrn:  lodsw
        call    lval
        add     di, [databgn]
        push    word [di]
        jmp     bnop
bvxtrn: lodsw
        mov     cx, [databgn]
        shr     cx, 1
        add     ax, cx
        jmp     pushax
bstore: lodsb                                           ; reserve space for ax local variables
        call    alval
        sub     sp, ax
        jmp     bnop
bjmp:   lodsw
        add     si, ax                                  ; new program counter (displacement)
        jmp     bnop
bret:   mov     sp, bp                                  ; erase all locals
        pop     bp                                      ; restore stack frame
        pop     si                                      ; restore program counter
        mov     cx, ax                                  ; save returned value
        lodsb
        inc     al
        call    alval
        add     sp, ax
        push    cx                                      ; copy returned value on current stack frame
        jmp     bnop
bstar:  call    lval
        mov     ax, di
        push    word [di]
        jmp     bnop
bvstar: jmp     pushax
bcall:  push    ax                                      ; push back
        push    si                                      ; save program counter
        call    getfn
        push    bp                                      ; save stack frame
        mov     bp, sp                                  ; new stack frame
        mov     si, ax                                  ; new program counter
        jmp     bnop
bjif:   mov     cx, ax                                  ; jump if false
        lodsw
        test    cx, cx
        jnz     bnop
        add     si, ax
        jmp     bnop
bnot:   not     ax
        jmp     pushax
blnot:  test    ax, ax
        jmp     beq
bneg:   neg     ax
        jmp     pushax
bincl:  call    lval
        inc     word [di]
pushdi: push    word [di]
        jmp     bnop
bincr:  call    lval
        push    word [di]
        inc     word [di]
        jmp     bnop
bdecl:  call    lval
        dec     word [di]
        jmp     pushdi
bdecr:  call    lval
        push    word [di]
        dec     word [di]
        jmp     bnop
bset:   call    lval
        mov     [di], cx
        jmp     pushdi
badd:   add     ax, cx
        jmp     pushax
bsub:   sub     ax, cx
        jmp     pushax
bshl:   shl     ax, cl
        jmp     pushax
bshr:   shr     ax, cl
        jmp     pushax
band:   and     ax, cx
        jmp     pushax
bor:    or      ax, cx
        jmp     pushax
bxor:   xor     ax, cx
        jmp     pushax
bmul:   mul     cx
        jmp     pushax
bdiv:   xor     dx, dx
        div     cx
        jmp     pushax
bmod:   xor     dx, dx
        div     cx
        push    dx
        jmp     bnop
beq:    sete    al
pushal: cbw
        jmp     pushax
bneq:   setne   al
        jmp     pushal
bleq:   setle   al
        jmp     pushal
bgeq:   setge   al
        jmp     pushal
bles:   setl    al
        jmp     pushal
bges:   setg    al
        jmp     pushal
bswt:   jmp     doswt
bnat:   mov     di, [codesiz]
        add     di, donat-next+codeadj                  ; set di=where to store native code
        mov     cx, natsiz
        mov     al, 0x90
.do1:   stosb                                           ; fill with nop
        loop    .do1
        sub     di, natsiz
        lodsb                                           ; command size
        mov     cl, al                                  ; ch=0 after .do1 => cx = command size
.do2:   lodsb                                           ; native command next byte
        stosb                                           ; copy
        loop    .do2
        jmp     donat

getfn:  lodsb
        mov     cl, al
        xor     ch, ch
        cbw
        shr     cx, 1                                   ; cx = nr args / 2
        call    alval                                   ; ax = nr args * 2
        add     ax, 4                                   ; skip sp, bp
        mov     si, sp
        mov     di, sp
        add     di, 4                                   ; di=ptr to last arg
        add     si, ax
        std
        lodsw                                           ; si=ptr to first arg, ax=ptr to fn
        cld
        test    cx, cx
        jz      .done                                   ; no swaps if no args
        push    ax
.swap:  mov     ax, [di]
        xchg    ax, [si]
        stosw                                           ; swap [si], [di]
        sub     si, 2
        loop    .swap                                   ; for each pair of args
        pop     ax
.done:  ret

alval:  xor     ah, ah
        shl     ax, 1
        ret

lval:   mov     di, ax
        shl     di, 1
        ret

natsiz  equ     24
donat:  resb    natsiz
        jmp     next

doswt:  xchg    ax, cx
        call    lval                                    ; switch table
        lodsw                                           ; get size
        xchg    ax, cx                                  ; ax=value, cx=size
.do:    scasw
        jz      .done
        scasw
        loop    .do
.done:  mov     si, [di]
        jmp     bnop


put8:   push    ax
        push    ax
        call    xput
        mov     ax, 0x0e20
        int     0x10
        pop     ax
        mov     ah, 0x0e
        int     0x10
        mov     ax, 0x0e0a
        int     0x10
        mov     ax, 0x0e0d
        int     0x10
        pop     ax
        ret

xput:   pusha
        mov     cx, 4
        call    puts
        db      "  ", 0
        jmp     xput2.xput
xput41: pusha
        mov     cx, 4
        call    puts
        db      " ", 0
        jmp     xput2.xput
xput2:  pusha
        mov     cx, 2
        call    puts
        db      " ", 0
.xput:  mov     bx, [codesiz]
        add     bx, hextab-next+codeadj
        call    .put
        popa
        ret
.put:   push    ax                                      ; auto t; t = ax;
        shr     ax, 4
        dec     cx
        test    cx, cx
        jz      .done                                   ; if (ax = ax >> 3) xput()
        call    .put
.done:  pop     ax
        and     al, 15
        xlat
        mov     ah, 0x0e                                ; putchar((t & 7) + '0')
        pusha
        int     0x10
        popa
        ret

puts:   pop     si
        push    ax
.put:   lodsb
        test    al, al
        jz      .done
        mov     ah, 0x0e
        int     0x10
        jmp     .put
.done:  pop     ax
        jmp     si

debug:  pusha
        push    si
        push    si
        call    puts
        db      13, 10, "  pc    sp    bp    opcode       stack", 13, 10, 0
        pop     ax
        call    xput
        mov     ax, sp
        add     ax, 20
        call    xput
        mov     ax, bp
        call    xput
        mov     ax, 0x0e20
        int     0x10

        pop     si
        xor     ah, ah
        mov     cx, 4
.ops:   lodsb
        call    xput2
        loop    .ops

        mov     ax, 0x0e20
        int     0x10
        mov     cx, 9
        mov     si, sp
        add     si, 18
.stk:   lodsw
        call    xput41
        loop    .stk
        
        call    puts
        db      10, 13, "  ax/bx/cx/dx/di/fl/ds/es:", 0
        popa
        pusha
        call    xput41
        mov     ax, bx
        call    xput41
        mov     ax, cx
        call    xput41
        mov     ax, dx
        call    xput41
        mov     ax, di
        call    xput41
        lahf
        mov     al, ah
        xor     ah, ah
        call    xput41
        mov     ax, ds
        call    xput41
        mov     ax, es
        call    xput41
        call    puts
        db      13, 10, 0

        xor     ah, ah
        ;int     0x16
        popa
        ret

hextab: db      "0123456789abcdef"

        db      0                                       ; -1=debug, 0=ndebug
optab:  db      bnop    - b
        db      bnat    - b
        db      bconst  - b
        db      bauto   - b
        db      bvauto  - b
        db      bxtrn   - b
        db      bvxtrn  - b
        db      bstore  - b
        db      bjmp    - b
pop1    equ     $       - optab
        db      bret    - b
        db      bstar   - b
        db      bvstar  - b
        db      bcall   - b
        db      bjif    - b
        db      bpop    - b
        db      bnot    - b
        db      blnot   - b
        db      bneg    - b
        db      bincl   - b
        db      bincr   - b
        db      bdecl   - b
        db      bdecr   - b
pop2    equ     $       - optab
        db      bset    - b
        db      badd    - b
        db      bsub    - b
        db      bshl    - b
        db      bshr    - b
        db      band    - b
        db      bor     - b
        db      bxor    - b
        db      bmul    - b
        db      bdiv    - b
        db      bmod    - b
        db      beq     - b
        db      bneq    - b
        db      bleq    - b
        db      bgeq    - b
        db      bles    - b
        db      bges    - b
        db      bswt    - b
