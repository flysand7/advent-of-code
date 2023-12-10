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

PART1_EXAMPLE_EXPECT :: 8
PART1_EXAMPLE :: `..F7.
.FJ|.
SJ.L7
|F--J
LJ...`

// PART1_EXAMPLE_EXPECT :: 4
// PART1_EXAMPLE :: `.....
// .S-7.
// .|.|.
// .L-J.
// .....`

Direction :: enum {
    U,
    L,
    D,
    R,
}

Orientation :: enum {
    H,
    V,
}

Winding :: enum {
    None,
    CW,
    CCW,
}

Pipe :: [2]Direction

Blocker :: struct {
    offset: int,
    orientation: Orientation,
}

pipes := map[rune]Pipe {
    '|' = {.D, .U},
    '-' = {.L, .R},
    'L' = {.U, .R},
    'J' = {.L, .U},
    '7' = {.L, .D},
    'F' = {.D, .R},
}

pipe_windings: [Direction][Direction]Winding = {
    .U = {.R = .CW, .L = .CCW, .U = .None, .D = .None},
    .R = {.D = .CW, .U = .CCW, .L = .None, .R = .None},
    .D = {.L = .CW, .R = .CCW, .U = .None, .D = .None},
    .L = {.U = .CW, .D = .CCW, .L = .None, .R = .None},
}

direction_negate :: proc(direction: Direction) -> Direction {
    switch direction {
        case .L: return .R
        case .R: return .L
        case .U: return .D
        case .D: return .U
    }
    unreachable()
}

direction_orientation :: proc(direction: Direction) -> Orientation {
    switch direction {
        case .L, .R: return .H
        case .U, .D: return .V
    }
    unreachable()
}

direction_match :: proc(direction: Direction, pipe: Pipe) -> (reject: Direction, ok: bool) {
    meet_direction := direction_negate(direction)
    if pipe[0] == meet_direction {
        return pipe[1], true
    }
    if pipe[1] == meet_direction {
        return pipe[0], true
    }
    return {}, false
}

part1 :: proc(input: string) -> int {
    stride := strings.index_byte(input, '\n')+1
    directions := [Direction]int {
        .L    = -1,
        .U    = -stride,
        .D    = +stride,
        .R    = 1,
    }
    width   := stride - 1
    animal  := strings.index_byte(input, 'S')
    pos     := animal
    length  := 0
    last_direction: Direction
    next_direction: Direction
    // Make the first step
    for offset, direction in directions {
        check_pos := pos+offset
        if !(0 <= check_pos && check_pos < len(input) && input[check_pos] != '\n') do continue
        check_spot := cast(rune) input[check_pos]
        if check_spot == '.' do continue
        check_pipe := pipes[check_spot]
        if reject, ok := direction_match(direction, check_pipe); ok {
            last_direction = direction
            next_direction = reject
            pos = check_pos
            length += 1
            break
        }
    }
    // Iterate until reached the starting point
    for pos != animal {
        // fmt.println("From", last_direction, "To", next_direction)
        check_pos := pos+directions[next_direction]
        check_spot := cast(rune) input[check_pos]
        if check_spot == 'S' {
            length += 1
            break
        }
        check_pipe := pipes[check_spot]
        if reject, ok := direction_match(next_direction, check_pipe); ok {
            last_direction = next_direction
            next_direction = reject
            pos = check_pos
        } else {
            assert(false)
        }
        length += 1
    }
    return length / 2
}

@(test)
part1_run :: proc(t: ^testing.T) {
    input := transmute(string) #load(INPUT_FILENAME)
    testing.expect_value(t, part1(PART1_EXAMPLE), PART1_EXAMPLE_EXPECT)
    if len(input) != 0 {
        runner(part1, input)
    }
}

// -----------------------------------  PART 2 --------------------------------------------------//

// PART2_EXAMPLE_EXPECT :: 4
// PART2_EXAMPLE ::
// `...........
// .S-------7.
// .|F-----7|.
// .||.....||.
// .||.....||.
// .|L-7.F-J|.
// .|..|.|..|.
// .L--J.L--J.
// ...........`

// PART2_EXAMPLE_EXPECT :: 8
// PART2_EXAMPLE :: `.F----7F7F7F7F-7....
// .|F--7||||||||FJ....
// .||.FJ||||||||L7....
// FJL7L7LJLJ||LJ.L-7..
// L--J.L7...LJS7F-7L7.
// ....F-J..F7FJ|L7L7L7
// ....L7.F7||L7|.L7L7|
// .....|FJLJ|FJ|F7|.LJ
// ....FJL-7.||.||||...
// ....L---J.LJ.LJLJ...`

