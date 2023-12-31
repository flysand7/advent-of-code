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

// -----------------------------------  PART 1 --------------------------------------------------//

part1 :: proc(input: string) -> int {
    return 0
}

PART1_RUN_INPUT   :: false

@(test)
part1_run :: proc(t: ^testing.T) {
    input := transmute(string) #load(INPUT_FILENAME)
    for test in tests do if test.enabled {
        testing.expect_value(t, part1(test.input), test.expect)
    }
    if len(input) != 0 {
        if PART1_RUN_INPUT {
            runner(part1, input)
        }
    }
}

tests := []struct {enabled: bool, expect: int, input: string} {
    {true, 0, 
``,
    },
}

// -----------------------------------  PART 2 --------------------------------------------------//


part2 :: proc(input: string) -> int {
    return 0
}

PART2_RUN_INPUT :: false

@(test)
part2_run :: proc(t: ^testing.T) {
    input := transmute(string) #load(INPUT_FILENAME)
    for test in tests do if test.enabled {
        testing.expect_value(t, part2(test.input), test.expect)
    }
    if len(input) != 0 {
        if PART2_RUN_INPUT {
            runner(part2, input)
        }
    }
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
