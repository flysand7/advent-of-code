package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:testing"
import "core:time"
import "core:mem"
import "core:math"

INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//
// --------------------------------- AND PART 2 !!!----------------------------------------------//

PART1_EXAMPLE_EXPECT :: 288
PART1_EXAMPLE :: `Time:      7  15   30
Distance:  9  40  200`

part1 :: proc(input: string) -> int {
    parse_ints :: proc(destination: ^[dynamic]int, line: string) {
        line := line
        for segment in strings.split_by_byte_iterator(&line, ' ') {
            if len(segment) > 0 {
                fmt.println(segment)
                number, ok := strconv.parse_int(segment, 10)
                assert(ok)
                append(destination, number)
            }
        }
    }
    newline := strings.index_byte(input, '\n')
    line_time := input[strings.index_byte(input[:newline], ':')+1:newline]
    line_dist := input[strings.index_byte(input[newline+1:], ':')+newline+2:]
    times := make([dynamic]int)
    dists := make([dynamic]int)
    parse_ints(&times, line_time)
    parse_ints(&dists, line_dist)
    races := len(times)
    assert(len(dists) == races)
    result := 1
    for race_number in 0 ..< races {
        race_time := times[race_number]
        race_dist := dists[race_number]
        D := race_time*race_time - 4*race_dist
        hold_time_lo := cast(int) math.ceil((f64(race_time) - math.sqrt(f64(D)) +  0.01) / 2.0)
        hold_time_hi := cast(int) math.floor((f64(race_time) + math.sqrt(f64(D)) - 0.01) / 2.0)
        result *= hold_time_hi - hold_time_lo + 1
    }
    return result
}

@(test)
part1_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part1(PART1_EXAMPLE), PART1_EXAMPLE_EXPECT)
}

@(test)
part1_run :: proc(t: ^testing.T) {
    runner(part1, #load(INPUT_FILENAME))
}

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
