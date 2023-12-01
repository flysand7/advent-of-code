package main


import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:testing"
import "core:time"
import "core:mem"

INPUT_PATH :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

PART1_EXAMPLE_EXPECT :: 142
PART1_EXAMPLE :: `1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet`

part1 :: proc(input: string) -> int {
    input := input
    sum: int = 0
    for line in strings.split_lines_iterator(&input) {
        first, last: Maybe(int)
        for ch in line {
            if '0' <= ch && ch <= '9' {
                digit := int(ch - '0')
                if first == nil {
                    first = digit
                }
                last = digit
            }
        }
        final_number := 10*first.? + last.?
        sum += final_number
    }
    return sum
}

@(test)
part1_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part1(PART1_EXAMPLE), PART1_EXAMPLE_EXPECT)
}

@(test)
part1_run :: proc(t: ^testing.T) {
    runner(part1, #load(INPUT_PATH))
}

// -----------------------------------  PART 2 --------------------------------------------------//

PART2_EXAMPLE_EXPECT :: 281
PART2_EXAMPLE :: `two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
`

digit_names: [10]string = {
    "one",
    "two",
    "six",
    "zero",
    "four",
    "five",
    "nine",
    "three",
    "seven",
    "eight",
}

digit_numbers: [10]int = {
    1,
    2,
    6,
    0,
    4,
    5,
    9,
    3,
    7,
    8,
}

part2 :: proc(input: string) -> int {
    input1 := input
    input2 := input
    sum_first: int = 0
    sum_last:  int = 0
    find_next_first: for line in strings.split_lines_iterator(&input1) {
        for i := 0; i < len(line); i += 1 {
            if '0' <= line[i] && line[i] <= '9' {
                sum_first += int(line[i] - '0')
                continue find_next_first
            } else {
                for name, index in digit_names {
                    if strings.has_prefix(line[i:], name) {
                        sum_first += digit_numbers[index]
                        continue find_next_first
                    } else if len(name) > len(line[i:]) {
                        break
                    }
                }
            }
        }
    }
    find_next_last: for line in strings.split_lines_iterator(&input2) {
        for i := len(line) - 1; i >= 0; i -= 1 {
            if '0' <= line[i] && line[i] <= '9' {
                sum_last += int(line[i] - '0')
                continue find_next_last
            } else {
                for name, index in digit_names {
                    if strings.has_prefix(line[i:], name) {
                        sum_last += digit_numbers[index]
                        continue find_next_last
                    } else if len(name) > len(line[i:]) {
                        break
                    }
                }
            }
        }
    }
    return sum_first*10 + sum_last
}

@(test)
part2_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part2(PART2_EXAMPLE), PART2_EXAMPLE_EXPECT)
}

@(test)
part2_run :: proc(t: ^testing.T) {
    runner(part2, #load(INPUT_PATH))
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

main :: proc() {
    runner(part2, PART2_EXAMPLE)
}
