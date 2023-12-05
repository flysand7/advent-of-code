package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:testing"
import "core:time"
import "core:mem"

INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

PART1_EXAMPLE_EXPECT :: 35
PART1_EXAMPLE :: `seeds: 79 14 55 13

seed-to-soil map:
50 98 2
52 50 48

soil-to-fertilizer map:
0 15 37
37 52 2
39 0 15

fertilizer-to-water map:
49 53 8
0 11 42
42 0 7
57 7 4

water-to-light map:
88 18 7
18 25 70

light-to-temperature map:
45 77 23
81 45 19
68 64 13

temperature-to-humidity map:
0 69 1
1 0 69

humidity-to-location map:
60 56 37
56 93 4
`

part1 :: proc(input: string) -> int {
    Seed :: struct {
        index: int,
        mapped: bool,
    }
    seeds := make([dynamic]Seed)
    first_line_idx := strings.index_byte(input, '\n')
    // Parse the first line and get the seeds
    {
        line := input[0:first_line_idx]
        colon := strings.index_byte(line, ':')
        seed_strings := line[colon+2:]
        for seed_string in strings.split_iterator(&seed_strings, " ") {
            seed, _ := strconv.parse_int(seed_string, 10)
            append(&seeds, Seed {
                index = seed,
                mapped = false,
            })
        }
    }
    // Map the seeds with every map
    lines := input[first_line_idx+1:]
    for line in strings.split_lines_iterator(&lines) {
        if len(line) == 0 || strings.index_byte(line, ':') != -1 {
            for &seed in seeds {
                seed.mapped = false
            }
            continue
        }
        splits := strings.split(line, " ")
        dst_index, _ := strconv.parse_int(splits[0])
        src_index, _ := strconv.parse_int(splits[1])
        length, _    := strconv.parse_int(splits[2])
        for &seed in seeds {
            if !seed.mapped && src_index <= seed.index && seed.index < src_index + length {
                seed.mapped = true
                seed.index += dst_index - src_index
            }
        }
    }
    // Find the lowest mapped value
    min_index := seeds[0].index
    for seed in seeds[1:] {
        min_index = min(min_index, seed.index)
    }
    return min_index
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

PART2_EXAMPLE_EXPECT :: 46
PART2_EXAMPLE :: PART1_EXAMPLE

Range :: struct {
    start: int,
    end:   int,
}

Range_Map :: struct {
    from: Range,
    to:   Range,
}

Step :: struct {
    maps: [dynamic]Range_Map,
}

range_len :: proc(range: Range) -> int {
    return range.end - range.start
}

range_intersects :: proc(a, b: Range) -> bool {
    
    if a.start <= b.start && b.start < a.end ||
       b.start <= a.start && a.start < b.end
    {
        return true
    }
    return false
}

range_equal :: proc(a, b: Range) -> bool {
    return a.start == b.start && a.end == b.end
}

range_offset :: proc(range: Range, offset: int) -> Range {
    return Range { range.start + offset, range.end + offset }
}

part2 :: proc(input: string) -> int {
    Seed :: struct {
        range:  Range,
        mapped: bool,
    }
    seeds := make([dynamic]Seed)
    first_line_idx := strings.index_byte(input, '\n')
    // Parse the first line and get the seed ranges
    {
        line := input[0:first_line_idx]
        colon := strings.index_byte(line, ':')
        seed_strings := strings.split(line[colon+2:], " ")
        for i := 0; i < len(seed_strings); i += 2 {
            range_start,  ok1 := strconv.parse_int(seed_strings[i+0], 10)
            range_length, ok2 := strconv.parse_int(seed_strings[i+1], 10)
            assert(ok1 && ok2)
            append(&seeds, Seed {
                range  = { range_start, range_start + range_length },
                mapped = false,
            })
        }
    }
    fmt.println(len(seeds))
    // Parse the conversion steps
    steps := make([dynamic]Step)
    lines := input[first_line_idx+1:]
    step := Step{}
    index := 0
    for line in strings.split_lines_iterator(&lines) {
        if len(line) == 0 || strings.index_byte(line, ':') != -1 {
            if index != 0 {
                append(&steps, step)
            }
            index += 1
            step = {
                maps = make([dynamic]Range_Map),
            }
            continue
        }
        splits := strings.split(line, " ")
        dst_index, ok1 := strconv.parse_int(splits[0])
        src_index, ok2 := strconv.parse_int(splits[1])
        length, ok3    := strconv.parse_int(splits[2])
        assert(ok1 && ok2 && ok3)
        append(&step.maps, Range_Map {
            to   = { dst_index, dst_index + length },
            from = { src_index, src_index + length },
        })
    }
    // Map ranges, transform into new ranges
    for step in steps {
        for seed_index := 0; seed_index < len(seeds); seed_index += 1 {
            if seeds[seed_index].mapped {
                continue
            }
            seed_range := seeds[seed_index].range
            // Find whether the range is in the mapping
            mapping_mb := Maybe(Range_Map) {}
            for check_mapping in step.maps {
                if range_intersects(check_mapping.from, seed_range) {
                    mapping_mb = check_mapping
                }
            }
            if mapping_mb == nil {
                continue
            }
            mapping := mapping_mb.?
            // Split into three ranges
            intersection := Range {
                clamp(mapping.from.start, seed_range.start, seed_range.end),
                clamp(mapping.from.end,   seed_range.start, seed_range.end),
            }
            assert(range_len(intersection) > 0)
            seeds[seed_index] = {
                range = range_offset(intersection, mapping.to.start - mapping.from.start),
                mapped = true,
            }
            // Push the unmapped ranges onto the queue
            range_before := Range { seed_range.start, intersection.start }
            range_after  := Range { intersection.end, seed_range.end }
            for range in ([]Range {range_before, range_after}) {
                if range_len(range) > 0 {
                    append(&seeds, Seed {
                        mapped = true,
                        range = range,
                    })
                }
            }
        }
        for &seed in seeds {
            seed.mapped = false
        }
    }
    // Find the lowest mapped value
    min_index := seeds[0].range.start
    for seed in seeds[1:] {
        min_index = min(min_index, seed.range.start)
    }
    return min_index
}

@(test)
part2_example :: proc(t: ^testing.T) {
    testing.expect_value(t, part2(PART2_EXAMPLE), PART2_EXAMPLE_EXPECT)
}

//46294175
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
