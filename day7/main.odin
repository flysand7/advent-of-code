package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:testing"
import "core:time"
import "core:mem"
import "core:strconv"

INPUT_FILENAME :: "./input"

// -----------------------------------  PART 1 --------------------------------------------------//

PART1_EXAMPLE_EXPECT :: 6440
PART1_EXAMPLE :: `32T3K 765
T55J5 684
KK677 28
KTJJT 220
QQQJA 483`

// 8 types of hand -> 3 bits for the type ordering
// 13 types cards  -> 4 bits for the deck ordering per card

// Here's what we do: Compress the deck into its ordering number.
// [ type ] [ card1 ] [ card2 ] [ card3 ] [ card4 ] [ card5 ]
//        |         |         |         |         |         |
//        20        16        12        8         4         0
part1 :: proc(input: string) -> int {
    card_index :: proc(card: u8) -> uint {
        switch card {
            case '2'..='9': return uint(card - '2')
            case 'T': return 8
            case 'J': return 9
            case 'Q': return 10
            case 'K': return 11
            case 'A': return 12
            case: panic("unknown card")
        }
        return 0
    }
    Hand :: struct {
        cards: [5]u8,
        cost:  uint,
        bid:   int,
    }
    input := input
    hands := make([dynamic]Hand)
    for line in strings.split_lines_iterator(&input) {
        cards := (transmute(^[5]u8) raw_data(line[0:5]))^
        bid, _ := strconv.parse_int(line[6:], 10)
        hand: Hand
        hand.cards = cards
        hand.bid = bid
        card_counts := [13]int{}
        for card in cards {
            card_counts[card_index(card)] += 1
        }
        has5 := false
        has4 := false
        has3 := false
        pairs := 0
        for count in card_counts {
            if count == 5 { has5 = true }
            if count == 4 { has4 = true }
            if count == 3 { has3 = true }
            if count == 2 { pairs += 1 }
        }
        score := 0 // high card
        if has5 {
            score = 6 // five of a kind
        } else if has4 {
            score = 5 // four of a kind
        } else if has3 && pairs == 1 {
            score = 4 // full house
        } else if has3 {
            score = 3 // three of a kind
        } else if pairs == 2 {
            score = 2 // two pair
        } else if pairs == 1 {
            score = 1 // one pair
        }
        hand.cost = 0|
            uint(score) << 20 |
            card_index(cards[0]) << 16 |
            card_index(cards[1]) << 12 |
            card_index(cards[2]) << 8  |
            card_index(cards[3]) << 4  |
            card_index(cards[4]) << 0
        append(&hands, hand)
    }
    slice.sort_by_key(hands[:], proc(hand: Hand) -> uint {
        return hand.cost
    })
    sum := 0
    for hand, index in hands {
        rank := index+1
        cards := hand.cards
        fmt.println(transmute(string) cards[:], rank, hand.bid)
        sum += rank * hand.bid
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

PART2_EXAMPLE_EXPECT :: 5905
PART2_EXAMPLE :: PART1_EXAMPLE

part2 :: proc(input: string) -> int {
    card_index :: proc(card: u8) -> uint {
        switch card {
            case 'J': return 0
            case '2'..='9': return uint(card - '2')+1
            case 'T': return 9
            case 'Q': return 10
            case 'K': return 11
            case 'A': return 12
            case: panic("unknown card")
        }
        return 0
    }
    Hand :: struct {
        cards: [5]u8,
        cost:  uint,
        bid:   int,
    }
    input := input
    hands := make([dynamic]Hand)
    for line in strings.split_lines_iterator(&input) {
        cards := (transmute(^[5]u8) raw_data(line[0:5]))^
        bid, _ := strconv.parse_int(line[6:], 10)
        hand: Hand
        hand.cards = cards
        hand.bid = bid
        // Count each card by index.
        card_counts := [13]int{}
        for card in cards {
            card_counts[card_index(card)] += 1
        }
        // Find the largest card and add joker counts to it.
        largest_count := card_counts[1]
        largest_index := 1
        for index in 2 ..< len(card_counts) {
            if card_counts[index] > largest_count {
                largest_count = card_counts[index]
                largest_index = index
            }
        }
        card_counts[largest_index] += card_counts[0]
        // Figure out parameters for deciding the card combo.
        has5 := false
        has4 := false
        has3 := false
        pairs := 0
        for count in card_counts[1:] {
            if count == 5 { has5 = true }
            if count == 4 { has4 = true }
            if count == 3 { has3 = true }
            if count == 2 { pairs += 1 }
        }
        // Assign score for each combo.
        score := 0
        score_type := "high card" // Debugging info.
        if has5 {
            score = 6
            score_type = "five of a kind"
        } else if has4 {
            score = 5
            score_type = "four of a kind"
        } else if has3 && pairs > 0 {
            score = 4
            score_type = "full house"
        } else if has3 {
            score = 3
            score_type = "three of a kind"
        } else if pairs == 2 {
            score = 2
            score_type = "two pair"
        } else if pairs == 1 {
            score = 1
            score_type = "one pair"
        }
        hand.cost = 0|
            uint(score) << 20 |
            card_index(cards[0]) << 16 |
            card_index(cards[1]) << 12 |
            card_index(cards[2]) << 8  |
            card_index(cards[3]) << 4  |
            card_index(cards[4]) << 0
        append(&hands, hand)
    }
    slice.sort_by_key(hands[:], proc(hand: Hand) -> uint {
        return hand.cost
    })
    sum := 0
    for hand, index in hands {
        rank := index+1
        cards := hand.cards
        sum += rank * hand.bid
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
