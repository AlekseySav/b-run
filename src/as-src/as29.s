/*
 * assembler, second pass
 * as29 -- data & bss
 */

$g;

/* symbol */
symsize = 12
s.name  = 0
s.flgs  = 8
s.value = 10

s.built = 0x3f
s.defin = 0x8000
s.firel = 0x4000
s.norel = ~s.firel
s.uname = 0x2000
s.globl = 0x1000
s.mutab = 0x0800

/* relocation info */
rtabsiz = 1000
relsize = 4
rellog  = 2
r.pcrel = 0x8000
r.size  = 0x4000
r.symb  = 0x3fff
r.flgs  = 0
r.addr  = 2

errbuf: .=.+30

o.syms: .=.+2
o.rels: .=.+2
header:
e.text: .=.+2
e.syms: .=.+2
e.rels: .=.+2

text:
