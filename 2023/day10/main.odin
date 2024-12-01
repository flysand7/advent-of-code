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

// TODO(flysand): I spent too much time commenting out and uncommenting these. I should put tests
// in an array of tests which is easily toggleable.

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
    /*
        We'll be building up a path out of pipes.
    */
    path := make(map[int]Pipe)
    /*
        Make the first step in a separate loop. Here we just need to figure out where we should
        go next. The first step may either be in clockwise direction or counter-clockwise direciton.
        
        The pipe matching is done in a simple way -- we tell `direction_match` function which
        direction we want to go in, and it'll say whether we can go there and also return the
        "other" piece of the pipe (all pipes have only 2 exits). That other piece of the pipe
        specifies the direction which we'll use to go further.
        
        The first step is done in a separate loop because it's the only step where we actually
        need to loop over directions to find out which way to go.
    */
    for offset, direction in directions {
        check_pos := pos+offset
        if !(0 <= check_pos && check_pos < len(input) && input[check_pos] != '\n') do continue
        check_spot := cast(rune) input[check_pos]
        if check_spot == '.' do continue
        check_pipe := pipes[check_spot]
        if reject, ok := direction_match(direction, check_pipe); ok {
            start_direction = direction
            last_direction = direction
            next_direction = reject
            path[check_pos] = Pipe {start_direction, next_direction}
            pos = check_pos
            break
        }
    }
    /*
        Here we just traverse the pipes using `direction_match` function. It's as simple as it
        could be, except for the special case where we reach the starting point -- at that point
        we just need to add an additional pipe to our path to complete the loop.
    */
    for pos != animal {
        check_pos := pos+directions[next_direction]
        check_spot := cast(rune) input[check_pos]
        if check_spot == 'S' {
            path[check_pos] = Pipe {next_direction, start_direction}
            break
        }
        check_pipe := pipes[check_spot]
        if reject, ok := direction_match(next_direction, check_pipe); ok {
            last_direction = next_direction
            next_direction = reject
            path[check_pos] = Pipe {last_direction, next_direction}
            pos = check_pos
        }
    }
    /*
        Here we will count how many of the free points in our pipe labyrinth are contained within
        the cycle formed by the pipes. The basis for the calculation is based on a following
        observation. Imagine a rectangle and casting a ray through any point (inside or outside)
        
            +-------------------------+
            |                         |
            |                         |
        #---x-------------------------x----->>>
            |                         |
            |                         |
            +-------------------------+
        
        You will notice that it has entered the rectangle once and exited the rectangle once. Let's
        try this with a more complicated shape:
        
        
            +---+  +-----+  +---------+
            |   |  |     |  |         |
            |   |  |     |  |         |
        #---x---x--x-----x--x---------x----->>>
            |   +--+     |  |         |
            |            +--+         |
            +-------------------------+
        
        Nothing has changed. So, if we raycast a ray from any point at all, in any direction we can
        tell whether we're inside of a rectangle or outside of the rectangle by counting how many
        times we intersect that shape.
        
        However, there are a bunch of edge cases, which made me spend quite a lot of time on this
        solution. One of such cases is what if the ray hits the edge of a shape? I will show you
        a cutout from my test sample (I'm so glad that the test sample contained this edge case,
        otherwise I probably would have gave up trying to find what's wrong).
        
        Let's soom in on the problematic part.
        
                #
                |
        ────────x
                |
         inside | outside
                |
                |
                |
                x───────┐
                :       |
                :       |
                :       |
                x───────┘
                |
        inside  |  outside
                |
                x─────────
                |
                v
        
        We see that the line has 4 "intersections" with the path, however it starts off outside and
        ends up on the inside. We can see that after first two intersections it winds up on the
        different side of the rectangle but after the second two it stays on the inside.
        
        The difference is that in the first case, one corner intersects our ray from the left and
        the second corner intersects it from the right. In the second case both corners intersect
        our line from the same side.
        
        So from that we see that the handling of corners and blockers in our case should be
        different. Corners are handled in pairs, blockers are handled individually.
        
        This is why I introduced the concept of "winding". I'm not sure if its necessary to
        abstract it like that, but basically every pipe has entry direction and exit direction,
        which form a turn in either clockwise or counter-clockwise direction. When we first
        encounter a corner we set winding to that value. When we encounter a second corner we check
        if the winding value is the same or not, and if its not we count that as an intersection.
        Otherwise we did not intersect the shape.
        
        The initial version of the loop before was written as O(n^2) loop and was checking the
        intersections on same positions multiple times. It ran for half a second (very slow). By
        reducing the loop to O(n) I achieved the time of 60 milliseconds.
        
        The idea of the optimized version is to go through each row, count how many empty spots
        were located at even numbers of intersections and how many at odd (equivalent to scanning
        to the left every time). At the end of each row we check if the total number of
        intersections is even and count either the odd-numbered ones or even-numbered ones.
        
        I wish I could explain that last part better but I'm too fucking tired.
    */
    n_inside := 0
    n_intersect := 0
    n_at_even := 0
    n_at_odd  := 0
    pair_winding := Winding.None
    for char, offs in input {
        if char == '\n' {
            if n_intersect % 2 == 0 {
                n_inside += n_at_odd
            } else {
                n_inside += n_at_even
            }
            n_intersect = 0
            n_at_even = 0
            n_at_odd = 0
            pair_winding = .None
            continue
        }
        char_x := offs % stride
        char_y := offs / stride
        if offs in path {
            pipe := path[offs]
            if pipe[0] == pipe[1] {
                if direction_orientation(pipe[0]) == .V {
                    n_intersect += 1
                }
            } else {
                corner_winding := pipe_windings[pipe[0]][pipe[1]]
                if pair_winding == .None {
                    pair_winding = corner_winding
                } else {
                    if corner_winding != pair_winding {
                        n_intersect += 1
                    }
                    pair_winding = .None
                }
            }
        } else {
            if n_intersect % 2 == 0 {
                n_at_even += 1
            } else {
                n_at_odd += 1
            }
        }
    }
    if n_intersect % 2 == 0 {
        n_inside += n_at_odd
    } else {
        n_inside += n_at_even
    }
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
