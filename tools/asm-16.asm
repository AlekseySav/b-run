*
* asm-16.asm -- contains assembler instructions for each opcode/operator
*   special characters:
*        * -- at the begining of the line starts a line comment
*       || -- is replaced with '\n'
*        $ -- is replaced with 'l' or 'x' (depending on size)
*        & -- is replaced with 'byte' or 'word' (depending on size)
*        # -- is replaced with '1' or '2' (depending on size)
*        % -- is replaced with 'cbw' or '' (depending on size)
*        @ -- is replaced with optional argument
*   first line contains startup code
*
call [_main] || xor ax, ax || int 0x20 || return: mov sp, bp || pop bp || ret       ; startup code
L_symbol -- "unused"
L_number -- "unused"
L_string -- "unused"
L_open_bracket -- "unused"
L_close_bracket -- "unused"
L_open_paran -- "unused"
L_close_paran -- "unused"
mov bx, ax || mov a$, [bx] || add &[bx], @ %                                        ; b++
mov bx, ax || mov a$, [bx] || sub &[bx], @ %                                        ; b--
call ax || add sp, @                                                                ; a(...)
mov bx, # || mul bx || pop bx || add bx, ax || mov a$, [bx] %                       ; b[a]
mov bx, ax || mov a$, [bx+@] %                                                      ; b.a
mov bx, ax || mov bx, [bx] || mov a$, [bx+@] %                                      ; b->a
mov bx, ax || add &[bx], @ || mov a$, [bx] %                                        ; ++b
mov bx, ax || sub &[bx], @ || mov a$, [bx] %                                        ; --b
; lalala                                                                            ; +a
neg ax                                                                              ; -a
test ax, ax || sete al || cbw                                                       ; !a
not ax                                                                              ; ~a
L_cast -- "unused"
mov bx, ax || mov a$, [bx] %                                                        ; *a
L_addr -- "unused"
pop bx || imul bx                                                                   ; b*a
pop bx || xor dx, dx || xchg ax, bx || idiv bx                                      ; b/a
pop bx || xor dx, dx || xchg ax, bx || idiv bx || mov ax, dx                        ; b%a
pop bx || add ax, bx                                                                ; b+a
pop bx || xchg ax, bx || sub ax, bx                                                 ; b-a
pop cx || xchg ax, cx || shl ax, cl                                                 ; b<<a
pop cx || xchg ax, cx || shr ax, cl                                                 ; b>>a
pop bx || and ax, bx                                                                ; b&a
pop bx || xor ax, bx                                                                ; b&a
pop bx || or  ax, bx                                                                ; b&a
pop bx || cmp bx, ax || setl  al || cbw                                             ; b<a
pop bx || cmp bx, ax || setle al || cbw                                             ; b<=a
pop bx || cmp bx, ax || setg  al || cbw                                             ; b>a
pop bx || cmp bx, ax || setge al || cbw                                             ; b>=a
pop bx || cmp bx, ax || sete  al || cbw                                             ; b==a
pop bx || cmp bx, ax || setne al || cbw                                             ; b!=a
L_andl -- "not implemented"
L_orl -- "not implemented"
L_question -- "not implemented"
L_colon -- "not implemented"
pop bx || mov [bx], a$                                                              ; b=a
pop bx || imul &[bx] || mov [bx], a$                                                ; b*=a
pop bx || xor dx, dx || xchg ax, [bx] || idiv &[bx] || mov [bx], a$                 ; b/=a
pop bx || xor dx, dx || xchg ax, [bx] || idiv &[bx] || mov a$, d$ || mov [bx], a$   ; b%=a
pop bx || add a$, [bx] || mov [bx], a$                                              ; b+=a
pop bx || sub [bx], a$ || mov a$, [bx] %                                            ; b-=a
pop bx || mov cx, ax || shl [bx], cl || mov a$, [bx]                                ; b<<=a
pop bx || mov cx, ax || shr [bx], cl || mov a$, [bx]                                ; b>>=a
pop bx || and a$, [bx] || mov [bx], a$                                              ; b&=a
pop bx || xor a$, [bx] || mov [bx], a$                                              ; b^=a
pop bx || or  a$, [bx] || mov [bx], a$                                              ; b|=a
add sp, 2                                                                           ; b,a
L_n_operators -- "unused"
L_open_curly -- "unused"
L_close_curly -- "unused"
L_semicolon -- "unused"
L_empty_expr -- "unused"
mov a$, [bp+@] %                                                                    ; local
lea ax, [bp+@]                                                                      ; &local
mov a$, [_@] %                                                                      ; global
mov ax, _@                                                                          ; &global
mov ax, @                                                                           ; const
mov ax, S@                                                                          ; string
mov bx, # || mul bx || pop bx || add ax, bx                                         ; &b[a]
push ax                                                                             ; push
push bp || mov bp, sp                                                               ; enter
jmp return                                                                          ; return
sub sp, @                                                                           ; adjust stack
jmp L@                                                                              ; jump
test ax, ax || jz L@                                                                ; conditional jump
dw L@                                                                               ; label
S@: db \
