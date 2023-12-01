package main


import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:testing"
import "core:time"
import "core:mem"
import "core:thread"
import "core:intrinsics"

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

part2_proc1 :: proc(t: ^thread.Thread) {
    input_start := cast(int)uintptr(t.user_args[1])
    input_end   := cast(int)uintptr(t.user_args[2])
    input := transmute(string) ((cast([^]u8) t.user_args[0])[input_start:input_end])
    sum_first := 0
    find_next_first: for line in strings.split_lines_iterator(&input) {
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
    intrinsics.atomic_add_explicit(cast(^int) t.user_args[3], sum_first, .Release)
}

part2_proc2 :: proc(t: ^thread.Thread) {
    input_start := cast(int)uintptr(t.user_args[1])
    input_end   := cast(int)uintptr(t.user_args[2])
    input := transmute(string) ((cast([^]u8) t.user_args[0])[input_start:input_end])
    sum_last  := 0
    find_next_last: for line in strings.split_lines_iterator(&input) {
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
    intrinsics.atomic_add_explicit(cast(^int) t.user_args[3], sum_last,  .Release)
}

// MUST BE EVEN!
N_THREADS :: 4

part2 :: proc(input: string) -> int {
    sum_first: int = 0
    sum_last:  int = 0
    last_split_index := -1
    threads: [N_THREADS]^thread.Thread
    for i in 0..<N_THREADS/2 {
        t1 := thread.create(part2_proc1)
        t2 := thread.create(part2_proc2)
        threads[2*i+0] = t1
        threads[2*i+1] = t2
        t1.user_args[0] = raw_data(input)
        t1.user_args[1] = cast(rawptr) uintptr(last_split_index+1)
        last_split_index = (len(input) / (N_THREADS/2)) * (i+1)
        if last_split_index > len(input) {
            last_split_index = len(input)
        }
        for last_split_index < len(input) && input[last_split_index] != '\n' {
            last_split_index += 1
        }
        t1.user_args[2] = cast(rawptr) uintptr(last_split_index)
        t2.user_args[0] = t1.user_args[0]
        t2.user_args[1] = t1.user_args[1]
        t2.user_args[2] = t1.user_args[2]
        t1.user_args[3] = &sum_first
        t2.user_args[3] = &sum_last
        thread.start(t1)
        thread.start(t2)
    }
    for i in 0..<N_THREADS {
        thread.join(threads[i])
    }
    return 10*sum_first + sum_last
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
