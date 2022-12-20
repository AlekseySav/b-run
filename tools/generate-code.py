#!/bin/python3
# generate assembler code

import sys

def print_line(line):
    if line[0] != '#':
        print(line[:-1])
        return
    command = line[1:].split()
    put = instructions[int(command[0])].replace('|| ', '\n').replace(';', '\n;')
    if len(command) > 1:
        put = put.replace('$', 'l' if command[1] == '1' else 'x'). \
            replace('&', 'byte' if command[1] == '1' else 'word'). \
            replace('%', '\n cbw' if command[1] == '1' else ''). \
            replace('#', command[1])
    if len(command) > 2:
        put = put.replace('@', command[2])
    print(put[:-1])
    print()

with open('tools/asm-16.asm') as file:
    instructions = [i for i in file.readlines() if i[0] != '*']

print_line("#0")

for line in sys.stdin.readlines():
    print_line(line)
