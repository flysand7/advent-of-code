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
import "core:simd"

ES_RESET :: "\e[0m"
ES_RED :: "\e[31m"
ES_GREEN :: "\e[32m"
ES_YELLOW :: "\e[33m"
INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

part1_tests := []Test {
    {true, 11, 
`3   4
4   3
2   5
1   3
3   9
3   3`,
    },
}

parse_u32_5 :: proc(s: [^]u8) -> u32 {
    r := u32(s[0] - '0')
    r = 10*r + u32(s[1] - '0')
    r = 10*r + u32(s[2] - '0')
    r = 10*r + u32(s[3] - '0')
    r = 10*r + u32(s[4] - '0')
    return r
}

part1 :: proc(input: string) -> int {
    input := transmute([]u8) input
    list_a: [1000]i32 = ---
    list_b: [1000]i32 = ---
    idx := 0
    for line_idx := 0; line_idx < len(input); line_idx += 14 {
        list_a[idx] = cast(i32) parse_u32_5(&input[line_idx+0])
        list_b[idx] = cast(i32) parse_u32_5(&input[line_idx+8])
        idx += 1
    }
    slice.sort(list_a[:])
    slice.sort(list_b[:])
    sum := u32(0)
    for idx := 0; idx < 1000; idx += 8 {
        a := simd.from_slice(#simd [8]i32, list_a[idx:idx+8])
        b := simd.from_slice(#simd [8]i32, list_b[idx:idx+8])
        sum += simd.reduce_add_ordered(transmute(#simd [8]u32) simd.abs(simd.sub(a, b)))
    }
    return int(sum)
}

// -----------------------------------  PART 2 --------------------------------------------------//

part2_tests := []Test {
    {true, 31, 
`3   4
4   3
2   5
1   3
3   9
3   3`,
    },
}

part2 :: proc(input: string) -> int {
    input := transmute([]u8) input
    list_a: [1000]u32 = ---
    list_b: [1000]u32 = ---
    idx := 0
    for line_idx := 0; line_idx < len(input); line_idx += 14 {
        list_a[idx] = parse_u32_5(&input[line_idx+0])
        list_b[idx] = parse_u32_5(&input[line_idx+8])
        idx += 1
    }
    slice.sort(list_a[:])
    slice.sort(list_b[:])
    sum := u32(0)
    idx_a := 0
    idx_b := 0
    iterate_all: for {
        val_a := list_a[idx_a]
        for val_a > list_b[idx_b] {
            idx_b += 1
            if idx_b == len(list_b) {
                break iterate_all
            }
        }
        val_b := list_b[idx_b]
        for list_a[idx_a] < val_b {
            idx_a += 1
            if idx_a == len(list_a) {
                break iterate_all
            }
        }
        val_a = list_a[idx_a]
        for val_a == list_b[idx_b] {
            sum += val_a
            idx_b += 1
            if idx_b == len(list_b) {
                break iterate_all
            }
        }
        if idx_a >= len(list_a) || idx_b >= len(list_b) {
            break
        }
    }
    return int(sum)
}

// -----------------------------------  MISC --------------------------------------------------//

Part :: struct {
    fn: Part_Fn,
    tests: []Test,
}

Part_Fn :: #type proc(input: string) -> int

Test :: struct {
    enabled: bool,
    expect: int,
    input: string,
}

parts := []Part {
    {},
    {part1, part1_tests},
    {part2, part2_tests},
}

runner :: proc(fn: Part_Fn, input: string) {
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
    fmt.printfln("  " + ES_RED + "Result" + ES_RESET + ": %v", result)
    fmt.printfln("  " + ES_GREEN + "Time" + ES_RESET + ": %v", t_dur)
    fmt.printfln("  " + ES_GREEN + "Memory" + ES_RESET + ": %v bytes", memory)
}

main :: proc() {
    if len(os.args) < 2 {
        fmt.eprintfln("today.exe <part> [options...]")
        os.exit(2)
    }
    part, part_ok := strconv.parse_int(os.args[1])
    if !part_ok {
        fmt.eprintfln("Part must be an integer: '%s'", os.args[1])
        os.exit(2)
    }
    if part != 1 && part != 2 {
        fmt.eprintfln("Unknown part: '%d'. Must be 1 or 2", part)
        os.exit(2)
    }
    do_tests := false
    do_input := false
    for arg in os.args[2:] {
        if arg == "-t" {
            do_tests = true
        } else if arg == "-i" {
            do_input = true
        } else {
            fmt.eprintfln("Unknown option: '%s'", arg)
            os.exit(2)
        }
    }
    if !do_tests && !do_input {
        fmt.eprintfln("Provide -t option to run tests or -i to run input")
        os.exit(2)
    }
    input := transmute(string) #load(INPUT_FILENAME)
    if do_tests {
        fmt.printfln("--------------------------------")
        tests := parts[part].tests
        tests_ok := true
        for test, i in tests do if test.enabled {
            found := parts[part].fn(test.input)
            expected := test.expect
            if found != expected {
                fmt.eprintfln(
                    ES_RED + "[ERR]" + ES_RESET +
                    " Test " + ES_YELLOW + "#%d" + ES_RESET +
                    " found " + ES_RED + "%d" + ES_RESET +
                    ", expected " + ES_GREEN + "%d" + ES_RESET,
                    i,
                    found,
                    expected,
                )
                tests_ok = false
            } else {
                fmt.printfln(
                    ES_GREEN + " [OK]" + ES_RESET +
                    " Test " + ES_YELLOW + "#%d" + ES_RESET +
                    " found " + ES_GREEN + "%d" + ES_RESET +
                    ", expected " + ES_GREEN + "%d" + ES_RESET,
                    i,
                    found,
                    expected,
                )
            }
        }
        if !tests_ok {
            fmt.eprintfln(ES_RED + "ERROR" + ES_RESET + ": Tests failed. Terminating.")
        }
    }
    fmt.printfln("--------------------------------")
    if do_input {
        if len(input) != 0 {
            runner(parts[part].fn, input)
            fmt.printfln("--------------------------------")
        }
    }
    fmt.printfln(ES_GREEN + "Done." + ES_RESET)
}
