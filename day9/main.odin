package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:testing"
import "core:time"
import "core:math"
import "core:mem"

INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1+2 -----------------------------------------------//

PART1_EXAMPLE_EXPECT :: 114
PART2_EXAMPLE_EXPECT :: 2
PART_EXAMPLE :: `0 3 6 9 12 15
1 3 6 10 15 21
10 13 16 21 30 45`

part :: proc(input: string, part: int) -> int {
    input := input
    sum := 0
    for line in strings.split_lines_after_iterator(&input) {
        line := line
        if line[len(line)-1] == '\n' {
            line = line[:len(line)-1]
        }
        sequence := make([dynamic]int, 0, 10)
        for value in strings.split_by_byte_iterator(&line, ' ') {
            number, ok := strconv.parse_int(value, 10)
            append(&sequence, number)
        }
        subsequences := make([dynamic][dynamic]int)
        append(&subsequences, sequence)
        make_next_sequence: for seq_index := 0; true; seq_index += 1{
            subsequence := make([dynamic]int)
            for i in 0 ..< len(subsequences[seq_index]) - 1 {
                next := subsequences[seq_index][i+1] - subsequences[seq_index][i]
                append(&subsequence, next)
            }
            append(&subsequences, subsequence)
            val := subsequence[0]
            for i in 1 ..< len(subsequence) {
                if val != subsequence[i] {
                    continue make_next_sequence
                }
            }
            break
        }
        newval := 0
        if part == 1 {
            #reverse for subsequence in subsequences {
                newval += subsequence[len(subsequence)-1]
            }
        } else if part == 2 {
            #reverse for subsequence in subsequences {
                newval = subsequence[0] - newval
            }
        }
        sum += newval
        delete(sequence)
    }
    return sum
}

@(test)
part_run :: proc(t: ^testing.T) {
    testing.expect_value(t, part(PART_EXAMPLE, 1), PART1_EXAMPLE_EXPECT)
    testing.expect_value(t, part(PART_EXAMPLE, 2), PART2_EXAMPLE_EXPECT)
    input := transmute(string) #load(INPUT_FILENAME)
    if len(input) != 0 {
        runner(part, 1, input)
        runner(part, 2, input)
    }
}

// -----------------------------------  MISC --------------------------------------------------//

runner :: proc(fn: #type proc(input: string, part: int) -> int, part: int, input: string) {
    // Create arena allocator
    allocator_storage := make([]u8, 8 * mem.Megabyte)
    arena: mem.Arena
    mem.arena_init(&arena, allocator_storage)
    allocator := mem.arena_allocator(&arena)
    context.allocator = allocator
    context.temp_allocator = allocator
    // Profile the function
    t_start := time.now()
    result := fn(input, part)
    t_dur := time.diff(t_start, time.now())
    memory := arena.peak_used
    // Print the results
    fmt.printf("--------------------------------\n")
    fmt.printf("  Result: %v\n", result)
    fmt.printf("  Time: %v\n", t_dur)
    fmt.printf("  Memory: %v bytes\n", memory)
    fmt.printf("--------------------------------\n")
}
