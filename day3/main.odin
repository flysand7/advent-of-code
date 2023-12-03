package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:testing"
import "core:time"
import "core:mem"

INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

PART1_EXAMPLE_EXPECT :: 4361
PART1_EXAMPLE :: `467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..
`

part1 :: proc(input: string) -> int {
    width  := strings.index_byte(input, '\n')
    height := strings.count(input, "\n")
    stride := width+1
    is_digit :: proc(chr: u8) -> bool {
        return '0' <= chr && chr <= '9'
    }
    scan_digits :: proc(schema: string, index: int) -> int {
        index := index
        for index != 0 && is_digit(schema[index-1]){
            index -= 1
        }
        return index
    }
    parse_number_at :: proc(used_indices: ^[dynamic]int, schema: string, index: int) -> int {
        if index < 0 || index >= len(schema) || schema[index] == '\n' {
            return 0
        }
        if ! is_digit(schema[index]) {
            return 0
        }
        start_index := scan_digits(schema, index)
        for used_index in used_indices {
            if start_index == used_index {
                return 0
            }
        }
        append(used_indices, start_index)
        index := start_index
        n := 0
        for is_digit(schema[index]) {
            n = 10*n + int(schema[index] - '0')
            index += 1
        }
        return n
    }
    used_indices: [dynamic]int
    sum := 0
    for i in 0 ..< len(input) {
        if input[i] != '\n' && input[i] != '.' && !is_digit(input[i]) {
            sum += parse_number_at(&used_indices, input, i-1)
            sum += parse_number_at(&used_indices, input, i+1)
            sum += parse_number_at(&used_indices, input, i-stride)
            sum += parse_number_at(&used_indices, input, i+stride)
            sum += parse_number_at(&used_indices, input, i-1-stride)
            sum += parse_number_at(&used_indices, input, i-1+stride)
            sum += parse_number_at(&used_indices, input, i+1-stride)
            sum += parse_number_at(&used_indices, input, i+1+stride)
        }
    }
    return sum
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

PART2_EXAMPLE_EXPECT :: 467835
PART2_EXAMPLE :: `467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..`

part2 :: proc(input: string) -> int {
    width  := strings.index_byte(input, '\n')
    height := strings.count(input, "\n")
    stride := width+1
    is_digit :: proc(chr: u8) -> bool {
        return '0' <= chr && chr <= '9'
    }
    scan_digits :: proc(schema: string, index: int) -> int {
        index := index
        for index != 0 && is_digit(schema[index-1]){
            index -= 1
        }
        return index
    }
    parse_number_at :: proc(used_indices: ^[dynamic]int, found: ^int, schema: string, index: int) -> int {
        if index < 0 || index >= len(schema) || schema[index] == '\n' {
            return 1
        }
        if ! is_digit(schema[index]) {
            return 1
        }
        start_index := scan_digits(schema, index)
        for used_index in used_indices {
            if start_index == used_index {
                return 1
            }
        }
        append(used_indices, start_index)
        index := start_index
        n := 0
        for is_digit(schema[index]) {
            n = 10*n + int(schema[index] - '0')
            index += 1
        }
        found^ += 1
        return n
    }
    used_indices: [dynamic]int
    sum := 0
    for i in 0 ..< len(input) {
        if input[i] != '\n' && input[i] != '.' && !is_digit(input[i]) {
            gear_ratio := 1
            found := 0
            gear_ratio *= parse_number_at(&used_indices, &found, input, i-1)
            gear_ratio *= parse_number_at(&used_indices, &found, input, i+1)
            gear_ratio *= parse_number_at(&used_indices, &found, input, i-stride)
            gear_ratio *= parse_number_at(&used_indices, &found, input, i+stride)
            gear_ratio *= parse_number_at(&used_indices, &found, input, i-1-stride)
            gear_ratio *= parse_number_at(&used_indices, &found, input, i-1+stride)
            gear_ratio *= parse_number_at(&used_indices, &found, input, i+1-stride)
            gear_ratio *= parse_number_at(&used_indices, &found, input, i+1+stride)
            if found == 2 {
                sum += gear_ratio
            }
            clear(&used_indices)
        }
    }
    return sum
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
