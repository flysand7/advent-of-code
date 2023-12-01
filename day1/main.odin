package main


import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:testing"
import "core:time"

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

part2 :: proc(input: string) -> int {
    input := input
    digit_map: map[string]int = {
        "0" = 0, "zero"  = 0,
        "1" = 1, "one"   = 1,
        "2" = 2, "two"   = 2,
        "3" = 3, "three" = 3,
        "4" = 4, "four"  = 4,
        "5" = 5, "five"  = 5,
        "6" = 6, "six"   = 6,
        "7" = 7, "seven" = 7,
        "8" = 8, "eight" = 8,
        "9" = 9, "nine"  = 9,
    }
    sum: int = 0
    for line in strings.split_lines_iterator(&input) {
        first, last: Maybe(int)
        for i := 0; i < len(line); i += 1 {
            for key in digit_map {
                if strings.has_prefix(line[i:], key) {
                    digit := digit_map[key]
                    if first == nil {
                        first = digit
                    }
                    last = digit
                }
            }
        }
        final_number := 10*first.? + last.?
        sum += final_number
    }
    return sum
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
    t_start := time.now()
    result := fn(input)
    fmt.printf("--------------------------------\n")
    fmt.printf("  Result: %v\n", result)
    t_dur := time.diff(t_start, time.now())
    fmt.printf("  Took: %v\n", t_dur)
    fmt.printf("--------------------------------\n")
}
