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

Pos :: [2]int

part1 :: proc(input: string) -> int {
    galaxies   := make([dynamic]Pos)
    empty_rows := make([dynamic]int)
    empty_cols := make([dynamic]int)
    {
        input_width := strings.index_byte(input, '\n')
        col_counts  := make([]int, input_width)
        pos_x := 0
        pos_y := 0
        row_n := 0
        for i in 0 ..< len(input) {
            fmt.println(pos_x, pos_y)
            if input[i] == '\n' {
                if row_n == 0 {
                    append(&empty_rows, pos_y)
                }
                pos_x = 0
                pos_y += 1
                row_n = 0
                continue
            }
            if input[i] == '#' {
                append(&galaxies, Pos{pos_x, pos_y})
                row_n += 1
                col_counts[pos_x] += 1
            }
            pos_x += 1
        }
        for col in 0 ..< len(col_counts) {
            if col_counts[col] == 0 {
                append(&empty_cols, col)
            }
        }
    }
    sum := 0
    for galaxy_a, index_a in galaxies {
        for galaxy_b, index_b in galaxies {
            if index_a >= index_b {
                continue
            }
            min_x := min(galaxy_a.x, galaxy_b.x)
            max_x := max(galaxy_a.x, galaxy_b.x)
            min_y := min(galaxy_a.y, galaxy_b.y)
            max_y := max(galaxy_a.y, galaxy_b.y)
            distance_x := max_x - min_x
            distance_y := max_y - min_y
            empty_x := 0
            empty_y := 0
            for col in empty_cols {
                if min_x < col && col < max_x {
                    empty_x += 1
                } else if col >= max_x {
                    break // They're ordered so no need to check further
                }
            }
            for row in empty_rows {
                if min_y < row && row < max_y {
                    empty_y += 1
                } else if row >= max_y {
                    break
                }
            }
            distance := distance_x + distance_y + empty_x + empty_y
            sum += distance
        }
    }
    return sum
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
    {true, 374, 
`...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....`,
    },
}

// -----------------------------------  PART 2 --------------------------------------------------//


part2 :: proc(input: string) -> int {
    galaxies   := make([dynamic]Pos)
    empty_rows := make([dynamic]int)
    empty_cols := make([dynamic]int)
    {
        input_width := strings.index_byte(input, '\n')
        col_counts  := make([]int, input_width)
        pos_x := 0
        pos_y := 0
        row_n := 0
        for i in 0 ..< len(input) {
            if input[i] == '\n' {
                if row_n == 0 {
                    append(&empty_rows, pos_y)
                }
                pos_x = 0
                pos_y += 1
                row_n = 0
                continue
            }
            if input[i] == '#' {
                append(&galaxies, Pos{pos_x, pos_y})
                row_n += 1
                col_counts[pos_x] += 1
            }
            pos_x += 1
        }
        for col in 0 ..< len(col_counts) {
            if col_counts[col] == 0 {
                append(&empty_cols, col)
            }
        }
    }
    sum := 0
    for galaxy_a, index_a in galaxies {
        for galaxy_b, index_b in galaxies {
            if index_a >= index_b {
                continue
            }
            min_x := min(galaxy_a.x, galaxy_b.x)
            max_x := max(galaxy_a.x, galaxy_b.x)
            min_y := min(galaxy_a.y, galaxy_b.y)
            max_y := max(galaxy_a.y, galaxy_b.y)
            distance_x := max_x - min_x
            distance_y := max_y - min_y
            empty_x := 0
            empty_y := 0
            for col in empty_cols {
                if min_x < col && col < max_x {
                    empty_x += 1000000 - 1
                } else if col >= max_x {
                    break // They're ordered so no need to check further
                }
            }
            for row in empty_rows {
                if min_y < row && row < max_y {
                    empty_y += 1000000 - 1
                } else if row >= max_y {
                    break
                }
            }
            distance := distance_x + distance_y + empty_x + empty_y
            sum += distance
        }
    }
    return sum
}

PART2_RUN_INPUT :: true

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
