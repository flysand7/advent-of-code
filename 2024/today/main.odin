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

ES_RESET :: "\e[0m"
ES_RED :: "\e[31m"
ES_GREEN :: "\e[32m"
ES_YELLOW :: "\e[33m"
INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

part1_tests := []Test {
    {true, 0, 
``,
    },
}

part1 :: proc(input: string) -> int {
    input := input
    return 0
}

// -----------------------------------  PART 2 --------------------------------------------------//

part2_tests := []Test {
    {true, 0, 
``,
    },
}

part2 :: proc(input: string) -> int {
    input := input
    return 0
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
