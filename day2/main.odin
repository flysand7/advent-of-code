
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

PART1_EXAMPLE_EXPECT :: 8
PART1_EXAMPLE :: `Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green`

part1 :: proc(input: string) -> int {
    max_red   := 12
    max_green := 13
    max_blue  := 14
    sum := 0
    input := input
    for line in strings.split_lines_after_iterator(&input) {
        line := line[:len(line)-1]
        colon_index := strings.index_byte(line, ':')
        game_id := strconv.atoi(line[5:colon_index])
        possible := true
        games := line[colon_index+2:]
        check_game: for draw in strings.split_iterator(&games, "; ") {
            draw := draw
            for color_draw in strings.split_iterator(&draw, ", ") {
                space_idx := strings.index_byte(color_draw, ' ')
                number := strconv.atoi(color_draw[:space_idx])
                color  := color_draw[space_idx+1:]
                switch color {
                case "red":
                    if number > max_red {
                        possible = false
                        break check_game
                    }
                case "green":
                    if number > max_green {
                        possible = false
                        break check_game
                    }
                case "blue":
                    if number > max_blue {
                        possible = false
                        break check_game
                    }
                }
            }
        }
        if possible {
            sum += game_id
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

PART2_EXAMPLE_EXPECT :: 2286
PART2_EXAMPLE :: `Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green`

part2 :: proc(input: string) -> int {
    sum := 0
    input := input
    for line in strings.split_lines_after_iterator(&input) {
        line := line[:len(line)-1]
        colon_index := strings.index_byte(line, ':')
        game_id := strconv.atoi(line[5:colon_index])
        power := 1
        games := line[colon_index+2:]
        max_red   := 0
        max_green := 0
        max_blue  := 0
        check_game: for draw in strings.split_iterator(&games, "; ") {
            draw := draw
            for color_draw in strings.split_iterator(&draw, ", ") {
                space_idx := strings.index_byte(color_draw, ' ')
                number := strconv.atoi(color_draw[:space_idx])
                color  := color_draw[space_idx+1:]
                switch color {
                    case "red":   max_red = max(max_red, number)
                    case "green": max_green = max(max_green, number)
                    case "blue":  max_blue = max(max_blue, number)
                }
            }
        }
        sum += max_red * max_blue * max_green
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
