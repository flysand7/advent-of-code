package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:testing"

@(test)
part1 :: proc(t: ^testing.T) {
    FILE :: "day1/input"
    fmt.println(os.args)
    file_bytes, ok := os.read_entire_file(FILE)
    assert(ok, "Error reading file")
    file_string := transmute(string) file_bytes
    sum: int = 0
    for line in strings.split_lines_iterator(&file_string) {
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
    fmt.printf("%d\n", sum)
}

@(test)
part2 :: proc(t: ^testing.T) {
    digit_map: map[string]int = {
        "0" = 0, "zero" = 0,
        "1" = 1, "one"  = 1,
        "2" = 2, "two"  = 2,
        "3" = 3, "three" = 3,
        "4" = 4, "four" = 4,
        "5" = 5, "five" = 5,
        "6" = 6, "six" = 6,
        "7" = 7, "seven" = 7,
        "8" = 8, "eight" = 8,
        "9" = 9, "nine" = 9,
    }
    FILE :: "day1/input"
    fmt.println(os.args)
    file_bytes, ok := os.read_entire_file(FILE)
    assert(ok, "Error reading file")
    file_string := transmute(string) file_bytes
    sum: int = 0
    for line in strings.split_lines_iterator(&file_string) {
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
    fmt.printf("%d\n", sum)
}
