$g

LINES = 500

quit: 0
peekc: 0
color: 0

bss:

n_lines:    .=.+2
top:        .=.+2
x:          .=.+2
y:          .=.+2
line:       .=.+20

lines:      .=.+[LINES*2]
e_lines = .-2
pool:       .=.+[LINES*81]
poolmap:    .=.+[LINES/8]

outbuf:     .=.+80

bsslen = .-bss
