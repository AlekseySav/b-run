jmp start
jmpb end
je end
mov ax, end
mov bx, value
mov bx, 1
write buf, len
buf: <hello\0>
len = .-buf
value = 2772
start:
0xffff
end:

add ax, (0)
adc (0), cx
or dx, cx
cmp ax, 0xff00
cmp al, 0xff
cmpb al, 0xff
add cx, 0xff00

shl (bx), 2
shr ax, 3
sarb al, cl
sar al, cl

test ax, 9
test al, 9
test bx, 9
test (bx,si,0x999), 9
test bx, cx
test bx, (di)

inc ax
inc cx
inc dx
inc bx
inc sp
inc bp
inc si
inc di

dec ax
dec cx
dec dx
dec bx
dec sp
dec bp
dec si
dec di

push ax
push bx
push cx
push dx
pop ax
pop bx
pop cx
pop dx
push cs
push ds
push es
push ss
push fs
push gs
pop cs
pop ds
pop es
pop ss
pop fs
pop gs
push 0x255
pushb 15
push (bx)
pop (bx)

lea ax, 0x300(bx)
lds ax, (0x800)
les cx, (0x800)

ret
retf
ret 15
retf 15

in 18
inb 18
in
out
outb
out 182

5; 6; 7; b 5, 6, 7
seg cs
seg gs

write
open 1
exit 1, 2

mov ax, 1
mov bx, ax
mov al, 1
mov (bx), cx
mov ax, (0x700)
mov (di,0x100), cx
mov (di), 15
movb al, 0xff
mov al, -1

xchg ax, bx
xchg bx, ax
xchg bl, al
xchg al, bl
xchg cx, dx
xchg cx, (bx)
xchg (bx), cx
