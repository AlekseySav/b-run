/*
 * assembler, first pass
 * as19 -- data, bss & debug stuff
 */

debug = 1

$g  /* make all implicitly global */

.if debug
ntrace: pusha
        mov     (line), ax
        call    error; '\s
        popa
        ret
strace: pusha
        mov     di, errbuf
        cld
1:      lodsb
        stosb
        test    al, al
        jnz     1b
        dec     si
        mov     al, '\n
        stosb
        mov     bx, 2
        mov     dx, di
        sub     dx, errbuf
        write   errbuf
        popa
        ret
psyms:  pusha
        mov     cx, (nsyms)
        mov     si, symtab
1:      call    strace
        add     si, symsize
        loop    1b
        popa
        ret
.endif

line: 1
tok: -1

ctab:
b 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0
b 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b 2, 3, 0, 0, 3, 3, 3, 4, 3, 3, 3, 3, 3, 3, 5, 3
b 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 3, 1, 3, 3, 3, 0
b 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
b 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 0, 3, 3, 5
b 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5
b 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 0, 3, 0, 3, 3

/* symbol */
hshsiz  = 2048 /* must be pow of 2 */
hshmsk  = hshsiz-1
symsize = 12
s.name  = 0
s.flags = 8
s.value = 10

s.built = 0x3f
s.defin = 0x8000
s.firel = 0x4000
s.norel = ~s.firel
s.uname = 0x2000
s.globl = 0x1000
s.mutab = 0x0800

/* builtin symbols */
p.if    = 1
p.else  = 2
p.endif = 3
regb    = 4
regw    = 5
sreg    = 6
siz0    = 7
byte    = 8
put0    = 9
seg0    = 10
mth0    = 11
mth1    = 12
mth2    = 13
mth3    = 14
mth4    = 15
stk0    = 16
adr0    = 17
jmp0    = 18
jmp1    = 19
jmp2    = 20
ret0    = 21
sio0    = 22
mov0    = 23
xcg0    = 24
sys0    = 25

/* relocation info */
rtabsiz = 1000
relsize = 4
rellog  = 2
r.pcrel = 0x8000
r.size  = 0x4000
r.symb  = 0x3fff

/* argument types, bits 0-7 for register number */
a.r0    = 0x01 /* ax/al */
a.r1    = 0x02 /* cx/cl */
a.reg   = 0x10
a.seg   = 0x20
a.mem   = 0x40
a.imm   = 0x80
a.mrm   = a.mem|a.reg

symtab:
<.\0      >
pc.flgs: s.firel|s.defin|s.mutab
pc.data: 0

<..\0     >
s.firel|s.defin|s.mutab
filebgn: 0

<lt.as\0  >; s.defin; 1

<.if\0    >; p.if; 0
elsesym:
<.else\0  >; p.else; 0
enifsym:
<.endif\0 >; p.endif; 0

<al\0     >; regb; 0
<cl\0     >; regb; 1
<dl\0     >; regb; 2
<bl\0     >; regb; 3
<ah\0     >; regb; 4
<ch\0     >; regb; 5
<dh\0     >; regb; 6
<bh\0     >; regb; 7

<ax\0     >; regw; 0
<cx\0     >; regw; 1
<dx\0     >; regw; 2
<bx\0     >; regw; 3
<sp\0     >; regw; 4
<bp\0     >; regw; 5
<si\0     >; regw; 6
<di\0     >; regw; 7

<es\0     >; sreg; 0
<cs\0     >; sreg; 1
<ss\0     >; sreg; 2
<ds\0     >; sreg; 3
<fs\0     >; sreg; 4
<gs\0     >; sreg; 5

<movs\0   >; byte; 0xa4
<movsb\0  >; byte; 0xa5
<cmps\0   >; byte; 0xa6
<cmpsb\0  >; byte; 0xa7
<stosb\0  >; byte; 0xaa
<stos\0   >; byte; 0xab
<lodsb\0  >; byte; 0xac
<lods\0   >; byte; 0xad
<scasb\0  >; byte; 0xae
<scas\0   >; byte; 0xaf
<pusha\0  >; byte; 0x60
<popa\0   >; byte; 0x61
<nop\0    >; byte; 0x90
<cbw\0    >; byte; 0x98
<cwd\0    >; byte; 0x99
<pushf\0  >; byte; 0x9c
<popf\0   >; byte; 0x9d
<sahf\0   >; byte; 0x9e
<lahf\0   >; byte; 0x9f
<leave\0  >; byte; 0xc9
<int3\0   >; byte; 0xcc
<into\0   >; byte; 0xce
<iret\0   >; byte; 0xcf
<xlat\0   >; byte; 0xd7
<repne\0  >; byte; 0xf2
<repe\0   >; byte; 0xf3
<rep\0    >; byte; 0xf3
<hlt\0    >; byte; 0xf4
<cmc\0    >; byte; 0xf5
<clc\0    >; byte; 0xf8
<stc\0    >; byte; 0xf9
<cli\0    >; byte; 0xfa
<sti\0    >; byte; 0xfb
<cld\0    >; byte; 0xfc
<std\0    >; byte; 0xfd
<int\0    >; byte; 0xcd