PART2_EXAMPLE_EXPECT :: 10
PART2_EXAMPLE :: `FF7FSF7F7F7F7F7F---7
L|LJ||||||||||||F--J
FL-7LJLJ||||||LJL-77
F--JF--7||LJLJ7F7FJ-
L---JF-JLJ.||-FJLJJ7
|F|F-JF---7F7-L7L|7|
|FFJF7L7F-JF7|JL---7
7-L-JL7||F7|L7F-7F7|
L.L7LFJ|||||FJL7||LJ
L7JLJL-JLJLJL--JLJ.L`

part2 :: proc(input: string) -> int {
    stride := strings.index_byte(input, '\n')+1
    directions := [Direction]int {
        .L    = -1,
        .U    = -stride,
        .D    = +stride,
        .R    = 1,
    }
    width   := stride - 1
    animal  := strings.index_byte(input, 'S')
    pos     := animal
    start_direction: Direction
    last_direction: Direction
    next_direction: Direction
    // We'll need these trackers for detection of "insideness" later on
    blockers := make(map[int]Blocker)
    corners := make(map[int]Pipe)
    // Make the first step
    for offset, direction in directions {
        check_pos := pos+offset
        if !(0 <= check_pos && check_pos < len(input) && input[check_pos] != '\n') do continue
        check_spot := cast(rune) input[check_pos]
        if check_spot == '.' do continue
        check_pipe := pipes[check_spot]
        if reject, ok := direction_match(direction, check_pipe); ok {
            // fmt.println(check_pos, "From", direction, "To", reject)
            start_direction = direction
            last_direction = direction
            next_direction = reject
            if start_direction != next_direction {
                corners[check_pos] = Pipe {start_direction, next_direction}
            } else {
                blockers[check_pos] = Blocker {orientation = direction_orientation(next_direction)}
            }
            pos = check_pos
            break
        }
    }
    // Iterate until reached the starting point
    for pos != animal {
        check_pos := pos+directions[next_direction]
        check_spot := cast(rune) input[check_pos]
        if check_spot == 'S' {
            // fmt.println(check_pos, "From", last_direction, "To", next_direction)
            if next_direction == start_direction {
                blockers[check_pos] = {orientation = direction_orientation(last_direction)}
            } else {
                corners[check_pos] = Pipe {start_direction, direction_negate(next_direction)}
            }
            break
        }
        check_pipe := pipes[check_spot]
        if reject, ok := direction_match(next_direction, check_pipe); ok {
            last_direction = next_direction
            next_direction = reject
            // fmt.println(check_pos, "From", last_direction, "To", next_direction)
            if last_direction == next_direction {
                blockers[check_pos] = {orientation = direction_orientation(last_direction)}
            } else {
                corners[check_pos] = Pipe {last_direction, next_direction}
            }
            pos = check_pos
        } else {
            assert(false)
        }
    }
    n_inside := 0
    n_outside := 0
    for char, offs in input do if char != '\n' {
        if offs in blockers {
            continue
        }
        if offs in corners {
            continue
        }
        // fmt.println("---")
        char_x := offs % stride
        char_y := offs / stride
        n_intersect := 0
        // Find number of intersections.
        pair_winding := Winding.None
        for i := offs; i<len(input) && input[i] != '\n'; i += 1 {
            // Straight edges.
            if i in blockers {
                blocker := blockers[i]
                if blocker.orientation == .V {
                    // fmt.println("blocker at", i, i%stride, char_y, blocker)
                    n_intersect += 1
                }
            }
            // Corners.
            if i in corners {
                corner_pipe := corners[i]
                corner_winding := pipe_windings[corner_pipe[0]][corner_pipe[1]]
                // fmt.println("corner at", i, i%stride, char_y, corner_pipe, pair_winding, corner_winding)
                if pair_winding == .None {
                    pair_winding = corner_winding
                } else {
                    if corner_winding != pair_winding {
                        n_intersect += 1
                    }
                    pair_winding = .None
                }
            }
        }
        if n_intersect % 2 == 0 {
            n_outside += 1
        } else {
            n_inside += 1
            // fmt.println("inside:", n_intersect, char_x, char_y)
        }
    }
    // if animal in corners {
    //     fmt.println("start corner", corners[animal])
    // } else if animal in blockers {
    //     fmt.println("start blocker", blockers[animal])
    // }
    return n_inside
}

@(test)
part2_run :: proc(t: ^testing.T) {
    input := transmute(string) #load(INPUT_FILENAME)
    if len(input) != 0 {
        runner(part2, input)
    }
    testing.expect_value(t, part2(PART2_EXAMPLE), PART2_EXAMPLE_EXPECT)
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
