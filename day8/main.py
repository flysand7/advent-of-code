#!/usr/bin/env python

# At some point I wasn't sure Odin compiler was correct, so I re-implemented my solution in
# Python, just to be sure. Huh, I guess Odin maps 1:1 to python if you forget that memory needs to
# be deallocated in Odin. See for yourself.
def part1(in_str: str)->int:
    instructions: dict[str, tuple[str, str]] = {}
    newline_pos = in_str.index('\n')
    tape = in_str[:newline_pos]
    rest = in_str[newline_pos+2:]
    for line in rest.splitlines():
        start = line[0:3]
        instructions[start] = (line[7:10], line[12:15])
    current = 'AAA'
    steps = 0
    while True:
        if current == "ZZZ":
            return steps
        current = instructions[current][0] if tape[steps%len(tape)]=='L' else instructions[current][1]

print(part1(open('./input', mode='r', encoding='utf8').read()))
