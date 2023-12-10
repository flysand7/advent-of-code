package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:testing"
import "core:time"
import "core:mem"
import "core:math"

INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

PART1_EXAMPLE_EXPECT :: 6
PART1_EXAMPLE :: `LLR

AAA = (BBB, BBB)
BBB = (AAA, ZZZ)
ZZZ = (ZZZ, ZZZ)`

part1 :: proc(input: string) -> int {
    Instruction :: struct {
        l: string,
        r: string,
    }
    instructions := make(map[string]Instruction)
    newline_pos := strings.index_byte(input, '\n')
    tape := input[:newline_pos]
    rest := input[newline_pos+2:]
    for line in strings.split_lines_iterator(&rest) {
        from := line[0:3]
        map_insert(&instructions, from, Instruction {line[7:10], line[12:15]})
    }
    current := "AAA"
    for steps := 0; true; steps += 1 {
        if current == "ZZZ" do return steps
        current = tape[steps%len(tape)]=='L'? instructions[current].l : instructions[current].r
    }
    return -1
}

@(test)
part1_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part1(PART1_EXAMPLE), PART1_EXAMPLE_EXPECT)
}

@(test)
part1_run :: proc(t: ^testing.T) {
    runner(part1, #load(INPUT_FILENAME))
}

// -----------------------------------  PART 2 --------------------------------------------------//

PART2_EXAMPLE_EXPECT :: 6
PART2_EXAMPLE :: `LR

11A = (11B, XXX)
11B = (XXX, 11Z)
11Z = (11B, XXX)
22A = (22B, XXX)
22B = (22C, 22C)
22C = (22Z, 22Z)
22Z = (22B, 22B)
XXX = (XXX, XXX)`

part2 :: proc(input: string) -> int {
    Instruction :: struct {
        l: string,
        r: string,
    }
    instructions: map[string]Instruction
    newline_pos := strings.index_byte(input, '\n')
    tape := input[:newline_pos]
    rest := input[newline_pos+2:]
    // Just parsing to get the mappings and list of initial nodes.
    nodes := make([dynamic]string)
    for line in strings.split_lines_iterator(&rest) {
        from := line[0:3]
        map_insert(&instructions, from, Instruction {line[7:10], line[12:15]})
        if from[2] == 'A' {
            append(&nodes, from)
        }
    }
    // Figure out where each node first encounters the end of the chain, and how often it repeats
    node_offsets := make([dynamic]int, len(nodes))
    node_cycles  := make([dynamic]int, len(nodes))
    next_node: for _, i in nodes {
        for steps := 0; true; steps += 1 {
            node := nodes[i]
            nodes[i] = tape[steps%len(tape)]=='L'? instructions[node].l : instructions[node].r
            if nodes[i][2] == 'Z' {
                if node_offsets[i] == 0 {
                    node_offsets[i] = steps+1
                } else {
                    node_cycles[i] = steps+1 - node_offsets[i]
                    continue next_node
                }
            }
        }
    }
    // Wait for it...
    extended_gcd :: proc(a, b: int)->(int, int, int) {
        if a == 0 {
            return b, 0, 1
        }
        gcd, x1, y1 := extended_gcd(b%a, a)
        x := y1 - (b/a)*x1
        y := x1
        return gcd, x, y
    }
    // Solving the diophantine equations in a loop.
    // Basically what we got here is an array of these values:
    //   offset[i] + n[i]*cycles[i]
    // We need to find minimum values of `n[i]` such that all the values in the array is equal.
    // That value will be the total amount of steps needed to complete the task.
    // 
    // As a further hint, consider the only pair of elements in the
    // provided example:
    //   2 + an*2 = 3 + bn*3
    // Which we reduce to the following diophantine equation:
    //   an*2 - bn*3 = 1
    // How to solve these can be looked up online, but in short that's basically why we needed
    // extended euclidean algo.
    // 
    // Using the method (accounting for sign of -3) we obtain the following minimi:
    //   The minimum amount of loops for a: -1 + k*(b / gcd)
    //   The minimum amount of loops for b: -1 + k*(a / gcd)
    // This isn't natural so we gotta normalize these values. We iterate up by b/gcd in case
    // of a, and a/gcd in case of b until we reach positive values for an and bn. That's our
    // minimum amounts of loops each value will go through the finishing value.
    //
    // In order to continue the loop, we'll consider that the minimum amount of steps to get both
    // 0'th and 1'st elements of the array into the finishing position we needed:
    //   offset[1] + n[1]*cycles[1]
    // Steps.
    // We use that as our value for the next iteration.
    a_offset := node_offsets[0]
    a_cycle := node_cycles[0]
    for i in 1 ..< len(nodes) {
        b_offset := node_offsets[i]
        b_cycle := node_cycles[i]
        c := b_offset - a_offset
        gcd, ag, bg := extended_gcd(a_cycle, b_cycle)
        assert(gcd != 0)
        assert(c % gcd == 0)
        an := ag * (c / gcd)
        bn := -bg * (c / gcd)
        for bn < 0 || an < 0 {
            bn += a_cycle / gcd
            an += b_cycle / gcd
        }
        assert(an > 0)
        assert(bn > 0)
        assert(a_offset + a_cycle*an == b_offset + b_cycle*bn)
        a_offset = a_offset + a_cycle*an
        a_cycle = math.lcm(a_cycle, b_cycle)
    }
    return a_offset
}

@(test)
part2_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part2(PART2_EXAMPLE), PART2_EXAMPLE_EXPECT)
}

@(test)
part2_run :: proc(t: ^testing.T) {
    runner(part2, #load(INPUT_FILENAME))
}

// -----------------------------------  MISC --------------------------------------------------//

runner :: proc(fn: #type proc(input: string) -> int, input: string) {
    // Create arena allocator
    allocator_storage := make([]u8, 8 * mem.Megabyte)
    arena: mem.Arena
    mem.arena_init(&arena, allocator_storage)
    allocator := mem.arena_allocator(&arena)
    context.allocator = allocator
    context.temp_allocator = allocator
    // Profile the function
    t_start := time.now()
    result := fn(input)
    t_dur := time.diff(t_start, time.now())
    memory := arena.peak_used
    // Print the results
    fmt.printf("--------------------------------\n")
    fmt.printf("  Result: %v\n", result)
    fmt.printf("  Time: %v\n", t_dur)
    fmt.printf("  Memory: %v bytes\n", memory)
    fmt.printf("--------------------------------\n")
}