<b\0      >; put0; 0
<seg\0    >; seg0; 0
<add\0    >; mth0; 0
<addb\0   >; siz0; 0
<or\0     >; mth0; 1
<orb\0    >; siz0; 0
<adc\0    >; mth0; 2
<adcb\0   >; siz0; 0
<sbb\0    >; mth0; 3
<sbbb\0   >; siz0; 0
<and\0    >; mth0; 4
<andb\0   >; siz0; 0
<sub\0    >; mth0; 5
<subb\0   >; siz0; 0
<xor\0    >; mth0; 6
<xorb\0   >; siz0; 0
<cmp\0    >; mth0; 7
<cmpb\0   >; siz0; 0
<rol\0    >; mth1; 0
<rolb\0   >; siz0; 0
<ror\0    >; mth1; 1
<rorb\0   >; siz0; 0
<rcl\0    >; mth1; 2
<rclb\0   >; siz0; 0
<rcr\0    >; mth1; 3
<rcrb\0   >; siz0; 0
<sal\0    >; mth1; 4
<salb\0   >; siz0; 0
<shl\0    >; mth1; 4
<shlb\0   >; siz0; 0
<shr\0    >; mth1; 5
<shrb\0   >; siz0; 0
<sar\0    >; mth1; 7
<sarb\0   >; siz0; 0
<inc\0    >; mth2; 0
<incb\0   >; siz0; 0
<dec\0    >; mth2; 1
<decb\0   >; siz0; 0
<not\0    >; mth3; 2
<notb\0   >; siz0; 0
<neg\0    >; mth3; 3
<negb\0   >; siz0; 0
<mul\0    >; mth3; 4
<mulb\0   >; siz0; 0
<imul\0   >; mth3; 5
<imulb\0  >; siz0; 0
<div\0    >; mth3; 6
<divb\0   >; siz0; 0
<idiv\0   >; mth3; 7
<idivb\0  >; siz0; 0
<test\0   >; mth4; 0
<testb\0  >; siz0; 0

<pop\0    >; stk0; 1
<push\0   >; stk0; 0
<pushb\0  >; siz0; 0

<les\0    >; adr0; 0xc4
<lds\0    >; adr0; 0xc5
<lea\0    >; adr0; 0x8d

<jo\0     >; jmp0; 0x70
<jno\0    >; jmp0; 0x71
<jb\0     >; jmp0; 0x72
<jc\0     >; jmp0; 0x72
<jnb\0    >; jmp0; 0x73
<jnc\0    >; jmp0; 0x73
<jae\0    >; jmp0; 0x73
<je\0     >; jmp0; 0x74
<jz\0     >; jmp0; 0x74
<jne\0    >; jmp0; 0x75
<jnz\0    >; jmp0; 0x75
<jbe\0    >; jmp0; 0x76
<jna\0    >; jmp0; 0x76
<ja\0     >; jmp0; 0x77
<js\0     >; jmp0; 0x78
<jns\0    >; jmp0; 0x79
<jp\0     >; jmp0; 0x7a
<jnp\0    >; jmp0; 0x7b
<jl\0     >; jmp0; 0x7c
<jnl\0    >; jmp0; 0x7d
<jge\0    >; jmp0; 0x7d
<jng\0    >; jmp0; 0x7e
<jle\0    >; jmp0; 0x7e
<jg\0     >; jmp0; 0x7f
<loopne\0 >; jmp0; 0xe0
<loope\0  >; jmp0; 0xe1
<loop\0   >; jmp0; 0xe2
<jcxz\0   >; jmp0; 0xe3

<call\0   >; jmp1; 2
<jmp\0    >; jmp1; 4
<jmpb\0   >; siz0; 0

<lcall\0  >; jmp2; 0x9a
<ljmp\0   >; jmp2; 0xea

<ret\0    >; ret0; 0xc2
<retf\0   >; ret0; 0xca

<in\0     >; sio0; 0
<inb\0    >; siz0; 0
<out\0    >; sio0; 2
<outb\0   >; siz0; 0

<mov\0    >; mov0; 0
<movb\0   >; siz0; 0
<xchg\0   >; xcg0; 0
<xchgb\0  >; siz0; 0

<exit\0   >; sys0; 0
<open\0   >; sys0; 3
<close\0  >; sys0; 4
<read\0   >; sys0; 5
<write\0  >; sys0; 6
<exec\0   >; sys0; 10

bsyms = [.-symtab]/symsize

bss:

usyms:  .=symtab+hshsiz*symsize
nsyms:  .=.+2
hshtab: .=.+hshsiz*2

header:
e.text: .=.+2
e.syms: .=.+2
e.rels: .=.+2

relfd:  .=.+2
reloc:
r.flgs: .=.+2
r.addr: .=.+2

getbuf: .=.+514
putbuf: .=.+512
errbuf: .=.+10

v.flgs: .=.+2
v.data: .=.+2
v.symb: .=.+2
x.flgs: .=.+2
x.data: .=.+2
x.symb: .=.+2

arg:    .=.+1
argx:   .=.+1
argsiz: .=.+2
modrm:  .=.+2
nreg:   .=.+2
nseg:   .=.+2

symbol: .=.+8
lval:   .=.+2
pc.adj: .=.+2

char:   .=.+2
nerror: .=.+2
size:   .=.+2
pcrel:  .=.+2

bsslen  = .-bss
