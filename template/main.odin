
package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:testing"
import "core:time"

// -----------------------------------  PART 1 --------------------------------------------------//

PART1_EXAMPLE_EXPECT :: 0
PART1_EXAMPLE :: ``

part1 :: proc(input: string) -> int {
    return 0
}

@(test)
part1_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part1(PART1_EXAMPLE), PART1_EXAMPLE_EXPECT)
}

@(test)
part1_run :: proc(t: ^testing.T) {
    runner(part1, "./input")
}

// -----------------------------------  PART 2 --------------------------------------------------//

PART2_EXAMPLE_EXPECT :: 0
PART2_EXAMPLE :: ``

part2 :: proc(input: string) -> int {
    return 0
}

@(test)
part2_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part2(PART2_EXAMPLE), PART2_EXAMPLE_EXPECT)
}

@(test)
part2_run :: proc(t: ^testing.T) {
    runner(part2, "./input")
}

// -----------------------------------  MISC --------------------------------------------------//

runner :: proc(fn: #type proc(input_file: string) -> int, input_file: string) {
    t_start := time.now()
    file_bytes, ok := os.read_entire_file(input_file)
    assert(ok, "Input file not found")
    file_string := transmute(string) file_bytes
    result := part1(file_string)
    fmt.printf("--------------------------------\n")
    fmt.printf("  Result: %v\n", result)
    t_end := time.now()
    t_dur := time.diff(t_start, t_end)
    fmt.printf("  Took: %v\n", t_dur)
    fmt.printf("--------------------------------\n")
}
