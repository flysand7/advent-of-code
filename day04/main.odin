package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:slice"
import "core:testing"
import "core:time"
import "core:mem"

INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

PART1_EXAMPLE_EXPECT :: 13
PART1_EXAMPLE :: `Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
`

part1 :: proc(input: string) -> int {
    sum := 0
    input := input
    for line in strings.split_lines_iterator(&input) {
        line := line[strings.index_byte(line, ':')+1:]
        separator_idx := strings.index_byte(line, '|')
        win_strings  := line[:separator_idx]
        have_strings := line[separator_idx+1:]
        win_numbers := make([dynamic]int)
        have_numbers := make([dynamic]int)
        for number_str in strings.split_iterator(&win_strings, " ") {
            number, ok := strconv.parse_int(number_str, 10)
            if ok {
                append(&win_numbers, number)
            }
        }
        for number_str in strings.split_iterator(&have_strings, " ") {
            number, ok := strconv.parse_int(number_str, 10)
            if ok {
                append(&have_numbers, number)
            }
        }
        card_score := 0
        for have_number in have_numbers {
            for win_number in win_numbers {
                if have_number == win_number {
                    if card_score == 0 {
                        card_score = 1
                    } else {
                        card_score *= 2
                    }
                }
            }
        }
        sum += card_score
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

PART2_EXAMPLE_EXPECT :: 30
PART2_EXAMPLE :: `Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11`

part2 :: proc(input: string) -> int {
    input := input
    cards := make([dynamic]int)
    resize_dynamic_array(&cards, strings.count(input, "\n")+1)
    card_idx := 0
    for line in strings.split_lines_iterator(&input) {
        line := line[strings.index_byte(line, ':')+1:]
        separator_idx := strings.index_byte(line, '|')
        win_strings  := line[:separator_idx]
        have_strings := line[separator_idx+1:]
        win_numbers := make([dynamic]int)
        have_numbers := make([dynamic]int)
        for number_str in strings.split_iterator(&win_strings, " ") {
            number, ok := strconv.parse_int(number_str, 10)
            if ok {
                append(&win_numbers, number)
            }
        }
        for number_str in strings.split_iterator(&have_strings, " ") {
            number, ok := strconv.parse_int(number_str, 10)
            if ok {
                append(&have_numbers, number)
            }
        }
        matches := 0
        for have_number in have_numbers {
            for win_number in win_numbers {
                if have_number == win_number {
                    matches += 1
                }
            }
        }
        cards[card_idx] += 1
        for i in card_idx+1 ..< card_idx+1+matches {
            cards[i] += 1 * cards[card_idx]
        }
        card_idx += 1
    }
    sum := 0
    for num in cards {
        sum += num
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
